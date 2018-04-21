// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSOrderedSet : XCTestCase {

    static var allTests: [(String, (TestNSOrderedSet) -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_Enumeration", test_Enumeration),
            ("test_Uniqueness", test_Uniqueness),
            ("test_reversedEnumeration", test_reversedEnumeration),
            ("test_reversedOrderedSet", test_reversedOrderedSet),
            ("test_reversedEmpty", test_reversedEmpty),
            ("test_ObjectAtIndex", test_ObjectAtIndex),
            ("test_ObjectsAtIndexes", test_ObjectsAtIndexes),
//            ("test_GetObjects", test_GetObjects),
            ("test_FirstAndLastObjects", test_FirstAndLastObjects),
            ("test_AddObject", test_AddObject),
            ("test_AddObjects", test_AddObjects),
            ("test_RemoveAllObjects", test_RemoveAllObjects),
            ("test_RemoveObject", test_RemoveObject),
            ("test_RemoveObjectAtIndex", test_RemoveObjectAtIndex),
            ("test_IsEqualToOrderedSet", test_IsEqualToOrderedSet),
            ("test_Subsets", test_Subsets),
            ("test_ReplaceObject", test_ReplaceObject),
            ("test_ExchangeObjects", test_ExchangeObjects),
            ("test_MoveObjects", test_MoveObjects),
            ("test_InsertObjects", test_InsertObjects),
            ("test_Insert", test_Insert),
            ("test_SetObjectAtIndex", test_SetObjectAtIndex),
            ("test_RemoveObjectsInRange", test_RemoveObjectsInRange),
            ("test_ReplaceObjectsAtIndexes", test_ReplaceObjectsAtIndexes),
            ("test_Intersection", test_Intersection),
            ("test_Subtraction", test_Subtraction),
            ("test_Union", test_Union),
            ("test_Initializers", test_Initializers),
            ("test_Sorting", test_Sorting),
            ("test_reversedEnumerationMutable", test_reversedEnumerationMutable),
            ("test_reversedOrderedSetMutable", test_reversedOrderedSetMutable),
        ]
    }

    func test_BasicConstruction() {
        let set = NSOrderedSet()
        let set2 = NSOrderedSet(array: ["foo", "bar"])
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set2.count, 2)
    }

    func test_Enumeration() {
        let arr = ["foo", "bar", "bar"]
        let set = NSOrderedSet(array: arr)
        var index = 0
        for item in set {
            XCTAssertEqual(arr[index], item as? String)
            index += 1
        }
    }

    func test_Uniqueness() {
        let set = NSOrderedSet(array: ["foo", "bar", "bar"])
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set.object(at: 0) as? String, "foo")
        XCTAssertEqual(set.object(at: 1) as? String, "bar")
    }

    func test_reversedEnumeration() {
        let arr = ["foo", "bar", "baz"]
        let set = NSOrderedSet(array: arr)
        var index = set.count - 1
        let revSet = set.reverseObjectEnumerator()
        for item in revSet {
            XCTAssertEqual(set.object(at: index) as? String, item as? String)
            index -= 1
        }
    }

    func test_reversedOrderedSet() {
        let days = ["monday", "tuesday", "wednesday", "thursday", "friday"]
        let work = NSOrderedSet(array: days)
        let krow = work.reversed
        var index = work.count - 1
        for item in krow {
            XCTAssertEqual(work.object(at: index) as? String, item as? String)
           index -= 1
        }
    }

    func test_reversedEmpty() {
        let set = NSOrderedSet(array: [])
        let reversedEnum = set.reverseObjectEnumerator()
        XCTAssertNil(reversedEnum.nextObject())
        let reversedSet = set.reversed
        XCTAssertNil(reversedSet.firstObject)
    }

    func test_ObjectAtIndex() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz"])
        XCTAssertEqual(set.object(at: 0) as? String, "foo")
        XCTAssertEqual(set.object(at: 1) as? String, "bar")
        XCTAssertEqual(set.object(at: 2) as? String, "baz")
    }

    func test_ObjectsAtIndexes() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz", "1", "2", "3"])
        var indexSet = IndexSet()
        indexSet.insert(1)
        indexSet.insert(3)
        indexSet.insert(5)
        let objects = set.objects(at: indexSet)
        XCTAssertEqual(objects[0] as? String, "bar")
        XCTAssertEqual(objects[1] as? String, "1")
        XCTAssertEqual(objects[2] as? String, "3")
    }

