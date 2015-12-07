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
    var allTests : [(String, () -> ())] {
        return [
            ("test_defaultCenter", test_defaultCenter),
            ("test_postNotification", test_postNotification),
            ("test_postMultipleNotifications", test_postMultipleNotifications),
            ("test_removeObserver", test_removeObserver),
        ]
    }
    
    func test_defaultCenter() {
        let defaultCenter1 = NSNotificationCenter.defaultCenter()
        XCTAssertNotNil(defaultCenter1)
        let defaultCenter2 = NSNotificationCenter.defaultCenter()
        XCTAssertEqual(defaultCenter1, defaultCenter2)
    }
    
    func removeObserverFromDefaultCenter(observer: NSObjectProtocol) {
        guard let observer = observer as? NSObject else {
            return
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(observer)
    }
    
    func test_postNotification() {
        let defaultCenter = NSNotificationCenter.defaultCenter()
        let notificationName = "test_postNotification_name"
        var flag = false
        let dummyObject = NSObject()
        let observer = defaultCenter.addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            XCTAssertEqual(notificationName, notification.name)
            XCTAssertTrue(dummyObject === notification.object)
            
            flag = true
        }
        
        defaultCenter.postNotificationName(notificationName, object: dummyObject)
        XCTAssertTrue(flag)
        
        removeObserverFromDefaultCenter(observer)

        flag = true
        let dummyObject2 = NSObject()
        let observer2 = defaultCenter.addObserverForName(notificationName, object: dummyObject, queue: nil) { notification in
            flag = false
        }
        
        defaultCenter.postNotificationName(notificationName, object: dummyObject2)
        XCTAssertTrue(flag)
        
        removeObserverFromDefaultCenter(observer2)
    }

    func test_postMultipleNotifications() {
        let defaultCenter = NSNotificationCenter.defaultCenter()
        let notificationName = "test_postNotification_name"
        var flag1 = false
        let observer1 = defaultCenter.addObserverForName(notificationName, object: nil, queue: nil) { _ in
            flag1 = true
        }

        var flag2 = true
        let observer2 = defaultCenter.addObserverForName(notificationName, object: nil, queue: nil) { _ in
            flag2 = false
        }

        var flag3 = false
        let observer3 = defaultCenter.addObserverForName(notificationName, object: nil, queue: nil) { _ in
            flag3 = true
        }

        removeObserverFromDefaultCenter(observer2)

        defaultCenter.postNotificationName(notificationName, object: nil)
        XCTAssertTrue(flag1)
        XCTAssertTrue(flag2)
        XCTAssertTrue(flag3)
        
        removeObserverFromDefaultCenter(observer1)
        removeObserverFromDefaultCenter(observer3)
    }

    func test_removeObserver() {
        let defaultCenter = NSNotificationCenter.defaultCenter()
        let notificationName = "test_removeObserver_name"
        var flag = true
        let observer = defaultCenter.addObserverForName(notificationName, object: nil, queue: nil) { _ in
            flag = false
        }

        removeObserverFromDefaultCenter(observer)

        defaultCenter.postNotificationName(notificationName, object: nil)
        XCTAssertTrue(flag)
    }

}