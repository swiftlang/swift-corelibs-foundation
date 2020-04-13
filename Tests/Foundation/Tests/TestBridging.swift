// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
        @testable import SwiftFoundation
    #else
        @testable import Foundation
    #endif
#endif

struct StructWithDescriptionAndDebugDescription:
    CustomStringConvertible, CustomDebugStringConvertible
{
    var description: String { "description" }
    var debugDescription: String { "debugDescription" }
}

class TestBridging : XCTestCase {
    static var allTests: [(String, (TestBridging) -> () throws -> Void)] {
        return [
            ("testBridgedDescription", testBridgedDescription),
        ]
    }

    func testBridgedDescription() throws {
        // Struct with working (debug)description properties:
        let a = StructWithDescriptionAndDebugDescription()
        XCTAssertEqual("description", a.description)
        XCTAssertEqual("debugDescription", a.debugDescription)

        // Wrap it up in a SwiftValue container
        let b = (a as AnyObject) as? NSObject
        XCTAssertNotNil(b)
        let c = try XCTUnwrap(b)

        // Check that the wrapper forwards (debug)description
        // to the wrapped description property.
        XCTAssertEqual("description", c.description)
        XCTAssertEqual("description", c.debugDescription)
    }
}
