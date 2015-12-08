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
            ("test_IdentityTransformation", test_IdentityTransformation)
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
            let newPoint = identityTransform.transformPoint(point)
            XCTAssertEqualWithAccuracy(Double(newPoint.x), Double(point.x), accuracy: accuracyThreshold)
            XCTAssertEqualWithAccuracy(Double(newPoint.y), Double(point.y), accuracy: accuracyThreshold)
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
}
