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



class TestNSCharacterSet : XCTestCase {
    
    static var allTests: [(String, (TestNSCharacterSet) -> () throws -> Void)] {
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
        let cset = NSCharacterSet.controlCharacters()
        
        XCTAssertTrue(cset === NSCharacterSet.controlCharacters(), "predefined charactersets should be singletons")
        
        XCTAssertTrue(cset.characterIsMember(unichar(0xFEFF)), "Control set should contain UFEFF")
        XCTAssertTrue(NSCharacterSet.letters().characterIsMember("a"), "Letter set should contain 'a'")
        XCTAssertTrue(NSCharacterSet.lowercaseLetters().characterIsMember("a"), "Lowercase Letter set should contain 'a'")
        XCTAssertTrue(NSCharacterSet.uppercaseLetters().characterIsMember("A"), "Uppercase Letter set should contain 'A'")
        XCTAssertTrue(NSCharacterSet.uppercaseLetters().characterIsMember(unichar(0x01C5)), "Uppercase Letter set should contain U01C5")
        XCTAssertTrue(NSCharacterSet.capitalizedLetters().characterIsMember(unichar(0x01C5)), "Uppercase Letter set should contain U01C5")
        XCTAssertTrue(NSCharacterSet.symbols().characterIsMember(unichar(0x002B)), "Symbol set should contain U002B")
        XCTAssertTrue(NSCharacterSet.symbols().characterIsMember(unichar(0x20B1)), "Symbol set should contain U20B1")
        XCTAssertTrue(NSCharacterSet.newlines().characterIsMember(unichar(0x000A)), "Newline set should contain 0x000A")
        XCTAssertTrue(NSCharacterSet.newlines().characterIsMember(unichar(0x2029)), "Newline set should contain 0x2029")
        
        let mcset = NSMutableCharacterSet.whitespacesAndNewlines()
        let cset2 = NSCharacterSet.whitespacesAndNewlines()

        XCTAssert(mcset.isSuperset(of: cset2))
        XCTAssert(cset2.isSuperset(of: mcset))
        
        XCTAssertTrue(NSCharacterSet.whitespacesAndNewlines().isSuperset(of: NSCharacterSet.newlines()), "whitespace and newline should be a superset of newline")
        let data = NSCharacterSet.uppercaseLetters().bitmapRepresentation
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
        let cset = NSCharacterSet(charactersIn: "abcABC")
        for idx: unichar in 0..<0xFFFF {
            XCTAssertEqual(cset.characterIsMember(idx), (idx >= unichar(unicodeScalarLiteral: "a") && idx <= unichar(unicodeScalarLiteral: "c")) || (idx >= unichar(unicodeScalarLiteral: "A") && idx <= unichar(unicodeScalarLiteral: "C")) ? true : false)
        }
    }
    
    func test_Bitmap() {
        
    }
    
    func test_Mutables() {
        let attachmentCharacterUnichar = unichar(0xFFFC)
        let attachmentCharacter = Character(UnicodeScalar(attachmentCharacterUnichar))

        let attachmentCharacterRange = NSRange(Int(attachmentCharacterUnichar)..<Int(attachmentCharacterUnichar + 1))

        let initialSetRange = NSRange(location: 0, length: 0)
        let string = String(attachmentCharacter)

        let mcset1 = NSMutableCharacterSet(range: initialSetRange)
        mcset1.addCharacters(in: attachmentCharacterRange)

        XCTAssertTrue(mcset1.characterIsMember(attachmentCharacterUnichar), "attachmentCharacter should be member of mcset1 after being added")
        XCTAssertNotNil(string.rangeOfCharacter(from: mcset1), "Range of character from mcset1 set should not be nil")

        let mcset2 = NSMutableCharacterSet(range: initialSetRange)
        mcset2.addCharacters(in: string)

        XCTAssertTrue(mcset2.characterIsMember(attachmentCharacterUnichar), "attachmentCharacter should be member of mcset2 after being added")
        XCTAssertNotNil(string.rangeOfCharacter(from: mcset2), "Range of character from mcset2 should not be nil")
    }
    
    func test_AnnexPlanes() {
        
    }
    
    func test_Planes() {
        
    }
    
    func test_InlineBuffer() {
        
    }
}

