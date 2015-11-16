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
import Darwin
#elseif os(Linux)
import Glibc
#endif

public typealias ObjCBool = Bool

public typealias NSStringEncoding = UInt
public var NSASCIIStringEncoding: UInt { return 1 }
public var NSNEXTSTEPStringEncoding: UInt { return 2 }
public var NSJapaneseEUCStringEncoding: UInt { return 3 }
public var NSUTF8StringEncoding: UInt { return 4 }
public var NSISOLatin1StringEncoding: UInt { return 5 }
public var NSSymbolStringEncoding: UInt { return 6 }
public var NSNonLossyASCIIStringEncoding: UInt { return 7 }
public var NSShiftJISStringEncoding: UInt { return 8 }
public var NSISOLatin2StringEncoding: UInt { return 9 }
public var NSUnicodeStringEncoding: UInt { return 10 }
public var NSWindowsCP1251StringEncoding: UInt { return 11 }
public var NSWindowsCP1252StringEncoding: UInt { return 12 }
public var NSWindowsCP1253StringEncoding: UInt { return 13 }
public var NSWindowsCP1254StringEncoding: UInt { return 14 }
public var NSWindowsCP1250StringEncoding: UInt { return 15 }
public var NSISO2022JPStringEncoding: UInt { return 21 }
public var NSMacOSRomanStringEncoding: UInt { return 30 }
public var NSUTF16StringEncoding: UInt { return NSUnicodeStringEncoding }
public var NSUTF16BigEndianStringEncoding: UInt { return 0x90000100 }
public var NSUTF16LittleEndianStringEncoding: UInt { return 0x94000100 }
public var NSUTF32StringEncoding: UInt { return 0x8c000100 }
public var NSUTF32BigEndianStringEncoding: UInt { return 0x98000100 }
public var NSUTF32LittleEndianStringEncoding: UInt { return 0x9c000100 }

internal class __NSCFType : NSObject {
    private var _cfinfo : Int32
    
    override init() {
        // This is not actually called; _CFRuntimeCreateInstance will initialize _cfinfo
        _cfinfo = 0
    }
    
    override var hash: Int {
        get {
            return Int(CFHash(self))
        }
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if let obj = object {
            return CFEqual(self, obj)
        } else {
            return false
        }
    }
    
    override var description: String {
        get {
            return CFCopyDescription(unsafeBitCast(self, CFTypeRef.self))._swiftObject
        }
    }

    deinit {
        _CFDeinit(self)
    }
}


internal func _CFSwiftGetTypeID(cf: AnyObject) -> CFTypeID {
    return (cf as! NSObject)._cfTypeID
}


internal func _CFSwiftGetHash(cf: AnyObject) -> CFHashCode {
    return CFHashCode((cf as! NSObject).hash)
}


internal func _CFSwiftIsEqual(cf1: AnyObject, cf2: AnyObject) -> Bool {
    return (cf1 as! NSObject).isEqual(cf2)
}

// Ivars in _NSCF* types must be zeroed via an unsafe accessor to avoid deinit of potentially unsafe memory to accces as an object/struct etc since it is stored via a foreign object graph
internal func _CFZeroUnsafeIvars<T>(inout arg: T) {
    withUnsafeMutablePointer(&arg) { (ptr: UnsafeMutablePointer<T>) -> Void in
        bzero(unsafeBitCast(ptr, UnsafeMutablePointer<Void>.self), sizeof(T))
    }
}

internal func __CFSwiftGetBaseClass() -> AnyObject.Type {
    return __NSCFType.self
}

