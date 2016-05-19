// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

extension Dictionary : _ObjectTypeBridgeable {
    public func _bridgeToObject() -> NSDictionary {
        let keyBuffer = UnsafeMutablePointer<NSObject>(allocatingCapacity: count)
        let valueBuffer = UnsafeMutablePointer<AnyObject>(allocatingCapacity: count)
        
        var idx = 0
        
        self.forEach {
            let key = _NSObjectRepresentableBridge($0.0)
            let value = _NSObjectRepresentableBridge($0.1)
            keyBuffer.advanced(by: idx).initialize(with: key)
            valueBuffer.advanced(by: idx).initialize(with: value)
            idx += 1
        }
        
        let dict = NSDictionary(objects: valueBuffer, forKeys: keyBuffer, count: count)
        
        keyBuffer.deinitialize(count: count)
        valueBuffer.deinitialize(count: count)
        keyBuffer.deallocateCapacity(count)
        valueBuffer.deallocateCapacity(count)

        return dict
    }
    
    public static func _forceBridgeFromObject(_ x: NSDictionary, result: inout Dictionary?) {
        var dict = [Key: Value]()
        var failedConversion = false
        
        if x.dynamicType == NSDictionary.self || x.dynamicType == NSMutableDictionary.self {
            x.enumerateKeysAndObjectsUsingBlock { key, value, stop in
                guard let key = key as? Key, let value = value as? Value else {
                    failedConversion = true
                    stop.pointee = true
                    return
                }
                dict[key] = value
            }
        } else if x.dynamicType == _NSCFDictionary.self {
            let cf = x._cfObject
            let cnt = CFDictionaryGetCount(cf)

            let keys = UnsafeMutablePointer<UnsafePointer<Void>?>(allocatingCapacity: cnt)
            let values = UnsafeMutablePointer<UnsafePointer<Void>?>(allocatingCapacity: cnt)
            
            CFDictionaryGetKeysAndValues(cf, keys, values)
            
            for idx in 0..<cnt {
                let key = unsafeBitCast(keys.advanced(by: idx).pointee!, to: AnyObject.self)
                let value = unsafeBitCast(values.advanced(by: idx).pointee!, to: AnyObject.self)
                guard let k = key as? Key, let v = value as? Value else {
                    failedConversion = true
                    break
                }
                dict[k] = v
            }
            keys.deinitialize(count: cnt)
            values.deinitialize(count: cnt)
            keys.deallocateCapacity(cnt)
            values.deallocateCapacity(cnt)
        }
        if !failedConversion {
            result = dict
        }
    }
    
    public static func _conditionallyBridgeFromObject(_ x: NSDictionary, result: inout Dictionary?) -> Bool {
        _forceBridgeFromObject(x, result: &result)
        return true
    }
}

