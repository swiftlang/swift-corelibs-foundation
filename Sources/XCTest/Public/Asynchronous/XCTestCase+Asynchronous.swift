// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTestCase+Asynchronous.swift
//  Methods on XCTestCase for testing asynchronous operations
//

public extension XCTestCase {

    /// Creates a point of synchronization in the flow of a test. Only one
    /// "wait" can be active at any given time, but multiple discrete sequences
    /// of { expectations -> wait } can be chained together. The related
    /// XCTWaiter API allows multiple "nested" waits if that is required.
    ///
    /// - Parameter timeout: The amount of time within which all expectation
    ///   must be fulfilled.
    /// - Parameter file: The file name to use in the error message if
    ///   expectations are not met before the given timeout. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   expectations are not met before the given timeout. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    /// - Parameter handler: If provided, the handler will be invoked both on
    ///   timeout or fulfillment of all expectations. Timeout is always treated
    ///   as a test failure.
    ///
    /// - SeeAlso: XCTWaiter
    ///
    /// - Note: Whereas Objective-C XCTest determines the file and line
    ///   number of the "wait" call using symbolication, this implementation
    ///   opts to take `file` and `line` as parameters instead. As a result,
    ///   the interface to these methods are not exactly identical between
    ///   these environments. To ensure compatibility of tests between
    ///   swift-corelibs-xctest and Apple XCTest, it is not recommended to pass
    ///   explicit values for `file` and `line`.
    @preconcurrency @MainActor
    func waitForExpectations(timeout: TimeInterval, file: StaticString = #file, line: Int = #line, handler: XCWaitCompletionHandler? = nil) {
        precondition(Thread.isMainThread, "\(#function) must be called on the main thread")
        if currentWaiter != nil {
            return recordFailure(description: "API violation - calling wait on test case while already waiting.", at: SourceLocation(file: file, line: line), expected: false)
        }
        let expectations = self.expectations
        if expectations.isEmpty {
            return recordFailure(description: "API violation - call made to wait without any expectations having been set.", at: SourceLocation(file: file, line: line), expected: false)
        }

        let waiter = XCTWaiter(delegate: self)
        currentWaiter = waiter

        let waiterResult = waiter.wait(for: expectations, timeout: timeout, file: file, line: line)

        currentWaiter = nil

        cleanUpExpectations(expectations)

        // The handler is invoked regardless of whether the test passed.
        if let handler = handler {
            let error = (waiterResult == .completed) ? nil : XCTestError(.timeoutWhileWaiting)
            handler(error)
        }
    }

    /// Wait on an array of expectations for up to the specified timeout, and optionally specify whether they
    /// must be fulfilled in the given order. May return early based on fulfillment of the waited on expectations.
    ///
    /// - Parameter expectations: The expectations to wait on.
    /// - Parameter timeout: The maximum total time duration to wait on all expectations.
    /// - Parameter enforceOrder: Specifies whether the expectations must be fulfilled in the order
    ///   they are specified in the `expectations` Array. Default is false.
    /// - Parameter file: The file name to use in the error message if
    ///   expectations are not fulfilled before the given timeout. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   expectations are not fulfilled before the given timeout. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    ///
    /// - SeeAlso: XCTWaiter
    @available(*, noasync, message: "Use await fulfillment(of:timeout:enforceOrder:) instead.")
    func wait(for expectations: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool = false, file: StaticString = #file, line: Int = #line) {
        let waiter = XCTWaiter(delegate: self)
        waiter.wait(for: expectations, timeout: timeout, enforceOrder: enforceOrder, file: file, line: line)

        cleanUpExpectations(expectations)
    }

