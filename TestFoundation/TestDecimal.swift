// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestDecimal: XCTestCase {

    static var allTests : [(String, (TestDecimal) -> () throws -> Void)] {
        return [
            ("test_NSDecimalNumberInit", test_NSDecimalNumberInit),
            ("test_AdditionWithNormalization", test_AdditionWithNormalization),
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_Constants", test_Constants),
            ("test_Description", test_Description),
            ("test_ExplicitConstruction", test_ExplicitConstruction),
            ("test_Maths", test_Maths),
            ("test_Misc", test_Misc),
            ("test_MultiplicationOverflow", test_MultiplicationOverflow),
            ("test_NaNInput", test_NaNInput),
            ("test_NegativeAndZeroMultiplication", test_NegativeAndZeroMultiplication),
            ("test_Normalise", test_Normalise),
            ("test_NSDecimal", test_NSDecimal),
            ("test_PositivePowers", test_PositivePowers),
            ("test_RepeatingDivision", test_RepeatingDivision),
            ("test_Round", test_Round),
            ("test_ScanDecimal", test_ScanDecimal),
            ("test_SimpleMultiplication", test_SimpleMultiplication),
            ("test_SmallerNumbers", test_SmallerNumbers),
            ("test_ZeroPower", test_ZeroPower),
        ]
    }

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

    func test_AdditionWithNormalization() {

        let biggie = Decimal(65536)
        let smallee = Decimal(65536)
        let answer = biggie/smallee
        XCTAssertEqual(Decimal(1),answer)

        var one = Decimal(1)
        var addend = Decimal(1)
        var expected = Decimal()
        var result = Decimal()

        expected._isNegative = 0;
        expected._isCompact = 0;

        // 2 digits -- certain to work
        addend._exponent = -1;
        XCTAssertEqual(.noError, NSDecimalAdd(&result, &one, &addend, .plain), "1 + 0.1")
        expected._exponent = -1;
        expected._length = 1;
        expected._mantissa.0 = 11;
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&expected, &result), "1.1 == 1 + 0.1")

        // 38 digits -- guaranteed by NSDecimal to work
        addend._exponent = -37;
        XCTAssertEqual(.noError, NSDecimalAdd(&result, &one, &addend, .plain), "1 + 1e-37")
        expected._exponent = -37;
        expected._length = 8;
        expected._mantissa.0 = 0x0001;
        expected._mantissa.1 = 0x0000;
        expected._mantissa.2 = 0x36a0;
        expected._mantissa.3 = 0x00f4;
        expected._mantissa.4 = 0x46d9;
        expected._mantissa.5 = 0xd5da;
        expected._mantissa.6 = 0xee10;
        expected._mantissa.7 = 0x0785;
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&expected, &result), "1 + 1e-37")

        // 39 digits -- not guaranteed to work but it happens to, so we make the test work either way
        addend._exponent = -38;
        let error = NSDecimalAdd(&result, &one, &addend, .plain)
        XCTAssertTrue(error == .noError || error == .lossOfPrecision, "1 + 1e-38")
        if error == .noError {
            expected._exponent = -38;
            expected._length = 8;
            expected._mantissa.0 = 0x0001;
            expected._mantissa.1 = 0x0000;
            expected._mantissa.2 = 0x2240;
            expected._mantissa.3 = 0x098a;
            expected._mantissa.4 = 0xc47a;
            expected._mantissa.5 = 0x5a86;
            expected._mantissa.6 = 0x4ca8;
            expected._mantissa.7 = 0x4b3b;
            XCTAssertEqual(.orderedSame, NSDecimalCompare(&expected, &result), "1 + 1e-38")
        } else {
            XCTAssertEqual(.orderedSame, NSDecimalCompare(&one, &result), "1 + 1e-38")
        }

        // 40 digits -- doesn't work; need to make sure it's rounding for us
        addend._exponent = -39;
        XCTAssertEqual(.lossOfPrecision, NSDecimalAdd(&result, &one, &addend, .plain), "1 + 1e-39")
        XCTAssertEqual("1", result.description)
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&one, &result), "1 + 1e-39")
    }

    func test_BasicConstruction() {
        let zero = Decimal()
        XCTAssertEqual(20, MemoryLayout<Decimal>.size)
        XCTAssertEqual(0, zero._exponent)
        XCTAssertEqual(0, zero._length)
        XCTAssertEqual(0, zero._isNegative)
        XCTAssertEqual(0, zero._isCompact)
        XCTAssertEqual(0, zero._reserved)
        let (m0, m1, m2, m3, m4, m5, m6, m7) = zero._mantissa
        XCTAssertEqual(0, m0)
        XCTAssertEqual(0, m1)
        XCTAssertEqual(0, m2)
        XCTAssertEqual(0, m3)
        XCTAssertEqual(0, m4)
        XCTAssertEqual(0, m5)
        XCTAssertEqual(0, m6)
        XCTAssertEqual(0, m7)
        XCTAssertEqual(8, NSDecimalMaxSize)
        XCTAssertEqual(32767, NSDecimalNoScale)
        XCTAssertFalse(zero.isNormal)
        XCTAssertTrue(zero.isFinite)
        XCTAssertTrue(zero.isZero)
        XCTAssertFalse(zero.isSubnormal)
        XCTAssertFalse(zero.isInfinite)
        XCTAssertFalse(zero.isNaN)
        XCTAssertFalse(zero.isSignaling)

        let d1 = Decimal(1234567890123456789 as UInt64)
        XCTAssertEqual(d1._exponent, 0)
        XCTAssertEqual(d1._length, 4)
    }
    func test_Constants() {
        XCTAssertEqual(8, NSDecimalMaxSize)
        XCTAssertEqual(32767, NSDecimalNoScale)
        let smallest = Decimal(_exponent: 127, _length: 8, _isNegative: 1, _isCompact: 1, _reserved: 0, _mantissa: (UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max))
        XCTAssertEqual(smallest, Decimal.leastFiniteMagnitude)
        let biggest = Decimal(_exponent: 127, _length: 8, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max))
        XCTAssertEqual(biggest, Decimal.greatestFiniteMagnitude)
        let leastNormal = Decimal(_exponent: -127, _length: 1, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (1, 0, 0, 0, 0, 0, 0, 0))
        XCTAssertEqual(leastNormal, Decimal.leastNormalMagnitude)
        let leastNonzero = Decimal(_exponent: -127, _length: 1, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (1, 0, 0, 0, 0, 0, 0, 0))
        XCTAssertEqual(leastNonzero, Decimal.leastNonzeroMagnitude)
        let pi = Decimal(_exponent: -38, _length: 8, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (0x6623, 0x7d57, 0x16e7, 0xad0d, 0xaf52, 0x4641, 0xdfa7, 0xec58))
        XCTAssertEqual(pi, Decimal.pi)
        XCTAssertEqual(10, Decimal.radix)
        XCTAssertTrue(Decimal().isCanonical)
        XCTAssertFalse(Decimal().isSignalingNaN)
        XCTAssertFalse(Decimal.nan.isSignalingNaN)
        XCTAssertTrue(Decimal.nan.isNaN)
        XCTAssertEqual(.quietNaN, Decimal.nan.floatingPointClass)
        XCTAssertEqual(.positiveZero, Decimal().floatingPointClass)
        XCTAssertEqual(.negativeNormal, smallest.floatingPointClass)
        XCTAssertEqual(.positiveNormal, biggest.floatingPointClass)
        XCTAssertFalse(Double.nan.isFinite)
        XCTAssertFalse(Double.nan.isInfinite)
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
        XCTAssertEqual("5", NSDecimalNumber(decimal:Decimal(5)).description)
        XCTAssertEqual("-5", NSDecimalNumber(decimal:Decimal(-5)).description)
    }

    func test_ExplicitConstruction() {
        let reserved: UInt32 = (1<<18 as UInt32) + (1<<17 as UInt32) + 1
        let mantissa: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16) = (6, 7, 8, 9, 10, 11, 12, 13)
        var explicit = Decimal(
            _exponent: 0x17f,
            _length: 0xff,
            _isNegative: 3,
            _isCompact: 4,
            _reserved: reserved,
            _mantissa: mantissa
        )
        XCTAssertEqual(0x7f, explicit._exponent)
        XCTAssertEqual(0x7f, explicit.exponent)
        XCTAssertEqual(0x0f, explicit._length)
        XCTAssertEqual(1, explicit._isNegative)
        XCTAssertEqual(FloatingPointSign.minus, explicit.sign)
        XCTAssertTrue(explicit.isSignMinus)
        XCTAssertEqual(0, explicit._isCompact)
        let i = 1 << 17 + 1
        let expectedReserved: UInt32 = UInt32(i)
        XCTAssertEqual(expectedReserved, explicit._reserved)
        let (m0, m1, m2, m3, m4, m5, m6, m7) = explicit._mantissa
        XCTAssertEqual(6, m0)
        XCTAssertEqual(7, m1)
        XCTAssertEqual(8, m2)
        XCTAssertEqual(9, m3)
        XCTAssertEqual(10, m4)
        XCTAssertEqual(11, m5)
        XCTAssertEqual(12, m6)
        XCTAssertEqual(13, m7)
        explicit._isCompact = 5
        explicit._isNegative = 6
        XCTAssertEqual(0, explicit._isNegative)
        XCTAssertEqual(1, explicit._isCompact)
        XCTAssertEqual(FloatingPointSign.plus, explicit.sign)
        XCTAssertFalse(explicit.isSignMinus)
        XCTAssertTrue(explicit.isNormal)

        let significand = explicit.significand
        XCTAssertEqual(0, significand._exponent)
        XCTAssertEqual(0, significand.exponent)
        XCTAssertEqual(0x0f, significand._length)
        XCTAssertEqual(0, significand._isNegative)
        XCTAssertEqual(1, significand._isCompact)
        XCTAssertEqual(0, significand._reserved)
        let (sm0, sm1, sm2, sm3, sm4, sm5, sm6, sm7) = significand._mantissa
        XCTAssertEqual(6, sm0)
        XCTAssertEqual(7, sm1)
        XCTAssertEqual(8, sm2)
        XCTAssertEqual(9, sm3)
        XCTAssertEqual(10, sm4)
        XCTAssertEqual(11, sm5)
        XCTAssertEqual(12, sm6)
        XCTAssertEqual(13, sm7)

        let ulp = explicit.ulp
        XCTAssertEqual(0x7f, ulp.exponent)
        XCTAssertEqual(8, ulp._length)
        XCTAssertEqual(0, ulp._isNegative)
        XCTAssertEqual(1, ulp._isCompact)
        XCTAssertEqual(0, ulp._reserved)
        XCTAssertEqual(1, ulp._mantissa.0)
        XCTAssertEqual(0, ulp._mantissa.1)
        XCTAssertEqual(0, ulp._mantissa.2)
        XCTAssertEqual(0, ulp._mantissa.3)
        XCTAssertEqual(0, ulp._mantissa.4)
        XCTAssertEqual(0, ulp._mantissa.5)
        XCTAssertEqual(0, ulp._mantissa.6)
        XCTAssertEqual(0, ulp._mantissa.7)
    }

    func test_Maths() {
        for i in -2...10 {
            for j in 0...5 {
                XCTAssertEqual(Decimal(i*j), Decimal(i) * Decimal(j), "\(Decimal(i*j)) == \(i) * \(j)")
                XCTAssertEqual(Decimal(i+j), Decimal(i) + Decimal(j), "\(Decimal(i+j)) == \(i)+\(j)")
                XCTAssertEqual(Decimal(i-j), Decimal(i) - Decimal(j), "\(Decimal(i-j)) == \(i)-\(j)")
                if j != 0 {
                    let approximation = Decimal(Double(i)/Double(j))
                    let answer = Decimal(i) / Decimal(j)
                    let answerDescription = answer.description
                    let approximationDescription = approximation.description
                    var failed: Bool = false
                    var count = 0
                    let SIG_FIG = 14
                    for (a, b) in zip(answerDescription, approximationDescription) {
                        if a != b {
                            failed = true
                            break
                        }
                        if count == 0 && (a == "-" || a == "0" || a == ".") {
                            continue // don't count these as significant figures
                        }
                        if count >= SIG_FIG {
                            break
                        }
                        count += 1
                    }
                    XCTAssertFalse(failed, "\(Decimal(i/j)) == \(i)/\(j)")
                }
            }
        }

        XCTAssertEqual(Decimal(186243 * 15673 as Int64), Decimal(186243) * Decimal(15673))

        XCTAssertEqual(Decimal(string: "5538")! + Decimal(string: "2880.4")!, Decimal(string: "8418.4")!)
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 5538).adding(NSDecimalNumber(floatLiteral: 2880.4)), NSDecimalNumber(floatLiteral: 5538 + 2880.4))

        XCTAssertEqual(Decimal(string: "5538.0")! - Decimal(string: "2880.4")!, Decimal(string: "2657.6")!)
        XCTAssertEqual(Decimal(string: "2880.4")! - Decimal(5538), Decimal(string: "-2657.6")!)
        XCTAssertEqual(Decimal(0x10000) - Decimal(0x1000), Decimal(0xf000))
        XCTAssertEqual(Decimal(0x1_0000_0000) - Decimal(0x1000), Decimal(0xFFFFF000))
        XCTAssertEqual(Decimal(0x1_0000_0000_0000) - Decimal(0x1000), Decimal(0xFFFFFFFFF000))
        XCTAssertEqual(Decimal(1234_5678_9012_3456_7899 as UInt64) - Decimal(1234_5678_9012_3456_7890 as UInt64), Decimal(9))
        XCTAssertEqual(Decimal(0xffdd_bb00_8866_4422 as UInt64) - Decimal(0x7777_7777), Decimal(0xFFDD_BB00_10EE_CCAB as UInt64))
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 5538).subtracting(NSDecimalNumber(floatLiteral: 2880.4)), NSDecimalNumber(floatLiteral: 5538 - 2880.4))
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 2880.4).subtracting(NSDecimalNumber(floatLiteral: 5538)), NSDecimalNumber(floatLiteral: 2880.4 - 5538))

        XCTAssertEqual(Decimal.greatestFiniteMagnitude - Decimal.greatestFiniteMagnitude, Decimal(0))
        XCTAssertEqual(Decimal.leastFiniteMagnitude - Decimal(1), Decimal.leastFiniteMagnitude)
        let overflowed = Decimal.greatestFiniteMagnitude + Decimal.greatestFiniteMagnitude
        XCTAssertTrue(overflowed.isNaN)

        let highBit = Decimal(_exponent: 0, _length: 8, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x8000))
        let otherBits = Decimal(_exponent: 0, _length: 8, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0x7fff))
        XCTAssertEqual(highBit - otherBits, Decimal(1))
        XCTAssertEqual(otherBits + Decimal(1), highBit)
    }

    func test_Misc() {
        XCTAssertEqual(.minus, Decimal(-5.2).sign)
        XCTAssertEqual(.plus, Decimal(5.2).sign)
        var d = Decimal(5.2)
        XCTAssertEqual(.plus, d.sign)
        d.negate()
        XCTAssertEqual(.minus, d.sign)
        d.negate()
        XCTAssertEqual(.plus, d.sign)
        var e = Decimal(0)
        e.negate()
        XCTAssertEqual(e, 0)
        XCTAssertTrue(Decimal(3.5).isEqual(to: Decimal(3.5)))
        XCTAssertTrue(Decimal.nan.isEqual(to: Decimal.nan))
        XCTAssertTrue(Decimal(1.28).isLess(than: Decimal(2.24)))
        XCTAssertFalse(Decimal(2.28).isLess(than: Decimal(2.24)))
        XCTAssertTrue(Decimal(1.28).isTotallyOrdered(belowOrEqualTo: Decimal(2.24)))
        XCTAssertFalse(Decimal(2.28).isTotallyOrdered(belowOrEqualTo: Decimal(2.24)))
        XCTAssertTrue(Decimal(1.2).isTotallyOrdered(belowOrEqualTo: Decimal(1.2)))
        XCTAssertTrue(Decimal.nan.isEqual(to: Decimal.nan))
        XCTAssertTrue(Decimal.nan.isLess(than: Decimal(0)))
        XCTAssertFalse(Decimal.nan.isLess(than: Decimal.nan))
        XCTAssertTrue(Decimal.nan.isLessThanOrEqualTo(Decimal(0)))
        XCTAssertTrue(Decimal.nan.isLessThanOrEqualTo(Decimal.nan))
        XCTAssertFalse(Decimal.nan.isTotallyOrdered(belowOrEqualTo: Decimal.nan))
        XCTAssertFalse(Decimal.nan.isTotallyOrdered(belowOrEqualTo: Decimal(2.3)))
        XCTAssertTrue(Decimal(2) < Decimal(3))
        XCTAssertTrue(Decimal(3) > Decimal(2))
#if !arch(arm)
        XCTAssertEqual(3275573729074, Decimal(1234).hashValue)
#endif
        XCTAssertEqual(Decimal(-9), Decimal(1) - Decimal(10))
        XCTAssertEqual(Decimal(3), Decimal(2).nextUp)
        XCTAssertEqual(Decimal(2), Decimal(3).nextDown)
        XCTAssertEqual(Decimal(-476), Decimal(1024).distance(to: Decimal(1500)))
        XCTAssertEqual(Decimal(68040), Decimal(386).advanced(by: Decimal(67654)))
        XCTAssertEqual(Decimal(1.234), abs(Decimal(1.234)))
        XCTAssertEqual(Decimal(1.234), abs(Decimal(-1.234)))
        var a = Decimal(1234)
        var result = Decimal(0)
        XCTAssertEqual(.noError, NSDecimalMultiplyByPowerOf10(&result, &a, 1, .plain))
        XCTAssertEqual(Decimal(12340), result)
        a = Decimal(1234)
        XCTAssertEqual(.noError, NSDecimalMultiplyByPowerOf10(&result, &a, 2, .plain))
        XCTAssertEqual(Decimal(123400), result)
        a = result
        XCTAssertEqual(.overflow, NSDecimalMultiplyByPowerOf10(&result, &a, 128, .plain))
        XCTAssertTrue(result.isNaN)
        a = Decimal(1234)
        XCTAssertEqual(.noError, NSDecimalMultiplyByPowerOf10(&result, &a, -2, .plain))
        XCTAssertEqual(Decimal(12.34), result)
        a = result
        XCTAssertEqual(.underflow, NSDecimalMultiplyByPowerOf10(&result, &a, -128, .plain))
        XCTAssertTrue(result.isNaN)
        a = Decimal(1234)
        XCTAssertEqual(.noError, NSDecimalPower(&result, &a, 0, .plain))
        XCTAssertEqual(Decimal(1), result)
        a = Decimal(8)
        XCTAssertEqual(.noError, NSDecimalPower(&result, &a, 2, .plain))
        XCTAssertEqual(Decimal(64), result)
        a = Decimal(-2)
        XCTAssertEqual(.noError, NSDecimalPower(&result, &a, 3, .plain))
        XCTAssertEqual(Decimal(-8), result)
        for i in -2...10 {
            for j in 0...5 {
                var actual = Decimal(i)
                var power = actual
                XCTAssertEqual(.noError, NSDecimalPower(&actual, &power, j, .plain))
                let expected = Decimal(pow(Double(i), Double(j)))
                XCTAssertEqual(expected, actual, "\(actual) == \(i)^\(j)")
            }
        }
    }

    func test_MultiplicationOverflow() {
        var multiplicand = Decimal(_exponent: 0, _length: 8, _isNegative: 0, _isCompact: 0, _reserved: 0, _mantissa: ( 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff ))

        var result = Decimal()
        var multiplier = Decimal(1)

        multiplier._mantissa.0 = 2

        XCTAssertEqual(.noError, NSDecimalMultiply(&result, &multiplicand, &multiplier, .plain), "2 * max mantissa")
        XCTAssertEqual(.noError, NSDecimalMultiply(&result, &multiplier, &multiplicand, .plain), "max mantissa * 2")

        multiplier._exponent = 0x7f
        XCTAssertEqual(.overflow, NSDecimalMultiply(&result, &multiplicand, &multiplier, .plain), "2e127 * max mantissa")
        XCTAssertEqual(.overflow, NSDecimalMultiply(&result, &multiplier, &multiplicand, .plain), "max mantissa * 2e127")
    }

    func test_NaNInput() {
        var NaN = Decimal.nan
        var one = Decimal(1)
        var result = Decimal()

        XCTAssertNotEqual(.noError, NSDecimalAdd(&result, &NaN, &one, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "NaN + 1")
        XCTAssertNotEqual(.noError, NSDecimalAdd(&result, &one, &NaN, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "1 + NaN")

        XCTAssertNotEqual(.noError, NSDecimalSubtract(&result, &NaN, &one, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "NaN - 1")
        XCTAssertNotEqual(.noError, NSDecimalSubtract(&result, &one, &NaN, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "1 - NaN")

        XCTAssertNotEqual(.noError, NSDecimalMultiply(&result, &NaN, &one, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "NaN * 1")
        XCTAssertNotEqual(.noError, NSDecimalMultiply(&result, &one, &NaN, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "1 * NaN")

        XCTAssertNotEqual(.noError, NSDecimalDivide(&result, &NaN, &one, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "NaN / 1")
        XCTAssertNotEqual(.noError, NSDecimalDivide(&result, &one, &NaN, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "1 / NaN")

        XCTAssertNotEqual(.noError, NSDecimalPower(&result, &NaN, 0, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "NaN ^ 0")
        XCTAssertNotEqual(.noError, NSDecimalPower(&result, &NaN, 4, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "NaN ^ 4")
        XCTAssertNotEqual(.noError, NSDecimalPower(&result, &NaN, 5, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "NaN ^ 5")

        XCTAssertNotEqual(.noError, NSDecimalMultiplyByPowerOf10(&result, &NaN, 0, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "NaN e0")
        XCTAssertNotEqual(.noError, NSDecimalMultiplyByPowerOf10(&result, &NaN, 4, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "NaN e4")
        XCTAssertNotEqual(.noError, NSDecimalMultiplyByPowerOf10(&result, &NaN, 5, .plain))
        XCTAssertTrue(NSDecimalIsNotANumber(&result), "NaN e5")

        XCTAssertFalse(Double(truncating: NSDecimalNumber(decimal: Decimal(0))).isNaN)
    }

    func test_NegativeAndZeroMultiplication() {
        var one = Decimal(1)
        var zero = Decimal(0)
        var negativeOne = Decimal(-1)

        var result = Decimal()

        XCTAssertEqual(.noError, NSDecimalMultiply(&result, &one, &one, .plain), "1 * 1")
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&one, &result), "1 * 1")

        XCTAssertEqual(.noError, NSDecimalMultiply(&result, &one, &negativeOne, .plain), "1 * -1")
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&negativeOne, &result), "1 * -1")

        XCTAssertEqual(.noError, NSDecimalMultiply(&result, &negativeOne, &one, .plain), "-1 * 1")
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&negativeOne, &result), "-1 * 1")

        XCTAssertEqual(.noError, NSDecimalMultiply(&result, &negativeOne, &negativeOne, .plain), "-1 * -1")
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&one, &result), "-1 * -1")

        XCTAssertEqual(.noError, NSDecimalMultiply(&result, &one, &zero, .plain), "1 * 0")
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&zero, &result), "1 * 0")
        XCTAssertEqual(0, result._isNegative, "1 * 0")

        XCTAssertEqual(.noError, NSDecimalMultiply(&result, &zero, &one, .plain), "0 * 1")
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&zero, &result), "0 * 1")
        XCTAssertEqual(0, result._isNegative, "0 * 1")

        XCTAssertEqual(.noError, NSDecimalMultiply(&result, &negativeOne, &zero, .plain), "-1 * 0")
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&zero, &result), "-1 * 0")
        XCTAssertEqual(0, result._isNegative, "-1 * 0")

        XCTAssertEqual(.noError, NSDecimalMultiply(&result, &zero, &negativeOne, .plain), "0 * -1")
        XCTAssertEqual(.orderedSame, NSDecimalCompare(&zero, &result), "0 * -1")
        XCTAssertEqual(0, result._isNegative, "0 * -1")
    }

    func test_Normalise() {
        var one = Decimal(1)
        var ten = Decimal(-10)
        XCTAssertEqual(.noError, NSDecimalNormalize(&one, &ten, .plain))
        XCTAssertEqual(Decimal(1), one)
        XCTAssertEqual(Decimal(-10), ten)
        XCTAssertEqual(1, one._length)
        XCTAssertEqual(1, ten._length)
        one = Decimal(1)
        ten = Decimal(10)
        XCTAssertEqual(.noError, NSDecimalNormalize(&one, &ten, .plain))
        XCTAssertEqual(Decimal(1), one)
        XCTAssertEqual(Decimal(10), ten)
        XCTAssertEqual(1, one._length)
        XCTAssertEqual(1, ten._length)
    }

    func test_NSDecimal() {
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
        XCTAssertEqual(0, f._isCompact)
        NSDecimalCompact(&f)
        XCTAssertEqual(1, f._isCompact)
        let after = f.description
        XCTAssertEqual(before, after)

        let nsd1 = NSDecimalNumber(decimal: Decimal(2657.6))
        let nsd2 = NSDecimalNumber(floatLiteral: 2657.6)
        XCTAssertEqual(nsd1, nsd2)
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

    func test_RepeatingDivision()  {
        let repeatingNumerator = Decimal(16)
        let repeatingDenominator = Decimal(9)
        let repeating = repeatingNumerator / repeatingDenominator

        let numerator = Decimal(1010)
        var result = numerator / repeating

        var expected = Decimal()
        expected._exponent = -35;
        expected._length = 8;
        expected._isNegative = 0;
        expected._isCompact = 1;
        expected._reserved = 0;
        expected._mantissa.0 = 51946;
        expected._mantissa.1 = 3;
        expected._mantissa.2 = 15549;
        expected._mantissa.3 = 55864;
        expected._mantissa.4 = 57984;
        expected._mantissa.5 = 55436;
        expected._mantissa.6 = 45186;
        expected._mantissa.7 = 10941;

        XCTAssertEqual(.orderedSame, NSDecimalCompare(&expected, &result), "568.12500000000000000000000000000248554: \(expected.description) != \(result.description)");
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
            ( -3, -2.5, 0, .bankers ),
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

    func test_ScanDecimal() {
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
            let decimal = Decimal(string:string)!
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
    }

    func test_SimpleMultiplication() {
        var multiplicand = Decimal()
        multiplicand._isNegative = 0
        multiplicand._isCompact = 0
        multiplicand._length = 1
        multiplicand._exponent = 1

        var multiplier = multiplicand
        multiplier._exponent = 2

        var expected = multiplicand
        expected._isNegative = 0
        expected._isCompact = 0
        expected._exponent = 3
        expected._length = 1

        var result = Decimal()

        for i in 1..<UInt8.max {
            multiplicand._mantissa.0 = UInt16(i)

            for j in 1..<UInt8.max {
                multiplier._mantissa.0 = UInt16(j)
                expected._mantissa.0 = UInt16(i) * UInt16(j)

                XCTAssertEqual(.noError, NSDecimalMultiply(&result, &multiplicand, &multiplier, .plain), "\(i) * \(j)")
                XCTAssertEqual(.orderedSame, NSDecimalCompare(&expected, &result), "\(expected._mantissa.0) == \(i) * \(j)");
            }
        }
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

    func test_ZeroPower() {
        let six = NSDecimalNumber(integerLiteral: 6)
        XCTAssertEqual(1, six.raising(toPower: 0))

        let negativeSix = NSDecimalNumber(integerLiteral: -6)
        XCTAssertEqual(1, negativeSix.raising(toPower: 0))
    }

}
