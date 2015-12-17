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


class TestNSRunLoop : XCTestCase {
    var allTests : [(String, () -> ())] {
        return [
            ("test_runLoopInit", test_runLoopInit),
            ("test_runLoopRunMode", test_runLoopRunMode),
            ("test_runLoopLimitDate", test_runLoopLimitDate),
        ]
    }
    
    func test_runLoopInit() {
        let mainRunLoop = NSRunLoop.mainRunLoop()
        XCTAssertNotNil(mainRunLoop)
        let currentRunLoop = NSRunLoop.currentRunLoop()
        XCTAssertNotNil(currentRunLoop)
    }
    
    func test_runLoopRunMode() {
        let runLoop = NSRunLoop.currentRunLoop()
        let timeInterval = NSTimeInterval(0.05)
        let endDate = NSDate(timeInterval: timeInterval, sinceDate: NSDate())
        var flag = false

        let dummyTimer = NSTimer.scheduledTimer(0.01, repeats: false) { _ in
            flag = true
            guard let runLoopMode = runLoop.currentMode else {
                XCTFail("Run loop mode is not defined")
                return
            }
            
            XCTAssertEqual(runLoopMode, NSDefaultRunLoopMode)
        }
        runLoop.addTimer(dummyTimer, forMode: NSDefaultRunLoopMode)
        let result = runLoop.runMode(NSDefaultRunLoopMode, beforeDate: endDate)
        
        XCTAssertFalse(result) // should be .Finished
        XCTAssertTrue(flag)
    }
    
    func test_runLoopLimitDate() {
        let runLoop = NSRunLoop.currentRunLoop()
        let timeInterval = NSTimeInterval(1)
        let expectedTimeInterval = NSDate(timeInterval: timeInterval, sinceDate: NSDate()).timeIntervalSince1970

        let dummyTimer = NSTimer.scheduledTimer(timeInterval, repeats: false) { _ in }
        runLoop.addTimer(dummyTimer, forMode: NSDefaultRunLoopMode)
        
        guard let timerTickInterval = runLoop.limitDateForMode(NSDefaultRunLoopMode)?.timeIntervalSince1970 else {
            XCTFail()
            return
        }
        
        XCTAssertLessThan(abs(timerTickInterval - expectedTimeInterval), 0.01)
    }
    
}
