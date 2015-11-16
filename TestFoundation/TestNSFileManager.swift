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

class TestNSFileManger : XCTestCase {
    
    var allTests : [(String, () -> ())] {
        return [
            ("test_createDirectory", test_createDirectory ),
            ("test_createFile", test_createFile ),
            ("test_fileSystemRepresentation", test_fileSystemRepresentation),
            ("test_fileAttributes", test_fileAttributes),
            ("test_directoryEnumerator", test_directoryEnumerator),
        ]
    }
    
    func ignoreError(@noescape block: () throws -> Void) {
        do { try block() } catch { }
    }
    
    func test_createDirectory() {
        let fm = NSFileManager.defaultManager()
        let path = "/tmp/testdir"
        
        ignoreError { try fm.removeItemAtPath(path) }
        
        do {
            try fm.createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        var isDir = false
        let exists = fm.fileExistsAtPath(path, isDirectory: &isDir)
        XCTAssertTrue(exists)
        XCTAssertTrue(isDir)

        do {
            try fm.removeItemAtPath(path)
        } catch {
            XCTFail("Failed to clean up file")
        }
        
    }
    
    func test_createFile() {
        let fm = NSFileManager.defaultManager()
        let path = "/tmp/testfile"
        
        ignoreError { try fm.removeItemAtPath(path) }
        
        XCTAssertTrue(fm.createFileAtPath(path, contents: NSData(), attributes: nil))
        
        var isDir = false
        let exists = fm.fileExistsAtPath(path, isDirectory: &isDir)
        XCTAssertTrue(exists)
        XCTAssertFalse(isDir)
        
        do {
            try fm.removeItemAtPath(path)
        } catch {
            XCTFail("Failed to clean up file")
        }
    }
    
    func test_fileSystemRepresentation() {
        let str = "☃"
        let result = NSFileManager.defaultManager().fileSystemRepresentationWithPath(str)
        XCTAssertNotNil(result)
        let uintResult = UnsafePointer<UInt8>(result)
        XCTAssertEqual(uintResult[0], 0xE2)
        XCTAssertEqual(uintResult[1], 0x98)
        XCTAssertEqual(uintResult[2], 0x83)
    }
    
    func test_fileAttributes() {
        let fm = NSFileManager.defaultManager()
        let path = "/tmp/testfile"

        ignoreError { try fm.removeItemAtPath(path) }
        
        XCTAssertTrue(fm.createFileAtPath(path, contents: NSData(), attributes: nil))
        
        do {
            let attrs = try fm.attributesOfItemAtPath(path)
            // TODO: Actually verify the contents of the dictionary.
            XCTAssertTrue(attrs.count > 0)
        } catch let err {
            XCTFail("\(err)")
        }
        
        do {
            try fm.removeItemAtPath(path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
    
    func test_directoryEnumerator() {
        let fm = NSFileManager.defaultManager()
        let path = "/tmp/testdir"
        let itemPath = "/tmp/testdir/item"
        
        ignoreError { try fm.removeItemAtPath(path) }
        
        do {
            try fm.createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
            fm.createFileAtPath(itemPath, contents: NSData(), attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        if let e = NSFileManager.defaultManager().enumeratorAtURL(NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
            XCTAssertEqual((e.nextObject() as? NSURL)?.path, itemPath)
            XCTAssertEqual(e.level, 1)
            XCTAssertNil(e.nextObject())
            XCTAssertEqual(e.level, 0)
            XCTAssertNil(e.nextObject())
        } else {
            XCTFail()
        }
        
        let subDirPath = "/tmp/testdir/testdir2"
        let subDirItemPath = "/tmp/testdir/testdir2/item"
        do {
            try fm.createDirectoryAtPath(subDirPath, withIntermediateDirectories: false, attributes: nil)
            fm.createFileAtPath(subDirItemPath, contents: NSData(), attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        if let e = NSFileManager.defaultManager().enumeratorAtURL(NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
            XCTAssertEqual((e.nextObject() as? NSURL)?.path, itemPath)
            XCTAssertEqual(e.level, 1)
            XCTAssertEqual((e.nextObject() as? NSURL)?.path, subDirPath)
            XCTAssertEqual(e.level, 1)
            XCTAssertEqual((e.nextObject() as? NSURL)?.path, subDirItemPath)
            XCTAssertEqual(e.level, 2)
            XCTAssertNil(e.nextObject())
            XCTAssertEqual(e.level, 0)
            XCTAssertNil(e.nextObject())
        } else {
            XCTFail()
        }
        
        if let e = NSFileManager.defaultManager().enumeratorAtURL(NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [.SkipsSubdirectoryDescendants], errorHandler: nil) {
            XCTAssertEqual((e.nextObject() as? NSURL)?.path, itemPath)
            XCTAssertEqual(e.level, 1)
            XCTAssertEqual((e.nextObject() as? NSURL)?.path, subDirPath)
            XCTAssertEqual(e.level, 1)
            XCTAssertNil(e.nextObject())
            XCTAssertEqual(e.level, 0)
            XCTAssertNil(e.nextObject())
        } else {
            XCTFail()
        }
        
        if let e = NSFileManager.defaultManager().enumeratorAtURL(NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
            XCTAssertEqual((e.nextObject() as? NSURL)?.path, itemPath)
            XCTAssertEqual(e.level, 1)
            XCTAssertEqual((e.nextObject() as? NSURL)?.path, subDirPath)
            XCTAssertEqual(e.level, 1)
            e.skipDescendants()
            XCTAssertNil(e.nextObject())
            XCTAssertEqual(e.level, 0)
            XCTAssertNil(e.nextObject())
        } else {
            XCTFail()
        }
        
        var didGetError = false
        let handler : (NSURL, NSError) -> Bool = { (NSURL, NSError) in
            didGetError = true
            return true
        }
        if let e = NSFileManager.defaultManager().enumeratorAtURL(NSURL(fileURLWithPath: "/nonexistant-path"), includingPropertiesForKeys: nil, options: [], errorHandler: handler) {
            XCTAssertNil(e.nextObject())
        } else {
            XCTFail()
        }
        XCTAssertTrue(didGetError)
        
        do {
            let contents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [])
            XCTAssertEqual(contents.count, 2)
            XCTAssertEqual(contents[0].path, itemPath)
            XCTAssertEqual(contents[1].path, subDirPath)
        } catch {
            XCTFail()
        }
        
        do {
            try fm.removeItemAtPath(path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
    
}