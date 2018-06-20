// Foundation/URLSession/URLSessionTask.swift - URLSession API
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
/// - SeeAlso: URLSession.swift
///
// -----------------------------------------------------------------------------




import CoreFoundation
import Dispatch

/// A cancelable object that refers to the lifetime
/// of processing a given request.
open class URLSessionTask : NSObject, NSCopying {
    
    public var countOfBytesClientExpectsToReceive: Int64 { NSUnimplemented() }
    public var countOfBytesClientExpectsToSend: Int64 { NSUnimplemented() }
    public var earliestBeginDate: Date? { NSUnimplemented() }
    
    /// How many times the task has been suspended, 0 indicating a running task.
    internal var suspendCount = 1
    internal var session: URLSessionProtocol! //change to nil when task completes
    internal let body: _Body
    fileprivate var _protocol: URLProtocol? = nil
    private let syncQ = DispatchQueue(label: "org.swift.URLSessionTask.SyncQ")
    
    /// All operations must run on this queue.
    internal let workQueue: DispatchQueue 
    
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
        /* make sure we're actually having a serial queue as it's used for synchronization */
        self.workQueue = DispatchQueue.init(label: "org.swift.URLSessionTask.WorkQueue", target: session.workQueue)
        self.taskIdentifier = taskIdentifier
        self.originalRequest = request
        self.body = body
        super.init()
        if session.configuration.protocolClasses != nil {
            guard let protocolClasses = session.configuration.protocolClasses else { fatalError() }
            if let urlProtocolClass = URLProtocol.getProtocolClass(protocols: protocolClasses, request: request) {
                guard let urlProtocol = urlProtocolClass as? URLProtocol.Type else { fatalError() }
                self._protocol = urlProtocol.init(task: self, cachedResponse: nil, client: nil)
            } else {
                guard let protocolClasses = URLProtocol.getProtocols() else { fatalError() }
                if let urlProtocolClass = URLProtocol.getProtocolClass(protocols: protocolClasses, request: request) {
                    guard let urlProtocol = urlProtocolClass as? URLProtocol.Type else { fatalError() }
                    self._protocol = urlProtocol.init(task: self, cachedResponse: nil, client: nil)
                }
            }
        } else {
            guard let protocolClasses = URLProtocol.getProtocols() else { fatalError() }
            if let urlProtocolClass = URLProtocol.getProtocolClass(protocols: protocolClasses, request: request) {
                guard let urlProtocol = urlProtocolClass as? URLProtocol.Type else { fatalError() }
                self._protocol = urlProtocol.init(task: self, cachedResponse: nil, client: nil)
            }
        }
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
    open private(set) var taskIdentifier: Int
    
    /// May be nil if this is a stream task
    /*@NSCopying*/ open private(set) var originalRequest: URLRequest?
    
    /// May differ from originalRequest due to http server redirection
    /*@NSCopying*/ open internal(set) var currentRequest: URLRequest? {
        get {
            return self.syncQ.sync { return self._currentRequest }
        }
        set {
            self.syncQ.sync { self._currentRequest = newValue }
        }
    }
    fileprivate var _currentRequest: URLRequest? = nil
    /*@NSCopying*/ open internal(set) var response: URLResponse? {
        get {
            return self.syncQ.sync { return self._response }
        }
        set {
            self.syncQ.sync { self._response = newValue }
        }
    }
    fileprivate var _response: URLResponse? = nil
    
    /* Byte count properties may be zero if no body is expected,
     * or URLSessionTransferSizeUnknown if it is not possible
     * to know how many bytes will be transferred.
     */
    
    /// Number of body bytes already received
    open internal(set) var countOfBytesReceived: Int64 {
        get {
            return self.syncQ.sync { return self._countOfBytesReceived }
        }
        set {
            self.syncQ.sync { self._countOfBytesReceived = newValue }
        }
    }
    fileprivate var _countOfBytesReceived: Int64 = 0
    
