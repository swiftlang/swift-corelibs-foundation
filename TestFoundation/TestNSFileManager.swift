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
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_createDirectory", test_createDirectory ),
            ("test_createFile", test_createFile ),
            ("test_fileSystemRepresentation", test_fileSystemRepresentation),
            ("test_fileAttributes", test_fileAttributes),
            ("test_directoryEnumerator", test_directoryEnumerator),
            ("test_pathEnumerator",test_pathEnumerator),
            ("test_contentsOfDirectoryAtPath", test_contentsOfDirectoryAtPath),
            ("test_subpathsOfDirectoryAtPath", test_subpathsOfDirectoryAtPath)
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
            
            XCTAssertTrue(attrs.count > 0)
            
            let fileSize = attrs[NSFileSize] as? NSNumber
            XCTAssertEqual(fileSize!.longLongValue, 0)
            
            let fileModificationDate = attrs[NSFileModificationDate] as? NSDate
            XCTAssertGreaterThan(NSDate().timeIntervalSince1970, fileModificationDate!.timeIntervalSince1970)
            
            let filePosixPermissions = attrs[NSFilePosixPermissions] as? NSNumber
            XCTAssertNotEqual(filePosixPermissions!.longLongValue, 0)
            
            let fileReferenceCount = attrs[NSFileReferenceCount] as? NSNumber
            XCTAssertEqual(fileReferenceCount!.longLongValue, 1)
            
            let fileSystemNumber = attrs[NSFileSystemNumber] as? NSNumber
            XCTAssertNotEqual(fileSystemNumber!.longLongValue, 0)
            
            let fileSystemFileNumber = attrs[NSFileSystemFileNumber] as? NSNumber
            XCTAssertNotEqual(fileSystemFileNumber!.longLongValue, 0)
            
            let fileType = attrs[NSFileType] as? String
            XCTAssertEqual(fileType!, NSFileTypeRegular)
            
            let fileOwnerAccountID = attrs[NSFileOwnerAccountID] as? NSNumber
            XCTAssertNotNil(fileOwnerAccountID)
            
        } catch let err {
            XCTFail("\(err)")
        }
        
        do {
            try fm.removeItemAtPath(path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
    
    func test_pathEnumerator() {
        let fm = NSFileManager.defaultManager()
        let basePath = "/tmp/testdir"
        let itemPath = "/tmp/testdir/item"
        let basePath2 = "/tmp/testdir/path2"
        let itemPath2 = "/tmp/testdir/path2/item"
        
        ignoreError { try fm.removeItemAtPath(basePath) }
        
        do {
            try fm.createDirectoryAtPath(basePath, withIntermediateDirectories: false, attributes: nil)
            try fm.createDirectoryAtPath(basePath2, withIntermediateDirectories: false, attributes: nil)

            fm.createFileAtPath(itemPath, contents: NSData(), attributes: nil)
            fm.createFileAtPath(itemPath2, contents: NSData(), attributes: nil)

        } catch _ {
            XCTFail()
        }
        
        if let e = NSFileManager.defaultManager().enumeratorAtPath(basePath) {
            let foundItems = NSMutableSet()
            while let item = e.nextObject() as? NSString {
                foundItems.addObject(item)
            }
            XCTAssertEqual(foundItems, NSMutableSet(array: ["item".bridge(),"path2".bridge(),"path2/item".bridge()]))
        } else {
            XCTFail()
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
            var foundItems = [String:Int]()
            while let item = e.nextObject() as? NSURL {
                if let p = item.path {
                    foundItems[p] = e.level
                }
            }
            XCTAssertEqual(foundItems[itemPath], 1)
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
            var foundItems = [String:Int]()
            while let item = e.nextObject() as? NSURL {
                if let p = item.path {
                    foundItems[p] = e.level
                }
            }
            XCTAssertEqual(foundItems[itemPath], 1)
            XCTAssertEqual(foundItems[subDirPath], 1)
            XCTAssertEqual(foundItems[subDirItemPath], 2)
        } else {
            XCTFail()
        }
        
        if let e = NSFileManager.defaultManager().enumeratorAtURL(NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [.SkipsSubdirectoryDescendants], errorHandler: nil) {
            var foundItems = [String:Int]()
            while let item = e.nextObject() as? NSURL {
                if let p = item.path {
                    foundItems[p] = e.level
                }
            }
            XCTAssertEqual(foundItems[itemPath], 1)
            XCTAssertEqual(foundItems[subDirPath], 1)
        } else {
            XCTFail()
        }
        
        if let e = NSFileManager.defaultManager().enumeratorAtURL(NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
            var foundItems = [String:Int]()
            while let item = e.nextObject() as? NSURL {
                if let p = item.path {
                    foundItems[p] = e.level
                }
            }
            XCTAssertEqual(foundItems[itemPath], 1)
            XCTAssertEqual(foundItems[subDirPath], 1)
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
            let contents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: []).map {
                return $0.path!
            }
            XCTAssertEqual(contents.count, 2)
            XCTAssertTrue(contents.contains(itemPath))
            XCTAssertTrue(contents.contains(subDirPath))
        } catch {
            XCTFail()
        }
        
        do {
            try fm.removeItemAtPath(path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
    
    func test_contentsOfDirectoryAtPath() {
        let fm = NSFileManager.defaultManager()
        let path = "/tmp/testdir"
        let itemPath1 = "/tmp/testdir/item"
        let itemPath2 = "/tmp/testdir/item2"
        
        ignoreError { try fm.removeItemAtPath(path) }
        
        do {
            try fm.createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
            fm.createFileAtPath(itemPath1, contents: NSData(), attributes: nil)
            fm.createFileAtPath(itemPath2, contents: NSData(), attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        do {
            let entries = try fm.contentsOfDirectoryAtPath(path)
            
            XCTAssertEqual(2, entries.count)
            XCTAssertTrue(entries.contains("item"))
            XCTAssertTrue(entries.contains("item2"))
        }
        catch _ {
            XCTFail()
        }
        
        do {
            try fm.contentsOfDirectoryAtPath("")
            
            XCTFail()
        }
        catch _ {
            // Invalid directories should fail.
        }
        
        do {
            try fm.removeItemAtPath(path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
    
    func test_subpathsOfDirectoryAtPath() {
        let fm = NSFileManager.defaultManager()
        let path = "/tmp/testdir"
        let path2 = "/tmp/testdir/sub"
        let itemPath1 = "/tmp/testdir/item"
        let itemPath2 = "/tmp/testdir/item2"
        let itemPath3 = "/tmp/testdir/sub/item3"
                
        ignoreError { try fm.removeItemAtPath(path) }
        
        do {
            try fm.createDirectoryAtPath(path, withIntermediateDirectories: false, attributes: nil)
            fm.createFileAtPath(itemPath1, contents: NSData(), attributes: nil)
            fm.createFileAtPath(itemPath2, contents: NSData(), attributes: nil)
            
            try fm.createDirectoryAtPath(path2, withIntermediateDirectories: false, attributes: nil)
            fm.createFileAtPath(itemPath3, contents: NSData(), attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        do {
            let entries = try fm.subpathsOfDirectoryAtPath(path)
            
            XCTAssertEqual(4, entries.count)
            XCTAssertTrue(entries.contains("item"))
            XCTAssertTrue(entries.contains("item2"))
            XCTAssertTrue(entries.contains("sub"))
            XCTAssertTrue(entries.contains("sub/item3"))
        }
        catch _ {
            XCTFail()
        }
        
        do {
            try fm.subpathsOfDirectoryAtPath("")
            
            XCTFail()
        }
        catch _ {
            // Invalid directories should fail.
        }
        
        do {
            try fm.removeItemAtPath(path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
}