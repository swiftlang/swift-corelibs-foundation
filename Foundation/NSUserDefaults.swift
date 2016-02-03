// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public let NSGlobalDomain: String = "NSGlobalDomain"
public let NSArgumentDomain: String = "NSArgumentDomain"
public let NSRegistrationDomain: String = "NSRegistrationDomain"

private var registeredDefaults = [String: AnyObject]()
private var sharedDefaults = NSUserDefaults()

public class NSUserDefaults : NSObject {
    private let suite: String?
    
    public class func standardUserDefaults() -> NSUserDefaults {
        return sharedDefaults
    }
    
    public class func resetStandardUserDefaults() {
        sharedDefaults.synchronize()
        sharedDefaults = NSUserDefaults()
    }
    
    public convenience override init() {
        self.init(suiteName: nil)!
    }
    
    /// nil suite means use the default search list that +standardUserDefaults uses
    public init?(suiteName suitename: String?) {
        suite = suitename
    }
    
    public func objectForKey(defaultName: String) -> AnyObject? {
        func getFromRegistered() -> AnyObject? {
            return registeredDefaults[defaultName]
        }
        
        guard let anObj = CFPreferencesCopyAppValue(defaultName._cfObject, suite?._cfObject ?? kCFPreferencesCurrentApplication) else {
            return getFromRegistered()
        }
        
        //Force the returned value to an NSObject
        switch CFGetTypeID(anObj) {
        case CFStringGetTypeID():
            return (anObj as! CFStringRef)._nsObject
            
        case CFNumberGetTypeID():
            return (anObj as! CFNumberRef)._nsObject
            
        case CFURLGetTypeID():
            return (anObj as! CFURLRef)._nsObject
            
        case CFArrayGetTypeID():
            return (anObj as! CFArrayRef)._nsObject
            
        case CFDictionaryGetTypeID():
            return (anObj as! CFDictionaryRef)._nsObject

        case CFDataGetTypeID():
            return (anObj as! CFDataRef)._nsObject
            
        default:
            return getFromRegistered()
        }
    }
    public func setObject(value: AnyObject?, forKey defaultName: String) {
        guard let value = value else {
            CFPreferencesSetAppValue(defaultName._cfObject, nil, suite?._cfObject ?? kCFPreferencesCurrentApplication)
            return
        }
        
        var cfType: CFTypeRef? = nil
		
		//FIXME: is this needed? Am I overcomplicating things?
        //Foundation types
        if let bType = value as? NSNumber {
            cfType = bType._cfObject
        } else if let bType = value as? NSString {
            cfType = bType._cfObject
        } else if let bType = value as? NSArray {
            cfType = bType._cfObject
        } else if let bType = value as? NSDictionary {
            cfType = bType._cfObject
        } else if let bType = value as? NSURL {
			setURL(bType, forKey: defaultName)
			return
        } else if let bType = value as? NSData {
            cfType = bType._cfObject
            //Swift types
        } else if let bType = value as? String {
            cfType = bType._cfObject
        } else if let bType = value as? Int {
            cfType = NSNumber(integer: bType)._cfObject
        } else if let bType = value as? UInt {
            cfType = NSNumber(unsignedInteger: bType)._cfObject
        } else if let bType = value as? Int32 {
            cfType = NSNumber(int: bType)._cfObject
        } else if let bType = value as? UInt32 {
            cfType = NSNumber(unsignedInt: bType)._cfObject
        } else if let bType = value as? Int64 {
            cfType = NSNumber(longLong: bType)._cfObject
        } else if let bType = value as? UInt64 {
            cfType = NSNumber(unsignedLongLong: bType)._cfObject
        } else if let bType = value as? Bool {
            cfType = NSNumber(bool: bType)._cfObject
        } else if let bType = value as? [NSObject: AnyObject] {
            cfType = bType._cfObject
        } else if let bType = value as? [String: AnyObject] {
            cfType = bType.map({ (str, obj) -> (NSString, AnyObject) in
                return (str._nsObject, obj)
            })._cfObject
        } else if let bType = value as? [AnyObject] {
            cfType = bType._cfObject
        } else if let bType = value as? [String] {
            cfType = bType.map({ (aStr) -> NSString in
                return aStr._nsObject
            })._cfObject
        }
        
        CFPreferencesSetAppValue(defaultName._cfObject, cfType, suite?._cfObject ?? kCFPreferencesCurrentApplication)
    }
    public func removeObjectForKey(defaultName: String) {
        CFPreferencesSetAppValue(defaultName._cfObject, nil, suite?._cfObject ?? kCFPreferencesCurrentApplication)
    }
    
