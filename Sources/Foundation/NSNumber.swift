// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


@_implementationOnly import CoreFoundation
@_spi(SwiftCorelibsFoundation) @_exported import FoundationEssentials

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

extension Int8 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.int8Value
    }

    public init(truncating number: NSNumber) {
        self = number.int8Value
    }

    public init?(exactly number: NSNumber) {
        let value = number.int8Value
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int8?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int8?) -> Bool {
        guard let value = Int8(exactly: x) else { return false }
        result = value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int8 {
        var result: Int8?
        guard let src = source else { return Int8(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Int8(0) }
        return result!
    }
}

extension UInt8 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.uint8Value
    }

    public init(truncating number: NSNumber) {
        self = number.uint8Value
    }

    public init?(exactly number: NSNumber) {
        let value = number.uint8Value
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt8?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt8?) -> Bool {
        guard let value = UInt8(exactly: x) else { return false }
        result = value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt8 {
        var result: UInt8?
        guard let src = source else { return UInt8(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return UInt8(0) }
        return result!
    }
}

extension Int16 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.int16Value
    }

    public init(truncating number: NSNumber) {
        self = number.int16Value
    }

    public init?(exactly number: NSNumber) {
        let value = number.int16Value
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int16?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int16?) -> Bool {
        guard let value = Int16(exactly: x) else { return false }
        result = value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int16 {
        var result: Int16?
        guard let src = source else { return Int16(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Int16(0) }
        return result!
    }
}

extension UInt16 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.uint16Value
    }

    public init(truncating number: NSNumber) {
        self = number.uint16Value
    }

    public init?(exactly number: NSNumber) {
        let value = number.uint16Value
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt16?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt16?) -> Bool {
        guard let value = UInt16(exactly: x) else { return false }
        result = value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt16 {
        var result: UInt16?
        guard let src = source else { return UInt16(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return UInt16(0) }
        return result!
    }
}

extension Int32 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.int32Value
    }

    public init(truncating number: NSNumber) {
        self = number.int32Value
    }

    public init?(exactly number: NSNumber) {
        let value = number.int32Value
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int32?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int32?) -> Bool {
        guard let value = Int32(exactly: x) else { return false }
        result = value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int32 {
        var result: Int32?
        guard let src = source else { return Int32(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Int32(0) }
        return result!
    }
}

extension UInt32 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.uint32Value
    }

    public init(truncating number: NSNumber) {
        self = number.uint32Value
    }

    public init?(exactly number: NSNumber) {
        let value = number.uint32Value
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt32?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt32?) -> Bool {
        guard let value = UInt32(exactly: x) else { return false }
        result = value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt32 {
        var result: UInt32?
        guard let src = source else { return UInt32(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return UInt32(0) }
        return result!
    }
}

extension Int64 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.int64Value
    }

    public init(truncating number: NSNumber) {
        self = number.int64Value
    }

    public init?(exactly number: NSNumber) {
        let value = number.int64Value
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int64?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int64?) -> Bool {
        guard let value = Int64(exactly: x) else { return false }
        result = value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int64 {
        var result: Int64?
        guard let src = source else { return Int64(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Int64(0) }
        return result!
    }
}

extension UInt64 : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.uint64Value
    }

    public init(truncating number: NSNumber) {
        self = number.uint64Value
    }

    public init?(exactly number: NSNumber) {
        let value = number.uint64Value
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }

    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt64?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt64?) -> Bool {
        guard let value = UInt64(exactly: x) else { return false }
        result = value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt64 {
        var result: UInt64?
        guard let src = source else { return UInt64(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return UInt64(0) }
        return result!
    }
}

extension Int : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.intValue
    }

    public init(truncating number: NSNumber) {
        self = number.intValue
    }

    public init?(exactly number: NSNumber) {
        let value = number.intValue
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Int?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Int?) -> Bool {
        guard let value = Int(exactly: x) else { return false }
        result = value
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Int {
        var result: Int?
        guard let src = source else { return Int(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Int(0) }
        return result!
    }
}

extension UInt : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.uintValue
    }

    public init(truncating number: NSNumber) {
        self = number.uintValue
    }

    public init?(exactly number: NSNumber) {
        let value = number.uintValue
        guard NSNumber(value: value) == number else { return nil }
        self = value
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout UInt?) -> Bool {
        guard let value = UInt(exactly: x) else { return false }
        result = value
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> UInt {
        var result: UInt?
        guard let src = source else { return UInt(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return UInt(0) }
        return result!
    }
}

extension Float : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.floatValue
    }

    public init(truncating number: NSNumber) {
        self = number.floatValue
    }

    public init?(exactly number: NSNumber) {
        let type = number.objCType.pointee
        if type == 0x49 || type == 0x4c || type == 0x51 {
            guard let result = Float(exactly: number.uint64Value) else { return nil }
            self = result
        } else if type == 0x69 || type == 0x6c || type == 0x71 {
            guard let result = Float(exactly: number.int64Value) else { return nil }
            self = result
        } else {
            guard let result = Float(exactly: number.doubleValue) else { return nil }
            self = result
        }
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Float?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Float?) -> Bool {
        if x.floatValue.isNaN {
            result = x.floatValue
            return true
        }
        result = Float(exactly: x)
        return result != nil
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Float {
        var result: Float?
        guard let src = source else { return Float(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Float(0) }
        return result!
    }
}

extension Double : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.doubleValue
    }

    public init(truncating number: NSNumber) {
        self = number.doubleValue
    }

    public init?(exactly number: NSNumber) {
        let type = number.objCType.pointee
        if type == 0x51 {
            guard let result = Double(exactly: number.uint64Value) else { return nil }
            self = result
        } else if type == 0x71 {
            guard let result = Double(exactly: number.int64Value) else  { return nil }
            self = result
        } else {
            // All other integer types and single-precision floating points will
            // fit in a `Double` without truncation.
            guard let result = Double(exactly: number.doubleValue) else { return nil }
            self = result
        }
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return NSNumber(value: self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Double?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Double?) -> Bool {
        if x.doubleValue.isNaN {
            result = x.doubleValue
            return true
        }
        result = Double(exactly: x)
        return result != nil
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Double {
        var result: Double?
        guard let src = source else { return Double(0) }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return Double(0) }
        return result!
    }
}

