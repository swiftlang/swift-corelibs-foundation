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
    import CoreFoundation
#else
    import SwiftFoundation
    import SwiftXCTest
#endif


class TestNSGeometry : XCTestCase {

    static var allTests: [(String, (TestNSGeometry) -> () throws -> Void)] {
        return [
            ("test_CGFloat_BasicConstruction", test_CGFloat_BasicConstruction),
            ("test_CGFloat_Equality", test_CGFloat_Equality),
            ("test_CGFloat_LessThanOrEqual", test_CGFloat_LessThanOrEqual),
            ("test_CGFloat_GreaterThanOrEqual", test_CGFloat_GreaterThanOrEqual),
            ("test_CGPoint_BasicConstruction", test_CGPoint_BasicConstruction),
            ("test_CGPoint_ExtendedConstruction", test_CGPoint_ExtendedConstruction),
            ("test_CGSize_BasicConstruction", test_CGSize_BasicConstruction),
            ("test_CGSize_ExtendedConstruction", test_CGSize_ExtendedConstruction),
            ("test_CGRect_BasicConstruction", test_CGRect_BasicConstruction),
            ("test_CGRect_ExtendedConstruction", test_CGRect_ExtendedConstruction),
            ("test_CGRect_SpecialValues", test_CGRect_SpecialValues),
            ("test_NSEdgeInsets_BasicConstruction", test_NSEdgeInsets_BasicConstruction),
            ("test_NSEdgeInsetsEqual", test_NSEdgeInsetsEqual),
            ("test_NSMakePoint", test_NSMakePoint),
            ("test_NSMakeSize", test_NSMakeSize),
            ("test_NSMakeRect", test_NSMakeRect),
            ("test_NSEdgeInsetsMake", test_NSEdgeInsetsMake),
            ("test_NSUnionRect", test_NSUnionRect),
            ("test_NSIntersectionRect", test_NSIntersectionRect),
            ("test_NSOffsetRect", test_NSOffsetRect),
            ("test_NSPointInRect", test_NSPointInRect),
            ("test_NSMouseInRect", test_NSMouseInRect),
            ("test_NSContainsRect", test_NSContainsRect),
            ("test_NSIntersectsRect", test_NSIntersectsRect),
            ("test_NSIntegralRect", test_NSIntegralRect),
            ("test_NSIntegralRectWithOptions", test_NSIntegralRectWithOptions),
            ("test_NSDivideRect", test_NSDivideRect),
            ("test_EncodeToNSString", test_EncodeToNSString),
            ("test_EncodeNegativeToNSString", test_EncodeNegativeToNSString),
            ("test_DecodeFromNSString", test_DecodeFromNSString),
            ("test_DecodeEmptyStrings", test_DecodeEmptyStrings),
            ("test_DecodeNegativeFromNSString", test_DecodeNegativeFromNSString),
            ("test_DecodeGarbageFromNSString", test_DecodeGarbageFromNSString),
        ]
    }

    func test_CGFloat_BasicConstruction() {
        XCTAssertEqual(CGFloat().native, 0.0)
        XCTAssertEqual(CGFloat(Double(3.0)).native, 3.0)
    }

    func test_CGFloat_Equality() {
        XCTAssertEqual(CGFloat(), CGFloat())
        XCTAssertEqual(CGFloat(1.0), CGFloat(1.0))
        XCTAssertEqual(CGFloat(-42.0), CGFloat(-42.0))

        XCTAssertNotEqual(CGFloat(1.0), CGFloat(1.4))
        XCTAssertNotEqual(CGFloat(37.3), CGFloat(-42.0))
        XCTAssertNotEqual(CGFloat(1.345), CGFloat())
    }

    func test_CGFloat_LessThanOrEqual() {
        let w = CGFloat(-4.5)
        let x = CGFloat(1.0)
        let y = CGFloat(2.2)

        XCTAssertLessThanOrEqual(CGFloat(), CGFloat())
        XCTAssertLessThanOrEqual(w, w)
        XCTAssertLessThanOrEqual(y, y)

        XCTAssertLessThan(w, x)
        XCTAssertLessThanOrEqual(w, x)
        XCTAssertLessThan(x, y)
        XCTAssertLessThanOrEqual(x, y)
        XCTAssertLessThan(w, y)
        XCTAssertLessThanOrEqual(w, y)
    }

    func test_CGFloat_GreaterThanOrEqual() {
        let w = CGFloat(-4.5)
        let x = CGFloat(1.0)
        let y = CGFloat(2.2)

        XCTAssertGreaterThanOrEqual(CGFloat(), CGFloat())
        XCTAssertGreaterThanOrEqual(w, w)
        XCTAssertGreaterThanOrEqual(y, y)

        XCTAssertGreaterThan(x, w)
        XCTAssertGreaterThanOrEqual(x, w)
        XCTAssertGreaterThan(y, x)
        XCTAssertGreaterThanOrEqual(y, x)
        XCTAssertGreaterThan(y, w)
        XCTAssertGreaterThanOrEqual(y, w)
    }

