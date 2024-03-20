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
import PowerAuthCore

class WPNHttpRequest<TRequest: WPNRequestBase, TResponse: WPNResponseBase> {
    
    /// Timeout interval of the request.
    ///
    /// Value from `WPNNetworkingService` `config` will be used when nil.
    var timeoutInterval: TimeInterval?
    
    private(set) var url: URL
    private(set) var uriIdentifier: String?
    private(set) var tokenName: String?
    private(set) var auth: PowerAuthAuthentication?

    private var headers = [String: String]()
    private(set) var method: String = "POST"
    
    private let encryptor: PowerAuthCoreEciesEncryptor?
    
    private(set) var requestData: Data?

    var needsSignature: Bool {
        return auth != nil && uriIdentifier != nil
    }
    
    var needsTokenSignature: Bool {
        return auth != nil && tokenName != nil
    }
    
    // Not signed request
    init(_ url: URL, requestData: TRequest, encryptor: PowerAuthCoreEciesEncryptor? = nil) {
        self.url = url
        self.encryptor = encryptor
        self.buildRequestData(requestData)
    }
    
    // Signed request
    init(_ url: URL, uriId: String, auth: PowerAuthAuthentication, requestData: TRequest, encryptor: PowerAuthCoreEciesEncryptor? = nil) {
        self.url = url
        self.uriIdentifier = uriId
        self.auth = auth
        self.encryptor = encryptor
        self.buildRequestData(requestData)
    }
    
    // Signed with token
    init(_ url: URL, tokenName: String, auth: PowerAuthAuthentication, requestData: TRequest, encryptor: PowerAuthCoreEciesEncryptor? = nil) {
        self.url = url
        self.tokenName = tokenName
        self.auth = auth
        self.encryptor = encryptor
        self.buildRequestData(requestData)
    }
    
    func addHeaders(_ headers: [String: String]) {
        for (k, v) in headers {
            self.headers[k] = v
        }
    }
    
    func addHeader(key: String, value: String) {
        headers[key] = value
    }
    
    func buildUrlRequest() -> URLRequest {
        
        var request = URLRequest(url: url)
        
        if let ti = timeoutInterval {
            request.timeoutInterval = ti
        }
        
        let jsonType = "application/json"
        let requestHeaders = headers.merging(["Accept": jsonType, "Content-Type": jsonType], uniquingKeysWith: { f, _ in f })
        
        for (k, v) in requestHeaders {
            request.addValue(v, forHTTPHeaderField: k)
        }
        
        var data = requestData
        if let encryptor = encryptor {
            if let cryptorgram = encryptor.encryptRequest(data) {
                data = try? jsonEncoder.encode(E2EERequest(cryptogram: cryptorgram))
                // Only add E2EE headers when the endpoint is not signed
                if !needsSignature, let metadata = encryptor.associatedMetaData {
                    request.addValue(metadata.httpHeaderValue, forHTTPHeaderField: metadata.httpHeaderKey)
                }
            } else {
                D.error("Failed to encrypt request with encryptor.")
            }
        }
        
        request.httpMethod = method
        request.httpBody = data
        
        return request
    }
    
    /// Builds current request and sets the data to `requestData` property
    private func buildRequestData(_ request: TRequest) {
        do {
            requestData = try jsonEncoder.encode(request)
        } catch let error {
            D.error("failed to build JSON request:\n\(error)")
        }
    }
    
    /// Parses given result data and sets it to `response` property
    func processResult(data: Data) -> ProcessResultResponse<TResponse> {

        if let encryptor = encryptor {
            do {
                if let decryptedData = encryptor.decryptResponse(try customDecode(E2EEResponse.self, from: data).toCryptorgram()) {
                    do {
                        let decryptedResponse = try customDecode(TResponse.self, from: decryptedData)
                        return .encrypted(obj: decryptedResponse, decryptedData: decryptedData)
                    } catch {
                        D.error("failed to decode decrypted response:\n\(error)")
                        D.error("from decryptedData: \(decryptedData.forLog())")
                        return .failed(error: error)
                    }
                } else {
                    D.error("failed to decrypt response")
                    
                    // error responses might not be encrypted, so try to parse the response as a plain, but only for error responses
                    if let plain = try? customDecode(TResponse.self, from: data), plain.responseError != nil {
                        D.error("but found plain error response")
                        return .plain(obj: plain)
                    }
                    
                    return .failed(error: WPNSimpleError(message: "failed to decrypt response"))
                }
            } catch {
                D.error("failed to decrypt response:\n\(error)")
                D.error("from data: \(data.forLog())")
                return .failed(error: error)
            }
        } else {
            do {
                return .plain(obj: try customDecode(TResponse.self, from: data))
            } catch {
                D.error("failed to decode the response:\n\(error)")
                D.error("from data: \(data.forLog())")
                return .failed(error: error)
            }
        }
    }
}

enum ProcessResultResponse<T> {
    case plain(obj: T)
    case encrypted(obj: T, decryptedData: Data)
    case failed(error: Error)
}

private struct E2EERequest: Encodable {
    let ephemeralPublicKey: String?
    let encryptedData: String?
    let mac: String?
    let nonce: String?
    
    init(cryptogram: PowerAuthCoreEciesCryptogram) {
        ephemeralPublicKey = cryptogram.keyBase64
        encryptedData = cryptogram.bodyBase64
        mac = cryptogram.macBase64
        nonce = cryptogram.nonceBase64
    }
}

private struct E2EEResponse: Decodable {
    let encryptedData: String?
    let mac: String?
    
    func toCryptorgram() -> PowerAuthCoreEciesCryptogram {
        let cryptogram = PowerAuthCoreEciesCryptogram()
        cryptogram.bodyBase64 = encryptedData
        cryptogram.macBase64 = mac
        return cryptogram
    }
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

// json coding

public func customDecode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
    do {
        return try jsonDecoder.decode(T.self, from: data)
    } catch let e {
        D.print("Failed to decode with platform decoder: \(e)")
        return try jsonDecoderCustom.decode(T.self, from: data)
    }
}

private let jsonEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()
private let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()
private let jsonDecoderCustom: JSONDecoder = {
    let decoder = JSONDecoder()
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateStr = try container.decode(String.self)

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        if let date = formatter.date(from: dateStr) {
            return date
        }
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        if let date = formatter.date(from: dateStr) {
            return date
        }
        throw WPNError(reason: .unknown)
    }
    return decoder
}()
