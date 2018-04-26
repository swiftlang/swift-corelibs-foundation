// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSPredicate: XCTestCase {

    static var allTests : [(String, (TestNSPredicate) -> () throws -> Void)] {
        return [
            ("test_BooleanPredicate", test_BooleanPredicate),
            ("test_BlockPredicateWithoutVariableBindings", test_BlockPredicateWithoutVariableBindings),
            ("test_filterNSArray", test_filterNSArray),
            ("test_filterNSMutableArray", test_filterNSMutableArray),
            ("test_filterNSSet", test_filterNSSet),
            ("test_filterNSMutableSet", test_filterNSMutableSet),
            ("test_filterNSOrderedSet", test_filterNSOrderedSet),
            ("test_filterNSMutableOrderedSet", test_filterNSMutableOrderedSet),
            ("test_NSCoding", test_NSCoding),
            ("test_copy", test_copy),
        ]
    }

    func test_BooleanPredicate() {
        let truePredicate = NSPredicate(value: true)
        let falsePredicate = NSPredicate(value: false)

        XCTAssertTrue(truePredicate.evaluate(with: NSObject()))
        XCTAssertFalse(falsePredicate.evaluate(with: NSObject()))
    }


    func test_BlockPredicateWithoutVariableBindings() {
        let isNSStringPredicate = NSPredicate { (object, bindings) -> Bool in
            return object is NSString
        }

        XCTAssertTrue(isNSStringPredicate.evaluate(with: NSString()))
        XCTAssertFalse(isNSStringPredicate.evaluate(with: NSArray()))
    }

    let lengthLessThanThreePredicate = NSPredicate { (obj, bindings) -> Bool in
        return (obj as! String).utf16.count < 3
    }

    let startArray = ["1", "12", "123", "1234"]
    let expectedArray = ["1", "12"]

    func test_filterNSArray() {
        let filteredArray = NSArray(array: startArray).filtered(using: lengthLessThanThreePredicate).map { $0 as! String }
        XCTAssertEqual(expectedArray, filteredArray)
    }

    func test_filterNSMutableArray() {
        let array = NSMutableArray(array: startArray)
        array.filter(using: lengthLessThanThreePredicate)
        XCTAssertEqual(NSArray(array: expectedArray), array)
    }

    func test_filterNSSet() {
        let set = NSSet(array: startArray)
        let filteredSet = set.filtered(using: lengthLessThanThreePredicate)
        XCTAssertEqual(Set(expectedArray), filteredSet)
    }

    func test_filterNSMutableSet() {
        let set = NSMutableSet(array: ["1", "12", "123", "1234"])
        set.filter(using: lengthLessThanThreePredicate)

        XCTAssertEqual(Set(expectedArray), Set(set.allObjects.map { $0 as! String }))
    }

    func test_filterNSOrderedSet() {
        let orderedSet = NSOrderedSet(array: startArray)
        let filteredOrderedSet = orderedSet.filtered(using: lengthLessThanThreePredicate)
        XCTAssertEqual(NSOrderedSet(array: expectedArray), filteredOrderedSet)
    }

    func test_filterNSMutableOrderedSet() {
        let orderedSet = NSMutableOrderedSet()
        orderedSet.addObjects(from: startArray)
        orderedSet.filter(using: lengthLessThanThreePredicate)

        let expectedOrderedSet = NSMutableOrderedSet()
        expectedOrderedSet.addObjects(from: expectedArray)
        XCTAssertEqual(expectedOrderedSet, orderedSet)
    }
    
    func test_NSCoding() {
        let predicateA = NSPredicate(value: true)
        let predicateB = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: predicateA)) as! NSPredicate
        XCTAssertEqual(predicateA, predicateB, "Archived then unarchived uuid must be equal.")
        let predicateC = NSPredicate(value: false)
        let predicateD = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: predicateC)) as! NSPredicate
        XCTAssertEqual(predicateC, predicateD, "Archived then unarchived uuid must be equal.")
    }
    
    func test_copy() {
        let predicate = NSPredicate(value: true)
        XCTAssert(predicate.isEqual(predicate.copy()))
    }
}
