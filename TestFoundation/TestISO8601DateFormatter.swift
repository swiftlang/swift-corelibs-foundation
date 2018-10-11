// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestISO8601DateFormatter: XCTestCase {
    
    static var allTests : [(String, (TestISO8601DateFormatter) -> () throws -> Void)] {
        
        return [
            ("test_stringFromDate", test_stringFromDate),
            ("test_dateFromString", test_dateFromString),
            ("test_stringFromDateClass", test_stringFromDateClass),
        ]
    }
    
    func test_stringFromDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss.SSSS zzz"
        let dateString = "2016/10/08 22:31:00.0713 GMT"

        guard let someDateTime = formatter.date(from: dateString) else {
            XCTFail("DateFormatter was unable to parse '\(dateString)' using '\(formatter.dateFormat ?? "")' date format.")
            return
        }
        let isoFormatter = ISO8601DateFormatter()

        //default settings check
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "2016-10-08T22:31:00Z")
        
        /*
         The following tests cover various cases when changing the .formatOptions property.
         */
        isoFormatter.formatOptions = [.withInternetDateTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "2016-10-08T22:31:00Z")
        
        isoFormatter.formatOptions = [.withInternetDateTime, .withSpaceBetweenDateAndTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "2016-10-08 22:31:00Z")
        
        isoFormatter.formatOptions = .withFullTime
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "22:31:00Z")
        
        isoFormatter.formatOptions = [.withFullTime, .withFractionalSeconds]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "22:31:00.071Z")
        
        isoFormatter.formatOptions = .withFullDate
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "2016-10-08")
        
        isoFormatter.formatOptions = [.withFullTime, .withFullDate]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "2016-10-08T22:31:00Z")
        
        isoFormatter.formatOptions = [.withFullTime, .withFullDate, .withSpaceBetweenDateAndTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "2016-10-08 22:31:00Z")
        
        isoFormatter.formatOptions = [.withFullTime, .withFullDate, .withSpaceBetweenDateAndTime, .withFractionalSeconds]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "2016-10-08 22:31:00.071Z")
        
        isoFormatter.formatOptions = [.withDay, .withTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "282T223100")
        
        isoFormatter.formatOptions = [.withDay, .withTime, .withFractionalSeconds]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "282T223100.071")
        
        isoFormatter.formatOptions = [.withWeekOfYear, .withTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "W40T223100")

        isoFormatter.formatOptions = [.withMonth, .withTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10T223100")

        isoFormatter.formatOptions = [.withDay, .withWeekOfYear, .withTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "W4006T223100")

        isoFormatter.formatOptions = [.withDay, .withMonth, .withTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "1008T223100")

        isoFormatter.formatOptions = [.withWeekOfYear, .withMonth, .withTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10W40T223100")

        isoFormatter.formatOptions = [.withWeekOfYear, .withMonth, .withTime, .withColonSeparatorInTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10W40T22:31:00")

        isoFormatter.formatOptions = [.withWeekOfYear, .withMonth, .withTime, .withColonSeparatorInTime, .withSpaceBetweenDateAndTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10W40 22:31:00")

        isoFormatter.formatOptions = [.withWeekOfYear, .withMonth, .withTime, .withColonSeparatorInTime, .withSpaceBetweenDateAndTime, .withDashSeparatorInDate]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10-W40 22:31:00")
        
        isoFormatter.formatOptions = [.withWeekOfYear, .withMonth, .withTime, .withColonSeparatorInTime, .withSpaceBetweenDateAndTime, .withDashSeparatorInDate, .withFractionalSeconds]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10-W40 22:31:00.071")

        isoFormatter.formatOptions = [.withDay, .withWeekOfYear]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "W4006")

        isoFormatter.formatOptions = [.withDay, .withMonth]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "1008")

        isoFormatter.formatOptions = [.withWeekOfYear, .withMonth]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10W40")

        isoFormatter.formatOptions = [.withDay, .withWeekOfYear, .withMonth]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10W4006")

        // .withFractionalSeconds should be ignored if neither .withTime or .withFullTime are specified
        isoFormatter.formatOptions = [.withDay, .withWeekOfYear, .withMonth, .withFractionalSeconds]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10W4006")
        
        isoFormatter.formatOptions = [.withMonth, .withDay, .withWeekOfYear, .withDashSeparatorInDate]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10-W40-06")

#if !os(Android)
        /*
         The following tests cover various cases when changing the .formatOptions property with a different TimeZone set.
         */

        isoFormatter.timeZone = TimeZone(identifier: "PST")

        isoFormatter.formatOptions = [.withInternetDateTime]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "2016-10-08T15:31:00-07:00")
        
        isoFormatter.formatOptions = [.withTime, .withTimeZone]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "153100-0700")

        isoFormatter.formatOptions = [.withDay, .withTimeZone]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "282-0700")

        isoFormatter.formatOptions = [.withWeekOfYear, .withTimeZone]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "W40-0700")

        isoFormatter.formatOptions = [.withMonth, .withTimeZone]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10-0700")

        isoFormatter.formatOptions = [.withDay, .withWeekOfYear, .withTimeZone]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "W4006-0700")

        isoFormatter.formatOptions = [.withDay, .withMonth, .withTimeZone]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "1008-0700")

        isoFormatter.formatOptions = [.withDay, .withWeekOfYear, .withMonth, .withTimeZone]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10W4006-0700")

        isoFormatter.formatOptions = [.withFullDate, .withTimeZone]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "2016-10-08-0700")

        isoFormatter.formatOptions = [.withFullTime, .withTimeZone]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "15:31:00-07:00")

        isoFormatter.formatOptions = [.withDay, .withWeekOfYear, .withMonth, .withTimeZone, .withColonSeparatorInTimeZone]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10W4006-07:00")

        isoFormatter.formatOptions = [.withDay, .withWeekOfYear, .withMonth, .withTimeZone, .withColonSeparatorInTimeZone, .withDashSeparatorInDate]
        XCTAssertEqual(isoFormatter.string(from: someDateTime), "10-W40-06-07:00")
