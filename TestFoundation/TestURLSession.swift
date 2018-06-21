// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestURLSession : LoopbackServerTest {
    
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
            ("test_httpRedirectionWithCompleteRelativePath", test_httpRedirectionWithCompleteRelativePath),
            ("test_httpRedirectionWithInCompleteRelativePath", test_httpRedirectionWithInCompleteRelativePath),
            ("test_httpRedirectionTimeout", test_httpRedirectionTimeout),
            ("test_http0_9SimpleResponses", test_http0_9SimpleResponses),
            ("test_outOfRangeButCorrectlyFormattedHTTPCode", test_outOfRangeButCorrectlyFormattedHTTPCode),
            ("test_missingContentLengthButStillABody", test_missingContentLengthButStillABody),
            ("test_illegalHTTPServerResponses", test_illegalHTTPServerResponses),
            ("test_dataTaskWithSharedDelegate", test_dataTaskWithSharedDelegate),
            // ("test_simpleUploadWithDelegate", test_simpleUploadWithDelegate), - Server needs modification
            ("test_concurrentRequests", test_concurrentRequests),
            ("test_disableCookiesStorage", test_disableCookiesStorage),
            ("test_cookiesStorage", test_cookiesStorage),
            ("test_setCookies", test_setCookies),
            ("test_dontSetCookies", test_dontSetCookies),
            ("test_initURLSessionConfiguration", test_initURLSessionConfiguration),
        ]
    }
    
    func test_dataTaskWithURL() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Nepal"
        let url = URL(string: urlString)!
        let d = DataTask(with: expectation(description: "GET \(urlString): with a delegate"))
        d.run(with: url)
        waitForExpectations(timeout: 12)
        if !d.error {
            XCTAssertEqual(d.capital, "Kathmandu", "test_dataTaskWithURLRequest returned an unexpected result")
        }
    }
    
    func test_dataTaskWithURLCompletionHandler() {
        //shared session
        dataTaskWithURLCompletionHandler(with: URLSession.shared)

        //new session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        dataTaskWithURLCompletionHandler(with: session)
    }

    func dataTaskWithURLCompletionHandler(with session: URLSession) {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/USA"
        let url = URL(string: urlString)!
        let expect = expectation(description: "GET \(urlString): with a completion handler")
        var expectedResult = "unknown"
        let task = session.dataTask(with: url) { data, response, error in
            defer { expect.fulfill() }
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            XCTAssertNotNil(response)
            XCTAssertNotNil(data)
            guard let httpResponse = response as? HTTPURLResponse, let data = data else { return }
            XCTAssertEqual(200, httpResponse.statusCode, "HTTP response code is not 200")
            expectedResult = String(data: data, encoding: .utf8) ?? ""
            XCTAssertEqual("Washington, D.C.", expectedResult, "Did not receive expected value")
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }
    
    func test_dataTaskWithURLRequest() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Peru"
        let urlRequest = URLRequest(url: URL(string: urlString)!)
        let d = DataTask(with: expectation(description: "GET \(urlString): with a delegate"))
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
        let expect = expectation(description: "GET \(urlString): with a completion handler")
        var expectedResult = "unknown"
        let task = session.dataTask(with: urlRequest) { data, response, error in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNotNil(response)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let httpResponse = response as? HTTPURLResponse, let data = data else { return }
            XCTAssertEqual(200, httpResponse.statusCode, "HTTP response code is not 200")
            expectedResult = String(data: data, encoding: .utf8) ?? ""
            XCTAssertEqual("Rome", expectedResult, "Did not receive expected value")
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }
    
    func test_downloadTaskWithURL() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt"
        let url = URL(string: urlString)!
        let d = DownloadTask(with: expectation(description: "Download GET \(urlString): with a delegate"))
        d.run(with: url)
        waitForExpectations(timeout: 12)
    }
    
    func test_downloadTaskWithURLRequest() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt"
        let urlRequest = URLRequest(url: URL(string: urlString)!)
        let d = DownloadTask(with: expectation(description: "Download GET \(urlString): with a delegate"))
        d.run(with: urlRequest)
        waitForExpectations(timeout: 12)
    }
    
    func test_downloadTaskWithRequestAndHandler() {
        //shared session
        downloadTaskWithRequestAndHandler(with: URLSession.shared)

        //newly created session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        downloadTaskWithRequestAndHandler(with: session)
    }

    func downloadTaskWithRequestAndHandler(with session: URLSession) {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt"
        let expect = expectation(description: "Download GET \(urlString): with a completion handler")
        let req = URLRequest(url: URL(string: urlString)!)
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
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "Download GET \(urlString): with a completion handler")
        let req = URLRequest(url: URL(string: urlString)!)
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
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Nepal"
        let invalidateExpectation = expectation(description: "Session invalidation")
        let delegate = SessionDelegate(invalidateExpectation: invalidateExpectation)
        let url = URL(string: urlString)!
        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: delegate, delegateQueue: nil)
        let completionExpectation = expectation(description: "GET \(urlString): task completion before session invalidation")
        let task = session.dataTask(with: url) { (_, _, _) in
            completionExpectation.fulfill()
        }
        task.resume()
        session.finishTasksAndInvalidate()
        waitForExpectations(timeout: 12)
    }
    
    func test_taskError() {
        let urlString = "http://127.0.0.1:-1/Nepal"
        let url = URL(string: urlString)!
        let session = URLSession(configuration: URLSessionConfiguration.default,
                                 delegate: nil,
                                 delegateQueue: nil)
        let completionExpectation = expectation(description: "GET \(urlString): Bad URL error")
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

    // This test is buggy becuase the server could respond before the task is cancelled.
    func test_cancelTask() {
#if os(Android)
        XCTFail("Intermittent failures on Android")
#else
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Peru"
        var urlRequest = URLRequest(url: URL(string: urlString)!)
        urlRequest.setValue("2.0", forHTTPHeaderField: "X-Pause")
        let d = DataTask(with: expectation(description: "GET \(urlString): task cancelation"))
        d.cancelExpectation = expectation(description: "GET \(urlString): task canceled")
        d.run(with: urlRequest)
        d.cancel()
        waitForExpectations(timeout: 12)
#endif
    }
    
    func test_verifyRequestHeaders() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/requestHeaders"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString): get request headers")
        var req = URLRequest(url: URL(string: urlString)!)
        let headers = ["header1": "value1"]
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let data = data else { return }
            let headers = String(data: data, encoding: .utf8) ?? ""
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
        config.httpAdditionalHeaders = ["header2": "svalue2", "header3": "svalue3", "header4": "svalue4"]
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/requestHeaders"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString) with additional headers")
        var req = URLRequest(url: URL(string: urlString)!)
        let headers = ["header1": "rvalue1", "header2": "rvalue2", "Header4": "rvalue4"]
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = headers
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let data = data else { return }
            let headers = String(data: data, encoding: .utf8) ?? ""
            XCTAssertNotNil(headers.range(of: "header1: rvalue1"))
            XCTAssertNotNil(headers.range(of: "header2: rvalue2"))
            XCTAssertNotNil(headers.range(of: "header3: svalue3"))
            XCTAssertNotNil(headers.range(of: "Header4: rvalue4"))
            XCTAssertNil(headers.range(of: "header4: svalue"))
        }
        task.resume()
        
        waitForExpectations(timeout: 30)
    }
    
    func test_taskTimeout() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Peru"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "GET \(urlString): no timeout")
        let req = URLRequest(url: URL(string: urlString)!)
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
        let urlString = "http://127.0.0.1:-1/Peru"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "GET \(urlString): will timeout")
        var req = URLRequest(url: URL(string: "http://127.0.0.1:-1/Peru")!)
        req.timeoutInterval = 1
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(error)
        }
        task.resume()
        
        waitForExpectations(timeout: 30)
    }
    
    func test_httpRedirectionWithCompleteRelativePath() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/UnitedStates"
        let url = URL(string: urlString)!
        let d = HTTPRedirectionDataTask(with: expectation(description: "GET \(urlString): with HTTP redirection"))
        d.run(with: url)
        waitForExpectations(timeout: 12)
    }

    func test_httpRedirectionWithInCompleteRelativePath() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/UnitedKingdom"
        let url = URL(string: urlString)!
        let d = HTTPRedirectionDataTask(with: expectation(description: "GET \(urlString): with HTTP redirection"))
        d.run(with: url)
        waitForExpectations(timeout: 12)
    }

     // temporarily disabled (https://bugs.swift.org/browse/SR-5751)
    func test_httpRedirectionTimeout() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/UnitedStates"
        var req = URLRequest(url: URL(string: urlString)!)
        req.timeoutInterval = 3
        let config = URLSessionConfiguration.default
        var expect = expectation(description: "GET \(urlString): timeout with redirection ")
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let task = session.dataTask(with: req) { data, response, error in
            defer { expect.fulfill() }
            if let e = error as? URLError {
                XCTAssertEqual(e.code, .cannotConnectToHost, "Unexpected error code")
                return
            } else {
                XCTFail("test unexpectedly succeeded (response=\(response.debugDescription))")
            }
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }

    func test_http0_9SimpleResponses() {
        for brokenCity in ["Pompeii", "Sodom"] {
            let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/LandOfTheLostCities/\(brokenCity)"
            let url = URL(string: urlString)!

            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 8
            let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
            let expect = expectation(description: "GET \(urlString): simple HTTP/0.9 response")
            var expectedResult = "unknown"
            let task = session.dataTask(with: url) { data, response, error in
                XCTAssertNotNil(data)
                XCTAssertNotNil(response)
                XCTAssertNil(error)

                defer { expect.fulfill() }

                guard let httpResponse = response as? HTTPURLResponse else {
                    XCTFail("response (\(response.debugDescription)) invalid")
                    return
                }
                XCTAssertEqual(200, httpResponse.statusCode, "HTTP response code is not 200")
            }
            task.resume()
            waitForExpectations(timeout: 12)
        }
    }

    func test_outOfRangeButCorrectlyFormattedHTTPCode() {
        let brokenCity = "Kameiros"
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/LandOfTheLostCities/\(brokenCity)"
        let url = URL(string: urlString)!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "GET \(urlString): out of range HTTP code")
        let task = session.dataTask(with: url) { data, response, error in
            XCTAssertNotNil(data)
            XCTAssertNotNil(response)
            XCTAssertNil(error)

            defer { expect.fulfill() }

            guard let httpResponse = response as? HTTPURLResponse else {
                XCTFail("response (\(response.debugDescription)) invalid")
                return
            }
            XCTAssertEqual(999, httpResponse.statusCode, "HTTP response code is not 999")
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }

    func test_missingContentLengthButStillABody() {
        let brokenCity = "Myndus"
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/LandOfTheLostCities/\(brokenCity)"
        let url = URL(string: urlString)!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "GET \(urlString): missing content length")
        let task = session.dataTask(with: url) { data, response, error in
            XCTAssertNotNil(data)
            XCTAssertNotNil(response)
            XCTAssertNil(error)

            defer { expect.fulfill() }

            guard let httpResponse = response as? HTTPURLResponse else {
                XCTFail("response (\(response.debugDescription)) invalid")
                return
            }
            XCTAssertEqual(200, httpResponse.statusCode, "HTTP response code is not 200")
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }


    func test_illegalHTTPServerResponses() {
        for brokenCity in ["Gomorrah", "Dinavar", "Kuhikugu"] {
            let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/LandOfTheLostCities/\(brokenCity)"
            let url = URL(string: urlString)!

            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 8
            let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
            let expect = expectation(description: "GET \(urlString): illegal response")
            let task = session.dataTask(with: url) { data, response, error in
                XCTAssertNil(data)
                XCTAssertNil(response)
                XCTAssertNotNil(error)

                defer { expect.fulfill() }
            }
            task.resume()
            waitForExpectations(timeout: 12)
        }
    }

    func test_dataTaskWithSharedDelegate() {
        let sharedDelegate = SharedDelegate()
        let urlString0 = "http://127.0.0.1:\(TestURLSession.serverPort)/Nepal"
        let session = URLSession(configuration: .default, delegate: sharedDelegate, delegateQueue: nil)

        let dataRequest = URLRequest(url: URL(string: urlString0)!)
        let dataTask = session.dataTask(with: dataRequest)

        sharedDelegate.dataCompletionExpectation = expectation(description: "GET \(urlString0)")
        dataTask.resume()
        waitForExpectations(timeout: 20)
    }

    func test_simpleUploadWithDelegate() {
        let delegate = HTTPUploadDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/upload"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "PUT"

        delegate.uploadCompletedExpectation = expectation(description: "PUT \(urlString): Upload data")

        let fileData = Data(count: 16*1024)
        let task = session.uploadTask(with: request, from: fileData)
        task.resume()
        waitForExpectations(timeout: 20)
    }

    func test_concurrentRequests() {
        // "10 tasks ought to be enough for anybody"
        let tasks = 10
        let syncQ = dispatchQueueMake("test_dataTaskWithURL.syncQ")
        var dataTasks: [DataTask] = []
        let g = dispatchGroupMake()
        for f in 0..<tasks {
            g.enter()
            let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Nepal"
            let expectation = self.expectation(description: "GET \(urlString) [\(f)]: with a delegate")
            globalDispatchQueue.async {
                let url = URL(string: urlString)!
                let d = DataTask(with: expectation)
                d.run(with: url)
                syncQ.async {
                    dataTasks.append(d)
                    g.leave()
                }
            }
        }
        waitForExpectations(timeout: 12)
        g.wait()
        for d in syncQ.sync(execute: {dataTasks}) {
            if !d.error {
                XCTAssertEqual(d.capital, "Kathmandu", "test_dataTaskWithURLRequest returned an unexpected result")
            }
        }
    }

    func test_disableCookiesStorage() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.never
        if let storage = config.httpCookieStorage, let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }
        XCTAssertEqual(config.httpCookieStorage?.cookies?.count, 0)
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/requestCookies"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString)")
        var req = URLRequest(url: URL(string: urlString)!)
        req.httpMethod = "POST"
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
        }
        task.resume()
        waitForExpectations(timeout: 30)
        let cookies = HTTPCookieStorage.shared.cookies
        XCTAssertEqual(cookies?.count, 0)
    }

    func test_cookiesStorage() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/requestCookies"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString)")
        var req = URLRequest(url: URL(string: urlString)!)
        req.httpMethod = "POST"
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
        }
        task.resume()
        waitForExpectations(timeout: 30)
        let cookies = HTTPCookieStorage.shared.cookies
        XCTAssertEqual(cookies?.count, 1)
    }

    func test_setCookies() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/setCookies"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString)")
        var req = URLRequest(url: URL(string: urlString)!)
        req.httpMethod = "POST"
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let data = data else { return }
            let headers = String(data: data, encoding: String.Encoding.utf8) ?? ""
            XCTAssertNotNil(headers.range(of: "Cookie: fr=anjd&232"))
        }
        task.resume()
        waitForExpectations(timeout: 30)
    }

    func test_dontSetCookies() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.httpShouldSetCookies = false
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/setCookies"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString)")
        var req = URLRequest(url: URL(string: urlString)!)
        req.httpMethod = "POST"
        var task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let data = data else { return }
            let headers = String(data: data, encoding: String.Encoding.utf8) ?? ""
            XCTAssertNil(headers.range(of: "Cookie: fr=anjd&232"))
        }
        task.resume()
        waitForExpectations(timeout: 30)
    }

    // Validate that the properties are correctly set
    func test_initURLSessionConfiguration() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .useProtocolCachePolicy
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 604800
        config.networkServiceType = .default
        config.allowsCellularAccess = false
        config.isDiscretionary = true
        config.httpShouldUsePipelining = true
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        config.httpMaximumConnectionsPerHost = 2
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.urlCredentialStorage = nil
        config.urlCache = nil
        config.shouldUseExtendedBackgroundIdleMode = true

        XCTAssertEqual(config.requestCachePolicy, NSURLRequest.CachePolicy.useProtocolCachePolicy)
        XCTAssertEqual(config.timeoutIntervalForRequest, 30)
        XCTAssertEqual(config.timeoutIntervalForResource, 604800)
        XCTAssertEqual(config.networkServiceType, NSURLRequest.NetworkServiceType.default)
        XCTAssertEqual(config.allowsCellularAccess, false)
        XCTAssertEqual(config.isDiscretionary, true)
        XCTAssertEqual(config.httpShouldUsePipelining, true)
        XCTAssertEqual(config.httpShouldSetCookies, true)
        XCTAssertEqual(config.httpCookieAcceptPolicy, HTTPCookie.AcceptPolicy.always)
        XCTAssertEqual(config.httpMaximumConnectionsPerHost, 2)
        XCTAssertEqual(config.httpCookieStorage, HTTPCookieStorage.shared)
        XCTAssertEqual(config.urlCredentialStorage, nil)
        XCTAssertEqual(config.urlCache, nil)
        XCTAssertEqual(config.shouldUseExtendedBackgroundIdleMode, true)
    }
}

