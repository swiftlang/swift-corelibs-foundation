// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

import CoreFoundation

public struct NSVolumeEnumerationOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    /* The mounted volume enumeration will skip hidden volumes.
     */
    public static let SkipHiddenVolumes = NSVolumeEnumerationOptions(rawValue: 1 << 1)
    
    /* The mounted volume enumeration will produce file reference URLs rather than path-based URLs.
     */
    public static let ProduceFileReferenceURLs = NSVolumeEnumerationOptions(rawValue: 1 << 2)
}

public struct NSDirectoryEnumerationOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    /* NSDirectoryEnumerationSkipsSubdirectoryDescendants causes the NSDirectoryEnumerator to perform a shallow enumeration and not descend into directories it encounters.
     */
    public static let SkipsSubdirectoryDescendants = NSDirectoryEnumerationOptions(rawValue: 1 << 0)
    
    /* NSDirectoryEnumerationSkipsPackageDescendants will cause the NSDirectoryEnumerator to not descend into packages.
     */
    public static let SkipsPackageDescendants = NSDirectoryEnumerationOptions(rawValue: 1 << 1)
    
    /* NSDirectoryEnumerationSkipsHiddenFiles causes the NSDirectoryEnumerator to not enumerate hidden files.
     */
    public static let SkipsHiddenFiles = NSDirectoryEnumerationOptions(rawValue: 1 << 2)
}

public struct NSFileManagerItemReplacementOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    /* NSFileManagerItemReplacementUsingNewMetadataOnly causes -replaceItemAtURL:withItemAtURL:backupItemName:options:resultingItemURL:error: to use metadata from the new item only and not to attempt to preserve metadata from the original item.
     */
    public static let UsingNewMetadataOnly = NSFileManagerItemReplacementOptions(rawValue: 1 << 0)
    
    /* NSFileManagerItemReplacementWithoutDeletingBackupItem causes -replaceItemAtURL:withItemAtURL:backupItemName:options:resultingItemURL:error: to leave the backup item in place after a successful replacement. The default behavior is to remove the item.
     */
    public static let WithoutDeletingBackupItem = NSFileManagerItemReplacementOptions(rawValue: 1 << 1)
}

public enum NSURLRelationship : Int {
    case Contains
    case Same
    case Other
}

public class NSFileManager : NSObject {
    
    /* Returns the default singleton instance.
    */
    internal static let defaultInstance = NSFileManager()
    public class func defaultManager() -> NSFileManager {
        return defaultInstance
    }
    
    /* Returns an NSArray of NSURLs locating the mounted volumes available on the computer. The property keys that can be requested are available in NSURL.
     */
    public func mountedVolumeURLsIncludingResourceValuesForKeys(propertyKeys: [String]?, options: NSVolumeEnumerationOptions) -> [NSURL]? {
        NSUnimplemented()
    }
    
    /* Returns an NSArray of NSURLs identifying the the directory entries. 
    
        If the directory contains no entries, this method will return the empty array. When an array is specified for the 'keys' parameter, the specified property values will be pre-fetched and cached with each enumerated URL.
     
        This method always does a shallow enumeration of the specified directory (i.e. it always acts as if NSDirectoryEnumerationSkipsSubdirectoryDescendants has been specified). If you need to perform a deep enumeration, use -[NSFileManager enumeratorAtURL:includingPropertiesForKeys:options:errorHandler:].
     
        If you wish to only receive the URLs and no other attributes, then pass '0' for 'options' and an empty NSArray ('[NSArray array]') for 'keys'. If you wish to have the property caches of the vended URLs pre-populated with a default set of attributes, then pass '0' for 'options' and 'nil' for 'keys'.
     */
    public func contentsOfDirectoryAtURL(url: NSURL, includingPropertiesForKeys keys: [String]?, options mask: NSDirectoryEnumerationOptions) throws -> [NSURL] {
        var error : NSError? = nil
        let e = self.enumeratorAtURL(url, includingPropertiesForKeys: keys, options: mask.union(.SkipsSubdirectoryDescendants)) { (url, err) -> Bool in
            error = err
            return false
        }
        var result = [NSURL]()
        if let e = e {
            for url in e {
                result.append(url as! NSURL)
            }
            if let error = error {
                throw error
            }
        }
        return result
    }
    
    /* -URLsForDirectory:inDomains: is analogous to NSSearchPathForDirectoriesInDomains(), but returns an array of NSURL instances for use with URL-taking APIs. This API is suitable when you need to search for a file or files which may live in one of a variety of locations in the domains specified.
     */
    public func URLsForDirectory(directory: NSSearchPathDirectory, inDomains domainMask: NSSearchPathDomainMask) -> [NSURL] {
        NSUnimplemented()
    }
    
    /* -URLForDirectory:inDomain:appropriateForURL:create:error: is a URL-based replacement for FSFindFolder(). It allows for the specification and (optional) creation of a specific directory for a particular purpose (e.g. the replacement of a particular item on disk, or a particular Library directory.
     
        You may pass only one of the values from the NSSearchPathDomainMask enumeration, and you may not pass NSAllDomainsMask.
     */
    public func URLForDirectory(directory: NSSearchPathDirectory, inDomain domain: NSSearchPathDomainMask, appropriateForURL url: NSURL?, create shouldCreate: Bool) throws -> NSURL {
        NSUnimplemented()
    }
    
    /* Sets 'outRelationship' to NSURLRelationshipContains if the directory at 'directoryURL' directly or indirectly contains the item at 'otherURL', meaning 'directoryURL' is found while enumerating parent URLs starting from 'otherURL'. Sets 'outRelationship' to NSURLRelationshipSame if 'directoryURL' and 'otherURL' locate the same item, meaning they have the same NSURLFileResourceIdentifierKey value. If 'directoryURL' is not a directory, or does not contain 'otherURL' and they do not locate the same file, then sets 'outRelationship' to NSURLRelationshipOther. If an error occurs, returns NO and sets 'error'.
     */
    public func getRelationship(outRelationship: UnsafeMutablePointer<NSURLRelationship>, ofDirectoryAtURL directoryURL: NSURL, toItemAtURL otherURL: NSURL) throws {
        NSUnimplemented()
    }
    
