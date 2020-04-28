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

    func test_percentEncodedQueryItems() {
        var components = URLComponents()
        // no query component
        var items = components.queryItems
        XCTAssertNil(items, "nil expected from queryItems when there's no query component.")
        components.queryItems = items
        XCTAssertNil(components.percentEncodedQuery, "nil query component expected when queryItems is set to nil.")
        // again with percentEncodedQueryItems
        components.percentEncodedQueryItems = items
        XCTAssertNil(components.percentEncodedQuery, "nil query component expected when percentEncodedQueryItems is set to nil.")

        // query component zero-length string
        components.percentEncodedQuery = ""
        items = components.queryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 0)
        components.queryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "", "\"\" query component expected when queryItems is set to empty array.")
        // again with percentEncodedQueryItems
        components.percentEncodedQueryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "")

        // query component with normal name-value pairs at beginning, in middle, and at end
        components.percentEncodedQuery = "name1=value1&name2=value2&name3=value3"
        items = components.queryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "name1", value: "value1"),
            URLQueryItem(name: "name2", value: "value2"),
            URLQueryItem(name: "name3", value: "value3"),
        ])
        components.queryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "name1=value1&name2=value2&name3=value3")
        // again with percentEncodedQueryItems
        items = components.percentEncodedQueryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "name1", value: "value1"),
            URLQueryItem(name: "name2", value: "value2"),
            URLQueryItem(name: "name3", value: "value3"),
        ])
        components.percentEncodedQueryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "name1=value1&name2=value2&name3=value3")

        // query component with zero-length name-value pairs at beginning, in middle, and at end
        components.percentEncodedQuery = "&&"
        items = components.queryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "", value: nil),
            URLQueryItem(name: "", value: nil),
            URLQueryItem(name: "", value: nil),
        ])
        components.queryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "&&")
        // again with percentEncodedQueryItems
        items = components.percentEncodedQueryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "", value: nil),
            URLQueryItem(name: "", value: nil),
            URLQueryItem(name: "", value: nil),
        ])
        components.percentEncodedQueryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "&&")

        // query component not in "name=value&name=value" format
        components.percentEncodedQuery = "query"
        items = components.queryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 1)
        XCTAssertEqual(items, [URLQueryItem(name: "query", value: nil)])
        components.queryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "query")
        // again with percentEncodedQueryItems
        items = components.percentEncodedQueryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 1)
        XCTAssertEqual(items, [URLQueryItem(name: "query", value: nil)])
        components.percentEncodedQueryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "query")

        // query component with a name and a zero-length value at beginning, in middle, and at end
        components.percentEncodedQuery = "name1=&name2=&name3="
        items = components.queryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "name1", value: ""),
            URLQueryItem(name: "name2", value: ""),
            URLQueryItem(name: "name3", value: ""),
        ])
        components.queryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "name1=&name2=&name3=")
        // again with percentEncodedQueryItems
        items = components.percentEncodedQueryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "name1", value: ""),
            URLQueryItem(name: "name2", value: ""),
            URLQueryItem(name: "name3", value: ""),
        ])
        components.percentEncodedQueryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "name1=&name2=&name3=")

        // query component with a zero-length name and a value at beginning, in middle, and at end
        components.percentEncodedQuery = "=value1&=value2&=value3"
        items = components.queryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "", value: "value1"),
            URLQueryItem(name: "", value: "value2"),
            URLQueryItem(name: "", value: "value3"),
        ])
        components.queryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "=value1&=value2&=value3")
        // again with percentEncodedQueryItems
        items = components.percentEncodedQueryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "", value: "value1"),
            URLQueryItem(name: "", value: "value2"),
            URLQueryItem(name: "", value: "value3"),
        ])
        components.percentEncodedQueryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "=value1&=value2&=value3")

        // query component with name-value pair containing an equal character in the value at beginning, in middle, and at end
        components.percentEncodedQuery = "name1=value1=withEqual&name2=value2=withEqual&name3=value3=withEqual"
        items = components.queryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "name1", value: "value1=withEqual"),
            URLQueryItem(name: "name2", value: "value2=withEqual"),
            URLQueryItem(name: "name3", value: "value3=withEqual"),
        ])
        components.queryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "name1=value1%3DwithEqual&name2=value2%3DwithEqual&name3=value3%3DwithEqual")
        // again with percentEncodedQueryItems
        items = components.percentEncodedQueryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "name1", value: "value1%3DwithEqual"),
            URLQueryItem(name: "name2", value: "value2%3DwithEqual"),
            URLQueryItem(name: "name3", value: "value3%3DwithEqual"),
        ])
        components.percentEncodedQueryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "name1=value1%3DwithEqual&name2=value2%3DwithEqual&name3=value3%3DwithEqual")

        // query component with name-value pair containing percent-encoded characters at beginning, in middle, and at end
        components.percentEncodedQuery = "name1%E2%80%A2=value1%E2%80%A2&name2%E2%80%A2=value2%E2%80%A2&name3%E2%80%A2=value3%E2%80%A2"
        items = components.queryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "name1•", value: "value1•"),
            URLQueryItem(name: "name2•", value: "value2•"),
            URLQueryItem(name: "name3•", value: "value3•"),
        ])
        components.queryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "name1%E2%80%A2=value1%E2%80%A2&name2%E2%80%A2=value2%E2%80%A2&name3%E2%80%A2=value3%E2%80%A2")
        // again with percentEncodedQueryItems
        items = components.percentEncodedQueryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 3)
        XCTAssertEqual(items, [
            URLQueryItem(name: "name1%E2%80%A2",value: "value1%E2%80%A2"),
            URLQueryItem(name: "name2%E2%80%A2",value: "value2%E2%80%A2"),
            URLQueryItem(name: "name3%E2%80%A2",value: "value3%E2%80%A2"),
        ])
        components.percentEncodedQueryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "name1%E2%80%A2=value1%E2%80%A2&name2%E2%80%A2=value2%E2%80%A2&name3%E2%80%A2=value3%E2%80%A2")

        // query component with name-value pair containing percent-encoded characters that didn't need to be percent-encoded
        components.percentEncodedQuery = "%41%42%43%44=%61%62%63%64"
        items = components.queryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 1)
        XCTAssertEqual(items, [URLQueryItem(name: "ABCD", value: "abcd")])
        components.queryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "ABCD=abcd")
        // again with percentEncodedQueryItems
        components.percentEncodedQuery = "%41%42%43%44=%61%62%63%64"
        items = components.percentEncodedQueryItems
        XCTAssertNotNil(items, "Expected queryItems array.")
        XCTAssertEqual(items?.count, 1)
        XCTAssertEqual(items, [URLQueryItem(name: "%41%42%43%44", value: "%61%62%63%64")])
        components.percentEncodedQueryItems = items
        XCTAssertEqual(components.percentEncodedQuery, "%41%42%43%44=%61%62%63%64")

        /* These cases cannot be tested by XCTest since `URLComponents.percentEncodedQueryItems` will fatalError on invalid inputs.
         * Ideally, once swift gains throwing accessors percentEncodedQueryItems:setter can be marked as throws instead and tested properly.
         * Forum thread: https://forums.swift.org/t/throwable-accessors/20509
         *
         * // invalid NSURLQueryItem name with '='
         * items = [URLQueryItem(name: "name", value: "value")]
         * XCTAssertThrowsError(try components.percentEncodedQueryItems = items, "percentEncodedQueryItems.set should have thrown an error when the name has an unpercent-encoded '='.")
         * // invalid NSURLQueryItem name with '&'
         * items = [URLQueryItem(name: "name&", value:"value")]
         * XCTAssertThrowsError(try components.percentEncodedQueryItems = items, "percentEncodedQueryItems.set should have thrown an error when the name has an unpercent-encoded '&'.")
         * // invalid NSURLQueryItem name with '•'
         * items = [URLQueryItem(name: "name•", value:"value")]
         * XCTAssertThrowsError(try components.percentEncodedQueryItems = items, "percentEncodedQueryItems.set should have thrown an error when the name has an unpercent-encoded '•'.")
         * // invalid NSURLQueryItem value with '•'
         * items = [URLQueryItem(name: "name", value:"value•")]
         * XCTAssertThrowsError(try components.percentEncodedQueryItems = items, "percentEncodedQueryItems.set should have thrown an error when the value has an unpercent-encoded '•'.")
         */
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
            ("test_percentEncodedQueryItems", test_percentEncodedQueryItems),
        ]
    }
}
