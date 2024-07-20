// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTNSPredicateExpectation.swift
//

/// Expectation subclass for waiting on a condition defined by an NSPredicate and an optional object.
open class XCTNSPredicateExpectation: XCTestExpectation {

    /// A closure to be invoked whenever evaluating the predicate against the object returns true.
    ///
    /// - Returns: `true` if the expectation should be fulfilled, `false` if it should not.
    ///
    /// - SeeAlso: `XCTNSPredicateExpectation.handler`
    public typealias Handler = @Sendable () -> Bool

    private let queue = DispatchQueue(label: "org.swift.XCTest.XCTNSPredicateExpectation")

    /// The predicate used by the expectation.
    open private(set) var predicate: NSPredicate

    /// The object against which the predicate is evaluated, if any. Default is nil.
    open private(set) var object: Any?

    private var _handler: Handler?

    /// Handler called when evaluating the predicate against the object returns true. If the handler is not
    /// provided, the first successful evaluation will fulfill the expectation. If the handler provided, the
    /// handler will be queried each time the notification is received to determine whether the expectation
    /// should be fulfilled or not.
    open var handler: Handler? {
        get {
            return queue.sync { _handler }
        }
        set {
            dispatchPrecondition(condition: .notOnQueue(queue))
            queue.async { self._handler = newValue }
        }
    }

    private let runLoop = RunLoop.current
    private var timer: Timer?
    private let evaluationInterval = 0.01

    /// Initializes an expectation that waits for a predicate to evaluate as true with an optionally specified object.
    ///
    /// - Parameter predicate: The predicate to evaluate.
    /// - Parameter object: An optional object to evaluate `predicate` with. Default is nil.
    /// - Parameter file: The file name to use in the error message if
    ///   expectations are not met before the wait timeout. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   expectations are not met before the wait timeout. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    public init(predicate: NSPredicate, object: Any? = nil, file: StaticString = #file, line: Int = #line) {
        self.predicate = predicate
        self.object = object
        let description = "Expect predicate `\(predicate)`" + (object.map { " for object \($0)" } ?? "")

        super.init(description: description, file: file, line: line)
    }

    deinit {
        assert(timer == nil, "timer should be nil, indicates failure to call cleanUp() internally")
    }

    override func didBeginWaiting() {
        runLoop.perform {
            if self.shouldFulfill() {
                self.fulfill()
            } else {
                self.startPolling()
            }
        }
    }

    private func startPolling() {
        let timer = Timer(timeInterval: evaluationInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            if self.shouldFulfill() {
                self.fulfill()
                timer.invalidate()
            }
        }

        runLoop.add(timer, forMode: .default)
        queue.async {
            self.timer = timer
        }
    }

    private func shouldFulfill() -> Bool {
        if predicate.evaluate(with: object) {
            if let handler = handler {
                if handler() {
                    return true
                }
                // We do not fulfill or invalidate the timer if the handler returns
                // false. The object is still re-evaluated until timeout.
            } else {
                return true
            }
        }

        return false
    }

    override func cleanUp() {
        queue.sync {
            if let timer = timer {
                timer.invalidate()
                self.timer = nil
            }
        }
    }

}

/// A closure to be invoked whenever evaluating the predicate against the object returns true.
///
/// - SeeAlso: `XCTNSPredicateExpectation.handler`
@available(*, deprecated, renamed: "XCTNSPredicateExpectation.Handler")
public typealias XCPredicateExpectationHandler = XCTNSPredicateExpectation.Handler
