// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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
private var sharedDefaults = UserDefaults()

open class UserDefaults: NSObject {
    private let suite: String?
    
    open class func standardUserDefaults() -> UserDefaults {
        return sharedDefaults
    }
    
    open class func resetStandardUserDefaults() {
        //sharedDefaults.synchronize()
        //sharedDefaults = NSUserDefaults()
    }
    
    public convenience override init() {
        self.init(suiteName: nil)!
    }
    
    /// nil suite means use the default search list that +standardUserDefaults uses
    public init?(suiteName suitename: String?) {
        suite = suitename
    }
    
    open func objectForKey(_ defaultName: String) -> AnyObject? {
        func getFromRegistered() -> AnyObject? {
            return registeredDefaults[defaultName]
        }
        
        guard let anObj = CFPreferencesCopyAppValue(defaultName._cfObject, suite?._cfObject ?? kCFPreferencesCurrentApplication) else {
            return getFromRegistered()
        }
        
        //Force the returned value to an NSObject
        switch CFGetTypeID(anObj) {
        case CFStringGetTypeID():
            return (anObj as! CFString)._nsObject
            
        case CFNumberGetTypeID():
            return (anObj as! CFNumber)._nsObject
            
        case CFURLGetTypeID():
            return (anObj as! CFURL)._nsObject
            
        case CFArrayGetTypeID():
            return (anObj as! CFArray)._nsObject
            
        case CFDictionaryGetTypeID():
            return (anObj as! CFDictionary)._nsObject

        case CFDataGetTypeID():
            return (anObj as! CFData)._nsObject
            
        default:
            return getFromRegistered()
        }
    }
    open func setObject(_ value: AnyObject?, forKey defaultName: String) {
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
        } else if let bType = value as? URL {
			setURL(bType, forKey: defaultName)
			return
        } else if let bType = value as? Data {
            cfType = bType._cfObject
        }
        
