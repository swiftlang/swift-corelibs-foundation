//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import CoreFoundation

#if canImport(ObjectiveC)
import ObjectiveC
#endif

public protocol _StructBridgeable {
    func _bridgeToAny() -> Any
}

fileprivate protocol Unwrappable {
    func unwrap() -> Any?
}

extension Optional: Unwrappable {
    func unwrap() -> Any? {
        return self
    }
}

/// - Note: This does not exist currently on Darwin but it is the inverse correlation to the bridge types such that a 
/// reference type can be converted via a callout to a conversion method.
public protocol _StructTypeBridgeable : _StructBridgeable {
    associatedtype _StructType
    
    func _bridgeToSwift() -> _StructType
}

// Default adoption of the type specific variants to the Any variant
extension _ObjectiveCBridgeable {
    public func _bridgeToAnyObject() -> AnyObject {
        return _bridgeToObjectiveC()
    }
}

extension _StructTypeBridgeable {
    public func _bridgeToAny() -> Any {
        return _bridgeToSwift()
    }
}

// slated for removal, these are the swift-corelibs-only variant of the _ObjectiveCBridgeable
internal protocol _CFBridgeable {
    associatedtype CFType
    var _cfObject: CFType { get }
}

internal protocol _SwiftBridgeable {
    associatedtype SwiftType
    var _swiftObject: SwiftType { get }
}

internal protocol _NSBridgeable {
    associatedtype NSType
    var _nsObject: NSType { get }
}


#if !canImport(ObjectiveC)
// The _NSSwiftValue protocol is in the stdlib, and only available on platforms without ObjC.
extension _SwiftValue: _NSSwiftValue {}
#endif

/// - Note: This is an internal boxing value for containing abstract structures
internal final class _SwiftValue : NSObject, NSCopying {
    public private(set) var value: Any
    
    static func fetch(_ object: AnyObject?) -> Any? {
        if let obj = object {
            let value = fetch(nonOptional: obj)
            if let wrapper = value as? Unwrappable, wrapper.unwrap() == nil {
                return nil
            } else {
                return value
            }
        }
        return nil
    }
    
    #if canImport(ObjectiveC)
    private static var _objCNSNullClassStorage: Any.Type?
    private static var objCNSNullClass: Any.Type? {
        if let type = _objCNSNullClassStorage {
            return type
        }
        
        let name = "NSNull"
        let maybeType = name.withCString { cString in
            return objc_getClass(cString)
        }
        
        if let type = maybeType as? Any.Type {
            _objCNSNullClassStorage = type
            return type
        } else {
            return nil
        }
    }
    
    private static var _swiftStdlibSwiftValueClassStorage: Any.Type?
    private static var swiftStdlibSwiftValueClass: Any.Type? {
        if let type = _swiftStdlibSwiftValueClassStorage {
            return type
        }
        
        let name = "_SwiftValue"
        let maybeType = name.withCString { cString in
            return objc_getClass(cString)
        }
        
        if let type = maybeType as? Any.Type {
            _swiftStdlibSwiftValueClassStorage = type
            return type
        } else {
            return nil
        }
    }
    
    #endif
    
    static func fetch(nonOptional object: AnyObject) -> Any {
        #if canImport(ObjectiveC)
        // You can pass the result of a `as AnyObject` expression to this method. This can have one of three results on Darwin:
        // - It's a SwiftFoundation type. Bridging will take care of it below.
        // - It's nil. The compiler is hardcoded to return [NSNull null] for nils.
        // - It's some other Swift type. The compiler will box it in a native _SwiftValue.
        // Case 1 is handled below.
        // Case 2 is handled here:
        if type(of: object as Any) == objCNSNullClass {
            return Optional<Any>.none as Any
        }
        // Case 3 is handled here:
        if type(of: object as Any) == swiftStdlibSwiftValueClass {
            return object
            // Since this returns Any, the object is casted almost immediately — e.g.:
            //   _SwiftValue.fetch(x) as SomeStruct
            // which will immediately unbox the native box. For callers, it will be exactly
            // as if we returned the unboxed value directly.
        }
        
        // On Linux, case 2 is handled by the stdlib bridging machinery, and case 3 can't happen —
        // the compiler will produce SwiftFoundation._SwiftValue boxes rather than ObjC ones.
        #endif
        
        if object === kCFBooleanTrue {
            return true
        } else if object === kCFBooleanFalse {
            return false
        } else if let container = object as? _SwiftValue {
            return container.value
        } else if let val = object as? _StructBridgeable {
            return val._bridgeToAny()
        } else {
            return object
        }
    }
    
    static func store(optional value: Any?) -> NSObject? {
        if let val = value {
            return store(val)
        }
        return nil
    }
    
    static func store(_ value: Any?) -> NSObject? {
        if let val = value {
            return store(val)
        }
        return nil
    }
    
    static func store(_ value: Any) -> NSObject {
        if let val = value as? NSObject {
            return val
        } else if let opt = value as? Unwrappable, opt.unwrap() == nil {
            return NSNull()
        } else {
            #if canImport(ObjectiveC)
                // On Darwin, this can be a native (ObjC) _SwiftValue.
                let boxed = (value as AnyObject)
                if !(boxed is NSObject) {
                    return _SwiftValue(value) // Do not emit native boxes — wrap them in Swift Foundation boxes instead.
                } else {
                    return boxed as! NSObject
                }
            #else
                return (value as AnyObject) as! NSObject
            #endif
        }
    }
    
    init(_ value: Any) {
        self.value = value
    }
    
    override var hash: Int {
        if let hashable = value as? AnyHashable {
            return hashable.hashValue
        }
        return ObjectIdentifier(self).hashValue
    }
    
    override func isEqual(_ value: Any?) -> Bool {
        switch value {
        case let other as _SwiftValue:
            guard let left = other.value as? AnyHashable,
                let right = self.value as? AnyHashable else { return self === other }
            
            return left == right
        case let other as AnyHashable:
            guard let hashable = self.value as? AnyHashable else { return false }
            return other == hashable
        default:
            return false
        }
    }
    
    public func copy(with zone: NSZone?) -> Any {
        return _SwiftValue(value)
    }
    
    public static let null: AnyObject = NSNull()
}
