// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

// WORKAROUND_SR9811
#if os(Windows)
internal typealias _swift_CFThreadRef = HANDLE
#else
internal typealias _swift_CFThreadRef = pthread_t
#endif

internal class NSThreadSpecific<T: NSObject> {
    private var key = _CFThreadSpecificKeyCreate()

    internal func get(_ generator: () -> T) -> T {
        if let specific = _CFThreadSpecificGet(key) {
            return specific as! T
        } else {
            let value = generator()
            _CFThreadSpecificSet(key, value)
            return value
        }
    }
    
    internal var current: T? {
        return _CFThreadSpecificGet(key) as? T
    }

    internal func set(_ value: T) {
        _CFThreadSpecificSet(key, value)
    }
    
    internal func clear() {
        _CFThreadSpecificSet(key, nil)
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
    if let name = thread.name {
#if os(Windows)
        _CFThreadSetName(GetCurrentThread(), name)
#else
        _CFThreadSetName(pthread_self(), name)
#endif
    }
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
            if Thread.isMainThread {
                return mainThread
            } else {
#if os(Windows)
                return Thread(thread: GetCurrentThread())
#else
                return Thread(thread: pthread_self())
#endif
            }
        }
    }

    open class var isMainThread: Bool {
        return _CFIsMainThread()
    }

    // !!! NSThread's mainThread property is incorrectly exported as "main", which conflicts with its "main" method.
    private static let _mainThread: Thread = {
        var thread = Thread(thread: _CFMainPThread)
        thread._status = .executing
        return thread
    }()

    open class var mainThread: Thread {
        return _mainThread
    }


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
#if os(Windows)
        var hTimer: HANDLE = CreateWaitableTimerW(nil, true, nil)
        if hTimer == HANDLE(bitPattern: 0) { fatalError("unable to create timer: \(GetLastError())") }
        defer { CloseHandle(hTimer) }

        // the timeout is in 100ns units
        var liTimeout: LARGE_INTEGER =
            LARGE_INTEGER(QuadPart: LONGLONG(date.timeIntervalSinceNow * -10_000_000))
        if !SetWaitableTimer(hTimer, &liTimeout, 0, nil, nil, false) {
          return
        }
        WaitForSingleObject(hTimer, WinSDK.INFINITE)
#else
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
#endif
    }

    open class func sleep(forTimeInterval interval: TimeInterval) {
#if os(Windows)
        var hTimer: HANDLE = CreateWaitableTimerW(nil, true, nil)
        // FIXME(compnerd) how to check that hTimer is not NULL?
        defer { CloseHandle(hTimer) }

        // the timeout is in 100ns units
        var liTimeout: LARGE_INTEGER =
            LARGE_INTEGER(QuadPart: LONGLONG(interval * -10_000_000))
        if !SetWaitableTimer(hTimer, &liTimeout, 0, nil, nil, false) {
          return
        }
        WaitForSingleObject(hTimer, WinSDK.INFINITE)
#else
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
#endif
    }

    open class func exit() {
        Thread.current._status = .finished
#if os(Windows)
        ExitThread(0)
#else
        pthread_exit(nil)
#endif
    }

    internal var _main: () -> Void = {}
    private var _thread: _swift_CFThreadRef? = nil

#if os(Windows) && !CYGWIN
    internal var _attr: _CFThreadAttributes =
        _CFThreadAttributes(dwSizeOfAttributes: DWORD(MemoryLayout<_CFThreadAttributes>.size),
                            dwThreadStackReservation: 0)
#elseif CYGWIN
    internal var _attr : pthread_attr_t? = nil
#else
    internal var _attr = pthread_attr_t()
#endif
    internal var _status = _NSThreadStatus.initialized
    internal var _cancelled = false

    /// - Note: This property is available on all platforms, but on some it may have no effect.
    open var qualityOfService: QualityOfService = .default

    open private(set) var threadDictionary: NSMutableDictionary = NSMutableDictionary()

    internal init(thread: _swift_CFThreadRef) {
        // Note: even on Darwin this is a non-optional _CFThreadRef; this is only used for valid threads, which are never null pointers.
        _thread = thread
    }

    public override init() {
#if !os(Windows)
        let _ = withUnsafeMutablePointer(to: &_attr) { attr in
            pthread_attr_init(attr)
            pthread_attr_setscope(attr, Int32(PTHREAD_SCOPE_SYSTEM))
            pthread_attr_setdetachstate(attr, Int32(PTHREAD_CREATE_DETACHED))
        }
#endif
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
        get {
            return _name
        }
        set {
            if let thread = _thread {
                _CFThreadSetName(thread, newValue ?? "" )
            }
        }
    }

    internal var _name: String? {
      var buf: [Int8] = Array<Int8>(repeating: 0, count: 128)
      #if DEPLOYMENT_RUNTIME_OBJC
        // Do not use _CF functions on the ObjC runtime as that breaks on the
        // Darwin runtime.
        if pthread_getname_np(pthread_self(), &buf, buf.count) == 0 {
          return ""
        }
      #else
        if _CFThreadGetName(&buf, Int32(buf.count)) == 0 {
          return ""
        }
      #endif
        return String(cString: buf)
    }

