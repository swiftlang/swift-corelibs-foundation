// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSCalendar: XCTestCase {
    func test_initWithCalendarIdentifier() {
        var calMaybe = NSCalendar(calendarIdentifier: NSCalendar.Identifier("Not a calendar"))
        XCTAssertNil(calMaybe)
        
        calMaybe = NSCalendar(calendarIdentifier: .chinese)
        guard let cal = calMaybe else {
            XCTFail(); return
        }
        
        XCTAssertEqual(cal.calendarIdentifier, NSCalendar.Identifier.chinese)
    }
    
    func test_calendarWithIdentifier() {
        var calMaybe = NSCalendar(identifier: NSCalendar.Identifier("Not a calendar"))
        XCTAssertNil(calMaybe)
        
        calMaybe = NSCalendar(identifier: .chinese)
        guard let cal = calMaybe else {
            XCTFail(); return
        }
        
        XCTAssertEqual(cal.calendarIdentifier, NSCalendar.Identifier.chinese)
    }
    
    func test_calendarOptions() {
        let allOptions: [NSCalendar.Options] = [.matchStrictly, .searchBackwards, .matchPreviousTimePreservingSmallerUnits, .matchNextTimePreservingSmallerUnits, .matchNextTime, .matchFirst, .matchLast]
        
        for (i, option) in allOptions.enumerated() {
            var otherOptions: NSCalendar.Options.RawValue = 0
            
            for (j, otherOption) in allOptions.enumerated() {
                if (i != j) {
                    otherOptions |= otherOption.rawValue
                }
            }
            
            XCTAssertEqual(0, (option.rawValue & otherOptions), "Options should be exclusive")
        }
    }
    
    func test_isEqualWithDifferentWaysToCreateCalendar() throws {
        let date = Date(timeIntervalSinceReferenceDate: 497973600) // 2016-10-12 07:00:00 +0000;
        
        let gregorianCalendar = try XCTUnwrap(NSCalendar(identifier: .gregorian))
        let gregorianCalendar2 = try XCTUnwrap(gregorianCalendar.components(.calendar, from: date).calendar) as NSCalendar
        
        XCTAssertEqual(gregorianCalendar, gregorianCalendar2)
        
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Antarctica/Vostok"))
        gregorianCalendar.timeZone = timeZone
        let gregorianCalendar3 = try XCTUnwrap(gregorianCalendar.components(.calendar, from: date).calendar) as NSCalendar
        
        XCTAssertEqual(gregorianCalendar, gregorianCalendar3)
    }
    
    func test_isEqual() throws {
        let testCal1 = try XCTUnwrap(NSCalendar(identifier: .gregorian))
        let testCal2 = try XCTUnwrap(NSCalendar(identifier: .gregorian))
        XCTAssertEqual(testCal1, testCal2)
        
        testCal2.timeZone = try XCTUnwrap(TimeZone(identifier: "Antarctica/Vostok"))
        testCal2.locale = Locale(identifier: "ru_RU")
        testCal2.firstWeekday += 1
        testCal2.minimumDaysInFirstWeek += 1
        XCTAssertNotEqual(testCal1, testCal2)
        
        let testCal3 = try XCTUnwrap(NSCalendar(calendarIdentifier: .chinese))
        XCTAssertNotEqual(testCal1, testCal3)
    }
    
    func test_isEqualCurrentCalendar() {
        let testCal1 = NSCalendar.current as NSCalendar
        let testCal2 = NSCalendar.current as NSCalendar
        XCTAssertEqual(testCal1, testCal2)
        XCTAssert(testCal1 !== testCal2)
        
        XCTAssertNotEqual(testCal1.firstWeekday, 4)
        testCal1.firstWeekday = 4
        XCTAssertNotEqual(testCal1, testCal2)
    }
    
    func test_isEqualAutoUpdatingCurrentCalendar() {
        let testCal1 = NSCalendar.autoupdatingCurrent as NSCalendar
        let testCal2 = NSCalendar.autoupdatingCurrent as NSCalendar
        XCTAssertEqual(testCal1, testCal2)
        XCTAssert(testCal1 !== testCal2)
        
        XCTAssertNotEqual(testCal1.firstWeekday, 4)
        testCal1.firstWeekday = 4
        XCTAssertNotEqual(testCal1, testCal2)
    }
    
    func test_copy() throws {
        let cal = try XCTUnwrap(NSCalendar(identifier: .gregorian))
        let calCopy = try XCTUnwrap((cal.copy() as? NSCalendar))
        XCTAssertEqual(cal, calCopy)
        XCTAssert(cal !== calCopy)
    }
    
    func test_copyCurrentCalendar() throws {
        let cal = NSCalendar.current as NSCalendar
        let calCopy = try XCTUnwrap((cal.copy() as? NSCalendar))
        XCTAssertEqual(cal, calCopy)
        XCTAssert(cal !== calCopy)
    }
    
    // MARK: API Method Tests
    
    let timeIntervalsNext50Months: [TimeInterval] = [
        349776000, // 2012-02-01 08:00:00 +0000
        352281600, // 2012-03-01 08:00:00 +0000
        354956400, // 2012-04-01 07:00:00 +0000
        357548400, // 2012-05-01 07:00:00 +0000
        360226800, // 2012-06-01 07:00:00 +0000
        362818800, // 2012-07-01 07:00:00 +0000
        365497200, // 2012-08-01 07:00:00 +0000
        368175600, // 2012-09-01 07:00:00 +0000
        370767600, // 2012-10-01 07:00:00 +0000
        373446000, // 2012-11-01 07:00:00 +0000
        376041600, // 2012-12-01 08:00:00 +0000
        378720000, // 2013-01-01 08:00:00 +0000
        381398400, // 2013-02-01 08:00:00 +0000
        383817600, // 2013-03-01 08:00:00 +0000
        386492400, // 2013-04-01 07:00:00 +0000
        389084400, // 2013-05-01 07:00:00 +0000
        391762800, // 2013-06-01 07:00:00 +0000
        394354800, // 2013-07-01 07:00:00 +0000
        397033200, // 2013-08-01 07:00:00 +0000
        399711600, // 2013-09-01 07:00:00 +0000
        402303600, // 2013-10-01 07:00:00 +0000
        404982000, // 2013-11-01 07:00:00 +0000
        407577600, // 2013-12-01 08:00:00 +0000
        410256000, // 2014-01-01 08:00:00 +0000
        412934400, // 2014-02-01 08:00:00 +0000
        415353600, // 2014-03-01 08:00:00 +0000
        418028400, // 2014-04-01 07:00:00 +0000
        420620400, // 2014-05-01 07:00:00 +0000
        423298800, // 2014-06-01 07:00:00 +0000
        425890800, // 2014-07-01 07:00:00 +0000
        428569200, // 2014-08-01 07:00:00 +0000
        431247600, // 2014-09-01 07:00:00 +0000
        433839600, // 2014-10-01 07:00:00 +0000
        436518000, // 2014-11-01 07:00:00 +0000
        439113600, // 2014-12-01 08:00:00 +0000
        441792000, // 2015-01-01 08:00:00 +0000
        444470400, // 2015-02-01 08:00:00 +0000
        446889600, // 2015-03-01 08:00:00 +0000
        449564400, // 2015-04-01 07:00:00 +0000
        452156400, // 2015-05-01 07:00:00 +0000
        454834800, // 2015-06-01 07:00:00 +0000
        457426800, // 2015-07-01 07:00:00 +0000
        460105200, // 2015-08-01 07:00:00 +0000
        462783600, // 2015-09-01 07:00:00 +0000
        465375600, // 2015-10-01 07:00:00 +0000
        468054000, // 2015-11-01 07:00:00 +0000
        470649600, // 2015-12-01 08:00:00 +0000
        473328000, // 2016-01-01 08:00:00 +0000
        476006400, // 2016-02-01 08:00:00 +0000
        478512000, // 2016-03-01 08:00:00 +0000
    ];
    
    func test_next50MonthsFromDate() throws {
        let calendar = try XCTUnwrap(NSCalendar(identifier: .gregorian))
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        
        let startDate = Date(timeIntervalSinceReferenceDate: 347113850) // 2012-01-01 12:30:50 +0000
        
        let expectedDates = timeIntervalsNext50Months.map { Date(timeIntervalSinceReferenceDate: $0) }
        
        var count = 0
        var resultDates: [Date] = []
        let components = NSDateComponents()
        components.day = 1
        
        calendar.enumerateDates(startingAfter: startDate, matching: components as DateComponents, options: .matchNextTime) { (date, exactMatch, stop) in
            count += 1
            if count > expectedDates.count {
                stop.pointee = true
                return
            }
            
            guard let date = date else {
                XCTFail()
                stop.pointee = true
                return
            }
            
            resultDates.append(date)
        }
        
        XCTAssertEqual(expectedDates, resultDates)
    }
    
    let iterableCalendarUnits: [NSCalendar.Unit] = [
        .era,
        .year,
        .month,
        .day,
        .hour,
        .minute,
        .second,
        .weekday,
        .weekdayOrdinal,
        .quarter,
        .weekOfMonth,
        .weekOfYear,
        .yearForWeekOfYear,
        .nanosecond,
        .calendar,
        .timeZone,
    ]
    
    let allCalendarUnits: NSCalendar.Unit = [
        .era,
        .year,
        .month,
        .day,
        .hour,
        .minute,
        .second,
        .weekday,
        .weekdayOrdinal,
        .quarter,
        .weekOfMonth,
        .weekOfYear,
        .yearForWeekOfYear,
        .nanosecond,
        .calendar,
        .timeZone,
    ]
    
    func yieldUnits(in components: NSDateComponents) -> [NSCalendar.Unit] {
        return iterableCalendarUnits.filter({ (unit) -> Bool in
            switch unit {
            case .calendar:
                return components.calendar != nil
            case .timeZone:
                return components.timeZone != nil
            default:
                return components.value(forComponent: unit) != NSDateComponentUndefined
            }
        })
    }
    
    func units(in components: NSDateComponents) -> NSCalendar.Unit {
        return yieldUnits(in: components).reduce([], { (current, toAdd) in
            var new = current
            new.insert(toAdd)
            return new
        })
    }
    
    func performTest_dateByAdding(with calendar: NSCalendar, components: NSDateComponents, toAdd secondComponents: NSDateComponents, options: NSCalendar.Options, expected: NSDateComponents, addSingleUnit: Bool) throws {
        
        let date = try XCTUnwrap(calendar.date(from: components as DateComponents))
        var returnedDate: Date
        
        if addSingleUnit {
            let unit = units(in: secondComponents)
            let valueToAdd = secondComponents.value(forComponent: unit)
            
            returnedDate = try XCTUnwrap(calendar.date(byAdding: unit, value: valueToAdd, to: date, options: options))
        } else {
            returnedDate = try XCTUnwrap(calendar.date(byAdding: secondComponents as DateComponents, to: date, options: options))
        }
        
        let expectedUnitFlags = units(in: expected)
        
        // If the NSDateComponents is being added to with a time zone, we want the result to be in the same time zone.
        let originalTimeZone = calendar.timeZone
        let calculationTimeZone = components.timeZone
        if let calculationTimeZone = calculationTimeZone {
            calendar.timeZone = calculationTimeZone
        }
        
        let returnedComponents = calendar.components(expectedUnitFlags, from: returnedDate) as NSDateComponents
        
        XCTAssertEqual(expected, returnedComponents, "\(calendar.calendarIdentifier) \(components) \(secondComponents) Expected \(expected), but received \(returnedComponents)")
        
        if calculationTimeZone != nil {
            calendar.timeZone = originalTimeZone
        }
    }
    
    func performTest_componentsFromDateToDate(with calendar: NSCalendar, from fromComponents: NSDateComponents, to toComponents: NSDateComponents, expected: NSDateComponents, options: NSCalendar.Options) throws {
        let fromDate = try XCTUnwrap(calendar.date(from: fromComponents as DateComponents))
        let toDate = try XCTUnwrap(calendar.date(from: toComponents as DateComponents))
        
        let expectedUnitFlags = units(in: expected)
        let returned = calendar.components(expectedUnitFlags, from: fromDate, to: toDate, options: options) as NSDateComponents
        XCTAssertEqual(expected, returned, "Expected \(expected), but received \(returned) - from date: \(fromDate) to date: \(toDate)")
    }
    
    func performTest_componentsFromDCToDC(with calendar: NSCalendar, from fromComponents: NSDateComponents, to toComponents: NSDateComponents, expected: NSDateComponents, options: NSCalendar.Options) throws {
        let expectedUnitFlags = units(in: expected)
        let returned = calendar.components(expectedUnitFlags, from: fromComponents as DateComponents, to: toComponents as DateComponents, options: options) as NSDateComponents
        XCTAssertEqual(expected, returned, "Expected \(expected), but received \(returned) - from components: \(fromComponents) to components: \(toComponents)")
    }
    
    func performTest_getComponentsInOtherCalendar(from fromCalendar: NSCalendar, to toCalendar: NSCalendar, from fromComponents: NSDateComponents, expected: NSDateComponents) throws {
        let originalTZ = fromCalendar.timeZone
        fromCalendar.timeZone = toCalendar.timeZone
        
        let fromDate = try XCTUnwrap(fromCalendar.date(from: fromComponents as DateComponents))
        
        fromCalendar.timeZone = originalTZ
        
        let expectedUnitFlags = units(in: expected)
        let returned = toCalendar.components(expectedUnitFlags, from: fromDate) as NSDateComponents
        
        XCTAssertEqual(expected, returned, "Expected \(expected), but received \(returned) - from calendar: \(fromCalendar) to calendar: \(toCalendar) from components: \(fromComponents)")
    }
    
    func test_dateByAddingUnit_withWrapOption() throws {
        let locale = Locale(identifier: "ar_EG")
        let calendar = try XCTUnwrap(NSCalendar(identifier: .gregorian))
        let timeZone = try XCTUnwrap(TimeZone(abbreviation: "GMT"))
        
        calendar.locale = locale
        calendar.timeZone = timeZone
        
        let date = try self.date(fromFixture: "2013-09-20 23:20:28 +0000")
        let newDate = try XCTUnwrap(calendar.date(byAdding: .hour, value: 12, to: date, options: .wrapComponents))
        XCTAssertEqual(newDate, try self.date(fromFixture: "2013-09-20 11:20:28 +0000"))
    }
    
    func date(fromFixture string: String) throws -> Date {
        let formatter = DateFormatter()
        let calendar = Calendar(identifier: .gregorian)
        
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US")
        
        return try XCTUnwrap(formatter.date(from: string))
    }
    
    func enumerateTestDates(using block: (NSCalendar, Date, NSDateComponents) throws -> Void) throws {
        func yield(to block: (NSCalendar, Date, NSDateComponents) throws -> Void, _ element: (calendarIdentifier: NSCalendar.Identifier, localeIdentifier: String, timeZoneName: String, dateString: String)) throws {
            let calendar = try XCTUnwrap(NSCalendar(calendarIdentifier: element.calendarIdentifier))
            let currentCalendar = NSCalendar.current as NSCalendar
            let autoCalendar = NSCalendar.autoupdatingCurrent as NSCalendar
            
            for aCalendar in [calendar, currentCalendar, autoCalendar] {
                if aCalendar.calendarIdentifier != element.calendarIdentifier {
                    continue
                }
                
                let locale = NSLocale(localeIdentifier: element.localeIdentifier) as Locale
                let timeZone = try XCTUnwrap(TimeZone(identifier: element.timeZoneName))
                calendar.locale = locale
                calendar.timeZone = timeZone
                
                let date = try self.date(fromFixture: element.dateString)
                let components = calendar.components(self.allCalendarUnits, from: date) as NSDateComponents
                
                try block(calendar, date, components)
            }
        }
        
        try yield(to: block, (.gregorian,           "en_US",   "America/Edmonton",    "1906-09-01 00:33:52 -0700"))
        try yield(to: block, (.gregorian,           "en_US",   "America/Los_Angeles", "2014-09-23 20:11:39 -0800"))
        try yield(to: block, (.gregorian,           "en_US",   "America/Los_Angeles", "2016-02-29 06:30:33 -0900"))
        try yield(to: block, (.hebrew,              "he_IL",   "Asia/Jerusalem",      "2018-12-24 05:40:43 +0200"))
        try yield(to: block, (.hebrew,              "he_IL",   "Asia/Jerusalem",      "2019-03-22 09:23:26 +0200"))
        try yield(to: block, (.buddhist,            "es_MX",   "America/Cancun",      "2022-10-26 23:05:34 -0500"))
        try yield(to: block, (.buddhist,            "es_MX",   "America/Cancun",      "2014-10-22 07:13:00 -0500"))
        try yield(to: block, (.japanese,            "ja_JP",   "Asia/Tokyo",          "2013-08-23 06:09:01 +0900"))
        try yield(to: block, (.japanese,            "ja_JP",   "Asia/Tokyo",          "2014-11-23 05:34:30 +0900"))
        try yield(to: block, (.persian,             "ps_AF",   "Asia/Kabul",          "2013-07-18 20:55:06 +0430"))
        try yield(to: block, (.persian,             "ps_AF",   "Asia/Kabul",          "2015-09-21 23:21:45 +0430"))
        try yield(to: block, (.coptic,              "ar_EG",   "Africa/Cairo",        "2013-12-22 19:49:15 +0200"))
        try yield(to: block, (.coptic,              "ar_EG",   "Africa/Cairo",        "2015-03-14 17:36:20 +0200"))
        try yield(to: block, (.ethiopicAmeteMihret, "am_ET",   "Africa/Addis_Ababa",  "2014-01-31 10:10:33 +0300"))
        try yield(to: block, (.ethiopicAmeteMihret, "am_ET",   "Africa/Addis_Ababa",  "2013-07-19 13:05:16 +0300"))
        try yield(to: block, (.ethiopicAmeteAlem,   "am_ET",   "Africa/Addis_Ababa",  "2015-02-28 16:34:34 +0300"))
        try yield(to: block, (.ethiopicAmeteAlem,   "am_ET",   "Africa/Addis_Ababa",  "2017-07-19 15:25:59 +0300"))
        try yield(to: block, (.islamic,             "ar_SA",   "Asia/Riyadh",         "2015-06-04 19:28:36 +0300"))
        try yield(to: block, (.islamic,             "ar_SA",   "Asia/Riyadh",         "2015-05-21 21:47:39 +0300"))
        try yield(to: block, (.islamicCivil,        "ar_SA",   "Asia/Riyadh",         "2002-05-05 22:44:18 +0300"))
        try yield(to: block, (.islamicCivil,        "ar_SA",   "Asia/Riyadh",         "2015-11-20 02:21:09 +0300"))
        try yield(to: block, (.chinese,             "zh_CN",   "Asia/Hong_Kong",      "2019-04-12 01:12:10 +0800"))
        try yield(to: block, (.chinese,             "zh_CN",   "Asia/Hong_Kong",      "2015-04-02 07:13:22 +0800"))
        try yield(to: block, (.chinese,             "zh_CN",   "Asia/Hong_Kong",      "2014-10-16 06:12:10 +0800"))

#if !os(Windows)
        // TODO: these are deprecated aliases which are unavailable on Windows,
        // it is unclear if the support for the old names need to be validated.
        try yield(to: block, (.hebrew,              "he_IL",   "Israel",              "2018-12-24 05:40:43 +0200"))
        try yield(to: block, (.hebrew,              "he_IL",   "Israel",              "2019-03-22 09:23:26 +0200"))
#endif
    }
    
    func test_getEra_year_month_day_fromDate() throws {
        try enumerateTestDates() { (calendar, date, components) in
            var era = 0, year = 0, month = 0, day = 0
            calendar.getEra(&era, year: &year, month: &month, day: &day, from: date)
            
            XCTAssertEqual(era, components.era)
            XCTAssertEqual(year, components.year)
            XCTAssertEqual(month, components.month)
            XCTAssertEqual(day, components.day)
        }
    }
    
    func test_getEra_yearForWeekOfYear_weekOfYear_weekday_fromDate() throws {
        try enumerateTestDates() { (calendar, date, components) in
            var era = 0, yearForWeekOfYear = 0, weekOfYear = 0, weekday = 0
            calendar.getEra(&era, yearForWeekOfYear: &yearForWeekOfYear, weekOfYear: &weekOfYear, weekday: &weekday, from: date)
            
            XCTAssertEqual(era, components.era)
            XCTAssertEqual(yearForWeekOfYear, components.yearForWeekOfYear)
            XCTAssertEqual(weekOfYear, components.weekOfYear)
            XCTAssertEqual(weekday, components.weekday)
        }
    }
    
    func test_getHour_minute_second_nanoseconds_fromDate() throws {
        try enumerateTestDates() { (calendar, date, components) in
            var hour = 0, minute = 0, second = 0, nanosecond = 0
            calendar.getHour(&hour, minute: &minute, second: &second, nanosecond: &nanosecond, from: date)
            
            XCTAssertEqual(hour, components.hour)
            XCTAssertEqual(minute, components.minute)
            XCTAssertEqual(second, components.second)
            XCTAssertEqual(nanosecond, components.nanosecond)
        }
    }
    
    func test_component_fromDate() throws {
        try enumerateTestDates() { (calendar, date, components) in
            for unit in iterableCalendarUnits {
                if unit == .calendar || unit == .timeZone {
                    continue
                }
                
                let value = calendar.component(unit, from: date)
                let expectedValue = components.value(forComponent: unit)
                
                XCTAssertEqual(expectedValue, value)
            }
        }
    }
    
    func test_dateWithYear_month_day_hour_minute_second_nanosecond() throws {
        try enumerateTestDates() { (calendar, date, components) in
            let returnedDate = try XCTUnwrap(calendar.date(era: components.era, year: components.year, month: components.month, day: components.day, hour: components.hour, minute: components.minute, second: components.second, nanosecond: components.nanosecond))
            
            let interval = date.timeIntervalSince(returnedDate)
            XCTAssertEqual(fabs(interval), 0, accuracy: 0.0000001)
        }
    }
    
    func test_dateWithYearForWeekOfYear_weekOfYear_weekday_hour_minute_second_nanosecond() throws {
        try enumerateTestDates() { (calendar, date, components) in
            // Era is defined to be in the current era, so the below can only work for dates that are in the current era.
            if components.era != calendar.components(.era, from: Date()).era {
                return
            }
            if (calendar.calendarIdentifier == .chinese) {
                // chinese calendar does not work for yearForWeekOfYear
                return;
            }
            
            let returnedDate = try XCTUnwrap(calendar.date(era: components.era, yearForWeekOfYear: components.yearForWeekOfYear, weekOfYear: components.weekOfYear, weekday: components.weekday, hour: components.hour, minute: components.minute, second: components.second, nanosecond: components.nanosecond))
            
            let interval = date.timeIntervalSince(returnedDate)
            XCTAssertEqual(fabs(interval), 0, accuracy: 0.0000001)
        }
    }
    
    func enumerateTestDatesWithStartOfDay(using block: (NSCalendar, Date, Date) throws -> Void) throws {
        func yield(to block: (NSCalendar, Date, Date) throws -> Void, _ element: (calendarIdentifier: NSCalendar.Identifier, localeIdentifier: String, timeZoneName: String, dateString: String, startOfDayDateString: String)) throws {
            let calendar = try XCTUnwrap(NSCalendar(calendarIdentifier: element.calendarIdentifier))
            let currentCalendar = NSCalendar.current as NSCalendar
            let autoCalendar = NSCalendar.autoupdatingCurrent as NSCalendar
            
            for aCalendar in [calendar, currentCalendar, autoCalendar] {
                if aCalendar.calendarIdentifier != element.calendarIdentifier {
                    continue
                }
                
                let locale = NSLocale(localeIdentifier: element.localeIdentifier) as Locale
                let timeZone = try XCTUnwrap(TimeZone(identifier: element.timeZoneName))
                calendar.locale = locale
                calendar.timeZone = timeZone
                
                let date = try self.date(fromFixture: element.dateString)
                let startOfDay = try self.date(fromFixture: element.startOfDayDateString)
                
                try block(calendar, date, startOfDay)
            }
        }
        
        try yield(to: block, (.gregorian, "en_US", "America/Los_Angeles", "2013-03-26 10:04:16 -0700", "2013-03-26 00:00:00 -0700"))
        try yield(to: block, (.gregorian, "pt_BR", "America/Sao_Paulo", "2013-10-20 13:10:20 -0200", "2013-10-20 01:00:00 -0200")) // DST jump forward at midnight
        try yield(to: block, (.gregorian, "pt_BR", "America/Sao_Paulo", "2014-02-15 23:59:59 -0300", "2014-02-15 00:00:00 -0200")) // DST jump backward
#if !os(Windows)
        // TODO: these are deprecated aliases which are unavailable on Windows,
        // it is unclear if the support for the old names need to be validated.
        try yield(to: block, (.gregorian, "pt_BR", "Brazil/East", "2013-10-20 13:10:20 -0200", "2013-10-20 01:00:00 -0200")) // DST jump forward at midnight
        try yield(to: block, (.gregorian, "pt_BR", "Brazil/East", "2014-02-15 23:59:59 -0300", "2014-02-15 00:00:00 -0200")) // DST jump backward
#endif
    }
    
    func test_startOfDayForDate() throws {
        try enumerateTestDatesWithStartOfDay() { (calendar, date, startOfDay) in
            let resultDate = calendar.startOfDay(for: date)
            XCTAssertEqual(startOfDay, resultDate)
        }
    }
    
    func test_componentsInTimeZone_fromDate() throws {
        try enumerateTestDates() { (calendar, date, components) in
            let calendarWithoutTimeZone = try XCTUnwrap(NSCalendar(identifier: calendar.calendarIdentifier))
            calendarWithoutTimeZone.locale = calendar.locale
            
            let timeZone = calendar.timeZone
            
            let returned = calendarWithoutTimeZone.components(in: timeZone, from: date) as NSDateComponents
            XCTAssertEqual(components, returned)
        }
    }
    
    func enumerateTestDateComparisons(using block: (NSCalendar, Date, Date, NSCalendar.Unit, ComparisonResult) throws -> Void) throws {
        func yield(to block: (NSCalendar, Date, Date, NSCalendar.Unit, ComparisonResult) throws -> Void, _ element: (calendarIdentifier: NSCalendar.Identifier, localeIdentifier: String, timeZoneName: String, firstDateString: String, secondDateString: String, granularity: NSCalendar.Unit, expectedResult: ComparisonResult)) throws {
            let calendar = try XCTUnwrap(NSCalendar(calendarIdentifier: element.calendarIdentifier))
            let currentCalendar = NSCalendar.current as NSCalendar
            let autoCalendar = NSCalendar.autoupdatingCurrent as NSCalendar
            
            for aCalendar in [calendar, currentCalendar, autoCalendar] {
                if aCalendar.calendarIdentifier != element.calendarIdentifier {
                    continue
                }
                
                let locale = NSLocale(localeIdentifier: element.localeIdentifier) as Locale
                let timeZone = try XCTUnwrap(TimeZone(identifier: element.timeZoneName))
                calendar.locale = locale
                calendar.timeZone = timeZone
                
                let firstDate = try self.date(fromFixture: element.firstDateString)
                let secondDate = try self.date(fromFixture: element.secondDateString)
                
                try block(calendar, firstDate, secondDate, element.granularity, element.expectedResult)
            }
        }
        
        try yield(to: block, (.gregorian,             "en_US",   "America/Los_Angeles", "2014-09-23 20:11:39 -0800", "2014-09-23 20:11:39 -0800", .year, .orderedSame))
        try yield(to: block, (.gregorian,             "en_US",   "America/Los_Angeles", "2014-09-23 20:11:39 -0800", "2014-09-23 20:11:39 -0800", .month, .orderedSame))
        try yield(to: block, (.gregorian,             "en_US",   "America/Los_Angeles", "2014-09-23 20:11:39 -0800", "2014-09-23 20:11:39 -0800", .day, .orderedSame))
        try yield(to: block, (.gregorian,             "en_US",   "America/Los_Angeles", "2014-09-23 20:11:39 -0800", "2014-09-23 20:11:39 -0800", .hour, .orderedSame))
        try yield(to: block, (.gregorian,             "en_US",   "America/Los_Angeles", "2014-09-23 20:11:39 -0800", "2014-09-23 20:11:39 -0800", .minute, .orderedSame))
        try yield(to: block, (.gregorian,             "en_US",   "America/Los_Angeles", "2014-09-23 20:11:39 -0800", "2014-09-23 20:11:39 -0800", .second, .orderedSame))
        
        // DST fall back
        try yield(to: block, (.gregorian,             "en_US",   "America/Los_Angeles", "2014-11-02 01:30:00 -0700", "2014-11-02 01:30:00 -0800", .day, .orderedSame))
        try yield(to: block, (.gregorian,             "en_US",   "America/Los_Angeles", "2014-11-02 01:30:00 -0700", "2014-11-02 01:30:00 -0800", .hour, .orderedAscending))
        try yield(to: block, (.gregorian,             "en_US",   "America/Los_Angeles", "2014-11-02 01:30:00 -0700", "2014-11-02 01:30:00 -0800", .minute, .orderedAscending))
        try yield(to: block, (.gregorian,             "en_US",   "America/Los_Angeles", "2014-11-02 01:30:00 -0700", "2014-11-02 01:30:00 -0800", .second, .orderedAscending))
        
        // Chinese leap month. First date is not a leap month, 2nd is. Same day.
        try yield(to: block, (.chinese,             "zh_CN",   "Asia/Hong_Kong", "2014-10-07 21:12:10 +0000", "2014-11-06 21:12:10 +0000", .era, .orderedSame))
        try yield(to: block, (.chinese,             "zh_CN",   "Asia/Hong_Kong", "2014-10-07 21:12:10 +0000", "2014-11-06 21:12:10 +0000", .year, .orderedSame))
        try yield(to: block, (.chinese,             "zh_CN",   "Asia/Hong_Kong", "2014-10-07 21:12:10 +0000", "2014-11-06 21:12:10 +0000", .month, .orderedAscending))
        try yield(to: block, (.chinese,             "zh_CN",   "Asia/Hong_Kong", "2014-10-07 21:12:10 +0000", "2014-11-06 21:12:10 +0000", .day, .orderedAscending))
        try yield(to: block, (.chinese,             "zh_CN",   "Asia/Hong_Kong", "2014-10-07 21:12:10 +0000", "2014-11-06 21:12:10 +0000", .hour, .orderedAscending))
        try yield(to: block, (.chinese,             "zh_CN",   "Asia/Hong_Kong", "2014-10-07 21:12:10 +0000", "2014-11-06 21:12:10 +0000", .minute, .orderedAscending))
        try yield(to: block, (.chinese,             "zh_CN",   "Asia/Hong_Kong", "2014-10-07 21:12:10 +0000", "2014-11-06 21:12:10 +0000", .second, .orderedAscending))
        
        // Different eras. era: 235, year: 23, month: 1, day: 22 vs  era: 234, year: 23, month: 1, day: 22
        try yield(to: block, (.japanese,             "ja_JP",   "Asia/Tokyo", "2011-01-23 06:12:10 +0900", "1948-01-23 06:12:10 +0900", .era, .orderedDescending))
        try yield(to: block, (.japanese,             "ja_JP",   "Asia/Tokyo", "2011-01-23 06:12:10 +0900", "1948-01-23 06:12:10 +0900", .year, .orderedDescending))
        try yield(to: block, (.japanese,             "ja_JP",   "Asia/Tokyo", "2011-01-23 06:12:10 +0900", "1948-01-23 06:12:10 +0900", .month, .orderedDescending))
        try yield(to: block, (.japanese,             "ja_JP",   "Asia/Tokyo", "2011-01-23 06:12:10 +0900", "1948-01-23 06:12:10 +0900", .day, .orderedDescending))
        try yield(to: block, (.japanese,             "ja_JP",   "Asia/Tokyo", "2011-01-23 06:12:10 +0900", "1948-01-23 06:12:10 +0900", .hour, .orderedDescending))
        try yield(to: block, (.japanese,             "ja_JP",   "Asia/Tokyo", "2011-01-23 06:12:10 +0900", "1948-01-23 06:12:10 +0900", .minute, .orderedDescending))
        try yield(to: block, (.japanese,             "ja_JP",   "Asia/Tokyo", "2011-01-23 06:12:10 +0900", "1948-01-23 06:12:10 +0900", .second, .orderedDescending))
        
        // Same week and week of year, different non-week year.
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-30 02:34:56 +0000", "2013-01-04 02:34:56 +0000", .yearForWeekOfYear, .orderedSame))
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-30 02:34:56 +0000", "2013-01-04 02:34:56 +0000", .weekOfYear, .orderedSame))
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-30 02:34:56 +0000", "2013-01-04 02:34:56 +0000", .weekOfMonth, .orderedAscending))
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-30 02:34:56 +0000", "2013-01-04 02:34:56 +0000", .weekday, .orderedAscending))
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-30 02:34:56 +0000", "2013-01-04 02:34:56 +0000", .weekdayOrdinal, .orderedAscending))
        
        // Same non-week year, different week of year
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-30 02:34:56 +0000", "2012-12-29 02:34:56 +0000", .yearForWeekOfYear, .orderedDescending))
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-30 02:34:56 +0000", "2012-12-29 02:34:56 +0000", .weekOfYear, .orderedDescending))
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-30 02:34:56 +0000", "2012-12-29 02:34:56 +0000", .weekOfMonth, .orderedDescending))
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-30 02:34:56 +0000", "2012-12-29 02:34:56 +0000", .weekday, .orderedDescending))
        
        // Same week, different weekday ordinal
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-14 02:34:56 +0000", "2012-12-15 02:34:56 +0000", .weekOfYear, .orderedSame))
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-14 02:34:56 +0000", "2012-12-15 02:34:56 +0000", .weekOfMonth, .orderedSame))
        try yield(to: block, (.buddhist,             "zh-Hans_HK",   "Asia/Hong_Kong", "2012-12-14 02:34:56 +0000", "2012-12-15 02:34:56 +0000", .weekdayOrdinal, .orderedAscending))
    }
    
    func test_compareDate_toDate_toUnitGranularity() throws {
        try enumerateTestDateComparisons { (calendar, firstDate, secondDate, granularity, result) in
            let returned = calendar.compare(firstDate, to: secondDate, toUnitGranularity: granularity)
            
            XCTAssertEqual(returned, result, "Comparison result should match; expected \(result), got \(returned), when comparing \(firstDate) (\(firstDate.timeIntervalSinceReferenceDate) to \(secondDate) (\(secondDate.timeIntervalSinceReferenceDate) with granularity \(granularity)")
        }
    }
    
    func test_isDate_equalToDate_toUnitGranularity() throws {
        try enumerateTestDateComparisons { (calendar, firstDate, secondDate, granularity, result) in
            let expected = result == .orderedSame
            let returned = calendar.isDate(firstDate, equalTo: secondDate, toUnitGranularity: granularity)
            
            XCTAssertEqual(returned, expected)
        }
    }
    
    let availableCalendarIdentifiers: [NSCalendar.Identifier] = [
        .gregorian,
        .buddhist,
        .chinese,
        .coptic,
        .ethiopicAmeteMihret,
        .ethiopicAmeteAlem,
        .hebrew,
        .ISO8601,
        .indian,
        .islamic,
        .islamicCivil,
        .japanese,
        .persian,
        .republicOfChina,
        .islamicTabular,
        .islamicUmmAlQura,
    ]
    
    func test_isDateInToday() throws {
        var datesTested: [Date] = []
        for identifier in availableCalendarIdentifiers {
            let calendar = try XCTUnwrap(NSCalendar(identifier: identifier))
            
            var foundDate = false
            var dateInToday = Date()
            for _ in 0..<10 {
                datesTested.append(dateInToday)
                if calendar.isDateInToday(dateInToday) {
                    foundDate = true
                    break
                }
                dateInToday += 1
            }
            
            XCTAssertTrue(foundDate, "Unable to match any of these dates: \(datesTested)")
            
            // Makes sure it doesn't work for other dates:
            XCTAssertFalse(calendar.isDateInToday(Date.distantPast), "Shouldn't match the distant past")
            XCTAssertFalse(calendar.isDateInToday(Date.distantFuture), "Shouldn't match the distant future")
        }
    }
  
    func test_isDateInYesterday() throws {
        var datesTested: [Date] = []
        for identifier in availableCalendarIdentifiers {
            let calendar = try XCTUnwrap(NSCalendar(identifier: identifier))
            
            var foundDate = false
            var dateInToday = Date()
            for _ in 0..<10 {
                let delta = NSDateComponents()
                delta.day = -1
                let dateInYesterday = try XCTUnwrap(calendar.date(byAdding: delta as DateComponents, to: dateInToday))
                
                datesTested.append(dateInYesterday)
                if calendar.isDateInYesterday(dateInYesterday) {
                    foundDate = true
                    break
                }
                dateInToday += 1
            }
            
            XCTAssertTrue(foundDate, "Unable to match any of these dates: \(datesTested)")
            
            // Makes sure it doesn't work for other dates:
            XCTAssertFalse(calendar.isDateInYesterday(Date.distantPast), "Shouldn't match the distant past")
            XCTAssertFalse(calendar.isDateInYesterday(Date.distantFuture), "Shouldn't match the distant future")
        }
    }
    
    func test_isDateInTomorrow() throws {
        var datesTested: [Date] = []
        for identifier in availableCalendarIdentifiers {
            let calendar = try XCTUnwrap(NSCalendar(identifier: identifier))
            
            var foundDate = false
            var dateInToday = Date()
            for _ in 0..<10 {
                let delta = NSDateComponents()
                delta.day = 1
                let dateInTomorrow = try XCTUnwrap(calendar.date(byAdding: delta as DateComponents, to: dateInToday))
                
                datesTested.append(dateInTomorrow)
                if calendar.isDateInTomorrow(dateInTomorrow) {
                    foundDate = true
                    break
                }
                dateInToday += 1
            }
            
            XCTAssertTrue(foundDate, "Unable to match any of these dates: \(datesTested)")
            
            // Makes sure it doesn't work for other dates:
            XCTAssertFalse(calendar.isDateInTomorrow(Date.distantPast), "Shouldn't match the distant past")
            XCTAssertFalse(calendar.isDateInTomorrow(Date.distantFuture), "Shouldn't match the distant future")
        }
    }
    
    func enumerateTestWeekends(using block: (NSCalendar, DateInterval) throws -> Void) throws {
        func yield(to block: (NSCalendar, DateInterval) throws -> Void, _ element: (calendarIdentifier: NSCalendar.Identifier, localeIdentifier: String, timeZoneName: String, firstDateString: String, secondDateString: String)) throws {
            let calendar = try XCTUnwrap(NSCalendar(calendarIdentifier: element.calendarIdentifier))
            
            let locale = NSLocale(localeIdentifier: element.localeIdentifier) as Locale
            let timeZone = try XCTUnwrap(TimeZone(identifier: element.timeZoneName))
            calendar.locale = locale
            calendar.timeZone = timeZone
            
            let firstDate = try self.date(fromFixture: element.firstDateString)
            let secondDate = try self.date(fromFixture: element.secondDateString)
            
            try block(calendar, DateInterval(start: firstDate, end: secondDate))
        }
        
        try yield(to: block, (.gregorian,             "en_US",   "America/Edmonton",    "1906-09-01 00:33:52 -0700",   "1906-09-03 00:00:00 -0700")) // suprise weekend 1
        try yield(to: block, (.gregorian,             "en_US",   "Asia/Damascus",       "2006-04-01 01:00:00 +0300",   "2006-04-03 00:00:00 +0300")) // suprise weekend 2
        try yield(to: block, (.gregorian,             "en_US",   "Asia/Tehran",         "2014-03-22 01:00:00 +0430",   "2014-03-24 00:00:00 +0430")) // suprise weekend 3
        try yield(to: block, (.gregorian,             "en_US",   "Africa/Algiers",      "1971-04-24 00:00:00 +0000",   "1971-04-26 00:00:00 +0100")) // suprise weekday 1
        try yield(to: block, (.gregorian,             "en_US",   "America/Toronto",     "1919-03-29 00:00:00 -0500",   "1919-03-31 00:30:00 -0400")) // suprise weekday 2
        try yield(to: block, (.gregorian,             "en_US",   "Europe/Madrid",       "1978-04-01 00:00:00 +0100",   "1978-04-03 00:00:00 +0200")) // suprise weekday 3
        try yield(to: block, (.hebrew,                "he_IL",   "Asia/Jerusalem",      "2018-03-23 00:00:00 +0200",   "2018-03-25 00:00:00 +0300")) // weekend with DST jump
        try yield(to: block, (.japanese,              "ja_JP",   "Asia/Tokyo",          "2015-08-22 00:00:00 +0900",   "2015-08-24 00:00:00 +0900")) // japanese
        try yield(to: block, (.persian,               "ps_AF",   "Asia/Kabul",          "2015-03-19 00:00:00 +0430",   "2015-03-21 00:00:00 +0430")) // persian
        try yield(to: block, (.coptic,                "ar_EG",   "Africa/Cairo",        "2015-12-18 00:00:00 +0200",   "2015-12-20 00:00:00 +0200")) // coptic
        try yield(to: block, (.ethiopicAmeteMihret,   "am_ET",   "Africa/Addis_Ababa",  "2015-07-25 00:00:00 +0300",   "2015-07-27 00:00:00 +0300")) // ethiopic
        try yield(to: block, (.ethiopicAmeteAlem,     "am_ET",   "Africa/Addis_Ababa",  "2015-07-25 00:00:00 +0300",   "2015-07-27 00:00:00 +0300")) // ethiopic-amete-alem
        try yield(to: block, (.islamic,               "ar_SA",   "Asia/Riyadh",         "2015-05-29 00:00:00 +0300",   "2015-05-31 00:00:00 +0300")) // islamic
        try yield(to: block, (.islamicCivil,          "ar_SA",   "Asia/Riyadh",         "2015-05-29 00:00:00 +0300",   "2015-05-31 00:00:00 +0300")) // islamic-civil
        try yield(to: block, (.chinese,               "zh_CN",   "Asia/Hong_Kong",      "2015-01-03 00:00:00 +0800",   "2015-01-05 00:00:00 +0800")) // chinese
#if !os(Windows)
        // TODO: these are deprecated aliases which are unavailable on Windows,
        // it is unclear if the support for the old names need to be validated.
        try yield(to: block, (.hebrew,                "he_IL",   "Israel",              "2018-03-23 00:00:00 +0200",   "2018-03-25 00:00:00 +0300")) // weekend with DST jump
#endif
    }
    
    func test_isDateInWeekend() throws {
        try enumerateTestWeekends() { (calendar, interval) in
            XCTAssertTrue(calendar.isDateInWeekend(interval.start), "Start date should be in weekend")
            XCTAssertFalse(calendar.isDateInWeekend(interval.end), "End date should not be in weekend")
            
            XCTAssertFalse(calendar.isDateInWeekend(interval.start - 1), "Just before start date should not be in weekend")
            XCTAssertTrue(calendar.isDateInWeekend(interval.end - 1), "Just before end date should be in weekend")
        }
    }
    
    func test_rangeOfWeekendStartDate_interval_containingDate() throws {
#if !DARWIN_COMPATIBILITY_TESTS // NSCalender range(ofWeekendContaining:) is experimental
        try enumerateTestWeekends() { (calendar, interval) in
            let startDateResult = calendar.range(ofWeekendContaining: interval.start)
            XCTAssertEqual(startDateResult, interval)
            
            let endDateResult = calendar.range(ofWeekendContaining: interval.end)
            XCTAssertNil(endDateResult)
            
            let oneSecondBeforeStartResult = calendar.range(ofWeekendContaining: interval.start - 1)
            XCTAssertNil(oneSecondBeforeStartResult)
            
            let oneSecondBeforeEndResult = calendar.range(ofWeekendContaining: interval.end - 1)
            XCTAssertEqual(oneSecondBeforeEndResult, interval)
        }
#endif
    }
    
    func test_enumerateDatesStartingAfterDate_chineseEra_matchYearOne() throws {
        let calendar = try XCTUnwrap(NSCalendar(calendarIdentifier: .chinese))
        let locale = Locale(identifier: "zh_CN")
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        calendar.locale = locale
        calendar.timeZone = timeZone
        
        let startDate = try date(fromFixture: "2013-06-19 15:59:59 +0000")
        let matchingComponents = NSDateComponents()
        matchingComponents.year = 1
        
        let expectedDate = try date(fromFixture: "1984-02-01 16:00:00 +0000")
        var atLeastOnce = false
        
        calendar.enumerateDates(startingAfter: startDate, matching: matchingComponents as DateComponents, options: [.matchStrictly, .searchBackwards]) { (date, exactMatch, stop) in
            atLeastOnce = true
            if let date = date {
                XCTAssertEqual(expectedDate, date)
                XCTAssertTrue(exactMatch)
                stop.pointee = true
            }
        }
        
        XCTAssertTrue(atLeastOnce)
    }
    
    struct TimeIntervalQuintuple {
        var value: (TimeInterval, TimeInterval, TimeInterval, TimeInterval, TimeInterval) = (0, 0, 0, 0, 0)
        
        subscript(_ index: Int) -> TimeInterval {
            switch index {
            case 0:
                return value.0
            case 1:
                return value.1
            case 2:
                return value.2
            case 3:
                return value.3
            case 4:
                return value.4
            default:
                fatalError()
            }
        }
        
        let count = 5
        
        init(_ a: TimeInterval, _ b: TimeInterval, _ c: TimeInterval, _ d: TimeInterval, _ e: TimeInterval) {
            value = (a, b, c, d, e)
        }
    }
    
    func test_enumerateDatesStartingAfterDate_ensureStrictlyIncreasingResults_minuteSecondClearing() throws {
        // When we match a specific hour in date enumeration, we clear out lower units (minute and second). This can cause us to accidentally match the components backwards, when we otherwise wouldn't have (e.g. 2018-02-14 00:00:01 -> 2018-02-14 00:00:00).
        // This leads us to propose a potential match twice in certain circumstances (when the highest set date component is hour and we're looking for hour 0).
        //
        // We want to ensure this never happens, and that all matches are strictly increasing or decreasing in time.
        let calendar = try XCTUnwrap(NSCalendar(identifier: .gregorian))
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        
        let reference = try date(fromFixture: "2018-02-13 12:00:00 -0800")
        let expectations: [(minute: Int, second: Int, results: TimeIntervalQuintuple)] = [
            (NSDateComponentUndefined, NSDateComponentUndefined, TimeIntervalQuintuple(540288000, 540374400, 540460800, 540547200, 540633600)),
            (0                       , NSDateComponentUndefined, TimeIntervalQuintuple(540288000, 540374400, 540460800, 540547200, 540633600)),
            (NSDateComponentUndefined, 0                       , TimeIntervalQuintuple(540288000, 540374400, 540460800, 540547200, 540633600)),
            (0                       , 0                       , TimeIntervalQuintuple(540288000, 540374400, 540460800, 540547200, 540633600)),
        ]
        
        for expectation in expectations {
            let matchComponents = NSDateComponents()
            matchComponents.hour = 0
            matchComponents.minute = expectation.minute
            matchComponents.second = expectation.second
            
            var j = 0
            calendar.enumerateDates(startingAfter: reference, matching: matchComponents as DateComponents, options: .matchNextTime) { (match, exactMatch, stop) in
                let expected = Date(timeIntervalSinceReferenceDate: TimeInterval(expectation.results[j]))
                XCTAssertTrue(exactMatch)
                XCTAssertEqual(match, expected)
                
                j += 1
                guard j < expectation.results.count else {
                    stop.pointee = true
                    return
                }
            }
        }
    }
    
    static var allTests: [(String, (TestNSCalendar) -> () throws -> Void)] {
        return [
            ("test_initWithCalendarIdentifier", test_initWithCalendarIdentifier),
            ("test_calendarWithIdentifier", test_calendarWithIdentifier),
            ("test_calendarOptions", test_calendarOptions),
            ("test_isEqualWithDifferentWaysToCreateCalendar", test_isEqualWithDifferentWaysToCreateCalendar),
            ("test_isEqual", test_isEqual),
            ("test_isEqualCurrentCalendar", test_isEqualCurrentCalendar),
            ("test_isEqualAutoUpdatingCurrentCalendar", test_isEqualAutoUpdatingCurrentCalendar),
            ("test_copy", test_copy),
            ("test_copyCurrentCalendar", test_copyCurrentCalendar),
            ("test_next50MonthsFromDate", test_next50MonthsFromDate),
            ("test_dateByAddingUnit_withWrapOption", test_dateByAddingUnit_withWrapOption),
            ("test_getEra_year_month_day_fromDate", test_getEra_year_month_day_fromDate),
            ("test_getEra_yearForWeekOfYear_weekOfYear_weekday_fromDate", test_getEra_yearForWeekOfYear_weekOfYear_weekday_fromDate),
            ("test_getHour_minute_second_nanoseconds_fromDate", test_getHour_minute_second_nanoseconds_fromDate),
            ("test_component_fromDate", test_component_fromDate),
            ("test_dateWithYear_month_day_hour_minute_second_nanosecond", test_dateWithYear_month_day_hour_minute_second_nanosecond),
            ("test_dateWithYearForWeekOfYear_weekOfYear_weekday_hour_minute_second_nanosecond", test_dateWithYearForWeekOfYear_weekOfYear_weekday_hour_minute_second_nanosecond),
            ("test_startOfDayForDate", test_startOfDayForDate),
            ("test_componentsInTimeZone_fromDate", test_componentsInTimeZone_fromDate),
            ("test_compareDate_toDate_toUnitGranularity", test_compareDate_toDate_toUnitGranularity),
            ("test_isDate_equalToDate_toUnitGranularity", test_isDate_equalToDate_toUnitGranularity),
            ("test_isDateInToday", test_isDateInToday),
            ("test_isDateInYesterday", test_isDateInYesterday),
            ("test_isDateInTomorrow", test_isDateInTomorrow),
            ("test_isDateInWeekend", test_isDateInWeekend),
            ("test_rangeOfWeekendStartDate_interval_containingDate", test_rangeOfWeekendStartDate_interval_containingDate),
            ("test_enumerateDatesStartingAfterDate_chineseEra_matchYearOne", test_enumerateDatesStartingAfterDate_chineseEra_matchYearOne),
            ("test_enumerateDatesStartingAfterDate_ensureStrictlyIncreasingResults_minuteSecondClearing", test_enumerateDatesStartingAfterDate_ensureStrictlyIncreasingResults_minuteSecondClearing),
        ]
    }
}
