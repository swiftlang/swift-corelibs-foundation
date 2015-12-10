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
  
  var allTests : [(String, () -> Void)] {
    return [
      ("test_gettingDatesOnGregorianCalendar", test_gettingDatesOnGregorianCalendar ),
      ("test_gettingDatesOnHebrewCalendar", test_gettingDatesOnHebrewCalendar ),
      ("test_initializingWithInvalidIdentifier", test_initializingWithInvalidIdentifier),
      ("test_gettingDatesOnChineseCalendar", test_gettingDatesOnChineseCalendar)
    ]
  }
  
  func test_gettingDatesOnGregorianCalendar() {
    let date = NSDate(timeIntervalSince1970: 1449332351)
    
    guard let components = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)?.components([.Year, .Month, .Day], fromDate: date) else {
      XCTFail("Could not get date from the gregorian calendar")
      return
    }
    XCTAssertEqual(components.year, 2015)
    XCTAssertEqual(components.month, 12)
    XCTAssertEqual(components.day, 5)
  }
  
  func test_gettingDatesOnHebrewCalendar() {
    let date = NSDate(timeIntervalSince1970: 1552580351)
    
    guard let components = NSCalendar(calendarIdentifier: NSCalendarIdentifierHebrew)?.components([.Year, .Month, .Day], fromDate: date) else {
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
    
    guard let components = NSCalendar(calendarIdentifier: NSCalendarIdentifierChinese)?.components([.Year, .Month, .Day], fromDate: date) else {
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
}