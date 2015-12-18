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

import CoreFoundation

class TestNSString : XCTestCase {
    
    var allTests : [(String, () -> Void)] {
        return [
            ("test_boolValue", test_boolValue ),
            ("test_BridgeConstruction", test_BridgeConstruction ),
            ("test_integerValue", test_integerValue ),
            ("test_intValue", test_intValue ),
            ("test_isEqualToStringWithSwiftString", test_isEqualToStringWithSwiftString ),
            ("test_isEqualToObjectWithNSString", test_isEqualToObjectWithNSString ),
            ("test_isNotEqualToObjectWithNSNumber", test_isNotEqualToObjectWithNSNumber ),
            ("test_FromASCIIData", test_FromASCIIData ),
            ("test_FromUTF8Data", test_FromUTF8Data ),
            ("test_FromMalformedUTF8Data", test_FromMalformedUTF8Data ),
            ("test_FromASCIINSData", test_FromASCIINSData ),
            ("test_FromUTF8NSData", test_FromUTF8NSData ),
            ("test_FromMalformedUTF8NSData", test_FromMalformedUTF8NSData ),
            ("test_FromNullTerminatedCStringInASCII", test_FromNullTerminatedCStringInASCII ),
            ("test_FromNullTerminatedCStringInUTF8", test_FromNullTerminatedCStringInUTF8 ),
            ("test_FromMalformedNullTerminatedCStringInUTF8", test_FromMalformedNullTerminatedCStringInUTF8 ),
            ("test_uppercaseString", test_uppercaseString ),
            ("test_lowercaseString", test_lowercaseString ),
            ("test_capitalizedString", test_capitalizedString ),
            ("test_longLongValue", test_longLongValue ),
            ("test_rangeOfCharacterFromSet", test_rangeOfCharacterFromSet ),
            ("test_CFStringCreateMutableCopy", test_CFStringCreateMutableCopy),
            ("test_FromContentOfFile",test_FromContentOfFile),
            ("test_swiftStringUTF16", test_swiftStringUTF16),
        ]
    }

    func test_boolValue() {
        let trueStrings: [NSString] = ["t", "true", "TRUE", "tRuE", "yes", "YES", "1", "+000009"]
        for string in trueStrings {
            XCTAssert(string.boolValue)
        }
        let falseStrings: [NSString] = ["false", "FALSE", "fAlSe", "no", "NO", "0", "<true>", "_true", "-00000"]
        for string in falseStrings {
            XCTAssertFalse(string.boolValue)
        }
    }
    
    func test_BridgeConstruction() {
        let literalConversion: NSString = "literal"
        XCTAssertEqual(literalConversion.length, 7)
        
        let nonLiteralConversion: NSString = "test\(self)".bridge()
        XCTAssertTrue(nonLiteralConversion.length > 4)
        
        let nonLiteral2: NSString = String(4).bridge()
        let t = nonLiteral2.characterAtIndex(0)
        XCTAssertTrue(t == 52)
        
        let externalString: NSString = String.localizedNameOfStringEncoding(String.defaultCStringEncoding()).bridge()
        XCTAssertTrue(externalString.length > 4)
        
        let cluster: NSString = "✌🏾"
        XCTAssertEqual(cluster.length, 3)
    }

    func test_integerValue() {
        let string1: NSString = "123"
        XCTAssertEqual(string1.integerValue, 123)

        let string2: NSString = "123a"
        XCTAssertEqual(string2.integerValue, 123)

        let string3: NSString = "-123a"
        XCTAssertEqual(string3.integerValue, -123)

        let string4: NSString = "a123"
        XCTAssertEqual(string4.integerValue, 0)

        let string5: NSString = "+123"
        XCTAssertEqual(string5.integerValue, 123)

        let string6: NSString = "++123"
        XCTAssertEqual(string6.integerValue, 0)

        let string7: NSString = "-123"
        XCTAssertEqual(string7.integerValue, -123)

        let string8: NSString = "--123"
        XCTAssertEqual(string8.integerValue, 0)

        let string9: NSString = "999999999999999999999999999999"
        XCTAssertEqual(string9.integerValue, Int.max)

        let string10: NSString = "-999999999999999999999999999999"
        XCTAssertEqual(string10.integerValue, Int.min)
    }

