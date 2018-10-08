// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

private func assertEqual(_ rect: CGRect,
                         x: CGFloat,
                         y: CGFloat,
                         width: CGFloat,
                         height: CGFloat,
                         accuracy: CGFloat? = nil,
                         _ message: @autoclosure () -> String = "",
                         file: StaticString = #file,
                         line: UInt = #line) {

    if let accuracy = accuracy {
        XCTAssertEqual(rect.origin.x, x, accuracy: accuracy, message, file: file, line: line)
        XCTAssertEqual(rect.origin.y, y, accuracy: accuracy, message, file: file, line: line)
        XCTAssertEqual(rect.size.width, width, accuracy: accuracy, message, file: file, line: line)
        XCTAssertEqual(rect.size.height, height, accuracy: accuracy, message, file: file, line: line)
    } else {
        XCTAssertEqual(rect.origin.x, x, message, file: file, line: line)
        XCTAssertEqual(rect.origin.y, y, message, file: file, line: line)
        XCTAssertEqual(rect.size.width, width, message, file: file, line: line)
        XCTAssertEqual(rect.size.height, height, message, file: file, line: line)
    }
}

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
            ("test_CGRect_IsNull", test_CGRect_IsNull),
            ("test_CGRect_IsInfinite", test_CGRect_IsInfinite),
            ("test_CGRect_IsEmpty", test_CGRect_IsEmpty),
            ("test_CGRect_Equatable", test_CGRect_Equatable),
            ("test_CGRect_CalculatedGeometricProperties", test_CGRect_CalculatedGeometricProperties),
            ("test_CGRect_Standardized", test_CGRect_Standardized),
            ("test_CGRect_Integral", test_CGRect_Integral),
            ("test_CGRect_ContainsPoint", test_CGRect_ContainsPoint),
            ("test_CGRect_ContainsRect", test_CGRect_ContainsRect),
            ("test_CGRect_Union", test_CGRect_Union),
            ("test_CGRect_Intersection", test_CGRect_Intersection),
            ("test_CGRect_Intersects", test_CGRect_Intersects),
            ("test_CGRect_OffsetBy", test_CGRect_OffsetBy),
            ("test_CGRect_Divide", test_CGRect_Divide),
            ("test_CGRect_InsetBy", test_CGRect_InsetBy),
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

    func test_CGRect_IsNull() {
        XCTAssertTrue(CGRect.null.isNull)
        XCTAssertTrue(CGRect(x: CGFloat.infinity, y: CGFloat.infinity, width: 0, height: 0).isNull)
        XCTAssertTrue(CGRect(x: CGFloat.infinity, y: CGFloat.infinity, width: 10, height: 10).isNull)
        XCTAssertTrue(CGRect(x: CGFloat.infinity, y: CGFloat.infinity, width: -10, height: -10).isNull)
        XCTAssertTrue(CGRect(x: CGFloat.infinity, y: 0, width: 0, height: 0).isNull)
        XCTAssertTrue(CGRect(x: 0, y: CGFloat.infinity, width: 0, height: 0).isNull)
        XCTAssertFalse(CGRect(x: 0, y: 0, width: 0, height: 0).isNull)
    }

    func test_CGRect_IsInfinite() {
        XCTAssertTrue(CGRect.infinite.isInfinite)

        XCTAssertFalse(CGRect(x: 0,
                              y: CGRect.infinite.origin.y,
                              width: CGRect.infinite.size.width,
                              height: CGRect.infinite.size.height).isInfinite)

        XCTAssertFalse(CGRect(x: CGRect.infinite.origin.x,
                              y: 0,
                              width: CGRect.infinite.size.width,
                              height: CGRect.infinite.size.height).isInfinite)

        XCTAssertFalse(CGRect(x: CGRect.infinite.origin.x,
                              y: CGRect.infinite.origin.y,
                              width: 0,
                              height: CGRect.infinite.size.height).isInfinite)

        XCTAssertFalse(CGRect(x: CGRect.infinite.origin.x,
                              y: CGRect.infinite.origin.y,
                              width: CGRect.infinite.size.width,
                              height: 0).isInfinite)

        XCTAssertFalse(CGRect(x: CGFloat.infinity,
                              y: CGFloat.infinity,
                              width: CGFloat.infinity,
                              height: CGFloat.infinity).isInfinite)

        XCTAssertFalse(CGRect.null.isInfinite)
    }

    func test_CGRect_IsEmpty() {
        XCTAssertTrue(CGRect.zero.isEmpty)
        XCTAssertTrue(CGRect.null.isEmpty)
        XCTAssertTrue(CGRect(x: 10, y: 20, width: 30, height: 0).isEmpty)
        XCTAssertTrue(CGRect(x: 10, y: 20, width: 0, height: 30).isEmpty)
        XCTAssertTrue(CGRect(x: 10, y: 20, width: -30, height: 0).isEmpty)
        XCTAssertTrue(CGRect(x: 10, y: 20, width: 0, height: -30).isEmpty)

        var r1 = CGRect.null
        r1.origin.x = 0
        XCTAssertTrue(r1.isEmpty)

        var r2 = CGRect.null
        r2.origin.y = 0
        XCTAssertTrue(r2.isEmpty)

        var r3 = CGRect.null
        r3.size.width = 20
        XCTAssertTrue(r3.isEmpty)

        var r4 = CGRect.null
        r4.size.height = 20
        XCTAssertTrue(r4.isEmpty)

        var r5 = CGRect.null
        r5.size.width = 20
        r5.size.height = 20
        XCTAssertTrue(r5.isEmpty)

        XCTAssertFalse(CGRect.infinite.isEmpty)
        XCTAssertFalse(CGRect.infinite.isEmpty)
    }

    func test_CGRect_Equatable() {
        XCTAssertEqual(CGRect(x: 10, y: 20, width: 30, height: 40), CGRect(x: 10, y: 20, width: 30, height: 40))
        XCTAssertEqual(CGRect(x: -10, y: -20, width: -30, height: -40), CGRect(x: -10, y: -20, width: -30, height: -40))
        XCTAssertEqual(CGRect(x: -10, y: -20, width: 30, height: 40), CGRect(x: 20, y: 20, width: -30, height: -40))

        XCTAssertNotEqual(CGRect(x: 10, y: 20, width: 30, height: 40), CGRect(x: 10, y: 20, width: 30, height: -40))
        XCTAssertNotEqual(CGRect(x: 10, y: 20, width: 30, height: 40), CGRect(x: 10, y: 20, width: -30, height: 40))
        XCTAssertNotEqual(CGRect(x: 10, y: 20, width: 30, height: 40), CGRect(x: 10, y: -20, width: 30, height: 40))
        XCTAssertNotEqual(CGRect(x: 10, y: 20, width: 30, height: 40), CGRect(x: -10, y: 20, width: 30, height: 40))

        XCTAssertEqual(CGRect.infinite, CGRect.infinite)
        XCTAssertEqual(CGRect.null, CGRect.null)
        XCTAssertNotEqual(CGRect.infinite, CGRect.null)

        var r1 = CGRect.null
        r1.size = CGSize(width: 20, height: 20)
        XCTAssertEqual(r1, CGRect.null)

        var r2 = CGRect.null
        r2.origin.x = 20
        XCTAssertEqual(r2, CGRect.null)

        var r3 = CGRect.null
        r3.origin.y = 20
        XCTAssertEqual(r3, CGRect.null)

        var r4 = CGRect.null
        r4.origin = CGPoint(x: 10, y: 20)
        XCTAssertNotEqual(r4, CGRect.null)
    }

    func test_CGRect_CalculatedGeometricProperties() {
        let ε = CGFloat(0.00001)

        let r1 = CGRect(x: 1.2, y: 3.4, width: 5.6, height: 7.8)
        XCTAssertEqual(r1.width, 5.6, accuracy: ε)
        XCTAssertEqual(r1.height, 7.8, accuracy: ε)

        XCTAssertEqual(r1.minX, 1.2, accuracy: ε)
        XCTAssertEqual(r1.midX, 4, accuracy: ε)
        XCTAssertEqual(r1.maxX, 6.8, accuracy: ε)

        XCTAssertEqual(r1.minY, 3.4, accuracy: ε)
        XCTAssertEqual(r1.midY, 7.3, accuracy: ε)
        XCTAssertEqual(r1.maxY, 11.2, accuracy: ε)

        let r2 = CGRect(x: -1.2, y: -3.4, width: 5.6, height: 7.8)
        XCTAssertEqual(r2.width, 5.6, accuracy: ε)
        XCTAssertEqual(r2.height, 7.8, accuracy: ε)

        XCTAssertEqual(r2.minX, -1.2, accuracy: ε)
        XCTAssertEqual(r2.midX, 1.6, accuracy: ε)
        XCTAssertEqual(r2.maxX, 4.4, accuracy: ε)

        XCTAssertEqual(r2.minY, -3.4, accuracy: ε)
        XCTAssertEqual(r2.midY, 0.5, accuracy: ε)
        XCTAssertEqual(r2.maxY, 4.4, accuracy: ε)

        let r3 = CGRect(x: 1.2, y: 3.4, width: -5.6, height: -7.8)
        XCTAssertEqual(r3.width, 5.6, accuracy: ε)
        XCTAssertEqual(r3.height, 7.8, accuracy: ε)

        XCTAssertEqual(r3.minX, -4.4, accuracy: ε)
        XCTAssertEqual(r3.midX, -1.6, accuracy: ε)
        XCTAssertEqual(r3.maxX, 1.2, accuracy: ε)

        XCTAssertEqual(r3.minY, -4.4, accuracy: ε)
        XCTAssertEqual(r3.midY, -0.5, accuracy: ε)
        XCTAssertEqual(r3.maxY, 3.4, accuracy: ε)

        let r4 = CGRect(x: -1.2, y: -3.4, width: -5.6, height: -7.8)
        XCTAssertEqual(r4.width, 5.6, accuracy: ε)
        XCTAssertEqual(r4.height, 7.8, accuracy: ε)

        XCTAssertEqual(r4.minX, -6.8, accuracy: ε)
        XCTAssertEqual(r4.midX, -4.0, accuracy: ε)
        XCTAssertEqual(r4.maxX, -1.2, accuracy: ε)

        XCTAssertEqual(r4.minY, -11.2, accuracy: ε)
        XCTAssertEqual(r4.midY, -7.3, accuracy: ε)
        XCTAssertEqual(r4.maxY, -3.4, accuracy: ε)
    }

    func test_CGRect_Standardized() {
        let ε = CGFloat(0.00001)
        let nullX = CGRect.null.origin.x
        let nullY = CGRect.null.origin.y
        let nullWidth = CGRect.null.size.width
        let nullHeight = CGRect.null.size.height

        let r1 = CGRect(x: 1.9, y: 1.9, width: 10.1, height: 10.2).standardized
        assertEqual(r1, x: 1.9, y: 1.9, width: 10.1, height: 10.2, accuracy: ε)

        let r2 = CGRect(x: 1.9, y: 1.9, width: -10.1, height: -10.2).standardized
        assertEqual(r2, x: -8.2, y: -8.3, width: 10.1, height: 10.2, accuracy: ε)

        let r3 = CGRect(x: -1.9, y: -1.9, width: 10.1, height: 10.2).standardized
        assertEqual(r3, x: -1.9, y: -1.9, width: 10.1, height: 10.2, accuracy: ε)

        let r4 = CGRect(x: -1.9, y: -1.9, width: -10.1, height: -10.2).standardized
        assertEqual(r4, x: -12, y: -12.1, width: 10.1, height: 10.2, accuracy: ε)

        let r5 = CGRect.null.standardized
        assertEqual(r5, x: nullX, y: nullY, width: nullWidth, height: nullHeight)

        var r6 = CGRect.null
        r6.size = CGSize(width: 10, height: 20)
        r6 = r6.standardized
        assertEqual(r6, x: nullX, y: nullY, width: nullWidth, height: nullHeight)

        var r7 = CGRect.null
        r7.size = CGSize(width: -10, height: -20)
        r7 = r7.standardized
        assertEqual(r7, x: nullX, y: nullY, width: nullWidth, height: nullHeight)

        var r8 = CGRect.null
        r8.origin.x = 20
        r8 = r8.standardized
        assertEqual(r8, x: nullX, y: nullY, width: nullWidth, height: nullHeight)

        var r9 = CGRect.null
        r9.origin.y = 20
        r9 = r9.standardized
        assertEqual(r9, x: nullX, y: nullY, width: nullWidth, height: nullHeight)

        var r10 = CGRect.null
        r10.origin = CGPoint(x: 10, y: 20)
        r10 = r10.standardized
        assertEqual(r10, x: 10, y: 20, width: 0, height: 0)
    }

    func test_CGRect_Integral() {
        let ε = CGFloat(0.00001)

        let r1 = CGRect(x: 1.9, y: 1.9, width: 10.1, height: 10.2).integral
        XCTAssertEqual(r1.origin.x, 1, accuracy: ε)
        XCTAssertEqual(r1.origin.y, 1, accuracy: ε)
        XCTAssertEqual(r1.size.width, 11, accuracy: ε)
        XCTAssertEqual(r1.size.height, 12, accuracy: ε)

        let r2 = CGRect(x: 1.9, y: 1.9, width: -10.1, height: -10.2).integral
        XCTAssertEqual(r2.origin.x, -9, accuracy: ε)
        XCTAssertEqual(r2.origin.y, -9, accuracy: ε)
        XCTAssertEqual(r2.size.width, 11, accuracy: ε)
        XCTAssertEqual(r2.size.height, 11, accuracy: ε)

        let r3 = CGRect(x: -1.9, y: -1.9, width: 10.1, height: 10.2).integral
        XCTAssertEqual(r3.origin.x, -2, accuracy: ε)
        XCTAssertEqual(r3.origin.y, -2, accuracy: ε)
        XCTAssertEqual(r3.size.width, 11, accuracy: ε)
        XCTAssertEqual(r3.size.height, 11, accuracy: ε)

        let r4 = CGRect(x: -1.9, y: -1.9, width: -10.1, height: -10.2).integral
        XCTAssertEqual(r4.origin.x, -12, accuracy: ε)
        XCTAssertEqual(r4.origin.y, -13, accuracy: ε)
        XCTAssertEqual(r4.size.width, 11, accuracy: ε)
        XCTAssertEqual(r4.size.height, 12, accuracy: ε)

        let r5 = CGRect.null.integral
        XCTAssertEqual(r5.origin.x, CGRect.null.origin.x)
        XCTAssertEqual(r5.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(r5.size.width, CGRect.null.size.width)
        XCTAssertEqual(r5.size.height, CGRect.null.size.height)

        var r6 = CGRect.null
        r6.origin.x = 10
        r6.size = CGSize(width: -20, height: -30)
        r6 = r6.integral
        XCTAssertEqual(r6.origin.x, 10)
        XCTAssertEqual(r6.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(r6.size.width, -20)
        XCTAssertEqual(r6.size.height, -30)

        var r7 = CGRect.null
        r7.origin.y = 10
        r7.size = CGSize(width: -20, height: -30)
        r7 = r7.integral
        XCTAssertEqual(r7.origin.x, CGRect.null.origin.y)
        XCTAssertEqual(r7.origin.y, 10)
        XCTAssertEqual(r7.size.width, -20)
        XCTAssertEqual(r7.size.height, -30)

        var r8 = CGRect.null
        r8.origin = CGPoint(x: 10, y: 20)
        r8.size = CGSize(width: -30, height: -40)
        r8 = r8.integral
        XCTAssertEqual(r8.origin.x, -20)
        XCTAssertEqual(r8.origin.y, -20)
        XCTAssertEqual(r8.size.width, 30)
        XCTAssertEqual(r8.size.height, 40)
    }

    func test_CGRect_ContainsPoint() {
        XCTAssertFalse(CGRect.null.contains(CGPoint()))
        XCTAssertFalse(CGRect.zero.contains(CGPoint()))

        let r1 = CGRect(x: 5, y: 5, width: 10, height: 10)
        XCTAssertFalse(r1.contains(CGPoint(x: 1, y: 2)))
        XCTAssertFalse(r1.contains(CGPoint(x: 7, y: 2)))
        XCTAssertFalse(r1.contains(CGPoint(x: 2, y: 7)))
        XCTAssertFalse(r1.contains(CGPoint(x: -7, y: -7)))
        XCTAssertFalse(r1.contains(CGPoint(x: 15, y: 15)))
        XCTAssertTrue(r1.contains(CGPoint(x: 7, y: 7)))
        XCTAssertTrue(r1.contains(CGPoint(x: 10, y: 10)))
        XCTAssertTrue(r1.contains(CGPoint(x: 5, y: 5)))

        let r2 = CGRect(x: -5, y: -5, width: -10, height: -10)
        XCTAssertFalse(r2.contains(CGPoint(x: -1, y: -2)))
        XCTAssertFalse(r2.contains(CGPoint(x: -7, y: -2)))
        XCTAssertFalse(r2.contains(CGPoint(x: -2, y: -7)))
        XCTAssertFalse(r2.contains(CGPoint(x: 7, y: 7)))
        XCTAssertFalse(r2.contains(CGPoint(x: -5, y: -5)))
        XCTAssertTrue(r2.contains(CGPoint(x: -7, y: -7)))
        XCTAssertTrue(r2.contains(CGPoint(x: -10, y: -10)))
        XCTAssertTrue(r2.contains(CGPoint(x: -15, y: -15)))

        XCTAssertTrue(CGRect.infinite.contains(CGPoint()))
    }

    func test_CGRect_ContainsRect() {
        XCTAssertFalse(CGRect.zero.contains(.infinite))
        XCTAssertTrue(CGRect.zero.contains(.null))
        XCTAssertTrue(CGRect.zero.contains(CGRect.zero))
        XCTAssertFalse(CGRect.zero.contains(CGRect(x: -1.2, y: -3.4, width: 5.6, height: 7.8)))

        XCTAssertFalse(CGRect.null.contains(.infinite))
        XCTAssertTrue(CGRect.null.contains(.null))
        XCTAssertFalse(CGRect.null.contains(CGRect.zero))
        XCTAssertFalse(CGRect.null.contains(CGRect(x: -1.2, y: -3.4, width: 5.6, height: 7.8)))

        XCTAssertTrue(CGRect.infinite.contains(.infinite))
        XCTAssertTrue(CGRect.infinite.contains(.null))
        XCTAssertTrue(CGRect.infinite.contains(CGRect.zero))
        XCTAssertTrue(CGRect.infinite.contains(CGRect(x: -1.2, y: -3.4, width: 5.6, height: 7.8)))

        let r1 = CGRect(x: 10, y: 20, width: 30, height: 40)
        XCTAssertTrue(r1.contains(r1))

        let r2 = CGRect(x: -10, y: -20, width: -30, height: -40)
        XCTAssertTrue(r2.contains(r2))

        let r3 = CGRect(x: -10, y: -20, width: 30, height: 40)
        let r4 = CGRect(x: 20, y: 20, width: -30, height: -40)
        XCTAssertTrue(r3.contains(r4))

        let r5 = CGRect(x: -10, y: -10, width: 20, height: 20)
        let r6 = CGRect(x: -5, y: -5, width: 10, height: 10)
        XCTAssertTrue(r5.contains(r6))
        XCTAssertFalse(r6.contains(r5))
    }

    func test_CGRect_Union() {
        let r1 = CGRect.null
        let r2 = CGRect.null
        let u1 = r1.union(r2)
        XCTAssertEqual(u1.origin.x, CGRect.null.origin.x)
        XCTAssertEqual(u1.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(u1.size.width, CGRect.null.size.width)
        XCTAssertEqual(u1.size.height, CGRect.null.size.height)

        let r3 = CGRect.null
        var r4 = CGRect.null
        r4.size = CGSize(width: 10, height: 20)
        let u2 = r3.union(r4)
        XCTAssertEqual(u2.origin.x, r4.origin.x)
        XCTAssertEqual(u2.origin.y, r4.origin.y)
        XCTAssertEqual(u2.size.width, r4.size.width)
        XCTAssertEqual(u2.size.height, r4.size.height)

        let u3 = r4.union(r3)
        XCTAssertEqual(u3.origin.x, r3.origin.x)
        XCTAssertEqual(u3.origin.y, r3.origin.y)
        XCTAssertEqual(u3.size.width, r3.size.width)
        XCTAssertEqual(u3.size.height, r3.size.height)

        let r5 = CGRect(x: -1.2, y: -3.4, width: -5.6, height: -7.8)
        let r6 = CGRect(x: 1.2, y: 3.4, width: 5.6, height: 7.8)
        let u4 = r5.union(r6)
        XCTAssertEqual(u4.origin.x, -6.8)
        XCTAssertEqual(u4.origin.y, -11.2)
        XCTAssertEqual(u4.size.width, 13.6)
        XCTAssertEqual(u4.size.height, 22.4)

        let r7 = CGRect(x: 1, y: 2, width: 3, height: 4)
        let r8 = CGRect.infinite
        let u5 = r7.union(r8)
        XCTAssertEqual(u5.origin.x, r8.origin.x)
        XCTAssertEqual(u5.origin.y, r8.origin.y)
        XCTAssertEqual(u5.size.width, r8.size.width)
        XCTAssertEqual(u5.size.height, r8.size.height)
    }

    func test_CGRect_Intersection() {
        let r1 = CGRect(x: 10, y: 10, width: 50, height: 60)
        let r2 = CGRect(x: 25, y: 25, width: 60, height: 70)
        let i1 = r1.intersection(r2)
        XCTAssertEqual(i1.origin.x, 25)
        XCTAssertEqual(i1.origin.y, 25)
        XCTAssertEqual(i1.size.width, 35)
        XCTAssertEqual(i1.size.height, 45)

        let r3 = CGRect(x: 85, y: 95, width: -60, height: -70)
        let i2 = r1.intersection(r3)
        XCTAssertEqual(i2.origin.x, 25)
        XCTAssertEqual(i2.origin.y, 25)
        XCTAssertEqual(i2.size.width, 35)
        XCTAssertEqual(i2.size.height, 45)

        let r4 = CGRect(x: -10, y: -10, width: -30, height: -30)
        let i3 = r1.intersection(r4)
        XCTAssertEqual(i3.origin.x, CGRect.null.origin.x)
        XCTAssertEqual(i3.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(i3.size.width, CGRect.null.size.width)
        XCTAssertEqual(i3.size.height, CGRect.null.size.height)

        let r5 = CGRect.null
        let i4 = r1.intersection(r5)
        XCTAssertEqual(i4.origin.x, CGRect.null.origin.x)
        XCTAssertEqual(i4.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(i4.size.width, CGRect.null.size.width)
        XCTAssertEqual(i4.size.height, CGRect.null.size.height)

        let i5 = r5.intersection(r1)
        XCTAssertEqual(i5.origin.x, CGRect.null.origin.x)
        XCTAssertEqual(i5.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(i5.size.width, CGRect.null.size.width)
        XCTAssertEqual(i5.size.height, CGRect.null.size.height)

        var r6 = CGRect.null
        r6.size = CGSize(width: 10, height: 20)
        r6.origin.x = 30
        let i6 = r5.intersection(r6)
        XCTAssertEqual(i6.origin.x, CGRect.null.origin.x)
        XCTAssertEqual(i6.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(i6.size.width, CGRect.null.size.width)
        XCTAssertEqual(i6.size.height, CGRect.null.size.height)

        let i7 = r1.intersection(.infinite)
        XCTAssertEqual(i7.origin.x, r1.origin.x)
        XCTAssertEqual(i7.origin.y, r1.origin.y)
        XCTAssertEqual(i7.size.width, r1.size.width)
        XCTAssertEqual(i7.size.height, r1.size.height)

        let i8 = CGRect.infinite.intersection(.infinite)
        XCTAssertEqual(i8.origin.x, CGRect.infinite.origin.x)
        XCTAssertEqual(i8.origin.y, CGRect.infinite.origin.y)
        XCTAssertEqual(i8.size.width, CGRect.infinite.size.width)
        XCTAssertEqual(i8.size.height, CGRect.infinite.size.height)

        let r7 = CGRect(x: -10, y: -10, width: 20, height: 20)
        let i9 = r7.intersection(.zero)
        XCTAssertEqual(i9.origin.x, 0)
        XCTAssertEqual(i9.origin.y, 0)
        XCTAssertEqual(i9.size.width, 0)
        XCTAssertEqual(i9.size.height, 0)
    }

    func test_CGRect_Intersects() {
        let r1 = CGRect(x: 10, y: 10, width: 50, height: 60)
        let r2 = CGRect(x: 25, y: 25, width: 60, height: 70)
        XCTAssertTrue(r1.intersects(r2))

        let r3 = CGRect(x: 85, y: 95, width: -60, height: -70)
        XCTAssertTrue(r1.intersects(r3))

        let r4 = CGRect(x: -10, y: -10, width: -30, height: -30)
        XCTAssertFalse(r1.intersects(r4))

        let r5 = CGRect.null
        XCTAssertFalse(r1.intersects(r5))
        XCTAssertFalse(r5.intersects(r1))

        var r6 = CGRect.null
        r6.size = CGSize(width: 10, height: 20)
        r6.origin.x = 30
        XCTAssertFalse(r5.intersects(r6))

        XCTAssertTrue(r1.intersects(.infinite))

        XCTAssertTrue(CGRect.infinite.intersects(.infinite))

        let r7 = CGRect(x: -10, y: -10, width: 20, height: 20)
        XCTAssertTrue(r7.intersects(.zero))
    }

    func test_CGRect_OffsetBy() {
        var r1 = CGRect.null
        r1.size = CGSize(width: 10, height: 20)
        r1.origin.x = 30
        let o1 = r1.offsetBy(dx: 40, dy: 50)
        XCTAssertEqual(o1.origin.x, r1.origin.x)
        XCTAssertEqual(o1.origin.y, r1.origin.y)
        XCTAssertEqual(o1.size.width, r1.size.width)
        XCTAssertEqual(o1.size.height, r1.size.height)

        var r2 = CGRect.null
        r2.size = CGSize(width: 10, height: 20)
        r2.origin.y = 30
        let o2 = r2.offsetBy(dx: 40, dy: 50)
        XCTAssertEqual(o2.origin.x, r2.origin.x)
        XCTAssertEqual(o2.origin.y, r2.origin.y)
        XCTAssertEqual(o2.size.width, r2.size.width)
        XCTAssertEqual(o2.size.height, r2.size.height)

        let o3 = CGRect(x: 1.2, y: 3.4, width: 5.6, height: 7.8).offsetBy(dx: 10.5, dy: 20.5)
        XCTAssertEqual(o3.origin.x, 11.7)
        XCTAssertEqual(o3.origin.y, 23.9)
        XCTAssertEqual(o3.size.width, 5.6)
        XCTAssertEqual(o3.size.height, 7.8)

        let o4 = CGRect(x: -1.2, y: -3.4, width: -5.6, height: -7.8).offsetBy(dx: -10.5, dy: -20.5)
        XCTAssertEqual(o4.origin.x, -17.3)
        XCTAssertEqual(o4.origin.y, -31.7)
        XCTAssertEqual(o4.size.width, 5.6)
        XCTAssertEqual(o4.size.height, 7.8)
    }

    func test_CGRect_Divide() {
        let r1 = CGRect(x: 10, y: 20, width: 30, height: 40)
        let d1 = r1.divided(atDistance: 10, from: .minXEdge)
        XCTAssertEqual(d1.slice.origin.x, 10)
        XCTAssertEqual(d1.slice.origin.y, 20)
        XCTAssertEqual(d1.slice.size.width, 10)
        XCTAssertEqual(d1.slice.size.height, 40)
        XCTAssertEqual(d1.remainder.origin.x, 20)
        XCTAssertEqual(d1.remainder.origin.y, 20)
        XCTAssertEqual(d1.remainder.size.width, 20)
        XCTAssertEqual(d1.remainder.size.height, 40)

        let d2 = r1.divided(atDistance: 10, from: .maxXEdge)
        XCTAssertEqual(d2.slice.origin.x, 30)
        XCTAssertEqual(d2.slice.origin.y, 20)
        XCTAssertEqual(d2.slice.size.width, 10)
        XCTAssertEqual(d2.slice.size.height, 40)
        XCTAssertEqual(d2.remainder.origin.x, 10)
        XCTAssertEqual(d2.remainder.origin.y, 20)
        XCTAssertEqual(d2.remainder.size.width, 20)
        XCTAssertEqual(d2.remainder.size.height, 40)

        let d3 = r1.divided(atDistance: 10, from: .minYEdge)
        XCTAssertEqual(d3.slice.origin.x, 10)
        XCTAssertEqual(d3.slice.origin.y, 20)
        XCTAssertEqual(d3.slice.size.width, 30)
        XCTAssertEqual(d3.slice.size.height, 10)
        XCTAssertEqual(d3.remainder.origin.x, 10)
        XCTAssertEqual(d3.remainder.origin.y, 30)
        XCTAssertEqual(d3.remainder.size.width, 30)
        XCTAssertEqual(d3.remainder.size.height, 30)

        let d4 = r1.divided(atDistance: 10, from: .maxYEdge)
        XCTAssertEqual(d4.slice.origin.x, 10)
        XCTAssertEqual(d4.slice.origin.y, 50)
        XCTAssertEqual(d4.slice.size.width, 30)
        XCTAssertEqual(d4.slice.size.height, 10)
        XCTAssertEqual(d4.remainder.origin.x, 10)
        XCTAssertEqual(d4.remainder.origin.y, 20)
        XCTAssertEqual(d4.remainder.size.width, 30)
        XCTAssertEqual(d4.remainder.size.height, 30)

        let d5 = r1.divided(atDistance: 31, from: .minXEdge)
        XCTAssertEqual(d5.slice.origin.x, 10)
        XCTAssertEqual(d5.slice.origin.y, 20)
        XCTAssertEqual(d5.slice.size.width, 30)
        XCTAssertEqual(d5.slice.size.height, 40)
        XCTAssertEqual(d5.remainder.origin.x, 40)
        XCTAssertEqual(d5.remainder.origin.y, 20)
        XCTAssertEqual(d5.remainder.size.width, 0)
        XCTAssertEqual(d5.remainder.size.height, 40)

        let d6 = r1.divided(atDistance: 31, from: .maxXEdge)
        XCTAssertEqual(d6.slice.origin.x, 10)
        XCTAssertEqual(d6.slice.origin.y, 20)
        XCTAssertEqual(d6.slice.size.width, 30)
        XCTAssertEqual(d6.slice.size.height, 40)
        XCTAssertEqual(d6.remainder.origin.x, 10)
        XCTAssertEqual(d6.remainder.origin.y, 20)
        XCTAssertEqual(d6.remainder.size.width, 0)
        XCTAssertEqual(d6.remainder.size.height, 40)

        let d7 = r1.divided(atDistance: 41, from: .minYEdge)
        XCTAssertEqual(d7.slice.origin.x, 10)
        XCTAssertEqual(d7.slice.origin.y, 20)
        XCTAssertEqual(d7.slice.size.width, 30)
        XCTAssertEqual(d7.slice.size.height, 40)
        XCTAssertEqual(d7.remainder.origin.x, 10)
        XCTAssertEqual(d7.remainder.origin.y, 60)
        XCTAssertEqual(d7.remainder.size.width, 30)
        XCTAssertEqual(d7.remainder.size.height, 0)

        let d8 = r1.divided(atDistance: 41, from: .maxYEdge)
        XCTAssertEqual(d8.slice.origin.x, 10)
        XCTAssertEqual(d8.slice.origin.y, 20)
        XCTAssertEqual(d8.slice.size.width, 30)
        XCTAssertEqual(d8.slice.size.height, 40)
        XCTAssertEqual(d8.remainder.origin.x, 10)
        XCTAssertEqual(d8.remainder.origin.y, 20)
        XCTAssertEqual(d8.remainder.size.width, 30)
        XCTAssertEqual(d8.remainder.size.height, 0)

        let d9 = CGRect(x: -10, y: -20, width: -30, height: -40).divided(atDistance: 10, from: .minXEdge)
        XCTAssertEqual(d9.slice.origin.x, -40)
        XCTAssertEqual(d9.slice.origin.y, -60)
        XCTAssertEqual(d9.slice.size.width, 10)
        XCTAssertEqual(d9.slice.size.height, 40)
        XCTAssertEqual(d9.remainder.origin.x, -30)
        XCTAssertEqual(d9.remainder.origin.y, -60)
        XCTAssertEqual(d9.remainder.size.width, 20)
        XCTAssertEqual(d9.remainder.size.height, 40)

        var r2 = CGRect.null
        r2.size = CGSize(width: 10, height: 20)
        r2.origin.x = 30
        let d10 = r2.divided(atDistance: 10, from: .minXEdge)
        XCTAssertEqual(d10.slice.origin.x, CGRect.null.origin.x)
        XCTAssertEqual(d10.slice.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(d10.slice.size.width, CGRect.null.size.width)
        XCTAssertEqual(d10.slice.size.height, CGRect.null.size.height)
        XCTAssertEqual(d10.remainder.origin.x, CGRect.null.origin.x)
        XCTAssertEqual(d10.remainder.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(d10.remainder.size.width, CGRect.null.size.width)
        XCTAssertEqual(d10.remainder.size.height, CGRect.null.size.height)

        var r3 = CGRect.null
        r3.size = CGSize(width: 10, height: 20)
        r3.origin.y = 30
        let d11 = r3.divided(atDistance: 10, from: .minXEdge)
        XCTAssertEqual(d11.slice.origin.x, CGRect.null.origin.x)
        XCTAssertEqual(d11.slice.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(d11.slice.size.width, CGRect.null.size.width)
        XCTAssertEqual(d11.slice.size.height, CGRect.null.size.height)
        XCTAssertEqual(d11.remainder.origin.x, CGRect.null.origin.x)
        XCTAssertEqual(d11.remainder.origin.y, CGRect.null.origin.y)
        XCTAssertEqual(d11.remainder.size.width, CGRect.null.size.width)
        XCTAssertEqual(d11.remainder.size.height, CGRect.null.size.height)
    }

    func test_CGRect_InsetBy() {
        let ε = CGFloat(0.00001)
        let nullX = CGRect.null.origin.x
        let nullY = CGRect.null.origin.y
        let nullWidth = CGRect.null.size.width
        let nullHeight = CGRect.null.size.height

        let r1 = CGRect(x: 1.2, y: 3.4, width: 5.6, height: 7.8)
        assertEqual(r1.insetBy(dx: 2.8, dy: 0), x: 4, y: 3.4, width: 0, height: 7.8, accuracy: ε)
        assertEqual(r1.insetBy(dx: 0, dy: 3.9), x: 1.2, y: 7.3, width: 5.6, height: 0, accuracy: ε)
        assertEqual(r1.insetBy(dx: 10, dy: 10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r1.insetBy(dx: 10, dy: -10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r1.insetBy(dx: -10, dy: 10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r1.insetBy(dx: -10, dy: -10), x: -8.8, y: -6.6, width: 25.6, height: 27.8, accuracy: ε)

        let r2 = CGRect(x: 1.2, y: 3.4, width: -5.6, height: -7.8)
        assertEqual(r2.insetBy(dx: 2.8, dy: 0), x: -1.6, y: -4.4, width: 0, height: 7.8, accuracy: ε)
        assertEqual(r2.insetBy(dx: 0, dy: 3.9), x: -4.4, y: -0.5, width: 5.6, height: 0, accuracy: ε)
        assertEqual(r2.insetBy(dx: 10, dy: 10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r2.insetBy(dx: 10, dy: -10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r2.insetBy(dx: -10, dy: 10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r2.insetBy(dx: -10, dy: -10), x: -14.4, y: -14.4, width: 25.6, height: 27.8, accuracy: ε)

        let r3 = CGRect(x: -1.2, y: -3.4, width: 5.6, height: 7.8)
        assertEqual(r3.insetBy(dx: 2.8, dy: 0), x: 1.6, y: -3.4, width: 0, height: 7.8, accuracy: ε)
        assertEqual(r3.insetBy(dx: 0, dy: 3.9), x: -1.2, y: 0.5, width: 5.6, height: 0, accuracy: ε)
        assertEqual(r3.insetBy(dx: 10, dy: 10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r3.insetBy(dx: 10, dy: -10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r3.insetBy(dx: -10, dy: 10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r3.insetBy(dx: -10, dy: -10), x: -11.2, y: -13.4, width: 25.6, height: 27.8, accuracy: ε)

        let r4 = CGRect(x: -1.2, y: -3.4, width: -5.6, height: -7.8)
        assertEqual(r4.insetBy(dx: 2.8, dy: 0), x: -4, y: -11.2, width: 0, height: 7.8, accuracy: ε)
        assertEqual(r4.insetBy(dx: 0, dy: 3.9), x: -6.8, y: -7.3, width: 5.6, height: 0, accuracy: ε)
        assertEqual(r4.insetBy(dx: 10, dy: 10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r4.insetBy(dx: 10, dy: -10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r4.insetBy(dx: -10, dy: 10), x: nullX, y: nullY, width: nullWidth, height: nullHeight)
        assertEqual(r4.insetBy(dx: -10, dy: -10), x: -16.8, y: -21.2, width: 25.6, height: 27.8, accuracy: ε)

        var r5 = CGRect.null
        r5.size = CGSize(width: 10, height: 20)
        r5.origin.x = 30
        let i1 = r5.insetBy(dx: 50, dy: 60)
        XCTAssertEqual(i1.origin.x, 30)
        XCTAssertEqual(i1.origin.y, r5.origin.y)
        XCTAssertEqual(i1.size.width, 10)
        XCTAssertEqual(i1.size.height, 20)

        var r6 = CGRect.null
        r6.size = CGSize(width: 10, height: 20)
        r6.origin.y = 30
        let i2 = r6.insetBy(dx: 50, dy: 60)
        XCTAssertEqual(i2.origin.x, r6.origin.x)
        XCTAssertEqual(i2.origin.y, 30)
        XCTAssertEqual(i2.size.width, 10)
        XCTAssertEqual(i2.size.height, 20)
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
