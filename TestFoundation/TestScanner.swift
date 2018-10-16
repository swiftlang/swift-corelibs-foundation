// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestScanner : XCTestCase {

    static var allTests: [(String, (TestScanner) -> () throws -> Void)] {
        return [
            ("test_scanInteger", test_scanInteger),
            ("test_scanFloat", test_scanFloat),
            ("test_scanString", test_scanString),
            ("test_charactersToBeSkipped", test_charactersToBeSkipped),
        ]
    }

    func test_scanInteger() {
        let scanner = Scanner(string: "123")
        var value: Int = 0
        XCTAssert(scanner.scanInt(&value), "An Integer should be found in the string `123`.")
        XCTAssertEqual(value, 123, "Scanned Integer value of the string `123` should be `123`.")
        XCTAssertTrue(scanner.isAtEnd)
    }

    func test_scanFloat() {
        let scanner = Scanner(string: "-350000000000000000000000000000000000000000")
        var value: Float = 0
        XCTAssert(scanner.scanFloat(&value), "A Float should be found in the string `-350000000000000000000000000000000000000000`.")
        XCTAssert(value.isInfinite, "Scanned Float value of the string `-350000000000000000000000000000000000000000` should be infinite`.")
    }

    func test_scanString() {
        let scanner = Scanner(string: "apple sauce")

        guard let firstPart = scanner.scanString("apple ") else {
            XCTFail()
            return
        }

        XCTAssertEqual(firstPart, "apple ")
        XCTAssertFalse(scanner.isAtEnd)

        let _ = scanner.scanString("sauce")
        XCTAssertTrue(scanner.isAtEnd)
    }

    func test_charactersToBeSkipped() {
        let scanner = Scanner(string: "xyz  ")
        scanner.charactersToBeSkipped = .whitespaces

        let _ = scanner.scanString("xyz")
        XCTAssertTrue(scanner.isAtEnd)
    }
}
