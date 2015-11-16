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
    public var bundleURL: NSURL { NSUnimplemented() }
    
    public var resourceURL: NSURL? { NSUnimplemented() }
    
    public var executableURL: NSURL? { NSUnimplemented() }
    
    public func URLForAuxiliaryExecutable(executableName: String) -> NSURL? { NSUnimplemented() }
    
    public var privateFrameworksURL: NSURL? { NSUnimplemented() }
    
    public var sharedFrameworksURL: NSURL? { NSUnimplemented() }
    
    public var sharedSupportURL: NSURL? { NSUnimplemented() }
    
    public var builtInPlugInsURL: NSURL? { NSUnimplemented() }
    
    public var appStoreReceiptURL: NSURL? {
        // Always nil on this platform
        return nil
    }
    
    public var bundlePath: String { NSUnimplemented() }
    
    public var resourcePath: String? { NSUnimplemented() }
    
    public var executablePath: String? { NSUnimplemented() }
    
    public func pathForAuxiliaryExecutable(executableName: String) -> String? { NSUnimplemented() }
    
    public var privateFrameworksPath: String? { NSUnimplemented() }
    
    public var sharedFrameworksPath: String? { NSUnimplemented() }
    
    public var sharedSupportPath: String? { NSUnimplemented() }
    
    public var builtInPlugInsPath: String? { NSUnimplemented() }
    
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
    
    public func URLForResource(name: String?, withExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> NSURL? { NSUnimplemented() }
    
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
    
    public func localizedStringForKey(key: String, value: String?, table tableName: String?) -> String { NSUnimplemented() }
    
    
    // -----------------------------------------------------------------------------------
    // MARK: - Other
    
    public var bundleIdentifier: String? { NSUnimplemented() }
    public var infoDictionary: [String : AnyObject]? { NSUnimplemented() }
    public var localizedInfoDictionary: [String : AnyObject]? { NSUnimplemented() }
    public func objectForInfoDictionaryKey(key: String) -> AnyObject? { NSUnimplemented() }
    public func classNamed(className: String) -> AnyClass? { NSUnimplemented() }
    public var principalClass: AnyClass? { NSUnimplemented() }
    public var preferredLocalizations: [String] { NSUnimplemented() }
    public var localizations: [String] { NSUnimplemented() }
    public var developmentLocalization: String? { NSUnimplemented() }
    public class func preferredLocalizationsFromArray(localizationsArray: [String]) -> [String] { NSUnimplemented() }
    public class func preferredLocalizationsFromArray(localizationsArray: [String], forPreferences preferencesArray: [String]?) -> [String] { NSUnimplemented() }
    public var executableArchitectures: [NSNumber]? { NSUnimplemented() }
}

