//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import CoreGraphics
import XCTest

// MARK: - Helper Functions
@available(macOS 10.11, iOS 9.0, watchOS 2.0, tvOS 9.0, *)
func makePersonNameComponents(namePrefix: String? = nil,
                              givenName: String? = nil,
                              middleName: String? = nil,
                              familyName: String? = nil,
                              nameSuffix: String? = nil,
                              nickname: String? = nil) -> PersonNameComponents {
    var result = PersonNameComponents()
    result.namePrefix = namePrefix
    result.givenName = givenName
    result.middleName = middleName
    result.familyName = familyName
    result.nameSuffix = nameSuffix
    result.nickname = nickname
    return result
}

func _debugDescription<T>(_ value: T) -> String {
    if let debugDescribable = value as? CustomDebugStringConvertible {
        return debugDescribable.debugDescription
    } else if let describable = value as? CustomStringConvertible {
        return describable.description
    } else {
        return "\(value)"
    }
}

func performEncodeAndDecode<T : Codable>(of value: T, encode: (T) throws -> Data, decode: (T.Type, Data) throws -> T, lineNumber: Int) -> T {

    let data: Data
    do {
        data = try encode(value)
    } catch {
        fatalError("\(#file):\(lineNumber): Unable to encode \(T.self) <\(_debugDescription(value))>: \(error)")
    }

    do {
        return try decode(T.self, data)
    } catch {
        fatalError("\(#file):\(lineNumber): Unable to decode \(T.self) <\(_debugDescription(value))>: \(error)")
    }
}

func expectRoundTripEquality<T : Codable>(of value: T, encode: (T) throws -> Data, decode: (T.Type, Data) throws -> T, lineNumber: Int) where T : Equatable {

    let decoded = performEncodeAndDecode(of: value, encode: encode, decode: decode, lineNumber: lineNumber)

    XCTAssertEqual(value, decoded, "\(#file):\(lineNumber): Decoded \(T.self) <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
}

func expectRoundTripEqualityThroughJSON<T : Codable>(for value: T, lineNumber: Int) where T : Equatable {
    let inf = "INF", negInf = "-INF", nan = "NaN"
    let encode = { (_ value: T) throws -> Data in
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: inf,
                                                                      negativeInfinity: negInf,
                                                                      nan: nan)
        return try encoder.encode(value)
    }

    let decode = { (_ type: T.Type, _ data: Data) throws -> T in
        let decoder = JSONDecoder()
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: inf,
                                                                        negativeInfinity: negInf,
                                                                        nan: nan)
        return try decoder.decode(type, from: data)
    }

    expectRoundTripEquality(of: value, encode: encode, decode: decode, lineNumber: lineNumber)
}

func expectRoundTripEqualityThroughPlist<T : Codable>(for value: T, lineNumber: Int) where T : Equatable {
    let encode = { (_ value: T) throws -> Data in
        return try PropertyListEncoder().encode(value)
    }

    let decode = { (_ type: T.Type,_ data: Data) throws -> T in
        return try PropertyListDecoder().decode(type, from: data)
    }

    expectRoundTripEquality(of: value, encode: encode, decode: decode, lineNumber: lineNumber)
}

// MARK: - Helper Types
// A wrapper around a UUID that will allow it to be encoded at the top level of an encoder.
struct UUIDCodingWrapper : Codable, Equatable {
    let value: UUID

    init(_ value: UUID) {
        self.value = value
    }

    static func ==(_ lhs: UUIDCodingWrapper, _ rhs: UUIDCodingWrapper) -> Bool {
        return lhs.value == rhs.value
    }
}

// MARK: - Tests
class TestCodable : XCTestCase {
    // MARK: - AffineTransform
#if os(macOS)
    lazy var affineTransformValues: [Int : AffineTransform] = [
        #line : AffineTransform.identity,
        #line : AffineTransform(),
        #line : AffineTransform(translationByX: 2.0, byY: 2.0),
        #line : AffineTransform(scale: 2.0),
        #line : AffineTransform(rotationByDegrees: .pi / 2),

        #line : AffineTransform(m11: 1.0, m12: 2.5, m21: 66.2, m22: 40.2, tX: -5.5, tY: 3.7),
        #line : AffineTransform(m11: -55.66, m12: 22.7, m21: 1.5, m22: 0.0, tX: -22, tY: -33),
        #line : AffineTransform(m11: 4.5, m12: 1.1, m21: 0.025, m22: 0.077, tX: -0.55, tY: 33.2),
        #line : AffineTransform(m11: 7.0, m12: -2.3, m21: 6.7, m22: 0.25, tX: 0.556, tY: 0.99),
        #line : AffineTransform(m11: 0.498, m12: -0.284, m21: -0.742, m22: 0.3248, tX: 12, tY: 44)
    ]

