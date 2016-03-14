// Foundation/NSURLSession/NSURLSessionTask.swift - NSURLSession API
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
/// NSURLSession API code.
/// - SeeAlso: NSURLSession.swift
///
// -----------------------------------------------------------------------------




import CoreFoundation
import Dispatch


public enum NSURLSessionTaskState : Int {
    /// The task is currently being serviced by the session
    case Running
    case Suspended
    /// The task has been told to cancel.  The session will receive a URLSession:task:didCompleteWithError: message.
    case Canceling
    /// The task has completed and the session will receive no more delegate notifications
    case Completed
}



/// A cancelable object that refers to the lifetime
/// of processing a given request.
public class NSURLSessionTask : NSObject, NSCopying {
    /// How many times the task has been suspended, 0 indicating a running task.
    private var suspendCount = 1
    private var easyHandle: EasyHandle!
    private unowned let session: NSURLSessionProtocol
    private let body: Body
    /// The internal state that the task is in.
    ///
    /// Setting this value will also add / remove the easy handle.
    /// It is independt of the `state: NSURLSessionTaskState`. The
    /// `internalState` tracks the state of transfers / waiting for callbacks.
    /// The `state` tracks the overall state of the task (running vs.
    /// completed).
    /// - SeeAlso: NSURLSessionTask.InternalState
    private var internalState = InternalState.initial {
        // We manage adding / removing the easy handle and pausing / unpausing
        // here at a centralized place to make sure the internal state always
        // matches up with the state of the easy handle being added and paused.
        willSet {
            if !internalState.isEasyHandlePaused && newValue.isEasyHandlePaused {
                fatalError("Need to solve pausing receive.")
            }
            if internalState.isEasyHandleAddedToMultiHandle && !newValue.isEasyHandleAddedToMultiHandle {
                session.remove(handle: easyHandle)
            }
        }
        didSet {
            if !oldValue.isEasyHandleAddedToMultiHandle && internalState.isEasyHandleAddedToMultiHandle {
                session.add(handle: easyHandle)
            }
            if oldValue.isEasyHandlePaused && !internalState.isEasyHandlePaused {
                fatalError("Need to solve pausing receive.")
            }
            if case .taskCompleted = internalState {
                updateTaskState()
            }
        }
    }
    /// All operations must run on this queue.
    private let workQueue: dispatch_queue_t
    /// This queue is used to make public attributes thread safe. It's a
    /// **concurrent** queue and must be used with a barries when writing. This
    /// allows multiple concurrent readers or a single writer.
    private let taskAttributesIsolation: dispatch_queue_t
    
