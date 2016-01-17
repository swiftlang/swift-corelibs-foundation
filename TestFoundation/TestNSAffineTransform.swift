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


class TestNSAffineTransform : XCTestCase {
    private let accuracyThreshold = 0.001

    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_IdentityTransformation", test_IdentityTransformation),
            ("test_Scale", test_Scale),
            ("test_Scaling", test_Scaling),
            ("test_TranslationScaling", test_TranslationScaling),
            ("test_ScalingTranslation", test_ScalingTranslation),
            ("test_Rotation_Degrees", test_Rotation_Degrees),
            ("test_Rotation_Radians", test_Rotation_Radians),
            ("test_Inversion", test_Inversion),
            ("test_IdentityTransformation", test_IdentityTransformation),
            ("test_Translation", test_Translation),
            ("test_TranslationComposed", test_TranslationComposed),
            ("test_AppendTransform", test_AppendTransform),
            ("test_PrependTransform", test_PrependTransform),
            ("test_TransformComposition", test_TransformComposition),
        ]
    }
    
    func checkPointTransformation(transform: NSAffineTransform, point: NSPoint, expectedPoint: NSPoint, _ message: String = "", file: StaticString = __FILE__, line: UInt = __LINE__) {
        let newPoint = transform.transformPoint(point)
        XCTAssertEqualWithAccuracy(Double(newPoint.x), Double(expectedPoint.x), accuracy: accuracyThreshold, file: file, line: line,
                                   "x (expected: \(expectedPoint.x), was: \(newPoint.x)): \(message)")
        XCTAssertEqualWithAccuracy(Double(newPoint.y), Double(expectedPoint.y), accuracy: accuracyThreshold, file: file, line: line,
                                   "y (expected: \(expectedPoint.y), was: \(newPoint.y)): \(message)")
    }
    
    func checkSizeTransformation(transform: NSAffineTransform, size: NSSize, expectedSize: NSSize, _ message: String = "", file: StaticString = __FILE__, line: UInt = __LINE__) {
        let newSize = transform.transformSize(size)
        XCTAssertEqualWithAccuracy(Double(newSize.width), Double(expectedSize.width), accuracy: accuracyThreshold, file: file, line: line,
                                   "width (expected: \(expectedSize.width), was: \(newSize.width)): \(message)")
        XCTAssertEqualWithAccuracy(Double(newSize.height), Double(expectedSize.height), accuracy: accuracyThreshold, file: file, line: line,
                                   "height (expected: \(expectedSize.height), was: \(newSize.height)): \(message)")
    }
    
    func checkRectTransformation(transform: NSAffineTransform, rect: NSRect, expectedRect: NSRect, _ message: String = "", file: StaticString = __FILE__, line: UInt = __LINE__) {
        let newRect = transform.transformRect(rect)
        
        checkPointTransformation(transform, point: newRect.origin, expectedPoint: expectedRect.origin, file: file, line: line,
                                 "origin (expected: \(expectedRect.origin), was: \(newRect.origin)): \(message)")
        checkSizeTransformation(transform, size: newRect.size, expectedSize: expectedRect.size, file: file, line: line,
                                "size (expected: \(expectedRect.size), was: \(newRect.size)): \(message)")
    }

    func test_BasicConstruction() {
        let identityTransform = NSAffineTransform()
        let transformStruct = identityTransform.transformStruct

        // The diagonal entries (1,1) and (2,2) of the identity matrix are ones. The other entries are zeros.
        // TODO: These should use DBL_MAX but it's not available as part of Glibc on Linux
        XCTAssertEqualWithAccuracy(Double(transformStruct.m11), Double(1), accuracy: accuracyThreshold)
        XCTAssertEqualWithAccuracy(Double(transformStruct.m22), Double(1), accuracy: accuracyThreshold)

        XCTAssertEqualWithAccuracy(Double(transformStruct.m12), Double(0), accuracy: accuracyThreshold)
        XCTAssertEqualWithAccuracy(Double(transformStruct.m21), Double(0), accuracy: accuracyThreshold)
        XCTAssertEqualWithAccuracy(Double(transformStruct.tX), Double(0), accuracy: accuracyThreshold)
        XCTAssertEqualWithAccuracy(Double(transformStruct.tY), Double(0), accuracy: accuracyThreshold)
    }

    func test_IdentityTransformation() {
        let identityTransform = NSAffineTransform()

        func checkIdentityPointTransformation(point: NSPoint) {
            checkPointTransformation(identityTransform, point: point, expectedPoint: point)
        }
        
        checkIdentityPointTransformation(NSPoint())
        checkIdentityPointTransformation(NSMakePoint(CGFloat(24.5), CGFloat(10.0)))
        checkIdentityPointTransformation(NSMakePoint(CGFloat(-7.5), CGFloat(2.0)))

        func checkIdentitySizeTransformation(size: NSSize) {
            checkSizeTransformation(identityTransform, size: size, expectedSize: size)
        }

        checkIdentitySizeTransformation(NSSize())
        checkIdentitySizeTransformation(NSMakeSize(CGFloat(13.0), CGFloat(12.5)))
        checkIdentitySizeTransformation(NSMakeSize(CGFloat(100.0), CGFloat(-100.0)))
    }
    
    func test_Translation() {
        let point = NSPoint(x: CGFloat(0.0), y: CGFloat(0.0))

        let noop = NSAffineTransform()
        noop.translateXBy(CGFloat(), yBy: CGFloat())
        checkPointTransformation(noop, point: point, expectedPoint: point)
        
        let translateH = NSAffineTransform()
        translateH.translateXBy(CGFloat(10.0), yBy: CGFloat())
        checkPointTransformation(translateH, point: point, expectedPoint: NSPoint(x: CGFloat(10.0), y: CGFloat()))
        
        let translateV = NSAffineTransform()
        translateV.translateXBy(CGFloat(), yBy: CGFloat(20.0))
        checkPointTransformation(translateV, point: point, expectedPoint: NSPoint(x: CGFloat(), y: CGFloat(20.0)))
        
        let translate = NSAffineTransform()
        translate.translateXBy(CGFloat(-30.0), yBy: CGFloat(40.0))
        checkPointTransformation(translate, point: point, expectedPoint: NSPoint(x: CGFloat(-30.0), y: CGFloat(40.0)))
    }
    
    func test_Scale() {
        let size = NSSize(width: CGFloat(10.0), height: CGFloat(10.0))
        
        let noop = NSAffineTransform()
        noop.scaleBy(CGFloat(1.0))
        checkSizeTransformation(noop, size: size, expectedSize: size)
        
        let shrink = NSAffineTransform()
        shrink.scaleBy(CGFloat(0.5))
        checkSizeTransformation(shrink, size: size, expectedSize: NSSize(width: CGFloat(5.0), height: CGFloat(5.0)))
        
        let grow = NSAffineTransform()
        grow.scaleBy(CGFloat(3.0))
        checkSizeTransformation(grow, size: size, expectedSize: NSSize(width: CGFloat(30.0), height: CGFloat(30.0)))
        
        let stretch = NSAffineTransform()
        stretch.scaleXBy(CGFloat(2.0), yBy: CGFloat(0.5))
        checkSizeTransformation(stretch, size: size, expectedSize: NSSize(width: CGFloat(20.0), height: CGFloat(5.0)))
    }
    
    func test_Rotation_Degrees() {
        let point = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        
        let noop = NSAffineTransform()
        noop.rotateByDegrees(CGFloat())
        checkPointTransformation(noop, point: point, expectedPoint: point)
        
        let tenEighty = NSAffineTransform()
        tenEighty.rotateByDegrees(CGFloat(1080.0))
        checkPointTransformation(tenEighty, point: point, expectedPoint: point)
        
        let rotateCounterClockwise = NSAffineTransform()
        rotateCounterClockwise.rotateByDegrees(CGFloat(90.0))
        checkPointTransformation(rotateCounterClockwise, point: point, expectedPoint: NSPoint(x: CGFloat(-10.0), y: CGFloat(10.0)))
        
        let rotateClockwise = NSAffineTransform()
        rotateClockwise.rotateByDegrees(CGFloat(-90.0))
        checkPointTransformation(rotateClockwise, point: point, expectedPoint: NSPoint(x: CGFloat(10.0), y: CGFloat(-10.0)))
        
        let reflectAboutOrigin = NSAffineTransform()
        reflectAboutOrigin.rotateByDegrees(CGFloat(180.0))
        checkPointTransformation(reflectAboutOrigin, point: point, expectedPoint: NSPoint(x: CGFloat(-10.0), y: CGFloat(-10.0)))
    }
    
    func test_Rotation_Radians() {
        let point = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        
        let noop = NSAffineTransform()
        noop.rotateByRadians(CGFloat())
        checkPointTransformation(noop, point: point, expectedPoint: point)
        
        let tenEighty = NSAffineTransform()
        tenEighty.rotateByRadians(CGFloat(6 * M_PI))
        checkPointTransformation(tenEighty, point: point, expectedPoint: point)
        
        let rotateCounterClockwise = NSAffineTransform()
        rotateCounterClockwise.rotateByRadians(CGFloat(M_PI_2))
        checkPointTransformation(rotateCounterClockwise, point: point, expectedPoint: NSPoint(x: CGFloat(-10.0), y: CGFloat(10.0)))
        
        let rotateClockwise = NSAffineTransform()
        rotateClockwise.rotateByRadians(CGFloat(-M_PI_2))
        checkPointTransformation(rotateClockwise, point: point, expectedPoint: NSPoint(x: CGFloat(10.0), y: CGFloat(-10.0)))
        
        let reflectAboutOrigin = NSAffineTransform()
        reflectAboutOrigin.rotateByRadians(CGFloat(M_PI))
        checkPointTransformation(reflectAboutOrigin, point: point, expectedPoint: NSPoint(x: CGFloat(-10.0), y: CGFloat(-10.0)))
    }
    
    func test_Inversion() {
        let point = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        
        let translate = NSAffineTransform()
        translate.translateXBy(CGFloat(-30.0), yBy: CGFloat(40.0))
        
        let rotate = NSAffineTransform()
        translate.rotateByDegrees(CGFloat(30.0))
        
        let scale = NSAffineTransform()
        scale.scaleBy(CGFloat(2.0))
        
        let identityTransform = NSAffineTransform()
        
        // append transformations
        identityTransform.appendTransform(translate)
        identityTransform.appendTransform(rotate)
        identityTransform.appendTransform(scale)
        
        // invert transformations
        scale.invert()
        rotate.invert()
        translate.invert()
        
        // append inverse transformations in reverse order
        identityTransform.appendTransform(scale)
        identityTransform.appendTransform(rotate)
        identityTransform.appendTransform(translate)
        
        checkPointTransformation(identityTransform, point: point, expectedPoint: point)
    }

    func test_TranslationComposed() {
        let xyPlus5 = NSAffineTransform()
        xyPlus5.translateXBy(CGFloat(2.0), yBy: CGFloat(3.0))
        xyPlus5.translateXBy(CGFloat(3.0), yBy: CGFloat(2.0))

        checkPointTransformation(xyPlus5, point: NSMakePoint(CGFloat(-2.0), CGFloat(-3.0)),
                                  expectedPoint: NSMakePoint(CGFloat(3.0), CGFloat(2.0)))
    }

    func test_Scaling() {
        let xyTimes5 = NSAffineTransform()
        xyTimes5.scaleBy(CGFloat(5.0))

        checkPointTransformation(xyTimes5, point: NSMakePoint(CGFloat(-2.0), CGFloat(3.0)),
                                   expectedPoint: NSMakePoint(CGFloat(-10.0), CGFloat(15.0)))

        let xTimes2YTimes3 = NSAffineTransform()
        xTimes2YTimes3.scaleXBy(CGFloat(2.0), yBy: CGFloat(-3.0))

        checkPointTransformation(xTimes2YTimes3, point: NSMakePoint(CGFloat(-1.0), CGFloat(3.5)),
                                         expectedPoint: NSMakePoint(CGFloat(-2.0), CGFloat(-10.5)))
    }

    func test_TranslationScaling() {
        let xPlus2XYTimes5 = NSAffineTransform()
        xPlus2XYTimes5.translateXBy(CGFloat(2.0), yBy: CGFloat())
        xPlus2XYTimes5.scaleXBy(CGFloat(5.0), yBy: CGFloat(-5.0))

        checkPointTransformation(xPlus2XYTimes5, point: NSMakePoint(CGFloat(1.0), CGFloat(2.0)),
                                         expectedPoint: NSMakePoint(CGFloat(7.0), CGFloat(-10.0)))
    }

    func test_ScalingTranslation() {
        let xyTimes5XPlus3 = NSAffineTransform()
        xyTimes5XPlus3.scaleBy(CGFloat(5.0))
        xyTimes5XPlus3.translateXBy(CGFloat(3.0), yBy: CGFloat())

        checkPointTransformation(xyTimes5XPlus3, point: NSMakePoint(CGFloat(1.0), CGFloat(2.0)),
                                         expectedPoint: NSMakePoint(CGFloat(20.0), CGFloat(10.0)))
    }
    
    func test_AppendTransform() {
        let point = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        
        let identityTransform = NSAffineTransform()
        identityTransform.appendTransform(identityTransform)
        checkPointTransformation(identityTransform, point: point, expectedPoint: point)
        
        let translate = NSAffineTransform()
        translate.translateXBy(CGFloat(10.0), yBy: CGFloat())
        
        let scale = NSAffineTransform()
        scale.scaleBy(CGFloat(2.0))
        
        let translateThenScale = NSAffineTransform(transform: translate)
        translateThenScale.appendTransform(scale)
        checkPointTransformation(translateThenScale, point: point, expectedPoint: NSPoint(x: CGFloat(40.0), y: CGFloat(20.0)))
    }
    
    func test_PrependTransform() {
        let point = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        
        let identityTransform = NSAffineTransform()
        identityTransform.prependTransform(identityTransform)
        checkPointTransformation(identityTransform, point: point, expectedPoint: point)
        
        let translate = NSAffineTransform()
        translate.translateXBy(CGFloat(10.0), yBy: CGFloat())
        
        let scale = NSAffineTransform()
        scale.scaleBy(CGFloat(2.0))
        
        let scaleThenTranslate = NSAffineTransform(transform: translate)
        scaleThenTranslate.prependTransform(scale)
        checkPointTransformation(scaleThenTranslate, point: point, expectedPoint: NSPoint(x: CGFloat(30.0), y: CGFloat(20.0)))
    }
    
    
    func test_TransformComposition() {
        let origin = NSPoint(x: CGFloat(10.0), y: CGFloat(10.0))
        let size = NSSize(width: CGFloat(40.0), height: CGFloat(20.0))
        let rect = NSRect(origin: origin, size: size)
        let center = NSPoint(x: NSMidX(rect), y: NSMidY(rect))
        
        let rotate = NSAffineTransform()
        rotate.rotateByDegrees(CGFloat(90.0))
        
        let moveOrigin = NSAffineTransform()
        moveOrigin.translateXBy(-center.x, yBy: -center.y)
        
        let moveBack = NSAffineTransform(transform: moveOrigin)
        moveBack.invert()
        
        let rotateAboutCenter = NSAffineTransform(transform: rotate)
        rotateAboutCenter.prependTransform(moveOrigin)
        rotateAboutCenter.appendTransform(moveBack)
        
        // center of rect shouldn't move as its the rotation anchor
        checkPointTransformation(rotateAboutCenter, point: center, expectedPoint: center)
    }
}

extension NSAffineTransform {
    func transformRect(aRect: NSRect) -> NSRect {
        return NSRect(origin: transformPoint(aRect.origin), size: transformSize(aRect.size))
    }
}
