// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


#if os(Windows)
import WinSDK
#endif

@_spi(SwiftCorelibsFoundation) @_exported import FoundationEssentials

internal import Synchronization

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(Bionic)
@preconcurrency import Bionic
#endif

open class NSURL : NSObject, NSSecureCoding, NSCopying, @unchecked Sendable {
    internal let _url: URL

    private let _resourceStorageValue = Mutex<URLResourceValuesStorage?>(nil)

    internal init(_url url: URL) {
        _url = url
        super.init()
    }

    var _resourceStorage: URLResourceValuesStorage? {
        guard isFileURL else { return nil }

        return _resourceStorageValue.withLock { value in
            if let storage = value {
                return storage
            }
            let storage = URLResourceValuesStorage()
            value = storage
            return storage
        }
    }

    var _resourceStorageIfPresent: URLResourceValuesStorage? {
        guard isFileURL else { return nil }

        return _resourceStorageValue.withLock { $0 }
    }

    open override var hash: Int {
        _url.hashValue
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSURL else { return false }
        return _url == other._url
    }

    open override var description: String {
        _url.description
    }

    open override func copy() -> Any {
        return copy(with: nil)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        if isFileURL {
            let newURL = NSURL(_url: _url)
            if let storage = _resourceStorageIfPresent {
                newURL._resourceStorageValue.withLock { $0 = URLResourceValuesStorage(copying: storage) }
            }
            return newURL
        } else {
            return self
        }
    }
    
    public static var supportsSecureCoding: Bool { return true }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        let base = aDecoder.decodeObject(of: NSURL.self, forKey:"NS.base")?._swiftObject
        let relative = aDecoder.decodeObject(of: NSString.self, forKey:"NS.relative")

        if relative == nil {
            return nil
        }