internal func __CFInitializeSwift() {
    
    _CFRuntimeBridgeTypeToClass(CFStringGetTypeID(), unsafeBitCast(_NSCFString.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFArrayGetTypeID(), unsafeBitCast(_NSCFArray.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFDictionaryGetTypeID(), unsafeBitCast(_NSCFDictionary.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFSetGetTypeID(), unsafeBitCast(_NSCFSet.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFNumberGetTypeID(), unsafeBitCast(NSNumber.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFDataGetTypeID(), unsafeBitCast(NSData.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFDateGetTypeID(), unsafeBitCast(NSDate.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFURLGetTypeID(), unsafeBitCast(NSURL.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFCalendarGetTypeID(), unsafeBitCast(NSCalendar.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFLocaleGetTypeID(), unsafeBitCast(NSLocale.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFTimeZoneGetTypeID(), unsafeBitCast(NSTimeZone.self, UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFCharacterSetGetTypeID(), unsafeBitCast(NSMutableCharacterSet.self, UnsafePointer<Void>.self))
    
//    _CFRuntimeBridgeTypeToClass(CFErrorGetTypeID(), unsafeBitCast(NSError.self, UnsafePointer<Void>.self))
//    _CFRuntimeBridgeTypeToClass(CFAttributedStringGetTypeID(), unsafeBitCast(NSMutableAttributedString.self, UnsafePointer<Void>.self))
//    _CFRuntimeBridgeTypeToClass(CFReadStreamGetTypeID(), unsafeBitCast(NSInputStream.self, UnsafePointer<Void>.self))
//    _CFRuntimeBridgeTypeToClass(CFWriteStreamGetTypeID(), unsafeBitCast(NSOutputStream.self, UnsafePointer<Void>.self))
//    _CFRuntimeBridgeTypeToClass(CFRunLoopTimerGetTypeID(), unsafeBitCast(NSTimer.self, UnsafePointer<Void>.self))
    
    __CFSwiftBridge.NSObject.isEqual = _CFSwiftIsEqual
    __CFSwiftBridge.NSObject.hash = _CFSwiftGetHash
    __CFSwiftBridge.NSObject._cfTypeID = _CFSwiftGetTypeID
    
    
    __CFSwiftBridge.NSArray.count = _CFSwiftArrayGetCount
    __CFSwiftBridge.NSArray.objectAtIndex = _CFSwiftArrayGetValueAtIndex
    __CFSwiftBridge.NSArray.getObjects = _CFSwiftArrayGetValues
    
    __CFSwiftBridge.NSMutableArray.addObject = _CFSwiftArrayAppendValue
    __CFSwiftBridge.NSMutableArray.setObject = _CFSwiftArraySetValueAtIndex
    __CFSwiftBridge.NSMutableArray.replaceObjectAtIndex = _CFSwiftArrayReplaceValueAtIndex
    __CFSwiftBridge.NSMutableArray.insertObject = _CFSwiftArrayInsertValueAtIndex
    __CFSwiftBridge.NSMutableArray.exchangeObjectAtIndex = _CFSwiftArrayExchangeValuesAtIndices
    __CFSwiftBridge.NSMutableArray.removeObjectAtIndex = _CFSwiftArrayRemoveValueAtIndex
    __CFSwiftBridge.NSMutableArray.removeAllObjects = _CFSwiftArrayRemoveAllValues
    __CFSwiftBridge.NSMutableArray.replaceObjectsInRange = _CFSwiftArrayReplaceValues
    
    __CFSwiftBridge.NSDictionary.count = _CFSwiftDictionaryGetCount
    __CFSwiftBridge.NSDictionary.countForKey = _CFSwiftDictionaryGetCountOfKey
    __CFSwiftBridge.NSDictionary.containsKey = _CFSwiftDictionaryContainsKey
    __CFSwiftBridge.NSDictionary.objectForKey = _CFSwiftDictionaryGetValue
    __CFSwiftBridge.NSDictionary._getValueIfPresent = _CFSwiftDictionaryGetValueIfPresent
    __CFSwiftBridge.NSDictionary.containsObject = _CFSwiftDictionaryContainsValue
    __CFSwiftBridge.NSDictionary.countForObject = _CFSwiftDictionaryGetCountOfValue
    __CFSwiftBridge.NSDictionary.getObjects = _CFSwiftDictionaryGetKeysAndValues
    __CFSwiftBridge.NSDictionary.__apply = _CFSwiftDictionaryApplyFunction
    
    __CFSwiftBridge.NSMutableDictionary.__addObject = _CFSwiftDictionaryAddValue
    __CFSwiftBridge.NSMutableDictionary.replaceObject = _CFSwiftDictionaryReplaceValue
    __CFSwiftBridge.NSMutableDictionary.__setObject = _CFSwiftDictionarySetValue
    __CFSwiftBridge.NSMutableDictionary.removeObjectForKey = _CFSwiftDictionaryRemoveValue
    __CFSwiftBridge.NSMutableDictionary.removeAllObjects = _CFSwiftDictionaryRemoveAllValues
    
    __CFSwiftBridge.NSString._createSubstringWithRange = _CFSwiftStringCreateWithSubstring
    __CFSwiftBridge.NSString.copy = _CFSwiftStringCreateCopy
    __CFSwiftBridge.NSString.mutableCopy = _CFSwiftStringCreateMutableCopy
    __CFSwiftBridge.NSString.length = _CFSwiftStringGetLength
    __CFSwiftBridge.NSString.characterAtIndex = _CFSwiftStringGetCharacterAtIndex
    __CFSwiftBridge.NSString.getCharacters = _CFSwiftStringGetCharacters
    __CFSwiftBridge.NSString.__getBytes = _CFSwiftStringGetBytes
    __CFSwiftBridge.NSString._fastCStringContents = _CFSwiftStringFastCStringContents
    __CFSwiftBridge.NSString._fastCharacterContents = _CFSwiftStringFastContents
    __CFSwiftBridge.NSString._getCString = _CFSwiftStringGetCString
    
    __CFSwiftBridge.NSMutableString.insertString = _CFSwiftStringInsert
    __CFSwiftBridge.NSMutableString.deleteCharactersInRange = _CFSwiftStringDelete
    __CFSwiftBridge.NSMutableString.replaceCharactersInRange = _CFSwiftStringReplace
    __CFSwiftBridge.NSMutableString.setString = _CFSwiftStringReplaceAll
    __CFSwiftBridge.NSMutableString.appendString = _CFSwiftStringAppend
    __CFSwiftBridge.NSMutableString.appendCharacters = _CFSwiftStringAppendCharacters
    __CFSwiftBridge.NSMutableString._cfAppendCString = _CFSwiftStringAppendCString
}

#if os(Linux)
/// This is ripped from the standard library; technically it should be
/// split out into two protocols. _ObjectiveCBridgeable causes extra thunks
/// to be emitted during subclassing to properly convert to objc bridgable
/// types; however this is being overloaded for it's meaning to be used as
/// a conversion point between struct types such as String and Dictionary
/// to object types such as NSDictionary; which in this case is a Swift class
/// type. So ideally the standard library should provide a _ImplicitConvertable
/// protocol which _ObjectiveCBridgeable derives from so that the classes that
/// adopt _ObjectiveCBridgeable get the subclassing thunk behavior and the
/// classes that adopt _ImplicitConvertable just get the implicit conversion
/// behavior and avoid the thunk generation.
public protocol _ObjectiveCBridgeable {
    typealias _ObjectiveCType : AnyObject
    
    /// Return true iff instances of `Self` can be converted to
    /// Objective-C.  Even if this method returns `true`, A given
    /// instance of `Self._ObjectiveCType` may, or may not, convert
    /// successfully to `Self`; for example, an `NSArray` will only
    /// convert successfully to `[String]` if it contains only
    /// `NSString`s.
    @warn_unused_result
    static func _isBridgedToObjectiveC() -> Bool
    
    // _getObjectiveCType is a workaround: right now protocol witness
    // tables don't include associated types, so we can not find
    // '_ObjectiveCType.self' from them.
    
    /// Must return `_ObjectiveCType.self`.
    @warn_unused_result
    static func _getObjectiveCType() -> Any.Type
    
    /// Convert `self` to Objective-C.
    @warn_unused_result
    func _bridgeToObjectiveC() -> _ObjectiveCType
    
    /// Bridge from an Objective-C object of the bridged class type to a
    /// value of the Self type.
    ///
    /// This bridging operation is used for forced downcasting (e.g.,
    /// via as), and may defer complete checking until later. For
    /// example, when bridging from `NSArray` to `Array<Element>`, we can defer
    /// the checking for the individual elements of the array.
    ///
    /// - parameter result: The location where the result is written. The optional
    ///   will always contain a value.
    static func _forceBridgeFromObjectiveC(
        source: _ObjectiveCType,
        inout result: Self?
    )
    
    /// Try to bridge from an Objective-C object of the bridged class
    /// type to a value of the Self type.
    ///
    /// This conditional bridging operation is used for conditional
    /// downcasting (e.g., via as?) and therefore must perform a
    /// complete conversion to the value type; it cannot defer checking
    /// to a later time.
    ///
    /// - parameter result: The location where the result is written.
    ///
    /// - Returns: `true` if bridging succeeded, `false` otherwise. This redundant
    ///   information is provided for the convenience of the runtime's `dynamic_cast`
    ///   implementation, so that it need not look into the optional representation
    ///   to determine success.
    static func _conditionallyBridgeFromObjectiveC(
        source: _ObjectiveCType,
        inout result: Self?
        ) -> Bool
}
#endif

protocol _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject
}

internal func _NSObjectRepresentableBridge(value: Any) -> NSObject {
    if let obj = value as? _NSObjectRepresentable {
        return obj._nsObjectRepresentation()
    } else if let str = value as? String {
        return str._nsObjectRepresentation()
    } else if let obj = value as? NSObject {
        return obj
    }
    fatalError("Unable to convert value of type \(value.dynamicType)")
}

extension Array : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObjectiveC()
    }
}

extension Dictionary : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObjectiveC()
    }
}


extension String : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObjectiveC()
    }
}

extension Set : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObjectiveC()
    }
}

#if os(Linux)
public func === (lhs: AnyClass, rhs: AnyClass) -> Bool {
    return unsafeBitCast(lhs, UnsafePointer<Void>.self) == unsafeBitCast(rhs, UnsafePointer<Void>.self)
}
#endif

/// Swift extensions for common operations in Foundation that use unsafe things...

extension UnsafeMutablePointer {
    internal init<T: AnyObject>(retained value: T) {
        self.init(Unmanaged<T>.passRetained(value).toOpaque())
    }
    
    internal init<T: AnyObject>(unretained value: T) {
        self.init(Unmanaged<T>.passUnretained(value).toOpaque())
    }
    
    internal func array(count: Int) -> [Memory] {
        let buffer = UnsafeBufferPointer<Memory>(start: self, count: count)
        return Array<Memory>(buffer)
    }
}

extension Unmanaged {
    internal static func fromOpaque(value: UnsafeMutablePointer<Void>) -> Unmanaged<Instance> {
        return self.fromOpaque(COpaquePointer(value))
    }
    
    internal static func fromOptionalOpaque(value: UnsafePointer<Void>) -> Unmanaged<Instance>? {
        if value != nil {
            return self.fromOpaque(COpaquePointer(value))
        } else {
            return nil
        }
    }
}

public protocol Bridgeable {
    typealias BridgeType
    func bridge() -> BridgeType
}

