// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
        @testable import SwiftFoundation
    #else
        @testable import Foundation
    #endif
#endif

class TestFileManager : XCTestCase {
#if os(Windows)
    let pathSep = "\\"
#else
    let pathSep = "/"
#endif

    func test_createDirectory() {
        let fm = FileManager.default
        let path = NSTemporaryDirectory() + "testdir\(NSUUID().uuidString)"
        
        try? fm.removeItem(atPath: path)
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
        } catch {
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
        
        try? fm.removeItem(atPath: path)
        
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

#if os(Windows)
        let permissions = NSNumber(value: Int16(0o700))
#else
        let permissions = NSNumber(value: Int16(0o753))
#endif
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
        let cwd = fileManager.currentDirectoryPath
        fileManager.changeCurrentDirectoryPath(NSTemporaryDirectory())

        let relativePath = NSUUID().uuidString

        do {
            try fileManager.createDirectory(atPath: relativePath, withIntermediateDirectories: true, attributes: nil)
            try fileManager.removeItem(atPath: relativePath)
        } catch {
            XCTFail("Failed to create and clean up directory")
        }
        fileManager.changeCurrentDirectoryPath(cwd)
    }

    func test_moveFile() {
        let fm = FileManager.default
        let path = NSTemporaryDirectory() + "testfile\(NSUUID().uuidString)"
        let path2 = NSTemporaryDirectory() + "testfile2\(NSUUID().uuidString)"

        func cleanup() {
            try? fm.removeItem(atPath: path)
            try? fm.removeItem(atPath: path2)
        }

        cleanup()

        XCTAssertTrue(fm.createFile(atPath: path, contents: Data(), attributes: nil))
        defer { cleanup() }

        do {
            try fm.moveItem(atPath: path, toPath: path2)
        } catch {
            XCTFail("Failed to move file: \(error)")
        }
    }

    func test_fileSystemRepresentation() {
        let str = "☃"
        let result = FileManager.default.fileSystemRepresentation(withPath: str)
        XCTAssertEqual(UInt8(bitPattern: result[0]), 0xE2)
        XCTAssertEqual(UInt8(bitPattern: result[1]), 0x98)
        XCTAssertEqual(UInt8(bitPattern: result[2]), 0x83)

#if !DARWIN_COMPATIBILITY_TESTS // auto-released by Darwin's Foundation
        result.deallocate()
#endif
    }

    func test_fileExists() {
        let fm = FileManager.default
        let tmpDir = fm.temporaryDirectory.appendingPathComponent("testFileExistsDir")
        let testFile = tmpDir.appendingPathComponent("testFile")
        let goodSymLink = tmpDir.appendingPathComponent("goodSymLink")
        let badSymLink = tmpDir.appendingPathComponent("badSymLink")
        let dirSymLink = tmpDir.appendingPathComponent("dirSymlink")

        try? fm.removeItem(atPath: tmpDir.path)

        do {
            try fm.createDirectory(atPath: tmpDir.path, withIntermediateDirectories: false, attributes: nil)
            XCTAssertTrue(fm.createFile(atPath: testFile.path, contents: Data()))
            try fm.createSymbolicLink(atPath: goodSymLink.path, withDestinationPath: testFile.path)
#if os(Windows)
            // Creating a broken symlink is expected to fail on Windows
            XCTAssertNil(try? fm.createSymbolicLink(atPath: badSymLink.path, withDestinationPath: "no_such_file"))
#else
            try fm.createSymbolicLink(atPath: badSymLink.path, withDestinationPath: "no_such_file")
#endif
            try fm.createSymbolicLink(atPath: dirSymLink.path, withDestinationPath: "..")

            var isDirFlag: ObjCBool = false
            XCTAssertTrue(fm.fileExists(atPath: tmpDir.path))
            XCTAssertTrue(fm.fileExists(atPath: tmpDir.path, isDirectory: &isDirFlag))
            XCTAssertTrue(isDirFlag.boolValue)

            isDirFlag = true
            XCTAssertTrue(fm.fileExists(atPath: testFile.path))
            XCTAssertTrue(fm.fileExists(atPath: testFile.path, isDirectory: &isDirFlag))
            XCTAssertFalse(isDirFlag.boolValue)

            isDirFlag = true
            XCTAssertTrue(fm.fileExists(atPath: goodSymLink.path))
            XCTAssertTrue(fm.fileExists(atPath: goodSymLink.path, isDirectory: &isDirFlag))
            XCTAssertFalse(isDirFlag.boolValue)

            isDirFlag = true
            XCTAssertFalse(fm.fileExists(atPath: badSymLink.path))
            XCTAssertFalse(fm.fileExists(atPath: badSymLink.path, isDirectory: &isDirFlag))

            isDirFlag = false
            XCTAssertTrue(fm.fileExists(atPath: dirSymLink.path))
            XCTAssertTrue(fm.fileExists(atPath: dirSymLink.path, isDirectory: &isDirFlag))
            XCTAssertTrue(isDirFlag.boolValue)
        } catch {
            XCTFail(String(describing: error))
        }
        try? fm.removeItem(atPath: tmpDir.path)
    }

    func test_isReadableFile() {
        let fm = FileManager.default
        let path = NSTemporaryDirectory() + "test_isReadableFile\(NSUUID().uuidString)"

        do {
            // create test file
            XCTAssertTrue(fm.createFile(atPath: path, contents: Data()))

            // test unReadable if file has no permissions
            try fm.setAttributes([.posixPermissions : NSNumber(value: Int16(0o0000))], ofItemAtPath: path)
#if os(Windows)
            // Files are always readable on Windows
            XCTAssertTrue(fm.isReadableFile(atPath: path))
#else
            XCTAssertFalse(fm.isReadableFile(atPath: path))
#endif

            // test readable if file has read permissions
            try fm.setAttributes([.posixPermissions : NSNumber(value: Int16(0o0400))], ofItemAtPath: path)
            XCTAssertTrue(fm.isReadableFile(atPath: path))
        } catch let e {
            XCTFail("\(e)")
        }
    }

    func test_isWritableFile() {
        let fm = FileManager.default
        let path = NSTemporaryDirectory() + "test_isWritableFile\(NSUUID().uuidString)"

        do {
            // create test file
            XCTAssertTrue(fm.createFile(atPath: path, contents: Data()))

            // test unWritable if file has no permissions
            try fm.setAttributes([.posixPermissions : NSNumber(value: Int16(0o0000))], ofItemAtPath: path)
            XCTAssertFalse(fm.isWritableFile(atPath: path))

            // test writable if file has write permissions
            try fm.setAttributes([.posixPermissions : NSNumber(value: Int16(0o0200))], ofItemAtPath: path)
            XCTAssertTrue(fm.isWritableFile(atPath: path))
        } catch let e {
            XCTFail("\(e)")
        }
    }

    func test_isExecutableFile() {
        let fm = FileManager.default
        let path = NSTemporaryDirectory() + "test_isExecutableFile\(NSUUID().uuidString)"

        do {
            // create test file
            XCTAssertTrue(fm.createFile(atPath: path, contents: Data()))

            // test unExecutable if file has no permissions
            try fm.setAttributes([.posixPermissions : NSNumber(value: Int16(0o0000))], ofItemAtPath: path)
#if os(Windows)
            // Files are always executable on Windows
            XCTAssertTrue(fm.isExecutableFile(atPath: path))
#else
            XCTAssertFalse(fm.isExecutableFile(atPath: path))
#endif

            // test executable if file has execute permissions
            try fm.setAttributes([.posixPermissions : NSNumber(value: Int16(0o0100))], ofItemAtPath: path)
            XCTAssertTrue(fm.isExecutableFile(atPath: path))
        } catch let e {
            XCTFail("\(e)")
        }
    }

    func test_isDeletableFile() {
        let fm = FileManager.default

        do {
            let dir_path = NSTemporaryDirectory() + "/test_isDeletableFile_dir/"
            let file_path = dir_path + "test_isDeletableFile\(NSUUID().uuidString)"
            // create test directory
            try fm.createDirectory(atPath: dir_path, withIntermediateDirectories: true)
            // create test file
            XCTAssertTrue(fm.createFile(atPath: file_path, contents: Data()))

            // test undeletable if parent directory has no permissions
            try fm.setAttributes([.posixPermissions : NSNumber(value: Int16(0o0000))], ofItemAtPath: dir_path)
            XCTAssertFalse(fm.isDeletableFile(atPath: file_path))

            // test deletable if parent directory has all necessary permissions
            try fm.setAttributes([.posixPermissions : NSNumber(value: Int16(0o0755))], ofItemAtPath: dir_path)
            XCTAssertTrue(fm.isDeletableFile(atPath: file_path))
        }
        catch { XCTFail("\(error)") }

        // test against known undeletable file
        XCTAssertFalse(fm.isDeletableFile(atPath: "/dev/null"))
    }

