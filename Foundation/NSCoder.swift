// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public protocol NSCoding {
    func encodeWithCoder(_ aCoder: NSCoder)
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
            buffer.0.deallocateCapacity(buffer.1)
        }
    }
    
    public func encodeValueOfObjCType(_ type: UnsafePointer<Int8>, at addr: UnsafePointer<Void>) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeDataObject(_ data: NSData) {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeValueOfObjCType(_ type: UnsafePointer<Int8>, at data: UnsafeMutablePointer<Void>) {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeDataObject() -> NSData? {
        NSRequiresConcreteImplementation()
    }
    
    public func versionForClassName(_ className: String) -> Int {
        NSRequiresConcreteImplementation()
    }

    @warn_unused_result
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
    @warn_unused_result
    public func decodeObjectOfClasses(_ classes: [AnyClass], forKey key: String) -> AnyObject? {
        NSUnimplemented()
    }
    
    @warn_unused_result
    public func decodeTopLevelObject() throws -> AnyObject? {
        NSUnimplemented()
    }
    
    @warn_unused_result
    public func decodeTopLevelObjectForKey(_ key: String) throws -> AnyObject? {
        NSUnimplemented()
    }
    
    @warn_unused_result
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
    @warn_unused_result
    public func decodeTopLevelObjectOfClasses(_ classes: [AnyClass], forKey key: String) throws -> AnyObject? {
        NSUnimplemented()
    }
    
    internal var error: NSError? {
        return nil
    }
    
    
    public func encodeObject(_ object: AnyObject?) {
        var object = object
        withUnsafePointer(&object) { (ptr: UnsafePointer<AnyObject?>) -> Void in
            encodeValueOfObjCType("@", at: unsafeBitCast(ptr, to: UnsafePointer<Void>.self))
        }
    }
    
    public func encodeRootObject(_ rootObject: AnyObject) {
        encodeObject(rootObject)
    }
    
    public func encodeBycopyObject(_ anObject: AnyObject?) {
        encodeObject(anObject)
    }
    
    public func encodeByrefObject(_ anObject: AnyObject?) {
        encodeObject(anObject)
    }
    
    public func encodeConditionalObject(_ object: AnyObject?) {
        encodeObject(object)
    }
    
    public func encodeArrayOfObjCType(_ type: UnsafePointer<Int8>, count: Int, at array: UnsafePointer<Void>) {
        encodeValueOfObjCType("[\(count)\(String(cString: type))]", at: array)
    }
    
    public func encodeBytes(_ byteaddr: UnsafePointer<Void>?, length: Int) {
        var newLength = UInt32(length)
        withUnsafePointer(&newLength) { (ptr: UnsafePointer<UInt32>) -> Void in
            encodeValueOfObjCType("I", at: ptr)
        }
        var empty: [Int8] = []
        withUnsafePointer(&empty) {
            encodeArrayOfObjCType("c", count: length, at: byteaddr ?? UnsafePointer($0))
        }
    }
    
    public func decodeObject() -> AnyObject? {
        if self.error != nil {
            return nil
        }
        
        var obj: AnyObject? = nil
        withUnsafeMutablePointer(&obj) { (ptr: UnsafeMutablePointer<AnyObject?>) -> Void in
            decodeValueOfObjCType("@", at: unsafeBitCast(ptr, to: UnsafeMutablePointer<Void>.self))
        }
        return obj
    }
    
    public func decodeArrayOfObjCType(_ itemType: UnsafePointer<Int8>, count: Int, at array: UnsafeMutablePointer<Void>) {
        decodeValueOfObjCType("[\(count)\(String(cString: itemType))]", at: array)
    }
    
    public func decodeBytesWithReturnedLength(_ lengthp: UnsafeMutablePointer<Int>) -> UnsafeMutablePointer<Void> {
        var length: UInt32 = 0
        withUnsafeMutablePointer(&length) { (ptr: UnsafeMutablePointer<UInt32>) -> Void in
            decodeValueOfObjCType("I", at: unsafeBitCast(ptr, to: UnsafeMutablePointer<Void>.self))
        }
        // we cannot autorelease here so instead the pending buffers will manage the lifespan of the returned data... this is wasteful but good enough...
        let result = UnsafeMutablePointer<Void>(allocatingCapacity: Int(length))
        decodeValueOfObjCType("c", at: result)
        lengthp.pointee = Int(length)
        _pendingBuffers.append((result, Int(length)))
        return result
    }
    
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
    
    public func encodeObject(_ objv: AnyObject?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeConditionalObject(_ objv: AnyObject?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeBool(_ boolv: Bool, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeInt(_ intv: Int32, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeInt32(_ intv: Int32, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeInt64(_ intv: Int64, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeFloat(_ realv: Float, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeDouble(_ realv: Double, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeBytes(_ bytesp: UnsafePointer<UInt8>, length lenv: Int, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func containsValueForKey(_ key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeObjectForKey(_ key: String) -> AnyObject? {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeBoolForKey(_ key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeIntForKey(_ key: String) -> Int32 {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeInt32ForKey(_ key: String) -> Int32 {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeInt64ForKey(_ key: String) -> Int64 {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeFloatForKey(_ key: String) -> Float {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeDoubleForKey(_ key: String) -> Double {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeBytesForKey(_ key: String, returnedLength lengthp: UnsafeMutablePointer<Int>?) -> UnsafePointer<UInt8>? { // returned bytes immutable!
        NSRequiresConcreteImplementation()
    }
    
    public func encodeInteger(_ intv: Int, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeIntegerForKey(_ key: String) -> Int {
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
