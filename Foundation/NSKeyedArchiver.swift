// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

/// Archives created using the class method `archivedData(withRootObject:)` use this key
/// for the root object in the hierarchy of encoded objects. The `NSKeyedUnarchiver` class method
/// `unarchiveObject(with:)` looks for this root key as well.
public let NSKeyedArchiveRootObjectKey: String = "root"

internal let NSKeyedArchiveNullObjectReference = _NSKeyedArchiverUID(value: 0)
internal let NSKeyedArchiveNullObjectReferenceName: String = "$null"
internal let NSKeyedArchivePlistVersion = 100000
internal let NSKeyedArchiverSystemVersion : UInt32 = 2000

internal func escapeArchiverKey(_ key: String) -> String {
    if key.hasPrefix("$") {
        return "$" + key
    } else {
        return key
    }
}

internal let NSPropertyListClasses : [AnyClass] = [
        NSArray.self,
        NSDictionary.self,
        NSString.self,
        NSData.self,
        NSDate.self,
        NSNumber.self
]

/// `NSKeyedArchiver`, a concrete subclass of `NSCoder`, provides a way to encode objects
/// (and scalar values) into an architecture-independent format that can be stored in a file.
/// When you archive a set of objects, the class information and instance variables for each object
/// are written to the archive. `NSKeyedArchiver`’s companion class, `NSKeyedUnarchiver`,
/// decodes the data in an archive and creates a set of objects equivalent to the original set.
///
/// A keyed archive differs from a non-keyed archive in that all the objects and values
/// encoded into the archive are given names, or keys. When decoding a non-keyed archive,
/// values have to be decoded in the same order in which they were encoded.
/// When decoding a keyed archive, because values are requested by name, values can be decoded
/// out of sequence or not at all. Keyed archives, therefore, provide better support
/// for forward and backward compatibility.
/// 
/// The keys given to encoded values must be unique only within the scope of the current
/// object being encoded. A keyed archive is hierarchical, so the keys used by object A
/// to encode its instance variables do not conflict with the keys used by object B,
/// even if A and B are instances of the same class. Within a single object,
/// however, the keys used by a subclass can conflict with keys used in its superclasses.
///
/// An `NSKeyedArchiver` object can write the archive data to a file or to a
/// mutable-data object (an instance of `NSMutableData`) that you provide.
open class NSKeyedArchiver : NSCoder {

    struct ArchiverFlags : OptionSet {
        let rawValue : UInt
        
        init(rawValue : UInt) {
            self.rawValue = rawValue
        }
        
        static let none = ArchiverFlags(rawValue: 0)
        static let finishedEncoding = ArchiverFlags(rawValue : 1)
        static let requiresSecureCoding = ArchiverFlags(rawValue: 2)
    }
    
    private class EncodingContext {
        // the object container that is being encoded
        var dict = Dictionary<String, Any>()
        // the index used for non-keyed objects (encodeObject: vs encodeObject:forKey:)
        var genericKey : UInt = 0
    }

    private static var _classNameMap = Dictionary<String, String>()
    private static var _classNameMapLock = NSLock()
    
    private var _stream : AnyObject
    private var _flags = ArchiverFlags(rawValue: 0)
    private var _containers : Array<EncodingContext> = [EncodingContext()]
    private var _objects : Array<Any> = [NSKeyedArchiveNullObjectReferenceName]
    private var _objRefMap : Dictionary<AnyHashable, UInt32> = [:]
    private var _replacementMap : Dictionary<AnyHashable, Any> = [:]
    private var _classNameMap : Dictionary<String, String> = [:]
    private var _classes : Dictionary<String, _NSKeyedArchiverUID> = [:]
    private var _cache : Array<_NSKeyedArchiverUID> = []

    /// The archiver’s delegate.
    open weak var delegate: NSKeyedArchiverDelegate?
    
    /// The format in which the receiver encodes its data.
    ///
    /// The available formats are `xml` and `binary`.
    open var outputFormat = PropertyListSerialization.PropertyListFormat.binary {
        willSet {
            if outputFormat != .xml &&
                outputFormat != .binary {
                NSUnimplemented()
            }
        }
    }
    