    func test_fileAttributes() throws {
        let fm = FileManager.default
        let path = NSTemporaryDirectory() + "test_fileAttributes\(NSUUID().uuidString)"

        try? fm.removeItem(atPath: path)
        
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
            
#if !os(Windows)
            let fileSystemFileNumber = attrs[.systemFileNumber] as? NSNumber
            XCTAssertNotEqual(fileSystemFileNumber!.int64Value, 0)
#endif
            
            let fileType = attrs[.type] as? FileAttributeType
            XCTAssertEqual(fileType!, .typeRegular)
            
            let fileOwnerAccountID = attrs[.ownerAccountID] as? NSNumber
            XCTAssertNotNil(fileOwnerAccountID)
            
            let fileGroupOwnerAccountID = attrs[.groupOwnerAccountID] as? NSNumber
            XCTAssertNotNil(fileGroupOwnerAccountID)

            // .creationDate is not not available on all systems but if it is supported check the value is reasonable
            if let creationDate = attrs[.creationDate] as? Date {
                XCTAssertGreaterThan(Date().timeIntervalSince1970, creationDate.timeIntervalSince1970)
            }

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
            
        } catch {
            XCTFail("\(error)")
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
            
            let systemFreeSize = attrs[.systemFreeSize] as? NSNumber
            XCTAssertNotNil(systemFreeSize)
            XCTAssertNotEqual(systemFreeSize!.uint64Value, 0)
            
            let systemSize = attrs[.systemSize] as? NSNumber
            XCTAssertNotNil(systemSize)
            XCTAssertGreaterThan(systemSize!.uint64Value, systemFreeSize!.uint64Value)

            if shouldAttemptWindowsXFailTests("FileAttributes[.systemFreeNodes], FileAttributes[.systemNodes] not implemented") {
              let systemFreeNodes = attrs[.systemFreeNodes] as? NSNumber
              XCTAssertNotNil(systemFreeNodes)
              XCTAssertNotEqual(systemFreeNodes!.uint64Value, 0)

              let systemNodes = attrs[.systemNodes] as? NSNumber
              XCTAssertNotNil(systemNodes)
              XCTAssertGreaterThan(systemNodes!.uint64Value, systemFreeNodes!.uint64Value)
            }
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func test_setFileAttributes() {
        let path = NSTemporaryDirectory() + "test_setFileAttributes\(NSUUID().uuidString)"
        let fm = FileManager.default
        
        try? fm.removeItem(atPath: path)
        XCTAssertTrue(fm.createFile(atPath: path, contents: Data(), attributes: nil))
        
        do {
            try fm.setAttributes([.posixPermissions : NSNumber(value: Int16(0o0600))], ofItemAtPath: path)
        }
        catch { XCTFail("\(error)") }
        
        //read back the attributes
        do {
            let attributes = try fm.attributesOfItem(atPath: path)
#if os(Windows)
            XCTAssert((attributes[.posixPermissions] as? NSNumber)?.int16Value == 0o0700)
#else
            XCTAssert((attributes[.posixPermissions] as? NSNumber)?.int16Value == 0o0600)
#endif
        }
        catch { XCTFail("\(error)") }

        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up files")
        }

        // test non existent file
        let noSuchFile = NSTemporaryDirectory() + "fileThatDoesntExist"
        try? fm.removeItem(atPath: noSuchFile)
        do {
            try fm.setAttributes([.posixPermissions: 0], ofItemAtPath: noSuchFile)
            XCTFail("Setting permissions of non-existent file should throw")
        } catch {
        }
    }
    
    func test_pathEnumerator() {
        let fm = FileManager.default
        let testDirName = "testdir\(NSUUID().uuidString)"
        let basePath = NSTemporaryDirectory() + "\(testDirName)"
        let itemPath = NSTemporaryDirectory() + "\(testDirName)/item"
        let basePath2 = NSTemporaryDirectory() + "\(testDirName)/path2"
        let itemPath2 = NSTemporaryDirectory() + "\(testDirName)/path2/item"
        
        try? fm.removeItem(atPath: basePath)
        
        do {
            try fm.createDirectory(atPath: basePath, withIntermediateDirectories: false, attributes: nil)
            try fm.createDirectory(atPath: basePath2, withIntermediateDirectories: false, attributes: nil)

            let _ = fm.createFile(atPath: itemPath, contents: Data(count: 123), attributes: nil)
            let _ = fm.createFile(atPath: itemPath2, contents: Data(count: 456), attributes: nil)

        } catch {
            XCTFail()
        }

        var item1FileAttributes: [FileAttributeKey: Any]!
        var item2FileAttributes: [FileAttributeKey: Any]!
        if let e = FileManager.default.enumerator(atPath: basePath) {
            let attrs = e.directoryAttributes
            XCTAssertNotNil(attrs)
            XCTAssertEqual(attrs?[.type] as? FileAttributeType, .typeDirectory)

            var foundItems = Set<String>()
            while let item = e.nextObject() as? String {
                foundItems.insert(item)
                if item == "item" {
                    item1FileAttributes = e.fileAttributes
                } else if item == "path2\(pathSep)item" {
                    item2FileAttributes = e.fileAttributes
                }
            }
            XCTAssertEqual(foundItems, Set(["item", "path2", "path2\(pathSep)item"]))
        } else {
            XCTFail()
        }

        XCTAssertNotNil(item1FileAttributes)
        if let size = item1FileAttributes[.size] as? NSNumber {
            XCTAssertEqual(size.int64Value, 123)
        } else {
            XCTFail("Cant get file size for 'item'")
        }

        XCTAssertNotNil(item2FileAttributes)
        if let size = item2FileAttributes[.size] as? NSNumber {
            XCTAssertEqual(size.int64Value, 456)
        } else {
            XCTFail("Cant get file size for 'path2/item'")
        }

        if let e2 = FileManager.default.enumerator(atPath: basePath) {
            var foundItems = Set<String>()
            while let item = e2.nextObject() as? String {
                foundItems.insert(item)
                if item == "path2" {
                    e2.skipDescendants()
                    XCTAssertEqual(e2.level, 1)
                    XCTAssertNotNil(e2.fileAttributes)
                }
            }
            XCTAssertEqual(foundItems, Set(["item", "path2"]))
        } else {
            XCTFail()
        }
    }
    
    func test_directoryEnumerator() {
        let fm = FileManager.default
        let basePath = NSTemporaryDirectory() + "testdir\(NSUUID().uuidString)/"
        let hiddenDir1 = basePath + "subdir1/subdir2/.hiddenDir/"
        let subDirs1 = hiddenDir1 + "subdir3/"
        let itemPath1 = basePath + "itemFile1"
#if os(Windows)
        // Filenames ending with '.' are not valid on Windows, so don't bother testing them
        let hiddenDir2 = basePath + "subdir1/subdir2/subdir4.app/subdir5/.subdir6.ext/"
        let subDirs2 = hiddenDir2 + "subdir7.ext/"
        let itemPath2 = subDirs1 + "itemFile2"
        let itemPath3 = subDirs1 + "itemFile3.ext"
#else
        let hiddenDir2 = basePath + "subdir1/subdir2/subdir4.app/subdir5./.subdir6.ext/"
        let subDirs2 = hiddenDir2 + "subdir7.ext./"
        let itemPath2 = subDirs1 + "itemFile2."
        let itemPath3 = subDirs1 + "itemFile3.ext."
#endif
        let hiddenItem1 = basePath + ".hiddenFile1"
        let hiddenItem2 = subDirs1 + ".hiddenFile2"
        let hiddenItem3 = subDirs2 + ".hiddenFile3"
        let hiddenItem4 = subDirs2 + ".hiddenFile4.ext"

        var fileLevels: [String: Int] = [
            "itemFile1": 1,
            ".hiddenFile1": 1,
            "subdir1": 1,
            "subdir2": 2,
            "subdir4.app": 3,
            ".subdir6.ext": 5,
            ".hiddenFile4.ext": 7,
            ".hiddenFile3": 7,
            ".hiddenDir": 3,
            "subdir3": 4,
            ".hiddenFile2": 5,
        ]
#if os(Windows)
        fileLevels["itemFile2"] = 5
        fileLevels["subdir5"] = 4
        fileLevels["subdir7.ext"] = 6
        fileLevels["itemFile3.ext"] = 5
#else
        fileLevels["itemFile2."] = 5
        fileLevels["subdir5."] = 4
        fileLevels["subdir7.ext."] = 6
        fileLevels["itemFile3.ext."] = 5
#endif

        func directoryItems(options: FileManager.DirectoryEnumerationOptions) -> [String: Int]? {
            guard let enumerator =
                FileManager.default.enumerator(at: URL(fileURLWithPath: basePath),
                                               includingPropertiesForKeys: nil,
                                               options: options, errorHandler: nil) else {
              return nil
            }

            var foundItems = [String:Int]()
            while let item = enumerator.nextObject() as? URL {
              foundItems[item.lastPathComponent] = enumerator.level
            }
            return foundItems
        }

        try? fm.removeItem(atPath: basePath)
        defer { try? fm.removeItem(atPath: basePath) }

        XCTAssertNotNil(try? fm.createDirectory(atPath: subDirs1, withIntermediateDirectories: true, attributes: nil))
        XCTAssertNotNil(try? fm.createDirectory(atPath: subDirs2, withIntermediateDirectories: true, attributes: nil))
        for filename in [itemPath1, itemPath2, itemPath3] {
            XCTAssertTrue(fm.createFile(atPath: filename, contents: Data(), attributes: nil), "Cant create file '\(filename)'")
        }

        var resourceValues = URLResourceValues()
        resourceValues.isHidden = true
        for filename in [ hiddenItem1, hiddenItem2, hiddenItem3, hiddenItem4] {
            XCTAssertTrue(fm.createFile(atPath: filename, contents: Data(), attributes: nil), "Cant create file '\(filename)'")
#if os(Windows)
            do {
                var url = URL(fileURLWithPath: filename)
                try url.setResourceValues(resourceValues)
            } catch {
                XCTFail("Couldn't make \(filename) a hidden file")
            }
#endif
        }

#if os(Windows)
        do {
            var hiddenURL1 = URL(fileURLWithPath: hiddenDir1)
            var hiddenURL2 = URL(fileURLWithPath: hiddenDir2)
            try hiddenURL1.setResourceValues(resourceValues)
            try hiddenURL2.setResourceValues(resourceValues)
        } catch {
            XCTFail("Couldn't make \(hiddenDir1) and \(hiddenDir2) hidden directories")
        }
#endif

        if let foundItems = directoryItems(options: []) {
            XCTAssertEqual(foundItems.count, fileLevels.count)
            for (name, level) in foundItems {
                XCTAssertEqual(fileLevels[name], level, "File level for \(name) is wrong")
            }
        } else {
            XCTFail("Cant enumerate directory at \(basePath) with options: []")
        }

        if let foundItems = directoryItems(options: [.skipsHiddenFiles]) {
            XCTAssertEqual(foundItems.count, 5)
        } else {
            XCTFail("Cant enumerate directory at \(basePath) with options: [.skipsHiddenFiles]")
        }

        if let foundItems = directoryItems(options: [.skipsSubdirectoryDescendants]) {
            XCTAssertEqual(foundItems.count, 3)
        } else {
            XCTFail("Cant enumerate directory at \(basePath) with options: [.skipsSubdirectoryDescendants]")
        }

        if let foundItems = directoryItems(options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]) {
            XCTAssertEqual(foundItems.count, 2)
        } else {
            XCTFail("Cant enumerate directory at \(basePath) with options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]")
        }

