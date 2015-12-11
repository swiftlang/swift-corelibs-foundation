// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public let NSDefaultRunLoopMode: String = kCFRunLoopDefaultMode._swiftObject
public let NSRunLoopCommonModes: String = kCFRunLoopCommonModes._swiftObject

public class NSRunLoop : NSObject {
    typealias CFType = CFRunLoopRef
    internal var _cfObject : CFType!
    internal static var _mainRunLoop : NSRunLoop = {
        return NSRunLoop(cfObject: CFRunLoopGetMain())
    }()
    
    internal init(cfObject : CFRunLoopRef) {
        _cfObject = cfObject
    }
    
    public class func currentRunLoop() -> NSRunLoop {
        return NSRunLoop(cfObject: CFRunLoopGetCurrent())
    }
    
    public class func mainRunLoop() -> NSRunLoop {
        return _mainRunLoop
    }
    
    public var currentMode: String? {
        return CFRunLoopCopyCurrentMode(_cfObject)?._swiftObject
    }
    
    public func addTimer(timer: NSTimer, forMode mode: String) {
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer._cfObject, mode._cfObject)
    }
    
    public func addPort(aPort: NSPort, forMode mode: String) {
//        CFRunLoopAddSource(CFRunLoopGetCurrent(), aPort._cfObject, mode._cfObject)
        NSUnimplemented()
    }

    public func removePort(aPort: NSPort, forMode mode: String) {
//        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), aPort._cfObject, mode._cfObject)
        NSUnimplemented()
    }
    
    public func limitDateForMode(mode: String) -> NSDate? {
        let nextTimerFireAbsoluteTime = CFRunLoopGetNextTimerFireDate(CFRunLoopGetCurrent(), mode._cfObject)
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
        let result: Int32 = CFRunLoopRunSpecific(_cfObject, mode._cfObject, limitDate.timeIntervalSinceNow, false)
        let runloopResult = CFRunLoopRunResult(rawValue: result)
        return runloopResult == .HandledSource || runloopResult == .TimedOut
    }

}

