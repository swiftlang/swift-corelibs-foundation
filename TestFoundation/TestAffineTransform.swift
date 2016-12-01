// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// RUN: rm -rf %t && mkdir %t
// RUN: cp %s %t/main.swift
// RUN: echo "TestAffineTransform.runAllTests()" >> %t/main.swift
// RUN: %target-build-swift %t/main.swift FoundationSupport/XCTStdlibStub.swift -o %t/test.out
// RUN: %target-run %t/test.out
// REQUIRES: executable_test
// REQUIRES: objc_interop

#if os(OSX) || DEPLOYMENT_RUNTIME_SWIFT

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#elseif DEPLOYMENT_RUNTIME_SWIFT
import SwiftFoundation
import SwiftXCTest
#endif

extension AffineTransform {
    func transform(_ aRect: NSRect) -> NSRect {
        return NSRect(origin: transform(aRect.origin), size: transform(aRect.size))
    }
}

class TestAffineTransform : XCTestCase {
    static var allTests: [(String, (TestAffineTransform) -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_IdentityTransformation", test_IdentityTransformation),
            ("test_Translation", test_Translation),
            ("test_Scale", test_Scale),
            ("test_Rotation_Degrees", test_Rotation_Degrees),
            ("test_Rotation_Radians", test_Rotation_Radians),
            ("test_Inversion", test_Inversion),
            ("test_TranslationComposed", test_TranslationComposed),
            ("test_Scaling", test_Scaling),
            ("test_TranslationScaling", test_TranslationScaling),
            ("test_ScalingTranslation", test_ScalingTranslation),
            ("test_AppendTransform", test_AppendTransform),
            ("test_PrependTransform", test_PrependTransform),
            ("test_TransformComposition", test_TransformComposition),
            ("test_hashing_identity", test_hashing_identity),
            ("test_hashing_values", test_hashing_values),
            ("test_AnyHashableContainingAffineTransform", test_AnyHashableContainingAffineTransform),
            ("test_AnyHashableCreatedFromNSAffineTransform", test_AnyHashableCreatedFromNSAffineTransform),
        ]
    }
    
    private let accuracyThreshold = 0.001
    
    func checkPointTransformation(_ transform: AffineTransform, point: NSPoint, expectedPoint: NSPoint, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        let newPoint = transform.transform(point)
        XCTAssertEqualWithAccuracy(Double(newPoint.x), Double(expectedPoint.x), accuracy: accuracyThreshold,
                                "x (expected: \(expectedPoint.x), was: \(newPoint.x)): \(message)", file: file, line: line)
        XCTAssertEqualWithAccuracy(Double(newPoint.y), Double(expectedPoint.y), accuracy: accuracyThreshold,
                                "y (expected: \(expectedPoint.y), was: \(newPoint.y)): \(message)", file: file, line: line)
    }
    
    func checkSizeTransformation(_ transform: AffineTransform, size: NSSize, expectedSize: NSSize, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        let newSize = transform.transform(size)
        XCTAssertEqualWithAccuracy(Double(newSize.width), Double(expectedSize.width), accuracy: accuracyThreshold,
                                "width (expected: \(expectedSize.width), was: \(newSize.width)): \(message)", file: file, line: line)
        XCTAssertEqualWithAccuracy(Double(newSize.height), Double(expectedSize.height), accuracy: accuracyThreshold,
                                "height (expected: \(expectedSize.height), was: \(newSize.height)): \(message)", file: file, line: line)
    }
    
    func checkRectTransformation(_ transform: AffineTransform, rect: NSRect, expectedRect: NSRect, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
        let newRect = transform.transform(rect)
        
        checkPointTransformation(transform, point: newRect.origin, expectedPoint: expectedRect.origin,
                                 "origin (expected: \(expectedRect.origin), was: \(newRect.origin)): \(message)", file: file, line: line)
        checkSizeTransformation(transform, size: newRect.size, expectedSize: expectedRect.size,
                                "size (expected: \(expectedRect.size), was: \(newRect.size)): \(message)", file: file, line: line)
    }
    
    func test_BasicConstruction() {
        let identityTransform = AffineTransform.identity
        
        // The diagonal entries (1,1) and (2,2) of the identity matrix are ones. The other entries are zeros.
        // TODO: These should use DBL_MAX but it's not available as part of Glibc on Linux
        XCTAssertEqualWithAccuracy(Double(identityTransform.m11), Double(1), accuracy: accuracyThreshold)
        XCTAssertEqualWithAccuracy(Double(identityTransform.m22), Double(1), accuracy: accuracyThreshold)
        
        XCTAssertEqualWithAccuracy(Double(identityTransform.m12), Double(0), accuracy: accuracyThreshold)
        XCTAssertEqualWithAccuracy(Double(identityTransform.m21), Double(0), accuracy: accuracyThreshold)
        XCTAssertEqualWithAccuracy(Double(identityTransform.tX), Double(0), accuracy: accuracyThreshold)
        XCTAssertEqualWithAccuracy(Double(identityTransform.tY), Double(0), accuracy: accuracyThreshold)
    }
    
