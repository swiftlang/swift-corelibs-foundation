// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestCalendar: XCTestCase {
    
    static var allTests: [(String, (TestCalendar) -> () throws -> Void)] {
        return [
            ("test_allCalendars", test_allCalendars),
            ("test_gettingDatesOnGregorianCalendar", test_gettingDatesOnGregorianCalendar ),
            ("test_gettingDatesOnHebrewCalendar", test_gettingDatesOnHebrewCalendar ),
            ("test_gettingDatesOnChineseCalendar", test_gettingDatesOnChineseCalendar),
            ("test_gettingDatesOnISO8601Calendar", test_gettingDatesOnISO8601Calendar),
            ("test_gettingDatesOnPersianCalendar",
                test_gettingDatesOnPersianCalendar),
            ("test_copy",test_copy),
            ("test_addingDates", test_addingDates),
            ("test_datesNotOnWeekend", test_datesNotOnWeekend),
            ("test_datesOnWeekend", test_datesOnWeekend),
            ("test_customMirror", test_customMirror),
            ("test_ampmSymbols", test_ampmSymbols),
            ("test_currentCalendarRRstability", test_currentCalendarRRstability),
        ]
    }
    
    func test_allCalendars() {
        for identifier in [
            Calendar.Identifier.buddhist,
            Calendar.Identifier.chinese,
            Calendar.Identifier.coptic,
            Calendar.Identifier.ethiopicAmeteAlem,
            Calendar.Identifier.ethiopicAmeteMihret,
            Calendar.Identifier.gregorian,
            Calendar.Identifier.hebrew,
            Calendar.Identifier.indian,
            Calendar.Identifier.islamic,
            Calendar.Identifier.islamicCivil,
            Calendar.Identifier.islamicTabular,
            Calendar.Identifier.islamicUmmAlQura,
            Calendar.Identifier.iso8601,
            Calendar.Identifier.japanese,
            Calendar.Identifier.persian,
            Calendar.Identifier.republicOfChina
            ] {
                let calendar = Calendar(identifier: identifier)
                XCTAssertEqual(identifier,calendar.identifier)
        }
    }

    func test_gettingDatesOnGregorianCalendar() {
        let date = Date(timeIntervalSince1970: 1449332351)
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        XCTAssertEqual(components.year, 2015)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 5)

        // Test for problem reported by Malcolm Barclay via swift-corelibs-dev
        // https://lists.swift.org/pipermail/swift-corelibs-dev/Week-of-Mon-20161128/001031.html
        let fromDate = Date()
        let interval = 200
        let toDate = Date(timeInterval: TimeInterval(interval), since: fromDate)
        let fromToComponents = calendar.dateComponents([.second], from: fromDate, to: toDate)
        XCTAssertEqual(fromToComponents.second, interval);

        // Issue with 32-bit CF calendar vector on Linux
        // Crashes on macOS 10.12.2/Foundation 1349.25
        // (Possibly related) rdar://24384757
        /*
        let interval2 = Int(INT32_MAX) + 1
        let toDate2 = Date(timeInterval: TimeInterval(interval2), since: fromDate)
        let fromToComponents2 = calendar.dateComponents([.second], from: fromDate, to: toDate2)
        XCTAssertEqual(fromToComponents2.second, interval2);
        */
    }

    func test_gettingDatesOnISO8601Calendar() {
        let date = Date(timeIntervalSince1970: 1449332351)

        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        XCTAssertEqual(components.year, 2015)
        XCTAssertEqual(components.month, 12)
        XCTAssertEqual(components.day, 5)
    }

    
    func test_gettingDatesOnHebrewCalendar() {
        let date = Date(timeIntervalSince1970: 1552580351)
        
        var calendar = Calendar(identifier: .hebrew)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(components.year, 5779)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 7)
        XCTAssertEqual(components.isLeapMonth, false)
    }
    
    func test_gettingDatesOnChineseCalendar() {
        let date = Date(timeIntervalSince1970: 1591460351.0)
        
        var calendar = Calendar(identifier: .chinese)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(components.year, 37)
        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.isLeapMonth, true)
    }

    func test_gettingDatesOnPersianCalendar() {
        let date = Date(timeIntervalSince1970: 1539146705)

        var calendar = Calendar(identifier: .persian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        XCTAssertEqual(components.year, 1397)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 18)

    }

    func test_ampmSymbols() {
        let calendar = Calendar(identifier: .gregorian)
        XCTAssertEqual(calendar.amSymbol, "AM")
        XCTAssertEqual(calendar.pmSymbol, "PM")
    }

    func test_currentCalendarRRstability() {
        var AMSymbols = [String]()
        for _ in 1...10 {
            let cal = Calendar.current
            AMSymbols.append(cal.amSymbol)
        }
        
        XCTAssertEqual(AMSymbols.count, 10, "Accessing current calendar should work over multiple callouts")
    }
    
    func test_copy() {
        var calendar = Calendar.current

        //Mutate below fields and check if change is being reflected in copy.
        calendar.firstWeekday = 2 
        calendar.minimumDaysInFirstWeek = 2

        let copy = calendar
        XCTAssertTrue(copy == calendar)

        //verify firstWeekday and minimumDaysInFirstWeek of 'copy'. 
        XCTAssertEqual(copy.firstWeekday, 2)
        XCTAssertEqual(copy.minimumDaysInFirstWeek, 2)
    }
    
    func test_addingDates() {
        let calendar = Calendar(identifier: .gregorian)
        let thisDay = calendar.date(from: DateComponents(year: 2016, month: 10, day: 4))!
        let diffComponents = DateComponents(day: 1)
        let dayAfter = calendar.date(byAdding: diffComponents, to: thisDay)
        
        let dayAfterComponents = calendar.dateComponents([.year, .month, .day], from: dayAfter!)
        XCTAssertEqual(dayAfterComponents.year, 2016)
        XCTAssertEqual(dayAfterComponents.month, 10)
        XCTAssertEqual(dayAfterComponents.day, 5)
    }
    
    func test_datesNotOnWeekend() {
        let calendar = Calendar(identifier: .gregorian)
        let mondayInDecember = calendar.date(from: DateComponents(year: 2018, month: 12, day: 10))!
        XCTAssertFalse(calendar.isDateInWeekend(mondayInDecember))
        let tuesdayInNovember = calendar.date(from: DateComponents(year: 2017, month: 11, day: 14))!
        XCTAssertFalse(calendar.isDateInWeekend(tuesdayInNovember))
        let wednesdayInFebruary = calendar.date(from: DateComponents(year: 2016, month: 2, day: 17))!
        XCTAssertFalse(calendar.isDateInWeekend(wednesdayInFebruary))
        let thursdayInOctober = calendar.date(from: DateComponents(year: 2015, month: 10, day: 22))!
        XCTAssertFalse(calendar.isDateInWeekend(thursdayInOctober))
        let fridayInSeptember = calendar.date(from: DateComponents(year: 2014, month: 9, day: 26))!
        XCTAssertFalse(calendar.isDateInWeekend(fridayInSeptember))
    }
    
    func test_datesOnWeekend() {
        let calendar = Calendar(identifier: .gregorian)
        let saturdayInJanuary = calendar.date(from: DateComponents(year:2017, month: 1, day: 7))!
        XCTAssertTrue(calendar.isDateInWeekend(saturdayInJanuary))
        let sundayInFebruary = calendar.date(from: DateComponents(year: 2016, month: 2, day: 14))!
        XCTAssertTrue(calendar.isDateInWeekend(sundayInFebruary))
    }
    
    func test_customMirror() {
        let calendar = Calendar(identifier: .gregorian)
        let calendarMirror = calendar.customMirror
        
        XCTAssertEqual(calendar.identifier, calendarMirror.descendant("identifier") as? Calendar.Identifier)
        XCTAssertEqual(calendar.locale, calendarMirror.descendant("locale") as? Locale)
        XCTAssertEqual(calendar.timeZone, calendarMirror.descendant("timeZone") as? TimeZone)
        XCTAssertEqual(calendar.firstWeekday, calendarMirror.descendant("firstWeekday") as? Int)
        XCTAssertEqual(calendar.minimumDaysInFirstWeek, calendarMirror.descendant("minimumDaysInFirstWeek") as? Int)
    }
}

