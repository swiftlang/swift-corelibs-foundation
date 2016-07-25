// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/**
 URLs to file system resources support the properties defined below. Note that not all property values will exist for all file system URLs. For example, if a file is located on a volume that does not support creation dates, it is valid to request the creation date property, but the returned value will be nil, and no error will be generated.
 
 Only the fields requested by the keys you pass into the `URL` function to receive this value will be populated. The others will return `nil` regardless of the underlying property on the file system.
 
 As a convenience, volume resource values can be requested from any file system URL. The value returned will reflect the property value for the volume on which the resource is located.
*/
public struct URLResourceValues {
    fileprivate var _values: [URLResourceKey: AnyObject]
    fileprivate var _keys: Set<URLResourceKey>
    
    public init() {
        _values = [:]
        _keys = []
    }
    
    fileprivate init(keys: Set<URLResourceKey>, values: [URLResourceKey: AnyObject]) {
        _values = values
        _keys = keys
    }
    
    private func contains(_ key: URLResourceKey) -> Bool {
        return _keys.contains(key)
    }
    
    private func _get<T>(_ key : URLResourceKey) -> T? {
        return _values[key] as? T
    }
    private func _get(_ key : URLResourceKey) -> Bool? {
        return (_values[key] as? NSNumber)?.boolValue
    }
    private func _get(_ key: URLResourceKey) -> Int? {
        return (_values[key] as? NSNumber)?.intValue
    }
    
    private mutating func _set(_ key : URLResourceKey, newValue : AnyObject?) {
        _keys.insert(key)
        _values[key] = newValue
    }
    private mutating func _set(_ key : URLResourceKey, newValue : String?) {
        _keys.insert(key)
        _values[key] = newValue?._nsObject
    }
    private mutating func _set(_ key : URLResourceKey, newValue : [String]?) {
        _keys.insert(key)
        _values[key] = newValue?._nsObject
    }
    private mutating func _set(_ key : URLResourceKey, newValue : Date?) {
        _keys.insert(key)
        _values[key] = newValue?._nsObject
    }
    private mutating func _set(_ key : URLResourceKey, newValue : URL?) {
        _keys.insert(key)
        _values[key] = newValue?._nsObject
    }
    private mutating func _set(_ key : URLResourceKey, newValue : Bool?) {
        _keys.insert(key)
        if let value = newValue {
            _values[key] = NSNumber(value: value)
        } else {
            _values[key] = nil
        }
    }
    private mutating func _set(_ key : URLResourceKey, newValue : Int?) {
        _keys.insert(key)
        if let value = newValue {
            _values[key] = NSNumber(value: value)
        } else {
            _values[key] = nil
        }
    }
    
    /// A loosely-typed dictionary containing all keys and values.
    ///
    /// If you have set temporary keys or non-standard keys, you can find them in here.
    public var allValues : [URLResourceKey : AnyObject] {
        return _values
    }
    
    /// The resource name provided by the file system.
    public var name: String? {
        get { return _get(.nameKey) }
        set { _set(.nameKey, newValue: newValue) }
    }
    
    /// Localized or extension-hidden name as displayed to users.
    public var localizedName: String? { return _get(.localizedNameKey) }
    
    /// True for regular files.
    public var isRegularFile: Bool? { return _get(.isRegularFileKey) }
    
    /// True for directories.
    public var isDirectory: Bool? { return _get(.isDirectoryKey) }
    
    /// True for symlinks.
    public var isSymbolicLink: Bool? { return _get(.isSymbolicLinkKey) }
    
    /// True for the root directory of a volume.
    public var isVolume: Bool? { return _get(.isVolumeKey) }
    
    /// True for packaged directories.
    ///
    /// - note: You can only set or clear this property on directories; if you try to set this property on non-directory objects, the property is ignored. If the directory is a package for some other reason (extension type, etc), setting this property to false will have no effect.
    public var isPackage: Bool? {
        get { return _get(.isPackageKey) }
        set { _set(.isPackageKey, newValue: newValue) }
    }
    
