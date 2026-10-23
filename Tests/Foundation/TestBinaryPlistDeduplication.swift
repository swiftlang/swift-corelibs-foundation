// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

final class TestBinaryPlistDeduplication: XCTestCase {
    private static let minimumBinaryPlistSize = 40
    private static let trailerObjectCountStartOffsetFromEnd = 24
    private static let trailerObjectCountEndOffsetFromEnd = 16

    private static func parseBinaryPlistObjectCount(_ data: Data) -> UInt64 {
        guard data.count >= minimumBinaryPlistSize else { return 0 }
        var objectCountBigEndian: UInt64 = 0
        _ = withUnsafeMutableBytes(of: &objectCountBigEndian) { destination in
            let startIndex = data.count - trailerObjectCountStartOffsetFromEnd
            let endIndex = data.count - trailerObjectCountEndOffsetFromEnd
            data.copyBytes(to: destination, from: startIndex..<endIndex)
        }
        return UInt64(bigEndian: objectCountBigEndian)
    }

    private func binaryPlistObjectCount(
        _ data: Data,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UInt64 {
        XCTAssertGreaterThanOrEqual(
            data.count, Self.minimumBinaryPlistSize, file: file, line: line)
        guard data.count >= Self.minimumBinaryPlistSize else { return 0 }
        return Self.parseBinaryPlistObjectCount(data)
    }

    func test_binaryPlistDeduplicatesStrings() throws {
        // Dynamically construct strings so they do not share a static immortal buffer.
        let index = 42
        let repeatedASCIIStrings = (0..<25).map { _ in String("repeated_ascii_string_\(index)") }
        let asciiData = try PropertyListSerialization.data(
            fromPropertyList: repeatedASCIIStrings, format: .binary, options: 0)
        #if !canImport(ObjectiveC)
        // 1 top-level array + 1 unique string = 2 objects.
        XCTAssertEqual(binaryPlistObjectCount(asciiData), 2)
        #endif
        let decodedASCIIStrings =
            try PropertyListSerialization.propertyList(from: asciiData, options: [], format: nil)
            as? [String]
        XCTAssertEqual(decodedASCIIStrings, repeatedASCIIStrings)

        // Dictionary with distinct keys sharing identical dynamically-allocated string values
        // (swift-corelibs-foundation#5452).
        var dictionary: [String: String] = [:]
        for keyIndex in 0..<20 {
            dictionary["key_\(keyIndex)"] = String("shared_localized_value_\(index)")
        }
        let dictionaryData = try PropertyListSerialization.data(
            fromPropertyList: dictionary, format: .binary, options: 0)
        #if !canImport(ObjectiveC)
        // 1 dictionary + 20 unique keys + 1 shared value = 22 objects (would be 41 without
        // deduplication).
        XCTAssertEqual(binaryPlistObjectCount(dictionaryData), 22)
        #endif
        let decodedDictionary =
            try PropertyListSerialization.propertyList(from: dictionaryData, options: [], format: nil)
            as? [String: String]
        XCTAssertEqual(decodedDictionary, dictionary)

        // Exact reproduction of `bug-repro-xml.plist` from swiftlang/swift-corelibs-foundation#5452:
        // {"A": <2,828-byte ASCII string>, "B": "B"} converted from XML to binary1 must deduplicate
        // the key/value "B" into 4 objects (2,889 bytes) rather than 5 objects (2,893 bytes).
        let bugReproductionDictionary: [String: String] = [
            "A": String(repeating: "L", count: 2828),
            "B": String("B".utf8),
        ]
        let bugReproductionXMLData = try PropertyListSerialization.data(
            fromPropertyList: bugReproductionDictionary, format: .xml, options: 0)
        let bugReproductionPropertyList = try PropertyListSerialization.propertyList(
            from: bugReproductionXMLData, options: [], format: nil)
        let bugReproductionBinaryData = try PropertyListSerialization.data(
            fromPropertyList: bugReproductionPropertyList, format: .binary, options: 0)
        XCTAssertEqual(binaryPlistObjectCount(bugReproductionBinaryData), 4)
        XCTAssertEqual(bugReproductionBinaryData.count, 2889)

        // XML-to-binary conversion of < 1024-byte strings (interned by CFBurstTrie in XML parser):
        // must produce 22 objects on both Darwin and Linux.
        let dictionaryXMLData = try PropertyListSerialization.data(
            fromPropertyList: dictionary, format: .xml, options: 0)
        let dictionaryParsedFromXML = try PropertyListSerialization.propertyList(
            from: dictionaryXMLData, options: [], format: nil)
        let dictionaryBinaryDataFromXML = try PropertyListSerialization.data(
            fromPropertyList: dictionaryParsedFromXML, format: .binary, options: 0)
        XCTAssertEqual(binaryPlistObjectCount(dictionaryBinaryDataFromXML), 22)

        // XML-to-binary conversion workflow (as performed by `plutil -convert binary1`), including a
        // repeated string >= 1024 UTF-8 bytes (which bypasses CFBurstTrie in the XML parser).
        let longRepeatedValue = String(repeating: "LongLocalizedPayload_", count: 60) + "\(index)"
        XCTAssertGreaterThanOrEqual(longRepeatedValue.utf8.count, 1024)
        var xmlDictionary = dictionary
        for keyIndex in 0..<10 {
            xmlDictionary["long_key_\(keyIndex)"] = String(longRepeatedValue)
        }
        let xmlData = try PropertyListSerialization.data(
            fromPropertyList: xmlDictionary, format: .xml, options: 0)
        let propertyListFromXML = try PropertyListSerialization.propertyList(
            from: xmlData, options: [], format: nil)
        let binaryDataFromXML = try PropertyListSerialization.data(
            fromPropertyList: propertyListFromXML, format: .binary, options: 0)
        #if !canImport(ObjectiveC)
        // 1 dictionary + 30 unique keys + 2 unique shared values = 33 objects.
        XCTAssertEqual(binaryPlistObjectCount(binaryDataFromXML), 33)
        #endif
        let decodedDictionaryFromXML =
            try PropertyListSerialization.propertyList(from: binaryDataFromXML, options: [], format: nil)
            as? [String: String]
        XCTAssertEqual(decodedDictionaryFromXML, xmlDictionary)

        // Latin-1 (U+0080..U+00FF), UTF-16 BMP, and non-BMP (surrogate pair) strings.
        let repeatedLatin1Strings = (0..<10).map { _ in String("caf\u{00E9}_na\u{00EF}ve_\(index)") }
        let latin1Data = try PropertyListSerialization.data(
            fromPropertyList: repeatedLatin1Strings, format: .binary, options: 0)
        #if !canImport(ObjectiveC)
        XCTAssertEqual(binaryPlistObjectCount(latin1Data), 2)
        #endif
        let decodedLatin1Strings =
            try PropertyListSerialization.propertyList(from: latin1Data, options: [], format: nil)
            as? [String]
        XCTAssertEqual(decodedLatin1Strings, repeatedLatin1Strings)

        let repeatedUnicodeStrings = (0..<10).map { _ in String("Привіт світ 🚀🎉 \(index)") }
        let unicodeData = try PropertyListSerialization.data(
            fromPropertyList: repeatedUnicodeStrings, format: .binary, options: 0)
        #if !canImport(ObjectiveC)
        XCTAssertEqual(binaryPlistObjectCount(unicodeData), 2)
        #endif
        let decodedUnicodeStrings =
            try PropertyListSerialization.propertyList(from: unicodeData, options: [], format: nil)
            as? [String]
        XCTAssertEqual(decodedUnicodeStrings, repeatedUnicodeStrings)
    }

    func test_binaryPlistStringEdgeCases() throws {
        // 1. Precomposed U+00E9 vs decomposed U+0065 U+0301: canonically equal in Swift String.==,
        // but different UTF-16 lengths (1 vs 2). Must remain distinct in binary plist.
        let precomposedString = "\u{00E9}"
        let decomposedString = "e\u{0301}"
        XCTAssertEqual(precomposedString, decomposedString)
        XCTAssertNotEqual(precomposedString.utf16.count, decomposedString.utf16.count)
        let canonicalStringsData = try PropertyListSerialization.data(
            fromPropertyList: [precomposedString, decomposedString], format: .binary, options: 0)
        XCTAssertEqual(binaryPlistObjectCount(canonicalStringsData), 3)
        let decodedCanonicalStrings = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: canonicalStringsData, options: [], format: nil)
                as? [String]
        )
        XCTAssertEqual(decodedCanonicalStrings.count, 2)
        XCTAssertEqual(Array(decodedCanonicalStrings[0].utf16), [0x00E9])
        XCTAssertEqual(Array(decodedCanonicalStrings[1].utf16), [0x0065, 0x0301])

