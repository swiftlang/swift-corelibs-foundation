// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

import CoreFoundation

#if DEPLOYMENT_RUNTIME_SWIFT && _runtime(_ObjC)
    @_exported import SwiftFoundationSoil

    public typealias NSAffineTransform = SwiftFoundationSoil.NSAffineTransform
    public typealias NSArray = SwiftFoundationSoil.NSArray
    public typealias NSMutableArray = SwiftFoundationSoil.NSMutableArray
    public typealias NSAttributedString = SwiftFoundationSoil.NSAttributedString
    public typealias NSMutableAttributedString = SwiftFoundationSoil.NSMutableAttributedString
    public typealias NSCache = SwiftFoundationSoil.NSCache
    public typealias NSCalendar = SwiftFoundationSoil.NSCalendar
    public typealias NSDateComponents = SwiftFoundationSoil.NSDateComponents
    public typealias NSCharacterSet = SwiftFoundationSoil.NSCharacterSet
    public typealias NSMutableCharacterSet = SwiftFoundationSoil.NSMutableCharacterSet
    public typealias NSCoder = SwiftFoundationSoil.NSCoder
    public typealias NSComparisonPredicate = SwiftFoundationSoil.NSComparisonPredicate
    public typealias NSCompoundPredicate = SwiftFoundationSoil.NSCompoundPredicate
    public typealias NSData = SwiftFoundationSoil.NSData
    public typealias NSMutableData = SwiftFoundationSoil.NSMutableData
    public typealias NSDate = SwiftFoundationSoil.NSDate
    public typealias NSDateInterval = SwiftFoundationSoil.NSDateInterval
    public typealias NSDecimalNumber = SwiftFoundationSoil.NSDecimalNumber
    public typealias NSDecimalNumberHandler = SwiftFoundationSoil.NSDecimalNumberHandler
    public typealias NSDictionary = SwiftFoundationSoil.NSDictionary
    public typealias NSMutableDictionary = SwiftFoundationSoil.NSMutableDictionary
    public typealias NSEnumerator = SwiftFoundationSoil.NSEnumerator
    public typealias NSError = SwiftFoundationSoil.NSError
    public typealias NSExpression = SwiftFoundationSoil.NSExpression
    public typealias NSIndexPath = SwiftFoundationSoil.NSIndexPath
    public typealias NSIndexSet = SwiftFoundationSoil.NSIndexSet
    public typealias NSMutableIndexSet = SwiftFoundationSoil.NSMutableIndexSet
    public typealias NSKeyedArchiver = SwiftFoundationSoil.NSKeyedArchiver
    public typealias NSKeyedUnarchiver = SwiftFoundationSoil.NSKeyedUnarchiver
    public typealias NSLocale = SwiftFoundationSoil.NSLocale
    public typealias NSLock = SwiftFoundationSoil.NSLock
    public typealias NSConditionLock = SwiftFoundationSoil.NSConditionLock
    public typealias NSRecursiveLock = SwiftFoundationSoil.NSRecursiveLock
    public typealias NSCondition = SwiftFoundationSoil.NSCondition
    public typealias NSMeasurement = SwiftFoundationSoil.NSMeasurement
    public typealias NSNotification = SwiftFoundationSoil.NSNotification
    public typealias NSNull = SwiftFoundationSoil.NSNull
    public typealias NSNumber = SwiftFoundationSoil.NSNumber
    public typealias NSObject = SwiftFoundationSoil.NSObject
    public typealias NSOrderedSet = SwiftFoundationSoil.NSOrderedSet
    public typealias NSMutableOrderedSet = SwiftFoundationSoil.NSMutableOrderedSet
    public typealias NSPersonNameComponents = SwiftFoundationSoil.NSPersonNameComponents
    public typealias NSPredicate = SwiftFoundationSoil.NSPredicate
    public typealias NSRegularExpression = SwiftFoundationSoil.NSRegularExpression
    public typealias NSSet = SwiftFoundationSoil.NSSet
    public typealias NSMutableSet = SwiftFoundationSoil.NSMutableSet
    public typealias NSCountedSet = SwiftFoundationSoil.NSCountedSet
    public typealias NSSortDescriptor = SwiftFoundationSoil.NSSortDescriptor
    public typealias NSString = SwiftFoundationSoil.NSString
    public typealias NSMutableString = SwiftFoundationSoil.NSMutableString
    public typealias NSTextCheckingResult = SwiftFoundationSoil.NSTextCheckingResult
    public typealias NSTimeZone = SwiftFoundationSoil.NSTimeZone
    public typealias NSURL = SwiftFoundationSoil.NSURL
    public typealias NSURLQueryItem = SwiftFoundationSoil.NSURLQueryItem
    public typealias NSURLComponents = SwiftFoundationSoil.NSURLComponents
    public typealias NSURLRequest = SwiftFoundationSoil.NSURLRequest
    public typealias NSMutableURLRequest = SwiftFoundationSoil.NSMutableURLRequest
    public typealias NSUUID = SwiftFoundationSoil.NSUUID
    public typealias NSValue = SwiftFoundationSoil.NSValue
