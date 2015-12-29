// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal class _NSOrderedSetEntry {
    let object: NSObject
    var previousEntry: _NSOrderedSetEntry?
    var nextEntry: _NSOrderedSetEntry?

    init(object: NSObject) {
        self.object = object
    }
}

/****************       Immutable Ordered Set   ****************/
public class NSOrderedSet : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, ArrayLiteralConvertible {
    internal var _entries: [NSObject: _NSOrderedSetEntry]
    internal var _headEntry: _NSOrderedSetEntry?
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }

    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }

    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    
    public var count: Int {
        return _entries.count
    }

    public func objectAtIndex(idx: Int) -> AnyObject {
        var nextEntry = _headEntry
        for _ in 0..<idx {
            nextEntry = nextEntry?.nextEntry
        }
        return nextEntry!.object
    }

    public func indexOfObject(object: AnyObject) -> Int {
        var nextEntry = _headEntry
        for idx in 0...count {
            if nextEntry!.object == object as! NSObject {
                return idx
            }
            nextEntry = nextEntry?.nextEntry
        }
        return NSNotFound
    }

    public convenience override init() {
        self.init(objects: nil, count: 0)
    }

    public init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        _entries = [NSObject: _NSOrderedSetEntry]()
        super.init()
        let buffer = UnsafeBufferPointer(start: objects, count: cnt)
        for obj in buffer {
            _insertEntry(obj as! NSObject)
        }
    }
    
    required public convenience init(arrayLiteral elements: AnyObject...) { NSUnimplemented() }
    public convenience init(objects elements: AnyObject...) { NSUnimplemented() }
    
    public subscript (idx: Int) -> AnyObject { NSUnimplemented() }

    private func _insertEntry(object: NSObject) {
        if _entries[object] != nil {
            return;
        }

        let entry = _entryWithObject(object)

        let previousEntry = _headEntry?.previousEntry ?? _headEntry
        entry.previousEntry = previousEntry
        previousEntry?.nextEntry = entry

        _headEntry?.previousEntry = entry
        if _headEntry == nil {
            _headEntry = entry
        }

        _entries[object] = entry
    }

    private func _entryWithObject(object: NSObject) -> _NSOrderedSetEntry {
        return _NSOrderedSetEntry(object: object)
    }
}


extension NSOrderedSet : SequenceType {
    /// Return a *generator* over the elements of this *sequence*.
    ///
    /// - Complexity: O(1).
    public func generate() -> AnyGenerator<AnyObject> {
        var current = _headEntry

        return AnyGenerator() {
            let returnValue = current
            current = current?.nextEntry

            if let returnValue = returnValue {
                return returnValue.object
            }
            return nil
        }
    }
}

extension NSOrderedSet {

    public func getObjects(inout objects: [AnyObject], range: NSRange) {
        var nextEntry = _headEntry
        for idx in 0..<(range.location + range.length) {
            if idx >= range.location {
                objects.append(nextEntry!.object)
            }
            nextEntry = nextEntry?.nextEntry
        }
    }

    public func objectsAtIndexes(indexes: NSIndexSet) -> [AnyObject]{
        var entries = [AnyObject]()
        for index in indexes {
            entries.append(objectAtIndex(index))
        }
        return entries
    }

    public var firstObject: AnyObject? {
        return _headEntry?.object
    }

    public var lastObject: AnyObject? {
        return _headEntry?.previousEntry?.object
    }
    
    public func isEqualToOrderedSet(other: NSOrderedSet) -> Bool { NSUnimplemented() }
    
    public func containsObject(object: AnyObject) -> Bool { NSUnimplemented() }
    public func intersectsOrderedSet(other: NSOrderedSet) -> Bool { NSUnimplemented() }
    public func intersectsSet(set: Set<NSObject>) -> Bool { NSUnimplemented() }
    
    public func isSubsetOfOrderedSet(other: NSOrderedSet) -> Bool { NSUnimplemented() }
    public func isSubsetOfSet(set: Set<NSObject>) -> Bool { NSUnimplemented() }
    
    public func objectEnumerator() -> NSEnumerator { NSUnimplemented() }
    public func reverseObjectEnumerator() -> NSEnumerator { NSUnimplemented() }
    
    /*@NSCopying*/ public var reversedOrderedSet: NSOrderedSet { NSUnimplemented() }
    
    // These two methods return a facade object for the receiving ordered set,
    // which acts like an immutable array or set (respectively).  Note that
    // while you cannot mutate the ordered set through these facades, mutations
    // to the original ordered set will "show through" the facade and it will
    // appear to change spontaneously, since a copy of the ordered set is not
    // being made.
    public var array: [AnyObject] { NSUnimplemented() }
    public var set: Set<NSObject> { NSUnimplemented() }
    
