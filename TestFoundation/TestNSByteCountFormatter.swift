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



class TestNSByteCountFormatter : XCTestCase {
    
    static var allTests: [(String, (TestNSByteCountFormatter) -> () throws -> Void)] {
        return [
            ("test_DefaultValues", test_DefaultValues)
        ]
    }
    
    func test_DefaultValues() {
        let formatter = ByteCountFormatter()
        XCTAssertEqual(formatter.allowedUnits, ByteCountFormatter.Units.useDefault)
        XCTAssertEqual(formatter.countStyle, ByteCountFormatter.CountStyle.file)
        XCTAssertEqual(formatter.allowsNonnumericFormatting, true)
        XCTAssertEqual(formatter.includesUnit, true)
        XCTAssertEqual(formatter.includesCount, true)
        XCTAssertEqual(formatter.includesActualByteCount, false)
        XCTAssertEqual(formatter.isAdaptive, true)
        XCTAssertEqual(formatter.zeroPadsFractionDigits, false)
        XCTAssertEqual(formatter.formattingContext, Formatter.Context.unknown)
    }
}
