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
    fileprivate static let maxSize: UInt32 = UInt32(NSDecimalMaxSize)
    fileprivate var __exponent: Int8
    fileprivate var __lengthAndFlags: UInt8
    fileprivate var __reserved: UInt16
    public var _exponent: Int32 {
        get {
            return Int32(__exponent)
        }
        set {
            __exponent = Int8(truncatingIfNeeded: newValue)
        }
    }
    // length == 0 && isNegative -> NaN
    public var _length: UInt32 {
        get {
            return UInt32((__lengthAndFlags & 0b0000_1111))
        }
        set {
            guard newValue <= maxMantissaLength else {
                fatalError("Attempt to set a length greater than capacity \(newValue) > \(maxMantissaLength)")
            }
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

    fileprivate init(length: UInt32, mantissa: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)) {
        self._mantissa = mantissa
        self.__exponent = 0
        self.__lengthAndFlags = 0
        self.__reserved = 0
        self._length = length
    }

    public init(_exponent: Int32, _length: UInt32, _isNegative: UInt32, _isCompact: UInt32, _reserved: UInt32, _mantissa: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)){
        self._mantissa = _mantissa
        self.__exponent = Int8(truncatingIfNeeded: _exponent)
        self.__lengthAndFlags = UInt8(_length & 0b1111)
        self.__reserved = 0
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
}

