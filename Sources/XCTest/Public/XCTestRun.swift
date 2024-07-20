// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTestRun.swift
//  A test run collects information about the execution of a test.
//

/// A test run collects information about the execution of a test. Failures in
/// explicit test assertions are classified as "expected", while failures from
/// unrelated or uncaught exceptions are classified as "unexpected".
open class XCTestRun {
    /// The test instance provided when the test run was initialized.
    public let test: XCTest

    /// The time at which the test run was started, or nil.
    open private(set) var startDate: Date?

    /// The time at which the test run was stopped, or nil.
    open private(set) var stopDate: Date?

    /// The number of seconds that elapsed between when the run was started and
    /// when it was stopped.
    open var totalDuration: TimeInterval {
        if let stop = stopDate, let start = startDate {
            return stop.timeIntervalSince(start)
        } else {
            return 0.0
        }
    }

    /// In an `XCTestCase` run, the number of seconds that elapsed between when
    /// the run was started and when it was stopped. In an `XCTestSuite` run,
    /// the combined `testDuration` of each test case in the suite.
    open var testDuration: TimeInterval {
        return totalDuration
    }

    /// The number of tests in the run.
    open var testCaseCount: Int {
        return test.testCaseCount
    }

    /// The number of test executions recorded during the run.
    open private(set) var executionCount: Int = 0

    /// The number of test skips recorded during the run.
    open var skipCount: Int {
        hasBeenSkipped ? 1 : 0
    }

    /// The number of test failures recorded during the run.
    open private(set) var failureCount: Int = 0

    /// The number of uncaught exceptions recorded during the run.
    open private(set) var unexpectedExceptionCount: Int = 0

    /// The total number of test failures and uncaught exceptions recorded
    /// during the run.
    open var totalFailureCount: Int {
        return failureCount + unexpectedExceptionCount
    }

    /// `true` if all tests in the run completed their execution without
    /// recording any failures, otherwise `false`.
    open var hasSucceeded: Bool {
        guard isStopped else {
            return false
        }
        return totalFailureCount == 0
    }

    /// `true` if the test was skipped, otherwise `false`.
    open private(set) var hasBeenSkipped = false

    /// Designated initializer for the XCTestRun class.
    /// - Parameter test: An XCTest instance.
    /// - Returns: A test run for the provided test.
    public required init(test: XCTest) {
        self.test = test
    }

    /// Start a test run. Must not be called more than once.
    open func start() {
        guard !isStarted else {
            fatalError("Invalid attempt to start a test run that has " +
                       "already been started: \(self)")
        }
        guard !isStopped else {
            fatalError("Invalid attempt to start a test run that has " +
                       "already been stopped: \(self)")
        }

        startDate = Date()
    }

    /// Stop a test run. Must not be called unless the run has been started.
    /// Must not be called more than once.
    open func stop() {
        guard isStarted else {
            fatalError("Invalid attempt to stop a test run that has " +
                       "not yet been started: \(self)")
        }
        guard !isStopped else {
            fatalError("Invalid attempt to stop a test run that has " +
                       "already been stopped: \(self)")
        }

        executionCount += 1
        stopDate = Date()
    }

    /// Records a failure in the execution of the test for this test run. Must
    /// not be called unless the run has been started. Must not be called if the
    /// test run has been stopped.
    /// - Parameter description: The description of the failure being reported.
    /// - Parameter filePath: The file path to the source file where the failure
    ///   being reported was encountered or nil if unknown.
    /// - Parameter lineNumber: The line number in the source file at filePath
    ///   where the failure being reported was encountered.
    /// - Parameter expected: `true` if the failure being reported was the
    ///   result of a failed assertion, `false` if it was the result of an
    ///   uncaught exception.
    func recordFailure(withDescription description: String, inFile filePath: String?, atLine lineNumber: Int, expected: Bool) {
        func failureLocation() -> String {
            if let filePath = filePath {
                return "\(test.name) (\(filePath):\(lineNumber))"
            } else {
                return "\(test.name)"
            }
        }

        guard isStarted else {
            fatalError("Invalid attempt to record a failure for a test run " +
                       "that has not yet been started: \(failureLocation())")
        }
        guard !isStopped else {
            fatalError("Invalid attempt to record a failure for a test run " +
                       "that has already been stopped: \(failureLocation())")
        }

        if expected {
            failureCount += 1
        } else {
            unexpectedExceptionCount += 1
        }
    }

    func recordSkip(description: String, sourceLocation: SourceLocation?) {
        func failureLocation() -> String {
            if let sourceLocation = sourceLocation {
                return "\(test.name) (\(sourceLocation.file):\(sourceLocation.line))"
            } else {
                return "\(test.name)"
            }
        }

        guard isStarted else {
            fatalError("Invalid attempt to record a skip for a test run " +
                       "that has not yet been started: \(failureLocation())")
        }
        guard !hasBeenSkipped else {
            fatalError("Invalid attempt to record a skip for a test run " +
                       "that has already been skipped: \(failureLocation())")
        }
        guard !isStopped else {
            fatalError("Invalid attempt to record a skip for a test run " +
                       "has already been stopped: \(failureLocation())")
        }

        hasBeenSkipped = true
    }

    private var isStarted: Bool {
        return startDate != nil
    }

    private var isStopped: Bool {
        return isStarted && stopDate != nil
    }
}
