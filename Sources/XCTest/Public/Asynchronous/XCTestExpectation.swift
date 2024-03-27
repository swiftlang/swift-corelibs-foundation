// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTestExpectation.swift
//

/// Expectations represent specific conditions in asynchronous testing.
open class XCTestExpectation: @unchecked Sendable {

    private static var currentMonotonicallyIncreasingToken: UInt64 = 0
    private static func queue_nextMonotonicallyIncreasingToken() -> UInt64 {
        dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
        currentMonotonicallyIncreasingToken += 1
        return currentMonotonicallyIncreasingToken
    }
    private static func nextMonotonicallyIncreasingToken() -> UInt64 {
        return XCTWaiter.subsystemQueue.sync { queue_nextMonotonicallyIncreasingToken() }
    }

    /*
     Rules for properties
     ====================

     XCTestExpectation has many properties, many of which require synchronization on `XCTWaiter.subsystemQueue`.
     When adding properties, use the following rules for consistency. The naming guidelines aim to allow
     property names to be as short & simple as possible, while maintaining the necessary synchronization.

     - If property is constant (`let`), it is immutable so there is no synchronization concern.
        - No underscore prefix on name
        - No matching `queue_` property
        - If it is only used within this file:
            - `private` access
        - If is is used outside this file but not outside the module:
            - `internal` access
        - If it is used outside the module:
            - `public` or `open` access, depending on desired overridability

     - If property is variable (`var`), it is mutable so access to it must be synchronized.
        - `private` access
        - If it is only used within this file:
            - No underscore prefix on name
            - No matching `queue_` property
        - If is is used outside this file:
            - If access outside this file is always on-queue:
                - No underscore prefix on name
                - Matching internal `queue_` property with `.onQueue` dispatchPreconditions
            - If access outside this file is sometimes off-queue
                - Underscore prefix on name
                - Matching `internal` property with `queue_` prefix and `XCTWaiter.subsystemQueue` dispatchPreconditions
                - Matching `internal` or `public` property without underscore prefix but with `XCTWaiter.subsystemQueue` synchronization
     */

    private var _expectationDescription: String

    internal let creationToken: UInt64
    internal let creationSourceLocation: SourceLocation

    private var isFulfilled = false
    private var fulfillmentToken: UInt64 = 0
    private var _fulfillmentSourceLocation: SourceLocation?

    private var _expectedFulfillmentCount = 1
    private var numberOfFulfillments = 0

    private var _isInverted = false

    private var _assertForOverFulfill = false

    private var _hasBeenWaitedOn = false

    private var _didFulfillHandler: (() -> Void)?

    /// A human-readable string used to describe the expectation in log output and test reports.
    open var expectationDescription: String {
        get {
            return XCTWaiter.subsystemQueue.sync { queue_expectationDescription }
        }
        set {
            XCTWaiter.subsystemQueue.sync { queue_expectationDescription = newValue }
        }
    }

    /// The number of times `fulfill()` must be called on the expectation in order for it
    /// to report complete fulfillment to its waiter. Default is 1.
    /// This value must be greater than 0 and is not meaningful if combined with `isInverted`.
    open var expectedFulfillmentCount: Int {
        get {
            return XCTWaiter.subsystemQueue.sync { queue_expectedFulfillmentCount }
        }
        set {
            precondition(newValue > 0, "API violation - fulfillment count must be greater than 0.")

            XCTWaiter.subsystemQueue.sync {
                precondition(!queue_hasBeenWaitedOn, "API violation - cannot set expectedFulfillmentCount on '\(queue_expectationDescription)' after already waiting on it.")
                queue_expectedFulfillmentCount = newValue
            }
        }
    }

    /// If an expectation is set to be inverted, then fulfilling it will have a similar effect as
    /// failing to fulfill a conventional expectation has, as handled by the waiter and its delegate.
    /// Furthermore, waiters that wait on an inverted expectation will allow the full timeout to elapse
    /// and not report timeout to the delegate if it is not fulfilled.
    open var isInverted: Bool {
        get {
            return XCTWaiter.subsystemQueue.sync { queue_isInverted }
        }
        set {
            XCTWaiter.subsystemQueue.sync {
                precondition(!queue_hasBeenWaitedOn, "API violation - cannot set isInverted on '\(queue_expectationDescription)' after already waiting on it.")
                queue_isInverted = newValue
            }
        }
    }

    /// If set, calls to fulfill() after the expectation has already been fulfilled - exceeding the fulfillment
    /// count - will cause a fatal error and halt process execution. Default is false (disabled).
    ///
    /// - Note: This is the legacy behavior of expectations created through APIs on the ObjC version of XCTestCase
    ///   because that version raises ObjC exceptions (which may be caught) instead of causing a fatal error.
    ///   In this version of XCTest, no expectation ever has this property set to true (enabled) by default, it
    ///   must be opted-in to explicitly.
    open var assertForOverFulfill: Bool {
        get {
            return XCTWaiter.subsystemQueue.sync { _assertForOverFulfill }
        }
        set {
            XCTWaiter.subsystemQueue.sync {
                precondition(!queue_hasBeenWaitedOn, "API violation - cannot set assertForOverFulfill on '\(queue_expectationDescription)' after already waiting on it.")
                _assertForOverFulfill = newValue
            }
        }
    }

