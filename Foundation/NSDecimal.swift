// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public var NSDecimalMaxSize: Int32 { NSUnimplemented() }
// Give a precision of at least 38 decimal digits, 128 binary positions.

public var NSDecimalNoScale: Int32 { NSUnimplemented() }

public struct Decimal {
    public var _exponent: Int32
    public var _length: UInt32 // length == 0 && isNegative -> NaN
    public var _isNegative: UInt32
    public var _isCompact: UInt32
    public var _reserved: UInt32
    public var _mantissa: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)
    public init() { NSUnimplemented() }
    public init(_exponent: Int32, _length: UInt32, _isNegative: UInt32, _isCompact: UInt32, _reserved: UInt32, _mantissa: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)){ NSUnimplemented() }
}

extension Decimal {
    // These will need to be `let`s when implemented for Foundation API compatibility
    public static var leastFiniteMagnitude: Decimal { NSUnimplemented() }
    public static var greatestFiniteMagnitude: Decimal { NSUnimplemented() }
    public static var leastNormalMagnitude: Decimal { NSUnimplemented() }
    public static var leastNonzeroMagnitude: Decimal { NSUnimplemented() }
    public static var pi: Decimal { NSUnimplemented() }
    public var exponent: Int { NSUnimplemented() }
    public var significand: Decimal { NSUnimplemented() }
    public init(sign: FloatingPointSign, exponent: Int, significand: Decimal) { NSUnimplemented() }
    public init(signOf: Decimal, magnitudeOf magnitude: Decimal) { NSUnimplemented() }
    public var sign: FloatingPointSign { NSUnimplemented() }
    public static var radix: Int { NSUnimplemented() }
    public var ulp: Decimal { NSUnimplemented() }
    public mutating func add(_ other: Decimal) { NSUnimplemented() }
    public mutating func subtract(_ other: Decimal) { NSUnimplemented() }
    public mutating func multiply(by other: Decimal) { NSUnimplemented() }
    public mutating func divide(by other: Decimal) { NSUnimplemented() }
    public mutating func negate() { NSUnimplemented() }
    public func isEqual(to other: Decimal) -> Bool { NSUnimplemented() }
    public func isLess(than other: Decimal) -> Bool { NSUnimplemented() }
    public func isLessThanOrEqualTo(_ other: Decimal) -> Bool { NSUnimplemented() }
    public func isTotallyOrdered(belowOrEqualTo other: Decimal) -> Bool { NSUnimplemented() }
    public var isCanonical: Bool { NSUnimplemented() }
    public var nextUp: Decimal { NSUnimplemented() }
    public var nextDown: Decimal { NSUnimplemented() }
    public static func +(lhs: Decimal, rhs: Decimal) -> Decimal { NSUnimplemented() }
    public static func -(lhs: Decimal, rhs: Decimal) -> Decimal { NSUnimplemented() }
    public static func /(lhs: Decimal, rhs: Decimal) -> Decimal { NSUnimplemented() }
    public static func *(lhs: Decimal, rhs: Decimal) -> Decimal { NSUnimplemented() }
}

extension Decimal : Hashable, Comparable {
    public var hashValue: Int { NSUnimplemented() }
    public static func ==(lhs: Decimal, rhs: Decimal) -> Bool { NSUnimplemented() }
    public static func <(lhs: Decimal, rhs: Decimal) -> Bool { NSUnimplemented() }
}

extension Decimal : ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { NSUnimplemented() }
}

extension Decimal : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { NSUnimplemented() }
}

extension Decimal : SignedNumber {
}

extension Decimal : Strideable {
    public func distance(to other: Decimal) -> Decimal { NSUnimplemented() }
    public func advanced(by n: Decimal) -> Decimal { NSUnimplemented() }
}

extension Decimal : AbsoluteValuable {
    public static func abs(_ x: Decimal) -> Decimal { NSUnimplemented() }
}

extension Decimal {
    public typealias RoundingMode = NSDecimalNumber.RoundingMode
    public typealias CalculationError = NSDecimalNumber.CalculationError
    public init(_ value: UInt8) { NSUnimplemented() }
    public init(_ value: Int8) { NSUnimplemented() }
    public init(_ value: UInt16) { NSUnimplemented() }
    public init(_ value: Int16) { NSUnimplemented() }
    public init(_ value: UInt32) { NSUnimplemented() }
    public init(_ value: Int32) { NSUnimplemented() }
    public init(_ value: Double) { NSUnimplemented() }
    public init(_ value: UInt64) { NSUnimplemented() }
    public init(_ value: Int64) { NSUnimplemented() }
    public init(_ value: UInt) { NSUnimplemented() }
    public init(_ value: Int) { NSUnimplemented() }
    public var isSignalingNaN: Bool { NSUnimplemented() }
    public static var nan: Decimal { NSUnimplemented() }
    public static var quietNaN: Decimal { NSUnimplemented() }
    public var floatingPointClass: FloatingPointClassification { NSUnimplemented() }
    public var isSignMinus: Bool { NSUnimplemented() }
    public var isNormal: Bool { NSUnimplemented() }
    public var isFinite: Bool { NSUnimplemented() }
    public var isZero: Bool { NSUnimplemented() }
    public var isSubnormal: Bool { NSUnimplemented() }
    public var isInfinite: Bool { NSUnimplemented() }
    public var isNaN: Bool { NSUnimplemented() }
    public var isSignaling: Bool { NSUnimplemented() }
}

extension Decimal : CustomStringConvertible {
    public init?(string: String, locale: Locale? = nil) {
        // Avoid a compiler warning for now by not calling NSUnimplemented
        return nil
    }
    public var description: String { NSUnimplemented() }
}

public func NSDecimalIsNotANumber(_ dcm: UnsafePointer<Decimal>) -> Bool { NSUnimplemented() }


/***************	Operations		***********/
public func NSDecimalCopy(_ destination: UnsafeMutablePointer<Decimal>, _ source: UnsafePointer<Decimal>) { NSUnimplemented() }

public func NSDecimalCompact(_ number: UnsafeMutablePointer<Decimal>) { NSUnimplemented() }

public func NSDecimalCompare(_ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>) -> ComparisonResult { NSUnimplemented() }
// NSDecimalCompare:Compares leftOperand and rightOperand.

public func NSDecimalRound(_ result: UnsafeMutablePointer<Decimal>, _ number: UnsafePointer<Decimal>, _ scale: Int, _ roundingMode: NSDecimalNumber.RoundingMode) { NSUnimplemented() }
// Rounds num to the given scale using the given mode.
// result may be a pointer to same space as num.
// scale indicates number of significant digits after the decimal point

public func NSDecimalNormalize(_ number1: UnsafeMutablePointer<Decimal>, _ number2: UnsafeMutablePointer<Decimal>, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError { NSUnimplemented() }

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

public func NSDecimalMultiplyByPowerOf10(_ result: UnsafeMutablePointer<Decimal>, _ number: UnsafePointer<Decimal>, _ power: Int16, _ roundingMode: NSDecimalNumber.RoundingMode) -> NSDecimalNumber.CalculationError { NSUnimplemented() }

public func NSDecimalString(_ dcm: UnsafePointer<Decimal>, _ locale: AnyObject?) -> String { NSUnimplemented() }
