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
    static var allTests: [(String, (TestThread) -> () throws -> Void)] {
        var tests: [(String, (TestThread) -> () throws -> Void)] = [
            ("test_currentThread", test_currentThread),
            ("test_threadStart", test_threadStart),
            ("test_mainThread", test_mainThread),
            ("test_callStackSymbols", testExpectedToFailOnAndroid(test_callStackSymbols, "Android doesn't support backtraces at the moment.")),
            ("test_callStackReturnAddresses", testExpectedToFailOnAndroid(test_callStackReturnAddresses, "Android doesn't support backtraces at the moment.")),
        ]

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
        tests.append(contentsOf: [
            ("test_threadName", test_threadName),
        ])
#endif

        return tests
    }

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
    
#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    func test_threadName() {
#if os(Linux) || os(Android) // Linux sets the initial thread name to the process name.
        XCTAssertEqual(Thread.current.name, "TestFoundation")
        XCTAssertEqual(Thread.current._name, "TestFoundation")
#else
        // No name is set initially
        XCTAssertEqual(Thread.current.name, "")
        XCTAssertEqual(Thread.current._name, "")
#endif
        Thread.current.name = "mainThread"
        XCTAssertEqual(Thread.mainThread.name, "mainThread")
        XCTAssertEqual(Thread.mainThread._name, "mainThread")

        let condition = NSCondition()
        condition.lock()

        let thread2 = Thread() {
            XCTAssertEqual(Thread.current.name, "Thread2-1")

            Thread.current.name = "Thread2-2"
            XCTAssertEqual(Thread.current.name, "Thread2-2")
            XCTAssertEqual(Thread.current._name, Thread.current.name)

            Thread.current.name = "12345678901234567890"
            XCTAssertEqual(Thread.current.name, "12345678901234567890")
#if os(macOS) || os(iOS)
            XCTAssertEqual(Thread.current._name, Thread.current.name)
#elseif os(Linux) || os(Android)
            // pthread_setname_np() only allows 15 characters on Linux, so setting it fails
            // and the previous name will still be there.
            XCTAssertEqual(Thread.current._name, "Thread2-2")
#endif
            condition.lock()
            condition.signal()
            condition.unlock()
        }
        thread2.name = "Thread2-1"
        thread2.start()

        // Allow 1 second for thread2 to finish
        XCTAssertTrue(condition.wait(until: Date(timeIntervalSinceNow: 1)))
        condition.unlock()

        XCTAssertEqual(Thread.current.name, "mainThread")
        XCTAssertEqual(Thread.mainThread.name, "mainThread")
        let thread3 = Thread()
        thread3.name = "Thread3"
        XCTAssertEqual(thread3.name, "Thread3")
    }
#endif

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
}