    public func stringForKey(defaultName: String) -> String? {
        guard let aVal = objectForKey(defaultName), bVal = aVal as? NSString else {
            return nil
        }
        return bVal._swiftObject
    }
    public func arrayForKey(defaultName: String) -> [AnyObject]? {
        guard let aVal = objectForKey(defaultName), bVal = aVal as? NSArray else {
            return nil
        }
        return bVal._swiftObject
    }
    public func dictionaryForKey(defaultName: String) -> [String : AnyObject]? {
        guard let aVal = objectForKey(defaultName), bVal = aVal as? NSDictionary else {
            return nil
        }
        //This got out of hand fast...
        let cVal = bVal._swiftObject
        enum convErr: ErrorType {
            case ConvErr
        }
        do {
            let dVal = try cVal.map({ (key, val) -> (String, AnyObject) in
                if let strKey = key as? NSString {
                    return (strKey._swiftObject, val)
                } else {
                    throw convErr.ConvErr
                }
            })
            var eVal = [String : AnyObject]()
            
            for (key, value) in dVal {
                eVal[key] = value
            }
            
            return eVal
        } catch _ { }
        return nil
    }
    public func dataForKey(defaultName: String) -> NSData? {
        guard let aVal = objectForKey(defaultName), bVal = aVal as? NSData else {
            return nil
        }
        return bVal
    }
    public func stringArrayForKey(defaultName: String) -> [String]? {
        guard let aVal = objectForKey(defaultName), bVal = aVal as? NSArray else {
            return nil
        }
        return (bVal._swiftObject as? [NSString])?.map({ return $0._swiftObject})
    }
    public func integerForKey(defaultName: String) -> Int {
        guard let aVal = objectForKey(defaultName), bVal = aVal as? NSNumber else {
            return 0
        }
        return bVal.integerValue
    }
    public func floatForKey(defaultName: String) -> Float {
        guard let aVal = objectForKey(defaultName), bVal = aVal as? NSNumber else {
            return 0
        }
        return bVal.floatValue
    }
    public func doubleForKey(defaultName: String) -> Double {
        guard let aVal = objectForKey(defaultName), bVal = aVal as? NSNumber else {
            return 0
        }
        return bVal.doubleValue
    }
    public func boolForKey(defaultName: String) -> Bool {
        guard let aVal = objectForKey(defaultName), bVal = aVal as? NSNumber else {
            return false
        }
        return bVal.boolValue
    }
    public func URLForKey(defaultName: String) -> NSURL? {
        guard let aVal = objectForKey(defaultName) else {
            return nil
        }
        
        if let bVal = aVal as? NSString {
            let cVal = bVal.stringByExpandingTildeInPath
            
            return NSURL(fileURLWithPath: cVal)
        } else if let bVal = aVal as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(bVal) as? NSURL
        }
        
        return nil
    }
    
    public func setInteger(value: Int, forKey defaultName: String) {
        setObject(NSNumber(integer: value), forKey: defaultName)
    }
    public func setFloat(value: Float, forKey defaultName: String) {
        setObject(NSNumber(float: value), forKey: defaultName)
    }
    public func setDouble(value: Double, forKey defaultName: String) {
        setObject(NSNumber(double: value), forKey: defaultName)
    }
    public func setBool(value: Bool, forKey defaultName: String) {
        setObject(NSNumber(bool: value), forKey: defaultName)
    }
    public func setURL(url: NSURL?, forKey defaultName: String) {
		if let url = url {
            //FIXME: CFURLIsFileReferenceURL is limited to OS X/iOS
            #if os(OSX) || os(iOS)
                //FIXME: no SwiftFoundation version of CFURLIsFileReferenceURL at time of writing!
                if !CFURLIsFileReferenceURL(url._cfObject) {
                    //FIXME: stringByAbbreviatingWithTildeInPath isn't implemented in SwiftFoundation
                    //TODO: use stringByAbbreviatingWithTildeInPath when it is
                    let urlPath = url.path!
                    
                    setObject(urlPath._nsObject, forKey: defaultName)
                    return
                }
            #else
                if let urlPath = url.path {
                    //FIXME: stringByAbbreviatingWithTildeInPath isn't implemented in SwiftFoundation
                    //TODO: use stringByAbbreviatingWithTildeInPath when it is
                    setObject(urlPath._nsObject, forKey: defaultName)
                    return
                }
            #endif
            let data = NSKeyedArchiver.archivedDataWithRootObject(url)
            setObject(data, forKey: defaultName)
        } else {
            setObject(nil, forKey: defaultName)
        }
    }
    
    public func registerDefaults(registrationDictionary: [String : AnyObject]) {
        for (key, value) in registrationDictionary {
            registeredDefaults[key] = value
        }
    }
    
    public func addSuiteNamed(suiteName: String) {
        CFPreferencesAddSuitePreferencesToApp(kCFPreferencesCurrentApplication, suiteName._cfObject)
    }
    public func removeSuiteNamed(suiteName: String) {
        CFPreferencesRemoveSuitePreferencesFromApp(kCFPreferencesCurrentApplication, suiteName._cfObject)
    }
    
    public func dictionaryRepresentation() -> [String : AnyObject] {
        guard let aPref = CFPreferencesCopyMultiple(nil, kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost),
            bPref = (aPref._swiftObject) as? [NSString: AnyObject] else {
                return registeredDefaults
        }
        var allDefaults = registeredDefaults
        
        for (key, value) in bPref {
            allDefaults[key._swiftObject] = value
        }
        
        return allDefaults
    }
    
    public var volatileDomainNames: [String] { NSUnimplemented() }
    public func volatileDomainForName(domainName: String) -> [String : AnyObject] { NSUnimplemented() }
    public func setVolatileDomain(domain: [String : AnyObject], forName domainName: String) { NSUnimplemented() }
    public func removeVolatileDomainForName(domainName: String) { NSUnimplemented() }
    
    public func persistentDomainForName(domainName: String) -> [String : AnyObject]? { NSUnimplemented() }
    public func setPersistentDomain(domain: [String : AnyObject], forName domainName: String) { NSUnimplemented() }
    public func removePersistentDomainForName(domainName: String) { NSUnimplemented() }
    
    public func synchronize() -> Bool {
        return CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
    
    public func objectIsForcedForKey(key: String) -> Bool { NSUnimplemented() }
    public func objectIsForcedForKey(key: String, inDomain domain: String) -> Bool { NSUnimplemented() }
}

public let NSUserDefaultsDidChangeNotification: String = "NSUserDefaultsDidChangeNotification"

