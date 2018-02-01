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

class TestMassFormatter: XCTestCase {
    let formatter: MassFormatter = MassFormatter()
    
    static var allTests: [(String, (TestMassFormatter) -> () throws -> Void)] {
        return [
            ("test_stringFromKilogramsImperialRegion", test_stringFromKilogramsImperialRegion),
            ("test_stringFromKilogramsMetricRegion", test_stringFromKilogramsMetricRegion),
            ("test_stringFromKilogramsMetricRegionPersonMassUse", test_stringFromKilogramsMetricRegionPersonMassUse),
            ("test_stringFromValue", test_stringFromValue),
            ("test_unitStringFromKilograms", test_unitStringFromKilograms),
            ("test_unitStringFromValue", test_unitStringFromValue),
        ]
    }
    
    override func setUp() {
        formatter.numberFormatter.locale = Locale(identifier: "en_US")
        formatter.isForPersonMassUse = false
        super.setUp()
    }
    
    func test_stringFromKilogramsImperialRegion() {
        XCTAssertEqual(formatter.string(fromKilograms: -100), "-220.462 lb")
        XCTAssertEqual(formatter.string(fromKilograms: 0.00001), "0 oz")
        XCTAssertEqual(formatter.string(fromKilograms: 0.0001), "0.004 oz")
        XCTAssertEqual(formatter.string(fromKilograms: 1), "2.205 lb")
        XCTAssertEqual(formatter.string(fromKilograms: 100), "220.462 lb")
    }
    
    func test_stringFromKilogramsMetricRegion() {
        formatter.numberFormatter.locale = Locale(identifier: "de_DE")
        XCTAssertEqual(formatter.string(fromKilograms: -100), "-100 kg")
        XCTAssertEqual(formatter.string(fromKilograms: -1), "-1 kg")
        XCTAssertEqual(formatter.string(fromKilograms: 1000), "1.000 kg")
    }
    
    func test_stringFromKilogramsMetricRegionPersonMassUse() {
        formatter.numberFormatter.locale = Locale(identifier: "en_GB")
        formatter.isForPersonMassUse = true
        XCTAssertEqual(formatter.string(fromKilograms: -100), "-100 kg")
        XCTAssertEqual(formatter.string(fromKilograms: -1), "-1 kg")
        XCTAssertEqual(formatter.string(fromKilograms: 1000), "1,000 kg")
    }
    
    func test_stringFromValue() {
        formatter.unitStyle = Formatter.UnitStyle.long
        XCTAssertEqual(formatter.string(fromValue: 0.002, unit: MassFormatter.Unit.kilogram),"0.002 kilograms")
        XCTAssertEqual(formatter.string(fromValue: 0, unit:MassFormatter.Unit.stone), "0 stones")
        XCTAssertEqual(formatter.string(fromValue: 1, unit:MassFormatter.Unit.stone), "1 stone")
        XCTAssertEqual(formatter.string(fromValue: 2.4, unit: MassFormatter.Unit.stone), "2 stones, 5.6 pounds")
        
        formatter.unitStyle = Formatter.UnitStyle.short
        XCTAssertEqual(formatter.string(fromValue: 0.00000001, unit:MassFormatter.Unit.kilogram), "0kg")
        XCTAssertEqual(formatter.string(fromValue: 6, unit:MassFormatter.Unit.pound), "6#")
        XCTAssertEqual(formatter.string(fromValue: 2.4, unit: MassFormatter.Unit.stone), "2st 5.6#")
        XCTAssertEqual(formatter.string(fromValue: 123456, unit: MassFormatter.Unit.stone), "123,456st")
        
        formatter.unitStyle = Formatter.UnitStyle.medium
        XCTAssertEqual(formatter.string(fromValue: 0.00000001, unit:MassFormatter.Unit.kilogram), "0 kg")
        XCTAssertEqual(formatter.string(fromValue: 2.4, unit: MassFormatter.Unit.stone), "2 st, 5.6 lb")
        XCTAssertEqual(formatter.string(fromValue: 2.0, unit: MassFormatter.Unit.stone), "2 st")
        XCTAssertEqual(formatter.string(fromValue: 123456.78, unit: MassFormatter.Unit.stone), "123,456 st, 10.92 lb")
    }
    
	func test_unitStringFromKilograms() {
        var unit = MassFormatter.Unit.kilogram
        
        // imperial
        XCTAssertEqual(formatter.unitString(fromKilograms: -100000, usedUnit: &unit), "lb")
        XCTAssertEqual(unit, MassFormatter.Unit.pound)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0, usedUnit: &unit), "lb")
        XCTAssertEqual(unit, MassFormatter.Unit.pound)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0.0001, usedUnit: &unit), "oz")
        XCTAssertEqual(unit, MassFormatter.Unit.ounce)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0.4535, usedUnit: &unit), "oz")
        XCTAssertEqual(unit, MassFormatter.Unit.ounce)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0.4536, usedUnit: &unit), "lb")
        XCTAssertEqual(unit, MassFormatter.Unit.pound)
        
        // metric
        formatter.numberFormatter.locale = Locale(identifier: "de_DE")
        XCTAssertEqual(formatter.unitString(fromKilograms: -100000, usedUnit: &unit), "kg")
        XCTAssertEqual(unit, MassFormatter.Unit.kilogram)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0, usedUnit: &unit), "kg")
        XCTAssertEqual(unit, MassFormatter.Unit.kilogram)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0.0001, usedUnit: &unit), "g")
        XCTAssertEqual(unit, MassFormatter.Unit.gram)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 1.000, usedUnit: &unit), "g")
        XCTAssertEqual(unit, MassFormatter.Unit.gram)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 1.001, usedUnit: &unit), "kg")
        XCTAssertEqual(unit, MassFormatter.Unit.kilogram)
    }
    
    func test_unitStringFromValue() {
        formatter.unitStyle = Formatter.UnitStyle.long
        XCTAssertEqual(formatter.unitString(fromValue: 0.002, unit: MassFormatter.Unit.kilogram), "kilograms")
        XCTAssertEqual(formatter.unitString(fromValue: 0.100, unit: MassFormatter.Unit.gram), "grams")
        XCTAssertEqual(formatter.unitString(fromValue: 2.000, unit: MassFormatter.Unit.pound), "pounds")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: MassFormatter.Unit.ounce), "ounces")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: MassFormatter.Unit.stone), "stone")
        
        formatter.unitStyle = Formatter.UnitStyle.medium
        XCTAssertEqual(formatter.unitString(fromValue: 0.002, unit: MassFormatter.Unit.kilogram), "kg")
        XCTAssertEqual(formatter.unitString(fromValue: 0.100, unit: MassFormatter.Unit.gram), "g")
        XCTAssertEqual(formatter.unitString(fromValue: 2.000, unit: MassFormatter.Unit.pound), "lb")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: MassFormatter.Unit.ounce), "oz")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: MassFormatter.Unit.stone), "st")
        
        formatter.unitStyle = Formatter.UnitStyle.short
        XCTAssertEqual(formatter.unitString(fromValue: 0.002, unit: MassFormatter.Unit.kilogram), "kg")
        XCTAssertEqual(formatter.unitString(fromValue: 0.100, unit: MassFormatter.Unit.gram), "g")
        XCTAssertEqual(formatter.unitString(fromValue: 2.000, unit: MassFormatter.Unit.pound), "lb")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: MassFormatter.Unit.ounce), "oz")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: MassFormatter.Unit.stone), "st")
    }
}
