// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
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
        XCTAssertEqual(result, kCFStringEncodingInvalidId) // Do not crash
    }

    func test_getNameOfEncoding_0x200() {
        // 0x200 caused buffer underflow in __CFStringEncodingGetName
        // The vulnerable code accessed __CFISONameList[encoding - 1] where encoding = 0
        // This resulted in accessing index -1 (out-of-bounds read)
        let encoding: CFStringEncoding = 0x0200
        let name = CFStringGetNameOfEncoding(encoding)
        // Should return nil, NOT crash or return garbage from OOB read
        XCTAssertNil(
            name, "0x0200 (ISO-8859 base) should return nil since it's not a valid encoding")
    }
}