#endif
    }
    
    
    
    func test_dateFromString() {
        
        let f = ISO8601DateFormatter()
        var result = f.date(from: "2016-10-08T00:00:00Z")
        XCTAssertNotNil(result)
        if let stringResult = result?.description {
            XCTAssertEqual(stringResult, "2016-10-08 00:00:00 +0000")
        }

        result = f.date(from: "2016-10-08T00:00:00+0600")
        XCTAssertNotNil(result)
        if let stringResult = result?.description {
            XCTAssertEqual(stringResult, "2016-10-07 18:00:00 +0000")
        }
        
        result = f.date(from: "2016-10-08T00:00:00-0600")
        XCTAssertNotNil(result)
        if let stringResult = result?.description {
            XCTAssertEqual(stringResult, "2016-10-08 06:00:00 +0000")
        }

        result = f.date(from: "12345")
        XCTAssertNil(result)

    }
    
    
    
    func test_stringFromDateClass() {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm zzz"
        let dateString = "2016/10/08 22:31 GMT"

        guard let someDateTime = formatter.date(from: dateString) else {
            XCTFail("DateFormatter was unable to parse '\(dateString)' using '\(formatter.dateFormat ?? "")' date format.")
            return
        }

        guard let timeZone = TimeZone(identifier: "GMT") else {
            XCTFail("Failed to create instance of TimeZone using GMT identifier")
            return
        }

        var formatOptions: ISO8601DateFormatter.Options = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withColonSeparatorInTimeZone]

        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "2016-10-08T22:31:00Z")

        /*
         The following tests cover various cases when changing the .formatOptions property.
         */

        formatOptions = [.withInternetDateTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "2016-10-08T22:31:00Z")

        formatOptions = [.withInternetDateTime, .withSpaceBetweenDateAndTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "2016-10-08 22:31:00Z")

        formatOptions = .withFullTime
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "22:31:00Z")

        formatOptions = .withFullDate
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "2016-10-08")

        formatOptions = [.withFullTime, .withFullDate]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "2016-10-08T22:31:00Z")

        formatOptions = [.withFullTime, .withFullDate, .withSpaceBetweenDateAndTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "2016-10-08 22:31:00Z")

        formatOptions = [.withDay, .withTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "282T223100")

        formatOptions = [.withWeekOfYear, .withTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "W40T223100")

        formatOptions = [.withMonth, .withTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "10T223100")

        formatOptions = [.withDay, .withWeekOfYear, .withTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "W4006T223100")

        formatOptions = [.withDay, .withMonth, .withTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "1008T223100")

        formatOptions = [.withWeekOfYear, .withMonth, .withTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "10W40T223100")

        formatOptions = [.withWeekOfYear, .withMonth, .withTime, .withColonSeparatorInTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "10W40T22:31:00")

        formatOptions = [.withWeekOfYear, .withMonth, .withTime, .withColonSeparatorInTime, .withSpaceBetweenDateAndTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "10W40 22:31:00")

        formatOptions = [.withWeekOfYear, .withMonth, .withTime, .withColonSeparatorInTime, .withSpaceBetweenDateAndTime, .withDashSeparatorInDate]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "10-W40 22:31:00")

        formatOptions = [.withDay, .withWeekOfYear]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "W4006")

        formatOptions = [.withDay, .withMonth]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "1008")

        formatOptions = [.withWeekOfYear, .withMonth]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "10W40")

        formatOptions = [.withDay, .withWeekOfYear, .withMonth]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "10W4006")

        formatOptions = [.withMonth, .withDay, .withWeekOfYear, .withDashSeparatorInDate]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: timeZone, formatOptions: formatOptions), "10-W40-06")

#if !os(Android)
        /*
         The following tests cover various cases when changing the .formatOptions property with a different TimeZone set.
         */

        guard let pstTimeZone = TimeZone(identifier: "PST") else {
            XCTFail("Failed to create instance of TimeZone using PST identifier")
            return
        }

        formatOptions = [.withInternetDateTime]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "2016-10-08T15:31:00-07:00")

        formatOptions = [.withTime, .withTimeZone]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "153100-0700")

        formatOptions = [.withDay, .withTimeZone]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "282-0700")

        formatOptions = [.withWeekOfYear, .withTimeZone]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "W40-0700")

        formatOptions = [.withMonth, .withTimeZone]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "10-0700")

        formatOptions = [.withDay, .withWeekOfYear, .withTimeZone]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "W4006-0700")

        formatOptions = [.withDay, .withMonth, .withTimeZone]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "1008-0700")

        formatOptions = [.withDay, .withWeekOfYear, .withMonth, .withTimeZone]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "10W4006-0700")

        formatOptions = [.withFullDate, .withTimeZone]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "2016-10-08-0700")

        formatOptions = [.withFullTime, .withTimeZone]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "15:31:00-07:00")

        formatOptions = [.withDay, .withWeekOfYear, .withMonth, .withTimeZone, .withColonSeparatorInTimeZone]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "10W4006-07:00")

        formatOptions = [.withDay, .withWeekOfYear, .withMonth, .withTimeZone, .withColonSeparatorInTimeZone, .withDashSeparatorInDate]
        XCTAssertEqual(ISO8601DateFormatter.string(from: someDateTime, timeZone: pstTimeZone, formatOptions: formatOptions), "10-W40-06-07:00")
#endif
    }

}
