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



class TestNSByteCountFormatter : XCTestCase {
    
    static var allTests: [(String, (TestNSByteCountFormatter) -> () throws -> Void)] {
        return [
            ("test_DefaultValues", test_DefaultValues),
            ("test_stringFromByteCount", test_stringFromByteCount),
            ("test_includesCountUnit", test_includesCountUnit),
            ("test_includesActualByteCount", test_includesActualByteCount),
            ("test_isAdaptive", test_isAdaptive),
            ("test_zeroPadsFractionDigits", test_zeroPadsFractionDigits),
            ("test_allowedUnits", test_allowedUnits)
        ]
    }
    
    func test_DefaultValues() {
        let formatter = ByteCountFormatter()
        XCTAssertEqual(formatter.allowedUnits, ByteCountFormatter.Units.useDefault)
        XCTAssertEqual(formatter.countStyle, ByteCountFormatter.CountStyle.file)
        XCTAssertEqual(formatter.allowsNonnumericFormatting, true)
        XCTAssertEqual(formatter.includesUnit, true)
        XCTAssertEqual(formatter.includesCount, true)
        XCTAssertEqual(formatter.includesActualByteCount, false)
        XCTAssertEqual(formatter.isAdaptive, true)
        XCTAssertEqual(formatter.zeroPadsFractionDigits, false)
        XCTAssertEqual(formatter.formattingContext, Formatter.Context.unknown)
    }
    
    func test_stringFromByteCount() {
        let formatter = ByteCountFormatter()
        //Default values tests
        XCTAssertEqual(formatter.string(fromByteCount: 0), "Zero KB")
        //Check singular value
        XCTAssertEqual(formatter.string(fromByteCount: 1), "1 byte")
        XCTAssertEqual(formatter.string(fromByteCount: 13), "13 bytes")
        //Check negative value
        XCTAssertEqual(formatter.string(fromByteCount: -13), "-13 bytes")
        //Check rounding
        XCTAssertEqual(formatter.string(fromByteCount: 1300), "1 KB")
        XCTAssertEqual(formatter.string(fromByteCount: 1600), "2 KB")
        XCTAssertEqual(formatter.string(fromByteCount: 1300000), "1.3 MB")
        XCTAssertEqual(formatter.string(fromByteCount: 1300000000), "1.3 GB")
        XCTAssertEqual(formatter.string(fromByteCount: 1300000000000), "1.3 TB")
        XCTAssertEqual(formatter.string(fromByteCount: 1300000000000000), "1.3 PB")
        XCTAssertEqual(formatter.string(fromByteCount: 1300000000000000000), "1.3 EB")
        
        //binary countStyle tests
        formatter.countStyle = .binary
        XCTAssertEqual(formatter.string(fromByteCount: 1000), "1,000 bytes")
        XCTAssertEqual(formatter.string(fromByteCount: 1000000), "977 KB")
        XCTAssertEqual(formatter.string(fromByteCount: 1000000000), "953.7 MB")
        XCTAssertEqual(formatter.string(fromByteCount: 1000000000000), "931.32 GB")
        XCTAssertEqual(formatter.string(fromByteCount: 1000000000000000), "909.49 TB")
        XCTAssertEqual(formatter.string(fromByteCount: 1000000000000000000), "888.18 PB")
        XCTAssertEqual(formatter.string(fromByteCount: 5000000000000000000), "4.34 EB")
        
        //AllowsNonnumericFormatting Test
        formatter.allowsNonnumericFormatting = false
        XCTAssertEqual(formatter.string(fromByteCount: 0), "0 bytes")
        
    }
    
    func test_includesCountUnit() {
        let formatter = ByteCountFormatter()
        formatter.includesCount = false
        formatter.includesUnit = false
        XCTAssertEqual(formatter.string(fromByteCount: 1300), "")
        
        formatter.includesUnit = true
        XCTAssertEqual(formatter.string(fromByteCount: 1300), "KB")
        
        formatter.includesCount = true
        formatter.includesUnit = false
        XCTAssertEqual(formatter.string(fromByteCount: 1300), "1")
    }
    
