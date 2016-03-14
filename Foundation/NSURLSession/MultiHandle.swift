// Foundation/NSURLSession/MultiHandle.swift - NSURLSession & libcurl
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// libcurl *multi handle* wrapper.
/// These are libcurl helpers for the NSURLSession API code.
/// - SeeAlso: https://curl.haxx.se/libcurl/c/
/// - SeeAlso: NSURLSession.swift
///
// -----------------------------------------------------------------------------

import CoreFoundation
import Dispatch



extension NSURLSession {
    /// Minimal wrapper around [curl multi interface](https://curl.haxx.se/libcurl/c/libcurl-multi.html).
    ///
    /// The the *multi handle* manages the sockets for easy handles
    /// (`NSURLSessionTask.EasyHandle`), and this implementation uses
    /// libdispatch to listen for sockets being read / write ready.
    ///
    /// Using `libdispatch_source_t` allows this implementation to be
    /// non-blocking and all code to run on the same thread /
    /// `dispatch_queue_t` -- thus keeping is simple.
    ///
    /// - SeeAlso: NSURLSessionTask.EasyHandle
    internal final class MultiHandle {
        let rawHandle = CFURLSessionMultiHandleInit()
        let queue = dispatch_queue_create("MultiHandle.isolation", DISPATCH_QUEUE_SERIAL)
        let group = dispatch_group_create()
        private var easyHandles: [NSURLSessionTask.EasyHandle] = []
        private var timeoutSource: TimeoutSource? = nil
        
