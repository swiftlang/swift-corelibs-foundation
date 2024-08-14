// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
        @testable import SwiftFoundation
    #else
        @testable import Foundation
    #endif
#endif

class TestProcessInfo : XCTestCase {
    
    func test_operatingSystemVersion() {
        let processInfo = ProcessInfo.processInfo
        let versionString = processInfo.operatingSystemVersionString
        XCTAssertFalse(versionString.isEmpty)

#if os(Linux)
        // Since the list of supported distros tends to change, at least check that it used os-release (if it's there).
        if let distroId = try? String(contentsOf: URL(fileURLWithPath: "/etc/os-release", isDirectory: false)),
           distroId.contains("PRETTY_NAME")
        {
            XCTAssertTrue(distroId.contains(versionString))
        } else {
            XCTAssertTrue(versionString.contains("Linux"))
        }
#elseif os(Windows)
        XCTAssertTrue(versionString.hasPrefix("Windows"))
#endif

        let version = processInfo.operatingSystemVersion
        XCTAssert(version.majorVersion != 0)

#if canImport(Darwin) || os(Linux) || os(Windows)
        let minVersion = OperatingSystemVersion(majorVersion: 1, minorVersion: 0, patchVersion: 0)
        XCTAssertTrue(processInfo.isOperatingSystemAtLeast(minVersion))
#endif
    }
    
    func test_processName() {
        let processInfo = ProcessInfo.processInfo
        let originalProcessName = processInfo.processName
        XCTAssertEqual(originalProcessName, "swift-corelibs-foundationPackageTests.xctest")
        
        // Try assigning a new process name.
        let newProcessName = "TestProcessName"
        processInfo.processName = newProcessName
        XCTAssertEqual(processInfo.processName, newProcessName)
        
        // Assign back to the original process name.
        processInfo.processName = originalProcessName
        XCTAssertEqual(processInfo.processName, originalProcessName)
    }
    
    func test_globallyUniqueString() {
        let uuid = ProcessInfo.processInfo.globallyUniqueString
        
        let parts = uuid.components(separatedBy: "-")
        XCTAssertEqual(parts.count, 7)
        XCTAssertEqual(parts[0].utf16.count, 8)
        XCTAssertEqual(parts[1].utf16.count, 4)
        XCTAssertEqual(parts[2].utf16.count, 4)
        XCTAssertEqual(parts[3].utf16.count, 4)
        XCTAssertEqual(parts[4].utf16.count, 12)
    }

    func test_environment() {
#if os(Windows)
        func setenv(_ key: String, _ value: String, _ overwrite: Int) -> Int32 {
          assert(overwrite == 1)
          guard !key.contains("=") else {
              errno = EINVAL
              return -1
          }
          return _putenv("\(key)=\(value)")
        }
#endif

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

#if os(Windows)
        // On Windows, adding an empty environment variable removes it from the environment
        XCTAssertNil(env["var1"])
#else
        XCTAssertEqual(env["var1"], "")
#endif
        XCTAssertEqual(env["var2"], "=")
        XCTAssertEqual(env["var3"], "=x")
        XCTAssertEqual(env["var4"], "x=")
        XCTAssertEqual(env["var5"], "=x=")
    }
}
