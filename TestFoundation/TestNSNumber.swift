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


class TestNSNumber : XCTestCase {
    static var allTests: [(String, (TestNSNumber) -> () throws -> Void)] {
        return [
            ("test_NumberWithBool", test_NumberWithBool ),
            ("test_numberWithChar", test_numberWithChar ),
            ("test_numberWithUnsignedChar", test_numberWithUnsignedChar ),
            ("test_numberWithShort", test_numberWithShort ),
            ("test_numberWithFloat", test_numberWithFloat ),
            ("test_numberWithDouble", test_numberWithDouble ),
            ("test_compareNumberWithBool", test_compareNumberWithBool ),
            ("test_compareNumberWithChar", test_compareNumberWithChar ),
            ("test_compareNumberWithUnsignedChar", test_compareNumberWithUnsignedChar ),
            ("test_compareNumberWithShort", test_compareNumberWithShort ),
            ("test_compareNumberWithFloat", test_compareNumberWithFloat ),
            ("test_compareNumberWithDouble", test_compareNumberWithDouble ),
            ("test_reflection", test_reflection ),
            ("test_description", test_description ),
            ("test_descriptionWithLocale", test_descriptionWithLocale ),
        ]
    }
    
    func test_NumberWithBool() {
        XCTAssertEqual(NSNumber(value: true).boolValue, true)
        XCTAssertEqual(NSNumber(value: true).int8Value, Int8(1))
        XCTAssertEqual(NSNumber(value: true).uint8Value, UInt8(1))
        XCTAssertEqual(NSNumber(value: true).int16Value, Int16(1))
        XCTAssertEqual(NSNumber(value: true).uint16Value, UInt16(1))
        XCTAssertEqual(NSNumber(value: true).int32Value, Int32(1))
        XCTAssertEqual(NSNumber(value: true).uint32Value, UInt32(1))
        XCTAssertEqual(NSNumber(value: true).int64Value, Int64(1))
        XCTAssertEqual(NSNumber(value: true).uint64Value, UInt64(1))

        XCTAssertEqual(NSNumber(value: true).floatValue, Float(1))
        XCTAssertEqual(NSNumber(value: true).doubleValue, Double(1))
        
        XCTAssertEqual(NSNumber(value: false).boolValue, false)
        XCTAssertEqual(NSNumber(value: false).int8Value, Int8(0))
        XCTAssertEqual(NSNumber(value: false).uint8Value, UInt8(0))
        XCTAssertEqual(NSNumber(value: false).int16Value, Int16(0))
        XCTAssertEqual(NSNumber(value: false).uint16Value, UInt16(0))
        XCTAssertEqual(NSNumber(value: false).int32Value, Int32(0))
        XCTAssertEqual(NSNumber(value: false).uint32Value, UInt32(0))
        XCTAssertEqual(NSNumber(value: false).int64Value, Int64(0))
        XCTAssertEqual(NSNumber(value: false).uint64Value, UInt64(0))

        XCTAssertEqual(NSNumber(value: false).floatValue, Float(0))
        XCTAssertEqual(NSNumber(value: false).doubleValue, Double(0))
    }
    
