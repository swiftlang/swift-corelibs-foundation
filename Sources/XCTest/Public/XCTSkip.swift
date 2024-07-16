// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTSkip.swift
//  APIs for skipping tests
//

/// An error which causes the current test to cease executing
/// and be marked as skipped when it is thrown.
public struct XCTSkip: Error {

    /// The user-supplied message related to this skip, if specified.
    public let message: String?

    /// A complete description of the skip. Includes the string-ified expression and user-supplied message when possible.
    let summary: String

    /// An explanation of why the skip has occurred.
    ///
    /// - Note: May be nil if the skip was unconditional.
    private let explanation: String?

    /// The source code location where the skip occurred.
    let sourceLocation: SourceLocation?

    private init(explanation: String?, message: String?, sourceLocation: SourceLocation?) {
        self.explanation = explanation
        self.message = message
        self.sourceLocation = sourceLocation

        var summary = "Test skipped"
        if let explanation = explanation {
            summary += ": \(explanation)"
        }
        if let message = message, !message.isEmpty {
            summary += " - \(message)"
        }
        self.summary = summary
    }

    public init(_ message: @autoclosure () -> String? = nil, file: StaticString = #file, line: UInt = #line) {
        self.init(explanation: nil, message: message(), sourceLocation: SourceLocation(file: file, line: line))
    }

    fileprivate init(expectedValue: Bool, message: String?, file: StaticString, line: UInt) {
        let explanation = expectedValue
            ? "required true value but got false"
            : "required false value but got true"
        self.init(explanation: explanation, message: message, sourceLocation: SourceLocation(file: file, line: line))
    }

    internal init(error: Error, message: String?, sourceLocation: SourceLocation?) {
        let explanation = #"threw error "\#(error)""#
        self.init(explanation: explanation, message: message, sourceLocation: sourceLocation)
    }

}

extension XCTSkip: XCTCustomErrorHandling {

    var shouldRecordAsTestFailure: Bool {
        // Don't record this error as a test failure since it's a test skip
        false
    }

    var shouldRecordAsTestSkip: Bool {
        true
    }

}

/// Evaluates a boolean expression and, if it is true, throws an error which
/// causes the current test to cease executing and be marked as skipped.
public func XCTSkipIf(
    _ expression: @autoclosure () throws -> Bool,
    _ message: @autoclosure () -> String? = nil,
    file: StaticString = #file, line: UInt = #line
) throws {
    try skipIfEqual(expression(), true, message(), file: file, line: line)
}

/// Evaluates a boolean expression and, if it is false, throws an error which
/// causes the current test to cease executing and be marked as skipped.
public func XCTSkipUnless(
    _ expression: @autoclosure () throws -> Bool,
    _ message: @autoclosure () -> String? = nil,
    file: StaticString = #file, line: UInt = #line
) throws {
    try skipIfEqual(expression(), false, message(), file: file, line: line)
}

private func skipIfEqual(
    _ expression: @autoclosure () throws -> Bool,
    _ expectedValue: Bool,
    _ message: @autoclosure () -> String?,
    file: StaticString, line: UInt
) throws {
    let expressionValue: Bool

    do {
        // evaluate the expression exactly once
        expressionValue = try expression()
    } catch {
        throw XCTSkip(error: error, message: message(), sourceLocation: SourceLocation(file: file, line: line))
    }

    if expressionValue == expectedValue {
        throw XCTSkip(expectedValue: expectedValue, message: message(), file: file, line: line)
    }
}
