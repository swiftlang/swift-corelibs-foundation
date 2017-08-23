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

public protocol NSLocking {
    func lock()
    func unlock()
}

open class NSLock: NSObject, NSLocking {
#if CYGWIN
    internal var mutex = UnsafeMutablePointer<pthread_mutex_t?>.allocate(capacity: 1)
#else
    internal var mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
#endif
    
    public override init() {
        pthread_mutex_init(mutex, nil)
    }
    
    deinit {
        pthread_mutex_destroy(mutex)
        mutex.deinitialize()
        mutex.deallocate(capacity: 1)
    }
    
    open func lock() {
        pthread_mutex_lock(mutex)
    }
    
    open func unlock() {
        pthread_mutex_unlock(mutex)
    }
    
    open func `try`() -> Bool {
        return pthread_mutex_trylock(mutex) == 0
    }
    
    open func lock(before limit: Date) {
        NSUnimplemented()
    }
    
    open var name: String?
}

extension NSLock {
    internal func synchronized<T>(_ closure: () -> T) -> T {
        self.lock()
        defer { self.unlock() }
        return closure()
    }
}

open class NSConditionLock : NSObject, NSLocking {
    internal var _cond = NSCondition()
    internal var _value: Int
    internal var _thread: pthread_t?
    
    public convenience override init() {
        self.init(condition: 0)
    }
    
    public init(condition: Int) {
        _value = condition
    }

    open func lock() {
        let _ = lock(before: Date.distantFuture)
    }

    open func unlock() {
        _cond.lock()
        _thread = nil
        _cond.broadcast()
        _cond.unlock()
    }
    
    open var condition: Int {
        return _value
    }

    open func lock(whenCondition condition: Int) {
        let _ = lock(whenCondition: condition, before: Date.distantFuture)
    }

    open func `try`() -> Bool {
        return lock(before: Date.distantPast)
    }
    
    open func tryLock(whenCondition condition: Int) -> Bool {
        return lock(whenCondition: condition, before: Date.distantPast)
    }

    open func unlock(withCondition condition: Int) {
        _cond.lock()
        _thread = nil
        _value = condition
        _cond.broadcast()
        _cond.unlock()
    }

    open func lock(before limit: Date) -> Bool {
        _cond.lock()
        while _thread != nil {
            if !_cond.wait(until: limit) {
                _cond.unlock()
                return false
            }
        }
        _thread = pthread_self()
        _cond.unlock()
        return true
    }
    
    open func lock(whenCondition condition: Int, before limit: Date) -> Bool {
        _cond.lock()
        while _thread != nil || _value != condition {
            if !_cond.wait(until: limit) {
                _cond.unlock()
                return false
            }
        }
        _thread = pthread_self()
        _cond.unlock()
        return true
    }
    
    open var name: String?
}

open class NSRecursiveLock: NSObject, NSLocking {
#if CYGWIN
    internal var mutex = UnsafeMutablePointer<pthread_mutex_t?>.allocate(capacity: 1)
#else
    internal var mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
#endif
    
    public override init() {
        super.init()
#if CYGWIN
        var attrib : pthread_mutexattr_t? = nil
#else
        var attrib = pthread_mutexattr_t()
#endif
        withUnsafeMutablePointer(to: &attrib) { attrs in
            pthread_mutexattr_settype(attrs, Int32(PTHREAD_MUTEX_RECURSIVE))
            pthread_mutex_init(mutex, attrs)
        }
    }
    
    deinit {
        pthread_mutex_destroy(mutex)
        mutex.deinitialize()
        mutex.deallocate(capacity: 1)
    }
    
    open func lock() {
        pthread_mutex_lock(mutex)
    }
    
    open func unlock() {
        pthread_mutex_unlock(mutex)
    }
    
    open func `try`() -> Bool {
        return pthread_mutex_trylock(mutex) == 0
    }
    
    open func lock(before limit: Date) {
        NSUnimplemented()
    }

    open var name: String?
}

open class NSCondition: NSObject, NSLocking {
#if CYGWIN
    internal var mutex = UnsafeMutablePointer<pthread_mutex_t?>.allocate(capacity: 1)
    internal var cond = UnsafeMutablePointer<pthread_cond_t?>.allocate(capacity: 1)
#else
    internal var mutex = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    internal var cond = UnsafeMutablePointer<pthread_cond_t>.allocate(capacity: 1)
#endif
    
    public override init() {
        pthread_mutex_init(mutex, nil)
        pthread_cond_init(cond, nil)
    }
    
    deinit {
        pthread_mutex_destroy(mutex)
        pthread_cond_destroy(cond)
        mutex.deinitialize()
        cond.deinitialize()
        mutex.deallocate(capacity: 1)
        cond.deallocate(capacity: 1)
    }
    
    open func lock() {
        pthread_mutex_lock(mutex)
    }
    
    open func unlock() {
        pthread_mutex_unlock(mutex)
    }
    
    open func wait() {
        pthread_cond_wait(cond, mutex)
    }
    
    open func wait(until limit: Date) -> Bool {
        let lim = limit.timeIntervalSinceReferenceDate
        let ti = lim - CFAbsoluteTimeGetCurrent()
        if ti < 0.0 {
            return false
        }
        var ts = timespec()
        ts.tv_sec = Int(floor(ti))
        ts.tv_nsec = Int((ti - Double(ts.tv_sec)) * 1_000_000_000.0)
        var tv = timeval()
        withUnsafeMutablePointer(to: &tv) { t in
            gettimeofday(t, nil)
            ts.tv_sec += t.pointee.tv_sec
            ts.tv_nsec += Int(t.pointee.tv_usec) * 1000
            if ts.tv_nsec >= 1_000_000_000 {
                ts.tv_sec += ts.tv_nsec / 1_000_000_000
                ts.tv_nsec = ts.tv_nsec % 1_000_000_000
            }
        }
        let retVal: Int32 = withUnsafePointer(to: &ts) { t in
            return pthread_cond_timedwait(cond, mutex, t)
        }

        return retVal == 0
    }
    
    open func signal() {
        pthread_cond_signal(cond)
    }
    
    open func broadcast() {
        pthread_cond_broadcast(cond)
    }
    
    open var name: String?
}
