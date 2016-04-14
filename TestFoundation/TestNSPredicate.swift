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

class TestNSPredicate: XCTestCase {

    static var allTests : [(String, TestNSPredicate -> () throws -> Void)] {
        return [
            ("test_BooleanPredicate", test_BooleanPredicate),
            ("test_BlockPredicateWithoutVariableBindings", test_BlockPredicateWithoutVariableBindings),
            ("test_filterNSArray", test_filterNSArray),
        ]
    }

    func test_BooleanPredicate() {
        let truePredicate = NSPredicate(value: true)
        let falsePredicate = NSPredicate(value: false)

        XCTAssertTrue(truePredicate.evaluateWithObject(NSObject()))
        XCTAssertFalse(falsePredicate.evaluateWithObject(NSObject()))
    }


    func test_BlockPredicateWithoutVariableBindings() {
        let isNSStringPredicate = NSPredicate { (object, bindings) -> Bool in
            return object is NSString
        }

        XCTAssertTrue(isNSStringPredicate.evaluateWithObject(NSString()))
        XCTAssertFalse(isNSStringPredicate.evaluateWithObject(NSArray()))
    }


    func test_filterNSArray() {
        let predicate = NSPredicate { (obj, bindings) -> Bool in
            return (obj as? NSString).map({ $0.length <= 2 }) == true
        }

        let array = NSArray(array: ["1".bridge(), "12".bridge(), "123".bridge(), "1234".bridge()])
        let filteredArray = array.filteredArrayUsingPredicate(predicate).bridge()

        XCTAssertEqual(["1".bridge(), "12".bridge()].bridge(), filteredArray)
    }
}
