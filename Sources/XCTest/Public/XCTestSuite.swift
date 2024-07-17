// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTestSuite.swift
//  A collection of test cases.
//

/// A subclass of XCTest, XCTestSuite is a collection of test cases. Based on
/// what's passed into XCTMain(), a hierarchy of suites is built up, but
/// XCTestSuite can also be instantiated and manipulated directly:
///
///     let suite = XCTestSuite(name: "My Tests")
///     suite.addTest(myTest)
///     suite.testCaseCount // 1
///     suite.run()
open class XCTestSuite: XCTest {
    open private(set) var tests = [XCTest]()

    /// The name of this test suite.
    open override var name: String {
        return _name
    }
    /// A private setter for the name of this test suite.
    private let _name: String

    /// The number of test cases in this suite.
    open override var testCaseCount: Int {
        return tests.reduce(0) { $0 + $1.testCaseCount }
    }

    open override var testRunClass: AnyClass? {
        return XCTestSuiteRun.self
    }

    open override func perform(_ run: XCTestRun) {
        guard let testRun = run as? XCTestSuiteRun else {
            fatalError("Wrong XCTestRun class.")
        }

        run.start()
        setUp()
        for test in tests {
            test.run()
            testRun.addTestRun(test.testRun!)
        }
        tearDown()
        run.stop()
    }

    public init(name: String) {
        _name = name
    }

    /// Adds a test (either an `XCTestSuite` or an `XCTestCase` to this
    /// collection.
    open func addTest(_ test: XCTest) {
        tests.append(test)
    }
}