        init(configuration: NSURLSession.Configuration, workQueue: dispatch_queue_t) {
            dispatch_set_target_queue(queue, workQueue)
            setupCallbacks()
            configure(with: configuration)
        }
        deinit {
            // C.f.: <https://curl.haxx.se/libcurl/c/curl_multi_cleanup.html>
            easyHandles.forEach {
                try! CFURLSessionMultiHandleRemoveHandle(rawHandle, $0.rawHandle).asError()
            }
            try! CFURLSessionMultiHandleDeinit(rawHandle).asError()
        }
    }
}
extension NSURLSession.MultiHandle {
    func configure(with configuration: NSURLSession.Configuration) {
        try! CFURLSession_multi_setopt_l(rawHandle, CFURLSessionMultiOptionMAX_HOST_CONNECTIONS, configuration.httpMaximumConnectionsPerHost).asError()
        try! CFURLSession_multi_setopt_l(rawHandle, CFURLSessionMultiOptionPIPELINING, configuration.httpShouldUsePipelining ? 3 : 2).asError()
        //TODO: We may want to set
        //    CFURLSessionMultiOptionMAXCONNECTS
        //    CFURLSessionMultiOptionMAX_TOTAL_CONNECTIONS
    }
}
private extension NSURLSession.MultiHandle {
    static func from(callbackUserData userdata: UnsafeMutablePointer<Void>?) -> NSURLSession.MultiHandle? {
        guard let userdata = userdata else { return nil }
        return Unmanaged<NSURLSession.MultiHandle>.fromOpaque(userdata).takeUnretainedValue()
    }
}
private extension NSURLSession.MultiHandle {
    /// Forward the libcurl callbacks into Swift methods
    func setupCallbacks() {
        // Socket
        try! CFURLSession_multi_setopt_ptr(rawHandle, CFURLSessionMultiOptionSOCKETDATA, UnsafeMutablePointer<Void>(unsafeAddress(of: self))).asError()
        try! CFURLSession_multi_setopt_sf(rawHandle, CFURLSessionMultiOptionSOCKETFUNCTION) { (easyHandle: CFURLSessionEasyHandle, socket: CFURLSession_socket_t, what: Int32, userdata: UnsafeMutablePointer<Void>?, socketptr: UnsafeMutablePointer<Void>?) -> Int32 in
            guard let handle = NSURLSession.MultiHandle.from(callbackUserData: userdata) else { fatalError() }
            return handle.register(socket: socket, for: easyHandle, what: what, socketSourcePtr: socketptr)
            }.asError()
        // Timeout:
        try! CFURLSession_multi_setopt_ptr(rawHandle, CFURLSessionMultiOptionTIMERDATA, UnsafeMutablePointer<Void>(unsafeAddress(of: self))).asError()
        try! CFURLSession_multi_setopt_tf(rawHandle, CFURLSessionMultiOptionTIMERFUNCTION) { (_, timeout: Int, userdata: UnsafeMutablePointer<Void>?) -> Int32 in
            guard let handle = NSURLSession.MultiHandle.from(callbackUserData: userdata) else { fatalError() }
            handle.updateTimeoutTimer(to: timeout)
            return 0
            }.asError()
    }
    /// <https://curl.haxx.se/libcurl/c/CURLMOPT_SOCKETFUNCTION.html> and
    /// <https://curl.haxx.se/libcurl/c/curl_multi_socket_action.html>
    func register(socket: CFURLSession_socket_t, for easyHandle: CFURLSessionEasyHandle, what: Int32, socketSourcePtr: UnsafeMutablePointer<Void>?) -> Int32 {
        // We get this callback whenever we need to register or unregister a
        // given socket with libdispatch.
        // The `action` / `what` defines if we should register or unregister
        // that we're interested in read and/or write readiness. We will do so
        // through libdispatch (dispatch_source_t) and store the source(s) inside
        // a `SocketSources` which we in turn store inside libcurl's multi handle
        // by means of curl_multi_assign() -- we retain the object fist.
        let action = SocketRegisterAction(rawValue: CFURLSessionPoll(value: what))
        var socketSources = SocketSources.from(socketSourcePtr: socketSourcePtr)
        if socketSources == nil && action.needsSource {
            let s = SocketSources()
            let p = OpaquePointer(bitPattern: Unmanaged.passRetained(s))
            CFURLSessionMultiHandleAssign(rawHandle, socket, UnsafeMutablePointer<Void>(p))
            socketSources = s
        } else if socketSources != nil && action == .unregister {
            // We need to release the stored pointer:
            if let opaque = socketSourcePtr {
                Unmanaged<SocketSources>.fromOpaque(opaque).release()
            }
            socketSources = nil
        }
        if let ss = socketSources {
            ss.createSources(with: action, fileDescriptor: Int(socket), queue: queue) { [weak self] in
                self?.performAction(for: socket)
            }
        }
        return 0
    }
    /// What read / write ready event to register / unregister.
    ///
    /// This re-maps `CFURLSessionPoll` / `CURL_POLL`.
    enum SocketRegisterAction {
        case none
        case registerRead
        case registerWrite
        case registerReadAndWrite
        case unregister
    }
}
internal extension NSURLSession.MultiHandle {
    /// Add an easy handle -- start its transfer.
    func add(_ handle: NSURLSessionTask.EasyHandle) {
        NSURLSession.printDebug("addHandle \(handle)")
        // If this is the first handle being added, we need to `kick` the
        // underlying multi handle by calling `timeoutTimerFired` as
        // described in
        // <https://curl.haxx.se/libcurl/c/curl_multi_socket_action.html>.
        // That will initiate the registration for timeout timer and socket
        // readiness.
        let needsTimeout = self.easyHandles.isEmpty
        self.easyHandles.append(handle)
        try! CFURLSessionMultiHandleAddHandle(self.rawHandle, handle.rawHandle).asError()
        if needsTimeout {
            self.timeoutTimerFired()
        }
    }
    /// Remove an easy handle -- stop its transfer.
    func remove(_ handle: NSURLSessionTask.EasyHandle) {
        NSURLSession.printDebug("removeHandle \(handle)")
        guard let idx = self.easyHandles.index(of: handle) else {
            fatalError("Handle not in list.")
        }
        self.easyHandles.remove(at: idx)
        try! CFURLSessionMultiHandleRemoveHandle(self.rawHandle, handle.rawHandle).asError()
    }
}
private extension NSURLSession.MultiHandle {
    /// This gets called when we should ask curl to perform action on a socket.
    func performAction(for socket: CFURLSession_socket_t) {
        try! readAndWriteAvailableData(on: socket)
    }
    /// This gets called when our timeout timer fires.
    ///
    /// libcurl relies on us calling curl_multi_socket_action() every now and then.
    func timeoutTimerFired() {
        try! readAndWriteAvailableData(on: CFURLSessionSocketTimeout)
    }
    /// reads/writes available data given an action
    func readAndWriteAvailableData(on socket: CFURLSession_socket_t) throws {
        var runningHandlesCount = Int32(0)
        try CFURLSessionMultiHandleAction(rawHandle, socket, 0, &runningHandlesCount).asError()
        //TODO: Do we remove the timeout timer here if / when runningHandles == 0 ?
        readMessages()
    }
    
