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

internal class _HTTPURLProtocol: _NativeProtocol {

    public required init(task: URLSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(task: task, cachedResponse: cachedResponse, client: client)
    }

    public required init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        guard request.url?.scheme == "http" || request.url?.scheme == "https" else { return false }
        return true
    }

    override func didReceive(headerData data: Data, contentLength: Int64) -> _EasyHandle._Action {
        guard case .transferInProgress(let ts) = internalState else {
            fatalError("Received header data, but no transfer in progress.")
        }
        guard let task = task else {
            fatalError("Received header data but no task available.")
        }
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

    /// Set options on the easy handle to match the given request.
    ///
    /// This performs a series of `curl_easy_setopt()` calls.
    override func configureEasyHandle(for request: URLRequest) {
        // At this point we will call the equivalent of curl_easy_setopt()
        // to configure everything on the handle. Since we might be re-using
        // a handle, we must be sure to set everything and not rely on default
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
        guard let url = request.url else {
            fatalError("No URL in request.")
        }
        easyHandle.set(url: url)
        let session = task?.session as! URLSession
        let _config = session._configuration
        easyHandle.set(sessionConfig: _config)
        easyHandle.setAllowedProtocolsToHTTPAndHTTPS()
        easyHandle.set(preferredReceiveBufferSize: Int.max)
        do {
            switch (task?.body, try task?.body.getBodyLength()) {
            case (nil, _):
                set(requestBodyLength: .noBody)
            case (_, let length?):
                set(requestBodyLength: .length(length))
                task!.countOfBytesExpectedToSend = Int64(length)
            case (_, nil):
                set(requestBodyLength: .unknown)
            }
        } catch let e {
            // Fail the request here.
            // TODO: We have multiple options:
            //     NSURLErrorNoPermissionsToReadFile
            //     NSURLErrorFileDoesNotExist
            self.internalState = .transferFailed
            let error = NSError(domain: NSURLErrorDomain, code: errorCode(fileSystemError: e),
                                userInfo: [NSLocalizedDescriptionKey: "File system error"])
            failWith(error: error, request: request)
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
                    // When adding a header, remove any current entry with the same header name regardless of case
                    let newKey = $0.lowercased()
                    for key in httpHeaders!.keys {
                        if newKey == (key as! String).lowercased() {
                            httpHeaders?.removeValue(forKey: key)
                            break
                        }
                    }
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
            guard let _ = self?.task else {
                fatalError("Timeout on a task that doesn't exist")
            } //this guard must always pass
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

    /// What action to take
    override func completionAction(forCompletedRequest request: URLRequest, response: URLResponse) -> _CompletionAction {
        // Redirect:
        guard let httpURLResponse = response as? HTTPURLResponse else {
            fatalError("Reponse was not HTTPURLResponse")
        }
        if let request = redirectRequest(for: httpURLResponse, fromRequest: request) {
            return .redirectWithRequest(request)
        }
        return .completeTask
    }

    override func redirectFor(request: URLRequest) {
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

    override func validateHeaderComplete(transferState: _NativeProtocol._TransferState) -> URLResponse? {
        if !transferState.isHeaderComplete {
            return HTTPURLResponse(url: transferState.url, statusCode: 200, httpVersion: "HTTP/0.9", headerFields: [:])
            /* we received body data before CURL tells us that the headers are complete, that happens for HTTP/0.9 simple responses, see
             - https://www.w3.org/Protocols/HTTP/1.0/spec.html#Message-Types
             - https://github.com/curl/curl/issues/467
             */
        }
        return nil
    }
}

fileprivate extension _HTTPURLProtocol {

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
	if let hh = httpHeaders as? [String : String] {
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
        if task?.body == nil  {
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
    //TODO: Use Bundle to get the version number?
    return "\(name) (unknown version) curl/\(curlVersion.major).\(curlVersion.minor).\(curlVersion.patch)"
}()

/// State Transfers
extension _HTTPURLProtocol {
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
        guard let response = ts.response as? HTTPURLResponse else { fatalError("Header complete, but not URL response.") }
        guard let session = task?.session as? URLSession else { fatalError() }
        switch session.behaviour(for: self.task!) {
        case .noDelegate:
            break
        case .taskDelegate:
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
        let port = request.url?.port

        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.port = port
        //The path must either begin with "/" or be an empty string.
        if targetURL.relativeString.first != "/" {
            components.path = "/" + targetURL.relativeString
        } else {
            components.path = targetURL.relativeString
        }

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
