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
        
        let resolvedPath = path._nsObject.stringByResolvingSymlinksInPath
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
        let url = CFBundleCopyBundleURL(_bundle)
        return url._nsObject
    }
    
    public var resourceURL: NSURL? {
        let url = CFBundleCopyResourcesDirectoryURL(_bundle)
        return url._nsObject
    }
    
    public var executableURL: NSURL? {
        let url = CFBundleCopyExecutableURL(_bundle)
        return url._nsObject
    }
    
    public func URLForAuxiliaryExecutable(executableName: String) -> NSURL? {
        let url = CFBundleCopyAuxiliaryExecutableURL(_bundle, executableName._cfObject)
        return url._nsObject
    }
    
    public var privateFrameworksURL: NSURL? {
        let url = CFBundleCopyPrivateFrameworksURL(_bundle)
        return url._nsObject
    }
    
    public var sharedFrameworksURL: NSURL? {
        let url = CFBundleCopySharedFrameworksURL(_bundle)
        return url._nsObject
    }
    
    public var sharedSupportURL: NSURL? {
        let url = CFBundleCopySharedSupportURL(_bundle)
        return url._nsObject
    }
    
    public var builtInPlugInsURL: NSURL? {
        let url = CFBundleCopyBuiltInPlugInsURL(_bundle)
        return url._nsObject
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
    // MARK: - URL and Path Resource Lookup
    
    public class func URLForResource(name: String?, withExtension ext: String?, subdirectory subpath: String?, inBundleWithURL bundleURL: NSURL) -> NSURL? { NSUnimplemented() }
    
    public class func URLsForResourcesWithExtension(ext: String?, subdirectory subpath: String?, inBundleWithURL bundleURL: NSURL) -> [NSURL]? { NSUnimplemented() }
    
    public func URLForResource(name: String?, withExtension ext: String?) -> NSURL? {
        return self.URLForResource(name, withExtension: ext, subdirectory: nil)
    }
    
    public func URLForResource(name: String?, withExtension ext: String?, subdirectory subpath: String?) -> NSURL? {
        // If both name and ext are nil/zero-length, return nil
        if (name == nil || name!.isEmpty) && (ext == nil || ext!.isEmpty) {
            return nil
        }
        let resultURL = CFBundleCopyResourceURL(_bundle, name?._cfObject, ext?._cfObject, subpath?._cfObject)
        return unsafeBitCast(resultURL, NSURL.self)
    }
    
    public func URLForResource(name: String?, withExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> NSURL? {
        if let url = CFBundleCopyResourceURLForLocalization(_bundle, name?._cfObject, ext?._cfObject, subpath?._cfObject, localizationName?._cfObject) {
            return url._nsObject
        } else {
            return nil
        }
    }
    
    public func URLsForResourcesWithExtension(ext: String?, subdirectory subpath: String?) -> [NSURL]? { NSUnimplemented() }
    
    public func URLsForResourcesWithExtension(ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> [NSURL]? { NSUnimplemented() }
    
    public class func pathForResource(name: String?, ofType ext: String?, inDirectory bundlePath: String) -> String? { NSUnimplemented() }
    
    public class func pathsForResourcesOfType(ext: String?, inDirectory bundlePath: String) -> [String] { NSUnimplemented() }
    
    public func pathForResource(name: String?, ofType ext: String?) -> String? {
        return self.URLForResource(name, withExtension: ext, subdirectory: nil)?.path
    }
    
    public func pathForResource(name: String?, ofType ext: String?, inDirectory subpath: String?) -> String? {
        return self.URLForResource(name, withExtension: ext, subdirectory: nil)?.path
    }
    
    public func pathForResource(name: String?, ofType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> String? { NSUnimplemented() }
    
    public func pathsForResourcesOfType(ext: String?, inDirectory subpath: String?) -> [String] { NSUnimplemented() }
    public func pathsForResourcesOfType(ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> [String] { NSUnimplemented() }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Localized Strings
    
    public func localizedStringForKey(key: String, value: String?, table tableName: String?) -> String {
        let localizedString = CFBundleCopyLocalizedString(_bundle, key._cfObject, value?._cfObject, tableName?._cfObject)
        return localizedString._swiftObject
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Other
    
    public var bundleIdentifier: String? {
        let identifier = CFBundleGetIdentifier(_bundle)
        return identifier._swiftObject
    }
    
    public var infoDictionary: [String : AnyObject]? {
        if let dictionary = CFBundleGetInfoDictionary(_bundle) {
            return dictionary._swiftObject as? [String: AnyObject]
        } else {
            return nil
        }
    }
    
    public var localizedInfoDictionary: [String : AnyObject]? {
        if let localDictionary = CFBundleGetLocalInfoDictionary(_bundle) {
            return localDictionary._swiftObject as? [String: AnyObject]
        } else {
            return nil
        }
    }
    
    public func objectForInfoDictionaryKey(key: String) -> AnyObject? {
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
        let localizations = CFBundleCopyBundleLocalizations(_bundle)
        return localizations._swiftObject as! [String]
    }
    
    public var developmentLocalization: String? {
        let region = CFBundleGetDevelopmentRegion(_bundle)
        return region._swiftObject
    }
    
    public class func preferredLocalizationsFromArray(localizationsArray: [String]) -> [String] {
        let localizations = CFBundleCopyPreferredLocalizationsFromArray(localizationsArray._cfObject)
        return localizations._swiftObject as! [String]
    }
    
    public class func preferredLocalizationsFromArray(localizationsArray: [String], forPreferences preferencesArray: [String]?) -> [String] {
        let localizations = CFBundleCopyLocalizationsForPreferences(localizationsArray._cfObject, preferencesArray?._cfObject)
        return localizations._swiftObject as! [String]
    }
    
    public var executableArchitectures: [NSNumber]? {
        let architectures = CFBundleCopyExecutableArchitectures(_bundle)
        return architectures._swiftObject as? [NSNumber]
    }
}

