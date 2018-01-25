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
    static private func _isValueAllowed(_ nonbridgedValue: Any) -> Bool {
        let value = _SwiftValue.fetch(nonOptional: nonbridgedValue as AnyObject)
        
        if let value = value as? [Any] {
            for innerValue in value {
                if !_isValueAllowed(innerValue) {
                    return false
                }
            }
            
            return true
        }
        
        if let value = value as? [AnyHashable: Any] {
            for (key, innerValue) in value {
                if !(key is String) {
                    return false
                }
                
                if !_isValueAllowed(innerValue) {
                    return false
                }
            }
            
            return true
        }
        
        // NSNumber doesn't quite bridge -- treat it specially.
        if value is NSNumber {
            return true
        }
        
        let isOfCommonTypes =  value is String || value is Data || value is Date || value is Int || value is Bool || value is CGFloat
        if isOfCommonTypes {
            return true
        }
        
        let isOfUncommonNumericTypes = value is Double || value is Float || value is Float || value is Int8 || value is UInt8 || value is Int16 || value is UInt16 || value is Int32 || value is UInt32 || value is Int64 || value is UInt64
        return isOfUncommonNumericTypes
    }
    
    static private func _unboxingNSNumbers(_ value: Any?) -> Any? {
        if value == nil {
            return nil
        }
        
        if let number = value as? NSNumber {
            return number._swiftValueOfOptimalType
        }
        
        if let value = value as? [Any] {
            return value.map(_unboxingNSNumbers)
        }
        
        if let value = value as? [AnyHashable: Any] {
            return value.mapValues(_unboxingNSNumbers)
        }
        
        return value
    }
    
    private let suite: String?
    
    open class var standard: UserDefaults {
        return sharedDefaults
    }
    
    open class func resetStandardUserDefaults() {}
    
    public convenience override init() {
        self.init(suiteName: nil)!
    }
    
    /// nil suite means use the default search list that +standardUserDefaults uses
    public init?(suiteName suitename: String?) {
        suite = suitename
        super.init()
        
        setVolatileDomain(UserDefaults._parsedArgumentsDomain, forName: UserDefaults.argumentDomain)
    }
    
    open func object(forKey defaultName: String) -> Any? {
        let argumentDomain = volatileDomain(forName: UserDefaults.argumentDomain)
        if let object = argumentDomain[defaultName] {
            return object
        }
        
        func getFromRegistered() -> Any? {
            return UserDefaults._unboxingNSNumbers(registeredDefaults[defaultName])
        }
        
        guard let anObj = CFPreferencesCopyAppValue(defaultName._cfObject, suite?._cfObject ?? kCFPreferencesCurrentApplication) else {
            return getFromRegistered()
        }
        
        if let fetched = _SwiftValue.fetch(anObj) {
            return UserDefaults._unboxingNSNumbers(fetched)
        } else {
            return nil
        }
    }

    open func set(_ value: Any?, forKey defaultName: String) {
        guard let value = value else {
            CFPreferencesSetAppValue(defaultName._cfObject, nil, suite?._cfObject ?? kCFPreferencesCurrentApplication)
            return
        }
        
        if let url = value as? URL {
            set(url.absoluteURL.path, forKey: defaultName)
            return
        }
        
        if let url = value as? NSURL, let path = url.absoluteURL?.path {
            set(path, forKey: defaultName)
            return
        }
        
        guard UserDefaults._isValueAllowed(value) else {
            fatalError("This value is not supported by set(_:forKey:)")
        }
        
        CFPreferencesSetAppValue(defaultName._cfObject, _SwiftValue.store(value), suite?._cfObject ?? kCFPreferencesCurrentApplication)
    }
    open func removeObject(forKey defaultName: String) {
        CFPreferencesSetAppValue(defaultName._cfObject, nil, suite?._cfObject ?? kCFPreferencesCurrentApplication)
    }
    
    open func string(forKey defaultName: String) -> String? {
        return object(forKey: defaultName) as? String
    }
    
    open func array(forKey defaultName: String) -> [Any]? {
        return object(forKey: defaultName) as? [Any]
    }
    
    open func dictionary(forKey defaultName: String) -> [String : Any]? {
        return object(forKey: defaultName) as? [String: Any]
    }
    
    open func data(forKey defaultName: String) -> Data? {
        return object(forKey: defaultName) as? Data
    }
    
    open func stringArray(forKey defaultName: String) -> [String]? {
        return object(forKey: defaultName) as? [String]
    }
    
    open func integer(forKey defaultName: String) -> Int {
        guard let aVal = object(forKey: defaultName) else {
            return 0
        }
        if let bVal = aVal as? Int {
            return bVal
        }
        if let bVal = aVal as? String {
            return NSString(string: bVal).integerValue
        }
        return 0
    }
    
    open func float(forKey defaultName: String) -> Float {
        guard let aVal = object(forKey: defaultName) else {
            return 0
        }
        if let bVal = aVal as? Float {
            return bVal
        }
        if let bVal = aVal as? String {
            return NSString(string: bVal).floatValue
        }
        return 0
    }
    
    open func double(forKey defaultName: String) -> Double {
        guard let aVal = object(forKey: defaultName) else {
            return 0
        }
        if let bVal = aVal as? Double {
            return bVal
        }
        if let bVal = aVal as? String {
            return NSString(string: bVal).doubleValue
        }
        return 0
    }
    
    open func bool(forKey defaultName: String) -> Bool {
        guard let aVal = object(forKey: defaultName) else {
            return false
        }
        if let bVal = aVal as? Bool {
            return bVal
        }
        if let bVal = aVal as? Int {
            return bVal != 0
        }
        if let bVal = aVal as? Float {
            return bVal != 0
        }
        if let bVal = aVal as? Double {
            return bVal != 0
        }
        if let bVal = aVal as? String {
            return NSString(string: bVal).boolValue
        }
        return false
    }
    open func url(forKey defaultName: String) -> URL? {
        guard let aVal = object(forKey: defaultName) else {
            return nil
        }
        
        if let bVal = aVal as? URL {
            return bVal
        } else if let bVal = aVal as? String {
            let cVal = NSString(string: bVal).expandingTildeInPath
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
        registeredDefaults.merge(registrationDictionary.mapValues { value in
            // This line will produce a 'Conditional cast always succeeds' warning on Darwin, since Darwin has bridging casts of any value to an object,
            // but is required for non-Darwin to work correctly, since that platform _doesn't_ have bridging casts of that kind for now.
            if let object = value as? AnyObject {
                return _SwiftValue.fetch(nonOptional: object)
            } else {
                return value
            }
        }, uniquingKeysWith: { $1 })
    }

    open func addSuite(named suiteName: String) {
        CFPreferencesAddSuitePreferencesToApp(kCFPreferencesCurrentApplication, suiteName._cfObject)
    }
    open func removeSuite(named suiteName: String) {
        CFPreferencesRemoveSuitePreferencesFromApp(kCFPreferencesCurrentApplication, suiteName._cfObject)
    }
    
    open func dictionaryRepresentation() -> [String: Any] {
        return _dictionaryRepresentation(searchingOutsideOfSuite: true)
    }
    
    private func _dictionaryRepresentation(searchingOutsideOfSuite: Bool) -> [String: Any] {
        let registeredDefaultsIfAllowed = searchingOutsideOfSuite ? registeredDefaults : [:]
        
        guard let defaultsFromDiskCF = CFPreferencesCopyMultiple(nil, suite?._cfObject ?? kCFPreferencesCurrentApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost) else {
            return registeredDefaultsIfAllowed
        }
        
        let defaultsFromDiskWithNumbersBoxed = _SwiftValue.fetch(defaultsFromDiskCF) as? [String: AnyObject] ?? [:]
        
        if registeredDefaultsIfAllowed.count == 0 {
            return UserDefaults._unboxingNSNumbers(defaultsFromDiskWithNumbersBoxed) as! [String: AnyObject]
        } else {
            var allDefaults = registeredDefaultsIfAllowed
            
            for (key, value) in defaultsFromDiskWithNumbersBoxed {
                allDefaults[key] = value
            }
            
            return UserDefaults._unboxingNSNumbers(allDefaults) as! [String: Any]
        }
    }
    
    private static let _parsedArgumentsDomain: [String: Any] = UserDefaults._parseArguments(ProcessInfo.processInfo.arguments)
    
    private var _volatileDomains: [String: [String: Any]] = [:]
    private let _volatileDomainsLock = NSLock()
    
    open var volatileDomainNames: [String] {
        _volatileDomainsLock.lock()
        let names = Array(_volatileDomains.keys)
        _volatileDomainsLock.unlock()
        
        return names
    }
    
    open func volatileDomain(forName domainName: String) -> [String : Any] {
        _volatileDomainsLock.lock()
        let domain = _volatileDomains[domainName]
        _volatileDomainsLock.unlock()
        
        return domain ?? [:]
    }
    
    open func setVolatileDomain(_ domain: [String : Any], forName domainName: String) {
        if !UserDefaults._isValueAllowed(domain) {
            fatalError("The content of 'domain' passed to UserDefaults.setVolatileDomain(_:forName:) is not supported.")
        }
        
        _volatileDomainsLock.lock()
        var storedDomain: [String: Any] = _volatileDomains[domainName] ?? [:]
        storedDomain.merge(domain, uniquingKeysWith: { $1 })
        _volatileDomains[domainName] = storedDomain
        _volatileDomainsLock.unlock()
    }
    
    open func removeVolatileDomain(forName domainName: String) {
        _volatileDomainsLock.lock()
        _volatileDomains.removeValue(forKey: domainName)
        _volatileDomainsLock.unlock()
    }
    
    open func persistentDomain(forName domainName: String) -> [String : Any]? {
        return UserDefaults(suiteName: domainName)?._dictionaryRepresentation(searchingOutsideOfSuite: false)
    }
    
    open func setPersistentDomain(_ domain: [String : Any], forName domainName: String) {
        if let defaults = UserDefaults(suiteName: domainName) {
            var removedAny = false
            for key in defaults._dictionaryRepresentation(searchingOutsideOfSuite: false).keys {
                defaults.removeObject(forKey: key)
                removedAny = true
            }
            
            var addedAny = false
            for (key, value) in domain {
                defaults.set(value, forKey: key)
                addedAny = true
            }
            
            _ = defaults.synchronize()
            
            if removedAny || addedAny {
                NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: self)
            }
        }
    }
    
    open func removePersistentDomain(forName domainName: String) {
        if let defaults = UserDefaults(suiteName: domainName) {
            var removedAny = false
            for key in defaults._dictionaryRepresentation(searchingOutsideOfSuite: false).keys {
                defaults.removeObject(forKey: key)
                removedAny = true
            }
            
            _ = defaults.synchronize()
            
            if removedAny {
                NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: self)
            }
        }
    }
    
    open func synchronize() -> Bool {
        return CFPreferencesAppSynchronize(suite?._cfObject ?? kCFPreferencesCurrentApplication)
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
