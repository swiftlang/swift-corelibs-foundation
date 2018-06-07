// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

open class NSKeyedUnarchiver : NSCoder {
    struct UnarchiverFlags : OptionSet {
        let rawValue : UInt
        
        init(rawValue : UInt) {
            self.rawValue = rawValue
        }
        
        static let None = UnarchiverFlags(rawValue: 0)
        static let FinishedDecoding = UnarchiverFlags(rawValue : 1)
        static let RequiresSecureCoding = UnarchiverFlags(rawValue: 2)
    }
    
    class DecodingContext {
        fileprivate var dict : Dictionary<String, Any>
        fileprivate var genericKey : UInt = 0
        
        init(_ dict : Dictionary<String, Any>) {
            self.dict = dict
        }
    }
    
    private static var _classNameMap : Dictionary<String, AnyClass> = [:]
    private static var _classNameMapLock = NSLock()
    
    open weak var delegate: NSKeyedUnarchiverDelegate?
    
    private enum Stream {
        case data(Data)
        case stream(CFReadStream)
    }
    
    private var _stream : Stream
    private var _flags = UnarchiverFlags(rawValue: 0)
    private var _containers : Array<DecodingContext>? = nil
    private var _objects : Array<Any> = []
    private var _objRefMap : Dictionary<UInt32, Any> = [:]
    private var _replacementMap : Dictionary<AnyHashable, Any> = [:]
    private var _classNameMap : Dictionary<String, AnyClass> = [:]
    private var _classes : Dictionary<UInt32, AnyClass> = [:]
    private var _cache : Array<_NSKeyedArchiverUID> = []
    private var _allowedClasses : Array<[AnyClass]> = []
    private var _error : Error? = nil
    
    override open var error: Error? {
        return _error
    }
    
    open class func unarchiveObject(with data: Data) -> Any? {
        do {
            return try unarchiveTopLevelObjectWithData(data)
        } catch {
        }
        return nil
    }
    
    open class func unarchiveObject(withFile path: String) -> Any? {
        let url = URL(fileURLWithPath: path)
        let readStream = CFReadStreamCreateWithFile(kCFAllocatorSystemDefault, url._cfObject)!
        var root : Any? = nil
        
        if !CFReadStreamOpen(readStream) {
            return nil
        }
        
        defer { CFReadStreamClose(readStream) }
        
        let keyedUnarchiver = NSKeyedUnarchiver(stream: Stream.stream(readStream))
        do {
            try root = keyedUnarchiver.decodeTopLevelObject(forKey: NSKeyedArchiveRootObjectKey)
            keyedUnarchiver.finishDecoding()
        } catch {
        }
        
        return root
    }
    
    public convenience init(forReadingWith data: Data) {
        self.init(stream: Stream.data(data))
    }
    
    private init(stream: Stream) {
        self._stream = stream
        super.init()
        
        do {
            try _readPropertyList()
        } catch {
            failWithError(error)
            self._error = error
        }
    }
  
    private func _readPropertyList() throws {
        var plist : Any? = nil
        var format = PropertyListSerialization.PropertyListFormat.binary
        
        // FIXME this implementation reads the entire property list into memory
        // which will not scale for large archives. We should support incremental
        // unarchiving, but that will be a considerable amount of work.
        
        switch self._stream {
        case .data(let data):
            try plist = PropertyListSerialization.propertyList(from: data, options: [], format: &format)
        case .stream(let readStream):
            try plist = PropertyListSerialization.propertyList(with: readStream, options: [], format: &format)
        }
        
        guard let unwrappedPlist = plist as? Dictionary<String, Any> else {
            throw _decodingError(.propertyListReadCorrupt,
                                 withDescription: "Unable to read archive. The data may be corrupt.")
        }
        
        let archiver = unwrappedPlist["$archiver"] as? String
        if archiver != NSStringFromClass(NSKeyedArchiver.self) {
            throw _decodingError(.propertyListReadCorrupt,
                                 withDescription: "Unknown archiver. The data may be corrupt.")
        }
        
        let version = unwrappedPlist["$version"] as? NSNumber
        if version?.int32Value != Int32(NSKeyedArchivePlistVersion) {
            throw _decodingError(.propertyListReadCorrupt,
                                 withDescription: "Unknown archive version. The data may be corrupt.")
        }
        
        let top = unwrappedPlist["$top"] as? Dictionary<String, Any>
        let objects = unwrappedPlist["$objects"] as? Array<Any>
        
        if top == nil || objects == nil {
            throw _decodingError(.propertyListReadCorrupt,
                                 withDescription: "Unable to read archive contents. The data may be corrupt.")
        }
        
        self._objects = objects!
        self._containers = [DecodingContext(top!)]
    }
    
