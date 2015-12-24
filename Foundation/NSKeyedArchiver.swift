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

public class NSKeyedArchiver : NSCoder {
    
    static var _classNameMap = Dictionary<String, String>()
    
    var _stream : AnyObject
    var _flags = NSKeyedArchiverFlags(rawValue: 0)
    var _delegate : NSKeyedArchiverDelegate? = nil
    var _containers = NSMutableArray(object: NSMutableDictionary())
    var _objects : Array<Any> = [NSKeyedArchiveNullObjectReferenceName]
    var _objRefMap : Dictionary<ObjectIdentifier, UInt32> = [:]
    var _replacementMap : Dictionary<ObjectIdentifier, AnyObject> = [:]
    var _classNameMap : Dictionary<String, String> = [:]
    var _classes : Dictionary<String, CFKeyedArchiverUID> = [:]
    var _cache : Array<CFKeyedArchiverUID> = []
    var _genericKey : UInt32 = 0
    var _visited : Set<ObjectIdentifier> = []

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
        plist["$top"] = self._containers[0]
        
        if let unwrappedDelegate = self._delegate {
            unwrappedDelegate.archiverWillFinish(self)
        }

        let nsPlist = plist.bridge()
        
        if self.outputFormat == NSPropertyListFormat.XMLFormat_v1_0 {
            success = _writeXMLData(nsPlist)
        } else {
            success = _writeBinaryData(nsPlist)
        }

