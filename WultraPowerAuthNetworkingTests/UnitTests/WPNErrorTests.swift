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
import Testing
@testable import WultraPowerAuthNetworking

@Suite("Errors")
final class WPNErrorTests {

    private let url = URL(string: "https://example.com/error")!

    @Test("Wrap preserves nested details from an existing WPNError")
    func wrapPreservesNestedDetails() {
        let nested = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        let original = WPNError(reason: .network_generic, error: nested)
        original.httpUrlResponse = HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: nil)
        original.restApiError = WPNRestApiError(code: WPNKnownRestApiError.invalidRequest.rawValue, message: "Bad request")

        let wrapped = WPNError.wrap(.network_invalidResponseObject, original)

        #expect(wrapped.reason == .network_invalidResponseObject)
        #expect((wrapped.nestedError as NSError?)?.code == NSURLErrorTimedOut)
        #expect(wrapped.httpStatusCode == 503)
        #expect(wrapped.restApiError?.errorCode == .invalidRequest)
    }

    @Test("HTTP status code is derived from stored response")
    func httpStatusCodeUsesStoredResponse() {
        let error = WPNError(reason: .network_errorStatusCode)
        error.httpUrlResponse = HTTPURLResponse(url: url, statusCode: 401, httpVersion: nil, headerFields: nil)

        #expect(error.httpStatusCode == 401)
    }

    @Test("SSL error reason has stable raw value")
    func sslErrorReasonHasStableRawValue() {
        #expect(WPNErrorReason.network_sslError.rawValue == "network_sslError")
    }

    @Test("Network reachability is detected from nested NSError")
    func networkReachabilityIsDetected() {
        let error = WPNError(reason: .network_generic, error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet))

        #expect(error.networkIsNotReachable)
    }

    @Test("Untrusted connection is detected from nested NSError")
    func untrustedConnectionIsDetected() {
        let error = WPNError(reason: .network_generic, error: NSError(domain: NSURLErrorDomain, code: NSURLErrorServerCertificateUntrusted))

        #expect(error.networkConnectionIsNotTrusted)
    }

    @Test("PowerAuth error message is exposed")
    func powerAuthErrorMessageIsExposed() {
        let error = WPNError(
            reason: .unknown,
            error: NSError(
                domain: PowerAuthErrorDomain,
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "PowerAuth failure"]
            )
        )

        #expect(error.powerAuthErrorMessage == "PowerAuth failure")
    }

    @Test("E2EE error reason has stable raw value")
    func e2eeErrorReasonHasStableRawValue() {
        #expect(WPNErrorReason.network_e2eeError.rawValue == "network_e2eeError")
    }

    @Test("Token error reason has stable raw value")
    func tokenErrorReasonHasStableRawValue() {
        #expect(WPNErrorReason.network_tokenError.rawValue == "network_tokenError")
    }
}