class SharedDelegate: NSObject {
    var dataCompletionExpectation: XCTestExpectation!
}

extension SharedDelegate: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        dataCompletionExpectation.fulfill()
    }
}

extension SharedDelegate: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
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
    let syncQ = dispatchQueueMake("org.swift.TestFoundation.TestURLSession.DataTask.syncQ")
    let dataTaskExpectation: XCTestExpectation!
    let protocols: [AnyClass]?

    /* all the following var _XYZ need to be synchronized on syncQ.
       We can't just assert that we're on main thread here as we're modified in the URLSessionDataDelegate extension
       for DataTask
     */
    var _capital = "unknown"
    var capital: String {
        get {
            return self.syncQ.sync { self._capital }
        }
        set {
            self.syncQ.sync { self._capital = newValue }
        }
    }
    var _session: URLSession! = nil
    var session: URLSession! {
        get {
            return self.syncQ.sync { self._session }
        }
        set {
            self.syncQ.sync { self._session = newValue }
        }
    }
    var _task: URLSessionDataTask! = nil
    var task: URLSessionDataTask! {
        get {
            return self.syncQ.sync { self._task }
        }
        set {
            self.syncQ.sync { self._task = newValue }
        }
    }
    var _cancelExpectation: XCTestExpectation?
    var cancelExpectation: XCTestExpectation? {
        get {
            return self.syncQ.sync { self._cancelExpectation }
        }
        set {
            self.syncQ.sync { self._cancelExpectation = newValue }
        }
    }
    var _responseReceivedExpectation: XCTestExpectation?
    var responseReceivedExpectation: XCTestExpectation? {
        get {
            return self.syncQ.sync { self._responseReceivedExpectation }
        }
        set {
            self.syncQ.sync { self._responseReceivedExpectation = newValue }
        }
    }
    
    private var _error = false
    public var error: Bool {
        get {
            return self.syncQ.sync { self._error }
        }
        set {
            self.syncQ.sync { self._error = newValue }
        }
    }
    
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
        capital = String(data: data, encoding: .utf8)!
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

class HTTPUploadDelegate: NSObject {
    var uploadCompletedExpectation: XCTestExpectation!
    var totalBytesSent: Int64 = 0
}

extension HTTPUploadDelegate: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.totalBytesSent = totalBytesSent
    }
}

extension HTTPUploadDelegate: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        XCTAssertEqual(self.totalBytesSent, 16*1024)
        uploadCompletedExpectation.fulfill()
    }
}
