// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTNSNotificationExpectation.swift
//

/// Expectation subclass for waiting on a condition defined by a Foundation Notification instance.
open class XCTNSNotificationExpectation: XCTestExpectation {

    /// A closure to be invoked when a notification specified by the expectation is observed.
    ///
    /// - Parameter notification: The notification object which was observed.
    /// - Returns: `true` if the expectation should be fulfilled, `false` if it should not.
    ///
    /// - SeeAlso: `XCTNSNotificationExpectation.handler`
    public typealias Handler = @Sendable (Notification) -> Bool

    private let queue = DispatchQueue(label: "org.swift.XCTest.XCTNSNotificationExpectation")

    /// The name of the notification being waited on.
    open private(set) var notificationName: Notification.Name

    /// The specific object that will post the notification, if any.
    /// If nil, any object may post the notification. Default is nil.
    open private(set) var observedObject: Any?

    /// The specific notification center that the notification will be posted to.
    open private(set) var notificationCenter: NotificationCenter

    private var observer: AnyObject?

    private var _handler: Handler?

    /// Allows the caller to install a special handler to do custom evaluation of received notifications
    /// matching the specified object and notification center.
    ///
    /// - SeeAlso: `XCTNSNotificationExpectation.Handler`
    open var handler: Handler? {
        get {
            return queue.sync { _handler }
        }
        set {
            dispatchPrecondition(condition: .notOnQueue(queue))
            queue.async { self._handler = newValue }
        }
    }

    /// Initializes an expectation that waits for a Foundation Notification to be posted by an optional `object` to a specific NotificationCenter.
    ///
    /// - Parameter notificationName: The name of the notification to wait on.
    /// - Parameter object: The object that will post the notification, if any. Default is nil.
    /// - Parameter notificationCenter: The specific notification center that the notification will be posted to.
    /// - Parameter file: The file name to use in the error message if
    ///   expectations are not met before the wait timeout. Default is the file
    ///   containing the call to this method. It is rare to provide this
    ///   parameter when calling this method.
    /// - Parameter line: The line number to use in the error message if the
    ///   expectations are not met before the wait timeout. Default is the line
    ///   number of the call to this method in the calling file. It is rare to
    ///   provide this parameter when calling this method.
    public init(name notificationName: Notification.Name, object: Any? = nil, notificationCenter: NotificationCenter = .default, file: StaticString = #file, line: Int = #line) {
        self.notificationName = notificationName
        self.observedObject = object
        self.notificationCenter = notificationCenter
        let description = "Expect notification '\(notificationName.rawValue)' from " + (object.map { "\($0)" } ?? "any object")

        super.init(description: description, file: file, line: line)

        beginObserving(with: notificationCenter)
    }

    deinit {
        assert(observer == nil, "observer should be nil, indicates failure to call cleanUp() internally")
    }

    private func beginObserving(with notificationCenter: NotificationCenter) {
        observer = notificationCenter.addObserver(forName: notificationName, object: observedObject, queue: nil) { [weak self] notification in
            guard let strongSelf = self else { return }

            let shouldFulfill: Bool

            // If the handler is invoked, the test will only pass if true is returned.
            if let handler = strongSelf.handler {
                shouldFulfill = handler(notification)
            } else {
                shouldFulfill = true
            }

            if shouldFulfill {
                strongSelf.fulfill()
            }
        }
    }

    override func cleanUp() {
        queue.sync {
            if let observer = observer {
                notificationCenter.removeObserver(observer)
                self.observer = nil
            }
        }
    }

}

/// A closure to be invoked when a notification specified by the expectation is observed.
///
/// - SeeAlso: `XCTNSNotificationExpectation.handler`
@available(*, deprecated, renamed: "XCTNSNotificationExpectation.Handler")
public typealias XCNotificationExpectationHandler = XCTNSNotificationExpectation.Handler