    /// True if resource is an application.
    public var isApplication: Bool? { return _get(.isApplicationKey) }
    
#if os(OSX)
    /// True if the resource is scriptable. Only applies to applications.
    public var applicationIsScriptable: Bool? { return _get(.applicationIsScriptableKey) }
#endif
    
    /// True for system-immutable resources.
    public var isSystemImmutable: Bool? { return _get(.isSystemImmutableKey) }
    
    /// True for user-immutable resources
    public var isUserImmutable: Bool? {
        get { return _get(.isUserImmutableKey) }
        set { _set(.isUserImmutableKey, newValue: newValue) }
    }
    
    /// True for resources normally not displayed to users.
    ///
    /// - note: If the resource is a hidden because its name starts with a period, setting this property to false will not change the property.
    public var isHidden: Bool? {
        get { return _get(.isHiddenKey) }
        set { _set(.isHiddenKey, newValue: newValue) }
    }
    
    /// True for resources whose filename extension is removed from the localized name property.
    public var hasHiddenExtension: Bool? {
        get { return _get(.hasHiddenExtensionKey) }
        set { _set(.hasHiddenExtensionKey, newValue: newValue) }
    }
    
    /// The date the resource was created.
    public var creationDate: Date? {
        get { return _get(.creationDateKey) }
        set { _set(.creationDateKey, newValue: newValue) }
    }
    
    /// The date the resource was last accessed.
    public var contentAccessDate: Date? {
        get { return _get(.contentAccessDateKey) }
        set { _set(.contentAccessDateKey, newValue: newValue) }
    }
    
    /// The time the resource content was last modified.
    public var contentModificationDate: Date? {
        get { return _get(.contentModificationDateKey) }
        set { _set(.contentModificationDateKey, newValue: newValue) }
    }
    
    /// The time the resource's attributes were last modified.
    public var attributeModificationDate: Date? { return _get(.attributeModificationDateKey) }
    
    /// Number of hard links to the resource.
    public var linkCount: Int? { return _get(.linkCountKey) }
    
    /// The resource's parent directory, if any.
    public var parentDirectory: URL? { return _get(.parentDirectoryURLKey) }
    
    /// URL of the volume on which the resource is stored.
    public var volume: URL? { return _get(.volumeURLKey) }
    
    /// Uniform type identifier (UTI) for the resource.
    public var typeIdentifier: String? { return _get(.typeIdentifierKey) }
    
    /// User-visible type or "kind" description.
    public var localizedTypeDescription: String? { return _get(.localizedTypeDescriptionKey) }
    
    /// The label number assigned to the resource.
    public var labelNumber: Int? {
        get { return _get(.labelNumberKey) }
        set { _set(.labelNumberKey, newValue: newValue) }
    }
    
    
    /// The user-visible label text.
    public var localizedLabel: String? {
        get { return _get(.localizedLabelKey) }
    }
        
    /// An identifier which can be used to compare two file system objects for equality using `isEqual`.
    ///
    /// Two object identifiers are equal if they have the same file system path or if the paths are linked to same inode on the same file system. This identifier is not persistent across system restarts.
    public var fileResourceIdentifier: (NSCopying & NSCoding & NSSecureCoding & NSObjectProtocol)? { return _get(.fileResourceIdentifierKey) }
    
    /// An identifier that can be used to identify the volume the file system object is on.
    ///
    /// Other objects on the same volume will have the same volume identifier and can be compared using for equality using `isEqual`. This identifier is not persistent across system restarts.
    public var volumeIdentifier: (NSCopying & NSCoding & NSSecureCoding & NSObjectProtocol)? { return _get(.volumeIdentifierKey) }
    
    /// The optimal block size when reading or writing this file's data, or nil if not available.
    public var preferredIOBlockSize: Int? { return _get(.preferredIOBlockSizeKey) }
    
    /// True if this process (as determined by EUID) can read the resource.
    public var isReadable: Bool? { return _get(.isReadableKey) }
    
    /// True if this process (as determined by EUID) can write to the resource.
    public var isWritable: Bool? { return _get(.isWritableKey) }
    
