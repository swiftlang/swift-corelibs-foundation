// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(Windows)
let validPathSeps: [Character] = ["\\", "/"]
#else
let validPathSeps: [Character] = ["/"]
#endif

public func NSTemporaryDirectory() -> String {
#if os(Windows)
    let cchLength: DWORD = GetTempPathW(0, nil)
    var wszPath: [WCHAR] = Array<WCHAR>(repeating: 0, count: Int(cchLength + 1))
    guard GetTempPathW(DWORD(wszPath.count), &wszPath) <= cchLength else {
      preconditionFailure("GetTempPathW mutation race")
    }
    return String(decodingCString: wszPath, as: UTF16.self).standardizingPath
#else
#if canImport(Darwin)
    let safe_confstr = { (name: Int32, buf: UnsafeMutablePointer<Int8>?, len: Int) -> Int in
        // POSIX moment of weird: confstr() is one of those annoying APIs which
        // can return zero for both error and non-error conditions, so the only
        // way to disambiguate is to put errno in a known state before calling.
        errno = 0
        let result = confstr(name, buf, len)
        
        // result == 0 is only error if errno is not zero. But, if there was an
        // error, bail; all possible errors from confstr() are Very Bad Things.
        let err = errno // only read errno once in the failure case.
        precondition(result > 0 || err == 0, "Unexpected confstr() error: \(err)")
        
        // This is extreme paranoia and should never happen; this would mean
        // confstr() returned < 0, which would only happen for impossibly long
        // sizes of value or long-dead versions of the OS.
        assert(result >= 0, "confstr() returned impossible result: \(result)")

        return result
    }

    let length: Int = safe_confstr(_CS_DARWIN_USER_TEMP_DIR, nil, 0)
    if length > 0 {
      var buffer: [Int8] = Array<Int8>(repeating: 0, count: length)
      let final_length = safe_confstr(_CS_DARWIN_USER_TEMP_DIR, &buffer, buffer.count)
      
      assert(length == final_length, "Value of _CS_DARWIN_USER_TEMP_DIR changed?")
      if length > 0 && length < buffer.count {
        return String(cString: buffer, encoding: .utf8)!
      }
    }
#endif
    if let tmpdir = ProcessInfo.processInfo.environment["TMPDIR"] {
        if !validPathSeps.contains(where: { tmpdir.hasSuffix(String($0)) }) {
            return tmpdir + "/"
        } else {
            return tmpdir
        }
    }
#if os(Android)
    // Bionic uses /data/local/tmp/ as temporary directory. TMPDIR is rarely
    // defined.
    return "/data/local/tmp/"
#else
    return "/tmp/"
#endif
#endif
}

extension String {
    
    internal var _startOfLastPathComponent : String.Index {
        precondition(!validPathSeps.contains(where: { hasSuffix(String($0)) }) && length > 1)
        
        let startPos = startIndex
        var curPos = endIndex
        
        // Find the beginning of the component
        while curPos > startPos {
            let prevPos = index(before: curPos)
            if validPathSeps.contains(self[prevPos]) {
                break
            }
            curPos = prevPos
        }
        return curPos

    }

    internal var _startOfPathExtension : String.Index? {
        precondition(!validPathSeps.contains(where: { hasSuffix(String($0)) }))

        var currentPosition = endIndex
        let startOfLastPathComponent = _startOfLastPathComponent

        // Find the beginning of the extension
        while currentPosition > startOfLastPathComponent {
            let previousPosition = index(before: currentPosition)
            let character = self[previousPosition]
            if validPathSeps.contains(character) {
                return nil
            } else if character == "." {
                if startOfLastPathComponent == previousPosition {
                    return nil
                } else if case let previous2Position = index(before: previousPosition),
                    previousPosition == index(before: endIndex) &&
                    previous2Position == startOfLastPathComponent &&
                    self[previous2Position] == "."
                {
                    return nil
                } else {
                    return currentPosition
                }
            }
            currentPosition = previousPosition
        }
        return nil
    }

