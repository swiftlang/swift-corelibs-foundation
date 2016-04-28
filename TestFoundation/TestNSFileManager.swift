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

class TestNSFileManager : XCTestCase {
    
    static var allTests: [(String, TestNSFileManager -> () throws -> Void)] {
        return [
            ("test_createDirectory", test_createDirectory ),
            ("test_createFile", test_createFile ),
            ("test_fileSystemRepresentation", test_fileSystemRepresentation),
            ("test_fileAttributes", test_fileAttributes),
            ("test_setFileAttributes", test_setFileAttributes),
            ("test_directoryEnumerator", test_directoryEnumerator),
            ("test_pathEnumerator",test_pathEnumerator),
            ("test_contentsOfDirectoryAtPath", test_contentsOfDirectoryAtPath),
            ("test_subpathsOfDirectoryAtPath", test_subpathsOfDirectoryAtPath)
        ]
    }
    
    func ignoreError(_ block: @noescape () throws -> Void) {
        do { try block() } catch { }
    }
    
    func test_createDirectory() {
        let fm = NSFileManager.defaultManager()
        let path = "/tmp/testdir"
        
        ignoreError { try fm.removeItem(atPath: path) }
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        var isDir = false
        let exists = fm.fileExists(atPath: path, isDirectory: &isDir)
        XCTAssertTrue(exists)
        XCTAssertTrue(isDir)

        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up file")
        }
        
    }
    
    func test_createFile() {
        let fm = NSFileManager.defaultManager()
        let path = "/tmp/testfile"
        
        ignoreError { try fm.removeItem(atPath: path) }
        
        XCTAssertTrue(fm.createFile(atPath: path, contents: NSData(), attributes: nil))
        
        var isDir = false
        let exists = fm.fileExists(atPath: path, isDirectory: &isDir)
        XCTAssertTrue(exists)
        XCTAssertFalse(isDir)
        
        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up file")
        }
    }
    
    func test_fileSystemRepresentation() {
        let str = "☃"
        let result = NSFileManager.defaultManager().fileSystemRepresentation(withPath: str)
        XCTAssertNotNil(result)
        let uintResult = UnsafePointer<UInt8>(result)
        XCTAssertEqual(uintResult[0], 0xE2)
        XCTAssertEqual(uintResult[1], 0x98)
        XCTAssertEqual(uintResult[2], 0x83)
    }
    
    func test_fileAttributes() {
        let fm = NSFileManager.defaultManager()
        let path = "/tmp/test_fileAttributes\(NSUUID().UUIDString)"

        ignoreError { try fm.removeItem(atPath: path) }
        
        XCTAssertTrue(fm.createFile(atPath: path, contents: NSData(), attributes: nil))
        
        do {
            let attrs = try fm.attributesOfItem(atPath: path)
            
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
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
    
    func test_setFileAttributes() {
        let path = "/tmp/test_setFileAttributes\(NSUUID().UUIDString)"
        let fm = NSFileManager.defaultManager()
        
        ignoreError { try fm.removeItem(atPath: path) }
        XCTAssertTrue(fm.createFile(atPath: path, contents: NSData(), attributes: nil))
        
        do {
            try fm.setAttributes([NSFilePosixPermissions:NSNumber(short: 0o0600)], ofItemAtPath: path)
        }
        catch { XCTFail("\(error)") }
        
        //read back the attributes
        do {
            let attributes = try fm.attributesOfItem(atPath: path)
            XCTAssert((attributes[NSFilePosixPermissions] as? NSNumber)?.shortValue == 0o0600)
        }
        catch { XCTFail("\(error)") }
    }
    
    func test_pathEnumerator() {
        let fm = NSFileManager.defaultManager()
        let basePath = "/tmp/testdir"
        let itemPath = "/tmp/testdir/item"
        let basePath2 = "/tmp/testdir/path2"
        let itemPath2 = "/tmp/testdir/path2/item"
        
        ignoreError { try fm.removeItem(atPath: basePath) }
        
        do {
            try fm.createDirectory(atPath: basePath, withIntermediateDirectories: false, attributes: nil)
            try fm.createDirectory(atPath: basePath2, withIntermediateDirectories: false, attributes: nil)

            fm.createFile(atPath: itemPath, contents: NSData(), attributes: nil)
            fm.createFile(atPath: itemPath2, contents: NSData(), attributes: nil)

        } catch _ {
            XCTFail()
        }
        
        if let e = NSFileManager.defaultManager().enumerator(atPath: basePath) {
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
        
        ignoreError { try fm.removeItem(atPath: path) }
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            fm.createFile(atPath: itemPath, contents: NSData(), attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        if let e = NSFileManager.defaultManager().enumerator(at: NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
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
            try fm.createDirectory(atPath: subDirPath, withIntermediateDirectories: false, attributes: nil)
            fm.createFile(atPath: subDirItemPath, contents: NSData(), attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        if let e = NSFileManager.defaultManager().enumerator(at: NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
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
        
        if let e = NSFileManager.defaultManager().enumerator(at: NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants], errorHandler: nil) {
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
        
        if let e = NSFileManager.defaultManager().enumerator(at: NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
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
        if let e = NSFileManager.defaultManager().enumerator(at: NSURL(fileURLWithPath: "/nonexistant-path"), includingPropertiesForKeys: nil, options: [], errorHandler: handler) {
            XCTAssertNil(e.nextObject())
        } else {
            XCTFail()
        }
        XCTAssertTrue(didGetError)
        
        do {
            let contents = try NSFileManager.defaultManager().contentsOfDirectory(at: NSURL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: []).map {
                return $0.path!
            }
            XCTAssertEqual(contents.count, 2)
            XCTAssertTrue(contents.contains(itemPath))
            XCTAssertTrue(contents.contains(subDirPath))
        } catch {
            XCTFail()
        }
        
        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
    
    func test_contentsOfDirectoryAtPath() {
        let fm = NSFileManager.defaultManager()
        let path = "/tmp/testdir"
        let itemPath1 = "/tmp/testdir/item"
        let itemPath2 = "/tmp/testdir/item2"
        
        ignoreError { try fm.removeItem(atPath: path) }
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            fm.createFile(atPath: itemPath1, contents: NSData(), attributes: nil)
            fm.createFile(atPath: itemPath2, contents: NSData(), attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        do {
            let entries = try fm.contentsOfDirectory(atPath: path)
            
            XCTAssertEqual(2, entries.count)
            XCTAssertTrue(entries.contains("item"))
            XCTAssertTrue(entries.contains("item2"))
        }
        catch _ {
            XCTFail()
        }
        
        do {
            try fm.contentsOfDirectory(atPath: "")
            
            XCTFail()
        }
        catch _ {
            // Invalid directories should fail.
        }
        
        do {
            try fm.removeItem(atPath: path)
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
                
        ignoreError { try fm.removeItem(atPath: path) }
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            fm.createFile(atPath: itemPath1, contents: NSData(), attributes: nil)
            fm.createFile(atPath: itemPath2, contents: NSData(), attributes: nil)
            
            try fm.createDirectory(atPath: path2, withIntermediateDirectories: false, attributes: nil)
            fm.createFile(atPath: itemPath3, contents: NSData(), attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        do {
            let entries = try fm.subpathsOfDirectory(atPath: path)
            
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
            try fm.subpathsOfDirectory(atPath: "")
            
            XCTFail()
        }
        catch _ {
            // Invalid directories should fail.
        }
        
        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
}
