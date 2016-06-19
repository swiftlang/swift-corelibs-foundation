// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/****************       Immutable Ordered Set   ****************/
public class NSOrderedSet : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, ArrayLiteralConvertible {
    internal var _storage: Set<NSObject>
    internal var _orderedStorage: [NSObject]
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }

    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }

    public func mutableCopyWithZone(_ zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public override func isEqual(_ object: AnyObject?) -> Bool {
        if let orderedSet = object as? NSOrderedSet {
            return isEqualToOrderedSet(orderedSet)
        } else {
            return false
        }
    }
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            for idx in 0..<self.count {
                aCoder.encodeObject(self.objectAtIndex(idx), forKey:"NS.object.\(idx)")
            }
        } else {
            NSUnimplemented()
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            var idx = 0
            var objects : [AnyObject] = []
            while aDecoder.containsValueForKey(("NS.object.\(idx)")) {
                guard let object = aDecoder.decodeObjectForKey("NS.object.\(idx)") else {
                    return nil
                }
                objects.append(object)
                idx += 1
            }
            self.init(array: objects)
        } else {
            NSUnimplemented()
        }
    }
    
    public var count: Int {
        return _storage.count
    }

    public func objectAtIndex(_ idx: Int) -> AnyObject {
        return _orderedStorage[idx]
    }

    public func indexOfObject(_ object: AnyObject) -> Int {
        guard let object = object as? NSObject else {
            return NSNotFound
        }

        return _orderedStorage.index(of: object) ?? NSNotFound
    }

    public convenience override init() {
        self.init(objects: [], count: 0)
    }

    public init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        _storage = Set<NSObject>()
        _orderedStorage = [NSObject]()

        super.init()

        _insertObjects(objects, count: cnt)
    }
    
    required public convenience init(arrayLiteral elements: AnyObject...) {
      self.init(array: elements)
    }

    public convenience init(objects elements: AnyObject...) {
      self.init(array: elements)
    }
    
    public subscript (idx: Int) -> AnyObject {
        return objectAtIndex(idx)
    }

    private func _insertObject(_ object: AnyObject) {
        guard !containsObject(object), let object = object as? NSObject else {
            return
        }

        _storage.insert(object)
        _orderedStorage.append(object)
    }

    private func _insertObjects(_ objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        let buffer = UnsafeBufferPointer(start: objects, count: cnt)
        for obj in buffer {
            _insertObject(obj!)
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

    public func objectsAtIndexes(_ indexes: NSIndexSet) -> [AnyObject] {
        var entries = [AnyObject]()
        for idx in indexes {
            if idx >= count && idx < 0 {
                fatalError("\(self): Index out of bounds")
            }
            entries.append(objectAtIndex(idx))
        }
        return entries
    }

    public var firstObject: AnyObject? {
        return _orderedStorage.first
    }

    public var lastObject: AnyObject? {
        return _orderedStorage.last
    }

    public func isEqualToOrderedSet(_ otherOrderedSet: NSOrderedSet) -> Bool {
        if count != otherOrderedSet.count {
            return false
        }
        
        for idx in 0..<count {
            let obj1 = objectAtIndex(idx) as! NSObject
            let obj2 = otherOrderedSet.objectAtIndex(idx) as! NSObject
            if obj1 === obj2 {
                continue
            }
            if !obj1.isEqual(obj2) {
                return false
            }
        }
        
        return true
    }
    
    public func containsObject(_ object: AnyObject) -> Bool {
        if let object = object as? NSObject {
            return _storage.contains(object)
        }
        return false
    }

    public func intersectsOrderedSet(_ other: NSOrderedSet) -> Bool {
        if count < other.count {
            return contains { obj in other.containsObject(obj as! NSObject) }
        } else {
            return other.contains { obj in containsObject(obj) }
        }
    }

    public func intersectsSet(_ set: Set<NSObject>) -> Bool {
        if count < set.count {
            return contains { obj in set.contains(obj as! NSObject) }
        } else {
            return set.contains { obj in containsObject(obj) }
        }
    }
    
    public func isSubsetOfOrderedSet(_ other: NSOrderedSet) -> Bool {
        return !self.contains { obj in
            !other.containsObject(obj as! NSObject)
        }
    }

    public func isSubsetOfSet(_ set: Set<NSObject>) -> Bool {
        return !self.contains { obj in
            !set.contains(obj as! NSObject)
        }
    }
    
    public func objectEnumerator() -> NSEnumerator {
        guard self.dynamicType === NSOrderedSet.self || self.dynamicType === NSMutableOrderedSet.self else {
            NSRequiresConcreteImplementation()
        }
        return NSGeneratorEnumerator(_orderedStorage.makeIterator())
    }

    public func reverseObjectEnumerator() -> NSEnumerator { 
        guard self.dynamicType === NSOrderedSet.self || self.dynamicType === NSMutableOrderedSet.self else {
            NSRequiresConcreteImplementation()
        }
        return NSGeneratorEnumerator(_orderedStorage.reversed().makeIterator())
    }
    
    /*@NSCopying*/ 
    public var reversedOrderedSet: NSOrderedSet { 
        return NSOrderedSet(array: _orderedStorage.reversed().bridge().bridge())     
    }
    
    // These two methods return a facade object for the receiving ordered set,
    // which acts like an immutable array or set (respectively).  Note that
    // while you cannot mutate the ordered set through these facades, mutations
    // to the original ordered set will "show through" the facade and it will
    // appear to change spontaneously, since a copy of the ordered set is not
    // being made.
    public var array: [AnyObject] { NSUnimplemented() }
    public var set: Set<NSObject> { NSUnimplemented() }
    
    public func enumerateObjectsUsingBlock(_ block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    public func enumerateObjectsWithOptions(_ opts: NSEnumerationOptions, usingBlock block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    public func enumerateObjectsAtIndexes(_ s: NSIndexSet, options opts: NSEnumerationOptions, usingBlock block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    
    public func indexOfObjectPassingTest(_ predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int { NSUnimplemented() }
    public func indexOfObjectWithOptions(_ opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int { NSUnimplemented() }
    public func indexOfObjectAtIndexes(_ s: NSIndexSet, options opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int { NSUnimplemented() }
    
    public func indexesOfObjectsPassingTest(_ predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet { NSUnimplemented() }
    public func indexesOfObjectsWithOptions(_ opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet { NSUnimplemented() }
    public func indexesOfObjectsAtIndexes(_ s: NSIndexSet, options opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet { NSUnimplemented() }
    
    public func indexOfObject(_ object: AnyObject, inSortedRange range: NSRange, options opts: NSBinarySearchingOptions, usingComparator cmp: NSComparator) -> Int { NSUnimplemented() } // binary search
    
    public func sortedArrayUsingComparator(_ cmptr: NSComparator) -> [AnyObject] { NSUnimplemented() }
    public func sortedArrayWithOptions(_ opts: NSSortOptions, usingComparator cmptr: NSComparator) -> [AnyObject] { NSUnimplemented() }
    
    public func descriptionWithLocale(_ locale: AnyObject?) -> String { NSUnimplemented() }
    public func descriptionWithLocale(_ locale: AnyObject?, indent level: Int) -> String { NSUnimplemented() }
}

extension NSOrderedSet {
    
    public convenience init(object: AnyObject) {
        self.init(array: [object])
    }
    
    public convenience init(orderedSet set: NSOrderedSet) {
        self.init(orderedSet: set, copyItems: false)
    }

    public convenience init(orderedSet set: NSOrderedSet, copyItems flag: Bool) {
        self.init(orderedSet: set, range: NSMakeRange(0, set.count), copyItems: flag)
    }

    public convenience init(orderedSet set: NSOrderedSet, range: NSRange, copyItems flag: Bool) {
        // TODO: Use the array method here when available.
        self.init(array: set.map { $0 }, range: range, copyItems: flag)
    }

    public convenience init(array: [AnyObject]) {
        let buffer = UnsafeMutablePointer<AnyObject?>(allocatingCapacity: array.count)
        for (idx, element) in array.enumerated() {
            buffer.advanced(by: idx).initialize(with: element)
        }
        self.init(objects: buffer, count: array.count)
        buffer.deinitialize(count: array.count)
        buffer.deallocateCapacity(array.count)
    }

    public convenience init(array set: [AnyObject], copyItems flag: Bool) {
        self.init(array: set, range: NSMakeRange(0, set.count), copyItems: flag)
    }

    public convenience init(array set: [AnyObject], range: NSRange, copyItems flag: Bool) {
        var objects = set

        if let range = range.toRange() where range.count != set.count || flag {
            objects = [AnyObject]()
            for index in range.indices {
                let object = set[index] as! NSObject
                objects.append(flag ? object.copy() : object)
            }
        }

        self.init(array: objects)
    }

    public convenience init(set: Set<NSObject>) {
        self.init(set: set, copyItems: false)
    }

    public convenience init(set: Set<NSObject>, copyItems flag: Bool) {
        self.init(array: set.map { $0 as AnyObject }, copyItems: flag)
    }
}


/****************       Mutable Ordered Set     ****************/

public class NSMutableOrderedSet : NSOrderedSet {
    
    public func insertObject(_ object: AnyObject, atIndex idx: Int) {
        guard idx < count && idx >= 0 else {
            fatalError("\(self): Index out of bounds")
        }

        if containsObject(object) {
            return
        }

        if let object = object as? NSObject {
            _storage.insert(object)
            _orderedStorage.insert(object, at: idx)
        }
    }

    public func removeObjectAtIndex(_ idx: Int) {
        _storage.remove(_orderedStorage[idx])
        _orderedStorage.remove(at: idx)
    }

    public func replaceObjectAtIndex(_ idx: Int, withObject object: AnyObject) {
        guard idx < count && idx >= 0 else {
            fatalError("\(self): Index out of bounds")
        }

        if let objectToReplace = objectAtIndex(idx) as? NSObject, object = object as? NSObject {
            _orderedStorage[idx] = object
            _storage.remove(objectToReplace)
            _storage.insert(object)
        }
    }

    public init(capacity numItems: Int) {
        super.init(objects: [], count: 0)
    }

    required public convenience init(arrayLiteral elements: AnyObject...) {
        self.init(capacity: 0)

        addObjectsFromArray(elements)
    }

    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }

    private func _removeObject(_ object: AnyObject) {
      guard containsObject(object), let object = object as? NSObject else {
        return
      }

      _storage.remove(object)
      _orderedStorage.remove(at: indexOfObject(object))
    }
}

extension NSMutableOrderedSet {
    
    public func addObject(_ object: AnyObject) {
        _insertObject(object)
    }

    public func addObjects(_ objects: UnsafePointer<AnyObject?>, count: Int) {
        _insertObjects(objects, count: count)
    }

    public func addObjectsFromArray(_ array: [AnyObject]) {
        for object in array {
            _insertObject(object)
        }
    }
    
    public func exchangeObjectAtIndex(_ idx1: Int, withObjectAtIndex idx2: Int) {
        guard idx1 < count && idx1 >= 0 && idx2 < count && idx2 >= 0 else {
            fatalError("\(self): Index out of bounds")
        }

        if let object1 = objectAtIndex(idx1) as? NSObject, object2 = objectAtIndex(idx2) as? NSObject {
            _orderedStorage[idx1] = object2
            _orderedStorage[idx2] = object1
        }
    }

    public func moveObjectsAtIndexes(_ indexes: NSIndexSet, toIndex idx: Int) {
        var removedObjects = [NSObject]()
        for index in indexes.lazy.reversed() {
            if let object = objectAtIndex(index) as? NSObject {
                removedObjects.append(object)
                removeObjectAtIndex(index)
            }
        }
        for removedObject in removedObjects {
            insertObject(removedObject, atIndex: idx)
        }
    }
    
    public func insertObjects(_ objects: [AnyObject], atIndexes indexes: NSIndexSet) {
        for (indexLocation, index) in indexes.enumerated() {
            if let object = objects[indexLocation] as? NSObject {
                insertObject(object, atIndex: index)
            }
        }
    }
    
    public func setObject(_ obj: AnyObject, atIndex idx: Int) {
        if let object = obj as? NSObject {
            _storage.insert(object)
            if idx == _orderedStorage.count {
                _orderedStorage.append(object)
            } else {
                _orderedStorage[idx] = object
            }
        }
    }
    
    public func replaceObjectsInRange(_ range: NSRange, withObjects objects: UnsafePointer<AnyObject?>, count: Int) {
        if let range = range.toRange() {
            let buffer = UnsafeBufferPointer(start: objects, count: count)
            for (indexLocation, index) in range.indices.lazy.reversed().enumerated() {
                if let object = buffer[indexLocation] as? NSObject {
                    replaceObjectAtIndex(index, withObject: object)
                }
            }
        }
    }

    public func replaceObjectsAtIndexes(_ indexes: NSIndexSet, withObjects objects: [AnyObject]) {
        for (indexLocation, index) in indexes.enumerated() {
            if let object = objects[indexLocation] as? NSObject {
                replaceObjectAtIndex(index, withObject: object)
            }
        }
    }
    
    public func removeObjectsInRange(_ range: NSRange) {
        if let range = range.toRange() {
            for index in range.indices.lazy.reversed() {
                removeObjectAtIndex(index)
            }
        }
    }

    public func removeObjectsAtIndexes(_ indexes: NSIndexSet) {
        for index in indexes.lazy.reversed() {
            removeObjectAtIndex(index)
        }
    }

    public func removeAllObjects() {
        _storage.removeAll()
        _orderedStorage.removeAll()
    }
    
    public func removeObject(_ object: AnyObject) {
        if let object = object as? NSObject {
            _storage.remove(object)
            _orderedStorage.remove(at: indexOfObject(object))
        }
    }

    public func removeObjectsInArray(_ array: [AnyObject]) {
        array.forEach(removeObject)
    }
    
    public func intersectOrderedSet(_ other: NSOrderedSet) {
        for case let item as NSObject in self where !other.containsObject(item) {
            removeObject(item)
        }
    }

    public func minusOrderedSet(_ other: NSOrderedSet) {
        for item in other where containsObject(item) {
            removeObject(item)
        }
    }

    public func unionOrderedSet(_ other: NSOrderedSet) {
        other.forEach(addObject)
    }
    
    public func intersectSet(_ other: Set<NSObject>) {
        for case let item as NSObject in self where !other.contains(item) {
            removeObject(item)
        }
    }

    public func minusSet(_ other: Set<NSObject>) {
        for item in other where containsObject(item) {
            removeObject(item)
        }
    }

    public func unionSet(_ other: Set<NSObject>) {
        other.forEach(addObject)
    }
    
    public func sortUsingComparator(_ cmptr: NSComparator) {
        sortRange(NSMakeRange(0, count), options: [], usingComparator: cmptr)
    }

    public func sortWithOptions(_ opts: NSSortOptions, usingComparator cmptr: NSComparator) {
        sortRange(NSMakeRange(0, count), options: opts, usingComparator: cmptr)
    }

    public func sortRange(_ range: NSRange, options opts: NSSortOptions, usingComparator cmptr: NSComparator) {
        // The sort options are not available. We use the Array's sorting algorithm. It is not stable neither concurrent.
        guard opts.isEmpty else {
            NSUnimplemented()
        }

        let swiftRange = range.toRange()!
        _orderedStorage[swiftRange].sort { lhs, rhs in
            return cmptr(lhs, rhs) == .orderedAscending
        }
    }
}