    func test_CGPoint_BasicConstruction() {
        let p1 = CGPoint()
        XCTAssertEqual(p1.x, CGFloat(0.0))
        XCTAssertEqual(p1.y, CGFloat(0.0))

        let p2 = CGPoint(x: CGFloat(3.6), y: CGFloat(4.5))
        XCTAssertEqual(p2.x, CGFloat(3.6))
        XCTAssertEqual(p2.y, CGFloat(4.5))
    }
    
    func test_CGPoint_ExtendedConstruction() {
        let p1 = CGPoint.zero
        XCTAssertEqual(p1.x, CGFloat(0))
        XCTAssertEqual(p1.y, CGFloat(0))
        
        let p2 = CGPoint(x: Int(3), y: Int(4))
        XCTAssertEqual(p2.x, CGFloat(3))
        XCTAssertEqual(p2.y, CGFloat(4))
        
        let p3 = CGPoint(x: Double(3.6), y: Double(4.5))
        XCTAssertEqual(p3.x, CGFloat(3.6))
        XCTAssertEqual(p3.y, CGFloat(4.5))
    }

    func test_CGSize_BasicConstruction() {
        let s1 = CGSize()
        XCTAssertEqual(s1.width, CGFloat(0.0))
        XCTAssertEqual(s1.height, CGFloat(0.0))

        let s2 = CGSize(width: CGFloat(3.6), height: CGFloat(4.5))
        XCTAssertEqual(s2.width, CGFloat(3.6))
        XCTAssertEqual(s2.height, CGFloat(4.5))
    }
    
    func test_CGSize_ExtendedConstruction() {
        let s1 = CGSize.zero
        XCTAssertEqual(s1.width, CGFloat(0))
        XCTAssertEqual(s1.height, CGFloat(0))
        
        let s2 = CGSize(width: Int(3), height: Int(4))
        XCTAssertEqual(s2.width, CGFloat(3))
        XCTAssertEqual(s2.height, CGFloat(4))
        
        let s3 = CGSize(width: Double(3.6), height: Double(4.5))
        XCTAssertEqual(s3.width, CGFloat(3.6))
        XCTAssertEqual(s3.height, CGFloat(4.5))
    }

    func test_CGRect_BasicConstruction() {
        let r1 = CGRect()
        XCTAssertEqual(r1.origin.x, CGFloat(0.0))
        XCTAssertEqual(r1.origin.y, CGFloat(0.0))
        XCTAssertEqual(r1.size.width, CGFloat(0.0))
        XCTAssertEqual(r1.size.height, CGFloat(0.0))

        let p = CGPoint(x: CGFloat(2.2), y: CGFloat(3.0))
        let s = CGSize(width: CGFloat(5.0), height: CGFloat(5.0))
        let r2 = CGRect(origin: p, size: s)
        XCTAssertEqual(r2.origin.x, p.x)
        XCTAssertEqual(r2.origin.y, p.y)
        XCTAssertEqual(r2.size.width, s.width)
        XCTAssertEqual(r2.size.height, s.height)
    }
    
    func test_CGRect_ExtendedConstruction() {
        let r1 = CGRect.zero
        XCTAssertEqual(r1.origin.x, CGFloat(0.0))
        XCTAssertEqual(r1.origin.y, CGFloat(0.0))
        XCTAssertEqual(r1.size.width, CGFloat(0.0))
        XCTAssertEqual(r1.size.height, CGFloat(0.0))
        
        let r2 = CGRect(x: CGFloat(1.2), y: CGFloat(2.3), width: CGFloat(3.4), height: CGFloat(4.5))
        XCTAssertEqual(r2.origin.x, CGFloat(1.2))
        XCTAssertEqual(r2.origin.y, CGFloat(2.3))
        XCTAssertEqual(r2.size.width, CGFloat(3.4))
        XCTAssertEqual(r2.size.height, CGFloat(4.5))
        
        let r3 = CGRect(x: Double(1.2), y: Double(2.3), width: Double(3.4), height: Double(4.5))
        XCTAssertEqual(r3.origin.x, CGFloat(1.2))
        XCTAssertEqual(r3.origin.y, CGFloat(2.3))
        XCTAssertEqual(r3.size.width, CGFloat(3.4))
        XCTAssertEqual(r3.size.height, CGFloat(4.5))
        
        let r4 = CGRect(x: Int(1), y: Int(2), width: Int(3), height: Int(4))
        XCTAssertEqual(r4.origin.x, CGFloat(1))
        XCTAssertEqual(r4.origin.y, CGFloat(2))
        XCTAssertEqual(r4.size.width, CGFloat(3))
        XCTAssertEqual(r4.size.height, CGFloat(4))
    }
    
    func test_CGRect_SpecialValues() {
        let r1 = CGRect.null
        XCTAssertEqual(r1.origin.x, CGFloat.infinity)
        XCTAssertEqual(r1.origin.y, CGFloat.infinity)
        XCTAssertEqual(r1.size.width, CGFloat(0.0))
        XCTAssertEqual(r1.size.height, CGFloat(0.0))
        
        let r2 = CGRect.infinite
        XCTAssertEqual(r2.origin.x, -CGFloat.greatestFiniteMagnitude / 2)
        XCTAssertEqual(r2.origin.y, -CGFloat.greatestFiniteMagnitude / 2)
        XCTAssertEqual(r2.size.width, CGFloat.greatestFiniteMagnitude)
        XCTAssertEqual(r2.size.height, CGFloat.greatestFiniteMagnitude)
    }