    /// Returns an `NSData` object containing the encoded form of the object graph
    /// whose root object is given.
    ///
    /// - Parameter rootObject: The root of the object graph to archive.
    /// - Returns:              An `NSData` object containing the encoded form of the object graph
    ///                         whose root object is rootObject. The format of the archive is
    ///                         `NSPropertyListBinaryFormat_v1_0`.
    open class func archivedData(withRootObject rootObject: Any) -> Data {
        let data = NSMutableData()
        let keyedArchiver = NSKeyedArchiver(forWritingWith: data)
        
        keyedArchiver.encode(rootObject, forKey: NSKeyedArchiveRootObjectKey)
        keyedArchiver.finishEncoding()
        
        return data._swiftObject
    }
    
    /// Archives an object graph rooted at a given object by encoding it into a data object
    /// then atomically writes the resulting data object to a file at a given path,
    /// and returns a Boolean value that indicates whether the operation was successful.
    ///
    /// - Parameters:
    ///   - rootObject: The root of the object graph to archive.
    ///   - path:       The path of the file in which to write the archive.
    /// - Returns:      `true` if the operation was successful, otherwise `false`.
    open class func archiveRootObject(_ rootObject: Any, toFile path: String) -> Bool {
        var fd : Int32 = -1
        var auxFilePath : String
        var finishedEncoding : Bool = false

        do {
            (fd, auxFilePath) = try _NSCreateTemporaryFile(path)
        } catch _ {
            return false
        }
        
        defer {
            do {
                if finishedEncoding {
                    try _NSCleanupTemporaryFile(auxFilePath, path)
                } else {
                    try FileManager.default.removeItem(atPath: auxFilePath)
                }
            } catch _ {
            }
        }

        let writeStream = _CFWriteStreamCreateFromFileDescriptor(kCFAllocatorSystemDefault, fd)!
        
        if !CFWriteStreamOpen(writeStream) {
            return false
        }
        
        defer { CFWriteStreamClose(writeStream) }
        
        let keyedArchiver = NSKeyedArchiver(output: writeStream)
        
        keyedArchiver.encode(rootObject, forKey: NSKeyedArchiveRootObjectKey)
        keyedArchiver.finishEncoding()
        finishedEncoding = keyedArchiver._flags.contains(.finishedEncoding)
        
        return finishedEncoding
    }
    
    public override convenience init() {
        self.init(forWritingWith: NSMutableData())
    }
    
    private init(output: AnyObject) {
        self._stream = output
        super.init()
    }
    
    /// Returns the archiver, initialized for encoding an archive into a given a mutable-data object.
    ///
    /// When you finish encoding data, you must invoke `finishEncoding()` at which point data
    /// is filled. The format of the archive is `NSPropertyListBinaryFormat_v1_0`.
    ///
    /// - Parameter data: The mutable-data object into which the archive is written.
    public convenience init(forWritingWith data: NSMutableData) {
        self.init(output: data)
    }
    
    private func _writeXMLData(_ plist : NSDictionary) -> Bool {
        var success = false
        
        if let data = self._stream as? NSMutableData {
            let xml : CFData?
            
            xml = _CFPropertyListCreateXMLDataWithExtras(kCFAllocatorSystemDefault, plist)
            if let unwrappedXml = xml {
                data.append(unwrappedXml._swiftObject)
                success = true
            }
        } else {
            success = CFPropertyListWrite(plist, self._stream as! CFWriteStream,
                                          kCFPropertyListXMLFormat_v1_0, 0, nil) > 0
        }
        
        return success
    }
    
    private func _writeBinaryData(_ plist : NSDictionary) -> Bool {
        return __CFBinaryPlistWriteToStream(plist, self._stream) > 0
    }
    
    /// Returns the encoded data for the archiver.
    ///
    /// If encoding has not yet finished, invoking this property calls `finishEncoding()`
    /// and returns the data. If you initialized the keyed archiver with a specific
    /// mutable data instance, then that data is returned by the property after
    /// `finishEncoding()` is called.
    open var encodedData: Data {
        
        if !_flags.contains(.finishedEncoding) {
            finishEncoding()
        }
        
        return (_stream as! NSData)._swiftObject
    }

