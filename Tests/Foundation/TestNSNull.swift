// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSNull : XCTestCase {
    func test_alwaysEqual() {
        let null_1 = NSNull()
        let null_2 = NSNull()

        let null_3: NSNull? = NSNull()
        let null_4: NSNull? = nil

        //Check that any two NSNull's are ==
        XCTAssertEqual(null_1, null_2)

        //Check that any two NSNull's are ===, preserving the singleton behavior
        XCTAssertTrue(null_1 === null_2)
        XCTAssertFalse(null_1 !== null_2)

        //Check that NSNull() == .Some(NSNull)
        XCTAssertEqual(null_1, null_3)

        //Make sure that NSNull() != .None
        XCTAssertNotEqual(null_1, null_4)
    }

    func test_identityOperator() {
        let null_1: NSNull? = NSNull()
        let null_2: NSNull? = NSNull()
        let null_nil: NSNull? = nil

        //Check that two non-nil NSNull values are ===
        XCTAssertTrue(null_1 === null_2)
        XCTAssertFalse(null_1 !== null_2)

        //Check that nil === nil for the NSNull? overload
        XCTAssertTrue(null_nil === null_nil)
        XCTAssertFalse(null_nil !== null_nil)

        //Check that a non-nil NSNull is not === to nil in either order
        XCTAssertFalse(null_1 === null_nil)
        XCTAssertFalse(null_nil === null_1)
        XCTAssertTrue(null_1 !== null_nil)
        XCTAssertTrue(null_nil !== null_1)
    }

    func test_description() {
        XCTAssertEqual(NSNull().description, "<null>")
    }
}
