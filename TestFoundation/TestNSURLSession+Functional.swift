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
/// This file contains functional tests of the NSURLSession API.
/// As such they're of black-box testing of the NSURLSession API. These tests
/// use an in-process HTTP server to check that the NSURLSession API behaves
/// as expected.
/// - SeeAlso: https://en.wikipedia.org/wiki/Functional_testing
///
// -----------------------------------------------------------------------------

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    @testable import Foundation
    import XCTest
#else
    @testable import SwiftFoundation
    import SwiftXCTest
#endif
import Dispatch



class TestNSURLSession : XCTestCase {
    static var allTests: [(String, TestNSURLSession -> () throws -> Void)] {
        return [
            ("test_CreateWithDefaultConfiguration", test_CreateWithDefaultConfiguration),
            ("test_thatTaskIsSuspendedUponCreation", test_thatTaskIsSuspendedUponCreation),
            
            ("test_functional_invalidURLs", test_functional_invalidURLs),
            ("test_functional_serverClosingConnection", test_functional_serverClosingConnection),
            ("test_functional_delegate_GET_withRedirect", test_functional_delegate_GET_withRedirect),
            ("test_functional_completionHandler_GET", test_functional_completionHandler_GET),
            ("test_functional_GET_compressedData", test_functional_GET_compressedData),
            ("test_functional_POST_fromData", test_functional_POST_fromData),
            ("test_functional_POST_fromFile", test_functional_POST_fromFile),
            ("test_functional_POST_fromFileThatDoesNotExist", test_functional_POST_fromFileThatDoesNotExist),
        
            ("test_functional_defaultHeaders", test_functional_defaultHeaders),
            ("test_functional_sessionConfigurationHeaders", test_functional_sessionConfigurationHeaders),
        ]
    }
    
    let queue = NSOperationQueue()
    
    /// Create an HTTP server and return the server and its base URL.
    private func createServer(file: StaticString = #file, line: UInt = #line, handler: (HTTPRequest) -> HTTPResponse) -> (SocketServer, NSURL)? {
        let q = dispatch_queue_create("test_2", DISPATCH_QUEUE_SERIAL)
        let server: SocketServer
        do {
            server = try SocketServer() { channel in
                httpConnectionHandler(channel: channel.channel, clientAddress: channel.address, queue: q) { request in
                    return handler(request)
                }
            }
        } catch let e {
            XCTFail("Unable to create HTTP server: \(e)", file: file, line: line)
            return nil
        }
        let c = NSURLComponents()
        c.scheme = "http"
        c.host = "localhost"
        c.port = NSNumber(unsignedShort: server.port)
        c.path = "/"
        return (server, c.URL!)
    }
    /// Creates an HTTP server with a block that gets all headers.
    private func createExtractHeaderServer(file: StaticString = #file, line: UInt = #line, headerHandler: (HeaderFields) -> ()) -> (SocketServer, NSURL)? {
        return createServer(file: file, line: line) { request in
            var headerFields: [(name: String, value: String)] = []
            request.forEachHeaderField {
                headerFields.append((name: $0, value: $1))
            }
            headerHandler(HeaderFields(fields: headerFields))
            return HTTPResponse(statusCode: 200, additionalHeaderFields: [], body: "")
        }
    }
    /// Helper function that creates a session with a delegate and calls the
    /// given closure with the sesion and delegate.
    ///
    /// The HTTP server, the NSURLSession, and the delegate are wrapped inside
    /// calls to `withExtendedLifetime` to ensure they live until the end of
    /// the test case.
    private func with(server: SocketServer, @noescape testClosure: (NSURLSession, TaskDelegate) -> ()) {
        with(server: server, configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), testClosure: testClosure)
    }
    /// Helper function that creates a session with a delegate and calls the
    /// given closure with all three wrapped in a `withExtendedLifetime()` call.
    /// - Parameter configuration: The configuration of the NSURLSession to be tested.
    private func with(server: SocketServer, configuration: NSURLSessionConfiguration, @noescape testClosure: (NSURLSession, TaskDelegate) -> ()) {
        withExtendedLifetime(server) {
            let delegate = TaskDelegate()
            let session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: queue)
            withExtendedLifetime(delegate) {
                withExtendedLifetime(session) {
                    testClosure(session, delegate)
                }
            }
        }
    }
}

