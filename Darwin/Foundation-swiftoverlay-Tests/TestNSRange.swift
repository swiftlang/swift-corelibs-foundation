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

class TestNSRange : XCTestCase {
    func testEquality() {
        let r1 = NSRange(location: 1, length: 10)
        let r2 = NSRange(location: 1, length: 11)
        let r3 = NSRange(location: 2, length: 10)
        let r4 = NSRange(location: 1, length: 10)
        let r5 = NSRange(location: NSNotFound, length: 0)
        let r6 = NSRange(location: NSNotFound, length: 2)

        XCTAssertNotEqual(r1, r2)
        XCTAssertNotEqual(r1, r3)
        XCTAssertEqual(r1, r4)
        XCTAssertNotEqual(r1, r5)
        XCTAssertNotEqual(r5, r6)
    }

    func testDescription() {
        let r1 = NSRange(location: 0, length: 22)
        let r2 = NSRange(location: 10, length: 22)
        let r3 = NSRange(location: NSNotFound, length: 0)
        let r4 = NSRange(location: NSNotFound, length: 22)
        XCTAssertEqual("{0, 22}", r1.description)
        XCTAssertEqual("{10, 22}", r2.description)
        XCTAssertEqual("{\(NSNotFound), 0}", r3.description)
        XCTAssertEqual("{\(NSNotFound), 22}", r4.description)

        XCTAssertEqual("{0, 22}", r1.debugDescription)
        XCTAssertEqual("{10, 22}", r2.debugDescription)
        XCTAssertEqual("{NSNotFound, 0}", r3.debugDescription)
        XCTAssertEqual("{NSNotFound, 22}", r4.debugDescription)
    }

    func testCreationFromString() {
        let r1 = NSRange("")
        XCTAssertNil(r1)
        let r2 = NSRange("1")
        XCTAssertNil(r2)
        let r3 = NSRange("1 2")
        XCTAssertEqual(NSRange(location: 1, length: 2), r3)
        let r4 = NSRange("{1 8")
        XCTAssertEqual(NSRange(location: 1, length: 8), r4)
        let r5 = NSRange("1.8")
        XCTAssertNil(r5)
        let r6 = NSRange("1-9")
        XCTAssertEqual(NSRange(location: 1, length: 9), r6)
        let r7 = NSRange("{1,9}")
        XCTAssertEqual(NSRange(location: 1, length: 9), r7)
        let r8 = NSRange("{1,9}asdfasdf")
        XCTAssertEqual(NSRange(location: 1, length: 9), r8)
        let r9 = NSRange("{1,9}{2,7}")
        XCTAssertEqual(NSRange(location: 1, length: 9), r9)
        let r10 = NSRange("{１,９}")        
        XCTAssertEqual(NSRange(location: 1, length: 9), r10)
        let r11 = NSRange("{1.0,9}")
        XCTAssertEqual(NSRange(location: 1, length: 9), r11)
        let r12 = NSRange("{1,9.0}")
        XCTAssertEqual(NSRange(location: 1, length: 9), r12)
        let r13 = NSRange("{1.2,9}")
        XCTAssertNil(r13)
        let r14 = NSRange("{1,9.8}")
        XCTAssertNil(r14)
    }

    func testHashing() {
        let large = Int.max >> 2
        let samples: [NSRange] = [
            NSRange(location: 1, length: 1),
            NSRange(location: 1, length: 2),
            NSRange(location: 2, length: 1),
            NSRange(location: 2, length: 2),
            NSRange(location: large, length: large),
            NSRange(location: 0, length: large),
            NSRange(location: large, length: 0),
        ]
        checkHashable(samples, equalityOracle: { $0 == $1 })
    }

    func testBounding() {
        let r1 = NSRange(location: 1000, length: 2222)
        XCTAssertEqual(r1.location, r1.lowerBound)
        XCTAssertEqual(r1.location + r1.length, r1.upperBound)
    }

    func testContains() {
        let r1 = NSRange(location: 1000, length: 2222)
        XCTAssertFalse(r1.contains(3))
        XCTAssertTrue(r1.contains(1001))
        XCTAssertFalse(r1.contains(4000))
    }

    func testUnion() {
        let r1 = NSRange(location: 10, length: 20)
        let r2 = NSRange(location: 30, length: 5)
        let union1 = r1.union(r2)

        XCTAssertEqual(Swift.min(r1.lowerBound, r2.lowerBound), union1.lowerBound)
        XCTAssertEqual(Swift.max(r1.upperBound, r2.upperBound), union1.upperBound)

        let r3 = NSRange(location: 10, length: 20)
        let r4 = NSRange(location: 11, length: 5)
        let union2 = r3.union(r4)

        XCTAssertEqual(Swift.min(r3.lowerBound, r4.lowerBound), union2.lowerBound)
        XCTAssertEqual(Swift.max(r3.upperBound, r4.upperBound), union2.upperBound)
        
        let r5 = NSRange(location: 10, length: 20)
        let r6 = NSRange(location: 11, length: 29)
        let union3 = r5.union(r6)
        
        XCTAssertEqual(Swift.min(r5.lowerBound, r6.upperBound), union3.lowerBound)
        XCTAssertEqual(Swift.max(r5.upperBound, r6.upperBound), union3.upperBound)
    }

    func testIntersection() {
        let r1 = NSRange(location: 1, length: 7)
        let r2 = NSRange(location: 2, length: 20)
        let r3 = NSRange(location: 2, length: 2)
        let r4 = NSRange(location: 10, length: 7)

        let intersection1 = r1.intersection(r2)
        XCTAssertEqual(NSRange(location: 2, length: 6), intersection1)
        let intersection2 = r1.intersection(r3)
        XCTAssertEqual(NSRange(location: 2, length: 2), intersection2)
        let intersection3 = r1.intersection(r4)
        XCTAssertEqual(nil, intersection3)
    }
}
