// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestUnitArea: XCTestCase {
    func testImperialAreaConversions() {
        func convert(_ from: UnitArea, _ to: UnitArea) -> Double { Measurement(value: 1, unit: from).converted(to: to).value }
        XCTAssertEqual(convert(.squareFeet, .squareMeters), 0.09290304)
        XCTAssertEqual(convert(.squareYards, .squareMeters), 0.83612736)
        XCTAssertEqual(convert(.acres, .squareFeet), 43_560, accuracy: 1e-6)
        XCTAssertEqual(convert(.squareMiles, .acres), 640, accuracy: 1e-9)
    }
}
