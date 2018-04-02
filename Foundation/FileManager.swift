// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux) || CYGWIN
    import Glibc
#endif

#if os(Android) // struct stat.st_mode is UInt32
internal func &(left: UInt32, right: mode_t) -> mode_t {
    return mode_t(left) & right
}
#endif

import CoreFoundation

open class FileManager : NSObject {
    
    /* Returns the default singleton instance.
    */
    private static let _default = FileManager()
    open class var `default`: FileManager {
        get {
            return _default
        }
    }
    
    /* Returns an NSArray of NSURLs locating the mounted volumes available on the computer. The property keys that can be requested are available in NSURL.
     */
    open func mountedVolumeURLs(includingResourceValuesForKeys propertyKeys: [URLResourceKey]?, options: VolumeEnumerationOptions = []) -> [URL]? {
        NSUnimplemented()
    }
    
    /* Returns an NSArray of NSURLs identifying the the directory entries. 
    
        If the directory contains no entries, this method will return the empty array. When an array is specified for the 'keys' parameter, the specified property values will be pre-fetched and cached with each enumerated URL.
     
        This method always does a shallow enumeration of the specified directory (i.e. it always acts as if NSDirectoryEnumerationSkipsSubdirectoryDescendants has been specified). If you need to perform a deep enumeration, use -[NSFileManager enumeratorAtURL:includingPropertiesForKeys:options:errorHandler:].
     
        If you wish to only receive the URLs and no other attributes, then pass '0' for 'options' and an empty NSArray ('[NSArray array]') for 'keys'. If you wish to have the property caches of the vended URLs pre-populated with a default set of attributes, then pass '0' for 'options' and 'nil' for 'keys'.
     */
    open func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: DirectoryEnumerationOptions = []) throws -> [URL] {
        var error : Error? = nil
        let e = self.enumerator(at: url, includingPropertiesForKeys: keys, options: mask.union(.skipsSubdirectoryDescendants)) { (url, err) -> Bool in
            error = err
            return false
        }
        var result = [URL]()
        if let e = e {
            for url in e {
                result.append(url as! URL)
            }
            if let error = error {
                throw error
            }
        }
        return result
    }
    
    /* -URLsForDirectory:inDomains: is analogous to NSSearchPathForDirectoriesInDomains(), but returns an array of NSURL instances for use with URL-taking APIs. This API is suitable when you need to search for a file or files which may live in one of a variety of locations in the domains specified.
     */
    open func urls(for directory: SearchPathDirectory, in domainMask: SearchPathDomainMask) -> [URL] {
        NSUnimplemented()
    }
    
    /* -URLForDirectory:inDomain:appropriateForURL:create:error: is a URL-based replacement for FSFindFolder(). It allows for the specification and (optional) creation of a specific directory for a particular purpose (e.g. the replacement of a particular item on disk, or a particular Library directory.
     
        You may pass only one of the values from the NSSearchPathDomainMask enumeration, and you may not pass NSAllDomainsMask.
     */
    open func url(for directory: SearchPathDirectory, in domain: SearchPathDomainMask, appropriateFor url: URL?, create shouldCreate: Bool) throws -> URL {
        NSUnimplemented()
    }
    
    /* Sets 'outRelationship' to NSURLRelationshipContains if the directory at 'directoryURL' directly or indirectly contains the item at 'otherURL', meaning 'directoryURL' is found while enumerating parent URLs starting from 'otherURL'. Sets 'outRelationship' to NSURLRelationshipSame if 'directoryURL' and 'otherURL' locate the same item, meaning they have the same NSURLFileResourceIdentifierKey value. If 'directoryURL' is not a directory, or does not contain 'otherURL' and they do not locate the same file, then sets 'outRelationship' to NSURLRelationshipOther. If an error occurs, returns NO and sets 'error'.
     */
    open func getRelationship(_ outRelationship: UnsafeMutablePointer<URLRelationship>, ofDirectoryAt directoryURL: URL, toItemAt otherURL: URL) throws {
        NSUnimplemented()
    }
    
    /* Similar to -[NSFileManager getRelationship:ofDirectoryAtURL:toItemAtURL:error:], except that the directory is instead defined by an NSSearchPathDirectory and NSSearchPathDomainMask. Pass 0 for domainMask to instruct the method to automatically choose the domain appropriate for 'url'. For example, to discover if a file is contained by a Trash directory, call [fileManager getRelationship:&result ofDirectory:NSTrashDirectory inDomain:0 toItemAtURL:url error:&error].
     */
    open func getRelationship(_ outRelationship: UnsafeMutablePointer<URLRelationship>, of directory: SearchPathDirectory, in domainMask: SearchPathDomainMask, toItemAt url: URL) throws {
        NSUnimplemented()
    }
    
    /* createDirectoryAtURL:withIntermediateDirectories:attributes:error: creates a directory at the specified URL. If you pass 'NO' for withIntermediateDirectories, the directory must not exist at the time this call is made. Passing 'YES' for withIntermediateDirectories will create any necessary intermediate directories. This method returns YES if all directories specified in 'url' were created and attributes were set. Directories are created with attributes specified by the dictionary passed to 'attributes'. If no dictionary is supplied, directories are created according to the umask of the process. This method returns NO if a failure occurs at any stage of the operation. If an error parameter was provided, a presentable NSError will be returned by reference.
     */
    open func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = [:]) throws {
        guard url.isFileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnsupportedScheme.rawValue, userInfo: [NSURLErrorKey : url])
        }
        try self.createDirectory(atPath: url.path, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }
    
    /* createSymbolicLinkAtURL:withDestinationURL:error: returns YES if the symbolic link that point at 'destURL' was able to be created at the location specified by 'url'. 'destURL' is always resolved against its base URL, if it has one. If 'destURL' has no base URL and it's 'relativePath' is indeed a relative path, then a relative symlink will be created. If this method returns NO, the link was unable to be created and an NSError will be returned by reference in the 'error' parameter. This method does not traverse a terminal symlink.
     */
    open func createSymbolicLink(at url: URL, withDestinationURL destURL: URL) throws {
        guard url.isFileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnsupportedScheme.rawValue, userInfo: [NSURLErrorKey : url])
        }
        guard destURL.scheme == nil || destURL.isFileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnsupportedScheme.rawValue, userInfo: [NSURLErrorKey : destURL])
        }
        try self.createSymbolicLink(atPath: url.path, withDestinationPath: destURL.path)
    }
    
    /* Instances of FileManager may now have delegates. Each instance has one delegate, and the delegate is not retained. In versions of Mac OS X prior to 10.5, the behavior of calling [[NSFileManager alloc] init] was undefined. In Mac OS X 10.5 "Leopard" and later, calling [[NSFileManager alloc] init] returns a new instance of an FileManager.
     */
    open weak var delegate: FileManagerDelegate? {
        NSUnimplemented()
    }
    
    /* setAttributes:ofItemAtPath:error: returns YES when the attributes specified in the 'attributes' dictionary are set successfully on the item specified by 'path'. If this method returns NO, a presentable NSError will be provided by-reference in the 'error' parameter. If no error is required, you may pass 'nil' for the error.
     
        This method replaces changeFileAttributes:atPath:.
     */
    open func setAttributes(_ attributes: [FileAttributeKey : Any], ofItemAtPath path: String) throws {
        for attribute in attributes.keys {
            if attribute == .posixPermissions {
                guard let number = attributes[attribute] as? NSNumber else {
                    fatalError("Can't set file permissions to \(attributes[attribute] as Any?)")
                }
                #if os(OSX) || os(iOS)
                    let modeT = number.uint16Value
                #elseif os(Linux) || os(Android) || CYGWIN
                    let modeT = number.uint32Value
                #endif
                if chmod(path, mode_t(modeT)) != 0 {
                    fatalError("errno \(errno)")
                }
            } else {
                fatalError("Attribute type not implemented: \(attribute)")
            }
        }
    }
    
    /* createDirectoryAtPath:withIntermediateDirectories:attributes:error: creates a directory at the specified path. If you pass 'NO' for createIntermediates, the directory must not exist at the time this call is made. Passing 'YES' for 'createIntermediates' will create any necessary intermediate directories. This method returns YES if all directories specified in 'path' were created and attributes were set. Directories are created with attributes specified by the dictionary passed to 'attributes'. If no dictionary is supplied, directories are created according to the umask of the process. This method returns NO if a failure occurs at any stage of the operation. If an error parameter was provided, a presentable NSError will be returned by reference.
     
        This method replaces createDirectoryAtPath:attributes:
     */
    open func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = [:]) throws {
        if createIntermediates {
            var isDir: ObjCBool = false
            if !fileExists(atPath: path, isDirectory: &isDir) {
                let parent = path._nsObject.deletingLastPathComponent
                if !parent.isEmpty && !fileExists(atPath: parent, isDirectory: &isDir) {
                    try createDirectory(atPath: parent, withIntermediateDirectories: true, attributes: attributes)
                }
                if mkdir(path, S_IRWXU | S_IRWXG | S_IRWXO) != 0 {
                    throw _NSErrorWithErrno(errno, reading: false, path: path)
                } else if let attr = attributes {
                    try self.setAttributes(attr, ofItemAtPath: path)
                }
            } else if isDir.boolValue {
                return
            } else {
                throw _NSErrorWithErrno(EEXIST, reading: false, path: path)
            }
        } else {
            if mkdir(path, S_IRWXU | S_IRWXG | S_IRWXO) != 0 {
                throw _NSErrorWithErrno(errno, reading: false, path: path)
            } else if let attr = attributes {
                try self.setAttributes(attr, ofItemAtPath: path)
            }
        }
    }

    private func _contentsOfDir(atPath path: String, _ closure: (String, Int32) throws -> () ) throws {
        let fsRep = fileSystemRepresentation(withPath: path)
        defer { fsRep.deallocate() }

        guard let dir = opendir(fsRep) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileReadNoSuchFile.rawValue, userInfo: [NSFilePathErrorKey: path])
        }
        defer { closedir(dir) }

        var entry = dirent()
        var result: UnsafeMutablePointer<dirent>? = nil

        while readdir_r(dir, &entry, &result) == 0 {
            guard result != nil else {
                return
            }
            let length = Int(_direntNameLength(&entry))
            let entryName = withUnsafePointer(to: &entry.d_name) { (ptr) -> String in
                let namePtr = UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self)
                return string(withFileSystemRepresentation: namePtr, length: length)
            }
            if entryName != "." && entryName != ".." {
                let entryType = Int32(entry.d_type)
                try closure(entryName, entryType)
            }
        }
    }

    /**
     Performs a shallow search of the specified directory and returns the paths of any contained items.
     
     This method performs a shallow search of the directory and therefore does not traverse symbolic links or return the contents of any subdirectories. This method also does not return URLs for the current directory (“.”), parent directory (“..”) but it does return other hidden files (files that begin with a period character).
     
     The order of the files in the returned array is undefined.
     
     - Parameter path: The path to the directory whose contents you want to enumerate.
     
     - Throws: `NSError` if the directory does not exist, this error is thrown with the associated error code.
     
     - Returns: An array of String each of which identifies a file, directory, or symbolic link contained in `path`. The order of the files returned is undefined.
     */
    open func contentsOfDirectory(atPath path: String) throws -> [String] {
        var contents: [String] = []

        try _contentsOfDir(atPath: path, { (entryName, entryType) throws in
            contents.append(entryName)
        })
        return contents
    }
    
    /**
    Performs a deep enumeration of the specified directory and returns the paths of all of the contained subdirectories.
    
    This method recurses the specified directory and its subdirectories. The method skips the “.” and “..” directories at each level of the recursion.
    
    Because this method recurses the directory’s contents, you might not want to use it in performance-critical code. Instead, consider using the enumeratorAtURL:includingPropertiesForKeys:options:errorHandler: or enumeratorAtPath: method to enumerate the directory contents yourself. Doing so gives you more control over the retrieval of items and more opportunities to abort the enumeration or perform other tasks at the same time.
    
    - Parameter path: The path of the directory to list.
    
    - Throws: `NSError` if the directory does not exist, this error is thrown with the associated error code.
    
    - Returns: An array of NSString objects, each of which contains the path of an item in the directory specified by path. If path is a symbolic link, this method traverses the link. This method returns nil if it cannot retrieve the device of the linked-to file.
    */
    open func subpathsOfDirectory(atPath path: String) throws -> [String] {
        var contents: [String] = []

        try _contentsOfDir(atPath: path, { (entryName, entryType) throws in
            contents.append(entryName)
            if entryType == Int32(DT_DIR) {
                let subPath: String = path + "/" + entryName
                let entries = try subpathsOfDirectory(atPath: subPath)
                contents.append(contentsOf: entries.map({file in "\(entryName)/\(file)"}))
            }
        })
        return contents
    }
    
    /* attributesOfItemAtPath:error: returns an NSDictionary of key/value pairs containing the attributes of the item (file, directory, symlink, etc.) at the path in question. If this method returns 'nil', an NSError will be returned by reference in the 'error' parameter. This method does not traverse a terminal symlink.
     
        This method replaces fileAttributesAtPath:traverseLink:.
     */
    open func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any] {
        var s = stat()
        guard lstat(path, &s) == 0 else {
            throw _NSErrorWithErrno(errno, reading: true, path: path)
        }
        var result = [FileAttributeKey : Any]()
        result[.size] = NSNumber(value: UInt64(s.st_size))

#if os(OSX) || os(iOS)
        let ti = (TimeInterval(s.st_mtimespec.tv_sec) - kCFAbsoluteTimeIntervalSince1970) + (1.0e-9 * TimeInterval(s.st_mtimespec.tv_nsec))
#elseif os(Android)
        let ti = (TimeInterval(s.st_mtime) - kCFAbsoluteTimeIntervalSince1970) + (1.0e-9 * TimeInterval(s.st_mtime_nsec))
#else
        let ti = (TimeInterval(s.st_mtim.tv_sec) - kCFAbsoluteTimeIntervalSince1970) + (1.0e-9 * TimeInterval(s.st_mtim.tv_nsec))
#endif
        result[.modificationDate] = Date(timeIntervalSinceReferenceDate: ti)
        
        result[.posixPermissions] = NSNumber(value: UInt64(s.st_mode & 0o7777))
        result[.referenceCount] = NSNumber(value: UInt64(s.st_nlink))
        result[.systemNumber] = NSNumber(value: UInt64(s.st_dev))
        result[.systemFileNumber] = NSNumber(value: UInt64(s.st_ino))
        
        if let pwd = getpwuid(s.st_uid), pwd.pointee.pw_name != nil {
            let name = String(cString: pwd.pointee.pw_name)
            result[.ownerAccountName] = name
        }
        
        if let grd = getgrgid(s.st_gid), grd.pointee.gr_name != nil {
            let name = String(cString: grd.pointee.gr_name)
            result[.groupOwnerAccountName] = name
        }

        var type : FileAttributeType
        switch s.st_mode & S_IFMT {
            case S_IFCHR: type = .typeCharacterSpecial
            case S_IFDIR: type = .typeDirectory
            case S_IFBLK: type = .typeBlockSpecial
            case S_IFREG: type = .typeRegular
            case S_IFLNK: type = .typeSymbolicLink
            case S_IFSOCK: type = .typeSocket
            default: type = .typeUnknown
        }
        result[.type] = type
        
        if type == .typeBlockSpecial || type == .typeCharacterSpecial {
            result[.deviceIdentifier] = NSNumber(value: UInt64(s.st_rdev))
        }

#if os(OSX) || os(iOS)
        if (s.st_flags & UInt32(UF_IMMUTABLE | SF_IMMUTABLE)) != 0 {
            result[.immutable] = NSNumber(value: true)
        }
        if (s.st_flags & UInt32(UF_APPEND | SF_APPEND)) != 0 {
            result[.appendOnly] = NSNumber(value: true)
        }
#endif
        result[.ownerAccountID] = NSNumber(value: UInt64(s.st_uid))
        result[.groupOwnerAccountID] = NSNumber(value: UInt64(s.st_gid))
        
        return result
    }
    
    /* attributesOfFileSystemForPath:error: returns an NSDictionary of key/value pairs containing the attributes of the filesystem containing the provided path. If this method returns 'nil', an NSError will be returned by reference in the 'error' parameter. This method does not traverse a terminal symlink.
     
        This method replaces fileSystemAttributesAtPath:.
     */
    open func attributesOfFileSystem(forPath path: String) throws -> [FileAttributeKey : Any] {
#if os(Android)
        NSUnimplemented()
#else
        // statvfs(2) doesn't support 64bit inode on Darwin (apfs), fallback to statfs(2)
        #if os(OSX) || os(iOS)
            var s = statfs()
            guard statfs(path, &s) == 0 else {
                throw _NSErrorWithErrno(errno, reading: true, path: path)
            }
        #else
            var s = statvfs()
            guard statvfs(path, &s) == 0 else {
                throw _NSErrorWithErrno(errno, reading: true, path: path)
            }
        #endif
        
        
        var result = [FileAttributeKey : Any]()
        #if os(OSX) || os(iOS)
            let blockSize = UInt64(s.f_bsize)
            result[.systemNumber] = NSNumber(value: UInt64(s.f_fsid.val.0))
        #else
            let blockSize = UInt64(s.f_frsize)
            result[.systemNumber] = NSNumber(value: UInt64(s.f_fsid))
        #endif
        result[.systemSize] = NSNumber(value: blockSize * UInt64(s.f_blocks))
        result[.systemFreeSize] = NSNumber(value: blockSize * UInt64(s.f_bavail))
        result[.systemNodes] = NSNumber(value: UInt64(s.f_files))
        result[.systemFreeNodes] = NSNumber(value: UInt64(s.f_ffree))
        
        return result
#endif
    }
    
    /* createSymbolicLinkAtPath:withDestination:error: returns YES if the symbolic link that point at 'destPath' was able to be created at the location specified by 'path'. If this method returns NO, the link was unable to be created and an NSError will be returned by reference in the 'error' parameter. This method does not traverse a terminal symlink.
     
        This method replaces createSymbolicLinkAtPath:pathContent:
     */
    open func createSymbolicLink(atPath path: String, withDestinationPath destPath: String) throws {
        if symlink(destPath, path) == -1 {
            throw _NSErrorWithErrno(errno, reading: false, path: path)
        }
    }
    
    /* destinationOfSymbolicLinkAtPath:error: returns an NSString containing the path of the item pointed at by the symlink specified by 'path'. If this method returns 'nil', an NSError will be returned by reference in the 'error' parameter.
     
        This method replaces pathContentOfSymbolicLinkAtPath:
     */
    open func destinationOfSymbolicLink(atPath path: String) throws -> String {
        let bufSize = Int(PATH_MAX + 1)
        var buf = [Int8](repeating: 0, count: bufSize)
        let len = readlink(path, &buf, bufSize)
        if len < 0 {
            throw _NSErrorWithErrno(errno, reading: true, path: path)
        }
        
        return self.string(withFileSystemRepresentation: buf, length: Int(len))
    }
    
    open func copyItem(atPath srcPath: String, toPath dstPath: String) throws {
        guard
            let attrs = try? attributesOfItem(atPath: srcPath),
            let fileType = attrs[.type] as? FileAttributeType
            else {
                return
        }
        if fileType == .typeDirectory {
            try createDirectory(atPath: dstPath, withIntermediateDirectories: false, attributes: nil)
            let subpaths = try subpathsOfDirectory(atPath: srcPath)
            for subpath in subpaths {
                try copyItem(atPath: srcPath + "/" + subpath, toPath: dstPath + "/" + subpath)
            }
        } else {
            if createFile(atPath: dstPath, contents: contents(atPath: srcPath), attributes: nil) == false {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnknown.rawValue, userInfo: [NSFilePathErrorKey : NSString(string: dstPath)])
            }
        }
    }
    
    open func moveItem(atPath srcPath: String, toPath dstPath: String) throws {
        guard !self.fileExists(atPath: dstPath) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteFileExists.rawValue, userInfo: [NSFilePathErrorKey : NSString(dstPath)])
        }
        if rename(srcPath, dstPath) != 0 {
            if errno == EXDEV {
                // TODO: Copy and delete.
                NSUnimplemented("Cross-device moves not yet implemented")
            } else {
                throw _NSErrorWithErrno(errno, reading: false, path: srcPath)
            }
        }
    }
    
    open func linkItem(atPath srcPath: String, toPath dstPath: String) throws {
        var isDir: ObjCBool = false
        if self.fileExists(atPath: srcPath, isDirectory: &isDir) {
            if !isDir.boolValue {
                // TODO: Symlinks should be copied instead of hard-linked.
                if link(srcPath, dstPath) == -1 {
                    throw _NSErrorWithErrno(errno, reading: false, path: srcPath)
                }
            } else {
                // TODO: Recurse through directories, copying them.
                NSUnimplemented("Recursive linking not yet implemented")
            }
        }
    }

    open func removeItem(atPath path: String) throws {
        if rmdir(path) == 0 {
            return
        } else if errno == ENOTEMPTY {

            let fsRep = FileManager.default.fileSystemRepresentation(withPath: path)
            let ps = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: 2)
            ps.initialize(to: UnsafeMutablePointer(mutating: fsRep))
            ps.advanced(by: 1).initialize(to: nil)
            let stream = fts_open(ps, FTS_PHYSICAL | FTS_XDEV | FTS_NOCHDIR, nil)
            ps.deinitialize(count: 2)
            ps.deallocate()
            fsRep.deallocate()

            if stream != nil {
                defer {
                    fts_close(stream)
                }

                var current = fts_read(stream)
                while current != nil {
                    switch Int32(current!.pointee.fts_info) {
                        case FTS_DEFAULT, FTS_F, FTS_NSOK, FTS_SL, FTS_SLNONE:
                            if unlink(current!.pointee.fts_path) == -1 {
                                let str = NSString(bytes: current!.pointee.fts_path, length: Int(strlen(current!.pointee.fts_path)), encoding: String.Encoding.utf8.rawValue)!._swiftObject
                                throw _NSErrorWithErrno(errno, reading: false, path: str)
                            }
                        case FTS_DP:
                            if rmdir(current!.pointee.fts_path) == -1 {
                                let str = NSString(bytes: current!.pointee.fts_path, length: Int(strlen(current!.pointee.fts_path)), encoding: String.Encoding.utf8.rawValue)!._swiftObject
                                throw _NSErrorWithErrno(errno, reading: false, path: str)
                            }
                        default:
                            break
                    }
                    current = fts_read(stream)
                }
            } else {
                let _ = _NSErrorWithErrno(ENOTEMPTY, reading: false, path: path)
            }
            // TODO: Error handling if fts_read fails.

        } else if errno != ENOTDIR {
            throw _NSErrorWithErrno(errno, reading: false, path: path)
        } else if unlink(path) != 0 {
            throw _NSErrorWithErrno(errno, reading: false, path: path)
        }
    }
    
    open func copyItem(at srcURL: URL, to dstURL: URL) throws {
        guard srcURL.isFileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnsupportedScheme.rawValue, userInfo: [NSURLErrorKey : srcURL])
        }
        guard dstURL.isFileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnsupportedScheme.rawValue, userInfo: [NSURLErrorKey : dstURL])
        }
        try copyItem(atPath: srcURL.path, toPath: dstURL.path)
    }
    
    open func moveItem(at srcURL: URL, to dstURL: URL) throws {
        guard srcURL.isFileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnsupportedScheme.rawValue, userInfo: [NSURLErrorKey : srcURL])
        }
        guard dstURL.isFileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnsupportedScheme.rawValue, userInfo: [NSURLErrorKey : dstURL])
        }
        try moveItem(atPath: srcURL.path, toPath: dstURL.path)
    }
    
    open func linkItem(at srcURL: URL, to dstURL: URL) throws {
        guard srcURL.isFileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnsupportedScheme.rawValue, userInfo: [NSURLErrorKey : srcURL])
        }
        guard dstURL.isFileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnsupportedScheme.rawValue, userInfo: [NSURLErrorKey : dstURL])
        }
        try linkItem(atPath: srcURL.path, toPath: dstURL.path)
    }
    
    open func removeItem(at url: URL) throws {
        guard url.isFileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnsupportedScheme.rawValue, userInfo: [NSURLErrorKey : url])
        }
        try self.removeItem(atPath: url.path)
    }
    
    /* Process working directory management. Despite the fact that these are instance methods on FileManager, these methods report and change (respectively) the working directory for the entire process. Developers are cautioned that doing so is fraught with peril.
     */
    open var currentDirectoryPath: String {
        let length = Int(PATH_MAX) + 1
        var buf = [Int8](repeating: 0, count: length)
        getcwd(&buf, length)
        let result = self.string(withFileSystemRepresentation: buf, length: Int(strlen(buf)))
        return result
    }
    
    @discardableResult
    open func changeCurrentDirectoryPath(_ path: String) -> Bool {
        return chdir(path) == 0
    }
    
    /* The following methods are of limited utility. Attempting to predicate behavior based on the current state of the filesystem or a particular file on the filesystem is encouraging odd behavior in the face of filesystem race conditions. It's far better to attempt an operation (like loading a file or creating a directory) and handle the error gracefully than it is to try to figure out ahead of time whether the operation will succeed.
     */
    open func fileExists(atPath path: String) -> Bool {
        return self.fileExists(atPath: path, isDirectory: nil)
    }
    
    open func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        var s = stat()
        if lstat(path, &s) >= 0 {
            if let isDirectory = isDirectory {
                if (s.st_mode & S_IFMT) == S_IFLNK {
                    if stat(path, &s) >= 0 {
                        isDirectory.pointee = ObjCBool((s.st_mode & S_IFMT) == S_IFDIR)
                    } else {
                        return false
                    }
                } else {
                    let isDir = (s.st_mode & S_IFMT) == S_IFDIR
                    isDirectory.pointee = ObjCBool(isDir)
                }
            }

            // don't chase the link for this magic case -- we might be /Net/foo
            // which is a symlink to /private/Net/foo which is not yet mounted...
            if (s.st_mode & S_IFMT) == S_IFLNK {
                if (s.st_mode & S_ISVTX) == S_ISVTX {
                    return true
                }
                // chase the link; too bad if it is a slink to /Net/foo
                stat(path, &s)
            }
        } else {
            return false
        }
        return true
    }
    
    open func isReadableFile(atPath path: String) -> Bool {
        return access(path, R_OK) == 0
    }
    
    open func isWritableFile(atPath path: String) -> Bool {
        return access(path, W_OK) == 0
    }
    
    open func isExecutableFile(atPath path: String) -> Bool {
        return access(path, X_OK) == 0
    }
    
    open func isDeletableFile(atPath path: String) -> Bool {
        NSUnimplemented()
    }
    
    /* -contentsEqualAtPath:andPath: does not take into account data stored in the resource fork or filesystem extended attributes.
     */
    open func contentsEqual(atPath path1: String, andPath path2: String) -> Bool {
        NSUnimplemented()
    }
    
    /* displayNameAtPath: returns an NSString suitable for presentation to the user. For directories which have localization information, this will return the appropriate localized string. This string is not suitable for passing to anything that must interact with the filesystem.
     */
    open func displayName(atPath path: String) -> String {
        NSUnimplemented()
    }
    
    /* componentsToDisplayForPath: returns an NSArray of display names for the path provided. Localization will occur as in displayNameAtPath: above. This array cannot and should not be reassembled into an usable filesystem path for any kind of access.
     */
    open func componentsToDisplay(forPath path: String) -> [String]? {
        NSUnimplemented()
    }
    
    /* enumeratorAtPath: returns an NSDirectoryEnumerator rooted at the provided path. If the enumerator cannot be created, this returns NULL. Because NSDirectoryEnumerator is a subclass of NSEnumerator, the returned object can be used in the for...in construct.
     */
    open func enumerator(atPath path: String) -> DirectoryEnumerator? {
        return NSPathDirectoryEnumerator(path: path)
    }
    
    /* enumeratorAtURL:includingPropertiesForKeys:options:errorHandler: returns an NSDirectoryEnumerator rooted at the provided directory URL. The NSDirectoryEnumerator returns NSURLs from the -nextObject method. The optional 'includingPropertiesForKeys' parameter indicates which resource properties should be pre-fetched and cached with each enumerated URL. The optional 'errorHandler' block argument is invoked when an error occurs. Parameters to the block are the URL on which an error occurred and the error. When the error handler returns YES, enumeration continues if possible. Enumeration stops immediately when the error handler returns NO.
    
        If you wish to only receive the URLs and no other attributes, then pass '0' for 'options' and an empty NSArray ('[NSArray array]') for 'keys'. If you wish to have the property caches of the vended URLs pre-populated with a default set of attributes, then pass '0' for 'options' and 'nil' for 'keys'.
     */
    // Note: Because the error handler is an optional block, the compiler treats it as @escaping by default. If that behavior changes, the @escaping will need to be added back.
    open func enumerator(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: DirectoryEnumerationOptions = [], errorHandler handler: (/* @escaping */ (URL, Error) -> Bool)? = nil) -> DirectoryEnumerator? {
        if mask.contains(.skipsPackageDescendants) || mask.contains(.skipsHiddenFiles) {
            NSUnimplemented("Enumeration options not yet implemented")
        }
        return NSURLDirectoryEnumerator(url: url, options: mask, errorHandler: handler)
    }
    
    /* subpathsAtPath: returns an NSArray of all contents and subpaths recursively from the provided path. This may be very expensive to compute for deep filesystem hierarchies, and should probably be avoided.
     */
    open func subpaths(atPath path: String) -> [String]? {
        NSUnimplemented()
    }
    
    /* These methods are provided here for compatibility. The corresponding methods on NSData which return NSErrors should be regarded as the primary method of creating a file from an NSData or retrieving the contents of a file as an NSData.
     */
    open func contents(atPath path: String) -> Data? {
        do {
            return try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            return nil
        }
    }
    
    open func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
        do {
            try (data ?? Data()).write(to: URL(fileURLWithPath: path), options: .atomic)
            if let attr = attr {
                try self.setAttributes(attr, ofItemAtPath: path)
            }
            return true
        } catch _ {
            return false
        }
    }
    
    /* fileSystemRepresentationWithPath: returns an array of characters suitable for passing to lower-level POSIX style APIs. The string is provided in the representation most appropriate for the filesystem in question.
     */
    open func fileSystemRepresentation(withPath path: String) -> UnsafePointer<Int8> {
        precondition(path != "", "Empty path argument")
        let len = CFStringGetMaximumSizeOfFileSystemRepresentation(path._cfObject)
        if len == kCFNotFound {
            fatalError("string could not be converted")
        }
        let buf = UnsafeMutablePointer<Int8>.allocate(capacity: len)
        for i in 0..<len {
            buf.advanced(by: i).initialize(to: 0)
        }
        if !path._nsObject.getFileSystemRepresentation(buf, maxLength: len) {
            buf.deinitialize(count: len)
            buf.deallocate()
            fatalError("string could not be converted")
        }
        return UnsafePointer(buf)
    }
    
    /* stringWithFileSystemRepresentation:length: returns an NSString created from an array of bytes that are in the filesystem representation.
     */
    open func string(withFileSystemRepresentation str: UnsafePointer<Int8>, length len: Int) -> String {
        return NSString(bytes: str, length: len, encoding: String.Encoding.utf8.rawValue)!._swiftObject
    }
    
    /* -replaceItemAtURL:withItemAtURL:backupItemName:options:resultingItemURL:error: is for developers who wish to perform a safe-save without using the full NSDocument machinery that is available in the AppKit.
     
        The `originalItemURL` is the item being replaced.
        `newItemURL` is the item which will replace the original item. This item should be placed in a temporary directory as provided by the OS, or in a uniquely named directory placed in the same directory as the original item if the temporary directory is not available.
        If `backupItemName` is provided, that name will be used to create a backup of the original item. The backup is placed in the same directory as the original item. If an error occurs during the creation of the backup item, the operation will fail. If there is already an item with the same name as the backup item, that item will be removed. The backup item will be removed in the event of success unless the `NSFileManagerItemReplacementWithoutDeletingBackupItem` option is provided in `options`.
        For `options`, pass `0` to get the default behavior, which uses only the metadata from the new item while adjusting some properties using values from the original item. Pass `NSFileManagerItemReplacementUsingNewMetadataOnly` in order to use all possible metadata from the new item.
     */
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    open func replaceItem(at originalItemURL: URL, withItemAt newItemURL: URL, backupItemName: String?, options: ItemReplacementOptions = []) throws {
        NSUnimplemented()
    }
    
    internal func _tryToResolveTrailingSymlinkInPath(_ path: String) -> String? {
        guard _pathIsSymbolicLink(path) else {
            return nil
        }
        
        guard let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: path) else {
            return nil
        }
        
        return _appendSymlinkDestination(destination, toPath: path)
    }
    
    internal func _appendSymlinkDestination(_ dest: String, toPath: String) -> String {
        if dest.hasPrefix("/") {
            return dest
        } else {
            let temp = toPath._bridgeToObjectiveC().deletingLastPathComponent
            return temp._bridgeToObjectiveC().appendingPathComponent(dest)
        }
    }
    
    internal func _pathIsSymbolicLink(_ path: String) -> Bool {
        guard
            let attrs = try? attributesOfItem(atPath: path),
            let fileType = attrs[.type] as? FileAttributeType
        else {
            return false
        }
        return fileType == .typeSymbolicLink
    }
}

