//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

internal import CoreFoundation

extension DateComponents : ReferenceConvertible {
    public typealias ReferenceType = NSDateComponents
    
    internal init(reference: NSDateComponents) {
        self = reference._components
    }
}

// MARK: - Bridging

extension DateComponents : _ObjectiveCBridgeable {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    public static func _getObjectiveCType() -> Any.Type {
        return NSDateComponents.self
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSDateComponents {
        NSDateComponents(components: self)
    }
    
    public static func _forceBridgeFromObjectiveC(_ dateComponents: NSDateComponents, result: inout DateComponents?) {
        if !_conditionallyBridgeFromObjectiveC(dateComponents, result: &result) {
            fatalError("Unable to bridge \(DateComponents.self) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ dateComponents: NSDateComponents, result: inout DateComponents?) -> Bool {
        result = DateComponents(reference: dateComponents)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSDateComponents?) -> DateComponents {
        var result: DateComponents? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}

extension DateComponents : _NSBridgeable {
    typealias NSType = NSDateComponents
    var _nsObject: NSType { return _bridgeToObjectiveC() }
}

extension DateComponents {
    func _createCFDateComponents() -> CFDateComponents {
        return _nsObject._createCFDateComponents()
    }
}
