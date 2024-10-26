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

@available(*, unavailable)
extension Notification : @unchecked Sendable { }

/**
 `Notification` encapsulates information broadcast to observers via a `NotificationCenter`.
 */
public struct Notification : ReferenceConvertible, Equatable, Hashable {
    public typealias ReferenceType = NSNotification
    
    /// A tag identifying the notification.
    public var name: Name
    
    /// An object that the poster wishes to send to observers.
    ///
    /// Typically this is the object that posted the notification.
    public var object: Any?
    
    /// Storage for values or objects related to this notification.
    public var userInfo: [AnyHashable : Any]?
    
    /// Initialize a new `Notification`.
    ///
    /// The default value for `userInfo` is nil.
    public init(name: Name, object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
        self.name = name
        self.object = object
        self.userInfo = userInfo
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        // FIXME: We should feed the object to the hasher, but using
        // the object identity would make the hash encoding unstable.

        // FIXME: Darwin also hashes the keys in the userInfo dictionary.
    }
    
    public var description: String {
        var description = "name = \(name.rawValue)"
        if let obj = object { description += ", object = \(obj)" }
        if let info = userInfo { description += ", userInfo = \(info)" }
        return description
    }
    
    public var debugDescription: String {
        return description
    }
    
    // FIXME: Handle directly via API Notes
    public typealias Name = NSNotification.Name
    
    public static func ==(lhs: Notification, rhs: Notification) -> Bool {
        // FIXME: Darwin also compares the userInfo dictionary.
        if lhs.name.rawValue != rhs.name.rawValue {
            return false
        }
        if let lhsObj = lhs.object {
            if let rhsObj = rhs.object {
                // FIXME: This violates reflexivity if object isn't Hashable.
                if __SwiftValue.store(lhsObj) !== __SwiftValue.store(rhsObj) {
                    return false
                }
            } else {
                return false
            }
        } else if rhs.object != nil {
            return false
        }
        return true
    }
}

extension Notification : CustomReflectable {
    public var customMirror: Mirror {
        var children: [(label: String?, value: Any)] = [(label: "name", self.name.rawValue)]

        if let object = self.object {
            children.append((label: "object", object))
        }

        if let info = self.userInfo {
            children.append((label: "userInfo", info))
        }

        return Mirror(self, children: children, displayStyle: .class)
    }
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
