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



class TestNSTimeZone: XCTestCase {

    var allTests : [(String, () throws -> Void)] {
        return [
            // Disabled see https://bugs.swift.org/browse/SR-300
            // ("test_abbreviation", test_abbreviation),
            ("test_initializingTimeZoneWithOffset", test_initializingTimeZoneWithOffset),
            // Also disabled due to https://bugs.swift.org/browse/SR-300
            // ("test_systemTimeZoneUsesSystemTime", test_systemTimeZoneUsesSystemTime),
        ]
    }

    func test_abbreviation() {
        let tz = NSTimeZone.systemTimeZone()
        let abbreviation1 = tz.abbreviation
        let abbreviation2 = tz.abbreviationForDate(NSDate())
        XCTAssertEqual(abbreviation1, abbreviation2, "\(abbreviation1) should be equal to \(abbreviation2)")
    }
    
    func test_initializingTimeZoneWithOffset() {
        let tz = NSTimeZone(name: "GMT-0400")
        XCTAssertNotNil(tz)
        let seconds = tz?.secondsFromGMTForDate(NSDate())
        XCTAssertEqual(seconds, -14400, "GMT-0400 should be -14400 seconds but got \(seconds) instead")
    }
    
    func test_systemTimeZoneUsesSystemTime() {
        tzset();
        var t = time(nil)
        var lt = tm()
        localtime_r(&t, &lt)
        let zoneName = NSTimeZone.systemTimeZone().abbreviation ?? "Invalid Abbreviation"
        let expectedName = NSString(CString: lt.tm_zone, encoding: NSASCIIStringEncoding)?.bridge() ?? "Invalid Zone"
        XCTAssertEqual(zoneName, expectedName, "expected name \"\(expectedName)\" is not equal to \"\(zoneName)\"")
    }
}
