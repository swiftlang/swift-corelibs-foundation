// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import SwiftFoundation
#else
import Foundation
#endif

@_implementationOnly import CoreFoundation
@_implementationOnly import CFURLSessionInterface
import Dispatch

internal class _WebSocketURLProtocol: _HTTPURLProtocol {
    public required init(task: URLSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(task: task, cachedResponse: nil, client: client)
    }
    
    public required init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        super.init(request: request, cachedResponse: nil, client: client)
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        switch request.url?.scheme {
        case "ws", "wss": return true
        default: return false
        }
    }
    
    override func canCache(_ response: CachedURLResponse) -> Bool {
        false
    }
    
    override func canRespondFromCache(using response: CachedURLResponse) -> Bool { false }

    override func didReceiveResponse() {
        guard let webSocketTask = task as? URLSessionWebSocketTask else { return }
        guard case .transferInProgress(let ts) = self.internalState else { fatalError("Transfer not in progress.") }
        guard let response = ts.response as? HTTPURLResponse else { fatalError("Header complete, but not URL response.") }

        webSocketTask.protocolPicked = response.value(forHTTPHeaderField: "Sec-WebSocket-Protocol")
        
        easyHandle.timeoutTimer = nil
        
        webSocketTask.handshakeCompleted = true
        
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }
    
    /// Set options on the easy handle to match the given request.
    ///
    /// This performs a series of `curl_easy_setopt()` calls.
    override func configureEasyHandle(for request: URLRequest, body: _Body) {
        guard request.httpMethod == "GET" else {
            NSLog("WebSocket tasks must use GET")
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL,
                                userInfo: [
                                    NSLocalizedDescriptionKey: "websocket task must use GET httpMethod",
                                    NSURLErrorFailingURLStringErrorKey: request.url?.description ?? ""
                                ])
            internalState = .transferFailed
            transferCompleted(withError: error)
            return
        }
        
        super.configureEasyHandle(for: request, body: body)
        
        easyHandle.setAllowedProtocolsToAll()
        
        guard let webSocketTask = task as? URLSessionWebSocketTask else { return }
        easyHandle.set(preferredReceiveBufferSize: webSocketTask.maximumMessageSize)
    }
    
    override func completionAction(forCompletedRequest request: URLRequest, response: URLResponse) -> _CompletionAction {
        // Redirect:
        guard let httpURLResponse = response as? HTTPURLResponse else {
            fatalError("Response was not HTTPURLResponse")
        }
        if let request = redirectRequest(for: httpURLResponse, fromRequest: request) {
            return .redirectWithRequest(request)
        }
        return .completeTask
    }
    
    override func completeTask() {
        if let webSocketTask = task as? URLSessionWebSocketTask {
            webSocketTask.close(code: .normalClosure, reason: nil)
        }
        super.completeTask()
    }

    func sendWebSocketData(_ data: Data, flags: _EasyHandle.WebSocketFlags) throws {
        try easyHandle.sendWebSocketsData(data, flags: flags)
    }
    
    override func didReceive(data: Data) -> _EasyHandle._Action {
        guard case .transferInProgress(var ts) = internalState else {
            fatalError("Received web socket data, but no transfer in progress.")
        }

        if let response = validateHeaderComplete(transferState:ts) {
            ts.response = response
        }

        // Note this excludes code 300 which should return the response of the redirect and not follow it.
        // For other redirect codes dont notify the delegate of the data received in the redirect response.
        if let httpResponse = ts.response as? HTTPURLResponse,
           301...308 ~= httpResponse.statusCode {
            // Save the response body in case the delegate does not perform a redirect and the 3xx response
            // including its body needs to be returned to the client.
            var redirectBody = lastRedirectBody ?? Data()
            redirectBody.append(data)
            lastRedirectBody = redirectBody
        }

        let flags = easyHandle.getWebSocketFlags()
        
        notifyTask(aboutReceivedData: data, flags: flags)
        internalState = .transferInProgress(ts)
        return .proceed
    }

    fileprivate func notifyTask(aboutReceivedData data: Data, flags: _EasyHandle.WebSocketFlags) {
        guard let t = self.task else {
            fatalError("Cannot notify")
        }
        guard case .taskDelegate = t.session.behaviour(for: self.task!),
              let task = self.task as? URLSessionWebSocketTask else {
            fatalError("WebSocket internal invariant violated")
        }
        
        // Buffer the response message in the task
        if flags.contains(.close) {
            let closeCode: URLSessionWebSocketTask.CloseCode
            let reasonData: Data
            if data.count >= 2 {
                closeCode = data.withUnsafeBytes {
                    let codeInt = UInt16(bigEndian: $0.load(as: UInt16.self))
                    return URLSessionWebSocketTask.CloseCode(rawValue: Int(codeInt)) ?? .unsupportedData
                }
                reasonData = Data(data[2...])
            } else {
                closeCode = .normalClosure
                reasonData = Data()
            }
            task.close(code: closeCode, reason: reasonData)
        } else if flags.contains(.pong) {
            task.noteReceivedPong()
        } else if flags.contains(.binary) {
            let message = URLSessionWebSocketTask.Message.data(data)
            task.appendReceivedMessage(message)
        } else if flags.contains(.text) {
            guard let utf8 = String(data: data, encoding: .utf8) else {
                NSLog("Invalid utf8 message received from server \(data)")
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse,
                                    userInfo: [
                                        NSLocalizedDescriptionKey: "Invalid message received from server",
                                        NSURLErrorFailingURLStringErrorKey: request.url?.description ?? ""
                                    ])
                internalState = .transferFailed
                transferCompleted(withError: error)
                return
            }
            let message = URLSessionWebSocketTask.Message.string(utf8)
            task.appendReceivedMessage(message)
        } else {
            NSLog("Unexpected message received from server \(data) \(flags)")
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse,
                                userInfo: [
                                    NSLocalizedDescriptionKey: "Unexpected message received from server",
                                    NSURLErrorFailingURLStringErrorKey: request.url?.description ?? ""
                                ])
            internalState = .transferFailed
            transferCompleted(withError: error)
        }
    }
}