    func test_IdentityTransformation() {
        let identityTransform = AffineTransform.identity
        
        func checkIdentityPointTransformation(_ point: NSPoint) {
            checkPointTransformation(identityTransform, point: point, expectedPoint: point)
        }
        
        checkIdentityPointTransformation(NSPoint())
        checkIdentityPointTransformation(NSPoint(x: CGFloat(24.5), y: CGFloat(10.0)))
        checkIdentityPointTransformation(NSPoint(x: CGFloat(-7.5), y: CGFloat(2.0)))
        
        func checkIdentitySizeTransformation(_ size: NSSize) {
            checkSizeTransformation(identityTransform, size: size, expectedSize: size)
        }
        
        checkIdentitySizeTransformation(NSSize())
        checkIdentitySizeTransformation(NSSize(width: CGFloat(13.0), height: CGFloat(12.5)))
        checkIdentitySizeTransformation(NSSize(width: CGFloat(100.0), height: CGFloat(-100.0)))
    }
    
    func test_Translation() {
        let point = NSPoint(x: CGFloat(0.0), y: CGFloat(0.0))
        
        var noop = AffineTransform.identity
        noop.translate(x: CGFloat(), y: CGFloat())
        checkPointTransformation(noop, point: point, expectedPoint: point)
        
        var translateH = AffineTransform.identity
        translateH.translate(x: CGFloat(10.0), y: CGFloat())
        checkPointTransformation(translateH, point: point, expectedPoint: NSPoint(x: CGFloat(10.0), y: CGFloat()))
        
        var translateV = AffineTransform.identity
        translateV.translate(x: CGFloat(), y: CGFloat(20.0))
        checkPointTransformation(translateV, point: point, expectedPoint: NSPoint(x: CGFloat(), y: CGFloat(20.0)))
        
        var translate = AffineTransform.identity
        translate.translate(x: CGFloat(-30.0), y: CGFloat(40.0))
        checkPointTransformation(translate, point: point, expectedPoint: NSPoint(x: CGFloat(-30.0), y: CGFloat(40.0)))
    }
    
    func test_Scale() {
        let size = NSSize(width: CGFloat(10.0), height: CGFloat(10.0))
        
        var noop = AffineTransform.identity
        noop.scale(CGFloat(1.0))
        checkSizeTransformation(noop, size: size, expectedSize: size)
        
        var shrink = AffineTransform.identity
        shrink.scale(CGFloat(0.5))
        checkSizeTransformation(shrink, size: size, expectedSize: NSSize(width: CGFloat(5.0), height: CGFloat(5.0)))
        
        var grow = AffineTransform.identity
        grow.scale(CGFloat(3.0))
        checkSizeTransformation(grow, size: size, expectedSize: NSSize(width: CGFloat(30.0), height: CGFloat(30.0)))
        
        var stretch = AffineTransform.identity
        stretch.scale(x: CGFloat(2.0), y: CGFloat(0.5))
        checkSizeTransformation(stretch, size: size, expectedSize: NSSize(width: CGFloat(20.0), height: CGFloat(5.0)))
    }
    
    func test_Rotation_Degrees() {
        let point = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        
        var noop = AffineTransform.identity
        noop.rotate(byDegrees: CGFloat())
        checkPointTransformation(noop, point: point, expectedPoint: point)
        
        var tenEighty = AffineTransform.identity
        tenEighty.rotate(byDegrees: CGFloat(1080.0))
        checkPointTransformation(tenEighty, point: point, expectedPoint: point)
        
        var rotateCounterClockwise = AffineTransform.identity
        rotateCounterClockwise.rotate(byDegrees: CGFloat(90.0))
        checkPointTransformation(rotateCounterClockwise, point: point, expectedPoint: NSPoint(x: CGFloat(-10.0), y: CGFloat(10.0)))
        
        var rotateClockwise = AffineTransform.identity
        rotateClockwise.rotate(byDegrees: CGFloat(-90.0))
        checkPointTransformation(rotateClockwise, point: point, expectedPoint: NSPoint(x: CGFloat(10.0), y: CGFloat(-10.0)))
        
        var reflectAboutOrigin = AffineTransform.identity
        reflectAboutOrigin.rotate(byDegrees: CGFloat(180.0))
        checkPointTransformation(reflectAboutOrigin, point: point, expectedPoint: NSPoint(x: CGFloat(-10.0), y: CGFloat(-10.0)))
    }
    
