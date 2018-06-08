// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

open class Bundle: NSObject {
    private var _bundle : CFBundle!

    private static var _mainBundle : Bundle = {
        return Bundle(cfBundle: CFBundleGetMainBundle())
    }()
    
    open class var main: Bundle {
        get {
            return _mainBundle
        }
    }
    
    open class var allBundles: [Bundle] {
        NSUnimplemented()
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
        self.init(path: url.path)
    }
    
    public init(for aClass: AnyClass) {
        NSUnimplemented()
    }

    public init?(identifier: String) {
        super.init()
        
        guard let result = CFBundleGetBundleWithIdentifier(identifier._cfObject) else {
            return nil
        }
        
        _bundle = result
    }
    
    override open var description: String {
        return "\(String(describing: Bundle.self)) <\(bundleURL.path)> (\(isLoaded  ? "loaded" : "not yet loaded"))"
    }

    
    /* Methods for loading and unloading bundles. */
    open func load() -> Bool {
        return  CFBundleLoadExecutable(_bundle)
    }
    open var isLoaded: Bool {
        return CFBundleIsExecutableLoaded(_bundle)
    }
    @available(*,deprecated,message:"Not available on non-Darwin platforms")
    open func unload() -> Bool { NSUnsupported() }
    
    open func preflight() throws {
        var unmanagedError:Unmanaged<CFError>? = nil
        try withUnsafeMutablePointer(to: &unmanagedError) { (unmanagedCFError: UnsafeMutablePointer<Unmanaged<CFError>?>)  in
            CFBundlePreflightExecutable(_bundle, unmanagedCFError)
            if let error = unmanagedCFError.pointee {
                throw   error.takeRetainedValue()._nsObject
            }
        }
    }
    
    open func loadAndReturnError() throws {
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
    open var bundleURL: URL {
        return CFBundleCopyBundleURL(_bundle)._swiftObject
    }
    
    open var resourceURL: URL? {
        return CFBundleCopyResourcesDirectoryURL(_bundle)?._swiftObject
    }
    
    open var executableURL: URL? {
        return CFBundleCopyExecutableURL(_bundle)?._swiftObject
    }
    
    open func url(forAuxiliaryExecutable executableName: String) -> URL? {
        return CFBundleCopyAuxiliaryExecutableURL(_bundle, executableName._cfObject)?._swiftObject
    }
    
    open var privateFrameworksURL: URL? {
        return CFBundleCopyPrivateFrameworksURL(_bundle)?._swiftObject
    }
    
    open var sharedFrameworksURL: URL? {
        return CFBundleCopySharedFrameworksURL(_bundle)?._swiftObject
    }
    
    open var sharedSupportURL: URL? {
        return CFBundleCopySharedSupportURL(_bundle)?._swiftObject
    }
    
    open var builtInPlugInsURL: URL? {
        return CFBundleCopyBuiltInPlugInsURL(_bundle)?._swiftObject
    }
    
    open var appStoreReceiptURL: URL? {
        // Always nil on this platform
        return nil
    }
    
    open var bundlePath: String {
        return bundleURL.path
    }
    
    open var resourcePath: String? {
        return resourceURL?.path
    }
    
    open var executablePath: String? {
        return executableURL?.path
    }
    
    open func path(forAuxiliaryExecutable executableName: String) -> String? {
        return url(forAuxiliaryExecutable: executableName)?.path
    }
    
    open var privateFrameworksPath: String? {
        return privateFrameworksURL?.path
    }
    
    open var sharedFrameworksPath: String? {
        return sharedFrameworksURL?.path
    }
    
    open var sharedSupportPath: String? {
        return sharedSupportURL?.path
    }
    
    open var builtInPlugInsPath: String? {
        return builtInPlugInsURL?.path
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - URL Resource Lookup - Class
    
    open class func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?, in bundleURL: URL) -> URL? {
        // If both name and ext are nil/zero-length, return nil
        if (name == nil || name!.isEmpty) && (ext == nil || ext!.isEmpty) {
            return nil
        }
        
        return CFBundleCopyResourceURLInDirectory(bundleURL._cfObject, name?._cfObject, ext?._cfObject, subpath?._cfObject)._swiftObject
    }
    
    open class func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?, in bundleURL: NSURL) -> [NSURL]? {
        return CFBundleCopyResourceURLsOfTypeInDirectory(bundleURL._cfObject, ext?._cfObject, subpath?._cfObject)?._unsafeTypedBridge()
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - URL Resource Lookup - Instance

    open func url(forResource name: String?, withExtension ext: String?) -> URL? {
        return self.url(forResource: name, withExtension: ext, subdirectory: nil)
    }
    
    open func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?) -> URL? {
        // If both name and ext are nil/zero-length, return nil
        if (name == nil || name!.isEmpty) && (ext == nil || ext!.isEmpty) {
            return nil
        }
        return CFBundleCopyResourceURL(_bundle, name?._cfObject, ext?._cfObject, subpath?._cfObject)?._swiftObject
    }
    
