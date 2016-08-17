// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation


open class NSDictionary : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFDictionaryGetTypeID())
    internal var _storage: [NSObject: AnyObject]
    
    open var count: Int {
        guard type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }
        return _storage.count
    }
    
    open func object(forKey aKey: Any) -> Any? {
        guard type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }
        if let val = _storage[_SwiftValue.store(aKey)] {
            return _SwiftValue.fetch(val)
        }
        return nil
    }
    
    open func keyEnumerator() -> NSEnumerator {
        guard type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }
        
        return NSGeneratorEnumerator(_storage.keys.map { _SwiftValue.fetch($0) }.makeIterator())
    }
    
    public override convenience init() {
        self.init(objects: [], forKeys: [], count: 0)
    }
    
    public required init(objects: UnsafePointer<AnyObject>!, forKeys keys: UnsafePointer<NSObject>!, count cnt: Int) {
        _storage = [NSObject : AnyObject](minimumCapacity: cnt)
        for idx in 0..<cnt {
            let key = keys[idx].copy()
            let value = objects[idx]
            _storage[key as! NSObject] = value
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            var cnt: UInt32 = 0
            // We're stuck with (int) here (rather than unsigned int)
            // because that's the way the code was originally written, unless
            // we go to a new version of the class, which has its own problems.
            withUnsafeMutablePointer(to: &cnt) { (ptr: UnsafeMutablePointer<UInt32>) -> Void in
                aDecoder.decodeValue(ofObjCType: "i", at: UnsafeMutableRawPointer(ptr))
            }
            let keys = UnsafeMutablePointer<NSObject>.allocate(capacity: Int(cnt))
            let objects = UnsafeMutablePointer<AnyObject>.allocate(capacity: Int(cnt))
            for idx in 0..<cnt {
                keys.advanced(by: Int(idx)).initialize(to: aDecoder.decodeObject()! as! NSObject)
                objects.advanced(by: Int(idx)).initialize(to: aDecoder.decodeObject()! as! NSObject)
            }
            self.init(objects: UnsafePointer<AnyObject>(objects), forKeys: UnsafePointer<NSObject>(keys), count: Int(cnt))
            keys.deinitialize(count: Int(cnt))
            keys.deallocate(capacity: Int(cnt))
            objects.deinitialize(count: Int(cnt))
            objects.deallocate(capacity: Int(cnt))
            
        } else if type(of: aDecoder) == NSKeyedUnarchiver.self || aDecoder.containsValue(forKey: "NS.objects") {
            let keys = aDecoder._decodeArrayOfObjectsForKey("NS.keys").map() { return $0 as! NSObject }
            let objects = aDecoder._decodeArrayOfObjectsForKey("NS.objects")
            self.init(objects: objects as! [NSObject], forKeys: keys)
        } else {
            var objects = [AnyObject]()
            var keys = [NSObject]()
            var count = 0
            while let key = aDecoder.decodeObject(forKey: "NS.key.\(count)"),
                let object = aDecoder.decodeObject(forKey: "NS.object.\(count)") {
                    keys.append(key as! NSObject)
                    objects.append(object as! NSObject)
                    count += 1
            }
            self.init(objects: objects, forKeys: keys)
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        if let keyedArchiver = aCoder as? NSKeyedArchiver {
            keyedArchiver._encodeArrayOfObjects(self.allKeys._nsObject, forKey:"NS.keys")
            keyedArchiver._encodeArrayOfObjects(self.allValues._nsObject, forKey:"NS.objects")
        } else {
            NSUnimplemented()
        }
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        if type(of: self) === NSDictionary.self {
            // return self for immutable type
            return self
        } else if type(of: self) === NSMutableDictionary.self {
            let dictionary = NSDictionary()
            dictionary._storage = self._storage
            return dictionary
        }
        return NSDictionary(objects: self.allValues, forKeys: self.allKeys.map({ $0 as! NSObject}))
    }

    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }

    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        if type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self {
            // always create and return an NSMutableDictionary
            let mutableDictionary = NSMutableDictionary()
            mutableDictionary._storage = self._storage
            return mutableDictionary
        }
        return NSMutableDictionary(objects: self.allValues, forKeys: self.allKeys.map { _SwiftValue.store($0) } )
    }

    public convenience init(object: Any, forKey key: NSCopying) {
        self.init(objects: [object], forKeys: [key as! NSObject])
    }
    
