// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

extension NSCoder {

    /// Describes the action an `NSCoder` should take when it encounters decode
    /// failures (e.g. corrupt data) for non-TopLevel decodes. Darwin platfrom
    /// supports exceptions here, and there may be other approaches supported
    /// in the future, so its included for completeness.
    public enum DecodingFailurePolicy : Int {
        case setErrorAndReturn
    }
}


/// The `NSCoding` protocol declares the two methods that a class must implement
/// so that instances of that class can be encoded and decoded. This capability
/// provides the basis for archiving (where objects and other structures are
/// stored on disk) and distribution (where objects are copied to different
/// address spaces).
///
/// In keeping with object-oriented design principles, an object being encoded
/// or decoded is responsible for encoding and decoding its instance variables.
/// A coder instructs the object to do so by invoking `encode(with:)` or
/// `init(coder:)`. `encode(with:)` instructs the object to encode its instance
/// variables to the coder provided; this method can be invoked any number of
/// times. `init(coder:)` instructs the object to initialize itself from data
/// in the coder provided.
/// Any object class that should be codable must adopt the NSCoding protocol and
/// implement its methods.
public protocol NSCoding {
    
    /// Encodes an instance of a conforming class using a given archiver.
    ///
    /// - Parameter aCoder: An archiver object.
    func encode(with aCoder: NSCoder)
    
    /// Initializes an object from data in a given unarchiver.
    ///
    /// - Parameter aDecoder: An unarchiver object.
    init?(coder aDecoder: NSCoder)
}

/// Conforming to the `NSSecureCoding` protocol indicates that an object handles
/// encoding and decoding instances of itself in a manner that is robust against
/// object substitution attacks.
///
/// Historically, many classes decoded instances of themselves like this:
/// ```swift
/// if let object = decoder.decodeObject(forKey: "myKey") as? MyClass {
///     ...succeeds...
/// } else {
///     ...fail...
/// }
/// ```
/// This technique is potentially unsafe because by the time you can verify
/// the class type, the object has already been constructed, and if this is part
/// of a collection class, potentially inserted into an object graph.
///
/// In order to conform to `NSSecureCoding`:
/// - An object that does not override `init(coder:)` can conform to
///   `NSSecureCoding` without any changes (assuming that it is a subclass
///   of another class that conforms).
/// - An object that does override `init(coder:)` must decode any enclosed
///   objects using the `decodeObject(of:forKey:)` method. For example:
///   ```swift
///   let obj = decoder.decodeObject(of: MyClass.self, forKey: "myKey")
///   ```
///   In addition, the class must override its `NSSecureCoding` method to return
///   `true`.
public protocol NSSecureCoding : NSCoding {
    
    static var supportsSecureCoding: Bool { get }
}

/// The `NSCoder` abstract class declares the interface used by concrete
/// subclasses to transfer objects and other values between memory and some
/// other format. This capability provides the basis for archiving (where
/// objects and data items are stored on disk) and distribution (where objects
/// and data items are copied between different processes or threads). The
/// concrete subclasses provided by Foundation for these purposes are
/// `NSKeyedArchiver` and `NSKeyedUnarchiver`. Concrete subclasses of `NSCoder`
/// are referred to in general as coder classes, and instances of these classes
/// as coder objects (or simply coders). A coder object that can only encode
/// values is referred to as an encoder object, and one that can only decode
/// values as a decoder object.
///
/// `NSCoder` operates on objects, scalars, C arrays, structures, and strings,
/// and on pointers to these types. It does not handle types whose
/// implementation varies across platforms, such as `UnsafeRawPointer`,
/// closures, and long chains of pointers. A coder object stores object type
/// information along with the data, so an object decoded from a stream of bytes
/// is normally of the same class as the object that was originally encoded into
/// the stream. An object can change its class when encoded, however; this is
/// described in Archives and Serializations Programming Guide.
open class NSCoder : NSObject {
    internal var _pendingBuffers = Array<(UnsafeMutableRawPointer, Int)>()
    
    deinit {
        for buffer in _pendingBuffers {
            // Cannot deinitialize a pointer to unknown type.
            buffer.0.deallocate()
        }
    }
    
    /// Must be overridden by subclasses to encode a single value residing at
    /// `addr`, whose Objective-C type is given by `type`.
    ///
    /// `type` must contain exactly one type code.
    ///
    /// This method must be matched by a subsequent
    /// `decodeValue(ofObjCType:at:)` call.
    ///
    /// - Parameters:
    ///   - type: A type code.
    ///   - addr: The address of the object to endcode.
    open func encodeValue(ofObjCType type: UnsafePointer<Int8>, at addr: UnsafeRawPointer) {
        NSRequiresConcreteImplementation()
    }
    
