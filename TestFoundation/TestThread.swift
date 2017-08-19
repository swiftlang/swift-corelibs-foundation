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

import CoreFoundation

class TestThread : XCTestCase {
    static var allTests: [(String, (TestThread) -> () throws -> Void)] {
        return [
            ("test_currentThread", test_currentThread ),
            ("test_threadStart", test_threadStart),
            ("test_threadName", test_threadName),
            ("test_mainThread", test_mainThread),
            ("test_callStackSymbols", test_callStackSymbols),
            ("test_callStackReurnAddresses", test_callStackReturnAddresses),
        ]
    }

    func test_currentThread() {
        let thread1 = Thread.current
        let thread2 = Thread.current
        XCTAssertNotNil(thread1)
        XCTAssertNotNil(thread2)
        XCTAssertEqual(thread1, thread2)
        XCTAssertEqual(thread1, Thread.mainThread)
    }
    
    func test_threadStart() {
        let condition = NSCondition()
        let thread = Thread() {
            condition.lock()
            condition.broadcast()
            condition.unlock()
        }
        thread.start()
        
        condition.lock()
        let ok = condition.wait(until: Date(timeIntervalSinceNow: 10))
        condition.unlock()
        XCTAssertTrue(ok, "NSCondition wait timed out")
    }
    
    func test_threadName() {
        let thread = Thread()
        XCTAssertNil(thread.name)

        func getPThreadName() -> String? {
            var buf = [Int8](repeating: 0, count: 16)
            let r = _CFThreadGetName(&buf, Int32(buf.count))

            guard r == 0 else {
                return nil
            }
            return String(cString: buf)
        }

        let thread2 = Thread() {
            Thread.current.name = "Thread2"
            XCTAssertEqual(Thread.current.name, "Thread2")
            XCTAssertEqual(Thread.current.name, getPThreadName())
        }

        thread2.start()

        Thread.current.name = "CurrentThread"
        XCTAssertEqual(Thread.current.name, getPThreadName())

        let thread3 = Thread()
        thread3.name = "Thread3"
        XCTAssertEqual(thread3.name, "Thread3")
        XCTAssertNotEqual(thread3.name, getPThreadName())
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
        let thread = Thread() {
            condition.lock()
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertFalse(Thread.mainThread == Thread.current)
            condition.broadcast()
            condition.unlock()
        }
        thread.start()

        condition.lock()
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
