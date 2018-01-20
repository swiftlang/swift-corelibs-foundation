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
            return unsafeBitCast(anObj, to: NSString.self)
            
        case CFNumberGetTypeID():
            return unsafeBitCast(anObj, to: NSNumber.self)
            
        case CFURLGetTypeID():
            return unsafeBitCast(anObj, to: NSURL.self)
            
        case CFArrayGetTypeID():
            return unsafeBitCast(anObj, to: NSArray.self)
            
        case CFDictionaryGetTypeID():
            return unsafeBitCast(anObj, to: NSDictionary.self)
            
        case CFDataGetTypeID():
            return unsafeBitCast(anObj, to: NSData.self)
            
        default:
            return getFromRegistered()
        }
    }

    open func set(_ value: Any?, forKey defaultName: String) {
        guard let value = value else {
            CFPreferencesSetAppValue(defaultName._cfObject, nil, suite?._cfObject ?? kCFPreferencesCurrentApplication)
            return
        }
        
        let cfType: CFTypeRef
		
		// Convert the input value to the internal representation. All values are
        // represented as CFTypeRef objects internally because we store the defaults
        // in a CFPreferences type.
        if let bType = value as? NSNumber {
            cfType = bType._cfObject
        } else if let bType = value as? NSString {
            cfType = bType._cfObject
        } else if let bType = value as? NSArray {
            cfType = bType._cfObject
        } else if let bType = value as? NSDictionary {
            cfType = bType._cfObject
        } else if let bType = value as? NSData {
            cfType = bType._cfObject
        } else if let bType = value as? NSURL {
            set(URL(reference: bType), forKey: defaultName)
            return
        } else if let bType = value as? String {
            cfType = bType._cfObject
        } else if let bType = value as? URL {
			set(bType, forKey: defaultName)
			return
        } else if let bType = value as? Int {
            var cfValue = Int64(bType)
            cfType = CFNumberCreate(nil, kCFNumberSInt64Type, &cfValue)
        } else if let bType = value as? Double {
            var cfValue = bType
            cfType = CFNumberCreate(nil, kCFNumberDoubleType, &cfValue)
        } else if let bType = value as? Data {
            cfType = bType._cfObject
        } else {
            fatalError("The type of 'value' passed to UserDefaults.set(forKey:) is not supported.")
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
              let bVal = aVal as? NSData else {
            return nil
        }
        return Data(referencing: bVal)
    }
    open func stringArray(forKey defaultName: String) -> [String]? {
        guard let aVal = object(forKey: defaultName),
              let bVal = aVal as? NSArray else {
            return nil
        }
        return _SwiftValue.fetch(nonOptional: bVal) as? [String]
    }
    open func integer(forKey defaultName: String) -> Int {
        guard let aVal = object(forKey: defaultName) else {
            return 0
        }
        if let bVal = aVal as? NSNumber {
            return bVal.intValue
        }
        if let bVal = aVal as? NSString {
            return bVal.integerValue
        }
        return 0
    }
    open func float(forKey defaultName: String) -> Float {
        guard let aVal = object(forKey: defaultName) else {
            return 0
        }
        if let bVal = aVal as? NSNumber {
            return bVal.floatValue
        }
        if let bVal = aVal as? NSString {
            return bVal.floatValue
        }
        return 0
    }
    open func double(forKey defaultName: String) -> Double {
        guard let aVal = object(forKey: defaultName) else {
            return 0
        }
        if let bVal = aVal as? NSNumber {
            return bVal.doubleValue
        }
        if let bVal = aVal as? NSString {
            return bVal.doubleValue
        }
        return 0
    }
    open func bool(forKey defaultName: String) -> Bool {
        guard let aVal = object(forKey: defaultName) else {
            return false
        }
        if let bVal = aVal as? NSNumber {
            return bVal.boolValue
        }
        if let bVal = aVal as? NSString {
            return bVal.boolValue
        }
        return false
    }
    open func url(forKey defaultName: String) -> URL? {
        guard let aVal = object(forKey: defaultName) else {
            return nil
        }
        
        if let bVal = aVal as? NSURL {
            return URL(reference: bVal)
        } else if let bVal = aVal as? NSString {
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
            let nsValue: NSObject

            // Converts a value to the internal representation. Internalized values are
            // stored as NSObject derived objects in the registration dictionary.
            if let val = value as? String {
                nsValue = val._nsObject
            } else if let val = value as? URL {
                nsValue = val.path._nsObject
            } else if let val = value as? Int {
                nsValue = NSNumber(value: val)
            } else if let val = value as? Double {
                nsValue = NSNumber(value: val)
            } else if let val = value as? Bool {
                nsValue = NSNumber(value: val)
            } else if let val = value as? Data {
                nsValue = val._nsObject
            } else if let val = value as? NSObject {
                nsValue = val
            } else {
                fatalError("The type of 'value' passed to UserDefaults.register(defaults:) is not supported.")
            }

            registeredDefaults[key] = nsValue
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
    
    open func objectIsForced(forKey key: String) -> Bool {
        // If you're using this version of Foundation, there is nothing in particular that can force a key.
        // So:
        return false
    }
    
    open func objectIsForced(forKey key: String, inDomain domain: String) -> Bool {
        // If you're using this version of Foundation, there is nothing in particular that can force a key.
        // So:
        return false
    }
}

extension UserDefaults {
    public static let didChangeNotification = NSNotification.Name(rawValue: "NSUserDefaultsDidChangeNotification")
    public static let globalDomain: String = "NSGlobalDomain"
    public static let argumentDomain: String = "NSArgumentDomain"
    public static let registrationDomain: String = "NSRegistrationDomain"
}
