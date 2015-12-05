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

    var allTests : [(String, () -> ())] {
        return [
            ("test_BasicConstruction", test_BasicConstruction)
        ]
    }

    func test_BasicConstruction() {
        let identityTransform = NSAffineTransform()
        let transformStruct = identityTransform.transformStruct

        // The diagonal entries (1,1) and (2,2) of the identity matrix are ones. The other entries are zeros.
        XCTAssertEqualWithAccuracy(Double(transformStruct.m11), Double(1), accuracy: DBL_MIN)
        XCTAssertEqualWithAccuracy(Double(transformStruct.m22), Double(1), accuracy: DBL_MIN)

        XCTAssertEqualWithAccuracy(Double(transformStruct.m12), Double(0), accuracy: DBL_MIN)
        XCTAssertEqualWithAccuracy(Double(transformStruct.m21), Double(0), accuracy: DBL_MIN)
        XCTAssertEqualWithAccuracy(Double(transformStruct.tX), Double(0), accuracy: DBL_MIN)
        XCTAssertEqualWithAccuracy(Double(transformStruct.tY), Double(0), accuracy: DBL_MIN)
    }
}