    func test_numberWithChar() {
        XCTAssertEqual(NSNumber(value: Int8(0)).boolValue, false)
        XCTAssertEqual(NSNumber(value: Int8(0)).int8Value, Int8(0))
        XCTAssertEqual(NSNumber(value: Int8(0)).uint8Value, UInt8(0))
        XCTAssertEqual(NSNumber(value: Int8(0)).int16Value, Int16(0))
        XCTAssertEqual(NSNumber(value: Int8(0)).uint16Value, UInt16(0))
        XCTAssertEqual(NSNumber(value: Int8(0)).int32Value, Int32(0))
        XCTAssertEqual(NSNumber(value: Int8(0)).uint32Value, UInt32(0))
        XCTAssertEqual(NSNumber(value: Int8(0)).int64Value, Int64(0))
        XCTAssertEqual(NSNumber(value: Int8(0)).uint64Value, UInt64(0))
        XCTAssertEqual(NSNumber(value: Int8(-37)).boolValue, true)
        XCTAssertEqual(NSNumber(value: Int8(-37)).int8Value, Int8(-37))
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, these tests will always fail.
        XCTAssertEqual(NSNumber(value: Int8(-37)).int16Value, Int16(-37))
        XCTAssertEqual(NSNumber(value: Int8(-37)).int32Value, Int32(-37))
        XCTAssertEqual(NSNumber(value: Int8(-37)).int64Value, Int64(-37))
#endif
        XCTAssertEqual(NSNumber(value: Int8(42)).boolValue, true)
        XCTAssertEqual(NSNumber(value: Int8(42)).int8Value, Int8(42))
        XCTAssertEqual(NSNumber(value: Int8(42)).uint8Value, UInt8(42))
        XCTAssertEqual(NSNumber(value: Int8(42)).int16Value, Int16(42))
        XCTAssertEqual(NSNumber(value: Int8(42)).uint16Value, UInt16(42))
        XCTAssertEqual(NSNumber(value: Int8(42)).int32Value, Int32(42))
        XCTAssertEqual(NSNumber(value: Int8(42)).uint32Value, UInt32(42))
        XCTAssertEqual(NSNumber(value: Int8(42)).int64Value, Int64(42))
        XCTAssertEqual(NSNumber(value: Int8(42)).uint64Value, UInt64(42))
        XCTAssertEqual(NSNumber(value: Int8.max).boolValue, true)
        XCTAssertEqual(NSNumber(value: Int8.max).int8Value, Int8(Int8.max))
        XCTAssertEqual(NSNumber(value: Int8.max).uint8Value, UInt8(Int8.max))
        XCTAssertEqual(NSNumber(value: Int8.max).int16Value, Int16(Int8.max))
        XCTAssertEqual(NSNumber(value: Int8.max).uint16Value, UInt16(Int8.max))
        XCTAssertEqual(NSNumber(value: Int8.max).int32Value, Int32(Int8.max))
        XCTAssertEqual(NSNumber(value: Int8.max).uint32Value, UInt32(Int8.max))
        XCTAssertEqual(NSNumber(value: Int8.max).int64Value, Int64(Int8.max))
        XCTAssertEqual(NSNumber(value: Int8.max).uint64Value, UInt64(Int8.max))
        XCTAssertEqual(NSNumber(value: Int8.min).boolValue, true)
        XCTAssertEqual(NSNumber(value: Int8.min).int8Value, Int8(Int8.min))
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, these tests will always fail.
        XCTAssertEqual(NSNumber(value: Int8.min).int16Value, Int16(Int8.min))
        XCTAssertEqual(NSNumber(value: Int8.min).int32Value, Int32(Int8.min))
        XCTAssertEqual(NSNumber(value: Int8.min).int64Value, Int64(Int8.min))
#endif
        XCTAssertEqual(NSNumber(value: Int8(0)).floatValue, Float(0))
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, this test will always fail.
        XCTAssertEqual(NSNumber(value: Int8(-37)).floatValue, Float(-37))
#endif
        XCTAssertEqual(NSNumber(value: Int8(42)).floatValue, Float(42))
        XCTAssertEqual(NSNumber(value: Int8.max).floatValue, Float(Int8.max))
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, this test will always fail.
        XCTAssertEqual(NSNumber(value: Int8.min).floatValue, Float(Int8.min))
#endif
        XCTAssertEqual(NSNumber(value: Int8(0)).doubleValue, Double(0))
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, this test will always fail.
        XCTAssertEqual(NSNumber(value: Int8(-37)).doubleValue, Double(-37))
#endif
        XCTAssertEqual(NSNumber(value: Int8(42)).doubleValue, Double(42))
        XCTAssertEqual(NSNumber(value: Int8.max).doubleValue, Double(Int8.max))
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, this test will always fail.
        XCTAssertEqual(NSNumber(value: Int8.min).doubleValue, Double(Int8.min))
#endif
    }
    