    /// Instructs the archiver to construct the final data stream.
    ///
    /// No more values can be encoded after this method is called. You must call this method when finished.
    open func finishEncoding() {
        if _flags.contains(.finishedEncoding) {
            return
        }

        var plist = Dictionary<String, Any>()
        var success : Bool

        plist["$archiver"] = NSStringFromClass(type(of: self))
        plist["$version"] = NSKeyedArchivePlistVersion
        plist["$objects"] = self._objects
        plist["$top"] = self._containers[0].dict

        
        
        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.archiverWillFinish(self)
        }

        let nsPlist = plist._bridgeToObjectiveC()
        
        if self.outputFormat == .xml {
            success = _writeXMLData(nsPlist)
        } else {
            success = _writeBinaryData(nsPlist)
        }

        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.archiverDidFinish(self)
        }

        if success {
            let _ = self._flags.insert(.finishedEncoding)
        }
    }

    /// Adds a class translation mapping to `NSKeyedArchiver` whereby instances of a given
    /// class are encoded with a given class name instead of their real class names.
    ///
    /// When encoding, the class’s translation mapping is used only if no translation
    /// is found first in an instance’s separate translation map.
    ///
    /// - Parameters:
    ///   - codedName:  The name of the class that `NSKeyedArchiver` uses in place of `cls`.
    ///   - cls:        The class for which to set up a translation mapping.
    open class func setClassName(_ codedName: String?, for cls: AnyClass) {
        let clsName = String(describing: type(of: cls))
        _classNameMapLock.synchronized {
            _classNameMap[clsName] = codedName
        }
    }
    
    /// Adds a class translation mapping to `NSKeyedArchiver` whereby instances of a given
    /// class are encoded with a given class name instead of their real class names.
    ///
    /// When encoding, the receiver’s translation map overrides any translation
    /// that may also be present in the class’s map.
    ///
    /// - Parameters:
    ///   - codedName:  The name of the class that the archiver uses in place of `cls`.
    ///   - cls:        The class for which to set up a translation mapping.
    open func setClassName(_ codedName: String?, for cls: AnyClass) {
        let clsName = String(describing: type(of: cls))
        _classNameMap[clsName] = codedName
    }
    
    open override var systemVersion: UInt32 {
        return NSKeyedArchiverSystemVersion
    }

    open override var allowsKeyedCoding: Bool {
        return true
    }
    
    private func _validateStillEncoding() -> Bool {
        if self._flags.contains(.finishedEncoding) {
            fatalError("Encoder already finished")
        }
        
        return true
    }
    
    private class func _supportsSecureCoding(_ objv : Any?) -> Bool {
        var supportsSecureCoding : Bool = false
        
        if let secureCodable = objv as? NSSecureCoding {
            supportsSecureCoding = type(of: secureCodable).supportsSecureCoding
        }
        
        return supportsSecureCoding
    }
    
    private func _validateObjectSupportsSecureCoding(_ objv : Any?) {
        if let objv = objv, self.requiresSecureCoding &&
            !NSKeyedArchiver._supportsSecureCoding(objv) {
            fatalError("Secure coding required when encoding \(objv)")
        }
    }
    
    private func _createObjectRefCached(_ uid : UInt32) -> _NSKeyedArchiverUID {
        if uid == 0 {
            return NSKeyedArchiveNullObjectReference
        } else if Int(uid) <= self._cache.count {
            return self._cache[Int(uid) - 1]
        } else {
            let objectRef = _NSKeyedArchiverUID(value: uid)
            self._cache.insert(objectRef, at: Int(uid) - 1)
            return objectRef
        }
    }
    
    /**
        Return a new object identifier, freshly allocated if need be. A placeholder null
        object is associated with the reference.
     */
    private func _referenceObject(_ objv: Any?, conditional: Bool = false) -> _NSKeyedArchiverUID? {
        var uid : UInt32?
        
        if objv == nil {
            return NSKeyedArchiveNullObjectReference
        }
        
        let value = _SwiftValue.store(objv)!
        
        uid = self._objRefMap[value]
        if uid == nil {
            if conditional {
                return nil // object has not been unconditionally encoded
            }
            
            uid = UInt32(self._objects.count)
            
            self._objRefMap[value] = uid
            self._objects.insert(NSKeyedArchiveNullObjectReferenceName, at: Int(uid!))
        }

        return _createObjectRefCached(uid!)
    }
   
    /**
        Returns true if the object has already been encoded.
     */ 
    private func _haveVisited(_ objv: Any?) -> Bool {
        if objv == nil {
            return true // always have a null reference
        } else {
            return self._objRefMap[_SwiftValue.store(objv!)] != nil
        }
    }
    
    /**
        Get or create an object reference, and associate the object.
     */
    private func _addObject(_ objv: Any?) -> _NSKeyedArchiverUID? {
        let haveVisited = _haveVisited(objv)
        let objectRef = _referenceObject(objv)
        
        if !haveVisited {
            _setObject(objv!, forReference: objectRef!)
        }
        
        return objectRef
    }

    private func _pushEncodingContext(_ encodingContext: EncodingContext) {
        self._containers.append(encodingContext)
    }
   
    private func _popEncodingContext() {
        self._containers.removeLast()
    }
    
    private var _currentEncodingContext : EncodingContext {
        return self._containers.last!
    }
  
    /**
        Associate an encoded object or reference with a key in the current encoding context
     */
    private func _setObjectInCurrentEncodingContext(_ object : Any?, forKey key: String? = nil, escape: Bool = true) {
        let encodingContext = self._containers.last!
        var encodingKey : String
 
        if key != nil {
            if escape {
                encodingKey = escapeArchiverKey(key!)
            } else {
                encodingKey = key!
            }
        } else {
            encodingKey = _nextGenericKey()
        }
        
        if encodingContext.dict[encodingKey] != nil {
            NSLog("*** NSKeyedArchiver warning: replacing existing value for key '\(encodingKey)'; probable duplication of encoding keys in class hierarchy")
        }
        
        encodingContext.dict[encodingKey] = object
    }
   
    /**
        The generic key is used for objects that are encoded without a key. It is a per-encoding
        context monotonically increasing integer prefixed with "$".
      */ 
    private func _nextGenericKey() -> String {
        let key = "$" + String(_currentEncodingContext.genericKey)
        _currentEncodingContext.genericKey += 1
        return key
    }

    /**
        Update replacement object mapping
     */
    private func replaceObject(_ object: Any, withObject replacement: Any?) {
        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.archiver(self, willReplace: object, with: replacement)
        }
        
        self._replacementMap[_SwiftValue.store(object)] = replacement
    }
   
    /**
        Returns true if the type cannot be encoded directly (i.e. is a container type)
     */
    private func _isContainer(_ objv: Any?) -> Bool {
        // Note that we check for class equality rather than membership, because
        // their mutable subclasses are as object references
        guard let obj = objv else { return false }
        if obj is String { return false }
        guard let nsObject = obj as? NSObject else { return true }
        return !(nsObject.classForCoder === NSString.self || nsObject.classForCoder === NSNumber.self || nsObject.classForCoder === NSData.self)
    }
   
    /**
        Associates an object with an existing reference
     */ 
    private func _setObject(_ objv: Any, forReference reference : _NSKeyedArchiverUID) {
        let index = Int(reference.value)
        self._objects[index] = objv
    }
    
    /**
        Returns a dictionary describing class metadata for a class
     */
    private func _classDictionary(_ clsv: AnyClass) -> Dictionary<String, Any> {
        func _classNameForClass(_ clsv: AnyClass) -> String? {
            var className : String?
            
            className = classNameForClass(clsv)
            if className == nil {
                className = NSKeyedArchiver.classNameForClass(clsv)
            }
            
            return className
        }

        var classDict : [String:Any] = [:]
        let className = NSStringFromClass(clsv)
        let mappedClassName = _classNameForClass(clsv)
        
        if mappedClassName != nil && mappedClassName != className {
            // If we have a mapped class name, OS X only encodes the mapped name
            classDict["$classname"] = mappedClassName
        } else {
            var classChain : [String] = []
            var classIter : AnyClass? = clsv

            classDict["$classname"] = className
            
            repeat {
                classChain.append(NSStringFromClass(classIter!))
                classIter = _getSuperclass(classIter!)
            } while classIter != nil
            
            classDict["$classes"] = classChain
            
            if let ns = clsv as? NSObject.Type {
                let classHints = ns.classFallbacksForKeyedArchiver()
                if !classHints.isEmpty {
                    classDict["$classhints"] = classHints
                }
            }
        }
        
        return classDict
    }
    
    /**
        Return an object reference for a class

        Because _classDictionary() returns a dictionary by value, and every
        time we bridge to NSDictionary we get a new object (the hash code is
        different), we maintain a private mapping between class name and
        object reference to avoid redundantly encoding class metadata
     */
    private func _classReference(_ clsv: AnyClass) -> _NSKeyedArchiverUID? {
        let className = NSStringFromClass(clsv)
        var classRef = self._classes[className] // keyed by actual class name
        
        if classRef == nil {
            let classDict = _classDictionary(clsv)
            classRef = _addObject(classDict._bridgeToObjectiveC())
            
            if let unwrappedClassRef = classRef {
                self._classes[className] = unwrappedClassRef
            }
        }
        
        return classRef
    }
   
    /**
        Return the object replacing another object (if any)
     */
    private func _replacementObject(_ object: Any?) -> Any? {
        var objectToEncode : Any? = nil // object to encode after substitution

        // nil cannot be mapped
        if object == nil {
            return nil
        }
        
        // check replacement cache
        if let hashable = object as? AnyHashable {
            objectToEncode = self._replacementMap[hashable]
            if objectToEncode != nil {
                return objectToEncode
            }
        }
        
        // object replaced by NSObject.replacementObject(for:)
        // if it is replaced with nil, it cannot be further replaced
        if let ns = objectToEncode as? NSObject {
            objectToEncode = ns.replacementObject(for: self)
            if objectToEncode == nil {
                replaceObject(object!, withObject: nil)
                return nil
            }
        }
        
        if objectToEncode == nil {
            objectToEncode = object
        }
        
        // object replaced by delegate. If the delegate returns nil, nil is encoded
        if let unwrappedDelegate = self.delegate {
            objectToEncode = unwrappedDelegate.archiver(self, willEncode: objectToEncode!)
            replaceObject(object!, withObject: objectToEncode)
        }
    
        return objectToEncode
    }
   
    /**
        Internal function to encode an object. Returns the object reference.
     */
    private func _encodeObject(_ objv: Any?, conditional: Bool = false) -> NSObject? {
        var object : Any? = nil // object to encode after substitution
        var objectRef : _NSKeyedArchiverUID? // encoded object reference
        let haveVisited : Bool

        let _ = _validateStillEncoding()

        haveVisited = _haveVisited(objv)
        object = _replacementObject(objv)
        
        // bridge value types
        object = _SwiftValue.store(object)
        
        objectRef = _referenceObject(object, conditional: conditional)
        guard let unwrappedObjectRef = objectRef else {
            // we can return nil if the object is being conditionally encoded
            return nil
        }

        _validateObjectSupportsSecureCoding(object)

        if !haveVisited {
            var encodedObject : Any

            if _isContainer(object) {
                guard let codable = object as? NSCoding else {
                    fatalError("Object \(String(describing: object)) does not conform to NSCoding")
                }

                let innerEncodingContext = EncodingContext()
                _pushEncodingContext(innerEncodingContext)
                codable.encode(with: self)

                let ns = object as? NSObject
                let cls : AnyClass = ns?.classForKeyedArchiver ?? type(of: object!) as! AnyClass
                
                _setObjectInCurrentEncodingContext(_classReference(cls), forKey: "$class", escape: false)
                _popEncodingContext()
                encodedObject = innerEncodingContext.dict
            } else {
                encodedObject = object!
            }

            _setObject(encodedObject, forReference: unwrappedObjectRef)
        }

        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.archiver(self, didEncode: object)
        }

        return unwrappedObjectRef
    }

    /**
	Encode an object and associate it with a key in the current encoding context.
     */
    private func _encodeObject(_ objv: Any?, forKey key: String?, conditional: Bool = false) {
        if let objectRef = _encodeObject(objv, conditional: conditional) {
            _setObjectInCurrentEncodingContext(objectRef, forKey: key, escape: key != nil)
        }
    }
    
    open override func encode(_ object: Any?) {
        _encodeObject(object, forKey: nil)
    }
    
    open override func encodeConditionalObject(_ object: Any?) {
        _encodeObject(object, forKey: nil, conditional: true)
    }

    /// Encodes a given object and associates it with a given key.
    ///
    /// - Parameters:
    ///   - objv:   The value to encode.
    ///   - key:    The key with which to associate `objv`.
    open override func encode(_ objv: Any?, forKey key: String) {
        _encodeObject(objv, forKey: key, conditional: false)
    }
    
    /// Encodes a reference to a given object and associates it with a given key
    /// only if it has been unconditionally encoded elsewhere in the archive with `encode(_:forKey:)`.
    ///
    /// - Parameters:
    ///   - objv:   The object to encode.
    ///   - key:    The key with which to associate the encoded value.
    open override func encodeConditionalObject(_ objv: Any?, forKey key: String) {
        _encodeObject(objv, forKey: key, conditional: true)
    }
    
    open override func encodePropertyList(_ aPropertyList: Any) {
        if !NSPropertyListClasses.contains(where: { $0 == type(of: aPropertyList) }) {
            fatalError("Cannot encode non-property list type \(type(of: aPropertyList)) as property list")
        }
        encode(aPropertyList)
    }
    
    open func encodePropertyList(_ aPropertyList: Any, forKey key: String) {
        if !NSPropertyListClasses.contains(where: { $0 == type(of: aPropertyList) }) {
            fatalError("Cannot encode non-property list type \(type(of: aPropertyList)) as property list")
        }
        encode(aPropertyList, forKey: key)
    }

    open func _encodePropertyList(_ aPropertyList: Any, forKey key: String? = nil) {
        let _ = _validateStillEncoding()
        _setObjectInCurrentEncodingContext(aPropertyList, forKey: key)
    }

    internal func _encodeValue<T: NSObject>(_ objv: T, forKey key: String? = nil) where T: NSCoding {
        _encodePropertyList(objv, forKey: key)
    }

    private func _encodeValueOfObjCType(_ type: _NSSimpleObjCType, at addr: UnsafeRawPointer) {
        switch type {
        case .ID:
            let objectp = addr.assumingMemoryBound(to: Any.self)
            encode(objectp.pointee)
        case .Class:
            let classp = addr.assumingMemoryBound(to: AnyClass.self)
            encode(NSStringFromClass(classp.pointee)._bridgeToObjectiveC())
        case .Char:
            let charp = addr.assumingMemoryBound(to: CChar.self)
            _encodeValue(NSNumber(value: charp.pointee))
        case .UChar:
            let ucharp = addr.assumingMemoryBound(to: UInt8.self)
            _encodeValue(NSNumber(value: ucharp.pointee))
        case .Int, .Long:
            let intp = addr.assumingMemoryBound(to: Int32.self)
            _encodeValue(NSNumber(value: intp.pointee))
        case .UInt, .ULong:
            let uintp = addr.assumingMemoryBound(to: UInt32.self)
            _encodeValue(NSNumber(value: uintp.pointee))
        case .LongLong:
            let longlongp = addr.assumingMemoryBound(to: Int64.self)
            _encodeValue(NSNumber(value: longlongp.pointee))
        case .ULongLong:
            let ulonglongp = addr.assumingMemoryBound(to: UInt64.self)
            _encodeValue(NSNumber(value: ulonglongp.pointee))
        case .Float:
            let floatp = addr.assumingMemoryBound(to: Float.self)
            _encodeValue(NSNumber(value: floatp.pointee))
        case .Double:
            let doublep = addr.assumingMemoryBound(to: Double.self)
            _encodeValue(NSNumber(value: doublep.pointee))
        case .Bool:
            let boolp = addr.assumingMemoryBound(to: Bool.self)
            _encodeValue(NSNumber(value: boolp.pointee))
        case .CharPtr:
            let charpp = addr.assumingMemoryBound(to: UnsafePointer<Int8>.self)
            encode(NSString(utf8String: charpp.pointee))
        default:
            fatalError("NSKeyedArchiver.encodeValueOfObjCType: unknown type encoding ('\(type.rawValue)')")
        }
    }
    
    open override func encodeValue(ofObjCType typep: UnsafePointer<Int8>, at addr: UnsafeRawPointer) {
        guard let type = _NSSimpleObjCType(UInt8(typep.pointee)) else {
            let spec = String(typep.pointee)
            fatalError("NSKeyedArchiver.encodeValueOfObjCType: unsupported type encoding spec '\(spec)'")
        }
        
        if type == .StructBegin {
            fatalError("NSKeyedArchiver.encodeValueOfObjCType: this archiver cannot encode structs")
        } else if type == .ArrayBegin {
            let scanner = Scanner(string: String(cString: typep))
            
            scanner.scanLocation = 1 // advance past ObJCType
            
            var count : Int = 0
            guard scanner.scanInt(&count) && count > 0 else {
                fatalError("NSKeyedArchiver.encodeValueOfObjCType: array count is missing or zero")
            }
            
            guard let elementType = _NSSimpleObjCType(scanner.scanUpToString(String(_NSSimpleObjCType.ArrayEnd))) else {
                fatalError("NSKeyedArchiver.encodeValueOfObjCType: array type is missing")
            }
            
            encode(_NSKeyedCoderOldStyleArray(objCType: elementType, count: count, at: addr))
        } else {
            return _encodeValueOfObjCType(type, at: addr)
        }
    }

    /// Encodes a given Boolean value and associates it with a given key.
    ///
    /// - Parameters:
    ///   - boolv:  The value to encode.
    ///   - key:    The key with which to associate `boolv`.
    open override func encode(_ boolv: Bool, forKey key: String) {
        _encodeValue(NSNumber(value: boolv), forKey: key)
    }
    

    /// Encodes a given 32-bit integer value and associates it with a given key.
    ///
    /// - Parameters:
    ///   - intv:   The value to encode.
    ///   - key:    The key with which to associate `intv`.
    open override func encode(_ intv: Int32, forKey key: String) {
        _encodeValue(NSNumber(value: intv), forKey: key)
    }
    
    /// Encodes a given 64-bit integer value and associates it with a given key.
    ///
    /// - Parameters:
    ///   - intv:   The value to encode.
    ///   - key:    The key with which to associate `intv`.
    open override func encode(_ intv: Int64, forKey key: String) {
        _encodeValue(NSNumber(value: intv), forKey: key)
    }
    
    /// Encodes a given float value and associates it with a given key.
    ///
    /// - Parameters:
    ///   - realv:  The value to encode.
    ///   - key:    The key with which to associate `realv`.
    open override func encode(_ realv: Float, forKey key: String) {
        _encodeValue(NSNumber(value: realv), forKey: key)
    }
    
    /// Encodes a given double value and associates it with a given key.
    ///
    /// - Parameters:
    ///   - realv:  The value to encode.
    ///   - key:    The key with which to associate `realv`.
    open override func encode(_ realv: Double, forKey key: String) {
        _encodeValue(NSNumber(value: realv), forKey: key)
    }
    
    /// Encodes a given integer value and associates it with a given key.
    ///
    /// - Parameters:
    ///   - intv:   The value to encode.
    ///   - key:    The key with which to associate `intv`.
    open override func encode(_ intv: Int, forKey key: String) {
        _encodeValue(NSNumber(value: intv), forKey: key)
    }

    open override func encode(_ data: Data) {
        // this encodes as a reference to an NSData object rather than encoding inline
        encode(data._nsObject)
    }
    
    /// Encodes a given number of bytes from a given C array of bytes and associates
    /// them with the a given key.
    ///
    /// - Parameters:
    ///   - bytesp: A C array of bytes to encode.
    ///   - lenv:   The number of bytes from `bytesp` to encode.
    ///   - key:    The key with which to associate the encoded value.
    open override func encodeBytes(_ bytesp: UnsafePointer<UInt8>?, length lenv: Int, forKey key: String) {
        // this encodes the data inline
        let data = NSData(bytes: bytesp, length: lenv)
        _encodeValue(data, forKey: key)
    }

    /**
        Helper API for NSArray and NSDictionary that encodes an array of objects,
        creating references as it goes
     */ 
    internal func _encodeArrayOfObjects(_ objects : NSArray, forKey key : String) {
        var objectRefs = [NSObject]()
        
        objectRefs.reserveCapacity(objects.count)
        
        for object in objects {
            let objectRef = _encodeObject(_SwiftValue.store(object))!

            objectRefs.append(objectRef)
        }
        
        _encodeValue(objectRefs._bridgeToObjectiveC(), forKey: key)
    }
    
    /// Indicates whether the archiver requires all archived classes to conform to `NSSecureCoding`.
    ///
    /// If you set the receiver to require secure coding, it will cause a fatal error
    /// if you attempt to archive a class which does not conform to `NSSecureCoding`.
    open override var requiresSecureCoding: Bool {
        get {
            return _flags.contains(.requiresSecureCoding)
        }
        set {
            if newValue {
                let _ = _flags.insert(.requiresSecureCoding)
            } else {
                _flags.remove(.requiresSecureCoding)
            }
        }
    }
    
    /// Returns the class name with which `NSKeyedArchiver` encodes instances of a given class.
    ///
    /// - Parameter cls:    The class for which to determine the translation mapping.
    /// - Returns:          The class name with which `NSKeyedArchiver` encodes instances of `cls`.
    ///                     Returns `nil` if `NSKeyedArchiver` does not have a translation mapping for `cls`.
    open class func classNameForClass(_ cls: AnyClass) -> String? {
        let clsName = String(reflecting: cls)
        var mappedClass : String?
        
        _classNameMapLock.synchronized {
            mappedClass = _classNameMap[clsName]
        }
        
        return mappedClass
    }
    
    /// Returns the class name with which the archiver encodes instances of a given class.
    ///
    /// - Parameter cls:    The class for which to determine the translation mapping.
    /// - Returns:          The class name with which the receiver encodes instances of cls.
    ///                     Returns `nil` if the archiver does not have a translation
    ///                     mapping for `cls`. The class’s separate translation map is not searched.
    open func classNameForClass(_ cls: AnyClass) -> String? {
        let clsName = String(reflecting: cls)
        return _classNameMap[clsName]
    }
}

