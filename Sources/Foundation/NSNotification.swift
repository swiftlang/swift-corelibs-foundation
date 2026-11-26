// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_spi(SwiftCorelibsFoundation) import FoundationEssentials

@available(*, unavailable)
extension NSNotification : @unchecked Sendable { }

open class NSNotification: NSObject, NSCopying, NSCoding {
    public typealias Name = Notification.Name

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

#if canImport(Dispatch)

extension NotificationCenter {
    @available(*, unavailable, renamed: "addObserver(forName:object:queue:using:)")
    public func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, usingBlock block: @escaping (Notification) -> Void) -> NSObjectProtocol {
        fatalError()
    }

    public func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @Sendable @escaping (Notification) -> Void) -> NSObjectProtocol {
        if let queue = queue {
            return _NSNotificationObserverToken(observer: _addBlockObserver(name?.rawValue, object: Self._observedObject(obj)) { [weak queue] (notification: Notification) in
                if let queue = queue {
                    if queue != OperationQueue.current {
                        // Not entirely safe, but maintained for compatibility
                        nonisolated(unsafe) let notification = notification
                        queue.addOperation { block(notification) }
                        queue.waitUntilAllOperationsAreFinished()
                    } else {
                        block(notification)
                    }
                }
            })
        } else {
            return _NSNotificationObserverToken(observer: _addBlockObserver(name?.rawValue, object: Self._observedObject(obj), using: block))
        }
    }
    
    public func removeObserver(_ observer: Any) {
        removeObserver(observer, name: nil, object: nil)
    }
    
    public func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object: Any?) {
        guard let observer = observer as? _NSNotificationObserverToken else { return }
        _removeObserver(observer.observer, name: aName?.rawValue, object: Self._observedObject(object))
    }
    
    public func post(_ notification: Notification) {
        _post(notification)
    }
    
    public func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable : Any]? = nil) {
        post(Notification(name: aName, object: anObject, userInfo: aUserInfo))
    }
    
    fileprivate static func _observedObject(_ object: Any?) -> AnyObject? {
        object.map { $0 as AnyObject }
    }
}

extension NotificationCenter {
    // Provides NSObjectProtocol conformance for addObserver()
    final class _NSNotificationObserverToken: NSObject {
        internal let observer: AnyObject
        
        init(observer: AnyObject) {
            self.observer = observer
        }
    }
}

#endif // canImport(Dispatch)
