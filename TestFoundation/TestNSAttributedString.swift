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



class TestNSAttributedString: XCTestCase {
    
    static var allTests: [(String, TestNSAttributedString -> () throws -> Void)] {
        return [
            ("test_initWithSimpleString", test_initWithSimpleString),
            ("test_initWithComplexString", test_initWithComplexString),
            ("test_initWithSimpleStringAndAttributes", test_initWithSimpleStringAndAttributes),
            ("test_initWithAttributedString", test_initWithAttributedString),
        ]
    }
    
    func test_initWithSimpleString() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let attrString = NSAttributedString(string: string)
        XCTAssertEqual(attrString.string, string)
        XCTAssertEqual(attrString.length, string.utf16Count)
    }
    
    func test_initWithComplexString() {
        let string = "Lorem 😀 ipsum dolor sit amet, consectetur adipiscing elit. ⌘ Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit. ಠ_ರೃ"
        let attrString = NSAttributedString(string: string)
        XCTAssertEqual(attrString.string, string)
        XCTAssertEqual(attrString.length, string.utf16Count)
    }
    
    func test_initWithSimpleStringAndAttributes() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let attributes: [String : AnyObject] = ["attribute.placeholder.key" : "attribute.placeholder.value" as NSString]

        let attrString = NSAttributedString(string: string, attributes: attributes)
        XCTAssertEqual(attrString.string, string)
        XCTAssertEqual(attrString.length, string.utf16Count)
        
        // TODO: None of the attributes retrival methods is implemented, as a result attributes can't be tested yet.
    }
    
    func test_initWithAttributedString() {
        let string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus consectetur et sem vitae consectetur. Nam venenatis lectus a laoreet blandit."
        let attrString = NSAttributedString(string: string)
        let newAttrString = NSAttributedString(attributedString: attrString)
        
        // FIXME: Should use `isEqualToAttributedString:` instead after it's implemented
        XCTAssertEqual(attrString.string, newAttrString.string)
    }
    
}
