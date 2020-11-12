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

//
// Semantic tests for protocol conformance
//

/// Test that the elements of `instances` satisfy the semantic
/// requirements of `Equatable`, using `oracle` to generate equality
/// expectations from pairs of positions in `instances`.
///
/// - Note: `oracle` is also checked for conformance to the
///   laws.
public func checkEquatable<Instances: Collection>(
  _ instances: Instances,
  oracle: (Instances.Index, Instances.Index) -> Bool,
  allowBrokenTransitivity: Bool = false,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file, line: UInt = #line
) where
  Instances.Element: Equatable
{
  let indices = Array(instances.indices)
  _checkEquatableImpl(
    Array(instances),
    oracle: { oracle(indices[$0], indices[$1]) },
    allowBrokenTransitivity: allowBrokenTransitivity,
    message(),
    file: file,
    line: line)
}

public final class Box<T> {
  public init(_ value: T) { self.value = value }
  public var value: T
}

internal func _checkEquatableImpl<Instance : Equatable>(
  _ instances: [Instance],
  oracle: (Int, Int) -> Bool,
  allowBrokenTransitivity: Bool = false,

  _ message: @autoclosure () -> String = "",
  file: StaticString,
  line: UInt
) {
  // For each index (which corresponds to an instance being tested) track the
  // set of equal instances.
  var transitivityScoreboard: [Box<Set<Int>>] =
    instances.indices.map { _ in Box(Set()) }

  // TODO: swift-3-indexing-model: add tests for this function.
  for i in instances.indices {
    let x = instances[i]
    XCTAssertTrue(oracle(i, i), "bad oracle: broken reflexivity at index \(i)", file: file, line: line)

    for j in instances.indices {
      let y = instances[j]

      let predictedXY = oracle(i, j)
      XCTAssertEqual(
        predictedXY, oracle(j, i),
        "bad oracle: broken symmetry between indices \(i), \(j)",
        file: file, line: line)

      let isEqualXY = x == y
      XCTAssertEqual(
        predictedXY, isEqualXY,
        """
        \((predictedXY
           ? "expected equal, found not equal"
           : "expected not equal, found equal"))
        lhs (at index \(i)): \(String(reflecting: x))
        rhs (at index \(j)): \(String(reflecting: y))
        """,
        file: file, line: line)

      // Not-equal is an inverse of equal.
      XCTAssertNotEqual(
        isEqualXY, x != y,
        """
        lhs (at index \(i)): \(String(reflecting: x))
        rhs (at index \(j)): \(String(reflecting: y))
        """,
        file: file, line: line)

      if !allowBrokenTransitivity {
        // Check transitivity of the predicate represented by the oracle.
        // If we are adding the instance `j` into an equivalence set, check that
        // it is equal to every other instance in the set.
        if predictedXY && i < j && transitivityScoreboard[i].value.insert(j).inserted {
          if transitivityScoreboard[i].value.count == 1 {
            transitivityScoreboard[i].value.insert(i)
          }
          for k in transitivityScoreboard[i].value {
            XCTAssertTrue(
              oracle(j, k),
              "bad oracle: broken transitivity at indices \(i), \(j), \(k)",
              file: file, line: line)
              // No need to check equality between actual values, we will check
              // them with the checks above.
          }
          precondition(transitivityScoreboard[j].value.isEmpty)
          transitivityScoreboard[j] = transitivityScoreboard[i]
        }
      }
    }
  }
}

