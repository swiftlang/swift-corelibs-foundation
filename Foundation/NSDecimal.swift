// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


// Rounding policies :
// Original
//    value 1.2  1.21  1.25  1.35  1.27
// Plain    1.2  1.2   1.3   1.4   1.3
// Down     1.2  1.2   1.2   1.3   1.2
// Up       1.2  1.3   1.3   1.4   1.3
// Bankers  1.2  1.2   1.2   1.4   1.3

/***************	Type definitions		***********/
extension Decimal {
    public enum RoundingMode : UInt {
        
        case roundPlain // Round up on a tie
        case roundDown // Always down == truncate
        case roundUp // Always up
        case roundBankers // on a tie round so last digit is even
    }

    public enum CalculationError : UInt {
        
        case noError
        case lossOfPrecision // Result lost precision
        case underflow // Result became 0
        case overflow // Result exceeds possible representation
        case divideByZero
    }

}
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

public func NSDecimalIsNotANumber(_ dcm: UnsafePointer<Decimal>) -> Bool { NSUnimplemented() }


/***************	Operations		***********/
public func NSDecimalCopy(_ destination: UnsafeMutablePointer<Decimal>, _ source: UnsafePointer<Decimal>) { NSUnimplemented() }

public func NSDecimalCompact(_ number: UnsafeMutablePointer<Decimal>) { NSUnimplemented() }

public func NSDecimalCompare(_ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>) -> ComparisonResult { NSUnimplemented() }
// NSDecimalCompare:Compares leftOperand and rightOperand.

public func NSDecimalRound(_ result: UnsafeMutablePointer<Decimal>, _ number: UnsafePointer<Decimal>, _ scale: Int, _ roundingMode: Decimal.RoundingMode) { NSUnimplemented() }
// Rounds num to the given scale using the given mode.
// result may be a pointer to same space as num.
// scale indicates number of significant digits after the decimal point

public func NSDecimalNormalize(_ number1: UnsafeMutablePointer<Decimal>, _ number2: UnsafeMutablePointer<Decimal>, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError { NSUnimplemented() }

public func NSDecimalAdd(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError { NSUnimplemented() }
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalSubtract(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError { NSUnimplemented() }
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalMultiply(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError { NSUnimplemented() }
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalDivide(_ result: UnsafeMutablePointer<Decimal>, _ leftOperand: UnsafePointer<Decimal>, _ rightOperand: UnsafePointer<Decimal>, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError { NSUnimplemented() }
// Division could be silently inexact;
// Exact operations. result may be a pointer to same space as leftOperand or rightOperand

public func NSDecimalPower(_ result: UnsafeMutablePointer<Decimal>, _ number: UnsafePointer<Decimal>, _ power: Int, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError { NSUnimplemented() }

public func NSDecimalMultiplyByPowerOf10(_ result: UnsafeMutablePointer<Decimal>, _ number: UnsafePointer<Decimal>, _ power: Int16, _ roundingMode: Decimal.RoundingMode) -> Decimal.CalculationError { NSUnimplemented() }

public func NSDecimalString(_ dcm: UnsafePointer<Decimal>, _ locale: AnyObject?) -> String { NSUnimplemented() }

