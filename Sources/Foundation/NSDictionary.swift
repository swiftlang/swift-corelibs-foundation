// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


internal import CoreFoundation

#if !os(WASI)
import Dispatch
#endif

fileprivate func getDescription(of object: Any) -> String? {
    switch object {
    case let nsArray as NSArray:
        return nsArray.description(withLocale: nil, indent: 1)
    case let nsDecimalNumber as NSDecimalNumber:
        return nsDecimalNumber.description(withLocale: nil)
    case let nsDate as NSDate:
        return nsDate.description(with: nil)
    case let nsOrderedSet as NSOrderedSet:
        return nsOrderedSet.description(withLocale: nil)
    case let nsSet as NSSet:
        return nsSet.description(withLocale: nil)
    case let nsDictionary as NSDictionary:
        return nsDictionary.description(withLocale: nil)
    case let hashableObject as Dictionary<AnyHashable, Any>:
        return hashableObject._nsObject.description(withLocale: nil, indent: 1)
    default:
        return nil
    }
}

@available(*, unavailable)
extension NSDictionary : @unchecked Sendable { }

@available(*, unavailable)
extension NSDictionary.Iterator : Sendable { }

open class NSDictionary : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding, ExpressibleByDictionaryLiteral {
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
        if let val = _storage[__SwiftValue.store(aKey)] {
            return __SwiftValue.fetch(nonOptional: val)
        }
        return nil
    }
    
    open func value(forKey key: String) -> Any? {
        if key.hasPrefix("@") {
            NSUnsupported()
        } else {
            return object(forKey: key)
        }
    }
    
    open func keyEnumerator() -> NSEnumerator {
        guard type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }
        
        return NSGeneratorEnumerator(_storage.keys.map { __SwiftValue.fetch(nonOptional: $0) }.makeIterator())
    }
    
#if !os(WASI)
    @available(*, deprecated)
    public convenience init?(contentsOfFile path: String) {
        self.init(contentsOf: URL(fileURLWithPath: path))
    }
    
    @available(*, deprecated)
    public convenience init?(contentsOf url: URL) {
        do {
            guard let plistDoc = try? Data(contentsOf: url) else { return nil }
            let plistDict = try PropertyListSerialization.propertyList(from: plistDoc, options: [], format: nil) as? Dictionary<AnyHashable,Any>
            guard let plistDictionary = plistDict else { return nil }
            self.init(dictionary: plistDictionary)
        } catch {
            return nil
        }
    }
