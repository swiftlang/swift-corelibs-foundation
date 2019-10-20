// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if !os(Windows)

class TestURLSessionFTP : LoopbackFTPServerTest {

    static var allTests: [(String, (TestURLSessionFTP) -> () throws -> Void)] {
        return [
            /* ⚠️ */ ("test_ftpDataTask", testExpectedToFail(test_ftpDataTask,
            /* ⚠️ */     "<https://bugs.swift.org/browse/SR-10922>  non-deterministic SEGFAULT in TestURLSessionFTP.test_ftpDataTask")),
            /* ⚠️ */ ("test_ftpDataTaskDelegate", testExpectedToFail(test_ftpDataTaskDelegate,
            /* ⚠️ */     "<https://bugs.swift.org/browse/SR-10922>  non-deterministic SEGFAULT in TestURLSessionFTP.test_ftpDataTask")),
        ]
    }

    let saveString = """
                     FTP implementation to test FTP
                     upload, download and data tasks. Instead of sending a file,
                     we are sending the hardcoded data.We are going to test FTP
                     data, download and upload tasks with delegates & completion handlers.
                     Creating the data here as we need to pass the count
                     as part of the header.\r\n
                     """

    func test_ftpDataTask() {
#if !DARWIN_COMPATIBILITY_TESTS
            let ftpURL = "ftp://127.0.0.1:\(TestURLSessionFTP.serverPort)/test.txt"
            let req = URLRequest(url: URL(string: ftpURL)!)
            let configuration = URLSessionConfiguration.default
            let expect = expectation(description: "URL test with custom protocol")
            let sesh = URLSession(configuration: configuration)
            let dataTask1 = sesh.dataTask(with: req, completionHandler: { data, res, error in
                defer { expect.fulfill() }
                XCTAssertNil(error)
                XCTAssertEqual(self.saveString, String(data: data!, encoding: String.Encoding.utf8))

            })
            dataTask1.resume()
            waitForExpectations(timeout: 60)
#endif
    }
   
    func test_ftpDataTaskDelegate() {
        let urlString = "ftp://127.0.0.1:\(TestURLSessionFTP.serverPort)/test.txt"
        let url = URL(string: urlString)!
        let dataTask = FTPDataTask(with: expectation(description: "data task"))
        dataTask.run(with: url)
        waitForExpectations(timeout: 60)
        if !dataTask.error {
            XCTAssertNotNil(dataTask.fileData)
        }
    }
}

class FTPDataTask : NSObject {
    let dataTaskExpectation: XCTestExpectation!
    var fileData: NSMutableData = NSMutableData()
    var session: URLSession! = nil
    var task: URLSessionDataTask! = nil
    var cancelExpectation: XCTestExpectation?
    var responseReceivedExpectation: XCTestExpectation?
    var hasTransferCompleted = false

    private var errorLock = NSLock()
    private var _error = false
    public var error: Bool {
        get { errorLock.synchronized { _error } }
        set { errorLock.synchronized { _error = newValue } }
    }
    
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

extension FTPDataTask : URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        fileData.append(data)
        responseReceivedExpectation?.fulfill()
    }
    
    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard responseReceivedExpectation != nil else { return }
        responseReceivedExpectation!.fulfill()
    }
}

extension FTPDataTask : URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        dataTaskExpectation.fulfill()
        guard (error as? URLError) != nil else { return }
        if let cancellation = cancelExpectation {
            cancellation.fulfill()
        }
        self.error = true
    }
}
#endif
