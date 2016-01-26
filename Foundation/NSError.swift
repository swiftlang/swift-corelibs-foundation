// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

public let NSCocoaErrorDomain: String = "NSCocoaErrorDomain"

public let NSPOSIXErrorDomain: String = "NSPOSIXErrorDomain"
public let NSOSStatusErrorDomain: String = "NSOSStatusErrorDomain"
public let NSMachErrorDomain: String = "NSMachErrorDomain"

public let NSUnderlyingErrorKey: String = "NSUnderlyingError"

public let NSLocalizedDescriptionKey: String = "NSLocalizedDescription"
public let NSLocalizedFailureReasonErrorKey: String = "NSLocalizedFailureReason"
public let NSLocalizedRecoverySuggestionErrorKey: String = "NSLocalizedRecoverySuggestion"
public let NSLocalizedRecoveryOptionsErrorKey: String = "NSLocalizedRecoveryOptions"
public let NSRecoveryAttempterErrorKey: String = "NSRecoveryAttempter"
public let NSHelpAnchorErrorKey: String = "NSHelpAnchor"

public let NSStringEncodingErrorKey: String = "NSStringEncodingErrorKey"
public let NSURLErrorKey: String = "NSURL"
public let NSFilePathErrorKey: String = "NSFilePathErrorKey"


public class NSError : NSObject, NSCopying, NSSecureCoding, NSCoding {
    typealias CFType = CFErrorRef
    
    internal var _cfObject: CFType {
        return CFErrorCreate(kCFAllocatorSystemDefault, domain._cfObject, code, nil)
    }
    
    // ErrorType forbids this being internal
    public var _domain: String
    public var _code: Int
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: This API differs from Darwin because it uses [String : Any] as a type instead of [String : AnyObject]. This allows the use of Swift value types.
    private var _userInfo: [String : Any]?
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: This API differs from Darwin because it uses [String : Any] as a type instead of [String : AnyObject]. This allows the use of Swift value types.
    public init(domain: String, code: Int, userInfo dict: [String : Any]?) {
        _domain = domain
        _code = code
        _userInfo = dict
    }
    
    public required init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            _code = aDecoder.decodeIntegerForKey("NSCode")
            _domain = aDecoder.decodeObjectOfClass(NSString.self, forKey: "NSDomain")!._swiftObject
            if let info = aDecoder.decodeObjectOfClasses([NSSet.self, NSDictionary.self, NSArray.self, NSString.self, NSNumber.self, NSData.self, NSURL.self], forKey: "NSUserInfo") as? NSDictionary {
                var filteredUserInfo = [String : Any]()
                // user info must be filtered so that the keys are all strings
                info.enumerateKeysAndObjectsUsingBlock() {
                    if let key = $0.0 as? NSString {
                        filteredUserInfo[key._swiftObject] = $0.1
                    }
                }
                _userInfo = filteredUserInfo
            }
        } else {
            var codeValue: Int32 = 0
            aDecoder.decodeValueOfObjCType("i", at: &codeValue)
            _code = Int(codeValue)
            _domain = (aDecoder.decodeObject() as? NSString)!._swiftObject
            if let info = aDecoder.decodeObject() as? NSDictionary {
                var filteredUserInfo = [String : Any]()
                // user info must be filtered so that the keys are all strings
                info.enumerateKeysAndObjectsUsingBlock() {
                    if let key = $0.0 as? NSString {
                        filteredUserInfo[key._swiftObject] = $0.1
                    }
                }
                _userInfo = filteredUserInfo
            }
        }
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        if aCoder.allowsKeyedCoding {
            aCoder.encodeObject(_domain.bridge(), forKey: "NSDomain")
            aCoder.encodeInt(Int32(_code), forKey: "NSCode")
            aCoder.encodeObject(_userInfo?.bridge(), forKey: "NSUserInfo")
        } else {
            var codeValue: Int32 = Int32(self._code)
            aCoder.encodeValueOfObjCType("i", at: &codeValue)
            aCoder.encodeObject(self._domain.bridge())
            aCoder.encodeObject(self._userInfo?.bridge())
        }
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public var domain: String {
        return _domain
    }
    
    public var code: Int {
        return _code
    }

    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: This API differs from Darwin because it uses [String : Any] as a type instead of [String : AnyObject]. This allows the use of Swift value types.
    public var userInfo: [String : Any] {
        if let info = _userInfo {
            return info
        } else {
            return Dictionary<String, Any>()
        }
    }
    
    public var localizedDescription: String {
        let desc = userInfo[NSLocalizedDescriptionKey] as? String
        
        return desc ?? "The operation could not be completed"
    }
    
    public var localizedFailureReason: String? {
        return userInfo[NSLocalizedFailureReasonErrorKey] as? String
    }
    
    public var localizedRecoverySuggestion: String? {
        return userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String
    }

    public var localizedRecoveryOptions: [String]? {
        return userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String]
    }
    
    public var recoveryAttempter: AnyObject? {
        return userInfo[NSRecoveryAttempterErrorKey] as? AnyObject
    }
    
    public var helpAnchor: String? {
        return userInfo[NSHelpAnchorErrorKey] as? String
    }
    
    internal typealias NSErrorProvider = (error: NSError, key: String) -> AnyObject?
    internal static var userInfoProviders = [String: NSErrorProvider]()
    
    public class func setUserInfoValueProviderForDomain(errorDomain: String, provider: ((NSError, String) -> AnyObject?)?) {
        NSError.userInfoProviders[errorDomain] = provider
    }

    public class func userInfoValueProviderForDomain(errorDomain: String) -> ((NSError, String) -> AnyObject?)? {
        return NSError.userInfoProviders[errorDomain]
    }
}

