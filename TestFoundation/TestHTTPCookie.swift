// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestHTTPCookie: XCTestCase {

    static var allTests: [(String, (TestHTTPCookie) -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_RequestHeaderFields", test_RequestHeaderFields),
            ("test_cookiesWithResponseHeader1cookie", test_cookiesWithResponseHeader1cookie),
            ("test_cookiesWithResponseHeader0cookies", test_cookiesWithResponseHeader0cookies),
            ("test_cookiesWithResponseHeader2cookies", test_cookiesWithResponseHeader2cookies),
            ("test_cookiesWithResponseHeaderNoDomain", test_cookiesWithResponseHeaderNoDomain),
            ("test_cookiesWithResponseHeaderNoPathNoDomain", test_cookiesWithResponseHeaderNoPathNoDomain)
        ]
    }

    func test_BasicConstruction() {
        let invalidVersionZeroCookie = HTTPCookie(properties: [
            .name: "TestCookie",
            .value: "Test value @#$%^$&*",
            .path: "/"
        ])
        XCTAssertNil(invalidVersionZeroCookie)

        let minimalVersionZeroCookie = HTTPCookie(properties: [
            .name: "TestCookie",
            .value: "Test value @#$%^$&*",
            .path: "/",
            .domain: "apple.com"
        ])
        XCTAssertNotNil(minimalVersionZeroCookie)
        XCTAssert(minimalVersionZeroCookie?.name == "TestCookie")
        XCTAssert(minimalVersionZeroCookie?.value == "Test value @#$%^$&*")
        XCTAssert(minimalVersionZeroCookie?.path == "/")
        XCTAssert(minimalVersionZeroCookie?.domain == "apple.com")

        let versionZeroCookieWithOriginURL = HTTPCookie(properties: [
            .name: "TestCookie",
            .value: "Test value @#$%^$&*",
            .path: "/",
            .originURL: URL(string: "https://apple.com")!
        ])
        XCTAssert(versionZeroCookieWithOriginURL?.domain == "apple.com")

        // Domain takes precedence over originURL inference
        let versionZeroCookieWithDomainAndOriginURL = HTTPCookie(properties: [
            .name: "TestCookie",
            .value: "Test value @#$%^$&*",
            .path: "/",
            .domain: "apple.com",
            .originURL: URL(string: "https://apple.com")!
        ])
        XCTAssert(versionZeroCookieWithDomainAndOriginURL?.domain == "apple.com")

        // This is implicitly a v0 cookie. Properties that aren't valid for v0 should fail.
        let versionZeroCookieWithInvalidVersionOneProps = HTTPCookie(properties: [
            .name: "TestCookie",
            .value: "Test value @#$%^$&*",
            .path: "/",
            .domain: "apple.com",
            .originURL: URL(string: "https://apple.com")!,
            .comment: "This comment should be nil since this is a v0 cookie.",
            .commentURL: "https://apple.com",
            .discard: "TRUE",
            .expires: Date(timeIntervalSince1970: 1000),
            .maximumAge: "2000",
            .port: "443,8443",
            .secure: "YES"
        ])
        XCTAssertEqual(versionZeroCookieWithInvalidVersionOneProps?.version, 0)
        XCTAssertNotNil(versionZeroCookieWithInvalidVersionOneProps?.comment)
        XCTAssertNotNil(versionZeroCookieWithInvalidVersionOneProps?.commentURL)
        XCTAssert(versionZeroCookieWithInvalidVersionOneProps?.isSessionOnly == true)

        // v0 should never use NSHTTPCookieMaximumAge
        XCTAssertNil(versionZeroCookieWithInvalidVersionOneProps?.expiresDate?.timeIntervalSince1970)

        XCTAssertEqual(versionZeroCookieWithInvalidVersionOneProps?.portList, [NSNumber(value: 443)])
        XCTAssert(versionZeroCookieWithInvalidVersionOneProps?.isSecure == true)
        XCTAssert(versionZeroCookieWithInvalidVersionOneProps?.version == 0)
    }

    func test_RequestHeaderFields() {
        let noCookies: [HTTPCookie] = []
        XCTAssertNil(HTTPCookie.requestHeaderFields(with: noCookies)["Cookie"])

        let basicCookies: [HTTPCookie] = [
            HTTPCookie(properties: [
                .name: "TestCookie1",
                .value: "testValue1",
                .path: "/",
                .originURL: URL(string: "https://apple.com")!
                ])!,
            HTTPCookie(properties: [
                .name: "TestCookie2",
                .value: "testValue2",
                .path: "/",
                .originURL: URL(string: "https://apple.com")!
                ])!,
        ]

        let basicCookieString = HTTPCookie.requestHeaderFields(with: basicCookies)["Cookie"]
        XCTAssertEqual(basicCookieString, "TestCookie1=testValue1; TestCookie2=testValue2")
    }

    func test_cookiesWithResponseHeader1cookie() {
        let header = ["header1":"value1",
                      "Set-Cookie": "fr=anjd&232; Max-Age=7776000; path=/; domain=.example.com; secure; httponly",
                      "header2":"value2",
                      "header3":"value3"]
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: header, for: URL(string: "https://example.com")!)
        XCTAssertEqual(cookies.count, 1)
        XCTAssertEqual(cookies[0].name, "fr")
        XCTAssertEqual(cookies[0].value, "anjd&232")
    }

    func test_cookiesWithResponseHeader0cookies() {
        let header = ["header1":"value1", "header2":"value2", "header3":"value3"]
        let cookies =  HTTPCookie.cookies(withResponseHeaderFields: header, for: URL(string: "http://example.com")!)
        XCTAssertEqual(cookies.count, 0)
    }

    func test_cookiesWithResponseHeader2cookies() {
        let header = ["header1":"value1",
                      "Set-Cookie": "fr=a&2@#; Max-Age=1186000; path=/; domain=.example.com; secure, xd=plm!@#;path=/;domain=.example2.com", 
                      "header2":"value2",
                      "header3":"value3"]
        let cookies =  HTTPCookie.cookies(withResponseHeaderFields: header, for: URL(string: "https://example.com")!)
        XCTAssertEqual(cookies.count, 2)
        XCTAssertTrue(cookies[0].isSecure)
        XCTAssertFalse(cookies[1].isSecure)
    }

    func test_cookiesWithResponseHeaderNoDomain() {
        let header =  ["header1":"value1",
                       "Set-Cookie": "fr=anjd&232; expires=Wed, 21 Sep 2016 05:33:00 GMT; path=/; secure; httponly",
                       "header2":"value2",
                       "header3":"value3"]
        let cookies =  HTTPCookie.cookies(withResponseHeaderFields: header, for: URL(string: "https://example.com")!)
        XCTAssertEqual(cookies[0].version, 0)
        XCTAssertEqual(cookies[0].domain, "example.com")
        XCTAssertNotNil(cookies[0].expiresDate)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss O"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        if let expiresDate = formatter.date(from: "Wed, 21 Sep 2016 05:33:00 GMT") {
            XCTAssertTrue(expiresDate.compare(cookies[0].expiresDate!) == .orderedSame)
        } else {
            XCTFail("Unable to parse the given date from the formatter")
        }
    }

    func test_cookiesWithResponseHeaderNoPathNoDomain() {
        let header = ["header1":"value1",
                      "Set-Cookie": "fr=tx; expires=Wed, 21-Sep-2016 05:33:00 GMT; Max-Age=7776000; secure; httponly", 
                      "header2":"value2",
                      "header3":"value3"]
        let cookies =  HTTPCookie.cookies(withResponseHeaderFields: header, for: URL(string: "https://example.com")!)
        XCTAssertEqual(cookies[0].domain, "example.com")
        XCTAssertEqual(cookies[0].path, "/")
    }
}
