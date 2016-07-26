// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

public class Bundle: NSObject {
    private var _bundle : CFBundle!

    private static var _mainBundle : Bundle = {
        return Bundle(cfBundle: CFBundleGetMainBundle())
    }()
    
    public class func main() -> Bundle {
        return _mainBundle
    }
    
    internal init(cfBundle: CFBundle) {
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
        
        let url = URL(fileURLWithPath: resolvedPath)
        _bundle = CFBundleCreate(kCFAllocatorSystemDefault, unsafeBitCast(url, to: CFURL.self))
        if (_bundle == nil) {
            return nil
        }
    }
    
    public convenience init?(url: URL) {
        if let path = url.path {
            self.init(path: path)
        } else {
            return nil
        }
    }
    
    public init(for aClass: AnyClass) { NSUnimplemented() }
    
    public init?(identifier: String) {
        super.init()
        
        guard let result = CFBundleGetBundleWithIdentifier(identifier._cfObject) else {
            return nil
        }
        
        _bundle = result
    }
    
    override public var description: String {
        return "\(String(describing: Bundle.self)) <\(bundleURL.path!)> (\(isLoaded  ? "loaded" : "not yet loaded"))"
    }

    
    /* Methods for loading and unloading bundles. */
    public func load() -> Bool {
        return  CFBundleLoadExecutable(_bundle)
    }
    public var isLoaded: Bool {
        return CFBundleIsExecutableLoaded(_bundle)
    }
    public func unload() -> Bool { NSUnimplemented() }
    
    public func preflight() throws {
        var unmanagedError:Unmanaged<CFError>? = nil
        try withUnsafeMutablePointer(to: &unmanagedError) { (unmanagedCFError: UnsafeMutablePointer<Unmanaged<CFError>?>)  in
            CFBundlePreflightExecutable(_bundle, unmanagedCFError)
            if let error = unmanagedCFError.pointee {
                throw   error.takeRetainedValue()._nsObject
            }
        }
    }
    
    public func loadAndReturnError() throws {
        var unmanagedError:Unmanaged<CFError>? = nil
        try  withUnsafeMutablePointer(to: &unmanagedError) { (unmanagedCFError: UnsafeMutablePointer<Unmanaged<CFError>?>)  in
            CFBundleLoadExecutableAndReturnError(_bundle, unmanagedCFError)
            if let error = unmanagedCFError.pointee {
                let retainedValue = error.takeRetainedValue()
                throw  retainedValue._nsObject
            }
        }
    }

    
    /* Methods for locating various components of a bundle. */
    public var bundleURL: URL {
        return CFBundleCopyBundleURL(_bundle)._swiftObject
    }
    
    public var resourceURL: URL? {
        return CFBundleCopyResourcesDirectoryURL(_bundle)?._swiftObject
    }
    
    public var executableURL: URL? {
        return CFBundleCopyExecutableURL(_bundle)?._swiftObject
    }
    
    public func urlForAuxiliaryExecutable(_ executableName: String) -> NSURL? {
        return CFBundleCopyAuxiliaryExecutableURL(_bundle, executableName._cfObject)?._nsObject
    }
    
    public var privateFrameworksURL: URL? {
        return CFBundleCopyPrivateFrameworksURL(_bundle)?._swiftObject
    }
    
    public var sharedFrameworksURL: URL? {
        return CFBundleCopySharedFrameworksURL(_bundle)?._swiftObject
    }
    
    public var sharedSupportURL: URL? {
        return CFBundleCopySharedSupportURL(_bundle)?._swiftObject
    }
    
    public var builtInPlugInsURL: URL? {
        return CFBundleCopyBuiltInPlugInsURL(_bundle)?._swiftObject
    }
    