extension FileManager {
    public func replaceItemAt(_ originalItemURL: URL, withItemAt newItemURL: URL, backupItemName: String? = nil, options: ItemReplacementOptions = []) throws -> NSURL? {
        NSUnimplemented()
    }
}

extension FileManager {
    open var homeDirectoryForCurrentUser: URL {
        return homeDirectory(forUser: NSUserName())!
    }
    
    open var temporaryDirectory: URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }
    
    open func homeDirectory(forUser userName: String) -> URL? {
        guard !userName.isEmpty else { return nil }
        guard let url = CFCopyHomeDirectoryURLForUser(userName._cfObject) else { return nil }
        return  url.takeRetainedValue()._swiftObject
    }
}

extension FileManager {
    public struct VolumeEnumerationOptions : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        /* The mounted volume enumeration will skip hidden volumes.
         */
        public static let skipHiddenVolumes = VolumeEnumerationOptions(rawValue: 1 << 1)

        /* The mounted volume enumeration will produce file reference URLs rather than path-based URLs.
         */
        public static let produceFileReferenceURLs = VolumeEnumerationOptions(rawValue: 1 << 2)
    }
    
    public struct DirectoryEnumerationOptions : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        /* NSDirectoryEnumerationSkipsSubdirectoryDescendants causes the NSDirectoryEnumerator to perform a shallow enumeration and not descend into directories it encounters.
         */
        public static let skipsSubdirectoryDescendants = DirectoryEnumerationOptions(rawValue: 1 << 0)

        /* NSDirectoryEnumerationSkipsPackageDescendants will cause the NSDirectoryEnumerator to not descend into packages.
         */
        public static let skipsPackageDescendants = DirectoryEnumerationOptions(rawValue: 1 << 1)

        /* NSDirectoryEnumerationSkipsHiddenFiles causes the NSDirectoryEnumerator to not enumerate hidden files.
         */
        public static let skipsHiddenFiles = DirectoryEnumerationOptions(rawValue: 1 << 2)
    }

    public struct ItemReplacementOptions : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        /* Causes -replaceItemAtURL:withItemAtURL:backupItemName:options:resultingItemURL:error: to use metadata from the new item only and not to attempt to preserve metadata from the original item.
         */
        public static let usingNewMetadataOnly = ItemReplacementOptions(rawValue: 1 << 0)

        /* Causes -replaceItemAtURL:withItemAtURL:backupItemName:options:resultingItemURL:error: to leave the backup item in place after a successful replacement. The default behavior is to remove the item.
         */
        public static let withoutDeletingBackupItem = ItemReplacementOptions(rawValue: 1 << 1)
    }

    public enum URLRelationship : Int {
        case contains
        case same
        case other
    }
}

