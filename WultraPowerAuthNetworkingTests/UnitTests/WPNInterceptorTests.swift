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

@Suite("Interceptor")
final class WPNInterceptorTests {

    private let url = URL(string: "https://example.com/test")!

    @Test("No interceptors leave the request untouched")
    func defaultBehaviorWithoutInterceptors() {
        var request = URLRequest(url: url)
        request.addValue("value", forHTTPHeaderField: "X-Original")

        let interceptors: [WPNInterceptor] = []
        let result = interceptors.apply(to: request)

        #expect(result.allHTTPHeaderFields == ["X-Original": "value"])
        #expect(result.url == url)
    }

    @Test("Custom interceptor modifies the request")
    func customInterceptorModifiesRequest() {
        let interceptor = BlockInterceptor { request in
            request.addValue("abc-123", forHTTPHeaderField: "X-Correlation-ID")
        }

        let result = [interceptor].apply(to: URLRequest(url: url))

        #expect(result.value(forHTTPHeaderField: "X-Correlation-ID") == "abc-123")
    }

    @Test("PowerAuth interceptor is compatible via its adapter")
    func powerAuthInterceptorIsCompatibleViaAdapter() {
        let paInterceptor = FakePowerAuthInterceptor { request in
            request.addValue("pa-value", forHTTPHeaderField: "X-PowerAuth-Custom")
        }

        let result = [paInterceptor.asWPNInterceptor].apply(to: URLRequest(url: url))

        #expect(result.value(forHTTPHeaderField: "X-PowerAuth-Custom") == "pa-value")
    }

    @Test("Interceptors are applied in declaration order")
    func interceptorsAreAppliedInDeclarationOrder() {
        var callOrder: [String] = []
        let first = BlockInterceptor { request in
            callOrder.append("first")
            request.setValue("first", forHTTPHeaderField: "X-Order")
        }
        let second = BlockInterceptor { request in
            callOrder.append("second")
            request.setValue("second", forHTTPHeaderField: "X-Order")
        }

        let result = [first, second].apply(to: URLRequest(url: url))

        #expect(callOrder == ["first", "second"])
        #expect(result.value(forHTTPHeaderField: "X-Order") == "second")
    }

    @Test("Interceptor can override a header set during request construction")
    func interceptorCanOverrideExistingHeader() {
        var request = URLRequest(url: url)
        request.addValue("en", forHTTPHeaderField: "Accept-Language")

        let interceptor = BlockInterceptor { request in
            request.setValue("cs", forHTTPHeaderField: "Accept-Language")
        }

        let result = [interceptor].apply(to: request)

        #expect(result.value(forHTTPHeaderField: "Accept-Language") == "cs")
    }

    // MARK: - Helpers

    private final class BlockInterceptor: WPNInterceptor {
        private let block: (NSMutableURLRequest) -> Void

        init(_ block: @escaping (NSMutableURLRequest) -> Void) {
            self.block = block
        }

        func processRequest(_ request: NSMutableURLRequest) {
            block(request)
        }
    }

    private final class FakePowerAuthInterceptor: NSObject, PowerAuthHttpRequestInterceptor {
        private let block: (NSMutableURLRequest) -> Void

        init(_ block: @escaping (NSMutableURLRequest) -> Void) {
            self.block = block
        }

        func processRequest(_ request: NSMutableURLRequest) {
            block(request)
        }
    }
}
