// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
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

class TestNSFileHandle : XCTestCase {
    static var allTests : [(String, (TestNSFileHandle) -> () throws -> ())] {
        return [
                   ("test_pipe", test_pipe),
        ]
    }

    func test_pipe() {
        let pipe = Pipe()
        let inputs = ["Hello", "world", "🐶"]

        for input in inputs {
            let inputData = input.data(using: .utf8)!

            // write onto pipe
            pipe.fileHandleForWriting.write(inputData)

            let outputData = pipe.fileHandleForReading.availableData
            let output = String(data: outputData, encoding: .utf8)

            XCTAssertEqual(output, input)
        }
    }
}
