// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public struct NSCocoaError : RawRepresentable, ErrorType, __BridgedNSError {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    public static var __NSErrorDomain: String { return NSCocoaErrorDomain }
}

/// Enumeration that describes the error codes within the Cocoa error
/// domain.
public extension NSCocoaError {
    
    public static var FileNoSuchFileError: NSCocoaError {
        return NSCocoaError(rawValue: 4)
    }
    
    public static var FileLockingError: NSCocoaError {
        return NSCocoaError(rawValue: 255)
    }
    
    public static var FileReadUnknownError: NSCocoaError {
        return NSCocoaError(rawValue: 256)
    }
    
    public static var FileReadNoPermissionError: NSCocoaError {
        return NSCocoaError(rawValue: 257)
    }
    
    public static var FileReadInvalidFileNameError: NSCocoaError {
        return NSCocoaError(rawValue: 258)
    }
    
    public static var FileReadCorruptFileError: NSCocoaError {
        return NSCocoaError(rawValue: 259)
    }
    
    public static var FileReadNoSuchFileError: NSCocoaError {
        return NSCocoaError(rawValue: 260)
    }
    
    public static var FileReadInapplicableStringEncodingError: NSCocoaError {
        return NSCocoaError(rawValue: 261)
    }
    public static var FileReadUnsupportedSchemeError: NSCocoaError {
        return NSCocoaError(rawValue: 262)
    }
    
    public static var FileReadTooLargeError: NSCocoaError {
        return NSCocoaError(rawValue: 263)
    }
    
    public static var FileReadUnknownStringEncodingError: NSCocoaError {
        return NSCocoaError(rawValue: 264)
    }
    
    public static var FileWriteUnknownError: NSCocoaError {
        return NSCocoaError(rawValue: 512)
    }
    
    public static var FileWriteNoPermissionError: NSCocoaError {
        return NSCocoaError(rawValue: 513)
    }
    
    public static var FileWriteInvalidFileNameError: NSCocoaError {
        return NSCocoaError(rawValue: 514)
    }
    
    public static var FileWriteFileExistsError: NSCocoaError {
        return NSCocoaError(rawValue: 516)
    }
    
    public static var FileWriteInapplicableStringEncodingError: NSCocoaError {
        return NSCocoaError(rawValue: 517)
    }
    
    public static var FileWriteUnsupportedSchemeError: NSCocoaError {
        return NSCocoaError(rawValue: 518)
    }
    
    public static var FileWriteOutOfSpaceError: NSCocoaError {
        return NSCocoaError(rawValue: 640)
    }
    
    public static var FileWriteVolumeReadOnlyError: NSCocoaError {
        return NSCocoaError(rawValue: 642)
    }
    
    public static var FileManagerUnmountUnknownError: NSCocoaError {
        return NSCocoaError(rawValue: 768)
    }
    
    public static var FileManagerUnmountBusyError: NSCocoaError {
        return NSCocoaError(rawValue: 769)
    }
    
    public static var KeyValueValidationError: NSCocoaError {
        return NSCocoaError(rawValue: 1024)
    }
    
    public static var FormattingError: NSCocoaError {
        return NSCocoaError(rawValue: 2048)
    }
    
    public static var UserCancelledError: NSCocoaError {
        return NSCocoaError(rawValue: 3072)
    }
    
    public static var FeatureUnsupportedError: NSCocoaError {
        return NSCocoaError(rawValue: 3328)
    }
    
    public static var ExecutableNotLoadableError: NSCocoaError {
        return NSCocoaError(rawValue: 3584)
    }
    
    public static var ExecutableArchitectureMismatchError: NSCocoaError {
        return NSCocoaError(rawValue: 3585)
    }
    
    public static var ExecutableRuntimeMismatchError: NSCocoaError {
        return NSCocoaError(rawValue: 3586)
    }
    
    public static var ExecutableLoadError: NSCocoaError {
        return NSCocoaError(rawValue: 3587)
    }
    
    public static var ExecutableLinkError: NSCocoaError {
        return NSCocoaError(rawValue: 3588)
    }
    
    public static var PropertyListReadCorruptError: NSCocoaError {
        return NSCocoaError(rawValue: 3840)
    }

    public static var PropertyListReadUnknownVersionError: NSCocoaError {
        return NSCocoaError(rawValue: 3841)
    }
    