        self.init(string: String._unconditionallyBridgeFromObjectiveC(relative!), relativeTo: base)
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        aCoder.encode(self.baseURL?._nsObject, forKey:"NS.base")
        aCoder.encode(self.relativeString._bridgeToObjectiveC(), forKey:"NS.relative")
    }
    
    public init(fileURLWithPath path: String, isDirectory isDir: Bool, relativeTo baseURL: URL?) {
        _url = URL(fileURLWithPath: path, isDirectory: isDir, relativeTo: baseURL)
        super.init()
    }

    public init(fileURLWithPath path: String, relativeTo baseURL: URL?) {
        _url = URL(fileURLWithPath: path, relativeTo: baseURL)
        super.init()
    }

    public convenience init(fileURLWithPath path: String, isDirectory isDir: Bool) {
        self.init(fileURLWithPath: path, isDirectory: isDir, relativeTo: nil)
    }

    public init(fileURLWithPath path: String) {
        _url = URL(fileURLWithPath: path)
        super.init()
    }
    
    public convenience init(fileURLWithFileSystemRepresentation path: UnsafePointer<Int8>, isDirectory isDir: Bool, relativeTo baseURL: URL?) {

        let pathString = String(cString: path)
        self.init(fileURLWithPath: pathString, isDirectory: isDir, relativeTo: baseURL)
    }
    
    public convenience init?(string URLString: String) {
        self.init(string: URLString, relativeTo:nil)
    }
    
    public init?(string URLString: String, relativeTo baseURL: URL?) {
        guard let url = URL(string: URLString, relativeTo: baseURL) else {
            _url = URL(_stringOrEmpty: "")!
            super.init()
            return
        }
        _url = url
        super.init()
    }

    /// Interprets the bytes as UTF-8, or as ISO Latin 1 if they are not valid UTF-8.
    private static func _string(fromURLData data: Data) -> String {
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        return String(String.UnicodeScalarView(data.map { Unicode.Scalar($0) }))
    }

    public init(dataRepresentation data: Data, relativeTo baseURL: URL?) {
        let string = NSURL._string(fromURLData: data)
        // Unlike init(string:relativeTo:), this must not fail, so invalid characters are encoded.
        guard let url = URL(string: string, relativeTo: baseURL) ?? URL(string: string, encodingInvalidCharacters: true) else {
            // Last fallback
            _url = URL(_stringOrEmpty: "")!
            super.init()
            return
        }
        _url = url
        super.init()
    }

    public init(absoluteURLWithDataRepresentation data: Data, relativeTo baseURL: URL?) {
        let string = NSURL._string(fromURLData: data)
        guard let url = URL(string: string, relativeTo: baseURL) ?? URL(string: string, encodingInvalidCharacters: true) else {
            // Last fallback
            _url = URL(dataRepresentation: Data(), relativeTo: baseURL, isAbsolute: true) ?? URL(_stringOrEmpty: "")!
            super.init()
            return
        }
        _url = url
        super.init()
    }
    
    /* Returns the data representation of the URL's relativeString. If the URL was initialized with -initWithData:relativeTo:, the data representation returned are the same bytes as those used at initialization; otherwise, the data representation returned are the bytes of the relativeString encoded with NSUTF8StringEncoding.
    */
    open var dataRepresentation: Data {
        _url.dataRepresentation
    }

    open var absoluteString: String {
        _url.absoluteString
    }

    // The relative portion of a URL.  If baseURL is nil, or if the receiver is itself absolute, this is the same as absoluteString
    open var relativeString: String {
        _url.relativeString
    }

    open var baseURL: URL? {
        _url.baseURL
    }

    // if the receiver is itself absolute, this will return self.
    open var absoluteURL: URL? {
        _url.absoluteURL
    }

    /* Any URL is composed of these two basic pieces.  The full URL would be the concatenation of [myURL scheme], ':', [myURL resourceSpecifier]
    */
    open var scheme: String? {
        _url.scheme
    }

    internal var _isAbsolute : Bool {
        self.baseURL == nil && self.scheme != nil
    }
    
    open var resourceSpecifier: String? {
        // Note that this does NOT have the same meaning as CFURL's resource specifier, which, for decomposeable URLs is merely that portion of the URL which comes after the path.  NSURL means everything after the scheme.
        guard _isAbsolute, let scheme = scheme else {
            return self.relativeString
        }
        return String(absoluteString.dropFirst(scheme.count + 1))
    }

    /* If the URL conforms to rfc 1808 (the most common form of URL), the following accessors will return the various components; otherwise they return nil.  The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is @"//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    */
    open var host: String? {
        _url.host(percentEncoded: false)
    }

    open var port: NSNumber? {
        guard let port = _url.port else {
            return nil
        }
        return NSNumber(value: port)
    }

    open var user: String? {
        _url.user(percentEncoded: false)
    }

    open var password: String? {
        // For historical reasons, the password string should _not_ have its percent escapes removed.
        _url.password(percentEncoded: true)
    }

    open var path: String? {
        _url.path
    }

    open var fragment: String? {
        _url.fragment(percentEncoded: true)
    }

    @available(swift, deprecated: 5.3, message: "The parameterString property is deprecated. When executing on Swift 5.3 or later, parameterString will always return nil, and the path method will return the complete path including the semicolon separator and params component if the URL string contains them.")
    open var parameterString: String? {
        nil
    }
    
    open var query: String? {
        _url.query(percentEncoded: true)
    }
    
    // The same as path if baseURL is nil
    open var relativePath: String? {
        _url.relativePath
    }
    
    /* Determines if a given URL string's path represents a directory (i.e. the path component in the URL string ends with a '/' character). This does not check the resource the URL refers to.
    */
    open var hasDirectoryPath: Bool {
        _url.hasDirectoryPath
    }

    /* Returns the URL's path in file system representation. File system representation is a null-terminated C string with canonical UTF-8 encoding.
    */
    open func getFileSystemRepresentation(_ buffer: UnsafeMutablePointer<Int8>, maxLength maxBufferLength: Int) -> Bool {
        return _url.withUnsafeFileSystemRepresentation { representation in
            guard let representation = representation else {
                return false
            }
            let size = strlen(representation) + 1
            guard size <= maxBufferLength else {
                return false
            }
            buffer.update(from: representation, count: size)
            return true
        }
    }

    /* Returns the URL's path in file system representation. File system representation is a null-terminated C string with canonical UTF-8 encoding. The returned C string will be automatically freed just as a returned object would be released; your code should copy the representation or use getFileSystemRepresentation:maxLength: if it needs to store the representation outside of the autorelease context in which the representation is created.
    */
    
    // Memory leak. See https://github.com/apple/swift-corelibs-foundation/blob/master/Docs/Issues.md
    open var fileSystemRepresentation: UnsafePointer<Int8> {
#if os(Windows)
        if let representation = path?.replacingOccurrences(of: "/", with: "\\") {
            let buffer = representation.withCString {
                let len = strlen($0)
                let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: len + 1)
                buffer.initialize(from: $0, count: len + 1)
                return buffer
            }
            return UnsafePointer(buffer)
        }
#else
        let bufSize = Int(PATH_MAX + 1)

        let _fsrBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: bufSize)
        _fsrBuffer.initialize(repeating: 0, count: bufSize)

        if getFileSystemRepresentation(_fsrBuffer, maxLength: bufSize) {
            return UnsafePointer(_fsrBuffer)
        }