extension NSKeyedArchiverDelegate {
    func archiver(_ archiver: NSKeyedArchiver, willEncode object: Any) -> Any? {
        // Returning the same object is the same as doing nothing
        return object
    }
    
    func archiver(_ archiver: NSKeyedArchiver, didEncode object: Any?) { }

    func archiver(_ archiver: NSKeyedArchiver, willReplace object: Any?, with newObject: Any?) { }

    func archiverWillFinish(_ archiver: NSKeyedArchiver) { }

    func archiverDidFinish(_ archiver: NSKeyedArchiver) { }

}

/// The `NSKeyedArchiverDelegate` protocol defines the optional methods implemented
/// by delegates of `NSKeyedArchiver` objects.
public protocol NSKeyedArchiverDelegate : class {
    
    /// Informs the delegate that `object` is about to be encoded.
    ///
    /// This method is called after the original object may have replaced itself
    /// with `replacementObject(for:)`.
    ///
    /// This method is called whether or not the object is being encoded conditionally.
    ///
    /// This method is not called for an object once a replacement mapping has been set up
    /// for that object (either explicitly, or because the object has previously been encoded).
    /// This method is also not called when `nil` is about to be encoded.
    ///
    /// - Parameters:
    ///   - archiver:   The archiver that invoked the method.
    ///   - object:     The object that is about to be encoded.
    /// - Returns:      Either object or a different object to be encoded in its stead.
    ///                 The delegate can also modify the coder state. If the delegate
    ///                 returns `nil`, `nil` is encoded.
    func archiver(_ archiver: NSKeyedArchiver, willEncode object: Any) -> Any?
    
