// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
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

class TestNSData: XCTestCase {
    
    var allTests: [(String, () -> ())] {
        return [
            ("test_description", test_description),
            ("test_emptyDescription", test_emptyDescription),
            ("test_longDescription", test_longDescription),
            ("test_debugDescription", test_debugDescription),
            ("test_longDebugDescription", test_longDebugDescription),
            ("test_limitDebugDescription", test_limitDebugDescription),
            ("test_edgeDebugDescription", test_edgeDebugDescription),
            ("test_writeToURLOptions", test_writeToURLOptions),
            ("test_edgeNoCopyDescription", test_edgeNoCopyDescription),
        ]
    }
    
    func test_writeToURLOptions() {
        let saveData = NSData(contentsOfURL: NSBundle.mainBundle().URLForResource("Test", withExtension: "plist")!)
        let savePath = "/var/tmp/Test.plist"
        do {
            try saveData!.writeToFile(savePath, options: NSDataWritingOptions.DataWritingAtomic)
            let fileManager = NSFileManager.defaultManager()
            XCTAssertTrue(fileManager.fileExistsAtPath(savePath))
            try! fileManager.removeItemAtPath(savePath)
        } catch _ {
            XCTFail()
        }
    }

    func test_emptyDescription() {
        let expected = "<>"
        
        let bytes: [UInt8] = []
        let data = NSData(bytes: bytes, length: bytes.count)
        
        XCTAssertEqual(expected, data.description)
    }
    
    func test_description() {
        let expected =  "<ff4c3e00 55>"
        
        let bytes: [UInt8] = [0xff, 0x4c, 0x3e, 0x00, 0x55]
        let data = NSData(bytes: bytes, length: bytes.count)
        
        XCTAssertEqual(data.description, expected)
    }
    
    func test_longDescription() {
        // taken directly from Foundation
        let expected = "<ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8ff6e 4482d8ff 6e4482d8 ff6e4482 d8ff6e44 82d8>"
        
        let bytes: [UInt8] = [0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, 0xff, 0x6e, 0x44, 0x82, 0xd8, ]
        let data = NSData(bytes: bytes, length: bytes.count)
        
        XCTAssertEqual(expected, data.description)
    }
    
    func test_debugDescription() {
        let expected =  "<ff4c3e00 55>"
        
        let bytes: [UInt8] = [0xff, 0x4c, 0x3e, 0x00, 0x55]
        let data = NSData(bytes: bytes, length: bytes.count)
        
        XCTAssertEqual(data.debugDescription, expected)
    }
    
    func test_limitDebugDescription() {
        let expected = "<ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff>"
        let bytes = [UInt8](count: 1024, repeatedValue: 0xff)
        let data = NSData(bytes: bytes, length: bytes.count)
        XCTAssertEqual(data.debugDescription, expected)
    }
    
    func test_longDebugDescription() {
        let expected = "<ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ... ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff>"
        let bytes = [UInt8](count: 100_000, repeatedValue: 0xff)
        let data = NSData(bytes: bytes, length: bytes.count)
        XCTAssertEqual(data.debugDescription, expected)
    }

    func test_edgeDebugDescription() {
        let expected = "<ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ... ffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ff>"
        let bytes = [UInt8](count: 1025, repeatedValue: 0xff)
        let data = NSData(bytes: bytes, length: bytes.count)
        XCTAssertEqual(data.debugDescription, expected)
    }

    func test_edgeNoCopyDescription() {
        let expected = "<ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ... ffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ff>"
        let bytes = [UInt8](count: 1025, repeatedValue: 0xff)
        let data = NSData(bytesNoCopy: UnsafeMutablePointer<Int8>(bytes), length: bytes.count, freeWhenDone: false)
        XCTAssertEqual(data.debugDescription, expected)
        XCTAssertEqual(data.bytes, bytes)
    }
}