    /// Check the status of all individual transfers.
    ///
    /// libcurl refers to this as “read multi stack informationals”.
    /// Check for transfers that completed.
    func readMessages() {
        // We pop the messages one by one in a loop:
        repeat {
            // count will contain the messages left in the queue
            var count = Int32(0)
            let info = CFURLSessionMultiHandleInfoRead(rawHandle, &count)
            guard let handle = info.easyHandle else { break }
            let code = info.resultCode
            completedTransfer(forEasyHandle: handle, easyCode: code)
        } while true
    }
    /// Transfer completed.
    func completedTransfer(forEasyHandle handle: CFURLSessionEasyHandle, easyCode: CFURLSessionEasyCode) {
        // Look up the matching wrapper:
        guard let idx = easyHandles.index(where: { $0.rawHandle == handle }) else {
            fatalError("Tansfer completed for easy handle, but it is not in the list of added handles.")
        }
        let easyHandle = easyHandles[idx]
        // Find the NSURLError code
        let errorCode = easyHandle.URLErrorCode(for: easyCode)
        completedTransfer(forEasyHandle: easyHandle, errorCode: errorCode)
    }
    /// Transfer completed.
    func completedTransfer(forEasyHandle handle: NSURLSessionTask.EasyHandle, errorCode: Int?) {
        handle.completedTransfer(withErrorCode: errorCode)
    }
}

private extension NSURLSessionTask.EasyHandle {
    /// An error code within the `NSURLErrorDomain` based on the error of the
    /// easy handle.
    /// - Note: The error value is set only on failure. You can't use it to
    ///   determine *if* something failed or not, only *why* it failed.
    func URLErrorCode(for easyCode: CFURLSessionEasyCode) -> Int? {
        switch (easyCode, connectFailureErrno) {
        case (CFURLSessionEasyCodeOK, _):
            return nil
        case (_, ECONNREFUSED):
            return NSURLErrorCannotConnectToHost
        case (CFURLSessionEasyCodeUNSUPPORTED_PROTOCOL, _):
            return NSURLErrorUnsupportedURL
        case (CFURLSessionEasyCodeURL_MALFORMAT, _):
            return NSURLErrorBadURL
        case (CFURLSessionEasyCodeCOULDNT_RESOLVE_HOST, _):
            // Oddly, this appears to happen for malformed URLs, too.
            return NSURLErrorCannotFindHost
        case (CFURLSessionEasyCodeRECV_ERROR, ECONNRESET):
            return NSURLErrorNetworkConnectionLost
        case (CFURLSessionEasyCodeSEND_ERROR, ECONNRESET):
            return NSURLErrorNetworkConnectionLost
        case (CFURLSessionEasyCodeGOT_NOTHING, _):
            return NSURLErrorBadServerResponse
        case (CFURLSessionEasyCodeABORTED_BY_CALLBACK, _):
            return NSURLErrorUnknown // Or NSURLErrorCancelled if we're in such a state
        default:
            //TODO: Need to map to one of the NSURLError... constants
            NSUnimplemented()
        }
    }
}

private extension NSURLSession.MultiHandle.SocketRegisterAction {
    init(rawValue: CFURLSessionPoll) {
        switch rawValue {
        case CFURLSessionPollNone:
            self = .none
        case CFURLSessionPollIn:
            self = .registerRead
        case CFURLSessionPollOut:
            self = .registerWrite
        case CFURLSessionPollInOut:
            self = .registerReadAndWrite
        case CFURLSessionPollRemove:
            self = .unregister
        default:
            fatalError("Invalid CFURLSessionPoll value.")
        }
    }
}
extension CFURLSessionPoll : Equatable {}
public func ==(lhs: CFURLSessionPoll, rhs: CFURLSessionPoll) -> Bool {
    return lhs.value == rhs.value
}
private extension NSURLSession.MultiHandle.SocketRegisterAction {
    /// Should a libdispatch source be registered for **read** readiness?
    var needsReadSource: Bool {
        switch self {
        case .none: return false
        case .registerRead: return true
        case .registerWrite: return false
        case .registerReadAndWrite: return true
        case .unregister: return false
        }
    }
    /// Should a libdispatch source be registered for **write** readiness?
    var needsWriteSource: Bool {
        switch self {
        case .none: return false
        case .registerRead: return false
        case .registerWrite: return true
        case .registerReadAndWrite: return true
        case .unregister: return false
        }
    }
    /// Should either a **read** or a **write** readiness libdispatch source be
    /// registered?
    var needsSource: Bool {
        return needsReadSource || needsWriteSource
    }
}

