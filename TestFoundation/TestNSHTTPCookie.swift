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

class TestNSHTTPCookie: XCTestCase {

    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_RequestHeaderFields", test_RequestHeaderFields)
        ]
    }

    func test_BasicConstruction() {
        let invalidVersionZeroCookie = NSHTTPCookie(properties: [
            NSHTTPCookieName: "TestCookie",
            NSHTTPCookieValue: "Test value @#$%^$&*",
            NSHTTPCookiePath: "/"
        ])
        XCTAssertNil(invalidVersionZeroCookie)

        let minimalVersionZeroCookie = NSHTTPCookie(properties: [
            NSHTTPCookieName: "TestCookie",
            NSHTTPCookieValue: "Test value @#$%^$&*",
            NSHTTPCookiePath: "/",
            NSHTTPCookieDomain: "apple.com"
        ])
        XCTAssertNotNil(minimalVersionZeroCookie)
        XCTAssert(minimalVersionZeroCookie?.name == "TestCookie")
        XCTAssert(minimalVersionZeroCookie?.value == "Test value @#$%^$&*")
        XCTAssert(minimalVersionZeroCookie?.path == "/")
        XCTAssert(minimalVersionZeroCookie?.domain == "apple.com")

        let versionZeroCookieWithOriginURL = NSHTTPCookie(properties: [
            NSHTTPCookieName: "TestCookie",
            NSHTTPCookieValue: "Test value @#$%^$&*",
            NSHTTPCookiePath: "/",
            NSHTTPCookieOriginURL: NSURL(string: "https://apple.com")!
        ])
        XCTAssert(versionZeroCookieWithOriginURL?.domain == "apple.com")

        // Domain takes precedence over originURL inference
        let versionZeroCookieWithDomainAndOriginURL = NSHTTPCookie(properties: [
            NSHTTPCookieName: "TestCookie",
            NSHTTPCookieValue: "Test value @#$%^$&*",
            NSHTTPCookiePath: "/",
            NSHTTPCookieDomain: "apple.com",
            NSHTTPCookieOriginURL: NSURL(string: "https://apple.com")!
        ])
        XCTAssert(versionZeroCookieWithDomainAndOriginURL?.domain == "apple.com")

        // This is implicitly a v0 cookie. Properties that aren't valid for v0 should fail.
        let versionZeroCookieWithInvalidVersionOneProps = NSHTTPCookie(properties: [
            NSHTTPCookieName: "TestCookie",
            NSHTTPCookieValue: "Test value @#$%^$&*",
            NSHTTPCookiePath: "/",
            NSHTTPCookieDomain: "apple.com",
            NSHTTPCookieOriginURL: NSURL(string: "https://apple.com")!,
            NSHTTPCookieComment: "This comment should be nil since this is a v0 cookie.",
            NSHTTPCookieCommentURL: NSURL(string: "https://apple.com")!,
            NSHTTPCookieDiscard: "TRUE",
            NSHTTPCookieExpires: NSDate(timeIntervalSince1970: 1000),
            NSHTTPCookieMaximumAge: "2000",
            NSHTTPCookiePort: "443,8443",
            NSHTTPCookieSecure: "YES"
        ])
        XCTAssertNil(versionZeroCookieWithInvalidVersionOneProps?.comment)
        XCTAssertNil(versionZeroCookieWithInvalidVersionOneProps?.commentURL)
        XCTAssert(versionZeroCookieWithInvalidVersionOneProps?.sessionOnly == true)

        // v0 should never use NSHTTPCookieMaximumAge
        XCTAssert(
            versionZeroCookieWithInvalidVersionOneProps?.expiresDate?.timeIntervalSince1970 ==
            NSDate(timeIntervalSince1970: 1000).timeIntervalSince1970
        )

        XCTAssertNil(versionZeroCookieWithInvalidVersionOneProps?.portList)
        XCTAssert(versionZeroCookieWithInvalidVersionOneProps?.secure == true)
        XCTAssert(versionZeroCookieWithInvalidVersionOneProps?.version == 0)
    }
    
    func test_RequestHeaderFields() {
        let noCookies: [NSHTTPCookie] = []
        XCTAssertEqual(NSHTTPCookie.requestHeaderFieldsWithCookies(noCookies)["Cookie"], "")
        
        let basicCookies: [NSHTTPCookie] = [
            NSHTTPCookie(properties: [
                NSHTTPCookieName: "TestCookie1",
                NSHTTPCookieValue: "testValue1",
                NSHTTPCookiePath: "/",
                NSHTTPCookieOriginURL: NSURL(string: "https://apple.com")!
                ])!,
            NSHTTPCookie(properties: [
                NSHTTPCookieName: "TestCookie2",
                NSHTTPCookieValue: "testValue2",
                NSHTTPCookiePath: "/",
                NSHTTPCookieOriginURL: NSURL(string: "https://apple.com")!
                ])!,
        ]
        
        let basicCookieString = NSHTTPCookie.requestHeaderFieldsWithCookies(basicCookies)["Cookie"]
        XCTAssertEqual(basicCookieString, "TestCookie1=testValue1; TestCookie2=testValue2")
    }
}