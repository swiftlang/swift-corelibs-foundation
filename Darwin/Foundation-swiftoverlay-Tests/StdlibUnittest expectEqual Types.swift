//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// FIXME: This should be in a separate package:
// rdar://57247249 Port StdlibUnittest's collection test suite to XCTest

import XCTest

public func expectEqual(
  _ expected: Any.Type, _ actual: Any.Type,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file, line: UInt = #line
) {
    guard expected != actual else { return }
    var report =  """
        expected: \(String(reflecting: expected)) (of type \(String(reflecting: type(of: expected))))
        actual: \(String(reflecting: actual)) (of type \(String(reflecting: type(of: actual))))
        """
    let message = message()
    if message != "" {
        report += "\n\(message)"
    }
    XCTFail(report, file: file, line: line)
}
