// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// RUN: %target-run-simple-swift
// REQUIRES: executable_test
// REQUIRES: objc_interop

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#elseif DEPLOYMENT_RUNTIME_SWIFT
import SwiftFoundation
import SwiftXCTest
#endif

class TestPersonNameComponents : XCTestCase {
    static var allTests: [(String, (TestPersonNameComponents) -> () throws -> Void)] {
        return [
            ("test_AnyHashableContainingPersonNameComponents", test_AnyHashableContainingPersonNameComponents),
            ("test_AnyHashableCreatedFromNSPersonNameComponents", test_AnyHashableCreatedFromNSPersonNameComponents),
        ]
    }
    
    
    func makePersonNameComponents(givenName: String, familyName: String) -> PersonNameComponents {
        var result = PersonNameComponents()
        result.givenName = givenName
        result.familyName = familyName
        return result
    }
    func test_AnyHashableContainingPersonNameComponents() {
        let values: [PersonNameComponents] = [
            makePersonNameComponents(givenName: "Kevin", familyName: "Frank"),
            makePersonNameComponents(givenName: "John", familyName: "Appleseed"),
            makePersonNameComponents(givenName: "John", familyName: "Appleseed"),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(PersonNameComponents.self, type(of: anyHashables[0].base))
        XCTAssertSameType(PersonNameComponents.self, type(of: anyHashables[1].base))
        XCTAssertSameType(PersonNameComponents.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func makeNSPersonNameComponents(givenName: String, familyName: String) -> NSPersonNameComponents {
        let result = NSPersonNameComponents()
        result.givenName = givenName
        result.familyName = familyName
        return result
    }
    
    func test_AnyHashableCreatedFromNSPersonNameComponents() {
        let values: [NSPersonNameComponents] = [
            makeNSPersonNameComponents(givenName: "Kevin", familyName: "Frank"),
            makeNSPersonNameComponents(givenName: "John", familyName: "Appleseed"),
            makeNSPersonNameComponents(givenName: "John", familyName: "Appleseed"),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(PersonNameComponents.self, type(of: anyHashables[0].base))
        XCTAssertSameType(PersonNameComponents.self, type(of: anyHashables[1].base))
        XCTAssertSameType(PersonNameComponents.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}
