// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016. 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
        @testable import SwiftFoundation
    #else
        @testable import Foundation
    #endif
#endif


class TestPipe: XCTestCase {
    
    static var allTests: [(String, (TestPipe) -> () throws -> Void)] {
        var tests: [(String, (TestPipe) -> () throws -> Void)] = [
            ("test_Pipe", test_Pipe),
        ]

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
        tests.append(contentsOf: [
            ("test_MaxPipes", test_MaxPipes),
        ])
#endif
        return tests
    }

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    func test_MaxPipes() {
        // Try and create enough pipes to exhaust the process's limits. 1024 is a reasonable
        // hard limit for the test. This is reached when testing on Linux (at around 488 pipes)
        // but not on macOS.

        var pipes: [Pipe] = []
        let maxPipes = 1024
        pipes.reserveCapacity(maxPipes)
        for _ in 1...maxPipes {
            let pipe = Pipe()
            if !pipe.fileHandleForReading._isPlatformHandleValid {
                XCTAssertEqual(pipe.fileHandleForReading.fileDescriptor, pipe.fileHandleForWriting.fileDescriptor)
                break
            }
            pipes.append(pipe)
        }
        pipes = []
    }
#endif

    func test_Pipe() throws {
        let aPipe = Pipe()
        let text = "test-pipe"
        
        // First write some data into the pipe
        let stringAsData = try XCTUnwrap(text.data(using: .utf8))
        try aPipe.fileHandleForWriting.write(contentsOf: stringAsData)

        // SR-10240 - Check empty Data() can be written without crashing
        aPipe.fileHandleForWriting.write(Data())

        // Then read it out again
        let data = try XCTUnwrap(aPipe.fileHandleForReading.read(upToCount: stringAsData.count))
        
        // Confirm that we did read data
        XCTAssertEqual(data.count, stringAsData.count, "Expected to read \(String(describing:stringAsData.count)) from pipe but read \(data.count) instead")
        
        // Confirm the data can be converted to a String
        let convertedData = String(data: data, encoding: .utf8)
        XCTAssertNotNil(convertedData)
        
        // Confirm the data written in is the same as the data we read
        XCTAssertEqual(text, convertedData)
    }
}
