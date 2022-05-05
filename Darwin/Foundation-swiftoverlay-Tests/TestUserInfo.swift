//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest

struct SubStruct: Equatable {
    var i: Int
    var str: String

    static func ==(lhs: SubStruct, rhs: SubStruct) -> Bool {
        return lhs.i == rhs.i && 
               lhs.str == rhs.str
    }
}

struct SomeStructure: Hashable {
    var i: Int
    var str: String
    var sub: SubStruct

    static func ==(lhs: SomeStructure, rhs: SomeStructure) -> Bool {
        return lhs.i == rhs.i && 
               lhs.str == rhs.str && 
               lhs.sub == rhs.sub
    }

    // FIXME: we don't care about this, but Any only finds == on Hashables
    func hash(into hasher: inout Hasher) {
        hasher.combine(i)
        hasher.combine(str)
        hasher.combine(sub.i)
        hasher.combine(sub.str)
    }
}

/*
 Notification and potentially other structures require a representation of a 
 userInfo dictionary. The Objective-C counterparts are represented via
 NSDictionary which can only store a hashable key (actually 
 NSObject<NSCopying> *) and a value of AnyObject (actually NSObject *). However
 it is desired in swift to store Any in the value. These structure expositions
 in swift have an adapter that allows them to pass a specialized NSDictionary
 subclass to the Objective-C layer that can round trip the stored Any types back
 out into Swift.

 In this case NSNotification -> Notification bridging is suitable to verify that
 behavior.
*/

class TestUserInfo : XCTestCase {
    var posted: Notification?

    func validate(_ testStructure: SomeStructure, _ value: SomeStructure) {
        XCTAssertEqual(testStructure.i, value.i)
        XCTAssertEqual(testStructure.str, value.str)
        XCTAssertEqual(testStructure.sub.i, value.sub.i)
        XCTAssertEqual(testStructure.sub.str, value.sub.str)
    }

    func test_userInfoPost() {
        let userInfoKey = "userInfoKey"
        let notifName = Notification.Name(rawValue: "TestSwiftNotification")
        let testStructure = SomeStructure(i: 5, str: "10", sub: SubStruct(i: 6, str: "11"))
        let info: [AnyHashable : Any] = [
            AnyHashable(userInfoKey) : testStructure
        ]
        let note = Notification(name: notifName, userInfo: info)
        XCTAssertNotNil(note.userInfo)
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(TestUserInfo.notification(_:)), name: notifName, object: nil)
        nc.post(note)
        XCTAssertNotNil(posted)
        if let notification = posted {
            let postedInfo = notification.userInfo
            XCTAssertNotNil(postedInfo)
            if let userInfo = postedInfo {
                let postedValue = userInfo[AnyHashable(userInfoKey)] as? SomeStructure
                XCTAssertNotNil(postedValue)
                if let value = postedValue {
                    validate(testStructure, value)
                }
            }
        }
    }

    func test_equality() {
        let userInfoKey = "userInfoKey"
        let notifName = Notification.Name(rawValue: "TestSwiftNotification")
        let testStructure = SomeStructure(i: 5, str: "10", sub: SubStruct(i: 6, str: "11"))
        let testStructure2 = SomeStructure(i: 6, str: "10", sub: SubStruct(i: 6, str: "11"))
        let info1: [AnyHashable : Any] = [
            AnyHashable(userInfoKey) : testStructure
        ]
        let info2: [AnyHashable : Any] = [
            AnyHashable(userInfoKey) : "this can convert"
        ]
        let info3: [AnyHashable : Any] = [
            AnyHashable(userInfoKey) : testStructure2
        ]

        let note1 = Notification(name: notifName, userInfo: info1)
        let note2 = Notification(name: notifName, userInfo: info1)
        XCTAssertEqual(note1, note2)

        let note3 = Notification(name: notifName, userInfo: info2)
        let note4 = Notification(name: notifName, userInfo: info2)
        XCTAssertEqual(note3, note4)

        let note5 = Notification(name: notifName, userInfo: info3)
        XCTAssertNotEqual(note1, note5)
    }

    @objc func notification(_ notif: Notification) {
        posted = notif
    }

    // MARK: -
    func test_classForCoder() {
        // confirm internal bridged impl types are not exposed to archival machinery
        // we have to be circuitous here, as bridging makes it very difficult to confirm this
        //
        // Gated on the availability of NSKeyedArchiver.archivedData(withRootObject:).
        if #available(macOS 10.11, iOS 9.0, tvOS 9.0, watchOS 2.0, *) {
            let note = Notification(name: Notification.Name(rawValue: "TestSwiftNotification"), userInfo: [AnyHashable("key"):"value"])
            let archivedNote = NSKeyedArchiver.archivedData(withRootObject: note)
            let noteAsPlist = try! PropertyListSerialization.propertyList(from: archivedNote, options: [], format: nil)
            let plistAsData = try! PropertyListSerialization.data(fromPropertyList: noteAsPlist, format: .xml, options: 0)
            let xml = NSString(data: plistAsData, encoding: String.Encoding.utf8.rawValue)!
            XCTAssertEqual(xml.range(of: "_NSUserInfoDictionary").location, NSNotFound)
        }
    }

    func test_AnyHashableContainingNotification() {
        let values: [Notification] = [
            Notification(name: Notification.Name(rawValue: "TestSwiftNotification")),
            Notification(name: Notification.Name(rawValue: "TestOtherSwiftNotification")),
            Notification(name: Notification.Name(rawValue: "TestOtherSwiftNotification")),
        ]
        let anyHashables = values.map(AnyHashable.init)
        expectEqual(Notification.self, type(of: anyHashables[0].base))
        expectEqual(Notification.self, type(of: anyHashables[1].base))
        expectEqual(Notification.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }

    func test_AnyHashableCreatedFromNSNotification() {
        let values: [NSNotification] = [
            NSNotification(name: Notification.Name(rawValue: "TestSwiftNotification"), object: nil),
            NSNotification(name: Notification.Name(rawValue: "TestOtherSwiftNotification"), object: nil),
            NSNotification(name: Notification.Name(rawValue: "TestOtherSwiftNotification"), object: nil),
        ]
        let anyHashables = values.map(AnyHashable.init)
        expectEqual(Notification.self, type(of: anyHashables[0].base))
        expectEqual(Notification.self, type(of: anyHashables[1].base))
        expectEqual(Notification.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}
