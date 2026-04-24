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

    @Test("Basic request does not require signature")
    func basicRequestDoesNotRequireSignature() {
        let request = makeBasicRequest()

        #expect(request.needsSignature == false)
        #expect(request.needsTokenSignature == false)
    }

    @Test("Signed request requires PowerAuth signature")
    func signedRequestRequiresSignature() {
        let request = WPNHttpRequest<TestRequest, TestResponse>(
            url,
            uriId: "/operation/sign",
            auth: PowerAuthAuthentication.possession(),
            requestData: WPNRequest(Payload(value: "hello")),
            decoder: JSONDecoder(),
            encoder: JSONEncoder()
        )

        #expect(request.needsSignature)
        #expect(request.needsTokenSignature == false)
    }

    @Test("Token-signed request requires token signature")
    func tokenSignedRequestRequiresTokenSignature() {
        let request = WPNHttpRequest<TestRequest, TestResponse>(
            url,
            tokenName: "access-token",
            auth: PowerAuthAuthentication.possession(),
            requestData: WPNRequest(Payload(value: "hello")),
            decoder: JSONDecoder(),
            encoder: JSONEncoder()
        )

        #expect(request.needsSignature == false)
        #expect(request.needsTokenSignature)
    }

    @Test("URL request merges headers and timeout")
    func urlRequestMergesHeadersAndTimeout() throws {
        let request = makeBasicRequest()
        request.timeoutInterval = 12
        request.addHeaders([
            "Accept": "application/custom+json",
            "X-Test": "value"
        ])

        let urlRequest = request.buildUrlRequest(encryptor: nil)
        let body = try #require(urlRequest.httpBody)
        let decodedBody = try JSONDecoder().decode(RequestEnvelope.self, from: body)

        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.timeoutInterval == 12)
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/custom+json")
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Test") == "value")
        #expect(decodedBody == RequestEnvelope(requestObject: Payload(value: "hello")))
    }

    @Test("Request data stays nil when encoding fails")
    func requestDataStaysNilWhenEncodingFails() {
        let request = WPNHttpRequest<FailingRequest, TestResponse>(
            url,
            requestData: WPNRequest(FailingPayload()),
            decoder: JSONDecoder(),
            encoder: JSONEncoder()
        )

        #expect(request.requestData == nil)
        #expect(request.buildUrlRequest(encryptor: nil).httpBody == nil)
    }

    @Test("Process result decodes plain success envelope")
    func processResultDecodesPlainSuccessEnvelope() {
        let request = makeBasicRequest()
        let data = Data(#"{"status":"OK","responseObject":{"value":"done"}}"#.utf8)

        switch request.processResult(data: data, encryptor: nil) {
        case .plain(let response):
            #expect(response.status == .Ok)
            #expect(response.responseObject == Payload(value: "done"))
        case .encrypted:
            Issue.record("Expected a plain response for a non-encrypted request.")
        case .failed(let error):
            Issue.record("Expected a decoded response, got error: \(error)")
        }
    }

    @Test("Process result decodes plain error envelope")
    func processResultDecodesPlainErrorEnvelope() {
        let request = makeBasicRequest()
        let data = Data(#"{"status":"ERROR","responseObject":{"code":"INVALID_REQUEST","message":"Bad request"}}"#.utf8)

        switch request.processResult(data: data, encryptor: nil) {
        case .plain(let response):
            #expect(response.status == .Error)
            #expect(response.responseError?.errorCode == .invalidRequest)
        case .encrypted:
            Issue.record("Expected a plain response for a non-encrypted request.")
        case .failed(let error):
            Issue.record("Expected a decoded error envelope, got error: \(error)")
        }
    }

    @Test("Process result fails on malformed response")
    func processResultFailsOnMalformedResponse() {
        let request = makeBasicRequest()
        let data = Data(#"{"responseObject":{"value":"missing status"}}"#.utf8)

        switch request.processResult(data: data, encryptor: nil) {
        case .plain, .encrypted:
            Issue.record("Expected malformed data to fail decoding.")
        case .failed:
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

    private func makeBasicRequest() -> WPNHttpRequest<TestRequest, TestResponse> {
        WPNHttpRequest(
            url,
            requestData: WPNRequest(Payload(value: "hello")),
            decoder: JSONDecoder(),
            encoder: JSONEncoder()
        )
    }
}
