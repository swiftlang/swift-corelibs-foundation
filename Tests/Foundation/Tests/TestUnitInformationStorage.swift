// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestUnitInformationStorage: XCTestCase {
    func testUnitInformationStorage() {
        let bits = Measurement(value: 8, unit: UnitInformationStorage.bits)
        XCTAssertEqual(
            bits.converted(to: .bytes).value,
            1,
            "Conversion from bits to bytes"
        )
        XCTAssertEqual(
            bits.converted(to: .nibbles).value,
            2,
            "Conversion from bits to nibbles"
        )
        XCTAssertEqual(
            bits.converted(to: .yottabits).value,
            8.0e-24,
            accuracy: 1.0e-27,
            "Conversion from bits to yottabits"
        )
        XCTAssertEqual(
            bits.converted(to: .gibibits).value,
            7.450581e-09,
            accuracy: 1.0e-12,
            "Conversion from bits to gibibits"
        )
    }

    static let allTests = [
        ("testUnitInformationStorage", testUnitInformationStorage),
    ]
}
