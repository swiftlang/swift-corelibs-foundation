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



class TestNSCharacterSet : XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_Predefines", test_Predefines),
            ("test_Range", test_Range),
            ("test_String", test_String),
            ("test_Bitmap", test_Bitmap),
            ("test_Mutables", test_Mutables),
            ("test_AnnexPlanes", test_AnnexPlanes),
            ("test_Planes", test_Planes),
            ("test_InlineBuffer", test_InlineBuffer),
        ]
    }
    
    func test_Predefines() {
        let cset = NSCharacterSet.controlCharacterSet()
        
        XCTAssertTrue(cset === NSCharacterSet.controlCharacterSet(), "predefined charactersets should be singletons")
        
        XCTAssertTrue(cset.characterIsMember(unichar(0xFEFF)), "Control set should contain UFEFF")
        XCTAssertTrue(NSCharacterSet.letterCharacterSet().characterIsMember("a"), "Letter set should contain 'a'")
        XCTAssertTrue(NSCharacterSet.lowercaseLetterCharacterSet().characterIsMember("a"), "Lowercase Letter set should contain 'a'")
        XCTAssertTrue(NSCharacterSet.uppercaseLetterCharacterSet().characterIsMember("A"), "Uppercase Letter set should contain 'A'")
        XCTAssertTrue(NSCharacterSet.uppercaseLetterCharacterSet().characterIsMember(unichar(0x01C5)), "Uppercase Letter set should contain U01C5")
        XCTAssertTrue(NSCharacterSet.capitalizedLetterCharacterSet().characterIsMember(unichar(0x01C5)), "Uppercase Letter set should contain U01C5")
        XCTAssertTrue(NSCharacterSet.symbolCharacterSet().characterIsMember(unichar(0x002B)), "Symbol set should contain U002B")
        XCTAssertTrue(NSCharacterSet.symbolCharacterSet().characterIsMember(unichar(0x20B1)), "Symbol set should contain U20B1")
        XCTAssertTrue(NSCharacterSet.newlineCharacterSet().characterIsMember(unichar(0x000A)), "Newline set should contain 0x000A")
        XCTAssertTrue(NSCharacterSet.newlineCharacterSet().characterIsMember(unichar(0x2029)), "Newline set should contain 0x2029")
        
        let mcset = NSMutableCharacterSet.whitespaceAndNewlineCharacterSet()
        let cset2 = NSCharacterSet.whitespaceAndNewlineCharacterSet()

        XCTAssert(mcset.isSupersetOfSet(cset2))
        XCTAssert(cset2.isSupersetOfSet(mcset))
        
        XCTAssertTrue(NSCharacterSet.whitespaceAndNewlineCharacterSet().isSupersetOfSet(NSCharacterSet.newlineCharacterSet()), "whitespace and newline should be a superset of newline")
        let data = NSCharacterSet.uppercaseLetterCharacterSet().bitmapRepresentation
        XCTAssertNotNil(data)
    }
    
    func test_Range() {
        let cset1 = NSCharacterSet(range: NSMakeRange(0x20, 40))
        for idx: unichar in 0..<0xFFFF {
            XCTAssertEqual(cset1.characterIsMember(idx), (idx >= 0x20 && idx < 0x20 + 40 ? true : false))
        }
        
        let cset2 = NSCharacterSet(range: NSMakeRange(0x0000, 0xFFFF))
        for idx: unichar in 0..<0xFFFF {
            XCTAssertEqual(cset2.characterIsMember(idx), true)
        }
        
        let cset3 = NSCharacterSet(range: NSMakeRange(0x0000, 10))
        for idx: unichar in 0..<0xFFFF {
            XCTAssertEqual(cset3.characterIsMember(idx), (idx < 10 ? true : false))
        }
        
        let cset4 = NSCharacterSet(range: NSMakeRange(0x20, 0))
        for idx: unichar in 0..<0xFFFF {
            XCTAssertEqual(cset4.characterIsMember(idx), false)
        }
    }
    
    func test_String() {
        let cset = NSCharacterSet(charactersInString: "abcABC")
        for idx: unichar in 0..<0xFFFF {
            XCTAssertEqual(cset.characterIsMember(idx), (idx >= unichar(unicodeScalarLiteral: "a") && idx <= unichar(unicodeScalarLiteral: "c")) || (idx >= unichar(unicodeScalarLiteral: "A") && idx <= unichar(unicodeScalarLiteral: "C")) ? true : false)
        }
    }
    
    func test_Bitmap() {
        
    }
    
    func test_Mutables() {
        
    }
    
    func test_AnnexPlanes() {
        
    }
    
    func test_Planes() {
        
    }
    
    func test_InlineBuffer() {
        
    }
}
    