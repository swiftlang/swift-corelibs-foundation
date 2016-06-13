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


class TestNSXMLParser : XCTestCase {
    
    static var allTests: [(String, (TestNSXMLParser) -> () throws -> Void)] {
        return [
            ("test_data", test_data),
        ]
    }
    
    func test_data() {
        let xml = Array("<test><foo>bar</foo></test>".nulTerminatedUTF8)
        let data = xml.withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<UInt8>) -> Data in
            return Data(bytes:UnsafePointer<Void>(buffer.baseAddress!), count: buffer.count)
        }
        let parser = XMLParser(data: data)
        let res = parser.parse()
        XCTAssertTrue(res)
    }
}
