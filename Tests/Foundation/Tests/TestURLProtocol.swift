// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestURLProtocol : LoopbackServerTest {
    
    static var allTests: [(String, (TestURLProtocol) -> () throws -> Void)] {
        return [
            ("test_interceptResponse", test_interceptResponse),
            ("test_interceptRequest", test_interceptRequest),
            ("test_multipleCustomProtocols", test_multipleCustomProtocols),
            ("test_customProtocolResponseWithDelegate", test_customProtocolResponseWithDelegate),
            ("test_customProtocolSetDataInResponseWithDelegate", test_customProtocolSetDataInResponseWithDelegate),
        ]
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