//    func test_GetObjects() {
//        let set = NSOrderedSet(array: ["foo", "bar", "baz"])
//        var objects = [Any]()
//        set.getObjects(&objects, range: NSRange(location: 1, length: 2))
//        XCTAssertEqual(objects[0] as? NSString, "bar")
//        XCTAssertEqual(objects[1] as? NSString, "baz")
//    }

    func test_FirstAndLastObjects() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz"])
        XCTAssertEqual(set.firstObject as? String, "foo")
        XCTAssertEqual(set.lastObject as? String, "baz")
    }

    func test_AddObject() {
        let set = NSMutableOrderedSet()
        set.add("1")
        set.add("2")
        XCTAssertEqual(set[0] as? String, "1")
        XCTAssertEqual(set[1] as? String, "2")
    }

    func test_AddObjects() {
        let set = NSMutableOrderedSet()
        set.addObjects(from: ["foo", "bar", "baz"])
        XCTAssertEqual(set.object(at: 0) as? String, "foo")
        XCTAssertEqual(set.object(at: 1) as? String, "bar")
        XCTAssertEqual(set.object(at: 2) as? String, "baz")
    }

    func test_RemoveAllObjects() {
        let set = NSMutableOrderedSet()
        set.addObjects(from: ["foo", "bar", "baz"])
        XCTAssertEqual(set.index(of: "foo"), 0)
        set.removeAllObjects()
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set.index(of: "foo"), NSNotFound)
    }

    func test_RemoveObject() {
        let set = NSMutableOrderedSet()
        set.addObjects(from: ["foo", "bar", "baz"])
        set.remove("bar")
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set.index(of: "baz"), 1)
    }

    func test_RemoveObjectAtIndex() {
        let set = NSMutableOrderedSet()
        set.addObjects(from: ["foo", "bar", "baz"])
        set.removeObject(at: 1)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set.index(of: "baz"), 1)
    }

    func test_IsEqualToOrderedSet() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz"])
        let otherSet = NSOrderedSet(array: ["foo", "bar", "baz"])
        let otherOtherSet = NSOrderedSet(array: ["foo", "bar", "123"])
        XCTAssert(set.isEqual(to: otherSet))
        XCTAssertFalse(set.isEqual(to: otherOtherSet))
    }

    func test_Subsets() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz"])
        let otherOrderedSet = NSOrderedSet(array: ["foo", "bar"])
        let otherSet = Set<AnyHashable>(["foo", "baz"])
        let otherOtherSet = Set<AnyHashable>(["foo", "bar", "baz", "123"])
        XCTAssert(otherOrderedSet.isSubset(of: set))
        XCTAssertFalse(set.isSubset(of: otherOrderedSet))
        XCTAssertFalse(set.isSubset(of: otherSet))
        XCTAssert(set.isSubset(of: otherOtherSet))
    }

    func test_ReplaceObject() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo", "bar", "baz")
        set.replaceObject(at: 1, with: "123")
        set[2] = "456"
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0] as? String, "foo")
        XCTAssertEqual(set[1] as? String, "123")
        XCTAssertEqual(set[2] as? String, "456")
    }

    func test_ExchangeObjects() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo", "bar", "baz")
        set.exchangeObject(at: 0, withObjectAt: 2)
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0] as? String, "baz")
        XCTAssertEqual(set[1] as? String, "bar")
        XCTAssertEqual(set[2] as? String, "foo")
    }

    func test_MoveObjects() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo", "bar", "baz", "123", "456")
        var indexes = IndexSet()
        indexes.insert(1)
        indexes.insert(2)
        indexes.insert(4)
        set.moveObjects(at: indexes, to: 0)
        XCTAssertEqual(set.count, 5)
        XCTAssertEqual(set[0] as? String, "bar")
        XCTAssertEqual(set[1] as? String, "baz")
        XCTAssertEqual(set[2] as? String, "456")
        XCTAssertEqual(set[3] as? String, "foo")
        XCTAssertEqual(set[4] as? String, "123")
    }

    func test_InsertObjects() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo", "bar", "baz")
        var indexes = IndexSet()
        indexes.insert(1)
        indexes.insert(3)
        set.insert(["123", "456"], at: indexes)
        XCTAssertEqual(set.count, 5)
        XCTAssertEqual(set[0] as? String, "foo")
        XCTAssertEqual(set[1] as? String, "123")
        XCTAssertEqual(set[2] as? String, "bar")
        XCTAssertEqual(set[3] as? String, "456")
        XCTAssertEqual(set[4] as? String, "baz")
    }

    func test_Insert() {
        let set = NSMutableOrderedSet()
        set.insert("foo", at: 0)
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set[0] as? String, "foo")
        set.insert("bar", at: 1)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[1] as? String, "bar")
    }

    func test_SetObjectAtIndex() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo", "bar", "baz")
        set.setObject("123", at: 1)
        XCTAssertEqual(set[0] as? String, "foo")
        XCTAssertEqual(set[1] as? String, "123")
        XCTAssertEqual(set[2] as? String, "baz")
        set.setObject("456", at: 3)
        XCTAssertEqual(set[3] as? String, "456")
    }

    func test_RemoveObjectsInRange() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo", "bar", "baz", "123", "456")
        set.removeObjects(in: NSRange(location: 1, length: 2))
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0] as? String, "foo")
        XCTAssertEqual(set[1] as? String, "123")
        XCTAssertEqual(set[2] as? String, "456")
    }

    func test_ReplaceObjectsAtIndexes() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo", "bar", "baz")
        var indexes = IndexSet()
        indexes.insert(0)
        indexes.insert(2)
        set.replaceObjects(at: indexes, with: ["a", "b"])
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0] as? String, "a")
        XCTAssertEqual(set[1] as? String, "bar")
        XCTAssertEqual(set[2] as? String, "b")
    }

    func test_Intersection() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo", "bar", "baz")
        let otherSet = NSOrderedSet(array: ["foo", "baz"])
        XCTAssert(set.intersects(otherSet))
        let otherOtherSet = Set<AnyHashable>(["foo", "123"])
        XCTAssert(set.intersectsSet(otherOtherSet))
        set.intersect(otherSet)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[0] as? String, "foo")
        XCTAssertEqual(set[1] as? String, "baz")
        set.intersectSet(otherOtherSet)
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set[0] as? String, "foo")

        let nonIntersectingSet = Set<AnyHashable>(["asdf"])
        XCTAssertFalse(set.intersectsSet(nonIntersectingSet))
    }

    func test_Subtraction() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo", "bar", "baz")
        let otherSet = NSOrderedSet(array: ["baz"])
        let otherOtherSet = Set<AnyHashable>(["foo"])
        set.minus(otherSet)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[0] as? String, "foo")
        XCTAssertEqual(set[1] as? String, "bar")
        set.minusSet(otherOtherSet)
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set[0] as? String, "bar")
    }

    func test_Union() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo", "bar", "baz")
        let otherSet = NSOrderedSet(array: ["123", "baz"])
        let otherOtherSet = Set<AnyHashable>(["foo", "456"])
        set.union(otherSet)
        XCTAssertEqual(set.count, 4)
        XCTAssertEqual(set[0] as? String, "foo")
        XCTAssertEqual(set[1] as? String, "bar")
        XCTAssertEqual(set[2] as? String, "baz")
        XCTAssertEqual(set[3] as? String, "123")
        set.unionSet(otherOtherSet)
        XCTAssertEqual(set.count, 5)
        XCTAssertEqual(set[4] as? String, "456")
    }

    func test_Initializers() {
        let copyableObject = NSObject()
        let set = NSMutableOrderedSet(arrayLiteral: copyableObject, "bar", "baz")
        let newSet = NSOrderedSet(orderedSet: set)
        XCTAssert(newSet.isEqual(to: set))
//        XCTAssert(set[0] === newSet[0])

        let unorderedSet = Set<AnyHashable>(["foo", "bar", "baz"])
        let newSetFromUnorderedSet = NSOrderedSet(set: unorderedSet)
        XCTAssertEqual(newSetFromUnorderedSet.count, 3)
        XCTAssert(newSetFromUnorderedSet.contains("foo"))
    }

    func test_Sorting() {
        let set = NSMutableOrderedSet(arrayLiteral: "a", "d", "c", "b")
        set.sort(options: []) { lhs, rhs in
            if let lhs = lhs as? String, let rhs = rhs as? String {
                return lhs.compare(rhs)
            }
            return .orderedSame
        }
        XCTAssertEqual(set[0] as? String, "a")
        XCTAssertEqual(set[1] as? String, "b")
        XCTAssertEqual(set[2] as? String, "c")
        XCTAssertEqual(set[3] as? String, "d")

        set.sortRange(NSRange(location: 1, length: 2), options: []) { lhs, rhs in
            if let lhs = lhs as? String, let rhs = rhs as? String {
                return rhs.compare(lhs)
            }
            return .orderedSame
        }
        XCTAssertEqual(set[0] as? String, "a")
        XCTAssertEqual(set[1] as? String, "c")
        XCTAssertEqual(set[2] as? String, "b")
        XCTAssertEqual(set[3] as? String, "d")
    }

    func test_reversedEnumerationMutable() {
        let arr = ["foo", "bar", "baz"]
        let set = NSMutableOrderedSet()
        set.addObjects(from: arr)

        set.add("jazz")
        var index = set.count - 1
        var revSet = set.reverseObjectEnumerator()
        for item in revSet {
            XCTAssertEqual(set.object(at: index) as? String, item as? String)
            index -= 1
        }

        set.remove("jazz")
        index = set.count - 1
        revSet = set.reverseObjectEnumerator()
        for item in revSet {
            XCTAssertEqual(set.object(at: index) as? String, item as? String)
            index -= 1
        }


    }

    func test_reversedOrderedSetMutable() {
        let days = ["monday", "tuesday", "wednesday", "thursday", "friday"]
        let work =  NSMutableOrderedSet()
        work.addObjects(from: days)
        var krow = work.reversed
        XCTAssertEqual(work.firstObject as? String, krow.lastObject as? String)
        XCTAssertEqual(work.lastObject as? String, krow.firstObject as? String)

        work.add("saturday")
        krow = work.reversed
        XCTAssertEqual(work.firstObject as? String, krow.lastObject as? String)
        XCTAssertEqual(work.lastObject as? String, krow.firstObject as? String)
    }

}
