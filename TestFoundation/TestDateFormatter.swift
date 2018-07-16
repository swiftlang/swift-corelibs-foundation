// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestDateFormatter: XCTestCase {
    
    let DEFAULT_LOCALE = "en_US"
    let DEFAULT_TIMEZONE = "GMT"
    
    static var allTests : [(String, (TestDateFormatter) -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_dateStyleShort",    test_dateStyleShort),
            //("test_dateStyleMedium",   test_dateStyleMedium),
            ("test_dateStyleLong",     test_dateStyleLong),
            ("test_dateStyleFull",     test_dateStyleFull),
            ("test_customDateFormat", test_customDateFormat),
            ("test_setLocalizedDateFormatFromTemplate", test_setLocalizedDateFormatFromTemplate),
            ("test_dateFormatString", test_dateFormatString),
        ]
    }
    
    func test_BasicConstruction() {
        
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
        
        let f = DateFormatter()
        XCTAssertNotNil(f.timeZone)
        XCTAssertNotNil(f.locale)
        
        f.timeZone = TimeZone(identifier: DEFAULT_TIMEZONE)
        f.locale = Locale(identifier: DEFAULT_LOCALE)

        // Assert default values are set properly
        XCTAssertFalse(f.generatesCalendarDates)
        XCTAssertNotNil(f.calendar)
        XCTAssertFalse(f.isLenient)
        XCTAssertEqual(f.twoDigitStartDate!, Date(timeIntervalSince1970: -631152000))
        XCTAssertNil(f.defaultDate)
        XCTAssertEqual(f.eraSymbols, symbolDictionaryOne["eraSymbols"]!)
        XCTAssertEqual(f.monthSymbols, symbolDictionaryOne["monthSymbols"]!)
        XCTAssertEqual(f.shortMonthSymbols, symbolDictionaryOne["shortMonthSymbols"]!)
        XCTAssertEqual(f.weekdaySymbols, symbolDictionaryOne["weekdaySymbols"]!)
        XCTAssertEqual(f.shortWeekdaySymbols, symbolDictionaryOne["shortWeekdaySymbols"]!)
        XCTAssertEqual(f.amSymbol, "AM")
        XCTAssertEqual(f.pmSymbol, "PM")
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
        XCTAssertEqual(f.gregorianStartDate, Date(timeIntervalSince1970: -12219292800))
        XCTAssertFalse(f.doesRelativeDateFormatting)
        
    }
    
    // ShortStyle
    // locale  stringFromDate  example
    // ------  --------------  --------
    // en_US   M/d/yy h:mm a   12/25/15 12:00 AM
    func test_dateStyleShort() {
        
        let timestamps = [
            -31536000 : "1/1/69, 12:00 AM" , 0.0 : "1/1/70, 12:00 AM", 31536000 : "1/1/71, 12:00 AM",
            2145916800 : "1/1/38, 12:00 AM", 1456272000 : "2/24/16, 12:00 AM", 1456358399 : "2/24/16, 11:59 PM",
            1452574638 : "1/12/16, 4:57 AM", 1455685038 : "2/17/16, 4:57 AM", 1458622638 : "3/22/16, 4:57 AM",
            1459745838 : "4/4/16, 4:57 AM", 1462597038 : "5/7/16, 4:57 AM", 1465534638 : "6/10/16, 4:57 AM",
            1469854638 : "7/30/16, 4:57 AM", 1470718638 : "8/9/16, 4:57 AM", 1473915438 : "9/15/16, 4:57 AM",
            1477285038 : "10/24/16, 4:57 AM", 1478062638 : "11/2/16, 4:57 AM", 1482641838 : "12/25/16, 4:57 AM"
        ]
        
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        
        // ensure tests give consistent results by setting specific timeZone and locale
        f.timeZone = TimeZone(identifier: DEFAULT_TIMEZONE)
        f.locale = Locale(identifier: DEFAULT_LOCALE)
        
        for (timestamp, stringResult) in timestamps {
            
            let testDate = Date(timeIntervalSince1970: timestamp)
            let sf = f.string(from: testDate)
            
            XCTAssertEqual(sf, stringResult)
        }
        
    }
    
    // MediumStyle
    // locale  stringFromDate        example
    // ------  --------------        ------------
    // en_US   MMM d, y, h:mm:ss a   Dec 25, 2015, 12:00:00 AM
    func test_dateStyleMedium() {
        
        let timestamps = [
            -31536000 : "Jan 1, 1969, 12:00:00 AM" , 0.0 : "Jan 1, 1970, 12:00:00 AM", 31536000 : "Jan 1, 1971, 12:00:00 AM",
            2145916800 : "Jan 1, 2038, 12:00:00 AM", 1456272000 : "Feb 24, 2016, 12:00:00 AM", 1456358399 : "Feb 24, 2016, 11:59:59 PM",
            1452574638 : "Jan 12, 2016, 4:57:18 AM", 1455685038 : "Feb 17, 2016, 4:57:18 AM", 1458622638 : "Mar 22, 2016, 4:57:18 AM",
            1459745838 : "Apr 4, 2016, 4:57:18 AM", 1462597038 : "May 7, 2016, 4:57:18 AM", 1465534638 : "Jun 10, 2016, 4:57:18 AM",
            1469854638 : "Jul 30, 2016, 4:57:18 AM", 1470718638 : "Aug 9, 2016, 4:57:18 AM", 1473915438 : "Sep 15, 2016, 4:57:18 AM",
            1477285038 : "Oct 24, 2016, 4:57:18 AM", 1478062638 : "Nov 2, 2016, 4:57:18 AM", 1482641838 : "Dec 25, 2016, 4:57:18 AM"
        ]
        
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .medium
        f.timeZone = TimeZone(identifier: DEFAULT_TIMEZONE)
        f.locale = Locale(identifier: DEFAULT_LOCALE)
        
        for (timestamp, stringResult) in timestamps {
            
            let testDate = Date(timeIntervalSince1970: timestamp)
            let sf = f.string(from: testDate)
            
            XCTAssertEqual(sf, stringResult)
        }
        
    }
    
    
    // LongStyle
    // locale  stringFromDate                 example
    // ------  --------------                 -----------------
    // en_US   MMMM d, y 'at' h:mm:ss a zzz   December 25, 2015 at 12:00:00 AM GMT
    func test_dateStyleLong() {
        
        let timestamps = [
            -31536000 : "January 1, 1969 at 12:00:00 AM GMT" , 0.0 : "January 1, 1970 at 12:00:00 AM GMT", 31536000 : "January 1, 1971 at 12:00:00 AM GMT",
            2145916800 : "January 1, 2038 at 12:00:00 AM GMT", 1456272000 : "February 24, 2016 at 12:00:00 AM GMT", 1456358399 : "February 24, 2016 at 11:59:59 PM GMT",
            1452574638 : "January 12, 2016 at 4:57:18 AM GMT", 1455685038 : "February 17, 2016 at 4:57:18 AM GMT", 1458622638 : "March 22, 2016 at 4:57:18 AM GMT",
            1459745838 : "April 4, 2016 at 4:57:18 AM GMT", 1462597038 : "May 7, 2016 at 4:57:18 AM GMT", 1465534638 : "June 10, 2016 at 4:57:18 AM GMT",
            1469854638 : "July 30, 2016 at 4:57:18 AM GMT", 1470718638 : "August 9, 2016 at 4:57:18 AM GMT", 1473915438 : "September 15, 2016 at 4:57:18 AM GMT",
            1477285038 : "October 24, 2016 at 4:57:18 AM GMT", 1478062638 : "November 2, 2016 at 4:57:18 AM GMT", 1482641838 : "December 25, 2016 at 4:57:18 AM GMT"
        ]
        
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .long
        f.timeZone = TimeZone(identifier: DEFAULT_TIMEZONE)
        f.locale = Locale(identifier: DEFAULT_LOCALE)
        
        for (timestamp, stringResult) in timestamps {
            
            let testDate = Date(timeIntervalSince1970: timestamp)
            let sf = f.string(from: testDate)
            
            XCTAssertEqual(sf, stringResult)
        }
        
    }
    
    // FullStyle
    // locale  stringFromDate                       example
    // ------  --------------                       -------------------------
    // en_US   EEEE, MMMM d, y 'at' h:mm:ss a zzzz  Friday, December 25, 2015 at 12:00:00 AM Greenwich Mean Time
    func test_dateStyleFull() {

#if os(macOS) // timestyle .full is currently broken on Linux, the timezone should be 'Greenwich Mean Time' not 'GMT'
        let timestamps: [TimeInterval:String] = [
            // Negative time offsets are still buggy on macOS
            -31536000 : "Wednesday, January 1, 1969 at 12:00:00 AM GMT", 0.0 : "Thursday, January 1, 1970 at 12:00:00 AM Greenwich Mean Time",
            31536000 : "Friday, January 1, 1971 at 12:00:00 AM Greenwich Mean Time", 2145916800 : "Friday, January 1, 2038 at 12:00:00 AM Greenwich Mean Time",
            1456272000 : "Wednesday, February 24, 2016 at 12:00:00 AM Greenwich Mean Time", 1456358399 : "Wednesday, February 24, 2016 at 11:59:59 PM Greenwich Mean Time",
            1452574638 : "Tuesday, January 12, 2016 at 4:57:18 AM Greenwich Mean Time", 1455685038 : "Wednesday, February 17, 2016 at 4:57:18 AM Greenwich Mean Time",
            1458622638 : "Tuesday, March 22, 2016 at 4:57:18 AM Greenwich Mean Time", 1459745838 : "Monday, April 4, 2016 at 4:57:18 AM Greenwich Mean Time",
            1462597038 : "Saturday, May 7, 2016 at 4:57:18 AM Greenwich Mean Time", 1465534638 : "Friday, June 10, 2016 at 4:57:18 AM Greenwich Mean Time",
            1469854638 : "Saturday, July 30, 2016 at 4:57:18 AM Greenwich Mean Time", 1470718638 : "Tuesday, August 9, 2016 at 4:57:18 AM Greenwich Mean Time",
            1473915438 : "Thursday, September 15, 2016 at 4:57:18 AM Greenwich Mean Time", 1477285038 : "Monday, October 24, 2016 at 4:57:18 AM Greenwich Mean Time",
            1478062638 : "Wednesday, November 2, 2016 at 4:57:18 AM Greenwich Mean Time", 1482641838 : "Sunday, December 25, 2016 at 4:57:18 AM Greenwich Mean Time"
        ]
        
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .full
        f.timeZone = TimeZone(identifier: DEFAULT_TIMEZONE)
        f.locale = Locale(identifier: DEFAULT_LOCALE)
        
        for (timestamp, stringResult) in timestamps {
            
            let testDate = Date(timeIntervalSince1970: timestamp)
            let sf = f.string(from: testDate)

            XCTAssertEqual(sf, stringResult)
        }
#endif
    }
    
    // Custom Style
    // locale  stringFromDate                        example
    // ------  --------------                        -------------------------
    // en_US   EEEE, MMMM d, y 'at' hh:mm:ss a zzzz  Friday, December 25, 2015 at 12:00:00 AM Greenwich Mean Time
    func test_customDateFormat() {
        let timestamps = [
             // Negative time offsets are still buggy on macOS
             -31536000 : "Wednesday, January 1, 1969 at 12:00:00 AM GMT", 0.0 : "Thursday, January 1, 1970 at 12:00:00 AM Greenwich Mean Time",
             31536000 : "Friday, January 1, 1971 at 12:00:00 AM Greenwich Mean Time", 2145916800 : "Friday, January 1, 2038 at 12:00:00 AM Greenwich Mean Time",
             1456272000 : "Wednesday, February 24, 2016 at 12:00:00 AM Greenwich Mean Time", 1456358399 : "Wednesday, February 24, 2016 at 11:59:59 PM Greenwich Mean Time",
             1452574638 : "Tuesday, January 12, 2016 at 04:57:18 AM Greenwich Mean Time", 1455685038 : "Wednesday, February 17, 2016 at 04:57:18 AM Greenwich Mean Time",
             1458622638 : "Tuesday, March 22, 2016 at 04:57:18 AM Greenwich Mean Time", 1459745838 : "Monday, April 4, 2016 at 04:57:18 AM Greenwich Mean Time",
             1462597038 : "Saturday, May 7, 2016 at 04:57:18 AM Greenwich Mean Time", 1465534638 : "Friday, June 10, 2016 at 04:57:18 AM Greenwich Mean Time",
             1469854638 : "Saturday, July 30, 2016 at 04:57:18 AM Greenwich Mean Time", 1470718638 : "Tuesday, August 9, 2016 at 04:57:18 AM Greenwich Mean Time",
             1473915438 : "Thursday, September 15, 2016 at 04:57:18 AM Greenwich Mean Time", 1477285038 : "Monday, October 24, 2016 at 04:57:18 AM Greenwich Mean Time",
             1478062638 : "Wednesday, November 2, 2016 at 04:57:18 AM Greenwich Mean Time", 1482641838 : "Sunday, December 25, 2016 at 04:57:18 AM Greenwich Mean Time"
        ]
        
        let f = DateFormatter()
        f.timeZone = TimeZone(identifier: DEFAULT_TIMEZONE)
        f.locale = Locale(identifier: DEFAULT_LOCALE)

#if os(macOS) // timestyle zzzz is currently broken on Linux
        f.dateFormat = "EEEE, MMMM d, y 'at' hh:mm:ss a zzzz"
        for (timestamp, stringResult) in timestamps {
            
            let testDate = Date(timeIntervalSince1970: timestamp)
            let sf = f.string(from: testDate)
            
            XCTAssertEqual(sf, stringResult)
        }
#endif

        let quarterTimestamps: [Double : String] = [
            1451679712 : "1", 1459542112 : "2", 1467404512 : "3", 1475353312 : "4"
        ]
        
        f.dateFormat = "Q"
        
        for (timestamp, stringResult) in quarterTimestamps {
            let testDate = Date(timeIntervalSince1970: timestamp)
            let sf = f.string(from: testDate)
            
            XCTAssertEqual(sf, stringResult)
        }
        
        // Check .dateFormat resets when style changes
        let testDate = Date(timeIntervalSince1970: 1457738454)

        // Fails on High Sierra
        //f.dateStyle = .medium
        //f.timeStyle = .medium
        //XCTAssertEqual(f.string(from: testDate), "Mar 11, 2016, 11:20:54 PM")
        //XCTAssertEqual(f.dateFormat, "MMM d, y, h:mm:ss a")
        
        f.dateFormat = "dd-MM-yyyy"
        XCTAssertEqual(f.string(from: testDate), "11-03-2016")
        
    }

    func test_setLocalizedDateFormatFromTemplate() {
        let locale = Locale(identifier: DEFAULT_LOCALE)
        let template = "EEEE MMMM d y hhmmss a zzzz"

        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate(template)

        let dateFormat = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: locale)
        XCTAssertEqual(f.dateFormat, dateFormat)
    }

    func test_dateFormatString() {
        let f = DateFormatter()
        f.timeZone = TimeZone(abbreviation: DEFAULT_TIMEZONE)
        
        //.full cases have been commented out as they're not working correctly on Linux
        let formats: [String: (DateFormatter.Style, DateFormatter.Style)] = [
            "": (.none, .none),
            "h:mm a": (.none, .short),
            "h:mm:ss a": (.none, .medium),
            "h:mm:ss a z": (.none, .long),
//            "h:mm:ss a zzzz": (.none, .full),
            "M/d/yy": (.short, .none),
            "M/d/yy, h:mm a": (.short, .short),
            "M/d/yy, h:mm:ss a": (.short, .medium),
            "M/d/yy, h:mm:ss a z": (.short, .long),
//            "M/d/yy, h:mm:ss a zzzz": (.short, .full),
            "MMM d, y": (.medium, .none),
            //These tests currently fail, there seems to be a difference in behavior in the CoreFoundation methods called to construct the format strings.
//            "MMM d, y 'at' h:mm a": (.medium, .short),
//            "MMM d, y 'at' h:mm:ss a": (.medium, .medium),
//            "MMM d, y 'at' h:mm:ss a z": (.medium, .long),
//            "MMM d, y 'at' h:mm:ss a zzzz": (.medium, .full),
            "MMMM d, y": (.long, .none),
            "MMMM d, y 'at' h:mm a": (.long, .short),
            "MMMM d, y 'at' h:mm:ss a": (.long, .medium),
            "MMMM d, y 'at' h:mm:ss a z": (.long, .long),
//            "MMMM d, y 'at' h:mm:ss a zzzz": (.long, .full),
//            "EEEE, MMMM d, y": (.full, .none),
//            "EEEE, MMMM d, y 'at' h:mm a": (.full, .short),
//            "EEEE, MMMM d, y 'at' h:mm:ss a": (.full, .medium),
//            "EEEE, MMMM d, y 'at' h:mm:ss a z": (.full, .long),
//            "EEEE, MMMM d, y 'at' h:mm:ss a zzzz": (.full, .full),
        ]
        
        for (dateFormat, styles) in formats {
            f.dateStyle = styles.0
            f.timeStyle = styles.1
            
            XCTAssertEqual(f.dateFormat, dateFormat)
        }
    }
}
