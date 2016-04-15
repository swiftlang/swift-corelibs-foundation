// Foundation/NSURLSession/NSURLSessionDelegate.swift - NSURLSession API
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



/*
 * Disposition options for various delegate messages
 */
public enum NSURLSessionAuthChallengeDisposition : Int {
    
    case useCredential /* Use the specified credential, which may be nil */
    case performDefaultHandling /* Default handling for the challenge - as if this delegate were not implemented; the credential parameter is ignored. */
    case cancelAuthenticationChallenge /* The entire request will be canceled; the credential parameter is ignored. */
    case rejectProtectionSpace /* This challenge is rejected and the next authentication protection space should be tried; the credential parameter is ignored. */
}

public enum NSURLSessionResponseDisposition : Int {
    
    case cancel /* Cancel the load, this is the same as -[task cancel] */
    case allow /* Allow the load to continue */
    case becomeDownload /* Turn this request into a download */
    case becomeStream /* Turn this task into a stream task */
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
    func urlSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?)
    
    /* If implemented, when a connection level authentication challenge
     * has occurred, this delegate will be given the opportunity to
     * provide authentication credentials to the underlying
     * connection. Some types of authentication will apply to more than
     * one request on a given connection to a server (SSL Server Trust
     * challenges).  If this delegate message is not implemented, the
     * behavior will be to use the default handling, which may involve user
     * interaction.
     */
    func urlSession(session: NSURLSession, didReceive challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
}

extension NSURLSessionDelegate {
    func urlSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) { }
    func urlSession(session: NSURLSession, didReceive challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) { }
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
    func urlSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void)
    
    /* The task has received a request specific authentication challenge.
     * If this delegate is not implemented, the session specific authentication challenge
     * will *NOT* be called and the behavior will be the same as using the default handling
     * disposition.
     */
    func urlSession(session: NSURLSession, task: NSURLSessionTask, didReceive challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
    
    /* Sent if a task requires a new, unopened body stream.  This may be
     * necessary when authentication has failed for any request that
     * involves a body stream.
     */
    func urlSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void)
    
    /* Sent periodically to notify the delegate of upload progress.  This
     * information is also available as properties of the task.
     */
    func urlSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64)
    
    /* Sent as the last message related to a specific task.  Error may be
     * nil, which implies that no error occurred and this task is complete.
     */
    func urlSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
}

extension NSURLSessionTaskDelegate {
    func urlSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        completionHandler(request)
    }
    
    func urlSession(session: NSURLSession, task: NSURLSessionTask, didReceive challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        completionHandler(nil)
    }
    
    func urlSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) { }
    
    func urlSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) { }
}

/*
 * Messages related to the operation of a task that delivers data
 * directly to the delegate.
 */
public protocol NSURLSessionDataDelegate : NSURLSessionTaskDelegate {
    
    /// The task has received a response and no further messages will be
    /// received until the completion block is called. The disposition
    /// allows you to cancel a request or to turn a data task into a
    /// download task. This delegate message is optional - if you do not
    /// implement it, you can get the response as a property of the task.
    ///
    /// - Note: This method will not be called for background upload tasks
    /// (which cannot be converted to download tasks).
    /// - Bug: This will currently not wait for the completion handler to run,
    /// and it will ignore anything passed to the completion handler.
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceive response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void)
    
    /* Notification that a data task has become a download task.  No
     * future messages will be sent to the data task.
     */
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecome downloadTask: NSURLSessionDownloadTask)
    
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
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecome streamTask: NSURLSessionStreamTask)
    
    /* Sent when data is available for the delegate to consume.  It is
     * assumed that the delegate will retain and not copy the data.  As
     * the data may be discontiguous, you should use
     * [NSData enumerateByteRangesUsingBlock:] to access it.
     */
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceive data: NSData)
    
    /* Invoke the completion routine with a valid NSCachedURLResponse to
     * allow the resulting data to be cached, or pass nil to prevent
     * caching. Note that there is no guarantee that caching will be
     * attempted for a given resource, and you should not rely on this
     * message to receive the resource data.
     */
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void)
}

extension NSURLSessionDataDelegate {
    
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceive response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) { }
    
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecome downloadTask: NSURLSessionDownloadTask) { }
    
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecome streamTask: NSURLSessionStreamTask) { }
    
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceive data: NSData) { }
    
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) { }
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
    func urlSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingTo location: NSURL)
    
    /* Sent periodically to notify the delegate of download progress. */
    func urlSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    
    /* Sent when a download has been resumed. If a download failed with an
     * error, the -userInfo dictionary of the error will contain an
     * NSURLSessionDownloadTaskResumeData key, whose value is the resume
     * data.
     */
    func urlSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64)
}

extension NSURLSessionDownloadDelegate {
    func urlSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) { }
    
    func urlSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) { }
}

public protocol NSURLSessionStreamDelegate : NSURLSessionTaskDelegate {
    
    /* Indiciates that the read side of a connection has been closed.  Any
     * outstanding reads complete, but future reads will immediately fail.
     * This may be sent even when no reads are in progress. However, when
     * this delegate message is received, there may still be bytes
     * available.  You only know that no more bytes are available when you
     * are able to read until EOF. */
    func urlSession(session: NSURLSession, readClosedFor streamTask: NSURLSessionStreamTask)
    
    /* Indiciates that the write side of a connection has been closed.
     * Any outstanding writes complete, but future writes will immediately
     * fail.
     */
    func urlSession(session: NSURLSession, writeClosedFor streamTask: NSURLSessionStreamTask)
    
    /* A notification that the system has determined that a better route
     * to the host has been detected (eg, a wi-fi interface becoming
     * available.)  This is a hint to the delegate that it may be
     * desirable to create a new task for subsequent work.  Note that
     * there is no guarantee that the future task will be able to connect
     * to the host, so callers should should be prepared for failure of
     * reads and writes over any new interface. */
    func urlSession(session: NSURLSession, betterRouteDiscoveredFor streamTask: NSURLSessionStreamTask)
    
    /* The given task has been completed, and unopened NSInputStream and
     * NSOutputStream objects are created from the underlying network
     * connection.  This will only be invoked after all enqueued IO has
     * completed (including any necessary handshakes.)  The streamTask
     * will not receive any further delegate messages.
     */
    func urlSession(session: NSURLSession, streamTask: NSURLSessionStreamTask, didBecome inputStream: NSInputStream, outputStream: NSOutputStream)
}

extension NSURLSessionStreamDelegate {
    func urlSession(session: NSURLSession, readClosedFor streamTask: NSURLSessionStreamTask) { }
    
    func urlSession(session: NSURLSession, writeClosedFor streamTask: NSURLSessionStreamTask) { }
    
    func urlSession(session: NSURLSession, betterRouteDiscoveredFor streamTask: NSURLSessionStreamTask) { }
    
    func urlSession(session: NSURLSession, streamTask: NSURLSessionStreamTask, didBecome inputStream: NSInputStream, outputStream: NSOutputStream) { }
}
