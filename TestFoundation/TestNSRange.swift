//
//  TestNSRange.swift
//  Foundation
//
//  Created by Harlan Haskins on 12/3/15.
//  Copyright © 2015 Apple. All rights reserved.
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

extension NSRange: Equatable {}

public func ==(lhs: NSRange, rhs: NSRange) -> Bool {
    return lhs.location == rhs.location && lhs.length == rhs.length
}

class TestNSRange: XCTestCase {
    
    var allTests: [(String, () -> ())] {
        return [
            ("test_rangeWithValidInput", test_rangeWithValidInput),
            ("test_rangesWithInvalidInput", test_rangesWithInvalidInput),
            ("test_roundTrip", test_roundTrip)
        ]
    }
    
    func test_rangeWithValidInput() {
        let practice = NSRangeFromString("{4,5}")
        XCTAssertEqual(practice, NSRange(location: 4, length: 5))
    }
    
    func test_rangesWithInvalidInput() {
        XCTAssertEqual(NSRangeFromString("4,5}"), NSRange(location: 4, length: 5))
        XCTAssertEqual(NSRangeFromString("{4,5"), NSRange(location: 4, length: 5))
        XCTAssertEqual(NSRangeFromString("{4,}"), NSRange(location: 4, length: 0))
        XCTAssertEqual(NSRangeFromString(",4}"), NSRange(location: 4, length: 0))
        XCTAssertEqual(NSRangeFromString("4,5"), NSRange(location: 4, length: 5))
    }
    
    func test_roundTrip() {
        let initial = NSRange(location: 4, length: 5)
        XCTAssertEqual(NSRangeFromString(NSStringFromRange(initial)), initial)
    }
    
}
