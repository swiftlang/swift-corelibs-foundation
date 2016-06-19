// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

extension Set : _ObjectTypeBridgeable {
    public func _bridgeToObject() -> NSSet {
        let buffer = UnsafeMutablePointer<AnyObject?>(allocatingCapacity: count)
        
        for (idx, obj) in enumerated() {
            buffer.advanced(by: idx).initialize(with: _NSObjectRepresentableBridge(obj))
        }
        
        let set = NSSet(objects: buffer, count: count)
        
        buffer.deinitialize(count: count)
        buffer.deallocateCapacity(count)
        
        return set
    }
    
    public static func _forceBridgeFromObject(_ x: NSSet, result: inout Set?) {
        var set = Set<Element>()
        var failedConversion = false
        
        if x.dynamicType == NSSet.self || x.dynamicType == NSMutableSet.self {
            x.enumerateObjectsUsingBlock() { obj, stop in
                if let o = obj as? Element {
                    set.insert(o)
                } else {
                    failedConversion = true
                    stop.pointee = true
                }
            }
        } else if x.dynamicType == _NSCFSet.self {
            let cf = x._cfObject
            let cnt = CFSetGetCount(cf)
            
            let objs = UnsafeMutablePointer<UnsafePointer<Void>?>(allocatingCapacity: cnt)
            
            CFSetGetValues(cf, objs)
            
            for idx in 0..<cnt {
                let obj = unsafeBitCast(objs.advanced(by: idx), to: AnyObject.self)
                if let o = obj as? Element {
                    set.insert(o)
                } else {
                    failedConversion = true
                    break
                }
            }
            objs.deinitialize(count: cnt)
            objs.deallocateCapacity(cnt)
        }
        if !failedConversion {
            result = set
        }
    }
    
    public static func _conditionallyBridgeFromObject(_ x: NSSet, result: inout Set?) -> Bool {
        self._forceBridgeFromObject(x, result: &result)
        return true
    }
}

public class NSSet : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFSetGetTypeID())
    internal var _storage: Set<NSObject>
    
    public var count: Int {
        guard self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self || self.dynamicType === NSCountedSet.self else {
                NSRequiresConcreteImplementation()
        }
        return _storage.count
    }
    
    public func member(_ object: AnyObject) -> AnyObject? {
        guard self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self || self.dynamicType === NSCountedSet.self else {
            NSRequiresConcreteImplementation()
        }
        
        guard let obj = object as? NSObject where _storage.contains(obj) else {
            return nil
        }
        
        return obj // this is not exactly the same behavior, but it is reasonably close
    }
    
    public func objectEnumerator() -> NSEnumerator {
        guard self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self || self.dynamicType === NSCountedSet.self else {
            NSRequiresConcreteImplementation()
        }
        return NSGeneratorEnumerator(_storage.makeIterator())
    }

    public convenience override init() {
        self.init(objects: [], count: 0)
    }
    
    public init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        _storage = Set(minimumCapacity: cnt)
        super.init()
        let buffer = UnsafeBufferPointer(start: objects, count: cnt)
        for obj in buffer {
            _storage.insert(obj as! NSObject)
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
            let objects = UnsafeMutablePointer<AnyObject?>(allocatingCapacity: Int(cnt))
            for idx in 0..<cnt {
                objects.advanced(by: Int(idx)).initialize(with: aDecoder.decodeObject())
            }
            self.init(objects: UnsafePointer<AnyObject?>(objects), count: Int(cnt))
            objects.deinitialize(count: Int(cnt))
            objects.deallocateCapacity(Int(cnt))
        } else if aDecoder.dynamicType == NSKeyedUnarchiver.self || aDecoder.containsValueForKey("NS.objects") {
            let objects = aDecoder._decodeArrayOfObjectsForKey("NS.objects")
            self.init(array: objects)
        } else {
            var objects = [AnyObject]()
            var count = 0
            while let object = aDecoder.decodeObjectForKey("NS.object.\(count)") {
                objects.append(object)
                count += 1
            }
            self.init(array: objects)
        }
    }
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        // The encoding of a NSSet is identical to the encoding of an NSArray of its contents
        self.allObjects._nsObject.encodeWithCoder(aCoder)
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        if self.dynamicType === NSSet.self {
            // return self for immutable type
            return self
        } else if self.dynamicType === NSMutableSet.self {
            let set = NSSet()
            set._storage = self._storage
            return set
        }
        return NSSet(array: self.allObjects)
    }
    
    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }

    public func mutableCopyWithZone(_ zone: NSZone) -> AnyObject {
        if self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self {
            // always create and return an NSMutableSet
            let mutableSet = NSMutableSet()
            mutableSet._storage = self._storage
            return mutableSet
        }
        return NSMutableSet(array: self.allObjects)
    }

    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func descriptionWithLocale(_ locale: AnyObject?) -> String { NSUnimplemented() }
    
    override public var _cfTypeID: CFTypeID {
        return CFSetGetTypeID()
    }

    public override func isEqual(_ object: AnyObject?) -> Bool {
        guard let otherObject = object where otherObject is NSSet else {
            return false
        }
        let otherSet = otherObject as! NSSet
        return self.isEqualToSet(otherSet.bridge())
    }

    public override var hash: Int {
        return self.count
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

    public convenience init(set: Set<NSObject>) {
        self.init(set: set, copyItems: false)
    }

    public convenience init(set: Set<NSObject>, copyItems flag: Bool) {
        var array = set.bridge().allObjects
        if (flag) {
            array = array.map() { ($0 as! NSObject).copy() }
        }
        self.init(array: array)
    }
}

