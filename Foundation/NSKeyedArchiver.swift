// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//



// Archives created using the class method archivedRootDataWithObject used this key for the root object in the hierarchy of encoded objects. The NSKeyedUnarchiver class method unarchiveObjectWithData: will look for this root key as well. You can also use it as the key for the root object in your own archives.
public let NSKeyedArchiveRootObjectKey: String = "root"

public class NSKeyedArchiver : NSCoder {
    
    public class func archivedDataWithRootObject(rootObject: AnyObject) -> NSData {
        NSUnimplemented()
    }
    
    public class func archiveRootObject(rootObject: AnyObject, toFile path: String) -> Bool {
        NSUnimplemented()
    }
    
    public init(forWritingWithMutableData data: NSMutableData) {
        NSUnimplemented()
    }
    
    public weak var delegate: NSKeyedArchiverDelegate?
    public var outputFormat: NSPropertyListFormat
    
    public func finishEncoding() {
        NSUnimplemented()
    }
    
    public class func setClassName(codedName: String?, forClass cls: AnyClass) {
        NSUnimplemented()
    }
    
    public func setClassName(codedName: String?, forClass cls: AnyClass) {
        NSUnimplemented()
    }
    
    // During encoding, the coder first checks with the coder's
    // own table, then if there was no mapping there, the class's.
    
    public class func classNameForClass(cls: AnyClass) -> String? {
        NSUnimplemented()
    }
    
    public func classNameForClass(cls: AnyClass) -> String? {
        NSUnimplemented()
    }
    
    public override func encodeObject(objv: AnyObject?, forKey key: String) {
        NSUnimplemented()
    }
    
    public override func encodeConditionalObject(objv: AnyObject?, forKey key: String) {
        NSUnimplemented()
    }
    
    public override func encodeBool(boolv: Bool, forKey key: String) {
        NSUnimplemented()
    }
    
    public override func encodeInt(intv: Int32, forKey key: String) {
        NSUnimplemented()
    }
    
    public override func encodeInt32(intv: Int32, forKey key: String) {
        NSUnimplemented()
    }
    
    public override func encodeInt64(intv: Int64, forKey key: String) {
        NSUnimplemented()
    }
    
    public override func encodeFloat(realv: Float, forKey key: String) {
        NSUnimplemented()
    }
    
    public override func encodeDouble(realv: Double, forKey key: String) {
        NSUnimplemented()
    }
    
    public override func encodeBytes(bytesp: UnsafePointer<UInt8>, length lenv: Int, forKey key: String) {
        NSUnimplemented()
    }
    
    // Enables secure coding support on this keyed archiver. You do not need to enable secure coding on the archiver to enable secure coding on the unarchiver. Enabling secure coding on the archiver is a way for you to be sure that all classes that are encoded conform with NSSecureCoding (it will throw an exception if a class which does not NSSecureCoding is archived). Note that the getter is on the superclass, NSCoder. See NSCoder for more information about secure coding.
    public override var requiresSecureCoding: Bool {
        get {
            return false
        }
    }
}

public class NSKeyedUnarchiver : NSCoder {
    
    public class func unarchiveObjectWithData(data: NSData) -> AnyObject? {
        NSUnimplemented()
    }
    
    public class func unarchiveObjectWithFile(path: String) -> AnyObject? {
        NSUnimplemented()
    }
    
    public init(forReadingWithData data: NSData) {
        NSUnimplemented()
    }
    
    public weak var delegate: NSKeyedUnarchiverDelegate?
    
    public func finishDecoding() {
        NSUnimplemented()
    }
    
    public class func setClass(cls: AnyClass?, forClassName codedName: String) {
        NSUnimplemented()
    }
    
    public func setClass(cls: AnyClass?, forClassName codedName: String) {
        NSUnimplemented()
    }
    
    // During decoding, the coder first checks with the coder's
    // own table, then if there was no mapping there, the class's.
    
    public class func classForClassName(codedName: String) -> AnyClass? {
        NSUnimplemented()
    }
    
    public func classForClassName(codedName: String) -> AnyClass? {
        NSUnimplemented()
    }
    
