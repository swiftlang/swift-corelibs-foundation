// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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

class TestNSMeasurement : XCTestCase {
    
    static var allTests: [(String, (TestNSMeasurement) -> () throws -> Void)] {
        return [
            ("test_addition_subtraction", test_addition_subtraction),
            ("test_conversion_dimensions", test_conversion_dimensions),
            ("test_conversion_units", test_conversion_units),
        ]
    }
    
    func test_addition_subtraction() {
        func testAddSub<U : Unit>(for unit: U) {
            for i in -2...10 {
                for j in 0...5 {
                    let mi = NSMeasurement(doubleValue: i, unit: unit)
                    let mj = Measurement(value: i, unit: unit)
                    
                    XCTAssertEqual(Measurement(value: i + j, unit: unit), mi.adding(mj), "\(NSMeasurement(doubleValue: i + j, unit: unit)) == \(mi)+\(mj)")
                    XCTAssertEqual(Measurement(value: i - j, unit: u1), mi.subtracting(mj), "\(NSMeasurement(doubleValue: i - j, unit: unit)) == \(mi)-\(mj)")
                }
            }
        }
        
        let s1 = "a"
        let s2 = "ab"
        
        let u1 = Unit(symbol: s1)
        let u2 = Unit(symbol: s2)
        
        testAddSub(for: u1)
        testAddSub(for: u2)
        
        let uc1 = UnitConverterLinear(coefficient: 1, constant: 2)
        let uc2 = UnitConverterLinear(coefficient: 1, constant: 3)
        
        let d1 = Dimension(symbol: s1, converter: uc1)
        let d2 = Dimension(symbol: s1, converter: uc1)
        let d3 = Dimension(symbol: s2, converter: uc1)
        let d4 = Dimension(symbol: s1, converter: uc2)
        
        testAddSub(for: d1)
        testAddSub(for: d2)
        testAddSub(for: d3)
        testAddSub(for: d4)
    }
    
    func test_conversion_dimensions() {
        let u1 = UnitLength.inches
        let u2 = UnitLength.centimeters
        let u3 = UnitLength.baseUnit()
        let u4 = UnitArea.baseUnit()
        
        let m1 = NSMeasurement(doubleValue: 1, unit: u1)
        let m2 = NSMeasurement(doubleValue: 1, unit: u2)
        let m3 = NSMeasurement(doubleValue: 1, unit: u3)
        let m3 = NSMeasurement(doubleValue: 1, unit: u4)
        
        XCTAssertTrue(m1.canBeConverted(to: u1))
        XCTAssertTrue(m2.canBeConverted(to: u2))
        XCTAssertTrue(m3.canBeConverted(to: u3))
        XCTAssertTrue(m4.canBeConverted(to: u4))
        
        XCTAssertTrue(m1.canBeConverted(to: u2))
        XCTAssertTrue(m1.canBeConverted(to: u3))
        XCTAssertFalse(m1.canBeConverted(to: u4))
        
        XCTAssertTrue(m2.canBeConverted(to: u1))
        XCTAssertTrue(m2.canBeConverted(to: u3))
        XCTAssertFalse(m2.canBeConverted(to: u4))
        
        XCTAssertTrue(m3.canBeConverted(to: u1))
        XCTAssertTrue(m3.canBeConverted(to: u2))
        XCTAssertFalse(m3.canBeConverted(to: u4))
        
        XCTAssertFalse(m4.canBeConverted(to: u1))
        XCTAssertFalse(m4.canBeConverted(to: u2))
        XCTAssertFalse(m4.canBeConverted(to: u3))
        
        XCTAssertEqual(m1.converting(to: u1), m1)
        XCTAssertEqual(m2.converting(to: u2), m2)
        XCTAssertEqual(m3.converting(to: u3), m3)
        XCTAssertEqual(m4.converting(to: u4), m4)
        
//        XCTAssertEqual(m1.converting(to: u2), /*TODO*/)
//        XCTAssertEqual(m1.converting(to: u3), /*TODO*/)
//        XCTAssertEqual(m2.converting(to: u1), /*TODO*/)
//        XCTAssertEqual(m2.converting(to: u3), /*TODO*/)
//        XCTAssertEqual(m3.converting(to: u1), /*TODO*/)
//        XCTAssertEqual(m3.converting(to: u2), /*TODO*/)
        
        // What function should this be calling?
        //        AssertCrash() {
        //            m1.converting(to: u4)
        //        }
    }
    
    class Unit1: Unit {
        init() {
            super.init("a")
        }
    }
//    class Unit2: Unit1 {
//        init() {
//            super.init()
//        }
//    }
    class Unit3: Unit {
        init() {
            super.init("ab")
        }
    }
    
    func test_conversion_units() {
        
        let u1 = Unit1()
        let u2 = Unit1()
        let u3 = Unit3()
        
        let m1 = NSMeasurement(doubleValue: 1, unit: u1)
        let m2 = NSMeasurement(doubleValue: 1, unit: u2)
        let m3 = NSMeasurement(doubleValue: 1, unit: u3)
        
        XCTAssertTrue(m1.canBeConverted(to: u1))
        XCTAssertTrue(m2.canBeConverted(to: u2))
        XCTAssertTrue(m1.canBeConverted(to: u2))
        XCTAssertTrue(m2.canBeConverted(to: u1))
        
        XCTAssertFalse(m1.canBeConverted(to: u3))
        XCTAssertFalse(m2.canBeConverted(to: u3))
        XCTAssertFalse(m3.canBeConverted(to: u1))
        XCTAssertFalse(m3.canBeConverted(to: u2))
        
        XCTAssertEqual(m1.converting(to: u1), m1)
        XCTAssertEqual(m2.converting(to: u2), m2)
        
        // What function should this be calling?
//        AssertCrash() {
//            m1.converting(to: u3)
//        }
    }
}