extension NSSet {
    
    public convenience init(object: AnyObject) {
        self.init(array: [object])
    }
}

extension NSSet {
    
    public var allObjects: [AnyObject] {
        // Would be nice to use `Array(self)` here but compiler
        // crashes on Linux @ swift 6e3e83c
        return map { $0 }
    }
    
    public func anyObject() -> AnyObject? {
        return objectEnumerator().nextObject()
    }
    
    public func containsObject(_ anObject: AnyObject) -> Bool {
        return member(anObject) != nil
    }
    
    public func intersectsSet(_ otherSet: Set<NSObject>) -> Bool {
        if count < otherSet.count {
            return contains { obj in otherSet.contains(obj as! NSObject) }
        } else {
            return otherSet.contains { obj in containsObject(obj) }
        }
    }
    
    public func isEqualToSet(_ otherSet: Set<NSObject>) -> Bool {
        return count == otherSet.count && isSubsetOfSet(otherSet)
    }
    
    public func isSubsetOfSet(_ otherSet: Set<NSObject>) -> Bool {
        // `true` if we don't contain any object that `otherSet` doesn't contain.
        return !self.contains { obj in !otherSet.contains(obj as! NSObject) }
    }

    public func setByAddingObject(_ anObject: AnyObject) -> Set<NSObject> {
        return self.setByAddingObjectsFromArray([anObject])
    }
    
    public func setByAddingObjectsFromSet(_ other: Set<NSObject>) -> Set<NSObject> {
        var result = Set<NSObject>(minimumCapacity: Swift.max(count, other.count))
        if self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self {
            result.formUnion(_storage)
        } else {
            for case let obj as NSObject in self {
                result.insert(obj)
            }
        }
        return result.union(other)
    }
    
    public func setByAddingObjectsFromArray(_ other: [AnyObject]) -> Set<NSObject> {
        var result = Set<NSObject>(minimumCapacity: count)
        if self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self {
            result.formUnion(_storage)
        } else {
            for case let obj as NSObject in self {
                result.insert(obj)
            }
        }
        for case let obj as NSObject in other {
            result.insert(obj)
        }
        return result
    }