    func test_numberWithUnsignedChar() {
        XCTAssertEqual(NSNumber(value: UInt8(0)).boolValue, false)
        XCTAssertEqual(NSNumber(value: UInt8(0)).int8Value, Int8(0))
        XCTAssertEqual(NSNumber(value: UInt8(0)).uint8Value, UInt8(0))
        XCTAssertEqual(NSNumber(value: UInt8(0)).int16Value, Int16(0))
        XCTAssertEqual(NSNumber(value: UInt8(0)).uint16Value, UInt16(0))
        XCTAssertEqual(NSNumber(value: UInt8(0)).int32Value, Int32(0))
        XCTAssertEqual(NSNumber(value: UInt8(0)).uint32Value, UInt32(0))
        XCTAssertEqual(NSNumber(value: UInt8(0)).int64Value, Int64(0))
        XCTAssertEqual(NSNumber(value: UInt8(0)).uint64Value, UInt64(0))
        XCTAssertEqual(NSNumber(value: UInt8(42)).boolValue, true)
        XCTAssertEqual(NSNumber(value: UInt8(42)).int8Value, Int8(42))
        XCTAssertEqual(NSNumber(value: UInt8(42)).uint8Value, UInt8(42))
        XCTAssertEqual(NSNumber(value: UInt8(42)).int16Value, Int16(42))
        XCTAssertEqual(NSNumber(value: UInt8(42)).uint16Value, UInt16(42))
        XCTAssertEqual(NSNumber(value: UInt8(42)).int32Value, Int32(42))
        XCTAssertEqual(NSNumber(value: UInt8(42)).uint32Value, UInt32(42))
        XCTAssertEqual(NSNumber(value: UInt8(42)).int64Value, Int64(42))
        XCTAssertEqual(NSNumber(value: UInt8(42)).uint64Value, UInt64(42))
        XCTAssertEqual(NSNumber(value: UInt8.max).boolValue, true)
        XCTAssertEqual(NSNumber(value: UInt8.max).uint8Value, UInt8.max)
//        XCTAssertEqual(NSNumber(value: UInt8.max).int16Value, Int16(UInt8.max))
//        XCTAssertEqual(NSNumber(value: UInt8.max).uint16Value, UInt16(UInt8.max))
//        XCTAssertEqual(NSNumber(value: UInt8.max).int32Value, Int32(UInt8.max))
//        XCTAssertEqual(NSNumber(value: UInt8.max).uint32Value, UInt32(UInt8.max))
//        XCTAssertEqual(NSNumber(value: UInt8.max).int64Value, Int64(UInt8.max))
//        XCTAssertEqual(NSNumber(value: UInt8.max).uint64Value, UInt64(UInt8.max))
        XCTAssertEqual(NSNumber(value: UInt8.min).boolValue, false)
        XCTAssertEqual(NSNumber(value: UInt8.min).int8Value, Int8(UInt8.min))
        XCTAssertEqual(NSNumber(value: UInt8.min).int16Value, Int16(UInt8.min))
        XCTAssertEqual(NSNumber(value: UInt8.min).int32Value, Int32(UInt8.min))
        XCTAssertEqual(NSNumber(value: UInt8.min).int64Value, Int64(UInt8.min))
        XCTAssertEqual(NSNumber(value: UInt8(0)).floatValue, Float(0))
        XCTAssertEqual(NSNumber(value: UInt8(42)).floatValue, Float(42))
//        XCTAssertEqual(NSNumber(value: UInt8.max).floatValue, Float(UInt8.max))
        XCTAssertEqual(NSNumber(value: UInt8.min).floatValue, Float(UInt8.min))
        XCTAssertEqual(NSNumber(value: UInt8(0)).doubleValue, Double(0))
        XCTAssertEqual(NSNumber(value: UInt8(42)).doubleValue, Double(42))
//        XCTAssertEqual(NSNumber(value: UInt8.max).doubleValue, Double(UInt8.max))
        XCTAssertEqual(NSNumber(value: UInt8.min).doubleValue, Double(UInt8.min))
    }
    
