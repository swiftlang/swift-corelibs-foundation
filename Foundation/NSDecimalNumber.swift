// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/***************	Exceptions		***********/
public struct NSExceptionName : RawRepresentable, Equatable, Hashable, Comparable {
    public private(set) var rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
    
    public static func ==(_ lhs: NSExceptionName, _ rhs: NSExceptionName) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public static func <(_ lhs: NSExceptionName, _ rhs: NSExceptionName) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension NSExceptionName {
    public static let decimalNumberExactnessException = NSExceptionName(rawValue: "NSDecimalNumberExactnessException")
    public static let decimalNumberOverflowException = NSExceptionName(rawValue: "NSDecimalNumberOverflowException")
    public static let decimalNumberUnderflowException = NSExceptionName(rawValue: "NSDecimalNumberUnderflowException")
    public static let decimalNumberDivideByZeroException = NSExceptionName(rawValue: "NSDecimalNumberDivideByZeroException")
}

/***************	Rounding and Exception behavior		***********/

// Rounding policies :
// Original
//    value 1.2  1.21  1.25  1.35  1.27
// Plain    1.2  1.2   1.3   1.4   1.3
// Down     1.2  1.2   1.2   1.3   1.2
// Up       1.2  1.3   1.3   1.4   1.3
// Bankers  1.2  1.2   1.2   1.4   1.3

/***************	Type definitions		***********/
extension NSDecimalNumber {
    public enum RoundingMode : UInt {
        case plain // Round up on a tie
        case down // Always down == truncate
        case up // Always up
        case bankers // on a tie round so last digit is even
    }
    
    public enum CalculationError : UInt {
        case noError
        case lossOfPrecision // Result lost precision
        case underflow // Result became 0
        case overflow // Result exceeds possible representation
        case divideByZero
    }
}

public protocol NSDecimalNumberBehaviors {
    func roundingMode() -> NSDecimalNumber.RoundingMode
    func scale() -> Int16
}

// Receiver can raise, return a new value, or return nil to ignore the exception.


/***************	NSDecimalNumber: the class		***********/
open class NSDecimalNumber : NSNumber {
    
    public convenience init(mantissa: UInt64, exponent: Int16, isNegative flag: Bool) { NSUnimplemented() }
    public init(decimal dcm: Decimal) { NSUnimplemented() }
    public convenience init(string numberValue: String?) { NSUnimplemented() }
    public convenience init(string numberValue: String?, locale: AnyObject?) { NSUnimplemented() }

    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }

    public required convenience init(floatLiteral value: Double) {
        NSUnimplemented()
    }

    public required convenience init(booleanLiteral value: Bool) {
        NSUnimplemented()
    }

    public required convenience init(integerLiteral value: Int) {
        NSUnimplemented()
    }
    
    public required convenience init(bytes buffer: UnsafeRawPointer, objCType type: UnsafePointer<Int8>) {
        NSRequiresConcreteImplementation()
    }
    
    open override func description(withLocale locale: Locale?) -> String { NSUnimplemented() }
    
    // TODO: "declarations from extensions cannot be overridden yet"
    // Although it's not clear we actually need to redeclare this here when the extension adds it to the superclass of this class
    // open var decimalValue: Decimal { NSUnimplemented() }
    
    open class var zero: NSDecimalNumber { NSUnimplemented() }
    open class var one: NSDecimalNumber { NSUnimplemented() }
    open class var minimum: NSDecimalNumber { NSUnimplemented() }
    open class var maximum: NSDecimalNumber { NSUnimplemented() }
    open class var notANumber: NSDecimalNumber { NSUnimplemented() }
    
    open func adding(_ decimalNumber: NSDecimalNumber) -> NSDecimalNumber { NSUnimplemented() }
    open func adding(_ decimalNumber: NSDecimalNumber, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    open func subtracting(_ decimalNumber: NSDecimalNumber) -> NSDecimalNumber { NSUnimplemented() }
    open func subtracting(_ decimalNumber: NSDecimalNumber, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    open func multiplying(by decimalNumber: NSDecimalNumber) -> NSDecimalNumber { NSUnimplemented() }
    open func multiplying(by decimalNumber: NSDecimalNumber, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    open func dividing(by decimalNumber: NSDecimalNumber) -> NSDecimalNumber { NSUnimplemented() }
    open func dividing(by decimalNumber: NSDecimalNumber, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    open func raising(toPower power: Int) -> NSDecimalNumber { NSUnimplemented() }
    open func raising(toPower power: Int, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    open func multiplying(byPowerOf10 power: Int16) -> NSDecimalNumber { NSUnimplemented() }
    open func multiplying(byPowerOf10 power: Int16, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    open func rounding(accordingToBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    // Round to the scale of the behavior.
    
    open override func compare(_ decimalNumber: NSNumber) -> ComparisonResult { NSUnimplemented() }
    // compare two NSDecimalNumbers
    
    open class var defaultBehavior: NSDecimalNumberBehaviors { NSUnimplemented() }
    // One behavior per thread - The default behavior is
    //   rounding mode: NSRoundPlain
    //   scale: No defined scale (full precision)
    //   ignore exactnessException
    //   raise on overflow, underflow and divide by zero.
    
    open override var objCType: UnsafePointer<Int8> { NSUnimplemented() }
    // return 'd' for double
    
    open override var doubleValue: Double { NSUnimplemented() }
}

// return an approximate double value


/***********	A class for defining common behaviors		*******/
open class NSDecimalNumberHandler : NSObject, NSDecimalNumberBehaviors, NSCoding {
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    open class func `default`() -> NSDecimalNumberHandler { NSUnimplemented() }
    // rounding mode: NSRoundPlain
    // scale: No defined scale (full precision)
    // ignore exactnessException (return nil)
    // raise on overflow, underflow and divide by zero.
    
    public init(roundingMode: NSDecimalNumber.RoundingMode, scale: Int16, raiseOnExactness exact: Bool, raiseOnOverflow overflow: Bool, raiseOnUnderflow underflow: Bool, raiseOnDivideByZero divideByZero: Bool) { NSUnimplemented() }
    
    open func roundingMode() -> NSDecimalNumber.RoundingMode { NSUnimplemented() }
    
    open func scale() -> Int16 { NSUnimplemented() }
    // The scale could return NO_SCALE for no defined scale.
}


extension NSNumber {
    
    public var decimalValue: Decimal { NSUnimplemented() }
}

// Could be silently inexact for float and double.

extension Scanner {
    
    public func scanDecimal(_ dcm: UnsafeMutablePointer<Decimal>) -> Bool { NSUnimplemented() }
}

