// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

class TestURLSession : XCTestCase {
    
    static var serverPort: Int = -1
    
    static var allTests: [(String, (TestURLSession) -> () throws -> Void)] {
        return [
            ("test_dataTaskWithURL", test_dataTaskWithURL),
            ("test_dataTaskWithURLRequest", test_dataTaskWithURLRequest),
            ("test_dataTaskWithURLCompletionHandler", test_dataTaskWithURLCompletionHandler),
            ("test_dataTaskWithURLRequestCompletionHandler", test_dataTaskWithURLRequestCompletionHandler),
            ("test_downloadTaskWithURL", test_downloadTaskWithURL),
            ("test_downloadTaskWithURLRequest", test_downloadTaskWithURLRequest),
            ("test_downloadTaskWithRequestAndHandler", test_downloadTaskWithRequestAndHandler),
            ("test_downloadTaskWithURLAndHandler", test_downloadTaskWithURLAndHandler),
            ("test_finishTaskAndInvalidate", test_finishTasksAndInvalidate),
            ("test_taskError", test_taskError),
            ("test_taskCopy", test_taskCopy),
            ("test_cancelTask", test_cancelTask),
            ("test_taskTimeout", test_taskTimeout),
            ("test_verifyRequestHeaders", test_verifyRequestHeaders),
            ("test_verifyHttpAdditionalHeaders", test_verifyHttpAdditionalHeaders),
            ("test_timeoutInterval", test_timeoutInterval),
            ("test_customProtocol", test_customProtocol),
	    ("test_customProtocolResponseWithDelegate", test_customProtocolResponseWithDelegate),
            ("test_httpRedirection", test_httpRedirection),
            ("test_httpRedirectionTimeout", test_httpRedirectionTimeout),
        ]
    }
    
    override class func setUp() {
        super.setUp()
        func runServer(with condition: ServerSemaphore, startDelay: TimeInterval? = nil, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
            let start = 21961
            for port in start...(start+100) { //we must find at least one port to bind
                do {
                    serverPort = port
                    let test = try TestURLSessionServer(port: UInt16(port), startDelay: startDelay, sendDelay: sendDelay, bodyChunks: bodyChunks)
                    try test.start(started: condition)
                    try test.readAndRespond()
                    test.stop()
                } catch let e as ServerError {
                    if e.operation == "bind" { continue }
                    throw e
                }
            }
        }
        
        let serverReady = ServerSemaphore()
        globalDispatchQueue.async {
            do {
                try runServer(with: serverReady)
                
            } catch {
                XCTAssertTrue(true)
                return
            }
        }
        
        serverReady.wait()
    }
    
