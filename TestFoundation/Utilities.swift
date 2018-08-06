// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


func checkHashableMutations_ValueType<Item: Hashable, S: Sequence>(
    _ item: Item,
    _ keyPath: WritableKeyPath<Item, S.Element>,
    _ values: S,
    file: StaticString = #file,
    line: UInt = #line
) {
    _checkHashableMutations(
        Item.self, Item.self,
        item,
        { $0 },
        keyPath,
        values)
}

func checkHashableMutations_NSCopying<Item: NSObject & NSCopying, S: Sequence>(
    _ item: Item,
    _ keyPath: ReferenceWritableKeyPath<Item, S.Element>,
    _ values: S,
    file: StaticString = #file,
    line: UInt = #line
) {
    _checkHashableMutations(
        Item.self, Item.self,
        item,
        { $0.copy() as! Item },
        keyPath,
        values)
}

func checkHashableMutations_NSMutableCopying<
  Source: NSObject & NSMutableCopying,
  Target: NSObject & NSMutableCopying,
  S: Sequence
>(
    _ item: Source,
    _ keyPath: ReferenceWritableKeyPath<Target, S.Element>,
    _ values: S,
    file: StaticString = #file,
    line: UInt = #line
) {
    _checkHashableMutations(
        Source.self, Target.self,
        item,
        { $0.mutableCopy() as! Target },
        keyPath,
        values)
}

// Check that mutating `object` via the specified key path affects its
// hash value.
func _checkHashableMutations<Source: Hashable, Target: Hashable, S: Sequence>(
    _ source: Source.Type,
    _ target: Target.Type,
    _ object: Source,
    _ copyBlock: (Source) -> Target,
    _ keyPath: WritableKeyPath<Target, S.Element>,
    _ values: S,
    file: StaticString = #file,
    line: UInt = #line
) {
    let reference = copyBlock(object)
    let referenceHash = reference.hashValue

    XCTAssertEqual(
        reference.hashValue, referenceHash,
        "\(type(of: reference)).hashValue is nondeterministic",
        file: file, line: line)

    var found = false
    for value in values {
        var copy = copyBlock(object)
        XCTAssertEqual(
            copy, reference,
            "Invalid copy operation",
            file: file, line: line)
        XCTAssertEqual(
            copy.hashValue, referenceHash,
            "Invalid copy operation",
            file: file, line: line)
        copy[keyPath: keyPath] = value
        XCTAssertNotEqual(
            reference, copy,
            "\(keyPath) did not affect object equality",
            file: file, line: line)
        if referenceHash != copy.hashValue {
            found = true
        }
    }
    if !found {
        XCTFail(
            "\(keyPath) does not seem to contribute to the hash value",
            file: file, line: line)
    }
}
