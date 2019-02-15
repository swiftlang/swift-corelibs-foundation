// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//



func checkHashing_ValueType<Item: Hashable, S: Sequence>(
    initialValue item: Item,
    byMutating keyPath: WritableKeyPath<Item, S.Element>,
    throughValues values: S,
    file: StaticString = #file,
    line: UInt = #line
) {
    _checkHashing(
        ofType: Item.self,
        withMutableCounterpart: Item.self,
        initialValue: item,
        mutableCopyBlock: { $0 },
        byMutating: keyPath,
        throughValues: values,
        file: file,
        line: line)
}

func checkHashing_NSCopying<Item: NSObject & NSCopying, S: Sequence>(
    initialValue item: Item,
    byMutating keyPath: ReferenceWritableKeyPath<Item, S.Element>,
    throughValues values: S,
    file: StaticString = #file,
    line: UInt = #line
) {
    _checkHashing(
        ofType: Item.self,
        withMutableCounterpart: Item.self,
        initialValue: item,
        mutableCopyBlock: { $0.copy() as! Item },
        byMutating: keyPath,
        throughValues: values,
        file: file,
        line: line)
}

func checkHashing_NSMutableCopying<
  Source: NSObject & NSMutableCopying,
  Target: NSObject & NSMutableCopying,
  S: Sequence
>(
    initialValue item: Source,
    byMutating keyPath: ReferenceWritableKeyPath<Target, S.Element>,
    throughValues values: S,
    file: StaticString = #file,
    line: UInt = #line
) {
    _checkHashing(
        ofType: Source.self,
        withMutableCounterpart: Target.self,
        initialValue: item,
        mutableCopyBlock: { $0.mutableCopy() as! Target },
        byMutating: keyPath,
        throughValues: values,
        file: file,
        line: line)
}

// Check that mutating `object` via the specified key path affects its
// hash value.
func _checkHashing<Source: Hashable, Target: Hashable, S: Sequence>(
    ofType source: Source.Type,
    withMutableCounterpart target: Target.Type,
    initialValue object: Source,
    mutableCopyBlock copyBlock: (Source) -> Target,
    byMutating keyPath: WritableKeyPath<Target, S.Element>,
    throughValues values: S,
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

enum TestError: Error {
    case unexpectedNil
}

extension Optional {
    func unwrapped(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) throws -> Wrapped {
        if let x = self {
            return x
        } else {
            XCTFail("Tried to invoke .unwrapped() on nil in \(file):\(line):\(fn)")
            throw TestError.unexpectedNil
        }
    }
}

// Shims for StdlibUnittest:
// These allow for test code to be written targeting the overlay and then ported to s-c-f, or vice versa.
// You can use the FOUNDATION_XCTEST compilation condition to distinguish between tests running in XCTest
// or in StdlibUnittest.

func expectThrows<Error: Swift.Error & Equatable>(_ expectedError: Error, _ test: () throws -> Void, _ message: @autoclosure () -> String = "") {
    var caught = false
    do {
        try test()
    } catch let error as Error {
        caught = true
        XCTAssertEqual(error, expectedError, message())
    } catch {
        caught = true
        XCTFail("Incorrect error thrown: \(error) -- \(message())")
    }
    XCTAssert(caught, "No error thrown -- \(message())")
}

func expectDoesNotThrow(_ test: () throws -> Void, _ message: @autoclosure () -> String = "") {
    XCTAssertNoThrow(try test(), message())
}

func expectTrue(_ actual: Bool, _ message: @autoclosure () -> String = "") {
    XCTAssertTrue(actual, message())
}

func expectFalse(_ actual: Bool, _ message: @autoclosure () -> String = "") {
    XCTAssertFalse(actual, message())
}

func expectEqual<T: Equatable>(_ expected: T, _ actual: T, _ message: @autoclosure () -> String = "") {
    XCTAssertEqual(expected, actual, message())
}

func expectEqual<T: FloatingPoint>(_ expected: T, _ actual: T, within: T, _ message: @autoclosure () -> String = "") {
    XCTAssertEqual(expected, actual, accuracy: within, message())
}

func expectEqual<T: FloatingPoint>(_ expected: T?, _ actual: T, within: T, _ message: @autoclosure () -> String = "") {
    XCTAssertNotNil(expected, message())
    if let expected = expected {
        XCTAssertEqual(expected, actual, accuracy: within, message())
    }
}

