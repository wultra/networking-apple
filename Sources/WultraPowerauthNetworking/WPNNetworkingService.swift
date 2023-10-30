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

/// Strategy that decides if request will be put in serial or concurent queue.
///
/// More about this topic can be found in the
/// [PowerAuth documentation](https://developers.wultra.com/components/powerauth-mobile-sdk/develop/documentation/PowerAuth-SDK-for-iOS#request-synchronization)
public enum WPNRequestConcurencyStrategy {
    /// All requests will be put into concurent queue.
    ///
    /// We recommend not using this option unless you're managing theserialization of requests yourself.
    ///
    /// More about this topic can be found in the
    /// [PowerAuth documentation](https://developers.wultra.com/components/powerauth-mobile-sdk/develop/documentation/PowerAuth-SDK-for-iOS#request-synchronization)
    case concurentAll
    /// Only request that needs PowerAuth signature will be put into serial queue.
    case serialSigned
    /// All requests will be put into serial queue.
    case serialAll
}

/// Networking service for dispatching PowerAuth signed requests.
public class WPNNetworkingService {
    
    /// Language sent to the server for request localized response.
    ///
    /// Compliant with standard RFC Accept-Language. Default value is "en".
    public var acceptLanguage: String
    
    /// Configuration of the service
    public let config: WPNConfig
    
    /// Response delegate is called on each received response
    public weak var responseDelegate: WPNResponseDelegate?
    
    /// Strategy that decides if request will be put in serial or concurent queue.
    ///
    /// Default value is `serialSigned`
    public var concurencyStrategy = WPNRequestConcurencyStrategy.serialSigned
    
    /// PowerAuth instance that will be used for this networking.
    public let powerAuth: PowerAuthSDK
    
    private let httpClient: WPNHttpClient
    private let concurrentQueue = OperationQueue()
    
    /// Creates instance of the `WPNNetworkingService`
    /// - Parameters:
    ///   - powerAuth: PowerAuth instance that will be used for signing.
    ///   - config: Configuration of the service
    ///   - serviceName: Name of the service. Will be reflected in the OperationQueue name and logs.
    ///   - acceptLanguage: Language sent to the server for request localized response.
    ///                     Compliant with standard RFC Accept-Language. Default value is "en".
    public init(powerAuth: PowerAuthSDK, config: WPNConfig, serviceName: String, acceptLanguage: String = "en") {
        self.acceptLanguage = acceptLanguage
        self.powerAuth = powerAuth
        self.httpClient = WPNHttpClient(sslValidation: config.sslValidation, timeout: config.timeoutIntervalForRequest)
        self.config = config
        concurrentQueue.name = "\(serviceName)_concurrent"
    }
    
    /// Sends basic request without an authentication
    /// - Parameters:
    ///   - data: Request data to send.
    ///   - endpoint: Server endpoint.
    ///   - headers: Custom headers to send along.
    ///   - encryptor: Optional encryptor for End to End Encryption.
    ///   - timeoutInterval: Timeout interval of the request.
    ///                      Value from `config` will be used when nil.
    ///   - progressCallback: Reports fraction of how much data was already transferred.
    ///   - completionQueue: Queue on wich the completion will be executed.
    ///                      Default value is .main
    ///   - completion: Completion handler. This callback is executed on the queue defined in `completionQueue` parameter.
    /// - Returns: Operation for observation or operation chaining.
    @discardableResult
    public func post<Req: WPNRequestBase, Resp: WPNResponseBase, Endpoint: WPNEndpointBasic<Req, Resp>>(data: Req,
                                                                                                        to endpoint: Endpoint,
                                                                                                        with headers: [String: String]? = nil,
                                                                                                        encryptedWith encryptor: PowerAuthCoreEciesEncryptor? = nil,
                                                                                                        timeoutInterval: TimeInterval? = nil,
                                                                                                        progressCallback: ((Double) -> Void)? = nil,
                                                                                                        completionQueue: DispatchQueue = .main,
                                                                                                        completion: @escaping Endpoint.Completion) -> Operation {
        let url = config.buildURL(endpoint.endpointURLPath)
        let request = Endpoint.Request(url, requestData: data, encryptor: encryptor)
        request.timeoutInterval = timeoutInterval
        return post(request: request, headers: headers, progressCallback: progressCallback, completionQueue: completionQueue, completion: completion)
    }
    
    /// Sends signed request with provided authentication.
    /// - Parameters:
    ///   - data: Request data to send.
    ///   - auth: Authentication object.
    ///   - endpoint: Server endpoint.
    ///   - headers: Custom headers to send along.
    ///   - encryptor: Optional encryptor for End to End Encryption.
    ///   - timeoutInterval: Timeout interval of the request.
    ///                      Value from `config` will be used when nil.
    ///   - progressCallback: Reports fraction of how much data was already transferred.
    ///   - completionQueue: Queue on wich the completion will be executed.
    ///                      Default value is .main
    ///   - completion: Completion handler. This callback is executed on the queue defined in `completionQueue` parameter.
    /// - Returns: Operation for observation or operation chaining.
    @discardableResult
    public func post<Req: WPNRequestBase, Resp: WPNResponseBase, Endpoint: WPNEndpointSigned<Req, Resp>>(data: Req,
                                                                                                         signedWith auth: PowerAuthAuthentication,
                                                                                                         to endpoint: Endpoint,
                                                                                                         with headers: [String: String]? = nil,
                                                                                                         encryptedWith encryptor: PowerAuthCoreEciesEncryptor? = nil,
                                                                                                         timeoutInterval: TimeInterval? = nil,
                                                                                                         progressCallback: ((Double) -> Void)? = nil,
                                                                                                         completionQueue: DispatchQueue = .main,
                                                                                                         completion: @escaping Endpoint.Completion) -> Operation {
        let url = config.buildURL(endpoint.endpointURLPath)
        let request = Endpoint.Request(url, uriId: endpoint.uriId, auth: auth, requestData: data, encryptor: encryptor)
        request.timeoutInterval = timeoutInterval
        return post(request: request, headers: headers, progressCallback: progressCallback, completionQueue: completionQueue, completion: completion)
    }
    
