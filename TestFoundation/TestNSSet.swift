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



class TestNSSet : XCTestCase {
    
    static var allTests: [(String, (TestNSSet) -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("testInitWithSet", testInitWithSet),
            ("test_enumeration", test_enumeration),
            ("test_sequenceType", test_sequenceType),
            ("test_setOperations", test_setOperations),
            ("test_equality", test_equality),
            ("test_copying", test_copying),
            ("test_mutableCopying", test_mutableCopying),
            ("test_CountedSetBasicConstruction", test_CountedSetBasicConstruction),
            ("test_CountedSetObjectCount", test_CountedSetObjectCount),
            ("test_CountedSetAddObject", test_CountedSetAddObject),
            ("test_CountedSetRemoveObject", test_CountedSetRemoveObject),
            ("test_CountedSetCopying", test_CountedSetCopying)
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
        let set = NSMutableSet(array: ["foo", "bar"].bridge().bridge())
        set.union(["bar".bridge(), "baz".bridge()])
        XCTAssertTrue(set.isEqual(to: ["foo".bridge(), "bar".bridge(), "baz".bridge()]))
    }

    func test_equality() {
        let inputArray1 = ["this", "is", "a", "test", "of", "equality", "with", "strings"].bridge()
        let inputArray2 = ["this", "is", "a", "test", "of", "equality", "with", "objects"].bridge()
        let set1 = NSSet(array: inputArray1.bridge())
        let set2 = NSSet(array: inputArray1.bridge())
        let set3 = NSSet(array: inputArray2.bridge())

        XCTAssertTrue(set1 == set2)
        XCTAssertTrue(set1.isEqual(set2))
        XCTAssertTrue(set1.isEqual(to: set2.bridge()))
        XCTAssertEqual(set1.hash, set2.hash)
        XCTAssertEqual(set1.hashValue, set2.hashValue)

        XCTAssertFalse(set1 == set3)
        XCTAssertFalse(set1.isEqual(set3))
        XCTAssertFalse(set1.isEqual(to: set3.bridge()))

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
        XCTAssertTrue(type(of: setCopy2) === NSSet.self)
        XCTAssertFalse(setMutableCopy === setCopy2)
        for entry in setCopy2 {
            XCTAssertTrue(setMutableCopy.allObjects.bridge().indexOfObjectIdentical(to: entry) != NSNotFound)
        }
    }

    func test_mutableCopying() {
        let inputArray = ["this", "is", "a", "test", "of", "mutableCopy", "with", "strings"].bridge()
        let set = NSSet(array: inputArray.bridge())

        let setMutableCopy1 = set.mutableCopy() as! NSMutableSet
        XCTAssertTrue(type(of: setMutableCopy1) === NSMutableSet.self)
        XCTAssertFalse(set === setMutableCopy1)
        for entry in setMutableCopy1 {
            XCTAssertTrue(set.allObjects.bridge().indexOfObjectIdentical(to: entry) != NSNotFound)
        }

        let setMutableCopy2 = setMutableCopy1.mutableCopy() as! NSMutableSet
        XCTAssertTrue(type(of: setMutableCopy2) === NSMutableSet.self)
        XCTAssertFalse(setMutableCopy2 === setMutableCopy1)
        for entry in setMutableCopy2 {
            XCTAssertTrue(setMutableCopy1.allObjects.bridge().indexOfObjectIdentical(to: entry) != NSNotFound)
        }
    }

    func test_CountedSetBasicConstruction() {
        let v1 = "v1".bridge()
        let v2 = "v2".bridge()
        let v3asv1 = "v1".bridge()
        let set = NSCountedSet()
        let set2 = NSCountedSet(array: [v1, v1, v2,v3asv1])
        let set3 = NSCountedSet(set: [v1, v1, v2,v3asv1])
        let set4 = NSCountedSet(capacity: 4)

        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set2.count, 2)
        XCTAssertEqual(set3.count, 2)
        XCTAssertEqual(set4.count, 0)

    }

    func test_CountedSetObjectCount() {
        let v1 = "v1".bridge()
        let v2 = "v2".bridge()
        let v3asv1 = "v1".bridge()
        let set = NSCountedSet()
        let set2 = NSCountedSet(array: [v1, v1, v2,v3asv1])
        let set3 = NSCountedSet(set: [v1, v1, v2,v3asv1])

        XCTAssertEqual(set.countForObject(v1), 0)
        XCTAssertEqual(set2.countForObject(v1), 3)
        XCTAssertEqual(set2.countForObject(v2), 1)
        XCTAssertEqual(set2.countForObject(v3asv1), 3)
        XCTAssertEqual(set3.countForObject(v1), 1)
        XCTAssertEqual(set3.countForObject(v2), 1)
        XCTAssertEqual(set3.countForObject(v3asv1), 1)
    }

    func test_CountedSetAddObject() {
        let v1 = "v1".bridge()
        let v2 = "v2".bridge()
        let v3asv1 = "v1".bridge()
        let set = NSCountedSet(array: [v1, v1, v2])

        XCTAssertEqual(set.countForObject(v1), 2)
        XCTAssertEqual(set.countForObject(v2), 1)
        set.add(v3asv1)
        XCTAssertEqual(set.countForObject(v1), 3)
        set.addObjects(from: [v1,v2])
        XCTAssertEqual(set.countForObject(v1), 4)
        XCTAssertEqual(set.countForObject(v2), 2)
    }


    func test_CountedSetRemoveObject() {
        let v1 = "v1".bridge()
        let v2 = "v2".bridge()
        let set = NSCountedSet(array: [v1, v1, v2])

        XCTAssertEqual(set.countForObject(v1), 2)
        XCTAssertEqual(set.countForObject(v2), 1)
        set.remove(v2)
        XCTAssertEqual(set.countForObject(v2), 0)
        XCTAssertEqual(set.countForObject(v1), 2)
        set.remove(v2)
        XCTAssertEqual(set.countForObject(v2), 0)
        XCTAssertEqual(set.countForObject(v1), 2)
        set.removeAllObjects()
        XCTAssertEqual(set.countForObject(v2), 0)
        XCTAssertEqual(set.countForObject(v1), 0)
    }

    func test_CountedSetCopying() {
        let inputArray = ["this", "is", "a", "test", "of", "copy", "with", "strings"].bridge()

        let set = NSCountedSet(array: inputArray.bridge())
        let setCopy = set.copy() as! NSCountedSet
        XCTAssertFalse(set === setCopy)

        let setMutableCopy = set.mutableCopy() as! NSCountedSet
        XCTAssertFalse(set === setMutableCopy)
        XCTAssertTrue(type(of: setCopy) === NSCountedSet.self)
        XCTAssertTrue(type(of: setMutableCopy) === NSCountedSet.self)
        for entry in setCopy {
            XCTAssertTrue(setMutableCopy.allObjects.bridge().indexOfObjectIdentical(to: entry) != NSNotFound)
        }
    }

}
