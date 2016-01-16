// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
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


class TestNSNotificationCenter : XCTestCase {
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_defaultCenter", test_defaultCenter),
            ("test_postNotification", test_postNotification),
            ("test_postNotificationForObject", test_postNotificationForObject),
            ("test_postMultipleNotifications", test_postMultipleNotifications),
            ("test_addObserverForNilName", test_addObserverForNilName),
            ("test_removeObserver", test_removeObserver),
        ]
    }
    
    func test_defaultCenter() {
        let defaultCenter1 = NSNotificationCenter.defaultCenter()
        XCTAssertNotNil(defaultCenter1)
        let defaultCenter2 = NSNotificationCenter.defaultCenter()
        XCTAssertEqual(defaultCenter1, defaultCenter2)
    }
    
    func removeObserver(observer: NSObjectProtocol, notificationCenter: NSNotificationCenter) {
        guard let observer = observer as? NSObject else {
            return
        }
        
        notificationCenter.removeObserver(observer)
    }
    
    func test_postNotification() {
        let notificationCenter = NSNotificationCenter()
        let notificationName = "test_postNotification_name"
        var flag = false
        let dummyObject = NSObject()
        let observer = notificationCenter.addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            XCTAssertEqual(notificationName, notification.name)
            XCTAssertTrue(dummyObject === notification.object)
            
            flag = true
        }
        
        notificationCenter.postNotificationName(notificationName, object: dummyObject)
        XCTAssertTrue(flag)
        
        removeObserver(observer, notificationCenter: notificationCenter)
    }

    func test_postNotificationForObject() {
        let notificationCenter = NSNotificationCenter()
        let notificationName = "test_postNotificationForObject_name"
        var flag = true
        let dummyObject = NSObject()
        let dummyObject2 = NSObject()
        let observer = notificationCenter.addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            flag = false
        }
        
        notificationCenter.postNotificationName(notificationName, object: dummyObject2)
        XCTAssertTrue(flag)
        
        removeObserver(observer, notificationCenter: notificationCenter)
    }
    
    func test_postMultipleNotifications() {
        let notificationCenter = NSNotificationCenter()
        let notificationName = "test_postMultipleNotifications_name"
        var flag1 = false
        let observer1 = notificationCenter.addObserverForName(notificationName, object: nil, queue: nil) { _ in
            flag1 = true
        }
        
        var flag2 = true
        let observer2 = notificationCenter.addObserverForName(notificationName, object: nil, queue: nil) { _ in
            flag2 = false
        }
        
        var flag3 = false
        let observer3 = notificationCenter.addObserverForName(notificationName, object: nil, queue: nil) { _ in
            flag3 = true
        }
        
        removeObserver(observer2, notificationCenter: notificationCenter)
        
        notificationCenter.postNotificationName(notificationName, object: nil)
        XCTAssertTrue(flag1)
        XCTAssertTrue(flag2)
        XCTAssertTrue(flag3)
        
        removeObserver(observer1, notificationCenter: notificationCenter)
        removeObserver(observer3, notificationCenter: notificationCenter)
    }

    func test_addObserverForNilName() {
        let notificationCenter = NSNotificationCenter()
        let notificationName = "test_addObserverForNilName_name"
        let invalidNotificationName = "test_addObserverForNilName_name_invalid"
        var flag1 = false
        let observer1 = notificationCenter.addObserverForName(notificationName, object: nil, queue: nil) { _ in
            flag1 = true
        }
        
        var flag2 = true
        let observer2 = notificationCenter.addObserverForName(invalidNotificationName, object: nil, queue: nil) { _ in
            flag2 = false
        }
        
        var flag3 = false
        let observer3 = notificationCenter.addObserverForName(nil, object: nil, queue: nil) { _ in
            flag3 = true
        }
        
        notificationCenter.postNotificationName(notificationName, object: nil)
        XCTAssertTrue(flag1)
        XCTAssertTrue(flag2)
        XCTAssertTrue(flag3)
        
        removeObserver(observer1, notificationCenter: notificationCenter)
        removeObserver(observer2, notificationCenter: notificationCenter)
        removeObserver(observer3, notificationCenter: notificationCenter)
    }

    func test_removeObserver() {
        let notificationCenter = NSNotificationCenter()
        let notificationName = "test_removeObserver_name"
        var flag = true
        let observer = notificationCenter.addObserverForName(notificationName, object: nil, queue: nil) { _ in
            flag = false
        }

        removeObserver(observer, notificationCenter: notificationCenter)

        notificationCenter.postNotificationName(notificationName, object: nil)
        XCTAssertTrue(flag)
    }

}