    /// True if this process (as determined by EUID) can execute a file resource or search a directory resource.
    public var isExecutable: Bool? { return _get(.isExecutableKey) }

    /// The URL's path as a file system path.
    public var path: String? { return _get(.pathKey) }

    /// The document identifier -- a value assigned by the kernel to a document (which can be either a file or directory) and is used to identify the document regardless of where it gets moved on a volume.
    ///
    /// The document identifier survives "safe save” operations; i.e it is sticky to the path it was assigned to (`replaceItem(at:,withItemAt:,backupItemName:,options:,resultingItem:) throws` is the preferred safe-save API). The document identifier is persistent across system restarts. The document identifier is not transferred when the file is copied. Document identifiers are only unique within a single volume. This property is not supported by all volumes.
    public var documentIdentifier: Int? { return _get(.documentIdentifierKey) }
    
    /// The date the resource was created, or renamed into or within its parent directory. Note that inconsistent behavior may be observed when this attribute is requested on hard-linked items. This property is not supported by all volumes.
    public var addedToDirectoryDate: Date? { return _get(.addedToDirectoryDateKey) }
    
    /// Returns the file system object type.
    public var fileResourceType: URLFileResourceType? { return _get(.fileResourceTypeKey) }
    
    /// Total file size in bytes
    ///
    /// - note: Only applicable to regular files.
    public var fileSize : Int? { return _get(.fileSizeKey) }
    
    /// Total size allocated on disk for the file in bytes (number of blocks times block size)
    ///
    /// - note: Only applicable to regular files.
    public var fileAllocatedSize : Int? { return _get(.fileAllocatedSizeKey) }
    
    /// Total displayable size of the file in bytes (this may include space used by metadata), or nil if not available.
    ///
    /// - note: Only applicable to regular files.
    public var totalFileSize : Int? { return _get(.totalFileSizeKey) }
    
    /// Total allocated size of the file in bytes (this may include space used by metadata), or nil if not available. This can be less than the value returned by `totalFileSize` if the resource is compressed.
    ///
    /// - note: Only applicable to regular files.
    public var totalFileAllocatedSize : Int? { return _get(.totalFileAllocatedSizeKey) }

    /// true if the resource is a Finder alias file or a symlink, false otherwise
    ///
    /// - note: Only applicable to regular files.
    public var isAliasFile : Bool? { return _get(.isAliasFileKey) }

}

public struct URL : ReferenceConvertible, CustomStringConvertible, Equatable {
    public typealias ReferenceType = NSURL
    private var _url : NSURL

    /// Initialize with string.
    ///
    /// Returns `nil` if a `URL` cannot be formed with the string.
    public init?(string: String) {
        if let inner = NSURL(string: string) {
            _url = inner
        } else {
            return nil
        }
    }
    
    public init?(string: String, relativeTo url: URL?) {
        if let inner = NSURL(string: string, relativeTo: url) {
            _url = inner
        } else {
            return nil
        }
    }
    
    public init(fileURLWithFileSystemRepresentation path: UnsafePointer<Int8>, isDirectory isDir: Bool, relativeTo baseURL: URL?) {
        _url = NSURL(fileURLWithFileSystemRepresentation: path, isDirectory:  isDir, relativeTo: baseURL)
    }
    
    /// Initializes a newly created file URL referencing the local file or directory at path, relative to a base URL.
    ///
    /// If an empty string is used for the path, then the path is assumed to be ".".
    /// - note: This function avoids an extra file system access to check if the file URL is a directory. You should use it if you know the answer already.
    public init(fileURLWithPath path: String, isDirectory: Bool, relativeTo base: URL?) {
        _url = NSURL(fileURLWithPath: path.isEmpty ? "." : path, isDirectory: isDirectory, relativeTo: base)
    }
    
    /// Initializes a newly created file URL referencing the local file or directory at path, relative to a base URL.
    ///
    public init(fileURLWithPath path: String, relativeTo base: URL?) {
        _url = NSURL(fileURLWithPath: path.isEmpty ? "." : path, relativeTo: base)
    }
    
