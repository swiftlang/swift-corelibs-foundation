// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestUnitPressure: XCTestCase {
    func testMetricPressureConversions() {
        let newtonsPerMetersSquared = Measurement(value: 4_010, unit: UnitPressure.newtonsPerMetersSquared)
        XCTAssertEqual(newtonsPerMetersSquared, Measurement(value: 40.1, unit: UnitPressure.hectopascals), "Conversion from newtonsPerMetersSquared to hectopascals")
        XCTAssertEqual(newtonsPerMetersSquared, Measurement(value: 40.1, unit: UnitPressure.millibars), "Conversion from newtonsPerMetersSquared to millibars")

        let hectopascals = Measurement(value: 5_020, unit: UnitPressure.hectopascals)
        XCTAssertEqual(hectopascals, Measurement(value: 502, unit: UnitPressure.kilopascals), "Conversion from hectopascals to kilopascals")

        let kilopascals = Measurement(value: 6_030, unit: UnitPressure.kilopascals)
        XCTAssertEqual(kilopascals, Measurement(value: 6.03, unit: UnitPressure.megapascals), "Conversion from kilopascals to megapascals")

        let megapascals = Measurement(value: 7_040, unit: UnitPressure.megapascals)
        XCTAssertEqual(megapascals, Measurement(value: 7.04, unit: UnitPressure.gigapascals), "Conversion from megapascals to gigapascals")

        let millibars = Measurement(value: 8_000, unit: UnitPressure.millibars)
        XCTAssertEqual(millibars, Measurement(value: 8, unit: UnitPressure.bars), "Conversion from millibars to bars")
        XCTAssertEqual(millibars.converted(to: .millimetersOfMercury).value, 6_000.51, accuracy: 0.001, "Conversion from millibars to millimetersOfMercury")

    }

    func testMetricToImperialPressureConversion() {
        let newtonsPerMetersSquared = Measurement(value: 1_000_000, unit: UnitPressure.newtonsPerMetersSquared)
        XCTAssertEqual(newtonsPerMetersSquared.converted(to: .poundsForcePerSquareInch).value, 145.037, accuracy: 0.001, "Conversion from newtonsPerMetersSquared to poundsForcePerSquareInch")
    }

    func testImperialPressureConversion() {
        let poundsForcePerSquareInch = Measurement(value: 1_000, unit: UnitPressure.poundsForcePerSquareInch)
        XCTAssertEqual(poundsForcePerSquareInch, Measurement(value: 1, unit: UnitPressure.kilopoundsForcePerSquareInch), "Conversion from poundsForcePerSquareInch to kilopoundsForcePerSquareInch")

        let kilopoundsForcePerSquareInch = Measurement(value: 2_000, unit: UnitPressure.kilopoundsForcePerSquareInch)
        XCTAssertEqual(kilopoundsForcePerSquareInch, Measurement(value: 2, unit: UnitPressure.megapoundsForcePerSquareInch), "Conversion from kilopoundsForcePerSquareInch to megapoundsForcePerSquareInch")
    }

    static let allTests = [
        ("testMetricPressureConversions", testMetricPressureConversions),
        ("testMetricToImperialPressureConversion", testMetricToImperialPressureConversion),
        ("testImperialPressureConversion", testImperialPressureConversion)
    ]
}

