// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif


class TestNSNotificationQueue : XCTestCase {
    static var allTests : [(String, TestNSNotificationQueue -> () throws -> Void)] {
        return [
            ("test_defaultQueue", test_defaultQueue),
            ("test_postNowToDefaultQueueWithoutCoalescing", test_postNowToDefaultQueueWithoutCoalescing),
            ("test_postNowToDefaultQueueWithCoalescing", test_postNowToDefaultQueueWithCoalescing),
            ("test_postNowToCustomQueue", test_postNowToCustomQueue),
            ("test_postNowForDefaultRunLoopMode", test_postNowForDefaultRunLoopMode),
            // ("test_notificationQueueLifecycle", test_notificationQueueLifecycle),
            ("test_postAsapToDefaultQueue", test_postAsapToDefaultQueue),
            ("test_postAsapToDefaultQueueWithCoalescingOnNameAndSender", test_postAsapToDefaultQueueWithCoalescingOnNameAndSender),
            ("test_postAsapToDefaultQueueWithCoalescingOnNameOrSender", test_postAsapToDefaultQueueWithCoalescingOnNameOrSender),
            ("test_postIdleToDefaultQueue", test_postIdleToDefaultQueue),
        ]
    }

    func test_defaultQueue() {
        let defaultQueue1 = NSNotificationQueue.defaultQueue()
        XCTAssertNotNil(defaultQueue1)
        let defaultQueue2 = NSNotificationQueue.defaultQueue()
        XCTAssertEqual(defaultQueue1, defaultQueue2)

        executeInBackgroundThread() {
            let defaultQueueForBackgroundThread = NSNotificationQueue.defaultQueue()
            XCTAssertNotNil(defaultQueueForBackgroundThread)
            XCTAssertEqual(defaultQueueForBackgroundThread, NSNotificationQueue.defaultQueue())
            XCTAssertNotEqual(defaultQueueForBackgroundThread, defaultQueue1)
        }
    }

    func test_postNowToDefaultQueueWithoutCoalescing() {
        let notificationName = "test_postNowWithoutCoalescing"
        let dummyObject = NSObject()
        let notification = NSNotification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        NSNotificationCenter.defaultCenter().addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NSNotificationQueue.defaultQueue()
        queue.enqueueNotification(notification, postingStyle: .PostNow)
        XCTAssertEqual(numberOfCalls, 1)
    }

    func test_postNowToDefaultQueueWithCoalescing() {
        let notificationName = "test_postNowToDefaultQueueWithCoalescingOnName"
        let dummyObject = NSObject()
        let notification = NSNotification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        NSNotificationCenter.defaultCenter().addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NSNotificationQueue.defaultQueue()
        queue.enqueueNotification(notification, postingStyle: .PostNow)
        queue.enqueueNotification(notification, postingStyle: .PostNow)
        queue.enqueueNotification(notification, postingStyle: .PostNow)
        // Coalescing doesn't work for the NSPostingStyle.PostNow. That is why we expect 3 calls here
        XCTAssertEqual(numberOfCalls, 3)
    }

    func test_postNowToCustomQueue() {
        let notificationName = "test_postNowToCustomQueue"
        let dummyObject = NSObject()
        let notification = NSNotification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let notificationCenter = NSNotificationCenter()
        notificationCenter.addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let notificationQueue = NSNotificationQueue(notificationCenter: notificationCenter)
        notificationQueue.enqueueNotification(notification, postingStyle: .PostNow)
        XCTAssertEqual(numberOfCalls, 1)
    }

    func test_postNowForDefaultRunLoopMode() {
        let notificationName = "test_postNowToDefaultQueueWithCoalescingOnName"
        let dummyObject = NSObject()
        let notification = NSNotification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        NSNotificationCenter.defaultCenter().addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NSNotificationQueue.defaultQueue()

        let runLoop = NSRunLoop.currentRunLoop()
        let endDate = NSDate(timeInterval: NSTimeInterval(0.05), sinceDate: NSDate())

        let dummyTimer = NSTimer.scheduledTimer(0.01, repeats: false) { _ in
            guard let runLoopMode = runLoop.currentMode else {
                return
            }

            // post 2 notifications for the NSDefaultRunLoopMode mode
            queue.enqueueNotification(notification, postingStyle: .PostNow, coalesceMask: [], forModes: [runLoopMode])
            queue.enqueueNotification(notification, postingStyle: .PostNow)
            // here we post notification for the NSRunLoopCommonModes. It shouldn't have any affect, because the timer is scheduled in NSDefaultRunLoopMode.
            // The notification queue will only post the notification to its notification center if the run loop is in one of the modes provided in the array.
            queue.enqueueNotification(notification, postingStyle: .PostNow, coalesceMask: [], forModes: [NSRunLoopCommonModes])
        }
        runLoop.addTimer(dummyTimer, forMode: NSDefaultRunLoopMode)
        runLoop.runMode(NSDefaultRunLoopMode, beforeDate: endDate)
        XCTAssertEqual(numberOfCalls, 2)
    }