    public override init() {
        // Darwin Foundation oddly allows calling this initializer, even though
        // such a task is quite broken -- it doesn't have a session. And calling
        // e.g. `taskIdentifier` will crash.
        //
        // We set up the bare minimum for init to work, but don't care too much
        // about things crashing later.
        session = MissingURLSession()
        taskIdentifier = 0
        originalRequest = nil
        body = .none
        workQueue = dispatch_queue_create("NSURLSessionTask.notused.0", DISPATCH_QUEUE_SERIAL)
        taskAttributesIsolation = dispatch_queue_create("NSURLSessionTask.notused.1", DISPATCH_QUEUE_SERIAL)
        super.init()
    }
    /// Create a data task, i.e. with no body
    internal convenience init(session: NSURLSession, request: NSURLRequest, taskIdentifier: Int) {
        self.init(session: session, request: request, taskIdentifier: taskIdentifier, body: .none)
    }
    internal init(session: NSURLSession, request: NSURLRequest, taskIdentifier: Int, body: Body) {
        self.session = session
        self.workQueue = session.workQueue
        self.taskAttributesIsolation = session.taskAttributesIsolation
        self.taskIdentifier = taskIdentifier
        self.originalRequest = (request.copy() as! NSURLRequest)
        self.body = body
        super.init()
        self.easyHandle = EasyHandle(delegate: self)
    }
    deinit {
        //TODO: Can we ensure this somewhere else? This might run on the wrong
        // thread / queue.
        //if internalState.isEasyHandleAddedToMultiHandle {
        //    session.removeHandle(easyHandle)
        //}
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    /// An identifier for this task, assigned by and unique to the owning session
    public let taskIdentifier: Int
    
    /// May be nil if this is a stream task
    /*@NSCopying*/ public let originalRequest: NSURLRequest?
    
    /// May differ from originalRequest due to http server redirection
    /*@NSCopying*/ public private(set) var currentRequest: NSURLRequest? {
        get {
            var r: NSURLRequest? = nil
            dispatch_sync(taskAttributesIsolation) { r = self._currentRequest }
            return r
        }
        set { dispatch_barrier_async(taskAttributesIsolation) { self._currentRequest = newValue } }
    }
    private var _currentRequest: NSURLRequest? = nil
    /*@NSCopying*/ public private(set) var response: NSURLResponse? {
        get {
            var r: NSURLResponse? = nil
            dispatch_sync(taskAttributesIsolation) { r = self._response }
            return r
        }
        set { dispatch_barrier_async(taskAttributesIsolation) { self._response = newValue } }
    }
    private var _response: NSURLResponse? = nil
    
    /* Byte count properties may be zero if no body is expected,
     * or NSURLSessionTransferSizeUnknown if it is not possible
     * to know how many bytes will be transferred.
     */
    
    /// Number of body bytes already received
    public private(set) var countOfBytesReceived: Int64 {
        get {
            var r: Int64 = 0
            dispatch_sync(taskAttributesIsolation) { r = self._countOfBytesReceived }
            return r
        }
        set { dispatch_barrier_async(taskAttributesIsolation) { self._countOfBytesReceived = newValue } }
    }
    private var _countOfBytesReceived: Int64 = 0
    
    /// Number of body bytes already sent */
    public private(set) var countOfBytesSent: Int64 {
        get {
            var r: Int64 = 0
            dispatch_sync(taskAttributesIsolation) { r = self._countOfBytesSent }
            return r
        }
        set { dispatch_barrier_async(taskAttributesIsolation) { self._countOfBytesSent = newValue } }
    }
    private var _countOfBytesSent: Int64 = 0
    
    /// Number of body bytes we expect to send, derived from the Content-Length of the HTTP request */
    public private(set) var countOfBytesExpectedToSend: Int64 = 0
    
    /// Number of byte bytes we expect to receive, usually derived from the Content-Length header of an HTTP response. */
    public private(set) var countOfBytesExpectedToReceive: Int64 = 0
    
    /// The taskDescription property is available for the developer to
    /// provide a descriptive label for the task.
    public var taskDescription: String?
    
    /* -cancel returns immediately, but marks a task as being canceled.
     * The task will signal -URLSession:task:didCompleteWithError: with an
     * error value of { NSURLErrorDomain, NSURLErrorCancelled }.  In some
     * cases, the task may signal other work before it acknowledges the
     * cancelation.  -cancel may be sent to a task that has been suspended.
     */
    public func cancel() { NSUnimplemented() }
    
    /*
     * The current state of the task within the session.
     */
    public var state: NSURLSessionTaskState {
        get {
            var r: NSURLSessionTaskState = .Suspended
            dispatch_sync(taskAttributesIsolation) { r = self._state }
            return r
        }
        set { dispatch_barrier_async(taskAttributesIsolation) { self._state = newValue } }
    }
    private var _state: NSURLSessionTaskState = .Suspended
    
    /*
     * The error, if any, delivered via -URLSession:task:didCompleteWithError:
     * This property will be nil in the event that no error occured.
     */
    /*@NSCopying*/ public var error: NSError? { NSUnimplemented() }
    
    /// Suspend the task.
    ///
    /// Suspending a task will prevent the NSURLSession from continuing to
    /// load data.  There may still be delegate calls made on behalf of
    /// this task (for instance, to report data received while suspending)
    /// but no further transmissions will be made on behalf of the task
    /// until -resume is sent.  The timeout timer associated with the task
    /// will be disabled while a task is suspended. -suspend and -resume are
    /// nestable.
    public func suspend() {
        // suspend / resume is implemented simply by adding / removing the task's
        // easy handle fromt he session's multi-handle.
        //
        // This might result in slightly different behaviour than the Darwin Foundation
        // implementation, but it'll be difficult to get complete parity anyhow.
        // Too many things depend on timeout on the wire etc.
        //
        // TODO: It may be worth looking into starting over a task that gets
        // resumed. The Darwin Foundation documentation states that that's what
        // it does for anything but download tasks.
        
        // We perform the increment and call to `updateTaskState()`
        // synchronous, to make sure the `state` is updated when this method
        // returns, but the actual suspend will be done asynchronous to avoid
        // dead-locks.
        dispatch_sync(workQueue) {
            self.suspendCount += 1
            guard self.suspendCount < Int.max else { fatalError("Task suspended too many times \(Int.max).") }
            self.updateTaskState()
            
            if self.suspendCount == 1 {
                dispatch_async(self.workQueue) {
                    self.performSuspend()
                }
            }
        }
    }
    /// Resume the task.
    ///
    /// - SeeAlso: `suspend()`
    public func resume() {
        dispatch_sync(workQueue) {
            self.suspendCount -= 1
            guard 0 <= self.suspendCount else { fatalError("Resuming a task that's not suspended. Calls to resume() / suspend() need to be matched.") }
            self.updateTaskState()
            
            if self.suspendCount == 0 {
                dispatch_async(self.workQueue) {
                    self.performResume()
                }
            }
        }
    }
    
    /// The priority of the task.
    ///
    /// Sets a scaling factor for the priority of the task. The scaling factor is a
    /// value between 0.0 and 1.0 (inclusive), where 0.0 is considered the lowest
    /// priority and 1.0 is considered the highest.
    ///
    /// The priority is a hint and not a hard requirement of task performance. The
    /// priority of a task may be changed using this API at any time, but not all
    /// protocols support this; in these cases, the last priority that took effect
    /// will be used.
    ///
    /// If no priority is specified, the task will operate with the default priority
    /// as defined by the constant NSURLSessionTaskPriorityDefault. Two additional
    /// priority levels are provided: NSURLSessionTaskPriorityLow and
    /// NSURLSessionTaskPriorityHigh, but use is not restricted to these.
    public var priority: Float {
        get {
            var r: Float = 0
            dispatch_sync(taskAttributesIsolation) { r = self._priority }
            return r
        }
        set {
            dispatch_barrier_async(taskAttributesIsolation) { self._priority = newValue }
        }
    }
    private var _priority: Float = NSURLSessionTaskPriorityDefault
}

private extension NSURLSessionTask {
    /// The calls to `suspend` can be nested. This one is only called when the
    /// task is not suspended and needs to go into suspended state.
    func performSuspend() {
        if case .transferInProgress(let transferState) = internalState {
            internalState = .transferReady(transferState)
        }
    }
    /// The calls to `resume` can be nested. This one is only called when the
    /// task is suspended and needs to go out of suspended state.
    func performResume() {
        if case .initial = internalState {
            guard let r = originalRequest else { fatalError("Task has no original request.") }
            startNewTransfer(with: r)
        }
        if case .transferReady(let transferState) = internalState {
            internalState = .transferInProgress(transferState)
        }
    }
}

internal extension NSURLSessionTask {
    /// The is independent of the public `state: NSURLSessionTaskState`.
    enum InternalState {
        /// Task has been created, but nothing has been done, yet
        case initial
        /// The easy handle has been fully configured. But it is not added to
        /// the multi handle.
        case transferReady(TransferState)
        /// The easy handle is currently added to the multi handle
        case transferInProgress(TransferState)
        /// The transfer completed.
        ///
        /// The easy handle has been removed from the multi handle. This does
        /// not (necessarily mean the task completed. A task that gets
        /// redirected will do multiple transfers.
        case transferCompleted(response: NSHTTPURLResponse, bodyDataDrain: TransferState.DataDrain)
        /// The transfer failed.
        ///
        /// Same as `.transferCompleted`, but without response / body data
        case transferFailed
        /// Waiting for the completion handler of the HTTP redirect callback.
        ///
        /// When we tell the delegate that we're about to perform an HTTP
        /// redirect, we need to wait for the delegate to let us know what
        /// action to take.
        case waitingForRedirectCompletionHandler(response: NSHTTPURLResponse, bodyDataDrain: TransferState.DataDrain)
        /// Waiting for the completion handler of the 'did receive response' callback.
        ///
        /// When we tell the delegate that we received a response (i.e. when
        /// we received a complete header), we need to wait for the delegate to
        /// let us know what action to take. In this state the easy handle is
        /// paused in order to suspend delegate callbacks.
        case waitingForResponseCompletionHandler(TransferState)
        /// The task is completed
        ///
        /// Contrast this with `.transferCompleted`.
        case taskCompleted
    }
}

private extension NSURLSessionTask.InternalState {
    var isEasyHandleAddedToMultiHandle: Bool {
        switch self {
        case .initial:                             return false
        case .transferReady:                       return false
        case .transferInProgress:                  return true
        case .transferCompleted:                   return false
        case .transferFailed:                      return false
        case .waitingForRedirectCompletionHandler: return false
        case .waitingForResponseCompletionHandler: return true
        case .taskCompleted:                       return false
        }
    }
    var isEasyHandlePaused: Bool {
        switch self {
        case .initial:                             return false
        case .transferReady:                       return false
        case .transferInProgress:                  return false
        case .transferCompleted:                   return false
        case .transferFailed:                      return false
        case .waitingForRedirectCompletionHandler: return false
        case .waitingForResponseCompletionHandler: return true
        case .taskCompleted:                       return false
        }
    }
}

internal extension NSURLSessionTask {
    /// Updates the (public) state based on private / internal state.
    ///
    /// - Note: This must be called on the `workQueue`.
    private func updateTaskState() {
        func calculateState() -> NSURLSessionTaskState {
            if case .taskCompleted = internalState {
                return .Completed
            }
            if suspendCount == 0 {
                return .Running
            } else {
                return .Suspended
            }
        }
        state = calculateState()
    }
}

internal extension NSURLSessionTask {
    enum Body {
        case none
        case data(dispatch_data_t)
        /// Body data is read from the given file URL
        case file(NSURL)
        case stream(NSInputStream)
    }
}
private extension NSURLSessionTask.Body {
    enum Error : ErrorProtocol {
        case fileForBodyDataNotFound
    }
    /// - Returns: The body length, or `nil` for no body (e.g. `GET` request).
    func getBodyLength() throws -> UInt64? {
        switch self {
        case .none:
            return 0
        case .data(let d):
            return UInt64(dispatch_data_get_size(d))
        /// Body data is read from the given file URL
        case .file(let fileURL):
            guard let s = try NSFileManager.defaultManager().attributesOfItemAtPath(fileURL.path!)[NSFileSize] as? NSNumber else {
                throw Error.fileForBodyDataNotFound
            }
            return s.unsignedLongLongValue
        case .stream:
            return nil
        }
    }
}

/// Easy handle related
private extension NSURLSessionTask {
    /// Start a new transfer
    func startNewTransfer(with request: NSURLRequest) {
        currentRequest = request
        guard let url = request.url else { fatalError("No URL in request.") }
        internalState = .transferReady(createTransferState(url: url))
        configureEasyHandle(for: request)
        if suspendCount < 1 {
            performResume()
        }
    }
    /// Creates a new transfer state with the given behaviour:
    func createTransferState(url: NSURL) -> NSURLSessionTask.TransferState {
        let drain = createTransferBodyDataDrain()
        switch body {
        case .none:
            return NSURLSessionTask.TransferState(url: url, bodyDataDrain: drain)
        case .data(let data):
            let source = HTTPBodyDataSource(data: data)
            return NSURLSessionTask.TransferState(url: url, bodyDataDrain: drain, bodySource: source)
        case .file(let fileURL):
            let source = HTTPBodyFileSource(fileURL: fileURL, workQueue: workQueue, dataAvailableHandler: { [weak self] in
                // Unpause the easy handle
                self?.easyHandle.unpauseSend()
                })
            return NSURLSessionTask.TransferState(url: url, bodyDataDrain: drain, bodySource: source)
        case .stream:
            NSUnimplemented()
        }
        
    }
    /// The data drain.
    ///
    /// This depends on what the delegate / completion handler need.
    private func createTransferBodyDataDrain() -> NSURLSessionTask.TransferState.DataDrain {
        switch session.behaviour(for: self) {
        case .noDelegate:
            return .ignore
        case .taskDelegate:
            // Data will be forwarded to the delegate as we receive it, we don't
            // need to do anything about it.
            return .ignore
        case .dataCompletionHandler:
            // Data needs to be concatenated in-memory such that we can pass it
            // to the completion handler upon completion.
            return .inMemory(nil)
        case .downloadCompletionHandler:
            // Data needs to be written to a file (i.e. a download task).
            NSUnimplemented()
        }
    }
    /// Set options on the easy handle to match the given request.
    ///
    /// This performs a series of `curl_easy_setopt()` calls.
    private func configureEasyHandle(for request: NSURLRequest) {
        // At this point we will call the equivalent of curl_easy_setopt()
        // to configure everything on the handle. Since we might be re-using
        // a handle, we must be sure to set everything and not rely on defaul
        // values.
        
        //TODO: We could add a strong reference from the easy handle back to
        // its NSURLSessionTask by means of CURLOPT_PRIVATE -- that would ensure
        // that the task is always around while the handle is running.
        // We would have to break that retain cycle once the handle completes
        // its transfer.
        
        // Behavior Options
        easyHandle.set(verboseModeOn: enableLibcurlDebugOutput)
        easyHandle.set(debugOutputOn: enableLibcurlDebugOutput, task: self)
        easyHandle.set(passHeadersToDataStream: false)
        easyHandle.set(progressMeterOff: true)
        easyHandle.set(skipAllSignalHandling: true)
        
        // Error Options:
        easyHandle.set(errorBuffer: nil)
        easyHandle.set(failOnHTTPErrorCode: false)
        
        // Network Options:
        guard let url = request.url else { fatalError("No URL in request.") }
        easyHandle.set(url: url)
        easyHandle.setAllowedProtocolsToHTTPAndHTTPS()
        easyHandle.set(preferredReceiveBufferSize: Int.max)
        do {
            switch (body, try body.getBodyLength()) {
            case (.none, _):
                set(requestBodyLength: .noBody)
            case (_, .some(let length)):
                set(requestBodyLength: .length(length))
            case (_, .none):
                set(requestBodyLength: .unknown)
            }
        } catch let e {
            // Fail the request here.
            // TODO: We have multiple options:
            //     NSURLErrorNoPermissionsToReadFile
            //     NSURLErrorFileDoesNotExist
            internalState = .transferFailed
            failWith(errorCode: errorCode(fileSystemError: e), request: request)
            return
        }
        
        // HTTP Options:
        easyHandle.set(followLocation: false)
        easyHandle.set(customHeaders: curlHeaders(for: request))
        easyHandle.set(waitForPipeliningAndMultiplexing: true)
        easyHandle.set(streamWeight: priority)
        easyHandle.set(automaticBodyDecompression: true)
        easyHandle.set(requestMethod: request.httpMethod ?? "GET")
        if request.httpMethod == "HEAD" {
            easyHandle.set(noBody: true)
        }
    }
}

private extension NSURLSessionTask {
    /// These are a list of headers that should be passed to libcurl.
    ///
    /// Headers will be returned as `Accept: text/html` strings for
    /// setting fields, `Accept:` for disabling the libcurl default header, or
    /// `Accept;` for a header with no content. This is the format that libcurl
    /// expects.
    ///
    /// - SeeAlso: https://curl.haxx.se/libcurl/c/CURLOPT_HTTPHEADER.html
    func curlHeaders(for request: NSURLRequest) -> [String] {
        var result: [String] = []
        var names = Set<String>()
        if let hh = currentRequest?.allHTTPHeaderFields {
            hh.forEach {
                let name = $0.0.lowercased()
                guard !names.contains(name) else { return }
                names.insert(name)
                
                if $0.1.isEmpty {
                    result.append($0.0 + ";")
                } else {
                    result.append($0.0 + ": " + $0.1)
                }
            }
        }
        curlHeadersToSet.forEach {
            let name = $0.0.lowercased()
            guard !names.contains(name) else { return }
            names.insert(name)
            
            if $0.1.isEmpty {
                result.append($0.0 + ";")
            } else {
                result.append($0.0 + ": " + $0.1)
            }
        }
        curlHeadersToRemove.forEach {
            let name = $0.lowercased()
            guard !names.contains(name) else { return }
            names.insert(name)
            result.append($0 + ":")
        }
        return result
    }
    /// Any header values that should be passed to libcurl
    ///
    /// These will only be set if not already part of the request.
    /// - SeeAlso: https://curl.haxx.se/libcurl/c/CURLOPT_HTTPHEADER.html
    var curlHeadersToSet: [(String,String)] {
        var result = [("Connection", "keep-alive"),
                      ("User-Agent", userAgentString),
                      ]
        if let language = NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) as? String {
            result.append(("Accept-Language", language))
        }
        return result
    }
    /// Any header values that should be removed from the ones set by libcurl
    /// - SeeAlso: https://curl.haxx.se/libcurl/c/CURLOPT_HTTPHEADER.html
    var curlHeadersToRemove: [String] {
        if case .none = body {
            return []
        } else {
            return ["Expect"]
        }
    }
}

