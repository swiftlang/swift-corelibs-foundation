// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if (os(Linux) || os(Android))
        @testable import Foundation
    #else
        @testable import SwiftFoundation
    #endif
#endif

class TestDateIntervalFormatter: XCTestCase {
    private var formatter: DateIntervalFormatter!
    
    override func setUp() {
        super.setUp()
        
        formatter = DateIntervalFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .long
        formatter.timeStyle = .full
    }
    
    override func tearDown() {
        formatter = nil
        
        super.tearDown()
    }
    
    func testStringFromDateToDateAcrossThreeBillionSeconds() {
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3e9)
        
        XCTAssertEqual(formatter.string(from: older, to: newer),
                       "January 1, 2001, 12:00:00 AM Greenwich Mean Time – January 25, 2096, 5:20:00 AM Greenwich Mean Time")
    }
    
    func testStringFromDateToDateAcrossThreeMillionSeconds() {
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3e6)
        
        XCTAssertEqual(formatter.string(from: older, to: newer),
                       "January 1, 2001, 12:00:00 AM Greenwich Mean Time – February 4, 2001, 5:20:00 PM Greenwich Mean Time")
    }
    
    func testStringFromDateToDateAcrossThreeBillionSecondsReversed() {
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3e9)
        
        XCTAssertEqual(formatter.string(from: newer, to: older),
                       "January 25, 2096, 5:20:00 AM Greenwich Mean Time – January 1, 2001, 12:00:00 AM Greenwich Mean Time")
    }
    
    func testStringFromDateToDateAcrossThreeMillionSecondsReversed() {
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3e6)
        
        XCTAssertEqual(formatter.string(from: newer, to: older),
                       "February 4, 2001, 5:20:00 PM Greenwich Mean Time – January 1, 2001, 12:00:00 AM Greenwich Mean Time")
    }
    
    func testStringFromDateToSameDate() {
        let date = Date(timeIntervalSinceReferenceDate: 3e6)
        
        // For a range from a date to itself, we represent the date only once, with no interdate separator.
        XCTAssertEqual(formatter.string(from: date, to: date),
                       "February 4, 2001, 5:20:00 PM Greenwich Mean Time")
    }
    
    func testStringFromDateIntervalAcrossThreeMillionSeconds() {
        let interval = DateInterval(start: Date(timeIntervalSinceReferenceDate: 0), duration: 3e6)
        
        XCTAssertEqual(formatter.string(from: interval),
                       "January 1, 2001, 12:00:00 AM Greenwich Mean Time – February 4, 2001, 5:20:00 PM Greenwich Mean Time")
    }
    
    func testStringFromDateToDateAcrossOneWeek() {
        formatter.dateTemplate = "MMMd"
        
        do {
            let older = Date(timeIntervalSinceReferenceDate: 0)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 7)
            
            XCTAssertEqual(formatter.string(from: older, to: newer),
                           "Jan 1 – 8")
        }
        
        do {
            let older = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 28)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 34)
            
            XCTAssertEqual(formatter.string(from: older, to: newer),
                           "Jan 29 – Feb 4")
        }
    }
    
    #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    func testStringFromDateToDateAcrossOneWeekWithMonthMinimization() {
        formatter.dateTemplate = "MMMd"
        formatter.boundaryStyle = .minimizeAdjacentMonths
        
        do {
            let older = Date(timeIntervalSinceReferenceDate: 0)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 7)
            
            XCTAssertEqual(formatter.string(from: older, to: newer),
                           "Jan 1 – 8")
        }
        
        do {
            let older = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 28)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 34)
            
            XCTAssertEqual(formatter.string(from: older, to: newer),
                           "Jan 29 – 4")
        }
    }
    #endif
    
    func testStringFromDateToDateAcrossSixtyDays() {
        formatter.dateTemplate = "MMMd"
        
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 60)
        
        XCTAssertEqual(formatter.string(from: older, to: newer),
                       "Jan 1 – Mar 2")
    }
    
    #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    func testStringFromDateToDateAcrossSixtyDaysWithMonthMinimization() {
        formatter.dateTemplate = "MMMd"
        formatter.boundaryStyle = .minimizeAdjacentMonths
        
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 60)
        
        // Minimization shouldn't do anything since this spans more than a month
        XCTAssertEqual(formatter.string(from: older, to: newer),
                       "Jan 1 – Mar 2")
    }
    #endif
    
    func testStringFromDateToDateAcrossFiveHours() {
        do {
            let older = Date(timeIntervalSinceReferenceDate: 0)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 5)
            
            XCTAssertEqual(formatter.string(from: older, to: newer),
                           "January 1, 2001, 12:00:00 AM GMT – 5:00:00 AM GMT")
        }
        
        do {
            let older = Date(timeIntervalSinceReferenceDate: 3600 * 22)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 27)
            
            XCTAssertEqual(formatter.string(from: older, to: newer),
                           "January 1, 2001, 10:00:00 PM Greenwich Mean Time – January 2, 2001, 3:00:00 AM Greenwich Mean Time")
        }
    }
    
    func testStringFromDateToDateAcrossEighteenHours() {
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3600 * 18)
        
        // Minimization shouldn't do anything since this spans more than a month
        XCTAssertEqual(formatter.string(from: older, to: newer),
                       "January 1, 2001, 12:00:00 AM GMT – 6:00:00 PM GMT")
    }
    
    static var allTests: [(String, (TestDateIntervalFormatter) -> () throws -> Void)] {
        var tests: [(String, (TestDateIntervalFormatter) -> () throws -> Void)] = [
            ("testStringFromDateToDateAcrossThreeBillionSeconds", testStringFromDateToDateAcrossThreeBillionSeconds),
            ("testStringFromDateToDateAcrossThreeMillionSeconds", testStringFromDateToDateAcrossThreeMillionSeconds),
            ("testStringFromDateToDateAcrossThreeBillionSecondsReversed", testStringFromDateToDateAcrossThreeBillionSecondsReversed),
            ("testStringFromDateToDateAcrossThreeMillionSecondsReversed", testStringFromDateToDateAcrossThreeMillionSecondsReversed),
            ("testStringFromDateToSameDate", testStringFromDateToSameDate),
            ("testStringFromDateIntervalAcrossThreeMillionSeconds", testStringFromDateIntervalAcrossThreeMillionSeconds),
            ("testStringFromDateToDateAcrossOneWeek", testStringFromDateToDateAcrossOneWeek),
            ("testStringFromDateToDateAcrossSixtyDays", testStringFromDateToDateAcrossSixtyDays),
            ("testStringFromDateToDateAcrossFiveHours", testStringFromDateToDateAcrossFiveHours),
            ("testStringFromDateToDateAcrossEighteenHours", testStringFromDateToDateAcrossEighteenHours),
        ]
        
        #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
        tests.append(contentsOf: [
            ("testStringFromDateToDateAcrossOneWeekWithMonthMinimization", testStringFromDateToDateAcrossOneWeekWithMonthMinimization),
            ("testStringFromDateToDateAcrossSixtyDaysWithMonthMinimization", testStringFromDateToDateAcrossSixtyDaysWithMonthMinimization),
        ])
        #endif
        
        return tests
    }
}
