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
    
    public typealias _ObjectType = NSNumber
    public func _bridgeToObjectiveC() -> _ObjectType {
        return NSNumber(value: self)
    }
    
    static public func _forceBridgeFromObjectiveC(_ source: _ObjectType, result: inout Int?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    
    @discardableResult
    static public func _conditionallyBridgeFromObjectiveC(_ source: _ObjectType, result: inout Int?) -> Bool {
        result = source.intValue
        return true
    }
    
    static public func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectType?) -> Int {
        if let object = source {
            var value: Int?
            _conditionallyBridgeFromObjectiveC(object, result: &value)
            return value!
        } else {
            return 0
        }
    }
}

extension UInt : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.uintValue
    }

    public typealias _ObjectType = NSNumber
    public func _bridgeToObjectiveC() -> _ObjectType {
        return NSNumber(value: self)
    }
    
    static public func _forceBridgeFromObjectiveC(_ source: _ObjectType, result: inout UInt?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    
    @discardableResult
    static public func _conditionallyBridgeFromObjectiveC(_ source: _ObjectType, result: inout UInt?) -> Bool {
        result = source.uintValue
        return true
    }
    
    static public func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectType?) -> UInt {
        if let object = source {
            var value: UInt?
            _conditionallyBridgeFromObjectiveC(object, result: &value)
            return value!
        } else {
            return 0
        }
    }
}

extension Float : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.floatValue
    }
    
    public typealias _ObjectType = NSNumber
    public func _bridgeToObjectiveC() -> _ObjectType {
        return NSNumber(value: self)
    }
    
    static public func _forceBridgeFromObjectiveC(_ source: _ObjectType, result: inout Float?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    
    @discardableResult
    static public func _conditionallyBridgeFromObjectiveC(_ source: _ObjectType, result: inout Float?) -> Bool {
        result = source.floatValue
        return true
    }
    
    static public func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectType?) -> Float {
        if let object = source {
            var value: Float?
            _conditionallyBridgeFromObjectiveC(object, result: &value)
            return value!
        } else {
            return 0.0
        }
    }
}

extension Double : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.doubleValue
    }
    
    public typealias _ObjectType = NSNumber
    public func _bridgeToObjectiveC() -> _ObjectType {
        return NSNumber(value: self)
    }
    
    static public func _forceBridgeFromObjectiveC(_ source: _ObjectType, result: inout Double?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    
    @discardableResult
    static public func _conditionallyBridgeFromObjectiveC(_ source: _ObjectType, result: inout Double?) -> Bool {
        result = source.doubleValue
        return true
    }
    
    static public func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectType?) -> Double {
        if let object = source {
            var value: Double?
            _conditionallyBridgeFromObjectiveC(object, result: &value)
            return value!
        } else {
            return 0.0
        }
    }
}

extension Bool : _ObjectTypeBridgeable {
    public init(_ number: NSNumber) {
        self = number.boolValue
    }
    
    public typealias _ObjectType = NSNumber
    public func _bridgeToObjectiveC() -> _ObjectType {
        return NSNumber(value: self)
    }
    
    static public func _forceBridgeFromObjectiveC(_ source: _ObjectType, result: inout Bool?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    
    @discardableResult
    static public func _conditionallyBridgeFromObjectiveC(_ source: _ObjectType, result: inout Bool?) -> Bool {
        result = source.boolValue
        return true
    }
    
    static public func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectType?) -> Bool {
        if let object = source {
            var value: Bool?
            _conditionallyBridgeFromObjectiveC(object, result: &value)
            return value!
        } else {
            return false
        }
    }
}

extension Bool : _CFBridgeable {
    typealias CFType = CFBoolean
    var _cfObject: CFType {
        return self ? kCFBooleanTrue : kCFBooleanFalse
    }
}

extension NSNumber : ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {

}

open class NSNumber : NSValue {
    typealias CFType = CFNumber
    // This layout MUST be the same as CFNumber so that they are bridgeable
    private var _base = _CFInfo(typeID: CFNumberGetTypeID())
    private var _pad: UInt64 = 0
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    open override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    open override func isEqual(_ value: Any?) -> Bool {
        if let number = value as? Int {
            return intValue == number
        } else if let number = value as? Double {
            return doubleValue == number
        } else if let number = value as? Bool {
            return boolValue == number
        } else if let number = value as? NSNumber {
            return CFEqual(_cfObject, number._cfObject)
        }
        return false
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
        } else if type(of: aDecoder) == NSKeyedUnarchiver.self || aDecoder.containsValue(forKey: "NS.number") {
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

    open var int8Value: Int8 {
        var val: Int8 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Int8>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberCharType, value)
        }
        return val
    }

    open var uint8Value: UInt8 {
        var val: UInt8 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<UInt8>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberCharType, value)
        }
        return val
    }
    
    open var int16Value: Int16 {
        var val: Int16 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Int16>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberShortType, value)
        }
        return val
    }
    
    open var uint16Value: UInt16 {
        var val: UInt16 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<UInt16>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberShortType, value)
        }
        return val
    }
    
    open var int32Value: Int32 {
        var val: Int32 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Int32>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberIntType, value)
        }
        return val
    }
    
    open var uint32Value: UInt32 {
        var val: UInt32 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<UInt32>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberIntType, value)
        }
        return val
    }
    
    open var int64Value: Int64 {
        var val: Int64 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Int64>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongLongType, value)
        }
        return val
    }
    
    open var uint64Value: UInt64 {
        var val: UInt64 = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<UInt64>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongLongType, value)
        }
        return val
    }
    
    open var floatValue: Float {
        var val: Float = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Float>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberFloatType, value)
        }
        return val
    }
    
    open var doubleValue: Double {
        var val: Double = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Double>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberDoubleType, value)
        }
        return val
    }
    
    open var boolValue: Bool {
        return int64Value != 0
    }
    
    open var intValue: Int {
        var val: Int = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<Int>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongType, value)
        }
        return val
    }
    
    open var uintValue: UInt {
        var val: UInt = 0
        withUnsafeMutablePointer(to: &val) { (value: UnsafeMutablePointer<UInt>) -> Void in
            CFNumberGetValue(_cfObject, kCFNumberLongType, value)
        }
        return val
    }
    
    open var stringValue: String {
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

    open func compare(_ otherNumber: NSNumber) -> ComparisonResult {
        return ._fromCF(CFNumberCompare(_cfObject, otherNumber._cfObject, nil))
    }

    open func description(withLocale locale: Locale?) -> String {
        let aLocale = locale
        let formatter: CFNumberFormatter
        if (aLocale == nil) {
            formatter = CFNumberFormatterCreate(nil, CFLocaleCopyCurrent(), kCFNumberFormatterNoStyle)
            CFNumberFormatterSetProperty(formatter, kCFNumberFormatterMaxFractionDigits, 15._bridgeToObjectiveC())

        } else {
            formatter = CFNumberFormatterCreate(nil, aLocale?._cfObject, kCFNumberFormatterDecimalStyle)
        }
        return CFNumberFormatterCreateStringWithNumber(nil, formatter, self._cfObject)._swiftObject
    }
    
    override open var _cfTypeID: CFTypeID {
        return CFNumberGetTypeID()
    }
    
    open override var description: String {
        return description(withLocale: nil)
    }
}

extension CFNumber : _NSBridgeable {
    typealias NSType = NSNumber
    internal var _nsObject: NSType { return unsafeBitCast(self, to: NSType.self) }
}

