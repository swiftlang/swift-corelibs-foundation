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

    static var allTests: [(String, (TestURLSession) -> () throws -> Void)] {
        return [
            ("test_dataTaskWithURL", test_dataTaskWithURL),
            ("test_dataTaskWithURLRequest", test_dataTaskWithURLRequest),
            ("test_dataTaskWithURLCompletionHandler", test_dataTaskWithURLCompletionHandler),
            ("test_dataTaskWithURLRequestCompletionHandler", test_dataTaskWithURLRequestCompletionHandler),
//            ("test_downloadTaskWithURL", test_downloadTaskWithURL),
//            ("test_downloadTaskWithURLRequest", test_downloadTaskWithURLRequest),
//            ("test_downloadTaskWithRequestAndHandler", test_downloadTaskWithRequestAndHandler),
//            ("test_downloadTaskWithURLAndHandler", test_downloadTaskWithURLAndHandler),
            
        ]
    }

    func test_dataTaskWithURL() {
        let urlString = "https://restcountries.eu/rest/v1/name/Nepal?fullText=true"
        let url = URL(string: urlString)!
        let d = DataTask(with: expectation(description: "data task"))                         
        d.run(with: url)
        waitForExpectations(timeout: 12)
        if !d.error {
            XCTAssertEqual(d.capital, "Kathmandu", "test_dataTaskWithURLRequest returned an unexpected result")
        }
    }
    
    func test_dataTaskWithURLCompletionHandler() {
        let urlString = "https://restcountries.eu/rest/v1/name/USA?fullText=true"
        let url = URL(string: urlString)!
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "URL test with completion handler")
        var expectedResult = "unknown"
        let task = session.dataTask(with: url) { data, response, error in
            if let e = error {
                XCTAssertEqual(e.code, NSURLErrorTimedOut, "Unexpected error code")
                expect.fulfill()
                return
            }

            let httpResponse = response as! HTTPURLResponse?
            XCTAssertEqual(200, httpResponse!.statusCode, "HTTP response code is not 200") 
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                let arr = json as? Array<Any>
                let first = arr![0]
                let result = first as? [String : Any]
                expectedResult = result!["capital"] as! String
            } catch { }
            XCTAssertEqual("Washington, D.C.", expectedResult, "Did not receive expected value")
            expect.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }

    func test_dataTaskWithURLRequest() {
        let urlString = "https://restcountries.eu/rest/v1/name/Peru?fullText=true"
        let urlRequest = URLRequest(url: URL(string: urlString)!)
        let d = DataTask(with: expectation(description: "data task"))     
        d.run(with: urlRequest)
        waitForExpectations(timeout: 12)
        if !d.error {
            XCTAssertEqual(d.capital, "Lima", "test_dataTaskWithURLRequest returned an unexpected result")
        }
    }

    func test_dataTaskWithURLRequestCompletionHandler() {
        let urlString = "https://restcountries.eu/rest/v1/name/Italy?fullText=true"
        let urlRequest = URLRequest(url: URL(string: urlString)!)
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        let expect = expectation(description: "URL test with completion handler")
        var expectedResult = "unknown"
        let task = session.dataTask(with: urlRequest) { data, response, error in
            if let e = error {
                XCTAssertEqual(e.code, NSURLErrorTimedOut, "Unexpected error code")
                expect.fulfill()
                return
            }
            let httpResponse = response as! HTTPURLResponse?
            XCTAssertEqual(200, httpResponse!.statusCode, "HTTP response code is not 200")
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                let arr = json as? Array<Any>
                let first = arr![0]
                let result = first as? [String : Any]
                expectedResult = result!["capital"] as! String
            } catch { }
            XCTAssertEqual("Rome", expectedResult, "Did not receive expected value")
            expect.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }

    func test_downloadTaskWithURL() {
        let urlString = "https://swift.org/LICENSE.txt"
        let url = URL(string: urlString)!   
        let d = DownloadTask(with: expectation(description: "download task with delegate"))
        d.run(with: url)
        waitForExpectations(timeout: 12)
    }

    func test_downloadTaskWithURLRequest() {
       let urlString = "https://swift.org/LICENSE.txt"
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
        let req = URLRequest(url: URL(string: "https://swift.org/LICENSE.txt")!)
        let task = session.downloadTask(with: req) { (_, _, error) -> Void in
            if let e = error {
                XCTAssertEqual(e.code, NSURLErrorTimedOut, "Unexpected error code")
            }
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
        let req = URLRequest(url: URL(string: "https://swift.org/LICENSE.txt")!)
        let task = session.downloadTask(with: req) { (_, _, error) -> Void in
            if let e = error {
                XCTAssertEqual(e.code, NSURLErrorTimedOut, "Unexpected error code")
            }
            expect.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 12)
    }
}

class DataTask: NSObject {
    let dataTaskExpectation: XCTestExpectation!
    var capital = "unknown"
    var session: URLSession! = nil
    var task: URLSessionDataTask! = nil
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
}

extension DataTask : URLSessionDataDelegate {
     public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
         do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let arr = json as? Array<Any>
            let first = arr![0]
            let result = first as? [String : Any]
            capital = result!["capital"] as! String
         } catch { }

         dataTaskExpectation.fulfill()
     }
}

extension DataTask : URLSessionTaskDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
         guard let e = error else { return }
         XCTAssertEqual(e.code, NSURLErrorTimedOut, "Unexpected error code")
         dataTaskExpectation.fulfill()
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
   public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
       guard let e = error else { return }
       XCTAssertEqual(e.code, NSURLErrorTimedOut, "Unexpected error code")
       dwdExpectation.fulfill()
   }
}
