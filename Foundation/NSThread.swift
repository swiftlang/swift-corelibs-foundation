// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if os(OSX) || os(iOS)
import Darwin
#elseif os(Linux) || CYGWIN
import Glibc
#endif

import CoreFoundation

// for some reason having this take a generic causes a crash...
private func _compiler_crash_fix(_ key: _CFThreadSpecificKey, _ value: AnyObject?) {
    _CThreadSpecificSet(key, value)
}

internal class NSThreadSpecific<T: NSObject> {
    private var key = _CFThreadSpecificKeyCreate()
    
    internal func get(_ generator: (Void) -> T) -> T {
        if let specific = _CFThreadSpecificGet(key) {
            return specific as! T
        } else {
            let value = generator()
            _compiler_crash_fix(key, value)
            return value
        }
    }
    
    internal func set(_ value: T) {
        _compiler_crash_fix(key, value)
    }
}

internal enum _NSThreadStatus {
    case initialized
    case starting
    case executing
    case finished
}

private func NSThreadStart(_ context: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    let thread: Thread = NSObject.unretainedReference(context!)
    Thread._currentThread.set(thread)
    thread._status = .executing
    thread.main()
    thread._status = .finished
    Thread.releaseReference(context!)
    return nil
}

open class Thread : NSObject {
    
    static internal var _currentThread = NSThreadSpecific<Thread>()
    open class var current: Thread {
        return Thread._currentThread.get() {
            return Thread(thread: pthread_self())
        }
    }
    
    open class var isMainThread: Bool { NSUnimplemented() }
    
    // !!! NSThread's mainThread property is incorrectly exported as "main", which conflicts with its "main" method.
    open class var mainThread: Thread { NSUnimplemented() }

    /// Alternative API for detached thread creation
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative to creation via selector
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open class func detachNewThread(_ block: @escaping () -> Swift.Void) {
        let t = Thread(block: block)
        t.start()
    }
    
    open class func isMultiThreaded() -> Bool {
        return true
    }
    
    open class func sleep(until date: Date) {
        let start_ut = CFGetSystemUptime()
        let start_at = CFAbsoluteTimeGetCurrent()
        let end_at = date.timeIntervalSinceReferenceDate
        var ti = end_at - start_at
        let end_ut = start_ut + ti
        while (0.0 < ti) {
            var __ts__ = timespec(tv_sec: Int.max, tv_nsec: 0)
            if ti < Double(Int.max) {
                var integ = 0.0
                let frac: Double = withUnsafeMutablePointer(to: &integ) { integp in
                    return modf(ti, integp)
                }
                __ts__.tv_sec = Int(integ)
                __ts__.tv_nsec = Int(frac * 1000000000.0)
            }
            let _ = withUnsafePointer(to: &__ts__) { ts in
                nanosleep(ts, nil)
            }
            ti = end_ut - CFGetSystemUptime()
        }
    }

    open class func sleep(forTimeInterval interval: TimeInterval) {
        var ti = interval
        let start_ut = CFGetSystemUptime()
        let end_ut = start_ut + ti
        while 0.0 < ti {
            var __ts__ = timespec(tv_sec: Int.max, tv_nsec: 0)
            if ti < Double(Int.max) {
                var integ = 0.0
                let frac: Double = withUnsafeMutablePointer(to: &integ) { integp in
                    return modf(ti, integp)
                }
                __ts__.tv_sec = Int(integ)
                __ts__.tv_nsec = Int(frac * 1000000000.0)
            }
            let _ = withUnsafePointer(to: &__ts__) { ts in
                nanosleep(ts, nil)
            }
            ti = end_ut - CFGetSystemUptime()
        }
    }

    open class func exit() {
        pthread_exit(nil)
    }
    
    internal var _main: (Void) -> Void = {}
#if os(OSX) || os(iOS) || CYGWIN
    private var _thread: pthread_t? = nil
#elseif os(Linux) || os(Android)
    private var _thread = pthread_t()
#endif
#if CYGWIN
    internal var _attr : pthread_attr_t? = nil
#else
    internal var _attr = pthread_attr_t()
#endif
    internal var _status = _NSThreadStatus.initialized
    internal var _cancelled = false
    /// - Note: this differs from the Darwin implementation in that the keys must be Strings
    open var threadDictionary = [String : Any]()
    
    internal init(thread: pthread_t) {
        // Note: even on Darwin this is a non-optional pthread_t; this is only used for valid threads, which are never null pointers.
        _thread = thread
    }
    
    public override init() {
        let _ = withUnsafeMutablePointer(to: &_attr) { attr in
            pthread_attr_init(attr)
            pthread_attr_setscope(attr, Int32(PTHREAD_SCOPE_SYSTEM))
            pthread_attr_setdetachstate(attr, Int32(PTHREAD_CREATE_DETACHED))
        }
    }
    
    public convenience init(block: @escaping () -> Swift.Void) {
        self.init()
        _main = block
    }

    open func start() {
        precondition(_status == .initialized, "attempting to start a thread that has already been started")
        _status = .starting
        if _cancelled {
            _status = .finished
            return
        }
#if CYGWIN
        if let attr = self._attr {
            _thread = self.withRetainedReference {
              return _CFThreadCreate(attr, NSThreadStart, $0)
            }
        } else {
            _thread = nil
        }
#else
        _thread = self.withRetainedReference {
            return _CFThreadCreate(self._attr, NSThreadStart, $0)
        }
#endif
    }
    
    open func main() {
        _main()
    }
    
    open var name: String? {
        didSet {
            if _thread == Thread.current._thread {
                _CFThreadSetName(name)
            }
        }
    }

    open var stackSize: Int {
        get {
            var size: Int = 0
            return withUnsafeMutablePointer(to: &_attr) { attr in
                withUnsafeMutablePointer(to: &size) { sz in
                    pthread_attr_getstacksize(attr, sz)
                    return sz.pointee
                }
            }
        }
        set {
            // just don't allow a stack size more than 1GB on any platform
            var s = newValue
            if (1 << 30) < s {
                s = 1 << 30
            }
            let _ = withUnsafeMutablePointer(to: &_attr) { attr in
                pthread_attr_setstacksize(attr, s)
            }
        }
    }

    open var isExecuting: Bool {
        return _status == .executing
    }

    open var isFinished: Bool {
        return _status == .finished
    }
    
    open var isCancelled: Bool {
        return _cancelled
    }
    
    open var isMainThread: Bool {
        NSUnimplemented()
    }
    
    open func cancel() {
        _cancelled = true
    }

    open class var callStackReturnAddresses: [NSNumber] {
        NSUnimplemented()
    }
    
    open class var callStackSymbols: [String] {
        NSUnimplemented()
    }
}

extension NSNotification.Name {
    public static let NSWillBecomeMultiThreaded = NSNotification.Name(rawValue: "NSWillBecomeMultiThreadedNotification")
    public static let NSDidBecomeSingleThreaded = NSNotification.Name(rawValue: "NSDidBecomeSingleThreadedNotification")
    public static let NSThreadWillExit = NSNotification.Name(rawValue: "NSThreadWillExitNotification")
}
