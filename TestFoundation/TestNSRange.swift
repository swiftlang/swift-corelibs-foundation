//
//  TestNSRange.swift
//  Foundation
//
//  Created by Harlan Haskins on 12/3/15.
//  Copyright © 2015 Apple. All rights reserved.
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

class TestNSRange: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testRangeWithValidInput() {
        XCTAssertEqual(NSRangeFromString("{4,5}"), NSRange(location: 4, length: 5))
    }
    
    func testRangesWithInvalidInput() {
        XCTAssertEqual(NSRangeFromString("4,5}"), NSRange(location: 4, length: 5))
        XCTAssertEqual(NSRangeFromString("{4,5"), NSRange(location: 4, length: 5))
        XCTAssertEqual(NSRangeFromString("{4,}"), NSRange(location: 4, length: 0))
        XCTAssertEqual(NSRangeFromString(",4}"), NSRange(location: 4, length: 0))
        XCTAssertEqual(NSRangeFromString("4,5"), NSRange(location: 4, length: 5))
    }
    
    func testRoundTrip() {
        let initial = NSRange(location: 4, length: 5)
        XCTAssertEqual(NSRangeFromString(NSStringFromRange(initial)), initial)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
