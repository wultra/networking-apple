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

private let jsonEncoder = JSONEncoder()
private let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

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
        
        do {
            if let encryptor = encryptor {
                if let decryptedData = encryptor.decryptResponse(try jsonDecoder.decode(E2EEResponse.self, from: data).toCryptorgram()) {
                    return .encrypted(obj: try jsonDecoder.decode(TResponse.self, from: decryptedData), decryptedData: decryptedData)
                } else {
                    D.error("failed to decrypt response")
                    
                    // error responses might not be encrypted, so try to parse the response as a plain, but only for error responses
                    if let plain = try? jsonDecoder.decode(TResponse.self, from: data), plain.responseError != nil {
                        D.error("but found plain error response")
                        return .plain(obj: plain)
                    }
                    
                    return .failed(error: WPNSimpleError(message: "failed to decrypt response"))
                }
            } else {
                return .plain(obj: try jsonDecoder.decode(TResponse.self, from: data))
            }
        } catch {
            D.error("failed to process result:\n\(error)")
            return .failed(error: error)
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