    /// Encodes a given `Data` object.
    ///
    /// Subclasses must override this method.
    ///
    /// This method must be matched by a subsequent `decodeData()` call.
    ///
    /// - Parameter data: The data to encode.
    open func encode(_ data: Data) {
        NSRequiresConcreteImplementation()
    }
    
    /// Decodes a single value, whose Objective-C type is given by `type`.
    ///
    /// `type` must contain exactly one type code, and the buffer specified by
    /// `data` must be large enough to hold the value corresponding to that type
    /// code.
    ///
    /// Subclasses must override this method and provide an implementation to
    /// decode the value. In your overriding implementation, decode the value
    /// into the buffer beginning at `data`.
    ///
    /// This method matches an `encodeValue(ofObjCType:at:)` call used during
    /// encoding.
    ///
    /// - Parameters:
    ///   - type: A type code.
    ///   - data: The buffer to put the decoded value into.
    open func decodeValue(ofObjCType type: UnsafePointer<Int8>, at data: UnsafeMutableRawPointer) {
        NSRequiresConcreteImplementation()
    }
    
    /// Decodes and returns a `Data` object that was previously encoded with
    /// `encode(_:)`. Subclasses must override this method.
    ///
    /// The implementation of your overriding method must match the
    /// implementation of your `encode(_:)` method. For example, a typical
    /// `encode(_:)` method encodes the number of bytes of data followed by
    /// the bytes themselves. Your override of this method must read the number
    /// of bytes, create a `Data` object of the appropriate size, and decode the
    /// bytes into the new `Data` object.
    ///
    /// - Returns: The decoded data.
    open func decodeData() -> Data? {
        NSRequiresConcreteImplementation()
    }
    
    /// This method is present for historical reasons and is not used with
    /// keyed archivers.
    ///
    /// The version number does apply not to
    /// `NSKeyedArchiver`/`NSKeyedUnarchiver`. A keyed archiver does not encode
    /// class version numbers.
    ///
    /// - Parameter className: The class name.
    /// - Returns: The version in effect for the class named `className` or
    ///            `NSNotFound` if no class named `className` exists.
    open func version(forClassName className: String) -> Int {
        NSRequiresConcreteImplementation()
    }

    open func decodeObject<DecodedObjectType: NSCoding>(of cls: DecodedObjectType.Type, forKey key: String) -> DecodedObjectType? where DecodedObjectType: NSObject {
        NSUnimplemented()
    }
   
    /// Decodes an object for the key, restricted to the specified `classes`.
    ///
    /// This function signature differs from Darwin Foundation in that `classes`
    /// is an array of classes, not a set. This is because `AnyClass` cannot
    /// be casted to `NSObject`, nor is it `Hashable`.
    ///
    /// - Parameters:
    ///   - classes:    An array of the expected classes.
    ///   - key:        The code key.
    /// - Returns:      The decoded object.
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
    
    /// Decodes an top-level object for the key, restricted to the specified
    /// `classes`.
    ///
    /// This function signature differs from Darwin Foundation in that `classes`
    /// is an array of classes, not a set. This is because `AnyClass` cannot
    /// be casted to `NSObject`, nor is it `Hashable`.
    ///
    /// - Parameters:
    ///   - classes: An array of the expected classes.
    ///   - key: The code key.
    /// - Returns: The decoded object.
    open func decodeTopLevelObject(of classes: [AnyClass], forKey key: String) throws -> Any? {
        NSUnimplemented()
    }
    
    /// Encodes `object`.
    ///
    /// `NSCoder`’s implementation simply invokes `encodeValue(ofObjCType:at:)`
    /// to encode object. Subclasses can override this method to encode
    /// a reference to object instead of object itself.
    ///
    /// This method must be matched by a subsequent `decodeObject()` call.
    ///
    /// - Parameter object: The object to encode.
    open func encode(_ object: Any?) {
        var object = object
        withUnsafePointer(to: &object) { (ptr: UnsafePointer<Any?>) -> Void in
            encodeValue(ofObjCType: "@", at: UnsafeRawPointer(ptr))
        }
    }
    
    /// Can be overridden by subclasses to encode an interconnected group of
    /// Objective-C objects, starting with `rootObject`.
    ///
    /// `NSCoder`’s implementation simply invokes `encode(_:)`.
    ///
    /// This method must be matched by a subsequent `decodeObject()` call.
    ///
    /// - Parameter rootObject: The root object of the group to encode.
    open func encodeRootObject(_ rootObject: Any) {
        encode(rootObject)
    }
    
