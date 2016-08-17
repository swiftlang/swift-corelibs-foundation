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
    
    static var allTests: [(String, (TestNSFileManager) -> () throws -> Void)] {
        return [
            ("test_createDirectory", test_createDirectory ),
            ("test_createFile", test_createFile ),
            ("test_moveFile", test_moveFile),
            ("test_fileSystemRepresentation", test_fileSystemRepresentation),
            ("test_fileAttributes", test_fileAttributes),
            ("test_setFileAttributes", test_setFileAttributes),
            ("test_directoryEnumerator", test_directoryEnumerator),
            ("test_pathEnumerator",test_pathEnumerator),
            ("test_contentsOfDirectoryAtPath", test_contentsOfDirectoryAtPath),
            ("test_subpathsOfDirectoryAtPath", test_subpathsOfDirectoryAtPath),
        ]
    }
    
    func ignoreError(_ block: () throws -> Void) {
        do { try block() } catch { }
    }
    
    func test_createDirectory() {
        let fm = FileManager.default
        let path = "/tmp/testdir\(NSUUID().uuidString)"
        
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
        let fm = FileManager.default
        let path = "/tmp/testfile\(NSUUID().uuidString)"
        
        ignoreError { try fm.removeItem(atPath: path) }
        
        XCTAssertTrue(fm.createFile(atPath: path, contents: Data(), attributes: nil))
        
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

    func test_moveFile() {
        let fm = FileManager.default
        let path = "/tmp/testfile\(NSUUID().uuidString)"
        let path2 = "/tmp/testfile2\(NSUUID().uuidString)"

        func cleanup() {
            ignoreError { try fm.removeItem(atPath: path) }
            ignoreError { try fm.removeItem(atPath: path2) }
        }

        cleanup()

        XCTAssertTrue(fm.createFile(atPath: path, contents: Data(), attributes: nil))
        defer { cleanup() }

        do {
            try fm.moveItem(atPath: path, toPath: path2)
        } catch let error {
            XCTFail("Failed to move file: \(error)")
        }
    }

    func test_fileSystemRepresentation() {
        let str = "☃"
        let result = FileManager.default.fileSystemRepresentation(withPath: str)
        XCTAssertNotNil(result)
        XCTAssertEqual(UInt8(bitPattern: result[0]), 0xE2)
        XCTAssertEqual(UInt8(bitPattern: result[1]), 0x98)
        XCTAssertEqual(UInt8(bitPattern: result[2]), 0x83)
    }
    
    func test_fileAttributes() {
        let fm = FileManager.default
        let path = "/tmp/test_fileAttributes\(NSUUID().uuidString)"

        ignoreError { try fm.removeItem(atPath: path) }
        
        XCTAssertTrue(fm.createFile(atPath: path, contents: Data(), attributes: nil))
        
        do {
            let attrs = try fm.attributesOfItem(atPath: path)
            
            XCTAssertTrue(attrs.count > 0)
            
            let fileSize = attrs[NSFileSize] as? NSNumber
            XCTAssertEqual(fileSize!.int64Value, 0)
            
            let fileModificationDate = attrs[NSFileModificationDate] as? Date
            XCTAssertGreaterThan(Date().timeIntervalSince1970, fileModificationDate!.timeIntervalSince1970)
            
            let filePosixPermissions = attrs[NSFilePosixPermissions] as? NSNumber
            XCTAssertNotEqual(filePosixPermissions!.int64Value, 0)
            
            let fileReferenceCount = attrs[NSFileReferenceCount] as? NSNumber
            XCTAssertEqual(fileReferenceCount!.int64Value, 1)
            
            let fileSystemNumber = attrs[NSFileSystemNumber] as? NSNumber
            XCTAssertNotEqual(fileSystemNumber!.int64Value, 0)
            
            let fileSystemFileNumber = attrs[NSFileSystemFileNumber] as? NSNumber
            XCTAssertNotEqual(fileSystemFileNumber!.int64Value, 0)
            
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
        let path = "/tmp/test_setFileAttributes\(NSUUID().uuidString)"
        let fm = FileManager.default
        
        ignoreError { try fm.removeItem(atPath: path) }
        XCTAssertTrue(fm.createFile(atPath: path, contents: Data(), attributes: nil))
        
        do {
            try fm.setAttributes([NSFilePosixPermissions:NSNumber(value: Int16(0o0600))], ofItemAtPath: path)
        }
        catch { XCTFail("\(error)") }
        
        //read back the attributes
        do {
            let attributes = try fm.attributesOfItem(atPath: path)
            XCTAssert((attributes[NSFilePosixPermissions] as? NSNumber)?.int16Value == 0o0600)
        }
        catch { XCTFail("\(error)") }

        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
    
    func test_pathEnumerator() {
        let fm = FileManager.default
        let testDirName = "testdir\(NSUUID().uuidString)"
        let basePath = "/tmp/\(testDirName)"
        let itemPath = "/tmp/\(testDirName)/item"
        let basePath2 = "/tmp/\(testDirName)/path2"
        let itemPath2 = "/tmp/\(testDirName)/path2/item"
        
        ignoreError { try fm.removeItem(atPath: basePath) }
        
        do {
            try fm.createDirectory(atPath: basePath, withIntermediateDirectories: false, attributes: nil)
            try fm.createDirectory(atPath: basePath2, withIntermediateDirectories: false, attributes: nil)

            let _ = fm.createFile(atPath: itemPath, contents: Data(), attributes: nil)
            let _ = fm.createFile(atPath: itemPath2, contents: Data(), attributes: nil)

        } catch _ {
            XCTFail()
        }
        
        if let e = FileManager.default.enumerator(atPath: basePath) {
            var foundItems = Set<String>()
            while let item = e.nextObject() as? String {
                foundItems.insert(item)
            }
            XCTAssertEqual(foundItems, Set(["item", "path2", "path2/item"]))
        } else {
            XCTFail()
        }

    }
    
    func test_directoryEnumerator() {
        let fm = FileManager.default
        let testDirName = "testdir\(NSUUID().uuidString)"
        let path = "/tmp/\(testDirName)"
        let itemPath = "/tmp/\(testDirName)/item"
        
        ignoreError { try fm.removeItem(atPath: path) }
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            let _ = fm.createFile(atPath: itemPath, contents: Data(), attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        if let e = FileManager.default.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
            var foundItems = [String:Int]()
            while let item = e.nextObject() as? URL {
                foundItems[item.path] = e.level
            }
            XCTAssertEqual(foundItems[itemPath], 1)
        } else {
            XCTFail()
        }
        
        let subDirPath = "/tmp/\(testDirName)/testdir2"
        let subDirItemPath = "/tmp/\(testDirName)/testdir2/item"
        do {
            try fm.createDirectory(atPath: subDirPath, withIntermediateDirectories: false, attributes: nil)
            let _ = fm.createFile(atPath: subDirItemPath, contents: Data(), attributes: nil)
        } catch _ {
            XCTFail()
        }
        
        if let e = FileManager.default.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
            var foundItems = [String:Int]()
            while let item = e.nextObject() as? URL {
                foundItems[item.path] = e.level
            }
            XCTAssertEqual(foundItems[itemPath], 1)
            XCTAssertEqual(foundItems[subDirPath], 1)
            XCTAssertEqual(foundItems[subDirItemPath], 2)
        } else {
            XCTFail()
        }
        
        if let e = FileManager.default.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants], errorHandler: nil) {
            var foundItems = [String:Int]()
            while let item = e.nextObject() as? URL {
                foundItems[item.path] = e.level
            }
            XCTAssertEqual(foundItems[itemPath], 1)
            XCTAssertEqual(foundItems[subDirPath], 1)
        } else {
            XCTFail()
        }
        
        if let e = FileManager.default.enumerator(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: [], errorHandler: nil) {
            var foundItems = [String:Int]()
            while let item = e.nextObject() as? URL {
                foundItems[item.path] = e.level
            }
            XCTAssertEqual(foundItems[itemPath], 1)
            XCTAssertEqual(foundItems[subDirPath], 1)
        } else {
            XCTFail()
        }
        
        var didGetError = false
        let handler : (URL, Error) -> Bool = { (URL, Error) in
            didGetError = true
            return true
        }
        if let e = FileManager.default.enumerator(at: URL(fileURLWithPath: "/nonexistant-path"), includingPropertiesForKeys: nil, options: [], errorHandler: handler) {
            XCTAssertNil(e.nextObject())
        } else {
            XCTFail()
        }
        XCTAssertTrue(didGetError)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: path), includingPropertiesForKeys: nil, options: []).map {
                return $0.path
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
        let fm = FileManager.default
        let testDirName = "testdir\(NSUUID().uuidString)"
        let path = "/tmp/\(testDirName)"
        let itemPath1 = "/tmp/\(testDirName)/item"
        let itemPath2 = "/tmp/\(testDirName)/item2"
        
        ignoreError { try fm.removeItem(atPath: path) }
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            let _ = fm.createFile(atPath: itemPath1, contents: Data(), attributes: nil)
            let _ = fm.createFile(atPath: itemPath2, contents: Data(), attributes: nil)
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
            let _ = try fm.contentsOfDirectory(atPath: "")
            
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
        let fm = FileManager.default
        let path = "/tmp/testdir"
        let path2 = "/tmp/testdir/sub"
        let itemPath1 = "/tmp/testdir/item"
        let itemPath2 = "/tmp/testdir/item2"
        let itemPath3 = "/tmp/testdir/sub/item3"
                
        ignoreError { try fm.removeItem(atPath: path) }
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            let _ = fm.createFile(atPath: itemPath1, contents: Data(), attributes: nil)
            let _ = fm.createFile(atPath: itemPath2, contents: Data(), attributes: nil)
            
            try fm.createDirectory(atPath: path2, withIntermediateDirectories: false, attributes: nil)
            let _ = fm.createFile(atPath: itemPath3, contents: Data(), attributes: nil)
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
            let _ = try fm.subpathsOfDirectory(atPath: "")
            
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
