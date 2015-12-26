// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

internal extension String {
    
    internal var _startOfLastPathComponent : String.CharacterView.Index {
        precondition(!hasSuffix("/") && length > 1)
        
        let characterView = characters
        let startPos = characterView.startIndex
        let endPos = characterView.endIndex
        var curPos = endPos
        
        // Find the beginning of the component
        while curPos > startPos {
            let prevPos = curPos.predecessor()
            if characterView[prevPos] == "/" {
                break
            }
            curPos = prevPos
        }
        return curPos

    }

    internal var _startOfPathExtension : String.CharacterView.Index? {
        precondition(!hasSuffix("/"))
        
        let characterView = self.characters
        let endPos = characterView.endIndex
        var curPos = endPos
        
        let lastCompStartPos = _startOfLastPathComponent
        
        // Find the beginning of the extension
        while curPos > lastCompStartPos {
            let prevPos = curPos.predecessor()
            let char = characterView[prevPos]
            if char == "/" {
                return nil
            } else if char == "." {
                if lastCompStartPos == prevPos {
                    return nil
                } else {
                    return curPos
                }
            }
            curPos = prevPos
        }
        return nil
    }

    internal var absolutePath: Bool {
        return hasPrefix("~") || hasPrefix("/")
    }
    
    internal static func pathWithComponents(components: [String]) -> String {
        var result = ""
        for comp in components.prefix(components.count - 1) {
            result = result._stringByAppendingPathComponent(comp._stringByFixingSlashes(), doneAppending: false)
        }
        if let last = components.last {
            result = result._stringByAppendingPathComponent(last._stringByFixingSlashes(), doneAppending: true)
        }
        return result
    }
    
    internal var pathComponents : [String] {
        var result = [String]()
        if length == 0 {
            return result
        } else {
            let characterView = characters
            var curPos = characterView.startIndex
            let endPos = characterView.endIndex
            if characterView[curPos] == "/" {
                result.append("/")
            }
            
            while curPos < endPos {
                while curPos < endPos && characterView[curPos] == "/" {
                    curPos = curPos.successor()
                }
                if curPos == endPos {
                    break
                }
                var curEnd = curPos
                while curEnd < endPos && characterView[curEnd] != "/" {
                    curEnd = curEnd.successor()
                }
                result.append(String(characterView[curPos ..< curEnd]))
                curPos = curEnd
            }
        }
        if length > 1 && hasSuffix("/") {
            result.append("/")
        }
        return result
    }
    
    internal var lastPathComponent : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return fixedSelf
        }
        
        return String(fixedSelf.characters.suffixFrom(fixedSelf._startOfLastPathComponent))
    }
    
    internal var pathExtension : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return ""
        }
        
        if let extensionPos = fixedSelf._startOfPathExtension {
            return String(fixedSelf.characters.suffixFrom(extensionPos))
        } else {
            return ""
        }
    }
    
    internal func _stringByAppendingPathComponent(str: String, doneAppending : Bool = true) -> String {
        if str.length == 0 {
            return self
        }
        if self == "" {
            return "/" + str
        }
        if self == "/" {
            return self + str
        }
        return self + "/" + str
    }
    
    internal func _stringByFixingSlashes(compress compress : Bool = true, stripTrailing: Bool = true) -> String {
        var result = self
        if compress {
            result.withMutableCharacters { characterView in
                let startPos = characterView.startIndex
                var endPos = characterView.endIndex
                var curPos = startPos
                
                while curPos < endPos {
                    if characterView[curPos] == "/" {
                        var afterLastSlashPos = curPos
                        while afterLastSlashPos < endPos && characterView[afterLastSlashPos] == "/" {
                            afterLastSlashPos = afterLastSlashPos.successor()
                        }
                        if afterLastSlashPos != curPos.successor() {
                            characterView.replaceRange(curPos ..< afterLastSlashPos, with: ["/"])
                            endPos = characterView.endIndex
                        }
                        curPos = afterLastSlashPos
                    } else {
                        curPos = curPos.successor()
                    }
                }
            }
        }
        if stripTrailing && result.length > 1 && result.hasSuffix("/") {
            result.removeAtIndex(result.characters.endIndex.predecessor())
        }
        return result
    }
}

public extension NSString {
    
    public var absolutePath: Bool {
        return hasPrefix("~") || hasPrefix("/")
    }
    
    public static func pathWithComponents(components: [String]) -> String {
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
        var result = [String]()
        if length == 0 {
            return result
        } else {
            let characterView = _swiftObject.characters
            var curPos = characterView.startIndex
            let endPos = characterView.endIndex
            if characterView[curPos] == "/" {
                result.append("/")
            }
            
            while curPos < endPos {
                while curPos < endPos && characterView[curPos] == "/" {
                    curPos = curPos.successor()
                }
                if curPos == endPos {
                    break
                }
                var curEnd = curPos
                while curEnd < endPos && characterView[curEnd] != "/" {
                    curEnd = curEnd.successor()
                }
                result.append(String(characterView[curPos ..< curEnd]))
                curPos = curEnd
            }
        }
        if length > 1 && hasSuffix("/") {
            result.append("/")
        }
        return result
    }
    
