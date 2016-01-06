// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/***************	Exceptions		***********/
public let NSDecimalNumberExactnessException: String = "NSDecimalNumberExactnessException"
public let NSDecimalNumberOverflowException: String = "NSDecimalNumberOverflowException"
public let NSDecimalNumberUnderflowException: String = "NSDecimalNumberUnderflowException"
public let NSDecimalNumberDivideByZeroException: String = "NSDecimalNumberDivideByZeroException"

/***************	Rounding and Exception behavior		***********/

public protocol NSDecimalNumberBehaviors {
    
    func roundingMode() -> NSRoundingMode
    
    func scale() -> Int16
    // The scale could return NO_SCALE for no defined scale.
}

// Receiver can raise, return a new value, or return nil to ignore the exception.


/***************	NSDecimalNumber: the class		***********/
public class NSDecimalNumber : NSNumber {
    
    public convenience init(mantissa: UInt64, exponent: Int16, isNegative flag: Bool) { NSUnimplemented() }
    public init(decimal dcm: NSDecimal) { NSUnimplemented() }
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
    
    public required convenience init(bytes buffer: UnsafePointer<Void>, objCType type: UnsafePointer<Int8>) {
        NSRequiresConcreteImplementation()
    }
    
    public func descriptionWithLocale(locale: AnyObject?) -> String { NSUnimplemented() }
    
    // TODO: "declarations from extensions cannot be overridden yet"
    // Although it's not clear we actually need to redeclare this here when the extension adds it to the superclass of this class
    // public var decimalValue: NSDecimal { NSUnimplemented() }
    
    public class func zero() -> NSDecimalNumber { NSUnimplemented() }
    public class func one() -> NSDecimalNumber { NSUnimplemented() }
    public class func minimumDecimalNumber() -> NSDecimalNumber { NSUnimplemented() }
    public class func maximumDecimalNumber() -> NSDecimalNumber { NSUnimplemented() }
    public class func notANumber() -> NSDecimalNumber { NSUnimplemented() }
    
    public func decimalNumberByAdding(decimalNumber: NSDecimalNumber) -> NSDecimalNumber { NSUnimplemented() }
    public func decimalNumberByAdding(decimalNumber: NSDecimalNumber, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    public func decimalNumberBySubtracting(decimalNumber: NSDecimalNumber) -> NSDecimalNumber { NSUnimplemented() }
    public func decimalNumberBySubtracting(decimalNumber: NSDecimalNumber, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    public func decimalNumberByMultiplyingBy(decimalNumber: NSDecimalNumber) -> NSDecimalNumber { NSUnimplemented() }
    public func decimalNumberByMultiplyingBy(decimalNumber: NSDecimalNumber, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    public func decimalNumberByDividingBy(decimalNumber: NSDecimalNumber) -> NSDecimalNumber { NSUnimplemented() }
    public func decimalNumberByDividingBy(decimalNumber: NSDecimalNumber, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    public func decimalNumberByRaisingToPower(power: Int) -> NSDecimalNumber { NSUnimplemented() }
    public func decimalNumberByRaisingToPower(power: Int, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    public func decimalNumberByMultiplyingByPowerOf10(power: Int16) -> NSDecimalNumber { NSUnimplemented() }
    public func decimalNumberByMultiplyingByPowerOf10(power: Int16, withBehavior behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    
    public func decimalNumberByRoundingAccordingToBehavior(behavior: NSDecimalNumberBehaviors?) -> NSDecimalNumber { NSUnimplemented() }
    // Round to the scale of the behavior.
    
    public override func compare(decimalNumber: NSNumber) -> NSComparisonResult { NSUnimplemented() }
    // compare two NSDecimalNumbers
    
    public class func setDefaultBehavior(behavior: NSDecimalNumberBehaviors) { NSUnimplemented() }
    
    public class func defaultBehavior() -> NSDecimalNumberBehaviors { NSUnimplemented() }
    // One behavior per thread - The default behavior is
    //   rounding mode: NSRoundPlain
    //   scale: No defined scale (full precision)
    //   ignore exactnessException
    //   raise on overflow, underflow and divide by zero.
    
    public override var objCType: UnsafePointer<Int8> { NSUnimplemented() }
    // return 'd' for double
    
    public override var doubleValue: Double { NSUnimplemented() }
}

// return an approximate double value


/***********	A class for defining common behaviors		*******/
public class NSDecimalNumberHandler : NSObject, NSDecimalNumberBehaviors, NSCoding {
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public class func defaultDecimalNumberHandler() -> NSDecimalNumberHandler{ NSUnimplemented() }
    // rounding mode: NSRoundPlain
    // scale: No defined scale (full precision)
    // ignore exactnessException (return nil)
    // raise on overflow, underflow and divide by zero.
    
    public init(roundingMode: NSRoundingMode, scale: Int16, raiseOnExactness exact: Bool, raiseOnOverflow overflow: Bool, raiseOnUnderflow underflow: Bool, raiseOnDivideByZero divideByZero: Bool) { NSUnimplemented() }
    
    public func roundingMode() -> NSRoundingMode { NSUnimplemented() }
    
    public func scale() -> Int16 { NSUnimplemented() }
    // The scale could return NO_SCALE for no defined scale.
}


extension NSNumber {
    
    public var decimalValue: NSDecimal { NSUnimplemented() }
}

// Could be silently inexact for float and double.

extension NSScanner {
    
    public func scanDecimal(dcm: UnsafeMutablePointer<NSDecimal>) -> Bool { NSUnimplemented() }
}

