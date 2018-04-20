// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSAttributedString : XCTestCase {
    
    static var allTests: [(String, (TestNSAttributedString) -> () throws -> Void)] {
        return [
            ("test_initWithString", test_initWithString),
            ("test_initWithStringAndAttributes", test_initWithStringAndAttributes),
            ("test_initWithAttributedString", test_initWithAttributedString),
            ("test_attributedSubstring", test_attributedSubstring),
            ("test_longestEffectiveRange", test_longestEffectiveRange),
            ("test_enumerateAttributeWithName", test_enumerateAttributeWithName),
            ("test_enumerateAttributes", test_enumerateAttributes),
            ("test_copy", test_copy),
            ("test_mutableCopy", test_mutableCopy),
            ("test_isEqual", test_isEqual),
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

        let attribute = attrString.attribute(NSAttributedStringKey("invalid"), at: 0, effectiveRange: &range)
        XCTAssertNil(attribute)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, string.utf16.count)
    }
    
    func test_initWithStringAndAttributes() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key") : "attribute.placeholder.value"]
        
        let attrString = NSAttributedString(string: string, attributes: attributes)
        XCTAssertEqual(attrString.string, string)
        XCTAssertEqual(attrString.length, string.utf16.count)
        
        var range = NSRange()
        let attrs = attrString.attributes(at: 0, effectiveRange: &range)
        guard let value = attrs[NSAttributedStringKey("attribute.placeholder.key")] as? String else {
            XCTAssert(false, "attribute value not found")
            return
        }
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, attrString.length)
        XCTAssertEqual(value, "attribute.placeholder.value")

        let invalidAttribute = attrString.attribute(NSAttributedStringKey("invalid"), at: 0, effectiveRange: &range)
        XCTAssertNil(invalidAttribute)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, string.utf16.count)

        let attribute = attrString.attribute(NSAttributedStringKey("attribute.placeholder.key"), at: 0, effectiveRange: &range)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, attrString.length)
        guard let validAttribute = attribute as? NSString else {
            XCTAssert(false, "attribute not found")
            return
        }
        XCTAssertEqual(validAttribute, "attribute.placeholder.value")
    }
    
    func test_initWithAttributedString() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key") : "attribute.placeholder.value"]
        let mutableAttrString = NSMutableAttributedString(string: string, attributes: attributes)

        let initializedAttrString = NSAttributedString(attributedString: mutableAttrString)
        XCTAssertTrue(initializedAttrString.isEqual(to: mutableAttrString))

        // changing the mutable attr string should not affect the initialized attr string
        mutableAttrString.append(mutableAttrString)
        XCTAssertEqual(initializedAttrString.string, string)
    }
    
    func test_attributedSubstring() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key") : "attribute.placeholder.value"]
        
        let attrString = NSAttributedString(string: string, attributes: attributes)
        let subStringRange = NSRange(location: 0, length: 26)
        let substring = attrString.attributedSubstring(from: subStringRange)
        XCTAssertEqual(substring.string, "Lorem ipsum dolor sit amet")
        
        var range = NSRange()
        let attrs = attrString.attributes(at: 0, effectiveRange: &range)
        guard let value = attrs[NSAttributedStringKey("attribute.placeholder.key")] as? String else {
            XCTAssert(false, "attribute value not found")
            return
        }
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, attrString.length)
        XCTAssertEqual(value, "attribute.placeholder.value")
    }
    
    func test_longestEffectiveRange() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        
        let attrKey = NSAttributedStringKey("attribute.placeholder.key")
        let attrValue = "attribute.placeholder.value"
        
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
        
        let attrKey1 = NSAttributedStringKey("attribute.placeholder.key1")
        let attrValue1 = "attribute.placeholder.value1"
        let attrRange1 = NSRange(location: 0, length: 20)
        let attrRange2 = NSRange(location: 18, length: 10)
        
        let attrKey3 = NSAttributedStringKey("attribute.placeholder.key3")
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
        
        let attrKey1 = NSAttributedStringKey("attribute.placeholder.key1")
        let attrValue1 = "attribute.placeholder.value1"
        let attrRange1 = NSRange(location: 0, length: 20)
        
        let attrKey2 = NSAttributedStringKey("attribute.placeholder.key2")
        let attrValue2 = "attribute.placeholder.value2"
        let attrRange2 = NSRange(location: 18, length: 10)
        
        let attrKey3 = NSAttributedStringKey("attribute.placeholder.key3")
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
    
    func test_copy() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key") : "attribute.placeholder.value"]
        
        let originalAttrString = NSAttributedString(string: string, attributes: attributes)
        let attrStringCopy = originalAttrString.copy()
        XCTAssertTrue(attrStringCopy is NSAttributedString)
        XCTAssertFalse(attrStringCopy is NSMutableAttributedString)
        XCTAssertTrue((attrStringCopy as! NSAttributedString).isEqual(to: originalAttrString))

        let originalMutableAttrString = NSMutableAttributedString(string: string, attributes: attributes)
        let mutableAttrStringCopy = originalMutableAttrString.copy()
        XCTAssertTrue(mutableAttrStringCopy is NSAttributedString)
        XCTAssertFalse(mutableAttrStringCopy is NSMutableAttributedString)
        XCTAssertTrue((mutableAttrStringCopy as! NSAttributedString).isEqual(to: originalMutableAttrString))
    }
    
    func test_mutableCopy() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key") : "attribute.placeholder.value"]

        let originalAttrString = NSAttributedString(string: string, attributes: attributes)
        let attrStringMutableCopy = originalAttrString.mutableCopy()
        XCTAssertTrue(attrStringMutableCopy is NSMutableAttributedString)
        XCTAssertTrue((attrStringMutableCopy as! NSMutableAttributedString).isEqual(to: originalAttrString))

        let originalMutableAttrString = NSMutableAttributedString(string: string, attributes: attributes)
        let mutableAttrStringMutableCopy = originalMutableAttrString.mutableCopy()
        XCTAssertTrue(mutableAttrStringMutableCopy is NSMutableAttributedString)
        XCTAssertTrue((mutableAttrStringMutableCopy as! NSMutableAttributedString).isEqual(to: originalMutableAttrString))
    }
    
    func test_isEqual() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key") : "attribute.placeholder.value"]

        let attrString = NSAttributedString(string: string, attributes: attributes)
        
        let attrString2 = NSAttributedString(string: string, attributes: attributes)
        XCTAssertTrue(attrString.isEqual(to: attrString2))
        
        let mutableAttrString = NSMutableAttributedString(string: string, attributes: attributes)
        XCTAssertTrue(attrString.isEqual(to: mutableAttrString))
        XCTAssertTrue(mutableAttrString.isEqual(to: attrString))
        
        let newAttrs: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key2") : "attribute.placeholder.value2"]
        let newAttrsRange = NSRange(string.startIndex..., in: string)
        mutableAttrString.addAttributes(newAttrs, range: newAttrsRange)
        XCTAssertFalse(attrString.isEqual(to: mutableAttrString))
        XCTAssertFalse(mutableAttrString.isEqual(to: attrString))
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
    
    fileprivate func describe(attrs: [NSAttributedStringKey : Any]) -> String {
        if attrs.count > 0 {
            let mapped: [String] = attrs.map({ "\($0.rawValue):\($1)" })
            let sorted: [String] = mapped.sorted(by: { $0 < $1 })
            let joined: String = sorted.joined(separator: ",")
            return "[" + joined + "]"
        } else {
            return "[:]"
        }
    }
}