private var userAgentString: String = {
    // Darwin uses something like this: "xctest (unknown version) CFNetwork/760.4.2 Darwin/15.4.0 (x86_64)"
    let info = NSProcessInfo.processInfo()
    let name = info.processName
    let curlVersion = CFURLSessionCurlVersionInfo()
    //TODO: Should probably use sysctl(3) to get these:
    // kern.ostype: Darwin
    // kern.osrelease: 15.4.0
    //TODO: Use NSBundle to get the version number?
    return "\(name) (unknown version) curl/\(curlVersion.major).\(curlVersion.minor).\(curlVersion.patch)"
}()

private func errorCode(fileSystemError error: ErrorProtocol) -> Int {
    func fromCocoaErrorCode(_ code: Int) -> Int {
        switch code {
        case NSCocoaError.FileReadNoSuchFileError.rawValue:
            return NSURLErrorFileDoesNotExist
        case NSCocoaError.FileReadNoPermissionError.rawValue:
            return NSURLErrorNoPermissionsToReadFile
        default:
            return NSURLErrorUnknown
        }
    }
    switch error {
    case let e as NSError where e.domain == NSCocoaErrorDomain:
        return fromCocoaErrorCode(e.code)
    default:
        return NSURLErrorUnknown
    }
}

private extension NSURLSessionTask {
    /// Set request body length.
    ///
    /// An unknown length
    func set(requestBodyLength length: NSURLSessionTask.RequestBodyLength) {
        switch length {
        case .noBody:
            easyHandle.set(upload: false)
            easyHandle.set(requestBodyLength: 0)
        case .length(let length):
            easyHandle.set(upload: true)
            easyHandle.set(requestBodyLength: Int64(length))
        case .unknown:
            easyHandle.set(upload: true)
            easyHandle.set(requestBodyLength: -1)
        }
    }
    enum RequestBodyLength {
        case noBody
        ///
        case length(UInt64)
        /// Will result in a chunked upload
        case unknown
    }
}

