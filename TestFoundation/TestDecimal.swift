// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

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
        XCTAssertEqual("5", NSDecimalNumber(decimal: Decimal(5)).description)
        XCTAssertEqual("-5", NSDecimalNumber(decimal: Decimal(-5)).description)
        XCTAssertEqual("-3402823669209384634633746074317682114550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", Decimal.leastFiniteMagnitude.description)
        XCTAssertEqual("3402823669209384634633746074317682114550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000", Decimal.greatestFiniteMagnitude.description)
        XCTAssertEqual("0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", Decimal.leastNormalMagnitude.description)
        XCTAssertEqual("0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", Decimal.leastNonzeroMagnitude.description)

        let fr = Locale(identifier: "fr_FR")
        let leastFiniteMagnitude = "-3402823669209384634633746074317682114550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        let greatestFiniteMagnitude = "3402823669209384634633746074317682114550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

        XCTAssertEqual("0", NSDecimalNumber(decimal: Decimal()).description(withLocale: fr))
        XCTAssertEqual("1000", NSDecimalNumber(decimal: Decimal(1000)).description(withLocale: fr))
        XCTAssertEqual("10", NSDecimalNumber(decimal: Decimal(10)).description(withLocale: fr))
        XCTAssertEqual("123,458", NSDecimalNumber(decimal: Decimal(123.458)).description(withLocale: fr))
        XCTAssertEqual("123", NSDecimalNumber(decimal: Decimal(UInt8(123))).description(withLocale: fr))
        XCTAssertEqual("3,14159265358979323846264338327950288419", NSDecimalNumber(decimal: Decimal.pi).description(withLocale: fr))
        XCTAssertEqual("-30000000000", NSDecimalNumber(decimal: Decimal(sign: .minus, exponent: 10, significand: Decimal(3))).description(withLocale: fr))
        XCTAssertEqual("123456,789", NSDecimalNumber(decimal: Decimal(string: "123456.789")!).description(withLocale: fr))
        XCTAssertEqual(leastFiniteMagnitude, NSDecimalNumber(decimal: Decimal.leastFiniteMagnitude).description(withLocale: fr))
        XCTAssertEqual(greatestFiniteMagnitude, NSDecimalNumber(decimal: Decimal.greatestFiniteMagnitude).description(withLocale: fr))
        XCTAssertEqual("0,0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", NSDecimalNumber(decimal: Decimal.leastNormalMagnitude).description(withLocale: fr))
        XCTAssertEqual("0,0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", NSDecimalNumber(decimal: Decimal.leastNonzeroMagnitude).description(withLocale: fr))

        let en = Locale(identifier: "en_GB")
        XCTAssertEqual("0", NSDecimalNumber(decimal: Decimal()).description(withLocale: en))
        XCTAssertEqual("1000", NSDecimalNumber(decimal: Decimal(1000)).description(withLocale: en))
        XCTAssertEqual("10", NSDecimalNumber(decimal: Decimal(10)).description(withLocale: en))
        XCTAssertEqual("123.458", NSDecimalNumber(decimal: Decimal(123.458)).description(withLocale: en))
        XCTAssertEqual("123", NSDecimalNumber(decimal: Decimal(UInt8(123))).description(withLocale: en))
        XCTAssertEqual("3.14159265358979323846264338327950288419", NSDecimalNumber(decimal: Decimal.pi).description(withLocale: en))
        XCTAssertEqual("-30000000000", NSDecimalNumber(decimal: Decimal(sign: .minus, exponent: 10, significand: Decimal(3))).description(withLocale: en))
        XCTAssertEqual("123456.789", NSDecimalNumber(decimal: Decimal(string: "123456.789")!).description(withLocale: en))
        XCTAssertEqual(leastFiniteMagnitude, NSDecimalNumber(decimal: Decimal.leastFiniteMagnitude).description(withLocale: en))
        XCTAssertEqual(greatestFiniteMagnitude, NSDecimalNumber(decimal: Decimal.greatestFiniteMagnitude).description(withLocale: en))
        XCTAssertEqual("0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", NSDecimalNumber(decimal: Decimal.leastNormalMagnitude).description(withLocale: en))
        XCTAssertEqual("0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", NSDecimalNumber(decimal: Decimal.leastNonzeroMagnitude).description(withLocale: en))
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

        // FIXME: This test is of questionable value. We should test hash properties.
        XCTAssertEqual((1234 as Double).hashValue, Decimal(1234).hashValue)

        XCTAssertEqual(Decimal(-9), Decimal(1) - Decimal(10))
        XCTAssertEqual(Decimal(3), Decimal(2).nextUp)
        XCTAssertEqual(Decimal(2), Decimal(3).nextDown)
        XCTAssertEqual(Decimal(-476), Decimal(1024).distance(to: Decimal(1500)))
        XCTAssertEqual(Decimal(68040), Decimal(386).advanced(by: Decimal(67654)))
        XCTAssertEqual(Decimal(1.234), abs(Decimal(1.234)))
        XCTAssertEqual(Decimal(1.234), abs(Decimal(-1.234)))
        XCTAssertEqual((0 as Decimal).magnitude, 0 as Decimal)
        XCTAssertEqual((1 as Decimal).magnitude, 1 as Decimal)
        XCTAssertEqual((1 as Decimal).magnitude, abs(1 as Decimal))
        XCTAssertEqual((1 as Decimal).magnitude, abs(-1 as Decimal))
        XCTAssertEqual((-1 as Decimal).magnitude, abs(-1 as Decimal))
        XCTAssertEqual((-1 as Decimal).magnitude, abs(1 as Decimal))
        XCTAssertEqual(Decimal.leastFiniteMagnitude.magnitude, -Decimal.leastFiniteMagnitude) // A bit of a misnomer.
        XCTAssertEqual(Decimal.greatestFiniteMagnitude.magnitude, Decimal.greatestFiniteMagnitude)
        XCTAssertTrue(Decimal.nan.magnitude.isNaN)

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
                XCTAssertEqual(expected, pow(power, j))
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

        // Check equality with numbers with large exponent difference
        var small = Decimal.leastNonzeroMagnitude
        var large = Decimal.greatestFiniteMagnitude
        XCTAssertTrue(Int(large.exponent) - Int(small.exponent) > Int(Int8.max))
        XCTAssertTrue(Int(small.exponent) - Int(large.exponent) < Int(Int8.min))
        XCTAssertNotEqual(small, large)

        XCTAssertEqual(small.exponent, -127)
        XCTAssertEqual(large.exponent, 127)
        XCTAssertEqual(.lossOfPrecision, NSDecimalNormalize(&small, &large, .plain))
        XCTAssertEqual(small.exponent, 127)
        XCTAssertEqual(large.exponent, 127)

        small = Decimal.leastNonzeroMagnitude
        large = Decimal.greatestFiniteMagnitude
        XCTAssertEqual(small.exponent, -127)
        XCTAssertEqual(large.exponent, 127)
        XCTAssertEqual(.lossOfPrecision, NSDecimalNormalize(&large, &small, .plain))
        XCTAssertEqual(small.exponent, 127)
        XCTAssertEqual(large.exponent, 127)
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
        XCTAssertEqual(0, f._isCompact)
        NSDecimalCompact(&f)
        XCTAssertEqual(1, f._isCompact)
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

    func test_doubleValue() {
        XCTAssertEqual(NSDecimalNumber(decimal:Decimal(0)).doubleValue, 0)
        XCTAssertEqual(NSDecimalNumber(decimal:Decimal(1)).doubleValue, 1)
        XCTAssertEqual(NSDecimalNumber(decimal:Decimal(-1)).doubleValue, -1)
        XCTAssertTrue(NSDecimalNumber(decimal:Decimal.nan).doubleValue.isNaN)
        XCTAssertEqual(NSDecimalNumber(decimal:Decimal(UInt64.max)).doubleValue, Double(1.8446744073709552e+19))
        XCTAssertEqual(NSDecimalNumber(decimal:Decimal(string: "1234567890123456789012345678901234567890")!).doubleValue, Double(1.2345678901234568e+39))

        var d = Decimal()
        d._mantissa.0 = 1
        d._mantissa.1 = 2
        d._mantissa.2 = 3
        d._mantissa.3 = 4
        d._mantissa.4 = 5
        d._mantissa.5 = 6
        d._mantissa.6 = 7
        d._mantissa.7 = 8

        XCTAssertEqual(NSDecimalNumber(decimal: d).doubleValue, 0)
        XCTAssertEqual(d, Decimal(0))

        d._length = 1
        XCTAssertEqual(NSDecimalNumber(decimal: d).doubleValue, 1)
        XCTAssertEqual(d, Decimal(1))

        d._length = 2
        XCTAssertEqual(NSDecimalNumber(decimal: d).doubleValue, 131073)
        XCTAssertEqual(d, Decimal(131073))

        d._length = 3
        XCTAssertEqual(NSDecimalNumber(decimal: d).doubleValue, 12885032961)
        XCTAssertEqual(d, Decimal(12885032961))

        d._length = 4
        XCTAssertEqual(NSDecimalNumber(decimal: d).doubleValue, 1125912791875585)
        XCTAssertEqual(d, Decimal(1125912791875585))

        d._length = 5
        XCTAssertEqual(NSDecimalNumber(decimal: d).doubleValue, 9.223484628133963e+19)
        XCTAssertEqual(d, Decimal(string: "92234846281339633665")!)

        d._length = 6
        XCTAssertEqual(NSDecimalNumber(decimal: d).doubleValue, 7.253647152534056e+24)
        XCTAssertEqual(d, Decimal(string: "7253647152534056387870721")!)

        d._length = 7
        XCTAssertEqual(NSDecimalNumber(decimal: d).doubleValue, 5.546043912470029e+29)
        XCTAssertEqual(d, Decimal(string: "554604391247002897211195523073")!)

        d._length = 8
        XCTAssertEqual(NSDecimalNumber(decimal: d).doubleValue, 4.153892947266987e+34)
        XCTAssertEqual(d, Decimal(string: "41538929472669868031141181829283841")!)

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

    func test_stringWithLocale() {

        let en_US = Locale(identifier: "en_US")
        let fr_FR = Locale(identifier: "fr_FR")

        XCTAssertEqual(Decimal(string: "1,234.56")! * 1000, Decimal(1000))
        XCTAssertEqual(Decimal(string: "1,234.56", locale: en_US)! * 1000, Decimal(1000))
        XCTAssertEqual(Decimal(string: "1,234.56", locale: fr_FR)! * 1000, Decimal(1234))
        XCTAssertEqual(Decimal(string: "1.234,56", locale: en_US)! * 1000, Decimal(1234))
        XCTAssertEqual(Decimal(string: "1.234,56", locale: fr_FR)! * 1000, Decimal(1000))

        XCTAssertEqual(Decimal(string: "-1,234.56")! * 1000, Decimal(-1000))
        XCTAssertEqual(Decimal(string: "+1,234.56")! * 1000, Decimal(1000))
        XCTAssertEqual(Decimal(string: "+1234.56e3"), Decimal(1234560))
        XCTAssertEqual(Decimal(string: "+1234.56E3"), Decimal(1234560))
        XCTAssertEqual(Decimal(string: "+123456000E-3"), Decimal(123456))

        XCTAssertNil(Decimal(string: ""))
        XCTAssertNil(Decimal(string: "x"))
        XCTAssertEqual(Decimal(string: "-x"), Decimal.zero)
        XCTAssertEqual(Decimal(string: "+x"), Decimal.zero)
        XCTAssertEqual(Decimal(string: "-"), Decimal.zero)
        XCTAssertEqual(Decimal(string: "+"), Decimal.zero)
        XCTAssertEqual(Decimal(string: "-."), Decimal.zero)
        XCTAssertEqual(Decimal(string: "+."), Decimal.zero)

        XCTAssertEqual(Decimal(string: "-0"), Decimal.zero)
        XCTAssertEqual(Decimal(string: "+0"), Decimal.zero)
        XCTAssertEqual(Decimal(string: "-0."), Decimal.zero)
        XCTAssertEqual(Decimal(string: "+0."), Decimal.zero)
        XCTAssertEqual(Decimal(string: "e1"), Decimal.zero)
        XCTAssertEqual(Decimal(string: "e-5"), Decimal.zero)
        XCTAssertEqual(Decimal(string: ".3e1"), Decimal(3))

        XCTAssertEqual(Decimal(string: "."), Decimal.zero)
        XCTAssertEqual(Decimal(string: ".", locale: en_US), Decimal.zero)
        XCTAssertNil(Decimal(string: ".", locale: fr_FR))

        XCTAssertNil(Decimal(string: ","))
        XCTAssertEqual(Decimal(string: ",", locale: fr_FR), Decimal.zero)
        XCTAssertNil(Decimal(string: ",", locale: en_US))

        let s1 = "1234.5678"
        XCTAssertEqual(Decimal(string: s1, locale: en_US)?.description, s1)
        XCTAssertEqual(Decimal(string: s1, locale: fr_FR)?.description, "1234")

        let s2 = "1234,5678"
        XCTAssertEqual(Decimal(string: s2, locale: en_US)?.description, "1234")
        XCTAssertEqual(Decimal(string: s2, locale: fr_FR)?.description, s1)
    }

    func test_NSDecimalString() {
        var decimal = Decimal(string: "-123456.789")!
        XCTAssertEqual(NSDecimalString(&decimal, nil), "-123456.789")
        let en = NSDecimalString(&decimal, Locale(identifier: "en_GB"))
        XCTAssertEqual(en, "-123456.789")
        let fr = NSDecimalString(&decimal, Locale(identifier: "fr_FR"))
        XCTAssertEqual(fr, "-123456,789")

        let d1: [NSLocale.Key: String] = [ .decimalSeparator: "@@@"]
        XCTAssertEqual(NSDecimalString(&decimal, d1), "-123456@@@789")
        let d2: [NSLocale.Key: String] = [ .decimalSeparator: "()"]
        XCTAssertEqual(NSDecimalString(&decimal, NSDictionary(dictionary: d2)), "-123456()789")
        let d3: [String: String] = [ "kCFLocaleDecimalSeparatorKey": "X"]
        XCTAssertEqual(NSDecimalString(&decimal, NSDictionary(dictionary: d3)), "-123456X789")

        // Input is ignored
        let d4: [Int: String] = [123: "X"]
        XCTAssertEqual(NSDecimalString(&decimal, NSDictionary(dictionary: d4)), "-123456.789")
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

    func test_initExactly() {
        // This really requires some tests using a BinaryInteger of bitwidth > 128 to test failures.
        let d1 = Decimal(exactly: UInt64.max)
        XCTAssertNotNil(d1)
        XCTAssertEqual(d1?.description, UInt64.max.description)
        XCTAssertEqual(d1?._length, 4)

        let d2 = Decimal(exactly: Int64.min)
        XCTAssertNotNil(d2)
        XCTAssertEqual(d2?.description, Int64.min.description)
        XCTAssertEqual(d2?._length, 4)

        let d3 = Decimal(exactly: Int64.max)
        XCTAssertNotNil(d3)
        XCTAssertEqual(d3?.description, Int64.max.description)
        XCTAssertEqual(d3?._length, 4)

        let d4 = Decimal(exactly: Int32.min)
        XCTAssertNotNil(d4)
        XCTAssertEqual(d4?.description, Int32.min.description)
        XCTAssertEqual(d4?._length, 2)

        let d5 = Decimal(exactly: Int32.max)
        XCTAssertNotNil(d5)
        XCTAssertEqual(d5?.description, Int32.max.description)
        XCTAssertEqual(d5?._length, 2)

        let d6 = Decimal(exactly: 0)
        XCTAssertNotNil(d6)
        XCTAssertEqual(d6, Decimal.zero)
        XCTAssertEqual(d6?.description, "0")
        XCTAssertEqual(d6?._length, 0)

        let d7 = Decimal(exactly: 1)
        XCTAssertNotNil(d7)
        XCTAssertEqual(d7?.description, "1")
        XCTAssertEqual(d7?._length, 1)

        let d8 = Decimal(exactly: -1)
        XCTAssertNotNil(d8)
        XCTAssertEqual(d8?.description, "-1")
        XCTAssertEqual(d8?._length, 1)
    }

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
            ("test_doubleValue", test_doubleValue),
            ("test_NSDecimalNumberValues", test_NSDecimalNumberValues),
            ("test_bridging", test_bridging),
            ("test_stringWithLocale", test_stringWithLocale),
            ("test_NSDecimalString", test_NSDecimalString),
            ("test_multiplyingByPowerOf10", test_multiplyingByPowerOf10),
            ("test_initExactly", test_initExactly),
        ]
    }
}
