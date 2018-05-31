// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

extension Dictionary : _ObjectiveCBridgeable {
    
    public typealias _ObjectType = NSDictionary
    public func _bridgeToObjectiveC() -> _ObjectType {
        let keyBuffer = UnsafeMutablePointer<NSObject>.allocate(capacity: count)
        let valueBuffer = UnsafeMutablePointer<AnyObject>.allocate(capacity: count)
        
        var idx = 0
        
        self.forEach { (keyItem, valueItem) in
            let key = _SwiftValue.store(keyItem)
            let value = _SwiftValue.store(valueItem)
            keyBuffer.advanced(by: idx).initialize(to: key)
            valueBuffer.advanced(by: idx).initialize(to: value)
            idx += 1
        }
        
        let dict = NSDictionary(objects: valueBuffer, forKeys: keyBuffer, count: count)
        
        keyBuffer.deinitialize(count: count)
        valueBuffer.deinitialize(count: count)
        keyBuffer.deallocate()
        valueBuffer.deallocate()
        
        return dict

    }
    
    static public func _forceBridgeFromObjectiveC(_ source: _ObjectType, result: inout Dictionary?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    
    @discardableResult
    static public func _conditionallyBridgeFromObjectiveC(_ source: _ObjectType, result: inout Dictionary?) -> Bool {
        var dict = [Key: Value]()
        var failedConversion = false

        if type(of: source) == NSDictionary.self || type(of: source) == NSMutableDictionary.self {
            source.enumerateKeysAndObjects(options: []) { key, value, stop in
                guard let key = key as? Key, let value = value as? Value else {
                    failedConversion = true
                    stop.pointee = true
                    return
                }
                dict[key] = value
            }
        } else if type(of: source) == _NSCFDictionary.self {
            let cf = source._cfObject
            let cnt = CFDictionaryGetCount(cf)

            let keys = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: cnt)
            let values = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: cnt)

            CFDictionaryGetKeysAndValues(cf, keys, values)

            for idx in 0..<cnt {
                let key = _SwiftValue.fetch(nonOptional: unsafeBitCast(keys.advanced(by: idx).pointee!, to: AnyObject.self))
                let value = _SwiftValue.fetch(nonOptional: unsafeBitCast(values.advanced(by: idx).pointee!, to: AnyObject.self))
                guard let k = key as? Key, let v = value as? Value else {
                    failedConversion = true
                    break
                }
                dict[k] = v
            }
            keys.deinitialize(count: cnt)
            values.deinitialize(count: cnt)
            keys.deallocate()
            values.deallocate()
        }
        if !failedConversion {
            result = dict
            return true
        }
        return false
    }
    
    static public func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectType?) -> Dictionary {
        if let object = source {
            var value: Dictionary<Key, Value>?
            _conditionallyBridgeFromObjectiveC(object, result: &value)
            return value!
        } else {
            return Dictionary<Key, Value>()
        }
    }
}
