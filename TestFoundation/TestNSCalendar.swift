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
import CoreFoundation

class TestNSCalendar: XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_gettingDatesOnGregorianCalendar", test_gettingDatesOnGregorianCalendar ),
            ("test_gettingDatesOnHebrewCalendar", test_gettingDatesOnHebrewCalendar ),
            ("test_initializingWithInvalidIdentifier", test_initializingWithInvalidIdentifier),
            ("test_gettingDatesOnChineseCalendar", test_gettingDatesOnChineseCalendar),
            // Disabled because this fails on linux https://bugs.swift.org/browse/SR-320
            // ("test_currentCalendarRRstability", test_currentCalendarRRstability),
        ]
    }
    
    func test_gettingDatesOnGregorianCalendar() {
        let date = NSDate(timeIntervalSince1970: 1449332351)
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        calendar?.timeZone = NSTimeZone(name: "UTC")!
        guard let components = calendar?.components([.Year, .Month, .Day], fromDate: date) else {
            XCTFail("Could not get date from the calendar")
            return
        }
        
        XCTAssertEqual(components.year, 2015)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 5)
    }
    
    func test_gettingDatesOnHebrewCalendar() {
        let date = NSDate(timeIntervalSince1970: 1552580351)
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierHebrew)
        calendar?.timeZone = NSTimeZone(name: "UTC")!
        guard let components = calendar?.components([.Year, .Month, .Day], fromDate: date) else {
            XCTFail("Could not get date from the Hebrew calendar")
            return
        }
        XCTAssertEqual(components.year, 5779)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 7)
        XCTAssertFalse(components.leapMonth)
    }
    
    func test_gettingDatesOnChineseCalendar() {
        let date = NSDate(timeIntervalSince1970: 1591460351.0)
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierChinese)
        calendar?.timeZone = NSTimeZone(name: "UTC")!
        guard let components = calendar?.components([.Year, .Month, .Day], fromDate: date) else {
            XCTFail("Could not get date from the Chinese calendar")
            return
        }
        XCTAssertEqual(components.year, 37)
        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.day, 15)
        XCTAssertTrue(components.leapMonth)
    }
    
    func test_initializingWithInvalidIdentifier() {
        let calendar = NSCalendar(calendarIdentifier: "nonexistant_calendar")
        XCTAssertNil(calendar)
    }
    
    func test_currentCalendarRRstability() {
        var AMSymbols = [String]()
        for _ in 1...10 {
            let cal = NSCalendar.currentCalendar()
            AMSymbols.append(cal.AMSymbol)
        }
        
        XCTAssertEqual(AMSymbols.count, 10, "Accessing current calendar should work over multiple callouts")
    }
}