    internal var fulfillmentSourceLocation: SourceLocation? {
        return XCTWaiter.subsystemQueue.sync { _fulfillmentSourceLocation }
    }

    internal var hasBeenWaitedOn: Bool {
        return XCTWaiter.subsystemQueue.sync { queue_hasBeenWaitedOn }
    }

    internal var queue_expectationDescription: String {
        get {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            return _expectationDescription
        }
        set {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            _expectationDescription = newValue
        }
    }
    internal var queue_isFulfilled: Bool {
        get {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            return isFulfilled
        }
        set {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            isFulfilled = newValue
        }
    }
    internal var queue_fulfillmentToken: UInt64 {
        get {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            return fulfillmentToken
        }
        set {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            fulfillmentToken = newValue
        }
    }
    internal var queue_expectedFulfillmentCount: Int {
        get {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            return _expectedFulfillmentCount
        }
        set {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            _expectedFulfillmentCount = newValue
        }
    }
    internal var queue_isInverted: Bool {
        get {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            return _isInverted
        }
        set {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            _isInverted = newValue
        }
    }
    internal var queue_hasBeenWaitedOn: Bool {
        get {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            return _hasBeenWaitedOn
        }
        set {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            _hasBeenWaitedOn = newValue

            if _hasBeenWaitedOn {
                didBeginWaiting()
            }
        }
    }
    internal var queue_didFulfillHandler: (() -> Void)? {
        get {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            return _didFulfillHandler
        }
        set {
            dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))
            _didFulfillHandler = newValue
        }
    }

    /// Initializes a new expectation with a description of the condition it is checking.
    ///
    /// - Parameter description: A human-readable string used to describe the condition the expectation is checking.
    public init(description: String = "no description provided", file: StaticString = #file, line: Int = #line) {
        _expectationDescription = description
        creationToken = XCTestExpectation.nextMonotonicallyIncreasingToken()
        creationSourceLocation = SourceLocation(file: file, line: line)
    }

    /// Marks an expectation as having been met. It's an error to call this
    /// method on an expectation that has already been fulfilled, or when the
    /// test case that vended the expectation has already completed.
    ///
    /// - Parameter file: The file name to use in the error message if
    ///   expectations are not met before the given timeout. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   expectations are not met before the given timeout. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    ///
    /// - Note: Whereas Objective-C XCTest determines the file and line
    ///   number the expectation was fulfilled using symbolication, this
    ///   implementation opts to take `file` and `line` as parameters instead.
    ///   As a result, the interface to these methods are not exactly identical
    ///   between these environments. To ensure compatibility of tests between
    ///   swift-corelibs-xctest and Apple XCTest, it is not recommended to pass
    ///   explicit values for `file` and `line`.
    open func fulfill(_ file: StaticString = #file, line: Int = #line) {
        let sourceLocation = SourceLocation(file: file, line: line)

        let didFulfillHandler: (() -> Void)? = XCTWaiter.subsystemQueue.sync {
            // FIXME: Objective-C XCTest emits failures when expectations are
            //        fulfilled after the test cases that generated those
            //        expectations have completed. Similarly, this should cause an
            //        error as well.

            if queue_isFulfilled, _assertForOverFulfill, let testCase = XCTCurrentTestCase {
                testCase.recordFailure(
                    description: "API violation - multiple calls made to XCTestExpectation.fulfill() for \(queue_expectationDescription).",
                    at: sourceLocation,
                    expected: false)

                return nil
            }

            if queue_fulfill(sourceLocation: sourceLocation) {
                return queue_didFulfillHandler
            } else {
                return nil
            }
        }

        didFulfillHandler?()
    }

    private func queue_fulfill(sourceLocation: SourceLocation) -> Bool {
        dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))

        numberOfFulfillments += 1

        if numberOfFulfillments == queue_expectedFulfillmentCount {
            queue_isFulfilled = true
            _fulfillmentSourceLocation = sourceLocation
            queue_fulfillmentToken = XCTestExpectation.queue_nextMonotonicallyIncreasingToken()
            return true
        } else {
            return false
        }
    }

    internal func didBeginWaiting() {
        // Override point for subclasses
    }

    internal func cleanUp() {
        // Override point for subclasses
    }

}

extension XCTestExpectation: Equatable {
    public static func == (lhs: XCTestExpectation, rhs: XCTestExpectation) -> Bool {
        return lhs === rhs
    }
}

extension XCTestExpectation: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

extension XCTestExpectation: CustomStringConvertible {
    public var description: String {
        return expectationDescription
    }
}
