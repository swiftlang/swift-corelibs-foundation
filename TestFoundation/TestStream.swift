// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestStream : XCTestCase {
    static var allTests: [(String, (TestStream) -> () throws -> Void)] {
        return [
            ("test_InputStreamWithData", test_InputStreamWithData),
            ("test_InputStreamWithUrl", test_InputStreamWithUrl),
            ("test_InputStreamWithFile", test_InputStreamWithFile),
            ("test_InputStreamHasBytesAvailable", test_InputStreamHasBytesAvailable),
            ("test_InputStreamInvalidPath", test_InputStreamInvalidPath),
            ("test_outputStreamCreationToFile", test_outputStreamCreationToFile),
            ("test_outputStreamCreationToBuffer", test_outputStreamCreationToBuffer),
            ("test_outputStreamCreationWithUrl", test_outputStreamCreationWithUrl),
            ("test_outputStreamCreationToMemory", test_outputStreamCreationToMemory),
            ("test_outputStreamHasSpaceAvailable", test_outputStreamHasSpaceAvailable),
            ("test_ouputStreamWithInvalidPath", test_ouputStreamWithInvalidPath),
        ]
    }
    
    func test_InputStreamWithData(){
        let message: NSString = "Hello, playground"
        let messageData: Data = message.data(using: String.Encoding.utf8.rawValue)!
        let dataStream: InputStream = InputStream(data: messageData)
        XCTAssertEqual(.notOpen, dataStream.streamStatus)
        dataStream.open()
        XCTAssertEqual(.open, dataStream.streamStatus)
        var buffer = [UInt8](repeating: 0, count: 20)
        if dataStream.hasBytesAvailable {
            let result: Int = dataStream.read(&buffer, maxLength: buffer.count)
            dataStream.close()
            XCTAssertEqual(.closed, dataStream.streamStatus)
            if(result > 0){
                let output = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
                XCTAssertEqual(message, output!)
            }
        }
    }
    
    func test_InputStreamWithUrl() {
        let message: NSString = "Hello, playground"
        let messageData: Data  = message.data(using: String.Encoding.utf8.rawValue)!
        guard let testFile = createTestFile("testFile_in.txt", _contents: messageData) else {
            XCTFail("Unable to create temp file")
            return
        }

        //Initialiser with url
        let url = URL(fileURLWithPath: testFile)
        let urlStream: InputStream = InputStream(url: url)!
        XCTAssertEqual(.notOpen, urlStream.streamStatus)
        urlStream.open()
        XCTAssertEqual(.open, urlStream.streamStatus)
        var buffer = [UInt8](repeating: 0, count: 20)
        if urlStream.hasBytesAvailable {
            let result :Int = urlStream.read(&buffer, maxLength: buffer.count)
            urlStream.close()
            XCTAssertEqual(.closed, urlStream.streamStatus)
            XCTAssertEqual(messageData.count, result)
            if(result > 0) {
                let output = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
                XCTAssertEqual(message, output!)
            }
        }
        removeTestFile(testFile)
    }
    
    func test_InputStreamWithFile() {
        let message: NSString = "Hello, playground"
        let messageData: Data  = message.data(using: String.Encoding.utf8.rawValue)!
        guard let testFile = createTestFile("testFile_in.txt", _contents: messageData) else {
            XCTFail("Unable to create temp file")
            return
        }

        //Initialiser with file
        let fileStream: InputStream = InputStream(fileAtPath: testFile)!
        XCTAssertEqual(.notOpen, fileStream.streamStatus)
        fileStream.open()
        XCTAssertEqual(.open, fileStream.streamStatus)
        var buffer = [UInt8](repeating: 0, count: 20)
        if fileStream.hasBytesAvailable {
            let result: Int = fileStream.read(&buffer, maxLength: buffer.count)
            fileStream.close()
            XCTAssertEqual(.closed, fileStream.streamStatus)
            XCTAssertEqual(messageData.count, result)
            if(result > 0){
                let output = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)
                XCTAssertEqual(message, output!)
            }
        }
        removeTestFile(testFile)
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
        let fileStream: InputStream = InputStream(fileAtPath: NSTemporaryDirectory() + "file.txt")!
        XCTAssertEqual(.notOpen, fileStream.streamStatus)
        fileStream.open()
        XCTAssertEqual(.error, fileStream.streamStatus)
    }
    
    func test_outputStreamCreationToFile() {
        guard let filePath = createTestFile("TestFileOut.txt", _contents: Data(capacity: 256)) else {
            XCTFail("Unable to create temp file");
            return
        }

        let outputStream = OutputStream(toFileAtPath: filePath, append: true)
        XCTAssertEqual(.notOpen, outputStream!.streamStatus)
        var myString = "Hello world!"
        let encodedData = [UInt8](myString.utf8)
        outputStream?.open()
        XCTAssertEqual(.open, outputStream!.streamStatus)
        let result: Int? = outputStream?.write(encodedData, maxLength: encodedData.count)
        outputStream?.close()
        XCTAssertEqual(myString.count, result)
        XCTAssertEqual(.closed, outputStream!.streamStatus)
        removeTestFile(filePath)
    }
    
    func  test_outputStreamCreationToBuffer() {
        var buffer = Array<UInt8>(repeating: 0, count: 12)
        var myString = "Hello world!"
        let encodedData = [UInt8](myString.utf8)
        let outputStream = OutputStream(toBuffer: UnsafeMutablePointer(mutating: buffer), capacity: 12)
        XCTAssertEqual(.notOpen, outputStream.streamStatus)
        outputStream.open()
        XCTAssertEqual(.open, outputStream.streamStatus)
        let result: Int? = outputStream.write(encodedData, maxLength: encodedData.count)
        outputStream.close()
        XCTAssertEqual(.closed, outputStream.streamStatus)
        XCTAssertEqual(myString.count, result)
        XCTAssertEqual(NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue), NSString(string: myString))
    }
    
    func test_outputStreamCreationWithUrl() {
        guard let filePath = createTestFile("TestFileOut.txt", _contents: Data(capacity: 256)) else {
            XCTFail("Unable to create temp file");
            return
        }

        let outputStream = OutputStream(url: URL(fileURLWithPath: filePath), append: true)
        XCTAssertEqual(.notOpen, outputStream!.streamStatus)
        var myString = "Hello world!"
        let encodedData = [UInt8](myString.utf8)
        outputStream!.open()
        XCTAssertEqual(.open, outputStream!.streamStatus)
        let result: Int? = outputStream?.write(encodedData, maxLength: encodedData.count)
        outputStream?.close()
        XCTAssertEqual(myString.count, result)
        XCTAssertEqual(.closed, outputStream!.streamStatus)
        removeTestFile(filePath)
    }
    
    func test_outputStreamCreationToMemory(){
        var buffer = Array<UInt8>(repeating: 0, count: 12)
        var myString = "Hello world!"
        let encodedData = [UInt8](myString.utf8)
        let outputStream = OutputStream.toMemory()
        XCTAssertEqual(.notOpen, outputStream.streamStatus)
        outputStream.open()
        XCTAssertEqual(.open, outputStream.streamStatus)
        let result: Int? = outputStream.write(encodedData, maxLength: encodedData.count)
        XCTAssertEqual(myString.count, result)
        //verify the data written
        let dataWritten  = outputStream.property(forKey: Stream.PropertyKey.dataWrittenToMemoryStreamKey)
        if let nsdataWritten = dataWritten as? NSData {
            nsdataWritten.getBytes(UnsafeMutablePointer(mutating: buffer), length: result!)
            XCTAssertEqual(NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue), NSString(string: myString))
            outputStream.close()
        } else {
            XCTFail("Unable to get data from memeory.")
        }
    }

    func test_outputStreamHasSpaceAvailable() {
        let buffer = Array<UInt8>(repeating: 0, count: 12)
        var myString = "Welcome To Hello world  !"
        let encodedData = [UInt8](myString.utf8)
        let outputStream = OutputStream(toBuffer: UnsafeMutablePointer(mutating: buffer), capacity: 12)
        outputStream.open()
        XCTAssertTrue(outputStream.hasSpaceAvailable)
        _ = outputStream.write(encodedData, maxLength: encodedData.count)
        XCTAssertFalse(outputStream.hasSpaceAvailable)
    }
    
    func test_ouputStreamWithInvalidPath(){
        let outputStream = OutputStream(toFileAtPath: "http:///home/sdsfsdfd", append: true)
        XCTAssertEqual(.notOpen, outputStream!.streamStatus)
        outputStream?.open()
        XCTAssertEqual(.error, outputStream!.streamStatus)
    }
    
    private func createTestFile(_ path: String, _contents: Data) -> String? {
        let tempDir = NSTemporaryDirectory() + "TestFoundation_Playground_" + NSUUID().uuidString + "/"
        do {
            try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: false, attributes: nil)
            if FileManager.default.createFile(atPath: tempDir + "/" + path, contents: _contents,
                                                attributes: nil) {
                return tempDir + path
            } else {
                return nil
            }
        } catch _ {
            return nil
        }
    }
    
    private func removeTestFile(_ location: String) {
        do {
            try FileManager.default.removeItem(atPath: location)
        } catch _ {
            
        }
    }
}

