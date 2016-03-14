// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/*

 NSURLSession is a replacement API for NSURLConnection.  It provides
 options that affect the policy of, and various aspects of the
 mechanism by which NSURLRequest objects are retrieved from the
 network.

 An NSURLSession may be bound to a delegate object.  The delegate is
 invoked for certain events during the lifetime of a session, such as
 server authentication or determining whether a resource to be loaded
 should be converted into a download.
 
 NSURLSession instances are threadsafe.

 The default NSURLSession uses a system provided delegate and is
 appropriate to use in place of existing code that uses
 +[NSURLConnection sendAsynchronousRequest:queue:completionHandler:]

 An NSURLSession creates NSURLSessionTask objects which represent the
 action of a resource being loaded.  These are analogous to
 NSURLConnection objects but provide for more control and a unified
 delegate model.
 
 NSURLSessionTask objects are always created in a suspended state and
 must be sent the -resume message before they will execute.

 Subclasses of NSURLSessionTask are used to syntactically
 differentiate between data and file downloads.

 An NSURLSessionDataTask receives the resource as a series of calls to
 the URLSession:dataTask:didReceiveData: delegate method.  This is type of
 task most commonly associated with retrieving objects for immediate parsing
 by the consumer.

 An NSURLSessionUploadTask differs from an NSURLSessionDataTask
 in how its instance is constructed.  Upload tasks are explicitly created
 by referencing a file or data object to upload, or by utilizing the
 -URLSession:task:needNewBodyStream: delegate message to supply an upload
 body.

 An NSURLSessionDownloadTask will directly write the response data to
 a temporary file.  When completed, the delegate is sent
 URLSession:downloadTask:didFinishDownloadingToURL: and given an opportunity 
 to move this file to a permanent location in its sandboxed container, or to
 otherwise read the file. If canceled, an NSURLSessionDownloadTask can
 produce a data blob that can be used to resume a download at a later
 time.

 Beginning with iOS 9 and Mac OS X 10.11, NSURLSessionStream is
 available as a task type.  This allows for direct TCP/IP connection
 to a given host and port with optional secure handshaking and
 navigation of proxies.  Data tasks may also be upgraded to a
 NSURLSessionStream task via the HTTP Upgrade: header and appropriate
 use of the pipelining option of NSURLSessionConfiguration.  See RFC
 2817 and RFC 6455 for information about the Upgrade: header, and
 comments below on turning data tasks into stream tasks.
 */

/* DataTask objects receive the payload through zero or more delegate messages */
/* UploadTask objects receive periodic progress updates but do not return a body */
/* DownloadTask objects represent an active download to disk.  They can provide resume data when canceled. */
/* StreamTask objects may be used to create NSInput and NSOutputStreams, or used directly in reading and writing. */

/*

 NSURLSession is not available for i386 targets before Mac OS X 10.10.

 */