    public func enumerateObjectsUsingBlock(block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    public func enumerateObjectsWithOptions(opts: NSEnumerationOptions, usingBlock block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    public func enumerateObjectsAtIndexes(s: NSIndexSet, options opts: NSEnumerationOptions, usingBlock block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void) { NSUnimplemented() }
    
    public func indexOfObjectPassingTest(predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int { NSUnimplemented() }
    public func indexOfObjectWithOptions(opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int { NSUnimplemented() }
    public func indexOfObjectAtIndexes(s: NSIndexSet, options opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int { NSUnimplemented() }
    
    public func indexesOfObjectsPassingTest(predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet { NSUnimplemented() }
    public func indexesOfObjectsWithOptions(opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet { NSUnimplemented() }
    public func indexesOfObjectsAtIndexes(s: NSIndexSet, options opts: NSEnumerationOptions, passingTest predicate: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexSet { NSUnimplemented() }
    
    public func indexOfObject(object: AnyObject, inSortedRange range: NSRange, options opts: NSBinarySearchingOptions, usingComparator cmp: NSComparator) -> Int { NSUnimplemented() } // binary search
    
    public func sortedArrayUsingComparator(cmptr: NSComparator) -> [AnyObject] { NSUnimplemented() }
    public func sortedArrayWithOptions(opts: NSSortOptions, usingComparator cmptr: NSComparator) -> [AnyObject] { NSUnimplemented() }
    
    public func descriptionWithLocale(locale: AnyObject?) -> String { NSUnimplemented() }
    public func descriptionWithLocale(locale: AnyObject?, indent level: Int) -> String { NSUnimplemented() }
}

extension NSOrderedSet {
    
    public convenience init(object: AnyObject) {
        self.init(array: [object])
    }
    
    public convenience init(orderedSet set: NSOrderedSet) { NSUnimplemented() }
    public convenience init(orderedSet set: NSOrderedSet, copyItems flag: Bool) { NSUnimplemented() }
    public convenience init(orderedSet set: NSOrderedSet, range: NSRange, copyItems flag: Bool) { NSUnimplemented() }

    public convenience init(array: [AnyObject]) {
        let buffer = UnsafeMutablePointer<AnyObject?>.alloc(array.count)
        for (idx, element) in array.enumerate() {
            buffer.advancedBy(idx).initialize(element)
        }
        self.init(objects: buffer, count: array.count)
        buffer.destroy(array.count)
        buffer.dealloc(array.count)
    }

    public convenience init(array set: [AnyObject], copyItems flag: Bool) { NSUnimplemented() }
    public convenience init(array set: [AnyObject], range: NSRange, copyItems flag: Bool) { NSUnimplemented() }
    public convenience init(set: Set<NSObject>) { NSUnimplemented() }
    public convenience init(set: Set<NSObject>, copyItems flag: Bool) { NSUnimplemented() }
}


/****************       Mutable Ordered Set     ****************/

public class NSMutableOrderedSet : NSOrderedSet {
    
    public func insertObject(object: AnyObject, atIndex idx: Int) { NSUnimplemented() }
    public func removeObjectAtIndex(idx: Int) { NSUnimplemented() }
    public func replaceObjectAtIndex(idx: Int, withObject object: AnyObject) { NSUnimplemented() }
    public init(capacity numItems: Int) { NSUnimplemented() }
    
    required public convenience init(arrayLiteral elements: AnyObject...) { NSUnimplemented() }
    public required init?(coder aDecoder: NSCoder) { NSUnimplemented() }
    
    public override subscript (idx: Int) -> AnyObject { NSUnimplemented() }
}

extension NSMutableOrderedSet {
    
    public func addObject(object: AnyObject) { NSUnimplemented() }
    public func addObjects(objects: UnsafePointer<AnyObject?>, count: Int) { NSUnimplemented() }
    public func addObjectsFromArray(array: [AnyObject]) { NSUnimplemented() }
    
    public func exchangeObjectAtIndex(idx1: Int, withObjectAtIndex idx2: Int) { NSUnimplemented() }
    public func moveObjectsAtIndexes(indexes: NSIndexSet, toIndex idx: Int) { NSUnimplemented() }
    
    public func insertObjects(objects: [AnyObject], atIndexes indexes: NSIndexSet) { NSUnimplemented() }
    
    public func setObject(obj: AnyObject, atIndex idx: Int) { NSUnimplemented() }
    
    public func replaceObjectsInRange(range: NSRange, withObjects objects: UnsafePointer<AnyObject?>, count: Int) { NSUnimplemented() }
    public func replaceObjectsAtIndexes(indexes: NSIndexSet, withObjects objects: [AnyObject]) { NSUnimplemented() }
    
    public func removeObjectsInRange(range: NSRange) { NSUnimplemented() }
    public func removeObjectsAtIndexes(indexes: NSIndexSet) { NSUnimplemented() }
    public func removeAllObjects() { NSUnimplemented() }
    
    public func removeObject(object: AnyObject) { NSUnimplemented() }
    public func removeObjectsInArray(array: [AnyObject]) { NSUnimplemented() }
    
    public func intersectOrderedSet(other: NSOrderedSet) { NSUnimplemented() }
    public func minusOrderedSet(other: NSOrderedSet) { NSUnimplemented() }
    public func unionOrderedSet(other: NSOrderedSet) { NSUnimplemented() }
    
    public func intersectSet(other: Set<NSObject>) { NSUnimplemented() }
    public func minusSet(other: Set<NSObject>) { NSUnimplemented() }
    public func unionSet(other: Set<NSObject>) { NSUnimplemented() }
    
    public func sortUsingComparator(cmptr: NSComparator) { NSUnimplemented() }
    public func sortWithOptions(opts: NSSortOptions, usingComparator cmptr: NSComparator) { NSUnimplemented() }
    public func sortRange(range: NSRange, options opts: NSSortOptions, usingComparator cmptr: NSComparator) { NSUnimplemented() }
}

