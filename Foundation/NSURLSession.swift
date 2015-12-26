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

public let NSURLSessionTransferSizeUnknown: Int64 = -1

public class NSURLSession : NSObject {
    
    /*
     * The shared session uses the currently set global NSURLCache,
     * NSHTTPCookieStorage and NSURLCredentialStorage objects.
     */
    public class func sharedSession() -> NSURLSession { NSUnimplemented() }
    
    /*
     * Customization of NSURLSession occurs during creation of a new session.
     * If you only need to use the convenience routines with custom
     * configuration options it is not necessary to specify a delegate.
     * If you do specify a delegate, the delegate will be retained until after
     * the delegate has been sent the URLSession:didBecomeInvalidWithError: message.
     */
    public /*not inherited*/ init(configuration: NSURLSessionConfiguration) { NSUnimplemented() }
    public /*not inherited*/ init(configuration: NSURLSessionConfiguration, delegate: NSURLSessionDelegate?, delegateQueue queue: NSOperationQueue?) { NSUnimplemented() }
    
    public var delegateQueue: NSOperationQueue { NSUnimplemented() }
    public var delegate: NSURLSessionDelegate? { NSUnimplemented() }
    /*@NSCopying*/ public var configuration: NSURLSessionConfiguration { NSUnimplemented() }
    
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
    
    public func resetWithCompletionHandler(completionHandler: () -> Void)  { NSUnimplemented() }/* empty all cookies, cache and credential stores, removes disk files, issues -flushWithCompletionHandler:. Invokes completionHandler() on the delegate queue if not nil. */
    public func flushWithCompletionHandler(completionHandler: () -> Void)  { NSUnimplemented() }/* flush storage to disk and clear transient network caches.  Invokes completionHandler() on the delegate queue if not nil. */
    
    public func getTasksWithCompletionHandler(completionHandler: ([NSURLSessionDataTask], [NSURLSessionUploadTask], [NSURLSessionDownloadTask]) -> Void)  { NSUnimplemented() }/* invokes completionHandler with outstanding data, upload and download tasks. */
    
    public func getAllTasksWithCompletionHandler(completionHandler: ([NSURLSessionTask]) -> Void)  { NSUnimplemented() }/* invokes completionHandler with all outstanding tasks. */
    
    /* 
     * NSURLSessionTask objects are always created in a suspended state and
     * must be sent the -resume message before they will execute.
     */
    
    /* Creates a data task with the given request.  The request may have a body stream. */
    public func dataTaskWithRequest(request: NSURLRequest) -> NSURLSessionDataTask { NSUnimplemented() }
    
    /* Creates a data task to retrieve the contents of the given URL. */
    public func dataTaskWithURL(url: NSURL) -> NSURLSessionDataTask { NSUnimplemented() }
    
