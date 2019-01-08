// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

import CoreFoundation

#if DEPLOYMENT_RUNTIME_SWIFT && _runtime(_ObjC)
    @_exported import SwiftFoundationBase

    public typealias NSAffineTransform = SwiftFoundationBase.NSAffineTransform
    public typealias NSArray = SwiftFoundationBase.NSArray
    public typealias NSMutableArray = SwiftFoundationBase.NSMutableArray
    public typealias NSAttributedString = SwiftFoundationBase.NSAttributedString
    public typealias NSMutableAttributedString = SwiftFoundationBase.NSMutableAttributedString
    public typealias NSCache = SwiftFoundationBase.NSCache
    public typealias NSCalendar = SwiftFoundationBase.NSCalendar
    public typealias NSDateComponents = SwiftFoundationBase.NSDateComponents
    public typealias NSCharacterSet = SwiftFoundationBase.NSCharacterSet
    public typealias NSMutableCharacterSet = SwiftFoundationBase.NSMutableCharacterSet
    public typealias NSCoder = SwiftFoundationBase.NSCoder
    public typealias NSComparisonPredicate = SwiftFoundationBase.NSComparisonPredicate
    public typealias NSCompoundPredicate = SwiftFoundationBase.NSCompoundPredicate
    public typealias NSData = SwiftFoundationBase.NSData
    public typealias NSMutableData = SwiftFoundationBase.NSMutableData
    public typealias NSDate = SwiftFoundationBase.NSDate
    public typealias NSDateInterval = SwiftFoundationBase.NSDateInterval
    public typealias NSDecimalNumber = SwiftFoundationBase.NSDecimalNumber
    public typealias NSDecimalNumberHandler = SwiftFoundationBase.NSDecimalNumberHandler
    public typealias NSDictionary = SwiftFoundationBase.NSDictionary
    public typealias NSMutableDictionary = SwiftFoundationBase.NSMutableDictionary
    public typealias NSEnumerator = SwiftFoundationBase.NSEnumerator
    public typealias NSError = SwiftFoundationBase.NSError
    public typealias NSExpression = SwiftFoundationBase.NSExpression
    public typealias NSIndexPath = SwiftFoundationBase.NSIndexPath
    public typealias NSIndexSet = SwiftFoundationBase.NSIndexSet
    public typealias NSMutableIndexSet = SwiftFoundationBase.NSMutableIndexSet
    public typealias NSKeyedArchiver = SwiftFoundationBase.NSKeyedArchiver
    public typealias NSKeyedUnarchiver = SwiftFoundationBase.NSKeyedUnarchiver
    public typealias NSLocale = SwiftFoundationBase.NSLocale
    public typealias NSLock = SwiftFoundationBase.NSLock
    public typealias NSConditionLock = SwiftFoundationBase.NSConditionLock
    public typealias NSRecursiveLock = SwiftFoundationBase.NSRecursiveLock
    public typealias NSCondition = SwiftFoundationBase.NSCondition
    public typealias NSMeasurement = SwiftFoundationBase.NSMeasurement
    public typealias NSNotification = SwiftFoundationBase.NSNotification
    public typealias NSNull = SwiftFoundationBase.NSNull
    public typealias NSNumber = SwiftFoundationBase.NSNumber
    public typealias NSObject = SwiftFoundationBase.NSObject
    public typealias NSOrderedSet = SwiftFoundationBase.NSOrderedSet
    public typealias NSMutableOrderedSet = SwiftFoundationBase.NSMutableOrderedSet
    public typealias NSPersonNameComponents = SwiftFoundationBase.NSPersonNameComponents
    public typealias NSPredicate = SwiftFoundationBase.NSPredicate
    public typealias NSRegularExpression = SwiftFoundationBase.NSRegularExpression
    public typealias NSSet = SwiftFoundationBase.NSSet
    public typealias NSMutableSet = SwiftFoundationBase.NSMutableSet
    public typealias NSCountedSet = SwiftFoundationBase.NSCountedSet
    public typealias NSSortDescriptor = SwiftFoundationBase.NSSortDescriptor
    public typealias NSString = SwiftFoundationBase.NSString
    public typealias NSMutableString = SwiftFoundationBase.NSMutableString
    public typealias NSTextCheckingResult = SwiftFoundationBase.NSTextCheckingResult
    public typealias NSTimeZone = SwiftFoundationBase.NSTimeZone
    public typealias NSURL = SwiftFoundationBase.NSURL
    public typealias NSURLQueryItem = SwiftFoundationBase.NSURLQueryItem
    public typealias NSURLComponents = SwiftFoundationBase.NSURLComponents
    public typealias NSURLRequest = SwiftFoundationBase.NSURLRequest
    public typealias NSMutableURLRequest = SwiftFoundationBase.NSMutableURLRequest
    public typealias NSUUID = SwiftFoundationBase.NSUUID
    public typealias NSValue = SwiftFoundationBase.NSValue
