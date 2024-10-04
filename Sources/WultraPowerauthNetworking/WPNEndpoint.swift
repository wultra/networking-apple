//
// Copyright 2021 Wultra s.r.o.
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

/// Class that describes a server endpoint.
public class WPNEndpoint<TRequestData: WPNRequestBase, TResponseData: WPNResponseBase> {
    
    /// URL path for the endpoint.
    /// For example "/my/custom/endpoint"
    public let endpointURLPath: String
    
    /// End to end encryption configuration
    public let e2ee: WPNE2EEConfiguration
    
    /// Class that describes a server endpoint.
    /// - Parameters:
    ///   - endpointURLPath: URL path for the endpoint. For example "/my/custom/endpoint".
    ///   - e2ee: End to end encryption configuration.
    init(endpointURLPath: String, e2ee: WPNE2EEConfiguration) {
        self.endpointURLPath = endpointURLPath
        self.e2ee = e2ee
    }
    
    typealias Request = WPNHttpRequest<TRequestData, TResponseData>
    /// Request data for the endpoint.
    public typealias RequestData = TRequestData
    /// Response data for the endpoint.
    public typealias ResponseData = TRequestData
    /// Completion called when call on the endpoint ends.
    public typealias Completion = (TResponseData?, WPNError?) -> Void
}

/// Basic endpoint not signed with PowerAuth.
public class WPNEndpointBasic<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    
    /// Basic endpoint - not signed with PowerAuth
    /// - Parameters:
    ///   - endpointURLPath: URL path for the endpoint. For example "/my/custom/endpoint".
    ///   - e2ee: End to end encryption configuration. `.notEncrypted` by default
    public override init(endpointURLPath: String, e2ee: WPNE2EEConfiguration = .notEncrypted) {
        super.init(endpointURLPath: endpointURLPath, e2ee: e2ee)
    }
}

/// Endpoint signed with PowerAuth signature
public class WPNEndpointSigned<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    
    /// Endpoint ID. Note that this is different from endpoint URL
    public let uriId: String
    
    /// Endpoint signed with PowerAuth signature.
    /// - Parameters:
    ///   - endpointURLPath: URL path for the endpoint. For example "/my/custom/endpoint".
    ///   - uriId: Endpoint ID. Note that this is different from endpoint URL.
    ///   - e2ee: End to end encryption configuration. `.notEncrypted` by default
    public init(endpointURLPath: String, uriId: String, e2ee: WPNE2EEConfiguration = .notEncrypted) {
        self.uriId = uriId
        super.init(endpointURLPath: endpointURLPath, e2ee: e2ee)
    }
}

/// Endpoint signed with PowerAuth Token signature
public class WPNEndpointSignedWithToken<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    
    /// Name of the token used for signature.
    public let tokenName: String
    
    /// Endpoint signed with PowerAuth Token signature.
    /// - Parameters:
    ///   - endpointURLPath: URL path for the endpoint. For example "/my/custom/endpoint".
    ///   - tokenName: Name of the token used for signature.
    ///   - e2ee: End to end encryption configuration. `.notEncrypted` by default
    public init(endpointURLPath: String, tokenName: String, e2ee: WPNE2EEConfiguration = .notEncrypted) {
        self.tokenName = tokenName
        super.init(endpointURLPath: endpointURLPath, e2ee: e2ee)
    }
}
