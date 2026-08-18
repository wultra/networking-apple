//
// Copyright 2026 Wultra s.r.o.
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

/// Interceptor that can modify the final HTTP request right before it is sent via `URLSession`.
///
/// Interceptors configured in `WPNConfig.requestInterceptors` are applied in declaration order,
/// after headers, PowerAuth authorization, E2EE encryption, and the request body were already set
/// on the request.
///
/// - Warning: Don't modify the `X-PowerAuth-*` headers or the request body - doing so could lead
///   to the backend rejecting the request.
public protocol WPNInterceptor {
    /// Called before the request is executed. May be called from a background thread.
    /// - Parameter request: The final, mutable URL request to be modified.
    func processRequest(_ request: NSMutableURLRequest)
}

/// Adapts a `PowerAuthHttpRequestInterceptor` so it can be used as a `WPNInterceptor`.
public struct WPNPowerAuthInterceptorAdapter: WPNInterceptor {

    private let interceptor: PowerAuthHttpRequestInterceptor

    public init(_ interceptor: PowerAuthHttpRequestInterceptor) {
        self.interceptor = interceptor
    }

    public func processRequest(_ request: NSMutableURLRequest) {
        interceptor.processRequest(request)
    }
}

public extension PowerAuthHttpRequestInterceptor {
    /// Wraps this interceptor so it can be used as a `WPNInterceptor` in `WPNConfig.requestInterceptors`.
    var asWPNInterceptor: WPNInterceptor {
        WPNPowerAuthInterceptorAdapter(self)
    }
}


extension Array where Element == WPNInterceptor {
    /// Applies all interceptors, in declaration order, to the given request, in place.
    func apply(to request: NSMutableURLRequest) {
        for interceptor in self {
            interceptor.processRequest(request)
        }
    }
}