extension NSURLSessionTask: EasyHandleDelegate {
    func didReceive(data: UnsafeBufferPointer<Int8>) -> EasyHandle.Action {
        guard case .transferInProgress(let ts) = internalState else { fatalError("Received body data, but no transfer in progress.") }
        guard ts.isHeaderComplete else { fatalError("Received body data, but the header is not complete, yet.") }
        notifyDelegate(aboutReceivedData: data)
        internalState = .transferInProgress(ts.byAppending(bodyData: data))
        return .proceed
    }
    private func notifyDelegate(aboutReceivedData data: UnsafeBufferPointer<Int8>) {
        if case .taskDelegate(let delegate) = session.behaviour(for: self),
            let dataDelegate = delegate as? NSURLSessionDataDelegate,
            let task = self as? NSURLSessionDataTask {
            // Forward to the delegate:
            guard let s = session as? NSURLSession else { fatalError() }
            let d = NSData(bytes: UnsafeMutablePointer<Void>(data.baseAddress), length: data.count)
            s.delegateQueue.addOperationWithBlock {
                dataDelegate.urlSession(session: s, dataTask: task, didReceive: d)
            }
        }
    }
    func didReceive(headerData data: UnsafeBufferPointer<Int8>) -> EasyHandle.Action {
        guard case .transferInProgress(let ts) = internalState else { fatalError("Received body data, but no transfer in progress.") }
        do {
            let newTS = try ts.byAppending(headerLine: data)
            internalState = .transferInProgress(newTS)
            let didCompleteHeader = !ts.isHeaderComplete && newTS.isHeaderComplete
            if didCompleteHeader {
                // The header is now complete, but wasn't before.
                didReceiveResponse()
            }
            return .proceed
        } catch {
            return .abort
        }
    }
    func fill(writeBuffer buffer: UnsafeMutableBufferPointer<Int8>) -> NSURLSessionTask.EasyHandle.WriteBufferResult {
        guard case .transferInProgress(let ts) = internalState else { fatalError("Requested to fill write buffer, but transfer isn’t in progress.") }
        guard let source = ts.requestBodySource else { fatalError("Requested to fill write buffer, but transfer state has no body source.") }
        switch source.getNextChunk(withLength: buffer.count) {
        case .data(let data):
            copyDispatchData(data, infoBuffer: buffer)
            let count = Int(dispatch_data_get_size(data))
            assert(0 < count)
            return .bytes(count)
        case .done:
            return .bytes(0)
        case .retryLater:
            // At this point we'll try to pause the easy handle. The body source
            // is responsible for un-pausing the handle once data becomes
            // available.
            return .pause
        case .error:
            return .abort
        }
    }
    func transferCompleted(withErrorCode errorCode: Int?) {
        // At this point the transfer is complete and we can decide what to do.
        // If everything went well, we will simply forward the resulting data
        // to the delegate. But in case of redirects etc. we might send another
        // request.
        guard case .transferInProgress(let ts) = internalState else { fatalError("Transfer completed, but it wasn't in progress.") }
        guard let request = currentRequest else { fatalError("Transfer completed, but there's no currect request.") }
        guard errorCode == nil else {
            internalState = .transferFailed
            failWith(errorCode: errorCode!, request: request)
            return
        }
        
        guard let response = ts.response else { fatalError("Transfer completed, but there's no response.") }
        internalState = .transferCompleted(response: response, bodyDataDrain: ts.bodyDataDrain)
        
        let action = completionAction(forCompletedRequest: request, response: response)
        switch action {
        case .completeTask:
            completeTask()
        case .failWithError(let errorCode):
            internalState = .transferFailed
            failWith(errorCode: errorCode, request: request)
        case .redirectWithRequest(let newRequest):
            redirectFor(request: newRequest)
        }
    }
    func seekInputStream(to position: UInt64) throws {
        // We will reset the body sourse and seek forward.
        NSUnimplemented()
    }
    func updateProgressMeter(with propgress: NSURLSessionTask.EasyHandle.Progress) {
        //TODO: Update progress. Note that a single NSURLSessionTask might
        // perform multiple transfers. The values in `progress` are only for
        // the current transfer.
    }
}

