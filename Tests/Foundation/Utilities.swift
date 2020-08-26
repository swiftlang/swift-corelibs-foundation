// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DARWIN_COMPATIBILITY_TESTS
public typealias XCTestCaseEntry = (testCaseClass: XCTestCase.Type, allTests: [(String, XCTestCaseClosure)])
public typealias XCTestCaseClosure = (XCTestCase) throws -> Void

public func testCase<T: XCTestCase>(_ allTests: [(String, (T) -> () throws -> Void)]) -> XCTestCaseEntry {
    let tests: [(String, XCTestCaseClosure)] = allTests.map { ($0.0, test($0.1)) }
    return (T.self, tests)
}

private func test<T: XCTestCase>(_ testFunc: @escaping (T) -> () throws -> Void) -> XCTestCaseClosure {
    return { testCaseType in
        guard let testCase = testCaseType as? T else {
            fatalError("Attempt to invoke test on class \(T.self) with incompatible instance type \(type(of: testCaseType))")
        }

        try testFunc(testCase)()
    }
}
#endif


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
    case fileCreationFailed
}

extension Optional {
    @available(*, unavailable, message: "Use XCTUnwrap() instead")
    func unwrapped(_ fn: String = #function, file: StaticString = #file, line: UInt = #line) throws -> Wrapped {
        return try XCTUnwrap(self, file: file, line: line)
    }
}

// Shims for StdlibUnittest:
// These allow for test code to be written targeting the overlay and then ported to s-c-f, or vice versa.
// You can use the FOUNDATION_XCTEST compilation condition to distinguish between tests running in XCTest
// or in StdlibUnittest.

func expectThrows<Error: Swift.Error & Equatable>(_ expectedError: Error, _ test: () throws -> Void, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    var caught = false
    do {
        try test()
    } catch let error as Error {
        caught = true
        XCTAssertEqual(error, expectedError, message(), file: file, line: line)
    } catch {
        caught = true
        XCTFail("Incorrect error thrown: \(error) -- \(message())", file: file, line: line)
    }
    XCTAssert(caught, "No error thrown -- \(message())", file: file, line: line)
}

func expectDoesNotThrow(_ test: () throws -> Void, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertNoThrow(try test(), message(), file: file, line: line)
}

func expectTrue(_ actual: Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertTrue(actual, message(), file: file, line: line)
}

func expectFalse(_ actual: Bool, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertFalse(actual, message(), file: file, line: line)
}

func expectEqual<T: Equatable>(_ expected: T, _ actual: T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(expected, actual, message(), file: file, line: line)
}

func expectNotEqual<T: Equatable>(_ expected: T, _ actual: T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertNotEqual(expected, actual, message(), file: file, line: line)
}

func expectEqual<T: FloatingPoint>(_ expected: T, _ actual: T, within: T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(expected, actual, accuracy: within, message(), file: file, line: line)
}

func expectEqual<T: FloatingPoint>(_ expected: T?, _ actual: T, within: T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertNotNil(expected, message(), file: file, line: line)
    if let expected = expected {
        XCTAssertEqual(expected, actual, accuracy: within, message(), file: file, line: line)
    }
}

func expectEqual(
    _ expected: Any.Type,
    _ actual: Any.Type,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    XCTAssertTrue(expected == actual, message(), file: file, line: line)
}

func expectChanges<T: BinaryInteger>(_ check: @autoclosure () -> T, by difference: T? = nil, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, _ expression: () throws -> ()) rethrows {
    let valueBefore = check()
    try expression()
    let valueAfter = check()
    if let difference = difference {
        XCTAssertEqual(valueAfter, valueBefore + difference, message(), file: file, line: line)
    } else {
        XCTAssertNotEqual(valueAfter, valueBefore, message(), file: file, line: line)
    }
}

func expectNoChanges<T: BinaryInteger>(_ check: @autoclosure () -> T, by difference: T? = nil, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line, _ expression: () throws -> ()) rethrows {
    let valueBefore = check()
    try expression()
    let valueAfter = check()
    if let difference = difference {
        XCTAssertNotEqual(valueAfter, valueBefore + difference, message(), file: file, line: line)
    } else {
        XCTAssertEqual(valueAfter, valueBefore, message(), file: file, line: line)
    }
}

