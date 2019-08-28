// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSSet : XCTestCase {
    func test_BasicConstruction() {
        let set = NSSet()
        let set2 = NSSet(array: ["foo", "bar"])
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set2.count, 2)

        let set3 = NSMutableSet(capacity: 3)
        set3.add(1)
        set3.add("foo")
        let set4 = NSSet(set: set3)
        XCTAssertEqual(set3, set4)
        set3.remove(1)
        XCTAssertNotEqual(set3, set4)

        let set5 = NSMutableSet(set: set3)
        XCTAssertEqual(set5, set3)
        set5.add(2)
        XCTAssertNotEqual(set5, set3)
    }

    func testInitWithSet() {
        let genres: Set<AnyHashable> = ["Rock", "Classical", "Hip hop"]
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
        let set = NSSet(array: ["foo", "bar", "baz"])
        let e = set.objectEnumerator()
        var result = Set<String>()
        result.insert((e.nextObject()! as! String))
        result.insert((e.nextObject()! as! String))
        result.insert((e.nextObject()! as! String))
        XCTAssertEqual(result, Set(["foo", "bar", "baz"]))
        
        let empty = NSSet().objectEnumerator()
        XCTAssertNil(empty.nextObject())
        XCTAssertNil(empty.nextObject())
    }
    
    func test_sequenceType() {
        let set = NSSet(array: ["foo", "bar", "baz"])
        var res = Set<String>()
        for obj in set {
            res.insert((obj as! String))
        }
        XCTAssertEqual(res, Set(["foo", "bar", "baz"]))
    }
    
    func test_setOperations() {
        let set = NSMutableSet(array: ["foo", "bar"])
        set.union(["bar", "baz"])
        XCTAssertTrue(set.isEqual(to: ["foo", "bar", "baz"]))
    }

    func test_equality() {
        let inputArray1 = ["this", "is", "a", "test", "of", "equality", "with", "strings"]
        let inputArray2 = ["this", "is", "a", "test", "of", "equality", "with", "objects"]
        let set1 = NSSet(array: inputArray1)
        let set2 = NSSet(array: inputArray1)
        let set3 = NSSet(array: inputArray2)

        XCTAssertTrue(set1 == set2)
        XCTAssertTrue(set1.isEqual(set2))
        XCTAssertTrue(set1.isEqual(to: Set(inputArray1)))
        XCTAssertEqual(set1.hash, set2.hash)
        XCTAssertEqual(set1.hashValue, set2.hashValue)

        XCTAssertFalse(set1 == set3)
        XCTAssertFalse(set1.isEqual(set3))
        XCTAssertFalse(set1.isEqual(to: Set(inputArray2)))

        XCTAssertFalse(set1.isEqual(nil))
        XCTAssertFalse(set1.isEqual(NSObject()))
    }

    func test_copying() {
        let inputArray = ["this", "is", "a", "test", "of", "copy", "with", "strings"]
        
        let set = NSSet(array: inputArray)
        let setCopy1 = set.copy() as! NSSet
        XCTAssertTrue(set === setCopy1)

        let setMutableCopy = set.mutableCopy() as! NSMutableSet
        let setCopy2 = setMutableCopy.copy() as! NSSet
        XCTAssertTrue(type(of: setCopy2) === NSSet.self)
        XCTAssertFalse(setMutableCopy === setCopy2)
        for entry in setCopy2 {
            XCTAssertTrue(NSArray(array: setMutableCopy.allObjects).index(of: entry) != NSNotFound)
        }
    }

    func test_mutableCopying() {
        let inputArray = ["this", "is", "a", "test", "of", "mutableCopy", "with", "strings"]
        let set = NSSet(array: inputArray)

        let setMutableCopy1 = set.mutableCopy() as! NSMutableSet
        XCTAssertTrue(type(of: setMutableCopy1) === NSMutableSet.self)
        XCTAssertFalse(set === setMutableCopy1)
        for entry in setMutableCopy1 {
            XCTAssertTrue(NSArray(array: set.allObjects).index(of: entry) != NSNotFound)
        }

        let setMutableCopy2 = setMutableCopy1.mutableCopy() as! NSMutableSet
        XCTAssertTrue(type(of: setMutableCopy2) === NSMutableSet.self)
        XCTAssertFalse(setMutableCopy2 === setMutableCopy1)
        for entry in setMutableCopy2 {
            XCTAssertTrue(NSArray(array: setMutableCopy1.allObjects).index(of: entry) != NSNotFound)
        }
    }

    func test_CountedSetBasicConstruction() {
        let v1 = "v1"
        let v2 = "v2"
        let v3asv1 = "v1"
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
        let v1 = "v1"
        let v2 = "v2"
        let v3asv1 = "v1"
        let set = NSCountedSet()
        let set2 = NSCountedSet(array: [v1, v1, v2,v3asv1])
        let set3 = NSCountedSet(set: [v1, v1, v2,v3asv1])

        XCTAssertEqual(set.count(for: v1), 0)
        XCTAssertEqual(set2.count(for: v1), 3)
        XCTAssertEqual(set2.count(for: v2), 1)
        XCTAssertEqual(set2.count(for: v3asv1), 3)
        XCTAssertEqual(set3.count(for: v1), 1)
        XCTAssertEqual(set3.count(for: v2), 1)
        XCTAssertEqual(set3.count(for: v3asv1), 1)
    }

    func test_CountedSetAddObject() {
        let v1 = "v1"
        let v2 = "v2"
        let v3asv1 = "v1"
        let set = NSCountedSet(array: [v1, v1, v2])

        XCTAssertEqual(set.count(for: v1), 2)
        XCTAssertEqual(set.count(for: v2), 1)
        set.add(v3asv1)
        XCTAssertEqual(set.count(for: v1), 3)
        set.addObjects(from: [v1,v2])
        XCTAssertEqual(set.count(for: v1), 4)
        XCTAssertEqual(set.count(for: v2), 2)
    }


    func test_CountedSetRemoveObject() {
        let v1 = "v1"
        let v2 = "v2"
        let set = NSCountedSet(array: [v1, v1, v2])

        XCTAssertEqual(set.count(for: v1), 2)
        XCTAssertEqual(set.count(for: v2), 1)
        set.remove(v2)
        XCTAssertEqual(set.count(for: v2), 0)
        XCTAssertEqual(set.count(for: v1), 2)
        set.remove(v2)
        XCTAssertEqual(set.count(for: v2), 0)
        XCTAssertEqual(set.count(for: v1), 2)
        set.removeAllObjects()
        XCTAssertEqual(set.count(for: v2), 0)
        XCTAssertEqual(set.count(for: v1), 0)
    }

    func test_CountedSetCopying() {
        let inputArray = ["this", "is", "a", "test", "of", "copy", "with", "strings"]

        let set = NSCountedSet(array: inputArray)
        let setCopy = set.copy() as! NSCountedSet
        XCTAssertFalse(set === setCopy)

        let setMutableCopy = set.mutableCopy() as! NSCountedSet
        XCTAssertFalse(set === setMutableCopy)
        XCTAssertTrue(type(of: setCopy) === NSCountedSet.self)
        XCTAssertTrue(type(of: setMutableCopy) === NSCountedSet.self)
        for entry in setCopy {
            XCTAssertTrue(NSArray(array: setMutableCopy.allObjects).index(of: entry) != NSNotFound)
        }
    }
    
    func test_mutablesetWithDictionary() {
        let aSet = NSMutableSet()
        let dictionary = NSMutableDictionary()
        let key = NSString(string: "Hello")
        aSet.add(["world": "again"])
        dictionary.setObject(aSet, forKey: key)
        XCTAssertNotNil(dictionary.description) //should not crash
    }

    func test_Subsets() {
        let set = NSSet(array: ["foo", "bar", "baz"])
        let otherSet = NSSet(array: ["foo", "bar"])
        let otherOtherSet = Set<AnyHashable>(["foo", "bar", "baz", "123"])
        let newSet = Set<AnyHashable>(["foo", "bin"])
        XCTAssert(otherSet.isSubset(of: set as! Set<AnyHashable>))
        XCTAssertFalse(set.isSubset(of: otherSet as! Set<AnyHashable>))
        XCTAssert(set.isSubset(of: otherOtherSet))
        XCTAssert(otherSet.isSubset(of: otherOtherSet))
        XCTAssertFalse(newSet.isSubset(of: otherSet as! Set<AnyHashable>))
    }
    
    func test_description() {
        let array = NSArray(array: ["array_element1", "arrayElement2", "", "!@#$%^&*()", "a+b"])
        let dictionary = NSDictionary(dictionary: ["key1": "value1", "key2": "value2"])
        let innerSet = NSSet(array: [4444, 5555])
        let set: NSSet = NSSet(array: [array, dictionary, innerSet, 1111, 2222, 3333])
        
        let description = NSString(string: set.description)

        XCTAssertTrue(description.hasPrefix("{("))
        XCTAssertTrue(description.hasSuffix(")}"))
        XCTAssertTrue(description.contains("        (\n        \"array_element1\",\n        arrayElement2,\n        \"\",\n        \"!@#$%^&*()\",\n        \"a+b\"\n    )"))
        XCTAssertTrue(description.contains("        key1 = value1"))
        XCTAssertTrue(description.contains("        key2 = value2"))
        XCTAssertTrue(description.contains("        4444"))
        XCTAssertTrue(description.contains("        5555"))
        XCTAssertTrue(description.contains("    1111"))
        XCTAssertTrue(description.contains("    2222"))
        XCTAssertTrue(description.contains("    3333"))
    }
    
    let setFixtures = [
        Fixtures.setOfNumbers,
        Fixtures.setEmpty,
    ]
    
    let mutableSetFixtures = [
        Fixtures.mutableSetOfNumbers,
        Fixtures.mutableSetEmpty,
    ]
    
    let countedSetFixtures = [
        Fixtures.countedSetOfNumbersAppearingOnce,
        Fixtures.countedSetOfNumbersAppearingSeveralTimes,
        Fixtures.countedSetEmpty,
    ]
    
    func test_codingRoundtrip() throws {
        for fixture in setFixtures {
            try fixture.assertValueRoundtripsInCoder()
        }
        for fixture in mutableSetFixtures {
            try fixture.assertValueRoundtripsInCoder()
        }
        for fixture in countedSetFixtures {
            try fixture.assertValueRoundtripsInCoder()
        }
    }
    
    func test_loadedValuesMatch() throws {
        for fixture in setFixtures {
            try fixture.assertLoadedValuesMatch()
        }
        for fixture in mutableSetFixtures {
            try fixture.assertLoadedValuesMatch()
        }
        for fixture in countedSetFixtures {
            try fixture.assertLoadedValuesMatch()
        }
    }
    
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
            ("test_CountedSetCopying", test_CountedSetCopying),
            ("test_mutablesetWithDictionary", test_mutablesetWithDictionary),
            ("test_Subsets", test_Subsets),
            ("test_description", test_description),
            ("test_codingRoundtrip", test_codingRoundtrip),
            ("test_loadedValuesMatch", test_loadedValuesMatch),
        ]
    }
    
}
