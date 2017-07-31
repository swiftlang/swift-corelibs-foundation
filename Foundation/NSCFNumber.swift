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

internal struct CFSInt128Struct {
    var high: Int64
    var low: UInt64
}

internal final class __NSCFNumber : NSNumber {
    override var hash: Int {
        return Int(bitPattern: CFHash(_unsafeReferenceCast(self, to: CFNumber.self)))
    }
    
    override func getValue(_ value: UnsafeMutableRawPointer) {
        let type = _CFNumberGetType2(_unsafeReferenceCast(self, to: CFNumber.self))
        if type == kCFNumberSInt128Type {
            var s = CFSInt128Struct(high: 0, low: 0)
            CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), type, &s)
            if s.high != 0 {
                value.assumingMemoryBound(to: UInt64.self).pointee = UInt64.max
            } else {
                value.assumingMemoryBound(to: UInt64.self).pointee = s.low
            }
            return
        }
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), type, value)
    }
    
    override var objCType: UnsafePointer<Int8> {
        func _objCType(_ staticString: StaticString) -> UnsafePointer<Int8> {
            return UnsafeRawPointer(staticString.utf8Start).assumingMemoryBound(to: Int8.self)
        }
        let type = _CFNumberGetType2(_unsafeReferenceCast(self, to: CFNumber.self))
        switch type {
        case kCFNumberSInt8Type: return _objCType("c")
        case kCFNumberSInt16Type: return _objCType("s")
        case kCFNumberSInt32Type: return _objCType("i")
        case kCFNumberSInt64Type: return _objCType("q")
        case kCFNumberFloat32Type: return _objCType("f")
        case kCFNumberFloat64Type: return _objCType("d")
        // we know, at this point, that we are only using the SInt128 for unsigned 64-bit int
        case kCFNumberSInt128Type: return _objCType("Q")
        default: fatalError()
        }
    }
    
    override var int8Value: Int8 {
        var value: Int64 = 0
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt64Type, &value)
        return Int8(truncatingIfNeeded: value)
    }
    
    override var uint8Value: UInt8 {
        var value: Int64 = 0
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt64Type, &value)
        return UInt8(truncatingIfNeeded: value)
    }
    
    override var int16Value: Int16 {
        var value: Int64 = 0
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt64Type, &value)
        return Int16(truncatingIfNeeded: value)
    }
    
    override var uint16Value: UInt16 {
        var value: Int64 = 0
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt64Type, &value)
        return UInt16(truncatingIfNeeded: value)
    }
    
    override var int32Value: Int32 {
        var value: Int64 = 0
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt64Type, &value)
        return Int32(truncatingIfNeeded: value)
    }
    
    override var uint32Value: UInt32 {
        var value: Int64 = 0
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt64Type, &value)
        return UInt32(truncatingIfNeeded: value)
    }
    
    override var intValue: Int {
        var value: Int64 = 0
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt64Type, &value)
        return Int(truncatingIfNeeded: value)
    }
    
    override var uintValue: UInt {
        #if arch(x86_64) || arch(arm64)
            var value = CFSInt128Struct(high: 0, low: 0)
            CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt128Type, &value)
            return UInt(value.low)
        #else
            var value: Int64 = 0
            CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt64Type, &value)
            return UInt(bitPattern: value)
        #endif
    }
    
    override var int64Value: Int64 {
        var value: Int64 = 0
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt64Type, &value)
        return value
    }
    
    override var uint64Value: UInt64 {
        var value = CFSInt128Struct(high: 0, low: 0)
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt128Type, &value)
        return UInt64(value.low)
    }
    
    override var floatValue: Float {
        var value: Float = 0
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberFloatType, &value)
        return value
    }
    
    override var doubleValue: Double {
        var value: Double = 0
        CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberDoubleType, &value)
        return value
    }
    
    override var boolValue: Bool {
        if CFNumberIsFloatType(_unsafeReferenceCast(self, to: CFNumber.self)) {
            var value: Double = 0
            CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberDoubleType, &value)
            return value == 0 ? false : true
        } else {
            var value: Int32 = 0
            CFNumberGetValue(_unsafeReferenceCast(self, to: CFNumber.self), kCFNumberSInt32Type, &value)
            return value == 0 ? false : true
        }
    }
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
