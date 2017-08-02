// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

internal func __NSFireTimer(_ timer: CFRunLoopTimer?, info: UnsafeMutableRawPointer?) -> Void {
    let t: Timer = NSObject.unretainedReference(info!)
    t._fire(t)
}

open class Timer : NSObject {
    typealias CFType = CFRunLoopTimer
    
    internal var _cfObject: CFType {
        get {
            return _timer!
        }
        set {
            _timer = newValue
        }
    }
    
    internal var _timer: CFRunLoopTimer? // has to be optional because this is a chicken/egg problem with initialization in swift
    internal var _fire: (Timer) -> Void = { (_: Timer) in }
    
    /// Alternative API for timer creation with a block.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative to creation via selector
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    /// - Warning: Capturing the timer or the owner of the timer inside of the block may cause retain cycles. Use with caution
    public init(fire date: Date, interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Swift.Void) {
        super.init()
        _fire = block
        var context = CFRunLoopTimerContext()
        withRetainedReference {
            (refPtr: UnsafeMutablePointer<UInt8>) in
            context.info = UnsafeMutableRawPointer(refPtr)
        }
        let timer = withUnsafeMutablePointer(to: &context) { (ctx: UnsafeMutablePointer<CFRunLoopTimerContext>) -> CFRunLoopTimer in
            var t = interval
            if !repeats {
                t = 0.0
            }
            return CFRunLoopTimerCreate(kCFAllocatorSystemDefault, date.timeIntervalSinceReferenceDate, t, 0, 0, __NSFireTimer, ctx)
        }
        _timer = timer
    }
    
    // !!! The interface as exposed by Darwin marks init(fire date: Date, interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Swift.Void) with "convenience", but this constructor without.
    // !!! That doesn't make sense as init(fire date: Date, ...) is more general than this constructor, which can be implemented in terms of init(fire date: Date, ...).
    // !!! The convenience here has been switched around and deliberately does not match what is exposed by Darwin Foundation.
    /// Creates and returns a new Timer object initialized with the specified block object.
    /// - parameter timeInterval: The number of seconds between firings of the timer. If seconds is less than or equal to 0.0, this method chooses the nonnegative value of 0.1 milliseconds instead
    /// - parameter repeats: If YES, the timer will repeatedly reschedule itself until invalidated. If NO, the timer will be invalidated after it fires.
    /// - parameter block: The execution body of the timer; the timer itself is passed as the parameter to this block when executed to aid in avoiding cyclical references
    public convenience init(timeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Swift.Void) {
        self.init(fire: Date(), interval: interval, repeats: repeats, block: block)
    }
    
    /// Alternative API for timer creation with a block.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative to creation via selector
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    /// - Warning: Capturing the timer or the owner of the timer inside of the block may cause retain cycles. Use with caution
    open class func scheduledTimer(withTimeInterval interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        let timer = Timer(fire: Date(timeIntervalSinceNow: interval), interval: interval, repeats: repeats, block: block)
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer._timer!, kCFRunLoopDefaultMode)
        return timer
    }
    
    open func fire() {
        if !isValid {
            return
        }
        _fire(self)
        if timeInterval == 0.0 {
            invalidate()
        }
    }

    open var fireDate: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: CFRunLoopTimerGetNextFireDate(_timer!))
        }
        set {
            CFRunLoopTimerSetNextFireDate(_timer!, newValue.timeIntervalSinceReferenceDate)
        }
    }
    
    open var timeInterval: TimeInterval {
        return CFRunLoopTimerGetInterval(_timer!)
    }

    open var tolerance: TimeInterval {
        get {
            return CFRunLoopTimerGetTolerance(_timer!)
        }
        set {
            CFRunLoopTimerSetTolerance(_timer!, newValue)
        }
    }
    
    open func invalidate() {
        CFRunLoopTimerInvalidate(_timer!)
    }

    open var isValid: Bool {
        return CFRunLoopTimerIsValid(_timer!)
    }
    
    // Timer's userInfo is meant to be read-only. The initializers that are exposed on Swift, however, do not take a custom userInfo, so it can never be set.
    // The default value should then be nil, and this is left as subclassable for potential consumers.
    open var userInfo: Any? {
        return nil
    }
}