    /// Initializes a newly created file URL referencing the local file or directory at path.
    ///
    /// If an empty string is used for the path, then the path is assumed to be ".".
    /// - note: This function avoids an extra file system access to check if the file URL is a directory. You should use it if you know the answer already.
    public init(fileURLWithPath path: String, isDirectory: Bool) {
        _url = NSURL(fileURLWithPath: path.isEmpty ? "." : path, isDirectory: isDirectory)
    }
    
    /// Initializes a newly created file URL referencing the local file or directory at path.
    ///
    /// If an empty string is used for the path, then the path is assumed to be ".".
    public init(fileURLWithPath path: String) {
        _url = NSURL(fileURLWithPath: path.isEmpty ? "." : path)
    }
    
    /// Initializes a newly created URL using the contents of the given data, relative to a base URL. If the data representation is not a legal URL string as ASCII bytes, the URL object may not behave as expected.
    public init(dataRepresentation: Data, relativeTo url: URL?, isAbsolute: Bool = false) {
        if isAbsolute {
            _url = NSURL(absoluteURLWithDataRepresentation: dataRepresentation, relativeTo: url)
        } else {
            _url = NSURL(dataRepresentation: dataRepresentation, relativeTo: url)
        }
    }

    /// Initializes a newly created URL referencing the local file or directory at the file system representation of the path. File system representation is a null-terminated C string with canonical UTF-8 encoding.
    public init(fileURLWithFileSystemRepresentation path: UnsafePointer<Int8>, isDirectory: Bool, relativeToURL baseURL: URL?) {
        _url = NSURL(fileURLWithFileSystemRepresentation: path, isDirectory: isDirectory, relativeTo: baseURL)
    }
    
    // MARK: -
    
    public var description: String {
        return _url.description
    }

    public var debugDescription: String {
        return _url.debugDescription
    }

    public var hashValue : Int {
        return _url.hash
    }
    
    // MARK: -
    
    /// Returns the data representation of the URL's relativeString. If the URL was initialized with -initWithData:relativeToURL:, the data representation returned are the same bytes as those used at initialization; otherwise, the data representation returned are the bytes of the relativeString encoded with NSUTF8StringEncoding.
    public var dataRepresentation: Data { return _url.dataRepresentation }
    
    public var absoluteString: String? { return _url.absoluteString }
    
    /// The relative portion of a URL.  If baseURL is nil, or if the receiver is itself absolute, this is the same as absoluteString
    public var relativeString: String { return _url.relativeString }
    public var baseURL: URL? { return _url.baseURL }
    
    /// If the receiver is itself absolute, this will return self.
    public var absoluteURL: URL? {  return _url.absoluteURL }
    
    /// Any URL is composed of these two basic pieces.  The full URL would be the concatenation of `myURL.scheme, ':', myURL.resourceSpecifier`.
    public var scheme: String? { return _url.scheme }
    
    /// Any URL is composed of these two basic pieces.  The full URL would be the concatenation of `myURL.scheme, ':', myURL.resourceSpecifier`.
    public var resourceSpecifier: String? { return _url.resourceSpecifier }
    
    /// If the URL conforms to rfc 1808 (the most common form of URL), returns a component of the URL; otherwise it returns nil.
    ///
    /// The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is "//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    public var host: String? { return _url.host }
    
    /// If the URL conforms to rfc 1808 (the most common form of URL), returns a component of the URL; otherwise it returns nil.
    ///
    /// The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is "//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    public var port: Int? { return _url.port?.intValue }
    
    /// If the URL conforms to rfc 1808 (the most common form of URL), returns a component of the URL; otherwise it returns nil.
    ///
    /// The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is "//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    public var user: String? { return _url.user }
    
    /// If the URL conforms to rfc 1808 (the most common form of URL), returns a component of the URL; otherwise it returns nil.
    ///
    /// The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is "//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    public var password: String? { return _url.password }
    
