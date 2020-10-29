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
import XCTest

class TestNotification : XCTestCase {
    func test_unconditionallyBridgeFromObjectiveC() {
        XCTAssertEqual(Notification(name: Notification.Name("")), Notification._unconditionallyBridgeFromObjectiveC(nil))
    }

    func test_hashing() {
        guard #available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *) else { return }

        let o1 = NSObject()
        let o2 = NSObject()
        let values: [Notification] = [
            /* 0 */ Notification(name: .init("a"), object: o1, userInfo: nil),
            /* 1 */ Notification(name: .init("a"), object: o2, userInfo: nil),
            /* 2 */ Notification(name: .init("b"), object: o1, userInfo: nil),
            /* 3 */ Notification(name: .init("b"), object: o2, userInfo: nil),
            /* 4 */ Notification(name: .init("a"), object: o1, userInfo: ["Foo": 1]),
            /* 5 */ Notification(name: .init("a"), object: o1, userInfo: ["Foo": 2]),
            /* 6 */ Notification(name: .init("a"), object: o1, userInfo: ["Bar": 1]),
            /* 7 */ Notification(name: .init("a"), object: o1, userInfo: ["Foo": 1, "Bar": 2]),
        ]

        let hashGroups: [Int: Int] = [
            0: 0,
            1: 0,
            2: 1,
            3: 1,
            4: 2,
            5: 2,
            6: 3,
            7: 4
        ]

        checkHashable(
            values,
            equalityOracle: { $0 == $1 },
            hashEqualityOracle: {
                // FIXME: Unfortunately while we have 8 different notifications,
                // three pairs of them have colliding hash encodings.
                hashGroups[$0] == hashGroups[$1]
            })
    }


    private struct NonHashableValueType: Equatable {
        let value: Int
        init(_ value: Int) {
            self.value = value
        }
    }

    func test_reflexivity_violation() {
        // <rdar://problem/49797185> Foundation.Notification's equality relation isn't reflexive
        let name = Notification.Name("name")
        let a = NonHashableValueType(1)
        let b = NonHashableValueType(2)
        // Currently none of these values compare equal to themselves:
        let values: [Notification] = [
            Notification(name: name, object: a, userInfo: nil),
            Notification(name: name, object: b, userInfo: nil),
            Notification(name: name, object: nil, userInfo: ["foo": a]),
            Notification(name: name, object: nil, userInfo: ["foo": b]),
        ]
        #if true // What we have
        for value in values {
            XCTAssertNotEqual(value, value)
        }
        #else // What we want
        checkHashable(values, equalityOracle: { $0 == $1 })
        #endif
    }
}
