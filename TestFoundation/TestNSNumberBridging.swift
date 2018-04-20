// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSNumberBridging : XCTestCase {
    static var allTests: [(String, (TestNSNumberBridging) -> () throws -> Void)] {
        return [
            ("testNSNumberBridgeFromInt8", testNSNumberBridgeFromInt8),
            ("testNSNumberBridgeFromUInt8", testNSNumberBridgeFromUInt8),
            ("testNSNumberBridgeFromInt16", testNSNumberBridgeFromInt16),
            ("testNSNumberBridgeFromUInt16", testNSNumberBridgeFromUInt16),
            ("testNSNumberBridgeFromInt32", testNSNumberBridgeFromInt32),
            ("testNSNumberBridgeFromUInt32", testNSNumberBridgeFromUInt32),
            ("testNSNumberBridgeFromInt64", testNSNumberBridgeFromInt64),
            ("testNSNumberBridgeFromUInt64", testNSNumberBridgeFromUInt64),
            ("testNSNumberBridgeFromInt", testNSNumberBridgeFromInt),
            ("testNSNumberBridgeFromUInt", testNSNumberBridgeFromUInt),
            ("testNSNumberBridgeFromFloat", testNSNumberBridgeFromFloat),
            ("testNSNumberBridgeFromDouble", testNSNumberBridgeFromDouble),
            ("test_numericBitPatterns_to_floatingPointTypes", test_numericBitPatterns_to_floatingPointTypes),
            ("testNSNumberBridgeAnyHashable", testNSNumberBridgeAnyHashable),
        ]
    }

    func testFloat(_ lhs: Float?, _ rhs: Float?, file: String = #file, line: UInt = #line) {
        let message = "\(file):\(line) \(String(describing: lhs)) != \(String(describing: rhs)) Float"
        if let lhsValue = lhs {
            if let rhsValue = rhs {
                if lhsValue.isNaN != rhsValue.isNaN {
                    XCTFail(message)
                } else if lhsValue != rhsValue && !lhsValue.isNaN {
                    XCTFail(message)
                }
            } else {
                XCTFail(message)
            }
        } else {
            if rhs != nil {
                XCTFail(message)
            }
        }
    }

    func testDouble(_ lhs: Double?, _ rhs: Double?, file: String = #file, line: UInt = #line) {
        let message = "\(file):\(line) \(String(describing: lhs)) != \(String(describing: rhs)) Double"
        if let lhsValue = lhs {
            if let rhsValue = rhs {
                if lhsValue.isNaN != rhsValue.isNaN {
                    XCTFail(message)
                } else if lhsValue != rhsValue && !lhsValue.isNaN {
                    XCTFail(message)
                }
            } else {
                XCTFail(message)
            }
        } else {
            if rhs != nil {
                XCTFail(message)
            }
        }
    }

    func testNSNumberBridgeFromInt8() {
        for interestingValue in Int8._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)
                let float = Float(exactly: number)
                XCTAssertEqual(Float(interestingValue), float)
                let double = Double(exactly: number)
                XCTAssertEqual(Double(interestingValue), double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromUInt8() {
        for interestingValue in UInt8._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)
                let float = Float(exactly: number)
                XCTAssertEqual(Float(interestingValue), float)
                let double = Double(exactly: number)
                XCTAssertEqual(Double(interestingValue), double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromInt16() {
        for interestingValue in Int16._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)
                let float = Float(exactly: number)
                XCTAssertEqual(Float(interestingValue), float)
                let double = Double(exactly: number)
                XCTAssertEqual(Double(interestingValue), double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromUInt16() {
        for interestingValue in UInt8._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)
                let float = Float(exactly: number)
                XCTAssertEqual(Float(interestingValue), float)
                let double = Double(exactly: number)
                XCTAssertEqual(Double(interestingValue), double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromInt32() {
        for interestingValue in Int32._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)

                let float = Float(exactly: number)
                let expectedFloat = Float(exactly: int32!)
                testFloat(expectedFloat, float)

                let double = Double(exactly: number)
                let expectedDouble = Double(exactly: int32!)
                testDouble(expectedDouble, double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromUInt32() {
        for interestingValue in UInt32._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)

                let float = Float(exactly: number)
                let expectedFloat = Float(exactly: uint32!)
                testFloat(expectedFloat, float)

                let double = Double(exactly: number)
                let expectedDouble = Double(exactly: uint32!)
                testDouble(expectedDouble, double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromInt64() {
        for interestingValue in Int64._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)

                let float = Float(exactly: number)
                let expectedFloat = Float(exactly: int64!)
                testFloat(expectedFloat, float)

                let double = Double(exactly: number)
                let expectedDouble = Double(exactly: int64!)
                testDouble(expectedDouble, double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromUInt64() {
        for interestingValue in UInt64._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)

                let float = Float(exactly: number)
                let expectedFloat = Float(exactly: uint64!)
                testFloat(expectedFloat, float)

                let double = Double(exactly: number)
                let expectedDouble = Double(exactly: uint64!)
                testDouble(expectedDouble, double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromInt() {
        for interestingValue in Int._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)

                let float = Float(exactly: number)
                let expectedFloat = Float(exactly: int!)
                testFloat(expectedFloat, float)

                let double = Double(exactly: number)
                let expectedDouble = Double(exactly: int!)
                testDouble(expectedDouble, double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromUInt() {
        for interestingValue in UInt._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)

                let float = Float(exactly: number)
                let expectedFloat = Float(exactly: uint!)
                testFloat(expectedFloat, float)

                let double = Double(exactly: number)
                let expectedDouble = Double(exactly: uint!)
                testDouble(expectedDouble, double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromFloat() {
        for interestingValue in Float._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)

                let float = Float(exactly: number)
                let expectedFloat = Float(exactly: interestingValue)
                testFloat(expectedFloat, float)
              
                let double = Double(exactly: number)
                let expectedDouble = Double(exactly: interestingValue)
                testDouble(expectedDouble, double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func testNSNumberBridgeFromDouble() {
        for interestingValue in Double._interestingValues {
            func testNumber(_ number: NSNumber) {
                let int8 = Int8(exactly: number)
                XCTAssertEqual(Int8(exactly: interestingValue), int8)
                let uint8 = UInt8(exactly: number)
                XCTAssertEqual(UInt8(exactly: interestingValue), uint8)
                let int16 = Int16(exactly: number)
                XCTAssertEqual(Int16(exactly: interestingValue), int16)
                let uint16 = UInt16(exactly: number)
                XCTAssertEqual(UInt16(exactly: interestingValue), uint16)
                let int32 = Int32(exactly: number)
                XCTAssertEqual(Int32(exactly: interestingValue), int32)
                let uint32 = UInt32(exactly: number)
                XCTAssertEqual(UInt32(exactly: interestingValue), uint32)
                let int64 = Int64(exactly: number)
                XCTAssertEqual(Int64(exactly: interestingValue), int64)
                let uint64 = UInt64(exactly: number)
                XCTAssertEqual(UInt64(exactly: interestingValue), uint64)
                let int = Int(exactly: number)
                XCTAssertEqual(Int(exactly: interestingValue), int)
                let uint = UInt(exactly: number)
                XCTAssertEqual(UInt(exactly: interestingValue), uint)

                let float = Float(exactly: number)
                let expectedFloat = Float(exactly: interestingValue)
                testFloat(expectedFloat, float)
              
                let double = Double(exactly: number)
                let expectedDouble = Double(exactly: interestingValue)
                testDouble(expectedDouble, double)
            }
            let bridged = interestingValue._bridgeToObjectiveC()
            testNumber(bridged)
            let created = NSNumber(value: interestingValue)
            testNumber(created)
        }
    }

    func test_numericBitPatterns_to_floatingPointTypes() {
        let signed_numbers: [NSNumber] = [
            NSNumber(value: Int64(6)),
            NSNumber(value: Int64(bitPattern: 1 << 56)),
            NSNumber(value: Int64(bitPattern: 1 << 53)),
            NSNumber(value: Int64(bitPattern: 1 << 52)),
            NSNumber(value: Int64(bitPattern: 1 << 25)),
            NSNumber(value: Int64(bitPattern: 1 << 24)),
            NSNumber(value: Int64(bitPattern: 1 << 23)),
            NSNumber(value: -Int64(bitPattern: 1 << 53)),
            NSNumber(value: -Int64(bitPattern: 1 << 52)),
            NSNumber(value: -Int64(6)),
            NSNumber(value: -Int64(bitPattern: 1 << 56)),
            NSNumber(value: -Int64(bitPattern: 1 << 25)),
            NSNumber(value: -Int64(bitPattern: 1 << 24)),
            NSNumber(value: -Int64(bitPattern: 1 << 23)),
            ]

        let signed_values: [Int64] = [
            Int64(6),
            Int64(bitPattern: 1 << 56),
            Int64(bitPattern: 1 << 53),
            Int64(bitPattern: 1 << 52),
            Int64(bitPattern: 1 << 25),
            Int64(bitPattern: 1 << 24),
            Int64(bitPattern: 1 << 23),
            -Int64(bitPattern: 1 << 53),
            -Int64(bitPattern: 1 << 52),
            -Int64(6),
            -Int64(bitPattern: 1 << 56),
            -Int64(bitPattern: 1 << 25),
            -Int64(bitPattern: 1 << 24),
            -Int64(bitPattern: 1 << 23),
            ]

        let unsigned_numbers: [NSNumber] = [
            NSNumber(value: UInt64(bitPattern: 6)),
            NSNumber(value: UInt64(bitPattern: 1 << 56)),
            NSNumber(value: UInt64(bitPattern: 1 << 63)),
            NSNumber(value: UInt64(bitPattern: 1 << 53)),
            NSNumber(value: UInt64(bitPattern: 1 << 52)),
            NSNumber(value: UInt64(bitPattern: 1 << 25)),
            NSNumber(value: UInt64(bitPattern: 1 << 24)),
            NSNumber(value: UInt64(bitPattern: 1 << 23)),
            ]

        let unsigned_values: [UInt64] = [
            UInt64(bitPattern: 6),
            UInt64(bitPattern: 1 << 56),
            UInt64(bitPattern: 1 << 63),
            UInt64(bitPattern: 1 << 53),
            UInt64(bitPattern: 1 << 52),
            UInt64(bitPattern: 1 << 25),
            UInt64(bitPattern: 1 << 24),
            UInt64(bitPattern: 1 << 23)
        ]

        for (number, value) in zip(signed_numbers, signed_values) {
            let numberCast = Double(exactly: number)
            let valueCast = Double(exactly: value)
            XCTAssertEqual(numberCast, valueCast)
        }

        for (number, value) in zip(unsigned_numbers, unsigned_values) {
            let numberCast = Double(exactly: number)
            let valueCast = Double(exactly: value)
            XCTAssertEqual(numberCast, valueCast)
        }

        for (number, value) in zip(signed_numbers, signed_values) {
            let numberCast = Float(exactly: number)
            let valueCast = Float(exactly: value)
            XCTAssertEqual(numberCast, valueCast)
        }

        for (number, value) in zip(unsigned_numbers, unsigned_values) {
            let numberCast = Float(exactly: number)
            let valueCast = Float(exactly: value)
            XCTAssertEqual(numberCast, valueCast)
        }
    }

    func testNSNumberBridgeAnyHashable() {
        var dict = [AnyHashable : Any]()
        for i in -Int(UInt8.min) ... Int(UInt8.max) {
            dict[i] = "\(i)"
        }

        // When bridging a dictionary to NSDictionary, we should be able to access
        // the keys through either an Int (the original type boxed in AnyHashable)
        // or NSNumber (the type Int bridged to).
        let ns_dict = dict._bridgeToObjectiveC()
        for i in -Int(UInt8.min) ... Int(UInt8.max) {
            guard let value = ns_dict[i] as? String else {
                XCTFail("Unable to look up value by Int key.")
                continue
            }

            guard let ns_value = ns_dict[NSNumber(value: i)] as? String else {
                XCTFail("Unable to look up value by NSNumber key.")
                continue
            }

            XCTAssertEqual(value, ns_value)
        }
    }
}

extension Float {
    init?(reasonably value: Float) {
        self = value
    }

    init?(reasonably value: Double) {
        guard !value.isNaN else {
            self = Float.nan
            return
        }

        guard !value.isInfinite else {
            if value.sign == .minus {
                self = -Float.infinity
            } else {
                self = Float.infinity
            }
            return
        }

        guard abs(value) <= Double(Float.greatestFiniteMagnitude) else {
            return nil
        }

        self = Float(value)
    }
}

extension Double {
    init?(reasonably value: Float) {
        guard !value.isNaN else {
            self = Double.nan
            return
        }

        guard !value.isInfinite else {
            if value.sign == .minus {
                self = -Double.infinity
            } else {
                self = Double.infinity
            }
            return
        }

        self = Double(value)
    }

    init?(reasonably value: Double) {
        self = value
    }
}

extension Int8 {
    static var _interestingValues: [Int8] {
        return [
            Int8.min,
            Int8.min + 1,
            Int8.max,
            Int8.max - 1,
            0,
            -1,
            1,
            -42,
            42,
        ]
    }
}

extension UInt8 {
    static var _interestingValues: [UInt8] {
        return [
            UInt8.min,
            UInt8.min + 1,
            UInt8.max,
            UInt8.max - 1,
            42,
        ]
    }
}

extension Int16 {
    static var _interestingValues: [Int16] {
        return [
            Int16.min,
            Int16.min + 1,
            Int16.max,
            Int16.max - 1,
            0,
            -1,
            1,
            -42,
            42,
        ]
    }
}

extension UInt16 {
    static var _interestingValues: [UInt16] {
        return [
            UInt16.min,
            UInt16.min + 1,
            UInt16.max,
            UInt16.max - 1,
            42,
        ]
    }
}

extension Int32 {
    static var _interestingValues: [Int32] {
        return [
            Int32.min,
            Int32.min + 1,
            Int32.max,
            Int32.max - 1,
            0,
            -1,
            1,
            -42,
            42,
        ]
    }
}

extension UInt32 {
    static var _interestingValues: [UInt32] {
        return [
            UInt32.min,
            UInt32.min + 1,
            UInt32.max,
            UInt32.max - 1,
            42,
        ]
    }
}

extension Int64 {
    static var _interestingValues: [Int64] {
        return [
            Int64.min,
            Int64.min + 1,
            Int64.max,
            Int64.max - 1,
            0,
            -1,
            1,
            -42,
            42,
        ]
    }
}

extension UInt64 {
    static var _interestingValues: [UInt64] {
        return [
            UInt64.min,
            UInt64.min + 1,
            UInt64.max,
            UInt64.max - 1,
            42,
        ]
    }
}

extension Int {
    static var _interestingValues: [Int] {
        return [
            Int.min,
            Int.min + 1,
            Int.max,
            Int.max - 1,
            0,
            -1,
            1,
            -42,
            42,
        ]
    }
}

extension UInt {
    static var _interestingValues: [UInt] {
        return [
            UInt.min,
            UInt.min + 1,
            UInt.max,
            UInt.max - 1,
            42,
        ]
    }
}

extension Float {
    static var _interestingValues: [Float] {
        return [
            -Float.infinity,
            -Float.greatestFiniteMagnitude,
            -1.0,
            -Float.ulpOfOne,
            -Float.leastNormalMagnitude,
            -0.0,
            0.0,
            Float.leastNormalMagnitude,
            Float.ulpOfOne,
            1.0,
            Float.greatestFiniteMagnitude,
            Float.infinity,
            Float.nan,
        ]
    }
}

extension Double {
    static var _interestingValues: [Double] {
        return [
            -Double.infinity,
            //-Double.greatestFiniteMagnitude,
            -1.0,
            -Double.ulpOfOne,
            -Double.leastNormalMagnitude,
            -0.0,
            0.0,
            Double.leastNormalMagnitude,
            Double.ulpOfOne,
            1.0,
            //Double.greatestFiniteMagnitude,
            Double.infinity,
            Double.nan,
        ]
    }
}