class TestNSDateComponents: XCTestCase {

    static var allTests: [(String, (TestNSDateComponents) -> () throws -> Void)] {
        return [
            ("test_hash", test_hash),
            ("test_copyNSDateComponents", test_copyNSDateComponents),
            ("test_dateDifferenceComponents", test_dateDifferenceComponents),
        ]
    }

    func test_hash() {
        let c1 = NSDateComponents()
        c1.year = 2018
        c1.month = 8
        c1.day = 1

        let c2 = NSDateComponents()
        c2.year = 2018
        c2.month = 8
        c2.day = 1

        XCTAssertEqual(c1, c2)
        XCTAssertEqual(c1.hash, c2.hash)

        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.calendar,
            throughValues: [
                Calendar(identifier: .gregorian),
                Calendar(identifier: .buddhist),
                Calendar(identifier: .chinese),
                Calendar(identifier: .coptic),
                Calendar(identifier: .hebrew),
                Calendar(identifier: .indian),
                Calendar(identifier: .islamic),
                Calendar(identifier: .iso8601),
                Calendar(identifier: .japanese),
                Calendar(identifier: .persian)])
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.timeZone,
            throughValues: (-10...10).map { TimeZone(secondsFromGMT: 3600 * $0) })
        // Note: These assume components aren't range checked.
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.era,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.year,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.quarter,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.month,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.day,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.hour,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.minute,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.second,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.nanosecond,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.weekOfYear,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.weekOfMonth,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.yearForWeekOfYear,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.weekday,
            throughValues: 0...20)
        checkHashing_NSCopying(
            initialValue: NSDateComponents(),
            byMutating: \NSDateComponents.weekdayOrdinal,
            throughValues: 0...20)
        // isLeapMonth does not have enough values to test it here.
    }

    func test_copyNSDateComponents() {
        let components = NSDateComponents()
        components.year = 1987
        components.month = 3
        components.day = 17
        components.hour = 14
        components.minute = 20
        components.second = 0
        let copy = components.copy(with: nil) as! NSDateComponents
        XCTAssertTrue(components.isEqual(copy))
        XCTAssertTrue(components == copy)
        XCTAssertFalse(components === copy)
        XCTAssertEqual(copy.year, 1987)
        XCTAssertEqual(copy.month, 3)
        XCTAssertEqual(copy.day, 17)
        XCTAssertEqual(copy.isLeapMonth, false)
        //Mutate NSDateComponents and verify that it does not reflect in the copy
        components.hour = 12
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(copy.hour, 14)
    }

    func test_dateDifferenceComponents() {
        // 1970-01-01 00:00:00
        let date1 = Date(timeIntervalSince1970: 0)

        // 1971-06-21 00:00:00
        let date2 = Date(timeIntervalSince1970: 46310400)

        // 2286-11-20 17:46:40
        let date3 = Date(timeIntervalSince1970: 10_000_000_000)

        // 2286-11-20 17:46:41
        let date4 = Date(timeIntervalSince1970: 10_000_000_001)

        // The date components below assume UTC/GMT time zone.
        guard let timeZone = TimeZone(abbreviation: "UTC") else {
            XCTFail("Unable to create UTC TimeZone for Test")
            return
        }

        var calendar = Calendar.current
        calendar.timeZone = timeZone

        let diff1 = calendar.dateComponents([.month, .year, .day], from: date1, to: date2)
        XCTAssertEqual(diff1.year, 1)
        XCTAssertEqual(diff1.month, 5)
        XCTAssertEqual(diff1.isLeapMonth, false)
        XCTAssertEqual(diff1.day, 20)
        XCTAssertNil(diff1.era)
        XCTAssertNil(diff1.yearForWeekOfYear)
        XCTAssertNil(diff1.quarter)
        XCTAssertNil(diff1.weekOfYear)
        XCTAssertNil(diff1.weekOfMonth)
        XCTAssertNil(diff1.weekdayOrdinal)
        XCTAssertNil(diff1.weekday)
        XCTAssertNil(diff1.hour)
        XCTAssertNil(diff1.minute)
        XCTAssertNil(diff1.second)
        XCTAssertNil(diff1.nanosecond)
        XCTAssertNil(diff1.calendar)
        XCTAssertNil(diff1.timeZone)

        let diff2 = calendar.dateComponents([.weekOfMonth], from: date2, to: date1)
        XCTAssertEqual(diff2.weekOfMonth, -76)
        XCTAssertEqual(diff2.isLeapMonth, false)

        let diff3 = calendar.dateComponents([.weekday], from: date2, to: date1)
        XCTAssertEqual(diff3.weekday, -536)
        XCTAssertEqual(diff3.isLeapMonth, false)

        let diff4 = calendar.dateComponents([.weekday, .weekOfMonth], from: date1, to: date2)
        XCTAssertEqual(diff4.weekday, 4)
        XCTAssertEqual(diff4.weekOfMonth, 76)
        XCTAssertEqual(diff4.isLeapMonth, false)

        let diff5 = calendar.dateComponents([.weekday, .weekOfYear], from: date1, to: date2)
        XCTAssertEqual(diff5.weekday, 4)
        XCTAssertEqual(diff5.weekOfYear, 76)
        XCTAssertEqual(diff5.isLeapMonth, false)

        let diff6 = calendar.dateComponents([.month, .weekOfMonth], from: date1, to: date2)
        XCTAssertEqual(diff6.month, 17)
        XCTAssertEqual(diff6.weekOfMonth, 2)
        XCTAssertEqual(diff6.isLeapMonth, false)

        let diff7 = calendar.dateComponents([.weekOfYear, .weekOfMonth], from: date2, to: date1)
        XCTAssertEqual(diff7.weekOfYear, -76)
        XCTAssertEqual(diff7.weekOfMonth, 0)
        XCTAssertEqual(diff7.isLeapMonth, false)

        let diff8 = calendar.dateComponents([.era, .quarter, .year, .month, .day, .hour, .minute, .second, .nanosecond, .calendar, .timeZone], from: date2, to: date3)
        XCTAssertEqual(diff8.era, 0)
        XCTAssertEqual(diff8.year, 315)
        XCTAssertEqual(diff8.quarter, 0)
        XCTAssertEqual(diff8.month, 4)
        XCTAssertEqual(diff8.day, 30)
        XCTAssertEqual(diff8.hour, 17)
        XCTAssertEqual(diff8.minute, 46)
        XCTAssertEqual(diff8.second, 40)
        XCTAssertEqual(diff8.nanosecond, 0)
        XCTAssertEqual(diff8.isLeapMonth, false)
        XCTAssertNil(diff8.calendar)
        XCTAssertNil(diff8.timeZone)

        let diff9 = calendar.dateComponents([.era, .quarter, .year, .month, .day, .hour, .minute, .second, .nanosecond, .calendar, .timeZone], from: date4, to: date3)
        XCTAssertEqual(diff9.era, 0)
        XCTAssertEqual(diff9.year, 0)
        XCTAssertEqual(diff9.quarter, 0)
        XCTAssertEqual(diff9.month, 0)
        XCTAssertEqual(diff9.day, 0)
        XCTAssertEqual(diff9.hour, 0)
        XCTAssertEqual(diff9.minute, 0)
        XCTAssertEqual(diff9.second, -1)
        XCTAssertEqual(diff9.nanosecond, 0)
        XCTAssertEqual(diff9.isLeapMonth, false)
        XCTAssertNil(diff9.calendar)
        XCTAssertNil(diff9.timeZone)
    }
}
