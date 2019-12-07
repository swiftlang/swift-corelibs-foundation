// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestUnitVolume: XCTestCase {
    func testMetricVolumeConversions() {
        let cubicKilometers = Measurement(value: 4, unit: UnitVolume.cubicKilometers)
        XCTAssertEqual(cubicKilometers, Measurement(value: 4e9, unit: UnitVolume.cubicMeters), "Conversion from cubicKilometers to cubicMeters")

        let megaliters = Measurement(value: 3, unit: UnitVolume.megaliters)
        XCTAssertEqual(megaliters, Measurement(value: 3_000_000, unit: UnitVolume.liters), "Conversion from megaliters to liters")

        let kiloliters = Measurement(value: 2, unit: UnitVolume.kiloliters)
        XCTAssertEqual(kiloliters, Measurement(value: 2000, unit: UnitVolume.liters), "Conversion from kiloliters to liters")

        let cubicMeters = Measurement(value: 2, unit: UnitVolume.cubicMeters)
        XCTAssertEqual(cubicMeters, Measurement(value: 2000, unit: UnitVolume.liters), "Conversion from cubicMeters to liters")
        XCTAssertEqual(kiloliters, cubicMeters, "Conversion from kiloliters to cubicMeters")

        let liters = Measurement(value: 5, unit: UnitVolume.liters)
        XCTAssertEqual(liters, Measurement(value: 5, unit: UnitVolume.cubicDecimeters), "Conversion from liters to cubicDecimeters")
        XCTAssertEqual(liters, Measurement(value: 50, unit: UnitVolume.deciliters), "Conversion from liters to deciliters")
        XCTAssertEqual(liters, Measurement(value: 500, unit: UnitVolume.centiliters), "Conversion from liters to centiliters")
        XCTAssertEqual(liters, Measurement(value: 5000, unit: UnitVolume.milliliters), "Conversion from liters to milliliters")
        XCTAssertEqual(liters, Measurement(value: 5000, unit: UnitVolume.cubicCentimeters), "Conversion from liters to cubicCentimeters")
        XCTAssertEqual(liters, Measurement(value: 5e6, unit: UnitVolume.cubicMillimeters), "Conversion from liters to cubicMillimeters")
    }

    func testMetricToImperialVolumeConversion() {
        let liters = Measurement(value: 10, unit: UnitVolume.liters)
        XCTAssertEqual(liters.converted(to: .cubicInches).value, 610.236, accuracy: 0.001, "Conversion from liters to cubicInches")
    }

    func testImperialVolumeConversions() {
        let cubicMiles = Measurement(value: 1, unit: UnitVolume.cubicMiles)
        XCTAssertEqual(cubicMiles.converted(to: .cubicYards).value, 1760 * 1760 * 1760, accuracy: 1_000_000, "Conversion from cubicMiles to cubicYards")

        let cubicYards = Measurement(value: 1, unit: UnitVolume.cubicYards)
        XCTAssertEqual(cubicYards.converted(to: .cubicFeet).value, 27, accuracy: 0.001, "Conversion from cubicYards to cubicFeet")

        let cubicFeet = Measurement(value: 1, unit: UnitVolume.cubicFeet)
        XCTAssertEqual(cubicFeet.converted(to: .cubicInches).value, 1728, accuracy: 0.01, "Conversion from cubicFeet to cubicInches")

        let gallons = Measurement(value: 1, unit: UnitVolume.gallons)
        XCTAssertEqual(gallons.converted(to: .quarts).value, 4, accuracy: 0.001, "Conversion from gallons to quarts")

        let quarts = Measurement(value: 1, unit: UnitVolume.quarts)
        XCTAssertEqual(quarts.converted(to: .pints).value, 2, accuracy: 0.001, "Conversion from quarts to pints")

        let pints = Measurement(value: 1, unit: UnitVolume.pints)
        XCTAssertEqual(pints.converted(to: .cups).value, 2, accuracy: 0.05, "Conversion from pints to cups")

        let cups = Measurement(value: 1, unit: UnitVolume.cups)
        XCTAssertEqual(cups.converted(to: .fluidOunces).value, 8.12, accuracy: 0.01, "Conversion from cups to fluidOunces")

        let fluidOunces = Measurement(value: 1, unit: UnitVolume.fluidOunces)
        XCTAssertEqual(fluidOunces.converted(to: .tablespoons).value, 2, accuracy: 0.001, "Conversion from fluidOunces to tablespoons")

        let tablespoons = Measurement(value: 1, unit: UnitVolume.tablespoons)
        XCTAssertEqual(tablespoons.converted(to: .teaspoons).value, 3, accuracy: 0.001, "Conversion from tablespoons to teaspoons")

        let teaspoons = Measurement(value: 1, unit: UnitVolume.teaspoons)
        XCTAssertEqual(teaspoons.converted(to: .cubicInches).value, 0.3, accuracy: 0.001, "Conversion from teaspoons to cubicInches")
    }

    static let allTests = [
        ("testMetricVolumeConversions", testMetricVolumeConversions),
        ("testMetricToImperialVolumeConversion", testMetricToImperialVolumeConversion),
        ("testImperialVolumeConversions", testImperialVolumeConversions),
    ]
}