    public func enumerateObjectsUsingBlock(_ block: (AnyObject, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateObjectsWithOptions([], usingBlock: block)
    }
    
    public func enumerateObjectsWithOptions(_ opts: NSEnumerationOptions, usingBlock block: (AnyObject, UnsafeMutablePointer<ObjCBool>) -> Void) {
        var stop : ObjCBool = false
        for obj in self {
            withUnsafeMutablePointer(&stop) { stop in
                block(obj, stop)
            }
            if stop {
                break
            }
        }
    }

    public func objectsPassingTest(_ predicate: (AnyObject, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Set<NSObject> {
        return objectsWithOptions([], passingTest: predicate)
    }
    
    public func objectsWithOptions(_ opts: NSEnumerationOptions, passingTest predicate: (AnyObject, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Set<NSObject> {
        var result = Set<NSObject>()
        enumerateObjectsWithOptions(opts) { obj, stopp in
            if predicate(obj, stopp) {
                result.insert(obj as! NSObject)
            }
        }
        return result
    }
}

extension NSSet : _CFBridgable, _SwiftBridgable {
    internal var _cfObject: CFSet { return unsafeBitCast(self, to: CFSet.self) }
    internal var _swiftObject: Set<NSObject> {
        var set: Set<NSObject>?
        Set._forceBridgeFromObject(self, result: &set)
        return set!
    }
}

extension CFSet : _NSBridgable, _SwiftBridgable {
    internal var _nsObject: NSSet { return unsafeBitCast(self, to: NSSet.self) }
    internal var _swiftObject: Set<NSObject> { return _nsObject._swiftObject }
}

extension Set : _NSBridgable, _CFBridgable {
    internal var _nsObject: NSSet { return _bridgeToObject() }
    internal var _cfObject: CFSet { return _nsObject._cfObject }
}

extension NSSet : Sequence {
    public typealias Iterator = NSEnumerator.Iterator
    public func makeIterator() -> Iterator {
        return self.objectEnumerator().makeIterator()
    }
}

public class NSMutableSet : NSSet {
    
    public func addObject(_ object: AnyObject) {
        guard self.dynamicType === NSMutableSet.self else {
            NSRequiresConcreteImplementation()
        }
        _storage.insert(object as! NSObject)
    }
    
    public func removeObject(_ object: AnyObject) {
        guard self.dynamicType === NSMutableSet.self else {
            NSRequiresConcreteImplementation()
        }

        if let obj = object as? NSObject {
            _storage.remove(obj)
        }
    }
    
    override public init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        super.init(objects: objects, count: cnt)
    }

    public convenience init() {
        self.init(capacity: 0)
    }
    
    public required init(capacity numItems: Int) {
        super.init(objects: [], count: 0)
    }
    
    public required convenience init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    public func addObjectsFromArray(_ array: [AnyObject]) {
        if self.dynamicType === NSMutableSet.self {
            for case let obj as NSObject in array {
                _storage.insert(obj)
            }
        } else {
            array.forEach(addObject)
        }
    }
    
    public func intersectSet(_ otherSet: Set<NSObject>) {
        if self.dynamicType === NSMutableSet.self {
            _storage.formIntersection(otherSet)
        } else {
            for case let obj as NSObject in self where !otherSet.contains(obj) {
                removeObject(obj)
            }
        }
    }
    
    public func minusSet(_ otherSet: Set<NSObject>) {
        if self.dynamicType === NSMutableSet.self {
            _storage.subtract(otherSet)
        } else {
            otherSet.forEach(removeObject)
        }
    }
    
    public func removeAllObjects() {
        if self.dynamicType === NSMutableSet.self {
            _storage.removeAll()
        } else {
            forEach(removeObject)
        }
    }
    
    public func unionSet(_ otherSet: Set<NSObject>) {
        if self.dynamicType === NSMutableSet.self {
            _storage.formUnion(otherSet)
        } else {
            otherSet.forEach(addObject)
        }
    }
    
    public func setSet(_ otherSet: Set<NSObject>) {
        if self.dynamicType === NSMutableSet.self {
            _storage = otherSet
        } else {
            removeAllObjects()
            unionSet(otherSet)
        }
    }

}

/****************	Counted Set	****************/
public class NSCountedSet : NSMutableSet {
    internal var _table: Dictionary<NSObject, Int>

    public required init(capacity numItems: Int) {
        _table = Dictionary<NSObject, Int>()
        super.init(capacity: numItems)
    }

    public  convenience init() {
        self.init(capacity: 0)
    }

    public convenience init(array: [AnyObject]) {
        self.init(capacity: array.count)
        for object in array {
            if let object = object as? NSObject {
                if let count = _table[object] {
                    _table[object] = count + 1
                } else {
                    _table[object] = 1
                    _storage.insert(object)
                }
            }
        }
    }

    public convenience init(set: Set<NSObject>) {
        self.init(array: set.map { $0 })
    }

    public required convenience init?(coder: NSCoder) { NSUnimplemented() }

    public override func copyWithZone(_ zone: NSZone) -> AnyObject {
        if self.dynamicType === NSCountedSet.self {
            let countedSet = NSCountedSet()
            countedSet._storage = self._storage
            countedSet._table = self._table
            return countedSet
        }
        return NSCountedSet(array: self.allObjects)
    }

    public override func mutableCopyWithZone(_ zone: NSZone) -> AnyObject {
        if self.dynamicType === NSCountedSet.self {
            let countedSet = NSCountedSet()
            countedSet._storage = self._storage
            countedSet._table = self._table
            return countedSet
        }
        return NSCountedSet(array: self.allObjects)
    }

    public func countForObject(_ object: AnyObject) -> Int {
        guard self.dynamicType === NSCountedSet.self else {
            NSRequiresConcreteImplementation()
        }
        guard let count = _table[object as! NSObject] else {
            return 0
        }
        return count
    }

    public override func addObject(_ object: AnyObject) {
        guard self.dynamicType === NSCountedSet.self else {
            NSRequiresConcreteImplementation()
        }

        if let count = _table[object as! NSObject] {
            _table[object as! NSObject] = count + 1
        } else {
            _table[object as! NSObject] = 1
            _storage.insert(object as! NSObject)
        }
    }

    public override func removeObject(_ object: AnyObject) {
        guard self.dynamicType === NSCountedSet.self else {
            NSRequiresConcreteImplementation()
        }
        guard let count = _table[object as! NSObject] else {
            return
        }

        if count > 1 {
            _table[object as! NSObject] = count - 1
        } else {
            _table[object as! NSObject] = nil
            _storage.remove(object as! NSObject)
        }
    }

    public override func removeAllObjects() {
        if self.dynamicType === NSCountedSet.self {
            _storage.removeAll()
            _table.removeAll()
        } else {
            forEach(removeObject)
        }
    }
}

extension Set : Bridgeable {
    public func bridge() -> NSSet { return _nsObject }
}

extension NSSet : Bridgeable {
    public func bridge() -> Set<NSObject> { return _swiftObject }
}
