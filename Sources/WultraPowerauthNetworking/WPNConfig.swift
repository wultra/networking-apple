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

/// Configuration of the library.
public struct WPNConfig {
    
    /// Base URL for service requests.
    public let baseUrl: URL
    
    /// SSL validation strategy for the request.
    public let sslValidation: WPNSSLValidationStrategy
    
    /// The timeout interval to use when waiting for backend data.
    ///
    /// Value can be overridden for each `post` call in `WPNNetworkingService`.
    /// Default value is 20.
    public let timeoutIntervalForRequest: TimeInterval
    
    /// Property that specifies the content of the User-Agent request header.
    ///
    /// Note that this value can be override in each request by setting the User-Agent header.
    public let userAgent: WPNUserAgent
    
    /// Create instance of the config
    /// - Parameters:
    ///   - baseUrl: Base URL for service requests.
    ///   - sslValidation: SSL validation strategy for the request.
    ///                    Default value is `.default`
    ///   - timeoutIntervalForRequest: The timeout interval to use when waiting for backend data.
    ///                                Value can be overridden for each `post` call in `WPNNetworkingService`.
    ///                                Default value is 20.
    ///   - userAgent: Default User-Agent request header.
    ///                Value can be override in each `post` call in the `WPNNetworkingService`  by setting the User-Agent header.
    ///                Default value is `.libraryDefault`
    public init(baseUrl: URL, sslValidation: WPNSSLValidationStrategy = .default, timeoutIntervalForRequest: TimeInterval = 20, userAgent: WPNUserAgent = .libraryDefault) {
        self.baseUrl = baseUrl
        self.sslValidation = sslValidation
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
        self.userAgent = userAgent
    }
    
    func buildURL(_ endpoint: String) -> URL {
        
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
