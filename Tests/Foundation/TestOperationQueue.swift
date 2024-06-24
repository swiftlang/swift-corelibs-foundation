// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Synchronization
import Dispatch

class TestOperationQueue : XCTestCase {
    func test_OperationCount() {
        let queue = OperationQueue()
        let op1 = BlockOperation(block: { Thread.sleep(forTimeInterval: 2) })
        queue.addOperation(op1)
        XCTAssertEqual(queue.operationCount, 1)
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(queue.operationCount, 0)

        let op2 = BlockOperation(block: { Thread.sleep(forTimeInterval: 0.5) })
        let op3 = BlockOperation(block: { Thread.sleep(forTimeInterval: 0.5) })
        queue.addOperation(op2)
        queue.addOperation(op3)
        XCTAssertEqual(queue.operationCount, 2)
        let operations = queue.operations
        XCTAssertEqual(operations.count, 2)
        if (operations.count == 2) {
            XCTAssertEqual(operations[0], op2)
            XCTAssertEqual(operations[1], op3)
        }
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(queue.operationCount, 0)
        XCTAssertEqual(queue.operations.count, 0)
    }

    func test_OperationPriorities() {
        let msgOperations = Mutex([String]())
        let operation1 : BlockOperation = BlockOperation(block: {
            msgOperations.withLock { $0.append("Operation1 executed") }
        })
        let operation2 : BlockOperation = BlockOperation(block: {
            msgOperations.withLock { $0.append("Operation2 executed") }
        })
        let operation3 : BlockOperation = BlockOperation(block: {
            msgOperations.withLock { $0.append("Operation3 executed") }
        })
        let operation4: BlockOperation = BlockOperation(block: {
            msgOperations.withLock { $0.append("Operation4 executed") }
        })
        operation4.queuePriority = .veryLow
        operation3.queuePriority = .veryHigh
        operation2.queuePriority = .low
        operation1.queuePriority = .normal
        var operations = [Operation]()
        operations.append(operation1)
        operations.append(operation2)
        operations.append(operation3)
        operations.append(operation4)
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperations(operations, waitUntilFinished: true)
        msgOperations.withLock {
            XCTAssertEqual($0[0], "Operation3 executed")
            XCTAssertEqual($0[1], "Operation1 executed")
            XCTAssertEqual($0[2], "Operation2 executed")
            XCTAssertEqual($0[3], "Operation4 executed")
        }
    }

    func test_isExecutingWorks() {
        class _OperationBox {
            var operation: Operation?
            init() {
                self.operation = nil
            }
        }
        let queue = OperationQueue()
        let opBox = _OperationBox()
        let op = BlockOperation(block: { XCTAssertEqual(true, opBox.operation?.isExecuting) })
        opBox.operation = op
        XCTAssertFalse(op.isExecuting)

        queue.addOperation(op)
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertFalse(op.isExecuting)

        opBox.operation = nil /* break the reference cycle op -> <closure> -> opBox -> op */
    }

    func test_AsyncOperation() {
        let operation = AsyncOperation()
        XCTAssertFalse(operation.isExecuting)
        XCTAssertFalse(operation.isFinished)

        operation.start()

        while !operation.isFinished {
            // do nothing
        }

        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
    }
    
    func test_SyncOperationWithoutAQueue() {
        let operation = SyncOperation()
        XCTAssertFalse(operation.isExecuting)
        XCTAssertFalse(operation.isFinished)

        operation.start()

        XCTAssertFalse(operation.isExecuting)
        XCTAssertTrue(operation.isFinished)
        XCTAssertTrue(operation.hasRun)
    }
    
    func test_MainQueueGetter() {
        XCTAssertTrue(OperationQueue.main === OperationQueue.main)
        
        /*
         This call is only to check if OperationQueue.main returns a living instance.
         There used to be a bug where subsequent OperationQueue.main call would return a "dangling pointer".
         */
        XCTAssertFalse(OperationQueue.main.isSuspended)
    }
    
    func test_CancelOneOperation() {
        var operations = [Operation]()
        let valueOperations = Mutex([Int]())
        for i in 0..<5 {
            let operation = BlockOperation {
                valueOperations.withLock { $0.append(i) }
                Thread.sleep(forTimeInterval: 2)
            }
            operations.append(operation)
        }
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperations(operations, waitUntilFinished: false)
        operations.remove(at: 2).cancel()
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertTrue(!valueOperations.withLock({ $0.contains(2)}))
    }
    
