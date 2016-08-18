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

class TestNSCompoundPredicate: XCTestCase {
    
    static var allTests: [(String, (TestNSCompoundPredicate) -> () throws -> Void)] {
        return [
            ("test_NotPredicate", test_NotPredicate),
            ("test_AndPredicateWithNoSubpredicates", test_AndPredicateWithNoSubpredicates),
            ("test_AndPredicateWithOneSubpredicate", test_AndPredicateWithOneSubpredicate),
            ("test_AndPredicateWithMultipleSubpredicates", test_AndPredicateWithMultipleSubpredicates),
            ("test_OrPredicateWithNoSubpredicates", test_OrPredicateWithNoSubpredicates),
            ("test_OrPredicateWithOneSubpredicate", test_OrPredicateWithOneSubpredicate),
            ("test_OrPredicateWithMultipleSubpredicates", test_OrPredicateWithMultipleSubpredicates),
            ("test_OrPredicateShortCircuits", test_OrPredicateShortCircuits),
            ("test_AndPredicateShortCircuits", test_AndPredicateShortCircuits),
        ]
    }

    private func eval(_ predicate: Predicate, object: NSObject = NSObject()) -> Bool {
        return predicate.evaluate(with: object, substitutionVariables: nil)
    }

    func test_NotPredicate() {
        let notTruePredicate = CompoundPredicate(notPredicateWithSubpredicate: Predicate(value: true))
        let notFalsePredicate = CompoundPredicate(notPredicateWithSubpredicate: Predicate(value: false))

        XCTAssertFalse(eval(notTruePredicate))
        XCTAssertTrue(eval(notFalsePredicate))
    }

    func test_AndPredicateWithNoSubpredicates() {
        let predicate = CompoundPredicate(andPredicateWithSubpredicates: [])

        XCTAssertTrue(eval(predicate))
    }

    func test_AndPredicateWithOneSubpredicate() {
        let truePredicate = CompoundPredicate(andPredicateWithSubpredicates: [Predicate(value: true)])
        let falsePredicate = CompoundPredicate(andPredicateWithSubpredicates: [Predicate(value: false)])

        XCTAssertTrue(eval(truePredicate))
        XCTAssertFalse(eval(falsePredicate))
    }

    func test_AndPredicateWithMultipleSubpredicates() {
        let truePredicate = CompoundPredicate(andPredicateWithSubpredicates: [Predicate(value: true), Predicate(value: true)])
        let falsePredicate = CompoundPredicate(andPredicateWithSubpredicates: [Predicate(value: true), Predicate(value: false)])

        XCTAssertTrue(eval(truePredicate))
        XCTAssertFalse(eval(falsePredicate))
    }


    func test_OrPredicateWithNoSubpredicates() {
        let predicate = CompoundPredicate(orPredicateWithSubpredicates: [])

        XCTAssertFalse(eval(predicate))
    }

    func test_OrPredicateWithOneSubpredicate() {
        let truePredicate = CompoundPredicate(orPredicateWithSubpredicates: [Predicate(value: true)])
        let falsePredicate = CompoundPredicate(orPredicateWithSubpredicates: [Predicate(value: false)])

        XCTAssertTrue(eval(truePredicate))
        XCTAssertFalse(eval(falsePredicate))
    }

    func test_OrPredicateWithMultipleSubpredicates() {
        let truePredicate = CompoundPredicate(orPredicateWithSubpredicates: [Predicate(value: true), Predicate(value: false)])
        let falsePredicate = CompoundPredicate(orPredicateWithSubpredicates: [Predicate(value: false), Predicate(value: false)])

        XCTAssertTrue(eval(truePredicate))
        XCTAssertFalse(eval(falsePredicate))
    }

    func test_AndPredicateShortCircuits() {
        var shortCircuited = true

        let bOK = Predicate(value: false)
        let bDontEval = Predicate(block: { _ in
            shortCircuited = false
            return true
        })

        let both = CompoundPredicate(andPredicateWithSubpredicates: [bOK, bDontEval])
        XCTAssertFalse(eval(both))
        XCTAssertTrue(shortCircuited)
    }

    func test_OrPredicateShortCircuits() {
        var shortCircuited = true

        let bOK = Predicate(value: true)
        let bDontEval = Predicate(block: { _ in
            shortCircuited = false
            return true
        })

        let both = CompoundPredicate(orPredicateWithSubpredicates: [bOK, bDontEval])
        XCTAssertTrue(eval(both))
        XCTAssertTrue(shortCircuited)
    }
}
