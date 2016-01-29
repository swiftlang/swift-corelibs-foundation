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

#if os(OSX) || os(iOS)
internal let kCFStringEncodingMacRoman =  CFStringBuiltInEncodings.MacRoman.rawValue
internal let kCFStringEncodingWindowsLatin1 =  CFStringBuiltInEncodings.WindowsLatin1.rawValue
internal let kCFStringEncodingISOLatin1 =  CFStringBuiltInEncodings.ISOLatin1.rawValue
internal let kCFStringEncodingNextStepLatin =  CFStringBuiltInEncodings.NextStepLatin.rawValue
internal let kCFStringEncodingASCII =  CFStringBuiltInEncodings.ASCII.rawValue
internal let kCFStringEncodingUnicode =  CFStringBuiltInEncodings.Unicode.rawValue
internal let kCFStringEncodingUTF8 =  CFStringBuiltInEncodings.UTF8.rawValue
internal let kCFStringEncodingNonLossyASCII =  CFStringBuiltInEncodings.NonLossyASCII.rawValue
internal let kCFStringEncodingUTF16 = CFStringBuiltInEncodings.UTF16.rawValue
internal let kCFStringEncodingUTF16BE =  CFStringBuiltInEncodings.UTF16BE.rawValue
internal let kCFStringEncodingUTF16LE =  CFStringBuiltInEncodings.UTF16LE.rawValue
internal let kCFStringEncodingUTF32 =  CFStringBuiltInEncodings.UTF32.rawValue
internal let kCFStringEncodingUTF32BE =  CFStringBuiltInEncodings.UTF32BE.rawValue
internal let kCFStringEncodingUTF32LE =  CFStringBuiltInEncodings.UTF32LE.rawValue
#endif


class TestNSString : XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
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
            ("test_FromContentsOfURL",test_FromContentsOfURL),
            ("test_FromContentOfFile",test_FromContentOfFile),
            ("test_swiftStringUTF16", test_swiftStringUTF16),
            // This test takes forever on build servers; it has been seen up to 1852.084 seconds
