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
    static var allTests : [(String, (TestNSNotificationQueue) -> () throws -> Void)] {
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
        let defaultQueue1 = NotificationQueue.defaultQueue()
        XCTAssertNotNil(defaultQueue1)
        let defaultQueue2 = NotificationQueue.defaultQueue()
        XCTAssertEqual(defaultQueue1, defaultQueue2)

        executeInBackgroundThread() {
            let defaultQueueForBackgroundThread = NotificationQueue.defaultQueue()
            XCTAssertNotNil(defaultQueueForBackgroundThread)
            XCTAssertEqual(defaultQueueForBackgroundThread, NotificationQueue.defaultQueue())
            XCTAssertNotEqual(defaultQueueForBackgroundThread, defaultQueue1)
        }
    }

    func test_postNowToDefaultQueueWithoutCoalescing() {
        let notificationName = Notification.Name(rawValue: "test_postNowWithoutCoalescing")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let obs = NotificationCenter.defaultCenter().addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NotificationQueue.defaultQueue()
        queue.enqueueNotification(notification, postingStyle: .postNow)
        XCTAssertEqual(numberOfCalls, 1)
        NotificationCenter.defaultCenter().removeObserver(obs)
    }

    func test_postNowToDefaultQueueWithCoalescing() {
        let notificationName = Notification.Name(rawValue: "test_postNowToDefaultQueueWithCoalescingOnName")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let obs = NotificationCenter.defaultCenter().addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NotificationQueue.defaultQueue()
        queue.enqueueNotification(notification, postingStyle: .postNow)
        queue.enqueueNotification(notification, postingStyle: .postNow)
        queue.enqueueNotification(notification, postingStyle: .postNow)
        // Coalescing doesn't work for the NSPostingStyle.PostNow. That is why we expect 3 calls here
        XCTAssertEqual(numberOfCalls, 3)
        NotificationCenter.defaultCenter().removeObserver(obs)
    }

    func test_postNowToCustomQueue() {
        let notificationName = Notification.Name(rawValue: "test_postNowToCustomQueue")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let notificationCenter = NotificationCenter()
        let obs = notificationCenter.addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let notificationQueue = NotificationQueue(notificationCenter: notificationCenter)
        notificationQueue.enqueueNotification(notification, postingStyle: .postNow)
        XCTAssertEqual(numberOfCalls, 1)
        NotificationCenter.defaultCenter().removeObserver(obs)
    }

    func test_postNowForDefaultRunLoopMode() {
        let notificationName = Notification.Name(rawValue: "test_postNowToDefaultQueueWithCoalescingOnName")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let obs = NotificationCenter.defaultCenter().addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NotificationQueue.defaultQueue()

        let runLoop = RunLoop.current()
        let endDate = Date(timeInterval: TimeInterval(0.05), since: Date())

        let dummyTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { _ in
            guard let runLoopMode = runLoop.currentMode else {
                return
            }

            // post 2 notifications for the NSDefaultRunLoopMode mode
            queue.enqueueNotification(notification, postingStyle: .postNow, coalesceMask: [], forModes: [runLoopMode])
            queue.enqueueNotification(notification, postingStyle: .postNow)
            // here we post notification for the NSRunLoopCommonModes. It shouldn't have any affect, because the timer is scheduled in NSDefaultRunLoopMode.
            // The notification queue will only post the notification to its notification center if the run loop is in one of the modes provided in the array.
            queue.enqueueNotification(notification, postingStyle: .postNow, coalesceMask: [], forModes: [.commonModes])
        }
        runLoop.add(dummyTimer, forMode: .defaultRunLoopMode)
        let _ = runLoop.run(mode: .defaultRunLoopMode, before: endDate)
        XCTAssertEqual(numberOfCalls, 2)
        NotificationCenter.defaultCenter().removeObserver(obs)
    }

    func test_postAsapToDefaultQueue() {
        let notificationName = Notification.Name(rawValue: "test_postAsapToDefaultQueue")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let obs = NotificationCenter.defaultCenter().addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NotificationQueue.defaultQueue()
        queue.enqueueNotification(notification, postingStyle: .postASAP)

        scheduleTimer(withInterval: 0.001) // run timer trigger the notifications
        XCTAssertEqual(numberOfCalls, 1)
        NotificationCenter.defaultCenter().removeObserver(obs)
    }

    func test_postAsapToDefaultQueueWithCoalescingOnNameAndSender() {
        // Check coalescing on name and object
        let notificationName = Notification.Name(rawValue: "test_postAsapToDefaultQueueWithCoalescingOnNameAndSender")
        let notification = Notification(name: notificationName, object: NSObject())
        var numberOfCalls = 0
        let obs = NotificationCenter.defaultCenter().addObserverForName(notificationName, object: notification.object, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NotificationQueue.defaultQueue()
        queue.enqueueNotification(notification, postingStyle: .postASAP)
        queue.enqueueNotification(notification, postingStyle: .postASAP)
        queue.enqueueNotification(notification, postingStyle: .postASAP)

        scheduleTimer(withInterval: 0.001)
        XCTAssertEqual(numberOfCalls, 1)
        NotificationCenter.defaultCenter().removeObserver(obs)
    }

    func test_postAsapToDefaultQueueWithCoalescingOnNameOrSender() {
        // Check coalescing on name or sender
        let notificationName = Notification.Name(rawValue: "test_postAsapToDefaultQueueWithCoalescingOnNameOrSender")
        let notification1 = Notification(name: notificationName, object: NSObject())
        var numberOfNameCoalescingCalls = 0
        let obs1 = NotificationCenter.defaultCenter().addObserverForName(notificationName, object: notification1.object, queue: nil) { notification in
            numberOfNameCoalescingCalls += 1
        }
        let notification2 = Notification(name: notificationName, object: NSObject())
        var numberOfObjectCoalescingCalls = 0
        let obs2 = NotificationCenter.defaultCenter().addObserverForName(notificationName, object: notification2.object, queue: nil) { notification in
            numberOfObjectCoalescingCalls += 1
        }

        let queue = NotificationQueue.defaultQueue()
        // #1
        queue.enqueueNotification(notification1, postingStyle: .postASAP,  coalesceMask: .CoalescingOnName, forModes: nil)
        // #2
        queue.enqueueNotification(notification2, postingStyle: .postASAP,  coalesceMask: .CoalescingOnSender, forModes: nil)
        // #3, coalesce with 1 & 2
        queue.enqueueNotification(notification1, postingStyle: .postASAP,  coalesceMask: .CoalescingOnName, forModes: nil)
        // #4, coalesce with #3
        queue.enqueueNotification(notification2, postingStyle: .postASAP,  coalesceMask: .CoalescingOnName, forModes: nil)
        // #5
        queue.enqueueNotification(notification1, postingStyle: .postASAP,  coalesceMask: .CoalescingOnSender, forModes: nil)
        scheduleTimer(withInterval: 0.001)
        // check that we received notifications #4 and #5
        XCTAssertEqual(numberOfNameCoalescingCalls, 1)
        XCTAssertEqual(numberOfObjectCoalescingCalls, 1)
        NotificationCenter.defaultCenter().removeObserver(obs1)
        NotificationCenter.defaultCenter().removeObserver(obs2)
    }


    func test_postIdleToDefaultQueue() {
        let notificationName = Notification.Name(rawValue: "test_postIdleToDefaultQueue")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0

        let obs = NotificationCenter.defaultCenter().addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        NotificationQueue.defaultQueue().enqueueNotification(notification, postingStyle: .postWhenIdle)
        // add a timer to wakeup the runloop, process the timer and call the observer awaiting for any input sources/timers
        scheduleTimer(withInterval: 0.001)
        XCTAssertEqual(numberOfCalls, 1)
        NotificationCenter.defaultCenter().removeObserver(obs)
    }

    func test_notificationQueueLifecycle() {
        // check that notificationqueue is associated with current thread. when the thread is destroyed, the queue should be deallocated as well
        weak var notificationQueue: NotificationQueue?

        self.executeInBackgroundThread() {
            notificationQueue = NotificationQueue(notificationCenter: NotificationCenter())
            XCTAssertNotNil(notificationQueue)
        }
        
        XCTAssertNil(notificationQueue)
    }

    // MARK: Private

    private func scheduleTimer(withInterval interval: TimeInterval) {
        let e = expectation(description: "Timer")
        let dummyTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            e.fulfill()
        }
        RunLoop.current().add(dummyTimer, forMode: .defaultRunLoopMode)
        waitForExpectations(timeout: 0.1)
    }

    private func executeInBackgroundThread(_ operation: () -> Void) {
        let e = expectation(description: "Background Execution")
        let bgThread = Thread() {
            operation()
            e.fulfill()
        }
        bgThread.start()

        waitForExpectations(timeout: 0.2)
    }
}
