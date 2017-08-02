// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

private var registeredDefaults = [String: Any]()
private var sharedDefaults = UserDefaults()

open class UserDefaults: NSObject {
    private let suite: String?
    
    open class var standard: UserDefaults {
        return sharedDefaults
    }
    
    open class func resetStandardUserDefaults() {
        //sharedDefaults.synchronize()
        //sharedDefaults = UserDefaults()
    }
    
    public convenience override init() {
        self.init(suiteName: nil)!
    }
    
    /// nil suite means use the default search list that +standardUserDefaults uses
    public init?(suiteName suitename: String?) {
        suite = suitename
    }
    
    open func object(forKey defaultName: String) -> Any? {
        func getFromRegistered() -> Any? {
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
    open func set(_ value: Any?, forKey defaultName: String) {
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
			set(bType, forKey: defaultName)
			return
        } else if let bType = value as? Data {
            cfType = bType._cfObject
        }
        
        CFPreferencesSetAppValue(defaultName._cfObject, cfType, suite?._cfObject ?? kCFPreferencesCurrentApplication)
    }
    open func removeObject(forKey defaultName: String) {
        CFPreferencesSetAppValue(defaultName._cfObject, nil, suite?._cfObject ?? kCFPreferencesCurrentApplication)
    }
    open func string(forKey defaultName: String) -> String? {
        guard let aVal = object(forKey: defaultName),
              let bVal = aVal as? NSString else {
            return nil
        }
        return bVal._swiftObject
    }
    open func array(forKey defaultName: String) -> [Any]? {
        guard let aVal = object(forKey: defaultName),
              let bVal = aVal as? NSArray else {
            return nil
        }
        return bVal._swiftObject
    }
    open func dictionary(forKey defaultName: String) -> [String : Any]? {
        guard let aVal = object(forKey: defaultName),
              let bVal = aVal as? NSDictionary else {
            return nil
        }
        //This got out of hand fast...
        let cVal = bVal._swiftObject
        enum convErr: Swift.Error {
            case convErr
        }
        do {
            let dVal = try cVal.map({ (key, val) -> (String, Any) in
                if let strKey = key as? NSString {
                    return (strKey._swiftObject, val)
                } else {
                    throw convErr.convErr
                }
            })
            var eVal = [String : Any]()
            
            for (key, value) in dVal {
                eVal[key] = value
            }
            
            return eVal
        } catch _ { }
        return nil
    }
    open func data(forKey defaultName: String) -> Data? {
        guard let aVal = object(forKey: defaultName),
              let bVal = aVal as? Data else {
            return nil
        }
        return bVal
    }
    open func stringArray(forKey defaultName: String) -> [String]? {
        guard let aVal = object(forKey: defaultName),
              let bVal = aVal as? NSArray else {
            return nil
        }
        return _SwiftValue.fetch(nonOptional: bVal) as? [String]
    }
    open func integer(forKey defaultName: String) -> Int {
        guard let aVal = object(forKey: defaultName),
              let bVal = aVal as? NSNumber else {
            return 0
        }
        return bVal.intValue
    }
    open func float(forKey defaultName: String) -> Float {
        guard let aVal = object(forKey: defaultName),
              let bVal = aVal as? NSNumber else {
            return 0
        }
        return bVal.floatValue
    }
    open func double(forKey defaultName: String) -> Double {
        guard let aVal = object(forKey: defaultName),
              let bVal = aVal as? NSNumber else {
            return 0
        }
        return bVal.doubleValue
    }
    open func bool(forKey defaultName: String) -> Bool {
        guard let aVal = object(forKey: defaultName),
              let bVal = aVal as? NSNumber else {
            return false
        }
        return bVal.boolValue
    }
    open func url(forKey defaultName: String) -> URL? {
        guard let aVal = object(forKey: defaultName) else {
            return nil
        }
        
        if let bVal = aVal as? NSString {
            let cVal = bVal.expandingTildeInPath
            
            return URL(fileURLWithPath: cVal)
        } else if let bVal = aVal as? Data {
            return NSKeyedUnarchiver.unarchiveObject(with: bVal) as? URL
        }
        return nil
    }
    
    open func set(_ value: Int, forKey defaultName: String) {
        set(NSNumber(value: value), forKey: defaultName)
    }
    open func set(_ value: Float, forKey defaultName: String) {
        set(NSNumber(value: value), forKey: defaultName)
    }
    open func set(_ value: Double, forKey defaultName: String) {
        set(NSNumber(value: value), forKey: defaultName)
    }
    open func set(_ value: Bool, forKey defaultName: String) {
        set(NSNumber(value: value), forKey: defaultName)
    }
    open func set(_ url: URL?, forKey defaultName: String) {
		if let url = url {
            //FIXME: CFURLIsFileReferenceURL is limited to OS X/iOS
            #if os(OSX) || os(iOS)
                //FIXME: no SwiftFoundation version of CFURLIsFileReferenceURL at time of writing!
                if CFURLIsFileReferenceURL(url._cfObject) {
                    let data = NSKeyedArchiver.archivedData(withRootObject: url._nsObject)
                    set(data._nsObject, forKey: defaultName)
                    return
                }
            #endif
            
            set(url.path._nsObject, forKey: defaultName)
        } else {
            set(nil, forKey: defaultName)
        }
    }
    
    open func register(defaults registrationDictionary: [String : Any]) {
        for (key, value) in registrationDictionary {
            registeredDefaults[key] = value
        }
    }
    
    open func addSuite(named suiteName: String) {
        CFPreferencesAddSuitePreferencesToApp(kCFPreferencesCurrentApplication, suiteName._cfObject)
    }
    open func removeSuite(named suiteName: String) {
        CFPreferencesRemoveSuitePreferencesFromApp(kCFPreferencesCurrentApplication, suiteName._cfObject)
    }
    
    open func dictionaryRepresentation() -> [String : Any] {
        guard let aPref = CFPreferencesCopyMultiple(nil, kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost),
            let bPref = (aPref._swiftObject) as? [NSString: Any] else {
                return registeredDefaults
        }
        var allDefaults = registeredDefaults
        
        for (key, value) in bPref {
            allDefaults[key._swiftObject] = value
        }
        
        return allDefaults
    }
    
    open var volatileDomainNames: [String] { NSUnimplemented() }
    open func volatileDomain(forName domainName: String) -> [String : Any] { NSUnimplemented() }
    open func setVolatileDomain(_ domain: [String : Any], forName domainName: String) { NSUnimplemented() }
    open func removeVolatileDomain(forName domainName: String) { NSUnimplemented() }
    
    open func persistentDomain(forName domainName: String) -> [String : Any]? { NSUnimplemented() }
    open func setPersistentDomain(_ domain: [String : Any], forName domainName: String) { NSUnimplemented() }
    open func removePersistentDomain(forName domainName: String) { NSUnimplemented() }
    
    open func synchronize() -> Bool {
        return CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }
    
    open func objectIsForced(forKey key: String) -> Bool { NSUnimplemented() }
    open func objectIsForced(forKey key: String, inDomain domain: String) -> Bool { NSUnimplemented() }
}

extension UserDefaults {
    public static let didChangeNotification = NSNotification.Name(rawValue: "NSUserDefaultsDidChangeNotification")
    public static let globalDomain: String = "NSGlobalDomain"
    public static let argumentDomain: String = "NSArgumentDomain"
    public static let registrationDomain: String = "NSRegistrationDomain"
}
