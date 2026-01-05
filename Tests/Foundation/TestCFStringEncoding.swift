// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestCFStringEncoding: XCTestCase {

    func test_mostCompatibleMacStringEncoding_0x200() {
        // Regression Test: 0x200 caused buffer underflow
        let encoding: CFStringEncoding = 0x0200
        let result = CFStringGetMostCompatibleMacStringEncoding(encoding)
        // Should return kCFStringEncodingInvalidId (0xFFFFFFFF) or a safe default, NOT crash
        XCTAssertEqual(
            result, kCFStringEncodingInvalidId,
            "0x200 encoding should return kCFStringEncodingInvalidId and not crash")
    }

    func test_mostCompatibleMacStringEncoding_OverflowCheck() {
        let ebcdicEncoding: CFStringEncoding = 0x0C02  // kCFStringEncodingEBCDIC_CP037
        let result = CFStringGetMostCompatibleMacStringEncoding(ebcdicEncoding)
        // Should map to MacRoman (0) or similar, but definitely no crash
        XCTAssertEqual(result, CFStringBuiltInEncodings.macRoman.rawValue)

        let dosLatinUS: CFStringEncoding = 0x0400  // kCFStringEncodingDOSLatinUS
        let result2 = CFStringGetMostCompatibleMacStringEncoding(dosLatinUS)
        XCTAssertEqual(result2, CFStringBuiltInEncodings.macRoman.rawValue)
    }

    func test_getNameOfEncoding_0x200() {
        // 0x200 caused buffer underflow in __CFStringEncodingGetName
        // The vulnerable code accessed __CFISONameList[encoding - 1] where encoding = 0
        // This resulted in accessing index -1 (out-of-bounds read)
        let encoding: CFStringEncoding = 0x0200
        let name = CFStringGetNameOfEncoding(encoding)
        // Should return nil safely, NOT crash or return garbage from OOB read
        XCTAssertNil(
            name, "0x0200 (ISO-8859 base) should return nil since it's not a valid encoding")
    }

    func test_getNameOfEncoding_validISO8859() {
        // Verify that valid ISO-8859 encodings still work correctly
        let iso8859_1: CFStringEncoding = 0x0201  // ISO-8859-1 (Latin-1)
        let name = CFStringGetNameOfEncoding(iso8859_1)
        XCTAssertNotNil(name, "ISO-8859-1 should have a valid name")
    }
}