        if let foundItems = directoryItems(options: [.skipsPackageDescendants]) {
#if DARWIN_COMPATIBILITY_TESTS
            XCTAssertEqual(foundItems.count, 10)    // Only native Foundation does not gnore .skipsPackageDescendants
#else
            XCTAssertEqual(foundItems.count, 15)
#endif
        } else {
            XCTFail("Cant enumerate directory at \(basePath) with options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]")
        }

        var didGetError = false
        let handler : (URL, Error) -> Bool = { (URL, Error) in
            didGetError = true
            return true
        }
        if let e = FileManager.default.enumerator(at: URL(fileURLWithPath: "/nonexistent-path"), includingPropertiesForKeys: nil, options: [], errorHandler: handler) {
            XCTAssertNil(e.nextObject())
        } else {
            XCTFail()
        }
        XCTAssertTrue(didGetError)
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: basePath), includingPropertiesForKeys: nil, options: []).map {
                return $0.path
            }
            XCTAssertEqual(contents.count, 3)
        } catch {
            XCTFail()
        }
    }
    
    func test_contentsOfDirectoryAtPath() {
        let fm = FileManager.default
        let testDirName = "testdir\(NSUUID().uuidString)"
        let path = NSTemporaryDirectory() + "\(testDirName)"
        let itemPath1 = NSTemporaryDirectory() + "\(testDirName)/item"
        let itemPath2 = NSTemporaryDirectory() + "\(testDirName)/item2"
        
        try? fm.removeItem(atPath: path)
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            let _ = fm.createFile(atPath: itemPath1, contents: Data(), attributes: nil)
            let _ = fm.createFile(atPath: itemPath2, contents: Data(), attributes: nil)
        } catch {
            XCTFail()
        }
        
        do {
            let entries = try fm.contentsOfDirectory(atPath: path)
            
            XCTAssertEqual(2, entries.count)
            XCTAssertTrue(entries.contains("item"))
            XCTAssertTrue(entries.contains("item2"))
        }
        catch {
            XCTFail()
        }
        
        do {
            // Check a bad path fails
            let _ = try fm.contentsOfDirectory(atPath: "/...")
            XCTFail()
        }
        catch {
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
                
        try? fm.removeItem(atPath: path)
        
        do {
            try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            let _ = fm.createFile(atPath: itemPath1, contents: Data(), attributes: nil)
            let _ = fm.createFile(atPath: itemPath2, contents: Data(), attributes: nil)
            
            try fm.createDirectory(atPath: path2, withIntermediateDirectories: false, attributes: nil)
            let _ = fm.createFile(atPath: itemPath3, contents: Data(), attributes: nil)
        } catch {
            XCTFail()
        }
        
        do {
            let entries = try fm.subpathsOfDirectory(atPath: path)
            
            XCTAssertEqual(4, entries.count)
            XCTAssertTrue(entries.contains("item"))
            XCTAssertTrue(entries.contains("item2"))
            XCTAssertTrue(entries.contains("sub"))
            XCTAssertTrue(entries.contains("sub/item3"))
            XCTAssertEqual(fm.subpaths(atPath: path), entries)
        }
        catch {
            XCTFail()
        }
        
        do {
            // Check a bad path fails
            XCTAssertNil(fm.subpaths(atPath: "/..."))

            let _ = try fm.subpathsOfDirectory(atPath: "/...")
            XCTFail()
        }
        catch {
            // Invalid directories should fail.
        }
        
        do {
            try fm.removeItem(atPath: path)
        } catch {
            XCTFail("Failed to clean up files")
        }
    }

    private func directoryExists(atPath path: String) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }

    func test_copyItemAtPathToPath() {
        let fm = FileManager.default
        let srcPath = NSTemporaryDirectory() + "testdir\(NSUUID().uuidString)"
        let destPath = NSTemporaryDirectory() + "testdir\(NSUUID().uuidString)"

        func cleanup() {
            try? fm.removeItem(atPath: srcPath)
            try? fm.removeItem(atPath: destPath)
        }

        func createDirectory(atPath path: String) {
            do {
                try fm.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch {
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
        } catch {
            XCTFail("Failed to copy file: \(error)")
        }

        cleanup()
        createDirectory(atPath: srcPath)
        createDirectory(atPath: "\(srcPath)/tempdir")
        createDirectory(atPath: "\(srcPath)/tempdir/subdir")
        createDirectory(atPath: "\(srcPath)/tempdir/subdir/otherdir")
        createDirectory(atPath: "\(srcPath)/tempdir/subdir/otherdir/extradir")
        createFile(atPath: "\(srcPath)/tempdir/tempfile")
        createFile(atPath: "\(srcPath)/tempdir/tempfile2")
        createFile(atPath: "\(srcPath)/tempdir/subdir/otherdir/extradir/tempfile2")

        do {
            try fm.copyItem(atPath: srcPath, toPath: destPath)
        } catch {
            XCTFail("Unable to copy directory: \(error)")
        }
        XCTAssertTrue(directoryExists(atPath: destPath))
        XCTAssertTrue(directoryExists(atPath: "\(destPath)/tempdir"))
        XCTAssertTrue(fm.fileExists(atPath: "\(destPath)/tempdir/tempfile"))
        XCTAssertTrue(fm.fileExists(atPath: "\(destPath)/tempdir/tempfile2"))
        XCTAssertTrue(directoryExists(atPath: "\(destPath)/tempdir/subdir/otherdir/extradir"))
        XCTAssertTrue(fm.fileExists(atPath: "\(destPath)/tempdir/subdir/otherdir/extradir/tempfile2"))

        if (false == directoryExists(atPath: destPath)) {
            return
        }
        do {
            try fm.copyItem(atPath: srcPath, toPath: destPath)
            XCTFail("Copy overwrites a file/folder that already exists")
        } catch {
            // ignore
        }

        // Test copying a symlink
        let srcLink = srcPath + "/testlink"
        let destLink = destPath + "/testlink"
        do {
#if os(Windows)
            fm.createFile(atPath: srcPath.appendingPathComponent("linkdest"), contents: Data(), attributes: nil)
#endif
            try fm.createSymbolicLink(atPath: srcLink, withDestinationPath: "linkdest")
            try fm.copyItem(atPath: srcLink, toPath: destLink)
            XCTAssertEqual(try fm.destinationOfSymbolicLink(atPath: destLink), "linkdest")
        } catch {
            XCTFail("\(error)")
        }

        do {
            try fm.copyItem(atPath: srcLink, toPath: destLink)
            XCTFail("Creating link where one already exists")
        } catch {
            // ignore
        }
    }

    func test_linkItemAtPathToPath() {
        let fm = FileManager.default
        let basePath = NSTemporaryDirectory() + "linkItemAtPathToPath/"
        let srcPath = basePath + "testdir\(NSUUID().uuidString)"
        let destPath = basePath + "testdir\(NSUUID().uuidString)"
        defer { try? fm.removeItem(atPath: basePath) }

        func getFileInfo(atPath path: String, _ body: (String, Bool, UInt64, UInt64) -> ()) {
            guard let enumerator = fm.enumerator(atPath: path) else {
                XCTFail("Cant enumerate \(path)")
                return
            }
            while let item = enumerator.nextObject() as? String {
                let fname = "\(path)/\(item)"
                do {
                    let attrs = try fm.attributesOfItem(atPath: fname)
                    let inode = (attrs[.systemFileNumber] as? NSNumber)?.uint64Value
                    let linkCount = (attrs[.referenceCount] as? NSNumber)?.uint64Value
                    let ftype = attrs[.type] as? FileAttributeType

                    if inode == nil || linkCount == nil || ftype == nil {
                        XCTFail("Unable to get attributes of \(fname)")
                        return
                    }
                    let isDir = (ftype == .typeDirectory)
                    body(item, isDir, inode!, linkCount!)
                } catch {
                    XCTFail("Unable to get attributes of \(fname): \(error)")
                    return
                }
            }
        }

        try? fm.removeItem(atPath: basePath)
        XCTAssertNotNil(try? fm.createDirectory(atPath: "\(srcPath)/tempdir/subdir/otherdir/extradir", withIntermediateDirectories: true, attributes: nil))
        XCTAssertTrue(fm.createFile(atPath: "\(srcPath)/tempdir/tempfile", contents: Data(), attributes: nil))
        XCTAssertTrue(fm.createFile(atPath: "\(srcPath)/tempdir/tempfile2", contents: Data(), attributes: nil))
        XCTAssertTrue(fm.createFile(atPath: "\(srcPath)/tempdir/subdir/otherdir/extradir/tempfile2", contents: Data(), attributes: nil))

        var fileInfos: [String: (Bool, UInt64, UInt64)] = [:]
        getFileInfo(atPath: srcPath, { name, isDir, inode, linkCount in
            fileInfos[name] = (isDir, inode, linkCount)
        })
        XCTAssertEqual(fileInfos.count, 7)
        XCTAssertNotNil(try? fm.linkItem(atPath: srcPath, toPath: destPath), "Unable to link directory")

        getFileInfo(atPath: destPath, { name, isDir, inode, linkCount in
            guard let srcFileInfo = fileInfos.removeValue(forKey: name) else {
                XCTFail("Cant find \(name) in \(destPath)")
                return
            }
            let (srcIsDir, srcInode, srcLinkCount) = srcFileInfo
            XCTAssertEqual(srcIsDir, isDir, "Directory/File type mismatch")
            if isDir {
                XCTAssertEqual(srcLinkCount, linkCount)
            } else {
                XCTAssertEqual(srcInode, inode)
                XCTAssertEqual(srcLinkCount + 1, linkCount)
            }
        })

        XCTAssertEqual(fileInfos.count, 0)
        // linkItem should fail a 2nd time
        XCTAssertNil(try? fm.linkItem(atPath: srcPath, toPath: destPath), "Copy overwrites a file/folder that already exists")

        // Test 'linking' a symlink, which actually does a copy
        let srcLink = srcPath + "/testlink"
        let destLink = destPath + "/testlink"
        do {
#if os(Windows)
            fm.createFile(atPath: srcPath.appendingPathComponent("linkdest"), contents: Data(), attributes: nil)
#endif
            try fm.createSymbolicLink(atPath: srcLink, withDestinationPath: "linkdest")
            try fm.linkItem(atPath: srcLink, toPath: destLink)
            XCTAssertEqual(try fm.destinationOfSymbolicLink(atPath: destLink), "linkdest")
        } catch {
            XCTFail("\(error)")
        }
        XCTAssertNil(try? fm.linkItem(atPath: srcLink, toPath: destLink), "Creating link where one already exists")
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

    func test_mountedVolumeURLs() {
        guard let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys:[], options: []) else {
            XCTFail("mountedVolumeURLs returned nil")
            return
        }
        XCTAssertNotEqual(0, volumes.count)
#if os(Windows)
        let url = URL(fileURLWithPath: String(NSTemporaryDirectory().prefix(3)))
        XCTAssertTrue(volumes.contains(url))
#else
        XCTAssertTrue(volumes.contains(URL(fileURLWithPath: "/")))
#endif
#if os(macOS)
        // On macOS, .skipHiddenVolumes should hide 'nobrowse' volumes of which there should be at least one
        guard let visibleVolumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [], options: [.skipHiddenVolumes]) else {
            XCTFail("mountedVolumeURLs returned nil")
            return
        }
        XCTAssertTrue(visibleVolumes.count > 0)
        XCTAssertTrue(visibleVolumes.count < volumes.count)
#endif
    }

    func test_contentsEqual() {
        let fm = FileManager.default
        let tmpParentDirURL = URL(fileURLWithPath: NSTemporaryDirectory() + "test_contentsEqualdir", isDirectory: true)
        let testDir1 = tmpParentDirURL.appendingPathComponent("testDir1")
        let testDir2 = tmpParentDirURL.appendingPathComponent("testDir2")
        let testDir3 = testDir1.appendingPathComponent("subDir/anotherDir/extraDir/lastDir")

        defer { try? fm.removeItem(atPath: tmpParentDirURL.path) }

        func testFileURL(_ name: String, _ ext: String) -> URL? {
            guard let url = testBundle().url(forResource: name, withExtension: ext) else {
                XCTFail("Cant open \(name).\(ext)")
                return nil
            }
            return url
        }

        guard let testFile1URL = testFileURL("NSStringTestData", "txt") else { return }
        guard let testFile2URL = testFileURL("NSURLTestData", "plist")  else { return }
        guard let testFile3URL = testFileURL("NSString-UTF32-BE-data", "txt") else { return }
        guard let testFile4URL = testFileURL("NSString-UTF32-LE-data", "txt") else { return }
        let symlink = testDir1.appendingPathComponent("testlink").path

        // Setup test directories
        do {
            // Clean out and leftover test data
            try? fm.removeItem(atPath: tmpParentDirURL.path)

            // testDir1
            try fm.createDirectory(atPath: testDir1.path, withIntermediateDirectories: true)
#if !os(Windows)
            try fm.createSymbolicLink(atPath: testDir1.appendingPathComponent("null1").path, withDestinationPath: "/dev/null")
            try fm.createSymbolicLink(atPath: testDir1.appendingPathComponent("zero1").path, withDestinationPath: "/dev/zero")
#endif
            try "foo".write(toFile: testDir1.appendingPathComponent("foo.txt").path, atomically: false, encoding: .ascii)
            try fm.createSymbolicLink(atPath: testDir1.appendingPathComponent("foo1").path, withDestinationPath: "foo.txt")
            try fm.createSymbolicLink(atPath: testDir1.appendingPathComponent("bar2").path, withDestinationPath: "foo1")
            let unreadable = testDir1.appendingPathComponent("unreadable_file").path
            try "unreadable".write(toFile: unreadable, atomically: false, encoding: .ascii)
            try fm.setAttributes([.posixPermissions: NSNumber(value: 0)], ofItemAtPath: unreadable)
            try Data().write(to: testDir1.appendingPathComponent("empty_file"))
            try fm.createSymbolicLink(atPath: symlink, withDestinationPath: testFile1URL.path)

            try fm.createSymbolicLink(atPath: testDir1.appendingPathComponent("thisDir").path, withDestinationPath: ".")
            try fm.createSymbolicLink(atPath: testDir1.appendingPathComponent("parentDir").path, withDestinationPath: "..")
            try fm.createSymbolicLink(atPath: testDir1.appendingPathComponent("rootDir").path, withDestinationPath: "/")

            // testDir2
            try fm.createDirectory(atPath: testDir2.path, withIntermediateDirectories: true)
#if os(Windows)
            try "foo".write(toFile: testDir2.appendingPathComponent("foo1").path, atomically: false, encoding: .ascii)
            try fm.createDirectory(atPath: testDir2.appendingPathComponent("../testDir1").path, withIntermediateDirectories: true)
            try "foo".write(toFile: testDir2.appendingPathComponent("../testDir1/foo.txt").path, atomically: false, encoding: .ascii)
#endif
            try fm.createSymbolicLink(atPath: testDir2.appendingPathComponent("bar2").path, withDestinationPath: "foo1")
            try fm.createSymbolicLink(atPath: testDir2.appendingPathComponent("foo2").path, withDestinationPath: "../testDir1/foo.txt")

            // testDir3
            try fm.createDirectory(atPath: testDir3.path, withIntermediateDirectories: true)
#if os(Windows)
            try fm.createDirectory(atPath: testDir3.appendingPathComponent("../testDir1").path, withIntermediateDirectories: true)
            try "foo".write(toFile: testDir3.appendingPathComponent("../testDir1/foo.txt").path, atomically: false, encoding: .ascii)
            try "foo".write(toFile: testDir3.appendingPathComponent("foo1").path, atomically: false, encoding: .ascii)
#endif
            try fm.createSymbolicLink(atPath: testDir3.appendingPathComponent("bar2").path, withDestinationPath: "foo1")
            try fm.createSymbolicLink(atPath: testDir3.appendingPathComponent("foo2").path, withDestinationPath: "../testDir1/foo.txt")
        } catch {
            XCTFail(String(describing: error))
        }

#if os(Windows)
        XCTAssertFalse(fm.contentsEqual(atPath: "NUL", andPath: "NUL"))
#else
        XCTAssertTrue(fm.contentsEqual(atPath: "/dev/null", andPath: "/dev/null"))
        XCTAssertTrue(fm.contentsEqual(atPath: "/dev/urandom", andPath: "/dev/urandom"))
        XCTAssertFalse(fm.contentsEqual(atPath: "/dev/null", andPath: "/dev/zero"))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.appendingPathComponent("null1").path, andPath: "/dev/null"))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.appendingPathComponent("zero").path, andPath: "/dev/zero"))
