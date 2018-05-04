// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/****************       Immutable Ordered Set   ****************/
open class NSOrderedSet : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, ExpressibleByArrayLiteral {
    internal var _storage: Set<NSObject>
    internal var _orderedStorage: [NSObject]
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        NSUnimplemented()
    }

    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }

    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        NSUnimplemented()
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let orderedSet = object as? NSOrderedSet else { return false }
        return isEqual(to: orderedSet)
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        for idx in 0..<self.count {
            aCoder.encode(_SwiftValue.store(self.object(at: idx)), forKey:"NS.object.\(idx)")
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        var idx = 0
        var objects : [AnyObject] = []
        while aDecoder.containsValue(forKey: ("NS.object.\(idx)")) {
            guard let object = aDecoder.decodeObject(forKey: "NS.object.\(idx)") else {
                return nil
            }
            objects.append(object as! NSObject)
            idx += 1
        }
        self.init(array: objects)
    }
    
    open var count: Int {
        return _storage.count
    }

    open func object(at idx: Int) -> Any {
        return _SwiftValue.fetch(nonOptional: _orderedStorage[idx])
    }

    open func index(of object: Any) -> Int {
        return _orderedStorage.index(of: _SwiftValue.store(object)) ?? NSNotFound
    }

    public convenience override init() {
        self.init(objects: [], count: 0)
    }

    public init(objects: UnsafePointer<AnyObject>!, count cnt: Int) {
        _storage = Set<NSObject>()
        _orderedStorage = [NSObject]()

        super.init()

        _insertObjects(objects, count: cnt)
    }
    
    required public convenience init(arrayLiteral elements: Any...) {
      self.init(array: elements)
    }

    public convenience init(objects elements: Any...) {
      self.init(array: elements)
    }
    
    open subscript (idx: Int) -> Any {
        return object(at: idx)
    }

    fileprivate func _insertObject(_ object: Any) {
        let value = _SwiftValue.store(object)
        guard !contains(value) else {
            return
        }

        _storage.insert(value)
        _orderedStorage.append(value)
    }

    fileprivate func _insertObjects(_ objects: UnsafePointer<AnyObject>!, count cnt: Int) {
        let buffer = UnsafeBufferPointer(start: objects, count: cnt)
        for obj in buffer {
            _insertObject(obj)
        }
    }
    
    internal var allObjects: [Any] {
        if type(of: self) === NSOrderedSet.self || type(of: self) === NSMutableOrderedSet.self {
            return _orderedStorage.map { _SwiftValue.fetch(nonOptional: $0) }
        } else {
            return (0..<count).map { idx in
                return self[idx]
            }
        }
    }
}

extension NSOrderedSet : Sequence {
    /// Return a *generator* over the elements of this *sequence*.
    ///
    /// - Complexity: O(1).
    public typealias Iterator = NSEnumerator.Iterator
    public func makeIterator() -> Iterator {
        return self.objectEnumerator().makeIterator()
    }
}

extension NSOrderedSet {

    public func getObjects(_ objects: inout [AnyObject], range: NSRange) {
        for idx in range.location..<(range.location + range.length) {
            objects.append(_orderedStorage[idx])
        }
    }

    open func objects(at indexes: IndexSet) -> [Any] {
        var entries = [Any]()
        for idx in indexes {
            guard idx < count && idx >= 0 else {
                fatalError("\(self): Index out of bounds")
            }
            entries.append(object(at: idx))
        }
        return entries
    }

    public var firstObject: Any? {
        if let value = _orderedStorage.first {
            return _SwiftValue.fetch(nonOptional: value)
        } else {
            return nil
        }
    }

    public var lastObject: Any? {
        if let value = _orderedStorage.last {
            return _SwiftValue.fetch(nonOptional: value)
        } else {
            return nil
        }
    }

    open func isEqual(to other: NSOrderedSet) -> Bool {
        if count != other.count {
            return false
        }
        
        for idx in 0..<count {
            if let value1 = object(at: idx) as? AnyHashable,
               let value2 = other.object(at: idx) as? AnyHashable {
                if value1 != value2 {
                    return false
                }
            }
        }
        
        return true
    }
    
