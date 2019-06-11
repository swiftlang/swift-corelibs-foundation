// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(Windows)
internal func joinPath(prefix: String, suffix: String) -> String {
    var pszPath: PWSTR?
    _ = prefix.withCString(encodedAs: UTF16.self) { prefix in
        _ = suffix.withCString(encodedAs: UTF16.self) { suffix in
            PathAllocCombine(prefix, suffix, ULONG(PATHCCH_ALLOW_LONG_PATHS.rawValue), &pszPath)
        }
    }

    let path: String = String(decodingCString: pszPath!, as: UTF16.self)
    LocalFree(pszPath)
    return path
}

extension FileManager {
    internal func _mountedVolumeURLs(includingResourceValuesForKeys propertyKeys: [URLResourceKey]?, options: VolumeEnumerationOptions = []) -> [URL]? {
        var urls: [URL] = []

        var wszVolumeName: [WCHAR] = Array<WCHAR>(repeating: 0, count: Int(MAX_PATH))

        var hVolumes: HANDLE = FindFirstVolumeW(&wszVolumeName, DWORD(wszVolumeName.count))
        guard hVolumes != INVALID_HANDLE_VALUE else { return nil }
        defer { FindVolumeClose(hVolumes) }

        repeat {
            var dwCChReturnLength: DWORD = 0
            GetVolumePathNamesForVolumeNameW(&wszVolumeName, nil, 0, &dwCChReturnLength)

            var wszPathNames: [WCHAR] = Array<WCHAR>(repeating: 0, count: Int(dwCChReturnLength + 1))
            if !GetVolumePathNamesForVolumeNameW(&wszVolumeName, &wszPathNames, DWORD(wszPathNames.count), &dwCChReturnLength) {
                // TODO(compnerd) handle error
                continue
            }

            var pPath: DWORD = 0
            repeat {
                let path: String = String(decodingCString: &wszPathNames[Int(pPath)], as: UTF16.self)
                if path.length == 0 {
                    break
                }
                urls.append(URL(fileURLWithPath: path, isDirectory: true))
                pPath += DWORD(path.length + 1)
            } while pPath < dwCChReturnLength
        } while FindNextVolumeW(hVolumes, &wszVolumeName, DWORD(wszVolumeName.count))

        return urls
    }
    internal func _urls(for directory: SearchPathDirectory, in domainMask: SearchPathDomainMask) -> [URL] {
        let domains = _SearchPathDomain.allInSearchOrder(from: domainMask)

        var urls: [URL] = []

        for domain in domains {
            urls.append(contentsOf: windowsURLs(for: directory, in: domain))
        }

        return urls
    }

    private class func url(for id: KNOWNFOLDERID) -> URL {
        var pszPath: PWSTR?
        let hResult: HRESULT = withUnsafePointer(to: id) { id in
            SHGetKnownFolderPath(id, DWORD(KF_FLAG_DEFAULT.rawValue), nil, &pszPath)
        }
        precondition(hResult >= 0, "SHGetKnownFolderpath failed \(GetLastError())")
        let url: URL = URL(fileURLWithPath: String(decodingCString: pszPath!, as: UTF16.self), isDirectory: true)
        CoTaskMemFree(pszPath)
        return url
    }