#endif
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.appendingPathComponent("foo.txt").path, andPath: testDir1.appendingPathComponent("foo1").path))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.appendingPathComponent("foo.txt").path, andPath: testDir1.appendingPathComponent("foo2").path))
        XCTAssertTrue(fm.contentsEqual(atPath: testDir1.appendingPathComponent("bar2").path, andPath: testDir2.appendingPathComponent("bar2").path))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.appendingPathComponent("foo1").path, andPath: testDir2.appendingPathComponent("foo2").path))
        XCTAssertFalse(fm.contentsEqual(atPath: "/non_existent_file", andPath: "/non_existent_file"))

        let emptyFile = testDir1.appendingPathComponent("empty_file")
#if os(Windows)
        XCTAssertFalse(fm.contentsEqual(atPath: emptyFile.path, andPath: "NUL"))
#else
        XCTAssertFalse(fm.contentsEqual(atPath: emptyFile.path, andPath: "/dev/null"))
#endif
        XCTAssertFalse(fm.contentsEqual(atPath: emptyFile.path, andPath: testDir1.appendingPathComponent("null1").path))
#if os(Windows)
        // A file cannot be unreadable on Windows
        XCTAssertTrue(fm.contentsEqual(atPath: emptyFile.path, andPath: testDir1.appendingPathComponent("unreadable_file").path))