extension TestNSURLSession {
    func test_CreateWithDefaultConfiguration() {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let _ = NSURLSession(configuration: config)
        let _ = NSURLSession(configuration: config, delegate: Delegate(), delegateQueue: NSOperationQueue())
    }
    
    func test_thatTaskIsSuspendedUponCreation() {
        let sut = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        let task = sut.dataTask(with: NSURL(string: "http://swift.org/")!)
        XCTAssertEqual(task.state, NSURLSessionTaskState.Suspended)
    }
}


extension TestNSURLSession {
    /// Test a few invalid, unresolvable, etc. URLs
    func test_functional_invalidURLs() {
        let delegate = TaskDelegate()
        let sut = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: delegate, delegateQueue: queue)
        withExtendedLifetime(sut) {
            let pairs = [
                            ("httttp://swift.org/", NSURLErrorUnsupportedURL),
                            ("http://does.not.exist.example.com", NSURLErrorCannotFindHost),
                            ]
            for (urlString, expectedError) in pairs {
                let invalidURL = NSURL(string: urlString)!
                let task = sut.dataTask(with: invalidURL)
                
                delegate.completionExpectation = expectation(withDescription: "Task did complete")
                task.resume()
                waitForExpectations(withTimeout: 1, handler: nil)
                XCTAssertEqual(task.state, NSURLSessionTaskState.Completed)
                
                guard let error = delegate.completionError else { XCTFail("URL: '\(urlString)'"); return }
                XCTAssertEqual(error.domain, NSURLErrorDomain, "URL: '\(urlString)'")
                XCTAssertEqual(error.code, expectedError, "URL: '\(urlString)'")
            }
        }
    }
    
    func test_functional_serverClosingConnection() {
        let server: SocketServer
        do {
            server = try SocketServer() { channel in
                // Close immediately after reading
                let c = channel.channel
                let q = dispatch_queue_create("test_functional_serverClosingConnection", DISPATCH_QUEUE_SERIAL)
                dispatch_io_read(c, 0, 40, q) { (done, _, _) in
                    if done {
                        dispatch_io_close(c, 0)
                    }
                }
            }
        } catch let e {
            XCTFail("Unable to create HTTP server: \(e)")
            return
        }
        let c = NSURLComponents()
        c.scheme = "http"
        c.host = "localhost"
        c.port = NSNumber(unsignedShort: server.port)
        c.path = "/"
        let baseURL = c.URL!
        
        with(server: server) { (session, delegate) in
            let task = session.dataTask(with: baseURL)
            
            delegate.completionExpectation = expectation(withDescription: "Task did complete")
            task.resume()
            waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertEqual(task.state, NSURLSessionTaskState.Completed)
            
            guard let error = delegate.completionError else { XCTFail(); return }
            XCTAssertEqual(error.domain, NSURLErrorDomain)
            XCTAssert(
                error.code == NSURLErrorNetworkConnectionLost ||
                error.code == NSURLErrorCannotConnectToHost ||
                error.code == NSURLErrorBadServerResponse, "error.code = \(error.code)")
        }
    }
    
    /// Test a task that uses the session's delegate and performs a `GET` request
    /// which will be redirected.
    func test_functional_delegate_GET_withRedirect() {
        var baseURL: NSURL?
        guard let (server, _baseURL) = createServer(handler: { request in
            switch request.URI.path! {
            case "/foo":
                // Redirect
                let fields = [("Location", NSURL(string: "/bar", relativeToURL: baseURL)!.absoluteString)]
                return HTTPResponse(statusCode: 302, additionalHeaderFields: fields, body: "Redirect.")
            case "/bar":
                let fields = [("Content-Type", "text/plain")]
                return HTTPResponse(statusCode: 200, additionalHeaderFields: fields, body: "Foo Bar Baz")
            default:
                XCTFail("Unexpected URI \(request.URI.absoluteString)")
                return HTTPResponse(statusCode: 500, additionalHeaderFields: [], body: "")
            }
        }) else { XCTFail(); return }
        baseURL = _baseURL
        with(server: server) { (session, delegate) in
            let originalURL = NSURL(string: "/foo", relativeToURL: baseURL)!
            let redirectedURL = NSURL(string: "/bar", relativeToURL: originalURL)!
            let task = session.dataTask(with: originalURL)
            
            delegate.redirectExpectation = expectation(withDescription: "Redirect")
            XCTAssertEqual(task.state, NSURLSessionTaskState.Suspended)
            task.resume()
            
            waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertEqual(task.state, NSURLSessionTaskState.Running)
            
            do {
                XCTAssertEqual(delegate.allResponses.count, 1, "Should only have received the redirect response.")
                guard let r = delegate.redirect else { XCTFail("No redirect."); return }
                XCTAssertEqual(r.redirection.url, originalURL, "The orignal request's URL")
                XCTAssertEqual(r.redirection.statusCode, 302)
                if let d = delegate.concatenatedReceivedData, let s = String(data: d, encoding: NSUTF8StringEncoding) {
                    XCTAssertEqual(s, "Redirect.")
                } else {
                    XCTFail()
                }
                XCTAssertEqual(r.newRequest.url?.absoluteString, redirectedURL.absoluteString)
                //TODO: Test that all properties from the original request are copied onto the redirect request.
                
                delegate.redirect = nil
                delegate.redirectExpectation = nil
                delegate.completionExpectation = expectation(withDescription: "Task did complete")
                r.completionHandler(r.newRequest)
            }
            waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertEqual(task.state, NSURLSessionTaskState.Completed)
            
            do {
                XCTAssertEqual(delegate.allResponses.count, 2, "Should have received the redirect response and the final.")
                XCTAssertNil(delegate.completionError)
                if let d = delegate.concatenatedReceivedData, let s = String(data: d, encoding: NSUTF8StringEncoding) {
                    XCTAssertEqual(s, "Foo Bar Baz")
                } else {
                    XCTFail()
                }
                guard let r = task.response as? NSHTTPURLResponse else { XCTFail(); return }
                XCTAssertEqual(r.url?.absoluteString, redirectedURL.absoluteString)
                XCTAssertEqual(r.statusCode, 200)
                XCTAssertEqual(r.mimeType, "text/plain")
            }
        }
    }
    

    /// Test a task with a completion handler performs a `GET` request.
    func test_functional_completionHandler_GET() {
        var baseURL: NSURL?
        guard let (server, _baseURL) = createServer(handler: { request in
            switch request.URI.path! {
            case "/bar":
                XCTAssertEqual(request.method, "GET")
                XCTAssertEqual(request.body.map({ dispatch_data_get_size($0) }) ?? -1, 0)
                let fields = [("Content-Type", "text/plain")]
                return HTTPResponse(statusCode: 200, additionalHeaderFields: fields, body: "Foo Bar Baz")
            default:
                XCTFail("Unexpected URI \(request.URI.absoluteString)")
                return HTTPResponse(statusCode: 500, additionalHeaderFields: [], body: "")
            }
        }) else { XCTFail(); return }
        baseURL = _baseURL
        with(server: server) { (session, delegate) in
            let url = NSURL(string: "/bar", relativeToURL: baseURL)!
            
            let completionExpectation = expectation(withDescription: "Task did complete")
            let task = session.dataTask(with: url, completionHandler: {
                (data, response, error) in
                
                XCTAssertNil(error)
                if let d = data, let s = String(data: d, encoding: NSUTF8StringEncoding) {
                    XCTAssertEqual(s, "Foo Bar Baz")
                } else {
                    XCTFail()
                }
                guard let r = response as? NSHTTPURLResponse else { XCTFail(); return }
                XCTAssertEqual(r.url?.absoluteString, url.absoluteString)
                XCTAssertEqual(r.statusCode, 200)
                XCTAssertEqual(r.mimeType, "text/plain")
                
                completionExpectation.fulfill()
            })
            
            XCTAssertEqual(task.state, NSURLSessionTaskState.Suspended)
            task.resume()
            XCTAssertEqual(task.state, NSURLSessionTaskState.Running)
            waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertEqual(task.state, NSURLSessionTaskState.Completed)
        }
    }
    
    func test_functional_GET_compressedData() {
        var baseURL: NSURL?
        guard let (server, _baseURL) = createServer(handler: { request in
            switch request.URI.path! {
            case "/hello":
                let bytes = ContiguousArray<UInt8>([0x1f, 0x8b, 0x08, 0x08, 0xa3, 0x7b, 0x05, 0x57,
                                                    0x00, 0x03, 0x74, 0x65, 0x78, 0x74, 0x2e, 0x74,
                                                    0x78, 0x74, 0x00, 0xf3, 0x48, 0xcd, 0xc9, 0xc9,
                                                    0x57, 0x08, 0x2e, 0xcf, 0x4c, 0x2b, 0x51, 0x04,
                                                    0x00, 0xef, 0xc5, 0x65, 0x17, 0x0c, 0x00, 0x00,
                                                    0x00])
                let body = bytes.withUnsafeBufferPointer { return dispatch_data_create($0.baseAddress, $0.count, nil, nil) }
                let fields = [("Content-Type", "text/plain"), ("Content-Encoding", "gzip")]
                return HTTPResponse(statusCode: 200, additionalHeaderFields: fields, bodyData: body)
            default:
                XCTFail("Unexpected URI \(request.URI.absoluteString)")
                return HTTPResponse(statusCode: 500, additionalHeaderFields: [], body: "")
            }
        }) else { XCTFail(); return }
        baseURL = _baseURL
        with(server: server) { (session, delegate) in
            let url = NSURL(string: "/hello", relativeToURL: baseURL)!
            
            let completionExpectation = expectation(withDescription: "Task did complete")
            let task = session.dataTask(with: url, completionHandler: {
                (data, response, error) in
                
                XCTAssertNil(error)
                if let d = data, let s = String(data: d, encoding: NSUTF8StringEncoding) {
                    XCTAssertEqual(s, "Hello Swift!")
                } else {
                    XCTFail()
                }
                guard let r = response as? NSHTTPURLResponse else { XCTFail(); return }
                XCTAssertEqual(r.url?.absoluteString, url.absoluteString)
                XCTAssertEqual(r.statusCode, 200)
                XCTAssertEqual(r.mimeType, "text/plain")
                
                completionExpectation.fulfill()
            })
            
            task.resume()
            waitForExpectations(withTimeout: 1, handler: nil)
        }
    }
    

    //MARK: Upload
    //
    // NSURLSessionUploadTask
    // Requests with a body
    //

    /// Test a task with a completion handler performs a `POST` request.
    func test_functional_POST_fromData() {
        let bodyData = dispatchData("resource -- A network data object or service that can be identified by a URI, as defined in section 3.2. Resources may be available in multiple representations (e.g. multiple languages, data formats, size, andresolutions) or vary in other ways.")
        
        var baseURL: NSURL?
        guard let (server, _baseURL) = createServer(handler: { request in
            switch request.URI.path! {
            case "/bar":
                XCTAssertEqual(request.method, "POST")
                if let body = request.body {
                    XCTAssertEqual(dispatch_data_get_size(body), dispatch_data_get_size(bodyData))
                    XCTAssertEqual(NSData(dispatchData: body), NSData(dispatchData: bodyData))
                } else {
                    XCTFail("No body in request.")
                }
                let fields = [("Content-Type", "text/plain")]
                return HTTPResponse(statusCode: 200, additionalHeaderFields: fields, body: "Foo Bar Baz")
            default:
                XCTFail("Unexpected URI \(request.URI.absoluteString)")
                return HTTPResponse(statusCode: 500, additionalHeaderFields: [], body: "")
            }
        }) else { XCTFail(); return }
        baseURL = _baseURL
        with(server: server) { (session, delegate) in
            let url = NSURL(string: "/bar", relativeToURL: baseURL)!
            let originalRequest = NSMutableURLRequest(url: url)
            originalRequest.httpMethod = "POST"
            
            let task = session.uploadTask(with: originalRequest, fromData: NSData(dispatchData: bodyData))
            
            delegate.completionExpectation = expectation(withDescription: "Task did complete")
            task.resume()
            waitForExpectations(withTimeout: 1, handler: nil)
            
            do {
                XCTAssertEqual(delegate.allResponses.count, 1)
                XCTAssertNil(delegate.completionError)
                if let d = delegate.concatenatedReceivedData, let s = String(data: d, encoding: NSUTF8StringEncoding) {
                    XCTAssertEqual(s, "Foo Bar Baz")
                } else {
                    XCTFail()
                }
                guard let r = task.response as? NSHTTPURLResponse else { XCTFail(); return }
                XCTAssertEqual(r.url?.absoluteString, url.absoluteString)
                XCTAssertEqual(r.statusCode, 200)
                XCTAssertEqual(r.mimeType, "text/plain")
            }
            
        }
    }

    func test_functional_POST_fromFile() {
        // We'll generate some pseudo-random data and write it into a file.
        let bodyData = createTestData(length: 2 * 1024 * 1024 - 91)
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("test_functional_POST_fromFile.body")!
        do {
            try bodyData.writeToURL(fileURL, options: [])
        } catch let e {
            XCTFail("\(e)");
            return
        }
        
        var baseURL: NSURL?
        guard let (server, _baseURL) = createServer(handler: { request in
            switch request.URI.path! {
            case "/bar":
                XCTAssertEqual(request.method, "POST")
                if let body = request.body {
                    if dispatch_data_get_size(body) != bodyData.length {
                        XCTFail("Body data length doesn't match: \(dispatch_data_get_size(body)) != \(bodyData.length)")
                    } else {
                        let d = NSData(dispatchData: body)
                        withExtendedLifetime(d) {
                            XCTAssertEqual(d, bodyData)
                            // If these don't match, find positions where they don't:
                            if d != bodyData {
                                let bufferA = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(d.bytes), count: d.length)
                                let bufferB = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(bodyData.bytes), count: bodyData.length)
                                (0..<bufferA.count).filter({ bufferA[$0] != bufferB[$0] }).prefix(10).forEach {
                                    XCTFail("Mismatch at index \($0): \(String(bufferA[$0], radix:16)) != \(String(bufferB[$0], radix:16))")
                                }
                            }
                        }
                    }
                } else {
                    XCTFail("No body in request.")
                }
                let fields = [("Content-Type", "text/plain")]
                return HTTPResponse(statusCode: 200, additionalHeaderFields: fields, body: "Foo Bar Baz")
            default:
                XCTFail("Unexpected URI \(request.URI.absoluteString)")
                return HTTPResponse(statusCode: 500, additionalHeaderFields: [], body: "")
            }
        }) else { XCTFail(); return }
        baseURL = _baseURL
        with(server: server) { (session, delegate) in
            let url = NSURL(string: "/bar", relativeToURL: baseURL)!
            let originalRequest = NSMutableURLRequest(url: url)
            originalRequest.httpMethod = "POST"
            
            let task = session.uploadTask(with: originalRequest, fromFile: fileURL)
            
            delegate.completionExpectation = expectation(withDescription: "Task did complete")
            task.resume()
            waitForExpectations(withTimeout: 1, handler: nil)
            
            do {
                XCTAssertEqual(delegate.allResponses.count, 1)
                XCTAssertNil(delegate.completionError)
                if let d = delegate.concatenatedReceivedData, let s = String(data: d, encoding: NSUTF8StringEncoding) {
                    XCTAssertEqual(s, "Foo Bar Baz")
                } else {
                    XCTFail()
                }
                guard let r = task.response as? NSHTTPURLResponse else { XCTFail(); return }
                XCTAssertEqual(r.url?.absoluteString, url.absoluteString)
                XCTAssertEqual(r.statusCode, 200)
                XCTAssertEqual(r.mimeType, "text/plain")
            }
        }
    }
    
    func test_functional_POST_fromFileThatDoesNotExist() {
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("test_functional_POST_fromFileThatDoesNotExist")!
        
        var baseURL: NSURL?
        guard let (server, _baseURL) = createServer(handler: { request in
            XCTFail("Should not receive a request.")
            return HTTPResponse(statusCode: 500, additionalHeaderFields: [], body: "")
        }) else { XCTFail(); return }
        baseURL = _baseURL
        with(server: server) { (session, delegate) in
            let url = NSURL(string: "/bar", relativeToURL: baseURL)!
            let originalRequest = NSMutableURLRequest(url: url)
            originalRequest.httpMethod = "POST"
            
            let task = session.uploadTask(with: originalRequest, fromFile: fileURL)
            
            delegate.completionExpectation = expectation(withDescription: "Task did complete")
            task.resume()
            waitForExpectations(withTimeout: 1, handler: nil)
            
            do {
                XCTAssertEqual(delegate.allResponses.count, 0)
                if let error = delegate.completionError {
                    XCTAssertEqual(error.domain, NSURLErrorDomain)
                    XCTAssertEqual(error.code, NSURLErrorFileDoesNotExist)
                } else {
                    XCTFail("Expected an error.")
                }
            }
        }
    }
    
    
    //TODO: Uploading data with completion handler
    // public func uploadTaskWithRequest(request: NSURLRequest, fromFile fileURL: NSURL, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionUploadTask
    // public func uploadTaskWithRequest(request: NSURLRequest, fromData bodyData: NSData?, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionUploadTask

    func test_functional_defaultHeaders() {
        var baseURL: NSURL?
        guard let (server, _baseURL) = createExtractHeaderServer(headerHandler: { headers in
            let port = Int(baseURL?.port ?? 0)
            let expected = ["Host": "\(baseURL?.host ?? ""):\(String(port))",
                            "Accept": "*/*",
                            //"Accept-Language": "en",
                            "Accept-Encoding": "deflate, gzip",
                            "Connection": "keep-alive",
                            ]
            AssertHeaderFieldsEqual(headers, expected)
            AssertHeaderFieldNamesEqual(headers, ["Host", "Accept", /*"Accept-Language",*/ "Accept-Encoding", "Connection", "User-Agent"])
        }) else { XCTFail(); return }
        baseURL = _baseURL
        with(server: server) { (session, delegate) in
            let url = NSURL(string: "/bar", relativeToURL: baseURL)!
            
            let completionExpectation = expectation(withDescription: "Task did complete")
            let task = session.dataTask(with: url, completionHandler: { (_, _, _) in
                completionExpectation.fulfill()
            })
            
            task.resume()
            waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertEqual(task.state, NSURLSessionTaskState.Completed)
        }
    }

    func test_functional_sessionConfigurationHeaders() {
        var baseURL: NSURL?
        guard let (server, _baseURL) = createExtractHeaderServer(headerHandler: { headers in
            let port = Int(baseURL?.port ?? 0)
            let expected = ["Host": "\(baseURL?.host ?? ""):\(String(port))",
                            "Accept": "*/*",
                            //"Accept-Language": "en-us",
                            "Accept-Encoding": "deflate, gzip",
                            "X-Foo": "Aa2",
                            "X-Bar": "Bb1",
                            "X-Baz": "Cc2",
                            "User-Agent": "Lovelace",
                            ]
            AssertHeaderFieldsEqual(headers, expected)
            AssertHeaderFieldNamesEqual(headers, ["Host", "Accept", /*"Accept-Language",*/ "Accept-Encoding", "Connection", "User-Agent", "X-Foo", "X-Bar", "X-Baz"])
        }) else { XCTFail(); return }
        baseURL = _baseURL
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.httpAdditionalHeaders = [NSString("X-Foo"): NSString("Aa1"),
                                        NSString("X-Bar"): NSString("Bb1"),
                                        NSString("User-Agent"): NSString("Lovelace")]
        with(server: server, configuration: config) { (session, delegate) in
            let url = NSURL(string: "/bar", relativeToURL: baseURL)!
            let request = NSMutableURLRequest(url: url)
            request.setValue("Aa2", forHTTPHeaderField: "X-Foo")
            request.setValue("Cc2", forHTTPHeaderField: "X-Baz")
            
            let completionExpectation = expectation(withDescription: "Task did complete")
            let task = session.dataTask(with: request, completionHandler: { (_, _, _) in
                completionExpectation.fulfill()
            })
            
            task.resume()
            waitForExpectations(withTimeout: 1, handler: nil)
            XCTAssertEqual(task.state, NSURLSessionTaskState.Completed)
        }
    }
}




