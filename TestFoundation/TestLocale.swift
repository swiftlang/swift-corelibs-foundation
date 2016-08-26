// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// RUN: rm -rf %t
// RUN: mkdir -p %t
//
// RUN: %target-clang %S/Inputs/FoundationBridge/FoundationBridge.m -c -o %t/FoundationBridgeObjC.o -g
// RUN: %target-build-swift %s -I %S/Inputs/FoundationBridge/ -Xlinker %t/FoundationBridgeObjC.o -o %t/TestLocale

// RUN: %target-run %t/TestLocale > %t.txt
// REQUIRES: executable_test
// REQUIRES: objc_interop

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#elseif DEPLOYMENT_RUNTIME_SWIFT
import SwiftFoundation
import SwiftXCTest
#endif

class TestLocale : XCTestCase {
    static var allTests: [(String, (TestLocale) -> () throws -> Void)] {
        return [
            ("test_bridgingAutoupdating", test_bridgingAutoupdating),
            ("test_equality", test_equality),
            ("test_localizedStringFunctions", test_localizedStringFunctions),
            ("test_properties", test_properties),
            ("test_AnyHashableContainingLocale", test_AnyHashableContainingLocale),
            ("test_AnyHashableCreatedFromNSLocale", test_AnyHashableCreatedFromNSLocale),
        ]
    }
    
    func test_bridgingAutoupdating() {
#if !DEPLOYMENT_RUNTIME_SWIFT
        let tester = LocaleBridgingTester()
        
        do {
            let loc = Locale.autoupdatingCurrent
            let result = tester.verifyAutoupdating(loc)
            XCTAssertTrue(result)
        }
        
        do {
            let loc = tester.autoupdatingCurrentLocale()
            let result = tester.verifyAutoupdating(loc)
            XCTAssertTrue(result)
        }
#endif
    }
    
    func test_equality() {
#if !DEPLOYMENT_RUNTIME_SWIFT // autoupdatingCurrent is not cross platform supported
        let autoupdating = Locale.autoupdatingCurrent
        let autoupdating2 = Locale.autoupdatingCurrent
        
        XCTAssertEqual(autoupdating, autoupdating2)
        let current = Locale.current
        XCTAssertNotEqual(autoupdating, current)
#endif
        let en = Locale(identifier: "en_US")
        let en2 = Locale(identifier: "en_US")
        let zh = Locale(identifier: "zh-Hant-HK")
        XCTAssertNotEqual(en, zh)
        XCTAssertEqual(en, en2)
    }
    
    func test_localizedStringFunctions() {
        let locale = Locale(identifier: "en")
        
        XCTAssertEqual("English", locale.localizedString(forIdentifier: "en"))
        XCTAssertEqual("France", locale.localizedString(forRegionCode: "fr"))
        XCTAssertEqual("Spanish", locale.localizedString(forLanguageCode: "es"))
        XCTAssertEqual("Simplified Han", locale.localizedString(forScriptCode: "Hans"))
        XCTAssertEqual("Computer", locale.localizedString(forVariantCode: "POSIX"))
        XCTAssertEqual("Buddhist Calendar", locale.localizedString(for: .buddhist))
        XCTAssertEqual("US Dollar", locale.localizedString(forCurrencyCode: "USD"))
        XCTAssertEqual("Phonebook Sort Order", locale.localizedString(forCollationIdentifier: "phonebook"))
        // Need to find a good test case for collator identifier
        // XCTAssertEqual("something", locale.localizedString(forCollatorIdentifier: "en"))
    }
    
    func test_properties() {
        let locale = Locale(identifier: "zh-Hant-HK")
        
        XCTAssertEqual("zh-Hant-HK", locale.identifier)
        XCTAssertEqual("zh", locale.languageCode)
        XCTAssertEqual("HK", locale.regionCode)
        XCTAssertEqual("Hant", locale.scriptCode)
        XCTAssertEqual("POSIX", Locale(identifier: "en_POSIX").variantCode)
        XCTAssertTrue(locale.exemplarCharacterSet != nil)
        // The calendar we get back from Locale has the locale set, but not the one we create with Calendar(identifier:). So we configure our comparison calendar first.
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "en_US")
        XCTAssertEqual(c, Locale(identifier: "en_US").calendar)
        XCTAssertEqual("「", locale.quotationBeginDelimiter)
        XCTAssertEqual("」", locale.quotationEndDelimiter)
        XCTAssertEqual("『", locale.alternateQuotationBeginDelimiter)
        XCTAssertEqual("』", locale.alternateQuotationEndDelimiter)
        XCTAssertEqual("phonebook", Locale(identifier: "en_US@collation=phonebook").collationIdentifier)
        XCTAssertEqual(".", locale.decimalSeparator)
        
        
        XCTAssertEqual(".", locale.decimalSeparator)
        XCTAssertEqual(",", locale.groupingSeparator)
        XCTAssertEqual("HK$", locale.currencySymbol)
        XCTAssertEqual("HKD", locale.currencyCode)
        
        XCTAssertTrue(Locale.availableIdentifiers.count > 0)
        XCTAssertTrue(Locale.isoLanguageCodes.count > 0)
        XCTAssertTrue(Locale.isoRegionCodes.count > 0)
        XCTAssertTrue(Locale.isoCurrencyCodes.count > 0)
        XCTAssertTrue(Locale.commonISOCurrencyCodes.count > 0)
#if !DEPLOYMENT_RUNTIME_SWIFT // this crashes due to CFAppPreferences not being setup correctly
        XCTAssertTrue(Locale.preferredLanguages.count > 0)
#endif
        
        // Need to find a good test case for collator identifier
        // XCTAssertEqual("something", locale.collatorIdentifier)
    }
    
    func test_AnyHashableContainingLocale() {
        let values: [Locale] = [
            Locale(identifier: "en"),
            Locale(identifier: "uk"),
            Locale(identifier: "uk"),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(Locale.self, type(of: anyHashables[0].base))
        XCTAssertSameType(Locale.self, type(of: anyHashables[1].base))
        XCTAssertSameType(Locale.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableCreatedFromNSLocale() {
        let values: [NSLocale] = [
            NSLocale(localeIdentifier: "en"),
            NSLocale(localeIdentifier: "uk"),
            NSLocale(localeIdentifier: "uk"),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(Locale.self, type(of: anyHashables[0].base))
        XCTAssertSameType(Locale.self, type(of: anyHashables[1].base))
        XCTAssertSameType(Locale.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}