extension Fixture where ValueType: NSObject & NSCoding {
    func loadEach(handler: (ValueType, FixtureVariant) throws -> Void) throws {
        try self.loadEach(fixtureRepository: try XCTUnwrap(testBundle().url(forResource: "Fixtures", withExtension: nil)), handler: handler)
    }
    
    func assertLoadedValuesMatch(_ matchHandler: (ValueType, ValueType) -> Bool = { $0 == $1 }) throws {
        let reference = try make()
        try loadEach(handler: { (value, variant) in
            XCTAssertTrue(matchHandler(reference, value), "The fixture with identifier \(identifier) failed to match for on-disk variant \(variant)")
        })
    }
    
    func assertValueRoundtripsInCoder(settingUpArchiverWith archiverSetup: (NSKeyedArchiver) -> Void = { _ in}, unarchiverWith unarchiverSetup: (NSKeyedUnarchiver) -> Void = { _ in}, matchingWith: (ValueType, ValueType) -> Bool = { $0 == $1 }) throws {
        let original = try make()
        
        let coder = NSKeyedArchiver(forWritingWith: NSMutableData())
        archiverSetup(coder)
        
        coder.encode(original, forKey: NSKeyedArchiveRootObjectKey)
        coder.finishEncoding()
        
        let data = coder.encodedData
        
        let decoder = NSKeyedUnarchiver(forReadingWith: data)
        decoder.decodingFailurePolicy = .setErrorAndReturn
        unarchiverSetup(decoder)
        
        let object = decoder.decodeObject(of: ValueType.self, forKey: NSKeyedArchiveRootObjectKey)
        
        XCTAssertNil(decoder.error)
        if let object = object {
            XCTAssertTrue(matchingWith(object, original), "The fixture with identifier '\(identifier)' failed to match after an in-memory roundtrip.")
        } else {
            XCTFail("The fixture with identifier '\(identifier)' failed to decode after an in-memory roundtrip.")
        }
    }
    
    func assertValueRoundtripsInCoder(secureCoding: Bool, matchingWith: (ValueType, ValueType) -> Bool = { $0 == $1 }) throws {
        try assertValueRoundtripsInCoder(settingUpArchiverWith: { (archiver) in
            archiver.requiresSecureCoding = secureCoding
        }, unarchiverWith: { (unarchiver) in
            unarchiver.requiresSecureCoding = secureCoding
        }, matchingWith: matchingWith)
    }
}

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
    file: StaticString = #file,
    line: UInt = #line
) where Instances.Element: Equatable {
    let indices = Array(instances.indices)
    _checkEquatableImpl(
        Array(instances),
        oracle: { oracle(indices[$0], indices[$1]) },
        allowBrokenTransitivity: allowBrokenTransitivity,
        message(),
        file: file,
        line: line)
}

private class Box<T> {
    var value: T

    init(_ value: T) {
        self.value = value
    }
}