extension Decimal : Hashable, Comparable {
    internal var doubleValue: Double {
        var d = 0.0
        if _length == 0 && _isNegative == 1 {
            return Double.nan
        }
        
        d = d * 65536 + Double(_mantissa.7)
        d = d * 65536 + Double(_mantissa.6)
        d = d * 65536 + Double(_mantissa.5)
        d = d * 65536 + Double(_mantissa.4)
        d = d * 65536 + Double(_mantissa.3)
        d = d * 65536 + Double(_mantissa.2)
        d = d * 65536 + Double(_mantissa.1)
        d = d * 65536 + Double(_mantissa.0)
        
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

extension Decimal : SignedNumeric {
    public var magnitude: Decimal {
        return Decimal(_exponent: _exponent, _length: _length, _isNegative: 0, _isCompact: _isCompact, _reserved: 0, _mantissa: _mantissa)
    }

    // FIXME(integers): implement properly
    public init?<T : BinaryInteger>(exactly source: T) {
        fatalError()
    }

    public static func +=(_ lhs: inout Decimal, _ rhs: Decimal) {
        var leftOp = lhs
        var rightOp = rhs
        _ = NSDecimalAdd(&lhs, &leftOp, &rightOp, .plain)
    }

    public static func -=(_ lhs: inout Decimal, _ rhs: Decimal) {
        var leftOp = lhs
        var rightOp = rhs
        _ = NSDecimalSubtract(&lhs, &leftOp, &rightOp, .plain)
    }

    public static func *=(_ lhs: inout Decimal, _ rhs: Decimal) {
        var leftOp = lhs
        var rightOp = rhs
        _ = NSDecimalMultiply(&lhs, &leftOp, &rightOp, .plain)
    }

    public static func /=(_ lhs: inout Decimal, _ rhs: Decimal) {
        var leftOp = lhs
        var rightOp = rhs
        _ = NSDecimalDivide(&lhs, &leftOp, &rightOp, .plain)
    }

    public static func +(lhs: Decimal, rhs: Decimal) -> Decimal {
        var answer = lhs
        answer += rhs
        return answer;
    }

    public static func -(lhs: Decimal, rhs: Decimal) -> Decimal {
        var answer = lhs
        answer -= rhs
        return answer;
    }

    public static func /(lhs: Decimal, rhs: Decimal) -> Decimal {
        var answer = lhs
        answer /= rhs
        return answer;
    }

    public static func *(lhs: Decimal, rhs: Decimal) -> Decimal {
        var answer = lhs
        answer *= rhs
        return answer;
    }

    @available(*, unavailable, message: "Decimal does not yet fully adopt FloatingPoint.")
    public mutating func formTruncatingRemainder(dividingBy other: Decimal) { fatalError("Decimal does not yet fully adopt FloatingPoint") }

    public mutating func negate() {
        guard _length != 0 else { return }
        _isNegative = _isNegative == 0 ? 1 : 0
    }
}

extension Decimal {
    @available(swift, obsoleted: 4, message: "Please use arithmetic operators instead")
    @_transparent
    public mutating func add(_ other: Decimal) {
        self += other
    }

    @available(swift, obsoleted: 4, message: "Please use arithmetic operators instead")
    @_transparent
    public mutating func subtract(_ other: Decimal) {
        self -= other
    }

    @available(swift, obsoleted: 4, message: "Please use arithmetic operators instead")
    @_transparent
    public mutating func multiply(by other: Decimal) {
        self *= other
    }

    @available(swift, obsoleted: 4, message: "Please use arithmetic operators instead")
    @_transparent
    public mutating func divide(by other: Decimal) {
        self /= other
    }
}

extension Decimal : Strideable {
    public func distance(to other: Decimal) -> Decimal {
        return self - other
    }
    public func advanced(by n: Decimal) -> Decimal {
        return self + n
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
        precondition(!value.isInfinite, "Decimal does not yet fully adopt FloatingPoint")
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
                    _mantissa.0 = UInt16(truncatingIfNeeded:mantissa)
                case 1:
                    _mantissa.1 = UInt16(truncatingIfNeeded:mantissa)
                case 2:
                    _mantissa.2 = UInt16(truncatingIfNeeded:mantissa)
                case 3:
                    _mantissa.3 = UInt16(truncatingIfNeeded:mantissa)
                case 4:
                    _mantissa.4 = UInt16(truncatingIfNeeded:mantissa)
                case 5:
                    _mantissa.5 = UInt16(truncatingIfNeeded:mantissa)
                case 6:
                    _mantissa.6 = UInt16(truncatingIfNeeded:mantissa)
                case 7:
                    _mantissa.7 = UInt16(truncatingIfNeeded:mantissa)
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
        self = Decimal()
        if value == 0 {
            return
        }

        var compactValue = value
        var exponent: Int32 = 0
        while compactValue % 10 == 0 {
            compactValue = compactValue / 10
            exponent = exponent + 1
        }
        _isCompact = 1
        _exponent = exponent

        let wordCount = ((UInt64.bitWidth - compactValue.leadingZeroBitCount) + (UInt16.bitWidth - 1)) / UInt16.bitWidth
        _length = UInt32(wordCount)
        _mantissa.0 = UInt16(truncatingIfNeeded: compactValue >> 0)
        _mantissa.1 = UInt16(truncatingIfNeeded: compactValue >> 16)
        _mantissa.2 = UInt16(truncatingIfNeeded: compactValue >> 32)
        _mantissa.3 = UInt16(truncatingIfNeeded: compactValue >> 48)
    }

    public init(_ value: Int64) {
        if value < 0 {
            self.init(value == Int64.min ? UInt64(Int64.max) + 1 : UInt64(abs(value)))
            _isNegative = 1
        } else {
            self.init(UInt64(value))
        }
    }

    public init(_ value: UInt) {
        self.init(UInt64(value))
    }

    public init(_ value: Int) {
        self.init(Int64(value))
    }

    @available(*, unavailable, message: "Decimal does not yet fully adopt FloatingPoint.")
    public static var infinity: Decimal { fatalError("Decimal does not yet fully adopt FloatingPoint") }

    @available(*, unavailable, message: "Decimal does not yet fully adopt FloatingPoint.")
    public static var signalingNaN: Decimal { fatalError("Decimal does not yet fully adopt FloatingPoint") }

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

fileprivate func divideByShort<T:VariableLengthNumber>(_ d: inout T, _ divisor:UInt16) -> (UInt16,NSDecimalNumber.CalculationError) {
    if divisor == 0 {
        d._length = 0
        return (0,.divideByZero)
    }
    // note the below is not the same as from length to 0 by -1
    var carry: UInt32 = 0
    for i in (0..<d._length).reversed() {
        let accumulator = UInt32(d[i]) + carry * (1<<16)
        d[i] = UInt16(accumulator / UInt32(divisor))
        carry = accumulator % UInt32(divisor)
    }
    d.trimTrailingZeros()
    return (UInt16(carry),.noError)
}

fileprivate func multiplyByShort<T:VariableLengthNumber>(_ d: inout T, _ mul:UInt16) -> NSDecimalNumber.CalculationError {
    if mul == 0 {
        d._length = 0
        return .noError
    }
    var carry: UInt32 = 0
    // FIXME handle NSCalculationOverflow here?
    for i in 0..<d._length {
        let accumulator: UInt32 = UInt32(d[i]) * UInt32(mul) + carry
        carry = accumulator >> 16
        d[i] = UInt16(truncatingIfNeeded: accumulator)
    }
    if carry != 0 {
        if d._length >= Decimal.maxSize {
            return .overflow
        }
        d[d._length] = UInt16(truncatingIfNeeded: carry)
        d._length += 1
    }
    return .noError
}

fileprivate func addShort<T:VariableLengthNumber>(_ d: inout T, _ add:UInt16) -> NSDecimalNumber.CalculationError {
    var carry:UInt32 = UInt32(add)
    for i in 0..<d._length {
        let accumulator: UInt32 = UInt32(d[i]) + carry
        carry = accumulator >> 16
        d[i] = UInt16(truncatingIfNeeded: accumulator)
    }
    if carry != 0 {
        if d._length >= Decimal.maxSize {
            return .overflow
        }
        d[d._length] = UInt16(truncatingIfNeeded: carry)
        d._length += 1
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

fileprivate func mantissaCompare<T:VariableLengthNumber>(
    _ left: T,
    _ right: T) -> ComparisonResult {

    if left._length > right._length {
        return .orderedDescending
    }
    if left._length < right._length {
        return .orderedAscending
    }
    let length = left._length // == right._length
    for i in (0..<length).reversed() {
        let comparison = left[i].compareTo(right[i])
        if comparison != .orderedSame {
            return comparison
        }
    }
    return .orderedSame
}

fileprivate func fitMantissa(_ big: inout WideDecimal, _ exponent: inout Int32, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError {

    if big._length <= Decimal.maxSize {
        return .noError
    }

    var remainder: UInt16 = 0
    var previousRemainder: Bool = false

    // Divide by 10 as much as possible
    while big._length > Decimal.maxSize + 1 {
        if remainder != 0 {
            previousRemainder = true
        }
        (remainder,_) = divideByShort(&big,10000)
        exponent += 4
    }

    while big._length > Decimal.maxSize {
        if remainder != 0 {
            previousRemainder = true
        }
        (remainder,_) = divideByShort(&big,10)
        exponent += 1
    }

    // If we are on a tie, adjust with previous remainder.
    // .50001 is equivalent to .6
    if previousRemainder && (remainder == 0 || remainder == 5) {
        remainder += 1
    }

    if remainder == 0 {
        return .noError
    }

    // Round the result
    switch roundingMode  {
    case .down:
        break
    case .bankers:
        if remainder == 5 && (big[0] & 1) == 0 {
            break
        }
        fallthrough
    case .plain:
        if remainder < 5 {
            break
        }
        fallthrough
    case .up:
        let originalLength = big._length
        // big._length += 1 ??
        _ = addShort(&big,1)
        if originalLength > big._length {
            // the last digit is == 0. Remove it.
            _ = divideByShort(&big, 10)
            exponent += 1
        }
    }
    return .lossOfPrecision;
}

fileprivate func integerMultiply<T:VariableLengthNumber>(_ big: inout T,
                                 _ left: T,
                                 _ right: Decimal) -> NSDecimalNumber.CalculationError {
    if left._length == 0 || right._length == 0 {
        big._length = 0
        return .noError
    }

    if big._length == 0 || big._length > left._length + right._length {
        big._length = min(big.maxMantissaLength,left._length + right._length)
    }

    big.zeroMantissa()

    var carry: UInt16 = 0

    for j in 0..<right._length {
        var accumulator: UInt32 = 0
        carry = 0

        for i in 0..<left._length {
            if i + j < big._length {
                let bigij = UInt32(big[i+j])
                accumulator = UInt32(carry) + bigij + UInt32(right[j]) * UInt32(left[i])
                carry = UInt16(truncatingIfNeeded:accumulator >> 16)
                big[i+j] = UInt16(truncatingIfNeeded:accumulator)
            } else if carry != 0 || (right[j] == 0 && left[j] == 0) {
                return .overflow
            }
        }

        if carry != 0 {
            if left._length + j < big._length {
                big[left._length + j] = carry
            } else {
                return .overflow
            }
        }
    }

    big.trimTrailingZeros()

    return .noError
}

fileprivate func integerDivide<T:VariableLengthNumber>(_ r: inout T,
                               _ cu: T,
                               _ cv: Decimal) -> NSDecimalNumber.CalculationError {
    // Calculate result = a / b.
    // Result could NOT be a pointer to same space as a or b.
    // resultLen must be >= aLen - bLen.
    //
    // Based on algorithm in The Art of Computer Programming, Volume 2,
    // Seminumerical Algorithms by Donald E. Knuth, 2nd Edition. In addition
    // you need to consult the erratas for the book available at:
    //
    //   http://www-cs-faculty.stanford.edu/~uno/taocp.html

    var u = WideDecimal(true)
    var v = WideDecimal(true) // divisor

    // Simple case
    if cv.isZero {
        return .divideByZero;
    }

    // If u < v, the result is approximately 0...
    if cu._length < cv._length {
        for i in 0..<cv._length {
            if cu[i] < cv[i] {
                r._length = 0
                return .noError;
            }
        }
    }

    // Fast algorithm
    if cv._length == 1 {
        r = cu
        let (_,error) = divideByShort(&r, cv[0])
        return error
    }

    u.copyMantissa(from: cu)
    v.copyMantissa(from: cv)

    u._length = cu._length + 1
    v._length = cv._length + 1

    // D1: Normalize
    // Calculate d such that d*highest_digit of v >= b/2 (0x8000)
    //
    // I could probably use something smarter to get d to be a power of 2.
    // In this case the multiply below became only a shift.
    let d: UInt32 = UInt32((1 << 16) / Int(cv[cv._length - 1] + 1))

    // This is to make the whole algorithm work and u*d/v*d == u/v
    _ = multiplyByShort(&u, UInt16(d))
    _ = multiplyByShort(&v, UInt16(d))

    u.trimTrailingZeros()
    v.trimTrailingZeros()

    // Set a zero at the leftmost u position if the multiplication
    // does not have a carry.
    if u._length == cu._length {
        u[u._length] = 0
        u._length += 1
    }

    v[v._length] = 0; // Set a zero at the leftmost v position.
    // the algorithm will use it during the
    // multiplication/subtraction phase.

    // Determine the size of the quotient.
    // It's an approximate value.
    let ql:UInt16 = UInt16(u._length - v._length)

    // Some useful constants for the loop
    // It's used to determine the quotient digit as fast as possible
    // The test vl > 1 is probably useless, since optimizations
    // up there are taking over this case. I'll keep it, just in case.
    let v1:UInt16 = v[v._length-1]
    let v2:UInt16 = v._length > 1 ? v[v._length-2] : 0

    // D2: initialize j
    // On each pass, build a single value for the quotient.
    for j in 0..<ql {

        // D3: calculate q^
        // This formula and test for q gives at most q+1; See Knuth for proof.

        let ul = u._length
        let tmp:UInt32 = UInt32(u[ul - UInt32(j) - UInt32(1)]) << 16 + UInt32(u[ul - UInt32(j) - UInt32(2)])
        var q:UInt32 = tmp / UInt32(v1) // Quotient digit. could be a short.
        var rtmp:UInt32 = tmp % UInt32(v1)

        // This test catches all cases where q is really q+2 and
        // most where it is q+1
        if q == (1 << 16) || UInt32(v2) * q > (rtmp<<16) + UInt32(u[ul - UInt32(j) - UInt32(3)]) {
            q -= 1
            rtmp += UInt32(v1)

            if (rtmp < (1 << 16)) && ( (q == (1 << 16) ) || ( UInt32(v2) * q > (rtmp<<16) + UInt32(u[ul - UInt32(j) - UInt32(3)])) ) {
                q -= 1
                rtmp += UInt32(v1)
            }
        }

        // D4: multiply and subtract.

        var mk:UInt32 = 0 // multiply carry
        var sk:UInt32 = 1 // subtraction carry
        var acc:UInt32

        // We perform a multiplication and a subtraction
        // during the same pass...
        for i in 0...v._length {
            let ul = u._length
            let vl = v._length
            acc = q * UInt32(v[i]) + mk     // multiply
            mk = acc >> 16                  // multiplication carry
            acc = acc & 0xffff;
            acc = 0xffff + UInt32(u[ul - vl + i - UInt32(j) - UInt32(1)]) - acc + sk; // subtract
            sk = acc >> 16;
            u[ul - vl + i - UInt32(j) - UInt32(1)] = UInt16(truncatingIfNeeded:acc)
        }

        // D5: test remainder
        // This test catches cases where q is still q + 1
        if sk == 0 {
            // D6: add back.
            var k:UInt32 = 0 // Addition carry

            // subtract one from the quotient digit
            q -= 1
            for i in 0...v._length {
                let ul = u._length
                let vl = v._length
                acc = UInt32(v[i]) + UInt32(u[UInt32(ul) - UInt32(vl) + UInt32(i) - UInt32(j) - UInt32(1)]) + k
                k = acc >> 16;
                u[UInt32(ul) - UInt32(vl) + UInt32(i) - UInt32(j) - UInt32(1)] = UInt16(truncatingIfNeeded:acc)
            }
            // k must be == 1 here
        }

        r[UInt32(ql - j - UInt16(1))] = UInt16(q)
        // D7: loop on j
    }

    r._length = UInt32(ql);

    r.trimTrailingZeros()

    return .noError;
}

fileprivate func integerMultiplyByPowerOf10<T:VariableLengthNumber>(_ result: inout T, _ left: T, _ p: Int) -> NSDecimalNumber.CalculationError {
    var power = p
    if power == 0 {
        result = left
        return .noError
    }
    let isNegative = power < 0
    if isNegative {
        power = -power
    }
    result = left

    let maxpow10 = pow10.count - 1
    var error:NSDecimalNumber.CalculationError = .noError

    while power > maxpow10 {
        var big = T()

        power -= maxpow10
        let p10 = pow10[maxpow10]

        if !isNegative {
            error = integerMultiply(&big,result,p10)
        } else {
            error = integerDivide(&big,result,p10)
        }

        if error != .noError && error != .lossOfPrecision {
            return error;
        }

        for i in 0..<big._length {
            result[i] = big[i]
        }

        result._length = big._length
    }

    var big = T()

    // Handle the rest of the power (<= maxpow10)
    let p10 = pow10[Int(power)]

    if !isNegative {
        error = integerMultiply(&big, result, p10)
    } else {
        error = integerDivide(&big, result, p10)
    }

    for i in 0..<big._length {
        result[i] = big[i]
    }

    result._length = big._length

    return error;
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
    var result = Decimal()

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

    //
    // Build a backup for aa
    //
    var backup = Decimal()

    NSDecimalCopy(&backup,aa)

    //
    // Try to multiply aa to reach the same exponent level than bb
    //

    if integerMultiplyByPowerOf10(&result, aa.pointee, Int(diffexp)) == .noError {
        // Succeed. Adjust the length/exponent info
        // and return no errorNSDecimalNormalize
        aa.pointee.copyMantissa(from: result)
        aa.pointee._exponent = bb.pointee._exponent
        return .noError;
    }

    //
    // Failed, restart from scratch
    //
    NSDecimalCopy(aa, &backup);

    //
    // What is the maximum pow10 we can apply to aa ?
    //
    let logBase10of2to16 = 4.81647993
    let aaLength = aa.pointee._length
    let maxpow10 = Int8(floor(Double(Decimal.maxSize - aaLength) * logBase10of2to16))

    //
    // Divide bb by this value
    //
    _ = integerMultiplyByPowerOf10(&result, bb.pointee, Int(maxpow10 - diffexp))

    bb.pointee.copyMantissa(from: result)
    bb.pointee._exponent -= Int32(maxpow10 - diffexp);

    //
    // If bb > 0 multiply aa by the same value
    //
    if !bb.pointee.isZero {
        _ = integerMultiplyByPowerOf10(&result, aa.pointee, Int(maxpow10))
        aa.pointee.copyMantissa(from: result)
        aa.pointee._exponent -= Int32(maxpow10)
    } else {
        bb.pointee._exponent = aa.pointee._exponent;
    }

    //
    // the two exponents are now identical, but we've lost some digits in the operation.
    //
    return .lossOfPrecision;
}

public func NSDecimalAdd(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError {
    if leftOperand.pointee.isNaN || rightOperand.pointee.isNaN {
        result.pointee.setNaN()
        return .overflow
    }
    if leftOperand.pointee.isZero {
        NSDecimalCopy(result, rightOperand)
        return .noError
    } else if rightOperand.pointee.isZero {
        NSDecimalCopy(result, leftOperand)
        return .noError
    } else {
        var a = Decimal()
        var b = Decimal()
        var error:NSDecimalNumber.CalculationError = .noError

        NSDecimalCopy(&a,leftOperand)
        NSDecimalCopy(&b,rightOperand)

        let normalizeError = NSDecimalNormalize(&a, &b,roundingMode)

        if a.isZero {
            NSDecimalCopy(result,&b)
            return normalizeError
        }
        if b.isZero {
            NSDecimalCopy(result,&a)
            return normalizeError
        }

        result.pointee._exponent = a._exponent

        if a.isNegative == b.isNegative {
            var big = WideDecimal()
            result.pointee.isNegative = a.isNegative

            // No possible error here.
            _ = integerAdd(&big,&a,&b)

            if big._length > Decimal.maxSize {
                var exponent:Int32 = 0
                error = fitMantissa(&big, &exponent, roundingMode)

                let newExponent = result.pointee._exponent + exponent

                // Just to be sure!
                if newExponent > Int32(Int8.max) {
                    result.pointee.setNaN()
                    return .overflow
                }
                result.pointee._exponent = newExponent
            }
            let length = min(Decimal.maxSize,big._length)
            for i in 0..<length {
                result.pointee[i] = big[i]
            }
            result.pointee._length = length
        } else { // not the same sign
            let comparison = mantissaCompare(a,b)

            switch comparison {
            case .orderedSame:
                result.pointee.setZero()
            case .orderedAscending:
                _ = integerSubtract(&result.pointee,&b,&a)
                result.pointee.isNegative = b.isNegative
            case .orderedDescending:
                _ = integerSubtract(&result.pointee,&a,&b)
                result.pointee.isNegative = a.isNegative
            }
        }
        result.pointee._isCompact = 0
        NSDecimalCompact(result)
        return error == .noError ? normalizeError : error
    }
}

fileprivate func integerAdd(_ result: inout WideDecimal, _ left: inout Decimal, _ right: inout Decimal) -> NSDecimalNumber.CalculationError {
    var idx: UInt32 = 0
    var carry: UInt16 = 0
    let maxIndex: UInt32 = min(left._length, right._length) // The highest index with bits set in both values

    while idx < maxIndex {
        let li = UInt32(left[idx])
        let ri = UInt32(right[idx])
        let sum = li + ri + UInt32(carry)
        carry = UInt16(truncatingIfNeeded: sum >> 16)
        result[idx] = UInt16(truncatingIfNeeded: sum)
        idx += 1
    }

    while idx < left._length {
        if carry != 0 {
            let li = UInt32(left[idx])
            let sum = li + UInt32(carry)
            carry = UInt16(truncatingIfNeeded: sum >> 16)
            result[idx] = UInt16(truncatingIfNeeded: sum)
            idx += 1
        } else {
            while idx < left._length {
                result[idx] = left[idx]
                idx += 1
            }
            break
        }
    }
    while idx < right._length {
        if carry != 0 {
            let ri = UInt32(right[idx])
            let sum = ri + UInt32(carry)
            carry = UInt16(truncatingIfNeeded: sum >> 16)
            result[idx] = UInt16(truncatingIfNeeded: sum)
            idx += 1
        } else {
            while idx < right._length {
                result[idx] = right[idx]
                idx += 1
            }
            break
        }
    }
    result._length = idx

    if carry != 0 {
        result[idx] = carry
        idx += 1
        result._length = idx
    }
    if idx > Decimal.maxSize {
        return .overflow
    }

    return .noError;
}

// integerSubtract: Subtract b from a, put the result in result, and
//     modify resultLen to match the length of the result.
// Result may be a pointer to same space as a or b.
// resultLen must be >= Max(aLen,bLen).
// Could return NSCalculationOverflow if b > a. In this case 0 - result
//    give b-a...
//
fileprivate func integerSubtract(_ result: inout Decimal, _ left: inout Decimal, _ right: inout Decimal) -> NSDecimalNumber.CalculationError {
    var idx: UInt32 = 0
    let maxIndex: UInt32 = min(left._length, right._length) // The highest index with bits set in both values
    var borrow: UInt16 = 0

    while idx < maxIndex {
        let li = UInt32(left[idx])
        let ri = UInt32(right[idx])
        // 0x10000 is to borrow in advance to avoid underflow.
        let difference: UInt32 = (0x10000 + li) - UInt32(borrow) - ri
        result[idx] = UInt16(truncatingIfNeeded: difference)
        // borrow = 1 if the borrow was used.
        borrow = 1 - UInt16(truncatingIfNeeded: difference >> 16)
        idx += 1
    }

    while idx < left._length {
        if borrow != 0 {
            let li = UInt32(left[idx])
            let sum = 0xffff + li // + no carry
            borrow = 1 - UInt16(truncatingIfNeeded: sum >> 16)
            result[idx] = UInt16(truncatingIfNeeded: sum)
            idx += 1
        } else {
            while idx < left._length {
                result[idx] = left[idx]
                idx += 1
            }
            break
        }
    }
    while idx < right._length {
        let ri = UInt32(right[idx])
        let difference = 0xffff - ri + UInt32(borrow)
        borrow = 1 - UInt16(truncatingIfNeeded: difference >> 16)
        result[idx] = UInt16(truncatingIfNeeded: difference)
        idx += 1
    }

    if borrow != 0 {
        return .overflow
    }
    result._length = idx;
    result.trimTrailingZeros()

    return .noError;
}

// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalSubtract(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError {
    var r = rightOperand.pointee
    r.negate()
    return NSDecimalAdd(result, leftOperand, &r, roundingMode)
}
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalMultiply(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError {

    if leftOperand.pointee.isNaN || rightOperand.pointee.isNaN {
        result.pointee.setNaN()
        return .overflow
    }
    if leftOperand.pointee.isZero || rightOperand.pointee.isZero {
        result.pointee.setZero()
        return .noError
    }

    var big = WideDecimal()
    var calculationError:NSDecimalNumber.CalculationError = .noError

    calculationError = integerMultiply(&big,WideDecimal(leftOperand.pointee),rightOperand.pointee)

    result.pointee._isNegative = (leftOperand.pointee._isNegative + rightOperand.pointee._isNegative) % 2

    var newExponent = leftOperand.pointee._exponent + rightOperand.pointee._exponent

    if big._length > Decimal.maxSize {
        var exponent:Int32 = 0
        calculationError = fitMantissa(&big, &exponent, roundingMode)
        newExponent += exponent
    }

    for i in 0..<big._length {
       result.pointee[i] = big[i]
    }
    result.pointee._length = big._length
    result.pointee._isCompact = 0

    if newExponent > Int32(Int8.max) {
        result.pointee.setNaN()
        return .overflow
    }
    result.pointee._exponent = newExponent
    NSDecimalCompact(result)
    return calculationError
}
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalDivide(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError {

    if leftOperand.pointee.isNaN || rightOperand.pointee.isNaN {
        result.pointee.setNaN()
        return .overflow
    }
    if rightOperand.pointee.isZero {
        result.pointee.setNaN()
        return .divideByZero
    }
    if leftOperand.pointee.isZero {
        result.pointee.setZero()
        return .noError
    }
    var a = Decimal()
    var b = Decimal()
    var big = WideDecimal()
    var exponent:Int32 = 0

    NSDecimalCopy(&a, leftOperand)
    NSDecimalCopy(&b, rightOperand)

    /* If the precision of the left operand is much smaller
     * than that of the right operand (for example,
     * 20 and 0.112314123094856724234234572), then the
     * difference in their exponents is large and a lot of
     * precision will be lost below. This is particularly
     * true as the difference approaches 38 or larger.
     * Normalizing here looses some precision on the
     * individual operands, but often produces a more
     * accurate result later. I chose 19 arbitrarily
     * as half of the magic 38, so that normalization
     * doesn't always occur. */
    if (19 <= Int(a._exponent - b._exponent)) {
        _ = NSDecimalNormalize(&a, &b, roundingMode);
        /* We ignore the small loss of precision this may
         * induce in the individual operands. */

        /* Sometimes the normalization done previously is inappropriate and
         * forces one of the operands to 0. If this happens, restore both. */
        if a.isZero || b.isZero {
            NSDecimalCopy(&a, leftOperand);
            NSDecimalCopy(&b, rightOperand);
        }
    }

    _ = integerMultiplyByPowerOf10(&big, WideDecimal(a), 38) // Trust me, it's 38 !
    _ = integerDivide(&big, big, b)
    _ = fitMantissa(&big, &exponent, .down)

    let length = min(big._length,Decimal.maxSize)
    for i in 0..<length {
        result.pointee[i] = big[i]
    }

    result.pointee._length = length

    result.pointee.isNegative = a._isNegative != b._isNegative

    exponent = a._exponent - b._exponent - 38 + exponent
    if exponent < Int32(Int8.min) {
        result.pointee.setNaN()
        return .underflow
    }
    if exponent > Int32(Int8.max) {
        result.pointee.setNaN()
        return .overflow;
    }
    result.pointee._exponent = Int32(exponent)
    result.pointee._isCompact = 0
    NSDecimalCompact(result)
    return .noError
}
// Division could be silently inexact;
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalPower(_ result: UnsafeMutablePointer<Decimal>, _ number: UnsafePointer<Decimal>, _ power: Int, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError {

    if number.pointee.isNaN {
        result.pointee.setNaN()
        return .overflow
    }
    NSDecimalCopy(result,number)
    return result.pointee.power(UInt(power), roundingMode:roundingMode)
}

public func NSDecimalMultiplyByPowerOf10(_ result: UnsafeMutablePointer<Decimal>, _ number: UnsafePointer<Decimal>, _ power: Int16, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError {
    NSDecimalCopy(result,number)
    return result.pointee.multiply(byPowerOf10: power)
}

public func NSDecimalString(_ dcm: UnsafePointer<Decimal>, _ locale: Any?) -> String {
    guard locale == nil else {
        fatalError("Locale not supported: \(locale!)")
    }
    return dcm.pointee.description
}

private func multiplyBy10(_ dcm: inout Decimal, andAdd extra:Int) -> NSDecimalNumber.CalculationError {
    let backup = dcm

    if multiplyByShort(&dcm, 10) == .noError && addShort(&dcm, UInt16(extra)) == .noError {
        return .noError
    } else {
        dcm = backup // restore the old values
        return .overflow // this is the only possible error
    }
}

fileprivate protocol VariableLengthNumber {
    var _length: UInt32 { get set }
    init()
    subscript(index:UInt32) -> UInt16 { get set }
    var isZero:Bool { get }
    mutating func copyMantissa<T:VariableLengthNumber>(from other:T)
    mutating func zeroMantissa()
    mutating func trimTrailingZeros()
    var maxMantissaLength: UInt32 { get }
}

extension Decimal: VariableLengthNumber {
    var maxMantissaLength:UInt32 {
        return Decimal.maxSize
    }
    fileprivate mutating func zeroMantissa() {
        for i in 0..<Decimal.maxSize {
            self[i] = 0
        }
    }
    internal mutating func trimTrailingZeros() {
        if _length > Decimal.maxSize {
            _length = Decimal.maxSize
        }
        while _length != 0 && self[_length - 1] == 0 {
            _length -= 1
        }
    }
    fileprivate mutating func copyMantissa<T : VariableLengthNumber>(from other: T) {
        if other._length > maxMantissaLength {
            for i in maxMantissaLength..<other._length {
                guard other[i] == 0 else {
                    fatalError("Loss of precision during copy other[\(i)] \(other[i]) != 0")
                }
            }
        }
        let length = min(other._length, maxMantissaLength)
        for i in 0..<length {
            self[i] = other[i]
        }
        self._length = length
        self._isCompact = 0
    }
}

// Provides a way with dealing with extra-length decimals, used for calculations
fileprivate struct WideDecimal : VariableLengthNumber {
    var maxMantissaLength:UInt32 {
        return _extraWide ? 17 : 16
    }

    fileprivate mutating func zeroMantissa() {
        for i in 0..<maxMantissaLength {
            self[i] = 0
        }
    }
    fileprivate mutating func trimTrailingZeros() {
        while _length != 0 && self[_length - 1] == 0 {
            _length -= 1
        }
    }
    init() {
        self.init(false)
    }

    fileprivate mutating func copyMantissa<T : VariableLengthNumber>(from other: T) {
        let length = other is Decimal ? min(other._length,Decimal.maxSize) : other._length
        for i in 0..<length {
            self[i] = other[i]
        }
        self._length = length
    }

    var isZero: Bool {
        return _length == 0
    }

    var __length: UInt16
    var _mantissa: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16,
        UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)
    // Most uses of this class use 16 shorts, but integer division uses 17 shorts
    var _extraWide: Bool
    var _length: UInt32 {
        get {
            return UInt32(__length)
        }
        set {
            guard newValue <= maxMantissaLength else {
                fatalError("Attempt to set a length greater than capacity \(newValue) > \(maxMantissaLength)")
            }
            __length = UInt16(newValue)
        }
    }
    init(_ extraWide:Bool = false) {
        __length = 0
        _mantissa = (UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0))
        _extraWide = extraWide
    }
    init(_ decimal:Decimal) {
        self.__length = UInt16(decimal._length)
        self._extraWide = false
        self._mantissa = (decimal[0],decimal[1],decimal[2],decimal[3],decimal[4],decimal[5],decimal[6],decimal[7],UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0),UInt16(0))
    }
    subscript(index:UInt32) -> UInt16 {
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
            case 8: return _mantissa.8
            case 9: return _mantissa.9
            case 10: return _mantissa.10
            case 11: return _mantissa.11
            case 12: return _mantissa.12
            case 13: return _mantissa.13
            case 14: return _mantissa.14
            case 15: return _mantissa.15
            case 16 where _extraWide: return _mantissa.16 // used in integerDivide
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
            case 8: _mantissa.8 = newValue
            case 9: _mantissa.9 = newValue
            case 10: _mantissa.10 = newValue
            case 11: _mantissa.11 = newValue
            case 12: _mantissa.12 = newValue
            case 13: _mantissa.13 = newValue
            case 14: _mantissa.14 = newValue
            case 15: _mantissa.15 = newValue
            case 16 where _extraWide: _mantissa.16 = newValue
            default: fatalError("Invalid index \(index) for _mantissa")
            }
        }
    }
    func toDecimal() -> Decimal {
        var result = Decimal()
        result._length = self._length
        for i in 0..<_length {
            result[i] = self[i]
        }
        return result
    }
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
    fileprivate var isNegative: Bool {
        get {
            return _isNegative != 0
        }
        set {
            _isNegative = newValue ? 1 : 0
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
        var s = Int32(scale) + _exponent
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
    internal func compare(to other:Decimal) -> ComparisonResult {
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
        let comparison = mantissaCompare(selfNormal,otherNormal)
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
    fileprivate mutating func setZero() {
        _length = 0
        _isNegative = 0
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
    fileprivate mutating func power(_ p:UInt, roundingMode:RoundingMode) -> CalculationError {
        if isNaN {
            return .overflow
        }
        var power = p
        if power == 0 {
            _exponent = 0
            _length = 1
            _isNegative = 0
            self[0] = 1
            _isCompact = 1
            return .noError
        } else if power == 1 {
            return .noError
        }

        var temporary = Decimal(1)
        var error:CalculationError = .noError

        while power > 1 {
            if power % 2 == 1 {
                let previousError = error
                var leftOp = temporary
                error = NSDecimalMultiply(&temporary, &leftOp, &self, roundingMode)

                if previousError != .noError { // FIXME is this the intent?
                    error = previousError
                }

                if error == .overflow || error == .underflow {
                    setNaN()
                    return error
                }
                power -= 1
            }
            if power != 0 {
                let previousError = error
                var leftOp = self
                var rightOp = self
                error = NSDecimalMultiply(&self, &leftOp, &rightOp, roundingMode)

                if previousError != .noError { // FIXME is this the intent?
                    error = previousError
                }

                if error == .overflow || error == .underflow {
                    setNaN()
                    return error
                }
                power /= 2
            }
        }
        let previousError = error
        var rightOp = self
        error = NSDecimalMultiply(&self, &temporary, &rightOp, roundingMode)

        if previousError != .noError { // FIXME is this the intent?
            error = previousError
        }

        if error == .overflow || error == .underflow {
            setNaN()
            return error
        }

        return error
    }
}

fileprivate let pow10 = [
/*^00*/ Decimal(length: 1, mantissa:( 0x0001,0,0,0,0,0,0,0)),
/*^01*/ Decimal(length: 1, mantissa:( 0x000a,0,0,0,0,0,0,0)),
/*^02*/ Decimal(length: 1, mantissa:( 0x0064,0,0,0,0,0,0,0)),
/*^03*/ Decimal(length: 1, mantissa:( 0x03e8,0,0,0,0,0,0,0)),
/*^04*/ Decimal(length: 1, mantissa:( 0x2710,0,0,0,0,0,0,0)),
/*^05*/ Decimal(length: 2, mantissa:( 0x86a0, 0x0001,0,0,0,0,0,0)),
/*^06*/ Decimal(length: 2, mantissa:( 0x4240, 0x000f,0,0,0,0,0,0)),
/*^07*/ Decimal(length: 2, mantissa:( 0x9680, 0x0098,0,0,0,0,0,0)),
/*^08*/ Decimal(length: 2, mantissa:( 0xe100, 0x05f5,0,0,0,0,0,0)),
/*^09*/ Decimal(length: 2, mantissa:( 0xca00, 0x3b9a,0,0,0,0,0,0)),
/*^10*/ Decimal(length: 3, mantissa:( 0xe400, 0x540b, 0x0002,0,0,0,0,0)),
/*^11*/ Decimal(length: 3, mantissa:( 0xe800, 0x4876, 0x0017,0,0,0,0,0)),
/*^12*/ Decimal(length: 3, mantissa:( 0x1000, 0xd4a5, 0x00e8,0,0,0,0,0)),
/*^13*/ Decimal(length: 3, mantissa:( 0xa000, 0x4e72, 0x0918,0,0,0,0,0)),
/*^14*/ Decimal(length: 3, mantissa:( 0x4000, 0x107a, 0x5af3,0,0,0,0,0)),
/*^15*/ Decimal(length: 4, mantissa:( 0x8000, 0xa4c6, 0x8d7e, 0x0003,0,0,0,0)),
/*^16*/ Decimal(length: 4, mantissa:( 0x0000, 0x6fc1, 0x86f2, 0x0023,0,0,0,0)),
/*^17*/ Decimal(length: 4, mantissa:( 0x0000, 0x5d8a, 0x4578, 0x0163,0,0,0,0)),
/*^18*/ Decimal(length: 4, mantissa:( 0x0000, 0xa764, 0xb6b3, 0x0de0,0,0,0,0)),
/*^19*/ Decimal(length: 4, mantissa:( 0x0000, 0x89e8, 0x2304, 0x8ac7,0,0,0,0)),
/*^20*/ Decimal(length: 5, mantissa:( 0x0000, 0x6310, 0x5e2d, 0x6bc7, 0x0005,0,0,0)),
/*^21*/ Decimal(length: 5, mantissa:( 0x0000, 0xdea0, 0xadc5, 0x35c9, 0x0036,0,0,0)),
/*^22*/ Decimal(length: 5, mantissa:( 0x0000, 0xb240, 0xc9ba, 0x19e0, 0x021e,0,0,0)),
/*^23*/ Decimal(length: 5, mantissa:( 0x0000, 0xf680, 0xe14a, 0x02c7, 0x152d,0,0,0)),
/*^24*/ Decimal(length: 5, mantissa:( 0x0000, 0xa100, 0xcced, 0x1bce, 0xd3c2,0,0,0)),
/*^25*/ Decimal(length: 6, mantissa:( 0x0000, 0x4a00, 0x0148, 0x1614, 0x4595, 0x0008,0,0)),
/*^26*/ Decimal(length: 6, mantissa:( 0x0000, 0xe400, 0x0cd2, 0xdcc8, 0xb7d2, 0x0052,0,0)),
/*^27*/ Decimal(length: 6, mantissa:( 0x0000, 0xe800, 0x803c, 0x9fd0, 0x2e3c, 0x033b,0,0)),
/*^28*/ Decimal(length: 6, mantissa:( 0x0000, 0x1000, 0x0261, 0x3e25, 0xce5e, 0x204f,0,0)),
/*^29*/ Decimal(length: 7, mantissa:( 0x0000, 0xa000, 0x17ca, 0x6d72, 0x0fae, 0x431e, 0x0001,0)),
/*^30*/ Decimal(length: 7, mantissa:( 0x0000, 0x4000, 0xedea, 0x4674, 0x9cd0, 0x9f2c, 0x000c,0)),
/*^31*/ Decimal(length: 7, mantissa:( 0x0000, 0x8000, 0x4b26, 0xc091, 0x2022, 0x37be, 0x007e,0)),
/*^32*/ Decimal(length: 7, mantissa:( 0x0000, 0x0000, 0xef81, 0x85ac, 0x415b, 0x2d6d, 0x04ee,0)),
/*^33*/ Decimal(length: 7, mantissa:( 0x0000, 0x0000, 0x5b0a, 0x38c1, 0x8d93, 0xc644, 0x314d,0)),
/*^34*/ Decimal(length: 8, mantissa:( 0x0000, 0x0000, 0x8e64, 0x378d, 0x87c0, 0xbead, 0xed09, 0x0001)),
/*^35*/ Decimal(length: 8, mantissa:( 0x0000, 0x0000, 0x8fe8, 0x2b87, 0x4d82, 0x72c7, 0x4261, 0x0013)),
/*^36*/ Decimal(length: 8, mantissa:( 0x0000, 0x0000, 0x9f10, 0xb34b, 0x0715, 0x7bc9, 0x97ce, 0x00c0)),
/*^37*/ Decimal(length: 8, mantissa:( 0x0000, 0x0000, 0x36a0, 0x00f4, 0x46d9, 0xd5da, 0xee10, 0x0785)),
/*^38*/ Decimal(length: 8, mantissa:( 0x0000, 0x0000, 0x2240, 0x098a, 0xc47a, 0x5a86, 0x4ca8, 0x4b3b))
/*^39 is on 9 shorts. */
]

// Copied from Scanner.swift
private func decimalSep(_ locale: Locale?) -> String {
    if let loc = locale {
        if let sep = loc._bridgeToObjectiveC().object(forKey: .decimalSeparator) as? NSString {
            return sep._swiftObject
        }
        return "."
    } else {
        return decimalSep(Locale.current)
    }
}

// Copied from Scanner.swift
private func isADigit(_ ch: unichar) -> Bool {
    struct Local {
        static let set = CharacterSet.decimalDigits
    }
    return Local.set.contains(UnicodeScalar(ch)!)
}

// Copied from Scanner.swift
private func numericValue(_ ch: unichar) -> Int {
    if (ch >= unichar(unicodeScalarLiteral: "0") && ch <= unichar(unicodeScalarLiteral: "9")) {
        return Int(ch) - Int(unichar(unicodeScalarLiteral: "0"))
    } else {
        return __CFCharDigitValue(UniChar(ch))
    }
}

// Could be silently inexact for float and double.
extension Scanner {

    public func scanDecimal(_ dcm: inout Decimal) -> Bool {
        if let result = scanDecimal() {
            dcm = result
            return true
        } else {
            return false
        }

    }
    public func scanDecimal() -> Decimal? {

        var result = Decimal()

        let string = self._scanString
        let length = string.length
        var buf = _NSStringBuffer(string: string, start: self._scanLocation, end: length)

        let ds_chars = decimalSep(locale).utf16
        let ds = ds_chars[ds_chars.startIndex]
        buf.skip(_skipSet)
        var neg = false

        if buf.currentCharacter == unichar(unicodeScalarLiteral: "-") || buf.currentCharacter == unichar(unicodeScalarLiteral: "+") {
            neg = buf.currentCharacter == unichar(unicodeScalarLiteral: "-")
            buf.advance()
            buf.skip(_skipSet)
        }
        guard isADigit(buf.currentCharacter) else {
            return nil
        }

        var tooBig = false

        // build the mantissa
        repeat {
            let numeral = numericValue(buf.currentCharacter)
            if numeral == -1 {
                break
            }

            if tooBig || multiplyBy10(&result,andAdd:numeral) != .noError {
                tooBig = true
                if result._exponent == Int32(Int8.max) {
                    repeat {
                        buf.advance()
                    } while isADigit(buf.currentCharacter)
                    return Decimal.nan
                }
                result._exponent += 1
            }
            buf.advance()
        } while isADigit(buf.currentCharacter)

        // get the decimal point
        if buf.currentCharacter == ds {
            buf.advance()
            // continue to build the mantissa
            repeat {
                let numeral = numericValue(buf.currentCharacter)
                if numeral == -1 {
                    break
                }
                if tooBig || multiplyBy10(&result,andAdd:numeral) != .noError {
                    tooBig = true
                } else {
                    if result._exponent == Int32(Int8.min) {
                        repeat {
                            buf.advance()
                        } while isADigit(buf.currentCharacter)
                        return Decimal.nan
                    }
                    result._exponent -= 1
                }
                buf.advance()
            } while isADigit(buf.currentCharacter)
        }

        if buf.currentCharacter == unichar(unicodeScalarLiteral: "e") || buf.currentCharacter == unichar(unicodeScalarLiteral: "E") {
            var exponentIsNegative = false
            var exponent: Int32 = 0

            buf.advance()
            if buf.currentCharacter == unichar(unicodeScalarLiteral: "-") {
                exponentIsNegative = true
                buf.advance()
            } else if buf.currentCharacter == unichar(unicodeScalarLiteral: "+") {
                buf.advance()
            }

            repeat {
                let numeral = numericValue(buf.currentCharacter)
                if numeral == -1 {
                    break
                }
                exponent = 10 * exponent + Int32(numeral)
                guard exponent <= 2*Int32(Int8.max) else {
                    return Decimal.nan
                }

                buf.advance()
            } while isADigit(buf.currentCharacter)

            if exponentIsNegative {
                exponent = -exponent
            }
            exponent += result._exponent
            guard exponent >= Int32(Int8.min) && exponent <= Int32(Int8.max) else {
                return Decimal.nan
            }
            result._exponent = exponent
        }

        result.isNegative = neg

        // if we get to this point, and have NaN, then the input string was probably "-0"
        // or some variation on that, and normalize that to zero.
        if result.isNaN {
            result = Decimal(0)
        }

        result.compact()
        self._scanLocation = buf.location
        return result
    }
}

extension Decimal : Codable {
    private enum CodingKeys : Int, CodingKey {
        case exponent
        case length
        case isNegative
        case isCompact
        case mantissa
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let exponent = try container.decode(CInt.self, forKey: .exponent)
        let length = try container.decode(CUnsignedInt.self, forKey: .length)
        let isNegative = try container.decode(Bool.self, forKey: .isNegative)
        let isCompact = try container.decode(Bool.self, forKey: .isCompact)
        
        var mantissaContainer = try container.nestedUnkeyedContainer(forKey: .mantissa)
        var mantissa: (CUnsignedShort, CUnsignedShort, CUnsignedShort, CUnsignedShort,
            CUnsignedShort, CUnsignedShort, CUnsignedShort, CUnsignedShort) = (0,0,0,0,0,0,0,0)
        mantissa.0 = try mantissaContainer.decode(CUnsignedShort.self)
        mantissa.1 = try mantissaContainer.decode(CUnsignedShort.self)
        mantissa.2 = try mantissaContainer.decode(CUnsignedShort.self)
        mantissa.3 = try mantissaContainer.decode(CUnsignedShort.self)
        mantissa.4 = try mantissaContainer.decode(CUnsignedShort.self)
        mantissa.5 = try mantissaContainer.decode(CUnsignedShort.self)
        mantissa.6 = try mantissaContainer.decode(CUnsignedShort.self)
        mantissa.7 = try mantissaContainer.decode(CUnsignedShort.self)
        
        self.init(_exponent: exponent,
                  _length: length,
                  _isNegative: CUnsignedInt(isNegative ? 1 : 0),
                  _isCompact: CUnsignedInt(isCompact ? 1 : 0),
                  _reserved: 0,
                  _mantissa: mantissa)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_exponent, forKey: .exponent)
        try container.encode(_length, forKey: .length)
        try container.encode(_isNegative == 0 ? false : true, forKey: .isNegative)
        try container.encode(_isCompact == 0 ? false : true, forKey: .isCompact)
        
        var mantissaContainer = container.nestedUnkeyedContainer(forKey: .mantissa)
        try mantissaContainer.encode(_mantissa.0)
        try mantissaContainer.encode(_mantissa.1)
        try mantissaContainer.encode(_mantissa.2)
        try mantissaContainer.encode(_mantissa.3)
        try mantissaContainer.encode(_mantissa.4)
        try mantissaContainer.encode(_mantissa.5)
        try mantissaContainer.encode(_mantissa.6)
        try mantissaContainer.encode(_mantissa.7)
    }
}