    func test_postAsapToDefaultQueue() {
        let notificationName = "test_postAsapToDefaultQueue"
        let dummyObject = NSObject()
        let notification = NSNotification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        NSNotificationCenter.defaultCenter().addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NSNotificationQueue.defaultQueue()
        queue.enqueueNotification(notification, postingStyle: .PostASAP)

        scheduleTimer(withInterval: 0.001) // run timer trigger the notifications
        XCTAssertEqual(numberOfCalls, 1)
    }

    func test_postAsapToDefaultQueueWithCoalescingOnNameAndSender() {
        // Check coalescing on name and object
        let notificationName = "test_postAsapToDefaultQueueWithCoalescingOnNameAndSender"
        let notification = NSNotification(name: notificationName, object: NSObject())
        var numberOfCalls = 0
        NSNotificationCenter.defaultCenter().addObserverForName(notificationName, object: notification.object, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NSNotificationQueue.defaultQueue()
        queue.enqueueNotification(notification, postingStyle: .PostASAP)
        queue.enqueueNotification(notification, postingStyle: .PostASAP)
        queue.enqueueNotification(notification, postingStyle: .PostASAP)

        scheduleTimer(withInterval: 0.001)
        XCTAssertEqual(numberOfCalls, 1)
    }

    func test_postAsapToDefaultQueueWithCoalescingOnNameOrSender() {
        // Check coalescing on name or sender
        let notificationName = "test_postAsapToDefaultQueueWithCoalescingOnNameOrSender"
        let notification1 = NSNotification(name: notificationName, object: NSObject())
        var numberOfNameCoalescingCalls = 0
        NSNotificationCenter.defaultCenter().addObserverForName(notificationName, object: notification1.object, queue: nil) { notification in
            numberOfNameCoalescingCalls += 1
        }
        let notification2 = NSNotification(name: notificationName, object: NSObject())
        var numberOfObjectCoalescingCalls = 0
        NSNotificationCenter.defaultCenter().addObserverForName(notificationName, object: notification2.object, queue: nil) { notification in
            numberOfObjectCoalescingCalls += 1
        }

        let queue = NSNotificationQueue.defaultQueue()
        // #1
        queue.enqueueNotification(notification1, postingStyle: .PostASAP,  coalesceMask: .CoalescingOnName, forModes: nil)
        // #2
        queue.enqueueNotification(notification2, postingStyle: .PostASAP,  coalesceMask: .CoalescingOnSender, forModes: nil)
        // #3, coalesce with 1 & 2
        queue.enqueueNotification(notification1, postingStyle: .PostASAP,  coalesceMask: .CoalescingOnName, forModes: nil)
        // #4, coalesce with #3
        queue.enqueueNotification(notification2, postingStyle: .PostASAP,  coalesceMask: .CoalescingOnName, forModes: nil)
        // #5
        queue.enqueueNotification(notification1, postingStyle: .PostASAP,  coalesceMask: .CoalescingOnSender, forModes: nil)
        scheduleTimer(withInterval: 0.001)
        // check that we received notifications #4 and #5
        XCTAssertEqual(numberOfNameCoalescingCalls, 1)
        XCTAssertEqual(numberOfObjectCoalescingCalls, 1)
    }


    func test_postIdleToDefaultQueue() {
        let notificationName = "test_postIdleToDefaultQueue"
        let dummyObject = NSObject()
        let notification = NSNotification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0

        NSNotificationCenter.defaultCenter().addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        NSNotificationQueue.defaultQueue().enqueueNotification(notification, postingStyle: .PostWhenIdle)
        // add a timer to wakeup the runloop, process the timer and call the observer awaiting for any input sources/timers
        scheduleTimer(withInterval: 0.001)
        XCTAssertEqual(numberOfCalls, 1)
    }

    func test_notificationQueueLifecycle() {
        // check that notificationqueue is associated with current thread. when the thread is destroyed, the queue should be deallocated as well
        weak var notificationQueue: NSNotificationQueue?

        self.executeInBackgroundThread() {
            notificationQueue = NSNotificationQueue(notificationCenter: NSNotificationCenter())
            XCTAssertNotNil(notificationQueue)
        }
        
        XCTAssertNil(notificationQueue)
    }

    // MARK: Private

    private func scheduleTimer(withInterval interval: NSTimeInterval) {
        let e = expectation(withDescription: "Timer")
        let dummyTimer = NSTimer.scheduledTimer(interval, repeats: false) { _ in
            e.fulfill()
        }
        NSRunLoop.currentRunLoop().addTimer(dummyTimer, forMode: NSDefaultRunLoopMode)
        waitForExpectations(withTimeout: 0.1)
    }

    private func executeInBackgroundThread(_ operation: () -> Void) {
        let e = expectation(withDescription: "Background Execution")
        let bgThread = NSThread() {
            operation()
            e.fulfill()
        }
        bgThread.start()

        waitForExpectations(withTimeout: 0.2)
    }
}