    /* Similar to -[NSFileManager getRelationship:ofDirectoryAtURL:toItemAtURL:error:], except that the directory is instead defined by an NSSearchPathDirectory and NSSearchPathDomainMask. Pass 0 for domainMask to instruct the method to automatically choose the domain appropriate for 'url'. For example, to discover if a file is contained by a Trash directory, call [fileManager getRelationship:&result ofDirectory:NSTrashDirectory inDomain:0 toItemAtURL:url error:&error].
     */
    public func getRelationship(outRelationship: UnsafeMutablePointer<NSURLRelationship>, ofDirectory directory: NSSearchPathDirectory, inDomain domainMask: NSSearchPathDomainMask, toItemAtURL url: NSURL) throws {
        NSUnimplemented()
    }
    
    /* createDirectoryAtURL:withIntermediateDirectories:attributes:error: creates a directory at the specified URL. If you pass 'NO' for withIntermediateDirectories, the directory must not exist at the time this call is made. Passing 'YES' for withIntermediateDirectories will create any necessary intermediate directories. This method returns YES if all directories specified in 'url' were created and attributes were set. Directories are created with attributes specified by the dictionary passed to 'attributes'. If no dictionary is supplied, directories are created according to the umask of the process. This method returns NO if a failure occurs at any stage of the operation. If an error parameter was provided, a presentable NSError will be returned by reference.
     */
    public func createDirectoryAtURL(url: NSURL, withIntermediateDirectories createIntermediates: Bool, attributes: [String : AnyObject]?) throws {
        guard url.fileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnsupportedSchemeError.rawValue, userInfo: [NSURLErrorKey : url])
        }
        guard let path = url.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: nil)
        }
        try self.createDirectoryAtPath(path, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }
    
    /* createSymbolicLinkAtURL:withDestinationURL:error: returns YES if the symbolic link that point at 'destURL' was able to be created at the location specified by 'url'. 'destURL' is always resolved against its base URL, if it has one. If 'destURL' has no base URL and it's 'relativePath' is indeed a relative path, then a relative symlink will be created. If this method returns NO, the link was unable to be created and an NSError will be returned by reference in the 'error' parameter. This method does not traverse a terminal symlink.
     */
    public func createSymbolicLinkAtURL(url: NSURL, withDestinationURL destURL: NSURL) throws {
        guard url.fileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnsupportedSchemeError.rawValue, userInfo: [NSURLErrorKey : url])
        }
        guard destURL.scheme == nil || destURL.fileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnsupportedSchemeError.rawValue, userInfo: [NSURLErrorKey : destURL])
        }
        guard let path = url.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [NSURLErrorKey : url])
        }
        guard let destPath = destURL.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [NSURLErrorKey : destURL])
        }
        try self.createSymbolicLinkAtPath(path, withDestinationPath: destPath)
    }
    
    /* Instances of NSFileManager may now have delegates. Each instance has one delegate, and the delegate is not retained. In versions of Mac OS X prior to 10.5, the behavior of calling [[NSFileManager alloc] init] was undefined. In Mac OS X 10.5 "Leopard" and later, calling [[NSFileManager alloc] init] returns a new instance of an NSFileManager.
     */
    public weak var delegate: NSFileManagerDelegate? {
        NSUnimplemented()
    }
    
    /* setAttributes:ofItemAtPath:error: returns YES when the attributes specified in the 'attributes' dictionary are set successfully on the item specified by 'path'. If this method returns NO, a presentable NSError will be provided by-reference in the 'error' parameter. If no error is required, you may pass 'nil' for the error.
     
        This method replaces changeFileAttributes:atPath:.
     */
    public func setAttributes(attributes: [String : AnyObject], ofItemAtPath path: String) throws {
        NSUnimplemented()
    }
    
    /* createDirectoryAtPath:withIntermediateDirectories:attributes:error: creates a directory at the specified path. If you pass 'NO' for createIntermediates, the directory must not exist at the time this call is made. Passing 'YES' for 'createIntermediates' will create any necessary intermediate directories. This method returns YES if all directories specified in 'path' were created and attributes were set. Directories are created with attributes specified by the dictionary passed to 'attributes'. If no dictionary is supplied, directories are created according to the umask of the process. This method returns NO if a failure occurs at any stage of the operation. If an error parameter was provided, a presentable NSError will be returned by reference.
     
        This method replaces createDirectoryAtPath:attributes:
     */
    public func createDirectoryAtPath(path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [String : AnyObject]?) throws {
        if createIntermediates {
            var isDir: ObjCBool = false
            if !fileExistsAtPath(path, isDirectory: &isDir) {
                let parent = path._nsObject.stringByDeletingLastPathComponent
                if !fileExistsAtPath(parent, isDirectory: &isDir) {
                    try createDirectoryAtPath(parent, withIntermediateDirectories: true, attributes: attributes)
                }
                if mkdir(path, S_IRWXU | S_IRWXG | S_IRWXO) != 0 {
                    throw _NSErrorWithErrno(errno, reading: false, path: path)
                } else if let attr = attributes {
                    try self.setAttributes(attr, ofItemAtPath: path)
                }
            } else if isDir {
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
    
    /**
     Performs a shallow search of the specified directory and returns the paths of any contained items.
     
     This method performs a shallow search of the directory and therefore does not traverse symbolic links or return the contents of any subdirectories. This method also does not return URLs for the current directory (“.”), parent directory (“..”) but it does return other hidden files (files that begin with a period character).
     
     The order of the files in the returned array is undefined.
     
     - Parameter path: The path to the directory whose contents you want to enumerate.
     
     - Throws: `NSError` if the directory does not exist, this error is thrown with the associated error code.
     
     - Returns: An array of String each of which identifies a file, directory, or symbolic link contained in `path`. The order of the files returned is undefined.
     */
    public func contentsOfDirectoryAtPath(path: String) throws -> [String] {
        var contents : [String] = [String]()
        
        let dir = opendir(path)
        
        if dir == nil {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadNoSuchFileError.rawValue, userInfo: [NSFilePathErrorKey: path])
        }
        
        defer {
            closedir(dir)
        }
        
        var entry: UnsafeMutablePointer<dirent> = readdir(dir)
        
        while entry != nil {
            if let entryName = withUnsafePointer(&entry.memory.d_name, { (ptr) -> String? in
                let int8Ptr = unsafeBitCast(ptr, UnsafePointer<Int8>.self)
                return String.fromCString(int8Ptr)
            }) {
                // TODO: `entryName` should be limited in length to `entry.memory.d_namlen`.
                if entryName != "." && entryName != ".." {
                    contents.append(entryName)
                }
            }
            
            entry = readdir(dir)
        }
        
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
    public func subpathsOfDirectoryAtPath(path: String) throws -> [String] {
        var contents : [String] = [String]()
        
        let dir = opendir(path)
        
        if dir == nil {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadNoSuchFileError.rawValue, userInfo: [NSFilePathErrorKey: path])
        }
        
        defer {
            closedir(dir)
        }
        
        var entry = readdir(dir)
        
        while entry != nil {
            if let entryName = withUnsafePointer(&entry.memory.d_name, { (ptr) -> String? in
                let int8Ptr = unsafeBitCast(ptr, UnsafePointer<Int8>.self)
                return String.fromCString(int8Ptr)
            }) {
                // TODO: `entryName` should be limited in length to `entry.memory.d_namlen`.
                if entryName != "." && entryName != ".." {
                    contents.append(entryName)
                    
                    if let entryType = withUnsafePointer(&entry.memory.d_type, { (ptr) -> Int32? in
                        let int32Ptr = unsafeBitCast(ptr, UnsafePointer<UInt8>.self)
                        return Int32(int32Ptr.memory)
                    }) {
                        #if os(OSX) || os(iOS)
                            let tempEntryType = entryType
                        #elseif os(Linux)
                            let tempEntryType = Int(entryType)
                        #endif
                        
                        if tempEntryType == DT_DIR {
                            let subPath: String = path + "/" + entryName
                            
                            let entries =  try subpathsOfDirectoryAtPath(subPath)
                            contents.appendContentsOf(entries.map({file in "\(entryName)/\(file)"}))
                        }
                    }
                }
            }
            
            entry = readdir(dir)
        }
        
        return contents
    }
    
    /* attributesOfItemAtPath:error: returns an NSDictionary of key/value pairs containing the attributes of the item (file, directory, symlink, etc.) at the path in question. If this method returns 'nil', an NSError will be returned by reference in the 'error' parameter. This method does not traverse a terminal symlink.
     
        This method replaces fileAttributesAtPath:traverseLink:.
     */
    /// - Experiment: Note that the return type of this function is different than on Darwin Foundation (Any instead of AnyObject). This is likely to change once we have a more complete story for bridging in place.
    public func attributesOfItemAtPath(path: String) throws -> [String : Any] {
        var s = stat()
        guard lstat(path, &s) == 0 else {
            throw _NSErrorWithErrno(errno, reading: true, path: path)
        }
        var result = [String : Any]()
        result[NSFileSize] = NSNumber(unsignedLongLong: UInt64(s.st_size))

#if os(OSX) || os(iOS)
        let ti = (NSTimeInterval(s.st_mtimespec.tv_sec) - kCFAbsoluteTimeIntervalSince1970) + (1.0e-9 * NSTimeInterval(s.st_mtimespec.tv_nsec))
#else
        let ti = (NSTimeInterval(s.st_mtim.tv_sec) - kCFAbsoluteTimeIntervalSince1970) + (1.0e-9 * NSTimeInterval(s.st_mtim.tv_nsec))
#endif
        result[NSFileModificationDate] = NSDate(timeIntervalSinceReferenceDate: ti)
        
        result[NSFilePosixPermissions] = NSNumber(unsignedLongLong: UInt64(s.st_mode & 0o7777))
        result[NSFileReferenceCount] = NSNumber(unsignedLongLong: UInt64(s.st_nlink))
        result[NSFileSystemNumber] = NSNumber(unsignedLongLong: UInt64(s.st_dev))
        result[NSFileSystemFileNumber] = NSNumber(unsignedLongLong: UInt64(s.st_ino))
        
        let pwd = getpwuid(s.st_uid)
        if pwd != nil && pwd.memory.pw_name != nil {
            if let name = String.fromCString(pwd.memory.pw_name) {
                result[NSFileOwnerAccountName] = name
            }
        }
        
        let grd = getgrgid(s.st_gid)
        if grd != nil && grd.memory.gr_name != nil {
            if let name = String.fromCString(grd.memory.gr_name) {
                result[NSFileGroupOwnerAccountID] = name
            }
        }

        var type : String
        switch s.st_mode & S_IFMT {
            case S_IFCHR: type = NSFileTypeCharacterSpecial
            case S_IFDIR: type = NSFileTypeDirectory
            case S_IFBLK: type = NSFileTypeBlockSpecial
            case S_IFREG: type = NSFileTypeRegular
            case S_IFLNK: type = NSFileTypeSymbolicLink
            case S_IFSOCK: type = NSFileTypeSocket
            default: type = NSFileTypeUnknown
        }
        result[NSFileType] = type
        
        if type == NSFileTypeBlockSpecial || type == NSFileTypeCharacterSpecial {
            result[NSFileDeviceIdentifier] = NSNumber(unsignedLongLong: UInt64(s.st_rdev))
        }

#if os(OSX) || os(iOS)
        if (s.st_flags & UInt32(UF_IMMUTABLE | SF_IMMUTABLE)) != 0 {
            result[NSFileImmutable] = NSNumber(bool: true)
        }
        if (s.st_flags & UInt32(UF_APPEND | SF_APPEND)) != 0 {
            result[NSFileAppendOnly] = NSNumber(bool: true)
        }
#endif
        result[NSFileOwnerAccountID] = NSNumber(unsignedLongLong: UInt64(s.st_uid))
        result[NSFileGroupOwnerAccountID] = NSNumber(unsignedLongLong: UInt64(s.st_gid))
        
        return result
    }
    
    /* attributesOfFileSystemForPath:error: returns an NSDictionary of key/value pairs containing the attributes of the filesystem containing the provided path. If this method returns 'nil', an NSError will be returned by reference in the 'error' parameter. This method does not traverse a terminal symlink.
     
        This method replaces fileSystemAttributesAtPath:.
     */
    public func attributesOfFileSystemForPath(path: String) throws -> [String : AnyObject] {
        NSUnimplemented()
    }
    
    /* createSymbolicLinkAtPath:withDestination:error: returns YES if the symbolic link that point at 'destPath' was able to be created at the location specified by 'path'. If this method returns NO, the link was unable to be created and an NSError will be returned by reference in the 'error' parameter. This method does not traverse a terminal symlink.
     
        This method replaces createSymbolicLinkAtPath:pathContent:
     */
    public func createSymbolicLinkAtPath(path: String, withDestinationPath destPath: String) throws {
        if symlink(destPath, path) == -1 {
            throw _NSErrorWithErrno(errno, reading: false, path: path)
        }
    }
    
    /* destinationOfSymbolicLinkAtPath:error: returns an NSString containing the path of the item pointed at by the symlink specified by 'path'. If this method returns 'nil', an NSError will be returned by reference in the 'error' parameter.
     
        This method replaces pathContentOfSymbolicLinkAtPath:
     */
    public func destinationOfSymbolicLinkAtPath(path: String) throws -> String {
        let bufSize = Int(PATH_MAX + 1)
        var buf = [Int8](count: bufSize, repeatedValue: 0)
        let len = readlink(path, &buf, bufSize)
        if len < 0 {
            throw _NSErrorWithErrno(errno, reading: true, path: path)
        }
        
        return self.stringWithFileSystemRepresentation(buf, length: len)
    }
    
    public func copyItemAtPath(srcPath: String, toPath dstPath: String) throws {
        NSUnimplemented()
    }
    
    public func moveItemAtPath(srcPath: String, toPath dstPath: String) throws {
        guard self.fileExistsAtPath(dstPath) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteFileExistsError.rawValue, userInfo: [NSFilePathErrorKey : NSString(dstPath)])
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
    
    public func linkItemAtPath(srcPath: String, toPath dstPath: String) throws {
        var isDir = false
        if self.fileExistsAtPath(srcPath, isDirectory: &isDir) {
            if !isDir {
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
    
    public func removeItemAtPath(path: String) throws {
        if rmdir(path) == 0 {
            return
        } else if errno == ENOTEMPTY {

            let fsRep = NSFileManager.defaultManager().fileSystemRepresentationWithPath(path)
            let ps = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(2)
            ps.initialize(UnsafeMutablePointer(fsRep))
            ps.advancedBy(1).initialize(nil)
            let stream = fts_open(ps, FTS_PHYSICAL | FTS_XDEV | FTS_NOCHDIR, nil)
            ps.destroy(2)
            ps.dealloc(2)
            
            if stream != nil {
                defer {
                    fts_close(stream)
                }
                
                var current = fts_read(stream)
                while current != nil {
                    switch Int32(current.memory.fts_info) {
                        case FTS_DEFAULT, FTS_F, FTS_NSOK, FTS_SL, FTS_SLNONE:
                            if unlink(current.memory.fts_path) == -1 {
                                let str = NSString(bytes: current.memory.fts_path, length: Int(strlen(current.memory.fts_path)), encoding: NSUTF8StringEncoding)!._swiftObject
                                throw _NSErrorWithErrno(errno, reading: false, path: str)
                            }
                        case FTS_DP:
                            if rmdir(current.memory.fts_path) == -1 {
                                let str = NSString(bytes: current.memory.fts_path, length: Int(strlen(current.memory.fts_path)), encoding: NSUTF8StringEncoding)!._swiftObject
                                throw _NSErrorWithErrno(errno, reading: false, path: str)
                            }
                        default:
                            break
                    }
                    current = fts_read(stream)
                }
            } else {
                _NSErrorWithErrno(ENOTEMPTY, reading: false, path: path)
            }
            // TODO: Error handling if fts_read fails.

        } else if errno != ENOTDIR {
            throw _NSErrorWithErrno(errno, reading: false, path: path)
        } else if unlink(path) != 0 {
            throw _NSErrorWithErrno(errno, reading: false, path: path)
        }
    }
    
    public func copyItemAtURL(srcURL: NSURL, toURL dstURL: NSURL) throws {
        guard srcURL.fileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnsupportedSchemeError.rawValue, userInfo: [NSURLErrorKey : srcURL])
        }
        guard dstURL.fileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnsupportedSchemeError.rawValue, userInfo: [NSURLErrorKey : dstURL])
        }
        guard let srcPath = srcURL.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [NSURLErrorKey : srcURL])
        }
        guard let dstPath = dstURL.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [NSURLErrorKey : dstURL])
        }
        try copyItemAtPath(srcPath, toPath: dstPath)
    }
    
    public func moveItemAtURL(srcURL: NSURL, toURL dstURL: NSURL) throws {
        guard srcURL.fileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnsupportedSchemeError.rawValue, userInfo: [NSURLErrorKey : srcURL])
        }
        guard dstURL.fileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnsupportedSchemeError.rawValue, userInfo: [NSURLErrorKey : dstURL])
        }
        guard let srcPath = srcURL.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [NSURLErrorKey : srcURL])
        }
        guard let dstPath = dstURL.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [NSURLErrorKey : dstURL])
        }
        try moveItemAtPath(srcPath, toPath: dstPath)
    }
    
    public func linkItemAtURL(srcURL: NSURL, toURL dstURL: NSURL) throws {
        guard srcURL.fileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnsupportedSchemeError.rawValue, userInfo: [NSURLErrorKey : srcURL])
        }
        guard dstURL.fileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnsupportedSchemeError.rawValue, userInfo: [NSURLErrorKey : dstURL])
        }
        guard let srcPath = srcURL.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [NSURLErrorKey : srcURL])
        }
        guard let dstPath = dstURL.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [NSURLErrorKey : dstURL])
        }
        try linkItemAtPath(srcPath, toPath: dstPath)
    }
    
    public func removeItemAtURL(URL: NSURL) throws {
        guard URL.fileURL else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnsupportedSchemeError.rawValue, userInfo: [NSURLErrorKey : URL])
        }
        guard let path = URL.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [NSURLErrorKey : URL])
        }
        try self.removeItemAtPath(path)
    }
    
    /* Process working directory management. Despite the fact that these are instance methods on NSFileManager, these methods report and change (respectively) the working directory for the entire process. Developers are cautioned that doing so is fraught with peril.
     */
    public var currentDirectoryPath: String {
        let length = Int(PATH_MAX) + 1
        var buf = [Int8](count: length, repeatedValue: 0)
        getcwd(&buf, length)
        let result = self.stringWithFileSystemRepresentation(buf, length: Int(strlen(buf)))
        return result
    }
    
    public func changeCurrentDirectoryPath(path: String) -> Bool {
        return chdir(path) == 0
    }
    
    /* The following methods are of limited utility. Attempting to predicate behavior based on the current state of the filesystem or a particular file on the filesystem is encouraging odd behavior in the face of filesystem race conditions. It's far better to attempt an operation (like loading a file or creating a directory) and handle the error gracefully than it is to try to figure out ahead of time whether the operation will succeed.
     */
    public func fileExistsAtPath(path: String) -> Bool {
        return self.fileExistsAtPath(path, isDirectory: nil)
    }
    
    public func fileExistsAtPath(path: String, isDirectory: UnsafeMutablePointer<ObjCBool>) -> Bool {
        var s = stat()
        if lstat(path, &s) >= 0 {
            if isDirectory != nil {
                if (s.st_mode & S_IFMT) == S_IFLNK {
                    if stat(path, &s) >= 0 {
                        isDirectory.memory = (s.st_mode & S_IFMT) == S_IFDIR
                    } else {
                        return false
                    }
                } else {
                    isDirectory.memory = (s.st_mode & S_IFMT) == S_IFDIR
                }
            }

            // don't chase the link for this magic case -- we might be /Net/foo
            // which is a symlink to /private/Net/foo which is not yet mounted...
            if (s.st_mode & S_IFMT) == S_IFLNK {
                if (s.st_mode & S_ISVTX) == S_ISVTX {
                    return true
                }
                // chase the link; too bad if it is a slink to /Net/foo
                stat(path, &s) >= 0
            }
        } else {
            return false
        }
        return true
    }
    
    public func isReadableFileAtPath(path: String) -> Bool {
        return access(path, R_OK) == 0
    }
    
    public func isWritableFileAtPath(path: String) -> Bool {
        return access(path, W_OK) == 0
    }
    
    public func isExecutableFileAtPath(path: String) -> Bool {
        return access(path, X_OK) == 0
    }
    
    public func isDeletableFileAtPath(path: String) -> Bool {
        NSUnimplemented()
    }
    
    /* -contentsEqualAtPath:andPath: does not take into account data stored in the resource fork or filesystem extended attributes.
     */
    public func contentsEqualAtPath(path1: String, andPath path2: String) -> Bool {
        NSUnimplemented()
    }
    
    /* displayNameAtPath: returns an NSString suitable for presentation to the user. For directories which have localization information, this will return the appropriate localized string. This string is not suitable for passing to anything that must interact with the filesystem.
     */
    public func displayNameAtPath(path: String) -> String {
        NSUnimplemented()
    }
    
    /* componentsToDisplayForPath: returns an NSArray of display names for the path provided. Localization will occur as in displayNameAtPath: above. This array cannot and should not be reassembled into an usable filesystem path for any kind of access.
     */
    public func componentsToDisplayForPath(path: String) -> [String]? {
        NSUnimplemented()
    }
    
    /* enumeratorAtPath: returns an NSDirectoryEnumerator rooted at the provided path. If the enumerator cannot be created, this returns NULL. Because NSDirectoryEnumerator is a subclass of NSEnumerator, the returned object can be used in the for...in construct.
     */
    public func enumeratorAtPath(path: String) -> NSDirectoryEnumerator? {
        return NSPathDirectoryEnumerator(path: path)
    }
    
    /* enumeratorAtURL:includingPropertiesForKeys:options:errorHandler: returns an NSDirectoryEnumerator rooted at the provided directory URL. The NSDirectoryEnumerator returns NSURLs from the -nextObject method. The optional 'includingPropertiesForKeys' parameter indicates which resource properties should be pre-fetched and cached with each enumerated URL. The optional 'errorHandler' block argument is invoked when an error occurs. Parameters to the block are the URL on which an error occurred and the error. When the error handler returns YES, enumeration continues if possible. Enumeration stops immediately when the error handler returns NO.
    
        If you wish to only receive the URLs and no other attributes, then pass '0' for 'options' and an empty NSArray ('[NSArray array]') for 'keys'. If you wish to have the property caches of the vended URLs pre-populated with a default set of attributes, then pass '0' for 'options' and 'nil' for 'keys'.
     */
    public func enumeratorAtURL(url: NSURL, includingPropertiesForKeys keys: [String]?, options mask: NSDirectoryEnumerationOptions, errorHandler handler: ((NSURL, NSError) -> Bool)?) -> NSDirectoryEnumerator? {
        if mask.contains(.SkipsPackageDescendants) || mask.contains(.SkipsHiddenFiles) {
            NSUnimplemented("Enumeration options not yet implemented")
        }
        return NSURLDirectoryEnumerator(url: url, options: mask, errorHandler: handler)
    }
    
    /* subpathsAtPath: returns an NSArray of all contents and subpaths recursively from the provided path. This may be very expensive to compute for deep filesystem hierarchies, and should probably be avoided.
     */
    public func subpathsAtPath(path: String) -> [String]? {
        NSUnimplemented()
    }
    
    /* These methods are provided here for compatibility. The corresponding methods on NSData which return NSErrors should be regarded as the primary method of creating a file from an NSData or retrieving the contents of a file as an NSData.
     */
    public func contentsAtPath(path: String) -> NSData? {
        return NSData(contentsOfFile: path)
    }
    
    public func createFileAtPath(path: String, contents data: NSData?, attributes attr: [String : AnyObject]?) -> Bool {
        do {
            try (data ?? NSData()).writeToFile(path, options: .DataWritingAtomic)
            return true
        } catch _ {
            return false
        }
    }
    
    /* fileSystemRepresentationWithPath: returns an array of characters suitable for passing to lower-level POSIX style APIs. The string is provided in the representation most appropriate for the filesystem in question.
     */
    public func fileSystemRepresentationWithPath(path: String) -> UnsafePointer<Int8> {
        precondition(path != "", "Empty path argument")
        let len = CFStringGetMaximumSizeOfFileSystemRepresentation(path._cfObject)
        if len == kCFNotFound {
            return nil
        }
        let buf = UnsafeMutablePointer<Int8>.alloc(len)
        for i in 0..<len {
            buf.advancedBy(i).initialize(0)
        }
        if !path._nsObject.getFileSystemRepresentation(buf, maxLength: len) {
            buf.destroy(len)
            buf.dealloc(len)
            return nil
        }
        return UnsafePointer(buf)
    }
    
    /* stringWithFileSystemRepresentation:length: returns an NSString created from an array of bytes that are in the filesystem representation.
     */
    public func stringWithFileSystemRepresentation(str: UnsafePointer<Int8>, length len: Int) -> String {
        return NSString(bytes: str, length: len, encoding: NSUTF8StringEncoding)!._swiftObject
    }
    
    /* -replaceItemAtURL:withItemAtURL:backupItemName:options:resultingItemURL:error: is for developers who wish to perform a safe-save without using the full NSDocument machinery that is available in the AppKit.
     
        The `originalItemURL` is the item being replaced.
        `newItemURL` is the item which will replace the original item. This item should be placed in a temporary directory as provided by the OS, or in a uniquely named directory placed in the same directory as the original item if the temporary directory is not available.
        If `backupItemName` is provided, that name will be used to create a backup of the original item. The backup is placed in the same directory as the original item. If an error occurs during the creation of the backup item, the operation will fail. If there is already an item with the same name as the backup item, that item will be removed. The backup item will be removed in the event of success unless the `NSFileManagerItemReplacementWithoutDeletingBackupItem` option is provided in `options`.
        For `options`, pass `0` to get the default behavior, which uses only the metadata from the new item while adjusting some properties using values from the original item. Pass `NSFileManagerItemReplacementUsingNewMetadataOnly` in order to use all possible metadata from the new item.
     */
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func replaceItemAtURL(originalItemURL: NSURL, withItemAtURL newItemURL: NSURL, backupItemName: String?, options: NSFileManagerItemReplacementOptions) throws -> NSURL {
        NSUnimplemented()
    }
    
    internal func _tryToResolveTrailingSymlinkInPath(path: String) -> String? {
        guard _pathIsSymbolicLink(path) else {
            return nil
        }
        
        guard let destination = try? NSFileManager.defaultManager().destinationOfSymbolicLinkAtPath(path) else {
            return nil
        }
        
        return _appendSymlinkDestination(destination, toPath: path)
    }
    
    internal func _appendSymlinkDestination(dest: String, toPath: String) -> String {
        if dest.hasPrefix("/") {
            return dest
        } else {
            let temp = toPath.bridge().stringByDeletingLastPathComponent
            return temp.bridge().stringByAppendingPathComponent(dest)
        }
    }
    
    internal func _pathIsSymbolicLink(path: String) -> Bool {
        guard let
            attrs = try? attributesOfItemAtPath(path),
            fileType = attrs[NSFileType] as? String
        else {
            return false
        }
        
        return fileType == NSFileTypeSymbolicLink
    }
}

