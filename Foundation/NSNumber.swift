// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(OSX) || os(iOS)
internal let kCFNumberSInt8Type = CFNumberType.sInt8Type
internal let kCFNumberSInt16Type = CFNumberType.sInt16Type
internal let kCFNumberSInt32Type = CFNumberType.sInt32Type
internal let kCFNumberSInt64Type = CFNumberType.sInt64Type
internal let kCFNumberFloat32Type = CFNumberType.float32Type
internal let kCFNumberFloat64Type = CFNumberType.float64Type
internal let kCFNumberCharType = CFNumberType.charType
internal let kCFNumberShortType = CFNumberType.shortType
internal let kCFNumberIntType = CFNumberType.intType
internal let kCFNumberLongType = CFNumberType.longType
internal let kCFNumberLongLongType = CFNumberType.longLongType
internal let kCFNumberFloatType = CFNumberType.floatType
internal let kCFNumberDoubleType = CFNumberType.doubleType
internal let kCFNumberCFIndexType = CFNumberType.cfIndexType
internal let kCFNumberNSIntegerType = CFNumberType.nsIntegerType
internal let kCFNumberCGFloatType = CFNumberType.cgFloatType
#endif

extension Int : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.intValue
    }
    
    public func _bridgeToObject() -> NSNumber {
        return NSNumber(value: self)
    }
    
    public static func _forceBridgeFromObject(_ x: NSNumber, result: inout Int?) {
        result = x.intValue
    }
    
    public static func _conditionallyBridgeFromObject(_ x: NSNumber, result: inout Int?) -> Bool {
        self._forceBridgeFromObject(x, result: &result)
        return true
    }
}

extension UInt : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.uintValue
    }

    public func _bridgeToObject() -> NSNumber {
        return NSNumber(value: self)
    }
    
    public static func _forceBridgeFromObject(_ x: NSNumber, result: inout UInt?) {
        result = x.uintValue
    }
    public static func _conditionallyBridgeFromObject(_ x: NSNumber, result: inout UInt?) -> Bool {
        _forceBridgeFromObject(x, result: &result)
        return true
    }
}

extension Float : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.floatValue
    }
    
    public func _bridgeToObject() -> NSNumber {
        return NSNumber(value: self)
    }
    
    public static func _forceBridgeFromObject(_ x: NSNumber, result: inout Float?) {
        result = x.floatValue
    }
    
    public static func _conditionallyBridgeFromObject(_ x: NSNumber, result: inout Float?) -> Bool {
        _forceBridgeFromObject(x, result: &result)
        return true
    }
}

extension Double : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.doubleValue
    }
    
    public func _bridgeToObject() -> NSNumber {
        return NSNumber(value: self)
    }
    
    public static func _forceBridgeFromObject(_ x: NSNumber, result: inout Double?) {
        result = x.doubleValue
    }
    
    public static func _conditionallyBridgeFromObject(_ x: NSNumber, result: inout Double?) -> Bool {
        _forceBridgeFromObject(x, result: &result)
        return true
    }
}

extension Bool : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.boolValue
    }
    
    public func _bridgeToObject() -> NSNumber {
        return NSNumber(value: self)
    }
    
    public static func _forceBridgeFromObject(_ x: NSNumber, result: inout Bool?) {
        result = x.boolValue
    }
    
    public static func _conditionallyBridgeFromObject(_ x: NSNumber, result: inout Bool?) -> Bool {
        _forceBridgeFromObject(x, result: &result)
        return true
    }
}

extension Bool : _CFBridgable {
    typealias CFType = CFBoolean
    var _cfObject: CFType {
        return self ? kCFBooleanTrue : kCFBooleanFalse
    }
}

extension NSNumber : ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {

}

public class NSNumber : NSValue {
    typealias CFType = CFNumber
    // This layout MUST be the same as CFNumber so that they are bridgeable
    private var _base = _CFInfo(typeID: CFNumberGetTypeID())
    private var _pad: UInt64 = 0
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(_ object: AnyObject?) -> Bool {
        if let number = object as? NSNumber {
            return CFEqual(_cfObject, number._cfObject)
        } else {
            return false
        }
    }
    
    deinit {
        _CFDeinit(self)
    }
    
    public init(value: Int8) {
        super.init()
        _CFNumberInitInt8(_cfObject, value)
    }
    
    public init(value: UInt8) {
        super.init()
        _CFNumberInitUInt8(_cfObject, value)
    }
    
