// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestUnitLength: XCTestCase {
    func testImperialAndAstronomicalConversions() {
        func meters(_ unit: UnitLength) -> Double { Measurement(value: 1, unit: unit).converted(to: .meters).value }
        XCTAssertEqual(meters(.miles), 1609.344)
        XCTAssertEqual(meters(.lightyears), 9_460_730_472_580_800)
        XCTAssertEqual(meters(.astronomicalUnits), 149_597_870_700)
        XCTAssertEqual(Measurement(value: 1, unit: UnitLength.miles).converted(to: .feet).value, 5280, accuracy: 1e-9)
        XCTAssertEqual(Measurement(value: 1, unit: UnitLength.parsecs).converted(to: .astronomicalUnits).value, 648_000 / .pi, accuracy: 1e-6)
    }
}