    /// If the URL conforms to rfc 1808 (the most common form of URL), returns a component of the URL; otherwise it returns nil.
    ///
    /// The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is "//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    public var path: String? { return _url.path }
    
    /// If the URL conforms to rfc 1808 (the most common form of URL), returns a component of the URL; otherwise it returns nil.
    ///
    /// The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is "//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    public var fragment: String? { return _url.fragment }
    
    /// If the URL conforms to rfc 1808 (the most common form of URL), returns a component of the URL; otherwise it returns nil.
    ///
    /// The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is "//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    public var parameterString: String? { return _url.parameterString }
    
    /// If the URL conforms to rfc 1808 (the most common form of URL), returns a component of the URL; otherwise it returns nil.
    ///
    /// The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is "//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    public var query: String? { return _url.query }
    
    /// If the URL conforms to rfc 1808 (the most common form of URL), returns a component of the URL; otherwise it returns nil.
    ///
    /// This is the same as path if baseURL is nil.
    /// The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is "//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    public var relativePath: String? { return _url.relativePath }
    
    public var hasDirectoryPath: Bool { return _url.hasDirectoryPath }
    
    /// Passes the URL's path in file system representation to `block`.
    ///
    /// File system representation is a null-terminated C string with canonical UTF-8 encoding.
    /// - note: The pointer is not valid outside the context of the block.
    public func withUnsafeFileSystemRepresentation(_ block: @noescape (UnsafePointer<Int8>) throws -> Void) rethrows {
        try block(_url.fileSystemRepresentation)
    }
    
    /// Whether the scheme is file:; if `myURL.isFileURL` is `true`, then `myURL.path` is suitable for input into `FileManager` or `PathUtilities`.
    public var isFileURL: Bool {
        return _url.isFileURL
    }
    