        // 2. Same-UTF-16-length canonically equivalent strings:
        // "\u{1E0B}\u{0323}" (U+1E0B LATIN SMALL LETTER D WITH DOT ABOVE + U+0323 COMBINING DOT BELOW)
        // vs "\u{1E0D}\u{0307}" (U+1E0D LATIN SMALL LETTER D WITH DOT BELOW +
        // U+0307 COMBINING DOT ABOVE).
        // Both have UTF-16 length 2 and are canonically equivalent, exercising CFStringCompare(..., 0)
        // after the CFStringGetLength equality check.
        let sameLengthCanonicalString1 = "\u{1E0B}\u{0323}"
        let sameLengthCanonicalString2 = "\u{1E0D}\u{0307}"
        XCTAssertEqual(sameLengthCanonicalString1, sameLengthCanonicalString2)
        XCTAssertEqual(sameLengthCanonicalString1.utf16.count, sameLengthCanonicalString2.utf16.count)
        let sameLengthCanonicalData = try PropertyListSerialization.data(
            fromPropertyList: [sameLengthCanonicalString1, sameLengthCanonicalString2],
            format: .binary,
            options: 0
        )
        XCTAssertEqual(binaryPlistObjectCount(sameLengthCanonicalData), 3)
        let decodedSameLengthStrings = try XCTUnwrap(
            PropertyListSerialization.propertyList(
                from: sameLengthCanonicalData, options: [], format: nil)
                as? [String]
        )
        XCTAssertEqual(decodedSameLengthStrings.count, 2)
        XCTAssertEqual(Array(decodedSameLengthStrings[0].utf16), [0x1E0B, 0x0323])
        XCTAssertEqual(Array(decodedSameLengthStrings[1].utf16), [0x1E0D, 0x0307])