    open func contains(_ object: Any) -> Bool {
        return _storage.contains(_SwiftValue.store(object))
    }

    open func intersects(_ other: NSOrderedSet) -> Bool {
        if count < other.count {
            return contains { obj in other.contains(obj) }
        } else {
            return other.contains { obj in contains(obj) }
        }
    }

    open func intersectsSet(_ set: Set<AnyHashable>) -> Bool {
        if count < set.count {
            return contains { obj in set.contains(obj) }
        } else {
            return set.contains { obj in contains(obj) }
        }
    }
    
    open func isSubset(of other: NSOrderedSet) -> Bool {
        for item in self {
            if !other.contains(item) {
                return false
            }
        }
        return true
    }

    open func isSubset(of set: Set<AnyHashable>) -> Bool {
        for item in self {
            if !set.contains(item as! AnyHashable) {
                return false
            }
        }
        return true
    }
    
    public func objectEnumerator() -> NSEnumerator {
        guard type(of: self) === NSOrderedSet.self || type(of: self) === NSMutableOrderedSet.self else {
            NSRequiresConcreteImplementation()
        }
        return NSGeneratorEnumerator(_orderedStorage.map { _SwiftValue.fetch(nonOptional: $0) }.makeIterator())
    }

    public func reverseObjectEnumerator() -> NSEnumerator { 
        guard type(of: self) === NSOrderedSet.self || type(of: self) === NSMutableOrderedSet.self else {
            NSRequiresConcreteImplementation()
        }
        return NSGeneratorEnumerator(_orderedStorage.map { _SwiftValue.fetch(nonOptional: $0) }.reversed().makeIterator())
    }
    
    /*@NSCopying*/ 
    public var reversed: NSOrderedSet {
        return NSOrderedSet(array: _orderedStorage.map { _SwiftValue.fetch(nonOptional: $0) }.reversed())
    }
    
    // These two methods return a facade object for the receiving ordered set,
    // which acts like an immutable array or set (respectively).  Note that
    // while you cannot mutate the ordered set through these facades, mutations
    // to the original ordered set will "show through" the facade and it will
    // appear to change spontaneously, since a copy of the ordered set is not
    // being made.
    public var array: [Any] { NSUnimplemented() }
    public var set: Set<AnyHashable> { NSUnimplemented() }
    
    open func enumerateObjects(_ block: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) { NSUnimplemented() }
    open func enumerateObjects(options opts: NSEnumerationOptions = [], using block: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) { NSUnimplemented() }
    open func enumerateObjects(at s: IndexSet, options opts: NSEnumerationOptions = [], using block: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) { NSUnimplemented() }
    
