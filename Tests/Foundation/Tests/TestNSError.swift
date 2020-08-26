// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

struct SwiftCustomNSError: Error, CustomNSError {
}

class TestNSError : XCTestCase {
    
    static var allTests: [(String, (TestNSError) -> () throws -> Void)] {
        return [
            ("test_LocalizedError_errorDescription", test_LocalizedError_errorDescription),
            ("test_NSErrorAsError_localizedDescription", test_NSErrorAsError_localizedDescription),
            ("test_NSError_inDictionary", test_NSError_inDictionary),
            ("test_CustomNSError_domain", test_CustomNSError_domain),
            ("test_CustomNSError_userInfo", test_CustomNSError_userInfo),
            ("test_CustomNSError_errorCode", test_CustomNSError_errorCode),
            ("test_CustomNSError_errorCodeRawInt", test_CustomNSError_errorCodeRawInt),
            ("test_CustomNSError_errorCodeRawUInt", test_CustomNSError_errorCodeRawUInt),
            ("test_errorConvenience", test_errorConvenience)
        ]
    }
    
    func test_LocalizedError_errorDescription() {
        struct Error : LocalizedError {
            var errorDescription: String? { return "error description" }
        }

        let error = Error()
        XCTAssertEqual(error.localizedDescription, "error description")
    }

    func test_NSErrorAsError_localizedDescription() {
        let nsError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Localized!"])
        let error = nsError as Error
        XCTAssertEqual(error.localizedDescription, "Localized!")
    }
    
    func test_NSError_inDictionary() {
        let error = NSError(domain: "domain", code: 42, userInfo: nil)
        let nsdictionary = ["error": error] as NSDictionary
        let dictionary = nsdictionary as? Dictionary<String, Error>
        XCTAssertNotNil(dictionary)
        XCTAssertEqual(error, dictionary?["error"] as? NSError)
    }

    func test_CustomNSError_domain() {
        let name = testBundleName()
        XCTAssertEqual(SwiftCustomNSError.errorDomain, "\(name).SwiftCustomNSError")
    }

    func test_CustomNSError_userInfo() {
        let userInfo = SwiftCustomNSError().errorUserInfo
        XCTAssertTrue(userInfo.isEmpty)
    }

    func test_CustomNSError_errorCode() {
        enum SwiftError : Error, CustomNSError {
            case zero
            case one
            case two
        }

        XCTAssertEqual(SwiftCustomNSError().errorCode, 1)

        XCTAssertEqual(SwiftError.zero.errorCode, 0)
        XCTAssertEqual(SwiftError.one.errorCode,  1)
        XCTAssertEqual(SwiftError.two.errorCode,  2)
    }

    func test_CustomNSError_errorCodeRawInt() {
        enum SwiftError : Int, Error, CustomNSError {
            case minusOne  = -1
            case fortyTwo = 42
        }

        XCTAssertEqual(SwiftError.minusOne.errorCode,  -1)
        XCTAssertEqual(SwiftError.fortyTwo.errorCode, 42)
    }

    func test_CustomNSError_errorCodeRawUInt() {
        enum SwiftError : UInt, Error, CustomNSError {
            case fortyTwo = 42
        }

        XCTAssertEqual(SwiftError.fortyTwo.errorCode, 42)
    }

