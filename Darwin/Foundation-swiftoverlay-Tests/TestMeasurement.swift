//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest

// We define our own units here so that we can have closer control over checking the behavior of just struct Measurement and not the rest of Foundation
@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
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
    override class func baseUnit() -> Self {
        return MyDimensionalUnit.unitA as! Self
    }
}

@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
class CustomUnit : Unit {
    override init(symbol: String) {
        super.init(symbol: symbol)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public static let bugs = CustomUnit(symbol: "bug")
    public static let features = CustomUnit(symbol: "feature")
}

@available(OSX 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
class TestMeasurement : XCTestCase {
    
    func testBasicConstruction() {
        let m1 = Measurement(value: 3, unit: MyDimensionalUnit.unitA)
        let m2 = Measurement(value: 3, unit: MyDimensionalUnit.unitA)
        
        let m3 = m1 + m2
        
        XCTAssertEqual(6, m3.value)
        XCTAssertEqual(m1, m2)
        
        let m10 = Measurement(value: 2, unit: CustomUnit.bugs)
        let m11 = Measurement(value: 2, unit: CustomUnit.bugs)
        let m12 = Measurement(value: 3, unit: CustomUnit.bugs)
        
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
        
        // let m2 = Measurement(value: 1, unit: CustomUnit.bugs)
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
        
        var bugCount = Measurement(value: 1, unit: CustomUnit.bugs)
        XCTAssertEqual(bugCount.value, 1)
        bugCount = bugCount + Measurement(value: 4, unit: CustomUnit.bugs)
        XCTAssertEqual(bugCount.value, 5)
    }
    
    func testUnits() {
        XCTAssertEqual(MyDimensionalUnit.unitA, MyDimensionalUnit.unitA)
        XCTAssertTrue(MyDimensionalUnit.unitA == MyDimensionalUnit.unitA)
    }
    
    func testMeasurementFormatter() {
        let formatter = MeasurementFormatter()
        let measurement = Measurement(value: 100, unit: UnitLength.kilometers)
        let result = formatter.string(from: measurement)
        
        // Just make sure we get a result at all here
        XCTAssertFalse(result.isEmpty)
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

    func testHashing() {
        guard #available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *) else { return }
        let lengths: [[Measurement<UnitLength>]] = [
            [
                Measurement(value: 5, unit: UnitLength.kilometers),
                Measurement(value: 5000, unit: UnitLength.meters),
                Measurement(value: 5000, unit: UnitLength.meters),
            ],
            [
                Measurement(value: 1, unit: UnitLength.kilometers),
                Measurement(value: 1000, unit: UnitLength.meters),
            ],
            [
                Measurement(value: 1, unit: UnitLength.meters),
                Measurement(value: 1000, unit: UnitLength.millimeters),
            ],
        ]
        checkHashableGroups(lengths)

        let durations: [[Measurement<UnitDuration>]] = [
            [
                Measurement(value: 3600, unit: UnitDuration.seconds),
                Measurement(value: 60, unit: UnitDuration.minutes),
                Measurement(value: 1, unit: UnitDuration.hours),
            ],
            [
                Measurement(value: 1800, unit: UnitDuration.seconds),
                Measurement(value: 30, unit: UnitDuration.minutes),
                Measurement(value: 0.5, unit: UnitDuration.hours),
            ]
        ]
        checkHashableGroups(durations)

        let custom: [Measurement<CustomUnit>] = [
            Measurement(value: 1, unit: CustomUnit.bugs),
            Measurement(value: 2, unit: CustomUnit.bugs),
            Measurement(value: 3, unit: CustomUnit.bugs),
            Measurement(value: 4, unit: CustomUnit.bugs),
            Measurement(value: 1, unit: CustomUnit.features),
            Measurement(value: 2, unit: CustomUnit.features),
            Measurement(value: 3, unit: CustomUnit.features),
            Measurement(value: 4, unit: CustomUnit.features),
        ]
        checkHashable(custom, equalityOracle: { $0 == $1 })
    }

    func test_AnyHashableContainingMeasurement() {
        let values: [Measurement<UnitLength>] = [
          Measurement(value: 100, unit: UnitLength.meters),
          Measurement(value: 100, unit: UnitLength.kilometers),
          Measurement(value: 100, unit: UnitLength.kilometers),
        ]
        let anyHashables = values.map(AnyHashable.init)
        expectEqual(Measurement<UnitLength>.self, type(of: anyHashables[0].base))
        expectEqual(Measurement<UnitLength>.self, type(of: anyHashables[1].base))
        expectEqual(Measurement<UnitLength>.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }

    func test_AnyHashableCreatedFromNSMeasurement() {
        let values: [NSMeasurement] = [
            NSMeasurement(doubleValue: 100, unit: UnitLength.meters),
            NSMeasurement(doubleValue: 100, unit: UnitLength.kilometers),
            NSMeasurement(doubleValue: 100, unit: UnitLength.kilometers),
        ]
        let anyHashables = values.map(AnyHashable.init)
        expectEqual(Measurement<Unit>.self, type(of: anyHashables[0].base))
        expectEqual(Measurement<Unit>.self, type(of: anyHashables[1].base))
        expectEqual(Measurement<Unit>.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}
