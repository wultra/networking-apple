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

/// Internal networking service for dispatching powerauth signed requests
public class WPNNetworkingService {
    
    private let powerAuth: PowerAuthSDK
    private let httpClient: WPNHttpClient
    private let config: WPNConfig
    private let queue = OperationQueue()
    internal var acceptLanguage = "en"
    
    public init(powerAuth: PowerAuthSDK, config: WPNConfig, serviceName: String) {
        self.powerAuth = powerAuth
        self.httpClient = WPNHttpClient(sslValidation: config.sslValidation)
        self.config = config
        queue.name = serviceName
    }
    
    /// Adds a HTTP post request to the request queue.
    @discardableResult
    public func post<Endpoint: WPNEndpoint>(_ data: Endpoint.RequestData, signing: Endpoint.Request.Signing, completion: @escaping Endpoint.Request.Completion) -> Operation {
        
        let request = Endpoint.request(config: config, data: data, signing: signing)
        
        // Setup default headers
        request.addHeaders(getDefaultHeaders())
        let op = WPNAsyncBlockOperation { operation, markFinished in
            
            let completion: Endpoint.Request.Completion = { resp, error in
                markFinished {
                    completion(resp, error)
                }
            }
            
            self.bgCalculateSignature(request) { error in
                
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                self.httpClient.post(request: request, completion: { data, urlResponse, error in
                    
                    guard operation.isCancelled == false else {
                        return
                    }
                    
                    // Handle response
                    var errorReason = WPNErrorReason.network_generic
                    var errorResponse: WPNRestApiError?
                    
                    if let receivedData = data {
                        // We have a data
                        if let responseEnvelope = request.processResult(data: receivedData) {
                            // Valid envelope
                            if responseEnvelope.status == .Ok {
                                // Success exit from block
                                completion(responseEnvelope, nil)
                                return
                                //
                            } else {
                                // Keep an error object received from the server
                                errorResponse = responseEnvelope.responseError
                            }
                        } else {
                            // if the error cannot be parsed and has non success code
                            // report is as error status code (most likely 5xx errors)
                            if let resp = urlResponse, resp.statusCode != 200 {
                                errorReason = .network_errorStatusCode
                            } else { // if the code is 200 and cannot be parsed, the object is "unexpected"
                                errorReason = .network_invalidResponseObject
                            }
                        }
                    } else if let resolved = WPNErrorReason.resolve(error: error) {
                        errorReason = resolved
                    }
                    
                    // Failure exit from block
                    let resultError = WPNError(reason: errorReason, error: error)
                    resultError.httpUrlResponse = urlResponse
                    resultError.restApiError = errorResponse
                    completion(nil, resultError)
                })
                
            }
        }
        op.assignCompletionDispatchQueue(.main)
        queue.addOperation(op)
        return op
    }
    
    // MARK: - Private functions
    
    private func getDefaultHeaders() -> [String: String] {
        return ["Accept-Language": acceptLanguage]
    }
    
    /// Calculates a signature for request. The function must be called on background thread.
    private func bgCalculateSignature<Endpoint: WPNEndpoint>(_ request: Endpoint.Request, completion: @escaping (WPNError?) -> Void) {
        do {
            guard let data = request.requestData else {
                completion(WPNError(reason: .network_invalidRequestObject))
                return
            }
            
            if request.needsTokenSignature {
                // authenticate with token
                _ = powerAuth.tokenStore.requestAccessToken(withName: request.tokenName!, authentication: request.auth!) { (token, error) in
                    //
                    var reportError: WPNError? = error != nil ? WPNError(reason: .network_generic, error: error) : nil
                    if let token = token {
                        if let header = token.generateHeader() {
                            request.addHeader(key: header.key, value: header.value)
                        } else {
                            reportError = WPNError(reason: .network_signError)
                        }
                    } else if error == nil {
                        reportError = WPNError(reason: .network_unknown)
                    }
                    completion(reportError)
                }
            } else {
                // This is always synchronous...
                if request.needsSignature {
                    // Sign request
                    let header = try powerAuth.requestSignature(with: request.auth!, method: request.method, uriId: request.uriIdentifier!, body: data)
                    request.addHeader(key: header.key, value: header.value)
                }
                completion(nil)
            }
            
            return
            
        } catch let error {
            let wpnError = WPNError(reason: .network_signError, error: error)
            completion(wpnError)
        }
    }
}

/// WPN errors for networking
public extension WPNErrorReason {
    /// When unknown (usually logic error) happened during networking.
    static let network_unknown = WPNErrorReason(rawValue: "network_unknown")
    /// When generic networking error happened.
    static let network_generic = WPNErrorReason(rawValue: "network_generic")
    /// An unexpected response from the server.
    static let network_invalidResponseObject = WPNErrorReason(rawValue: "network_invalidResponseObject")
    /// Request is not valid. Such an object is not sent to the server.
    static let network_invalidRequestObject = WPNErrorReason(rawValue: "network_invalidRequestObject")
    /// When the signing of the request failed.
    static let network_signError = WPNErrorReason(rawValue: "network_signError")
    /// Request timed out.
    static let network_timeOut = WPNErrorReason(rawValue: "network_timeOut")
    /// Not connected to the internet.
    static let network_noInternetConnection = WPNErrorReason(rawValue: "network_noInternetConnection")
    /// Bad (malformed) HTTP server response. Probably an unexpected HTTP server error.
    static let network_badServerResponse = WPNErrorReason(rawValue: "network_badServerResponse")
    /// SSL error. For detailed information, see attached error object when available.
    static let network_sslError = WPNErrorReason(rawValue: "network_sslErrror")
    /// HTTP response code was different than 200 (success).
    static let network_errorStatusCode = WPNErrorReason(rawValue: "network_errorStatusCode")
    
    fileprivate static func resolve(error: Error?) -> WPNErrorReason? {
        guard let nse = error as NSError? else {
            return nil
        }
        switch nse.code {
        case NSURLErrorTimedOut: return .network_timeOut
        case NSURLErrorNotConnectedToInternet: return .network_noInternetConnection
        case NSURLErrorBadServerResponse: return .network_badServerResponse
        case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateHasBadDate, NSURLErrorServerCertificateUntrusted,
             NSURLErrorServerCertificateHasUnknownRoot, NSURLErrorServerCertificateNotYetValid, NSURLErrorClientCertificateRejected,
             NSURLErrorClientCertificateRequired, NSURLErrorCannotLoadFromNetwork:
            return .network_sslError
        default: return nil
        }
    }
}
