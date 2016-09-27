// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public var NSDecimalMaxSize: Int32 { return 8 }
// Give a precision of at least 38 decimal digits, 128 binary positions.

public var NSDecimalNoScale: Int32 { return Int32(Int16.max) }

public struct Decimal {
    fileprivate var __exponent: Int8
    fileprivate var __lengthAndFlags: UInt8
    fileprivate var __reserved: UInt16
    public var _exponent: Int32 {
        get {
            return Int32(__exponent)
        }
        set {
            __exponent = Int8(truncatingBitPattern: newValue)
        }
    }
    // length == 0 && isNegative -> NaN
    public var _length: UInt32 {
        get {
            return UInt32((__lengthAndFlags & 0b0000_1111))
        }
        set {
            __lengthAndFlags =
                (__lengthAndFlags & 0b1111_0000) |
                UInt8(newValue & 0b0000_1111)
        }
    }
    public var _isNegative: UInt32 {
        get {
            return UInt32(((__lengthAndFlags) & 0b0001_0000) >> 4)
        }
        set {
            __lengthAndFlags =
                (__lengthAndFlags & 0b1110_1111) |
                (UInt8(newValue & 0b0000_0001 ) << 4)
        }
    }
    public var _isCompact: UInt32 {
        get {
            return UInt32(((__lengthAndFlags) & 0b0010_0000) >> 5)
        }
        set {
            __lengthAndFlags =
                (__lengthAndFlags & 0b1101_1111) |
                (UInt8(newValue & 0b0000_00001 ) << 5)
        }
    }
    public var _reserved: UInt32 {
        get {
            return UInt32(UInt32(__lengthAndFlags & 0b1100_0000) << 10 | UInt32(__reserved))
        }
        set {
            __lengthAndFlags =
                (__lengthAndFlags & 0b0011_1111) |
                UInt8(UInt32(newValue & (0b11 << 16)) >> 10)
            __reserved = UInt16(newValue & 0b1111_1111_1111_1111)
        }
    }
    public var _mantissa: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)
    public init() {
        self._mantissa = (0,0,0,0,0,0,0,0)
        self.__exponent = 0
        self.__lengthAndFlags = 0
        self.__reserved = 0
    }

    public init(_exponent: Int32, _length: UInt32, _isNegative: UInt32, _isCompact: UInt32, _reserved: UInt32, _mantissa: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)){
        self._mantissa = _mantissa
        self.__exponent = Int8(truncatingBitPattern: _exponent)
        self.__lengthAndFlags = 0
        self.__reserved = 0
        self._length = _length
        self._isNegative = _isNegative
        self._isCompact = _isCompact
        self._reserved = _reserved
    }
}

