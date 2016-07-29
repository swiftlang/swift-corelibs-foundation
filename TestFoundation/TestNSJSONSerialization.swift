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


class TestNSJSONSerialization : XCTestCase {
    
    let supportedEncodings: [String.Encoding] = [
        .utf8,
        .utf16, .utf16BigEndian,
        .utf32LittleEndian, .utf32BigEndian
    ]

    static var allTests: [(String, (TestNSJSONSerialization) -> () throws -> Void)] {
        return JSONObjectWithDataTests
            + deserializationTests
            + isValidJSONObjectTests
            + serializationTests
    }
    
}

//MARK: - JSONObjectWithData
extension TestNSJSONSerialization {

    class var JSONObjectWithDataTests: [(String, (TestNSJSONSerialization) -> () throws -> Void)] {
        return [
            ("test_JSONObjectWithData_emptyObject", test_JSONObjectWithData_emptyObject),
            ("test_JSONObjectWithData_encodingDetection", test_JSONObjectWithData_encodingDetection),
        ]
    }
    
    func test_JSONObjectWithData_emptyObject() {
        let subject = Data(bytes: UnsafeRawPointer([UInt8]([0x7B, 0x7D])), count: 2)
        
        let object = try! JSONSerialization.jsonObject(with: subject, options: []) as? [String:Any]
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
            let result = try? JSONSerialization.jsonObject(with: Data(bytes:UnsafeRawPointer(encoded), count: encoded.count), options: [])
            XCTAssertNotNil(result, description)
        }
    }

}

//MARK: - JSONDeserialization
extension TestNSJSONSerialization {
    
