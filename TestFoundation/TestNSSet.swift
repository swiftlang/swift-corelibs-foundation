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



class TestNSSet : XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("testInitWithSet", testInitWithSet),
            ("test_enumeration", test_enumeration),
            ("test_sequenceType", test_sequenceType),
            ("test_setOperations", test_setOperations),
            ("test_equality", test_equality),
            ("test_copying", test_copying),
            ("test_mutableCopying", test_mutableCopying),
        ]
    }
    
    func test_BasicConstruction() {
        let set = NSSet()
        let set2 = NSSet(array: ["foo", "bar"].bridge().bridge())
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set2.count, 2)
    }

    func testInitWithSet() {
        let genres: Set<NSObject> = ["Rock".bridge(), "Classical".bridge(), "Hip hop".bridge()]
        let set1 = NSSet(set: genres)
        let set2 = NSSet(set: genres, copyItems: false)
        XCTAssertEqual(set1.count, 3)
        XCTAssertEqual(set2.count, 3)
        XCTAssertEqual(set1, set2)

        let set3 = NSSet(set: genres, copyItems: true)
        XCTAssertEqual(set3.count, 3)
        XCTAssertEqual(set3, set2)
    }
    
    func test_enumeration() {
        let set = NSSet(array: ["foo", "bar", "baz"].bridge().bridge())
        let e = set.objectEnumerator()
        var result = Set<String>()
        result.insert((e.nextObject()! as! NSString).bridge())
        result.insert((e.nextObject()! as! NSString).bridge())
        result.insert((e.nextObject()! as! NSString).bridge())
        XCTAssertEqual(result, Set(["foo", "bar", "baz"]))
        
        let empty = NSSet().objectEnumerator()
        XCTAssertNil(empty.nextObject())
        XCTAssertNil(empty.nextObject())
    }
    
    func test_sequenceType() {
        let set = NSSet(array: ["foo", "bar", "baz"].bridge().bridge())
        var res = Set<String>()
        for obj in set {
            res.insert((obj as! NSString).bridge())
        }
        XCTAssertEqual(res, Set(["foo", "bar", "baz"]))
    }
    
    func test_setOperations() {
        // TODO: This fails because hashValue and == use NSObject's implementaitons, which don't have the right semantics
//        let set = NSMutableSet(array: ["foo", "bar"])
//        set.unionSet(["bar", "baz"])
//        XCTAssertTrue(set.isEqualToSet(["foo", "bar", "baz"]))
    }

    func test_equality() {
        let inputArray1 = ["this", "is", "a", "test", "of", "equality", "with", "strings"].bridge()
        let inputArray2 = ["this", "is", "a", "test", "of", "equality", "with", "objects"].bridge()
        let set1 = NSSet(array: inputArray1.bridge())
        let set2 = NSSet(array: inputArray1.bridge())
        let set3 = NSSet(array: inputArray2.bridge())

        XCTAssertTrue(set1 == set2)
        XCTAssertTrue(set1.isEqual(set2))
        XCTAssertTrue(set1.isEqualToSet(set2.bridge()))
        XCTAssertEqual(set1.hash, set2.hash)
        XCTAssertEqual(set1.hashValue, set2.hashValue)

        XCTAssertFalse(set1 == set3)
        XCTAssertFalse(set1.isEqual(set3))
        XCTAssertFalse(set1.isEqualToSet(set3.bridge()))

        XCTAssertFalse(set1.isEqual(nil))
        XCTAssertFalse(set1.isEqual(NSObject()))
    }

    func test_copying() {
        let inputArray = ["this", "is", "a", "test", "of", "copy", "with", "strings"].bridge()
        
        let set = NSSet(array: inputArray.bridge())
        let setCopy1 = set.copy() as! NSSet
        XCTAssertTrue(set === setCopy1)

        let setMutableCopy = set.mutableCopy() as! NSMutableSet
        let setCopy2 = setMutableCopy.copy() as! NSSet
        XCTAssertTrue(setCopy2.dynamicType === NSSet.self)
        XCTAssertFalse(setMutableCopy === setCopy2)
        for entry in setCopy2 {
            XCTAssertTrue(setMutableCopy.allObjects.bridge().indexOfObjectIdenticalTo(entry) != NSNotFound)
        }
    }

    func test_mutableCopying() {
        let inputArray = ["this", "is", "a", "test", "of", "mutableCopy", "with", "strings"].bridge()
        let set = NSSet(array: inputArray.bridge())

        let setMutableCopy1 = set.mutableCopy() as! NSMutableSet
        XCTAssertTrue(setMutableCopy1.dynamicType === NSMutableSet.self)
        XCTAssertFalse(set === setMutableCopy1)
        for entry in setMutableCopy1 {
            XCTAssertTrue(set.allObjects.bridge().indexOfObjectIdenticalTo(entry) != NSNotFound)
        }

        let setMutableCopy2 = setMutableCopy1.mutableCopy() as! NSMutableSet
        XCTAssertTrue(setMutableCopy2.dynamicType === NSMutableSet.self)
        XCTAssertFalse(setMutableCopy2 === setMutableCopy1)
        for entry in setMutableCopy2 {
            XCTAssertTrue(setMutableCopy1.allObjects.bridge().indexOfObjectIdenticalTo(entry) != NSNotFound)
        }
    }

}
