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

class TestFTP : LoopbackFTPServerTest {
    
    static var allTests: [(String, (TestFTP) -> () throws -> Void)] {
        return [
           
            ("test_ftpdatatask", test_ftpdatatask),
            ("test_ftpdownloadtask", test_ftpdownloadtask),
            ("test_ftpdatataskDelegate", test_ftpdatataskDelegate),
            ("test_ftpdownloadtaskDelegate", test_ftpdownloadtaskDelegate),
            ("test_ftpuploadtask", test_ftpuploadtask), 
            //("test_simpleFTPUploadWithDelegate", test_simpleFTPUploadWithDelegate),
        ]
    }
    
     let saveData =  "FTP Implementation to test FTP Upload,download and data tasks.Instead of sending file, we are sending the hardcoded data.We are going to test FTP data,Download aand upload tasks with delegates & completion handlers.Creating the data here as we need to pass the count as part of the header.\r\n ".data(using: String.Encoding.utf8)
   
    func test_ftpdatatask() {
        let ftpURL = "ftp://127.0.0.1:\(TestFTP.serverPort)/test.txt"
        let  req = URLRequest(url: URL(string: ftpURL)!)
        let configuration = URLSessionConfiguration.default
        let expect = expectation(description: "URL test with custom protocol")
        let sesh = URLSession(configuration: configuration)
        let dataTask1 = sesh.dataTask(with: req, completionHandler: { data, res, error in
            XCTAssertNil(error)
            defer { expect.fulfill() }
            
        })
        dataTask1.resume()
        waitForExpectations(timeout: 60)
    }
    func test_ftpdownloadtask() {
        let ftpURL = "ftp://127.0.0.1:\(TestFTP.serverPort)/test.txt"
        let  req = URLRequest(url: URL(string: ftpURL)!)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10 //check this behavior on Darwin
        let expect = expectation(description: "URL test with custom protocol")
        let sesh = URLSession(configuration: configuration)
        let dataTask1 = sesh.downloadTask(with: req, completionHandler: { url, res, error in
            XCTAssertNil(error)
            defer { expect.fulfill() }
            
        })
        dataTask1.resume()
        waitForExpectations(timeout: 60)
    }

    func test_ftpdatataskDelegate() {
        let urlString = "ftp://127.0.0.1:\(TestFTP.serverPort)/test.txt"
        let url = URL(string: urlString)!
        let d = FTPDataTask(with: expectation(description: "data task"))
        d.run(with: url)
        waitForExpectations(timeout: 60)
        if !d.error {
            XCTAssertNotNil(d.fileData)
        }
    }

    func test_ftpdownloadtaskDelegate() {
        let urlString = "ftp://127.0.0.1:\(TestFTP.serverPort)/test.txt"
        let url = URL(string: urlString)!
        let d = DownloadTask(with: expectation(description: "data task"))
        d.run(with: url)
        waitForExpectations(timeout: 60)
    }

   func test_ftpuploadtask() {
        let ftpURL = "ftp://127.0.0.1:\(TestFTP.serverPort)/test.txt"
        let req = URLRequest(url: URL(string: ftpURL)!)
        let configuration = URLSessionConfiguration.default
        let expect = expectation(description: "URL test with custom protocol")
        let sesh = URLSession(configuration: configuration)
        let uploadTask = sesh.uploadTask(with: req, from: saveData, completionHandler: { data, res, error in
            XCTAssertNil(error)
            defer { expect.fulfill() }
            
        })
        uploadTask.resume()
        waitForExpectations(timeout: 60)
    }

    func test_simpleFTPUploadWithDelegate() {
        let delegate = FTPUploadDelegate()
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        let ftpURL = "ftp://127.0.0.1:\(TestFTP.serverPort)/test.txt"
         let req = URLRequest(url: URL(string: ftpURL)!)
         delegate.uploadCompletedExpectation = expectation(description: "PUT \(ftpURL): Upload data")
        let task = session.uploadTask(with: req, from: saveData!)
         task.resume()
         waitForExpectations(timeout: 20)
    }
}