#else
        XCTAssertFalse(fm.contentsEqual(atPath: emptyFile.path, andPath: testDir1.appendingPathComponent("unreadable_file").path))
#endif

        XCTAssertTrue(fm.contentsEqual(atPath: testFile1URL.path, andPath: testFile1URL.path))
        XCTAssertFalse(fm.contentsEqual(atPath: testFile1URL.path, andPath: testFile2URL.path))
        XCTAssertFalse(fm.contentsEqual(atPath: testFile3URL.path, andPath: testFile4URL.path))
        XCTAssertFalse(fm.contentsEqual(atPath: symlink, andPath: testFile1URL.path))

        XCTAssertTrue(fm.contentsEqual(atPath: testDir1.path, andPath: testDir1.path))
        XCTAssertTrue(fm.contentsEqual(atPath: testDir2.path, andPath: testDir3.path))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.path, andPath: testDir2.path))

        // Copy everything in testDir1 to testDir2 to make them equal
        do {
            for entry in try fm.subpathsOfDirectory(atPath: testDir1.path) {
                // Skip entries that already exist
                if entry == "bar2" || entry == "unreadable_file" {
                    continue
                }
                let srcPath = testDir1.appendingPathComponent(entry).path
                let dstPath = testDir2.appendingPathComponent(entry).path
                if let attrs = try? fm.attributesOfItem(atPath: srcPath),
                    let fileType = attrs[.type] as? FileAttributeType, fileType == .typeDirectory {
                    try fm.createDirectory(atPath: dstPath, withIntermediateDirectories: false, attributes: nil)
                } else {
                    try fm.copyItem(atPath: srcPath, toPath: dstPath)
                }
            }
        } catch {
            XCTFail("Failed to copy \(testDir1.path) to \(testDir2.path), \(error)")
            return
        }
        // This will still fail due to unreadable files and a file in testDir2 not in testDir1
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.path, andPath: testDir2.path))
        do {
            try fm.copyItem(atPath: testDir2.appendingPathComponent("foo2").path, toPath: testDir1.appendingPathComponent("foo2").path)
            try fm.removeItem(atPath: testDir1.appendingPathComponent("unreadable_file").path)
        } catch {
            XCTFail(String(describing: error))
            return
        }
        XCTAssertTrue(fm.contentsEqual(atPath: testDir1.path, andPath: testDir2.path))

        let dataFile1 = testDir1.appendingPathComponent("dataFile")
        let dataFile2 = testDir2.appendingPathComponent("dataFile")
        do {
            try Data(count: 100_000).write(to: dataFile1)
            try fm.copyItem(atPath: dataFile1.path, toPath: dataFile2.path)
        } catch {
            XCTFail("Could not create test data files: \(error)")
            return
        }
        XCTAssertTrue(fm.contentsEqual(atPath: dataFile1.path, andPath: dataFile2.path))
        XCTAssertTrue(fm.contentsEqual(atPath: testDir1.path, andPath: testDir2.path))
        var data = Data(count: 100_000)
        data[99_999] = 1
        try? data.write(to: dataFile1)
        XCTAssertFalse(fm.contentsEqual(atPath: dataFile1.path, andPath: dataFile2.path))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.path, andPath: testDir2.path))
    }

    func test_copyItemsPermissions() throws {
        let fm = FileManager.default
        let tmpDir = fm.temporaryDirectory.appendingPathComponent("test_copyItemsPermissions")
        try fm.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(atPath: tmpDir.path) }

        let srcFile = tmpDir.appendingPathComponent("file1.txt")
        let destFile = tmpDir.appendingPathComponent("file2.txt")

        let source = "This is the source file"
        try? fm.removeItem(at: srcFile)
        try source.write(toFile: srcFile.path, atomically: false, encoding: .utf8)

        func testCopy() throws {
            try? fm.removeItem(at: destFile)
            try fm.copyItem(at: srcFile, to: destFile)
            let copy = try String(contentsOf: destFile)
            XCTAssertEqual(source, copy)
            if let srcPerms = (try fm.attributesOfItem(atPath: srcFile.path)[.posixPermissions] as? NSNumber)?.intValue,
                let destPerms = (try fm.attributesOfItem(atPath: destFile.path)[.posixPermissions] as? NSNumber)?.intValue {
                XCTAssertEqual(srcPerms, destPerms)
            } else {
                XCTFail("Cant get file permissions")
            }
        }

        try testCopy()

        try fm.setAttributes([ .posixPermissions: 0o417], ofItemAtPath: srcFile.path)
        try testCopy()

        try fm.setAttributes([ .posixPermissions: 0o400], ofItemAtPath: srcFile.path)
        try testCopy()

        try fm.setAttributes([ .posixPermissions: 0o700], ofItemAtPath: srcFile.path)
        try testCopy()

        try fm.setAttributes([ .posixPermissions: 0o707], ofItemAtPath: srcFile.path)
        try testCopy()

        try fm.setAttributes([ .posixPermissions: 0o411], ofItemAtPath: srcFile.path)
        try testCopy()
    }
    