    open func index(ofObjectPassingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int { NSUnimplemented() }
    open func index(_ opts: NSEnumerationOptions = [], ofObjectPassingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int { NSUnimplemented() }
    open func index(ofObjectAt s: IndexSet, options opts: NSEnumerationOptions = [], passingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int { NSUnimplemented() }
    
    open func indexes(ofObjectsPassingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet { NSUnimplemented() }
    open func indexes(options opts: NSEnumerationOptions = [], ofObjectsPassingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet { NSUnimplemented() }
    open func indexes(ofObjectsAt s: IndexSet, options opts: NSEnumerationOptions = [], passingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet { NSUnimplemented() }
    
    open func index(of object: Any, inSortedRange range: NSRange, options opts: NSBinarySearchingOptions = [], usingComparator cmp: (Any, Any) -> ComparisonResult) -> Int { NSUnimplemented() } // binary search
    
    open func sortedArray(comparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] { NSUnimplemented() }
    open func sortedArray(options opts: NSSortOptions = [], usingComparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] { NSUnimplemented() }
    
    public func description(withLocale locale: Locale?) -> String { NSUnimplemented() }
    public func description(withLocale locale: Locale?, indent level: Int) -> String { NSUnimplemented() }
}

extension NSOrderedSet {
    
    public convenience init(object: Any) {
        self.init(array: [object])
    }
    
    public convenience init(orderedSet set: NSOrderedSet) {
        self.init(orderedSet: set, copyItems: false)
    }

    public convenience init(orderedSet set: NSOrderedSet, copyItems flag: Bool) {
        self.init(orderedSet: set, range: NSRange(location: 0, length: set.count), copyItems: flag)
    }

    public convenience init(orderedSet set: NSOrderedSet, range: NSRange, copyItems flag: Bool) {
        // TODO: Use the array method here when available.
        self.init(array: Array(set), range: range, copyItems: flag)
    }

    public convenience init(array: [Any]) {
        let buffer = UnsafeMutablePointer<AnyObject>.allocate(capacity: array.count)
        for (idx, element) in array.enumerated() {
            buffer.advanced(by: idx).initialize(to: _SwiftValue.store(element))
        }
        self.init(objects: buffer, count: array.count)
        buffer.deinitialize(count: array.count)
        buffer.deallocate()
    }

    public convenience init(array set: [Any], copyItems flag: Bool) {
        self.init(array: set, range: NSRange(location: 0, length: set.count), copyItems: flag)
    }

    public convenience init(array set: [Any], range: NSRange, copyItems flag: Bool) {
        var objects = set

        if let range = Range(range), range.count != set.count || flag {
            objects = [Any]()
            for index in range.indices {
                let object = set[index]
                objects.append(flag ? (object as! NSObject).copy() : object)
            }
        }

        self.init(array: objects)
    }

    public convenience init(set: Set<AnyHashable>) {
        self.init(set: set, copyItems: false)
    }

    public convenience init(set: Set<AnyHashable>, copyItems flag: Bool) {
        self.init(array: Array(set), copyItems: flag)
    }
}


/****************       Mutable Ordered Set     ****************/

open class NSMutableOrderedSet : NSOrderedSet {
    
    open func insert(_ object: Any, at idx: Int) {
        guard idx <= count && idx >= 0 else {
            fatalError("\(self): Index out of bounds")
        }

        let value = _SwiftValue.store(object)

        if contains(value) {
            return
        }
        
        _storage.insert(value)
        _orderedStorage.insert(value, at: idx)
    }

    open func removeObject(at idx: Int) {
        _storage.remove(_orderedStorage[idx])
        _orderedStorage.remove(at: idx)
    }

    open func replaceObject(at idx: Int, with obj: Any) {
        guard idx < count && idx >= 0 else {
            fatalError("\(self): Index out of bounds")
        }
        
        let value = _SwiftValue.store(obj)
        let objectToReplace = _SwiftValue.store(object(at: idx))
        _orderedStorage[idx] = value
        _storage.remove(objectToReplace)
        _storage.insert(value)
    }

    public init(capacity numItems: Int) {
        super.init(objects: [], count: 0)
    }

    required public convenience init(arrayLiteral elements: Any...) {
        self.init(capacity: 0)

        addObjects(from: elements)
    }

    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }

    fileprivate func _removeObject(_ object: Any) {
        let value = _SwiftValue.store(object)
        
        guard contains(object) else {
            return
        }

        _storage.remove(value)
        _orderedStorage.remove(at: index(of: object))
    }

    open override subscript(idx: Int) -> Any {
        get {
            return object(at: idx)
        }
        set {
            replaceObject(at: idx, with: newValue)
        }
    }
    
}

extension NSMutableOrderedSet {
    
    open func add(_ object: Any) {
        _insertObject(object)
    }

    open func add(_ objects: UnsafePointer<AnyObject>!, count: Int) {
        _insertObjects(objects, count: count)
    }

    open func addObjects(from array: [Any]) {
        for object in array {
            _insertObject(object)
        }
    }
    
    open func exchangeObject(at idx1: Int, withObjectAt idx2: Int) {
        guard idx1 < count && idx1 >= 0 && idx2 < count && idx2 >= 0 else {
            fatalError("\(self): Index out of bounds")
        }

        let object1 = self.object(at: idx1)
        let object2 = self.object(at: idx2)
        _orderedStorage[idx1] = _SwiftValue.store(object2)
        _orderedStorage[idx2] = _SwiftValue.store(object1)
    }

    open func moveObjects(at indexes: IndexSet, to idx: Int) {
        var removedObjects = [Any]()
        for index in indexes.lazy.reversed() {
            let obj = object(at: index)
            removedObjects.append(obj)
            removeObject(at: index)
            
        }
        for removedObject in removedObjects {
            insert(removedObject, at: idx)
        }
    }
    
    open func insert(_ objects: [Any], at indexes: IndexSet) {
        for (indexLocation, index) in indexes.enumerated() {
            let object = objects[indexLocation]
            insert(object, at: index)
        }
    }
    
    open func setObject(_ obj: Any, at idx: Int) {
        let object = _SwiftValue.store(obj)
        _storage.insert(object)
        if idx == _orderedStorage.count {
            _orderedStorage.append(object)
        } else {
            _orderedStorage[idx] = object
        }
    }
    
    open func replaceObjects(in range: NSRange, with objects: UnsafePointer<AnyObject>!, count: Int) {
        if let range = Range(range) {
            let buffer = UnsafeBufferPointer(start: objects, count: count)
            for (indexLocation, index) in range.indices.lazy.reversed().enumerated() {
                let object = buffer[indexLocation]
                replaceObject(at: index, with: object)
            }
        }
    }

    open func replaceObjects(at indexes: IndexSet, with objects: [Any]) {
        for (indexLocation, index) in indexes.enumerated() {
            let object = objects[indexLocation]
            replaceObject(at: index, with: object)
        }
    }
    
    open func removeObjects(in range: NSRange) {
        if let range = Range(range) {
            for index in range.indices.lazy.reversed() {
                removeObject(at: index)
            }
        }
    }

    open func removeObjects(at indexes: IndexSet) {
        for index in indexes.lazy.reversed() {
            removeObject(at: index)
        }
    }

    public func removeAllObjects() {
        _storage.removeAll()
        _orderedStorage.removeAll()
    }
    
    open func remove(_ val: Any) {
        let object = _SwiftValue.store(val)
        
        _storage.remove(object)
        _orderedStorage.remove(at: index(of: val))
    }

    open func removeObjects(in array: [Any]) {
        array.forEach(remove)
    }
    
    open func intersect(_ other: NSOrderedSet) {
        for item in self where !other.contains(item) {
            remove(item)
        }
    }

    open func minus(_ other: NSOrderedSet) {
        for item in other where contains(item) {
            remove(item)
        }
    }

    open func union(_ other: NSOrderedSet) {
        other.forEach(add)
    }
    
    open func intersectSet(_ other: Set<AnyHashable>) {
        for case let item as AnyHashable in self where !other.contains(item) {
            remove(item)
        }
    }

    open func minusSet(_ other: Set<AnyHashable>) {
        for item in other where contains(item) {
            remove(item)
        }
    }

    open func unionSet(_ other: Set<AnyHashable>) {
        other.forEach(add)
    }
    
    open func sort(comparator cmptr: (Any, Any) -> ComparisonResult) {
        sortRange(NSRange(location: 0, length: count), options: [], usingComparator: cmptr)
    }

    open func sort(options opts: NSSortOptions = [], usingComparator cmptr: (Any, Any) -> ComparisonResult) {
        sortRange(NSRange(location: 0, length: count), options: opts, usingComparator: cmptr)
    }

    open func sortRange(_ range: NSRange, options opts: NSSortOptions = [], usingComparator cmptr: (Any, Any) -> ComparisonResult) {
        // The sort options are not available. We use the Array's sorting algorithm. It is not stable neither concurrent.
        guard opts.isEmpty else {
            NSUnimplemented()
        }

        let swiftRange = Range(range)!
        _orderedStorage[swiftRange].sort { lhs, rhs in
            return cmptr(_SwiftValue.fetch(nonOptional: lhs), _SwiftValue.fetch(nonOptional: rhs)) == .orderedAscending
        }
    }
}