extension Bool : _ObjectiveCBridgeable {
    @available(swift, deprecated: 4, renamed: "init(truncating:)")
    public init(_ number: NSNumber) {
        self = number.boolValue
    }

    public init(truncating number: NSNumber) {
        self = number.boolValue
    }

    public init?(exactly number: NSNumber) {
        if number === kCFBooleanTrue || NSNumber(value: 1) == number {
            self = true
        } else if number === kCFBooleanFalse || NSNumber(value: 0) == number {
            self = false
        } else {
            return nil
        }
    }

    public func _bridgeToObjectiveC() -> NSNumber {
        return unsafeBitCast(self ? kCFBooleanTrue : kCFBooleanFalse, to: NSNumber.self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ x: NSNumber, result: inout Bool?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(type(of: x)) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNumber, result: inout Bool?) -> Bool {
        if x === kCFBooleanTrue || NSNumber(value: 1) == x {
            result = true
            return true
        } else if x === kCFBooleanFalse || NSNumber(value: 0) == x {
            result = false
            return true
        }

        result = nil
        return false
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNumber?) -> Bool {
        var result: Bool?
        guard let src = source else { return false }
        guard _conditionallyBridgeFromObjectiveC(src, result: &result) else { return false }
        return result!
    }
}

extension Bool {
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

fileprivate func cast<T, U>(_ t: T) -> U {
  return t as! U
}

open class NSNumber : NSValue, @unchecked Sendable {
    typealias CFType = CFNumber
    // This layout MUST be the same as CFNumber so that they are bridgeable
    private let _base = _CFInfo(typeID: CFNumberGetTypeID())
    private let _pad: UInt64 = 0

    internal final var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    open override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }

