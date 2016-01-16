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


class TestNSUUID : XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_Equality", test_Equality),
            ("test_InvalidUUID", test_InvalidUUID),
            ("test_InitializationWithNil", test_InitializationWithNil),
            ("test_UUIDString", test_UUIDString),
            ("test_description", test_description),
            // Disabled until NSKeyedArchiver and NSKeyedUnarchiver are implemented
            // ("test_NSCoding", test_NSCoding),
        ]
    }
    
    func test_Equality() {
        let uuidA = NSUUID(UUIDString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        let uuidB = NSUUID(UUIDString: "e621e1f8-c36c-495a-93fc-0c247a3e6e5f")
        let uuidC = NSUUID(UUIDBytes: [0xe6,0x21,0xe1,0xf8,0xc3,0x6c,0x49,0x5a,0x93,0xfc,0x0c,0x24,0x7a,0x3e,0x6e,0x5f])
        let uuidD = NSUUID()
        
        XCTAssertEqual(uuidA, uuidB, "String case must not matter.")
        XCTAssertEqual(uuidA, uuidC, "A UUID initialized with a string must be equal to the same UUID initialized with its UnsafePointer<UInt8> equivalent representation.")
        XCTAssertNotEqual(uuidC, uuidD, "Two different UUIDs must not be equal.")
    }
    
    func test_InvalidUUID() {
        let uuid = NSUUID(UUIDString: "Invalid UUID")
        XCTAssertNil(uuid, "The convenience initializer `init?(UUIDString string:)` must return nil for an invalid UUID string.")
    }
    
    func test_InitializationWithNil() {
        let uuid = NSUUID(UUIDBytes: nil)
        XCTAssertEqual(uuid, NSUUID(UUIDBytes: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]), "The convenience initializer `init(UUIDBytes bytes:)` must return the Nil UUID when UUIDBytes is nil.")
    }
    
    func test_UUIDString() {
        let uuid = NSUUID(UUIDBytes: [0xe6,0x21,0xe1,0xf8,0xc3,0x6c,0x49,0x5a,0x93,0xfc,0x0c,0x24,0x7a,0x3e,0x6e,0x5f])
        XCTAssertEqual(uuid.UUIDString, "e621e1f8-c36c-495a-93fc-0c247a3e6e5f", "The UUIDString representation must be lowercase as defined by RFC 4122.")
    }
    
    func test_description() {
        let uuid = NSUUID()
        XCTAssertEqual(uuid.description, uuid.UUIDString, "The description must be the same as the UUIDString.")
    }
    
    func test_NSCoding() {
        let uuidA = NSUUID()
        let uuidB = NSKeyedUnarchiver.unarchiveObjectWithData(NSKeyedArchiver.archivedDataWithRootObject(uuidA)) as! NSUUID
        XCTAssertEqual(uuidA, uuidB, "Archived then unarchived uuid must be equal.")
    }
}
