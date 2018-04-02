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

class TestFileManager : XCTestCase {
    
    static var allTests: [(String, (TestFileManager) -> () throws -> Void)] {
        return [
            ("test_createDirectory", test_createDirectory ),
            ("test_createFile", test_createFile ),
            ("test_moveFile", test_moveFile),
            ("test_fileSystemRepresentation", test_fileSystemRepresentation),
            ("test_fileAttributes", test_fileAttributes),
            ("test_fileSystemAttributes", test_fileSystemAttributes),
            ("test_setFileAttributes", test_setFileAttributes),
            ("test_directoryEnumerator", test_directoryEnumerator),
            ("test_pathEnumerator",test_pathEnumerator),
            ("test_contentsOfDirectoryAtPath", test_contentsOfDirectoryAtPath),
            ("test_subpathsOfDirectoryAtPath", test_subpathsOfDirectoryAtPath),
            ("test_copyItemAtPathToPath", test_copyItemAtPathToPath),
            ("test_homedirectoryForUser", test_homedirectoryForUser),
            ("test_temporaryDirectoryForUser", test_temporaryDirectoryForUser),
            ("test_creatingDirectoryWithShortIntermediatePath", test_creatingDirectoryWithShortIntermediatePath),
        ]
    }
    
    func ignoreError(_ block: () throws -> Void) {
        do { try block() } catch { }
    }
    
    func test_createDirectory() {
        let fm = FileManager.default
        let path = NSTemporaryDirectory() + "testdir\(NSUUID().uuidString)"
        
        ignoreError { try fm.removeItem(atPath: path) }
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
        } catch _ {
            XCTFail()
        }

        // Ensure attempting to create the directory again fails gracefully.
        XCTAssertNil(try? fm.createDirectory(atPath: path, withIntermediateDirectories:false, attributes:nil))

