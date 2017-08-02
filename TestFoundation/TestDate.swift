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



class TestDate : XCTestCase {
    
    static var allTests: [(String, (TestDate) -> () throws -> Void)] {
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
            ("test_timeIntervalSinceReferenceDate", test_timeIntervalSinceReferenceDate),
        ]
    }
    
    func test_BasicConstruction() {
        let d = Date()
        XCTAssertNotNil(d)
    }

    func test_descriptionWithLocale() {
        let d = NSDate(timeIntervalSince1970: 0)
        XCTAssertEqual(d.description(with: nil), "1970-01-01 00:00:00 +0000")
        XCTAssertNotNil(d.description(with: Locale(identifier: "ja_JP")))
    }
    
    func test_InitTimeIntervalSince1970() {
        let ti: TimeInterval = 1
        let d = Date(timeIntervalSince1970: ti)
        XCTAssertNotNil(d)
    }
    
    func test_InitTimeIntervalSinceSinceDate() {
        let ti: TimeInterval = 1
        let d1 = Date()
        let d2 = Date(timeInterval: ti, since: d1)
        XCTAssertNotNil(d2)
    }
    
    func test_TimeIntervalSinceSinceDate() {
        let ti: TimeInterval = 1
        let d1 = Date()
        let d2 = Date(timeInterval: ti, since: d1)
        XCTAssertEqual(d2.timeIntervalSince(d1), ti)
    }
    
    func test_DistantFuture() {
        let d = Date.distantFuture
        XCTAssertNotNil(d)
    }
    
    func test_DistantPast() {
        let d = Date.distantPast
        XCTAssertNotNil(d)
    }
    
    func test_DateByAddingTimeInterval() {
        let ti: TimeInterval = 1
        let d1 = Date()
        let d2 = d1 + ti
        XCTAssertNotNil(d2)
    }
    
    func test_EarlierDate() {
        let ti: TimeInterval = 1
        let d1 = Date()
        let d2 = d1 + ti
        XCTAssertLessThan(d1, d2)
    }
    
    func test_LaterDate() {
        let ti: TimeInterval = 1
        let d1 = Date()
        let d2 = d1 + ti
        XCTAssertGreaterThan(d2, d1)
    }
    
    func test_Compare() {
        let ti: TimeInterval = 1
        let d1 = Date()
        let d2 = d1 + ti
        XCTAssertEqual(d1.compare(d2), ComparisonResult.orderedAscending)
    }
    
    func test_IsEqualToDate() {
        let ti: TimeInterval = 1
        let d1 = Date()
        let d2 = d1 + ti
        let d3 = d1 + ti
        XCTAssertEqual(d2, d3)
    }

    func test_timeIntervalSinceReferenceDate() {
        let d1 = Date().timeIntervalSinceReferenceDate
        let sinceReferenceDate = Date.timeIntervalSinceReferenceDate
        let d2 = Date().timeIntervalSinceReferenceDate
        XCTAssertTrue(d1 <= sinceReferenceDate)
        XCTAssertTrue(d2 >= sinceReferenceDate)
    }
}