internal func _checkEquatableImpl<Instance : Equatable>(
    _ instances: [Instance],
    oracle: (Int, Int) -> Bool,
    allowBrokenTransitivity: Bool = false,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) {
    // For each index (which corresponds to an instance being tested) track the
    // set of equal instances.
    var transitivityScoreboard: [Box<Set<Int>>] =
        instances.indices.map { _ in Box([]) }

    for i in instances.indices {
        let x = instances[i]
        expectTrue(oracle(i, i), "bad oracle: broken reflexivity at index \(i)")

        for j in instances.indices {
            let y = instances[j]

            let predictedXY = oracle(i, j)
            expectEqual(
                predictedXY, oracle(j, i),
                "bad oracle: broken symmetry between indices \(i), \(j)",
                file: file,
                line: line)

            let isEqualXY = x == y
            expectEqual(
                predictedXY, isEqualXY,
                """
                \((predictedXY
                ? "expected equal, found not equal"
                : "expected not equal, found equal"))
                lhs (at index \(i)): \(String(reflecting: x))
                rhs (at index \(j)): \(String(reflecting: y))
                """,
                file: file,
                line: line)

            // Not-equal is an inverse of equal.
            expectNotEqual(
                isEqualXY, x != y,
                """
                lhs (at index \(i)): \(String(reflecting: x))
                rhs (at index \(j)): \(String(reflecting: y))
                """,
                file: file,
                line: line)

            if !allowBrokenTransitivity {
                // Check transitivity of the predicate represented by the oracle.
                // If we are adding the instance `j` into an equivalence set, check that
                // it is equal to every other instance in the set.
                if predictedXY && i < j && transitivityScoreboard[i].value.insert(j).inserted {
                    if transitivityScoreboard[i].value.count == 1 {
                        transitivityScoreboard[i].value.insert(i)
                    }
                    for k in transitivityScoreboard[i].value {
                        expectTrue(
                            oracle(j, k),
                            "bad oracle: broken transitivity at indices \(i), \(j), \(k)",
                            file: file,
                            line: line)
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

func hash<H: Hashable>(_ value: H, salt: Int? = nil) -> Int {
    var hasher = Hasher()
    if let salt = salt {
        hasher.combine(salt)
    }
    hasher.combine(value)
    return hasher.finalize()
}

public func checkHashable<Instances: Collection>(
    _ instances: Instances,
    equalityOracle: (Instances.Index, Instances.Index) -> Bool,
    allowIncompleteHashing: Bool = false,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line
) where Instances.Element: Hashable {
    checkHashable(
        instances,
        equalityOracle: equalityOracle,
        hashEqualityOracle: equalityOracle,
        allowIncompleteHashing: allowIncompleteHashing,
        message(),
        file: file,
        line: line)
}


public func checkHashable<Instances: Collection>(
    _ instances: Instances,
    equalityOracle: (Instances.Index, Instances.Index) -> Bool,
    hashEqualityOracle: (Instances.Index, Instances.Index) -> Bool,
    allowIncompleteHashing: Bool = false,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line
) where Instances.Element: Hashable {

    checkEquatable(
        instances,
        oracle: equalityOracle,
        message(),
        file: file,
        line: line)

    for i in instances.indices {
        let x = instances[i]
        for j in instances.indices {
            let y = instances[j]
            let predicted = hashEqualityOracle(i, j)
            XCTAssertEqual(
                predicted,
                hashEqualityOracle(j, i),
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
                    (0..<10).contains { hash(x, salt: $0) != hash(y, salt: $0) },
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

/// Test that the elements of `groups` consist of instances that satisfy the
/// semantic requirements of `Hashable`, with each group defining a distinct
/// equivalence class under `==`.
public func checkHashableGroups<Groups: Collection>(
    _ groups: Groups,
    _ message: @autoclosure () -> String = "",
    allowIncompleteHashing: Bool = false,
    file: StaticString = #file,
    line: UInt = #line
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
        allowIncompleteHashing: allowIncompleteHashing,
        file: file,
        line: line)
}

private var shouldRunXFailTests: Bool {
    return ProcessInfo.processInfo.environment["NS_FOUNDATION_ATTEMPT_XFAIL_TESTS"] == "YES"
}


private func printStderr(_ msg: String) {
    try? FileHandle.standardError.write(contentsOf: Data(msg.utf8))
}

func shouldAttemptXFailTests(_ reason: String) -> Bool {
    if shouldRunXFailTests {
        return true
    } else {
        printStderr("warning: Skipping test expected to fail with reason '\(reason)'\n")
        return false
    }
}

func shouldAttemptWindowsXFailTests(_ reason: String) -> Bool {
    #if os(Windows)
    return shouldAttemptXFailTests(reason)
    #else
    return true
    #endif
}

func shouldAttemptAndroidXFailTests(_ reason: String) -> Bool {
    #if os(Android)
    return shouldAttemptXFailTests(reason)
    #else
    return true
    #endif
}

#if !DARWIN_COMPATIBILITY_TESTS
func testCaseExpectedToFail<T: XCTestCase>(_ allTests: [(String, (T) -> () throws -> Void)], _ reason: String) -> XCTestCaseEntry {
    return testCase(allTests.map { ($0.0, testExpectedToFail($0.1, "This test suite is disabled: \(reason)")) })
}
#endif

func appendTestCaseExpectedToFail<T: XCTestCase>(_ reason: String, _ allTests: [(String, (T) -> () throws -> Void)], into array: inout [XCTestCaseEntry]) {
    if shouldAttemptXFailTests(reason) {
        array.append(testCase(allTests))
    }
}

func testExpectedToFail<T>(_ test:  @escaping (T) -> () throws -> Void, _ reason: String) -> (T) -> () throws -> Void {
    testExpectedToFailWithCheck(check: shouldAttemptXFailTests(_:), test, reason)
}

func testExpectedToFailOnWindows<T>(_ test:  @escaping (T) -> () throws -> Void, _ reason: String) -> (T) -> () throws -> Void {
    testExpectedToFailWithCheck(check: shouldAttemptWindowsXFailTests(_:), test, reason)
}

func testExpectedToFailOnAndroid<T>(_ test: @escaping (T) -> () throws -> Void, _ reason: String) -> (T) -> () throws -> Void {
    testExpectedToFailWithCheck(check: shouldAttemptAndroidXFailTests(_:), test, reason)
}

func testExpectedToFailWithCheck<T>(check: (String) -> Bool, _ test:  @escaping (T) -> () throws -> Void, _ reason: String) -> (T) -> () throws -> Void {
    if check(reason) {
        return test
    } else {
        return { _ in return { } }
    }
}

extension XCTest {
    func assertCrashes(within block: () throws -> Void) rethrows {
        let childProcessEnvVariable = "NS_FOUNDATION_TEST_PERFORM_ASSERT_CRASHES_BLOCKS"
        let childProcessEnvVariableOnValue = "YES"
        
        let isChildProcess = ProcessInfo.processInfo.environment[childProcessEnvVariable] == childProcessEnvVariableOnValue
        
        if isChildProcess {
            try block()
        } else {
            var arguments = ProcessInfo.processInfo.arguments
            let process = Process()
            process.executableURL = URL(fileURLWithPath: arguments[0])
            
            arguments.remove(at: 0)
            arguments.removeAll(where: { $0.hasPrefix("TestFoundation.") })
            arguments.append("TestFoundation." + self.name.replacingOccurrences(of: ".", with: "/"))
            process.arguments = arguments
            
            var environment = ProcessInfo.processInfo.environment
            environment[childProcessEnvVariable] = childProcessEnvVariableOnValue
            process.environment = environment
            
            do {
                try process.run()
                process.waitUntilExit()
                XCTAssertEqual(process.terminationReason, .uncaughtSignal, "Child process should have crashed: \(process)")
            } catch {
                XCTFail("Couldn't start child process for testing crash: \(process) - \(error)")
            }
            
        }
    }
}

extension String {
    public func standardizePath() -> String {
        URL(fileURLWithPath: self).resolvingSymlinksInPath().path
    }
}

extension FileHandle: TextOutputStream {
    public func write(_ string: String) {
        write(Data(string.utf8))
    }
    
    struct EncodedOutputStream: TextOutputStream {
        let fileHandle: FileHandle
        let encoding: String.Encoding
        
        init(_ fileHandle: FileHandle, encoding: String.Encoding) {
            self.fileHandle = fileHandle
            self.encoding = encoding
        }
        
        func write(_ string: String) {
            fileHandle.write(string.data(using: encoding)!)
        }
    }
}

extension NSLock {
    public func synchronized<T>(_ closure: () throws -> T) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try closure()
    }
}


// Create a uniquely named temporary directory, pass the URL and path to a closure then remove the directory afterwards.
public func withTemporaryDirectory<R>(functionName: String = #function, block: (URL, String) throws -> R) throws -> R {

    // Find the name of the function upto '('
    guard let idx = functionName.firstIndex(of: "(") else {
        throw TestError.unexpectedNil
    }

    let fname = String(functionName[..<idx])
    let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(testBundleName()).appendingPathComponent(fname).appendingPathComponent(NSUUID().uuidString)
    let fm = FileManager.default
    try? fm.removeItem(at: tmpDir)
    try fm.createDirectory(at: tmpDir, withIntermediateDirectories: true)
    defer { try? fm.removeItem(at: tmpDir) }

    return try block(tmpDir, tmpDir.path)
}