#endif

        // FIXME: This used to return nil, but the corresponding Darwin
        // implementation is marked as non-nullable.
        fatalError("URL cannot be expressed in the filesystem representation;" +
                   "use getFileSystemRepresentation to handle this case")
    }

    // Whether the scheme is file:; if myURL.isFileURL is true, then myURL.path is suitable for input into FileManager or NSPathUtilities.
    open var isFileURL: Bool {
        _url.isFileURL
    }

    /* A string constant for the "file" URL scheme. If you are using this to compare to a URL's scheme to see if it is a file URL, you should instead use the NSURL fileURL property -- the fileURL property is much faster. */
    open var standardized: URL? {
        let standardized = _url.standardized
        guard isFileURL else {
            return standardized
        }

        // Resolving "." and ".." can change whether the last component looks like a directory, but the result keeps the directory flag of the receiver.
        let path = baseURL == nil ? standardized.path : standardized.relativePath
        return URL(fileURLWithPath: NSURL._removingTrailingSlash(path), isDirectory: hasDirectoryPath, relativeTo: baseURL)
    }

    /// A path never ends in a "/", unless the path is only a "/".
    private static func _removingTrailingSlash(_ path: String) -> String {
        guard path.count > 1, path.hasSuffix("/") else {
            return path
        }
        return String(path.dropLast())
    }

    /* Returns whether the URL's resource exists and is reachable. This method synchronously checks if the resource's backing store is reachable. Checking reachability is appropriate when making decisions that do not require other immediate operations on the resource, e.g. periodic maintenance of UI state that depends on the existence of a specific document. When performing operations such as opening a file or copying resource properties, it is more efficient to simply try the operation and handle failures. If this method returns NO, the optional error is populated. This method is currently applicable only to URLs for file system resources. For other URL types, NO is returned. Symbol is present in iOS 4, but performs no operation.
    */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    // TODO: should be `checkResourceIsReachableAndReturnError` with autoreleased error parameter.
    // Currently Autoreleased pointers is not supported on Linux.
    open func checkResourceIsReachable() throws -> Bool {
        guard isFileURL,
            let path = path else {
                throw NSError(domain: NSCocoaErrorDomain,
                              code: CocoaError.Code.fileReadUnsupportedScheme.rawValue)
        }
        
        guard FileManager.default.fileExists(atPath: path) else {
            throw NSError(domain: NSCocoaErrorDomain,
                          code: CocoaError.Code.fileReadNoSuchFile.rawValue,
                          userInfo: [
                            "NSURL" : self,
                            "NSFilePath" : path])
        }
        
        return true
    }

    /* Returns a file path URL that refers to the same resource as a specified URL. File path URLs use a file system style path. An error will occur if the url parameter is not a file URL. A file reference URL's resource must exist and be reachable to be converted to a file path URL. Symbol is present in iOS 4, but performs no operation.
    */
    open var filePathURL: URL? {
        guard isFileURL else {
            return nil
        }

        return URL(string: absoluteString)
    }

    open func removeAllCachedResourceValues() {
        _resourceStorage?.removeAllCachedResourceValues()
    }
    open func removeCachedResourceValue(forKey key: URLResourceKey) {
        _resourceStorage?.removeCachedResourceValue(forKey: key)
    }
    open  func getResourceValue(_ value: inout AnyObject?, forKey key: URLResourceKey) throws {
        guard let storage = _resourceStorage else { value = nil; return }
        try storage.getResourceValue(&value, forKey: key, url: self)
    }
    open func resourceValues(forKeys keys: [URLResourceKey]) throws -> [URLResourceKey : Any] {
        guard let storage = _resourceStorage else { return [:] }
        return try storage.resourceValues(forKeys: keys, url: self)
    }
    open func setResourceValue(_ value: Any?, forKey key: URLResourceKey) throws {
        guard let storage = _resourceStorage else { return }
        try storage.setResourceValue(value, forKey: key, url: self)
    }
    open func setResourceValues(_ keyedValues: [URLResourceKey : Any]) throws {
        guard let storage = _resourceStorage else { return }
        try storage.setResourceValues(keyedValues, url: self)
    }
    open func setTemporaryResourceValue(_ value: Any?, forKey key: URLResourceKey) {
        guard let storage = _resourceStorage else { return }
        storage.setTemporaryResourceValue(value, forKey: key)
    }
}

internal final class URLResourceValuesStorage: NSObject, Sendable {
    // Resource values are arbitrary client values (`Any`), so we cannot check that they are `Sendable`. They are only read and written while holding the lock.
    private struct Cache: @unchecked Sendable {
        var values: [URLResourceKey: Any] = [:]
    }

    private let cache: Mutex<Cache>

    func removeAllCachedResourceValues() {
        cache.withLock { $0.values = [:] }
    }

    func removeCachedResourceValue(forKey key: URLResourceKey) {
        cache.withLock { $0.values[key] = nil }
    }

    func setTemporaryResourceValue(_ value: Any?, forKey key: URLResourceKey) {
        cache.withLock { $0.values[key] = value }
    }