/// State Transfers
extension NSURLSessionTask {
    func completeTask() {
        guard case .transferCompleted(response: let response, bodyDataDrain: let bodyDataDrain) = internalState else {
            fatalError("Trying to complete the task, but its transfer isn't complete.")
        }
        internalState = .taskCompleted
        self.response = response
        switch session.behaviour(for: self) {
        case .taskDelegate(let delegate):
            guard let s = session as? NSURLSession else { fatalError() }
            s.delegateQueue.addOperationWithBlock {
                delegate.urlSession(session: s, task: self, didCompleteWithError: nil)
            }
        case .noDelegate:
            break
        case .dataCompletionHandler(let completion):
            guard case .inMemory(let bodyData) = bodyDataDrain else {
                fatalError("Task has data completion handler, but data drain is not in-memory.")
            }
            guard let s = session as? NSURLSession else { fatalError() }
            s.delegateQueue.addOperationWithBlock {
                completion(bodyData, response, nil)
            }
        case .downloadCompletionHandler:
            NSUnimplemented()
        }
    }
    func completeTask(withError error: NSError) {
        guard case .transferFailed = internalState else {
            fatalError("Trying to complete the task, but its transfer isn't complete / failed.")
        }
        internalState = .taskCompleted
        switch session.behaviour(for: self) {
        case .taskDelegate(let delegate):
            guard let s = session as? NSURLSession else { fatalError() }
            s.delegateQueue.addOperationWithBlock {
                delegate.urlSession(session: s, task: self, didCompleteWithError: error)
            }
        case .noDelegate:
            break
        case .dataCompletionHandler(let completion):
            guard let s = session as? NSURLSession else { fatalError() }
            s.delegateQueue.addOperationWithBlock {
                completion(nil, nil, error)
            }
        case .downloadCompletionHandler:
            NSUnimplemented()
        }
    }
    func failWith(errorCode: Int, request: NSURLRequest) {
        //TODO: Error handling
        let userInfo: [String : Any]? = request.url.map {
            [
                NSURLErrorFailingURLErrorKey: $0,
                NSURLErrorFailingURLStringErrorKey: $0.absoluteString,
                ]
        }
        let error = NSError(domain: NSURLErrorDomain, code: errorCode, userInfo: userInfo)
        completeTask(withError: error)
    }
    func redirectFor(request: NSURLRequest) {
        //TODO: Should keep track of the number of redirects that this
        // request has gone through and err out once it's too large, i.e.
        // call into `failWith(errorCode: )` with NSURLErrorHTTPTooManyRedirects
        guard case .transferCompleted(response: let response, bodyDataDrain: let bodyDataDrain) = internalState else {
            fatalError("Trying to redirect, but the transfer is not complete.")
        }
        
        switch session.behaviour(for: self) {
        case .taskDelegate(let delegate):
            // At this point we need to change the internal state to note
            // that we're waiting for the delegate to call the completion
            // handler. Then we'll call the delegate callback
            // (willPerformHTTPRedirection). The task will then switch out of
            // its internal state once the delegate calls the completion
            // handler.
            
            //TODO: Should the `public response: NSURLResponse` property be updated
            // before we call delegate API
            // `func urlSession(session: session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void)`
            // ?
            
            internalState = .waitingForRedirectCompletionHandler(response: response, bodyDataDrain: bodyDataDrain)
            // We need this ugly cast in order to be able to support `NSURLSessionTask.init()`
            guard let s = session as? NSURLSession else { fatalError() }
            s.delegateQueue.addOperationWithBlock {
                delegate.urlSession(session: s, task: self, willPerformHTTPRedirection: response, newRequest: request) { [weak self] (request: NSURLRequest?) in
                    guard let task = self else { return }
                    dispatch_async(task.workQueue) {
                        task.didCompleteRedirectCallback(request)
                    }
                }
            }
        case .noDelegate, .dataCompletionHandler, .downloadCompletionHandler:
            // Follow the redirect.
            startNewTransfer(with: request)
        }
    }
    private func didCompleteRedirectCallback(_ request: NSURLRequest?) {
        guard case .waitingForRedirectCompletionHandler(response: let response, bodyDataDrain: let bodyDataDrain) = internalState else {
            fatalError("Received callback for HTTP redirection, but we're not waiting for it. Was it called multiple times?")
        }
        // If the request is `nil`, we're supposed to treat the current response
        // as the final response, i.e. not do any redirection.
        // Otherwise, we'll start a new transfer with the passed in request.
        if let r = request {
            startNewTransfer(with: r)
        } else {
            internalState = .transferCompleted(response: response, bodyDataDrain: bodyDataDrain)
            completeTask()
        }
    }
}


