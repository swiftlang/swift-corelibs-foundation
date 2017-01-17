// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public var NSFileNoSuchFileError: Int                        { return CocoaError.Code.fileNoSuchFile.rawValue }
public var NSFileLockingError: Int                           { return CocoaError.Code.fileLocking.rawValue }
public var NSFileReadUnknownError: Int                       { return CocoaError.Code.fileReadUnknown.rawValue }
public var NSFileReadNoPermissionError: Int                  { return CocoaError.Code.fileReadNoPermission.rawValue }
public var NSFileReadInvalidFileNameError: Int               { return CocoaError.Code.fileReadInvalidFileName.rawValue }
public var NSFileReadCorruptFileError: Int                   { return CocoaError.Code.fileReadCorruptFile.rawValue }
public var NSFileReadNoSuchFileError: Int                    { return CocoaError.Code.fileReadNoSuchFile.rawValue }
public var NSFileReadInapplicableStringEncodingError: Int    { return CocoaError.Code.fileReadInapplicableStringEncoding.rawValue }
public var NSFileReadUnsupportedSchemeError: Int             { return CocoaError.Code.fileReadUnsupportedScheme.rawValue }
public var NSFileReadTooLargeError: Int                      { return CocoaError.Code.fileReadTooLarge.rawValue }
public var NSFileReadUnknownStringEncodingError: Int         { return CocoaError.Code.fileReadUnknownStringEncoding.rawValue }
public var NSFileWriteUnknownError: Int                      { return CocoaError.Code.fileWriteUnknown.rawValue }
public var NSFileWriteNoPermissionError: Int                 { return CocoaError.Code.fileWriteNoPermission.rawValue }
public var NSFileWriteInvalidFileNameError: Int              { return CocoaError.Code.fileWriteInvalidFileName.rawValue }
public var NSFileWriteFileExistsError: Int                   { return CocoaError.Code.fileWriteFileExists.rawValue }
public var NSFileWriteInapplicableStringEncodingError: Int   { return CocoaError.Code.fileWriteInapplicableStringEncoding.rawValue }
public var NSFileWriteUnsupportedSchemeError: Int            { return CocoaError.Code.fileWriteUnsupportedScheme.rawValue }
public var NSFileWriteOutOfSpaceError: Int                   { return CocoaError.Code.fileWriteOutOfSpace.rawValue }
public var NSFileWriteVolumeReadOnlyError: Int               { return CocoaError.Code.fileWriteVolumeReadOnly.rawValue }
public var NSFileManagerUnmountUnknownError: Int             { return CocoaError.Code.fileManagerUnmountUnknown.rawValue }
public var NSFileManagerUnmountBusyError: Int                { return CocoaError.Code.fileManagerUnmountBusy.rawValue }
public var NSKeyValueValidationError: Int                    { return CocoaError.Code.keyValueValidation.rawValue }
public var NSFormattingError: Int                            { return CocoaError.Code.formatting.rawValue }
public var NSUserCancelledError: Int                         { return CocoaError.Code.userCancelled.rawValue }
public var NSFeatureUnsupportedError: Int                    { return CocoaError.Code.featureUnsupported.rawValue }
public var NSExecutableNotLoadableError: Int                 { return CocoaError.Code.executableNotLoadable.rawValue }
public var NSExecutableArchitectureMismatchError: Int        { return CocoaError.Code.executableArchitectureMismatch.rawValue }
public var NSExecutableRuntimeMismatchError: Int             { return CocoaError.Code.executableRuntimeMismatch.rawValue }
public var NSExecutableLoadError: Int                        { return CocoaError.Code.executableLoad.rawValue }
public var NSExecutableLinkError: Int                        { return CocoaError.Code.executableLink.rawValue }
public var NSPropertyListReadCorruptError: Int               { return CocoaError.Code.propertyListReadCorrupt.rawValue }
public var NSPropertyListReadUnknownVersionError: Int        { return CocoaError.Code.propertyListReadUnknownVersion.rawValue }
public var NSPropertyListReadStreamError: Int                { return CocoaError.Code.propertyListReadStream.rawValue }
public var NSPropertyListWriteStreamError: Int               { return CocoaError.Code.propertyListWriteStream.rawValue }
public var NSPropertyListWriteInvalidError: Int              { return CocoaError.Code.propertyListWriteInvalid.rawValue }
public var NSXPCConnectionInterrupted: Int                   { return CocoaError.Code.xpcConnectionInterrupted.rawValue }
public var NSXPCConnectionInvalid: Int                       { return CocoaError.Code.xpcConnectionInvalid.rawValue }
public var NSXPCConnectionReplyInvalid: Int                  { return CocoaError.Code.xpcConnectionReplyInvalid.rawValue }
public var NSUbiquitousFileUnavailableError: Int             { return CocoaError.Code.ubiquitousFileUnavailable.rawValue }
public var NSUbiquitousFileNotUploadedDueToQuotaError: Int   { return CocoaError.Code.ubiquitousFileNotUploadedDueToQuota.rawValue }
public var NSUbiquitousFileUbiquityServerNotAvailable: Int   { return CocoaError.Code.ubiquitousFileUbiquityServerNotAvailable.rawValue }
public var NSUserActivityHandoffFailedError: Int             { return CocoaError.Code.userActivityHandoffFailed.rawValue }
public var NSUserActivityConnectionUnavailableError: Int     { return CocoaError.Code.userActivityConnectionUnavailable.rawValue }
public var NSUserActivityRemoteApplicationTimedOutError: Int { return CocoaError.Code.userActivityRemoteApplicationTimedOut.rawValue }
public var NSUserActivityHandoffUserInfoTooLargeError: Int   { return CocoaError.Code.userActivityHandoffUserInfoTooLarge.rawValue }
public var NSCoderReadCorruptError: Int                      { return CocoaError.Code.coderReadCorrupt.rawValue }
public var NSCoderValueNotFoundError: Int                    { return CocoaError.Code.coderValueNotFound.rawValue }

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux) || CYGWIN
    import Glibc