#if !DEPLOYMENT_RUNTIME_OBJC && !os(Android) // XDG tests require swift-corelibs-foundation
    
    #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT // These are white box tests for the internals of XDG parsing:
    func test_xdgStopgapsCoverAllConstants() {
        let stopgaps = _XDGUserDirectory.stopgapDefaultDirectoryURLs
        for directory in _XDGUserDirectory.allDirectories {
            XCTAssertNotNil(stopgaps[directory])
        }
    }
    
    func test_parseXDGConfiguration() {
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        
        let assertConfigurationProduces = { (configuration: String, paths: [_XDGUserDirectory: String]) in
            XCTAssertEqual(_XDGUserDirectory.userDirectories(fromConfiguration: configuration).mapValues({ $0.absoluteURL.path }),
                           paths.mapValues({ URL(fileURLWithPath: $0, isDirectory: true, relativeTo: home).absoluteURL.path }))
        }
        
        assertConfigurationProduces("", [:])
        
        // Test partial configuration and paths relative to home.
        assertConfigurationProduces(
"""
DESKTOP=/xdg_test/Desktop
MUSIC=/xdg_test/Music
PICTURES=Pictures
""", [ .desktop: "/xdg_test/Desktop",
       .music: "/xdg_test/Music",
       .pictures: "Pictures" ])

        // Test full configuration with XDG_…_DIR syntax, duplicate keys and varying indentation
        // 'XDG_MUSIC_DIR' is duplicated, below.
        assertConfigurationProduces(
"""
	XDG_MUSIC_DIR=ShouldNotBeUsedUseTheOneBelowInstead

	XDG_DESKTOP_DIR=Desktop
		XDG_DOWNLOAD_DIR=Download
	XDG_PUBLICSHARE_DIR=Public
XDG_DOCUMENTS_DIR=Documents
	XDG_MUSIC_DIR=Music
XDG_PICTURES_DIR=Pictures
	XDG_VIDEOS_DIR=Videos
""", [ .desktop: "Desktop",
       .download: "Download",
       .publicShare: "Public",
       .documents: "Documents",
       .music: "Music",
       .pictures: "Pictures",
       .videos: "Videos" ])
        
        // Same, without XDG…DIR.
        assertConfigurationProduces(
"""
    MUSIC=ShouldNotBeUsedUseTheOneBelowInstead

    DESKTOP=Desktop
        DOWNLOAD=Download
    PUBLICSHARE=Public
DOCUMENTS=Documents
    MUSIC=Music
PICTURES=Pictures
    VIDEOS=Videos
""", [ .desktop: "Desktop",
       .download: "Download",
       .publicShare: "Public",
       .documents: "Documents",
       .music: "Music",
       .pictures: "Pictures",
       .videos: "Videos" ])
    
        assertConfigurationProduces(
"""
    DESKTOP=/home/Desktop
This configuration file has an invalid syntax.
""", [:])
    }
    
    func test_xdgURLSelection() {
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        
        let configuration = _XDGUserDirectory.userDirectories(fromConfiguration:
"""
DESKTOP=UserDesktop
"""
        )
        
        let osDefaults = _XDGUserDirectory.userDirectories(fromConfiguration:
"""
DESKTOP=SystemDesktop
PUBLICSHARE=SystemPublicShare
"""
        )
        
        let stopgaps = _XDGUserDirectory.userDirectories(fromConfiguration:
"""
DESKTOP=StopgapDesktop
DOWNLOAD=StopgapDownload
PUBLICSHARE=StopgapPublicShare
DOCUMENTS=StopgapDocuments
MUSIC=StopgapMusic
PICTURES=StopgapPictures
VIDEOS=StopgapVideos
"""
        )
        
        let assertSameAbsolutePath = { (lhs: URL, rhs: URL) in
            XCTAssertEqual(lhs.absoluteURL.path, rhs.absoluteURL.path)
        }
        
        assertSameAbsolutePath(_XDGUserDirectory.desktop.url(userConfiguration: configuration, osDefaultConfiguration: osDefaults, stopgaps: stopgaps), home.appendingPathComponent("UserDesktop"))
        assertSameAbsolutePath(_XDGUserDirectory.publicShare.url(userConfiguration: configuration, osDefaultConfiguration: osDefaults, stopgaps: stopgaps), home.appendingPathComponent("SystemPublicShare"))
        assertSameAbsolutePath(_XDGUserDirectory.music.url(userConfiguration: configuration, osDefaultConfiguration: osDefaults, stopgaps: stopgaps), home.appendingPathComponent("StopgapMusic"))
    }
    #endif // NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    
    // This test below is a black box test, and does not require @testable import.

    #if !os(Android)
    func printPathByRunningHelper(withConfiguration config: String, method: String, identifier: String) throws -> String {
        let uuid = UUID().uuidString
        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("org.swift.Foundation.XDGTestHelper").appendingPathComponent(uuid)
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        
        let configFilePath = path.appendingPathComponent("user-dirs.dirs")
        try config.write(to: configFilePath, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: path)
        }
        
        var environment = [ "XDG_CONFIG_HOME": path.path,
                            "_NSFileManagerUseXDGPathsForDirectoryDomains": "YES" ]
        
        // Copy all LD_* and DYLD_* variables over, in case we're running with altered paths (e.g. from ninja test on Linux)
        for entry in ProcessInfo.processInfo.environment.lazy.filter({ $0.key.hasPrefix("DYLD_") || $0.key.hasPrefix("LD_") }) {
            environment[entry.key] = entry.value
        }
        
        let helper = xdgTestHelperURL()
        let (stdout, _) = try runTask([ helper.path, "--nspathfor", method, identifier ],
                                      environment: environment)
        
        return stdout.trimmingCharacters(in: CharacterSet.newlines)
    }
    
    func assertFetchingPath(withConfiguration config: String, identifier: String, yields path: String) {
        for method in [ "NSSearchPath", "FileManagerDotURLFor", "FileManagerDotURLsFor" ] {
            do {
                let found = try printPathByRunningHelper(withConfiguration: config, method: method, identifier: identifier)
                XCTAssertEqual(found, path)
            } catch let error {
                XCTFail("Failed with method \(method), configuration \(config), identifier \(identifier), equal to \(path), error \(error)")
            }
        }
    }
    
    func test_fetchXDGPathsFromHelper() {
        let prefix = NSHomeDirectory() + "/_Foundation_Test_"
        
        let configuration = """
        DESKTOP=\(prefix)/Desktop
        DOWNLOAD=\(prefix)/Download
        PUBLICSHARE=\(prefix)/PublicShare
        DOCUMENTS=\(prefix)/Documents
        MUSIC=\(prefix)/Music
        PICTURES=\(prefix)/Pictures
        VIDEOS=\(prefix)/Videos
        """
        
        assertFetchingPath(withConfiguration: configuration, identifier: "desktop", yields: "\(prefix)/Desktop")
        assertFetchingPath(withConfiguration: configuration, identifier: "download", yields: "\(prefix)/Download")
        assertFetchingPath(withConfiguration: configuration, identifier: "publicShare", yields: "\(prefix)/PublicShare")
        assertFetchingPath(withConfiguration: configuration, identifier: "documents", yields: "\(prefix)/Documents")
        assertFetchingPath(withConfiguration: configuration, identifier: "music", yields: "\(prefix)/Music")
        assertFetchingPath(withConfiguration: configuration, identifier: "pictures", yields: "\(prefix)/Pictures")
        assertFetchingPath(withConfiguration: configuration, identifier: "videos", yields: "\(prefix)/Videos")
    }
    #endif // !os(Android)
