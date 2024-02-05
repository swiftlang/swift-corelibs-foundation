// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

// This is the same as the XCTUnwrap() method used in TestFoundation, but does not require XCTest.

enum TestError: Error {
    case unexpectedNil
}

// Same signature as the original.
func XCTUnwrap<T>(_ expression: @autoclosure () throws -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) throws -> T {
    if let value = try expression() {
        return value
    } else {
        throw TestError.unexpectedNil
    }
}

func swiftVersionString() -> String {
    #if compiler(>=5.0) && compiler(<5.1)
        return "5.0"  // We support 5.0 or later.
    #elseif compiler(>=5.1)
        return "5.1"
    #endif
}
