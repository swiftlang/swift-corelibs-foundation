// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

internal final class _NSCFDictionary : NSMutableDictionary {
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

    required init(objects: UnsafePointer<AnyObject>!, forKeys keys: UnsafePointer<NSObject>!, count cnt: Int) {
        fatalError()
    }
    
    required public convenience init(dictionaryLiteral elements: (Any, Any)...) {
        fatalError("init(dictionaryLiteral:) has not been implemented")
    }

    override var count: Int {
        return CFDictionaryGetCount(unsafeBitCast(self, to: CFDictionary.self))
    }
    
    override func object(forKey aKey: Any) -> Any? {
        let value = CFDictionaryGetValue(_cfObject, unsafeBitCast(_SwiftValue.store(aKey), to: UnsafeRawPointer.self))
        if value != nil {
            return _SwiftValue.fetch(nonOptional: unsafeBitCast(value, to: AnyObject.self))
        } else {
            return nil
        }
    }
    
    // This doesn't feel like a particularly efficient generator of CFDictionary keys, but it works for now. We should probably put a function into CF that allows us to simply iterate the keys directly from the underlying CF storage.
    private struct _NSCFKeyGenerator : IteratorProtocol {
        var keyArray : [NSObject] = []
        var index : Int = 0
        let count : Int
        mutating func next() -> AnyObject? {
            if index == count {
                return nil
            } else {
                let item = keyArray[index]
                index += 1
                return item
            }
        }
        
        init(_ dict : _NSCFDictionary) {
            let cf = dict._cfObject
            count = CFDictionaryGetCount(cf)
            
            let keys = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: count)            
            CFDictionaryGetKeysAndValues(cf, keys, nil)
            
            for idx in 0..<count {
                let key = unsafeBitCast(keys.advanced(by: idx).pointee!, to: NSObject.self)
                keyArray.append(key)
            }
            keys.deinitialize(count: 1)
            keys.deallocate()
        }
    }

    override func keyEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(_NSCFKeyGenerator(self))
    }

    override func removeObject(forKey aKey: Any) {
        CFDictionaryRemoveValue(_cfMutableObject, unsafeBitCast(_SwiftValue.store(aKey), to: UnsafeRawPointer.self))
    }
    
    override func setObject(_ anObject: Any, forKey aKey: AnyHashable) {
        CFDictionarySetValue(_cfMutableObject, unsafeBitCast(_SwiftValue.store(aKey), to: UnsafeRawPointer.self), unsafeBitCast(_SwiftValue.store(anObject), to: UnsafeRawPointer.self))
    }
    
    override var classForCoder: AnyClass {
        return NSMutableDictionary.self
    }
}

internal func _CFSwiftDictionaryGetCount(_ dictionary: AnyObject) -> CFIndex {
    return (dictionary as! NSDictionary).count
}

internal func _CFSwiftDictionaryGetCountOfKey(_ dictionary: AnyObject, key: AnyObject) -> CFIndex {
    if _CFSwiftDictionaryContainsKey(dictionary, key: key) {
        return 1
    } else {
        return 0
    }
}

internal func _CFSwiftDictionaryContainsKey(_ dictionary: AnyObject, key: AnyObject) -> Bool {
    return (dictionary as! NSDictionary).object(forKey: key) != nil
}

//(AnyObject, AnyObject) -> Unmanaged<AnyObject>
internal func _CFSwiftDictionaryGetValue(_ dictionary: AnyObject, key: AnyObject) -> Unmanaged<AnyObject>? {
    let dict = dictionary as! NSDictionary
    if type(of: dictionary) === NSDictionary.self || type(of: dictionary) === NSMutableDictionary.self {
        if let obj = dict._storage[key as! NSObject] {
            return Unmanaged<AnyObject>.passUnretained(obj)
        }
    } else {
        let k = _SwiftValue.fetch(nonOptional: key)
        let value = dict.object(forKey: k)
        let v = _SwiftValue.store(value)
        dict._storage[key as! NSObject] = v
        if let obj = v {
            return Unmanaged<AnyObject>.passUnretained(obj)
        }
    }
    return nil
}

internal func _CFSwiftDictionaryGetValueIfPresent(_ dictionary: AnyObject, key: AnyObject, value: UnsafeMutablePointer<Unmanaged<AnyObject>?>?) -> Bool {
    if let val = _CFSwiftDictionaryGetValue(dictionary, key: key) {
        value?.pointee = val
        return true
    } else {
        value?.pointee = nil
        return false
    }
}