    func test_NSEdgeInsets_BasicConstruction() {
        let i1 = NSEdgeInsets()
        XCTAssertEqual(i1.top, CGFloat(0.0))
        XCTAssertEqual(i1.left, CGFloat(0.0))
        XCTAssertEqual(i1.bottom, CGFloat(0.0))
        XCTAssertEqual(i1.right, CGFloat(0.0))

        let i2 = NSEdgeInsets(top: CGFloat(3.6), left: CGFloat(4.5), bottom: CGFloat(5.0), right: CGFloat(-1.0))
        XCTAssertEqual(i2.top, CGFloat(3.6))
        XCTAssertEqual(i2.left, CGFloat(4.5))
        XCTAssertEqual(i2.bottom, CGFloat(5.0))
        XCTAssertEqual(i2.right, CGFloat(-1.0))
    }

    func test_NSEdgeInsetsEqual() {
        let variant1 = NSEdgeInsets(top: CGFloat(3.6), left: CGFloat(4.5), bottom: CGFloat(5.0), right: CGFloat(-1.0))
        let variant1Copy = NSEdgeInsets(top: CGFloat(3.6), left: CGFloat(4.5), bottom: CGFloat(5.0), right: CGFloat(-1.0))
        let variant2 = NSEdgeInsets(top: CGFloat(3.1), left: CGFloat(4.5), bottom: CGFloat(5.0), right: CGFloat(-1.0))
        XCTAssertTrue(NSEdgeInsetsEqual(variant1, variant1Copy))
        XCTAssertFalse(NSEdgeInsetsEqual(variant1, variant2))
    }

    func test_NSMakePoint() {
        let p2 = NSMakePoint(CGFloat(3.6), CGFloat(4.5))
        XCTAssertEqual(p2.x, CGFloat(3.6))
        XCTAssertEqual(p2.y, CGFloat(4.5))
    }

    func test_NSMakeSize() {
        let s2 = NSMakeSize(CGFloat(3.6), CGFloat(4.5))
        XCTAssertEqual(s2.width, CGFloat(3.6))
        XCTAssertEqual(s2.height, CGFloat(4.5))
    }

    func test_NSMakeRect() {
        let r2 = NSMakeRect(CGFloat(2.2), CGFloat(3.0), CGFloat(5.0), CGFloat(5.0))
        XCTAssertEqual(r2.origin.x, CGFloat(2.2))
        XCTAssertEqual(r2.origin.y, CGFloat(3.0))
        XCTAssertEqual(r2.size.width, CGFloat(5.0))
        XCTAssertEqual(r2.size.height, CGFloat(5.0))
    }

    func test_NSEdgeInsetsMake() {
        let i2 = NSEdgeInsetsMake(CGFloat(2.2), CGFloat(3.0), CGFloat(5.0), CGFloat(5.0))
        XCTAssertEqual(i2.top, CGFloat(2.2))
        XCTAssertEqual(i2.left, CGFloat(3.0))
        XCTAssertEqual(i2.bottom, CGFloat(5.0))
        XCTAssertEqual(i2.right, CGFloat(5.0))
    }

    func test_NSUnionRect() {
        let r1 = NSMakeRect(CGFloat(1.2), CGFloat(3.1), CGFloat(10.0), CGFloat(10.0))
        let r2 = NSMakeRect(CGFloat(10.2), CGFloat(2.5), CGFloat(5.0), CGFloat(5.0))

        XCTAssertTrue(NSIsEmptyRect(NSUnionRect(NSZeroRect, NSZeroRect)))
        XCTAssertTrue(NSEqualRects(r1, NSUnionRect(r1, NSZeroRect)))
        XCTAssertTrue(NSEqualRects(r2, NSUnionRect(NSZeroRect, r2)))

        let r3 = NSUnionRect(r1, r2)
        XCTAssertEqual(r3.origin.x, CGFloat(1.2))
        XCTAssertEqual(r3.origin.y, CGFloat(2.5))
        XCTAssertEqual(r3.size.width, CGFloat(14.0))
        XCTAssertEqual(r3.size.height, CGFloat(10.6))
    }

    func test_NSIntersectionRect() {
        let r1 = NSMakeRect(CGFloat(1.2), CGFloat(3.1), CGFloat(10.0), CGFloat(10.0))
        let r2 = NSMakeRect(CGFloat(-2.3), CGFloat(-1.5), CGFloat(1.0), CGFloat(1.0))
        let r3 = NSMakeRect(CGFloat(10.2), CGFloat(2.5), CGFloat(5.0), CGFloat(5.0))

        XCTAssertTrue(NSIsEmptyRect(NSIntersectionRect(r1, r2)))

        let r4 = NSIntersectionRect(r1, r3)
        XCTAssertEqual(r4.origin.x, CGFloat(10.2))
        XCTAssertEqual(r4.origin.y, CGFloat(3.1))
        XCTAssertEqual(r4.size.width, CGFloat(1.0))
        XCTAssertEqual(r4.size.height, CGFloat(4.4))
    }