public struct FileAttributeKey : RawRepresentable, Equatable, Hashable {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
    
    public static func ==(_ lhs: FileAttributeKey, _ rhs: FileAttributeKey) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public static let type = FileAttributeKey(rawValue: "NSFileType")
    public static let size = FileAttributeKey(rawValue: "NSFileSize")
    public static let modificationDate = FileAttributeKey(rawValue: "NSFileModificationDate")
    public static let referenceCount = FileAttributeKey(rawValue: "NSFileReferenceCount")
    public static let deviceIdentifier = FileAttributeKey(rawValue: "NSFileDeviceIdentifier")
    public static let ownerAccountName = FileAttributeKey(rawValue: "NSFileOwnerAccountName")
    public static let groupOwnerAccountName = FileAttributeKey(rawValue: "NSFileGroupOwnerAccountName")
    public static let posixPermissions = FileAttributeKey(rawValue: "NSFilePosixPermissions")
    public static let systemNumber = FileAttributeKey(rawValue: "NSFileSystemNumber")
    public static let systemFileNumber = FileAttributeKey(rawValue: "NSFileSystemFileNumber")
    public static let extensionHidden = FileAttributeKey(rawValue: "NSFileExtensionHidden")
    public static let hfsCreatorCode = FileAttributeKey(rawValue: "NSFileHFSCreatorCode")
    public static let hfsTypeCode = FileAttributeKey(rawValue: "NSFileHFSTypeCode")
    public static let immutable = FileAttributeKey(rawValue: "NSFileImmutable")
    public static let appendOnly = FileAttributeKey(rawValue: "NSFileAppendOnly")
    public static let creationDate = FileAttributeKey(rawValue: "NSFileCreationDate")
    public static let ownerAccountID = FileAttributeKey(rawValue: "NSFileOwnerAccountID")
    public static let groupOwnerAccountID = FileAttributeKey(rawValue: "NSFileGroupOwnerAccountID")
    public static let busy = FileAttributeKey(rawValue: "NSFileBusy")
    public static let systemSize = FileAttributeKey(rawValue: "NSFileSystemSize")
    public static let systemFreeSize = FileAttributeKey(rawValue: "NSFileSystemFreeSize")
    public static let systemNodes = FileAttributeKey(rawValue: "NSFileSystemNodes")
    public static let systemFreeNodes = FileAttributeKey(rawValue: "NSFileSystemFreeNodes")
}

