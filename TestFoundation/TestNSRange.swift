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


class TestNSRange : XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            // currently disabled due to pending requirements for NSString
            // ("test_NSRangeFromString", test_NSRangeFromString ),
            ("test_NSRangeBridging", test_NSRangeBridging)
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
        let swiftRange = 1..<7
        let range = NSRange(swiftRange)
        let swiftRange2 = range.toRange()
        XCTAssertEqual(swiftRange, swiftRange2)
    }
}