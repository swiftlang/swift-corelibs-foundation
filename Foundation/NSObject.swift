// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

public protocol NSObjectProtocol {
    
    func isEqual(object: AnyObject?) -> Bool
    var hash: Int { get }
    
    func `self`() -> Self
    
    func isProxy() -> Bool

    var description: String { get }
    
    var debugDescription: String { get }
}

extension NSObjectProtocol {
    public var debugDescription: String {
        get {
            return description
        }
    }
}

public struct NSZone : NilLiteralConvertible {
    public init() {
        
    }
    
    public init(nilLiteral: ()) {
        
    }
}

public protocol NSCopying {
    
    func copyWithZone(zone: NSZone) -> AnyObject
}

extension NSCopying {
    public func copy() -> AnyObject {
        return copyWithZone(nil)
    }
}

public protocol NSMutableCopying {
    
    func mutableCopyWithZone(zone: NSZone) -> AnyObject
}

extension NSMutableCopying {
    public func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }
}

public class NSObject : NSObjectProtocol {
    // Important: add no ivars here. It will subvert the careful layout of subclasses that bridge into CF.    
    
    public init() {
        
    }
    
    public func copy() -> AnyObject {
        if let copyable = self as? NSCopying {
            return copyable.copyWithZone(nil)
        }
        return self
    }
    
    public func mutableCopy() -> AnyObject {
        if let copyable = self as? NSMutableCopying {
            return copyable.mutableCopyWithZone(nil)
        }
        return self
    }
    
    public func isEqual(object: AnyObject?) -> Bool {
        return object === self
    }
    
    public var hash: Int {
        get {
            return ObjectIdentifier(self).hashValue
        }
    }
    
    public func `self`() -> Self {
        return self
    }
    
    public func isProxy() -> Bool {
        return false
    }
    
    public var description: String {
        get {
            return "<\(self.dynamicType): \(unsafeAddressOf(self))>"
        }
    }
    
    public var debugDescription: String {
        get {
            return description
        }
    }
    
    internal var _cfTypeID: CFTypeID {
        return 0
    }
}


extension NSObject : Equatable, Hashable {
    public var hashValue: Int {
        get {
            return hash
        }
    }
}

public func ==(lhs: NSObject, rhs: NSObject) -> Bool {
    return lhs.isEqual(rhs)
}

extension NSObject : CustomDebugStringConvertible {
}

extension NSObject : CustomStringConvertible {
}
