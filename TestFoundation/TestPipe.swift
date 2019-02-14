// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016. 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestPipe: XCTestCase {
    
    static var allTests: [(String, (TestPipe) -> () throws -> Void)] {
        return [
            ("test_MaxPipes", test_MaxPipes),
            ("test_Pipe", test_Pipe),
        ]
    }

    func test_MaxPipes() {
        // Try and create enough pipes to exhaust the process's limits. 1024 is a reasonable
        // hard limit for the test. This is reached when testing on Linux (at around 488 pipes)
        // but not on macOS.

        var pipes: [Pipe] = []
        let maxPipes = 1024
        pipes.reserveCapacity(maxPipes)
        for _ in 1...maxPipes {
            let pipe = Pipe()
            if pipe.fileHandleForReading.fileDescriptor == -1 {
                XCTAssertEqual(pipe.fileHandleForReading.fileDescriptor, pipe.fileHandleForWriting.fileDescriptor)
                break
            }
            pipes.append(pipe)
        }
        pipes = []
    }

    func test_Pipe() throws {
        let aPipe = Pipe()
        let text = "test-pipe"
        
        // First write some data into the pipe
        let stringAsData = try text.data(using: .utf8).unwrapped()
        try aPipe.fileHandleForWriting.write(contentsOf: stringAsData)
        
        // Then read it out again
        let data = try aPipe.fileHandleForReading.read(upToCount: stringAsData.count).unwrapped()
        
        // Confirm that we did read data
        XCTAssertEqual(data.count, stringAsData.count, "Expected to read \(String(describing:stringAsData.count)) from pipe but read \(data.count) instead")
        
        // Confirm the data can be converted to a String
        let convertedData = String(data: data, encoding: .utf8)
        XCTAssertNotNil(convertedData)
        
        // Confirm the data written in is the same as the data we read
        XCTAssertEqual(text, convertedData)
    }
}
