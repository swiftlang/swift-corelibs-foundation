// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

class TestPropertyListSerialization : XCTestCase {
    func test_BasicConstruction() {
        let dict = NSMutableDictionary(capacity: 0)
//        dict["foo"] = "bar"
        var data: Data? = nil
        do {
            data = try PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)
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

    func test_decodeEmptyData() {
        XCTAssertThrowsError(try PropertyListSerialization.propertyList(from: Data(), format: nil)) { error in
            let nserror = error as NSError
            XCTAssertEqual(nserror.domain, NSCocoaErrorDomain)
            XCTAssertEqual(CocoaError(_nsError: nserror).code, .propertyListReadCorrupt)
            XCTAssertEqual(nserror.userInfo[NSDebugDescriptionErrorKey] as? String, "Cannot parse a NULL or zero-length data")
        }
    }
    
    func test_decodeOverflowUnicodeString() throws {
        var native = "ФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФФ"
        let ns = native.withCString {
            NSString(utf8String: $0)!
        }
        do {
            var buffer = Array<UInt8>(repeating: 1, count: native.utf8.count)
            buffer.withUnsafeMutableBufferPointer { bufferPtr in
                var used: CFIndex = 0
                CFStringGetBytes(unsafeBitCast(ns, to: CFString.self), CFRangeMake(0, ns.length), CFStringBuiltInEncodings.UTF8.rawValue, 0xF, false, bufferPtr.baseAddress!, 10, &used)
                XCTAssertEqual(used, 10)
            }
            for i in 10 ..< buffer.count {
                XCTAssertEqual(buffer[i], 1)
            }
        }
        do {
            var buffer = Array<UInt16>(repeating: 1, count: native.utf8.count)
            buffer.withUnsafeMutableBufferPointer { bufferPtr in
                var used: CFIndex = 0
                CFStringGetBytes(unsafeBitCast(ns, to: CFString.self), CFRangeMake(0, ns.length), CFStringBuiltInEncodings.UTF16.rawValue, 0xF, false, bufferPtr.baseAddress!, 10, &used)
                XCTAssertEqual(used, 10)
            }
            for i in 10 ..< buffer.count {
                XCTAssertEqual(buffer[i], 1)
            }
        }
    }
}