//            ("test_completePathIntoString", test_completePathIntoString),
            ("test_stringByTrimmingCharactersInSet", test_stringByTrimmingCharactersInSet),
            ("test_initializeWithFormat", test_initializeWithFormat),
            ("test_initializeWithFormat2", test_initializeWithFormat2),
            ("test_stringByDeletingLastPathComponent", test_stringByDeletingLastPathComponent),
            ("test_getCString_simple", test_getCString_simple),
            ("test_getCString_nonASCII_withASCIIAccessor", test_getCString_nonASCII_withASCIIAccessor),
            ("test_NSHomeDirectoryForUser", test_NSHomeDirectoryForUser),
            ("test_stringByResolvingSymlinksInPath", test_stringByResolvingSymlinksInPath),
            ("test_stringByExpandingTildeInPath", test_stringByExpandingTildeInPath),
            ("test_stringByStandardizingPath", test_stringByStandardizingPath),
            ("test_ExternalRepresentation", test_ExternalRepresentation),
            ("test_mutableStringConstructor", test_mutableStringConstructor),
            ("test_PrefixSuffix", test_PrefixSuffix),
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
        XCTAssertTrue(externalString.length >= 4)
        
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

    func test_FromContentsOfURL() {
        guard let testFileURL = testBundle().URLForResource("NSStringTestData", withExtension: "txt") else {
            XCTFail("URL for NSStringTestData.txt is nil")
            return
        }

        do {
            let string = try NSString(contentsOfURL: testFileURL, encoding: NSUTF8StringEncoding)
            XCTAssertEqual(string, "swift-corelibs-foundation")
        } catch {
            XCTFail("Unable to init NSString from contentsOfURL:encoding:")
        }
        do {
            let string = try NSString(contentsOfURL: testFileURL, encoding: NSUTF16StringEncoding)
            XCTAssertNotEqual(string, "swift-corelibs-foundation", "Wrong result when reading UTF-8 file with UTF-16 encoding in contentsOfURL:encoding")
        } catch {
            XCTFail("Unable to init NSString from contentsOfURL:encoding:")
        }
    }

    func test_FromContentOfFile() {
        let testFilePath = testBundle().pathForResource("NSStringTestData", ofType: "txt")
        XCTAssertNotNil(testFilePath)
        
        do {
            let str = try NSString(contentsOfFile: testFilePath!, encoding: NSUTF8StringEncoding)
            XCTAssertEqual(str, "swift-corelibs-foundation")
        } catch {
            XCTFail("Unable to init NSString from contentsOfFile:encoding:")
        }
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
    
    func test_completePathIntoString() {
        let fileNames = [
            "/tmp/Test_completePathIntoString_01",
            "/tmp/test_completePathIntoString_02",
            "/tmp/test_completePathIntoString_01.txt",
            "/tmp/test_completePathIntoString_01.dat",
            "/tmp/test_completePathIntoString_03.DAT"
        ]
        
        guard ensureFiles(fileNames) else {
            XCTAssert(false, "Could not create temp files for testing.")
            return
        }

        let tmpPath = { (path: String) -> NSString in
        	return "/tmp/\(path)".bridge()
        }

        do {
            let path: NSString = tmpPath("")
            var outName: NSString?
            var matches: [NSString] = []
            _ = path.completePathIntoString(&outName, caseSensitive: false, matchesIntoArray: &matches, filterTypes: nil)
            _ = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(NSURL(string: path.bridge())!, includingPropertiesForKeys: nil, options: [])
            XCTAssert(outName == "/", "If NSString is valid path to directory which has '/' suffix then outName is '/'.")
            // This assert fails on CI; https://bugs.swift.org/browse/SR-389
//            XCTAssert(matches.count == content.count && matches.count == count, "If NSString is valid path to directory then matches contain all content of directory. expected \(content) but got \(matches)")
        } catch {
            XCTAssert(false, "Could not finish test due to error")
        }
        
        do {
            let path: NSString = "/tmp"
            var outName: NSString?
            var matches: [NSString] = []
            _ = path.completePathIntoString(&outName, caseSensitive: false, matchesIntoArray: &matches, filterTypes: nil)
            let urlToTmp = NSURL(fileURLWithPath: "/private/tmp/").URLByStandardizingPath!
            _ = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(urlToTmp, includingPropertiesForKeys: nil, options: [])
            XCTAssert(outName == "/tmp/", "If path could be completed to existing directory then outName is a string itself plus '/'.")
            // This assert fails on CI; https://bugs.swift.org/browse/SR-389
            //            XCTAssert(matches.count == content.count && matches.count == count, "If NSString is valid path to directory then matches contain all content of directory. expected \(content) but got \(matches)")
        } catch {
            XCTAssert(false, "Could not finish test due to error")
        }
        
        let fileNames2 = [
            "/tmp/ABC/",
            "/tmp/ABCD/",
            "/tmp/abcde"
        ]
        
        guard ensureFiles(fileNames2) else {
            XCTAssert(false, "Could not create temp files for testing.")
            return
        }
        
        do {
            let path: NSString = tmpPath("ABC")
            var outName: NSString?
            var matches: [NSString] = []
            let count = path.completePathIntoString(&outName, caseSensitive: false, matchesIntoArray: &matches, filterTypes: nil)
            XCTAssert(stringsAreCaseInsensitivelyEqual(outName!, path), "If NSString is valid path to directory then outName is string itself.")
            XCTAssert(matches.count == count && count == fileNames2.count, "")
        }
        
        do {
            let path: NSString = tmpPath("Test_completePathIntoString_01")
            var outName: NSString?
            var matches: [NSString] = []
            let count = path.completePathIntoString(&outName, caseSensitive: true, matchesIntoArray: &matches, filterTypes: nil)
            XCTAssert(outName == path, "If NSString is valid path to file and search is case sensitive then outName is string itself.")
            XCTAssert(matches.count == 1 && count == 1 && stringsAreCaseInsensitivelyEqual(matches[0], path), "If NSString is valid path to file and search is case sensitive then matches contain that file path only")
        }
        
		do {
            let path: NSString = tmpPath("Test_completePathIntoString_01")
            var outName: NSString?
            var matches: [NSString] = []
            let count = path.completePathIntoString(&outName, caseSensitive: false, matchesIntoArray: &matches, filterTypes: nil)
            XCTAssert(stringsAreCaseInsensitivelyEqual(outName!, path), "If NSString is valid path to file and search is case insensitive then outName is string equal to self.")
            XCTAssert(matches.count == 3 && count == 3, "Matches contain all files with similar name.")
        }

        do {
            let path = tmpPath(NSUUID().UUIDString)
            var outName: NSString?
            var matches: [NSString] = []
            let count = path.completePathIntoString(&outName, caseSensitive: false, matchesIntoArray: &matches, filterTypes: nil)
            XCTAssert(outName == nil, "If no matches found then outName is nil.")
            XCTAssert(matches.count == 0 && count == 0, "If no matches found then return 0 and matches is empty.")
        }

        do {
            let path: NSString = ""
            var outName: NSString?
            var matches: [NSString] = []
            let count = path.completePathIntoString(&outName, caseSensitive: false, matchesIntoArray: &matches, filterTypes: nil)
            XCTAssert(outName == nil, "If no matches found then outName is nil.")
            XCTAssert(matches.count == 0 && count == 0, "If no matches found then return 0 and matches is empty.")
        }

        do {
            let path: NSString = tmpPath("test_c")
            var outName: NSString?
            var matches: [NSString] = []
            // case insensetive
            let count = path.completePathIntoString(&outName, caseSensitive: false, matchesIntoArray: &matches, filterTypes: nil)
            XCTAssert(stringsAreCaseInsensitivelyEqual(outName!, tmpPath("Test_completePathIntoString_0")), "If there are matches then outName should be longest common prefix of all matches.")
            XCTAssert(matches.count == fileNames.count && count == fileNames.count, "If there are matches then matches array contains them.")
        }
        
        do {
            let path: NSString = tmpPath("test_c")
            var outName: NSString?
            var matches: [NSString] = []
            // case sensetive
            let count = path.completePathIntoString(&outName, caseSensitive: true, matchesIntoArray: &matches, filterTypes: nil)
            XCTAssert(outName == tmpPath("test_completePathIntoString_0"), "If there are matches then outName should be longest common prefix of all matches.")
            XCTAssert(matches.count == 4 && count == 4, "Supports case sensetive search")
        }
        
        do {
            let path: NSString = tmpPath("test_c")
            var outName: NSString?
            var matches: [NSString] = []
            // case sensetive
            let count = path.completePathIntoString(&outName, caseSensitive: true, matchesIntoArray: &matches, filterTypes: ["DAT"])
            XCTAssert(outName == tmpPath("test_completePathIntoString_03.DAT"), "If there are matches then outName should be longest common prefix of all matches.")
            XCTAssert(matches.count == 1 && count == 1, "Supports case sensetive search by extensions")
        }
        
        do {
            let path: NSString = tmpPath("test_c")
            var outName: NSString?
            var matches: [NSString] = []
            // type by filter
            let count = path.completePathIntoString(&outName, caseSensitive: false, matchesIntoArray: &matches, filterTypes: ["txt", "dat"])
            XCTAssert(stringsAreCaseInsensitivelyEqual(outName!, tmpPath("test_completePathIntoString_0")), "If there are matches then outName should be longest common prefix of all matches.")
            XCTAssert(matches.count == 3 && count == 3, "Supports filtration by type")
        }
        
        do {
            // will be resolved against current working directory that is directory there results of build process are stored
            let path: NSString = "TestFoundation"
            var outName: NSString?
            var matches: [NSString] = []
            let count = path.completePathIntoString(&outName, caseSensitive: false, matchesIntoArray: &matches, filterTypes: nil)
            // Build directory at least contains executable itself and *.swiftmodule directory
            XCTAssert(matches.count == count && count >= 2, "Supports relative paths.")
            XCTAssert(startWith(path.bridge(), strings: matches), "For relative paths matches are relative too.")
        }
        
        // Next check has no sense on Linux due to case sensitive file system.
        #if os(OSX)
        guard ensureFiles(["/tmp/ABC/temp.txt"]) else {
            XCTAssert(false, "Could not create temp files for testing.")
            return
        }
        
        do {
            let path: NSString = tmpPath("aBc/t")
            var outName: NSString?
            var matches: [NSString] = []
            // type by filter
            let count = path.completePathIntoString(&outName, caseSensitive: true, matchesIntoArray: &matches, filterTypes: ["txt", "dat"])
            XCTAssert(outName == tmpPath("aBc/temp.txt"), "outName starts with receiver.")
            XCTAssert(matches.count >= 1 && count >= 1, "There are matches")
        }
        #endif
    }
    
    private func startWith(prefix: String, strings: [NSString]) -> Bool {
        for item in strings {
            guard item.hasPrefix(prefix) else {
                return false
            }
        }
        
        return true
    }
    
    private func stringsAreCaseInsensitivelyEqual(lhs: NSString, _ rhs: NSString) -> Bool {
    	return lhs.compare(rhs.bridge(), options: .CaseInsensitiveSearch) == .OrderedSame
    }

    func test_stringByTrimmingCharactersInSet() {
        let characterSet = NSCharacterSet.whitespaceCharacterSet()
        let string: NSString = " abc   "
        XCTAssertEqual(string.stringByTrimmingCharactersInSet(characterSet), "abc")
    }
    
    func test_initializeWithFormat() {
        let argument: [CVarArgType] = [42, 42.0]
        withVaList(argument) {
            pointer in
            let string = NSString(format: "Value is %d (%.1f)", arguments: pointer)
            XCTAssertEqual(string, "Value is 42 (42.0)")
        }
    }
    
    func test_initializeWithFormat2() {
        let argument: UInt8 = 75
        let string = NSString(format: "%02X", argument)
        XCTAssertEqual(string, "4B")
    }
    
    func test_stringByDeletingLastPathComponent() {
        do {
            let path: NSString = "/tmp/scratch.tiff"
            let result = path.stringByDeletingLastPathComponent
            XCTAssertEqual(result, "/tmp")
        }
        
        do {
            let path: NSString = "/tmp/lock/"
            let result = path.stringByDeletingLastPathComponent
            XCTAssertEqual(result, "/tmp")
        }
        
        do {
            let path: NSString = "/tmp/"
            let result = path.stringByDeletingLastPathComponent
            XCTAssertEqual(result, "/")
        }
        
        do {
            let path: NSString = "/tmp"
            let result = path.stringByDeletingLastPathComponent
            XCTAssertEqual(result, "/")
        }
        
        do {
            let path: NSString = "/"
            let result = path.stringByDeletingLastPathComponent
            XCTAssertEqual(result, "/")
        }
        
        do {
            let path: NSString = "scratch.tiff"
            let result = path.stringByDeletingLastPathComponent
            XCTAssertEqual(result, "")
        }
        
        do {
            let path: NSString = "foo/bar"
            let result = path.stringByDeletingLastPathComponent
            XCTAssertEqual(result, "foo", "Relative path stays relative.")
        }
    }
    
    func test_stringByResolvingSymlinksInPath() {
        do {
            let path: NSString = "foo/bar"
            let result = path.stringByResolvingSymlinksInPath
            XCTAssertEqual(result, "foo/bar", "For relative paths, symbolic links that can’t be resolved are left unresolved in the returned string.")
        }
        
        do {
            let path: NSString = "/tmp/.."
            let result = path.stringByResolvingSymlinksInPath
            
            #if os(OSX)
            let expected = "/private"
            #else
            let expected = "/"
            #endif
            
            XCTAssertEqual(result, expected, "For absolute paths, all symbolic links are guaranteed to be removed.")
        }

        do {
            let path: NSString = "tmp/.."
            let result = path.stringByResolvingSymlinksInPath
            XCTAssertEqual(result, "tmp/..", "Parent links could be resolved for absolute paths only.")
        }
        
        do {
            let path: NSString = "/tmp/"
            let result = path.stringByResolvingSymlinksInPath
            XCTAssertEqual(result, "/tmp", "Result doesn't contain trailing slash.")
        }
        
        do {
            let path: NSString = "http://google.com/search/.."
            let result = path.stringByResolvingSymlinksInPath
            XCTAssertEqual(result, "http:/google.com/search/..", "stringByResolvingSymlinksInPath treats receiver as file path always")
        }
        
        do {
            let path: NSString = "file:///tmp/.."
            let result = path.stringByResolvingSymlinksInPath
            XCTAssertEqual(result, "file:/tmp/..", "stringByResolvingSymlinksInPath treats receiver as file path always")
        }
    }

    func test_getCString_simple() {
        let str: NSString = "foo"
        var chars = [Int8](count:4, repeatedValue:0xF)
        let count = chars.count
        let expected: [Int8] = [102, 111, 111, 0]
        var res: Bool = false
        chars.withUnsafeMutableBufferPointer() {
            let ptr = $0.baseAddress
            res = str.getCString(ptr, maxLength: count, encoding: NSASCIIStringEncoding)
        }
        XCTAssertTrue(res, "getCString should work on simple strings with ascii string encoding")
        XCTAssertEqual(chars, expected, "getCString on \(str) should have resulted in \(expected) but got \(chars)")
    }
    
    func test_getCString_nonASCII_withASCIIAccessor() {
        let str: NSString = "ƒoo"
        var chars = [Int8](count:5, repeatedValue:0xF)
        let expected: [Int8] = [-58, -110, 111, 111, 0]
        let count = chars.count
        var res: Bool = false
        chars.withUnsafeMutableBufferPointer() {
            let ptr = $0.baseAddress
            res = str.getCString(ptr, maxLength: count, encoding: NSASCIIStringEncoding)
        }
        XCTAssertFalse(res, "getCString should not work on non ascii strings accessing as ascii string encoding")
        chars.withUnsafeMutableBufferPointer() {
            let ptr = $0.baseAddress
            res = str.getCString(ptr, maxLength: count, encoding: NSUTF8StringEncoding)
        }
        XCTAssertTrue(res, "getCString should work on UTF8 encoding")
        XCTAssertEqual(chars, expected, "getCString on \(str) should have resulted in \(expected) but got \(chars)")
    }
    
    func test_NSHomeDirectoryForUser() {
        let homeDir = NSHomeDirectoryForUser(nil)
        let userName = NSUserName()
        let homeDir2 = NSHomeDirectoryForUser(userName)
        let homeDir3 = NSHomeDirectory()
        XCTAssert(homeDir != nil && homeDir == homeDir2 && homeDir == homeDir3, "Could get user' home directory")
    }
    
    func test_stringByExpandingTildeInPath() {
        do {
            let path: NSString = "~"
            let result = path.stringByExpandingTildeInPath
            XCTAssert(result == NSHomeDirectory(), "Could resolve home directory for current user")
            XCTAssertFalse(result.hasSuffix("/"), "Result have no trailing path separator")
        }
        
        do {
            let path: NSString = "~/"
            let result = path.stringByExpandingTildeInPath
            XCTAssert(result == NSHomeDirectory(), "Could resolve home directory for current user")
            XCTAssertFalse(result.hasSuffix("/"), "Result have no trailing path separator")
        }
        
        do {
            let path = NSString(string: "~\(NSUserName())")
            let result = path.stringByExpandingTildeInPath
            XCTAssert(result == NSHomeDirectory(), "Could resolve home directory for specific user")
            XCTAssertFalse(result.hasSuffix("/"), "Result have no trailing path separator")
        }
        
        do {
            let userName = NSUUID().UUIDString
            let path = NSString(string: "~\(userName)/")
            let result = path.stringByExpandingTildeInPath
          	// next assert fails in VirtualBox because home directory for unknown user resolved to /var/run/vboxadd
            XCTAssert(result == "~\(userName)", "Return copy of reciver if home directory could no be resolved.")
        }
    }
    
    func test_stringByStandardizingPath() {
        
        // tmp is special because it is symlinked to /private/tmp and this /private prefix should be dropped,
        // so tmp is tmp. On Linux tmp is not symlinked so it would be the same.
        do {
            let path: NSString = "/.//tmp/ABC/.."
            let result = path.stringByStandardizingPath
            XCTAssertEqual(result, "/tmp", "stringByStandardizingPath removes extraneous path components and resolve symlinks.")
        }
        
        do {
            let path: NSString =  "~"
            let result = path.stringByStandardizingPath
            let expected = NSHomeDirectory()
            XCTAssertEqual(result, expected, "stringByStandardizingPath expanding initial tilde.")
        }
        
        do {
            let path: NSString =  "~/foo/bar/"
            let result = path.stringByStandardizingPath
            let expected = NSHomeDirectory() + "/foo/bar"
            XCTAssertEqual(result, expected, "stringByStandardizingPath expanding initial tilde.")
        }
        
        // relative file paths depend on file path standardizing that is not yet implemented
        do {
            let path: NSString = "foo/bar"
            let result = path.stringByStandardizingPath
            XCTAssertEqual(result, path.bridge(), "stringByStandardizingPath doesn't resolve relative paths")
        }
        
        // tmp is symlinked on OS X only
        #if os(OSX)
        do {
            let path: NSString = "/tmp/.."
            let result = path.stringByStandardizingPath
            XCTAssertEqual(result, "/private")
        }
        #endif
        
        do {
            let path: NSString = "/tmp/ABC/.."
            let result = path.stringByStandardizingPath
            XCTAssertEqual(result, "/tmp", "parent links could be resolved for absolute paths")
        }
        
        do {
            let path: NSString = "tmp/ABC/.."
            let result = path.stringByStandardizingPath
            XCTAssertEqual(result, path.bridge(), "parent links could not be resolved for relative paths")
        }
    }
    
    func test_ExternalRepresentation() {
        // Ensure NSString can be used to create an external data representation
        
        let UTF8Encoding = CFStringEncoding(kCFStringEncodingUTF8)
        let UTF16Encoding = CFStringEncoding(kCFStringEncodingUTF16)
        let ISOLatin1Encoding = CFStringEncoding(kCFStringEncodingISOLatin1)
        
        do {
            let string = unsafeBitCast(NSString(string: "this is an external string that should be representable by data"), CFStringRef.self)
            let UTF8Data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, string, UTF8Encoding, 0)
            let UTF8Length = CFDataGetLength(UTF8Data)
            XCTAssertEqual(UTF8Length, 63, "NSString should successfully produce an external UTF8 representation with a length of 63 but got \(UTF8Length) bytes")
            
            let UTF16Data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, string, UTF16Encoding, 0)
            let UTF16Length = CFDataGetLength(UTF16Data)
            XCTAssertEqual(UTF16Length, 128, "NSString should successfully produce an external UTF16 representation with a length of 128 but got \(UTF16Length) bytes")
            
            let ISOLatin1Data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, string, ISOLatin1Encoding, 0)
            let ISOLatin1Length = CFDataGetLength(ISOLatin1Data)
            XCTAssertEqual(ISOLatin1Length, 63, "NSString should successfully produce an external ISOLatin1 representation with a length of 63 but got \(ISOLatin1Length) bytes")
        }
        
        do {
            let string = unsafeBitCast(NSString(string: "🐢 encoding all the way down. 🐢🐢🐢"), CFStringRef.self)
            let UTF8Data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, string, UTF8Encoding, 0)
            let UTF8Length = CFDataGetLength(UTF8Data)
            XCTAssertEqual(UTF8Length, 44, "NSString should successfully produce an external UTF8 representation with a length of 44 but got \(UTF8Length) bytes")
            
            let UTF16Data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, string, UTF16Encoding, 0)
            let UTF16Length = CFDataGetLength(UTF16Data)
            XCTAssertEqual(UTF16Length, 74, "NSString should successfully produce an external UTF16 representation with a length of 74 but got \(UTF16Length) bytes")
            
            let ISOLatin1Data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, string, ISOLatin1Encoding, 0)
            XCTAssertNil(ISOLatin1Data)
        }
    }
    
    func test_mutableStringConstructor() {
        let mutableString = NSMutableString(string: "Test")
        XCTAssertEqual(mutableString, "Test")
    }
}

