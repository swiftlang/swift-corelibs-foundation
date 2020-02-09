// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestURLProtectionSpace : XCTestCase {

    static var allTests: [(String, (TestURLProtectionSpace) -> () throws -> Void)] {
        return [
            ("test_description", test_description),
        ]
    }

    func test_description() {
        var space = URLProtectionSpace(
            host: "apple.com",
            port: 80,
            protocol: "http",
            realm: nil,
            authenticationMethod: "basic"
        )
        XCTAssert(space.description.hasPrefix("<\(type(of: space))"))
        XCTAssert(space.description.hasSuffix(": Host:apple.com, Server:http, Auth-Scheme:NSURLAuthenticationMethodDefault, Realm:(null), Port:80, Proxy:NO, Proxy-Type:(null)"))

        space = URLProtectionSpace(
            host: "apple.com",
            port: 80,
            protocol: "http",
            realm: nil,
            authenticationMethod: "NSURLAuthenticationMethodHTMLForm"
        )
        XCTAssert(space.description.hasPrefix("<\(type(of: space))"))
        XCTAssert(space.description.hasSuffix(": Host:apple.com, Server:http, Auth-Scheme:NSURLAuthenticationMethodHTMLForm, Realm:(null), Port:80, Proxy:NO, Proxy-Type:(null)"))
    }
}