#endif // !DEPLOYMENT_RUNTIME_OBJC

    func test_emptyFilename() {

        // Some of these tests will throw an NSException on Darwin which would be normally be
        // modelled by a fatalError() or other hard failure, however since most of these functions
        // are thorwable, an NSError is thrown instead which is more useful.
        let fm = FileManager.default

        XCTAssertNil(fm.homeDirectory(forUser: ""))
        XCTAssertNil(NSHomeDirectoryForUser(""))

        XCTAssertThrowsError(try fm.contentsOfDirectory(atPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }

        XCTAssertNil(fm.enumerator(atPath: ""))
        XCTAssertNil(fm.subpaths(atPath: ""))
        XCTAssertThrowsError(try fm.subpathsOfDirectory(atPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }

        XCTAssertThrowsError(try fm.createDirectory(atPath: "", withIntermediateDirectories: true)) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertFalse(fm.createFile(atPath: "", contents: Data()))
        XCTAssertThrowsError(try fm.removeItem(atPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }

        XCTAssertThrowsError(try fm.copyItem(atPath: "", toPath: "/tmp/t"))  {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertThrowsError(try fm.copyItem(atPath: "", toPath: ""))  {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertThrowsError(try fm.copyItem(atPath: "/tmp/t", toPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadNoSuchFile)
        }

        XCTAssertThrowsError(try fm.moveItem(atPath: "", toPath: "/tmp/t")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertThrowsError(try fm.moveItem(atPath: "", toPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertThrowsError(try fm.moveItem(atPath: "/tmp/t", toPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }

        XCTAssertThrowsError(try fm.linkItem(atPath: "", toPath: "/tmp/t")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertThrowsError(try fm.linkItem(atPath: "", toPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertThrowsError(try fm.linkItem(atPath: "/tmp/t", toPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadNoSuchFile)
        }

        XCTAssertThrowsError(try fm.createSymbolicLink(atPath: "", withDestinationPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertThrowsError(try fm.createSymbolicLink(atPath: "", withDestinationPath: "/tmp/t")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertThrowsError(try fm.createSymbolicLink(atPath: "/tmp/t", withDestinationPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }

        XCTAssertThrowsError(try fm.destinationOfSymbolicLink(atPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertFalse(fm.fileExists(atPath: ""))
        XCTAssertFalse(fm.fileExists(atPath: "", isDirectory: nil))
        XCTAssertFalse(fm.isReadableFile(atPath: ""))
        XCTAssertFalse(fm.isWritableFile(atPath: ""))
        XCTAssertFalse(fm.isExecutableFile(atPath: ""))
        XCTAssertTrue(fm.isDeletableFile(atPath: ""))

        XCTAssertThrowsError(try fm.attributesOfItem(atPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertThrowsError(try fm.attributesOfFileSystem(forPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }
        XCTAssertThrowsError(try fm.setAttributes([:], ofItemAtPath: "")) {
            let code = CocoaError.Code(rawValue: ($0 as? NSError)!.code)
            XCTAssertEqual(code, .fileReadInvalidFileName)
        }

        XCTAssertNil(fm.contents(atPath: ""))
        XCTAssertFalse(fm.contentsEqual(atPath: "", andPath: ""))
        XCTAssertFalse(fm.contentsEqual(atPath: "/tmp/t", andPath: ""))
        XCTAssertFalse(fm.contentsEqual(atPath: "", andPath: "/tmp/t"))

        //_ = fm.fileSystemRepresentation(withPath: "")  // NSException
        XCTAssertEqual(fm.string(withFileSystemRepresentation: UnsafePointer(bitPattern: 1)!, length: 0), "")

        XCTAssertFalse(fm.changeCurrentDirectoryPath(""))
        XCTAssertNotEqual(fm.currentDirectoryPath, "")

        // Not Implemented - XCTAssertNil(fm.componentsToDisplay(forPath: ""))
        // Not Implemented - XCTAssertEqual(fm.displayName(atPath: ""), "")
    }
    
    func test_getRelationship() throws {
        /* a/
           a/b
           a/bb
           c -> symlink to a/b
           d */
        
        let a        = writableTestDirectoryURL.appendingPathComponent("a")
        let a_b      = a.appendingPathComponent("b")
        let a_bb     = a.appendingPathComponent("bb")
        let c        = writableTestDirectoryURL.appendingPathComponent("c")
        let a_b_d    = a_b.appendingPathComponent("d")
        
        let fm = FileManager.default
        try fm.createDirectory(at: a, withIntermediateDirectories: true)
        try fm.createDirectory(at: a_b, withIntermediateDirectories: true)
        try Data().write(to: a_bb)
        try Data().write(to: c)
        try fm.createSymbolicLink(at: a_b_d, withDestinationURL: a)
        
        var relationship: FileManager.URLRelationship = .other
        
        try fm.getRelationship(&relationship, ofDirectoryAt: writableTestDirectoryURL, toItemAt: a)
        XCTAssertEqual(relationship, .contains)
        
        try fm.getRelationship(&relationship, ofDirectoryAt: a, toItemAt: a_b)
        XCTAssertEqual(relationship, .contains)
        
        // The path of one is a prefix to the other, but lacks the directory separator.
        try fm.getRelationship(&relationship, ofDirectoryAt: a_b, toItemAt: a_bb)
        XCTAssertEqual(relationship, .other)
        
        try fm.getRelationship(&relationship, ofDirectoryAt: a_b, toItemAt: c)
        XCTAssertEqual(relationship, .other)
        
        try fm.getRelationship(&relationship, ofDirectoryAt: a_b_d, toItemAt: a)
        XCTAssertEqual(relationship, .same)
    }
    
    func test_displayNames() throws {
        /* a/
           a/Test.localized (with a ./.localized/ subdirectory and strings file);
           a/Test.localized/b
        */
        
        let a = writableTestDirectoryURL.appendingPathComponent("a")
        let a_Test = a.appendingPathComponent("Test.localized")
        let a_Test_dotLocalized = a_Test.appendingPathComponent(".localized")
        let a_Test_dotLocalized_enStrings = a_Test_dotLocalized.appendingPathComponent("en.strings")
        let a_Test_dotLocalized_itStrings = a_Test_dotLocalized.appendingPathComponent("it.strings")
        let a_Test_b = a_Test.appendingPathComponent("b")
        
        let fm = FileManager.default
        try fm.createDirectory(at: a, withIntermediateDirectories: true)
        try fm.createDirectory(at: a_Test, withIntermediateDirectories: true)
        try fm.createDirectory(at: a_Test_dotLocalized, withIntermediateDirectories: true)
        try Data("\"Test\" = \"Test\";".utf8).write(to: a_Test_dotLocalized_enStrings)
        try Data("\"Test\" = \"Prova\";".utf8).write(to: a_Test_dotLocalized_itStrings)
        try fm.createDirectory(at: a_Test_b, withIntermediateDirectories: true)

        XCTAssertEqual(fm.displayName(atPath: a.path), "a")
        
        #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
        fm._overridingDisplayNameLanguages(with: ["en", "es", "it"]) {
            XCTAssertEqual(fm.displayName(atPath: a_Test.path), "Test")
        }
        fm._overridingDisplayNameLanguages(with: ["it", "en", "es"]) {
            XCTAssertEqual(fm.displayName(atPath: a_Test.path), "Prova")
        }
        fm._overridingDisplayNameLanguages(with: ["es", "it", "en"]) {
            XCTAssertEqual(fm.displayName(atPath: a_Test.path), "Prova")
        }
        #endif
        
        do {
            let components = try XCTUnwrap(fm.componentsToDisplay(forPath: a.path))
            XCTAssertGreaterThanOrEqual(components.count, 2)
            XCTAssertEqual(components.last, "a")
        }
        
        do {
            #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
            let components = try fm._overridingDisplayNameLanguages(with: ["it"]) {
                return try XCTUnwrap(fm.componentsToDisplay(forPath: a_Test.path))
            }
            #else
            let components = try XCTUnwrap(fm.componentsToDisplay(forPath: a_Test.path))
            #endif
            
            XCTAssertGreaterThanOrEqual(components.count, 3)
            if components.count >= 3 {
                XCTAssertEqual(components[components.count - 2], "a")
            }
            
            #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
            XCTAssertEqual(components.last, "Prova")
            #endif
        }
        
        do {
            #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
            let components = try fm._overridingDisplayNameLanguages(with: ["en"]) {
                return try XCTUnwrap(fm.componentsToDisplay(forPath: a_Test_b.path))
            }
            #else
            let components = try XCTUnwrap(fm.componentsToDisplay(forPath: a_Test_b.path))
            #endif
            
            XCTAssertGreaterThanOrEqual(components.count, 4)
            if components.count >= 4 {
                XCTAssertEqual(components[components.count - 3], "a")
                
                #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
                XCTAssertEqual(components[components.count - 2], "Test")
                #endif
            }
            
            XCTAssertEqual(components.last, "b")
        }
        
    }
    
    func test_getItemReplacementDirectory() throws {
        try FileManager.default.createDirectory(at: writableTestDirectoryURL, withIntermediateDirectories: true)
        let a = writableTestDirectoryURL.appendingPathComponent("a")
        try Data().write(to: a)
        
        let whereAt = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: a, create: false)
        // Either this is in the temporary directory, or this is on the same filesystem as 'a' (at writableTestDirectoryURL).
        if whereAt.deletingLastPathComponent() == writableTestDirectoryURL {
            XCTAssertEqual(whereAt.deletingLastPathComponent(), writableTestDirectoryURL)
        } else {
            var relationship: FileManager.URLRelationship = .other
            try FileManager.default.getRelationship(&relationship, ofDirectoryAt: URL(fileURLWithPath: NSTemporaryDirectory()), toItemAt: whereAt.deletingLastPathComponent())
            XCTAssertEqual(relationship, .contains)
        }
        
        // To avoid races, Darwin always creates the directory even if create: false. Check this is the case.
        XCTAssertNotNil(try? FileManager.default.attributesOfItem(atPath: whereAt.path))
        try? FileManager.default.removeItem(at: whereAt)
    }
    
    func test_replacement() throws {
        let fm = FileManager.default
        let a = writableTestDirectoryURL.appendingPathComponent("a")

        let initialData = Data("INITIAL".utf8)
        let finalData = Data("FINAL".utf8)
        var temporaryDirectory: URL!
        var b: URL!

        let initialFileName = "INITIAL"
        let finalFileName = "FINAL"
        
        func setUpReplacement(aIsDirectory: Bool, bIsDirectory: Bool) throws {
            try fm.createDirectory(at: writableTestDirectoryURL, withIntermediateDirectories: true)
            if aIsDirectory {
                try fm.createDirectory(at: a, withIntermediateDirectories: true)
                try Data().write(to: a.appendingPathComponent(initialFileName))
            } else {
                try initialData.write(to: a)
            }
            
            temporaryDirectory = try fm.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: a, create: true)
            
            if bIsDirectory {
                b = temporaryDirectory.appendingPathComponent("b")
                try fm.createDirectory(at: b, withIntermediateDirectories: true)
                try Data().write(to: b.appendingPathComponent(finalFileName))
            } else {
                b = temporaryDirectory.appendingPathComponent("b")
                try finalData.write(to: b)
            }
        }
        
        func tearDownReplacement() throws {
            try? fm.removeItem(at: a)
            try? fm.removeItem(at: writableTestDirectoryURL.appendingPathComponent("c"))
            try? fm.removeItem(at: temporaryDirectory)
        }
        
        var stderr = FileHandle.standardError
        
        func testReplaceMethod(invokedBy replace: (URL, URL, String?, FileManager.ItemReplacementOptions) throws -> URL?) throws {
            func runSingleTest(aIsDirectory: Bool, bIsDirectory: Bool, options: FileManager.ItemReplacementOptions = []) throws {
                print("note: Testing with: a is directory? \(aIsDirectory), b is directory? \(bIsDirectory), using new metadata only? \(options.contains(.usingNewMetadataOnly)), without deleting backup item? \(options.contains(.withoutDeletingBackupItem))", to: &stderr)
                try setUpReplacement(aIsDirectory: aIsDirectory, bIsDirectory: bIsDirectory)
                
                let initialAttributes = options.contains(.usingNewMetadataOnly) ? try fm.attributesOfItem(atPath: b.path) : try fm.attributesOfItem(atPath: a.path)
                
                // Do the thing.
                let result = try replace(a, b, "c", options)
                
                let c = writableTestDirectoryURL.appendingPathComponent("c")
                let cAttributes = try? fm.attributesOfItem(atPath: c.path)
                if options.contains(.withoutDeletingBackupItem) {
                    XCTAssertNotNil(cAttributes)
                    
                    if aIsDirectory {
                        XCTAssertNotNil(try? fm.attributesOfItem(atPath: c.appendingPathComponent(initialFileName).path))
                        XCTAssertNil(try? fm.attributesOfItem(atPath: c.appendingPathComponent(finalFileName).path))
                    } else {
                        XCTAssertEqual(try? Data(contentsOf: c), initialData)
                    }
                    
                    // Remove the backup manually.
                    try? fm.removeItem(at: c)
                } else {
                    XCTAssertNil(cAttributes)
                }
                
                let newA = try XCTUnwrap(result)

                let finalAttributes = try fm.attributesOfItem(atPath: newA.path)
                XCTAssertEqual(initialAttributes[.creationDate] as? AnyHashable, finalAttributes[.creationDate] as? AnyHashable)
                XCTAssertEqual(initialAttributes[.posixPermissions] as? AnyHashable, finalAttributes[.posixPermissions] as? AnyHashable)

                if bIsDirectory {
                    // Ensure we have execute permission, which can happen if .…newMetadataOnly isn't used, and we replace a file with a directory. (That's why we check attributes first.)
                    try? fm.setAttributes([.posixPermissions: 0o777], ofItemAtPath: newA.path)
                    XCTAssertNil(try? fm.attributesOfItem(atPath: newA.appendingPathComponent(initialFileName).path))
                    XCTAssertNotNil(try? fm.attributesOfItem(atPath: newA.appendingPathComponent(finalFileName).path))
                } else {
                    XCTAssertEqual(try? Data(contentsOf: newA), finalData)
                }
                
                try tearDownReplacement()
            }
            
            try runSingleTest(aIsDirectory: false, bIsDirectory: false)
            try runSingleTest(aIsDirectory: false, bIsDirectory: false, options: .withoutDeletingBackupItem)
            try runSingleTest(aIsDirectory: false, bIsDirectory: false, options: .usingNewMetadataOnly)
            try runSingleTest(aIsDirectory: false, bIsDirectory: false, options: [.withoutDeletingBackupItem, .usingNewMetadataOnly])
            try runSingleTest(aIsDirectory: true, bIsDirectory: true)
            try runSingleTest(aIsDirectory: true, bIsDirectory: true, options: .withoutDeletingBackupItem)
            try runSingleTest(aIsDirectory: true, bIsDirectory: true, options: .usingNewMetadataOnly)
            try runSingleTest(aIsDirectory: true, bIsDirectory: true, options: [.withoutDeletingBackupItem, .usingNewMetadataOnly])
            try runSingleTest(aIsDirectory: false, bIsDirectory: true)
            try runSingleTest(aIsDirectory: false, bIsDirectory: true, options: .withoutDeletingBackupItem)
            try runSingleTest(aIsDirectory: false, bIsDirectory: true, options: .usingNewMetadataOnly)
            try runSingleTest(aIsDirectory: false, bIsDirectory: true, options: [.withoutDeletingBackupItem, .usingNewMetadataOnly])
            try runSingleTest(aIsDirectory: true, bIsDirectory: false)
            try runSingleTest(aIsDirectory: true, bIsDirectory: false, options: .withoutDeletingBackupItem)
            try runSingleTest(aIsDirectory: true, bIsDirectory: false, options: .usingNewMetadataOnly)
            try runSingleTest(aIsDirectory: true, bIsDirectory: false, options: [.withoutDeletingBackupItem, .usingNewMetadataOnly])
        }

        print("Testing Darwin Foundation compatible replace", to: &stderr)
        try testReplaceMethod { (a, b, backupItemName, options) -> URL? in
            try fm.replaceItemAt(a, withItemAt: b, backupItemName: backupItemName, options: options)
        }

        #if !DARWIN_COMPATIBILITY_TESTS
        print("note: Testing platform-specific replace implementation.", to: &stderr)
        try testReplaceMethod { (a, b, backupItemName, options) -> URL? in
            try fm.replaceItem(at: a, withItemAt: b, backupItemName: backupItemName, options: options)
        }
        #endif

        #if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT && !os(Windows) // Not implemented on Windows yet
        print("note: Testing cross-platform replace implementation.", to: &stderr)
        try testReplaceMethod { (a, b, backupItemName, options) -> URL? in
            try fm._replaceItem(at: a, withItemAt: b, backupItemName: backupItemName, options: options, allowPlatformSpecificSyscalls: false)
        }
        #endif
    }
    
    // -----
    
    var writableTestDirectoryURL: URL!
    
    override func setUp() {
        super.setUp()
        
        let pid = ProcessInfo.processInfo.processIdentifier
        writableTestDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("org.swift.TestFoundation.TestFileManager.\(pid)")
    }
    
    override func tearDown() {
        if let directoryURL = writableTestDirectoryURL,
           (try? FileManager.default.attributesOfItem(atPath: directoryURL.path)) != nil {
            do {
                try FileManager.default.removeItem(at: directoryURL)
            } catch {
                NSLog("Could not remove test directory at URL \(directoryURL): \(error)")
            }
        }
        
        super.tearDown()
    }
    
    static var allTests: [(String, (TestFileManager) -> () throws -> Void)] {
        var tests: [(String, (TestFileManager) -> () throws -> Void)] = [
            ("test_createDirectory", test_createDirectory ),
            ("test_createFile", test_createFile ),
            ("test_moveFile", test_moveFile),
            ("test_fileSystemRepresentation", test_fileSystemRepresentation),
            ("test_fileExists", test_fileExists),
            ("test_isReadableFile", test_isReadableFile),
            ("test_isWritableFile", test_isWritableFile),
            ("test_isExecutableFile", test_isExecutableFile),
            ("test_isDeletableFile", test_isDeletableFile),
            ("test_fileAttributes", test_fileAttributes),
            ("test_fileSystemAttributes", test_fileSystemAttributes),
            ("test_setFileAttributes", test_setFileAttributes),
            ("test_directoryEnumerator", test_directoryEnumerator),
            ("test_pathEnumerator",test_pathEnumerator),
            ("test_contentsOfDirectoryAtPath", test_contentsOfDirectoryAtPath),
            ("test_subpathsOfDirectoryAtPath", test_subpathsOfDirectoryAtPath),
            ("test_copyItemAtPathToPath", test_copyItemAtPathToPath),
            ("test_linkItemAtPathToPath", testExpectedToFailOnAndroid(test_linkItemAtPathToPath, "Android doesn't allow hard links")),
            ("test_homedirectoryForUser", test_homedirectoryForUser),
            ("test_temporaryDirectoryForUser", test_temporaryDirectoryForUser),
            ("test_creatingDirectoryWithShortIntermediatePath", test_creatingDirectoryWithShortIntermediatePath),
            ("test_mountedVolumeURLs", test_mountedVolumeURLs),
            ("test_copyItemsPermissions", test_copyItemsPermissions),
            ("test_emptyFilename", test_emptyFilename),
            ("test_getRelationship", test_getRelationship),
            ("test_displayNames", test_displayNames),
            ("test_getItemReplacementDirectory", test_getItemReplacementDirectory),
            ("test_contentsEqual", test_contentsEqual),
            /* ⚠️  */ ("test_replacement", testExpectedToFail(test_replacement,
            /* ⚠️  */     "<https://bugs.swift.org/browse/SR-10819> Re-enable Foundation test TestFileManager.test_replacement")),
        ]
        
        #if !DEPLOYMENT_RUNTIME_OBJC && NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT && !os(Android)
        tests.append(contentsOf: [
            ("test_xdgStopgapsCoverAllConstants", test_xdgStopgapsCoverAllConstants),
            ("test_parseXDGConfiguration", test_parseXDGConfiguration),
            ("test_xdgURLSelection", test_xdgURLSelection),
            ])
        #endif
        
        #if !DEPLOYMENT_RUNTIME_OBJC && !os(Android) && !os(Windows)
        tests.append(contentsOf: [
            ("test_fetchXDGPathsFromHelper", test_fetchXDGPathsFromHelper),
            ])
        #endif
        
        return tests
    }
}