// -----------------------------------------------------------------------------
/// # NSURLSession API implementation overview
///
/// ## Design Overview
///
/// This implementation uses libcurl for the HTTP layer implementation. At a
/// high level, the `NSURLSession` keeps a *multi handle*, and each
/// `NSURLSessionTask` has an *easy handle*. This way these two APIs somewhat
/// have a 1-to-1 mapping.
///
/// The `NSURLSessionTask` class is in charge of configuring its *easy handle*
/// and adding it to the owning session’s *multi handle*. Adding / removing
/// the handle effectively resumes / suspends the transfer.
///
/// The `NSURLSessionTask` class has subclasses, but this design puts all the
/// logic into the parent `NSURLSessionTask`.
///
/// Both the `NSURLSession` and `NSURLSessionTask` extensively use helper
/// types to ease testability, separate responsibilities, and improve
/// readability. These types are nested inside the `NSURLSession` and
/// `NSURLSessionTask` to limit their scope. Some of these even have sub-types.
///
/// The session class uses the `NSURLSession.TaskRegistry` to keep track of its
/// tasks.
///
/// The task class uses an `InternalState` type together with `TransferState` to
/// keep track of its state and each transfer’s state -- note that a single task
/// may do multiple transfers, e.g. as the result of a redirect.
///
/// ## Error Handling
///
/// Most libcurl functions either return a `CURLcode` or `CURLMcode` which
/// are represented in Swift as `CFURLSessionEasyCode` and
/// `CFURLSessionMultiCode` respectively. We turn these functions into throwing
/// functions by appending `.asError()` onto their calls. This turns the error
/// code into `Void` but throws the error if it's not `.OK` / zero.
///
/// This is combined with `try!` is almost all places, because such an error
/// indicates a programming error. Hence the pattern used in this code is
///
/// ```
/// try! someFunction().asError()
/// ```
///
/// where `someFunction()` is a function that returns a `CFURLSessionEasyCode`.
///
/// ## Threading
///
/// The NSURLSession has a libdispatch ‘work queue’, and all internal work is
/// done on that queue, such that the code doesn't have to deal with thread
/// safety beyond that. All work inside a `NSURLSessionTask` will run on this
/// work queue, and so will code manipulating the session's *multi handle*.
///
/// Delegate callbacks are, however, done on the passed in
/// `delegateQueue`. And any calls into this API need to switch onto the ‘work
/// queue’ as needed.
///
/// - SeeAlso: https://curl.haxx.se/libcurl/c/threadsafe.html
/// - SeeAlso: NSURLSession+libcurl.swift
///
/// The (publicly accessible) attributes of an `NSURLSessionTask` are made thread
/// safe by using a concurrent libdispatch queue and only doing writes with a
/// barrier while allowing concurrent reads. A single queue is shared for all
/// tasks of a given session for this isolation. C.f. `taskAttributesIsolation`.
///
/// ## HTTP and RFC 2616
///
/// Most of HTTP is defined in [RFC 2616](https://tools.ietf.org/html/rfc2616).
/// While libcurl handles many of these details, some are handled by this
/// NSURLSession implementation.
///
/// ## To Do
///
/// - TODO: Is is not clear if using API that takes a NSURLRequest will override
/// all settings of the NSURLSessionConfiguration or just those that have not
/// explicitly been set.
/// E.g. creating an NSURLRequest will cause it to have the default timeoutInterval
/// of 60 seconds, but should this be used in stead of the configuration's
/// timeoutIntervalForRequest even if the request's timeoutInterval has not
/// been set explicitly?
///
/// - TODO: We could re-use EasyHandles once they're complete. That'd be a
/// performance optimization. Not sure how much that'd help. The NSURLSession
/// would have to keep a pool of unused handles.
///
/// - TODO: Could make `workQueue` concurrent and use a multiple reader / single
/// writer approach if it turns out that there's contention.
// -----------------------------------------------------------------------------



import CoreFoundation
import Dispatch


private var sessionCounter = Int32(0)
private func nextSessionIdentifier() -> Int32 {
    return OSAtomicIncrement32Barrier(&sessionCounter)
}
public let NSURLSessionTransferSizeUnknown: Int64 = -1

public class NSURLSession : NSObject {
    private let _configuration: NSURLSession.Configuration
    private let multiHandle: MultiHandle
    private var nextTaskIdentifier = 1
    internal let workQueue: dispatch_queue_t
    /// This queue is used to make public attributes on `NSURLSessionTask` instances thread safe.
    /// - Note: It's a **concurrent** queue.
    internal let taskAttributesIsolation: dispatch_queue_t
    private let taskRegistry = NSURLSession.TaskRegistry()
    private let identifier: Int32
    
    /*
     * The shared session uses the currently set global NSURLCache,
     * NSHTTPCookieStorage and NSURLCredentialStorage objects.
     */
    public class func shared() -> NSURLSession { NSUnimplemented() }
    
