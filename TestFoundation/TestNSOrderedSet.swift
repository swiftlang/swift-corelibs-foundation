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

    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_Enumeration", test_Enumeration),
            ("test_Uniqueness", test_Uniqueness),
            ("test_ObjectAtIndex", test_ObjectAtIndex),
            ("test_ObjectsAtIndexes", test_ObjectsAtIndexes),
            ("test_GetObjects", test_GetObjects),
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
            ("test_InserObjects", test_InsertObjects),
            ("test_SetObjectAtIndex", test_SetObjectAtIndex),
            ("test_RemoveObjectsInRange", test_RemoveObjectsInRange),
            ("test_ReplaceObjectsAtIndexes", test_ReplaceObjectsAtIndexes),
            ("test_Intersection", test_Intersection),
            ("test_Subtraction", test_Subtraction),
            ("test_Union", test_Union),
            ("test_Initializers", test_Initializers),
            ("test_Sorting", test_Sorting),
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

    func test_AddObject() {
        let set = NSMutableOrderedSet()
        set.addObject("1".bridge())
        set.addObject("2".bridge())
        XCTAssertEqual(set[0] as? NSString, "1")
        XCTAssertEqual(set[1] as? NSString, "2")
    }

    func test_AddObjects() {
        let set = NSMutableOrderedSet()
        set.addObjectsFromArray(["foo", "bar", "baz"].bridge().bridge())
        XCTAssertEqual(set.objectAtIndex(0) as? NSString, "foo")
        XCTAssertEqual(set.objectAtIndex(1) as? NSString, "bar")
        XCTAssertEqual(set.objectAtIndex(2) as? NSString, "baz")
    }

    func test_RemoveAllObjects() {
        let set = NSMutableOrderedSet()
        set.addObjectsFromArray(["foo", "bar", "baz"].bridge().bridge())
        XCTAssertEqual(set.indexOfObject("foo" as NSString), 0)
        set.removeAllObjects()
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set.indexOfObject("foo" as NSString), NSNotFound)
    }

    func test_RemoveObject() {
        let set = NSMutableOrderedSet()
        set.addObjectsFromArray(["foo", "bar", "baz"].bridge().bridge())
        set.removeObject("bar" as NSString)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set.indexOfObject("baz" as NSString), 1)
    }

    func test_RemoveObjectAtIndex() {
        let set = NSMutableOrderedSet()
        set.addObjectsFromArray(["foo", "bar", "baz"].bridge().bridge())
        set.removeObjectAtIndex(1)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set.indexOfObject("baz" as NSString), 1)
    }

    func test_IsEqualToOrderedSet() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz"].bridge().bridge())
        let otherSet = NSOrderedSet(array: ["foo", "bar", "baz"].bridge().bridge())
        let otherOtherSet = NSOrderedSet(array: ["foo", "bar", "123"].bridge().bridge())
        XCTAssert(set.isEqualToOrderedSet(otherSet))
        XCTAssertFalse(set.isEqualToOrderedSet(otherOtherSet))
    }

    func test_Subsets() {
        let set = NSOrderedSet(array: ["foo", "bar", "baz"].bridge().bridge())
        let otherOrderedSet = NSOrderedSet(array: ["foo", "bar"].bridge().bridge())
        let otherSet = Set<NSObject>(["foo" as NSString, "baz" as NSString])
        let otherOtherSet = Set<NSObject>(["foo".bridge(), "bar".bridge(), "baz".bridge(), "123".bridge()])
        XCTAssert(otherOrderedSet.isSubsetOfOrderedSet(set))
        XCTAssertFalse(set.isSubsetOfOrderedSet(otherOrderedSet))
        XCTAssertFalse(set.isSubsetOfSet(otherSet))
        XCTAssert(set.isSubsetOfSet(otherOtherSet))
    }

    func test_ReplaceObject() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo".bridge(), "bar".bridge(), "baz".bridge())
        set.replaceObjectAtIndex(1, withObject: "123".bridge())
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0] as? NSString, "foo")
        XCTAssertEqual(set[1] as? NSString, "123")
        XCTAssertEqual(set[2] as? NSString, "baz")
    }

    func test_ExchangeObjects() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo".bridge(), "bar".bridge(), "baz".bridge())
        set.exchangeObjectAtIndex(0, withObjectAtIndex: 2)
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0] as? NSString, "baz")
        XCTAssertEqual(set[1] as? NSString, "bar")
        XCTAssertEqual(set[2] as? NSString, "foo")
    }

    func test_MoveObjects() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo".bridge(), "bar".bridge(), "baz".bridge(), "123".bridge(), "456".bridge())
        let indexes = NSMutableIndexSet()
        indexes.addIndex(1)
        indexes.addIndex(2)
        indexes.addIndex(4)
        set.moveObjectsAtIndexes(indexes, toIndex: 0)
        XCTAssertEqual(set.count, 5)
        XCTAssertEqual(set[0] as? NSString, "bar")
        XCTAssertEqual(set[1] as? NSString, "baz")
        XCTAssertEqual(set[2] as? NSString, "456")
        XCTAssertEqual(set[3] as? NSString, "foo")
        XCTAssertEqual(set[4] as? NSString, "123")
    }

    func test_InsertObjects() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo".bridge(), "bar".bridge(), "baz".bridge())
        let indexes = NSMutableIndexSet()
        indexes.addIndex(1)
        indexes.addIndex(3)
        set.insertObjects(["123".bridge(), "456".bridge()], atIndexes: indexes)
        XCTAssertEqual(set.count, 5)
        XCTAssertEqual(set[0] as? NSString, "foo")
        XCTAssertEqual(set[1] as? NSString, "123")
        XCTAssertEqual(set[2] as? NSString, "bar")
        XCTAssertEqual(set[3] as? NSString, "456")
        XCTAssertEqual(set[4] as? NSString, "baz")
    }

    func test_SetObjectAtIndex() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo".bridge(), "bar".bridge(), "baz".bridge())
        set.setObject("123".bridge(), atIndex: 1)
        XCTAssertEqual(set[0] as? NSString, "foo")
        XCTAssertEqual(set[1] as? NSString, "123")
        XCTAssertEqual(set[2] as? NSString, "baz")
        set.setObject("456".bridge(), atIndex: 3)
        XCTAssertEqual(set[3] as? NSString, "456")
    }

    func test_RemoveObjectsInRange() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo".bridge(), "bar".bridge(), "baz".bridge(), "123".bridge(), "456".bridge())
        set.removeObjectsInRange(NSMakeRange(1, 2))
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0] as? NSString, "foo")
        XCTAssertEqual(set[1] as? NSString, "123")
        XCTAssertEqual(set[2] as? NSString, "456")
    }

    func test_ReplaceObjectsAtIndexes() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo".bridge(), "bar".bridge(), "baz".bridge())
        let indexes = NSMutableIndexSet()
        indexes.addIndex(0)
        indexes.addIndex(2)
        set.replaceObjectsAtIndexes(indexes, withObjects: ["a".bridge(), "b".bridge()])
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set[0] as? NSString, "a")
        XCTAssertEqual(set[1] as? NSString, "bar")
        XCTAssertEqual(set[2] as? NSString, "b")
    }

    func test_Intersection() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo".bridge(), "bar".bridge(), "baz".bridge())
        let otherSet = NSOrderedSet(array: ["foo", "baz"].bridge().bridge())
        XCTAssert(set.intersectsOrderedSet(otherSet))
        let otherOtherSet = Set<NSObject>(["foo".bridge(), "123".bridge()])
        XCTAssert(set.intersectsSet(otherOtherSet))
        set.intersectOrderedSet(otherSet)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[0] as? NSString, "foo")
        XCTAssertEqual(set[1] as? NSString, "baz")
        set.intersectSet(otherOtherSet)
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set[0] as? NSString, "foo")

        let nonIntersectingSet = Set<NSObject>(["asdf".bridge()])
        XCTAssertFalse(set.intersectsSet(nonIntersectingSet))
    }

    func test_Subtraction() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo".bridge(), "bar".bridge(), "baz".bridge())
        let otherSet = NSOrderedSet(array: ["baz"].bridge().bridge())
        let otherOtherSet = Set<NSObject>(["foo".bridge()])
        set.minusOrderedSet(otherSet)
        XCTAssertEqual(set.count, 2)
        XCTAssertEqual(set[0] as? NSString, "foo")
        XCTAssertEqual(set[1] as? NSString, "bar")
        set.minusSet(otherOtherSet)
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set[0] as? NSString, "bar")
    }

    func test_Union() {
        let set = NSMutableOrderedSet(arrayLiteral: "foo".bridge(), "bar".bridge(), "baz".bridge())
        let otherSet = NSOrderedSet(array: ["123", "baz"].bridge().bridge())
        let otherOtherSet = Set<NSObject>(["foo".bridge(), "456".bridge()])
        set.unionOrderedSet(otherSet)
        XCTAssertEqual(set.count, 4)
        XCTAssertEqual(set[0] as? NSString, "foo")
        XCTAssertEqual(set[1] as? NSString, "bar")
        XCTAssertEqual(set[2] as? NSString, "baz")
        XCTAssertEqual(set[3] as? NSString, "123")
        set.unionSet(otherOtherSet)
        XCTAssertEqual(set.count, 5)
        XCTAssertEqual(set[4] as? NSString, "456")
    }

    func test_Initializers() {
        let copyableObject = NSObject()
        let set = NSMutableOrderedSet(arrayLiteral: copyableObject, "bar".bridge(), "baz".bridge())
        let newSet = NSOrderedSet(orderedSet: set)
        XCTAssert(newSet.isEqualToOrderedSet(set))
        XCTAssert(set[0] === newSet[0])

        let unorderedSet = Set<NSObject>(["foo".bridge(), "bar".bridge(), "baz".bridge()])
        let newSetFromUnorderedSet = NSOrderedSet(set: unorderedSet)
        XCTAssertEqual(newSetFromUnorderedSet.count, 3)
        XCTAssert(newSetFromUnorderedSet.containsObject("foo".bridge()))
    }

    func test_Sorting() {
        let set = NSMutableOrderedSet(arrayLiteral: "a".bridge(), "d".bridge(), "c".bridge(), "b".bridge())
        set.sortUsingComparator { lhs, rhs in
            if let lhs = lhs as? NSString, rhs = rhs as? NSString {
                return lhs.compare(rhs.bridge())
            }
            return NSComparisonResult.OrderedSame
        }
        XCTAssertEqual(set[0] as? NSString, "a")
        XCTAssertEqual(set[1] as? NSString, "b")
        XCTAssertEqual(set[2] as? NSString, "c")
        XCTAssertEqual(set[3] as? NSString, "d")

        set.sortRange(NSMakeRange(1, 2), options: []) { lhs, rhs in
            if let lhs = lhs as? NSString, rhs = rhs as? NSString {
                return rhs.compare(lhs.bridge())
            }
            return NSComparisonResult.OrderedSame
        }
        XCTAssertEqual(set[0] as? NSString, "a")
        XCTAssertEqual(set[1] as? NSString, "c")
        XCTAssertEqual(set[2] as? NSString, "b")
        XCTAssertEqual(set[3] as? NSString, "d")
    }
}
