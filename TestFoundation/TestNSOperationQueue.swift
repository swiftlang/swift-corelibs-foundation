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
    static var allTests: [(String, TestNSOperationQueue -> () throws -> Void)] {
        return [
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
}
