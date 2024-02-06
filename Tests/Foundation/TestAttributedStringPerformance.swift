//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
        @testable import SwiftFoundation
    #else
        @testable import Foundation
    #endif
#endif

/// Performance tests for `AttributedString` and its associated objects
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
final class TestAttributedStringPerformance: XCTestCase {
    
    /// Set to true to record a baseline for equivalent operations on `NSAttributedString`
    static let runWithNSAttributedString = false
    
    func createLongString() -> AttributedString {
        var str = AttributedString(String(repeating: "a", count: 10000), attributes: AttributeContainer().testInt(1))
        str += AttributedString(String(repeating: "b", count: 10000), attributes: AttributeContainer().testInt(2))
        str += AttributedString(String(repeating: "c", count: 10000), attributes: AttributeContainer().testInt(3))
        return str
    }
    
    func createManyAttributesString() -> AttributedString {
        var str = AttributedString("a")
        for i in 0..<10000 {
            str += AttributedString("a", attributes: AttributeContainer().testInt(i))
        }
        return str
    }
    
    func createLongNSString() -> NSMutableAttributedString {
        let str = NSMutableAttributedString(string: String(repeating: "a", count: 10000), attributes: [.testInt: NSNumber(1)])
        str.append(NSMutableAttributedString(string: String(repeating: "b", count: 10000), attributes: [.testInt: NSNumber(2)]))
        str.append(NSMutableAttributedString(string: String(repeating: "c", count: 10000), attributes: [.testInt: NSNumber(3)]))
        return str
    }
    
    func createManyAttributesNSString() -> NSMutableAttributedString {
        let str = NSMutableAttributedString(string: "a")
        for i in 0..<10000 {
            str.append(NSAttributedString(string: "a", attributes: [.testInt: NSNumber(value: i)]))
        }
        return str
    }
    
    // MARK: - String Manipulation
    
