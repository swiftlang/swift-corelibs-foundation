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
            ("test_completePathIntoString", test_completePathIntoString),
            ("test_stringByTrimmingCharactersInSet", test_stringByTrimmingCharactersInSet),
            ("test_initializeWithFormat", test_initializeWithFormat),
            ("test_stringByDeletingLastPathComponent", test_stringByDeletingLastPathComponent),
            ("test_getCString_simple", test_getCString_simple),
            ("test_getCString_nonASCII_withASCIIAccessor", test_getCString_nonASCII_withASCIIAccessor),
            ("test_NSHomeDirectoryForUser", test_NSHomeDirectoryForUser)
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
        	#if os(Linux)
        	let tmp = "/tmp/"
        	#else
        	let tmp = "/private/tmp/" // no symlink support yet
        	#endif
        	return "\(tmp)\(path)".bridge()
        }

        do {
            let path: NSString = tmpPath("")
            var outName: NSString?
            var matches: [NSString] = []
            let count = path.completePathIntoString(&outName, caseSensitive: false, matchesIntoArray: &matches, filterTypes: nil)
            let content = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(NSURL(string: path.bridge())!, includingPropertiesForKeys: nil, options: [])
            XCTAssert(outName == path, "If NSString is valid path to directory then outName is string itself.")
            // This assert fails on CI; https://bugs.swift.org/browse/SR-389
//            XCTAssert(matches.count == content.count && matches.count == count, "If NSString is valid path to directory then matches contain all content of directory. expected \(content) but got \(matches)")
        } catch {
            XCTAssert(false, "Could not finish test due to error")
        }
        
        do {
            let path: NSString = tmpPath("Test_completePathIntoString_01")
            var outName: NSString?
            var matches: [NSString] = []
            let count = path.completePathIntoString(&outName, caseSensitive: true, matchesIntoArray: &matches, filterTypes: nil)
            XCTAssert(stringsAreCaseInsensitivelyEqual(outName!, path), "If NSString is valid path to file and search is case sensitive then outName is string itself.")
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
    
    private func stringsAreCaseInsensitivelyEqual(lhs: NSString, _ rhs: NSString) -> Bool {
    	return lhs.compare(rhs.bridge(), options: .CaseInsensitiveSearch) == .OrderedSame
    }

    private func ensureFiles(fileNames: [String]) -> Bool {
        var result = true
        let fm = NSFileManager.defaultManager()
        for name in fileNames {
            guard !fm.fileExistsAtPath(name) else {
                continue
            }
            
            var isDir: ObjCBool = false
            let dir = name.bridge().stringByDeletingLastPathComponent
            if !fm.fileExistsAtPath(dir, isDirectory: &isDir) {
                do {
                    try fm.createDirectoryAtPath(dir, withIntermediateDirectories: true, attributes: nil)
                } catch let err {
                    print(err)
                    return false
                }
            } else if !isDir {
                return false
            }
            
            
            result = result && fm.createFileAtPath(name, contents: nil, attributes: nil)
        }
        return result
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
}
