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
            ("test_Translation", test_Translation),
            ("test_TranslationComposed", test_TranslationComposed),
            ("test_Scaling", test_Scaling),
            ("test_TranslationScaling", test_TranslationScaling),
            ("test_ScalingTranslation", test_ScalingTranslation)
        ]
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
            let newSize = identityTransform.transformSize(size)
            XCTAssertEqualWithAccuracy(Double(newSize.width), Double(size.width), accuracy: accuracyThreshold)
            XCTAssertEqualWithAccuracy(Double(newSize.height), Double(size.height), accuracy: accuracyThreshold)
        }

        checkIdentitySizeTransformation(NSSize())
        checkIdentitySizeTransformation(NSMakeSize(CGFloat(13.0), CGFloat(12.5)))
        checkIdentitySizeTransformation(NSMakeSize(CGFloat(100.0), CGFloat(-100.0)))
    }

    private func checkPointTransformation(transform: NSAffineTransform, point: NSPoint, expectedPoint: NSPoint) {
        let newPoint = transform.transformPoint(point)
        XCTAssertEqualWithAccuracy(Double(newPoint.x), Double(expectedPoint.x), accuracy: accuracyThreshold)
        XCTAssertEqualWithAccuracy(Double(newPoint.y), Double(expectedPoint.y), accuracy: accuracyThreshold)
    }

    func test_Translation() {
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
}