    /* Creates an upload task with the given request.  The body of the request will be created from the file referenced by fileURL */
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL) -> NSURLSessionUploadTask { NSUnimplemented() }
    
    /* Creates an upload task with the given request.  The body of the request is provided from the bodyData. */
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData) -> NSURLSessionUploadTask { NSUnimplemented() }
    
    /* Creates an upload task with the given request.  The previously set body stream of the request (if any) is ignored and the URLSession:task:needNewBodyStream: delegate will be called when the body payload is required. */
    public func uploadTaskWithStreamedRequest(request: NSURLRequest) -> NSURLSessionUploadTask { NSUnimplemented() }
    
    /* Creates a download task with the given request. */
    public func downloadTaskWithRequest(request: NSURLRequest) -> NSURLSessionDownloadTask { NSUnimplemented() }
    
    /* Creates a download task to download the contents of the given URL. */
    public func downloadTaskWithURL(url: NSURL) -> NSURLSessionDownloadTask { NSUnimplemented() }
    
    /* Creates a download task with the resume data.  If the download cannot be successfully resumed, URLSession:task:didCompleteWithError: will be called. */
    public func downloadTaskWithResumeData(resumeData: NSData) -> NSURLSessionDownloadTask { NSUnimplemented() }
    
    /* Creates a bidirectional stream task to a given host and port.
     */
    public func streamTaskWithHostName(hostname: String, port: Int) -> NSURLSessionStreamTask { NSUnimplemented() }
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
    public func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask { NSUnimplemented() }
    public func dataTaskWithURL(url: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask { NSUnimplemented() }
    
    /*
     * upload convenience method.
     */
    public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionUploadTask { NSUnimplemented() }
    public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionUploadTask { NSUnimplemented() }
    
    /*
     * download task convenience methods.  When a download successfully
     * completes, the NSURL will point to a file that must be read or
     * copied during the invocation of the completion routine.  The file
     * will be removed automatically.
     */
    public func downloadTaskWithRequest(request: NSURLRequest, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDownloadTask { NSUnimplemented() }
    public func downloadTaskWithURL(url: NSURL, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDownloadTask { NSUnimplemented() }
    public func downloadTaskWithResumeData(resumeData: NSData, completionHandler: (NSURL?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDownloadTask { NSUnimplemented() }
}

public enum NSURLSessionTaskState : Int {
    
    case Running /* The task is currently being serviced by the session */
    case Suspended
    case Canceling /* The task has been told to cancel.  The session will receive a URLSession:task:didCompleteWithError: message. */
    case Completed /* The task has completed and the session will receive no more delegate notifications */
}

/*
 * NSURLSessionTask - a cancelable object that refers to the lifetime
 * of processing a given request.
 */

public class NSURLSessionTask : NSObject, NSCopying {
    
    public override init() {
        NSUnimplemented()
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public var taskIdentifier: Int { NSUnimplemented() } /* an identifier for this task, assigned by and unique to the owning session */
    /*@NSCopying*/ public var originalRequest: NSURLRequest? { NSUnimplemented() } /* may be nil if this is a stream task */
    /*@NSCopying*/ public var currentRequest: NSURLRequest? { NSUnimplemented() } /* may differ from originalRequest due to http server redirection */
    /*@NSCopying*/ public var response: NSURLResponse? { NSUnimplemented() } /* may be nil if no response has been received */
    
    /* Byte count properties may be zero if no body is expected, 
     * or NSURLSessionTransferSizeUnknown if it is not possible 
     * to know how many bytes will be transferred.
     */
    
    /* number of body bytes already received */
    public var countOfBytesReceived: Int64 { NSUnimplemented() }
    
    /* number of body bytes already sent */
    public var countOfBytesSent: Int64 { NSUnimplemented() }
    
    /* number of body bytes we expect to send, derived from the Content-Length of the HTTP request */
    public var countOfBytesExpectedToSend: Int64 { NSUnimplemented() }
    
    /* number of byte bytes we expect to receive, usually derived from the Content-Length header of an HTTP response. */
    public var countOfBytesExpectedToReceive: Int64 { NSUnimplemented() }
    
    /*
     * The taskDescription property is available for the developer to
     * provide a descriptive label for the task.
     */
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
    public var state: NSURLSessionTaskState { NSUnimplemented() }
    
    /*
     * The error, if any, delivered via -URLSession:task:didCompleteWithError:
     * This property will be nil in the event that no error occured.
     */
    /*@NSCopying*/ public var error: NSError? { NSUnimplemented() }
    
    /*
     * Suspending a task will prevent the NSURLSession from continuing to
     * load data.  There may still be delegate calls made on behalf of
     * this task (for instance, to report data received while suspending)
     * but no further transmissions will be made on behalf of the task
     * until -resume is sent.  The timeout timer associated with the task
     * will be disabled while a task is suspended. -suspend and -resume are
     * nestable. 
     */
    public func suspend() { NSUnimplemented() }
    public func resume() { NSUnimplemented() }
    
    /*
     * Sets a scaling factor for the priority of the task. The scaling factor is a
     * value between 0.0 and 1.0 (inclusive), where 0.0 is considered the lowest
     * priority and 1.0 is considered the highest.
     *
     * The priority is a hint and not a hard requirement of task performance. The
     * priority of a task may be changed using this API at any time, but not all
     * protocols support this; in these cases, the last priority that took effect
     * will be used.
     *
     * If no priority is specified, the task will operate with the default priority
     * as defined by the constant NSURLSessionTaskPriorityDefault. Two additional
     * priority levels are provided: NSURLSessionTaskPriorityLow and
     * NSURLSessionTaskPriorityHigh, but use is not restricted to these.
     */
    public var priority: Float
}

public let NSURLSessionTaskPriorityDefault: Float = 0.0 // NSUnimplemented
public let NSURLSessionTaskPriorityLow: Float = 0.0 // NSUnimplemented
public let NSURLSessionTaskPriorityHigh: Float = 0.0 // NSUnimplemented

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
    public func readDataOfMinLength(minBytes: Int, maxLength maxBytes: Int, timeout: NSTimeInterval, completionHandler: (NSData?, Bool, NSError?) -> Void) { NSUnimplemented() }
    
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

/*
 * Configuration options for an NSURLSession.  When a session is
 * created, a copy of the configuration object is made - you cannot
 * modify the configuration of a session after it has been created.
 *
 * The shared session uses the global singleton credential, cache
 * and cookie storage objects.
 *
 * An ephemeral session has no persistent disk storage for cookies,
 * cache or credentials.
 *
 * A background session can be used to perform networking operations
 * on behalf of a suspended application, within certain constraints.
 */

public class NSURLSessionConfiguration : NSObject, NSCopying {
    
    public override init() {
        NSUnimplemented()
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public class func defaultSessionConfiguration() -> NSURLSessionConfiguration { NSUnimplemented() }
    public class func ephemeralSessionConfiguration() -> NSURLSessionConfiguration { NSUnimplemented() }
    public class func backgroundSessionConfigurationWithIdentifier(identifier: String) -> NSURLSessionConfiguration { NSUnimplemented() }
    
    /* identifier for the background session configuration */
    public var identifier: String? { NSUnimplemented() }
    
    /* default cache policy for requests */
    public var requestCachePolicy: NSURLRequestCachePolicy
    
    /* default timeout for requests.  This will cause a timeout if no data is transmitted for the given timeout value, and is reset whenever data is transmitted. */
    public var timeoutIntervalForRequest: NSTimeInterval
    
    /* default timeout for requests.  This will cause a timeout if a resource is not able to be retrieved within a given timeout. */
    public var timeoutIntervalForResource: NSTimeInterval
    
    /* type of service for requests. */
    public var networkServiceType: NSURLRequestNetworkServiceType
    
    /* allow request to route over cellular. */
    public var allowsCellularAccess: Bool
    
    /* allows background tasks to be scheduled at the discretion of the system for optimal performance. */
    public var discretionary: Bool
    
    /* The identifier of the shared data container into which files in background sessions should be downloaded.
     * App extensions wishing to use background sessions *must* set this property to a valid container identifier, or
     * all transfers in that session will fail with NSURLErrorBackgroundSessionRequiresSharedContainer.
     */
    public var sharedContainerIdentifier: String?
    
    /* 
     * Allows the app to be resumed or launched in the background when tasks in background sessions complete
     * or when auth is required. This only applies to configurations created with +backgroundSessionConfigurationWithIdentifier:
     * and the default value is YES.
     */
    
    /* The proxy dictionary, as described by <CFNetwork/CFHTTPStream.h> */
    public var connectionProxyDictionary: [NSObject : AnyObject]?
    
    // TODO: We don't have the SSLProtocol type from Security
    /*
    /* The minimum allowable versions of the TLS protocol, from <Security/SecureTransport.h> */
    public var TLSMinimumSupportedProtocol: SSLProtocol
    
    /* The maximum allowable versions of the TLS protocol, from <Security/SecureTransport.h> */
    public var TLSMaximumSupportedProtocol: SSLProtocol
    */
    
    /* Allow the use of HTTP pipelining */
    public var HTTPShouldUsePipelining: Bool
    
    /* Allow the session to set cookies on requests */
    public var HTTPShouldSetCookies: Bool
    
    /* Policy for accepting cookies.  This overrides the policy otherwise specified by the cookie storage. */
    public var HTTPCookieAcceptPolicy: NSHTTPCookieAcceptPolicy
    
    /* Specifies additional headers which will be set on outgoing requests.
       Note that these headers are added to the request only if not already present. */
    public var HTTPAdditionalHeaders: [NSObject : AnyObject]?
    
    /* The maximum number of simultanous persistent connections per host */
    public var HTTPMaximumConnectionsPerHost: Int
    
    /* The cookie storage object to use, or nil to indicate that no cookies should be handled */
    public var HTTPCookieStorage: NSHTTPCookieStorage?
    
    /* The credential storage object, or nil to indicate that no credential storage is to be used */
    public var URLCredentialStorage: NSURLCredentialStorage?
    
    /* The URL resource cache, or nil to indicate that no caching is to be performed */
    public var URLCache: NSURLCache?
    
    /* Enable extended background idle mode for any tcp sockets created.    Enabling this mode asks the system to keep the socket open
     *  and delay reclaiming it when the process moves to the background (see https://developer.apple.com/library/ios/technotes/tn2277/_index.html) 
     */
    public var shouldUseExtendedBackgroundIdleMode: Bool
    
    /* An optional array of Class objects which subclass NSURLProtocol.
       The Class will be sent +canInitWithRequest: when determining if
       an instance of the class can be used for a given URL scheme.
       You should not use +[NSURLProtocol registerClass:], as that
       method will register your class with the default session rather
       than with an instance of NSURLSession. 
       Custom NSURLProtocol subclasses are not available to background
       sessions.
     */
    public var protocolClasses: [AnyClass]?
}

/*
 * Disposition options for various delegate messages
 */
public enum NSURLSessionAuthChallengeDisposition : Int {
    
    case UseCredential /* Use the specified credential, which may be nil */
    case PerformDefaultHandling /* Default handling for the challenge - as if this delegate were not implemented; the credential parameter is ignored. */
    case CancelAuthenticationChallenge /* The entire request will be canceled; the credential parameter is ignored. */
    case RejectProtectionSpace /* This challenge is rejected and the next authentication protection space should be tried; the credential parameter is ignored. */
}

public enum NSURLSessionResponseDisposition : Int {
    
    case Cancel /* Cancel the load, this is the same as -[task cancel] */
    case Allow /* Allow the load to continue */
    case BecomeDownload /* Turn this request into a download */
    case BecomeStream /* Turn this task into a stream task */
}

/*
 * NSURLSessionDelegate specifies the methods that a session delegate
 * may respond to.  There are both session specific messages (for
 * example, connection based auth) as well as task based messages.
 */

/*
 * Messages related to the URL session as a whole
 */
public protocol NSURLSessionDelegate : NSObjectProtocol {
    
    /* The last message a session receives.  A session will only become
     * invalid because of a systemic error or when it has been
     * explicitly invalidated, in which case the error parameter will be nil.
     */
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?)
    
    /* If implemented, when a connection level authentication challenge
     * has occurred, this delegate will be given the opportunity to
     * provide authentication credentials to the underlying
     * connection. Some types of authentication will apply to more than
     * one request on a given connection to a server (SSL Server Trust
     * challenges).  If this delegate message is not implemented, the 
     * behavior will be to use the default handling, which may involve user
     * interaction. 
     */
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
}

extension NSURLSessionDelegate {
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) { }
    func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) { }
}

/* If an application has received an
 * -application:handleEventsForBackgroundURLSession:completionHandler:
 * message, the session delegate will receive this message to indicate
 * that all messages previously enqueued for this session have been
 * delivered.  At this time it is safe to invoke the previously stored
 * completion handler, or to begin any internal updates that will
 * result in invoking the completion handler.
 */

/*
 * Messages related to the operation of a specific task.
 */
public protocol NSURLSessionTaskDelegate : NSURLSessionDelegate {
    
    /* An HTTP request is attempting to perform a redirection to a different
     * URL. You must invoke the completion routine to allow the
     * redirection, allow the redirection with a modified request, or
     * pass nil to the completionHandler to cause the body of the redirection 
     * response to be delivered as the payload of this request. The default
     * is to follow redirections. 
     *
     * For tasks in background sessions, redirections will always be followed and this method will not be called.
     */
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void)
    
    /* The task has received a request specific authentication challenge.
     * If this delegate is not implemented, the session specific authentication challenge
     * will *NOT* be called and the behavior will be the same as using the default handling
     * disposition. 
     */
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
    
    /* Sent if a task requires a new, unopened body stream.  This may be
     * necessary when authentication has failed for any request that
     * involves a body stream. 
     */
    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void)
    
    /* Sent periodically to notify the delegate of upload progress.  This
     * information is also available as properties of the task.
     */
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    
    /* Sent as the last message related to a specific task.  Error may be
     * nil, which implies that no error occurred and this task is complete. 
     */
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
}

extension NSURLSessionTaskDelegate {
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) { }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) { }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) { }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) { }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) { }
}

