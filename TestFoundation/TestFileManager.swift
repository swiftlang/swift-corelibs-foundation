// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestFileManager : XCTestCase {
    
    static var allTests: [(String, (TestFileManager) -> () throws -> Void)] {
        return [
            ("test_createDirectory", test_createDirectory ),
            ("test_createFile", test_createFile ),
            ("test_moveFile", test_moveFile),
            ("test_fileSystemRepresentation", test_fileSystemRepresentation),
            ("test_fileExists", test_fileExists),
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
            ("test_mountedVolumeURLs", test_mountedVolumeURLs),
            ("test_contentsEqual", test_contentsEqual)
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

        ignoreError { try fm.removeItem(atPath: tmpDir.path) }

        do {
            try fm.createDirectory(atPath: tmpDir.path, withIntermediateDirectories: false, attributes: nil)
            XCTAssertTrue(fm.createFile(atPath: testFile.path, contents: Data()))
            try fm.createSymbolicLink(atPath: goodSymLink.path, withDestinationPath: testFile.path)
            try fm.createSymbolicLink(atPath: badSymLink.path, withDestinationPath: "no_such_file")
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
        ignoreError { try fm.removeItem(atPath: tmpDir.path) }
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
#if !os(Android)
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
#endif
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
        createDirectory(atPath: "\(srcPath)/tempdir/subdir")
        createDirectory(atPath: "\(srcPath)/tempdir/subdir/otherdir")
        createDirectory(atPath: "\(srcPath)/tempdir/subdir/otherdir/extradir")
        createFile(atPath: "\(srcPath)/tempdir/tempfile")
        createFile(atPath: "\(srcPath)/tempdir/tempfile2")
        createFile(atPath: "\(srcPath)/tempdir/subdir/otherdir/extradir/tempfile2")

        do {
            try fm.copyItem(atPath: srcPath, toPath: destPath)
        } catch let error {
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
        XCTAssertTrue(volumes.contains(URL(fileURLWithPath: "/")))
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
            try fm.createSymbolicLink(atPath: testDir1.appendingPathComponent("null1").path, withDestinationPath: "/dev/null")
            try fm.createSymbolicLink(atPath: testDir1.appendingPathComponent("zero1").path, withDestinationPath: "/dev/zero")
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
            try fm.createSymbolicLink(atPath: testDir2.appendingPathComponent("bar2").path, withDestinationPath: "foo1")
            try fm.createSymbolicLink(atPath: testDir2.appendingPathComponent("foo2").path, withDestinationPath: "../testDir1/foo.txt")

            // testDir3
            try fm.createDirectory(atPath: testDir3.path, withIntermediateDirectories: true)
            try fm.createSymbolicLink(atPath: testDir3.appendingPathComponent("bar2").path, withDestinationPath: "foo1")
            try fm.createSymbolicLink(atPath: testDir3.appendingPathComponent("foo2").path, withDestinationPath: "../testDir1/foo.txt")
        } catch {
            XCTFail(String(describing: error))
        }

        XCTAssertTrue(fm.contentsEqual(atPath: "/dev/null", andPath: "/dev/null"))
        XCTAssertTrue(fm.contentsEqual(atPath: "/dev/urandom", andPath: "/dev/urandom"))
        XCTAssertFalse(fm.contentsEqual(atPath: "/dev/null", andPath: "/dev/zero"))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.appendingPathComponent("null1").path, andPath: "/dev/null"))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.appendingPathComponent("zero").path, andPath: "/dev/zero"))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.appendingPathComponent("foo.txt").path, andPath: testDir1.appendingPathComponent("foo1").path))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.appendingPathComponent("foo.txt").path, andPath: testDir1.appendingPathComponent("foo2").path))
        XCTAssertTrue(fm.contentsEqual(atPath: testDir1.appendingPathComponent("bar2").path, andPath: testDir2.appendingPathComponent("bar2").path))
        XCTAssertFalse(fm.contentsEqual(atPath: testDir1.appendingPathComponent("foo1").path, andPath: testDir2.appendingPathComponent("foo2").path))
        XCTAssertFalse(fm.contentsEqual(atPath: "/non_existant_file", andPath: "/non_existant_file"))

        let emptyFile = testDir1.appendingPathComponent("empty_file")
        XCTAssertFalse(fm.contentsEqual(atPath: emptyFile.path, andPath: "/dev/null"))
        XCTAssertFalse(fm.contentsEqual(atPath: emptyFile.path, andPath: testDir1.appendingPathComponent("null1").path))
        XCTAssertFalse(fm.contentsEqual(atPath: emptyFile.path, andPath: testDir1.appendingPathComponent("unreadable_file").path))

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
}
