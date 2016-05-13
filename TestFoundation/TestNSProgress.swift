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
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

class TestNSProgress: XCTestCase {

    static var allTests: [(String, (TestNSProgress) -> () throws -> Void)] {
        return [
            ("test_initWithTotalUnitCount", test_initWithTotalUnitCount),
        ]
    }
    
    func test_initWithTotalUnitCount() {
        let progress = NSProgress(totalUnitCount: 1000)
        XCTAssertEqual(progress.totalUnitCount, 1000)
        XCTAssertEqual(progress.completedUnitCount, 0)
        XCTAssertTrue(progress.isCancellable)
        XCTAssertFalse(progress.isPausable)
    }

}
