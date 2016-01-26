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
    var allTests : [(String, () throws -> Void)] {
        return [
            ( "test_valueWithLong", test_valueWithLong ),
            ( "test_valueWithCGPoint", test_valueWithCGPoint ),
            ( "test_valueWithCGSize", test_valueWithCGSize ),
            ( "test_valueWithCGRect", test_valueWithCGRect ),
            ( "test_valueWithNSEdgeInsets", test_valueWithNSEdgeInsets ),
            ( "test_valueWithNSRange", test_valueWithNSRange ),
            ( "test_valueWithShortArray", test_valueWithShortArray ),
            ( "test_valueWithULongLongArray", test_valueWithULongLongArray ),
            ( "test_valueWithCharPtr", test_valueWithULongLongArray ),
        ]
    }
    
    func test_valueWithCGPoint() {
        let point = CGPoint(x: CGFloat(1.0), y: CGFloat(2.0234))
        let value = NSValue(point: point)
        XCTAssertEqual(value.pointValue, point)
        
        var expected = CGPoint()
        value.getValue(&expected)
        XCTAssertEqual(expected, point)
    }
    
    func test_valueWithCGSize() {
        let size = CGSize(width: CGFloat(1123.234), height: CGFloat(3452.234))
        let value = NSValue(size: size)
        XCTAssertEqual(value.sizeValue, size)
        
        var expected = CGSize()
        value.getValue(&expected)
        XCTAssertEqual(expected, size)
    }
    
    func test_valueWithCGRect() {
        let point = CGPoint(x: CGFloat(1.0), y: CGFloat(2.0234))
        let size = CGSize(width: CGFloat(1123.234), height: CGFloat(3452.234))
        let rect = CGRect(origin: point, size: size)
        let value = NSValue(rect: rect)
        XCTAssertEqual(value.rectValue, rect)
        
        var expected = CGRect()
        value.getValue(&expected)
        XCTAssertEqual(expected, rect)
    }
    
    func test_valueWithNSRange() {
        let range = NSMakeRange(1, 2)
        let value = NSValue(range: range)
        XCTAssertEqual(value.rangeValue.location, range.location)
        XCTAssertEqual(value.rangeValue.length, range.length)

        var expected = NSRange()
        value.getValue(&expected)
        XCTAssertEqual(expected.location, range.location)
        XCTAssertEqual(expected.length, range.length)
    }
    
    func test_valueWithNSEdgeInsets() {
        let edgeInsets = NSEdgeInsets(top: CGFloat(234.0), left: CGFloat(23.20), bottom: CGFloat(0.0), right: CGFloat(99.0))
        let value = NSValue(edgeInsets: edgeInsets)
        XCTAssertEqual(value.edgeInsetsValue.top, edgeInsets.top)
        XCTAssertEqual(value.edgeInsetsValue.left, edgeInsets.left)
        XCTAssertEqual(value.edgeInsetsValue.bottom, edgeInsets.bottom)
        XCTAssertEqual(value.edgeInsetsValue.right, edgeInsets.right)
        
        var expected = NSEdgeInsets()
        value.getValue(&expected)
        XCTAssertEqual(expected.top, edgeInsets.top)
        XCTAssertEqual(expected.left, edgeInsets.left)
        XCTAssertEqual(expected.bottom, edgeInsets.bottom)
        XCTAssertEqual(expected.right, edgeInsets.right)
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
        var charPtr = UnsafeMutablePointer<UInt8>(charArray)
        var expectedPtr = UnsafeMutablePointer<UInt8>()
        
        NSValue(bytes: &charPtr, objCType: "*").getValue(&expectedPtr)
        XCTAssertEqual(charPtr, expectedPtr)
    }
}
