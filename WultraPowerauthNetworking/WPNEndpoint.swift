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

public class WPNEndpoint<TRequestData: WPNRequestBase, TResponseData: WPNResponseBase> {
    
    let endpointURL: String
    
    init(endpointURL: String) {
        self.endpointURL = endpointURL
    }
    
    typealias Request = WPNHttpRequest<TRequestData, TResponseData>
    public typealias RequestData = TRequestData
    public typealias ResponseData = TRequestData
    public typealias Completion = (TResponseData?, WPNError?) -> Void
}

public class WPNEndpointBasic<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    public override init(endpointURL: String) {
        super.init(endpointURL: endpointURL)
    }
}

public class WPNEndpointSigned<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    
    let uriId: String
    
    public init(endpointURL: String, uriId: String) {
        self.uriId = uriId
        super.init(endpointURL: endpointURL)
    }
}

public class WPNEndpointSignedWithToken<RequestData: WPNRequestBase, ResponseData: WPNResponseBase>: WPNEndpoint<RequestData, ResponseData> {
    let tokenName: String
    
    public init(endpointURL: String, tokenName: String) {
        self.tokenName = tokenName
        super.init(endpointURL: endpointURL)
    }
}

public extension WPNEndpointBasic {
    
}
