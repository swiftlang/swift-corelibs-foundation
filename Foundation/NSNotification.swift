// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public class NSNotification : NSObject, NSCopying, NSCoding {
    private(set) public var name: String
    
    private(set) public var object: AnyObject?
    
    private(set) public var userInfo: [NSObject : AnyObject]?
    
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
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
}

extension NSNotification {
    public convenience init(name aName: String, object anObject: AnyObject?) {
        self.init(name: aName, object: anObject, userInfo: nil)
    }
}


private class NSNotificationReceiver : NSObject {
    private weak var object: NSObject?
    private var name: String?
    private var block: ((NSNotification) -> Void)?
    private var sender: AnyObject?
}


private let _defaultCenter: NSNotificationCenter = NSNotificationCenter()

public class NSNotificationCenter : NSObject {
    
    private var observers: [NSNotificationReceiver]
    
    public required override init() {
        observers = [NSNotificationReceiver]()
    }
    
    public class func defaultCenter() -> NSNotificationCenter {
        return _defaultCenter
    }
    
    public func postNotification(notification: NSNotification) {
        let name = notification.name
        let sender = notification.object
        
        let sendTo = observers.filter { observer in
            let sameName = (observer.name == nil || observer.name == name)
            let sameSender = (observer.sender == nil || observer.sender === sender)
            
            return sameSender && sameName
        }
        
        for observer in sendTo {
            guard let block = observer.block else {
                continue
            }
            
            block(notification)
        }
    }

    public func postNotificationName(aName: String, object anObject: AnyObject?) {
        let notification = NSNotification(name: aName, object: anObject)
        postNotification(notification)
    }

    public func postNotificationName(aName: String, object anObject: AnyObject?, userInfo aUserInfo: [NSObject : AnyObject]?) {
        let notification = NSNotification(name: aName, object: anObject, userInfo: aUserInfo)
        postNotification(notification)
    }

    public func removeObserver(observer: AnyObject) {
        removeObserver(observer, name: nil, object: nil)
    }

    public func removeObserver(observer: AnyObject, name aName: String?, object anObject: AnyObject?) {
        guard let observer = observer as? NSObject else {
            return
        }
        
        observers = observers.filter { curObserver in
            return (curObserver.object !== observer)
                || (aName != nil && curObserver.name != aName)
                || (anObject != nil && curObserver.sender !== anObject)
        }
    }

    
    public func addObserverForName(name: String?, object obj: AnyObject?, queue: NSOperationQueue?, usingBlock block: (NSNotification) -> Void) -> NSObjectProtocol {
        if queue != nil {
            NSUnimplemented()
        }

        let object = NSObject()
        
        let newObserver = NSNotificationReceiver()
        newObserver.object = object
        newObserver.name = name
        newObserver.block = block
        newObserver.sender = obj
        
        observers.append(newObserver)
        
        return object
    }

}
