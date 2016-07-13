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

class TestNSStream : XCTestCase {
    static var allTests: [(String, (TestNSStream) -> () throws -> Void)] {
        return [
            ("test_InputStreamWithData", test_InputStreamWithData),
            ("test_InputStreamWithUrl", test_InputStreamWithUrl),
            ("test_InputStreamWithFile", test_InputStreamWithFile),
            ("test_InputStreamHasBytesAvailable", test_InputStreamHasBytesAvailable),
            ("test_InputStreamInvalidPath", test_InputStreamInvalidPath),
        ]
    }
    
    func test_InputStreamWithData(){
        let message: NSString = "Hello, playground"
        let messageData: Data = message.data(using: String.Encoding.utf8.rawValue)!
        let dataStream: InputStream = InputStream(data: messageData)
        XCTAssertEqual(Stream.Status.notOpen, dataStream.streamStatus)
        dataStream.open()
        XCTAssertEqual(Stream.Status.open, dataStream.streamStatus)
        var buffer = [UInt8](repeating: 0, count: 20)
        if dataStream.hasBytesAvailable {
            let result: Int = dataStream.read(&buffer, maxLength: buffer.count)
            dataStream.close()
            XCTAssertEqual(Stream.Status.closed, dataStream.streamStatus)
            if(result > 0){
                let output = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
                XCTAssertEqual(message, output!)
            }
        }
    }
    
    func test_InputStreamWithUrl() {
        let message: NSString = "Hello, playground"
        let messageData: Data  = message.data(using: String.Encoding.utf8.rawValue)!
        //Initialiser with url
        let testFile = createTestFile("testFile_in.txt", _contents: messageData)
        if testFile != nil {
            let url = URL(fileURLWithPath: testFile!)
            let urlStream: InputStream = InputStream(url: url)!
            XCTAssertEqual(Stream.Status.notOpen, urlStream.streamStatus)
            urlStream.open()
            XCTAssertEqual(Stream.Status.open, urlStream.streamStatus)
            var buffer = [UInt8](repeating: 0, count: 20)
            if urlStream.hasBytesAvailable {
                let result :Int = urlStream.read(&buffer, maxLength: buffer.count)
                urlStream.close()
                XCTAssertEqual(Stream.Status.closed, urlStream.streamStatus)
                XCTAssertEqual(messageData.count, result)
                if(result > 0) {
                    let output = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
                    XCTAssertEqual(message, output!)
                }
            }
            removeTestFile(testFile!)
        } else {
            XCTFail("Unable to create temp file")
        }
    }
    
    func test_InputStreamWithFile() {
        let message: NSString = "Hello, playground"
        let messageData: Data  = message.data(using: String.Encoding.utf8.rawValue)!
        //Initialiser with file
        let testFile = createTestFile("testFile_in.txt", _contents: messageData)
        if testFile != nil {
            let fileStream: InputStream = InputStream(fileAtPath: testFile!)!
            XCTAssertEqual(Stream.Status.notOpen, fileStream.streamStatus)
            fileStream.open()
            XCTAssertEqual(Stream.Status.open, fileStream.streamStatus)
            var buffer = [UInt8](repeating: 0, count: 20)
            if fileStream.hasBytesAvailable {
                let result: Int = fileStream.read(&buffer, maxLength: buffer.count)
                fileStream.close()
                XCTAssertEqual(Stream.Status.closed, fileStream.streamStatus)
                XCTAssertEqual(messageData.count, result)
                if(result > 0){
                    let output = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
                    XCTAssertEqual(message, output!)
                }
            }
            removeTestFile(testFile!)
        } else {
            XCTFail("Unable to create temp file")
        }
    }
    
    func test_InputStreamHasBytesAvailable() {
        let message: NSString = "Hello, playground"
        let messageData: Data  = message.data(using: String.Encoding.utf8.rawValue)!
        let stream: InputStream = InputStream(data: messageData)
        var buffer = [UInt8](repeating: 0, count: 20)
        stream.open()
        XCTAssertTrue(stream.hasBytesAvailable)
        _ = stream.read(&buffer, maxLength: buffer.count)
        XCTAssertFalse(stream.hasBytesAvailable)
    }
    
    func test_InputStreamInvalidPath() {
        let fileStream: InputStream = InputStream(fileAtPath: "/tmp/file.txt")!
        XCTAssertEqual(Stream.Status.notOpen, fileStream.streamStatus)
        fileStream.open()
        XCTAssertEqual(Stream.Status.error, fileStream.streamStatus)
    }
    
    private func createTestFile(_ path: String,_contents: Data) -> String? {
        let tempDir = "/tmp/TestFoundation_Playground_" + NSUUID().UUIDString + "/"
        do {
            try FileManager.default().createDirectory(atPath: tempDir, withIntermediateDirectories: false, attributes: nil)
            if FileManager.default().createFile(atPath: tempDir + "/" + path, contents: _contents, attributes: nil) {
                return  tempDir + path
            } else {
                return nil
            }
        } catch _ {
            return nil
        }
        
    }
    
    private func removeTestFile(_ location: String) {
        do {
            try FileManager.default().removeItem(atPath: location)
        } catch _ {
            
        }
    }
}