    internal var isAbsolutePath: Bool {
      if hasPrefix("~") { return true }
#if os(Windows)
      guard let value = try? FileManager.default._fileSystemRepresentation(withPath: self, {
          !PathIsRelativeW($0)
      }) else { return false }
      return value
#else
      return hasPrefix("/")
#endif
    }

    internal func _stringByAppendingPathComponent(_ str: String, doneAppending : Bool = true) -> String {
        if str.isEmpty {
            return self
        }
        if isEmpty {
            return str
        }
        if validPathSeps.contains(where: { hasSuffix(String($0)) }) {
          return self + str
        }
        return self + "/" + str
    }
    
    internal func _stringByFixingSlashes(compress : Bool = true, stripTrailing: Bool = true) -> String {
        var result = self
        if compress {
            let startPos = result.startIndex
            var endPos = result.endIndex
            var curPos = startPos

            while curPos < endPos {
                if validPathSeps.contains(result[curPos]) {
                    var afterLastSlashPos = curPos
                    while afterLastSlashPos < endPos && validPathSeps.contains(result[afterLastSlashPos]) {
                        afterLastSlashPos = result.index(after: afterLastSlashPos)
                    }
                    if afterLastSlashPos != result.index(after: curPos) {
                        result.replaceSubrange(curPos ..< afterLastSlashPos, with: ["/"])
                        endPos = result.endIndex
                    }
                    curPos = afterLastSlashPos
                } else {
                    curPos = result.index(after: curPos)
                }
            }
        }
        if stripTrailing && result.length > 1 && validPathSeps.contains(where: {result.hasSuffix(String($0))}) {
            result.remove(at: result.index(before: result.endIndex))
        }
        return result
    }
    
    internal func _stringByRemovingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else {
            return self
        }

        var temp = self
        temp.removeSubrange(startIndex..<prefix.endIndex)
        return temp
    }
    
    internal func _tryToRemovePathPrefix(_ prefix: String) -> String? {
        guard self != prefix else {
            return nil
        }
        
        let temp = _stringByRemovingPrefix(prefix)
        if FileManager.default.fileExists(atPath: temp) {
            return temp
        }
        
        return nil
    }
}

extension NSString {

    public var isAbsolutePath: Bool {
      return (self as String).isAbsolutePath
    }

    public static func path(withComponents components: [String]) -> String {
        var result = ""
        for comp in components.prefix(components.count - 1) {
            result = result._stringByAppendingPathComponent(comp._stringByFixingSlashes(), doneAppending: false)
        }
        if let last = components.last {
            result = result._stringByAppendingPathComponent(last._stringByFixingSlashes(), doneAppending: true)
        }
        return result
    }
    
    public var pathComponents : [String] {
        return _pathComponents(self._swiftObject)!
    }
    
