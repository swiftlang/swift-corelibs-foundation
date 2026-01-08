// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation
class TestCFStringEncoding: XCTestCase {

    func test_mostCompatibleMacStringEncoding_0x200() {
        // Regression Test: 0x200 caused buffer underflow and crashed
        let encoding: CFStringEncoding = 0x0200
        let result = CFStringGetMostCompatibleMacStringEncoding(encoding) // Do not crash
        XCTAssertEqual(result, kCFStringEncodingInvalidId)
    }

    func test_getNameOfEncoding_0x200() {
        // Regression Test: 0x200 caused buffer underflow
        let encoding: CFStringEncoding = 0x0200
        let name = CFStringGetNameOfEncoding(encoding) // Do not crash
        XCTAssertNil(name)
    }
}
