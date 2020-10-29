//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import CoreFoundation
import XCTest

class TestPersonNameComponents : XCTestCase {
    @available(OSX 10.11, iOS 9.0, *)
    func makePersonNameComponents(givenName: String, familyName: String) -> PersonNameComponents {
        var result = PersonNameComponents()
        result.givenName = givenName
        result.familyName = familyName
        return result
    }

    func test_Hashing() {
        guard #available(macOS 10.13, iOS 11.0, *) else {
            // PersonNameComponents was available in earlier versions, but its
            // hashing did not match its definition for equality.
            return
        }

        let values: [[PersonNameComponents]] = [
            [
                makePersonNameComponents(givenName: "Kevin", familyName: "Frank"),
                makePersonNameComponents(givenName: "Kevin", familyName: "Frank"),
            ],
            [
                makePersonNameComponents(givenName: "John", familyName: "Frank"),
                makePersonNameComponents(givenName: "John", familyName: "Frank"),
            ],
            [
                makePersonNameComponents(givenName: "Kevin", familyName: "Appleseed"),
                makePersonNameComponents(givenName: "Kevin", familyName: "Appleseed"),
            ],
            [
                makePersonNameComponents(givenName: "John", familyName: "Appleseed"),
                makePersonNameComponents(givenName: "John", familyName: "Appleseed"),
            ]
        ]
        checkHashableGroups(
            values,
            // FIXME: PersonNameComponents hashes aren't seeded.
            allowIncompleteHashing: true)
    }

    func test_AnyHashableContainingPersonNameComponents() {
        if #available(OSX 10.11, iOS 9.0, *) {
            let values: [PersonNameComponents] = [
                makePersonNameComponents(givenName: "Kevin", familyName: "Frank"),
                makePersonNameComponents(givenName: "John", familyName: "Appleseed"),
                makePersonNameComponents(givenName: "John", familyName: "Appleseed"),
            ]
            let anyHashables = values.map(AnyHashable.init)
            expectEqual(PersonNameComponents.self, type(of: anyHashables[0].base))
            expectEqual(PersonNameComponents.self, type(of: anyHashables[1].base))
            expectEqual(PersonNameComponents.self, type(of: anyHashables[2].base))
            XCTAssertNotEqual(anyHashables[0], anyHashables[1])
            XCTAssertEqual(anyHashables[1], anyHashables[2])
        }
    }

    @available(OSX 10.11, iOS 9.0, *)
    func makeNSPersonNameComponents(givenName: String, familyName: String) -> NSPersonNameComponents {
        let result = NSPersonNameComponents()
        result.givenName = givenName
        result.familyName = familyName
        return result
    }

    func test_AnyHashableCreatedFromNSPersonNameComponents() {
        if #available(OSX 10.11, iOS 9.0, *) {
            let values: [NSPersonNameComponents] = [
                makeNSPersonNameComponents(givenName: "Kevin", familyName: "Frank"),
                makeNSPersonNameComponents(givenName: "John", familyName: "Appleseed"),
                makeNSPersonNameComponents(givenName: "John", familyName: "Appleseed"),
            ]
            let anyHashables = values.map(AnyHashable.init)
            expectEqual(PersonNameComponents.self, type(of: anyHashables[0].base))
            expectEqual(PersonNameComponents.self, type(of: anyHashables[1].base))
            expectEqual(PersonNameComponents.self, type(of: anyHashables[2].base))
            XCTAssertNotEqual(anyHashables[0], anyHashables[1])
            XCTAssertEqual(anyHashables[1], anyHashables[2])
        }
    }
}
