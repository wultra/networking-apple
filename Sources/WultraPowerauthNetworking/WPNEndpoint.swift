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

/// Typed description of a server endpoint handled by `WPNNetworkingService`.
public class WPNEndpoint<TRequestData: WPNRequestBase, TResponseData: WPNResponseBase> {
    
    /// Request envelope type accepted by the endpoint.
    public typealias RequestData = TRequestData
    /// Response envelope type returned by the endpoint.
    public typealias ResponseData = TResponseData

    /// URL path appended to the service base URL.
    /// For example `"/my/custom/endpoint"`.
    public let endpointURLPath: String
    
    /// End-to-end encryption configuration for this endpoint.
    public let e2ee: WPNE2EEConfiguration
    
    /// Creates a typed server endpoint definition.
    /// - Parameters:
    ///   - endpointURLPath: URL path for the endpoint. For example `"/my/custom/endpoint"`.
    ///   - e2ee: End-to-end encryption configuration.
    init(endpointURLPath: String, e2ee: WPNE2EEConfiguration) {
        self.endpointURLPath = endpointURLPath
        self.e2ee = e2ee
    }
    
    /// Completion called when a request to the endpoint finishes.
    public typealias Completion = (ResponseData?, WPNError?) -> Void
}

/// Endpoint that does not require a PowerAuth authentication code.
public class WPNEndpointBasic<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    
    typealias Request = WPNHttpPlainRequest<RequestData, ResponseData>
    
    /// Creates an unauthenticated endpoint definition.
    /// - Parameters:
    ///   - endpointURLPath: URL path for the endpoint. For example `"/my/custom/endpoint"`.
    ///   - e2ee: End-to-end encryption configuration. `.notEncrypted` by default.
    public override init(endpointURLPath: String, e2ee: WPNE2EEConfiguration = .notEncrypted) {
        super.init(endpointURLPath: endpointURLPath, e2ee: e2ee)
    }
}

/// Endpoint authenticated with a standard PowerAuth authentication code.
public class WPNEndpointAuthenticated<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    
    typealias Request = WPNHttpAuthenticatedRequest<RequestData, ResponseData>
    
    /// PowerAuth URI identifier used for authentication code computation.
    /// This can differ from the endpoint URL path.
    public let uriId: String
    
    /// Creates an endpoint authenticated with a standard PowerAuth authentication code.
    /// - Parameters:
    ///   - endpointURLPath: URL path for the endpoint. For example `"/my/custom/endpoint"`.
    ///   - uriId: PowerAuth URI identifier used for authentication code computation.
    ///   - e2ee: End-to-end encryption configuration. `.notEncrypted` by default.
    public init(endpointURLPath: String, uriId: String, e2ee: WPNE2EEConfiguration = .notEncrypted) {
        self.uriId = uriId
        super.init(endpointURLPath: endpointURLPath, e2ee: e2ee)
    }
}

/// Endpoint authenticated with a PowerAuth token authorization header.
public class WPNEndpointAuthenticatedWithToken<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    
    typealias Request = WPNHttpTokenAuthenticatedRequest<RequestData, ResponseData>
    
    /// Name of the PowerAuth token used for authorization.
    public let tokenName: String
    
    /// Creates an endpoint authenticated with a PowerAuth token authorization header.
    /// - Parameters:
    ///   - endpointURLPath: URL path for the endpoint. For example `"/my/custom/endpoint"`.
    ///   - tokenName: Name of the PowerAuth token used for authorization.
    ///   - e2ee: End-to-end encryption configuration. `.notEncrypted` by default.
    public init(endpointURLPath: String, tokenName: String, e2ee: WPNE2EEConfiguration = .notEncrypted) {
        self.tokenName = tokenName
        super.init(endpointURLPath: endpointURLPath, e2ee: e2ee)
    }
}
