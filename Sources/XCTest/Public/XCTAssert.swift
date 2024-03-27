// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTAssert.swift
//

private enum _XCTAssertion {
    case equal
    case equalWithAccuracy
    case identical
    case notIdentical
    case greaterThan
    case greaterThanOrEqual
    case lessThan
    case lessThanOrEqual
    case notEqual
    case notEqualWithAccuracy
    case `nil`
    case notNil
    case unwrap
    case `true`
    case `false`
    case fail
    case throwsError
    case noThrow

    var name: String? {
        switch(self) {
        case .equal: return "XCTAssertEqual"
        case .equalWithAccuracy: return "XCTAssertEqual"
        case .identical: return "XCTAssertIdentical"
        case .notIdentical: return "XCTAssertNotIdentical"
        case .greaterThan: return "XCTAssertGreaterThan"
        case .greaterThanOrEqual: return "XCTAssertGreaterThanOrEqual"
        case .lessThan: return "XCTAssertLessThan"
        case .lessThanOrEqual: return "XCTAssertLessThanOrEqual"
        case .notEqual: return "XCTAssertNotEqual"
        case .notEqualWithAccuracy: return "XCTAssertNotEqual"
        case .`nil`: return "XCTAssertNil"
        case .notNil: return "XCTAssertNotNil"
        case .unwrap: return "XCTUnwrap"
        case .`true`: return "XCTAssertTrue"
        case .`false`: return "XCTAssertFalse"
        case .throwsError: return "XCTAssertThrowsError"
        case .noThrow: return "XCTAssertNoThrow"
        case .fail: return nil
        }
    }
}

private enum _XCTAssertionResult {
    case success
    case expectedFailure(String?)
    case unexpectedFailure(Swift.Error)

    var isExpected: Bool {
        switch self {
        case .unexpectedFailure(_): return false
        default: return true
        }
    }

    func failureDescription(_ assertion: _XCTAssertion) -> String {
        let explanation: String
        switch self {
        case .success: explanation = "passed"
        case .expectedFailure(let details?): explanation = "failed: \(details)"
        case .expectedFailure(_): explanation = "failed"
        case .unexpectedFailure(let error): explanation = "threw error \"\(error)\""
        }

        if let name = assertion.name {
            return "\(name) \(explanation)"
        } else {
            return explanation
        }
    }
}

private func _XCTEvaluateAssertion(_ assertion: _XCTAssertion, message: @autoclosure () -> String, file: StaticString, line: UInt, expression: () throws -> _XCTAssertionResult) {
    let result: _XCTAssertionResult
    do {
        result = try expression()
    } catch {
        result = .unexpectedFailure(error)
    }

    switch result {
    case .success:
        return
    default:
        if let currentTestCase = XCTCurrentTestCase {
            currentTestCase.recordFailure(
                withDescription: "\(result.failureDescription(assertion)) - \(message())",
                inFile: String(describing: file),
                atLine: Int(line),
                expected: result.isExpected)
        }
    }
}

/// This function emits a test failure if the general `Boolean` expression passed
/// to it evaluates to `false`.
///
/// - Requires: This and all other XCTAssert* functions must be called from
///   within a test method, as passed to `XCTMain`.
///   Assertion failures that occur outside of a test method will *not* be
///   reported as failures.
///
/// - Parameter expression: A boolean test. If it evaluates to `false`, the
///   assertion fails and emits a test failure.
/// - Parameter message: An optional message to use in the failure if the
///   assertion fails. If no message is supplied a default message is used.
/// - Parameter file: The file name to use in the error message if the assertion
///   fails. Default is the file containing the call to this function. It is
///   rare to provide this parameter when calling this function.
/// - Parameter line: The line number to use in the error message if the
///   assertion fails. Default is the line number of the call to this function
///   in the calling file. It is rare to provide this parameter when calling
///   this function.
///
/// - Note: It is rare to provide the `file` and `line` parameters when calling
///   this function, although you may consider doing so when creating your own
///   assertion functions. For example, consider the following custom assertion:
///
///   ```
///   // AssertEmpty.swift
///
///   func AssertEmpty<T>(_ elements: [T]) {
///       XCTAssertEqual(elements.count, 0, "Array is not empty")
///   }
///   ```
///
///  Calling this assertion will cause XCTest to report the failure occurred
///  in the file where `AssertEmpty()` is defined, and on the line where
///  `XCTAssertEqual` is called from within that function:
///
///  ```
///  // MyFile.swift
///
///  AssertEmpty([1, 2, 3]) // Emits "AssertEmpty.swift:3: error: ..."
///  ```
///
///  To have XCTest properly report the file and line where the assertion
///  failed, you may specify the file and line yourself:
///
///  ```
///  // AssertEmpty.swift
///
///  func AssertEmpty<T>(_ elements: [T], file: StaticString = #file, line: UInt = #line) {
///      XCTAssertEqual(elements.count, 0, "Array is not empty", file: file, line: line)
///  }
///  ```
///
///  Now calling failures in `AssertEmpty` will be reported in the file and on
///  the line that the assert function is *called*, not where it is defined.
public func XCTAssert(_ expression: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(try expression(), message(), file: file, line: line)
}