    func test_dataTaskWithURL() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Nepal"
        let url = URL(string: urlString)!
        let d = DataTask(with: expectation(description: "data task"))
        d.run(with: url)
        waitForExpectations(timeout: 12)
        if !d.error {
            XCTAssertEqual(d.capital, "Kathmandu", "test_dataTaskWithURLRequest returned an unexpected result")
        }
    }
    
    func test_dataTaskWithURLCompletionHandler() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/USA"
        let url = URL(string: urlString)!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "URL test with completion handler")
        var expectedResult = "unknown"
        let task = session.dataTask(with: url) { data, response, error in
            defer { expect.fulfill() }
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            XCTAssertNotNil(response)
            XCTAssertNotNil(data)
            guard let httpResponse = response as? HTTPURLResponse, let data = data else { return }
            XCTAssertEqual(200, httpResponse.statusCode, "HTTP response code is not 200")
            expectedResult = String(data: data, encoding: String.Encoding.utf8) ?? ""
            XCTAssertEqual("Washington, D.C.", expectedResult, "Did not receive expected value")
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }
    
    func test_dataTaskWithURLRequest() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Peru"
        let urlRequest = URLRequest(url: URL(string: urlString)!)
        let d = DataTask(with: expectation(description: "data task"))
        d.run(with: urlRequest)
        waitForExpectations(timeout: 12)
        if !d.error {
            XCTAssertEqual(d.capital, "Lima", "test_dataTaskWithURLRequest returned an unexpected result")
        }
    }
    
    func test_dataTaskWithURLRequestCompletionHandler() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Italy"
        let urlRequest = URLRequest(url: URL(string: urlString)!)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "URL test with completion handler")
        var expectedResult = "unknown"
        let task = session.dataTask(with: urlRequest) { data, response, error in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNotNil(response)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let httpResponse = response as? HTTPURLResponse, let data = data else { return }
            XCTAssertEqual(200, httpResponse.statusCode, "HTTP response code is not 200")
            expectedResult = String(data: data, encoding: String.Encoding.utf8) ?? ""
            XCTAssertEqual("Rome", expectedResult, "Did not receive expected value")
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }
    
    func test_downloadTaskWithURL() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt"
        let url = URL(string: urlString)!
        let d = DownloadTask(with: expectation(description: "download task with delegate"))
        d.run(with: url)
        waitForExpectations(timeout: 12)
    }
    
    func test_downloadTaskWithURLRequest() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt"
        let urlRequest = URLRequest(url: URL(string: urlString)!)
        let d = DownloadTask(with: expectation(description: "download task with delegate"))
        d.run(with: urlRequest)
        waitForExpectations(timeout: 12)
    }
    
    func test_downloadTaskWithRequestAndHandler() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "download task with handler")
        let req = URLRequest(url: URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt")!)
        let task = session.downloadTask(with: req) { (_, _, error) -> Void in
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            expect.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }
    
    func test_downloadTaskWithURLAndHandler() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "download task with handler")
        let req = URLRequest(url: URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt")!)
        let task = session.downloadTask(with: req) { (_, _, error) -> Void in
            if let e = error as? URLError {
                XCTAssertEqual(e.code, .timedOut, "Unexpected error code")
            }
            expect.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }
    
    func test_finishTasksAndInvalidate() {
        let invalidateExpectation = expectation(description: "URLSession wasn't invalidated")
        let delegate = SessionDelegate(invalidateExpectation: invalidateExpectation)
        let url = URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/Nepal")!
        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: delegate, delegateQueue: nil)
        let completionExpectation = expectation(description: "dataTask completion block wasn't called")
        let task = session.dataTask(with: url) { (_, _, _) in
            completionExpectation.fulfill()
        }
        task.resume()
        session.finishTasksAndInvalidate()
        waitForExpectations(timeout: 12)
    }
    
    func test_taskError() {
        let url = URL(string: "http://127.0.0.1:-1/Nepal")!
        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: nil,
                                 delegateQueue: nil)
        let completionExpectation = expectation(description: "dataTask completion block wasn't called")
        let task = session.dataTask(with: url) { (_, _, result) in
            let error = result as? URLError
            XCTAssertNotNil(error)
            XCTAssertEqual(error?.code, .badURL)
            completionExpectation.fulfill()
        }
        //should result in Bad URL error
        task.resume()
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
            
            XCTAssertNotNil(task.error)
            XCTAssertEqual((task.error as? URLError)?.code, .badURL)
        }
    }
    
    func test_taskCopy() {
        let url = URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/Nepal")!
        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: nil,
                                 delegateQueue: nil)
        let task = session.dataTask(with: url)
        
        XCTAssert(task.isEqual(task.copy()))
    }
    
    func test_cancelTask() {
        let url = URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/Peru")!
        let d = DataTask(with: expectation(description: "Task to be canceled"))
        d.cancelExpectation = expectation(description: "URLSessionTask wasn't canceled")
        d.run(with: url)
        d.cancel()
        waitForExpectations(timeout: 12)
    }
    
    func test_verifyRequestHeaders() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "download task with handler")
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/requestHeaders")!)
        let headers = ["header1": "value1"]
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let data = data else { return }
            let headers = String(data: data, encoding: String.Encoding.utf8) ?? ""
            XCTAssertNotNil(headers.range(of: "header1: value1"))
        }
        task.resume()
        req.allHTTPHeaderFields = nil
        waitForExpectations(timeout: 30)
    }
    
    // Verify httpAdditionalHeaders from session configuration are added to the request
    // and whether it is overriden by Request.allHTTPHeaderFields.
    
    func test_verifyHttpAdditionalHeaders() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.httpAdditionalHeaders = ["header2": "svalue2", "header3": "svalue3"]
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "download task with handler")
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/requestHeaders")!)
        let headers = ["header1": "rvalue1", "header2": "rvalue2"]
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            let headers = String(data: data!, encoding: String.Encoding.utf8) ?? ""
            XCTAssertNotNil(headers.range(of: "header1: rvalue1"))
            XCTAssertNotNil(headers.range(of: "header2: rvalue2"))
            XCTAssertNotNil(headers.range(of: "header3: svalue3"))
        }
        task.resume()
        
        waitForExpectations(timeout: 30)
    }
    
    func test_taskTimeout() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "download task with handler")
        let req = URLRequest(url: URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/Peru")!)
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
        }
        task.resume()
        
        waitForExpectations(timeout: 30)
    }
    
    func test_timeoutInterval() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "download task with handler")
        var req = URLRequest(url: URL(string: "http://127.0.0.1:-1/Peru")!)
        req.timeoutInterval = 1
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(error)
        }
        task.resume()
        
        waitForExpectations(timeout: 30)
    }
    
    func test_customProtocol () {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/USA"
        let url = URL(string: urlString)!
        let config = URLSessionConfiguration.default
        config.protocolClasses = [CustomProtocol.self]
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "URL test with custom protocol")
        let task = session.dataTask(with: url) { data, response, error in
            defer { expect.fulfill() }
            if let e = error as? URLError {
                XCTAssertEqual(e.code, .timedOut, "Unexpected error code")
                return
            }
            let httpResponse = response as! HTTPURLResponse?
            XCTAssertEqual(429, httpResponse!.statusCode, "HTTP response code is not 429")
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }

    func test_customProtocolResponseWithDelegate() {
        let url = URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/Peru")!
        let d = DataTask(with: expectation(description: "Custom protocol with delegate"), protocolClasses: [CustomProtocol.self])
        d.responseReceivedExpectation = expectation(description: "A response wasn't received")
        d.run(with: url)
        waitForExpectations(timeout: 12)
    }
    
    func test_httpRedirection() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/UnitedStates"
        let url = URL(string: urlString)!
        let d = HTTPRedirectionDataTask(with: expectation(description: "data task"))
        d.run(with: url)
        waitForExpectations(timeout: 12)
    }

    func test_httpRedirectionTimeout() {
        var req = URLRequest(url: URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/UnitedStates")!)
        req.timeoutInterval = 3
        let config = URLSessionConfiguration.default
        var expect = expectation(description: "download task with handler")
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let task = session.dataTask(with: req) { data, response, error in
            defer { expect.fulfill() }
            if let e = error as? URLError {
                XCTAssertEqual(e.code, .timedOut, "Unexpected error code")
                return
            }
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }
}

class SessionDelegate: NSObject, URLSessionDelegate {
    let invalidateExpectation: XCTestExpectation
    init(invalidateExpectation: XCTestExpectation){
        self.invalidateExpectation = invalidateExpectation
    }
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        invalidateExpectation.fulfill()
    }
}