    /*
     * Customization of NSURLSession occurs during creation of a new session.
     * If you only need to use the convenience routines with custom
     * configuration options it is not necessary to specify a delegate.
     * If you do specify a delegate, the delegate will be retained until after
     * the delegate has been sent the URLSession:didBecomeInvalidWithError: message.
     */
    public /*not inherited*/ init(configuration: NSURLSessionConfiguration) {
        initializeLibcurl()
        identifier = nextSessionIdentifier()
        self.workQueue = dispatch_queue_create("NSURLSession<\(identifier)>", DISPATCH_QUEUE_SERIAL)
        self.taskAttributesIsolation = dispatch_queue_create("NSURLSession<\(identifier)>.taskAttributes", DISPATCH_QUEUE_CONCURRENT)
        self.delegateQueue = NSOperationQueue()
        self.delegate = nil
        //TODO: Make sure this one can't be written to?
        // Could create a subclass of NSURLSessionConfiguration that wraps the
        // NSURLSession.Configuration and with fatalError() in all setters.
        self.configuration = configuration.copy() as! NSURLSessionConfiguration
        let c = NSURLSession.Configuration(URLSessionConfiguration: configuration)
        self._configuration = c
        self.multiHandle = MultiHandle(configuration: c, workQueue: workQueue)
    }
    public /*not inherited*/ init(configuration: NSURLSessionConfiguration, delegate: NSURLSessionDelegate?, delegateQueue queue: NSOperationQueue?) {
        initializeLibcurl()
        identifier = nextSessionIdentifier()
        self.workQueue = dispatch_queue_create("NSURLSession<\(identifier)>", DISPATCH_QUEUE_SERIAL)
        self.taskAttributesIsolation = dispatch_queue_create("NSURLSession<\(identifier)>.taskAttributes", DISPATCH_QUEUE_CONCURRENT)
        self.delegateQueue = queue ?? NSOperationQueue()
        self.delegate = delegate
        //TODO: Make sure this one can't be written to?
        // Could create a subclass of NSURLSessionConfiguration that wraps the
        // NSURLSession.Configuration and with fatalError() in all setters.
        self.configuration = configuration.copy() as! NSURLSessionConfiguration
        let c = NSURLSession.Configuration(URLSessionConfiguration: configuration)
        self._configuration = c
        self.multiHandle = MultiHandle(configuration: c, workQueue: workQueue)
    }
    
    public let delegateQueue: NSOperationQueue
    public let delegate: NSURLSessionDelegate?
    public let configuration: NSURLSessionConfiguration
    
    /*
     * The sessionDescription property is available for the developer to
     * provide a descriptive label for the session.
     */
    public var sessionDescription: String?
    
    /* -finishTasksAndInvalidate returns immediately and existing tasks will be allowed
     * to run to completion.  New tasks may not be created.  The session
     * will continue to make delegate callbacks until URLSession:didBecomeInvalidWithError:
     * has been issued. 
     *
     * -finishTasksAndInvalidate and -invalidateAndCancel do not
     * have any effect on the shared session singleton.
     *
     * When invalidating a background session, it is not safe to create another background
     * session with the same identifier until URLSession:didBecomeInvalidWithError: has
     * been issued.
     */
    public func finishTasksAndInvalidate() { NSUnimplemented() }
    
    /* -invalidateAndCancel acts as -finishTasksAndInvalidate, but issues
     * -cancel to all outstanding tasks for this session.  Note task 
     * cancellation is subject to the state of the task, and some tasks may
     * have already have completed at the time they are sent -cancel. 
     */
    public func invalidateAndCancel() { NSUnimplemented() }
    
    public func reset(completionHandler: () -> Void) { NSUnimplemented() } /* empty all cookies, cache and credential stores, removes disk files, issues -flushWithCompletionHandler:. Invokes completionHandler() on the delegate queue if not nil. */

    public func flush(completionHandler: () -> Void)  { NSUnimplemented() }/* flush storage to disk and clear transient network caches.  Invokes completionHandler() on the delegate queue if not nil. */
    
    public func getTasksWithCompletionHandler(completionHandler: ([NSURLSessionDataTask], [NSURLSessionUploadTask], [NSURLSessionDownloadTask]) -> Void)  { NSUnimplemented() }/* invokes completionHandler with outstanding data, upload and download tasks. */
    
    public func getAllTasks(completionHandler: ([NSURLSessionTask]) -> Void)  { NSUnimplemented() }/* invokes completionHandler with all outstanding tasks. */
    
    /* 
     * NSURLSessionTask objects are always created in a suspended state and
     * must be sent the -resume message before they will execute.
     */
    
    /* Creates a data task with the given request.  The request may have a body stream. */
    public func dataTask(with request: NSURLRequest) -> NSURLSessionDataTask {
        return dataTask(with: Request(request), behaviour: .callDelegate)
    }
    
