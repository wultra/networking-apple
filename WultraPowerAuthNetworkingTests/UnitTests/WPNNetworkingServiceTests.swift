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
}
