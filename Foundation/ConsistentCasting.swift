// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// Implementation note: This file is included in both the framework and the test bundle, in order for us to be able to test it directly. Once @testable support works for Linux we may be able to use it from the framework instead.

#if TEST_TARGET
#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    #else
    import SwiftFoundation
#endif
#endif

/**
 There are discrepancies in how standard casting behaves for numeric types on Darwin and Linux.
 E.g. casting an `Int8` to `NSNumber` will succeed on Darwin, but will not on Linux.

 This function is intended to provide a consistent behaviour for all platforms (maintain the one from Darwin).

 ## Usage:
 Normally you would cast an object using:
 ```
 if let casted = object as? NewType {
 …
 }
 ```
 with this function, you would instead write:
 ```
 if let casted: NewType = platformConsistentCast(object) {
 …
 }
 ```

 - Note:
 Below is a chart depicting which casting works on:
 * D - Darwin
 * L - Linux

 ```
 y-axis: Type casting from
 x-axis: Type casting to
 ```

 ```
 .--------.----.-----.-----.------.-----.------.-----.------.-----.------.----.---.----.-------.--------.
 |        |Int8|UInt8|Int16|UInt16|Int32|UInt32|Int64|UInt64|Float|Double|Bool|Int|UInt|Decimal|NSNumber|
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |Int8    |DL  |     |     |      |     |      |     |      |     |      |    |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |UInt8   |    |DL   |     |      |     |      |     |      |     |      |    |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |Int16   |    |     |DL   |      |     |      |     |      |     |      |    |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |UInt16  |    |     |     |DL    |     |      |     |      |     |      |    |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |Int32   |    |     |     |      |DL   |      |     |      |     |      |    |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |UInt32  |    |     |     |      |     |DL    |     |      |     |      |    |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |Int64   |    |     |     |      |     |      |DL   |      |     |      |    |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |UInt64  |    |     |     |      |     |      |     |DL    |     |      |    |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |Float   |    |     |     |      |     |      |     |      |DL   |      |    |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |Double  |    |     |     |      |     |      |     |      |     |DL    |    |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |Bool    |    |     |     |      |     |      |     |      |     |      |DL  |   |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |Int     |    |     |     |      |     |      |     |      |     |      |    |DL |    |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |UInt    |    |     |     |      |     |      |     |      |     |      |    |   |DL  |       |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |Decimal |    |     |     |      |     |      |     |      |     |      |    |   |    |DL     |D       |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 |NSNumber|D   |D    |D    |D     |D    |D     |D    |D     |D    |D     |D   |D  |D   |       |DL      |
 :--------+----+-----+-----+------+-----+------+-----+------+-----+------+----+---+----+-------+--------:
 ```

 - Returns: Casted representation of passed object, or `nil` if casting failed.

 - Parameter object: Object to cast.
 */
func platformConsistentCast<T>(_ object: Any) -> T? {
    if let casted = object as? T {
        return casted
    }

    if let safeBridgeable = object as? _PlatformConsistentCasting {
        return safeBridgeable._casted()
    }

    return nil
}

protocol _PlatformConsistentCasting {
    func _casted<T>() -> T?
}

extension NSNumber: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is Int8.Type: return self.int8Value as? T
        case is UInt8.Type: return self.uint8Value as? T
        case is Int16.Type: return self.int16Value as? T
        case is UInt16.Type: return self.uint16Value as? T
        case is Int32.Type: return self.int32Value as? T
        case is UInt32.Type: return self.uint32Value as? T
        case is Int64.Type: return self.int64Value as? T
        case is UInt64.Type: return self.uint64Value as? T
        case is Float.Type: return self.floatValue as? T
        case is Double.Type: return self.doubleValue as? T
        case is Bool.Type: return self.boolValue as? T
        case is Int.Type: return self.intValue as? T
        case is UInt.Type: return self.uintValue as? T
        default: return nil
        }
    }
}

extension Int8: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension UInt8: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension Int16: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension UInt16: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension Int32: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension UInt32: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension Int64: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension UInt64: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension Int: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension UInt: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension Float: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension Double: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension Bool: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSNumber(value: self) as? T
        default: return nil
        }
    }
}

extension Decimal: _PlatformConsistentCasting {
    func _casted<T>() -> T? {
        if let casted = self as? T { return casted }
        switch T.self {
        case is NSNumber.Type: return NSDecimalNumber(decimal: self) as? T
        default: return nil
        }
    }
}

extension CodingKey {
    var nsstringValue: NSString {
        return self.stringValue._bridgeToObjectiveC()
    }
}
