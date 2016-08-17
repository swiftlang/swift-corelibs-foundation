// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

extension NSCoder {
    /*!
     Describes the action an NSCoder should take when it encounters decode failures (e.g. corrupt data) for non-TopLevel decodes. Darwin platfrom supports exceptions here, and there may be other approaches supported in the future, so its included for completeness.
     */
    public enum DecodingFailurePolicy : Int {
        case setErrorAndReturn
    }
}


public protocol NSCoding {
    func encode(with aCoder: NSCoder)
    init?(coder aDecoder: NSCoder)
}

public protocol NSSecureCoding : NSCoding {
    static var supportsSecureCoding: Bool { get }
}

open class NSCoder : NSObject {
    internal var _pendingBuffers = Array<(UnsafeMutableRawPointer, Int)>()
    
    deinit {
        for buffer in _pendingBuffers {
            // Cannot deinitialize a pointer to unknown type.
            buffer.0.deallocate(bytes: buffer.1, alignedTo: MemoryLayout<Int>.alignment)
        }
    }
    
    open func encodeValue(ofObjCType type: UnsafePointer<Int8>, at addr: UnsafeRawPointer) {
        NSRequiresConcreteImplementation()
    }
    
    open func encode(_ data: Data) {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeValue(ofObjCType type: UnsafePointer<Int8>, at data: UnsafeMutableRawPointer) {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeData() -> Data? {
        NSRequiresConcreteImplementation()
    }
    
    open func version(forClassName className: String) -> Int {
        NSRequiresConcreteImplementation()
    }

    open func decodeObject<DecodedObjectType: NSCoding>(of cls: DecodedObjectType.Type, forKey key: String) -> DecodedObjectType? where DecodedObjectType: NSObject {
        NSUnimplemented()
    }
   
    /*!
     @method decodeObjectOfClasses:forKey:
        @abstract Decodes an object for the key, restricted to the specified classes.
        @param classes An array of the expected classes.
        @param key The code key.
        @return The decoded object.
        @discussion This function signature differs from Foundation OS X in that
        classes is an array of Classes, not a NSSet. This is because AnyClass cannot
        be casted to NSObject, nor is it Hashable.
     */
    open func decodeObject(of classes: [AnyClass]?, forKey key: String) -> Any? {
        NSUnimplemented()
    }
    
    open func decodeTopLevelObject() throws -> Any? {
        NSUnimplemented()
    }
    
    open func decodeTopLevelObject(forKey key: String) throws -> Any? {
        NSUnimplemented()
    }
    
    open func decodeTopLevelObject<DecodedObjectType: NSCoding>(of cls: DecodedObjectType.Type, forKey key: String) throws -> DecodedObjectType? where DecodedObjectType: NSObject {
        NSUnimplemented()
    }
    
    /*!
     @method decodeTopLevelObjectOfClasses:
     @abstract Decodes an top-level object for the key, restricted to the specified classes.
     @param classes An array of the expected classes.
     @param key The code key.
     @return The decoded object.
     @discussion This function signature differs from Foundation OS X in that
     classes is an array of Classes, not a NSSet. This is because AnyClass cannot
     be casted to NSObject, nor is it Hashable.
     */
    open func decodeTopLevelObject(of classes: [AnyClass], forKey key: String) throws -> Any? {
        NSUnimplemented()
    }
    
    open func encode(_ object: Any?) {
        var object = object
        withUnsafePointer(to: &object) { (ptr: UnsafePointer<Any?>) -> Void in
            encodeValue(ofObjCType: "@", at: unsafeBitCast(ptr, to: UnsafeRawPointer.self))
        }
    }
    
    open func encodeRootObject(_ rootObject: Any) {
        encode(rootObject)
    }
    
    open func encodeBycopyObject(_ anObject: Any?) {
        encode(anObject)
    }
    
    open func encodeByrefObject(_ anObject: Any?) {
        encode(anObject)
    }
    
    open func encodeConditionalObject(_ object: Any?) {
        encode(object)
    }
    
    open func encodeArray(ofObjCType type: UnsafePointer<Int8>, count: Int, at array: UnsafeRawPointer) {
        encodeValue(ofObjCType: "[\(count)\(String(cString: type))]", at: array)
    }
    
    open func encodeBytes(_ byteaddr: UnsafeRawPointer?, length: Int) {
        var newLength = UInt32(length)
        withUnsafePointer(to: &newLength) { (ptr: UnsafePointer<UInt32>) -> Void in
            encodeValue(ofObjCType: "I", at: ptr)
        }
        var empty: [Int8] = []
        withUnsafePointer(to: &empty) {
            encodeArray(ofObjCType: "c", count: length, at: byteaddr ?? UnsafeRawPointer($0))
        }
    }
    
    open func decodeObject() -> Any? {
        if self.error != nil {
            return nil
        }
        
        var obj: Any? = nil
        withUnsafeMutablePointer(to: &obj) { (ptr: UnsafeMutablePointer<Any?>) -> Void in
            decodeValue(ofObjCType: "@", at: unsafeBitCast(ptr, to: UnsafeMutableRawPointer.self))
        }
        return obj
    }
    
    open func decodeArray(ofObjCType itemType: UnsafePointer<Int8>, count: Int, at array: UnsafeMutableRawPointer) {
        decodeValue(ofObjCType: "[\(count)\(String(cString: itemType))]", at: array)
    }
   
    /*
    // TODO: This is disabled, as functions which return unsafe interior pointers are inherently unsafe when we have no autorelease pool. 
    open func decodeBytes(withReturnedLength lengthp: UnsafeMutablePointer<Int>) -> UnsafeMutableRawPointer? {
        var length: UInt32 = 0
        withUnsafeMutablePointer(to: &length) { (ptr: UnsafeMutablePointer<UInt32>) -> Void in
            decodeValue(ofObjCType: "I", at: unsafeBitCast(ptr, to: UnsafeMutableRawPointer.self))
        }
        // we cannot autorelease here so instead the pending buffers will manage the lifespan of the returned data... this is wasteful but good enough...
        let result = UnsafeMutableRawPointer.allocate(bytes: Int(length), alignedTo: MemoryLayout<Int>.alignment)
        decodeValue(ofObjCType: "c", at: result)
        lengthp.pointee = Int(length)
        _pendingBuffers.append((result, Int(length)))
        return result
    }
    */
    
    open func encodePropertyList(_ aPropertyList: Any) {
        NSUnimplemented()
    }
    
    open func decodePropertyList() -> Any? {
        NSUnimplemented()
    }
    
    open var systemVersion: UInt32 {
        return 1000
    }
    
    open var allowsKeyedCoding: Bool {
        return false
    }
    
    open func encode(_ objv: Any?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func encodeConditionalObject(_ objv: Any?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func encode(_ boolv: Bool, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func encode(_ intv: Int32, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func encode(_ intv: Int64, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func encode(_ realv: Float, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func encode(_ realv: Double, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func encodeBytes(_ bytesp: UnsafePointer<UInt8>?, length lenv: Int, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func containsValue(forKey key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeObject(forKey key: String) -> Any? {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeBool(forKey key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    // NOTE: this equivalent to the decodeIntForKey: in Objective-C implementation
    open func decodeCInt(forKey key: String) -> Int32 {
        
        NSRequiresConcreteImplementation()
    }
    
    open func decodeInt32(forKey key: String) -> Int32 {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeInt64(forKey key: String) -> Int64 {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeFloat(forKey key: String) -> Float {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeDouble(forKey key: String) -> Double {
        NSRequiresConcreteImplementation()
    }
    
    // TODO: This is disabled, as functions which return unsafe interior pointers are inherently unsafe when we have no autorelease pool. 
    /*
    open func decodeBytes(forKey key: String, returnedLength lengthp: UnsafeMutablePointer<Int>?) -> UnsafePointer<UInt8>? { // returned bytes immutable!
        NSRequiresConcreteImplementation()
    }
    */
    /// - experimental: This method does not exist in the Darwin Foundation.
    open func withDecodedUnsafeBufferPointer<ResultType>(forKey key: String, body: (UnsafeBufferPointer<UInt8>?) throws -> ResultType) rethrows -> ResultType {
        NSRequiresConcreteImplementation()
    }

    open func encode(_ intv: Int, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeInteger(forKey key: String) -> Int {
        NSRequiresConcreteImplementation()
    }
    
    open var requiresSecureCoding: Bool {
        return false
    }
    
    open func decodePropertyListForKey(_ key: String) -> Any? {
        NSUnimplemented()
    }
    
    /*!
     @property allowedClasses
     @abstract The set of coded classes allowed for secure coding. (read-only)
     @discussion This property type differs from Foundation OS X in that
     classes is an array of Classes, not a Set. This is because AnyClass is not
     hashable.
     */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    open var allowedClasses: [AnyClass]? {
        NSUnimplemented()
    }
    
    open func failWithError(_ error: Error) {
        NSUnimplemented()
        // NOTE: disabled for now due to bridging uncertainty
        // if let debugDescription = error.userInfo["NSDebugDescription"] {
        //    NSLog("*** NSKeyedUnarchiver.init: \(debugDescription)")
        // } else {
        //    NSLog("*** NSKeyedUnarchiver.init: decoding error")
        // }
    }
    
    open var decodingFailurePolicy: NSCoder.DecodingFailurePolicy {
        return .setErrorAndReturn
    }
    open var error: Error? {
        NSRequiresConcreteImplementation()
    }
    
    internal func _decodeArrayOfObjectsForKey(_ key: String) -> [Any] {
        NSRequiresConcreteImplementation()
    }
    
    internal func _decodePropertyListForKey(_ key: String) -> Any {
        NSRequiresConcreteImplementation()
    }
}
