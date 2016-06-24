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

class TestNSURLCredential : XCTestCase {
    
    static var allTests: [(String, (TestNSURLCredential) -> () throws -> Void)] {
        return [
                   ("test_construction", test_construction)
        ]
    }
    
    func test_construction() {
        let credential = URLCredential(user: "swiftUser", password: "swiftPassword", persistence: .forSession)
        XCTAssertNotNil(credential)
        XCTAssertEqual(credential.user, "swiftUser")
        XCTAssertEqual(credential.password, "swiftPassword")
        XCTAssertEqual(credential.persistence, URLCredential.Persistence.forSession)
        XCTAssertEqual(credential.hasPassword, true)
    }
}
