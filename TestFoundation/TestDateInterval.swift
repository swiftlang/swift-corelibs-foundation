// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestDateInterval: XCTestCase {
    static var allTests: [(String, (TestDateInterval) -> () throws -> Void)] {
        return [
            ("test_default_constructor", test_default_constructor),
            ("test_start_end_constructor", test_start_end_constructor),
            ("test_start_duration_constructor", test_start_duration_constructor),
            ("test_compare_different_starts", test_compare_different_starts),
            ("test_compare_different_durations", test_compare_different_durations),
            ("test_compare_same", test_compare_same),
            ("test_comparison_operators", test_comparison_operators),
            ("test_intersects", test_intersects),
            ("test_intersection", test_intersection),
            ("test_intersection_zero_duration", test_intersection_zero_duration),
            ("test_intersection_nil", test_intersection_nil),
            ("test_contains", test_contains),
            ("test_hashing", test_hashing),
        ]
    }

    func test_default_constructor() {
        let dateInterval = DateInterval()
        XCTAssertEqual(dateInterval.duration, 0)
    }
    
    func test_start_end_constructor() {
        let date1 = dateWithString("2019-04-04 17:09:23 -0700")
        let date2 = dateWithString("2019-04-04 18:09:23 -0700")
        let dateInterval = DateInterval(start: date1, end: date2)
        XCTAssertEqual(dateInterval.duration, 60 * 60)
    }

    func test_start_duration_constructor() {
        let date = dateWithString("2019-04-04 17:09:23 -0700")
        let dateInterval = DateInterval(start: date, duration: 60)
        XCTAssertEqual(dateInterval.duration, 60)
    }

    func test_compare_different_starts() {
        let date1 = dateWithString("2019-04-04 17:09:23 -0700")
        let date2 = dateWithString("2019-04-04 18:09:23 -0700")
        let dateInterval1 = DateInterval(start: date1, duration: 100)
        let dateInterval2 = DateInterval(start: date2, duration: 100)
        XCTAssertEqual(dateInterval1.compare(dateInterval2), .orderedAscending)
        XCTAssertEqual(dateInterval2.compare(dateInterval1), .orderedDescending)
    }
    
    func test_compare_different_durations() {
        let date = dateWithString("2019-04-04 17:09:23 -0700")
        let dateInterval1 = DateInterval(start: date, duration: 60)
        let dateInterval2 = DateInterval(start: date, duration: 90)
        XCTAssertEqual(dateInterval1.compare(dateInterval2), .orderedAscending)
        XCTAssertEqual(dateInterval2.compare(dateInterval1), .orderedDescending)
    }

    func test_compare_same() {
        let date = dateWithString("2019-04-04 17:09:23 -0700")
        let dateInterval1 = DateInterval(start: date, duration: 60)
        let dateInterval2 = DateInterval(start: date, duration: 60)
        XCTAssertEqual(dateInterval1.compare(dateInterval2), .orderedSame)
        XCTAssertEqual(dateInterval2.compare(dateInterval1), .orderedSame)
    }
    
    func test_comparison_operators() {
        let date1 = dateWithString("2019-04-04 17:00:00 -0700")
        let date2 = dateWithString("2019-04-04 17:30:00 -0700")
        let dateInterval1 = DateInterval(start: date1, duration: 60)
        let dateInterval2 = DateInterval(start: date2, duration: 60)
        let dateInterval3 = DateInterval(start: date1, duration: 90)
        let dateInterval4 = DateInterval(start: date1, duration: 60)
        XCTAssertTrue(dateInterval1 < dateInterval2)
        XCTAssertTrue(dateInterval1 < dateInterval3)
        XCTAssertTrue(dateInterval1 == dateInterval4)
    }

    func test_intersects() {
        let date1 = dateWithString("2019-04-04 17:09:23 -0700")
        let date2 = dateWithString("2019-04-04 17:10:20 -0700")
        let dateInterval1 = DateInterval(start: date1, duration: 60)
        let dateInterval2 = DateInterval(start: date2, duration: 15)
        XCTAssertTrue(dateInterval1.intersects(dateInterval2))
    }
    
    func test_intersection() {
        let date1 = dateWithString("2019-04-04 17:00:00 -0700")
        let date2 = dateWithString("2019-04-04 17:15:00 -0700")
        let dateInterval1 = DateInterval(start: date1, duration: 60 * 30)
        let dateInterval2 = DateInterval(start: date2, duration: 60 * 30)
        let intersection = dateInterval1.intersection(with: dateInterval2)
        XCTAssertNotNil(intersection)
        XCTAssertEqual(intersection!.duration, 60 * 15)
    }

    func test_intersection_zero_duration() {
        let date1 = dateWithString("2019-04-04 17:00:00 -0700")
        let date2 = dateWithString("2019-04-04 17:30:00 -0700")
        let dateInterval1 = DateInterval(start: date1, duration: 60 * 30)
        let dateInterval2 = DateInterval(start: date2, duration: 60 * 30)
        let intersection = dateInterval1.intersection(with: dateInterval2)
        XCTAssertNotNil(intersection)
        XCTAssertEqual(intersection!.duration, 0)
    }
    
    func test_intersection_nil() {
        let date1 = dateWithString("2019-04-04 17:00:00 -0700")
        let date2 = dateWithString("2019-04-04 17:30:01 -0700")
        let dateInterval1 = DateInterval(start: date1, duration: 60 * 30)
        let dateInterval2 = DateInterval(start: date2, duration: 60 * 30)
        XCTAssertNil(dateInterval1.intersection(with: dateInterval2))
    }
    
    func test_contains() {
        let date1 = dateWithString("2019-04-04 17:00:00 -0700")
        let date2 = dateWithString("2019-04-04 17:30:00 -0700")
        let date3 = dateWithString("2019-04-04 17:45:00 -0700")
        let date4 = dateWithString("2019-04-04 17:50:00 -0700")
        let dateInterval = DateInterval(start: date1, duration: 60 * 45)
        XCTAssertTrue(dateInterval.contains(date2))
        XCTAssertTrue(dateInterval.contains(date3))
        XCTAssertFalse(dateInterval.contains(date4))
    }
    
    func test_hashing() {
        guard #available(iOS 10.10, OSX 10.12, tvOS 10.0, watchOS 3.0, *) else { return }

        let start1a = dateWithString("2019-04-04 17:09:23 -0700")
        let start1b = dateWithString("2019-04-04 17:09:23 -0700")
        let start2a = Date(timeIntervalSinceReferenceDate: start1a.timeIntervalSinceReferenceDate.nextUp)
        let start2b = Date(timeIntervalSinceReferenceDate: start1a.timeIntervalSinceReferenceDate.nextUp)
        let duration1 = 1800.0
        let duration2 = duration1.nextUp
        let intervals: [[DateInterval]] = [
            [
                DateInterval(start: start1a, duration: duration1),
                DateInterval(start: start1b, duration: duration1),
            ],
            [
                DateInterval(start: start1a, duration: duration2),
                DateInterval(start: start1b, duration: duration2),
            ],
            [
                DateInterval(start: start2a, duration: duration1),
                DateInterval(start: start2b, duration: duration1),
            ],
            [
                DateInterval(start: start2a, duration: duration2),
                DateInterval(start: start2b, duration: duration2),
            ],
        ]
        checkHashableGroups(intervals)
    }
}