    public init(value: Int16) {
        super.init()
        _CFNumberInitInt16(_cfObject, value)
    }
    
    public init(value: UInt16) {
        super.init()
        _CFNumberInitUInt16(_cfObject, value)
    }
    
    public init(value: Int32) {
        super.init()
        _CFNumberInitInt32(_cfObject, value)
    }
    
    public init(value: UInt32) {
        super.init()
        _CFNumberInitUInt32(_cfObject, value)
    }
    
    public init(value: Int) {
        super.init()
        _CFNumberInitInt(_cfObject, value)
    }
    
    public init(value: UInt) {
        super.init()
        _CFNumberInitUInt(_cfObject, value)
    }
    
    public init(value: Int64) {
        super.init()
        _CFNumberInitInt64(_cfObject, value)
    }
    
    public init(value: UInt64) {
        super.init()
        _CFNumberInitUInt64(_cfObject, value)
    }
    
    public init(value: Float) {
        super.init()
        _CFNumberInitFloat(_cfObject, value)
    }
    
    public init(value: Double) {
        super.init()
        _CFNumberInitDouble(_cfObject, value)
    }
    
    public init(value: Bool) {
        super.init()
        _CFNumberInitBool(_cfObject, value)
    }
    
    public required convenience init(bytes buffer: UnsafeRawPointer, objCType: UnsafePointer<Int8>) {
        guard let type = _NSSimpleObjCType(UInt8(objCType.pointee)) else {
            fatalError("NSNumber.init: unsupported type encoding spec '\(String(cString: objCType))'")
        }
        switch type {
        case .Bool:
            self.init(value:buffer.load(as: Bool.self))
            break
        case .Char:
            self.init(value:buffer.load(as: Int8.self))
            break
        case .UChar:
            self.init(value:buffer.load(as: UInt8.self))
            break
        case .Short:
            self.init(value:buffer.load(as: Int16.self))
            break
        case .UShort:
            self.init(value:buffer.load(as: UInt16.self))
            break
        case .Int, .Long:
            self.init(value:buffer.load(as: Int32.self))
            break
        case .UInt, .ULong:
            self.init(value:buffer.load(as: UInt32.self))
            break
        case .LongLong:
            self.init(value:buffer.load(as: Int64.self))
            break
        case .ULongLong:
            self.init(value:buffer.load(as: UInt64.self))
            break
        case .Float:
            self.init(value:buffer.load(as: Float.self))
            break
        case .Double:
            self.init(value:buffer.load(as: Double.self))
            break
        default:
            fatalError("NSNumber.init: unsupported type encoding spec '\(String(cString: objCType))'")
            break
        }
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            var objCType: UnsafeMutablePointer<Int8>? = nil
            withUnsafeMutablePointer(to: &objCType, { (ptr: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>) -> Void in
                aDecoder.decodeValue(ofObjCType: String(_NSSimpleObjCType.CharPtr), at: UnsafeMutableRawPointer(ptr))
            })
            if objCType == nil {
                return nil
            }
            var size: Int = 0
            let _ = NSGetSizeAndAlignment(objCType!, &size, nil)
            let buffer = malloc(size)!
            aDecoder.decodeValue(ofObjCType: objCType!, at: buffer)
            self.init(bytes: buffer, objCType: objCType!)
            free(buffer)
        } else if aDecoder.dynamicType == NSKeyedUnarchiver.self || aDecoder.containsValue(forKey: "NS.number") {
            let number = aDecoder._decodePropertyListForKey("NS.number")
            if let val = number as? Double {
                self.init(value:val)
            } else if let val = number as? Int {
                self.init(value:val)
            } else if let val = number as? Bool {
                self.init(value:val)
            } else {
                return nil
            }
        } else {
            if aDecoder.containsValue(forKey: "NS.boolval") {
                self.init(value: aDecoder.decodeBool(forKey: "NS.boolval"))
            } else if aDecoder.containsValue(forKey: "NS.intval") {
                self.init(value: aDecoder.decodeInt64(forKey: "NS.intval"))
            } else if aDecoder.containsValue(forKey: "NS.dblval") {
                self.init(value: aDecoder.decodeDouble(forKey: "NS.dblval"))
            } else {
                return nil
            }
        }
    }

    public var int8Value: Int8 {
        var val: Int8 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Int8>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberCharType, value)
        }
        return val
    }

    public var uint8Value: UInt8 {
        var val: UInt8 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<UInt8>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberCharType, value)
        }
        return val
    }
    
    public var int16Value: Int16 {
        var val: Int16 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Int16>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberShortType, value)
        }
        return val
    }
    
    public var uint16Value: UInt16 {
        var val: UInt16 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<UInt16>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberShortType, value)
        }
        return val
    }
    
    public var int32Value: Int32 {
        var val: Int32 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Int32>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberIntType, value)
        }
        return val
    }
    
    public var uint32Value: UInt32 {
        var val: UInt32 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<UInt32>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberIntType, value)
        }
        return val
    }
    
    public var int64Value: Int64 {
        var val: Int64 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Int64>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongLongType, value)
        }
        return val
    }
    
    public var uint64Value: UInt64 {
        var val: UInt64 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<UInt64>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongLongType, value)
        }
        return val
    }
    
    public var floatValue: Float {
        var val: Float = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Float>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberFloatType, value)
        }
        return val
    }
    
    public var doubleValue: Double {
        var val: Double = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Double>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberDoubleType, value)
        }
        return val
    }
    
    public var boolValue: Bool {
        return int64Value != 0
    }
    
    public var intValue: Int {
        var val: Int = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Int>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongType, value)
        }
        return val
    }
    
    public var uintValue: UInt {
        var val: UInt = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<UInt>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongType, value)
        }
        return val
    }
    
    public var stringValue: String {
        return description(withLocale: nil)
    }
    
    /// Create an instance initialized to `value`.
    public required convenience init(integerLiteral value: Int) {
        self.init(value: value)
    }
    
    /// Create an instance initialized to `value`.
    public required convenience init(floatLiteral value: Double) {
        self.init(value: value)
    }
    
    /// Create an instance initialized to `value`.
    public required convenience init(booleanLiteral value: Bool) {
        self.init(value: value)
    }

    public func compare(_ otherNumber: NSNumber) -> ComparisonResult {
        return ._fromCF(CFNumberCompare(_cfObject, otherNumber._cfObject, nil))
    }

    public func description(withLocale locale: AnyObject?) -> String {
        let aLocale = locale
        let formatter: CFNumberFormatter
        if (aLocale == nil) {
            formatter = CFNumberFormatterCreate(nil, CFLocaleCopyCurrent(), kCFNumberFormatterNoStyle)
            CFNumberFormatterSetProperty(formatter, kCFNumberFormatterMaxFractionDigits, 15._bridgeToObject())

        } else {
            formatter = CFNumberFormatterCreate(nil, (aLocale as! Locale)._cfObject, kCFNumberFormatterDecimalStyle)
        }
        return CFNumberFormatterCreateStringWithNumber(nil, formatter, self._cfObject)._swiftObject
    }
    
    override public var _cfTypeID: CFTypeID {
        return CFNumberGetTypeID()
    }
    
    public override var description: String {
        return description(withLocale: nil)
    }
}