        var isDir: ObjCBool = false
        let exists = fm.fileExists(atPath: path, isDirectory: &isDir)
        XCTAssertTrue(exists)
        XCTAssertTrue(isDir.boolValue)

        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up file")
        }
        
    }
    
    func test_createFile() {
        let fm = FileManager.default
        let path = NSTemporaryDirectory() + "testfile\(NSUUID().uuidString)"
        
        ignoreError { try fm.removeItem(atPath: path) }
        
        XCTAssertTrue(fm.createFile(atPath: path, contents: Data(), attributes: nil))
        
        var isDir: ObjCBool = false
        let exists = fm.fileExists(atPath: path, isDirectory: &isDir)
        XCTAssertTrue(exists)
        XCTAssertFalse(isDir.boolValue)
        
        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up file")
        }

        let permissions = NSNumber(value: Int16(0o753))
        let attributes = [FileAttributeKey.posixPermissions: permissions]
        XCTAssertTrue(fm.createFile(atPath: path, contents: Data(),
                                    attributes: attributes))
        guard let retrievedAtributes = try? fm.attributesOfItem(atPath: path) else {
            XCTFail("Failed to retrieve file attributes from created file")
            return
        }

        XCTAssertTrue(retrievedAtributes.contains(where: { (attribute) -> Bool in
            guard let attributeValue = attribute.value as? NSNumber else {
                return false
            }
            return (attribute.key == .posixPermissions)
                && (attributeValue == permissions)
        }))

        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up file")
        }
    }

    func test_creatingDirectoryWithShortIntermediatePath() {
        let fileManager = FileManager.default
        fileManager.changeCurrentDirectoryPath(NSTemporaryDirectory())

        let relativePath = NSUUID().uuidString

        do {
            try fileManager.createDirectory(atPath: relativePath, withIntermediateDirectories: true, attributes: nil)
            try fileManager.removeItem(atPath: relativePath)
        } catch {
            XCTFail("Failed to create and clean up directory")
        }
    }

    func test_moveFile() {
        let fm = FileManager.default
        let path = NSTemporaryDirectory() + "testfile\(NSUUID().uuidString)"
        let path2 = NSTemporaryDirectory() + "testfile2\(NSUUID().uuidString)"

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

#if !DARWIN_COMPATIBILITY_TESTS // auto-released by Darwin's Foundation
        result.deallocate()
#endif
    }
    
    func test_fileAttributes() {
        let fm = FileManager.default
        let path = NSTemporaryDirectory() + "test_fileAttributes\(NSUUID().uuidString)"

        ignoreError { try fm.removeItem(atPath: path) }
        
        XCTAssertTrue(fm.createFile(atPath: path, contents: Data(), attributes: nil))
        
        do {
            let attrs = try fm.attributesOfItem(atPath: path)
            
            XCTAssertTrue(attrs.count > 0)
            
            let fileSize = attrs[.size] as? NSNumber
            XCTAssertEqual(fileSize!.int64Value, 0)
            
            let fileModificationDate = attrs[.modificationDate] as? Date
            XCTAssertGreaterThan(Date().timeIntervalSince1970, fileModificationDate!.timeIntervalSince1970)
            
            let filePosixPermissions = attrs[.posixPermissions] as? NSNumber
            XCTAssertNotEqual(filePosixPermissions!.int64Value, 0)
            
            let fileReferenceCount = attrs[.referenceCount] as? NSNumber
            XCTAssertEqual(fileReferenceCount!.int64Value, 1)
            
            let fileSystemNumber = attrs[.systemNumber] as? NSNumber
            XCTAssertNotEqual(fileSystemNumber!.int64Value, 0)
            
            let fileSystemFileNumber = attrs[.systemFileNumber] as? NSNumber
            XCTAssertNotEqual(fileSystemFileNumber!.int64Value, 0)
            
            let fileType = attrs[.type] as? FileAttributeType
            XCTAssertEqual(fileType!, .typeRegular)
            
            let fileOwnerAccountID = attrs[.ownerAccountID] as? NSNumber
            XCTAssertNotNil(fileOwnerAccountID)
            
            let fileGroupOwnerAccountID = attrs[.groupOwnerAccountID] as? NSNumber
            XCTAssertNotNil(fileGroupOwnerAccountID)
            
            if let fileOwnerAccountName = attrs[.ownerAccountName] {
                XCTAssertNotNil(fileOwnerAccountName as? String)
                if let fileOwnerAccountNameStr = fileOwnerAccountName as? String {
                    XCTAssertFalse(fileOwnerAccountNameStr.isEmpty)
                }
            }
            
            if let fileGroupOwnerAccountName = attrs[.groupOwnerAccountName] {
                XCTAssertNotNil(fileGroupOwnerAccountName as? String)
                if let fileGroupOwnerAccountNameStr = fileGroupOwnerAccountName as? String {
                    XCTAssertFalse(fileGroupOwnerAccountNameStr.isEmpty)
                }
            }
            
        } catch let err {
            XCTFail("\(err)")
        }
        
        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }
    
    func test_fileSystemAttributes() {
        let fm = FileManager.default
        let path = NSTemporaryDirectory()
        
        do {
            let attrs = try fm.attributesOfFileSystem(forPath: path)
            
            XCTAssertTrue(attrs.count > 0)
            
            let systemNumber = attrs[.systemNumber] as? NSNumber
            XCTAssertNotNil(systemNumber)
            XCTAssertNotEqual(systemNumber!.uint64Value, 0)
            
            let systemFreeSize = attrs[.systemFreeSize] as? NSNumber
            XCTAssertNotNil(systemFreeSize)
            XCTAssertNotEqual(systemFreeSize!.uint64Value, 0)
            
            let systemSize = attrs[.systemSize] as? NSNumber
            XCTAssertNotNil(systemSize)
            XCTAssertGreaterThan(systemSize!.uint64Value, systemFreeSize!.uint64Value)
            
            let systemFreeNodes = attrs[.systemFreeNodes] as? NSNumber
            XCTAssertNotNil(systemFreeNodes)
            XCTAssertNotEqual(systemFreeNodes!.uint64Value, 0)
            
            let systemNodes = attrs[.systemNodes] as? NSNumber
            XCTAssertNotNil(systemNodes)
            XCTAssertGreaterThan(systemNodes!.uint64Value, systemFreeNodes!.uint64Value)
            
        } catch let err {
            XCTFail("\(err)")
        }
    }
    
    func test_setFileAttributes() {
        let path = NSTemporaryDirectory() + "test_setFileAttributes\(NSUUID().uuidString)"
        let fm = FileManager.default
        
        ignoreError { try fm.removeItem(atPath: path) }
        XCTAssertTrue(fm.createFile(atPath: path, contents: Data(), attributes: nil))
        
        do {
            try fm.setAttributes([.posixPermissions : NSNumber(value: Int16(0o0600))], ofItemAtPath: path)
        }
        catch { XCTFail("\(error)") }
        
        //read back the attributes
        do {
            let attributes = try fm.attributesOfItem(atPath: path)
            XCTAssert((attributes[.posixPermissions] as? NSNumber)?.int16Value == 0o0600)
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
        let basePath = NSTemporaryDirectory() + "\(testDirName)"
        let itemPath = NSTemporaryDirectory() + "\(testDirName)/item"
        let basePath2 = NSTemporaryDirectory() + "\(testDirName)/path2"
        let itemPath2 = NSTemporaryDirectory() + "\(testDirName)/path2/item"
        
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
        let path = NSTemporaryDirectory() + "\(testDirName)"
        let itemPath = NSTemporaryDirectory() + "\(testDirName)/item"
        
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
        
        let subDirPath = NSTemporaryDirectory() + "\(testDirName)/testdir2"
        let subDirItemPath = NSTemporaryDirectory() + "\(testDirName)/testdir2/item"
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
        let path = NSTemporaryDirectory() + "\(testDirName)"
        let itemPath1 = NSTemporaryDirectory() + "\(testDirName)/item"
        let itemPath2 = NSTemporaryDirectory() + "\(testDirName)/item2"
        
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
            // Check a bad path fails
            let _ = try fm.contentsOfDirectory(atPath: "/...")
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
        let path = NSTemporaryDirectory() + "testdir"
        let path2 = NSTemporaryDirectory() + "testdir/sub"
        let itemPath1 = NSTemporaryDirectory() + "testdir/item"
        let itemPath2 = NSTemporaryDirectory() + "testdir/item2"
        let itemPath3 = NSTemporaryDirectory() + "testdir/sub/item3"
                
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
            // Check a bad path fails
            let _ = try fm.subpathsOfDirectory(atPath: "/...")
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
    
    func test_copyItemAtPathToPath() {
        let fm = FileManager.default
        let srcPath = NSTemporaryDirectory() + "testdir\(NSUUID().uuidString)"
        let destPath = NSTemporaryDirectory() + "testdir\(NSUUID().uuidString)"
        
        func cleanup() {
            ignoreError { try fm.removeItem(atPath: srcPath) }
            ignoreError { try fm.removeItem(atPath: destPath) }
        }
        
        func directoryExists(atPath path: String) -> Bool {
            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: path, isDirectory: &isDir)
            return exists && isDir.boolValue
        }
        
        func createDirectory(atPath path: String) {
            do {
                try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch let error {
                XCTFail("Unable to create directory: \(error)")
            }
            XCTAssertTrue(directoryExists(atPath: path))
        }
        
        func createFile(atPath path: String) {
            XCTAssertTrue(fm.createFile(atPath: path, contents: Data(), attributes: nil))
        }
        
        cleanup()
        createFile(atPath: srcPath)
        do {
            try fm.copyItem(atPath: srcPath, toPath: destPath)
        } catch let error {
            XCTFail("Failed to copy file: \(error)")
        }

        cleanup()
        createDirectory(atPath: srcPath)
        createDirectory(atPath: "\(srcPath)/tempdir")
        createFile(atPath: "\(srcPath)/tempdir/tempfile")
        createFile(atPath: "\(srcPath)/tempdir/tempfile2")
        do {
            try fm.copyItem(atPath: srcPath, toPath: destPath)
        } catch let error {
            XCTFail("Unable to copy directory: \(error)")
        }
        XCTAssertTrue(directoryExists(atPath: destPath))
        XCTAssertTrue(directoryExists(atPath: "\(destPath)/tempdir"))
        XCTAssertTrue(fm.fileExists(atPath: "\(destPath)/tempdir/tempfile"))
        XCTAssertTrue(fm.fileExists(atPath: "\(destPath)/tempdir/tempfile2"))
        
        if (false == directoryExists(atPath: destPath)) {
            return
        }
        do {
            try fm.copyItem(atPath: srcPath, toPath: destPath)
        } catch {
            return
        }
        XCTFail("Copy overwrites a file/folder that already exists")
    }
    
    func test_homedirectoryForUser() {
        let filemanger = FileManager.default
        XCTAssertNil(filemanger.homeDirectory(forUser: "someuser"))
        XCTAssertNil(filemanger.homeDirectory(forUser: ""))
        XCTAssertNotNil(filemanger.homeDirectoryForCurrentUser)
    }
    
    func test_temporaryDirectoryForUser() {
        let filemanger = FileManager.default
        let tmpDir = filemanger.temporaryDirectory
        XCTAssertNotNil(tmpDir)
        let tmpFileUrl = tmpDir.appendingPathComponent("test.bin")
        let tmpFilePath = tmpFileUrl.path
        
        do {
            if filemanger.fileExists(atPath: tmpFilePath) {
                try filemanger.removeItem(at: tmpFileUrl)
            }
            
            try "hello world".write(to: tmpFileUrl, atomically: false, encoding: .utf8)
            XCTAssert(filemanger.fileExists(atPath: tmpFilePath))

            try filemanger.removeItem(at: tmpFileUrl)
        } catch {
            XCTFail("Unable to write a file to the temporary directory: \(tmpDir), err: \(error)")
        }
    }
}