    func getResourceValue(_ value: inout AnyObject?,
                          forKey key: URLResourceKey, url: NSURL) throws {
        var cached: Any?
        cache.withLock { cached = $0.values[key] }

        if let cached = cached {
            value = __SwiftValue.store(cached)
            return
        }

        let fetchedValues = try read([key], for: url)
        if let fetched = fetchedValues[key] {
            cache.withLock { $0.values[key] = fetched }
            value = __SwiftValue.store(fetched)
        } else {
            value = nil
        }
    }

    func resourceValues(forKeys keys: [URLResourceKey], url: NSURL) throws -> [URLResourceKey : Any] {
        var result: [URLResourceKey : Any] = [:]
        var keysToFetch: [URLResourceKey] = []
        cache.withLock { cache in
            for key in keys {
                if let value = cache.values[key] {
                    result[key] = value
                } else {
                    keysToFetch.append(key)
                }
            }
        }

        if keysToFetch.count > 0 {
            let found = try read(keysToFetch, for: url).compactMapValues { $0 }

            cache.withLock { $0.values.merge(found, uniquingKeysWith: { $1 }) }

            result.merge(found, uniquingKeysWith: { $1 })
        }

        return result
    }

    func setResourceValue(_ value: Any?, forKey key: URLResourceKey, url: NSURL) throws {
        try write([key: value], to: url)

        cache.withLock { $0.values[key] = value }
    }

    func setResourceValues(_ keyedValues: [URLResourceKey : Any], url: NSURL) throws {
        try write(keyedValues, to: url)

        cache.withLock { $0.values.merge(keyedValues, uniquingKeysWith: { $1 }) }
    }

    internal override init() {
        cache = Mutex(Cache())
        super.init()
    }

    internal init(copying storage: URLResourceValuesStorage) {
        cache = Mutex(storage.cache.withLock { $0 })
        super.init()
    }
}

extension NSCharacterSet {
    
    // Predefined character sets for the six URL components and subcomponents which allow percent encoding. These character sets are passed to -stringByAddingPercentEncodingWithAllowedCharacters:.
    
    // Returns a character set containing the characters allowed in an URL's user subcomponent.
    public class var urlUserAllowed: CharacterSet {
        return CharacterSet.urlUserAllowed
    }
    
    // Returns a character set containing the characters allowed in an URL's password subcomponent.
    public class var urlPasswordAllowed: CharacterSet {
        return CharacterSet.urlPasswordAllowed
    }
    
    // Returns a character set containing the characters allowed in an URL's host subcomponent.
    public class var urlHostAllowed: CharacterSet {
        return CharacterSet.urlHostAllowed
    }
    
    // Returns a character set containing the characters allowed in an URL's path component. ';' is a legal path character, but it is recommended that it be percent-encoded for best compatibility with NSURL (-stringByAddingPercentEncodingWithAllowedCharacters: will percent-encode any ';' characters if you pass the URLPathAllowedCharacterSet).
    public class var urlPathAllowed: CharacterSet {
        return CharacterSet.urlPathAllowed
    }
    
    // Returns a character set containing the characters allowed in an URL's query component.
    public class var urlQueryAllowed: CharacterSet {
        return CharacterSet.urlQueryAllowed
    }
    
    // Returns a character set containing the characters allowed in an URL's fragment component.
    public class var urlFragmentAllowed: CharacterSet {
        return CharacterSet.urlFragmentAllowed
    }
}

extension NSString {
    
    // Returns a new string made from the receiver by replacing all characters not in the allowedCharacters set with percent encoded characters. UTF-8 encoding is used to determine the correct percent encoded characters. Entire URL strings cannot be percent-encoded. This method is intended to percent-encode an URL component or subcomponent string, NOT the entire URL string. Any characters in allowedCharacters outside of the 7-bit ASCII range are ignored.
    public func addingPercentEncoding(withAllowedCharacters allowedCharacters: CharacterSet) -> String? {
        return _swiftObject.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
    
    // Returns a new string made from the receiver by replacing all percent encoded sequences with the matching UTF-8 characters.
    public var removingPercentEncoding: String? {
        return _swiftObject.removingPercentEncoding
    }
}

extension NSURL {
    
    /* The following methods work on the path portion of a URL in the same manner that the NSPathUtilities methods on NSString do.
    */
    public class func fileURL(withPathComponents components: [String]) -> URL? {
        let path = NSString.path(withComponents: components)
        if components.last == "/" {
            return URL(fileURLWithPath: path, isDirectory: true)
        } else {
            return URL(fileURLWithPath: path)
        }
    }
    
    public var pathComponents: [String]? {
        _url.pathComponents
    }
    
    public var lastPathComponent: String? {
        _url.lastPathComponent
    }
    
