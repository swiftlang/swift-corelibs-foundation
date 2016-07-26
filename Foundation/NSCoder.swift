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

public class NSCoder : NSObject {
    internal var _pendingBuffers = Array<(UnsafeMutablePointer<Void>, Int)>()
    
    deinit {
        for buffer in _pendingBuffers {
            buffer.0.deinitialize()
            buffer.0.deallocate(capacity: buffer.1)
        }
    }
    
    public func encodeValue(ofObjCType type: UnsafePointer<Int8>, at addr: UnsafePointer<Void>) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeDataObject(_ data: Data) {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeValue(ofObjCType type: UnsafePointer<Int8>, at data: UnsafeMutablePointer<Void>) {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeDataObject() -> Data? {
        NSRequiresConcreteImplementation()
    }
    
    public func version(forClassName className: String) -> Int {
        NSRequiresConcreteImplementation()
    }

    public func decodeObjectOfClass<DecodedObjectType : NSCoding where DecodedObjectType : NSObject>(_ cls: DecodedObjectType.Type, forKey key: String) -> DecodedObjectType? {
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
    public func decodeObjectOfClasses(_ classes: [AnyClass], forKey key: String) -> AnyObject? {
        NSUnimplemented()
    }
    
    public func decodeTopLevelObject() throws -> AnyObject? {
        NSUnimplemented()
    }
    
    public func decodeTopLevelObjectForKey(_ key: String) throws -> AnyObject? {
        NSUnimplemented()
    }
    
    public func decodeTopLevelObjectOfClass<DecodedObjectType : NSCoding where DecodedObjectType : NSObject>(_ cls: DecodedObjectType.Type, forKey key: String) throws -> DecodedObjectType? {
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
    public func decodeTopLevelObjectOfClasses(_ classes: [AnyClass], forKey key: String) throws -> AnyObject? {
        NSUnimplemented()
    }
    
    internal var error: NSError? {
        return nil
    }
    
    
    public func encode(_ object: AnyObject?) {
        var object = object
        withUnsafePointer(&object) { (ptr: UnsafePointer<AnyObject?>) -> Void in
            encodeValue(ofObjCType: "@", at: unsafeBitCast(ptr, to: UnsafePointer<Void>.self))
        }
    }
    
    public func encodeRootObject(_ rootObject: AnyObject) {
        encode(rootObject)
    }
    
    public func encodeBycopyObject(_ anObject: AnyObject?) {
        encode(anObject)
    }
    
    public func encodeByrefObject(_ anObject: AnyObject?) {
        encode(anObject)
    }
    
    public func encodeConditionalObject(_ object: AnyObject?) {
        encode(object)
    }
    
    public func encodeArray(ofObjCType type: UnsafePointer<Int8>, count: Int, at array: UnsafePointer<Void>) {
        encodeValue(ofObjCType: "[\(count)\(String(cString: type))]", at: array)
    }
    
    public func encodeBytes(_ byteaddr: UnsafePointer<Void>?, length: Int) {
        var newLength = UInt32(length)
        withUnsafePointer(&newLength) { (ptr: UnsafePointer<UInt32>) -> Void in
            encodeValue(ofObjCType: "I", at: ptr)
        }
        var empty: [Int8] = []
        withUnsafePointer(&empty) {
            encodeArray(ofObjCType: "c", count: length, at: byteaddr ?? UnsafePointer($0))
        }
    }
    
    public func decodeObject() -> AnyObject? {
        if self.error != nil {
            return nil
        }
        
        var obj: AnyObject? = nil
        withUnsafeMutablePointer(&obj) { (ptr: UnsafeMutablePointer<AnyObject?>) -> Void in
            decodeValue(ofObjCType: "@", at: unsafeBitCast(ptr, to: UnsafeMutablePointer<Void>.self))
        }
        return obj
    }
    
    public func decodeArray(ofObjCType itemType: UnsafePointer<Int8>, count: Int, at array: UnsafeMutablePointer<Void>) {
        decodeValue(ofObjCType: "[\(count)\(String(cString: itemType))]", at: array)
    }
   
    /*
    // TODO: This is disabled, as functions which return unsafe interior pointers are inherently unsafe when we have no autorelease pool. 
    public func decodeBytes(withReturnedLength lengthp: UnsafeMutablePointer<Int>) -> UnsafeMutablePointer<Void>? {
        var length: UInt32 = 0
        withUnsafeMutablePointer(&length) { (ptr: UnsafeMutablePointer<UInt32>) -> Void in
            decodeValue(ofObjCType: "I", at: unsafeBitCast(ptr, to: UnsafeMutablePointer<Void>.self))
        }
        // we cannot autorelease here so instead the pending buffers will manage the lifespan of the returned data... this is wasteful but good enough...
        let result = UnsafeMutablePointer<Void>.allocate(capacity: Int(length))
        decodeValue(ofObjCType: "c", at: result)
        lengthp.pointee = Int(length)
        _pendingBuffers.append((result, Int(length)))
        return result
    }
    */
    
    public func encodePropertyList(_ aPropertyList: AnyObject) {
        NSUnimplemented()
    }
    
    public func decodePropertyList() -> AnyObject? {
        NSUnimplemented()
    }
    
    public var systemVersion: UInt32 {
        return 1000
    }
    
    public var allowsKeyedCoding: Bool {
        return false
    }
    
    public func encode(_ objv: AnyObject?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeConditionalObject(_ objv: AnyObject?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encode(_ boolv: Bool, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encode(_ intv: Int32, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encode(_ intv: Int64, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encode(_ realv: Float, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encode(_ realv: Double, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeBytes(_ bytesp: UnsafePointer<UInt8>?, length lenv: Int, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func containsValue(forKey key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeObject(forKey key: String) -> AnyObject? {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeBool(forKey key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeInt32(forKey key: String) -> Int32 {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeInt64(forKey key: String) -> Int64 {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeFloat(forKey key: String) -> Float {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeDouble(forKey key: String) -> Double {
        NSRequiresConcreteImplementation()
    }
    
    // TODO: This is disabled, as functions which return unsafe interior pointers are inherently unsafe when we have no autorelease pool. 
    /*
    public func decodeBytes(forKey key: String, returnedLength lengthp: UnsafeMutablePointer<Int>?) -> UnsafePointer<UInt8>? { // returned bytes immutable!
        NSRequiresConcreteImplementation()
    }
    */
    /// - experimental: This method does not exist in the Darwin Foundation.
    public func withDecodedUnsafeBufferPointer<ResultType>(forKey key: String, body: @noescape (UnsafeBufferPointer<UInt8>?) throws -> ResultType) rethrows -> ResultType {
        NSRequiresConcreteImplementation()
    }

    public func encode(_ intv: Int, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeInteger(forKey key: String) -> Int {
        NSRequiresConcreteImplementation()
    }
    
    public var requiresSecureCoding: Bool {
        return false
    }
    
    public func decodePropertyListForKey(_ key: String) -> AnyObject? {
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
    public var allowedClasses: [AnyClass]? {
        NSUnimplemented()
    }
    
    public func failWithError(_ error: NSError) {
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
