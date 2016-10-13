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

class TestNSDecimal: XCTestCase {

    static var allTests : [(String, (TestNSDecimal) -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_Constants", test_Constants),
            ("test_Description", test_Description),
            ("test_ExplicitConstruction", test_ExplicitConstruction),
            ("test_Maths", test_Maths),
            ("test_Misc", test_Misc),
            ("test_Normalise", test_Normalise),
            ("test_Round", test_Round),
            ("test_NSDecimal", test_NSDecimal),
        ]
    }

    func test_BasicConstruction() {
        let zero = Decimal()
        XCTAssertEqual(20, MemoryLayout<Decimal>.size)
        XCTAssertEqual(0, zero._exponent)
        XCTAssertEqual(0, zero._length)
        XCTAssertEqual(0, zero._isNegative)
        XCTAssertEqual(0, zero._isCompact)
        XCTAssertEqual(0, zero._reserved)
        let (m0,m1,m2,m3,m4,m5,m6,m7) = zero._mantissa
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
    }
    func test_Constants() {
        XCTAssertEqual(8,NSDecimalMaxSize)
        XCTAssertEqual(32767,NSDecimalNoScale)
        let smallest = Decimal(_exponent: 127, _length: 8, _isNegative: 1, _isCompact: 1, _reserved: 0, _mantissa: (UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max))
        XCTAssertEqual(smallest, Decimal.leastFiniteMagnitude)
        let biggest = Decimal(_exponent: 127, _length: 8, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max, UInt16.max))
        XCTAssertEqual(biggest, Decimal.greatestFiniteMagnitude)
        let leastNormal = Decimal(_exponent: -127, _length: 1, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (1,0,0,0,0,0,0,0))
        XCTAssertEqual(leastNormal, Decimal.leastNormalMagnitude)
        let leastNonzero = Decimal(_exponent: -127, _length: 1, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (1,0,0,0,0,0,0,0))
        XCTAssertEqual(leastNonzero, Decimal.leastNonzeroMagnitude)
        let pi = Decimal(_exponent: -38, _length: 8, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (0x6623, 0x7d57, 0x16e7, 0xad0d, 0xaf52, 0x4641, 0xdfa7, 0xec58))
        XCTAssertEqual(pi,Decimal.pi)
        XCTAssertEqual(10,Decimal.radix)
        XCTAssertTrue(Decimal().isCanonical)
        XCTAssertFalse(Decimal().isSignalingNaN)
        XCTAssertFalse(Decimal.nan.isSignalingNaN)
        XCTAssertTrue(Decimal.nan.isNaN)
        XCTAssertEqual(.quietNaN,Decimal.nan.floatingPointClass)
        XCTAssertEqual(.positiveZero,Decimal().floatingPointClass)
        XCTAssertEqual(.negativeNormal,smallest.floatingPointClass)
        XCTAssertEqual(.positiveNormal,biggest.floatingPointClass)
        XCTAssertFalse(Double.nan.isFinite)
        XCTAssertFalse(Double.nan.isInfinite)
    }

    func test_Description() {
        XCTAssertEqual("0",Decimal().description)
        XCTAssertEqual("0",Decimal(0).description)
        XCTAssertEqual("10",Decimal(_exponent: 1, _length: 1, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (1,0,0,0,0,0,0,0)).description)
        XCTAssertEqual("10",Decimal(10).description)
        XCTAssertEqual("123.458",Decimal(_exponent: -3, _length: 2, _isNegative: 0, _isCompact:1, _reserved: 0, _mantissa: (57922,1,0,0,0,0,0,0)).description)
        XCTAssertEqual("123.458",Decimal(123.458).description)
        XCTAssertEqual("123",Decimal(UInt8(123)).description)
        XCTAssertEqual("45",Decimal(Int8(45)).description)
        XCTAssertEqual("3.14159265358979323846264338327950288419",Decimal.pi.description)
        XCTAssertEqual("-30000000000",Decimal(sign: .minus, exponent: 10, significand: Decimal(3)).description)
        XCTAssertEqual("300000",Decimal(sign: .plus, exponent: 5, significand: Decimal(3)).description)
        XCTAssertEqual("5",Decimal(signOf: Decimal(3), magnitudeOf: Decimal(5)).description)
        XCTAssertEqual("-5",Decimal(signOf: Decimal(-3), magnitudeOf: Decimal(5)).description)
        XCTAssertEqual("5",Decimal(signOf: Decimal(3), magnitudeOf: Decimal(-5)).description)
        XCTAssertEqual("-5",Decimal(signOf: Decimal(-3), magnitudeOf: Decimal(-5)).description)
    }

    func test_ExplicitConstruction() {
        var explicit = Decimal(
            _exponent: 0x17f,
            _length: 0xff,
            _isNegative: 3,
            _isCompact: 4,
            _reserved: UInt32(1<<18 + 1<<17 + 1),
            _mantissa: (6,7,8,9,10,11,12,13)
        )
        XCTAssertEqual(0x7f, explicit._exponent)
        XCTAssertEqual(0x7f, explicit.exponent)
        XCTAssertEqual(0x0f, explicit._length)
        XCTAssertEqual(1, explicit._isNegative)
        XCTAssertEqual(FloatingPointSign.minus, explicit.sign)
        XCTAssertTrue(explicit.isSignMinus)
        XCTAssertEqual(0, explicit._isCompact)
        XCTAssertEqual(UInt32(1<<17 + 1), explicit._reserved)
        let (m0,m1,m2,m3,m4,m5,m6,m7) = explicit._mantissa
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
        let (sm0,sm1,sm2,sm3,sm4,sm5,sm6,sm7) = significand._mantissa
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
                    for (a, b) in zip(answerDescription.characters, approximationDescription.characters) {
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
        XCTAssertEqual(Decimal(186243*15673), Decimal(186243) * Decimal(15673))
    }

    func test_Misc() {
        XCTAssertEqual(.minus,Decimal(-5.2).sign)
        XCTAssertEqual(.plus,Decimal(5.2).sign)
        var d = Decimal(5.2)
        XCTAssertEqual(.plus,d.sign)
        d.negate()
        XCTAssertEqual(.minus,d.sign)
        d.negate()
        XCTAssertEqual(.plus,d.sign)
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
        XCTAssertEqual(3275573729074,Decimal(1234).hashValue)
        XCTAssertEqual(Decimal(-9), Decimal(1) - Decimal(10))
        XCTAssertEqual(Decimal(3),Decimal(2).nextUp)
        XCTAssertEqual(Decimal(2),Decimal(3).nextDown)
        XCTAssertEqual(Decimal(-476),Decimal(1024).distance(to: Decimal(1500)))
        XCTAssertEqual(Decimal(68040),Decimal(386).advanced(by: Decimal(67654)))
        XCTAssertEqual(Decimal(1.234),abs(Decimal(1.234)))
        XCTAssertEqual(Decimal(1.234),abs(Decimal(-1.234)))
        var a = Decimal(1234)
        XCTAssertEqual(.noError,NSDecimalMultiplyByPowerOf10(&a,&a,1,.plain))
        XCTAssertEqual(Decimal(12340),a)
        a = Decimal(1234)
        XCTAssertEqual(.noError,NSDecimalMultiplyByPowerOf10(&a,&a,2,.plain))
        XCTAssertEqual(Decimal(123400),a)
        XCTAssertEqual(.overflow,NSDecimalMultiplyByPowerOf10(&a,&a,128,.plain))
        XCTAssertTrue(a.isNaN)
        a = Decimal(1234)
        XCTAssertEqual(.noError,NSDecimalMultiplyByPowerOf10(&a,&a,-2,.plain))
        XCTAssertEqual(Decimal(12.34),a)
        XCTAssertEqual(.underflow,NSDecimalMultiplyByPowerOf10(&a,&a,-128,.plain))
        XCTAssertTrue(a.isNaN)
        a = Decimal(1234)
        XCTAssertEqual(.noError,NSDecimalPower(&a,&a,0,.plain))
        XCTAssertEqual(Decimal(1),a)
        a = Decimal(8)
        XCTAssertEqual(.noError,NSDecimalPower(&a,&a,2,.plain))
        XCTAssertEqual(Decimal(64),a)
        a = Decimal(-2)
        XCTAssertEqual(.noError,NSDecimalPower(&a,&a,3,.plain))
        XCTAssertEqual(Decimal(-8),a)
        for i in -2...10 {
            for j in 0...5 {
                var actual = Decimal(i)
                XCTAssertEqual(.noError,NSDecimalPower(&actual,&actual,j,.plain))
                let expected = Decimal(pow(Double(i),Double(j)))
                XCTAssertEqual(expected, actual, "\(actual) == \(i)^\(j)")
            }
        }
    }

    func test_Round() {
        let testCases = [
            // expected, start, scale, round
            ( 0, 0.5, 0, Decimal.RoundingMode.down ),
            ( 1, 0.5, 0, Decimal.RoundingMode.up ),
            ( 2, 2.5, 0, Decimal.RoundingMode.bankers ),
            ( 4, 3.5, 0, Decimal.RoundingMode.bankers ),
            ( 5, 5.2, 0, Decimal.RoundingMode.plain ),
            ( 4.5, 4.5, 1, Decimal.RoundingMode.down ),
            ( 5.5, 5.5, 1, Decimal.RoundingMode.up ),
            ( 6.5, 6.5, 1, Decimal.RoundingMode.plain ),
            ( 7.5, 7.5, 1, Decimal.RoundingMode.bankers ),

            ( -1, -0.5, 0, Decimal.RoundingMode.down ),
            ( -2, -2.5, 0, Decimal.RoundingMode.up ),
            ( -3, -2.5, 0, Decimal.RoundingMode.bankers ),
            ( -4, -3.5, 0, Decimal.RoundingMode.bankers ),
            ( -5, -5.2, 0, Decimal.RoundingMode.plain ),
            ( -4.5, -4.5, 1, Decimal.RoundingMode.down ),
            ( -5.5, -5.5, 1, Decimal.RoundingMode.up ),
            ( -6.5, -6.5, 1, Decimal.RoundingMode.plain ),
            ( -7.5, -7.5, 1, Decimal.RoundingMode.bankers ),
        ]
        for testCase in testCases {
            let (expected, start, scale, mode) = testCase
            var num = Decimal(start)
            NSDecimalRound(&num,&num,scale,mode)
            XCTAssertEqual(Decimal(expected), num)
        }
    }

    func test_Normalise() {
        var one = Decimal(1)
        var ten = Decimal(-10)
        XCTAssertEqual(.noError,NSDecimalNormalize(&one,&ten,.plain))
        XCTAssertEqual(Decimal(1),one)
        XCTAssertEqual(Decimal(-10),ten)
        XCTAssertEqual(1,one._length)
        XCTAssertEqual(1,ten._length)
        one = Decimal(1)
        ten = Decimal(10)
        XCTAssertEqual(.noError,NSDecimalNormalize(&one,&ten,.plain))
        XCTAssertEqual(Decimal(1),one)
        XCTAssertEqual(Decimal(10),ten)
        XCTAssertEqual(1,one._length)
        XCTAssertEqual(1,ten._length)
    }

    func test_NSDecimal() {
        var nan = Decimal.nan
        XCTAssertTrue(NSDecimalIsNotANumber(&nan))
        var zero = Decimal()
        XCTAssertFalse(NSDecimalIsNotANumber(&zero))
        var three = Decimal(3)
        var guess = Decimal()
        NSDecimalCopy(&guess,&three)
        XCTAssertEqual(three,guess)

        var f = Decimal(_exponent: 0, _length: 2, _isNegative: 0, _isCompact: 0, _reserved: 0, _mantissa: (0x0000, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000))
        let before = f.description
        XCTAssertEqual(0,f._isCompact)
        NSDecimalCompact(&f)
        XCTAssertEqual(1,f._isCompact)
        let after = f.description
        XCTAssertEqual(before,after)
    }
}
