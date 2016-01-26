// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(OSX) || os(iOS)
internal let kCFNumberCharType = CFNumberType.CharType
internal let kCFNumberShortType = CFNumberType.ShortType
internal let kCFNumberIntType = CFNumberType.IntType
internal let kCFNumberLongType = CFNumberType.LongType
internal let kCFNumberLongLongType = CFNumberType.LongLongType
internal let kCFNumberFloatType = CFNumberType.FloatType
internal let kCFNumberDoubleType = CFNumberType.DoubleType
#endif

extension Int : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.integerValue
    }
    
    public func _bridgeToObject() -> NSNumber {
        return NSNumber(integer: self)
    }
    
    public static func _forceBridgeFromObject(x: NSNumber, inout result: Int?) {
        result = x.integerValue
    }
    
    public static func _conditionallyBridgeFromObject(x: NSNumber, inout result: Int?) -> Bool {
        self._forceBridgeFromObject(x, result: &result)
        return true
    }
}

extension UInt : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.unsignedIntegerValue
    }

    public func _bridgeToObject() -> NSNumber {
        return NSNumber(unsignedInteger: self)
    }
    
    public static func _forceBridgeFromObject(x: NSNumber, inout result: UInt?) {
        result = x.unsignedIntegerValue
    }
    public static func _conditionallyBridgeFromObject(x: NSNumber, inout result: UInt?) -> Bool {
        _forceBridgeFromObject(x, result: &result)
        return true
    }
}

extension Float : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.floatValue
    }
    
    public func _bridgeToObject() -> NSNumber {
        return NSNumber(float: self)
    }
    
    public static func _forceBridgeFromObject(x: NSNumber, inout result: Float?) {
        result = x.floatValue
    }
    
    public static func _conditionallyBridgeFromObject(x: NSNumber, inout result: Float?) -> Bool {
        _forceBridgeFromObject(x, result: &result)
        return true
    }
}

extension Double : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.doubleValue
    }
    
    public func _bridgeToObject() -> NSNumber {
        return NSNumber(double: self)
    }
    
    public static func _forceBridgeFromObject(x: NSNumber, inout result: Double?) {
        result = x.doubleValue
    }
    
    public static func _conditionallyBridgeFromObject(x: NSNumber, inout result: Double?) -> Bool {
        _forceBridgeFromObject(x, result: &result)
        return true
    }
}

extension Bool : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.boolValue
    }
    
    public func _bridgeToObject() -> NSNumber {
        return NSNumber(bool: self)
    }
    
    public static func _forceBridgeFromObject(x: NSNumber, inout result: Bool?) {
        result = x.boolValue
    }
    
    public static func _conditionallyBridgeFromObject(x: NSNumber, inout result: Bool?) -> Bool {
        _forceBridgeFromObject(x, result: &result)
        return true
    }
}

extension Bool : _CFBridgable {
    typealias CFType = CFBooleanRef
    var _cfObject: CFType {
        return self ? kCFBooleanTrue : kCFBooleanFalse
    }
}

extension NSNumber : FloatLiteralConvertible, IntegerLiteralConvertible, BooleanLiteralConvertible {

}