    public var lastPathComponent : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return fixedSelf
        }
        
        return String(fixedSelf.suffix(from: fixedSelf._startOfLastPathComponent))
    }
    
    public var deletingLastPathComponent : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf == "/" || fixedSelf == "" {
            return fixedSelf
        }
        
        switch fixedSelf._startOfLastPathComponent {
        
        // relative path, single component
        case fixedSelf.startIndex:
            return ""
        
        // absolute path, single component
        case fixedSelf.index(after: fixedSelf.startIndex):
            return "/"
        
        // all common cases
        case let startOfLast:
            return String(fixedSelf.prefix(upTo: fixedSelf.index(before: startOfLast)))
        }
    }
    
    internal func _stringByFixingSlashes(compress : Bool = true, stripTrailing: Bool = true) -> String {
        if validPathSeps.contains(where: { String($0) == _swiftObject }) {
            return _swiftObject
        }
        
        var result = _swiftObject
        if compress {
            let startPos = result.startIndex
            var endPos = result.endIndex
            var curPos = startPos

            while curPos < endPos {
                if validPathSeps.contains(result[curPos]) {
                    var afterLastSlashPos = curPos
                    while afterLastSlashPos < endPos && validPathSeps.contains(result[afterLastSlashPos]) {
                        afterLastSlashPos = result.index(after: afterLastSlashPos)
                    }
                    if afterLastSlashPos != result.index(after: curPos) {
                        result.replaceSubrange(curPos ..< afterLastSlashPos, with: ["/"])
                        endPos = result.endIndex
                    }
                    curPos = afterLastSlashPos
                } else {
                    curPos = result.index(after: curPos)
                }
            }
        }
        if stripTrailing && validPathSeps.contains(where: { result.hasSuffix(String($0)) }) {
            result.remove(at: result.index(before: result.endIndex))
        }
        return result
    }
    
    internal func _stringByAppendingPathComponent(_ str: String, doneAppending : Bool = true) -> String {
        return _swiftObject._stringByAppendingPathComponent(str, doneAppending: doneAppending)
    }
    
    public func appendingPathComponent(_ str: String) -> String {
        return _stringByAppendingPathComponent(str)
    }
    
    public var pathExtension : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return ""
        }

        if let extensionPos = fixedSelf._startOfPathExtension {
            return String(fixedSelf.suffix(from: extensionPos))
        } else {
            return ""
        }
    }
    
    public var deletingPathExtension: String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return fixedSelf
        }
        if let extensionPos = fixedSelf._startOfPathExtension {
            return String(fixedSelf.prefix(upTo: fixedSelf.index(before: extensionPos)))
        } else {
            return fixedSelf
        }
    }
    
    public func appendingPathExtension(_ str: String) -> String? {
        if validPathSeps.contains(where: { str.hasPrefix(String($0)) }) || self == "" || validPathSeps.contains(where: { String($0)._nsObject == self }) {
            print("Cannot append extension \(str) to path \(self)")
            return nil
        }
        let result = _swiftObject._stringByFixingSlashes(compress: false, stripTrailing: true) + "." + str
        return result._stringByFixingSlashes()
    }

    public var expandingTildeInPath: String {
        guard hasPrefix("~") else {
            return _swiftObject
        }

        let endOfUserName = _swiftObject.firstIndex(where : { validPathSeps.contains($0) }) ?? _swiftObject.endIndex
        let startOfUserName = _swiftObject.index(after: _swiftObject.startIndex)
        let userName = String(_swiftObject[startOfUserName..<endOfUserName])
        let optUserName: String? = userName.isEmpty ? nil : userName
        
        guard let homeDir = NSHomeDirectoryForUser(optUserName) else {
            return _swiftObject._stringByFixingSlashes(compress: false, stripTrailing: true)
        }
        
        var result = _swiftObject
        result.replaceSubrange(_swiftObject.startIndex..<endOfUserName, with: homeDir)
        result = result._stringByFixingSlashes(compress: false, stripTrailing: true)
        
        return result
    }

#if os(Windows)
    public var unixPath: String {
        var unprefixed = self as String
        // If there is anything before the drive letter, e.g. "\\?\", "\\host\",
        // "\??\", etc, remove it.
        if isAbsolutePath, let index = unprefixed.firstIndex(of: ":") {
            unprefixed.removeSubrange(..<unprefixed.index(before: index))
        }
        let converted = String(unprefixed.map({ $0 == "\\" ? "/" : $0 }))
        return converted._stringByFixingSlashes(stripTrailing: false)
    }
