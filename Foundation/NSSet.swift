// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

extension Set : _ObjectiveCBridgeable {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    public static func _getObjectiveCType() -> Any.Type {
        return NSSet.self
    }
    
    public func _bridgeToObjectiveC() -> NSSet {
        let buffer = UnsafeMutablePointer<AnyObject?>.alloc(count)
        
        for (idx, obj) in enumerate() {
            buffer.advancedBy(idx).initialize(_NSObjectRepresentableBridge(obj))
        }
        
        let set = NSSet(objects: buffer, count: count)
        
        buffer.destroy(count)
        buffer.dealloc(count)
        
        return set
    }
    
    public static func _forceBridgeFromObjectiveC(x: NSSet, inout result: Set?) {
        var set = Set<Element>()
        var failedConversion = false
        
        if x.dynamicType == NSSet.self || x.dynamicType == NSMutableSet.self {
            x.enumerateObjectsUsingBlock() { obj, stop in
                if let o = obj as? Element {
                    set.insert(o)
                } else {
                    failedConversion = true
                    stop.memory = true
                }
            }
        } else if x.dynamicType == _NSCFSet.self {
            let cf = x._cfObject
            let cnt = CFSetGetCount(cf)
            
            let objs = UnsafeMutablePointer<UnsafePointer<Void>>.alloc(cnt)
            
            CFSetGetValues(cf, objs)
            
            for var idx = 0; idx < cnt; idx++ {
                let obj = unsafeBitCast(objs.advancedBy(idx), AnyObject.self)
                if let o = obj as? Element {
                    set.insert(o)
                } else {
                    failedConversion = true
                    break
                }
            }
            objs.destroy(cnt)
            objs.dealloc(cnt)
        }
        if !failedConversion {
            result = set
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(x: NSSet, inout result: Set?) -> Bool {
        self._forceBridgeFromObjectiveC(x, result: &result)
        return true
    }
}

public class NSSet : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFSetGetTypeID())
    internal var _storage = Set<NSObject>()
    
    public var count: Int {
        get {
            if self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self {
                return _storage.count
            } else {
                NSRequiresConcreteImplementation()
            }
        }
    }
    
