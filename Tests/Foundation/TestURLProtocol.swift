// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestURLProtocol : LoopbackServerTest {
    func test_protocolPropertiesReachCustomProtocol() {
        let url = URL(string: "https://example.invalid/protocol-properties")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PropertyEchoProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let request = NSMutableURLRequest(url: url)
        URLProtocol.setProperty("present", forKey: "marker", in: request)
        let expect = expectation(description: "The protocol receives the request property")
        let task = session.dataTask(with: request as URLRequest) { data, _, error in
            defer { expect.fulfill() }
            XCTAssertNil(error)
            XCTAssertEqual(String(data: data ?? Data(), encoding: .utf8), "present")
        }

        task.resume()
        waitForExpectations(timeout: 5)
    }

    func test_interceptResponse() {
        let urlString = "http://127.0.0.1:\(TestURLProtocol.serverPort)/USA"
        let url = URL(string: urlString)!
        let config = URLSessionConfiguration.default
        config.protocolClasses = [CustomProtocol.self]
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "GET \(urlString): with a custom protocol")
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
    
    func test_interceptRequest() {
        let urlString = "ssh://127.0.0.1:\(TestURLProtocol.serverPort)/USA"
        let url = URL(string: urlString)!
        let config = URLSessionConfiguration.default
        config.protocolClasses = [InterceptableRequest.self]
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "GET \(urlString): with a custom protocol")
        let task = session.dataTask(with: url) { data, response, error in
            defer { expect.fulfill() }
            if let e = error as? URLError {
                XCTAssertEqual(e.code, .timedOut, "Unexpected error code")
                return
            }
            let httpResponse = response as! HTTPURLResponse?
            let responseURL = URL(string: "http://google.com")
            XCTAssertEqual(responseURL, httpResponse?.url, "Unexpected url")
            XCTAssertEqual(200, httpResponse!.statusCode, "HTTP response code is not 200")
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }
    
    func test_multipleCustomProtocols() {
        let urlString = "http://127.0.0.1:\(TestURLProtocol.serverPort)/Nepal"
        let url = URL(string: urlString)!
        let config = URLSessionConfiguration.default
        config.protocolClasses = [InterceptableRequest.self, CustomProtocol.self]
        let expect = expectation(description: "GET \(urlString): with a custom protocol")
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: url) { data, response, error in
            defer { expect.fulfill() }
            if let e = error as? URLError {
                XCTAssertEqual(e.code, .timedOut, "Unexpected error code")
                return
            }
            let httpResponse = response as! HTTPURLResponse
            print(httpResponse.statusCode)
            XCTAssertEqual(429, httpResponse.statusCode, "Status code is not 429")
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }
    
    func test_customProtocolResponseWithDelegate() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Peru"
        let url = URL(string: urlString)!
        let d = DataTask(with: expectation(description: "GET \(urlString): with a custom protocol and delegate"), protocolClasses: [CustomProtocol.self])
        d.responseReceivedExpectation = expectation(description: "GET \(urlString): response received")
        d.run(with: url)
        waitForExpectations(timeout: 12)
    }
    
    func test_customProtocolSetDataInResponseWithDelegate() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Nepal"
        let url = URL(string: urlString)!
        let d = DataTask(with: expectation(description: "GET \(urlString): with a custom protocol and delegate"), protocolClasses: [CustomProtocol.self])
        d.run(with: url)
        waitForExpectations(timeout: 12)
        if !d.error {
            XCTAssertEqual(d.capital, "Kathmandu", "test_dataTaskWithURLRequest returned an unexpected result")
        }
    }

    func test_finishLoadingWithNoResponse() throws {
        let url = try XCTUnwrap(URL(string: "https://test/url"))
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [TestURLServer.self]
        let session = URLSession(configuration: configuration)

        let expect = expectation(description: "GET \(url.absoluteString)")
        let task = session.dataTask(with: url) { data, response, error in
            defer { expect.fulfill() }
            XCTAssertNil(data)
            XCTAssertNil(response)
            XCTAssertNotNil(error)
        }

        task.resume()
        waitForExpectations(timeout: 2)
    }

    func test_incrementalDataWithCompletionHandler() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [IncrementalDataProtocol.self]
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        for path in ["empty", "single", "multiple"] {
            let url = URL(string: "http://127.0.0.1:\(Self.serverPort)/\(path)")!
            let expected = IncrementalDataProtocol.chunks(for: path).reduce(into: Data()) { $0.append($1) }
            let finished = expectation(description: "Completion for \(path)")
            let task = session.dataTask(with: url) { data, response, error in
                XCTAssertNil(error)
                XCTAssertEqual(data, expected)
                XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 203)
                XCTAssertEqual((response as? HTTPURLResponse)?.value(forHTTPHeaderField: "X-D02"), "chunks")
                finished.fulfill()
            }
            task.resume()
            wait(for: [finished], timeout: 2)
        }
    }

    func test_incrementalDataWithRequestCompletionHandler() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [IncrementalDataProtocol.self]
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let url = URL(string: "http://127.0.0.1:\(Self.serverPort)/multiple")!
        let finished = expectation(description: "Request completion")
        let task = session.dataTask(with: URLRequest(url: url)) { data, response, error in
            XCTAssertNil(error)
            XCTAssertEqual(data, Data([0x00, 0x66, 0xff, 0x41]))
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 203)
            finished.fulfill()
        }
        task.resume()
        wait(for: [finished], timeout: 2)
    }

    func test_incrementalDataWithCacheCandidate() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [IncrementalDataProtocol.self]
        configuration.urlCache = URLCache(memoryCapacity: 1024, diskCapacity: 0, diskPath: nil)
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let url = URL(string: "http://127.0.0.1:\(Self.serverPort)/cache-candidate")!
        let finished = expectation(description: "Completion with cache candidate")
        session.dataTask(with: url) { data, response, error in
            XCTAssertNil(error)
            XCTAssertEqual(data, Data([0x00, 0x66, 0xff, 0x41]))
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 203)
            finished.fulfill()
        }.resume()
        wait(for: [finished], timeout: 2)
    }

    func test_incrementalDataWithAsyncConveniences() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [IncrementalDataProtocol.self]
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let url = URL(string: "http://127.0.0.1:\(Self.serverPort)/multiple")!
        let expected = Data([0x00, 0x66, 0xff, 0x41])
        let (fromData, fromResponse) = try await session.data(from: url)
        XCTAssertEqual(fromData, expected)
        XCTAssertEqual((fromResponse as? HTTPURLResponse)?.statusCode, 203)

        let (requestData, requestResponse) = try await session.data(for: URLRequest(url: url))
        XCTAssertEqual(requestData, expected)
        XCTAssertEqual((requestResponse as? HTTPURLResponse)?.value(forHTTPHeaderField: "X-D02"), "chunks")
    }

    func test_incrementalDataWithDelegate() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [IncrementalDataProtocol.self]
        configuration.urlCache = nil
        let finished = expectation(description: "Delegate completion")
        let delegate = IncrementalDataDelegate(finished: finished)
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }

        let url = URL(string: "http://127.0.0.1:\(Self.serverPort)/multiple")!
        session.dataTask(with: url).resume()
        wait(for: [finished], timeout: 2)
        XCTAssertNil(delegate.error)
        XCTAssertEqual(delegate.chunks, [Data([0x00, 0x66]), Data([0xff, 0x41])])
    }

    func test_incrementalDataFailureDoesNotReturnPartialBody() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [IncrementalDataProtocol.self]
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let url = URL(string: "http://127.0.0.1:\(Self.serverPort)/failure")!
        let finished = expectation(description: "Failed completion")
        session.dataTask(with: url) { data, response, error in
            XCTAssertNil(data)
            XCTAssertNil(response)
            XCTAssertEqual((error as? URLError)?.code, .networkConnectionLost)
            finished.fulfill()
        }.resume()
        wait(for: [finished], timeout: 2)
    }
}

