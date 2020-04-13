// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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

class SwiftClass {
    class InnerClass {}
}



struct SwiftStruct {}

enum SwiftEnum {}

class TestObjCRuntime: XCTestCase {
    static var allTests: [(String, (TestObjCRuntime) -> () throws -> Void)] {
        var tests: [(String, (TestObjCRuntime) -> () throws -> Void)] = [
            ("testStringFromClass", testStringFromClass),
            ("testClassFromString", testClassFromString),
        ]
        
        #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
        tests.append(("testClassesRenamedByAPINotes", testClassesRenamedByAPINotes))
        #endif
        
        return tests
    }

    func testStringFromClass() {
        let name = testBundleName()
        XCTAssertEqual(NSStringFromClass(NSObject.self), "NSObject")
        XCTAssertEqual(NSStringFromClass(SwiftClass.self), "\(name).SwiftClass")
#if canImport(SwiftXCTest) && !DEPLOYMENT_RUNTIME_OBJC
        XCTAssertEqual(NSStringFromClass(XCTestCase.self), "SwiftXCTest.XCTestCase");
#else
        XCTAssertEqual(NSStringFromClass(XCTestCase.self), "XCTest.XCTestCase");
#endif
    }

    func testClassFromString() {
        let name = testBundleName()
        XCTAssertNotNil(NSClassFromString("NSObject"))
        XCTAssertNotNil(NSClassFromString("\(name).SwiftClass"))
        XCTAssertNil(NSClassFromString("\(name).SwiftClass.InnerClass"))
        XCTAssertNil(NSClassFromString("SwiftClass"))
        XCTAssertNil(NSClassFromString("MadeUpClassName"))
        XCTAssertNil(NSClassFromString("SwiftStruct"));
        XCTAssertNil(NSClassFromString("SwiftEnum"));
    }
    
    #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    func testClassesRenamedByAPINotes() throws {
        for entry in _NSClassesRenamedByObjCAPINotes {
            XCTAssert(try XCTUnwrap(NSClassFromString(NSStringFromClass(entry.class))) === entry.class)
            XCTAssert(NSStringFromClass(try XCTUnwrap(NSClassFromString(entry.objCName))) == entry.objCName)
        }
    }
    #endif
}
