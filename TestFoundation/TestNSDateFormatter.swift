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

class TestNSDateFormatter: XCTestCase {
    
    let DEFAULT_LOCALE = "en_US"
    let DEFAULT_TIMEZONE = "GMT"
    
    static var allTests : [(String, TestNSDateFormatter -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
//            ("test_customDateFormat", test_customDateFormat),
            ("test_dateStyleShort",    test_dateStyleShort),
            ("test_dateStyleMedium",   test_dateStyleMedium),
            ("test_dateStyleLong",     test_dateStyleLong),
            ("test_dateStyleFull",     test_dateStyleFull)
        ]
    }
    
    func test_BasicConstruction() {
        
        // TODO: move to plist
        let symbolDictionaryOne = ["eraSymbols" : ["BC", "AD"],
                             "monthSymbols" : ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
                             "shortMonthSymbols" : ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                             "weekdaySymbols" : ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
                             "shortWeekdaySymbols" : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
                             "longEraSymbols" : ["Before Christ", "Anno Domini"],
                             "veryShortMonthSymbols" : ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"],
                            "standaloneMonthSymbols" : ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
                            "shortStandaloneMonthSymbols" : ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                            "veryShortStandaloneMonthSymbols" : ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]]
        
        let symbolDictionaryTwo = ["veryShortWeekdaySymbols" : ["S", "M", "T", "W", "T", "F", "S"],
                            "standaloneWeekdaySymbols" : ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
                            "shortStandaloneWeekdaySymbols" : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
                            "veryShortStandaloneWeekdaySymbols" : ["S", "M", "T", "W", "T", "F", "S"],
                            "quarterSymbols" : ["1st quarter", "2nd quarter", "3rd quarter", "4th quarter"],
                            "shortQuarterSymbols" : ["Q1", "Q2", "Q3", "Q4"],
                            "standaloneQuarterSymbols" : ["1st quarter", "2nd quarter", "3rd quarter", "4th quarter"],
                            "shortStandaloneQuarterSymbols" : ["Q1", "Q2", "Q3", "Q4"]]
        
        let f = NSDateFormatter()
        XCTAssertNotNil(f)
        XCTAssertNotNil(f.timeZone)
        XCTAssertNotNil(f.locale)
        
        f.timeZone = NSTimeZone(name: DEFAULT_TIMEZONE)
        f.locale = NSLocale(localeIdentifier: DEFAULT_LOCALE)