    func test_CancelOperationsOfSpecificQueuePriority() {
        var operations = [Operation]()
        let valueOperations = Mutex([Int]())
        
        let operation1 = BlockOperation {
            valueOperations.withLock { $0.append(0) }
            Thread.sleep(forTimeInterval: 2)
        }
        operation1.queuePriority = .high
        operations.append(operation1)
        
        let operation2 = BlockOperation {
            valueOperations.withLock { $0.append(1) }
            Thread.sleep(forTimeInterval: 2)
        }
        operation2.queuePriority = .high
        operations.append(operation2)
        
        let operation3 = BlockOperation {
            valueOperations.withLock { $0.append(2) }
        }
        operation3.queuePriority = .normal
        operations.append(operation3)
        
        let operation4 = BlockOperation {
            valueOperations.withLock { $0.append(3) }
        }
        operation4.queuePriority = .normal
        operations.append(operation4)
        
        let operation5 = BlockOperation {
            valueOperations.withLock { $0.append(4) }
        }
        operation5.queuePriority = .normal
        operations.append(operation5)
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperations(operations, waitUntilFinished: false)
        for operation in operations {
            if operation.queuePriority == .normal {
                operation.cancel()
            }
        }
        queue.waitUntilAllOperationsAreFinished()
        valueOperations.withLock {
            XCTAssertTrue($0.count == 2)
            XCTAssertTrue($0[0] == 0)
            XCTAssertTrue($0[1] == 1)
        }
    }
    
    func test_CurrentQueueOnMainQueue() {
        XCTAssertTrue(OperationQueue.main === OperationQueue.current)
    }
    
