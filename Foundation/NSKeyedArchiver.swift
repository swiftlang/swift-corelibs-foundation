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

private let NSKeyedArchiveNullObjectReference = NSKeyedArchiver._createObjectRef(0)
private let NSKeyedArchiveNullObjectReferenceName: NSString = "$null"
private let NSKeyedArchivePlistVersion = 100000
private let NSKeyedArchiverSystemVersion : UInt32 = 2000

struct NSKeyedArchiverFlags : OptionSetType {
    let rawValue : UInt
    
    init(rawValue : UInt) {
        self.rawValue = rawValue
    }
    
    static let None = NSKeyedArchiverFlags(rawValue: 0)
    static let FinishedEncoding = NSKeyedArchiverFlags(rawValue : 1)
    static let RequiresSecureCoding = NSKeyedArchiverFlags(rawValue: 2)
}

typealias CFKeyedArchiverUID = CFTypeRef

private func objectRefGetValue(objectRef : CFKeyedArchiverUID) -> UInt32 {
    return _CFKeyedArchiverUIDGetValue(unsafeBitCast(objectRef, CFKeyedArchiverUIDRef.self))
}

private class NSKeyedEncodingContext {
    // the object container that is being encoded
    var dict = Dictionary<String, Any>()
    // the index used for non-keyed objects (encodeObject: vs encodeObject:forKey:)
    var genericKey : UInt = 0
}

// NSUniqueObject is a wrapper that allows both hashable and non-hashable objects
// to be used as keys in a dictionary
private struct NSUniqueObject : Hashable {
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

private func ==(x : NSUniqueObject, y : NSUniqueObject) -> Bool {
    return x._equality(y._backing)
}

public class NSKeyedArchiver : NSCoder {
    
    private static var _classNameMap = Dictionary<String, String>()
    
    private var _stream : AnyObject
    private var _flags = NSKeyedArchiverFlags(rawValue: 0)
    private var _containers : Array<NSKeyedEncodingContext> = [NSKeyedEncodingContext()]
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
        // FIXME write to temp file first
        // FIXME CFWriteStreamCreateWithFile() seems to be broken
        let url = NSURL(fileURLWithPath: path)
        let writeStream = CFWriteStreamCreateWithFile(kCFAllocatorSystemDefault, url._cfObject)
        
        if !CFWriteStreamOpen(writeStream) {
            return false
        }
        
        let keyedArchiver = NSKeyedArchiver(output: writeStream)
        
        keyedArchiver.encodeObject(rootObject, forKey: NSKeyedArchiveRootObjectKey)
        keyedArchiver.finishEncoding()
        
        CFWriteStreamClose(writeStream)
        
