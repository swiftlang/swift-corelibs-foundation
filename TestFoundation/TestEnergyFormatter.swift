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

class TestEnergyFormatter: XCTestCase {
    let formatter: EnergyFormatter = EnergyFormatter()
    
    static var allTests: [(String, (TestEnergyFormatter) -> () throws -> Void)] {
        return [
            ("test_stringFromJoulesJoulesRegion", test_stringFromJoulesJoulesRegion),
            ("test_stringFromJoulesCaloriesRegion", test_stringFromJoulesCaloriesRegion),
            ("test_stringFromJoulesCaloriesRegionFoodEnergyUse", test_stringFromJoulesCaloriesRegionFoodEnergyUse),
            ("test_stringFromValue", test_stringFromValue),
            ("test_unitStringFromValue", test_unitStringFromValue),
            ("test_unitStringFromJoules", test_unitStringFromJoules)
        ]
    }
    
    override func setUp() {
        formatter.numberFormatter.locale = Locale(identifier: "en_US")
        formatter.isForFoodEnergyUse = false
        super.setUp()
    }

    func test_stringFromJoulesJoulesRegion() {
        formatter.numberFormatter.locale = Locale(identifier: "de_DE")
        XCTAssertEqual(formatter.string(fromJoules: -100000), "-100 kJ")
        XCTAssertEqual(formatter.string(fromJoules: -1), "-0,001 kJ")
        XCTAssertEqual(formatter.string(fromJoules: 100000000), "100.000 kJ")
    }
    
    
    func test_stringFromJoulesCaloriesRegion() {
        XCTAssertEqual(formatter.string(fromJoules: -10000), "-2.39 kcal")
        XCTAssertEqual(formatter.string(fromJoules: 0.00001), "0 cal")
        XCTAssertEqual(formatter.string(fromJoules: 0.0001), "0 cal")
        XCTAssertEqual(formatter.string(fromJoules: 1), "0.239 cal")
        XCTAssertEqual(formatter.string(fromJoules: 10000), "2.39 kcal")
    }
    
    func test_stringFromJoulesCaloriesRegionFoodEnergyUse() {
        formatter.isForFoodEnergyUse = true
        XCTAssertEqual(formatter.string(fromJoules: -1), "-0 Cal")
        XCTAssertEqual(formatter.string(fromJoules: 0.001), "0 cal")
        XCTAssertEqual(formatter.string(fromJoules: 0.1), "0.024 cal")
        XCTAssertEqual(formatter.string(fromJoules: 1), "0.239 cal")
        XCTAssertEqual(formatter.string(fromJoules: 10000), "2.39 Cal")
    }
    
    func test_stringFromValue() {
        formatter.unitStyle = Formatter.UnitStyle.long
        XCTAssertEqual(formatter.string(fromValue: 0.002, unit: EnergyFormatter.Unit.kilojoule),"0.002 kilojoules")
        XCTAssertEqual(formatter.string(fromValue:0, unit:EnergyFormatter.Unit.joule), "0 joules")
        XCTAssertEqual(formatter.string(fromValue:1, unit:EnergyFormatter.Unit.joule), "1 joule")
        
        formatter.unitStyle = Formatter.UnitStyle.short
        XCTAssertEqual(formatter.string(fromValue: 0.00000001, unit:EnergyFormatter.Unit.kilocalorie), "0kcal")
        XCTAssertEqual(formatter.string(fromValue: 2.4, unit: EnergyFormatter.Unit.calorie), "2.4cal")
        XCTAssertEqual(formatter.string(fromValue: 123456, unit: EnergyFormatter.Unit.calorie), "123,456cal")
        
        formatter.unitStyle = Formatter.UnitStyle.medium
        formatter.isForFoodEnergyUse = true
        XCTAssertEqual(formatter.string(fromValue: 0.00000001, unit: EnergyFormatter.Unit.calorie), "0 cal")
        XCTAssertEqual(formatter.string(fromValue: 987654321, unit: EnergyFormatter.Unit.kilocalorie), "987,654,321 Cal")
        
        formatter.isForFoodEnergyUse = false
        XCTAssertEqual(formatter.string(fromValue: 5.3, unit: EnergyFormatter.Unit.kilocalorie), "5.3 kcal")
        XCTAssertEqual(formatter.string(fromValue: 873.2345, unit: EnergyFormatter.Unit.calorie), "873.234 cal")
    }
    