public struct FileAttributeType : RawRepresentable, Equatable, Hashable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var hashValue: Int {
        return self.rawValue.hashValue
    }

    public static func ==(_ lhs: FileAttributeType, _ rhs: FileAttributeType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public static let typeDirectory = FileAttributeType(rawValue: "NSFileTypeDirectory")
    public static let typeRegular = FileAttributeType(rawValue: "NSFileTypeRegular")
    public static let typeSymbolicLink = FileAttributeType(rawValue: "NSFileTypeSymbolicLink")
    public static let typeSocket = FileAttributeType(rawValue: "NSFileTypeSocket")
    public static let typeCharacterSpecial = FileAttributeType(rawValue: "NSFileTypeCharacterSpecial")
    public static let typeBlockSpecial = FileAttributeType(rawValue: "NSFileTypeBlockSpecial")
    public static let typeUnknown = FileAttributeType(rawValue: "NSFileTypeUnknown")
}

public protocol FileManagerDelegate : NSObjectProtocol {
    
    /* fileManager:shouldCopyItemAtPath:toPath: gives the delegate an opportunity to filter the resulting copy. Returning YES from this method will allow the copy to happen. Returning NO from this method causes the item in question to be skipped. If the item skipped was a directory, no children of that directory will be copied, nor will the delegate be notified of those children.
     */
    func fileManager(_ fileManager: FileManager, shouldCopyItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(_ fileManager: FileManager, shouldCopyItemAt srcURL: URL, to dstURL: URL) -> Bool
    
    /* fileManager:shouldProceedAfterError:copyingItemAtPath:toPath: gives the delegate an opportunity to recover from or continue copying after an error. If an error occurs, the error object will contain an NSError indicating the problem. The source path and destination paths are also provided. If this method returns YES, the FileManager instance will continue as if the error had not occurred. If this method returns NO, the FileManager instance will stop copying, return NO from copyItemAtPath:toPath:error: and the error will be provided there.
     */
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAt srcURL: URL, to dstURL: URL) -> Bool
    
