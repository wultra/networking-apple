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
import UIKit
@testable import WultraPowerAuthNetworking

@Suite("User agent")
final class WPNUserAgentTests {

    @Test("System default uses system-provided header")
    func systemDefaultUsesSystemHeader() {
        #expect(WPNUserAgent.systemDefault.getValue() == nil)
    }

    @Test("Custom user agent returns custom value")
    func customUserAgentReturnsCustomValue() {
        #expect(WPNUserAgent.custom("Custom/1.0").getValue() == "Custom/1.0")
    }

    @Test("Library default includes stable SDK and device fragments")
    func libraryDefaultIncludesStableFragments() throws {
        let value = try #require(WPNUserAgent.libraryDefault.getValue())

        #expect(value.hasPrefix("PowerAuthNetworking/\(WPNConstants.sdkVersionName)"))
        #expect(value.contains("Apple;"))
        #expect(value.contains(UIDevice.current.systemName))
        #expect(value.contains(UIDevice.deviceModel))
        #expect(value.contains(Bundle.main.identifier ?? "??"))
    }
}
