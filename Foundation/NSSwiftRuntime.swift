// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

// Re-export Darwin and Glibc by importing Foundation
// This mimics the behavior of the swift sdk overlay on Darwin
#if os(OSX) || os(iOS)
@_exported import Darwin
#elseif os(Linux)
@_exported import Glibc
#endif

public typealias ObjCBool = Bool

internal class __NSCFType : NSObject {
    private var _cfinfo : Int32
    
    override init() {
        // This is not actually called; _CFRuntimeCreateInstance will initialize _cfinfo
        _cfinfo = 0
    }
    
    override var hash: Int {
        return Int(bitPattern: CFHash(self))
    }
    
    override func isEqual(_ object: AnyObject?) -> Bool {
        if let obj = object {
            return CFEqual(self, obj)
        } else {
            return false
        }
    }
    
    override var description: String {
        return CFCopyDescription(unsafeBitCast(self, to: CFTypeRef.self))._swiftObject
    }

    deinit {
        _CFDeinit(self)
    }
}


internal func _CFSwiftGetTypeID(_ cf: AnyObject) -> CFTypeID {
    return (cf as! NSObject)._cfTypeID
}


internal func _CFSwiftGetHash(_ cf: AnyObject) -> CFHashCode {
    return CFHashCode(bitPattern: (cf as! NSObject).hash)
}


internal func _CFSwiftIsEqual(_ cf1: AnyObject, cf2: AnyObject) -> Bool {
    return (cf1 as! NSObject).isEqual(cf2)
}

// Ivars in _NSCF* types must be zeroed via an unsafe accessor to avoid deinit of potentially unsafe memory to accces as an object/struct etc since it is stored via a foreign object graph
internal func _CFZeroUnsafeIvars<T>(_ arg: inout T) {
    withUnsafeMutablePointer(&arg) { (ptr: UnsafeMutablePointer<T>) -> Void in
        bzero(unsafeBitCast(ptr, to: UnsafeMutablePointer<Void>.self), sizeof(T.self))
    }
}

internal func __CFSwiftGetBaseClass() -> AnyObject.Type {
    return __NSCFType.self
}

