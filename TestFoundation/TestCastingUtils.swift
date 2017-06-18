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

class TestCastingUtils: XCTestCase {

    static var allTests: [(String, (TestCastingUtils) -> () throws -> Void)] {
        return [
            ("test_castingInt8", test_castingInt8),
            ("test_castingUInt8", test_castingUInt8),
            ("test_castingInt16", test_castingInt16),
            ("test_castingUInt16", test_castingUInt16),
            ("test_castingInt32", test_castingInt32),
            ("test_castingUInt32", test_castingUInt32),
            ("test_castingInt64", test_castingInt64),
            ("test_castingUInt64", test_castingUInt64),
            ("test_castingFloat", test_castingFloat),
            ("test_castingDouble", test_castingDouble),
            ("test_castingBool", test_castingBool),
            ("test_castingInt", test_castingInt),
            ("test_castingUInt", test_castingUInt),
            ("test_castingDecimal", test_castingDecimal),
            ("test_castingNSNumber", test_castingNSNumber),
        ]
    }

    func test_castingInt8() {
        let value: Int8 = 1

        XCTAssertEqual(1 as Int8, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingUInt8() {
        let value: UInt8 = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(1 as UInt8, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingInt16() {
        let value: Int16 = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(1 as Int16, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingUInt16() {
        let value: UInt16 = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(1 as UInt16, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingInt32() {
        let value: Int32 = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(1 as Int32, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingUInt32() {
        let value: UInt32 = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(1 as UInt32, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingInt64() {
        let value: Int64 = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(1 as Int64, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingUInt64() {
        let value: UInt64 = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(1 as UInt64, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingFloat() {
        let value: Float = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(1 as Float, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingDouble() {
        let value: Double = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(1 as Double, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingBool() {
        let value: Bool = true

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(true as Bool, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingInt() {
        let value: Int = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(1 as Int, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingUInt() {
        let value: UInt = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(1 as UInt, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingDecimal() {
        let value: Decimal = 1

        XCTAssertEqual(nil, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Float?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Double?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Int?)
        XCTAssertEqual(nil, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(1 as Decimal, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(NSDecimalNumber(decimal: 1) as NSNumber, platformConsistentCast(value) as NSNumber?)
    }

    func test_castingNSNumber() {
        let value: NSNumber = 1

        XCTAssertEqual(1 as Int8, platformConsistentCast(value) as Int8?)
        XCTAssertEqual(1 as UInt8, platformConsistentCast(value) as UInt8?)
        XCTAssertEqual(1 as Int16, platformConsistentCast(value) as Int16?)
        XCTAssertEqual(1 as UInt16, platformConsistentCast(value) as UInt16?)
        XCTAssertEqual(1 as Int32, platformConsistentCast(value) as Int32?)
        XCTAssertEqual(1 as UInt32, platformConsistentCast(value) as UInt32?)
        XCTAssertEqual(1 as Int64, platformConsistentCast(value) as Int64?)
        XCTAssertEqual(1 as UInt64, platformConsistentCast(value) as UInt64?)
        XCTAssertEqual(1 as Float, platformConsistentCast(value) as Float?)
        XCTAssertEqual(1 as Double, platformConsistentCast(value) as Double?)
        XCTAssertEqual(true as Bool, platformConsistentCast(value) as Bool?)
        XCTAssertEqual(1 as Int, platformConsistentCast(value) as Int?)
        XCTAssertEqual(1 as UInt, platformConsistentCast(value) as UInt?)
        XCTAssertEqual(nil, platformConsistentCast(value) as Decimal?)
        XCTAssertEqual(1 as NSNumber, platformConsistentCast(value) as NSNumber?)
    }
}