        return keyedArchiver._flags.contains(NSKeyedArchiverFlags.FinishedEncoding)
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
                                          CFPropertyListFormat.XMLFormat_v1_0, 0, nil) > 0
        }
        
        return success;
    }
    
    private func _writeBinaryData(plist : NSDictionary) -> Bool {
        return __CFBinaryPlistWriteToStream(plist, self._stream) > 0
    }
    
    public func finishEncoding() {
        if _flags.contains(NSKeyedArchiverFlags.FinishedEncoding) {
            return;
        }

        var plist = Dictionary<String, Any>()
        var success : Bool
        
        plist["$archiver"] = String(self.dynamicType)
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
            self._flags.insert(NSKeyedArchiverFlags.FinishedEncoding)
        }
    }
    
    public class func setClassName(codedName: String?, forClass cls: AnyClass) {
        let clsName = String(cls.dynamicType)
        _classNameMap[clsName] = codedName
    }
    
    public func setClassName(codedName: String?, forClass cls: AnyClass) {
        let clsName = String(cls.dynamicType)
        _classNameMap[clsName] = codedName
    }
    
    public override var systemVersion: UInt32 {
        return NSKeyedArchiverSystemVersion
    }

    public override var allowsKeyedCoding: Bool {
        get {
            return true
        }
    }
    
    private func _validateStillEncoding() -> Bool {
        if self._flags.contains(NSKeyedArchiverFlags.FinishedEncoding) {
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
        if self.requiresSecureCoding && !NSKeyedArchiver._supportsSecureCoding(objv) {
            fatalError("Secure coding required when encoding \(objv)")
        }
    }
    
    private class func _createObjectRef(uid : UInt32) -> CFKeyedArchiverUID {
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
    
    private class func _escapeKey(key: String) -> String {
        if key.hasPrefix("$") {
            return "$" + key
        } else {
            return key
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

    private func _pushEncodingContext(encodingContext: NSKeyedEncodingContext) {
        self._containers.append(encodingContext)
    }
    
    private func _popEncodingContext() {
        self._containers.removeLast()
    }
    
    private var _currentEncodingContext : NSKeyedEncodingContext {
        return self._containers.last!
    }
   
    private func _setObjectInCurrentEncodingContext(object : AnyObject?, forKey key: String, escape: Bool = true) {
        let encodingContext = self._containers.last!
        
        if escape {
            let escapedKey = NSKeyedArchiver._escapeKey(key)
            encodingContext.dict[escapedKey] = object
        } else {
            encodingContext.dict[key] = object
        }
    }
    
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
        Returns true if the type can be encoded directly (i.e. is not a container type)
     */ 
    private func _isContainer(objv: AnyObject?) -> Bool {
        return !(objv == nil ||
            objv is String ||
            objv is NSString ||
            objv is NSNumber ||
            objv is NSData)
    }
   
    /**
        Associates an object with an existing reference
     */ 
    private func _setObject(objv: Any, forReference reference : CFKeyedArchiverUID) {
        let index = Int(objectRefGetValue(reference))
        self._objects[index] = objv
    }
    
    /**
        Returns a dictionary describing class metadata for clsv
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
        Return the object replacing another object
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
            return nil
        }
        
        _validateObjectSupportsSecureCoding(object)
    
        if !haveVisited {
            var encodedObject : Any? = nil

            if _isContainer(object) {
                if let codable = object as? NSCoding {
                    let innerEncodingContext = NSKeyedEncodingContext()
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
                }
            } else {
                encodedObject = object!
            }
            
            if encodedObject != nil {
                _setObject(encodedObject!, forReference: unwrappedObjectRef)
            }
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
        let objectRef = _encodeObject(objv, conditional: conditional)

        if let unwrappedObjectRef = objectRef {
            var unwrappedKey = key
            if unwrappedKey == nil {
                unwrappedKey = _nextGenericKey()
            }
            
            _setObjectInCurrentEncodingContext(unwrappedObjectRef, forKey: unwrappedKey!, escape: key != nil)
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
    
    private func _encodeValue<T: NSObject where T: NSCoding>(objv: T, forKey key: String) {
        _validateStillEncoding()
        _setObjectInCurrentEncodingContext(objv, forKey: key)
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
        let data = NSData(bytes: bytesp, length: lenv)
        _encodeValue(data, forKey: key)
    }
    
    internal func _encodeArrayOfObjects(objects : NSArray, forKey key : String) {
        var objectRefs = [CFKeyedArchiverUID]()
        
        objectRefs.reserveCapacity(objects.count)
        
        for object in objects {
            let objectRef = _encodeObject(object)!

            objectRefs.append(objectRef)
        }
        
        _encodeValue(objectRefs.bridge(), forKey: key)
    }
    
    // Enables secure coding support on this keyed archiver. You do not need to enable secure coding on the archiver to enable secure coding on the unarchiver. Enabling secure coding on the archiver is a way for you to be sure that all classes that are encoded conform with NSSecureCoding (it will throw an exception if a class which does not NSSecureCoding is archived). Note that the getter is on the superclass, NSCoder. See NSCoder for more information about secure coding.
    public override var requiresSecureCoding: Bool {
        get {
            return _flags.contains(NSKeyedArchiverFlags.RequiresSecureCoding)
        }
        set {
            if newValue {
                _flags.insert(NSKeyedArchiverFlags.RequiresSecureCoding)
            } else {
                _flags.remove(NSKeyedArchiverFlags.RequiresSecureCoding)
            }
        }
    }
    
    // During encoding, the coder first checks with the coder's
    // own table, then if there was no mapping there, the class's.
    public class func classNameForClass(cls: AnyClass) -> String? {
        let clsName = _typeName(cls)
        return _classNameMap[clsName]
    }
    
    public func classNameForClass(cls: AnyClass) -> String? {
        let clsName = _typeName(cls)
        return _classNameMap[clsName]
    }
}

struct NSKeyedUnarchiverFlags : OptionSetType {
    let rawValue : UInt
    
    init(rawValue : UInt) {
        self.rawValue = rawValue
    }
    
    static let None = NSKeyedUnarchiverFlags(rawValue: 0)
    static let FinishedDecoding = NSKeyedUnarchiverFlags(rawValue : 1)
    static let RequiresSecureCoding = NSKeyedUnarchiverFlags(rawValue: 2)
}

private class NSKeyedDecodingContext {
    private var dict : Dictionary<String, Any>
    private var genericKey : UInt = 0
    private var allowedClasses : NSSet?
    
    init(_ dict : Dictionary<String, Any>, allowedClasses classes : NSSet? = nil) {
        self.dict = dict
        self.allowedClasses = classes
    }
}

public class NSKeyedUnarchiver : NSCoder {
    private static var _classNameMap : Dictionary<String, AnyClass> = [:]

    public weak var delegate: NSKeyedUnarchiverDelegate?

    private var _stream : AnyObject
    private var _flags = NSKeyedUnarchiverFlags(rawValue: 0)
    private var _containers : Array<NSKeyedDecodingContext>? = nil
    private var _objects : Array<Any> = [NSKeyedArchiveNullObjectReferenceName]
    private var _objRefMap : Dictionary<UInt32, AnyObject> = [:]
    private var _replacementMap : Dictionary<NSUniqueObject, AnyObject> = [:]
    private var _classNameMap : Dictionary<String, AnyClass> = [:]
    private var _classes : Dictionary<UInt32, AnyClass> = [:]
    private var _cache : Array<CFKeyedArchiverUID> = []
    private var _error : NSError? = nil

    internal override var error: NSError? {
        return _error
    }

    public class func unarchiveObjectWithData(data: NSData) -> AnyObject? {
        do {
            return try unarchiveTopLevelObjectWithData(data)
        } catch {
        }
        return nil
    }
    
    public class func unarchiveObjectWithFile(path: String) -> AnyObject? {
        let url = NSURL(fileURLWithPath: path)
        let readStream = CFReadStreamCreateWithFile(kCFAllocatorSystemDefault, url._cfObject)
        var root : AnyObject? = nil

        if !CFReadStreamOpen(readStream) {
            return nil
        }
        
        if let keyedUnarchiver = NSKeyedUnarchiver(stream: readStream) {
            do {
                try root = keyedUnarchiver.decodeTopLevelObjectForKey(NSKeyedArchiveRootObjectKey)
                keyedUnarchiver.finishDecoding()
            } catch {
            }
        }
        
        CFReadStreamClose(readStream)

        return root
    }
    
    public convenience init?(forReadingWithData data: NSData) {
        self.init(stream: data)
    }
    
    private init?(stream: AnyObject) {
        self._stream = stream
        super.init()
        
        do {
            try _readPropertyList()
        } catch let error as NSError {
            if let debugDescription = error.userInfo["NSDebugDescription"] {
                print("*** NSKeyedUnarchiver.init: \(debugDescription)")
            }
        } catch {
            return nil
        }
    }

    private func _readPropertyList() throws {
        var plist : Any? = nil
        var format = NSPropertyListFormat.BinaryFormat_v1_0
        
        // FIXME this implementation reads the entire property list into memory
        // which will not scale for large archives. We should support incremental
        // unarchiving, but that will be a considerable amount of work.
        
        if let data = self._stream as? NSData {
            try plist = NSPropertyListSerialization.propertyListWithData(data, options: NSPropertyListMutabilityOptions.Immutable, format: &format)
        } else {
            try plist = NSPropertyListSerialization.propertyListWithStream(self._stream as! CFReadStream,
                                                                           length: 0,
                                                                           options: NSPropertyListMutabilityOptions.Immutable,
                                                                           format: &format)
        }
        
        guard let unwrappedPlist = plist as? Dictionary<String, Any> else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Unable to read archive. The data may be corrupt."
                ])
        }
        
        let archiver = unwrappedPlist["$archiver"] as? String
        if archiver != String(NSKeyedArchiver.self) {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Unknown archiver. The data may be corrupt."
                ])
        }
        
        let version = unwrappedPlist["$version"] as? NSNumber
        if version?.intValue != Int32(NSKeyedArchivePlistVersion) {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Unknown archive version. The data may be corrupt."
                ])
        }
        
        let top = unwrappedPlist["$top"] as? Dictionary<String, Any>
        let objects = unwrappedPlist["$objects"] as? Array<Any>
        
        if top == nil || objects == nil {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.PropertyListReadCorruptError.rawValue, userInfo: [
                "NSDebugDescription" : "Unable to read archive contents. The data may be corrupt."
                ])
        }
        
        self._objects = objects!
        self._containers = [NSKeyedDecodingContext(top!)]
    }

    private class func _unescapeKey(key : String) -> String {
        if key.hasPrefix("$") {
            return key.bridge().substringFromIndex(1)
        }
        
        return key
    }
    
    private func _pushDecodingContext(decodingContext: NSKeyedDecodingContext) {
        self._containers!.append(decodingContext)
    }
    
    private func _popDecodingContext() {
        self._containers!.removeLast()
    }
    
    private var _currentDecodingContext : NSKeyedDecodingContext {
        return self._containers!.last!
    }
    
    private func _nextGenericKey() -> String {
        let key = "$" + String(_currentDecodingContext.genericKey)
        _currentDecodingContext.genericKey += 1
        return key
    }
    
    private func _objectInCurrentDecodingContext<T>(forKey key: String?) -> T? {
        var unwrappedKey = key
        
        if key != nil {
            unwrappedKey = NSKeyedUnarchiver._unescapeKey(key!)
        } else {
            unwrappedKey = _nextGenericKey()
        }
        
        return _currentDecodingContext.dict[unwrappedKey!] as? T
    }

    /**
        Dereferences, but does not decode, an object reference
     */
    private func _dereferenceObjectReference(unwrappedObjectRef: CFKeyedArchiverUID) -> Any? {
        let uid = Int(objectRefGetValue(unwrappedObjectRef))
            
        guard uid < self._objects.count else {
            return nil
        }
        
        if uid == 0 {
            return nil
        }
        
        return self._objects[uid]
    }
    
    public override var systemVersion: UInt32 {
        return NSKeyedArchiverSystemVersion
    }

    public override var allowsKeyedCoding: Bool {
        get {
            return true
        }
    }
    
    private func _validateStillDecoding() -> Bool {
        if self._flags.contains(NSKeyedUnarchiverFlags.FinishedDecoding) {
            fatalError("Decoder already finished")
        }
        
        return true
    }
    
    private class func _supportsSecureCoding(clsv : AnyClass) -> Bool {
        if let secureCodable = clsv as? NSSecureCoding.Type {
            return secureCodable.supportsSecureCoding()
        }
        
        return false
    }
    
    private func _isClassAllowed(assertedClass: AnyClass?, whitelist: NSSet?) -> Bool {
        if assertedClass == nil {
            return false
        }
        
        if _flags.contains(NSKeyedUnarchiverFlags.RequiresSecureCoding) {
            if let unwrappedWhitelist = whitelist {
                for whitelistedClass in unwrappedWhitelist {
                    if whitelistedClass as? AnyClass == assertedClass {
                        return true
                    }
                }
            }
            
            fatalError("Value was of unexpected class \(assertedClass!)")
        } else {
            return true
        }
    }
    
    private func _validateAndMapClassDictionary(classDict: Dictionary<String, Any>?, whitelist: NSSet?, inout classToConstruct: AnyClass?) -> Bool {
        classToConstruct = nil
        
        func _classForClassName(codedName: String) -> AnyClass? {
            var aClass : AnyClass?
            
            aClass = classForClassName(codedName)
            if aClass == nil {
                aClass = NSKeyedUnarchiver.classForClassName(codedName)
            }
            if aClass == nil {
                aClass = NSClassFromString(codedName)
            }
            
            return aClass
        }

        guard let unwrappedClassDict = classDict else {
            return false
        }
        
        // TODO is it required to validate the superclass hierarchy?
        let assertedClassName = unwrappedClassDict["$classname"] as? String
        let assertedClassHints = unwrappedClassDict["$classhints"] as? [String]
        let assertedClasses = unwrappedClassDict["$classes"] as? [String]

        if assertedClassName != nil {
            let assertedClass : AnyClass? = _classForClassName(assertedClassName!)
            if _isClassAllowed(assertedClass, whitelist: whitelist) {
                classToConstruct = assertedClass
                return true
            }
        }
        
        if assertedClassHints != nil {
            for assertedClassHint in assertedClassHints! {
                // FIXME check whether class hints should be subject to mapping or not
                let assertedClass : AnyClass? = NSClassFromString(assertedClassHint)
                if _isClassAllowed(assertedClass, whitelist: whitelist) {
                    classToConstruct = assertedClass
                    return true
                }
            }
        }
        
        if assertedClassName != nil {
            if let unwrappedDelegate = self.delegate {
                classToConstruct = unwrappedDelegate.unarchiver(self, cannotDecodeObjectOfClassName: assertedClassName!,
                                                                originalClasses: assertedClasses != nil ? assertedClasses! : [])
                if classToConstruct != nil {
                    return true
                }
            }
        }

        return false
    }
   
    /**
        Validate a class reference against an optional class whitelist, and return the class object
        if it's allowed
     */
    private func _validateAndMapClassReference(classReference: CFKeyedArchiverUID) throws -> AnyClass? {
        let whitelist : NSSet? = _currentDecodingContext.allowedClasses
        let classUid = objectRefGetValue(classReference)
        var classToConstruct : AnyClass? = _classes[classUid]

        if classToConstruct == nil {
            let classDict = _dereferenceObjectReference(classReference) as? Dictionary<String, Any>
            
            if !_validateAndMapClassDictionary(classDict!, whitelist: whitelist, classToConstruct: &classToConstruct) {
                try _throwError(NSCocoaError.CoderReadCorruptError, withDescription: "Invalid class \(classDict). The data may be corrupt.")
            }
        
            _classes[classUid] = classToConstruct
        }
        
        return classToConstruct
    }

    /**
        Returns true if objectOrReference represents a reference to another object in the archive
     */
    internal class func _isReference(objectOrReference : Any?) -> Bool {
        if let cf = objectOrReference as? AnyObject {
            return CFGetTypeID(cf) == _CFKeyedArchiverUIDGetTypeID()
        } else {
            return false
        }
    }
    
    private func _cachedObjectForReference(objectRef: CFKeyedArchiverUID) -> AnyObject? {
        return self._objRefMap[objectRefGetValue(objectRef)]
    }
    
    private func _cacheObject(object: AnyObject, forReference objectRef: CFKeyedArchiverUID) {
        self._objRefMap[objectRefGetValue(objectRef)] = object
    }
    
    private func _isNullObjectReference(objectRef: CFKeyedArchiverUID) -> Bool {
        return objectRefGetValue(objectRef) == 0
    }
    
    /**
        Returns true if the object is a dictionary representing a object rather than a value type
      */
    private func _isContainer(object: Any) -> Bool {
        guard let dict = object as? Dictionary<String, Any> else {
            return false
        }
        
        let classRef = dict["$class"]
        
        return NSKeyedUnarchiver._isReference(classRef)
    }
   

    /**
        Replace object with another one
     */ 
    private func replaceObject(object: AnyObject, withObject replacement: AnyObject) {
        let oid = NSUniqueObject(object)
        
        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.unarchiver(self, willReplaceObject: object, withObject: replacement)
        }
        
        self._replacementMap[oid] = replacement
    }
    
    private func _throwError(code: NSCocoaError, withDescription description: String) throws -> AnyObject? {
        throw NSError(domain: NSCocoaErrorDomain, code: code.rawValue, userInfo: [
            "NSDebugDescription" : description
            ])
    }
    
    private func _replacementObject(decodedObject: AnyObject?) -> AnyObject? {
        var object : AnyObject? = nil // object to encode after substitution
        
        // nil cannot be mapped
        if decodedObject == nil {
            return nil
        }
        
        // check replacement cache
        object = self._replacementMap[NSUniqueObject(decodedObject!)]
        if object != nil {
            return object
        }
        
        // object replaced by delegate. If the delegate returns nil, nil is encoded
        if let unwrappedDelegate = self.delegate {
            object = unwrappedDelegate.unarchiver(self, didDecodeObject: decodedObject!)
            if object != nil {
                replaceObject(decodedObject!, withObject: object!)
                return object
            }
        }
        
        return decodedObject
    }
    
    private func _validateClassSupportsSecureCoding(classToConstruct : AnyClass?) -> Bool {
        var supportsSecureCoding : Bool = false
        
        if let secureDecodableClass = classToConstruct as? NSSecureCoding.Type {
            supportsSecureCoding = secureDecodableClass.supportsSecureCoding()
        }
        
        if self.requiresSecureCoding && !supportsSecureCoding {
            fatalError("Archiver \(self) requires secure coding but class \(classToConstruct) does not support it")
        }
        
        return supportsSecureCoding
    }

    /**
        Decode an object for the given reference, validating class against provided whitelist.
     */
    private func _decodeObject(classes: NSSet?, forObjectReference objectRef: CFKeyedArchiverUID) throws -> AnyObject? {
        var object : AnyObject? = nil

        _validateStillDecoding()
        
        if !NSKeyedUnarchiver._isReference(objectRef) {
            return try _throwError(NSCocoaError.CoderReadCorruptError,
                                   withDescription: "Object \(objectRef) is not a reference. The data may be corrupt.")
        }

        if _isNullObjectReference(objectRef) {
            // reference to the nil object
            object = nil
        } else {
            guard let dereferencedObject = _dereferenceObjectReference(objectRef) else {
                return try _throwError(NSCocoaError.CoderReadCorruptError,
                                       withDescription: "Invalid object reference \(objectRef). The data may be corrupt.")
            }

            if _isContainer(dereferencedObject) {
                // check cached of decoded objects
                object = _cachedObjectForReference(objectRef)
                if object == nil {
                    guard let dict = dereferencedObject as? Dictionary<String, Any> else {
                        return try _throwError(NSCocoaError.CoderReadCorruptError,
                                               withDescription: "Invalid object encoding \(objectRef). The data may be corrupt.")
                    }
                    
                    let innerDecodingContext = NSKeyedDecodingContext(dict, allowedClasses: requiresSecureCoding ? classes : nil)
                    
                    let classReference = innerDecodingContext.dict["$class"] as? CFKeyedArchiverUID
                    if !NSKeyedUnarchiver._isReference(classReference) {
                        return try _throwError(NSCocoaError.CoderReadCorruptError,
                                               withDescription: "Invalid class reference \(classReference). The data may be corrupt.")
                    }
                    
                    _pushDecodingContext(innerDecodingContext)
                    defer { _popDecodingContext() } // ensure an error does not invalidate the decoding context stack

                    var classToConstruct : AnyClass? = try _validateAndMapClassReference(classReference!)
                    
                    if let ns = classToConstruct as? NSObject.Type {
                        classToConstruct = ns.classForKeyedUnarchiver()
                    }
                    
                    guard let decodableClass = classToConstruct as? NSCoding.Type else {
                        return try _throwError(NSCocoaError.CoderReadCorruptError,
                                               withDescription: "Class \(classToConstruct) is not decodable. The data may be corrupt.")
                    }

                    _validateClassSupportsSecureCoding(classToConstruct)
                    
                    object = decodableClass.init(coder: self) as? AnyObject
                    
                    _cacheObject(object!, forReference: objectRef)
                }
            } else {
                // reference to a non-container object
                // FIXME remove these special cases
                if let str = dereferencedObject as? String {
                    object = str.bridge()
                } else {
                    object = dereferencedObject as? AnyObject
                }
            }
        }
        
        return _replacementObject(object)
    }
    
    /**
        Internal function to decode an object. Returns the decoded object or throws an error.
      */
    private func _decodeObject(classes: NSSet?, forKey key: String?) throws -> AnyObject? {
        guard let objectRef : AnyObject? = _objectInCurrentDecodingContext(forKey: key) else {
            return try _throwError(NSCocoaError.CoderValueNotFoundError,
                                   withDescription: "No value found for key \(key). The data may be corrupt.")
        }
        
        return try _decodeObject(classes, forObjectReference: objectRef!)
    }
    
    private func _decodeValueForKey<T>(key: String?) -> T? {
        _validateStillDecoding()
        return _objectInCurrentDecodingContext(forKey: key)
    }
    
    internal func _decodeArray(key : String, withBlock block: (Any) -> Void) throws {
        let objectRefs : Array<Any>? = _decodeValueForKey(key)
        
        guard let unwrappedObjectRefs = objectRefs else {
            return
        }
        
        for objectRef in unwrappedObjectRefs {
            guard NSKeyedUnarchiver._isReference(objectRef) else {
                return
            }
            
            if let object = try _decodeObject(nil, forObjectReference: objectRef as! CFKeyedArchiverUID) {
                block(object)
            }
        }
    }
    
    internal func _decodeArrayOfObjects(key : String) -> Array<AnyObject>? {
        var array : Array<AnyObject> = []
        
        do {
            try _decodeArray(key) { any in
                if let object = any as? AnyObject {
                    array.append(object)
                }
            }
        } catch let error as NSError {
            self._error = error
            return nil
        } catch {
            return nil
        }
        
        return array
    }
    
    public func finishDecoding() {
        if _flags.contains(NSKeyedUnarchiverFlags.FinishedDecoding) {
            return;
        }
        
        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.unarchiverWillFinish(self)
        }
    
	// FIXME are we supposed to do anything here?
    
        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.unarchiverDidFinish(self)
        }

        self._flags.insert(NSKeyedUnarchiverFlags.FinishedDecoding)
    }
    
    public class func setClass(cls: AnyClass?, forClassName codedName: String) {
        _classNameMap[codedName] = cls
    }
    
    public func setClass(cls: AnyClass?, forClassName codedName: String) {
        _classNameMap[codedName] = cls
    }
    
    // During decoding, the coder first checks with the coder's
    // own table, then if there was no mapping there, the class's.
    
    public class func classForClassName(codedName: String) -> AnyClass? {
        return _classNameMap[codedName]
    }
    
    public func classForClassName(codedName: String) -> AnyClass? {
        return _classNameMap[codedName]
    }
    
    public override func containsValueForKey(key: String) -> Bool {
        return _decodeValueForKey(key) != nil
    }
    
    public override func decodeObjectForKey(key: String) -> AnyObject? {
        return decodeObjectOfClasses(nil, forKey: key)
    }
    
    @warn_unused_result
    public override func decodeObjectOfClass<DecodedObjectType : NSCoding where DecodedObjectType : NSObject>(cls: DecodedObjectType.Type, forKey key: String) -> DecodedObjectType? {
        let classes = NSSet(object: cls)
        return decodeObjectOfClasses(classes, forKey: key) as? DecodedObjectType
    }
    
    @warn_unused_result
    public override func decodeObjectOfClasses(classes: NSSet?, forKey key: String) -> AnyObject? {
        do {
            return try _decodeObject(classes, forKey: key)
        } catch let error as NSError {
            self._error = error
        } catch {
        }
        
        return nil
    }
    
    @warn_unused_result
    public override func decodeTopLevelObjectForKey(key: String) throws -> AnyObject? {
        return try self.decodeTopLevelObjectOfClasses(nil, forKey: key)
    }
    
    @warn_unused_result
    public override func decodeTopLevelObjectOfClass<DecodedObjectType : NSCoding where DecodedObjectType : NSObject>(cls: DecodedObjectType.Type, forKey key: String) throws -> DecodedObjectType? {
        let classes = NSSet(object: cls)
        return try self.decodeTopLevelObjectOfClasses(classes, forKey: key) as! DecodedObjectType?
    }
    
    @warn_unused_result
    public override func decodeTopLevelObjectOfClasses(classes: NSSet?, forKey key: String) throws -> AnyObject? {
        guard self._containers?.count == 1 else {
            return try _throwError(NSCocoaError.CoderReadCorruptError,
                                   withDescription: "Can only call decodeTopLevelObjectOfClasses when decoding top level objects.")
        }
        
        return try _decodeObject(classes, forKey: key)
    }
    
    public override func decodeObject() -> AnyObject? {
        do {
            return try _decodeObject(nil, forKey: nil)
        } catch let error as NSError {
            self._error = error
        } catch {
        }
        
        return nil
    }

    // FIXME would be nicer to use a generic function that called _conditionallyBridgeFromObject
    private func _nsNumberForKey(key: String) -> NSNumber? {
        let ns : NSNumber? = _decodeValueForKey(key)
        return ns
    }

    public override func decodeBoolForKey(key: String) -> Bool {
        guard let result = _nsNumberForKey(key)?.boolValue else {
            return false
        }
        return result
    }
    
    public override func decodeIntForKey(key: String) -> Int32  {
        guard let result = _nsNumberForKey(key)?.intValue else {
            return 0
        }
        return result // FIXME
    }
    
    public override func decodeInt32ForKey(key: String) -> Int32 {
        guard let result = _nsNumberForKey(key)?.intValue else {
            return 0
        }
        return result
    }
    
    public override func decodeInt64ForKey(key: String) -> Int64 {
        guard let result = _nsNumberForKey(key)?.longLongValue else {
            return 0
        }
        return result
    }
    
    public override func decodeFloatForKey(key: String) -> Float {
        guard let result = _nsNumberForKey(key)?.floatValue else {
            return 0.0
        }
        return result
    }
    
    public override func decodeDoubleForKey(key: String) -> Double {
        guard let result = _nsNumberForKey(key)?.doubleValue else {
            return 0.0
        }
        return result
    }
    
    public override func decodeIntegerForKey(key: String) -> Int {
        guard let result = _nsNumberForKey(key)?.longValue else {
            return 0
        }
        return result
    }
    
    // returned bytes immutable, and they go away with the unarchiver, not the containing autorelease pool
    public override func decodeBytesForKey(key: String, returnedLength lengthp: UnsafeMutablePointer<Int>) -> UnsafePointer<UInt8> {
        let ns : NSData? = _decodeValueForKey(key)
        
        if let value = ns {
            lengthp.memory = Int(value.length)
            return UnsafePointer<UInt8>(value.bytes)
        }
        
        return nil
    }
    
    public override func decodeDataObject() -> NSData? {
        return decodeObject() as? NSData
    }
    
    public override func decodeBytesWithReturnedLength(lengthp: UnsafeMutablePointer<Int>) -> UnsafeMutablePointer<Void> {
        let ns : NSData? = _decodeValueForKey(nil)
        
        if let value = ns {
            lengthp.memory = Int(value.length)
            return UnsafeMutablePointer<Void>(value.bytes) // FIXME really mutable?
        }
        
        return nil
    }

    public override func encodePropertyList(aPropertyList: AnyObject) {
        return encodeObject(aPropertyList)
    }
    
    public override func decodePropertyList() -> AnyObject? {
        return decodeObject()
    }

    public override var allowedClasses: Set<NSObject>? {
        get {
            return _currentDecodingContext.allowedClasses?._swiftObject
        }
    }

    // Enables secure coding support on this keyed unarchiver. When enabled, anarchiving a disallowed class throws an exception. Once enabled, attempting to set requiresSecureCoding to NO will throw an exception. This is to prevent classes from selectively turning secure coding off. This is designed to be set once at the top level and remain on. Note that the getter is on the superclass, NSCoder. See NSCoder for more information about secure coding.
    public override var requiresSecureCoding: Bool {
        get {
            return _flags.contains(NSKeyedUnarchiverFlags.RequiresSecureCoding)
        }
        set {
            if _flags.contains(NSKeyedUnarchiverFlags.RequiresSecureCoding) {
                if !newValue {
                    fatalError("Cannot unset requiresSecureCoding")
                }
            } else {
                if newValue {
                    _flags.insert(NSKeyedUnarchiverFlags.RequiresSecureCoding)
                }
            }
        }
    }
}