    private func windowsURLs(for directory: SearchPathDirectory, in domain: _SearchPathDomain) -> [URL] {
        switch directory {
        case .autosavedInformationDirectory:
            // FIXME(compnerd) where should this go?
            return []

        case .desktopDirectory:
            guard domain == .user else { return [] }
            return [FileManager.url(for: FOLDERID_Desktop)]

        case .documentDirectory:
            guard domain == .user else { return [] }
            return [FileManager.url(for: FOLDERID_Documents)]

        case .cachesDirectory:
            guard domain == .user else { return [] }
            return [URL(fileURLWithPath: NSTemporaryDirectory())]

        case .applicationSupportDirectory:
            switch domain {
            case .local:
                return [FileManager.url(for: FOLDERID_ProgramData)]
            case .user:
                return [FileManager.url(for: FOLDERID_LocalAppData)]
            default:
                return []
            }

            case .downloadsDirectory:
                guard domain == .user else { return [] }
                return [FileManager.url(for: FOLDERID_Downloads)]

            case .userDirectory:
                guard domain == .user else { return [] }
                return [FileManager.url(for: FOLDERID_UserProfiles)]

            case .moviesDirectory:
                guard domain == .user else { return [] }
                return [FileManager.url(for: FOLDERID_Videos)]

            case .musicDirectory:
                guard domain == .user else { return [] }
                return [FileManager.url(for: FOLDERID_Music)]

            case .picturesDirectory:
                guard domain == .user else { return [] }
                return [FileManager.url(for: FOLDERID_PicturesLibrary)]

            case .sharedPublicDirectory:
                guard domain == .user else { return [] }
                return [FileManager.url(for: FOLDERID_Public)]

            case .trashDirectory:
                guard domain == .user else { return [] }
                return [FileManager.url(for: FOLDERID_RecycleBinFolder)]

                // None of these are supported outside of Darwin:
            case .applicationDirectory,
                 .demoApplicationDirectory,
                 .developerApplicationDirectory,
                 .adminApplicationDirectory,
                 .libraryDirectory,
                 .developerDirectory,
                 .documentationDirectory,
                 .coreServiceDirectory,
                 .inputMethodsDirectory,
                 .preferencePanesDirectory,
                 .applicationScriptsDirectory,
                 .allApplicationsDirectory,
                 .allLibrariesDirectory,
                 .printerDescriptionDirectory,
                 .itemReplacementDirectory:
                return []
        }
    }