    func test_CurrentQueueOnBackgroundQueue() {
        let expectation = self.expectation(description: "Background execution")
        
        let operationQueue = OperationQueue()
        operationQueue.addOperation {
            XCTAssertEqual(operationQueue, OperationQueue.current)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func test_CurrentQueueOnBackgroundQueueWithSelfCancel() {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        let expectation = self.expectation(description: "Background execution")
        operationQueue.addOperation {
            XCTAssertEqual(operationQueue, OperationQueue.current)
            expectation.fulfill()
            // Canceling operation X from inside operation X should not cause the app to a crash
            operationQueue.cancelAllOperations()
        }
        
        waitForExpectations(timeout: 1)
    }

    func test_CurrentQueueWithCustomUnderlyingQueue() {
        let expectation = self.expectation(description: "Background execution")

        let operationQueue = OperationQueue()
        let underlyingQueue = DispatchQueue(label: "underlying_queue")
        operationQueue.underlyingQueue = underlyingQueue

        operationQueue.addOperation {
            XCTAssertEqual(operationQueue, OperationQueue.current)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func test_isSuspended() {
        let expectation1 = self.expectation(description: "DispatchQueue execution")
        let expectation2 = self.expectation(description: "OperationQueue execution")
        
        let dispatchQueue = DispatchQueue(label: "underlying_queue")
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.underlyingQueue = dispatchQueue
        operationQueue.isSuspended = true
        
        operationQueue.addOperation {
            XCTAssert(OperationQueue.current?.underlyingQueue === dispatchQueue)
            expectation2.fulfill()
        }
        
        dispatchQueue.async {
            operationQueue.isSuspended = false
            expectation1.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func test_CurrentQueueWithUnderlyingQueueResetToNil() {
        let expectation = self.expectation(description: "Background execution")
        
        let operationQueue = OperationQueue()
        let underlyingQueue = DispatchQueue(label: "underlying_queue")
        operationQueue.underlyingQueue = underlyingQueue
        operationQueue.underlyingQueue = nil
        
        operationQueue.addOperation {
            XCTAssertEqual(operationQueue, OperationQueue.current)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func test_OperationDependencyCount() {
        let op1 = BlockOperation {
        }
        op1.name = "op1"
        let op2 = BlockOperation {
        }
        op2.name = "op2"
        op1.addDependency(op2)
        XCTAssert(op1.dependencies.count == 1)
    }
    
    func test_CancelDependency() {
        let expectation = self.expectation(description: "Operation should finish")

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let op1 = BlockOperation() {
            XCTAssert(false, "Should not run")
        }
        let op2 = BlockOperation() {
            expectation.fulfill()
        }

        op2.addDependency(op1)
        op1.cancel()

        queue.addOperation(op1)
        queue.addOperation(op2)

        waitForExpectations(timeout: 1)
    }

    func test_Deadlock() {
        let expectation1 = self.expectation(description: "Operation should finish")
        let expectation2 = self.expectation(description: "Operation should finish")

        let op1 = BlockOperation {
            expectation1.fulfill()
        }
        op1.name = "op1"

        let op2 = BlockOperation {
            expectation2.fulfill()
        }
        op2.name = "op2"

        op1.addDependency(op2)

        // Narrow scope to force early release of queue object
        _ = {
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            queue.addOperation(op1)
            queue.addOperation(op2)
        }()

        waitForExpectations(timeout: 1)
        Thread.sleep(forTimeInterval: 1)
    }

    public func test_CancelOutOfQueue() {
        let op = Operation()
        op.cancel()

        XCTAssert(op.isCancelled)
        XCTAssertFalse(op.isExecuting)
        XCTAssertFalse(op.isFinished)
    }

    public func test_CrossQueueDependency() {
        let queue = OperationQueue()
        let queue2 = OperationQueue()

        let expectation1 = self.expectation(description: "Operation should finish")
        let expectation2 = self.expectation(description: "Operation should finish")

        let op1 = BlockOperation {
            expectation1.fulfill()
        }
        op1.name = "op1"

        let op2 = BlockOperation {
            expectation2.fulfill()
        }
        op2.name = "op2"

        op1.addDependency(op2)

        queue.addOperation(op1)
        queue2.addOperation(op2)

        waitForExpectations(timeout: 1)
    }

    public func test_CancelWhileSuspended() {
        let queue = OperationQueue()
        queue.isSuspended = true

        let op1 = BlockOperation {}
        op1.name = "op1"

        let op2 = BlockOperation {}
        op2.name = "op2"

        queue.addOperation(op1)
        queue.addOperation(op2)

        op1.cancel()
        op2.cancel()

        queue.isSuspended = false
        queue.waitUntilAllOperationsAreFinished()

        XCTAssert(op1.isCancelled)
        XCTAssertFalse(op1.isExecuting)
        XCTAssert(op1.isFinished)
        XCTAssert(op2.isCancelled)
        XCTAssertFalse(op2.isExecuting)
        XCTAssert(op2.isFinished)
    }

    public func test_OperationOrder() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true

        let array = Mutex([Int]())

        let op1 = BlockOperation {
            array.withLock { $0.append(1) }
        }
        op1.queuePriority = .normal
        op1.name = "op1"

        let op2 = BlockOperation {
            array.withLock { $0.append(2) }
        }
        op2.queuePriority = .normal
        op2.name = "op2"

        let op3 = BlockOperation {
            array.withLock { $0.append(3) }
        }
        op3.queuePriority = .normal
        op3.name = "op3"

        let op4 = BlockOperation {
            array.withLock { $0.append(4) }
        }
        op4.queuePriority = .normal
        op4.name = "op4"

        let op5 = BlockOperation {
            array.withLock { $0.append(5) }
        }
        op5.queuePriority = .normal
        op5.name = "op5"

        queue.addOperation(op1)
        queue.addOperation(op2)
        queue.addOperation(op3)
        queue.addOperation(op4)
        queue.addOperation(op5)

        queue.isSuspended = false
        queue.waitUntilAllOperationsAreFinished()

        array.withLock {
            XCTAssertEqual($0, [1, 2, 3, 4, 5])
        }
    }

    public func test_OperationOrder2() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.isSuspended = true

        let array = Mutex([Int]())

        let op1 = BlockOperation {
            array.withLock { $0.append(1) }
        }
        op1.queuePriority = .veryLow
        op1.name = "op1"

        let op2 = BlockOperation {
            array.withLock { $0.append(2) }
        }
        op2.queuePriority = .low
        op2.name = "op2"

        let op3 = BlockOperation {
            array.withLock { $0.append(3) }
        }
        op3.queuePriority = .normal
        op3.name = "op3"

        let op4 = BlockOperation {
            array.withLock { $0.append(4) }
        }
        op4.queuePriority = .high
        op4.name = "op4"

        let op5 = BlockOperation {
            array.withLock { $0.append(5) }
        }
        op5.queuePriority = .veryHigh
        op5.name = "op5"

        queue.addOperation(op1)
        queue.addOperation(op2)
        queue.addOperation(op3)
        queue.addOperation(op4)
        queue.addOperation(op5)

        queue.isSuspended = false
        queue.waitUntilAllOperationsAreFinished()

        array.withLock {
            XCTAssertEqual($0, [5, 4, 3, 2, 1])
        }
    }

    func test_ExecutionOrder() {
        let queue = OperationQueue()
        
        let didRunOp1 = expectation(description: "Did run first operation")
        let didRunOp1Dependency = expectation(description: "Did run first operation dependency")
        let didRunOp2 = expectation(description: "Did run second operation")
        // Protected by the ordering of execution, which we are testing here
        nonisolated(unsafe) var didRunOp1DependencyFirst = false
        
        let op1 = BlockOperation {
            didRunOp1.fulfill()
            XCTAssertTrue(didRunOp1DependencyFirst, "Dependency should be executed first")
        }
        let op1Dependency = BlockOperation {
            didRunOp1Dependency.fulfill()
            didRunOp1DependencyFirst = true
        }
        op1.addDependency(op1Dependency)
        queue.addOperations([op1, op1Dependency], waitUntilFinished: false)
        
        queue.addOperation {
            didRunOp2.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }

    func test_WaitUntilFinished() {
        let queue1 = OperationQueue()
        let queue2 = OperationQueue()

        let op1 = BlockOperation {Thread.sleep(forTimeInterval: 1) }
        let op2 = BlockOperation { }

        op2.addDependency(op1)

        queue1.addOperation(op1)
        queue2.addOperation(op2)

        queue2.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(queue2.operationCount, 0)
    }

    func test_OperationWaitUntilFinished() {
        let queue1 = OperationQueue()
        let op1 = BlockOperation { Thread.sleep(forTimeInterval: 1) }
        queue1.addOperation(op1)
        op1.waitUntilFinished()
        
        // Operation is not removed from Queue simultaneously
        // with transitioning to "Finished" state. Wait a bit
        // to allow OperationQueue to deal with finished op.
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertEqual(queue1.operationCount, 0)
    }

    func test_CustomOperationReady() throws {
        throw XCTSkip("Flaky test: https://bugs.swift.org/browse/SR-14657")
        #if false
        class CustomOperation: Operation {

            private var _isReady = false

            override var isReady: Bool {
                return _isReady
            }

            func setIsReady() {
                willChangeValue(forKey: "isReady")
                _isReady = true
                didChangeValue(forKey: "isReady")
            }

        }

        let expectation = self.expectation(description: "Operation should finish")

        let queue1 = OperationQueue()
        let op1 = CustomOperation()
        let op2 = BlockOperation(block: {
            expectation.fulfill()
        })

        queue1.addOperation(op1)
        queue1.addOperation(op2)

        waitForExpectations(timeout: 1)

        XCTAssertEqual(queue1.operationCount, 1)
        op1.setIsReady()
        queue1.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(queue1.operationCount, 0)
        #endif
    }

    func test_DependencyCycleBreak() {
        let op1DidRun = expectation(description: "op1 supposed to be run")
        let op2DidRun = expectation(description: "op2 supposed to be run")
        let op2Finished = expectation(description: "op2 supposed to be finished")
        let op3Cancelled = expectation(description: "op3 supposed to be cancelled")
        let op3DidRun = expectation(description: "op3 is not supposed to be run")
        op3DidRun.isInverted = true

        struct Ops {
            var op1: Operation!
            var op2: Operation!
            var op3: Operation!
            init() {
                op1 = nil
                op2 = nil
                op3 = nil
            }
        }
        let ops = Mutex(Ops())

        let queue1 = OperationQueue()
        ops.withLock {
            $0.op1 = BlockOperation {
                op1DidRun.fulfill()
                ops.withLock {
                    if $0.op2.isFinished {
                        op2Finished.fulfill()
                    }
                }
            }
            $0.op2 = BlockOperation {
                op2DidRun.fulfill()
                ops.withLock {
                    if $0.op3.isCancelled {
                        op3Cancelled.fulfill()
                    }
                }
            }
            $0.op3 = BlockOperation {
                op3DidRun.fulfill()
            }
            
            // Create dependency cycle
            $0.op1.addDependency($0.op2)
            $0.op2.addDependency($0.op3)
            $0.op3.addDependency($0.op1)
            
            queue1.addOperation($0.op1)
            queue1.addOperation($0.op2)
            queue1.addOperation($0.op3)
            
            XCTAssertEqual(queue1.operationCount, 3)
            
            //Break dependency cycle
            $0.op3.cancel()
        }
        
        waitForExpectations(timeout: 1)
    }

    func test_Lifecycle() {
        let opStarted = expectation(description: "Operation supposed to start")
        let opDone = expectation(description: "Operation supposed to be done")

        let op1 = BlockOperation {
            Thread.sleep(forTimeInterval: 0.3)
        }
        let op2 = BlockOperation {
            opStarted.fulfill()
            Thread.sleep(forTimeInterval: 0.3)
            opDone.fulfill()
        }

        op1.addDependency(op2)

        weak var weakQueue: OperationQueue?
        _ = {
            let queue = OperationQueue()
            weakQueue = queue
            queue.addOperation(op1)
            queue.addOperation(op2)
        }()

        wait(for: [opStarted], timeout: 1)
        op2.cancel()
        wait(for: [opDone], timeout: 1)

        Thread.sleep(forTimeInterval: 1) // Let queue to be deallocated
        XCTAssertNil(weakQueue, "Queue should be deallocated at this point")
    }

    func test_ConcurrentOperations() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        
        // Running several iterations helps to reveal use-after-dealloc crashes
        for _ in 0..<3 {
            let didRunOp1 = expectation(description: "Did run first operation")
            let didRunOp2 = expectation(description: "Did run second operation")
            
            queue.addOperation {
                self.wait(for: [didRunOp2], timeout: 0.2)
                didRunOp1.fulfill()
            }
            queue.addOperation {
                didRunOp2.fulfill()
            }
            
            self.wait(for: [didRunOp1], timeout: 0.3)
        }
    }

    func test_ConcurrentOperationsWithDependenciesAndCompletions() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        
        // Running several iterations helps to reveal use-after-dealloc crashes
        for _ in 0..<3 {
            let didRunOp1 = expectation(description: "Did run first operation")
            let didRunOp1Completion = expectation(description: "Did run first operation completion")
            let didRunOp1Dependency = expectation(description: "Did run first operation dependency")
            let didRunOp2 = expectation(description: "Did run second operation")
            
            let op1 = BlockOperation {
                self.wait(for: [didRunOp1Dependency, didRunOp2], timeout: 0.2)
                didRunOp1.fulfill()
            }
            op1.completionBlock = {
                didRunOp1Completion.fulfill()
            }
            let op1Dependency = BlockOperation {
                didRunOp1Dependency.fulfill()
            }
            queue.addOperations([op1, op1Dependency], waitUntilFinished: false)
            queue.addOperation {
                didRunOp2.fulfill()
            }
            
            self.wait(for: [didRunOp1, didRunOp1Completion], timeout: 0.3)
        }
    }

    func test_BlockOperationAddExecutionBlock() {
        let block1Expectation = expectation(description: "Block 1 executed")
        let block2Expectation = expectation(description: "Block 2 executed")
        
        let blockOperation = BlockOperation {
            block1Expectation.fulfill()
        }
        blockOperation.addExecutionBlock {
            block2Expectation.fulfill()
        }
        XCTAssert(blockOperation.executionBlocks.count == 2)
        let queue = OperationQueue()
        queue.addOperation(blockOperation)
        waitForExpectations(timeout: 1.0)
    }
}

class AsyncOperation: Operation, @unchecked Sendable {

    private let queue = DispatchQueue(label: "async.operation.queue")
    private let lock = NSLock()

    private var _executing = false
    private var _finished = false

    override var isExecuting: Bool {
        get {
            lock.lock()
            let wasExecuting = _executing
            lock.unlock()
            return wasExecuting
        }
        set {
            if isExecuting != newValue {
                willChangeValue(forKey: "isExecuting")
                lock.lock()
                _executing = newValue
                lock.unlock()
                didChangeValue(forKey: "isExecuting")
            }
        }
    }

    override var isFinished: Bool {
        get {
            lock.lock()
            let wasFinished = _finished
            lock.unlock()
            return wasFinished
        }
        set {
            if isFinished != newValue {
                willChangeValue(forKey: "isFinished")
                lock.lock()
                _finished = newValue
                lock.unlock()
                didChangeValue(forKey: "isFinished")
            }
        }
    }

    override var isAsynchronous: Bool {
        return true
    }

    override func start() {
        if isCancelled {
            isFinished = true
            return
        }

        isExecuting = true

        queue.async {
            Thread.sleep(forTimeInterval: 1)
            self.isExecuting = false
            self.isFinished = true
        }
    }

}

class SyncOperation: Operation, @unchecked Sendable {

    var hasRun = false

    override func main() {
        Thread.sleep(forTimeInterval: 1)
        hasRun = true
    }

}
