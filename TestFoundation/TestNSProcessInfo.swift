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


class TestNSProcessInfo : XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_operatingSystemVersion", test_operatingSystemVersion ),
            ("test_processName", test_processName ),
            ("test_globallyUniqueString", test_globallyUniqueString ),
        ]
    }
    
    func test_operatingSystemVersion() {
        let processInfo = NSProcessInfo.processInfo()
        let versionString = processInfo.operatingSystemVersionString
        XCTAssertFalse(versionString.isEmpty)
        
        let version = processInfo.operatingSystemVersion
        XCTAssertNotNil(version.majorVersion != 0)
    }
    
    func test_processName() {
        // Assert that the original process name is "TestFoundation". This test
        // will fail if the test target ever gets renamed, so maybe it should
        // just test that the initial name is not empty or something?
        let processInfo = NSProcessInfo.processInfo()
        let targetName = "TestFoundation"
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
        let uuid = NSProcessInfo.processInfo().globallyUniqueString
        let parts = uuid.bridge().componentsSeparatedByString("-")
        XCTAssertEqual(parts.count, 5)
        XCTAssertEqual(parts[0].bridge().length, 8)
        XCTAssertEqual(parts[1].bridge().length, 4)
        XCTAssertEqual(parts[2].bridge().length, 4)
        XCTAssertEqual(parts[3].bridge().length, 4)
        XCTAssertEqual(parts[4].bridge().length, 12)
    }
    
}
