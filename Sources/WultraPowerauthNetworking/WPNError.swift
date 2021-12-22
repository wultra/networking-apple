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

/// A class returned as Error from the library interfaces.
public class WPNError: Error {
    
    public init(reason: WPNErrorReason, error: Error? = nil) {
        #if DEBUG
        if let error = error as? WPNError {
            D.error("You should not embed WPNError into another WPNError object. Please use .wrap() function if you're not sure what type of error is passed to initializer. Error: \(error.localizedDescription)")
        }
        #endif
        self.reason = reason
        self.nestedError = error
    }
    
    /// Private initializer
    fileprivate convenience init(reason: WPNErrorReason, nestedError: Error?, httpUrlResponse: HTTPURLResponse?, restApiError: WPNRestApiError?) {
        self.init(reason: reason, error: nestedError)
        self.httpUrlResponse = httpUrlResponse
        self.restApiError = restApiError
    }
    
    // MARK: - Properties
    
    /// Reason why the error was created
    public let reason: WPNErrorReason
    
    /// Nested error.
    public let nestedError: Error?
    
    /// A full response received from the server.
    ///
    /// If you set a valid object to this property, then the `httpStatusCode` starts
    /// returning status code from the response. You can set this value in cases that,
    /// it's important to investigate a whole response, after the authentication fails.
    ///
    /// Normally, setting `httpStatusCode` is enough for proper handling authentication errors.
    internal(set) public var httpUrlResponse: HTTPURLResponse?
    
    /// An optional error describing details about REST API failure.
    internal(set) public var restApiError: WPNRestApiError?
    
    // MARK: - Computed properties
    
    /// HTTP status code.
    ///
    /// -1 if not available (not a HTTP error).
    public var httpStatusCode: Int? {
        if let httpUrlResponse = httpUrlResponse {
            return Int(httpUrlResponse.statusCode)
        } else if let responseObject = powerAuthRestApiError {
            return Int(responseObject.httpStatusCode)
        } else {
            return nil
        }
    }
    
    /// Returns `PowerAuthRestApiErrorResponse` if such object is embedded in nested error. This is typically useful
    /// for getting error HTTP response created in the PowerAuth2 library.
    public var powerAuthRestApiError: PowerAuthRestApiErrorResponse? {
        guard domain == PowerAuthErrorDomain else {
            return nil
        }
        return userInfo[PowerAuthErrorDomain] as? PowerAuthRestApiErrorResponse
    }
    
    /// Returns PowerAuth error code when the error was caused by the PowerAuth2 library.
    ///
    /// For possible values, visit [PowerAuth Documentation](https://developers.wultra.com/components/powerauth-mobile-sdk/develop/documentation/PowerAuth-SDK-for-iOS#error-handling)
    public var powerAuthErrorCode: PowerAuthErrorCode? {
        return (nestedError as NSError?)?.powerAuthErrorCode
    }
    
    /// Returns error message when the underlying error was caused by the PowerAuth2 library.
    public var powerAuthErrorMessage: String? {
        guard domain == PowerAuthErrorDomain else {
            return nil
        }
        return userInfo[NSLocalizedDescriptionKey] as? String
    }
    
    /// Returns true if the error is caused by the missing network connection.
    /// The device is typically not connected to the internet.
    public var networkIsNotReachable: Bool {
        if self.domain == NSURLErrorDomain || self.domain == kCFErrorDomainCFNetwork as String {
            let ec = CFNetworkErrors(rawValue: Int32(self.code))
            return ec == .cfurlErrorNotConnectedToInternet ||
                ec == .cfurlErrorInternationalRoamingOff ||
                ec == .cfurlErrorDataNotAllowed
        }
        return false
    }
    
    /// Returns true if the error is related to the connection security - like untrusted TLS
    /// certificate, or similar TLS related problems.
    public var networkConnectionIsNotTrusted: Bool {
        if domain == NSURLErrorDomain || domain == kCFErrorDomainCFNetwork as String {
            let code = Int32(code)
            if code == CFNetworkErrors.cfurlErrorServerCertificateHasBadDate.rawValue ||
                code == CFNetworkErrors.cfurlErrorServerCertificateUntrusted.rawValue ||
                code == CFNetworkErrors.cfurlErrorServerCertificateHasUnknownRoot.rawValue ||
                code == CFNetworkErrors.cfurlErrorServerCertificateNotYetValid.rawValue ||
                code == CFNetworkErrors.cfurlErrorSecureConnectionFailed.rawValue {
                return true
            }
        }
        return false
    }
    
    /// Returns WPNError object with nested error and additional nested description.
    /// If the provided error object is already WPNError, then returns copy of the object,
    /// with modified nested description.
    public static func wrap(_ reason: WPNErrorReason, _ error: Error? = nil) -> WPNError {
        if let error = error as? WPNError {
            return WPNError(
                reason: reason,
                nestedError: error.nestedError,
                httpUrlResponse: error.httpUrlResponse,
                restApiError: error.restApiError)
        }
        return WPNError(reason: reason, error: error)
    }
}

/// Reason of the error.
public struct WPNErrorReason: RawRepresentable, Equatable, Hashable {
    
    public static let missingActivation = WPNErrorReason(rawValue: "missingActivation")
    public static let unknown = WPNErrorReason(rawValue: "unknown")
    
    public typealias RawValue = String
    public var rawValue: RawValue
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

// private helpers
private extension WPNError {
    
    var code: Int {
        guard let e = nestedError as NSError? else {
            return 0
        }
        return e.code
    }
    
    var domain: String {
        guard let e = nestedError as NSError? else {
            return "WPNError"
        }
        return e.domain
    }
    
    var userInfo: [String: Any] {
        guard let e = nestedError as NSError? else {
            return [:]
        }
        return e.userInfo
    }
}

extension WPNError: CustomStringConvertible {
    public var description: String {
        
        if let powerAuthErrorMessage = powerAuthErrorMessage {
            return powerAuthErrorMessage
        }
        
        if let nsne = nestedError as NSError? {
            return nsne.description
        }
        
        var result = "Error reason: \(reason)"
        
        result += "\nError  domain: \(domain), code: \(code)"
        
        if let httpStatusCode = httpStatusCode {
            result += "\nHTTP Status Code: \(httpStatusCode)"
        }
        
        if let powerAuthRestApiError = powerAuthRestApiError {
            result += "\nPA REST API Code: \(powerAuthRestApiError)"
        }
        
        return result
    }
}

extension D {
    static func error(_ error: @autoclosure () -> WPNError) {
        D.error(error().description)
    }
}

/// Simple error class to add developer comment when throwing an WPNError
internal class WPNSimpleError: Error {
    
    let localizedDescription: String
    
    init(message: String) {
        localizedDescription = message
    }
}
