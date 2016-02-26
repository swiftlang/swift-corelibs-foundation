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
    
    var allTests : [(String, () throws -> Void)] {
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
        let f = NSDateFormatter()
        XCTAssertNotNil(f)
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
            -31536000 : "1/1/69" , 0.0 : "1/1/70", 31536000 : "1/1/71",
            2145916800 : "1/1/38", 1456272000 : "2/24/16", 1456358399 : "2/24/16",
            1452574638 : "1/12/16", 1455685038 : "2/17/16", 1458622638 : "3/22/16",
            1459745838 : "4/4/16", 1462597038 : "5/7/16", 1465534638 : "6/10/16",
            1469854638 : "7/30/16", 1470718638 : "8/9/16", 1473915438 : "9/15/16",
            1477285038 : "10/24/16", 1478062638 : "11/2/16", 1482641838 : "12/25/16"
        ]
        
        let f = NSDateFormatter()
        f.dateStyle = .ShortStyle
        
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
            -31536000 : "Jan 1, 1969" , 0.0 : "Jan 1, 1970", 31536000 : "Jan 1, 1971",
            2145916800 : "Jan 1, 2038", 1456272000 : "Feb 24, 2016", 1456358399 : "Feb 24, 2016",
            1452574638 : "Jan 12, 2016", 1455685038 : "Feb 17, 2016", 1458622638 : "Mar 22, 2016",
            1459745838 : "Apr 4, 2016", 1462597038 : "May 7, 2016", 1465534638 : "Jun 10, 2016",
            1469854638 : "Jul 30, 2016", 1470718638 : "Aug 9, 2016", 1473915438 : "Sep 15, 2016",
            1477285038 : "Oct 24, 2016", 1478062638 : "Nov 2, 2016", 1482641838 : "Dec 25, 2016"
        ]
        
        let f = NSDateFormatter()
        f.dateStyle = .MediumStyle
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
            -31536000 : "January 1, 1969" , 0.0 : "January 1, 1970", 31536000 : "January 1, 1971",
            2145916800 : "January 1, 2038", 1456272000 : "February 24, 2016", 1456358399 : "February 24, 2016",
            1452574638 : "January 12, 2016", 1455685038 : "February 17, 2016", 1458622638 : "March 22, 2016",
            1459745838 : "April 4, 2016", 1462597038 : "May 7, 2016", 1465534638 : "June 10, 2016",
            1469854638 : "July 30, 2016", 1470718638 : "August 9, 2016", 1473915438 : "September 15, 2016",
            1477285038 : "October 24, 2016", 1478062638 : "November 2, 2016", 1482641838 : "December 25, 2016"
        ]
        
        let f = NSDateFormatter()
        f.dateStyle = .LongStyle
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
            -31536000 : "Wednesday, January 1, 1969" , 0.0 : "Thursday, January 1, 1970", 31536000 : "Friday, January 1, 1971",
            2145916800 : "Friday, January 1, 2038", 1456272000 : "Wednesday, February 24, 2016", 1456358399 : "Wednesday, February 24, 2016",
            1452574638 : "Tuesday, January 12, 2016", 1455685038 : "Wednesday, February 17, 2016", 1458622638 : "Tuesday, March 22, 2016",
            1459745838 : "Monday, April 4, 2016", 1462597038 : "Saturday, May 7, 2016", 1465534638 : "Friday, June 10, 2016",
            1469854638 : "Saturday, July 30, 2016", 1470718638 : "Tuesday, August 9, 2016", 1473915438 : "Thursday, September 15, 2016",
            1477285038 : "Monday, October 24, 2016", 1478062638 : "Wednesday, November 2, 2016", 1482641838 : "Sunday, December 25, 2016"
        ]
        
        let f = NSDateFormatter()
        f.dateStyle = .FullStyle
        f.timeZone = NSTimeZone(name: DEFAULT_TIMEZONE)
        f.locale = NSLocale(localeIdentifier: DEFAULT_LOCALE)
        
        for (timestamp, stringResult) in timestamps {
            
            let testDate = NSDate(timeIntervalSince1970: timestamp)
            let sf = f.stringFromDate(testDate)
            
            XCTAssertEqual(sf, stringResult)
        }
        
    }
    
}