    func testInsertIntoLongString() {
        var str = createLongString()
        let idx = str.characters.index(str.startIndex, offsetBy: str.characters.count / 2)
        let toInsert = AttributedString(String(repeating: "c", count: str.characters.count))
        
        let strNS = createLongNSString()
        let idxNS = str.characters.count / 2
        let toInsertNS = NSAttributedString(string: String(repeating: "c", count: str.characters.count))
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.insert(toInsertNS, at: idxNS)
            } else {
                str.insert(toInsert, at: idx)
            }
        }
    }
    
    func testReplaceSubrangeOfLongString() {
        var str = createLongString()
        let start = str.characters.index(str.startIndex, offsetBy: str.characters.count / 2)
        let range = start ... str.characters.index(start, offsetBy: 10)
        let toInsert = AttributedString(String(repeating: "d", count: str.characters.count / 2), attributes: AttributeContainer().testDouble(2.5))
        
        let strNS = createLongNSString()
        let startNS = strNS.string.count / 2
        let rangeNS = NSRange(location: startNS, length: 10)
        let toInsertNS = NSAttributedString(string: String(repeating: "d", count: strNS.string.count / 2), attributes: [.testDouble: NSNumber(value: 2.5)])
        
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.replaceCharacters(in: rangeNS, with: toInsertNS)
            } else {
                str.replaceSubrange(range, with: toInsert)
            }
        }
    }
    
    // MARK: - Attribute Manipulation
    
    func testSetAttribute() {
        var str = createManyAttributesString()
        let strNS = createManyAttributesNSString()
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.addAttributes([.testDouble: NSNumber(value: 1.5)], range: NSRange(location: 0, length: strNS.string.count))
            } else {
                str.testDouble = 1.5
            }
        }
    }
    
    func testGetAttribute() {
        let str = createManyAttributesString()
        let strNS = createManyAttributesNSString()
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.enumerateAttribute(.testDouble, in: NSRange(location: 0, length: strNS.string.count), options: []) { (attr, range, pointer) in
                    let _ = attr
                }
            } else {
                let _ = str.testDouble
            }
        }
    }
    
    func testSetAttributeSubrange() {
        var str = createManyAttributesString()
        let range = str.characters.index(str.startIndex, offsetBy: str.characters.count / 2)...
        
        let strNS = createManyAttributesNSString()
        let rangeNS = NSRange(location: 0, length: str.characters.count / 2)
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.addAttributes([.testDouble: NSNumber(value: 1.5)], range: rangeNS)
            } else {
                str[range].testDouble = 1.5
            }
        }
    }
    
    func testGetAttributeSubrange() {
        let str = createManyAttributesString()
        let range = str.characters.index(str.startIndex, offsetBy: str.characters.count / 2)...
        
        let strNS = createManyAttributesNSString()
        let rangeNS = NSRange(location: 0, length: str.characters.count / 2)
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.enumerateAttribute(.testDouble, in: rangeNS, options: []) { (attr, range, pointer) in
                    let _ = attr
                }
            } else {
                let _ = str[range].testDouble
            }
        }
    }
    
    func testModifyAttributes() {
        let str = createManyAttributesString()
        let strNS = createManyAttributesNSString()
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.enumerateAttribute(.testInt, in: NSRange(location: 0, length: strNS.string.count), options: []) { (val, range, pointer) in
                    if let value = val as? NSNumber {
                        strNS.addAttributes([.testInt: NSNumber(value: value.intValue + 2)], range: range)
                    }
                }
            } else {
                let _ = str.transformingAttributes(\.testInt) { transformer in
                    if let val = transformer.value {
                        transformer.value = val + 2
                    }
                }
            }
        }
    }
    
    func testReplaceAttributes() {
        var str = createManyAttributesString()
        let old = AttributeContainer().testInt(100)
        let new = AttributeContainer().testDouble(100.5)
        
        let strNS = createManyAttributesNSString()
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.enumerateAttribute(.testInt, in: NSRange(location: 0, length: strNS.string.count), options: []) { (val, range, pointer) in
                    if let value = val as? NSNumber, value == 100 {
                        strNS.removeAttribute(.testInt, range: range)
                        strNS.addAttribute(.testDouble, value: NSNumber(value: 100.5), range: range)
                    }
                }
            } else {
                str.replaceAttributes(old, with: new)
            }
        }
    }
    
    func testMergeMultipleAttributes() throws {
        var str = createManyAttributesString()
        let new = AttributeContainer().testDouble(1.5).testString("test")
        
        let strNS = createManyAttributesNSString()
        let newNS: [NSAttributedString.Key: Any] = [.testDouble: NSNumber(value: 1.5), .testString: "test"]
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.addAttributes(newNS, range: NSRange(location: 0, length: strNS.string.count))
            } else {
                str.mergeAttributes(new)
            }
        }
    }
    
    func testSetMultipleAttributes() throws {
        var str = createManyAttributesString()
        let new = AttributeContainer().testDouble(1.5).testString("test")
        
        let strNS = createManyAttributesNSString()
        let rangeNS = NSRange(location: 0, length: str.characters.count / 2)
        let newNS: [NSAttributedString.Key: Any] = [.testDouble: NSNumber(value: 1.5), .testString: "test"]
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.setAttributes(newNS, range: rangeNS)
            } else {
                str.setAttributes(new)
            }
        }
    }
    
    // MARK: - Attribute Enumeration
    
    func testEnumerateAttributes() {
        let str = createManyAttributesString()
        let strNS = createManyAttributesNSString()
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.enumerateAttributes(in: NSRange(location: 0, length: strNS.string.count), options: []) { (attrs, range, pointer) in
                    
                }
            } else {
                for _ in str.runs {
                    
                }
            }
        }
    }
    
    func testEnumerateAttributesSlice() {
        let str = createManyAttributesString()
        let strNS = createManyAttributesNSString()
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                strNS.enumerateAttribute(.testInt, in: NSRange(location: 0, length: strNS.string.count), options: []) { (val, range, pointer) in
                    
                }
            } else {
                for (_, _) in str.runs[\.testInt] {
                    
                }
            }
        }
    }
    
    // MARK: - NSAS Conversion
    
    func testConvertToNSAS() throws {
        guard !TestAttributedStringPerformance.runWithNSAttributedString else {
            throw XCTSkip("Test disabled for NSAS")
        }
        
        let str = createManyAttributesString()
        
        self.measure {
            let _ = try! NSAttributedString(str, including: AttributeScopes.TestAttributes.self)
        }
    }
    
    func testConvertFromNSAS() throws {
        guard !TestAttributedStringPerformance.runWithNSAttributedString else {
            throw XCTSkip("Test disabled for NSAS")
        }
        
        let str = createManyAttributesString()
        let ns = try NSAttributedString(str, including: AttributeScopes.TestAttributes.self)
        
        self.measure {
            let _ = try! AttributedString(ns, including: AttributeScopes.TestAttributes.self)
        }
    }
    
    // MARK: - Encoding and Decoding
    
    func testEncode() throws {
        struct CodableType: Codable {
            @CodableConfiguration(from: AttributeScopes.TestAttributes.self)
            var str = AttributedString()
        }
        
        let str = createManyAttributesString()
        let codableType = CodableType(str: str)
        let encoder = JSONEncoder()
        
        let ns = createManyAttributesNSString()
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                let _ = try! NSKeyedArchiver.archivedData(withRootObject: ns, requiringSecureCoding: false)
            } else {
                let _ = try! encoder.encode(codableType)
            }
        }
    }
    
    func testDecode() throws {
        struct CodableType: Codable {
            @CodableConfiguration(from: AttributeScopes.TestAttributes.self)
            var str = AttributedString()
        }
        
        let str = createManyAttributesString()
        let codableType = CodableType(str: str)
        let encoder = JSONEncoder()
        let data = try encoder.encode(codableType)
        let decoder = JSONDecoder()
        
        let dataNS: Data
        if TestAttributedStringPerformance.runWithNSAttributedString {
            let ns = createManyAttributesNSString()
            dataNS = try NSKeyedArchiver.archivedData(withRootObject: ns, requiringSecureCoding: false)
        } else {
            dataNS = Data()
        }
        
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                let _ = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataNS)
            } else {
                let _ = try! decoder.decode(CodableType.self, from: data)
            }
        }
    }
    
    // MARK: - Other
    
    func testCreateLongString() {
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                let _ = createLongNSString()
            } else {
                let _ = createLongString()
            }
        }
    }
    
    func testCreateManyAttributesString() {
        self.measure {
            if TestAttributedStringPerformance.runWithNSAttributedString {
                let _ = createManyAttributesNSString()
            } else {
                let _ = createManyAttributesString()
            }
        }
    }
    
    func testEquality() throws {
        guard !TestAttributedStringPerformance.runWithNSAttributedString else {
            throw XCTSkip("Test disabled for NSAS")
        }
        
        let str = createManyAttributesString()
        let str2 = createManyAttributesString()
        
        self.measure {
            _ = str == str2
        }
    }
    
    func testSubstringEquality() throws {
        guard !TestAttributedStringPerformance.runWithNSAttributedString else {
            throw XCTSkip("Test disabled for NSAS")
        }
        
        let str = createManyAttributesString()
        let str2 = createManyAttributesString()
        let range = str.characters.index(str.startIndex, offsetBy: str.characters.count / 2)...
        let substring = str[range]
        let substring2 = str2[range]
        
        self.measure {
            _ = substring == substring2
        }
    }
    
    static var allTests: [(String, (TestAttributedStringPerformance) -> () throws -> Void)] {
        return [
            ("testInsertIntoLongString", testInsertIntoLongString),
            ("testReplaceSubrangeOfLongString", testReplaceSubrangeOfLongString),
            ("testSetAttribute", testSetAttribute),
            ("testGetAttribute", testGetAttribute),
            ("testSetAttributeSubrange", testSetAttributeSubrange),
            ("testGetAttributeSubrange", testGetAttributeSubrange),
            ("testModifyAttributes", testModifyAttributes),
            ("testReplaceAttributes", testReplaceAttributes),
            ("testMergeMultipleAttributes", testMergeMultipleAttributes),
            ("testSetMultipleAttributes", testSetMultipleAttributes),
            ("testEnumerateAttributes", testEnumerateAttributes),
            ("testEnumerateAttributesSlice", testEnumerateAttributesSlice),
            ("testConvertToNSAS", testConvertToNSAS),
            ("testConvertFromNSAS", testConvertFromNSAS),
            ("testEncode", testEncode),
            ("testDecode", testDecode),
            ("testCreateLongString", testCreateLongString),
            ("testCreateManyAttributesString", testCreateManyAttributesString),
            ("testEquality", testEquality),
            ("testSubstringEquality", testSubstringEquality)
        ]
    }
}
