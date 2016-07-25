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
    typealias NSStreamTestCases = (String, (TestNSStream) -> () throws -> Void)
    static var allTests: [NSStreamTestCases] {
        return [
            ("test_InputStreamWithData", test_InputStreamWithData),
            ("test_InputStreamWithUrl", test_InputStreamWithUrl),
            ("test_InputStreamWithFile", test_InputStreamWithFile),
            ("test_InputStreamHasBytesAvailable", test_InputStreamHasBytesAvailable),
            ("test_InputStreamInvalidPath", test_InputStreamInvalidPath),
            ("test_InputOutStreamError", test_InputOutStreamError),
            ("test_InputStreamGetBufferSuccessFromBlessedList", test_InputStreamGetBufferSuccessFromBlessedList),
            ("test_InputStreamGetBufferFailedExcludedFromBlessedList", test_InputStreamGetBufferFailedExcludedFromBlessedList),
            ("test_inputStreamGetSetProperty", test_inputStreamGetSetProperty),
            ("test_outputStreamCreationToFile", test_outputStreamCreationToFile),
            ("test_outputStreamCreationToBuffer", test_outputStreamCreationToBuffer),
            ("test_outputStreamCreationWithUrl", test_outputStreamCreationWithUrl),
            ("test_outputStreamCreationToMemory", test_outputStreamCreationToMemory),
            ("test_outputStreamHasSpaceAvailable", test_outputStreamHasSpaceAvailable),
            ("test_ouputStreamWithInvalidPath", test_ouputStreamWithInvalidPath),
            ("test_outputStreamGetSetProperty", test_outputStreamGetSetProperty),


        ]
    }
    
    func test_InputStreamWithData(){
        let message: NSString = "Hello, playground"
        let messageData: Data = message.data(using: String.Encoding.utf8.rawValue)!
        let dataStream: InputStream = InputStream(data: messageData)
        XCTAssertEqual(NSStream.Status.notOpen, dataStream.streamStatus)
        dataStream.open()
        XCTAssertEqual(NSStream.Status.open, dataStream.streamStatus)
        var buffer = [UInt8](repeating: 0, count: 20)
        if dataStream.hasBytesAvailable {
            let result: Int = dataStream.read(&buffer, maxLength: buffer.count)
            dataStream.close()
            XCTAssertEqual(NSStream.Status.closed, dataStream.streamStatus)
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
            XCTAssertEqual(NSStream.Status.notOpen, urlStream.streamStatus)
            urlStream.open()
            XCTAssertEqual(NSStream.Status.open, urlStream.streamStatus)
            var buffer = [UInt8](repeating: 0, count: 20)
            if urlStream.hasBytesAvailable {
                let result :Int = urlStream.read(&buffer, maxLength: buffer.count)
                urlStream.close()
                XCTAssertEqual(NSStream.Status.closed, urlStream.streamStatus)
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
            XCTAssertEqual(NSStream.Status.notOpen, fileStream.streamStatus)
            fileStream.open()
            XCTAssertEqual(NSStream.Status.open, fileStream.streamStatus)
            var buffer = [UInt8](repeating: 0, count: 20)
            if fileStream.hasBytesAvailable {
                let result: Int = fileStream.read(&buffer, maxLength: buffer.count)
                fileStream.close()
                XCTAssertEqual(NSStream.Status.closed, fileStream.streamStatus)
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
        XCTAssertEqual(NSStream.Status.notOpen, fileStream.streamStatus)
        fileStream.open()
        XCTAssertEqual(NSStream.Status.error, fileStream.streamStatus)
    }
    
    /* This test is the success case for Streams that are in the blessed list with the
     * dataGetBuffer as part of the call back e.g
     * static const struct _CFStreamCallBacksV1 readDataCallBacks = {1, readDataCreate,readDataFinalize, readDataCopyDescription, readDataOpen, NULL, dataRead, dataGetBuffer, dataCanRead, NULL, NULL, NULL, NULL, NULL, NULL, readDataSchedule, NULL};
     */
    func test_InputStreamGetBufferSuccessFromBlessedList(){
        let message: NSString = "Hello, playground"
        let messageData: Data = message.data(using: String.Encoding.utf8.rawValue)!
        let dataStream: InputStream = InputStream(data: messageData)
        XCTAssertEqual(NSStream.Status.notOpen, dataStream.streamStatus)
        dataStream.open()
        XCTAssertEqual(NSStream.Status.open, dataStream.streamStatus)
        let buffer = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>(allocatingCapacity: 1)
        let ptr = UnsafeMutablePointer<Int>(allocatingCapacity:1)
        let gotBuffer = dataStream.getBuffer(buffer, length:ptr)
        
        XCTAssertTrue(gotBuffer)
    }
    
    /* This test is the fail case for Streams that are not in the blessed list with the
     * dataGetBuffer as not part of the call back e.g
     * static const struct _CFStreamCallBacksV1 fileCallBacks = {1, fileCreate, fileFinalize, fileCopyDescription, fileOpen, NULL, fileRead, NULL, fileCanRead, fileWrite, fileCanWrite, fileClose, fileCopyProperty, fileSetProperty, NULL, fileSchedule, fileUnschedule};
     */
    func test_InputStreamGetBufferFailedExcludedFromBlessedList(){
        let message: NSString = "Hello, playground"
        let messageData: Data  = message.data(using: String.Encoding.utf8.rawValue)!
        let testFile = createTestFile("testFile_in.txt", _contents: messageData)
        if testFile != nil {
            let fileStream: InputStream = InputStream(fileAtPath: testFile!)!
            XCTAssertEqual(NSStream.Status.notOpen, fileStream.streamStatus)
            fileStream.open()
            XCTAssertEqual(NSStream.Status.open, fileStream.streamStatus)
            let buffer = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>(allocatingCapacity: 1)
            let ptr = UnsafeMutablePointer<Int>(allocatingCapacity:1)
            let gotBuffer = fileStream.getBuffer(buffer, length:ptr)
            XCTAssertFalse(gotBuffer)
            removeTestFile(testFile!)
        } else {
            XCTFail("Unable to create temp file")
        }
    }
    
    func test_InputOutStreamError(){
        let testFile = "/Path/to/nil"
        let fileStream: InputStream = InputStream(fileAtPath: testFile)!
        XCTAssertEqual(NSStream.Status.notOpen, fileStream.streamStatus)
        fileStream.open()
        
        //Example Call site::
        // let error = CFReadStreamCopyError(_stream)
        // let error2 = CFReadStreamGetError(_stream)
        //
        //Problem::looks like there is a bug with CFReadStreamCopyError
        //         it wont return a CFError even though 
        //         CFReadStreamGetError returns a CFStreamError
        //
        // I have tried to track the call down to this call here CFSocketStream.c #231
        // ``` result = CFNETWORK_CALL(_CFErrorCreateWithStreamError, (alloc, streamError)); ```
        // where both of the params alloc and streamError are valid objects 
        // 
        // This function is loaded from the CFNetwork.frameworks binary
        //    CFNetworkSupport._CFErrorCreateWithStreamError = CFNETWORK_LOAD_SYM(_CFErrorCreateWithStreamError);
        //__CFLookupCFNetworkFunction
        //path = "/System/Library/Frameworks/CFNetwork.framework/CFNetwork";
        
        // after this point it is black box to me
    
        //this should yeild a error as error2 from Example Call Site yeids a CFStreamError
        //
        //JIRA:: link to jira here
        //this crashes on 12 core mac
//        let error = fileStream.streamError
    
        
    }
    
    func test_inputStreamGetSetProperty(){
        
        let testFile = "/Path/to/nil"
        let fileStream: InputStream = InputStream(fileAtPath: testFile)!
        XCTAssertEqual(NSStream.Status.notOpen, fileStream.streamStatus)
        fileStream.open()
        
        //Set: failure case
        let value = NSString(string:"value")
        let inputStreamSetProperty_invalidKey = "inputStreamSetProperty_invalidKey"
        let didSetShouldFail = fileStream.setProperty(value, forKey: inputStreamSetProperty_invalidKey)
        XCTAssertFalse(didSetShouldFail)
        
        //Get: failure case
        let didGetShouldBeNil = fileStream.propertyForKey(inputStreamSetProperty_invalidKey)
        XCTAssertNil(didGetShouldBeNil)
        
        //Set: success case
        let inputStreamSetProperty_validKey = "kCFStreamPropertyFileCurrentOffset"
        let didSetShouldSucceed = fileStream.setProperty(1._bridgeToObject(), forKey:inputStreamSetProperty_validKey)
        XCTAssertTrue(didSetShouldSucceed)
        
        
        //Get: Success case
        let didGetShouldNotBeNil = fileStream.propertyForKey(inputStreamSetProperty_validKey)
        XCTAssertNotNil(didGetShouldNotBeNil)
        XCTAssertTrue(1._bridgeToObject() == didGetShouldNotBeNil as! NSNumber)
    }
    
    
    
    
    func test_outputStreamCreationToFile() {
        let filePath = createTestFile("TestFileOut.txt", _contents: Data(capacity: 256)!)
        if filePath != nil {
            let outputStream = NSOutputStream(toFileAtPath: filePath!, append: true)
            XCTAssertEqual(NSStream.Status.notOpen, outputStream!.streamStatus)
            var myString = "Hello world!"
            let encodedData = [UInt8](myString.utf8)
            outputStream?.open()
            XCTAssertEqual(NSStream.Status.open, outputStream!.streamStatus)
            let result: Int? = outputStream?.write(encodedData, maxLength: encodedData.count)
            outputStream?.close()
            XCTAssertEqual(myString.characters.count, result)
            XCTAssertEqual(NSStream.Status.closed, outputStream!.streamStatus)
            removeTestFile(filePath!)
        } else {
            XCTFail("Unable to create temp file");
        }
    }
    
    func  test_outputStreamCreationToBuffer() {
        var buffer = Array<UInt8>(repeating: 0, count: 12)
        var myString = "Hello world!"
        let encodedData = [UInt8](myString.utf8)
        let outputStream = NSOutputStream(toBuffer: UnsafeMutablePointer<UInt8>(buffer), capacity: 12)
        XCTAssertEqual(NSStream.Status.notOpen, outputStream.streamStatus)
        outputStream.open()
        XCTAssertEqual(NSStream.Status.open, outputStream.streamStatus)
        let result: Int? = outputStream.write(encodedData, maxLength: encodedData.count)
        outputStream.close()
        XCTAssertEqual(NSStream.Status.closed, outputStream.streamStatus)
        XCTAssertEqual(myString.characters.count, result)
        XCTAssertEqual(NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue),myString._bridgeToObject())
    }
    
    func test_outputStreamCreationWithUrl() {
        let filePath = createTestFile("TestFileOut.txt", _contents: Data(capacity: 256)!)
        if filePath != nil {
            let outputStream = NSOutputStream(url: URL(fileURLWithPath: filePath!), append: true)
            XCTAssertEqual(NSStream.Status.notOpen, outputStream!.streamStatus)
            var myString = "Hello world!"
            let encodedData = [UInt8](myString.utf8)
            outputStream!.open()
            XCTAssertEqual(NSStream.Status.open, outputStream!.streamStatus)
            let result: Int? = outputStream?.write(encodedData, maxLength: encodedData.count)
            outputStream?.close()
            XCTAssertEqual(myString.characters.count, result)
            XCTAssertEqual(NSStream.Status.closed, outputStream!.streamStatus)
            removeTestFile(filePath!)
        } else {
            XCTFail("Unable to create temp file");
        }
    }
    
    func test_outputStreamCreationToMemory(){
        var buffer = Array<UInt8>(repeating: 0, count: 12)
        var myString = "Hello world!"
        let encodedData = [UInt8](myString.utf8)
        let outputStream = NSOutputStream.outputStreamToMemory()
        XCTAssertEqual(NSStream.Status.notOpen, outputStream.streamStatus)
        outputStream.open()
        XCTAssertEqual(NSStream.Status.open, outputStream.streamStatus)
        let result: Int? = outputStream.write(encodedData, maxLength: encodedData.count)
        XCTAssertEqual(myString.characters.count, result)
        //verify the data written
        let dataWritten  = outputStream.propertyForKey(NSStreamDataWrittenToMemoryStreamKey)
        if let nsdataWritten = dataWritten as? NSData {
            nsdataWritten.getBytes(UnsafeMutablePointer<UInt8>(buffer), length: result!)
            XCTAssertEqual(NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue), myString._bridgeToObject())
            outputStream.close()
        } else {
            XCTFail("Unable to get data from memeory.")
        }
    }

    func test_outputStreamHasSpaceAvailable() {
        let buffer = Array<UInt8>(repeating: 0, count: 12)
        var myString = "Welcome To Hello world  !"
        let encodedData = [UInt8](myString.utf8)
        let outputStream = NSOutputStream(toBuffer: UnsafeMutablePointer<UInt8>(buffer), capacity: 12)
        outputStream.open()
        XCTAssertTrue(outputStream.hasSpaceAvailable)
        _ = outputStream.write(encodedData, maxLength: encodedData.count)
        XCTAssertFalse(outputStream.hasSpaceAvailable)
    }
    
    func test_ouputStreamWithInvalidPath(){
        let outputStream = NSOutputStream(toFileAtPath: "http:///home/sdsfsdfd", append: true)
        XCTAssertEqual(NSStream.Status.notOpen, outputStream!.streamStatus)
        outputStream?.open()
        XCTAssertEqual(NSStream.Status.error, outputStream!.streamStatus)
    }
    
    func test_outputStreamGetSetProperty(){
        let filePath = createTestFile("TestFileOut.txt", _contents: Data(capacity: 256)!)
        let outputStream = NSOutputStream(url: URL(fileURLWithPath: filePath!), append: false)
        XCTAssertEqual(NSStream.Status.notOpen, outputStream?.streamStatus)

        //Set: failure case
        let value = NSString(string:"value")
        let inputStreamSetProperty_invalidKey = "inputStreamSetProperty_invalidKey"
        let didSetShouldFail = outputStream?.setProperty(value, forKey: inputStreamSetProperty_invalidKey)
        XCTAssertFalse(didSetShouldFail!)
        
        //Get: failure case
        let didGetShouldBeNil = outputStream?.propertyForKey(inputStreamSetProperty_invalidKey)
        XCTAssertNil(didGetShouldBeNil)
        
        //Set: success case
        let inputStreamSetProperty_validKey = "kCFStreamPropertyFileCurrentOffset"
        let didSetShouldSucceed = outputStream?.setProperty(1._bridgeToObject(), forKey:inputStreamSetProperty_validKey)
        XCTAssertTrue(didSetShouldSucceed!)
        
        
        //Get: Success case
        let didGetShouldNotBeNil = outputStream?.propertyForKey(inputStreamSetProperty_validKey)
        XCTAssertNotNil(didGetShouldNotBeNil)
        XCTAssertTrue(1._bridgeToObject() == didGetShouldNotBeNil as! NSNumber)
    }
    
    
    
    private func createTestFile(_ path: String, _contents: Data) -> String? {
        let tempDir = "/tmp/TestFoundation_Playground_" + NSUUID().UUIDString + "/"
        do {
            try FileManager.default().createDirectory(atPath: tempDir, withIntermediateDirectories: false, attributes: nil)
            if FileManager.default().createFile(atPath: tempDir + "/" + path, contents: _contents,
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
            try FileManager.default().removeItem(atPath: location)
        } catch _ {
            
        }
    }
}

