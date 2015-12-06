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

//MARK: - JSONDeserialization
extension TestNSJSONSerialization {
    
    var deserializationTests: [(String, () -> ())] {
        return [
            ("test_detectEncoding", test_detectEncoding),
            
            ("test_deserialize_emptyObject", test_deserialize_emptyObject),
            ("test_deserialize_multiStringObject", test_deserialize_multiStringObject),
            
            ("test_deserialize_emptyArray", test_deserialize_emptyArray),
            ("test_deserialize_multiStringArray", test_deserialize_multiStringArray),
            
            ("test_deserialize_values", test_deserialize_values),
            ("test_deserialize_numbers", test_deserialize_numbers),
            
            ("test_deserialize_unterminatedObjectString", test_deserialize_unterminatedObjectString),
            ("test_deserialize_missingObjectKey", test_deserialize_missingObjectKey),
            ("test_deserialize_unexpectedEndOfFile", test_deserialize_unexpectedEndOfFile),
            ("test_deserialize_invalidValueInObject", test_deserialize_invalidValueInObject),
            ("test_deserialize_invalidValueInArray", test_deserialize_invalidValueInArray),
            ("test_deserialize_badlyFormedArray", test_deserialize_badlyFormedArray),
        ]
    }
    
    //MARK: - Encoding Detection
    func test_detectEncoding() {
        let subjects: [(NSStringEncoding, [UInt8], String)] = [
            (NSUTF8StringEncoding, [], "Empty String"),
            
            // BOM Detection
            (NSUTF8StringEncoding, [0xEF, 0xBB, 0xBF], "UTF-8 BOM"),
            (NSUTF16BigEndianStringEncoding, [0xFE, 0xFF], "UTF-16BE BOM"),
            (NSUTF16LittleEndianStringEncoding, [0xFF, 0xFE], "UTF-16LE BOM"),
            (NSUTF32BigEndianStringEncoding, [0x00, 0x00, 0xFE, 0xFF], "UTF-32BE BOM"),
            (NSUTF32LittleEndianStringEncoding, [0xFF, 0xFE, 0x00, 0x00], "UTF-32LE BOM"),
            
            // RFC4627 Detection
            (NSUTF8StringEncoding, [0x7B, 0x7D], "{} UTF-8"),
            (NSUTF16BigEndianStringEncoding, [0x0, 0x7B, 0x0, 0x7D], "{} UTF-16BE"),
            (NSUTF16LittleEndianStringEncoding, [0x7B, 0x0, 0x7D, 0x0], "{} UTF-16LE"),
            (NSUTF32BigEndianStringEncoding, [0x0, 0x0, 0x0, 0x7B, 0x0, 0x0, 0x0, 0x7D], "{} UTF-32BE"),
            (NSUTF32LittleEndianStringEncoding, [0x7B, 0x0, 0x0, 0x0, 0x7D, 0x0, 0x0, 0x0], "{} UTF-32LE"),
            
            // Single Characters
            (NSUTF8StringEncoding, [0x33], "'3' UTF-8"),
            (NSUTF16BigEndianStringEncoding, [0x0, 0x33], "'3' UTF-16BE"),
            (NSUTF16LittleEndianStringEncoding, [0x33, 0x0], "'3' UTF-16LE"),
        ]

        for (encoding, encoded, message) in subjects {
            XCTAssertEqual(NSJSONSerialization.detectEncoding(NSData(bytes: UnsafePointer<Void>(encoded), length: encoded.count)), encoding, message)
        }
    }
    
    //MARK: - Object Deserialization
    func test_deserialize_emptyObject() {
        let subject = "{}"
        
        do {
            let result = try NSJSONSerialization.JSONObjectWithString(subject) as? [NSObject: AnyObject]
            XCTAssertEqual(result?.keys.count, 0)
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func test_deserialize_multiStringObject() {
        let subject = "{ \"hello\": \"world\", \"swift\": \"rocks\" }"
        
        do {
            let result = try NSJSONSerialization.JSONObjectWithString(subject) as? [String: String]
            XCTAssertEqual(result?["hello"], "world")
            XCTAssertEqual(result?["swift"], "rocks")
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    //MARK: - Array Deserialization
    func test_deserialize_emptyArray() {
        let subject = "[]"
        
        do {
            let result = try NSJSONSerialization.JSONObjectWithString(subject) as? [String]
            XCTAssertEqual(result?.count, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_multiStringArray() {
        let subject = "[\"hello\", \"swift⚡️\"]"
        
        do {
            let result = try NSJSONSerialization.JSONObjectWithString(subject) as? [String]
            XCTAssertEqual(result?[0], "hello")
            XCTAssertEqual(result?[1], "swift⚡️")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    //MARK: - Value parsing
    func test_deserialize_values() {
        let subject = "[true, false, \"hello\", null, {}, []]"
        
        do {
            let result = try NSJSONSerialization.JSONObjectWithString(subject) as? [AnyObject]
            XCTAssertEqual(result?[0] as? Bool, true)
            XCTAssertEqual(result?[1] as? Bool, false)
            XCTAssertEqual(result?[2] as? String, "hello")
            XCTAssertNotNil(result?[3] as? NSNull)
            XCTAssertNotNil(result?[4] as? [String:String])
            XCTAssertNotNil(result?[5] as? [String])
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    //MARK: - Number parsing
    func test_deserialize_numbers() {
        let subject = "[1, -1, 1.3, -1.3, 1e3, 1E-3]"
        
        do {
            let result = try NSJSONSerialization.JSONObjectWithString(subject) as? [Double]
            XCTAssertEqual(result?[0],     1)
            XCTAssertEqual(result?[1],    -1)
            XCTAssertEqual(result?[2],   1.3)
            XCTAssertEqual(result?[3],  -1.3)
            XCTAssertEqual(result?[4],  1000)
            XCTAssertEqual(result?[5], 0.001)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    //MARK: - Parsing Errors
    func test_deserialize_unterminatedObjectString() {
        let subject = "{\"}"
        
        do {
            try NSJSONSerialization.JSONObjectWithString(subject)
            XCTFail("Expected error: UnterminatedString")
        } catch let NSJSONSerializationError.UnterminatedString(index){
            XCTAssertEqual(index, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_missingObjectKey() {
        let subject = "{3}"
        
        do {
            try NSJSONSerialization.JSONObjectWithString(subject)
            XCTFail("Expected error: Missing key for value")
        } catch let NSJSONSerializationError.MissingObjectKey(index){
            XCTAssertEqual(index, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_unexpectedEndOfFile() {
        let subject = "{"
        
        do {
            try NSJSONSerialization.JSONObjectWithString(subject)
            XCTFail("Expected error: Unexpected end of file")
        } catch NSJSONSerializationError.UnexpectedEndOfFile {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_invalidValueInObject() {
        let subject = "{\"error\":}"
        
        do {
            try NSJSONSerialization.JSONObjectWithString(subject)
            XCTFail("Expected error: Invalid value")
        } catch let NSJSONSerializationError.InvalidValue(index){
            XCTAssertEqual(index, 9)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_invalidValueInArray() {
        let subject = "[,"
        
        do {
            try NSJSONSerialization.JSONObjectWithString(subject)
            XCTFail("Expected error: Invalid value")
        } catch let NSJSONSerializationError.InvalidValue(index){
            XCTAssertEqual(index, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_badlyFormedArray() {
        let subject = "[2b4]"
        
        do {
            try NSJSONSerialization.JSONObjectWithString(subject)
            XCTFail("Expected error: Badly formed array")
        } catch let NSJSONSerializationError.BadlyFormedArray(index){
            XCTAssertEqual(index, 2)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