    func test_errorConvenience() {
        let error = CocoaError.error(.fileReadNoSuchFile, url: URL(fileURLWithPath: #file))

        if let nsError = error as? NSError {
            XCTAssertEqual(nsError._domain, NSCocoaErrorDomain)
            XCTAssertEqual(nsError._code, CocoaError.fileReadNoSuchFile.rawValue)
            if let filePath = nsError.userInfo[NSURLErrorKey] as? URL {
                XCTAssertEqual(filePath, URL(fileURLWithPath: #file))
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }
    }
}

class TestURLError: XCTestCase {

    static var allTests: [(String, (TestURLError) -> () throws -> Void)] {
        return [
          ("test_errorCode", TestURLError.test_errorCode),
          ("test_failingURL", TestURLError.test_failingURL),
          ("test_failingURLString", TestURLError.test_failingURLString),
        ]
    }

    static let testURL = URL(string: "https://swift.org")!
    let userInfo: [String: Any] =  [
        NSURLErrorFailingURLErrorKey: TestURLError.testURL,
        NSURLErrorFailingURLStringErrorKey: TestURLError.testURL.absoluteString,
    ]

    func test_errorCode() {
        let e = URLError(.unsupportedURL)
        XCTAssertEqual(e.errorCode, URLError.Code.unsupportedURL.rawValue)
    }

    func test_failingURL() {
        let e = URLError(.badURL, userInfo: userInfo)
        XCTAssertNotNil(e.failingURL)
        XCTAssertEqual(e.failingURL, e.userInfo[NSURLErrorFailingURLErrorKey] as? URL)
    }

    func test_failingURLString() {
        let e = URLError(.badURL, userInfo: userInfo)
        XCTAssertNotNil(e.failureURLString)
        XCTAssertEqual(e.failureURLString, e.userInfo[NSURLErrorFailingURLStringErrorKey] as? String)
    }
}

class TestCocoaError: XCTestCase {

    static var allTests: [(String, (TestCocoaError) -> () throws -> Void)] {
        return [
            ("test_errorCode", TestCocoaError.test_errorCode),
            ("test_filePath", TestCocoaError.test_filePath),
            ("test_url", TestCocoaError.test_url),
            ("test_stringEncoding", TestCocoaError.test_stringEncoding),
            ("test_underlying", TestCocoaError.test_underlying),
        ]
    }

    static let testURL = URL(string: "file:///")!
    let userInfo: [String: Any] =  [
        NSURLErrorKey: TestCocoaError.testURL,
        NSFilePathErrorKey: TestCocoaError.testURL.path,
        NSUnderlyingErrorKey: POSIXError(.EACCES),
        NSStringEncodingErrorKey: String.Encoding.utf16.rawValue,
    ]

    func test_errorCode() {
        let e = CocoaError(.fileReadNoSuchFile)
        XCTAssertEqual(e.errorCode, CocoaError.Code.fileReadNoSuchFile.rawValue)
        XCTAssertEqual(e.isCoderError, false)
        XCTAssertEqual(e.isExecutableError, false)
        XCTAssertEqual(e.isFileError, true)
        XCTAssertEqual(e.isFormattingError, false)
        XCTAssertEqual(e.isPropertyListError, false)
        XCTAssertEqual(e.isUbiquitousFileError, false)
        XCTAssertEqual(e.isUserActivityError, false)
        XCTAssertEqual(e.isValidationError, false)
        XCTAssertEqual(e.isXPCConnectionError, false)
    }

    func test_filePath() {
        let e = CocoaError(.fileWriteNoPermission, userInfo: userInfo)
        XCTAssertNotNil(e.filePath)
        XCTAssertEqual(e.filePath, TestCocoaError.testURL.path)
    }

    func test_url() {
        let e = CocoaError(.fileReadNoSuchFile, userInfo: userInfo)
        XCTAssertNotNil(e.url)
        XCTAssertEqual(e.url, TestCocoaError.testURL)
    }

    func test_stringEncoding() {
        let e = CocoaError(.fileReadUnknownStringEncoding, userInfo: userInfo)
        XCTAssertNotNil(e.stringEncoding)
        XCTAssertEqual(e.stringEncoding, .utf16)
    }

    func test_underlying() {
        let e = CocoaError(.fileWriteNoPermission, userInfo: userInfo)
        XCTAssertNotNil(e.underlying as? POSIXError)
        XCTAssertEqual(e.underlying as? POSIXError, POSIXError.init(.EACCES))
    }
}