    public func member(object: AnyObject) -> AnyObject? {
        if self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self {
            if let obj = object as? NSObject {
                if _storage.contains(obj) {
                    return obj // this is not exactly the same behavior, but it is reasonably close
                }
            }
            return nil
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func objectEnumerator() -> NSEnumerator {
        if self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self {
            return NSGeneratorEnumerator(_storage.generate())
        } else {
            NSRequiresConcreteImplementation()
        }
    }

    public convenience override init() {
        self.init(objects: UnsafePointer<AnyObject?>(), count: 0)
    }
    
    public init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        super.init()
        for idx in 0..<cnt {
            let obj = objects[idx] as! NSObject
            _storage.insert(obj)
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func descriptionWithLocale(locale: AnyObject?) -> String { NSUnimplemented() }
    
    override internal var _cfTypeID: CFTypeID {
        return CFSetGetTypeID()
    }
}

extension NSSet {
    
    public convenience init(object: AnyObject) {
        self.init(array: [object])
    }
    
    // public convenience init(set: Set<NSObject>) {
    //     self.init(set: set, copyItems: false)
    // }

    // public convenience init(set: Set<NSObject>, copyItems flag: Bool) {
    //     var array = Array<NSObject>()
    //     for object in set {
    //         var value = object
    //         if flag {
    //             value = object.copy() as! NSObject
    //         }
    //         array.append(value)
    //     }
    //     self.init(array: array)
    // }

    public convenience init(array: [AnyObject]) {
        let buffer = UnsafeMutablePointer<AnyObject?>.alloc(array.count)
        for var idx = 0; idx < array.count; idx++ {
            buffer.advancedBy(idx).initialize(array[idx])
        }
        self.init(objects: buffer, count: array.count)
        buffer.destroy(array.count)
        buffer.dealloc(array.count)
    }
}

extension NSSet {
    
    public var allObjects: [AnyObject] {
        get {
            if self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self {
                return _storage.map { $0 }
            } else {
                var objects = [AnyObject]()
                let enumerator = objectEnumerator()
                while let obj = enumerator.nextObject() {
                    objects.append(obj)
                }
                return objects
            }
        }
    }
    
    public func anyObject() -> AnyObject? {
        return objectEnumerator().nextObject()
    }
    
    public func containsObject(anObject: AnyObject) -> Bool {
        return member(anObject) != nil
    }
    
    public func intersectsSet(otherSet: Set<NSObject>) -> Bool {
        if count < otherSet.count {
            for obj in allObjects {
                if otherSet.contains(obj as! NSObject) {
                    return true
                }
            }
        } else {
            for obj in otherSet {
                if containsObject(obj) {
                    return true
                }
            }
        }
        return false
    }
    
    public func isEqualToSet(otherSet: Set<NSObject>) -> Bool {
        if count != otherSet.count {
            return false
        }
        for obj in otherSet where !containsObject(obj) {
            return false
        }
        return true
    }
    
    public func isSubsetOfSet(otherSet: Set<NSObject>) -> Bool {
        for case let obj as NSObject in allObjects where !otherSet.contains(obj) {
            return false
        }
        return true
    }

    public func setByAddingObject(anObject: AnyObject) -> Set<NSObject> {
        return self.setByAddingObjectsFromArray([anObject])
    }
    
    public func setByAddingObjectsFromSet(other: Set<NSObject>) -> Set<NSObject> {
        var result: Set<NSObject>
        if self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self {
            result = _storage
        } else {
            result = Set<NSObject>()
            for case let obj as NSObject in self {
                result.insert(obj)
            }
        }
        return result.union(other)
    }
    
    public func setByAddingObjectsFromArray(other: [AnyObject]) -> Set<NSObject> {
        var result: Set<NSObject>
        if self.dynamicType === NSSet.self || self.dynamicType === NSMutableSet.self {
            result = _storage
        } else {
            result = Set<NSObject>()
            for case let obj as NSObject in self {
                result.insert(obj)
            }
        }
        for case let obj as NSObject in other {
            result.insert(obj)
        }
        return result
    }

    public func enumerateObjectsUsingBlock(block: (AnyObject, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateObjectsWithOptions([], usingBlock: block)
    }
    
    public func enumerateObjectsWithOptions(opts: NSEnumerationOptions, usingBlock block: (AnyObject, UnsafeMutablePointer<ObjCBool>) -> Void) {
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

    public func objectsPassingTest(predicate: (AnyObject, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Set<NSObject> {
        return objectsWithOptions([], passingTest: predicate)
    }
    
    public func objectsWithOptions(opts: NSEnumerationOptions, passingTest predicate: (AnyObject, UnsafeMutablePointer<ObjCBool>) -> Bool) -> Set<NSObject> {
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
    internal var _cfObject: CFSetRef { return unsafeBitCast(self, CFSetRef.self) }
    internal var _swiftObject: Set<NSObject> {
        var set: Set<NSObject>?
        Set._forceBridgeFromObjectiveC(self, result: &set)
        return set!
    }
}

extension CFSetRef : _NSBridgable, _SwiftBridgable {
    internal var _nsObject: NSSet { return unsafeBitCast(self, NSSet.self) }
    internal var _swiftObject: Set<NSObject> { return _nsObject._swiftObject }
}

extension Set : _NSBridgable, _CFBridgable {
    internal var _nsObject: NSSet { return _bridgeToObjectiveC() }
    internal var _cfObject: CFSetRef { return _nsObject._cfObject }
}

extension NSSet : SequenceType {
    public typealias Generator = NSEnumerator.Generator
    public func generate() -> Generator {
        return self.objectEnumerator().generate()
    }
}

public class NSMutableSet : NSSet {
    
    public func addObject(object: AnyObject) {
        if self.dynamicType === NSMutableSet.self {
            _storage.insert(object as! NSObject)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func removeObject(object: AnyObject) {
        if self.dynamicType === NSMutableSet.self {
            if let obj = object as? NSObject {
                _storage.remove(obj)
            }
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    override public init(objects: UnsafePointer<AnyObject?>, count cnt: Int) {
        super.init(objects: objects, count: cnt)
    }

    public convenience init() {
        self.init(capacity: 0)
    }
    
    public required init(capacity numItems: Int) {
        super.init(objects: nil, count: 0)
    }
    
    public required convenience init?(coder: NSCoder) {
        NSUnimplemented()
    }
    
    public func addObjectsFromArray(array: [AnyObject]) {
        if self.dynamicType === NSMutableSet.self {
            for case let obj as NSObject in array {
                _storage.insert(obj)
            }
        } else {
            array.forEach(addObject)
        }
    }
    
    public func intersectSet(otherSet: Set<NSObject>) {
        if self.dynamicType === NSMutableSet.self {
            _storage.intersectInPlace(otherSet)
        } else {
            for case let obj as NSObject in self where !otherSet.contains(obj) {
                removeObject(obj)
            }
        }
    }
    
    public func minusSet(otherSet: Set<NSObject>) {
        if self.dynamicType === NSMutableSet.self {
            _storage.subtractInPlace(otherSet)
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
    
    public func unionSet(otherSet: Set<NSObject>) {
        if self.dynamicType === NSMutableSet.self {
            _storage.unionInPlace(otherSet)
        } else {
            otherSet.forEach(addObject)
        }
    }
    
    public func setSet(otherSet: Set<NSObject>) {
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
    
    public required init(capacity numItems: Int) { NSUnimplemented() }
    
//    public convenience init(array: [AnyObject]) { NSUnimplemented() }
    public convenience init(set: Set<NSObject>) { NSUnimplemented() }
    public required convenience init?(coder: NSCoder) { NSUnimplemented() }
    
    public func countForObject(object: AnyObject) -> Int { NSUnimplemented() }
    
    public override func objectEnumerator() -> NSEnumerator { NSUnimplemented() }
    public override func addObject(object: AnyObject) { NSUnimplemented() }
    public override func removeObject(object: AnyObject) { NSUnimplemented() }
}

extension Set : Bridgeable {
    public func bridge() -> NSSet { return _nsObject }
}

extension NSSet : Bridgeable {
    public func bridge() -> Set<NSObject> { return _swiftObject }
}