internal func _CFSwiftDictionaryGetCountOfValue(_ dictionary: AnyObject, value: AnyObject) -> CFIndex {
    if _CFSwiftDictionaryContainsValue(dictionary, value: value) {
        return 1
    } else {
        return 0
    }
}

internal func _CFSwiftDictionaryContainsValue(_ dictionary: AnyObject, value: AnyObject) -> Bool {
    NSUnimplemented()
}

// HAZARD! WARNING!
// The contract of these CF APIs is that the elements in the buffers have a lifespan of the container dictionary.
// Since the public facing elements of the dictionary may be a structure (which could not be retained) or the boxing
// would potentially make a reference that is not the direct access of the element, this function must do a bit of
// hoop jumping to deal with storage.
// In the case of NSDictionary and NSMutableDictionary (NOT subclasses) we can directly reach into the storage and
// grab the un-fetched items. This allows the same behavior to be maintained.
// In the case of subclasses of either NSDictionary or NSMutableDictionary we cannot reconstruct boxes here since
// they will fall out of scope and be consumed by automatic reference counting at the end of this function. But since
// swift has a fragile layout we can reach into the super-class ivars (NSDictionary) and store boxed references to ensure lifespan
// is similar to how it works on Darwin. Effectively this binds the acceess point of all values and keys for those objects
// to have the same lifespan of the parent container object.

internal func _CFSwiftDictionaryGetValuesAndKeys(_ dictionary: AnyObject, valuebuf: UnsafeMutablePointer<Unmanaged<AnyObject>?>?, keybuf: UnsafeMutablePointer<Unmanaged<AnyObject>?>?) {
    var idx = 0
    if valuebuf == nil && keybuf == nil {
        return
    }
    
    let dict = dictionary as! NSDictionary
    if type(of: dictionary) === NSDictionary.self || type(of: dictionary) === NSMutableDictionary.self {
        for (key, value) in dict._storage {
            valuebuf?[idx] = Unmanaged<AnyObject>.passUnretained(value)
            keybuf?[idx] = Unmanaged<AnyObject>.passUnretained(key)
            idx += 1
        }
    } else {
        dict.enumerateKeysAndObjects(options: []) { k, v, _ in
            let key = _SwiftValue.store(k)
            let value = _SwiftValue.store(v)
            valuebuf?[idx] = Unmanaged<AnyObject>.passUnretained(value)
            keybuf?[idx] = Unmanaged<AnyObject>.passUnretained(key)
            dict._storage[key] = value
            idx += 1
        }
    }
}

internal func _CFSwiftDictionaryApplyFunction(_ dictionary: AnyObject, applier: @convention(c) (AnyObject, AnyObject, UnsafeMutableRawPointer) -> Void, context: UnsafeMutableRawPointer) {
    (dictionary as! NSDictionary).enumerateKeysAndObjects(options: []) { key, value, _ in
        applier(_SwiftValue.store(key), _SwiftValue.store(value), context)
    }
}

internal func _CFSwiftDictionaryAddValue(_ dictionary: AnyObject, key: AnyObject, value: AnyObject) {
    (dictionary as! NSMutableDictionary).setObject(value, forKey: key as! NSObject)
}

internal func _CFSwiftDictionaryReplaceValue(_ dictionary:  AnyObject, key: AnyObject, value: AnyObject) {
    (dictionary as! NSMutableDictionary).setObject(value, forKey: key as! NSObject)
}

internal func _CFSwiftDictionarySetValue(_ dictionary:  AnyObject, key: AnyObject, value: AnyObject) {
    (dictionary as! NSMutableDictionary).setObject(value, forKey: key as! NSObject)
}

internal func _CFSwiftDictionaryRemoveValue(_ dictionary:  AnyObject, key: AnyObject) {
    (dictionary as! NSMutableDictionary).removeObject(forKey: key)
}

internal func _CFSwiftDictionaryRemoveAllValues(_ dictionary: AnyObject) {
    (dictionary as! NSMutableDictionary).removeAllObjects()
}

internal func _CFSwiftDictionaryCreateCopy(_ dictionary: AnyObject) -> Unmanaged<AnyObject> {
    return Unmanaged<AnyObject>.passRetained((dictionary as! NSDictionary).copy() as! NSObject)
}