    public var lastPathComponent : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return fixedSelf
        }
        
        return String(fixedSelf.characters.suffixFrom(fixedSelf._startOfLastPathComponent))
    }
    
    public var stringByDeletingLastPathComponent : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf == "/" {
            return fixedSelf
        }
        if fixedSelf.length <= 1 {
            return ""
        }
        
        return String(fixedSelf.characters.prefixUpTo(fixedSelf._startOfLastPathComponent))
    }
    
    internal func _stringByFixingSlashes(compress compress : Bool = true, stripTrailing: Bool = true) -> String {
        var result = _swiftObject
        if compress {
            result.withMutableCharacters { characterView in
                let startPos = characterView.startIndex
                var endPos = characterView.endIndex
                var curPos = startPos
                
                while curPos < endPos {
                    if characterView[curPos] == "/" {
                        var afterLastSlashPos = curPos
                        while afterLastSlashPos < endPos && characterView[afterLastSlashPos] == "/" {
                            afterLastSlashPos = afterLastSlashPos.successor()
                        }
                        if afterLastSlashPos != curPos.successor() {
                            characterView.replaceRange(curPos ..< afterLastSlashPos, with: ["/"])
                            endPos = characterView.endIndex
                        }
                        curPos = afterLastSlashPos
                    } else {
                        curPos = curPos.successor()
                    }
                }
            }
        }
        if stripTrailing && result.hasSuffix("/") {
            result.removeAtIndex(result.characters.endIndex.predecessor())
        }
        return result
    }
    
    internal func _stringByAppendingPathComponent(str: String, doneAppending : Bool = true) -> String {
        if str.length == 0 {
            return _swiftObject
        }
        if self == "" {
            return "/" + str
        }
        if self == "/" {
            return _swiftObject + str
        }
        return _swiftObject + "/" + str
    }
    
    public func stringByAppendingPathComponent(str: String) -> String {
        return _stringByAppendingPathComponent(str)
    }
    
    public var pathExtension : String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return ""
        }

        if let extensionPos = fixedSelf._startOfPathExtension {
            return String(fixedSelf.characters.suffixFrom(extensionPos))
        } else {
            return ""
        }
    }
    
    public var stringByDeletingPathExtension: String {
        let fixedSelf = _stringByFixingSlashes()
        if fixedSelf.length <= 1 {
            return fixedSelf
        }
        
        if let extensionPos = fixedSelf._startOfPathExtension {
            return String(fixedSelf.characters.prefixUpTo(extensionPos))
        } else {
            return fixedSelf
        }
    }
    
    public func stringByAppendingPathExtension(str: String) -> String? {
        if str.hasPrefix("/") || self == "" || self == "/" {
            print("Cannot append extension \(str) to path \(self)")
            return nil
        }
        let result = _swiftObject + str._stringByFixingSlashes(compress: false, stripTrailing: true)
        return result._stringByFixingSlashes()
    }

    public var stringByStandardizingPath: String {
        NSUnimplemented()
    }
    
    public var stringByResolvingSymlinksInPath: String {
        NSUnimplemented()
    }
    
    public func stringsByAppendingPaths(paths: [String]) -> [String] {
        if self == "" {
            return paths
        }
        return paths.map(stringByAppendingPathComponent)
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func completePathIntoString(inout outputName: NSString?, caseSensitive flag: Bool, inout matchesIntoArray outputArray: [NSString], filterTypes: [String]?) -> Int {
        // FIXME: I guess, it should be NSURL(fileURLWithPath: _storage), but it is not implemented yet.
        guard !_storage.isEmpty else {
            return 0
        }
        
        guard let url = NSURL(string: _storage) else {
            return 0
        }
        
        let normalizedTypes = flag ? filterTypes : filterTypes?.map { $0.lowercaseString }
        let types = Set<String>(normalizedTypes ?? [])
        let compareOptions = flag ? [] : NSStringCompareOptions.CaseInsensitiveSearch
        
        var isDirectory = false
        let isAbsolutePath = NSFileManager.defaultManager().fileExistsAtPath(_storage, isDirectory: &isDirectory)
        let searchAllFilesInDirectory = isAbsolutePath && isDirectory
        
        guard let urlWhereToSearch = searchAllFilesInDirectory ? url : url.URLByDeletingLastPathComponent else {
            return 0
        }
        
        var matches: [String] = []
        
        let namePrefix = url.lastPathComponent ?? ""

        let enumerator = NSFileManager.defaultManager().enumeratorAtURL(urlWhereToSearch, includingPropertiesForKeys: nil, options: .SkipsSubdirectoryDescendants, errorHandler: nil)
        
        while let item = enumerator?.nextObject() as? NSURL {
            
            let itemName = item.lastPathComponent ?? ""
            let itemExtension = item.pathExtension ?? ""
            let normalizedExtension = flag ? itemExtension : itemExtension.lowercaseString
            
            let matchByName = searchAllFilesInDirectory || itemName.bridge().rangeOfString(namePrefix, options: compareOptions).location == 0
            let matchByExtension = types.isEmpty || types.contains(normalizedExtension)
            
            if matchByName && matchByExtension {
                matches.append(itemName)
            }
        }
        
        let commonPath = urlWhereToSearch.absoluteString!.bridge().stringByReplacingOccurrencesOfString("file://", withString: "")
        
        if let lcp = _longestCommonPrefix(matches, caseSensitive: flag) {
           outputName = (commonPath + lcp).bridge()
        }
        
        outputArray = matches.map({ (commonPath + $0).bridge() })
        
        return matches.count
    }
    
    internal func _longestCommonPrefix(strings: [String], caseSensitive: Bool) -> String? {
        guard strings.count > 0 else {
            return nil
        }
        
        guard strings.count > 1 else {
            return strings.first
        }
        
        var sequences = strings.map({ $0.characters.generate() })
        var prefix: [Character] = []
        loop: while true {
            var char: Character? = nil
            for (idx, s) in sequences.enumerate() {
                var seq = s
                
                guard let c = seq.next() else {
                    break loop
                }
                
                if char != nil {
                    let lhs = caseSensitive ? char : String(char!).lowercaseString.characters.first!
                    let rhs = caseSensitive ? c : String(c).lowercaseString.characters.first!
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
    
    public var fileSystemRepresentation : UnsafePointer<Int8> {
        NSUnimplemented()
    }
    
    public func getFileSystemRepresentation(cname: UnsafeMutablePointer<Int8>, maxLength max: Int) -> Bool {
        guard self.length > 0 else {
            return false
        }
        
        return CFStringGetFileSystemRepresentation(self._cfObject, cname, max)
    }

}

public enum NSSearchPathDirectory : UInt {
    
    case ApplicationDirectory // supported applications (Applications)
    case DemoApplicationDirectory // unsupported applications, demonstration versions (Demos)
    case DeveloperApplicationDirectory // developer applications (Developer/Applications). DEPRECATED - there is no one single Developer directory.
    case AdminApplicationDirectory // system and network administration applications (Administration)
    case LibraryDirectory // various documentation, support, and configuration files, resources (Library)
    case DeveloperDirectory // developer resources (Developer) DEPRECATED - there is no one single Developer directory.
    case UserDirectory // user home directories (Users)
    case DocumentationDirectory // documentation (Documentation)
    case DocumentDirectory // documents (Documents)
    case CoreServiceDirectory // location of CoreServices directory (System/Library/CoreServices)
    case AutosavedInformationDirectory // location of autosaved documents (Documents/Autosaved)
    case DesktopDirectory // location of user's desktop
    case CachesDirectory // location of discardable cache files (Library/Caches)
    case ApplicationSupportDirectory // location of application support files (plug-ins, etc) (Library/Application Support)
    case DownloadsDirectory // location of the user's "Downloads" directory
    case InputMethodsDirectory // input methods (Library/Input Methods)
    case MoviesDirectory // location of user's Movies directory (~/Movies)
    case MusicDirectory // location of user's Music directory (~/Music)
    case PicturesDirectory // location of user's Pictures directory (~/Pictures)
    case PrinterDescriptionDirectory // location of system's PPDs directory (Library/Printers/PPDs)
    case SharedPublicDirectory // location of user's Public sharing directory (~/Public)
    case PreferencePanesDirectory // location of the PreferencePanes directory for use with System Preferences (Library/PreferencePanes)
    case ApplicationScriptsDirectory // location of the user scripts folder for the calling application (~/Library/Application Scripts/code-signing-id)
    case ItemReplacementDirectory // For use with NSFileManager's URLForDirectory:inDomain:appropriateForURL:create:error:
    case AllApplicationsDirectory // all directories where applications can occur
    case AllLibrariesDirectory // all directories where resources can occur
    case TrashDirectory // location of Trash directory
}

public struct NSSearchPathDomainMask : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let UserDomainMask = NSSearchPathDomainMask(rawValue: 1) // user's home directory --- place to install user's personal items (~)
    public static let LocalDomainMask = NSSearchPathDomainMask(rawValue: 2) // local to the current machine --- place to install items available to everyone on this machine (/Library)
    public static let NetworkDomainMask = NSSearchPathDomainMask(rawValue: 4) // publically available location in the local area network --- place to install items available on the network (/Network)
    public static let SystemDomainMask = NSSearchPathDomainMask(rawValue: 8) // provided by Apple, unmodifiable (/System)
    public static let AllDomainsMask = NSSearchPathDomainMask(rawValue: 0x0ffff) // all domains: all of the above and future items
}

public func NSSearchPathForDirectoriesInDomains(directory: NSSearchPathDirectory, _ domainMask: NSSearchPathDomainMask, _ expandTilde: Bool) -> [String] {
    NSUnimplemented()
}