    public var appStoreReceiptURL: URL? {
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
    
    public func pathForAuxiliaryExecutable(_ executableName: String) -> String? {
        return urlForAuxiliaryExecutable(executableName)?.path
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
    
    public class func urlForResource(_ name: String?, withExtension ext: String?, subdirectory subpath: String?, inBundleWith bundleURL: URL) -> URL? {
        // If both name and ext are nil/zero-length, return nil
        if (name == nil || name!.isEmpty) && (ext == nil || ext!.isEmpty) {
            return nil
        }
        
        return CFBundleCopyResourceURLInDirectory(bundleURL._cfObject, name?._cfObject, ext?._cfObject, subpath?._cfObject)._swiftObject
    }
    
    public class func urlsForResources(withExtension ext: String?, subdirectory subpath: String?, inBundleWith bundleURL: NSURL) -> [NSURL]? {
        return CFBundleCopyResourceURLsOfTypeInDirectory(bundleURL._cfObject, ext?._cfObject, subpath?._cfObject)?._unsafeTypedBridge()
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - URL Resource Lookup - Instance

    public func urlForResource(_ name: String?, withExtension ext: String?) -> URL? {
        return self.urlForResource(name, withExtension: ext, subdirectory: nil)
    }
    
    public func urlForResource(_ name: String?, withExtension ext: String?, subdirectory subpath: String?) -> URL? {
        // If both name and ext are nil/zero-length, return nil
        if (name == nil || name!.isEmpty) && (ext == nil || ext!.isEmpty) {
            return nil
        }
        return CFBundleCopyResourceURL(_bundle, name?._cfObject, ext?._cfObject, subpath?._cfObject)?._swiftObject
    }
    
    public func urlForResource(_ name: String?, withExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> URL? {
        // If both name and ext are nil/zero-length, return nil
        if (name == nil || name!.isEmpty) && (ext == nil || ext!.isEmpty) {
            return nil
        }

        return CFBundleCopyResourceURLForLocalization(_bundle, name?._cfObject, ext?._cfObject, subpath?._cfObject, localizationName?._cfObject)?._swiftObject
    }
    
    public func urlsForResources(withExtension ext: String?, subdirectory subpath: String?) -> [NSURL]? {
        return CFBundleCopyResourceURLsOfType(_bundle, ext?._cfObject, subpath?._cfObject)?._unsafeTypedBridge()
    }
    
    public func urlsForResources(withExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> [NSURL]? {
        return CFBundleCopyResourceURLsOfTypeForLocalization(_bundle, ext?._cfObject, subpath?._cfObject, localizationName?._cfObject)?._unsafeTypedBridge()
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Path Resource Lookup - Class

    public class func pathForResource(_ name: String?, ofType ext: String?, inDirectory bundlePath: String) -> String? {
        return Bundle.urlForResource(name, withExtension: ext, subdirectory: bundlePath, inBundleWith: URL(fileURLWithPath: bundlePath))?.path ?? nil
    }
    
    public class func pathsForResources(ofType ext: String?, inDirectory bundlePath: String) -> [String] {
        // Force-unwrap path, beacuse if the URL can't be turned into a path then something is wrong anyway
        return urlsForResources(withExtension: ext, subdirectory: bundlePath, inBundleWith: NSURL(fileURLWithPath: bundlePath))?.map { $0.path! } ?? []
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Path Resource Lookup - Instance

    public func pathForResource(_ name: String?, ofType ext: String?) -> String? {
        return self.urlForResource(name, withExtension: ext, subdirectory: nil)?.path
    }
    
    public func pathForResource(_ name: String?, ofType ext: String?, inDirectory subpath: String?) -> String? {
        return self.urlForResource(name, withExtension: ext, subdirectory: subpath)?.path
    }
    
    public func pathForResource(_ name: String?, ofType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> String? {
        return self.urlForResource(name, withExtension: ext, subdirectory: subpath, localization: localizationName)?.path
    }
    
    public func pathsForResources(ofType ext: String?, inDirectory subpath: String?) -> [String] {
        // Force-unwrap path, beacuse if the URL can't be turned into a path then something is wrong anyway
        return self.urlsForResources(withExtension: ext, subdirectory: subpath)?.map { $0.path! } ?? []
    }
    
    public func pathsForResources(ofType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> [String] {
        // Force-unwrap path, beacuse if the URL can't be turned into a path then something is wrong anyway
        return self.urlsForResources(withExtension: ext, subdirectory: subpath, localization: localizationName)?.map { $0.path! } ?? []
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Localized Strings
    
    public func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let localizedString = CFBundleCopyLocalizedString(_bundle, key._cfObject, value?._cfObject, tableName?._cfObject)!
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
    public func objectForInfoDictionaryKey(_ key: String) -> Any? {
        if let localizedInfoDictionary = localizedInfoDictionary {
            return localizedInfoDictionary[key]
        } else {
            return infoDictionary?[key]
        }
    }
    
    public func classNamed(_ className: String) -> AnyClass? { NSUnimplemented() }
    public var principalClass: AnyClass? { NSUnimplemented() }
    public var preferredLocalizations: [String] {
        return Bundle.preferredLocalizations(from: localizations)
    }
    public var localizations: [String] {
        let cfLocalizations: CFArray? = CFBundleCopyBundleLocalizations(_bundle)
        let nsLocalizations = cfLocalizations.map(_expensivePropertyListConversion) as? [Any]
        return nsLocalizations?.map { $0 as! String } ?? []
    }

    public var developmentLocalization: String? {
        let region = CFBundleGetDevelopmentRegion(_bundle)!
        return region._swiftObject
    }

    public class func preferredLocalizations(from localizationsArray: [String]) -> [String] {
        let cfLocalizations: CFArray? = CFBundleCopyPreferredLocalizationsFromArray(localizationsArray._cfObject)
        let nsLocalizations = cfLocalizations.map(_expensivePropertyListConversion) as? [Any]
        return nsLocalizations?.map { $0 as! String } ?? []
    }
    
	public class func preferredLocalizations(from localizationsArray: [String], forPreferences preferencesArray: [String]?) -> [String] {
        let localizations = CFBundleCopyLocalizationsForPreferences(localizationsArray._cfObject, preferencesArray?._cfObject)!
        return localizations._swiftObject.map { return ($0 as! NSString)._swiftObject }
    }
	
	public var executableArchitectures: [NSNumber]? {
        let architectures = CFBundleCopyExecutableArchitectures(_bundle)!
        return architectures._swiftObject.map() { $0 as! NSNumber }
    }
}