    /// Wait on an array of expectations for up to the specified timeout, and optionally specify whether they
    /// must be fulfilled in the given order. May return early based on fulfillment of the waited on expectations.
    ///
    /// - Parameter expectations: The expectations to wait on.
    /// - Parameter timeout: The maximum total time duration to wait on all expectations.
    /// - Parameter enforceOrder: Specifies whether the expectations must be fulfilled in the order
    ///   they are specified in the `expectations` Array. Default is false.
    /// - Parameter file: The file name to use in the error message if
    ///   expectations are not fulfilled before the given timeout. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   expectations are not fulfilled before the given timeout. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    ///
    /// - SeeAlso: XCTWaiter
    @available(macOS 12.0, *)
    func fulfillment(of expectations: [XCTestExpectation], timeout: TimeInterval, enforceOrder: Bool = false, file: StaticString = #file, line: Int = #line) async {
        let waiter = XCTWaiter(delegate: self)
        await waiter.fulfillment(of: expectations, timeout: timeout, enforceOrder: enforceOrder, file: file, line: line)

        cleanUpExpectations(expectations)
    }

    /// Creates and returns an expectation associated with the test case.
    ///
    /// - Parameter description: This string will be displayed in the test log
    ///   to help diagnose failures.
    /// - Parameter file: The file name to use in the error message if
    ///   this expectation is not waited for. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   this expectation is not waited for. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    ///
    /// - Note: Whereas Objective-C XCTest determines the file and line
    ///   number of expectations that are created by using symbolication, this
    ///   implementation opts to take `file` and `line` as parameters instead.
    ///   As a result, the interface to these methods are not exactly identical
    ///   between these environments. To ensure compatibility of tests between
    ///   swift-corelibs-xctest and Apple XCTest, it is not recommended to pass
    ///   explicit values for `file` and `line`.
    @discardableResult func expectation(description: String, file: StaticString = #file, line: Int = #line) -> XCTestExpectation {
        let expectation = XCTestExpectation(description: description, file: file, line: line)
        addExpectation(expectation)
        return expectation
    }

    /// Creates and returns an expectation for a notification.
    ///
    /// - Parameter notificationName: The name of the notification the
    ///   expectation observes.
    /// - Parameter object: The object whose notifications the expectation will
    ///   receive; that is, only notifications with this object are observed by
    ///   the test case. If you pass nil, the expectation doesn't use
    ///   a notification's object to decide whether it is fulfilled.
    /// - Parameter notificationCenter: The specific notification center that
    ///   the notification will be posted to.
    /// - Parameter handler: If provided, the handler will be invoked when the
    ///   notification is observed. It will not be invoked on timeout. Use the
    ///   handler to further investigate if the notification fulfills the
    ///   expectation.
    @discardableResult func expectation(forNotification notificationName: Notification.Name, object: Any? = nil, notificationCenter: NotificationCenter = .default, file: StaticString = #file, line: Int = #line, handler: XCTNSNotificationExpectation.Handler? = nil) -> XCTestExpectation {
        let expectation = XCTNSNotificationExpectation(name: notificationName, object: object, notificationCenter: notificationCenter, file: file, line: line)
        expectation.handler = handler
        addExpectation(expectation)
        return expectation
    }

    /// Creates and returns an expectation for a notification.
    ///
    /// - Parameter notificationName: The name of the notification the
    ///   expectation observes.
    /// - Parameter object: The object whose notifications the expectation will
    ///   receive; that is, only notifications with this object are observed by
    ///   the test case. If you pass nil, the expectation doesn't use
    ///   a notification's object to decide whether it is fulfilled.
    /// - Parameter notificationCenter: The specific notification center that
    ///   the notification will be posted to.
    /// - Parameter handler: If provided, the handler will be invoked when the
    ///   notification is observed. It will not be invoked on timeout. Use the
    ///   handler to further investigate if the notification fulfills the
    ///   expectation.
    @discardableResult func expectation(forNotification notificationName: String, object: Any? = nil, notificationCenter: NotificationCenter = .default, file: StaticString = #file, line: Int = #line, handler: XCTNSNotificationExpectation.Handler? = nil) -> XCTestExpectation {
        return expectation(forNotification: Notification.Name(rawValue: notificationName), object: object, notificationCenter: notificationCenter, file: file, line: line, handler: handler)
    }

