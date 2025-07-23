// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

final class NotificationCenterDummyObject : NSObject, Sendable { }

class TestNotificationCenter : XCTestCase {
    func removeObserver(_ observer: NSObjectProtocol, notificationCenter: NotificationCenter) {
        guard let observer = observer as? NSObject else {
            return
        }
        
        notificationCenter.removeObserver(observer)
    }
    
    func test_postNotification() {
        let notificationCenter = NotificationCenter()
        let notificationName = Notification.Name(rawValue: "test_postNotification_name")
        nonisolated(unsafe) var flag = false
        let dummyObject = NotificationCenterDummyObject()
        let observer = notificationCenter.addObserver(forName: notificationName, object: dummyObject, queue: nil) { notification in
            XCTAssertEqual(notificationName, notification.name)
            XCTAssertTrue(dummyObject === notification.object as? NotificationCenterDummyObject)
            
            flag = true
        }
        
        notificationCenter.post(name: notificationName, object: dummyObject)
        XCTAssertTrue(flag)
        
        removeObserver(observer, notificationCenter: notificationCenter)
    }

    func test_postNotificationForObject() {
        let notificationCenter = NotificationCenter()
        let notificationName = Notification.Name(rawValue: "test_postNotificationForObject_name")
        nonisolated(unsafe) var flag = true
        let dummyObject = NotificationCenterDummyObject()
        let dummyObject2 = NotificationCenterDummyObject()
        let observer = notificationCenter.addObserver(forName: notificationName, object: dummyObject, queue: nil) { notification in
            flag = false
        }
        
        notificationCenter.post(name: notificationName, object: dummyObject2)
        XCTAssertTrue(flag)
        
        removeObserver(observer, notificationCenter: notificationCenter)
    }
    
    func test_postMultipleNotifications() {
        let notificationCenter = NotificationCenter()
        let notificationName = Notification.Name(rawValue: "test_postMultipleNotifications_name")
        nonisolated(unsafe) var flag1 = false
        let observer1 = notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
            flag1 = true
        }
        