#else
    @_exported import FoundationBase

    public typealias NSAffineTransform = FoundationBase.NSAffineTransform
    public typealias NSArray = FoundationBase.NSArray
    public typealias NSMutableArray = FoundationBase.NSMutableArray
    public typealias NSAttributedString = FoundationBase.NSAttributedString
    public typealias NSMutableAttributedString = FoundationBase.NSMutableAttributedString
    public typealias NSCache = FoundationBase.NSCache
    public typealias NSCalendar = FoundationBase.NSCalendar
    public typealias NSDateComponents = FoundationBase.NSDateComponents
    public typealias NSCharacterSet = FoundationBase.NSCharacterSet
    public typealias NSMutableCharacterSet = FoundationBase.NSMutableCharacterSet
    public typealias NSCoder = FoundationBase.NSCoder
    public typealias NSComparisonPredicate = FoundationBase.NSComparisonPredicate
    public typealias NSCompoundPredicate = FoundationBase.NSCompoundPredicate
    public typealias NSData = FoundationBase.NSData
    public typealias NSMutableData = FoundationBase.NSMutableData
    public typealias NSDate = FoundationBase.NSDate
    public typealias NSDateInterval = FoundationBase.NSDateInterval
    public typealias NSDecimalNumber = FoundationBase.NSDecimalNumber
    public typealias NSDecimalNumberHandler = FoundationBase.NSDecimalNumberHandler
    public typealias NSDictionary = FoundationBase.NSDictionary
    public typealias NSMutableDictionary = FoundationBase.NSMutableDictionary
    public typealias NSEnumerator = FoundationBase.NSEnumerator
    public typealias NSError = FoundationBase.NSError
    public typealias NSExpression = FoundationBase.NSExpression
    public typealias NSIndexPath = FoundationBase.NSIndexPath
    public typealias NSIndexSet = FoundationBase.NSIndexSet
    public typealias NSMutableIndexSet = FoundationBase.NSMutableIndexSet
    public typealias NSKeyedArchiver = FoundationBase.NSKeyedArchiver
    public typealias NSKeyedUnarchiver = FoundationBase.NSKeyedUnarchiver
    public typealias NSLocale = FoundationBase.NSLocale
    public typealias NSLock = FoundationBase.NSLock
    public typealias NSConditionLock = FoundationBase.NSConditionLock
    public typealias NSRecursiveLock = FoundationBase.NSRecursiveLock
    public typealias NSCondition = FoundationBase.NSCondition
    public typealias NSMeasurement = FoundationBase.NSMeasurement
    public typealias NSNotification = FoundationBase.NSNotification
    public typealias NSNull = FoundationBase.NSNull
    public typealias NSNumber = FoundationBase.NSNumber
    public typealias NSObject = FoundationBase.NSObject
    public typealias NSOrderedSet = FoundationBase.NSOrderedSet
    public typealias NSMutableOrderedSet = FoundationBase.NSMutableOrderedSet
    public typealias NSPersonNameComponents = FoundationBase.NSPersonNameComponents
    public typealias NSPredicate = FoundationBase.NSPredicate
    public typealias NSRegularExpression = FoundationBase.NSRegularExpression
    public typealias NSSet = FoundationBase.NSSet
    public typealias NSMutableSet = FoundationBase.NSMutableSet
    public typealias NSCountedSet = FoundationBase.NSCountedSet
    public typealias NSSortDescriptor = FoundationBase.NSSortDescriptor
    public typealias NSString = FoundationBase.NSString
    public typealias NSMutableString = FoundationBase.NSMutableString
    public typealias NSTextCheckingResult = FoundationBase.NSTextCheckingResult
    public typealias NSTimeZone = FoundationBase.NSTimeZone
    public typealias NSURL = FoundationBase.NSURL
    public typealias NSURLQueryItem = FoundationBase.NSURLQueryItem
    public typealias NSURLComponents = FoundationBase.NSURLComponents
    public typealias NSURLRequest = FoundationBase.NSURLRequest
    public typealias NSMutableURLRequest = FoundationBase.NSMutableURLRequest
    public typealias NSUUID = FoundationBase.NSUUID
    public typealias NSValue = FoundationBase.NSValue
#endif

// These type aliases are used to maintain source compatibility, even though these types now live in FoundationBase now.


// Below this point are compiler intrinsics — symbols either swiftc or clang rely upon that _must_ be in the Foundation module.

#if !_runtime(_ObjC)

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

#endif // !_runtime(_ObjC)