    public static var PropertyListReadStreamError: NSCocoaError {
        return NSCocoaError(rawValue: 3842)
    }
    
    public static var PropertyListWriteStreamError: NSCocoaError {
        return NSCocoaError(rawValue: 3851)
    }
    
    public static var PropertyListWriteInvalidError: NSCocoaError {
        return NSCocoaError(rawValue: 3852)
    }
    
    public static var XPCConnectionInterrupted: NSCocoaError {
        return NSCocoaError(rawValue: 4097)
    }
    
    public static var XPCConnectionInvalid: NSCocoaError {
        return NSCocoaError(rawValue: 4099)
    }
    
    public static var XPCConnectionReplyInvalid: NSCocoaError {
        return NSCocoaError(rawValue: 4101)
    }
    
    public static var UbiquitousFileUnavailableError: NSCocoaError {
        return NSCocoaError(rawValue: 4353)
    }
    
    public static var UbiquitousFileNotUploadedDueToQuotaError: NSCocoaError {
        return NSCocoaError(rawValue: 4354)
    }

    public static var UbiquitousFileUbiquityServerNotAvailable: NSCocoaError {
        return NSCocoaError(rawValue: 4355)
    }
    
    public static var UserActivityHandoffFailedError: NSCocoaError {
        return NSCocoaError(rawValue: 4608)
    }
    
    public static var UserActivityConnectionUnavailableError: NSCocoaError {
        return NSCocoaError(rawValue: 4609)
    }
    
    public static var UserActivityRemoteApplicationTimedOutError: NSCocoaError {
        return NSCocoaError(rawValue: 4610)
    }
    
    public static var UserActivityHandoffUserInfoTooLargeError: NSCocoaError {
        return NSCocoaError(rawValue: 4611)
    }
    
    public static var CoderReadCorruptError: NSCocoaError {
        return NSCocoaError(rawValue: 4864)
    }
    
    public static var CoderValueNotFoundError: NSCocoaError {
        return NSCocoaError(rawValue: 4865)
    }
    
    public var isCoderError: Bool {
        return rawValue >= 4864 && rawValue <= 4991;
    }
    
    public var isExecutableError: Bool {
        return rawValue >= 3584 && rawValue <= 3839;
    }
    
    public var isFileError: Bool {
        return rawValue >= 0 && rawValue <= 1023;
    }
    
    public var isFormattingError: Bool {
        return rawValue >= 2048 && rawValue <= 2559;
    }
    
    public var isPropertyListError: Bool {
        return rawValue >= 3840 && rawValue <= 4095;
    }
    
    public var isUbiquitousFileError: Bool {
        return rawValue >= 4352 && rawValue <= 4607;
    }
    
    public var isUserActivityError: Bool {
        return rawValue >= 4608 && rawValue <= 4863;
    }
    
    public var isValidationError: Bool {
        return rawValue >= 1024 && rawValue <= 2047;
    }
    
    public var isXPCConnectionError: Bool {
        return rawValue >= 4096 && rawValue <= 4224;
    }
}

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

internal func _NSErrorWithErrno(posixErrno : Int32, reading : Bool, path : String? = nil, url : NSURL? = nil, extraUserInfo : [String : Any]? = nil) -> NSError {
    var cocoaError : NSCocoaError
    if reading {
        switch posixErrno {
            case EFBIG: cocoaError = NSCocoaError.FileReadTooLargeError
            case ENOENT: cocoaError = NSCocoaError.FileReadNoSuchFileError
            case EPERM, EACCES: cocoaError = NSCocoaError.FileReadNoPermissionError
            case ENAMETOOLONG: cocoaError = NSCocoaError.FileReadUnknownError
            default: cocoaError = NSCocoaError.FileReadUnknownError
        }
    } else {
        switch posixErrno {
            case ENOENT: cocoaError = NSCocoaError.FileNoSuchFileError
            case EPERM, EACCES: cocoaError = NSCocoaError.FileWriteNoPermissionError
            case ENAMETOOLONG: cocoaError = NSCocoaError.FileWriteInvalidFileNameError
            case EDQUOT, ENOSPC: cocoaError = NSCocoaError.FileWriteOutOfSpaceError
            case EROFS: cocoaError = NSCocoaError.FileWriteVolumeReadOnlyError
            case EEXIST: cocoaError = NSCocoaError.FileWriteFileExistsError
            default: cocoaError = NSCocoaError.FileWriteUnknownError
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
