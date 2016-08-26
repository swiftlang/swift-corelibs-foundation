// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// RUN: %target-run-simple-swift
// REQUIRES: executable_test
// REQUIRES: objc_interop

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#elseif DEPLOYMENT_RUNTIME_SWIFT
import SwiftFoundation
import SwiftXCTest
#endif

class TestDateInterval : XCTestCase {
    static var allTests: [(String, (TestDateInterval) -> () throws -> Void)] {
        return [
            ("test_compareDateIntervals", test_compareDateIntervals),
            ("test_isEqualToDateInterval", test_isEqualToDateInterval),
            ("test_checkIntersection", test_checkIntersection),
            ("test_validIntersections", test_validIntersections),
            ("test_AnyHashableContainingDateInterval", test_AnyHashableContainingDateInterval),
            ("test_AnyHashableCreatedFromNSDateInterval", test_AnyHashableCreatedFromNSDateInterval),
        ]
    }
    func dateWithString(_ str: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter.date(from: str)! as Date
    }

    func test_compareDateIntervals() {
        if #available(iOS 10.10, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            let start = dateWithString("2010-05-17 14:49:47 -0700")
            let duration: TimeInterval = 10000000.0
            let testInterval1 = DateInterval(start: start, duration: duration)
            let testInterval2 = DateInterval(start: start, duration: duration)
            XCTAssertEqual(testInterval1, testInterval2)
            XCTAssertEqual(testInterval2, testInterval1)
            XCTAssertEqual(testInterval1.compare(testInterval2), ComparisonResult.orderedSame)
            
            let testInterval3 = DateInterval(start: start, duration: 10000000000.0)
            XCTAssertTrue(testInterval1 < testInterval3)
            XCTAssertTrue(testInterval3 > testInterval1)
            
            let earlierStart = dateWithString("2009-05-17 14:49:47 -0700")
            let testInterval4 = DateInterval(start: earlierStart, duration: duration)
            
            XCTAssertTrue(testInterval4 < testInterval1)
            XCTAssertTrue(testInterval1 > testInterval4)
        }
    }

    func test_isEqualToDateInterval() {
        if #available(iOS 10.10, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            let start = dateWithString("2010-05-17 14:49:47 -0700")
            let duration = 10000000.0
            let testInterval1 = DateInterval(start: start, duration: duration)
            let testInterval2 = DateInterval(start: start, duration: duration)
            
            XCTAssertEqual(testInterval1, testInterval2)
            
            let testInterval3 = DateInterval(start: start, duration: 100.0)
            XCTAssertNotEqual(testInterval1, testInterval3)
        }
    }

    func test_checkIntersection() {
        if #available(iOS 10.10, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            let start1 = dateWithString("2010-05-17 14:49:47 -0700")
            let end1 = dateWithString("2010-08-17 14:49:47 -0700")
            
            let testInterval1 = DateInterval(start: start1, end: end1)
            
            let start2 = dateWithString("2010-02-17 14:49:47 -0700")
            let end2 = dateWithString("2010-07-17 14:49:47 -0700")
            
            let testInterval2 = DateInterval(start: start2, end: end2)
            
            XCTAssertTrue(testInterval1.intersects(testInterval2))
            
            let start3 = dateWithString("2010-10-17 14:49:47 -0700")
            let end3 = dateWithString("2010-11-17 14:49:47 -0700")
            
            let testInterval3 = DateInterval(start: start3, end: end3)
            
            XCTAssertFalse(testInterval1.intersects(testInterval3))
        }
    }

    func test_validIntersections() {
        if #available(iOS 10.10, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            let start1 = dateWithString("2010-05-17 14:49:47 -0700")
            let end1 = dateWithString("2010-08-17 14:49:47 -0700")
            
            let testInterval1 = DateInterval(start: start1, end: end1)
            
            let start2 = dateWithString("2010-02-17 14:49:47 -0700")
            let end2 = dateWithString("2010-07-17 14:49:47 -0700")
            
            let testInterval2 = DateInterval(start: start2, end: end2)
            
            let start3 = dateWithString("2010-05-17 14:49:47 -0700")
            let end3 = dateWithString("2010-07-17 14:49:47 -0700")
            
            let testInterval3 = DateInterval(start: start3, end: end3)
            
            let intersection1 = testInterval2.intersection(with: testInterval1)
            XCTAssertNotNil(intersection1)
            XCTAssertEqual(testInterval3, intersection1)
            
            let intersection2 = testInterval1.intersection(with: testInterval2)
            XCTAssertNotNil(intersection2)
            XCTAssertEqual(intersection1, intersection2)
        }
    }

    func test_containsDate() {
        if #available(iOS 10.10, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            let start = dateWithString("2010-05-17 14:49:47 -0700")
            let duration = 10000000.0
            
            let testInterval = DateInterval(start: start, duration: duration)
            let containedDate = dateWithString("2010-05-17 20:49:47 -0700")
            
            XCTAssertTrue(testInterval.contains(containedDate))
            
            let earlierStart = dateWithString("2009-05-17 14:49:47 -0700")
            XCTAssertFalse(testInterval.contains(earlierStart))
        }
    }

    func test_AnyHashableContainingDateInterval() {
        if #available(iOS 10.10, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            let start = dateWithString("2010-05-17 14:49:47 -0700")
            let duration = 10000000.0
            let values: [DateInterval] = [
                DateInterval(start: start, duration: duration),
                DateInterval(start: start, duration: duration / 2),
                DateInterval(start: start, duration: duration / 2),
            ]
            let anyHashables = values.map(AnyHashable.init)
            XCTAssertSameType(DateInterval.self, type(of: anyHashables[0].base))
            XCTAssertSameType(DateInterval.self, type(of: anyHashables[1].base))
            XCTAssertSameType(DateInterval.self, type(of: anyHashables[2].base))
            XCTAssertNotEqual(anyHashables[0], anyHashables[1])
            XCTAssertEqual(anyHashables[1], anyHashables[2])
        }
    }

    func test_AnyHashableCreatedFromNSDateInterval() {
        if #available(iOS 10.10, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            let start = dateWithString("2010-05-17 14:49:47 -0700")
            let duration = 10000000.0
            let values: [NSDateInterval] = [
                NSDateInterval(start: start, duration: duration),
                NSDateInterval(start: start, duration: duration / 2),
                NSDateInterval(start: start, duration: duration / 2),
            ]
            let anyHashables = values.map(AnyHashable.init)
            XCTAssertSameType(DateInterval.self, type(of: anyHashables[0].base))
            XCTAssertSameType(DateInterval.self, type(of: anyHashables[1].base))
            XCTAssertSameType(DateInterval.self, type(of: anyHashables[2].base))
            XCTAssertNotEqual(anyHashables[0], anyHashables[1])
            XCTAssertEqual(anyHashables[1], anyHashables[2])
        }
    }
}