        // 3. Strings with embedded null terminator characters sharing the same prefix and length.
        let nullTerminatedString1 = String("abc\0def_\(1)")
        let nullTerminatedString1Copy = String("abc\0def_\(1)")
        let nullTerminatedString2 = String("abc\0xyz_\(1)")
        let nullTerminatedStringData = try PropertyListSerialization.data(
            fromPropertyList: [
                nullTerminatedString1, nullTerminatedString1Copy, nullTerminatedString2,
            ],
            format: .binary,
            options: 0
        )
        #if !canImport(ObjectiveC)
        XCTAssertEqual(binaryPlistObjectCount(nullTerminatedStringData), 3)
        #endif
        let decodedNullTerminatedStrings =
            try PropertyListSerialization.propertyList(
                from: nullTerminatedStringData, options: [], format: nil)
            as? [String]
        XCTAssertEqual(
            decodedNullTerminatedStrings,
            [nullTerminatedString1, nullTerminatedString1Copy, nullTerminatedString2]
        )

        // 4. Long strings (> 1024 characters) that collide in __CFStrHashCharacters (which only
        // samples [0..<32], [length/2-16..<length/2+16], and [length-32..<length] when length > 96).
        var charactersA = Array(repeating: "A" as Character, count: 2000)
        var charactersB = charactersA
        charactersA[500] = "B"
        charactersB[500] = "C"
        let longStringA1 = String(charactersA)
        let longStringA2 = String(charactersA)
        let longStringB = String(charactersB)
        let longStringData = try PropertyListSerialization.data(
            fromPropertyList: [longStringA1, longStringA2, longStringB], format: .binary, options: 0)
        #if !canImport(ObjectiveC)
        XCTAssertEqual(binaryPlistObjectCount(longStringData), 3)
        #endif
        let decodedLongStrings =
            try PropertyListSerialization.propertyList(from: longStringData, options: [], format: nil)
            as? [String]
        XCTAssertEqual(decodedLongStrings, [longStringA1, longStringA2, longStringB])