    /// Creates and returns an expectation that is fulfilled if the predicate
    /// returns true when evaluated with the given object. The expectation
    /// periodically evaluates the predicate and also may use notifications or
    /// other events to optimistically re-evaluate.
    ///
    /// - Parameter predicate: The predicate that will be used to evaluate the
    ///   object.
    /// - Parameter object: The object that is evaluated against the conditions
    ///   specified by the predicate, if any. Default is nil.
    /// - Parameter file: The file name to use in the error message if
    ///   this expectation is not waited for. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   this expectation is not waited for. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    /// - Parameter handler: A block to be invoked when evaluating the predicate
    ///   against the object returns true. If the block is not provided the
    ///   first successful evaluation will fulfill the expectation. If provided,
    ///   the handler can override that behavior which leaves the caller
    ///   responsible for fulfilling the expectation.
    @discardableResult func expectation(for predicate: NSPredicate, evaluatedWith object: Any? = nil, file: StaticString = #file, line: Int = #line, handler: XCTNSPredicateExpectation.Handler? = nil) -> XCTestExpectation {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: object, file: file, line: line)
        expectation.handler = handler
        addExpectation(expectation)
        return expectation
    }

}

/// A block to be invoked when a call to wait times out or has had all
/// associated expectations fulfilled.
///
/// - Parameter error: If the wait timed out or a failure was raised while
///   waiting, the error's code will specify the type of failure. Otherwise
///   error will be nil.
public typealias XCWaitCompletionHandler = (Error?) -> ()

extension XCTestCase: XCTWaiterDelegate {

    public func waiter(_ waiter: XCTWaiter, didTimeoutWithUnfulfilledExpectations unfulfilledExpectations: [XCTestExpectation]) {
        let expectationDescription = unfulfilledExpectations.map { $0.expectationDescription }.joined(separator: ", ")
        let failureDescription = "Asynchronous wait failed - Exceeded timeout of \(waiter.timeout) seconds, with unfulfilled expectations: \(expectationDescription)"
        recordFailure(description: failureDescription, at: waiter.waitSourceLocation ?? .unknown, expected: true)
    }

    public func waiter(_ waiter: XCTWaiter, fulfillmentDidViolateOrderingConstraintsFor expectation: XCTestExpectation, requiredExpectation: XCTestExpectation) {
        let failureDescription = "Failed due to expectation fulfilled in incorrect order: requires '\(requiredExpectation.expectationDescription)', actually fulfilled '\(expectation.expectationDescription)'"
        recordFailure(description: failureDescription, at: expectation.fulfillmentSourceLocation ?? .unknown, expected: true)
    }

    public func waiter(_ waiter: XCTWaiter, didFulfillInvertedExpectation expectation: XCTestExpectation) {
        let failureDescription = "Asynchronous wait failed - Fulfilled inverted expectation '\(expectation.expectationDescription)'"
        recordFailure(description: failureDescription, at: expectation.fulfillmentSourceLocation ?? .unknown, expected: true)
    }

    public func nestedWaiter(_ waiter: XCTWaiter, wasInterruptedByTimedOutWaiter outerWaiter: XCTWaiter) {
        let failureDescription = "Asynchronous waiter \(waiter) failed - Interrupted by timeout of containing waiter \(outerWaiter)"
        recordFailure(description: failureDescription, at: waiter.waitSourceLocation ?? .unknown, expected: true)
    }

}

internal extension XCTestCase {
    // It is an API violation to create expectations but not wait for them to
    // be completed. Notify the user of a mistake via a test failure.
    func failIfExpectationsNotWaitedFor(_ expectations: [XCTestExpectation]) {
        let orderedUnwaitedExpectations = expectations.filter { !$0.hasBeenWaitedOn }.sorted { $0.creationToken < $1.creationToken }
        guard let expectationForFileLineReporting = orderedUnwaitedExpectations.first else {
            return
        }

        let expectationDescriptions = orderedUnwaitedExpectations.map { "'\($0.expectationDescription)'" }.joined(separator: ", ")
        let failureDescription = "Failed due to unwaited expectation\(orderedUnwaitedExpectations.count > 1 ? "s" : "") \(expectationDescriptions)"

        recordFailure(
            description: failureDescription,
            at: expectationForFileLineReporting.creationSourceLocation,
            expected: false)
    }
}
