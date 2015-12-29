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



class TestNSOrderedSet : XCTestCase {

    var allTests : [(String, () -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_Enumeration", test_Enumeration),
            ("test_Uniqueness", test_Uniqueness),
            ("test_ObjectAtIndex", test_ObjectAtIndex),
            ("test_ObjectsAtIndexes", test_ObjectsAtIndexes),
            ("test_GetObjects", test_GetObjects),
            ("test_FirstAndLastObjects", test_FirstAndLastObjects),
        ]
    }

    func test_BasicConstruction() {
        let set = NSOrderedSet()
        let set2 = NSOrderedSet(array: ["foo", "bar"].bridge().bridge())
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set2.count, 2)
    }

    func test_Enumeration() {
        let arr = ["foo", "bar", "bar"]
        let set = NSOrderedSet(array: arr.bridge().bridge())
        var index = 0
        for item in set {
            XCTAssertEqual(arr[index].bridge(), item as? NSString)
            index += 1
        }
    }

    func test_Uniqueness() {
        let set = NSOrderedSet(array: ["foo", "bar", "bar"].bridge().bridge())
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set.objectAtIndex(0) as? NSString, "foo")
        XCTAssertEqual(set.objectAtIndex(1) as? NSString, "bar")
    }

    func test_ObjectAtIndex() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz"].bridge().bridge())
        XCTAssertEqual(set.objectAtIndex(0) as? NSString, "foo")
        XCTAssertEqual(set.objectAtIndex(1) as? NSString, "bar")
        XCTAssertEqual(set.objectAtIndex(2) as? NSString, "baz")
    }

    func test_ObjectsAtIndexes() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz", "1", "2", "3"].bridge().bridge())
        let indexSet = NSMutableIndexSet()
        indexSet.addIndex(1)
        indexSet.addIndex(3)
        indexSet.addIndex(5)
        let objects = set.objectsAtIndexes(indexSet)
        XCTAssertEqual(objects[0] as? NSString, "bar")
        XCTAssertEqual(objects[1] as? NSString, "1")
        XCTAssertEqual(objects[2] as? NSString, "3")
    }

    func test_GetObjects() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz"].bridge().bridge())
        var objects = [AnyObject]()
        set.getObjects(&objects, range: NSMakeRange(1, 2))
        XCTAssertEqual(objects[0] as? NSString, "bar")
        XCTAssertEqual(objects[1] as? NSString, "baz")
    }

    func test_FirstAndLastObjects() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz"].bridge().bridge())
        XCTAssertEqual(set.firstObject as? NSString, "foo")
        XCTAssertEqual(set.lastObject as? NSString, "baz")
    }
}