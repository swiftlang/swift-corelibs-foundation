// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

// Archives created using the class method archivedRootDataWithObject used this key for the root object in the hierarchy of encoded objects. The NSKeyedUnarchiver class method unarchiveObjectWithData: will look for this root key as well. You can also use it as the key for the root object in your own archives.
public let NSKeyedArchiveRootObjectKey: String = "root"

typealias CFKeyedArchiverUID = CFTypeRef

internal let NSKeyedArchiveNullObjectReference = NSKeyedArchiver._createObjectRef(0)
internal let NSKeyedArchiveNullObjectReferenceName: String = "$null"
internal let NSKeyedArchivePlistVersion = 100000
internal let NSKeyedArchiverSystemVersion : UInt32 = 2000

internal func objectRefGetValue(objectRef : CFKeyedArchiverUID) -> UInt32 {
    assert(objectRef.dynamicType == __NSCFType.self)
    assert(CFGetTypeID(objectRef) == _CFKeyedArchiverUIDGetTypeID())

    return _CFKeyedArchiverUIDGetValue(unsafeBitCast(objectRef, CFKeyedArchiverUIDRef.self))
}

internal func escapeArchiverKey(key: String) -> String {
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
    
    init(_ object: AnyObject) {
        // FIXME can't we check for Hashable directly?
        if let ns = object as? NSObject {
            self.init(hashableObject: ns)
        } else {
            self.init(hashableObject: ObjectIdentifier(object))
        }
    }
    
    var hashValue: Int {
        return _hashValue()
    }
}

internal func ==(x : NSUniqueObject, y : NSUniqueObject) -> Bool {
    return x._equality(y._backing)
}

public class NSKeyedArchiver : NSCoder {
    struct ArchiverFlags : OptionSetType {
        let rawValue : UInt
        
        init(rawValue : UInt) {
            self.rawValue = rawValue
        }
        
        static let None = ArchiverFlags(rawValue: 0)
        static let FinishedEncoding = ArchiverFlags(rawValue : 1)
        static let RequiresSecureCoding = ArchiverFlags(rawValue: 2)
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
    private var _replacementMap : Dictionary<NSUniqueObject, AnyObject> = [:]
    private var _classNameMap : Dictionary<String, String> = [:]
    private var _classes : Dictionary<String, CFKeyedArchiverUID> = [:]
    private var _cache : Array<CFKeyedArchiverUID> = []

    public weak var delegate: NSKeyedArchiverDelegate?
    public var outputFormat = NSPropertyListFormat.BinaryFormat_v1_0 {
        willSet {
            if outputFormat != NSPropertyListFormat.XMLFormat_v1_0 &&
                outputFormat != NSPropertyListFormat.BinaryFormat_v1_0 {
                NSUnimplemented()
            }
        }
    }
    
    public class func archivedDataWithRootObject(rootObject: AnyObject) -> NSData {
        let data = NSMutableData()
        let keyedArchiver = NSKeyedArchiver(forWritingWithMutableData: data)
        
        keyedArchiver.encodeObject(rootObject, forKey: NSKeyedArchiveRootObjectKey)
        keyedArchiver.finishEncoding()
        
        return data
    }
    
