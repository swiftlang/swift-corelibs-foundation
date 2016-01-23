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


class TestNSJSONSerialization : XCTestCase {
    
    let supportedEncodings = [
        NSUTF8StringEncoding,
        NSUTF16LittleEndianStringEncoding, NSUTF16BigEndianStringEncoding,
        NSUTF32LittleEndianStringEncoding, NSUTF32BigEndianStringEncoding
    ]

    var allTests : [(String, () throws -> Void)] {
        return JSONObjectWithDataTests
            + deserializationTests
            + isValidJSONObjectTests
    }
    
}

//MARK: - JSONObjectWithData
extension TestNSJSONSerialization {

    var JSONObjectWithDataTests: [(String, () throws -> Void)] {
        return [
            ("test_JSONObjectWithData_emptyObject", test_JSONObjectWithData_emptyObject),
            ("test_JSONObjectWithData_encodingDetection", test_JSONObjectWithData_encodingDetection),
        ]
    }
    
    func test_JSONObjectWithData_emptyObject() {
        let subject = NSData(bytes: UnsafePointer<Void>([UInt8]([0x7B, 0x7D])), length: 2)
        
        let object = try! NSJSONSerialization.JSONObjectWithData(subject, options: []) as? [String:Any]
        XCTAssertEqual(object?.count, 0)
    }
    
    //MARK: - Encoding Detection
    func test_JSONObjectWithData_encodingDetection() {
        let subjects: [(String, [UInt8])] = [
            // BOM Detection
            ("{} UTF-8 w/BOM", [0xEF, 0xBB, 0xBF, 0x7B, 0x7D]),
            ("{} UTF-16BE w/BOM", [0xFE, 0xFF, 0x0, 0x7B, 0x0, 0x7D]),
            ("{} UTF-16LE w/BOM", [0xFF, 0xFE, 0x7B, 0x0, 0x7D, 0x0]),
            ("{} UTF-32BE w/BOM", [0x00, 0x00, 0xFE, 0xFF, 0x0, 0x0, 0x0, 0x7B, 0x0, 0x0, 0x0, 0x7D]),
            ("{} UTF-32LE w/BOM", [0xFF, 0xFE, 0x00, 0x00, 0x7B, 0x0, 0x0, 0x0, 0x7D, 0x0, 0x0, 0x0]),
            
            // RFC4627 Detection
            ("{} UTF-8", [0x7B, 0x7D]),
            ("{} UTF-16BE", [0x0, 0x7B, 0x0, 0x7D]),
            ("{} UTF-16LE", [0x7B, 0x0, 0x7D, 0x0]),
            ("{} UTF-32BE", [0x0, 0x0, 0x0, 0x7B, 0x0, 0x0, 0x0, 0x7D]),
            ("{} UTF-32LE", [0x7B, 0x0, 0x0, 0x0, 0x7D, 0x0, 0x0, 0x0]),
            
            //            // Single Characters
            //            ("'3' UTF-8", [0x33]),
            //            ("'3' UTF-16BE", [0x0, 0x33]),
            //            ("'3' UTF-16LE", [0x33, 0x0]),
        ]
        
        for (description, encoded) in subjects {
            let result = try? NSJSONSerialization.JSONObjectWithData(NSData(bytes:UnsafePointer<Void>(encoded), length: encoded.count), options: [])
            XCTAssertNotNil(result, description)
        }
    }

}

//MARK: - JSONDeserialization
extension TestNSJSONSerialization {
    