#else
    @_exported import FoundationSoil

    public typealias NSAffineTransform = FoundationSoil.NSAffineTransform
    public typealias NSArray = FoundationSoil.NSArray
    public typealias NSMutableArray = FoundationSoil.NSMutableArray
    public typealias NSAttributedString = FoundationSoil.NSAttributedString
    public typealias NSMutableAttributedString = FoundationSoil.NSMutableAttributedString
    public typealias NSCache = FoundationSoil.NSCache
    public typealias NSCalendar = FoundationSoil.NSCalendar
    public typealias NSDateComponents = FoundationSoil.NSDateComponents
    public typealias NSCharacterSet = FoundationSoil.NSCharacterSet
    public typealias NSMutableCharacterSet = FoundationSoil.NSMutableCharacterSet
    public typealias NSCoder = FoundationSoil.NSCoder
    public typealias NSComparisonPredicate = FoundationSoil.NSComparisonPredicate
    public typealias NSCompoundPredicate = FoundationSoil.NSCompoundPredicate
    public typealias NSData = FoundationSoil.NSData
    public typealias NSMutableData = FoundationSoil.NSMutableData
    public typealias NSDate = FoundationSoil.NSDate
    public typealias NSDateInterval = FoundationSoil.NSDateInterval
    public typealias NSDecimalNumber = FoundationSoil.NSDecimalNumber
    public typealias NSDecimalNumberHandler = FoundationSoil.NSDecimalNumberHandler
    public typealias NSDictionary = FoundationSoil.NSDictionary
    public typealias NSMutableDictionary = FoundationSoil.NSMutableDictionary
    public typealias NSEnumerator = FoundationSoil.NSEnumerator
    public typealias NSError = FoundationSoil.NSError
    public typealias NSExpression = FoundationSoil.NSExpression
    public typealias NSIndexPath = FoundationSoil.NSIndexPath
    public typealias NSIndexSet = FoundationSoil.NSIndexSet
    public typealias NSMutableIndexSet = FoundationSoil.NSMutableIndexSet
    public typealias NSKeyedArchiver = FoundationSoil.NSKeyedArchiver
    public typealias NSKeyedUnarchiver = FoundationSoil.NSKeyedUnarchiver
    public typealias NSLocale = FoundationSoil.NSLocale
    public typealias NSLock = FoundationSoil.NSLock
    public typealias NSConditionLock = FoundationSoil.NSConditionLock
    public typealias NSRecursiveLock = FoundationSoil.NSRecursiveLock
    public typealias NSCondition = FoundationSoil.NSCondition
    public typealias NSMeasurement = FoundationSoil.NSMeasurement
    public typealias NSNotification = FoundationSoil.NSNotification
    public typealias NSNull = FoundationSoil.NSNull
    public typealias NSNumber = FoundationSoil.NSNumber
    public typealias NSObject = FoundationSoil.NSObject
    public typealias NSOrderedSet = FoundationSoil.NSOrderedSet
    public typealias NSMutableOrderedSet = FoundationSoil.NSMutableOrderedSet
    public typealias NSPersonNameComponents = FoundationSoil.NSPersonNameComponents
    public typealias NSPredicate = FoundationSoil.NSPredicate
    public typealias NSRegularExpression = FoundationSoil.NSRegularExpression
    public typealias NSSet = FoundationSoil.NSSet
    public typealias NSMutableSet = FoundationSoil.NSMutableSet
    public typealias NSCountedSet = FoundationSoil.NSCountedSet
    public typealias NSSortDescriptor = FoundationSoil.NSSortDescriptor
    public typealias NSString = FoundationSoil.NSString
    public typealias NSMutableString = FoundationSoil.NSMutableString
    public typealias NSTextCheckingResult = FoundationSoil.NSTextCheckingResult
    public typealias NSTimeZone = FoundationSoil.NSTimeZone
    public typealias NSURL = FoundationSoil.NSURL
    public typealias NSURLQueryItem = FoundationSoil.NSURLQueryItem
    public typealias NSURLComponents = FoundationSoil.NSURLComponents
    public typealias NSURLRequest = FoundationSoil.NSURLRequest
    public typealias NSMutableURLRequest = FoundationSoil.NSMutableURLRequest
    public typealias NSUUID = FoundationSoil.NSUUID
    public typealias NSValue = FoundationSoil.NSValue
#endif

// These type aliases are used to maintain source compatibility, even though these types now live in FoundationSoil now.


// Below this point are compiler intrinsics — symbols either swiftc or clang rely upon that _must_ be in the Foundation module.

#if !canImport(ObjectiveC)

enum UnknownNSError: Error {
    case missingError
}

public // COMPILER_INTRINSIC
func _convertNSErrorToError(_ error: NSError?) -> Error {
    return error ?? UnknownNSError.missingError
}

public // COMPILER_INTRINSIC
func _convertErrorToNSError(_ error: Error) -> NSError {
    if let object = _extractDynamicValue(error as Any) {
        return unsafeBitCast(object, to: NSError.self)
    } else {
        let domain: String
        let code: Int
        let userInfo: [String: Any]
        
        if let error = error as? CustomNSError {
            domain = type(of: error).errorDomain
            code = error.errorCode
            userInfo = error.errorUserInfo
        } else {
            domain = "SwiftError"
            code = 0
            userInfo = (_swift_Foundation_getErrorDefaultUserInfo(error) as? [String : Any]) ?? [:]
        }
        
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
}

#endif

