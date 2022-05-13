// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(macOS) || os(iOS)
internal let kCFStringEncodingMacRoman =  CFStringBuiltInEncodings.macRoman.rawValue
internal let kCFStringEncodingWindowsLatin1 =  CFStringBuiltInEncodings.windowsLatin1.rawValue
internal let kCFStringEncodingISOLatin1 =  CFStringBuiltInEncodings.isoLatin1.rawValue
internal let kCFStringEncodingNextStepLatin =  CFStringBuiltInEncodings.nextStepLatin.rawValue
internal let kCFStringEncodingASCII =  CFStringBuiltInEncodings.ASCII.rawValue
internal let kCFStringEncodingUnicode =  CFStringBuiltInEncodings.unicode.rawValue
internal let kCFStringEncodingUTF8 =  CFStringBuiltInEncodings.UTF8.rawValue
internal let kCFStringEncodingNonLossyASCII =  CFStringBuiltInEncodings.nonLossyASCII.rawValue
internal let kCFStringEncodingUTF16 = CFStringBuiltInEncodings.UTF16.rawValue
internal let kCFStringEncodingUTF16BE =  CFStringBuiltInEncodings.UTF16BE.rawValue
internal let kCFStringEncodingUTF16LE =  CFStringBuiltInEncodings.UTF16LE.rawValue
internal let kCFStringEncodingUTF32 =  CFStringBuiltInEncodings.UTF32.rawValue
internal let kCFStringEncodingUTF32BE =  CFStringBuiltInEncodings.UTF32BE.rawValue
internal let kCFStringEncodingUTF32LE =  CFStringBuiltInEncodings.UTF32LE.rawValue
#endif


class TestNSString: LoopbackServerTest {

    func test_initData() {
        let testString = "\u{00} This is a test string"
        let data = testString.data(using: .utf8)!
        XCTAssertEqual(data.count, 23)
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            if let text1 = NSString(bytes: bytes.baseAddress!, length: data.count, encoding: String.Encoding.utf8.rawValue) {
                XCTAssertEqual(text1.length, data.count)
                XCTAssertEqual(text1, testString as NSString)
            } else {
                XCTFail("Cant convert Data to NSString")
            }
        }

        if let text2 = String(data: data, encoding: .utf8) {
            XCTAssertEqual(text2.count, data.count)
            XCTAssertEqual(text2, testString)
        } else {
            XCTFail("Cant convert Data to String")
        }

        // Test multibyte UTF8 and UTF16
        // kra ("ĸ") has codepoint value 312,
        // as UTF-8  bytes it is 0xC4 0xB8
        // as UTF-16 bytes it is 0x1, 0x38
        let kra = "ĸ"
        let utf8KraData = Data([0xc4, 0xb8])
        if let utf8kra = utf8KraData.withUnsafeBytes( { (bytes: UnsafeRawBufferPointer) -> NSString? in
            return NSString(bytes: bytes.baseAddress!, length: utf8KraData.count, encoding: String.Encoding.utf8.rawValue)
        }) {
            XCTAssertEqual(kra.count, 1)
            XCTAssertEqual(kra.utf8.count, 2)
            XCTAssertEqual(kra.utf16.count, 1)
            XCTAssertEqual(kra, utf8kra as String)
        } else {
            XCTFail("Cant create UTF8 kra")
        }

        let utf16KraData = Data([0x1, 0x38])
        if let utf16kra = utf16KraData.withUnsafeBytes( { (bytes: UnsafeRawBufferPointer) -> NSString? in
            return NSString(bytes: bytes.baseAddress!, length: utf16KraData.count, encoding: String.Encoding.utf16.rawValue)
        }) {
            XCTAssertEqual(kra.count, 1)
            XCTAssertEqual(kra.utf8.count, 2)
            XCTAssertEqual(kra.utf16.count, 1)
            XCTAssertEqual(kra, utf16kra as String)
        } else {
            XCTFail("Cant create UTF16 kra")
        }