    public var pathExtension: String? {
        _url.pathExtension
    }
    
    public func appendingPathComponent(_ pathComponent: String) -> URL? {
        _url.appendingPathComponent(pathComponent)
    }
    
    public func appendingPathComponent(_ pathComponent: String, isDirectory: Bool) -> URL? {
        return _url.appendingPathComponent(pathComponent, isDirectory: isDirectory)
    }
    
    public var deletingLastPathComponent: URL? {
        return _url.deletingLastPathComponent()
    }
    
    public func appendingPathExtension(_ pathExtension: String) -> URL? {
        return _url.appendingPathExtension(pathExtension)
    }
    
    public var deletingPathExtension: URL? {
        return _url.deletingPathExtension()
    }
    
    /* The following methods work only on `file:` scheme URLs; for non-`file:` scheme URLs, these methods return the URL unchanged.
    */
    public var standardizingPath: URL? {
        guard isFileURL else {
            return _url
        }

        // As with standardized, the result keeps the directory flag of the receiver.
        return URL(fileURLWithPath: NSURL._removingTrailingSlash(_url.standardizedFileURL.path), isDirectory: hasDirectoryPath)
    }
    
    public var resolvingSymlinksInPath: URL? {
        guard isFileURL else {
            return _url
        }

        // The directory flag comes from the file system, so a path that does not exist is not a directory.
        return URL(fileURLWithPath: NSURL._removingTrailingSlash(_url.resolvingSymlinksInPath().path))
    }
}

extension NSURL: _SwiftBridgeable {
    typealias SwiftType = URL
    internal var _swiftObject: SwiftType { return _url }
}

extension URL : _NSBridgeable {
    typealias NSType = NSURL
    internal var _nsObject: NSType { return NSURL(_url: self) }
}

extension NSURL : _StructTypeBridgeable {
    public typealias _StructType = URL

    public func _bridgeToSwift() -> _StructType {
        return _url
    }
}

// MARK: Fetching URL resource values

internal class _URLFileResourceIdentifier: NSObject {
    let path: String
    let inode: Int
    let volumeIdentifier: Int
    
    init(path: String, inode: Int, volumeIdentifier: Int) {
        self.path = path
        self.inode = inode
        self.volumeIdentifier = volumeIdentifier
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? _URLFileResourceIdentifier else {
            return false
        }
        
        return path == other.path || (inode == other.inode && volumeIdentifier == other.volumeIdentifier)
    }
    
