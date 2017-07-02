// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

internal class __NSCFBoolean : NSNumber {
    override var hash: Int {
        return Int(bitPattern: CFHash(unsafeBitCast(self, to: CFBoolean.self)))
    }
    
    override func description(withLocale locale: Locale?) -> String {
        return boolValue ? "1" : "0"
    }
    
    override var int8Value: Int8 {
        return boolValue ? 1 : 0
    }
    
    override var uint8Value: UInt8 {
        return boolValue ? 1 : 0
    }

    override var int16Value: Int16 {
        return boolValue ? 1 : 0
    }
    
    override var uint16Value: UInt16 {
        return boolValue ? 1 : 0
    }
    
    override var int32Value: Int32 {
        return boolValue ? 1 : 0
    }
    
    override var uint32Value: UInt32 {
        return boolValue ? 1 : 0
    }

    override var intValue: Int {
        return boolValue ? 1 : 0
    }
    
    override var uintValue: UInt {
        return boolValue ? 1 : 0
    }
    
    override var int64Value: Int64 {
        return boolValue ? 1 : 0
    }
    
    override var uint64Value: UInt64 {
        return boolValue ? 1 : 0
    }
    
    override var floatValue: Float {
        return boolValue ? 1 : 0
    }
    
    override var doubleValue: Double {
        return boolValue ? 1 : 0
    }
    
    override var boolValue: Bool {
        return CFBooleanGetValue(unsafeBitCast(self, to: CFBoolean.self))
    }
    
    override var _cfTypeID: CFTypeID {
        return CFBooleanGetTypeID()
    }
    
    override var objCType: UnsafePointer<Int8> {
        // This must never be fixed to be "B", although that would
        // cause correct old-style archiving when this is unarchived.
        func _objCType(_ staticString: StaticString) -> UnsafePointer<Int8> {
            return UnsafeRawPointer(staticString.utf8Start).assumingMemoryBound(to: Int8.self)
        }
        return _objCType("c")
    }
    
    internal override func _cfNumberType() -> CFNumberType  {
        return kCFNumberCharType
    }
}
