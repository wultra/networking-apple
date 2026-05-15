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
    
    func post(request: URLRequest, progressCallback: ((Double) -> Void)?, completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        
        if request.url?.absoluteString.hasPrefix("http://") == true {
            D.warning("Using HTTP for communication may create a serious security issue! Use HTTPS in production.")
        }
        
        request.printToConsole()
        
        var observation: NSKeyValueObservation?
        
        let task = urlSession.dataTask(with: request) { responseData, response, error in
            observation?.invalidate()
            observation = nil
            assert(Thread.isMainThread) // make sure we're on the right thread
            let httpResponse = response as? HTTPURLResponse
            httpResponse?.printToConsole(withData: responseData, andError: error)
            completion(responseData, httpResponse, error)
            
        }
        
        if let progressCallback = progressCallback {
            observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                progressCallback(progress.fractionCompleted)
            }
        }
        task.resume()
    }
    
    // URLSessionDelegate
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        sslValidation.validate(challenge: challenge, completionHandler: completionHandler)
    }
}

// MARK: - Convenience logging methods

private extension URLRequest {
    func printToConsole() {
        if D.logHttpTraffic {
            D.info("WPNHttpClient Request\n- URL: POST - \(url?.absoluteString ?? "no URL")\n- Headers: \(D.httpHeadersToSkip.filterHeaders(headers: allHTTPHeaderFields))")
            D.debug("- Body: \(httpBody?.utf8string ?? "empty body")")
        }
    }
}

private extension HTTPURLResponse {
    func printToConsole(withData data: Data?, andError error: Error?) {
        if D.logHttpTraffic {
            D.info("WPNHttpClient Response\n- URL: POST - \(url?.absoluteString ?? "no URL")\n- Status code: \(statusCode)\n- Headers: \(D.httpHeadersToSkip.filterHeaders(headers: Dictionary(uniqueKeysWithValues: allHeaderFields.map { ($0.key.description, "\($0.value)") })))")
            D.debug("- Body: \(data?.utf8string ?? "empty body")")
            
            if let error {
                D.error("WPNHttpClient response error for \(url?.absoluteString ?? "unknown URL"): \(error.localizedDescription)")
            }
        }
    }
}

private extension Data {
    var utf8string: String? {
        return String(bytes: self, encoding: .utf8)
    }
}
