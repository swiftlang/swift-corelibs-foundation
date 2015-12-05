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



class TestNSBundle : XCTestCase {
    
    var allTests : [(String, () -> ())] {
        return [
            ("test_paths", test_paths),
            ("test_resources", test_resources),
            ("test_infoPlist", test_infoPlist),
            ("test_localizations", test_localizations),
        ]
    }
    
    func test_paths() {
        let bundle = NSBundle.mainBundle()
        
        // bundlePath
        XCTAssert(!bundle.bundlePath.isEmpty)
        XCTAssertEqual(bundle.bundleURL.path, bundle.bundlePath)
        let path = bundle.bundlePath
        
        // etc
        #if os(OSX)
        XCTAssertEqual("\(path)/Contents/Resources", bundle.resourcePath)
        XCTAssertEqual("\(path)/Contents/MacOS/TestFoundation", bundle.executablePath)
        XCTAssertEqual("\(path)/Contents/Frameworks", bundle.privateFrameworksPath)
        XCTAssertEqual("\(path)/Contents/SharedFrameworks", bundle.sharedFrameworksPath)
        XCTAssertEqual("\(path)/Contents/SharedSupport", bundle.sharedSupportPath)
        #endif
        
        XCTAssertNil(bundle.pathForAuxiliaryExecutable("no_such_file"))
        XCTAssertNil(bundle.appStoreReceiptURL)
    }
    
    func test_resources() {
        let bundle = NSBundle.mainBundle()
        
        // bad resources
        XCTAssertNil(bundle.URLForResource(nil, withExtension: nil, subdirectory: nil))
        XCTAssertNil(bundle.URLForResource("", withExtension: "", subdirectory: nil))
        XCTAssertNil(bundle.URLForResource("no_such_file", withExtension: nil, subdirectory: nil))
        
        // test file
        let testPlist = bundle.URLForResource("Test", withExtension: "plist")
        XCTAssertNotNil(testPlist)
        XCTAssertEqual("Test.plist", testPlist!.lastPathComponent)
        XCTAssert(NSFileManager.defaultManager().fileExistsAtPath(testPlist!.path!))
        
        // aliases, paths
        XCTAssertEqual(testPlist!.path, bundle.URLForResource("Test", withExtension: "plist", subdirectory: nil)!.path)
        XCTAssertEqual(testPlist!.path, bundle.pathForResource("Test", ofType: "plist"))
        XCTAssertEqual(testPlist!.path, bundle.pathForResource("Test", ofType: "plist", inDirectory: nil))
    }
    
    func test_infoPlist() {
        let bundle = NSBundle.mainBundle()
        
        // bundleIdentifier
        XCTAssertEqual("com.apple.TestFoundation", bundle.bundleIdentifier)
        
        // infoDictionary
        let info = bundle.infoDictionary
        XCTAssertNotNil(info)
        XCTAssert("com.apple.TestFoundation" == info!["CFBundleIdentifier"] as! String)
        XCTAssert("TestFoundation" == info!["CFBundleName"] as! String)
        
        // localizedInfoDictionary
        XCTAssertNil(bundle.localizedInfoDictionary) // FIXME: Add a localized Info.plist for testing
    }
    
    func test_localizations() {
        let bundle = NSBundle.mainBundle()
        
        XCTAssertEqual(["en"], bundle.localizations)
        XCTAssertEqual(["en"], bundle.preferredLocalizations)
        XCTAssertEqual(["en"], NSBundle.preferredLocalizationsFromArray(["en", "pl", "es"]))
    }
}
