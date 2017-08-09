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

class TestNSData: XCTestCase {
    

    // MARK: -
    
    // String of course has its own way to get data, but this way tests our own data struct
    func dataFrom(_ string : String) -> Data {
        // Create a Data out of those bytes
        return string.utf8CString.withUnsafeBufferPointer { (ptr) in
            ptr.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: ptr.count) {
                // Subtract 1 so we don't get the null terminator byte. This matches NSString behavior.
                return Data(bytes: $0, count: ptr.count - 1)
            }
        }
    }
    
    static var allTests: [(String, (TestNSData) -> () throws -> Void)] {
        return [
            ("testBasicConstruction", testBasicConstruction),
            ("test_base64Data_medium", test_base64Data_medium),
            ("test_base64Data_small", test_base64Data_small),
            ("test_openingNonExistentFile", test_openingNonExistentFile),
            ("test_contentsOfFile", test_contentsOfFile),
            ("test_contentsOfZeroFile", test_contentsOfZeroFile),
            ("test_basicReadWrite", test_basicReadWrite),
            ("test_bufferSizeCalculation", test_bufferSizeCalculation),
            // ("test_dataHash", test_dataHash),   Disabled due to lack of brdiging in swift runtime -- infinite loops
            ("test_genericBuffers", test_genericBuffers),
            // ("test_writeFailure", test_writeFailure), segfaults
            ("testBasicConstruction", testBasicConstruction),
            ("testBridgingDefault", testBridgingDefault),
            ("testBridgingMutable", testBridgingMutable),
            ("testCopyBytes_oversized", testCopyBytes_oversized),
            ("testCopyBytes_ranges", testCopyBytes_ranges),
            ("testCopyBytes_undersized", testCopyBytes_undersized),
             ("testCopyBytes", testCopyBytes),
            ("testCustomDeallocator", testCustomDeallocator),
            ("testDataInSet", testDataInSet),
            ("testEquality", testEquality),
            ("testGenericAlgorithms", testGenericAlgorithms),
            ("testInitializationWithArray", testInitializationWithArray),
            ("testInsertData", testInsertData),
            ("testLoops", testLoops),
            ("testMutableData", testMutableData),
            ("testRange", testRange),
            ("testReplaceSubrange", testReplaceSubrange),
            ("testReplaceSubrange2", testReplaceSubrange2),
            ("testReplaceSubrange3", testReplaceSubrange3),
            ("testReplaceSubrange4", testReplaceSubrange4),
            ("testReplaceSubrange5", testReplaceSubrange5),
            
            
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
            ("test_rangeOfData",test_rangeOfData),
            ("test_initMutableDataWithLength", test_initMutableDataWithLength),
            ("test_replaceBytes", test_replaceBytes),
            ("test_replaceBytesWithNil", test_replaceBytesWithNil),
            ("test_initDataWithCapacity", test_initDataWithCapacity),
            ("test_initDataWithCount", test_initDataWithCount),
            ("test_emptyStringToData", test_emptyStringToData),
            ("test_repeatingValueInitialization", test_repeatingValueInitialization),
            
            ("test_sliceAppending", test_sliceAppending),
            ("test_replaceSubrange", test_replaceSubrange),
            ("test_sliceWithUnsafeBytes", test_sliceWithUnsafeBytes),
            ("test_sliceIteration", test_sliceIteration),
        ]
    }
    
    func test_writeToURLOptions() {
        let saveData = try! Data(contentsOf: Bundle.main.url(forResource: "Test", withExtension: "plist")!)
        let savePath = URL(fileURLWithPath: "/var/tmp/Test.plist")
        do {
            try saveData.write(to: savePath, options: .atomic)
            let fileManager = FileManager.default
            XCTAssertTrue(fileManager.fileExists(atPath: savePath.path))
            try! fileManager.removeItem(atPath: savePath.path)
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
        let bytes = [UInt8](repeating: 0xff, count: 1024)
        let data = NSData(bytes: bytes, length: bytes.count)
        XCTAssertEqual(data.debugDescription, expected)
    }
    
    func test_longDebugDescription() {
        let expected = "<ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ... ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff>"
        let bytes = [UInt8](repeating: 0xff, count: 100_000)
        let data = NSData(bytes: bytes, length: bytes.count)
        XCTAssertEqual(data.debugDescription, expected)
    }

    func test_edgeDebugDescription() {
        let expected = "<ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ... ffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ff>"
        let bytes = [UInt8](repeating: 0xff, count: 1025)
        let data = NSData(bytes: bytes, length: bytes.count)
        XCTAssertEqual(data.debugDescription, expected)
    }

    func test_edgeNoCopyDescription() {
        let expected = "<ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ... ffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ffffffff ff>"
        let bytes = [UInt8](repeating: 0xff, count: 1025)
        let data = NSData(bytesNoCopy: UnsafeMutablePointer(mutating: bytes), length: bytes.count, freeWhenDone: false)
        XCTAssertEqual(data.debugDescription, expected)
        XCTAssertEqual(data.bytes, bytes)
    }

    func test_initializeWithBase64EncodedDataGetsDecodedData() {
        let plainText = "ARMA virumque cano, Troiae qui primus ab oris\nItaliam, fato profugus, Laviniaque venit"
        let encodedText = "QVJNQSB2aXJ1bXF1ZSBjYW5vLCBUcm9pYWUgcXVpIHByaW11cyBhYiBvcmlzCkl0YWxpYW0sIGZhdG8gcHJvZnVndXMsIExhdmluaWFxdWUgdmVuaXQ="
        guard let encodedData = encodedText.data(using: .utf8) else {
            XCTFail("Could not get UTF-8 data")
            return
        }
        guard let decodedData = Data(base64Encoded: encodedData, options: []) else {
            XCTFail("Could not Base-64 decode data")
            return
        }
        guard let decodedText = String(data: decodedData, encoding: .utf8) else {
            XCTFail("Could not convert decoded data to a UTF-8 String")
            return
        }

        XCTAssertEqual(decodedText, plainText)
        XCTAssertTrue(decodedData == plainText.data(using: .utf8)!)
    }
    
    func test_initializeWithBase64EncodedDataWithNonBase64CharacterIsNil() {
        let encodedText = "QVJNQSB2aXJ1bXF1ZSBjYW5vLCBUcm9pYWUgcXVpIHBya$W11cyBhYiBvcmlzCkl0YWxpYW0sIGZhdG8gcHJvZnVndXMsIExhdmluaWFxdWUgdmVuaXQ="
        guard let encodedData = encodedText.data(using: .utf8) else {
            XCTFail("Could not get UTF-8 data")
            return
        }
        let decodedData = NSData(base64Encoded: encodedData, options: [])
        XCTAssertNil(decodedData)
    }
    
    func test_initializeWithBase64EncodedDataWithNonBase64CharacterWithOptionToAllowItSkipsCharacter() {
        let plainText = "ARMA virumque cano, Troiae qui primus ab oris\nItaliam, fato profugus, Laviniaque venit"
        let encodedText = "QVJNQSB2aXJ1bXF1ZSBjYW5vLCBUcm9pYWUgcXVpIHBya$W11cyBhYiBvcmlzCkl0YWxpYW0sIGZhdG8gcHJvZnVndXMsIExhdmluaWFxdWUgdmVuaXQ="
        guard let encodedData = encodedText.data(using: .utf8) else {
            XCTFail("Could not get UTF-8 data")
            return
        }
        guard let decodedData = Data(base64Encoded: encodedData, options: [.ignoreUnknownCharacters]) else {
            XCTFail("Could not Base-64 decode data")
            return
        }
        guard let decodedText = String(data: decodedData, encoding: .utf8) else {
            XCTFail("Could not convert decoded data to a UTF-8 String")
            return
        }
        
        XCTAssertEqual(decodedText, plainText)
        XCTAssertTrue(decodedData == plainText.data(using: .utf8)!)
    }
    
    func test_initializeWithBase64EncodedStringGetsDecodedData() {
        let plainText = "ARMA virumque cano, Troiae qui primus ab oris\nItaliam, fato profugus, Laviniaque venit"
        let encodedText = "QVJNQSB2aXJ1bXF1ZSBjYW5vLCBUcm9pYWUgcXVpIHByaW11cyBhYiBvcmlzCkl0YWxpYW0sIGZhdG8gcHJvZnVndXMsIExhdmluaWFxdWUgdmVuaXQ="
        guard let decodedData = Data(base64Encoded: encodedText, options: []) else {
            XCTFail("Could not Base-64 decode data")
            return
        }
        guard let decodedText = String(data: decodedData, encoding: .utf8) else {
            XCTFail("Could not convert decoded data to a UTF-8 String")
            return
        }
        
        XCTAssertEqual(decodedText, plainText)
    }
    
    func test_base64EncodedDataGetsEncodedText() {
        let plainText = "Constitit, et lacrimans, `Quis iam locus’ inquit `Achate,\nquae regio in terris nostri non plena laboris?`"
        let encodedText = "Q29uc3RpdGl0LCBldCBsYWNyaW1hbnMsIGBRdWlzIGlhbSBsb2N1c+KAmSBpbnF1aXQgYEFjaGF0ZSwKcXVhZSByZWdpbyBpbiB0ZXJyaXMgbm9zdHJpIG5vbiBwbGVuYSBsYWJvcmlzP2A="
        guard let data = plainText.data(using: String.Encoding.utf8) else {
            XCTFail("Could not encode UTF-8 string")
            return
        }
        let encodedData = data.base64EncodedData()
        guard let encodedTextResult = String(data: encodedData, encoding: String.Encoding.ascii) else {
            XCTFail("Could not convert encoded data to an ASCII String")
            return
        }
        XCTAssertEqual(encodedTextResult, encodedText)
    }
    
    func test_base64EncodedDataWithOptionToInsertLineFeedsContainsLineFeed() {
        let plainText = "Constitit, et lacrimans, `Quis iam locus’ inquit `Achate,\nquae regio in terris nostri non plena laboris?`"
        let encodedText = "Q29uc3RpdGl0LCBldCBsYWNyaW1hbnMsIGBRdWlzIGlhbSBsb2N1c+KAmSBpbnF1\naXQgYEFjaGF0ZSwKcXVhZSByZWdpbyBpbiB0ZXJyaXMgbm9zdHJpIG5vbiBwbGVu\nYSBsYWJvcmlzP2A="
        guard let data = plainText.data(using: String.Encoding.utf8) else {
            XCTFail("Could not encode UTF-8 string")
            return
        }
        let encodedData = data.base64EncodedData(options: [.lineLength64Characters, .endLineWithLineFeed])
        guard let encodedTextResult = String(data: encodedData, encoding: String.Encoding.ascii) else {
            XCTFail("Could not convert encoded data to an ASCII String")
            return
        }
        XCTAssertEqual(encodedTextResult, encodedText)
    }
    
    func test_base64EncodedDataWithOptionToInsertCarriageReturnContainsCarriageReturn() {
        let plainText = "Constitit, et lacrimans, `Quis iam locus’ inquit `Achate,\nquae regio in terris nostri non plena laboris?`"
        let encodedText = "Q29uc3RpdGl0LCBldCBsYWNyaW1hbnMsIGBRdWlzIGlhbSBsb2N1c+KAmSBpbnF1aXQgYEFjaGF0\rZSwKcXVhZSByZWdpbyBpbiB0ZXJyaXMgbm9zdHJpIG5vbiBwbGVuYSBsYWJvcmlzP2A="
        guard let data = plainText.data(using: String.Encoding.utf8) else {
            XCTFail("Could not encode UTF-8 string")
            return
        }
        let encodedData = data.base64EncodedData(options: [.lineLength76Characters, .endLineWithCarriageReturn])
        guard let encodedTextResult = String(data: encodedData, encoding: String.Encoding.ascii) else {
            XCTFail("Could not convert encoded data to an ASCII String")
            return
        }
        XCTAssertEqual(encodedTextResult, encodedText)
    }
    
    func test_base64EncodedDataWithOptionToInsertCarriageReturnAndLineFeedContainsBoth() {
        let plainText = "Revocate animos, maestumque timorem mittite: forsan et haec olim meminisse iuvabit."
        let encodedText = "UmV2b2NhdGUgYW5pbW9zLCBtYWVzdHVtcXVlIHRpbW9yZW0gbWl0dGl0ZTogZm9yc2FuIGV0IGhh\r\nZWMgb2xpbSBtZW1pbmlzc2UgaXV2YWJpdC4="
        guard let data = plainText.data(using: String.Encoding.utf8) else {
            XCTFail("Could not encode UTF-8 string")
            return
        }
        let encodedData = data.base64EncodedData(options: [.lineLength76Characters, .endLineWithCarriageReturn, .endLineWithLineFeed])
        guard let encodedTextResult = String(data: encodedData, encoding: String.Encoding.ascii) else {
            XCTFail("Could not convert encoded data to an ASCII String")
            return
        }
        XCTAssertEqual(encodedTextResult, encodedText)
    }
    
    func test_base64EncodedStringGetsEncodedText() {
        let plainText = "Revocate animos, maestumque timorem mittite: forsan et haec olim meminisse iuvabit."
        let encodedText = "UmV2b2NhdGUgYW5pbW9zLCBtYWVzdHVtcXVlIHRpbW9yZW0gbWl0dGl0ZTogZm9yc2FuIGV0IGhhZWMgb2xpbSBtZW1pbmlzc2UgaXV2YWJpdC4="
        guard let data = plainText.data(using: String.Encoding.utf8) else {
            XCTFail("Could not encode UTF-8 string")
            return
        }
        let encodedTextResult = data.base64EncodedString()
        XCTAssertEqual(encodedTextResult, encodedText)

    }
    func test_base64DecodeWithPadding1() {
        let encodedPadding1 = "AoR="
        let dataPadding1Bytes : [UInt8] = [0x02,0x84]
        let dataPadding1 = NSData(bytes: dataPadding1Bytes, length: dataPadding1Bytes.count)
        
        
        guard let decodedPadding1 = Data(base64Encoded:encodedPadding1, options: []) else {
            XCTFail("Could not Base-64 decode data")
            return
        }
        XCTAssert(dataPadding1.isEqual(to: decodedPadding1))
    }
    func test_base64DecodeWithPadding2() {
        let encodedPadding2 = "Ao=="
        let dataPadding2Bytes : [UInt8] = [0x02]
        let dataPadding2 = NSData(bytes: dataPadding2Bytes, length: dataPadding2Bytes.count)
        
        
        guard let decodedPadding2 = Data(base64Encoded:encodedPadding2, options: []) else {
            XCTFail("Could not Base-64 decode data")
            return
        }
        XCTAssert(dataPadding2.isEqual(to: decodedPadding2))
    }
    func test_rangeOfData() {
        let baseData : [UInt8] = [0x00,0x01,0x02,0x03,0x04]
        let base = NSData(bytes: baseData, length: baseData.count)
        let baseFullRange = NSRange(location : 0,length : baseData.count)
        let noPrefixRange = NSRange(location : 2,length : baseData.count-2)
        let noSuffixRange = NSRange(location : 0,length : baseData.count-2)
        let notFoundRange = NSMakeRange(NSNotFound, 0)
        
        
        let prefixData : [UInt8] = [0x00,0x01]
        let prefix = Data(bytes: prefixData, count: prefixData.count)
        let prefixRange = NSMakeRange(0, prefixData.count)
        
        XCTAssert(NSEqualRanges(base.range(of: prefix, options: [], in: baseFullRange),prefixRange))
        XCTAssert(NSEqualRanges(base.range(of: prefix, options: [.anchored], in: baseFullRange),prefixRange))
        XCTAssert(NSEqualRanges(base.range(of: prefix, options: [.backwards], in: baseFullRange),prefixRange))
        XCTAssert(NSEqualRanges(base.range(of: prefix, options: [.backwards,.anchored], in: baseFullRange),notFoundRange))
        
        XCTAssert(NSEqualRanges(base.range(of: prefix, options: [], in: noPrefixRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.range(of: prefix, options: [.backwards], in: noPrefixRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.range(of: prefix, options: [], in: noSuffixRange),prefixRange))
        XCTAssert(NSEqualRanges(base.range(of: prefix, options: [.backwards], in: noSuffixRange),prefixRange))
        
        
        let suffixData : [UInt8] = [0x03,0x04]
        let suffix = Data(bytes: suffixData, count: suffixData.count)
        let suffixRange = NSMakeRange(3, suffixData.count)
        
        XCTAssert(NSEqualRanges(base.range(of: suffix, options: [], in: baseFullRange),suffixRange))
        XCTAssert(NSEqualRanges(base.range(of: suffix, options: [.anchored], in: baseFullRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.range(of: suffix, options: [.backwards], in: baseFullRange),suffixRange))
        XCTAssert(NSEqualRanges(base.range(of: suffix, options: [.backwards,.anchored], in: baseFullRange),suffixRange))
        
        XCTAssert(NSEqualRanges(base.range(of: suffix, options: [], in: noPrefixRange),suffixRange))
        XCTAssert(NSEqualRanges(base.range(of: suffix, options: [.backwards], in: noPrefixRange),suffixRange))
        XCTAssert(NSEqualRanges(base.range(of: suffix, options: [], in: noSuffixRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.range(of: suffix, options: [.backwards], in: noSuffixRange),notFoundRange))
        
        
        let sliceData : [UInt8] = [0x02,0x03]
        let slice = Data(bytes: sliceData, count: sliceData.count)
        let sliceRange = NSMakeRange(2, sliceData.count)
        
        XCTAssert(NSEqualRanges(base.range(of: slice, options: [], in: baseFullRange),sliceRange))
        XCTAssert(NSEqualRanges(base.range(of: slice, options: [.anchored], in: baseFullRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.range(of: slice, options: [.backwards], in: baseFullRange),sliceRange))
        XCTAssert(NSEqualRanges(base.range(of: slice, options: [.backwards,.anchored], in: baseFullRange),notFoundRange))
        
        let empty = Data()
        XCTAssert(NSEqualRanges(base.range(of: empty, options: [], in: baseFullRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.range(of: empty, options: [.anchored], in: baseFullRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.range(of: empty, options: [.backwards], in: baseFullRange),notFoundRange))
        XCTAssert(NSEqualRanges(base.range(of: empty, options: [.backwards,.anchored], in: baseFullRange),notFoundRange))
        
    }

    func test_initMutableDataWithLength() {
        let mData = NSMutableData(length: 30)
        XCTAssertNotNil(mData)
        XCTAssertEqual(mData!.length, 30)
    }

    func test_replaceBytes() {
        var data = Data(bytes: [0, 0, 0, 0, 0])
        let newData = Data(bytes: [1, 2, 3, 4, 5])

        // test replaceSubrange(_, with:)
        XCTAssertFalse(data == newData)
        data.replaceSubrange(data.startIndex..<data.endIndex, with: newData)
        XCTAssertTrue(data == newData)

        // subscript(index:) uses replaceBytes so use it to test edge conditions
        data[0] = 0
        data[4] = 0
        XCTAssertTrue(data == Data(bytes: [0, 2, 3, 4, 0]))

        // test NSMutableData.replaceBytes(in:withBytes:length:) directly
        func makeData(_ data: [UInt8]) -> NSData {
            return NSData(bytes: data, length: data.count)
        }

        guard let mData = NSMutableData(length: 5) else {
            XCTFail("Cant create NSMutableData")
            return
        }

        let replacement = makeData([8, 9, 10])
        mData.replaceBytes(in: NSMakeRange(1, 3), withBytes: replacement.bytes,
            length: 3)
        let expected = makeData([0, 8, 9, 10, 0])
        XCTAssertEqual(mData, expected)
    }

    func test_replaceBytesWithNil() {
        func makeData(_ data: [UInt8]) -> NSMutableData {
            return NSMutableData(bytes: data, length: data.count)
        }

        let mData = makeData([1, 2, 3, 4, 5])
        mData.replaceBytes(in: NSMakeRange(1, 3), withBytes: nil, length: 0)
        let expected = makeData([1, 5])
        XCTAssertEqual(mData, expected)
    }

    func test_initDataWithCapacity() {
        let data = Data(capacity: 123)
        XCTAssertEqual(data.count, 0)
    }

    func test_initDataWithCount() {
        let dataSize = 1024
        let data = Data(count: dataSize)
        XCTAssertEqual(data.count, dataSize)
        if let index = (data.index { $0 != 0 }) {
            XCTFail("Byte at index: \(index) is not zero: \(data[index])")
            return
        }
    }

    func test_emptyStringToData() {
        let data = "".data(using: .utf8)!
        XCTAssertEqual(0, data.count, "data from empty string is empty")
    }
}

// Tests from Swift SDK Overlay
extension TestNSData {
    func testBasicConstruction() throws {
        
        // Make sure that we were able to create some data
        let hello = dataFrom("hello")
        let helloLength = hello.count
        XCTAssertEqual(hello[0], 0x68, "Unexpected first byte")
        
        let world = dataFrom(" world")
        var helloWorld = hello
        world.withUnsafeBytes {
            helloWorld.append($0, count: world.count)
        }
        
        XCTAssertEqual(hello[0], 0x68, "First byte should not have changed")
        XCTAssertEqual(hello.count, helloLength, "Length of first data should not have changed")
        XCTAssertEqual(helloWorld.count, hello.count + world.count, "The total length should include both buffers")
    }
    
    func testInitializationWithArray() {
        let data = Data(bytes: [1, 2, 3])
        XCTAssertEqual(3, data.count)
        
        let data2 = Data(bytes: [1, 2, 3].filter { $0 >= 2 })
        XCTAssertEqual(2, data2.count)
        
        let data3 = Data(bytes: [1, 2, 3, 4, 5][1..<3])
        XCTAssertEqual(2, data3.count)
    }
    
    func testMutableData() {
        let hello = dataFrom("hello")
        let helloLength = hello.count
        XCTAssertEqual(hello[0], 0x68, "Unexpected first byte")
        
        // Double the length
        var mutatingHello = hello
        mutatingHello.count *= 2
        
        XCTAssertEqual(hello.count, helloLength, "The length of the initial data should not have changed")
        XCTAssertEqual(mutatingHello.count, helloLength * 2, "The length should have changed")
        
        // Get the underlying data for hello2
        mutatingHello.withUnsafeMutableBytes { (bytes : UnsafeMutablePointer<UInt8>) in
            XCTAssertEqual(bytes.pointee, 0x68, "First byte should be 0x68")
            
            // Mutate it
            bytes.pointee = 0x67
            XCTAssertEqual(bytes.pointee, 0x67, "First byte should be 0x67")
            XCTAssertEqual(mutatingHello[0], 0x67, "First byte accessed via other method should still be 0x67")
            
            // Verify that the first data is still correct
            XCTAssertEqual(hello[0], 0x68, "The first byte should still be 0x68")
        }
    }
    

    
    func testBridgingDefault() {
        let hello = dataFrom("hello")
        // Convert from struct Data to NSData
        if let s = NSString(data: hello, encoding: String.Encoding.utf8.rawValue) {
            XCTAssertTrue(s.isEqual(to: "hello"), "The strings should be equal")
        }
        
        // Convert from NSData to struct Data
        let goodbye = dataFrom("goodbye")
        if let resultingData = NSString(string: "goodbye").data(using: String.Encoding.utf8.rawValue) {
            XCTAssertEqual(resultingData[0], goodbye[0], "First byte should be equal")
        }
    }
    
    func testBridgingMutable() {
        // Create a mutable data
        var helloWorld = dataFrom("hello")
        helloWorld.append(dataFrom("world"))
        
        // Convert from struct Data to NSData
        if let s = NSString(data: helloWorld, encoding: String.Encoding.utf8.rawValue) {
            XCTAssertTrue(s.isEqual(to: "helloworld"), "The strings should be equal")
        }
        
    }
    
  
    func testEquality() {
        let d1 = dataFrom("hello")
        let d2 = dataFrom("hello")
        
        // Use == explicitly here to make sure we're calling the right methods
        XCTAssertTrue(d1 == d2, "Data should be equal")
    }
    
    func testDataInSet() {
        let d1 = dataFrom("Hello")
        let d2 = dataFrom("Hello")
        let d3 = dataFrom("World")
        
        var s = Set<Data>()
        s.insert(d1)
        s.insert(d2)
        s.insert(d3)
        
        XCTAssertEqual(s.count, 2, "Expected only two entries in the Set")
    }
    
    func testReplaceSubrange() {
        var hello = dataFrom("Hello")
        let world = dataFrom("World")
        
        hello[0] = world[0]
        XCTAssertEqual(hello[0], world[0])
        
        var goodbyeWorld = dataFrom("Hello World")
        let goodbye = dataFrom("Goodbye")
        let expected = dataFrom("Goodbye World")
        
        goodbyeWorld.replaceSubrange(0..<5, with: goodbye)
        XCTAssertEqual(goodbyeWorld, expected)
    }
    
    func testReplaceSubrange2() {
        let hello = dataFrom("Hello")
        let world = dataFrom(" World")
        let goodbye = dataFrom("Goodbye")
        let expected = dataFrom("Goodbye World")
        
        var mutateMe = hello
        mutateMe.append(world)
        
        if let found = mutateMe.range(of: hello) {
            mutateMe.replaceSubrange(found, with: goodbye)
        }
        XCTAssertEqual(mutateMe, expected)
    }
    
    func testReplaceSubrange3() {
        // The expected result
        let expectedBytes : [UInt8] = [1, 2, 9, 10, 11, 12, 13]
        let expected = expectedBytes.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
        
        // The data we'll mutate
        let someBytes : [UInt8] = [1, 2, 3, 4, 5]
        var a = someBytes.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
        
        // The bytes we'll insert
        let b : [UInt8] = [9, 10, 11, 12, 13]
        b.withUnsafeBufferPointer {
            a.replaceSubrange(2..<5, with: $0)
        }
        XCTAssertEqual(expected, a)
    }
    
    func testReplaceSubrange4() {
        let expectedBytes : [UInt8] = [1, 2, 9, 10, 11, 12, 13]
        let expected = Data(bytes: expectedBytes)
        
        // The data we'll mutate
        let someBytes : [UInt8] = [1, 2, 3, 4, 5]
        var a = Data(bytes: someBytes)
        
        // The bytes we'll insert
        let b : [UInt8] = [9, 10, 11, 12, 13]
        a.replaceSubrange(2..<5, with: b)
        XCTAssertEqual(expected, a)
    }
    
    func testReplaceSubrange5() {
        var d = Data(bytes: [1, 2, 3])
        d.replaceSubrange(0..<0, with: [4])
        XCTAssertEqual(Data(bytes: [4, 1, 2, 3]), d)
        
        d.replaceSubrange(0..<4, with: [9])
        XCTAssertEqual(Data(bytes: [9]), d)
        
        d.replaceSubrange(0..<d.count, with: [])
        XCTAssertEqual(Data(), d)
        
        d.replaceSubrange(0..<0, with: [1, 2, 3, 4])
        XCTAssertEqual(Data(bytes: [1, 2, 3, 4]), d)
        
        d.replaceSubrange(1..<3, with: [9, 8])
        XCTAssertEqual(Data(bytes: [1, 9, 8, 4]), d)
        
        d.replaceSubrange(d.count..<d.count, with: [5])
        XCTAssertEqual(Data(bytes: [1, 9, 8, 4, 5]), d)
    }
    
    func testRange() {
        let helloWorld = dataFrom("Hello World")
        let goodbye = dataFrom("Goodbye")
        let hello = dataFrom("Hello")
        
        do {
            let found = helloWorld.range(of: goodbye)
            XCTAssertTrue(found == nil || found!.isEmpty)
        }
        
        do {
            let found = helloWorld.range(of: goodbye, options: .anchored)
            XCTAssertTrue(found == nil || found!.isEmpty)
        }
        
        do {
            let found = helloWorld.range(of: hello, in: 7..<helloWorld.count)
            XCTAssertTrue(found == nil || found!.isEmpty)
        }
    }
    
    func testInsertData() {
        let hello = dataFrom("Hello")
        let world = dataFrom(" World")
        let expected = dataFrom("Hello World")
        var helloWorld = dataFrom("")
        
        helloWorld.replaceSubrange(0..<0, with: world)
        helloWorld.replaceSubrange(0..<0, with: hello)
        
        XCTAssertEqual(helloWorld, expected)
    }
    
    func testLoops() {
        let hello = dataFrom("Hello")
        var count = 0
        for _ in hello {
            count += 1
        }
        XCTAssertEqual(count, 5)
    }
    
    func testGenericAlgorithms() {
        let hello = dataFrom("Hello World")
        
        let isCapital = { (byte : UInt8) in byte >= 65 && byte <= 90 }
        
        let allCaps = hello.filter(isCapital)
        XCTAssertEqual(allCaps.count, 2)
        
        let capCount = hello.reduce(0) { isCapital($1) ? $0 + 1 : $0 }
        XCTAssertEqual(capCount, 2)
        
        let allLower = hello.map { isCapital($0) ? $0 + 31 : $0 }
        XCTAssertEqual(allLower.count, hello.count)
    }
    
    func testCustomDeallocator() {
        var deallocatorCalled = false
        
        // Scope the data to a block to control lifecycle
        do {
            let buffer = malloc(16)!
            let bytePtr = buffer.bindMemory(to: UInt8.self, capacity: 16)
            var data = Data(bytesNoCopy: bytePtr, count: 16, deallocator: .custom({ (ptr, size) in
                deallocatorCalled = true
                free(UnsafeMutableRawPointer(ptr))
            }))
            // Use the data
            data[0] = 1
        }
        
        XCTAssertTrue(deallocatorCalled, "Custom deallocator was never called")
    }
    
    func testCopyBytes() {
        let c = 10
        let underlyingBuffer = malloc(c * MemoryLayout<UInt16>.stride)!
        let u16Ptr = underlyingBuffer.bindMemory(to: UInt16.self, capacity: c)
        let buffer = UnsafeMutableBufferPointer<UInt16>(start: u16Ptr, count: c)
        
        buffer[0] = 0
        buffer[1] = 0
        
        var data = Data(capacity: c * MemoryLayout<UInt16>.stride)
        data.resetBytes(in: 0..<c * MemoryLayout<UInt16>.stride)
        data[0] = 0xFF
        data[1] = 0xFF
        let copiedCount = data.copyBytes(to: buffer)
        XCTAssertEqual(copiedCount, c * MemoryLayout<UInt16>.stride)
        
        XCTAssertEqual(buffer[0], 0xFFFF)
        free(underlyingBuffer)
    }
    
    func testCopyBytes_undersized() {
        let a : [UInt8] = [1, 2, 3, 4, 5]
        var data = a.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
        let expectedSize = MemoryLayout<UInt8>.stride * a.count
        XCTAssertEqual(expectedSize, data.count)
        
        let size = expectedSize - 1
        let underlyingBuffer = malloc(size)!
        let buffer = UnsafeMutableBufferPointer(start: underlyingBuffer.bindMemory(to: UInt8.self, capacity: size), count: size)
        
        // We should only copy in enough bytes that can fit in the buffer
        let copiedCount = data.copyBytes(to: buffer)
        XCTAssertEqual(expectedSize - 1, copiedCount)
        
        var index = 0
        for v in a[0..<expectedSize-1] {
            XCTAssertEqual(v, buffer[index])
            index += 1
        }
        
        free(underlyingBuffer)
    }
    
    func testCopyBytes_oversized() {
        let a : [Int32] = [1, 0, 1, 0, 1]
        var data = a.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
        let expectedSize = MemoryLayout<Int32>.stride * a.count
        XCTAssertEqual(expectedSize, data.count)

        let size = expectedSize + 1
        let underlyingBuffer = malloc(size)!
        let buffer = UnsafeMutableBufferPointer(start: underlyingBuffer.bindMemory(to: UInt8.self, capacity: size), count: size)
        
        let copiedCount = data.copyBytes(to: buffer)
        XCTAssertEqual(expectedSize, copiedCount)
        
        free(underlyingBuffer)
    }
    
    func testCopyBytes_ranges() {
        
        do {
            // Equal sized buffer, data
            let a : [UInt8] = [1, 2, 3, 4, 5]
            var data = a.withUnsafeBufferPointer {
                return Data(buffer: $0)
            }

            let size = data.count
            let underlyingBuffer = malloc(size)!
            let buffer = UnsafeMutableBufferPointer(start: underlyingBuffer.bindMemory(to: UInt8.self, capacity: size), count: size)
            
            var copiedCount : Int
            
            copiedCount = data.copyBytes(to: buffer, from: 0..<0)
            XCTAssertEqual(0, copiedCount)
            
            copiedCount = data.copyBytes(to: buffer, from: 1..<1)
            XCTAssertEqual(0, copiedCount)
            
            copiedCount = data.copyBytes(to: buffer, from: 0..<3)
            XCTAssertEqual((0..<3).count, copiedCount)
            
            var index = 0
            for v in a[0..<3] {
                XCTAssertEqual(v, buffer[index])
                index += 1
            }
            free(underlyingBuffer)
        }
        
        do {
            // Larger buffer than data
            let a : [UInt8] = [1, 2, 3, 4]
            let data = a.withUnsafeBufferPointer {
                return Data(buffer: $0)
            }

            let size = 10
            let underlyingBuffer = malloc(size)!
            let buffer = UnsafeMutableBufferPointer(start: underlyingBuffer.bindMemory(to: UInt8.self, capacity: size), count: size)

            var copiedCount : Int
            
            copiedCount = data.copyBytes(to: buffer, from: 0..<3)
            XCTAssertEqual((0..<3).count, copiedCount)
            
            var index = 0
            for v in a[0..<3] {
                XCTAssertEqual(v, buffer[index])
                index += 1
            }
            free(underlyingBuffer)
        }
        
        do {
            // Larger data than buffer
            let a : [UInt8] = [1, 2, 3, 4, 5, 6]
            let data = a.withUnsafeBufferPointer {
                return Data(buffer: $0)
            }

            let size = 4
            let underlyingBuffer = malloc(size)!
            let buffer = UnsafeMutableBufferPointer(start: underlyingBuffer.bindMemory(to: UInt8.self, capacity: size), count: size)
            
            var copiedCount : Int
            
            copiedCount = data.copyBytes(to: buffer, from: 0..<data.index(before: data.endIndex))
            XCTAssertEqual(4, copiedCount)
            
            var index = 0
            for v in a[0..<4] {
                XCTAssertEqual(v, buffer[index])
                index += 1
            }
            free(underlyingBuffer)
            
        }
    }
    
    func test_base64Data_small() {
        let data = "Hello World".data(using: .utf8)!
        let base64 = data.base64EncodedString()
        XCTAssertEqual("SGVsbG8gV29ybGQ=", base64, "trivial base64 conversion should work")
    }
    
    func test_dataHash() {
        let dataStruct = "Hello World".data(using: .utf8)!
        let dataObj = dataStruct._bridgeToObjectiveC()
        XCTAssertEqual(dataObj.hashValue, dataStruct.hashValue, "Data and NSData should have the same hash value")
    }
    
    func test_base64Data_medium() {
        let data = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut at tincidunt arcu. Suspendisse nec sodales erat, sit amet imperdiet ipsum. Etiam sed ornare felis. Nunc mauris turpis, bibendum non lectus quis, malesuada placerat turpis. Nam adipiscing non massa et semper. Nulla convallis semper bibendum. Aliquam dictum nulla cursus mi ultricies, at tincidunt mi sagittis. Nulla faucibus at dui quis sodales. Morbi rutrum, dui id ultrices venenatis, arcu urna egestas felis, vel suscipit mauris arcu quis risus. Nunc venenatis ligula at orci tristique, et mattis purus pulvinar. Etiam ultricies est odio. Nunc eleifend malesuada justo, nec euismod sem ultrices quis. Etiam nec nibh sit amet lorem faucibus dapibus quis nec leo. Praesent sit amet mauris vel lacus hendrerit porta mollis consectetur mi. Donec eget tortor dui. Morbi imperdiet, arcu sit amet elementum interdum, quam nisl tempor quam, vitae feugiat augue purus sed lacus. In ac urna adipiscing purus venenatis volutpat vel et metus. Nullam nec auctor quam. Phasellus porttitor felis ac nibh gravida suscipit tempus at ante. Nunc pellentesque iaculis sapien a mattis. Aenean eleifend dolor non nunc laoreet, non dictum massa aliquam. Aenean quis turpis augue. Praesent augue lectus, mollis nec elementum eu, dignissim at velit. Ut congue neque id ullamcorper pellentesque. Maecenas euismod in elit eu vehicula. Nullam tristique dui nulla, nec convallis metus suscipit eget. Cras semper augue nec cursus blandit. Nulla rhoncus et odio quis blandit. Praesent lobortis dignissim velit ut pulvinar. Duis interdum quam adipiscing dolor semper semper. Nunc bibendum convallis dui, eget mollis magna hendrerit et. Morbi facilisis, augue eu fringilla convallis, mauris est cursus dolor, eu posuere odio nunc quis orci. Ut eu justo sem. Phasellus ut erat rhoncus, faucibus arcu vitae, vulputate erat. Aliquam nec magna viverra, interdum est vitae, rhoncus sapien. Duis tincidunt tempor ipsum ut dapibus. Nullam commodo varius metus, sed sollicitudin eros. Etiam nec odio et dui tempor blandit posuere.".data(using: .utf8)!
        let base64 = data.base64EncodedString()
        XCTAssertEqual("TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNlY3RldHVyIGFkaXBpc2NpbmcgZWxpdC4gVXQgYXQgdGluY2lkdW50IGFyY3UuIFN1c3BlbmRpc3NlIG5lYyBzb2RhbGVzIGVyYXQsIHNpdCBhbWV0IGltcGVyZGlldCBpcHN1bS4gRXRpYW0gc2VkIG9ybmFyZSBmZWxpcy4gTnVuYyBtYXVyaXMgdHVycGlzLCBiaWJlbmR1bSBub24gbGVjdHVzIHF1aXMsIG1hbGVzdWFkYSBwbGFjZXJhdCB0dXJwaXMuIE5hbSBhZGlwaXNjaW5nIG5vbiBtYXNzYSBldCBzZW1wZXIuIE51bGxhIGNvbnZhbGxpcyBzZW1wZXIgYmliZW5kdW0uIEFsaXF1YW0gZGljdHVtIG51bGxhIGN1cnN1cyBtaSB1bHRyaWNpZXMsIGF0IHRpbmNpZHVudCBtaSBzYWdpdHRpcy4gTnVsbGEgZmF1Y2lidXMgYXQgZHVpIHF1aXMgc29kYWxlcy4gTW9yYmkgcnV0cnVtLCBkdWkgaWQgdWx0cmljZXMgdmVuZW5hdGlzLCBhcmN1IHVybmEgZWdlc3RhcyBmZWxpcywgdmVsIHN1c2NpcGl0IG1hdXJpcyBhcmN1IHF1aXMgcmlzdXMuIE51bmMgdmVuZW5hdGlzIGxpZ3VsYSBhdCBvcmNpIHRyaXN0aXF1ZSwgZXQgbWF0dGlzIHB1cnVzIHB1bHZpbmFyLiBFdGlhbSB1bHRyaWNpZXMgZXN0IG9kaW8uIE51bmMgZWxlaWZlbmQgbWFsZXN1YWRhIGp1c3RvLCBuZWMgZXVpc21vZCBzZW0gdWx0cmljZXMgcXVpcy4gRXRpYW0gbmVjIG5pYmggc2l0IGFtZXQgbG9yZW0gZmF1Y2lidXMgZGFwaWJ1cyBxdWlzIG5lYyBsZW8uIFByYWVzZW50IHNpdCBhbWV0IG1hdXJpcyB2ZWwgbGFjdXMgaGVuZHJlcml0IHBvcnRhIG1vbGxpcyBjb25zZWN0ZXR1ciBtaS4gRG9uZWMgZWdldCB0b3J0b3IgZHVpLiBNb3JiaSBpbXBlcmRpZXQsIGFyY3Ugc2l0IGFtZXQgZWxlbWVudHVtIGludGVyZHVtLCBxdWFtIG5pc2wgdGVtcG9yIHF1YW0sIHZpdGFlIGZldWdpYXQgYXVndWUgcHVydXMgc2VkIGxhY3VzLiBJbiBhYyB1cm5hIGFkaXBpc2NpbmcgcHVydXMgdmVuZW5hdGlzIHZvbHV0cGF0IHZlbCBldCBtZXR1cy4gTnVsbGFtIG5lYyBhdWN0b3IgcXVhbS4gUGhhc2VsbHVzIHBvcnR0aXRvciBmZWxpcyBhYyBuaWJoIGdyYXZpZGEgc3VzY2lwaXQgdGVtcHVzIGF0IGFudGUuIE51bmMgcGVsbGVudGVzcXVlIGlhY3VsaXMgc2FwaWVuIGEgbWF0dGlzLiBBZW5lYW4gZWxlaWZlbmQgZG9sb3Igbm9uIG51bmMgbGFvcmVldCwgbm9uIGRpY3R1bSBtYXNzYSBhbGlxdWFtLiBBZW5lYW4gcXVpcyB0dXJwaXMgYXVndWUuIFByYWVzZW50IGF1Z3VlIGxlY3R1cywgbW9sbGlzIG5lYyBlbGVtZW50dW0gZXUsIGRpZ25pc3NpbSBhdCB2ZWxpdC4gVXQgY29uZ3VlIG5lcXVlIGlkIHVsbGFtY29ycGVyIHBlbGxlbnRlc3F1ZS4gTWFlY2VuYXMgZXVpc21vZCBpbiBlbGl0IGV1IHZlaGljdWxhLiBOdWxsYW0gdHJpc3RpcXVlIGR1aSBudWxsYSwgbmVjIGNvbnZhbGxpcyBtZXR1cyBzdXNjaXBpdCBlZ2V0LiBDcmFzIHNlbXBlciBhdWd1ZSBuZWMgY3Vyc3VzIGJsYW5kaXQuIE51bGxhIHJob25jdXMgZXQgb2RpbyBxdWlzIGJsYW5kaXQuIFByYWVzZW50IGxvYm9ydGlzIGRpZ25pc3NpbSB2ZWxpdCB1dCBwdWx2aW5hci4gRHVpcyBpbnRlcmR1bSBxdWFtIGFkaXBpc2NpbmcgZG9sb3Igc2VtcGVyIHNlbXBlci4gTnVuYyBiaWJlbmR1bSBjb252YWxsaXMgZHVpLCBlZ2V0IG1vbGxpcyBtYWduYSBoZW5kcmVyaXQgZXQuIE1vcmJpIGZhY2lsaXNpcywgYXVndWUgZXUgZnJpbmdpbGxhIGNvbnZhbGxpcywgbWF1cmlzIGVzdCBjdXJzdXMgZG9sb3IsIGV1IHBvc3VlcmUgb2RpbyBudW5jIHF1aXMgb3JjaS4gVXQgZXUganVzdG8gc2VtLiBQaGFzZWxsdXMgdXQgZXJhdCByaG9uY3VzLCBmYXVjaWJ1cyBhcmN1IHZpdGFlLCB2dWxwdXRhdGUgZXJhdC4gQWxpcXVhbSBuZWMgbWFnbmEgdml2ZXJyYSwgaW50ZXJkdW0gZXN0IHZpdGFlLCByaG9uY3VzIHNhcGllbi4gRHVpcyB0aW5jaWR1bnQgdGVtcG9yIGlwc3VtIHV0IGRhcGlidXMuIE51bGxhbSBjb21tb2RvIHZhcml1cyBtZXR1cywgc2VkIHNvbGxpY2l0dWRpbiBlcm9zLiBFdGlhbSBuZWMgb2RpbyBldCBkdWkgdGVtcG9yIGJsYW5kaXQgcG9zdWVyZS4=", base64, "medium base64 conversion should work")
    }

    func test_openingNonExistentFile() {
        var didCatchError = false

        do {
            let _ = try NSData(contentsOfFile: "does not exist", options: [])
        } catch {
            didCatchError = true
        }

        XCTAssertTrue(didCatchError)
    }

    func test_contentsOfFile() {
        let testDir = testBundle().resourcePath
        let filename = testDir!.appending("/NSStringTestData.txt")

        let contents = NSData(contentsOfFile: filename)
        XCTAssertNotNil(contents)
        if let contents = contents {
            let ptr =  UnsafeMutableRawPointer(mutating: contents.bytes)
            let str = String(bytesNoCopy: ptr, length: contents.length,
                         encoding: .ascii, freeWhenDone: false)
            XCTAssertEqual(str, "swift-corelibs-foundation")
        }
    }

    func test_contentsOfZeroFile() {
#if os(Linux)
        guard FileManager.default.fileExists(atPath: "/proc/self") else {
            return
        }
        let contents = NSData(contentsOfFile: "/proc/self/cmdline")
        XCTAssertNotNil(contents)
        if let contents = contents {
            XCTAssertTrue(contents.length > 0)
            let ptr = UnsafeMutableRawPointer(mutating: contents.bytes)
            let str = String(bytesNoCopy: ptr, length: contents.length,
                             encoding: .ascii, freeWhenDone: false)
            XCTAssertNotNil(str)
            if let str = str {
                XCTAssertTrue(str.hasSuffix("TestFoundation"))
            }
        }

        do {
            let maps = try String(contentsOfFile: "/proc/self/maps", encoding: .utf8)
            XCTAssertTrue(maps.count > 0)
        } catch {
            XCTFail("Cannot read /proc/self/maps: \(String(describing: error))")
        }
#endif
    }

    func test_basicReadWrite() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testfile")
        let count = 1 << 24
        let randomMemory = malloc(count)!
        let ptr = randomMemory.bindMemory(to: UInt8.self, capacity: count)
        let data = Data(bytesNoCopy: ptr, count: count, deallocator: .free)
        do {
            try data.write(to: url)
            let readData = try Data(contentsOf: url)
            XCTAssertEqual(data, readData)
        } catch {
            XCTFail("Should not have thrown")
        }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            // ignore
        }
    }
    
    func test_writeFailure() {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("testfile")
        
        let data = Data()
        do {
            try data.write(to: url)
        } catch let error as NSError {
            print(error)
            XCTAssertTrue(false, "Should not have thrown")
        } catch {
            XCTFail("unexpected error")
        }
        
        do {
            try data.write(to: url, options: [.withoutOverwriting])
            XCTAssertTrue(false, "Should have thrown")
        } catch let error as NSError {
            XCTAssertEqual(error.code, CocoaError.fileWriteFileExists.rawValue)
        } catch {
            XCTFail("unexpected error")
        }
        
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            // ignore
        }
        
        // Make sure clearing the error condition allows the write to succeed
        do {
            try data.write(to: url, options: [.withoutOverwriting])
        } catch {
            XCTAssertTrue(false, "Should not have thrown")
        }
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            // ignore
        }
    }
    
    func test_genericBuffers() {
        let a : [Int32] = [1, 0, 1, 0, 1]
        var data = a.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
        
        var expectedSize = MemoryLayout<Int32>.stride * a.count
        XCTAssertEqual(expectedSize, data.count)
        
        [false, true].withUnsafeBufferPointer {
            data.append($0)
        }
        
        expectedSize += MemoryLayout<Bool>.stride * 2
        XCTAssertEqual(expectedSize, data.count)
        
        let size = expectedSize
        let underlyingBuffer = malloc(size)!
        let buffer = UnsafeMutableBufferPointer(start: underlyingBuffer.bindMemory(to: UInt8.self, capacity: size), count: size)
        let copiedCount = data.copyBytes(to: buffer)
        XCTAssertEqual(copiedCount, expectedSize)
        
        free(underlyingBuffer)
    }
    
    // intentionally structured so sizeof() != strideof()
    struct MyStruct {
        var time: UInt64
        let x: UInt32
        let y: UInt32
        let z: UInt32
        init() {
            time = 0
            x = 1
            y = 2
            z = 3
        }
    }
    
    func test_bufferSizeCalculation() {
        // Make sure that Data is correctly using strideof instead of sizeof.
        // n.b. if sizeof(MyStruct) == strideof(MyStruct), this test is not as useful as it could be
        
        // init
        let stuff = [MyStruct(), MyStruct(), MyStruct()]
        var data = stuff.withUnsafeBufferPointer {
            return Data(buffer: $0)
        }
        
        XCTAssertEqual(data.count, MemoryLayout<MyStruct>.stride * 3)
        
        
        // append
        stuff.withUnsafeBufferPointer {
            data.append($0)
        }
        
        XCTAssertEqual(data.count, MemoryLayout<MyStruct>.stride * 6)
        
        // copyBytes
        do {
            // equal size
            let underlyingBuffer = malloc(6 * MemoryLayout<MyStruct>.stride)!
            defer { free(underlyingBuffer) }
            
            let ptr = underlyingBuffer.bindMemory(to: MyStruct.self, capacity: 6)
            let buffer = UnsafeMutableBufferPointer<MyStruct>(start: ptr, count: 6)
            
            let byteCount = data.copyBytes(to: buffer)
            XCTAssertEqual(6 * MemoryLayout<MyStruct>.stride, byteCount)
        }
        
        do {
            // undersized
            let underlyingBuffer = malloc(3 * MemoryLayout<MyStruct>.stride)!
            defer { free(underlyingBuffer) }
            
            let ptr = underlyingBuffer.bindMemory(to: MyStruct.self, capacity: 3)
            let buffer = UnsafeMutableBufferPointer<MyStruct>(start: ptr, count: 3)
            
            let byteCount = data.copyBytes(to: buffer)
            XCTAssertEqual(3 * MemoryLayout<MyStruct>.stride, byteCount)
        }
        
        do {
            // oversized
            let underlyingBuffer = malloc(12 * MemoryLayout<MyStruct>.stride)!
            defer { free(underlyingBuffer) }
            
            let ptr = underlyingBuffer.bindMemory(to: MyStruct.self, capacity: 6)
            let buffer = UnsafeMutableBufferPointer<MyStruct>(start: ptr, count: 6)
            
            let byteCount = data.copyBytes(to: buffer)
            XCTAssertEqual(6 * MemoryLayout<MyStruct>.stride, byteCount)
        }
    }

    func test_repeatingValueInitialization() {
        var d = Data(repeating: 0x01, count: 3)
        let elements = repeatElement(UInt8(0x02), count: 3) // ensure we fall into the sequence case
        d.append(contentsOf: elements)

        XCTAssertEqual(d[0], 0x01)
        XCTAssertEqual(d[1], 0x01)
        XCTAssertEqual(d[2], 0x01)

        XCTAssertEqual(d[3], 0x02)
        XCTAssertEqual(d[4], 0x02)
        XCTAssertEqual(d[5], 0x02)
    }
    
    func test_sliceAppending() {
        // https://bugs.swift.org/browse/SR-4473
        var fooData = Data()
        let barData = Data([0, 1, 2, 3, 4, 5])
        let slice = barData.suffix(from: 3)
        fooData.append(slice)
        XCTAssertEqual(fooData[0], 0x03)
        XCTAssertEqual(fooData[1], 0x04)
        XCTAssertEqual(fooData[2], 0x05)
    }
    
    func test_replaceSubrange() {
        // https://bugs.swift.org/browse/SR-4462
        let data = Data(bytes: [0x01, 0x02])
        var dataII = Data(base64Encoded: data.base64EncodedString())!
        dataII.replaceSubrange(0..<1, with: Data())
        XCTAssertEqual(dataII[0], 0x02)
    }
    
    func test_sliceWithUnsafeBytes() {
        let base = Data([0, 1, 2, 3, 4, 5])
        let slice = base[2..<4]
        let segment = slice.withUnsafeBytes { (ptr: UnsafePointer<UInt8>) -> [UInt8] in
            return [ptr.pointee, ptr.advanced(by: 1).pointee]
        }
        XCTAssertEqual(segment, [UInt8(2), UInt8(3)])
    }
    
    func test_sliceIteration() {
        let base = Data([0, 1, 2, 3, 4, 5])
        let slice = base[2..<4]
        var found = [UInt8]()
        for byte in slice {
            found.append(byte)
        }
        XCTAssertEqual(found[0], 2)
        XCTAssertEqual(found[1], 3)
    }
}

