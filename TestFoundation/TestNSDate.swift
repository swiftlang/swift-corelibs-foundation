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



class TestNSDate : XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_InitTimeIntervalSince1970", test_InitTimeIntervalSince1970),
            ("test_InitTimeIntervalSinceSinceDate", test_InitTimeIntervalSinceSinceDate),
            ("test_TimeIntervalSinceSinceDate", test_TimeIntervalSinceSinceDate),
            ("test_descriptionWithLocale", test_descriptionWithLocale),
            ("test_DistantFuture", test_DistantFuture),
            ("test_DistantPast", test_DistantPast),
            ("test_DateByAddingTimeInterval", test_DateByAddingTimeInterval),
            ("test_EarlierDate", test_EarlierDate),
            ("test_LaterDate", test_LaterDate),
            ("test_Compare", test_Compare),
            ("test_IsEqualToDate", test_IsEqualToDate),
        ]
    }
    
    func test_BasicConstruction() {
        let d = NSDate()
        XCTAssertNotNil(d)
    }

    func test_descriptionWithLocale() {
        let d = NSDate(timeIntervalSince1970: 0)
        XCTAssertEqual(d.descriptionWithLocale(nil), "1970-01-01 00:00:00 +0000")
        XCTAssertNotNil(d.descriptionWithLocale(NSLocale(localeIdentifier: "ja_JP")))
    }
    
    func test_InitTimeIntervalSince1970() {
        let ti: NSTimeInterval = 1
        let d = NSDate(timeIntervalSince1970: ti)
        XCTAssertNotNil(d)
    }
    
    func test_InitTimeIntervalSinceSinceDate() {
        let ti: NSTimeInterval = 1
        let d1 = NSDate()
        let d2 = NSDate(timeInterval: ti, sinceDate: d1)
        XCTAssertNotNil(d2)
    }
    
    func test_TimeIntervalSinceSinceDate() {
        let ti: NSTimeInterval = 1
        let d1 = NSDate()
        let d2 = NSDate(timeInterval: ti, sinceDate: d1)
        XCTAssertEqual(d2.timeIntervalSinceDate(d1), ti)
    }
    
    func test_DistantFuture() {
        let d = NSDate.distantFuture()
        XCTAssertNotNil(d)
    }
    
    func test_DistantPast() {
        let d = NSDate.distantPast()
        XCTAssertNotNil(d)
    }
    
    func test_DateByAddingTimeInterval() {
        let ti: NSTimeInterval = 1
        let d1 = NSDate()
        let d2 = d1.dateByAddingTimeInterval(ti)
        XCTAssertNotNil(d2)
    }
    
    func test_EarlierDate() {
        let ti: NSTimeInterval = 1
        let d1 = NSDate()
        let d2 = d1.dateByAddingTimeInterval(ti)
        XCTAssertEqual(d1.earlierDate(d2), d1)
    }
    
    func test_LaterDate() {
        let ti: NSTimeInterval = 1
        let d1 = NSDate()
        let d2 = d1.dateByAddingTimeInterval(ti)
        XCTAssertEqual(d1.laterDate(d2), d2)
    }
    
    func test_Compare() {
        let ti: NSTimeInterval = 1
        let d1 = NSDate()
        let d2 = d1.dateByAddingTimeInterval(ti)
        XCTAssertEqual(d1.compare(d2), NSComparisonResult.OrderedAscending)
    }
    
    func test_IsEqualToDate() {
        let ti: NSTimeInterval = 1
        let d1 = NSDate()
        let d2 = d1.dateByAddingTimeInterval(ti)
        let d3 = d1.dateByAddingTimeInterval(ti)
        XCTAssertTrue(d2.isEqualToDate(d3))
    }
}