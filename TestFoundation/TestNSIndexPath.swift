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


class TestNSIndexPath: XCTestCase {
    
    static var allTests: [(String, (TestNSIndexPath) -> () throws -> Void)] {
        return [
           ("test_BasicConstruction", test_BasicConstruction)
        ]
    }

    func test_BasicConstruction() {
        // Test `init()`
        do {
            let path = IndexPath()
            XCTAssertEqual(path.count, 0)
        }
        
        // Test `init(index:)`
        do {
            let path = IndexPath(index: 8)
            XCTAssertEqual(path.count, 1)
            
            let index0 = path[0]
            XCTAssertEqual(index0, 8)
        }
        
        // Test `init(indexes:)`
        do {
            let path = IndexPath(indexes: [1, 2])
            XCTAssertEqual(path.count, 2)
            
            let index0 = path[0]
            XCTAssertEqual(index0, 1)
            
            let index1 = path[1]
            XCTAssertEqual(index1, 2)
        }
    }

}