    var deserializationTests: [(String, () throws -> Void)] {
        return [
            ("test_deserialize_emptyObject", test_deserialize_emptyObject),
            ("test_deserialize_multiStringObject", test_deserialize_multiStringObject),
            
            ("test_deserialize_emptyArray", test_deserialize_emptyArray),
            ("test_deserialize_multiStringArray", test_deserialize_multiStringArray),
            ("test_deserialize_unicodeString", test_deserialize_unicodeString),
            
            
            ("test_deserialize_values", test_deserialize_values),
            ("test_deserialize_numbers", test_deserialize_numbers),
            
            ("test_deserialize_simpleEscapeSequences", test_deserialize_simpleEscapeSequences),
            ("test_deserialize_unicodeEscapeSequence", test_deserialize_unicodeEscapeSequence),
            ("test_deserialize_unicodeSurrogatePairEscapeSequence", test_deserialize_unicodeSurrogatePairEscapeSequence),
            // Disabled due to uninitialized memory SR-606
            // ("test_deserialize_allowFragments", test_deserialize_allowFragments),
            
            ("test_deserialize_unterminatedObjectString", test_deserialize_unterminatedObjectString),
            ("test_deserialize_missingObjectKey", test_deserialize_missingObjectKey),
            ("test_deserialize_unexpectedEndOfFile", test_deserialize_unexpectedEndOfFile),
            ("test_deserialize_invalidValueInObject", test_deserialize_invalidValueInObject),
            ("test_deserialize_invalidValueIncorrectSeparatorInObject", test_deserialize_invalidValueIncorrectSeparatorInObject),
            ("test_deserialize_invalidValueInArray", test_deserialize_invalidValueInArray),
            ("test_deserialize_badlyFormedArray", test_deserialize_badlyFormedArray),
            ("test_deserialize_invalidEscapeSequence", test_deserialize_invalidEscapeSequence),
            ("test_deserialize_unicodeMissingTrailingSurrogate", test_deserialize_unicodeMissingTrailingSurrogate),
        ]
    }
    