extension Decimal {
    public static let leastFiniteMagnitude = Decimal(
        _exponent: 127,
        _length: 8,
        _isNegative: 1,
        _isCompact: 1,
        _reserved: 0,
        _mantissa: (0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff)
    )
    public static let greatestFiniteMagnitude = Decimal(
        _exponent: 127,
        _length: 8,
        _isNegative: 0,
        _isCompact: 1,
        _reserved: 0,
        _mantissa: (0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff)
    )
    public static let leastNormalMagnitude = Decimal(
        _exponent: -127,
        _length: 1,
        _isNegative: 0,
        _isCompact: 1,
        _reserved: 0,
        _mantissa: (0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000)
    )
    public static let leastNonzeroMagnitude = Decimal(
        _exponent: -127,
        _length: 1,
        _isNegative: 0,
        _isCompact: 1,
        _reserved: 0,
        _mantissa: (0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000)
    )
    public static let pi = Decimal(
        _exponent: -38,
        _length: 8,
        _isNegative: 0,
        _isCompact: 1,
        _reserved: 0,
        _mantissa: (0x6623, 0x7d57, 0x16e7, 0xad0d, 0xaf52, 0x4641, 0xdfa7, 0xec58)
    )
    public var exponent: Int {
        get {
            return Int(self.__exponent)
        }
    }
    public var significand: Decimal {
        get {
            return Decimal(_exponent: 0, _length: _length, _isNegative: _isNegative, _isCompact: _isCompact, _reserved: 0, _mantissa: _mantissa)
        }
    }
    public init(sign: FloatingPointSign, exponent: Int, significand: Decimal) {
        self.init(_exponent: Int32(exponent) + significand._exponent, _length: significand._length, _isNegative: sign == .plus ? 0 : 1, _isCompact: significand._isCompact, _reserved: 0, _mantissa: significand._mantissa)
    }
    public init(signOf: Decimal, magnitudeOf magnitude: Decimal) {
        self.init(_exponent: magnitude._exponent, _length: magnitude._length, _isNegative: signOf._isNegative, _isCompact: magnitude._isCompact, _reserved: 0, _mantissa: magnitude._mantissa)
    }
    public var sign: FloatingPointSign {
        return _isNegative == 0 ? FloatingPointSign.plus : FloatingPointSign.minus
    }
    public static var radix: Int {
        return 10
    }
    public var ulp: Decimal {
        if !self.isFinite { return Decimal.nan }
        return Decimal(_exponent: _exponent, _length: 8, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000))
    }
    public mutating func add(_ other: Decimal) {
        var rhs = other
        _ = NSDecimalAdd(&self, &self, &rhs, .plain)
    }
    public mutating func subtract(_ other: Decimal) {
        var rhs = other
        _ = NSDecimalSubtract(&self, &self, &rhs, .plain)
    }
    public mutating func multiply(by other: Decimal) {
        var rhs = other
        _ = NSDecimalMultiply(&self, &self, &rhs, .plain)
    }
    public mutating func divide(by other: Decimal) {
        var rhs = other
        _ = NSDecimalDivide(&self, &self, &rhs, .plain)
    }
    public mutating func negate() {
        _isNegative = _isNegative == 0 ? 1 : 0
    }
    public func isEqual(to other: Decimal) -> Bool {
        return self.compare(to: other) == .orderedSame
    }
    public func isLess(than other: Decimal) -> Bool {
        return self.compare(to: other) == .orderedAscending
    }
    public func isLessThanOrEqualTo(_ other: Decimal) -> Bool {
        let comparison = self.compare(to: other)
        return comparison == .orderedAscending || comparison == .orderedSame
    }
    public func isTotallyOrdered(belowOrEqualTo other: Decimal) -> Bool {
        // Notes: Decimal does not have -0 or infinities to worry about
        if self.isNaN {
            return false
        } else if self < other {
            return true
        } else if other < self {
            return false
        }
        // fall through to == behavior
        return true
    }
    public var isCanonical: Bool {
        return true
    }
    public var nextUp: Decimal {
        return self + Decimal(_exponent: _exponent, _length: 1, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000))
    }
    public var nextDown: Decimal {
        return self - Decimal(_exponent: _exponent, _length: 1, _isNegative: 0, _isCompact: 1, _reserved: 0, _mantissa: (0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000))
    }
    public static func +(lhs: Decimal, rhs: Decimal) -> Decimal {
        var answer = lhs
        answer.add(lhs)
        return answer;
    }
    public static func -(lhs: Decimal, rhs: Decimal) -> Decimal {
        var answer = lhs
        answer.subtract(lhs)
        return answer;
    }
    public static func /(lhs: Decimal, rhs: Decimal) -> Decimal {
        var answer = lhs
        answer.divide(by: rhs)
        return answer;
    }
    public static func *(lhs: Decimal, rhs: Decimal) -> Decimal {
        var answer = lhs
        answer.multiply(by: rhs)
        return answer;
    }
}