    func test_includesActualByteCount() {
        let formatter = ByteCountFormatter()
        formatter.includesActualByteCount = true
        
        XCTAssertEqual(formatter.string(fromByteCount: 100), "100 bytes")
        XCTAssertEqual(formatter.string(fromByteCount: 1300), "1 KB (1,300 bytes)")
        
        formatter.allowedUnits = .useBytes
        XCTAssertEqual(formatter.string(fromByteCount: 100000), "100,000 bytes")
        formatter.allowedUnits = .useKB
        XCTAssertEqual(formatter.string(fromByteCount: 100000), "100 KB (100,000 bytes)")
        
        formatter.allowedUnits = .useDefault
        formatter.includesCount = false
        XCTAssertEqual(formatter.string(fromByteCount: 100), "bytes")
        XCTAssertEqual(formatter.string(fromByteCount: 1300), "KB")
        
        
    }
    
    func test_isAdaptive() {
        let formatter = ByteCountFormatter()
        formatter.isAdaptive = false
        
        XCTAssertEqual(formatter.string(fromByteCount: 123000), "123 KB")
        
        //isAdaptive tests for when allowUnits is set
        formatter.allowedUnits = .useTB
        XCTAssertEqual(formatter.string(fromByteCount: 10000000), "0.0000100 TB")
    }
    
    func test_zeroPadsFractionDigits() {
        let formatter = ByteCountFormatter()
        formatter.zeroPadsFractionDigits = true
        
        XCTAssertEqual(formatter.string(fromByteCount: 120), "120 bytes")
        XCTAssertEqual(formatter.string(fromByteCount: 12000), "12 KB")
        XCTAssertEqual(formatter.string(fromByteCount: 12000000), "12.0 MB")
        XCTAssertEqual(formatter.string(fromByteCount: 12000000000), "12.00 GB")
        
        formatter.isAdaptive = false
        XCTAssertEqual(formatter.string(fromByteCount: 1200), "1.20 KB")
        XCTAssertEqual(formatter.string(fromByteCount: 12000), "12.0 KB")
        XCTAssertEqual(formatter.string(fromByteCount: 12000000), "12.0 MB")
        XCTAssertEqual(formatter.string(fromByteCount: 12000000000), "12.0 GB")
    }
    
    func test_allowedUnits() {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useBytes
        XCTAssertEqual(formatter.string(fromByteCount: 12000000000000), "12,000,000,000,000 bytes")
        
        formatter.allowedUnits = .useKB
        XCTAssertEqual(formatter.string(fromByteCount: 12000000000000), "12,000,000,000 KB")
        
        formatter.allowedUnits = .useMB
        XCTAssertEqual(formatter.string(fromByteCount: 12000000000000), "12,000,000 MB")
        
        formatter.allowedUnits = .useGB
        XCTAssertEqual(formatter.string(fromByteCount: 12000000000000), "12,000 GB")
        
        formatter.allowedUnits = .useTB
        XCTAssertEqual(formatter.string(fromByteCount: 12000000000000), "12 TB")
        
        formatter.allowedUnits = .usePB
        XCTAssertEqual(formatter.string(fromByteCount: 12000000000000), "0.01 PB")
        
        formatter.allowedUnits = .useEB
        XCTAssertEqual(formatter.string(fromByteCount: 1900000000000000000), "1.9 EB")
        
        formatter.allowedUnits = .useZB
        XCTAssertEqual(formatter.string(fromByteCount: 6000000000000000000), "0.01 ZB")
        
        formatter.allowedUnits = .useYBOrHigher
        XCTAssertEqual(formatter.string(fromByteCount: 6000000000000000000), "0 YB")
        XCTAssertEqual(formatter.string(fromByteCount: 0), "Zero KB")
    }

}