    //MARK: - Object Deserialization
    func test_deserialize_emptyObject() {
        let subject = "{}"
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let t = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            let result = t as? [String: Any]
            XCTAssertEqual(result?.count, 0)
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func test_deserialize_multiStringObject() {
        let subject = "{ \"hello\": \"world\", \"swift\": \"rocks\" }"
        do {
            for encoding in [NSUTF8StringEncoding, NSUTF16BigEndianStringEncoding] {
                guard let data = subject.bridge().dataUsingEncoding(encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: Any]
                XCTAssertEqual(result?["hello"] as? String, "world")
                XCTAssertEqual(result?["swift"] as? String, "rocks")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    //MARK: - Array Deserialization
    func test_deserialize_emptyArray() {
        let subject = "[]"
        
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [Any]
            XCTAssertEqual(result?.count, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_multiStringArray() {
        let subject = "[\"hello\", \"swift⚡️\"]"
        
        do {
            for encoding in [NSUTF8StringEncoding, NSUTF16BigEndianStringEncoding] {
                guard let data = subject.bridge().dataUsingEncoding(encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [Any]
                XCTAssertEqual(result?[0] as? String, "hello")
                XCTAssertEqual(result?[1] as? String, "swift⚡️")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_unicodeString() {
        /// Ģ has the same LSB as quotation mark " (U+0022) so test guarding against this case
        let subject = "[\"unicode\", \"Ģ\", \"😢\"]"
        
        do {
            for encoding in [NSUTF16LittleEndianStringEncoding, NSUTF16BigEndianStringEncoding, NSUTF32LittleEndianStringEncoding, NSUTF32BigEndianStringEncoding] {
                guard let data = subject.bridge().dataUsingEncoding(encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [Any]
                XCTAssertEqual(result?[0] as? String, "unicode")
                XCTAssertEqual(result?[1] as? String, "Ģ")
                XCTAssertEqual(result?[2] as? String, "😢")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    //MARK: - Value parsing
    func test_deserialize_values() {
        let subject = "[true, false, \"hello\", null, {}, []]"
        
        do {
            for encoding in supportedEncodings {
                guard let data = subject.bridge().dataUsingEncoding(encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [Any]
                XCTAssertEqual(result?[0] as? Bool, true)
                XCTAssertEqual(result?[1] as? Bool, false)
                XCTAssertEqual(result?[2] as? String, "hello")
                XCTAssertNotNil(result?[3] as? NSNull)
                XCTAssertNotNil(result?[4] as? [String:Any])
                XCTAssertNotNil(result?[5] as? [Any])
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    //MARK: - Number parsing
    func test_deserialize_numbers() {
        let subject = "[1, -1, 1.3, -1.3, 1e3, 1E-3]"
        
        do {
            for encoding in supportedEncodings {
                guard let data = subject.bridge().dataUsingEncoding(encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [Any]
                XCTAssertEqual(result?[0] as? Double,     1)
                XCTAssertEqual(result?[1] as? Double,    -1)
                XCTAssertEqual(result?[2] as? Double,   1.3)
                XCTAssertEqual(result?[3] as? Double,  -1.3)
                XCTAssertEqual(result?[4] as? Double,  1000)
                XCTAssertEqual(result?[5] as? Double, 0.001)
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    //MARK: - Escape Sequences
    func test_deserialize_simpleEscapeSequences() {
        let subject = "[\"\\\"\", \"\\\\\", \"\\/\", \"\\b\", \"\\f\", \"\\n\", \"\\r\", \"\\t\"]"
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let res = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [Any]
            let result = res?.flatMap { $0 as? String }
            XCTAssertEqual(result?[0], "\"")
            XCTAssertEqual(result?[1], "\\")
            XCTAssertEqual(result?[2], "/")
            XCTAssertEqual(result?[3], "\u{08}")
            XCTAssertEqual(result?[4], "\u{0C}")
            XCTAssertEqual(result?[5], "\u{0A}")
            XCTAssertEqual(result?[6], "\u{0D}")
            XCTAssertEqual(result?[7], "\u{09}")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_unicodeEscapeSequence() {
        let subject = "[\"\\u2728\"]"
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [Any]
            XCTAssertEqual(result?[0] as? String, "✨")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_unicodeSurrogatePairEscapeSequence() {
        let subject = "[\"\\uD834\\udd1E\"]"
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let result = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [Any]
            XCTAssertEqual(result?[0] as? String, "\u{1D11E}")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_allowFragments() {
        let subject = "3"
        
        do {
            for encoding in supportedEncodings {
                guard let data = subject.bridge().dataUsingEncoding(encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? Double
                XCTAssertEqual(result, 3)
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    //MARK: - Parsing Errors
    func test_deserialize_unterminatedObjectString() {
        let subject = "{\"}"
        
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            try NSJSONSerialization.JSONObjectWithData(data, options: [])
            XCTFail("Expected error: UnterminatedString")
        } catch {
            // Passing case; the object as unterminated
        }
    }
    
    func test_deserialize_missingObjectKey() {
        let subject = "{3}"
        
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            try NSJSONSerialization.JSONObjectWithData(data, options: [])
            XCTFail("Expected error: Missing key for value")
        } catch {
            // Passing case; the key was missing for a value
        }
    }
    
    func test_deserialize_unexpectedEndOfFile() {
        let subject = "{"
        
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            try NSJSONSerialization.JSONObjectWithData(data, options: [])
            XCTFail("Expected error: Unexpected end of file")
        } catch {
            // Success
        }
    }
    
    func test_deserialize_invalidValueInObject() {
        let subject = "{\"error\":}"
        
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            try NSJSONSerialization.JSONObjectWithData(data, options: [])
            XCTFail("Expected error: Invalid value")
        } catch {
            // Passing case; the value is invalid
        }
    }
    
    func test_deserialize_invalidValueIncorrectSeparatorInObject() {
        let subject = "{\"missing\";}"
        
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            try NSJSONSerialization.JSONObjectWithData(data, options: [])
            XCTFail("Expected error: Invalid value")
        } catch {
            // passing case the value is invalid
        }
    }
    
    func test_deserialize_invalidValueInArray() {
        let subject = "[,"
        
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            try NSJSONSerialization.JSONObjectWithData(data, options: [])
            XCTFail("Expected error: Invalid value")
        } catch {
            // Passing case; the element in the array is missing
        }
    }
    
    func test_deserialize_badlyFormedArray() {
        let subject = "[2b4]"
        
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            try NSJSONSerialization.JSONObjectWithData(data, options: [])
            XCTFail("Expected error: Badly formed array")
        } catch {
            // Passing case; the array is malformed
        }
    }
    
    func test_deserialize_invalidEscapeSequence() {
        let subject = "[\"\\e\"]"
        
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            try NSJSONSerialization.JSONObjectWithData(data, options: [])
            XCTFail("Expected error: Invalid escape sequence")
        } catch {
            // Passing case; the escape sequence is invalid
        }
    }
    
    func test_deserialize_unicodeMissingTrailingSurrogate() {
        let subject = "[\"\\uD834\"]"
        do {
            guard let data = subject.bridge().dataUsingEncoding(NSUTF8StringEncoding) else {
                XCTFail("Unable to convert string to data")
                return
            }
            try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String]
            XCTFail("Expected error: Missing Trailing Surrogate")
        } catch {
            // Passing case; the unicode character is malformed
        }
    }

}

// MARK: - isValidJSONObjectTests
extension TestNSJSONSerialization {

    var isValidJSONObjectTests: [(String, () throws -> Void)] {
        return [
            ("test_isValidJSONObjectTrue", test_isValidJSONObjectTrue),
            ("test_isValidJSONObjectFalse", test_isValidJSONObjectFalse),
        ]
    }

    func test_isValidJSONObjectTrue() {
        let trueJSON: [Any] = [
            // []
            Array<Any>(),

            // [1, ["string", [[]]]]
            Array<Any>(arrayLiteral:
                NSNumber(int: 1),
                Array<Any>(arrayLiteral:
                    "string",
                    Array<Any>(arrayLiteral:
                        Array<Any>()
                    )
                )
            ),

            // [NSNull(), ["1" : ["string", 1], "2" : NSNull()]]
            Array<Any>(arrayLiteral:
                NSNull(),
                Dictionary<String, Any>(dictionaryLiteral:
                    (
                        "1",
                        Array<Any>(arrayLiteral:
                            "string",
                            NSNumber(int: 1)
                        )
                    ),
                    (
                        "2",
                        NSNull()
                    )
                )
            ),

            // ["0" : 0]
            Dictionary<String, Any>(dictionaryLiteral:
                (
                    "0",
                    NSNumber(int: 0)
                )
            )
        ]
        for testCase in trueJSON {
            XCTAssertTrue(NSJSONSerialization.isValidJSONObject(testCase))
        }
    }

    func test_isValidJSONObjectFalse() {
        let falseJSON: [Any] = [
            // 0
            NSNumber(int: 0),

            // NSNull()
            NSNull(),

            // "string"
            "string",

            // [1, 2, 3, [4 : 5]]
            Array<Any>(arrayLiteral:
                NSNumber(int: 1),
                NSNumber(int: 2),
                NSNumber(int: 3),
                Dictionary<NSNumber, Any>(dictionaryLiteral:
                    (
                        NSNumber(int: 4),
                        NSNumber(int: 5)
                    )
                )
            ),

            // [1, 2, Infinity]
            [NSNumber(int: 1), NSNumber(int: 2), NSNumber(double: 1 / 0)],

            // [NSNull() : 1]
            [NSNull() : NSNumber(int: 1)],

            // [[[[1 : 2]]]]
            Array<Any>(arrayLiteral:
                Array<Any>(arrayLiteral:
                    Array<Any>(arrayLiteral:
                        Dictionary<NSNumber, Any>(dictionaryLiteral:
                            (
                                NSNumber(int: 1),
                                NSNumber(int: 2)
                            )
                        )
                    )
                )
            )
        ]
        for testCase in falseJSON {
            XCTAssertFalse(NSJSONSerialization.isValidJSONObject(testCase))
        }
    }

}