    /// Can be overridden by subclasses to encode `anObject` so that a copy,
    /// rather than a proxy, is created upon decoding.
    ///
    /// `NSCoder`’s implementation simply invokes `encode(_:)`.
    ///
    /// This method must be matched by a corresponding `decodeObject()` call.
    ///
    /// - Parameter anObject: The object to encode.
    open func encodeBycopyObject(_ anObject: Any?) {
        encode(anObject)
    }
    
    /// Can be overridden by subclasses to encode `anObject` so that a proxy,
    /// rather than a copy, is created upon decoding.
    ///
    /// `NSCoder`’s implementation simply invokes `encode(_:)`.
    ///
    /// This method must be matched by a corresponding `decodeObject()` call.
    ///
    /// - Parameter anObject: The object to encode.
    open func encodeByrefObject(_ anObject: Any?) {
        encode(anObject)
    }
    
    /// Can be overridden by subclasses to conditionally encode `object`,
    /// preserving common references to that object.
    ///
    /// In the overriding method, `object` should be encoded only if it’s
    /// unconditionally encoded elsewhere (with any other `encode...Object`
    /// method).
    ///
    /// This method must be matched by a subsequent `decodeObject()` call. Upon
    /// decoding, if `object` was never encoded unconditionally,
    /// `decodeObject()` returns `nil` in place of `object`. However, if
    /// `object` was encoded unconditionally, all references to `object` must be
    /// resolved.
    ///
    /// `NSCoder’s` implementation simply invokes `encode(_:)`.
    ///
    /// - Parameter object: The object to conditionally encode.
    open func encodeConditionalObject(_ object: Any?) {
        encode(object)
    }
    
    /// Encodes an array of `count` items, whose Objective-C type is given by
    /// `type`.
    ///
    /// The values are encoded from the buffer beginning at `array`. `type` must
    /// contain exactly one type code. `NSCoder`’s implementation invokes
    /// `encodeValue(ofObjCType:at:)` to encode the entire array of items.
    /// Subclasses that implement the `encodeValue(ofObjCType:at:)` method do
    /// not need to override this method.
    ///
    /// This method must be matched by a subsequent
    /// `decodeArray(ofObjCType:count:at:)` call.
    ///
    /// - note: You should not use this method to encode C arrays of Objective-C
    ///         objects. See `decodeArray(ofObjCType:count:at:)` for more
    ///         details.
    ///
    /// - Parameters:
    ///   - type:   A type code.
    ///   - count:  The number of items in `array`.
    ///   - array:  The buffer of items.
    open func encodeArray(ofObjCType type: UnsafePointer<Int8>, count: Int, at array: UnsafeRawPointer) {
        encodeValue(ofObjCType: "[\(count)\(String(cString: type))]", at: array)
    }
    
    /// Encodes a buffer of data whose types are unspecified.
    ///
    /// The buffer to be encoded begins at `byteaddr`, and its length in bytes
    /// is given by `length`.
    ///
    /// This method must be matched by a corresponding
    /// `decodeBytes(withReturnedLength:)` call.
    ///
    /// - Parameters:
    ///   - byteaddr:   The address of the buffer to encode.
    ///   - length:     The length of the buffer.
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
    