public class NSDictionary : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFDictionaryGetTypeID())
    internal var _storage = [NSObject: AnyObject]()
    
    public var count: Int {
        guard self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }
        return _storage.count
    }
    
    public func objectForKey(_ aKey: AnyObject) -> AnyObject? {
        guard self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }
        return _storage[aKey as! NSObject]
    }
    
    public func keyEnumerator() -> NSEnumerator {
        guard self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }
        return NSGeneratorEnumerator(_storage.keys.makeIterator())
    }
    
    public override convenience init() {
        self.init(objects: [], forKeys: [], count: 0)
    }
    
    public required init(objects: UnsafePointer<AnyObject>, forKeys keys: UnsafePointer<NSObject>, count cnt: Int) {
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
            withUnsafeMutablePointer(&cnt) { (ptr: UnsafeMutablePointer<UInt32>) -> Void in
                aDecoder.decodeValueOfObjCType("i", at: UnsafeMutablePointer<Void>(ptr))
            }
            let keys = UnsafeMutablePointer<NSObject>(allocatingCapacity: Int(cnt))
            let objects = UnsafeMutablePointer<AnyObject>(allocatingCapacity: Int(cnt))
            for idx in 0..<cnt {
                keys.advanced(by: Int(idx)).initialize(with: aDecoder.decodeObject()! as! NSObject)
                objects.advanced(by: Int(idx)).initialize(with: aDecoder.decodeObject()!)
            }
            self.init(objects: UnsafePointer<AnyObject>(objects), forKeys: UnsafePointer<NSObject>(keys), count: Int(cnt))
            keys.deinitialize(count: Int(cnt))
            keys.deallocateCapacity(Int(cnt))
            objects.deinitialize(count: Int(cnt))
            objects.deallocateCapacity(Int(cnt))
            
        } else if aDecoder.dynamicType == NSKeyedUnarchiver.self || aDecoder.containsValueForKey("NS.objects") {
            let keys = aDecoder._decodeArrayOfObjectsForKey("NS.keys").map() { return $0 as! NSObject }
            let objects = aDecoder._decodeArrayOfObjectsForKey("NS.objects")
            self.init(objects: objects, forKeys: keys)
        } else {
            var objects = [AnyObject]()
            var keys = [NSObject]()
            var count = 0
            while let key = aDecoder.decodeObjectForKey("NS.key.\(count)"),
                let object = aDecoder.decodeObjectForKey("NS.object.\(count)") {
                    keys.append(key as! NSObject)
                    objects.append(object)
                    count += 1
            }
            self.init(objects: objects, forKeys: keys)
        }
    }
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        if let keyedArchiver = aCoder as? NSKeyedArchiver {
            keyedArchiver._encodeArrayOfObjects(self.allKeys._nsObject, forKey:"NS.keys")
            keyedArchiver._encodeArrayOfObjects(self.allValues._nsObject, forKey:"NS.objects")
        } else {
            NSUnimplemented()
        }
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }

    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        if self.dynamicType === NSDictionary.self {
            // return self for immutable type
            return self
        } else if self.dynamicType === NSMutableDictionary.self {
            let dictionary = NSDictionary()
            dictionary._storage = self._storage
            return dictionary
        }
        return NSDictionary(objects: self.allValues, forKeys: self.allKeys.map({ $0 as! NSObject}))
    }

    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }

    public func mutableCopyWithZone(_ zone: NSZone) -> AnyObject {
        if self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self {
            // always create and return an NSMutableDictionary
            let mutableDictionary = NSMutableDictionary()
            mutableDictionary._storage = self._storage
            return mutableDictionary
        }
        return NSMutableDictionary(objects: self.allValues, forKeys: self.allKeys.map({ $0 as! NSObject}))
    }

    public convenience init(object: AnyObject, forKey key: NSCopying) {
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
    
    public convenience init(objects: [AnyObject], forKeys keys: [NSObject]) {
        let keyBuffer = UnsafeMutablePointer<NSObject>(allocatingCapacity: keys.count)
        keyBuffer.initializeFrom(keys)

        let valueBuffer = UnsafeMutablePointer<AnyObject>(allocatingCapacity: objects.count)
        valueBuffer.initializeFrom(objects)

        self.init(objects: valueBuffer, forKeys:keyBuffer, count: keys.count)
        
        keyBuffer.deinitialize(count: keys.count)
        valueBuffer.deinitialize(count: objects.count)
        keyBuffer.deallocateCapacity(keys.count)
        valueBuffer.deallocateCapacity(objects.count)
    }

    public override func isEqual(_ object: AnyObject?) -> Bool {
        guard let otherDictionary = object as? NSDictionary else {
            return false
        }
        return self.isEqualToDictionary(otherDictionary.bridge())
    }

    public override var hash: Int {
        return self.count
    }

    public var allKeys: [AnyObject] {
        if self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self {
            return _storage.keys.map { $0 }
        } else {
            var keys = [AnyObject]()
            let enumerator = keyEnumerator()
            while let key = enumerator.nextObject() {
                keys.append(key)
            }
            return keys
        }
    }
    
    public var allValues: [AnyObject] {
        if self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self {
            return _storage.values.map { $0 }
        } else {
            var values = [AnyObject]()
            let enumerator = keyEnumerator()
            while let key = enumerator.nextObject() {
                values.append(objectForKey(key)!)
            }
            return values
        }
    }
    
    /// Alternative pseudo funnel method for fastpath fetches from dictionaries
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func getObjects(_ objects: inout [AnyObject], andKeys keys: inout [AnyObject], count: Int) {
        if self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self {
            for (key, value) in _storage {
                keys.append(key)
                objects.append(value)
            }
        } else {
            
            let enumerator = keyEnumerator()
            while let key = enumerator.nextObject() {
                let value = objectForKey(key)!
                keys.append(key)
                objects.append(value)
            }
        }
    }
    
    public subscript (key: AnyObject) -> AnyObject? {
        return objectForKey(key)
    }
    
    
    public func allKeysForObject(_ anObject: AnyObject) -> [AnyObject] {
        var matching = Array<AnyObject>()
        enumerateKeysAndObjectsWithOptions([]) { key, value, _ in
            if value === anObject {
                matching.append(key)
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
    public override var description: String {
        return descriptionWithLocale(nil)
    }

    public var descriptionInStringsFileFormat: String { NSUnimplemented() }

    /// Returns a string object that represents the contents of the dictionary,
    /// formatted as a property list.
    ///
    /// - parameter locale: An object that specifies options used for formatting
    ///   each of the dictionary’s keys and values; pass `nil` if you don’t
    ///   want them formatted.
    public func descriptionWithLocale(_ locale: AnyObject?) -> String {
        return descriptionWithLocale(locale, indent: 0)
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
    public func descriptionWithLocale(_ locale: AnyObject?, indent level: Int) -> String {
        if level > 100 { return "..." }

        var lines = [String]()
        let indentation = String(repeating: Character(" "), count: level * 4)
        lines.append(indentation + "{")

        for key in self.allKeys {
            var line = String(repeating: Character(" "), count: (level + 1) * 4)

            if key is NSArray {
                line += (key as! NSArray).descriptionWithLocale(locale, indent: level + 1)
            } else if key is NSDate {
                line += (key as! NSDate).descriptionWithLocale(locale)
            } else if key is NSDecimalNumber {
                line += (key as! NSDecimalNumber).description(withLocale: locale)
            } else if key is NSDictionary {
                line += (key as! NSDictionary).descriptionWithLocale(locale, indent: level + 1)
            } else if key is NSOrderedSet {
                line += (key as! NSOrderedSet).descriptionWithLocale(locale, indent: level + 1)
            } else if key is NSSet {
                line += (key as! NSSet).descriptionWithLocale(locale)
            } else {
                line += "\(key)"
            }

            line += " = "

            let object = objectForKey(key)!
            if object is NSArray {
                line += (object as! NSArray).descriptionWithLocale(locale, indent: level + 1)
            } else if object is NSDate {
                line += (object as! NSDate).descriptionWithLocale(locale)
            } else if object is NSDecimalNumber {
                line += (object as! NSDecimalNumber).description(withLocale: locale)
            } else if object is NSDictionary {
                line += (object as! NSDictionary).descriptionWithLocale(locale, indent: level + 1)
            } else if object is NSOrderedSet {
                line += (object as! NSOrderedSet).descriptionWithLocale(locale, indent: level + 1)
            } else if object is NSSet {
                line += (object as! NSSet).descriptionWithLocale(locale)
            } else {
                line += "\(object)"
            }

            line += ";"

            lines.append(line)
        }

        lines.append(indentation + "}")
        
        return lines.joined(separator: "\n")
    }

    public func isEqualToDictionary(_ otherDictionary: [NSObject : AnyObject]) -> Bool {
        if count != otherDictionary.count {
            return false
        }
        
        for key in keyEnumerator() {
            if let otherValue = otherDictionary[key as! NSObject] as? NSObject {
                let value = objectForKey(key as! NSObject)! as! NSObject
                if otherValue != value {
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
        var keyGenerator : Array<AnyObject>.Iterator
        public mutating func next() -> (key: AnyObject, value: AnyObject)? {
            if let key = keyGenerator.next() {
                return (key, dictionary.objectForKey(key)!)
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
        var keyGenerator : Array<AnyObject>.Iterator
        mutating func next() -> AnyObject? {
            if let key = keyGenerator.next() {
                return dictionary.objectForKey(key)!
            } else {
                return nil
            }
        }
        init(_ dict : NSDictionary) {
            self.dictionary = dict
            self.keyGenerator = dict.allKeys.makeIterator()
        }
    }

    public func objectEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(ObjectGenerator(self))
    }
    
    public func objectsForKeys(_ keys: [NSObject], notFoundMarker marker: AnyObject) -> [AnyObject] {
        var objects = [AnyObject]()
        for key in keys {
            if let object = objectForKey(key) {
                objects.append(object)
            } else {
                objects.append(marker)
            }
        }
        return objects
    }
    
    public func writeToFile(_ path: String, atomically useAuxiliaryFile: Bool) -> Bool { NSUnimplemented() }
    public func writeToURL(_ url: NSURL, atomically: Bool) -> Bool { NSUnimplemented() } // the atomically flag is ignored if url of a type that cannot be written atomically.
    
    public func enumerateKeysAndObjectsUsingBlock(_ block: (NSObject, AnyObject, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateKeysAndObjectsWithOptions([], usingBlock: block)
    }

    public func enumerateKeysAndObjectsWithOptions(_ opts: NSEnumerationOptions, usingBlock block: (NSObject, AnyObject, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let count = self.count
        var keys = [AnyObject]()
        var objects = [AnyObject]()
        getObjects(&objects, andKeys: &keys, count: count)
        var stop = ObjCBool(false)
        for idx in 0..<count {
            withUnsafeMutablePointer(&stop, { stop in
                block(keys[idx] as! NSObject, objects[idx], stop)
            })

            if stop {
                break
            }
        }
    }
    
    public func keysSortedByValueUsingComparator(_ cmptr: NSComparator) -> [AnyObject] {
        return keysSortedByValueWithOptions([], usingComparator: cmptr)
    }

    public func keysSortedByValueWithOptions(_ opts: NSSortOptions, usingComparator cmptr: NSComparator) -> [AnyObject] {
        let sorted = allKeys.sorted { lhs, rhs in
            return cmptr(lhs, rhs) == .orderedSame
        }
        return sorted
    }

    public func keysOfEntriesPassingTest(_ predicate: (AnyObject, AnyObject, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Set<NSObject> {
        return keysOfEntriesWithOptions([], passingTest: predicate)
    }

    public func keysOfEntriesWithOptions(_ opts: NSEnumerationOptions, passingTest predicate: (AnyObject, AnyObject, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Set<NSObject> {
        var matching = Set<NSObject>()
        enumerateKeysAndObjectsWithOptions(opts) { key, value, stop in
            if predicate(key, value, stop) {
                matching.insert(key)
            }
        }
        return matching
    }
    
    override public var _cfTypeID: CFTypeID {
        return CFDictionaryGetTypeID()
    }
    
    required public convenience init(dictionaryLiteral elements: (NSObject, AnyObject)...) {
        var keys = [NSObject]()
        var values = [AnyObject]()

        for (key, value) in elements {
            keys.append(key)
            values.append(value)
        }
        
        self.init(objects: values, forKeys: keys)
    }
}

extension NSDictionary : _CFBridgable, _SwiftBridgable {
    internal var _cfObject: CFDictionary { return unsafeBitCast(self, to: CFDictionary.self) }
    internal var _swiftObject: Dictionary<NSObject, AnyObject> {
        var dictionary: [NSObject: AnyObject]?
        Dictionary._forceBridgeFromObject(self, result: &dictionary)
        return dictionary!
    }
}

extension NSMutableDictionary {
    internal var _cfMutableObject: CFMutableDictionary { return unsafeBitCast(self, to: CFMutableDictionary.self) }
}

extension CFDictionary : _NSBridgable, _SwiftBridgable {
    internal var _nsObject: NSDictionary { return unsafeBitCast(self, to: NSDictionary.self) }
    internal var _swiftObject: [NSObject: AnyObject] { return _nsObject._swiftObject }
}

extension Dictionary : _NSBridgable, _CFBridgable {
    internal var _nsObject: NSDictionary { return _bridgeToObject() }
    internal var _cfObject: CFDictionary { return _nsObject._cfObject }
}

public class NSMutableDictionary : NSDictionary {
    
    public func removeObjectForKey(_ aKey: AnyObject) {
        guard self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }

        if let key = aKey as? NSObject {
            _storage.removeValue(forKey: key)
        }
    }
    
    public func setObject(_ anObject: AnyObject, forKey aKey: NSObject) {
        guard self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }
        _storage[aKey] = anObject
    }
    
    public convenience required init() {
        self.init(capacity: 0)
    }
    
    public convenience init(capacity numItems: Int) {
        self.init(objects: [], forKeys: [], count: 0)
    }
    
    public required init(objects: UnsafePointer<AnyObject>, forKeys keys: UnsafePointer<NSObject>, count cnt: Int) {
        super.init(objects: objects, forKeys: keys, count: cnt)
    }
    
    public convenience init?(contentsOfFile path: String) { NSUnimplemented() }
    public convenience init?(contentsOfURL url: NSURL) { NSUnimplemented() }

}

extension NSMutableDictionary {
    
    public func addEntriesFromDictionary(_ otherDictionary: [NSObject : AnyObject]) {
        for (key, obj) in otherDictionary {
            setObject(obj, forKey: key)
        }
    }
    
    public func removeAllObjects() {
        if self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self {
            _storage.removeAll()
//            CFDictionaryRemoveAllValues(unsafeBitCast(self, CFMutableDictionaryRef.self))
        } else {
            for key in allKeys {
                removeObjectForKey(key)
            }
        }
    }
    
    public func removeObjectsForKeys(_ keyArray: [AnyObject]) {
        for key in keyArray {
            removeObjectForKey(key)
        }
    }
    
    public func setDictionary(_ otherDictionary: [NSObject : AnyObject]) {
        if self.dynamicType === NSDictionary.self || self.dynamicType === NSMutableDictionary.self {
            _storage = otherDictionary
        } else {
            removeAllObjects()
            for (key, obj) in otherDictionary {
                setObject(obj, forKey: key)
            }
        }
    }
    
    public subscript (key: NSObject) -> AnyObject? {
        get {
            return objectForKey(key)
        }
        set {
            if let val = newValue {
                setObject(val, forKey: key)
            } else {
                removeObjectForKey(key)
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
    public class func sharedKeySetForKeys(_ keys: [NSCopying]) -> AnyObject { NSUnimplemented() }
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

extension NSDictionary : DictionaryLiteralConvertible { }

extension Dictionary : Bridgeable {
    public func bridge() -> NSDictionary { return _nsObject }
}

extension NSDictionary : Bridgeable {
    public func bridge() -> [NSObject: AnyObject] { return _swiftObject }
}