private extension HTTPResponse {
    init(statusCode: Int, additionalHeaderFields: [(String, String)], bodyData: dispatch_data_t) {
        var headerFields = additionalHeaderFields
        // This simple server does not support persistent connections.
        // C.f. RFC 2616 section 8.1.2.1
        headerFields.append(("Connection", "close"))
        // https://tools.ietf.org/html/rfc2616#section-14.13
        headerFields.append(("Content-Length", String(dispatch_data_get_size(bodyData))))
        self.init(statusCode: statusCode, headerFields: headerFields, body: bodyData)
    }
    init(statusCode: Int, additionalHeaderFields: [(String, String)], body: String) {
        let bodyData = dispatchData(body)
        self.init(statusCode: statusCode, additionalHeaderFields: additionalHeaderFields, bodyData: bodyData)
    }
}

/// Encodes the string as UTF-8 into a dispatch_data_t without copying memory.
private func dispatchData(_ string: String) -> dispatch_data_t {
    // Avoid copying buffers. Simply allocate a buffer, fill it with the UTF-8,
    // and wrap the buffer as dispatch_data_t.
    var array = ContiguousArray<UTF8.CodeUnit>()
    for code in string.utf8 {
        array.append(code)
    }
    return array.withUnsafeBufferPointer { buffer in
        return dispatch_data_create(UnsafePointer<Void>(buffer.baseAddress), buffer.count, nil, nil)
    }
}



