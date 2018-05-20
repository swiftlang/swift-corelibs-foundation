// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Dispatch

class TestHTTPCookieStorage: XCTestCase {

    enum _StorageType {
        case shared
        case groupContainer(String)
    }

    static var allTests: [(String, (TestHTTPCookieStorage) -> () throws -> Void)] {
        return [
            ("test_sharedCookieStorageAccessedFromMultipleThreads", test_sharedCookieStorageAccessedFromMultipleThreads),
            ("test_BasicStorageAndRetrieval", test_BasicStorageAndRetrieval),
            ("test_deleteCookie", test_deleteCookie),
            ("test_removeCookies", test_removeCookies),
            ("test_cookiesForURL", test_cookiesForURL),
            ("test_cookiesForURLWithMainDocumentURL", test_cookiesForURLWithMainDocumentURL),
            ("test_cookieInXDGSpecPath", test_cookieInXDGSpecPath),
            ("test_descriptionCookie", test_descriptionCookie),
        ]
    }

    override func setUp() {
        // Delete any cookies in the storage
        getStorage(for: .shared).removeCookies(since: Date(timeIntervalSince1970: 0))
        getStorage(for: .groupContainer("test")).removeCookies(since: Date(timeIntervalSince1970: 0))
    }

    func test_sharedCookieStorageAccessedFromMultipleThreads() {
        let q = DispatchQueue.global()
        let syncQ = DispatchQueue(label: "TestHTTPCookieStorage.syncQ")
        var allCookieStorages: [HTTPCookieStorage] = []
        let g = DispatchGroup()
        for _ in 0..<64 {
            g.enter()
            q.async {
                let mySharedCookieStore = HTTPCookieStorage.shared
                syncQ.async {
                    allCookieStorages.append(mySharedCookieStore)
                    g.leave()
                }
            }
        }
        g.wait()
        let cookieStorages = syncQ.sync { allCookieStorages }
        let mySharedCookieStore = HTTPCookieStorage.shared
        XCTAssertTrue(cookieStorages.reduce(true, { $0 && $1 === mySharedCookieStore }), "\(cookieStorages)")
    }

    func test_BasicStorageAndRetrieval() {
        basicStorageAndRetrieval(with: .shared)
        basicStorageAndRetrieval(with: .groupContainer("test"))
    }

    func test_deleteCookie() {
        deleteCookie(with: .shared)
        deleteCookie(with: .groupContainer("test"))
    }

    func test_removeCookies() {
        removeCookies(with: .shared)
        removeCookies(with: .groupContainer("test"))
    }

    func test_cookiesForURL() {
        setCookiesForURL(with: .shared)
        getCookiesForURL(with: .shared)

        setCookiesForURL(with: .groupContainer("test"))
        getCookiesForURL(with: .groupContainer("test"))
    }

    func test_cookiesForURLWithMainDocumentURL() {
        setCookiesForURLWithMainDocumentURL(with: .shared)
        setCookiesForURLWithMainDocumentURL(with: .groupContainer("test"))
    }

    func test_descriptionCookie() {
        descriptionCookie(with: .shared)
        descriptionCookie(with: .groupContainer("test"))
    }

