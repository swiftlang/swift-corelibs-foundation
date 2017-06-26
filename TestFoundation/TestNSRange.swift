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


class TestNSRange : XCTestCase {
    
    static var allTests: [(String, (TestNSRange) -> () throws -> Void)] {
        return [
            ("test_NSRangeFromString", test_NSRangeFromString ),
            ("test_NSRangeBridging", test_NSRangeBridging),
            ("test_NSMaxRange", test_NSMaxRange),
            ("test_NSLocationInRange", test_NSLocationInRange),
            ("test_NSEqualRanges", test_NSEqualRanges),
            ("test_NSUnionRange", test_NSUnionRange),
            ("test_NSIntersectionRange", test_NSIntersectionRange),
            ("test_NSStringFromRange", test_NSStringFromRange),
        ]
    }
    
    func test_NSRangeFromString() {
        let emptyRangeStrings = [
            "",
            "{}",
            "{a, b}",
        ]
        let emptyRange = NSMakeRange(0, 0)
        for string in emptyRangeStrings {
            XCTAssert(NSEqualRanges(NSRangeFromString(string), emptyRange))
        }

        let partialRangeStrings = [
            "12",
            "[12]",
            "{12",
            "{12,",
        ]
        let partialRange = NSMakeRange(12, 0)
        for string in partialRangeStrings {
            XCTAssert(NSEqualRanges(NSRangeFromString(string), partialRange))
        }

        let fullRangeStrings = [
            "{12, 34}",
            "[12, 34]",
            "12.34",
        ]
        let fullRange = NSMakeRange(12, 34)
        for string in fullRangeStrings {
            XCTAssert(NSEqualRanges(NSRangeFromString(string), fullRange))
        }
    }
    
    func test_NSRangeBridging() {
        let swiftRange: Range<Int> = 1..<7
        let range = NSRange(swiftRange)
        let swiftRange2 = Range(range)
        XCTAssertEqual(swiftRange, swiftRange2)
    }

    func test_NSMaxRange() {
        let ranges = [(NSMakeRange(0, 3), 3),
                      (NSMakeRange(7, 8), 15),
                      (NSMakeRange(56, 1), 57)]
        for (range, result) in ranges {
            XCTAssertEqual(NSMaxRange(range), result)
        }
    }

    func test_NSLocationInRange() {
        let ranges = [(3, NSMakeRange(0, 5), true),
                      (10, NSMakeRange(2, 9), true),
                      (7, NSMakeRange(2, 5), false),
                      (5, NSMakeRange(5, 1), true)];
        for (location, range, result) in ranges {
            XCTAssertEqual(NSLocationInRange(location, range), result);
        }
    }

    func test_NSEqualRanges() {
        let ranges = [(NSMakeRange(0, 3), NSMakeRange(0, 3), true),
                      (NSMakeRange(0, 4), NSMakeRange(0, 8), false),
                      (NSMakeRange(3, 6), NSMakeRange(3, 10), false),
                      (NSMakeRange(0, 5), NSMakeRange(7, 8), false)]
        for (first, second, result) in ranges {
            XCTAssertEqual(NSEqualRanges(first, second), result)
        }
    }

    
    func test_NSUnionRange() {
        let ranges = [(NSMakeRange(0, 5), NSMakeRange(3, 8), NSMakeRange(0, 11)),
                      (NSMakeRange(6, 10), NSMakeRange(3, 8), NSMakeRange(3, 13)),
                      (NSMakeRange(3, 8), NSMakeRange(6, 10), NSMakeRange(3, 13)),
                      (NSMakeRange(0, 5), NSMakeRange(7, 8), NSMakeRange(0, 15)),
                      (NSMakeRange(0, 3), NSMakeRange(1, 2), NSMakeRange(0, 3))]
        for (first, second, result) in ranges {
            XCTAssert(NSEqualRanges(NSUnionRange(first, second), result))
        }
    }

    func test_NSIntersectionRange() {
        let ranges = [(NSMakeRange(0, 5), NSMakeRange(3, 8), NSMakeRange(3, 2)),
                      (NSMakeRange(6, 10), NSMakeRange(3, 8), NSMakeRange(6, 5)),
                      (NSMakeRange(3, 8), NSMakeRange(6, 10), NSMakeRange(6, 5)),
                      (NSMakeRange(0, 5), NSMakeRange(7, 8), NSMakeRange(0, 0)),
                      (NSMakeRange(0, 3), NSMakeRange(1, 2), NSMakeRange(1, 2))]
        for (first, second, result) in ranges {
            XCTAssert(NSEqualRanges(NSIntersectionRange(first, second), result))
        }
    }

    func test_NSStringFromRange() {
        let ranges = ["{0, 0}": NSMakeRange(0, 0),
                      "{6, 4}": NSMakeRange(6, 4),
                      "{0, 10}": NSMakeRange(0, 10),
                      "{10, 200}": NSMakeRange(10, 200),
                      "{100, 10}": NSMakeRange(100, 10),
                      "{1000, 100000}": NSMakeRange(1000, 100_000)];

        for (string, range) in ranges {
            XCTAssertEqual(NSStringFromRange(range), string)
        }
    }
}