    override var hash: Int {
        return path._nsObject.hashValue ^ inode ^ volumeIdentifier
    }
}

fileprivate extension URLResourceValuesStorage {
    func read(_ keys: [URLResourceKey], for url: NSURL) throws -> [URLResourceKey: Any?] {
        var result: [URLResourceKey: Any?] = [:]
        
        let fm = FileManager.default
        let path = url.path ?? ""
        
        // Memoized access to attributes:
        
        var fileAttributesStorage: [FileAttributeKey: Any]? = nil
        func attributes() throws -> [FileAttributeKey: Any] {
            if let storage = fileAttributesStorage {
                return storage
            } else {
                let storage = try fm._attributesOfItemIncludingPrivate(atPath: path)
                fileAttributesStorage = storage
                return storage
            }
        }
        func attribute(_ fileAttributeKey: FileAttributeKey) throws -> Any? {
            let attributeValues = try attributes()
            return attributeValues[fileAttributeKey]
        }
        
        // Memoized access to lstat:
        
        var urlStatStorage: stat?
        func urlStat() throws -> stat {
            if let storage = urlStatStorage {
                return storage
            } else {
                let storage = try fm._lstatFile(atPath: path)
                urlStatStorage = storage
                return storage
            }
        }
        
        // Memoized access to volume URLs:
        
        var volumeURLsStorage: [URL]?
        var volumeURLs: [URL] {
            if let storage = volumeURLsStorage {
                return storage
            } else {
                let storage = fm.mountedVolumeURLs(includingResourceValuesForKeys: nil) ?? []
                volumeURLsStorage = storage
                return storage
            }
        }
        
        var volumeAttributesStorage: [FileAttributeKey: Any]?
        var blockSizeStorage: UInt64?
        func volumeAttributes() throws -> [FileAttributeKey: Any] {
            if let storage = volumeAttributesStorage {
                return storage
            } else {
                let (storage, block) = try fm._attributesOfFileSystemIncludingBlockSize(forPath: path)
                volumeAttributesStorage = storage
                blockSizeStorage = block
                return storage
            }
        }
        func blockSize() throws -> UInt64? {
            _ = try volumeAttributes()
            return blockSizeStorage
        }
        func volumeAttribute(_ fileAttributeKey: FileAttributeKey) throws -> Any? {
            let attributeValues = try volumeAttributes()
            return attributeValues[fileAttributeKey]
        }
        
        var volumeURLStorage: (searched: Bool, url: URL?)?
        func volumeURL() throws -> URL? {
            if let url = volumeURLStorage {
                return url.url
            }
            
            var foundURL: URL?
            
            for volumeURL in volumeURLs {
                var relationship: FileManager.URLRelationship = .other
                try fm.getRelationship(&relationship, ofDirectoryAt: volumeURL, toItemAt: url._swiftObject)
                if relationship == .same || relationship == .contains {
                    foundURL = volumeURL
                    break
                }
            }
            
            volumeURLStorage = (searched: true, url: foundURL)
            return foundURL
        }
        
        for key in keys {
            switch key {
            case .nameKey:
                result[key] = url.lastPathComponent
            case .localizedNameKey:
                result[key] = fm.displayName(atPath: path)
            case .isRegularFileKey:
                result[key] = try attribute(.type) as? FileAttributeType == FileAttributeType.typeRegular
            case .isDirectoryKey:
                result[key] = try attribute(.type) as? FileAttributeType == FileAttributeType.typeDirectory
            case .isSymbolicLinkKey:
                result[key] = try attribute(.type) as? FileAttributeType == FileAttributeType.typeSymbolicLink
            case .isVolumeKey:
                result[key] = volumeURLs.contains(url._swiftObject)
            case .isPackageKey:
                result[key] = try attribute(.type) as? FileAttributeType == FileAttributeType.typeDirectory && url.pathExtension != nil && url.pathExtension != ""
            case .isApplicationKey:
                #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
                result[key] = try attribute(.type) as? FileAttributeType == FileAttributeType.typeDirectory && url.pathExtension == "app"
                #else
                result[key] = false
                #endif
            case .applicationIsScriptableKey:
                // Not supported.
                break
            case .isSystemImmutableKey:
                result[key] = try attribute(._systemImmutable) as? Bool == true
            case .isUserImmutableKey:
                result[key] = try attribute(.immutable) as? Bool == true
            case .isHiddenKey:
                result[key] = try attribute(._hidden) as? Bool == true
            case .hasHiddenExtensionKey:
                result[key] = false // Most OSes do not have a way to record this.
            case .creationDateKey:
                result[key] = try attribute(.creationDate)
            case .contentAccessDateKey:
                result[key] = try attribute(._accessDate)
            case .contentModificationDateKey:
                result[key] = try attribute(.modificationDate)
            case .attributeModificationDateKey:
                // We do not support this in a cross-platform manner.
                break
            case .linkCountKey:
                result[key] = Int(try urlStat().st_nlink)
            case .parentDirectoryURLKey:
                result[key] = url.deletingLastPathComponent
            case .volumeURLKey:
                result[key] = try volumeURL()
                
            case .fileResourceIdentifierKey:
                result[key] = _URLFileResourceIdentifier(path: path, inode: Int(try urlStat().st_ino), volumeIdentifier: Int(try urlStat().st_dev))
                
            case .volumeIdentifierKey:
                result[key] = try volumeAttribute(.systemNumber)
                
            case .preferredIOBlockSizeKey:
                result[key] = try blockSize()
                
            case .isReadableKey:
                result[key] = fm.isReadableFile(atPath: path)
            case .isWritableKey:
                result[key] = fm.isWritableFile(atPath: path)
            case .isExecutableKey:
                result[key] = fm.isExecutableFile(atPath: path)
            case .pathKey:
                result[key] = url.path
            case .canonicalPathKey:
                result[key] = try fm._canonicalizedPath(toFileAtPath: path)
            case .fileResourceTypeKey:
                result[key] = try attribute(.type)
            case .totalFileSizeKey: fallthrough // FIXME: This should add the size of any metadata.
            case .fileSizeKey:
                result[key] = try attribute(.size)
            case .totalFileAllocatedSizeKey: fallthrough // FIXME: This should add the size of any metadata.
            case .fileAllocatedSizeKey:
#if !os(Windows)
                let stat = try urlStat()
                result[key] = Int(stat.st_blocks) * Int(stat.st_blksize)
#endif
            case .isAliasFileKey:
                // swift-corelibs-foundation does not support aliases and bookmarks.
                break
            case .volumeLocalizedFormatDescriptionKey:
                // FIXME: This should have different names for different kinds of volumes, and be localized.
                result[key] = "Volume"
            case .volumeTotalCapacityKey:
                result[key] = try volumeAttribute(.systemSize)
            case .volumeAvailableCapacityKey:
                result[key] = try volumeAttribute(.systemFreeSize)
            case .volumeResourceCountKey:
                result[key] = try volumeAttribute(.systemFileNumber)

            // FIXME: swift-corelibs-foundation does not currently support querying this kind of filesystem information. We return reasonable assumptions for now, with the understanding that by noting support we are encouraging the application to try performing corresponding I/O operations (and handle those errors, which they already must) instead. Where those keys would inform I/O decisions that are not single operations, we assume conservatively.
            case .volumeSupportsPersistentIDsKey:
                result[key] = false
            case .volumeSupportsSymbolicLinksKey:
                result[key] = true
            case .volumeSupportsHardLinksKey:
                result[key] = true
            case .volumeSupportsJournalingKey:
                result[key] = false
            case .volumeIsJournalingKey:
                result[key] = false
            case .volumeSupportsSparseFilesKey:
                result[key] = false
            case .volumeSupportsZeroRunsKey:
                result[key] = false
            case .volumeSupportsRootDirectoryDatesKey:
                result[key] = true
            case .volumeSupportsVolumeSizesKey:
                result[key] = true
            case .volumeSupportsRenamingKey:
                result[key] = true
            case .volumeSupportsAdvisoryFileLockingKey:
                result[key] = false
            case .volumeSupportsExtendedSecurityKey:
                result[key] = false
            case .volumeIsBrowsableKey:
                result[key] = true
            case .volumeIsReadOnlyKey:
                result[key] = false
            case .volumeCreationDateKey:
                result[key] = try volumeAttribute(.creationDate)
            case .volumeURLForRemountingKey:
                result[key] = nil
            case .volumeMaximumFileSizeKey: fallthrough
            case .volumeIsEjectableKey: fallthrough
            case .volumeIsRemovableKey: fallthrough
            case .volumeIsInternalKey: fallthrough
            case .volumeIsAutomountedKey: fallthrough
            case .volumeIsLocalKey: fallthrough
            case .volumeSupportsCaseSensitiveNamesKey: fallthrough
            case .volumeUUIDStringKey: fallthrough
            case .volumeIsEncryptedKey: fallthrough
            case .volumeSupportsCompressionKey: fallthrough
            case .volumeSupportsFileCloningKey: fallthrough
            case .volumeSupportsSwapRenamingKey: fallthrough
            case .volumeSupportsExclusiveRenamingKey: fallthrough
            case .volumeSupportsCasePreservedNamesKey:
                // Whatever we assume here, we may make problems for the implementation that relies on them; we just don't answer for now.
                break
                
            case .volumeNameKey:
                if let url = try volumeURL() {
                    result[key] = url.lastPathComponent
                }
            case .volumeLocalizedNameKey:
                if let url = try volumeURL() {
                    result[key] = fm.displayName(atPath: url.path)
                }
                
            case .volumeIsRootFileSystemKey:
                #if !os(Windows)
                if let url = try volumeURL() {
                    result[key] = url.path == "/"
                }
                #endif
                
            case .isUbiquitousItemKey: fallthrough
            case .ubiquitousItemHasUnresolvedConflictsKey: fallthrough
            case .ubiquitousItemIsDownloadingKey: fallthrough
            case .ubiquitousItemIsUploadedKey: fallthrough
            case .ubiquitousItemIsUploadingKey: fallthrough
            case .ubiquitousItemDownloadingStatusKey: fallthrough
            case .ubiquitousItemDownloadingErrorKey: fallthrough
            case .ubiquitousItemUploadingErrorKey: fallthrough
            case .ubiquitousItemDownloadRequestedKey: fallthrough
            case .ubiquitousItemContainerDisplayNameKey: fallthrough
            case .fileSecurityKey: fallthrough
            case .isExcludedFromBackupKey: fallthrough
            case .tagNamesKey: fallthrough
            case .typeIdentifierKey: fallthrough
            case .localizedTypeDescriptionKey: fallthrough
            case .labelNumberKey: fallthrough
            case .labelColorKey: fallthrough
            case .localizedLabelKey: fallthrough
            case .effectiveIconKey: fallthrough
            case .isMountTriggerKey: fallthrough
            case .generationIdentifierKey: fallthrough
            case .documentIdentifierKey: fallthrough
            case .addedToDirectoryDateKey: fallthrough
            case .quarantinePropertiesKey: fallthrough
            case .thumbnailDictionaryKey: fallthrough
            case .thumbnailKey: fallthrough
            case .customIconKey:
                // Not supported outside of Apple OSes.
                break
                
            default:
                break
            }
        }
        
        return result
    }
    
    func write(_ keysAndValues: [URLResourceKey: Any?], to url: NSURL) throws {
        // Keys we could support but don't yet (FIXME):
        // .labelNumberKey, // Darwin only:
        // .fileSecurityKey,
        // .isExcludedFromBackupKey,
        // .tagNamesKey,
        // .quarantinePropertiesKey,
        // .addedToDirectoryDateKey, // Most OSes do not have a separate stat()-able added-to-directory date.
        // .volumeNameKey, // The way to set this is very system-dependent.
        
        var finalError: Error?
        var unsuccessfulKeys = Set(keysAndValues.keys)
        
        let fm = FileManager.default
        let path = url.path ?? ""
        
        let swiftURL = url._swiftObject
        
        var attributesToSet: [FileAttributeKey: Any] = [:]
        var keysThatSucceedBySettingAttributes: Set<URLResourceKey> = []
        
        for key in keysAndValues.keys {
            let value = keysAndValues[key]
            do {
                var succeeded = true
                
                func prepareToSetFileAttribute(_ attributeKey: FileAttributeKey, value: Any?) throws {
                    if let value = value {
                        attributesToSet[attributeKey] = value
                        keysThatSucceedBySettingAttributes.insert(key)
                    } else {
                        throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnknown.rawValue)
                    }
                    
                    succeeded = false
                }

                switch key {
                    
                case .isUserImmutableKey:
                    try prepareToSetFileAttribute(.immutable, value: value as? Bool)

                case .isSystemImmutableKey:
                    try prepareToSetFileAttribute(._systemImmutable, value: value as? Bool)

                case .hasHiddenExtensionKey:
                    try prepareToSetFileAttribute(.extensionHidden, value: value as? Bool)
                    
                case .creationDateKey:
                    try prepareToSetFileAttribute(.creationDate, value: value as? Date)
                    
                case .contentAccessDateKey:
                    try prepareToSetFileAttribute(._accessDate, value: value as? Date)
                    
                case .contentModificationDateKey:
                    try prepareToSetFileAttribute(.modificationDate, value: value as? Date)
                    
                case .isHiddenKey:
                    try prepareToSetFileAttribute(._hidden, value: value as? Bool)
                    
                default:
                    /* https://developer.apple.com/documentation/foundation/nsurl/1408208-setresourcevalues:
                     Attempts to set a read-only resource property or to set a resource property that is not supported by the resource are ignored and are not considered errors.
                     
                     Properties swift-corelibs-foundation doesn't support are treated as if they are supported by no resource. */
                    break
                }
                
                if succeeded {
                    unsuccessfulKeys.remove(key)
                }
            } catch {
                finalError = error
                break
            }
            
            // _setAttributes(…) needs to figure out the correct order to apply these attributes in, so set them all together at the end.
            if !attributesToSet.isEmpty {
                try fm._setAttributesIncludingPrivate(attributesToSet, ofItemAtPath: path)
                unsuccessfulKeys.formSymmetricDifference(keysThatSucceedBySettingAttributes)
            }
            
            // The name must be set last, since otherwise the URL may be invalid.
            if keysAndValues.keys.contains(.nameKey) {
                if let value = keysAndValues[.nameKey] as? String {
                    let destination = swiftURL.deletingLastPathComponent().appendingPathComponent(value)
                    try fm.moveItem(at: swiftURL, to: destination)
                    unsuccessfulKeys.remove(.nameKey)
                } else {
                    throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteInvalidFileName.rawValue)
                }
            }
        }
        
