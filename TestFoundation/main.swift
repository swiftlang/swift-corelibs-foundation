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

internal func testBundle() -> NSBundle {
    return NSBundle.mainBundle()
}

// For the Swift version of the Foundation tests, we must manually list all test cases here.
XCTMain([
    TestNSAffineTransform(),
    TestNSArray(),
    TestNSByteCountFormatter(),
    TestNSCalendar(),
    TestNSCharacterSet(),
    TestNSData(),
    TestNSDate(),
    TestNSDictionary(),
    TestNSFileManger(),
    TestNSGeometry(),
    TestNSHTTPCookie(),
    TestNSIndexSet(),
    TestNSJSONSerialization(),
    TestNSNotificationCenter(),
    TestNSNumber(),
    TestNSPipe(),
    TestNSPropertyList(),
    TestNSRange(),
    TestNSScanner(),
    TestNSSet(),
    TestNSString(),
    TestNSTimeZone(),
    TestNSURL(),
    TestNSURLRequest(),
    TestNSURLResponse(),
    TestNSUUID(),
    TestNSXMLParser(),
])
