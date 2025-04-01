//
// Copyright 2020 Wultra s.r.o.
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

/** Async operation that takes block as main execution article.
 
 To properly use this class, you need to pass execution block and when the block finishes any
 asynchronous work, call `completion` block that is passed as 2nd parameter to this block.
*/
open class WPNAsyncBlockOperation: WPNAsyncOperation {
    
    /// Type of block that needs to be passed in init
    ///
    /// - Parameter this: Reference to this operation
    /// - Parameter markFinished: Call this completion block to mark operation as finished. You can pass closure
    ///   that will complete this operation to be sure things get called in proper order on proper queue.
    public typealias ExecutionBlock = (_ this: WPNAsyncBlockOperation, _ markFinished: @escaping MarkFinishedBlock) -> Void
    public typealias MarkFinishedBlock = ((() -> Void)?) -> Void
    
    private let executionBlock: ExecutionBlock
    private let canceledBlock: (() -> Void)?
    
    /// Create async operation with block, that does asynchronous work.
    ///
    /// - Parameter executionBlock: Closure that will be executed when the operation starts.
    ///   See its type documentation (`ExecutionBlock`) for more info.
    public init(_ executionBlock: @escaping ExecutionBlock) {
        self.executionBlock = executionBlock
        self.canceledBlock = nil
        super.init()
    }
    
    /// Create async operation with block, that does asynchronous work.
    ///
    /// - Parameter executionBlock: Closure that will be executed when operation is canceled.
    /// - Parameter executionBlock: Closure that will be executed when the operation starts.
    ///   See its type documentation (`ExecutionBlock`) for more info.
    public init(_ canceledBlock: (() -> Void)?, executionBlock: @escaping ExecutionBlock) {
        self.executionBlock = executionBlock
        self.canceledBlock = canceledBlock
        super.init()
    }
    
    final public override func started() {
        
        // first, execute block that was recieved in initializer
        executionBlock(self) { [weak self] completion in
            
            // when markFinished is called, mark operation finished
            self?.markFinished(completion: completion)
        }
    }
    
    final public override func canceled() {
        canceledBlock?()
    }
}

public extension OperationQueue {
    
    /// Creates an asynchonous operation with the execution block and adds to the receiver.
    /// - Parameters:
    ///   - completionQueue: Disatch queue that in which will be the completionblocked called
    ///   - executionBlock: Block to execute
    func addAsyncOperation(_ completionQueue: DispatchQueue? = nil, _ executionBlock: @escaping WPNAsyncBlockOperation.ExecutionBlock) {
        let op = WPNAsyncBlockOperation(executionBlock)
        op.completionQueue = completionQueue
        addOperation(op)
    }
}

/// Base class for asynchronous operations that will be put in `OperationQueue`
open class WPNAsyncOperation: Operation, CompletableInSpecificQueue {
    
    override final public var isAsynchronous: Bool { return true }
    override final public var isReady: Bool { return state == .isReady && dependencies.allSatisfy({ $0.isFinished }) }
    override final public var isExecuting: Bool { return state == .isExecuting }
    override final public var isFinished: Bool { return state.done }
    override final public var isCancelled: Bool { return state == .isCanceled }
    
    // Internal state of the operation
    private var state: AsyncOperationState = .isReady {
        didSet {
            willChangeValue(forKey: oldValue.rawValue)
            willChangeValue(forKey: state.rawValue)
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
            if state == .isCanceled {
                canceled()
            }
        }
    }
    private let stateLock = WPNLock()
    
    public var completionQueue: DispatchQueue?
    
    internal weak var delegate: WPNAsyncOperationDelegate?
    
    // MARK: - Lifecycle of the operation
    
    public override init() {
        self.state = .isReady
        super.init()
    }
    
    /// Starts the operation. This method is called by OperationQueue. Do not call this method.
    ///
    /// If the operation is already finished (canceled), it does nothing.
    final public override func start() {
        stateLock.lock()
        guard isFinished == false else {
            D.warning("Failed to start operation: already finished - \(state.rawValue)")
            stateLock.unlock()
            return
        }
        state = .isExecuting
        stateLock.unlock()
        started()
        delegate?.didStartAsyncOperation(self)
    }
    
    /// Advises the operation object that it should stop executing its task. This method does not force
    /// your operation code to stop. Instead, it updates the object’s internal flags to reflect the change in state.
    final public override func cancel() {
        stateLock.synchronized {
            guard self.isFinished == false else {
                D.warning("Cannot cancel already finished operation")
                return
            }
            self.state = .isCanceled
            self.delegate?.didCancelAsyncOperation(self)
        }
    }
    
    /// Sets the operation as finished.
    ///
    /// If the operation was already finished (or canceled), this method does nothing and the completion will not be called.
    ///
    /// - Parameter completion: Your completion block that will be called right after operation finishes.
    ///                         If the operation was alredy finished, it won't be called at all.
    ///                         If CompletionDispatchQueue was set, completion is executed on this queue.
    final public func markFinished(completion: (() -> Void)? = nil) {
        
        stateLock.lock()
        guard isFinished == false else {
            D.warning("Operation is already finished - \(state.rawValue)")
            stateLock.unlock()
            return
        }
        
        state = .isFinished
        stateLock.unlock()
        
        if let queue = completionQueue {
            // if completion queue is specified, do it in this queue
            queue.async {
                completion?()
            }
        } else {
            // else just execute the block
            completion?()
        }
    }
    
    // MARK: - Methods to override
    
    /// Implement your operation in this method. When the operation is finished, don't fotget to call `markFinished()`.
    /// If operation was crerated with `completionQueue`, use it to call completion.
    open func started() {
        D.fatalError("this method needs to be overriden")
    }
    
    /// Called when operation is canceled. Do not call this method.
    open func canceled() {
        // to override
    }
    
    // MARK: - CompletableInSpecificQueue protocol
    
    public func assignCompletionDispatchQueue(_ queue: DispatchQueue?) {
        completionQueue = queue
    }
}

protocol CompletableInSpecificQueue {
    func assignCompletionDispatchQueue(_ queue: DispatchQueue?)
}

private enum AsyncOperationState: String {
    case isWaiting
    case isReady
    case isCanceled
    case isExecuting
    case isFinished
    
    var done: Bool {
        return self == .isCanceled || self == .isFinished
    }
}

// internal for tests
internal protocol WPNAsyncOperationDelegate: class {
    func didStartAsyncOperation(_ operation: WPNAsyncOperation)
    func didCancelAsyncOperation(_ operation: WPNAsyncOperation)
}
