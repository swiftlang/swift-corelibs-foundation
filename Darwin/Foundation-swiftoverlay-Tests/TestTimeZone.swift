//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest

class TestTimeZone : XCTestCase {
    
    func test_timeZoneBasics() {
        let tz = TimeZone(identifier: "America/Los_Angeles")!
        
        XCTAssertTrue(!tz.identifier.isEmpty)
    }
    
    func test_bridgingAutoupdating() {
        let tester = TimeZoneBridgingTester()
        
        do {
            let tz = TimeZone.autoupdatingCurrent
            let result = tester.verifyAutoupdating(tz)
            XCTAssertTrue(result)
        }
        
        // Round trip an autoupdating calendar
        do {
            let tz = tester.autoupdatingCurrentTimeZone()
            let result = tester.verifyAutoupdating(tz)
            XCTAssertTrue(result)
        }
    }
    
    func test_equality() {
        let autoupdating = TimeZone.autoupdatingCurrent
        let autoupdating2 = TimeZone.autoupdatingCurrent

        XCTAssertEqual(autoupdating, autoupdating2)
        
        let current = TimeZone.current
        
        XCTAssertNotEqual(autoupdating, current)
    }

    func test_AnyHashableContainingTimeZone() {
        let values: [TimeZone] = [
            TimeZone(identifier: "America/Los_Angeles")!,
            TimeZone(identifier: "Europe/Kiev")!,
            TimeZone(identifier: "Europe/Kiev")!,
        ]
        let anyHashables = values.map(AnyHashable.init)
        expectEqual(TimeZone.self, type(of: anyHashables[0].base))
        expectEqual(TimeZone.self, type(of: anyHashables[1].base))
        expectEqual(TimeZone.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }

    func test_AnyHashableCreatedFromNSTimeZone() {
        let values: [NSTimeZone] = [
            NSTimeZone(name: "America/Los_Angeles")!,
            NSTimeZone(name: "Europe/Kiev")!,
            NSTimeZone(name: "Europe/Kiev")!,
        ]
        let anyHashables = values.map(AnyHashable.init)
        expectEqual(TimeZone.self, type(of: anyHashables[0].base))
        expectEqual(TimeZone.self, type(of: anyHashables[1].base))
        expectEqual(TimeZone.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}