extension Decimal : Hashable, Comparable {
    internal var doubleValue: Double {
        var d = 0.0
        if _length == 0 && _isNegative == 0 {
            return Double.nan
        }
        for i in 0..<8 {
            let index = 8 - i - 1
            switch index {
            case 0:
                d = d * 65536 + Double(_mantissa.0)
                break
            case 1:
                d = d * 65536 + Double(_mantissa.1)
                break
            case 2:
                d = d * 65536 + Double(_mantissa.2)
                break
            case 3:
                d = d * 65536 + Double(_mantissa.3)
                break
            case 4:
                d = d * 65536 + Double(_mantissa.4)
                break
            case 5:
                d = d * 65536 + Double(_mantissa.5)
                break
            case 6:
                d = d * 65536 + Double(_mantissa.6)
                break
            case 7:
                d = d * 65536 + Double(_mantissa.7)
                break
            default:
                fatalError("conversion overflow")
            }
        }
        if _exponent < 0 {
            for _ in _exponent..<0 {
                d /= 10.0
            }
        } else {
            for _ in 0..<_exponent {
                d *= 10.0
            }
        }
        return _isNegative != 0 ? -d : d
    }
    public var hashValue: Int {
        return Int(bitPattern: __CFHashDouble(doubleValue))
    }
    public static func ==(lhs: Decimal, rhs: Decimal) -> Bool {
        if lhs.isNaN {
            return rhs.isNaN
        }
        if lhs.__exponent == rhs.__exponent && lhs.__lengthAndFlags == rhs.__lengthAndFlags && lhs.__reserved == rhs.__reserved {
            if lhs._mantissa.0 == rhs._mantissa.0 &&
                lhs._mantissa.1 == rhs._mantissa.1 &&
                lhs._mantissa.2 == rhs._mantissa.2 &&
                lhs._mantissa.3 == rhs._mantissa.3 &&
                lhs._mantissa.4 == rhs._mantissa.4 &&
                lhs._mantissa.5 == rhs._mantissa.5 &&
                lhs._mantissa.6 == rhs._mantissa.6 &&
                lhs._mantissa.7 == rhs._mantissa.7 {
                return true
            }
        }
        var lhsVal = lhs
        var rhsVal = rhs
        return NSDecimalCompare(&lhsVal, &rhsVal) == .orderedSame
    }
    public static func <(lhs: Decimal, rhs: Decimal) -> Bool {
        var lhsVal = lhs
        var rhsVal = rhs
        return NSDecimalCompare(&lhsVal, &rhsVal) == .orderedAscending
    }
}

extension Decimal : ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension Decimal : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension Decimal : SignedNumber {
}

extension Decimal : Strideable {
    public func distance(to other: Decimal) -> Decimal {
        return self - other
    }
    public func advanced(by n: Decimal) -> Decimal {
        return self + n
    }
}

extension Decimal : AbsoluteValuable {
    public static func abs(_ x: Decimal) -> Decimal {
        return Decimal(_exponent: x._exponent, _length: x._length, _isNegative: 0, _isCompact: x._isCompact, _reserved: 0, _mantissa: x._mantissa)
    }
}