        // 5. Empty Swift-bridged strings (exercising the length == 0 short-circuit in
        // _uniquingSetEqual).
        let emptyString1 = String("a".dropLast())
        let emptyString2 = String("b".dropLast())
        let emptyStringData = try PropertyListSerialization.data(
            fromPropertyList: [emptyString1, emptyString2], format: .binary, options: 0)
        XCTAssertEqual(binaryPlistObjectCount(emptyStringData), 2)
        let decodedEmptyStrings =
            try PropertyListSerialization.propertyList(from: emptyStringData, options: [], format: nil)
            as? [String]
        XCTAssertEqual(decodedEmptyStrings, ["", ""])
    }

    func test_binaryPlistDeduplicatesNumbersAndPreservesTypes() throws {
        // Large integers outside CFNumber's small integer cache (-1...12), plus negative integers
        // and integers constructed from different widths with the same numeric value.
        let zero = Int("0") ?? 0
        let integerA = NSNumber(value: 1_000_000 + zero)
        let integerB = NSNumber(value: 1_000_000 + zero)
        let negativeIntegerA = NSNumber(value: -500_000 + zero)
        let negativeIntegerB = NSNumber(value: -500_000 + zero)
        let width8Integer = NSNumber(value: 77 as Int8)
        let width16Integer = NSNumber(value: 77 as Int16)
        let width32Integer = NSNumber(value: 77 as Int32)
        let width64Integer = NSNumber(value: 77 as Int64)
        let integerData = try PropertyListSerialization.data(
            fromPropertyList: [
                integerA, integerB, negativeIntegerA, negativeIntegerB,
                width8Integer, width16Integer, width32Integer, width64Integer,
            ],
            format: .binary,
            options: 0
        )
        #if !canImport(ObjectiveC)
        // 1 array + 1_000_000 + (-500_000) + 77 = 4 objects.
        XCTAssertEqual(binaryPlistObjectCount(integerData), 4)
        #endif

        // UInt64.max (kCFNumberSInt128Type, 16-byte integer) vs Int64(-1) (kCFNumberSInt64Type,
        // 8-byte integer): Both have low 64 bits == 0xffffffffffffffff, so they must not be
        // conflated.
        let maximumUInt64Number1 = NSNumber(value: UInt64.max)
        let maximumUInt64Number2 = NSNumber(value: UInt64.max)
        let negativeOne = NSNumber(value: -1 as Int64)
        let signedInteger128Data = try PropertyListSerialization.data(
            fromPropertyList: [maximumUInt64Number1, maximumUInt64Number2, negativeOne],
            format: .binary,
            options: 0
        )
        #if !canImport(ObjectiveC)
        XCTAssertEqual(binaryPlistObjectCount(signedInteger128Data), 3)
        #endif
        let decodedSignedInteger128Numbers = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: signedInteger128Data, options: [], format: nil)
                as? [NSNumber]
        )
        XCTAssertEqual(decodedSignedInteger128Numbers.count, 3)
        XCTAssertEqual(decodedSignedInteger128Numbers[0].uint64Value, UInt64.max)
        XCTAssertEqual(decodedSignedInteger128Numbers[1].uint64Value, UInt64.max)
        XCTAssertEqual(decodedSignedInteger128Numbers[2].int64Value, -1)
        XCTAssertNotEqual(decodedSignedInteger128Numbers[0], decodedSignedInteger128Numbers[2])

        // Float32 (4-byte real 0x22) vs Float64 (8-byte real 0x23) with equal numeric value.
        let float1 = NSNumber(value: 1.5 as Float)
        let float2 = NSNumber(value: 1.5 as Float)
        let double1 = NSNumber(value: 1.5 as Double)
        let double2 = NSNumber(value: 1.5 as Double)
        let floatDoubleData = try PropertyListSerialization.data(
            fromPropertyList: [float1, float2, double1, double2],
            format: .binary,
            options: 0
        )
        #if !canImport(ObjectiveC)
        // 1 array + 1 Float32(1.5) + 1 Float64(1.5) = 3 objects.
        XCTAssertEqual(binaryPlistObjectCount(floatDoubleData), 3)
        #endif

        // +0.0 vs -0.0 and NaN / Infinity (must not trigger undefined behavior in hashing or
        // conflate signed zeros).
        let positiveZero = NSNumber(value: 0.0)
        let negativeZero1 = NSNumber(value: -0.0)
        let negativeZero2 = NSNumber(value: -0.0)
        let notANumber1 = NSNumber(value: Double.nan)
        let notANumber2 = NSNumber(value: Double.nan)
        let positiveInfinity1 = NSNumber(value: Double.infinity)
        let positiveInfinity2 = NSNumber(value: Double.infinity)
        let negativeInfinity1 = NSNumber(value: -Double.infinity)
        let negativeInfinity2 = NSNumber(value: -Double.infinity)
        let specialFloatsData = try PropertyListSerialization.data(
            fromPropertyList: [
                positiveZero, negativeZero1, negativeZero2,
                notANumber1, notANumber2,
                positiveInfinity1, positiveInfinity2,
                negativeInfinity1, negativeInfinity2,
            ],
            format: .binary,
            options: 0
        )
        #if !canImport(ObjectiveC)
        // 1 array + (+0.0) + (-0.0) + NaN + (+Infinity) + (-Infinity) = 6 objects.
        XCTAssertEqual(binaryPlistObjectCount(specialFloatsData), 6)
        #endif
        let decodedSpecialFloats = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: specialFloatsData, options: [], format: nil)
                as? [Double]
        )
        XCTAssertEqual(decodedSpecialFloats.count, 9)
        XCTAssertEqual(decodedSpecialFloats[0].sign, .plus)
        XCTAssertEqual(decodedSpecialFloats[1].sign, .minus)
        XCTAssertEqual(decodedSpecialFloats[2].sign, .minus)
        XCTAssertTrue(decodedSpecialFloats[3].isNaN)
        XCTAssertTrue(decodedSpecialFloats[4].isNaN)
        XCTAssertEqual(decodedSpecialFloats[5], .infinity)
        XCTAssertEqual(decodedSpecialFloats[7], -.infinity)

        // Booleans vs integers 0 and 1 vs floats 0.0 and 1.0 must remain distinct.
        let booleanAndNumberData = try PropertyListSerialization.data(
            fromPropertyList: [
                NSNumber(value: true),
                NSNumber(value: 1),
                NSNumber(value: 1.0),
                NSNumber(value: false),
                NSNumber(value: 0),
                NSNumber(value: 0.0),
            ],
            format: .binary,
            options: 0
        )
        XCTAssertEqual(binaryPlistObjectCount(booleanAndNumberData), 7)
    }

    func test_binaryPlistDeduplicatesDatesAndData() throws {
        // Pre-2001 dates (negative timeIntervalSinceReferenceDate) and post-2001 dates.
        let pre2001DateA = Date(timeIntervalSince1970: 0)
        let pre2001DateB = Date(timeIntervalSince1970: 0)
        let post2001DateA = Date(timeIntervalSinceReferenceDate: 123_456.789)
        let post2001DateB = Date(timeIntervalSinceReferenceDate: 123_456.789)
        let negativeZeroDate = Date(timeIntervalSinceReferenceDate: -0.0)
        let positiveZeroDate = Date(timeIntervalSinceReferenceDate: 0.0)
        let dateData = try PropertyListSerialization.data(
            fromPropertyList: [
                pre2001DateA, pre2001DateB, post2001DateA, post2001DateB,
                negativeZeroDate, positiveZeroDate,
            ],
            format: .binary,
            options: 0
        )
        // 1 array + pre2001Date + post2001Date + (-0.0 date) + (+0.0 date) = 5 objects.
        XCTAssertEqual(binaryPlistObjectCount(dateData), 5)
        let decodedDates = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: dateData, options: [], format: nil) as? [Date]
        )
        XCTAssertEqual(decodedDates.count, 6)
        XCTAssertEqual(decodedDates[0], pre2001DateA)
        XCTAssertEqual(decodedDates[2], post2001DateA)
        XCTAssertEqual(decodedDates[4].timeIntervalSinceReferenceDate.sign, .minus)
        XCTAssertEqual(decodedDates[5].timeIntervalSinceReferenceDate.sign, .plus)

        // Empty Data, all-zero Data of different lengths, and large Data (> 80 bytes, where
        // CFHashBytes only hashes the first 80 bytes).
        let emptyData1 = Data()
        let emptyData2 = Data()
        let fourZeroBytesA = Data(repeating: 0, count: 4)
        let fourZeroBytesB = Data(repeating: 0, count: 4)
        let eightZeroBytes = Data(repeating: 0, count: 8)
        var bytesA = Array(repeating: 0xAB as UInt8, count: 200)
        var bytesB = bytesA
        bytesA[150] = 0x01
        bytesB[150] = 0x02
        let largeDataA1 = Data(bytesA)
        let largeDataA2 = Data(bytesA)
        let largeDataB = Data(bytesB)
        let largeDataPrefix100 = Data(bytesA.prefix(100))
        let serializedDataPropertyList = try PropertyListSerialization.data(
            fromPropertyList: [
                emptyData1, emptyData2, fourZeroBytesA, fourZeroBytesB, eightZeroBytes,
                largeDataA1, largeDataA2, largeDataB, largeDataPrefix100,
            ],
            format: .binary,
            options: 0
        )
        #if !canImport(ObjectiveC)
        // 1 array + emptyData + fourZeroBytes + eightZeroBytes + largeDataA + largeDataB +
        // largeDataPrefix100 = 7 objects.
        XCTAssertEqual(binaryPlistObjectCount(serializedDataPropertyList), 7)
        #endif
        let decodedDataValues = try XCTUnwrap(
            PropertyListSerialization.propertyList(
                from: serializedDataPropertyList, options: [], format: nil) as? [Data]
        )
        XCTAssertEqual(
            decodedDataValues,
            [
                emptyData1, emptyData2, fourZeroBytesA, fourZeroBytesB, eightZeroBytes,
                largeDataA1, largeDataA2, largeDataB, largeDataPrefix100,
            ]
        )
    }

    func test_binaryPlistDeduplicatesBooleansWithoutOrphans() throws {
        let booleanArray = [true, true, true, false, false]
        let booleanData = try PropertyListSerialization.data(
            fromPropertyList: booleanArray, format: .binary, options: 0)
        #if !canImport(ObjectiveC)
        // 1 top-level array + true + false = 3 objects (51 bytes total), with no orphan 0x09/0x08
        // objects.
        XCTAssertEqual(binaryPlistObjectCount(booleanData), 3)
        XCTAssertEqual(booleanData.count, 51)
        #endif
        let decodedBooleans = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: booleanData, options: [], format: nil) as? [Bool]
        )
        XCTAssertEqual(decodedBooleans, booleanArray)

        // Shared container references (NSArray / NSDictionary referenced multiple times in a plist
        // graph) must not emit orphan duplicate container entries in objlist.
        let sharedDictionary: NSDictionary = ["shared_key": "shared_value"]
        let sharedArray: NSArray = [sharedDictionary, sharedDictionary]
        let rootContainer: NSArray = [sharedArray, sharedArray]
        let containerData = try PropertyListSerialization.data(
            fromPropertyList: rootContainer, format: .binary, options: 0)
        #if !canImport(ObjectiveC)
        // 1 rootContainer + 1 sharedArray + 1 sharedDictionary + "shared_key" + "shared_value" =
        // 5 objects.
        XCTAssertEqual(binaryPlistObjectCount(containerData), 5)
        #endif
        let decodedContainers = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: containerData, options: [], format: nil)
                as? [[[String: String]]]
        )
        XCTAssertEqual(
            decodedContainers,
            [
                [["shared_key": "shared_value"], ["shared_key": "shared_value"]],
                [["shared_key": "shared_value"], ["shared_key": "shared_value"]],
            ]
        )
    }

    func test_binaryPlistDeduplicatesKeyedArchiverUIDs() throws {
        let sharedString = "shared_archived_value_\(42)" as NSString
        let distinctEqualString = String("shared_archived_value_\(42)") as NSString
        let anotherString = "distinct_archived_value_\(42)" as NSString
        let stringsToArchive: [NSString] = [
            sharedString,
            sharedString,
            distinctEqualString,
            anotherString,
            sharedString,
        ]
        let arrayToArchive = NSArray(array: stringsToArchive)
        let archivedData = try NSKeyedArchiver.archivedData(
            withRootObject: arrayToArchive, requiringSecureCoding: true)
        let unarchivedStrings = try XCTUnwrap(
            NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSArray.self, NSString.self], from: archivedData) as? [String]
        )
        XCTAssertEqual(
            unarchivedStrings,
            [
                "shared_archived_value_42",
                "shared_archived_value_42",
                "shared_archived_value_42",
                "distinct_archived_value_42",
                "shared_archived_value_42",
            ]
        )

        #if !canImport(ObjectiveC)
        // Verify that all objects in the archive's object table are reachable (no orphan UIDs,
        // booleans, or strings) and that re-serializing the decoded raw plist produces the exact
        // same object count.
        let rawArchivePropertyList = try PropertyListSerialization.propertyList(
            from: archivedData, options: [], format: nil)
        let reserializedArchiveData = try PropertyListSerialization.data(
            fromPropertyList: rawArchivePropertyList, format: .binary, options: 0)
        XCTAssertEqual(
            binaryPlistObjectCount(archivedData),
            binaryPlistObjectCount(reserializedArchiveData)
        )
        // Exact object count in the keyed archive:
        // 1 top dictionary + 4 top keys ($archiver, $version, $objects, $top) + "NSKeyedArchiver" +
        // 100000 + $objects array + $top dictionary + "root" + "$null" + root NSArray dictionary +
        // 2 keys ($class, NS.objects) + NS.objects array + 4 UIDs (UID(1) for root array,
        // UID(2) for sharedString, UID(3) for anotherString, UID(4) for NSArray class) +
        // 2 strings + NSArray class dictionary + 2 keys ($classname, $classes) + "NSArray" +
        // $classes array + "NSObject" = 27 objects.
        XCTAssertEqual(binaryPlistObjectCount(archivedData), 27)

        // Also round-trip the archive through XML plist format: in XML, each
        // `<dict><key>CF$UID</key><integer>2</integer></dict>` tag is parsed via
        // `_CFKeyedArchiverUIDCreate` into a distinct `CFKeyedArchiverUIDRef` heap pointer with the
        // same `uint32_t` value, directly exercising `_uniquingSetEqual` and `_uniquingSetHash` for
        // `_kCFRuntimeIDCFKeyedArchiverUID`.
        let xmlArchiveData = try PropertyListSerialization.data(
            fromPropertyList: rawArchivePropertyList, format: .xml, options: 0)
        let xmlDecodedArchivePropertyList = try PropertyListSerialization.propertyList(
            from: xmlArchiveData, options: [], format: nil)
        let binaryDataFromXMLArchive = try PropertyListSerialization.data(
            fromPropertyList: xmlDecodedArchivePropertyList, format: .binary, options: 0)
        XCTAssertEqual(binaryPlistObjectCount(binaryDataFromXMLArchive), 27)
        let unarchivedFromXMLRoundTrip = try XCTUnwrap(
            NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSArray.self, NSString.self], from: binaryDataFromXMLArchive) as? [String]
        )
        XCTAssertEqual(unarchivedFromXMLRoundTrip, unarchivedStrings)

        // Repeating sharedString 10 more times must not add any new objects or orphan UIDs to the
        // object table.
        let largerArrayToArchive = NSArray(
            array: (0..<10).map { _ in sharedString } + stringsToArchive)
        let largerArchivedData = try NSKeyedArchiver.archivedData(
            withRootObject: largerArrayToArchive, requiringSecureCoding: true)
        XCTAssertEqual(
            binaryPlistObjectCount(largerArchivedData),
            binaryPlistObjectCount(archivedData)
        )
        #endif
    }

    func test_binaryPlistPureCFStringFastPathAndConcurrentSerialization() throws {
        // Exercise the non-Swift CFString (_CFStringEqual / __CFStringHash) fast path directly via
        // CoreFoundation on an XML plist with repeated >= 1024-byte strings (which bypass CFBurstTrie
        // in the XML parser).
        let longString = String(repeating: "PureCFStringPayload_", count: 60)
        XCTAssertGreaterThanOrEqual(longString.utf8.count, 1024)
        let xmlData = try PropertyListSerialization.data(
            fromPropertyList: [
                "key1": longString,
                "key2": String(longString),
                "key3": "short",
                "key4": "short",
            ],
            format: .xml,
            options: 0
        )
        let coreFoundationXMLData = try XCTUnwrap(
            xmlData.withUnsafeBytes { rawBuffer -> CFData? in
                guard let baseAddress = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    return nil
                }
                return CFDataCreate(kCFAllocatorDefault, baseAddress, xmlData.count)
            }
        )
        let coreFoundationPropertyList = try XCTUnwrap(
            CFPropertyListCreateWithData(kCFAllocatorDefault, coreFoundationXMLData, 0, nil, nil)?
                .takeRetainedValue()
        )
        let coreFoundationBinaryData = try XCTUnwrap(
            CFPropertyListCreateData(
                kCFAllocatorDefault,
                coreFoundationPropertyList,
                CFPropertyListFormat.binaryFormat_v1_0,
                0,
                nil
            )?.takeRetainedValue()
        )
        let binaryData = Data(
            bytes: CFDataGetBytePtr(coreFoundationBinaryData),
            count: CFDataGetLength(coreFoundationBinaryData)
        )
        #if !canImport(ObjectiveC)
        // 1 dictionary + 4 keys + 1 longString + 1 "short" = 7 objects.
        XCTAssertEqual(binaryPlistObjectCount(binaryData), 7)
        #else
        // On Darwin, "short" is interned by CFBurstTrie (< 1024 bytes) while longString
        // (>= 1024 bytes) is not.
        XCTAssertEqual(binaryPlistObjectCount(binaryData), 8)
        #endif

        // Concurrent binary plist serialization across multiple threads to verify thread-safe
        // execution of _uniquingSetEqual and _uniquingSetHash.
        let iterations = 32
        let errorCount = LockProtected<Int>(0)
        DispatchQueue.concurrentPerform(iterations: iterations) { iterationIndex in
            do {
                let payload: [String: Any] = [
                    "string1": String("concurrent_value_\(iterationIndex % 4)"),
                    "string2": String("concurrent_value_\(iterationIndex % 4)"),
                    "number1": NSNumber(value: 1_000_000 + (iterationIndex % 4)),
                    "number2": NSNumber(value: 1_000_000 + (iterationIndex % 4)),
                    "boolean1": true,
                    "boolean2": true,
                    "data1": Data([UInt8(iterationIndex % 4), 1, 2, 3]),
                    "data2": Data([UInt8(iterationIndex % 4), 1, 2, 3]),
                ]
                let encodedData = try PropertyListSerialization.data(
                    fromPropertyList: payload, format: .binary, options: 0)
                #if !canImport(ObjectiveC)
                // 1 dictionary + 8 keys + 4 unique values (string, integer, boolean, data) = 13 objects.
                if Self.parseBinaryPlistObjectCount(encodedData) != 13 {
                    errorCount.increment()
                }
                #endif
                let decodedDictionary =
                    try PropertyListSerialization.propertyList(from: encodedData, options: [], format: nil)
                    as? [String: Any]
                if decodedDictionary?.count != 8 {
                    errorCount.increment()
                }
            } catch {
                errorCount.increment()
            }
        }
        XCTAssertEqual(errorCount.value, 0)
    }
}

private final class LockProtected<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var protectedValue: Value

    init(_ protectedValue: Value) {
        self.protectedValue = protectedValue
    }

    var value: Value {
        lock.withLock { protectedValue }
    }

    func increment() where Value == Int {
        lock.withLock { protectedValue += 1 }
    }
}