/// Response processing
private extension NSURLSessionTask {
    /// Whenever we receive a response (i.e. a complete header) from libcurl,
    /// this method gets called.
    func didReceiveResponse() {
        guard let dt = self as? NSURLSessionDataTask else { return }
        guard case .transferInProgress(let ts) = internalState else { fatalError("Transfer not in progress.") }
        guard let response = ts.response else { fatalError("Header complete, but not URL response.") }
        switch session.behaviour(for: self) {
        case .noDelegate:
            break
        case .taskDelegate(let delegate as NSURLSessionDataDelegate):
            //TODO: There's a problem with libcurl / with how we're using it.
            // We're currently unable to pause the transfer / the easy handle:
            // https://curl.haxx.se/mail/lib-2016-03/0222.html
            //
            // For now, we'll notify the delegate, but won't pause the transfer,
            // and we'll disregard the completion handler:
            let workaround = true
            if workaround {
                guard let s = session as? NSURLSession else { fatalError() }
                s.delegateQueue.addOperationWithBlock {
                    delegate.urlSession(session: s, dataTask: dt, didReceive: response, completionHandler: { _ in
                        print("warning: Ignoring dispotion from completion handler.")
                    })
                }
            } else {
                askDelegateHowToProceedAfterCompleteResponse(response, delegate: delegate)
            }
        case .taskDelegate:
            break
        case .dataCompletionHandler:
            break
        case .downloadCompletionHandler:
            break
        }
    }
    /// Give the delegate a chance to tell us how to proceed once we have a
    /// response / complete header.
    ///
    /// This will pause the transfer.
    func askDelegateHowToProceedAfterCompleteResponse(_ response: NSHTTPURLResponse, delegate: NSURLSessionDataDelegate) {
        // Ask the delegate how to proceed.
        
        // This will pause the easy handle. We need to wait for the
        // delegate before processing any more data.
        guard case .transferInProgress(let ts) = internalState else { fatalError("Transfer not in progress.") }
        internalState = .waitingForResponseCompletionHandler(ts)
        
        let dt = self as! NSURLSessionDataTask
        
        // We need this ugly cast in order to be able to support `NSURLSessionTask.init()`
        guard let s = session as? NSURLSession else { fatalError() }
        s.delegateQueue.addOperationWithBlock {
            delegate.urlSession(session: s, dataTask: dt, didReceive: response, completionHandler: { [weak self] disposition in
                guard let task = self else { return }
                dispatch_async(task.workQueue) {
                    task.didCompleteResponseCallback(disposition: disposition)
                }
                })
        }
    }
    /// This gets called (indirectly) when the data task delegates lets us know
    /// how we should proceed after receiving a response (i.e. complete header).
    func didCompleteResponseCallback(disposition: NSURLSessionResponseDisposition) {
        guard case .waitingForResponseCompletionHandler(let ts) = internalState else { fatalError("Received response disposition, but we're not waiting for it.") }
        switch disposition {
        case .cancel:
            //TODO: Fail the task with NSURLErrorCancelled
            NSUnimplemented()
        case .allow:
            // Continue the transfer. This will unpause the easy handle.
            internalState = .transferInProgress(ts)
        case .becomeDownload:
            /* Turn this request into a download */
            NSUnimplemented()
        case .becomeStream:
            /* Turn this task into a stream task */
            NSUnimplemented()
        }
    }
    
