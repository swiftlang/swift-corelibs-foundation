// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestURLCredential : XCTestCase {
    
    static var allTests: [(String, (TestURLCredential) -> () throws -> Void)] {
        return [
                   ("test_construction", test_construction),
                   ("test_copy", test_copy),
                   ("test_NSCoding", test_NSCoding)
        ]
    }
    
    func test_construction() {
        let credential = URLCredential(user: "swiftUser", password: "swiftPassword", persistence: .forSession)
        XCTAssertEqual(credential.user, "swiftUser")
        XCTAssertEqual(credential.password, "swiftPassword")
        XCTAssertEqual(credential.persistence, URLCredential.Persistence.forSession)
        XCTAssertEqual(credential.hasPassword, true)
    }

    func test_copy() {
        let credential = URLCredential(user: "swiftUser", password: "swiftPassword", persistence: .forSession)
        let copy = credential.copy() as! URLCredential
        XCTAssertTrue(copy.isEqual(credential))
    }
    
    func test_NSCoding() {
        let credentialA = URLCredential(user: "swiftUser", password: "swiftPassword", persistence: .forSession)
        let credentialB = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: credentialA)) as! URLCredential
        XCTAssertEqual(credentialA, credentialB, "Archived then unarchived url credential must be equal.")
    }
}
