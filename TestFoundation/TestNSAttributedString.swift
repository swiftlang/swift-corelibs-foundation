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



class TestNSAttributedString : XCTestCase {
    
    static var allTests: [(String, (TestNSAttributedString) -> () throws -> Void)] {
        return [
            ("test_initWithString", test_initWithString),
            ("test_initWithStringAndAttributes", test_initWithStringAndAttributes),
            ("test_longestEffectiveRange", test_longestEffectiveRange),
            ("test_enumerateAttributeWithName", test_enumerateAttributeWithName),
            ("test_enumerateAttributes", test_enumerateAttributes),
        ]
    }
    
    func test_initWithString() {
        let string = "Lorem 😀 ipsum dolor sit amet, consectetur adipiscing elit. ⌘ Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit. ಠ_ರೃ"
        let attrString = NSAttributedString(string: string)
        XCTAssertEqual(attrString.string, string)
        XCTAssertEqual(attrString.length, string.utf16.count)
        
        var range = NSRange()
        let attrs = attrString.attributes(at: 0, effectiveRange: &range)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, string.utf16.count)
        XCTAssertEqual(attrs.count, 0)

        let attribute = attrString.attribute("invalid", at: 0, effectiveRange: &range)
        XCTAssertNil(attribute)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, string.utf16.count)
    }
    
    func test_initWithStringAndAttributes() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let attributes: [String : AnyObject] = ["attribute.placeholder.key" : "attribute.placeholder.value" as NSString]
        
        let attrString = NSAttributedString(string: string, attributes: attributes)
        XCTAssertEqual(attrString.string, string)
        XCTAssertEqual(attrString.length, string.utf16.count)
        
        var range = NSRange()
        let attrs = attrString.attributes(at: 0, effectiveRange: &range)
        guard let value = attrs["attribute.placeholder.key"] as? String else {
            XCTAssert(false, "attribute value not found")
            return
        }
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, attrString.length)
        XCTAssertEqual(value, "attribute.placeholder.value")

        let invalidAttribute = attrString.attribute("invalid", at: 0, effectiveRange: &range)
        XCTAssertNil(invalidAttribute)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, string.utf16.count)

        let attribute = attrString.attribute("attribute.placeholder.key", at: 0, effectiveRange: &range)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, attrString.length)
        guard let validAttribute = attribute as? NSString else {
            XCTAssert(false, "attribuet not found")
            return
        }
        XCTAssertEqual(validAttribute, "attribute.placeholder.value")
    }
    
    func test_longestEffectiveRange() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        
        let attrKey = "attribute.placeholder.key"
        let attrValue = "attribute.placeholder.value" as NSString
        
        let attrRange1 = NSRange(location: 0, length: 20)
        let attrRange2 = NSRange(location: 18, length: 10)
        
        let attrString = NSMutableAttributedString(string: string)
        attrString.addAttribute(attrKey, value: attrValue, range: attrRange1)
        attrString.addAttribute(attrKey, value: attrValue, range: attrRange2)
        
        let searchRange = NSRange(location: 0, length: attrString.length)
        var range = NSRange()
        
        _ = attrString.attribute(attrKey, at: 0, longestEffectiveRange: &range, in: searchRange)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 28)
        
        _ = attrString.attributes(at: 0, longestEffectiveRange: &range, in: searchRange)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 28)
    }
    
    func test_enumerateAttributeWithName() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        
        let attrKey1 = "attribute.placeholder.key1"
        let attrValue1 = "attribute.placeholder.value1"
        let attrRange1 = NSRange(location: 0, length: 20)
        let attrRange2 = NSRange(location: 18, length: 10)
        
        let attrKey3 = "attribute.placeholder.key3"
        let attrValue3 = "attribute.placeholder.value3"
        let attrRange3 = NSRange(location: 40, length: 5)
        
        let attrString = NSMutableAttributedString(string: string)
        attrString.addAttribute(attrKey1, value: attrValue1, range: attrRange1)
        attrString.addAttribute(attrKey1, value: attrValue1, range: attrRange2)
        attrString.addAttribute(attrKey3, value: attrValue3, range: attrRange3)

        let fullRange = NSRange(location: 0, length: attrString.length)

        var rangeDescriptionString = ""
        var attrDescriptionString = ""
        attrString.enumerateAttribute(attrKey1, in: fullRange) { attr, range, stop in
            rangeDescriptionString.append(self.describe(range: range))
            attrDescriptionString.append(self.describe(attr: attr))
        }
        XCTAssertEqual(rangeDescriptionString, "(0,28)(28,116)")
        XCTAssertEqual(attrDescriptionString, "\(attrValue1)|nil|")
        
        rangeDescriptionString = ""
        attrDescriptionString = ""
        attrString.enumerateAttribute(attrKey1, in: fullRange, options: [.reverse]) { attr, range, stop in
            rangeDescriptionString.append(self.describe(range: range))
            attrDescriptionString.append(self.describe(attr: attr))
        }
        XCTAssertEqual(rangeDescriptionString, "(28,116)(0,28)")
        XCTAssertEqual(attrDescriptionString, "nil|\(attrValue1)|")
        
        rangeDescriptionString = ""
        attrDescriptionString = ""
        attrString.enumerateAttribute(attrKey1, in: fullRange, options: [.longestEffectiveRangeNotRequired]) { attr, range, stop in
            rangeDescriptionString.append(self.describe(range: range))
            attrDescriptionString.append(self.describe(attr: attr))
        }
        XCTAssertEqual(rangeDescriptionString, "(0,28)(28,12)(40,5)(45,99)")
        XCTAssertEqual(attrDescriptionString, "\(attrValue1)|nil|nil|nil|")
    }
    
    func test_enumerateAttributes() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        
        let attrKey1 = "attribute.placeholder.key1"
        let attrValue1 = "attribute.placeholder.value1"
        let attrRange1 = NSRange(location: 0, length: 20)
        
        let attrKey2 = "attribute.placeholder.key2"
        let attrValue2 = "attribute.placeholder.value2"
        let attrRange2 = NSRange(location: 18, length: 10)
        
        let attrKey3 = "attribute.placeholder.key3"
        let attrValue3 = "attribute.placeholder.value3"
        let attrRange3 = NSRange(location: 40, length: 5)
        
        let attrString = NSMutableAttributedString(string: string)
        attrString.addAttribute(attrKey1, value: attrValue1, range: attrRange1)
        attrString.addAttribute(attrKey2, value: attrValue2, range: attrRange2)
        attrString.addAttribute(attrKey3, value: attrValue3, range: attrRange3)
        
        let fullRange = NSRange(location: 0, length: attrString.length)
        
        var rangeDescriptionString = ""
        var attrsDescriptionString = ""
        attrString.enumerateAttributes(in: fullRange) { attrs, range, stop in
            rangeDescriptionString.append(self.describe(range: range))
            attrsDescriptionString.append(self.describe(attrs: attrs))
        }
        XCTAssertEqual(rangeDescriptionString, "(0,18)(18,2)(20,8)(28,12)(40,5)(45,99)")
        XCTAssertEqual(attrsDescriptionString, "[attribute.placeholder.key1:attribute.placeholder.value1][attribute.placeholder.key1:attribute.placeholder.value1,attribute.placeholder.key2:attribute.placeholder.value2][attribute.placeholder.key2:attribute.placeholder.value2][:][attribute.placeholder.key3:attribute.placeholder.value3][:]")
        
        rangeDescriptionString = ""
        attrsDescriptionString = ""
        attrString.enumerateAttributes(in: fullRange, options: [.reverse]) { attrs, range, stop in
            rangeDescriptionString.append(self.describe(range: range))
            attrsDescriptionString.append(self.describe(attrs: attrs))
        }
        XCTAssertEqual(rangeDescriptionString, "(45,99)(40,5)(28,12)(20,8)(18,2)(0,18)")
        XCTAssertEqual(attrsDescriptionString, "[:][attribute.placeholder.key3:attribute.placeholder.value3][:][attribute.placeholder.key2:attribute.placeholder.value2][attribute.placeholder.key1:attribute.placeholder.value1,attribute.placeholder.key2:attribute.placeholder.value2][attribute.placeholder.key1:attribute.placeholder.value1]")
        
        let partialRange = NSRange(location: 0, length: 10)
        
        rangeDescriptionString = ""
        attrsDescriptionString = ""
        attrString.enumerateAttributes(in: partialRange) { attrs, range, stop in
            rangeDescriptionString.append(self.describe(range: range))
            attrsDescriptionString.append(self.describe(attrs: attrs))
        }
        XCTAssertEqual(rangeDescriptionString, "(0,10)")
        XCTAssertEqual(attrsDescriptionString, "[attribute.placeholder.key1:attribute.placeholder.value1]")
        
        rangeDescriptionString = ""
        attrsDescriptionString = ""
        attrString.enumerateAttributes(in: partialRange, options: [.reverse]) { attrs, range, stop in
            rangeDescriptionString.append(self.describe(range: range))
            attrsDescriptionString.append(self.describe(attrs: attrs))
        }
        XCTAssertEqual(rangeDescriptionString, "(0,10)")
        XCTAssertEqual(attrsDescriptionString, "[attribute.placeholder.key1:attribute.placeholder.value1]")
    }
}

fileprivate extension TestNSAttributedString {
    
    fileprivate func describe(range: NSRange) -> String {
        return "(\(range.location),\(range.length))"
    }
    
    fileprivate func describe(attr: Any?) -> String {
        if let attr = attr {
            return "\(attr)" + "|"
        } else {
            return "nil" + "|"
        }
    }
    
    fileprivate func describe(attrs: [String : Any]) -> String {
        if attrs.count > 0 {
            return "[" + attrs.map({ "\($0):\($1)" }).sorted(by: { $0 < $1 }).joined(separator: ",") + "]"
        } else {
            return "[:]"
        }
    }
}

class TestNSMutableAttributedString : XCTestCase {
    
    static var allTests: [(String, (TestNSMutableAttributedString) -> () throws -> Void)] {
        return [
            ("test_initWithString", test_initWithString),
        ]
    }
    
    func test_initWithString() {
        let string = "Lorem 😀 ipsum dolor sit amet, consectetur adipiscing elit. ⌘ Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit. ಠ_ರೃ"
        let mutableAttrString = NSMutableAttributedString(string: string)
        XCTAssertEqual(mutableAttrString.mutableString, NSMutableString(string: string))
    }    
}