struct ComparisonTest {
    let lhs: String
    let rhs: String
    let loc: UInt
    let reason: String

    var xfail: Bool {
      return !reason.isEmpty
    }

    init(
        _ lhs: String, _ rhs: String,
        reason: String = "", line: UInt = __LINE__
    ) {
        self.lhs = lhs
        self.rhs = rhs
        self.reason = reason
        self.loc = line
    }
}

let comparisonTests = [
    ComparisonTest("", ""),
    ComparisonTest("", "a"),

    // ASCII cases
    ComparisonTest("t", "tt"),
    ComparisonTest("t", "Tt"),
    ComparisonTest("\u{0}", ""),
    ComparisonTest("\u{0}", "\u{0}",
        reason: "https://bugs.swift.org/browse/SR-332"),
    ComparisonTest("\r\n", "t"),
    ComparisonTest("\r\n", "\n",
        reason: "blocked on rdar://problem/19036555"),
    ComparisonTest("\u{0}", "\u{0}\u{0}",
        reason: "rdar://problem/19034601"),

    // Whitespace
    // U+000A LINE FEED (LF)
    // U+000B LINE TABULATION
    // U+000C FORM FEED (FF)
    // U+0085 NEXT LINE (NEL)
    // U+2028 LINE SEPARATOR
    // U+2029 PARAGRAPH SEPARATOR
    ComparisonTest("\u{0085}", "\n"),
    ComparisonTest("\u{000b}", "\n"),
    ComparisonTest("\u{000c}", "\n"),
    ComparisonTest("\u{2028}", "\n"),
    ComparisonTest("\u{2029}", "\n"),
    ComparisonTest("\r\n\r\n", "\r\n"),

    // U+0301 COMBINING ACUTE ACCENT
    // U+00E1 LATIN SMALL LETTER A WITH ACUTE
    ComparisonTest("a\u{301}", "\u{e1}"),
    ComparisonTest("a", "a\u{301}"),
    ComparisonTest("a", "\u{e1}"),

    // U+304B HIRAGANA LETTER KA
    // U+304C HIRAGANA LETTER GA
    // U+3099 COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK
    ComparisonTest("\u{304b}", "\u{304b}"),
    ComparisonTest("\u{304c}", "\u{304c}"),
    ComparisonTest("\u{304b}", "\u{304c}"),
    ComparisonTest("\u{304b}", "\u{304c}\u{3099}"),
    ComparisonTest("\u{304c}", "\u{304b}\u{3099}"),
    ComparisonTest("\u{304c}", "\u{304c}\u{3099}"),

    // U+212B ANGSTROM SIGN
    // U+030A COMBINING RING ABOVE
    // U+00C5 LATIN CAPITAL LETTER A WITH RING ABOVE
    ComparisonTest("\u{212b}", "A\u{30a}"),
    ComparisonTest("\u{212b}", "\u{c5}"),
    ComparisonTest("A\u{30a}", "\u{c5}"),
    ComparisonTest("A\u{30a}", "a"),
    ComparisonTest("A", "A\u{30a}"),

    // U+2126 OHM SIGN
    // U+03A9 GREEK CAPITAL LETTER OMEGA
    ComparisonTest("\u{2126}", "\u{03a9}"),

    // U+0323 COMBINING DOT BELOW
    // U+0307 COMBINING DOT ABOVE
    // U+1E63 LATIN SMALL LETTER S WITH DOT BELOW
    // U+1E69 LATIN SMALL LETTER S WITH DOT BELOW AND DOT ABOVE
    ComparisonTest("\u{1e69}", "s\u{323}\u{307}"),
    ComparisonTest("\u{1e69}", "s\u{307}\u{323}"),
    ComparisonTest("\u{1e69}", "\u{1e63}\u{307}"),
    ComparisonTest("\u{1e63}", "s\u{323}"),
    ComparisonTest("\u{1e63}\u{307}", "s\u{323}\u{307}"),
    ComparisonTest("\u{1e63}\u{307}", "s\u{307}\u{323}"),
    ComparisonTest("s\u{323}", "\u{1e69}"),

    // U+FB01 LATIN SMALL LIGATURE FI
    ComparisonTest("\u{fb01}", "\u{fb01}"),
    ComparisonTest("fi", "\u{fb01}"),

    // U+1F1E7 REGIONAL INDICATOR SYMBOL LETTER B
    // \u{1F1E7}\u{1F1E7} Flag of Barbados
    ComparisonTest("\u{1F1E7}", "\u{1F1E7}\u{1F1E7}",
        reason: "https://bugs.swift.org/browse/SR-367"),

    // Test that Unicode collation is performed in deterministic mode.
    //
    // U+0301 COMBINING ACUTE ACCENT
    // U+0341 COMBINING ACUTE TONE MARK
    // U+0954 DEVANAGARI ACUTE ACCENT
    //
    // Collation elements from DUCET:
    // 0301  ; [.0000.0024.0002] # COMBINING ACUTE ACCENT
    // 0341  ; [.0000.0024.0002] # COMBINING ACUTE TONE MARK
    // 0954  ; [.0000.0024.0002] # DEVANAGARI ACUTE ACCENT
    //
    // U+0301 and U+0954 don't decompose in the canonical decomposition mapping.
    // U+0341 has a canonical decomposition mapping of U+0301.
    ComparisonTest("\u{0301}", "\u{0341}",
        reason: "https://bugs.swift.org/browse/SR-243"),
    ComparisonTest("\u{0301}", "\u{0954}"),
    ComparisonTest("\u{0341}", "\u{0954}"),
]