#endif
    
    public var standardizingPath: String {
#if os(Windows)
        let expanded = unixPath.expandingTildeInPath
#else
        let expanded = expandingTildeInPath
#endif
        var resolved = expanded._bridgeToObjectiveC().resolvingSymlinksInPath
        
        let automount = "/var/automount"
        resolved = resolved._tryToRemovePathPrefix(automount) ?? resolved
        return resolved
    }
    
    public var resolvingSymlinksInPath: String {
        var components = pathComponents
        guard !components.isEmpty else {
            return _swiftObject
        }
        
        // TODO: pathComponents keeps final path separator if any. Check that logic.
        if validPathSeps.contains(where: { String($0) == components.last }) && components.count > 1 {
            components.removeLast()
        }
        
        var resolvedPath = components.removeFirst()
        for component in components {
            switch component {
                
            case "", ".":
                break
                
            case ".." where isAbsolutePath:
                resolvedPath = resolvedPath._bridgeToObjectiveC().deletingLastPathComponent
                
            default:
                resolvedPath = resolvedPath._bridgeToObjectiveC().appendingPathComponent(component)
                if let destination = FileManager.default._tryToResolveTrailingSymlinkInPath(resolvedPath) {
                    resolvedPath = destination
                }
            }
        }
        
        let privatePrefix = "/private"
        resolvedPath = resolvedPath._tryToRemovePathPrefix(privatePrefix) ?? resolvedPath
        
        return resolvedPath
    }
    
    public func stringsByAppendingPaths(_ paths: [String]) -> [String] {
        if self == "" {
            return paths
        }
        return paths.map(appendingPathComponent)
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func completePath(into outputName: inout String?, caseSensitive flag: Bool, matchesInto outputArray: inout [String], filterTypes: [String]?) -> Int {
        let path = _swiftObject
        guard !path.isEmpty else {
            return 0
        }
        
        let url = URL(fileURLWithPath: path)
        
        let searchAllFilesInDirectory = _stringIsPathToDirectory(path)
        let namePrefix = searchAllFilesInDirectory ? "" : url.lastPathComponent
        let checkFileName = _getFileNamePredicate(namePrefix, caseSensitive: flag)
        let checkExtension = _getExtensionPredicate(filterTypes, caseSensitive: flag)
        
        let resolvedURL: URL = url.resolvingSymlinksInPath()
        let urlWhereToSearch: URL = searchAllFilesInDirectory ? resolvedURL : resolvedURL.deletingLastPathComponent()
        
        var matches = _getNamesAtURL(urlWhereToSearch, prependWith: "", namePredicate: checkFileName, typePredicate: checkExtension)
        
        if matches.count == 1 {
            let theOnlyFoundItem = URL(fileURLWithPath: matches[0], relativeTo: urlWhereToSearch)
            if theOnlyFoundItem.hasDirectoryPath {
                matches = _getNamesAtURL(theOnlyFoundItem, prependWith: matches[0], namePredicate: nil, typePredicate: checkExtension)
            }
        }
        
        let commonPath = searchAllFilesInDirectory ? path : _ensureLastPathSeparator(deletingLastPathComponent)
        
        if searchAllFilesInDirectory {
            outputName = "/"
        } else {            
            if let lcp = _longestCommonPrefix(matches, caseSensitive: flag) {
                outputName = (commonPath + lcp)
            }
        }
        
        outputArray = matches.map({ (commonPath + $0) })
        
        return matches.count
    }

    internal func _stringIsPathToDirectory(_ path: String) -> Bool {
        if !validPathSeps.contains(where: { path.hasSuffix(String($0)) }) {
            return false
        }

        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }


    fileprivate typealias _FileNamePredicate = (String) -> Bool

    fileprivate func _getNamesAtURL(_ filePathURL: URL, prependWith: String, namePredicate: _FileNamePredicate?, typePredicate: _FileNamePredicate?) -> [String] {
        var result: [String] = []

        if let enumerator = FileManager.default.enumerator(at: filePathURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants, errorHandler: nil) {
            for item in enumerator.lazy.map({ $0 as! URL }) {
                let itemName = item.lastPathComponent

                if let predicate = namePredicate, !predicate(itemName) { continue }
                if let predicate = typePredicate, !predicate(item.pathExtension) { continue }
                if prependWith.isEmpty {
                    result.append(itemName)
                } else {
                    result.append(prependWith._bridgeToObjectiveC().appendingPathComponent(itemName))
                }
            }
        }

        return result
    }


    fileprivate func _getExtensionPredicate(_ extensions: [String]?, caseSensitive: Bool) -> _FileNamePredicate? {
        guard let exts = extensions else {
            return nil
        }
        
        if caseSensitive {
            let set = Set(exts)
            return { set.contains($0) }
        } else {
            let set = Set(exts.map { $0.lowercased() })
            return {set.contains($0.lowercased()) }
        }
    }
    
    fileprivate func _getFileNamePredicate(_ prefix: String, caseSensitive: Bool) -> _FileNamePredicate? {
        guard !prefix.isEmpty else {
            return nil
        }

        if caseSensitive {
            return { $0.hasPrefix(prefix) }
        } else {
            let prefix = prefix.lowercased()
            return { $0.lowercased().hasPrefix(prefix) }
        }
    }
    
    internal func _longestCommonPrefix(_ strings: [String], caseSensitive: Bool) -> String? {
        guard !strings.isEmpty else {
            return nil
        }
        
        guard strings.count > 1 else {
            return strings.first
        }
        
        var sequences = strings.map({ $0.makeIterator() })
        var prefix: [Character] = []
        loop: while true {
            var char: Character? = nil
            for (idx, s) in sequences.enumerated() {
                var seq = s
                
                guard let c = seq.next() else {
                    break loop
                }
                
                if let char = char {
                    let lhs = caseSensitive ? char : String(char).lowercased().first!
                    let rhs = caseSensitive ? c : String(c).lowercased().first!
                    if lhs != rhs {
                        break loop
                    }
                } else {
                    char = c
                }
                
                sequences[idx] = seq
            }
            prefix.append(char!)
        }
        
        return String(prefix)
    }
    
    internal func _ensureLastPathSeparator(_ path: String) -> String {
        if validPathSeps.contains(where: { path.hasSuffix(String($0)) }) || path.isEmpty {
            return path
        }
        
        return path + "/"
    }
    
    public var fileSystemRepresentation: UnsafePointer<Int8> {
        return FileManager.default.fileSystemRepresentation(withPath: self._swiftObject)
    }

    public func getFileSystemRepresentation(_ cname: UnsafeMutablePointer<Int8>, maxLength max: Int) -> Bool {
#if os(Windows)
        let fsr = UnsafeMutablePointer<WCHAR>.allocate(capacity: max)
        defer { fsr.deallocate() }

        guard _getFileSystemRepresentation(fsr, maxLength: max) else { return false }
        return String(decodingCString: fsr, as: UTF16.self).withCString() {
            let chars = strnlen_s($0, max)
            guard chars < max else { return false }
            cname.assign(from: $0, count: chars + 1)
            return true
        }
#else
        return _getFileSystemRepresentation(cname, maxLength: max)
#endif
    }

    internal func _getFileSystemRepresentation(_ cname: UnsafeMutablePointer<NativeFSRCharType>, maxLength max: Int) -> Bool {
        guard self.length > 0 else {
            return false
        }
        
#if os(Windows)
        var fsr = self._swiftObject

        // If we have a RFC8089 style path, e.g. `/[drive-letter]:/...`, drop
        // the leading '/', otherwise, a leading slash indicates a rooted path
        // on the drive for the current working directoyr.
        if fsr.count >= 3 {
            let index0 = fsr.startIndex
            let index1 = fsr.index(after: index0)
            let index2 = fsr.index(after: index1)

            if fsr[index0] == "/" && fsr[index1].isLetter && fsr[index2] == ":" {
                fsr.removeFirst()
            }
        }

        // Windows APIs that go through the path parser can handle forward
        // slashes in paths.  However, symlinks created with forward slashes
        // do not resolve properly, so we normalize the path separators anyways.
        fsr = fsr.replacingOccurrences(of: "/", with: "\\")

        // Drop trailing slashes unless it follows a drive letter.  On Windows,
        // the path `C:\` indicates the root directory of the `C:` drive.  The
        // path `C:` indicates the current working directory on the `C:` drive.
        while fsr.count > 1 &&
              fsr[fsr.index(before: fsr.endIndex)] == "\\" &&
              !(fsr.count == 3 &&
                fsr[fsr.index(fsr.endIndex, offsetBy: -2)] == ":" &&
                fsr[fsr.index(fsr.endIndex, offsetBy: -3)].isLetter) {
            fsr.removeLast()
        }

        return fsr.withCString(encodedAs: UTF16.self) {
            let wchars = wcsnlen_s($0, max)
            guard wchars < max else { return false }
            cname.assign(from: $0, count: wchars + 1)
            return true
        }
#else
        return CFStringGetFileSystemRepresentation(self._cfObject, cname, max)
#endif
    }

}