    /// Informs the delegate that a given object has been encoded.
    ///
    /// The delegate might restore some state it had modified previously,
    /// or use this opportunity to keep track of the objects that are encoded.
    ///
    /// This method is not called for conditional objects until they are actually encoded (if ever).
    ///
    /// - Parameters:
    ///   - archiver:   The archiver that invoked the method.
    ///   - object:     The object that has been encoded.
    func archiver(_ archiver: NSKeyedArchiver, didEncode object: Any?)
    
    /// Informs the delegate that one given object is being substituted for another given object.
    ///
    /// This method is called even when the delegate itself is doing, or has done,
    /// the substitution. The delegate may use this method if it is keeping track
    /// of the encoded or decoded objects.
    ///
    /// - Parameters:
    ///   - archiver:   The archiver that invoked the method.
    ///   - object:     The object being replaced in the archive.
    ///   - newObject:  The object replacing `object` in the archive.
    func archiver(_ archiver: NSKeyedArchiver, willReplace object: Any?, withObject newObject: Any?)
    

    /// Notifies the delegate that encoding is about to finish.
    ///
    /// - Parameter archiver: The archiver that invoked the method.
    func archiverWillFinish(_ archiver: NSKeyedArchiver)
    

    /// Notifies the delegate that encoding has finished.
    ///
    /// - Parameter archiver: The archiver that invoked the method.
    func archiverDidFinish(_ archiver: NSKeyedArchiver)
}
