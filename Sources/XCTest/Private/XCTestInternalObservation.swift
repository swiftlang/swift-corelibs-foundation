// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTestInternalObservation.swift
//  Extra hooks used within XCTest for being notified about additional events
//  during a test run.
//

/// Expanded version of `XCTestObservation` used internally to respond to
/// additional events not publicly exposed.
internal protocol XCTestInternalObservation: XCTestObservation {
    func testCase(_ testCase: XCTestCase, wasSkippedWithDescription description: String, at sourceLocation: SourceLocation?)

    /// Called when a test case finishes measuring performance and has results
    /// to report
    /// - Parameter testCase: The test case that did the measurements.
    /// - Parameter results: The measured values and derived stats.
    /// - Parameter file: The path to the source file where the failure was
    ///   reported, if available.
    /// - Parameter line: The line number in the source file where the failure
    ///   was reported.
    func testCase(_ testCase: XCTestCase, didMeasurePerformanceResults results: String, file: StaticString, line: Int)
}

// All `XCInternalTestObservation` methods are optional, so empty default implementations are provided
internal extension XCTestInternalObservation {
    func testCase(_ testCase: XCTestCase, wasSkippedWithDescription description: String, at sourceLocation: SourceLocation?) {}
    func testCase(_ testCase: XCTestCase, didMeasurePerformanceResults results: String, file: StaticString, line: Int) {}
}