    /* Creates a data task to retrieve the contents of the given URL. */
    public func dataTask(with url: NSURL) -> NSURLSessionDataTask {
        return dataTask(with: Request(url), behaviour: .callDelegate)
    }
    
    /* Creates an upload task with the given request.  The body of the request will be created from the file referenced by fileURL */
    public func uploadTask(with request: NSURLRequest, fromFile fileURL: NSURL) -> NSURLSessionUploadTask {
        let r = NSURLSession.Request(request)
        return uploadTask(with: r, body: .file(fileURL), behaviour: .callDelegate)
    }
    
    /* Creates an upload task with the given request.  The body of the request is provided from the bodyData. */
    public func uploadTask(with request: NSURLRequest, fromData bodyData: NSData) -> NSURLSessionUploadTask {
        let r = NSURLSession.Request(request)
        return uploadTask(with: r, body: .data(createDispatchData(bodyData)), behaviour: .callDelegate)
    }
    
    /* Creates an upload task with the given request.  The previously set body stream of the request (if any) is ignored and the URLSession:task:needNewBodyStream: delegate will be called when the body payload is required. */
    public func uploadTask(withStreamedRequest request: NSURLRequest) -> NSURLSessionUploadTask { NSUnimplemented() }
    
    /* Creates a download task with the given request. */
    public func downloadTask(with request: NSURLRequest) -> NSURLSessionDownloadTask { NSUnimplemented() }
    
    /* Creates a download task to download the contents of the given URL. */
    public func downloadTask(with url: NSURL) -> NSURLSessionDownloadTask { NSUnimplemented() }
    
    /* Creates a download task with the resume data.  If the download cannot be successfully resumed, URLSession:task:didCompleteWithError: will be called. */
    public func downloadTask(withResumeData resumeData: NSData) -> NSURLSessionDownloadTask { NSUnimplemented() }
    
    /* Creates a bidirectional stream task to a given host and port.
     */
    public func streamTask(withHostName hostname: String, port: Int) -> NSURLSessionStreamTask { NSUnimplemented() }
}


// Helpers
private extension NSURLSession {
    enum Request {
        case request(NSURLRequest)
        case url(NSURL)
    }
    func createConfiguredRequest(from request: NSURLSession.Request) -> NSURLRequest {
        let r = request.createMutableURLRequest()
        _configuration.configure(request: r)
        return r
    }
}
extension NSURLSession.Request {
    init(_ url: NSURL) {
        self = .url(url)
    }
    init(_ request: NSURLRequest) {
        self = .request(request)
    }
}
extension NSURLSession.Request {
    func createMutableURLRequest() -> NSMutableURLRequest {
        switch self {
        case .url(let url): return NSMutableURLRequest(url: url)
        case .request(let r): return r.mutableCopy() as! NSMutableURLRequest
        }
    }
}

private extension NSURLSession {
    func createNextTaskIdentifier() -> Int {
        let i = nextTaskIdentifier
        nextTaskIdentifier += 1
        return i
    }
}

private extension NSURLSession {
    /// Create a data task.
    ///
    /// All public methods funnel into this one.
    func dataTask(with request: Request, behaviour: TaskRegistry.Behaviour) -> NSURLSessionDataTask {
        let r = createConfiguredRequest(from: request)
        let i = createNextTaskIdentifier()
        let task = NSURLSessionDataTask(session: self, request: r, taskIdentifier: i)
        dispatch_async(workQueue) {
            self.taskRegistry.add(task, behaviour: behaviour)
        }
        return task
    }
    
    /// Create an upload task.
    ///
    /// All public methods funnel into this one.
    func uploadTask(with request: Request, body: NSURLSessionTask.Body, behaviour: TaskRegistry.Behaviour) -> NSURLSessionUploadTask {
        let r = createConfiguredRequest(from: request)
        let i = createNextTaskIdentifier()
        let task = NSURLSessionUploadTask(session: self, request: r, taskIdentifier: i, body: body)
        dispatch_async(workQueue) {
            self.taskRegistry.add(task, behaviour: behaviour)
        }
        return task
    }
}