    open func url(forResource name: String?, withExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> URL? {
        // If both name and ext are nil/zero-length, return nil
        if (name == nil || name!.isEmpty) && (ext == nil || ext!.isEmpty) {
            return nil
        }

        return CFBundleCopyResourceURLForLocalization(_bundle, name?._cfObject, ext?._cfObject, subpath?._cfObject, localizationName?._cfObject)?._swiftObject
    }
    
    open func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?) -> [NSURL]? {
        return CFBundleCopyResourceURLsOfType(_bundle, ext?._cfObject, subpath?._cfObject)?._unsafeTypedBridge()
    }
    
    open func urls(forResourcesWithExtension ext: String?, subdirectory subpath: String?, localization localizationName: String?) -> [NSURL]? {
        return CFBundleCopyResourceURLsOfTypeForLocalization(_bundle, ext?._cfObject, subpath?._cfObject, localizationName?._cfObject)?._unsafeTypedBridge()
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Path Resource Lookup - Class

    open class func path(forResource name: String?, ofType ext: String?, inDirectory bundlePath: String) -> String? {
        return Bundle.url(forResource: name, withExtension: ext, subdirectory: bundlePath, in: URL(fileURLWithPath: bundlePath))?.path
    }
    
    open class func paths(forResourcesOfType ext: String?, inDirectory bundlePath: String) -> [String] {
        // Force-unwrap path, beacuse if the URL can't be turned into a path then something is wrong anyway
        return urls(forResourcesWithExtension: ext, subdirectory: bundlePath, in: NSURL(fileURLWithPath: bundlePath))?.map { $0.path! } ?? []
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Path Resource Lookup - Instance

    open func path(forResource name: String?, ofType ext: String?) -> String? {
        return self.url(forResource: name, withExtension: ext, subdirectory: nil)?.path
    }
    
    open func path(forResource name: String?, ofType ext: String?, inDirectory subpath: String?) -> String? {
        return self.url(forResource: name, withExtension: ext, subdirectory: subpath)?.path
    }
    
    open func path(forResource name: String?, ofType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> String? {
        return self.url(forResource: name, withExtension: ext, subdirectory: subpath, localization: localizationName)?.path
    }
    
    open func paths(forResourcesOfType ext: String?, inDirectory subpath: String?) -> [String] {
        // Force-unwrap path, beacuse if the URL can't be turned into a path then something is wrong anyway
        return self.urls(forResourcesWithExtension: ext, subdirectory: subpath)?.map { $0.path! } ?? []
    }
    
    open func paths(forResourcesOfType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> [String] {
        // Force-unwrap path, beacuse if the URL can't be turned into a path then something is wrong anyway
        return self.urls(forResourcesWithExtension: ext, subdirectory: subpath, localization: localizationName)?.map { $0.path! } ?? []
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Localized Strings
    
    open func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        let localizedString = CFBundleCopyLocalizedString(_bundle, key._cfObject, value?._cfObject, tableName?._cfObject)!
        return localizedString._swiftObject
    }
    
    // -----------------------------------------------------------------------------------
    // MARK: - Other
    
    open var bundleIdentifier: String? {
        return CFBundleGetIdentifier(_bundle)?._swiftObject
    }
    
    open var infoDictionary: [String : Any]? {
        let cfDict: CFDictionary? = CFBundleGetInfoDictionary(_bundle)
        return _SwiftValue.fetch(cfDict) as? [String : Any]
    }
    
    open var localizedInfoDictionary: [String : Any]? {
        let cfDict: CFDictionary? = CFBundleGetLocalInfoDictionary(_bundle)
        return _SwiftValue.fetch(cfDict) as? [String : Any]
    }
    
    open func object(forInfoDictionaryKey key: String) -> Any? {
        if let localizedInfoDictionary = localizedInfoDictionary {
            return localizedInfoDictionary[key]
        } else {
            return infoDictionary?[key]
        }
    }
    
    open func classNamed(_ className: String) -> AnyClass? { NSUnimplemented() }
    open var principalClass: AnyClass? { NSUnimplemented() }
    open var preferredLocalizations: [String] {
        return Bundle.preferredLocalizations(from: localizations)
    }
    open var localizations: [String] {
        let cfLocalizations: CFArray? = CFBundleCopyBundleLocalizations(_bundle)
        let nsLocalizations = _SwiftValue.fetch(cfLocalizations) as? [Any]
        return nsLocalizations?.map { $0 as! String } ?? []
    }

    open var developmentLocalization: String? {
        let region = CFBundleGetDevelopmentRegion(_bundle)!
        return region._swiftObject
    }

    open class func preferredLocalizations(from localizationsArray: [String]) -> [String] {
        let cfLocalizations: CFArray? = CFBundleCopyPreferredLocalizationsFromArray(localizationsArray._cfObject)
        let nsLocalizations = _SwiftValue.fetch(cfLocalizations) as? [Any]
        return nsLocalizations?.map { $0 as! String } ?? []
    }
    
	open class func preferredLocalizations(from localizationsArray: [String], forPreferences preferencesArray: [String]?) -> [String] {
        let localizations = CFBundleCopyLocalizationsForPreferences(localizationsArray._cfObject, preferencesArray?._cfObject)!
        return localizations._swiftObject.map { return ($0 as! NSString)._swiftObject }
    }
	
	open var executableArchitectures: [NSNumber]? {
        let architectures = CFBundleCopyExecutableArchitectures(_bundle)!
        return architectures._swiftObject.map() { $0 as! NSNumber }
    }
}

