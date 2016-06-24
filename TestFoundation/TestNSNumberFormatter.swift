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

class TestNSNumberFormatter: XCTestCase {

    static var allTests: [(String, (TestNSNumberFormatter) -> () throws -> Void)] {
        return [
            ("test_currencyCode", test_currencyCode),
            ("test_decimalSeparator", test_decimalSeparator),
            ("test_currencyDecimalSeparator", test_currencyDecimalSeparator),
            ("test_alwaysShowDecimalSeparator", test_alwaysShowDecimalSeparator),
            ("test_groupingSeparator", test_groupingSeparator),
            ("test_percentSymbol", test_percentSymbol),
            ("test_zeroSymbol", test_zeroSymbol),
            ("test_notANumberSymbol", test_notANumberSymbol),
            ("test_positiveInfinitySymbol", test_positiveInfinitySymbol),
            ("test_minusSignSymbol", test_minusSignSymbol),
            ("test_plusSignSymbol", test_plusSignSymbol),
            ("test_currencySymbol", test_currencySymbol),
            ("test_exponentSymbol", test_exponentSymbol),
            ("test_minimumIntegerDigits", test_minimumIntegerDigits),
            ("test_maximumIntegerDigits", test_maximumIntegerDigits),
            ("test_minimumFractionDigits", test_minimumFractionDigits),
            ("test_maximumFractionDigits", test_maximumFractionDigits),
            ("test_groupingSize", test_groupingSize),
            ("test_secondaryGroupingSize", test_secondaryGroupingSize),
            ("test_roundingMode", test_roundingMode),
            ("test_roundingIncrement", test_roundingIncrement),
            ("test_formatWidth", test_formatWidth),
            ("test_formatPosition", test_formatPosition),
            ("test_multiplier", test_multiplier),
            ("test_positivePrefix", test_positivePrefix),
            ("test_positiveSuffix", test_positiveSuffix),
            ("test_negativePrefix", test_negativePrefix),
            ("test_negativeSuffix", test_negativeSuffix),
            ("test_internationalCurrencySymbol", test_internationalCurrencySymbol),
            ("test_currencyGroupingSeparator", test_currencyGroupingSeparator),
            ("test_lenient", test_lenient),
            ("test_minimumSignificantDigits", test_minimumSignificantDigits),
            ("test_maximumSignificantDigits", test_maximumSignificantDigits)
        ]
    }
    
    func test_currencyCode() {
        // Disabled due to [SR-250]
        /*
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = .CurrencyStyle
        numberFormatter.currencyCode = "T"
        numberFormatter.currencyDecimalSeparator = "_"
        let formattedString = numberFormatter.stringFromNumber(42)
        XCTAssertEqual(formattedString, "T 42_00")
         */
    }
    
