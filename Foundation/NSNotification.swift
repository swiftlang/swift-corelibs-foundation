// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public class NSNotification : NSObject, NSCopying, NSCoding {
    
    public var name: String {
        NSUnimplemented()
    }
    
    public var object: AnyObject? {
        NSUnimplemented()
    }
    
    public var userInfo: [NSObject : AnyObject]? {
        NSUnimplemented()
    }
    
    public convenience override init() {
        /* do not invoke; not a valid initializer for this class */
        fatalError()
    }
    
    public init(name: String, object: AnyObject?, userInfo: [NSObject : AnyObject]?) {
        NSUnimplemented()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
}

extension NSNotification {
    public convenience init(name aName: String, object anObject: AnyObject?) {
        NSUnimplemented()
    }
}

public class NSNotificationCenter : NSObject {
    private var _observers = [NSNotificationObserver]()
    
    
    /* Returns the default singleton instance.
    */
    internal static let defaultInstance = NSNotificationCenter()
    public class func defaultCenter() -> NSNotificationCenter {
        return defaultInstance
    }
    
    public func postNotification(notification: NSNotification) {
        NSUnimplemented()
    }

    public func postNotificationName(aName: String, object anObject: AnyObject?) {
        NSUnimplemented()
    }

    public func postNotificationName(aName: String, object anObject: AnyObject?, userInfo aUserInfo: [NSObject : AnyObject]?) {
        NSUnimplemented()
    }

    
    public func removeObserver(observer: AnyObject) {
        NSUnimplemented()
    }

    public func removeObserver(observer: AnyObject, name aName: String?, object anObject: AnyObject?) {
        NSUnimplemented()
    }

    
    public func addObserverForName(name: String?, object obj: AnyObject?, queue: NSOperationQueue?, usingBlock block: (NSNotification) -> Void) -> NSObjectProtocol {
        // Create observer object and store it
        let observer = NSNotificationObserver(name: name, object: obj, queue: queue, usingBlock: block)
        _observers.append(observer)
        return observer
    }
}

extension NSNotificationCenter {
    
    private class NSNotificationObserver : NSObject {
        let name: String?
        let object: AnyObject?
        let queue: NSOperationQueue?
        let block: (NSNotification) -> Void
        init(name: String?, object obj: AnyObject?, queue: NSOperationQueue?, usingBlock block: (NSNotification) -> Void) {
            self.name = name
            self.object = obj
            self.queue = queue
            self.block = block
        }
    }
}