    func test_intValue() {
        let string1: NSString = "123"
        XCTAssertEqual(string1.intValue, 123)

        let string2: NSString = "123a"
        XCTAssertEqual(string2.intValue, 123)

        let string3: NSString = "-123a"
        XCTAssertEqual(string3.intValue, -123)

        let string4: NSString = "a123"
        XCTAssertEqual(string4.intValue, 0)

        let string5: NSString = "+123"
        XCTAssertEqual(string5.intValue, 123)

        let string6: NSString = "++123"
        XCTAssertEqual(string6.intValue, 0)

        let string7: NSString = "-123"
        XCTAssertEqual(string7.intValue, -123)

        let string8: NSString = "--123"
        XCTAssertEqual(string8.intValue, 0)

        let string9: NSString = "999999999999999999999999999999"
        XCTAssertEqual(string9.intValue, Int32.max)

        let string10: NSString = "-999999999999999999999999999999"
        XCTAssertEqual(string10.intValue, Int32.min)
    }
    
    func test_isEqualToStringWithSwiftString() {
        let string: NSString = "literal"
        let swiftString = "literal"
        XCTAssertTrue(string.isEqualToString(swiftString))
    }
  
    func test_isEqualToObjectWithNSString() {
        let string1: NSString = "literal"
        let string2: NSString = "literal"
        XCTAssertTrue(string1.isEqual(string2))
    }
    
    func test_isNotEqualToObjectWithNSNumber() {
      let string: NSString = "5"
      let number: NSNumber = 5
      XCTAssertFalse(string.isEqual(number))
    }

