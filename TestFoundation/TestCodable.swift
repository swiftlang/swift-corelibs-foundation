// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
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

// MARK: - Helper Functions

private func makePersonNameComponents(namePrefix: String? = nil,
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

func expectRoundTripEquality<T : Codable>(of value: T,
                                          encode: (T) throws -> Data,
                                          decode: (Data) throws -> T) throws where T : Equatable  {
    do {
        let data = try encode(value)
        let decoded: T = try decode(data)
        if value != decoded {
            let errorMessage = "Decoded \(T.self) <\(decoded)> not equal to original <\(value)>"
            throw NSError(domain: "Decode mismatch", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
}

func expectRoundTripEqualityThroughJSON<T : Codable>(for value: T, lineNumber: UInt) where T : Equatable {
    do {
        let inf = "INF", negInf = "-INF", nan = "NaN"
        let encode = { (_ value: T) throws -> Data in
            let encoder = JSONEncoder()
            encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: inf,
                                                                          negativeInfinity: negInf,
                                                                          nan: nan)
            return try encoder.encode(value)
        }

        let decode = { (_ data: Data) throws -> T in
            let decoder = JSONDecoder()
            decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: inf,
                                                                            negativeInfinity: negInf,
                                                                            nan: nan)
            return try decoder.decode(T.self, from: data)
        }

        try expectRoundTripEquality(of: value, encode: encode, decode: decode)
    } catch {
        XCTFail("\(error)", line: lineNumber)
    }
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

    // MARK: - PersonNameComponents
    lazy var personNameComponentsValues: [UInt : PersonNameComponents] = [
        #line : makePersonNameComponents(givenName: "John", familyName: "Appleseed"),
        #line : makePersonNameComponents(givenName: "John", familyName: "Appleseed", nickname: "Johnny"),
        #line : makePersonNameComponents(namePrefix: "Dr.",
                                         givenName: "Jane",
                                         middleName: "A.",
                                         familyName: "Appleseed",
                                         nameSuffix: "Esq.",
                                         nickname: "Janie")
    ]

    func test_PersonNameComponents_JSON() {
        for (testLine, components) in personNameComponentsValues {
            expectRoundTripEqualityThroughJSON(for: components, lineNumber: testLine)
        }
    }

    // MARK: - UUID
    lazy var uuidValues: [UInt : UUID] = [
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

    // MARK: - URL
    lazy var urlValues: [UInt : URL] = [
        #line : URL(fileURLWithPath: NSTemporaryDirectory()),
        #line : URL(fileURLWithPath: "/"),
        #line : URL(string: "http://apple.com")!,
        #line : URL(string: "swift", relativeTo: URL(string: "http://apple.com")!)!,
        #line : URL(fileURLWithPath: "bin/sh", relativeTo: URL(fileURLWithPath: "/"))
    ]

    func test_URL_JSON() {
        for (testLine, url) in urlValues {
            expectRoundTripEqualityThroughJSON(for: url, lineNumber: testLine)
        }
    }

    // MARK: - NSRange
    lazy var nsrangeValues: [UInt : NSRange] = [
        #line : NSRange(),
        #line : NSRange(location: 0, length: Int.max),
        #line : NSRange(location: NSNotFound, length: 0)
    ]

    func test_NSRange_JSON() {
        for (testLine, range) in nsrangeValues {
            expectRoundTripEqualityThroughJSON(for: range, lineNumber: testLine)
        }
    }

    // MARK: - Locale
    lazy var localeValues: [UInt : Locale] = [
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

    // MARK: - IndexSet
    lazy var indexSetValues: [UInt : IndexSet] = [
        #line : IndexSet(),
        #line : IndexSet(integer: 42),
        #line : IndexSet(integersIn: 0 ..< Int.max)
    ]

    func test_IndexSet_JSON() {
        for (testLine, indexSet) in indexSetValues {
            expectRoundTripEqualityThroughJSON(for: indexSet, lineNumber: testLine)
        }
    }

    // MARK: - IndexPath
    lazy var indexPathValues: [UInt : IndexPath] = [
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

    // MARK: - AffineTransform
    lazy var affineTransformValues: [UInt : AffineTransform] = [
        #line : AffineTransform.identity,
        #line : AffineTransform(),
        #line : AffineTransform(translationByX: 2.0, byY: 2.0),
        #line : AffineTransform(scale: 2.0),

        // Disabled due to a bug: JSONSerialization loses precision for m12 and m21
        // 0.02741213359204429 is serialized to 0.0274121335920443
        //        AffineTransform(rotationByDegrees: .pi / 2),

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

    // MARK: - Decimal
    lazy var decimalValues: [UInt : Decimal] = [
        #line : Decimal.leastFiniteMagnitude,
        #line : Decimal.greatestFiniteMagnitude,
        #line : Decimal.leastNormalMagnitude,
        #line : Decimal.leastNonzeroMagnitude,
        #line : Decimal.pi,
        #line : Decimal()
    ]

    func test_Decimal_JSON() {
        for (testLine, decimal) in decimalValues {
            expectRoundTripEqualityThroughJSON(for: decimal, lineNumber: testLine)
        }
    }
    
    // MARK: - CGPoint
    lazy var cgpointValues: [UInt : CGPoint] = [
        #line : CGPoint(),
        #line : CGPoint.zero,
        #line : CGPoint(x: 10, y: 20),
        #line : CGPoint(x: -10, y: -20),
        // Disabled due to limit on magnitude in JSON. See SR-5346
        // CGPoint(x: .greatestFiniteMagnitude, y: .greatestFiniteMagnitude),
    ]
    
    func test_CGPoint_JSON() {
        for (testLine, point) in cgpointValues {
            expectRoundTripEqualityThroughJSON(for: point, lineNumber: testLine)
        }
    }
    
    // MARK: - CGSize
    lazy var cgsizeValues: [UInt : CGSize] = [
        #line : CGSize(),
        #line : CGSize.zero,
        #line : CGSize(width: 30, height: 40),
        #line : CGSize(width: -30, height: -40),
        // Disabled due to limit on magnitude in JSON. See SR-5346
        // CGSize(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
    ]
    
    func test_CGSize_JSON() {
        for (testLine, size) in cgsizeValues {
            expectRoundTripEqualityThroughJSON(for: size, lineNumber: testLine)
        }
    }
    
    // MARK: - CGRect
    lazy var cgrectValues: [UInt : CGRect] = [
        #line : CGRect(),
        #line : CGRect.zero,
        #line : CGRect(origin: CGPoint(x: 10, y: 20), size: CGSize(width: 30, height: 40)),
        #line : CGRect(origin: CGPoint(x: -10, y: -20), size: CGSize(width: -30, height: -40)),
        #line : CGRect.null,
        // Disabled due to limit on magnitude in JSON. See SR-5346
        // CGRect.infinite
    ]
    
    func test_CGRect_JSON() {
        for (testLine, rect) in cgrectValues {
            expectRoundTripEqualityThroughJSON(for: rect, lineNumber: testLine)
        }
    }
    
    // MARK: - CharacterSet
    lazy var characterSetValues: [UInt : CharacterSet] = [
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
        #line : CharacterSet.newlines,
        #line : CharacterSet(charactersIn: "abcd")
    ]
    
    func test_CharacterSet_JSON() {
        for (testLine, characterSet) in characterSetValues {
            expectRoundTripEqualityThroughJSON(for: characterSet, lineNumber: testLine)
        }
    }

    // MARK: - TimeZone
    lazy var timeZoneValues: [UInt : TimeZone] = {
        #if !os(Android)
            var values: [UInt : TimeZone] = [
                #line : TimeZone(identifier: "America/Los_Angeles")!,
                #line : TimeZone(identifier: "UTC")!
            ]

            #if !os(Linux)
                // Disabled due to [SR-5598] bug, which occurs on Linux, and breaks
                // TimeZone.current == TimeZone(identifier: TimeZone.current.identifier) equality,
                // causing encode -> decode -> compare test to fail.
                values[#line] = TimeZone.current
            #endif
        #else
            var values: [UInt : TimeZone] = [
                #line : TimeZone(identifier: "UTC")!,
                #line : TimeZone.current
            ]
        #endif
        return values
    }()

    func test_TimeZone_JSON() {
        for (testLine, timeZone) in timeZoneValues {
            expectRoundTripEqualityThroughJSON(for: timeZone, lineNumber: testLine)
        }
    }

    // MARK: - Calendar
    lazy var calendarValues: [UInt : Calendar] = {
        var values: [UInt : Calendar] = [
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
            #line : Calendar(identifier: .republicOfChina)
        ]

        #if os(Linux)
            // Custom timeZone set to work around [SR-5598] bug, which occurs on Linux, and breaks equality after
            // serializing and deserializing TimeZone.current
            values = values.mapValues { calendar in
                var copy = calendar
                copy.timeZone = TimeZone(identifier: "UTC")!
                return copy
            }
        #endif

        return values
    }()

    func test_Calendar_JSON() {
        for (testLine, calendar) in calendarValues {
            expectRoundTripEqualityThroughJSON(for: calendar, lineNumber: testLine)
        }
    }

    // MARK: - DateComponents
    lazy var dateComponents: Set<Calendar.Component> = [
        .era,
        .year,
        .month,
        .day,
        .hour,
        .minute,
        .second,
        .weekday,
        .weekdayOrdinal,
        .weekOfMonth,
        .weekOfYear,
        .yearForWeekOfYear,
        .timeZone,
        .calendar,
        // [SR-5576] Disabled due to a bug in Calendar.dateComponents(_:from:) which crashes on Darwin and returns
        // invalid values on Linux if components include .nanosecond or .quarter.
        // .nanosecond,
        // .quarter,
    ]

    func test_DateComponents_JSON() {
        #if os(Linux)
            var calendar = Calendar(identifier: .gregorian)
            // Custom timeZone set to work around [SR-5598] bug, which occurs on Linux, and breaks equality after
            // serializing and deserializing TimeZone.current
            calendar.timeZone = TimeZone(identifier: "UTC")!
        #else
            let calendar = Calendar(identifier: .gregorian)
        #endif

        let components = calendar.dateComponents(dateComponents, from: Date(timeIntervalSince1970: 1501283776))
        expectRoundTripEqualityThroughJSON(for: components, lineNumber: #line)
    }

    // MARK: - Measurement
    func test_Measurement_JSON() {
        expectRoundTripEqualityThroughJSON(for: Measurement(value: 42, unit: UnitAcceleration.metersPerSecondSquared),
                                           lineNumber: #line)
        expectRoundTripEqualityThroughJSON(for: Measurement(value: 42, unit: UnitMass.kilograms), lineNumber: #line)
        expectRoundTripEqualityThroughJSON(for: Measurement(value: 42, unit: UnitLength.miles), lineNumber: #line)
    }
    
    // MARK: - URLComponents
    lazy var urlComponentsValues: [UInt : URLComponents] = [
        #line : URLComponents(),
        
        #line : URLComponents(string: "http://swift.org")!,
        #line : URLComponents(string: "http://swift.org:80")!,
        #line : URLComponents(string: "https://www.mywebsite.org/api/v42/something.php#param1=hi&param2=hello")!,
        #line : URLComponents(string: "ftp://johnny:apples@myftpserver.org:4242/some/path")!,
        
        #line : URLComponents(url: URL(string: "http://swift.org")!, resolvingAgainstBaseURL: false)!,
        #line : URLComponents(url: URL(string: "http://swift.org:80")!, resolvingAgainstBaseURL: false)!,
        #line : {
            let url = URL(string: "https://www.mywebsite.org/api/v42/something.php#param1=hi&param2=hello")!
            return URLComponents(url: url, resolvingAgainstBaseURL: false)!
        }(),
        #line : {
            let url = URL(string: "ftp://johnny:apples@myftpserver.org:4242/some/path")!
            return URLComponents(url: url, resolvingAgainstBaseURL: false)!
        }(),
        #line : URLComponents(url: URL(fileURLWithPath: NSTemporaryDirectory()), resolvingAgainstBaseURL: false)!,
        #line : URLComponents(url: URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: false)!,
        #line : {
            let url = URL(string: "documentation", relativeTo: URL(string: "http://swift.org")!)!
            return URLComponents(url: url, resolvingAgainstBaseURL: false)!
        }(),

        #line : URLComponents(url: URL(string: "http://swift.org")!, resolvingAgainstBaseURL: true)!,
        #line : URLComponents(url: URL(string: "http://swift.org:80")!, resolvingAgainstBaseURL: true)!,
        #line : {
            let url = URL(string: "https://www.mywebsite.org/api/v42/something.php#param1=hi&param2=hello")!
            return URLComponents(url: url, resolvingAgainstBaseURL: true)!
        }(),
        #line : {
            let url = URL(string: "ftp://johnny:apples@myftpserver.org:4242/some/path")!
            return URLComponents(url: url, resolvingAgainstBaseURL: true)!
        }(),
        #line : URLComponents(url: URL(fileURLWithPath: NSTemporaryDirectory()), resolvingAgainstBaseURL: true)!,
        #line : URLComponents(url: URL(fileURLWithPath: "/"), resolvingAgainstBaseURL: true)!,
        #line : {
            let url = URL(string: "documentation", relativeTo: URL(string: "http://swift.org")!)!
            return URLComponents(url: url, resolvingAgainstBaseURL: true)!
        }(),

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
}

extension TestCodable {
    static var allTests: [(String, (TestCodable) -> () throws -> Void)] {
        return [
            ("test_PersonNameComponents_JSON", test_PersonNameComponents_JSON),
            ("test_UUID_JSON", test_UUID_JSON),
            ("test_URL_JSON", test_URL_JSON),
            ("test_NSRange_JSON", test_NSRange_JSON),
            ("test_Locale_JSON", test_Locale_JSON),
            ("test_IndexSet_JSON", test_IndexSet_JSON),
            ("test_IndexPath_JSON", test_IndexPath_JSON),
            ("test_AffineTransform_JSON", test_AffineTransform_JSON),
            ("test_Decimal_JSON", test_Decimal_JSON),
            ("test_CGPoint_JSON", test_CGPoint_JSON),
            ("test_CGSize_JSON", test_CGSize_JSON),
            ("test_CGRect_JSON", test_CGRect_JSON),
            ("test_CharacterSet_JSON", test_CharacterSet_JSON),
            ("test_TimeZone_JSON", test_TimeZone_JSON),
            ("test_Calendar_JSON", test_Calendar_JSON),
            ("test_DateComponents_JSON", test_DateComponents_JSON),
            ("test_Measurement_JSON", test_Measurement_JSON),
            ("test_URLComponents_JSON", test_URLComponents_JSON),
        ]
    }
}
