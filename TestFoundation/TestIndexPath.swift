// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// RUN: %target-run-simple-swift
// REQUIRES: executable_test
// REQUIRES: objc_interop

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#elseif DEPLOYMENT_RUNTIME_SWIFT
import SwiftFoundation
import SwiftXCTest
#endif

class TestIndexPath : XCTestCase {
    
    static var allTests: [(String, (TestIndexPath) -> () throws -> Void)] {
        return [
            ("testBasics", testBasics),
            ("testAppending", testAppending),
            ("testRanges", testRanges),
            ("testMoreRanges", testMoreRanges),
            ("testIteration", testIteration),
            ("test_AnyHashableContainingIndexPath", test_AnyHashableContainingIndexPath),
            ("test_AnyHashableCreatedFromNSIndexPath", test_AnyHashableCreatedFromNSIndexPath),
        ]
    }
    
    func testBasics() {
        let ip = IndexPath(index: 1)
        XCTAssertEqual(ip.count, 1)
    }
    
    func testAppending() {
        var ip : IndexPath = [1, 2, 3, 4]
        let ip2 = IndexPath(indexes: [5, 6, 7])
        
        ip.append(ip2)
        
        XCTAssertEqual(ip.count, 7)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[6], 7)
    }
    
    func testRanges() {
        let ip1 = IndexPath(indexes: [1, 2, 3])
        let ip2 = IndexPath(indexes: [6, 7, 8])
        
        // Replace the whole range
        var mutateMe = ip1
        mutateMe[0..<3] = ip2
        XCTAssertEqual(mutateMe, ip2)
        
        // Insert at the beginning
        mutateMe = ip1
        mutateMe[0..<0] = ip2
        XCTAssertEqual(mutateMe, IndexPath(indexes: [6, 7, 8, 1, 2, 3]))
        
        // Insert at the end
        mutateMe = ip1
        mutateMe[3..<3] = ip2
        XCTAssertEqual(mutateMe, IndexPath(indexes: [1, 2, 3, 6, 7, 8]))
        
        // Insert in middle
        mutateMe = ip1
        mutateMe[2..<2] = ip2
        XCTAssertEqual(mutateMe, IndexPath(indexes: [1, 2, 6, 7, 8, 3]))
    }
    
    func testMoreRanges() {
        var ip = IndexPath(indexes: [1, 2, 3])
        let ip2 = IndexPath(indexes: [5, 6, 7, 8, 9, 10])
        
        ip[1..<2] = ip2
        XCTAssertEqual(ip, IndexPath(indexes: [1, 5, 6, 7, 8, 9, 10, 3]))
    }
    
    func testIteration() {
        let ip = IndexPath(indexes: [1, 2, 3])
        
        var count = 0
        for _ in ip {
            count += 1
        }
        
        XCTAssertEqual(3, count)
    }

    func test_AnyHashableContainingIndexPath() {
        let values: [IndexPath] = [
            IndexPath(indexes: [1, 2]),
            IndexPath(indexes: [1, 2, 3]),
            IndexPath(indexes: [1, 2, 3]),
        ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(IndexPath.self, type(of: anyHashables[0].base))
        XCTAssertSameType(IndexPath.self, type(of: anyHashables[1].base))
        XCTAssertSameType(IndexPath.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }

    func test_AnyHashableCreatedFromNSIndexPath() {
        let values: [NSIndexPath] = [
            NSIndexPath(index: 1),
            NSIndexPath(index: 2),
            NSIndexPath(index: 2),
        ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(IndexPath.self, type(of: anyHashables[0].base))
        XCTAssertSameType(IndexPath.self, type(of: anyHashables[1].base))
        XCTAssertSameType(IndexPath.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    // TODO: Test bridging
    
}