#endif
    
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

    public convenience init(object: Any, forKey key: NSCopying) {
        self.init(objects: [object], forKeys: [key as! NSObject])
    }

    public convenience init(objects: [Any], forKeys keys: [NSObject]) {
        let keyBuffer = UnsafeMutablePointer<NSObject>.allocate(capacity: keys.count)
        keyBuffer.initialize(from: keys, count: keys.count)

        let valueBuffer = UnsafeMutablePointer<AnyObject>.allocate(capacity: objects.count)
        valueBuffer.initialize(from: objects.map { __SwiftValue.store($0) }, count: objects.count)

        self.init(objects: valueBuffer, forKeys:keyBuffer, count: keys.count)

        keyBuffer.deinitialize(count: keys.count)
        valueBuffer.deinitialize(count: objects.count)
        keyBuffer.deallocate()
        valueBuffer.deallocate()
    }

    public convenience init(dictionary otherDictionary: [AnyHashable : Any]) {
        self.init(dictionary: otherDictionary, copyItems: false)
    }

    public convenience init(dictionary otherDictionary: [AnyHashable: Any], copyItems flag: Bool) {
        if flag {
            self.init(objects: Array(otherDictionary.values.map { __SwiftValue($0).copy() as! NSObject }), forKeys: otherDictionary.keys.map { __SwiftValue.store($0).copy() as! NSObject})
        } else {
            self.init(objects: Array(otherDictionary.values), forKeys: otherDictionary.keys.map { __SwiftValue.store($0) })
        }
    }

    required public convenience init(dictionaryLiteral elements: (Any, Any)...) {
        var keys = [NSObject]()
        var values = [Any]()

        for (key, value) in elements {
            keys.append(__SwiftValue.store(key))
            values.append(value)
        }

        self.init(objects: values, forKeys: keys)
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        if type(of: aDecoder) == NSKeyedUnarchiver.self || aDecoder.containsValue(forKey: "NS.objects") {
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
            guard aCoder.allowsKeyedCoding else {
                preconditionFailure("Unkeyed decoding is unsupported.")
            }
            
            var count = 0
            var keyKey: String {
                "NS.key.\(count)"
            }
            var objectKey: String {
                "NS.object.\(count)"
            }
            for key in self.allKeys {
                aCoder.encode(key as AnyObject, forKey: keyKey)
                aCoder.encode(self[key] as AnyObject, forKey: objectKey)
                count += 1
            }
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
        return NSMutableDictionary(objects: self.allValues, forKeys: self.allKeys.map { __SwiftValue.store($0) } )
    }

    open override func isEqual(_ value: Any?) -> Bool {
        switch value {
        case let other as Dictionary<AnyHashable, Any>:
            return isEqual(to: other)
        case let other as NSDictionary:
            return isEqual(to: Dictionary._unconditionallyBridgeFromObjectiveC(other))
        default:
            return false
        }
    }

    open override var hash: Int {
        return self.count
    }

    open var allKeys: [Any] {
        if type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self {
            return Array(_storage.keys)
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
            return Array(_storage.values)
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
                keys.append(__SwiftValue.fetch(nonOptional: key))
                objects.append(__SwiftValue.fetch(nonOptional: value))
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
        enumerateKeysAndObjects(options: []) { key, value, _ in
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
    
    open var descriptionInStringsFileFormat: String {
        var lines = [String]()
        for key in self.allKeys {
            let line = NSMutableString(capacity: 0)
            line.append("\"")
            if let descriptionByType = getDescription(of: key) {
                line.append(descriptionByType)
            } else {
                line.append("\(key)")
            }
            line.append("\"")
            line.append(" = ")
            line.append("\"")
            let value = self.object(forKey: key)!
            if let descriptionByTypeValue = getDescription(of: value) {
                line.append(descriptionByTypeValue)
            } else {
                line.append("\(value)")
            }
            line.append("\"")
            line.append(";")
            lines.append(line._bridgeToSwift())
        }
        return lines.joined(separator: "\n")
    }

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

        let nextLevelIndentation = String(repeating: " ", count: (level + 1) * 4)
        for key in self.allKeys {
            var line = nextLevelIndentation

            switch key {
            case let nsArray as NSArray:
                line += nsArray.description(withLocale: locale, indent: level + 1)
            case let nsDate as Date:
                line += nsDate.description(with: locale)
            case let nsDecimalNumber as NSDecimalNumber:
                line += nsDecimalNumber.description(withLocale: locale)
            case let nsDictionary as NSDictionary:
                line += nsDictionary.description(withLocale: locale, indent: level + 1)
            case let nsOderedSet as NSOrderedSet:
                line += nsOderedSet.description(withLocale: locale, indent: level + 1)
            case let nsSet as NSSet:
                line += nsSet.description(withLocale: locale)
            default:
                line += "\(key)"
            }

            line += " = "

            let object = self.object(forKey: key)!
            switch object {
            case let nsArray as NSArray:
                line += nsArray.description(withLocale: locale, indent: level + 1)
            case let nsDate as NSDate:
                line += nsDate.description(with: locale)
            case let nsDecimalNumber as NSDecimalNumber:
                line += nsDecimalNumber.description(withLocale: locale)
            case let nsDictionary as NSDictionary:
                line += nsDictionary.description(withLocale: locale, indent: level + 1)
            case let nsOrderedSet as NSOrderedSet:
                line += nsOrderedSet.description(withLocale: locale, indent: level + 1)
            case let nsSet as NSSet:
                line += nsSet.description(withLocale: locale)
            case let hashableObject as Dictionary<AnyHashable, Any>:
                line += hashableObject._nsObject.description(withLocale: nil, indent: level + 1)
            default:
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
            } else {
                let otherBridgeable = otherDictionary[key as! AnyHashable]
                let bridgeable = object(forKey: key)!
                let equal = __SwiftValue.store(optional: otherBridgeable)?.isEqual(__SwiftValue.store(bridgeable))
                if equal != true {
                    return false
                }
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
    
#if !os(WASI)
    open func write(toFile path: String, atomically useAuxiliaryFile: Bool) -> Bool {
        return write(to: URL(fileURLWithPath: path), atomically: useAuxiliaryFile)
    }
    
    // the atomically flag is ignored if url of a type that cannot be written atomically.
    open func write(to url: URL, atomically: Bool) -> Bool {
        do {
            let pListData = try PropertyListSerialization.data(fromPropertyList: self, format: .xml, options: 0)
            try pListData.write(to: url, options: atomically ? .atomic : [])
            return true
        } catch {
            return false
        }
    }
#endif
    
    open func enumerateKeysAndObjects(_ block: (Any, Any, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        enumerateKeysAndObjects(options: [], using: block)
    }

    open func enumerateKeysAndObjects(options opts: NSEnumerationOptions = [], using block: (Any, Any, UnsafeMutablePointer<ObjCBool>) -> Void) {
        let count = self.count
        var keys = [Any]()
        var objects = [Any]()
        var sharedStop = ObjCBool(false)
        let lock = NSLock()
        
        getObjects(&objects, andKeys: &keys, count: count)
        withoutActuallyEscaping(block) { (closure: @escaping (Any, Any, UnsafeMutablePointer<ObjCBool>) -> Void) -> () in
            let iteration: (Int) -> Void = { (idx) in
                lock.lock()
                var stop = sharedStop
                lock.unlock()
                if stop.boolValue { return }
                
                closure(keys[idx], objects[idx], &stop)
                
                if stop.boolValue {
                    lock.lock()
                    sharedStop = stop
                    lock.unlock()
                    return
                }
            }

            // We ignore the concurrent option because it is not possible to make it thread-safe. The block argument is not marked Sendable.
            for idx in 0..<count {
                iteration(idx)
            }
        }
    }
    
    open func keysSortedByValue(comparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] {
        return keysSortedByValue(options: [], usingComparator: cmptr)
    }

    open func keysSortedByValue(options opts: NSSortOptions = [], usingComparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] {
        let sorted = allKeys.sorted { lhs, rhs in
            return cmptr(lhs, rhs) == .orderedSame
        }
        return sorted
    }

    open func keysOfEntries(passingTest predicate: (Any, Any, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Set<AnyHashable> {
        return keysOfEntries(options: [], passingTest: predicate)
    }

    open func keysOfEntries(options opts: NSEnumerationOptions = [], passingTest predicate: (Any, Any, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Set<AnyHashable> {
        var matching = Set<AnyHashable>()
        enumerateKeysAndObjects(options: opts) { key, value, stop in
            if predicate(key, value, stop) {
                matching.insert(key as! AnyHashable)
            }
        }
        return matching
    }
    
    internal override var _cfTypeID: CFTypeID {
        return CFDictionaryGetTypeID()
    }
}

extension NSDictionary : _SwiftBridgeable {
    internal var _cfObject: CFDictionary { return unsafeBitCast(self, to: CFDictionary.self) }
    internal var _swiftObject: Dictionary<AnyHashable, Any> { return Dictionary._unconditionallyBridgeFromObjectiveC(self) }
}

extension NSMutableDictionary {
    internal var _cfMutableObject: CFMutableDictionary { return unsafeBitCast(self, to: CFMutableDictionary.self) }
}

extension CFDictionary : _NSBridgeable, _SwiftBridgeable {
    internal var _nsObject: NSDictionary { return unsafeBitCast(self, to: NSDictionary.self) }
    internal var _swiftObject: [AnyHashable: Any] { return _nsObject._swiftObject }
}

extension Dictionary : _NSBridgeable {
    internal var _nsObject: NSDictionary { return _bridgeToObjectiveC() }
    internal var _cfObject: CFDictionary { return _nsObject._cfObject }
}

open class NSMutableDictionary : NSDictionary {
    
    open func removeObject(forKey aKey: Any) {
        guard type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }

        _storage.removeValue(forKey: __SwiftValue.store(aKey))
    }
    
    /// - Note: this diverges from the darwin version that requires NSCopying (this differential preserves allowing strings and such to be used as keys)
    open func setObject(_ anObject: Any, forKey aKey: AnyHashable) {
        guard type(of: self) === NSDictionary.self || type(of: self) === NSMutableDictionary.self else {
            NSRequiresConcreteImplementation()
        }
        _storage[__SwiftValue.store(aKey)] = __SwiftValue.store(anObject)
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

// We implement this as a shim for now. It is legal to call these methods and the behavior of the resulting NSDictionary will match Darwin's; however, the performance characteristics will be unmodified for the returned dictionary vs. a NSMutableDictionary created without a shared key set.
// SR-XXXX.

final internal class SharedKeySetPlaceholder : NSObject, Sendable { }

extension NSDictionary {
    
    static let sharedKeySetPlaceholder = SharedKeySetPlaceholder()
    
    /*  Use this method to create a key set to pass to +dictionaryWithSharedKeySet:.
    The keys are copied from the array and must be copyable.
    If the array parameter is nil or not an NSArray, an exception is thrown.
    If the array of keys is empty, an empty key set is returned.
    The array of keys may contain duplicates, which are ignored (it is undefined which object of each duplicate pair is used).
    As for any usage of hashing, is recommended that the keys have a well-distributed implementation of -hash, and the hash codes must satisfy the hash/isEqual: invariant.
    Keys with duplicate hash codes are allowed, but will cause lower performance and increase memory usage.
    */
    public class func sharedKeySet(forKeys keys: [NSCopying]) -> Any {
        return sharedKeySetPlaceholder
    }
}

extension NSMutableDictionary {
    
    /*  Create a mutable dictionary which is optimized for dealing with a known set of keys.
    Keys that are not in the key set can still be set into the dictionary, but that usage is not optimal.
    As with any dictionary, the keys must be copyable.
    If keyset is nil, an exception is thrown.
    If keyset is not an object returned by +sharedKeySetForKeys:, an exception is thrown.
    */
    public convenience init(sharedKeySet keyset: Any) {
        precondition(keyset as? NSObject == NSDictionary.sharedKeySetPlaceholder)
        self.init()
    }
}

extension NSDictionary: CustomReflectable {
    public var customMirror: Mirror {
        return Mirror(reflecting: self._storage as [NSObject: AnyObject])
    }
}

extension NSDictionary: _StructTypeBridgeable {
    public typealias _StructType = Dictionary<AnyHashable,Any>
    
    public func _bridgeToSwift() -> _StructType {
        return _StructType._unconditionallyBridgeFromObjectiveC(self)
    }
}
