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

public struct WPNConfig {
    
    /// Base URL for service requests.
    public let baseUrl: URL
    
    /// SSL validation strategy for the request.
    public let sslValidation: WPNSSLValidationStrategy
    
    public init(baseUrl: URL, sslValidation: WPNSSLValidationStrategy) {
        self.baseUrl = baseUrl
        self.sslValidation = sslValidation
    }
    
    public func buildURL(_ endpoint: String) -> URL {
        
        var relativePath = endpoint
        var url = baseUrl
        
        // if relative path starts with "/", lets remove it to create valid URL
        if relativePath.hasPrefix("/") {
            relativePath.removeFirst()
        }
        
        url.appendPathComponent(relativePath)
        
        return url
    }
}
