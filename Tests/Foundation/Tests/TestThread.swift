// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if !(os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
    import CoreFoundation
#endif

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
        @testable import SwiftFoundation
    #else
        @testable import Foundation
    #endif
#endif

class TestThread : XCTestCase {

    func test_currentThread() {
        let thread1 = Thread.current
        let thread2 = Thread.current
        XCTAssertEqual(thread1, thread2)
        XCTAssertEqual(thread1, Thread.mainThread)
    }
    
    func test_threadStart() {
        let condition = NSCondition()
        condition.lock()

        let thread = Thread() {
            condition.lock()
            condition.broadcast()
            condition.unlock()
        }
        XCTAssertEqual(thread.qualityOfService, .default)
        thread.start()

        let ok = condition.wait(until: Date(timeIntervalSinceNow: 2))
        condition.unlock()
        XCTAssertTrue(ok, "NSCondition wait timed out")
    }
    
    func test_threadName() {

        func testInternalThreadName(_ name: String?) {
#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
            XCTAssertEqual(Thread.current._name, name)
#endif
        }

#if os(Linux) || os(Android) // Linux sets the initial thread name to the process name.
        XCTAssertEqual(Thread.current.name, "TestFoundation")
        testInternalThreadName("TestFoundation")
#else
        // No name is set initially
        XCTAssertEqual(Thread.current.name, "")
        testInternalThreadName("")
#endif
        Thread.current.name = "mainThread"
        XCTAssertEqual(Thread.mainThread.name, "mainThread")
        testInternalThreadName("mainThread")

        Thread.current.name = "12345678901234567890"
#if os(Linux) || os(Android)
        // pthread_setname_np() only allows 15 characters on Linux, so setting it fails
        // and the previous name will still be there.
        XCTAssertEqual(Thread.current.name, "mainThread")
#else
        XCTAssertEqual(Thread.current.name, "12345678901234567890")
#endif
        testInternalThreadName(Thread.current.name)
    }

    func test_mainThread() {
        XCTAssertTrue(Thread.isMainThread)
        let t = Thread.mainThread
        XCTAssertTrue(t.isMainThread)
        let c = Thread.current
        XCTAssertTrue(c.isMainThread)
        XCTAssertTrue(c.isExecuting)
        XCTAssertTrue(c.isEqual(t))

        let condition = NSCondition()
        condition.lock()

        let thread = Thread() {
            condition.lock()
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertFalse(Thread.mainThread == Thread.current)
            condition.broadcast()
            condition.unlock()
        }
        thread.start()

        let ok = condition.wait(until: Date(timeIntervalSinceNow: 10))
        condition.unlock()
        XCTAssertTrue(ok, "NSCondition wait timed out")
    }

    func test_callStackSymbols() {
        let symbols = Thread.callStackSymbols
        XCTAssertTrue(symbols.count > 0)
        XCTAssertTrue(symbols.count <= 128)
    }

    func test_callStackReturnAddresses() {
        let addresses = Thread.callStackReturnAddresses
        XCTAssertTrue(addresses.count > 0)
        XCTAssertTrue(addresses.count <= 128)
    }
    
    func test_sleepForTimeInterval() {
        let measureOversleep = { (timeInterval: TimeInterval) -> TimeInterval in
            let start = Date()
            Thread.sleep(forTimeInterval: timeInterval)

            // Measures time Thread.sleep spends over specified timeInterval value
            return -(start.timeIntervalSinceNow + timeInterval)
        }

        // Allow a little early wake-ups. Sleep timer on Windows
        // is more precise than timer used in Date implementation.
        let allowedOversleepRange = -0.00001..<0.1

        let oversleep1 = measureOversleep(TimeInterval(0.9))
        XCTAssertTrue(allowedOversleepRange.contains(oversleep1), "Oversleep \(oversleep1) is not in expected range \(allowedOversleepRange)")

        let oversleep2 = measureOversleep(TimeInterval(1.2))
        XCTAssertTrue(allowedOversleepRange.contains(oversleep2), "Oversleep \(oversleep2) is not in expected range \(allowedOversleepRange)")

        let oversleep3 = measureOversleep(TimeInterval(1.0))
        XCTAssertTrue(allowedOversleepRange.contains(oversleep3), "Oversleep \(oversleep3) is not in expected range \(allowedOversleepRange)")
    }

    func test_sleepUntilDate() {
        let measureOversleep = { (date: Date) -> TimeInterval in
            Thread.sleep(until: date)
            return -date.timeIntervalSinceNow
        }

        let allowedOversleepRange = -0.00001..<0.1

        let oversleep1 = measureOversleep(Date(timeIntervalSinceNow: 0.8))
        XCTAssertTrue(allowedOversleepRange.contains(oversleep1), "Oversleep \(oversleep1) is not in expected range \(allowedOversleepRange)")

        let oversleep2 = measureOversleep(Date(timeIntervalSinceNow: 1.1))
        XCTAssertTrue(allowedOversleepRange.contains(oversleep2), "Oversleep \(oversleep2) is not in expected range \(allowedOversleepRange)")

        let oversleep3 = measureOversleep(Date(timeIntervalSinceNow: 1.0))
        XCTAssertTrue(allowedOversleepRange.contains(oversleep3), "Oversleep \(oversleep3) is not in expected range \(allowedOversleepRange)")
    }

    static var allTests: [(String, (TestThread) -> () throws -> Void)] {
        let tests: [(String, (TestThread) -> () throws -> Void)] = [
            ("test_currentThread", test_currentThread),
            ("test_threadStart", test_threadStart),
            ("test_mainThread", test_mainThread),
            ("test_callStackSymbols", testExpectedToFailOnAndroid(test_callStackSymbols, "Android doesn't support backtraces at the moment.")),
            ("test_callStackReturnAddresses", testExpectedToFailOnAndroid(test_callStackReturnAddresses, "Android doesn't support backtraces at the moment.")),
            ("test_sleepForTimeInterval", test_sleepForTimeInterval),
            ("test_sleepUntilDate", test_sleepUntilDate),
            ("test_threadName", test_threadName),
        ]

        return tests
    }
}
