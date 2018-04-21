// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

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
        formatter.unitStyle = .long
        XCTAssertEqual(formatter.string(fromValue: 0.002, unit: .kilojoule),"0.002 kilojoules")
        XCTAssertEqual(formatter.string(fromValue:0, unit: .joule), "0 joules")
        XCTAssertEqual(formatter.string(fromValue:1, unit: .joule), "1 joule")
        
        formatter.unitStyle = .short
        XCTAssertEqual(formatter.string(fromValue: 0.00000001, unit: .kilocalorie), "0kcal")
        XCTAssertEqual(formatter.string(fromValue: 2.4, unit: .calorie), "2.4cal")
        XCTAssertEqual(formatter.string(fromValue: 123456, unit: .calorie), "123,456cal")
        
        formatter.unitStyle = .medium
        formatter.isForFoodEnergyUse = true
        XCTAssertEqual(formatter.string(fromValue: 0.00000001, unit: .calorie), "0 cal")
        XCTAssertEqual(formatter.string(fromValue: 987654321, unit: .kilocalorie), "987,654,321 Cal")
        
        formatter.isForFoodEnergyUse = false
        XCTAssertEqual(formatter.string(fromValue: 5.3, unit: .kilocalorie), "5.3 kcal")
        XCTAssertEqual(formatter.string(fromValue: 873.2345, unit: .calorie), "873.234 cal")
    }
    
    func test_unitStringFromJoules() {
        var unit = EnergyFormatter.Unit.joule
        XCTAssertEqual(formatter.unitString(fromJoules: -100000, usedUnit: &unit), "kcal")
        XCTAssertEqual(unit, .kilocalorie)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 0, usedUnit: &unit), "kcal")
        XCTAssertEqual(unit, .kilocalorie)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 0.0001, usedUnit: &unit), "cal")
        XCTAssertEqual(unit, .calorie)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 4184, usedUnit: &unit), "cal")
        XCTAssertEqual(unit, .calorie)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 4185, usedUnit: &unit), "kcal")
        XCTAssertEqual(unit, .kilocalorie)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 100000, usedUnit: &unit), "kcal")
        XCTAssertEqual(unit, .kilocalorie)
        
        formatter.numberFormatter.locale = Locale(identifier: "de_DE")
        XCTAssertEqual(formatter.unitString(fromJoules: -100000, usedUnit: &unit), "kJ")
        XCTAssertEqual(unit, .kilojoule)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 0, usedUnit: &unit), "kJ")
        XCTAssertEqual(unit, .kilojoule)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 0.0001, usedUnit: &unit), "J")
        XCTAssertEqual(unit, .joule)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 1000, usedUnit: &unit), "J")
        XCTAssertEqual(unit, .joule)
        
        XCTAssertEqual(formatter.unitString(fromJoules: 1000.01, usedUnit: &unit), "kJ")
        XCTAssertEqual(unit, .kilojoule)
    }
    
    func test_unitStringFromValue() {
        formatter.isForFoodEnergyUse = true
        formatter.unitStyle = .long
        XCTAssertEqual(formatter.unitString(fromValue: 1, unit: .kilocalorie), "Calories")
        XCTAssertEqual(formatter.unitString(fromValue: 2, unit: .kilocalorie), "Calories")
        
        formatter.unitStyle = .medium
        XCTAssertEqual(formatter.unitString(fromValue: 0.00000001, unit: .kilocalorie), "Cal")
        XCTAssertEqual(formatter.unitString(fromValue: 987654321, unit: .kilocalorie), "Cal")
        
        formatter.unitStyle = .short
        XCTAssertEqual(formatter.unitString(fromValue: 0.00000001, unit: .calorie), "cal")
        XCTAssertEqual(formatter.unitString(fromValue: 123456, unit: .kilocalorie), "C")
        
        formatter.isForFoodEnergyUse = false
        formatter.unitStyle = .long
        XCTAssertEqual(formatter.unitString(fromValue: 0.002, unit: .kilojoule), "kilojoules")
        
        formatter.unitStyle = .medium
        XCTAssertEqual(formatter.unitString(fromValue: 0.00000001, unit: .kilocalorie), "kcal")
        XCTAssertEqual(formatter.unitString(fromValue: 987654321, unit: .kilocalorie), "kcal")
        
        formatter.unitStyle = .short
        XCTAssertEqual(formatter.unitString(fromValue: 0.00000001, unit: .calorie), "cal")
        XCTAssertEqual(formatter.unitString(fromValue: 123456, unit: .joule), "J")
    }

}
