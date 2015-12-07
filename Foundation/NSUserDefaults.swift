// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public let NSGlobalDomain: String = "NSGlobalDomain"
public let NSArgumentDomain: String = "NSArgumentDomain"
public let NSRegistrationDomain: String = "NSRegistrationDomain"

public class NSUserDefaults : NSObject {
    
    public class func standardUserDefaults() -> NSUserDefaults { NSUnimplemented() }
    public class func resetStandardUserDefaults() { NSUnimplemented() }
    
    public convenience override init() { NSUnimplemented() }
    public init?(suiteName suitename: String?)  { NSUnimplemented() } //nil suite means use the default search list that +standardUserDefaults uses
    
    public func objectForKey(defaultName: String) -> AnyObject? { NSUnimplemented() }
    public func setObject(value: AnyObject?, forKey defaultName: String) { NSUnimplemented() }
    public func removeObjectForKey(defaultName: String) { NSUnimplemented() }
    
    public func stringForKey(defaultName: String) -> String? { NSUnimplemented() }
    public func arrayForKey(defaultName: String) -> [AnyObject]? { NSUnimplemented() }
    public func dictionaryForKey(defaultName: String) -> [String : AnyObject]? { NSUnimplemented() }
    public func dataForKey(defaultName: String) -> NSData? { NSUnimplemented() }
    public func stringArrayForKey(defaultName: String) -> [String]? { NSUnimplemented() }
    public func integerForKey(defaultName: String) -> Int { NSUnimplemented() }
    public func floatForKey(defaultName: String) -> Float { NSUnimplemented() }
    public func doubleForKey(defaultName: String) -> Double { NSUnimplemented() }
    public func boolForKey(defaultName: String) -> Bool { NSUnimplemented() }
    public func URLForKey(defaultName: String) -> NSURL? { NSUnimplemented() }
    
    public func setInteger(value: Int, forKey defaultName: String) { NSUnimplemented() }
    public func setFloat(value: Float, forKey defaultName: String) { NSUnimplemented() }
    public func setDouble(value: Double, forKey defaultName: String) { NSUnimplemented() }
    public func setBool(value: Bool, forKey defaultName: String) { NSUnimplemented() }
    public func setURL(url: NSURL?, forKey defaultName: String) { NSUnimplemented() }
    
    public func registerDefaults(registrationDictionary: [String : AnyObject]) { NSUnimplemented() }
    
    public func addSuiteNamed(suiteName: String) { NSUnimplemented() }
    public func removeSuiteNamed(suiteName: String) { NSUnimplemented() }
    
    public func dictionaryRepresentation() -> [String : AnyObject] { NSUnimplemented() }
    
    public var volatileDomainNames: [String] { NSUnimplemented() }
    public func volatileDomainForName(domainName: String) -> [String : AnyObject] { NSUnimplemented() }
    public func setVolatileDomain(domain: [String : AnyObject], forName domainName: String) { NSUnimplemented() }
    public func removeVolatileDomainForName(domainName: String) { NSUnimplemented() }
    
    public func persistentDomainForName(domainName: String) -> [String : AnyObject]? { NSUnimplemented() }
    public func setPersistentDomain(domain: [String : AnyObject], forName domainName: String) { NSUnimplemented() }
    public func removePersistentDomainForName(domainName: String) { NSUnimplemented() }
    
    public func synchronize() -> Bool { NSUnimplemented() }
    
    public func objectIsForcedForKey(key: String) -> Bool { NSUnimplemented() }
    public func objectIsForcedForKey(key: String, inDomain domain: String) -> Bool { NSUnimplemented() }
}

public let NSUserDefaultsDidChangeNotification: String = "NSUserDefaultsDidChangeNotification"

