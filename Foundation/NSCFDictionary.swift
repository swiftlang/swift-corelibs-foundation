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

    required init(objects: UnsafePointer<AnyObject>, forKeys keys: UnsafePointer<NSObject>, count cnt: Int) {
        fatalError()
    }
    
    required convenience init(dictionaryLiteral elements: (NSObject, AnyObject)...) {
        fatalError()
    }
    
    override var count: Int {
        return CFDictionaryGetCount(unsafeBitCast(self, to: CFDictionary.self))
    }
    
    override func objectForKey(_ aKey: AnyObject) -> AnyObject? {
        let value = CFDictionaryGetValue(_cfObject, unsafeBitCast(aKey, to: UnsafeRawPointer.self))
        if value != nil {
            return unsafeBitCast(value, to: AnyObject.self)
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
            keys.deinitialize()
            keys.deallocate(capacity: count)
        }
    }

    override func keyEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(_NSCFKeyGenerator(self))
    }

    override func removeObject(forKey aKey: AnyObject) {
        CFDictionaryRemoveValue(_cfMutableObject, unsafeBitCast(aKey, to: UnsafeRawPointer.self))
    }
    
    override func setObject(_ anObject: AnyObject, forKey aKey: NSObject) {
        CFDictionarySetValue(_cfMutableObject, unsafeBitCast(aKey, to: UnsafeRawPointer.self), unsafeBitCast(anObject, to: UnsafeRawPointer.self))
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
    return (dictionary as! NSDictionary).objectForKey(key) != nil
}

//(AnyObject, AnyObject) -> Unmanaged<AnyObject>
internal func _CFSwiftDictionaryGetValue(_ dictionary: AnyObject, key: AnyObject) -> Unmanaged<AnyObject>? {
    if let obj = (dictionary as! NSDictionary).objectForKey(key) {
        return Unmanaged<AnyObject>.passUnretained(obj)
    } else {
        return nil
    }
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

internal func _CFSwiftDictionaryGetValuesAndKeys(_ dictionary: AnyObject, valuebuf: UnsafeMutablePointer<Unmanaged<AnyObject>?>?, keybuf: UnsafeMutablePointer<Unmanaged<AnyObject>?>?) {
    var idx = 0
    if valuebuf == nil && keybuf == nil {
        return
    }
    (dictionary as! NSDictionary).enumerateKeysAndObjects([]) { key, value, _ in
        valuebuf?[idx] = Unmanaged<AnyObject>.passUnretained(value)
        keybuf?[idx] = Unmanaged<AnyObject>.passUnretained(key)
        idx += 1
    }
}

internal func _CFSwiftDictionaryApplyFunction(_ dictionary: AnyObject, applier: @convention(c) (AnyObject, AnyObject, UnsafeMutableRawPointer) -> Void, context: UnsafeMutableRawPointer) {
    (dictionary as! NSDictionary).enumerateKeysAndObjects([]) { key, value, _ in
        applier(key, value, context)
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
