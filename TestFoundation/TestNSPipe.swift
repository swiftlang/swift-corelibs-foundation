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


class TestNSPipe : XCTestCase {
    
    var allTests: [(String, () throws -> Void)] {
        return [
            // Currently disabled until NSString implements dataUsingEncoding
            // ("test_NSPipe", test_NSPipe)
        ]
    }
    
    func test_NSPipe() {
        let aPipe = NSPipe()
        let text = "test-pipe"
        
        // First write some data into the pipe
        let stringAsData = text.bridge().dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssertNotNil(stringAsData)
        aPipe.fileHandleForWriting.writeData(stringAsData!)
        
        // Then read it out again
        let data = aPipe.fileHandleForReading.readDataOfLength(text.characters.count)
        
        // Confirm that we did read data
        XCTAssertNotNil(data)
        
        // Confirm the data can be converted to a String
        let convertedData = String(data: data, encoding: NSUTF8StringEncoding)
        XCTAssertNotNil(convertedData)
        
        // Confirm the data written in is the same as the data we read
        XCTAssertEqual(text, convertedData)
    }
}