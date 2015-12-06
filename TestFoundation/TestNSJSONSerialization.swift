// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    @testable import Foundation
    import XCTest
#else
    @testable import SwiftFoundation
    import SwiftXCTest
#endif


class TestNSJSONSerialization : XCTestCase {
    
    var allTests : [(String, () -> ())] {
        return JSONObjectWithDataTests
            + detectEncodingTests
            + deserializationTests
    }
    
}

//MARK: - JSONObjectWithData
extension TestNSJSONSerialization {
    var JSONObjectWithDataTests: [(String, () -> ())] {
        return [
            ("test_JSONObjectWithData_emptyObject", test_JSONObjectWithData_emptyObject)
        ]
    }
    
    func test_JSONObjectWithData_emptyObject() {
        let subject = NSData(bytes: UnsafePointer<Void>([UInt8]([0x7B, 0x7D])), length: 2)
        
        let object = try! NSJSONSerialization.JSONObjectWithData(subject, options: []) as? [NSObject: AnyObject]
        XCTAssertEqual(object?.keys.count, 0)
    }
}

//MARK: - Encoding Detection
extension TestNSJSONSerialization {
    
    var detectEncodingTests: [(String, () -> ())] {
        return [
            ("test_detectEncoding_basic", test_detectEncoding_basic),
            ("test_detectEncoding_empty", test_detectEncoding_empty),
            ("test_detectEncoding_single_char", test_detectEncoding_single_char),
            ("test_detectEncoding_BOM_utf8", test_detectEncoding_BOM_utf8),
            ("test_detectEncoding_BOM_utf16be", test_detectEncoding_BOM_utf16be),
            ("test_detectEncoding_BOM_utf16le", test_detectEncoding_BOM_utf16le),
            ("test_detectEncoding_BOM_utf32be", test_detectEncoding_BOM_utf32be),
            ("test_detectEncoding_BOM_utf32le", test_detectEncoding_BOM_utf32le),
        ]
    }
    
    func test_detectEncoding_basic() {
        let subjects: [NSStringEncoding: [UInt8]] = [
            NSUTF8StringEncoding: [0x7B, 0x7D], // "{}"
            NSUTF16BigEndianStringEncoding:    [0x0, 0x7B, 0x0, 0x7D],
            NSUTF16LittleEndianStringEncoding: [0x7B, 0x0, 0x7D, 0x0],
            NSUTF32BigEndianStringEncoding:    [0x0, 0x0, 0x0, 0x7B, 0x0, 0x0, 0x0, 0x7D],
            NSUTF32LittleEndianStringEncoding: [0x7B, 0x0, 0x0, 0x0, 0x7D, 0x0, 0x0, 0x0],
        ]

        for (encoding, encoded) in subjects {
            XCTAssertEqual(NSJSONSerialization.detectEncoding(NSData(bytes: UnsafePointer<Void>(encoded), length: encoded.count)), encoding)
        }
    }
    
    func test_detectEncoding_empty() {
        XCTAssertEqual(NSJSONSerialization.detectEncoding(NSData()), NSUTF8StringEncoding)
    }
    
    func test_detectEncoding_single_char() {
        let subjects: [NSStringEncoding: [UInt8]] = [
            NSUTF8StringEncoding: [0x33], // "3"
            NSUTF16BigEndianStringEncoding:    [0x0, 0x33],
            NSUTF16LittleEndianStringEncoding: [0x33, 0x0],
        ]
        
        for (encoding, encoded) in subjects {
            XCTAssertEqual(NSJSONSerialization.detectEncoding(NSData(bytes: UnsafePointer<Void>(encoded), length: encoded.count)), encoding)
        }
    }
    
    func test_detectEncoding_BOM_utf8() {
        let bom: [UInt8] = [0xEF, 0xBB, 0xBF]
        let utf8BOM = NSData(bytes: UnsafePointer<Void>(bom), length: 3)
        XCTAssertEqual(NSJSONSerialization.detectEncoding(utf8BOM), NSUTF8StringEncoding)
    }
    
    func test_detectEncoding_BOM_utf16be() {
        let bom: [UInt8] = [0xFE, 0xFF]
        let utf16beBOM = NSData(bytes: UnsafePointer<Void>(bom), length: 2)
        XCTAssertEqual(NSJSONSerialization.detectEncoding(utf16beBOM), NSUTF16BigEndianStringEncoding)
    }
    
    func test_detectEncoding_BOM_utf16le() {
        let bom: [UInt8] = [0xFF, 0xFE]
        let utf16leBOM = NSData(bytes: UnsafePointer<Void>(bom), length: 2)
        XCTAssertEqual(NSJSONSerialization.detectEncoding(utf16leBOM), NSUTF16LittleEndianStringEncoding)
    }
    
    func test_detectEncoding_BOM_utf32be() {
        let bom: [UInt8] = [0x00, 0x00, 0xFE, 0xFF]
        let utf32beBOM = NSData(bytes: UnsafePointer<Void>(bom), length: 4)
        XCTAssertEqual(NSJSONSerialization.detectEncoding(utf32beBOM), NSUTF32BigEndianStringEncoding)
    }
    
    func test_detectEncoding_BOM_utf32le() {
        let bom: [UInt8] = [0xFF, 0xFE, 0x00, 0x00]
        let utf32leBOM = NSData(bytes: UnsafePointer<Void>(bom), length: 4)
        XCTAssertEqual(NSJSONSerialization.detectEncoding(utf32leBOM), NSUTF32LittleEndianStringEncoding)
    }
}

//MARK: - JSONDeserialization
extension TestNSJSONSerialization {
    
    var deserializationTests: [(String, () -> ())] {
        return [
            ("test_deserialize_emptyObject", test_deserialize_emptyObject),
            ("test_deserialize_objectWithString", test_deserialize_objectWithString),
        ]
    }
    
    func test_deserialize_emptyObject() {
        let subject = "{}"
        
        do {
            let result = try NSJSONSerialization.JSONObjectWithString(subject) as? [NSObject: AnyObject]
            XCTAssertEqual(result?.keys.count, 0)
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func test_deserialize_objectWithString() {
        let subject = "{ \"hello\": \"world\" }"
        
        do {
            let result = try NSJSONSerialization.JSONObjectWithString(subject) as? [String: String]
            XCTAssertEqual(result?["hello"], "world")
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
}
