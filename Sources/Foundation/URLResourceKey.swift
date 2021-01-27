// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public struct URLResourceKey: RawRepresentable, Equatable, Hashable {
    public private(set) var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension URLResourceKey {
    public static let keysOfUnsetValuesKey = URLResourceKey(rawValue: "NSURLKeysOfUnsetValuesKey")
    public static let nameKey = URLResourceKey(rawValue: "NSURLNameKey")
    public static let localizedNameKey = URLResourceKey(rawValue: "NSURLLocalizedNameKey")
    public static let isRegularFileKey = URLResourceKey(rawValue: "NSURLIsRegularFileKey")
    public static let isDirectoryKey = URLResourceKey(rawValue: "NSURLIsDirectoryKey")
    public static let isSymbolicLinkKey = URLResourceKey(rawValue: "NSURLIsSymbolicLinkKey")
    public static let isVolumeKey = URLResourceKey(rawValue: "NSURLIsVolumeKey")
    public static let isPackageKey = URLResourceKey(rawValue: "NSURLIsPackageKey")
    public static let isApplicationKey = URLResourceKey(rawValue: "NSURLIsApplicationKey")
    public static let applicationIsScriptableKey = URLResourceKey(rawValue: "NSURLApplicationIsScriptableKey")
    public static let isSystemImmutableKey = URLResourceKey(rawValue: "NSURLIsSystemImmutableKey")
    public static let isUserImmutableKey = URLResourceKey(rawValue: "NSURLIsUserImmutableKey")
    public static let isHiddenKey = URLResourceKey(rawValue: "NSURLIsHiddenKey")
    public static let hasHiddenExtensionKey = URLResourceKey(rawValue: "NSURLHasHiddenExtensionKey")
    public static let creationDateKey = URLResourceKey(rawValue: "NSURLCreationDateKey")
    public static let contentAccessDateKey = URLResourceKey(rawValue: "NSURLContentAccessDateKey")
    public static let contentModificationDateKey = URLResourceKey(rawValue: "NSURLContentModificationDateKey")
    public static let attributeModificationDateKey = URLResourceKey(rawValue: "NSURLAttributeModificationDateKey")
    public static let linkCountKey = URLResourceKey(rawValue: "NSURLLinkCountKey")
    public static let parentDirectoryURLKey = URLResourceKey(rawValue: "NSURLParentDirectoryURLKey")
    public static let volumeURLKey = URLResourceKey(rawValue: "NSURLVolumeURLKey")
    public static let typeIdentifierKey = URLResourceKey(rawValue: "NSURLTypeIdentifierKey")
    public static let localizedTypeDescriptionKey = URLResourceKey(rawValue: "NSURLLocalizedTypeDescriptionKey")
    public static let labelNumberKey = URLResourceKey(rawValue: "NSURLLabelNumberKey")
    public static let labelColorKey = URLResourceKey(rawValue: "NSURLLabelColorKey")
    public static let localizedLabelKey = URLResourceKey(rawValue: "NSURLLocalizedLabelKey")
    public static let effectiveIconKey = URLResourceKey(rawValue: "NSURLEffectiveIconKey")
    public static let customIconKey = URLResourceKey(rawValue: "NSURLCustomIconKey")
    public static let fileResourceIdentifierKey = URLResourceKey(rawValue: "NSURLFileResourceIdentifierKey")
    public static let volumeIdentifierKey = URLResourceKey(rawValue: "NSURLVolumeIdentifierKey")
    public static let preferredIOBlockSizeKey = URLResourceKey(rawValue: "NSURLPreferredIOBlockSizeKey")
    public static let isReadableKey = URLResourceKey(rawValue: "NSURLIsReadableKey")
    public static let isWritableKey = URLResourceKey(rawValue: "NSURLIsWritableKey")
    public static let isExecutableKey = URLResourceKey(rawValue: "NSURLIsExecutableKey")
    public static let fileSecurityKey = URLResourceKey(rawValue: "NSURLFileSecurityKey")
    public static let isExcludedFromBackupKey = URLResourceKey(rawValue: "NSURLIsExcludedFromBackupKey")
    public static let tagNamesKey = URLResourceKey(rawValue: "NSURLTagNamesKey")
    public static let pathKey = URLResourceKey(rawValue: "NSURLPathKey")
    public static let canonicalPathKey = URLResourceKey(rawValue: "NSURLCanonicalPathKey")
    public static let isMountTriggerKey = URLResourceKey(rawValue: "NSURLIsMountTriggerKey")
    public static let generationIdentifierKey = URLResourceKey(rawValue: "NSURLGenerationIdentifierKey")
    public static let documentIdentifierKey = URLResourceKey(rawValue: "NSURLDocumentIdentifierKey")
    public static let addedToDirectoryDateKey = URLResourceKey(rawValue: "NSURLAddedToDirectoryDateKey")
    public static let quarantinePropertiesKey = URLResourceKey(rawValue: "NSURLQuarantinePropertiesKey")
    public static let fileResourceTypeKey = URLResourceKey(rawValue: "NSURLFileResourceTypeKey")
    public static let thumbnailDictionaryKey = URLResourceKey(rawValue: "NSURLThumbnailDictionaryKey")
    public static let thumbnailKey = URLResourceKey(rawValue: "NSURLThumbnailKey")
    public static let fileSizeKey = URLResourceKey(rawValue: "NSURLFileSizeKey")
    public static let fileAllocatedSizeKey = URLResourceKey(rawValue: "NSURLFileAllocatedSizeKey")
    public static let totalFileSizeKey = URLResourceKey(rawValue: "NSURLTotalFileSizeKey")
    public static let totalFileAllocatedSizeKey = URLResourceKey(rawValue: "NSURLTotalFileAllocatedSizeKey")
    public static let isAliasFileKey = URLResourceKey(rawValue: "NSURLIsAliasFileKey")
    public static let volumeLocalizedFormatDescriptionKey = URLResourceKey(rawValue: "NSURLVolumeLocalizedFormatDescriptionKey")
    public static let volumeTotalCapacityKey = URLResourceKey(rawValue: "NSURLVolumeTotalCapacityKey")
    public static let volumeAvailableCapacityKey = URLResourceKey(rawValue: "NSURLVolumeAvailableCapacityKey")
    public static let volumeResourceCountKey = URLResourceKey(rawValue: "NSURLVolumeResourceCountKey")
    public static let volumeSupportsPersistentIDsKey = URLResourceKey(rawValue: "NSURLVolumeSupportsPersistentIDsKey")
    public static let volumeSupportsSymbolicLinksKey = URLResourceKey(rawValue: "NSURLVolumeSupportsSymbolicLinksKey")
    public static let volumeSupportsHardLinksKey = URLResourceKey(rawValue: "NSURLVolumeSupportsHardLinksKey")
    public static let volumeSupportsJournalingKey = URLResourceKey(rawValue: "NSURLVolumeSupportsJournalingKey")
    public static let volumeIsJournalingKey = URLResourceKey(rawValue: "NSURLVolumeIsJournalingKey")
    public static let volumeSupportsSparseFilesKey = URLResourceKey(rawValue: "NSURLVolumeSupportsSparseFilesKey")
    public static let volumeSupportsZeroRunsKey = URLResourceKey(rawValue: "NSURLVolumeSupportsZeroRunsKey")
    public static let volumeSupportsCaseSensitiveNamesKey = URLResourceKey(rawValue: "NSURLVolumeSupportsCaseSensitiveNamesKey")
    public static let volumeSupportsCasePreservedNamesKey = URLResourceKey(rawValue: "NSURLVolumeSupportsCasePreservedNamesKey")
    public static let volumeSupportsRootDirectoryDatesKey = URLResourceKey(rawValue: "NSURLVolumeSupportsRootDirectoryDatesKey")
    public static let volumeSupportsVolumeSizesKey = URLResourceKey(rawValue: "NSURLVolumeSupportsVolumeSizesKey")
    public static let volumeSupportsRenamingKey = URLResourceKey(rawValue: "NSURLVolumeSupportsRenamingKey")
    public static let volumeSupportsAdvisoryFileLockingKey = URLResourceKey(rawValue: "NSURLVolumeSupportsAdvisoryFileLockingKey")
    public static let volumeSupportsExtendedSecurityKey = URLResourceKey(rawValue: "NSURLVolumeSupportsExtendedSecurityKey")
    public static let volumeIsBrowsableKey = URLResourceKey(rawValue: "NSURLVolumeIsBrowsableKey")
    public static let volumeMaximumFileSizeKey = URLResourceKey(rawValue: "NSURLVolumeMaximumFileSizeKey")
    public static let volumeIsEjectableKey = URLResourceKey(rawValue: "NSURLVolumeIsEjectableKey")
    public static let volumeIsRemovableKey = URLResourceKey(rawValue: "NSURLVolumeIsRemovableKey")
    public static let volumeIsInternalKey = URLResourceKey(rawValue: "NSURLVolumeIsInternalKey")
    public static let volumeIsAutomountedKey = URLResourceKey(rawValue: "NSURLVolumeIsAutomountedKey")
    public static let volumeIsLocalKey = URLResourceKey(rawValue: "NSURLVolumeIsLocalKey")
    public static let volumeIsReadOnlyKey = URLResourceKey(rawValue: "NSURLVolumeIsReadOnlyKey")
    public static let volumeCreationDateKey = URLResourceKey(rawValue: "NSURLVolumeCreationDateKey")
    public static let volumeURLForRemountingKey = URLResourceKey(rawValue: "NSURLVolumeURLForRemountingKey")
    public static let volumeUUIDStringKey = URLResourceKey(rawValue: "NSURLVolumeUUIDStringKey")
    public static let volumeNameKey = URLResourceKey(rawValue: "NSURLVolumeNameKey")
    public static let volumeLocalizedNameKey = URLResourceKey(rawValue: "NSURLVolumeLocalizedNameKey")
    public static let volumeIsEncryptedKey = URLResourceKey(rawValue: "NSURLVolumeIsEncryptedKey")
    public static let volumeIsRootFileSystemKey = URLResourceKey(rawValue: "NSURLVolumeIsRootFileSystemKey")
    public static let volumeSupportsCompressionKey = URLResourceKey(rawValue: "NSURLVolumeSupportsCompressionKey")
    public static let volumeSupportsFileCloningKey = URLResourceKey(rawValue: "NSURLVolumeSupportsFileCloningKey")
    public static let volumeSupportsSwapRenamingKey = URLResourceKey(rawValue: "NSURLVolumeSupportsSwapRenamingKey")
    public static let volumeSupportsExclusiveRenamingKey = URLResourceKey(rawValue: "NSURLVolumeSupportsExclusiveRenamingKey")
    public static let isUbiquitousItemKey = URLResourceKey(rawValue: "NSURLIsUbiquitousItemKey")
    public static let ubiquitousItemHasUnresolvedConflictsKey = URLResourceKey(rawValue: "NSURLUbiquitousItemHasUnresolvedConflictsKey")
    public static let ubiquitousItemIsDownloadingKey = URLResourceKey(rawValue: "NSURLUbiquitousItemIsDownloadingKey")
    public static let ubiquitousItemIsUploadedKey = URLResourceKey(rawValue: "NSURLUbiquitousItemIsUploadedKey")
    public static let ubiquitousItemIsUploadingKey = URLResourceKey(rawValue: "NSURLUbiquitousItemIsUploadingKey")
    public static let ubiquitousItemDownloadingStatusKey = URLResourceKey(rawValue: "NSURLUbiquitousItemDownloadingStatusKey")
    public static let ubiquitousItemDownloadingErrorKey = URLResourceKey(rawValue: "NSURLUbiquitousItemDownloadingErrorKey")
    public static let ubiquitousItemUploadingErrorKey = URLResourceKey(rawValue: "NSURLUbiquitousItemUploadingErrorKey")
    public static let ubiquitousItemDownloadRequestedKey = URLResourceKey(rawValue: "NSURLUbiquitousItemDownloadRequestedKey")
    public static let ubiquitousItemContainerDisplayNameKey = URLResourceKey(rawValue: "NSURLUbiquitousItemContainerDisplayNameKey")
}


public struct URLFileResourceType: RawRepresentable, Equatable, Hashable {
    public private(set) var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

extension URLFileResourceType {
    public static let namedPipe = URLFileResourceType(rawValue: "NSURLFileResourceTypeNamedPipe")
    public static let characterSpecial = URLFileResourceType(rawValue: "NSURLFileResourceTypeCharacterSpecial")
    public static let directory = URLFileResourceType(rawValue: "NSURLFileResourceTypeDirectory")
    public static let blockSpecial = URLFileResourceType(rawValue: "NSURLFileResourceTypeBlockSpecial")
    public static let regular = URLFileResourceType(rawValue: "NSURLFileResourceTypeRegular")
    public static let symbolicLink = URLFileResourceType(rawValue: "NSURLFileResourceTypeSymbolicLink")
    public static let socket = URLFileResourceType(rawValue: "NSURLFileResourceTypeSocket")
    public static let unknown = URLFileResourceType(rawValue: "NSURLFileResourceTypeUnknown")
}
