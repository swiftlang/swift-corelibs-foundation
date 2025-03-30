##===----------------------------------------------------------------------===##
##
## This source file is part of the Swift open source project
##
## Copyright (c) 2024 Apple Inc. and the Swift project authors
## Licensed under Apache License v2.0
##
## See LICENSE.txt for license information
## See CONTRIBUTORS.md for the list of Swift project authors
##
## SPDX-License-Identifier: Apache-2.0
##
##===----------------------------------------------------------------------===##

add_library(Foundation
    AffineTransform.swift
    Array.swift
    Boxing.swift
    Bridging.swift
    Bundle.swift
    ByteCountFormatter.swift
    CGFloat.swift
    CharacterSet.swift
    DateComponents.swift
    DateComponentsFormatter.swift
    DateFormatter.swift
    DateInterval.swift
    DateIntervalFormatter.swift
    Decimal.swift
    Dictionary.swift
    DispatchData+DataProtocol.swift
    EnergyFormatter.swift
    Essentials.swift
    ExtraStringAPIs.swift
    FileHandle.swift
    FileManager.swift
    FileManager+POSIX.swift
    FileManager+Win32.swift
    Formatter.swift
    FoundationErrors.swift
    Host.swift
    IndexPath.swift
    IndexSet.swift
    ISO8601DateFormatter.swift
    JSONDecoder.swift
    JSONEncoder.swift
    JSONSerialization.swift
    JSONSerialization+Parser.swift
    LengthFormatter.swift
    MassFormatter.swift
    Measurement.swift
    MeasurementFormatter.swift
    Morphology.swift
    Notification.swift
    NotificationQueue.swift
    NSArray.swift
    NSAttributedString.swift
    NSCache.swift
    NSCalendar.swift
    NSCFArray.swift
    NSCFBoolean.swift
    NSCFCharacterSet.swift
    NSCFDictionary.swift
    NSCFSet.swift
    NSCFString.swift
    NSCFTypeShims.swift
    NSCharacterSet.swift
    NSCoder.swift
    NSComparisonPredicate.swift
    NSCompoundPredicate.swift
    NSConcreteValue.swift
    NSData.swift
    NSData+DataProtocol.swift
    NSDate.swift
    NSDateComponents.swift
    NSDecimalNumber.swift
    NSDictionary.swift
    NSEnumerator.swift
    NSError.swift
    NSExpression.swift
    NSGeometry.swift
    NSIndexPath.swift
    NSIndexSet.swift
    NSKeyedArchiver.swift
    NSKeyedArchiverHelpers.swift
    NSKeyedCoderOldStyleArray.swift
    NSKeyedUnarchiver.swift
    NSLocale.swift
    NSLock.swift
    NSLog.swift
    NSMeasurement.swift
    NSNotification.swift
    NSNull.swift
    NSNumber.swift
    NSObjCRuntime.swift
    NSObject.swift
    NSOrderedSet.swift
    NSPathUtilities.swift
    NSPersonNameComponents.swift
    NSPlatform.swift
    NSPredicate.swift
    NSRange.swift
    NSRegularExpression.swift
    NSSet.swift
    NSSortDescriptor.swift
    NSSpecialValue.swift
    NSString.swift
    NSStringAPI.swift
    NSSwiftRuntime.swift
    NSTextCheckingResult.swift
    NSTimeZone.swift
    NSURL.swift
    NSURLComponents.swift
    NSURLError.swift
    NSURLQueryItem.swift
    NSUUID.swift
    NSValue.swift
    NumberFormatter.swift
    Operation.swift
    PersonNameComponents.swift
    PersonNameComponentsFormatter.swift
    Port.swift
    PortMessage.swift
    Process.swift
    ProcessInfo.swift
    Progress.swift
    ProgressFraction.swift
    PropertyListSerialization.swift
    ReferenceConvertible.swift
    RunLoop.swift
    Scanner.swift
    ScannerAPI.swift
    Set.swift
    Stream.swift
    String.swift
    StringEncodings.swift
    Thread.swift
    Timer.swift
    Unit.swift
    URL.swift
    URLComponents.swift
    URLQueryItem.swift
    URLResourceKey.swift
    UserDefaults.swift
    UUID.swift
    WinSDK+Extensions.swift)

target_compile_options(Foundation PRIVATE
    "SHELL:$<$<COMPILE_LANGUAGE:Swift>:${_Foundation_swift_build_flags}>")

target_link_libraries(Foundation
    PRIVATE
        CoreFoundation
    PUBLIC
        FoundationEssentials
        FoundationInternationalization)

if(NOT BUILD_SHARED_LIBS)
    target_compile_options(Foundation PRIVATE
        "SHELL:$<$<COMPILE_LANGUAGE:Swift>:-Xfrontend -public-autolink-library -Xfrontend CoreFoundation>")
    target_compile_options(Foundation PRIVATE
        "SHELL:$<$<COMPILE_LANGUAGE:Swift>:-Xfrontend -public-autolink-library -Xfrontend _FoundationICU>")
    target_compile_options(Foundation PRIVATE
        "SHELL:$<$<COMPILE_LANGUAGE:Swift>:-Xfrontend -public-autolink-library -Xfrontend swiftSynchronization>")
endif()

if(dispatch_FOUND)
    set_target_properties(Foundation PROPERTIES
        BUILD_RPATH "$<TARGET_FILE_DIR:swiftDispatch>")
    target_link_libraries(Foundation PUBLIC
        swiftDispatch)
endif()

if(LINKER_SUPPORTS_BUILD_ID)
  target_link_options(Foundation PRIVATE "LINKER:--build-id=sha1")
endif()

set_property(GLOBAL APPEND PROPERTY Foundation_EXPORTS Foundation)
_foundation_install_target(Foundation)