//MARK: - Delegates

private class Delegate: SwiftFoundation.NSObject {
    let file: StaticString
    let line: UInt
    init(file: StaticString = #file, line: UInt = #line) {
        self.file = file
        self.line = line
        super.init()
    }
}
extension Delegate: NSURLSessionDelegate {
    func urlSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
    }
    func urlSession(session: NSURLSession, didReceive challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
    }
}

private class TaskDelegate: Delegate {
    var redirectExpectation: XCTestExpectation?
    var redirect: Redirect?
    
    var allResponses: [NSURLResponse] = []
    var responseAction: ResponseAction = .clearDataAndDisposition(.allow)
    
    var completionExpectation: XCTestExpectation?
    var completionError: NSError?
    
    var receivedData: [NSData]? = nil
    var concatenatedReceivedData: NSData? {
        guard let d = receivedData else { return nil }
        let md = NSMutableData()
        d.forEach { md.appendData($0) }
        return md
    }
}
extension TaskDelegate {
    struct Redirect {
        let redirection: NSHTTPURLResponse
        let newRequest: NSURLRequest
        let completionHandler: (NSURLRequest?) -> Void
    }
    enum ResponseAction {
        case disposition(NSURLSessionResponseDisposition)
        case clearDataAndDisposition(NSURLSessionResponseDisposition)
        case fulfillExpectation(XCTestExpectation)
    }
}
extension TaskDelegate: NSURLSessionDataDelegate {
    func urlSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        redirect = Redirect(redirection: response, newRequest: request, completionHandler: completionHandler)
        guard let e = redirectExpectation else { XCTFail("Unexpected 'redirect' callback.", file: file, line: line); return }
        e.fulfill()
    }
    func urlSession(session: NSURLSession, task: NSURLSessionTask, didReceive challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        fatalError("Unimplemented")
    }
    func urlSession(session: NSURLSession, task: NSURLSessionTask, needNewBodyStream completionHandler: (NSInputStream?) -> Void) {
        fatalError("Unimplemented")
    }
    func urlSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    }
    func urlSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        guard let e = completionExpectation else { XCTFail("Unexpected 'completion' callback.", file: file, line: line); return }
        completionError = error
        e.fulfill()
    }
    
    // Data
    
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceive response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        allResponses.append(response)
        switch responseAction {
        case .disposition(let d):
            completionHandler(d)
        case .clearDataAndDisposition(let d):
            receivedData = nil
            completionHandler(d)
        case .fulfillExpectation(let e):
            e.fulfill()
        }
    }
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecome downloadTask: NSURLSessionDownloadTask) {
        NSUnimplemented()
    }
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecome streamTask: NSURLSessionStreamTask) {
        NSUnimplemented()
    }
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceive data: NSData) {
        var r = receivedData ?? []
        r.append(data)
        receivedData = r
    }
    func urlSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        NSUnimplemented()
    }
}

