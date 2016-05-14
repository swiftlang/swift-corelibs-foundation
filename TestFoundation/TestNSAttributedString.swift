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
            ("test_initWithStringAndAttributes", test_initWithStringAndAttributes)
        ]
    }
    
    func test_initWithString() {
        let string = "Lorem 😀 ipsum dolor sit amet, consectetur adipiscing elit. ⌘ Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit. ಠ_ರೃ"
        let attrString = NSAttributedString(string: string)
        XCTAssertEqual(attrString.string, string)
        XCTAssertEqual(attrString.length, string.utf16Count)
        
        var range = NSRange()
        let attrs = attrString.attributesAtIndex(0, effectiveRange: &range)
        XCTAssertEqual(range.location, NSNotFound)
        XCTAssertEqual(range.length, 0)
        XCTAssertEqual(attrs.count, 0)

        let attribute = attrString.attribute("invalid", atIndex: 0, effectiveRange: &range)
        XCTAssertNil(attribute)
        XCTAssertEqual(range.location, NSNotFound)
        XCTAssertEqual(range.length, 0)
    }
    
    func test_initWithStringAndAttributes() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let attributes: [String : AnyObject] = ["attribute.placeholder.key" : "attribute.placeholder.value" as NSString]
        
        let attrString = NSAttributedString(string: string, attributes: attributes)
        XCTAssertEqual(attrString.string, string)
        XCTAssertEqual(attrString.length, string.utf16Count)
        
        var range = NSRange()
        let attrs = attrString.attributesAtIndex(0, effectiveRange: &range)
        guard let value = attrs["attribute.placeholder.key"] as? NSString else {
            XCTAssert(false, "attribute value not found")
            return
        }
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, attrString.length)
        XCTAssertEqual(value, "attribute.placeholder.value")

        let invalidAttribute = attrString.attribute("invalid", atIndex: 0, effectiveRange: &range)
        XCTAssertNil(invalidAttribute)
        XCTAssertEqual(range.location, NSNotFound)
        XCTAssertEqual(range.length, 0)

        let attribute = attrString.attribute("attribute.placeholder.key", atIndex: 0, effectiveRange: &range)
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
        
        _ = attrString.attribute(attrKey, atIndex: 0, longestEffectiveRange: &range, inRange: searchRange)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 29)
        
        _ = attrString.attributesAtIndex(0, longestEffectiveRange: &range, inRange: searchRange)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 29)
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