// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if os(macOS) || os(iOS)
import Darwin
#elseif os(Linux) || CYGWIN
import Glibc
#endif

import CoreFoundation

public protocol NSLocking {
    func lock()
    func unlock()
}

#if CYGWIN
private typealias _PthreadMutexPointer = UnsafeMutablePointer<pthread_mutex_t?>
private typealias _PthreadCondPointer = UnsafeMutablePointer<pthread_cond_t?>
#else
private typealias _PthreadMutexPointer = UnsafeMutablePointer<pthread_mutex_t>
private typealias _PthreadCondPointer = UnsafeMutablePointer<pthread_cond_t>
#endif

open class NSLock: NSObject, NSLocking {
    internal var mutex = _PthreadMutexPointer.allocate(capacity: 1)
#if os(macOS) || os(iOS)
    private var timeoutCond = _PthreadCondPointer.allocate(capacity: 1)
    private var timeoutMutex = _PthreadMutexPointer.allocate(capacity: 1)
#endif

    public override init() {
        pthread_mutex_init(mutex, nil)
#if os(macOS) || os(iOS)
        pthread_cond_init(timeoutCond, nil)
        pthread_mutex_init(timeoutMutex, nil)
#endif
    }
    
    deinit {
        pthread_mutex_destroy(mutex)
        mutex.deinitialize(count: 1)
        mutex.deallocate()
#if os(macOS) || os(iOS)
        deallocateTimedLockData(cond: timeoutCond, mutex: timeoutMutex)
#endif
    }
    
    open func lock() {
        pthread_mutex_lock(mutex)
    }

    open func unlock() {
        pthread_mutex_unlock(mutex)
#if os(macOS) || os(iOS)
        // Wakeup any threads waiting in lock(before:)
        pthread_mutex_lock(timeoutMutex)
        pthread_cond_broadcast(timeoutCond)
        pthread_mutex_unlock(timeoutMutex)
#endif
    }

    open func `try`() -> Bool {
        return pthread_mutex_trylock(mutex) == 0
    }
    
    open func lock(before limit: Date) -> Bool {
        if pthread_mutex_trylock(mutex) == 0 {
            return true
        }

#if os(macOS) || os(iOS)
        return timedLock(mutex: mutex, endTime: limit, using: timeoutCond, with: timeoutMutex)
#else
        guard var endTime = timeSpecFrom(date: limit) else {
            return false
        }
        return pthread_mutex_timedlock(mutex, &endTime) == 0
#endif
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
    internal var mutex = _PthreadMutexPointer.allocate(capacity: 1)
#if os(macOS) || os(iOS)
    private var timeoutCond = _PthreadCondPointer.allocate(capacity: 1)
    private var timeoutMutex = _PthreadMutexPointer.allocate(capacity: 1)
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
        mutex.deinitialize(count: 1)
        mutex.deallocate()
#if os(macOS) || os(iOS)
        deallocateTimedLockData(cond: timeoutCond, mutex: timeoutMutex)
#endif
    }
    
    open func lock() {
        pthread_mutex_lock(mutex)
    }
    
    open func unlock() {
        pthread_mutex_unlock(mutex)
#if os(macOS) || os(iOS)
        // Wakeup any threads waiting in lock(before:)
        pthread_mutex_lock(timeoutMutex)
        pthread_cond_broadcast(timeoutCond)
        pthread_mutex_unlock(timeoutMutex)
#endif
    }
    
    open func `try`() -> Bool {
        return pthread_mutex_trylock(mutex) == 0
    }
    
    open func lock(before limit: Date) -> Bool {
        if pthread_mutex_trylock(mutex) == 0 {
            return true
        }

#if os(macOS) || os(iOS)
        return timedLock(mutex: mutex, endTime: limit, using: timeoutCond, with: timeoutMutex)
#else
        guard var endTime = timeSpecFrom(date: limit) else {
            return false
        }
        return pthread_mutex_timedlock(mutex, &endTime) == 0
#endif
    }

    open var name: String?
}

open class NSCondition: NSObject, NSLocking {
    internal var mutex = _PthreadMutexPointer.allocate(capacity: 1)
    internal var cond = _PthreadCondPointer.allocate(capacity: 1)

    public override init() {
        pthread_mutex_init(mutex, nil)
        pthread_cond_init(cond, nil)
    }
    
    deinit {
        pthread_mutex_destroy(mutex)
        pthread_cond_destroy(cond)
        mutex.deinitialize(count: 1)
        cond.deinitialize(count: 1)
        mutex.deallocate()
        cond.deallocate()
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
        guard var timeout = timeSpecFrom(date: limit) else {
            return false
        }
        return pthread_cond_timedwait(cond, mutex, &timeout) == 0
    }
    
    open func signal() {
        pthread_cond_signal(cond)
    }
    
    open func broadcast() {
        pthread_cond_broadcast(cond)
    }
    
    open var name: String?
}

private func timeSpecFrom(date: Date) -> timespec? {
    guard date.timeIntervalSinceNow > 0 else {
        return nil
    }
    let nsecPerSec: Int64 = 1_000_000_000
    let interval = date.timeIntervalSince1970
    let intervalNS = Int64(interval * Double(nsecPerSec))

    return timespec(tv_sec: Int(intervalNS / nsecPerSec),
                    tv_nsec: Int(intervalNS % nsecPerSec))
}

#if os(macOS) || os(iOS)

private func deallocateTimedLockData(cond: _PthreadCondPointer, mutex: _PthreadMutexPointer) {
    pthread_cond_destroy(cond)
    cond.deinitialize(count: 1)
    cond.deallocate()

    pthread_mutex_destroy(mutex)
    mutex.deinitialize(count: 1)
    mutex.deallocate()
}

// Emulate pthread_mutex_timedlock using pthread_cond_timedwait.
// lock(before:) passes a condition variable/mutex pair to use.
// unlock() will use pthread_cond_broadcast() to wake any waits in progress.
private func timedLock(mutex: _PthreadMutexPointer, endTime: Date,
                       using timeoutCond: _PthreadCondPointer,
                       with timeoutMutex: _PthreadMutexPointer) -> Bool {

    var timeSpec = timeSpecFrom(date: endTime)
    while var ts = timeSpec {
        let lockval = pthread_mutex_lock(timeoutMutex)
        precondition(lockval == 0)
        let waitval = pthread_cond_timedwait(timeoutCond, timeoutMutex, &ts)
        precondition(waitval == 0 || waitval == ETIMEDOUT)
        let unlockval = pthread_mutex_unlock(timeoutMutex)
        precondition(unlockval == 0)

        if waitval == ETIMEDOUT {
            return false
        }
        let tryval = pthread_mutex_trylock(mutex)
        precondition(tryval == 0 || tryval == EBUSY)
        if tryval == 0 { // The lock was obtained.
            return true
        }
        // pthread_cond_timedwait didnt timeout so wait some more.
        timeSpec = timeSpecFrom(date: endTime)
    }
    return false
}
#endif
