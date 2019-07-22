// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Foundation

class TestMeasurementFormatter: XCTestCase {
    static var allTests: [(String, (TestMeasurementFormatter) -> () throws -> Void)] {
        return [
            ("testSeriesFormat", testSeriesFormat),
        ]
    }

    func testSeriesFormat() {
        let f = MeasurementFormatter()
        XCTAssertEqual(f.locale, Locale.current)
        let enLocale = Locale(identifier: "en_US_POSIX")
        f.locale = enLocale
        // Request format of unit twice
        XCTAssertEqual(f.locale, enLocale)
        let kgUnit = UnitMass.kilograms
        let kgstr = f.string(from: kgUnit)
        XCTAssertEqual(f.string(from: kgUnit), kgstr)

        // Still ok after change of unit?
        let knotUnit = UnitSpeed.knots
        let knotStr = f.string(from: knotUnit)
        XCTAssertEqual(f.string(from: knotUnit), knotStr)
        
    }
}

