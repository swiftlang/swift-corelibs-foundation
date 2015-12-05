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


class TestNSPipe : XCTestCase {
    
    func test_NSPipe() {
        let expectation = self.expectationWithDescription("Should read data")
        let aPipe = XNPipe()
        
        let text = "test-pipe"
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            let data = aPipe.fileHandleForReading.readDataOfLength(text.characters.count)
            if String(data: data, encoding: NSUTF8StringEncoding) == text {
                expectation.fulfill()
            }
        }
        
        aPipe.fileHandleForWriting.writeData(text.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}