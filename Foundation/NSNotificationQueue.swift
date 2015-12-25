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

    internal typealias NotificationQueueList = NSMutableArray
    internal typealias NSNotificationListEntry = (NSNotification, [String]) // Notification ans list of modes the notification may be posted in.
    internal typealias NSNotificationList = [NSNotificationListEntry] // The list of notifications to post

    internal let notificationCenter: NSNotificationCenter
    internal var asapList = NSNotificationList()
    internal var idleList = NSNotificationList()

    // The NSNotificationQueue instance is associated with current thread.
    // The _notificationQueueList represents a list of notification queues related to the current thread.
    private static var _notificationQueueList = NSThreadSpecific<NSMutableArray>()
    internal static var notificationQueueList: NotificationQueueList {
        return _notificationQueueList.get() {
            return NSMutableArray()
        }
    }

    // The default notification queue for the current thread.
    private static var _defaultQueue = NSThreadSpecific<NSNotificationQueue>()
    public class func defaultQueue() -> NSNotificationQueue {
        return _defaultQueue.get() {
            return NSNotificationQueue(notificationCenter: NSNotificationCenter.defaultCenter())
        }
    }
    
    public init(notificationCenter: NSNotificationCenter) {
        self.notificationCenter = notificationCenter
        super.init()
        NSNotificationQueue.registerQueue(self)
    }

    deinit {
        NSNotificationQueue.unregisterQueue(self)
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

    private static func registerQueue(notificationQueue: NSNotificationQueue) {
        self.notificationQueueList.addObject(notificationQueue)
    }

    private static func unregisterQueue(notificationQueue: NSNotificationQueue) {
        guard self.notificationQueueList.indexOfObject(notificationQueue) != NSNotFound else {
            return
        }
        self.notificationQueueList.removeObject(notificationQueue)
    }

}