    func test_numberWithShort() {
        XCTAssertEqual(NSNumber(value: Int16(0)).boolValue, false)
        XCTAssertEqual(NSNumber(value: Int16(0)).int8Value, Int8(0))
        XCTAssertEqual(NSNumber(value: Int16(0)).uint8Value, UInt8(0))
        XCTAssertEqual(NSNumber(value: Int16(0)).int16Value, Int16(0))
        XCTAssertEqual(NSNumber(value: Int16(0)).uint16Value, UInt16(0))
        XCTAssertEqual(NSNumber(value: Int16(0)).int32Value, Int32(0))
        XCTAssertEqual(NSNumber(value: Int16(0)).uint32Value, UInt32(0))
        XCTAssertEqual(NSNumber(value: Int16(0)).int64Value, Int64(0))
        XCTAssertEqual(NSNumber(value: Int16(0)).uint64Value, UInt64(0))
        XCTAssertEqual(NSNumber(value: Int16(-37)).boolValue, true)
        XCTAssertEqual(NSNumber(value: Int16(-37)).int8Value, Int8(-37))
        XCTAssertEqual(NSNumber(value: Int16(-37)).int16Value, Int16(-37))
        XCTAssertEqual(NSNumber(value: Int16(-37)).int32Value, Int32(-37))
        XCTAssertEqual(NSNumber(value: Int16(-37)).int64Value, Int64(-37))
        XCTAssertEqual(NSNumber(value: Int16(42)).boolValue, true)
        XCTAssertEqual(NSNumber(value: Int16(42)).int8Value, Int8(42))
        XCTAssertEqual(NSNumber(value: Int16(42)).uint8Value, UInt8(42))
        XCTAssertEqual(NSNumber(value: Int16(42)).int16Value, Int16(42))
        XCTAssertEqual(NSNumber(value: Int16(42)).uint16Value, UInt16(42))
        XCTAssertEqual(NSNumber(value: Int16(42)).int32Value, Int32(42))
        XCTAssertEqual(NSNumber(value: Int16(42)).uint32Value, UInt32(42))
        XCTAssertEqual(NSNumber(value: Int16(42)).int64Value, Int64(42))
        XCTAssertEqual(NSNumber(value: Int16(42)).uint64Value, UInt64(42))
        XCTAssertEqual(NSNumber(value: Int16.max).boolValue, true)
        XCTAssertEqual(NSNumber(value: Int16.min).boolValue, true)
        XCTAssertEqual(NSNumber(value: Int16(0)).floatValue, Float(0))
        XCTAssertEqual(NSNumber(value: Int16(-37)).floatValue, Float(-37))
        XCTAssertEqual(NSNumber(value: Int16(42)).floatValue, Float(42))
        XCTAssertEqual(NSNumber(value: Int16(0)).doubleValue, Double(0))
        XCTAssertEqual(NSNumber(value: Int16(-37)).doubleValue, Double(-37))
        XCTAssertEqual(NSNumber(value: Int16(42)).doubleValue, Double(42))
    }
    
    func test_numberWithFloat() {
        XCTAssertEqual(NSNumber(value: Float(0)).boolValue, false)
        XCTAssertEqual(NSNumber(value: Float(0)).int8Value, Int8(0))
        XCTAssertEqual(NSNumber(value: Float(0)).uint8Value, UInt8(0))
        XCTAssertEqual(NSNumber(value: Float(0)).int16Value, Int16(0))
        XCTAssertEqual(NSNumber(value: Float(0)).uint16Value, UInt16(0))
        XCTAssertEqual(NSNumber(value: Float(0)).int32Value, Int32(0))
        XCTAssertEqual(NSNumber(value: Float(0)).uint32Value, UInt32(0))
        XCTAssertEqual(NSNumber(value: Float(0)).int64Value, Int64(0))
        XCTAssertEqual(NSNumber(value: Float(0)).uint64Value, UInt64(0))
        XCTAssertEqual(NSNumber(value: Float(-37)).boolValue, true)
        XCTAssertEqual(NSNumber(value: Float(-37)).int8Value, Int8(-37))
        XCTAssertEqual(NSNumber(value: Float(-37)).int16Value, Int16(-37))
        XCTAssertEqual(NSNumber(value: Float(-37)).int32Value, Int32(-37))
        XCTAssertEqual(NSNumber(value: Float(-37)).int64Value, Int64(-37))
        XCTAssertEqual(NSNumber(value: Float(42)).boolValue, true)
        XCTAssertEqual(NSNumber(value: Float(42)).int8Value, Int8(42))
        XCTAssertEqual(NSNumber(value: Float(42)).uint8Value, UInt8(42))
        XCTAssertEqual(NSNumber(value: Float(42)).int16Value, Int16(42))
        XCTAssertEqual(NSNumber(value: Float(42)).uint16Value, UInt16(42))
        XCTAssertEqual(NSNumber(value: Float(42)).int32Value, Int32(42))
        XCTAssertEqual(NSNumber(value: Float(42)).uint32Value, UInt32(42))
        XCTAssertEqual(NSNumber(value: Float(42)).int64Value, Int64(42))
        XCTAssertEqual(NSNumber(value: Float(42)).uint64Value, UInt64(42))
        XCTAssertEqual(NSNumber(value: Float(0)).floatValue, Float(0))
        XCTAssertEqual(NSNumber(value: Float(-37.5)).floatValue, Float(-37.5))
        XCTAssertEqual(NSNumber(value: Float(42.1)).floatValue, Float(42.1))
        XCTAssertEqual(NSNumber(value: Float(0)).doubleValue, Double(0))
        XCTAssertEqual(NSNumber(value: Float(-37.5)).doubleValue, Double(-37.5))
        XCTAssertEqual(NSNumber(value: Float(42.5)).doubleValue, Double(42.5))
    }
    
