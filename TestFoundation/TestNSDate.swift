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

class TestNSDate : XCTestCase {
    
    var allTests : [(String, () -> ())] {
        return [
            ("test_comparable", test_comparable ),
        ]
    }
    
    func ignoreError(@noescape block: () throws -> Void) {
        do { try block() } catch { }
    }
    
    func test_comparable() {
        
        let past = NSDate.distantPast()
        let future = NSDate.distantFuture()
        let present = NSDate()
        
        XCTAssertTrue(past < present)
        XCTAssertTrue(past <= present)
        
        XCTAssertTrue(past != present)
        XCTAssertTrue(present == present)

        XCTAssertTrue(future > present)
        XCTAssertTrue(future >= present)
    }
    
}