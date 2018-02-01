// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

internal final class _NSCFArray : NSMutableArray {
    deinit {
        _CFDeinit(self)
        _CFZeroUnsafeIvars(&_storage)
    }
    
    required init(coder: NSCoder) {
        fatalError()
    }
    
    required init(objects: UnsafePointer<AnyObject>?, count cnt: Int) {
        fatalError()
    }
    
    required public convenience init(arrayLiteral elements: Any...) {
        fatalError()
    }
    
    override var count: Int {
        return CFArrayGetCount(_cfObject)
    }
    
    override func object(at index: Int) -> Any {
        let value = CFArrayGetValueAtIndex(_cfObject, index)
        return _SwiftValue.fetch(nonOptional: unsafeBitCast(value, to: AnyObject.self))
    }
    
    override func insert(_ value: Any, at index: Int) {
        let anObject = _SwiftValue.store(value)
        CFArrayInsertValueAtIndex(_cfMutableObject, index, unsafeBitCast(anObject, to: UnsafeRawPointer.self))
    }
    
    override func removeObject(at index: Int) {
        CFArrayRemoveValueAtIndex(_cfMutableObject, index)
    }
    
    override var classForCoder: AnyClass {
        return NSMutableArray.self
    }
}

internal func _CFSwiftArrayGetCount(_ array: AnyObject) -> CFIndex {
    return (array as! NSArray).count
}

internal func _CFSwiftArrayGetValueAtIndex(_ array: AnyObject, _ index: CFIndex) -> Unmanaged<AnyObject> {
    let arr = array as! NSArray
    if type(of: array) === NSArray.self || type(of: array) === NSMutableArray.self {
        return Unmanaged.passUnretained(arr._storage[index])
    } else {
        let value = _SwiftValue.store(arr.object(at: index))
        let container: NSMutableDictionary
        if arr._storage.isEmpty {
            container = NSMutableDictionary()
            arr._storage.append(container)
        } else {
            container = arr._storage[0] as! NSMutableDictionary
        }
        container[NSNumber(value: index)] = value
        return Unmanaged.passUnretained(value)
    }
}

internal func _CFSwiftArrayGetValues(_ array: AnyObject, _ range: CFRange, _ values: UnsafeMutablePointer<Unmanaged<AnyObject>?>) {
    let arr = array as! NSArray
    if type(of: array) === NSArray.self || type(of: array) === NSMutableArray.self {
        for idx in 0..<range.length {
            values[idx] = Unmanaged.passUnretained(arr._storage[idx + range.location])
        }
    } else {
        for idx in 0..<range.length {
            let index = idx + range.location
            let value = _SwiftValue.store(arr.object(at: index))
            let container: NSMutableDictionary
            if arr._storage.isEmpty {
                container = NSMutableDictionary()
                arr._storage.append(container)
            } else {
                container = arr._storage[0] as! NSMutableDictionary
            }
            container[NSNumber(value: index)] = value
            values[idx] = Unmanaged.passUnretained(value)
        }
    }
}

internal func _CFSwiftArrayAppendValue(_ array: AnyObject, _ value: AnyObject) {
    (array as! NSMutableArray).add(value)
}

internal func _CFSwiftArraySetValueAtIndex(_ array: AnyObject, _ value: AnyObject, _ idx: CFIndex) {
    (array as! NSMutableArray).replaceObject(at: idx, with: value)
}

internal func _CFSwiftArrayReplaceValueAtIndex(_ array: AnyObject, _ idx: CFIndex, _ value: AnyObject) {
    (array as! NSMutableArray).replaceObject(at: idx, with: value)
}

internal func _CFSwiftArrayInsertValueAtIndex(_ array: AnyObject, _ idx: CFIndex, _ value: AnyObject) {
    (array as! NSMutableArray).insert(value, at: idx)
}

internal func _CFSwiftArrayExchangeValuesAtIndices(_ array: AnyObject, _ idx1: CFIndex, _ idx2: CFIndex) {
    (array as! NSMutableArray).exchangeObject(at: idx1, withObjectAt: idx2)
}

internal func _CFSwiftArrayRemoveValueAtIndex(_ array: AnyObject, _ idx: CFIndex) {
    (array as! NSMutableArray).removeObject(at: idx)
}

internal func _CFSwiftArrayRemoveAllValues(_ array: AnyObject) {
    (array as! NSMutableArray).removeAllObjects()
}

internal func _CFSwiftArrayReplaceValues(_ array: AnyObject, _ range: CFRange, _ newValues: UnsafeMutablePointer<Unmanaged<AnyObject>>, _ newCount: CFIndex) {
    NSUnimplemented()
//    (array as! NSMutableArray).replaceObjectsInRange(NSRange(location: range.location, length: range.length), withObjectsFrom: newValues.array(newCount))
}