    func test_NSOffsetRect() {
        let r1 = NSMakeRect(CGFloat(1.2), CGFloat(3.1), CGFloat(10.0), CGFloat(10.0))
        let r2 = NSOffsetRect(r1, CGFloat(2.0), CGFloat(-5.0))
        let expectedRect = NSMakeRect(CGFloat(3.2), CGFloat(-1.9), CGFloat(10.0), CGFloat(10.0))
        
        XCTAssertTrue(_NSRect(expectedRect, equalsToRect: r2))
    }

    func test_NSPointInRect() {
        let p1 = NSMakePoint(CGFloat(2.2), CGFloat(5.3))
        let p2 = NSMakePoint(CGFloat(1.2), CGFloat(3.1))
        let p3 = NSMakePoint(CGFloat(1.2), CGFloat(5.3))
        let p4 = NSMakePoint(CGFloat(5.2), CGFloat(3.1))
        let p5 = NSMakePoint(CGFloat(11.2), CGFloat(13.1))
        let r1 = NSMakeRect(CGFloat(1.2), CGFloat(3.1), CGFloat(10.0), CGFloat(10.0))
        let r2 = NSMakeRect(CGFloat(-2.3), CGFloat(-1.5), CGFloat(1.0), CGFloat(1.0))

        XCTAssertFalse(NSPointInRect(NSZeroPoint, NSZeroRect))
        XCTAssertFalse(NSPointInRect(p1, r2))
        XCTAssertTrue(NSPointInRect(p1, r1))
        XCTAssertTrue(NSPointInRect(p2, r1))
        XCTAssertTrue(NSPointInRect(p3, r1))
        XCTAssertTrue(NSPointInRect(p4, r1))
        XCTAssertFalse(NSPointInRect(p5, r1))
    }

    func test_NSMouseInRect() {
        let p1 = NSMakePoint(CGFloat(2.2), CGFloat(5.3))
        let r1 = NSMakeRect(CGFloat(1.2), CGFloat(3.1), CGFloat(10.0), CGFloat(10.0))
        let r2 = NSMakeRect(CGFloat(-2.3), CGFloat(-1.5), CGFloat(1.0), CGFloat(1.0))

        XCTAssertFalse(NSMouseInRect(NSZeroPoint, NSZeroRect, true))
        XCTAssertFalse(NSMouseInRect(p1, r2, true))
        XCTAssertTrue(NSMouseInRect(p1, r1, true))

        let p2 = NSMakePoint(NSMinX(r1), NSMaxY(r1))
        XCTAssertFalse(NSMouseInRect(p2, r1, true))
        XCTAssertTrue(NSMouseInRect(p2, r1, false))

        let p3 = NSMakePoint(NSMinX(r1), NSMinY(r1))
        XCTAssertFalse(NSMouseInRect(p3, r1, false))
        XCTAssertTrue(NSMouseInRect(p3, r1, true))
    }

    func test_NSContainsRect() {
        let r1 = NSMakeRect(CGFloat(1.2), CGFloat(3.1), CGFloat(10.0), CGFloat(10.0))
        let r2 = NSMakeRect(CGFloat(-2.3), CGFloat(-1.5), CGFloat(1.0), CGFloat(1.0))
        let r3 = NSMakeRect(CGFloat(10.2), CGFloat(5.5), CGFloat(0.5), CGFloat(5.0))

        XCTAssertFalse(NSContainsRect(r1, NSZeroRect))
        XCTAssertFalse(NSContainsRect(r1, r2))
        XCTAssertFalse(NSContainsRect(r2, r1))
        XCTAssertTrue(NSContainsRect(r1, r3))
    }

    func test_NSIntersectsRect() {
        let r1 = NSMakeRect(CGFloat(1.2), CGFloat(3.1), CGFloat(10.0), CGFloat(10.0))
        let r2 = NSMakeRect(CGFloat(-2.3), CGFloat(-1.5), CGFloat(1.0), CGFloat(1.0))
        let r3 = NSMakeRect(CGFloat(10.2), CGFloat(2.5), CGFloat(5.0), CGFloat(5.0))

        XCTAssertFalse(NSIntersectsRect(NSZeroRect, NSZeroRect))
        XCTAssertFalse(NSIntersectsRect(r1, NSZeroRect))
        XCTAssertFalse(NSIntersectsRect(NSZeroRect, r2))
        XCTAssertFalse(NSIntersectsRect(r1, r2))
        XCTAssertTrue(NSIntersectsRect(r1, r3))
    }

    func test_NSIntegralRect() {
        let referenceNegativeRect = NSMakeRect(CGFloat(-0.6), CGFloat(-5.4), CGFloat(-105.7), CGFloat(-24.3))
        XCTAssertEqual(NSIntegralRect(referenceNegativeRect), NSZeroRect)

        
        let referenceRect = NSMakeRect(CGFloat(0.6), CGFloat(5.4), CGFloat(105.7), CGFloat(24.3))
        let referenceNegativeOriginRect = NSMakeRect(CGFloat(-0.6), CGFloat(-5.4), CGFloat(105.7), CGFloat(24.3))
        
        var expectedResult = NSMakeRect(CGFloat(0.0), CGFloat(5.0), CGFloat(107.0), CGFloat(25.0))
        var result = NSIntegralRect(referenceRect)
        XCTAssertEqual(result, expectedResult)

        expectedResult = NSMakeRect(CGFloat(-1.0), CGFloat(-6.0), CGFloat(107.0), CGFloat(25.0))
        result = NSIntegralRect(referenceNegativeOriginRect)
        XCTAssertEqual(result, expectedResult)
    
    }
    
