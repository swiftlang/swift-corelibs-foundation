// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCAbstractTest.swift
//  An abstract base class that XCTestCase and XCTestSuite inherit from.
//  The purpose of this class is to mirror the design of Apple XCTest.
//

/// An abstract base class for testing. `XCTestCase` and `XCTestSuite` extend
/// `XCTest` to provide for creating, managing, and executing tests. Most
/// developers will not need to subclass `XCTest` directly.
open class XCTest {
    /// Test's name. Must be overridden by subclasses.
    open var name: String {
        fatalError("Must be overridden by subclasses.")
    }

    /// Number of test cases. Must be overridden by subclasses.
    open var testCaseCount: Int {
        fatalError("Must be overridden by subclasses.")
    }

    /// The `XCTestRun` subclass that will be instantiated when the test is run
    /// to hold the test's results. Must be overridden by subclasses.
    open var testRunClass: AnyClass? {
        fatalError("Must be overridden by subclasses.")
    }

    /// The test run object that executed the test, an instance of
    /// testRunClass. If the test has not yet been run, this will be nil.
    open private(set) var testRun: XCTestRun? = nil

    /// The method through which tests are executed. Must be overridden by
    /// subclasses.
    open func perform(_ run: XCTestRun) {
        fatalError("Must be overridden by subclasses.")
    }

    /// Creates an instance of the `testRunClass` and passes it as a parameter
    /// to `perform()`.
    open func run() {
        guard let testRunType = testRunClass as? XCTestRun.Type else {
            fatalError("XCTest.testRunClass must be a kind of XCTestRun.")
        }
        testRun = testRunType.init(test: self)
        perform(testRun!)
    }

    /// Async setup method called before the invocation of `setUpWithError` for each test method in the class.
    @available(macOS 12.0, *)
    open func setUp() async throws {}
    /// Setup method called before the invocation of `setUp` and the test method
    /// for each test method in the class.
    open func setUpWithError() throws {}

    /// Setup method called before the invocation of each test method in the
    /// class.
    open func setUp() {}

    /// Teardown method called after the invocation of each test method in the
    /// class.
    open func tearDown() {}

    /// Teardown method called after the invocation of the test method and `tearDown`
    /// for each test method in the class.
    open func tearDownWithError() throws {}

    /// Async teardown method which is called after the invocation of `tearDownWithError`
    /// for each test method in the class.
    @available(macOS 12.0, *)
    open func tearDown() async throws {}
    // FIXME: This initializer is required due to a Swift compiler bug on Linux.
    //        It should be removed once the bug is fixed.
    public init() {}
}
