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



class TestNSScanner : XCTestCase {

    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_scanInteger", test_scanInteger),
        ]
    }

    func test_scanInteger() {
        let scanner = NSScanner(string: "123")
        var value: Int = 0
        XCTAssert(scanner.scanInteger(&value), "An Integer should be found in the string `123`.")
        XCTAssertEqual(value, 123, "Scanned Integer value of the string `123` should be `123`.")
    }
}
