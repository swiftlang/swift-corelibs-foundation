// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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


class TestProcessInfo : XCTestCase {
    
    static var allTests: [(String, (TestProcessInfo) -> () throws -> Void)] {
        return [
            ("test_operatingSystemVersion", test_operatingSystemVersion ),
            ("test_processName", test_processName ),
            ("test_globallyUniqueString", test_globallyUniqueString ),
            ("test_environment", test_environment),
        ]
    }
    
    func test_operatingSystemVersion() {
        let processInfo = ProcessInfo.processInfo
        let versionString = processInfo.operatingSystemVersionString
        XCTAssertFalse(versionString.isEmpty)
        
        let version = processInfo.operatingSystemVersion
        XCTAssertNotNil(version.majorVersion != 0)
    }
    
    func test_processName() {
        // Assert that the original process name is "TestFoundation". This test
        // will fail if the test target ever gets renamed, so maybe it should
        // just test that the initial name is not empty or something?
#if DARWIN_COMPATIBILITY_TESTS
        let targetName = "xctest"
#else
        let targetName = "TestFoundation"
#endif
        let processInfo = ProcessInfo.processInfo
        let originalProcessName = processInfo.processName
        XCTAssertEqual(originalProcessName, targetName, "\"\(originalProcessName)\" not equal to \"TestFoundation\"")
        
        // Try assigning a new process name.
        let newProcessName = "TestProcessName"
        processInfo.processName = newProcessName
        XCTAssertEqual(processInfo.processName, newProcessName, "\"\(processInfo.processName)\" not equal to \"\(newProcessName)\"")
        
        // Assign back to the original process name.
        processInfo.processName = originalProcessName
        XCTAssertEqual(processInfo.processName, originalProcessName, "\"\(processInfo.processName)\" not equal to \"\(originalProcessName)\"")
    }
    
    func test_globallyUniqueString() {
        let uuid = ProcessInfo.processInfo.globallyUniqueString
        
        let parts = uuid.components(separatedBy: "-")
        XCTAssertEqual(parts.count, 5)
        XCTAssertEqual(parts[0].utf16.count, 8)
        XCTAssertEqual(parts[1].utf16.count, 4)
        XCTAssertEqual(parts[2].utf16.count, 4)
        XCTAssertEqual(parts[3].utf16.count, 4)
        XCTAssertEqual(parts[4].utf16.count, 12)
    }

    func test_environment() {
        let preset = ProcessInfo.processInfo.environment["test"]
        setenv("test", "worked", 1)
        let postset = ProcessInfo.processInfo.environment["test"]
        XCTAssertNil(preset)
        XCTAssertEqual(postset, "worked")

        // Bad values that wont be stored
        XCTAssertEqual(setenv("", "", 1), -1)
        XCTAssertEqual(setenv("bad1=", "", 1), -1)
        XCTAssertEqual(setenv("bad2=", "1", 1) ,-1)
        XCTAssertEqual(setenv("bad3=", "=2", 1), -1)

        // Good values that will be, check splitting on '='
        XCTAssertEqual(setenv("var1", "",1 ), 0)
        XCTAssertEqual(setenv("var2", "=", 1), 0)
        XCTAssertEqual(setenv("var3", "=x", 1), 0)
        XCTAssertEqual(setenv("var4", "x=", 1), 0)
        XCTAssertEqual(setenv("var5", "=x=", 1), 0)

        let env = ProcessInfo.processInfo.environment

        XCTAssertNil(env[""])
        XCTAssertNil(env["bad1"])
        XCTAssertNil(env["bad1="])
        XCTAssertNil(env["bad2"])
        XCTAssertNil(env["bad2="])
        XCTAssertNil(env["bad3"])
        XCTAssertNil(env["bad3="])

        XCTAssertEqual(env["var1"], "")
        XCTAssertEqual(env["var2"], "=")
        XCTAssertEqual(env["var3"], "=x")
        XCTAssertEqual(env["var4"], "x=")
        XCTAssertEqual(env["var5"], "=x=")
    }
}
