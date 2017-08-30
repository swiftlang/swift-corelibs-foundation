// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation
import Dispatch

internal class _HTTPURLProtocol: URLProtocol {

    fileprivate var easyHandle: _EasyHandle!
    fileprivate lazy var tempFileURL: URL = {
        let fileName = NSTemporaryDirectory() + NSUUID().uuidString + ".tmp"
        _ = FileManager.default.createFile(atPath: fileName, contents: nil)
        return URL(fileURLWithPath: fileName)
    }()

    public required init(task: URLSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        self.internalState = _InternalState.initial
        super.init(request: task.originalRequest!, cachedResponse: cachedResponse, client: client)
        self.task = task
        self.easyHandle = _EasyHandle(delegate: self)
    }

    public required init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        self.internalState = _InternalState.initial
        super.init(request: request, cachedResponse: cachedResponse, client: client)
        self.easyHandle = _EasyHandle(delegate: self)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard request.url?.scheme == "http" || request.url?.scheme == "https" else { return false }
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        resume()
    }

    override func stopLoading() {
        if task?.state == .suspended {
            suspend()
        } else {
            self.internalState = .transferFailed
            guard let error = self.task?.error else { fatalError() }
            completeTask(withError: error)
        }
    }

    /// The internal state that the task is in.
    ///
    /// Setting this value will also add / remove the easy handle.
    /// It is independt of the `state: URLSessionTask.State`. The
    /// `internalState` tracks the state of transfers / waiting for callbacks.
    /// The `state` tracks the overall state of the task (running vs.
    /// completed).
    fileprivate var internalState: _InternalState {
        // We manage adding / removing the easy handle and pausing / unpausing
        // here at a centralized place to make sure the internal state always
        // matches up with the state of the easy handle being added and paused.
        willSet {
            if !internalState.isEasyHandlePaused && newValue.isEasyHandlePaused {
                fatalError("Need to solve pausing receive.")
            }
            if internalState.isEasyHandleAddedToMultiHandle && !newValue.isEasyHandleAddedToMultiHandle {
                task?.session.remove(handle: easyHandle)
            }
        }
        didSet {
            if !oldValue.isEasyHandleAddedToMultiHandle && internalState.isEasyHandleAddedToMultiHandle {
                task?.session.add(handle: easyHandle)
            }
            if oldValue.isEasyHandlePaused && !internalState.isEasyHandlePaused {
                fatalError("Need to solve pausing receive.")
            }
        }
    }
}

fileprivate extension _HTTPURLProtocol {

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
        easyHandle.set(debugOutputOn: enableLibcurlDebugOutput, task: task!)
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
            switch (task?.body, try task?.body.getBodyLength()) {
            case (.none, _):
                set(requestBodyLength: .noBody)
            case (_, .some(let length)):
                set(requestBodyLength: .length(length))
                task!.countOfBytesExpectedToSend = Int64(length)
            case (_, .none):
                set(requestBodyLength: .unknown)
            }
        } catch let e {
            // Fail the request here.
            // TODO: We have multiple options:
            //     NSURLErrorNoPermissionsToReadFile
            //     NSURLErrorFileDoesNotExist
            self.internalState = .transferFailed
            failWith(errorCode: errorCode(fileSystemError: e), request: request)
            return
        }

        // HTTP Options:
        easyHandle.set(followLocation: false)

        // The httpAdditionalHeaders from session configuration has to be added to the request.
        // The request.allHTTPHeaders can override the httpAdditionalHeaders elements. Add the
        // httpAdditionalHeaders from session configuration first and then append/update the
        // request.allHTTPHeaders so that request.allHTTPHeaders can override httpAdditionalHeaders.

        let httpSession = self.task?.session as! URLSession
        var httpHeaders: [AnyHashable : Any]?

        if let hh = httpSession.configuration.httpAdditionalHeaders {
            httpHeaders = hh
        }

        if let hh = self.task?.originalRequest?.allHTTPHeaderFields {
            if httpHeaders == nil {
                httpHeaders = hh
            } else {
                hh.forEach {
                    httpHeaders![$0] = $1
                }
            }
        }
        let customHeaders: [String]
        let headersForRequest = curlHeaders(for: httpHeaders)
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

        var timeoutInterval = Int(httpSession.configuration.timeoutIntervalForRequest) * 1000
        if request.isTimeoutIntervalSet {
           timeoutInterval = Int(request.timeoutInterval) * 1000
        }
        let timeoutHandler = DispatchWorkItem { [weak self] in
            guard let _ = self?.task else { fatalError("Timeout on a task that doesn't exist") } //this guard must always pass
            self?.internalState = .transferFailed
            let urlError = URLError(_nsError: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
            self?.completeTask(withError: urlError)
            self?.client?.urlProtocol(self!, didFailWithError: urlError)
        }
	guard let task = self.task else { fatalError() }
        easyHandle.timeoutTimer = _TimeoutSource(queue: task.workQueue, milliseconds: timeoutInterval, handler: timeoutHandler)

        easyHandle.set(automaticBodyDecompression: true)
        easyHandle.set(requestMethod: request.httpMethod ?? "GET")
        if request.httpMethod == "HEAD" {
            easyHandle.set(noBody: true)
        }
    }

    /// These are a list of headers that should be passed to libcurl.
    ///
    /// Headers will be returned as `Accept: text/html` strings for
    /// setting fields, `Accept:` for disabling the libcurl default header, or
    /// `Accept;` for a header with no content. This is the format that libcurl
    /// expects.
    ///
    /// - SeeAlso: https://curl.haxx.se/libcurl/c/CURLOPT_HTTPHEADER.html
    func curlHeaders(for httpHeaders: [AnyHashable : Any]?) -> [String] {
        var result: [String] = []
        var names = Set<String>()
        if httpHeaders != nil {
            let hh = httpHeaders as! [String:String]
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
        if case .none = task?.body {
            return []
        } else {
            return ["Expect"]
        }
    }
}

