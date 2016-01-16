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


class TestNSURLResponse : XCTestCase {
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_URL", test_URL),
            ("test_MIMEType", test_MIMEType),
            ("test_ExpectedContentLength", test_ExpectedContentLength),
            ("test_TextEncodingName", test_TextEncodingName)
        ]
    }
    
    func test_URL() {
        let url = NSURL(string: "a/test/path")!
        let res = NSURLResponse(URL: url, MIMEType: "txt", expectedContentLength: 0, textEncodingName: nil)
        XCTAssertEqual(res.URL, url, "should be the expected url")
    }
    
    func test_MIMEType() {
        let mimetype1 = "text/plain"
        let mimetype2 = "application/wordperfect"
        let res1 = NSURLResponse(URL: NSURL(string: "test")!, MIMEType: mimetype1, expectedContentLength: 0, textEncodingName: nil)
        XCTAssertEqual(res1.MIMEType, mimetype1, "should be the passed in mimetype")
        let res2 = NSURLResponse(URL: NSURL(string: "test")!, MIMEType: mimetype2, expectedContentLength: 0, textEncodingName: nil)
        XCTAssertEqual(res2.MIMEType, mimetype2, "should be the other mimetype")
    }
    
    func test_ExpectedContentLength() {
        let zeroContentLength = 0
        let positiveContentLength = 100
        let url = NSURL(string: "test")!
        let res1 = NSURLResponse(URL: url, MIMEType: "text/plain", expectedContentLength: zeroContentLength, textEncodingName: nil)
        XCTAssertEqual(res1.expectedContentLength, Int64(zeroContentLength), "should be Int65 of the zero length")
        let res2 = NSURLResponse(URL: url, MIMEType: "text/plain", expectedContentLength: positiveContentLength, textEncodingName: nil)
        XCTAssertEqual(res2.expectedContentLength, Int64(positiveContentLength), "should be Int64 of the positive content length")
    }
    
    func test_TextEncodingName() {
        let encoding = "utf8"
        let url = NSURL(string: "test")!
        let res1 = NSURLResponse(URL: url, MIMEType: nil, expectedContentLength: 0, textEncodingName: encoding)
        XCTAssertEqual(res1.textEncodingName, encoding, "should be the utf8 encoding")
        let res2 = NSURLResponse(URL: url, MIMEType: nil, expectedContentLength: 0, textEncodingName: nil)
        XCTAssertNil(res2.textEncodingName)
    }
}