    func test_Rotation_Radians() {
        let point = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        
        var noop = AffineTransform.identity
        noop.rotate(byRadians: CGFloat())
        checkPointTransformation(noop, point: point, expectedPoint: point)
        
        var tenEighty = AffineTransform.identity
        tenEighty.rotate(byRadians: CGFloat(6 * M_PI))
        checkPointTransformation(tenEighty, point: point, expectedPoint: point)
        
        var rotateCounterClockwise = AffineTransform.identity
        rotateCounterClockwise.rotate(byRadians: CGFloat(M_PI_2))
        checkPointTransformation(rotateCounterClockwise, point: point, expectedPoint: NSPoint(x: CGFloat(-10.0), y: CGFloat(10.0)))
        
        var rotateClockwise = AffineTransform.identity
        rotateClockwise.rotate(byRadians: CGFloat(-M_PI_2))
        checkPointTransformation(rotateClockwise, point: point, expectedPoint: NSPoint(x: CGFloat(10.0), y: CGFloat(-10.0)))
        
        var reflectAboutOrigin = AffineTransform.identity
        reflectAboutOrigin.rotate(byRadians: CGFloat(M_PI))
        checkPointTransformation(reflectAboutOrigin, point: point, expectedPoint: NSPoint(x: CGFloat(-10.0), y: CGFloat(-10.0)))
    }
    
    func test_Inversion() {
        let point = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        
        var translate = AffineTransform.identity
        translate.translate(x: CGFloat(-30.0), y: CGFloat(40.0))
        
        var rotate = AffineTransform.identity
        translate.rotate(byDegrees: CGFloat(30.0))
        
        var scale = AffineTransform.identity
        scale.scale(CGFloat(2.0))
        
        var identityTransform = AffineTransform.identity
        
        // append transformations
        identityTransform.append(translate)
        identityTransform.append(rotate)
        identityTransform.append(scale)
        
        // invert transformations
        scale.invert()
        rotate.invert()
        translate.invert()
        
        // append inverse transformations in reverse order
        identityTransform.append(scale)
        identityTransform.append(rotate)
        identityTransform.append(translate)
        
        checkPointTransformation(identityTransform, point: point, expectedPoint: point)
    }
    
    func test_TranslationComposed() {
        var xyPlus5 = AffineTransform.identity
        xyPlus5.translate(x: CGFloat(2.0), y: CGFloat(3.0))
        xyPlus5.translate(x: CGFloat(3.0), y: CGFloat(2.0))
        
        checkPointTransformation(xyPlus5, point: NSPoint(x: CGFloat(-2.0), y: CGFloat(-3.0)),
                                 expectedPoint: NSPoint(x: CGFloat(3.0), y: CGFloat(2.0)))
    }
    
    func test_Scaling() {
        var xyTimes5 = AffineTransform.identity
        xyTimes5.scale(CGFloat(5.0))
        
        checkPointTransformation(xyTimes5, point: NSPoint(x: CGFloat(-2.0), y: CGFloat(3.0)),
                                 expectedPoint: NSPoint(x: CGFloat(-10.0), y: CGFloat(15.0)))
        
        var xTimes2YTimes3 = AffineTransform.identity
        xTimes2YTimes3.scale(x: CGFloat(2.0), y: CGFloat(-3.0))
        
        checkPointTransformation(xTimes2YTimes3, point: NSPoint(x: CGFloat(-1.0), y: CGFloat(3.5)),
                                 expectedPoint: NSPoint(x: CGFloat(-2.0), y: CGFloat(-10.5)))
    }
    
    func test_TranslationScaling() {
        var xPlus2XYTimes5 = AffineTransform.identity
        xPlus2XYTimes5.translate(x: CGFloat(2.0), y: CGFloat())
        xPlus2XYTimes5.scale(x: CGFloat(5.0), y: CGFloat(-5.0))
        
        checkPointTransformation(xPlus2XYTimes5, point: NSPoint(x: CGFloat(1.0), y: CGFloat(2.0)),
                                 expectedPoint: NSPoint(x: CGFloat(7.0), y: CGFloat(-10.0)))
    }
    
    func test_ScalingTranslation() {
        var xyTimes5XPlus3 = AffineTransform.identity
        xyTimes5XPlus3.scale(CGFloat(5.0))
        xyTimes5XPlus3.translate(x: CGFloat(3.0), y: CGFloat())
        
        checkPointTransformation(xyTimes5XPlus3, point: NSPoint(x: CGFloat(1.0), y: CGFloat(2.0)),
                                 expectedPoint: NSPoint(x: CGFloat(20.0), y: CGFloat(10.0)))
    }
    
