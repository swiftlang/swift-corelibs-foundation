// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

open class NSNumber : NSValue {
    typealias CFType = CFNumber

    internal var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    open override var hash: Int {
        switch objCType.pointee {
        case 0x6c /*l*/: fallthrough
        case 0x69 /*i*/: fallthrough
        case 0x73 /*s*/: fallthrough
        case 0x63 /*c*/: fallthrough
        case 0x42 /*B*/:
            return Int(bitPattern: _CFHashInt(intValue))
        case 0x4c /*L*/: fallthrough
        case 0x49 /*I*/: fallthrough
        case 0x53 /*S*/: fallthrough
        case 0x43 /*C*/:
            let i = uintValue
            return i > UInt(Int.max) ? Int(bitPattern: _CFHashDouble(Double(i))) : Int(bitPattern: _CFHashInt(Int(bitPattern: i)))
        case 0x71 /*q*/:
            return Int(bitPattern: _CFHashDouble(Double(int64Value)))
        case 0x51 /*Q*/:
            return Int(bitPattern: _CFHashDouble(Double(uint64Value)))
        default:
            return Int(bitPattern: _CFHashDouble(doubleValue))
        }
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
            return CFEqual(_cfObject, other._cfObject)
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
    
    private convenience init(bytes: UnsafeRawPointer, numberType: CFNumberType) {
        let cfnumber = CFNumberCreate(nil, numberType, bytes)
        self.init(factory: unsafeBitCast(cfnumber, to: NSNumber.self))
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
        self.init(factory: unsafeBitCast(value ? kCFBooleanTrue : kCFBooleanFalse, to: NSNumber.self))
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
        switch objCType.pointee {
        case 0x42 /*B*/: return self.int8Value
        case 0x63 /*c*/: return self.int8Value
        case 0x43 /*C*/: return Int8(bitPattern: uint8Value)
        case 0x73 /*s*/: return Int8(truncatingIfNeeded: int16Value)
        case 0x53 /*S*/: return Int8(truncatingIfNeeded: uint16Value)
        case 0x69 /*i*/: return Int8(truncatingIfNeeded: int32Value)
        case 0x49 /*I*/: return Int8(truncatingIfNeeded: uint32Value)
        case 0x6c /*l*/: return Int8(truncatingIfNeeded: intValue)
        case 0x4c /*L*/: return Int8(truncatingIfNeeded: uintValue)
        case 0x66 /*f*/: return Int8(truncatingIfNeeded: Int(floatValue))
        case 0x64 /*d*/: return Int8(truncatingIfNeeded: Int(doubleValue))
        case 0x71 /*q*/: return Int8(truncatingIfNeeded: int64Value)
        case 0x51 /*Q*/: return Int8(truncatingIfNeeded: uint64Value)
        default: fatalError()
        }
    }
    
    open var uint8Value: UInt8 {
        switch objCType.pointee {
        case 0x42 /*B*/: return UInt8(bitPattern: int8Value)
        case 0x63 /*c*/: return UInt8(bitPattern: int8Value)
        case 0x43 /*C*/: return self.uint8Value
        case 0x73 /*s*/: return UInt8(truncatingIfNeeded: int16Value)
        case 0x53 /*S*/: return UInt8(truncatingIfNeeded: uint16Value)
        case 0x69 /*i*/: return UInt8(truncatingIfNeeded: int32Value)
        case 0x49 /*I*/: return UInt8(truncatingIfNeeded: uint32Value)
        case 0x6c /*l*/: return UInt8(truncatingIfNeeded: intValue)
        case 0x4c /*L*/: return UInt8(truncatingIfNeeded: uintValue)
        case 0x66 /*f*/: return UInt8(truncatingIfNeeded: Int(floatValue))
        case 0x64 /*d*/: return UInt8(truncatingIfNeeded: Int(doubleValue))
        case 0x71 /*q*/: return UInt8(truncatingIfNeeded: int64Value)
        case 0x51 /*Q*/: return UInt8(truncatingIfNeeded: uint64Value)
        default: fatalError()
        }
    }
    
    open var int16Value: Int16 {
        switch objCType.pointee {
        case 0x42 /*B*/: return Int16(int8Value)
        case 0x63 /*c*/: return Int16(int8Value)
        case 0x43 /*C*/: return Int16(uint8Value)
        case 0x73 /*s*/: return self.int16Value
        case 0x53 /*S*/: return Int16(bitPattern: uint16Value)
        case 0x69 /*i*/: return Int16(truncatingIfNeeded: int32Value)
        case 0x49 /*I*/: return Int16(truncatingIfNeeded: uint32Value)
        case 0x6c /*l*/: return Int16(truncatingIfNeeded: intValue)
        case 0x4c /*L*/: return Int16(truncatingIfNeeded: uintValue)
        case 0x66 /*f*/: return Int16(truncatingIfNeeded: Int(floatValue))
        case 0x64 /*d*/: return Int16(truncatingIfNeeded: Int(doubleValue))
        case 0x71 /*q*/: return Int16(truncatingIfNeeded: int64Value)
        case 0x51 /*Q*/: return Int16(truncatingIfNeeded: uint64Value)
        default: fatalError()
        }
    }
    
    open var uint16Value: UInt16 {
        switch objCType.pointee {
        case 0x42 /*B*/: return UInt16(bitPattern: Int16(int8Value))
        case 0x63 /*c*/: return UInt16(bitPattern: Int16(int8Value))
        case 0x43 /*C*/: return UInt16(uint8Value)
        case 0x73 /*s*/: return UInt16(bitPattern: int16Value)
        case 0x53 /*S*/: return self.uint16Value
        case 0x69 /*i*/: return UInt16(truncatingIfNeeded: int32Value)
        case 0x49 /*I*/: return UInt16(truncatingIfNeeded: uint32Value)
        case 0x6c /*l*/: return UInt16(truncatingIfNeeded: intValue)
        case 0x4c /*L*/: return UInt16(truncatingIfNeeded: uintValue)
        case 0x66 /*f*/: return UInt16(truncatingIfNeeded: Int(floatValue))
        case 0x64 /*d*/: return UInt16(truncatingIfNeeded: Int(doubleValue))
        case 0x71 /*q*/: return UInt16(truncatingIfNeeded: int64Value)
        case 0x51 /*Q*/: return UInt16(truncatingIfNeeded: uint64Value)
        default: fatalError()
        }
    }
    
    open var int32Value: Int32 {
        switch objCType.pointee {
        case 0x42 /*B*/: return Int32(int8Value)
        case 0x63 /*c*/: return Int32(int8Value)
        case 0x43 /*C*/: return Int32(uint8Value)
        case 0x73 /*s*/: return Int32(int16Value)
        case 0x53 /*S*/: return Int32(uint16Value)
        case 0x69 /*i*/: return self.int32Value
        case 0x49 /*I*/: return Int32(bitPattern: uint32Value)
        case 0x6c /*l*/: return Int32(truncatingIfNeeded: intValue)
        case 0x4c /*L*/: return Int32(truncatingIfNeeded: uintValue)
        case 0x66 /*f*/: return Int32(truncatingIfNeeded: Int(floatValue))
        case 0x64 /*d*/: return Int32(truncatingIfNeeded: Int(doubleValue))
        case 0x71 /*q*/: return Int32(truncatingIfNeeded: int64Value)
        case 0x51 /*Q*/: return Int32(truncatingIfNeeded: uint64Value)
        default: fatalError()
        }
    }
    
    open var uint32Value: UInt32 {
        switch objCType.pointee {
        case 0x42 /*B*/: return UInt32(bitPattern: Int32(int8Value))
        case 0x63 /*c*/: return UInt32(bitPattern: Int32(int8Value))
        case 0x43 /*C*/: return UInt32(uint8Value)
        case 0x73 /*s*/: return UInt32(bitPattern: Int32(int16Value))
        case 0x53 /*S*/: return UInt32(uint16Value)
        case 0x69 /*i*/: return UInt32(bitPattern: int32Value)
        case 0x49 /*I*/: return self.uint32Value
        case 0x6c /*l*/: return UInt32(truncatingIfNeeded: intValue)
        case 0x4c /*L*/: return UInt32(truncatingIfNeeded: uintValue)
        case 0x66 /*f*/: return UInt32(truncatingIfNeeded: Int(floatValue))
        case 0x64 /*d*/: return UInt32(truncatingIfNeeded: Int(doubleValue))
        case 0x71 /*q*/: return UInt32(truncatingIfNeeded: int64Value)
        case 0x51 /*Q*/: return UInt32(truncatingIfNeeded: uint64Value)
        default: fatalError()
        }
    }
    
    open var int64Value: Int64 {
        switch objCType.pointee {
        case 0x42 /*B*/: return Int64(int8Value)
        case 0x63 /*c*/: return Int64(int8Value)
        case 0x43 /*C*/: return Int64(uint8Value)
        case 0x73 /*s*/: return Int64(int16Value)
        case 0x53 /*S*/: return Int64(uint16Value)
        case 0x69 /*i*/: return Int64(int32Value)
        case 0x49 /*I*/: return Int64(uint32Value)
        case 0x6c /*l*/: return Int64(intValue)
        case 0x4c /*L*/: return Int64(bitPattern: UInt64(uintValue))
        case 0x66 /*f*/: return Int64(floatValue)
        case 0x64 /*d*/: return Int64(doubleValue)
        case 0x71 /*q*/: return self.int64Value
        case 0x51 /*Q*/: return Int64(bitPattern: uint64Value)
        default: fatalError()
        }
    }
    
    open var uint64Value: UInt64 {
        switch objCType.pointee {
        case 0x42 /*B*/: return UInt64(bitPattern: Int64(int8Value))
        case 0x63 /*c*/: return UInt64(bitPattern: Int64(int8Value))
        case 0x43 /*C*/: return UInt64(uint8Value)
        case 0x73 /*s*/: return UInt64(bitPattern: Int64(int16Value))
        case 0x53 /*S*/: return UInt64(uint16Value)
        case 0x69 /*i*/: return UInt64(bitPattern: Int64(int32Value))
        case 0x49 /*I*/: return UInt64(uint32Value)
        case 0x6c /*l*/: return UInt64(bitPattern: Int64(intValue))
        case 0x4c /*L*/: return UInt64(uintValue)
        case 0x66 /*f*/: return UInt64(floatValue)
        case 0x64 /*d*/: return UInt64(doubleValue)
        case 0x71 /*q*/: return UInt64(bitPattern: int64Value)
        case 0x51 /*Q*/: return self.uint64Value
        default: fatalError()
        }
    }
    
    open var floatValue: Float {
        switch objCType.pointee {
        case 0x42 /*B*/: return Float(int8Value)
        case 0x63 /*c*/: return Float(int8Value)
        case 0x43 /*C*/: return Float(uint8Value)
        case 0x73 /*s*/: return Float(int16Value)
        case 0x53 /*S*/: return Float(uint16Value)
        case 0x69 /*i*/: return Float(int32Value)
        case 0x49 /*I*/: return Float(uint32Value)
        case 0x6c /*l*/: return Float(intValue)
        case 0x4c /*L*/: return Float(uintValue)
        case 0x66 /*f*/: return self.floatValue
        case 0x64 /*d*/: return Float(doubleValue)
        case 0x71 /*q*/: return Float(int64Value)
        case 0x51 /*Q*/: return Float(uint64Value)
        default: fatalError()
        }
    }
    
    open var doubleValue: Double {
        switch objCType.pointee {
        case 0x42 /*B*/: return Double(int8Value)
        case 0x63 /*c*/: return Double(int8Value)
        case 0x43 /*C*/: return Double(uint8Value)
        case 0x73 /*s*/: return Double(int16Value)
        case 0x53 /*S*/: return Double(uint16Value)
        case 0x69 /*i*/: return Double(int32Value)
        case 0x49 /*I*/: return Double(uint32Value)
        case 0x6c /*l*/: return Double(intValue)
        case 0x4c /*L*/: return Double(uintValue)
        case 0x66 /*f*/: return Double(floatValue)
        case 0x64 /*d*/: return self.doubleValue
        case 0x71 /*q*/: return Double(int64Value)
        case 0x51 /*Q*/: return Double(uint64Value)
        default: fatalError()
        }
    }
    
    open var boolValue: Bool {
        switch objCType.pointee {
        case 0x42 /*B*/: fallthrough
        case 0x63 /*c*/: fallthrough
        case 0x43 /*C*/: fallthrough
        case 0x73 /*s*/: fallthrough
        case 0x53 /*S*/: fallthrough
        case 0x69 /*i*/: fallthrough
        case 0x49 /*I*/: fallthrough
        case 0x6c /*l*/: fallthrough
        case 0x4c /*L*/: return intValue != 0
        case 0x66 /*f*/: fallthrough
        case 0x64 /*d*/: return doubleValue != 0.0
        case 0x71 /*q*/: fallthrough
        case 0x51 /*Q*/: return int64Value != 0
        default: fatalError()
        }
    }

    open var intValue: Int {
#if arch(x86_64) || arch(arm64)
        return Int(int64Value)
#else
        return Int(int32Value)
#endif
    }
    
    open var uintValue: UInt {
#if arch(x86_64) || arch(arm64)
        return UInt(uint64Value)
#else
        return UInt(uint32Value)
#endif
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