extension Decimal {
    public typealias RoundingMode = NSDecimalNumber.RoundingMode
    public typealias CalculationError = NSDecimalNumber.CalculationError
    public init(_ value: UInt8) {
        self.init(UInt64(value))
    }
    public init(_ value: Int8) {
        self.init(Int64(value))
    }
    public init(_ value: UInt16) {
        self.init(UInt64(value))
    }
    public init(_ value: Int16) {
        self.init(Int64(value))
    }
    public init(_ value: UInt32) {
        self.init(UInt64(value))
    }
    public init(_ value: Int32) {
        self.init(Int64(value))
    }
    public init(_ value: Double) {
        if value.isNaN {
            self = Decimal.nan
        } else if value == 0.0 {
            self = Decimal()
        } else {
            self = Decimal()
            let negative = value < 0
            var val = negative ? -1 * value : value
            var exponent = 0
            while val < Double(UInt64.max - 1) {
                val *= 10.0
                exponent -= 1
            }
            while Double(UInt64.max - 1) < val {
                val /= 10.0
                exponent += 1
            }
            var mantissa = UInt64(val)

            var i = Int32(0)
            // this is a bit ugly but it is the closest approximation of the C initializer that can be expressed here.
            while mantissa != 0 && i < NSDecimalMaxSize {
                switch i {
                case 0:
                    _mantissa.0 = UInt16(mantissa & 0xffff)
                    break
                case 1:
                    _mantissa.1 = UInt16(mantissa & 0xffff)
                    break
                case 2:
                    _mantissa.2 = UInt16(mantissa & 0xffff)
                    break
                case 3:
                    _mantissa.3 = UInt16(mantissa & 0xffff)
                    break
                case 4:
                    _mantissa.4 = UInt16(mantissa & 0xffff)
                    break
                case 5:
                    _mantissa.5 = UInt16(mantissa & 0xffff)
                    break
                case 6:
                    _mantissa.6 = UInt16(mantissa & 0xffff)
                    break
                case 7:
                    _mantissa.7 = UInt16(mantissa & 0xffff)
                    break
                default:
                    fatalError("initialization overflow")
                }
                mantissa = mantissa >> 16
                i += 1
            }
            _length = UInt32(i)
            _isNegative = negative ? 1 : 0
            _isCompact = 0
            _exponent = Int32(exponent)
            self.compact()
        }
    }
    public init(_ value: UInt64) {
        self.init(Double(value))
    }
    public init(_ value: Int64) {
        self.init(Double(value))
    }
    public init(_ value: UInt) {
        self.init(UInt64(value))
    }
    public init(_ value: Int) {
        self.init(Int64(value))
    }
    public var isSignalingNaN: Bool {
        return false
    }
    public static var nan: Decimal {
        return quietNaN
    }
    public static var quietNaN: Decimal {
        var quiet = Decimal()
        quiet._isNegative = 1
        return quiet
    }
    public var floatingPointClass: FloatingPointClassification {
        if _length == 0 && _isNegative == 1 {
            return .quietNaN
        } else if _length == 0 {
            return .positiveZero
        }
        if _isNegative == 1 {
            return .negativeNormal
        } else {
            return .positiveNormal
        }
    }
    public var isSignMinus: Bool {
        return _isNegative != 0
    }
    public var isNormal: Bool {
        return !isZero && !isInfinite && !isNaN
    }
    public var isFinite: Bool {
        return !isNaN
    }
    public var isZero: Bool {
        return _length == 0 && _isNegative == 0
    }
    public var isSubnormal: Bool {
        return false
    }
    public var isInfinite: Bool {
        return false
    }
    public var isNaN: Bool {
        return _length == 0 && _isNegative == 1
    }
    public var isSignaling: Bool {
        return false
    }
}

extension Decimal : CustomStringConvertible {
    public init?(string: String, locale: Locale? = nil) {
        let scan = Scanner(string: string)
        var theDecimal = Decimal()
        if !scan.scanDecimal(&theDecimal) {
            return nil
        }
        self = theDecimal
    }
    public var description: String {
        if self.isNaN {
            return "NaN"
        }
        if _length == 0 {
            return "0"
        }
        var copy = self
        let ZERO : CChar = 0x30 // ASCII '0' == 0x30
        let decimalChar : CChar = 0x2e // ASCII '.' == 0x2e
        let MINUS : CChar = 0x2d // ASCII '-' == 0x2d

        let bufferSize = 200 // max value : 39+128+sign+decimalpoint
        var buffer = Array<CChar>(repeating: 0, count: bufferSize)

        var i = bufferSize - 1
        while copy._exponent > 0 {
            i -= 1
            buffer[i] = ZERO
            copy._exponent -= 1
        }

        if copy._exponent == 0 {
            copy._exponent = 1
        }

        while copy._length != 0 {
            var remainder: UInt16 = 0
            if copy._exponent == 0 {
                i -= 1
                buffer[i] = decimalChar
            }
            copy._exponent += 1
            (remainder,_) = divideByShort(&copy, 10)
            i -= 1
            buffer[i] = Int8(remainder) + ZERO
        }
        if copy._exponent <= 0 {
            while copy._exponent != 0 {
                i -= 1
                buffer[i] = ZERO
                copy._exponent += 1
            }
            i -= 1
            buffer[i] = decimalChar
            i -= 1
            buffer[i] = ZERO
        }
        if copy._isNegative != 0 {
            i -= 1
            buffer[i] = MINUS
        }
        return String(cString: Array(buffer.suffix(from:i)))
    }
}

