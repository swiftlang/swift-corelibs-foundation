//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@available(*, unavailable)
extension URLResourceValues : Sendable { }

/**
 URLs to file system resources support the properties defined below. Note that not all property values will exist for all file system URLs. For example, if a file is located on a volume that does not support creation dates, it is valid to request the creation date property, but the returned value will be nil, and no error will be generated.
 
 Only the fields requested by the keys you pass into the `URL` function to receive this value will be populated. The others will return `nil` regardless of the underlying property on the file system.
 
 As a convenience, volume resource values can be requested from any file system URL. The value returned will reflect the property value for the volume on which the resource is located.
 */
public struct URLResourceValues {
    fileprivate var _values: [URLResourceKey: Any]
    fileprivate var _keys: Set<URLResourceKey>
    
    public init() {
        _values = [:]
        _keys = []
    }
    
    fileprivate init(keys: Set<URLResourceKey>, values: [URLResourceKey: Any]) {
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
    
    private mutating func _set(_ key : URLResourceKey, newValue : Any?) {
        _keys.insert(key)
        _values[key] = newValue
    }
    private mutating func _set(_ key : URLResourceKey, newValue : String?) {
        _keys.insert(key)
        _values[key] = newValue
    }
    private mutating func _set(_ key : URLResourceKey, newValue : [String]?) {
        _keys.insert(key)
        _values[key] = newValue
    }
    private mutating func _set(_ key : URLResourceKey, newValue : Date?) {
        _keys.insert(key)
        _values[key] = newValue
    }
    private mutating func _set(_ key : URLResourceKey, newValue : URL?) {
        _keys.insert(key)
        _values[key] = newValue
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
    public var allValues : [URLResourceKey : Any] {
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
    
    /// True if the resource is scriptable. Only applies to applications.
    public var applicationIsScriptable: Bool? { return _get(.applicationIsScriptableKey) }
    
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
    public var fileResourceIdentifier: (NSCopying & NSSecureCoding & NSObjectProtocol)? { return _get(.fileResourceIdentifierKey) }
    
    /// An identifier that can be used to identify the volume the file system object is on.
    ///
    /// Other objects on the same volume will have the same volume identifier and can be compared using for equality using `isEqual`. This identifier is not persistent across system restarts.
    public var volumeIdentifier: (NSCopying & NSSecureCoding & NSObjectProtocol)? { return _get(.volumeIdentifierKey) }
    
    /// The optimal block size when reading or writing this file's data, or nil if not available.
    public var preferredIOBlockSize: Int? { return _get(.preferredIOBlockSizeKey) }
    
    /// True if this process (as determined by EUID) can read the resource.
    public var isReadable: Bool? { return _get(.isReadableKey) }
    
    /// True if this process (as determined by EUID) can write to the resource.
    public var isWritable: Bool? { return _get(.isWritableKey) }
    
    /// True if this process (as determined by EUID) can execute a file resource or search a directory resource.
    public var isExecutable: Bool? { return _get(.isExecutableKey) }

    
    /// True if resource should be excluded from backups, false otherwise.
    ///
    /// This property is only useful for excluding cache and other application support files which are not needed in a backup. Some operations commonly made to user documents will cause this property to be reset to false and so this property should not be used on user documents.
    public var isExcludedFromBackup: Bool? {
        get { return _get(.isExcludedFromBackupKey) }
        set { _set(.isExcludedFromBackupKey, newValue: newValue) }
    }
    
    /// The array of Tag names.
    public var tagNames: [String]? { return _get(.tagNamesKey) }

    /// The URL's path as a file system path.
    public var path: String? { return _get(.pathKey) }
    
    /// The URL's path as a canonical absolute file system path.
    public var canonicalPath: String? { return _get(.canonicalPathKey) }
    
    /// True if this URL is a file system trigger directory. Traversing or opening a file system trigger will cause an attempt to mount a file system on the trigger directory.
    public var isMountTrigger: Bool? { return _get(.isMountTriggerKey) }
    
    /// An opaque generation identifier which can be compared using `==` to determine if the data in a document has been modified.
    ///
    /// For URLs which refer to the same file inode, the generation identifier will change when the data in the file's data fork is changed (changes to extended attributes or other file system metadata do not change the generation identifier). For URLs which refer to the same directory inode, the generation identifier will change when direct children of that directory are added, removed or renamed (changes to the data of the direct children of that directory will not change the generation identifier). The generation identifier is persistent across system restarts. The generation identifier is tied to a specific document on a specific volume and is not transferred when the document is copied to another volume. This property is not supported by all volumes.
    public var generationIdentifier: (NSCopying & NSSecureCoding & NSObjectProtocol)? { return _get(.generationIdentifierKey) }
    
    /// The document identifier -- a value assigned by the kernel to a document (which can be either a file or directory) and is used to identify the document regardless of where it gets moved on a volume.
    ///
    /// The document identifier survives "safe save" operations; i.e it is sticky to the path it was assigned to (`replaceItem(at:,withItemAt:,backupItemName:,options:,resultingItem:) throws` is the preferred safe-save API). The document identifier is persistent across system restarts. The document identifier is not transferred when the file is copied. Document identifiers are only unique within a single volume. This property is not supported by all volumes.
    public var documentIdentifier: Int? { return _get(.documentIdentifierKey) }
    
    /// The date the resource was created, or renamed into or within its parent directory. Note that inconsistent behavior may be observed when this attribute is requested on hard-linked items. This property is not supported by all volumes.
    public var addedToDirectoryDate: Date? { return _get(.addedToDirectoryDateKey) }
    
    /// The quarantine properties as defined in LSQuarantine.h. To remove quarantine information from a file, pass `nil` as the value when setting this property.
    public var quarantineProperties: [String : Any]? {
        get { return _get(.quarantinePropertiesKey) }
        set { _set(.quarantinePropertiesKey, newValue: newValue) }
    }
    
    /// Returns the file system object type.
    public var fileResourceType: URLFileResourceType? { return _get(.fileResourceTypeKey) }
    
    /// The user-visible volume format.
    public var volumeLocalizedFormatDescription : String? { return _get(.volumeLocalizedFormatDescriptionKey) }
    
    /// Total volume capacity in bytes.
    public var volumeTotalCapacity : Int? { return _get(.volumeTotalCapacityKey) }
    
    /// Total free space in bytes.
    public var volumeAvailableCapacity : Int? { return _get(.volumeAvailableCapacityKey) }
    
    /// Total number of resources on the volume.
    public var volumeResourceCount : Int? { return _get(.volumeResourceCountKey) }
    
    /// true if the volume format supports persistent object identifiers and can look up file system objects by their IDs.
    public var volumeSupportsPersistentIDs : Bool? { return _get(.volumeSupportsPersistentIDsKey) }
    
    /// true if the volume format supports symbolic links.
    public var volumeSupportsSymbolicLinks : Bool? { return _get(.volumeSupportsSymbolicLinksKey) }
    
    /// true if the volume format supports hard links.
    public var volumeSupportsHardLinks : Bool? { return _get(.volumeSupportsHardLinksKey) }
    
    /// true if the volume format supports a journal used to speed recovery in case of unplanned restart (such as a power outage or crash). This does not necessarily mean the volume is actively using a journal.
    public var volumeSupportsJournaling : Bool? { return _get(.volumeSupportsJournalingKey) }
    
    /// true if the volume is currently using a journal for speedy recovery after an unplanned restart.
    public var volumeIsJournaling : Bool? { return _get(.volumeIsJournalingKey) }
    
    /// true if the volume format supports sparse files, that is, files which can have 'holes' that have never been written to, and thus do not consume space on disk. A sparse file may have an allocated size on disk that is less than its logical length.
    public var volumeSupportsSparseFiles : Bool? { return _get(.volumeSupportsSparseFilesKey) }
    
    /// For security reasons, parts of a file (runs) that have never been written to must appear to contain zeroes. true if the volume keeps track of allocated but unwritten runs of a file so that it can substitute zeroes without actually writing zeroes to the media.
    public var volumeSupportsZeroRuns : Bool? { return _get(.volumeSupportsZeroRunsKey) }
    
    /// true if the volume format treats upper and lower case characters in file and directory names as different. Otherwise an upper case character is equivalent to a lower case character, and you can't have two names that differ solely in the case of the characters.
    public var volumeSupportsCaseSensitiveNames : Bool? { return _get(.volumeSupportsCaseSensitiveNamesKey) }
    
    /// true if the volume format preserves the case of file and directory names.  Otherwise the volume may change the case of some characters (typically making them all upper or all lower case).
    public var volumeSupportsCasePreservedNames : Bool? { return _get(.volumeSupportsCasePreservedNamesKey) }
    
    /// true if the volume supports reliable storage of times for the root directory.
    public var volumeSupportsRootDirectoryDates : Bool? { return _get(.volumeSupportsRootDirectoryDatesKey) }
    
    /// true if the volume supports returning volume size values (`volumeTotalCapacity` and `volumeAvailableCapacity`).
    public var volumeSupportsVolumeSizes : Bool? { return _get(.volumeSupportsVolumeSizesKey) }
    
    /// true if the volume can be renamed.
    public var volumeSupportsRenaming : Bool? { return _get(.volumeSupportsRenamingKey) }
    
    /// true if the volume implements whole-file flock(2) style advisory locks, and the O_EXLOCK and O_SHLOCK flags of the open(2) call.
    public var volumeSupportsAdvisoryFileLocking : Bool? { return _get(.volumeSupportsAdvisoryFileLockingKey) }
    
    /// true if the volume implements extended security (ACLs).
    public var volumeSupportsExtendedSecurity : Bool? { return _get(.volumeSupportsExtendedSecurityKey) }
    
    /// true if the volume should be visible via the GUI (i.e., appear on the Desktop as a separate volume).
    public var volumeIsBrowsable : Bool? { return _get(.volumeIsBrowsableKey) }
    
    /// The largest file size (in bytes) supported by this file system, or nil if this cannot be determined.
    public var volumeMaximumFileSize : Int? { return _get(.volumeMaximumFileSizeKey) }
    
    /// true if the volume's media is ejectable from the drive mechanism under software control.
    public var volumeIsEjectable : Bool? { return _get(.volumeIsEjectableKey) }
    
    /// true if the volume's media is removable from the drive mechanism.
    public var volumeIsRemovable : Bool? { return _get(.volumeIsRemovableKey) }
    
    /// true if the volume's device is connected to an internal bus, false if connected to an external bus, or nil if not available.
    public var volumeIsInternal : Bool? { return _get(.volumeIsInternalKey) }
    
    /// true if the volume is automounted. Note: do not mistake this with the functionality provided by kCFURLVolumeSupportsBrowsingKey.
    public var volumeIsAutomounted : Bool? { return _get(.volumeIsAutomountedKey) }

    /// true if the volume is stored on a local device.
    public var volumeIsLocal : Bool? { return _get(.volumeIsLocalKey) }

    /// true if the volume is read-only.
    public var volumeIsReadOnly : Bool? { return _get(.volumeIsReadOnlyKey) }

    /// The volume's creation date, or nil if this cannot be determined.
    public var volumeCreationDate : Date? { return _get(.volumeCreationDateKey) }

    /// The `URL` needed to remount a network volume, or nil if not available.
    public var volumeURLForRemounting : URL? { return _get(.volumeURLForRemountingKey) }

    /// The volume's persistent `UUID` as a string, or nil if a persistent `UUID` is not available for the volume.
    public var volumeUUIDString : String? { return _get(.volumeUUIDStringKey) }

    /// The name of the volume
    public var volumeName : String? {
        get { return _get(.volumeNameKey) }
        set { _set(.volumeNameKey, newValue: newValue) }
    }
    
    /// The user-presentable name of the volume
    public var volumeLocalizedName : String? { return _get(.volumeLocalizedNameKey) }
    
    /// true if the volume is encrypted.
    public var volumeIsEncrypted : Bool? { return _get(.volumeIsEncryptedKey) }

    /// true if the volume is the root filesystem.
    public var volumeIsRootFileSystem : Bool? { return _get(.volumeIsRootFileSystemKey) }

    /// true if the volume supports transparent decompression of compressed files using decmpfs.
    public var volumeSupportsCompression : Bool? { return _get(.volumeSupportsCompressionKey) }
    
    /// true if this item is synced to the cloud, false if it is only a local file.
    public var isUbiquitousItem : Bool? { return _get(.isUbiquitousItemKey) }

    /// true if this item has conflicts outstanding.
    public var ubiquitousItemHasUnresolvedConflicts : Bool? { return _get(.ubiquitousItemHasUnresolvedConflictsKey) }

    /// true if data is being downloaded for this item.
    public var ubiquitousItemIsDownloading : Bool? { return _get(.ubiquitousItemIsDownloadingKey) }

    /// true if there is data present in the cloud for this item.
    public var ubiquitousItemIsUploaded : Bool? { return _get(.ubiquitousItemIsUploadedKey) }

    /// true if data is being uploaded for this item.
    public var ubiquitousItemIsUploading : Bool? { return _get(.ubiquitousItemIsUploadingKey) }
    
    /// returns the error when downloading the item from iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h
    public var ubiquitousItemDownloadingError : NSError? { return _get(.ubiquitousItemDownloadingErrorKey) }

    /// returns the error when uploading the item to iCloud failed, see the NSUbiquitousFile section in FoundationErrors.h
    public var ubiquitousItemUploadingError : NSError? { return _get(.ubiquitousItemUploadingErrorKey) }
    
    /// returns whether a download of this item has already been requested with an API like `startDownloadingUbiquitousItem(at:) throws`.
    public var ubiquitousItemDownloadRequested : Bool? { return _get(.ubiquitousItemDownloadRequestedKey) }
    
    /// returns the name of this item's container as displayed to users.
    public var ubiquitousItemContainerDisplayName : String? { return _get(.ubiquitousItemContainerDisplayNameKey) }
    
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

extension URL {
    // This thing was never really part of the URL specs
    @available(*, unavailable, message: "Use `path`, `query`, and `fragment` instead")
    public var resourceSpecifier: String {
        fatalError()
    }
    
    
    @available(*, unavailable, message: "use the 'path' property")
    public var parameterString: String? {
        fatalError()
    }

    // MARK: - Resource Values
    
    /// Sets the resource value identified by a given resource key.
    ///
    /// This method writes the new resource values out to the backing store. Attempts to set a read-only resource property or to set a resource property not supported by the resource are ignored and are not considered errors. This method is currently applicable only to URLs for file system resources.
    ///
    /// `URLResourceValues` keeps track of which of its properties have been set. Those values are the ones used by this function to determine which properties to write.
    public mutating func setResourceValues(_ values: URLResourceValues) throws {
        let ns = self as NSURL
        try ns.setResourceValues(values._values)
        self = ns as URL
    }
    
    /// Return a collection of resource values identified by the given resource keys.
    ///
    /// This method first checks if the URL object already caches the resource value. If so, it returns the cached resource value to the caller. If not, then this method synchronously obtains the resource value from the backing store, adds the resource value to the URL object's cache, and returns the resource value to the caller. The type of the resource value varies by resource property (see resource key definitions). If this method does not throw and the resulting value in the `URLResourceValues` is populated with nil, it means the resource property is not available for the specified resource and no errors occurred when determining the resource property was not available. This method is currently applicable only to URLs for file system resources.
    ///
    /// When this function is used from the main thread, resource values cached by the URL (except those added as temporary properties) are removed the next time the main thread's run loop runs. `func removeCachedResourceValue(forKey:)` and `func removeAllCachedResourceValues()` also may be used to remove cached resource values.
    ///
    /// Only the values for the keys specified in `keys` will be populated.
    public func resourceValues(forKeys keys: Set<URLResourceKey>) throws -> URLResourceValues {
        return URLResourceValues(keys: keys, values: try (self as NSURL).resourceValues(forKeys: Array(keys)))
    }

    /// Sets a temporary resource value on the URL object.
    ///
    /// Temporary resource values are for client use. Temporary resource values exist only in memory and are never written to the resource's backing store. Once set, a temporary resource value can be copied from the URL object with `func resourceValues(forKeys:)`. The values are stored in the loosely-typed `allValues` dictionary property.
    ///
    /// To remove a temporalet resource value from the URL object, use `func removeCachedResourceValue(forKey:)`. Care should be taken to ensure the key that identifies a temporary resource value is unique and does not conflict with system defined keys (using reverse domain name notation in your temporary resource value keys is recommended). This method is currently applicable only to URLs for file system resources.
    public mutating func setTemporaryResourceValue(_ value : Any, forKey key: URLResourceKey) {
        let ns = self as NSURL
        ns.setTemporaryResourceValue(value, forKey: key)
        self = ns as URL
    }
    
    /// Removes all cached resource values and all temporary resource values from the URL object.
    ///
    /// This method is currently applicable only to URLs for file system resources.
    public mutating func removeAllCachedResourceValues() {
        let ns = self as NSURL
        ns.removeAllCachedResourceValues()
        self = ns as URL
    }
    
    /// Removes the cached resource value identified by a given resource value key from the URL object.
    ///
    /// Removing a cached resource value may remove other cached resource values because some resource values are cached as a set of values, and because some resource values depend on other resource values (temporary resource values have no dependencies). This method is currently applicable only to URLs for file system resources.
    public mutating func removeCachedResourceValue(forKey key: URLResourceKey) {
        let ns = self as NSURL
        ns.removeCachedResourceValue(forKey: key)
        self = ns as URL
    }
    
    /// Returns whether the URL's resource exists and is reachable.
    ///
    /// This method synchronously checks if the resource's backing store is reachable. Checking reachability is appropriate when making decisions that do not require other immediate operations on the resource, e.g. periodic maintenance of UI state that depends on the existence of a specific document. When performing operations such as opening a file or copying resource properties, it is more efficient to simply try the operation and handle failures. This method is currently applicable only to URLs for file system resources. For other URL types, `false` is returned.
    public func checkResourceIsReachable() throws -> Bool {
        return try (self as NSURL).checkResourceIsReachable()
    }
}

extension URL : ReferenceConvertible {
    public typealias ReferenceType = NSURL
}

extension URL : _ObjectiveCBridgeable {
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSURL {
        return NSURL(string: self.absoluteString, relativeTo: self.baseURL)!
    }
    
    public static func _forceBridgeFromObjectiveC(_ source: NSURL, result: inout URL?) {
        if !_conditionallyBridgeFromObjectiveC(source, result: &result) {
            fatalError("Unable to bridge \(NSURL.self) to \(self)")
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSURL, result: inout URL?) -> Bool {
        result = URL(string: source.absoluteString, relativeTo: source.baseURL)
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSURL?) -> URL {
        var result: URL? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}

extension URL : CustomPlaygroundDisplayConvertible {
    public var playgroundDescription: Any {
        return absoluteString
    }
}

private func _pathIsDirectory<S>(_ path: S, directoryHint: URL.DirectoryHint) -> Bool where S: StringProtocol {
    switch directoryHint {
    case .isDirectory:
        return true
    case .notDirectory:
        return false
    case .checkFileSystem:
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: String(path), isDirectory: &isDir) else {
            return false
        }
        return isDir.boolValue
    case .inferFromPath:
        let standardizedPath = _standardizedPath(String(path))
        return validPathSeps.contains(where: { standardizedPath.hasSuffix(String($0)) })
    }
}

private func _joinPathComponents<S>(_ components: [S]) -> String where S: StringProtocol {
    return components.joined(separator: String(validPathSeps.first!))
}

extension URL {
    public enum DirectoryHint: Sendable, Equatable, Hashable {
        /// Specifies that the `URL` does reference a directory
        case isDirectory

        /// Specifies that the `URL` does **not** reference a directory
        case notDirectory

        /// Specifies that `URL` should check with the file system to determine whether it references a directory
        case checkFileSystem

        /// Specifies that `URL` should infer whether is references a directory based on whether it has a trialing slash
        case inferFromPath
    }

    // TODO: Implement a new initializer depending on both `FilePath` and `DirectoryHint`:
    //       `init?(filePath: FilePath, directoryHint: DirectoryHint)`.
    // There's no conclusion how we should handle cross-import overlays.
    // See https://github.com/apple/swift-system/issues/7

    public init(
        filePath path: String,
        directoryHint: DirectoryHint = .inferFromPath,
        relativeTo base: URL? = nil
    ) {
        let newPath = base.map({ _joinPathComponents([$0.path, path]) }) ?? path
        let isDir = _pathIsDirectory(newPath, directoryHint: directoryHint)
        _url = NSURL(fileURLWithPath: newPath, isDirectory: isDir)
    }

    public mutating func append<S>(
        component: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) where S: StringProtocol {
        append(components: component, directoryHint: directoryHint)
    }

    public mutating func append<S>(
        components: S...,
        directoryHint: DirectoryHint = .inferFromPath
    ) where S: StringProtocol {
        append(path: _joinPathComponents(components), directoryHint: directoryHint)
    }

    public mutating func append<S>(
        path: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) where S: StringProtocol {
        self = appending(path: path, directoryHint: directoryHint)
    }

    public func appending<S>(
        component: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> URL where S: StringProtocol {
        return appending(components: component, directoryHint: directoryHint)
    }

    public func appending<S>(
        components: S...,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> URL where S: StringProtocol {
        return appending(path: _joinPathComponents(components), directoryHint: directoryHint)
    }

    public func appending<S>(
        path: S,
        directoryHint: DirectoryHint = .inferFromPath
    ) -> URL where S: StringProtocol {
        if isFileURL {
            return URL(filePath: String(path), directoryHint: directoryHint, relativeTo: self)
        }

        if case .checkFileSystem = directoryHint {
            return _url.appendingPathComponent(String(path))!
        }
        return _url.appendingPathComponent(
            String(path),
            isDirectory: _pathIsDirectory(path, directoryHint: directoryHint)
        )!
    }
}

//===----------------------------------------------------------------------===//
// File references, for playgrounds.
//===----------------------------------------------------------------------===//

extension URL : _ExpressibleByFileReferenceLiteral {
  public init(fileReferenceLiteralResourceName name: String) {
    self = Bundle.main.url(forResource: name, withExtension: nil)!
  }
}

public typealias _FileReferenceLiteralType = URL
