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

internal class _FTPURLProtocol: _NativeProtocol {
    
    public required init(task: URLSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(task: task, cachedResponse: cachedResponse, client: client)
    }
    
    public required init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard request.url?.scheme == "ftp" || request.url?.scheme == "ftps" || request.url?.scheme == "sftp" else { return false }
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
    
    override  func didReceive(headerData data: Data, contentLength: Int64) -> _EasyHandle._Action {
        guard case .transferInProgress(let ts) = internalState else { fatalError("Received body data, but no transfer in progress.") }
        guard let task = task else { fatalError("Received header data but no task available.") }
        task.countOfBytesExpectedToReceive = contentLength > 0 ? contentLength : NSURLSessionTransferSizeUnknown
        do {
            let newTS = try ts.byAppendingFTP(headerLine: data, expectedContentLength: contentLength)
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
    
    override func seekInputStream(to position: UInt64) throws {
        // NSUnimplemented()
    }
    
    override  func updateProgressMeter(with propgress: _EasyHandle._Progress) {
        //NSUnimplemented()
    }
    
    override func configureEasyHandle(for request: URLRequest) {
        easyHandle.set(verboseModeOn: enableLibcurlDebugOutput)
        easyHandle.set(debugOutputOn: enableLibcurlDebugOutput, task: task!)
        easyHandle.set(skipAllSignalHandling: true)
        guard let url = request.url else { fatalError("No URL in request.") }
        easyHandle.set(url: url)
        easyHandle.set(preferredReceiveBufferSize: Int.max)
        do {
            switch (task?.body, try task?.body.getBodyLength()) {
            case (.some(URLSessionTask._Body.none), _):
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
        let timeoutHandler = DispatchWorkItem { [weak self] in
            guard let _ = self?.task else { fatalError("Timeout on a task that doesn't exist") } //this guard must always pass
            self?.internalState = .transferFailed
            let urlError = URLError(_nsError: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
            self?.completeTask(withError: urlError)
            self?.client?.urlProtocol(self!, didFailWithError: urlError)
        }
        guard let task = self.task else { fatalError() }
        easyHandle.timeoutTimer = _TimeoutSource(queue: task.workQueue, milliseconds: Int(request.timeoutInterval) * 1000, handler: timeoutHandler)
        
        easyHandle.set(automaticBodyDecompression: true)
    }
    
}


/// Response processing
internal extension _FTPURLProtocol {
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
            
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            
        case .dataCompletionHandler:
            break
        case .downloadCompletionHandler:
            break
        }
    }
    
}





