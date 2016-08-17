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



class TestNSBundle : XCTestCase {
    
    static var allTests: [(String, (TestNSBundle) -> () throws -> Void)] {
        return [
            ("test_paths", test_paths),
            ("test_resources", test_resources),
            ("test_infoPlist", test_infoPlist),
            ("test_localizations", test_localizations),
            ("test_URLsForResourcesWithExtension", test_URLsForResourcesWithExtension),
            ("test_bundleLoad", test_bundleLoad),
            ("test_bundleLoadWithError", test_bundleLoadWithError),
            ("test_bundleWithInvalidPath", test_bundleWithInvalidPath),
            ("test_bundlePreflight", test_bundlePreflight),
        ]
    }
    
    func test_paths() {
        let bundle = Bundle.main
        
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
        
        XCTAssertNil(bundle.path(forAuxiliaryExecutable: "no_such_file"))
        XCTAssertNil(bundle.appStoreReceiptURL)
    }
    
    func test_resources() {
        let bundle = Bundle.main
        
        // bad resources
        XCTAssertNil(bundle.url(forResource: nil, withExtension: nil, subdirectory: nil))
        XCTAssertNil(bundle.url(forResource: "", withExtension: "", subdirectory: nil))
        XCTAssertNil(bundle.url(forResource: "no_such_file", withExtension: nil, subdirectory: nil))
        
        // test file
        let testPlist = bundle.url(forResource: "Test", withExtension: "plist")
        XCTAssertNotNil(testPlist)
        XCTAssertEqual("Test.plist", testPlist!.lastPathComponent)
        XCTAssert(FileManager.default.fileExists(atPath: testPlist!.path))
        
        // aliases, paths
        XCTAssertEqual(testPlist!.path, bundle.url(forResource: "Test", withExtension: "plist", subdirectory: nil)!.path)
        XCTAssertEqual(testPlist!.path, bundle.path(forResource: "Test", ofType: "plist"))
        XCTAssertEqual(testPlist!.path, bundle.path(forResource: "Test", ofType: "plist", inDirectory: nil))
    }
    
    func test_infoPlist() {
        let bundle = Bundle.main
        
        // bundleIdentifier
        XCTAssertEqual("org.swift.TestFoundation", bundle.bundleIdentifier)
        
        // infoDictionary
        let info = bundle.infoDictionary
        XCTAssertNotNil(info)
        XCTAssert("org.swift.TestFoundation" == info!["CFBundleIdentifier"] as! String)
        XCTAssert("TestFoundation" == info!["CFBundleName"] as! String)
        
        // localizedInfoDictionary
        XCTAssertNil(bundle.localizedInfoDictionary) // FIXME: Add a localized Info.plist for testing
    }
    
    func test_localizations() {
        let bundle = Bundle.main
        
        XCTAssertEqual(["en"], bundle.localizations)
        XCTAssertEqual(["en"], bundle.preferredLocalizations)
        XCTAssertEqual(["en"], Bundle.preferredLocalizations(from: ["en", "pl", "es"]))
    }
    
    private let _bundleName = "MyBundle.bundle"
    private let _bundleResourceNames = ["hello.world", "goodbye.world", "swift.org"]
    private let _subDirectory = "Sources"
    private let _main = "main"
    private let _type = "swift"
    
    private func _setupPlayground() -> String? {
        // Make sure the directory is uniquely named
        let tempDir = "/tmp/TestFoundation_Playground_" + NSUUID().uuidString + "/"
        
        do {
            try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: false, attributes: nil)
            
            // Make a flat bundle in the playground
            let bundlePath = tempDir + _bundleName
            try FileManager.default.createDirectory(atPath: bundlePath, withIntermediateDirectories: false, attributes: nil)
            
            // Put some resources in the bundle
            for n in _bundleResourceNames {
                let _ = FileManager.default.createFile(atPath: bundlePath + "/" + n, contents: nil, attributes: nil)
            }
            // Add a resource into a subdirectory
            let subDirPath = bundlePath + "/" + _subDirectory
            try FileManager.default.createDirectory(atPath: subDirPath, withIntermediateDirectories: false, attributes: nil)
            let _ = FileManager.default.createFile(atPath: subDirPath + "/" + _main + "." + _type, contents: nil, attributes: nil)
        } catch _ {
            return nil
        }
        
        
        return tempDir
    }
    
    private func _cleanupPlayground(_ location: String) {
        do {
            try FileManager.default.removeItem(atPath: location)
        } catch _ {
            // Oh well
        }
    }

    func test_URLsForResourcesWithExtension() {
        guard let playground = _setupPlayground() else { XCTFail("Unable to create playground"); return }
        
        let bundle = Bundle(path: playground + _bundleName)
        XCTAssertNotNil(bundle)
        
        let worldResources = bundle?.urls(forResourcesWithExtension: "world", subdirectory: nil)
        XCTAssertNotNil(worldResources)
        XCTAssertEqual(worldResources?.count, 2)
        
        let path = bundle?.path(forResource: _main, ofType: _type, inDirectory: _subDirectory)
        XCTAssertNotNil(path)
        
        _cleanupPlayground(playground)
    }
    
    func test_bundleLoad(){
        let bundle = Bundle.main
        let _ = bundle.load()
        XCTAssertTrue(bundle.isLoaded)
    }
    
    func test_bundleLoadWithError(){
        let bundleValid = Bundle.main
        //test valid load using loadAndReturnError
        do{
            try bundleValid.loadAndReturnError()
        }catch{
            XCTFail("should not fail to load")
        }
        // executable cannot be located
        guard let playground = _setupPlayground() else { XCTFail("Unable to create playground"); return }
        let bundle = Bundle(path: playground + _bundleName)
        XCTAssertThrowsError(try bundle!.loadAndReturnError())
        _cleanupPlayground(playground)
    }
    
    func test_bundleWithInvalidPath(){
        let bundleInvalid = Bundle(path: "/tmp/test.playground")
        XCTAssertNil(bundleInvalid)
    }
    
    func test_bundlePreflight(){
        let bundleValid = Bundle.main
        do{
            try bundleValid.preflight()
        }catch{
            XCTFail("should not fail to load")
        }
        // executable cannot be located ..preflight should report error
        guard let playground = _setupPlayground() else { XCTFail("Unable to create playground"); return }
        let bundle = Bundle(path: playground + _bundleName)
        XCTAssertThrowsError(try bundle!.preflight())
        _cleanupPlayground(playground)
    }


}
