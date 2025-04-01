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

import XCTest
import PowerAuth2
@testable import WultraPowerAuthNetworking

final class WPNNetworkingServiceTests: XCTestCase {
    
    struct FakeData: Codable { }
    
    enum FakeEndpoint {
        typealias EndpointType = WPNEndpointBasic<WPNRequestBase, WPNResponse<FakeData>>
        static let endpoint: EndpointType = .init(endpointURLPath: "/fake/path")
    }
    
    private var pa: PowerAuthSDK!
    private var service: WPNNetworkingService!
    
    override func setUp() {
        WPNLogger.verboseLevel = .debug
        pa = PowerAuthSDK(configuration: .init(instanceId: "test", baseEndpointUrl: "https://fake.url/", configuration: "ARCB+/qxpmLCa04AyT2IPXHKED4Heu76QU+v2PtnzQbe0sYBAUEEU05t3byEUdh90CBiBvqgr4sWU7r1YTAtdpTh3EygAUL791k66wy+SZM1qELw6zdoOHNFk/s4neDDqKtIQ5E5jg=="))
        service = WPNNetworkingService(powerAuth: pa, config: .init(baseUrl: URL(string: "https://fake.url/")!), serviceName: "testservice")
    }

    func testCancel() {
        
        let exp = XCTestExpectation(description: "Wait for cancel")
        
        var op: WPNAsyncBlockOperation?
        op = service.post(data: .init(), to: FakeEndpoint.endpoint) { resp, error in
            XCTAssertEqual(error?.reason, WPNErrorReason.canceled)
            exp.fulfill()
        } as? WPNAsyncBlockOperation
        let delegate = WPNAsyncOperationHandler(onStart: { op?.cancel() }, onCancel: { })
        op!.delegate = delegate
        
        let waiter = XCTWaiter()
        waiter.wait(for: [exp], timeout: 10)
    }
}

final class WPNAsyncOperationHandler: WPNAsyncOperationDelegate {
    
    private let onStart: () -> Void
    private let onCancel: () -> Void
    
    init(onStart: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.onStart = onStart
        self.onCancel = onCancel
    }
    
    func didStartAsyncOperation(_ operation: WPNAsyncOperation) {
        onStart()
    }
    
    func didCancelAsyncOperation(_ operation: WPNAsyncOperation) {
        onCancel()
    }
}