    func test_AffineTransform_JSON() {
        for (testLine, transform) in affineTransformValues {
            expectRoundTripEqualityThroughJSON(for: transform, lineNumber: testLine)
        }
    }

    func test_AffineTransform_Plist() {
        for (testLine, transform) in affineTransformValues {
            expectRoundTripEqualityThroughPlist(for: transform, lineNumber: testLine)
        }
    }
#endif

    // MARK: - Calendar
    lazy var calendarValues: [Int : Calendar] = [
        #line : Calendar(identifier: .gregorian),
        #line : Calendar(identifier: .buddhist),
        #line : Calendar(identifier: .chinese),
        #line : Calendar(identifier: .coptic),
        #line : Calendar(identifier: .ethiopicAmeteMihret),
        #line : Calendar(identifier: .ethiopicAmeteAlem),
        #line : Calendar(identifier: .hebrew),
        #line : Calendar(identifier: .iso8601),
        #line : Calendar(identifier: .indian),
        #line : Calendar(identifier: .islamic),
        #line : Calendar(identifier: .islamicCivil),
        #line : Calendar(identifier: .japanese),
        #line : Calendar(identifier: .persian),
        #line : Calendar(identifier: .republicOfChina),
    ]

    func test_Calendar_JSON() {
        for (testLine, calendar) in calendarValues {
            expectRoundTripEqualityThroughJSON(for: calendar, lineNumber: testLine)
        }
    }

    func test_Calendar_Plist() {
        for (testLine, calendar) in calendarValues {
            expectRoundTripEqualityThroughPlist(for: calendar, lineNumber: testLine)
        }
    }

    // MARK: - CharacterSet
    lazy var characterSetValues: [Int : CharacterSet] = [
        #line : CharacterSet.controlCharacters,
        #line : CharacterSet.whitespaces,
        #line : CharacterSet.whitespacesAndNewlines,
        #line : CharacterSet.decimalDigits,
        #line : CharacterSet.letters,
        #line : CharacterSet.lowercaseLetters,
        #line : CharacterSet.uppercaseLetters,
        #line : CharacterSet.nonBaseCharacters,
        #line : CharacterSet.alphanumerics,
        #line : CharacterSet.decomposables,
        #line : CharacterSet.illegalCharacters,
        #line : CharacterSet.punctuationCharacters,
        #line : CharacterSet.capitalizedLetters,
        #line : CharacterSet.symbols,
        #line : CharacterSet.newlines
    ]

    func test_CharacterSet_JSON() {
        for (testLine, characterSet) in characterSetValues {
            expectRoundTripEqualityThroughJSON(for: characterSet, lineNumber: testLine)
        }
    }

    func test_CharacterSet_Plist() {
        for (testLine, characterSet) in characterSetValues {
            expectRoundTripEqualityThroughPlist(for: characterSet, lineNumber: testLine)
        }
    }

    // MARK: - CGAffineTransform
    lazy var cg_affineTransformValues: [Int : CGAffineTransform] = {
        var values = [
            #line : CGAffineTransform.identity,
            #line : CGAffineTransform(),
            #line : CGAffineTransform(translationX: 2.0, y: 2.0),
            #line : CGAffineTransform(scaleX: 2.0, y: 2.0),
            #line : CGAffineTransform(a: 1.0, b: 2.5, c: 66.2, d: 40.2, tx: -5.5, ty: 3.7),
            #line : CGAffineTransform(a: -55.66, b: 22.7, c: 1.5, d: 0.0, tx: -22, ty: -33),
            #line : CGAffineTransform(a: 4.5, b: 1.1, c: 0.025, d: 0.077, tx: -0.55, ty: 33.2),
            #line : CGAffineTransform(a: 7.0, b: -2.3, c: 6.7, d: 0.25, tx: 0.556, ty: 0.99),
            #line : CGAffineTransform(a: 0.498, b: -0.284, c: -0.742, d: 0.3248, tx: 12, ty: 44)
        ]

        if #available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
            values[#line] = CGAffineTransform(rotationAngle: .pi / 2)
        }

        return values
    }()

