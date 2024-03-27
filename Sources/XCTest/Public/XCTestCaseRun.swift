// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTestCaseRun.swift
//  A test run for an `XCTestCase`.
//

/// A test run for an `XCTestCase`.
open class XCTestCaseRun: XCTestRun {
    open override func start() {
        super.start()
        XCTestObservationCenter.shared.testCaseWillStart(testCase)
    }

    open override func stop() {
        super.stop()
        XCTestObservationCenter.shared.testCaseDidFinish(testCase)
    }

    open override func recordFailure(withDescription description: String, inFile filePath: String?, atLine lineNumber: Int, expected: Bool) {
        super.recordFailure(
            withDescription: "\(test.name) : \(description)",
            inFile: filePath,
            atLine: lineNumber,
            expected: expected)
        XCTestObservationCenter.shared.testCase(
            testCase,
            didFailWithDescription: description,
            inFile: filePath,
            atLine: lineNumber)
    }

    override func recordSkip(description: String, sourceLocation: SourceLocation?) {
        super.recordSkip(description: description, sourceLocation: sourceLocation)

        XCTestObservationCenter.shared.testCase(
            testCase,
            wasSkippedWithDescription: description,
            at: sourceLocation)
    }

    private var testCase: XCTestCase {
        return test as! XCTestCase
    }
}