extension FileManager {
    public enum SearchPathDirectory: UInt {
        
        case applicationDirectory // supported applications (Applications)
        case demoApplicationDirectory // unsupported applications, demonstration versions (Demos)
        case developerApplicationDirectory // developer applications (Developer/Applications). DEPRECATED - there is no one single Developer directory.
        case adminApplicationDirectory // system and network administration applications (Administration)
        case libraryDirectory // various documentation, support, and configuration files, resources (Library)
        case developerDirectory // developer resources (Developer) DEPRECATED - there is no one single Developer directory.
        case userDirectory // user home directories (Users)
        case documentationDirectory // documentation (Documentation)
        case documentDirectory // documents (Documents)
        case coreServiceDirectory // location of CoreServices directory (System/Library/CoreServices)
        case autosavedInformationDirectory // location of autosaved documents (Documents/Autosaved)
        case desktopDirectory // location of user's desktop
        case cachesDirectory // location of discardable cache files (Library/Caches)
        case applicationSupportDirectory // location of application support files (plug-ins, etc) (Library/Application Support)
        case downloadsDirectory // location of the user's "Downloads" directory
        case inputMethodsDirectory // input methods (Library/Input Methods)
        case moviesDirectory // location of user's Movies directory (~/Movies)
        case musicDirectory // location of user's Music directory (~/Music)
        case picturesDirectory // location of user's Pictures directory (~/Pictures)
        case printerDescriptionDirectory // location of system's PPDs directory (Library/Printers/PPDs)
        case sharedPublicDirectory // location of user's Public sharing directory (~/Public)
        case preferencePanesDirectory // location of the PreferencePanes directory for use with System Preferences (Library/PreferencePanes)
        case applicationScriptsDirectory // location of the user scripts folder for the calling application (~/Library/Application Scripts/code-signing-id)
        case itemReplacementDirectory // For use with NSFileManager's URLForDirectory:inDomain:appropriateForURL:create:error:
        case allApplicationsDirectory // all directories where applications can occur
        case allLibrariesDirectory // all directories where resources can occur
        case trashDirectory // location of Trash directory
    }

