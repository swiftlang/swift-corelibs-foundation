// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//



#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#else
import SwiftFoundation
import SwiftXCTest
#endif
import Dispatch

class TestNSOperationQueue : XCTestCase {
    static var allTests: [(String, (TestNSOperationQueue) -> () throws -> Void)] {
        return [
            ("test_OperationPriorities", test_OperationPriorities),
            ("test_OperationCount", test_OperationCount),
            ("test_AsyncOperation", test_AsyncOperation)
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
}

class AsyncOperation: Operation {

    private let queue = DispatchQueue(label: "async.operation.queue")
    private let lock = NSLock()

    private var _executing = false
    private var _finished = false

    override internal(set) var isExecuting: Bool {
        get {
            return _executing
        }
        set {
            if _executing != newValue {
                willChangeValue(forKey: "isExecuting")
                _executing = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }

    override internal(set) var isFinished: Bool {
        get {
            return _finished
        }
        set {
            if _finished != newValue {
                willChangeValue(forKey: "isFinished")
                _finished = newValue
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
            self.lock.lock()
            self.isExecuting = false
            self.isFinished = true
            self.lock.unlock()
        }
    }

}
