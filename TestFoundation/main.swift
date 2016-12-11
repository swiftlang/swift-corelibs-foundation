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

internal func testBundle() -> Bundle {
    return Bundle.main
}

// For the Swift version of the Foundation tests, we must manually list all test cases here.
XCTMain([
    testCase(TestNSAffineTransform.allTests),
    testCase(TestNSArray.allTests),
    testCase(TestNSBundle.allTests),
    testCase(TestByteCountFormatter.allTests),
    testCase(TestNSCalendar.allTests),
    testCase(TestNSCharacterSet.allTests),
    testCase(TestNSCompoundPredicate.allTests),
    testCase(TestNSData.allTests),
    testCase(TestNSDate.allTests),
    testCase(TestNSDateComponents.allTests),
    testCase(TestDateFormatter.allTests),
    testCase(TestNSDecimal.allTests),
    testCase(TestNSDictionary.allTests),
    testCase(TestNSFileManager.allTests),
    testCase(TestNSGeometry.allTests),
    testCase(TestHTTPCookie.allTests),
    testCase(TestNSIndexPath.allTests),
    testCase(TestNSIndexSet.allTests),
    testCase(TestJSONSerialization.allTests),
    testCase(TestNSKeyedArchiver.allTests),
    testCase(TestNSKeyedUnarchiver.allTests),
    testCase(TestNSLocale.allTests),
    testCase(TestNSNotificationCenter.allTests),
    testCase(TestNSNotificationQueue.allTests),
    testCase(TestNSNull.allTests),
    testCase(TestNSNumber.allTests),
    testCase(TestNumberFormatter.allTests),
    testCase(TestNSOperationQueue.allTests),
    testCase(TestNSOrderedSet.allTests),
    testCase(TestNSPipe.allTests),
    testCase(TestNSPredicate.allTests),
    testCase(TestNSProcessInfo.allTests),
    testCase(TestPropertyListSerialization.allTests),
    testCase(TestNSRange.allTests),
    testCase(TestNSRegularExpression.allTests),
    testCase(TestNSRunLoop.allTests),
    testCase(TestNSScanner.allTests),
    testCase(TestNSSet.allTests),
    testCase(TestNSStream.allTests),
    testCase(TestNSString.allTests),
//    testCase(TestNSThread.allTests),
    testCase(TestProcess.allTests),
    testCase(TestNSTextCheckingResult.allTests),
    testCase(TestNSTimer.allTests),
    testCase(TestNSTimeZone.allTests),
    testCase(TestNSURL.allTests),
    testCase(TestURLComponents.allTests),
    testCase(TestURLCredential.allTests),
    testCase(TestNSURLRequest.allTests),
    testCase(TestURLRequest.allTests),
    testCase(TestURLResponse.allTests),
    testCase(TestNSHTTPURLResponse.allTests),
    testCase(TestURLSession.allTests),
    testCase(TestNSNull.allTests),
    testCase(TestNSUUID.allTests),
    testCase(TestNSValue.allTests),
    testCase(TestNSUserDefaults.allTests),
    testCase(TestXMLParser.allTests),
    testCase(TestXMLDocument.allTests),
    testCase(TestNSAttributedString.allTests),
    testCase(TestNSMutableAttributedString.allTests),
    testCase(TestNSFileHandle.allTests),
    testCase(TestUnitConverter.allTests),
    testCase(TestProgressFraction.allTests),
    testCase(TestProgress.allTests),
    testCase(TestObjCRuntime.allTests),
    testCase(TestNotification.allTests),
])