public class NSNumber : NSValue {
    typealias CFType = CFNumberRef
    // This layout MUST be the same as CFNumber so that they are bridgeable
    private var _base = _CFInfo(typeID: CFNumberGetTypeID())
    private var _pad: UInt64 = 0
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, CFType.self)
    }
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let number = object as? NSNumber {
            return CFEqual(_cfObject, number._cfObject)
        } else {
            return false
        }
    }
    
    deinit {
        _CFDeinit(self)
    }
    
    public init(char value: Int8) {
        super.init()
        _CFNumberInitInt8(_cfObject, value)
    }
    
    public init(unsignedChar value: UInt8) {
        super.init()
        _CFNumberInitUInt8(_cfObject, value)
    }
    
    public init(short value: Int16) {
        super.init()
        _CFNumberInitInt16(_cfObject, value)
    }
    
    public init(unsignedShort value: UInt16) {
        super.init()
        _CFNumberInitUInt16(_cfObject, value)
    }
    
    public init(int value: Int32) {
        super.init()
        _CFNumberInitInt32(_cfObject, value)
    }
    
    public init(unsignedInt value: UInt32) {
        super.init()
        _CFNumberInitUInt32(_cfObject, value)
    }
    
    public init(long value: Int) {
        super.init()
        _CFNumberInitInt(_cfObject, value)
    }
    
    public init(unsignedLong value: UInt) {
        super.init()
        _CFNumberInitUInt(_cfObject, value)
    }
    
    public init(longLong value: Int64) {
        super.init()
        _CFNumberInitInt64(_cfObject, value)
    }
    
    public init(unsignedLongLong value: UInt64) {
        super.init()
        _CFNumberInitUInt64(_cfObject, value)
    }
    
    public init(float value: Float) {
        super.init()
        _CFNumberInitFloat(_cfObject, value)
    }
    
    public init(double value: Double) {
        super.init()
        _CFNumberInitDouble(_cfObject, value)
    }
    
    public init(bool value: Bool) {
        super.init()
        _CFNumberInitBool(_cfObject, value)
    }
    
    public init(integer value: Int) {
        super.init()
        _CFNumberInitInt(_cfObject, value)
    }
    
    public init(unsignedInteger value: UInt) {
        super.init()
        _CFNumberInitUInt(_cfObject, value)
    }

    public required convenience init(bytes buffer: UnsafePointer<Void>, objCType: UnsafePointer<Int8>) {
        guard let type = _NSSimpleObjCType(UInt8(objCType.memory)) else {
            fatalError("NSNumber.init: unsupported type encoding spec '\(String.fromCString(objCType))'")
        }
        switch type {
        case .Bool:
            self.init(bool:UnsafePointer<Bool>(buffer).memory)
            break
        case .Char:
            self.init(char:UnsafePointer<Int8>(buffer).memory)
            break
        case .UChar:
            self.init(unsignedChar:UnsafePointer<UInt8>(buffer).memory)
            break
        case .Short:
            self.init(short:UnsafePointer<Int16>(buffer).memory)
            break
        case .UShort:
            self.init(unsignedShort:UnsafePointer<UInt16>(buffer).memory)
            break
        case .Int, .Long:
            self.init(int:UnsafePointer<Int32>(buffer).memory)
            break
        case .UInt, .ULong:
            self.init(unsignedInt:UnsafePointer<UInt32>(buffer).memory)
            break
        case .LongLong:
            self.init(longLong:UnsafePointer<Int64>(buffer).memory)
            break
        case .ULongLong:
            self.init(unsignedLongLong:UnsafePointer<UInt64>(buffer).memory)
            break
        case .Float:
            self.init(float:UnsafePointer<Float>(buffer).memory)
            break
        case .Double:
            self.init(double:UnsafePointer<Double>(buffer).memory)
            break
        default:
            fatalError("NSNumber.init: unsupported type encoding spec '\(String.fromCString(objCType))'")
            break
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            var objCType = UnsafeMutablePointer<Int8>()
            var size: Int = 0
            NSGetSizeAndAlignment(objCType, &size, nil)
            let buffer = malloc(size)
            aDecoder.decodeValueOfObjCType(objCType, at: buffer)
            withUnsafeMutablePointer(&objCType, { (ptr: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>) -> Void in
                aDecoder.decodeValueOfObjCType(String(_NSSimpleObjCType.CharPtr), at: UnsafeMutablePointer<Void>(ptr))
            })
            if objCType == nil {
                return nil
            }
            self.init(bytes: buffer, objCType: objCType)
            free(buffer)
        } else if aDecoder.dynamicType == NSKeyedUnarchiver.self || aDecoder.containsValueForKey("NS.number") {
            let number = aDecoder._decodePropertyListForKey("NS.number")
            if let val = number as? Double {
                self.init(double:val)
            } else if let val = number as? Int {
                self.init(long:val)
            } else if let val = number as? Bool {
                self.init(bool:val)
            } else {
                return nil
            }
        } else {
            if aDecoder.containsValueForKey("NS.boolval") {
                self.init(bool: aDecoder.decodeBoolForKey("NS.boolval"))
            } else if aDecoder.containsValueForKey("NS.intval") {
                self.init(longLong: aDecoder.decodeInt64ForKey("NS.intval"))
            } else if aDecoder.containsValueForKey("NS.dblval") {
                self.init(double: aDecoder.decodeDoubleForKey("NS.dblval"))
            } else {
                return nil
            }
        }
    }

    public var charValue: Int8 {
        var val: Int8 = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<Int8>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberCharType, value)
        }
        return val
    }

    public var unsignedCharValue: UInt8 {
        var val: UInt8 = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<UInt8>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberCharType, value)
        }
        return val
    }
    
    public var shortValue: Int16 {
        var val: Int16 = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<Int16>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberShortType, value)
        }
        return val
    }
    
    public var unsignedShortValue: UInt16 {
        var val: UInt16 = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<UInt16>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberShortType, value)
        }
        return val
    }
    
    public var intValue: Int32 {
        var val: Int32 = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<Int32>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberIntType, value)
        }
        return val
    }
    
    public var unsignedIntValue: UInt32 {
        var val: UInt32 = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<UInt32>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberIntType, value)
        }
        return val
    }
    
    public var longValue: Int {
        var val: Int = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<Int>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongType, value)
        }
        return val
    }
    
    public var unsignedLongValue: UInt {
        var val: UInt = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<UInt>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongType, value)
        }
        return val
    }
    
    public var longLongValue: Int64 {
        var val: Int64 = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<Int64>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongLongType, value)
        }
        return val
    }
    
    public var unsignedLongLongValue: UInt64 {
        var val: UInt64 = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<UInt64>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongLongType, value)
        }
        return val
    }
    
    public var floatValue: Float {
        var val: Float = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<Float>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberFloatType, value)
        }
        return val
    }
    
    public var doubleValue: Double {
        var val: Double = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<Double>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberDoubleType, value)
        }
        return val
    }
    
    public var boolValue: Bool {
        return longLongValue != 0
    }
    
    public var integerValue: Int {
        var val: Int = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<Int>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongType, value)
        }
        return val
    }
    
    public var unsignedIntegerValue: UInt {
        var val: UInt = 0
        withUnsafeMutablePointer(&val) { (value: UnsafeMutablePointer<UInt>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongType, value)
        }
        return val
    }
    
    /// Create an instance initialized to `value`.
    public required convenience init(integerLiteral value: Int) {
        self.init(integer: value)
    }
    
    /// Create an instance initialized to `value`.
    public required convenience init(floatLiteral value: Double) {
        self.init(double: value)
    }
    
    /// Create an instance initialized to `value`.
    public required convenience init(booleanLiteral value: Bool) {
        self.init(bool: value)
    }

    public func compare(otherNumber: NSNumber) -> NSComparisonResult {
        return ._fromCF(CFNumberCompare(_cfObject, otherNumber._cfObject, nil))
    }
    
    override public var _cfTypeID: CFTypeID {
        return CFNumberGetTypeID()
    }
    
    public override var description: String {
        let locale = CFLocaleCopyCurrent()
        let formatter = CFNumberFormatterCreate(nil, locale, kCFNumberFormatterDecimalStyle)
        CFNumberFormatterSetProperty(formatter, kCFNumberFormatterMaxFractionDigits, 15._bridgeToObject())
        return CFNumberFormatterCreateStringWithNumber(nil, formatter, self._cfObject)._swiftObject
    }
}

extension CFNumberRef : _NSBridgable {
    typealias NSType = NSNumber
    internal var _nsObject: NSType { return unsafeBitCast(self, NSType.self) }
}
