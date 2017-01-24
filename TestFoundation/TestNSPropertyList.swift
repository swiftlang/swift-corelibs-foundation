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



class TestNSPropertyList : XCTestCase {
    static var allTests: [(String, (TestNSPropertyList) -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_decodeData", test_decodeData),
            ("test_decodeStream", test_decodeStream),
            ("test_booleanProperty", test_booleanProperty),
        ]
    }
    
    func test_BasicConstruction() {
        let dict = NSMutableDictionary(capacity: 0)
//        dict["foo"] = "bar"
        var data: Data? = nil
        do {
            data = try PropertyListSerialization.data(fromPropertyList: dict, format: PropertyListSerialization.PropertyListFormat.binary, options: 0)
        } catch {
            
        }
        XCTAssertNotNil(data)
        XCTAssertEqual(data!.count, 42, "empty dictionary should be 42 bytes")
    }
    
    func test_decodeData() {
        var decoded: Any?
        var fmt = PropertyListSerialization.PropertyListFormat.binary
        let path = testBundle().url(forResource: "Test", withExtension: "plist")
        let data = try! Data(contentsOf: path!)
        do {
            decoded = try withUnsafeMutablePointer(to: &fmt) { (format: UnsafeMutablePointer<PropertyListSerialization.PropertyListFormat>) -> Any in
                return try PropertyListSerialization.propertyList(from: data, options: [], format: format)
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

    func test_decodeStream() {
        var decoded: Any?
        var fmt = PropertyListSerialization.PropertyListFormat.binary
        let path = testBundle().url(forResource: "Test", withExtension: "plist")
        let stream = InputStream(url: path!)!
        stream.open()
        do {
            decoded = try withUnsafeMutablePointer(to: &fmt) { (format: UnsafeMutablePointer<PropertyListSerialization.PropertyListFormat>) -> Any in
                return try PropertyListSerialization.propertyList(with: stream, options: [], format: format)
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
    
    func test_booleanProperty() {
        let plistDocString = "<?xml version='1.0' encoding='utf-8'?><!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"> <plist version='1.0'><dict><key>state</key><true/></dict></plist>"
        do {
            let plistDoc = try XMLDocument(xmlString: plistDocString, options: [])
            try plistDoc.validate()
            let plist = try PropertyListSerialization.propertyList(from: plistDoc.xmlData, options: [], format: nil) as! [String: Any]
            XCTAssertNotNil(plist)
            XCTAssertEqual(plist["state"] as? NSNumber, 1)
        } catch {
             XCTFail("Value stored is not boolean")
        }
    }
}