/*
 * Messages related to the operation of a task that delivers data
 * directly to the delegate.
 */
public protocol NSURLSessionDataDelegate : NSURLSessionTaskDelegate {
    
    /* The task has received a response and no further messages will be
     * received until the completion block is called. The disposition
     * allows you to cancel a request or to turn a data task into a
     * download task. This delegate message is optional - if you do not
     * implement it, you can get the response as a property of the task.
     *
     * This method will not be called for background upload tasks (which cannot be converted to download tasks).
     */
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void)
    
    /* Notification that a data task has become a download task.  No
     * future messages will be sent to the data task.
     */
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask)
    
    /*
     * Notification that a data task has become a bidirectional stream
     * task.  No future messages will be sent to the data task.  The newly
     * created streamTask will carry the original request and response as
     * properties.
     *
     * For requests that were pipelined, the stream object will only allow
     * reading, and the object will immediately issue a
     * -URLSession:writeClosedForStream:.  Pipelining can be disabled for
     * all requests in a session, or by the NSURLRequest
     * HTTPShouldUsePipelining property.
     *
     * The underlying connection is no longer considered part of the HTTP
     * connection cache and won't count against the total number of
     * connections per host.
     */
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeStreamTask streamTask: NSURLSessionStreamTask)
    
    /* Sent when data is available for the delegate to consume.  It is
     * assumed that the delegate will retain and not copy the data.  As
     * the data may be discontiguous, you should use 
     * [NSData enumerateByteRangesUsingBlock:] to access it.
     */
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData)
    
    /* Invoke the completion routine with a valid NSCachedURLResponse to
     * allow the resulting data to be cached, or pass nil to prevent
     * caching. Note that there is no guarantee that caching will be
     * attempted for a given resource, and you should not rely on this
     * message to receive the resource data.
     */
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void)
}

