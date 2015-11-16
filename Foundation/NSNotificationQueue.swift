
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
    
    public class func defaultQueue() -> NSNotificationQueue {
        NSUnimplemented()
    }
    
    public init(notificationCenter: NSNotificationCenter) {
        NSUnimplemented()
    }
    
    public func enqueueNotification(notification: NSNotification, postingStyle: NSPostingStyle) {
        NSUnimplemented()
    }

    public func enqueueNotification(notification: NSNotification, postingStyle: NSPostingStyle, coalesceMask: NSNotificationCoalescing, forModes modes: [String]?) {
        NSUnimplemented()
    }
    
    public func dequeueNotificationsMatching(notification: NSNotification, coalesceMask: Int) {
        NSUnimplemented()
    }

}

