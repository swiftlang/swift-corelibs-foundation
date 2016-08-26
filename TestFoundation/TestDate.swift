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

class TestDate : XCTestCase {
    
    static var allTests: [(String, (TestDate) -> () throws -> Void)] {
        return [
            ("testDateComparison", testDateComparison),
            ("testDateMutation", testDateMutation),
            ("testDateHash", testDateHash),
            ("testCast", testCast),
            ("testDistantPast", testDistantPast),
            ("testDistantFuture", testDistantFuture),
            ("testEquality", testEquality),
            ("testTimeIntervalSinceDate", testTimeIntervalSinceDate),
            ("testDateComponents", testDateComponents),
            ("test_AnyHashableContainingDate", test_AnyHashableContainingDate),
            ("test_AnyHashableCreatedFromNSDate", test_AnyHashableCreatedFromNSDate),
            ("test_AnyHashableContainingDateComponents", test_AnyHashableContainingDateComponents),
            ("test_AnyHashableCreatedFromNSDateComponents", test_AnyHashableCreatedFromNSDateComponents),
        ]
    }
    
    func testDateComparison() {
        let d1 = Date()
        let d2 = d1 + 1
        
        XCTAssertTrue(d2 > d1)
        XCTAssertTrue(d1 < d2)
        
        let d3 = Date(timeIntervalSince1970: 12345)
        let d4 = Date(timeIntervalSince1970: 12345)
        
        XCTAssertTrue(d3 == d4)
        XCTAssertTrue(d3 <= d4)
        XCTAssertTrue(d4 >= d3)
    }
    
    func testDateMutation() {
        let d0 = Date()
        var d1 = Date()
        d1 = d1 + 1
        let d2 = Date(timeIntervalSinceNow: 10)
        
        XCTAssertTrue(d2 > d1)
        XCTAssertTrue(d1 != d0)
        
        let d3 = d1
        d1 += 10
        XCTAssertTrue(d1 > d3)
    }
    
    func testDateHash() {
        let d0 = NSDate()
        let d1 = Date(timeIntervalSinceReferenceDate: d0.timeIntervalSinceReferenceDate)
        XCTAssertEqual(d0.hashValue, d1.hashValue)
    }
    
    func testCast() {
        let d0 = NSDate()
        let d1 = Date._unconditionallyBridgeFromObjectiveC(d0)
        XCTAssertEqual(d0.timeIntervalSinceReferenceDate, d1.timeIntervalSinceReferenceDate)
    }
    
    func testDistantPast() {
        let distantPast = Date.distantPast
        let currentDate = Date()
        XCTAssertTrue(distantPast < currentDate)
        XCTAssertTrue(currentDate > distantPast)
        XCTAssertTrue(distantPast.timeIntervalSince(currentDate) < 3600.0*24*365*100) /* ~1 century in seconds */
    }
    
    func testDistantFuture() {
        let distantFuture = Date.distantFuture
        let currentDate = Date()
        XCTAssertTrue(currentDate < distantFuture)
        XCTAssertTrue(distantFuture > currentDate)
        XCTAssertTrue(distantFuture.timeIntervalSince(currentDate) > 3600.0*24*365*100) /* ~1 century in seconds */
    }
    
    func dateWithString(_ str: String) -> Date {
        let formatter = DateFormatter()
        // Note: Calendar(identifier:) is OSX 10.9+ and iOS 8.0+ whereas the CF version has always been available
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter.date(from: str)! as Date
    }
    
    func testEquality() {
        let date = dateWithString("2010-05-17 14:49:47 -0700")
        let sameDate = dateWithString("2010-05-17 14:49:47 -0700")
        XCTAssertEqual(date, sameDate)
        XCTAssertEqual(sameDate, date)
        
        let differentDate = dateWithString("2010-05-17 14:49:46 -0700")
        XCTAssertNotEqual(date, differentDate)
        XCTAssertNotEqual(differentDate, date)
        
        let sameDateByTimeZone = dateWithString("2010-05-17 13:49:47 -0800")
        XCTAssertEqual(date, sameDateByTimeZone)
        XCTAssertEqual(sameDateByTimeZone, date)
        
        let differentDateByTimeZone = dateWithString("2010-05-17 14:49:47 -0800")
        XCTAssertNotEqual(date, differentDateByTimeZone)
        XCTAssertNotEqual(differentDateByTimeZone, date)
    }
    
    func testTimeIntervalSinceDate() {
        let referenceDate = dateWithString("1900-01-01 00:00:00 +0000")
        let sameDate = dateWithString("1900-01-01 00:00:00 +0000")
        let laterDate = dateWithString("2010-05-17 14:49:47 -0700")
        let earlierDate = dateWithString("1810-05-17 14:49:47 -0700")
        
        let laterSeconds = laterDate.timeIntervalSince(referenceDate)
        XCTAssertEqual(laterSeconds, 3483121787.0)
        
        let earlierSeconds = earlierDate.timeIntervalSince(referenceDate)
        XCTAssertEqual(earlierSeconds, -2828311813.0)
        
        let sameSeconds = sameDate.timeIntervalSince(referenceDate)
        XCTAssertEqual(sameSeconds, 0.0)
    }
    
    func testDateComponents() {
        // Make sure the optional init stuff works
        let dc = DateComponents()
        
        XCTAssertNil(dc.year)
        
        let dc2 = DateComponents(year: 1999)
        
        XCTAssertNil(dc2.day)
        XCTAssertEqual(1999, dc2.year)
    }
    
    func test_AnyHashableContainingDate() {
        let values: [Date] = [
            dateWithString("2016-05-17 14:49:47 -0700"),
            dateWithString("2010-05-17 14:49:47 -0700"),
            dateWithString("2010-05-17 14:49:47 -0700"),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(Date.self, type(of: anyHashables[0].base))
        XCTAssertSameType(Date.self, type(of: anyHashables[1].base))
        XCTAssertSameType(Date.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableCreatedFromNSDate() {
        let values: [NSDate] = [
            NSDate(timeIntervalSince1970: 1000000000),
            NSDate(timeIntervalSince1970: 1000000001),
            NSDate(timeIntervalSince1970: 1000000001),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(Date.self, type(of: anyHashables[0].base))
        XCTAssertSameType(Date.self, type(of: anyHashables[1].base))
        XCTAssertSameType(Date.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableContainingDateComponents() {
        let values: [DateComponents] = [
            DateComponents(year: 2016),
            DateComponents(year: 1995),
            DateComponents(year: 1995),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(DateComponents.self, type(of: anyHashables[0].base))
        XCTAssertSameType(DateComponents.self, type(of: anyHashables[1].base))
        XCTAssertSameType(DateComponents.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableCreatedFromNSDateComponents() {
        func makeNSDateComponents(year: Int) -> NSDateComponents {
            let result = NSDateComponents()
            result.year = year
            return result
        }
        let values: [NSDateComponents] = [
            makeNSDateComponents(year: 2016),
            makeNSDateComponents(year: 1995),
            makeNSDateComponents(year: 1995),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(DateComponents.self, type(of: anyHashables[0].base))
        XCTAssertSameType(DateComponents.self, type(of: anyHashables[1].base))
        XCTAssertSameType(DateComponents.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}
