// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

extension Array : _ObjectiveCBridgeable {
    
    public typealias _ObjectType = NSArray
    public func _bridgeToObjectiveC() -> _ObjectType {
        return NSArray(array: map { (element: Element) -> AnyObject in
            return _SwiftValue.store(element)
        })
    }
    
    static public func _forceBridgeFromObjectiveC(_ source: _ObjectType, result: inout Array?) {
        result = _unconditionallyBridgeFromObjectiveC(source)
    }
    
    @discardableResult
    static public func _conditionallyBridgeFromObjectiveC(_ source: _ObjectType, result: inout Array?) -> Bool {
        var array = [Element]()
        for value in source.allObjects {
            if let v = value as? Element {
                array.append(v)
            } else {
                return false
            }
        }
        result = array
        return true
    }
    
    static public func _unconditionallyBridgeFromObjectiveC(_ source: _ObjectType?) -> Array {
        if let object = source {
            var value: Array<Element>?
            _conditionallyBridgeFromObjectiveC(object, result: &value)
            return value!
        } else {
            return Array<Element>()
        }
    }
}