    /* fileManager:shouldMoveItemAtPath:toPath: gives the delegate an opportunity to not move the item at the specified path. If the source path and the destination path are not on the same device, a copy is performed to the destination path and the original is removed. If the copy does not succeed, an error is returned and the incomplete copy is removed, leaving the original in place.
    
     */
    func fileManager(_ fileManager: FileManager, shouldMoveItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(_ fileManager: FileManager, shouldMoveItemAt srcURL: URL, to dstURL: URL) -> Bool
    
    /* fileManager:shouldProceedAfterError:movingItemAtPath:toPath: functions much like fileManager:shouldProceedAfterError:copyingItemAtPath:toPath: above. The delegate has the opportunity to remedy the error condition and allow the move to continue.
     */
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, movingItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, movingItemAt srcURL: URL, to dstURL: URL) -> Bool
    
    /* fileManager:shouldLinkItemAtPath:toPath: acts as the other "should" methods, but this applies to the file manager creating hard links to the files in question.
     */
    func fileManager(_ fileManager: FileManager, shouldLinkItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(_ fileManager: FileManager, shouldLinkItemAt srcURL: URL, to dstURL: URL) -> Bool
    
    /* fileManager:shouldProceedAfterError:linkingItemAtPath:toPath: allows the delegate an opportunity to remedy the error which occurred in linking srcPath to dstPath. If the delegate returns YES from this method, the linking will continue. If the delegate returns NO from this method, the linking operation will stop and the error will be returned via linkItemAtPath:toPath:error:.
     */
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, linkingItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, linkingItemAt srcURL: URL, to dstURL: URL) -> Bool
    
