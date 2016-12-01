// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// RUN: %target-run-simple-swift
// REQUIRES: executable_test
// REQUIRES: objc_interop

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#elseif DEPLOYMENT_RUNTIME_SWIFT
import SwiftFoundation
import SwiftXCTest
#endif


// We define our own units here so that we can have closer control over checking the behavior of just struct Measurement and not the rest of Foundation
class MyDimensionalUnit : Dimension {
    class var unitA : MyDimensionalUnit {
        return MyDimensionalUnit(symbol: "a", converter: UnitConverterLinear(coefficient: 1))
    }
    class var unitKiloA : MyDimensionalUnit {
        return MyDimensionalUnit(symbol: "ka", converter: UnitConverterLinear(coefficient: 1_000))
    }
    class var unitMegaA : MyDimensionalUnit {
        return MyDimensionalUnit(symbol: "Ma", converter: UnitConverterLinear(coefficient: 1_000_000))
    }
    override class func baseUnit() -> MyDimensionalUnit {
        return MyDimensionalUnit.unitA
    }
}

class BugUnit : Unit {
    override init() {
        super.init(symbol: "bug")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class TestMeasurement : XCTestCase {
    
    static var allTests: [(String, (TestMeasurement) -> () throws -> Void)] {
        return [
            ("testBasicConstruction", testBasicConstruction),
            ("testConversion", testConversion),
            ("testOperators", testOperators),
            ("testUnits", testUnits),
            ("testMeasurementFormatter", testMeasurementFormatter),
            ("testEquality", testEquality),
            ("testComparison", testComparison),
        ]
    }
    
    func testBasicConstruction() {
        let m1 = Measurement(value: 3, unit: MyDimensionalUnit.unitA)
        let m2 = Measurement(value: 3, unit: MyDimensionalUnit.unitA)
        
        let m3 = m1 + m2
        
        XCTAssertEqual(6, m3.value)
        XCTAssertEqual(m1, m2)
        
        let m10 = Measurement(value: 2, unit: BugUnit())
        let m11 = Measurement(value: 2, unit: BugUnit())
        let m12 = Measurement(value: 3, unit: BugUnit())
        
        XCTAssertEqual(m10, m11)
        XCTAssertNotEqual(m10, m12)
        
        // This test has 2 + 2 + 3 bugs
        XCTAssertEqual((m10 + m11 + m12).value, 7)
    }
    
    func testConversion() {
        let m1 = Measurement(value: 1000, unit: MyDimensionalUnit.unitA)
        let kiloM1 = Measurement(value: 1, unit: MyDimensionalUnit.unitKiloA)
        
        let result = m1.converted(to: MyDimensionalUnit.unitKiloA)
        XCTAssertEqual(kiloM1, result)
        
        let sameResult = m1.converted(to: MyDimensionalUnit.unitA)
        XCTAssertEqual(sameResult, m1)
        
        // This correctly fails to build
        
        // let m2 = Measurement(value: 1, unit: BugUnit())
        // m2.converted(to: MyDimensionalUnit.unitKiloA)
    }
    
    func testOperators() {
        // Which is bigger: 1 ka or 1 Ma?
        let oneKiloA = Measurement(value: 1, unit: MyDimensionalUnit.unitKiloA)
        let oneMegaA = Measurement(value: 1, unit: MyDimensionalUnit.unitMegaA)
        
        XCTAssertTrue(oneKiloA < oneMegaA)
        XCTAssertFalse(oneKiloA > oneMegaA)
        XCTAssertTrue(oneKiloA * 2000 > oneMegaA)
        XCTAssertTrue(oneMegaA / 1_000_000 < oneKiloA)
        XCTAssertTrue(2000 * oneKiloA > oneMegaA)
        XCTAssertTrue(2 / oneMegaA > oneMegaA)
        XCTAssertEqual(2 / (oneMegaA * 2), oneMegaA)
        XCTAssertTrue(oneMegaA <= oneKiloA * 1000)
        XCTAssertTrue(oneMegaA - oneKiloA <= oneKiloA * 1000)
        XCTAssertTrue(oneMegaA >= oneKiloA * 1000)
        XCTAssertTrue(oneMegaA >= ((oneKiloA * 1000) - oneKiloA))
        
        // Dynamically different dimensions
        XCTAssertEqual(Measurement(value: 1_001_000, unit: MyDimensionalUnit.unitA), oneMegaA + oneKiloA)
        
        var bugCount = Measurement(value: 1, unit: BugUnit())
        XCTAssertEqual(bugCount.value, 1)
        bugCount = bugCount + Measurement(value: 4, unit: BugUnit())
        XCTAssertEqual(bugCount.value, 5)
    }
    
    func testUnits() {
        XCTAssertEqual(MyDimensionalUnit.unitA, MyDimensionalUnit.unitA)
        XCTAssertTrue(MyDimensionalUnit.unitA == MyDimensionalUnit.unitA)
    }
    
    func testMeasurementFormatter() {
#if !DEPLOYMENT_RUNTIME_SWIFT // MeasurementFormatter is unimplemented
        let formatter = MeasurementFormatter()
        let measurement = Measurement(value: 100, unit: UnitLength.kilometers)
        let result = formatter.string(from: measurement)
        
        // Just make sure we get a result at all here
        XCTAssertFalse(result.isEmpty)
#endif
    }
    
    func testEquality() {
        let fiveKM = Measurement(value: 5, unit: UnitLength.kilometers)
        let fiveSeconds = Measurement(value: 5, unit: UnitDuration.seconds)
        let fiveThousandM = Measurement(value: 5000, unit: UnitLength.meters)
        
        XCTAssertTrue(fiveKM == fiveThousandM)
        XCTAssertEqual(fiveKM, fiveThousandM)
        XCTAssertFalse(fiveKM == fiveSeconds)
    }
    
    func testComparison() {
        let fiveKM = Measurement(value: 5, unit: UnitLength.kilometers)
        let fiveThousandM = Measurement(value: 5000, unit: UnitLength.meters)
        let sixKM = Measurement(value: 6, unit: UnitLength.kilometers)
        let sevenThousandM = Measurement(value: 7000, unit: UnitLength.meters)
        
        XCTAssertTrue(fiveKM < sixKM)
        XCTAssertTrue(fiveKM < sevenThousandM)
        XCTAssertTrue(fiveKM <= fiveThousandM)
    }
}

