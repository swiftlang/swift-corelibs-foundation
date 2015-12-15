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



class TestNSMutableArray : XCTestCase {
    
    var allTests : [(String, () -> ())] {
        return [
            ("test_replaceObjectsInRangeWithObjectsFromArray", test_replaceObjectsInRangeWithObjectsFromArray),
        ]
    }
    
    func test_replaceObjectsInRangeWithObjectsFromArray() {
        let existing = [NSNumber(int: 1), NSNumber(int: 2), NSNumber(int: 3), NSNumber(int: 4), NSNumber(int: 5), NSNumber(int: 6)]
        let nsExisting = NSMutableArray(array: existing)
        let otherArr = [NSNumber(int: 7), NSNumber(int: 8), NSNumber(int: 9)]
        let range = NSMakeRange(3, 3)
        nsExisting.replaceObjectsInRange(range, withObjectsFromArray: otherArr)
        XCTAssertEqual((nsExisting[0] as! NSNumber).intValue, 1)
        XCTAssertEqual((nsExisting[1] as! NSNumber).intValue, 2)
        XCTAssertEqual((nsExisting[2] as! NSNumber).intValue, 3)
        XCTAssertEqual((nsExisting[3] as! NSNumber).intValue, 7)
        XCTAssertEqual((nsExisting[4] as! NSNumber).intValue, 8)
        XCTAssertEqual((nsExisting[5] as! NSNumber).intValue, 9)
    }
    
    func test_replaceObjectsInRangeWithObjectsFromArrayOtherRange() {
        let existing = [NSNumber(int: 1), NSNumber(int: 2), NSNumber(int: 3), NSNumber(int: 4), NSNumber(int: 5), NSNumber(int: 6)]
        let nsExisting = NSMutableArray(array: existing)
        let otherArr = [NSNumber(int: 7), NSNumber(int: 8), NSNumber(int: 9), NSNumber(int: 1), NSNumber(int: 2), NSNumber(int: 3)]
        let range = NSMakeRange(3, 3)
        let otherRange = NSMakeRange(2, 3)
        nsExisting.replaceObjectsInRange(range, withObjectsFromArray: otherArr, range: otherRange)
        XCTAssertEqual((nsExisting[0] as! NSNumber).intValue, 1)
        XCTAssertEqual((nsExisting[1] as! NSNumber).intValue, 2)
        XCTAssertEqual((nsExisting[2] as! NSNumber).intValue, 9)
        XCTAssertEqual((nsExisting[3] as! NSNumber).intValue, 1)
        XCTAssertEqual((nsExisting[4] as! NSNumber).intValue, 2)
        XCTAssertEqual((nsExisting[5] as! NSNumber).intValue, 6)
    }
}