enum Stack: ErrorType {
    case Stack([UInt])
}

func checkHasPrefixHasSuffix(lhs: String, _ rhs: String, _ stack: [UInt]) -> Int {
    if lhs == "" {
        var failures = 0
        failures += lhs.hasPrefix(rhs) ? 1 : 0
        failures += lhs.hasSuffix(rhs) ? 1 : 0
        return failures
    }
    if rhs == "" {
        var failures = 0
        failures += lhs.hasPrefix(rhs) ? 1 : 0
        failures += lhs.hasSuffix(rhs) ? 1 : 0
        return failures
    }

    // To determine the expected results, compare grapheme clusters,
    // scalar-to-scalar, of the NFD form of the strings.
    let lhsNFDGraphemeClusters =
        lhs.decomposedStringWithCanonicalMapping.characters.map {
            Array(String($0).unicodeScalars)
    }
    let rhsNFDGraphemeClusters =
        rhs.decomposedStringWithCanonicalMapping.characters.map {
            Array(String($0).unicodeScalars)
    }
    let expectHasPrefix = lhsNFDGraphemeClusters.startsWith(
        rhsNFDGraphemeClusters, isEquivalent: (==))
    let expectHasSuffix =
        lhsNFDGraphemeClusters.lazy.reverse().startsWith(
            rhsNFDGraphemeClusters.lazy.reverse(), isEquivalent: (==))

    func testFailure(lhs: Bool, _ rhs: Bool, _ stack: [UInt]) -> Int {
        guard lhs == rhs else {
            // print(stack)
            return 1
        }
        return 0
    }

    var failures = 0
    failures += testFailure(expectHasPrefix, lhs.hasPrefix(rhs), stack + [__LINE__])
    failures += testFailure(expectHasSuffix, lhs.hasSuffix(rhs), stack + [__LINE__])
    return failures
}

extension TestNSString {
    func test_PrefixSuffix() {
#if !_runtime(_ObjC)
        for test in comparisonTests {
            var failures = 0
            failures += checkHasPrefixHasSuffix(test.lhs, test.rhs, [test.loc, __LINE__])
            failures += checkHasPrefixHasSuffix(test.rhs, test.lhs, [test.loc, __LINE__])

            let fragment = "abc"
            let combiner = "\u{0301}"

            failures += checkHasPrefixHasSuffix(test.lhs + fragment, test.rhs, [test.loc, __LINE__])
            failures += checkHasPrefixHasSuffix(fragment + test.lhs, test.rhs, [test.loc, __LINE__])
            failures += checkHasPrefixHasSuffix(test.lhs + combiner, test.rhs, [test.loc, __LINE__])
            failures += checkHasPrefixHasSuffix(combiner + test.lhs, test.rhs, [test.loc, __LINE__])

            let fail = (failures > 0)
            if fail {
                // print("Prefix/Suffix case \(test.loc): \(failures) failures")
                // print("Failures were\(test.xfail ? "" : " not") expected")
            }
            XCTAssert(test.xfail == fail, "Unexpected \(test.xfail ?"success":"failure"): \(test.loc)")
        }
#endif
    }
}
