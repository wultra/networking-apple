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

public class WPNRequestBase: Codable {
    
}

public class WPNRequest<T: Codable>: WPNRequestBase {
    
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

//
// RESPONSES
//

public class WPNResponseBase: Decodable {

    public enum Status: String, Decodable {
        case Ok     = "OK"
        case Error  = "ERROR"
    }
    
    public var status: Status = .Error
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

/// With Nested object T
public class WPNResponse<T: Decodable>: WPNResponseBase {

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

/// With nested array of objects T
public class WPNResponseArray<T: Decodable>: WPNResponseBase {
    
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

/// Known values of rest api errors
public enum WPNKnownRestApiError: String, Decodable {
    
    /// General authentication failure (wrong password, wrong activation state, etc...)
    case authenticationFailure          = "POWERAUTH_AUTH_FAIL"
    
    case pushRegistrationFailed         = "PUSH_REGISTRATION_FAILED"
    
    /// Invalid request sent - missing request object in request
    case invalidRequest                 = "INVALID_REQUEST"
    
    /// Activation is not valid (it is different from configured activation)
    case invalidActivation              = "INVALID_ACTIVATION"
    
    /// Operation is already finished
    case operationAlreadyFinished       = "OPERATION_ALREADY_FINISHED"
    
    /// Operation is already failed
    case operationAlreadyFailed         = "OPERATION_ALREADY_FAILED"
    
    /// Operation is cancelled
    case operationAlreadyCancelled      = "OPERATION_ALREADY_CANCELED"
    
    /// Operation is expired
    case operationExpired               = "OPERATION_EXPIRED"
}

public struct WPNRestApiError: Codable {
    
    /// Code that identifies the type of the error
    public let code: String
    /// Message from the backend
    public let message: String
    
    public var errorCode: WPNKnownRestApiError? {
        return WPNKnownRestApiError(rawValue: code)
    }
    
    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}
