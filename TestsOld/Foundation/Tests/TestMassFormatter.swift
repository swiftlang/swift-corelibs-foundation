// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

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
        formatter.unitStyle = .long
        XCTAssertEqual(formatter.string(fromValue: 0.002, unit: .kilogram),"0.002 kilograms")
        XCTAssertEqual(formatter.string(fromValue: 0, unit: .stone), "0 stones")
        XCTAssertEqual(formatter.string(fromValue: 1, unit: .stone), "1 stone")
        XCTAssertEqual(formatter.string(fromValue: 2.4, unit: .stone), "2 stones, 5.6 pounds")
        
        formatter.unitStyle = .short
        XCTAssertEqual(formatter.string(fromValue: 0.00000001, unit: .kilogram), "0kg")
        XCTAssertEqual(formatter.string(fromValue: 6, unit: .pound), "6#")
        XCTAssertEqual(formatter.string(fromValue: 2.4, unit: .stone), "2st 5.6#")
        XCTAssertEqual(formatter.string(fromValue: 123456, unit: .stone), "123,456st")
        
        formatter.unitStyle = .medium
        XCTAssertEqual(formatter.string(fromValue: 0.00000001, unit: .kilogram), "0 kg")
        XCTAssertEqual(formatter.string(fromValue: 2.4, unit: .stone), "2 st, 5.6 lb")
        XCTAssertEqual(formatter.string(fromValue: 2.0, unit: .stone), "2 st")
        XCTAssertEqual(formatter.string(fromValue: 123456.78, unit: .stone), "123,456 st, 10.92 lb")
    }
    
	func test_unitStringFromKilograms() {
        var unit = MassFormatter.Unit.kilogram
        
        // imperial
        XCTAssertEqual(formatter.unitString(fromKilograms: -100000, usedUnit: &unit), "lb")
        XCTAssertEqual(unit, .pound)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0, usedUnit: &unit), "lb")
        XCTAssertEqual(unit, .pound)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0.0001, usedUnit: &unit), "oz")
        XCTAssertEqual(unit, .ounce)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0.4535, usedUnit: &unit), "oz")
        XCTAssertEqual(unit, .ounce)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0.4536, usedUnit: &unit), "lb")
        XCTAssertEqual(unit, .pound)
        
        // metric
        formatter.numberFormatter.locale = Locale(identifier: "de_DE")
        XCTAssertEqual(formatter.unitString(fromKilograms: -100000, usedUnit: &unit), "kg")
        XCTAssertEqual(unit, .kilogram)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0, usedUnit: &unit), "kg")
        XCTAssertEqual(unit, .kilogram)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 0.0001, usedUnit: &unit), "g")
        XCTAssertEqual(unit, .gram)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 1.000, usedUnit: &unit), "g")
        XCTAssertEqual(unit, .gram)
        
        XCTAssertEqual(formatter.unitString(fromKilograms: 1.001, usedUnit: &unit), "kg")
        XCTAssertEqual(unit, .kilogram)
    }
    
    func test_unitStringFromValue() {
        formatter.unitStyle = .long
        XCTAssertEqual(formatter.unitString(fromValue: 0.002, unit: .kilogram), "kilograms")
        XCTAssertEqual(formatter.unitString(fromValue: 0.100, unit: .gram), "grams")
        XCTAssertEqual(formatter.unitString(fromValue: 2.000, unit: .pound), "pounds")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: .ounce), "ounces")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: .stone), "stone")
        
        formatter.unitStyle = .medium
        XCTAssertEqual(formatter.unitString(fromValue: 0.002, unit: .kilogram), "kg")
        XCTAssertEqual(formatter.unitString(fromValue: 0.100, unit: .gram), "g")
        XCTAssertEqual(formatter.unitString(fromValue: 2.000, unit: .pound), "lb")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: .ounce), "oz")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: .stone), "st")
        
        formatter.unitStyle = .short
        XCTAssertEqual(formatter.unitString(fromValue: 0.002, unit: .kilogram), "kg")
        XCTAssertEqual(formatter.unitString(fromValue: 0.100, unit: .gram), "g")
        XCTAssertEqual(formatter.unitString(fromValue: 2.000, unit: .pound), "lb")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: .ounce), "oz")
        XCTAssertEqual(formatter.unitString(fromValue: 2.002, unit: .stone), "st")
    }
}
