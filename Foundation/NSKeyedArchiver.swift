// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

// Archives created using the class method archivedRootDataWithObject used this key for the root object in the hierarchy of encoded objects. The NSKeyedUnarchiver class method unarchiveObjectWithData: will look for this root key as well. You can also use it as the key for the root object in your own archives.
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

// NSUniqueObject is a wrapper that allows both hashable and non-hashable objects
// to be used as keys in a dictionary
internal struct NSUniqueObject : Hashable {
    var _backing : Any
    var _hashValue : () -> Int
    var _equality : (Any) -> Bool
    
    init<T: Hashable>(hashableObject: T) {
        self._backing = hashableObject
        self._hashValue = { hashableObject.hashValue }
        self._equality = {
            if let other = $0 as? T {
                return hashableObject == other
            }
            return false
        }
    }
    
    init(_ object: Any) {
        // FIXME can't we check for Hashable directly?
        if let ns = object as? NSObject {
            self.init(hashableObject: ns)
        } else if let ah = object as? AnyHashable {
            self.init(hashableObject: ah)
        } else {
            fatalError("Non-object, non-hashable type used as key")
        }
    }
    
    var hashValue: Int {
        return _hashValue()
    }
}

internal func ==(x : NSUniqueObject, y : NSUniqueObject) -> Bool {
    return x._equality(y._backing)
}

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
    private var _objRefMap : Dictionary<NSUniqueObject, UInt32> = [:]
    private var _replacementMap : Dictionary<NSUniqueObject, Any> = [:]
    private var _classNameMap : Dictionary<String, String> = [:]
    private var _classes : Dictionary<String, _NSKeyedArchiverUID> = [:]
    private var _cache : Array<_NSKeyedArchiverUID> = []

    open weak var delegate: NSKeyedArchiverDelegate?
    open var outputFormat = PropertyListSerialization.PropertyListFormat.binary {
        willSet {
            if outputFormat != PropertyListSerialization.PropertyListFormat.xml &&
                outputFormat != PropertyListSerialization.PropertyListFormat.binary {
                NSUnimplemented()
            }
        }
    }
    
    open class func archivedData(withRootObject rootObject: Any) -> Data {
        let data = NSMutableData()
        let keyedArchiver = NSKeyedArchiver(forWritingWith: data)
        
        keyedArchiver.encode(rootObject, forKey: NSKeyedArchiveRootObjectKey)
        keyedArchiver.finishEncoding()
        
        return data._swiftObject
    }
    
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
        
        let keyedArchiver = NSKeyedArchiver(output: writeStream)
        
        keyedArchiver.encode(rootObject, forKey: NSKeyedArchiveRootObjectKey)
        keyedArchiver.finishEncoding()
        finishedEncoding = keyedArchiver._flags.contains(ArchiverFlags.finishedEncoding)

        CFWriteStreamClose(writeStream)
        
        return finishedEncoding
    }
    
    public override init() {
        NSUnimplemented()
    }
    
    private init(output: AnyObject) {
        self._stream = output
        super.init()
    }
    
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
    
    
    /// If encoding has not yet finished, then invoking this property will call finishEncoding and return the data. If you initialized the keyed archiver with a specific mutable data instance, then it will be returned from this property after finishEncoding is called.
    open var encodedData: Data {
        NSUnimplemented()
    }

    open func finishEncoding() {
        if _flags.contains(ArchiverFlags.finishedEncoding) {
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
        
        if self.outputFormat == PropertyListSerialization.PropertyListFormat.xml {
            success = _writeXMLData(nsPlist)
        } else {
            success = _writeBinaryData(nsPlist)
        }

        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.archiverDidFinish(self)
        }

        if success {
            let _ = self._flags.insert(ArchiverFlags.finishedEncoding)
        }
    }

    open class func setClassName(_ codedName: String?, for cls: AnyClass) {
        let clsName = String(describing: type(of: cls))
        _classNameMapLock.synchronized {
            _classNameMap[clsName] = codedName
        }
    }
    
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
        if self._flags.contains(ArchiverFlags.finishedEncoding) {
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
        if objv != nil &&
            self.requiresSecureCoding &&
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
        
        let oid = NSUniqueObject(objv!)

        uid = self._objRefMap[oid]
        if uid == nil {
            if conditional {
                return nil // object has not been unconditionally encoded
            }
            
            uid = UInt32(self._objects.count)
            
            self._objRefMap[oid] = uid
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
            let oid = NSUniqueObject(objv!)

            return self._objRefMap[oid] != nil
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
        let oid = NSUniqueObject(object)
        
        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.archiver(self, willReplace: object, with: replacement)
        }
        
        self._replacementMap[oid] = replacement
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
        return !(type(of: nsObject) === NSString.self || type(of: nsObject) === NSNumber.self || type(of: nsObject) === NSData.self)
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
                if classHints.count > 0 {
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
        objectToEncode = self._replacementMap[NSUniqueObject(object!)]
        if objectToEncode != nil {
            return objectToEncode
        }
        
        // object replaced by NSObject.replacementObjectForKeyedArchiver
        // if it is replaced with nil, it cannot be further replaced
        if objectToEncode == nil {
            let ns = object as? NSObject
            objectToEncode = ns?.replacementObjectForKeyedArchiver(self)
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
                    fatalError("Object \(object) does not conform to NSCoding")
                }

                let innerEncodingContext = EncodingContext()
                _pushEncodingContext(innerEncodingContext)
                codable.encode(with: self)

                guard let ns = object as? NSObject else {
                    fatalError("Attempt to encode non-NSObject");
                }

                let cls : AnyClass = ns.classForKeyedArchiver ?? type(of: object) as! AnyClass

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

    open override func encode(_ objv: Any?, forKey key: String) {
        _encodeObject(objv, forKey: key, conditional: false)
    }
    
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
            let objectp = unsafeBitCast(addr, to: UnsafePointer<Any>.self)
            encode(objectp.pointee)
            break
        case .Class:
            let classp = unsafeBitCast(addr, to: UnsafePointer<AnyClass>.self)
            encode(NSStringFromClass(classp.pointee)._bridgeToObjectiveC())
            break
        case .Char:
            let charp = unsafeBitCast(addr, to: UnsafePointer<CChar>.self)
            _encodeValue(NSNumber(value: charp.pointee))
            break
        case .UChar:
            let ucharp = unsafeBitCast(addr, to: UnsafePointer<UInt8>.self)
            _encodeValue(NSNumber(value: ucharp.pointee))
            break
        case .Int, .Long:
            let intp = unsafeBitCast(addr, to: UnsafePointer<Int32>.self)
            _encodeValue(NSNumber(value: intp.pointee))
            break
        case .UInt, .ULong:
            let uintp = unsafeBitCast(addr, to: UnsafePointer<UInt32>.self)
            _encodeValue(NSNumber(value: uintp.pointee))
            break
        case .LongLong:
            let longlongp = unsafeBitCast(addr, to: UnsafePointer<Int64>.self)
            _encodeValue(NSNumber(value: longlongp.pointee))
            break
        case .ULongLong:
            let ulonglongp = unsafeBitCast(addr, to: UnsafePointer<UInt64>.self)
            _encodeValue(NSNumber(value: ulonglongp.pointee))
            break
        case .Float:
            let floatp = unsafeBitCast(addr, to: UnsafePointer<Float>.self)
            _encodeValue(NSNumber(value: floatp.pointee))
            break
        case .Double:
            let doublep = unsafeBitCast(addr, to: UnsafePointer<Double>.self)
            _encodeValue(NSNumber(value: doublep.pointee))
            break
        case .Bool:
            let boolp = unsafeBitCast(addr, to: UnsafePointer<Bool>.self)
            _encodeValue(NSNumber(value: boolp.pointee))
            break
        case .CharPtr:
            let charpp = unsafeBitCast(addr, to: UnsafePointer<UnsafePointer<Int8>>.self)
            encode(NSString(utf8String: charpp.pointee))
            break
        default:
            fatalError("NSKeyedArchiver.encodeValueOfObjCType: unknown type encoding ('\(type.rawValue)')")
            break
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
            guard scanner.scanInteger(&count) && count > 0 else {
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

    open override func encode(_ boolv: Bool, forKey key: String) {
        _encodeValue(NSNumber(value: boolv), forKey: key)
    }
    

    open override func encode(_ intv: Int32, forKey key: String) {
        _encodeValue(NSNumber(value: intv), forKey: key)
    }
    
    open override func encode(_ intv: Int64, forKey key: String) {
        _encodeValue(NSNumber(value: intv), forKey: key)
    }
    
    open override func encode(_ realv: Float, forKey key: String) {
        _encodeValue(NSNumber(value: realv), forKey: key)
    }
    
    open override func encode(_ realv: Double, forKey key: String) {
        _encodeValue(NSNumber(value: realv), forKey: key)
    }
    
    open override func encode(_ intv: Int, forKey key: String) {
        _encodeValue(NSNumber(value: intv), forKey: key)
    }

    open override func encode(_ data: Data) {
        // this encodes as a reference to an NSData object rather than encoding inline
        encode(data._nsObject)
    }
    
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
    
    /**
        Enables secure coding support on this keyed archiver. You do not need to enable
        secure coding on the archiver to enable secure coding on the unarchiver. Enabling
        secure coding on the archiver is a way for you to be sure that all classes that
        are encoded conform with NSSecureCoding (it will throw an exception if a class
        which does not NSSecureCoding is archived). Note that the getter is on the superclass,
        NSCoder. See NSCoder for more information about secure coding.
     */
    open override var requiresSecureCoding: Bool {
        get {
            return _flags.contains(ArchiverFlags.requiresSecureCoding)
        }
        set {
            if newValue {
                let _ = _flags.insert(ArchiverFlags.requiresSecureCoding)
            } else {
                _flags.remove(ArchiverFlags.requiresSecureCoding)
            }
        }
    }
    
    // During encoding, the coder first checks with the coder's
    // own table, then if there was no mapping there, the class's.
    open class func classNameForClass(_ cls: AnyClass) -> String? {
        let clsName = String(reflecting: cls)
        var mappedClass : String?
        
        _classNameMapLock.synchronized {
            mappedClass = _classNameMap[clsName]
        }
        
        return mappedClass
    }
    
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
    func archiver(_ archiver: NSKeyedArchiver, willEncode object: Any) -> Any?
    
    // Informs the delegate that the given object has been encoded.  The delegate
    // might restore some state it had fiddled previously, or use this to keep
    // track of the objects which are encoded.  The object may be nil.  Not called
    // for conditional objects until they are really encoded (if ever).
    func archiver(_ archiver: NSKeyedArchiver, didEncode object: Any?)
    
    // Informs the delegate that the newObject is being substituted for the
    // object. This is also called when the delegate itself is doing/has done
    // the substitution. The delegate may use this method if it is keeping track
    // of the encoded or decoded objects.
    func archiver(_ archiver: NSKeyedArchiver, willReplace object: Any?, withObject newObject: Any?)
    
    // Notifies the delegate that encoding is about to finish.
    func archiverWillFinish(_ archiver: NSKeyedArchiver)
    
    // Notifies the delegate that encoding has finished.
    func archiverDidFinish(_ archiver: NSKeyedArchiver)
}
