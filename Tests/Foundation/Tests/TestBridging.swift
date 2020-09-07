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
            ("testDynamicCast", testDynamicCast),
        ]
    }

    func testBridgedDescription() throws {
        #if canImport(Foundation) && canImport(SwiftFoundation)
        /*
          Do not test this on Darwin.
          On systems where swift-corelibs-foundation is the Foundation module,
         the stdlib gives us the ability to specify how bridging works
         (by using our __SwiftValue class), which is what we're testing
         here when we do 'a as AnyObject'. But on Darwin, bridging is out
         of SCF's hands — there is an ObjC __SwiftValue class vended by
         the runtime.
          Deceptively, below, when we say 'NSObject', we mean SwiftFoundation.NSObject,
         not the ObjC NSObject class — which is what __SwiftValue actually
         derives from. So, as? NSObject below returns nil on Darwin.
          Since this functionality is tested by the stdlib tests on Darwin,
         just skip this test here.
        */
        #else
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
        #endif
    }

    func testDynamicCast() throws {
        // Covers https://github.com/apple/swift-corelibs-foundation/pull/2500
        class TestClass {}
        let anyArray: Any = [TestClass()]
        XCTAssertNotNil(anyArray as? NSObject)
    }
}