//    public convenience init(dictionary otherDictionary: [NSObject : AnyObject]) {
//        self.init(dictionary: otherDictionary, copyItems: false)
//    }
    
//    public convenience init(dictionary otherDictionary: [NSObject : AnyObject], copyItems flag: Bool) {
//        var keys = Array<KeyType>()
//        var values = Array<AnyObject>()
//        for key in otherDictionary.keys {
//            keys.append(key)
//            var value = otherDictionary[key]
//            if flag {
//                if let val = value as? NSObject {
//                    value = val.copy()
//                }
//            }
//            values.append(value!)
//        }
//        self.init(objects: values, forKeys: keys)
//    }
    
    public convenience init(objects: [Any], forKeys keys: [NSObject]) {
        let keyBuffer = UnsafeMutablePointer<NSObject>.allocate(capacity: keys.count)
        keyBuffer.initialize(from: keys)

        let valueBuffer = UnsafeMutablePointer<AnyObject>.allocate(capacity: objects.count)
        valueBuffer.initialize(from: objects.map { _SwiftValue.store($0) })

        self.init(objects: valueBuffer, forKeys:keyBuffer, count: keys.count)
        
        keyBuffer.deinitialize(count: keys.count)
        valueBuffer.deinitialize(count: objects.count)
        keyBuffer.deallocate(capacity: keys.count)
        valueBuffer.deallocate(capacity: objects.count)
    }
    
    public convenience init(dictionary otherDictionary: [AnyHashable : Any]) {
        self.init(objects: otherDictionary.values.map { $0 }, forKeys: otherDictionary.keys.map { _SwiftValue.store($0) })
    }

    open override func isEqual(_ object: AnyObject?) -> Bool {
        guard let otherDictionary = object as? NSDictionary else {
            return false
        }
        
        return self.isEqual(to: Dictionary._unconditionallyBridgeFromObjectiveC(otherDictionary))
    }

    open override var hash: Int {
        return self.count
    }

    open var allKeys: [Any] {
        if type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self {
            return _storage.keys.map { $0 }
        } else {
            var keys = [Any]()
            let enumerator = keyEnumerator()
            while let key = enumerator.nextObject() {
                keys.append(key)
            }
            return keys
        }
    }
    
    open var allValues: [Any] {
        if type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self {
            return _storage.values.map { $0 }
        } else {
            var values = [Any]()
            let enumerator = keyEnumerator()
            while let key = enumerator.nextObject() {
                values.append(object(forKey: key)!)
            }
            return values
        }
    }
    
    /// Alternative pseudo funnel method for fastpath fetches from dictionaries
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open func getObjects(_ objects: inout [Any], andKeys keys: inout [Any], count: Int) {
        if type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self {
            for (key, value) in _storage {
                keys.append(_SwiftValue.fetch(key))
                objects.append(_SwiftValue.fetch(value))
            }
        } else {
            
            let enumerator = keyEnumerator()
            while let key = enumerator.nextObject() {
                let value = object(forKey: key)!
                keys.append(key)
                objects.append(value)
            }
        }
    }
    
    open subscript (key: Any) -> Any? {
        return object(forKey: key)
    }
    
    
    open func allKeys(for anObject: Any) -> [Any] {
        var matching = Array<Any>()
        enumerateKeysAndObjects([]) { key, value, _ in
            if let val = value as? AnyHashable,
               let obj = anObject as? AnyHashable {
                if val == obj {
                    matching.append(key)
                }
            }
        }
        return matching
    }

    /// A string that represents the contents of the dictionary, formatted as
    /// a property list (read-only)
    ///
    /// If each key in the dictionary is an NSString object, the entries are
    /// listed in ascending order by key, otherwise the order in which the entries
    /// are listed is undefined. This property is intended to produce readable
    /// output for debugging purposes, not for serializing data. If you want to
    /// store dictionary data for later retrieval, see
    /// [Property List Programming Guide](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/PropertyLists/Introduction/Introduction.html#//apple_ref/doc/uid/10000048i)
    /// and [Archives and Serializations Programming Guide](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Archiving/Archiving.html#//apple_ref/doc/uid/10000047i).
    open override var description: String {
        return description(withLocale: nil)
    }

    open var descriptionInStringsFileFormat: String { NSUnimplemented() }

    /// Returns a string object that represents the contents of the dictionary,
    /// formatted as a property list.
    ///
    /// - parameter locale: An object that specifies options used for formatting
    ///   each of the dictionary’s keys and values; pass `nil` if you don’t
    ///   want them formatted.
    open func description(withLocale locale: Locale?) -> String {
        return description(withLocale: locale, indent: 0)
    }

    /// Returns a string object that represents the contents of the dictionary,
    /// formatted as a property list.
    ///
    /// - parameter locale: An object that specifies options used for formatting
    ///   each of the dictionary’s keys and values; pass `nil` if you don’t
    ///   want them formatted.
    ///
    /// - parameter level: Specifies a level of indentation, to make the output
    ///   more readable: the indentation is (4 spaces) * level.
    ///
    /// - returns: A string object that represents the contents of the dictionary,
    ///   formatted as a property list.
    open func description(withLocale locale: Locale?, indent level: Int) -> String {
        if level > 100 { return "..." }

        var lines = [String]()
        let indentation = String(repeating: " ", count: level * 4)
        lines.append(indentation + "{")

        for key in self.allKeys {
            var line = String(repeating: " ", count: (level + 1) * 4)

            if key is NSArray {
                line += (key as! NSArray).description(withLocale: locale, indent: level + 1)
            } else if key is Date {
                line += (key as! NSDate).description(with: locale)
            } else if key is NSDecimalNumber {
                line += (key as! NSDecimalNumber).description(withLocale: locale)
            } else if key is NSDictionary {
                line += (key as! NSDictionary).description(withLocale: locale, indent: level + 1)
            } else if key is NSOrderedSet {
                line += (key as! NSOrderedSet).description(withLocale: locale, indent: level + 1)
            } else if key is NSSet {
                line += (key as! NSSet).description(withLocale: locale)
            } else {
                line += "\(key)"
            }

            line += " = "

            let object = self.object(forKey: key)!
            if object is NSArray {
                line += (object as! NSArray).description(withLocale: locale, indent: level + 1)
            } else if object is Date {
                line += (object as! NSDate).description(with: locale)
            } else if object is NSDecimalNumber {
                line += (object as! NSDecimalNumber).description(withLocale: locale)
            } else if object is NSDictionary {
                line += (object as! NSDictionary).description(withLocale: locale, indent: level + 1)
            } else if object is NSOrderedSet {
                line += (object as! NSOrderedSet).description(withLocale: locale, indent: level + 1)
            } else if object is NSSet {
                line += (object as! NSSet).description(withLocale: locale)
            } else {
                line += "\(object)"
            }

            line += ";"

            lines.append(line)
        }

        lines.append(indentation + "}")
        
        return lines.joined(separator: "\n")
    }

    open func isEqual(to otherDictionary: [AnyHashable : Any]) -> Bool {
        if count != otherDictionary.count {
            return false
        }
        
        for key in keyEnumerator() {
            if let otherValue = otherDictionary[key as! AnyHashable] as? AnyHashable,
               let value = object(forKey: key)! as? AnyHashable {
                if otherValue != value {
                    return false
                }
            } else if let otherBridgeable = otherDictionary[key as! AnyHashable] as? _ObjectBridgeable,
                      let bridgeable = object(forKey: key)! as? _ObjectBridgeable {
                if !(otherBridgeable._bridgeToAnyObject() as! NSObject).isEqual(bridgeable._bridgeToAnyObject()) {
                    return false
                }
            } else {
                return false
            }
        }
        
        return true
    }
    
    public struct Iterator : IteratorProtocol {
        let dictionary : NSDictionary
        var keyGenerator : Array<Any>.Iterator
        public mutating func next() -> (key: Any, value: Any)? {
            if let key = keyGenerator.next() {
                return (key, dictionary.object(forKey: key)!)
            } else {
                return nil
            }
        }
        init(_ dict : NSDictionary) {
            self.dictionary = dict
            self.keyGenerator = dict.allKeys.makeIterator()
        }
    }
    
    internal struct ObjectGenerator: IteratorProtocol {
        let dictionary : NSDictionary
        var keyGenerator : Array<Any>.Iterator
        mutating func next() -> Any? {
            if let key = keyGenerator.next() {
                return dictionary.object(forKey: key)!
            } else {
                return nil
            }
        }
        init(_ dict : NSDictionary) {
            self.dictionary = dict
            self.keyGenerator = dict.allKeys.makeIterator()
        }
    }

    open func objectEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(ObjectGenerator(self))
    }
    
    open func objects(forKeys keys: [Any], notFoundMarker marker: Any) -> [Any] {
        var objects = [Any]()
        for key in keys {
            if let object = object(forKey: key) {
                objects.append(object)
            } else {
                objects.append(marker)
            }
        }
        return objects
    }
    
    open func write(toFile path: String, atomically useAuxiliaryFile: Bool) -> Bool { NSUnimplemented() }
    open func write(to url: URL, atomically: Bool) -> Bool { NSUnimplemented() } // the atomically flag is ignored if url of a type that cannot be written atomically.
    
    public func enumerateKeysAndObjects(_ block: (Any, Any, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateKeysAndObjects([], using: block)
    }

    public func enumerateKeysAndObjects(_ opts: NSEnumerationOptions = [], using block: (Any, Any, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        let count = self.count
        var keys = [Any]()
        var objects = [Any]()
        getObjects(&objects, andKeys: &keys, count: count)
        var stop = ObjCBool(false)
        for idx in 0..<count {
            withUnsafeMutablePointer(to: &stop, { stop in
                block(keys[idx], objects[idx], stop)
            })

            if stop {
                break
            }
        }
    }
    
    open func keysSortedByValue(comparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] {
        return keysSortedByValue([], usingComparator: cmptr)
    }

    open func keysSortedByValue(_ opts: SortOptions = [], usingComparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] {
        let sorted = allKeys.sorted { lhs, rhs in
            return cmptr(lhs, rhs) == .orderedSame
        }
        return sorted
    }

    open func keysOfEntries(passingTest predicate: (Any, Any, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Set<NSObject> {
        return keysOfEntries([], passingTest: predicate)
    }

    open func keysOfEntries(_ opts: NSEnumerationOptions = [], passingTest predicate: (Any, Any, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Set<NSObject> {
        var matching = Set<NSObject>()
        enumerateKeysAndObjects(opts) { key, value, stop in
            if predicate(key, value, stop) {
                matching.insert(key as! NSObject)
            }
        }
        return matching
    }
    
    override open var _cfTypeID: CFTypeID {
        return CFDictionaryGetTypeID()
    }
    
    required public convenience init(dictionaryLiteral elements: (Any, Any)...) {
        var keys = [NSObject]()
        var values = [Any]()

        for (key, value) in elements {
            keys.append(_SwiftValue.store(key))
            values.append(value)
        }
        
        self.init(objects: values, forKeys: keys)
    }
}

extension NSDictionary : _CFBridgable, _SwiftBridgable {
    internal var _cfObject: CFDictionary { return unsafeBitCast(self, to: CFDictionary.self) }
    internal var _swiftObject: Dictionary<AnyHashable, Any> { return Dictionary._unconditionallyBridgeFromObjectiveC(self) }
}

extension NSMutableDictionary {
    internal var _cfMutableObject: CFMutableDictionary { return unsafeBitCast(self, to: CFMutableDictionary.self) }
}

extension CFDictionary : _NSBridgable, _SwiftBridgable {
    internal var _nsObject: NSDictionary { return unsafeBitCast(self, to: NSDictionary.self) }
    internal var _swiftObject: [AnyHashable: Any] { return _nsObject._swiftObject }
}

extension Dictionary : _NSBridgable, _CFBridgable {
    internal var _nsObject: NSDictionary { return _bridgeToObjectiveC() }
    internal var _cfObject: CFDictionary { return _nsObject._cfObject }
}

open class NSMutableDictionary : NSDictionary {
    
    open func removeObject(forKey aKey: Any) {
        guard type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }

        _storage.removeValue(forKey: _SwiftValue.store(aKey))
    }
    
    /// - Note: this diverges from the darwin version that requires NSCopying (this differential preserves allowing strings and such to be used as keys)
    open func setObject(_ anObject: Any, forKey aKey: AnyHashable) {
        guard type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }
        _storage[(aKey as! NSObject)] = _SwiftValue.store(anObject)
    }
    
    public convenience required init() {
        self.init(capacity: 0)
    }
    
    public convenience init(capacity numItems: Int) {
        self.init(objects: [], forKeys: [], count: 0)
        
        // It is safe to reset the storage here because we know is empty
        _storage = [NSObject: AnyObject](minimumCapacity: numItems)
    }
    
    public required init(objects: UnsafePointer<AnyObject>!, forKeys keys: UnsafePointer<NSObject>!, count cnt: Int) {
        super.init(objects: objects, forKeys: keys, count: cnt)
    }
    
    public convenience init?(contentsOfFile path: String) { NSUnimplemented() }
    public convenience init?(contentsOfURL url: URL) { NSUnimplemented() }
}

extension NSMutableDictionary {
    
    open func addEntries(from otherDictionary: [AnyHashable : Any]) {
        for (key, obj) in otherDictionary {
            setObject(obj, forKey: key)
        }
    }
    
    open func removeAllObjects() {
        if type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self {
            _storage.removeAll()
        } else {
            for key in allKeys {
                removeObject(forKey: key)
            }
        }
    }
    
    open func removeObjects(forKeys keyArray: [Any]) {
        for key in keyArray {
            removeObject(forKey: key)
        }
    }
    
    open func setDictionary(_ otherDictionary: [AnyHashable : Any]) {
        removeAllObjects()
        for (key, obj) in otherDictionary {
            setObject(obj, forKey: key)
        }
    
    }
    
    /// - Note: See setObject(_:,forKey:) for details on the differential here
    public subscript (key: AnyHashable) -> Any? {
        get {
            return object(forKey: key)
        }
        set {
            if let val = newValue {
                setObject(val, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
}

extension NSDictionary : Sequence {
    public func makeIterator() -> Iterator {
        return Iterator(self)
    }
}

// MARK - Shared Key Sets

extension NSDictionary {
    
    /*  Use this method to create a key set to pass to +dictionaryWithSharedKeySet:.
    The keys are copied from the array and must be copyable.
    If the array parameter is nil or not an NSArray, an exception is thrown.
    If the array of keys is empty, an empty key set is returned.
    The array of keys may contain duplicates, which are ignored (it is undefined which object of each duplicate pair is used).
    As for any usage of hashing, is recommended that the keys have a well-distributed implementation of -hash, and the hash codes must satisfy the hash/isEqual: invariant.
    Keys with duplicate hash codes are allowed, but will cause lower performance and increase memory usage.
    */
    open class func sharedKeySet(forKeys keys: [NSCopying]) -> AnyObject { NSUnimplemented() }
}

extension NSMutableDictionary {
    
    /*  Create a mutable dictionary which is optimized for dealing with a known set of keys.
    Keys that are not in the key set can still be set into the dictionary, but that usage is not optimal.
    As with any dictionary, the keys must be copyable.
    If keyset is nil, an exception is thrown.
    If keyset is not an object returned by +sharedKeySetForKeys:, an exception is thrown.
    */
    public convenience init(sharedKeySet keyset: AnyObject) { NSUnimplemented() }
}

extension NSDictionary : ExpressibleByDictionaryLiteral { }

extension NSDictionary : _StructTypeBridgeable {
    public typealias _StructType = Dictionary<AnyHashable,Any>
    
    public func _bridgeToSwift() -> _StructType {
        return _StructType._unconditionallyBridgeFromObjectiveC(self)
    }
}