public func XCTAssertEqual<T: Equatable>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.equal, message: message(), file: file, line: line) {
        let (value1, value2) = (try expression1(), try expression2())
        if value1 == value2 {
            return .success
        } else {
            return .expectedFailure("(\"\(value1)\") is not equal to (\"\(value2)\")")
        }
    }
}

private func areEqual<T: Numeric>(_ exp1: T, _ exp2: T, accuracy: T) -> Bool {
    // Test with equality first to handle comparing inf/-inf with itself.
    if exp1 == exp2 {
        return true
    } else {
        // NaN values are handled implicitly, since the <= operator returns false when comparing any value to NaN.
        let difference = (exp1.magnitude > exp2.magnitude) ? exp1 - exp2 : exp2 - exp1
        return difference.magnitude <= accuracy.magnitude
    }
}

public func XCTAssertEqual<T: FloatingPoint>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, accuracy: T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTAssertEqual(try expression1(), try expression2(), accuracy: accuracy, message(), file: file, line: line)
}

public func XCTAssertEqual<T: Numeric>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, accuracy: T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTAssertEqual(try expression1(), try expression2(), accuracy: accuracy, message(), file: file, line: line)
}

private func _XCTAssertEqual<T: Numeric>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, accuracy: T, _ message: @autoclosure () -> String, file: StaticString, line: UInt) {
    _XCTEvaluateAssertion(.equalWithAccuracy, message: message(), file: file, line: line) {
        let (value1, value2) = (try expression1(), try expression2())
        if areEqual(value1, value2, accuracy: accuracy) {
            return .success
        } else {
            return .expectedFailure("(\"\(value1)\") is not equal to (\"\(value2)\") +/- (\"\(accuracy)\")")
        }
    }
}

@available(*, deprecated, renamed: "XCTAssertEqual(_:_:accuracy:file:line:)")
public func XCTAssertEqualWithAccuracy<T: FloatingPoint>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, accuracy: T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(try expression1(), try expression2(), accuracy: accuracy, message(), file: file, line: line)
}

private func describe(_ object: AnyObject?) -> String {
    return object == nil ? String(describing: object) : String(describing: object!)
}

/// Asserts that two values are identical.
public func XCTAssertIdentical(_ expression1: @autoclosure () throws -> AnyObject?, _ expression2: @autoclosure () throws -> AnyObject?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.identical, message: message(), file: file, line: line) {
        let (value1, value2) = (try expression1(), try expression2())
        if value1 === value2 {
            return .success
        } else {
            return .expectedFailure("(\"\(describe(value1))\") is not identical to (\"\(describe(value2))\")")
        }
    }
}

/// Asserts that two values aren't identical.
public func XCTAssertNotIdentical(_ expression1: @autoclosure () throws -> AnyObject?, _ expression2: @autoclosure () throws -> AnyObject?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.notIdentical, message: message(), file: file, line: line) {
        let (value1, value2) = (try expression1(), try expression2())
        if value1 !== value2 {
            return .success
        } else {
            return .expectedFailure("(\"\(describe(value1))\") is identical to (\"\(describe(value2))\")")
        }
    }
}

public func XCTAssertFalse(_ expression: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.`false`, message: message(), file: file, line: line) {
        let value = try expression()
        if !value {
            return .success
        } else {
            return .expectedFailure(nil)
        }
    }
}

public func XCTAssertGreaterThan<T: Comparable>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.greaterThan, message: message(), file: file, line: line) {
        let (value1, value2) = (try expression1(), try expression2())
        if value1 > value2 {
            return .success
        } else {
            return .expectedFailure("(\"\(value1)\") is not greater than (\"\(value2)\")")
        }
    }
}

public func XCTAssertGreaterThanOrEqual<T: Comparable>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.greaterThanOrEqual, message: message(), file: file, line: line) {
        let (value1, value2) = (try expression1(), try expression2())
        if value1 >= value2 {
            return .success
        } else {
            return .expectedFailure("(\"\(value1)\") is less than (\"\(value2)\")")
        }
    }
}

public func XCTAssertLessThan<T: Comparable>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.lessThan, message: message(), file: file, line: line) {
        let (value1, value2) = (try expression1(), try expression2())
        if value1 < value2 {
            return .success
        } else {
            return .expectedFailure("(\"\(value1)\") is not less than (\"\(value2)\")")
        }
    }
}

public func XCTAssertLessThanOrEqual<T: Comparable>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.lessThanOrEqual, message: message(), file: file, line: line) {
        let (value1, value2) = (try expression1(), try expression2())
        if value1 <= value2 {
            return .success
        } else {
            return .expectedFailure("(\"\(value1)\") is greater than (\"\(value2)\")")
        }
    }
}

public func XCTAssertNil(_ expression: @autoclosure () throws -> Any?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.`nil`, message: message(), file: file, line: line) {
        let value = try expression()
        if value == nil {
            return .success
        } else {
            return .expectedFailure("\"\(value!)\"")
        }
    }
}

