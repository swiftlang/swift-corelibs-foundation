//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest

class TestNSString : XCTestCase {
    
  func test_equalOverflow() {
    let cyrillic = "чебурашка@ящик-с-апельсинами.рф"
    let other = getNSStringEqualTestString()
    print(NSStringBridgeTestEqual(cyrillic, other))
  }
  
  func test_smallString_BOM() {
    let bom = "\u{FEFF}" // U+FEFF (ZERO WIDTH NO-BREAK SPACE)
//    XCTAssertEqual(1, NSString(string: bom).length)
//    XCTAssertEqual(4, NSString(string: "\(bom)abc").length)
//    XCTAssertEqual(5, NSString(string: "\(bom)\(bom)abc").length)
//    XCTAssertEqual(4, NSString(string: "a\(bom)bc").length)
//    XCTAssertEqual(13, NSString(string: "\(bom)234567890123").length)
//    XCTAssertEqual(14, NSString(string: "\(bom)2345678901234").length)
    
    XCTAssertEqual(1, (bom as NSString).length)
    XCTAssertEqual(4, ("\(bom)abc" as NSString).length)
    XCTAssertEqual(5, ("\(bom)\(bom)abc" as NSString).length)
    XCTAssertEqual(4, ("a\(bom)bc" as NSString).length)
    XCTAssertEqual(13, ("\(bom)234567890123" as NSString).length)
    XCTAssertEqual(14, ("\(bom)2345678901234" as NSString).length)
    
    let string = "\(bom)abc"
    let middleIndex = string.index(string.startIndex, offsetBy: 2)
    string.enumerateSubstrings(in: middleIndex..<string.endIndex, options: .byLines) { (_, _, _, _) in }  //shouldn't crash
  }
  
  func test_unpairedSurrogates() {
    let evil = getNSStringWithUnpairedSurrogate();
    print("\(evil)")
  }
  
}
