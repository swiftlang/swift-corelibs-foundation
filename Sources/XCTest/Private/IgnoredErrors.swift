// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  IgnoredErrors.swift
//

protocol XCTCustomErrorHandling: Error {

    /// Whether this error should be recorded as a test failure when it is caught. Default: true.
    var shouldRecordAsTestFailure: Bool { get }

    /// Whether this error should cause the test invocation to be skipped when it is caught during a throwing setUp method. Default: true.
    var shouldSkipTestInvocation: Bool { get }

    /// Whether this error should be recorded as a test skip when it is caught during a test invocation. Default: false.
    var shouldRecordAsTestSkip: Bool { get }

}

extension XCTCustomErrorHandling {

    var shouldRecordAsTestFailure: Bool {
        true
    }

    var shouldSkipTestInvocation: Bool {
        true
    }

    var shouldRecordAsTestSkip: Bool {
        false
    }

}

extension Error {

    var xct_shouldRecordAsTestFailure: Bool {
        (self as? XCTCustomErrorHandling)?.shouldRecordAsTestFailure ?? true
    }

    var xct_shouldSkipTestInvocation: Bool {
        (self as? XCTCustomErrorHandling)?.shouldSkipTestInvocation ?? true
    }

    var xct_shouldRecordAsTestSkip: Bool {
        (self as? XCTCustomErrorHandling)?.shouldRecordAsTestSkip ?? false
    }

}

/// The error type thrown by `XCTUnwrap` on assertion failure.
internal struct XCTestErrorWhileUnwrappingOptional: Error, XCTCustomErrorHandling {

    var shouldRecordAsTestFailure: Bool {
        // Don't record this error as a test failure, because XCTUnwrap
        // internally records the failure before throwing this error
        false
    }

}
