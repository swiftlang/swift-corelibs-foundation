// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestDateIntervalFormatter: XCTestCase {
    static let allTests = [
        ("testBasics", testBasics)
    ]

    // Apple's ICU variant uses a THIN SPACE instead of a normal space around the separator.
#if canImport(Darwin)
    let separator = "\u{2009}\u{2013}\u{2009}"     // " – "  {THIN SPACE} {EN DASH} {THIN SPACE}
#else
    let separator = "\u{20}\u{2013}\u{20}"         // " – "  {SPACE} {EN DASH} {SPACE}
#endif

    func testBasics() throws {
        let dif = DateIntervalFormatter()
        dif.locale = Locale(identifier: "en_GB")
        dif.dateStyle = .short
        XCTAssertEqual(dif.dateTemplate, "dd/MM/y, HH:mm")

        let f = ISO8601DateFormatter()
        let date1 = try f.date(from: "2019-12-18T20:00:00Z").unwrapped()
        let date2 = try f.date(from: "2019-12-19T22:15:00Z").unwrapped()

        dif.timeZone = TimeZone(identifier: "Europe/London")
        dif.locale = Locale(identifier: "en_GB")
        XCTAssertEqual(dif.string(from: date1, to: date2), "18/12/2019, 20:00\(separator)19/12/2019, 22:15")
        dif.locale = Locale(identifier: "en_US")
        XCTAssertEqual(dif.string(from: date1, to: date2), "12/18/19, 8:00 PM\(separator)12/19/19, 10:15 PM")
        dif.timeZone = TimeZone(identifier: "Europe/Paris")
        XCTAssertEqual(dif.string(from: date1, to: date2), "12/18/19, 9:00 PM\(separator)12/19/19, 11:15 PM")

        dif.dateTemplate = "jm"
        dif.timeZone = TimeZone(identifier: "Europe/London")
        dif.locale = Locale(identifier: "en_GB")
        XCTAssertEqual(dif.string(from: date1, to: date2), "18/12/2019, 20:00\(separator)19/12/2019, 22:15")
        dif.locale = Locale(identifier: "en_US")
        XCTAssertEqual(dif.string(from: date1, to: date2), "12/18/2019, 8:00 PM\(separator)12/19/2019, 10:15 PM")
        dif.timeZone = TimeZone(identifier: "Europe/Paris")
        XCTAssertEqual(dif.string(from: date1, to: date2), "12/18/2019, 9:00 PM\(separator)12/19/2019, 11:15 PM")

        dif.dateTemplate = "MMMd"
        dif.timeZone = TimeZone(identifier: "Europe/London")
        dif.locale = Locale(identifier: "en_GB")
        XCTAssertEqual(dif.string(from: date1, to: date2), "18–19 Dec")
        dif.locale = Locale(identifier: "en_US")
        XCTAssertEqual(dif.string(from: date1, to: date2), "Dec 18\(separator)19")
        dif.timeZone = TimeZone(identifier: "Europe/Paris")
        XCTAssertEqual(dif.string(from: date1, to: date2), "Dec 18\(separator)19")

        dif.dateTemplate = nil
        XCTAssertEqual(dif.string(from: date1, to: date2), "")
    }
}
