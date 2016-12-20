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
    internal var _storage: NSMutableSet
    internal var _orderedStorage: NSMutableArray
    
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
        if let orderedSet = object as? NSOrderedSet {
            return isEqual(to: orderedSet)
        } else {
            return false
        }
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
        return _orderedStorage.count
    }

    open func object(at idx: Int) -> Any {
        return _orderedStorage.object(at: idx)
    }

    open func index(of object: Any) -> Int {
        return _orderedStorage.index(of: object)
    }

    public convenience override init() {
        self.init(objects: [], count: 0)
    }

    public init(objects: UnsafePointer<AnyObject>!, count cnt: Int) {
        _storage = NSMutableSet(objects: objects, count: cnt)
        _orderedStorage = NSMutableArray()
        let buffer = NSArray(objects: objects, count: cnt)
        for obj in buffer {
            if _orderedStorage.index(of: obj) == NSNotFound {
                _orderedStorage.add(obj)
            }
        }

        super.init()
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
        guard !contains(object) else {
            return
        }

        _storage.add(object)
        _orderedStorage.add(object)
    }

    fileprivate func _insertObjects(_ objects: UnsafePointer<AnyObject>!, count cnt: Int) {
        let buffer = UnsafeBufferPointer(start: objects, count: cnt)
        for obj in buffer {
            _insertObject(obj)
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
            objects.append(_orderedStorage[idx] as AnyObject)
        }
    }

    open func objects(at indexes: IndexSet) -> [Any] {
        var entries = [Any]()
        for idx in indexes {
            if idx >= count && idx < 0 {
                fatalError("\(self): Index out of bounds")
            }
            entries.append(object(at: idx))
        }
        return entries
    }

    public var firstObject: Any? {
        return _orderedStorage.firstObject
    }

    public var lastObject: Any? {
        return _orderedStorage.lastObject
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
        return _storage.contains(object)
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
        return NSGeneratorEnumerator(_orderedStorage.makeIterator())
    }

    public func reverseObjectEnumerator() -> NSEnumerator { 
        guard type(of: self) === NSOrderedSet.self || type(of: self) === NSMutableOrderedSet.self else {
            NSRequiresConcreteImplementation()
        }
        return _orderedStorage.reverseObjectEnumerator()
    }
    
    /*@NSCopying*/ 
    public var reversed: NSOrderedSet {
        return NSOrderedSet(array: _orderedStorage.reversed())
    }
    
    // These two methods return a facade object for the receiving ordered set,
    // which acts like an immutable array or set (respectively).  Note that
    // while you cannot mutate the ordered set through these facades, mutations
    // to the original ordered set will "show through" the facade and it will
    // appear to change spontaneously, since a copy of the ordered set is not
    // being made.
    public var array: [Any] {
        return _orderedStorage._bridgeToSwift()
    }
    public var set: Set<AnyHashable> {
        return _storage._bridgeToSwift()
    }
    
    open func enumerateObjects(_ block: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        _orderedStorage.enumerateObjects(options: [], using: block)
    }
    
    open func enumerateObjects(options opts: NSEnumerationOptions = [], using block: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        _orderedStorage.enumerateObjects(options: opts, using: block)
    }
    
    open func enumerateObjects(at s: IndexSet, options opts: NSEnumerationOptions = [], using block: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        _orderedStorage.enumerateObjects(at: s, options: opts, using: block)
    }
    
    open func index(ofObjectPassingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return _orderedStorage.indexOfObject([], passingTest: predicate)
    }
    
    open func index(_ opts: NSEnumerationOptions = [], ofObjectPassingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return _orderedStorage.indexOfObject(opts, passingTest: predicate)
    }
    
    open func index(ofObjectAt s: IndexSet, options opts: NSEnumerationOptions = [], passingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int {
        return _orderedStorage.indexOfObject(at: s, options: opts, passingTest: predicate)
    }
    
    open func indexes(ofObjectsPassingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        return _orderedStorage.indexesOfObjects(options: [], passingTest: predicate)
    }
    
    open func indexes(options opts: NSEnumerationOptions = [], ofObjectsPassingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        return _orderedStorage.indexesOfObjects(options: opts, passingTest: predicate)
    }
    
    open func indexes(ofObjectsAt s: IndexSet, options opts: NSEnumerationOptions = [], passingTest predicate: (Any, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> IndexSet {
        return _orderedStorage.indexesOfObjects(at: s, options: opts, passingTest: predicate)
    }
    
    open func index(of object: Any, inSortedRange range: NSRange, options opts: NSBinarySearchingOptions = [], usingComparator cmp: (Any, Any) -> ComparisonResult) -> Int {
        return _orderedStorage.index(of: object, inSortedRange: range, options: opts, usingComparator: cmp)
    }
    
    open func sortedArray(comparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] {
        return _orderedStorage.sortedArray(comparator: cmptr)
    }
    
    open func sortedArray(options opts: NSSortOptions = [], usingComparator cmptr: (Any, Any) -> ComparisonResult) -> [Any] {
        return _orderedStorage.sortedArray(options: opts, usingComparator: cmptr)
    }
    
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
        self.init(orderedSet: set, range: NSMakeRange(0, set.count), copyItems: flag)
    }

    public convenience init(orderedSet set: NSOrderedSet, range: NSRange, copyItems flag: Bool) {
        self.init(array: set.array, range: range, copyItems: flag)
    }

    public convenience init(array: [Any]) {
        let buffer = UnsafeMutablePointer<AnyObject>.allocate(capacity: array.count)
        for (idx, element) in array.enumerated() {
            buffer.advanced(by: idx).initialize(to: _SwiftValue.store(element))
        }
        self.init(objects: buffer, count: array.count)
        buffer.deinitialize(count: array.count)
        buffer.deallocate(capacity: array.count)
    }

    public convenience init(array set: [Any], copyItems flag: Bool) {
        self.init(array: set, range: NSMakeRange(0, set.count), copyItems: flag)
    }

    public convenience init(array set: [Any], range: NSRange, copyItems flag: Bool) {
        var objects = set

        if let range = range.toCountableRange(), range.count != set.count || flag {
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
        self.init(array: set.map { $0 }, copyItems: flag)
    }
}


/****************       Mutable Ordered Set     ****************/

open class NSMutableOrderedSet : NSOrderedSet {
    
    open func insert(_ object: Any, at idx: Int) {
        guard idx < count && idx >= 0 else {
            fatalError("\(self): Index out of bounds")
        }

        let value = _SwiftValue.store(object)
        
        if contains(value) {
            return
        }
        
        if contains(object) {
            return
        }
        
        _storage.add(object)
        _orderedStorage.insert(object, at: idx)
    }

    open func removeObject(at idx: Int) {
        _storage.remove(_orderedStorage[idx])
        _orderedStorage.removeObject(at: idx)
    }

    open func replaceObject(at idx: Int, with obj: Any) {
        guard idx < count && idx >= 0 else {
            fatalError("\(self): Index out of bounds")
        }
        
        let objectToReplace = _orderedStorage.object(at: idx)
        _orderedStorage.replaceObject(at: idx, with: obj)
        _storage.remove(objectToReplace)
        _storage.add(obj)
    }

    public init(capacity numItems: Int) {
        super.init(objects: [], count: 0)
    }

    required public convenience init(arrayLiteral elements: Any...) {
        self.init(capacity: 0)

        addObjects(from: elements)
    }

    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }

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
        _orderedStorage.exchangeObject(at: idx1, withObjectAt: idx2)
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
        _storage.add(obj)
        if idx == _orderedStorage.count {
            _orderedStorage.add(obj)
        } else {
            _orderedStorage[idx] = obj
        }
    }
    
    open func replaceObjects(in range: NSRange, with objects: UnsafePointer<AnyObject>!, count: Int) {
        if let range = range.toCountableRange() {
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
        let objectsToRemove = _orderedStorage.subarray(with: range)
        removeObjects(in: objectsToRemove)
    }

    open func removeObjects(at indexes: IndexSet) {
        for index in indexes.lazy.reversed() {
            removeObject(at: index)
        }
    }

    public func removeAllObjects() {
        _storage.removeAllObjects()
        _orderedStorage.removeAllObjects()
    }
    
    open func remove(_ val: Any) {
        _storage.remove(val)
        _orderedStorage.remove(val)
    }

    open func removeObjects(in array: [Any]) {
        array.forEach(remove)
    }
    
    open func intersect(_ other: NSOrderedSet) {
        intersectSet(other.set)
    }

    open func minus(_ other: NSOrderedSet) {
        minusSet(other.set)
    }

    open func union(_ other: NSOrderedSet) {
        other.forEach(add)
    }
    
    open func intersectSet(_ other: Set<AnyHashable>) {
        let objectsToRemove = self.array.filter({ return !other.contains($0 as! AnyHashable)})
        _storage.intersect(other)
        _orderedStorage.removeObjects(in: objectsToRemove)
    }

    open func minusSet(_ other: Set<AnyHashable>) {
        _storage.minus(other)
        _orderedStorage.removeObjects(in: Array(other))
    }

    open func unionSet(_ other: Set<AnyHashable>) {
        other.forEach(add)
    }
    
    open func sort(comparator cmptr: (Any, Any) -> ComparisonResult) {
        sortRange(NSMakeRange(0, count), options: [], usingComparator: cmptr)
    }

    open func sort(options opts: NSSortOptions = [], usingComparator cmptr: (Any, Any) -> ComparisonResult) {
        sortRange(NSMakeRange(0, count), options: opts, usingComparator: cmptr)
    }

    open func sortRange(_ range: NSRange, options opts: NSSortOptions = [], usingComparator cmptr: (Any, Any) -> ComparisonResult) {
        // The sort options are not available. We use the Array's sorting algorithm. It is not stable neither concurrent.
        guard opts.isEmpty else {
            NSUnimplemented()
        }

        let sortedObjects = _orderedStorage.sortedArray(from: range, options: opts, usingComparator: cmptr)
        _orderedStorage.replaceObjects(in: range, withObjectsFromArray: sortedObjects)
    }
}