#endif

internal func _NSErrorWithErrno(_ posixErrno : Int32, reading : Bool, path : String? = nil, url : URL? = nil, extraUserInfo : [String : Any]? = nil) -> NSError {
    var cocoaError : CocoaError.Code
    if reading {
        switch posixErrno {
            case EFBIG: cocoaError = CocoaError.fileReadTooLarge
            case ENOENT: cocoaError = CocoaError.fileReadNoSuchFile
            case EPERM, EACCES: cocoaError = CocoaError.fileReadNoPermission
            case ENAMETOOLONG: cocoaError = CocoaError.fileReadUnknown
            default: cocoaError = CocoaError.fileReadUnknown
        }
    } else {
        switch posixErrno {
            case ENOENT: cocoaError = CocoaError.fileNoSuchFile
            case EPERM, EACCES: cocoaError = CocoaError.fileWriteNoPermission
            case ENAMETOOLONG: cocoaError = CocoaError.fileWriteInvalidFileName
            case EDQUOT, ENOSPC: cocoaError = CocoaError.fileWriteOutOfSpace
            case EROFS: cocoaError = CocoaError.fileWriteVolumeReadOnly
            case EEXIST: cocoaError = CocoaError.fileWriteFileExists
            default: cocoaError = CocoaError.fileWriteUnknown
        }
    }
    
    var userInfo = extraUserInfo ?? [String : Any]()
    if let path = path {
        userInfo[NSFilePathErrorKey] = path._nsObject
    } else if let url = url {
        userInfo[NSURLErrorKey] = url
    }
    
    return NSError(domain: NSCocoaErrorDomain, code: cocoaError.rawValue, userInfo: userInfo)
}
