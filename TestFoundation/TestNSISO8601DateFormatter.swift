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

class TestNSISO8601DateFormatter: XCTestCase {
    
    let DEFAULT_LOCALE = "en_US"
    let DEFAULT_TIMEZONE = "GMT"
    
    static var allTests : [(String, (TestNSISO8601DateFormatter) -> () throws -> Void)] {
        return [

        ]
    }
}