extension NSError : ErrorType { }

extension NSError : _CFBridgable { }
extension CFErrorRef : _NSBridgable {
    typealias NSType = NSError
    internal var _nsObject: NSType {
        let userInfo = CFErrorCopyUserInfo(self)._swiftObject
        var newUserInfo: [String: Any] = [:]
        for (key, value) in userInfo {
            if let key = key as? NSString {
                newUserInfo[key._swiftObject] = value
            }
        }

        return NSError(domain: CFErrorGetDomain(self)._swiftObject, code: CFErrorGetCode(self), userInfo: newUserInfo)
    }
}


public protocol _ObjectTypeBridgeableErrorType : ErrorType {
    init?(_bridgedNSError: NSError)
}

public protocol __BridgedNSError : RawRepresentable, ErrorType {
    static var __NSErrorDomain: String { get }
}

@warn_unused_result
public func ==<T: __BridgedNSError where T.RawValue: SignedIntegerType>(lhs: T, rhs: T) -> Bool {
    return lhs.rawValue.toIntMax() == rhs.rawValue.toIntMax()
}

public extension __BridgedNSError where RawValue: SignedIntegerType {
    public final var _domain: String { return Self.__NSErrorDomain }
    public final var _code: Int { return Int(rawValue.toIntMax()) }
    
    public init?(rawValue: RawValue) {
        self = unsafeBitCast(rawValue, Self.self)
    }
    
    public init?(_bridgedNSError: NSError) {
        if _bridgedNSError.domain != Self.__NSErrorDomain {
            return nil
        }
        
        self.init(rawValue: RawValue(IntMax(_bridgedNSError.code)))
    }
    
    public final var hashValue: Int { return _code }
}

@warn_unused_result
public func ==<T: __BridgedNSError where T.RawValue: UnsignedIntegerType>(lhs: T, rhs: T) -> Bool {
    return lhs.rawValue.toUIntMax() == rhs.rawValue.toUIntMax()
}

public extension __BridgedNSError where RawValue: UnsignedIntegerType {
    public final var _domain: String { return Self.__NSErrorDomain }
    public final var _code: Int {
        return Int(bitPattern: UInt(rawValue.toUIntMax()))
    }
    
    public init?(rawValue: RawValue) {
        self = unsafeBitCast(rawValue, Self.self)
    }
    
    public init?(_bridgedNSError: NSError) {
        if _bridgedNSError.domain != Self.__NSErrorDomain {
            return nil
        }
        
        self.init(rawValue: RawValue(UIntMax(UInt(_bridgedNSError.code))))
    }
    
    public final var hashValue: Int { return _code }
}

public protocol _BridgedNSError : __BridgedNSError, Hashable {
    // TODO: Was _NSErrorDomain, but that caused a module error.
    static var __NSErrorDomain: String { get }
}
