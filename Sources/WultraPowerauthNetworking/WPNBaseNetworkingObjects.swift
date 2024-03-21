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

/// Base empty request class. Every request needs to inherit from this class.
open class WPNRequestBase: Codable {
    public init() { }
}

/// Standard request, where the request payload is passed as the `requestObject`
/// with a type defined through the generics.
public class WPNRequest<T: Codable>: WPNRequestBase {
    
    /// Request payload.
    public var requestObject: T?
    
    private enum Keys: CodingKey {
        case requestObject
    }
    
    public init(_ requestObject: T) {
        super.init()
        self.requestObject = requestObject
    }
    
    public override func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        try c.encode(requestObject, forKey: .requestObject)
        
        try super.encode(to: encoder)
    }
    
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        requestObject = try c.decode(T.self, forKey: .requestObject)
        
        try super.init(from: decoder)
    }
}

/// Base response class. Every response  needs to inherit from this class.
open class WPNResponseBase: Decodable {
    
    /// Status of the response
    public enum Status: String, Decodable {
        case Ok     = "OK"
        case Error  = "ERROR"
    }
    
    /// Status of the response
    public var status: Status = .Error
    /// Details of the error (when the response is error)
    public var responseError: WPNRestApiError?
    
    private enum Keys: CodingKey {
        case status, responseObject
    }
    
    required public init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        status = try c.decode(Status.self, forKey: .status)
        
        if status == .Error {
            responseError = try c.decode(WPNRestApiError.self, forKey: .responseObject)
        }
        
    }
}

/// Standard response, where the response payload is saved in the `responseObject`
/// with a type defined through the generics.
open class WPNResponse<T: Decodable>: WPNResponseBase {
    
    /// Response object. `nil` on error.
    public var responseObject: T?

    private enum Keys: CodingKey {
        case responseObject
    }
    
    public required init(from decoder: Decoder) throws {
        
        try super.init(from: decoder)
        
        guard status == .Ok else { return }
        
        let c = try decoder.container(keyedBy: Keys.self)
        responseObject = try c.decode(T.self, forKey: .responseObject)
    }
}

/// Standard response where the response payload is array passed as the `responseObject`
/// with type of an element defined through the generics.
open class WPNResponseArray<T: Decodable>: WPNResponseBase {
    
    /// Response object. `nil` on error.
    public var responseObject: [T]?
    
    private enum Keys: CodingKey {
        case responseObject
    }
    
    public required init(from decoder: Decoder) throws {
        
        try super.init(from: decoder)
        
        guard status == .Ok else { return }
        
        let c = try decoder.container(keyedBy: Keys.self)
        responseObject = try c.decode([T].self, forKey: .responseObject)
    }
}

/// Known values of REST API errors
public enum WPNKnownRestApiError: String, Decodable {
    
    // COMMON ERRORS
    
    /// When unexpected error happened.
    case genericError                     = "ERROR_GENERIC"
    
    /// General authentication failure (wrong password, wrong activation state, etc...)
    case authenticationFailure            = "POWERAUTH_AUTH_FAIL"
    
    /// Invalid request sent - missing request object in request
    case invalidRequest                   = "INVALID_REQUEST"
    
    /// Activation is not valid (it is different from configured activation)
    case invalidActivation                = "INVALID_ACTIVATION"
    
    /// Invalid application identifier is attempted for operation manipulation
    case invalidApplication               = "INVALID_APPLICATION"
    
    /// Invalid operation identifier is attempted for operation manipulation
    case invalidOperation                 = "INVALID_OPERATION"
    
    /// Error during activfation
    case activationError                  = "ERR_ACTIVATION"
    
    /// Error in case that PowerAuth authentication fails
    case authenticationError              = "ERR_AUTHENTICATION"
    
    /// Error during secure vault unlocking
    case secureVaultError                 = "ERR_SECURE_VAULT"
    
    /// Returned in case encryption or decryption fails
    case encryptionError                  = "ERR_ENCRYPTION"
    
    // PUSH ERRORS
    
    /// Failed to register push notifications
    case pushRegistrationFailed           = "PUSH_REGISTRATION_FAILED"
    
    // OPERATIONS ERRORS
    
    /// Operation is already finished
    case operationAlreadyFinished         = "OPERATION_ALREADY_FINISHED"
    
    /// Operation is already failed
    case operationAlreadyFailed           = "OPERATION_ALREADY_FAILED"
    
    /// Operation is cancelled
    case operationAlreadyCancelled        = "OPERATION_ALREADY_CANCELED"
    
    /// Operation is expired
    case operationExpired                 = "OPERATION_EXPIRED"
    
    /// Operation authorization failed
    case operationFailed                  = "OPERATION_FAILED"
    
    // ACTIVATION SPAWN ERRORS
    
    /// Unable to fetch activation code.
    case activationCodeFailed             = "ACTIVATION_CODE_FAILED"
    
    // IDENTITY ONBOARDING ERRORS
    
    /// Onboarding process failed or failed to start
    case onboardingFailed                 = "ONBOARDING_FAILED"
    
    /// An onboarding process limit reached (e.g. too many reset attempts for identity verification or maximum error score exceeded).
    case onboardingLimitReached           = "ONBOARDING_PROCESS_LIMIT_REACHED"
    
    /// Too many attempts to start an onboarding process for a user.
    case onboardingTooManyProcesses       = "TOO_MANY_ONBOARDING_PROCESSES"
    
    /// Failed to resend onboarding OTP (probably requested too soon)
    case onboardingOtpFailed              = "ONBOARDING_OTP_FAILED"
    
    /// Document is invalid
    case invalidDocument                  = "INVALID_DOCUMENT"
    
    /// Document submit failed
    case documentSubmitFailed             = "DOCUMENT_SUBMIT_FAILED"
    
    /// Identity verification failed
    case identityVerificationFailed       = "IDENTITY_VERIFICATION_FAILED"
    
    /// Identity verification limit reached (e.g. exceeded number of upload attempts).
    case identityVerificationLimitReached = "IDENTITY_VERIFICATION_LIMIT_REACHED"
    
    /// Verification of documents failed
    case documentVerificationFailed       = "DOCUMENT_VERIFICATION_FAILED"
    
    /// Presence check failed
    case presenceCheckFailed              = "PRESENCE_CHECK_FAILED"
    
    /// Presence check is not enabled
    case presenceCheckNotEnabled          = "PRESENCE_CHECK_NOT_ENABLED"
    
    /// Maximum limit of presence check attempts was exceeded.
    case presenceCheckLimitEached         = "PRESENCE_CHECK_LIMIT_REACHED"
    
    /// Too many same requests
    case tooManyRequests                  = "TOO_MANY_REQUESTS"
    
    // OTHER
    
    /// Communication with remote system failed
    case remoteCommunicationError         = "REMOTE_COMMUNICATION_ERROR"
}

/// Error passed in a response, when the error is returned from an endpoint.
public struct WPNRestApiError: Codable {
    
    /// Code that identifies the type of the error
    public let code: String
    /// Message from the backend
    public let message: String
    
    /// If the `code` is a known API Error, it can be resolved into as finite enum.
    public var errorCode: WPNKnownRestApiError? {
        return WPNKnownRestApiError(rawValue: code)
    }
    
    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}