fileprivate extension _HTTPURLProtocol {
    /// Set request body length.
    ///
    /// An unknown length
    func set(requestBodyLength length: _HTTPURLProtocol._RequestBodyLength) {
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

fileprivate var userAgentString: String = {
    // Darwin uses something like this: "xctest (unknown version) CFNetwork/760.4.2 Darwin/15.4.0 (x86_64)"
    let info = ProcessInfo.processInfo
    let name = info.processName
    let curlVersion = CFURLSessionCurlVersionInfo()
    //TODO: Should probably use sysctl(3) to get these:
    // kern.ostype: Darwin
    // kern.osrelease: 15.4.0
    //TODO: Use Bundle to get the version number?
    return "\(name) (unknown version) curl/\(curlVersion.major).\(curlVersion.minor).\(curlVersion.patch)"
}()

fileprivate let enableLibcurlDebugOutput: Bool = {
    return (ProcessInfo.processInfo.environment["URLSessionDebugLibcurl"] != nil)
}()
fileprivate let enableDebugOutput: Bool = {
    return (ProcessInfo.processInfo.environment["URLSessionDebug"] != nil)
}()

extension URLSession {
    static func printDebug(_ text: @autoclosure () -> String) {
        guard enableDebugOutput else { return }
        debugPrint(text())
    }
}

internal extension _HTTPURLProtocol {
    enum _Body {
        case none
        case data(DispatchData)
        /// Body data is read from the given file URL
        case file(URL)
        case stream(InputStream)
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
        self.client?.urlProtocol(self, didFailWithError: error)
    }
}

fileprivate extension _HTTPURLProtocol._Body {
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

internal extension _HTTPURLProtocol {
    /// The data drain.
    ///
    /// This depends on what the delegate / completion handler need.
    fileprivate func createTransferBodyDataDrain() -> _DataDrain {
        guard let task = task else { fatalError() }
        let s = task.session as! URLSession
        switch s.behaviour(for: task) {
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
            let fileHandle = try! FileHandle(forWritingTo: self.tempFileURL)
            return .toFile(self.tempFileURL, fileHandle)
        }
    }
}

extension _HTTPURLProtocol {

    /// Creates a new transfer state with the given behaviour:
    func createTransferState(url: URL, workQueue: DispatchQueue) -> _HTTPTransferState {
        let drain = createTransferBodyDataDrain()
        guard let t = task else { fatalError("Cannot create transfer state") }
        switch t.body {
        case .none:
            return _HTTPTransferState(url: url, bodyDataDrain: drain)
        case .data(let data):
            let source = _HTTPBodyDataSource(data: data)
            return _HTTPTransferState(url: url, bodyDataDrain: drain, bodySource: source)
        case .file(let fileURL):
            let source = _HTTPBodyFileSource(fileURL: fileURL, workQueue: workQueue, dataAvailableHandler: { [weak self] in
                // Unpause the easy handle
                self?.easyHandle.unpauseSend()
            })
            return _HTTPTransferState(url: url, bodyDataDrain: drain, bodySource: source)
        case .stream:
            NSUnimplemented()
        }
    }
}

extension _HTTPURLProtocol: _EasyHandleDelegate {
    
    func didReceive(data: Data) -> _EasyHandle._Action {
        guard case .transferInProgress(var ts) = internalState else { fatalError("Received body data, but no transfer in progress.") }
        if !ts.isHeaderComplete {
            ts.response = HTTPURLResponse(url: ts.url, statusCode: 200, httpVersion: "HTTP/0.9", headerFields: [:])
            /* we received body data before CURL tells us that the headers are complete, that happens for HTTP/0.9 simple responses, see
               - https://www.w3.org/Protocols/HTTP/1.0/spec.html#Message-Types
               - https://github.com/curl/curl/issues/467
            */
        }
        notifyDelegate(aboutReceivedData: data)
        internalState = .transferInProgress(ts.byAppending(bodyData: data))
        return .proceed
    }

    fileprivate func notifyDelegate(aboutReceivedData data: Data) {
        guard let t = self.task else { fatalError("Cannot notify") }
        if case .taskDelegate(let delegate) = t.session.behaviour(for: self.task!),
            let _ = delegate as? URLSessionDataDelegate,
            let _ = self.task as? URLSessionDataTask {
            // Forward to protocol client:
            self.client?.urlProtocol(self, didLoad: data)
        } else if case .taskDelegate(let delegate) = t.session.behaviour(for: self.task!),
            let downloadDelegate = delegate as? URLSessionDownloadDelegate,
            let task = self.task as? URLSessionDownloadTask {
            guard let s = self.task?.session as? URLSession else { fatalError() }
            let fileHandle = try! FileHandle(forWritingTo: self.tempFileURL)
            _ = fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            task.countOfBytesReceived += Int64(data.count)
            
            s.delegateQueue.addOperation {
                downloadDelegate.urlSession(s, downloadTask: task, didWriteData: Int64(data.count), totalBytesWritten: task.countOfBytesReceived,
                                            totalBytesExpectedToWrite: task.countOfBytesExpectedToReceive)
            }
            if task.countOfBytesExpectedToReceive == task.countOfBytesReceived {
                fileHandle.closeFile()
                self.properties[.temporaryFileURL] = self.tempFileURL
            }
        }
    }

    func didReceive(headerData data: Data, contentLength: Int64) -> _EasyHandle._Action {
        guard case .transferInProgress(let ts) = internalState else { fatalError("Received header data, but no transfer in progress.") }
        guard let task = task else { fatalError("Received header data but no task available.") }
        task.countOfBytesExpectedToReceive = contentLength > 0 ? contentLength : NSURLSessionTransferSizeUnknown
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

    fileprivate func notifyDelegate(aboutUploadedData count: Int64) {
        guard let task = self.task as? URLSessionUploadTask,
            let session = self.task?.session as? URLSession,
            case .taskDelegate(let delegate) = session.behaviour(for: task) else { return }
        task.countOfBytesSent += count
        session.delegateQueue.addOperation {
            delegate.urlSession(session, task: task, didSendBodyData: count,
                totalBytesSent: task.countOfBytesSent, totalBytesExpectedToSend: task.countOfBytesExpectedToSend)
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
            notifyDelegate(aboutUploadedData: Int64(count))
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
        guard let request = task?.currentRequest else { fatalError("Transfer completed, but there's no current request.") }
        guard errorCode == nil else {
            internalState = .transferFailed
            failWith(errorCode: errorCode!, request: request)
            return
        }

        if let response = task?.response as? HTTPURLResponse {
            var transferState = ts
            transferState.response = response
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

extension _HTTPURLProtocol {
    /// The is independent of the public `state: URLSessionTask.State`.
    enum _InternalState {
        /// Task has been created, but nothing has been done, yet
        case initial
        /// The easy handle has been fully configured. But it is not added to
        /// the multi handle.
        case transferReady(_HTTPTransferState)
        /// The easy handle is currently added to the multi handle
        case transferInProgress(_HTTPTransferState)
        /// The transfer completed.
        ///
        /// The easy handle has been removed from the multi handle. This does
        /// not (necessarily mean the task completed. A task that gets
        /// redirected will do multiple transfers.
        case transferCompleted(response: URLResponse, bodyDataDrain: _DataDrain)
        /// The transfer failed.
        ///
        /// Same as `.transferCompleted`, but without response / body data
        case transferFailed
        /// Waiting for the completion handler of the HTTP redirect callback.
        ///
        /// When we tell the delegate that we're about to perform an HTTP
        /// redirect, we need to wait for the delegate to let us know what
        /// action to take.
        case waitingForRedirectCompletionHandler(response: URLResponse, bodyDataDrain: _DataDrain)
        /// Waiting for the completion handler of the 'did receive response' callback.
        ///
        /// When we tell the delegate that we received a response (i.e. when
        /// we received a complete header), we need to wait for the delegate to
        /// let us know what action to take. In this state the easy handle is
        /// paused in order to suspend delegate callbacks.
        case waitingForResponseCompletionHandler(_HTTPTransferState)
        /// The task is completed
        ///
        /// Contrast this with `.transferCompleted`.
        case taskCompleted
    }
}

extension _HTTPURLProtocol._InternalState {
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

internal extension _HTTPURLProtocol {
    /// Start a new transfer
    func startNewTransfer(with request: URLRequest) {
        guard let t = task else { fatalError() }
        t.currentRequest = request
        guard let url = request.url else { fatalError("No URL in request.") }

        self.internalState = .transferReady(createTransferState(url: url, workQueue: t.workQueue))
        configureEasyHandle(for: request)
        if (t.suspendCount) < 1 {
            resume()
        }
    }

    func resume() {
        if case .initial = self.internalState {
            guard let r = task?.originalRequest else { fatalError("Task has no original request.") }
            startNewTransfer(with: r)
        }
        
        if case .transferReady(let transferState) = self.internalState {
            self.internalState = .transferInProgress(transferState)
        }
    }

    func suspend() {
        if case .transferInProgress(let transferState) =  self.internalState {
            self.internalState = .transferReady(transferState)
        }
    }
}

/// State Transfers
extension _HTTPURLProtocol {
    func completeTask() {
        guard case .transferCompleted(response: let response, bodyDataDrain: let bodyDataDrain) = self.internalState else {
            fatalError("Trying to complete the task, but its transfer isn't complete.")
        }
        task?.response = response

        //We don't want a timeout to be triggered after this. The timeout timer needs to be cancelled.
        easyHandle.timeoutTimer = nil

        //because we deregister the task with the session on internalState being set to taskCompleted
        //we need to do the latter after the delegate/handler was notified/invoked
        if case .inMemory(let bodyData) = bodyDataDrain {
            var data = Data()
            if let body = bodyData {
                data = Data(bytes: body.bytes, count: body.length)
            }
            self.client?.urlProtocol(self, didLoad: data)
            self.internalState = .taskCompleted
        }

        if case .toFile(let url, let fileHandle?) = bodyDataDrain {
            self.properties[.temporaryFileURL] = url
            fileHandle.closeFile()
        }
        self.client?.urlProtocolDidFinishLoading(self)
        self.internalState = .taskCompleted
    }

    func completeTask(withError error: Error) {
        task?.error = error
        
        guard case .transferFailed = self.internalState else {
            fatalError("Trying to complete the task, but its transfer isn't complete / failed.")
        }

        //We don't want a timeout to be triggered after this. The timeout timer needs to be cancelled.
        easyHandle.timeoutTimer = nil
        self.internalState = .taskCompleted
    }

    func redirectFor(request: URLRequest) {
        //TODO: Should keep track of the number of redirects that this
        // request has gone through and err out once it's too large, i.e.
        // call into `failWith(errorCode: )` with NSURLErrorHTTPTooManyRedirects
        guard case .transferCompleted(response: let response, bodyDataDrain: let bodyDataDrain) = self.internalState else {
            fatalError("Trying to redirect, but the transfer is not complete.")
        }

        guard let session = task?.session as? URLSession else { fatalError() }
        switch session.behaviour(for: task!) {
        case .taskDelegate(let delegate):
            // At this point we need to change the internal state to note
            // that we're waiting for the delegate to call the completion
            // handler. Then we'll call the delegate callback
            // (willPerformHTTPRedirection). The task will then switch out of
            // its internal state once the delegate calls the completion
            // handler.

            //TODO: Should the `public response: URLResponse` property be updated
            // before we call delegate API

            self.internalState = .waitingForRedirectCompletionHandler(response: response, bodyDataDrain: bodyDataDrain)
            // We need this ugly cast in order to be able to support `URLSessionTask.init()`
            session.delegateQueue.addOperation {
                delegate.urlSession(session, task: self.task!, willPerformHTTPRedirection: response as! HTTPURLResponse, newRequest: request) { [weak self] (request: URLRequest?) in
                    guard let task = self else { return }
                    self?.task?.workQueue.async {
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
        guard case .waitingForRedirectCompletionHandler(response: let response, bodyDataDrain: let bodyDataDrain) = self.internalState else {
            fatalError("Received callback for HTTP redirection, but we're not waiting for it. Was it called multiple times?")
        }
        // If the request is `nil`, we're supposed to treat the current response
        // as the final response, i.e. not do any redirection.
        // Otherwise, we'll start a new transfer with the passed in request.
        if let r = request {
            startNewTransfer(with: r)
        } else {
            self.internalState = .transferCompleted(response: response, bodyDataDrain: bodyDataDrain)
            completeTask()
        }
    }
}

/// Response processing
internal extension _HTTPURLProtocol {
    /// Whenever we receive a response (i.e. a complete header) from libcurl,
    /// this method gets called.
    func didReceiveResponse() {
        guard let _ = task as? URLSessionDataTask else { return }
        guard case .transferInProgress(let ts) = self.internalState else { fatalError("Transfer not in progress.") }
        guard let response = ts.response else { fatalError("Header complete, but not URL response.") }
        guard let session = task?.session as? URLSession else { fatalError() }
        switch session.behaviour(for: self.task!) {
        case .noDelegate:
            break
        case .taskDelegate(_):
            //TODO: There's a problem with libcurl / with how we're using it.
            // We're currently unable to pause the transfer / the easy handle:
            // https://curl.haxx.se/mail/lib-2016-03/0222.html
            //
            // For now, we'll notify the delegate, but won't pause the transfer,
            // and we'll disregard the completion handler:
            switch response.statusCode {
            case 301, 302, 303, 307:
                break
            default:
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
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
        guard case .transferInProgress(let ts) = self.internalState else { fatalError("Transfer not in progress.") }
        self.internalState = .waitingForResponseCompletionHandler(ts)
        
        let dt = task as! URLSessionDataTask
        
        // We need this ugly cast in order to be able to support `URLSessionTask.init()`
        guard let s = task?.session as? URLSession else { fatalError() }
        s.delegateQueue.addOperation {
            delegate.urlSession(s, dataTask: dt, didReceive: response, completionHandler: { [weak self] disposition in
                guard let task = self else { return }
                self?.task?.workQueue.async {
                    task.didCompleteResponseCallback(disposition: disposition)
                }
            })
        }
    }
    /// This gets called (indirectly) when the data task delegates lets us know
    /// how we should proceed after receiving a response (i.e. complete header).
    func didCompleteResponseCallback(disposition: URLSession.ResponseDisposition) {
        guard case .waitingForResponseCompletionHandler(let ts) = self.internalState else { fatalError("Received response disposition, but we're not waiting for it.") }
        switch disposition {
        case .cancel:
            let error = URLError(_nsError: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
            self.completeTask(withError: error)
            self.client?.urlProtocol(self, didFailWithError: error)
        case .allow:
            // Continue the transfer. This will unpause the easy handle.
            self.internalState = .transferInProgress(ts)
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
                let location = response.value(forHeaderField: .location, response: response),
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
 
        // If targetURL has only relative path of url, create a new valid url with relative path
        // Otherwise, return request with targetURL ie.url from location field
        guard targetURL.scheme == nil || targetURL.host == nil else {
            request.url = targetURL
            return request
        }
    
        let scheme = request.url?.scheme
        let host = request.url?.host

        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = targetURL.relativeString
        guard let urlString = components.string else { fatalError("Invalid URL") }
        request.url = URL(string: urlString)
        let timeSpent = easyHandle.getTimeoutIntervalSpent()
        request.timeoutInterval = fromRequest.timeoutInterval - timeSpent
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
    func value(forHeaderField field: _Field, response: HTTPURLResponse?) -> String? {
        let value = field.rawValue
	guard let response = response else { fatalError("Response is nil") }
        if let location = response.allHeaderFields[value] as? String {
            return location
        }
        return nil
    }
}
