// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSDateComponents: XCTestCase {

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

    func test_nanoseconds() throws {
        // 1971-06-21 00:00:00
        let date1 = Date(timeIntervalSince1970: 46310400)

        // 1971-06-21 00:00:00.00123
        let date2 = Date(timeIntervalSince1970: 46310400.00123)

        // 1971-06-24 00:16:40:00123
        let date3 = Date(timeIntervalSince1970: 46570600.45678)

        var calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "UTC"))

        let diff1 = calendar.dateComponents([.nanosecond], from: date1, to: date2)
        XCTAssertEqual(diff1.nanosecond, 1230003)

        let diff2 = calendar.dateComponents([.nanosecond], from: date1, to: date2)
        XCTAssertEqual(diff2.nanosecond, 1230003)

        let diff3 = calendar.dateComponents([.day, .minute, .second, .nanosecond], from: date2, to: date3)
        XCTAssertEqual(diff3.day, 3)
        XCTAssertEqual(diff3.minute, 16)
        XCTAssertEqual(diff3.second, 40)
        XCTAssertEqual(diff3.nanosecond, 455549949)

        let diff4 = calendar.dateComponents([.day, .minute, .second, .nanosecond], from: date3, to: date2)
        XCTAssertEqual(diff4.day, -3)
        XCTAssertEqual(diff4.minute, -16)
        XCTAssertEqual(diff4.second, -40)
        XCTAssertEqual(diff4.nanosecond, -455549950)
    }

    func test_currentCalendar() {
        let month = Calendar.current.dateComponents([.month], from: Date(timeIntervalSince1970: 1554678000)).month // 2019-04-07 23:00:00.000 Sunday
        XCTAssertEqual(month, 4)

        let components = Calendar.current.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: Date(timeIntervalSince1970: 1554678000))
        XCTAssertEqual(components.year, 2019)
        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.hour, 23)

        let d1 = Date.init(timeIntervalSince1970: 1529431200.0) // 2018-06-19 18:00:00 +0000
        let d2 = Date.init(timeIntervalSince1970: 1529604000.0) // 2018-06-21 18:00:00 +0000
        XCTAssertEqual(Calendar.current.compare(d1, to: d2, toGranularity: .month), .orderedSame)
        XCTAssertEqual(Calendar.current.compare(d1, to: d2, toGranularity: .weekday), .orderedAscending)
        XCTAssertEqual(Calendar.current.compare(d2, to: d1, toGranularity: .weekday), .orderedDescending)
    }

    static var allTests: [(String, (TestNSDateComponents) -> () throws -> Void)] {
        return [
            ("test_hash", test_hash),
            ("test_copyNSDateComponents", test_copyNSDateComponents),
            ("test_dateDifferenceComponents", test_dateDifferenceComponents),
            ("test_nanoseconds", test_nanoseconds),
            ("test_currentCalendar", test_currentCalendar),
        ]
    }
}
