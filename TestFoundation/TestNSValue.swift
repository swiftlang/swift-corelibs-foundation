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


class TestNSValue : XCTestCase {
    var allTests : [(String, () -> Void)] {
        return [
            ( "test_valueWithLong", test_valueWithLong ),
            ( "test_valueWithCGTypes", test_valueWithCGTypes ),
            ( "test_valueWithShortArray", test_valueWithShortArray ),
            ( "test_valueWithULongLongArray", test_valueWithULongLongArray ),
            ( "test_valueWithCharPtr", test_valueWithULongLongArray ),
        ]
    }
    
    func test_valueWithCGTypes() {
        let point = CGPoint(x: CGFloat(1.0), y: CGFloat(2.0234))
        XCTAssertEqual(NSValue(point: point).pointValue, point)
        
        let size = CGSize(width: CGFloat(1123.234), height: CGFloat(3452.234))
        XCTAssertEqual(NSValue(size: size).sizeValue, size)
        
        let rect = CGRect(origin: point, size: size)
        XCTAssertEqual(NSValue(rect: rect).rectValue, rect)
        
        let insets = NSEdgeInsets(top: CGFloat(234.0), left: CGFloat(23.20), bottom: CGFloat(0.0), right: CGFloat(99.0))
        XCTAssertEqual(NSValue(edgeInsets: insets).edgeInsetsValue, insets)
    }
    
    func test_valueWithLong() {
        var long: Int32 = 123456
        var expected: Int32 = 0
        NSValue(bytes: &long, objCType: "l").getValue(&expected)
        XCTAssertEqual(long, expected)
    }
    
    func test_valueWithULongLongArray() {
        let array: Array<UInt64> = [12341234123, 23452345234, 23475982345, 9893563243, 13469816598]
        array.withUnsafeBufferPointer { cArray in
            var expected = [UInt64](count: 5, repeatedValue: 0)
            NSValue(bytes: cArray.baseAddress, objCType: "[5Q]").getValue(&expected)
            XCTAssertEqual(array, expected)
        }
    }
    
    func test_valueWithShortArray() {
        let array: Array<Int16> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        let objctype = "[" + String(array.count) + "s]"
        array.withUnsafeBufferPointer { cArray in
            var expected = [Int16](count: array.count, repeatedValue: 0)
            NSValue(bytes: cArray.baseAddress, objCType: objctype).getValue(&expected)
            XCTAssertEqual(array, expected)
        }
    }

    func test_valueWithCharPtr() {
        let charArray = [UInt8]("testing123".utf8)
        let charPtr = UnsafeMutablePointer<UInt8>(charArray)
        var expectedPtr = UnsafeMutablePointer<UInt8>()
        
        NSValue(bytes: charPtr, objCType: "*").getValue(&expectedPtr)
        XCTAssertEqual(charPtr, expectedPtr)
    }
}
