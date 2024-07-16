// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTestCaseSuite.swift
//  A test suite associated with a particular test case class.
//

/// A test suite which is associated with a particular test case class. It will
/// call `setUp` and `tearDown` on the class itself before and after invoking
/// all of the test cases making up the class.
internal class XCTestCaseSuite: XCTestSuite {
    private let testCaseClass: XCTestCase.Type

    init(testCaseEntry: XCTestCaseEntry) {
        let testCaseClass = testCaseEntry.testCaseClass
        self.testCaseClass = testCaseClass
        super.init(name: String(describing: testCaseClass))

        for (testName, testClosure) in testCaseEntry.allTests {
            let testCase = testCaseClass.init(name: testName, testClosure: testClosure)
            addTest(testCase)
        }
    }

    override func setUp() {
        testCaseClass.setUp()
    }

    override func tearDown() {
        testCaseClass.tearDown()
    }
}