    public struct SearchPathDomainMask: OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let userDomainMask = SearchPathDomainMask(rawValue: 1) // user's home directory --- place to install user's personal items (~)
        public static let localDomainMask = SearchPathDomainMask(rawValue: 2) // local to the current machine --- place to install items available to everyone on this machine (/Library)
        public static let networkDomainMask = SearchPathDomainMask(rawValue: 4) // publically available location in the local area network --- place to install items available on the network (/Network)
        public static let systemDomainMask = SearchPathDomainMask(rawValue: 8) // provided by Apple, unmodifiable (/System)
        public static let allDomainsMask = SearchPathDomainMask(rawValue: 0x0ffff) // all domains: all of the above and future items
    }
}

public func NSSearchPathForDirectoriesInDomains(_ directory: FileManager.SearchPathDirectory, _ domainMask: FileManager.SearchPathDomainMask, _ expandTilde: Bool) -> [String] {
    let knownDomains: [FileManager.SearchPathDomainMask] = [
        .userDomainMask,
        .networkDomainMask,
        .localDomainMask,
        .systemDomainMask,
    ]
    
    var result: [URL] = []
    
    for domain in knownDomains {
        if domainMask.contains(domain) {
            result.append(contentsOf: FileManager.default.urls(for: directory, in: domain))
        }
    }
    
    return result.map { (url) in
        var path = url.absoluteURL.path
        if expandTilde {
            path = NSString(string: path).expandingTildeInPath
        }
        
        return path
    }
}