        if let finalError = finalError {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnknown.rawValue, userInfo: [
                URLResourceKey.keysOfUnsetValuesKey.rawValue: Array(unsuccessfulKeys),
                NSUnderlyingErrorKey: finalError,
            ])
        }
    }
}

// -----

internal extension Date {
    #if !os(Windows)
    init(timespec: timespec) {
        self.init(timeIntervalSince1970: TimeInterval(timespec.tv_sec), nanoseconds: Double(timespec.tv_nsec))
    }
    #endif
    
    init(timeIntervalSince1970: TimeInterval, nanoseconds: Double = 0) {
        self.init(timeIntervalSinceReferenceDate: (timeIntervalSince1970 - 978307200.0) /* seconds from 1970 to the reference date, 2001 */ + (1.0e-9 * nanoseconds))
    }
}

extension stat {
    var lastModificationDate: Date {
        #if canImport(Darwin)
        return Date(timespec: st_mtimespec)
        #elseif os(Windows)
        return Date(timeIntervalSince1970: TimeInterval(st_mtime))
        #else
        return Date(timespec: st_mtim)
        #endif
    }
    
    var lastAccessDate: Date {
        #if canImport(Darwin)
        return Date(timespec: st_atimespec)
        #elseif os(Windows)
        return Date(timeIntervalSince1970: TimeInterval(st_atime))
        #else
        return Date(timespec: st_atim)
        #endif
    }
    
    var creationDate: Date {
        #if canImport(Darwin)
        return Date(timespec: st_birthtimespec)
        #elseif os(Windows)
        return Date(timeIntervalSince1970: TimeInterval(st_ctime))
        #else
        return Date(timespec: st_ctim)
        #endif
    }
}
