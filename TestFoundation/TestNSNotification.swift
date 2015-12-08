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
            // TODO: Uncomment this once NSKeyed[Un]Archiver is implemented.
            // ("test_encodeWithCoder", test_encodeWithCoder),
        ]
    }
    
    func assertEqual(original: NSNotification, copy: NSNotification) {
        XCTAssertEqual(copy.name, original.name)
        guard let copyObject = copy.object, object = original.object else {
            XCTFail("Copy does not have an object")
            return
        }
        guard let copyInfo = copy.userInfo, info = original.userInfo else {
            XCTFail("Copy does not have a userInfo")
            return
        }
        XCTAssertEqual(ObjectIdentifier(copyObject), ObjectIdentifier(object))
        XCTAssertEqual(ObjectIdentifier(copyInfo), ObjectIdentifier(info))
    }
    
    func test_copyWithZone() {
        let copy = notification.copyWithZone(nil) as! NSNotification
        assertEqual(notification, copy: copy)
    }
    
    func test_encodeWithCoder() {
        let archive = NSKeyedArchiver.archivedDataWithRootObject(notification)
        guard let unarchived = NSKeyedUnarchiver.unarchiveObjectWithData(archive) as? NSNotification else {
            XCTFail("Notification could not be unarchived.")
            return
        }
        assertEqual(notification, copy: unarchived)
    }

}