/*
 * NSURLSession convenience routines deliver results to
 * a completion handler block.  These convenience routines
 * are not available to NSURLSessions that are configured
 * as background sessions.
 *
 * Task objects are always created in a suspended state and 
 * must be sent the -resume message before they will execute.
 */
extension NSURLSession {
    /*
     * data task convenience methods.  These methods create tasks that
     * bypass the normal delegate calls for response and data delivery,
     * and provide a simple cancelable asynchronous interface to receiving
     * data.  Errors will be returned in the NSURLErrorDomain, 
     * see <Foundation/NSURLError.h>.  The delegate, if any, will still be
     * called for authentication challenges.
     */
    public func dataTask(with request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
        return dataTask(with: Request(request), behaviour: .dataCompletionHandler(completionHandler))
    }
    public func dataTask(with url: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask {
        return dataTask(with: Request(url), behaviour: .dataCompletionHandler(completionHandler))
    }
    
    /*
     * upload convenience method.
     */
    public func uploadTask(with request: NSURLRequest, fromFile fileURL: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionUploadTask { NSUnimplemented() }
    public func uploadTask(with request: NSURLRequest, fromData bodyData: NSData?, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionUploadTask { NSUnimplemented() }
    
    /*
     * download task convenience methods.  When a download successfully
     * completes, the NSURL will point to a file that must be read or
     * copied during the invocation of the completion routine.  The file
     * will be removed automatically.
     */
    public func downloadTask(with request: NSURLRequest, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDownloadTask { NSUnimplemented() }
    public func downloadTask(with url: NSURL, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDownloadTask { NSUnimplemented() }
    public func downloadTask(withResumeData resumeData: NSData, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDownloadTask { NSUnimplemented() }
}

internal extension NSURLSession {
    /// The kind of callback / delegate behaviour of a task.
    ///
    /// This is similar to the `NSURLSession.TaskRegistry.Behaviour`, but it
    /// also encodes the kind of delegate that the session has.
    enum TaskBehaviour {
        /// The session has no delegate, or just a plain `NSURLSessionDelegate`.
        case noDelegate
        /// The session has a delegate of type `NSURLSessionTaskDelegate`
        case taskDelegate(NSURLSessionTaskDelegate)
        /// Default action for all events, except for completion.
        /// - SeeAlso: NSURLSession.TaskRegistry.Behaviour.dataCompletionHandler
        case dataCompletionHandler(NSURLSession.TaskRegistry.DataTaskCompletion)
        /// Default action for all events, except for completion.
        /// - SeeAlso: NSURLSession.TaskRegistry.Behaviour.downloadCompletionHandler
        case downloadCompletionHandler(NSURLSession.TaskRegistry.DownloadTaskCompletion)
    }
    func behaviour(for task: NSURLSessionTask) -> TaskBehaviour {
        switch taskRegistry.behaviour(for: task) {
        case .dataCompletionHandler(let c): return .dataCompletionHandler(c)
        case .downloadCompletionHandler(let c): return .downloadCompletionHandler(c)
        case .callDelegate:
            switch delegate {
            case .none: return .noDelegate
            case .some(let d as NSURLSessionTaskDelegate): return .taskDelegate(d)
            case .some: return .noDelegate
            }
        }
    }
}




internal protocol NSURLSessionProtocol: class {
    func add(handle: NSURLSessionTask.EasyHandle)
    func remove(handle: NSURLSessionTask.EasyHandle)
    func behaviour(for: NSURLSessionTask) -> NSURLSession.TaskBehaviour
}
extension NSURLSession: NSURLSessionProtocol {
    func add(handle: NSURLSessionTask.EasyHandle) {
        multiHandle.add(handle)
    }
    func remove(handle: NSURLSessionTask.EasyHandle) {
        multiHandle.remove(handle)
    }
}
/// This class is only used to allow `NSURLSessionTask.init()` to work.
///
/// - SeeAlso: NSURLSessionTask.init()
final internal class MissingURLSession: NSURLSessionProtocol {
    func add(handle: NSURLSessionTask.EasyHandle) {
        fatalError()
    }
    func remove(handle: NSURLSessionTask.EasyHandle) {
        fatalError()
    }
    func behaviour(for: NSURLSessionTask) -> NSURLSession.TaskBehaviour {
        fatalError()
    }
}