        nonisolated(unsafe) var flag2 = true
        let observer2 = notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
            flag2 = false
        }
        
        nonisolated(unsafe) var flag3 = false
        let observer3 = notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
            flag3 = true
        }
        
        removeObserver(observer2, notificationCenter: notificationCenter)
        
        notificationCenter.post(name: notificationName, object: nil)
        XCTAssertTrue(flag1)
        XCTAssertTrue(flag2)
        XCTAssertTrue(flag3)
        
        removeObserver(observer1, notificationCenter: notificationCenter)
        removeObserver(observer3, notificationCenter: notificationCenter)
    }

    func test_addObserverForNilName() {
        let notificationCenter = NotificationCenter()
        let notificationName = Notification.Name(rawValue: "test_addObserverForNilName_name")
        let invalidNotificationName = Notification.Name(rawValue: "test_addObserverForNilName_name_invalid")
        nonisolated(unsafe) var flag1 = false
        let observer1 = notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
            flag1 = true
        }
        
        nonisolated(unsafe) var flag2 = true
        let observer2 = notificationCenter.addObserver(forName: invalidNotificationName, object: nil, queue: nil) { _ in
            flag2 = false
        }
        
        nonisolated(unsafe) var flag3 = false
        let observer3 = notificationCenter.addObserver(forName: nil, object: nil, queue: nil) { _ in
            flag3 = true
        }
        
        notificationCenter.post(name: notificationName, object: nil)
        XCTAssertTrue(flag1)
        XCTAssertTrue(flag2)
        XCTAssertTrue(flag3)
        
        removeObserver(observer1, notificationCenter: notificationCenter)
        removeObserver(observer2, notificationCenter: notificationCenter)
        removeObserver(observer3, notificationCenter: notificationCenter)
    }

    func test_removeObserver() {
        let notificationCenter = NotificationCenter()
        let notificationName = Notification.Name(rawValue: "test_removeObserver_name")
        nonisolated(unsafe) var flag = true
        let observer = notificationCenter.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
            flag = false
        }

        removeObserver(observer, notificationCenter: notificationCenter)

        notificationCenter.post(name: notificationName, object: nil)
        XCTAssertTrue(flag)
    }
    
    func test_observeOnPostingQueue() {
        let notificationCenter = NotificationCenter()
        let name = Notification.Name(rawValue: "\(#function)_name")
        let postingQueue = OperationQueue()
        let expectation = self.expectation(description: "Observer was not notified.")
        
        _ = notificationCenter.addObserver(forName: name, object: nil, queue: nil) { _ in
            XCTAssertEqual(OperationQueue.current, postingQueue)
            expectation.fulfill()
        }
        
        postingQueue.addOperation {
            notificationCenter.post(name: name, object: nil)
        }
        
        self.waitForExpectations(timeout: 1)
    }
    
    func test_observeOnSpecificQueuePostFromMainQueue() {
        let name = Notification.Name(rawValue: "\(#function)_name")
        let notificationCenter = NotificationCenter()
        let operationQueue = OperationQueue()
        nonisolated(unsafe) var flag1 = false
        nonisolated(unsafe) var flag2 = false
        
        _ = notificationCenter.addObserver(forName: name, object: nil, queue: operationQueue) { _ in
            XCTAssertEqual(OperationQueue.current, operationQueue)
            flag1 = true
        }
        
        _ = notificationCenter.addObserver(forName: name, object: nil, queue: .main) { _ in
            XCTAssertEqual(OperationQueue.current, .main)
            flag2 = true
        }
        
        notificationCenter.post(name: name, object: nil)
        // All observers should be notified synchronously regardless of the observer queue.
        XCTAssertTrue(flag1)
        XCTAssertTrue(flag2)
    }
    
    func test_observeOnSpecificQueuePostFromObservedQueue() {
        let name = Notification.Name(rawValue: "\(#function)_name")
        let notificationCenter = NotificationCenter()
        let observingQueue = OperationQueue()
        let expectation = self.expectation(description: "Notification posting operation was not executed.")
        
        // Protected by the inherent ordering of notification center posts - which is the point of this test
        nonisolated(unsafe) var flag1 = false
        nonisolated(unsafe) var flag2 = false
        
        _ = notificationCenter.addObserver(forName: name, object: nil, queue: observingQueue) { _ in
            XCTAssertEqual(OperationQueue.current, observingQueue)
            flag1 = true
        }
        
        _ = notificationCenter.addObserver(forName: name, object: nil, queue: .main) { _ in
            XCTAssertEqual(OperationQueue.current, .main)
            flag2 = true
        }
        
        observingQueue.addOperation {
            notificationCenter.post(name: name, object: nil)
            // All observers should be notified synchronously regardless of the observer queue.
            XCTAssertTrue(flag1)
            XCTAssertTrue(flag2)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1)
    }
    
    func test_observeOnSpecificQueuePostFromUnrelatedQueue() {
        let name = Notification.Name(rawValue: "\(#function)_name")
        let notificationCenter = NotificationCenter()
        let operationQueue = OperationQueue()
        let postingQueue = OperationQueue()
        let expectation = self.expectation(description: "Notification posting operation was not executed.")
        
        // Protected by the inherent ordering of notification center posts - which is the point of this test
        nonisolated(unsafe) var flag1 = false
        nonisolated(unsafe) var flag2 = false
        
        _ = notificationCenter.addObserver(forName: name, object: nil, queue: operationQueue) { _ in
            XCTAssertEqual(OperationQueue.current, operationQueue)
            flag1 = true
        }
        
        _ = notificationCenter.addObserver(forName: name, object: nil, queue: .main) { _ in
            XCTAssertEqual(OperationQueue.current, .main)
            flag2 = true
        }
        
        postingQueue.addOperation {
            notificationCenter.post(name: name, object: nil)
            // All observers should be notified synchronously regardless of the observer queue.
            XCTAssertTrue(flag1)
            XCTAssertTrue(flag2)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1)
    }
}
