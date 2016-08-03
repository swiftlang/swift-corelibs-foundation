// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

extension NSNotification {
    public struct Name : RawRepresentable, Equatable, Hashable, Comparable {
        public private(set) var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public var hashValue: Int {
            return self.rawValue.hashValue
        }
    }
}

public func ==(lhs: NSNotification.Name, rhs: NSNotification.Name) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public func <(lhs: NSNotification.Name, rhs: NSNotification.Name) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

open class NSNotification: NSObject, NSCopying, NSCoding {
    private(set) open var name: Name
    
    private(set) open var object: AnyObject?
    
    private(set) open var userInfo: [String : Any]?
    
    public convenience override init() {
        /* do not invoke; not a valid initializer for this class */
        fatalError()
    }
    
    public init(name: Name, object: AnyObject?, userInfo: [String : Any]?) {
        self.name = name
        self.object = object
        self.userInfo = userInfo
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            guard let name = aDecoder.decodeObjectOfClass(NSString.self, forKey:"NS.name") else {
                return nil
            }
            let object = aDecoder.decodeObject(forKey: "NS.object")
//            let userInfo = aDecoder.decodeObjectOfClass(NSDictionary.self, forKey: "NS.userinfo")
            self.init(name: Name(rawValue: name.bridge()), object: object, userInfo: nil)
        } else {
            guard let name = aDecoder.decodeObject() as? NSString else {
                return nil
            }
            let object = aDecoder.decodeObject()
//            let userInfo = aDecoder.decodeObject() as? NSDictionary
            self.init(name: Name(rawValue: name.bridge()), object: object, userInfo: nil)
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encode(self.name.rawValue.bridge(), forKey:"NS.name")
            aCoder.encode(self.object, forKey:"NS.object")
//            aCoder.encodeObject(self.userInfo?.bridge(), forKey:"NS.userinfo")
        } else {
            aCoder.encode(self.name.rawValue.bridge())
            aCoder.encode(self.object)
//            aCoder.encodeObject(self.userInfo?.bridge())
        }
    }
    
    open override func copy() -> AnyObject {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> AnyObject {
        return self
    }
    
    open override var description: String {
        var str = "\(type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()) {"
        
        str += "name = \(self.name.rawValue)"
        if let object = self.object {
            str += "; object = \(object)"
        }
        if let userInfo = self.userInfo {
            str += "; userInfo = \(userInfo)"
        }
        str += "}"
        
        return str
    }
}

extension NSNotification {
    public convenience init(name aName: Name, object anObject: AnyObject?) {
        self.init(name: aName, object: anObject, userInfo: nil)
    }
}

private class NSNotificationReceiver : NSObject {
    fileprivate weak var object: NSObject?
    fileprivate var name: Notification.Name?
    fileprivate var block: ((Notification) -> Void)?
    fileprivate var sender: AnyObject?
}

extension Sequence where Iterator.Element : NSNotificationReceiver {

    /// Returns collection of `NSNotificationReceiver`.
    ///
    /// Will return:
    ///  - elements that property `object` is not equal to `observerToFilter`
    ///  - elements that property `name` is not equal to parameter `name` if specified.
    ///  - elements that property `sender` is not equal to parameter `object` if specified.
    ///
    fileprivate func filterOutObserver(_ observerToFilter: AnyObject, name:Notification.Name? = nil, object: AnyObject? = nil) -> [Iterator.Element] {
        return self.filter { observer in

            let differentObserver = observer.object !== observerToFilter
            let nameSpecified = name != nil
            let differentName = observer.name != name
            let objectSpecified = object != nil
            let differentSender = observer.sender !== object

            return differentObserver || (nameSpecified  && differentName) || (objectSpecified && differentSender)
        }
    }

    /// Returns collection of `NSNotificationReceiver`.
    ///
    /// Will return:
    ///  - elements that property `sender` is `nil` or equals specified parameter `sender`.
    ///  - elements that property `name` is `nil` or equals specified parameter `name`.
    ///
    fileprivate func observersMatchingName(_ name:Notification.Name? = nil, sender: AnyObject? = nil) -> [Iterator.Element] {
        return self.filter { observer in

            let emptyName = observer.name == nil
            let sameName = observer.name == name
            let emptySender = observer.sender == nil
            let sameSender = observer.sender === sender

            return (emptySender || sameSender) && (emptyName || sameName)
        }
    }
}

private let _defaultCenter: NotificationCenter = NotificationCenter()

open class NotificationCenter: NSObject {
    
    private var _observers: [NSNotificationReceiver]
    private let _observersLock = Lock()
    
    public required override init() {
        _observers = [NSNotificationReceiver]()
    }
    
    open class func defaultCenter() -> NotificationCenter {
        return _defaultCenter
    }
    
    open func postNotification(_ notification: Notification) {

        let sendTo = _observersLock.synchronized({
            return _observers.observersMatchingName(notification.name, sender: notification.object)
        })

        for observer in sendTo {
            guard let block = observer.block else {
                continue
            }
            
            block(notification)
        }
    }

    open func postNotificationName(_ aName: Notification.Name, object anObject: AnyObject?) {
        let notification = Notification(name: aName, object: anObject)
        postNotification(notification)
    }

    open func postNotificationName(_ aName: Notification.Name, object anObject: AnyObject?, userInfo aUserInfo: [String : Any]?) {
        let notification = Notification(name: aName, object: anObject, userInfo: aUserInfo)
        postNotification(notification)
    }

    open func removeObserver(_ observer: AnyObject) {
        removeObserver(observer, name: nil, object: nil)
    }

    open func removeObserver(_ observer: AnyObject, name: Notification.Name?, object: AnyObject?) {
        guard let observer = observer as? NSObject else {
            return
        }

        _observersLock.synchronized({
            self._observers = _observers.filterOutObserver(observer, name: name, object: object)
        })
    }
    
    open func addObserverForName(_ name: Notification.Name?, object obj: AnyObject?, queue: OperationQueue?, usingBlock block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        if queue != nil {
            NSUnimplemented()
        }

        let object = NSObject()
        
        let newObserver = NSNotificationReceiver()
        newObserver.object = object
        newObserver.name = name
        newObserver.block = block
        newObserver.sender = obj

        _observersLock.synchronized({
            _observers.append(newObserver)
        })
        
        return object
    }

}
