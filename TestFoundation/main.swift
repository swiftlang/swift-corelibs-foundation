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

internal func XCTAssertSameType(_ expression1: @autoclosure () throws -> Any.Type, _ expression2: @autoclosure () throws -> Any.Type, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) {
    do {
        let lhs = try expression1()
        let rhs = try expression2()
        if lhs != rhs {
            let msg = message()
            fatalError("Expected \(lhs) == \(rhs) : \(msg) in \(file):\(line)")
        }
    } catch {
        let msg = message()
        fatalError("An error was thrown while evaluating type comparison: \(msg) in \(file):\(line)")
    }
}

// For the Swift version of the Foundation tests, we must manually list all test cases here.
XCTMain([
    testCase(TestNSAffineTransform.allTests),
    testCase(TestAffineTransform.allTests),
    testCase(TestNSArray.allTests),
    testCase(TestNSBundle.allTests),
    testCase(TestNSByteCountFormatter.allTests),
    testCase(TestNSCalendar.allTests),
    testCase(TestCalendar.allTests),
    testCase(TestNSCharacterSet.allTests),
    testCase(TestNSCompoundPredicate.allTests),
    testCase(TestNSData.allTests),
    testCase(TestData.allTests),
    testCase(TestNSDate.allTests),
    testCase(TestDate.allTests),
    testCase(TestNSDateComponents.allTests),
    testCase(TestDateInterval.allTests),
    testCase(TestNSDateFormatter.allTests),
    testCase(TestNSDictionary.allTests),
    testCase(TestNSFileManager.allTests),
    testCase(TestNSGeometry.allTests),
    testCase(TestNSHTTPCookie.allTests),
    testCase(TestNSIndexPath.allTests),
    testCase(TestIndexPath.allTests),
    testCase(TestNSIndexSet.allTests),
    testCase(TestNSJSONSerialization.allTests),
    testCase(TestNSKeyedArchiver.allTests),
    testCase(TestNSKeyedUnarchiver.allTests),
    testCase(TestNSLocale.allTests),
    testCase(TestNSNotificationCenter.allTests),
    testCase(TestNSNotificationQueue.allTests),
    testCase(TestNSNull.allTests),
    testCase(TestNSNumber.allTests),
    testCase(TestNSNumberFormatter.allTests),
    testCase(TestNSOperationQueue.allTests),
    testCase(TestNSOrderedSet.allTests),
    testCase(TestNSPipe.allTests),
    testCase(TestNSPredicate.allTests),
    testCase(TestNSProcessInfo.allTests),
    testCase(TestNSPropertyList.allTests),
    testCase(TestNSRange.allTests),
    testCase(TestNSRegularExpression.allTests),
    testCase(TestNSRunLoop.allTests),
    testCase(TestNSScanner.allTests),
    testCase(TestNSSet.allTests),
    testCase(TestNSStream.allTests),
    testCase(TestNSString.allTests),
//    testCase(TestNSThread.allTests),
    testCase(TestNSTask.allTests),
    testCase(TestNSTextCheckingResult.allTests),
    testCase(TestNSTimer.allTests),
    testCase(TestNSTimeZone.allTests),
    testCase(TestNSURL.allTests),
    testCase(TestNSURLComponents.allTests),
    testCase(TestNSURLCredential.allTests),
    testCase(TestNSURLRequest.allTests),
    testCase(TestURLRequest.allTests),
    testCase(TestNSURLResponse.allTests),
    testCase(TestNSHTTPURLResponse.allTests),
    testCase(TestURLSession.allTests),
    testCase(TestNSNull.allTests),
    testCase(TestNSUUID.allTests),
    testCase(TestNSValue.allTests),
    testCase(TestNSUserDefaults.allTests),
    testCase(TestNSXMLParser.allTests),
    testCase(TestNSXMLDocument.allTests),
    testCase(TestNSAttributedString.allTests),
    testCase(TestNSMutableAttributedString.allTests),
    testCase(TestNSFileHandle.allTests),
    testCase(TestUnitConverter.allTests),
    testCase(TestProgressFraction.allTests),
    testCase(TestProgress.allTests),
])