class DataTask : NSObject {
    let dataTaskExpectation: XCTestExpectation!
    var capital = "unknown"
    var session: URLSession! = nil
    var task: URLSessionDataTask! = nil
    var cancelExpectation: XCTestExpectation?
    var responseReceivedExpectation: XCTestExpectation?
    var protocols: [AnyClass]?
    
    public var error = false
    
    init(with expectation: XCTestExpectation, protocolClasses: [AnyClass]? = nil) {
        dataTaskExpectation = expectation
	protocols = protocolClasses
    }
    
    func run(with request: URLRequest) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        if let customProtocols = protocols {
            config.protocolClasses = customProtocols
        }
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.dataTask(with: request)
        task.resume()
    }
    
    func run(with url: URL) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        if let customProtocols = protocols {
            config.protocolClasses = customProtocols
        }
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.dataTask(with: url)
        task.resume()
    }
    
    func cancel() {
        task.cancel()
    }
}

extension DataTask : URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        capital = String(data: data, encoding: String.Encoding.utf8)!
    }

    public func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard responseReceivedExpectation != nil else { return }
        responseReceivedExpectation!.fulfill()
    }
}

extension DataTask : URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        dataTaskExpectation.fulfill()
        guard (error as? URLError) != nil else { return }
        if let cancellation = cancelExpectation {
            cancellation.fulfill()
        }
        self.error = true
    }
}

class DownloadTask : NSObject {
    var totalBytesWritten: Int64 = 0
    let dwdExpectation: XCTestExpectation!
    var session: URLSession! = nil
    var task: URLSessionDownloadTask! = nil
    
    init(with expectation: XCTestExpectation) {
        dwdExpectation = expectation
    }
    
    func run(with url: URL) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.downloadTask(with: url)
        task.resume()
    }
    
    func run(with urlRequest: URLRequest) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.downloadTask(with: urlRequest)
        task.resume()
    }
}

extension DownloadTask : URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void {
        self.totalBytesWritten = totalBytesWritten
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: location.path)
            XCTAssertEqual((attr[.size]! as? NSNumber)!.int64Value, totalBytesWritten, "Size of downloaded file not equal to total bytes downloaded")
        } catch {
            XCTFail("Unable to calculate size of the downloaded file")
        }
        dwdExpectation.fulfill()
    }
}

extension DownloadTask : URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let e = error as? URLError else { return }
        XCTAssertEqual(e.code, .timedOut, "Unexpected error code")
        dwdExpectation.fulfill()
    }
}

class CustomProtocol : URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    func sendResponse(statusCode: Int, headers: [String: String] = [:], data: Data) {
        let response = HTTPURLResponse(url: self.request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)
        self.client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        sendResponse(statusCode: 429, data: Data())
    }
    
    override func stopLoading() {
        return
    }
}

class HTTPRedirectionDataTask : NSObject {
    let dataTaskExpectation: XCTestExpectation!
    var session: URLSession! = nil
    var task: URLSessionDataTask! = nil
    var cancelExpectation: XCTestExpectation?
    
    public var error = false
    
    init(with expectation: XCTestExpectation) {
        dataTaskExpectation = expectation
    }
    
    func run(with request: URLRequest) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.dataTask(with: request)
        task.resume()
    }
    
    func run(with url: URL) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.dataTask(with: url)
        task.resume()
    }
    
    func cancel() {
        task.cancel()
    }
}

extension HTTPRedirectionDataTask : URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpresponse = response as? HTTPURLResponse else { fatalError() }
        XCTAssertNotNil(response)
        XCTAssertEqual(200, httpresponse.statusCode, "HTTP response code is not 200")
    }
}

extension HTTPRedirectionDataTask : URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        dataTaskExpectation.fulfill()
        guard (error as? URLError) != nil else { return }
        if let cancellation = cancelExpectation {
            cancellation.fulfill()
        }
        self.error = true
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        XCTAssertNotNil(response)
        XCTAssertEqual(302, response.statusCode, "HTTP response code is not 302")
        completionHandler(request)
    }
}
