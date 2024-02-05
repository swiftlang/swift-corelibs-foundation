// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSURL: XCTestCase {

    func test_absoluteString() {
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/folder", isDirectory: true).absoluteString, "file:///path/to/folder/")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/folder/", isDirectory: true).absoluteString, "file:///path/to/folder/")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../folder", isDirectory: true).absoluteString, "file:///path/../folder/")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/./folder/..", isDirectory: true).absoluteString, "file:///path/to/./folder/../")

        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/.file", isDirectory: false).absoluteString, "file:///path/to/.file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/file/", isDirectory: false).absoluteString, "file:///path/to/file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../file", isDirectory: false).absoluteString, "file:///path/../file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/./file/..", isDirectory: false).absoluteString, "file:///path/to/./file/..")
    }

    func test_pathComponents() {
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/folder", isDirectory: true).pathComponents, ["/", "path", "to", "folder"])
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/folder/", isDirectory: true).pathComponents, ["/", "path", "to", "folder"])
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../folder", isDirectory: true).pathComponents, ["/", "path", "..", "folder"])
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../folder", isDirectory: true).standardized?.pathComponents, ["/", "folder"])
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/./folder/..", isDirectory: true).pathComponents, ["/", "path", "to", ".", "folder", ".."])

        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/.file", isDirectory: false).pathComponents, ["/", "path", "to", ".file"])
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/file/", isDirectory: false).pathComponents, ["/", "path", "to", "file"])
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../file", isDirectory: false).pathComponents, ["/", "path", "..", "file"])
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/./file/..", isDirectory: false).pathComponents, ["/", "path", "to", ".", "file", ".."])
    }

    func test_standardized() {
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/folder", isDirectory: true).standardized?.absoluteString, "file:///path/to/folder/")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/folder/", isDirectory: true).standardized?.absoluteString, "file:///path/to/folder/")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../folder", isDirectory: true).standardized?.absoluteString, "file:///folder/")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/./folder/..", isDirectory: true).standardized?.absoluteString, "file:///path/to/")

        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/.file", isDirectory: false).standardized?.absoluteString, "file:///path/to/.file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/file/", isDirectory: false).standardized?.absoluteString, "file:///path/to/file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../file", isDirectory: false).standardized?.absoluteString, "file:///file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/./file/..", isDirectory: false).standardized?.absoluteString, "file:///path/to")
    }

    func test_standardizingPath() {
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/folder", isDirectory: true).standardizingPath?.absoluteString, "file:///path/to/folder/")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/folder/", isDirectory: true).standardizingPath?.absoluteString, "file:///path/to/folder/")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../folder", isDirectory: true).standardizingPath?.absoluteString, "file:///folder/")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/./folder/..", isDirectory: true).standardizingPath?.absoluteString, "file:///path/to/")

        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/.file", isDirectory: false).standardizingPath?.absoluteString, "file:///path/to/.file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/file/", isDirectory: false).standardizingPath?.absoluteString, "file:///path/to/file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../file", isDirectory: false).standardizingPath?.absoluteString, "file:///file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/./file/..", isDirectory: false).standardizingPath?.absoluteString, "file:///path/to")
    }

    func test_resolvingSymlinksInPath() {
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/folder", isDirectory: true).resolvingSymlinksInPath?.absoluteString, "file:///path/to/folder")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/folder/", isDirectory: true).resolvingSymlinksInPath?.absoluteString, "file:///path/to/folder")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../folder", isDirectory: true).resolvingSymlinksInPath?.absoluteString, "file:///folder")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/./folder/..", isDirectory: true).resolvingSymlinksInPath?.absoluteString, "file:///path/to")

        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/.file", isDirectory: false).resolvingSymlinksInPath?.absoluteString, "file:///path/to/.file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/file/", isDirectory: false).resolvingSymlinksInPath?.absoluteString, "file:///path/to/file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/../file", isDirectory: false).resolvingSymlinksInPath?.absoluteString, "file:///file")
        XCTAssertEqual(NSURL(fileURLWithPath: "/path/to/./file/..", isDirectory: false).resolvingSymlinksInPath?.absoluteString, "file:///path/to")
    }

    static var allTests: [(String, (TestNSURL) -> () throws -> Void)] {
        let tests: [(String, (TestNSURL) -> () throws -> Void)] = [
            ("test_absoluteString", test_absoluteString),
            ("test_pathComponents", test_pathComponents),
            ("test_standardized", test_standardized),
            ("test_standardizingPath", test_standardizingPath),
            ("test_resolvingSymlinksInPath", test_resolvingSymlinksInPath),
        ]

        return tests
    }
}
