//
// Copyright 2020 Wultra s.r.o.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions
// and limitations under the License.
//

import Foundation
import PowerAuth2

/// Base HTTP request used by `WPNNetworkingService`. Represents a plain (unauthenticated) POST request.
///
/// Authentication variants are provided as subclasses:
/// - `WPNHttpAuthenticatedRequest` for PowerAuth authentication code authentication.
/// - `WPNHttpTokenAuthenticatedRequest` for PowerAuth token-based authentication.
internal class WPNHttpPlainRequest<TRequest: WPNRequestBase, TResponse: WPNResponseBase> {

    /// Explicit timeout interval of the request.
    let timeoutInterval: TimeInterval?

    let url: URL
    let method = "POST"

    private(set) var headers = [String: String]()

    fileprivate let jsonDecoder: JSONDecoder
    fileprivate let jsonEncoder: JSONEncoder

    private let requestObject: TRequest

    /// Whether the encrypted request headers should be added to the URL request when E2EE is active.
    /// Subclasses that authenticate via PowerAuth authentication code override this to `false` to avoid header collision.
    fileprivate var addsEncryptionHeaders: Bool { true }

    init(_ url: URL, requestData: TRequest, decoder: JSONDecoder, encoder: JSONEncoder, timeoutInterval: TimeInterval? = nil) {
        self.url = url
        self.requestObject = requestData
        self.jsonDecoder = decoder
        self.jsonEncoder = encoder
        self.timeoutInterval = timeoutInterval
    }

    func addHeaders(_ headers: [String: String]) {
        for (key, value) in headers {
            addHeader(key: key, value: value)
        }
    }

    func addHeader(key: String, value: String) {
        headers[key] = value
    }

    /// Encodes the request body, computes any authentication headers required by this request
    /// subclass, obtains an E2EE encryptor when configured, and assembles the final `WPNUrlRequest`.
    ///
    /// This is the single entry point for callers; encoding, auth-header computation, and
    /// encryptor acquisition are handled internally.
    ///
    /// - Parameters:
    ///   - powerAuth: PowerAuth instance used for authentication header computation and encryptor acquisition.
    ///   - e2ee: End-to-end encryption configuration for this endpoint.
    ///   - completion: Completion called with `.success(WPNUrlRequest)` or `.failure(WPNError)`.
    func buildUrlRequest(
        powerAuth: PowerAuthSDK,
        e2ee: WPNE2EEConfiguration,
        completion: @escaping (Result<WPNUrlRequest<TResponse>, WPNError>) -> Void
    ) {
        let bodyData: Data
        do {
            bodyData = try jsonEncoder.encode(requestObject)
        } catch {
            D.error("Failed to encode request body for \(url.absoluteString): \(error)")
            completion(.failure(WPNError(reason: .network_invalidRequestObject, error: error)))
            return
        }

        computeAuthHeaders(powerAuth: powerAuth, bodyData: bodyData) { [self] error in
            if let error {
                D.error("Failed to compute authentication headers for \(self.url.absoluteString): \(error)")
                completion(.failure(error))
                return
            }
            self.getEncryptor(powerAuth: powerAuth, e2ee: e2ee) { [self] encryptor, encryptorError in
                if let encryptorError {
                    D.error("Failed to obtain E2EE encryptor for \(self.url.absoluteString): \(encryptorError)")
                    completion(.failure(WPNError(reason: .network_e2eeError, error: encryptorError)))
                    return
                }
                do {
                    let urlRequest = try self.assembleUrlRequest(bodyData: bodyData, encryptor: encryptor)
                    let wpnRequest = WPNUrlRequest<TResponse>(urlRequest: urlRequest, url: self.url, encryptor: encryptor, jsonDecoder: self.jsonDecoder)
                    completion(.success(wpnRequest))
                } catch {
                    completion(.failure(WPNError(reason: .network_e2eeError, error: error)))
                }
            }
        }
    }

    /// Computes any authorization headers required by this request and stores them via `addHeader`.
    /// The base implementation is a no-op since plain requests are unauthenticated.
    fileprivate func computeAuthHeaders(
        powerAuth: PowerAuthSDK,
        bodyData: Data,
        completion: @escaping (WPNError?) -> Void
    ) {
        completion(nil)
    }

