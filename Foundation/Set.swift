// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

extension Set : _ObjectiveCBridgeable {
    public typealias _ObjectType = NSSet
    public func _bridgeToObjectiveC() -> _ObjectType {
        let buffer = UnsafeMutablePointer<AnyObject>.allocate(capacity: count)
        
        for (idx, obj) in enumerated() {
            buffer.advanced(by: idx).initialize(to: obj as AnyObject)
        }
        
        let set = NSSet(objects: buffer, count: count)
        
        buffer.deinitialize(count: count)
        buffer.deallocate()
        
        return set
    }
    
    public static func _forceBridgeFromObjectiveC(_ source: _ObjectType, result: inout Set?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    
    @discardableResult
    public static func _conditionallyBridgeFromObjectiveC(_ source: _ObjectType, result: inout Set?) -> Bool {
        var set = Set<Element>()
        var failedConversion = false
        
        if type(of: source) == NSSet.self || type(of: source) == NSMutableSet.self {
            source.enumerateObjects(options: []) { obj, stop in
                if let o = obj as? Element {
                    set.insert(o)
                } else {
                    // here obj must be a swift type
                    if let nsObject = _SwiftValue.store(obj) as? Element {
                        set.insert(nsObject)
                    } else {
                        failedConversion = true
                        stop.pointee = true
                    }
                }
            }
        } else if type(of: source) == _NSCFSet.self {
            let cf = source._cfObject
            let cnt = CFSetGetCount(cf)
            
            let objs = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: cnt)
            
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
            objs.deallocate()
        }
        if !failedConversion {
            result = set
            return true
        }
        return false
    }
    
    static public func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectType?) -> Set {
        if let object = source {
            var value: Set<Element>?
            _conditionallyBridgeFromObjectiveC(object, result: &value)
            return value!
        } else {
            return Set<Element>()
        }
    }
}