    func test_AppendTransform() {
        let point = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        
        var identityTransform = AffineTransform.identity
        identityTransform.append(identityTransform)
        checkPointTransformation(identityTransform, point: point, expectedPoint: point)
        
        let translate = AffineTransform(translationByX: 10.0, byY: 0.0)
        
        let scale = AffineTransform(scale: 2.0)
        
        var translateThenScale = translate
        translateThenScale.append(scale)
        checkPointTransformation(translateThenScale, point: point, expectedPoint: NSPoint(x: CGFloat(40.0), y: CGFloat(20.0)))
    }
    
    func test_PrependTransform() {
        let point = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        
        var identityTransform = AffineTransform.identity
        identityTransform.append(identityTransform)
        checkPointTransformation(identityTransform, point: point, expectedPoint: point)
        
        let translate = AffineTransform(translationByX: 10.0, byY: 0.0)
        
        let scale = AffineTransform(scale: 2.0)
        
        var scaleThenTranslate = translate
        scaleThenTranslate.prepend(scale)
        checkPointTransformation(scaleThenTranslate, point: point, expectedPoint: NSPoint(x: CGFloat(30.0), y: CGFloat(20.0)))
    }
    
    func test_TransformComposition() {
        let origin = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        let size = NSSize(width: CGFloat(40.0), height: CGFloat(20.0))
        let rect = NSRect(origin: origin, size: size)
        let center = NSPoint(x: NSMidX(rect), y: NSMidY(rect))
        
        let rotate = AffineTransform(rotationByDegrees: 90.0)
        
        let moveOrigin = AffineTransform(translationByX: -center.x, byY: -center.y)
        
        var moveBack = moveOrigin
        moveBack.invert()
        
        var rotateAboutCenter = rotate
        rotateAboutCenter.prepend(moveOrigin)
        rotateAboutCenter.append(moveBack)
        
        // center of rect shouldn't move as its the rotation anchor
        checkPointTransformation(rotateAboutCenter, point: center, expectedPoint: center)
    }
    
    func test_hashing_identity() {
        let ref = NSAffineTransform()
        let val = AffineTransform.identity
        XCTAssertEqual(ref.hashValue, val.hashValue)
    }
    
    func test_hashing_values() {
        // the transforms are made up and the values don't matter
        let values = [
            AffineTransform(m11: 1.0, m12: 2.5, m21: 66.2, m22: 40.2, tX: -5.5, tY: 3.7),
            AffineTransform(m11: -55.66, m12: 22.7, m21: 1.5, m22: 0.0, tX: -22, tY: -33),
            AffineTransform(m11: 4.5, m12: 1.1, m21: 0.025, m22: 0.077, tX: -0.55, tY: 33.2),
            AffineTransform(m11: 7.0, m12: -2.3, m21: 6.7, m22: 0.25, tX: 0.556, tY: 0.99),
            AffineTransform(m11: 0.498, m12: -0.284, m21: -0.742, m22: 0.3248, tX: 12, tY: 44)
        ]
        for val in values {
            let ref = NSAffineTransform()
            ref.transformStruct = val
            XCTAssertEqual(ref.hashValue, val.hashValue)
        }
    }
    
    func test_AnyHashableContainingAffineTransform() {
        let values: [AffineTransform] = [
            AffineTransform.identity,
            AffineTransform(m11: -55.66, m12: 22.7, m21: 1.5, m22: 0.0, tX: -22, tY: -33),
            AffineTransform(m11: -55.66, m12: 22.7, m21: 1.5, m22: 0.0, tX: -22, tY: -33)
        ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(AffineTransform.self, type(of: anyHashables[0].base))
        XCTAssertSameType(AffineTransform.self, type(of: anyHashables[1].base))
        XCTAssertSameType(AffineTransform.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableCreatedFromNSAffineTransform() {
        func makeNSAffineTransform(rotatedByDegrees angle: CGFloat) -> NSAffineTransform {
            let result = NSAffineTransform()
            result.rotate(byDegrees: angle)
            return result
        }
        let values: [NSAffineTransform] = [
            makeNSAffineTransform(rotatedByDegrees: 0),
            makeNSAffineTransform(rotatedByDegrees: 10),
            makeNSAffineTransform(rotatedByDegrees: 10),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(AffineTransform.self, type(of: anyHashables[0].base))
        XCTAssertSameType(AffineTransform.self, type(of: anyHashables[1].base))
        XCTAssertSameType(AffineTransform.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}
#endif
