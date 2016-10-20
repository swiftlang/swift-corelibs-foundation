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

fileprivate func handle(_ error: NSDecimalNumber.CalculationError, _ handler: NSDecimalNumberBehaviors) {
    // handle the error condition, such as throwing an error for over/underflow
}

/***************	NSDecimalNumber: the class		***********/
open class NSDecimalNumber : NSNumber {

    fileprivate let decimal: Decimal
    public convenience init(mantissa: UInt64, exponent: Int16, isNegative: Bool) {
        var d = Decimal()
        d._exponent = Int32(exponent)
        d._isNegative = isNegative ? 1 : 0
        var man = mantissa
        d._mantissa.0 = UInt16(man & 0xffff)
        man >>= 4
        d._mantissa.1 = UInt16(man & 0xffff)
        man >>= 4
        d._mantissa.2 = UInt16(man & 0xffff)
        man >>= 4
        d._mantissa.3 = UInt16(man & 0xffff)
        d._length = 4
        d.trimTrailingZeros()
        // TODO more parts of the mantissa...
        self.init(decimal: d)
    }
    public init(decimal dcm: Decimal) {
        self.decimal = dcm
        super.init()
    }
    public convenience init(string numberValue: String?) { NSUnimplemented() }
    public convenience init(string numberValue: String?, locale: AnyObject?) { NSUnimplemented() }

    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }

    public required convenience init(floatLiteral value: Double) {
        self.init(decimal:Decimal(value))
    }

    public required convenience init(booleanLiteral value: Bool) {
        if value {
            self.init(integerLiteral: 1)
        } else {
            self.init(integerLiteral: 0)
        }
    }

    public required convenience init(integerLiteral value: Int) {
        self.init(decimal:Decimal(value))
    }
    
    public required convenience init(bytes buffer: UnsafeRawPointer, objCType type: UnsafePointer<Int8>) {
        NSRequiresConcreteImplementation()
    }
    
    open override func description(withLocale locale: Locale?) -> String { NSUnimplemented() }

    open class var zero: NSDecimalNumber {
        return NSDecimalNumber(integerLiteral: 0)
    }
    open class var one: NSDecimalNumber {
        return NSDecimalNumber(integerLiteral: 1)
    }
    open class var minimum: NSDecimalNumber {
        return NSDecimalNumber(decimal:Decimal.leastFiniteMagnitude)
    }
    open class var maximum: NSDecimalNumber {
        return NSDecimalNumber(decimal:Decimal.greatestFiniteMagnitude)

    }
    open class var notANumber: NSDecimalNumber {
        return NSDecimalNumber(decimal: Decimal.nan)
    }
    
    open func adding(_ other: NSDecimalNumber) -> NSDecimalNumber {
        return adding(other, withBehavior: nil)
    }
    open func adding(_ other: NSDecimalNumber, withBehavior b: NSDecimalNumberBehaviors?) -> NSDecimalNumber {
        var result = Decimal()
        var left = self.decimal
        var right = other.decimal
        let behavior = b ?? NSDecimalNumber.defaultBehavior
        let roundingMode = behavior.roundingMode()
        let error = NSDecimalAdd(&result, &left, &right, roundingMode)
        handle(error,behavior)
        return NSDecimalNumber(decimal: result)
    }

    open func subtracting(_ other: NSDecimalNumber) -> NSDecimalNumber {
        return subtracting(other, withBehavior: nil)
    }
    open func subtracting(_ other: NSDecimalNumber, withBehavior b: NSDecimalNumberBehaviors?) -> NSDecimalNumber {
        var result = Decimal()
        var left = self.decimal
        var right = other.decimal
        let behavior = b ?? NSDecimalNumber.defaultBehavior
        let roundingMode = behavior.roundingMode()
        let error = NSDecimalSubtract(&result, &left, &right, roundingMode)
        handle(error,behavior)
        return NSDecimalNumber(decimal: result)
    }
    open func multiplying(by other: NSDecimalNumber) -> NSDecimalNumber {
        return multiplying(by: other, withBehavior: nil)
    }
    open func multiplying(by other: NSDecimalNumber, withBehavior b: NSDecimalNumberBehaviors?) -> NSDecimalNumber {
        var result = Decimal()
        var left = self.decimal
        var right = other.decimal
        let behavior = b ?? NSDecimalNumber.defaultBehavior
        let roundingMode = behavior.roundingMode()
        let error = NSDecimalMultiply(&result, &left, &right, roundingMode)
        handle(error,behavior)
        return NSDecimalNumber(decimal: result)
    }
    
    open func dividing(by other: NSDecimalNumber) -> NSDecimalNumber {
        return dividing(by: other, withBehavior: nil)
    }
    open func dividing(by other: NSDecimalNumber, withBehavior b: NSDecimalNumberBehaviors?) -> NSDecimalNumber {
        var result = Decimal()
        var left = self.decimal
        var right = other.decimal
        let behavior = b ?? NSDecimalNumber.defaultBehavior
        let roundingMode = behavior.roundingMode()
        let error = NSDecimalDivide(&result, &left, &right, roundingMode)
        handle(error,behavior)
        return NSDecimalNumber(decimal: result)
    }
    
    open func raising(toPower power: Int) -> NSDecimalNumber {
        return raising(toPower:power, withBehavior: nil)
    }
    open func raising(toPower power: Int, withBehavior b: NSDecimalNumberBehaviors?) -> NSDecimalNumber {
        var result = Decimal()
        var input = self.decimal
        let behavior = b ?? NSDecimalNumber.defaultBehavior
        let roundingMode = behavior.roundingMode()
        let error = NSDecimalPower(&result, &input, power, roundingMode)
        handle(error,behavior)
        return NSDecimalNumber(decimal: result)
    }

    open func multiplying(byPowerOf10 power: Int16) -> NSDecimalNumber {
        return multiplying(byPowerOf10: power, withBehavior: nil)
    }
    open func multiplying(byPowerOf10 power: Int16, withBehavior b: NSDecimalNumberBehaviors?) -> NSDecimalNumber {
        var result = Decimal()
        var input = self.decimal
        let behavior = b ?? NSDecimalNumber.defaultBehavior
        let roundingMode = behavior.roundingMode()
        let error = NSDecimalPower(&result, &input, Int(power), roundingMode)
        handle(error,behavior)
        return NSDecimalNumber(decimal: result)
    }
    
    open func rounding(accordingToBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    // Round to the scale of the behavior.
    
    // compare two NSDecimalNumbers
    open override func compare(_ decimalNumber: NSNumber) -> ComparisonResult {
        if let num = decimalNumber as? NSDecimalNumber {
            return decimal.compare(to:num.decimal)
        } else {
            return decimal.compare(to:Decimal(decimalNumber.doubleValue))
        }
    }

    open class var defaultBehavior: NSDecimalNumberBehaviors {
        return NSDecimalNumberHandler.defaultBehavior
    }
    // One behavior per thread - The default behavior is
    //   rounding mode: NSRoundPlain
    //   scale: No defined scale (full precision)
    //   ignore exactnessException
    //   raise on overflow, underflow and divide by zero.
    
    open override var objCType: UnsafePointer<Int8> { NSUnimplemented() }
    // return 'd' for double
    
    open override var int8Value: Int8 {
        return Int8(decimal.doubleValue)
    }
    open override var uint8Value: UInt8 {
        return UInt8(decimal.doubleValue)
    }
    open override var int16Value: Int16 {
        return Int16(decimal.doubleValue)
    }
    open override var uint16Value: UInt16 {
        return UInt16(decimal.doubleValue)
    }
    open override var int32Value: Int32 {
        return Int32(decimal.doubleValue)
    }
    open override var uint32Value: UInt32 {
        return UInt32(decimal.doubleValue)
    }
    open override var int64Value: Int64 {
        return Int64(decimal.doubleValue)
    }
    open override var uint64Value: UInt64 {
        return UInt64(decimal.doubleValue)
    }
    open override var floatValue: Float {
        return Float(decimal.doubleValue)
    }
    open override var doubleValue: Double {
        return decimal.doubleValue
    }
    open override var boolValue: Bool {
        return !decimal.isZero
    }
    open override var intValue: Int {
        return Int(decimal.doubleValue)
    }
    open override var uintValue: UInt {
        return UInt(decimal.doubleValue)
    }

    open override func isEqual(_ value: Any?) -> Bool {
        if let number = value as? NSDecimalNumber {
            return self.decimal == number.decimal
        } else {
            return false
        }
    }

}

