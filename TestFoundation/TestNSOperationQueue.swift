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

class TestNSOperationQueue : XCTestCase {
    static var allTests: [(String, (TestNSOperationQueue) -> () throws -> Void)] {
        return [
            ("test_OperationPriorities", test_OperationPriorities),
            ("test_OperationCount", test_OperationCount),
            ("test_OperationAddRemoveDependency",test_OperationAddRemoveDependency),
            ("test_OperationExecutionWithDependency", test_OperationExecutionWithDependency),
            ("test_OperationStates", test_OperationStates),
            ("test_synchronousOperations", test_synchronousOperations),
            ("test_completionBlock", test_completionBlock),
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
        let operation1 = BlockOperation(block: {
            msgOperations.append("Operation1 executed")
            sleep(1)
        })
        let operation2 = BlockOperation(block: {
            msgOperations.append("Operation2 executed")
            sleep(1)
        })
        let operation3 = BlockOperation(block: {
            msgOperations.append("Operation3 executed")
            sleep(1)
        })
        let operation4 = BlockOperation(block: {
            msgOperations.append("Operation4 executed")
            sleep(1)
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

    func test_OperationAddRemoveDependency() {
        let operation1 = BlockOperation(block: {
        })
        operation1.name = "Operation1"
        let operation2 = BlockOperation(block: {
        })
        operation2.name = "Operation2"
        operation1.addDependency(operation2)
        XCTAssertEqual(1, operation1.dependencies.count)
        for dependentOperation in operation1.dependencies {
            XCTAssertEqual("Operation2", dependentOperation.name)
        }
        operation1.removeDependency(operation2)
        operation2.removeDependency(operation1)
        XCTAssertEqual(0, operation1.dependencies.count)
    }

    func test_OperationExecutionWithDependency() {
        var finalMsg: String = "init"
        let operation1 = BlockOperation(block: {
            finalMsg = "Execution Order: Operation1"
        })
        let operation2 = BlockOperation(block: {
            finalMsg = finalMsg + ", Operation2"
        })
        let operation3 = BlockOperation(block: {
            finalMsg = finalMsg + ", Operation3"
        })
        let myOpQueue = OperationQueue()
        operation3.addDependency(operation2)
        operation2.addDependency(operation1)
        myOpQueue.addOperation(operation1)
        myOpQueue.addOperation(operation2)
        myOpQueue.addOperation(operation3)
        myOpQueue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(finalMsg, "Execution Order: Operation1, Operation2, Operation3")
    }

    func test_OperationStates() {
        var total: Int = 0
        let operation1 = BlockOperation(block: {
            sleep(1)
            total += 1
        })
        let operation2 = BlockOperation(block: {
            sleep(1)
            total += 1
        })
        operation1.cancel()
        XCTAssertTrue(operation1.isCancelled)
        let queue = OperationQueue()
        queue.addOperation(operation1)
        queue.addOperation(operation2)
        queue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(total, 1)
        XCTAssertTrue(operation1.isCancelled)
        XCTAssertTrue(operation2.isFinished)
    }

    func test_synchronousOperations() {
        var finalMsg: String = "init"
        let operation1 = BlockOperation(block: {
            finalMsg = "Operation1"
        })
        let operation2 = BlockOperation(block: {
            finalMsg = "Operation2"
        })
        let operation3 = BlockOperation(block: {
            finalMsg = "Operation3"
        })
        operation2.start()
        operation3.start()
        operation1.start()
        XCTAssertEqual(finalMsg, "Operation1")
    }

    func test_completionBlock() {
        var message = ""
        let operation = BlockOperation(block: {
            message.append("Operation done.")
        })
        operation.completionBlock = {
            message.append("completionBlock invoked.")
        }
        operation.start()
        repeat {
            sleep(1)
        } while(!operation.isFinished)
        XCTAssertEqual(message, "Operation done.completionBlock invoked.")
    }
}
