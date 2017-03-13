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
/// URLSession API code.
/// - SeeAlso: NSURLSession.swift
///
// -----------------------------------------------------------------------------




import CoreFoundation
import Dispatch


/// A cancelable object that refers to the lifetime
/// of processing a given request.
open class URLSessionTask : NSObject, NSCopying {
    /// How many times the task has been suspended, 0 indicating a running task.
    fileprivate var suspendCount = 1
    fileprivate var easyHandle: _EasyHandle!
    fileprivate var totalDownloaded = 0
    fileprivate var session: URLSessionProtocol! //change to nil when task completes
    fileprivate let body: _Body
    fileprivate let tempFileURL: URL
    
    /// The internal state that the task is in.
    ///
    /// Setting this value will also add / remove the easy handle.
    /// It is independt of the `state: URLSessionTask.State`. The
    /// `internalState` tracks the state of transfers / waiting for callbacks.
    /// The `state` tracks the overall state of the task (running vs.
    /// completed).
    /// - SeeAlso: URLSessionTask._InternalState
    fileprivate var internalState = _InternalState.initial {
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
                guard let s = session as? URLSession else { fatalError() }
                s.workQueue.async {
                    s.taskRegistry.remove(self)
                }
            }
        }
    }
    /// All operations must run on this queue.
    fileprivate let workQueue: DispatchQueue 
    /// This queue is used to make public attributes thread safe. It's a
    /// **concurrent** queue and must be used with a barries when writing. This
    /// allows multiple concurrent readers or a single writer.
    fileprivate let taskAttributesIsolation: DispatchQueue 
    
    public override init() {
        // Darwin Foundation oddly allows calling this initializer, even though
        // such a task is quite broken -- it doesn't have a session. And calling
        // e.g. `taskIdentifier` will crash.
        //
        // We set up the bare minimum for init to work, but don't care too much
        // about things crashing later.
        session = _MissingURLSession()
        taskIdentifier = 0
        originalRequest = nil
        body = .none
        workQueue = DispatchQueue(label: "URLSessionTask.notused.0")
        taskAttributesIsolation = DispatchQueue(label: "URLSessionTask.notused.1", attributes: DispatchQueue.Attributes.concurrent)
        let fileName = NSTemporaryDirectory() + NSUUID().uuidString + ".tmp"
        _ = FileManager.default.createFile(atPath: fileName, contents: nil)
        self.tempFileURL = URL(fileURLWithPath: fileName)
        super.init()
    }
    /// Create a data task. If there is a httpBody in the URLRequest, use that as a parameter
    internal convenience init(session: URLSession, request: URLRequest, taskIdentifier: Int) {
        if let bodyData = request.httpBody {
            self.init(session: session, request: request, taskIdentifier: taskIdentifier, body: _Body.data(createDispatchData(bodyData)))
        } else {
            self.init(session: session, request: request, taskIdentifier: taskIdentifier, body: .none)
        }
    }
    internal init(session: URLSession, request: URLRequest, taskIdentifier: Int, body: _Body) {
        self.session = session
        self.workQueue = session.workQueue
        self.taskAttributesIsolation = session.taskAttributesIsolation
        self.taskIdentifier = taskIdentifier
        self.originalRequest = request
        self.body = body
        let fileName = NSTemporaryDirectory() + NSUUID().uuidString + ".tmp"
        _ = FileManager.default.createFile(atPath: fileName, contents: nil)
        self.tempFileURL = URL(fileURLWithPath: fileName)
        super.init()
        self.easyHandle = _EasyHandle(delegate: self)
    }
    deinit {
        //TODO: Do we remove the EasyHandle from the session here? This might run on the wrong thread / queue.
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone?) -> Any {
        return self
    }
    
    /// An identifier for this task, assigned by and unique to the owning session
    open let taskIdentifier: Int
    
    /// May be nil if this is a stream task
    /*@NSCopying*/ open let originalRequest: URLRequest?
    
    /// May differ from originalRequest due to http server redirection
    /*@NSCopying*/ open fileprivate(set) var currentRequest: URLRequest? {
        get {
            return taskAttributesIsolation.sync { self._currentRequest }
        }
        //TODO: dispatch_barrier_async
        set { taskAttributesIsolation.async(flags: .barrier) { self._currentRequest = newValue } }
    }
    fileprivate var _currentRequest: URLRequest? = nil
    /*@NSCopying*/ open fileprivate(set) var response: URLResponse? {
        get {
            return taskAttributesIsolation.sync { self._response }
        }
        set { taskAttributesIsolation.async(flags: .barrier) { self._response = newValue } }
    }
    fileprivate var _response: URLResponse? = nil
    
    /* Byte count properties may be zero if no body is expected,
     * or URLSessionTransferSizeUnknown if it is not possible
     * to know how many bytes will be transferred.
     */
    
    /// Number of body bytes already received
   open fileprivate(set) var countOfBytesReceived: Int64 {
        get {
            return taskAttributesIsolation.sync { self._countOfBytesReceived }
        }
        set { taskAttributesIsolation.async(flags: .barrier) { self._countOfBytesReceived = newValue } }
    }
    fileprivate var _countOfBytesReceived: Int64 = 0
    
    /// Number of body bytes already sent */
    open fileprivate(set) var countOfBytesSent: Int64 {
        get {
            return taskAttributesIsolation.sync { self._countOfBytesSent }
        }
        set { taskAttributesIsolation.async(flags: .barrier) { self._countOfBytesSent = newValue } }
    }

    fileprivate var _countOfBytesSent: Int64 = 0
    
    /// Number of body bytes we expect to send, derived from the Content-Length of the HTTP request */
    open fileprivate(set) var countOfBytesExpectedToSend: Int64 = 0
    
    /// Number of byte bytes we expect to receive, usually derived from the Content-Length header of an HTTP response. */
    open fileprivate(set) var countOfBytesExpectedToReceive: Int64 = 0
    
    /// The taskDescription property is available for the developer to
    /// provide a descriptive label for the task.
    open var taskDescription: String?
    
    /* -cancel returns immediately, but marks a task as being canceled.
     * The task will signal -URLSession:task:didCompleteWithError: with an
     * error value of { NSURLErrorDomain, NSURLErrorCancelled }.  In some
     * cases, the task may signal other work before it acknowledges the
     * cancelation.  -cancel may be sent to a task that has been suspended.
     */
    open func cancel() {
        workQueue.sync {
            guard self.state == .running || self.state == .suspended else { return }
            self.state = .canceling
            self.workQueue.async {
                self.internalState = .transferFailed
                let urlError = URLError(_nsError: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
                self.completeTask(withError: urlError)
            }
        }
    }

    /*
     * The current state of the task within the session.
     */
    open var state: URLSessionTask.State {
        get {
            return taskAttributesIsolation.sync { self._state }
        }
        set { taskAttributesIsolation.async(flags: .barrier) { self._state = newValue } }
    }
    fileprivate var _state: URLSessionTask.State = .suspended
    
    /*
     * The error, if any, delivered via -URLSession:task:didCompleteWithError:
     * This property will be nil in the event that no error occured.
     */
    /*@NSCopying*/ open fileprivate(set) var error: Error?
    
    /// Suspend the task.
    ///
    /// Suspending a task will prevent the URLSession from continuing to
    /// load data.  There may still be delegate calls made on behalf of
    /// this task (for instance, to report data received while suspending)
    /// but no further transmissions will be made on behalf of the task
    /// until -resume is sent.  The timeout timer associated with the task
    /// will be disabled while a task is suspended. -suspend and -resume are
    /// nestable.
    open func suspend() {
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
        workQueue.sync {
            self.suspendCount += 1
            guard self.suspendCount < Int.max else { fatalError("Task suspended too many times \(Int.max).") }
            self.updateTaskState()
            
            if self.suspendCount == 1 {
                self.workQueue.async {
                    self.performSuspend()
                }
            }
        }
    }
    /// Resume the task.
    ///
    /// - SeeAlso: `suspend()`
    open func resume() {
        workQueue.sync {
            self.suspendCount -= 1
            guard 0 <= self.suspendCount else { fatalError("Resuming a task that's not suspended. Calls to resume() / suspend() need to be matched.") }
            self.updateTaskState()
            if self.suspendCount == 0 {
                self.workQueue.async {
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
    /// as defined by the constant URLSessionTask.defaultPriority. Two additional
    /// priority levels are provided: URLSessionTask.lowPriority and
    /// URLSessionTask.highPriority, but use is not restricted to these.
    open var priority: Float {
        get {
            return taskAttributesIsolation.sync { self._priority }
        }
        set {
            taskAttributesIsolation.async(flags: .barrier) { self._priority = newValue }
        }
    }
    fileprivate var _priority: Float = URLSessionTask.defaultPriority
}

extension URLSessionTask {
    public enum State : Int {
        /// The task is currently being serviced by the session
        case running
        case suspended
        /// The task has been told to cancel.  The session will receive a URLSession:task:didCompleteWithError: message.
        case canceling
        /// The task has completed and the session will receive no more delegate notifications
        case completed
    }
}

fileprivate extension URLSessionTask {
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

internal extension URLSessionTask {
    /// The is independent of the public `state: URLSessionTask.State`.
    enum _InternalState {
        /// Task has been created, but nothing has been done, yet
        case initial
        /// The easy handle has been fully configured. But it is not added to
        /// the multi handle.
        case transferReady(_TransferState)
        /// The easy handle is currently added to the multi handle
        case transferInProgress(_TransferState)
        /// The transfer completed.
        ///
        /// The easy handle has been removed from the multi handle. This does
        /// not (necessarily mean the task completed. A task that gets
        /// redirected will do multiple transfers.
        case transferCompleted(response: HTTPURLResponse, bodyDataDrain: _TransferState._DataDrain)
        /// The transfer failed.
        ///
        /// Same as `.transferCompleted`, but without response / body data
        case transferFailed
        /// Waiting for the completion handler of the HTTP redirect callback.
        ///
        /// When we tell the delegate that we're about to perform an HTTP
        /// redirect, we need to wait for the delegate to let us know what
        /// action to take.
        case waitingForRedirectCompletionHandler(response: HTTPURLResponse, bodyDataDrain: _TransferState._DataDrain)
        /// Waiting for the completion handler of the 'did receive response' callback.
        ///
        /// When we tell the delegate that we received a response (i.e. when
        /// we received a complete header), we need to wait for the delegate to
        /// let us know what action to take. In this state the easy handle is
        /// paused in order to suspend delegate callbacks.
        case waitingForResponseCompletionHandler(_TransferState)
        /// The task is completed
        ///
        /// Contrast this with `.transferCompleted`.
        case taskCompleted
    }
}

fileprivate extension URLSessionTask._InternalState {
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

internal extension URLSessionTask {
    /// Updates the (public) state based on private / internal state.
    ///
    /// - Note: This must be called on the `workQueue`.
    fileprivate func updateTaskState() {
        func calculateState() -> URLSessionTask.State {
            if case .taskCompleted = internalState {
                return .completed
            }
            if suspendCount == 0 {
                return .running
            } else {
                return .suspended
            }
        }
        state = calculateState()
    }
}

internal extension URLSessionTask {
    enum _Body {
        case none
        case data(DispatchData)
        /// Body data is read from the given file URL
        case file(URL)
        case stream(InputStream)
    }
}
fileprivate extension URLSessionTask._Body {
    enum _Error : Error {
        case fileForBodyDataNotFound
    }
    /// - Returns: The body length, or `nil` for no body (e.g. `GET` request).
    func getBodyLength() throws -> UInt64? {
        switch self {
        case .none:
            return 0
        case .data(let d):
            return UInt64(d.count)
        /// Body data is read from the given file URL
        case .file(let fileURL):
            guard let s = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber else {
                throw _Error.fileForBodyDataNotFound
            }
            return s.uint64Value
        case .stream:
            return nil
        }
    }
}

/// Easy handle related
fileprivate extension URLSessionTask {
    /// Start a new transfer
    func startNewTransfer(with request: URLRequest) {
        currentRequest = request
        guard let url = request.url else { fatalError("No URL in request.") }
        internalState = .transferReady(createTransferState(url: url))
        configureEasyHandle(for: request)
        if suspendCount < 1 {
            performResume()
        }
    }
    /// Creates a new transfer state with the given behaviour:
    func createTransferState(url: URL) -> URLSessionTask._TransferState {
        let drain = createTransferBodyDataDrain()
        switch body {
        case .none:
            return URLSessionTask._TransferState(url: url, bodyDataDrain: drain)
        case .data(let data):
            let source = _HTTPBodyDataSource(data: data)
            return URLSessionTask._TransferState(url: url, bodyDataDrain: drain, bodySource: source)
        case .file(let fileURL):
            let source = _HTTPBodyFileSource(fileURL: fileURL, workQueue: workQueue, dataAvailableHandler: { [weak self] in
                // Unpause the easy handle
                self?.easyHandle.unpauseSend()
                })
            return URLSessionTask._TransferState(url: url, bodyDataDrain: drain, bodySource: source)
        case .stream:
            NSUnimplemented()
        }
        
    }
    /// The data drain.
    ///
    /// This depends on what the delegate / completion handler need.
    fileprivate func createTransferBodyDataDrain() -> URLSessionTask._TransferState._DataDrain {
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
            let fileHandle = try! FileHandle(forWritingTo: tempFileURL)
            return .toFile(tempFileURL, fileHandle) 
        }
    }
    /// Set options on the easy handle to match the given request.
    ///
    /// This performs a series of `curl_easy_setopt()` calls.
    fileprivate func configureEasyHandle(for request: URLRequest) {
        // At this point we will call the equivalent of curl_easy_setopt()
        // to configure everything on the handle. Since we might be re-using
        // a handle, we must be sure to set everything and not rely on defaul
        // values.
        
        //TODO: We could add a strong reference from the easy handle back to
        // its URLSessionTask by means of CURLOPT_PRIVATE -- that would ensure
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

        let customHeaders: [String]
        let headersForRequest = curlHeaders(for: request)
        if ((request.httpMethod == "POST") && (request.value(forHTTPHeaderField: "Content-Type") == nil)) {
            customHeaders = headersForRequest + ["Content-Type:application/x-www-form-urlencoded"]
        } else {
            customHeaders = headersForRequest
        }

        easyHandle.set(customHeaders: customHeaders)

	//TODO: The CURLOPT_PIPEDWAIT option is unavailable on Ubuntu 14.04 (libcurl 7.36)
	//TODO: Introduce something like an #if, if we want to set them here

        //set the request timeout
        //TODO: the timeout value needs to be reset on every data transfer
        let s = session as! URLSession
        let timeoutInterval = Int(s.configuration.timeoutIntervalForRequest) * 1000
        let timeoutHandler = DispatchWorkItem { [weak self] in
            guard let currentTask = self else { fatalError("Timeout on a task that doesn't exist") } //this guard must always pass
            currentTask.internalState = .transferFailed
            let urlError = URLError(_nsError: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
            currentTask.completeTask(withError: urlError)
        }
        easyHandle.timeoutTimer = _TimeoutSource(queue: workQueue, milliseconds: timeoutInterval, handler: timeoutHandler)

        easyHandle.set(automaticBodyDecompression: true)
        easyHandle.set(requestMethod: request.httpMethod ?? "GET")
        if request.httpMethod == "HEAD" {
            easyHandle.set(noBody: true)
        }
    }
}

fileprivate extension URLSessionTask {
    /// These are a list of headers that should be passed to libcurl.
    ///
    /// Headers will be returned as `Accept: text/html` strings for
    /// setting fields, `Accept:` for disabling the libcurl default header, or
    /// `Accept;` for a header with no content. This is the format that libcurl
    /// expects.
    ///
    /// - SeeAlso: https://curl.haxx.se/libcurl/c/CURLOPT_HTTPHEADER.html
    func curlHeaders(for request: URLRequest) -> [String] {
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
        if let language = NSLocale.current.languageCode {
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

fileprivate var userAgentString: String = {
    // Darwin uses something like this: "xctest (unknown version) CFNetwork/760.4.2 Darwin/15.4.0 (x86_64)"
    let info = ProcessInfo.processInfo
    let name = info.processName
    let curlVersion = CFURLSessionCurlVersionInfo()
    //TODO: Should probably use sysctl(3) to get these:
    // kern.ostype: Darwin
    // kern.osrelease: 15.4.0
    //TODO: Use NSBundle to get the version number?
    return "\(name) (unknown version) curl/\(curlVersion.major).\(curlVersion.minor).\(curlVersion.patch)"
}()

fileprivate func errorCode(fileSystemError error: Error) -> Int {
    func fromCocoaErrorCode(_ code: Int) -> Int {
        switch code {
        case CocoaError.fileReadNoSuchFile.rawValue:
            return NSURLErrorFileDoesNotExist
        case CocoaError.fileReadNoPermission.rawValue:
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

fileprivate extension URLSessionTask {
    /// Set request body length.
    ///
    /// An unknown length
    func set(requestBodyLength length: URLSessionTask._RequestBodyLength) {
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
    enum _RequestBodyLength {
        case noBody
        ///
        case length(UInt64)
        /// Will result in a chunked upload
        case unknown
    }
}

extension URLSessionTask: _EasyHandleDelegate {
    func didReceive(data: Data) -> _EasyHandle._Action {
        guard case .transferInProgress(let ts) = internalState else { fatalError("Received body data, but no transfer in progress.") }
        guard ts.isHeaderComplete else { fatalError("Received body data, but the header is not complete, yet.") }
        notifyDelegate(aboutReceivedData: data)
        internalState = .transferInProgress(ts.byAppending(bodyData: data))
        return .proceed
    }

    fileprivate func notifyDelegate(aboutReceivedData data: Data) {
        if case .taskDelegate(let delegate) = session.behaviour(for: self),
            let dataDelegate = delegate as? URLSessionDataDelegate,
            let task = self as? URLSessionDataTask {
            // Forward to the delegate:
            guard let s = session as? URLSession else { fatalError() }
            s.delegateQueue.addOperation {
                dataDelegate.urlSession(s, dataTask: task, didReceive: data)
            }
        } else if case .taskDelegate(let delegate) = session.behaviour(for: self),
            let downloadDelegate = delegate as? URLSessionDownloadDelegate,
            let task = self as? URLSessionDownloadTask {
                guard let s = session as? URLSession else { fatalError() }
                let fileHandle = try! FileHandle(forWritingTo: tempFileURL)
                _ = fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                self.totalDownloaded += data.count
            
                s.delegateQueue.addOperation {
                    downloadDelegate.urlSession(s, downloadTask: task, didWriteData: Int64(data.count), totalBytesWritten: Int64(self.totalDownloaded),
                        totalBytesExpectedToWrite: Int64(self.easyHandle.fileLength))
                }
                if Int(self.easyHandle.fileLength) == totalDownloaded {
                    fileHandle.closeFile()
                    s.delegateQueue.addOperation {
                        downloadDelegate.urlSession(s, downloadTask: task, didFinishDownloadingTo: self.tempFileURL)
                    }
                }
            
        }
    }

    func didReceive(headerData data: Data) -> _EasyHandle._Action {
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

    func fill(writeBuffer buffer: UnsafeMutableBufferPointer<Int8>) -> _EasyHandle._WriteBufferResult {
        guard case .transferInProgress(let ts) = internalState else { fatalError("Requested to fill write buffer, but transfer isn't in progress.") }
        guard let source = ts.requestBodySource else { fatalError("Requested to fill write buffer, but transfer state has no body source.") }
        switch source.getNextChunk(withLength: buffer.count) {
        case .data(let data):
            copyDispatchData(data, infoBuffer: buffer)
            let count = data.count
            assert(count > 0)
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
        guard let request = currentRequest else { fatalError("Transfer completed, but there's no current request.") }
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
    func updateProgressMeter(with propgress: _EasyHandle._Progress) {
        //TODO: Update progress. Note that a single URLSessionTask might
        // perform multiple transfers. The values in `progress` are only for
        // the current transfer.
    }
}

/// State Transfers
extension URLSessionTask {
    func completeTask() {
        guard case .transferCompleted(response: let response, bodyDataDrain: let bodyDataDrain) = internalState else {
            fatalError("Trying to complete the task, but its transfer isn't complete.")
        }
        self.response = response

        //We don't want a timeout to be triggered after this. The timeout timer needs to be cancelled.
        easyHandle.timeoutTimer = nil

        //because we deregister the task with the session on internalState being set to taskCompleted
        //we need to do the latter after the delegate/handler was notified/invoked
        switch session.behaviour(for: self) {
        case .taskDelegate(let delegate):
            guard let s = session as? URLSession else { fatalError() }
            s.delegateQueue.addOperation {
                delegate.urlSession(s, task: self, didCompleteWithError: nil)
                self.internalState = .taskCompleted
            }
        case .noDelegate:
            internalState = .taskCompleted
        case .dataCompletionHandler(let completion):
            guard case .inMemory(let bodyData) = bodyDataDrain else {
                fatalError("Task has data completion handler, but data drain is not in-memory.")
            }

            guard let s = session as? URLSession else { fatalError() }

            var data = Data()
            if let body = bodyData {
                data = Data(bytes: body.bytes, count: body.length)
            }

            s.delegateQueue.addOperation {
                completion(data, response, nil)
                self.internalState = .taskCompleted
                self.session = nil
            }
        case .downloadCompletionHandler(let completion):
            guard case .toFile(let url, let fileHandle?) = bodyDataDrain else {
                fatalError("Task has data completion handler, but data drain is not a file handle.")
            }

            guard let s = session as? URLSession else { fatalError() }
            //The contents are already written, just close the file handle and call the handler
            fileHandle.closeFile()
            
            s.delegateQueue.addOperation {
                completion(url, response, nil) 
                self.internalState = .taskCompleted
                self.session = nil
            }
            
        }
    }
    func completeTask(withError error: Error) {
        self.error = error

        guard case .transferFailed = internalState else {
            fatalError("Trying to complete the task, but its transfer isn't complete / failed.")
        }

        //We don't want a timeout to be triggered after this. The timeout timer needs to be cancelled.
        easyHandle.timeoutTimer = nil

        switch session.behaviour(for: self) {
        case .taskDelegate(let delegate):
            guard let s = session as? URLSession else { fatalError() }
            s.delegateQueue.addOperation {
                delegate.urlSession(s, task: self, didCompleteWithError: error as Error)
                self.internalState = .taskCompleted
            }
        case .noDelegate:
            internalState = .taskCompleted
        case .dataCompletionHandler(let completion):
            guard let s = session as? URLSession else { fatalError() }
            s.delegateQueue.addOperation {
                completion(nil, nil, error)
                self.internalState = .taskCompleted
            }
        case .downloadCompletionHandler(let completion): 
            guard let s = session as? URLSession else { fatalError() }
            s.delegateQueue.addOperation {
                completion(nil, nil, error)
                self.internalState = .taskCompleted
            }
        }
    }
    func failWith(errorCode: Int, request: URLRequest) {
        //TODO: Error handling
        let userInfo: [String : Any]? = request.url.map {
            [
                NSURLErrorFailingURLErrorKey: $0,
                NSURLErrorFailingURLStringErrorKey: $0.absoluteString,
                ]
        }
        let error = URLError(_nsError: NSError(domain: NSURLErrorDomain, code: errorCode, userInfo: userInfo))
        completeTask(withError: error)
    }
    func redirectFor(request: URLRequest) {
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
            
            //TODO: Should the `public response: URLResponse` property be updated
            // before we call delegate API
            
            internalState = .waitingForRedirectCompletionHandler(response: response, bodyDataDrain: bodyDataDrain)
            // We need this ugly cast in order to be able to support `URLSessionTask.init()`
            guard let s = session as? URLSession else { fatalError() }
            s.delegateQueue.addOperation {
                delegate.urlSession(s, task: self, willPerformHTTPRedirection: response, newRequest: request) { [weak self] (request: URLRequest?) in
                    guard let task = self else { return }
                    task.workQueue.async {
                        task.didCompleteRedirectCallback(request)
                    }
                }
            }
        case .noDelegate, .dataCompletionHandler, .downloadCompletionHandler:
            // Follow the redirect.
            startNewTransfer(with: request)
        }
    }
    fileprivate func didCompleteRedirectCallback(_ request: URLRequest?) {
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
fileprivate extension URLSessionTask {
    /// Whenever we receive a response (i.e. a complete header) from libcurl,
    /// this method gets called.
    func didReceiveResponse() {
        guard let dt = self as? URLSessionDataTask else { return }
        guard case .transferInProgress(let ts) = internalState else { fatalError("Transfer not in progress.") }
        guard let response = ts.response else { fatalError("Header complete, but not URL response.") }
        switch session.behaviour(for: self) {
        case .noDelegate:
            break
        case .taskDelegate(let delegate as URLSessionDataDelegate):
            //TODO: There's a problem with libcurl / with how we're using it.
            // We're currently unable to pause the transfer / the easy handle:
            // https://curl.haxx.se/mail/lib-2016-03/0222.html
            //
            // For now, we'll notify the delegate, but won't pause the transfer,
            // and we'll disregard the completion handler:
            guard let s = session as? URLSession else { fatalError() }
            s.delegateQueue.addOperation {
                delegate.urlSession(s, dataTask: dt, didReceive: response, completionHandler: { _ in
                    URLSession.printDebug("warning: Ignoring disposition from completion handler.")
                })
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
    func askDelegateHowToProceedAfterCompleteResponse(_ response: HTTPURLResponse, delegate: URLSessionDataDelegate) {
        // Ask the delegate how to proceed.
        
        // This will pause the easy handle. We need to wait for the
        // delegate before processing any more data.
        guard case .transferInProgress(let ts) = internalState else { fatalError("Transfer not in progress.") }
        internalState = .waitingForResponseCompletionHandler(ts)
        
        let dt = self as! URLSessionDataTask
        
        // We need this ugly cast in order to be able to support `URLSessionTask.init()`
        guard let s = session as? URLSession else { fatalError() }
        s.delegateQueue.addOperation {
            delegate.urlSession(s, dataTask: dt, didReceive: response, completionHandler: { [weak self] disposition in
                guard let task = self else { return }
                task.workQueue.async {
                    task.didCompleteResponseCallback(disposition: disposition)
                }
                })
        }
    }
    /// This gets called (indirectly) when the data task delegates lets us know
    /// how we should proceed after receiving a response (i.e. complete header).
    func didCompleteResponseCallback(disposition: URLSession.ResponseDisposition) {
        guard case .waitingForResponseCompletionHandler(let ts) = internalState else { fatalError("Received response disposition, but we're not waiting for it.") }
        switch disposition {
        case .cancel:
            let error = URLError(_nsError: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
            self.completeTask(withError: error)
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
    enum _CompletionAction {
        case completeTask
        case failWithError(Int)
        case redirectWithRequest(URLRequest)
    }
    
    /// What action to take
    func completionAction(forCompletedRequest request: URLRequest, response: HTTPURLResponse) -> _CompletionAction {
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
    func redirectRequest(for response: HTTPURLResponse, fromRequest: URLRequest) -> URLRequest? {
        //TODO: Do we ever want to redirect for HEAD requests?
        func methodAndURL() -> (String, URL)? {
            guard
                let location = response.value(forHeaderField: .location),
                let targetURL = URL(string: location)
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
        var request = fromRequest
        request.httpMethod = method
        request.url = targetURL
        return request
    }
}


fileprivate extension HTTPURLResponse {
    /// Type safe HTTP header field name(s)
    enum _Field: String {
        /// `Location`
        /// - SeeAlso: RFC 2616 section 14.30 <https://tools.ietf.org/html/rfc2616#section-14.30>
        case location = "Location"
    }
    func value(forHeaderField field: _Field) -> String? {
        return field.rawValue
    }
}

public extension URLSessionTask {
    /// The default URL session task priority, used implicitly for any task you 
    /// have not prioritized. The floating point value of this constant is 0.5.
    public static let defaultPriority: Float = 0.5

    /// A low URL session task priority, with a floating point value above the 
    /// minimum of 0 and below the default value.
    public static let lowPriority: Float = 0.25

    /// A high URL session task priority, with a floating point value above the
    /// default value and below the maximum of 1.0.
    public static let highPriority: Float = 0.75
}

/*
 * An URLSessionDataTask does not provide any additional
 * functionality over an URLSessionTask and its presence is merely
 * to provide lexical differentiation from download and upload tasks.
 */
open class URLSessionDataTask : URLSessionTask {
}

/*
 * An URLSessionUploadTask does not currently provide any additional
 * functionality over an URLSessionDataTask.  All delegate messages
 * that may be sent referencing an URLSessionDataTask equally apply
 * to URLSessionUploadTasks.
 */
open class URLSessionUploadTask : URLSessionDataTask {
}

/*
 * URLSessionDownloadTask is a task that represents a download to
 * local storage.
 */
open class URLSessionDownloadTask : URLSessionTask {
    
    internal var fileLength = -1.0
    
    /* Cancel the download (and calls the superclass -cancel).  If
     * conditions will allow for resuming the download in the future, the
     * callback will be called with an opaque data blob, which may be used
     * with -downloadTaskWithResumeData: to attempt to resume the download.
     * If resume data cannot be created, the completion handler will be
     * called with nil resumeData.
     */
    open func cancel(byProducingResumeData completionHandler: @escaping (Data?) -> Void) { NSUnimplemented() }
}

/*
 * An URLSessionStreamTask provides an interface to perform reads
 * and writes to a TCP/IP stream created via URLSession.  This task
 * may be explicitly created from an URLSession, or created as a
 * result of the appropriate disposition response to a
 * -URLSession:dataTask:didReceiveResponse: delegate message.
 *
 * URLSessionStreamTask can be used to perform asynchronous reads
 * and writes.  Reads and writes are enquened and executed serially,
 * with the completion handler being invoked on the sessions delegate
 * queuee.  If an error occurs, or the task is canceled, all
 * outstanding read and write calls will have their completion
 * handlers invoked with an appropriate error.
 *
 * It is also possible to create InputStream and OutputStream
 * instances from an URLSessionTask by sending
 * -captureStreams to the task.  All outstanding read and writess are
 * completed before the streams are created.  Once the streams are
 * delivered to the session delegate, the task is considered complete
 * and will receive no more messsages.  These streams are
 * disassociated from the underlying session.
 */

open class URLSessionStreamTask : URLSessionTask {
    
    /* Read minBytes, or at most maxBytes bytes and invoke the completion
     * handler on the sessions delegate queue with the data or an error.
     * If an error occurs, any outstanding reads will also fail, and new
     * read requests will error out immediately.
     */
    open func readData(ofMinLength minBytes: Int, maxLength maxBytes: Int, timeout: TimeInterval, completionHandler: @escaping (Data?, Bool, Error?) -> Void) { NSUnimplemented() }
    
    /* Write the data completely to the underlying socket.  If all the
     * bytes have not been written by the timeout, a timeout error will
     * occur.  Note that invocation of the completion handler does not
     * guarantee that the remote side has received all the bytes, only
     * that they have been written to the kernel. */
    open func write(_ data: Data, timeout: TimeInterval, completionHandler: @escaping (Error?) -> Void) { NSUnimplemented() }
    
    /* -captureStreams completes any already enqueued reads
     * and writes, and then invokes the
     * URLSession:streamTask:didBecomeInputStream:outputStream: delegate
     * message. When that message is received, the task object is
     * considered completed and will not receive any more delegate
     * messages. */
    open func captureStreams() { NSUnimplemented() }
    
    /* Enqueue a request to close the write end of the underlying socket.
     * All outstanding IO will complete before the write side of the
     * socket is closed.  The server, however, may continue to write bytes
     * back to the client, so best practice is to continue reading from
     * the server until you receive EOF.
     */
    open func closeWrite() { NSUnimplemented() }
    
    /* Enqueue a request to close the read side of the underlying socket.
     * All outstanding IO will complete before the read side is closed.
     * You may continue writing to the server.
     */
    open func closeRead() { NSUnimplemented() }
    
    /*
     * Begin encrypted handshake.  The hanshake begins after all pending
     * IO has completed.  TLS authentication callbacks are sent to the
     * session's -URLSession:task:didReceiveChallenge:completionHandler:
     */
    open func startSecureConnection() { NSUnimplemented() }
    
    /*
     * Cleanly close a secure connection after all pending secure IO has
     * completed.
     */
    open func stopSecureConnection() { NSUnimplemented() }
}

/* Key in the userInfo dictionary of an NSError received during a failed download. */
public let URLSessionDownloadTaskResumeData: String = "NSURLSessionDownloadTaskResumeData"


extension URLSession {
    static func printDebug(_ text: @autoclosure () -> String) {
        guard enableDebugOutput else { return }
        debugPrint(text())
    }
}

fileprivate let enableLibcurlDebugOutput: Bool = {
    return (ProcessInfo.processInfo.environment["URLSessionDebugLibcurl"] != nil)
}()
fileprivate let enableDebugOutput: Bool = {
    return (ProcessInfo.processInfo.environment["URLSessionDebug"] != nil)
}()