    func test_decimalSeparator() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimalStyle
        numberFormatter.decimalSeparator = "-"
        let formattedString = numberFormatter.string(from: 42.42)
        XCTAssertEqual(formattedString, "42-42")
    }
    
    func test_currencyDecimalSeparator() {
        // Disabled due to [SR-250]
        /*
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = .CurrencyStyle
        numberFormatter.currencyDecimalSeparator = "-"
        numberFormatter.currencyCode = "T"
        let formattedString = numberFormatter.stringFromNumber(42.42)
        XCTAssertEqual(formattedString, "T 42-42")
        */
    }
    
    func test_alwaysShowDecimalSeparator() {
        let numberFormatter = NumberFormatter()
        numberFormatter.decimalSeparator = "-"
        numberFormatter.alwaysShowsDecimalSeparator = true
        let formattedString = numberFormatter.string(from: 42)
        XCTAssertEqual(formattedString, "42-")
    }
    
    func test_groupingSeparator() {
        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.groupingSeparator = "_"
        let formattedString = numberFormatter.string(from: 42_000)
        XCTAssertEqual(formattedString, "42_000")
    }
    
    func test_percentSymbol() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percentStyle
        numberFormatter.percentSymbol = "💯"
        let formattedString = numberFormatter.string(from: 0.42)
        XCTAssertEqual(formattedString, "42💯")
    }
    
    func test_zeroSymbol() {
        let numberFormatter = NumberFormatter()
        numberFormatter.zeroSymbol = "⚽️"
        let formattedString = numberFormatter.string(from: 0)
        XCTAssertEqual(formattedString, "⚽️")
    }
    var unknownZero: Int = 0
    
    func test_notANumberSymbol() {
        let numberFormatter = NumberFormatter()
        numberFormatter.notANumberSymbol = "👽"
        let number: Double = -42
        let numberObject = NSNumber(value: sqrt(number))
        let formattedString = numberFormatter.string(from: numberObject)
        XCTAssertEqual(formattedString, "👽")
    }
    
    func test_positiveInfinitySymbol() {
        let numberFormatter = NumberFormatter()
        numberFormatter.positiveInfinitySymbol = "🚀"

        let numberObject = NSNumber(value: Double(42.0) / Double(0))
        let formattedString = numberFormatter.string(from: numberObject)
        XCTAssertEqual(formattedString, "🚀")
    }
    
    func test_minusSignSymbol() {
        let numberFormatter = NumberFormatter()
        numberFormatter.minusSign = "👎"
        let formattedString = numberFormatter.string(from: -42)
        XCTAssertEqual(formattedString, "👎42")
    }
    
    func test_plusSignSymbol() {
        //FIXME: How do we show the plus sign from a NSNumberFormatter?

//        let numberFormatter = NumberFormatter()
//        numberFormatter.plusSign = "👍"
//        let formattedString = numberFormatter.stringFromNumber(42)
//        XCTAssertEqual(formattedString, "👍42")
    }
    
    func test_currencySymbol() {
        // Disabled due to [SR-250]
        /*
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .CurrencyStyle
        numberFormatter.currencySymbol = "🍯"
        numberFormatter.currencyDecimalSeparator = "_"
        let formattedString = numberFormatter.stringFromNumber(42)
        XCTAssertEqual(formattedString, "🍯 42_00")
        */
    }
    
    func test_exponentSymbol() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .scientificStyle
        numberFormatter.exponentSymbol = "⬆️"
        let formattedString = numberFormatter.string(from: 42)
        XCTAssertEqual(formattedString, "4.2⬆️1")
    }
    
    func test_minimumIntegerDigits() {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumIntegerDigits = 3
        let formattedString = numberFormatter.string(from: 0)
        XCTAssertEqual(formattedString, "000")
    }
    
    func test_maximumIntegerDigits() {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumIntegerDigits = 3
        let formattedString = numberFormatter.string(from: 1_000)
        XCTAssertEqual(formattedString, "000")
    }
    
    func test_minimumFractionDigits() {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = 3
        numberFormatter.decimalSeparator = "-"
        let formattedString = numberFormatter.string(from: 42)
        XCTAssertEqual(formattedString, "42-000")
    }
    
    func test_maximumFractionDigits() {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 3
        numberFormatter.decimalSeparator = "-"
        let formattedString = numberFormatter.string(from: 42.4242)
        XCTAssertEqual(formattedString, "42-424")
    }
    
    func test_groupingSize() {
        let numberFormatter = NumberFormatter()
        numberFormatter.groupingSize = 4
        numberFormatter.groupingSeparator = "_"
        numberFormatter.usesGroupingSeparator = true
        let formattedString = numberFormatter.string(from: 42_000)
        XCTAssertEqual(formattedString, "4_2000")
    }
    
    func test_secondaryGroupingSize() {
        let numberFormatter = NumberFormatter()
        numberFormatter.secondaryGroupingSize = 2
        numberFormatter.groupingSeparator = "_"
        numberFormatter.usesGroupingSeparator = true
        let formattedString = numberFormatter.string(from: 42_000_000)
        XCTAssertEqual(formattedString, "4_20_00_000")
    }
    
    func test_roundingMode() {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.roundingMode = .roundCeiling
        let formattedString = numberFormatter.string(from: 41.0001)
        XCTAssertEqual(formattedString, "42")
    }
    
    func test_roundingIncrement() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimalStyle
        numberFormatter.roundingIncrement = 0.2
        let formattedString = numberFormatter.string(from: 4.25)
        XCTAssertEqual(formattedString, "4.2")
    }
    
    func test_formatWidth() {
        let numberFormatter = NumberFormatter()
        numberFormatter.paddingCharacter = "_"
        numberFormatter.formatWidth = 5
        let formattedString = numberFormatter.string(from: 42)
        XCTAssertEqual(formattedString, "___42")
    }
    
    func test_formatPosition() {
        let numberFormatter = NumberFormatter()
        numberFormatter.paddingCharacter = "_"
        numberFormatter.formatWidth = 5
        numberFormatter.paddingPosition = .afterPrefix
        let formattedString = numberFormatter.string(from: -42)
        XCTAssertEqual(formattedString, "-__42")
    }
    
    func test_multiplier() {
        let numberFormatter = NumberFormatter()
        numberFormatter.multiplier = 2
        let formattedString = numberFormatter.string(from: 21)
        XCTAssertEqual(formattedString, "42")
    }
    
    func test_positivePrefix() {
        let numberFormatter = NumberFormatter()
        numberFormatter.positivePrefix = "👍"
        let formattedString = numberFormatter.string(from: 42)
        XCTAssertEqual(formattedString, "👍42")
    }
    
    func test_positiveSuffix() {
        let numberFormatter = NumberFormatter()
        numberFormatter.positiveSuffix = "👍"
        let formattedString = numberFormatter.string(from: 42)
        XCTAssertEqual(formattedString, "42👍")
    }
    
    func test_negativePrefix() {
        let numberFormatter = NumberFormatter()
        numberFormatter.negativePrefix = "👎"
        let formattedString = numberFormatter.string(from: -42)
        XCTAssertEqual(formattedString, "👎42")
    }
    
    func test_negativeSuffix() {
        let numberFormatter = NumberFormatter()
        numberFormatter.negativeSuffix = "👎"
        let formattedString = numberFormatter.string(from: -42)
        XCTAssertEqual(formattedString, "-42👎")
    }
    
    func test_internationalCurrencySymbol() {
        // Disabled due to [SR-250]
        /*
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .CurrencyPluralStyle
        numberFormatter.internationalCurrencySymbol = "💵"
        numberFormatter.currencyDecimalSeparator = "_"
        let formattedString = numberFormatter.stringFromNumber(42)
        XCTAssertEqual(formattedString, "💵 42_00")
        */
    }
    
    func test_currencyGroupingSeparator() {
        // Disabled due to [SR-250]
        /*
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .CurrencyStyle
        numberFormatter.currencyGroupingSeparator = "_"
        numberFormatter.currencyCode = "T"
        numberFormatter.currencyDecimalSeparator = "/"
        let formattedString = numberFormatter.stringFromNumber(42_000)
        XCTAssertEqual(formattedString, "T 42_000/00")
        */
    }

    //FIXME: Something is wrong with numberFromString implementation, I don't know exactly why, but it's not working.
    func test_lenient() {
//        let numberFormatter = NumberFormatter()
//        numberFormatter.numberStyle = .CurrencyStyle
//        let nilNumberBeforeLenient = numberFormatter.numberFromString("42")
//        XCTAssertNil(nilNumberBeforeLenient)
//        numberFormatter.lenient = true
//        let numberAfterLenient = numberFormatter.numberFromString("42.42")
//        XCTAssertEqual(numberAfterLenient, 42.42)
    }
    
    func test_minimumSignificantDigits() {
        let numberFormatter = NumberFormatter()
        numberFormatter.usesSignificantDigits = true
        numberFormatter.minimumSignificantDigits = 3
        let formattedString = numberFormatter.string(from: 42)
        XCTAssertEqual(formattedString, "42.0")
    }
    
    func test_maximumSignificantDigits() {
        let numberFormatter = NumberFormatter()
        numberFormatter.usesSignificantDigits = true
        numberFormatter.maximumSignificantDigits = 3
        let formattedString = numberFormatter.string(from: 42.42424242)
        XCTAssertEqual(formattedString, "42.4")
    }
}