    /// Sends signed request with provided authentication.
    /// - Parameters:
    ///   - data: Request data to send.
    ///   - auth: Authentication object.
    ///   - endpoint: Server endpoint.
    ///   - headers: Custom headers to send along.
    ///   - encryptor: Optional encryptor for End to End Encryption.
    ///   - timeoutInterval: Timeout interval of the request.
    ///                      Value from `config` will be used when nil.
    ///   - progressCallback: Reports fraction of how much data was already transferred.
    ///   - completionQueue: Queue on wich the completion will be executed.
    ///                      Default value is .main
    ///   - completion: Completion handler. This callback is executed on the queue defined in `completionQueue` parameter.
    /// - Returns: Operation for observation or operation chaining.
    @discardableResult
    public func post<Req: WPNRequestBase, Resp: WPNResponseBase, Endpoint: WPNEndpointSignedWithToken<Req, Resp>>(data: Req,
                                                                                                                  signedWith auth: PowerAuthAuthentication,
                                                                                                                  to endpoint: Endpoint,
                                                                                                                  with headers: [String: String]? = nil,
                                                                                                                  encryptedWith encryptor: PowerAuthCoreEciesEncryptor? = nil,
                                                                                                                  timeoutInterval: TimeInterval? = nil,
                                                                                                                  progressCallback: ((Double) -> Void)? = nil,
                                                                                                                  completionQueue: DispatchQueue = .main,
                                                                                                                  completion: @escaping Endpoint.Completion) -> Operation {
        let url = config.buildURL(endpoint.endpointURLPath)
        let request = Endpoint.Request(url, tokenName: endpoint.tokenName, auth: auth, requestData: data, encryptor: encryptor)
        request.timeoutInterval = timeoutInterval
        return post(request: request, headers: headers, progressCallback: progressCallback, completionQueue: completionQueue, completion: completion)
    }
    
    /// Adds a HTTP post request to the request queue.
    @discardableResult
    func post<Req: WPNRequestBase, Resp: WPNResponseBase, Endpoint: WPNEndpoint<Req, Resp>>(request: Endpoint.Request,
                                                                                            headers: [String: String]?,
                                                                                            progressCallback: ((Double) -> Void)?,
                                                                                            completionQueue: DispatchQueue,
                                                                                            completion: @escaping Endpoint.Completion) -> Operation {
        // Setup default headers
        request.addHeaders(getDefaultHeaders())
        
        // add additional headers (be aware that it can override the default headers)
        if let headers = headers {
            request.addHeaders(headers)
        }
        
        let op = WPNAsyncBlockOperation { operation, markFinished in
            
            let completion: (Resp?, WPNError?) -> Void = { resp, error in
                markFinished {
                    completion(resp, error)
                }
            }
            
            self.bgCalculateSignature(request) { error in
                
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                self.httpClient.post(request: request, progressCallback: progressCallback, completion: { [weak self] data, urlResponse, error in
                    
                    guard let self = self, operation.isCancelled == false else {
                        return
                    }
                    
                    // Handle response
                    var errorReason = WPNErrorReason.network_generic
                    var errorResponse: WPNRestApiError?
                    
                    if let receivedData = data {
                        // Process data
                        let processedResult = request.processResult(data: receivedData)
                        
                        var resp: Resp?
                        
                        switch processedResult {
                        case .plain(let envelope):
                            self.responseDelegate?.responseReceived(from: request.url, statusCode: urlResponse?.statusCode, body: receivedData)
                            resp = envelope
                        case .encrypted(let envelope, let decryptedData):
                            self.responseDelegate?.encryptedResponseReceived(from: request.url, statusCode: urlResponse?.statusCode, body: receivedData, decrypted: decryptedData)
                            resp = envelope
                        case .failed:
                            self.responseDelegate?.responseReceived(from: request.url, statusCode: urlResponse?.statusCode, body: receivedData)
                            resp = nil
                        }
                        if let responseEnvelope = resp {
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
        
        op.completionQueue = completionQueue
        
        if (concurencyStrategy == .serialSigned && request.needsSignature) || concurencyStrategy == .serialAll {
            // Add operation to the "signing" queue.
            if !powerAuth.executeOperation(onSerialQueue: op) {
                // Operation wont be added to the queue if there is a missing
                // activation in the powerauth instance.
                // In such case, cancel the operation and call completion with appropriate error.
                op.cancel()
                completionQueue.async {
                    completion(nil, WPNError(reason: .network_signError, error: WPNSimpleError(message: "Failed to execute signed operation - PowerAuth instance without activation.")))
                }
            }
        } else {
            concurrentQueue.addOperation(op)
        }
        
        return op
    }
    
    // MARK: - Private functions
    
    private func getDefaultHeaders() -> [String: String] {
        var headers = ["Accept-Language": acceptLanguage]
        if let userAgent = config.userAgent.getValue() {
            headers["User-Agent"] = userAgent
        }
        return headers
    }
    
    /// Calculates a signature for request. The function must be called on background thread.
    private func bgCalculateSignature<Req: WPNRequestBase, Resp: WPNResponseBase>(_ request: WPNHttpRequest<Req, Resp>, completion: @escaping (WPNError?) -> Void) {
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
