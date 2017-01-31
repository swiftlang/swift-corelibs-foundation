// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif


class TestNSError : XCTestCase {
    
    static var allTests: [(String, (TestNSError) -> () throws -> Void)] {
        return [
            ("test_LocalizedError_errorDescription", test_LocalizedError_errorDescription),
        ]
    }
    
    func test_LocalizedError_errorDescription() {
        struct Error : LocalizedError {
            var errorDescription: String? { return "error description" }
        }

        let error = Error()
        XCTAssertEqual(error.localizedDescription, "error description")
    }
}