    /* fileManager:shouldRemoveItemAtPath: allows the delegate the opportunity to not remove the item at path. If the delegate returns YES from this method, the FileManager instance will attempt to remove the item. If the delegate returns NO from this method, the remove skips the item. If the item is a directory, no children of that item will be visited.
     */
    func fileManager(_ fileManager: FileManager, shouldRemoveItemAtPath path: String) -> Bool
    func fileManager(_ fileManager: FileManager, shouldRemoveItemAt URL: URL) -> Bool
    
    /* fileManager:shouldProceedAfterError:removingItemAtPath: allows the delegate an opportunity to remedy the error which occurred in removing the item at the path provided. If the delegate returns YES from this method, the removal operation will continue. If the delegate returns NO from this method, the removal operation will stop and the error will be returned via linkItemAtPath:toPath:error:.
     */
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, removingItemAtPath path: String) -> Bool
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, removingItemAt URL: URL) -> Bool
}

extension FileManagerDelegate {
    func fileManager(_ fileManager: FileManager, shouldCopyItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return true }
    func fileManager(_ fileManager: FileManager, shouldCopyItemAtURL srcURL: URL, toURL dstURL: URL) -> Bool { return true }

    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return false }
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, copyingItemAtURL srcURL: URL, toURL dstURL: URL) -> Bool { return false }

    func fileManager(_ fileManager: FileManager, shouldMoveItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return true }
    func fileManager(_ fileManager: FileManager, shouldMoveItemAtURL srcURL: URL, toURL dstURL: URL) -> Bool { return true }

    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, movingItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return false }
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, movingItemAtURL srcURL: URL, toURL dstURL: URL) -> Bool { return false }

    func fileManager(_ fileManager: FileManager, shouldLinkItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return true }
    func fileManager(_ fileManager: FileManager, shouldLinkItemAtURL srcURL: URL, toURL dstURL: URL) -> Bool { return true }

    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, linkingItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return false }
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, linkingItemAtURL srcURL: URL, toURL dstURL: URL) -> Bool { return false }

    func fileManager(_ fileManager: FileManager, shouldRemoveItemAtPath path: String) -> Bool { return true }
    func fileManager(_ fileManager: FileManager, shouldRemoveItemAtURL url: URL) -> Bool { return true }

    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, removingItemAtPath path: String) -> Bool { return false }
    func fileManager(_ fileManager: FileManager, shouldProceedAfterError error: Error, removingItemAtURL url: URL) -> Bool { return false }
}