internal func __CFInitializeSwift() {
    
    _CFRuntimeBridgeTypeToClass(CFStringGetTypeID(), unsafeBitCast(_NSCFString.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFArrayGetTypeID(), unsafeBitCast(_NSCFArray.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFDictionaryGetTypeID(), unsafeBitCast(_NSCFDictionary.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFSetGetTypeID(), unsafeBitCast(_NSCFSet.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFNumberGetTypeID(), unsafeBitCast(NSNumber.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFDataGetTypeID(), unsafeBitCast(NSData.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFDateGetTypeID(), unsafeBitCast(NSDate.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFURLGetTypeID(), unsafeBitCast(NSURL.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFCalendarGetTypeID(), unsafeBitCast(Calendar.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFLocaleGetTypeID(), unsafeBitCast(Locale.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFTimeZoneGetTypeID(), unsafeBitCast(TimeZone.self, to: UnsafePointer<Void>.self))
    _CFRuntimeBridgeTypeToClass(CFCharacterSetGetTypeID(), unsafeBitCast(_NSCFCharacterSet.self, to: UnsafePointer<Void>.self))
    
//    _CFRuntimeBridgeTypeToClass(CFErrorGetTypeID(), unsafeBitCast(NSError.self, UnsafePointer<Void>.self))
//    _CFRuntimeBridgeTypeToClass(CFAttributedStringGetTypeID(), unsafeBitCast(NSMutableAttributedString.self, UnsafePointer<Void>.self))
//    _CFRuntimeBridgeTypeToClass(CFReadStreamGetTypeID(), unsafeBitCast(NSInputStream.self, UnsafePointer<Void>.self))
//    _CFRuntimeBridgeTypeToClass(CFWriteStreamGetTypeID(), unsafeBitCast(NSOutputStream.self, UnsafePointer<Void>.self))
   _CFRuntimeBridgeTypeToClass(CFRunLoopTimerGetTypeID(), unsafeBitCast(Timer.self, to: UnsafePointer<Void>.self))
    
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
    __CFSwiftBridge.NSDictionary.getObjects = _CFSwiftDictionaryGetValuesAndKeys
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
    __CFSwiftBridge.NSString._encodingCantBeStoredInEightBitCFString = _CFSwiftStringIsUnicode
    
    __CFSwiftBridge.NSMutableString.insertString = _CFSwiftStringInsert
    __CFSwiftBridge.NSMutableString.deleteCharactersInRange = _CFSwiftStringDelete
    __CFSwiftBridge.NSMutableString.replaceCharactersInRange = _CFSwiftStringReplace
    __CFSwiftBridge.NSMutableString.setString = _CFSwiftStringReplaceAll
    __CFSwiftBridge.NSMutableString.appendString = _CFSwiftStringAppend
    __CFSwiftBridge.NSMutableString.appendCharacters = _CFSwiftStringAppendCharacters
    __CFSwiftBridge.NSMutableString._cfAppendCString = _CFSwiftStringAppendCString
    
    __CFSwiftBridge.NSXMLParser.currentParser = _NSXMLParserCurrentParser
    __CFSwiftBridge.NSXMLParser._xmlExternalEntityWithURL = _NSXMLParserExternalEntityWithURL
    __CFSwiftBridge.NSXMLParser.getContext = _NSXMLParserGetContext
    __CFSwiftBridge.NSXMLParser.internalSubset = _NSXMLParserInternalSubset
    __CFSwiftBridge.NSXMLParser.isStandalone = _NSXMLParserIsStandalone
    __CFSwiftBridge.NSXMLParser.hasInternalSubset = _NSXMLParserHasInternalSubset
    __CFSwiftBridge.NSXMLParser.hasExternalSubset = _NSXMLParserHasExternalSubset
    __CFSwiftBridge.NSXMLParser.getEntity = _NSXMLParserGetEntity
    __CFSwiftBridge.NSXMLParser.notationDecl = _NSXMLParserNotationDecl
    __CFSwiftBridge.NSXMLParser.attributeDecl = _NSXMLParserAttributeDecl
    __CFSwiftBridge.NSXMLParser.elementDecl = _NSXMLParserElementDecl
    __CFSwiftBridge.NSXMLParser.unparsedEntityDecl = _NSXMLParserUnparsedEntityDecl
    __CFSwiftBridge.NSXMLParser.startDocument = _NSXMLParserStartDocument
    __CFSwiftBridge.NSXMLParser.endDocument = _NSXMLParserEndDocument
    __CFSwiftBridge.NSXMLParser.startElementNs = _NSXMLParserStartElementNs
    __CFSwiftBridge.NSXMLParser.endElementNs = _NSXMLParserEndElementNs
    __CFSwiftBridge.NSXMLParser.characters = _NSXMLParserCharacters
    __CFSwiftBridge.NSXMLParser.processingInstruction = _NSXMLParserProcessingInstruction
    __CFSwiftBridge.NSXMLParser.cdataBlock = _NSXMLParserCdataBlock
    __CFSwiftBridge.NSXMLParser.comment = _NSXMLParserComment
    __CFSwiftBridge.NSXMLParser.externalSubset = _NSXMLParserExternalSubset
    
    __CFSwiftBridge.NSRunLoop._new = _NSRunLoopNew
    
    __CFSwiftBridge.NSCharacterSet._expandedCFCharacterSet = _CFSwiftCharacterSetExpandedCFCharacterSet
    __CFSwiftBridge.NSCharacterSet._retainedBitmapRepresentation = _CFSwiftCharacterSetRetainedBitmapRepresentation
    __CFSwiftBridge.NSCharacterSet.characterIsMember = _CFSwiftCharacterSetCharacterIsMember
    __CFSwiftBridge.NSCharacterSet.mutableCopy = _CFSwiftCharacterSetMutableCopy
    __CFSwiftBridge.NSCharacterSet.longCharacterIsMember = _CFSwiftCharacterSetLongCharacterIsMember
    __CFSwiftBridge.NSCharacterSet.hasMemberInPlane = _CFSwiftCharacterSetHasMemberInPlane
    __CFSwiftBridge.NSCharacterSet.invertedSet = _CFSwiftCharacterSetInverted
    
    __CFDefaultEightBitStringEncoding = UInt32(kCFStringEncodingUTF8)
}

public protocol _ObjectTypeBridgeable {
    associatedtype _ObjectType : AnyObject
    
    /// Convert `self` to an Object type
    func _bridgeToObject() -> _ObjectType
    
    /// Bridge from an object of the bridged class type to a value of 
    /// the Self type.
    ///
    /// This bridging operation is used for forced downcasting (e.g.,
    /// via as), and may defer complete checking until later. For
    /// example, when bridging from `NSArray` to `Array<Element>`, we can defer
    /// the checking for the individual elements of the array.
    ///
    /// - parameter result: The location where the result is written. The optional
    ///   will always contain a value.
    static func _forceBridgeFromObject(
        _ source: _ObjectType,
        result: inout Self?
    )
    
    /// Try to bridge from an object of the bridged class type to a value of 
    /// the Self type.
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
    static func _conditionallyBridgeFromObject(
        _ source: _ObjectType,
        result: inout Self?
    ) -> Bool
}

protocol _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject
}

internal func _NSObjectRepresentableBridge(_ value: Any) -> NSObject {
    if let obj = value as? _NSObjectRepresentable {
        return obj._nsObjectRepresentation()
    } else if let str = value as? String {
        return str._nsObjectRepresentation()
    } else if let obj = value as? NSObject {
        return obj
    } else if let obj = value as? Int {
        return obj._bridgeToObject()
    } else if let obj = value as? UInt {
        return obj._bridgeToObject()
    } else if let obj = value as? Float {
        return obj._bridgeToObject()
    } else if let obj = value as? Double {
        return obj._bridgeToObject()
    } else if let obj = value as? Bool {
        return obj._bridgeToObject()
    }
    fatalError("Unable to convert value of type \(value.dynamicType)")
}

extension Array : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObject()
    }
}

extension Dictionary : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObject()
    }
}


extension String : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObject()
    }
}

extension Set : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObject()
    }
}

extension Int : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObject()
    }
}

