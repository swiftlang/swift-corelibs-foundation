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
    
    func test_NSPipe() {
        let aPipe = NSPipe()
        let text = "test-pipe"
        
        // First write some data into the pipe
        aPipe.fileHandleForWriting.writeData(text.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        // Then read it out again
        let data = aPipe.fileHandleForReading.readDataOfLength(text.characters.count)
        
        // Make sure we *did* get data
        XCTAssertNotNil(data)
        
        // Make sure the data can be converted
        let convertedData = String(data: data, encoding: NSUTF8StringEncoding)
        XCTAssertNotNil(convertedData)
        
        // Make sure we did get back what we wrote in
        XCTAssertEqual(text, convertedData)
    }
}