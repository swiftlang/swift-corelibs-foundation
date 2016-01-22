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
    
    var allTests: [(String, () throws -> Void)] {
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
            ("test_initializeWithBase64EncodedDataGetsDecodedData", test_initializeWithBase64EncodedDataGetsDecodedData),
            ("test_initializeWithBase64EncodedDataWithNonBase64CharacterIsNil", test_initializeWithBase64EncodedDataWithNonBase64CharacterIsNil),
            ("test_initializeWithBase64EncodedDataWithNonBase64CharacterWithOptionToAllowItSkipsCharacter", test_initializeWithBase64EncodedDataWithNonBase64CharacterWithOptionToAllowItSkipsCharacter),
            ("test_base64EncodedDataGetsEncodedText", test_base64EncodedDataGetsEncodedText),
            ("test_base64EncodedDataWithOptionToInsertCarriageReturnContainsCarriageReturn", test_base64EncodedDataWithOptionToInsertCarriageReturnContainsCarriageReturn),
            ("test_base64EncodedDataWithOptionToInsertLineFeedsContainsLineFeed", test_base64EncodedDataWithOptionToInsertLineFeedsContainsLineFeed),
            ("test_base64EncodedDataWithOptionToInsertCarriageReturnAndLineFeedContainsBoth", test_base64EncodedDataWithOptionToInsertCarriageReturnAndLineFeedContainsBoth),
            ("test_base64EncodedStringGetsEncodedText", test_base64EncodedStringGetsEncodedText),
            ("test_initializeWithBase64EncodedStringGetsDecodedData", test_initializeWithBase64EncodedStringGetsDecodedData),
            ("test_base64DecodeWithPadding1", test_base64DecodeWithPadding1),
            ("test_base64DecodeWithPadding2", test_base64DecodeWithPadding2),
            ("test_rangeOfData",test_rangeOfData)
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

    func test_initializeWithBase64EncodedDataGetsDecodedData() {
        let plainText = "ARMA virumque cano, Troiae qui primus ab oris\nItaliam, fato profugus, Laviniaque venit"
        let encodedText = "QVJNQSB2aXJ1bXF1ZSBjYW5vLCBUcm9pYWUgcXVpIHByaW11cyBhYiBvcmlzCkl0YWxpYW0sIGZhdG8gcHJvZnVndXMsIExhdmluaWFxdWUgdmVuaXQ="
        guard let encodedData = encodedText.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
            XCTFail("Could not get UTF-8 data")
            return
        }
        guard let decodedData = NSData(base64EncodedData: encodedData, options: []) else {
            XCTFail("Could not Base-64 decode data")
            return
        }
        guard let decodedText = NSString(data: decodedData, encoding: NSUTF8StringEncoding)?.bridge() else {
            XCTFail("Could not convert decoded data to a UTF-8 String")
            return
        }

        XCTAssertEqual(decodedText, plainText)
        XCTAssertTrue(decodedData.isEqualToData(plainText.bridge().dataUsingEncoding(NSUTF8StringEncoding)!))    }
    
    func test_initializeWithBase64EncodedDataWithNonBase64CharacterIsNil() {
        let encodedText = "QVJNQSB2aXJ1bXF1ZSBjYW5vLCBUcm9pYWUgcXVpIHBya$W11cyBhYiBvcmlzCkl0YWxpYW0sIGZhdG8gcHJvZnVndXMsIExhdmluaWFxdWUgdmVuaXQ="
        guard let encodedData = encodedText.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
            XCTFail("Could not get UTF-8 data")
            return
        }
        let decodedData = NSData(base64EncodedData: encodedData, options: [])
        XCTAssertNil(decodedData)
    }
    
    func test_initializeWithBase64EncodedDataWithNonBase64CharacterWithOptionToAllowItSkipsCharacter() {
        let plainText = "ARMA virumque cano, Troiae qui primus ab oris\nItaliam, fato profugus, Laviniaque venit"
        let encodedText = "QVJNQSB2aXJ1bXF1ZSBjYW5vLCBUcm9pYWUgcXVpIHBya$W11cyBhYiBvcmlzCkl0YWxpYW0sIGZhdG8gcHJvZnVndXMsIExhdmluaWFxdWUgdmVuaXQ="
        guard let encodedData = encodedText.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
            XCTFail("Could not get UTF-8 data")
            return
        }
        guard let decodedData = NSData(base64EncodedData: encodedData, options: [.IgnoreUnknownCharacters]) else {
            XCTFail("Could not Base-64 decode data")
            return
        }
        guard let decodedText = NSString(data: decodedData, encoding: NSUTF8StringEncoding)?.bridge() else {
            XCTFail("Could not convert decoded data to a UTF-8 String")
            return
        }
        
        XCTAssertEqual(decodedText, plainText)
        XCTAssertTrue(decodedData.isEqualToData(plainText.bridge().dataUsingEncoding(NSUTF8StringEncoding)!))
    }
    
    func test_initializeWithBase64EncodedStringGetsDecodedData() {
        let plainText = "ARMA virumque cano, Troiae qui primus ab oris\nItaliam, fato profugus, Laviniaque venit"
        let encodedText = "QVJNQSB2aXJ1bXF1ZSBjYW5vLCBUcm9pYWUgcXVpIHByaW11cyBhYiBvcmlzCkl0YWxpYW0sIGZhdG8gcHJvZnVndXMsIExhdmluaWFxdWUgdmVuaXQ="
        guard let decodedData = NSData(base64EncodedString: encodedText, options: []) else {
            XCTFail("Could not Base-64 decode data")
            return
        }
        guard let decodedText = NSString(data: decodedData, encoding: NSUTF8StringEncoding)?.bridge() else {
            XCTFail("Could not convert decoded data to a UTF-8 String")
            return
        }
        
        XCTAssertEqual(decodedText, plainText)
    }
    
    func test_base64EncodedDataGetsEncodedText() {
        let plainText = "Constitit, et lacrimans, `Quis iam locus’ inquit `Achate,\nquae regio in terris nostri non plena laboris?`"
        let encodedText = "Q29uc3RpdGl0LCBldCBsYWNyaW1hbnMsIGBRdWlzIGlhbSBsb2N1c+KAmSBpbnF1aXQgYEFjaGF0ZSwKcXVhZSByZWdpbyBpbiB0ZXJyaXMgbm9zdHJpIG5vbiBwbGVuYSBsYWJvcmlzP2A="
        guard let data = plainText.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
            XCTFail("Could not encode UTF-8 string")
            return
        }
        let encodedData = data.base64EncodedDataWithOptions([])
        guard let encodedTextResult = NSString(data: encodedData, encoding: NSASCIIStringEncoding)?.bridge() else {
            XCTFail("Could not convert encoded data to an ASCII String")
            return
        }
        XCTAssertEqual(encodedTextResult, encodedText)
    }
    
    func test_base64EncodedDataWithOptionToInsertLineFeedsContainsLineFeed() {
        let plainText = "Constitit, et lacrimans, `Quis iam locus’ inquit `Achate,\nquae regio in terris nostri non plena laboris?`"
        let encodedText = "Q29uc3RpdGl0LCBldCBsYWNyaW1hbnMsIGBRdWlzIGlhbSBsb2N1c+KAmSBpbnF1\naXQgYEFjaGF0ZSwKcXVhZSByZWdpbyBpbiB0ZXJyaXMgbm9zdHJpIG5vbiBwbGVu\nYSBsYWJvcmlzP2A="
        guard let data = plainText.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
            XCTFail("Could not encode UTF-8 string")
            return
        }
        let encodedData = data.base64EncodedDataWithOptions([.Encoding64CharacterLineLength, .EncodingEndLineWithLineFeed])
        guard let encodedTextResult = NSString(data: encodedData, encoding: NSASCIIStringEncoding)?.bridge() else {
            XCTFail("Could not convert encoded data to an ASCII String")
            return
        }
        XCTAssertEqual(encodedTextResult, encodedText)
    }
    
    func test_base64EncodedDataWithOptionToInsertCarriageReturnContainsCarriageReturn() {
        let plainText = "Constitit, et lacrimans, `Quis iam locus’ inquit `Achate,\nquae regio in terris nostri non plena laboris?`"
        let encodedText = "Q29uc3RpdGl0LCBldCBsYWNyaW1hbnMsIGBRdWlzIGlhbSBsb2N1c+KAmSBpbnF1aXQgYEFjaGF0\rZSwKcXVhZSByZWdpbyBpbiB0ZXJyaXMgbm9zdHJpIG5vbiBwbGVuYSBsYWJvcmlzP2A="
        guard let data = plainText.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
            XCTFail("Could not encode UTF-8 string")
            return
        }
        let encodedData = data.base64EncodedDataWithOptions([.Encoding76CharacterLineLength, .EncodingEndLineWithCarriageReturn])
        guard let encodedTextResult = NSString(data: encodedData, encoding: NSASCIIStringEncoding)?.bridge() else {
            XCTFail("Could not convert encoded data to an ASCII String")
            return
        }
        XCTAssertEqual(encodedTextResult, encodedText)
    }
    
    func test_base64EncodedDataWithOptionToInsertCarriageReturnAndLineFeedContainsBoth() {
        let plainText = "Revocate animos, maestumque timorem mittite: forsan et haec olim meminisse iuvabit."
        let encodedText = "UmV2b2NhdGUgYW5pbW9zLCBtYWVzdHVtcXVlIHRpbW9yZW0gbWl0dGl0ZTogZm9yc2FuIGV0IGhh\r\nZWMgb2xpbSBtZW1pbmlzc2UgaXV2YWJpdC4="
        guard let data = plainText.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
            XCTFail("Could not encode UTF-8 string")
            return
        }
        let encodedData = data.base64EncodedDataWithOptions([.Encoding76CharacterLineLength, .EncodingEndLineWithCarriageReturn, .EncodingEndLineWithLineFeed])
        guard let encodedTextResult = NSString(data: encodedData, encoding: NSASCIIStringEncoding)?.bridge() else {
            XCTFail("Could not convert encoded data to an ASCII String")
            return
        }
        XCTAssertEqual(encodedTextResult, encodedText)
    }
    
    func test_base64EncodedStringGetsEncodedText() {
        let plainText = "Revocate animos, maestumque timorem mittite: forsan et haec olim meminisse iuvabit."
        let encodedText = "UmV2b2NhdGUgYW5pbW9zLCBtYWVzdHVtcXVlIHRpbW9yZW0gbWl0dGl0ZTogZm9yc2FuIGV0IGhhZWMgb2xpbSBtZW1pbmlzc2UgaXV2YWJpdC4="
        guard let data = plainText.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
            XCTFail("Could not encode UTF-8 string")
            return
        }
        let encodedTextResult = data.base64EncodedStringWithOptions([])
        XCTAssertEqual(encodedTextResult, encodedText)

    }
    func test_base64DecodeWithPadding1() {
        let encodedPadding1 = "AoR="
        let dataPadding1Bytes : [UInt8] = [0x02,0x84]
        let dataPadding1 = NSData(bytes: dataPadding1Bytes, length: dataPadding1Bytes.count)
        
        
        guard let decodedPadding1 = NSData(base64EncodedString:encodedPadding1, options: []) else {
            XCTFail("Could not Base-64 decode data")
            return
        }
        XCTAssert(dataPadding1.isEqualToData(decodedPadding1))
    }
    func test_base64DecodeWithPadding2() {
        let encodedPadding2 = "Ao=="
        let dataPadding2Bytes : [UInt8] = [0x02]
        let dataPadding2 = NSData(bytes: dataPadding2Bytes, length: dataPadding2Bytes.count)
        
        
        guard let decodedPadding2 = NSData(base64EncodedString:encodedPadding2, options: []) else {
            XCTFail("Could not Base-64 decode data")
            return
        }
        XCTAssert(dataPadding2.isEqualToData(decodedPadding2))
    }
    func test_rangeOfData() {
        let baseData : [UInt8] = [0x00,0x01,0x02,0x03,0x04]
        let base = NSData(bytes: baseData, length: baseData.count)
        let baseFullRange = NSRange(location : 0,length : baseData.count)
        let noPrefixRange = NSRange(location : 2,length : baseData.count-2)
        let noSuffixRange = NSRange(location : 0,length : baseData.count-2)
        let notFoundRange = NSMakeRange(NSNotFound, 0)
        
        
        let prefixData : [UInt8] = [0x00,0x01]
        let prefix = NSData(bytes: prefixData, length: prefixData.count)
        let prefixRange = NSMakeRange(0, prefixData.count)
        
        XCTAssert(NSEqualRanges(base.rangeOfData(prefix, options: [], range: baseFullRange),prefixRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(prefix, options: [.Anchored], range: baseFullRange),prefixRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(prefix, options: [.Backwards], range: baseFullRange),prefixRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(prefix, options: [.Backwards,.Anchored], range: baseFullRange),notFoundRange))
        
        XCTAssert(NSEqualRanges(base.rangeOfData(prefix, options: [], range: noPrefixRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(prefix, options: [.Backwards], range: noPrefixRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(prefix, options: [], range: noSuffixRange),prefixRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(prefix, options: [.Backwards], range: noSuffixRange),prefixRange))
        
        
        let suffixData : [UInt8] = [0x03,0x04]
        let suffix = NSData(bytes: suffixData, length: suffixData.count)
        let suffixRange = NSMakeRange(3, suffixData.count)
        
        XCTAssert(NSEqualRanges(base.rangeOfData(suffix, options: [], range: baseFullRange),suffixRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(suffix, options: [.Anchored], range: baseFullRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(suffix, options: [.Backwards], range: baseFullRange),suffixRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(suffix, options: [.Backwards,.Anchored], range: baseFullRange),suffixRange))
        
        XCTAssert(NSEqualRanges(base.rangeOfData(suffix, options: [], range: noPrefixRange),suffixRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(suffix, options: [.Backwards], range: noPrefixRange),suffixRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(suffix, options: [], range: noSuffixRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(suffix, options: [.Backwards], range: noSuffixRange),notFoundRange))
        
        
        let sliceData : [UInt8] = [0x02,0x03]
        let slice = NSData(bytes: sliceData, length: sliceData.count)
        let sliceRange = NSMakeRange(2, sliceData.count)
        
        XCTAssert(NSEqualRanges(base.rangeOfData(slice, options: [], range: baseFullRange),sliceRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(slice, options: [.Anchored], range: baseFullRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(slice, options: [.Backwards], range: baseFullRange),sliceRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(slice, options: [.Backwards,.Anchored], range: baseFullRange),notFoundRange))
        
        let empty = NSData()
        XCTAssert(NSEqualRanges(base.rangeOfData(empty, options: [], range: baseFullRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(empty, options: [.Anchored], range: baseFullRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(empty, options: [.Backwards], range: baseFullRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.rangeOfData(empty, options: [.Backwards,.Anchored], range: baseFullRange),notFoundRange))
        
    }

}
