// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

open class NSNotification: NSObject, NSCopying, NSCoding {
    public struct Name : RawRepresentable, Equatable, Hashable {
        public private(set) var rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    private(set) open var name: Name
    
    private(set) open var object: Any?
    
    private(set) open var userInfo: [AnyHashable : Any]?
    
    public convenience override init() {
        /* do not invoke; not a valid initializer for this class */
        fatalError()
    }
    
    public init(name: Name, object: Any?, userInfo: [AnyHashable : Any]? = nil) {
        self.name = name
        self.object = object
        self.userInfo = userInfo
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        guard let name = aDecoder.decodeObject(of: NSString.self, forKey:"NS.name") else {
            return nil
        }
        let object = aDecoder.decodeObject(forKey: "NS.object")
        //            let userInfo = aDecoder.decodeObject(of: NSDictionary.self, forKey: "NS.userinfo")
        self.init(name: Name(rawValue: String._unconditionallyBridgeFromObjectiveC(name)), object: object as! NSObject, userInfo: nil)
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.name.rawValue._bridgeToObjectiveC(), forKey:"NS.name")
        aCoder.encode(self.object, forKey:"NS.object")
        aCoder.encode(self.userInfo?._bridgeToObjectiveC(), forKey:"NS.userinfo")
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
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

private class NSNotificationReceiver : NSObject {
    fileprivate var name: Notification.Name?
    fileprivate var block: ((Notification) -> Void)?
    fileprivate var sender: AnyObject?
    fileprivate var queue: OperationQueue?
}

private let _defaultCenter: NotificationCenter = NotificationCenter()

open class NotificationCenter: NSObject {
    private lazy var _nilIdentifier: ObjectIdentifier = ObjectIdentifier(_observersLock)
    private lazy var _nilHashable: AnyHashable = AnyHashable(_nilIdentifier)
    
    private var _observers: [AnyHashable /* Notification.Name */ : [ObjectIdentifier /* object */ : [ObjectIdentifier /* notification receiver */ : NSNotificationReceiver]]]
    private let _observersLock = NSLock()
    
    public required override init() {
        _observers = [AnyHashable: [ObjectIdentifier: [ObjectIdentifier: NSNotificationReceiver]]]()
    }
    
    open class var `default`: NotificationCenter {
        return _defaultCenter
    }
    
    open func post(_ notification: Notification) {
        let notificationNameIdentifier: AnyHashable = AnyHashable(notification.name)
        let senderIdentifier: ObjectIdentifier? = notification.object.map({ ObjectIdentifier(__SwiftValue.store($0)) })
        

        let sendTo: [Dictionary<ObjectIdentifier, NSNotificationReceiver>.Values] = _observersLock.synchronized({
            var retVal = [Dictionary<ObjectIdentifier, NSNotificationReceiver>.Values]()
            (_observers[_nilHashable]?[_nilIdentifier]?.values).map({ retVal.append($0) })
            senderIdentifier.flatMap({ _observers[_nilHashable]?[$0]?.values }).map({ retVal.append($0) })
            (_observers[notificationNameIdentifier]?[_nilIdentifier]?.values).map({ retVal.append($0) })
            senderIdentifier.flatMap({ _observers[notificationNameIdentifier]?[$0]?.values}).map({ retVal.append($0) })
            
            return retVal
        })

        sendTo.forEach { observers in
            observers.forEach { observer in
                guard let block = observer.block else {
                    return
                }
                
                if let queue = observer.queue, queue != OperationQueue.current {
                    queue.addOperation { block(notification) }
                    queue.waitUntilAllOperationsAreFinished()
                } else {
                    block(notification)
                }
            }
        }
    }

    open func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable : Any]? = nil) {
        let notification = Notification(name: aName, object: anObject, userInfo: aUserInfo)
        post(notification)
    }

    open func removeObserver(_ observer: Any) {
        removeObserver(observer, name: nil, object: nil)
    }

    open func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object: Any?) {
        guard let observer = observer as? NSNotificationReceiver,
            // These 2 parameters would only be useful for removing notifications added by `addObserver:selector:name:object:`
            aName == nil || observer.name == aName,
            object == nil || observer.sender === __SwiftValue.store(object)
        else {
            return
        }

        let notificationNameIdentifier: AnyHashable = observer.name.map { AnyHashable($0) } ?? _nilHashable
        let senderIdentifier: ObjectIdentifier = observer.sender.map { ObjectIdentifier($0) } ?? _nilIdentifier
        let receiverIdentifier: ObjectIdentifier = ObjectIdentifier(observer)
        
        _observersLock.synchronized({
            _observers[notificationNameIdentifier]?[senderIdentifier]?.removeValue(forKey: receiverIdentifier)
            if _observers[notificationNameIdentifier]?[senderIdentifier]?.count == 0 {
                _observers[notificationNameIdentifier]?.removeValue(forKey: senderIdentifier)
            }
        })
    }

    @available(*, unavailable, renamed: "addObserver(forName:object:queue:using:)")
    open func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, usingBlock block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        return addObserver(forName: name, object: obj, queue: queue, using: block)
    }

    open func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        let newObserver = NSNotificationReceiver()
        newObserver.name = name
        newObserver.block = block
        newObserver.sender = __SwiftValue.store(obj)
        newObserver.queue = queue
        
        let notificationNameIdentifier: AnyHashable = name.map({ AnyHashable($0) }) ?? _nilHashable
        let senderIdentifier: ObjectIdentifier = newObserver.sender.map({ ObjectIdentifier($0) }) ?? _nilIdentifier
        let receiverIdentifier: ObjectIdentifier = ObjectIdentifier(newObserver)

        _observersLock.synchronized({
            _observers[notificationNameIdentifier, default: [:]][senderIdentifier, default: [:]][receiverIdentifier] = newObserver
        })
        
        return newObserver
    }

}