    public override func containsValueForKey(key: String) -> Bool {
        NSUnimplemented()
    }
    
    public override func decodeObjectForKey(key: String) -> AnyObject? {
        NSUnimplemented()
    }
    
    public override func decodeBoolForKey(key: String) -> Bool {
        NSUnimplemented()
    }
    
    public override func decodeIntForKey(key: String) -> Int32  {
        NSUnimplemented()
    }
    
    public override func decodeInt32ForKey(key: String) -> Int32 {
        NSUnimplemented()
    }
    
    public override func decodeInt64ForKey(key: String) -> Int64 {
        NSUnimplemented()
    }
    
    public override func decodeFloatForKey(key: String) -> Float {
        NSUnimplemented()
    }
    
    public override func decodeDoubleForKey(key: String) -> Double {
        NSUnimplemented()
    }
    
    // returned bytes immutable, and they go away with the unarchiver, not the containing autorelease pool
    public override func decodeBytesForKey(key: String, returnedLength lengthp: UnsafeMutablePointer<Int>) -> UnsafePointer<UInt8> {
        NSUnimplemented()
    }
    
    // Enables secure coding support on this keyed unarchiver. When enabled, anarchiving a disallowed class throws an exception. Once enabled, attempting to set requiresSecureCoding to NO will throw an exception. This is to prevent classes from selectively turning secure coding off. This is designed to be set once at the top level and remain on. Note that the getter is on the superclass, NSCoder. See NSCoder for more information about secure coding.
    public override var requiresSecureCoding: Bool {
        get {
            return false
        }
    }
}

extension NSKeyedUnarchiver {
    @warn_unused_result
    public class func unarchiveTopLevelObjectWithData(data: NSData) throws -> AnyObject? {
        NSUnimplemented()
    }
}

extension NSKeyedArchiverDelegate {
    func archiver(archiver: NSKeyedArchiver, willEncodeObject object: AnyObject) -> AnyObject? {
        // Returning the same object is the same as doing nothing
        return object
    }
    
    func archiver(archiver: NSKeyedArchiver, didEncodeObject object: AnyObject?) { }

    func archiver(archiver: NSKeyedArchiver, willReplaceObject object: AnyObject?, withObject newObject: AnyObject?) { }

    func archiverWillFinish(archiver: NSKeyedArchiver) { }

    func archiverDidFinish(archiver: NSKeyedArchiver) { }

}

public protocol NSKeyedArchiverDelegate : class {
    
    // Informs the delegate that the object is about to be encoded.  The delegate
    // either returns this object or can return a different object to be encoded
    // instead.  The delegate can also fiddle with the coder state.  If the delegate
    // returns nil, nil is encoded.  This method is called after the original object
    // may have replaced itself with replacementObjectForKeyedArchiver:.
    // This method is not called for an object once a replacement mapping has been
    // setup for that object (either explicitly, or because the object has previously
    // been encoded).  This is also not called when nil is about to be encoded.
    // This method is called whether or not the object is being encoded conditionally.
    func archiver(archiver: NSKeyedArchiver, willEncodeObject object: AnyObject) -> AnyObject?
    
    // Informs the delegate that the given object has been encoded.  The delegate
    // might restore some state it had fiddled previously, or use this to keep
    // track of the objects which are encoded.  The object may be nil.  Not called
    // for conditional objects until they are really encoded (if ever).
    func archiver(archiver: NSKeyedArchiver, didEncodeObject object: AnyObject?)
    
    // Informs the delegate that the newObject is being substituted for the
    // object. This is also called when the delegate itself is doing/has done
    // the substitution. The delegate may use this method if it is keeping track
    // of the encoded or decoded objects.
    func archiver(archiver: NSKeyedArchiver, willReplaceObject object: AnyObject?, withObject newObject: AnyObject?)
    
    // Notifies the delegate that encoding is about to finish.
    func archiverWillFinish(archiver: NSKeyedArchiver)
    
    // Notifies the delegate that encoding has finished.
    func archiverDidFinish(archiver: NSKeyedArchiver)
}