    open override func isEqual(_ value: Any?) -> Bool {
        // IMPORTANT:
        // .isEqual() is invoked by the bridging machinery that gets triggered whenever you use '(-a NSNumber value-) as{,?,!} Int', so using a refutable pattern ('case let other as NSNumber') below will cause an infinite loop if value is an Int, and similarly for other types we can bridge to.
        // To prevent this, _this check must come first._ If you change it, _do not use the 'as' operator_ or any of its variants _unless_ you know that value _is_ actually a NSNumber to avoid infinite loops. ('is' is fine.)
        if let value = value, value is NSNumber {
            return compare(value as! NSNumber) == .orderedSame
        }
        
        switch value {
        case let other as Int:
            return intValue == other
        case let other as Double:
            return doubleValue == other
        case let other as Bool:
            return boolValue == other
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
    
    internal var _swiftValueOfOptimalType: (Any & Sendable) {
        if self === kCFBooleanTrue {
            return true
        } else if self === kCFBooleanFalse {
            return false
        }
        
        let numberType = _CFNumberGetType2(_cfObject)
        switch numberType {
        case kCFNumberSInt8Type:
            return Int(int8Value)
        case kCFNumberSInt16Type:
            return Int(int16Value)
        case kCFNumberSInt32Type:
            return Int(int32Value)
        case kCFNumberSInt64Type:
            return int64Value < Int.max ? Int(int64Value) : int64Value
        case kCFNumberFloat32Type:
            return floatValue
        case kCFNumberFloat64Type:
            return doubleValue
        case kCFNumberSInt128Type:
            // If the high portion is 0, return just the low portion as a UInt64, which reasonably fixes trying to roundtrip UInt.max and UInt64.max.
            if int128Value.high == 0 {
                return int128Value.low
            } else {
                return int128Value                
            }
        default:
            fatalError("unsupported CFNumberType: '\(numberType)'")
        }
    }

    deinit {
        _CFDeinit(self)
    }
    
    private convenience init(bytes: UnsafeRawPointer, numberType: CFNumberType) {
        // CFNumber is not Sendable, but we know this is safe
        nonisolated(unsafe) let cfnumber = CFNumberCreate(nil, numberType, bytes)
        self.init(factory: { cast(unsafeBitCast(cfnumber, to: NSNumber.self)) })
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
        #elseif arch(i386) || arch(arm) || arch(wasm32)
            self.init(bytes: &value, numberType: kCFNumberSInt32Type)
        #else
            #error("This architecture isn't known. Add it to the 32-bit or 64-bit line.")
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
    #elseif arch(i386) || arch(arm) || arch(wasm32)
        var value = Int64(value)
        self.init(bytes: &value, numberType: kCFNumberSInt64Type)
    #else
        #error("This architecture isn't known. Add it to the 32-bit or 64-bit line.")
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
        self.init(factory: cast(value._bridgeToObjectiveC))
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

    private var int128Value: CFSInt128Struct {
        var value = CFSInt128Struct(high: 0, low: 0)
        CFNumberGetValue(_cfObject, kCFNumberSInt128Type, &value)
        return value
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
        return self.description
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
        switch (_cfNumberType(), otherNumber._cfNumberType()) {
        case (kCFNumberFloatType, _), (_, kCFNumberFloatType): fallthrough
        case (kCFNumberDoubleType, _), (_, kCFNumberDoubleType):
            let (lhs, rhs) = (doubleValue, otherNumber.doubleValue)
            // Apply special handling for NaN as <, >, == always return false
            // when comparing with NaN
            if lhs.isNaN && rhs.isNaN { return .orderedSame }
            if lhs.isNaN { return rhs < 0 ? .orderedDescending : .orderedAscending }
            if rhs.isNaN { return lhs < 0 ? .orderedAscending : .orderedDescending }

            if lhs < rhs { return .orderedAscending }
            if lhs > rhs { return .orderedDescending }
            return .orderedSame

        default: // For signed and unsigned integers expand upto S128Int
            let (lhs, rhs) = (int128Value, otherNumber.int128Value)
            if lhs.high < rhs.high { return .orderedAscending }
            if lhs.high > rhs.high { return .orderedDescending }
            if lhs.low < rhs.low { return .orderedAscending }
            if lhs.low > rhs.low { return .orderedDescending }
            return .orderedSame
        }
    }

    open func isEqual(to number: NSNumber) -> Bool {
        return compare(number) == .orderedSame
    }

    open func description(withLocale locale: Locale?) -> String {
        guard let locale = locale else { return self.description }
        switch _CFNumberGetType2(_cfObject) {
        case kCFNumberSInt8Type, kCFNumberCharType:
            return String(format: "%d", locale: locale, self.int8Value)

        case kCFNumberSInt16Type, kCFNumberShortType:
            return String(format: "%hi", locale: locale, self.int16Value)

        case kCFNumberSInt32Type:
            return String(format: "%d", locale: locale, self.int32Value)

        case kCFNumberIntType, kCFNumberLongType, kCFNumberNSIntegerType, kCFNumberCFIndexType:
            return String(format: "%ld", locale: locale, self.intValue)

        case kCFNumberSInt64Type, kCFNumberLongLongType:
            return String(format: "%lld", locale: locale, self.int64Value)

        case kCFNumberSInt128Type:
            let value = self.int128Value
            if value.high == 0 {
                return value.low.description    // BUG: "%llu" doesnt work correctly and treats number as signed
            } else {
                // BUG: Note the locale is actually ignored here as this is converted using CFNumber.c:emit128()
                return String(format: "%@", locale: locale, unsafeBitCast(_cfObject, to: UnsafePointer<CFNumber>.self))
            }

        case kCFNumberFloatType, kCFNumberFloat32Type:
            return String(format: "%0.7g", locale: locale, self.floatValue)

        case kCFNumberFloat64Type, kCFNumberDoubleType:
            return String(format: "%0.16g", locale: locale, self.doubleValue)

        case kCFNumberCGFloatType:
            if Int.max == Int32.max {
                return String(format: "%0.7g", locale: locale, self.floatValue)
            } else {
                return String(format: "%0.16g", locale: locale, self.doubleValue)
            }
        default: fatalError("Unknown NSNumber Type")
        }
    }
    
    override internal var _cfTypeID: CFTypeID {
        return CFNumberGetTypeID()
    }
    
    open override var description: String {
        switch _CFNumberGetType2(_cfObject) {
        case kCFNumberSInt8Type, kCFNumberCharType, kCFNumberSInt16Type, kCFNumberShortType,
             kCFNumberSInt32Type, kCFNumberIntType, kCFNumberLongType, kCFNumberNSIntegerType, kCFNumberCFIndexType:
            return self.intValue.description

        case kCFNumberSInt64Type, kCFNumberLongLongType:
            return self.int64Value.description

        case kCFNumberSInt128Type:
            let value = self.int128Value
            if value.high == 0 {
                return value.low.description
            } else {
                return String(format: "%@", locale: nil, unsafeBitCast(_cfObject, to: UnsafePointer<CFNumber>.self))
            }

        case kCFNumberFloatType, kCFNumberFloat32Type:
            return self.floatValue.description

        case kCFNumberFloat64Type, kCFNumberDoubleType:
            return self.doubleValue.description

        case kCFNumberCGFloatType:
            if Int.max == Int32.max {
                return self.floatValue.description
            } else {
                return self.doubleValue.description
            }
        default: fatalError("Unknown NSNumber Type")
        }
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
    
    internal final func _getValue(_ valuePtr: UnsafeMutableRawPointer, forType type: CFNumberType) -> Bool {
        switch type {
        case kCFNumberSInt8Type:
            valuePtr.assumingMemoryBound(to: Int8.self).pointee = int8Value
        case kCFNumberSInt16Type:
            valuePtr.assumingMemoryBound(to: Int16.self).pointee = int16Value
        case kCFNumberSInt32Type:
            valuePtr.assumingMemoryBound(to: Int32.self).pointee = int32Value
        case kCFNumberSInt64Type:
            valuePtr.assumingMemoryBound(to: Int64.self).pointee = int64Value
        case kCFNumberSInt128Type:
            struct CFSInt128Struct {
                var high: Int64
                var low: UInt64
            }
            let val = int64Value
            valuePtr.assumingMemoryBound(to: CFSInt128Struct.self).pointee = CFSInt128Struct.init(high: (val < 0) ? -1 : 0, low: UInt64(bitPattern: val))
        case kCFNumberFloat32Type:
            valuePtr.assumingMemoryBound(to: Float.self).pointee = floatValue
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
    
    /// Provides a way for `plutil` to know if `CFPropertyList` has returned a literal `true`/`false` value, as opposed to a number which happens to have a value of 1 or 0.
    @_spi(BooleanCheckingForPLUtil)
    public var _exactBoolValue: Bool? {
        if self === kCFBooleanTrue {
            return true
        } else if self === kCFBooleanFalse {
            return false
        } else {
            return nil
        }
    }
}

extension CFNumber : _NSBridgeable {
    typealias NSType = NSNumber
    internal var _nsObject: NSType { return unsafeBitCast(self, to: NSType.self) }
}

internal func _CFSwiftNumberGetType(_ obj: CFTypeRef) -> CFNumberType {
    return unsafeDowncast(obj, to: NSNumber.self)._cfNumberType()
}

internal func _CFSwiftNumberGetValue(_ obj: CFTypeRef, _ valuePtr: UnsafeMutableRawPointer, _ type: CFNumberType) -> Bool {
    return unsafeDowncast(obj, to: NSNumber.self)._getValue(valuePtr, forType: type)
}

internal func _CFSwiftNumberGetBoolValue(_ obj: CFTypeRef) -> Bool {
    return unsafeDowncast(obj, to: NSNumber.self).boolValue
}

protocol _NSNumberCastingWithoutBridging {
  var _swiftValueOfOptimalType: (Any & Sendable) { get }
}

extension NSNumber: _NSNumberCastingWithoutBridging {}

// Called by FoundationEssentials
internal struct _FoundationNSNumberInitializer : _NSNumberInitializer {
    public static func initialize(value: some BinaryInteger) -> Any {
        if let int64 = Int64(exactly: value) {
            return NSNumber(value: int64)
        } else {
            return NSNumber(value: UInt64(value))
        }
    }
    
    public static func initialize(value: Bool) -> Any {
        NSNumber(value: value)
    }
}

@_dynamicReplacement(for: _nsNumberInitializer())
private func _nsNumberInitializer_corelibs_foundation() -> _NSNumberInitializer.Type? {
    return _FoundationNSNumberInitializer.self
}
