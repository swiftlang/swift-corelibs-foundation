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


class TestPipe : XCTestCase {
    
    static var allTests: [(String, (TestPipe) -> () throws -> Void)] {
        return [
             ("test_NSPipe", test_NSPipe)
        ]
    }
    
    func test_NSPipe() {
        let aPipe = Pipe()
        let text = "test-pipe"
        
        // First write some data into the pipe
        let stringAsData = text.data(using: .utf8)
        XCTAssertNotNil(stringAsData)
        aPipe.fileHandleForWriting.write(stringAsData!)
        
        // Then read it out again
        let data = aPipe.fileHandleForReading.readData(ofLength: text.count)
        
        // Confirm that we did read data
        XCTAssertNotNil(data)
        
        // Confirm the data can be converted to a String
        let convertedData = String(data: data, encoding: .utf8)
        XCTAssertNotNil(convertedData)
        
        // Confirm the data written in is the same as the data we read
        XCTAssertEqual(text, convertedData)
    }
}
