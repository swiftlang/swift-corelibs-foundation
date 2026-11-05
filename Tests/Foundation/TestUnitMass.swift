// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestUnitMass: XCTestCase {
    func testStonesConversions() {
        let stone = Measurement(value: 1, unit: UnitMass.stones)
        XCTAssertEqual(stone.converted(to: .kilograms).value, 6.35029)
        XCTAssertEqual(stone.converted(to: .pounds).value, 14, accuracy: 0.001)
        XCTAssertEqual(Measurement(value: 6.35029, unit: UnitMass.kilograms).converted(to: .stones).value, 1, accuracy: 1e-12)
    }
}
