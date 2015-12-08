//
//  TestNSNotification.swift
//  Foundation
//
//  Created by Harlan Haskins on 12/8/15.
//  Copyright © 2015 Apple. All rights reserved.
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

class TestNSNotification: XCTestCase {
    
    static let dummyNotificationName = "SwiftCoreLibsFoundationDummyNotification"
    static let object = NSNumber(double: 42.0)
    static let info = ["Test": "Info"]
    let notification = NSNotification(name: TestNSNotification.dummyNotificationName, object: TestNSNotification.object, userInfo: TestNSNotification.info)
    
    var allTests: [(String, () -> ())] {
        return [
            ("test_copyWithZone", test_copyWithZone),
        ]
    }
    
    func test_copyWithZone() {
        let copy = notification.copyWithZone(nil) as! NSNotification
        XCTAssertEqual(copy.name, notification.name)
        guard let copyObject = copy.object, object = notification.object else {
            XCTFail("Copy does not have an object")
            return
        }
        guard let copyInfo = copy.userInfo, info = notification.userInfo else {
            XCTFail("Copy does not have a userInfo")
            return
        }
        XCTAssertEqual(ObjectIdentifier(copyObject), ObjectIdentifier(object))
        XCTAssertEqual(ObjectIdentifier(copyInfo), ObjectIdentifier(info))
    }

}
