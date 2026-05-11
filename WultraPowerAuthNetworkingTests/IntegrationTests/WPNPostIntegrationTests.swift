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

// MARK: - Success tests

@Suite("POST integration - Success")
final class WPNPostSuccessIntegrationTests {

    @Test("Plain POST verifies transport to jsonplaceholder")
    func plainPost() async throws {
        let service = try TestUtils.createDummyService(url: "https://jsonplaceholder.typicode.com")
        let recorder = ResponseRecorder()
        service.responseDelegate = recorder

        do {
            _ = try await service.post(data: WPNRequestBase(), to: TestEndpoints.Todo.endpoint)
            Issue.record("Expected error because jsonplaceholder does not return WPN envelope format")
        } catch let error as WPNError {
            // Transport succeeded but jsonplaceholder either returns a non-200
            // status or a body that lacks the WPN envelope format
            let isExpectedError = error.reason == .network_errorStatusCode || error.reason == .network_invalidResponseObject
            #expect(isExpectedError)
        }

        // Confirm the response delegate received exactly one response
        #expect(recorder.responses.count == 1)
        let recorded = try #require(recorder.responses.first)
        #expect(recorded.statusCode == 201) // this API returns 201 on success
        #expect(!recorded.body.isEmpty)
    }

    @Test("E2EE POST with application scope encryption")
    func e2eePost() async throws {
        let loaded = try #require(TestConfiguration.load())
        let proxy = IntegrationProxy(config: loaded.config)
        try await proxy.initializePowerauth()
        try await proxy.prepareActivation()
        defer { Task { await proxy.cleanup() } }

        let service = try proxy.createNetworkingService(url: loaded.enrollmentServerOnboardingUrl)
        let request = WPNRequest(TestEndpoints.StartRequest(identification: ["clientNumber": UUID().uuidString]))

        let response = try await service.post(data: request, to: TestEndpoints.Start.endpoint)
        #expect(response.status == .ok)
    }

    @Test("Authenticated POST with PowerAuth authentication code")
    func authenticatedPost() async throws {
        let loaded = try #require(TestConfiguration.load())
        let proxy = IntegrationProxy(config: loaded.config)
        try await proxy.initializePowerauth()
        try await proxy.prepareActivation()
        defer { Task { await proxy.cleanup() } }

        let service = try proxy.createNetworkingService(url: loaded.operationsServerUrl)
        let response = try await service.post(
            data: WPNRequestBase(),
            authenticatedWith: .possessionWithPassword(password: proxy.pin),
            to: TestEndpoints.History.endpoint
        )
        #expect(response.status == .ok)
    }

    @Test("Token-authenticated POST with PowerAuth token")
    func tokenPost() async throws {
        let loaded = try #require(TestConfiguration.load())
        let proxy = IntegrationProxy(config: loaded.config)
        try await proxy.initializePowerauth()
        try await proxy.prepareActivation()
        defer { Task { await proxy.cleanup() } }

        let service = try proxy.createNetworkingService(url: loaded.operationsServerUrl)
        let response = try await service.post(
            data: WPNRequestBase(),
            authenticatedWith: .possessionWithPassword(password: proxy.pin),
            to: TestEndpoints.OperationList.endpoint
        )
        #expect(response.status == .ok)
    }
}

// MARK: - Failure tests

@Suite("POST integration - Failure")
final class WPNPostFailureIntegrationTests {

    @Test("E2EE activationScope without activation")
    func e2eePostUnactivated() async throws {

        let loaded = try #require(TestConfiguration.load())
        let proxy = IntegrationProxy(config: loaded.config)
        try await proxy.initializePowerauth()
        defer { Task { await proxy.cleanup() } }

        let service = try proxy.createNetworkingService(url: loaded.enrollmentServerOnboardingUrl)

        do {
            _ = try await service.post(data: WPNRequest(WPNRequestBase()), to: TestEndpoints.FailingStart.endpoint)
            Issue.record("Expected error for malformed E2EE payload")
        } catch let error as WPNError {
            #expect(error.reason == .network_e2eeError)
        }
    }

