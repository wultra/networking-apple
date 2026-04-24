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
import Testing
@testable import WultraPowerAuthNetworking

@Suite("Config")
final class WPNConfigTests {

    @Test("Build URL strips leading slash")
    func buildURLStripsLeadingSlash() {
        let config = WPNConfig(baseUrl: URL(string: "https://example.com/api")!)

        let url = config.buildURL("/v1/action")

        #expect(url.absoluteString == "https://example.com/api/v1/action")
    }

    @Test("Build URL appends relative path")
    func buildURLAppendsRelativePath() {
        let config = WPNConfig(baseUrl: URL(string: "https://example.com/api/")!)

        let url = config.buildURL("v2/items")

        #expect(url.absoluteString == "https://example.com/api/v2/items")
    }

    @Test("Build URL handles both trailing and leading slash")
    func buildURLHandlesBothSlashes() {
        let config = WPNConfig(baseUrl: URL(string: "https://example.com/api/")!)

        let url = config.buildURL("/v1/action")

        #expect(url.absoluteString == "https://example.com/api/v1/action")
    }

    @Test("Build URL handles no trailing and no leading slash")
    func buildURLHandlesNoSlashes() {
        let config = WPNConfig(baseUrl: URL(string: "https://example.com/api")!)

        let url = config.buildURL("v2/items")

        #expect(url.absoluteString == "https://example.com/api/v2/items")
    }
}

@Suite("SSL validation")
final class WPNSSLValidationStrategyTests {

    @Test("Default strategy uses default handling")
    func defaultStrategyUsesDefaultHandling() {
        var disposition: URLSession.AuthChallengeDisposition?

        WPNSSLValidationStrategy.default.validate(challenge: makeChallenge()) { resolvedDisposition, _ in
            disposition = resolvedDisposition
        }

        #expect(disposition == .performDefaultHandling)
    }

    @Test("No-validation falls back when trust is missing")
    func noValidationFallsBackWhenTrustIsMissing() {
        var disposition: URLSession.AuthChallengeDisposition?

        WPNSSLValidationStrategy.noValidation.validate(challenge: makeChallenge()) { resolvedDisposition, _ in
            disposition = resolvedDisposition
        }

        #expect(disposition == .performDefaultHandling)
    }

    @Test("SSL pinning accepts validated challenge")
    func sslPinningAcceptsValidatedChallenge() {
        var disposition: URLSession.AuthChallengeDisposition?

        WPNSSLValidationStrategy.sslPinning(DummyPinningProvider(shouldValidate: true))
            .validate(challenge: makeChallenge()) { resolvedDisposition, _ in
                disposition = resolvedDisposition
            }

        #expect(disposition == .performDefaultHandling)
    }

    @Test("SSL pinning rejects invalid challenge")
    func sslPinningRejectsInvalidChallenge() {
        var disposition: URLSession.AuthChallengeDisposition?

        WPNSSLValidationStrategy.sslPinning(DummyPinningProvider(shouldValidate: false))
            .validate(challenge: makeChallenge()) { resolvedDisposition, _ in
                disposition = resolvedDisposition
            }

        #expect(disposition == .cancelAuthenticationChallenge)
    }

    // MARK: - Helpers

    private func makeChallenge() -> URLAuthenticationChallenge {
        let protectionSpace = URLProtectionSpace(
            host: "example.com",
            port: 443,
            protocol: "https",
            realm: nil,
            authenticationMethod: NSURLAuthenticationMethodServerTrust
        )

        return URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: DummyChallengeSender()
        )
    }

    private final class DummyPinningProvider: WPNPinningProvider {
        private let shouldValidate: Bool

        init(shouldValidate: Bool) {
            self.shouldValidate = shouldValidate
        }

        func validate(challenge: URLAuthenticationChallenge) -> Bool {
            shouldValidate
        }
    }

    private final class DummyChallengeSender: NSObject, URLAuthenticationChallengeSender {
        func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) { }
        func continueWithoutCredential(for challenge: URLAuthenticationChallenge) { }
        func cancel(_ challenge: URLAuthenticationChallenge) { }
        func performDefaultHandling(for challenge: URLAuthenticationChallenge) { }
        func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) { }
    }
}