    func test_numberWithDouble() {
        XCTAssertEqual(NSNumber(value: Double(0)).boolValue, false)
        XCTAssertEqual(NSNumber(value: Double(0)).int8Value, Int8(0))
        XCTAssertEqual(NSNumber(value: Double(0)).uint8Value, UInt8(0))
        XCTAssertEqual(NSNumber(value: Double(0)).int16Value, Int16(0))
        XCTAssertEqual(NSNumber(value: Double(0)).uint16Value, UInt16(0))
        XCTAssertEqual(NSNumber(value: Double(0)).int32Value, Int32(0))
        XCTAssertEqual(NSNumber(value: Double(0)).uint32Value, UInt32(0))
        XCTAssertEqual(NSNumber(value: Double(0)).int64Value, Int64(0))
        XCTAssertEqual(NSNumber(value: Double(0)).uint64Value, UInt64(0))
        XCTAssertEqual(NSNumber(value: Double(-37)).boolValue, true)
        XCTAssertEqual(NSNumber(value: Double(-37)).int8Value, Int8(-37))
        XCTAssertEqual(NSNumber(value: Double(-37)).int16Value, Int16(-37))
        XCTAssertEqual(NSNumber(value: Double(-37)).int32Value, Int32(-37))
        XCTAssertEqual(NSNumber(value: Double(-37)).int64Value, Int64(-37))
        XCTAssertEqual(NSNumber(value: Double(42)).boolValue, true)
        XCTAssertEqual(NSNumber(value: Double(42)).int8Value, Int8(42))
        XCTAssertEqual(NSNumber(value: Double(42)).uint8Value, UInt8(42))
        XCTAssertEqual(NSNumber(value: Double(42)).int16Value, Int16(42))
        XCTAssertEqual(NSNumber(value: Double(42)).uint16Value, UInt16(42))
        XCTAssertEqual(NSNumber(value: Double(42)).int32Value, Int32(42))
        XCTAssertEqual(NSNumber(value: Double(42)).uint32Value, UInt32(42))
        XCTAssertEqual(NSNumber(value: Double(42)).int64Value, Int64(42))
        XCTAssertEqual(NSNumber(value: Double(42)).uint64Value, UInt64(42))
        XCTAssertEqual(NSNumber(value: Double(0)).floatValue, Float(0))
        XCTAssertEqual(NSNumber(value: Double(-37.5)).floatValue, Float(-37.5))
        XCTAssertEqual(NSNumber(value: Double(42.1)).floatValue, Float(42.1))
        XCTAssertEqual(NSNumber(value: Double(0)).doubleValue, Double(0))
        XCTAssertEqual(NSNumber(value: Double(-37.5)).doubleValue, Double(-37.5))
        XCTAssertEqual(NSNumber(value: Double(42.1)).doubleValue, Double(42.1))
    }

