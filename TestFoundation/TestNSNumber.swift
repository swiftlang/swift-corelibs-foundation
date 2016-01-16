// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
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
    var allTests : [(String, () throws -> Void)] {
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
        ]
    }
    
    func test_NumberWithBool() {
        XCTAssertEqual(NSNumber(bool: true).boolValue, true)
        XCTAssertEqual(NSNumber(bool: true).charValue, Int8(1))
        XCTAssertEqual(NSNumber(bool: true).unsignedCharValue, UInt8(1))
        XCTAssertEqual(NSNumber(bool: true).shortValue, Int16(1))
        XCTAssertEqual(NSNumber(bool: true).unsignedShortValue, UInt16(1))
        XCTAssertEqual(NSNumber(bool: true).intValue, Int32(1))
        XCTAssertEqual(NSNumber(bool: true).unsignedIntValue, UInt32(1))
        XCTAssertEqual(NSNumber(bool: true).longLongValue, Int64(1))
        XCTAssertEqual(NSNumber(bool: true).unsignedLongLongValue, UInt64(1))

        XCTAssertEqual(NSNumber(bool: true).floatValue, Float(1))
        XCTAssertEqual(NSNumber(bool: true).doubleValue, Double(1))
        
        XCTAssertEqual(NSNumber(bool: false).boolValue, false)
        XCTAssertEqual(NSNumber(bool: false).charValue, Int8(0))
        XCTAssertEqual(NSNumber(bool: false).unsignedCharValue, UInt8(0))
        XCTAssertEqual(NSNumber(bool: false).shortValue, Int16(0))
        XCTAssertEqual(NSNumber(bool: false).unsignedShortValue, UInt16(0))
        XCTAssertEqual(NSNumber(bool: false).intValue, Int32(0))
        XCTAssertEqual(NSNumber(bool: false).unsignedIntValue, UInt32(0))
        XCTAssertEqual(NSNumber(bool: false).longLongValue, Int64(0))
        XCTAssertEqual(NSNumber(bool: false).unsignedLongLongValue, UInt64(0))

        XCTAssertEqual(NSNumber(bool: false).floatValue, Float(0))
        XCTAssertEqual(NSNumber(bool: false).doubleValue, Double(0))
    }
    
    func test_numberWithChar() {
        XCTAssertEqual(NSNumber(char: Int8(0)).boolValue, false)
        XCTAssertEqual(NSNumber(char: Int8(0)).charValue, Int8(0))
        XCTAssertEqual(NSNumber(char: Int8(0)).unsignedCharValue, UInt8(0))
        XCTAssertEqual(NSNumber(char: Int8(0)).shortValue, Int16(0))
        XCTAssertEqual(NSNumber(char: Int8(0)).unsignedShortValue, UInt16(0))
        XCTAssertEqual(NSNumber(char: Int8(0)).intValue, Int32(0))
        XCTAssertEqual(NSNumber(char: Int8(0)).unsignedIntValue, UInt32(0))
        XCTAssertEqual(NSNumber(char: Int8(0)).longLongValue, Int64(0))
        XCTAssertEqual(NSNumber(char: Int8(0)).unsignedLongLongValue, UInt64(0))
        XCTAssertEqual(NSNumber(char: Int8(-37)).boolValue, true);
        XCTAssertEqual(NSNumber(char: Int8(-37)).charValue, Int8(-37))
        XCTAssertEqual(NSNumber(char: Int8(-37)).shortValue, Int16(-37))
        XCTAssertEqual(NSNumber(char: Int8(-37)).intValue, Int32(-37))
        XCTAssertEqual(NSNumber(char: Int8(-37)).longLongValue, Int64(-37))
        XCTAssertEqual(NSNumber(char: Int8(42)).boolValue, true)
        XCTAssertEqual(NSNumber(char: Int8(42)).charValue, Int8(42))
        XCTAssertEqual(NSNumber(char: Int8(42)).unsignedCharValue, UInt8(42))
        XCTAssertEqual(NSNumber(char: Int8(42)).shortValue, Int16(42))
        XCTAssertEqual(NSNumber(char: Int8(42)).unsignedShortValue, UInt16(42))
        XCTAssertEqual(NSNumber(char: Int8(42)).intValue, Int32(42))
        XCTAssertEqual(NSNumber(char: Int8(42)).unsignedIntValue, UInt32(42))
        XCTAssertEqual(NSNumber(char: Int8(42)).longLongValue, Int64(42))
        XCTAssertEqual(NSNumber(char: Int8(42)).unsignedLongLongValue, UInt64(42))
        XCTAssertEqual(NSNumber(char: Int8.max).boolValue, true)
        XCTAssertEqual(NSNumber(char: Int8.max).charValue, Int8(Int8.max))
        XCTAssertEqual(NSNumber(char: Int8.max).unsignedCharValue, UInt8(Int8.max))
        XCTAssertEqual(NSNumber(char: Int8.max).shortValue, Int16(Int8.max))
        XCTAssertEqual(NSNumber(char: Int8.max).unsignedShortValue, UInt16(Int8.max))
        XCTAssertEqual(NSNumber(char: Int8.max).intValue, Int32(Int8.max))
        XCTAssertEqual(NSNumber(char: Int8.max).unsignedIntValue, UInt32(Int8.max))
        XCTAssertEqual(NSNumber(char: Int8.max).longLongValue, Int64(Int8.max))
        XCTAssertEqual(NSNumber(char: Int8.max).unsignedLongLongValue, UInt64(Int8.max))
        XCTAssertEqual(NSNumber(char: Int8.min).boolValue, true)
        XCTAssertEqual(NSNumber(char: Int8.min).charValue, Int8(Int8.min))
        XCTAssertEqual(NSNumber(char: Int8.min).shortValue, Int16(Int8.min))
        XCTAssertEqual(NSNumber(char: Int8.min).intValue, Int32(Int8.min))
        XCTAssertEqual(NSNumber(char: Int8.min).longLongValue, Int64(Int8.min))
        XCTAssertEqual(NSNumber(char: Int8(0)).floatValue, Float(0))
        XCTAssertEqual(NSNumber(char: Int8(-37)).floatValue, Float(-37))
        XCTAssertEqual(NSNumber(char: Int8(42)).floatValue, Float(42))
        XCTAssertEqual(NSNumber(char: Int8.max).floatValue, Float(Int8.max))
        XCTAssertEqual(NSNumber(char: Int8.min).floatValue, Float(Int8.min))
        XCTAssertEqual(NSNumber(char: Int8(0)).doubleValue, Double(0))
        XCTAssertEqual(NSNumber(char: Int8(-37)).doubleValue, Double(-37))
        XCTAssertEqual(NSNumber(char: Int8(42)).doubleValue, Double(42))
        XCTAssertEqual(NSNumber(char: Int8.max).doubleValue, Double(Int8.max))
        XCTAssertEqual(NSNumber(char: Int8.min).doubleValue, Double(Int8.min))
    }
    
    func test_numberWithUnsignedChar() {
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).boolValue, false)
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).charValue, Int8(0))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).unsignedCharValue, UInt8(0))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).shortValue, Int16(0))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).unsignedShortValue, UInt16(0))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).intValue, Int32(0))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).unsignedIntValue, UInt32(0))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).longLongValue, Int64(0))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).unsignedLongLongValue, UInt64(0))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).boolValue, true)
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).charValue, Int8(42))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).unsignedCharValue, UInt8(42))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).shortValue, Int16(42))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).unsignedShortValue, UInt16(42))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).intValue, Int32(42))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).unsignedIntValue, UInt32(42))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).longLongValue, Int64(42))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).unsignedLongLongValue, UInt64(42))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8.max).boolValue, true)
        XCTAssertEqual(NSNumber(unsignedChar: UInt8.max).unsignedCharValue, UInt8.max)