//MARK: - Header Field Helpers

private struct HeaderFields {
    let fields: [(name: String, value: String)]
}
extension HeaderFields {
    func value(forField name: String) -> String? {
        let lowercasedName = name.lowercased()
        return fields.index(where: { lowercasedName == $0.name.lowercased() }).map { fields[$0].value }
    }
    var count: Int { return fields.count }
}
extension HeaderFields {
    func hasValue(forField name: String) -> Bool {
        return value(forField: name) != nil
    }
}


/// Asserts that the header fields with the given names exist.
private func AssertHeaderFieldsExist(@autoclosure _ expression1: () throws -> HeaderFields, @autoclosure _ expression2: () throws -> [String], @autoclosure _ message: () -> String = "", file: StaticString = #file, line: UInt = #line) {
    let m = message()
    do {
        let f = try expression1()
        try expression2().forEach {
            if !f.hasValue(forField: $0) {
                XCTFail(file: file, line: line, "Field '\($0)' is missing. " + m)
            }
        }
    } catch let e { XCTFail(file: file, line: line, "\(m) -- \(e)") }
}
/// Asserts that header fields only exist for the given names and nothing else.
private func AssertHeaderFieldNamesEqual(@autoclosure _ expression1: () throws -> HeaderFields, @autoclosure _ expression2: () throws -> [String], @autoclosure _ message: () -> String = "", file: StaticString = #file, line: UInt = #line) {
    let m = message()
    do {
        let fields = try expression1()
        var extraNames = fields.fields.map { $0.name }
        try expression2().forEach { field in
            if let idx = extraNames.index(where: { field.lowercased() == $0.lowercased() }) {
                extraNames.remove(at: idx)
            } else {
                XCTFail(file: file, line: line, "Header field '\(field)' is missing. " + m)
            }
        }
        extraNames.forEach {
            let value = fields.value(forField: $0) ?? ""
            XCTFail(file: file, line: line, "Extranous header field '\($0): \(value)'. " + m)
        }
        
    } catch let e { XCTFail(file: file, line: line, "\(m) -- \(e)") }
}
/// Asserts the the header fields match those in the dictionary, *and* that all
/// fields in the dictionary exist. But the headers might have more values.
private func AssertHeaderFieldsEqual(@autoclosure _ expression1: () throws -> HeaderFields, @autoclosure _ expression2: () throws -> [String:String], @autoclosure _ message: () -> String = "", file: StaticString = #file, line: UInt = #line) {
    let m = message()
    do {
        let f = try expression1()
        try expression2().forEach { field in
            if let v = f.value(forField: field.0) {
                XCTAssertEqual(v, field.1, file: file, line: line, "Header field '\(field.0)'. \(m)")
            } else {
                XCTFail(file: file, line: line, "Header field '\(field.0)' is missing. \(m)")
            }
        }
    } catch let e { XCTFail(file: file, line: line, "\(m) -- \(e)") }
}

/// Create test data with a well-defined pattern.
func createTestData(length: Int) -> NSData {
    let count = (length + 1) / sizeof(UInt16)
    let mutableData = NSMutableData(length: count * sizeof(UInt16))!
    let buffer = UnsafeMutableBufferPointer<UInt16>(start: UnsafeMutablePointer<UInt16>(mutableData.bytes), count: mutableData.length / sizeof(UInt16))
    for i in 0..<buffer.count {
        // 16 bits, we'll use the 5 MSB for (i % 61) and the lower 12 bits for (i % 997)
        let v: UInt16 = (UInt16(i % 61) << 11) | UInt16(i % 997)
        buffer[i] = v
    }
    mutableData.length = length
    return mutableData.copy() as! NSData
}
