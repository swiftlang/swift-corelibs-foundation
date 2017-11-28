// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

internal final class _NSCFSet : NSMutableSet {
    deinit {
        _CFDeinit(self)
        _CFZeroUnsafeIvars(&_storage)
    }
    
    required init() {
        fatalError()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    required init(capacity numItems: Int) {
        fatalError()
    }
    
    override var classForCoder: AnyClass {
        return NSMutableSet.self
    }
    
    override var count: Int {
        return CFSetGetCount(_cfObject)
    }
    
    override func member(_ object: Any) -> Any? {
        
        guard let value = CFSetGetValue(_cfObject, unsafeBitCast(_SwiftValue.store(object), to: UnsafeRawPointer.self)) else {
            return nil
        }
        return _SwiftValue.fetch(nonOptional: unsafeBitCast(value, to: AnyObject.self))
        
    }
    
    override func objectEnumerator() -> NSEnumerator {
        
        var objArray: [AnyObject] = []
        let cf = _cfObject
        let count = CFSetGetCount(cf)
        
        let objects = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: count)
        CFSetGetValues(cf, objects)
        
        for idx in 0..<count {
            let obj = unsafeBitCast(objects.advanced(by: idx).pointee!, to: AnyObject.self)
            objArray.append(obj)
        }
        objects.deinitialize(count: 1)
        objects.deallocate()
        
        return NSGeneratorEnumerator(objArray.makeIterator())
        
    }
    
    override func add(_ object: Any) {
        CFSetAddValue(_cfMutableObject, unsafeBitCast(_SwiftValue.store(object), to: UnsafeRawPointer.self))
    }
    
    override func remove(_ object: Any) {
        CFSetRemoveValue(_cfMutableObject, unsafeBitCast(_SwiftValue.store(object), to: UnsafeRawPointer.self))
    }
    
}

internal func _CFSwiftSetGetCount(_ set: AnyObject) -> CFIndex {
    return (set as! NSSet).count
}

internal func _CFSwiftSetGetCountOfValue(_ set: AnyObject, value: AnyObject) -> CFIndex {
    if _CFSwiftSetContainsValue(set, value: value) {
        return 1
    } else {
        return 0
    }
}

internal func _CFSwiftSetContainsValue(_ set: AnyObject, value: AnyObject) -> Bool {
    return _CFSwiftSetGetValue(set, value: value, key: value) != nil
}

internal func _CFSwiftSetGetValues(_ set: AnyObject, _ values: UnsafeMutablePointer<Unmanaged<AnyObject>?>?) {
    
    var idx = 0
    if values == nil {
        return
    }
    
    let set = set as! NSSet
    if type(of: set) === NSSet.self || type(of: set) === NSMutableSet.self {
        for obj in set._storage {
            values?[idx] = Unmanaged<AnyObject>.passUnretained(obj)
            idx += 1
        }
    } else {
        set.enumerateObjects( { v, _ in
            let value = _SwiftValue.store(v)
            values?[idx] = Unmanaged<AnyObject>.passUnretained(value)
            set._storage.update(with: value)
            idx += 1
        })
    }
}

internal func _CFSwiftSetGetValue(_ set: AnyObject, value: AnyObject, key: AnyObject) -> Unmanaged<AnyObject>? {
    let set = set as! NSSet
    if type(of: set) === NSSet.self || type(of: set) === NSMutableSet.self {
        if let idx = set._storage.index(of: value as! NSObject){
            return Unmanaged<AnyObject>.passUnretained(set._storage[idx])
        }
        
    } else {
        let v = _SwiftValue.store(set.member(value))
        if let obj = v {
            set._storage.update(with: obj)
            return Unmanaged<AnyObject>.passUnretained(obj)
        }
    }
    return nil
}

internal func _CFSwiftSetGetValueIfPresent(_ set: AnyObject, object: AnyObject, value: UnsafeMutablePointer<Unmanaged<AnyObject>?>?) -> Bool {
    if let val = _CFSwiftSetGetValue(set, value: object, key: object) {
        value?.pointee = val
        return true
    } else {
        value?.pointee = nil
        return false
    }
}

internal func _CFSwiftSetApplyFunction(_ set: AnyObject, applier: @convention(c) (AnyObject, UnsafeMutableRawPointer) -> Void, context: UnsafeMutableRawPointer) {
    (set as! NSSet).enumerateObjects({ value, _ in
        applier(_SwiftValue.store(value), context)
    })
}

internal func _CFSwiftSetMember(_ set: CFTypeRef, _ object: CFTypeRef) -> Unmanaged<CFTypeRef>? {
    return _CFSwiftSetGetValue(set, value: object, key: object)
}

internal func _CFSwiftSetAddValue(_ set: AnyObject, value: AnyObject) {
    (set as! NSMutableSet).add(value)
}

internal func _CFSwiftSetReplaceValue(_ set:  AnyObject, value: AnyObject) {
    let set = set as! NSMutableSet
    if (set.contains(value)){
        set.remove(value)
        set.add(value)
    }
}

internal func _CFSwiftSetSetValue(_ set:  AnyObject, value: AnyObject) {
    let set = set as! NSMutableSet
    set.remove(value)
    set.add(value)
}

internal func _CFSwiftSetRemoveValue(_ set:  AnyObject, value: AnyObject) {
    (set as! NSMutableSet).remove(value)
}

internal func _CFSwiftSetRemoveAllValues(_ set: AnyObject) {
    (set as! NSMutableSet).removeAllObjects()
}

internal func _CFSwiftSetCreateCopy(_ set: AnyObject) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((set as! NSSet).copy() as! NSObject)
}