// return an approximate double value


/***********	A class for defining common behaviors		*******/
open class NSDecimalNumberHandler : NSObject, NSDecimalNumberBehaviors, NSCoding {

    static let defaultBehavior = NSDecimalNumberHandler()

    let _roundingMode: NSDecimalNumber.RoundingMode
    let _scale:Int16

    let _raiseOnExactness: Bool
    let _raiseOnOverflow: Bool
    let _raiseOnUnderflow: Bool
    let _raiseOnDivideByZero: Bool

    public override init() {
        _roundingMode = .plain
        _scale = Int16(NSDecimalNoScale)

        _raiseOnExactness = false
        _raiseOnOverflow = true
        _raiseOnUnderflow = true
        _raiseOnDivideByZero = true
    }
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    open class func `default`() -> NSDecimalNumberHandler {
        return defaultBehavior
    }
    // rounding mode: NSRoundPlain
    // scale: No defined scale (full precision)
    // ignore exactnessException (return nil)
    // raise on overflow, underflow and divide by zero.
    
    public init(roundingMode: NSDecimalNumber.RoundingMode, scale: Int16, raiseOnExactness exact: Bool, raiseOnOverflow overflow: Bool, raiseOnUnderflow underflow: Bool, raiseOnDivideByZero divideByZero: Bool) {
        _roundingMode = roundingMode
        _scale = scale
        _raiseOnExactness = exact
        _raiseOnOverflow = overflow
        _raiseOnUnderflow = underflow
        _raiseOnDivideByZero = divideByZero
    }
    
    open func roundingMode() -> NSDecimalNumber.RoundingMode {
        return _roundingMode
    }
    
    // The scale could return NoScale for no defined scale.
    open func scale() -> Int16 {
        return _scale
    }
}


extension NSNumber {
    
    public var decimalValue: Decimal {
        if let d = self as? NSDecimalNumber {
            return d.decimal
        } else {
            return Decimal(self.doubleValue)
        }
    }
}

// Could be silently inexact for float and double.

extension Scanner {
    
    public func scanDecimal(_ dcm: UnsafeMutablePointer<Decimal>) -> Bool { NSUnimplemented() }
}

