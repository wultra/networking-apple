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

class WPNHttpClient: NSObject, URLSessionDelegate {
    
    private let defaultTimeout: TimeInterval
    private let sslValidation: WPNSSLValidationStrategy
    
    private lazy var urlSession: URLSession = {
        guard let configuration = URLSessionConfiguration.ephemeral.copy() as? URLSessionConfiguration else {
            D.fatalError("Cannot create URLSessionConfiguration")
        }
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = defaultTimeout
        return URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
    }()
    
    init(sslValidation: WPNSSLValidationStrategy, timeout: TimeInterval) {
        self.sslValidation = sslValidation
        self.defaultTimeout = timeout
        super.init()
    }
    
    func post<Req: WPNRequestBase, Resp: WPNResponseBase>(request: WPNHttpRequest<Req, Resp>, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        
        let urlRequest = request.buildUrlRequest()
        
        if request.url.absoluteString.hasPrefix("http://") {
            D.warning("Using HTTP for communication may create a serious security issue! Use HTTPS in production.")
        }
        
        urlRequest.printToConsole()
        
        urlSession.dataTask(with: urlRequest) { responseData, response, error in
            assert(Thread.isMainThread) // make sure we're on the right thread
            let httpResponse = response as? HTTPURLResponse
            httpResponse?.printToConsole(withData: responseData, andError: error)
            completion(responseData, httpResponse, error)
            
        }.resume()
    }
    
    // URLSessionDelegate
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        sslValidation.validate(challenge: challenge, completionHandler: completionHandler)
    }
}

// MARK: - Convenience logging methods

private extension URLRequest {
    func printToConsole() {
        D.print("WPNHttpClient Request")
        D.print("- URL: POST - \(url?.absoluteString ?? "no URL")")
        D.print("- Headers: \(allHTTPHeaderFields?.betterDescription ?? "no headers")")
        D.print("- Body: \(httpBody?.utf8string ?? "empty body")")
    }
}

private extension HTTPURLResponse {
    func printToConsole(withData data: Data?, andError error: Error?) {
        D.print("WPNHttpClient Response")
        D.print("- URL: POST - \(url?.absoluteString ?? "no URL")")
        D.print("- Status code: \(statusCode)")
        D.print("- Headers: \(allHeaderFields.betterDescription)")
        D.print("- Body: \(data?.utf8string ?? "empty body")")
        if let error = error {
            D.print("- Error: \(error.localizedDescription)")
        }
    }
}

private extension Data {
    var utf8string: String? {
        return String(bytes: self, encoding: .utf8)
    }
}

private extension Dictionary where Key: CustomStringConvertible, Value: Any {
    var betterDescription: String {
        return map({($0.key.description, $0.value)}).description
    }
}