extension NSURLSessionDataDelegate {

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) { }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) { }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeStreamTask streamTask: NSURLSessionStreamTask) { }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) { }
}

/*
 * Messages related to the operation of a task that writes data to a
 * file and notifies the delegate upon completion.
 */
public protocol NSURLSessionDownloadDelegate : NSURLSessionTaskDelegate {
    
    /* Sent when a download task that has completed a download.  The delegate should 
     * copy or move the file at the given location to a new location as it will be 
     * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
     * still be called.
     */
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)
    
    /* Sent periodically to notify the delegate of download progress. */
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    
    /* Sent when a download has been resumed. If a download failed with an
     * error, the -userInfo dictionary of the error will contain an
     * NSURLSessionDownloadTaskResumeData key, whose value is the resume
     * data. 
     */
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64)
}

extension NSURLSessionDownloadDelegate {
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) { }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) { }

}

public protocol NSURLSessionStreamDelegate : NSURLSessionTaskDelegate {
    
    /* Indiciates that the read side of a connection has been closed.  Any
     * outstanding reads complete, but future reads will immediately fail.
     * This may be sent even when no reads are in progress. However, when
     * this delegate message is received, there may still be bytes
     * available.  You only know that no more bytes are available when you
     * are able to read until EOF. */
    func URLSession(session: NSURLSession, readClosedForStreamTask streamTask: NSURLSessionStreamTask)
    