    func test_unitStringFromJoules() {
        var unit = EnergyFormatter.Unit.joule
        XCTAssertEqual(formatter.unitString(fromJoules: -100000, usedUnit: &unit), "kcal")
        XCTAssertEqual(unit, EnergyFormatter.Unit.kilocalorie)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 0, usedUnit: &unit), "kcal")
        XCTAssertEqual(unit, EnergyFormatter.Unit.kilocalorie)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 0.0001, usedUnit: &unit), "cal")
        XCTAssertEqual(unit, EnergyFormatter.Unit.calorie)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 4184, usedUnit: &unit), "cal")
        XCTAssertEqual(unit, EnergyFormatter.Unit.calorie)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 4185, usedUnit: &unit), "kcal")
        XCTAssertEqual(unit, EnergyFormatter.Unit.kilocalorie)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 100000, usedUnit: &unit), "kcal")
        XCTAssertEqual(unit, EnergyFormatter.Unit.kilocalorie)
        
        formatter.numberFormatter.locale = Locale(identifier: "de_DE")
        XCTAssertEqual(formatter.unitString(fromJoules: -100000, usedUnit: &unit), "kJ")
        XCTAssertEqual(unit, EnergyFormatter.Unit.kilojoule)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 0, usedUnit: &unit), "kJ")
        XCTAssertEqual(unit, EnergyFormatter.Unit.kilojoule)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 0.0001, usedUnit: &unit), "J")
        XCTAssertEqual(unit, EnergyFormatter.Unit.joule)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 1000, usedUnit: &unit), "J")
        XCTAssertEqual(unit, EnergyFormatter.Unit.joule)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 1000.01, usedUnit: &unit), "kJ")
        XCTAssertEqual(unit, EnergyFormatter.Unit.kilojoule)
    }
    
    func test_unitStringFromValue() {
        formatter.isForFoodEnergyUse = true
        formatter.unitStyle = Formatter.UnitStyle.long
        XCTAssertEqual(formatter.unitString(fromValue: 1, unit: EnergyFormatter.Unit.kilocalorie), "Calories")
        XCTAssertEqual(formatter.unitString(fromValue: 2, unit: EnergyFormatter.Unit.kilocalorie), "Calories")
        
        formatter.unitStyle = Formatter.UnitStyle.medium
        XCTAssertEqual(formatter.unitString(fromValue: 0.00000001, unit: EnergyFormatter.Unit.kilocalorie), "Cal")
        XCTAssertEqual(formatter.unitString(fromValue: 987654321, unit: EnergyFormatter.Unit.kilocalorie), "Cal")
        
        formatter.unitStyle = Formatter.UnitStyle.short
        XCTAssertEqual(formatter.unitString(fromValue: 0.00000001, unit: EnergyFormatter.Unit.calorie), "cal")
        XCTAssertEqual(formatter.unitString(fromValue: 123456, unit: EnergyFormatter.Unit.kilocalorie), "C")
        
        formatter.isForFoodEnergyUse = false
        formatter.unitStyle = Formatter.UnitStyle.long
        XCTAssertEqual(formatter.unitString(fromValue: 0.002, unit: EnergyFormatter.Unit.kilojoule), "kilojoules")
        
        formatter.unitStyle = Formatter.UnitStyle.medium
        XCTAssertEqual(formatter.unitString(fromValue: 0.00000001, unit: EnergyFormatter.Unit.kilocalorie), "kcal")
        XCTAssertEqual(formatter.unitString(fromValue: 987654321, unit: EnergyFormatter.Unit.kilocalorie), "kcal")
        
        formatter.unitStyle = Formatter.UnitStyle.short
        XCTAssertEqual(formatter.unitString(fromValue: 0.00000001, unit: EnergyFormatter.Unit.calorie), "cal")
        XCTAssertEqual(formatter.unitString(fromValue: 123456, unit: EnergyFormatter.Unit.joule), "J")
    }

}
