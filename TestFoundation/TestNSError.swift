// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

struct SwiftCustomNSError: Error, CustomNSError {
}

class TestNSError : XCTestCase {
    
    static var allTests: [(String, (TestNSError) -> () throws -> Void)] {
        return [
            ("test_LocalizedError_errorDescription", test_LocalizedError_errorDescription),
            ("test_NSErrorAsError_localizedDescription", test_NSErrorAsError_localizedDescription),
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
