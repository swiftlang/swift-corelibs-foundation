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



class TestNSPredicate : XCTestCase {

    var allTests : [(String, () -> ())] {
        return [
            ("test_constantPredicate", test_constantPredicate),
            ("test_blockPredicate", test_blockPredicate),
        ]
    }

    func test_constantPredicate() {
        XCTAssert(NSPredicate(value: true).evaluateWithObject( self ) == true)
        XCTAssert(NSPredicate(value: false).evaluateWithObject( self ) == false)
    }

    func test_blockPredicate() {
        var called = false
        let block : (AnyObject, [String:AnyObject]?) -> Bool = {[unowned self] object, bindings in
            XCTAssert(object === self)
            XCTAssertNil(bindings)

            called = true
            return true
        }

        XCTAssert(NSPredicate(block: block).evaluateWithObject( self ) == true)
        XCTAssert(called)
    }

}
