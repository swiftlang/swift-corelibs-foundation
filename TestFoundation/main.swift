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
    testCase(TestNSAffineTransform.allTests),
    testCase(TestNSArray.allTests),
    testCase(TestNSBundle.allTests),
    testCase(TestNSByteCountFormatter.allTests),
    testCase(TestNSCalendar.allTests),
    testCase(TestNSCharacterSet.allTests),
    testCase(TestNSData.allTests),
    testCase(TestNSDate.allTests),
    testCase(TestNSDateFormatter.allTests),
    testCase(TestNSDictionary.allTests),
    testCase(TestNSFileManger.allTests),
    testCase(TestNSGeometry.allTests),
    testCase(TestNSHTTPCookie.allTests),
    testCase(TestNSIndexPath.allTests),
    testCase(TestNSIndexSet.allTests),
    testCase(TestNSJSONSerialization.allTests),
    testCase(TestNSKeyedArchiver.allTests),
    testCase(TestNSKeyedUnarchiver.allTests),
    testCase(TestNSLocale.allTests),
    testCase(TestNSNotificationCenter.allTests),
    testCase(TestNSNull.allTests),
    testCase(TestNSNotificationQueue.allTests),
    testCase(TestNSNumber.allTests),
    testCase(TestNSNumberFormatter.allTests),
    testCase(TestNSPipe.allTests),
    testCase(TestNSProcessInfo.allTests),
    testCase(TestNSPropertyList.allTests),
    testCase(TestNSRange.allTests),
    testCase(TestNSRegularExpression.allTests),
    testCase(TestNSRunLoop.allTests),
    testCase(TestNSScanner.allTests),
    testCase(TestNSSet.allTests),
    testCase(TestNSOrderedSet.allTests),
    testCase(TestNSString.allTests),
//    testCase(TestNSTask.allTests),
//    testCase(TestNSThread.allTests),
    testCase(TestNSTimer.allTests),
    testCase(TestNSTimeZone.allTests),
    testCase(TestNSURL.allTests),
    testCase(TestNSURLComponents.allTests),
    testCase(TestNSURLCredential.allTests),
    testCase(TestNSURLRequest.allTests),
    testCase(TestNSURLResponse.allTests),
    testCase(TestNSNull.allTests),
    testCase(TestNSUUID.allTests),
    testCase(TestNSValue.allTests),
    testCase(TestNSUserDefaults.allTests),
    testCase(TestNSXMLParser.allTests),
    testCase(TestNSXMLDocument.allTests),
])
