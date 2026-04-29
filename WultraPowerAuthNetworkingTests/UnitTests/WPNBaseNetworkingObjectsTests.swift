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

@Suite("Networking objects")
final class WPNBaseNetworkingObjectsTests {

    private struct Payload: Codable, Equatable {
        let value: String
    }

    private struct RequestEnvelope: Decodable {
        let requestObject: Payload
    }

    @Test("Request encodes requestObject envelope")
    func requestEncodesRequestObjectEnvelope() throws {
        let request = WPNRequest(Payload(value: "hello"))

        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(RequestEnvelope.self, from: data)

        #expect(decoded.requestObject == Payload(value: "hello"))
    }

    @Test("Response decodes success envelope")
    func responseDecodesSuccessEnvelope() throws {
        let data = Data(#"{"status":"OK","responseObject":{"value":"hello"}}"#.utf8)

        let response = try JSONDecoder().decode(WPNResponse<Payload>.self, from: data)

        #expect(response.status == .Ok)
        #expect(response.responseObject == Payload(value: "hello"))
        #expect(response.responseError == nil)
    }

    @Test("Endpoint exposes response data type")
    func endpointExposesResponseDataType() {
        typealias Endpoint = WPNEndpointBasic<WPNRequest<Payload>, WPNResponse<Payload>>

        let responseType: Endpoint.ResponseData.Type = WPNResponse<Payload>.self

        #expect(responseType == WPNResponse<Payload>.self)
    }

    @Test("Response decodes error envelope")
    func responseDecodesErrorEnvelope() throws {
        let data = Data(#"{"status":"ERROR","responseObject":{"code":"INVALID_REQUEST","message":"Bad request"}}"#.utf8)

        let response = try JSONDecoder().decode(WPNResponse<Payload>.self, from: data)

        #expect(response.status == .Error)
        #expect(response.responseObject == nil)
        #expect(response.responseError?.code == "INVALID_REQUEST")
        #expect(response.responseError?.errorCode == .invalidRequest)
    }

    @Test("Array response decodes success envelope")
    func responseArrayDecodesSuccessEnvelope() throws {
        let data = Data(#"{"status":"OK","responseObject":[{"value":"first"},{"value":"second"}]}"#.utf8)

        let response = try JSONDecoder().decode(WPNResponseArray<Payload>.self, from: data)

        #expect(response.status == .Ok)
        #expect(response.responseObject == [Payload(value: "first"), Payload(value: "second")])
    }

    @Test("REST API error resolves known code")
    func restApiErrorResolvesKnownCode() {
        let error = WPNRestApiError(code: "TOO_MANY_REQUESTS", message: "Slow down")

        #expect(error.errorCode == .tooManyRequests)
        #expect(error.message == "Slow down")
    }
}
