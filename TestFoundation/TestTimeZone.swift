// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// RUN: rm -rf %t
// RUN: mkdir -p %t
//
// RUN: %target-clang %S/Inputs/FoundationBridge/FoundationBridge.m -c -o %t/FoundationBridgeObjC.o -g
// RUN: %target-build-swift %s -I %S/Inputs/FoundationBridge/ -Xlinker %t/FoundationBridgeObjC.o -o %t/TestTimeZone

// RUN: %target-run %t/TestTimeZone > %t.txt
// REQUIRES: executable_test
// REQUIRES: objc_interop

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#elseif DEPLOYMENT_RUNTIME_SWIFT
import SwiftFoundation
import SwiftXCTest
#endif

class TestTimeZone : XCTestCase {
    static var allTests: [(String, (TestTimeZone) -> () throws -> Void)] {
        return [
            ("test_timeZoneBasics", test_timeZoneBasics),
            ("test_bridgingAutoupdating", test_bridgingAutoupdating),
            ("test_equality", test_equality),
            ("test_AnyHashableContainingTimeZone", test_AnyHashableContainingTimeZone),
            ("test_AnyHashableCreatedFromNSTimeZone", test_AnyHashableCreatedFromNSTimeZone),
        ]
    }
    func test_timeZoneBasics() {
        let tz = TimeZone(identifier: "America/Los_Angeles")!
        
        XCTAssertTrue(!tz.identifier.isEmpty)
    }
    
    func test_bridgingAutoupdating() {
#if !DEPLOYMENT_RUNTIME_SWIFT
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
#endif
    }
    
    func test_equality() {
#if !DEPLOYMENT_RUNTIME_SWIFT
        let autoupdating = TimeZone.autoupdatingCurrent
        let autoupdating2 = TimeZone.autoupdatingCurrent
        
        XCTAssertEqual(autoupdating, autoupdating2)
        
        let current = TimeZone.current
        
        XCTAssertNotEqual(autoupdating, current)
#endif
        let tz1 = TimeZone(identifier: "America/Los_Angeles")!
        let tz2 = TimeZone(identifier: "America/Los_Angeles")!
        let tz3 = TimeZone(identifier: "Europe/Kiev")!
        XCTAssertEqual(tz1, tz2)
        XCTAssertNotEqual(tz1, tz3)
    }
    
    func test_AnyHashableContainingTimeZone() {
        let values: [TimeZone] = [
            TimeZone(identifier: "America/Los_Angeles")!,
            TimeZone(identifier: "Europe/Kiev")!,
            TimeZone(identifier: "Europe/Kiev")!,
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(TimeZone.self, type(of: anyHashables[0].base))
        XCTAssertSameType(TimeZone.self, type(of: anyHashables[1].base))
        XCTAssertSameType(TimeZone.self, type(of: anyHashables[2].base))
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
        XCTAssertSameType(TimeZone.self, type(of: anyHashables[0].base))
        XCTAssertSameType(TimeZone.self, type(of: anyHashables[1].base))
        XCTAssertSameType(TimeZone.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}