fileprivate func divideByShort(_ d: UnsafeMutablePointer<Decimal>, _ divisor:UInt16) -> (UInt16,NSDecimalNumber.CalculationError) {
    if divisor == 0 {
        d.pointee._length = 0
        return (0,.divideByZero)
    }
    // note the below is not the same as from length to 0 by -1
    var carry: UInt32 = 0
    for i in stride(from: 0, to: d.pointee._length, by: 1).reversed() {
        let accumulator = UInt32(d.pointee[i]) + carry * (1<<16)
        d.pointee[i] = UInt16(accumulator / UInt32(divisor))
        carry = accumulator % UInt32(divisor)
    }
    while d.pointee._length != 0 && d.pointee[d.pointee._length - 1] == 0 {
        d.pointee._length -= 1
    }
    return (UInt16(carry),.noError)
}

fileprivate func multiplyByShort(_ d: UnsafeMutablePointer<Decimal>, _ mul:UInt16) -> NSDecimalNumber.CalculationError {
    if mul == 0 {
        d.pointee._length = 0
        return .noError
    }
    var carry: UInt32 = 0
    // FIXME handle NSCalculationOverflow here?
    for i in 0..<d.pointee._length {
        let accumulator: UInt32 = UInt32(d.pointee[i]) * UInt32(mul) + carry
        carry = accumulator >> 16
        d.pointee[i] = UInt16(truncatingBitPattern: accumulator)
    }
    if carry != 0 {
        if Int32(d.pointee._length) == NSDecimalMaxSize {
            return .overflow
        }
        d.pointee[d.pointee._length] = UInt16(truncatingBitPattern: carry)
        d.pointee._length += 1
    }
    return .noError
}

fileprivate func addShort(_ d: UnsafeMutablePointer<Decimal>, _ add:UInt16) -> NSDecimalNumber.CalculationError {
    var carry:UInt32 = UInt32(add)
    for i in 0..<d.pointee._length {
        let accumulator: UInt32 = UInt32(d.pointee[i]) + carry
        carry = accumulator >> 16
        d.pointee[i] = UInt16(truncatingBitPattern: accumulator)
    }
    if carry != 0 {
        if Int32(d.pointee._length) == NSDecimalMaxSize {
            return .overflow
        }
        d.pointee[d.pointee._length] = UInt16(truncatingBitPattern: carry)
        d.pointee._length += 1
    }
    return .noError
}

public func NSDecimalIsNotANumber(_ dcm: UnsafePointer<Decimal>) -> Bool {
	return dcm.pointee.isNaN
}

/***************	Operations		***********/
public func NSDecimalCopy(_ destination: UnsafeMutablePointer<Decimal>, _ source: UnsafePointer<Decimal>) {
    destination.pointee.__lengthAndFlags = source.pointee.__lengthAndFlags
    destination.pointee.__exponent = source.pointee.__exponent
    destination.pointee.__reserved = source.pointee.__reserved
    destination.pointee._mantissa = source.pointee._mantissa
}

public func NSDecimalCompact(_ number: UnsafeMutablePointer<Decimal>) {
    number.pointee.compact()
}

// NSDecimalCompare:Compares leftOperand and rightOperand.
public func NSDecimalCompare(_ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>) -> ComparisonResult {
    let left = leftOperand.pointee
    let right = rightOperand.pointee
    return left.compare(to: right)
}

