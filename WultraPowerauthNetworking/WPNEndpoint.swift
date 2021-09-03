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

public protocol WPNEndpoint {
    
    static var url: String { get }
    static var uriId: String { get }
    
    associatedtype RequestData: WPNRequestBase
    associatedtype ResponseData: WPNResponseBase
    
    typealias Request = WPNHttpRequest<Self>
}

extension WPNEndpoint {
    
    static func request(config: WPNConfig, data: Self.RequestData, signing: Self.Request.Signing) -> Self.Request {
        return WPNHttpRequest(config: config, requestData: data, signing: signing)
    }
}
