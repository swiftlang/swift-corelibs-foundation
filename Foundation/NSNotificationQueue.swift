// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public enum NSPostingStyle : UInt {
    
    case PostWhenIdle
    case PostASAP
    case PostNow
}

public struct NSNotificationCoalescing : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let CoalescingOnName = NSNotificationCoalescing(rawValue: 1 << 0)
    public static let CoalescingOnSender = NSNotificationCoalescing(rawValue: 1 << 1)
}

public class NSNotificationQueue : NSObject {

    private typealias NotificationQueueList = Array<NSNotificationQueue>
    private typealias NSNotificationListEntry = (NSNotification, [String])
    private typealias NSNotificationList = [NSNotificationListEntry]

    private static let _notificationQueueThreadKey = "NSNotificationQueueThreadKey"
    private static let _notificationListThreadKey = "NSNotificationListThreadKey"
    private let notificationCenter: NSNotificationCenter
    private var asapList = NSNotificationList()
    private var idleList = NSNotificationList()
    private var notificationQueueList: NotificationQueueList {
        get {
            let currentThread = NSThread.currentThread()
            let lKey = NSNotificationQueue._notificationListThreadKey

            if let list = currentThread.threadDictionary[lKey] as? NotificationQueueList {
                return list
            }

            let list = NotificationQueueList()
            currentThread.threadDictionary[lKey] = NSArray(array: list)
            return list
        }
        set {
            let currentThread = NSThread.currentThread()
            let lKey = NSNotificationQueue._notificationListThreadKey

            currentThread.threadDictionary[lKey] = NSArray(array: newValue)
        }
    }

    public class func defaultQueue() -> NSNotificationQueue {
        let currentThread = NSThread.currentThread()
        let qKey = NSNotificationQueue._notificationListThreadKey

        if let defaultQueue = currentThread.threadDictionary[qKey] as? NSNotificationQueue {
            return defaultQueue
        }

        let defaultQueue = NSNotificationQueue(notificationCenter: NSNotificationCenter.defaultCenter())
        currentThread.threadDictionary[qKey] = defaultQueue
        return defaultQueue
    }
    
    public init(notificationCenter: NSNotificationCenter) {
        self.notificationCenter = notificationCenter
        super.init()
        self.registerQueue()
    }

    deinit {
        self.unregisterQueue()
    }

    public func enqueueNotification(notification: NSNotification, postingStyle: NSPostingStyle) {
        enqueueNotification(notification, postingStyle: postingStyle, coalesceMask: [.CoalescingOnName, .CoalescingOnSender], forModes: nil)
    }

    public func enqueueNotification(notification: NSNotification, postingStyle: NSPostingStyle, coalesceMask: NSNotificationCoalescing, forModes modes: [String]?) {
        var runloopModes = [NSDefaultRunLoopMode]
        if let modes = modes  {
            runloopModes = modes
        }

        if !coalesceMask.isEmpty {
            self.dequeueNotificationsMatching(notification, coalesceMask: coalesceMask)
        }

        switch postingStyle {
        case .PostNow:
            let currentMode = NSRunLoop.currentRunLoop().currentMode
            if currentMode == nil || runloopModes.contains(currentMode!) {
                self.notificationCenter.postNotification(notification)
            }
        case .PostASAP:
            self.asapList.append((notification, runloopModes))
            NSUnimplemented() // post at the end of the current notification callout or timer
        case .PostWhenIdle:
            self.idleList.append((notification, runloopModes))
            NSUnimplemented() // wait until the runloop is idle, then post the notification
        }
    }
    
    public func dequeueNotificationsMatching(notification: NSNotification, coalesceMask: NSNotificationCoalescing) {
        var predicate: (NSNotificationListEntry) -> Bool
        switch coalesceMask {
        case [.CoalescingOnName, .CoalescingOnSender]:
            predicate = { (entryNotification, _) in
                return notification.object === entryNotification.object && notification.name == entryNotification.name
            }
        case [.CoalescingOnName]:
            predicate = { (entryNotification, _) in
                return notification.name == entryNotification.name
            }
        case [.CoalescingOnSender]:
            predicate = { (entryNotification, _) in
                return notification.object === entryNotification.object
            }
        default:
            return
        }

        self.asapList = self.asapList.filter(predicate)
        self.idleList = self.idleList.filter(predicate)
    }

    // MARK: Private

    private func registerQueue() {
        var notificationQueueList = self.notificationQueueList
        notificationQueueList.append(self)
        self.notificationQueueList = notificationQueueList
    }

    private func unregisterQueue() {
        guard let idx = self.notificationQueueList.indexOf(self) else {
            return
        }

        var notificationQueueList = self.notificationQueueList
        notificationQueueList.removeAtIndex(idx)
        self.notificationQueueList = notificationQueueList
    }

}