    func test_compareNumberWithBool() {
        XCTAssertEqual(NSNumber(value: true).compare(NSNumber(value: true)), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: true).compare(NSNumber(value: false)), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: false).compare(NSNumber(value: true)), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: false).compare(NSNumber(value: Int8(0))), ComparisonResult.orderedSame)
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, this test will always fail.
        XCTAssertEqual(NSNumber(value: false).compare(NSNumber(value: Int8(-1))), ComparisonResult.orderedDescending)
#endif
        XCTAssertEqual(NSNumber(value: false).compare(NSNumber(value: Int8(1))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: true).compare(NSNumber(value: Int8(1))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: true).compare(NSNumber(value: Int8(0))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: true).compare(NSNumber(value: Int8(2))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: false).compare(NSNumber(value: Double(0))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: false).compare(NSNumber(value: Double(-0.1))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: false).compare(NSNumber(value: Double(0.1))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: true).compare(NSNumber(value: Double(1))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: true).compare(NSNumber(value: Double(0.9))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: true).compare(NSNumber(value: Double(1.1))), ComparisonResult.orderedAscending)
    }

    func test_compareNumberWithChar() {
        XCTAssertEqual(NSNumber(value: Int8(42)).compare(NSNumber(value: Int8(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Int8(42)).compare(NSNumber(value: Int8(0))), ComparisonResult.orderedDescending)
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, this test will always fail.
        XCTAssertEqual(NSNumber(value: Int8(-37)).compare(NSNumber(value: Int8(16))), ComparisonResult.orderedAscending)
#endif

        XCTAssertEqual(NSNumber(value: Int8(1)).compare(NSNumber(value: true)), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Int8(1)).compare(NSNumber(value: false)), ComparisonResult.orderedDescending)
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, this test will always fail.
        XCTAssertEqual(NSNumber(value: Int8(-37)).compare(NSNumber(value: true)), ComparisonResult.orderedAscending)
#endif

        XCTAssertEqual(NSNumber(value: Int8(42)).compare(NSNumber(value: UInt8(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Int8(42)).compare(NSNumber(value: UInt8(16))), ComparisonResult.orderedDescending)
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, this test will always fail.
        XCTAssertEqual(NSNumber(value: Int8(-37)).compare(NSNumber(value: UInt8(255))), ComparisonResult.orderedAscending)
#endif

        XCTAssertEqual(NSNumber(value: Int8(42)).compare(NSNumber(value: Float(42))), ComparisonResult.orderedSame)
#if !(os(Linux) && arch(arm))
        // Linux/arm chars are unsigned, so Int8 in Swift, until this issue is resolved, this test will always fail.
        XCTAssertEqual(NSNumber(value: Int8(-16)).compare(NSNumber(value: Float(-37.5))), ComparisonResult.orderedDescending)
#endif
        XCTAssertEqual(NSNumber(value: Int8(16)).compare(NSNumber(value: Float(16.1))), ComparisonResult.orderedAscending)
    }

    func test_compareNumberWithUnsignedChar() {
        XCTAssertEqual(NSNumber(value: UInt8(42)).compare(NSNumber(value: UInt8(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: UInt8(42)).compare(NSNumber(value: UInt8(0))), ComparisonResult.orderedDescending)
//        XCTAssertEqual(NSNumber(value: UInt8(42)).compare(NSNumber(value: UInt8(255))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: UInt8(1)).compare(NSNumber(value: true)), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: UInt8(1)).compare(NSNumber(value: false)), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: UInt8(0)).compare(NSNumber(value: true)), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: UInt8(42)).compare(NSNumber(value: Int16(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: UInt8(0)).compare(NSNumber(value: Int16(-123))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: UInt8(255)).compare(NSNumber(value: Int16(12345))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: UInt8(42)).compare(NSNumber(value: Float(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: UInt8(0)).compare(NSNumber(value: Float(-37.5))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: UInt8(255)).compare(NSNumber(value: Float(1234.5))), ComparisonResult.orderedAscending)
    }

    func test_compareNumberWithShort() {
        XCTAssertEqual(NSNumber(value: Int16(42)).compare(NSNumber(value: Int16(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Int16(42)).compare(NSNumber(value: Int16(0))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Int16(-37)).compare(NSNumber(value: Int16(12345))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: Int16(1)).compare(NSNumber(value: true)), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Int16(1)).compare(NSNumber(value: false)), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Int16(0)).compare(NSNumber(value: true)), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: Int16(42)).compare(NSNumber(value: UInt8(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Int16(42)).compare(NSNumber(value: UInt8(0))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Int16(-37)).compare(NSNumber(value: UInt8(255))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: Int16(42)).compare(NSNumber(value: Float(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Int16(0)).compare(NSNumber(value: Float(-37.5))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Int16(255)).compare(NSNumber(value: Float(1234.5))), ComparisonResult.orderedAscending)
    }

    func test_compareNumberWithFloat() {
        XCTAssertEqual(NSNumber(value: Float(42)).compare(NSNumber(value: Float(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Float(42)).compare(NSNumber(value: Float(0))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Float(-37)).compare(NSNumber(value: Float(12345))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: Float(1)).compare(NSNumber(value: true)), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Float(0.1)).compare(NSNumber(value: false)), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Float(0.9)).compare(NSNumber(value: true)), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: Float(42)).compare(NSNumber(value: UInt8(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Float(0.1)).compare(NSNumber(value: UInt8(0))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Float(-254.9)).compare(NSNumber(value: UInt8(255))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: Float(42)).compare(NSNumber(value: Double(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Float(0)).compare(NSNumber(value: Double(-37.5))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Float(-37.5)).compare(NSNumber(value: Double(1234.5))), ComparisonResult.orderedAscending)
    }

    func test_compareNumberWithDouble() {
        XCTAssertEqual(NSNumber(value: Double(42)).compare(NSNumber(value: Double(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Double(42)).compare(NSNumber(value: Double(0))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Double(-37)).compare(NSNumber(value: Double(12345))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: Double(1)).compare(NSNumber(value: true)), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Double(0.1)).compare(NSNumber(value: false)), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Double(0.9)).compare(NSNumber(value: true)), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: Double(42)).compare(NSNumber(value: UInt8(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Double(0.1)).compare(NSNumber(value: UInt8(0))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Double(-254.9)).compare(NSNumber(value: UInt8(255))), ComparisonResult.orderedAscending)

        XCTAssertEqual(NSNumber(value: Double(42)).compare(NSNumber(value: Float(42))), ComparisonResult.orderedSame)
        XCTAssertEqual(NSNumber(value: Double(0)).compare(NSNumber(value: Float(-37.5))), ComparisonResult.orderedDescending)
        XCTAssertEqual(NSNumber(value: Double(-37.5)).compare(NSNumber(value: Float(1234.5))), ComparisonResult.orderedAscending)
    }

    func test_reflection() {
       let ql1 = NSNumber(value: 1234).customPlaygroundQuickLook
       switch ql1 {
           case .int(let value): XCTAssertEqual(value, 1234)
           default: XCTAssert(false, "NSNumber(value: Int) quicklook is not an Int")
       }

       let ql2 = NSNumber(value: Float(1.25)).customPlaygroundQuickLook
       switch ql2 {
           case .float(let value): XCTAssertEqual(value, 1.25)
           default: XCTAssert(false, "NSNumber(value: Float) quicklook is not a Float")
       }

       let ql3 = NSNumber(value: Double(1.25)).customPlaygroundQuickLook
       switch ql3 {
           case .double(let value): XCTAssertEqual(value, 1.25)
           default: XCTAssert(false, "NSNumber(value: Double) quicklook is not a Double")
       }
    }
    
    func test_description() {
        let nsnumber: NSNumber = 1000
        let expectedDesc = "1000"
        XCTAssertEqual(nsnumber.description, expectedDesc, "expected \(expectedDesc) but received \(nsnumber.description)")
    }
    
    func test_descriptionWithLocale() {
        let nsnumber: NSNumber = 1000
        let values : Dictionary = [
                Locale.init(localeIdentifier: "en_GB") : "1,000",
                Locale.init(localeIdentifier: "de_DE") : "1.000",
        ]
        for (locale, expectedDesc) in values {
            let receivedDesc = nsnumber.description(withLocale: locale)
            XCTAssertEqual(receivedDesc, expectedDesc, "expected \(expectedDesc) but received \(receivedDesc)")
        }
    }
}