    /// Action to be taken after a transfer completes
    enum CompletionAction {
        case completeTask
        case failWithError(Int)
        case redirectWithRequest(NSURLRequest)
    }
    
    /// What action to take
    func completionAction(forCompletedRequest request: NSURLRequest, response: NSHTTPURLResponse) -> CompletionAction {
        // Redirect:
        if let request = redirectRequest(for: response, fromRequest: request) {
            return .redirectWithRequest(request)
        }
        return .completeTask
    }
    /// If the response is a redirect, return the new request
    ///
    /// RFC 7231 section 6.4 defines redirection behavior for HTTP/1.1
    ///
    /// - SeeAlso: <https://tools.ietf.org/html/rfc7231#section-6.4>
    func redirectRequest(for response: NSHTTPURLResponse, fromRequest: NSURLRequest) -> NSURLRequest? {
        //TODO: Do we ever want to redirect for HEAD requests?
        func methodAndURL() -> (String, NSURL)? {
            guard
                let location = response.value(forHeaderField: .location),
                let targetURL = NSURL(string: location)
                else {
                    // Can't redirect when there's no location to redirect to.
                    return nil
            }
            
            // Check for a redirect:
            switch response.statusCode {
            //TODO: Should we do this for 300 "Multiple Choices", too?
            case 301, 302, 303:
                // Change into "GET":
                return ("GET", targetURL)
            case 307:
                // Re-use existing method:
                return (fromRequest.httpMethod ?? "GET", targetURL)
            default:
                return nil
            }
        }
        guard let (method, targetURL) = methodAndURL() else { return nil }
        let request = fromRequest.mutableCopy() as! NSMutableURLRequest
        request.httpMethod = method
        request.url = targetURL
        return request
    }
}


private extension NSHTTPURLResponse {
    /// Type safe HTTP header field name(s)
    enum Field: String {
        /// `Location`
        /// - SeeAlso: RFC 2616 section 14.30 <https://tools.ietf.org/html/rfc2616#section-14.30>
        case location = "Location"
    }
    func value(forHeaderField field: Field) -> String? {
        return value(forHeaderField: field.rawValue)
    }
}

