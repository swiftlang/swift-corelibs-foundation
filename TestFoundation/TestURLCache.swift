// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestURLCache : XCTestCase {
    
    let aBit = 2 * 1024 /* 2 KB */
    let lots = 200 * 1024 * 1024 /* 200 MB */
    
    func testStorageRoundtrip() throws {
        let cache = try self.cache(memoryCapacity: lots, diskCapacity: lots)

        let (request, response) = try cachePair(for: "https://google.com/", ofSize: aBit, storagePolicy: .allowed)
        cache.storeCachedResponse(response, for: request)

        let storedResponse = cache.cachedResponse(for: request)
        XCTAssertEqual(response, storedResponse)
    }
    
    func testStoragePolicy() throws {
        do {
            let cache = try self.cache(memoryCapacity: lots, diskCapacity: lots)

            let (request, response) = try cachePair(for: "https://google.com/", ofSize: aBit, storagePolicy: .allowed)
            cache.storeCachedResponse(response, for: request)
            
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 1)
            XCTAssertNotNil(cache.cachedResponse(for: request))
        }
        
        try FileManager.default.removeItem(at: writableTestDirectoryURL)
        
        do {
            let cache = try self.cache(memoryCapacity: lots, diskCapacity: lots)
            
            let (request, response) = try cachePair(for: "https://google.com/", ofSize: aBit, storagePolicy: .allowedInMemoryOnly)
            cache.storeCachedResponse(response, for: request)
            
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 0)
            XCTAssertNotNil(cache.cachedResponse(for: request))
        }
        
        try FileManager.default.removeItem(at: writableTestDirectoryURL)
        
        do {
            let cache = try self.cache(memoryCapacity: lots, diskCapacity: lots)
            
            let (request, response) = try cachePair(for: "https://google.com/", ofSize: aBit, storagePolicy: .notAllowed)
            cache.storeCachedResponse(response, for: request)
            
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 0)
            XCTAssertNil(cache.cachedResponse(for: request))
        }
        
        try FileManager.default.removeItem(at: writableTestDirectoryURL)
    }
    
    func testNoDiskUsageIfDisabled() throws {
        let cache = try self.cache(memoryCapacity: lots, diskCapacity: 0)
        let (request, response) = try cachePair(for: "https://google.com/", ofSize: aBit)
        cache.storeCachedResponse(response, for: request)
        
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 0)
        XCTAssertNotNil(cache.cachedResponse(for: request))
    }
    
    func testShrinkingDiskCapacityEvictsItems() throws {
        let cache = try self.cache(memoryCapacity: lots, diskCapacity: lots)
        
        let urls = [ "https://apple.com/",
                     "https://google.com/",
                     "https://facebook.com/" ]
        
        for (request, response) in try urls.map({ try cachePair(for: $0, ofSize: aBit) }) {
            cache.storeCachedResponse(response, for: request)
        }
        
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 3)
        for url in urls {
            XCTAssertNotNil(cache.cachedResponse(for: URLRequest(url: URL(string: url)!)))
        }
        
        cache.diskCapacity = 0
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 0)
        for url in urls {
            XCTAssertNotNil(cache.cachedResponse(for: URLRequest(url: URL(string: url)!)))
        }
    }
    
    func testNoMemoryUsageIfDisabled() throws {
        let cache = try self.cache(memoryCapacity: 0, diskCapacity: lots)
        let (request, response) = try cachePair(for: "https://google.com/", ofSize: aBit)
        cache.storeCachedResponse(response, for: request)
        
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 1)
        XCTAssertNotNil(cache.cachedResponse(for: request))
        
        // Ensure that the fulfillment doesn't come from memory:
        try FileManager.default.removeItem(at: writableTestDirectoryURL)
        try FileManager.default.createDirectory(at: writableTestDirectoryURL, withIntermediateDirectories: true)
        
        XCTAssertNil(cache.cachedResponse(for: request))
    }
    
    func testShrinkingMemoryCapacityEvictsItems() throws {
        let cache = try self.cache(memoryCapacity: lots, diskCapacity: lots)
        
        let urls = [ "https://apple.com/",
                     "https://google.com/",
                     "https://facebook.com/" ]
        
        for (request, response) in try urls.map({ try cachePair(for: $0, ofSize: aBit) }) {
            cache.storeCachedResponse(response, for: request)
        }
        
        // Ensure these can be fulfilled from memory:
        try FileManager.default.removeItem(at: writableTestDirectoryURL)
        try FileManager.default.createDirectory(at: writableTestDirectoryURL, withIntermediateDirectories: true)

        for url in urls {
            XCTAssertNotNil(cache.cachedResponse(for: URLRequest(url: URL(string: url)!)))
        }
        
        // And evict all:
        cache.memoryCapacity = 0

        for url in urls {
            XCTAssertNil(cache.cachedResponse(for: URLRequest(url: URL(string: url)!)))
        }
    }
    
    func testRemovingOne() throws {
        let cache = try self.cache(memoryCapacity: lots, diskCapacity: lots)

        let urls = [ "https://apple.com/",
                     "https://google.com/",
                     "https://facebook.com/" ]
        
        for (request, response) in try urls.map({ try cachePair(for: $0, ofSize: aBit) }) {
            cache.storeCachedResponse(response, for: request)
        }

        let request = URLRequest(url: URL(string: urls[0])!)
        cache.removeCachedResponse(for: request)
        
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 2)
        
        var first = true
        for request in urls.map({ URLRequest(url: URL(string: $0)!) }) {
            if first {
                XCTAssertNil(cache.cachedResponse(for: request))
            } else {
                XCTAssertNotNil(cache.cachedResponse(for: request))
            }
            
            first = false
        }
    }
    
    func testRemovingAll() throws {
        let cache = try self.cache(memoryCapacity: lots, diskCapacity: lots)
        
        let urls = [ "https://apple.com/",
                     "https://google.com/",
                     "https://facebook.com/" ]
        
        for (request, response) in try urls.map({ try cachePair(for: $0, ofSize: aBit) }) {
            cache.storeCachedResponse(response, for: request)
        }
        
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 3)
        
        cache.removeAllCachedResponses()
        
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 0)
        
        for request in urls.map({ URLRequest(url: URL(string: $0)!) }) {
            XCTAssertNil(cache.cachedResponse(for: request))
        }
    }
    
    func testRemovingSince() throws {
        let cache = try self.cache(memoryCapacity: lots, diskCapacity: lots)
        
        let urls = [ "https://apple.com/",
                     "https://google.com/",
                     "https://facebook.com/" ]
        
        var first = true
        for (request, response) in try urls.map({ try cachePair(for: $0, ofSize: aBit) }) {
            cache.storeCachedResponse(response, for: request)
            if first {
                Thread.sleep(forTimeInterval: 5.0)
                first = false
            }
        }
        
        cache.removeCachedResponses(since: Date(timeIntervalSinceNow: -3.5))
        
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: writableTestDirectoryURL.path).count, 1)
        
        first = true
        for request in urls.map({ URLRequest(url: URL(string: $0)!) }) {
            if first {
                XCTAssertNotNil(cache.cachedResponse(for: request))
            } else {
                XCTAssertNil(cache.cachedResponse(for: request))
            }
            
            first = false
        }
    }
    
    // -----
    
    static var allTests: [(String, (TestURLCache) -> () throws -> Void)] {
        return [
            ("testStorageRoundtrip", testStorageRoundtrip),
            ("testStoragePolicy", testStoragePolicy),
            ("testNoDiskUsageIfDisabled", testNoDiskUsageIfDisabled),
            ("testShrinkingDiskCapacityEvictsItems", testShrinkingDiskCapacityEvictsItems),
            ("testNoMemoryUsageIfDisabled", testNoMemoryUsageIfDisabled),
            ("testShrinkingMemoryCapacityEvictsItems", testShrinkingMemoryCapacityEvictsItems),
            ("testRemovingOne", testRemovingOne),
            ("testRemovingAll", testRemovingAll),
            ("testRemovingSince", testRemovingSince),
        ]
    }
    
    // -----
    
    func cache(memoryCapacity: Int = 0, diskCapacity: Int = 0) throws -> URLCache {
        try FileManager.default.createDirectory(at: writableTestDirectoryURL, withIntermediateDirectories: true)
        return URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: writableTestDirectoryURL.path)
    }
    
    func cachePair(for urlString: String, ofSize size: Int, storagePolicy: URLCache.StoragePolicy = .allowed) throws -> (URLRequest, CachedURLResponse) {
        let url = try URL(string: urlString).unwrapped()
        let request = URLRequest(url: url)
        let response = try HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: [:]).unwrapped()
        return (request, CachedURLResponse(response: response, data: Data(count: size), storagePolicy: storagePolicy))
    }
    
    var writableTestDirectoryURL: URL!
    
    override func setUp() {
        super.setUp()
        
        let pid = ProcessInfo.processInfo.processIdentifier
        writableTestDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("org.swift.TestFoundation.TestURLCache.\(pid)")
    }
    
    override func tearDown() {
        if let directoryURL = writableTestDirectoryURL,
            (try? FileManager.default.attributesOfItem(atPath: directoryURL.path)) != nil {
            do {
                try FileManager.default.removeItem(at: directoryURL)
            } catch {
                NSLog("Could not remove test directory at URL \(directoryURL): \(error)")
            }
        }
        
        super.tearDown()
    }
    
}