private final class IncrementalDataProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    static func chunks(for path: String) -> [Data] {
        switch path {
        case "empty": return []
        case "single": return [Data([0x00, 0x66, 0xff, 0x41])]
        default: return [Data([0x00, 0x66]), Data([0xff, 0x41])]
        }
    }

    override func startLoading() {
        let chunks = Self.chunks(for: request.url!.lastPathComponent)
        let length = chunks.reduce(0) { $0 + $1.count }
        let response = HTTPURLResponse(url: request.url!, statusCode: 203, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Length": String(length), "X-D02": "chunks"])!
        let policy: URLCache.StoragePolicy = request.url!.lastPathComponent == "cache-candidate" ? .allowed : .notAllowed
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
        for chunk in chunks {
            client?.urlProtocol(self, didLoad: chunk)
        }
        if request.url!.lastPathComponent == "failure" {
            client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
            return
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class IncrementalDataDelegate: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    let finished: XCTestExpectation
    private let lock = NSLock()
    private var receivedChunks: [Data] = []
    private var completionError: Error?

    init(finished: XCTestExpectation) {
        self.finished = finished
    }

    var chunks: [Data] { lock.withLock { receivedChunks } }
    var error: Error? { lock.withLock { completionError } }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.withLock { receivedChunks.append(data) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.withLock { completionError = error }
        finished.fulfill()
    }
}

private class PropertyEchoProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "example.invalid"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let value = URLProtocol.property(forKey: "marker", in: request) as? String ?? "<missing>"
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(value.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

class InterceptableRequest : URLProtocol {

    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme == "ssh"
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        let urlString = "http://google.com"
        let url = URL(string: urlString)!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])
        self.client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocolDidFinishLoading(self)
        
    }

    override func stopLoading() {
        return
    }
}

class CustomProtocol : URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    func sendResponse(statusCode: Int, headers: [String: String] = [:], data: Data) {
        let response = HTTPURLResponse(url: self.request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)
        let capital = "Kathmandu"
        let data = capital.data(using: .utf8)
        self.client?.urlProtocol(self, didReceive: response!, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocol(self, didLoad: data!)
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


public class TestURLServer: URLProtocol {
    public override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    public override func startLoading() {
        var info: [String: Any] = [:]
        if let url = request.url {
            info[NSURLErrorFailingURLStringErrorKey] = url.absoluteString
            info[NSURLErrorFailingURLErrorKey] = url
        }
        let error = URLError(.networkConnectionLost, userInfo: info)

        client?.urlProtocol(self, didFailWithError: error)
        client?.urlProtocolDidFinishLoading(self)
    }

    public override func stopLoading() {
    }
}