        if let unwrappedDelegate = self._delegate {
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
    
    public override var allowsKeyedCoding: Bool {
        get {
            return true
        }
    }
    
    private func _assertStillEncoding() {
        if self._flags.contains(NSKeyedArchiverFlags.FinishedEncoding) {
            fatalError("Encoder already finished")
        }
    }
    
    private class func _supportsSecureCoding(objv : AnyObject?) -> Bool {
        if let secureCodable = objv as? NSSecureCoding {
            return secureCodable.dynamicType.supportsSecureCoding()
        }
        
        return false
    }
    
    private func _assertSecureCoding(objv : AnyObject?) {
        if self.requiresSecureCoding && !NSKeyedArchiver._supportsSecureCoding(objv) {
            fatalError("Secure coding required")
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
    
    private func _nextGenericKey() -> UInt32! {
        self._genericKey += 1
        return self._genericKey
    }
    
    private class func _objectRefGetValue(objectRef : CFKeyedArchiverUID) -> UInt32 {
        return _CFKeyedArchiverUIDGetValue(unsafeBitCast(objectRef, CFKeyedArchiverUIDRef.self))
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
        
        let oid = ObjectIdentifier(objv!)

        uid = self._objRefMap[oid]
        if uid == nil {
            if conditional {
                return nil
            }
            
            uid = _nextGenericKey()
            
            self._objRefMap[oid] = uid
            self._visited.insert(oid)
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
            let oid = ObjectIdentifier(objv!)

            return self._visited.contains(oid)
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

    /**
        Gets the current serialization dictionary
     */
    private func _blobForCurrentObject() -> NSMutableDictionary {
        return self._containers.lastObject as! NSMutableDictionary
    }
    
    /**
        Pushes or pops a serialization dictionary
     */ 
    private func _setBlobForCurrentObject(blob: NSDictionary?) {
        if let unwrappedBlob = blob {
            self._containers.addObject(unwrappedBlob)
        } else {
            self._containers.removeLastObject()
        }
    }
   
    /**
        Update replacement object mapping
     */
    private func replaceObject(object: AnyObject, withObject replacement: AnyObject?) {
        let oid = ObjectIdentifier(object)
        
        if let unwrappedDelegate = self._delegate {
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
        let index = Int(NSKeyedArchiver._objectRefGetValue(reference))
        self._objects[index] = objv
    }

    private func _classNameForClass(clsv: AnyClass) -> String {
        var className : String?
        
        className = classNameForClass(clsv)
        if className == nil {
            className = NSKeyedArchiver.classNameForClass(clsv)
        }
        if className == nil {
            className = _typeName(clsv)
        }

        return className!
    }
    
    /**
        Returns a dictionary describing class metadata for clsv
     */
    private func _classDictionary(clsv: AnyClass) -> Dictionary<String, Any> {
        var classDict : [String:Any] = [:]
        
        classDict["$classname"] = NSStringFromClass(clsv)

        var classChain : [String] = []
        var classIter : AnyClass? = clsv

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
        
        return classDict
    }
    
    /*
        Return an object reference for a class

        Because _classDictionary() returns a dictionary by value, and every
        time we bridge to NSDictionary we get a new object (the hash code is
        different), we maintain a private mapping between class name and
        object reference to avoid redundantly encoding class metadata
     */
    private func _classReference(clsv: AnyClass) -> CFKeyedArchiverUID? {
        let className = _classNameForClass(clsv)
        var classRef = self._classes[className]
        
        if classRef == nil {
            let classDictionary = _classDictionary(clsv)
            classRef = _addObject(classDictionary.bridge())
            
            if let unwrappedClassRef = classRef {
                self._classes[className] = unwrappedClassRef
            }
            
            return classRef
        }
        
        return classRef
    }
    
    private func _replacementObject(object: AnyObject?) -> AnyObject? {
        var objectToEncode : AnyObject? = nil // object to encode after substitution

        // nil cannot be mapped
        if object == nil {
            return nil
        }
        
        // check replacement cache
        objectToEncode = self._replacementMap[ObjectIdentifier(object!)]
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
        if let unwrappedDelegate = self._delegate {
            objectToEncode = unwrappedDelegate.archiver(self, willEncodeObject: objectToEncode!)
            replaceObject(object!, withObject: objectToEncode)
        }
    
        return objectToEncode
    }
   
    /**
        Internal function to encode an object. Returns the object reference.
     */
    private func _encodeObject(objv: AnyObject?, forKey key: String? = nil, conditional: Bool = false) -> CFKeyedArchiverUID? {
        var object : AnyObject? = nil // object to encode after substitution
        var objectRef : CFKeyedArchiverUID? // encoded object reference
        let haveVisited : Bool

        _assertStillEncoding()
        
        haveVisited = _haveVisited(objv)
        object = _replacementObject(objv)

        objectRef = _referenceObject(object, conditional: conditional)
        guard let unwrappedObjectRef = objectRef else {
            return nil
        }
        
        _assertSecureCoding(object)

        let blob = _blobForCurrentObject()
    
        if let unwrappedKey = key {
            let escapedKey = NSKeyedArchiver._escapeKey(unwrappedKey)
            blob[NSString(escapedKey)] = unwrappedObjectRef
        }

        if !haveVisited {
            var flattenedObject : Any? = nil

            if _isContainer(object) {
                if let codable = object as? NSCoding {
                    let innerBlob = NSMutableDictionary()
                    var cls : AnyClass?
                    
                    _setBlobForCurrentObject(innerBlob)
                    codable.encodeWithCoder(self)

                    let ns = object as? NSObject
                    cls = ns?.classForKeyedArchiver
                    if cls == nil {
                        cls = object!.dynamicType
                    }
                    
                    innerBlob[NSString("$class")] = _classReference(cls!)
                    
                    _setBlobForCurrentObject(nil)
                    flattenedObject = innerBlob
                }
            } else {
                flattenedObject = object!
            }
            
            if flattenedObject != nil {
                _setObject(flattenedObject!, forReference: unwrappedObjectRef)
            }
        }
        
        if let unwrappedDelegate = self._delegate {
            unwrappedDelegate.archiver(self, didEncodeObject: object)
        }

        return unwrappedObjectRef
    }
    
    public override func encodeObject(objv: AnyObject?, forKey key: String) {
        _encodeObject(objv, forKey: key, conditional: false)
    }
    
    public override func encodeConditionalObject(objv: AnyObject?, forKey key: String) {
        _encodeObject(objv, forKey: key, conditional: true)
    }
    
    private func _encodeValueType<T: NSObject where T: NSCoding>(objv: T, forKey key: String) {
        _assertStillEncoding()
        let blob = _blobForCurrentObject()
        blob[NSString(key)] = objv
    }
    
    public override func encodeBool(boolv: Bool, forKey key: String) {
        _encodeValueType(NSNumber(bool: boolv), forKey: key)
    }
    
    public override func encodeInt(intv: Int32, forKey key: String) {
        _encodeValueType(NSNumber(int: intv), forKey: key)
    }
    
    public override func encodeInt32(intv: Int32, forKey key: String) {
        _encodeValueType(NSNumber(int: intv), forKey: key)
    }
    
    public override func encodeInt64(intv: Int64, forKey key: String) {
        _encodeValueType(NSNumber(longLong: intv), forKey: key)
    }
    
    public override func encodeFloat(realv: Float, forKey key: String) {
        _encodeValueType(NSNumber(float: realv), forKey: key)
    }
    
    public override func encodeDouble(realv: Double, forKey key: String) {
        _encodeValueType(NSNumber(double: realv), forKey: key)
    }
    
    public override func encodeBytes(bytesp: UnsafePointer<UInt8>, length lenv: Int, forKey key: String) {
        let data = NSData(bytes: bytesp, length: lenv)
        _encodeValueType(data, forKey: key)
    }
    
    internal func _encodeArrayOfObjects(objects : NSArray, forKey key : String) {
        var objectRefs = [CFKeyedArchiverUID]()
        
        objectRefs.reserveCapacity(objects.count)
        
        for object in objects {
            let objectRef = _encodeObject(object)!

            objectRefs.append(objectRef)
        }
        
        _encodeValueType(objectRefs.bridge(), forKey: key)
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

public class NSKeyedUnarchiver : NSCoder {
    static private var _classNameMap : Dictionary<String, AnyClass> = [:]

    public weak var delegate: NSKeyedUnarchiverDelegate?

    var _stream : AnyObject
    var _flags = NSKeyedUnarchiverFlags(rawValue: 0)
    var _delegate : NSKeyedUnarchiverDelegate? = nil
    var _containers : Array<Dictionary<String, Any>>? = nil
    var _objects : Array<Any> = [NSKeyedArchiveNullObjectReferenceName]
    var _objRefMap : Dictionary<UInt32, AnyObject> = [:]
    var _replacementMap : Dictionary<ObjectIdentifier, AnyObject> = [:]
    var _classNameMap : Dictionary<String, AnyClass> = [:]
    var _classes : Dictionary<UInt32, AnyClass> = [:]
    var _cache : Array<CFKeyedArchiverUID> = []
    var _error : NSError? = nil

    public class func unarchiveObjectWithData(data: NSData) -> AnyObject? {
        do {
            return try unarchiveTopLevelObjectWithData(data)
        } catch {
            return nil
        }
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
        self._containers = [top!]
    }

    private func _blobForCurrentObject() -> Dictionary<String, Any> {
        return self._containers!.last!
    }
    
    private func _setBlobForCurrentObject(blob: Dictionary<String, Any>?) {
        if let unwrappedBlob = blob {
            self._containers!.append(unwrappedBlob)
        } else {
            self._containers!.removeLast()
        }
    }

    /**
        Dereferences, but does not decode, an object reference
     */
    private func _dereferenceObjectReference(unwrappedObjectRef: CFKeyedArchiverUID) -> Any? {
        let uid = Int(NSKeyedArchiver._objectRefGetValue(unwrappedObjectRef))
            
        guard uid < self._objects.count else {
            return nil
        }
        
        if uid == 0 {
            return nil
        }
        
        return self._objects[uid]
    }
    
    private func _assertStillDecoding() {
        if self._flags.contains(NSKeyedUnarchiverFlags.FinishedDecoding) {
            fatalError("Decoder already finished")
        }
    }
    
    private class func _supportsSecureCoding(clsv : AnyClass) -> Bool {
        if let secureCodable = clsv as? NSSecureCoding.Type {
            return secureCodable.supportsSecureCoding()
        }
        
        return false
    }
    
    private func _isClassInWhitelist(assertedClass: AnyClass?, whitelist: NSSet?) -> Bool {
        if assertedClass == nil {
            return false
        }
        
        if whitelist == nil {
            return !_flags.contains(NSKeyedUnarchiverFlags.RequiresSecureCoding)
        }
        
        for whitelistedClass in whitelist! {
            if whitelistedClass as? AnyClass == assertedClass {
                return true
            }
        }
        
        return false
    }
    
    private func _parseClassDictionaryWithWhitelist(classDict: Dictionary<String, Any>?, whitelist: NSSet?, inout classToConstruct: AnyClass?) -> Bool {
        classToConstruct = nil
        
        guard let unwrappedClassDict = classDict else {
            return false
        }
        
        // TODO is it required to validate the superclass hierarchy?
        let assertedClassName = unwrappedClassDict["$classname"] as? String
        let assertedClassHints = unwrappedClassDict["$classhints"] as? [String]
        let assertedClasses = unwrappedClassDict["$classes"] as? [String]

        if assertedClassName != nil {
            let assertedClass : AnyClass? = NSClassFromString(assertedClassName!)
            if _isClassInWhitelist(assertedClass, whitelist: whitelist) {
                classToConstruct = assertedClass
                return true
            }
        }
        
        if assertedClassHints != nil {
            for assertedClassHint in assertedClassHints! {
                let assertedClass : AnyClass? = NSClassFromString(assertedClassHint)
                if _isClassInWhitelist(assertedClass, whitelist: whitelist) {
                    classToConstruct = assertedClass
                    return true
                }
            }
        }
        
        if assertedClassName != nil && assertedClasses != nil {
            if let unwrappedDelegate = self._delegate {
                classToConstruct = unwrappedDelegate.unarchiver(self, cannotDecodeObjectOfClassName: assertedClassName!, originalClasses: assertedClasses!)
                if classToConstruct != nil {
                    return true
                }
            }
        }

        return false
    }
    
    private func _mapClass(classReference: CFKeyedArchiverUID, whitelist: NSSet?) throws -> AnyClass? {
        let classUid = NSKeyedUnarchiver._objectRefGetValue(classReference)
        var classToConstruct : AnyClass? = _classes[classUid]

        if classToConstruct == nil {
            let classDict = _dereferenceObjectReference(classReference) as? Dictionary<String, Any>
            
            if !_parseClassDictionaryWithWhitelist(classDict!, whitelist: whitelist, classToConstruct: &classToConstruct) {
                throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.CoderReadCorruptError.rawValue, userInfo: [
                    "NSDebugDescription" : "Invalid class \(classDict). The data may be corrupt."
                    ])
            }
        
            _classes[classUid] = classToConstruct
        }
        
        return classToConstruct
    }
    
    internal class func _isReference(objectOrReference : Any?) -> Bool {
        if let cf = objectOrReference as? AnyObject {
            return CFGetTypeID(cf) == _CFKeyedArchiverUIDGetTypeID()
        } else {
            return false
        }
    }
    
    private class func _objectRefGetValue(objectRef : CFKeyedArchiverUID) -> UInt32 {
        return _CFKeyedArchiverUIDGetValue(unsafeBitCast(objectRef, CFKeyedArchiverUIDRef.self))
    }

    private func _cachedObjectForReference(objectRef: CFKeyedArchiverUID) -> AnyObject? {
        return self._objRefMap[NSKeyedUnarchiver._objectRefGetValue(objectRef)]
    }
    
    private func _cacheObject(object: AnyObject, forReference objectRef: CFKeyedArchiverUID) {
        self._objRefMap[NSKeyedUnarchiver._objectRefGetValue(objectRef)] = object
    }
    
    private func _isNullObjectReference(objectRef: CFKeyedArchiverUID) -> Bool {
        return NSKeyedUnarchiver._objectRefGetValue(objectRef) == 0
    }
    
    /**
        Returns true if the object is a dictionary representing an object container
      */
    private func _isContainer(object: Any) -> Bool {
        guard let dict = object as? Dictionary<String, Any> else {
            return false
        }
        
        let classRef = dict["$class"]
        
        return NSKeyedUnarchiver._isReference(classRef)
    }
    
    private func replaceObject(object: AnyObject, withObject replacement: AnyObject) {
        let oid = ObjectIdentifier(object)
        
        if let unwrappedDelegate = self._delegate {
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
        object = self._replacementMap[ObjectIdentifier(decodedObject!)]
        if object != nil {
            return object
        }
        
        // object replaced by delegate. If the delegate returns nil, nil is encoded
        if let unwrappedDelegate = self._delegate {
            object = unwrappedDelegate.unarchiver(self, didDecodeObject: decodedObject!)
            if object != nil {
                replaceObject(decodedObject!, withObject: object!)
                return object
            }
        }
        
        return decodedObject
    }

    private func _decodeObject(classes: NSSet?, forObjectReference objectRef: CFKeyedArchiverUID) throws -> AnyObject? {
        var object : AnyObject? = nil

        _assertStillDecoding()
        
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

                    guard let innerBlob = dereferencedObject as? Dictionary<String, Any> else {
                        return try _throwError(NSCocoaError.CoderReadCorruptError,
                                               withDescription: "Invalid object encoding \(objectRef). The data may be corrupt.")
                    }
                    
                    let classReference = innerBlob["$class"] as? CFKeyedArchiverUID
                    if !NSKeyedUnarchiver._isReference(classReference) {
                        return try _throwError(NSCocoaError.CoderReadCorruptError,
                                               withDescription: "Invalid class reference \(classReference). The data may be corrupt.")
                    }
                    
                    var classToConstruct : AnyClass? = try _mapClass(classReference!, whitelist: classes)
                    
                    if let ns = classToConstruct as? NSObject.Type {
                        classToConstruct = ns.classForKeyedUnarchiver()
                    }
                    
                    guard let decodableClass = classToConstruct as? NSCoding.Type else {
                        return try _throwError(NSCocoaError.CoderReadCorruptError,
                                               withDescription: "Class \(classToConstruct) is not decodable. The data may be corrupt.")
                    }
                    
                    _setBlobForCurrentObject(innerBlob)
                    object = decodableClass.init(coder: self) as? AnyObject
                    _setBlobForCurrentObject(nil)
                    
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
    private func _decodeObject(classes: NSSet?, forKey key: String) throws -> AnyObject? {
        
        let blob = _blobForCurrentObject()
        
        guard let objectRef = blob[key] as? AnyObject else {
            return try _throwError(NSCocoaError.CoderValueNotFoundError,
                                   withDescription: "No value found for key \(key). The data may be corrupt.")
        }
        
        return try _decodeObject(classes, forObjectReference: objectRef)
    }
    
    public func finishDecoding() {
        if _flags.contains(NSKeyedUnarchiverFlags.FinishedDecoding) {
            return;
        }
        
        if let unwrappedDelegate = self._delegate {
            unwrappedDelegate.unarchiverWillFinish(self)
        }
        
        if let unwrappedDelegate = self._delegate {
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
        return _valueForKey(key) != nil
    }
    
    public override func decodeObjectForKey(key: String) -> AnyObject? {
        return decodeObjectOfClasses(nil, forKey: key)
    }
    
    @warn_unused_result
    public override func decodeObjectOfClass<DecodedObjectType : NSCoding where DecodedObjectType : NSObject>(cls: DecodedObjectType.Type, forKey key: String) -> DecodedObjectType? {
        let classes = NSSet(object: cls)
        return decodeObjectOfClasses(classes, forKey: key) as! DecodedObjectType?
    }
    
    @warn_unused_result
    public override func decodeObjectOfClasses(classes: NSSet?, forKey key: String) -> AnyObject? {
        _assertStillDecoding()
        do {
            return try _decodeObject(classes, forKey: key)
        } catch {
            return nil
        }
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
        _assertStillDecoding()
        
        guard self._containers?.count == 1 else {
            return try _throwError(NSCocoaError.CoderReadCorruptError,
                                   withDescription: "Can only call decodeTopLevelObjectOfClasses when decoding top level objects.")
        }
        
        return try _decodeObject(classes, forKey: key)
    }
    
    private func _valueForKey(key: String) -> Any? {
        _assertStillDecoding()
        return _blobForCurrentObject()[key]
    }
    
    // FIXME would be nicer to use a generic function that called _conditionallyBridgeFromObject
    private func _nsNumberForKey(key: String) -> NSNumber? {
        return _valueForKey(key) as? NSNumber
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
    
    // returned bytes immutable, and they go away with the unarchiver, not the containing autorelease pool
    public override func decodeBytesForKey(key: String, returnedLength lengthp: UnsafeMutablePointer<Int>) -> UnsafePointer<UInt8> {
        let ns = _valueForKey(key) as? NSData
        
        if let value = ns {
            lengthp.memory = Int(value.length)
            return UnsafePointer<UInt8>(value.bytes)
        }
        
        return nil
    }
    
    internal func _decodeArrayOfObjects(key : String, _ block: (Any) -> Void) {
        let objectRefs = _valueForKey(key) as? Array<Any>
        
        guard let unwrappedObjectRefs = objectRefs else {
            return
        }
        
        for objectRef in unwrappedObjectRefs {
            guard NSKeyedUnarchiver._isReference(objectRef) else {
                return
            }
            
            do {
                if let object = try _decodeObject(nil, forObjectReference: objectRef as! CFKeyedArchiverUID) {
                    block(object)
                }
            } catch {
            }
        }
    }
    
    internal func _decodeArrayOfObjects(key : String) -> Array<AnyObject> {
        var array : Array<AnyObject> = []
        
        _decodeArrayOfObjects(key) { any in
            if let object = any as? AnyObject {
                array.append(object)
            }
        }
        
        return array
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