extension NSKeyedUnarchiver {
    @warn_unused_result
    public class func unarchiveTopLevelObjectWithData(data: NSData) throws -> AnyObject? {
        var root : AnyObject? = nil
        
        if let keyedUnarchiver = NSKeyedUnarchiver(forReadingWithData: data) {
            do {
                try root = keyedUnarchiver.decodeTopLevelObjectForKey(NSKeyedArchiveRootObjectKey)
                keyedUnarchiver.finishDecoding()
            } catch {
            }
        }
        
        return root
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
        return self.dynamicType
    }
    
    // Implemented by classes to substitute a new class for instances during
    // encoding.  The object will be encoded as if it were a member of the
    // returned class.  The results of this method are overridden by the archiver
    // class and instance name<->class encoding tables.  If nil is returned,
    // then the null object is encoded.  This method returns the result of
    // [self classForArchiver] by default, NOT -classForCoder as might be
    // expected.  This is a concession to source compatibility.
    
    public func replacementObjectForKeyedArchiver(archiver: NSKeyedArchiver) -> AnyObject? {
        return self
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
        return []
    }
}

// TODO: Could perhaps be an extension of NSCoding instead. The reason it is an extension of NSObject is the lack of default implementations on protocols in Objective-C.
extension NSObject {
    public class func classForKeyedUnarchiver() -> AnyClass {
        return self
    }
}


