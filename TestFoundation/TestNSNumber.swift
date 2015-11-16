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
    var allTests : [(String, () -> ())] {
        return [
            ("test_NumberWithBool", test_NumberWithBool ),
            ("test_numberWithChar", test_numberWithChar ),
            ("test_numberWithUnsignedChar", test_numberWithUnsignedChar ),
            ("test_numberWithShort", test_numberWithShort ),   
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
}