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



class TestNSPropertyList : XCTestCase {
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction ),
            ("test_decode", test_decode ),
        ]
    }
    
    func test_BasicConstruction() {
        let dict = NSMutableDictionary(capacity: 0)
//        dict["foo"] = "bar"
        var data: NSData? = nil
        do {
            data = try NSPropertyListSerialization.dataWithPropertyList(dict, format: NSPropertyListFormat.BinaryFormat_v1_0, options: 0)
        } catch {
            
        }
        XCTAssertNotNil(data)
        XCTAssertEqual(data!.length, 42, "empty dictionary should be 42 bytes")
    }
    
    func test_decode() {
        var decoded: Any?
        var fmt = NSPropertyListFormat.BinaryFormat_v1_0
        let path = testBundle().pathForResource("Test", ofType: "plist")
        let data = NSData(contentsOfFile: path!)
        do {
            decoded = try withUnsafeMutablePointer(&fmt) { (format: UnsafeMutablePointer<NSPropertyListFormat>) -> Any in
                return try NSPropertyListSerialization.propertyListWithData(data!, options: [], format: format)
            }
        } catch {
            
        }

        XCTAssertNotNil(decoded)
        let dict = decoded as! Dictionary<String, Any>
        XCTAssertEqual(dict.count, 3)
        let val = dict["Foo"]
        XCTAssertNotNil(val)
        if let str = val as? String {
            XCTAssertEqual(str, "Bar")
        } else {
            XCTFail("value stored is not a string")
        }
    }
}