    public func standardized() throws -> URL {
        if let result = _url.standardized.map({ $0 }) {
            return result;
        } else {
            // TODO: We need to call into CFURL to figure out the error
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadUnknownError.rawValue, userInfo: [:])
        }
    }

    /// Returns a file path URL that refers to the same resource as a specified URL.
    ///
    /// File path URLs use a file system style path. A file reference URL's resource must exist and be reachable to be converted to a file path URL.
    public func filePathURL() throws -> URL {
        if let result = _url.filePathURL.map({ $0 }) {
            return result
        } else {
            // TODO: We need to call into CFURL to figure out the error
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadUnknownError.rawValue, userInfo: [:])
        }
    }
    
    public var pathComponents: [String]? { return _url.pathComponents }
    
    public var lastPathComponent: String? { return _url.lastPathComponent }
    
    public var pathExtension: String? { return _url.pathExtension }
    
    public func appendingPathComponent(_ pathComponent: String, isDirectory: Bool) throws -> URL {
        // TODO: Use URLComponents to handle an empty-path case
        /*
         URLByAppendingPathComponent can return nil if:
         • the URL does not have a path component. (see note 1)
         • a mutable copy of the URLs string could not be created.
         • a percent-encoded string of the new path component could not created using the same encoding as the URL’s string. (see note 2)
         • a new URL object could not be created with the modified URL string.
         
         Note 1: If NS/CFURL parsed URLs correctly, this would not occur because URL strings always have a path component. For example, the URL <mailto:user@example.com> should be parsed as Scheme=“mailto”, and Path= “user@example.com". Instead, CFURL returns false for CFURLCanBeDecomposed(), says Scheme=“mailto”, Path=nil, and ResourceSpecifier=“user@example.com”. rdar://problem/15060399
         
         Note 2: CFURLCreateWithBytes() and CFURLCreateAbsoluteURLWithBytes() allow URLs to be created with an array of bytes and a CFStringEncoding. All other CFURL functions and URL methods which create URLs use kCFStringEncodingUTF8/NSUTF8StringEncoding. So, the encoding passed to CFURLCreateWithBytes/CFURLCreateAbsoluteURLWithBytes might prevent the percent-encoding of the new path component or path extension.
         */
        guard let result = _url.appendingPathComponent(pathComponent, isDirectory: isDirectory) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadUnknownError.rawValue, userInfo: [:])
        }
        return result
    }
    public mutating func appendPathComponent(_ pathComponent: String, isDirectory: Bool) throws {
        self = try appendingPathComponent(pathComponent, isDirectory: isDirectory)
    }
    
    public func appendingPathComponent(_ pathComponent: String) throws -> URL {
        guard let result = _url.appendingPathComponent(pathComponent) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadUnknownError.rawValue, userInfo: [:])
        }
        return result
    }
    public mutating func appendPathComponent(_ pathComponent: String) throws {
        self = try appendingPathComponent(pathComponent)
    }

    public func deletingLastPathComponent() throws -> URL {
        /*
         URLByDeletingLastPathComponent can return nil if:
         • the URL is a file reference URL which cannot be resolved back to a path.
         • the URL does not have a path component. (see note 1)
         • a mutable copy of the URLs string could not be created.
         • a new URL object could not be created with the modified URL string.
         */
        if let result = _url.deletingLastPathComponent.map({ $0 }) {
            return result
        } else {
            // TODO: We need to call into CFURL to figure out the error
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadUnknownError.rawValue, userInfo: [:])
        }
    }
    public mutating func deleteLastPathComponent() throws {
        let result = try deletingLastPathComponent()
        self = result
    }
    
    public func appendingPathExtension(_ pathExtension: String) throws -> URL {
        /*
         URLByAppendingPathExtension can return nil if:
         • the new path extension is not a valid extension (see _CFExtensionIsValidToAppend)
         • the URL is a file reference URL which cannot be resolved back to a path.
         • the URL does not have a path component. (see note 1)
         • a mutable copy of the URLs string could not be created.
         • a percent-encoded string of the new path extension could not created using the same encoding as the URL’s string. (see note 1))
         • a new URL object could not be created with the modified URL string.
         */
        guard let result = _url.appendingPathExtension(pathExtension) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadUnknownError.rawValue, userInfo: [:])
        }
        return result
    }
    public mutating func appendPathExtension(_ pathExtension: String) throws {
        self = try appendingPathExtension(pathExtension)
    }
    
    public func deletingPathExtension() throws -> URL {
        /*
         URLByDeletingPathExtension can return nil if:
         • the URL is a file reference URL which cannot be resolved back to a path.
         • the URL does not have a path component. (see note 1)
         • a mutable copy of the URLs string could not be created.
         • a new URL object could not be created with the modified URL string.
         */
        if let result = _url.deletingPathExtension.map({ $0 }) {
            return result
        } else {
            // TODO: We need to call into CFURL to figure out the error
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadUnknownError.rawValue, userInfo: [:])
        }
    }
    public mutating func deletePathExtension() throws {
        let result = try deletingPathExtension()
        self = result
    }
    
    public func standardizingPath() throws -> URL {
        /*
         URLByStandardizingPath can return nil if:
         • the URL is a file reference URL which cannot be resolved back to a path.
         • a new URL object could not be created with the standardized path).
         */
        if let result = _url.standardizingPath.map({ $0 }) {
            return result
        } else {
            // TODO: We need to call into CFURL to figure out the error
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadUnknownError.rawValue, userInfo: [:])
        }
    }
    public mutating func standardizePath() throws {
        let result = try standardizingPath()
        self = result
    }
    
    public func resolvingSymlinksInPath() throws -> URL {
        /*
         URLByResolvingSymlinksInPath can return nil if:
         • the URL is a file reference URL which cannot be resolved back to a path.
         • NSPathUtilities’ stringByResolvingSymlinksInPath property returns nil.
         • a new URL object could not be created with the resolved path).
         */
        if let result = _url.resolvingSymlinksInPath.map({ $0 }) {
            return result
        } else {
            // TODO: We need to call into CFURL to figure out the error
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadUnknownError.rawValue, userInfo: [:])
        }
    }

    public mutating func resolveSymlinksInPath() throws {
        let result = try resolvingSymlinksInPath()
        self = result
    }
    
    // MARK: - Resource Values
