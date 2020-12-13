// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/// Reads the test data plist file and returns the list of objects
private func getTestData() -> [Any]? {
    let testFilePath = testBundle().url(forResource: "NSURLTestData", withExtension: "plist")
    let data = try! Data(contentsOf: testFilePath!)
    guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) else {
        XCTFail("Unable to deserialize property list data")
        return nil
    }
    guard let testRoot = plist as? [String : Any] else {
        XCTFail("Unable to deserialize property list data")
        return nil
    }
    guard let parsingTests = testRoot[kURLTestParsingTestsKey] as? [Any] else {
        XCTFail("Unable to create the parsingTests dictionary")
        return nil
    }
    return parsingTests
}

class TestURLComponents: XCTestCase {

    func test_queryItems() {
        let urlString = "http://localhost:8080/foo?bar=&bar=baz"
        let url = URL(string: urlString)!

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        var query = [String: String]()
        components?.queryItems?.forEach {
            query[$0.name] = $0.value ?? ""
        }
        XCTAssertEqual(["bar": "baz"], query)
    }

    func test_string() {
        for obj in getTestData()! {
            let testDict = obj as! [String: Any]
            let unencodedString = testDict[kURLTestUrlKey] as! String
            let expectedString = NSString(string: unencodedString).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
            guard let components = URLComponents(string: expectedString) else { continue }
            XCTAssertEqual(components.string!, expectedString, "should be the expected string (\(components.string!) != \(expectedString))")
        }
    }

    func test_portSetter() {
        let urlString = "http://myhost.mydomain.com"
        let port: Int = 8080
        let expectedString = "http://myhost.mydomain.com:8080"
        var url = URLComponents(string: urlString)
        url!.port = port
        let receivedString = url!.string
        XCTAssertEqual(receivedString, expectedString, "expected \(expectedString) but received \(receivedString as Optional)")
    }

    func test_url() throws {

        let baseURL = try XCTUnwrap(URL(string: "https://www.example.com"))

        /* test NSURLComponents without authority */
        guard var compWithAuthority = URLComponents(string: "https://www.swift.org") else {
            XCTFail("Failed to create URLComponents using 'https://www.swift.org'")
            return
        }
        compWithAuthority.path = "/path/to/file with space.html"
        compWithAuthority.query = "id=23&search=Foo Bar"
        var expectedString = "https://www.swift.org/path/to/file%20with%20space.html?id=23&search=Foo%20Bar"
        XCTAssertEqual(compWithAuthority.string, expectedString, "expected \(expectedString) but received \(compWithAuthority.string as Optional)")

        guard let urlA = compWithAuthority.url(relativeTo: baseURL) else {
            XCTFail("URLComponents with authority failed to create relative URL to '\(baseURL)'")
            return
        }
        XCTAssertNil(urlA.baseURL)
        XCTAssertEqual(urlA.absoluteString, expectedString, "expected \(expectedString) but received \(urlA.absoluteString)")

        compWithAuthority.path = "path/to/file with space.html" //must start with /
        XCTAssertNil(compWithAuthority.string) // must be nil
        XCTAssertNil(compWithAuthority.url(relativeTo: baseURL)) //must be nil

        /* test NSURLComponents without authority */
        var compWithoutAuthority = URLComponents()
        compWithoutAuthority.path = "path/to/file with space.html"
        compWithoutAuthority.query = "id=23&search=Foo Bar"
        expectedString = "path/to/file%20with%20space.html?id=23&search=Foo%20Bar"
        XCTAssertEqual(compWithoutAuthority.string, expectedString, "expected \(expectedString) but received \(compWithoutAuthority.string as Optional)")

        guard let urlB = compWithoutAuthority.url(relativeTo: baseURL) else {
            XCTFail("URLComponents without authority failed to create relative URL to '\(baseURL)'")
            return
        }
        expectedString = "https://www.example.com/path/to/file%20with%20space.html?id=23&search=Foo%20Bar"
        XCTAssertEqual(urlB.absoluteString, expectedString, "expected \(expectedString) but received \(urlB.absoluteString)")

        compWithoutAuthority.path = "//path/to/file with space.html" //shouldn't start with //
        XCTAssertNil(compWithoutAuthority.string) // must be nil
        XCTAssertNil(compWithoutAuthority.url(relativeTo: baseURL)) //must be nil
    }

    func test_copy() {
        let urlString = "https://www.swift.org/path/to/file.html?id=name"
        let urlComponent = NSURLComponents(string: urlString)!
        let copy = urlComponent.copy() as! NSURLComponents

        /* Assert that NSURLComponents.copy did not return self */
        XCTAssertFalse(copy === urlComponent)

        /* Assert that NSURLComponents.copy is actually a copy of NSURLComponents */
        XCTAssertTrue(copy.isEqual(urlComponent))
    }

