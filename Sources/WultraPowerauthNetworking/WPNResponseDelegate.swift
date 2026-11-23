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

/// Observes responses and can restrict opted-in redirects.
public protocol WPNResponseDelegate: AnyObject {
    /// Decides whether to send the proposed follow-up request after a redirect response.
    ///
    /// Called on the main queue for each hop, only when `WPNConfig.followRedirects` is enabled.
    /// Return `false` to stop the redirect. The default implementation returns `true`.
    func shouldFollowRedirect(_ response: HTTPURLResponse, to request: URLRequest) -> Bool

    /// Called when response is received
    ///
    /// - Parameters:
    ///   - url: Called URL
    ///   - statusCode: HTTP status code (if retrieved)
    ///   - body: Data retrieved from the response
    ///   - decrypted: If the request was encrypted, this will contain decrypted body
    func responseReceived(from url: URL, statusCode: Int?, body: Data, decrypted: Data?)
}

public extension WPNResponseDelegate {
    func shouldFollowRedirect(_ response: HTTPURLResponse, to request: URLRequest) -> Bool {
        return true
    }
}
