// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

@_silgen_name("swift_getTypeContextDescriptor")
private func _getTypeContextDescriptor(of cls: AnyClass) -> UnsafeRawPointer

open class Bundle: NSObject {
    private var _bundle : CFBundle!
    
    public static var _supportsFHSBundles: Bool {
        #if DEPLOYMENT_RUNTIME_OBJC
        return false
        #else
        return _CFBundleSupportsFHSBundles()
        #endif
    }
    
    public static var _supportsFreestandingBundles: Bool {
        #if DEPLOYMENT_RUNTIME_OBJC
        return false
        #else
        return _CFBundleSupportsFreestandingBundles()
        #endif
    }

    private static var _mainBundle : Bundle = {
        return Bundle(cfBundle: CFBundleGetMainBundle())
    }()
    
    open class var main: Bundle {
        get {
            return _mainBundle
        }
    }
    
    private class var allBundlesRegardlessOfType: [Bundle] {
        // FIXME: This doesn't return bundles that weren't loaded using CFBundle or class Bundle. https://bugs.swift.org/browse/SR-10433
        guard let bundles = CFBundleGetAllBundles()?._swiftObject as? [CFBundle] else { return [] }
        return bundles.map(Bundle.init(cfBundle:))
    }

    private var isFramework: Bool {
        #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
        return bundleURL.pathExtension == "framework"
        #else
        
            #if os(Windows)
            if let name = _CFBundleCopyExecutablePath(_bundle)?._nsObject {
                return name.pathExtension.lowercased == "dll"
            }
            #else
        
            // We're assuming this is an OS like Linux or BSD that uses FHS-style library names (lib….so or lib….so.2.3.4)
            if let name = _CFBundleCopyExecutablePath(_bundle)?._nsObject {
                return name.hasPrefix("lib") && (name.pathExtension == "so" || name.range(of: ".so.").location != NSNotFound)
            }
        
            #endif
        
        return false
        #endif
    }
    
    open class var allBundles: [Bundle] {
        return allBundlesRegardlessOfType.filter { !$0.isFramework }
    }
    
    open class var allFrameworks: [Bundle] {
        return allBundlesRegardlessOfType.filter { $0.isFramework }
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
        _bundle = CFBundleCreate(kCFAllocatorSystemDefault, url._cfObject)
        if (_bundle == nil) {
            return nil
        }
    }
    
    public convenience init?(url: URL) {
        self.init(path: url.path)
    }
    
    #if os(Windows)
    @available(Windows, deprecated, message: "Not yet implemented.")
    public init(for aClass: AnyClass) {
        NSUnimplemented()
    }
    #else
    public init(for aClass: AnyClass) {
        let pointerInImageOfClass = _getTypeContextDescriptor(of: aClass)
        guard let imagePath = _CFBundleCopyLoadedImagePathForAddress(pointerInImageOfClass)?._swiftObject else {
            _bundle = CFBundleGetMainBundle()
            return
        }
        
        let path = (try? FileManager.default._canonicalizedPath(toFileAtPath: imagePath)) ?? imagePath
        
        let url = URL(fileURLWithPath: path)
        if Bundle.main.executableURL == url {
            _bundle = CFBundleGetMainBundle()
            return
        }
        
        for bundle in Bundle.allBundlesRegardlessOfType {
            if bundle.executableURL == url {
                _bundle = bundle._bundle
                return
            }
        }
        
        let bundle = _CFBundleCreateWithExecutableURLIfMightBeBundle(kCFAllocatorSystemDefault, url._cfObject)?.takeRetainedValue()
        _bundle = bundle ?? CFBundleGetMainBundle()
    }
    #endif

    public init?(identifier: String) {
        super.init()
        
        guard let result = CFBundleGetBundleWithIdentifier(identifier._cfObject) else {
            return nil
        }
        
        _bundle = result
    }
    
    public convenience init?(_executableURL: URL) {
        guard let bundleURL = _CFBundleCopyBundleURLForExecutableURL(_executableURL._cfObject)?.takeRetainedValue() else {
            return nil
        }
        
        self.init(url: bundleURL._swiftObject)
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
        // Force-unwrap path, because if the URL can't be turned into a path then something is wrong anyway
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
        // Force-unwrap path, because if the URL can't be turned into a path then something is wrong anyway
        return self.urls(forResourcesWithExtension: ext, subdirectory: subpath)?.map { $0.path! } ?? []
    }
    
    open func paths(forResourcesOfType ext: String?, inDirectory subpath: String?, forLocalization localizationName: String?) -> [String] {
        // Force-unwrap path, because if the URL can't be turned into a path then something is wrong anyway
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
        return __SwiftValue.fetch(cfDict) as? [String : Any]
    }
    
    open var localizedInfoDictionary: [String : Any]? {
        let cfDict: CFDictionary? = CFBundleGetLocalInfoDictionary(_bundle)
        return __SwiftValue.fetch(cfDict) as? [String : Any]
    }
    
    open func object(forInfoDictionaryKey key: String) -> Any? {
        if let localizedInfoDictionary = localizedInfoDictionary {
            return localizedInfoDictionary[key]
        } else {
            return infoDictionary?[key]
        }
    }
    
    open func classNamed(_ className: String) -> AnyClass? {
        // FIXME: This will return a class that may not be associated with the receiver. https://bugs.swift.org/browse/SR-10347.
        guard isLoaded || load() else { return nil }
        return NSClassFromString(className)
    }
    
    open var principalClass: AnyClass? {
        // NB: Cross-platform Swift doesn't have a notion of 'the first class in the ObjC segment' that ObjC platforms have. For swift-corelibs-foundation, if a bundle doesn't have a principal class named, the principal class is nil.
        guard let name = infoDictionary?["NSPrincipalClass"] as? String else { return nil }
        return classNamed(name)
    }
    
    open var preferredLocalizations: [String] {
        return Bundle.preferredLocalizations(from: localizations)
    }
    open var localizations: [String] {
        let cfLocalizations: CFArray? = CFBundleCopyBundleLocalizations(_bundle)
        let nsLocalizations = __SwiftValue.fetch(cfLocalizations) as? [Any]
        return nsLocalizations?.map { $0 as! String } ?? []
    }

    open var developmentLocalization: String? {
        let region = CFBundleGetDevelopmentRegion(_bundle)!
        return region._swiftObject
    }

    open class func preferredLocalizations(from localizationsArray: [String]) -> [String] {
        let cfLocalizations: CFArray? = CFBundleCopyPreferredLocalizationsFromArray(localizationsArray._cfObject)
        let nsLocalizations = __SwiftValue.fetch(cfLocalizations) as? [Any]
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
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let bundle = object as? Bundle else { return false }
        return CFEqual(_bundle, bundle._bundle)
    }
    
    open override var hash: Int {
        return Int(bitPattern: CFHash(_bundle))
    }
}