class TestNSMutableAttributedString : XCTestCase {
    
    static var allTests: [(String, (TestNSMutableAttributedString) -> () throws -> Void)] {
        return [
            ("test_initWithString", test_initWithString),
            ("test_initWithStringAndAttributes", test_initWithStringAndAttributes),
            ("test_initWithAttributedString", test_initWithAttributedString),
            ("test_addAttribute", test_addAttribute),
            ("test_addAttributes", test_addAttributes),
            ("test_setAttributes", test_setAttributes),
            ("test_replaceCharactersWithString", test_replaceCharactersWithString),
            ("test_replaceCharactersWithAttributedString", test_replaceCharactersWithAttributedString),
            ("test_insert", test_insert),
            ("test_append", test_append),
            ("test_deleteCharacters", test_deleteCharacters),
            ("test_setAttributedString", test_setAttributedString),
        ]
    }
    
    func test_initWithString() {
        let string = "Lorem 😀 ipsum dolor sit amet, consectetur adipiscing elit. ⌘ Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit. ಠ_ರೃ"
        let mutableAttrString = NSMutableAttributedString(string: string)
        XCTAssertEqual(mutableAttrString.mutableString, NSMutableString(string: string))
    }
    
    func test_initWithStringAndAttributes() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key") : "attribute.placeholder.value"]
        