//        XCTAssertEqual(NSNumber(unsignedChar: UInt8.max).shortValue, Int16(UInt8.max))
//        XCTAssertEqual(NSNumber(unsignedChar: UInt8.max).unsignedShortValue, UInt16(UInt8.max))
//        XCTAssertEqual(NSNumber(unsignedChar: UInt8.max).intValue, Int32(UInt8.max))
//        XCTAssertEqual(NSNumber(unsignedChar: UInt8.max).unsignedIntValue, UInt32(UInt8.max))
//        XCTAssertEqual(NSNumber(unsignedChar: UInt8.max).longLongValue, Int64(UInt8.max))
//        XCTAssertEqual(NSNumber(unsignedChar: UInt8.max).unsignedLongLongValue, UInt64(UInt8.max))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8.min).boolValue, false)
        XCTAssertEqual(NSNumber(unsignedChar: UInt8.min).charValue, Int8(UInt8.min))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8.min).shortValue, Int16(UInt8.min))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8.min).intValue, Int32(UInt8.min))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8.min).longLongValue, Int64(UInt8.min))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).floatValue, Float(0))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).floatValue, Float(42))
//        XCTAssertEqual(NSNumber(unsignedChar: UInt8.max).floatValue, Float(UInt8.max))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8.min).floatValue, Float(UInt8.min))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(0)).doubleValue, Double(0))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8(42)).doubleValue, Double(42))
//        XCTAssertEqual(NSNumber(unsignedChar: UInt8.max).doubleValue, Double(UInt8.max))
        XCTAssertEqual(NSNumber(unsignedChar: UInt8.min).doubleValue, Double(UInt8.min))
    }
    
    func test_numberWithShort() {
        XCTAssertEqual(NSNumber(short: Int16(0)).boolValue, false)
        XCTAssertEqual(NSNumber(short: Int16(0)).charValue, Int8(0))
        XCTAssertEqual(NSNumber(short: Int16(0)).unsignedCharValue, UInt8(0))
        XCTAssertEqual(NSNumber(short: Int16(0)).shortValue, Int16(0))
        XCTAssertEqual(NSNumber(short: Int16(0)).unsignedShortValue, UInt16(0))
        XCTAssertEqual(NSNumber(short: Int16(0)).intValue, Int32(0))
        XCTAssertEqual(NSNumber(short: Int16(0)).unsignedIntValue, UInt32(0))
        XCTAssertEqual(NSNumber(short: Int16(0)).longLongValue, Int64(0))
        XCTAssertEqual(NSNumber(short: Int16(0)).unsignedLongLongValue, UInt64(0))
        XCTAssertEqual(NSNumber(short: Int16(-37)).boolValue, true);
        XCTAssertEqual(NSNumber(short: Int16(-37)).charValue, Int8(-37))
        XCTAssertEqual(NSNumber(short: Int16(-37)).shortValue, Int16(-37))
        XCTAssertEqual(NSNumber(short: Int16(-37)).intValue, Int32(-37))
        XCTAssertEqual(NSNumber(short: Int16(-37)).longLongValue, Int64(-37))
        XCTAssertEqual(NSNumber(short: Int16(42)).boolValue, true)
        XCTAssertEqual(NSNumber(short: Int16(42)).charValue, Int8(42))
        XCTAssertEqual(NSNumber(short: Int16(42)).unsignedCharValue, UInt8(42))
        XCTAssertEqual(NSNumber(short: Int16(42)).shortValue, Int16(42))
        XCTAssertEqual(NSNumber(short: Int16(42)).unsignedShortValue, UInt16(42))
        XCTAssertEqual(NSNumber(short: Int16(42)).intValue, Int32(42))
        XCTAssertEqual(NSNumber(short: Int16(42)).unsignedIntValue, UInt32(42))
        XCTAssertEqual(NSNumber(short: Int16(42)).longLongValue, Int64(42))
        XCTAssertEqual(NSNumber(short: Int16(42)).unsignedLongLongValue, UInt64(42))
        XCTAssertEqual(NSNumber(short: Int16.max).boolValue, true)
        XCTAssertEqual(NSNumber(short: Int16.min).boolValue, true)
        XCTAssertEqual(NSNumber(short: Int16(0)).floatValue, Float(0))
        XCTAssertEqual(NSNumber(short: Int16(-37)).floatValue, Float(-37))
        XCTAssertEqual(NSNumber(short: Int16(42)).floatValue, Float(42))
        XCTAssertEqual(NSNumber(short: Int16(0)).doubleValue, Double(0))
        XCTAssertEqual(NSNumber(short: Int16(-37)).doubleValue, Double(-37))
        XCTAssertEqual(NSNumber(short: Int16(42)).doubleValue, Double(42))
    }
    
    func test_numberWithFloat() {
        XCTAssertEqual(NSNumber(float: Float(0)).boolValue, false)
        XCTAssertEqual(NSNumber(float: Float(0)).charValue, Int8(0))
        XCTAssertEqual(NSNumber(float: Float(0)).unsignedCharValue, UInt8(0))
        XCTAssertEqual(NSNumber(float: Float(0)).shortValue, Int16(0))
        XCTAssertEqual(NSNumber(float: Float(0)).unsignedShortValue, UInt16(0))
        XCTAssertEqual(NSNumber(float: Float(0)).intValue, Int32(0))
        XCTAssertEqual(NSNumber(float: Float(0)).unsignedIntValue, UInt32(0))
        XCTAssertEqual(NSNumber(float: Float(0)).longLongValue, Int64(0))
        XCTAssertEqual(NSNumber(float: Float(0)).unsignedLongLongValue, UInt64(0))
        XCTAssertEqual(NSNumber(float: Float(-37)).boolValue, true);
        XCTAssertEqual(NSNumber(float: Float(-37)).charValue, Int8(-37))
        XCTAssertEqual(NSNumber(float: Float(-37)).shortValue, Int16(-37))
        XCTAssertEqual(NSNumber(float: Float(-37)).intValue, Int32(-37))
        XCTAssertEqual(NSNumber(float: Float(-37)).longLongValue, Int64(-37))
        XCTAssertEqual(NSNumber(float: Float(42)).boolValue, true)
        XCTAssertEqual(NSNumber(float: Float(42)).charValue, Int8(42))
        XCTAssertEqual(NSNumber(float: Float(42)).unsignedCharValue, UInt8(42))
        XCTAssertEqual(NSNumber(float: Float(42)).shortValue, Int16(42))
        XCTAssertEqual(NSNumber(float: Float(42)).unsignedShortValue, UInt16(42))
        XCTAssertEqual(NSNumber(float: Float(42)).intValue, Int32(42))
        XCTAssertEqual(NSNumber(float: Float(42)).unsignedIntValue, UInt32(42))
        XCTAssertEqual(NSNumber(float: Float(42)).longLongValue, Int64(42))
        XCTAssertEqual(NSNumber(float: Float(42)).unsignedLongLongValue, UInt64(42))
        XCTAssertEqual(NSNumber(float: Float(0)).floatValue, Float(0))
        XCTAssertEqual(NSNumber(float: Float(-37.5)).floatValue, Float(-37.5))
        XCTAssertEqual(NSNumber(float: Float(42.1)).floatValue, Float(42.1))
        XCTAssertEqual(NSNumber(float: Float(0)).doubleValue, Double(0))
        XCTAssertEqual(NSNumber(float: Float(-37.5)).doubleValue, Double(-37.5))
        XCTAssertEqual(NSNumber(float: Float(42.5)).doubleValue, Double(42.5))
    }
    
    func test_numberWithDouble() {
        XCTAssertEqual(NSNumber(double: Double(0)).boolValue, false)
        XCTAssertEqual(NSNumber(double: Double(0)).charValue, Int8(0))
        XCTAssertEqual(NSNumber(double: Double(0)).unsignedCharValue, UInt8(0))
        XCTAssertEqual(NSNumber(double: Double(0)).shortValue, Int16(0))
        XCTAssertEqual(NSNumber(double: Double(0)).unsignedShortValue, UInt16(0))
        XCTAssertEqual(NSNumber(double: Double(0)).intValue, Int32(0))
        XCTAssertEqual(NSNumber(double: Double(0)).unsignedIntValue, UInt32(0))
        XCTAssertEqual(NSNumber(double: Double(0)).longLongValue, Int64(0))
        XCTAssertEqual(NSNumber(double: Double(0)).unsignedLongLongValue, UInt64(0))
        XCTAssertEqual(NSNumber(double: Double(-37)).boolValue, true);
        XCTAssertEqual(NSNumber(double: Double(-37)).charValue, Int8(-37))
        XCTAssertEqual(NSNumber(double: Double(-37)).shortValue, Int16(-37))
        XCTAssertEqual(NSNumber(double: Double(-37)).intValue, Int32(-37))
        XCTAssertEqual(NSNumber(double: Double(-37)).longLongValue, Int64(-37))
        XCTAssertEqual(NSNumber(double: Double(42)).boolValue, true)
        XCTAssertEqual(NSNumber(double: Double(42)).charValue, Int8(42))
        XCTAssertEqual(NSNumber(double: Double(42)).unsignedCharValue, UInt8(42))
        XCTAssertEqual(NSNumber(double: Double(42)).shortValue, Int16(42))
        XCTAssertEqual(NSNumber(double: Double(42)).unsignedShortValue, UInt16(42))
        XCTAssertEqual(NSNumber(double: Double(42)).intValue, Int32(42))
        XCTAssertEqual(NSNumber(double: Double(42)).unsignedIntValue, UInt32(42))
        XCTAssertEqual(NSNumber(double: Double(42)).longLongValue, Int64(42))
        XCTAssertEqual(NSNumber(double: Double(42)).unsignedLongLongValue, UInt64(42))
        XCTAssertEqual(NSNumber(double: Double(0)).floatValue, Float(0))
        XCTAssertEqual(NSNumber(double: Double(-37.5)).floatValue, Float(-37.5))
        XCTAssertEqual(NSNumber(double: Double(42.1)).floatValue, Float(42.1))
        XCTAssertEqual(NSNumber(double: Double(0)).doubleValue, Double(0))
        XCTAssertEqual(NSNumber(double: Double(-37.5)).doubleValue, Double(-37.5))
        XCTAssertEqual(NSNumber(double: Double(42.1)).doubleValue, Double(42.1))
    }

    func test_compareNumberWithBool() {
        XCTAssertEqual(NSNumber(bool: true).compare(NSNumber(bool: true)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(bool: true).compare(NSNumber(bool: false)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(bool: false).compare(NSNumber(bool: true)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(bool: false).compare(NSNumber(char: 0)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(bool: false).compare(NSNumber(char: -1)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(bool: false).compare(NSNumber(char: 1)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(bool: true).compare(NSNumber(char: 1)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(bool: true).compare(NSNumber(char: 0)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(bool: true).compare(NSNumber(char: 2)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(bool: false).compare(NSNumber(double: 0)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(bool: false).compare(NSNumber(double: -0.1)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(bool: false).compare(NSNumber(double: 0.1)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(bool: true).compare(NSNumber(double: 1)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(bool: true).compare(NSNumber(double: 0.9)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(bool: true).compare(NSNumber(double: 1.1)), NSComparisonResult.OrderedAscending)
    }

    func test_compareNumberWithChar() {
        XCTAssertEqual(NSNumber(char: 42).compare(NSNumber(char: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(char: 42).compare(NSNumber(char: 0)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(char: -37).compare(NSNumber(char: 16)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(char: 1).compare(NSNumber(bool: true)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(char: 1).compare(NSNumber(bool: false)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(char: -37).compare(NSNumber(bool: true)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(char: 42).compare(NSNumber(unsignedChar: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(char: 42).compare(NSNumber(unsignedChar: 16)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(char: -37).compare(NSNumber(unsignedChar: 255)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(char: 42).compare(NSNumber(float: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(char: -16).compare(NSNumber(float: -37.5)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(char: 16).compare(NSNumber(float: 16.1)), NSComparisonResult.OrderedAscending)
    }

    func test_compareNumberWithUnsignedChar() {
        XCTAssertEqual(NSNumber(unsignedChar: 42).compare(NSNumber(unsignedChar: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(unsignedChar: 42).compare(NSNumber(unsignedChar: 0)), NSComparisonResult.OrderedDescending)
//        XCTAssertEqual(NSNumber(unsignedChar: 42).compare(NSNumber(unsignedChar: 255)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(unsignedChar: 1).compare(NSNumber(bool: true)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(unsignedChar: 1).compare(NSNumber(bool: false)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(unsignedChar: 0).compare(NSNumber(bool: true)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(unsignedChar: 42).compare(NSNumber(short: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(unsignedChar: 0).compare(NSNumber(short: -123)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(unsignedChar: 255).compare(NSNumber(short: 12345)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(unsignedChar: 42).compare(NSNumber(float: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(unsignedChar: 0).compare(NSNumber(float: -37.5)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(unsignedChar: 255).compare(NSNumber(float: 1234.5)), NSComparisonResult.OrderedAscending)
    }

    func test_compareNumberWithShort() {
        XCTAssertEqual(NSNumber(short: 42).compare(NSNumber(short: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(short: 42).compare(NSNumber(short: 0)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(short: -37).compare(NSNumber(short: 12345)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(short: 1).compare(NSNumber(bool: true)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(short: 1).compare(NSNumber(bool: false)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(short: 0).compare(NSNumber(bool: true)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(short: 42).compare(NSNumber(unsignedChar: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(short: 42).compare(NSNumber(unsignedChar: 0)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(short: -37).compare(NSNumber(unsignedChar: 255)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(short: 42).compare(NSNumber(float: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(short: 0).compare(NSNumber(float: -37.5)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(short: 255).compare(NSNumber(float: 1234.5)), NSComparisonResult.OrderedAscending)
    }

    func test_compareNumberWithFloat() {
        XCTAssertEqual(NSNumber(float: 42).compare(NSNumber(float: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(float: 42).compare(NSNumber(float: 0)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(float: -37).compare(NSNumber(float: 12345)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(float: 1).compare(NSNumber(bool: true)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(float: 0.1).compare(NSNumber(bool: false)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(float: 0.9).compare(NSNumber(bool: true)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(float: 42).compare(NSNumber(unsignedChar: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(float: 0.1).compare(NSNumber(unsignedChar: 0)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(float: -254.9).compare(NSNumber(unsignedChar: 255)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(float: 42).compare(NSNumber(double: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(float: 0).compare(NSNumber(double: -37.5)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(float: -37.5).compare(NSNumber(double: 1234.5)), NSComparisonResult.OrderedAscending)
    }

    func test_compareNumberWithDouble() {
        XCTAssertEqual(NSNumber(double: 42).compare(NSNumber(double: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(double: 42).compare(NSNumber(double: 0)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(double: -37).compare(NSNumber(double: 12345)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(double: 1).compare(NSNumber(bool: true)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(double: 0.1).compare(NSNumber(bool: false)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(double: 0.9).compare(NSNumber(bool: true)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(double: 42).compare(NSNumber(unsignedChar: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(double: 0.1).compare(NSNumber(unsignedChar: 0)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(double: -254.9).compare(NSNumber(unsignedChar: 255)), NSComparisonResult.OrderedAscending)

        XCTAssertEqual(NSNumber(double: 42).compare(NSNumber(float: 42)), NSComparisonResult.OrderedSame)
        XCTAssertEqual(NSNumber(double: 0).compare(NSNumber(float: -37.5)), NSComparisonResult.OrderedDescending)
        XCTAssertEqual(NSNumber(double: -37.5).compare(NSNumber(float: 1234.5)), NSComparisonResult.OrderedAscending)
    }
}