    internal func _createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = [:]) throws {
        if createIntermediates {
            var isDir: ObjCBool = false
            if fileExists(atPath: path, isDirectory: &isDir) {
                guard isDir.boolValue else { throw _NSErrorWithErrno(EEXIST, reading: false, path: path) }
                return
            }

            let parent = path._nsObject.deletingLastPathComponent
            if !parent.isEmpty && !fileExists(atPath: parent, isDirectory: &isDir) {
                try createDirectory(atPath: parent, withIntermediateDirectories: true, attributes: attributes)
            }
        }

        var saAttributes: SECURITY_ATTRIBUTES =
          SECURITY_ATTRIBUTES(nLength: DWORD(MemoryLayout<SECURITY_ATTRIBUTES>.size),
                              lpSecurityDescriptor: nil,
                              bInheritHandle: false)
        let psaAttributes: UnsafeMutablePointer<SECURITY_ATTRIBUTES> =
          UnsafeMutablePointer<SECURITY_ATTRIBUTES>(&saAttributes)


        try path.withCString(encodedAs: UTF16.self) {
            if !CreateDirectoryW($0, psaAttributes) {
                // FIXME(compnerd) pass along path
                throw _NSErrorWithWindowsError(GetLastError(), reading: false)
            }
        }
        if let attr = attributes {
            try self.setAttributes(attr, ofItemAtPath: path)
        }
    }

    internal func _contentsOfDir(atPath path: String, _ closure: (String, Int32) throws -> () ) throws {
        try path.withCString(encodedAs: UTF16.self) {
            var ffd: WIN32_FIND_DATAW = WIN32_FIND_DATAW()

            let hDirectory: HANDLE = FindFirstFileW($0, &ffd)
            if hDirectory == INVALID_HANDLE_VALUE {
                throw _NSErrorWithWindowsError(GetLastError(), reading: true)
            }
            defer { FindClose(hDirectory) }

            repeat {
                let path: String = withUnsafePointer(to: &ffd.cFileName) {
                    $0.withMemoryRebound(to: UInt16.self, capacity: MemoryLayout.size(ofValue: $0) / MemoryLayout<WCHAR>.size) {
                        String(decodingCString: $0, as: UTF16.self)
                    }
                }

                try closure(path, Int32(ffd.dwFileAttributes))
            } while FindNextFileW(hDirectory, &ffd)
        }
    }

    internal func _subpathsOfDirectory(atPath path: String) throws -> [String] {
        var contents: [String] = []

        try _contentsOfDir(atPath: path, { (entryName, entryType) throws in
            contents.append(entryName)
            if entryType & FILE_ATTRIBUTE_DIRECTORY == FILE_ATTRIBUTE_DIRECTORY {
                let subPath: String = joinPath(prefix: path, suffix: entryName)
                let entries = try subpathsOfDirectory(atPath: subPath)
                contents.append(contentsOf: entries.map { joinPath(prefix: entryName, suffix: $0) })
            }
        })
        return contents
    }

    internal func windowsFileAttributes(atPath path: String) throws -> WIN32_FILE_ATTRIBUTE_DATA {
        var faAttributes: WIN32_FILE_ATTRIBUTE_DATA = WIN32_FILE_ATTRIBUTE_DATA()
        return try path.withCString(encodedAs: UTF16.self) {
            if !GetFileAttributesExW($0, GetFileExInfoStandard, &faAttributes) {
                throw _NSErrorWithWindowsError(GetLastError(), reading: true)
            }
            return faAttributes
        }
    }
    
    internal func _attributesOfFileSystemIncludingBlockSize(forPath path: String) throws -> (attributes: [FileAttributeKey : Any], blockSize: UInt64?) {
        return (attributes: try _attributesOfFileSystem(forPath: path), blockSize: nil)
    }

    internal func _attributesOfFileSystem(forPath path: String) throws -> [FileAttributeKey : Any] {
        var result: [FileAttributeKey:Any] = [:]

        try path.withCString(encodedAs: UTF16.self) {
            let dwLength: DWORD = GetFullPathNameW($0, 0, nil, nil)
            var szVolumePath: [WCHAR] = Array<WCHAR>(repeating: 0, count: Int(dwLength + 1))

            guard GetVolumePathNameW($0, &szVolumePath, dwLength) else {
                throw _NSErrorWithWindowsError(GetLastError(), reading: true)
            }

            var liTotal: ULARGE_INTEGER = ULARGE_INTEGER()
            var liFree: ULARGE_INTEGER = ULARGE_INTEGER()

            guard GetDiskFreeSpaceExW(&szVolumePath, nil, &liTotal, &liFree) else {
                throw _NSErrorWithWindowsError(GetLastError(), reading: true)
            }

            result[.systemSize] = NSNumber(value: liTotal.QuadPart)
            result[.systemFreeSize] = NSNumber(value: liFree.QuadPart)
            // FIXME(compnerd): what about .systemNodes, .systemFreeNodes?
        }
        return result
    }

    internal func _createSymbolicLink(atPath path: String, withDestinationPath destPath: String) throws {
        var dwFlags = DWORD(SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE)
        // Note: windowsfileAttributes will throw if the destPath is not found.
        // Since on Windows, you are required to know the type of the symlink
        // target (file or directory) during creation, and assuming one or the
        // other doesn't make a lot of sense, we allow it to throw, thus
        // disallowing the creation of broken symlinks on Windows (unlike with
        // POSIX).
        let faAttributes = try windowsFileAttributes(atPath: destPath)
        if faAttributes.dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) == DWORD(FILE_ATTRIBUTE_DIRECTORY) {
            dwFlags |= DWORD(SYMBOLIC_LINK_FLAG_DIRECTORY)
        }

        try path.withCString(encodedAs: UTF16.self) { name in
            try destPath.withCString(encodedAs: UTF16.self) { dest in
                guard CreateSymbolicLinkW(name, dest, dwFlags) != 0 else {
                    throw _NSErrorWithWindowsError(GetLastError(), reading: false)
                }
            }
        }
    }

    internal func _destinationOfSymbolicLink(atPath path: String) throws -> String {
        return try _canonicalizedPath(toFileAtPath: path)
    }
    
    internal func _canonicalizedPath(toFileAtPath path: String) throws -> String {
        var hFile: HANDLE = INVALID_HANDLE_VALUE
        path.withCString(encodedAs: UTF16.self) { link in
          // BACKUP_SEMANTICS are (confusingly) required in order to receive a
          // handle to a directory
          hFile = CreateFileW(link, 0, DWORD(FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE),
                              nil, DWORD(OPEN_EXISTING), DWORD(FILE_FLAG_BACKUP_SEMANTICS),
                              nil)
        }
        if hFile == INVALID_HANDLE_VALUE {
            throw _NSErrorWithWindowsError(GetLastError(), reading: true)
        }
        defer { CloseHandle(hFile) }

        let dwLength: DWORD = GetFinalPathNameByHandleW(hFile, nil, 0, DWORD(FILE_NAME_NORMALIZED))
        var szPath: [WCHAR] = Array<WCHAR>(repeating: 0, count: Int(dwLength + 1))

        GetFinalPathNameByHandleW(hFile, &szPath, dwLength, DWORD(FILE_NAME_NORMALIZED))
        return String(decodingCString: &szPath, as: UTF16.self)
    }

    internal func _copyRegularFile(atPath srcPath: String, toPath dstPath: String, variant: String = "Copy") throws {
        try srcPath.withCString(encodedAs: UTF16.self) { src in
            try dstPath.withCString(encodedAs: UTF16.self) { dst in
                if !CopyFileW(src, dst, false) {
                    throw _NSErrorWithWindowsError(GetLastError(), reading: false)
                }
            }
        }
    }

    internal func _copySymlink(atPath srcPath: String, toPath dstPath: String, variant: String = "Copy") throws {
        let faAttributes: WIN32_FILE_ATTRIBUTE_DATA = try windowsFileAttributes(atPath: srcPath)
        guard faAttributes.dwFileAttributes & DWORD(FILE_ATTRIBUTE_REPARSE_POINT) == DWORD(FILE_ATTRIBUTE_REPARSE_POINT) else {
            throw _NSErrorWithErrno(EINVAL, reading: true, path: srcPath, extraUserInfo: extraErrorInfo(srcPath: srcPath, dstPath: dstPath, userVariant: variant))
        }

        let destination = try FileManager.default.destinationOfSymbolicLink(atPath: srcPath)

        var dwFlags: DWORD = DWORD(SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE)
        if try windowsFileAttributes(atPath: destination).dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) == DWORD(FILE_ATTRIBUTE_DIRECTORY) {
            dwFlags |= DWORD(SYMBOLIC_LINK_FLAG_DIRECTORY)
        }

        try FileManager.default.createSymbolicLink(atPath: dstPath, withDestinationPath: destination)
    }

    internal func _copyOrLinkDirectoryHelper(atPath srcPath: String, toPath dstPath: String, variant: String = "Copy", _ body: (String, String, FileAttributeType) throws -> ()) throws {
        var faAttributes: WIN32_FILE_ATTRIBUTE_DATA = WIN32_FILE_ATTRIBUTE_DATA()
        do { faAttributes = try windowsFileAttributes(atPath: srcPath) } catch { return }

        var fileType = FileAttributeType(attributes: faAttributes, atPath: srcPath)
        if fileType == .typeDirectory {
          try createDirectory(atPath: dstPath, withIntermediateDirectories: false, attributes: nil)
          guard let enumerator = enumerator(atPath: srcPath) else {
            throw _NSErrorWithErrno(ENOENT, reading: true, path: srcPath)
          }

          while let item = enumerator.nextObject() as? String {
            let src = joinPath(prefix: srcPath, suffix: item)
            let dst = joinPath(prefix: dstPath, suffix: item)

            do { faAttributes = try windowsFileAttributes(atPath: src) } catch { return }
            fileType = FileAttributeType(attributes: faAttributes, atPath: srcPath)
            if fileType == .typeDirectory {
              try createDirectory(atPath: dst, withIntermediateDirectories: false, attributes: nil)
            } else {
              try body(src, dst, fileType)
            }
          }
        } else {
          try body(srcPath, dstPath, fileType)
        }
    }

    internal func _moveItem(atPath srcPath: String, toPath dstPath: String, isURL: Bool) throws {
        guard shouldMoveItemAtPath(srcPath, toPath: dstPath, isURL: isURL) else {
            return
        }

        guard !self.fileExists(atPath: dstPath) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteFileExists.rawValue, userInfo: [NSFilePathErrorKey : NSString(dstPath)])
        }

        try srcPath.withCString(encodedAs: UTF16.self) { src in
            try dstPath.withCString(encodedAs: UTF16.self) { dst in
                if !MoveFileExW(src, dst, DWORD(MOVEFILE_COPY_ALLOWED | MOVEFILE_WRITE_THROUGH)) {
                    throw _NSErrorWithWindowsError(GetLastError(), reading: false)
                }
            }
        }
    }

    internal func _linkItem(atPath srcPath: String, toPath dstPath: String, isURL: Bool) throws {
        try _copyOrLinkDirectoryHelper(atPath: srcPath, toPath: dstPath) { (srcPath, dstPath, fileType) in
            guard shouldLinkItemAtPath(srcPath, toPath: dstPath, isURL: isURL) else {
                return
            }

            do {
                switch fileType {
                case .typeRegular:
                    try srcPath.withCString(encodedAs: UTF16.self) { src in
                        try dstPath.withCString(encodedAs: UTF16.self) { dst in
                            if !CreateHardLinkW(src, dst, nil) {
                                throw _NSErrorWithWindowsError(GetLastError(), reading: false)
                            }
                        }
                    }
                case .typeSymbolicLink:
                    try _copySymlink(atPath: srcPath, toPath: dstPath)
                default:
                    break
                }
            } catch {
                if !shouldProceedAfterError(error, linkingItemAtPath: srcPath, toPath: dstPath, isURL: isURL) {
                    throw error
                }
            }
        }
    }

    internal func _removeItem(atPath path: String, isURL: Bool, alreadyConfirmed: Bool = false) throws {
        guard alreadyConfirmed || shouldRemoveItemAtPath(path, isURL: isURL) else {
            return
        }
        let url = URL(fileURLWithPath: path)
        var fsrBuf: [WCHAR] = Array<WCHAR>(repeating: 0, count: Int(MAX_PATH))
        _CFURLGetWideFileSystemRepresentation(url._cfObject, false, &fsrBuf, Int(MAX_PATH))
        let length = wcsnlen_s(&fsrBuf, fsrBuf.count)
        let fsrPath = String(utf16CodeUnits: &fsrBuf, count: length)

        let faAttributes = try windowsFileAttributes(atPath: fsrPath)

        if faAttributes.dwFileAttributes & DWORD(FILE_ATTRIBUTE_READONLY) == FILE_ATTRIBUTE_READONLY {
        let readableAttributes = faAttributes.dwFileAttributes & DWORD(bitPattern: ~FILE_ATTRIBUTE_READONLY)
            guard fsrPath.withCString(encodedAs: UTF16.self, { SetFileAttributesW($0, readableAttributes) }) else {
                throw _NSErrorWithWindowsError(GetLastError(), reading: false)
            }
        }

        if faAttributes.dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) == 0 {
            if !fsrPath.withCString(encodedAs: UTF16.self, DeleteFileW) {
                throw _NSErrorWithWindowsError(GetLastError(), reading: false)
            }
            return
        }
        var dirStack = [fsrPath]
        var itemPath = ""
        while let currentDir = dirStack.popLast() {
            do {
                itemPath = currentDir
                guard alreadyConfirmed || shouldRemoveItemAtPath(itemPath, isURL: isURL) else {
                    continue
                }
                guard !itemPath.withCString(encodedAs: UTF16.self, RemoveDirectoryW) else {
                    continue
                }
                guard GetLastError() == ERROR_DIR_NOT_EMPTY else {
                    throw _NSErrorWithWindowsError(GetLastError(), reading: false)
                }
                dirStack.append(itemPath)
                var ffd: WIN32_FIND_DATAW = WIN32_FIND_DATAW()
                let h: HANDLE = (itemPath + "\\*").withCString(encodedAs: UTF16.self, {
                    FindFirstFileW($0, &ffd)
                })
                guard h != INVALID_HANDLE_VALUE else {
                    throw _NSErrorWithWindowsError(GetLastError(), reading: false)
                }
                defer { FindClose(h) }

                repeat {
                    let fileArr = Array<WCHAR>(
                        UnsafeBufferPointer(start: &ffd.cFileName.0,
                                            count: MemoryLayout.size(ofValue: ffd.cFileName)))
                    let file = String(decodingCString: fileArr, as: UTF16.self)
                    itemPath = "\(currentDir)\\\(file)"

                    if ffd.dwFileAttributes & DWORD(FILE_ATTRIBUTE_READONLY) == FILE_ATTRIBUTE_READONLY {
                        let readableAttributes = ffd.dwFileAttributes & DWORD(bitPattern: ~FILE_ATTRIBUTE_READONLY)
                        guard file.withCString(encodedAs: UTF16.self, { SetFileAttributesW($0, readableAttributes) }) else {
                            throw _NSErrorWithWindowsError(GetLastError(), reading: false)
                        }
                    }

                    if (ffd.dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) != 0) {
                        if file != "." && file != ".." {
                            dirStack.append(itemPath)
                        }
                    } else {
                        guard alreadyConfirmed || shouldRemoveItemAtPath(itemPath, isURL: isURL) else {
                            continue
                        }
                        if !itemPath.withCString(encodedAs: UTF16.self, DeleteFileW) {
                            throw _NSErrorWithWindowsError(GetLastError(), reading: false)
                        }
                    }
                } while FindNextFileW(h, &ffd)
            } catch {
                if !shouldProceedAfterError(error, removingItemAtPath: itemPath, isURL: isURL) {
                    throw error
                }
            }
        }
    }

    internal func _currentDirectoryPath() -> String {
        let dwLength: DWORD = GetCurrentDirectoryW(0, nil)
        var szDirectory: [WCHAR] = Array<WCHAR>(repeating: 0, count: Int(dwLength + 1))

        GetCurrentDirectoryW(dwLength, &szDirectory)
        return String(decodingCString: &szDirectory, as: UTF16.self)
    }

    @discardableResult
    internal func _changeCurrentDirectoryPath(_ path: String) -> Bool {
        return path.withCString(encodedAs: UTF16.self) { SetCurrentDirectoryW($0) }
    }

    internal func _fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        var faAttributes: WIN32_FILE_ATTRIBUTE_DATA = WIN32_FILE_ATTRIBUTE_DATA()
        do { faAttributes = try windowsFileAttributes(atPath: path) } catch { return false }
        if faAttributes.dwFileAttributes & DWORD(FILE_ATTRIBUTE_REPARSE_POINT) == DWORD(FILE_ATTRIBUTE_REPARSE_POINT) {
            do { try faAttributes = windowsFileAttributes(atPath: destinationOfSymbolicLink(atPath: path)) } catch { return false }
        }
        if let isDirectory = isDirectory {
            isDirectory.pointee = ObjCBool(faAttributes.dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) == DWORD(FILE_ATTRIBUTE_DIRECTORY))
        }
        return true
    }


    internal func _isReadableFile(atPath path: String) -> Bool {
        do { let _ = try windowsFileAttributes(atPath: path) } catch { return false }
        return true
    }

    internal func _isWritableFile(atPath path: String) -> Bool {
        guard let faAttributes: WIN32_FILE_ATTRIBUTE_DATA = try? windowsFileAttributes(atPath: path) else { return false }
        return faAttributes.dwFileAttributes & DWORD(FILE_ATTRIBUTE_READONLY) != DWORD(FILE_ATTRIBUTE_READONLY)
    }

    internal func _isExecutableFile(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: path, isDirectory: &isDirectory) else { return false }
        return !isDirectory.boolValue && _isReadableFile(atPath: path)
    }

    internal func _isDeletableFile(atPath path: String) -> Bool {
        guard path != "" else { return true }

        // Get the parent directory of supplied path
        let parent = path._nsObject.deletingLastPathComponent
        var faAttributes: WIN32_FILE_ATTRIBUTE_DATA = WIN32_FILE_ATTRIBUTE_DATA()
        do { faAttributes = try windowsFileAttributes(atPath: parent) } catch { return false }
        if faAttributes.dwFileAttributes & DWORD(FILE_ATTRIBUTE_READONLY) == DWORD(FILE_ATTRIBUTE_READONLY) {
            return false
        }

        do { faAttributes = try windowsFileAttributes(atPath: path) } catch { return false }
        if faAttributes.dwFileAttributes & DWORD(FILE_ATTRIBUTE_READONLY) == DWORD(FILE_ATTRIBUTE_READONLY) {
            return false
        }

        return true
    }

    internal func _compareFiles(withFileSystemRepresentation file1Rep: UnsafePointer<Int8>, andFileSystemRepresentation file2Rep: UnsafePointer<Int8>, size: Int64, bufSize: Int) -> Bool {
        NSUnimplemented()
    }

    internal func _lstatFile(atPath path: String, withFileSystemRepresentation fsRep: UnsafePointer<Int8>? = nil) throws -> stat {
        let _fsRep: UnsafePointer<Int8>
        if fsRep == nil {
            _fsRep = try __fileSystemRepresentation(withPath: path)
        } else {
            _fsRep = fsRep!
        }

        defer {
            if fsRep == nil { _fsRep.deallocate() }
        }

        var statInfo = stat()
        let h = path.withCString(encodedAs: UTF16.self) {
            CreateFileW(/*lpFileName=*/$0,
                        /*dwDesiredAccess=*/DWORD(0),
                        /*dwShareMode=*/DWORD(FILE_SHARE_READ),
                        /*lpSecurityAttributes=*/nil,
                        /*dwCreationDisposition=*/DWORD(OPEN_EXISTING),
                        /*dwFlagsAndAttributes=*/DWORD(FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_BACKUP_SEMANTICS),
                        /*hTemplateFile=*/nil)
        }
        if h == INVALID_HANDLE_VALUE {
            throw _NSErrorWithWindowsError(GetLastError(), reading: false)
        }
        var info: BY_HANDLE_FILE_INFORMATION = BY_HANDLE_FILE_INFORMATION()
        GetFileInformationByHandle(h, &info)
        // Group id is always 0 on Windows
        statInfo.st_gid = 0
        statInfo.st_atime = info.ftLastAccessTime.time_t
        statInfo.st_ctime = info.ftCreationTime.time_t
        statInfo.st_dev = info.dwVolumeSerialNumber
        // inodes have meaning on FAT/HPFS/NTFS
        statInfo.st_ino = 0
        statInfo.st_rdev = info.dwVolumeSerialNumber

        let isReparsePoint = info.dwFileAttributes & DWORD(FILE_ATTRIBUTE_REPARSE_POINT) != 0
        let isDir = info.dwFileAttributes & DWORD(FILE_ATTRIBUTE_DIRECTORY) != 0
        let fileMode = isDir ? _S_IFDIR : _S_IFREG
        // On a symlink to a directory, Windows sets both the REPARSE_POINT and
        // DIRECTORY attributes. Since Windows doesn't provide S_IFLNK and we
        // want unix style "symlinks to directories are not directories
        // themselves, we say symlinks are regular files
        statInfo.st_mode = UInt16(isReparsePoint ? _S_IFREG : fileMode)
        let isReadOnly = info.dwFileAttributes & DWORD(FILE_ATTRIBUTE_READONLY) != 0
        statInfo.st_mode |= UInt16(isReadOnly ? _S_IREAD : (_S_IREAD | _S_IWRITE))
        statInfo.st_mode |= UInt16(_S_IEXEC)

        statInfo.st_mtime = info.ftLastWriteTime.time_t
        statInfo.st_nlink = Int16(info.nNumberOfLinks)
        if info.nFileSizeHigh != 0 {
            throw _NSErrorWithErrno(EOVERFLOW, reading: true, path: path)
        }
        statInfo.st_size = Int32(info.nFileSizeLow)
        // Uid is always 0 on Windows systems
        statInfo.st_uid = 0
        CloseHandle(h)
        return statInfo
    }

    internal func _contentsEqual(atPath path1: String, andPath path2: String) -> Bool {
        NSUnimplemented()
    }

    internal func _appendSymlinkDestination(_ dest: String, toPath: String) -> String {
        var isAbsolutePath: Bool = false
        dest.withCString(encodedAs: UTF16.self) {
            isAbsolutePath = !PathIsRelativeW($0)
        }

        if isAbsolutePath {
            return dest
        }
        let temp = toPath._bridgeToObjectiveC().deletingLastPathComponent
        return temp._bridgeToObjectiveC().appendingPathComponent(dest)
    }

    internal func _updateTimes(atPath path: String,
                               withFileSystemRepresentation fsr: UnsafePointer<Int8>,
                               creationTime: Date? = nil,
                               accessTime: Date? = nil,
                               modificationTime: Date? = nil) throws {
      let stat = try _lstatFile(atPath: path, withFileSystemRepresentation: fsr)

      var atime: FILETIME =
          FILETIME(from: time_t((accessTime ?? stat.lastAccessDate).timeIntervalSince1970))
      var mtime: FILETIME =
          FILETIME(from: time_t((modificationTime ?? stat.lastModificationDate).timeIntervalSince1970))

      let hFile: HANDLE = String(utf8String: fsr)!.withCString(encodedAs: UTF16.self) {
        CreateFileW($0, DWORD(GENERIC_WRITE), DWORD(FILE_SHARE_WRITE),
                    nil, DWORD(OPEN_EXISTING), 0, nil)
      }
      if hFile == INVALID_HANDLE_VALUE {
        throw _NSErrorWithWindowsError(GetLastError(), reading: true)
      }
      defer { CloseHandle(hFile) }

      if !SetFileTime(hFile, nil, &atime, &mtime) {
        throw _NSErrorWithWindowsError(GetLastError(), reading: false)
      }

    }

    internal class NSURLDirectoryEnumerator : DirectoryEnumerator {
        var _options : FileManager.DirectoryEnumerationOptions
        var _errorHandler : ((URL, Error) -> Bool)?
        var _stack: [URL]
        var _lastReturned: URL
        var _rootDepth : Int

        init(url: URL, options: FileManager.DirectoryEnumerationOptions, errorHandler: (/* @escaping */ (URL, Error) -> Bool)?) {
            _options = options
            _errorHandler = errorHandler
            _stack = []
            _rootDepth = url.pathComponents.count
            _lastReturned = url
        }

        override func nextObject() -> Any? {
            func firstValidItem() -> URL? {
                while let url = _stack.popLast() {
                    if !FileManager.default.fileExists(atPath: url.path, isDirectory: nil) {
                        guard let handler = _errorHandler,
                              handler(url, _NSErrorWithWindowsError(GetLastError(), reading: true))
                        else { return nil }
                        continue
                    }
                    _lastReturned = url
                    return _lastReturned
                }
                return nil
            }

            // If we most recently returned a directory, decend into it
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: _lastReturned.path, isDirectory: &isDir) else {
              guard let handler = _errorHandler,
                    handler(_lastReturned, _NSErrorWithWindowsError(GetLastError(), reading: true))
              else { return nil }
              return firstValidItem()
            }

            if isDir.boolValue && (level == 0 || !_options.contains(.skipsSubdirectoryDescendants)) {
                var ffd = WIN32_FIND_DATAW()
                let dirPath = joinPath(prefix: _lastReturned.path, suffix: "*")
                let handle = dirPath.withCString(encodedAs: UTF16.self) {
                  FindFirstFileW($0, &ffd)
                }
                guard handle != INVALID_HANDLE_VALUE else { return firstValidItem() }
                defer { FindClose(handle) }

                repeat {
                    let fileArr = Array<WCHAR>(
                      UnsafeBufferPointer(start: &ffd.cFileName.0,
                                          count: MemoryLayout.size(ofValue: ffd.cFileName)))
                    let file = String(decodingCString: fileArr, as: UTF16.self)
                    if file != "." && file != ".."
                        && (!_options.contains(.skipsHiddenFiles)
                            || (ffd.dwFileAttributes & DWORD(FILE_ATTRIBUTE_HIDDEN) == 0)) {
                        let relative = URL(fileURLWithPath: file, relativeTo: _lastReturned)
                        _stack.append(relative)
                    }
                } while FindNextFileW(handle, &ffd)
            }

            return firstValidItem()
        }

        override var level: Int {
            return _lastReturned.pathComponents.count - _rootDepth
        }

        override func skipDescendants() {
            _options.insert(.skipsSubdirectoryDescendants)
        }

        override var directoryAttributes : [FileAttributeKey : Any]? {
            return nil
        }

        override var fileAttributes: [FileAttributeKey : Any]? {
            return nil
        }
    }
}

extension FileManager.NSPathDirectoryEnumerator {
    internal func _nextObject() -> Any? {
        guard let url = innerEnumerator.nextObject() as? URL else { return nil }

        var relativePath: [WCHAR] = Array<WCHAR>(repeating: 0, count: Int(MAX_PATH))

        guard baseURL._withUnsafeWideFileSystemRepresentation({ baseUrlFsr in
            url._withUnsafeWideFileSystemRepresentation { urlFsr in
                let fromAttrs = GetFileAttributesW(baseUrlFsr)
                let toAttrs = GetFileAttributesW(urlFsr)
                guard fromAttrs != INVALID_FILE_ATTRIBUTES, toAttrs != INVALID_FILE_ATTRIBUTES else {
                    return false
                }
                return PathRelativePathToW(&relativePath, baseUrlFsr, fromAttrs, urlFsr, toAttrs)
            }
        }) else { return nil }

        let path = String(decodingCString: &relativePath, as: UTF16.self)
        // Drop the leading ".\" from the path
        _currentItemPath = String(path.dropFirst(2))
        return _currentItemPath
    }

}

#endif
