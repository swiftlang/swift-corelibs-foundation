// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  WaiterManager.swift
//

internal protocol ManageableWaiter: AnyObject, Equatable {
    var isFinished: Bool { get }

    // Invoked on `XCTWaiter.subsystemQueue`
    func queue_handleWatchdogTimeout()
    func queue_interrupt(for interruptingWaiter: Self)
}

private protocol ManageableWaiterWatchdog {
    func cancel()
}
extension DispatchWorkItem: ManageableWaiterWatchdog {}

/// This class manages the XCTWaiter instances which are currently waiting on a particular thread.
/// It facilitates "nested" waiters, allowing an outer waiter to interrupt inner waiters if it times
/// out.
internal final class WaiterManager<WaiterType: ManageableWaiter> : NSObject {

    /// The current thread's waiter manager. This is the only supported way to access an instance of
    /// this class, since each instance is bound to a particular thread and is only concerned with
    /// the XCTWaiters waiting on that thread.
    static var current: WaiterManager {
        let threadKey = "org.swift.XCTest.WaiterManager"

        if let existing = Thread.current.threadDictionary[threadKey] as? WaiterManager {
            return existing
        } else {
            let manager = WaiterManager()
            Thread.current.threadDictionary[threadKey] = manager
            return manager
        }
    }

    private struct ManagedWaiterDetails {
        let waiter: WaiterType
        let watchdog: ManageableWaiterWatchdog?
    }

    private var managedWaiterStack = [ManagedWaiterDetails]()
    private weak var thread = Thread.current
    private let queue = DispatchQueue(label: "org.swift.XCTest.WaiterManager")

    // Use `WaiterManager.current` to access the thread-specific instance
    private override init() {}

    deinit {
        assert(managedWaiterStack.isEmpty, "Waiters still registered when WaiterManager is deallocating.")
    }

    func startManaging(_ waiter: WaiterType, timeout: TimeInterval) {
        guard let thread = thread else { fatalError("\(self) no longer belongs to a thread") }
        precondition(thread === Thread.current, "\(#function) called on wrong thread, must be called on \(thread)")

        var alreadyFinishedOuterWaiter: WaiterType?

        queue.sync {
            // To start managing `waiter`, first see if any existing, outer waiters have already finished,
            // because if one has, then `waiter` will be immediately interrupted before it begins waiting.
            alreadyFinishedOuterWaiter = managedWaiterStack.first(where: { $0.waiter.isFinished })?.waiter

            let watchdog: ManageableWaiterWatchdog?
            if alreadyFinishedOuterWaiter == nil {
                // If there is no already-finished outer waiter, install a watchdog for `waiter`, and store it
                // alongside `waiter` so that it may be canceled if `waiter` finishes waiting within its allotted timeout.
                watchdog = WaiterManager.installWatchdog(for: waiter, timeout: timeout)
            } else {
                // If there is an already-finished outer waiter, no watchdog is needed for `waiter` because it will
                // be interrupted before it begins waiting.
                watchdog = nil
            }

            // Add the waiter even if it's going to immediately be interrupted below to simplify the stack management
            let details = ManagedWaiterDetails(waiter: waiter, watchdog: watchdog)
            managedWaiterStack.append(details)
        }

        if let alreadyFinishedOuterWaiter = alreadyFinishedOuterWaiter {
            XCTWaiter.subsystemQueue.async {
                waiter.queue_interrupt(for: alreadyFinishedOuterWaiter)
            }
        }
    }

    func stopManaging(_ waiter: WaiterType) {
        guard let thread = thread else { fatalError("\(self) no longer belongs to a thread") }
        precondition(thread === Thread.current, "\(#function) called on wrong thread, must be called on \(thread)")

        queue.sync {
            precondition(!managedWaiterStack.isEmpty, "Waiter stack was empty when requesting to stop managing: \(waiter)")

            let expectedIndex = managedWaiterStack.index(before: managedWaiterStack.endIndex)
            let waiterDetails = managedWaiterStack[expectedIndex]
            guard waiter == waiterDetails.waiter else {
                fatalError("Top waiter on stack \(waiterDetails.waiter) is not equal to waiter to stop managing: \(waiter)")
            }

            waiterDetails.watchdog?.cancel()
            managedWaiterStack.remove(at: expectedIndex)
        }
    }

    private static func installWatchdog(for waiter: WaiterType, timeout: TimeInterval) -> ManageableWaiterWatchdog {
        // Use DispatchWorkItem instead of a basic closure since it can be canceled.
        let watchdog = DispatchWorkItem { [weak waiter] in
            waiter?.queue_handleWatchdogTimeout()
        }

        let outerTimeoutSlop = TimeInterval(0.25)
        let deadline = DispatchTime.now() + timeout + outerTimeoutSlop
        XCTWaiter.subsystemQueue.asyncAfter(deadline: deadline, execute: watchdog)

        return watchdog
    }

    func queue_handleWatchdogTimeout(of waiter: WaiterType) {
        dispatchPrecondition(condition: .onQueue(XCTWaiter.subsystemQueue))

        var waitersToInterrupt = [WaiterType]()

        queue.sync {
            guard let indexOfWaiter = managedWaiterStack.firstIndex(where: { $0.waiter == waiter }) else {
                preconditionFailure("Waiter \(waiter) reported timed out but is not in the waiter stack \(managedWaiterStack)")
            }

            waitersToInterrupt += managedWaiterStack[managedWaiterStack.index(after: indexOfWaiter)...].map { $0.waiter }
        }

        for waiterToInterrupt in waitersToInterrupt.reversed() {
            waiterToInterrupt.queue_interrupt(for: waiter)
        }
    }

}
