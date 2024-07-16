// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTestObservationCenter.swift
//  Notification center for test run progress events.
//

private let _sharedCenter: XCTestObservationCenter = XCTestObservationCenter()

/// Provides a registry for objects wishing to be informed about progress
/// during the course of a test run. Observers must implement the
/// `XCTestObservation` protocol
/// - seealso: `XCTestObservation`
public class XCTestObservationCenter {

    private var observers = Set<ObjectWrapper<XCTestObservation>>()

    /// Registration should be performed on this shared instance
    public class var shared: XCTestObservationCenter {
        return _sharedCenter
    }

    /// Register an observer to receive future events during a test run. The order
    /// in which individual observers are notified about events is undefined.
    public func addTestObserver(_ testObserver: XCTestObservation) {
        observers.insert(testObserver.wrapper)
    }

    /// Remove a previously-registered observer so that it will no longer receive
    /// event callbacks.
    public func removeTestObserver(_ testObserver: XCTestObservation) {
        observers.remove(testObserver.wrapper)
    }

    internal func testBundleWillStart(_ testBundle: Bundle) {
        forEachObserver { $0.testBundleWillStart(testBundle) }
    }

    internal func testSuiteWillStart(_ testSuite: XCTestSuite) {
        forEachObserver { $0.testSuiteWillStart(testSuite) }
    }

    internal func testCaseWillStart(_ testCase: XCTestCase) {
        forEachObserver { $0.testCaseWillStart(testCase) }
    }

    internal func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: Int) {
        forEachObserver { $0.testCase(testCase, didFailWithDescription: description, inFile: filePath, atLine: lineNumber) }
    }

    internal func testCase(_ testCase: XCTestCase, wasSkippedWithDescription description: String, at sourceLocation: SourceLocation?) {
        forEachInternalObserver { $0.testCase(testCase, wasSkippedWithDescription: description, at: sourceLocation) }
    }

    internal func testCaseDidFinish(_ testCase: XCTestCase) {
        forEachObserver { $0.testCaseDidFinish(testCase) }
    }

    internal func testSuiteDidFinish(_ testSuite: XCTestSuite) {
        forEachObserver { $0.testSuiteDidFinish(testSuite) }
    }

    internal func testBundleDidFinish(_ testBundle: Bundle) {
        forEachObserver { $0.testBundleDidFinish(testBundle) }
    }

    internal func testCase(_ testCase: XCTestCase, didMeasurePerformanceResults results: String, file: StaticString, line: Int) {
        forEachInternalObserver { $0.testCase(testCase, didMeasurePerformanceResults: results, file: file, line: line) }
    }

    private func forEachObserver(_ body: (XCTestObservation) -> Void) {
        for observer in observers {
            body(observer.object)
        }
    }

    private func forEachInternalObserver(_ body: (XCTestInternalObservation) -> Void) {
        for observer in observers where observer.object is XCTestInternalObservation {
            body(observer.object as! XCTestInternalObservation)
        }
    }
}

private extension XCTestObservation {
    var wrapper: ObjectWrapper<XCTestObservation> {
        return ObjectWrapper(object: self, objectIdentifier: ObjectIdentifier(self))
    }
}
