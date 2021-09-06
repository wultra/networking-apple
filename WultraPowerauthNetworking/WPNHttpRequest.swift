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

private let jsonEncoder = JSONEncoder()
private let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

class WPNHttpRequest<TRequest: WPNRequestBase, TResponse: WPNResponseBase> {
    
    enum BodyType: String {
        case json = "application/json"
    }
    
    /// Default value is `.json`
    var requestType = BodyType.json
    /// Default value is `.json`
    var responseType = BodyType.json
    
    private(set) var url: URL
    private(set) var uriIdentifier: String?
    private(set) var tokenName: String?
    private(set) var auth: PowerAuthAuthentication?

    private var headers = [String: String]()
    private(set) var method: String = "POST"
    
    private(set) var requestData: Data?

    var needsSignature: Bool {
        return auth != nil && uriIdentifier != nil
    }
    
    var needsTokenSignature: Bool {
        return auth != nil && tokenName != nil
    }
    
    // Not signed request
    init(_ url: URL, requestData: TRequest) {
        self.url = url
        self.buildRequestData(requestData)
    }
    
    // Signed request
    init(_ url: URL, uriId: String, auth: PowerAuthAuthentication, requestData: TRequest) {
        self.url = url
        self.uriIdentifier = uriId
        self.auth = auth
        self.buildRequestData(requestData)
    }
    
    // Signed with token
    init(_ url: URL, tokenName: String, auth: PowerAuthAuthentication, requestData: TRequest) {
        self.url = url
        self.tokenName = tokenName
        self.auth = auth
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
        
        let requestHeaders = headers.merging(["Accept": responseType.rawValue, "Content-Type": requestType.rawValue], uniquingKeysWith: { f, _ in f })
        
        for (k, v) in requestHeaders {
            request.addValue(v, forHTTPHeaderField: k)
        }
        
        request.httpMethod = method
        request.httpBody = requestData
        
        return request
    }
    
    /// Builds current request and sets the data to `requestData` property
    private func buildRequestData(_ request: TRequest) {
        do {
            switch requestType {
            case .json:
                requestData = try jsonEncoder.encode(request)
            }
        } catch let error {
            D.error("failed to build JSON request:\n\(error)")
        }
    }
    
    /// Parses given result data and sets it to `response` property
    func processResult(data: Data) -> TResponse? {
        
        var response: TResponse?
        
        do {
            switch responseType {
            case .json:
                response = try jsonDecoder.decode(TResponse.self, from: data)
            }
        } catch let error {
            D.error("failed to process result:\n\(error)")
        }
        return response
    }
}