#if false // disabled for now...
    /// Sets the resource value identified by a given resource key.
    ///
    /// This method writes the new resource values out to the backing store. Attempts to set a read-only resource property or to set a resource property not supported by the resource are ignored and are not considered errors. This method is currently applicable only to URLs for file system resources.
    ///
    /// `URLResourceValues` keeps track of which of its properties have been set. Those values are the ones used by this function to determine which properties to write.
    public mutating func setResourceValues(_ values: URLResourceValues) throws {
        try _url.setResourceValues(values._values)
    }
    
    /// Return a collection of resource values identified by the given resource keys.
    ///
    /// This method first checks if the URL object already caches the resource value. If so, it returns the cached resource value to the caller. If not, then this method synchronously obtains the resource value from the backing store, adds the resource value to the URL object's cache, and returns the resource value to the caller. The type of the resource value varies by resource property (see resource key definitions). If this method does not throw and the resulting value in the `URLResourceValues` is populated with nil, it means the resource property is not available for the specified resource and no errors occurred when determining the resource property was not available. This method is currently applicable only to URLs for file system resources.
    ///
    /// When this function is used from the main thread, resource values cached by the URL (except those added as temporary properties) are removed the next time the main thread's run loop runs. `func removeCachedResourceValue(forKey:)` and `func removeAllCachedResourceValues()` also may be used to remove cached resource values.
    ///
    /// Only the values for the keys specified in `keys` will be populated.
    public func resourceValues(forKeys keys: Set<URLResourceKey>) throws -> URLResourceValues {
        return URLResourceValues(keys: keys, values: try _url.resourceValues(forKeys: Array(keys)))
    }

    /// Sets a temporary resource value on the URL object.
    ///
    /// Temporary resource values are for client use. Temporary resource values exist only in memory and are never written to the resource's backing store. Once set, a temporary resource value can be copied from the URL object with `func resourceValues(forKeys:)`. The values are stored in the loosely-typed `allValues` dictionary property.
    ///
    /// To remove a temporary resource value from the URL object, use `func removeCachedResourceValue(forKey:)`. Care should be taken to ensure the key that identifies a temporary resource value is unique and does not conflict with system defined keys (using reverse domain name notation in your temporary resource value keys is recommended). This method is currently applicable only to URLs for file system resources.
    public mutating func setTemporaryResourceValue(_ value : AnyObject, forKey key: URLResourceKey) {
        _url.setTemporaryResourceValue(value, forKey: key)
    }
    
    /// Removes all cached resource values and all temporary resource values from the URL object.
    ///
    /// This method is currently applicable only to URLs for file system resources.
    public mutating func removeAllCachedResourceValues() {
        _url.removeAllCachedResourceValues()
    }
    
    /// Removes the cached resource value identified by a given resource value key from the URL object.
    ///
    /// Removing a cached resource value may remove other cached resource values because some resource values are cached as a set of values, and because some resource values depend on other resource values (temporary resource values have no dependencies). This method is currently applicable only to URLs for file system resources.
    public mutating func removeCachedResourceValue(forKey key: URLResourceKey) {
        _url.removeCachedResourceValue(forKey: key)
    }
#endif
    
    internal func _resolveSymlinksInPath(excludeSystemDirs: Bool) -> URL? {
        return _url._resolveSymlinksInPath(excludeSystemDirs: excludeSystemDirs)
    }
    
    // MARK: - Bridging Support
    
    internal init(reference: NSURL) {
        _url = reference.copy() as! NSURL
    }
    
    internal var reference : NSURL {
        return _url
    }
}

public func ==(lhs: URL, rhs: URL) -> Bool {
    return lhs.reference.isEqual(rhs.reference)
}

extension URL : Bridgeable {
    public typealias BridgeType = NSURL
    public func bridge() -> BridgeType {
        return _nsObject
    }
}

extension NSURL : Bridgeable {
    public typealias BridgeType = URL
    public func bridge() -> BridgeType {
        return _swiftObject
    }
}
