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
    
    init(endpointURLPath: String) {
        self.endpointURLPath = endpointURLPath
    }
    
    typealias Request = WPNHttpRequest<TRequestData, TResponseData>
    /// Request data for the endpoint.
    public typealias RequestData = TRequestData
    /// Response data for the endpoint.
    public typealias ResponseData = TRequestData
    /// Completion called when call on the endpoint ends.
    public typealias Completion = (TResponseData?, WPNError?) -> Void
}

/// Basic endpoint - not signed.
public class WPNEndpointBasic<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    public override init(endpointURLPath: String) {
        super.init(endpointURLPath: endpointURLPath)
    }
}

public class WPNEndpointSigned<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    
    let uriId: String
    
    public init(endpointURLPath: String, uriId: String) {
        self.uriId = uriId
        super.init(endpointURLPath: endpointURLPath)
    }
}

public class WPNEndpointSignedWithToken<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    let tokenName: String
    
    public init(endpointURLPath: String, tokenName: String) {
        self.tokenName = tokenName
        super.init(endpointURLPath: endpointURLPath)
    }
}

public extension WPNEndpointBasic {
    
}