        CFPreferencesSetAppValue(defaultName._cfObject, cfType, suite?._cfObject ?? kCFPreferencesCurrentApplication)
    }
    open func removeObjectForKey(_ defaultName: String) {
        CFPreferencesSetAppValue(defaultName._cfObject, nil, suite?._cfObject ?? kCFPreferencesCurrentApplication)
    }
    
    open func stringForKey(_ defaultName: String) -> String? {
        guard let aVal = objectForKey(defaultName),
              let bVal = aVal as? NSString else {
            return nil
        }
        return bVal._swiftObject
    }
    open func arrayForKey(_ defaultName: String) -> [AnyObject]? {
        guard let aVal = objectForKey(defaultName),
              let bVal = aVal as? NSArray else {
            return nil
        }
        return bVal._swiftObject
    }
    open func dictionaryForKey(_ defaultName: String) -> [String : AnyObject]? {
        guard let aVal = objectForKey(defaultName),
              let bVal = aVal as? NSDictionary else {
            return nil
        }
        //This got out of hand fast...
        let cVal = bVal._swiftObject
        enum convErr: Swift.Error {
            case convErr
        }
        do {
            let dVal = try cVal.map({ (key, val) -> (String, AnyObject) in
                if let strKey = key as? NSString {
                    return (strKey._swiftObject, val)
                } else {
                    throw convErr.convErr
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
    open func dataForKey(_ defaultName: String) -> Data? {
        guard let aVal = objectForKey(defaultName),
              let bVal = aVal as? Data else {
            return nil
        }
        return bVal
    }
    open func stringArrayForKey(_ defaultName: String) -> [String]? {
        guard let aVal = objectForKey(defaultName),
              let bVal = aVal as? NSArray else {
            return nil
        }
        return _expensivePropertyListConversion(bVal) as? [String]
    }
    open func integerForKey(_ defaultName: String) -> Int {
        guard let aVal = objectForKey(defaultName),
              let bVal = aVal as? NSNumber else {
            return 0
        }
        return bVal.intValue
    }
    open func floatForKey(_ defaultName: String) -> Float {
        guard let aVal = objectForKey(defaultName),
              let bVal = aVal as? NSNumber else {
            return 0
        }
        return bVal.floatValue
    }
    open func doubleForKey(_ defaultName: String) -> Double {
        guard let aVal = objectForKey(defaultName),
              let bVal = aVal as? NSNumber else {
            return 0
        }
        return bVal.doubleValue
    }
    open func boolForKey(_ defaultName: String) -> Bool {
        guard let aVal = objectForKey(defaultName),
              let bVal = aVal as? NSNumber else {
            return false
        }
        return bVal.boolValue
    }
    open func URLForKey(_ defaultName: String) -> URL? {
        guard let aVal = objectForKey(defaultName) else {
            return nil
        }
        
        if let bVal = aVal as? NSString {
            let cVal = bVal.stringByExpandingTildeInPath
            
            return URL(fileURLWithPath: cVal)
        } else if let bVal = aVal as? Data {
            return NSKeyedUnarchiver.unarchiveObjectWithData(bVal) as? URL
        }
        
        return nil
    }
    
    open func setInteger(_ value: Int, forKey defaultName: String) {
        setObject(NSNumber(value: value), forKey: defaultName)
    }
    open func setFloat(_ value: Float, forKey defaultName: String) {
        setObject(NSNumber(value: value), forKey: defaultName)
    }
    open func setDouble(_ value: Double, forKey defaultName: String) {
        setObject(NSNumber(value: value), forKey: defaultName)
    }
    open func setBool(_ value: Bool, forKey defaultName: String) {
        setObject(NSNumber(value: value), forKey: defaultName)
    }
    open func setURL(_ url: URL?, forKey defaultName: String) {
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
            let data = NSKeyedArchiver.archivedData(withRootObject: url._nsObject)
            setObject(data._nsObject, forKey: defaultName)
        } else {
            setObject(nil, forKey: defaultName)
        }
    }
    
    open func registerDefaults(_ registrationDictionary: [String : AnyObject]) {
        for (key, value) in registrationDictionary {
            registeredDefaults[key] = value
        }
    }
    
    open func addSuiteNamed(_ suiteName: String) {
        CFPreferencesAddSuitePreferencesToApp(kCFPreferencesCurrentApplication, suiteName._cfObject)
    }
    open func removeSuiteNamed(_ suiteName: String) {
        CFPreferencesRemoveSuitePreferencesFromApp(kCFPreferencesCurrentApplication, suiteName._cfObject)
    }
    
    open func dictionaryRepresentation() -> [String : AnyObject] {
        NSUnimplemented()
        /*
        Currently crashes the compiler.
        guard let aPref = CFPreferencesCopyMultiple(nil, kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost),
            bPref = (aPref._swiftObject) as? [NSString: AnyObject] else {
                return registeredDefaults
        }
        var allDefaults = registeredDefaults
        
        for (key, value) in bPref {
            allDefaults[key._swiftObject] = value
        }
        
        return allDefaults
        */
    }
    
    open var volatileDomainNames: [String] { NSUnimplemented() }
    open func volatileDomainForName(_ domainName: String) -> [String : AnyObject] { NSUnimplemented() }
    open func setVolatileDomain(_ domain: [String : AnyObject], forName domainName: String) { NSUnimplemented() }
    open func removeVolatileDomainForName(_ domainName: String) { NSUnimplemented() }
    
    open func persistentDomainForName(_ domainName: String) -> [String : AnyObject]? { NSUnimplemented() }
    open func setPersistentDomain(_ domain: [String : AnyObject], forName domainName: String) { NSUnimplemented() }
    open func removePersistentDomainForName(_ domainName: String) { NSUnimplemented() }
    
    open func synchronize() -> Bool {
        return CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
    
    open func objectIsForcedForKey(_ key: String) -> Bool { NSUnimplemented() }
    open func objectIsForcedForKey(_ key: String, inDomain domain: String) -> Bool { NSUnimplemented() }
}

public let NSUserDefaultsDidChangeNotification: String = "NSUserDefaultsDidChangeNotification"

