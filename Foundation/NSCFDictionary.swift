// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
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
        return CFDictionaryGetCount(unsafeBitCast(self, CFDictionaryRef.self))
    }
    
    override func objectForKey(aKey: AnyObject) -> AnyObject? {
        let value = CFDictionaryGetValue(_cfObject, unsafeBitCast(aKey, UnsafePointer<Void>.self))
        if value != nil {
            return unsafeBitCast(value, AnyObject.self)
        } else {
            return nil
        }
    }
    
    // This doesn't feel like a particularly efficient generator of CFDictionary keys, but it works for now. We should probably put a function into CF that allows us to simply iterate the keys directly from the underlying CF storage.
    private struct _NSCFKeyGenerator : GeneratorType {
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
            
            let keys = UnsafeMutablePointer<UnsafePointer<Void>>.alloc(count)            
            CFDictionaryGetKeysAndValues(cf, keys, nil)
            
            for idx in 0..<count {
                let key = unsafeBitCast(keys.advancedBy(idx).memory, NSObject.self)
                keyArray.append(key)
            }
            keys.destroy()
            keys.dealloc(count)
        }
    }

    override func keyEnumerator() -> NSEnumerator {
        return NSGeneratorEnumerator(_NSCFKeyGenerator(self))
    }

    override func removeObjectForKey(aKey: AnyObject) {
        CFDictionaryRemoveValue(_cfMutableObject, unsafeBitCast(aKey, UnsafePointer<Void>.self))
    }
    
    override func setObject(anObject: AnyObject, forKey aKey: NSObject) {
        CFDictionarySetValue(_cfMutableObject, unsafeBitCast(aKey, UnsafePointer<Void>.self), unsafeBitCast(anObject, UnsafePointer<Void>.self))
    }
    
    override var classForCoder: AnyClass {
        return NSMutableDictionary.self
    }
}

internal func _CFSwiftDictionaryGetCount(dictionary: AnyObject) -> CFIndex {
    return (dictionary as! NSDictionary).count
}

internal func _CFSwiftDictionaryGetCountOfKey(dictionary: AnyObject, key: AnyObject) -> CFIndex {
    if _CFSwiftDictionaryContainsKey(dictionary, key: key) {
        return 1
    } else {
        return 0
    }
}

internal func _CFSwiftDictionaryContainsKey(dictionary: AnyObject, key: AnyObject) -> Bool {
    return (dictionary as! NSDictionary).objectForKey(key) != nil
}

//(AnyObject, AnyObject) -> Unmanaged<AnyObject>
internal func _CFSwiftDictionaryGetValue(dictionary: AnyObject, key: AnyObject) -> Unmanaged<AnyObject>? {
    if let obj = (dictionary as! NSDictionary).objectForKey(key) {
        return Unmanaged<AnyObject>.passUnretained(obj)
    } else {
        return nil
    }
}

internal func _CFSwiftDictionaryGetValueIfPresent(dictionary: AnyObject, key: AnyObject, value: UnsafeMutablePointer<Unmanaged<AnyObject>?>) -> Bool {
    if let val = _CFSwiftDictionaryGetValue(dictionary, key: key) {
        value.memory = val
        return true
    } else {
        value.memory = nil
        return false
    }
}

internal func _CFSwiftDictionaryGetCountOfValue(dictionary: AnyObject, value: AnyObject) -> CFIndex {
    if _CFSwiftDictionaryContainsValue(dictionary, value: value) {
        return 1
    } else {
        return 0
    }
}

internal func _CFSwiftDictionaryContainsValue(dictionary: AnyObject, value: AnyObject) -> Bool {
    NSUnimplemented()
}

internal func _CFSwiftDictionaryGetValuesAndKeys(dictionary: AnyObject, valuebuf: UnsafeMutablePointer<Unmanaged<AnyObject>?>, keybuf: UnsafeMutablePointer<Unmanaged<AnyObject>?>) {
    var idx = 0
    if valuebuf == nil && keybuf == nil {
        return
    }
    (dictionary as! NSDictionary).enumerateKeysAndObjectsUsingBlock { key, value, _ in
	if valuebuf != nil {
	    valuebuf[idx] = Unmanaged<AnyObject>.passUnretained(value)
	}
	if keybuf != nil {
	    keybuf[idx] = Unmanaged<AnyObject>.passUnretained(key)
	}
        idx += 1
    }
}

internal func _CFSwiftDictionaryApplyFunction(dictionary: AnyObject, applier: @convention(c) (AnyObject, AnyObject, UnsafeMutablePointer<Void>) -> Void, context: UnsafeMutablePointer<Void>) {
    (dictionary as! NSDictionary).enumerateKeysAndObjectsUsingBlock { key, value, _ in
        applier(key, value, context)
    }
}

internal func _CFSwiftDictionaryAddValue(dictionary: AnyObject, key: AnyObject, value: AnyObject) {
    (dictionary as! NSMutableDictionary).setObject(value, forKey: key as! NSObject)
}

internal func _CFSwiftDictionaryReplaceValue(dictionary:  AnyObject, key: AnyObject, value: AnyObject) {
    (dictionary as! NSMutableDictionary).setObject(value, forKey: key as! NSObject)
}

internal func _CFSwiftDictionarySetValue(dictionary:  AnyObject, key: AnyObject, value: AnyObject) {
    (dictionary as! NSMutableDictionary).setObject(value, forKey: key as! NSObject)
}

internal func _CFSwiftDictionaryRemoveValue(dictionary:  AnyObject, key: AnyObject) {
    (dictionary as! NSMutableDictionary).removeObjectForKey(key)
}

internal func _CFSwiftDictionaryRemoveAllValues(dictionary: AnyObject) {
    (dictionary as! NSMutableDictionary).removeAllObjects()
}
