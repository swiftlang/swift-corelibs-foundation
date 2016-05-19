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
           /* uncomment below lines once Dispatch is enabled in Foundation */
           // ("test_OperationPriorities", test_OperationPriorities),
            ("test_OperationCount", test_OperationCount)
        ]
    }
    
    func test_OperationCount() {
        let queue = NSOperationQueue()
        let op1 = NSBlockOperation(block: { sleep(2) })
        queue.addOperation(op1)
        XCTAssertTrue(queue.operationCount == 1)
        /* uncomment below lines once Dispatch is enabled in Foundation */
        //queue.waitUntilAllOperationsAreFinished()
        //XCTAssertTrue(queue.operationCount == 0)
    }

    func test_OperationPriorities() {
        var msgOperations = [String]()
        let operation1 : NSBlockOperation = NSBlockOperation (block: {
            msgOperations.append("Operation1 executed")
        })
        let operation2 : NSBlockOperation = NSBlockOperation (block: {
            msgOperations.append("Operation2 executed")
        })
        let operation3 : NSBlockOperation = NSBlockOperation (block: {
            msgOperations.append("Operation3 executed")
        })
        let operation4: NSBlockOperation = NSBlockOperation (block: {
            msgOperations.append("Operation4 executed")
        })
        operation4.queuePriority = OperationQueuePriority.VeryLow
        operation3.queuePriority = OperationQueuePriority.VeryHigh
        operation2.queuePriority = OperationQueuePriority.Low
        operation1.queuePriority = OperationQueuePriority.Normal
        var operations = [NSOperation]()
        operations.append(operation1)
        operations.append(operation2)
        operations.append(operation3)
        operations.append(operation4)
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperations(operations, waitUntilFinished: true)
        XCTAssertEqual(msgOperations[0], "Operation3 executed")
        XCTAssertEqual(msgOperations[1], "Operation1 executed")
        XCTAssertEqual(msgOperations[2], "Operation2 executed")
        XCTAssertEqual(msgOperations[3], "Operation4 executed")
    }
}
