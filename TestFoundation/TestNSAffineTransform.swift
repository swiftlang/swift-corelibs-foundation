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

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

class TestNSAffineTransform : XCTestCase {
    private let accuracyThreshold = 0.001

    var allTests : [(String, () -> ())] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_IdentityTransformation", test_IdentityTransformation),
            ("test_Scale", test_Scale),
            ("test_Rotation_Degrees", test_Rotation_Degrees),
            ("test_Rotation_Radians", test_Rotation_Radians),
            ("test_Inversion", test_Inversion),
            ("test_IdentityTransformation", test_IdentityTransformation),
            ("test_Translation", test_Translation),
            ("test_Translation2", test_Translation2),
            ("test_TranslationComposed", test_TranslationComposed),
        ]
    }
    
    func checkPointTransformation(transform: NSAffineTransform, point: NSPoint, expectedPoint: NSPoint, _ message: String = "", _ file: StaticString = __FILE__, _ line: UInt = __LINE__) {
        let newPoint = transform.transformPoint(point)
        XCTAssertEqualWithAccuracy(Double(newPoint.x), Double(expectedPoint.x), accuracy: accuracyThreshold, "x: \(message)", file: file, line: line)
        XCTAssertEqualWithAccuracy(Double(newPoint.y), Double(expectedPoint.y), accuracy: accuracyThreshold, "y: \(message)", file: file, line: line)
    }
    
    func checkSizeTransformation(transform: NSAffineTransform, size: NSSize, expectedSize: NSSize, _ message: String = "", _ file: StaticString = __FILE__, _ line: UInt = __LINE__) {
        let newSize = transform.transformSize(size)
        XCTAssertEqualWithAccuracy(Double(newSize.width), Double(expectedSize.width), accuracy: accuracyThreshold, "width: \(message)", file: file, line: line)
        XCTAssertEqualWithAccuracy(Double(newSize.height), Double(expectedSize.height), accuracy: accuracyThreshold, "height: \(message)", file: file, line: line)
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

    func test_Translation2() {
        let xPlus2 = NSAffineTransform()
        xPlus2.translateXBy(CGFloat(2.0), yBy: CGFloat())

        checkPointTransformation(xPlus2, point: NSMakePoint(CGFloat(22.0), CGFloat(10.0)),
                                 expectedPoint: NSMakePoint(CGFloat(24.0), CGFloat(10.0)))
    }

    func test_TranslationComposed() {
        let xyPlus5 = NSAffineTransform()
        xyPlus5.translateXBy(CGFloat(2.0), yBy: CGFloat(3.0))
        xyPlus5.translateXBy(CGFloat(3.0), yBy: CGFloat(2.0))

        checkPointTransformation(xyPlus5, point: NSMakePoint(CGFloat(-2.0), CGFloat(-3.0)),
                                  expectedPoint: NSMakePoint(CGFloat(3.0), CGFloat(2.0)))
    }
}

