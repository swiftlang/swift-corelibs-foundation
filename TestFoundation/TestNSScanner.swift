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



class TestNSScanner : XCTestCase {

    static var allTests: [(String, (TestNSScanner) -> () throws -> Void)] {
        return [
            ("test_scanInteger", test_scanInteger),
            ("test_scanFloat", test_scanFloat),
        ]
    }

    func test_scanInteger() {
        let scanner = Scanner(string: "123")
        var value: Int = 0
        XCTAssert(scanner.scanInteger(&value), "An Integer should be found in the string `123`.")
        XCTAssertEqual(value, 123, "Scanned Integer value of the string `123` should be `123`.")
    }

    func test_scanFloat() {
        let scanner = Scanner(string: "-350000000000000000000000000000000000000000")
        var value: Float = 0
        XCTAssert(scanner.scanFloat(&value), "A Float should be found in the string `-350000000000000000000000000000000000000000`.")
        XCTAssert(value.isInfinite, "Scanned Float value of the string `-350000000000000000000000000000000000000000` should be infinite`.")
    }
}