    func test_CGAffineTransform_JSON() {
        for (testLine, transform) in cg_affineTransformValues {
            expectRoundTripEqualityThroughJSON(for: transform, lineNumber: testLine)
        }
    }

    func test_CGAffineTransform_Plist() {
        for (testLine, transform) in cg_affineTransformValues {
            expectRoundTripEqualityThroughPlist(for: transform, lineNumber: testLine)
        }
    }

    // MARK: - CGPoint
    lazy var cg_pointValues: [Int : CGPoint] = {
        var values = [
            #line : CGPoint.zero,
            #line : CGPoint(x: 10, y: 20)
        ]

        if #available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
            // Limit on magnitude in JSON. See rdar://problem/12717407
            values[#line] = CGPoint(x: CGFloat.greatestFiniteMagnitude,
                                    y: CGFloat.greatestFiniteMagnitude)
        }

        return values
    }()

    func test_CGPoint_JSON() {
        for (testLine, point) in cg_pointValues {
            expectRoundTripEqualityThroughJSON(for: point, lineNumber: testLine)
        }
    }

    func test_CGPoint_Plist() {
        for (testLine, point) in cg_pointValues {
            expectRoundTripEqualityThroughPlist(for: point, lineNumber: testLine)
        }
    }

    // MARK: - CGSize
    lazy var cg_sizeValues: [Int : CGSize] = {
        var values = [
            #line : CGSize.zero,
            #line : CGSize(width: 30, height: 40)
        ]

        if #available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
            // Limit on magnitude in JSON. See rdar://problem/12717407
            values[#line] = CGSize(width: CGFloat.greatestFiniteMagnitude,
                                   height: CGFloat.greatestFiniteMagnitude)
        }

        return values
    }()

    func test_CGSize_JSON() {
        for (testLine, size) in cg_sizeValues {
            expectRoundTripEqualityThroughJSON(for: size, lineNumber: testLine)
        }
    }

    func test_CGSize_Plist() {
        for (testLine, size) in cg_sizeValues {
            expectRoundTripEqualityThroughPlist(for: size, lineNumber: testLine)
        }
    }

    // MARK: - CGRect
    lazy var cg_rectValues: [Int : CGRect] = {
        var values = [
            #line : CGRect.zero,
            #line : CGRect.null,
            #line : CGRect(x: 10, y: 20, width: 30, height: 40)
        ]

        if #available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
            // Limit on magnitude in JSON. See rdar://problem/12717407
            values[#line] = CGRect.infinite
        }

        return values
    }()

    func test_CGRect_JSON() {
        for (testLine, rect) in cg_rectValues {
            expectRoundTripEqualityThroughJSON(for: rect, lineNumber: testLine)
        }
    }

    func test_CGRect_Plist() {
        for (testLine, rect) in cg_rectValues {
            expectRoundTripEqualityThroughPlist(for: rect, lineNumber: testLine)
        }
    }

    // MARK: - CGVector
    lazy var cg_vectorValues: [Int : CGVector] = {
        var values = [
            #line : CGVector.zero,
            #line : CGVector(dx: 0.0, dy: -9.81)
        ]

        if #available(macOS 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
            // Limit on magnitude in JSON. See rdar://problem/12717407
            values[#line] = CGVector(dx: CGFloat.greatestFiniteMagnitude,
                                     dy: CGFloat.greatestFiniteMagnitude)
        }

        return values
    }()

    func test_CGVector_JSON() {
        for (testLine, vector) in cg_vectorValues {
            expectRoundTripEqualityThroughJSON(for: vector, lineNumber: testLine)
        }
    }

    func test_CGVector_Plist() {
        for (testLine, vector) in cg_vectorValues {
            expectRoundTripEqualityThroughPlist(for: vector, lineNumber: testLine)
        }
    }

    // MARK: - ClosedRange
    func test_ClosedRange_JSON() {
        // NSJSONSerialization used to produce NSDecimalNumber values with different ranges, making Int.max as a bound lossy.
        if #available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *) {
            let value = 0...Int.max
            let decoded = performEncodeAndDecode(of: value, encode: { try JSONEncoder().encode($0) }, decode: { try JSONDecoder().decode($0, from: $1)  }, lineNumber: #line)
            XCTAssertEqual(value.upperBound, decoded.upperBound, "\(#file):\(#line): Decoded ClosedRange upperBound <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
            XCTAssertEqual(value.lowerBound, decoded.lowerBound, "\(#file):\(#line): Decoded ClosedRange lowerBound <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
        }
    }

    func test_ClosedRange_Plist() {
        let value = 0...Int.max
        let decoded = performEncodeAndDecode(of: value, encode: { try PropertyListEncoder().encode($0) }, decode: { try PropertyListDecoder().decode($0, from: $1)  }, lineNumber: #line)
        XCTAssertEqual(value.upperBound, decoded.upperBound, "\(#file):\(#line): Decoded ClosedRange upperBound <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
        XCTAssertEqual(value.lowerBound, decoded.lowerBound, "\(#file):\(#line): Decoded ClosedRange lowerBound <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
    }

    // MARK: - ContiguousArray
    lazy var contiguousArrayValues: [Int : ContiguousArray<String>] = [
        #line : [],
        #line : ["foo"],
        #line : ["foo", "bar"],
        #line : ["foo", "bar", "baz"],
    ]

    func test_ContiguousArray_JSON() {
        for (testLine, contiguousArray) in contiguousArrayValues {
            expectRoundTripEqualityThroughJSON(for: contiguousArray, lineNumber: testLine)
        }
    }

    func test_ContiguousArray_Plist() {
        for (testLine, contiguousArray) in contiguousArrayValues {
            expectRoundTripEqualityThroughPlist(for: contiguousArray, lineNumber: testLine)
        }
    }

    // MARK: - DateComponents
    lazy var dateComponents: Set<Calendar.Component> = [
        .era, .year, .month, .day, .hour, .minute, .second, .nanosecond,
        .weekday, .weekdayOrdinal, .quarter, .weekOfMonth, .weekOfYear,
        .yearForWeekOfYear, .timeZone, .calendar
    ]

    func test_DateComponents_JSON() {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(dateComponents, from: Date())
        expectRoundTripEqualityThroughJSON(for: components, lineNumber: #line - 1)
    }

    func test_DateComponents_Plist() {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(dateComponents, from: Date())
        expectRoundTripEqualityThroughPlist(for: components, lineNumber: #line - 1)
    }

    // MARK: - DateInterval
    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    lazy var dateIntervalValues: [Int : DateInterval] = [
        #line : DateInterval(),
        #line : DateInterval(start: Date.distantPast, end: Date()),
        #line : DateInterval(start: Date(), end: Date.distantFuture),
        #line : DateInterval(start: Date.distantPast, end: Date.distantFuture)
    ]

    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    func test_DateInterval_JSON() {
        for (testLine, interval) in dateIntervalValues {
            expectRoundTripEqualityThroughJSON(for: interval, lineNumber: testLine)
        }
    }

    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    func test_DateInterval_Plist() {
        for (testLine, interval) in dateIntervalValues {
            expectRoundTripEqualityThroughPlist(for: interval, lineNumber: testLine)
        }
    }

    // MARK: - Decimal
    lazy var decimalValues: [Int : Decimal] = [
        #line : Decimal.leastFiniteMagnitude,
        #line : Decimal.greatestFiniteMagnitude,
        #line : Decimal.leastNormalMagnitude,
        #line : Decimal.leastNonzeroMagnitude,
        #line : Decimal(),

        // See 33996620 for re-enabling this test.
        // #line : Decimal.pi,
    ]

    func test_Decimal_JSON() {
        for (testLine, decimal) in decimalValues {
            // Decimal encodes as a number in JSON and cannot be encoded at the top level.
            expectRoundTripEqualityThroughJSON(for: TopLevelWrapper(decimal), lineNumber: testLine)
        }
    }

    func test_Decimal_Plist() {
        for (testLine, decimal) in decimalValues {
            expectRoundTripEqualityThroughPlist(for: decimal, lineNumber: testLine)
        }
    }

    // MARK: - IndexPath
    lazy var indexPathValues: [Int : IndexPath] = [
        #line : IndexPath(), // empty
        #line : IndexPath(index: 0), // single
        #line : IndexPath(indexes: [1, 2]), // pair
        #line : IndexPath(indexes: [3, 4, 5, 6, 7, 8]), // array
    ]

    func test_IndexPath_JSON() {
        for (testLine, indexPath) in indexPathValues {
            expectRoundTripEqualityThroughJSON(for: indexPath, lineNumber: testLine)
        }
    }

    func test_IndexPath_Plist() {
        for (testLine, indexPath) in indexPathValues {
            expectRoundTripEqualityThroughPlist(for: indexPath, lineNumber: testLine)
        }
    }

    // MARK: - IndexSet
    lazy var indexSetValues: [Int : IndexSet] = [
        #line : IndexSet(),
        #line : IndexSet(integer: 42),
    ]
    lazy var indexSetMaxValues: [Int : IndexSet] = [
        #line : IndexSet(integersIn: 0 ..< Int.max)
    ]

    func test_IndexSet_JSON() {
        for (testLine, indexSet) in indexSetValues {
            expectRoundTripEqualityThroughJSON(for: indexSet, lineNumber: testLine)
        }
        if #available(macOS 10.10, iOS 8, *) {
            // Mac OS X 10.9 and iOS 7 weren't able to round-trip Int.max in JSON.
            for (testLine, indexSet) in indexSetMaxValues {
                expectRoundTripEqualityThroughJSON(for: indexSet, lineNumber: testLine)
            }
        }
    }

    func test_IndexSet_Plist() {
        for (testLine, indexSet) in indexSetValues {
            expectRoundTripEqualityThroughPlist(for: indexSet, lineNumber: testLine)
        }
        for (testLine, indexSet) in indexSetMaxValues {
            expectRoundTripEqualityThroughPlist(for: indexSet, lineNumber: testLine)
        }
    }

    // MARK: - Locale
    lazy var localeValues: [Int : Locale] = [
        #line : Locale(identifier: ""),
        #line : Locale(identifier: "en"),
        #line : Locale(identifier: "en_US"),
        #line : Locale(identifier: "en_US_POSIX"),
        #line : Locale(identifier: "uk"),
        #line : Locale(identifier: "fr_FR"),
        #line : Locale(identifier: "fr_BE"),
        #line : Locale(identifier: "zh-Hant-HK")
    ]

    func test_Locale_JSON() {
        for (testLine, locale) in localeValues {
            expectRoundTripEqualityThroughJSON(for: locale, lineNumber: testLine)
        }
    }

    func test_Locale_Plist() {
        for (testLine, locale) in localeValues {
            expectRoundTripEqualityThroughPlist(for: locale, lineNumber: testLine)
        }
    }

    // MARK: - Measurement
    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    lazy var unitValues: [Int : Dimension] = [
        #line : UnitAcceleration.metersPerSecondSquared,
        #line : UnitMass.kilograms,
        #line : UnitLength.miles
    ]

    #if false // FIXME: This test is broken; it was commented out in the original StdlibUnittest setup.
    // (The problem is that it uses encodes/decodes through `Measurement<Dimension>` which should not be a thing.)
    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    func test_Measurement_JSON() {
        for (testLine, unit) in unitValues {
            expectRoundTripEqualityThroughJSON(for: Measurement(value: 42, unit: unit), lineNumber: testLine)
        }
    }

    @available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
    func test_Measurement_Plist() {
        for (testLine, unit) in unitValues {
            expectRoundTripEqualityThroughJSON(for: Measurement(value: 42, unit: unit), lineNumber: testLine)
        }
    }
    #endif

    // MARK: - NSRange
    lazy var nsrangeValues: [Int : NSRange] = [
        #line : NSRange(),
        #line : NSRange(location: 5, length: 20),
    ]
    lazy var nsrangeMaxValues: [Int : NSRange] = [
        #line : NSRange(location: 0, length: Int.max),
        #line : NSRange(location: NSNotFound, length: 0),
    ]

    func test_NSRange_JSON() {
        for (testLine, range) in nsrangeValues {
            expectRoundTripEqualityThroughJSON(for: range, lineNumber: testLine)
        }
        if #available(macOS 10.10, iOS 8, *) {
            // Mac OS X 10.9 and iOS 7 weren't able to round-trip Int.max in JSON.
            for (testLine, range) in nsrangeMaxValues {
                expectRoundTripEqualityThroughJSON(for: range, lineNumber: testLine)
            }
        }
    }

    func test_NSRange_Plist() {
        for (testLine, range) in nsrangeValues {
            expectRoundTripEqualityThroughPlist(for: range, lineNumber: testLine)
        }
        for (testLine, range) in nsrangeMaxValues {
            expectRoundTripEqualityThroughPlist(for: range, lineNumber: testLine)
        }
    }

    // MARK: - PartialRangeFrom
    func test_PartialRangeFrom_JSON() {
        let value = 0...
        let decoded = performEncodeAndDecode(of: value, encode: { try JSONEncoder().encode($0) }, decode: { try JSONDecoder().decode($0, from: $1)  }, lineNumber: #line)
        XCTAssertEqual(value.lowerBound, decoded.lowerBound, "\(#file):\(#line): Decoded PartialRangeFrom <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
    }

    func test_PartialRangeFrom_Plist() {
        let value = 0...
        let decoded = performEncodeAndDecode(of: value, encode: { try PropertyListEncoder().encode($0) }, decode: { try PropertyListDecoder().decode($0, from: $1)  }, lineNumber: #line)
        XCTAssertEqual(value.lowerBound, decoded.lowerBound, "\(#file):\(#line): Decoded PartialRangeFrom <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
    }

    // MARK: - PartialRangeThrough
    func test_PartialRangeThrough_JSON() {
        // NSJSONSerialization used to produce NSDecimalNumber values with different ranges, making Int.max as a bound lossy.
        if #available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *) {

            let value = ...Int.max
            let decoded = performEncodeAndDecode(of: value, encode: { try JSONEncoder().encode($0) }, decode: { try JSONDecoder().decode($0, from: $1)  }, lineNumber: #line)
            XCTAssertEqual(value.upperBound, decoded.upperBound, "\(#file):\(#line): Decoded PartialRangeThrough <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
        }
    }

    func test_PartialRangeThrough_Plist() {
        let value = ...Int.max
        let decoded = performEncodeAndDecode(of: value, encode: { try PropertyListEncoder().encode($0) }, decode: { try PropertyListDecoder().decode($0, from: $1)  }, lineNumber: #line)
        XCTAssertEqual(value.upperBound, decoded.upperBound, "\(#file):\(#line): Decoded PartialRangeThrough <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
    }

    // MARK: - PartialRangeUpTo
    func test_PartialRangeUpTo_JSON() {
        // NSJSONSerialization used to produce NSDecimalNumber values with different ranges, making Int.max as a bound lossy.
        if #available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *) {

            let value = ..<Int.max
            let decoded = performEncodeAndDecode(of: value, encode: { try JSONEncoder().encode($0) }, decode: { try JSONDecoder().decode($0, from: $1)  }, lineNumber: #line)
            XCTAssertEqual(value.upperBound, decoded.upperBound, "\(#file):\(#line): Decoded PartialRangeUpTo <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
        }
    }

    func test_PartialRangeUpTo_Plist() {
        let value = ..<Int.max
        let decoded = performEncodeAndDecode(of: value, encode: { try PropertyListEncoder().encode($0) }, decode: { try PropertyListDecoder().decode($0, from: $1)  }, lineNumber: #line)
        XCTAssertEqual(value.upperBound, decoded.upperBound, "\(#file):\(#line): Decoded PartialRangeUpTo <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
    }

    // MARK: - PersonNameComponents
    @available(macOS 10.11, iOS 9.0, watchOS 2.0, tvOS 9.0, *)
    lazy var personNameComponentsValues: [Int : PersonNameComponents] = [
        #line : makePersonNameComponents(givenName: "John", familyName: "Appleseed"),
        #line : makePersonNameComponents(givenName: "John", familyName: "Appleseed", nickname: "Johnny"),
        #line : makePersonNameComponents(namePrefix: "Dr.", givenName: "Jane", middleName: "A.", familyName: "Appleseed", nameSuffix: "Esq.", nickname: "Janie")
    ]

    @available(macOS 10.11, iOS 9.0, watchOS 2.0, tvOS 9.0, *)
    func test_PersonNameComponents_JSON() {
        for (testLine, components) in personNameComponentsValues {
            expectRoundTripEqualityThroughJSON(for: components, lineNumber: testLine)
        }
    }

    @available(macOS 10.11, iOS 9.0, watchOS 2.0, tvOS 9.0, *)
    func test_PersonNameComponents_Plist() {
        for (testLine, components) in personNameComponentsValues {
            expectRoundTripEqualityThroughPlist(for: components, lineNumber: testLine)
        }
    }

    // MARK: - Range
    func test_Range_JSON() {
        // NSJSONSerialization used to produce NSDecimalNumber values with different ranges, making Int.max as a bound lossy.
        if #available(macOS 10.10, iOS 8.0, tvOS 9.0, watchOS 2.0, *) {
            let value = 0..<Int.max
            let decoded = performEncodeAndDecode(of: value, encode: { try JSONEncoder().encode($0) }, decode: { try JSONDecoder().decode($0, from: $1)  }, lineNumber: #line)
            XCTAssertEqual(value.upperBound, decoded.upperBound, "\(#file):\(#line): Decoded Range upperBound <\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
            XCTAssertEqual(value.lowerBound, decoded.lowerBound, "\(#file):\(#line): Decoded Range lowerBound<\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
        }
    }

    func test_Range_Plist() {
        let value = 0..<Int.max
        let decoded = performEncodeAndDecode(of: value, encode: { try PropertyListEncoder().encode($0) }, decode: { try PropertyListDecoder().decode($0, from: $1)  }, lineNumber: #line)
        XCTAssertEqual(value.upperBound, decoded.upperBound, "\(#file):\(#line): Decoded Range upperBound<\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
        XCTAssertEqual(value.lowerBound, decoded.lowerBound, "\(#file):\(#line): Decoded Range lowerBound<\(_debugDescription(decoded))> not equal to original <\(_debugDescription(value))>")
    }

    // MARK: - TimeZone
    lazy var timeZoneValues: [Int : TimeZone] = [
        #line : TimeZone(identifier: "America/Los_Angeles")!,
        #line : TimeZone(identifier: "UTC")!,
        #line : TimeZone.current
    ]

    func test_TimeZone_JSON() {
        for (testLine, timeZone) in timeZoneValues {
            expectRoundTripEqualityThroughJSON(for: timeZone, lineNumber: testLine)
        }
    }

    func test_TimeZone_Plist() {
        for (testLine, timeZone) in timeZoneValues {
            expectRoundTripEqualityThroughPlist(for: timeZone, lineNumber: testLine)
        }
    }

    // MARK: - URL
    lazy var urlValues: [Int : URL] = {
        var values: [Int : URL] = [
            #line : URL(fileURLWithPath: NSTemporaryDirectory()),
            #line : URL(fileURLWithPath: "/"),
            #line : URL(string: "http://swift.org")!,
            #line : URL(string: "documentation", relativeTo: URL(string: "http://swift.org")!)!
        ]

        if #available(macOS 10.11, iOS 9.0, watchOS 2.0, tvOS 9.0, *) {
            values[#line] = URL(fileURLWithPath: "bin/sh", relativeTo: URL(fileURLWithPath: "/"))
        }

        return values
    }()

    func test_URL_JSON() {
        for (testLine, url) in urlValues {
            // URLs encode as single strings in JSON. They lose their baseURL this way.
            // For relative URLs, we don't expect them to be equal to the original.
            if url.baseURL == nil {
                // This is an absolute URL; we can expect equality.
                expectRoundTripEqualityThroughJSON(for: TopLevelWrapper(url), lineNumber: testLine)
            } else {
                // This is a relative URL. Make it absolute first.
                let absoluteURL = URL(string: url.absoluteString)!
                expectRoundTripEqualityThroughJSON(for: TopLevelWrapper(absoluteURL), lineNumber: testLine)
            }
        }
    }

    func test_URL_Plist() {
        for (testLine, url) in urlValues {
            expectRoundTripEqualityThroughPlist(for: url, lineNumber: testLine)
        }
    }

    // MARK: - URLComponents
    lazy var urlComponentsValues: [Int : URLComponents] = [
        #line : URLComponents(),

        #line : URLComponents(string: "http://swift.org")!,
        #line : URLComponents(string: "http://swift.org:80")!,
        #line : URLComponents(string: "https://www.mywebsite.org/api/v42/something.php#param1=hi&param2=hello")!,
        #line : URLComponents(string: "ftp://johnny:apples@myftpserver.org:4242/some/path")!,

        #line : URLComponents(url: URL(string: "http://swift.org")!, resolvingAgainstBaseURL: false)!,
        #line : URLComponents(url: URL(string: "http://swift.org:80")!, resolvingAgainstBaseURL: false)!,
        #line : URLComponents(url: URL(string: "https://www.mywebsite.org/api/v42/something.php#param1=hi&param2=hello")!, resolvingAgainstBaseURL: false)!,
        #line : URLComponents(url: URL(string: "ftp://johnny:apples@myftpserver.org:4242/some/path")!, resolvingAgainstBaseURL: false)!,
        #line : URLComponents(url: URL(fileURLWithPath: NSTemporaryDirectory()), resolvingAgainstBaseURL: false)!,
        #line : URLComponents(url: URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)!,
        #line : URLComponents(url: URL(string: "documentation", relativeTo: URL(string: "http://swift.org")!)!, resolvingAgainstBaseURL: false)!,

        #line : URLComponents(url: URL(string: "http://swift.org")!, resolvingAgainstBaseURL: true)!,
        #line : URLComponents(url: URL(string: "http://swift.org:80")!, resolvingAgainstBaseURL: true)!,
        #line : URLComponents(url: URL(string: "https://www.mywebsite.org/api/v42/something.php#param1=hi&param2=hello")!, resolvingAgainstBaseURL: true)!,
        #line : URLComponents(url: URL(string: "ftp://johnny:apples@myftpserver.org:4242/some/path")!, resolvingAgainstBaseURL: true)!,
        #line : URLComponents(url: URL(fileURLWithPath: NSTemporaryDirectory()), resolvingAgainstBaseURL: true)!,
        #line : URLComponents(url: URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: true)!,
        #line : URLComponents(url: URL(string: "documentation", relativeTo: URL(string: "http://swift.org")!)!, resolvingAgainstBaseURL: true)!,

        #line : {
            var components = URLComponents()
            components.scheme = "https"
            return components
        }(),

        #line : {
            var components = URLComponents()
            components.user = "johnny"
            return components
        }(),

        #line : {
            var components = URLComponents()
            components.password = "apples"
            return components
        }(),

        #line : {
            var components = URLComponents()
            components.host = "0.0.0.0"
            return components
        }(),

        #line : {
            var components = URLComponents()
            components.port = 8080
            return components
        }(),

        #line : {
            var components = URLComponents()
            components.path = ".."
            return components
        }(),

        #line : {
            var components = URLComponents()
            components.query = "param1=hi&param2=there"
            return components
        }(),

        #line : {
            var components = URLComponents()
            components.fragment = "anchor"
            return components
        }(),

        #line : {
            var components = URLComponents()
            components.scheme = "ftp"
            components.user = "johnny"
            components.password = "apples"
            components.host = "0.0.0.0"
            components.port = 4242
            components.path = "/some/file"
            components.query = "utf8=✅"
            components.fragment = "anchor"
            return components
        }()
    ]

    func test_URLComponents_JSON() {
        for (testLine, components) in urlComponentsValues {
            expectRoundTripEqualityThroughJSON(for: components, lineNumber: testLine)
        }
    }

    func test_URLComponents_Plist() {
        for (testLine, components) in urlComponentsValues {
            expectRoundTripEqualityThroughPlist(for: components, lineNumber: testLine)
        }
    }

    // MARK: - UUID
    lazy var uuidValues: [Int : UUID] = [
        #line : UUID(),
        #line : UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!,
        #line : UUID(uuidString: "e621e1f8-c36c-495a-93fc-0c247a3e6e5f")!,
        #line : UUID(uuid: uuid_t(0xe6,0x21,0xe1,0xf8,0xc3,0x6c,0x49,0x5a,0x93,0xfc,0x0c,0x24,0x7a,0x3e,0x6e,0x5f))
    ]

    func test_UUID_JSON() {
        for (testLine, uuid) in uuidValues {
            // We have to wrap the UUID since we cannot have a top-level string.
            expectRoundTripEqualityThroughJSON(for: UUIDCodingWrapper(uuid), lineNumber: testLine)
        }
    }

    func test_UUID_Plist() {
        for (testLine, uuid) in uuidValues {
            // We have to wrap the UUID since we cannot have a top-level string.
            expectRoundTripEqualityThroughPlist(for: UUIDCodingWrapper(uuid), lineNumber: testLine)
        }
    }
}

// MARK: - Helper Types

private struct TopLevelWrapper<T> : Codable, Equatable where T : Codable, T : Equatable {
    let value: T

    init(_ value: T) {
        self.value = value
    }

    static func ==(_ lhs: TopLevelWrapper<T>, _ rhs: TopLevelWrapper<T>) -> Bool {
        return lhs.value == rhs.value
    }
}