    @Test("Authenticated POST with wrong authentication")
    func authenticatedPostWrongPin() async throws {
        let loaded = try #require(TestConfiguration.load())
        let proxy = IntegrationProxy(config: loaded.config)
        try await proxy.initializePowerauth()
        try await proxy.prepareActivation()
        defer { Task { await proxy.cleanup() } }

        let service = try proxy.createNetworkingService(url: loaded.operationsServerUrl)
        do {
            _ = try await service.post(
                data: WPNRequestBase(),
                authenticatedWith: .possessionWithPassword(password: "0000"),
                to: TestEndpoints.History.endpoint
            )
            Issue.record("Request should have failed with wrong PIN but succeeded")
        } catch let error as WPNError {
            #expect(error.reason == .network_generic)
            #expect(error.restApiError?.errorCode == .authenticationFailure)
        }
    }
}

// MARK: - Shared helpers

/// Records responses received through `WPNResponseDelegate` for test assertions.
private final class ResponseRecorder: WPNResponseDelegate, @unchecked Sendable {

    struct Entry {
        let url: URL
        let statusCode: Int?
        let body: Data
    }

    private(set) var responses: [Entry] = []

    func responseReceived(from url: URL, statusCode: Int?, body: Data, decrypted: Data?) {
        responses.append(Entry(url: url, statusCode: statusCode, body: body))
    }
}

/// Endpoints reimplemented for testing, inspired by digital-onboarding and mtoken SDKs.
private enum TestEndpoints {

    /// Plain endpoint for jsonplaceholder (no auth, no e2ee).
    enum Todo {
        typealias EndpointType = WPNEndpointBasic<WPNRequestBase, WPNResponseBase>
        static let endpoint: EndpointType = .init(endpointURLPath: "/posts")
    }

    /// E2EE endpoint inspired by digital-onboarding Start (application scope).
    enum Start {
        typealias EndpointType = WPNEndpointBasic<WPNRequest<StartRequest>, WPNResponse<ProcessResponse>>
        static var endpoint: EndpointType { .init(endpointURLPath: "/api/onboarding/start", e2ee: .applicationScope) }
    }

    /// Authenticated endpoint inspired by mtoken History.
    enum History {
        typealias EndpointType = WPNEndpointAuthenticated<WPNRequestBase, WPNResponseBase>
        static let endpoint: EndpointType = .init(endpointURLPath: "/api/auth/token/app/operation/history", uriId: "/operation/history")
    }

    /// Token-authenticated endpoint inspired by mtoken List.
    enum OperationList {
        typealias EndpointType = WPNEndpointAuthenticatedWithToken<WPNRequestBase, WPNResponseBase>
        static let endpoint: EndpointType = .init(endpointURLPath: "/api/auth/token/app/operation/list", tokenName: "possession_universal")
    }

    /// E2EE endpoint with a deliberately failing on wrong activation scope
    enum FailingStart {
        typealias EndpointType = WPNEndpointBasic<WPNRequest<WPNRequestBase>, WPNResponseBase>
        static var endpoint: EndpointType { .init(endpointURLPath: "/api/onboarding/start", e2ee: .activationScope) }
    }

    // MARK: - Models

    struct StartRequest: Codable {
        let identification: [String: String]
    }

    struct ProcessResponse: Codable {
        let processId: String?
        let onboardingStatus: String?
    }
}

// MARK: - Networking service factory

extension IntegrationProxy {

    /// Creates a `WPNNetworkingService` pointed at the given URL using this
    /// proxy's PowerAuth instance. Throws `IntegrationError.powerAuthNotInitialized`
    /// when called before `initializePowerauth()`.
    func createNetworkingService(url: String, serviceName: String = UUID().uuidString) throws -> WPNNetworkingService {
        guard let powerAuth else {
            throw IntegrationError.powerAuthNotInitialized
        }
        WPNLogger.verboseLevel = .debug
        return WPNNetworkingService(
            powerAuth: powerAuth,
            config: .init(baseUrl: try TestUtils.createURL(string: url)),
            serviceName: serviceName
        )
    }
}
