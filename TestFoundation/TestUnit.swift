// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

class TestUnit: XCTestCase {

    static var allTests: [(String, (TestUnit) -> () throws -> Void)] {
        return [
            ("test_equality", test_equality),
        ]
    }

    func test_equality() {
        let s1 = "a"
        let s2 = "ab"

        let u1 = Unit(symbol: s1)
        let u2 = Unit(symbol: s1)
        let u3 = Unit(symbol: s2)

        XCTAssertEqual(u1, u2)
        XCTAssertEqual(u2, u1)
        XCTAssertNotEqual(u1, u3)
        XCTAssertNotEqual(u3, u1)

        let uc1 = UnitConverterLinear(coefficient: 1, constant: 2)
        let uc2 = UnitConverterLinear(coefficient: 1, constant: 3)

        let d1 = Dimension(symbol: s1, converter: uc1)
        let d2 = Dimension(symbol: s1, converter: uc1)
        let d3 = Dimension(symbol: s2, converter: uc1)
        let d4 = Dimension(symbol: s1, converter: uc2)

        XCTAssertEqual(d1, d2)
        XCTAssertEqual(d2, d1)
        XCTAssertNotEqual(d1, d3)
        XCTAssertNotEqual(d3, d1)
        XCTAssertNotEqual(d1, d4)
        XCTAssertNotEqual(d4, d1)

        XCTAssertEqual(u1, d1)
        XCTAssertNotEqual(d1, u1)
    }

}
