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
        ]
    }

    func test_BooleanPredicate() {
        let truePredicate = Predicate(value: true)
        let falsePredicate = Predicate(value: false)

        XCTAssertTrue(truePredicate.evaluate(with: NSObject()))
        XCTAssertFalse(falsePredicate.evaluate(with: NSObject()))
    }


    func test_BlockPredicateWithoutVariableBindings() {
        let isNSStringPredicate = Predicate { (object, bindings) -> Bool in
            return object is NSString
        }

        XCTAssertTrue(isNSStringPredicate.evaluate(with: NSString()))
        XCTAssertFalse(isNSStringPredicate.evaluate(with: NSArray()))
    }

    let lengthLessThanThreePredicate = Predicate { (obj, bindings) -> Bool in
        return (obj as? NSString).map({ $0.length < 3 }) == true
    }

    let startArray = ["1".bridge(), "12".bridge(), "123".bridge(), "1234".bridge()]
    let expectedArray = ["1".bridge(), "12".bridge()]

    func test_filterNSArray() {
        let filteredArray = startArray.bridge().filteredArrayUsingPredicate(lengthLessThanThreePredicate).bridge()

        XCTAssertEqual(expectedArray.bridge(), filteredArray)
    }

    func test_filterNSMutableArray() {
        let array = startArray.bridge().mutableCopy() as! NSMutableArray

        array.filterUsingPredicate(lengthLessThanThreePredicate)

        XCTAssertEqual(expectedArray.bridge(), array)
    }

    func test_filterNSSet() {
        let set = Set(startArray).bridge()
        let filteredSet = set.filteredSetUsingPredicate(lengthLessThanThreePredicate).bridge()

        XCTAssertEqual(Set(expectedArray).bridge(), filteredSet)
    }

    func test_filterNSMutableSet() {
        let set = NSMutableSet(objects: ["1".bridge(), "12".bridge(), "123".bridge(), "1234".bridge()], count: 4)
        set.filterUsingPredicate(lengthLessThanThreePredicate)

        XCTAssertEqual(Set(expectedArray).bridge(), set)
    }

    func test_filterNSOrderedSet() {
        // TODO
        // This test is temporarily disabled due to a compile crash when calling the initializer of NSOrderedSet with an array
        /*
        let orderedSet = NSOrderedSet(array: startArray)
        let filteredOrderedSet = orderedSet.filteredOrderedSetUsingPredicate(lengthLessThanThreePredicate)

        XCTAssertEqual(NSOrderedSet(array: expectedArray), filteredOrderedSet)
        */
    }

    func test_filterNSMutableOrderedSet() {
        // TODO
        // This test is temporarily disabled due to a compile crash when calling the initializer of NSOrderedSet with an array
        /*
        let orderedSet = NSMutableOrderedSet()
        orderedSet.addObjectsFromArray(startArray)

        orderedSet.filterUsingPredicate(lengthLessThanThreePredicate)

        let expectedOrderedSet = NSMutableOrderedSet()
        expectedOrderedSet.addObjectsFromArray(expectedArray)
        XCTAssertEqual(expectedOrderedSet, orderedSet)
        */
    }
}