public func XCTAssertNotEqual<T: Equatable>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.notEqual, message: message(), file: file, line: line) {
        let (value1, value2) = (try expression1(), try expression2())
        if value1 != value2 {
            return .success
        } else {
            return .expectedFailure("(\"\(value1)\") is equal to (\"\(value2)\")")
        }
    }
}

public func XCTAssertNotEqual<T: FloatingPoint>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, accuracy: T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTAssertNotEqual(try expression1(), try expression2(), accuracy: accuracy, message(), file: file, line: line)
}

public func XCTAssertNotEqual<T: Numeric>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, accuracy: T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTAssertNotEqual(try expression1(), try expression2(), accuracy: accuracy, message(), file: file, line: line)
}

private func _XCTAssertNotEqual<T: Numeric>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, accuracy: T, _ message: @autoclosure () -> String, file: StaticString, line: UInt) {
    _XCTEvaluateAssertion(.notEqualWithAccuracy, message: message(), file: file, line: line) {
        let (value1, value2) = (try expression1(), try expression2())
        if !areEqual(value1, value2, accuracy: accuracy) {
            return .success
        } else {
            return .expectedFailure("(\"\(value1)\") is equal to (\"\(value2)\") +/- (\"\(accuracy)\")")
        }
    }
}

@available(*, deprecated, renamed: "XCTAssertNotEqual(_:_:accuracy:file:line:)")
public func XCTAssertNotEqualWithAccuracy<T: FloatingPoint>(_ expression1: @autoclosure () throws -> T, _ expression2: @autoclosure () throws -> T, _ accuracy: T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertNotEqual(try expression1(), try expression2(), accuracy: accuracy, message(), file: file, line: line)
}

public func XCTAssertNotNil(_ expression: @autoclosure () throws -> Any?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.notNil, message: message(), file: file, line: line) {
        let value = try expression()
        if value != nil {
            return .success
        } else {
            return .expectedFailure(nil)
        }
    }
}

/// Asserts that an expression is not `nil`, and returns its unwrapped value.
///
/// Generates a failure if `expression` returns `nil`.
///
/// - Parameters:
///   - expression: An expression of type `T?` to compare against `nil`. Its type will determine the type of the
///     returned value.
///   - message: An optional description of the failure.
///   - file: The file in which failure occurred. Defaults to the file name of the test case in which this function was
///     called.
///   - line: The line number on which failure occurred. Defaults to the line number on which this function was called.
/// - Returns: A value of type `T`, the result of evaluating and unwrapping the given `expression`.
/// - Throws: An error if `expression` returns `nil`. If `expression` throws an error, then that error will be rethrown instead.
public func XCTUnwrap<T>(_ expression: @autoclosure () throws -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) throws -> T {
    var value: T?
    var caughtErrorOptional: Swift.Error?

    _XCTEvaluateAssertion(.unwrap, message: message(), file: file, line: line) {
        do {
            value = try expression()
        } catch {
            caughtErrorOptional = error
            return .unexpectedFailure(error)
        }

        if value != nil {
            return .success
        } else {
            return .expectedFailure("expected non-nil value of type \"\(T.self)\"")
        }
    }

    if let unwrappedValue = value {
        return unwrappedValue
    } else if let error = caughtErrorOptional {
        throw error
    } else {
        throw XCTestErrorWhileUnwrappingOptional()
    }
}

public func XCTAssertTrue(_ expression: @autoclosure () throws -> Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.`true`, message: message(), file: file, line: line) {
        let value = try expression()
        if value {
            return .success
        } else {
            return .expectedFailure(nil)
        }
    }
}

public func XCTFail(_ message: String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.fail, message: message, file: file, line: line) {
        return .expectedFailure(nil)
    }
}

public func XCTAssertThrowsError<T>(_ expression: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, _ errorHandler: (_ error: Swift.Error) -> Void = { _ in }) {
    let rethrowsOverload: (() throws -> T, () -> String, StaticString, UInt, (Swift.Error) throws -> Void) throws -> Void = XCTAssertThrowsError

    try? rethrowsOverload(expression, message, file, line, errorHandler)
}

public func XCTAssertThrowsError<T>(_ expression: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, _ errorHandler: (_ error: Swift.Error) throws -> Void = { _ in }) rethrows {
    _XCTEvaluateAssertion(.throwsError, message: message(), file: file, line: line) {
        var caughtErrorOptional: Swift.Error?
        do {
            _ = try expression()
        } catch {
            caughtErrorOptional = error
        }

        if let caughtError = caughtErrorOptional {
            try errorHandler(caughtError)
            return .success
        } else {
            return .expectedFailure("did not throw error")
        }
    }
}

public func XCTAssertNoThrow<T>(_ expression: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    _XCTEvaluateAssertion(.noThrow, message: message(), file: file, line: line) {
        do {
             _ = try expression()
            return .success
        } catch let error {
            return .expectedFailure("threw error \"\(error)\"")
        }
    }
}
