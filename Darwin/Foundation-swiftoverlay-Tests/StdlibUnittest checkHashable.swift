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

/// Produce an integer hash value for `value` by feeding it to a dedicated
/// `Hasher`. This is always done by calling the `hash(into:)` method.
/// If a non-nil `seed` is given, it is used to perturb the hasher state;
/// this is useful for resolving accidental hash collisions.
private func hash<H: Hashable>(_ value: H, seed: Int? = nil) -> Int {
  var hasher = Hasher()
  if let seed = seed {
    hasher.combine(seed)
  }
  hasher.combine(value)
  return hasher.finalize()
}

/// Test that the elements of `groups` consist of instances that satisfy the
/// semantic requirements of `Hashable`, with each group defining a distinct
/// equivalence class under `==`.
public func checkHashableGroups<Groups: Collection>(
  _ groups: Groups,
  _ message: @autoclosure () -> String = "",
  allowIncompleteHashing: Bool = false,
  file: StaticString = #file, line: UInt = #line
) where Groups.Element: Collection, Groups.Element.Element: Hashable {
  let instances = groups.flatMap { $0 }
  // groupIndices[i] is the index of the element in groups that contains
  // instances[i].
  let groupIndices =
    zip(0..., groups).flatMap { i, group in group.map { _ in i } }
  func equalityOracle(_ lhs: Int, _ rhs: Int) -> Bool {
    return groupIndices[lhs] == groupIndices[rhs]
  }
  checkHashable(
    instances,
    equalityOracle: equalityOracle,
    hashEqualityOracle: equalityOracle,
    allowBrokenTransitivity: false,
    allowIncompleteHashing: allowIncompleteHashing,
    file: file, line: line)
}

/// Test that the elements of `instances` satisfy the semantic requirements of
/// `Hashable`, using `equalityOracle` to generate equality and hashing
/// expectations from pairs of positions in `instances`.
public func checkHashable<Instances: Collection>(
  _ instances: Instances,
  equalityOracle: (Instances.Index, Instances.Index) -> Bool,
  allowBrokenTransitivity: Bool = false,
  allowIncompleteHashing: Bool = false,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file, line: UInt = #line
) where Instances.Element: Hashable {
  checkHashable(
    instances,
    equalityOracle: equalityOracle,
    hashEqualityOracle: equalityOracle,
    allowBrokenTransitivity: allowBrokenTransitivity,
    allowIncompleteHashing: allowIncompleteHashing,
    file: file, line: line)
}

/// Test that the elements of `instances` satisfy the semantic
/// requirements of `Hashable`, using `equalityOracle` to generate
/// equality expectations from pairs of positions in `instances`,
/// and `hashEqualityOracle` to do the same for hashing.
public func checkHashable<Instances: Collection>(
  _ instances: Instances,
  equalityOracle: (Instances.Index, Instances.Index) -> Bool,
  hashEqualityOracle: (Instances.Index, Instances.Index) -> Bool,
  allowBrokenTransitivity: Bool = false,
  allowIncompleteHashing: Bool = false,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file, line: UInt = #line
) where
  Instances.Element: Hashable {
  checkEquatable(
    instances,
    oracle: equalityOracle,
    allowBrokenTransitivity: allowBrokenTransitivity,
    message(),
    file: file, line: line)

  for i in instances.indices {
    let x = instances[i]
    for j in instances.indices {
      let y = instances[j]
      let predicted = hashEqualityOracle(i, j)
      XCTAssertEqual(
        predicted, hashEqualityOracle(j, i),
        "bad hash oracle: broken symmetry between indices \(i), \(j)",
        file: file, line: line)
      if x == y {
        XCTAssertTrue(
          predicted,
          """
          bad hash oracle: equality must imply hash equality
          lhs (at index \(i)): \(x)
          rhs (at index \(j)): \(y)
          """,
          file: file, line: line)
      }
      if predicted {
        XCTAssertEqual(
          hash(x), hash(y),
          """
          hash(into:) expected to match, found to differ
          lhs (at index \(i)): \(x)
          rhs (at index \(j)): \(y)
          """,
          file: file, line: line)
        XCTAssertEqual(
          x.hashValue, y.hashValue,
          """
          hashValue expected to match, found to differ
          lhs (at index \(i)): \(x)
          rhs (at index \(j)): \(y)
          """,
          file: file, line: line)
        XCTAssertEqual(
          x._rawHashValue(seed: 0), y._rawHashValue(seed: 0),
          """
          _rawHashValue(seed:) expected to match, found to differ
          lhs (at index \(i)): \(x)
          rhs (at index \(j)): \(y)
          """,
          file: file, line: line)
      } else if !allowIncompleteHashing {
        // Try a few different seeds; at least one of them should discriminate
        // between the hashes. It is extremely unlikely this check will fail
        // all ten attempts, unless the type's hash encoding is not unique,
        // or unless the hash equality oracle is wrong.
        XCTAssertTrue(
          (0..<10).contains { hash(x, seed: $0) != hash(y, seed: $0) },
          """
          hash(into:) expected to differ, found to match
          lhs (at index \(i)): \(x)
          rhs (at index \(j)): \(y)
          """,
          file: file, line: line)
        XCTAssertTrue(
          (0..<10).contains { i in
            x._rawHashValue(seed: i) != y._rawHashValue(seed: i)
          },
          """
          _rawHashValue(seed:) expected to differ, found to match
          lhs (at index \(i)): \(x)
          rhs (at index \(j)): \(y)
          """,
          file: file, line: line)
      }
    }
  }
}

public func checkHashable<T : Hashable>(
  expectedEqual: Bool, _ lhs: T, _ rhs: T,
  _ message: @autoclosure () -> String = "",
  file: StaticString = #file, line: UInt = #line
) {
  checkHashable(
    [lhs, rhs], equalityOracle: { expectedEqual || $0 == $1 }, message(),
    file: file, line: line)
}
