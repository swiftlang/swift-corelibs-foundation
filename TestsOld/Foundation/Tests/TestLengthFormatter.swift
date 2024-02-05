// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestLengthFormatter: XCTestCase {
    let formatter: LengthFormatter = LengthFormatter()
    
    static var allTests: [(String, (TestLengthFormatter) -> () throws -> Void)] {
        return [
            ("test_stringFromMetersUS", test_stringFromMetersUS),
            ("test_stringFromMetersUSPersonHeight", test_stringFromMetersUSPersonHeight),
            ("test_stringFromMetersMetric", test_stringFromMetersMetric),
            ("test_stringFromMetersMetricPersonHeight", test_stringFromMetersMetricPersonHeight),
            ("test_stringFromValue", test_stringFromValue),
            ("test_unitStringFromMeters", test_unitStringFromMeters),
            ("test_unitStringFromValue", test_unitStringFromValue)
        ]
    }

    override func setUp() {
        formatter.numberFormatter.locale = Locale(identifier: "en_US")
        formatter.isForPersonHeightUse = false
        super.setUp()
    }
    
    func test_stringFromMetersUS() {
        XCTAssertEqual(formatter.string(fromMeters:-100000), "-62.137 mi")
        XCTAssertEqual(formatter.string(fromMeters: -1), "-0.001 mi")
        XCTAssertEqual(formatter.string(fromMeters: 0.00001), "0 in")
        XCTAssertEqual(formatter.string(fromMeters: 0.0001), "0.004 in")
        XCTAssertEqual(formatter.string(fromMeters: 0.001), "0.039 in")
        XCTAssertEqual(formatter.string(fromMeters: 0.01), "0.394 in")
        XCTAssertEqual(formatter.string(fromMeters: 0.1), "3.937 in")
        XCTAssertEqual(formatter.string(fromMeters: 1), "1.094 yd")
        XCTAssertEqual(formatter.string(fromMeters: 10), "10.936 yd")
        XCTAssertEqual(formatter.string(fromMeters: 10000), "6.214 mi")
        XCTAssertEqual(formatter.string(fromMeters: 1000000), "621.373 mi")
        XCTAssertEqual(formatter.string(fromMeters: 10000000), "6,213.727 mi")
        XCTAssertEqual(formatter.string(fromMeters: 100000000), "62,137.274 mi")
    }
    
    func test_stringFromMetersUSPersonHeight() {
        formatter.isForPersonHeightUse = true
        XCTAssertEqual(formatter.string(fromMeters: -100000), "-328,083 ft, 11.874 in")
        XCTAssertEqual(formatter.string(fromMeters: -1), "-3 ft, 3.37 in")
        XCTAssertEqual(formatter.string(fromMeters: 0.00001), "0 ft, 0 in")
        XCTAssertEqual(formatter.string(fromMeters: 0.0001), "0 ft, 0.004 in")
        XCTAssertEqual(formatter.string(fromMeters: 0.001), "0 ft, 0.039 in")
        XCTAssertEqual(formatter.string(fromMeters: 0.01), "0 ft, 0.394 in")
        XCTAssertEqual(formatter.string(fromMeters: 0.1), "0 ft, 3.937 in")
        XCTAssertEqual(formatter.string(fromMeters: 1), "3 ft, 3.37 in")
        XCTAssertEqual(formatter.string(fromMeters: 10), "32 ft, 9.701 in")
        XCTAssertEqual(formatter.string(fromMeters: 100000000), "328,083,989 ft, 6.016 in")
    }
    
    func test_stringFromMetersMetric() {
        formatter.numberFormatter.locale = Locale(identifier: "en_GB")
        XCTAssertEqual(formatter.string(fromMeters: -10000), "-10 km")
        XCTAssertEqual(formatter.string(fromMeters: -1), "-0.001 km")
        XCTAssertEqual(formatter.string(fromMeters: 0.00001), "0.01 mm")
        XCTAssertEqual(formatter.string(fromMeters: 0.0001), "0.1 mm")
        XCTAssertEqual(formatter.string(fromMeters: 0.001), "1 mm")
        XCTAssertEqual(formatter.string(fromMeters: 0.01), "10 mm")
        XCTAssertEqual(formatter.string(fromMeters: 0.1), "10 cm")
        XCTAssertEqual(formatter.string(fromMeters: 0.5), "50 cm")
        XCTAssertEqual(formatter.string(fromMeters: 1), "100 cm")
        XCTAssertEqual(formatter.string(fromMeters: 10), "10 m")
        XCTAssertEqual(formatter.string(fromMeters: 10000), "10 km")
        XCTAssertEqual(formatter.string(fromMeters: 1000000), "1,000 km")
        XCTAssertEqual(formatter.string(fromMeters: 10000000), "10,000 km")
        XCTAssertEqual(formatter.string(fromMeters: 100000000), "100,000 km")
    }
    
    func test_stringFromMetersMetricPersonHeight() {
        formatter.numberFormatter.locale = Locale(identifier: "en_GB")
        formatter.isForPersonHeightUse = true
        XCTAssertEqual(formatter.string(fromMeters: -1), "-100 cm")
        XCTAssertEqual(formatter.string(fromMeters: 0.001), "0.1 cm")
        XCTAssertEqual(formatter.string(fromMeters: 0.1), "10 cm")
        XCTAssertEqual(formatter.string(fromMeters: 10), "1,000 cm")
        XCTAssertEqual(formatter.string(fromMeters: 1000000), "100,000,000 cm")
    }
    
    func test_stringFromValue() {
        formatter.unitStyle = .long
        XCTAssertEqual(formatter.string(fromValue: 0.002, unit: .millimeter),"0.002 millimeters")
        XCTAssertEqual(formatter.string(fromValue:0, unit: .centimeter), "0 centimeters")
        
        formatter.unitStyle = .short
        XCTAssertEqual(formatter.string(fromValue: 0.00000001, unit: .foot), "0′")
        XCTAssertEqual(formatter.string(fromValue: 2.4, unit: .inch), "2.4″")
        XCTAssertEqual(formatter.string(fromValue: 123456, unit: .yard), "123,456yd")
        
        formatter.unitStyle = .medium
        formatter.isForPersonHeightUse = true
        XCTAssertEqual(formatter.string(fromValue: 0.00000001, unit: .foot), "0 ft")
        XCTAssertEqual(formatter.string(fromValue: 987654321, unit: .yard), "987,654,321 yd")
        
        formatter.isForPersonHeightUse = false
        XCTAssertEqual(formatter.string(fromValue: 5.3, unit: .millimeter), "5.3 mm")
        XCTAssertEqual(formatter.string(fromValue: 873.2345, unit: .centimeter), "873.234 cm")
    }
    
    func test_unitStringFromMeters() {
        var unit = LengthFormatter.Unit.meter
        XCTAssertEqual(formatter.unitString(fromMeters: -100000, usedUnit: &unit), "mi")
        XCTAssertEqual(unit, .mile)
        
        XCTAssertEqual(formatter.unitString(fromMeters: -1, usedUnit: &unit), "mi")
        XCTAssertEqual(unit, .mile)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 0.00001, usedUnit: &unit), "in")
        XCTAssertEqual(unit, .inch)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 0.0001, usedUnit: &unit), "in")
        XCTAssertEqual(unit, .inch)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 0.001, usedUnit: &unit), "in")
        XCTAssertEqual(unit, .inch)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 0.01, usedUnit: &unit), "in")
        XCTAssertEqual(unit, .inch)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 0.1, usedUnit: &unit), "in")
        XCTAssertEqual(unit, .inch)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 1, usedUnit: &unit), "yd")
        XCTAssertEqual(unit, .yard)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 10, usedUnit: &unit), "yd")
        XCTAssertEqual(unit, .yard)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 10000, usedUnit: &unit), "mi")
        XCTAssertEqual(unit, .mile)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 1000000, usedUnit: &unit),"mi")
        XCTAssertEqual(unit, .mile)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 10000000, usedUnit: &unit), "mi")
        XCTAssertEqual(unit, .mile)
        
        XCTAssertEqual(formatter.unitString(fromMeters: 100000000, usedUnit: &unit), "mi")
        XCTAssertEqual(unit, .mile)
    }
    
    func test_unitStringFromValue() {
        formatter.unitStyle = .long
        XCTAssertEqual(formatter.unitString(fromValue: 0.002, unit: .millimeter), "millimeters")
        XCTAssertEqual(formatter.unitString(fromValue: 0, unit: .centimeter), "centimeters")
        
        formatter.unitStyle = .short
        XCTAssertEqual(formatter.unitString(fromValue: 0.00000001, unit: .foot), "′")
        XCTAssertEqual(formatter.unitString(fromValue: 123456, unit: .yard), "yd")
        
        formatter.unitStyle = .medium
        formatter.isForPersonHeightUse = true
        XCTAssertEqual(formatter.unitString(fromValue: 0.00000001, unit: .foot), "ft")
        XCTAssertEqual(formatter.unitString(fromValue: 987654321, unit: .yard), "yd")
        
        formatter.isForPersonHeightUse = false
        XCTAssertEqual(formatter.unitString(fromValue: 5.3, unit: .millimeter), "mm")
        XCTAssertEqual(formatter.unitString(fromValue: 873.2345, unit: .centimeter), "cm")
    }
}
