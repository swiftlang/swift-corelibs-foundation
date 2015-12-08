// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public class NSNotification : NSObject, NSCopying, NSCoding {
    
    public let name: String
    public let object: AnyObject?
    public let userInfo: [NSObject : AnyObject]?
    
    public convenience override init() {
        /* do not invoke; not a valid initializer for this class */
        fatalError()
    }
    
    public init(name: String, object: AnyObject?, userInfo: [NSObject : AnyObject]?) {
        self.name = name
        self.object = object
        self.userInfo = userInfo
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard let name = aDecoder.decodeObjectForKey("name") as? String else { return nil }
        self.name = name
        self.object = aDecoder.decodeObjectForKey("object")
        self.userInfo = aDecoder.decodeObjectForKey("userInfo") as? [NSObject: AnyObject]
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        if let object = self.object {
            aCoder.encodeObject(object, forKey: "object")
        }
        aCoder.encodeObject(name, forKey: "name")
        if let userInfo = self.userInfo {
            aCoder.encodeObject(userInfo, forKey: "userInfo")
        }
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return NSNotification(name: self.name, object: self.object, userInfo: self.userInfo)
    }
}

extension NSNotification {
    public convenience init(name aName: String, object anObject: AnyObject?) {
        self.init(name: aName, object: anObject, userInfo: nil)
    }
}

public class NSNotificationCenter : NSObject {
    
    public class func defaultCenter() -> NSNotificationCenter {
        NSUnimplemented()
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
        NSUnimplemented()
    }

}

