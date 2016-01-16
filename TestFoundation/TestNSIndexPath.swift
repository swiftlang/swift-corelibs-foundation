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


class TestNSIndexPath: XCTestCase {
    
    var allTests: [(String, () throws -> Void)] {
        return [
           ("test_BasicConstruction", test_BasicConstruction)
        ]
    }

    func test_BasicConstruction() {
        // Test `init()`
        do {
            let path = NSIndexPath()
            XCTAssertEqual(path.length, 0)
        }
        
        // Test `init(index:)`
        do {
            let path = NSIndexPath(index: 8)
            XCTAssertEqual(path.length, 1)
            
            let index0 = path.indexAtPosition(0)
            XCTAssertEqual(index0, 8)
        }
        
        // Test `init(indexes:)`
        do {
            let path = NSIndexPath(indexes: [1, 2], length: 2)
            XCTAssertEqual(path.length, 2)
            
            let index0 = path.indexAtPosition(0)
            XCTAssertEqual(index0, 1)
            
            let index1 = path.indexAtPosition(1)
            XCTAssertEqual(index1, 2)
        }
    }

}
