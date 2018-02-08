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

class TestNSMeasurement : XCTestCase {

    static var allTests: [(String, (TestNSMeasurement) -> () throws -> Void)] {
        return [
            ("test_addition", test_addition),
            ("test_subtraction", test_subtraction),
            ("test_coding", test_coding),
        ]
    }

    func test_addition() {
        XCTAssertEqual(false, false)
        XCTAssertTrue(true)
    }

    func test_subtraction() {
        XCTAssertEqual(false, false)
        XCTAssertTrue(true)
    }

    func test_coding() {
        XCTAssertEqual(false, false)
        XCTAssertTrue(true)
    }

}