extension UInt : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObject()
    }
}

extension Float : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObject()
    }
}

extension Double : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObject()
    }
}

extension Bool : _NSObjectRepresentable {
    func _nsObjectRepresentation() -> NSObject {
        return _bridgeToObject()
    }
}

public func === (lhs: AnyClass, rhs: AnyClass) -> Bool {
    return unsafeBitCast(lhs, to: UnsafePointer<Void>.self) == unsafeBitCast(rhs, to: UnsafePointer<Void>.self)
}

/// Swift extensions for common operations in Foundation that use unsafe things...


extension NSObject {
    static func unretainedReference<T, R: NSObject>(_ value: UnsafePointer<T>) -> R {
        return unsafeBitCast(value, to: R.self)
    }
    
    static func unretainedReference<T, R: NSObject>(_ value: UnsafeMutablePointer<T>) -> R {
        return unretainedReference(UnsafePointer<T>(value))
    }
    
    static func releaseReference<T>(_ value: UnsafePointer<T>) {
        _CFSwiftRelease(UnsafeMutablePointer<Void>(value))
    }
    
    static func releaseReference<T>(_ value: UnsafeMutablePointer<T>) {
        _CFSwiftRelease(value)
    }

    func withRetainedReference<T, R>(_ work: @noescape (UnsafePointer<T>) -> R) -> R {
        return work(UnsafePointer<T>(_CFSwiftRetain(unsafeBitCast(self, to: UnsafeMutablePointer<Void>.self))!))
    }
    
    func withRetainedReference<T, R>(_ work: @noescape (UnsafeMutablePointer<T>) -> R) -> R {
        return work(UnsafeMutablePointer<T>(_CFSwiftRetain(unsafeBitCast(self, to: UnsafeMutablePointer<Void>.self))!))
    }
    
    func withUnretainedReference<T, R>(_ work: @noescape (UnsafePointer<T>) -> R) -> R {
        return work(unsafeBitCast(self, to: UnsafePointer<T>.self))
    }
    
    func withUnretainedReference<T, R>(_ work: @noescape (UnsafeMutablePointer<T>) -> R) -> R {
        return work(unsafeBitCast(self, to: UnsafeMutablePointer<T>.self))
    }
}

extension Array {
    internal mutating func withUnsafeMutablePointerOrAllocation<R>(_ count: Int, fastpath: UnsafeMutablePointer<Element>? = nil, body: @noescape (UnsafeMutablePointer<Element>) -> R) -> R {
        if let fastpath = fastpath {
            return body(fastpath)
        } else if self.count > count {
            let buffer = UnsafeMutablePointer<Element>(allocatingCapacity: count)
            let res = body(buffer)
            buffer.deinitialize(count: count)
            buffer.deallocateCapacity(count)
            return res
        } else {
            return withUnsafeMutableBufferPointer() { (bufferPtr: inout UnsafeMutableBufferPointer<Element>) -> R in
                return body(bufferPtr.baseAddress!)
            }
        }
    }
}

public protocol Bridgeable {
    associatedtype BridgeType
    func bridge() -> BridgeType
}

#if os(OSX) || os(iOS)
    internal typealias _DarwinCompatibleBoolean = DarwinBoolean
#else
    internal typealias _DarwinCompatibleBoolean = Bool
#endif
