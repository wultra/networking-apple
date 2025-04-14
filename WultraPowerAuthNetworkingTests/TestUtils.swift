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
import PowerAuth2
import WultraPowerAuthNetworking

class TestUtils {
    
    struct FakeData: Codable { }
    
    enum FakeEndpoint {
        typealias EndpointType = WPNEndpointBasic<WPNRequestBase, WPNResponse<FakeData>>
        static let endpoint: EndpointType = .init(endpointURLPath: "/fake/path")
    }
    
    static func createFakeService() -> WPNNetworkingService {
        let pa = PowerAuthSDK(configuration: .init(instanceId: "test", baseEndpointUrl: "https://fake.url/", configuration: "ARCB+/qxpmLCa04AyT2IPXHKED4Heu76QU+v2PtnzQbe0sYBAUEEU05t3byEUdh90CBiBvqgr4sWU7r1YTAtdpTh3EygAUL791k66wy+SZM1qELw6zdoOHNFk/s4neDDqKtIQ5E5jg=="))!
        return WPNNetworkingService(powerAuth: pa, config: .init(baseUrl: URL(string: "https://fake.url/")!), serviceName: "testservice")
    }
}
