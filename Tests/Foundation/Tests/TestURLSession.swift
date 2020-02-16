// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestURLSession : LoopbackServerTest {
    
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
    
    func test_dataTaskWithHttpInputStream() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/echo"
        
        let dataString = """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras congue laoreet facilisis. Sed porta tristique orci. Fusce ut nisl dignissim, tempor tortor id, molestie neque. Nam non tincidunt mi. Integer ac diam quis leo aliquam congue et non magna. In porta mauris suscipit erat pulvinar, sed fringilla quam ornare. Nulla vulputate et ligula vitae sollicitudin. Nulla vel vehicula risus. Quisque eu urna ullamcorper, tincidunt ante vitae, aliquet sem. Suspendisse nec turpis placerat, porttitor ex vel, tristique orci. Maecenas pretium, augue non elementum imperdiet, diam ex vestibulum tortor, non ultrices ante enim iaculis ex.

            Suspendisse ante eros, scelerisque ut molestie vitae, lacinia nec metus. Sed in feugiat sem. Nullam sed congue nulla, id vehicula mauris. Aliquam ultrices ultricies pellentesque. Etiam blandit ultrices quam in egestas. Donec a vulputate est, ut ultricies dui. In non maximus velit.

            Vivamus vehicula faucibus odio vel maximus. Vivamus elementum, quam at accumsan rhoncus, ex ligula maximus sem, sed pretium urna enim ut urna. Donec semper porta augue at faucibus. Quisque vel congue purus. Morbi vitae elit pellentesque, finibus lectus quis, laoreet nulla. Praesent in fermentum felis. Aenean vestibulum dictum lorem quis egestas. Sed dictum elementum est laoreet volutpat.
        """
        
        let url = URL(string: urlString)!
        let urlSession = URLSession(configuration: URLSessionConfiguration.default)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        guard let data = dataString.data(using: .utf8) else {
            XCTFail()
            return
        }
        
        let inputStream = InputStream(data: data)
        inputStream.open()
        
        urlRequest.httpBodyStream = inputStream
        
        urlRequest.setValue("en-us", forHTTPHeaderField: "Accept-Language")
        urlRequest.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("chunked", forHTTPHeaderField: "Transfer-Encoding")
        
        let expect = expectation(description: "POST \(urlString): with HTTP Body as InputStream")
        let task = urlSession.dataTask(with: urlRequest) { respData, response, error in
            XCTAssertNotNil(respData)
            XCTAssertNotNil(response)
            XCTAssertNil(error)
            
            defer { expect.fulfill() }
            guard let httpResponse = response as? HTTPURLResponse else {
                XCTFail("response (\(response.debugDescription)) invalid")
                return
            }
            
            XCTAssertEqual(data, respData!, "Response Data and Data is not equal")
            XCTAssertEqual(200, httpResponse.statusCode, "HTTP response code is not 200")
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }

    func test_gzippedDataTask() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/gzipped-response"
        let url = URL(string: urlString)!
        let d = DataTask(with: expectation(description: "GET \(urlString): gzipped response"))
        d.run(with: url)
        waitForExpectations(timeout: 12)
        if !d.error {
            XCTAssertEqual(d.capital, "Hello World!")
        }
    }

    func test_downloadTaskWithURL() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt"
        let url = URL(string: urlString)!
        let d = DownloadTask(testCase: self, description: "Download GET \(urlString): with a delegate")
        d.run(with: url)
        waitForExpectations(timeout: 12)
    }
    
    func test_downloadTaskWithURLRequest() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt"
        let urlRequest = URLRequest(url: URL(string: urlString)!)
        let d = DownloadTask(testCase: self, description: "Download GET \(urlString): with a delegate")
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

    func test_gzippedDownloadTask() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/gzipped-response"
        let url = URL(string: urlString)!
        let d = DownloadTask(testCase: self, description: "GET \(urlString): gzipped response")
        d.run(with: url)
        waitForExpectations(timeout: 12)
        if d.totalBytesWritten != "Hello World!".utf8.count {
            XCTFail("Expected the gzipped-response to be the length of Hello World!")
        }
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
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/Peru"
        var urlRequest = URLRequest(url: URL(string: urlString)!)
        urlRequest.setValue("2.0", forHTTPHeaderField: "X-Pause")
        let d = DataTask(with: expectation(description: "GET \(urlString): task cancelation"))
        d.cancelExpectation = expectation(description: "GET \(urlString): task canceled")
        d.run(with: urlRequest)
        d.cancel()
        waitForExpectations(timeout: 12)
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
        let task = session.dataTask(with: req) { (data, _, error) -> Void in
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
        let task = session.dataTask(with: req) { (data, _, error) -> Void in
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
        let task = session.dataTask(with: req) { (data, _, error) -> Void in
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
        let task = session.dataTask(with: req) { (data, _, error) -> Void in
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

    func test_httpRedirectionWithDefaultPort() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/redirect-with-default-port"
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

                expect.fulfill()
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

    func emptyCookieStorage(storage: HTTPCookieStorage?) {
        if let storage = storage, let cookies = storage.cookies {
            for cookie in cookies {
                storage.deleteCookie(cookie)
            }
        }
    }

    func test_disableCookiesStorage() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.httpCookieAcceptPolicy = HTTPCookie.AcceptPolicy.never
        emptyCookieStorage(storage: config.httpCookieStorage)
        XCTAssertEqual(config.httpCookieStorage?.cookies?.count, 0)
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/requestCookies"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString)")
        var req = URLRequest(url: URL(string: urlString)!)
        req.httpMethod = "POST"
        let task = session.dataTask(with: req) { (data, response, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let httpResponse = try? XCTUnwrap(response as? HTTPURLResponse) else {
                XCTFail("response should be a non-nil HTTPURLResponse")
                return
            }
            XCTAssertNotNil(httpResponse.allHeaderFields["Set-Cookie"])
        }
        task.resume()
        waitForExpectations(timeout: 30)
        let cookies = HTTPCookieStorage.shared.cookies
        XCTAssertEqual(cookies?.count, 0)
    }

    func test_cookiesStorage() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        emptyCookieStorage(storage: config.httpCookieStorage)
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/requestCookies"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString)")
        var req = URLRequest(url: URL(string: urlString)!)
        req.httpMethod = "POST"
        let task = session.dataTask(with: req) { (data, response, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let httpResponse = try? XCTUnwrap(response as? HTTPURLResponse) else {
                XCTFail("response should be a non-nil HTTPURLResponse")
                return
            }
            XCTAssertNotNil(httpResponse.allHeaderFields["Set-Cookie"])
        }
        task.resume()
        waitForExpectations(timeout: 30)
        let cookies = HTTPCookieStorage.shared.cookies
        XCTAssertEqual(cookies?.count, 1)
    }

    func test_redirectionWithSetCookies() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        emptyCookieStorage(storage: config.httpCookieStorage)
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/redirectToEchoHeaders"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString)")
        let req = URLRequest(url: URL(string: urlString)!)
        let task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            // Because /redirectToEchoHeaders is a redirection, this is the
            // final result of the redirection, not the redirection itself.
            guard let data = try? XCTUnwrap(data) else {
                XCTFail("data should not be nil")
                return
            }
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            let headers = String(data: data, encoding: String.Encoding.utf8) ?? ""
            XCTAssertNotNil(headers.range(of: "Cookie: redirect=true"))
        }
        task.resume()
        waitForExpectations(timeout: 30)
    }

    func test_previouslySetCookiesAreSentInLaterRequests() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        emptyCookieStorage(storage: config.httpCookieStorage)
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)

        let urlString1 = "http://127.0.0.1:\(TestURLSession.serverPort)/requestCookies"
        var expect1 = expectation(description: "POST \(urlString1)")
        var req1 = URLRequest(url: URL(string: urlString1)!)
        req1.httpMethod = "POST"

        let urlString2 = "http://127.0.0.1:\(TestURLSession.serverPort)/echoHeaders"
        var expect2 = expectation(description: "POST \(urlString2)")
        var req2 = URLRequest(url: URL(string: urlString2)!)
        req2.httpMethod = "POST"

        let task1 = session.dataTask(with: req1) { (data, response, error) -> Void in
            defer { expect1.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let httpResponse = try? XCTUnwrap(response as? HTTPURLResponse) else {
                XCTFail("response should be a non-nil HTTPURLResponse")
                return
            }
            XCTAssertNotNil(httpResponse.allHeaderFields["Set-Cookie"])

            let task2 = session.dataTask(with: req2) { (data, _, error) -> Void in
                defer { expect2.fulfill() }
                guard let data = try? XCTUnwrap(data) else {
                    XCTFail("data should not be nil")
                    return
                }
                XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
                let headers = String(data: data, encoding: String.Encoding.utf8) ?? ""
                XCTAssertNotNil(headers.range(of: "Cookie: fr=anjd&232"))
            }
            task2.resume()
        }
        task1.resume()

        waitForExpectations(timeout: 30)
    }

    func test_cookieStorageForEphemeralConfiguration() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        emptyCookieStorage(storage: config.httpCookieStorage)

        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/requestCookies"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString)")
        var req = URLRequest(url: URL(string: urlString)!)
        req.httpMethod = "POST"
        let task = session.dataTask(with: req) { (data, _, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
        }
        task.resume()
        waitForExpectations(timeout: 30)
        let cookies = config.httpCookieStorage?.cookies
        XCTAssertEqual(cookies?.count, 1)

        let config2 = URLSessionConfiguration.ephemeral
        let cookies2 = config2.httpCookieStorage?.cookies
        XCTAssertEqual(cookies2?.count, 0)
    }

    func test_setCookieHeadersCanBeIgnored() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.httpShouldSetCookies = false
        emptyCookieStorage(storage: config.httpCookieStorage)
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)

        let urlString1 = "http://127.0.0.1:\(TestURLSession.serverPort)/requestCookies"
        var expect1 = expectation(description: "POST \(urlString1)")
        var req1 = URLRequest(url: URL(string: urlString1)!)
        req1.httpMethod = "POST"

        let urlString2 = "http://127.0.0.1:\(TestURLSession.serverPort)/echoHeaders"
        var expect2 = expectation(description: "POST \(urlString2)")
        var req2 = URLRequest(url: URL(string: urlString2)!)
        req2.httpMethod = "POST"

        let task1 = session.dataTask(with: req1) { (data, response, error) -> Void in
            defer { expect1.fulfill() }
            XCTAssertNotNil(data)
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let httpResponse = try? XCTUnwrap(response as? HTTPURLResponse) else {
                XCTFail("response should be a non-nil HTTPURLResponse")
                return
            }
            XCTAssertNotNil(httpResponse.allHeaderFields["Set-Cookie"])

            let task2 = session.dataTask(with: req2) { (data, _, error) -> Void in
                defer { expect2.fulfill() }
                guard let data = try? XCTUnwrap(data) else {
                    XCTFail("data should not be nil")
                    return
                }
                XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
                let headers = String(data: data, encoding: String.Encoding.utf8) ?? ""
                XCTAssertNil(headers.range(of: "Cookie: fr=anjd&232"))
            }
            task2.resume()
        }
        task1.resume()

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

   func test_basicAuthRequest() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/auth/basic"
        let url = URL(string: urlString)!
        let d = DataTask(with: expectation(description: "GET \(urlString): with a delegate"))
        d.run(with: url)
        waitForExpectations(timeout: 60)
    }

    /* Test for SR-8970 to verify that content-type header is not added to post with empty body */
    func test_postWithEmptyBody() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/emptyPost"
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        var expect = expectation(description: "POST \(urlString): post with empty body")
        var req = URLRequest(url: URL(string: urlString)!)
        req.httpMethod = "POST"
        let task = session.dataTask(with: req) { (_, response, error) -> Void in
            defer { expect.fulfill() }
            XCTAssertNil(error as? URLError, "error = \(error as! URLError)")
            guard let httpresponse = response as? HTTPURLResponse else { fatalError() }
            XCTAssertEqual(200, httpresponse.statusCode, "HTTP response code is not 200")
        }
        task.resume()
        waitForExpectations(timeout: 30)
    }

    func test_basicAuthWithUnauthorizedHeader() {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/unauthorized"
        let url = URL(string: urlString)!
        let expect = expectation(description: "GET \(urlString): with a completion handler")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: url) { _, response, error in
            defer { expect.fulfill() }
            XCTAssertNotNil(response)
            XCTAssertNil(error)
        }
        task.resume()
        waitForExpectations(timeout: 12, handler: nil)
    }

    func test_checkErrorTypeAfterInvalidateAndCancel() throws {
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt"
        let url = try XCTUnwrap(URL(string: urlString))
        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("5", forHTTPHeaderField: "X-Pause")
        let expect = expectation(description: "Check error code of tasks after invalidateAndCancel")
        let delegate = SessionDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: urlRequest) { (_, _, error) in
            XCTAssertNotNil(error as? URLError)
            if let urlError = error as? URLError {
                XCTAssertEqual(urlError._nsError.code, NSURLErrorCancelled)
            }

            expect.fulfill()
        }
        task.resume()
        session.invalidateAndCancel()
        waitForExpectations(timeout: 5)
    }

    func test_taskCountAfterInvalidateAndCancel() throws {
        let expect = expectation(description: "Check task count after invalidateAndCancel")

        let session = URLSession(configuration: .default)
        var request = URLRequest(url: try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt")))
        request.addValue("5", forHTTPHeaderField: "X-Pause")
        let task1 = session.dataTask(with: request)
        request.url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/requestHeaders"))
        let task2 = session.dataTask(with: request)
        request.url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/emptyPost"))
        let task3 = session.dataTask(with: request)

        task1.resume()
        task2.resume()
        session.invalidateAndCancel()

        session.getAllTasks { tasksBeforeResume in
            XCTAssertEqual(tasksBeforeResume.count, 0)

            // Resume a task after invalidating a session shouldn't change the task's status
            task3.resume()

            session.getAllTasks { tasksAfterResume in
                XCTAssertEqual(tasksAfterResume.count, 0)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 5)
    }

    func test_sessionDelegateAfterInvalidateAndCancel() {
        let delegate = SessionDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        session.invalidateAndCancel()
        Thread.sleep(forTimeInterval: 2)
        XCTAssertNil(session.delegate)
    }

    func test_getAllTasks() throws {
        let expect = expectation(description: "Tasks URLSession.getAllTasks")

        let session = URLSession(configuration: .default)
        var request = URLRequest(url: try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt")))
        request.addValue("5", forHTTPHeaderField: "X-Pause")
        let dataTask1 = session.dataTask(with: request)
        request.url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/requestHeaders"))
        let dataTask2 = session.dataTask(with: request)
        request.url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/emptyPost"))
        let dataTask3 = session.dataTask(with: request)

        session.getAllTasks { (tasksBeforeResume) in
            XCTAssertEqual(tasksBeforeResume.count, 0)

            dataTask1.cancel()

            dataTask2.resume()
            dataTask2.suspend()
            // dataTask3 is suspended even before it was resumed, so the next call to `getAllTasks` should not include this tasks
            dataTask3.suspend()
            session.getAllTasks { (tasksAfterCancel) in
                // tasksAfterCancel should only contain dataTask2
                XCTAssertEqual(tasksAfterCancel.count, 1)

                // A task will in be in suspended state when it was created.
                // Given that, dataTask3 was suspended once again earlier above, so it should receive `resume()` twice in order to be executed
                // Calling `getAllTasks` next time should not include dataTask3
                dataTask3.resume()

                session.getAllTasks { (tasksAfterFirstResume) in
                    // tasksAfterFirstResume should only contain dataTask2
                    XCTAssertEqual(tasksAfterFirstResume.count, 1)

                    // Now dataTask3 received `resume()` twice, this time `getAllTasks` should include
                    dataTask3.resume()
                    session.getAllTasks { (tasksAfterSecondResume) in
                        // tasksAfterSecondResume should contain dataTask2 and dataTask2 this time
                        XCTAssertEqual(tasksAfterSecondResume.count, 2)
                        expect.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 20)
    }

    func test_getTasksWithCompletion() throws {
        let expect = expectation(description: "Test URLSession.getTasksWithCompletion")

        let session = URLSession(configuration: .default)
        var request = URLRequest(url: try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/country.txt")))
        request.addValue("5", forHTTPHeaderField: "X-Pause")
        let dataTask1 = session.dataTask(with: request)
        request.url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/requestHeaders"))
        let dataTask2 = session.dataTask(with: request)
        request.url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/emptyPost"))
        let dataTask3 = session.dataTask(with: request)

        request.url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/upload"))
        let uploadTask1 = session.uploadTask(with: request, from: Data())
        request.url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/echo"))
        let uploadTask2 = session.uploadTask(with: request, from: Data())

        request.url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/DTDs/PropertyList-1.0.dtd"))
        let downloadTask1 = session.downloadTask(with: request)

        session.getTasksWithCompletionHandler { (dataTasksBeforeCancel, uploadTasksBeforeCancel, downloadTasksBeforeCancel) in
            XCTAssertEqual(dataTasksBeforeCancel.count, 0)
            XCTAssertEqual(uploadTasksBeforeCancel.count, 0)
            XCTAssertEqual(downloadTasksBeforeCancel.count, 0)

            dataTask1.cancel()
            dataTask2.resume()
            // dataTask3 is resumed and suspended, so this task should be a part of `getTasksWithCompletionHandler` response
            dataTask3.resume()
            dataTask3.suspend()

            // uploadTask1 suspended even before it was resumed, so this task shouldn't be a part of `getTasksWithCompletionHandler` response
            uploadTask1.suspend()
            uploadTask2.resume()

            downloadTask1.cancel()

            session.getTasksWithCompletionHandler{ (dataTasksAfterCancel, uploadTasksAfterCancel, downloadTasksAfterCancel) in
                XCTAssertEqual(dataTasksAfterCancel.count, 2)
                XCTAssertEqual(uploadTasksAfterCancel.count, 1)
                XCTAssertEqual(downloadTasksAfterCancel.count, 0)
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: 20)
    }

    func test_noDoubleCallbackWhenCancellingAndProtocolFailsFast() throws {
        let urlString = "failfast://bogus"
        var callbackCount = 0
        let callback1 = expectation(description: "Callback call #1")
        let callback2 = expectation(description: "Callback call #2")
        callback2.isInverted = true
        let delegate = SessionDelegate()
        let url = try XCTUnwrap(URL(string: urlString))
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [FailFastProtocol.self]
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        let task = session.dataTask(with: url) { (_, _, error) in
            callbackCount += 1
            XCTAssertNotNil(error)
            if let urlError = error as? URLError {
                XCTAssertNotEqual(urlError._nsError.code, NSURLErrorCancelled)
            }

            if callbackCount == 1 {
                callback1.fulfill()
            } else {
                callback2.fulfill()
            }
        }
        task.resume()
        session.invalidateAndCancel()
        waitForExpectations(timeout: 1)
    }

    func test_cancelledTasksCannotBeResumed() throws {
        let url = try XCTUnwrap(URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/Nepal"))
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        let task = session.dataTask(with: url)

        task.cancel() // should set .cancelling and eventually .completed
        task.resume() // should not change the task to .running

        let e = expectation(description: "getAllTasks callback called")
        session.getAllTasks { tasks in
            XCTAssertEqual(tasks.count, 0)
            e.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
    func test_invalidResumeDataForDownloadTask() {
        let done = expectation(description: "Invalid resume data for download task (with completion block)")
        URLSession.shared.downloadTask(withResumeData: Data()) { (url, response, error) in
            XCTAssertNil(url)
            XCTAssertNil(response)
            XCTAssert(error is URLError)
            XCTAssertEqual((error as? URLError)?.errorCode, URLError.unsupportedURL.rawValue)
            
            done.fulfill()
        }.resume()
        waitForExpectations(timeout: 20)
        
        let d = DownloadTask(testCase: self, description: "Invalid resume data for download task")
        d.run { (session) -> DownloadTask.Configuration in
            return DownloadTask.Configuration(task: session.downloadTask(withResumeData: Data()),
                                              errorExpectation:
                { (error) in
                    XCTAssert(error is URLError)
                    XCTAssertEqual((error as? URLError)?.errorCode, URLError.unsupportedURL.rawValue)
            })
        }
        waitForExpectations(timeout: 20)
    }
    
    func test_simpleUploadWithDelegateProvidingInputStream() throws {
        let delegate = HTTPUploadDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let urlString = "http://127.0.0.1:\(TestURLSession.serverPort)/upload"
        var request = URLRequest(url: URL(string: urlString)!)
        request.httpMethod = "PUT"
        
        delegate.uploadCompletedExpectation = expectation(description: "PUT \(urlString): Upload data")
        
        
        let fileData = Data(count: 16*1024)
        let stream = InputStream(data: fileData)
        stream.open()
        delegate.streamToProvideOnRequest = stream
        
        let task = session.uploadTask(withStreamedRequest: request)
        task.resume()
        waitForExpectations(timeout: 20)
    }
    
    static var allTests: [(String, (TestURLSession) -> () throws -> Void)] {
        return [
            ("test_dataTaskWithURL", test_dataTaskWithURL),
            ("test_dataTaskWithURLRequest", test_dataTaskWithURLRequest),
            ("test_dataTaskWithURLCompletionHandler", test_dataTaskWithURLCompletionHandler),
            ("test_dataTaskWithURLRequestCompletionHandler", test_dataTaskWithURLRequestCompletionHandler),
            // ("test_dataTaskWithHttpInputStream", test_dataTaskWithHttpInputStream), - Flaky test
            ("test_gzippedDataTask", test_gzippedDataTask),
            ("test_downloadTaskWithURL", test_downloadTaskWithURL),
            ("test_downloadTaskWithURLRequest", test_downloadTaskWithURLRequest),
            ("test_downloadTaskWithRequestAndHandler", test_downloadTaskWithRequestAndHandler),
            ("test_downloadTaskWithURLAndHandler", test_downloadTaskWithURLAndHandler),
            ("test_gzippedDownloadTask", test_gzippedDownloadTask),
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
            ("test_httpRedirectionWithDefaultPort", test_httpRedirectionWithDefaultPort),
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
            ("test_cookieStorageForEphemeralConfiguration", test_cookieStorageForEphemeralConfiguration),
            ("test_previouslySetCookiesAreSentInLaterRequests", test_previouslySetCookiesAreSentInLaterRequests),
            ("test_setCookieHeadersCanBeIgnored", test_setCookieHeadersCanBeIgnored),
            ("test_initURLSessionConfiguration", test_initURLSessionConfiguration),
            ("test_basicAuthRequest", test_basicAuthRequest),
            ("test_redirectionWithSetCookies", test_redirectionWithSetCookies),
            ("test_postWithEmptyBody", test_postWithEmptyBody),
            ("test_basicAuthWithUnauthorizedHeader", test_basicAuthWithUnauthorizedHeader),
            ("test_checkErrorTypeAfterInvalidateAndCancel", test_checkErrorTypeAfterInvalidateAndCancel),
            ("test_taskCountAfterInvalidateAndCancel", test_taskCountAfterInvalidateAndCancel),
            ("test_sessionDelegateAfterInvalidateAndCancel", test_sessionDelegateAfterInvalidateAndCancel),
            ("test_getAllTasks", test_getAllTasks),
            ("test_getTasksWithCompletion", test_getTasksWithCompletion),
            /* ⚠️ */ ("test_invalidResumeDataForDownloadTask",
            /* ⚠️ */   testExpectedToFail(test_invalidResumeDataForDownloadTask, "This test crashes nondeterministically: https://bugs.swift.org/browse/SR-11353")),
            /* ⚠️ */ ("test_simpleUploadWithDelegateProvidingInputStream",
            /* ⚠️ */   testExpectedToFail(test_simpleUploadWithDelegateProvidingInputStream, "This test times out frequently: https://bugs.swift.org/browse/SR-11343")),
            /* ⚠️ */ ("test_noDoubleCallbackWhenCancellingAndProtocolFailsFast",
            /* ⚠️ */      testExpectedToFail(test_noDoubleCallbackWhenCancellingAndProtocolFailsFast, "This test crashes nondeterministically: https://bugs.swift.org/browse/SR-11310")),
            ("test_cancelledTasksCannotBeResumed", test_cancelledTasksCannotBeResumed),
        ]
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
    let invalidateExpectation: XCTestExpectation?
    override init() {
        invalidateExpectation = nil
        super.init()
    }
    init(invalidateExpectation: XCTestExpectation) {
        self.invalidateExpectation = invalidateExpectation
    }
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        invalidateExpectation?.fulfill()
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

    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge:
        URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition,
        URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(user: "user", password: "passwd", persistence: .none))
    }
}

class DownloadTask : NSObject {
    var totalBytesWritten: Int64 = 0
    var didDownloadExpectation: XCTestExpectation?
    let didCompleteExpectation: XCTestExpectation
    var session: URLSession! = nil
    var task: URLSessionDownloadTask! = nil
    var errorExpectation: ((Error) -> Void)?
    weak var testCase: XCTestCase?
    var expectationsDescription: String
    
    init(testCase: XCTestCase, description: String) {
        self.expectationsDescription = description
        self.testCase = testCase
        self.didCompleteExpectation = testCase.expectation(description: "Did complete \(description)")
    }
    
    private func makeDownloadExpectation() {
        guard didDownloadExpectation == nil else { return }
        self.didDownloadExpectation = testCase!.expectation(description: "Did finish download: \(description)")
        self.testCase = nil // No need for it any more here.
    }
    
    func run(with url: URL) {
        makeDownloadExpectation()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.downloadTask(with: url)
        task.resume()
    }
    
    func run(with urlRequest: URLRequest) {
        makeDownloadExpectation()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        task = session.downloadTask(with: urlRequest)
        task.resume()
    }
    
    struct Configuration {
        var task: URLSessionDownloadTask
        var errorExpectation: ((Error) -> Void)?
    }
    
    func run(configuration: (URLSession) -> Configuration) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let taskConfiguration = configuration(session)
        
        task = taskConfiguration.task
        errorExpectation = taskConfiguration.errorExpectation
        if errorExpectation == nil {
            makeDownloadExpectation()
        }
        task.resume()
    }
}

extension DownloadTask : URLSessionDownloadDelegate {
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void {
        self.totalBytesWritten = totalBytesWritten
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        defer { didDownloadExpectation?.fulfill() }
        
        guard self.errorExpectation == nil else {
            XCTFail("Expected an error, but got …didFinishDownloadingTo… from download task \(downloadTask) (at \(location))")
            return
        }
        
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: location.path)
            XCTAssertEqual((attr[.size]! as? NSNumber)!.int64Value, totalBytesWritten, "Size of downloaded file not equal to total bytes downloaded")
        } catch {
            XCTFail("Unable to calculate size of the downloaded file")
        }
    }
}

extension DownloadTask : URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer { didCompleteExpectation.fulfill() }
        
        if let errorExpectation = self.errorExpectation {
            if let error = error {
                errorExpectation(error)
            } else {
                XCTFail("Expected an error, but got a completion without error from download task \(task)")
            }
        } else {
            guard let e = error as? URLError else { return }
            XCTAssertEqual(e.code, .timedOut, "Unexpected error code")
        }
    }
}

class FailFastProtocol: URLProtocol {
    enum Error: Swift.Error {
    case fastError
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.scheme == "failfast"
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let request = task.currentRequest else { return false }
        return canInit(with: request)
    }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: Error.fastError)
    }

    override func stopLoading() {
        // Intentionally blank
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
        if let url = response.url, url.path.hasSuffix("/redirect-with-default-port") {
            XCTAssertEqual(request.url?.absoluteString, "http://127.0.0.1/redirected-with-default-port")
            // Don't follow the redirect as the test server is not running on port 80
            return
        }
        completionHandler(request)
    }
}

class HTTPUploadDelegate: NSObject {
    var uploadCompletedExpectation: XCTestExpectation!
    var streamToProvideOnRequest: InputStream?
    var totalBytesSent: Int64 = 0
}

extension HTTPUploadDelegate: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.totalBytesSent = totalBytesSent
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        if streamToProvideOnRequest == nil {
            XCTFail("This shouldn't have been invoked -- no stream was set.")
        }
        
        completionHandler(self.streamToProvideOnRequest)
    }
}

extension HTTPUploadDelegate: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        XCTAssertEqual(self.totalBytesSent, 16*1024)
        uploadCompletedExpectation.fulfill()
    }
}

