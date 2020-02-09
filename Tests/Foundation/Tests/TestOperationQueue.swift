// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Dispatch

class TestOperationQueue : XCTestCase {
    static var allTests: [(String, (TestOperationQueue) -> () throws -> Void)] {
        return [
            ("test_OperationPriorities", test_OperationPriorities),
            ("test_OperationCount", test_OperationCount),
            ("test_AsyncOperation", test_AsyncOperation),
            ("test_SyncOperationWithoutAQueue", test_SyncOperationWithoutAQueue),
            ("test_isExecutingWorks", test_isExecutingWorks),
            ("test_MainQueueGetter", test_MainQueueGetter),
            ("test_CancelOneOperation", test_CancelOneOperation),
            ("test_CancelOperationsOfSpecificQueuePriority", test_CancelOperationsOfSpecificQueuePriority),
            ("test_CurrentQueueOnMainQueue", test_CurrentQueueOnMainQueue),
            ("test_CurrentQueueOnBackgroundQueue", test_CurrentQueueOnBackgroundQueue),
            ("test_CurrentQueueOnBackgroundQueueWithSelfCancel", test_CurrentQueueOnBackgroundQueueWithSelfCancel),
            ("test_CurrentQueueWithCustomUnderlyingQueue", test_CurrentQueueWithCustomUnderlyingQueue),
            ("test_CurrentQueueWithUnderlyingQueueResetToNil", test_CurrentQueueWithUnderlyingQueueResetToNil),
            ("test_isSuspended", test_isSuspended),
            ("test_OperationDependencyCount", test_OperationDependencyCount),
        ]
    }
    
    func test_OperationCount() {
        let queue = OperationQueue()
        let op1 = BlockOperation(block: { Thread.sleep(forTimeInterval: 2) })
        queue.addOperation(op1)
        XCTAssertTrue(queue.operationCount == 1)
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertTrue(queue.operationCount == 0)
    }

    func test_OperationPriorities() {
        var msgOperations = [String]()
        let operation1 : BlockOperation = BlockOperation(block: {
            msgOperations.append("Operation1 executed")
        })
        let operation2 : BlockOperation = BlockOperation(block: {
            msgOperations.append("Operation2 executed")
        })
        let operation3 : BlockOperation = BlockOperation(block: {
            msgOperations.append("Operation3 executed")
        })
        let operation4: BlockOperation = BlockOperation(block: {
            msgOperations.append("Operation4 executed")
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
        XCTAssertEqual(msgOperations[0], "Operation3 executed")
        XCTAssertEqual(msgOperations[1], "Operation1 executed")
        XCTAssertEqual(msgOperations[2], "Operation2 executed")
        XCTAssertEqual(msgOperations[3], "Operation4 executed")
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
        var valueOperations = [Int]()
        for i in 0..<5 {
            let operation = BlockOperation {
                valueOperations.append(i)
                Thread.sleep(forTimeInterval: 2)
            }
            operations.append(operation)
        }
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperations(operations, waitUntilFinished: false)
        operations.remove(at: 2).cancel()
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertTrue(!valueOperations.contains(2))
    }
    
    func test_CancelOperationsOfSpecificQueuePriority() {
        var operations = [Operation]()
        var valueOperations = [Int]()
        
        let operation1 = BlockOperation {
            valueOperations.append(0)
            Thread.sleep(forTimeInterval: 2)
        }
        operation1.queuePriority = .high
        operations.append(operation1)
        
        let operation2 = BlockOperation {
            valueOperations.append(1)
            Thread.sleep(forTimeInterval: 2)
        }
        operation2.queuePriority = .high
        operations.append(operation2)
        
        let operation3 = BlockOperation {
            valueOperations.append(2)
        }
        operation3.queuePriority = .normal
        operations.append(operation3)
        
        let operation4 = BlockOperation {
            valueOperations.append(3)
        }
        operation4.queuePriority = .normal
        operations.append(operation4)
        
        let operation5 = BlockOperation {
            valueOperations.append(4)
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
        XCTAssertTrue(valueOperations.count == 2)
        XCTAssertTrue(valueOperations[0] == 0)
        XCTAssertTrue(valueOperations[1] == 1)
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
        operationQueue.underlyingQueue = DispatchQueue(label: "underlying_queue")
        
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
        operationQueue.underlyingQueue = DispatchQueue(label: "underlying_queue")
        operationQueue.underlyingQueue = nil
        
        operationQueue.addOperation {
            XCTAssertEqual(operationQueue, OperationQueue.current)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1)
    }
    
    func test_OperationDependencyCount() {
        var results = [Int]()
        let op1 = BlockOperation {
            results.append(1)
        }
        op1.name = "op1"
        let op2 = BlockOperation {
            results.append(2)
        }
        op2.name = "op2"
        op1.addDependency(op2)
        XCTAssert(op1.dependencies.count == 1)
    }
}

class AsyncOperation: Operation {

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

class SyncOperation: Operation {

    var hasRun = false

    override func main() {
        Thread.sleep(forTimeInterval: 1)
        hasRun = true
    }

}