    private func getEncryptor(
        powerAuth: PowerAuthSDK,
        e2ee: WPNE2EEConfiguration,
        completion: @escaping (PowerAuthEncryptor?, Error?) -> Void
    ) {
        switch e2ee {
        case .activationScope:
            powerAuth.encryptorForActivationScope(callback: completion)
        case .applicationScope:
            powerAuth.encryptorForApplicationScope(callback: completion)
        case .notEncrypted:
            completion(nil, nil)
        }
    }

    /// Assembles the final `URLRequest` from pre-encoded body data and optional encryptor.
    private func assembleUrlRequest(bodyData: Data, encryptor: PowerAuthEncryptor?) throws -> URLRequest {

        var request = URLRequest(url: url)

        if let timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }

        let jsonType = "application/json"
        let requestHeaders = headers.merging(["Accept": jsonType, "Content-Type": jsonType], uniquingKeysWith: { f, _ in f })

        for (key, value) in requestHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }

        let (body, encryptionHeaders) = try encryptBody(bodyData: bodyData, encryptor: encryptor)

        for (key, value) in encryptionHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }

        request.httpMethod = method
        request.httpBody = body

        return request
    }

    /// Encrypts the request body when an encryptor is provided, returning the (possibly encrypted)
    /// body data together with any encryption headers that must be added to the URL request.
    private func encryptBody(
        bodyData: Data,
        encryptor: PowerAuthEncryptor?
    ) throws -> (body: Data, headers: [(key: String, value: String)]) {
        guard let encryptor else {
            return (bodyData, [])
        }
        do {
            let encrypted = try encryptor.encryptRequest(bodyData)
            let headers: [(key: String, value: String)] = addsEncryptionHeaders
                ? encrypted.requestHeaders.map { ($0.key, $0.value) }
                : []
            return (encrypted.requestBody, headers)
        } catch {
            D.error("Failed to encrypt request body for \(url.absoluteString): \(error)")
            throw error
        }
    }

}

/// HTTP request authenticated via a PowerAuth authentication code header.
internal final class WPNHttpAuthenticatedRequest<TRequest: WPNRequestBase, TResponse: WPNResponseBase>: WPNHttpPlainRequest<TRequest, TResponse> {

    let uriIdentifier: String
    let auth: PowerAuthAuthentication

    init(
        _ url: URL,
        uriId: String,
        auth: PowerAuthAuthentication,
        requestData: TRequest,
        decoder: JSONDecoder,
        encoder: JSONEncoder,
        timeoutInterval: TimeInterval? = nil
    ) {
        self.uriIdentifier = uriId
        self.auth = auth
        super.init(url, requestData: requestData, decoder: decoder, encoder: encoder, timeoutInterval: timeoutInterval)
    }

    /// Authentication-code requests provide their own authentication header, so the encrypted
    /// request headers must not be added to avoid clashing with the authentication code scheme.
    fileprivate override var addsEncryptionHeaders: Bool { false }

    fileprivate override func computeAuthHeaders(
        powerAuth: PowerAuthSDK,
        bodyData: Data,
        completion: @escaping (WPNError?) -> Void
    ) {
        do {
            let header = try powerAuth.authenticationHeaderForRequestWithBody(
                with: auth,
                method: method,
                uriId: uriIdentifier,
                body: bodyData
            )
            addHeader(key: header.key, value: header.value)
            completion(nil)
        } catch {
            D.error("Failed to compute authentication code for \(url.absoluteString) (uriId: \(uriIdentifier)): \(error)")
            completion(WPNError(reason: .network_signError, error: error))
        }
    }
}

/// HTTP request authenticated via a PowerAuth token authorization header.
internal final class WPNHttpTokenAuthenticatedRequest<TRequest: WPNRequestBase, TResponse: WPNResponseBase>: WPNHttpPlainRequest<TRequest, TResponse> {

    let tokenName: String
    let auth: PowerAuthAuthentication

    init(
        _ url: URL,
        tokenName: String,
        auth: PowerAuthAuthentication,
        requestData: TRequest,
        decoder: JSONDecoder,
        encoder: JSONEncoder,
        timeoutInterval: TimeInterval? = nil
    ) {
        self.tokenName = tokenName
        self.auth = auth
        super.init(url, requestData: requestData, decoder: decoder, encoder: encoder, timeoutInterval: timeoutInterval)
    }

