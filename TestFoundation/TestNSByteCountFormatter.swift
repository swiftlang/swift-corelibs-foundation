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



class TestNSByteCountFormatter : XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_DefaultValues", test_DefaultValues)
        ]
    }
    
    func test_DefaultValues() {
        let formatter = NSByteCountFormatter()
        XCTAssertEqual(formatter.allowedUnits, NSByteCountFormatterUnits.UseDefault)
        XCTAssertEqual(formatter.countStyle, NSByteCountFormatterCountStyle.File)
        XCTAssertEqual(formatter.allowsNonnumericFormatting, true)
        XCTAssertEqual(formatter.includesUnit, true)
        XCTAssertEqual(formatter.includesCount, true)
        XCTAssertEqual(formatter.includesActualByteCount, false)
        XCTAssertEqual(formatter.adaptive, true)
        XCTAssertEqual(formatter.zeroPadsFractionDigits, false)
        XCTAssertEqual(formatter.formattingContext, NSFormattingContext.Unknown)
    }
}
