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

enum ContainsInOrderResult: Equatable {
    case success
    case missed(String)
    case doesNotEndWithLastElement
}

extension String {
    func containsInOrder(requiresLastToBeAtEnd: Bool = false, _ substrings: [String]) -> ContainsInOrderResult {
        var foundRange: Range<String.Index> = startIndex ..< startIndex
        for substring in substrings {
            if let newRange = range(of: substring, options: [], range: foundRange.upperBound..<endIndex, locale: nil) {
                foundRange = newRange
            } else {
                return .missed(substring)
            }
        }
        
        if requiresLastToBeAtEnd {
            return foundRange.upperBound == endIndex ? .success : .doesNotEndWithLastElement
        } else {
            return .success
        }
    }
    
    func assertContainsInOrder(requiresLastToBeAtEnd: Bool = false, _ substrings: String...) {
        let result = containsInOrder(requiresLastToBeAtEnd: requiresLastToBeAtEnd, substrings)
        XCTAssert(result == .success, "String '\(self)' (must end with: \(requiresLastToBeAtEnd)) does not contain in sequence: \(substrings) — reason: \(result)")
    }
}

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
        
        let result = formatter.string(from: older, to: newer)
        result.assertContainsInOrder("January 1",  "2001", "12:00:00 AM", "Greenwich Mean Time",
                                     "January 25", "2096", "5:20:00 AM",  "Greenwich Mean Time")
    }
    
    func testStringFromDateToDateAcrossThreeMillionSeconds() {
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3e6)
        
        let result = formatter.string(from: older, to: newer)
        result.assertContainsInOrder("January 1",  "2001", "12:00:00 AM", "Greenwich Mean Time",
                                     "February 4", "2001", "5:20:00 AM",  "Greenwich Mean Time")
    }
    
    func testStringFromDateToDateAcrossThreeBillionSecondsReversed() {
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3e9)
        
        let result = formatter.string(from: older, to: newer)
        result.assertContainsInOrder("January 25", "2096", "5:20:00 AM",  "Greenwich Mean Time",
                                     "January 1",  "2001", "12:00:00 AM", "Greenwich Mean Time")
    }
    
    func testStringFromDateToDateAcrossThreeMillionSecondsReversed() {
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3e6)
        
        let result = formatter.string(from: older, to: newer)
        result.assertContainsInOrder("February 4", "2001", "5:20:00 AM",  "Greenwich Mean Time",
                                     "January 1",  "2001", "12:00:00 AM", "Greenwich Mean Time")
    }
    
    func testStringFromDateToSameDate() {
        let date = Date(timeIntervalSinceReferenceDate: 3e6)
        
        // For a range from a date to itself, we represent the date only once, with no interdate separator.
        let result = formatter.string(from: date, to: date)
        result.assertContainsInOrder(requiresLastToBeAtEnd: true, "February 4", "2001", "5:20:00 AM",  "Greenwich Mean Time")
    }
    
    func testStringFromDateIntervalAcrossThreeMillionSeconds() throws {
        let interval = DateInterval(start: Date(timeIntervalSinceReferenceDate: 0), duration: 3e6)
        
        let result = try formatter.string(from: interval).unwrapped()
        result.assertContainsInOrder("January 1",  "2001", "12:00:00 AM", "Greenwich Mean Time",
                                     "February 4", "2001", "5:20:00 AM",  "Greenwich Mean Time")
    }
    
    func testStringFromDateToDateAcrossOneWeek() {
        formatter.dateTemplate = "MMMd"
        
        do {
            let older = Date(timeIntervalSinceReferenceDate: 0)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 7)
            
            let result = formatter.string(from: older, to: newer)
            result.assertContainsInOrder(requiresLastToBeAtEnd: true, "Jan", "1", "8")
        }
        
        do {
            let older = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 28)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 34)
            
            let result = formatter.string(from: older, to: newer)
            result.assertContainsInOrder(requiresLastToBeAtEnd: true, "Jan", "29", "Feb", "4")
        }
    }
    
    #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS))
    func testStringFromDateToDateAcrossOneWeekWithMonthMinimization() {
        formatter.dateTemplate = "MMMd"
        formatter.boundaryStyle = .minimizeAdjacentMonths
        
        do {
            let older = Date(timeIntervalSinceReferenceDate: 0)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 7)
            
            let result = formatter.string(from: older, to: newer)
            result.assertContainsInOrder(requiresLastToBeAtEnd: true, "Jan", "1", "8")
        }
        
        do {
            let older = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 28)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 34)
            
            let result = formatter.string(from: older, to: newer)
            result.assertContainsInOrder(requiresLastToBeAtEnd: true, "Jan", "29", "4")
            XCTAssertNil(result.range(of: "Feb"))
        }
    }
    #endif
    
    func testStringFromDateToDateAcrossSixtyDays() {
        formatter.dateTemplate = "MMMd"
        
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 60)
        
        let result = formatter.string(from: older, to: newer)
        result.assertContainsInOrder(requiresLastToBeAtEnd: true, "Jan", "1", "Mar", "2")
    }
    
    #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS))
    func testStringFromDateToDateAcrossSixtyDaysWithMonthMinimization() {
        formatter.dateTemplate = "MMMd"
        formatter.boundaryStyle = .minimizeAdjacentMonths
        
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3600 * 24 * 60)
        
        // Minimization shouldn't do anything since this spans more than a month
        let result = formatter.string(from: older, to: newer)
        result.assertContainsInOrder(requiresLastToBeAtEnd: true, "Jan", "1", "Mar", "2")
    }
    #endif
    
    func testStringFromDateToDateAcrossFiveHours() throws {
        do {
            let older = Date(timeIntervalSinceReferenceDate: 0)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 5)
            
            let result = formatter.string(from: older, to: newer)
            result.assertContainsInOrder(requiresLastToBeAtEnd: true, "January", "1", "2001", "12:00:00 AM", "5:00:00 AM")
            
            let firstJanuary = try result.range(of: "January").unwrapped()
            XCTAssertNil(result[firstJanuary.upperBound...].range(of: "January")) // January appears only once.
        }
        
        do {
            let older = Date(timeIntervalSinceReferenceDate: 3600 * 22)
            let newer = Date(timeIntervalSinceReferenceDate: 3600 * 27)
            
            XCTAssertEqual(formatter.string(from: older, to: newer),
                           "January 1, 2001, 10:00:00 PM Greenwich Mean Time – January 2, 2001, 3:00:00 AM Greenwich Mean Time")
            let result = formatter.string(from: older, to: newer)
            result.assertContainsInOrder(requiresLastToBeAtEnd: true, "January", "1", "2001", "10:00:00 AM", "5:00:00 AM")
        }
    }
    
    func testStringFromDateToDateAcrossEighteenHours() throws {
        let older = Date(timeIntervalSinceReferenceDate: 0)
        let newer = Date(timeIntervalSinceReferenceDate: 3600 * 18)
        
        let result = formatter.string(from: older, to: newer)
        result.assertContainsInOrder(requiresLastToBeAtEnd: true, "January", "1", "2001", "12:00:00 AM", "6:00:00 PM")
        
        let firstJanuary = try result.range(of: "January").unwrapped()
        XCTAssertNil(result[firstJanuary.upperBound...].range(of: "January")) // January appears only once.
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
        
        #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT && (os(macOS) || os(iOS) || os(tvOS) || os(watchOS))
        tests.append(contentsOf: [
            ("testStringFromDateToDateAcrossOneWeekWithMonthMinimization", testStringFromDateToDateAcrossOneWeekWithMonthMinimization),
            ("testStringFromDateToDateAcrossSixtyDaysWithMonthMinimization", testStringFromDateToDateAcrossSixtyDaysWithMonthMinimization),
        ])
        #endif
        
        return tests
    }
}
