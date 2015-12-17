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
    import Glibc
#else
    import SwiftFoundation
    import SwiftXCTest
    import Darwin
#endif



class TestNSTimeZone: XCTestCase {

    var allTests : [(String, () -> Void)] {
        return [
            ("test_abbreviation", test_abbreviation),
            ("test_initializingTimeZoneWithOffset", test_initializingTimeZoneWithOffset),
            ("test_systemTimeZoneUsesSystemTime", test_systemTimeZoneUsesSystemTime),
        ]
    }

    func test_abbreviation() {
        let tz = NSTimeZone.systemTimeZone()
        XCTAssertEqual(tz.abbreviation, tz.abbreviationForDate(NSDate()))
    }
    
    func test_initializingTimeZoneWithOffset() {
        let tz = NSTimeZone(name: "GMT-0400")
        XCTAssertNotNil(tz)
        let seconds = tz?.secondsFromGMTForDate(NSDate())
        XCTAssertEqual(seconds, -14400)
    }
    
    func test_systemTimeZoneUsesSystemTime() {
        tzset();
        var t = time(nil)
        var lt = tm()
        localtime_r(&t, &lt)
        let zoneName = NSTimeZone.systemTimeZone().abbreviation ?? "Invalid Abbreviation"
        let expectedName = NSString(CString: lt.tm_zone, encoding: NSASCIIStringEncoding)?.bridge() ?? "Invalid Zone"
        XCTAssertEqual(zoneName, expectedName)
    }
}
