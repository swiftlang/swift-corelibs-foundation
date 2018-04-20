// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

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

    private func eval(_ predicate: NSPredicate, object: NSObject = NSObject()) -> Bool {
        return predicate.evaluate(with: object, substitutionVariables: nil)
    }

    func test_NotPredicate() {
        let notTruePredicate = NSCompoundPredicate(notPredicateWithSubpredicate: NSPredicate(value: true))
        let notFalsePredicate = NSCompoundPredicate(notPredicateWithSubpredicate: NSPredicate(value: false))

        XCTAssertFalse(eval(notTruePredicate))
        XCTAssertTrue(eval(notFalsePredicate))
    }

    func test_AndPredicateWithNoSubpredicates() {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [])

        XCTAssertTrue(eval(predicate))
    }

    func test_AndPredicateWithOneSubpredicate() {
        let truePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(value: true)])
        let falsePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(value: false)])

        XCTAssertTrue(eval(truePredicate))
        XCTAssertFalse(eval(falsePredicate))
    }

    func test_AndPredicateWithMultipleSubpredicates() {
        let truePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(value: true), NSPredicate(value: true)])
        let falsePredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(value: true), NSPredicate(value: false)])

        XCTAssertTrue(eval(truePredicate))
        XCTAssertFalse(eval(falsePredicate))
    }


    func test_OrPredicateWithNoSubpredicates() {
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [])

        XCTAssertFalse(eval(predicate))
    }

    func test_OrPredicateWithOneSubpredicate() {
        let truePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [NSPredicate(value: true)])
        let falsePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [NSPredicate(value: false)])

        XCTAssertTrue(eval(truePredicate))
        XCTAssertFalse(eval(falsePredicate))
    }

    func test_OrPredicateWithMultipleSubpredicates() {
        let truePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [NSPredicate(value: true), NSPredicate(value: false)])
        let falsePredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [NSPredicate(value: false), NSPredicate(value: false)])

        XCTAssertTrue(eval(truePredicate))
        XCTAssertFalse(eval(falsePredicate))
    }

    func test_AndPredicateShortCircuits() {
        var shortCircuited = true

        let bOK = NSPredicate(value: false)
        let bDontEval = NSPredicate(block: { (_, _) in
            shortCircuited = false
            return true
        })

        let both = NSCompoundPredicate(andPredicateWithSubpredicates: [bOK, bDontEval])
        XCTAssertFalse(eval(both))
        XCTAssertTrue(shortCircuited)
    }

    func test_OrPredicateShortCircuits() {
        var shortCircuited = true

        let bOK = NSPredicate(value: true)
        let bDontEval = NSPredicate(block: { (_, _) in
            shortCircuited = false
            return true
        })

        let both = NSCompoundPredicate(orPredicateWithSubpredicates: [bOK, bDontEval])
        XCTAssertTrue(eval(both))
        XCTAssertTrue(shortCircuited)
    }
}
