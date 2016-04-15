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
import CoreFoundation

class TestNSMassFormatter: XCTestCase {

    static var allTests: [(String, TestNSMassFormatter -> () throws -> Void)] {
        return [
            ("test_stringFromKilogramsLb", test_stringFromKilogramsLb),
            ("test_stringFromKilogramsOz", test_stringFromKilogramsOz),
            ("test_stringFromKilogramsLbLong", test_stringFromKilogramsLbLong),
            ("test_stringFromKilogramsOzLong", test_stringFromKilogramsOzLong),
            ("test_stringFromKilogramsLbShort", test_stringFromKilogramsLbShort),
            ("test_stringFromKilogramsOzShort", test_stringFromKilogramsOzShort),
        ]
    }

    func test_stringFromKilogramsLb() {
        let massFormatter = NSMassFormatter()
        let numForm = NSNumberFormatter()
        numForm.locale = NSLocale(localeIdentifier: "en_US")
        numForm.numberStyle = .DecimalStyle
        let formattedString = massFormatter.stringFromKilograms(75.0)
        XCTAssertEqual(formattedString, "165.347 lb")
    }
    
    func test_stringFromKilogramsOz() {
        let massFormatter = NSMassFormatter()
        let numForm = NSNumberFormatter()
        numForm.locale = NSLocale(localeIdentifier: "en_US")
        numForm.numberStyle = .DecimalStyle
        let formattedString = massFormatter.stringFromKilograms(0.01)
        XCTAssertEqual(formattedString, "0.35274 oz")
    }
    
    func test_stringFromKilogramsLbLong() {
        let massFormatter = NSMassFormatter()
        massFormatter.unitStyle = .Long
        let numForm = NSNumberFormatter()
        numForm.locale = NSLocale(localeIdentifier: "en_US")
        numForm.numberStyle = .DecimalStyle
        let formattedString = massFormatter.stringFromKilograms(80.0)
        XCTAssertEqual(formattedString, "176.37 pounds")
    }
    
    func test_stringFromKilogramsOzLong() {
        let massFormatter = NSMassFormatter()
        massFormatter.unitStyle = .Long
        let numForm = NSNumberFormatter()
        numForm.locale = NSLocale(localeIdentifier: "en_US")
        numForm.numberStyle = .DecimalStyle
        let formattedString = massFormatter.stringFromKilograms(0.5)
        XCTAssertEqual(formattedString, "1.10231 pounds")
    }
    
    func test_stringFromKilogramsLbShort() {
        let massFormatter = NSMassFormatter()
        massFormatter.unitStyle = .Short
        let numForm = NSNumberFormatter()
        numForm.locale = NSLocale(localeIdentifier: "en_US")
        numForm.numberStyle = .DecimalStyle
        let formattedString = massFormatter.stringFromKilograms(83.0)
        XCTAssertEqual(formattedString, "182.984#")
    }
    
    func test_stringFromKilogramsOzShort() {
        let massFormatter = NSMassFormatter()
        massFormatter.unitStyle = .Short
        let numForm = NSNumberFormatter()
        numForm.locale = NSLocale(localeIdentifier: "en_US")
        numForm.numberStyle = .DecimalStyle
        let formattedString = massFormatter.stringFromKilograms(0.69)
        XCTAssertEqual(formattedString, "1.52119#")
    }
    
}