    /* Indiciates that the write side of a connection has been closed.
     * Any outstanding writes complete, but future writes will immediately
     * fail.
     */
    func URLSession(session: NSURLSession, writeClosedForStreamTask streamTask: NSURLSessionStreamTask)
    
    /* A notification that the system has determined that a better route
     * to the host has been detected (eg, a wi-fi interface becoming
     * available.)  This is a hint to the delegate that it may be
     * desirable to create a new task for subsequent work.  Note that
     * there is no guarantee that the future task will be able to connect
     * to the host, so callers should should be prepared for failure of
     * reads and writes over any new interface. */
    func URLSession(session: NSURLSession, betterRouteDiscoveredForStreamTask streamTask: NSURLSessionStreamTask)
    
    /* The given task has been completed, and unopened NSInputStream and
     * NSOutputStream objects are created from the underlying network
     * connection.  This will only be invoked after all enqueued IO has
     * completed (including any necessary handshakes.)  The streamTask
     * will not receive any further delegate messages.
     */
    func URLSession(session: NSURLSession, streamTask: NSURLSessionStreamTask, didBecomeInputStream inputStream: NSInputStream, outputStream: NSOutputStream)
}

extension NSURLSessionStreamDelegate {
    func URLSession(session: NSURLSession, readClosedForStreamTask streamTask: NSURLSessionStreamTask) { }
    
    func URLSession(session: NSURLSession, writeClosedForStreamTask streamTask: NSURLSessionStreamTask) { }
    
    func URLSession(session: NSURLSession, betterRouteDiscoveredForStreamTask streamTask: NSURLSessionStreamTask) { }
    
    func URLSession(session: NSURLSession, streamTask: NSURLSessionStreamTask, didBecomeInputStream inputStream: NSInputStream, outputStream: NSOutputStream) { }
}

/* Key in the userInfo dictionary of an NSError received during a failed download. */
public let NSURLSessionDownloadTaskResumeData: String = "" // NSUnimplemented