    public class func archiveRootObject(rootObject: AnyObject, toFile path: String) -> Bool {
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
                    try NSFileManager.defaultManager().removeItemAtPath(auxFilePath)
                }
            } catch _ {
            }
        }

        let writeStream = _CFWriteStreamCreateFromFileDescriptor(kCFAllocatorSystemDefault, fd)
        
        if !CFWriteStreamOpen(writeStream) {
            return false
        }
        
        let keyedArchiver = NSKeyedArchiver(output: writeStream)
        
        keyedArchiver.encodeObject(rootObject, forKey: NSKeyedArchiveRootObjectKey)
        keyedArchiver.finishEncoding()
        finishedEncoding = keyedArchiver._flags.contains(ArchiverFlags.FinishedEncoding)

        CFWriteStreamClose(writeStream)
        
        return finishedEncoding
    }
    
    private init(output: AnyObject) {
        self._stream = output
        super.init()
    }
    
    public convenience init(forWritingWithMutableData data: NSMutableData) {
        self.init(output: data)
    }
    
    private func _writeXMLData(plist : NSDictionary) -> Bool {
        var success = false
        
        if let data = self._stream as? NSMutableData {
            let xml : CFData?
            
            xml = _CFPropertyListCreateXMLDataWithExtras(kCFAllocatorSystemDefault, plist)
            if let unwrappedXml = xml {
                data.appendData(unwrappedXml._nsObject)
                success = true
            }
        } else {
            success = CFPropertyListWrite(plist, self._stream as! CFWriteStream,
                                          kCFPropertyListOpenStepFormat, 0, nil) > 0
        }
        
        return success;
    }
    
    private func _writeBinaryData(plist : NSDictionary) -> Bool {
        return __CFBinaryPlistWriteToStream(plist, self._stream) > 0
    }
    
    public func finishEncoding() {
        if _flags.contains(ArchiverFlags.FinishedEncoding) {
            return;
        }

        var plist = Dictionary<String, Any>()
        var success : Bool
        
        plist["$archiver"] = NSStringFromClass(self.dynamicType)
        plist["$version"] = NSKeyedArchivePlistVersion
        plist["$objects"] = self._objects
        plist["$top"] = self._containers[0].dict
        
        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.archiverWillFinish(self)
        }

        let nsPlist = plist.bridge()
        
        if self.outputFormat == NSPropertyListFormat.XMLFormat_v1_0 {
            success = _writeXMLData(nsPlist)
        } else {
            success = _writeBinaryData(nsPlist)
        }

        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.archiverDidFinish(self)
        }

        if success {
            self._flags.insert(ArchiverFlags.FinishedEncoding)
        }
    }
    
    public class func setClassName(codedName: String?, forClass cls: AnyClass) {
        let clsName = String(cls.dynamicType)
        _classNameMapLock.synchronized {
            _classNameMap[clsName] = codedName
        }
    }
    
    public func setClassName(codedName: String?, forClass cls: AnyClass) {
        let clsName = String(cls.dynamicType)
        _classNameMap[clsName] = codedName
    }
    
    public override var systemVersion: UInt32 {
        return NSKeyedArchiverSystemVersion
    }

    public override var allowsKeyedCoding: Bool {
        return true
    }
    
    private func _validateStillEncoding() -> Bool {
        if self._flags.contains(ArchiverFlags.FinishedEncoding) {
            fatalError("Encoder already finished")
        }
        
        return true
    }
    
    private class func _supportsSecureCoding(objv : AnyObject?) -> Bool {
        var supportsSecureCoding : Bool = false
        
        if let secureCodable = objv as? NSSecureCoding {
            supportsSecureCoding = secureCodable.dynamicType.supportsSecureCoding()
        }
        
        return supportsSecureCoding
    }
    
    private func _validateObjectSupportsSecureCoding(objv : AnyObject?) {
        if objv != nil &&
            self.requiresSecureCoding &&
            !NSKeyedArchiver._supportsSecureCoding(objv) {
            fatalError("Secure coding required when encoding \(objv)")
        }
    }
    
    private static func _createObjectRef(uid : UInt32) -> CFKeyedArchiverUID {
        return Unmanaged<CFKeyedArchiverUID>.fromOpaque(_CFKeyedArchiverUIDCreate(kCFAllocatorSystemDefault, uid)).takeUnretainedValue()
    }
    
    private func _createObjectRefCached(uid : UInt32) -> CFKeyedArchiverUID {
        if uid == 0 {
            return NSKeyedArchiveNullObjectReference
        } else if Int(uid) <= self._cache.count {
            return self._cache[Int(uid) - 1]
        } else {
            let objectRef = NSKeyedArchiver._createObjectRef(uid)
            self._cache.insert(objectRef, atIndex: Int(uid) - 1)
            return objectRef
        }
    }
    
    /**
        Return a new object identifier, freshly allocated if need be. A placeholder null
        object is associated with the reference.
     */
    private func _referenceObject(objv: AnyObject?, conditional: Bool = false) -> CFKeyedArchiverUID? {
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
            self._objects.insert(NSKeyedArchiveNullObjectReferenceName, atIndex: Int(uid!))
        }

        return _createObjectRefCached(uid!)
    }
   
    /**
        Returns true if the object has already been encoded.
     */ 
    private func _haveVisited(objv: AnyObject?) -> Bool {
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
    private func _addObject(objv: AnyObject?) -> CFKeyedArchiverUID? {
        let haveVisited = _haveVisited(objv)
        let objectRef = _referenceObject(objv)
        
        if !haveVisited {
            _setObject(objv!, forReference: objectRef!)
        }
        
        return objectRef
    }

    private func _pushEncodingContext(encodingContext: EncodingContext) {
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
    private func _setObjectInCurrentEncodingContext(object : AnyObject?, forKey key: String? = nil, escape: Bool = true) {
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
    private func replaceObject(object: AnyObject, withObject replacement: AnyObject?) {
        let oid = NSUniqueObject(object)
        
        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.archiver(self, willReplaceObject: object, withObject: replacement)
        }
        
        self._replacementMap[oid] = replacement
    }
   
    /**
        Returns true if the type cannot be encoded directly (i.e. is a container type)
     */
    private func _isContainer(objv: AnyObject?) -> Bool {
        // Note that we check for class equality rather than membership, because
        // their mutable subclasses are as object references
        let valueType = (objv == nil ||
                         objv is String ||
                         objv!.dynamicType === NSString.self ||
                         objv!.dynamicType === NSNumber.self ||
                         objv!.dynamicType === NSData.self)
        
        return !valueType
    }
   
    /**
        Associates an object with an existing reference
     */ 
    private func _setObject(objv: Any, forReference reference : CFKeyedArchiverUID) {
        let index = Int(objectRefGetValue(reference))
        self._objects[index] = objv
    }
    
    /**
        Returns a dictionary describing class metadata for a class
     */
    private func _classDictionary(clsv: AnyClass) -> Dictionary<String, Any> {
        func _classNameForClass(clsv: AnyClass) -> String? {
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
    private func _classReference(clsv: AnyClass) -> CFKeyedArchiverUID? {
        let className = NSStringFromClass(clsv)
        var classRef = self._classes[className] // keyed by actual class name
        
        if classRef == nil {
            let classDict = _classDictionary(clsv)
            classRef = _addObject(classDict.bridge())
            
            if let unwrappedClassRef = classRef {
                self._classes[className] = unwrappedClassRef
            }
        }
        
        return classRef
    }
   
    /**
        Return the object replacing another object (if any)
     */
    private func _replacementObject(object: AnyObject?) -> AnyObject? {
        var objectToEncode : AnyObject? = nil // object to encode after substitution

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
            objectToEncode = unwrappedDelegate.archiver(self, willEncodeObject: objectToEncode!)
            replaceObject(object!, withObject: objectToEncode)
        }
    
        return objectToEncode
    }
   
    /**
        Internal function to encode an object. Returns the object reference.
     */
    private func _encodeObject(objv: AnyObject?, conditional: Bool = false) -> CFKeyedArchiverUID? {
        var object : AnyObject? = nil // object to encode after substitution
        var objectRef : CFKeyedArchiverUID? // encoded object reference
        let haveVisited : Bool

        _validateStillEncoding()
        
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
                var cls : AnyClass?
                
                _pushEncodingContext(innerEncodingContext)
                codable.encodeWithCoder(self)

                let ns = object as? NSObject
                cls = ns?.classForKeyedArchiver
                if cls == nil {
                    cls = object!.dynamicType
                }
                
                _setObjectInCurrentEncodingContext(_classReference(cls!), forKey: "$class", escape: false)
                _popEncodingContext()
                encodedObject = innerEncodingContext.dict
            } else {
                encodedObject = object!
            }
            
            _setObject(encodedObject, forReference: unwrappedObjectRef)
        }
        
        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.archiver(self, didEncodeObject: object)
        }

        return unwrappedObjectRef
    }

    /**
	Encode an object and associate it with a key in the current encoding context.
     */
    private func _encodeObject(objv: AnyObject?, forKey key: String?, conditional: Bool = false) {
        if let objectRef = _encodeObject(objv, conditional: conditional) {
            _setObjectInCurrentEncodingContext(objectRef, forKey: key, escape: key != nil)
        }
    }
    
    public override func encodeObject(object: AnyObject?) {
        _encodeObject(object, forKey: nil)
    }
    
    public override func encodeConditionalObject(object: AnyObject?) {
        _encodeObject(object, forKey: nil, conditional: true)
    }

    public override func encodeObject(objv: AnyObject?, forKey key: String) {
        _encodeObject(objv, forKey: key, conditional: false)
    }
    
    public override func encodeConditionalObject(objv: AnyObject?, forKey key: String) {
        _encodeObject(objv, forKey: key, conditional: true)
    }
    
    public override func encodePropertyList(aPropertyList: AnyObject) {
        if !NSPropertyListClasses.contains({ $0 == aPropertyList.dynamicType }) {
            fatalError("Cannot encode non-property list type \(aPropertyList.dynamicType) as property list")
        }
        encodeObject(aPropertyList)
    }
    
    public func encodePropertyList(aPropertyList: AnyObject, forKey key: String) {
        if !NSPropertyListClasses.contains({ $0 == aPropertyList.dynamicType }) {
            fatalError("Cannot encode non-property list type \(aPropertyList.dynamicType) as property list")
        }
        encodeObject(aPropertyList, forKey: key)
    }
    
    public func _encodePropertyList(aPropertyList: AnyObject, forKey key: String? = nil) {
        _validateStillEncoding()
        _setObjectInCurrentEncodingContext(aPropertyList, forKey: key)
    }
    
    internal func _encodeValue<T: NSObject where T: NSCoding>(objv: T, forKey key: String? = nil) {
        _encodePropertyList(objv, forKey: key)
    }

    private func _encodeValueOfObjCType(type: _NSSimpleObjCType, at addr: UnsafePointer<Void>) {
        switch type {
        case .ID:
            let objectp = unsafeBitCast(addr, UnsafePointer<AnyObject>.self)
            encodeObject(objectp.memory)
            break
        case .Class:
            let classp = unsafeBitCast(addr, UnsafePointer<AnyClass>.self)
            encodeObject(NSStringFromClass(classp.memory).bridge())
            break
        case .Char:
            let charp = unsafeBitCast(addr, UnsafePointer<CChar>.self)
            _encodeValue(NSNumber(char: charp.memory))
            break
        case .UChar:
            let ucharp = unsafeBitCast(addr, UnsafePointer<UInt8>.self)
            _encodeValue(NSNumber(unsignedChar: ucharp.memory))
            break
        case .Int, .Long:
            let intp = unsafeBitCast(addr, UnsafePointer<Int32>.self)
            _encodeValue(NSNumber(int: intp.memory))
            break
        case .UInt, .ULong:
            let uintp = unsafeBitCast(addr, UnsafePointer<UInt32>.self)
            _encodeValue(NSNumber(unsignedInt: uintp.memory))
            break
        case .LongLong:
            let longlongp = unsafeBitCast(addr, UnsafePointer<Int64>.self)
            _encodeValue(NSNumber(longLong: longlongp.memory))
            break
        case .ULongLong:
            let ulonglongp = unsafeBitCast(addr, UnsafePointer<UInt64>.self)
            _encodeValue(NSNumber(unsignedLongLong: ulonglongp.memory))
            break
        case .Float:
            let floatp = unsafeBitCast(addr, UnsafePointer<Float>.self)
            _encodeValue(NSNumber(float: floatp.memory))
            break
        case .Double:
            let doublep = unsafeBitCast(addr, UnsafePointer<Double>.self)
            _encodeValue(NSNumber(double: doublep.memory))
            break
        case .Bool:
            let boolp = unsafeBitCast(addr, UnsafePointer<Bool>.self)
            _encodeValue(NSNumber(bool: boolp.memory))
            break
        case .CharPtr:
            let charpp = unsafeBitCast(addr, UnsafePointer<UnsafePointer<Int8>>.self)
            encodeObject(NSString(UTF8String: charpp.memory))
            break
        default:
            fatalError("NSKeyedArchiver.encodeValueOfObjCType: unknown type encoding ('\(type.rawValue)')")
            break
        }
    }
    
    public override func encodeValueOfObjCType(typep: UnsafePointer<Int8>, at addr: UnsafePointer<Void>) {
        guard let type = _NSSimpleObjCType(UInt8(typep.memory)) else {
            let spec = String(typep.memory)
            fatalError("NSKeyedArchiver.encodeValueOfObjCType: unsupported type encoding spec '\(spec)'")
        }
        
        if type == .StructBegin {
            fatalError("NSKeyedArchiver.encodeValueOfObjCType: this archiver cannot encode structs")
        } else if type == .ArrayBegin {
            let scanner = NSScanner(string: String.fromCString(typep)!)
            
            scanner.scanLocation = 1 // advance past ObJCType
            
            var count : Int = 0
            guard scanner.scanInteger(&count) && count > 0 else {
                fatalError("NSKeyedArchiver.encodeValueOfObjCType: array count is missing or zero")
            }
            
            guard let elementType = _NSSimpleObjCType(scanner.scanUpToString(String(_NSSimpleObjCType.ArrayEnd))) else {
                fatalError("NSKeyedArchiver.encodeValueOfObjCType: array type is missing")
            }
            
            encodeObject(_NSKeyedCoderOldStyleArray(objCType: elementType, count: count, at: addr))
        } else {
            return _encodeValueOfObjCType(type, at: addr)
        }
    }

    public override func encodeBool(boolv: Bool, forKey key: String) {
        _encodeValue(NSNumber(bool: boolv), forKey: key)
    }
    
    public override func encodeInt(intv: Int32, forKey key: String) {
        _encodeValue(NSNumber(int: intv), forKey: key)
    }
    
    public override func encodeInt32(intv: Int32, forKey key: String) {
        _encodeValue(NSNumber(int: intv), forKey: key)
    }
    
    public override func encodeInt64(intv: Int64, forKey key: String) {
        _encodeValue(NSNumber(longLong: intv), forKey: key)
    }
    
    public override func encodeFloat(realv: Float, forKey key: String) {
        _encodeValue(NSNumber(float: realv), forKey: key)
    }
    
    public override func encodeDouble(realv: Double, forKey key: String) {
        _encodeValue(NSNumber(double: realv), forKey: key)
    }
    
    public override func encodeInteger(intv: Int, forKey key: String) {
        _encodeValue(NSNumber(long: intv), forKey: key)
    }

    public override func encodeDataObject(data: NSData) {
        // this encodes as a reference to an NSData object rather than encoding inline
        encodeObject(data)
    }
    
    public override func encodeBytes(bytesp: UnsafePointer<UInt8>, length lenv: Int, forKey key: String) {
        // this encodes the data inline
        let data = NSData(bytes: bytesp, length: lenv)
        _encodeValue(data, forKey: key)
    }

    /**
        Helper API for NSArray and NSDictionary that encodes an array of objects,
        creating references as it goes
     */ 
    internal func _encodeArrayOfObjects(objects : NSArray, forKey key : String) {
        var objectRefs = [CFKeyedArchiverUID]()
        
        objectRefs.reserveCapacity(objects.count)
        
        for object in objects {
            let objectRef = _encodeObject(object)!

            objectRefs.append(objectRef)
        }
        
        _encodeValue(objectRefs.bridge(), forKey: key)
    }
    
    /**
        Enables secure coding support on this keyed archiver. You do not need to enable
        secure coding on the archiver to enable secure coding on the unarchiver. Enabling
        secure coding on the archiver is a way for you to be sure that all classes that
        are encoded conform with NSSecureCoding (it will throw an exception if a class
        which does not NSSecureCoding is archived). Note that the getter is on the superclass,
        NSCoder. See NSCoder for more information about secure coding.
     */
    public override var requiresSecureCoding: Bool {
        get {
            return _flags.contains(ArchiverFlags.RequiresSecureCoding)
        }
        set {
            if newValue {
                _flags.insert(ArchiverFlags.RequiresSecureCoding)
            } else {
                _flags.remove(ArchiverFlags.RequiresSecureCoding)
            }
        }
    }
    
    // During encoding, the coder first checks with the coder's
    // own table, then if there was no mapping there, the class's.
    public class func classNameForClass(cls: AnyClass) -> String? {
        let clsName = String(reflecting: cls)
        var mappedClass : String?
        
        _classNameMapLock.synchronized {
            mappedClass = _classNameMap[clsName]
        }
        
        return mappedClass
    }
    
    public func classNameForClass(cls: AnyClass) -> String? {
        let clsName = String(reflecting: cls)
        return _classNameMap[clsName]
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