    /// Number of body bytes already sent */
    open internal(set) var countOfBytesSent: Int64 {
        get {
            return self.syncQ.sync { return self._countOfBytesSent }
        }
        set {
            self.syncQ.sync { self._countOfBytesSent = newValue }
        }
    }
    
    fileprivate var _countOfBytesSent: Int64 = 0
    
    /// Number of body bytes we expect to send, derived from the Content-Length of the HTTP request */
    open internal(set) var countOfBytesExpectedToSend: Int64 = 0
    
    /// Number of bytes we expect to receive, usually derived from the Content-Length header of an HTTP response. */
    open internal(set) var countOfBytesExpectedToReceive: Int64 = 0
    
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
                let urlError = URLError(_nsError: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil))
                self.error = urlError
                self._protocol?.stopLoading()
                self._protocol?.client?.urlProtocol(self._protocol!, didFailWithError: urlError)
            }
        }
    }
    
    /*
     * The current state of the task within the session.
     */
    open var state: URLSessionTask.State {
        get {
            return self.syncQ.sync { self._state }
        }
        set {
            self.syncQ.sync { self._state = newValue }
        }
    }
    fileprivate var _state: URLSessionTask.State = .suspended
    
    /*
     * The error, if any, delivered via -URLSession:task:didCompleteWithError:
     * This property will be nil in the event that no error occured.
     */
    /*@NSCopying*/ open internal(set) var error: Error?
    
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
                    self._protocol?.stopLoading()
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
                    if let _protocol = self._protocol {
                        _protocol.startLoading()
                    }
                    else if self.error == nil {
                        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: "unsupported URL"]
                        if let url = self.originalRequest?.url {
                            userInfo[NSURLErrorFailingURLErrorKey] = url
                            userInfo[NSURLErrorFailingURLStringErrorKey] = url.absoluteString
                        }
                        let urlError = URLError(_nsError: NSError(domain: NSURLErrorDomain,
                                                                  code: NSURLErrorUnsupportedURL,
                                                                  userInfo: userInfo))
                        self.error = urlError
                        _ProtocolClient().urlProtocol(task: self, didFailWithError: urlError)
                    }
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
            return self.workQueue.sync { return self._priority }
        }
        set {
            self.workQueue.sync { self._priority = newValue }
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

extension URLSessionTask : ProgressReporting {
    public var progress: Progress {
        NSUnimplemented()
    }
}

internal extension URLSessionTask {
    /// Updates the (public) state based on private / internal state.
    ///
    /// - Note: This must be called on the `workQueue`.
    internal func updateTaskState() {
        func calculateState() -> URLSessionTask.State {
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
internal extension URLSessionTask._Body {
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
    open func cancel(byProducingResumeData completionHandler: @escaping (Data?) -> Void) {
        super.cancel()
        
        /*
         * In Objective-C, this method relies on an Apple-maintained XPC process
         * to manage the bookmarking of partially downloaded data. Therefore, the
         * original behavior cannot be directly ported, here.
         *
         * Instead, we just call the completionHandler directly.
         */
        completionHandler(nil)
    }
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

extension _ProtocolClient : URLProtocolClient {

    func urlProtocol(_ protocol: URLProtocol, didReceive response: URLResponse, cacheStoragePolicy policy: URLCache.StoragePolicy) {
        guard let task = `protocol`.task else { fatalError("Received response, but there's no task.") }
        task.response = response
        let session = task.session as! URLSession
        guard let dataTask = task as? URLSessionDataTask else { return }
        switch session.behaviour(for: task) {
        case .taskDelegate(let delegate as URLSessionDataDelegate):
            session.delegateQueue.addOperation {
                delegate.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: { _ in
                    URLSession.printDebug("warning: Ignoring disposition from completion handler.")
                })
            }
        case .noDelegate, .taskDelegate, .dataCompletionHandler, .downloadCompletionHandler:
            break
        }
    }

    func urlProtocolDidFinishLoading(_ protocol: URLProtocol) {
        guard let task = `protocol`.task else { fatalError() }
        guard let session = task.session as? URLSession else { fatalError() }
        switch session.behaviour(for: task) {
        case .taskDelegate(let delegate):
            if let downloadDelegate = delegate as? URLSessionDownloadDelegate, let downloadTask = task as? URLSessionDownloadTask {
                session.delegateQueue.addOperation {
                    downloadDelegate.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: `protocol`.properties[URLProtocol._PropertyKey.temporaryFileURL] as! URL)
                }
            }
            session.delegateQueue.addOperation {
                delegate.urlSession(session, task: task, didCompleteWithError: nil)
                task.state = .completed
                task.workQueue.async {
                    session.taskRegistry.remove(task)
                }
            }
        case .noDelegate:
            task.state = .completed
            session.taskRegistry.remove(task)
        case .dataCompletionHandler(let completion):
            session.delegateQueue.addOperation {
                completion(`protocol`.properties[URLProtocol._PropertyKey.responseData] as? Data ?? Data(), task.response, nil)
                task.state = .completed
                session.taskRegistry.remove(task)
            }
        case .downloadCompletionHandler(let completion):
            session.delegateQueue.addOperation {
                completion(`protocol`.properties[URLProtocol._PropertyKey.temporaryFileURL] as? URL, task.response, nil)
                task.state = .completed
                session.taskRegistry.remove(task)
            }
        }
        task._protocol = nil
    }

    func urlProtocol(_ protocol: URLProtocol, didCancel challenge: URLAuthenticationChallenge) {
        NSUnimplemented()
    }

    func urlProtocol(_ protocol: URLProtocol, didReceive challenge: URLAuthenticationChallenge) {
        NSUnimplemented()
    }

    func urlProtocol(_ protocol: URLProtocol, didLoad data: Data) {
        `protocol`.properties[.responseData] = data
        guard let task = `protocol`.task else { fatalError() }
        guard let session = task.session as? URLSession else { fatalError() }
        switch session.behaviour(for: task) {
        case .taskDelegate(let delegate):
            let dataDelegate = delegate as? URLSessionDataDelegate
            let dataTask = task as? URLSessionDataTask
            session.delegateQueue.addOperation {
                dataDelegate?.urlSession(session, dataTask: dataTask!, didReceive: data)
            }
        default: return
        }
    }

    func urlProtocol(_ protocol: URLProtocol, didFailWithError error: Error) {
        guard let task = `protocol`.task else { fatalError() }
        urlProtocol(task: task, didFailWithError: error)
    }

    func urlProtocol(task: URLSessionTask, didFailWithError error: Error) {
        guard let session = task.session as? URLSession else { fatalError() }
        switch session.behaviour(for: task) {
        case .taskDelegate(let delegate):
            session.delegateQueue.addOperation {
                delegate.urlSession(session, task: task, didCompleteWithError: error as Error)
                task.state = .completed
                task.workQueue.async {
                    session.taskRegistry.remove(task)
                }
            }
        case .noDelegate:
            task.state = .completed
            session.taskRegistry.remove(task)
        case .dataCompletionHandler(let completion):
            session.delegateQueue.addOperation {
                completion(nil, nil, error)
                task.state = .completed
                task.workQueue.async {
                    session.taskRegistry.remove(task)
                }
            }
        case .downloadCompletionHandler(let completion):
            session.delegateQueue.addOperation {
                completion(nil, nil, error)
                task.state = .completed
                session.taskRegistry.remove(task)
            }
        }
        task._protocol = nil
    }

    func urlProtocol(_ protocol: URLProtocol, cachedResponseIsValid cachedResponse: CachedURLResponse) {
        NSUnimplemented()
    }

    func urlProtocol(_ protocol: URLProtocol, wasRedirectedTo request: URLRequest, redirectResponse: URLResponse) {
        NSUnimplemented()
    }
}

extension URLProtocol {
    enum _PropertyKey: String {
        case responseData
        case temporaryFileURL
    }
}