        let mutableAttrString = NSMutableAttributedString(string: string, attributes: attributes)
        XCTAssertEqual(mutableAttrString.mutableString, NSMutableString(string: string))
        XCTAssertEqual(mutableAttrString.length, string.utf16.count)
        
        var range = NSRange()
        let attrs = mutableAttrString.attributes(at: 0, effectiveRange: &range)
        guard let value = attrs[NSAttributedStringKey("attribute.placeholder.key")] as? String else {
            XCTAssert(false, "attribute value not found")
            return
        }
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, mutableAttrString.length)
        XCTAssertEqual(value, "attribute.placeholder.value")
        
        let invalidAttribute = mutableAttrString.attribute(NSAttributedStringKey("invalid"), at: 0, effectiveRange: &range)
        XCTAssertNil(invalidAttribute)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, string.utf16.count)
        
        let attribute = mutableAttrString.attribute(NSAttributedStringKey("attribute.placeholder.key"), at: 0, effectiveRange: &range)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, mutableAttrString.length)
        guard let validAttribute = attribute as? NSString else {
            XCTAssert(false, "attribute not found")
            return
        }
        XCTAssertEqual(validAttribute, "attribute.placeholder.value")
    }
    
    func test_initWithAttributedString() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key") : "attribute.placeholder.value"]

        let mutableAttrString = NSMutableAttributedString(string: string, attributes: attributes)
        
        let initializedMutableAttrString = NSMutableAttributedString(attributedString: mutableAttrString)
        XCTAssertTrue(initializedMutableAttrString.isEqual(to: mutableAttrString))
        
        // changing the mutable attr string should not affect the initialized attr string
        mutableAttrString.append(mutableAttrString)
        XCTAssertEqual(initializedMutableAttrString.mutableString, NSMutableString(string: string))
    }
    
    func test_addAttribute() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let mutableAttrString = NSMutableAttributedString(string: string)
        
        let attrKey1 = NSAttributedStringKey("attribute.placeholder.key1")
        let attrValue1 = "attribute.placeholder.value1"
        let attrRange1 = NSRange(location: 0, length: 20)
        mutableAttrString.addAttribute(attrKey1, value: attrValue1, range: attrRange1)
        
        let attrValue = mutableAttrString.attribute(attrKey1, at: 10, effectiveRange: nil)
        guard let validAttribute = attrValue as? NSString else {
            XCTAssert(false, "attribute not found")
            return
        }
        XCTAssertEqual(validAttribute, "attribute.placeholder.value1")
    }
    
    func test_addAttributes() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let mutableAttrString = NSMutableAttributedString(string: string)
        
        let attrKey1 = NSAttributedStringKey("attribute.placeholder.key1")
        let attrValue1 = "attribute.placeholder.value1"
        let attrRange1 = NSRange(location: 0, length: 20)
        mutableAttrString.addAttribute(attrKey1, value: attrValue1, range: attrRange1)

        let attrs2 = [
            NSAttributedStringKey("attribute.placeholder.key2") : "attribute.placeholder.value2",
            NSAttributedStringKey("attribute.placeholder.key3") : "attribute.placeholder.value3",
        ]
        let attrRange2 = NSRange(location: 0, length: 20)
        mutableAttrString.addAttributes(attrs2, range: attrRange2)
        
        let result = mutableAttrString.attributes(at: 10, effectiveRange: nil) as? [NSAttributedStringKey : String]
        let expectedResult: [NSAttributedStringKey : String] = [
            NSAttributedStringKey("attribute.placeholder.key1") : "attribute.placeholder.value1",
            NSAttributedStringKey("attribute.placeholder.key2") : "attribute.placeholder.value2",
            NSAttributedStringKey("attribute.placeholder.key3") : "attribute.placeholder.value3",
        ]
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_setAttributes() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let mutableAttrString = NSMutableAttributedString(string: string)
        
        let attrKey1 = NSAttributedStringKey("attribute.placeholder.key1")
        let attrValue1 = "attribute.placeholder.value1"
        let attrRange1 = NSRange(location: 0, length: 20)
        mutableAttrString.addAttribute(attrKey1, value: attrValue1, range: attrRange1)
        
        let attrs2 = [
            NSAttributedStringKey("attribute.placeholder.key2") : "attribute.placeholder.value2",
            NSAttributedStringKey("attribute.placeholder.key3") : "attribute.placeholder.value3",
        ]
        let attrRange2 = NSRange(location: 0, length: 20)
        mutableAttrString.setAttributes(attrs2, range: attrRange2)
        
        let result = mutableAttrString.attributes(at: 10, effectiveRange: nil) as? [NSAttributedStringKey : String]
        let expectedResult: [NSAttributedStringKey : String] = [
            NSAttributedStringKey("attribute.placeholder.key2") : "attribute.placeholder.value2",
            NSAttributedStringKey("attribute.placeholder.key3") : "attribute.placeholder.value3",
        ]
        XCTAssertEqual(result, expectedResult)
        
        mutableAttrString.setAttributes(nil, range: attrRange2)
        let emptyResult = mutableAttrString.attributes(at: 10, effectiveRange: nil)
        XCTAssertTrue(emptyResult.isEmpty)
    }
    
    func test_replaceCharactersWithString() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let attrKey1 = NSAttributedStringKey("attribute.placeholder.key1")
        let attrValue1 = "attribute.placeholder.value1"
        let mutableAttrString = NSMutableAttributedString(string: string, attributes: [attrKey1 : attrValue1])

        let replacement = "Sample replacement "
        let replacementRange = NSRange(replacement.startIndex..., in: replacement)
        
        mutableAttrString.replaceCharacters(in: replacementRange, with: replacement)
        
        let expectedString = string.replacingCharacters(in: replacement.startIndex..<replacement.endIndex, with: replacement)
        XCTAssertEqual(mutableAttrString.string, expectedString)
        
        let attrValue = mutableAttrString.attribute(attrKey1, at: 0, effectiveRange: nil)
        guard let validAttribute = attrValue as? NSString else {
            XCTAssert(false, "attribute not found")
            return
        }
        XCTAssertEqual(validAttribute, "attribute.placeholder.value1")
    }

    func test_replaceCharactersWithAttributedString() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let attrKey1 = NSAttributedStringKey("attribute.placeholder.key1")
        let attrValue1 = "attribute.placeholder.value1"
        let mutableAttrString = NSMutableAttributedString(string: string, attributes: [attrKey1 : attrValue1])

        let replacement = "Sample replacement "
        let replacementAttrKey = NSAttributedStringKey("attribute.replacement.key")
        let replacementAttributes: [NSAttributedStringKey : Any] = [replacementAttrKey : "attribute.replacement.value"]
        
        let replacementAttrString = NSAttributedString(string: replacement, attributes: replacementAttributes)
        let replacementRange = NSRange(location: 0, length: replacementAttrString.length)
        
        mutableAttrString.replaceCharacters(in: replacementRange, with: replacementAttrString)
        
        let expectedString = string.replacingCharacters(in: replacement.startIndex..<replacement.endIndex, with: replacement)
        XCTAssertEqual(mutableAttrString.string, expectedString)
        
        // the original attribute should be replaced
        XCTAssertNil(mutableAttrString.attribute(attrKey1, at: 0, effectiveRange: nil))
        
        guard let attrValue = mutableAttrString.attribute(replacementAttrKey, at: 0, effectiveRange: nil) as? NSString else {
            XCTAssert(false, "attribute not found")
            return
        }
        XCTAssertEqual(attrValue, "attribute.replacement.value")
    }

    func test_insert() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let attrKey1 = NSAttributedStringKey("attribute.placeholder.key1")
        let attrValue1 = "attribute.placeholder.value1"
        let mutableAttrString = NSMutableAttributedString(string: string, attributes: [attrKey1 : attrValue1])

        let insertString = "Sample insertion. "
        let insertAttrKey = NSAttributedStringKey("attribute.insertion.key")
        let insertAttributes: [NSAttributedStringKey : Any] = [insertAttrKey : "attribute.insertion.value"]
        let insertAttrString = NSAttributedString(string: insertString, attributes: insertAttributes)
        
        mutableAttrString.insert(insertAttrString, at: 0)
        
        let expectedString = insertString + string
        XCTAssertEqual(mutableAttrString.string, expectedString)
        
        let insertedAttributes = mutableAttrString.attributes(at: 0, effectiveRange: nil) as? [NSAttributedStringKey : String]
        let expectedInserted = [insertAttrKey : "attribute.insertion.value"]
        XCTAssertEqual(insertedAttributes, expectedInserted)
        
        let originalAttributes = mutableAttrString.attributes(at: insertAttrString.length, effectiveRange: nil) as? [NSAttributedStringKey : String]
        let expectedOriginal = [attrKey1 : attrValue1]
        XCTAssertEqual(originalAttributes, expectedOriginal)
    }

    func test_append() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let attrKey1 = NSAttributedStringKey("attribute.placeholder.key1")
        let attrValue1 = "attribute.placeholder.value1"
        let mutableAttrString = NSMutableAttributedString(string: string, attributes: [attrKey1 : attrValue1])
        
        let appendString = " Sample appending."
        let appendAttrKey = NSAttributedStringKey("attribute.appending.key")
        let appendAttributes : [NSAttributedStringKey : Any] = [appendAttrKey : "attribute.appending.value"]
        let appendAttrString = NSAttributedString(string: appendString, attributes: appendAttributes)
        
        mutableAttrString.append(appendAttrString)
        
        let expectedString = string + appendString
        XCTAssertEqual(mutableAttrString.string, expectedString)
        
        let originalAttributes = mutableAttrString.attributes(at: 0, effectiveRange: nil) as? [NSAttributedStringKey : String]
        let expectedOriginal = [attrKey1 : attrValue1]
        XCTAssertEqual(originalAttributes, expectedOriginal)
        
        let appendedAttributes = mutableAttrString.attributes(at: string.utf16.count, effectiveRange: nil) as? [NSAttributedStringKey : String]
        let expectedAppended = [appendAttrKey : "attribute.appending.value"]
        XCTAssertEqual(appendedAttributes, expectedAppended)
    }

    func test_deleteCharacters() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let attrKey1 = NSAttributedStringKey("attribute.placeholder.key1")
        let attrValue1 = "attribute.placeholder.value1"
        let mutableAttrString = NSMutableAttributedString(string: string, attributes: [attrKey1 : attrValue1])

        let deleteRange = NSRange(location: 0, length: 10)
        mutableAttrString.deleteCharacters(in: deleteRange)
        
        let expectedString = String(string[string.index(string.startIndex, offsetBy: 10)...])
        XCTAssertEqual(mutableAttrString.string, expectedString)
        
        let expectedLongestEffectiveRange = NSRange(expectedString.startIndex..., in: expectedString)
        var longestEffectiveRange = NSRange()
        let searchRange = NSRange(location: 0, length: mutableAttrString.length)
        guard let value = mutableAttrString.attribute(attrKey1, at: 0, longestEffectiveRange: &longestEffectiveRange, in: searchRange) as? NSString else {
            XCTAssert(false, "attribute not found")
            return
        }
        XCTAssertEqual(value, "attribute.placeholder.value1")
        XCTAssertEqual(longestEffectiveRange.location, expectedLongestEffectiveRange.location)
        XCTAssertEqual(longestEffectiveRange.length, expectedLongestEffectiveRange.length)
    }
    
    func test_setAttributedString() {
        let string1 = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        let attributes1: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key1") : "attribute.placeholder.value1"]
        let mutableAttrString = NSMutableAttributedString(string: string1, attributes: attributes1)
        
        let string2 = "Sample set attributed string."
        let attributes2: [NSAttributedStringKey : Any] = [NSAttributedStringKey("attribute.placeholder.key2") : "attribute.placeholder.value2"]
        let replacementAttrString = NSMutableAttributedString(string: string2, attributes: attributes2)
        
        mutableAttrString.setAttributedString(replacementAttrString)
        XCTAssertTrue(mutableAttrString.isEqual(to: replacementAttrString))
        
        // changing the replacement attr string should not affect the replaced attr string
        replacementAttrString.append(replacementAttrString)
        XCTAssertEqual(mutableAttrString.string, string2)
    }
}
