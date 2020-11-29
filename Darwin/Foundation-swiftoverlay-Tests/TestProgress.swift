//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest

class TestProgress : XCTestCase {
    func testUserInfoConveniences() {
        if #available(OSX 10.13, iOS 11.0, watchOS 4.0, tvOS 11.0, *) {
            let p = Progress(parent:nil, userInfo: nil)
            
            XCTAssertNil(p.userInfo[.throughputKey])
            XCTAssertNil(p.throughput)
            p.throughput = 50
            XCTAssertEqual(p.throughput, 50)
            XCTAssertNotNil(p.userInfo[.throughputKey])
            
            XCTAssertNil(p.userInfo[.estimatedTimeRemainingKey])
            XCTAssertNil(p.estimatedTimeRemaining)
            p.estimatedTimeRemaining = 100
            XCTAssertEqual(p.estimatedTimeRemaining, 100)
            XCTAssertNotNil(p.userInfo[.estimatedTimeRemainingKey])
            
            XCTAssertNil(p.userInfo[.fileTotalCountKey])
            XCTAssertNil(p.fileTotalCount)
            p.fileTotalCount = 42
            XCTAssertEqual(p.fileTotalCount, 42)
            XCTAssertNotNil(p.userInfo[.fileTotalCountKey])
            
            XCTAssertNil(p.userInfo[.fileCompletedCountKey])
            XCTAssertNil(p.fileCompletedCount)
            p.fileCompletedCount = 24
            XCTAssertEqual(p.fileCompletedCount, 24)
            XCTAssertNotNil(p.userInfo[.fileCompletedCountKey])
        }
    }
    
    func testPerformAsCurrent() {
        if #available(OSX 10.11, iOS 8.0, *) {
            // This test can be enabled once <rdar://problem/31867347> is in the SDK
            /*
            let p = Progress.discreteProgress(totalUnitCount: 10)
            let r = p.performAsCurrent(withPendingUnitCount: 10) {
                XCTAssertNotNil(Progress.current())
                return 42
            }
            XCTAssertEqual(r, 42)
            XCTAssertEqual(p.completedUnitCount, 10)
            XCTAssertNil(Progress.current())
            */
        }
    }
}
