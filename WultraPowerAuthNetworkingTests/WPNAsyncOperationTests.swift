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
@testable import WultraPowerAuthNetworking

final class WPNAsyncOperationTests: XCTestCase {

    func testCancel() {
        
        var cancelledCalled = false
        let op = WPNAsyncBlockOperation({ cancelledCalled = true }) { _, _ in }
        op.cancel()
        op.markFinished()
        XCTAssertTrue(cancelledCalled)
        XCTAssertTrue(op.isCancelled)
        XCTAssertTrue(op.isFinished)
    }
    
    func testFailedCancel() {
        
        var cancelledCalled = false
        let op = WPNAsyncBlockOperation({ cancelledCalled = true }) { _, _ in }
        op.markFinished()
        op.cancel()
        XCTAssertFalse(cancelledCalled)
        XCTAssertFalse(op.isCancelled)
        XCTAssertTrue(op.isFinished)
    }
}
