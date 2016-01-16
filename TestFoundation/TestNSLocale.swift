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

class TestNSLocale : XCTestCase {
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_constants", test_constants),
        ]
    }
    
    func test_constants() {
        XCTAssertEqual(NSCurrentLocaleDidChangeNotification, "kCFLocaleCurrentLocaleDidChangeNotification",
                        "\(NSCurrentLocaleDidChangeNotification) is not equal to kCFLocaleCurrentLocaleDidChangeNotification")
        
        XCTAssertEqual(NSLocaleIdentifier, "kCFLocaleIdentifierKey",
                        "\(NSLocaleIdentifier) is not equal to kCFLocaleIdentifierKey")

        XCTAssertEqual(NSLocaleLanguageCode, "kCFLocaleLanguageCodeKey",
                        "\(NSLocaleLanguageCode) is not equal to kCFLocaleLanguageCodeKey")

        XCTAssertEqual(NSLocaleCountryCode, "kCFLocaleCountryCodeKey", 
                        "\(NSLocaleCountryCode) is not equal to kCFLocaleCountryCodeKey")

        XCTAssertEqual(NSLocaleScriptCode, "kCFLocaleScriptCodeKey",
                        "\(NSLocaleScriptCode) is not equal to kCFLocaleScriptCodeKey")

        XCTAssertEqual(NSLocaleVariantCode, "kCFLocaleVariantCodeKey", 
                        "\(NSLocaleVariantCode) is not equal to kCFLocaleVariantCodeKey")

        XCTAssertEqual(NSLocaleExemplarCharacterSet, "kCFLocaleExemplarCharacterSetKey",
                        "\(NSLocaleExemplarCharacterSet) is not equal to kCFLocaleExemplarCharacterSetKey")

        XCTAssertEqual(NSLocaleCalendar, "kCFLocaleCalendarKey",
                        "\(NSLocaleCalendar) is not equal to kCFLocaleCalendarKey")

        XCTAssertEqual(NSLocaleCollationIdentifier, "collation",
                        "\(NSLocaleCollationIdentifier) is not equal to collation")

        XCTAssertEqual(NSLocaleUsesMetricSystem, "kCFLocaleUsesMetricSystemKey",
                        "\(NSLocaleUsesMetricSystem) is not equal to kCFLocaleUsesMetricSystemKey")

        XCTAssertEqual(NSLocaleMeasurementSystem, "kCFLocaleMeasurementSystemKey",
                        "\(NSLocaleMeasurementSystem) is not equal to kCFLocaleMeasurementSystemKey")

        XCTAssertEqual(NSLocaleDecimalSeparator, "kCFLocaleDecimalSeparatorKey",
                        "\(NSLocaleDecimalSeparator) is not equal to kCFLocaleDecimalSeparatorKey")

        XCTAssertEqual(NSLocaleGroupingSeparator, "kCFLocaleGroupingSeparatorKey",
                        "\(NSLocaleGroupingSeparator) is not equal to kCFLocaleGroupingSeparatorKey")

        XCTAssertEqual(NSLocaleCurrencySymbol, "kCFLocaleCurrencySymbolKey",
                        "\(NSLocaleCurrencySymbol) is not equal to kCFLocaleCurrencySymbolKey")

        XCTAssertEqual(NSLocaleCurrencyCode, "currency",
                        "\(NSLocaleCurrencyCode) is not equal to currency")

        XCTAssertEqual(NSLocaleCollatorIdentifier, "kCFLocaleCollatorIdentifierKey",
                        "\(NSLocaleCollatorIdentifier) is not equal to kCFLocaleCollatorIdentifierKey")

        XCTAssertEqual(NSLocaleQuotationBeginDelimiterKey, "kCFLocaleQuotationBeginDelimiterKey",
                        "\(NSLocaleQuotationBeginDelimiterKey) is not equal to kCFLocaleQuotationBeginDelimiterKey")

        XCTAssertEqual(NSLocaleQuotationEndDelimiterKey, "kCFLocaleQuotationEndDelimiterKey",
                        "\(NSLocaleQuotationEndDelimiterKey) is not equal to kCFLocaleQuotationEndDelimiterKey")

        XCTAssertEqual(NSLocaleAlternateQuotationBeginDelimiterKey, "kCFLocaleAlternateQuotationBeginDelimiterKey",
                        "\(NSLocaleAlternateQuotationBeginDelimiterKey) is not equal to kCFLocaleAlternateQuotationBeginDelimiterKey")

        XCTAssertEqual(NSLocaleAlternateQuotationEndDelimiterKey, "kCFLocaleAlternateQuotationEndDelimiterKey",
                        "\(NSLocaleAlternateQuotationEndDelimiterKey) is not equal to kCFLocaleAlternateQuotationEndDelimiterKey")

    }

}