fileprivate extension UInt16 {
    func compareTo(_ other: UInt16) -> ComparisonResult {
        if self < other {
            return .orderedAscending
        } else if self > other {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
}

fileprivate func decimalCompare(
    _ left: Decimal,
    _ right: Decimal) -> ComparisonResult {

    if left._length > right._length {
        return .orderedDescending
    }
    if left._length < right._length {
        return .orderedAscending
    }
    let length = left._length // == right._length
    for i in 0..<length {
        let comparison = left[i].compareTo(right[i])
        if comparison != .orderedSame {
            return comparison
        }
    }
    return .orderedSame
}

public func NSDecimalRound(_ result: UnsafeMutablePointer<Decimal>, _ number: UnsafePointer<Decimal>, _ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode) {
    NSDecimalCopy(result,number) // this is unnecessary if they are the same address, but we can't test that here
    result.pointee.round(scale: scale,roundingMode: roundingMode)
}
// Rounds num to the given scale using the given mode.
// result may be a pointer to same space as num.
// scale indicates number of significant digits after the decimal point

public func NSDecimalNormalize(_ a: UnsafeMutablePointer<Decimal>, _ b: UnsafeMutablePointer<Decimal>, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError {
    var diffexp = a.pointee.__exponent - b.pointee.__exponent

    //
    // If the two numbers share the same exponents,
    // the normalisation is already done
    //
    if diffexp == 0 {
        return .noError
    }


    //
    // Put the smallest of the two in aa
    //
    var aa: UnsafeMutablePointer<Decimal>
    var bb: UnsafeMutablePointer<Decimal>

    if diffexp < 0 {
        aa = b
        bb = a
        diffexp = -diffexp
    } else {
        aa = a
        bb = b
    }
    
    // NSDecimalCopy(&backup,aa)

    //
    // Try to multiply aa to reach the same exponent level than bb
    //
    if aa.pointee.multiply(byPowerOf10: Int16(diffexp)) == .noError {
        // Succeed. Adjust the length/exponent info
        // and return no errorNSDecimalNormalize
        aa.pointee._isCompact = 0
        aa.pointee._exponent = bb.pointee._exponent
        return .noError;
    }
    
    NSUnimplemented() // work in progress
}

public func NSDecimalAdd(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError { NSUnimplemented() }
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalSubtract(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError { NSUnimplemented() }
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalMultiply(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError { NSUnimplemented() }
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalDivide(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError { NSUnimplemented() }
// Division could be silently inexact;
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalPower(_ result: UnsafeMutablePointer<Decimal>, _ number: UnsafePointer<Decimal>, _ power: Int, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError { NSUnimplemented() }

public func NSDecimalMultiplyByPowerOf10(_ result: UnsafeMutablePointer<Decimal>, _ number: UnsafePointer<Decimal>, _ power: Int16, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError {
    NSDecimalCopy(result,number)
    return result.pointee.multiply(byPowerOf10: power)
}

public func NSDecimalString(_ dcm: UnsafePointer<Decimal>, _ locale: AnyObject?) -> String {
    guard locale == nil else {
        NSUnimplemented()
    }
    return dcm.pointee.description
}

// == Internal (Swifty) functions ==

extension Decimal {
    fileprivate var isCompact: Bool {
        get {
            return _isCompact != 0
        }
        set {
            _isCompact = newValue ? 1 : 0
        }
    }
    fileprivate mutating func compact() {
        if isCompact || isNaN || _length == 0 {
            return
        }
        var newExponent = self._exponent
        var remainder: UInt16 = 0
        // Divide by 10 as much as possible
        repeat {
            (remainder,_) = divideByShort(&self,10)
            newExponent += 1
        } while remainder == 0
        // Put the non-empty remainder in place
        _ = multiplyByShort(&self,10)
        _ = addShort(&self,remainder)
        newExponent -= 1
        // Set the new exponent
        while newExponent > Int32(Int8.max) {
            _ = multiplyByShort(&self,10)
            newExponent -= 1
        }
        _exponent = newExponent
        isCompact = true
    }
    fileprivate mutating func round(scale:Int, roundingMode:RoundingMode) {
        // scale is the number of digits after the decimal point
        var s = scale + _exponent
        if s == NSDecimalNoScale || s >= 0 {
            return
        }
        s = -s
        var remainder: UInt16 = 0
        var previousRemainder = false

        let negative = _isNegative != 0
        var newExponent = _exponent + s
        while s > 4 {
            if remainder != 0 {
                previousRemainder = true
            }
            (remainder,_) = divideByShort(&self, 10000)
            s -= 4
        }
        while s > 0 {
            if remainder != 0 {
                previousRemainder = true
            }
            (remainder,_) = divideByShort(&self, 10)
            s -= 1
        }
        // If we are on a tie, adjust with premdr. .50001 is equivalent to .6
        if previousRemainder && (remainder == 0 || remainder == 5) {
            remainder += 1;
        }
        if remainder != 0 {
            if negative {
                switch roundingMode {
                case .up:
                    break
                case .bankers:
                    if remainder == 5 && (self[0] & 1) == 0 {
                        remainder += 1
                    }
                    fallthrough
                case .plain:
                    if remainder < 5 {
                        break
                    }
                    fallthrough
                case .down:
                    _ = addShort(&self, 1)
                }
                if _length == 0 {
                    _isNegative = 0;
                }
            } else {
                switch roundingMode {
                case .down:
                    break
                case .bankers:
                    if remainder == 5 && (self[0] & 1) == 0 {
                        remainder -= 1
                    }
                    fallthrough
                case .plain:
                    if remainder < 5 {
                        break
                    }
                    fallthrough
                case .up:
                    _ = addShort(&self, 1)
                }
            }
        }
        _isCompact = 0;
        
        while newExponent > Int32(Int8.max) {
            newExponent -= 1;
            _ = multiplyByShort(&self, 10);
        }
        _exponent = newExponent;
        self.compact();
    }
    fileprivate func compare(to other:Decimal) -> ComparisonResult {
        // NaN is a special case and is arbitrary ordered before everything else
        // Conceptually comparing with NaN is bogus anyway but raising or
        // always returning the same answer will confuse the sorting algorithms
        if self.isNaN {
            return other.isNaN ? .orderedSame : .orderedAscending
        }
        if other.isNaN {
            return .orderedDescending
        }
        // Check the sign
        if self._isNegative > other._isNegative {
            return .orderedAscending
        }
        if self._isNegative < other._isNegative {
            return .orderedDescending
        }
        // If one of the two is == 0, the other is bigger
        // because 0 implies isNegative = 0...
        if self.isZero && other.isZero {
            return .orderedSame
        }
        if self.isZero {
            return .orderedAscending
        }
        if other.isZero {
            return .orderedDescending
        }
        var selfNormal = self
        var otherNormal = other
        _ = NSDecimalNormalize(&selfNormal, &otherNormal, .down)
        let comparison = decimalCompare(selfNormal,otherNormal)
        if selfNormal._isNegative == 1 {
            if comparison == .orderedDescending {
                return .orderedAscending
            } else if comparison == .orderedAscending {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
        return comparison
    }
    fileprivate subscript(index:UInt32) -> UInt16 {
        get {
            switch index {
            case 0: return _mantissa.0
            case 1: return _mantissa.1
            case 2: return _mantissa.2
            case 3: return _mantissa.3
            case 4: return _mantissa.4
            case 5: return _mantissa.5
            case 6: return _mantissa.6
            case 7: return _mantissa.7
            default: fatalError("Invalid index \(index) for _mantissa")
            }
        }
        set {
            switch index {
            case 0: _mantissa.0 = newValue
            case 1: _mantissa.1 = newValue
            case 2: _mantissa.2 = newValue
            case 3: _mantissa.3 = newValue
            case 4: _mantissa.4 = newValue
            case 5: _mantissa.5 = newValue
            case 6: _mantissa.6 = newValue
            case 7: _mantissa.7 = newValue
            default: fatalError("Invalid index \(index) for _mantissa")
            }
        }
    }
    fileprivate mutating func setNaN() {
        _length = 0
        _isNegative = 1
    }
    fileprivate mutating func multiply(byPowerOf10 power:Int16) -> CalculationError {
        if isNaN {
            return .overflow
        }
        if isZero {
            return .noError
        }
        let newExponent = _exponent + Int32(power)
        if newExponent < Int32(Int8.min) {
            setNaN()
            return .underflow
        }
        if newExponent > Int32(Int8.max) {
            setNaN()
            return .overflow
        }
        _exponent = newExponent
        return .noError
    }
}
