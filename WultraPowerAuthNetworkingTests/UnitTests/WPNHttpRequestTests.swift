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

@Suite("HTTP request")
final class WPNHttpRequestTests {

    private let url = URL(string: "https://example.com/test")!
    private let powerAuth: PowerAuthSDK

    init() throws {
        powerAuth = try TestUtils.createDummyService().powerAuth
    }

    @Test("URL request merges headers and timeout")
    func urlRequestMergesHeadersAndTimeout() async throws {
        let request = makeBasicRequest(timeoutInterval: 12)
        request.addHeaders([
            "Accept": "application/custom+json",
            "X-Test": "value"
        ])

        let wpnRequest = try await buildUrlRequest(request)
        let urlRequest = wpnRequest.urlRequest
        let body = try #require(urlRequest.httpBody)
        let decodedBody = try JSONDecoder().decode(RequestEnvelope.self, from: body)

        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.timeoutInterval == 12)
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/custom+json")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Test") == "value")
        #expect(decodedBody == RequestEnvelope(requestObject: Payload(value: "hello")))
    }

    @Test("buildUrlRequest fails when encoding fails")
    func buildUrlRequestFailsWhenEncodingFails() async {
        let request = WPNHttpPlainRequest<FailingRequest, TestResponse>(
            url,
            requestData: WPNRequest(FailingPayload()),
            decoder: JSONDecoder(),
            encoder: JSONEncoder()
        )

        let result = await buildUrlRequestResult(request)
        switch result {
        case .success:
            Issue.record("Expected encoding failure.")
        case .failure(let error):
            #expect(error.reason == .network_invalidRequestObject)
        }
    }

    @Test("Process result decodes plain success envelope")
    func processResultDecodesPlainSuccessEnvelope() {
        let wpnRequest = makePlainWpnRequest()
        let data = Data(#"{"status":"OK","responseObject":{"value":"done"}}"#.utf8)

        switch wpnRequest.processResult(data: data) {
        case .success(let response, _):
            #expect(response.status == .ok)
            #expect(response.responseObject == Payload(value: "done"))
        case .failure(let error):
            Issue.record("Expected a decoded response, got error: \(error)")
        }
    }

    @Test("Process result decodes plain error envelope")
    func processResultDecodesPlainErrorEnvelope() {
        let wpnRequest = makePlainWpnRequest()
        let data = Data(#"{"status":"ERROR","responseObject":{"code":"INVALID_REQUEST","message":"Bad request"}}"#.utf8)

        switch wpnRequest.processResult(data: data) {
        case .success(let response, _):
            #expect(response.status == .error)
            #expect(response.responseError?.errorCode == .invalidRequest)
        case .failure(let error):
            Issue.record("Expected a decoded error envelope, got error: \(error)")
        }
    }

    @Test("Process result fails on malformed response")
    func processResultFailsOnMalformedResponse() {
        let wpnRequest = makePlainWpnRequest()
        let data = Data(#"{"responseObject":{"value":"missing status"}}"#.utf8)

        switch wpnRequest.processResult(data: data) {
        case .success:
            Issue.record("Expected malformed data to fail decoding.")
        case .failure:
            break
        }
    }

    // MARK: - Helpers

    private struct Payload: Codable, Equatable {
        let value: String
    }

    private struct RequestEnvelope: Decodable, Equatable {
        let requestObject: Payload
    }

    private struct FailingPayload: Encodable {
        func encode(to encoder: Encoder) throws {
            throw Failure.encodingFailed
        }
    }

    private enum Failure: Error {
        case encodingFailed
    }

    private typealias TestRequest = WPNRequest<Payload>
    private typealias TestResponse = WPNResponse<Payload>
    private typealias FailingRequest = WPNRequest<FailingPayload>

    private func makeBasicRequest(timeoutInterval: TimeInterval? = nil) -> WPNHttpPlainRequest<TestRequest, TestResponse> {
        WPNHttpPlainRequest(
            url,
            requestData: WPNRequest(Payload(value: "hello")),
            decoder: JSONDecoder(),
            encoder: JSONEncoder(),
            timeoutInterval: timeoutInterval
        )
    }

    private func makePlainWpnRequest() -> WPNUrlRequest<TestResponse> {
        WPNUrlRequest(
            urlRequest: URLRequest(url: url),
            url: url,
            encryptor: nil,
            jsonDecoder: JSONDecoder()
        )
    }

    private func buildUrlRequest<Req: WPNRequestBase, Resp: WPNResponseBase>(
        _ request: WPNHttpPlainRequest<Req, Resp>,
        e2ee: WPNE2EEConfiguration = .notEncrypted
    ) async throws -> WPNUrlRequest<Resp> {
        try await withCheckedThrowingContinuation { continuation in
            request.buildUrlRequest(powerAuth: powerAuth, e2ee: e2ee) { result in
                continuation.resume(with: result)
            }
        }
    }

    private func buildUrlRequestResult<Req: WPNRequestBase, Resp: WPNResponseBase>(
        _ request: WPNHttpPlainRequest<Req, Resp>,
        e2ee: WPNE2EEConfiguration = .notEncrypted
    ) async -> Result<WPNUrlRequest<Resp>, WPNError> {
        await withCheckedContinuation { continuation in
            request.buildUrlRequest(powerAuth: powerAuth, e2ee: e2ee) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