    func test_NSIntegralRectWithOptions() {
        let referenceRect = NSMakeRect(CGFloat(0.6), CGFloat(5.4), CGFloat(105.7), CGFloat(24.3))
        let referenceNegativeRect = NSMakeRect(CGFloat(-0.6), CGFloat(-5.4), CGFloat(-105.7), CGFloat(-24.3))
        let referenceNegativeOriginRect = NSMakeRect(CGFloat(-0.6), CGFloat(-5.4), CGFloat(105.7), CGFloat(24.3))

        var options: AlignmentOptions = [.alignMinXInward, .alignMinYInward, .alignHeightInward, .alignWidthInward]
        var expectedResult = NSMakeRect(CGFloat(1.0), CGFloat(6.0), CGFloat(105.0), CGFloat(24.0))
        var result = NSIntegralRectWithOptions(referenceRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMinXOutward, .alignMinYOutward, .alignHeightOutward, .alignWidthOutward]
        expectedResult = NSMakeRect(CGFloat(0.0), CGFloat(5.0), CGFloat(106.0), CGFloat(25.0))
        result = NSIntegralRectWithOptions(referenceRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMinXInward, .alignMinYInward, .alignHeightInward, .alignWidthInward]
        expectedResult = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(0.0), CGFloat(0.0))
        result = NSIntegralRectWithOptions(referenceNegativeRect, options)
        XCTAssertEqual(result, expectedResult)
        