public func NSHomeDirectory() -> String {
    return NSHomeDirectoryForUser(nil)!
}

public func NSHomeDirectoryForUser(_ user: String?) -> String? {
    let userName = user?._cfObject
    guard let homeDir = CFCopyHomeDirectoryURLForUser(userName)?.takeRetainedValue() else {
        return nil
    }
    
    let url: URL = homeDir._swiftObject
    return url.path
}

public func NSUserName() -> String {
    let userName = CFCopyUserName().takeRetainedValue()
    return userName._swiftObject
}

public func NSFullUserName() -> String {
    let userName = CFCopyFullUserName()
    return userName._swiftObject
}

internal func _NSCreateTemporaryFile(_ filePath: String) throws -> (Int32, String) {
    let template = filePath + ".tmp.XXXXXX"
#if os(Windows)
    let maxLength: Int = Int(MAX_PATH + 1)
    var buf: [UInt16] = Array<UInt16>(repeating: 0, count: maxLength)
    let length = GetTempPathW(DWORD(MAX_PATH), &buf)
    precondition(length <= MAX_PATH - 14, "temp path too long")
    guard "SCF".withCString(encodedAs: UTF16.self, {
      return GetTempFileNameW(buf, $0, 0, &buf) != 0
    }) else {
      throw _NSErrorWithWindowsError(GetLastError(), reading: false)
    }
    let pathResult = FileManager.default.string(withFileSystemRepresentation: String(decoding: buf, as: UTF16.self), length: wcslen(buf))
    guard let h = CreateFileW(buf,
                              GENERIC_READ | DWORD(GENERIC_WRITE),
                              DWORD(FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE),
                              nil,
                              DWORD(OPEN_EXISTING),
                              DWORD(FILE_ATTRIBUTE_NORMAL),
                              nil),
          h != INVALID_HANDLE_VALUE else {
      throw _NSErrorWithWindowsError(GetLastError(), reading: false)
    }
    // Don't close h, fd is transferred ownership
    let fd = _open_osfhandle(intptr_t(bitPattern: h), 0)
#else
    let maxLength = Int(PATH_MAX) + 1
    var buf = [Int8](repeating: 0, count: maxLength)
    let _ = template._nsObject.getFileSystemRepresentation(&buf, maxLength: maxLength)
    let fd = mkstemp(&buf)
    if fd == -1 {
        throw _NSErrorWithErrno(errno, reading: false, path: filePath)
    }
    let pathResult = FileManager.default.string(withFileSystemRepresentation: buf, length: Int(strlen(buf)))
#endif
    return (fd, pathResult)
}

internal func _NSCleanupTemporaryFile(_ auxFilePath: String, _ filePath: String) throws  {
    try FileManager.default._fileSystemRepresentation(withPath: auxFilePath, andPath: filePath, {
#if os(Windows)
        let res = CopyFileW($0, $1, /*bFailIfExists=*/false)
        try? FileManager.default.removeItem(atPath: auxFilePath)
        if !res {
          throw _NSErrorWithWindowsError(GetLastError(), reading: false)
        }
#else
        if rename($0, $1) != 0 {
            try? FileManager.default.removeItem(atPath: auxFilePath)
            throw _NSErrorWithErrno(errno, reading: false, path: filePath)
        }
#endif
    })
}