    private func _pushDecodingContext(_ decodingContext: DecodingContext) {
        self._containers!.append(decodingContext)
    }
    
    private func _popDecodingContext() {
        self._containers!.removeLast()
    }
    
    private var _currentDecodingContext : DecodingContext {
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
            unwrappedKey = escapeArchiverKey(key!)
        } else {
            unwrappedKey = _nextGenericKey()
        }

        if let v = _currentDecodingContext.dict[unwrappedKey!] {
            return v as? T
        }
        return nil
    }
    
    /**
        Dereferences, but does not decode, an object reference
     */
    private func _dereferenceObjectReference(_ unwrappedObjectRef: _NSKeyedArchiverUID) -> Any? {
        let uid = Int(unwrappedObjectRef.value)
        
        guard uid < self._objects.count else {
            return nil
        }

        return self._objects[uid]
    }
    
    open override var systemVersion: UInt32 {
        return NSKeyedArchiverSystemVersion
    }
    
    open override var allowsKeyedCoding: Bool {
        get {
            return true
        }
    }
    
    private func _validateStillDecoding() -> Bool {
        if self._flags.contains(.FinishedDecoding) {
            fatalError("Decoder already finished")
        }
        
        return true
    }
    
    private static func _supportsSecureCoding(_ clsv : AnyClass) -> Bool {
        if let secureCodable = clsv as? NSSecureCoding.Type {
            return secureCodable.supportsSecureCoding
        }
        
        return false
    }
    
    // FIXME is there a better way to do this with Swift stdlib?
    private static func _classIsKindOfClass(_ assertedClass : AnyClass, _ allowedClass : AnyClass) -> Bool {
        var superClass : AnyClass? = assertedClass
        
        repeat {
            if superClass == allowedClass {
                return true
            }
            
            superClass = _getSuperclass(superClass!)
        } while superClass != nil
        
        return false
    }
    
    private func _isClassAllowed(_ assertedClass: AnyClass?, allowedClasses: [AnyClass]?) -> Bool {
        if assertedClass == nil {
            return false
        }
        
        if _flags.contains(.RequiresSecureCoding) {
            if let unwrappedAllowedClasses = allowedClasses {
                if unwrappedAllowedClasses.contains(where: {NSKeyedUnarchiver._classIsKindOfClass(assertedClass!, $0)}) {
                    return true
                }
            }
            
            fatalError("Value was of unexpected class \(assertedClass!)")
        } else {
            return true
        }
    }
   
    /**
        Validate a dictionary with class type information, mapping to a class if allowed
     */ 
    private func _validateAndMapClassDictionary(_ classDict: Dictionary<String, Any>?,
                                                allowedClasses: [AnyClass]?,
                                                classToConstruct: inout AnyClass?) -> Bool {
        classToConstruct = nil
        
        func _classForClassName(_ codedName: String) -> AnyClass? {
            var aClass : AnyClass?
            
            aClass = `class`(forClassName: codedName)
            if aClass == nil {
                aClass = NSKeyedUnarchiver.class(forClassName: codedName)
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
            if _isClassAllowed(assertedClass, allowedClasses: allowedClasses) {
                classToConstruct = assertedClass
                return true
            }
        }
        
        if assertedClassHints != nil {
            for assertedClassHint in assertedClassHints! {
                // FIXME check whether class hints should be subject to mapping or not
                let assertedClass : AnyClass? = NSClassFromString(assertedClassHint)
                if _isClassAllowed(assertedClass, allowedClasses: allowedClasses) {
                    classToConstruct = assertedClass
                    return true
                }
            }
        }
        
        if assertedClassName != nil {
            if let unwrappedDelegate = self.delegate {
                classToConstruct = unwrappedDelegate.unarchiver(self,
                                                                cannotDecodeObjectOfClassName: assertedClassName!,
                                                                originalClasses: assertedClasses != nil ? assertedClasses! : [])
                if classToConstruct != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    /**
        Validate a class reference against a class list, and return the class object if allowed
     */
    private func _validateAndMapClassReference(_ classReference: _NSKeyedArchiverUID,
                                               allowedClasses: [AnyClass]?) throws -> AnyClass? {
        let classUid = classReference.value
        var classToConstruct : AnyClass? = _classes[classUid]
 
        if classToConstruct == nil {
            guard let classDict = _dereferenceObjectReference(classReference) as? Dictionary<String, Any> else {
                return nil
            }
            
            if !_validateAndMapClassDictionary(classDict,
                                               allowedClasses: allowedClasses,
                                               classToConstruct: &classToConstruct) {
                throw _decodingError(.coderReadCorrupt, withDescription: "Invalid class \(classDict). The data may be corrupt.")
            }
            
            _classes[classUid] = classToConstruct
        }
        
        return classToConstruct
    }
    
    private func _cachedObjectForReference(_ objectRef: _NSKeyedArchiverUID) -> Any? {
        return self._objRefMap[objectRef.value]
    }
    
    private func _cacheObject(_ object: Any, forReference objectRef: _NSKeyedArchiverUID) {
        self._objRefMap[objectRef.value] = object
    }
    
    /**
        Returns true if the object is a dictionary representing a object rather than a value type
     */
    private func _isContainer(_ object: Any) -> Bool {
        guard let dict = object as? Dictionary<String, Any> else {
            return false
        }
        
        let classRef = dict["$class"]
        
        return classRef is _NSKeyedArchiverUID
    }
    
    
    /**
        Replace object with another one
     */
    private func replaceObject(_ object: Any, withObject replacement: Any) {
        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.unarchiver(self, willReplace: object, with: replacement)
        }
        
        self._replacementMap[_SwiftValue.store(object)] = replacement
    }
    
    private func _decodingError(_ code: CocoaError.Code, withDescription description: String) -> NSError {
        return NSError(domain: NSCocoaErrorDomain,
                               code: code.rawValue, userInfo: [ "NSDebugDescription" : description ])
    }
    
    private func _replacementObject(_ decodedObject: Any?) -> Any? {
        var object : Any? = nil // object to encode after substitution
        
        // nil cannot be mapped
        if decodedObject == nil {
            return nil
        }
        
        // check replacement cache
        object = self._replacementMap[_SwiftValue.store(decodedObject!)]
        if object != nil {
            return object
        }
        
        // object replaced by delegate. If the delegate returns nil, nil is encoded
        if let unwrappedDelegate = self.delegate {
            object = unwrappedDelegate.unarchiver(self, didDecode: decodedObject!)
            if object != nil {
                replaceObject(decodedObject!, withObject: object!)
                return object
            }
        }
        
        return decodedObject
    }
    
    private func _validateClassSupportsSecureCoding(_ classToConstruct : AnyClass?) -> Bool {
        var supportsSecureCoding : Bool = false
        
        if let secureDecodableClass = classToConstruct as? NSSecureCoding.Type {
            supportsSecureCoding = secureDecodableClass.supportsSecureCoding
        }
        
        if self.requiresSecureCoding && !supportsSecureCoding {
            // FIXME should this be a fatal error?
            fatalError("Archiver \(self) requires secure coding but class \(classToConstruct as Optional) does not support it")
        }
        
        return supportsSecureCoding
    }

    /**
        Decode an object for the given reference
     */
    private func _decodeObject(_ objectRef: Any) throws -> Any? {
        var object : Any? = nil

        let _ = _validateStillDecoding()

        if !(objectRef is _NSKeyedArchiverUID) {
            throw _decodingError(.coderReadCorrupt,
                                 withDescription: "Object \(objectRef) is not a reference. The data may be corrupt.")
        }

        guard let dereferencedObject = _dereferenceObjectReference(objectRef as! _NSKeyedArchiverUID) else {
            throw _decodingError(.coderReadCorrupt,
                                 withDescription: "Invalid object reference \(objectRef). The data may be corrupt.")
        }

        if dereferencedObject as? String == NSKeyedArchiveNullObjectReferenceName {
            return nil
        }

        if _isContainer(dereferencedObject) {
            // check cached of decoded objects
            object = _cachedObjectForReference(objectRef as! _NSKeyedArchiverUID)
            if object == nil {
                guard let dict = dereferencedObject as? Dictionary<String, Any> else {
                    throw _decodingError(.coderReadCorrupt,
                                         withDescription: "Invalid object encoding \(objectRef). The data may be corrupt.")
                }

                let innerDecodingContext = DecodingContext(dict)

                guard let classReference = innerDecodingContext.dict["$class"] as? _NSKeyedArchiverUID else {
                    throw _decodingError(.coderReadCorrupt,
                                         withDescription: "Invalid class reference \(String(describing: innerDecodingContext.dict["$class"])). The data may be corrupt.")
                }

                var classToConstruct : AnyClass? = try _validateAndMapClassReference(classReference,
                                                                                     allowedClasses: self.allowedClasses)

                _pushDecodingContext(innerDecodingContext)
                defer { _popDecodingContext() } // ensure an error does not invalidate the decoding context stack

                if let ns = classToConstruct as? NSObject.Type {
                    classToConstruct = ns.classForKeyedUnarchiver()
                }

                guard let decodableClass = classToConstruct as? NSCoding.Type else {
                    throw _decodingError(.coderReadCorrupt,
                                         withDescription: "Class \(classToConstruct!) is not decodable. The data may be corrupt.")
                }

                let _ = _validateClassSupportsSecureCoding(classToConstruct)

                object = decodableClass.init(coder: self)
                guard object != nil else {
                    throw _decodingError(.coderReadCorrupt,
                                         withDescription: "Class \(classToConstruct!) failed to decode. The data may be corrupt.")
                }

                _cacheObject(object!, forReference: objectRef as! _NSKeyedArchiverUID)
            }
        } else {
            object = _SwiftValue.store(dereferencedObject)
        }

        return _replacementObject(object)
    }

    /**
            Internal function to decode an object. Returns the decoded object or throws an error.
     */
    private func _decodeObject(forKey key: String?) throws -> Any? {
        guard let objectRef : Any? = _objectInCurrentDecodingContext(forKey: key) else {
            throw _decodingError(.coderValueNotFound, withDescription: "No value found for key \(key as Optional). The data may be corrupt.")
        }
        
        return try _decodeObject(objectRef!)
    }

    /**
        Decode a value type in the current decoding context
     */
    internal func _decodeValue<T>(forKey key: String? = nil) -> T? {
        let _ = _validateStillDecoding()
        return _objectInCurrentDecodingContext(forKey: key)
    }

    /**
        Helper for NSArray/NSDictionary to dereference and decode an array of objects
     */
    internal func _decodeArrayOfObjectsForKey(_ key: String,
                                              withBlock block: (Any) -> Void) throws {
        let objectRefs : Array<Any>? = _decodeValue(forKey: key)
        
        guard let unwrappedObjectRefs = objectRefs else {
            return
        }
        
        for objectRef in unwrappedObjectRefs {
            guard objectRef is _NSKeyedArchiverUID else {
                return
            }
            
            if let object = try _decodeObject(objectRef as Any) {
                block(object)
            }
        }
    }
    
    internal override func _decodeArrayOfObjectsForKey(_ key: String) -> [Any] {
        var array : Array<Any> = []
        
        do {
            try _decodeArrayOfObjectsForKey(key) { object in
                array.append(object)
            }
        } catch {
            failWithError(error)
            self._error = error
        }
        
        return array
    }

    /**
     Called when the caller has finished decoding.
     */
    open func finishDecoding() {
        if _flags.contains(.FinishedDecoding) {
            return
        }

        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.unarchiverWillFinish(self)
        }

        // FIXME are we supposed to do anything here?

        if let unwrappedDelegate = self.delegate {
            unwrappedDelegate.unarchiverDidFinish(self)
        }

        let _ = self._flags.insert(.FinishedDecoding)
    }

    open class func setClass(_ cls: AnyClass?, forClassName codedName: String) {
        _classNameMapLock.synchronized {
            _classNameMap[codedName] = cls
        }
    }
    
    open func setClass(_ cls: AnyClass?, forClassName codedName: String) {
        _classNameMap[codedName] = cls
    }
    
    // During decoding, the coder first checks with the coder's
    // own table, then if there was no mapping there, the class's.
    
    open class func `class`(forClassName codedName: String) -> AnyClass? {
        var mappedClass : AnyClass?
        
        _classNameMapLock.synchronized {
            mappedClass = _classNameMap[codedName]
        }
        
        return mappedClass
    }
    
    open func `class`(forClassName codedName: String) -> AnyClass? {
        return _classNameMap[codedName]
    }
    
    open override func containsValue(forKey key: String) -> Bool {
        let any : Any? = _decodeValue(forKey: key)
        return any != nil
    }
    
    open override func decodeObject(forKey key: String) -> Any? {
        do {
            return try _decodeObject(forKey: key)
        } catch {
            failWithError(error)
            self._error = error
        }
        return nil
    }
    
    // private variant of decodeObject(of: ) that supports generic (unkeyed) objects
    private func _decodeObject(of classes: [AnyClass]?, forKey key: String? = nil) -> Any? {
        if let classes = classes {
            do {
                self._allowedClasses.append(classes)
                defer { self._allowedClasses.removeLast() }
                
                return try _decodeObject(forKey: key)
            } catch {
                failWithError(error)
                self._error = error
            }
        }        
        return nil
    }

    open override func decodeObject<DecodedObjectType : NSCoding>(of cls: DecodedObjectType.Type, forKey key: String) -> DecodedObjectType? where DecodedObjectType : NSObject {
        return decodeObject(of: [cls], forKey: key) as? DecodedObjectType
    }
    
    open override func decodeObject(of classes: [AnyClass]?, forKey key: String) -> Any? {
        return _decodeObject(of: classes, forKey: key)
    }
    
    open override func decodeTopLevelObject(forKey key: String) throws -> Any? {
        return try decodeTopLevelObject(of: [NSArray.self], forKey: key)
    }
    
    open override func decodeTopLevelObject<DecodedObjectType : NSCoding>(of cls: DecodedObjectType.Type, forKey key: String) throws -> DecodedObjectType? where DecodedObjectType : NSObject {
        return try self.decodeTopLevelObject(of: [cls], forKey: key) as! DecodedObjectType?
    }
    
    open override func decodeTopLevelObject(of classes: [AnyClass], forKey key: String) throws -> Any? {
        guard self._containers?.count == 1 else {
            throw _decodingError(.coderReadCorrupt,
                                 withDescription: "Can only call decodeTopLevelObjectOfClasses when decoding top level objects.")
        }
        
        return decodeObject(of: classes, forKey: key)
    }
    
    open override func decodeObject() -> Any? {
        do {
            return try _decodeObject(forKey: nil)
        } catch {
            failWithError(error)
            self._error = error
        }
        
        return nil
    }
    
    open override func decodePropertyList() -> Any? {
        return _decodeObject(of: NSPropertyListClasses)
    }
    
    open override func decodePropertyList(forKey key: String) -> Any? {
        return decodeObject(of: NSPropertyListClasses, forKey:key)
    }
    
    /**
        Note that unlike decodePropertyList(forKey:), _decodePropertyListForKey() decodes
        a property list in the current decoding context rather than as an object. It also 
        is able to return value types.
     */
    internal override func _decodePropertyListForKey(_ key: String) -> Any? {
        return _decodeValue(forKey: key)
    }
    
    open override func decodeBool(forKey key: String) -> Bool {
        guard let result : Bool = _decodeValue(forKey: key) else {
            return false
        }
        return result
    }
    
    open override func decodeInt32(forKey key: String) -> Int32 {
        guard let result : NSNumber = _decodeValue(forKey: key) else {
            return 0
        }
        return result.int32Value
    }
    
    open override func decodeInt64(forKey key: String) -> Int64 {
        guard let result : NSNumber = _decodeValue(forKey: key) else {
            return 0
        }
        return result.int64Value
    }
    
    open override func decodeFloat(forKey key: String) -> Float {
        guard let result : NSNumber = _decodeValue(forKey: key) else {
            return 0
        }
        return result.floatValue
    }
    
    open override func decodeDouble(forKey key: String) -> Double {
        guard let result : NSNumber = _decodeValue(forKey: key) else {
            return 0
        }
        return result.doubleValue
    }
    
    open override func decodeInteger(forKey key: String) -> Int {
        guard let result : NSNumber = _decodeValue(forKey: key) else {
            return 0
        }
        return result.intValue
    }
    
    /// - experimental: replaces decodeBytes(forKey:)
    open override func withDecodedUnsafeBufferPointer<ResultType>(forKey key: String, body: (UnsafeBufferPointer<UInt8>?) throws -> ResultType) rethrows -> ResultType {
        let ns : Data? = _decodeValue(forKey: key)
        if let value = ns {
            return try value.withUnsafeBytes {
                try body(UnsafeBufferPointer(start: $0, count: value.count))
            }
        } else {
            return try body(nil)
        }
    }
    
    open override func decodeData() -> Data? {
        return decodeObject() as? Data
    }
    
    private func _decodeValueOfObjCType(_ type: _NSSimpleObjCType, at addr: UnsafeMutableRawPointer) {
        switch type {
        case .ID:
            if let ns = decodeObject() {
                // TODO: Pretty sure this is not 100% correct
                addr.assumingMemoryBound(to: Any.self).pointee = ns
            }
        case .Class:
            if let ns = decodeObject() as? NSString {
                if let nsClass = NSClassFromString(String._unconditionallyBridgeFromObjectiveC(ns)) {
                    addr.assumingMemoryBound(to: AnyClass.self).pointee = nsClass
                }
            }
        case .Char:
            if let ns : NSNumber = _decodeValue() {
                addr.assumingMemoryBound(to: CChar.self).pointee = ns.int8Value
            }
        case .UChar:
            if let ns : NSNumber = _decodeValue() {
                addr.assumingMemoryBound(to: UInt8.self).pointee = ns.uint8Value
            }
        case .Int, .Long:
            if let ns : NSNumber = _decodeValue() {
                addr.assumingMemoryBound(to: Int32.self).pointee = ns.int32Value
            }
        case .UInt, .ULong:
            if let ns : NSNumber = _decodeValue() {
                addr.assumingMemoryBound(to: UInt32.self).pointee = ns.uint32Value
            }
        case .LongLong:
            if let ns : NSNumber = _decodeValue() {
                addr.assumingMemoryBound(to: Int64.self).pointee = ns.int64Value
            }
        case .ULongLong:
            if let ns : NSNumber = _decodeValue() {
                addr.assumingMemoryBound(to: UInt64.self).pointee = ns.uint64Value
            }
        case .Float:
            if let ns : NSNumber = _decodeValue() {
                addr.assumingMemoryBound(to: Float.self).pointee = ns.floatValue
            }
        case .Double:
            if let ns : NSNumber = _decodeValue() {
                addr.assumingMemoryBound(to: Double.self).pointee = ns.doubleValue
            }
        case .Bool:
            if let ns : NSNumber = _decodeValue() {
                addr.assumingMemoryBound(to: Bool.self).pointee = ns.boolValue
            }
        case .CharPtr:
            if let ns = decodeObject() as? NSString {
                let string = ns.utf8String! // XXX leaky
                addr.assumingMemoryBound(to: UnsafePointer<Int8>.self).pointee = string
            }
        default:
            fatalError("NSKeyedUnarchiver.decodeValueOfObjCType: unknown type encoding ('\(type.rawValue)')")
        }
    }
    
    open override func decodeValue(ofObjCType typep: UnsafePointer<Int8>, at addr: UnsafeMutableRawPointer) {
        guard let type = _NSSimpleObjCType(UInt8(typep.pointee)) else {
            let spec = String(typep.pointee)
            fatalError("NSKeyedUnarchiver.decodeValueOfObjCType: unsupported type encoding spec '\(spec)'")
        }
        
        if type == .StructBegin {
            fatalError("NSKeyedUnarchiver.decodeValueOfObjCType: this archiver cannot decode structs")
        } else if type == .ArrayBegin {
            let scanner = Scanner(string: String(cString: typep))
            
            scanner.scanLocation = 1
            
            var count : Int = 0
            guard scanner.scanInt(&count) && count > 0 else {
                fatalError("NSKeyedUnarchiver.decodeValueOfObjCType: array count is missing or zero")
            }
            
            guard let elementType = _NSSimpleObjCType(scanner.scanUpToString(String(_NSSimpleObjCType.ArrayEnd))) else {
                fatalError("NSKeyedUnarchiver.decodeValueOfObjCType: array type is missing")
            }
            
            if let oldStyleArray = _decodeObject(of: [_NSKeyedCoderOldStyleArray.self]) as? _NSKeyedCoderOldStyleArray {
                oldStyleArray.fillObjCType(elementType, count: count, at: addr)
            }
        } else {
            return _decodeValueOfObjCType(type, at: addr)
        }
    }

    open override var allowedClasses: [AnyClass]? {
        get {
            return self._allowedClasses.last
        }
    }
 
    // Enables secure coding support on this keyed unarchiver. When enabled, anarchiving a disallowed class throws an exception. Once enabled, attempting to set requiresSecureCoding to NO will throw an exception. This is to prevent classes from selectively turning secure coding off. This is designed to be set once at the top level and remain on. Note that the getter is on the superclass, NSCoder. See NSCoder for more information about secure coding.
    open override var requiresSecureCoding: Bool {
        get {
            return _flags.contains(.RequiresSecureCoding)
        }
        set {
            if _flags.contains(.RequiresSecureCoding) {
                if !newValue {
                    fatalError("Cannot unset requiresSecureCoding")
                }
            } else {
                if newValue {
                    let _ = _flags.insert(.RequiresSecureCoding)
                }
            }
        }
    }
    
    open override var decodingFailurePolicy: NSCoder.DecodingFailurePolicy {
        get {
            return .setErrorAndReturn
        }
        set {
            NSUnimplemented();
        }
    }

    open class func unarchiveTopLevelObjectWithData(_ data: Data) throws -> Any? {
        let keyedUnarchiver = NSKeyedUnarchiver(forReadingWith: data)
        let root = try keyedUnarchiver.decodeTopLevelObject(forKey: NSKeyedArchiveRootObjectKey)
        keyedUnarchiver.finishDecoding()
        return root
    }
}

public protocol NSKeyedUnarchiverDelegate : class {
    
    // Informs the delegate that the named class is not available during decoding.
    // The delegate may, for example, load some code to introduce the class to the
    // runtime and return it, or substitute a different class object.  If the
    // delegate returns nil, unarchiving aborts with an exception.  The first class
    // name string in the array is the class of the encoded object, the second is
    // the immediate superclass, and so on.
    func unarchiver(_ unarchiver: NSKeyedUnarchiver, cannotDecodeObjectOfClassName name: String, originalClasses classNames: [String]) -> AnyClass?
    
    // Informs the delegate that the object has been decoded.  The delegate
    // either returns this object or can return a different object to replace
    // the decoded one.  The object may be nil.  If the delegate returns nil,
    // the decoded value will be unchanged (that is, the original object will be
    // decoded). The delegate may use this to keep track of the decoded objects.
    func unarchiver(_ unarchiver: NSKeyedUnarchiver, didDecode object: Any?) -> Any?
    
    // Informs the delegate that the newObject is being substituted for the
    // object. This is also called when the delegate itself is doing/has done
    // the substitution. The delegate may use this method if it is keeping track
    // of the encoded or decoded objects.
    func unarchiver(_ unarchiver: NSKeyedUnarchiver, willReplace object: Any, with newObject: Any)
    
    // Notifies the delegate that decoding is about to finish.
    func unarchiverWillFinish(_ unarchiver: NSKeyedUnarchiver)
    
    // Notifies the delegate that decoding has finished.
    func unarchiverDidFinish(_ unarchiver: NSKeyedUnarchiver)
}

extension NSKeyedUnarchiverDelegate {
    func unarchiver(_ unarchiver: NSKeyedUnarchiver, cannotDecodeObjectOfClassName name: String, originalClasses classNames: [String]) -> AnyClass? {
        return nil
    }
    
    func unarchiver(_ unarchiver: NSKeyedUnarchiver, didDecode object: Any?) -> Any? {
        // Returning the same object is the same as doing nothing
        return object
    }
    
    func unarchiver(_ unarchiver: NSKeyedUnarchiver, willReplace object: Any, with newObject: Any) { }
    func unarchiverWillFinish(_ unarchiver: NSKeyedUnarchiver) { }
    func unarchiverDidFinish(_ unarchiver: NSKeyedUnarchiver) { }
}
