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
    static let NullObjectReference = NSKeyedArchiver._createObjectRef(0)
    static let NullObjectReferenceName: NSString = "$null"
    static let PlistVersion = 100000
    static let SwiftFoundationPrefix = "SwiftFoundation."
    
    var _stream : AnyObject
    var _flags = NSKeyedArchiverFlags(rawValue: 0)
    var _delegate : NSKeyedArchiverDelegate? = nil
    var _containers = NSMutableArray(object: NSMutableDictionary())
    var _classNameMap : Dictionary<String, String> = [:]
    var _objects : Array<AnyObject> = [NSKeyedArchiver.NullObjectReferenceName]
    var _objRefMap : Dictionary<ObjectIdentifier, UInt32> = [:]
    var _replacementMap : Dictionary<ObjectIdentifier, AnyObject> = [:]
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
        
        let keyedArchiver = NSKeyedArchiver(stream: writeStream)
        
        keyedArchiver.encodeObject(rootObject, forKey: NSKeyedArchiveRootObjectKey)
        keyedArchiver.finishEncoding()
        
        CFWriteStreamClose(writeStream)
        
        return keyedArchiver._flags.contains(NSKeyedArchiverFlags.FinishedEncoding)
    }
    
    private init(stream: AnyObject) {
        self._stream = stream
        super.init()
    }
    
    public convenience init(forWritingWithMutableData data: NSMutableData) {
        self.init(stream: data)
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

        let plist = NSMutableDictionary()
        var success : Bool
        
        plist["$archiver".bridge()] = String(self.dynamicType).bridge()
        plist["$version".bridge()] = NSKeyedArchiver.PlistVersion._bridgeToObject()
        plist["$objects".bridge()] = self._objects.bridge()
        plist["$top".bridge()] = self._containers[0]
        
        if let unwrappedDelegate = self._delegate {
            unwrappedDelegate.archiverWillFinish(self)
        }

        if self.outputFormat == NSPropertyListFormat.XMLFormat_v1_0 {
            success = _writeXMLData(plist)
        } else {
            success = _writeBinaryData(plist)
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
            return NSKeyedArchiver.NullObjectReference
        } else if Int(uid) <= self._cache.count {
            return self._cache[Int(uid) - 1]
        } else {
            let objectRef = NSKeyedArchiver._createObjectRef(uid)
            self._cache.insert(objectRef, atIndex: Int(uid) - 1)
            return objectRef
        }
    }
    
    private func _nextGenericKey() -> UInt32 {
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
            return NSKeyedArchiver.NullObjectReference
        }
        
        let oid = ObjectIdentifier(objv!)

        uid = self._objRefMap[oid]
        if uid == nil {
            if conditional {
                return nil
            }
            
            uid = _nextGenericKey()
            
            self._objRefMap[oid] = uid!
            self._visited.insert(oid)
            self._objects.insert(NSKeyedArchiver.NullObjectReferenceName, atIndex: Int(uid!))
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
    private func _setBlobForCurrentObject(blob: NSMutableDictionary?) {
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
    private func _setObject(objv: AnyObject, forReference reference : CFKeyedArchiverUID) {
        let index = Int(NSKeyedArchiver._objectRefGetValue(reference))
        self._objects[index] = objv
    }

    /**
        Strips the SwiftFoundation prefix off Foundation classes, for wire interoperability
     */
    private func _unnamespacedClassName(clsName: String) -> String {
        if clsName.hasPrefix(NSKeyedArchiver.SwiftFoundationPrefix) {
            return NSString(clsName).substringFromIndex(NSKeyedArchiver.SwiftFoundationPrefix.length)
        } else {
            return clsName
        }
    }
    
    /**
        Returns a dictionary describing class metadata for clsv
     */
    private func _classDictionary(clsv: AnyClass) -> NSDictionary {
        var dict : [String:AnyObject] = [:]
        var classname : String?
        
        classname = classNameForClass(clsv)
        if classname == nil {
            classname = NSKeyedArchiver.classNameForClass(clsv)
        }
        if classname == nil {
            classname = _typeName(clsv)
        }
        
        dict["$classname"] = _unnamespacedClassName(classname!).bridge()

        var chain : [String] = []
        var cls : AnyClass? = clsv

        repeat {
            chain.append(_unnamespacedClassName(_typeName(cls!)))
            cls = _getSuperclass(cls!)
        } while cls != nil
        
        dict["$classes"] = chain.bridge()
        
        if let ns = clsv as? NSObject.Type {
            let classhints = ns.classFallbacksForKeyedArchiver()
            if classhints.count > 0 {
                dict["$classhints"] = classhints.bridge()
            }
        }

        return dict.bridge()
    }
   
    /**
        Internal function to encode an object. Returns the object reference.
     */
    private func _encodeObject(objv: AnyObject?, forKey key: String? = nil, conditional: Bool = false) -> CFKeyedArchiverUID? {
        var object : AnyObject? = nil // object to encode after substitution
        var objectRef : CFKeyedArchiverUID? // encoded object reference
        let haveVisited : Bool
        
        _assertStillEncoding()
        
        if objv != nil {
            // object replacement cached
            object = self._replacementMap[ObjectIdentifier(objv!)]
            
            // object replaced by NSObject.replacementObjectForKeyedArchiver
            if object == nil {
                let ns = objv as? NSObject
                if let object = ns?.replacementObjectForKeyedArchiver(self) {
                    replaceObject(objv!, withObject: object)
                }
            }
            
            // object replaced by delegate
            if object == nil {
                if let unwrappedDelegate = self._delegate {
                    let possiblyReplacedObject = object != nil ? object! : objv!
                    object = unwrappedDelegate.archiver(self, willEncodeObject: possiblyReplacedObject)
                    replaceObject(objv!, withObject: object)
                }
            }
            
            // object not replaced
            if object == nil {
                object = objv
            }
        }
        
        haveVisited = _haveVisited(object)

        objectRef = _referenceObject(object, conditional: conditional)
        guard let unwrappedObjectRef = objectRef else {
            return nil
        }
        
        _assertSecureCoding(object)

        var blob : NSMutableDictionary
        let isContainer = _isContainer(object)

        blob = _blobForCurrentObject()
    
        if let unwrappedKey = key {
            let escapedKey = NSKeyedArchiver._escapeKey(unwrappedKey)
            blob[escapedKey.bridge()] = unwrappedObjectRef
        }

        if !haveVisited {
            var flattenedObject : AnyObject? = nil

            if isContainer {
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
                    
                    innerBlob["$class".bridge()] = _addObject(_classDictionary(cls!))
                    
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
            // XXX is this called with the original object or the substituted one?
            unwrappedDelegate.archiver(self, didEncodeObject: objv)
        }
        
        return unwrappedObjectRef
    }
    
    public override func encodeObject(objv: AnyObject?, forKey key: String) {
        _encodeObject(objv, forKey: key, conditional: false)
    }
    
    public override func encodeConditionalObject(objv: AnyObject?, forKey key: String) {
        _encodeObject(objv, forKey: key, conditional: true)
    }
    
    private func _encodeValueType(objv: NSObject, forKey key: String) {
        _assertStillEncoding()
        let blob = _blobForCurrentObject()
        blob[key.bridge()] = objv
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
        return self.dynamicType
    }
    
    // Implemented by classes to substitute a new class for instances during
    // encoding.  The object will be encoded as if it were a member of the
    // returned class.  The results of this method are overridden by the archiver
    // class and instance name<->class encoding tables.  If nil is returned,
    // the result of this method is ignored.  This method returns the result of
    // [self classForArchiver] by default, NOT -classForCoder as might be
    // expected.  This is a concession to source compatibility.
    
    public func replacementObjectForKeyedArchiver(archiver: NSKeyedArchiver) -> AnyObject? {
        return nil
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
        NSUnimplemented()
    }
}


