// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public protocol NSCoding {
    func encode(with aCoder: NSCoder)
    init?(coder aDecoder: NSCoder)
}

public protocol NSSecureCoding : NSCoding {
    static func supportsSecureCoding() -> Bool
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
    
    open func encodeDataObject(_ data: Data) {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeValue(ofObjCType type: UnsafePointer<Int8>, at data: UnsafeMutableRawPointer) {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeDataObject() -> Data? {
        NSRequiresConcreteImplementation()
    }
    
    open func version(forClassName className: String) -> Int {
        NSRequiresConcreteImplementation()
    }

    open func decodeObjectOfClass<DecodedObjectType : NSCoding where DecodedObjectType : NSObject>(_ cls: DecodedObjectType.Type, forKey key: String) -> DecodedObjectType? {
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
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    open func decodeObjectOfClasses(_ classes: [AnyClass], forKey key: String) -> AnyObject? {
        NSUnimplemented()
    }
    
    open func decodeTopLevelObject() throws -> AnyObject? {
        NSUnimplemented()
    }
    
    open func decodeTopLevelObjectForKey(_ key: String) throws -> AnyObject? {
        NSUnimplemented()
    }
    
    open func decodeTopLevelObjectOfClass<DecodedObjectType : NSCoding where DecodedObjectType : NSObject>(_ cls: DecodedObjectType.Type, forKey key: String) throws -> DecodedObjectType? {
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
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    open func decodeTopLevelObjectOfClasses(_ classes: [AnyClass], forKey key: String) throws -> AnyObject? {
        NSUnimplemented()
    }
    
    internal var error: NSError? {
        return nil
    }
    
    
    open func encode(_ object: AnyObject?) {
        var object = object
        withUnsafePointer(to: &object) { (ptr: UnsafePointer<AnyObject?>) -> Void in
            encodeValue(ofObjCType: "@", at: unsafeBitCast(ptr, to: UnsafeRawPointer.self))
        }
    }
    
    open func encodeRootObject(_ rootObject: AnyObject) {
        encode(rootObject)
    }
    
    open func encodeBycopyObject(_ anObject: AnyObject?) {
        encode(anObject)
    }
    
    open func encodeByrefObject(_ anObject: AnyObject?) {
        encode(anObject)
    }
    
    open func encodeConditionalObject(_ object: AnyObject?) {
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
    
    open func decodeObject() -> AnyObject? {
        if self.error != nil {
            return nil
        }
        
        var obj: AnyObject? = nil
        withUnsafeMutablePointer(to: &obj) { (ptr: UnsafeMutablePointer<AnyObject?>) -> Void in
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
    
    open func encodePropertyList(_ aPropertyList: AnyObject) {
        NSUnimplemented()
    }
    
    open func decodePropertyList() -> AnyObject? {
        NSUnimplemented()
    }
    
    open var systemVersion: UInt32 {
        return 1000
    }
    
    open var allowsKeyedCoding: Bool {
        return false
    }
    
    open func encode(_ objv: AnyObject?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    open func encodeConditionalObject(_ objv: AnyObject?, forKey key: String) {
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
    
    open func decodeObject(forKey key: String) -> AnyObject? {
        NSRequiresConcreteImplementation()
    }
    
    open func decodeBool(forKey key: String) -> Bool {
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
    open func withDecodedUnsafeBufferPointer<ResultType>(forKey key: String, body: @noescape (UnsafeBufferPointer<UInt8>?) throws -> ResultType) rethrows -> ResultType {
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
    
    open func decodePropertyListForKey(_ key: String) -> AnyObject? {
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
    
    open func failWithError(_ error: NSError) {
        if let debugDescription = error.userInfo["NSDebugDescription"] {
            NSLog("*** NSKeyedUnarchiver.init: \(debugDescription)")
        } else {
            NSLog("*** NSKeyedUnarchiver.init: decoding error")
        }
    }
    
    internal func _decodeArrayOfObjectsForKey(_ key: String) -> [AnyObject] {
        NSRequiresConcreteImplementation()
    }
    
    internal func _decodePropertyListForKey(_ key: String) -> Any {
        NSRequiresConcreteImplementation()
    }
}