        options = [.alignMinXInward, .alignMinYInward, .alignHeightInward, .alignWidthInward]
        expectedResult = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(105.0), CGFloat(24.0))
        result = NSIntegralRectWithOptions(referenceNegativeOriginRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMinXOutward, .alignMinYOutward, .alignHeightOutward, .alignWidthOutward]
        expectedResult = NSMakeRect(CGFloat(-1.0), CGFloat(-6.0), CGFloat(106.0), CGFloat(25.0))
        result = NSIntegralRectWithOptions(referenceNegativeOriginRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMaxXOutward, .alignMaxYOutward, .alignHeightOutward, .alignWidthOutward]
        expectedResult = NSMakeRect(CGFloat(0.0), CGFloat(-6.0), CGFloat(106.0), CGFloat(25.0))
        result = NSIntegralRectWithOptions(referenceNegativeOriginRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMinXOutward, .alignMaxXOutward, .alignMinYOutward, .alignMaxYOutward]
        expectedResult = NSMakeRect(CGFloat(-1.0), CGFloat(-6.0), CGFloat(107.0), CGFloat(25.0))
        result = NSIntegralRectWithOptions(referenceNegativeOriginRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMaxXOutward, .alignMaxYOutward, .alignHeightOutward, .alignWidthOutward]
        expectedResult = NSMakeRect(CGFloat(1.0), CGFloat(5.0), CGFloat(106.0), CGFloat(25.0))
        result = NSIntegralRectWithOptions(referenceRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMaxXInward, .alignMaxYInward, .alignHeightOutward, .alignWidthOutward]
        expectedResult = NSMakeRect(CGFloat(-1.0), CGFloat(-7.0), CGFloat(106.0), CGFloat(25.0))
        result = NSIntegralRectWithOptions(referenceNegativeOriginRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMaxXInward, .alignMaxYInward, .alignHeightOutward, .alignWidthOutward]
        expectedResult = NSMakeRect(CGFloat(0.0), CGFloat(4.0), CGFloat(106.0), CGFloat(25.0))
        result = NSIntegralRectWithOptions(referenceRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMinXNearest, .alignMinYNearest, .alignHeightNearest, .alignWidthNearest]
        expectedResult = NSMakeRect(CGFloat(1.0), CGFloat(5.0), CGFloat(106.0), CGFloat(24.0))
        result = NSIntegralRectWithOptions(referenceRect, options)
        XCTAssertEqual(result, expectedResult)
        
        options = [.alignMinXNearest, .alignMinYNearest, .alignHeightNearest, .alignWidthNearest]
        expectedResult = NSMakeRect(CGFloat(-1.0), CGFloat(-5.0), CGFloat(106.0), CGFloat(24.0))
        result = NSIntegralRectWithOptions(referenceNegativeOriginRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMaxXNearest, .alignMaxYNearest, .alignHeightNearest, .alignWidthNearest]
        expectedResult = NSMakeRect(CGFloat(0.0), CGFloat(6.0), CGFloat(106.0), CGFloat(24.0))
        result = NSIntegralRectWithOptions(referenceRect, options)
        XCTAssertEqual(result, expectedResult)
        
        options = [.alignMaxXNearest, .alignMaxYNearest, .alignHeightNearest, .alignWidthNearest]
        expectedResult = NSMakeRect(CGFloat(-1.0), CGFloat(-5.0), CGFloat(106.0), CGFloat(24.0))
        result = NSIntegralRectWithOptions(referenceNegativeOriginRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMinXInward, .alignMaxXInward, .alignMinYInward, .alignMaxYInward]
        expectedResult = NSMakeRect(CGFloat(1.0), CGFloat(6.0), CGFloat(105.0), CGFloat(23.0))
        result = NSIntegralRectWithOptions(referenceRect, options)
        XCTAssertEqual(result, expectedResult)
        
        options = [.alignMinXInward, .alignMaxXInward, .alignMinYInward, .alignMaxYInward]
        expectedResult = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(105.0), CGFloat(23.0))
        result = NSIntegralRectWithOptions(referenceNegativeOriginRect, options)
        XCTAssertEqual(result, expectedResult)

        options = [.alignMinXNearest, .alignMaxXInward, .alignMinYInward, .alignMaxYNearest]
        expectedResult = NSMakeRect(CGFloat(-1.0), CGFloat(-5.0), CGFloat(106.0), CGFloat(24.0))
        result = NSIntegralRectWithOptions(referenceNegativeOriginRect, options)
        XCTAssertEqual(result, expectedResult)
    }

    func test_NSDivideRect() {

        // divide empty rect
        var inRect = NSZeroRect
        var slice = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(35.0))
        var remainder = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(35.0))
        NSDivideRect(inRect, &slice, &remainder, CGFloat(0.0), .maxX)
        var expectedSlice = NSZeroRect
        var expectedRemainder = NSZeroRect
        XCTAssertEqual(slice, expectedSlice)
        XCTAssertEqual(remainder, expectedRemainder)

        // divide rect by MinX edge
        inRect = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(35.0))
        slice = NSZeroRect
        remainder = NSZeroRect
        NSDivideRect(inRect, &slice, &remainder, CGFloat(10.0), .minX)
        expectedSlice = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(10.0), CGFloat(35.0))
        expectedRemainder = NSMakeRect(CGFloat(10.0), CGFloat(-5.0), CGFloat(15.0), CGFloat(35.0))
        XCTAssertEqual(slice, expectedSlice)
        XCTAssertEqual(remainder, expectedRemainder)

        // divide rect by MinX edge with amount > width
        inRect = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(35.0))
        slice = NSZeroRect
        remainder = NSZeroRect
        NSDivideRect(inRect, &slice, &remainder, NSWidth(inRect) + CGFloat(1.0), .minX)
        expectedSlice = inRect
        expectedRemainder = NSMakeRect(CGFloat(25.0), CGFloat(-5.0), CGFloat(0.0), CGFloat(35.0))
        XCTAssertEqual(slice, expectedSlice)
        XCTAssertEqual(remainder, expectedRemainder)

        // divide rect by MinY edge
        inRect = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(35.0))
        slice = NSZeroRect
        remainder = NSZeroRect
        NSDivideRect(inRect, &slice, &remainder, CGFloat(10.0), .minY)
        expectedSlice = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(10.0))
        expectedRemainder = NSMakeRect(CGFloat(0.0), CGFloat(5.0), CGFloat(25.0), CGFloat(25.0))
        XCTAssertEqual(slice, expectedSlice)
        XCTAssertEqual(remainder, expectedRemainder)

        // divide rect by MinY edge with amount > height
        inRect = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(35.0))
        slice = NSZeroRect
        remainder = NSZeroRect
        NSDivideRect(inRect, &slice, &remainder, NSHeight(inRect) + CGFloat(1.0), .minY)
        expectedSlice = inRect
        expectedRemainder = NSMakeRect(CGFloat(0.0), CGFloat(30.0), CGFloat(25.0), CGFloat(0.0))
        XCTAssertEqual(slice, expectedSlice)
        XCTAssertEqual(remainder, expectedRemainder)

        // divide rect by MaxX edge
        inRect = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(35.0))
        slice = NSZeroRect
        remainder = NSZeroRect
        NSDivideRect(inRect, &slice, &remainder, CGFloat(10.0), .maxX)
        expectedSlice = NSMakeRect(CGFloat(15.0), CGFloat(-5.0), CGFloat(10.0), CGFloat(35.0))
        expectedRemainder = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(15.0), CGFloat(35.0))
        XCTAssertEqual(slice, expectedSlice)
        XCTAssertEqual(remainder, expectedRemainder)

        // divide rect by MaxX edge with amount > width
        inRect = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(35.0))
        slice = NSZeroRect
        remainder = NSZeroRect
        NSDivideRect(inRect, &slice, &remainder, NSWidth(inRect) + CGFloat(1.0), .maxX)
        expectedSlice = inRect
        expectedRemainder = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(0.0), CGFloat(35.0))
        XCTAssertEqual(slice, expectedSlice)
        XCTAssertEqual(remainder, expectedRemainder)

        // divide rect by MaxY edge
        inRect = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(35.0))
        slice = NSZeroRect
        remainder = NSZeroRect
        NSDivideRect(inRect, &slice, &remainder, CGFloat(10.0), .maxY)
        expectedSlice = NSMakeRect(CGFloat(0.0), CGFloat(20.0), CGFloat(25.0), CGFloat(10.0))
        expectedRemainder = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(25.0))
        XCTAssertEqual(slice, expectedSlice)
        XCTAssertEqual(remainder, expectedRemainder)

        // divide rect by MaxY edge with amount > height
        inRect = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(35.0))
        slice = NSZeroRect
        remainder = NSZeroRect
        NSDivideRect(inRect, &slice, &remainder, NSHeight(inRect) + CGFloat(1.0), .maxY)
        expectedSlice = inRect
        expectedRemainder = NSMakeRect(CGFloat(0.0), CGFloat(-5.0), CGFloat(25.0), CGFloat(0.0))
        XCTAssertEqual(slice, expectedSlice)
        XCTAssertEqual(remainder, expectedRemainder)
    }
    
    func test_EncodeToNSString() {
        let referenceRect = NSMakeRect(CGFloat(0.6), CGFloat(5.4), CGFloat(105.7), CGFloat(24.3))
        
        var expectedString = "{0.6, 5.4}"
        var string = NSStringFromPoint(referenceRect.origin)
        XCTAssertEqual(expectedString, string,
                       "\(string) is not equal to expected \(expectedString)")
        
        expectedString = "{105.7, 24.3}"
        string = NSStringFromSize(referenceRect.size)
        XCTAssertEqual(expectedString, string,
                       "\(string) is not equal to expected \(expectedString)")
        
        expectedString = "{{0.6, 5.4}, {105.7, 24.3}}"
        string = NSStringFromRect(referenceRect)
        XCTAssertEqual(expectedString, string,
                       "\(string) is not equal to expected \(expectedString)")
    }
    
    func test_EncodeNegativeToNSString() {
        let referenceNegativeRect = NSMakeRect(CGFloat(-0.6), CGFloat(-5.4), CGFloat(-105.7), CGFloat(-24.3))
        
        var expectedString = "{-0.6, -5.4}"
        var string = NSStringFromPoint(referenceNegativeRect.origin)
        XCTAssertEqual(expectedString, string,
                       "\(string) is not equal to expected \(expectedString)")
        
        expectedString = "{-105.7, -24.3}"
        string = NSStringFromSize(referenceNegativeRect.size)
        XCTAssertEqual(expectedString, string,
                       "\(string) is not equal to expected \(expectedString)")
        
        expectedString = "{{-0.6, -5.4}, {-105.7, -24.3}}"
        string = NSStringFromRect(referenceNegativeRect)
        XCTAssertEqual(expectedString, string,
                       "\(string) is not equal to expected \(expectedString)")
    }
    
    func test_DecodeFromNSString() {
        var stringPoint = "{0.6, 5.4}"
        var stringSize = "{105.7, 24.3}"
        var stringRect = "{{0.6, 5.4}, {105.7, 24.3}}"
        
        let expectedPoint = NSMakePoint(CGFloat(0.6), CGFloat(5.4))
        var point = NSPointFromString(stringPoint)
        XCTAssertTrue(_NSPoint(expectedPoint, equalsToPoint: point),
                       "\(NSStringFromPoint(point)) is not equal to expected \(NSStringFromPoint(expectedPoint))")
        
        let expectedSize = NSMakeSize(CGFloat(105.7), CGFloat(24.3))
        var size = NSSizeFromString(stringSize)
        XCTAssertTrue(_NSSize(expectedSize, equalsToSize: size),
                       "\(NSStringFromSize(size)) is not equal to expected \(NSStringFromSize(expectedSize))")
        
        let expectedRect = NSMakeRect(CGFloat(0.6), CGFloat(5.4), CGFloat(105.7), CGFloat(24.3))
        var rect = NSRectFromString(stringRect)
        XCTAssertTrue(_NSRect(expectedRect, equalsToRect: rect),
                       "\(NSStringFromRect(rect)) is not equal to expected \(NSStringFromRect(expectedRect))")
        
        // No spaces
        stringPoint = "{0.6,5.4}"
        stringSize = "{105.7,24.3}"
        stringRect = "{{0.6,5.4},{105.7,24.3}}"
        
        point = NSPointFromString(stringPoint)
        XCTAssertTrue(_NSPoint(expectedPoint, equalsToPoint: point),
                       "\(NSStringFromPoint(point)) is not equal to expected \(NSStringFromPoint(expectedPoint))")
        
        size = NSSizeFromString(stringSize)
        XCTAssertTrue(_NSSize(expectedSize, equalsToSize: size),
                       "\(NSStringFromSize(size)) is not equal to expected \(NSStringFromSize(expectedSize))")
        
        rect = NSRectFromString(stringRect)
        XCTAssertTrue(_NSRect(expectedRect, equalsToRect: rect),
                       "\(NSStringFromRect(rect)) is not equal to expected \(NSStringFromRect(expectedRect))")
        
        // Random spaces
        stringPoint = "{  0.6   , 5.4   }"
        stringSize = "{ 105.7, 24.3       }"
        stringRect = "{{0.6 , 5.4}   ,{105.7 ,24.3}}"
        
        point = NSPointFromString(stringPoint)
        XCTAssertTrue(_NSPoint(expectedPoint, equalsToPoint: point),
                       "\(NSStringFromPoint(point)) is not equal to expected \(NSStringFromPoint(expectedPoint))")
        
        size = NSSizeFromString(stringSize)
        XCTAssertTrue(_NSSize(expectedSize, equalsToSize: size),
                       "\(NSStringFromSize(size)) is not equal to expected \(NSStringFromSize(expectedSize))")
        
        rect = NSRectFromString(stringRect)
        XCTAssertTrue(_NSRect(expectedRect, equalsToRect: rect),
                       "\(NSStringFromRect(rect)) is not equal to expected \(NSStringFromRect(expectedRect))")
    
    }
    
    func test_DecodeEmptyStrings() {
        let stringPoint = ""
        let stringSize = ""
        let stringRect = ""
        
        let expectedPoint = NSZeroPoint
        let point = NSPointFromString(stringPoint)
        XCTAssertTrue(_NSPoint(expectedPoint, equalsToPoint: point),
                       "\(NSStringFromPoint(point)) is not equal to expected \(NSStringFromPoint(expectedPoint))")

        let expectedSize = NSZeroSize
        let size = NSSizeFromString(stringSize)
        XCTAssertTrue(_NSSize(expectedSize, equalsToSize: size),
                       "\(NSStringFromSize(size)) is not equal to expected \(NSStringFromSize(expectedSize))")
        
        let expectedRect = NSZeroRect
        let rect = NSRectFromString(stringRect)
        XCTAssertTrue(_NSRect(expectedRect, equalsToRect: rect),
                       "\(NSStringFromRect(rect)) is not equal to expected \(NSStringFromRect(expectedRect))")
    }
    
    func test_DecodeNegativeFromNSString() {
        let stringPoint = "{-0.6, -5.4}"
        let stringSize = "{-105.7, -24.3}"
        let stringRect = "{{-0.6, -5.4}, {-105.7, -24.3}}"
        
        let expectedPoint = NSMakePoint(CGFloat(-0.6), CGFloat(-5.4))
        let point = NSPointFromString(stringPoint)
        XCTAssertTrue(_NSPoint(expectedPoint, equalsToPoint: point),
            "\(NSStringFromPoint(point)) is not equal to expected \(NSStringFromPoint(expectedPoint))")
        
        let expectedSize = NSMakeSize(CGFloat(-105.7), CGFloat(-24.3))
        let size = NSSizeFromString(stringSize)
        XCTAssertTrue(_NSSize(expectedSize, equalsToSize: size),
                       "\(NSStringFromSize(size)) is not equal to expected \(NSStringFromSize(expectedSize))")
        
        let expectedRect = NSMakeRect(CGFloat(-0.6), CGFloat(-5.4), CGFloat(-105.7), CGFloat(-24.3))
        let rect = NSRectFromString(stringRect)
        XCTAssertTrue(_NSRect(expectedRect, equalsToRect: rect),
                       "\(NSStringFromRect(rect)) is not equal to expected \(NSStringFromRect(expectedRect))")
        
    }
    
    func test_DecodeGarbageFromNSString() {
        var stringRect = "-0.6a5.4das-105.7bfh24.3dfas;hk312}}"
        var expectedRect = NSMakeRect(CGFloat(-0.6), CGFloat(5.4), CGFloat(-105.7), CGFloat(24.3))
        var rect = NSRectFromString(stringRect)
        XCTAssertTrue(_NSRect(expectedRect, equalsToRect: rect),
                       "\(NSStringFromRect(rect)) is not equal to expected \(NSStringFromRect(expectedRect))")

        stringRect = "-0.6a5.4da}}"
        expectedRect = NSMakeRect(CGFloat(-0.6), CGFloat(5.4), CGFloat(0.0), CGFloat(0.0))
        rect = NSRectFromString(stringRect)
        XCTAssertTrue(_NSRect(expectedRect, equalsToRect: rect),
                       "\(NSStringFromRect(rect)) is not equal to expected \(NSStringFromRect(expectedRect))")

    }
    
    // MARK: Private
    
    func _NSRect(_ rect: NSRect, equalsToRect rect2: NSRect, withPrecision precision: CGFloat.NativeType = .ulpOfOne) -> Bool {
        return _NSPoint(rect.origin, equalsToPoint: rect2.origin, withPrecision: precision)
            && _NSSize(rect.size, equalsToSize: rect2.size, withPrecision: precision)
    }

    func _NSSize(_ size: NSSize, equalsToSize size2: NSSize, withPrecision precision: CGFloat.NativeType = .ulpOfOne) -> Bool {
        return _CGFloat(size.width, equalsToCGFloat: size2.width, withPrecision: precision)
            && _CGFloat(size.height, equalsToCGFloat: size2.height, withPrecision: precision)
    }

    func _NSPoint(_ point: NSPoint, equalsToPoint point2: NSPoint, withPrecision precision: CGFloat.NativeType = .ulpOfOne) -> Bool {
        return _CGFloat(point.x, equalsToCGFloat: point2.x, withPrecision: precision)
            && _CGFloat(point.y, equalsToCGFloat: point2.y, withPrecision: precision)
    }

    func _CGFloat(_ float: CGFloat, equalsToCGFloat float2: CGFloat, withPrecision precision: CGFloat.NativeType = .ulpOfOne) -> Bool {
        return fabs(float.native - float2.native) <= precision
    }

}