extension FileManager {
    open class DirectoryEnumerator : NSEnumerator {
        
        /* For NSDirectoryEnumerators created with -enumeratorAtPath:, the -fileAttributes and -directoryAttributes methods return an NSDictionary containing the keys listed below. For NSDirectoryEnumerators created with -enumeratorAtURL:includingPropertiesForKeys:options:errorHandler:, these two methods return nil.
         */
        open var fileAttributes: [FileAttributeKey : Any]? {
            NSRequiresConcreteImplementation()
        }
        open var directoryAttributes: [FileAttributeKey : Any]? {
            NSRequiresConcreteImplementation()
        }
        
        /* This method returns the number of levels deep the current object is in the directory hierarchy being enumerated. The directory passed to -enumeratorAtURL:includingPropertiesForKeys:options:errorHandler: is considered to be level 0.
         */
        open var level: Int {
            NSRequiresConcreteImplementation()
        }
        
        open func skipDescendants() {
            NSRequiresConcreteImplementation()
        }
    }

    internal class NSPathDirectoryEnumerator: DirectoryEnumerator {
        let baseURL: URL
        let innerEnumerator : DirectoryEnumerator
        override var fileAttributes: [FileAttributeKey : Any]? {
            NSUnimplemented()
        }
        override var directoryAttributes: [FileAttributeKey : Any]? {
            NSUnimplemented()
        }
        
