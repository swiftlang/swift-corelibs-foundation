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
            ("test_isExecutingWorks", test_isExecutingWorks),
            ("test_MainQueueGetter", test_MainQueueGetter),
            ("test_CurrentQueueOnMainQueue", test_CurrentQueueOnMainQueue),
            ("test_CurrentQueueOnBackgroundQueue", test_CurrentQueueOnBackgroundQueue),
            ("test_CurrentQueueOnBackgroundQueueWithSelfCancel", test_CurrentQueueOnBackgroundQueueWithSelfCancel),
            ("test_CurrentQueueWithCustomUnderlyingQueue", test_CurrentQueueWithCustomUnderlyingQueue),
            ("test_CurrentQueueWithUnderlyingQueueResetToNil", test_CurrentQueueWithUnderlyingQueueResetToNil),
            ("test_isSuspended", test_isSuspended),
            ("test_QueueDoesntEatAllThreadsInPool", test_QueueDoesntEatAllThreadsInPool),
            ("test_isSuspendedAndCanceled", test_isSuspendedAndCanceled),
            ("test_WaitUntilFinished", test_WaitUntilFinished),
            ("test_WaitUntilFinishedOperation", test_WaitUntilFinishedOperation),
            ("test_CustomReadyOperation", test_CustomReadyOperation),
            ("testMac0s_10_6_CancelBehavour", testMac0s_10_6_CancelBehavour),
        ]
    }
    
    func test_OperationCount() {
        let queue = OperationQueue()
        let op1 = BlockOperation(block: { sleep(2) })
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
    
    func test_MainQueueGetter() {
        XCTAssertTrue(OperationQueue.main === OperationQueue.main)
        
        /*
         This call is only to check if OperationQueue.main returns a living instance.
         There used to be a bug where subsequent OperationQueue.main call would return a "dangling pointer".
         */
        XCTAssertFalse(OperationQueue.main.isSuspended)
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
    
    // OperationQueue shouldn't move all threads on wait as previous implementation does
    func test_QueueDoesntEatAllThreadsInPool() {
        let expectation = self.expectation(description: "Background execution")
        
        let operationQueue1 = OperationQueue()
        operationQueue1.maxConcurrentOperationCount = 2
        operationQueue1.underlyingQueue = DispatchQueue(label: "underlying_queue1")
        operationQueue1.underlyingQueue = nil
        
        for _ in 0 ..< 1000 {
            operationQueue1.addOperation {
                sleep(1)
            }
        }
        
        let operationQueue2 = OperationQueue()
        operationQueue2.maxConcurrentOperationCount = 2
        operationQueue2.underlyingQueue = DispatchQueue(label: "underlying_queue2")
        operationQueue2.underlyingQueue = nil
        
        operationQueue2.addOperation {
            expectation.fulfill()
        }
    
        waitForExpectations(timeout: 1)
        
        operationQueue1.cancelAllOperations()
    }
    
    public func test_isSuspendedAndCanceled() {
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
    
    func test_WaitUntilFinished() {
        let expectation = self.expectation(description: "Operation should finish")
        let queue1 = OperationQueue()
        let queue2 = OperationQueue()
        
        let op1 = BlockOperation {
            sleep(1)
            expectation.fulfill()
        }
        let op2 = BlockOperation { }
        
        op2.addDependency(op1)
        
        queue1.addOperation(op1)
        queue2.addOperation(op2)
        
        queue2.waitUntilAllOperationsAreFinished()
        waitForExpectations(timeout: 0)
        XCTAssertEqual(queue2.operationCount, 0)
    }
    
    func test_WaitUntilFinishedOperation() {
        let expectation = self.expectation(description: "Operation should finish")
        let queue1 = OperationQueue()
        let op1 = BlockOperation {
            sleep(1)
            expectation.fulfill()
        }
        queue1.addOperation(op1)
        op1.waitUntilFinished()
        waitForExpectations(timeout: 0)
        XCTAssertEqual(queue1.operationCount, 0)
    }
    
    func test_CustomReadyOperation() {
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
        
        op2.addDependency(op1)
        
        queue1.addOperation(op1)
        queue1.addOperation(op2)
        
        sleep(1)
        XCTAssertEqual(queue1.operationCount, 2)
        
        op1.setIsReady()
        waitForExpectations(timeout: 1)
        XCTAssertEqual(queue1.operationCount, 0)
    }
    
    // In macOS 10.6 and later, if you cancel an operation while it is waiting on the completion of
    // one or more dependent operations, those dependencies are thereafter ignored and the
    // value of this property is updated to reflect that it is now ready to run. This behavior gives
    // an operation queue the chance to flush cancelled operations out of its queue more quickly.
    func testMac0s_10_6_CancelBehavour() {
        
        let expectation1 = self.expectation(description: "Operation should finish")
        let expectation2 = self.expectation(description: "Operation should finish")
        
        let queue1 = OperationQueue()
        let op1 = BlockOperation(block: {
            expectation1.fulfill()
        })
        let op2 = BlockOperation(block: {
            expectation2.fulfill()
        })
        let op3 = BlockOperation(block: {
            // empty
        })
        
        op1.addDependency(op2)
        op2.addDependency(op3)
        op3.addDependency(op1)
        
        queue1.addOperation(op1)
        queue1.addOperation(op2)
        queue1.addOperation(op3)
        
        sleep(1)
        
        XCTAssertEqual(queue1.operationCount, 3)
        
        op3.cancel()
        
        waitForExpectations(timeout: 1)
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
            sleep(1)
            self.isExecuting = false
            self.isFinished = true
        }
    }

}
