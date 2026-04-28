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
import Testing
@testable import WultraPowerAuthNetworking

@Suite("Async operation")
final class WPNAsyncOperationTests {

    @Test("Cancel")
    func asyncOperationCancel() {
        var cancelledCalled = false
        let op = WPNAsyncBlockOperation({ cancelledCalled = true }) { _, _ in }
        op.cancel()
        op.markFinished()
        #expect(cancelledCalled)
        #expect(op.isCancelled)
        #expect(op.isFinished)
    }

    @Test("Cancel after finish")
    func asyncOperationCancelAfterFinish() {
        var cancelledCalled = false
        let op = WPNAsyncBlockOperation({ cancelledCalled = true }) { _, _ in }
        op.markFinished()
        op.cancel()
        #expect(cancelledCalled == false)
        #expect(op.isCancelled == false)
        #expect(op.isFinished)
    }

    @Test("Cancel notifies Operation KVO keys")
    func cancelNotifiesOperationKVOKeys() {
        let op = WPNAsyncBlockOperation({ }) { _, _ in }
        var didNotifyFinished = false
        var didNotifyCancelled = false

        let finishedObservation = op.observe(\.isFinished, options: [.new]) { _, change in
            didNotifyFinished = change.newValue == true
        }
        let cancelledObservation = op.observe(\.isCancelled, options: [.new]) { _, change in
            didNotifyCancelled = change.newValue == true
        }

        op.cancel()

        withExtendedLifetime((finishedObservation, cancelledObservation)) {
            #expect(didNotifyFinished)
            #expect(didNotifyCancelled)
        }
    }

    @Test("Completion runs on assigned queue")
    func completionRunsOnAssignedQueue() {
        let completionQueue = DispatchQueue(label: "WPNAsyncOperationTests.completion")
        let key = DispatchSpecificKey<String>()
        let semaphore = DispatchSemaphore(value: 0)
        var queueTag: String?

        completionQueue.setSpecific(key: key, value: "completion")

        let op = WPNAsyncBlockOperation { _, markFinished in
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 0.05)
                markFinished {
                    queueTag = DispatchQueue.getSpecific(key: key)
                    semaphore.signal()
                }
            }
        }
        op.completionQueue = completionQueue

        let queue = OperationQueue()
        queue.addOperation(op)

        #expect(semaphore.wait(timeout: .now() + 2) == .success)
        #expect(queueTag == "completion")
    }

    @Test("Dependencies delay dependent operations")
    func dependenciesDelayDependentOperations() {
        let recorder = EventRecorder()
        let first = SleepingAsyncOperation(operationId: "first", delay: 0.08, recorder: recorder)
        let second = SleepingAsyncOperation(operationId: "second", delay: 0.02, recorder: recorder)
        second.addDependency(first)

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        queue.addOperations([second, first], waitUntilFinished: true)

        #expect(recorder.snapshot() == [
            "start-first",
            "finish-first",
            "start-second",
            "finish-second"
        ])
        #expect(first.isFinished)
        #expect(second.isFinished)
    }

    // MARK: - Helpers

    private final class EventRecorder {
        private let lock = NSLock()
        private var values = [String]()

        func record(_ value: String) {
            lock.lock()
            values.append(value)
            lock.unlock()
        }

        func snapshot() -> [String] {
            lock.lock()
            defer { lock.unlock() }
            return values
        }
    }

    private final class SleepingAsyncOperation: WPNAsyncOperation, @unchecked Sendable {
        private let operationId: String
        private let delay: TimeInterval
        private let recorder: EventRecorder

        init(operationId: String, delay: TimeInterval, recorder: EventRecorder) {
            self.operationId = operationId
            self.delay = delay
            self.recorder = recorder
            super.init()
        }

        override func started() {
            recorder.record("start-\(operationId)")
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: self.delay)
                self.recorder.record("finish-\(self.operationId)")
                self.markFinished()
            }
        }
    }
}