        override var level: Int {
            NSUnimplemented()
        }
        
        override func skipDescendants() {
            NSUnimplemented()
        }
        
        init?(path: String) {
            let url = URL(fileURLWithPath: path)
            self.baseURL = url
            guard let ie = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil, options: [], errorHandler: nil) else {
                return nil
            }
            self.innerEnumerator = ie
        }
        
        override func nextObject() -> Any? {
            let o = innerEnumerator.nextObject()
            guard let url = o as? URL else {
                return nil
            }
            let path = url.path.replacingOccurrences(of: baseURL.path+"/", with: "")
            return path
        }

    }

    internal class NSURLDirectoryEnumerator : DirectoryEnumerator {
        var _url : URL
        var _options : FileManager.DirectoryEnumerationOptions
        var _errorHandler : ((URL, Error) -> Bool)?
        var _stream : UnsafeMutablePointer<FTS>? = nil
        var _current : UnsafeMutablePointer<FTSENT>? = nil
        var _rootError : Error? = nil
        var _gotRoot : Bool = false
        
        // See @escaping comments above.
        init(url: URL, options: FileManager.DirectoryEnumerationOptions, errorHandler: (/* @escaping */ (URL, Error) -> Bool)?) {
            _url = url
            _options = options
            _errorHandler = errorHandler
            
            if FileManager.default.fileExists(atPath: _url.path) {
                let fsRep = FileManager.default.fileSystemRepresentation(withPath: _url.path)
                let ps = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: 2)
                ps.initialize(to: UnsafeMutablePointer(mutating: fsRep))
                ps.advanced(by: 1).initialize(to: nil)
                _stream = fts_open(ps, FTS_PHYSICAL | FTS_XDEV | FTS_NOCHDIR, nil)
                ps.deinitialize(count: 2)
                ps.deallocate()
                fsRep.deallocate()
            } else {
                _rootError = _NSErrorWithErrno(ENOENT, reading: true, url: url)
            }
        }
        
        deinit {
            if let stream = _stream {
                fts_close(stream)
            }
        }
        
        override func nextObject() -> Any? {
            if let stream = _stream {
                
                if !_gotRoot  {
                    _gotRoot = true
                    
                    // Skip the root.
                    _current = fts_read(stream)
                    
                }

                _current = fts_read(stream)
                while let current = _current {
                    switch Int32(current.pointee.fts_info) {
                        case FTS_D:
                            if _options.contains(.skipsSubdirectoryDescendants) {
                                fts_set(_stream, _current, FTS_SKIP)
                            }
                            fallthrough
                        case FTS_DEFAULT, FTS_F, FTS_NSOK, FTS_SL, FTS_SLNONE:
                            let str = NSString(bytes: current.pointee.fts_path, length: Int(strlen(current.pointee.fts_path)), encoding: String.Encoding.utf8.rawValue)!._swiftObject
                            return URL(fileURLWithPath: str)
                        case FTS_DNR, FTS_ERR, FTS_NS:
                            let keepGoing : Bool
                            if let handler = _errorHandler {
                                let str = NSString(bytes: current.pointee.fts_path, length: Int(strlen(current.pointee.fts_path)), encoding: String.Encoding.utf8.rawValue)!._swiftObject
                                keepGoing = handler(URL(fileURLWithPath: str), _NSErrorWithErrno(current.pointee.fts_errno, reading: true))
                            } else {
                                keepGoing = true
                            }
                            if !keepGoing {
                                fts_close(stream)
                                _stream = nil
                                return nil
                            }
                        default:
                            break
                    }
                    _current = fts_read(stream)
                }
                // TODO: Error handling if fts_read fails.
                
            } else if let error = _rootError {
                // Was there an error opening the stream?
                if let handler = _errorHandler {
                    let _ = handler(_url, error)
                }
            }
            return nil
        }
        
        override var directoryAttributes : [FileAttributeKey : Any]? {
            return nil
        }
        
        override var fileAttributes: [FileAttributeKey : Any]? {
            return nil
        }
        
        override var level: Int {
            return Int(_current?.pointee.fts_level ?? 0)
        }
        
        override func skipDescendants() {
            if let stream = _stream, let current = _current {
                fts_set(stream, current, FTS_SKIP)
            }
        }
    }
}
