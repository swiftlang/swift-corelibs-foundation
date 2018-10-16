// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNotificationQueue : XCTestCase {
    static var allTests : [(String, (TestNotificationQueue) -> () throws -> Void)] {
        return [
/*
FIXME SR-4280 timeouts in TestNSNotificationQueue tests

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
*/
        ]
    }

    func test_defaultQueue() {
        let defaultQueue1 = NotificationQueue.default
        let defaultQueue2 = NotificationQueue.default
        XCTAssertEqual(defaultQueue1, defaultQueue2)

        executeInBackgroundThread() {
            let defaultQueueForBackgroundThread = NotificationQueue.default
            XCTAssertEqual(defaultQueueForBackgroundThread, NotificationQueue.default)
            XCTAssertNotEqual(defaultQueueForBackgroundThread, defaultQueue1)
        }
    }

    func test_postNowToDefaultQueueWithoutCoalescing() {
        let notificationName = Notification.Name(rawValue: "test_postNowWithoutCoalescing")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let obs = NotificationCenter.default.addObserver(forName: notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NotificationQueue.default
        queue.enqueue(notification, postingStyle: .now)
        XCTAssertEqual(numberOfCalls, 1)
        NotificationCenter.default.removeObserver(obs)
    }

    func test_postNowToDefaultQueueWithCoalescing() {
        let notificationName = Notification.Name(rawValue: "test_postNowToDefaultQueueWithCoalescingOnName")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let obs = NotificationCenter.default.addObserver(forName: notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NotificationQueue.default
        queue.enqueue(notification, postingStyle: .now)
        queue.enqueue(notification, postingStyle: .now)
        queue.enqueue(notification, postingStyle: .now)
        // Coalescing doesn't work for the NSPostingStyle.PostNow. That is why we expect 3 calls here
        XCTAssertEqual(numberOfCalls, 3)
        NotificationCenter.default.removeObserver(obs)
    }

    func test_postNowToCustomQueue() {
        let notificationName = Notification.Name(rawValue: "test_postNowToCustomQueue")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let notificationCenter = NotificationCenter()
        let obs = notificationCenter.addObserver(forName: notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let notificationQueue = NotificationQueue(notificationCenter: notificationCenter)
        notificationQueue.enqueue(notification, postingStyle: .now)
        XCTAssertEqual(numberOfCalls, 1)
        NotificationCenter.default.removeObserver(obs)
    }

    func test_postNowForDefaultRunLoopMode() {
        let notificationName = Notification.Name(rawValue: "test_postNowToDefaultQueueWithCoalescingOnName")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let obs = NotificationCenter.default.addObserver(forName: notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NotificationQueue.default

        let runLoop = RunLoop.current
        let endDate = Date(timeInterval: TimeInterval(0.05), since: Date())

        let dummyTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { _ in
            guard let runLoopMode = runLoop.currentMode else {
                return
            }

            // post 2 notifications for the RunLoopMode.defaultRunLoopMode mode
            queue.enqueue(notification, postingStyle: .now, coalesceMask: [], forModes: [runLoopMode])
            queue.enqueue(notification, postingStyle: .now)
            // here we post notification for the RunLoopMode.commonModes. It shouldn't have any affect, because the timer is scheduled in RunLoopMode.defaultRunLoopMode.
            // The notification queue will only post the notification to its notification center if the run loop is in one of the modes provided in the array.
            queue.enqueue(notification, postingStyle: .now, coalesceMask: [], forModes: [.commonModes])
        }
        runLoop.add(dummyTimer, forMode: .defaultRunLoopMode)
        let _ = runLoop.run(mode: .defaultRunLoopMode, before: endDate)
        XCTAssertEqual(numberOfCalls, 2)
        NotificationCenter.default.removeObserver(obs)
    }

    func test_postAsapToDefaultQueue() {
        let notificationName = Notification.Name(rawValue: "test_postAsapToDefaultQueue")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0
        let obs = NotificationCenter.default.addObserver(forName: notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NotificationQueue.default
        queue.enqueue(notification, postingStyle: .asap)

        scheduleTimer(withInterval: 0.001) // run timer trigger the notifications
        XCTAssertEqual(numberOfCalls, 1)
        NotificationCenter.default.removeObserver(obs)
    }

    func test_postAsapToDefaultQueueWithCoalescingOnNameAndSender() {
        // Check coalescing on name and object
        let notificationName = Notification.Name(rawValue: "test_postAsapToDefaultQueueWithCoalescingOnNameAndSender")
        let notification = Notification(name: notificationName, object: NSObject())
        var numberOfCalls = 0
        let obs = NotificationCenter.default.addObserver(forName: notificationName, object: notification.object, queue: nil) { notification in
            numberOfCalls += 1
        }
        let queue = NotificationQueue.default
        queue.enqueue(notification, postingStyle: .asap)
        queue.enqueue(notification, postingStyle: .asap)
        queue.enqueue(notification, postingStyle: .asap)

        scheduleTimer(withInterval: 0.001)
        XCTAssertEqual(numberOfCalls, 1)
        NotificationCenter.default.removeObserver(obs)
    }

    func test_postAsapToDefaultQueueWithCoalescingOnNameOrSender() {
        // Check coalescing on name or sender
        let notificationName = Notification.Name(rawValue: "test_postAsapToDefaultQueueWithCoalescingOnNameOrSender")
        let notification1 = Notification(name: notificationName, object: NSObject())
        var numberOfNameCoalescingCalls = 0
        let obs1 = NotificationCenter.default.addObserver(forName: notificationName, object: notification1.object, queue: nil) { notification in
            numberOfNameCoalescingCalls += 1
        }
        let notification2 = Notification(name: notificationName, object: NSObject())
        var numberOfObjectCoalescingCalls = 0
        let obs2 = NotificationCenter.default.addObserver(forName: notificationName, object: notification2.object, queue: nil) { notification in
            numberOfObjectCoalescingCalls += 1
        }

        let queue = NotificationQueue.default
        // #1
        queue.enqueue(notification1, postingStyle: .asap,  coalesceMask: .onName, forModes: nil)
        // #2
        queue.enqueue(notification2, postingStyle: .asap,  coalesceMask: .onSender, forModes: nil)
        // #3, coalesce with 1 & 2
        queue.enqueue(notification1, postingStyle: .asap,  coalesceMask: .onName, forModes: nil)
        // #4, coalesce with #3
        queue.enqueue(notification2, postingStyle: .asap,  coalesceMask: .onName, forModes: nil)
        // #5
        queue.enqueue(notification1, postingStyle: .asap,  coalesceMask: .onSender, forModes: nil)
        scheduleTimer(withInterval: 0.001)
        // check that we received notifications #4 and #5
        XCTAssertEqual(numberOfNameCoalescingCalls, 1)
        XCTAssertEqual(numberOfObjectCoalescingCalls, 1)
        NotificationCenter.default.removeObserver(obs1)
        NotificationCenter.default.removeObserver(obs2)
    }


    func test_postIdleToDefaultQueue() {
        let notificationName = Notification.Name(rawValue: "test_postIdleToDefaultQueue")
        let dummyObject = NSObject()
        let notification = Notification(name: notificationName, object: dummyObject)
        var numberOfCalls = 0

        let obs = NotificationCenter.default.addObserver(forName: notificationName, object: dummyObject, queue: nil) { notification in
            numberOfCalls += 1
        }
        NotificationQueue.default.enqueue(notification, postingStyle: .whenIdle)
        // add a timer to wakeup the runloop, process the timer and call the observer awaiting for any input sources/timers
        scheduleTimer(withInterval: 0.001)
        XCTAssertEqual(numberOfCalls, 1)
        NotificationCenter.default.removeObserver(obs)
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
        RunLoop.current.add(dummyTimer, forMode: .defaultRunLoopMode)
        waitForExpectations(timeout: 0.1)
    }

    private func executeInBackgroundThread(_ operation: @escaping () -> Void) {
        let e = expectation(description: "Background Execution")
        let bgThread = Thread() {
            operation()
            e.fulfill()
        }
        bgThread.start()

        waitForExpectations(timeout: 0.2)
    }
}
