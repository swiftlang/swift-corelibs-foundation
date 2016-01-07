// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public class NSBundle : NSObject {
    private var _bundle : CFBundleRef!

    private static var _mainBundle : NSBundle = {
        return NSBundle(cfBundle: CFBundleGetMainBundle())
    }()
    
    public class func mainBundle() -> NSBundle {
        return _mainBundle
    }
    
    internal init(cfBundle: CFBundleRef) {
        super.init()
        _bundle = cfBundle
    }
    
    public init?(path: String) {
        super.init()
        
        // TODO: We do not yet resolve symlinks, but we must for compatibility
        // let resolvedPath = path._nsObject.stringByResolvingSymlinksInPath
        let resolvedPath = path
        guard resolvedPath.length > 0 else {
            return nil
        }
        
        let url = NSURL(fileURLWithPath: resolvedPath)
        _bundle = CFBundleCreate(kCFAllocatorSystemDefault, unsafeBitCast(url, CFURLRef.self))
    }
    
    public convenience init?(URL url: NSURL) {
        if let path = url.path {
            self.init(path: path)
        } else {
            return nil
        }
    }
    
    public init(forClass aClass: AnyClass) { NSUnimplemented() }
    
    public init?(identifier: String) {
        super.init()
        
        guard let result = CFBundleGetBundleWithIdentifier(identifier._cfObject) else {
            return nil
        }
        
        _bundle = result
    }
    
    /* Methods for loading and unloading bundles. */
    public func load() -> Bool { NSUnimplemented() }
    public var loaded: Bool { NSUnimplemented() }
    public func unload() -> Bool { NSUnimplemented() }
    
    public func preflight() throws { NSUnimplemented() }
    public func loadAndReturnError() throws { NSUnimplemented() }
    
    /* Methods for locating various components of a bundle. */
    public var bundleURL: NSURL {
        return CFBundleCopyBundleURL(_bundle)._nsObject
    }
    
    public var resourceURL: NSURL? {
        return CFBundleCopyResourcesDirectoryURL(_bundle)?._nsObject
    }
    
    public var executableURL: NSURL? {
        return CFBundleCopyExecutableURL(_bundle)?._nsObject
    }
    
    public func URLForAuxiliaryExecutable(executableName: String) -> NSURL? {
        return CFBundleCopyAuxiliaryExecutableURL(_bundle, executableName._cfObject)?._nsObject
    }
    
    public var privateFrameworksURL: NSURL? {
        return CFBundleCopyPrivateFrameworksURL(_bundle)?._nsObject
    }
    
    public var sharedFrameworksURL: NSURL? {
        return CFBundleCopySharedFrameworksURL(_bundle)?._nsObject
    }
    
    public var sharedSupportURL: NSURL? {
        return CFBundleCopySharedSupportURL(_bundle)?._nsObject
    }
    
    public var builtInPlugInsURL: NSURL? {
        return CFBundleCopyBuiltInPlugInsURL(_bundle)?._nsObject
    }
    
    public var appStoreReceiptURL: NSURL? {
        // Always nil on this platform
        return nil
    }
    
    public var bundlePath: String {
        return bundleURL.path!
    }
    
    public var resourcePath: String? {
        return resourceURL?.path
    }
    
    public var executablePath: String? {
        return executableURL?.path
    }
    
    public func pathForAuxiliaryExecutable(executableName: String) -> String? {
        return URLForAuxiliaryExecutable(executableName)?.path
    }
    
    public var privateFrameworksPath: String? {
        return privateFrameworksURL?.path
    }
    
    public var sharedFrameworksPath: String? {
        return sharedFrameworksURL?.path
    }
    
    public var sharedSupportPath: String? {
        return sharedSupportURL?.path
    }
    
    public var builtInPlugInsPath: String? {
        return builtInPlugInsURL?.path
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - URL Resource Lookup - Class
    
    public class func URLForResource(name: String?, withExtension ext: String?, subdirectory subpath: String?, inBundleWithURL bundleURL: NSURL) -> NSURL? {
        // If both name and ext are nil/zero-length, return nil
        if (name == nil || name!.isEmpty) && (ext == nil || ext!.isEmpty) {
            return nil
        }
        
        return CFBundleCopyResourceURLInDirectory(bundleURL._cfObject, name?._cfObject, ext?._cfObject, subpath?._cfObject)._nsObject
    }
    
    public class func URLsForResourcesWithExtension(ext: String?, subdirectory subpath: String?, inBundleWithURL bundleURL: NSURL) -> [NSURL]? {
        return CFBundleCopyResourceURLsOfTypeInDirectory(bundleURL._cfObject, ext?._cfObject, subpath?._cfObject)?._unsafeTypedBridge()
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - URL Resource Lookup - Instance

    public func URLForResource(name: String?, withExtension ext: String?) -> NSURL? {
        return self.URLForResource(name, withExtension: ext, subdirectory: nil)
    }
    
    public func URLForResource(name: String?, withExtension ext: String?, subdirectory subpath: String?) -> NSURL? {
        // If both name and ext are nil/zero-length, return nil
        if (name == nil || name!.isEmpty) && (ext == nil || ext!.isEmpty) {
            return nil
        }
        return CFBundleCopyResourceURL(_bundle, name?._cfObject, ext?._cfObject, subpath?._cfObject)?._nsObject
    }
    
    public func URLForResource(name: String?, withExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> NSURL? {
        // If both name and ext are nil/zero-length, return nil
        if (name == nil || name!.isEmpty) && (ext == nil || ext!.isEmpty) {
            return nil
        }

        return CFBundleCopyResourceURLForLocalization(_bundle, name?._cfObject, ext?._cfObject, subpath?._cfObject, localizationName?._cfObject)?._nsObject
    }
    
    public func URLsForResourcesWithExtension(ext: String?, subdirectory subpath: String?) -> [NSURL]? {
        return CFBundleCopyResourceURLsOfType(_bundle, ext?._cfObject, subpath?._cfObject)?._unsafeTypedBridge()
    }
    
    public func URLsForResourcesWithExtension(ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> [NSURL]? {
        return CFBundleCopyResourceURLsOfTypeForLocalization(_bundle, ext?._cfObject, subpath?._cfObject, localizationName?._cfObject)?._unsafeTypedBridge()
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Path Resource Lookup - Class

    public class func pathForResource(name: String?, ofType ext: String?, inDirectory bundlePath: String) -> String? {
        return NSBundle.URLForResource(name, withExtension: ext, subdirectory: bundlePath, inBundleWithURL: NSURL(fileURLWithPath: bundlePath))?.path ?? nil
    }
    
    public class func pathsForResourcesOfType(ext: String?, inDirectory bundlePath: String) -> [String] {
        // Force-unwrap path, beacuse if the URL can't be turned into a path then something is wrong anyway
        return URLsForResourcesWithExtension(ext, subdirectory: bundlePath, inBundleWithURL: NSURL(fileURLWithPath: bundlePath))?.map { $0.path! } ?? []
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Path Resource Lookup - Instance

    public func pathForResource(name: String?, ofType ext: String?) -> String? {
        return self.URLForResource(name, withExtension: ext, subdirectory: nil)?.path
    }
    
    public func pathForResource(name: String?, ofType ext: String?, inDirectory subpath: String?) -> String? {
        return self.URLForResource(name, withExtension: ext, subdirectory: nil)?.path
    }
    
    public func pathForResource(name: String?, ofType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> String? {
        return self.URLForResource(name, withExtension: ext, subdirectory: subpath, localization: localizationName)?.path
    }
    
    public func pathsForResourcesOfType(ext: String?, inDirectory subpath: String?) -> [String] {
        // Force-unwrap path, beacuse if the URL can't be turned into a path then something is wrong anyway
        return self.URLsForResourcesWithExtension(ext, subdirectory: subpath)?.map { $0.path! } ?? []
    }
    
    public func pathsForResourcesOfType(ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> [String] {
        // Force-unwrap path, beacuse if the URL can't be turned into a path then something is wrong anyway
        return self.URLsForResourcesWithExtension(ext, subdirectory: subpath, localization: localizationName)?.map { $0.path! } ?? []
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Localized Strings
    
    public func localizedStringForKey(key: String, value: String?, table tableName: String?) -> String {
        let localizedString = CFBundleCopyLocalizedString(_bundle, key._cfObject, value?._cfObject, tableName?._cfObject)
        return localizedString._swiftObject
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Other
    
    public var bundleIdentifier: String? {
        return CFBundleGetIdentifier(_bundle)?._swiftObject
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: This API differs from Darwin because it uses [String : Any] as a type instead of [String : AnyObject]. This allows the use of Swift value types.
    public var infoDictionary: [String : Any]? {
        let cfDict: CFDictionary? = CFBundleGetInfoDictionary(_bundle)
        return cfDict.map(_expensivePropertyListConversion) as? [String: Any]
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: This API differs from Darwin because it uses [String : Any] as a type instead of [String : AnyObject]. This allows the use of Swift value types.
    public var localizedInfoDictionary: [String : Any]? {
        let cfDict: CFDictionary? = CFBundleGetLocalInfoDictionary(_bundle)
        return cfDict.map(_expensivePropertyListConversion) as? [String: Any]
    }
    
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: This API differs from Darwin because it uses [String : Any] as a type instead of [String : AnyObject]. This allows the use of Swift value types.
    public func objectForInfoDictionaryKey(key: String) -> Any? {
        if let localizedInfoDictionary = localizedInfoDictionary {
            return localizedInfoDictionary[key]
        } else {
            return infoDictionary?[key]
        }
    }
    
    public func classNamed(className: String) -> AnyClass? { NSUnimplemented() }
    public var principalClass: AnyClass? { NSUnimplemented() }
    public var preferredLocalizations: [String] {
        return NSBundle.preferredLocalizationsFromArray(localizations)
    }
    public var localizations: [String] {
        let cfLocalizations: CFArray? = CFBundleCopyBundleLocalizations(_bundle)
        let nsLocalizations = cfLocalizations.map(_expensivePropertyListConversion) as? [Any]
        return nsLocalizations?.map { $0 as! String } ?? []
    }

    public var developmentLocalization: String? {
        let region = CFBundleGetDevelopmentRegion(_bundle)
        return region._swiftObject
    }

    public class func preferredLocalizationsFromArray(localizationsArray: [String]) -> [String] {
        let cfLocalizations: CFArray? = CFBundleCopyPreferredLocalizationsFromArray(localizationsArray._cfObject)
        let nsLocalizations = cfLocalizations.map(_expensivePropertyListConversion) as? [Any]
        return nsLocalizations?.map { $0 as! String } ?? []
    }
    
	public class func preferredLocalizationsFromArray(localizationsArray: [String], forPreferences preferencesArray: [String]?) -> [String] {
        let localizations = CFBundleCopyLocalizationsForPreferences(localizationsArray._cfObject, preferencesArray?._cfObject)
        return localizations._swiftObject.map { return ($0 as! NSString)._swiftObject }
    }
	
	public var executableArchitectures: [NSNumber]? {
        let architectures = CFBundleCopyExecutableArchitectures(_bundle)
        return architectures._swiftObject.map() { $0 as! NSNumber }
    }
}