    class var deserializationTests: [(String, (TestNSJSONSerialization) -> () throws -> Void)] {
        return [
            ("test_deserialize_emptyObject", test_deserialize_emptyObject),
            ("test_deserialize_multiStringObject", test_deserialize_multiStringObject),
            
            ("test_deserialize_emptyArray", test_deserialize_emptyArray),
            ("test_deserialize_multiStringArray", test_deserialize_multiStringArray),
            ("test_deserialize_unicodeString", test_deserialize_unicodeString),
            ("test_deserialize_stringWithSpacesAtStart", test_deserialize_stringWithSpacesAtStart),
            
            
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
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let t = try JSONSerialization.jsonObject(with: data, options: [])
            let result = t as? [String: Any]
            XCTAssertEqual(result?.count, 0)
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func test_deserialize_multiStringObject() {
        let subject = "{ \"hello\": \"world\", \"swift\": \"rocks\" }"
        do {
            for encoding in [String.Encoding.utf8, String.Encoding.utf16BigEndian] {
                guard let data = subject.data(using: encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                XCTAssertEqual(result?["hello"] as? String, "world")
                XCTAssertEqual(result?["swift"] as? String, "rocks")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func test_deserialize_stringWithSpacesAtStart(){
        
        let subject = "{\"title\" : \" hello world!!\" }"
        do {
            guard let data = subject.data(using: .utf8) else  {
                XCTFail("Unable to convert string to data")
                return
            }
            let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            XCTAssertEqual(result?["title"] as? String, " hello world!!")
        } catch{
            XCTFail("Error thrown: \(error)")
        }
        
        
    }
    
    //MARK: - Array Deserialization
    func test_deserialize_emptyArray() {
        let subject = "[]"
        
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let result = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
            XCTAssertEqual(result?.count, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_deserialize_multiStringArray() {
        let subject = "[\"hello\", \"swift⚡️\"]"
        
        do {
            for encoding in [String.Encoding.utf8, String.Encoding.utf16BigEndian] {
                guard let data = subject.data(using: encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
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
            for encoding in [String.Encoding.utf16LittleEndian, String.Encoding.utf16BigEndian, String.Encoding.utf32LittleEndian, String.Encoding.utf32BigEndian] {
                guard let data = subject.data(using: encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
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
                guard let data = subject.data(using: encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
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
                guard let data = subject.data(using: encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
                XCTAssertEqual(result?[0] as? Int,        1)
                XCTAssertEqual(result?[1] as? Int,       -1)
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
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let res = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
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
        // DISABLED: changes for SE-128 have apparently changed the result of parsing
        // TODO: Investigate and re-enable test.
        /*
        let subject = "[\"\\u2728\"]"
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let result = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
            XCTAssertEqual(result?[0] as? String, "✨")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        */
    }
    
    func test_deserialize_unicodeSurrogatePairEscapeSequence() {
        // DISABLED: changes for SE-128 have apparently changed the result of parsing
        // TODO: Investigate and re-enable test.
        /*
        let subject = "[\"\\uD834\\udd1E\"]"
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let result = try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
            XCTAssertEqual(result?[0] as? String, "\u{1D11E}")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        */
    }
    
    func test_deserialize_allowFragments() {
        let subject = "3"
        
        do {
            for encoding in supportedEncodings {
                guard let data = subject.data(using: encoding) else {
                    XCTFail("Unable to convert string to data")
                    return
                }
                let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Int
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
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let _ = try JSONSerialization.jsonObject(with: data, options: [])
            XCTFail("Expected error: UnterminatedString")
        } catch {
            // Passing case; the object as unterminated
        }
    }
    
    func test_deserialize_missingObjectKey() {
        let subject = "{3}"
        
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let _ = try JSONSerialization.jsonObject(with: data, options: [])
            XCTFail("Expected error: Missing key for value")
        } catch {
            // Passing case; the key was missing for a value
        }
    }
    
    func test_deserialize_unexpectedEndOfFile() {
        let subject = "{"
        
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let _ = try JSONSerialization.jsonObject(with: data, options: [])
            XCTFail("Expected error: Unexpected end of file")
        } catch {
            // Success
        }
    }
    
    func test_deserialize_invalidValueInObject() {
        let subject = "{\"error\":}"
        
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let _ = try JSONSerialization.jsonObject(with: data, options: [])
            XCTFail("Expected error: Invalid value")
        } catch {
            // Passing case; the value is invalid
        }
    }
    
    func test_deserialize_invalidValueIncorrectSeparatorInObject() {
        let subject = "{\"missing\";}"
        
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let _ = try JSONSerialization.jsonObject(with: data, options: [])
            XCTFail("Expected error: Invalid value")
        } catch {
            // passing case the value is invalid
        }
    }
    
    func test_deserialize_invalidValueInArray() {
        let subject = "[,"
        
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let _ = try JSONSerialization.jsonObject(with: data, options: [])
            XCTFail("Expected error: Invalid value")
        } catch {
            // Passing case; the element in the array is missing
        }
    }
    
    func test_deserialize_badlyFormedArray() {
        let subject = "[2b4]"
        
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let _ = try JSONSerialization.jsonObject(with: data, options: [])
            XCTFail("Expected error: Badly formed array")
        } catch {
            // Passing case; the array is malformed
        }
    }
    
    func test_deserialize_invalidEscapeSequence() {
        let subject = "[\"\\e\"]"
        
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let _ = try JSONSerialization.jsonObject(with: data, options: [])
            XCTFail("Expected error: Invalid escape sequence")
        } catch {
            // Passing case; the escape sequence is invalid
        }
    }
    
    func test_deserialize_unicodeMissingTrailingSurrogate() {
        let subject = "[\"\\uD834\"]"
        do {
            guard let data = subject.data(using: .utf8) else {
                XCTFail("Unable to convert string to data")
                return
            }
            let _ = try JSONSerialization.jsonObject(with: data, options: []) as? [String]
            XCTFail("Expected error: Missing Trailing Surrogate")
        } catch {
            // Passing case; the unicode character is malformed
        }
    }

}

// MARK: - isValidJSONObjectTests
extension TestNSJSONSerialization {

    class var isValidJSONObjectTests: [(String, (TestNSJSONSerialization) -> () throws -> Void)] {
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
                NSNumber(value: Int(1)),
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
                            NSNumber(value: Int(1))
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
                    NSNumber(value: Int(0))
                )
            )
        ]
        for testCase in trueJSON {
            XCTAssertTrue(JSONSerialization.isValidJSONObject(testCase))
        }
    }

    func test_isValidJSONObjectFalse() {
        var falseJSON = [Any]()
        falseJSON.append(NSNumber(value: Int(0)))
        falseJSON.append(NSNull())
        falseJSON.append("string")
        falseJSON.append(Array<Any>(arrayLiteral:
            NSNumber(value: Int(1)),
            NSNumber(value: Int(2)),
            NSNumber(value: Int(3)),
            Dictionary<NSNumber, Any>(dictionaryLiteral:
                (
                    NSNumber(value: Int(4)),
                    NSNumber(value: Int(5))
                )
            )
        ))
        
        let one = NSNumber(value: Int(1))
        let two = NSNumber(value: Int(2))
        let divo = NSNumber(value: Double(1) / Double(0))
        falseJSON.append([one, two, divo])
        falseJSON.append([NSNull() : NSNumber(value: Int(1))])
        falseJSON.append(Array<Any>(arrayLiteral:
            Array<Any>(arrayLiteral:
                Array<Any>(arrayLiteral:
                    Dictionary<NSNumber, Any>(dictionaryLiteral:
                        (
                            NSNumber(value: Int(1)),
                            NSNumber(value: Int(2))
                        )
                    )
                )
            )
        ))
        
        for testCase in falseJSON {
            XCTAssertFalse(JSONSerialization.isValidJSONObject(testCase))
        }
    }

}

// MARK: - serializationTests
extension TestNSJSONSerialization {

    class var serializationTests: [(String, (TestNSJSONSerialization) -> () throws -> Void)] {
        return [
            ("test_serialize_emptyObject", test_serialize_emptyObject),
            ("test_serialize_null", test_serialize_null),
            ("test_serialize_complexObject", test_serialize_complexObject),
            ("test_nested_array", test_nested_array),
            ("test_nested_dictionary", test_nested_dictionary),
            ("test_serialize_number", test_serialize_number),
            ("test_serialize_stringEscaping", test_serialize_stringEscaping),
            ("test_serialize_invalid_json", test_serialize_invalid_json),
            ("test_jsonReadingOffTheEndOfBuffers", test_jsonReadingOffTheEndOfBuffers),
            ("test_jsonObjectToOutputStreamBuffer", test_jsonObjectToOutputStreamBuffer),
            ("test_jsonObjectToOutputStreamFile", test_jsonObjectToOutputStreamFile),
            ("test_invalidJsonObjectToStreamBuffer", test_invalidJsonObjectToStreamBuffer),
            ("test_jsonObjectToOutputStreamInsufficeintBuffer", test_jsonObjectToOutputStreamInsufficeintBuffer),
        ]
    }

    func trySerialize(_ obj: AnyObject) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: obj, options: [])
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Unable to create string")
            return ""
        }
        return string
    }

    func test_serialize_emptyObject() {
        let dict1 = [String: Any]().bridge()
        XCTAssertEqual(try trySerialize(dict1), "{}")
            
        let dict2 = [String: NSNumber]().bridge()
        XCTAssertEqual(try trySerialize(dict2), "{}")

        let dict3 = [String: String]().bridge()
        XCTAssertEqual(try trySerialize(dict3), "{}")

        let array1 = [String]().bridge()
        XCTAssertEqual(try trySerialize(array1), "[]")

        let array2 = [NSNumber]().bridge()
        XCTAssertEqual(try trySerialize(array2), "[]")
    }
    
    func test_serialize_null() {
        let arr = [NSNull()].bridge()
        XCTAssertEqual(try trySerialize(arr), "[null]")
        
        let dict = ["a":NSNull()].bridge()
        XCTAssertEqual(try trySerialize(dict), "{\"a\":null}")
        
        let arr2 = [NSNull(), NSNull(), NSNull()].bridge()
        XCTAssertEqual(try trySerialize(arr2), "[null,null,null]")
        
        let dict2 = [["a":NSNull()], ["b":NSNull()], ["c":NSNull()]].bridge()
        XCTAssertEqual(try trySerialize(dict2), "[{\"a\":null},{\"b\":null},{\"c\":null}]")
    }

    func test_serialize_complexObject() {
        let jsonDict = ["a": 4].bridge()
        XCTAssertEqual(try trySerialize(jsonDict), "{\"a\":4}")

        let jsonArr = [1, 2, 3, 4].bridge()
        XCTAssertEqual(try trySerialize(jsonArr), "[1,2,3,4]")

        let jsonDict2 = ["a": [1,2]].bridge()
        XCTAssertEqual(try trySerialize(jsonDict2), "{\"a\":[1,2]}")

        let jsonArr2 = ["a", "b", "c"].bridge()
        XCTAssertEqual(try trySerialize(jsonArr2), "[\"a\",\"b\",\"c\"]")
        
        let jsonArr3 = [["a":1],["b":2]].bridge()
        XCTAssertEqual(try trySerialize(jsonArr3), "[{\"a\":1},{\"b\":2}]")
        
        let jsonArr4 = [["a":NSNull()],["b":NSNull()]].bridge()
        XCTAssertEqual(try trySerialize(jsonArr4), "[{\"a\":null},{\"b\":null}]")
    }
    
    func test_nested_array() {
        var arr = ["a"].bridge()
        XCTAssertEqual(try trySerialize(arr), "[\"a\"]")
        
        arr = [["b"]].bridge()
        XCTAssertEqual(try trySerialize(arr), "[[\"b\"]]")
        
        arr = [[["c"]]].bridge()
        XCTAssertEqual(try trySerialize(arr), "[[[\"c\"]]]")
        
        arr = [[[["d"]]]].bridge()
        XCTAssertEqual(try trySerialize(arr), "[[[[\"d\"]]]]")
    }
    
    func test_nested_dictionary() {
        var dict = ["a":1].bridge()
        XCTAssertEqual(try trySerialize(dict), "{\"a\":1}")
        
        dict = ["a":["b":1]].bridge()
        XCTAssertEqual(try trySerialize(dict), "{\"a\":{\"b\":1}}")
        
        dict = ["a":["b":["c":1]]].bridge()
        XCTAssertEqual(try trySerialize(dict), "{\"a\":{\"b\":{\"c\":1}}}")
        
        dict = ["a":["b":["c":["d":1]]]].bridge()
        XCTAssertEqual(try trySerialize(dict), "{\"a\":{\"b\":{\"c\":{\"d\":1}}}}")
    }
    
    func test_serialize_number() {
        var json = [1, 1.1, 0, -2].bridge()
        XCTAssertEqual(try trySerialize(json), "[1,1.1,0,-2]")
        
        // Cannot generate "true"/"false" currently
        json = [NSNumber(value:false),NSNumber(value:true)].bridge()
        XCTAssertEqual(try trySerialize(json), "[0,1]")
    }
    
    func test_serialize_stringEscaping() {
        var json = ["foo"].bridge()
        XCTAssertEqual(try trySerialize(json), "[\"foo\"]")

        json = ["a\0"].bridge()
        XCTAssertEqual(try trySerialize(json), "[\"a\\u0000\"]")
            
        json = ["b\\"].bridge()
        XCTAssertEqual(try trySerialize(json), "[\"b\\\\\"]")
        
        json = ["c\t"].bridge()
        XCTAssertEqual(try trySerialize(json), "[\"c\\t\"]")
        
        json = ["d\n"].bridge()
        XCTAssertEqual(try trySerialize(json), "[\"d\\n\"]")
        
        json = ["e\r"].bridge()
        XCTAssertEqual(try trySerialize(json), "[\"e\\r\"]")
        
        json = ["f\""].bridge()
        XCTAssertEqual(try trySerialize(json), "[\"f\\\"\"]")
        
        json = ["g\'"].bridge()
        XCTAssertEqual(try trySerialize(json), "[\"g\'\"]")
        
        json = ["h\u{7}"].bridge()
        XCTAssertEqual(try trySerialize(json), "[\"h\\u0007\"]")
        
        json = ["i\u{1f}"].bridge()
        XCTAssertEqual(try trySerialize(json), "[\"i\\u001f\"]")
    }

    func test_serialize_invalid_json() {
        let str = "Invalid JSON".bridge()
        do {
            let _ = try trySerialize(str)
            XCTFail("Top-level JSON object cannot be string")
        } catch {
            // should get here
        }
        
        let double = NSNumber(value: Double(1.2))
        do {
            let _ = try trySerialize(double)
            XCTFail("Top-level JSON object cannot be double")
        } catch {
            // should get here
        }
        
        let dict = [NSNumber(value: Double(1.2)):"a"].bridge()
        do {
            let _ = try trySerialize(dict)
            XCTFail("Dictionary keys must be strings")
        } catch {
            // should get here
        }
    }
    
    func test_jsonReadingOffTheEndOfBuffers() {
        let data = "12345679".data(using: .utf8)!
        do {
            let res = try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Any in
                let slice = Data(bytesNoCopy: UnsafeMutablePointer(mutating: bytes), count: 1, deallocator: .none)
                return try JSONSerialization.jsonObject(with: slice, options: .allowFragments)
            }
            if let num = res as? Int {
                XCTAssertEqual(1, num) // the slice truncation should only parse 1 byte!
            } else {
                XCTFail("expected an integer but got a \(res)")
            }
        } catch {
            XCTFail("Unknow json decoding failure")
        }
    }
    
    func test_jsonObjectToOutputStreamBuffer(){
        let dict = ["a":["b":1]]
        do {
            let buffer = Array<UInt8>(repeating: 0, count: 20)
            let outputStream = NSOutputStream(toBuffer: UnsafeMutablePointer(mutating: buffer), capacity: 20)
            outputStream.open()
            let result = try JSONSerialization.writeJSONObject(dict.bridge(), toStream: outputStream, options: [])
            outputStream.close()
            if(result > -1) {
                XCTAssertEqual(NSString(bytes: buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue), "{\"a\":{\"b\":1}}")
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func test_jsonObjectToOutputStreamFile() {
        let dict = ["a":["b":1]]
        do {
            let filePath = createTestFile("TestFileOut.txt",_contents: Data(capacity: 128)!)
            if filePath != nil {
                let outputStream = NSOutputStream(toFileAtPath: filePath!, append: true)
                outputStream?.open()
                let result = try JSONSerialization.writeJSONObject(dict.bridge(), toStream: outputStream!, options: [])
                outputStream?.close()
                if(result > -1) {
                    let fileStream: InputStream = InputStream(fileAtPath: filePath!)!
                    var buffer = [UInt8](repeating: 0, count: 20)
                    fileStream.open()
                    if fileStream.hasBytesAvailable {
                        let resultRead: Int = fileStream.read(&buffer, maxLength: buffer.count)
                        fileStream.close()
                        if(resultRead > -1){
                            XCTAssertEqual(NSString(bytes: buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue), "{\"a\":{\"b\":1}}")
                        }
                    }
                    removeTestFile(filePath!)
                } else {
                    XCTFail("Unable to create temp file")
                }
            }
        } catch {
            XCTFail("Error thrown: \(error)")
        }
    }
    
    func test_jsonObjectToOutputStreamInsufficeintBuffer() {
        let dict = ["a":["b":1]]
        let buffer = Array<UInt8>(repeating: 0, count: 10)
        let outputStream = NSOutputStream(toBuffer: UnsafeMutablePointer(mutating: buffer), capacity: 20)
        outputStream.open()
        do {
            let result = try JSONSerialization.writeJSONObject(dict.bridge(), toStream: outputStream, options: [])
            outputStream.close()
            if(result > -1) {
                XCTAssertNotEqual(NSString(bytes: buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue), "{\"a\":{\"b\":1}}")
            }
        } catch {
            XCTFail("Error occurred while writing to stream")
        }
    }
    
    func test_invalidJsonObjectToStreamBuffer() {
        let str = "Invalid JSON"
        let buffer = Array<UInt8>(repeating: 0, count: 10)
        let outputStream = NSOutputStream(toBuffer: UnsafeMutablePointer(mutating: buffer), capacity: 20)
        outputStream.open()
        XCTAssertThrowsError(try JSONSerialization.writeJSONObject(str.bridge(), toStream: outputStream, options: []))
    }
    
    private func createTestFile(_ path: String,_contents: Data) -> String? {
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