/// A helper class that wraps a libdispatch timer.
///
/// Used to implement the timeout of `NSURLSession.MultiHandle`.
private class TimeoutSource {
    let rawSource: dispatch_source_t
    let milliseconds: Int
    init(queue: dispatch_queue_t, milliseconds: Int, handler: () -> ()) {
        self.milliseconds = milliseconds
        self.rawSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
        
        let delay = UInt64(max(1, milliseconds - 1)) * NSEC_PER_MSEC
        let leeway: UInt64 = (milliseconds == 1) ? NSEC_PER_USEC : NSEC_PER_MSEC
        let start = dispatch_time(0, Int64(delay))
        
        dispatch_source_set_timer(rawSource, start, delay, leeway)
        dispatch_source_set_event_handler(rawSource, handler)
        dispatch_resume(rawSource)
    }
    deinit {
        dispatch_source_cancel(rawSource)
    }
}
private extension NSURLSession.MultiHandle {
    /// <https://curl.haxx.se/libcurl/c/CURLMOPT_TIMERFUNCTION.html>
    func updateTimeoutTimer(to value: Int) {
        updateTimeoutTimer(to: Timeout(timeout: value))
    }
    func updateTimeoutTimer(to timeout: Timeout) {
        // Set up a timeout timer based on the given value:
        switch timeout {
        case .none:
            timeoutSource = nil
        case .immediate:
            timeoutSource = nil
            timeoutTimerFired()
        case .milliseconds(let milliseconds):
            if (timeoutSource == nil) || timeoutSource!.milliseconds != milliseconds {
                //TODO: Could simply change the existing timer by calling
                // dispatch_source_set_timer() again.
                timeoutSource = TimeoutSource(queue: queue, milliseconds: milliseconds) { [weak self] in
                    self?.timeoutTimerFired()
                }
            }
        }
    }
    enum Timeout {
        case milliseconds(Int)
        case none
        case immediate
    }
}

private extension NSURLSession.MultiHandle.Timeout {
    init(timeout: Int) {
        switch timeout {
        case -1:
            self = .none
        case 0:
            self = .immediate
        default:
            self = .milliseconds(timeout)
        }
    }
}


/// Read and write libdispatch sources for a specific socket.
///
/// A simple helper that combines two sources -- both being optional.
///
/// This info is stored into the socket using `curl_multi_assign()`.
///
/// - SeeAlso: NSURLSession.MultiHandle.SocketRegisterAction
private class SocketSources {
    var readSource: dispatch_source_t?
    var writeSource: dispatch_source_t?
    func createReadSource(fileDescriptor fd: Int, queue: dispatch_queue_t, handler: () -> ()) {
        guard readSource == nil else { return }
        let s = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(fd), 0, queue)
        dispatch_source_set_event_handler(s, handler)
        readSource = s
        dispatch_resume(s)
    }
    func createWriteSource(fileDescriptor fd: Int, queue: dispatch_queue_t, handler: () -> ()) {
        guard writeSource == nil else { return }
        let s = dispatch_source_create(DISPATCH_SOURCE_TYPE_WRITE, UInt(fd), 0, queue)
        dispatch_source_set_event_handler(s, handler)
        writeSource = s
        dispatch_resume(s)
    }
    func tearDown() {
        if let s = readSource {
            dispatch_source_cancel(s)
        }
        readSource = nil
        if let s = writeSource {
            dispatch_source_cancel(s)
        }
        writeSource = nil
    }
}
extension SocketSources {
    /// Create a read and/or write source as specified by the action.
    func createSources(with action: NSURLSession.MultiHandle.SocketRegisterAction, fileDescriptor fd: Int, queue: dispatch_queue_t, handler: () -> ()) {
        if action.needsReadSource {
            createReadSource(fileDescriptor: fd, queue: queue, handler: handler)
        }
        if action.needsWriteSource {
            createWriteSource(fileDescriptor: fd, queue: queue, handler: handler)
        }
    }
}
extension SocketSources {
    /// Unwraps the `SocketSources`
    ///
    /// A `SocketSources` is stored into the multi handle's socket using
    /// `curl_multi_assign()`. This helper unwraps it from the returned
    /// `UnsafeMutablePointer<Void>`.
    static func from(socketSourcePtr ptr: UnsafeMutablePointer<Void>?) -> SocketSources? {
        guard let ptr = ptr else { return nil }
        return Unmanaged<SocketSources>.fromOpaque(ptr).takeUnretainedValue()
    }
}


extension CFURLSessionMultiCode : Equatable {}
public func ==(lhs: CFURLSessionMultiCode, rhs: CFURLSessionMultiCode) -> Bool {
    return lhs.value == rhs.value
}
extension CFURLSessionMultiCode : ErrorProtocol {
    public var _domain: String { return "libcurl.Multi" }
    public var _code: Int { return Int(self.value) }
}
internal extension CFURLSessionMultiCode {
    func asError() throws {
        if self == CFURLSessionMultiCodeOK { return }
        throw self
    }
}
