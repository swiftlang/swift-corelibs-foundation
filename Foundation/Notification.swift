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
    public var object: AnyObject?
    
    /// Storage for values or objects related to this notification.
    public var userInfo: [String : Any]?
    
    /// Initialize a new `Notification`.
    ///
    /// The default value for `userInfo` is nil.
    public init(name: Name, object: AnyObject? = nil, userInfo: [String : Any]? = nil) {
        self.name = name
        self.object = object
        self.userInfo = userInfo
    }
    
    public var hashValue: Int {
        return name.rawValue.hash
    }
    
    public var description: String {
        return "name = \(name.rawValue),  object = \(object), userInfo = \(userInfo)"
    }
    
    public var debugDescription: String {
        return description
    }
    
    // FIXME: Handle directly via API Notes
    public typealias Name = NSNotification.Name
}

public func ==(lhs: Notification, rhs: Notification) -> Bool {
    if lhs.name.rawValue != rhs.name.rawValue {
        return false
    }
    if let lhsObj = lhs.object {
        if let rhsObj = rhs.object {
            if lhsObj !== rhsObj {
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
