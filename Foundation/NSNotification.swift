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
    private weak var sender: AnyObject?
    private weak var queue: NSOperationQueue?
}


private let _defaultCenter: NSNotificationCenter = NSNotificationCenter()

public class NSNotificationCenter : NSObject {
    
    private var _observers = [NSNotificationReceiver]()
    private let _observersLock = NSLock()
    
    public class func defaultCenter() -> NSNotificationCenter {
        return _defaultCenter
    }
    
    private func synchronized<T>(lock: NSLock, closure: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return closure()
    }
    
    public func postNotification(notification: NSNotification) {

        let name = notification.name
        let sender = notification.object

        let sendTo = synchronized(_observersLock) {
            return self._observers.filter { observer in
                let sameName = (observer.name == nil || observer.name == name)
                let sameSender = (observer.sender == nil || observer.sender === sender)
            
                return sameSender && sameName
            }
        }
        
        for observer in sendTo {
            guard let block = observer.block else {
                continue
            }
            
            if let queue = observer.queue where queue != NSOperationQueue.currentQueue() {
                
                let operation = NSBlockOperation {
                    block(notification)
                }
                
                queue.addOperation(operation)
                operation.waitUntilFinished()
            } else {
                block(notification)
            }
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
        
        guard let observerToRemove = observer as? NSObject else {
            return
        }
        
        _observersLock.lock()
        defer { _observersLock.unlock() }
        
        _observers = _observers.filter { observer in
            return (observer.object !== observerToRemove)
                || (aName != nil && observer.name != aName)
                || (anObject != nil && observer.sender !== anObject)
        }
    }
    
    public func addObserverForName(name: String?, object obj: AnyObject?, queue: NSOperationQueue?, usingBlock block: (NSNotification) -> Void) -> NSObjectProtocol {

        let object = NSObject()
        
        let newObserver = NSNotificationReceiver()
        newObserver.object = object
        newObserver.name = name
        newObserver.block = block
        newObserver.sender = obj
        newObserver.queue = queue
        
        _observersLock.lock()
        _observers.append(newObserver)
        _observersLock.unlock()
        
        return object
    }

}