public let NSURLSessionTaskPriorityDefault: Float = 0.5
public let NSURLSessionTaskPriorityLow: Float = 0.25
public let NSURLSessionTaskPriorityHigh: Float = 0.75

/*
 * An NSURLSessionDataTask does not provide any additional
 * functionality over an NSURLSessionTask and its presence is merely
 * to provide lexical differentiation from download and upload tasks.
 */
public class NSURLSessionDataTask : NSURLSessionTask {
}

/*
 * An NSURLSessionUploadTask does not currently provide any additional
 * functionality over an NSURLSessionDataTask.  All delegate messages
 * that may be sent referencing an NSURLSessionDataTask equally apply
 * to NSURLSessionUploadTasks.
 */
public class NSURLSessionUploadTask : NSURLSessionDataTask {
}

/*
 * NSURLSessionDownloadTask is a task that represents a download to
 * local storage.
 */
public class NSURLSessionDownloadTask : NSURLSessionTask {
    
    /* Cancel the download (and calls the superclass -cancel).  If
     * conditions will allow for resuming the download in the future, the
     * callback will be called with an opaque data blob, which may be used
     * with -downloadTaskWithResumeData: to attempt to resume the download.
     * If resume data cannot be created, the completion handler will be
     * called with nil resumeData.
     */
    public func cancelByProducingResumeData(completionHandler: (NSData?) -> Void) { NSUnimplemented() }
}

/*
 * An NSURLSessionStreamTask provides an interface to perform reads
 * and writes to a TCP/IP stream created via NSURLSession.  This task
 * may be explicitly created from an NSURLSession, or created as a
 * result of the appropriate disposition response to a
 * -URLSession:dataTask:didReceiveResponse: delegate message.
 *
 * NSURLSessionStreamTask can be used to perform asynchronous reads
 * and writes.  Reads and writes are enquened and executed serially,
 * with the completion handler being invoked on the sessions delegate
 * queuee.  If an error occurs, or the task is canceled, all
 * outstanding read and write calls will have their completion
 * handlers invoked with an appropriate error.
 *
 * It is also possible to create NSInputStream and NSOutputStream
 * instances from an NSURLSessionTask by sending
 * -captureStreams to the task.  All outstanding read and writess are
 * completed before the streams are created.  Once the streams are
 * delivered to the session delegate, the task is considered complete
 * and will receive no more messsages.  These streams are
 * disassociated from the underlying session.
 */

public class NSURLSessionStreamTask : NSURLSessionTask {
    
    /* Read minBytes, or at most maxBytes bytes and invoke the completion
     * handler on the sessions delegate queue with the data or an error.
     * If an error occurs, any outstanding reads will also fail, and new
     * read requests will error out immediately.
     */
    public func readData(ofMinLength minBytes: Int, maxLength maxBytes: Int, timeout: NSTimeInterval, completionHandler: (NSData?, Bool, NSError?) -> Void) { NSUnimplemented() }
    
    /* Write the data completely to the underlying socket.  If all the
     * bytes have not been written by the timeout, a timeout error will
     * occur.  Note that invocation of the completion handler does not
     * guarantee that the remote side has received all the bytes, only
     * that they have been written to the kernel. */
    public func writeData(data: NSData, timeout: NSTimeInterval, completionHandler: (NSError?) -> Void) { NSUnimplemented() }
    
    /* -captureStreams completes any already enqueued reads
     * and writes, and then invokes the
     * URLSession:streamTask:didBecomeInputStream:outputStream: delegate
     * message. When that message is received, the task object is
     * considered completed and will not receive any more delegate
     * messages. */
    public func captureStreams() { NSUnimplemented() }
    
    /* Enqueue a request to close the write end of the underlying socket.
     * All outstanding IO will complete before the write side of the
     * socket is closed.  The server, however, may continue to write bytes
     * back to the client, so best practice is to continue reading from
     * the server until you receive EOF.
     */
    public func closeWrite() { NSUnimplemented() }
    
    /* Enqueue a request to close the read side of the underlying socket.
     * All outstanding IO will complete before the read side is closed.
     * You may continue writing to the server.
     */
    public func closeRead() { NSUnimplemented() }
    
    /*
     * Begin encrypted handshake.  The hanshake begins after all pending
     * IO has completed.  TLS authentication callbacks are sent to the
     * session's -URLSession:task:didReceiveChallenge:completionHandler:
     */
    public func startSecureConnection() { NSUnimplemented() }
    
    /*
     * Cleanly close a secure connection after all pending secure IO has
     * completed.
     */
    public func stopSecureConnection() { NSUnimplemented() }
}

/* Key in the userInfo dictionary of an NSError received during a failed download. */
public let NSURLSessionDownloadTaskResumeData: String = "" // NSUnimplemented


extension NSURLSession {
    static func printDebug(@autoclosure _ text: () -> String) {
        guard enableDebugOutput else { return }
        debugPrint(text())
    }
}

private let enableLibcurlDebugOutput: Bool = {
    return (NSProcessInfo.processInfo().environment["NSURLSessionDebugLibcurl"] != nil)
}()
private let enableDebugOutput: Bool = {
    return (NSProcessInfo.processInfo().environment["NSURLSessionDebug"] != nil)
}()