extension CFNumber : _NSBridgable {
    typealias NSType = NSNumber
    internal var _nsObject: NSType { return unsafeBitCast(self, to: NSType.self) }
}

extension NSNumber : CustomPlaygroundQuickLookable {
    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        let type = CFNumberGetType(_cfObject)
        switch type {
        case kCFNumberCharType:
            fallthrough
        case kCFNumberSInt16Type:
            fallthrough
        case kCFNumberSInt32Type:
            fallthrough
        case kCFNumberSInt64Type:
            fallthrough
        case kCFNumberCharType:
            fallthrough
        case kCFNumberShortType:
            fallthrough
        case kCFNumberIntType:
            fallthrough
        case kCFNumberLongType:
            fallthrough
        case kCFNumberCFIndexType:
            fallthrough
        case kCFNumberNSIntegerType:
            fallthrough
        case kCFNumberLongLongType:
            return .int(self.int64Value)
        case kCFNumberFloat32Type:
            fallthrough
        case kCFNumberFloatType:
            return .float(self.floatValue)
        case kCFNumberFloat64Type:
            fallthrough
        case kCFNumberDoubleType:
            return .double(self.doubleValue)
        case kCFNumberCGFloatType:
            if sizeof(CGFloat.self) == sizeof(Float32.self) {
                return .float(self.floatValue)
            } else {
                return .double(self.doubleValue)
            }
        default:
            return .text("invalid NSNumber")
        }
    }
}
