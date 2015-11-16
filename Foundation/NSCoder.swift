// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public protocol NSCoding {
    func encodeWithCoder(aCoder: NSCoder)
    init?(coder aDecoder: NSCoder)
}

public protocol NSSecureCoding : NSCoding {
    static func supportsSecureCoding() -> Bool
}

public class NSCoder : NSObject {
    internal var _pendingBuffers = Array<(UnsafeMutablePointer<Void>, Int)>()
    
    deinit {
        for buffer in _pendingBuffers {
            buffer.0.destroy()
            buffer.0.dealloc(buffer.1)
        }
    }
    
    public func encodeValueOfObjCType(type: UnsafePointer<Int8>, at addr: UnsafePointer<Void>) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeDataObject(data: NSData) {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeValueOfObjCType(type: UnsafePointer<Int8>, at data: UnsafeMutablePointer<Void>) {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeDataObject() -> NSData? {
        NSRequiresConcreteImplementation()
    }
    
    public func versionForClassName(className: String) -> Int {
        NSRequiresConcreteImplementation()
    }

    @warn_unused_result
    public func decodeObjectOfClass<DecodedObjectType : NSCoding where DecodedObjectType : NSObject>(cls: DecodedObjectType.Type, forKey key: String) -> DecodedObjectType? {
        NSUnimplemented()
    }
    
    @warn_unused_result
    public func decodeObjectOfClasses(classes: NSSet?, forKey key: String) -> AnyObject? {
        NSUnimplemented()
    }
    
    @warn_unused_result
    public func decodeTopLevelObject() throws -> AnyObject? {
        NSUnimplemented()
    }
    
    @warn_unused_result
    public func decodeTopLevelObjectForKey(key: String) throws -> AnyObject? {
        NSUnimplemented()
    }
    
    @warn_unused_result
    public func decodeTopLevelObjectOfClass<DecodedObjectType : NSCoding where DecodedObjectType : NSObject>(cls: DecodedObjectType.Type, forKey key: String) throws -> DecodedObjectType? {
        NSUnimplemented()
    }
    
    @warn_unused_result
    public func decodeTopLevelObjectOfClasses(classes: NSSet?, forKey key: String) throws -> AnyObject? {
        NSUnimplemented()
    }
    
    internal var error: NSError? {
        return nil
    }
    
    
    public func encodeObject(object: AnyObject?) {
        var object = object
        withUnsafePointer(&object) { (ptr: UnsafePointer<AnyObject?>) -> Void in
            encodeValueOfObjCType("@", at: unsafeBitCast(ptr, UnsafePointer<Void>.self))
        }
    }
    
    public func encodeRootObject(rootObject: AnyObject) {
        encodeObject(rootObject)
    }
    
    public func encodeBycopyObject(anObject: AnyObject?) {
        encodeObject(anObject)
    }
    
    public func encodeByrefObject(anObject: AnyObject?) {
        encodeObject(anObject)
    }
    
    public func encodeConditionalObject(object: AnyObject?) {
        encodeObject(object)
    }
    
    public func encodeArrayOfObjCType(type: UnsafePointer<Int8>, count: Int, at array: UnsafePointer<Void>) {
        encodeValueOfObjCType("[\(count)\(String.fromCString(type)!)]", at: array)
    }
    
    public func encodeBytes(byteaddr: UnsafePointer<Void>, length: Int) {
        var newLength = UInt32(length)
        withUnsafePointer(&newLength) { (ptr: UnsafePointer<UInt32>) -> Void in
            encodeValueOfObjCType("I", at: ptr)
        }
        encodeArrayOfObjCType("c", count: length, at: byteaddr)
    }
    
    public func decodeObject() -> AnyObject? {
        if self.error != nil {
            return nil
        }
        
        var obj: AnyObject? = nil
        withUnsafeMutablePointer(&obj) { (ptr: UnsafeMutablePointer<AnyObject?>) -> Void in
            decodeValueOfObjCType("@", at: unsafeBitCast(ptr, UnsafeMutablePointer<Void>.self))
        }
        return obj
    }
    
    public func decodeArrayOfObjCType(itemType: UnsafePointer<Int8>, count: Int, at array: UnsafeMutablePointer<Void>) {
        decodeValueOfObjCType("[\(count)\(String.fromCString(itemType)!)]", at: array)
    }
    
    public func decodeBytesWithReturnedLength(lengthp: UnsafeMutablePointer<Int>) -> UnsafeMutablePointer<Void> {
        var length: UInt32 = 0
        withUnsafeMutablePointer(&length) { (ptr: UnsafeMutablePointer<UInt32>) -> Void in
            decodeValueOfObjCType("I", at: unsafeBitCast(ptr, UnsafeMutablePointer<Void>.self))
        }
        // we cannot autorelease here so instead the pending buffers will manage the lifespan of the returned data... this is wasteful but good enough...
        let result = UnsafeMutablePointer<Void>.alloc(Int(length))
        decodeValueOfObjCType("c", at: result)
        lengthp.memory = Int(length)
        _pendingBuffers.append((result, Int(length)))
        return result
    }
    
    public func encodePropertyList(aPropertyList: AnyObject) {
        NSUnimplemented()
    }
    
    public func decodePropertyList() -> AnyObject? {
        NSUnimplemented()
    }
    
    public var systemVersion: UInt32 {
        return 1000
    }
    
    public var allowsKeyedCoding: Bool {
        get {
            return false
        }
    }
    
    public func encodeObject(objv: AnyObject?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeConditionalObject(objv: AnyObject?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeBool(boolv: Bool, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeInt(intv: Int32, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeInt32(intv: Int32, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeInt64(intv: Int64, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeFloat(realv: Float, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeDouble(realv: Double, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func encodeBytes(bytesp: UnsafePointer<UInt8>, length lenv: Int, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func containsValueForKey(key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeObjectForKey(key: String) -> AnyObject? {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeBoolForKey(key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeIntForKey(key: String) -> Int32 {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeInt32ForKey(key: String) -> Int32 {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeInt64ForKey(key: String) -> Int64 {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeFloatForKey(key: String) -> Float {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeDoubleForKey(key: String) -> Double {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeBytesForKey(key: String, returnedLength lengthp: UnsafeMutablePointer<Int>) -> UnsafePointer<UInt8> { // returned bytes immutable!
        NSRequiresConcreteImplementation()
    }
    
    public func encodeInteger(intv: Int, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    public func decodeIntegerForKey(key: String) -> Int {
        NSRequiresConcreteImplementation()
    }
    
    public var requiresSecureCoding: Bool {
        get {
            return false
        }
    }
    
    public func decodePropertyListForKey(key: String) -> AnyObject? {
        NSUnimplemented()
    }
    
    public var allowedClasses: Set<NSObject>? {
        get {
            NSUnimplemented()
        }
    }
    
    public func failWithError(error: NSError) {
        NSUnimplemented()
    }
}