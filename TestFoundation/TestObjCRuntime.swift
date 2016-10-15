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

class SwiftClass {
    class InnerClass {}
}

struct SwfitStruct {}

enum SwiftEnum {}

class TestObjCRuntime: XCTestCase {
    static var allTests: [(String, (TestObjCRuntime) -> () throws -> Void)] {
        return [
            ("testStringFromClass", testStringFromClass),
            ("testClassFromString", testClassFromString),
        ]
    }

    func testStringFromClass() {
        XCTAssertEqual(NSStringFromClass(NSObject.self), "NSObject")
        XCTAssertEqual(NSStringFromClass(SwiftClass.self), "TestFoundation.SwiftClass")
#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
        XCTAssertEqual(NSStringFromClass(XCTestCase.self), "XCTest.XCTestCase");
#else
        XCTAssertEqual(NSStringFromClass(XCTestCase.self), "SwiftXCTest.XCTestCase");
#endif
    }

    func testClassFromString() {
        XCTAssertNotNil(NSClassFromString("NSObject"))
        XCTAssertNotNil(NSClassFromString("TestFoundation.SwiftClass"))
        XCTAssertNil(NSClassFromString("TestFoundation.SwiftClass.InnerClass"))
        XCTAssertNil(NSClassFromString("SwiftClass"))
        XCTAssertNil(NSClassFromString("MadeUpClassName"))
        XCTAssertNil(NSClassFromString("SwiftStruct"));
        XCTAssertNil(NSClassFromString("SwiftEnum"));
    }
}
