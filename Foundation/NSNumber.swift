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
internal let kCFNumberSInt128Type = CFNumberType(rawValue: 17)!
#else
internal let kCFNumberSInt128Type: CFNumberType = 17
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
        return unsafeBitCast(self ? kCFBooleanTrue : kCFBooleanFalse, to: NSNumber.self)
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

private struct CFSInt128Struct {
    var high: Int64
    var low: UInt64
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
        switch value {
        case let other as Int:
            return intValue == other
        case let other as Double:
            return doubleValue == other
        case let other as Bool:
            return boolValue == other
        case let other as NSNumber:
            return compare(other) == .orderedSame
        default:
            return false
        }
    }

    open override var objCType: UnsafePointer<Int8> {
        func _objCType(_ staticString: StaticString) -> UnsafePointer<Int8> {
            return UnsafeRawPointer(staticString.utf8Start).assumingMemoryBound(to: Int8.self)
        }
        let numberType = _CFNumberGetType2(_cfObject)
        switch numberType {
        case kCFNumberSInt8Type:
            return _objCType("c")
        case kCFNumberSInt16Type:
            return _objCType("s")
        case kCFNumberSInt32Type:
            return _objCType("i")
        case kCFNumberSInt64Type:
            return _objCType("q")
        case kCFNumberFloat32Type:
            return _objCType("f")
        case kCFNumberFloat64Type:
            return _objCType("d")
        case kCFNumberSInt128Type:
            return _objCType("Q")
        default:
            fatalError("unsupported CFNumberType: '\(numberType)'")
        }
    }

    deinit {
        _CFDeinit(self)
    }
    
    private convenience init(bytes: UnsafeRawPointer, numberType: CFNumberType) {
        let cfnumber = CFNumberCreate(nil, numberType, bytes)
        self.init(factory: { unsafeBitCast(cfnumber, to: NSNumber.self) })
    }
    
    public convenience init(value: Int8) {
        var value = value
        self.init(bytes: &value, numberType: kCFNumberSInt8Type)
    }
    
    public convenience init(value: UInt8) {
        var value = Int16(value)
        self.init(bytes: &value, numberType: kCFNumberSInt16Type)
    }
    
    public convenience init(value: Int16) {
        var value = value
        self.init(bytes: &value, numberType: kCFNumberSInt16Type)
    }
    
    public convenience init(value: UInt16) {
        var value = Int32(value)
        self.init(bytes: &value, numberType: kCFNumberSInt32Type)
    }
    
    public convenience init(value: Int32) {
        var value = value
        self.init(bytes: &value, numberType: kCFNumberSInt32Type)
    }
    
    public convenience init(value: UInt32) {
        var value = Int64(value)
        self.init(bytes: &value, numberType: kCFNumberSInt64Type)
    }
    
    public convenience init(value: Int) {
        var value = value
        #if arch(x86_64) || arch(arm64) || arch(s390x) || arch(powerpc64) || arch(powerpc64le)
            self.init(bytes: &value, numberType: kCFNumberSInt64Type)
        #elseif arch(i386) || arch(arm)
            self.init(bytes: &value, numberType: kCFNumberSInt32Type)
        #endif
    }
    
    public convenience init(value: UInt) {
    #if arch(x86_64) || arch(arm64) || arch(s390x) || arch(powerpc64) || arch(powerpc64le)
        if value > UInt64(Int64.max) {
            var value = CFSInt128Struct(high: 0, low: UInt64(value))
            self.init(bytes: &value, numberType: kCFNumberSInt128Type)
        } else {
            var value = Int64(value)
            self.init(bytes: &value, numberType: kCFNumberSInt64Type)
        }
    #elseif arch(i386) || arch(arm)
        var value = Int64(value)
        self.init(bytes: &value, numberType: kCFNumberSInt64Type)
    #endif
    }
    
    public convenience init(value: Int64) {
        var value = value
        self.init(bytes: &value, numberType: kCFNumberSInt64Type)
    }
    
    public convenience init(value: UInt64) {
        if value > UInt64(Int64.max) {
            var value = CFSInt128Struct(high: 0, low: UInt64(value))
            self.init(bytes: &value, numberType: kCFNumberSInt128Type)
        } else {
            var value = Int64(value)
            self.init(bytes: &value, numberType: kCFNumberSInt64Type)
        }
    }
    
    public convenience init(value: Float) {
        var value = value
        self.init(bytes: &value, numberType: kCFNumberFloatType)
    }
    
    public convenience init(value: Double) {
        var value = value
        self.init(bytes: &value, numberType: kCFNumberDoubleType)
    }

    public convenience init(value: Bool) {
        self.init(factory: value._bridgeToObjectiveC)
    }

    override internal init() {
        super.init()
    }

    public required convenience init(bytes buffer: UnsafeRawPointer, objCType: UnsafePointer<Int8>) {
        guard let type = _NSSimpleObjCType(UInt8(objCType.pointee)) else {
            fatalError("NSNumber.init: unsupported type encoding spec '\(String(cString: objCType))'")
        }
        switch type {
        case .Bool:
            self.init(value:buffer.load(as: Bool.self))
        case .Char:
            self.init(value:buffer.load(as: Int8.self))
        case .UChar:
            self.init(value:buffer.load(as: UInt8.self))
        case .Short:
            self.init(value:buffer.load(as: Int16.self))
        case .UShort:
            self.init(value:buffer.load(as: UInt16.self))
        case .Int, .Long:
            self.init(value:buffer.load(as: Int32.self))
        case .UInt, .ULong:
            self.init(value:buffer.load(as: UInt32.self))
        case .LongLong:
            self.init(value:buffer.load(as: Int64.self))
        case .ULongLong:
            self.init(value:buffer.load(as: UInt64.self))
        case .Float:
            self.init(value:buffer.load(as: Float.self))
        case .Double:
            self.init(value:buffer.load(as: Double.self))
        default:
            fatalError("NSNumber.init: unsupported type encoding spec '\(String(cString: objCType))'")
        }
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        if type(of: aDecoder) == NSKeyedUnarchiver.self || aDecoder.containsValue(forKey: "NS.number") {
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
        var value: Int64 = 0
        CFNumberGetValue(_cfObject, kCFNumberSInt64Type, &value)
        return .init(truncatingIfNeeded: value)
    }

    open var uint8Value: UInt8 {
        var value: Int64 = 0
        CFNumberGetValue(_cfObject, kCFNumberSInt64Type, &value)
        return .init(truncatingIfNeeded: value)
    }
    
    open var int16Value: Int16 {
        var value: Int64 = 0
        CFNumberGetValue(_cfObject, kCFNumberSInt64Type, &value)
        return .init(truncatingIfNeeded: value)
    }
    
    open var uint16Value: UInt16 {
        var value: Int64 = 0
        CFNumberGetValue(_cfObject, kCFNumberSInt64Type, &value)
        return .init(truncatingIfNeeded: value)
    }
    
    open var int32Value: Int32 {
        var value: Int64 = 0
        CFNumberGetValue(_cfObject, kCFNumberSInt64Type, &value)
        return .init(truncatingIfNeeded: value)
    }
    
    open var uint32Value: UInt32 {
        var value: Int64 = 0
        CFNumberGetValue(_cfObject, kCFNumberSInt64Type, &value)
        return .init(truncatingIfNeeded: value)
    }
    
    open var int64Value: Int64 {
        var value: Int64 = 0
        CFNumberGetValue(_cfObject, kCFNumberSInt64Type, &value)
        return .init(truncatingIfNeeded: value)
    }
    
    open var uint64Value: UInt64 {
        var value = CFSInt128Struct(high: 0, low: 0)
        CFNumberGetValue(_cfObject, kCFNumberSInt128Type, &value)
        return .init(truncatingIfNeeded: value.low)
    }
    
    open var floatValue: Float {
        var value: Float = 0
        CFNumberGetValue(_cfObject, kCFNumberFloatType, &value)
        return value
    }
    
    open var doubleValue: Double {
        var value: Double = 0
        CFNumberGetValue(_cfObject, kCFNumberDoubleType, &value)
        return value
    }
    
    open var boolValue: Bool {
        // Darwin Foundation NSNumber appears to have a bug and return false for NSNumber(value: Int64.min).boolValue,
        // even though the documentation says:
        // "A 0 value always means false, and any nonzero value is interpreted as true."
        return (int64Value != 0) && (int64Value != Int64.min)
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
        switch (objCType.pointee, otherNumber.objCType.pointee) {
        case (0x66, _), (_, 0x66), (0x66, 0x66): fallthrough // 'f' float
        case (0x64, _), (_, 0x64), (0x64, 0x64):             // 'd' double
            let (lhs, rhs) = (doubleValue, otherNumber.doubleValue)
            if lhs < rhs { return .orderedAscending }
            if lhs > rhs { return .orderedDescending }
            return .orderedSame
        case (0x51, _), (_, 0x51), (0x51, 0x51):             // 'q' unsigned long long
            let (lhs, rhs) = (uint64Value, otherNumber.uint64Value)
            if lhs < rhs { return .orderedAscending }
            if lhs > rhs { return .orderedDescending }
            return .orderedSame
        case (_, _):
            let (lhs, rhs) = (int64Value, otherNumber.int64Value)
            if lhs < rhs { return .orderedAscending }
            if lhs > rhs { return .orderedDescending }
            return .orderedSame
        }
    }

    private static let _numberFormatterForNilLocale: CFNumberFormatter = {
        let formatter: CFNumberFormatter
        formatter = CFNumberFormatterCreate(nil, CFLocaleCopyCurrent(), kCFNumberFormatterNoStyle)
        CFNumberFormatterSetProperty(formatter, kCFNumberFormatterMaxFractionDigits, 15._bridgeToObjectiveC())
        return formatter
    }()

    open func description(withLocale locale: Locale?) -> String {
        // CFNumberFormatterCreateStringWithNumber() does not like numbers of type
        // SInt128Type, as it loses the type when looking it up and treats it as
        // an SInt64Type, so special case them.
        if _CFNumberGetType2(_cfObject) == kCFNumberSInt128Type {
            return String(format: "%@", unsafeBitCast(_cfObject, to: UnsafePointer<CFNumber>.self))
        }

        let aLocale = locale
        let formatter: CFNumberFormatter
        if (aLocale == nil) {
            formatter = NSNumber._numberFormatterForNilLocale
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
    
    internal func _cfNumberType() -> CFNumberType {
        switch objCType.pointee {
        case 0x42: return kCFNumberCharType
        case 0x63: return kCFNumberCharType
        case 0x43: return kCFNumberShortType
        case 0x73: return kCFNumberShortType
        case 0x53: return kCFNumberIntType
        case 0x69: return kCFNumberIntType
        case 0x49: return Int(uint32Value) < Int(Int32.max) ? kCFNumberIntType : kCFNumberLongLongType
        case 0x6C: return kCFNumberLongType
        case 0x4C: return uintValue < UInt(Int.max) ? kCFNumberLongType : kCFNumberLongLongType
        case 0x66: return kCFNumberFloatType
        case 0x64: return kCFNumberDoubleType
        case 0x71: return kCFNumberLongLongType
        case 0x51: return kCFNumberLongLongType
        default: fatalError()
        }
    }
    
    internal func _getValue(_ valuePtr: UnsafeMutableRawPointer, forType type: CFNumberType) -> Bool {
        switch type {
        case kCFNumberSInt8Type:
            valuePtr.assumingMemoryBound(to: Int8.self).pointee = int8Value
            break
        case kCFNumberSInt16Type:
            valuePtr.assumingMemoryBound(to: Int16.self).pointee = int16Value
            break
        case kCFNumberSInt32Type:
            valuePtr.assumingMemoryBound(to: Int32.self).pointee = int32Value
            break
        case kCFNumberSInt64Type:
            valuePtr.assumingMemoryBound(to: Int64.self).pointee = int64Value
            break
        case kCFNumberSInt128Type:
            struct CFSInt128Struct {
                var high: Int64
                var low: UInt64
            }
            let val = int64Value
            valuePtr.assumingMemoryBound(to: CFSInt128Struct.self).pointee = CFSInt128Struct.init(high: (val < 0) ? -1 : 0, low: UInt64(bitPattern: val))
            break
        case kCFNumberFloat32Type:
            valuePtr.assumingMemoryBound(to: Float.self).pointee = floatValue
            break
        case kCFNumberFloat64Type:
            valuePtr.assumingMemoryBound(to: Double.self).pointee = doubleValue
        default: fatalError()
        }
        return true
    }
    
    open override func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        if let keyedCoder = aCoder as? NSKeyedArchiver {
            keyedCoder._encodePropertyList(self)
        } else {
            if CFGetTypeID(self) == CFBooleanGetTypeID() {
                aCoder.encode(boolValue, forKey: "NS.boolval")
            } else {
                switch objCType.pointee {
                case 0x42:
                    aCoder.encode(boolValue, forKey: "NS.boolval")
                    break
                case 0x63: fallthrough
                case 0x43: fallthrough
                case 0x73: fallthrough
                case 0x53: fallthrough
                case 0x69: fallthrough
                case 0x49: fallthrough
                case 0x6C: fallthrough
                case 0x4C: fallthrough
                case 0x71: fallthrough
                case 0x51:
                    aCoder.encode(int64Value, forKey: "NS.intval")
                case 0x66: fallthrough
                case 0x64:
                    aCoder.encode(doubleValue, forKey: "NS.dblval")
                default: break
                }
            }
        }
    }

    open override var classForCoder: AnyClass { return NSNumber.self }
}

extension CFNumber : _NSBridgeable {
    typealias NSType = NSNumber
    internal var _nsObject: NSType { return unsafeBitCast(self, to: NSType.self) }
}

internal func _CFSwiftNumberGetType(_ obj: CFTypeRef) -> CFNumberType {
    return unsafeBitCast(obj, to: NSNumber.self)._cfNumberType()
}

internal func _CFSwiftNumberGetValue(_ obj: CFTypeRef, _ valuePtr: UnsafeMutableRawPointer, _ type: CFNumberType) -> Bool {
    return unsafeBitCast(obj, to: NSNumber.self)._getValue(valuePtr, forType: type)
}

internal func _CFSwiftNumberGetBoolValue(_ obj: CFTypeRef) -> Bool {
    return unsafeBitCast(obj, to: NSNumber.self).boolValue
}
