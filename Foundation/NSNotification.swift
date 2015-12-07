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
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
}

extension NSNotification {
    public convenience init(name aName: String, object anObject: AnyObject?) {
        self.init(name: aName, object: anObject, userInfo: nil)
    }
}


private class NSNotificationReceiver : NSObject {
    private weak var object: NSObject?
    private var block: ((NSNotification) -> Void)?
    private var sender: AnyObject?
    private var valid: Bool = false
}


private var _defaultCenter: NSNotificationCenter = NSNotificationCenter()

public class NSNotificationCenter : NSObject {
    
    private var observers: Dictionary<String, [NSNotificationReceiver]>
    
    public required override init() {
        observers = [String: [NSNotificationReceiver]]()
    }
    
    public class func defaultCenter() -> NSNotificationCenter {
        return _defaultCenter
    }
    
    public func postNotification(notification: NSNotification) {
        let name = notification.name
        guard let observers = observers[name] else {
            return
        }
        
        var sendTo = [NSNotificationReceiver]()
        let sender = notification.object
        
        for observer in observers where observer.valid {
            if observer.sender != nil && observer.sender !== sender {
                continue
            }
            
            sendTo.append(observer)
        }
        
        for observer in sendTo where observer.valid {
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
        for (name, _) in observers {
            removeObserver(observer, name: name, object: nil)
        }
    }

    public func removeObserver(observer: AnyObject, name aName: String?, object anObject: AnyObject?) {
        guard let name = aName, observers = observers[name] else {
            return
        }
        guard let observer = observer as? NSObject else {
            return
        }
        
        for curObserver in observers where curObserver.valid {
            if curObserver.object !== observer {
                continue
            }
            
            if anObject != nil && curObserver.sender !== anObject {
                continue
            }
            
            curObserver.valid = false
        }
        
        let validObservers = observers.filter { $0.valid }
        
        if validObservers.count == 0 {
            self.observers.removeValueForKey(name)
        } else {
            self.observers[name] = validObservers
        }
    }

    
    public func addObserverForName(name: String?, object obj: AnyObject?, queue: NSOperationQueue?, usingBlock block: (NSNotification) -> Void) -> NSObjectProtocol {
        if queue != nil {
            NSUnimplemented()
        }

        guard let name = name else {
            NSUnimplemented()
        }

        let object = NSObject()
        
        let newObserver = NSNotificationReceiver()
        newObserver.object = object
        newObserver.block = block
        newObserver.sender = obj
        newObserver.valid = true
        
        var observersForName = observers[name] ?? [NSNotificationReceiver]()
        observersForName.append(newObserver)
        
        observers[name] = observersForName
        
        return object
    }

}