    func test_hash() {
        let c1 = URLComponents(string: "https://www.swift.org/path/to/file.html?id=name")!
        let c2 = URLComponents(string: "https://www.swift.org/path/to/file.html?id=name")!

        XCTAssertEqual(c1, c2)
        XCTAssertEqual(c1.hashValue, c2.hashValue)

        let strings: [String?] = (0..<20).map { "s\($0)" as String? }
        checkHashing_ValueType(
            initialValue: URLComponents(),
            byMutating: \URLComponents.scheme,
            throughValues: strings)
        checkHashing_ValueType(
            initialValue: URLComponents(),
            byMutating: \URLComponents.user,
            throughValues: strings)
        checkHashing_ValueType(
            initialValue: URLComponents(),
            byMutating: \URLComponents.password,
            throughValues: strings)
        checkHashing_ValueType(
            initialValue: URLComponents(),
            byMutating: \URLComponents.host,
            throughValues: strings)
        checkHashing_ValueType(
            initialValue: URLComponents(),
            byMutating: \URLComponents.port,
            throughValues: (0..<20).map { $0 as Int? })
        checkHashing_ValueType(
            initialValue: URLComponents(),
            byMutating: \URLComponents.path,
            throughValues: strings.compactMap { $0 })
        checkHashing_ValueType(
            initialValue: URLComponents(),
            byMutating: \URLComponents.query,
            throughValues: strings)
        checkHashing_ValueType(
            initialValue: URLComponents(),
            byMutating: \URLComponents.fragment,
            throughValues: strings)

        checkHashing_NSCopying(
            initialValue: NSURLComponents(),
            byMutating: \NSURLComponents.scheme,
            throughValues: strings)
        checkHashing_NSCopying(
            initialValue: NSURLComponents(),
            byMutating: \NSURLComponents.user,
            throughValues: strings)
        checkHashing_NSCopying(
            initialValue: NSURLComponents(),
            byMutating: \NSURLComponents.password,
            throughValues: strings)
        checkHashing_NSCopying(
            initialValue: NSURLComponents(),
            byMutating: \NSURLComponents.host,
            throughValues: strings)
        checkHashing_NSCopying(
            initialValue: NSURLComponents(),
            byMutating: \NSURLComponents.port,
            throughValues: (0..<20).map { $0 as NSNumber? })
        checkHashing_NSCopying(
            initialValue: NSURLComponents(),
            byMutating: \NSURLComponents.path,
            throughValues: strings)
        checkHashing_NSCopying(
            initialValue: NSURLComponents(),
            byMutating: \NSURLComponents.query,
            throughValues: strings)
        checkHashing_NSCopying(
            initialValue: NSURLComponents(),
            byMutating: \NSURLComponents.fragment,
            throughValues: strings)
    }

    func test_createURLWithComponents() {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = "https";
        urlComponents.host = "com.test.swift";
        urlComponents.path = "/test/path";
        let date = Date()
        let query1 = URLQueryItem(name: "date", value: date.description)
        let query2 = URLQueryItem(name: "simpleDict", value: "false")
        let query3 = URLQueryItem(name: "checkTest", value: "false")
        let query4 = URLQueryItem(name: "someKey", value: "afsdjhfgsdkf^fhdjgf")
        urlComponents.queryItems = [query1, query2, query3, query4]
        XCTAssertNotNil(urlComponents.url?.query)
        XCTAssertEqual(urlComponents.queryItems?.count, 4)
    }

    func test_path() {
        let c1 = URLComponents()
        XCTAssertEqual(c1.path, "")

        let c2 = URLComponents(string: "http://swift.org")
        XCTAssertEqual(c2?.path, "")

        let c3 = URLComponents(string: "http://swift.org/")
        XCTAssertEqual(c3?.path, "/")

        let c4 = URLComponents(string: "http://swift.org/foo/bar")
        XCTAssertEqual(c4?.path, "/foo/bar")

        let c5 = URLComponents(string: "http://swift.org:80/foo/bar")
        XCTAssertEqual(c5?.path, "/foo/bar")

        let c6 = URLComponents(string: "http://swift.org:80/foo/b%20r")
        XCTAssertEqual(c6?.path, "/foo/b r")
    }

    func test_percentEncodedPath() {
        let c1 = URLComponents()
        XCTAssertEqual(c1.percentEncodedPath, "")

        let c2 = URLComponents(string: "http://swift.org")
        XCTAssertEqual(c2?.percentEncodedPath, "")

        let c3 = URLComponents(string: "http://swift.org/")
        XCTAssertEqual(c3?.percentEncodedPath, "/")

        let c4 = URLComponents(string: "http://swift.org/foo/bar")
        XCTAssertEqual(c4?.percentEncodedPath, "/foo/bar")

        let c5 = URLComponents(string: "http://swift.org:80/foo/bar")
        XCTAssertEqual(c5?.percentEncodedPath, "/foo/bar")

        let c6 = URLComponents(string: "http://swift.org:80/foo/b%20r")
        XCTAssertEqual(c6?.percentEncodedPath, "/foo/b%20r")
    }

    static var allTests: [(String, (TestURLComponents) -> () throws -> Void)] {
        return [
            ("test_queryItems", test_queryItems),
            ("test_string", test_string),
            ("test_port", test_portSetter),
            ("test_url", test_url),
            ("test_copy", test_copy),
            ("test_hash", test_hash),
            ("test_createURLWithComponents", test_createURLWithComponents),
            ("test_path", test_path),
            ("test_percentEncodedPath", test_percentEncodedPath),
        ]
    }
}