    /// Decodes an Objective-C object that was previously encoded with any of
    /// the `encode...Object` methods.
    ///
    /// `NSCoder`’s implementation invokes `decodeValue(ofObjCType:at:)` to
    /// decode the object data.
    ///
    /// Subclasses may need to override this method if they override any of the
    /// corresponding `encode...Object` methods. For example, if an object was
    /// encoded conditionally using the `encodeConditionalObject(_:)` method,
    /// this method needs to check whether the object had actually been encoded.
    ///
    /// - Returns: The decoded object.
    open func decodeObject() -> Any? {
        if self.error != nil {
            return nil
        }
        
        var obj: Any? = nil
        withUnsafeMutablePointer(to: &obj) { (ptr: UnsafeMutablePointer<Any?>) -> Void in
            decodeValue(ofObjCType: "@", at: UnsafeMutableRawPointer(ptr))
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
        let result = UnsafeMutableRawPointer.allocate(byteCount: Int(length), alignment: MemoryLayout<Int>.alignment)
        decodeValue(ofObjCType: "c", at: result)
        lengthp.pointee = Int(length)
        _pendingBuffers.append((result, Int(length)))
        return result
    }
    */
    
    /// Encodes the property list `aPropertyList`.
    ///
    /// `NSCoder`’s implementation invokes `encodeValue(ofObjCType:at:)`
    /// to encode `aPropertyList`.
    ///
    /// This method must be matched by a subsequent `decodePropertyList()` call.
    ///
    /// - Parameter aPropertyList: The property list to encode.
    open func encodePropertyList(_ aPropertyList: Any) {
        NSUnimplemented()
    }
    
    /// Decodes a property list that was previously encoded with
    /// `encodePropertyList(_:)`.
    ///
    /// - Returns: The decoded property list.
    open func decodePropertyList() -> Any? {
        NSUnimplemented()
    }
    
    /// The system version in effect for the archive.
    ///
    /// During encoding, the current version. During decoding, the version that
    /// was in effect when the data was encoded.
    ///
    /// Subclasses that implement decoding must override this property to return
    /// the system version of the data being decoded.
    open var systemVersion: UInt32 {
        return 1000
    }
    
    /// A Boolean value that indicates whether the receiver supports keyed
    /// coding of objects.
    ///
    /// `false` by default. Concrete subclasses that support keyed coding,
    /// such as `NSKeyedArchiver`, need to override this property to return
    /// `true`.
    open var allowsKeyedCoding: Bool {
        return false
    }
    
    /// Encodes the object `objv` and associates it with the string `key`.
    ///
    /// Subclasses must override this method to identify multiple encodings
    /// of `objv` and encode a reference to `objv` instead. For example,
    /// `NSKeyedArchiver` detects duplicate objects and encodes a reference to
    /// the original object rather than encode the same object twice.
    ///
    /// - Parameters:
    ///   - objv:   The object to encode.
    ///   - key:    The key to associate the object with.
    open func encode(_ objv: Any?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    /// Conditionally encodes a reference to `objv` and associates it with
    /// the string `key` only if `objv` has been unconditionally encoded with
    /// `encode(_:forKey:)`.
    ///
    /// Subclasses must override this method if they support keyed coding.
    ///
    /// The encoded object is decoded with the `decodeObject(forKey:)` method.
    /// If `objv` was never encoded unconditionally, `decodeObject(forKey:)`
    /// returns `nil` in place of `objv`.
    ///
    /// - Parameters:
    ///   - objv:   The object to conditionally encode.
    ///   - key:    The key to associate the object with.
    open func encodeConditionalObject(_ objv: Any?, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    /// Encodes `boolv` and associates it with the string `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameters:
    ///   - boolv:  The value to encode.
    ///   - key:    The key to associate the value with.
    open func encode(_ boolv: Bool, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    /// Encodes the 32-bit integer `intv` and associates it with the string
    /// `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameters:
    ///   - intv:   The value to encode.
    ///   - key:    The key to associate the value with.
    open func encode(_ intv: Int32, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    /// Encodes the 64-bit integer `intv` and associates it with the string
    /// `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameters:
    ///   - intv:   The value to encode.
    ///   - key:    The key to associate the value with.
    open func encode(_ intv: Int64, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    /// Encodes `realv` and associates it with the string
    /// `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameters:
    ///   - intv:   The value to encode.
    ///   - key:    The key to associate the value with.
    open func encode(_ realv: Float, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    /// Encodes `realv` and associates it with the string
    /// `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameters:
    ///   - intv:   The value to encode.
    ///   - key:    The key to associate the value with.
    open func encode(_ realv: Double, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    /// Encodes a buffer of data, `bytesp`, whose length is specified by `lenv`,
    /// and associates it with the string `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameters:
    ///   - bytesp: The buffer of data to encode.
    ///   - lenv:   The length of the buffer.
    ///   - key:    The key to associate the data with.
    open func encodeBytes(_ bytesp: UnsafePointer<UInt8>?, length lenv: Int, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    /// Returns a Boolean value that indicates whether an encoded value is
    /// available for a string.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// The string is passed as `key`.
    ///
    /// - Parameter key:    The key to test.
    /// - Returns:          `true` if an encoded value is available for provided
    ///                     `key`, otherwise `false`.
    open func containsValue(forKey key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    /// Decodes and returns an Objective-C object that was previously encoded
    /// with `encode(_:forKey:)` or `encodeConditionalObject(_:forKey:)` and
    /// associated with the string `key`.
    ///
    /// - Parameter key:    The key the object to be decoded is associated with.
    /// - Returns:          The decoded object.
    open func decodeObject(forKey key: String) -> Any? {
        NSRequiresConcreteImplementation()
    }
    
    /// Decodes and returns a Boolean value that was previously encoded with
    /// `encode(_:forKey:)` and associated with the string `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameter key:    The key the value to be decoded is associated with.
    /// - Returns:          The decoded value.
    open func decodeBool(forKey key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    // NOTE: this equivalent to the decodeIntForKey: in Objective-C implementation
    
    /// Decodes and returns an int value that was previously encoded with
    /// `encodeCInt(_:forKey:)` or `encode(_:forKey:)` and associated with
    /// the string `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameter key:    The key the value to be decoded is associated with.
    /// - Returns:          The decoded value.
    open func decodeCInt(forKey key: String) -> Int32 {
        
        NSRequiresConcreteImplementation()
    }
    
    /// Decodes and returns a 32-bit integer value that was previously encoded
    /// with `encodeCInt(_:forKey:)` or `encode(_:forKey:)` and associated with
    /// the string `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameter key:    The key the value to be decoded is associated with.
    /// - Returns:          The decoded value.
    open func decodeInt32(forKey key: String) -> Int32 {
        NSRequiresConcreteImplementation()
    }
    
    /// Decodes and returns a 64-bit integer value that was previously encoded
    /// with `encodeCInt(_:forKey:)` or `encode(_:forKey:)` and associated with
    /// the string `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameter key:    The key the value to be decoded is associated with.
    /// - Returns:          The decoded value.
    open func decodeInt64(forKey key: String) -> Int64 {
        NSRequiresConcreteImplementation()
    }
    
    /// Decodes and returns a float value that was previously encoded
    /// with `encodeCInt(_:forKey:)` or `encode(_:forKey:)` and associated with
    /// the string `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameter key:    The key the value to be decoded is associated with.
    /// - Returns:          The decoded value.
    open func decodeFloat(forKey key: String) -> Float {
        NSRequiresConcreteImplementation()
    }
    
    /// Decodes and returns a double value that was previously encoded
    /// with `encodeCInt(_:forKey:)` or `encode(_:forKey:)` and associated with
    /// the string `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameter key:    The key the value to be decoded is associated with.
    /// - Returns:          The decoded value.
    open func decodeDouble(forKey key: String) -> Double {
        NSRequiresConcreteImplementation()
    }
    
    // TODO: This is disabled, as functions which return unsafe interior pointers are inherently unsafe when we have no autorelease pool. 
    /*
    open func decodeBytes(forKey key: String, returnedLength lengthp: UnsafeMutablePointer<Int>?) -> UnsafePointer<UInt8>? { // returned bytes immutable!
        NSRequiresConcreteImplementation()
    }
    */

    /// - Experiment: This method does not exist in the Darwin Foundation.
    open func withDecodedUnsafeBufferPointer<ResultType>(forKey key: String, body: (UnsafeBufferPointer<UInt8>?) throws -> ResultType) rethrows -> ResultType {
        NSRequiresConcreteImplementation()
    }

    /// Encodes a given integer number and associates it with a given key.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameters:
    ///   - intv:   The value to encode.
    ///   - key:    The key to associate the value with.
    open func encode(_ intv: Int, forKey key: String) {
        NSRequiresConcreteImplementation()
    }
    
    /// Decodes and returns an integer value that was previously encoded
    /// with `encodeCInt(_:forKey:)` or `encode(_:forKey:)` and associated with
    /// the string `key`.
    ///
    /// Subclasses must override this method if they perform keyed coding.
    ///
    /// - Parameter key:    The key the value to be decoded is associated with.
    /// - Returns:          The decoded value.
    open func decodeInteger(forKey key: String) -> Int {
        NSRequiresConcreteImplementation()
    }
    
    /// Boolean value that indicates whether the coder requires secure coding.
    ///
    /// `true` if this coder requires secure coding; `false` otherwise.
    ///
    /// Secure coders check a set of allowed classes before decoding objects,
    /// and all objects must implement the `NSSecureCoding` protocol.
    open var requiresSecureCoding: Bool {
        return false
    }
    
    /// Returns a decoded property list for the specified key.
    ///
    /// - Parameter key:    The coder key.
    /// - Returns:          A decoded object containing a property list.
    open func decodePropertyList(forKey key: String) -> Any? {
        NSUnimplemented()
    }

    /// The array of coded classes allowed for secure coding.
    ///
    /// This property type differs from Darwin Foundation in that `classes` is
    /// an array of classes, not a set. This is because `AnyClass` is not
    /// `Hashable`.
    ///
    /// - Experiment: This is a draft API currently under consideration for
    ///               official import into Foundation.
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
    
    internal func _decodePropertyListForKey(_ key: String) -> Any? {
        NSRequiresConcreteImplementation()
    }
}
