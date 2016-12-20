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



class TestNSPersonNameComponents : XCTestCase {
    
    static var allTests: [(String, (TestNSPersonNameComponents) -> () throws -> Void)] {
        return [
            ("testCopy", testCopy),
        ]
    }
    
    func testCopy() {
        let original = NSPersonNameComponents()
        original.givenName = "Maria"
        original.phoneticRepresentation = PersonNameComponents()
        original.phoneticRepresentation!.givenName = "Jeff"
        let copy = original.copy(with:nil) as! NSPersonNameComponents
        copy.givenName = "Rebecca"
        
        XCTAssertNotEqual(original.givenName, copy.givenName)
        XCTAssertEqual(original.phoneticRepresentation!.givenName,copy.phoneticRepresentation!.givenName)
        XCTAssertNil(copy.phoneticRepresentation!.phoneticRepresentation)
    }
}

        
