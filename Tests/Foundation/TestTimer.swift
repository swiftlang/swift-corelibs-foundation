// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Synchronization

class TestTimer : XCTestCase {
    func test_timerInit() {
        let fireDate = Date()
        let timeInterval: TimeInterval = 0.3

        let timer = Timer(fire: fireDate, interval: timeInterval, repeats: false) { _ in }
        XCTAssertEqual(timer.fireDate, fireDate)
        XCTAssertEqual(timer.timeInterval, 0, "Time interval should be 0 for a non repeating Timer")
        XCTAssert(timer.isValid)

        let repeatingTimer = Timer(fire: fireDate, interval: timeInterval, repeats: true) { _ in }
        XCTAssertEqual(repeatingTimer.fireDate, fireDate)
        XCTAssertEqual(repeatingTimer.timeInterval, timeInterval)
        XCTAssert(timer.isValid)
    }
    
    func test_timerTickOnce() {
        let flag = Atomic(false)
        
        let dummyTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { timer in
            
            let (exchanged, original) = flag.compareExchange(expected: false, desired: true, ordering: .relaxed)
            XCTAssertFalse(original)
            XCTAssertTrue(exchanged)
            timer.invalidate()
        }

        let runLoop = RunLoop.current
        runLoop.add(dummyTimer, forMode: .default)
        runLoop.run(until: Date(timeIntervalSinceNow: 0.05))
        
        XCTAssertTrue(flag.load(ordering: .relaxed))
    }

    func test_timerRepeats() {
        let flag = Mutex(0)
        let interval = TimeInterval(0.1)
        let numberOfRepeats = 3
        let previousInterval = Mutex(Date().timeIntervalSince1970)
        
        let dummyTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            XCTAssertEqual(timer.timeInterval, interval)

            let currentInterval = Date().timeIntervalSince1970
            previousInterval.withLock {
                XCTAssertEqual(currentInterval, $0 + interval, accuracy: 0.2)
                $0 = currentInterval
            }
            
            let invalidate = flag.withLock {
                $0 += 1
                if $0 == numberOfRepeats {
                    return true
                } else {
                    return false
                }
            }
            
            if invalidate {
                timer.invalidate()
            }
        }
        
        let runLoop = RunLoop.current
        runLoop.add(dummyTimer, forMode: .default)
        runLoop.run(until: Date(timeIntervalSinceNow: interval * Double(numberOfRepeats + 1)))
        
        flag.withLock {
            XCTAssertEqual($0, numberOfRepeats)
        }
    }

    func test_timerInvalidate() {
        // Only mutated once, protected by behavior of RunLoop validated in this test
        nonisolated(unsafe) var flag = false
        
        let dummyTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            XCTAssertTrue(timer.isValid)
            XCTAssertFalse(flag) // timer should tick only once
            
            flag = true
            
            timer.invalidate()
            XCTAssertFalse(timer.isValid)
        }
        
        let runLoop = RunLoop.current
        runLoop.add(dummyTimer, forMode: .default)
        runLoop.run(until: Date(timeIntervalSinceNow: 0.05))
        
        XCTAssertTrue(flag)
    }

}
