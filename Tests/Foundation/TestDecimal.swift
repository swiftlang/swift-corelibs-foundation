// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_spi(SwiftCorelibsFoundation) import FoundationEssentials

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
        @testable import SwiftFoundation
    #else
        @testable import Foundation
    #endif
#endif

class TestDecimal: XCTestCase {

    func test_NSDecimalNumberInit() {
        XCTAssertEqual(NSDecimalNumber(mantissa: 123456789000, exponent: -2, isNegative: true), -1234567890)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal()).decimalValue, Decimal(0))
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1)).intValue, 1)
        XCTAssertEqual(NSDecimalNumber(string: "1.234").floatValue, 1.234)
        XCTAssertTrue(NSDecimalNumber(string: "invalid").decimalValue.isNaN)
        XCTAssertEqual(NSDecimalNumber(value: true).boolValue, true)
        XCTAssertEqual(NSDecimalNumber(value: false).boolValue, false)
        XCTAssertEqual(NSDecimalNumber(value: Int.min).intValue, Int.min)
        XCTAssertEqual(NSDecimalNumber(value: UInt.min).uintValue, UInt.min)
        XCTAssertEqual(NSDecimalNumber(value: Int8.min).int8Value, Int8.min)
        XCTAssertEqual(NSDecimalNumber(value: UInt8.min).uint8Value, UInt8.min)
        XCTAssertEqual(NSDecimalNumber(value: Int16.min).int16Value, Int16.min)
        XCTAssertEqual(NSDecimalNumber(value: UInt16.min).uint16Value, UInt16.min)
        XCTAssertEqual(NSDecimalNumber(value: Int32.min).int32Value, Int32.min)
        XCTAssertEqual(NSDecimalNumber(value: UInt32.min).uint32Value, UInt32.min)
        XCTAssertEqual(NSDecimalNumber(value: Int64.min).int64Value, Int64.min)
        XCTAssertEqual(NSDecimalNumber(value: UInt64.min).uint64Value, UInt64.min)
        XCTAssertEqual(NSDecimalNumber(value: Float.leastNormalMagnitude).floatValue, Float.leastNormalMagnitude)
        XCTAssertEqual(NSDecimalNumber(value: Float.greatestFiniteMagnitude).floatValue, Float.greatestFiniteMagnitude)
        XCTAssertEqual(NSDecimalNumber(value: Double.pi).doubleValue, Double.pi)
        XCTAssertEqual(NSDecimalNumber(integerLiteral: 0).intValue, 0)
        XCTAssertEqual(NSDecimalNumber(floatLiteral: Double.pi).doubleValue, Double.pi)
        XCTAssertEqual(NSDecimalNumber(booleanLiteral: true).boolValue, true)
        XCTAssertEqual(NSDecimalNumber(booleanLiteral: false).boolValue, false)
    }

    func test_Description() {
        XCTAssertEqual("0", Decimal().description)
        XCTAssertEqual("0", Decimal(0).description)
        XCTAssertEqual("10", Decimal(_exponent: 1, _length: 1, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (1, 0, 0, 0, 0, 0, 0, 0)).description)
        XCTAssertEqual("10", Decimal(10).description)
        XCTAssertEqual("123.458", Decimal(_exponent: -3, _length: 2, _isNegative: 0, _isCompact:1, _reserved: 0, _mantissa: (57922, 1, 0, 0, 0, 0, 0, 0)).description)
        XCTAssertEqual("123.458", Decimal(123.458).description)
        XCTAssertEqual("123", Decimal(UInt8(123)).description)
        XCTAssertEqual("45", Decimal(Int8(45)).description)
        XCTAssertEqual("3.14159265358979323846264338327950288419", Decimal.pi.description)
        XCTAssertEqual("-30000000000", Decimal(sign: .minus, exponent: 10, significand: Decimal(3)).description)
        XCTAssertEqual("300000", Decimal(sign: .plus, exponent: 5, significand: Decimal(3)).description)
        XCTAssertEqual("5", Decimal(signOf: Decimal(3), magnitudeOf: Decimal(5)).description)
        XCTAssertEqual("-5", Decimal(signOf: Decimal(-3), magnitudeOf: Decimal(5)).description)
        XCTAssertEqual("5", Decimal(signOf: Decimal(3), magnitudeOf: Decimal(-5)).description)
        XCTAssertEqual("-5", Decimal(signOf: Decimal(-3), magnitudeOf: Decimal(-5)).description)
        XCTAssertEqual("5", NSDecimalNumber(decimal: Decimal(5)).description)
        XCTAssertEqual("-5", NSDecimalNumber(decimal: Decimal(-5)).description)
        
        // Disabled pending decision about size of Decimal mantissa
        /*
        XCTAssertEqual("3402823669209384634633746074317682114550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", Decimal.greatestFiniteMagnitude.description)
        XCTAssertEqual("0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", Decimal.leastNormalMagnitude.description)
        XCTAssertEqual("0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", Decimal.leastNonzeroMagnitude.description)
         */
        
        let fr = Locale(identifier: "fr_FR")
        let greatestFiniteMagnitude = "3402823669209384634633746074317682114550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

        XCTAssertEqual("0", NSDecimalNumber(decimal: Decimal()).description(withLocale: fr))
        XCTAssertEqual("1000", NSDecimalNumber(decimal: Decimal(1000)).description(withLocale: fr))
        XCTAssertEqual("10", NSDecimalNumber(decimal: Decimal(10)).description(withLocale: fr))
        XCTAssertEqual("123,458", NSDecimalNumber(decimal: Decimal(123.458)).description(withLocale: fr))
        XCTAssertEqual("123", NSDecimalNumber(decimal: Decimal(UInt8(123))).description(withLocale: fr))
        XCTAssertEqual("3,14159265358979323846264338327950288419", NSDecimalNumber(decimal: Decimal.pi).description(withLocale: fr))
        XCTAssertEqual("-30000000000", NSDecimalNumber(decimal: Decimal(sign: .minus, exponent: 10, significand: Decimal(3))).description(withLocale: fr))
        XCTAssertEqual("123456,789", NSDecimalNumber(decimal: Decimal(string: "123456.789")!).description(withLocale: fr))
        
        // Disabled pending decision about size of Decimal mantissa
        /*
        XCTAssertEqual(greatestFiniteMagnitude, NSDecimalNumber(decimal: Decimal.greatestFiniteMagnitude).description(withLocale: fr))
        XCTAssertEqual("0,00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", NSDecimalNumber(decimal: Decimal.leastNormalMagnitude).description(withLocale: fr))
        XCTAssertEqual("0,00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", NSDecimalNumber(decimal: Decimal.leastNonzeroMagnitude).description(withLocale: fr))
         */
        
        let en = Locale(identifier: "en_GB")
        XCTAssertEqual("0", NSDecimalNumber(decimal: Decimal()).description(withLocale: en))
        XCTAssertEqual("1000", NSDecimalNumber(decimal: Decimal(1000)).description(withLocale: en))
        XCTAssertEqual("10", NSDecimalNumber(decimal: Decimal(10)).description(withLocale: en))
        XCTAssertEqual("123.458", NSDecimalNumber(decimal: Decimal(123.458)).description(withLocale: en))
        XCTAssertEqual("123", NSDecimalNumber(decimal: Decimal(UInt8(123))).description(withLocale: en))
        XCTAssertEqual("3.14159265358979323846264338327950288419", NSDecimalNumber(decimal: Decimal.pi).description(withLocale: en))
        XCTAssertEqual("-30000000000", NSDecimalNumber(decimal: Decimal(sign: .minus, exponent: 10, significand: Decimal(3))).description(withLocale: en))
        XCTAssertEqual("123456.789", NSDecimalNumber(decimal: Decimal(string: "123456.789")!).description(withLocale: en))
        
        // Disabled pending decision about size of Decimal mantissa
        /*
        XCTAssertEqual(greatestFiniteMagnitude, NSDecimalNumber(decimal: Decimal.greatestFiniteMagnitude).description(withLocale: en))
        XCTAssertEqual("0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", NSDecimalNumber(decimal: Decimal.leastNormalMagnitude).description(withLocale: en))
        XCTAssertEqual("0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", NSDecimalNumber(decimal: Decimal.leastNonzeroMagnitude).description(withLocale: en))
         */
    }
    
    func test_Maths() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 5538).adding(NSDecimalNumber(floatLiteral: 2880.4)), NSDecimalNumber(floatLiteral: 5538 + 2880.4))
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 5538).subtracting(NSDecimalNumber(floatLiteral: 2880.4)), NSDecimalNumber(floatLiteral: 5538 - 2880.4))
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 2880.4).subtracting(NSDecimalNumber(floatLiteral: 5538)), NSDecimalNumber(floatLiteral: 2880.4 - 5538))
    }

    func test_NSDecimal() throws {
        var nan = Decimal.nan
        XCTAssertTrue(NSDecimalIsNotANumber(&nan))
        var zero = Decimal()
        XCTAssertFalse(NSDecimalIsNotANumber(&zero))
        var three = Decimal(3)
        var guess = Decimal()
        NSDecimalCopy(&guess, &three)
        XCTAssertEqual(three, guess)

        var f = Decimal(_exponent: 0, _length: 2, _isNegative: 0, _isCompact: 0, _reserved: 0, _mantissa: (0x0000, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000))
        let before = f.description
        NSDecimalCompact(&f)
        let after = f.description
        XCTAssertEqual(before, after)

        let nsd1 = NSDecimalNumber(decimal: Decimal(2657.6))
        let nsd2 = NSDecimalNumber(floatLiteral: 2657.6)
        XCTAssertEqual(nsd1, nsd2)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.min)).description, Int8.min.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.max)).description, Int8.max.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt8.min)).description, UInt8.min.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt8.max)).description, UInt8.max.description)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.min)).description, Int16.min.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.max)).description, Int16.max.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt16.min)).description, UInt16.min.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt16.max)).description, UInt16.max.description)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.min)).description, Int32.min.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.max)).description, Int32.max.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.min)).description, UInt32.min.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.max)).description, UInt32.max.description)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.min)).description, Int64.min.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.max)).description, Int64.max.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt64.min)).description, UInt64.min.description)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt64.max)).description, UInt64.max.description)

        XCTAssertEqual(NSDecimalNumber(decimal: try XCTUnwrap(Decimal(string: "12.34"))).description, "12.34")
        XCTAssertEqual(NSDecimalNumber(decimal: try XCTUnwrap(Decimal(string: "0.0001"))).description, "0.0001")
        XCTAssertEqual(NSDecimalNumber(decimal: try XCTUnwrap(Decimal(string: "-1.0002"))).description, "-1.0002")
        XCTAssertEqual(NSDecimalNumber(decimal: try XCTUnwrap(Decimal(string: "0.0"))).description, "0")
    }

    func test_PositivePowers() {
        let six = NSDecimalNumber(integerLiteral: 6)

        XCTAssertEqual(6, six.raising(toPower:1).intValue)
        XCTAssertEqual(36, six.raising(toPower:2).intValue)
        XCTAssertEqual(216, six.raising(toPower:3).intValue)
        XCTAssertEqual(1296, six.raising(toPower:4).intValue)
        XCTAssertEqual(7776, six.raising(toPower:5).intValue)
        XCTAssertEqual(46656, six.raising(toPower:6).intValue)
        XCTAssertEqual(279936, six.raising(toPower:7).intValue)
        XCTAssertEqual(1679616, six.raising(toPower:8).intValue)
        XCTAssertEqual(10077696, six.raising(toPower:9).intValue)

        let negativeSix = NSDecimalNumber(integerLiteral: -6)

        XCTAssertEqual(-6, negativeSix.raising(toPower:1).intValue)
        XCTAssertEqual(36, negativeSix.raising(toPower:2).intValue)
        XCTAssertEqual(-216, negativeSix.raising(toPower:3).intValue)
        XCTAssertEqual(1296, negativeSix.raising(toPower:4).intValue)
        XCTAssertEqual(-7776, negativeSix.raising(toPower:5).intValue)
        XCTAssertEqual(46656, negativeSix.raising(toPower:6).intValue)
        XCTAssertEqual(-279936, negativeSix.raising(toPower:7).intValue)
        XCTAssertEqual(1679616, negativeSix.raising(toPower:8).intValue)
        XCTAssertEqual(-10077696, negativeSix.raising(toPower:9).intValue)
    }

    func test_Round() {
        let testCases: [(Double, Double, Int, NSDecimalNumber.RoundingMode)] = [
            // expected, start, scale, round
            ( 0, 0.5, 0, .down ),
            ( 1, 0.5, 0, .up ),
            ( 2, 2.5, 0, .bankers ),
            ( 4, 3.5, 0, .bankers ),
            ( 5, 5.2, 0, .plain ),
            ( 4.5, 4.5, 1, .down ),
            ( 5.5, 5.5, 1, .up ),
            ( 6.5, 6.5, 1, .plain ),
            ( 7.5, 7.5, 1, .bankers ),

            ( -1, -0.5, 0, .down ),
            ( -2, -2.5, 0, .up ),
            ( -2, -2.5, 0, .bankers ),
            ( -4, -3.5, 0, .bankers ),
            ( -5, -5.2, 0, .plain ),
            ( -4.5, -4.5, 1, .down ),
            ( -5.5, -5.5, 1, .up ),
            ( -6.5, -6.5, 1, .plain ),
            ( -7.5, -7.5, 1, .bankers ),
            ]
        for testCase in testCases {
            let (expected, start, scale, mode) = testCase
            var num = Decimal(start)
            var actual = Decimal(0)
            NSDecimalRound(&actual, &num, scale, mode)
            XCTAssertEqual(Decimal(expected), actual)
            let numnum = NSDecimalNumber(decimal:Decimal(start))
            let behavior = NSDecimalNumberHandler(roundingMode: mode, scale: Int16(scale), raiseOnExactness: false, raiseOnOverflow: true, raiseOnUnderflow: true, raiseOnDivideByZero: true)
            let result = numnum.rounding(accordingToBehavior:behavior)
            XCTAssertEqual(Double(expected), result.doubleValue)
        }
    }

    func test_ScanDecimal() throws {
        let testCases = [
            // expected, value
            ( 123.456e78, "123.456e78" ),
            ( -123.456e78, "-123.456e78" ),
            ( 123.456, " 123.456 " ),
            ( 3.14159, " 3.14159e0" ),
            ( 3.14159, " 3.14159e-0" ),
            ( 0.314159, " 3.14159e-1" ),
            ( 3.14159, " 3.14159e+0" ),
            ( 31.4159, " 3.14159e+1" ),
            ( 12.34, " 01234e-02"),
        ]
        for testCase in testCases {
            let (expected, string) = testCase
            let decimal = try XCTUnwrap(Decimal(string:string))
            let aboutOne = Decimal(expected) / decimal
            let approximatelyRight = aboutOne >= Decimal(0.99999) && aboutOne <= Decimal(1.00001)
            XCTAssertTrue(approximatelyRight, "\(expected) ~= \(decimal) : \(aboutOne) \(aboutOne >= Decimal(0.99999)) \(aboutOne <= Decimal(1.00001))" )
        }
        guard let ones = Decimal(string:"111111111111111111111111111111111111111") else {
            XCTFail("Unable to parse Decimal(string:'111111111111111111111111111111111111111')")
            return
        }
        let num = ones / Decimal(9)
        guard let answer = Decimal(string:"12345679012345679012345679012345679012.3") else {
            XCTFail("Unable to parse Decimal(string:'12345679012345679012345679012345679012.3')")
            return
        }
        XCTAssertEqual(answer,num,"\(ones) / 9 = \(answer) \(num)")

        // Exponent overflow, returns nil
        XCTAssertNil(Decimal(string: "1e200"))
        XCTAssertNil(Decimal(string: "1e-200"))
        XCTAssertNil(Decimal(string: "1e300"))
        XCTAssertNil(Decimal(string: "1" + String(repeating: "0", count: 170)))
        XCTAssertNil(Decimal(string: "0." + String(repeating: "0", count: 170) + "1"))
        XCTAssertNil(Decimal(string: "0e200"))

        // Parsing zero in different forms
        let zero1 = try XCTUnwrap(Decimal(string: "000.000e123"))
        XCTAssertTrue(zero1.isZero)
        XCTAssertEqual(zero1.description, "0")

        let zero2 = try XCTUnwrap(Decimal(string: "+000.000e-123"))
        XCTAssertTrue(zero2.isZero)
        XCTAssertEqual(zero2.description, "0")

        let zero3 = try XCTUnwrap(Decimal(string: "-0.0e1"))
        XCTAssertTrue(zero3.isZero)
        XCTAssertEqual(zero3.description, "0")
    }

    func test_SmallerNumbers() {
        var number = NSDecimalNumber(booleanLiteral:true)
        XCTAssertTrue(number.boolValue, "Should have received true")

        number = NSDecimalNumber(mantissa:0, exponent:0, isNegative:false)
        XCTAssertFalse(number.boolValue, "Should have received false")

        number = NSDecimalNumber(mantissa:1, exponent:0, isNegative:false)
        XCTAssertTrue(number.boolValue, "Should have received true")

        XCTAssertEqual(100,number.objCType.pointee, "ObjC type for NSDecimalNumber is 'd'")
    }

    func test_Strideable() {
        XCTAssertEqual(Decimal(476), Decimal(1024).distance(to: Decimal(1500)))
        XCTAssertEqual(Decimal(68040), Decimal(386).advanced(by: Decimal(67654)))

        let x = 42 as Decimal
        XCTAssertEqual(x.distance(to: 43), 1)
        XCTAssertEqual(x.advanced(by: 1), 43)
        XCTAssertEqual(x.distance(to: 41), -1)
        XCTAssertEqual(x.advanced(by: -1), 41)
    }
    
    func test_ZeroPower() {
        let six = NSDecimalNumber(integerLiteral: 6)
        XCTAssertEqual(1, six.raising(toPower: 0))

        let negativeSix = NSDecimalNumber(integerLiteral: -6)
        XCTAssertEqual(1, negativeSix.raising(toPower: 0))
    }

    func test_parseDouble() throws {
        XCTAssertEqual(Decimal(Double(0.0)), Decimal(Int.zero))
        XCTAssertEqual(Decimal(Double(-0.0)), Decimal(Int.zero))

        // These values can only be represented as Decimal.nan
        XCTAssertEqual(Decimal(Double.nan), Decimal.nan)
        XCTAssertEqual(Decimal(Double.signalingNaN), Decimal.nan)

        // These values are out out range for Decimal
        XCTAssertEqual(Decimal(-Double.leastNonzeroMagnitude), Decimal.nan)
        XCTAssertEqual(Decimal(Double.leastNonzeroMagnitude), Decimal.nan)
        XCTAssertEqual(Decimal(-Double.leastNormalMagnitude), Decimal.nan)
        XCTAssertEqual(Decimal(Double.leastNormalMagnitude), Decimal.nan)
        XCTAssertEqual(Decimal(-Double.greatestFiniteMagnitude), Decimal.nan)
        XCTAssertEqual(Decimal(Double.greatestFiniteMagnitude), Decimal.nan)

        // SR-13837
        let testDoubles: [(Double, String)] = [
            (1.8446744073709550E18, "1844674407370954752"),
            (1.8446744073709551E18, "1844674407370954752"),
            (1.8446744073709552E18, "1844674407370955264"),
            (1.8446744073709553E18, "1844674407370955264"),
            (1.8446744073709554E18, "1844674407370955520"),
            (1.8446744073709555E18, "1844674407370955520"),

            (1.8446744073709550E19, "18446744073709547520"),
            (1.8446744073709551E19, "18446744073709552640"),
            (1.8446744073709552E19, "18446744073709552640"),
            (1.8446744073709553E19, "18446744073709552640"),
            (1.8446744073709554E19, "18446744073709555200"),
            (1.8446744073709555E19, "18446744073709555200"),

            (1.8446744073709550E20, "184467440737095526400"),
            (1.8446744073709551E20, "184467440737095526400"),
            (1.8446744073709552E20, "184467440737095526400"),
            (1.8446744073709553E20, "184467440737095526400"),
            (1.8446744073709554E20, "184467440737095552000"),
            (1.8446744073709555E20, "184467440737095552000"),
        ]

        for (d, s) in testDoubles {
            XCTAssertEqual(Decimal(d), Decimal(string: s))
            XCTAssertEqual(Decimal(d).description, try XCTUnwrap(Decimal(string: s)).description)
        }
    }

    func test_doubleValue() {
        XCTAssertEqual(NSDecimalNumber(decimal:Decimal(0)).doubleValue, 0)
        XCTAssertEqual(NSDecimalNumber(decimal:Decimal(1)).doubleValue, 1)
        XCTAssertEqual(NSDecimalNumber(decimal:Decimal(-1)).doubleValue, -1)
        XCTAssertTrue(NSDecimalNumber(decimal:Decimal.nan).doubleValue.isNaN)
        XCTAssertEqual(NSDecimalNumber(decimal:Decimal(UInt64.max)).doubleValue, Double(1.8446744073709552e+19))
        XCTAssertEqual(NSDecimalNumber(decimal:Decimal(string: "1234567890123456789012345678901234567890")!).doubleValue, Double(1.2345678901234568e+39))

        // The result of the subtractions can leave values in the internal mantissa of a and b,
        // although _length = 0 which is correct.
        let x = Decimal(10.5)
        let y = Decimal(9.0)
        let z = Decimal(1.5)
        let a = x - y - z
        let b = x - z - y

        XCTAssertEqual(x.description, "10.5")
        XCTAssertEqual(y.description, "9")
        XCTAssertEqual(z.description, "1.5")
        XCTAssertEqual(a.description, "0")
        XCTAssertEqual(b.description, "0")
        XCTAssertEqual(NSDecimalNumber(decimal: x).doubleValue, 10.5)
        XCTAssertEqual(NSDecimalNumber(decimal: y).doubleValue, 9.0)
        XCTAssertEqual(NSDecimalNumber(decimal: z).doubleValue, 1.5)
        XCTAssertEqual(NSDecimalNumber(decimal: a).doubleValue, 0.0)
        XCTAssertEqual(NSDecimalNumber(decimal: b).doubleValue, 0.0)

        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 2
        nf.maximumFractionDigits = 2

        XCTAssertEqual(nf.string(from: NSDecimalNumber(decimal: x)), "10.50")
        XCTAssertEqual(nf.string(from: NSDecimalNumber(decimal: y)), "9.00")
        XCTAssertEqual(nf.string(from: NSDecimalNumber(decimal: z)), "1.50")
        XCTAssertEqual(nf.string(from: NSDecimalNumber(decimal: a)), "0.00")
        XCTAssertEqual(nf.string(from: NSDecimalNumber(decimal: b)), "0.00")
    }

    func test_NSDecimalNumberValues() {
        let uint64MaxDecimal = Decimal(string: UInt64.max.description)!

        // int8Value
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(0)).int8Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-1)).int8Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1)).int8Value, 1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-129)).int8Value, 127)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(128)).int8Value, -128)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.min)).int8Value, Int8.min)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.min)).int8Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.min)).int8Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.min)).int8Value, 0)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.max)).int8Value, Int8.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.max)).int8Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.max)).int8Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.max)).int8Value, -1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt8.max)).int8Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt16.max)).int8Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.max)).int8Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: uint64MaxDecimal).int8Value, -1)

        // uint8Value
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(0)).uint8Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-1)).uint8Value, UInt8.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1)).uint8Value, 1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-129)).uint8Value, 127)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(128)).uint8Value, 128)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(256)).uint8Value, 0)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.min)).uint8Value, 128)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.min)).uint8Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.min)).uint8Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.min)).uint8Value, 0)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.max)).uint8Value, 127)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.max)).uint8Value, UInt8.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.max)).uint8Value, UInt8.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.max)).uint8Value, UInt8.max)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt8.max)).uint8Value, UInt8.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt16.max)).uint8Value, UInt8.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.max)).uint8Value, UInt8.max)
        XCTAssertEqual(NSDecimalNumber(decimal: uint64MaxDecimal).uint8Value, UInt8.max)

        // int16Value
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(0)).int16Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-1)).int16Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1)).int16Value, 1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-32769)).int16Value, 32767)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(32768)).int16Value, -32768)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.min)).int16Value, -128)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.min)).int16Value, Int16.min)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.min)).int16Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.min)).int16Value, 0)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.max)).int16Value, 127)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.max)).int16Value, Int16.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.max)).int16Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.max)).int16Value, -1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt8.max)).int16Value, 255)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt16.max)).int16Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.max)).int16Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: uint64MaxDecimal).int16Value, -1)

        // uint16Value
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(0)).uint16Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-1)).uint16Value, UInt16.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1)).uint16Value, 1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-32769)).uint16Value, 32767)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(32768)).uint16Value, 32768)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(65536)).uint16Value, 0)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.min)).uint16Value, 65408)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.min)).uint16Value, 32768)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.min)).uint16Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.min)).uint16Value, 0)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.max)).uint16Value, 127)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.max)).uint16Value, 32767)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.max)).uint16Value, UInt16.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.max)).uint16Value, UInt16.max)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt8.max)).uint16Value, 255)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt16.max)).uint16Value, UInt16.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.max)).uint16Value, UInt16.max)
        XCTAssertEqual(NSDecimalNumber(decimal: uint64MaxDecimal).uint16Value, UInt16.max)

        // int32Value
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(0)).int32Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-1)).int32Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1)).int32Value, 1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-32769)).int32Value, -32769)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(32768)).int32Value, 32768)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.min)).int32Value, -128)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.min)).int32Value, -32768)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.min)).int32Value, Int32.min)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.min)).int32Value, 0)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.max)).int32Value, 127)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.max)).int32Value, 32767)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.max)).int32Value, Int32.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.max)).int32Value, -1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt8.max)).int32Value, 255)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt16.max)).int32Value, 65535)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.max)).int32Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: uint64MaxDecimal).int32Value, -1)

        // uint32Value
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(0)).uint32Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-1)).uint32Value, UInt32.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1)).uint32Value, 1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-32769)).uint32Value, 4294934527)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(32768)).uint32Value, 32768)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(65536)).uint32Value, 65536)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.min)).uint32Value, 4294967168)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.min)).uint32Value, 4294934528)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.min)).uint32Value, 2147483648)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.min)).uint32Value, 0)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.max)).uint32Value, 127)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.max)).uint32Value, 32767)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.max)).uint32Value, UInt32(Int32.max))
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.max)).uint32Value, UInt32.max)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt8.max)).uint32Value, 255)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt16.max)).uint32Value, 65535)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.max)).uint32Value, UInt32.max)
        XCTAssertEqual(NSDecimalNumber(decimal: uint64MaxDecimal).uint32Value, UInt32.max)

        // int64Value
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(0)).int64Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-1)).int64Value, -1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1)).int64Value, 1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-32769)).int64Value, -32769)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(32768)).int64Value, 32768)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.min)).int64Value, -128)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.min)).int64Value, -32768)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.min)).int64Value, -2147483648)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.min)).int64Value, Int64.min)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.max)).int64Value, 127)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.max)).int64Value, 32767)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.max)).int64Value, 2147483647)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.max)).int64Value, Int64.max)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt8.max)).int64Value, 255)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt16.max)).int64Value, 65535)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.max)).int64Value, 4294967295)
        XCTAssertEqual(NSDecimalNumber(decimal: uint64MaxDecimal).int64Value, -1)

        // uint64Value
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(0)).uint64Value, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-1)).uint64Value, UInt64.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1)).uint64Value, 1)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(-32769)).uint64Value, 18446744073709518847)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(32768)).uint64Value, 32768)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(65536)).uint64Value, 65536)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.min)).uint64Value, 18446744073709551488)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.min)).uint64Value, 18446744073709518848)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.min)).uint64Value, 18446744071562067968)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.min)).uint64Value, 9223372036854775808)

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int8.max)).uint64Value, 127)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int16.max)).uint64Value, 32767)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.max)).uint64Value, UInt64(Int32.max))
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.max)).uint64Value, UInt64(Int64.max))

        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt8.max)).uint64Value, 255)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt16.max)).uint64Value, 65535)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.max)).uint64Value, 4294967295)
        XCTAssertEqual(NSDecimalNumber(decimal: uint64MaxDecimal).uint64Value, UInt64.max)
    }

    func test_bridging() {
        let d1 = Decimal(1)
        let nsd1 = d1 as NSDecimalNumber
        XCTAssertEqual(nsd1 as Decimal, d1)

        let d2 = nsd1 as Decimal
        XCTAssertEqual(d1, d2)

        let ns = d1 as NSNumber
        XCTAssertTrue(type(of: ns) == NSDecimalNumber.self)

        // NSNumber does NOT bridge to Decimal
        XCTAssertNil(NSNumber(value: 1) as? Decimal)
    }

    func test_multiplyingByPowerOf10() {
        let decimalNumber = NSDecimalNumber(string: "0.022829306361065572")
        let d1 = decimalNumber.multiplying(byPowerOf10: 18)
        XCTAssertEqual(d1.stringValue, "22829306361065572")
        let d2 = d1.multiplying(byPowerOf10: -18)
        XCTAssertEqual(d2.stringValue, "0.022829306361065572")

        XCTAssertEqual(NSDecimalNumber(string: "0.01").multiplying(byPowerOf10: 0).stringValue, "0.01")
        XCTAssertEqual(NSDecimalNumber(string: "0.01").multiplying(byPowerOf10: 1).stringValue, "0.1")
        XCTAssertEqual(NSDecimalNumber(string: "0.01").multiplying(byPowerOf10: -1).stringValue, "0.001")
        XCTAssertEqual(NSDecimalNumber(value: 0).multiplying(byPowerOf10: 0).stringValue, "0")
        XCTAssertEqual(NSDecimalNumber(value: 0).multiplying(byPowerOf10: -1).stringValue, "0")
        XCTAssertEqual(NSDecimalNumber(value: 0).multiplying(byPowerOf10: 1).stringValue, "0")

        XCTAssertEqual(NSDecimalNumber(value: 1).multiplying(byPowerOf10: 128).stringValue, "NaN")
        XCTAssertEqual(NSDecimalNumber(value: 1).multiplying(byPowerOf10: 127).stringValue, "10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000")
        XCTAssertEqual(NSDecimalNumber(value: 1).multiplying(byPowerOf10: -128).stringValue, "0.00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001")
        XCTAssertEqual(NSDecimalNumber(value: 1).multiplying(byPowerOf10: -129).stringValue, "NaN")
    }

    func test_NSNumberEquality() {

        let values = [
            (NSNumber(value: Int.min), NSDecimalNumber(decimal: Decimal(Int.min))),
            (NSNumber(value: Int.max), NSDecimalNumber(decimal: Decimal(Int.max))),
            (NSNumber(value: Double(1.1)), NSDecimalNumber(decimal: Decimal(Double(1.1)))),
            (NSNumber(value: Float(-1.0)), NSDecimalNumber(decimal: Decimal(-1))),
            (NSNumber(value: Int8(1)), NSDecimalNumber(decimal: Decimal(1))),
            (NSNumber(value: UInt8.max), NSDecimalNumber(decimal: Decimal(255))),
            (NSNumber(value: Int16.min), NSDecimalNumber(decimal: Decimal(-32768))),
        ]

        for pair in values {
            let number = pair.0
            let decimalNumber = pair.1

            XCTAssertEqual(number.compare(decimalNumber), .orderedSame)
            XCTAssertTrue(number.isEqual(to: decimalNumber))
            XCTAssertEqual(number, decimalNumber)

            XCTAssertEqual(decimalNumber.compare(number), .orderedSame)
            XCTAssertTrue(decimalNumber.isEqual(to: number))
            XCTAssertEqual(decimalNumber, number)
        }
    }

    func test_intValue() {
        // SR-7236
        XCTAssertEqual(NSDecimalNumber(value: -1).intValue, -1)
        XCTAssertEqual(NSDecimalNumber(value: 0).intValue, 0)
        XCTAssertEqual(NSDecimalNumber(value: 1).intValue, 1)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal.nan).intValue, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1e50)).intValue, 0)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(1e-50)).intValue, 0)

        XCTAssertEqual(NSDecimalNumber(value: UInt64.max).uint64Value, UInt64.max)
        XCTAssertEqual(NSDecimalNumber(value: UInt64.max).adding(1).uint64Value, 0)
        XCTAssertEqual(NSDecimalNumber(value: Int64.max).int64Value, Int64.max)
        XCTAssertEqual(NSDecimalNumber(value: Int64.max).adding(1).int64Value, Int64.min)
        XCTAssertEqual(NSDecimalNumber(value: Int64.max).adding(1).uint64Value, UInt64(Int64.max) + 1)
        XCTAssertEqual(NSDecimalNumber(value: Int64.min).int64Value, Int64.min)

        XCTAssertEqual(NSDecimalNumber(value: 10).dividing(by: 3).intValue, 3)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Double.pi)).intValue, 3)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int.max)).intValue, Int.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.max)).int32Value, Int32.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.max)).int64Value, Int64.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int.min)).intValue, Int.min)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int32.min)).int32Value, Int32.min)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(Int64.min)).int64Value, Int64.min)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt.max)).uintValue, UInt.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt32.max)).uint32Value, UInt32.max)
        XCTAssertEqual(NSDecimalNumber(decimal: Decimal(UInt64.max)).uint64Value, UInt64.max)


        // SR-2980
        let sr2980Tests = [
            ("250.229953885078403", 250),
            ("103.8097165991902834008097165991902834", 103),
            ("31.541176470588235294", 31),
            ("12345.12345678901234", 12345),
            ("12345.123456789012345", 12345),
        ]

        for (string, value) in sr2980Tests {
            let decimalValue = NSDecimalNumber(string: string)
            XCTAssertEqual(decimalValue.intValue, value)
            XCTAssertEqual(decimalValue.int8Value, Int8(truncatingIfNeeded: value))
            XCTAssertEqual(decimalValue.int16Value, Int16(value))
            XCTAssertEqual(decimalValue.int32Value, Int32(value))
            XCTAssertEqual(decimalValue.int64Value, Int64(value))
            XCTAssertEqual(decimalValue.uintValue, UInt(value))
            XCTAssertEqual(decimalValue.uint8Value, UInt8(truncatingIfNeeded: value))
            XCTAssertEqual(decimalValue.uint16Value, UInt16(value))
            XCTAssertEqual(decimalValue.uint32Value, UInt32(value))
            XCTAssertEqual(decimalValue.uint64Value, UInt64(value))
        }

        // Large mantissas, negative exponent
        let maxMantissa = (UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max)

        let tests = [
            (-34, 0, "34028.2366920938463463374607431768211455", 34028),
            (-35, 0, "3402.82366920938463463374607431768211455", 3402),
            (-36, 0, "340.282366920938463463374607431768211455", 340),
            (-37, 0, "34.0282366920938463463374607431768211455", 34),
            (-38, 0, "3.40282366920938463463374607431768211455", 3),
            (-39, 0, "0.340282366920938463463374607431768211455", 0),
            (-34, 1, "-34028.2366920938463463374607431768211455", -34028),
            (-35, 1, "-3402.82366920938463463374607431768211455", -3402),
            (-36, 1, "-340.282366920938463463374607431768211455", -340),
            (-37, 1, "-34.0282366920938463463374607431768211455", -34),
            (-38, 1, "-3.40282366920938463463374607431768211455", -3),
            (-39, 1, "-0.340282366920938463463374607431768211455", 0),
        ]

        for (exponent, isNegative, description, intValue) in tests {
            let d = Decimal(_exponent: Int32(exponent), _length: 8, _isNegative: UInt32(isNegative), _isCompact: 1, _reserved: 0, _mantissa: maxMantissa)
            XCTAssertEqual(d.description, description)
            XCTAssertEqual(NSDecimalNumber(decimal:d).intValue, intValue)
        }
    }
}
