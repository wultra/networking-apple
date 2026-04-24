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

final class JSONTests: XCTestCase {
    
    private var service: WPNNetworkingService!
    
    override func setUp() {
        WPNLogger.verboseLevel = .debug
        service = TestUtils.createFakeService()
    }

    func testDateDeserialization() {
        
        struct TestObject: Codable {
            let test: Date
        }
        
        // the string is valid, but Apple parser cannot parse it by default...
        let invalidISO8601Data = """
            {"test":"2024-03-19T12:29:29.554668Z"}
        """.data(using: .utf8)!
        
        // valid string that apple can parse by defualt
        let validISO8601Data = """
            {"test":"2023-12-06T07:54:06+0100"}
        """.data(using: .utf8)!
        
        // Foundation behavior changed over time, so the built-in decoder may or may not parse
        // fractional seconds on the current Xcode/runtime.
        let oldDecoder = JSONDecoder()
        oldDecoder.dateDecodingStrategy = .iso8601
        
        // default decoder we use in the SDK
        let defaultDecoder = service.jsonDecoder
        
        // This result is runtime-dependent and is not part of the SDK contract.
        let oldInvalidResult = try? oldDecoder.decode(TestObject.self, from: invalidISO8601Data)
        let oldValidDecoded = try? oldDecoder.decode(TestObject.self, from: validISO8601Data)
        XCTAssertNotNil(oldValidDecoded)
        _ = oldInvalidResult
        
        // "invalid" string parsed with the the default decoder should be OK
        let defaultInvalidResult = try? defaultDecoder.decode(TestObject.self, from: invalidISO8601Data)
        XCTAssertNotNil(defaultInvalidResult)
        
        // valid string should be parsed with the default decoder
        let defaultValidDecoded = try? defaultDecoder.decode(TestObject.self, from: validISO8601Data)
        XCTAssertNotNil(defaultValidDecoded)
    }
}