    func getStorage(for type: _StorageType) -> HTTPCookieStorage {
        switch type {
        case .shared:
            return HTTPCookieStorage.shared
        case .groupContainer(let identifier):
            return HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: identifier)
        }
    }

    func basicStorageAndRetrieval(with storageType: _StorageType) {
        let storage = getStorage(for: storageType)

        let simpleCookie = HTTPCookie(properties: [
           .name: "TestCookie1",
           .value: "Test value @#$%^$&*99",
           .path: "/",
           .domain: "swift.org",
           .expires: Date(timeIntervalSince1970: 1475767775) //expired cookie
        ])!

        storage.setCookie(simpleCookie)
        XCTAssertEqual(storage.cookies!.count, 0)

        let simpleCookie0 = HTTPCookie(properties: [   //no expiry date
           .name: "TestCookie1",
           .value: "Test @#$%^$&*99",
           .path: "/",
           .domain: "swift.org",
        ])!

        storage.setCookie(simpleCookie0)
        XCTAssertEqual(storage.cookies!.count, 1)

        let simpleCookie1 = HTTPCookie(properties: [
           .name: "TestCookie1",
           .value: "Test @#$%^$&*99",
           .path: "/",
           .domain: "swift.org",
        ])!

        storage.setCookie(simpleCookie1)
        XCTAssertEqual(storage.cookies!.count, 1) //test for replacement

        let simpleCookie2 = HTTPCookie(properties: [
           .name: "TestCookie1",
           .value: "Test @#$%^$&*99",
           .path: "/",
           .domain: "example.com",
        ])!

        storage.setCookie(simpleCookie2)
        XCTAssertEqual(storage.cookies!.count, 2)
    }

    func deleteCookie(with storageType: _StorageType) {
        let storage = getStorage(for: storageType)

        let simpleCookie2 = HTTPCookie(properties: [
            .name: "TestCookie1",
            .value: "Test @#$%^$&*99",
            .path: "/",
            .domain: "example.com",
            ])!

        let simpleCookie = HTTPCookie(properties: [
            .name: "TestCookie1",
            .value: "Test value @#$%^$&*99",
            .path: "/",
            .domain: "swift.org",
            .expires: Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 1000)
            ])!
        storage.setCookie(simpleCookie)
        storage.setCookie(simpleCookie2)
        XCTAssertEqual(storage.cookies!.count, 2)

        storage.deleteCookie(simpleCookie)
        XCTAssertEqual(storage.cookies!.count, 1)
        storage.deleteCookie(simpleCookie2)
        XCTAssertEqual(storage.cookies!.count, 0)
    }

    func removeCookies(with storageType: _StorageType) {
        let storage = getStorage(for: storageType)
        let past = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate - 120)
        let future = Date(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate + 120)
        let simpleCookie = HTTPCookie(properties: [
            .name: "TestCookie1",
            .value: "Test value @#$%^$&*99",
            .path: "/",
            .domain: "swift.org",
            .expires: Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 1000)
            ])!
        storage.setCookie(simpleCookie)
        XCTAssertEqual(storage.cookies!.count, 1)
        storage.removeCookies(since: future)
        XCTAssertEqual(storage.cookies!.count, 1)
        storage.removeCookies(since: past)
        XCTAssertEqual(storage.cookies!.count, 0)
    }

    func setCookiesForURL(with storageType: _StorageType) {
        let storage = getStorage(for: storageType)
        let url = URL(string: "https://swift.org")
        let simpleCookie = HTTPCookie(properties: [
            .name: "TestCookie1",
            .value: "Test @#$%^$&*99",
            .path: "/",
            .domain: "example.com",
        ])!

        let simpleCookie1 = HTTPCookie(properties: [
            .name: "TestCookie1",
            .value: "Test value @#$%^$&*99",
            .path: "/",
            .domain: "swift.org",
            .expires: Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 1000)
        ])!

        storage.setCookies([simpleCookie, simpleCookie1], for: url, mainDocumentURL: nil)
        XCTAssertEqual(storage.cookies!.count, 1)
    }

    func getCookiesForURL(with storageType: _StorageType) {
        let storage = getStorage(for: storageType)
        let url = URL(string: "https://swift.org")
        XCTAssertEqual(storage.cookies(for: url!)!.count, 1)
    }

    func setCookiesForURLWithMainDocumentURL(with storageType: _StorageType) {
        let storage = getStorage(for: storageType)
        storage.cookieAcceptPolicy = .onlyFromMainDocumentDomain
        let url = URL(string: "https://swift.org/downloads")
        let mainUrl = URL(string: "http://ci.swift.org")
        let simpleCookie = HTTPCookie(properties: [
            .name: "TestCookie2",
            .value: "Test@#$%^$&*99khnia",
            .path: "/",
            .domain: "swift.org",
        ])!
        storage.setCookies([simpleCookie], for: url, mainDocumentURL: mainUrl)
        XCTAssertEqual(storage.cookies(for: url!)!.count, 1)

        let url1 = URL(string: "https://dt.swift.org/downloads")
        let simpleCookie1 = HTTPCookie(properties: [
            .name: "TestCookie3",
            .value: "Test@#$%^$&*999189",
            .path: "/",
            .domain: "swift.org",
        ])!
        storage.setCookies([simpleCookie1], for: url1, mainDocumentURL: mainUrl)
        XCTAssertEqual(storage.cookies(for: url1!)!.count, 0)
    }

    func descriptionCookie(with storageType: _StorageType) {
        let storage = getStorage(for: storageType)
        guard let cookies = storage.cookies else {
            XCTFail("No cookies")
            return
        }
        XCTAssertEqual(storage.description, "<NSHTTPCookieStorage cookies count:\(cookies.count)>")

        let simpleCookie = HTTPCookie(properties: [
            .name: "TestCookie1",
            .value: "Test value @#$%^$&*99",
            .path: "/",
            .domain: "swift.org",
            .expires: Date(timeIntervalSince1970: Date().timeIntervalSince1970 + 1000)
            ])!
        storage.setCookie(simpleCookie)
        guard let cookies0 = storage.cookies else {
            XCTFail("No cookies")
            return
        }
        XCTAssertEqual(storage.description, "<NSHTTPCookieStorage cookies count:\(cookies0.count)>")

        storage.deleteCookie(simpleCookie)
        guard let cookies1 = storage.cookies else {
            XCTFail("No cookies")
            return
        }
        XCTAssertEqual(storage.description, "<NSHTTPCookieStorage cookies count:\(cookies1.count)>")
    }

    func test_cookieInXDGSpecPath() {
#if !os(Android)
        //Test without setting the environment variable
        let testCookie = HTTPCookie(properties: [
           .name: "TestCookie0",
           .value: "Test @#$%^$&*99mam",
           .path: "/",
           .domain: "sample.com",
        ])!
        let storage = HTTPCookieStorage.shared
        storage.setCookie(testCookie)
        XCTAssertEqual(storage.cookies!.count, 1)
        let destPath: String
        let bundleName = "/" + testBundleName()
        if let xdg_data_home = getenv("XDG_DATA_HOME") {
            destPath = String(utf8String: xdg_data_home)! + bundleName + "/.cookies.shared"
        } else {
            destPath = NSHomeDirectory() + "/.local/share" + bundleName + "/.cookies.shared"
        }
        let fm = FileManager.default
        var isDir: ObjCBool = false
        let exists = fm.fileExists(atPath: destPath, isDirectory: &isDir)
        XCTAssertTrue(exists)

        // Test by setting the environmental variable
        let task = Process()
        task.executableURL = xdgTestHelperURL()
        var environment = ProcessInfo.processInfo.environment
        let testPath = NSHomeDirectory() + "/TestXDG"
        environment["XDG_DATA_HOME"] = testPath
        task.environment = environment

        // Launch the task
        task.launch()
        task.waitUntilExit()
        let status = task.terminationStatus
        XCTAssertEqual(status, 0)
        let terminationReason = task.terminationReason
        XCTAssertEqual(terminationReason, Process.TerminationReason.exit)
        try? fm.removeItem(atPath: testPath)
#endif
    }
}
