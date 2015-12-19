// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
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


class TestNSOperation : XCTestCase {

    var allTests : [(String, () -> ())] {
        return [
            ("test_OperationQueueWaitsForExecutionAndAllBlocksWereExecuted", test_OperationQueueWaitsForExecutionAndAllBlocksWereExecuted ),
            ("test_BlockOperationWaitsForExecutionAndAllBlocksWereExecuted", test_BlockOperationWaitsForExecutionAndAllBlocksWereExecuted ),
            ("test_BlockOperationHasFinishedPropertyEqualTrueAfterItFinishes", test_BlockOperationHasFinishedPropertyEqualTrueAfterItFinishes ),
            ("test_BlockOperationHasExecutingPropertyEquaFalseAfterItFinishes", test_BlockOperationHasExecutingPropertyEquaFalseAfterItFinishes ),
            ("test_BlockOperationHasCancelledPropertyEqualFalseAfterItFinishes", test_BlockOperationHasCancelledPropertyEqualFalseAfterItFinishes ),
            ("test_BlockOperationHasFinishedPropertyEqualFalseBeforeItFinishes", test_BlockOperationHasFinishedPropertyEqualFalseBeforeItFinishes ),
            ("test_BlockOperationHasCancelPropertyEqualFalseBeforeItsCancelled", test_BlockOperationHasCancelPropertyEqualFalseBeforeItsCancelled ),
            ("test_BlockOperationHasCancelPropertyEqualTrueAfterItsCancelled", test_BlockOperationHasCancelPropertyEqualTrueAfterItsCancelled ),
            ("test_BlockOperationHasFinishedPropertyEqualTrueAfterItsCancelled", test_BlockOperationHasFinishedPropertyEqualTrueAfterItsCancelled ),
        ]
    }

    func test_OperationQueueWaitsForExecutionAndAllBlocksWereExecuted() {

        let operation = NSBlockOperation()
        let queue = NSOperationQueue()

        var block1Executed = false
        var block2Executed = false

        operation.addExecutionBlock({  block1Executed = true })
        operation.addExecutionBlock({  block2Executed = true })

        queue.addOperation(operation)
        queue.waitUntilAllOperationsAreFinished()

        XCTAssertTrue(block1Executed)
        XCTAssertTrue(block2Executed)
    }

    func test_BlockOperationWaitsForExecutionAndAllBlocksWereExecuted() {

        let operation = NSBlockOperation()

        var block1Executed = false
        var block2Executed = false

        operation.addExecutionBlock({  block1Executed = true })
        operation.addExecutionBlock({  block2Executed = true })

        operation.start()
        operation.waitUntilFinished()

        XCTAssertTrue(block1Executed)
        XCTAssertTrue(block2Executed)
    }

    func test_BlockOperationHasFinishedPropertyEqualTrueAfterItFinishes() {

        let operation = NSBlockOperation()

        operation.addExecutionBlock({  })
        operation.addExecutionBlock({  })

        operation.start()
        operation.waitUntilFinished()

        XCTAssertTrue(operation.finished)
    }

    func test_BlockOperationHasExecutingPropertyEquaFalseAfterItFinishes() {

        let operation = NSBlockOperation()

        operation.addExecutionBlock({  })
        operation.addExecutionBlock({  })

        operation.start()
        operation.waitUntilFinished()

        XCTAssertFalse(operation.executing)
    }

    func test_BlockOperationHasCancelledPropertyEqualFalseAfterItFinishes() {

        let operation = NSBlockOperation()

        operation.addExecutionBlock({  })
        operation.addExecutionBlock({  })

        operation.start()
        operation.waitUntilFinished()

        XCTAssertFalse(operation.cancelled)
    }

    func test_BlockOperationHasFinishedPropertyEqualFalseBeforeItFinishes() {

        let operation = NSBlockOperation()

        XCTAssertFalse(operation.finished)
    }

    func test_BlockOperationHasCancelPropertyEqualFalseBeforeItsCancelled() {

        let operation = NSBlockOperation()

        XCTAssertFalse(operation.cancelled)
    }

    func test_BlockOperationHasExecutingPropertyEqualFalseBeforeItsStarted() {

        let operation = NSBlockOperation()

        XCTAssertFalse(operation.executing)
    }

    func test_BlockOperationHasCancelPropertyEqualTrueAfterItsCancelled() {

        let operation = NSBlockOperation()

        operation.cancel()

        XCTAssertTrue(operation.cancelled)
    }

    func test_BlockOperationHasFinishedPropertyEqualTrueAfterItsCancelled() {

        let operation = NSBlockOperation()

        operation.cancel()

        XCTAssertTrue(operation.finished)
    }
}
