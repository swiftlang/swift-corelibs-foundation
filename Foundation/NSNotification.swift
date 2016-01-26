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
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            guard let name = aDecoder.decodeObjectOfClass(NSString.self, forKey:"NS.name") else {
                return nil
            }
            let object = aDecoder.decodeObjectForKey("NS.object")
            let userInfo = aDecoder.decodeObjectOfClass(NSDictionary.self, forKey: "NS.userinfo")
            self.init(name: name.bridge(), object: object, userInfo: userInfo?.bridge())
        } else {
            guard let name = aDecoder.decodeObject() as? NSString else {
                return nil
            }
            let object = aDecoder.decodeObject()
            let userInfo = aDecoder.decodeObject() as? NSDictionary
            self.init(name: name.bridge(), object: object, userInfo: userInfo?.bridge())
        }
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encodeObject(self.name.bridge(), forKey:"NS.name")
            aCoder.encodeObject(self.object, forKey:"NS.object")
            aCoder.encodeObject(self.userInfo?.bridge(), forKey:"NS.userinfo")
        } else {
            aCoder.encodeObject(self.name.bridge())
            aCoder.encodeObject(self.object)
            aCoder.encodeObject(self.userInfo?.bridge())
        }
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public override var description: String {
        var str = "\(self.dynamicType) \(unsafeAddressOf(self)) {"
        
        str += "name = \(self.name)"
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

extension SequenceType where Generator.Element : NSNotificationReceiver {

    /// Returns collection of `NSNotificationReceiver`.
    ///
    /// Will return:
    ///  - elements that property `object` is not equal to `observerToFilter`
    ///  - elements that property `name` is not equal to parameter `name` if specified.
    ///  - elements that property `sender` is not equal to parameter `object` if specified.
    ///
    private func filterOutObserver(observerToFilter: AnyObject, name:String? = nil, object: AnyObject? = nil) -> [Generator.Element] {
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
    private func observersMatchingName(name:String? = nil, sender: AnyObject? = nil) -> [Generator.Element] {
        return self.filter { observer in

            let emptyName = observer.name == nil
            let sameName = observer.name == name
            let emptySender = observer.sender == nil
            let sameSender = observer.sender === sender

            return (emptySender || sameSender) && (emptyName || sameName)
        }
    }
}

private let _defaultCenter: NSNotificationCenter = NSNotificationCenter()

public class NSNotificationCenter : NSObject {
    
    private var _observers: [NSNotificationReceiver]
    private let _observersLock = NSLock()
    
    public required override init() {
        _observers = [NSNotificationReceiver]()
    }
    
    public class func defaultCenter() -> NSNotificationCenter {
        return _defaultCenter
    }
    
    public func postNotification(notification: NSNotification) {

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

    public func removeObserver(observer: AnyObject, name: String?, object: AnyObject?) {
        guard let observer = observer as? NSObject else {
            return
        }

        _observersLock.synchronized({
            self._observers = _observers.filterOutObserver(observer, name: name, object: object)
        })
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

        _observersLock.synchronized({
            _observers.append(newObserver)
        })
        
        return object
    }

}
