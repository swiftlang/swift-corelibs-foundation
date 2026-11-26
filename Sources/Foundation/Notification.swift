//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

extension Notification : ReferenceConvertible {
    public typealias ReferenceType = NSNotification
}

extension Notification : _ObjectiveCBridgeable {
    public static func _getObjectiveCType() -> Any.Type {
        return NSNotification.self
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSNotification {
        return NSNotification(name: name, object: object, userInfo: userInfo)
    }
    
    public static func _forceBridgeFromObjectiveC(_ x: NSNotification, result: inout Notification?) {
        if !_conditionallyBridgeFromObjectiveC(x, result: &result) {
            fatalError("Unable to bridge \(NSNotification.self) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ x: NSNotification, result: inout Notification?) -> Bool {
        result = Notification(name: x.name, object: x.object, userInfo: x.userInfo)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSNotification?) -> Notification {
        var result: Notification? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}