#if os(Windows)
    open var stackSize: Int {
      get {
        var ulLowLimit: ULONG_PTR = 0
        var ulHighLimit: ULONG_PTR = 0
        GetCurrentThreadStackLimits(&ulLowLimit, &ulHighLimit)
        return Int(ulLowLimit)
      }
      set {
        _attr.dwThreadStackReservation = DWORD(newValue)
      }
    }
#else
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
#endif

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
        return self === Thread.mainThread
    }

    open func cancel() {
        _cancelled = true
    }


    private class func backtraceAddresses<T>(_ body: (UnsafeMutablePointer<UnsafeMutableRawPointer?>, Int) -> [T]) -> [T] {
        // Same as swift/stdlib/public/runtime/Errors.cpp backtrace
        let maxSupportedStackDepth = 128;
        let addrs = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: maxSupportedStackDepth)
        defer { addrs.deallocate() }
#if os(Android)
        let count = 0
#elseif os(Windows)
        let count = RtlCaptureStackBackTrace(0, DWORD(maxSupportedStackDepth),
                                             addrs, nil)
#else
        let count = backtrace(addrs, Int32(maxSupportedStackDepth))
#endif
        let addressCount = max(0, min(Int(count), maxSupportedStackDepth))
        return body(addrs, addressCount)
    }

    open class var callStackReturnAddresses: [NSNumber] {
        return backtraceAddresses({ (addrs, count) in
            UnsafeBufferPointer(start: addrs, count: count).map {
                NSNumber(value: UInt(bitPattern: $0))
            }
        })
    }

    open class var callStackSymbols: [String] {
#if os(Android)
        return []
#elseif os(Windows)
        let hProcess: HANDLE = GetCurrentProcess()
        SymSetOptions(DWORD(SYMOPT_UNDNAME | SYMOPT_DEFERRED_LOADS))
        if !SymInitializeW(hProcess, nil, true) {
          return []
        }
        return backtraceAddresses { (addresses, count) in
          var symbols: [String] = []

          var buffer: UnsafeMutablePointer<Int8> =
              UnsafeMutablePointer<Int8>
                  .allocate(capacity: MemoryLayout<SYMBOL_INFO>.size + 128)
          defer { buffer.deallocate() }

          buffer.withMemoryRebound(to: SYMBOL_INFO.self, capacity: 1) {
            $0.pointee.SizeOfStruct = ULONG(MemoryLayout<SYMBOL_INFO>.size)
            $0.pointee.MaxNameLen = 128

            var address = addresses
            for _ in 1...count {
              var dwDisplacement: DWORD64 = 0
              if !SymFromAddr(hProcess, unsafeBitCast(address.pointee, to: DWORD64.self), &dwDisplacement, $0) {
                symbols.append("\($0.pointee)")
              } else {
                symbols.append(String(cString: &$0.pointee.Name))
              }
              address = address.successor()
            }
          }
          return symbols
        }
#else
        return backtraceAddresses({ (addrs, count) in
            var symbols: [String] = []
            if let bs = backtrace_symbols(addrs, Int32(count)) {
                symbols = UnsafeBufferPointer(start: bs, count: count).map {
                    guard let symbol = $0 else {
                        return "<null>"
                    }
                    return String(cString: symbol)
                }
                free(bs)
            }
            return symbols
        })
#endif
    }
}

extension NSNotification.Name {
    public static let NSWillBecomeMultiThreaded = NSNotification.Name(rawValue: "NSWillBecomeMultiThreadedNotification")
    public static let NSDidBecomeSingleThreaded = NSNotification.Name(rawValue: "NSDidBecomeSingleThreadedNotification")
    public static let NSThreadWillExit = NSNotification.Name(rawValue: "NSThreadWillExitNotification")
}
