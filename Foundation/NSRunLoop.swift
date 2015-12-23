// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public let NSDefaultRunLoopMode: String = "kCFRunLoopDefaultMode"
public let NSRunLoopCommonModes: String = "kCFRunLoopCommonModes"

internal func _NSRunLoopNew(cf: CFRunLoopRef) -> Unmanaged<AnyObject> {
    let rl = Unmanaged<NSRunLoop>.passRetained(NSRunLoop(cfObject: cf))
    return unsafeBitCast(rl, Unmanaged<AnyObject>.self) // this retain is balanced on the other side of the CF fence
}

public class NSRunLoop : NSObject {
    internal var _cfRunLoop : CFRunLoopRef!
    
    internal init(cfObject : CFRunLoopRef) {
        _cfRunLoop = cfObject
    }
    
    public class func currentRunLoop() -> NSRunLoop {
        return _CFRunLoopGet2(CFRunLoopGetCurrent()) as! NSRunLoop
    }
    
    public class func mainRunLoop() -> NSRunLoop {
        return _CFRunLoopGet2(CFRunLoopGetMain()) as! NSRunLoop
    }
    
    public var currentMode: String? {
        return CFRunLoopCopyCurrentMode(_cfRunLoop)?._swiftObject
    }
    
    public func addTimer(timer: NSTimer, forMode mode: String) {
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer._cfObject, mode._cfObject)
    }
    
    public func addPort(aPort: NSPort, forMode mode: String) {
        NSUnimplemented()
    }

    public func removePort(aPort: NSPort, forMode mode: String) {
        NSUnimplemented()
    }
    
    public func limitDateForMode(mode: String) -> NSDate? {
        let nextTimerFireAbsoluteTime = CFRunLoopGetNextTimerFireDate(CFRunLoopGetCurrent(), mode._cfObject)
        
        if (nextTimerFireAbsoluteTime == 0) {
            return NSDate.distantFuture()
        }
        
        return NSDate(timeIntervalSinceReferenceDate: nextTimerFireAbsoluteTime)
    }

    public func acceptInputForMode(mode: String, beforeDate limitDate: NSDate) {
        NSUnimplemented()
    }

}

extension NSRunLoop {
    
    public func run() {
        runUntilDate(NSDate.distantFuture());
    }

    public func runUntilDate(limitDate: NSDate) {
        runMode(NSDefaultRunLoopMode, beforeDate: limitDate)
    }

    public func runMode(mode: String, beforeDate limitDate: NSDate) -> Bool {
        let runloopResult = CFRunLoopRunInMode(mode._cfObject, limitDate.timeIntervalSinceNow, false)
#if os(Linux)
        return runloopResult == Int32(kCFRunLoopRunHandledSource) || runloopResult == Int32(kCFRunLoopRunTimedOut)
#else
        return runloopResult == .HandledSource || runloopResult == .TimedOut
#endif
    }

}

