// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(OSX) || os(iOS)
    internal let kCFRunLoopEntry = CFRunLoopActivity.entry.rawValue
    internal let kCFRunLoopBeforeTimers = CFRunLoopActivity.beforeTimers.rawValue
    internal let kCFRunLoopBeforeSources = CFRunLoopActivity.beforeSources.rawValue
    internal let kCFRunLoopBeforeWaiting = CFRunLoopActivity.beforeWaiting.rawValue
    internal let kCFRunLoopAfterWaiting = CFRunLoopActivity.afterWaiting.rawValue
    internal let kCFRunLoopExit = CFRunLoopActivity.exit.rawValue
    internal let kCFRunLoopAllActivities = CFRunLoopActivity.allActivities.rawValue
#endif

public let NSDefaultRunLoopMode: String = "kCFRunLoopDefaultMode"
public let NSRunLoopCommonModes: String = "kCFRunLoopCommonModes"

internal func _NSRunLoopNew(_ cf: CFRunLoop) -> Unmanaged<AnyObject> {
    let rl = Unmanaged<RunLoop>.passRetained(RunLoop(cfObject: cf))
    return unsafeBitCast(rl, to: Unmanaged<AnyObject>.self) // this retain is balanced on the other side of the CF fence
}

public class RunLoop: NSObject {
    internal var _cfRunLoop : CFRunLoop!
    internal static var _mainRunLoop : RunLoop = {
        return RunLoop(cfObject: CFRunLoopGetMain())
    }()

    internal init(cfObject : CFRunLoop) {
        _cfRunLoop = cfObject
    }

    public class func currentRunLoop() -> RunLoop {
        return _CFRunLoopGet2(CFRunLoopGetCurrent()) as! RunLoop
    }

    public class func mainRunLoop() -> RunLoop {
        return _CFRunLoopGet2(CFRunLoopGetMain()) as! RunLoop
    }

    public var currentMode: String? {
        return CFRunLoopCopyCurrentMode(_cfRunLoop)?._swiftObject
    }

    public func addTimer(_ timer: Timer, forMode mode: String) {
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer._cfObject, mode._cfObject)
    }

    public func addPort(_ aPort: NSPort, forMode mode: String) {
        NSUnimplemented()
    }

    public func removePort(_ aPort: NSPort, forMode mode: String) {
        NSUnimplemented()
    }

    public func limitDateForMode(_ mode: String) -> Date? {
        if _cfRunLoop !== CFRunLoopGetCurrent() {
            return nil
        }
        let modeArg = mode._cfObject
        
        CFRunLoopRunInMode(modeArg, -10.0, true) /* poll run loop to fire ready timers and performers, as used to be done here */
        if _CFRunLoopFinished(_cfRunLoop, modeArg) {
            return nil
        }
        
        let nextTimerFireAbsoluteTime = CFRunLoopGetNextTimerFireDate(CFRunLoopGetCurrent(), mode._cfObject)

        if (nextTimerFireAbsoluteTime == 0) {
            return Date.distantFuture
        }

        return Date(timeIntervalSinceReferenceDate: nextTimerFireAbsoluteTime)
    }

    public func acceptInputForMode(_ mode: String, beforeDate limitDate: Date) {
        if _cfRunLoop !== CFRunLoopGetCurrent() {
            return
        }
        CFRunLoopRunInMode(mode._cfObject, limitDate.timeIntervalSinceReferenceDate - CFAbsoluteTimeGetCurrent(), true)
    }

}

extension RunLoop {

    public func run() {
        while runMode(NSDefaultRunLoopMode, beforeDate: Date.distantFuture) { }
    }

    public func runUntilDate(_ limitDate: Date) {
        while runMode(NSDefaultRunLoopMode, beforeDate: limitDate) && limitDate.timeIntervalSinceReferenceDate > CFAbsoluteTimeGetCurrent() { }
    }

    public func runMode(_ mode: String, beforeDate limitDate: Date) -> Bool {
        if _cfRunLoop !== CFRunLoopGetCurrent() {
            return false
        }
        let modeArg = mode._cfObject
        if _CFRunLoopFinished(_cfRunLoop, modeArg) {
            return false
        }
        
        let limitTime = limitDate.timeIntervalSinceReferenceDate
        let ti = limitTime - CFAbsoluteTimeGetCurrent()
        CFRunLoopRunInMode(modeArg, ti, true)
        return true
    }

}