        // Assert default values are set properly
        XCTAssertFalse(f.generatesCalendarDates)
        XCTAssertNotNil(f.calendar)
        XCTAssertFalse(f.lenient)
        XCTAssertEqual(f.twoDigitStartDate!, NSDate(timeIntervalSince1970: -631152000))
        XCTAssertNil(f.defaultDate)
        XCTAssertEqual(f.eraSymbols, symbolDictionaryOne["eraSymbols"]!)
        XCTAssertEqual(f.monthSymbols, symbolDictionaryOne["monthSymbols"]!)
        XCTAssertEqual(f.shortMonthSymbols, symbolDictionaryOne["shortMonthSymbols"]!)
        XCTAssertEqual(f.weekdaySymbols, symbolDictionaryOne["weekdaySymbols"]!)
        XCTAssertEqual(f.shortWeekdaySymbols, symbolDictionaryOne["shortWeekdaySymbols"]!)
        XCTAssertEqual(f.AMSymbol, "AM")
        XCTAssertEqual(f.PMSymbol, "PM")
        XCTAssertEqual(f.longEraSymbols, symbolDictionaryOne["longEraSymbols"]!)
        XCTAssertEqual(f.veryShortMonthSymbols, symbolDictionaryOne["veryShortMonthSymbols"]!)
        XCTAssertEqual(f.standaloneMonthSymbols, symbolDictionaryOne["standaloneMonthSymbols"]!)
        XCTAssertEqual(f.shortStandaloneMonthSymbols, symbolDictionaryOne["shortStandaloneMonthSymbols"]!)
        XCTAssertEqual(f.veryShortStandaloneMonthSymbols, symbolDictionaryOne["veryShortStandaloneMonthSymbols"]!)
        XCTAssertEqual(f.veryShortWeekdaySymbols, symbolDictionaryTwo["veryShortWeekdaySymbols"]!)
        XCTAssertEqual(f.standaloneWeekdaySymbols, symbolDictionaryTwo["standaloneWeekdaySymbols"]!)
        XCTAssertEqual(f.shortStandaloneWeekdaySymbols, symbolDictionaryTwo["shortStandaloneWeekdaySymbols"]!)
        XCTAssertEqual(f.veryShortStandaloneWeekdaySymbols, symbolDictionaryTwo["veryShortStandaloneWeekdaySymbols"]!)
        XCTAssertEqual(f.quarterSymbols, symbolDictionaryTwo["quarterSymbols"]!)
        XCTAssertEqual(f.shortQuarterSymbols, symbolDictionaryTwo["shortQuarterSymbols"]!)
        XCTAssertEqual(f.standaloneQuarterSymbols, symbolDictionaryTwo["standaloneQuarterSymbols"]!)
        XCTAssertEqual(f.shortStandaloneQuarterSymbols, symbolDictionaryTwo["shortStandaloneQuarterSymbols"]!)
        XCTAssertEqual(f.gregorianStartDate, NSDate(timeIntervalSince1970: -12219292800))
        XCTAssertFalse(f.doesRelativeDateFormatting)
        
    }
    
    func test_customDateFormat() {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = String("dd-MM-yyyy")
        let dateStr = dateFormatter.stringFromDate(NSDate())
        
        print("With dateFormat '\(dateFormatter.dateFormat)':  '\(dateStr)'")
        
    }
    
    // ShortStyle
    // locale  stringFromDate  example
    // ------  --------------  --------
    // en_US   M/d/yy       12/25/15
    func test_dateStyleShort() {
        
        let timestamps = [
            -31536000 : "1/1/69, 12:00 AM" , 0.0 : "1/1/70, 12:00 AM", 31536000 : "1/1/71, 12:00 AM",
            2145916800 : "1/1/38, 12:00 AM", 1456272000 : "2/24/16, 12:00 AM", 1456358399 : "2/24/16, 11:59 PM",
            1452574638 : "1/12/16, 4:57 AM", 1455685038 : "2/17/16, 4:57 AM", 1458622638 : "3/22/16, 4:57 AM",
            1459745838 : "4/4/16, 4:57 AM", 1462597038 : "5/7/16, 4:57 AM", 1465534638 : "6/10/16, 4:57 AM",
            1469854638 : "7/30/16, 4:57 AM", 1470718638 : "8/9/16, 4:57 AM", 1473915438 : "9/15/16, 4:57 AM",
            1477285038 : "10/24/16, 4:57 AM", 1478062638 : "11/2/16, 4:57 AM", 1482641838 : "12/25/16, 4:57 AM"
        ]
        
        let f = NSDateFormatter()
        f.dateStyle = .ShortStyle
        f.timeStyle = .ShortStyle
        
        // ensure tests give consistent results by setting specific timeZone and locale
        f.timeZone = NSTimeZone(name: DEFAULT_TIMEZONE)
        f.locale = NSLocale(localeIdentifier: DEFAULT_LOCALE)
        
        for (timestamp, stringResult) in timestamps {
            
            let testDate = NSDate(timeIntervalSince1970: timestamp)
            let sf = f.stringFromDate(testDate)
            
            XCTAssertEqual(sf, stringResult)
        }
        
    }
    
    // MediumStyle
    // locale  stringFromDate  example
    // ------  --------------  ------------
    // en_US   MMM d, y       Dec 25, 2015
    func test_dateStyleMedium() {
        
        let timestamps = [
            -31536000 : "Jan 1, 1969, 12:00:00 AM" , 0.0 : "Jan 1, 1970, 12:00:00 AM", 31536000 : "Jan 1, 1971, 12:00:00 AM",
            2145916800 : "Jan 1, 2038, 12:00:00 AM", 1456272000 : "Feb 24, 2016, 12:00:00 AM", 1456358399 : "Feb 24, 2016, 11:59:59 PM",
            1452574638 : "Jan 12, 2016, 4:57:18 AM", 1455685038 : "Feb 17, 2016, 4:57:18 AM", 1458622638 : "Mar 22, 2016, 4:57:18 AM",
            1459745838 : "Apr 4, 2016, 4:57:18 AM", 1462597038 : "May 7, 2016, 4:57:18 AM", 1465534638 : "Jun 10, 2016, 4:57:18 AM",
            1469854638 : "Jul 30, 2016, 4:57:18 AM", 1470718638 : "Aug 9, 2016, 4:57:18 AM", 1473915438 : "Sep 15, 2016, 4:57:18 AM",
            1477285038 : "Oct 24, 2016, 4:57:18 AM", 1478062638 : "Nov 2, 2016, 4:57:18 AM", 1482641838 : "Dec 25, 2016, 4:57:18 AM"
        ]
        
        let f = NSDateFormatter()
        f.dateStyle = .MediumStyle
        f.timeStyle = .MediumStyle
        f.timeZone = NSTimeZone(name: DEFAULT_TIMEZONE)
        f.locale = NSLocale(localeIdentifier: DEFAULT_LOCALE)
        
        for (timestamp, stringResult) in timestamps {
            
            let testDate = NSDate(timeIntervalSince1970: timestamp)
            let sf = f.stringFromDate(testDate)
            
            XCTAssertEqual(sf, stringResult)
        }
        
    }
    
    
    // LongStyle
    // locale  stringFromDate  example
    // ------  --------------  -----------------
    // en_US   MMMM d, y       December 25, 2015
    func test_dateStyleLong() {
        
        let timestamps = [
            -31536000 : "January 1, 1969 at 12:00:00 AM GMT" , 0.0 : "January 1, 1970 at 12:00:00 AM GMT", 31536000 : "January 1, 1971 at 12:00:00 AM GMT",
            2145916800 : "January 1, 2038 at 12:00:00 AM GMT", 1456272000 : "February 24, 2016 at 12:00:00 AM GMT", 1456358399 : "February 24, 2016 at 11:59:59 PM GMT",
            1452574638 : "January 12, 2016 at 4:57:18 AM GMT", 1455685038 : "February 17, 2016 at 4:57:18 AM GMT", 1458622638 : "March 22, 2016 at 4:57:18 AM GMT",
            1459745838 : "April 4, 2016 at 4:57:18 AM GMT", 1462597038 : "May 7, 2016 at 4:57:18 AM GMT", 1465534638 : "June 10, 2016 at 4:57:18 AM GMT",
            1469854638 : "July 30, 2016 at 4:57:18 AM GMT", 1470718638 : "August 9, 2016 at 4:57:18 AM GMT", 1473915438 : "September 15, 2016 at 4:57:18 AM GMT",
            1477285038 : "October 24, 2016 at 4:57:18 AM GMT", 1478062638 : "November 2, 2016 at 4:57:18 AM GMT", 1482641838 : "December 25, 2016 at 4:57:18 AM GMT"
        ]
        
        let f = NSDateFormatter()
        f.dateStyle = .LongStyle
        f.timeStyle = .LongStyle
        f.timeZone = NSTimeZone(name: DEFAULT_TIMEZONE)
        f.locale = NSLocale(localeIdentifier: DEFAULT_LOCALE)
        
        for (timestamp, stringResult) in timestamps {
            
            let testDate = NSDate(timeIntervalSince1970: timestamp)
            let sf = f.stringFromDate(testDate)
            
            XCTAssertEqual(sf, stringResult)
        }
        
    }
    
    // FullStyle
    // locale  stringFromDate  example
    // ------  --------------  -------------------------
    // en_US   EEEE, MMMM d, y  Friday, December 25, 2015
    func test_dateStyleFull() {
        
        let timestamps = [
            -31536000 : "Wednesday, January 1, 1969 at 12:00:00 AM GMT" , 0.0 : "Thursday, January 1, 1970 at 12:00:00 AM GMT",
            31536000 : "Friday, January 1, 1971 at 12:00:00 AM GMT", 2145916800 : "Friday, January 1, 2038 at 12:00:00 AM GMT",
            1456272000 : "Wednesday, February 24, 2016 at 12:00:00 AM GMT", 1456358399 : "Wednesday, February 24, 2016 at 11:59:59 PM GMT",
            1452574638 : "Tuesday, January 12, 2016 at 4:57:18 AM GMT", 1455685038 : "Wednesday, February 17, 2016 at 4:57:18 AM GMT",
            1458622638 : "Tuesday, March 22, 2016 at 4:57:18 AM GMT", 1459745838 : "Monday, April 4, 2016 at 4:57:18 AM GMT",
            1462597038 : "Saturday, May 7, 2016 at 4:57:18 AM GMT", 1465534638 : "Friday, June 10, 2016 at 4:57:18 AM GMT",
            1469854638 : "Saturday, July 30, 2016 at 4:57:18 AM GMT", 1470718638 : "Tuesday, August 9, 2016 at 4:57:18 AM GMT",
            1473915438 : "Thursday, September 15, 2016 at 4:57:18 AM GMT", 1477285038 : "Monday, October 24, 2016 at 4:57:18 AM GMT",
            1478062638 : "Wednesday, November 2, 2016 at 4:57:18 AM GMT", 1482641838 : "Sunday, December 25, 2016 at 4:57:18 AM GMT"
        ]
        
        let f = NSDateFormatter()
        f.dateStyle = .FullStyle
        f.timeStyle = .FullStyle
        f.timeZone = NSTimeZone(name: DEFAULT_TIMEZONE)
        f.locale = NSLocale(localeIdentifier: DEFAULT_LOCALE)
        
        for (timestamp, stringResult) in timestamps {
            
            let testDate = NSDate(timeIntervalSince1970: timestamp)
            let sf = f.stringFromDate(testDate)

            XCTAssertEqual(sf, stringResult)
        }
        
    }
    
}
