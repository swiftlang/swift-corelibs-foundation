// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestURLCache: XCTestCase {

    static var allTests: [(String, (TestURLCache) -> () throws -> Void)] {
        return [
            ("test_cacheFileAndDirectorySetup", test_cacheFileAndDirectorySetup),
        ]
    }

    private var cacheDirectoryPath: String {
        if let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.path {
            return "\(path)/org.swift.TestFoundation"
        } else {
            return "\(NSHomeDirectory())/Library/Caches/org.swift.TestFoundation"
        }
    }

    func test_cacheFileAndDirectorySetup() {
        // Test default directory
        let _ = URLCache.shared
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDirectoryPath))

        let fourMegaByte = 4 * 1024 * 1024
        let twentyMegaByte = 20 * 1024 * 1024

        // Test with a custom directory
        let newPath = cacheDirectoryPath + ".test_cacheFileAndDirectorySetup/"
        URLCache.shared = URLCache(memoryCapacity: fourMegaByte, diskCapacity: twentyMegaByte, diskPath: newPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: newPath))
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheDirectoryPath))
    }

}
