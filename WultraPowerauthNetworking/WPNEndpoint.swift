/*
 * Copyright (c) 2021, Wultra s.r.o. (www.wultra.com).
 *
 * All rights reserved. This source code can be used only for purposes specified 
 * by the given license contract signed by the rightful deputy of Wultra s.r.o. 
 * This source code can be used only by the owner of the license.
 * 
 * Any disputes arising in respect of this agreement (license) shall be brought
 * before the Municipal Court of Prague.
 *
 */

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
