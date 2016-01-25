// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

internal func __NSFireTimer(timer: CFRunLoopTimer!, info: UnsafeMutablePointer<Void>) -> Void {
    let t = Unmanaged<NSTimer>.fromOpaque(info).takeUnretainedValue()
    t._fire(t)
}

public class NSTimer : NSObject {
    typealias CFType = CFRunLoopTimerRef
    
    internal var _cfObject: CFType {
        get {
            return _timer!
        }
        set {
            _timer = newValue
        }
    }
    
    internal var _timer: CFRunLoopTimer? // has to be optional because this is a chicken/egg problem with initialization in swift
    internal var _fire: NSTimer -> Void = { (_: NSTimer) in }
    
    /// Alternative API for timer creation with a block.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative to creation via selector
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    /// - Warning: Capturing the timer or the owner of the timer inside of the block may cause retain cycles. Use with caution
    public init(fireDate: NSDate, interval: NSTimeInterval, repeats: Bool, fire: NSTimer -> Void ) {
        super.init()
        _fire = fire
        var context = CFRunLoopTimerContext()
        context.info = UnsafeMutablePointer<Void>(retained: self)
        let timer = withUnsafeMutablePointer(&context) { (ctx: UnsafeMutablePointer<CFRunLoopTimerContext>) -> CFRunLoopTimerRef in
            var t = interval
            if !repeats {
                t = 0.0
            }
            return CFRunLoopTimerCreate(kCFAllocatorSystemDefault, fireDate.timeIntervalSinceReferenceDate, t, 0, 0, __NSFireTimer, ctx)
        }
        _timer = timer
    }
    
    /// Alternative API for timer creation with a block.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative to creation via selector
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    /// - Warning: Capturing the timer or the owner of the timer inside of the block may cause retain cycles. Use with caution
    public class func scheduledTimer(ti: NSTimeInterval, repeats: Bool, fire: NSTimer -> Void) -> NSTimer {
        let timer = NSTimer(fireDate: NSDate(timeIntervalSinceNow: ti), interval: ti, repeats: repeats, fire: fire)
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer._timer!, kCFRunLoopDefaultMode)
        return timer
    }
    
    public func fire() {
        if !valid {
            return
        }
        _fire(self)
        if timeInterval == 0.0 {
            invalidate()
        }
    }

    public var fireDate: NSDate {
        get {
            return NSDate(timeIntervalSinceReferenceDate: CFRunLoopTimerGetNextFireDate(_timer!))
        }
        set {
            CFRunLoopTimerSetNextFireDate(_timer!, newValue.timeIntervalSinceReferenceDate)
        }
    }
    
    public var timeInterval: NSTimeInterval {
        return CFRunLoopTimerGetInterval(_timer!)
    }

    public var tolerance: NSTimeInterval {
        get {
            return CFRunLoopTimerGetTolerance(_timer!)
        }
        set {
            CFRunLoopTimerSetTolerance(_timer!, newValue)
        }
    }
    
    public func invalidate() {
        CFRunLoopTimerInvalidate(_timer!)
    }

    public var valid: Bool {
        return CFRunLoopTimerIsValid(_timer!)
    }
}
