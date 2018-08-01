// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestDateComponents: XCTestCase {
    static var allTests: [(String, (TestDateComponents) -> () throws -> Void)] {
        return [
            ("test_hash", test_hash),
        ]
    }

    func test_hash() {
        let c1 = DateComponents(year: 2018, month: 8, day: 1)
        let c2 = DateComponents(year: 2018, month: 8, day: 1)

        XCTAssertEqual(c1, c2)
        XCTAssertEqual(c1.hashValue, c2.hashValue)

        checkHashableMutations_ValueType(
            DateComponents(),
            \DateComponents.calendar,
            [
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
        checkHashableMutations_ValueType(
            DateComponents(),
            \DateComponents.timeZone,
            (-10...10).map { TimeZone(secondsFromGMT: 3600 * $0) })
        // Note: These assume components aren't range checked.
        let integers: [Int?] = (0..<20).map { $0 as Int? }
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.era, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.year, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.quarter, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.month, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.day, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.hour, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.minute, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.second, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.nanosecond, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.weekOfYear, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.weekOfMonth, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.yearForWeekOfYear, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.weekday, integers)
        checkHashableMutations_ValueType(DateComponents(), \DateComponents.weekdayOrdinal, integers)
        // isLeapMonth does not have enough values to test it here.
    }
}
