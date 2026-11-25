//
// Copyright 2025 Wultra s.r.o.
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

@Suite("Networking service")
final class WPNNetworkingServiceTests {

    @Test("Async post cancellation")
    func asyncPostCancellation() async throws {
        let service = try TestUtils.createDummyService()
        let task = Task<WPNResponse<TestUtils.FakeData>, Error> {
            try await service.post(data: .init(), to: TestUtils.FakeEndpoint.endpoint)
        }

        await Task.yield()
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected the request to be canceled.")
        } catch let error as WPNError {
            #expect(error.reason == .canceled)
        } catch {
            Issue.record("Unexpected error: \(String(describing: error))")
        }
    }

    @Test("The session redirect delegate requires explicit opt-in", arguments: [false, true])
    func sessionRedirectPolicy(followRedirects: Bool) throws {
        let redirect = try Self.makeRedirect()
        let config = followRedirects
            ? WPNConfig(baseUrl: try #require(redirect.response.url), followRedirects: true)
            : WPNConfig(baseUrl: try #require(redirect.response.url))
        let client = WPNHttpClient(sslValidation: .default, timeout: 20, requestInterceptors: [], followRedirects: config.followRedirects)
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: redirect.request)

        let delegate = ResponseDelegate()
        client.responseDelegate = delegate
        withExtendedLifetime(delegate) {
            client.urlSession(session, task: task, willPerformHTTPRedirection: redirect.response, newRequest: redirect.request) {
                #expect($0 == (followRedirects ? redirect.request : nil))
            }
        }
    }

    @Test("The response delegate can veto a redirect only when opted in", arguments: [false, true], [false, true])
    func responseDelegateRedirectPolicy(followRedirects: Bool, allow: Bool) throws {
        let redirect = try Self.makeRedirect()
        let client = WPNHttpClient(sslValidation: .default, timeout: 20, requestInterceptors: [], followRedirects: followRedirects)
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let task = session.dataTask(with: redirect.request)
        let delegate = RedirectDecisionDelegate(allow: allow)
        client.responseDelegate = delegate
        client.urlSession(session, task: task, willPerformHTTPRedirection: redirect.response, newRequest: redirect.request) {
            #expect($0 == (followRedirects && allow ? redirect.request : nil))
        }
        #expect(delegate.redirectStatuses == (followRedirects ? [302] : []))
        #expect(delegate.proposedRequests == (followRedirects ? [redirect.request] : []))
    }

    @Test("Unfollowed redirects preserve status and never decode a success body", arguments: [false, true])
    func unfollowedRedirectResponse(hasBody: Bool) throws {
        let redirect = try Self.makeRedirect()
        let service = try TestUtils.createDummyService()
        let request = try Self.makeRequest(for: redirect.response)
        let delegate = ResponseDelegate()
        service.responseDelegate = delegate
        let data = hasBody ? Data(#"{"status":"OK","responseObject":{}}"#.utf8) : nil
        service.handleResponse(wpnRequest: request, data: data, urlResponse: redirect.response, error: nil) { result, error in
            #expect(result == nil)
            #expect(error?.reason == .network_errorStatusCode)
            #expect(error?.httpStatusCode == 302)
        }
        #expect(delegate.statusCodes == [302])
        #expect(delegate.bodies == [data ?? Data()])
    }

    @Test("A transport error takes precedence over a redirect status")
    func redirectTransportError() throws {
        let redirect = try Self.makeRedirect()
        let service = try TestUtils.createDummyService()
        let request = try Self.makeRequest(for: redirect.response)
        service.handleResponse(wpnRequest: request, data: Data(), urlResponse: redirect.response, error: URLError(.timedOut)) { result, error in
            #expect(result == nil)
            #expect(error?.reason == .network_timeOut)
            #expect(error?.httpStatusCode == 302)
        }
    }

    // MARK: - Helpers

    private static func makeRedirect() throws -> (response: HTTPURLResponse, request: URLRequest) {
        let source = try #require(URL(string: "https://service.example/start"))
        let destination = try #require(URL(string: "https://service.example/final"))
        let response = try #require(HTTPURLResponse(
            url: source,
            statusCode: 302,
            httpVersion: nil,
            headerFields: ["Location": destination.absoluteString]
        ))
        return (response, URLRequest(url: destination))
    }

    private static func makeRequest(for response: HTTPURLResponse) throws -> WPNUrlRequest<WPNResponse<TestUtils.FakeData>> {
        let url = try #require(response.url)
        return WPNUrlRequest(urlRequest: NSMutableURLRequest(url: url), url: url, encryptor: nil, jsonDecoder: JSONDecoder())
    }

    private final class ResponseDelegate: WPNResponseDelegate {
        var statusCodes: [Int?] = []
        var bodies: [Data] = []

        func responseReceived(from url: URL, statusCode: Int?, body: Data, decrypted: Data?) {
            statusCodes.append(statusCode)
            bodies.append(body)
            #expect(decrypted == nil)
        }
    }

    private final class RedirectDecisionDelegate: WPNResponseDelegate {
        let allow: Bool
        var redirectStatuses: [Int] = []
        var proposedRequests: [URLRequest] = []

        init(allow: Bool) {
            self.allow = allow
        }

        func shouldFollowRedirect(_ response: HTTPURLResponse, to request: URLRequest) -> Bool {
            redirectStatuses.append(response.statusCode)
            proposedRequests.append(request)
            return allow
        }

        func responseReceived(from url: URL, statusCode: Int?, body: Data, decrypted: Data?) {}
    }
}