extension NSFileManagerDelegate {
    func fileManager(fileManager: NSFileManager, shouldCopyItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return true }
    func fileManager(fileManager: NSFileManager, shouldCopyItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool { return true }
    
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, copyingItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return false }
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, copyingItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool { return false }

    func fileManager(fileManager: NSFileManager, shouldMoveItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return true }
    func fileManager(fileManager: NSFileManager, shouldMoveItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool { return true }
    
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, movingItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return false }
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, movingItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool { return false }
    
    func fileManager(fileManager: NSFileManager, shouldLinkItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return true }
    func fileManager(fileManager: NSFileManager, shouldLinkItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool { return true }
    
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, linkingItemAtPath srcPath: String, toPath dstPath: String) -> Bool { return false }
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, linkingItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool { return false }
    
    func fileManager(fileManager: NSFileManager, shouldRemoveItemAtPath path: String) -> Bool { return true }
    func fileManager(fileManager: NSFileManager, shouldRemoveItemAtURL URL: NSURL) -> Bool { return true }
    
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, removingItemAtPath path: String) -> Bool { return false }
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, removingItemAtURL URL: NSURL) -> Bool { return false }
}

public protocol NSFileManagerDelegate : class {
    
    /* fileManager:shouldCopyItemAtPath:toPath: gives the delegate an opportunity to filter the resulting copy. Returning YES from this method will allow the copy to happen. Returning NO from this method causes the item in question to be skipped. If the item skipped was a directory, no children of that directory will be copied, nor will the delegate be notified of those children.
     */
    func fileManager(fileManager: NSFileManager, shouldCopyItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(fileManager: NSFileManager, shouldCopyItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool
    
    /* fileManager:shouldProceedAfterError:copyingItemAtPath:toPath: gives the delegate an opportunity to recover from or continue copying after an error. If an error occurs, the error object will contain an NSError indicating the problem. The source path and destination paths are also provided. If this method returns YES, the NSFileManager instance will continue as if the error had not occurred. If this method returns NO, the NSFileManager instance will stop copying, return NO from copyItemAtPath:toPath:error: and the error will be provied there.
     */
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, copyingItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, copyingItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool
    
    /* fileManager:shouldMoveItemAtPath:toPath: gives the delegate an opportunity to not move the item at the specified path. If the source path and the destination path are not on the same device, a copy is performed to the destination path and the original is removed. If the copy does not succeed, an error is returned and the incomplete copy is removed, leaving the original in place.
    
     */
    func fileManager(fileManager: NSFileManager, shouldMoveItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(fileManager: NSFileManager, shouldMoveItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool
    
    /* fileManager:shouldProceedAfterError:movingItemAtPath:toPath: functions much like fileManager:shouldProceedAfterError:copyingItemAtPath:toPath: above. The delegate has the opportunity to remedy the error condition and allow the move to continue.
     */
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, movingItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, movingItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool
    
    /* fileManager:shouldLinkItemAtPath:toPath: acts as the other "should" methods, but this applies to the file manager creating hard links to the files in question.
     */
    func fileManager(fileManager: NSFileManager, shouldLinkItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(fileManager: NSFileManager, shouldLinkItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool
    
    /* fileManager:shouldProceedAfterError:linkingItemAtPath:toPath: allows the delegate an opportunity to remedy the error which occurred in linking srcPath to dstPath. If the delegate returns YES from this method, the linking will continue. If the delegate returns NO from this method, the linking operation will stop and the error will be returned via linkItemAtPath:toPath:error:.
     */
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, linkingItemAtPath srcPath: String, toPath dstPath: String) -> Bool
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, linkingItemAtURL srcURL: NSURL, toURL dstURL: NSURL) -> Bool
    
    /* fileManager:shouldRemoveItemAtPath: allows the delegate the opportunity to not remove the item at path. If the delegate returns YES from this method, the NSFileManager instance will attempt to remove the item. If the delegate returns NO from this method, the remove skips the item. If the item is a directory, no children of that item will be visited.
     */
    func fileManager(fileManager: NSFileManager, shouldRemoveItemAtPath path: String) -> Bool
    func fileManager(fileManager: NSFileManager, shouldRemoveItemAtURL URL: NSURL) -> Bool
    
    /* fileManager:shouldProceedAfterError:removingItemAtPath: allows the delegate an opportunity to remedy the error which occurred in removing the item at the path provided. If the delegate returns YES from this method, the removal operation will continue. If the delegate returns NO from this method, the removal operation will stop and the error will be returned via linkItemAtPath:toPath:error:.
     */
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, removingItemAtPath path: String) -> Bool
    func fileManager(fileManager: NSFileManager, shouldProceedAfterError error: NSError, removingItemAtURL URL: NSURL) -> Bool
}

public class NSDirectoryEnumerator : NSEnumerator {
    
    /* For NSDirectoryEnumerators created with -enumeratorAtPath:, the -fileAttributes and -directoryAttributes methods return an NSDictionary containing the keys listed below. For NSDirectoryEnumerators created with -enumeratorAtURL:includingPropertiesForKeys:options:errorHandler:, these two methods return nil.
     */
    public var fileAttributes: [String : AnyObject]? {
        NSRequiresConcreteImplementation()
    }
    public var directoryAttributes: [String : AnyObject]? {
        NSRequiresConcreteImplementation()
    }
    
    /* This method returns the number of levels deep the current object is in the directory hierarchy being enumerated. The directory passed to -enumeratorAtURL:includingPropertiesForKeys:options:errorHandler: is considered to be level 0.
     */
    public var level: Int {
        NSRequiresConcreteImplementation()
    }
    
    public func skipDescendants() {
        NSRequiresConcreteImplementation()
    }
}

internal class NSPathDirectoryEnumerator: NSDirectoryEnumerator {
    let baseURL: NSURL
    let innerEnumerator : NSDirectoryEnumerator
    override var fileAttributes: [String : AnyObject]? {
        NSUnimplemented()
    }
    override var directoryAttributes: [String : AnyObject]? {
        NSUnimplemented()
    }
    
    override var level: Int {
        NSUnimplemented()
    }
    
    override func skipDescendants() {
        NSUnimplemented()
    }
    
    init?(path: String) {
        let url = NSURL(fileURLWithPath: path)
        self.baseURL = url
        guard let ie = NSFileManager.defaultManager().enumeratorAtURL(url, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions(), errorHandler: nil) else {
            return nil
        }
        self.innerEnumerator = ie
    }
    
    override func nextObject() -> AnyObject? {
        let o = innerEnumerator.nextObject()
        guard let url = o as? NSURL else {
            return nil
        }
        let path = url.path!.stringByReplacingOccurrencesOfString(baseURL.path!+"/", withString: "")
        return NSString(string: path)
    }

}

internal class NSURLDirectoryEnumerator : NSDirectoryEnumerator {
    var _url : NSURL
    var _options : NSDirectoryEnumerationOptions
    var _errorHandler : ((NSURL, NSError) -> Bool)?
    var _stream : UnsafeMutablePointer<FTS> = nil
    var _current : UnsafeMutablePointer<FTSENT> = nil
    var _rootError : NSError? = nil
    var _gotRoot : Bool = false
    
    init(url: NSURL, options: NSDirectoryEnumerationOptions, errorHandler: ((NSURL, NSError) -> Bool)?) {
        _url = url
        _options = options
        _errorHandler = errorHandler
        
        if let path = _url.path {
            if NSFileManager.defaultManager().fileExistsAtPath(path) {
                let fsRep = NSFileManager.defaultManager().fileSystemRepresentationWithPath(path)
                let ps = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(2)
                ps.initialize(UnsafeMutablePointer(fsRep))
                ps.advancedBy(1).initialize(nil)
                _stream = fts_open(ps, FTS_PHYSICAL | FTS_XDEV | FTS_NOCHDIR, nil)
                ps.destroy(2)
                ps.dealloc(2)
            } else {
                _rootError = _NSErrorWithErrno(ENOENT, reading: true, url: url)
            }
        } else {
            _rootError = _NSErrorWithErrno(ENOENT, reading: true, url: url)
        }

    }
    
    deinit {
        if _stream != nil {
            fts_close(_stream)
        }
    }
    
    override func nextObject() -> AnyObject? {
        if _stream != nil {
            
            if !_gotRoot  {
                _gotRoot = true
                
                // Skip the root.
                _current = fts_read(_stream)
                
            }

            _current = fts_read(_stream)
            while _current != nil {
                switch Int32(_current.memory.fts_info) {
                    case FTS_D:
                        if _options.contains(.SkipsSubdirectoryDescendants) {
                            fts_set(_stream, _current, FTS_SKIP)
                        }
                        fallthrough
                    case FTS_DEFAULT, FTS_F, FTS_NSOK, FTS_SL, FTS_SLNONE:
                        let str = NSString(bytes: _current.memory.fts_path, length: Int(strlen(_current.memory.fts_path)), encoding: NSUTF8StringEncoding)!._swiftObject
                        return NSURL(fileURLWithPath: str)
                    case FTS_DNR, FTS_ERR, FTS_NS:
                        let keepGoing : Bool
                        if let handler = _errorHandler {
                            let str = NSString(bytes: _current.memory.fts_path, length: Int(strlen(_current.memory.fts_path)), encoding: NSUTF8StringEncoding)!._swiftObject
                            keepGoing = handler(NSURL(fileURLWithPath: str), _NSErrorWithErrno(_current.memory.fts_errno, reading: true))
                        } else {
                            keepGoing = true
                        }
                        if !keepGoing {
                            fts_close(_stream)
                            _stream = nil
                            return nil
                        }
                    default:
                        break
                }
                _current = fts_read(_stream)
            }
            // TODO: Error handling if fts_read fails.
            
        } else if let error = _rootError {
            // Was there an error opening the stream?
            if let handler = _errorHandler {
                handler(_url, error)
            }
        }
        return nil
    }
    
    override var directoryAttributes : [String : AnyObject]? {
        return nil
    }
    
    override var fileAttributes: [String : AnyObject]? {
        return nil
    }
    
    override var level: Int {
        if _current != nil {
            return Int(_current.memory.fts_level)
        } else {
            return 0
        }
    }
    
    override func skipDescendants() {
        if _stream != nil && _current != nil {
            fts_set(_stream, _current, FTS_SKIP)
        }
    }
}

public let NSFileType: String = "NSFileType"
public let NSFileTypeDirectory: String = "NSFileTypeDirectory"
public let NSFileTypeRegular: String = "NSFileTypeRegular"
public let NSFileTypeSymbolicLink: String = "NSFileTypeSymbolicLink"
public let NSFileTypeSocket: String = "NSFileTypeSocket"
public let NSFileTypeCharacterSpecial: String = "NSFileTypeCharacterSpecial"
public let NSFileTypeBlockSpecial: String = "NSFileTypeBlockSpecial"
public let NSFileTypeUnknown: String = "NSFileTypeUnknown"
public let NSFileSize: String = "NSFileSize"
public let NSFileModificationDate: String = "NSFileModificationDate"
public let NSFileReferenceCount: String = "NSFileReferenceCount"
public let NSFileDeviceIdentifier: String = "NSFileDeviceIdentifier"
public let NSFileOwnerAccountName: String = "NSFileOwnerAccountName"
public let NSFileGroupOwnerAccountName: String = "NSFileGroupOwnerAccountName"
public let NSFilePosixPermissions: String = "NSFilePosixPermissions"
public let NSFileSystemNumber: String = "NSFileSystemNumber"
public let NSFileSystemFileNumber: String = "NSFileSystemFileNumber"
public let NSFileExtensionHidden: String = "" // NSUnimplemented
public let NSFileHFSCreatorCode: String = "" // NSUnimplemented
public let NSFileHFSTypeCode: String = "" // NSUnimplemented
public let NSFileImmutable: String = "NSFileImmutable"
public let NSFileAppendOnly: String = "NSFileAppendOnly"
public let NSFileCreationDate: String = "" // NSUnimplemented
public let NSFileOwnerAccountID: String = "NSFileOwnerAccountID"
public let NSFileGroupOwnerAccountID: String = "NSFileGroupOwnerAccountID"
public let NSFileBusy: String = "" // NSUnimplemented

public let NSFileSystemSize: String = "" // NSUnimplemented
public let NSFileSystemFreeSize: String = "" // NSUnimplemented
public let NSFileSystemNodes: String = "" // NSUnimplemented
public let NSFileSystemFreeNodes: String = "" // NSUnimplemented