    internal let mockASCIIStringBytes: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x53, 0x77, 0x69, 0x66, 0x74, 0x21]
    internal let mockASCIIString = "Hello Swift!"
    internal let mockUTF8StringBytes: [UInt8] = [0x49, 0x20, 0xE2, 0x9D, 0xA4, 0xEF, 0xB8, 0x8F, 0x20, 0x53, 0x77, 0x69, 0x66, 0x74]
    internal let mockUTF8String = "I ❤️ Swift"
    internal let mockMalformedUTF8StringBytes: [UInt8] = [0xFF]

    func test_FromASCIIData() {
        let bytes = mockASCIIStringBytes
        let string = NSString(bytes: bytes, length: bytes.count, encoding: NSASCIIStringEncoding)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqualToString(mockASCIIString) ?? false)
    }

    func test_FromUTF8Data() {
        let bytes = mockUTF8StringBytes
        let string = NSString(bytes: bytes, length: bytes.count, encoding: NSUTF8StringEncoding)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqualToString(mockUTF8String) ?? false)
    }

    func test_FromMalformedUTF8Data() {
        let bytes = mockMalformedUTF8StringBytes
        let string = NSString(bytes: bytes, length: bytes.count, encoding: NSUTF8StringEncoding)
        XCTAssertNil(string)
    }

    func test_FromASCIINSData() {
        let bytes = mockASCIIStringBytes
        let data = NSData(bytes: bytes, length: bytes.count)
        let string = NSString(data: data, encoding: NSASCIIStringEncoding)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqualToString(mockASCIIString) ?? false)
    }

    func test_FromUTF8NSData() {
        let bytes = mockUTF8StringBytes
        let data = NSData(bytes: bytes, length: bytes.count)
        let string = NSString(data: data, encoding: NSUTF8StringEncoding)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqualToString(mockUTF8String) ?? false)
    }

    func test_FromMalformedUTF8NSData() {
        let bytes = mockMalformedUTF8StringBytes
        let data = NSData(bytes: bytes, length: bytes.count)
        let string = NSString(data: data, encoding: NSUTF8StringEncoding)
        XCTAssertNil(string)
    }

    func test_FromNullTerminatedCStringInASCII() {
        let bytes = mockASCIIStringBytes + [0x00]
        let string = NSString(CString: bytes.map { Int8(bitPattern: $0) }, encoding: NSASCIIStringEncoding)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqualToString(mockASCIIString) ?? false)
    }

    func test_FromNullTerminatedCStringInUTF8() {
        let bytes = mockUTF8StringBytes + [0x00]
        let string = NSString(CString: bytes.map { Int8(bitPattern: $0) }, encoding: NSUTF8StringEncoding)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqualToString(mockUTF8String) ?? false)
    }

    func test_FromMalformedNullTerminatedCStringInUTF8() {
        let bytes = mockMalformedUTF8StringBytes + [0x00]
        let string = NSString(CString: bytes.map { Int8(bitPattern: $0) }, encoding: NSUTF8StringEncoding)
        XCTAssertNil(string)
    }
    
    func test_FromContentOfFile() {
        let testFilePath = testBundle().pathForResource("NSStingTestData", ofType: "txt")
        
        do {
            let str = try NSString(contentsOfFile: testFilePath, encoding: NSUTF8StringEncoding)
        } catch {
            XCTFail("Unable to init NSString from contentsOfFile:encoding:")
        }
        
        XCTAssertEqual(str, "swift-corelibs-foundation")
    }

    func test_uppercaseString() {
        XCTAssertEqual(NSString(stringLiteral: "abcd").uppercaseString, "ABCD")
        XCTAssertEqual(NSString(stringLiteral: "ａｂｃｄ").uppercaseString, "ＡＢＣＤ") // full-width
        XCTAssertEqual(NSString(stringLiteral: "абВГ").uppercaseString, "АБВГ")
        XCTAssertEqual(NSString(stringLiteral: "たちつてと").uppercaseString, "たちつてと")

        // Special casing (see swift/validation-tests/stdlib/NSStringAPI.swift)
        XCTAssertEqual(NSString(stringLiteral: "\u{0069}").uppercaseStringWithLocale(NSLocale(localeIdentifier: "en")), "\u{0049}")
        // Currently fails; likely there are locale loading issues that are preventing this from functioning correctly
        // XCTAssertEqual(NSString(stringLiteral: "\u{0069}").uppercaseStringWithLocale(NSLocale(localeIdentifier: "tr")), "\u{0130}")
        XCTAssertEqual(NSString(stringLiteral: "\u{00df}").uppercaseString, "\u{0053}\u{0053}")
        XCTAssertEqual(NSString(stringLiteral: "\u{fb01}").uppercaseString, "\u{0046}\u{0049}")
    }

    func test_lowercaseString() {
        XCTAssertEqual(NSString(stringLiteral: "abCD").lowercaseString, "abcd")
        XCTAssertEqual(NSString(stringLiteral: "ＡＢＣＤ").lowercaseString, "ａｂｃｄ") // full-width
        XCTAssertEqual(NSString(stringLiteral: "aБВГ").lowercaseString, "aбвг")
        XCTAssertEqual(NSString(stringLiteral: "たちつてと").lowercaseString, "たちつてと")

        // Special casing (see swift/validation-tests/stdlib/NSStringAPI.swift)
        XCTAssertEqual(NSString(stringLiteral: "\u{0130}").lowercaseStringWithLocale(NSLocale(localeIdentifier: "en")), "\u{0069}\u{0307}")
        // Currently fails; likely there are locale loading issues that are preventing this from functioning correctly
        // XCTAssertEqual(NSString(stringLiteral: "\u{0130}").lowercaseStringWithLocale(NSLocale(localeIdentifier: "tr")), "\u{0069}")
        XCTAssertEqual(NSString(stringLiteral: "\u{0049}\u{0307}").lowercaseStringWithLocale(NSLocale(localeIdentifier: "en")), "\u{0069}\u{0307}")
        // Currently fails; likely there are locale loading issues that are preventing this from functioning correctly
        // XCTAssertEqual(NSString(stringLiteral: "\u{0049}\u{0307}").lowercaseStringWithLocale(NSLocale(localeIdentifier: "tr")), "\u{0069}")
    }

    func test_capitalizedString() {
        XCTAssertEqual(NSString(stringLiteral: "foo Foo fOO FOO").capitalizedString, "Foo Foo Foo Foo")
        XCTAssertEqual(NSString(stringLiteral: "жжж").capitalizedString, "Жжж")
    }

    func test_longLongValue() {
        let string1: NSString = "123"
        XCTAssertEqual(string1.longLongValue, 123)

        let string2: NSString = "123a"
        XCTAssertEqual(string2.longLongValue, 123)

        let string3: NSString = "-123a"
        XCTAssertEqual(string3.longLongValue, -123)

        let string4: NSString = "a123"
        XCTAssertEqual(string4.longLongValue, 0)

        let string5: NSString = "+123"
        XCTAssertEqual(string5.longLongValue, 123)

        let string6: NSString = "++123"
        XCTAssertEqual(string6.longLongValue, 0)

        let string7: NSString = "-123"
        XCTAssertEqual(string7.longLongValue, -123)

        let string8: NSString = "--123"
        XCTAssertEqual(string8.longLongValue, 0)

        let string9: NSString = "999999999999999999999999999999"
        XCTAssertEqual(string9.longLongValue, Int64.max)

        let string10: NSString = "-999999999999999999999999999999"
        XCTAssertEqual(string10.longLongValue, Int64.min)
    }
    
    func test_rangeOfCharacterFromSet() {
        let string: NSString = "0Az"
        let letters = NSCharacterSet.letterCharacterSet()
        let decimalDigits = NSCharacterSet.decimalDigitCharacterSet()
        XCTAssertEqual(string.rangeOfCharacterFromSet(letters).location, 1)
        XCTAssertEqual(string.rangeOfCharacterFromSet(decimalDigits).location, 0)
        XCTAssertEqual(string.rangeOfCharacterFromSet(letters, options: [.BackwardsSearch]).location, 2)
        XCTAssertEqual(string.rangeOfCharacterFromSet(letters, options: [], range: NSMakeRange(2, 1)).location, 2)
    }
    
    func test_CFStringCreateMutableCopy() {
        let nsstring: NSString = "абВГ"
        let mCopy = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, unsafeBitCast(nsstring, CFStringRef.self))
        let str = unsafeBitCast(mCopy, NSString.self).bridge()
        XCTAssertEqual(nsstring.bridge(), str)
    }
    
    // This test verifies that CFStringGetBytes with a UTF16 encoding works on an NSString backed by a Swift string
    func test_swiftStringUTF16() {
        #if os(OSX) || os(iOS)
        let kCFStringEncodingUTF16 = CFStringBuiltInEncodings.UTF16.rawValue
        #endif

        let testString = "hello world"
        let string = NSString(string: testString)
        let cfString = unsafeBitCast(string, CFStringRef.self)
        
        // Get the bytes as UTF16
        let reservedLength = 50
        var buf : [UInt8] = []
        buf.reserveCapacity(reservedLength)
        var usedLen : CFIndex = 0
        buf.withUnsafeMutableBufferPointer { p in
            CFStringGetBytes(cfString, CFRangeMake(0, CFStringGetLength(cfString)), CFStringEncoding(kCFStringEncodingUTF16), 0, false, p.baseAddress, reservedLength, &usedLen)
        }
        
        // Make a new string out of it
        let newCFString = CFStringCreateWithBytes(nil, buf, usedLen, CFStringEncoding(kCFStringEncodingUTF16), false)
        let newString = unsafeBitCast(newCFString, NSString.self)
        
        XCTAssertTrue(newString.isEqualToString(testString))
    }
}
