// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNotification : XCTestCase {

    static var allTests: [(String, (TestNotification) -> () throws -> Void)] {
        return [
            ("test_customReflection", test_customReflection),
        ]
    }

    func test_customReflection() {
        let someName = "somenotifname"
        let targetObject = NSObject()
        let userInfo = ["hello": "world", "indexThis": 350] as [AnyHashable: Any]
        let notif = Notification(name: Notification.Name(rawValue: someName), object: targetObject, userInfo: userInfo)
        let mirror = notif.customMirror

        XCTAssertEqual(mirror.displayStyle, .class)
        XCTAssertNil(mirror.superclassMirror)

        var children = Array(mirror.children).makeIterator()
        let firstChild = children.next()
        let secondChild = children.next()
        let thirdChild = children.next()
        XCTAssertEqual(firstChild?.label, "name")
        XCTAssertEqual(firstChild?.value as? String, someName)

        XCTAssertEqual(secondChild?.label, "object")
        XCTAssertEqual(secondChild?.value as? NSObject, targetObject)

        XCTAssertEqual(thirdChild?.label, "userInfo")
        XCTAssertEqual((thirdChild?.value as? [AnyHashable: Any])?["hello"] as? String, "world")
        XCTAssertEqual((thirdChild?.value as? [AnyHashable: Any])?["indexThis"] as? Int, 350)

    }

}
