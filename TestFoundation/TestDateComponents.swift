// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestDateComponents: XCTestCase {

    func test_hash() {
        let c1 = DateComponents(year: 2018, month: 8, day: 1)
        let c2 = DateComponents(year: 2018, month: 8, day: 1)

        XCTAssertEqual(c1, c2)
        XCTAssertEqual(c1.hashValue, c2.hashValue)

        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.calendar,
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
                Calendar(identifier: .persian)
            ])
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.timeZone,
            throughValues: (-10...10).map { TimeZone(secondsFromGMT: 3600 * $0) })
        // Note: These assume components aren't range checked.
        let integers: [Int?] = (0..<20).map { $0 as Int? }
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.era,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.year,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.quarter,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.month,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.day,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.hour,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.minute,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.second,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.nanosecond,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.weekOfYear,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.weekOfMonth,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.yearForWeekOfYear,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.weekday,
            throughValues: integers)
        checkHashing_ValueType(
            initialValue: DateComponents(),
            byMutating: \DateComponents.weekdayOrdinal,
            throughValues: integers)
        // isLeapMonth does not have enough values to test it here.
    }

    func test_isValidDate() throws {
        // SR-11569
        let calendarTimeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let dateComponentsTimeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 3600))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = calendarTimeZone

        var dc = DateComponents()
        dc.calendar = calendar
        dc.timeZone = dateComponentsTimeZone
        dc.year = 2019
        dc.month = 1
        dc.day = 2
        dc.hour = 3
        dc.minute = 4
        dc.second = 5
        dc.nanosecond = 6
        XCTAssertTrue(dc.isValidDate)
    }

    static var allTests: [(String, (TestDateComponents) -> () throws -> Void)] {
        return [
            ("test_hash", test_hash),
            ("test_isValidDate", test_isValidDate),
        ]
    }
}