        // Test a large string > 255 characters
        let largeString = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut at tincidunt arcu. Suspendisse nec sodales erat, sit amet imperdiet ipsum. Etiam sed ornare felis. Nunc mauris turpis, bibendum non lectus quis, malesuada placerat turpis. Nam adipiscing non massa et semper. Nulla convallis semper bibendum."
        XCTAssertTrue(largeString.count > 255)
        let largeData = largeString.data(using: .utf8)!
        if let largeText = largeData.withUnsafeBytes( { (bytes: UnsafeRawBufferPointer) -> NSString? in
            return NSString(bytes: bytes.baseAddress!, length: largeData.count, encoding: String.Encoding.ascii.rawValue)
        }) {
            XCTAssertEqual(largeText.length, largeString.count)
            XCTAssertEqual(largeText.length, largeData.count)
            XCTAssertEqual(largeString, largeText as String)
        } else {
            XCTFail("Cant convert large Data string to String")
        }
    }

    func test_boolValue() {
        let trueStrings: [NSString] = ["t", "true", "TRUE", "tRuE", "yes", "YES", "1", "+000009"]
        for string in trueStrings {
            XCTAssert(string.boolValue)
        }
        let falseStrings: [NSString] = ["false", "FALSE", "fAlSe", "no", "NO", "0", "<true>", "_true", "-00000", "+t", "+", "0t", "++"]
        for string in falseStrings {
            XCTAssertFalse(string.boolValue)
        }
    }
    
    func test_BridgeConstruction() {
        let literalConversion: NSString = "literal"
        XCTAssertEqual(literalConversion.length, 7)
        
        let nonLiteralConversion = NSString(string: "test\(self)")
        XCTAssertTrue(nonLiteralConversion.length > 4)
        
        let nonLiteral2 = NSString(string: String(4))
        let t = nonLiteral2.character(at: 0)
        XCTAssertTrue(t == 52)
        
        let externalString: NSString = NSString(string: String.localizedName(of: String.defaultCStringEncoding))
        XCTAssertTrue(externalString.length >= 4)
        
        let cluster: NSString = "✌🏾"
        XCTAssertEqual(cluster.length, 3)
    }

    func test_bridging() {
        let nsstring = NSString("NSString")
        let anyNSstring = nsstring as Any

        XCTAssertEqual(nsstring as String, "NSString")
        XCTAssertEqual(nsstring as Substring, "NSString")

        XCTAssertEqual(anyNSstring as! String, "NSString")
        XCTAssertEqual(anyNSstring as! Substring, "NSString")

        XCTAssertEqual(anyNSstring as? String, "NSString")
        XCTAssertEqual(anyNSstring as? Substring, "NSString")

        let string = "String"
        let subString = string.dropFirst()
        XCTAssertEqual(string as NSString, NSString("String"))
        XCTAssertEqual(subString as NSString, NSString("tring"))

        let abc = "abc" as Substring as NSString
        XCTAssertEqual(abc, NSString("abc"))
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

    func test_doubleValue() {
        XCTAssertEqual(NSString(string: ".2").doubleValue, 0.2)
        XCTAssertEqual(NSString(string: "+.2").doubleValue, 0.2)
        XCTAssertEqual(NSString(string: "-.2").doubleValue, -0.2)
        XCTAssertEqual(NSString(string: "1.23015e+3").doubleValue, 1230.15)
        XCTAssertEqual(NSString(string: "12.3015e+02").doubleValue, 1230.15)
        XCTAssertEqual(NSString(string: "+1.23015e+3").doubleValue, 1230.15)
        XCTAssertEqual(NSString(string: "+12.3015e+02").doubleValue, 1230.15)
        XCTAssertEqual(NSString(string: "-1.23015e+3").doubleValue, -1230.15)
        XCTAssertEqual(NSString(string: "-12.3015e+02").doubleValue, -1230.15)
        XCTAssertEqual(NSString(string: "-12.3015e02").doubleValue, -1230.15)
        XCTAssertEqual(NSString(string: "-31.25e-04").doubleValue, -0.003125)

        XCTAssertEqual(NSString(string: ".e12").doubleValue, 0)
        XCTAssertEqual(NSString(string: "2e3.12").doubleValue, 2000)
        XCTAssertEqual(NSString(string: "1e2.3").doubleValue, 100)
        XCTAssertEqual(NSString(string: "12.e4").doubleValue, 120000)
        XCTAssertEqual(NSString(string: "1.2.3.4").doubleValue, 1.2)
        XCTAssertEqual(NSString(string: "1e2.3").doubleValue, 100)
        XCTAssertEqual(NSString(string: "1E3").doubleValue, 1000)
    }
    
    func test_isEqualToStringWithSwiftString() {
        let string: NSString = "literal"
        let swiftString = "literal"
        XCTAssertTrue(string.isEqual(to: swiftString))
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
        let string = NSString(bytes: bytes, length: bytes.count, encoding: String.Encoding.ascii.rawValue)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqual(to: mockASCIIString) ?? false)
    }

    func test_FromUTF8Data() {
        let bytes = mockUTF8StringBytes
        let string = NSString(bytes: bytes, length: bytes.count, encoding: String.Encoding.utf8.rawValue)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqual(to: mockUTF8String) ?? false)
    }

    func test_FromMalformedUTF8Data() {
        let bytes = mockMalformedUTF8StringBytes
        let string = NSString(bytes: bytes, length: bytes.count, encoding: String.Encoding.utf8.rawValue)
        XCTAssertNil(string)
    }

    func test_FromASCIINSData() {
        let bytes = mockASCIIStringBytes
        let data = Data(bytes: bytes, count: bytes.count)
        let string = NSString(data: data, encoding: String.Encoding.ascii.rawValue)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqual(to: mockASCIIString) ?? false)
    }

    func test_FromUTF8NSData() {
        let bytes = mockUTF8StringBytes
        let data = Data(bytes: bytes, count: bytes.count)
        let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqual(to: mockUTF8String) ?? false)
    }

    func test_FromMalformedUTF8NSData() {
        let bytes = mockMalformedUTF8StringBytes
        let data = Data(bytes: bytes, count: bytes.count)
        let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        XCTAssertNil(string)
    }

    func test_FromNullTerminatedCStringInASCII() {
        let bytes = mockASCIIStringBytes + [0x00]
        let string = NSString(cString: bytes.map { Int8(bitPattern: $0) }, encoding: String.Encoding.ascii.rawValue)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqual(to: mockASCIIString) ?? false)
    }

    func test_FromNullTerminatedCStringInUTF8() {
        let bytes = mockUTF8StringBytes + [0x00]
        let string = NSString(cString: bytes.map { Int8(bitPattern: $0) }, encoding: String.Encoding.utf8.rawValue)
        XCTAssertNotNil(string)
        XCTAssertTrue(string?.isEqual(to: mockUTF8String) ?? false)
    }

    func test_FromMalformedNullTerminatedCStringInUTF8() {
        let bytes = mockMalformedUTF8StringBytes + [0x00]
        let string = NSString(cString: bytes.map { Int8(bitPattern: $0) }, encoding: String.Encoding.utf8.rawValue)
        XCTAssertNil(string)
    }

    func test_FromContentsOfURL() {
        guard let testFileURL = testBundle().url(forResource: "NSStringTestData", withExtension: "txt") else {
            XCTFail("URL for NSStringTestData.txt is nil")
            return
        }

        do {
            let string = try NSString(contentsOf: testFileURL, encoding: String.Encoding.utf8.rawValue)
            XCTAssertEqual(string, "swift-corelibs-foundation")
        } catch {
            XCTFail("Unable to init NSString from contentsOf:encoding:")
        }
        do {
            let string = try NSString(contentsOf: testFileURL, encoding: String.Encoding.utf16.rawValue)
            XCTAssertNotEqual(string, "swift-corelibs-foundation", "Wrong result when reading UTF-8 file with UTF-16 encoding in contentsOf:encoding")
        } catch {
            XCTFail("Unable to init NSString from contentsOf:encoding:")
        }

        let url = URL(string: "http://127.0.0.1:\(TestURLSession.serverPort)/NSString-ISO-8859-1-data.txt")!
        var enc: UInt = 0
        let contents = try? NSString(contentsOf: url, usedEncoding: &enc)

        XCTAssertNotNil(contents)
        XCTAssertEqual(enc, String.Encoding.isoLatin1.rawValue)
        if let contents = contents {
            XCTAssertEqual(contents, "This file is encoded as ISO-8859-1\nÀÁÂÃÄÅÿ\n±\n")
        }

        guard let zeroFileURL = testBundle().url(forResource: "TestFileWithZeros", withExtension: "txt") else {
            XCTFail("Cant get URL for TestFileWithZeros.txt")
           return
        }
        guard let zeroString = try? String(contentsOf: zeroFileURL, encoding: .utf8) else {
            XCTFail("Cant create string from \(zeroFileURL)")
            return
        }
        XCTAssertEqual(zeroString, "Some\u{00}text\u{00}with\u{00}NUL\u{00}bytes\u{00}instead\u{00}of\u{00}spaces.\u{00}\n")
    }

    func test_FromContentOfFileUsedEncodingIgnored() {
        let testFilePath = testBundle().path(forResource: "NSStringTestData", ofType: "txt")
        XCTAssertNotNil(testFilePath)
        
        do {
            let str = try NSString(contentsOfFile: testFilePath!, usedEncoding: nil)
            XCTAssertEqual(str, "swift-corelibs-foundation")
        } catch {
            XCTFail("Unable to init NSString from contentsOfFile:encoding:")
        }
    }
    
    func test_FromContentOfFileUsedEncodingUTF8() {
        let testFilePath = testBundle().path(forResource: "NSStringTestData", ofType: "txt")
        XCTAssertNotNil(testFilePath)
        
        do {
            var encoding: UInt = 0
            let str = try NSString(contentsOfFile: testFilePath!, usedEncoding: &encoding)
            XCTAssertEqual(str, "swift-corelibs-foundation")
            XCTAssertEqual(encoding, String.Encoding.utf8.rawValue, "Wrong encoding detected from UTF8 file")
        } catch {
            XCTFail("Unable to init NSString from contentsOfFile:encoding:")
        }
    }

    func test_FromContentsOfURLUsedEncodingUTF16BE() {
      guard let testFileURL = testBundle().url(forResource: "NSString-UTF16-BE-data", withExtension: "txt") else {
        XCTFail("URL for NSString-UTF16-BE-data.txt is nil")
        return
      }

      do {
          var encoding: UInt = 0
          let string = try NSString(contentsOf: testFileURL, usedEncoding: &encoding)
          XCTAssertEqual(string, "NSString fromURL usedEncoding test with UTF16 BE file", "Wrong result when reading UTF16BE file")
          XCTAssertEqual(encoding, String.Encoding.utf16BigEndian.rawValue, "Wrong encoding detected from UTF16BE file")
      } catch {
          XCTFail("Unable to init NSString from contentsOf:usedEncoding:")
      }
    }

    func test_FromContentsOfURLUsedEncodingUTF16LE() {
      guard let testFileURL = testBundle().url(forResource: "NSString-UTF16-LE-data", withExtension: "txt") else {
        XCTFail("URL for NSString-UTF16-LE-data.txt is nil")
        return
      }

      do {
          var encoding: UInt = 0
          let string = try NSString(contentsOf: testFileURL, usedEncoding: &encoding)
          XCTAssertEqual(string, "NSString fromURL usedEncoding test with UTF16 LE file", "Wrong result when reading UTF16LE file")
          XCTAssertEqual(encoding, String.Encoding.utf16LittleEndian.rawValue, "Wrong encoding detected from UTF16LE file")
      } catch {
          XCTFail("Unable to init NSString from contentOf:usedEncoding:")
      }
    }

    func test_FromContentsOfURLUsedEncodingUTF32BE() {
      guard let testFileURL = testBundle().url(forResource: "NSString-UTF32-BE-data", withExtension: "txt") else {
        XCTFail("URL for NSString-UTF32-BE-data.txt is nil")
        return
      }

      do {
         var encoding: UInt = 0
         let string = try NSString(contentsOf: testFileURL, usedEncoding: &encoding)
         XCTAssertEqual(string, "NSString fromURL usedEncoding test with UTF32 BE file", "Wrong result when reading UTF32BE file")
         XCTAssertEqual(encoding, String.Encoding.utf32BigEndian.rawValue, "Wrong encoding detected from UTF32BE file")
      } catch {
          XCTFail("Unable to init NSString from contentOf:usedEncoding:")
      }
    }

    func test_FromContentsOfURLUsedEncodingUTF32LE() {
      guard let testFileURL = testBundle().url(forResource: "NSString-UTF32-LE-data", withExtension: "txt") else {
        XCTFail("URL for NSString-UTF32-LE-data.txt is nil")
        return
      }

      do {
         var encoding: UInt = 0
         let string = try NSString(contentsOf: testFileURL, usedEncoding: &encoding)
         XCTAssertEqual(string, "NSString fromURL usedEncoding test with UTF32 LE file", "Wrong result when reading UTF32LE file")
         XCTAssertEqual(encoding, String.Encoding.utf32LittleEndian.rawValue, "Wrong encoding detected from UTF32LE file")
      } catch {
          XCTFail("Unable to init NSString from contentOf:usedEncoding:")
      }
    }

    func test_FromContentOfFile() {
        let testFilePath = testBundle().path(forResource: "NSStringTestData", ofType: "txt")
        XCTAssertNotNil(testFilePath)
        
        do {
            let str = try NSString(contentsOfFile: testFilePath!, encoding: String.Encoding.utf8.rawValue)
            XCTAssertEqual(str, "swift-corelibs-foundation")
        } catch {
            XCTFail("Unable to init NSString from contentsOfFile:encoding:")
        }
    }

    func test_uppercaseString() {
        XCTAssertEqual(NSString(stringLiteral: "abcd").uppercased, "ABCD")
        XCTAssertEqual(NSString(stringLiteral: "ａｂｃｄ").uppercased, "ＡＢＣＤ") // full-width
        XCTAssertEqual(NSString(stringLiteral: "абВГ").uppercased, "АБВГ")
        XCTAssertEqual(NSString(stringLiteral: "たちつてと").uppercased, "たちつてと")

        // Special casing (see swift/validation-tests/stdlib/NSStringAPI.swift)
        XCTAssertEqual(NSString(stringLiteral: "\u{0069}").uppercased(with: Locale(identifier: "en")), "\u{0049}")
        // Currently fails; likely there are locale loading issues that are preventing this from functioning correctly
        // XCTAssertEqual(NSString(stringLiteral: "\u{0069}").uppercased(with: NSLocale(localeIdentifier: "tr")), "\u{0130}")
        XCTAssertEqual(NSString(stringLiteral: "\u{00df}").uppercased, "\u{0053}\u{0053}")
        XCTAssertEqual(NSString(stringLiteral: "\u{fb01}").uppercased, "\u{0046}\u{0049}")
    }

    func test_lowercaseString() {
        XCTAssertEqual(NSString(stringLiteral: "abCD").lowercased, "abcd")
        XCTAssertEqual(NSString(stringLiteral: "ＡＢＣＤ").lowercased, "ａｂｃｄ") // full-width
        XCTAssertEqual(NSString(stringLiteral: "aБВГ").lowercased, "aбвг")
        XCTAssertEqual(NSString(stringLiteral: "たちつてと").lowercased, "たちつてと")

        // Special casing (see swift/validation-tests/stdlib/NSStringAPI.swift)
        XCTAssertEqual(NSString(stringLiteral: "\u{0130}").lowercased(with: Locale(identifier: "en")), "\u{0069}\u{0307}")
        // Currently fails; likely there are locale loading issues that are preventing this from functioning correctly
        // XCTAssertEqual(NSString(stringLiteral: "\u{0130}").lowercased(with: NSLocale(localeIdentifier: "tr")), "\u{0069}")
        XCTAssertEqual(NSString(stringLiteral: "\u{0049}\u{0307}").lowercased(with: Locale(identifier: "en")), "\u{0069}\u{0307}")
        // Currently fails; likely there are locale loading issues that are preventing this from functioning correctly
        // XCTAssertEqual(NSString(stringLiteral: "\u{0049}\u{0307}").lowercaseStringWithLocale(NSLocale(localeIdentifier: "tr")), "\u{0069}")
    }

    func test_capitalizedString() {
        XCTAssertEqual(NSString(stringLiteral: "foo Foo fOO FOO").capitalized, "Foo Foo Foo Foo")
        XCTAssertEqual(NSString(stringLiteral: "жжж").capitalized, "Жжж")
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
        let letters = CharacterSet.letters
        let decimalDigits = CharacterSet.decimalDigits
        XCTAssertEqual(string.rangeOfCharacter(from: letters).location, 1)
        XCTAssertEqual(string.rangeOfCharacter(from: decimalDigits).location, 0)
        XCTAssertEqual(string.rangeOfCharacter(from: letters, options: .backwards).location, 2)
        XCTAssertEqual(string.rangeOfCharacter(from: letters, options: [], range: NSRange(location: 2, length: 1)).location, 2)
    }
    
    func test_CFStringCreateMutableCopy() {
        let nsstring: NSString = "абВГ"
        XCTAssertEqual(nsstring, nsstring.mutableCopy() as! NSString)
    }
    
    // This test verifies that CFStringGetBytes with a UTF16 encoding works on an NSString backed by a Swift string
    func test_swiftStringUTF16() {
        let testString = "hello world"
        let string = NSString(string: testString)

        // Get the bytes as UTF16
        let data: Data = string.data(using: String.Encoding.utf16.rawValue, allowLossyConversion: false)!

        // Make a new string out of it
        let newString = data.withUnsafeBytes {
            NSString(bytes: $0.baseAddress!, length: $0.count, encoding: String.Encoding.utf16.rawValue)!
        }
        
        XCTAssertTrue(newString.isEqual(to: testString))
    }
    
    func test_completePathIntoString() throws {

        // Check all strings start with a common prefix
        func startWith(_ prefix: String, strings: [String]) -> Bool {
            return strings.contains { !$0.hasPrefix(prefix) } == false
        }

        func stringsAreCaseInsensitivelyEqual(_ lhs: String, _ rhs: String) -> Bool {
            return lhs.compare(rhs, options: .caseInsensitive) == .orderedSame
        }

        try withTemporaryDirectory {
            (tmpDir, tmpDirPath) in

            func tmpPath(_ path: String) -> String {
                // Trailing '/' ensures path is created as a directory not a file
                return tmpDir.appendingPathComponent(path).path + (path.hasSuffix("/") ? "/" : "")
            }

            let fileNames = [
                tmpPath("Test_completePathIntoString_01"),
                tmpPath("test_completePathIntoString_02"),
                tmpPath("test_completePathIntoString_01.txt"),
                tmpPath("test_completePathIntoString_01.dat"),
                tmpPath("test_completePathIntoString_03.DAT"),
            ]

            guard ensureFiles(fileNames) else { throw TestError.fileCreationFailed }

            do {
                let urlToTmp = tmpDir.appendingPathComponent("tmp")
                let path = urlToTmp.path + "/"
                guard ensureFiles([path]) else { throw TestError.fileCreationFailed }

                var outName = ""
                var matches: [String] = []
                let count = path.completePath(into: &outName, caseSensitive: false, matchesInto: &matches, filterTypes: nil)
                XCTAssertEqual(outName, "/", "If NSString is valid path to directory which has '/' suffix then outName is '/'.")
                XCTAssertEqual(matches.count, count)
            } catch {
                XCTFail("Could not finish test due to error: \(error)")
            }

            do {
                // Create a subdirectory with non-matching files
                let urlToTmp = tmpDir.appendingPathComponent("tmp")
                guard ensureFiles([
                    urlToTmp.appendingPathComponent("abc").path,
                    urlToTmp.appendingPathComponent("xyz").path
                ]) else { throw TestError.fileCreationFailed }
                let path = urlToTmp.path

                var outName = ""
                var matches: [String] = []
                let count = path.completePath(into: &outName, caseSensitive: false, matchesInto: &matches, filterTypes: nil)
                let contents = try FileManager.default.contentsOfDirectory(at: urlToTmp, includingPropertiesForKeys: nil, options: [])
                XCTAssertEqual(outName, path + "/", "If path could be completed to existing directory then outName is a string itself plus '/'.")
                XCTAssertEqual(matches.count, count)
                XCTAssertEqual(matches.count, contents.count, "If NSString is valid path to directory then matches contain all content of directory.")
            } catch {
                XCTFail("Could not finish test due to error: \(error)")
            }

            let fileNames2 = [
                tmpPath("ABC/"),
                tmpPath("ABCD/"),
                tmpPath("abcde")
            ]

            guard ensureFiles(fileNames2) else {
                XCTFail( "Could not create temp files for testing.")
                return
            }

            do {
                let path = tmpPath("ABC")
                var outName = ""
                var matches: [String] = []
                let count = path.completePath(into: &outName, caseSensitive: false, matchesInto: &matches, filterTypes: nil)
                XCTAssertTrue(stringsAreCaseInsensitivelyEqual(outName, path), "If NSString is valid path to directory then outName is string itself.")
                XCTAssertEqual(matches.count,count)
                XCTAssertEqual(count, fileNames2.count)
            }

            do {
                let path = tmpPath("Test_completePathIntoString_01")
                var outName = ""
                var matches: [String] = []
                let count = path.completePath(into: &outName, caseSensitive: true, matchesInto: &matches, filterTypes: nil)
                XCTAssertEqual(outName, path, "If NSString is valid path to file and search is case sensitive then outName is string itself.")
                XCTAssertTrue(stringsAreCaseInsensitivelyEqual(matches[0], path), "If NSString is valid path to file and search is case sensitive then matches contain that file path only")
                XCTAssertEqual(matches.count, 1)
                XCTAssertEqual(count, 1)
            }

            do {
                let path = tmpPath("Test_completePathIntoString_01")
                var outName = ""
                var matches: [String] = []
                let count = path.completePath(into: &outName, caseSensitive: false, matchesInto: &matches, filterTypes: nil)
                XCTAssertTrue(stringsAreCaseInsensitivelyEqual(outName, path), "If NSString is valid path to file and search is case insensitive then outName is string equal to self.")
                XCTAssertEqual(matches.count, 3, "Matches contain all files with similar name.")
                XCTAssertEqual(count, 3, "Matches contain all files with similar name.")
            }

            do {
                let path = tmpPath(NSUUID().uuidString)
                var outName = ""
                var matches: [String] = []
                let count = path.completePath(into: &outName, caseSensitive: false, matchesInto: &matches, filterTypes: nil)
                XCTAssertEqual(outName, "", "If no matches found then outName is nil.")
                XCTAssertTrue(matches.isEmpty)
                XCTAssertEqual(count, 0, "If no matches found then return 0 and matches is empty.")
            }

            do {
                let path = ""
                var outName = ""
                var matches: [String] = []
                let count = path.completePath(into: &outName, caseSensitive: false, matchesInto: &matches, filterTypes: nil)
                XCTAssertEqual(outName, "", "If no matches found then outName is nil.")
                XCTAssertTrue(matches.isEmpty)
                XCTAssertEqual(count, 0, "If no matches found then return 0 and matches is empty.")
            }

            do {
                let path = tmpPath("test_c")
                var outName = ""
                var matches: [String] = []
                // case insensitive
                let count = path.completePath(into: &outName, caseSensitive: false, matchesInto: &matches, filterTypes: nil)
                XCTAssertTrue(stringsAreCaseInsensitivelyEqual(outName, tmpPath("Test_completePathIntoString_0")), "If there are matches then outName should be longest common prefix of all matches.")
                XCTAssertEqual(matches.count, fileNames.count, "If there are matches then matches array contains them.")
                XCTAssertEqual(count, fileNames.count)
            }

            do {
                let path = tmpPath("test_c")
                var outName = ""
                var matches: [String] = []
                // case sensitive
                let count = path.completePath(into: &outName, caseSensitive: true, matchesInto: &matches, filterTypes: nil)
                XCTAssertEqual(outName, tmpPath("test_completePathIntoString_0"), "If there are matches then outName should be longest common prefix of all matches.")
                XCTAssertEqual(matches.count, 4, "Supports case sensitive search")
                XCTAssertEqual(count, 4)
            }

            do {
                let path = tmpPath("test_c")
                var outName = ""
                var matches: [String] = []
                // case sensitive
                let count = path.completePath(into: &outName, caseSensitive: true, matchesInto: &matches, filterTypes: ["DAT"])
                XCTAssertEqual(outName, tmpPath("test_completePathIntoString_03.DAT"), "If there are matches then outName should be longest common prefix of all matches.")
                XCTAssertEqual(matches.count, 1, "Supports case sensitive search by extensions")
                XCTAssertEqual(count, 1)
            }

            do {
                let path = tmpPath("test_c")
                var outName = ""
                var matches: [String] = []
                // type by filter
                let count = path.completePath(into: &outName, caseSensitive: false, matchesInto: &matches, filterTypes: ["txt", "dat"])
                XCTAssertTrue(stringsAreCaseInsensitivelyEqual(outName, tmpPath("test_completePathIntoString_0")), "If there are matches then outName should be longest common prefix of all matches.")
                XCTAssertEqual(matches.count, 3, "Supports filtration by type")
                XCTAssertEqual(count, 3)
            }

            do {
                // will be resolved against current working directory that is directory there results of build process are stored
                let path = "TestFoundation"
                var outName = ""
                var matches: [String] = []
                let count = path.completePath(into: &outName, caseSensitive: false, matchesInto: &matches, filterTypes: nil)
                // Build directory at least contains executable itself and *.swiftmodule directory
                XCTAssertEqual(matches.count, count)
                XCTAssertGreaterThanOrEqual(count, 0, "Supports relative paths.")
                XCTAssertTrue(startWith(path, strings: matches), "For relative paths matches are relative too.")
            }

            // Next check has no sense on Linux due to case sensitive file system.
            #if os(macOS)
            guard ensureFiles([tmpPath("ABC/temp.txt")]) else {
                XCTFail("Could not create temp files for testing.")
                return
            }

            do {
                let path = tmpPath("aBc/t")
                var outName = ""
                var matches: [String] = []
                // type by filter
                let count = path.completePath(into: &outName, caseSensitive: true, matchesInto: &matches, filterTypes: ["txt", "dat"])
                XCTAssertEqual(outName, tmpPath("aBc/temp.txt"), "outName starts with receiver.")
                XCTAssertGreaterThanOrEqual(matches.count, 1, "There are matches")
                XCTAssertEqual(matches.count, count)
            }
            #endif
        }
    }


    func test_stringByTrimmingCharactersInSet() {
        let characterSet = CharacterSet.whitespaces
        let string: NSString = " abc   "
        XCTAssertEqual(string.trimmingCharacters(in: characterSet), "abc")
        
        let emojiString: NSString = " \u{1F62C}  "
        XCTAssertEqual(emojiString.trimmingCharacters(in: characterSet), "\u{1F62C}")
    }
    
    func test_initializeWithFormat() {
        let argument: [CVarArg] = [42, 42.0]
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
    
    func test_initializeWithFormat3() {
        let argument: [CVarArg] = [1000, 42.0]
        
        withVaList(argument) {
            pointer in
            let string = NSString(format: "Default value is %d (%.1f)", locale: nil, arguments: pointer)
            XCTAssertEqual(string, "Default value is 1000 (42.0)")
        }
        
        withVaList(argument) {
            pointer in
            let string = NSString(format: "en_GB value is %d (%.1f)", locale: Locale.init(identifier: "en_GB") as AnyObject, arguments: pointer)
            XCTAssertEqual(string, "en_GB value is 1,000 (42.0)")
        }

        withVaList(argument) {
            pointer in
            let string = NSString(format: "de_DE value is %d (%.1f)", locale: Locale.init(identifier: "de_DE") as AnyObject, arguments: pointer)
            XCTAssertEqual(string, "de_DE value is 1.000 (42,0)")
        }
        
        withVaList(argument) {
            pointer in
            let loc: NSDictionary = ["NSDecimalSeparator" as NSString : "&" as NSString]
            let string = NSString(format: "NSDictionary value is %d (%.1f)", locale: loc, arguments: pointer)
            XCTAssertEqual(string, "NSDictionary value is 1000 (42&0)")
        }
    }

    func test_initializeWithFormat4() {
        // The NSString() is required on macOS to work around error: `Type of expression is ambiguous without more context`
        let argument: [CVarArg] = [NSString("One"), NSString("Two"), NSString("Three")]
        withVaList(argument) {
            pointer in
            let string = NSString(format: "Testing %@ %@ %@", arguments: pointer)
            XCTAssertEqual(string, "Testing One Two Three")
        }
    }

    func test_appendingPathComponent() {
        do {
            let path: NSString = "/tmp"
            let result = path.appendingPathComponent("scratch.tiff")
            XCTAssertEqual(result, "/tmp/scratch.tiff")
        }

        do {
            let path: NSString = "/tmp/"
            let result = path.appendingPathComponent("scratch.tiff")
            XCTAssertEqual(result, "/tmp/scratch.tiff")
        }

        do {
            let path: NSString = "/"
            let result = path.appendingPathComponent("scratch.tiff")
            XCTAssertEqual(result, "/scratch.tiff")
        }

        do {
            let path: NSString = ""
            let result = path.appendingPathComponent("scratch.tiff")
            XCTAssertEqual(result, "scratch.tiff")
        }                        
    }
    
    func test_deletingLastPathComponent() {
        do {
            let path: NSString = "/tmp/scratch.tiff"
            let result = path.deletingLastPathComponent
            XCTAssertEqual(result, "/tmp")
        }
        
        do {
            let path: NSString = "/tmp/lock/"
            let result = path.deletingLastPathComponent
            XCTAssertEqual(result, "/tmp")
        }
        
        do {
            let path: NSString = "/tmp/"
            let result = path.deletingLastPathComponent
            XCTAssertEqual(result, "/")
        }
        
        do {
            let path: NSString = "/tmp"
            let result = path.deletingLastPathComponent
            XCTAssertEqual(result, "/")
        }
        
        do {
            let path: NSString = "/"
            let result = path.deletingLastPathComponent
            XCTAssertEqual(result, "/")
        }
        
        do {
            let path: NSString = "scratch.tiff"
            let result = path.deletingLastPathComponent
            XCTAssertEqual(result, "")
        }
        
        do {
            let path: NSString = "foo/bar"
            let result = path.deletingLastPathComponent
            XCTAssertEqual(result, "foo", "Relative path stays relative.")
        }
    }
    
    func test_resolvingSymlinksInPath() {
        do {
            let path: NSString = "foo/bar"
            let result = path.resolvingSymlinksInPath
            XCTAssertEqual(result, "foo/bar", "For relative paths, symbolic links that can’t be resolved are left unresolved in the returned string.")
        }
        
        do {
            let path: NSString = "/tmp/.."
            let result = path.resolvingSymlinksInPath
            
            #if os(macOS)
            let expected = "/private"
            #else
            let expected = "/"
            #endif
            
            XCTAssertEqual(result, expected, "For absolute paths, all symbolic links are guaranteed to be removed.")
        }

        do {
            let path: NSString = "tmp/.."
            let result = path.resolvingSymlinksInPath
            XCTAssertEqual(result, "tmp/..", "Parent links could be resolved for absolute paths only.")
        }
        
        do {
            let path: NSString = "/tmp/"
            let result = path.resolvingSymlinksInPath
            XCTAssertEqual(result, "/tmp", "Result doesn't contain trailing slash.")
        }
        
        do {
            let path: NSString = "http://google.com/search/.."
            let result = path.resolvingSymlinksInPath
            XCTAssertEqual(result, "http:/google.com/search/..", "resolvingSymlinksInPath treats receiver as file path always")
        }
        
        do {
            let path: NSString = "file:///tmp/.."
            let result = path.resolvingSymlinksInPath
            XCTAssertEqual(result, "file:/tmp/..", "resolvingSymlinksInPath treats receiver as file path always")
        }
    }

    func test_getCString_simple() {
        let str: NSString = "foo"
        var chars = [Int8](repeating:0xF, count:4)
        let count = chars.count
        let expected: [Int8] = [102, 111, 111, 0]
        var res: Bool = false
        chars.withUnsafeMutableBufferPointer() {
            let ptr = $0.baseAddress!
            res = str.getCString(ptr, maxLength: count, encoding: String.Encoding.ascii.rawValue)
        }
        XCTAssertTrue(res, "getCString should work on simple strings with ascii string encoding")
        XCTAssertEqual(chars, expected, "getCString on \(str) should have resulted in \(expected) but got \(chars)")
    }
    
    func test_getCString_nonASCII_withASCIIAccessor() {
        let str: NSString = "ƒoo"
        var chars = [Int8](repeating:0xF, count:5)
        let expected: [Int8] = [-58, -110, 111, 111, 0]
        let count = chars.count
        var res: Bool = false
        chars.withUnsafeMutableBufferPointer() {
            let ptr = $0.baseAddress!
            res = str.getCString(ptr, maxLength: count, encoding: String.Encoding.ascii.rawValue)
        }
        XCTAssertFalse(res, "getCString should not work on non ascii strings accessing as ascii string encoding")
        chars.withUnsafeMutableBufferPointer() {
            let ptr = $0.baseAddress!
            res = str.getCString(ptr, maxLength: count, encoding: String.Encoding.utf8.rawValue)
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
    
    func test_expandingTildeInPath() {
        // Android home directory is the root directory, so the result of ~ may
        // actually have a trailing path separator, but only if it is the root
        // directory itself.
        let rootDirectory = "/"

        do {
            let path: NSString = "~"
            let result = path.expandingTildeInPath
            XCTAssert(result == NSHomeDirectory(), "Could resolve home directory for current user")
            XCTAssertFalse(result.hasSuffix("/") && result != rootDirectory, "Result should not have a trailing path separator")
        }
        
        do {
            let path: NSString = "~/"
            let result = path.expandingTildeInPath
            XCTAssert(result == NSHomeDirectory(), "Could resolve home directory for current user")
            XCTAssertFalse(result.hasSuffix("/") && result != rootDirectory, "Result should not have a trailing path separator")
        }
        
        do {
            let path = NSString(string: "~\(NSUserName())")
            let result = path.expandingTildeInPath
            XCTAssert(result == NSHomeDirectory(), "Could resolve home directory for specific user")
            XCTAssertFalse(result.hasSuffix("/") && result != rootDirectory, "Result should not have a trailing path separator")
        }
        
        do {
            let userName = NSUUID().uuidString
            let path = NSString(string: "~\(userName)/")
            let result = path.expandingTildeInPath
          	// next assert fails in VirtualBox because home directory for unknown user resolved to /var/run/vboxadd
            XCTAssertEqual(result, "~\(userName)", "Return copy of receiver if home directory could not be resolved.")
        }
    }
    
    func test_standardizingPath() {
        
        // tmp is special because it is symlinked to /private/tmp and this /private prefix should be dropped,
        // so tmp is tmp. On Linux tmp is not symlinked so it would be the same.
        do {
            let path: NSString = "/.//tmp/ABC/.."
            let result = path.standardizingPath
            XCTAssertEqual(result, "/tmp", "standardizingPath removes extraneous path components and resolve symlinks.")
        }
        
        do {
            let path: NSString =  "~"
            let result = path.standardizingPath
            let expected = NSHomeDirectory()
            XCTAssertEqual(result, expected, "standardizingPath expanding initial tilde.")
        }
        
        do {
#if !DARWIN_COMPATIBILITY_TESTS // https://bugs.swift.org/browse/SR-10916
            let path: NSString =  "~/foo/bar/"
            let result = path.standardizingPath
            let expected = NSHomeDirectory().appendingPathComponent("foo/bar")
            XCTAssertEqual(result, expected, "standardizingPath expanding initial tilde.")
#endif
        }
        
        // relative file paths depend on file path standardizing that is not yet implemented
        do {
            let path: NSString = "foo/bar"
            let result = path.standardizingPath
            XCTAssertEqual(NSString(string: result), path, "standardizingPath doesn't resolve relative paths")
        }
        
        // tmp is symlinked on macOS only
        #if os(macOS)
        do {
            let path: NSString = "/tmp/.."
            let result = path.standardizingPath
            XCTAssertEqual(result, "/private")
        }
        #endif
        
        do {
            let path: NSString = "/tmp/ABC/.."
            let result = path.standardizingPath
            XCTAssertEqual(result, "/tmp", "parent links could be resolved for absolute paths")
        }
        
        do {
            let path: NSString = "tmp/ABC/.."
            let result = path.standardizingPath
            XCTAssertEqual(NSString(string: result), path, "parent links could not be resolved for relative paths")
        }
    }

    func test_addingPercentEncoding() {
        let s1 = "a b".addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        XCTAssertEqual(s1, "a%20b")
        
        let s2 = "\u{0434}\u{043E}\u{043C}".addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        XCTAssertEqual(s2, "%D0%B4%D0%BE%D0%BC")
    }
    
    func test_removingPercentEncodingInLatin() {
        let s1 = "a%20b".removingPercentEncoding
        XCTAssertEqual(s1, "a b")
        let s2 = "a%1 b".removingPercentEncoding
        XCTAssertNil(s2, "returns nil for a string with an invalid percent encoding")
    }
    
    func test_removingPercentEncodingInNonLatin() {
        let s1 = "\u{043C}\u{043E}\u{0439}%20\u{0434}\u{043E}\u{043C}".removingPercentEncoding
        XCTAssertEqual(s1, "\u{043C}\u{043E}\u{0439} \u{0434}\u{043E}\u{043C}")
        
        let s2 = "%D0%B4%D0%BE%D0%BC".removingPercentEncoding
        XCTAssertEqual(s2, "\u{0434}\u{043E}\u{043C}")
        
        let s3 = "\u{00E0}a%1 b".removingPercentEncoding
        XCTAssertNil(s3, "returns nil for a string with an invalid percent encoding")
    }
    
    func test_removingPersentEncodingWithoutEncoding() {
        let cyrillicString = "\u{0434}\u{043E}\u{043C}"
        let cyrillicEscapedString = cyrillicString.removingPercentEncoding
        XCTAssertEqual(cyrillicString, cyrillicEscapedString)
        
        let chineseString = "\u{623F}\u{5B50}"
        let chineseEscapedString = chineseString.removingPercentEncoding
        XCTAssertEqual(chineseString, chineseEscapedString)
        
        let arabicString = "\u{0645}\u{0646}\u{0632}\u{0644}"
        let arabicEscapedString = arabicString.removingPercentEncoding
        XCTAssertEqual(arabicString, arabicEscapedString)
        
        let randomString = "\u{00E0}\u{00E6}"
        let randomEscapedString = randomString.removingPercentEncoding
        XCTAssertEqual(randomString, randomEscapedString)
        
        let latinString = "home"
        let latinEscapedString = latinString.removingPercentEncoding
        XCTAssertEqual(latinString, latinEscapedString)
    }
    
    func test_addingPercentEncodingAndBack() {
        let latingString = "a b"
        let escapedLatingString = latingString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        let returnedLatingString = escapedLatingString?.removingPercentEncoding
        XCTAssertEqual(returnedLatingString, latingString)
        
        let cyrillicString = "\u{0434}\u{043E}\u{043C}"
        let escapedCyrillicString = cyrillicString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        let returnedCyrillicString = escapedCyrillicString?.removingPercentEncoding
        XCTAssertEqual(returnedCyrillicString, cyrillicString)
    }
    
    func test_stringByAppendingPathExtension() {
        let values = [
            NSString(string: "/tmp/scratch.old") : "/tmp/scratch.old.tiff",
            NSString(string: "/tmp/scratch.") : "/tmp/scratch..tiff",
            NSString(string: "/tmp/") : "/tmp.tiff",
            NSString(string: "/scratch") : "/scratch.tiff",
            NSString(string: "/~scratch") : "/~scratch.tiff",
            NSString(string: "scratch") : "scratch.tiff",
        ]
        for (fileName, expectedResult) in values {
            let result = fileName.appendingPathExtension("tiff")
            XCTAssertEqual(result, expectedResult, "expected \(expectedResult) for \(fileName) but got \(result as Optional)")
        }
    }
    
    func test_deletingPathExtension() {
        let values : Dictionary = [
            NSString(string: "/tmp/scratch.tiff") : "/tmp/scratch",
            NSString(string: "/tmp/") : "/tmp",
            NSString(string: "scratch.bundle") : "scratch",
            NSString(string: "scratch..tiff") : "scratch.",
            NSString(string: ".tiff") : ".tiff",
            NSString(string: "/") : "/",
            NSString(string: "..") : "..",
        ]
        for (fileName, expectedResult) in values {
            let result = fileName.deletingPathExtension
            XCTAssertEqual(result, expectedResult, "expected \(expectedResult) for \(fileName) but got \(result)")
        }
    }
    
    func test_ExternalRepresentation() throws {
        // Ensure NSString can be used to create an external data representation

        do {
            let string = NSString(string: "this is an external string that should be representable by data")

            let UTF8Data = try XCTUnwrap(string.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)) as NSData
            let UTF8Length = UTF8Data.length
            XCTAssertEqual(UTF8Length, 63, "NSString should successfully produce an external UTF8 representation with a length of 63 but got \(UTF8Length) bytes")

            let UTF16Data = try XCTUnwrap(string.data(using: String.Encoding.utf16.rawValue, allowLossyConversion: false)) as NSData
            let UTF16Length = UTF16Data.length
            XCTAssertEqual(UTF16Length, 128, "NSString should successfully produce an external UTF16 representation with a length of 128 but got \(UTF16Length) bytes")

            let ISOLatin1Data = try XCTUnwrap(string.data(using: String.Encoding.isoLatin1.rawValue, allowLossyConversion: false)) as NSData
            let ISOLatin1Length = ISOLatin1Data.length
            XCTAssertEqual(ISOLatin1Length, 63, "NSString should successfully produce an external ISOLatin1 representation with a length of 63 but got \(ISOLatin1Length) bytes")
        }

        do {
            let string = NSString(string: "🐢 encoding all the way down. 🐢🐢🐢")

            let UTF8Data = try XCTUnwrap(string.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)) as NSData
            let UTF8Length = UTF8Data.length
            XCTAssertEqual(UTF8Length, 44, "NSString should successfully produce an external UTF8 representation with a length of 44 but got \(UTF8Length) bytes")

            let UTF16Data = try XCTUnwrap(string.data(using: String.Encoding.utf16.rawValue, allowLossyConversion: false)) as NSData
            let UTF16Length = UTF16Data.length
            XCTAssertEqual(UTF16Length, 74, "NSString should successfully produce an external UTF16 representation with a length of 74 but got \(UTF16Length) bytes")

            let ISOLatin1Data = string.data(using: String.Encoding.isoLatin1.rawValue, allowLossyConversion: false) as NSData?
            XCTAssertNil(ISOLatin1Data)
        }
    }
    
    func test_mutableStringConstructor() {
        let mutableString = NSMutableString(string: "Test")
        XCTAssertEqual(mutableString, "Test")
    }

    func test_getLineStart() {
        // offset        012345 678901
        let twoLines =  "line1\nline2\n"
        var outStartIndex = twoLines.startIndex
        var outEndIndex = twoLines.startIndex
        var outContentsEndIndex = twoLines.startIndex

        twoLines.getLineStart(&outStartIndex, end: &outEndIndex,
                              contentsEnd: &outContentsEndIndex,
                              for: outEndIndex..<outEndIndex)

        XCTAssertEqual(outStartIndex, twoLines.startIndex)
        XCTAssertEqual(outContentsEndIndex, twoLines.index(twoLines.startIndex, offsetBy: 5))
        XCTAssertEqual(outEndIndex, twoLines.index(twoLines.startIndex, offsetBy: 6))

        twoLines.getLineStart(&outStartIndex, end: &outEndIndex,
                              contentsEnd: &outContentsEndIndex,
                              for: outEndIndex..<outEndIndex)

        XCTAssertEqual(outStartIndex, twoLines.index(twoLines.startIndex, offsetBy: 6))
        XCTAssertEqual(outContentsEndIndex, twoLines.index(twoLines.startIndex, offsetBy: 11))
        XCTAssertEqual(outEndIndex, twoLines.index(twoLines.startIndex, offsetBy: 12))
    }
    
    func test_emptyStringPrefixAndSuffix() {
        let testString = "hello"
        XCTAssertTrue(testString.hasPrefix(""))
        XCTAssertTrue(testString.hasSuffix(""))
    }

    func test_substringWithRange() {
        let trivial = NSString(string: "swift.org")
        XCTAssertEqual(trivial.substring(with: NSRange(location: 0, length: 5)), "swift")

        let surrogatePairSuffix = NSString(string: "Hurray🎉")
        XCTAssertEqual(surrogatePairSuffix.substring(with: NSRange(location: 0, length: 7)), "Hurray�")

        let surrogatePairPrefix = NSString(string: "🐱Cat")
        XCTAssertEqual(surrogatePairPrefix.substring(with: NSRange(location: 1, length: 4)), "�Cat")

        let singleChar = NSString(string: "😹")
        XCTAssertEqual(singleChar.substring(with: NSRange(location: 0, length: 1)), "�")

        let crlf = NSString(string: "\r\n")
        XCTAssertEqual(crlf.substring(with: NSRange(location: 0, length: 1)), "\r")
        XCTAssertEqual(crlf.substring(with: NSRange(location: 1, length: 1)), "\n")
        XCTAssertEqual(crlf.substring(with: NSRange(location: 1, length: 0)), "")

        let bothEnds1 = NSString(string: "😺😺")
        XCTAssertEqual(bothEnds1.substring(with: NSRange(location: 1, length: 2)), "��") 

        let s1 = NSString(string: "😺\r\n")
        XCTAssertEqual(s1.substring(with: NSRange(location: 1, length: 2)), "�\r")

        let s2 = NSString(string: "\r\n😺")
        XCTAssertEqual(s2.substring(with: NSRange(location: 1, length: 2)), "\n�")

        let s3 = NSString(string: "😺cats😺")
        XCTAssertEqual(s3.substring(with: NSRange(location: 1, length: 6)), "�cats�")

        let s4 = NSString(string: "😺cats\r\n")
        XCTAssertEqual(s4.substring(with: NSRange(location: 1, length: 6)), "�cats\r")

        let s5 = NSString(string: "\r\ncats😺")
        XCTAssertEqual(s5.substring(with: NSRange(location: 1, length: 6)), "\ncats�")

        // SR-3363
        let s6 = NSString(string: "Beyonce\u{301} and Tay")
        XCTAssertEqual(s6.substring(with: NSRange(location: 7, length: 9)), "\u{301} and Tay")
    }

    func test_substringFromCFString() {
        let string = StringTransform.stripCombiningMarks.rawValue as NSString
        let range = NSRange(location: 0, length: string.length)
        let substring = string.substring(with: range)

        XCTAssertEqual(string.length, substring.utf16.count)
    }

    func test_createCopy() {
        let string: NSMutableString = "foo"
        let stringCopy = string.copy() as! NSString
        XCTAssertEqual(string, stringCopy)
        string.append("bar")
        XCTAssertNotEqual(string, stringCopy)
        XCTAssertEqual(string, "foobar")
        XCTAssertEqual(stringCopy, "foo")
    }

    func test_commonPrefix() {
        XCTAssertEqual("".commonPrefix(with: ""), "")
        XCTAssertEqual("1234567890".commonPrefix(with: ""), "")
        XCTAssertEqual("".commonPrefix(with: "1234567890"), "")
        XCTAssertEqual("abcba".commonPrefix(with: "abcde"), "abc")
        XCTAssertEqual("/path/to/file1".commonPrefix(with: "/path/to/file2"), "/path/to/file")
        XCTAssertEqual("/a_really_long_path/to/a/file".commonPrefix(with: "/a_really_long_path/to/the/file"), "/a_really_long_path/to/")
        XCTAssertEqual("this".commonPrefix(with: "THAT", options: [.caseInsensitive]), "th")

        // Both forms of ä, a\u{308} decomposed and \u{E4} precomposed, should match without .literal and not match when .literal is used
        XCTAssertEqual("Ma\u{308}dchen".commonPrefix(with: "M\u{E4}dchenschule"), "Ma\u{308}dchen")
        XCTAssertEqual("Ma\u{308}dchen".commonPrefix(with: "M\u{E4}dchenschule", options: [.literal]), "M")
        XCTAssertEqual("m\u{E4}dchen".commonPrefix(with: "M\u{E4}dchenschule", options: [.caseInsensitive, .literal]), "mädchen")
        XCTAssertEqual("ma\u{308}dchen".commonPrefix(with: "M\u{E4}dchenschule", options: [.caseInsensitive, .literal]), "m")
    }

    func test_lineRangeFor() {
        // column     1 2 3 4 5 6 7 8 9  10 11
        // line 1     L I N E 1 _ 6 7 あ \n
        // line 2     L I N E 2 _ 7 8 9  0 \n
        // line 3     L I N E 3 _ 8 9 0  1 \n
        let string = "LINE1_67あ\nLINE2_7890\nLINE3_8901\n"
        let rangeOfFirstLine = string.lineRange(for: string.startIndex..<string.startIndex)
        XCTAssertEqual(string.distance(from: rangeOfFirstLine.lowerBound, to: rangeOfFirstLine.upperBound), 10)
        let firstLine = string[rangeOfFirstLine]
        XCTAssertEqual(firstLine, "LINE1_67あ\n")
    }

    func test_reflection() {
    }

    func test_replacingOccurrences() {
        let testPrefix = "ab"
        let testSuffix = "cd"
        let testEmoji = "\u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467}\u{200D}\u{1F466}"
        let testString = testPrefix + testEmoji + testSuffix

        let testReplacement = "xyz"
        let testReplacementEmoji = "\u{01F468}\u{200D}\u{002764}\u{00FE0F}\u{200D}\u{01F48B}\u{200D}\u{01F468}"

        let noChange = testString.replacingOccurrences(of: testReplacement, with: "")
        XCTAssertEqual(noChange, testString)

        let removePrefix = testString.replacingOccurrences(of: testPrefix, with: "")
        XCTAssertEqual(removePrefix, testEmoji + testSuffix)
        let replacePrefix = testString.replacingOccurrences(of: testPrefix, with: testReplacement)
        XCTAssertEqual(replacePrefix, testReplacement + testEmoji + testSuffix)

        let removeSuffix = testString.replacingOccurrences(of: testSuffix, with: "")
        XCTAssertEqual(removeSuffix, testPrefix + testEmoji)
        let replaceSuffix = testString.replacingOccurrences(of: testSuffix, with: testReplacement)
        XCTAssertEqual(replaceSuffix, testPrefix + testEmoji + testReplacement)

        let removeMultibyte = testString.replacingOccurrences(of: testEmoji, with: "")
        XCTAssertEqual(removeMultibyte, testPrefix + testSuffix)
        let replaceMultibyte = testString.replacingOccurrences(of: testEmoji, with: testReplacement)
        XCTAssertEqual(replaceMultibyte, testPrefix + testReplacement + testSuffix)

        let replaceMultibyteWithMultibyte = testString.replacingOccurrences(of: testEmoji, with: testReplacementEmoji)
        XCTAssertEqual(replaceMultibyteWithMultibyte, testPrefix + testReplacementEmoji + testSuffix)

        let replacePrefixWithMultibyte = testString.replacingOccurrences(of: testPrefix, with: testReplacementEmoji)
        XCTAssertEqual(replacePrefixWithMultibyte, testReplacementEmoji + testEmoji + testSuffix)

        let replaceSuffixWithMultibyte = testString.replacingOccurrences(of: testSuffix, with: testReplacementEmoji)
        XCTAssertEqual(replaceSuffixWithMultibyte, testPrefix + testEmoji + testReplacementEmoji)

        let str1 = "Hello\r\nworld."
        XCTAssertEqual(str1.replacingOccurrences(of: "\n", with: " "), "Hello\r world.")
        XCTAssertEqual(str1.replacingOccurrences(of: "\r", with: " "), "Hello \nworld.")
        XCTAssertEqual(str1.replacingOccurrences(of: "\r\n", with: " "), "Hello world.")
        XCTAssertEqual(str1.replacingOccurrences(of: "\r\n", with: "\n\r"), "Hello\n\rworld.")
        XCTAssertEqual(str1.replacingOccurrences(of: "\r\n", with: "\r\n"), "Hello\r\nworld.")
        XCTAssertEqual(str1.replacingOccurrences(of: "\n\r", with: " "), "Hello\r\nworld.")

        let str2 = "Hello\n\rworld."
        XCTAssertEqual(str2.replacingOccurrences(of: "\n", with: " "), "Hello \rworld.")
        XCTAssertEqual(str2.replacingOccurrences(of: "\r", with: " "), "Hello\n world.")
        XCTAssertEqual(str2.replacingOccurrences(of: "\r\n", with: " "), "Hello\n\rworld.")
        XCTAssertEqual(str2.replacingOccurrences(of: "\n\r", with: " "), "Hello world.")
        XCTAssertEqual(str2.replacingOccurrences(of: "\n\r", with: "\r\n"), "Hello\r\nworld.")
        XCTAssertEqual(str2.replacingOccurrences(of: "\n\r", with: "\n\r"), "Hello\n\rworld.")

        let str3 = "Hello\n\nworld."
        XCTAssertEqual(str3.replacingOccurrences(of: "\n", with: " "), "Hello  world.")
        XCTAssertEqual(str3.replacingOccurrences(of: "\r", with: " "), "Hello\n\nworld.")
        XCTAssertEqual(str3.replacingOccurrences(of: "\r\n", with: " "), "Hello\n\nworld.")
        XCTAssertEqual(str3.replacingOccurrences(of: "\r\n", with: "\n\r"), "Hello\n\nworld.")
        XCTAssertEqual(str3.replacingOccurrences(of: "\r\n", with: "\r\n"), "Hello\n\nworld.")
        XCTAssertEqual(str3.replacingOccurrences(of: "\n\r", with: " "), "Hello\n\nworld.")

        let str4 = "Hello\r\rworld."
        XCTAssertEqual(str4.replacingOccurrences(of: "\n", with: " "), "Hello\r\rworld.")
        XCTAssertEqual(str4.replacingOccurrences(of: "\r", with: " "), "Hello  world.")
        XCTAssertEqual(str4.replacingOccurrences(of: "\r\n", with: " "), "Hello\r\rworld.")
        XCTAssertEqual(str4.replacingOccurrences(of: "\r\n", with: "\n\r"), "Hello\r\rworld.")
        XCTAssertEqual(str4.replacingOccurrences(of: "\r\n", with: "\r\n"), "Hello\r\rworld.")
        XCTAssertEqual(str4.replacingOccurrences(of: "\n\r", with: " "), "Hello\r\rworld.")
    }

    func test_replacingOccurrencesInSubclass() {
        // NSMutableString doesnt subclasss correctly
#if !DARWIN_COMPATIBILITY_TESTS
        class TestMutableString: NSMutableString {
            private var wrapped: NSMutableString
            var replaceCharactersCount: Int = 0

            override var length: Int {
                return wrapped.length
            }

            override func character(at index: Int) -> unichar {
                return wrapped.character(at: index)
            }

            override func replaceCharacters(in range: NSRange, with aString: String) {
                defer { replaceCharactersCount += 1 }
                wrapped.replaceCharacters(in: range, with: aString)
            }

            override func mutableCopy(with zone: NSZone? = nil) -> Any {
                return wrapped.mutableCopy()
            }

            required init(stringLiteral value: StaticString) {
                wrapped = .init(stringLiteral: value)
                super.init(stringLiteral: value)
            }

            required init(capacity: Int) {
                fatalError("init(capacity:) has not been implemented")
            }

            required init(string aString: String) {
                fatalError("init(string:) has not been implemented")
            }

            required convenience init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            required init(characters: UnsafePointer<unichar>, length: Int) {
                fatalError("init(characters:length:) has not been implemented")
            }

            required convenience init(extendedGraphemeClusterLiteral value: StaticString) {
                fatalError("init(extendedGraphemeClusterLiteral:) has not been implemented")
            }

            required convenience init(unicodeScalarLiteral value: StaticString) {
                fatalError("init(unicodeScalarLiteral:) has not been implemented")
            }
        }

        let testString = TestMutableString(stringLiteral: "ababab")
        XCTAssertEqual(testString.replacingOccurrences(of: "ab", with: "xx"), "xxxxxx")
        XCTAssertEqual(testString.replaceCharactersCount, 3)
#endif
    }


    func test_fileSystemRepresentation() {
        let name = "☃" as NSString
        let result = name.fileSystemRepresentation
        XCTAssertEqual(UInt8(bitPattern: result[0]), 0xE2)
        XCTAssertEqual(UInt8(bitPattern: result[1]), 0x98)
        XCTAssertEqual(UInt8(bitPattern: result[2]), 0x83)

    #if !DARWIN_COMPATIBILITY_TESTS // auto-released by Darwin's Foundation
        result.deallocate()
    #endif
    }
    
    func test_enumerateSubstrings() {
        // http://www.gutenberg.org/ebooks/12389, with a prefix addition by me.
        // U+0300 COMBINING ACUTE ACCENT;
        // U+0085 NEXT LINE (creates a new line that's not a new paragraph)
        let text = "Questo e\u{0300} un poema.\n---\nCyprus, Paphos, or Panormus\u{0085}May detain thee with their splendour\u{0085}Of oblations on thine altars,\u{0085}O imperial Aphrodite.\n\nYet do thou regard, with pity\u{0085}For a nameless child of passion,\u{0085}This small unfrequented valley\u{0085}By the sea, O sea-born mother.\u{0085}"
        let nstext = text as NSString
        
        let graphemes = ["Q", "u", "e", "s", "t", "o", " ", "e\u{0300}", " ", "u", "n", " ", "p", "o", "e", "m", "a", ".", "\n", "-", "-", "-", "\n", "C", "y", "p", "r", "u", "s", ",", " ", "P", "a", "p", "h", "o", "s", ",", " ", "o", "r", " ", "P", "a", "n", "o", "r", "m", "u", "s", "\u{0085}", "M", "a", "y", " ", "d", "e", "t", "a", "i", "n", " ", "t", "h", "e", "e", " ", "w", "i", "t", "h", " ", "t", "h", "e", "i", "r", " ", "s", "p", "l", "e", "n", "d", "o", "u", "r", "\u{0085}", "O", "f", " ", "o", "b", "l", "a", "t", "i", "o", "n", "s", " ", "o", "n", " ", "t", "h", "i", "n", "e", " ", "a", "l", "t", "a", "r", "s", ",", "\u{0085}", "O", " ", "i", "m", "p", "e", "r", "i", "a", "l", " ", "A", "p", "h", "r", "o", "d", "i", "t", "e", ".", "\n", "\n", "Y", "e", "t", " ", "d", "o", " ", "t", "h", "o", "u", " ", "r", "e", "g", "a", "r", "d", ",", " ", "w", "i", "t", "h", " ", "p", "i", "t", "y", "\u{0085}", "F", "o", "r", " ", "a", " ", "n", "a", "m", "e", "l", "e", "s", "s", " ", "c", "h", "i", "l", "d", " ", "o", "f", " ", "p", "a", "s", "s", "i", "o", "n", ",", "\u{0085}", "T", "h", "i", "s", " ", "s", "m", "a", "l", "l", " ", "u", "n", "f", "r", "e", "q", "u", "e", "n", "t", "e", "d", " ", "v", "a", "l", "l", "e", "y", "\u{0085}", "B", "y", " ", "t", "h", "e", " ", "s", "e", "a", ",", " ", "O", " ", "s", "e", "a", "-", "b", "o", "r", "n", " ", "m", "o", "t", "h", "e", "r", ".", "\u{0085}"]
        
        let lines = ["Questo e\u{0300} un poema.", "---", "Cyprus, Paphos, or Panormus", "May detain thee with their splendour", "Of oblations on thine altars,", "O imperial Aphrodite.", "", "Yet do thou regard, with pity", "For a nameless child of passion,", "This small unfrequented valley", "By the sea, O sea-born mother."]
        
        let paragraphs = ["Questo è un poema.", "---", "Cyprus, Paphos, or Panormus\u{0085}May detain thee with their splendour\u{0085}Of oblations on thine altars,\u{0085}O imperial Aphrodite.", "", "Yet do thou regard, with pity\u{0085}For a nameless child of passion,\u{0085}This small unfrequented valley\u{0085}By the sea, O sea-born mother.\u{0085}"]
        
        enum Result {
            case substrings([String])
            case count(Int)
        }
        
        let expectations: [(options: NSString.EnumerationOptions, result: Result)] = [
            (options: [.byComposedCharacterSequences],
             result: .substrings(graphemes)),
            (options: [.byComposedCharacterSequences, .reverse],
             result: .substrings(graphemes.reversed())),
            (options: [.byComposedCharacterSequences, .substringNotRequired],
             result: .count(graphemes.count)),
            (options: [.byComposedCharacterSequences, .substringNotRequired, .reverse],
             result: .count(graphemes.count)),
            (options: [.byLines],
             result: .substrings(lines)),
            (options: [.byLines, .reverse],
             result: .substrings(lines.reversed())),
            (options: [.byLines, .substringNotRequired],
             result: .count(lines.count)),
            (options: [.byLines, .substringNotRequired, .reverse],
             result: .count(lines.count)),
            (options: [.byParagraphs],
             result: .substrings(paragraphs)),
            (options: [.byParagraphs, .reverse],
             result: .substrings(paragraphs.reversed())),
            (options: [.byParagraphs, .substringNotRequired],
             result: .count(paragraphs.count)),
            (options: [.byParagraphs, .substringNotRequired, .reverse],
             result: .count(paragraphs.count)),
        ]
        
        for expectation in expectations {
            var substrings: [String] = []
            let requiresSubstrings = !expectation.options.contains(.substringNotRequired)
            
            var hasFailedSubstringPresence = false
            var count = 0
            
            nstext.enumerateSubstrings(in: NSMakeRange(0, nstext.length), options: expectation.options) { (substring, range, fullRange, stop) in
                // TODO: range, fullRange
                
                count += 1
                
                if requiresSubstrings {
                    XCTAssertNotNil(substring, "Testing with options: \(expectation.options)")
                    if let substring = substring {
                        substrings.append(substring)
                    } else {
                        hasFailedSubstringPresence = true
                    }
                } else {
                    XCTAssertNil(substring, "Testing with options: \(expectation.options)")
                    if substring != nil {
                        hasFailedSubstringPresence = true
                    }
                }
            }
            
            if !hasFailedSubstringPresence {
                switch expectation.result {
                case .count(let expectedCount):
                    XCTAssertEqual(count, expectedCount, "Testing with options: \(expectation.options)")
                case .substrings(let expectedSubstrings):
                    XCTAssertEqual(substrings, expectedSubstrings, "Testing with options: \(expectation.options)")
                }
            }
        }
    }
    
    func test_paragraphRange() {
        let text = "Klaatu\nbarada\r\nnikto.\rRemember 🟨those\u{2029}words."
        let nsText = text as NSString

        // Expected paragraph ranges in test string
        let paragraphRanges = [
            NSRange(location: 0, length: 7),
            NSRange(location: 7, length: 8),
            NSRange(location: 15, length: 7),
            NSRange(location: 22, length: 17),
            NSRange(location: 39, length: 6),
        ]

        // We also will check ranges across two consecutive paragraphs.
        // Generate pairs from plain array.
        let paragraphPairs = paragraphRanges.enumerated().compactMap { i, range -> (NSRange, NSRange)? in
            guard i < paragraphRanges.count - 1 else {
                return nil
            }

            return (range, paragraphRanges[i + 1])
        }

        // Helper function. Generates all possible subranges in provided range.
        // Interrupts if handler returns false.
        func subranges(in range: NSRange, with handler: (NSRange) -> Bool) {
            for location in range.location..<(range.location + range.length) {
                let maxLength = range.length - (location - range.location)
                for length in 0...maxLength {
                    let generatedRange = NSRange(location: location, length: length)

                    guard handler(generatedRange) else {
                        return
                    }
                }
            }
        }

        // Simplest check. Whole string is one or more
        // paragraphs, so result range should cover it completely.
        let wholeStringRange = NSRange(location: 0, length: nsText.length)
        let allParagrapsRange = nsText.paragraphRange(for: wholeStringRange)
        XCTAssertEqual(wholeStringRange, allParagrapsRange)

        // Every paragraph is checked against all possible subranges in it.
        for expectedRange in paragraphRanges {
            subranges(in: expectedRange) { generatedRange in
                let calculatedRange = nsText.paragraphRange(for: generatedRange)

                // One fail report is enough.
                // Otherwise there will be hundreds.
                // Using manual check (not XCTAssertEqual)
                // for early exit.
                guard calculatedRange == expectedRange else {
                    XCTFail("paragraphRange(for:) returned \(calculatedRange) for \(generatedRange), but expected is \(expectedRange)")
                    return false
                }

                return true
            }
        }

        // Every paragraph pair is checked against all possible
        // subranges in single continuous range of both paragraphs.
        for paragraphPair in paragraphPairs {
            let paragraphPairRange = NSRange(location: paragraphPair.0.location, length: paragraphPair.0.length + paragraphPair.1.length)
            subranges(in: paragraphPairRange) { generatedRange in
                let calculatedRange = nsText.paragraphRange(for: generatedRange)

                let expectedRange: NSRange = {
                    // Does it fit in first paragraph range?
                    if paragraphPair.0.intersection(generatedRange) == generatedRange {
                        return paragraphPair.0
                    }
                    // Does it fit in second paragraph range?
                    if paragraphPair.1.intersection(generatedRange) == generatedRange {
                        return paragraphPair.1
                    }
                    // Neither completely in first, nor in second. Must be partially in both.
                    return paragraphPairRange
                }()

                // Again, manual check with early exit
                guard calculatedRange == expectedRange else {
                    XCTFail("paragraphRange(for:) returned \(calculatedRange) for \(generatedRange), but expected \(expectedRange)")
                    return false
                }

                return true
            }
        }
    }

    func test_initStringWithNSString() {
        let ns = NSString("Test")
        XCTAssertEqual(String(ns), "Test")
    }

    func test_initString_utf8StringWithArrayInput() {
        var source: [CChar] = [0x61, 0x62, 0, 0x63]
        var str: String?
        str = String(utf8String: source)
        XCTAssertNotNil(str)
        source.withUnsafeBufferPointer {
            XCTAssertEqual(str, String(utf8String: $0.baseAddress!))
        }
        // substitute a value not valid in UTF-8
        source[1] = CChar(bitPattern: 0xff)
        str = String(utf8String: source)
        XCTAssertNil(str)
    }

    @available(*, deprecated) // silence the deprecation warning within
    func test_initString_utf8StringWithStringInput() {
        let source = "ab\0c"
        var str: String?
        str = String(utf8String: source)
        XCTAssertNotNil(str)
        source.withCString {
            XCTAssertEqual(str, String(utf8String: $0))
        }
        str = String(utf8String: "")
        XCTAssertNotNil(str)
        XCTAssertEqual(str?.isEmpty, true)
    }

    @available(*, deprecated) // silence the deprecation warning within
    func test_initString_utf8StringWithInoutConversion() {
        var c = CChar.zero
        var str: String?
        str = String(utf8String: &c)
        // Any other value of `c` would violate the null-terminated precondition
        XCTAssertNotNil(str)
        XCTAssertEqual(str?.isEmpty, true)
    }

    func test_initString_cStringWithArrayInput() {
        var source: [CChar] = [0x61, 0x62, 0, 0x63]
        var str: String?
        str = String(cString: source, encoding: .utf8)
        XCTAssertNotNil(str)
        source.withUnsafeBufferPointer {
            XCTAssertEqual(
                str, String(cString: $0.baseAddress!, encoding: .utf8)
            )
        }
        str = String(cString: source, encoding: .ascii)
        XCTAssertNotNil(str)
        source.withUnsafeBufferPointer {
            XCTAssertEqual(
                str, String(cString: $0.baseAddress!, encoding: .ascii)
            )
        }
        str = String(cString: source, encoding: .macOSRoman)
        XCTAssertNotNil(str)
        source.withUnsafeBufferPointer {
            XCTAssertEqual(
                str, String(cString: $0.baseAddress!, encoding: .macOSRoman)
            )
        }
        // substitute a value not valid in UTF-8
        source[1] = CChar(bitPattern: 0xff)
        str = String(cString: source, encoding: .utf8)
        XCTAssertNil(str)
        str = String(cString: source, encoding: .macOSRoman)
        XCTAssertNotNil(str)
        source.withUnsafeBufferPointer {
            XCTAssertEqual(
                str, String(cString: $0.baseAddress!, encoding: .macOSRoman)
            )
        }
    }

    @available(*, deprecated) // silence the deprecation warning within
    func test_initString_cStringWithStringInput() {
        let source = "ab\0c"
        var str: String?
        str = String(cString: source, encoding: .utf8)
        XCTAssertNotNil(str)
        source.withCString {
            XCTAssertEqual(str, String(cString: $0, encoding: .utf8))
        }
        str = String(cString: source, encoding: .ascii)
        XCTAssertNotNil(str)
        source.withCString {
            XCTAssertEqual(str, String(cString: $0, encoding: .ascii))
        }
        str = String(cString: "", encoding: .utf8)
        XCTAssertNotNil(str)
        XCTAssertEqual(str?.isEmpty, true)
        str = String(cString: "Caractères", encoding: .ascii)
        XCTAssertNil(str)
    }

    @available(*, deprecated) // silence the deprecation warning within
    func test_initString_cStringWithInoutConversion() {
        var c = CChar.zero
        var str: String?
        str = String(cString: &c, encoding: .ascii)
        // Any other value of `c` would violate the null-terminated precondition
        XCTAssertNotNil(str)
        XCTAssertEqual(str?.isEmpty, true)
    }

    static var allTests: [(String, (TestNSString) -> () throws -> Void)] {
        var tests = [
            ("test_initData", test_initData),
            ("test_boolValue", test_boolValue ),
            ("test_BridgeConstruction", test_BridgeConstruction),
            ("test_bridging", test_bridging),
            ("test_integerValue", test_integerValue ),
            ("test_intValue", test_intValue ),
            ("test_doubleValue", test_doubleValue),
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
            
            /* ⚠️ */ ("test_FromContentsOfURL", testExpectedToFail(test_FromContentsOfURL,
            /* ⚠️ */     "test_FromContentsOfURL is flaky on CI, with unclear causes. https://bugs.swift.org/browse/SR-10514")),

            ("test_FromContentOfFileUsedEncodingIgnored", test_FromContentOfFileUsedEncodingIgnored),
            ("test_FromContentOfFileUsedEncodingUTF8", test_FromContentOfFileUsedEncodingUTF8),
            ("test_FromContentsOfURLUsedEncodingUTF16BE", test_FromContentsOfURLUsedEncodingUTF16BE),
            ("test_FromContentsOfURLUsedEncodingUTF16LE", test_FromContentsOfURLUsedEncodingUTF16LE),
            ("test_FromContentsOfURLUsedEncodingUTF32BE", test_FromContentsOfURLUsedEncodingUTF32BE),
            ("test_FromContentsOfURLUsedEncodingUTF32LE", test_FromContentsOfURLUsedEncodingUTF32LE),
            ("test_FromContentOfFile",test_FromContentOfFile),
            ("test_swiftStringUTF16", test_swiftStringUTF16),
            ("test_stringByTrimmingCharactersInSet", test_stringByTrimmingCharactersInSet),
            ("test_initializeWithFormat", test_initializeWithFormat),
            ("test_initializeWithFormat2", test_initializeWithFormat2),
            ("test_initializeWithFormat3", test_initializeWithFormat3),
            ("test_initializeWithFormat4", test_initializeWithFormat4),
            ("test_appendingPathComponent", test_appendingPathComponent),
            ("test_deletingLastPathComponent", test_deletingLastPathComponent),
            ("test_getCString_simple", test_getCString_simple),
            ("test_getCString_nonASCII_withASCIIAccessor", test_getCString_nonASCII_withASCIIAccessor),
            ("test_NSHomeDirectoryForUser", test_NSHomeDirectoryForUser),
            ("test_resolvingSymlinksInPath", test_resolvingSymlinksInPath),
            ("test_expandingTildeInPath", test_expandingTildeInPath),
            ("test_standardizingPath", test_standardizingPath),
            ("test_addingPercentEncoding", test_addingPercentEncoding),
            ("test_removingPercentEncodingInLatin", test_removingPercentEncodingInLatin),
            ("test_removingPercentEncodingInNonLatin", test_removingPercentEncodingInNonLatin),
            ("test_removingPersentEncodingWithoutEncoding", test_removingPersentEncodingWithoutEncoding),
            ("test_addingPercentEncodingAndBack", test_addingPercentEncodingAndBack),
            ("test_stringByAppendingPathExtension", test_stringByAppendingPathExtension),
            ("test_deletingPathExtension", test_deletingPathExtension),
            ("test_ExternalRepresentation", test_ExternalRepresentation),
            ("test_mutableStringConstructor", test_mutableStringConstructor),
            ("test_emptyStringPrefixAndSuffix",test_emptyStringPrefixAndSuffix),
            ("test_reflection", test_reflection),
            ("test_replacingOccurrences", test_replacingOccurrences),
            ("test_getLineStart", test_getLineStart),
            ("test_substringWithRange", test_substringWithRange),
            ("test_substringFromCFString", test_substringFromCFString),
            ("test_createCopy", test_createCopy),
            ("test_commonPrefix", test_commonPrefix),
            ("test_lineRangeFor", test_lineRangeFor),
            ("test_fileSystemRepresentation", test_fileSystemRepresentation),
            ("test_enumerateSubstrings", test_enumerateSubstrings),
            ("test_paragraphRange", test_paragraphRange),
            ("test_initStringWithNSString", test_initStringWithNSString),
            ("test_initString_utf8StringWithArrayInput", test_initString_utf8StringWithArrayInput),
            ("test_initString_utf8StringWithStringInput", test_initString_utf8StringWithStringInput),
            ("test_initString_utf8StringWithInoutConversion", test_initString_utf8StringWithInoutConversion),
            ("test_initString_cStringWithArrayInput", test_initString_cStringWithArrayInput),
            ("test_initString_cStringWithStringInput", test_initString_cStringWithStringInput),
            ("test_initString_cStringWithInoutConversion", test_initString_cStringWithInoutConversion),
        ]

#if !os(Windows)
        // Tests that dont currently work on windows
        tests += [
            ("test_completePathIntoString", test_completePathIntoString),
        ]
#endif
        return tests
    }
}