extension NSKeyedUnarchiverDelegate {
    func unarchiver(unarchiver: NSKeyedUnarchiver, cannotDecodeObjectOfClassName name: String, originalClasses classNames: [String]) -> AnyClass? {
        return nil
    }
    
    func unarchiver(unarchiver: NSKeyedUnarchiver, didDecodeObject object: AnyObject?) -> AnyObject? {
        // Returning the same object is the same as doing nothing
        return object
    }
    
    func unarchiver(unarchiver: NSKeyedUnarchiver, willReplaceObject object: AnyObject, withObject newObject: AnyObject) { }
    func unarchiverWillFinish(unarchiver: NSKeyedUnarchiver) { }
    func unarchiverDidFinish(unarchiver: NSKeyedUnarchiver) { }
}

public protocol NSKeyedUnarchiverDelegate : class {
    
    // Informs the delegate that the named class is not available during decoding.
    // The delegate may, for example, load some code to introduce the class to the
    // runtime and return it, or substitute a different class object.  If the
    // delegate returns nil, unarchiving aborts with an exception.  The first class
    // name string in the array is the class of the encoded object, the second is
    // the immediate superclass, and so on.
    func unarchiver(unarchiver: NSKeyedUnarchiver, cannotDecodeObjectOfClassName name: String, originalClasses classNames: [String]) -> AnyClass?
    
    // Informs the delegate that the object has been decoded.  The delegate
    // either returns this object or can return a different object to replace
    // the decoded one.  The object may be nil.  If the delegate returns nil,
    // the decoded value will be unchanged (that is, the original object will be
    // decoded). The delegate may use this to keep track of the decoded objects.
    func unarchiver(unarchiver: NSKeyedUnarchiver, didDecodeObject object: AnyObject?) -> AnyObject?
    
    // Informs the delegate that the newObject is being substituted for the
    // object. This is also called when the delegate itself is doing/has done
    // the substitution. The delegate may use this method if it is keeping track
    // of the encoded or decoded objects.
    func unarchiver(unarchiver: NSKeyedUnarchiver, willReplaceObject object: AnyObject, withObject newObject: AnyObject)
    
    // Notifies the delegate that decoding is about to finish.
    func unarchiverWillFinish(unarchiver: NSKeyedUnarchiver)
    
    // Notifies the delegate that decoding has finished.
    func unarchiverDidFinish(unarchiver: NSKeyedUnarchiver)
}

// TODO: Could perhaps be an extension of NSCoding instead. The reason it is an extension of NSObject is the lack of default implementations on protocols in Objective-C.
extension NSObject {
    
    public var classForKeyedArchiver: AnyClass? {
        NSUnimplemented()
    }
    
    // Implemented by classes to substitute a new class for instances during
    // encoding.  The object will be encoded as if it were a member of the
    // returned class.  The results of this method are overridden by the archiver
    // class and instance name<->class encoding tables.  If nil is returned,
    // the result of this method is ignored.  This method returns the result of
    // [self classForArchiver] by default, NOT -classForCoder as might be
    // expected.  This is a concession to source compatibility.
    
    public func replacementObjectForKeyedArchiver(archiver: NSKeyedArchiver) -> AnyObject? {
        NSUnimplemented()
    }
    
    // Implemented by classes to substitute new instances for the receiving
    // instance during encoding.  The returned object will be encoded instead
    // of the receiver (if different).  This method is called only if no
    // replacement mapping for the object has been set up in the archiver yet
    // (for example, due to a previous call of replacementObjectForKeyedArchiver:
    // to that object).  This method returns the result of
    // [self replacementObjectForArchiver:nil] by default, NOT
    // -replacementObjectForCoder: as might be expected.  This is a concession
    // to source compatibility.
    
    public class func classFallbacksForKeyedArchiver() -> [String] {
        NSUnimplemented()
    }
}

// TODO: Could perhaps be an extension of NSCoding instead. The reason it is an extension of NSObject is the lack of default implementations on protocols in Objective-C.
extension NSObject {
    public class func classForKeyedUnarchiver() -> AnyClass {
        NSUnimplemented()
    }
}


