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


class TestNSTimer : XCTestCase {
    var allTests : [(String, () throws -> ())] {
        return [
            ("test_timerInit", test_timerInit),
            ("test_timerTickOnce", test_timerTickOnce),
            ("test_timerRepeats", test_timerRepeats),
            ("test_timerInvalidate", test_timerInvalidate),
        ]
    }
    
    func test_timerInit() {
        let timer = NSTimer(fireDate: NSDate(), interval: 0.3, repeats: false) { _ in }
        XCTAssertNotNil(timer)
    }
    
    func test_timerTickOnce() {
        var flag = false
        
        let dummyTimer = NSTimer.scheduledTimer(0.01, repeats: false) { timer in
            XCTAssertFalse(flag)

            flag = true
            timer.invalidate()
        }

        let runLoop = NSRunLoop.currentRunLoop()
        runLoop.addTimer(dummyTimer, forMode: NSDefaultRunLoopMode)
        runLoop.runUntilDate(NSDate(timeIntervalSinceNow: 0.05))
        
        XCTAssertTrue(flag)
    }

    func test_timerRepeats() {
        var flag = 0
        let interval = NSTimeInterval(0.1)
        let numberOfRepeats = 3
        var previousInterval = NSDate().timeIntervalSince1970
        
        let dummyTimer = NSTimer.scheduledTimer(interval, repeats: true) { timer in
            XCTAssertEqual(timer.timeInterval, interval)

            let currentInterval = NSDate().timeIntervalSince1970
            XCTAssertEqualWithAccuracy(currentInterval, previousInterval + interval, accuracy: 0.01)
            previousInterval = currentInterval
            
            flag += 1
            if (flag == numberOfRepeats) {
                timer.invalidate()
            }
        }
        
        let runLoop = NSRunLoop.currentRunLoop()
        runLoop.addTimer(dummyTimer, forMode: NSDefaultRunLoopMode)
        runLoop.runUntilDate(NSDate(timeIntervalSinceNow: interval * Double(numberOfRepeats + 1)))
        
        XCTAssertEqual(flag, numberOfRepeats)
    }

    func test_timerInvalidate() {
        var flag = false
        
        let dummyTimer = NSTimer.scheduledTimer(0.01, repeats: true) { timer in
            XCTAssertTrue(timer.valid)
            XCTAssertFalse(flag) // timer should tick only once
            
            flag = true
            
            timer.invalidate()
            XCTAssertFalse(timer.valid)
        }
        
        let runLoop = NSRunLoop.currentRunLoop()
        runLoop.addTimer(dummyTimer, forMode: NSDefaultRunLoopMode)
        runLoop.runUntilDate(NSDate(timeIntervalSinceNow: 0.05))
        
        XCTAssertTrue(flag)
    }

}