    fileprivate override func computeAuthHeaders(
        powerAuth: PowerAuthSDK,
        bodyData: Data,
        completion: @escaping (WPNError?) -> Void
    ) {
        let tokenName = self.tokenName
        let url = self.url
        powerAuth.tokenStore.requestAccessToken(withName: tokenName, authentication: auth) { [weak self] token, tokenError in
            guard let self else {
                completion(WPNError(reason: .network_tokenError))
                return
            }
            guard let token else {
                if let tokenError {
                    D.error("Failed to obtain token '\(tokenName)' for \(url.absoluteString): \(tokenError)")
                    completion(WPNError(reason: .network_tokenError, error: tokenError))
                } else {
                    D.error("Failed to obtain token '\(tokenName)' for \(url.absoluteString): unknown error")
                    completion(WPNError(reason: .network_unknown))
                }
                return
            }
            powerAuth.tokenStore.generateAuthenticationHeader(withName: token.tokenName) { header, headerError in
                if let header {
                    self.addHeader(key: header.key, value: header.value)
                }
                if let headerError {
                    D.error("Failed to generate token header '\(token.tokenName)' for \(url.absoluteString): \(headerError)")
                }
                completion(headerError != nil ? WPNError(reason: .network_tokenError, error: headerError) : nil)
            }
        }
    }
}

/// Ready-to-send URL request produced by `WPNHttpPlainRequest.buildUrlRequest(...)`.
///
/// Bundles the assembled `URLRequest` with the encryptor and decoder needed to process the response,
/// so callers do not have to pass those dependencies separately.
internal struct WPNUrlRequest<TResponse: WPNResponseBase> {

    /// The assembled `URLRequest` ready to be sent via `WPNHttpClient`.
    let urlRequest: URLRequest

    /// The original endpoint URL (used for logging and response delegate callbacks).
    let url: URL

    /// Whether the request uses end-to-end encryption.
    var isEncrypted: Bool { encryptor != nil }

    private let encryptor: PowerAuthEncryptor?
    private let jsonDecoder: JSONDecoder

    init(urlRequest: URLRequest, url: URL, encryptor: PowerAuthEncryptor?, jsonDecoder: JSONDecoder) {
        self.urlRequest = urlRequest
        self.url = url
        self.encryptor = encryptor
        self.jsonDecoder = jsonDecoder
    }

    /// Parses the received response data into the typed response envelope,
    /// decrypting it first when E2EE is active.
    func processResult(data: Data) -> WPNProcessedResponse<TResponse> {
        if let encryptor {
            do {
                let decryptedData = try encryptor.decryptResponse(try PowerAuthEncryptedResponse(responseBody: data))
                do {
                    let envelope = try jsonDecoder.decode(TResponse.self, from: decryptedData)
                    return .success(envelope: envelope, decryptedData: decryptedData)
                } catch {
                    D.error("Failed to decode decrypted response from \(url.absoluteString): \(error)")
                    D.debug("Decrypted data: \(decryptedData.forLog())")
                    return .failure(error: error)
                }
            } catch {
                // error responses are not encrypted - try to parse the response as a plain, but only for error responses
                if let plain = try? jsonDecoder.decode(TResponse.self, from: data), plain.responseError != nil {
                    return .success(envelope: plain, decryptedData: nil)
                }
                D.error("Failed to decrypt response from \(url.absoluteString): \(error)")
                return .failure(error: error)
            }
        } else {
            do {
                let envelope = try jsonDecoder.decode(TResponse.self, from: data)
                return .success(envelope: envelope, decryptedData: nil)
            } catch {
                D.error("Failed to decode response from \(url.absoluteString): \(error)")
                D.debug("Raw data: \(data.forLog())")
                return .failure(error: error)
            }
        }
    }
}

/// Result of decoding/decrypting a server response.
enum WPNProcessedResponse<T: WPNResponseBase> {
    /// The response envelope was decoded successfully.
    /// `decryptedData` is non-nil when the response was E2EE-encrypted.
    case success(envelope: T, decryptedData: Data?)
    /// Decoding or decryption failed.
    case failure(error: Error)
}

private extension Data {
    func forLog() -> String {
        // If the Data instance can’t be converted to a UTF-8 string, you’ll get back an empty string.
        let decoded = String(decoding: self, as: UTF8.self)
        if decoded.isEmpty == false {
            return decoded
        } else {
            return "Data could not be stringified. Here is a base64 encoded version of it: \(self.base64EncodedString())"
        }
    }
}
