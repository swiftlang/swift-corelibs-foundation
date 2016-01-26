// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

#if os(OSX) || os(iOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

#if os(OSX) || os(iOS)
internal let kCFURLPOSIXPathStyle = CFURLPathStyle.CFURLPOSIXPathStyle
internal let kCFURLWindowsPathStyle = CFURLPathStyle.CFURLWindowsPathStyle
#endif

private func _standardizedPath(path: String) -> String {
    if !path.absolutePath {
        return path._nsObject.stringByStandardizingPath
    }
    return path
}

public class NSURL : NSObject, NSSecureCoding, NSCopying {
    typealias CFType = CFURLRef
    internal var _base = _CFInfo(typeID: CFURLGetTypeID())
    internal var _flags : UInt32 = 0
    internal var _encoding : CFStringEncoding = 0
    internal var _string : UnsafeMutablePointer<CFString> = nil
    internal var _baseURL : UnsafeMutablePointer<CFURL> = nil
    internal var _extra : COpaquePointer = nil
    internal var _resourceInfo : COpaquePointer = nil
    internal var _range1 = NSRange(location: 0, length: 0)
    internal var _range2 = NSRange(location: 0, length: 0)
    internal var _range3 = NSRange(location: 0, length: 0)
    internal var _range4 = NSRange(location: 0, length: 0)
    internal var _range5 = NSRange(location: 0, length: 0)
    internal var _range6 = NSRange(location: 0, length: 0)
    internal var _range7 = NSRange(location: 0, length: 0)
    internal var _range8 = NSRange(location: 0, length: 0)
    internal var _range9 = NSRange(location: 0, length: 0)
    
    
    internal var _cfObject : CFType {
        if self.dynamicType === NSURL.self {
            return unsafeBitCast(self, CFType.self)
        } else {
            return CFURLCreateWithString(kCFAllocatorSystemDefault, relativeString._cfObject, self.baseURL?._cfObject)
        }
    }
    
    public override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    public override func isEqual(object: AnyObject?) -> Bool {
        if let url = object as? NSURL {
            return CFEqual(_cfObject, url._cfObject)
        } else {
            return false
        }
    }
    
    public override var description: String {
        return CFCopyDescription(_cfObject)._swiftObject
    }

    deinit {
        _CFDeinit(self)
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    static public func supportsSecureCoding() -> Bool {
        return true
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if aDecoder.allowsKeyedCoding {
            let base = aDecoder.decodeObjectOfClass(NSURL.self, forKey:"NS.base")
            let relative = aDecoder.decodeObjectOfClass(NSString.self, forKey:"NS.relative")

            if relative == nil {
                return nil
            }
            
            self.init(string: relative!.bridge(), relativeToURL: base)
        } else {
            NSUnimplemented()
        }
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
	if aCoder.allowsKeyedCoding {
            aCoder.encodeObject(self.baseURL, forKey:"NS.base")
            aCoder.encodeObject(self.relativeString.bridge(), forKey:"NS.relative")
	} else {
            NSUnimplemented()
        }
    }
    
    internal init(fileURLWithPath path: String, isDirectory isDir: Bool, relativeToURL baseURL: NSURL?) {
        super.init()
        let thePath = _standardizedPath(path)
        if thePath.length > 0 {
            
            _CFURLInitWithFileSystemPathRelativeToBase(_cfObject, thePath._cfObject, kCFURLPOSIXPathStyle, isDir, baseURL?._cfObject)
        } else if let baseURL = baseURL, let path = baseURL.path {
            _CFURLInitWithFileSystemPathRelativeToBase(_cfObject, path._cfObject, kCFURLPOSIXPathStyle, baseURL.hasDirectoryPath, nil)
        }
    }
    
    public convenience init(fileURLWithPath path: String, relativeToURL baseURL: NSURL?) {
        let thePath = _standardizedPath(path)
        
        var isDir : Bool = false
        if thePath.hasSuffix("/") {
            isDir = true
        } else {
            let absolutePath: String
            if let absPath = baseURL?.URLByAppendingPathComponent(path)?.path {
                absolutePath = absPath
            } else {
                absolutePath = path
            }
            NSFileManager.defaultManager().fileExistsAtPath(absolutePath, isDirectory: &isDir)
        }

        self.init(fileURLWithPath: thePath, isDirectory: isDir, relativeToURL: baseURL)
    }
    
    public convenience init(fileURLWithPath path: String, isDirectory isDir: Bool) {
        self.init(fileURLWithPath: path, isDirectory: isDir, relativeToURL: nil)
    }
    
    public convenience init(fileURLWithPath path: String) {
        let thePath = _standardizedPath(path)
        
        var isDir : Bool = false
        if thePath.hasSuffix("/") {
            isDir = true
        } else {
            NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir)
        }

        self.init(fileURLWithPath: thePath, isDirectory: isDir, relativeToURL: nil)
    }
    
    public convenience init(fileURLWithFileSystemRepresentation path: UnsafePointer<Int8>, isDirectory isDir: Bool, relativeToURL baseURL: NSURL?) {
        let pathString = String.fromCString(path)!
        self.init(fileURLWithPath: pathString, isDirectory: isDir, relativeToURL: baseURL)
    }
    
    public convenience init?(string URLString: String) {
        self.init(string: URLString, relativeToURL:nil)
    }
    
    public init?(string URLString: String, relativeToURL baseURL: NSURL?) {
        super.init()
        if !_CFURLInitWithURLString(_cfObject, URLString._cfObject, true, baseURL?._cfObject) {
            return nil
        }
    }
    
    public init(dataRepresentation data: NSData, relativeToURL baseURL: NSURL?) {
        super.init()
        // _CFURLInitWithURLString does not fail if checkForLegalCharacters == false
        if let str = CFStringCreateWithBytes(kCFAllocatorSystemDefault, UnsafePointer(data.bytes), data.length, CFStringEncoding(kCFStringEncodingUTF8), false) {
            _CFURLInitWithURLString(_cfObject, str, false, baseURL?._cfObject)
        } else if let str = CFStringCreateWithBytes(kCFAllocatorSystemDefault, UnsafePointer(data.bytes), data.length, CFStringEncoding(kCFStringEncodingISOLatin1), false) {
            _CFURLInitWithURLString(_cfObject, str, false, baseURL?._cfObject)
        } else {
            fatalError()
        }
    }
    
    public init(absoluteURLWithDataRepresentation data: NSData, relativeToURL baseURL: NSURL?) {
        super.init()
        if _CFURLInitAbsoluteURLWithBytes(_cfObject, UnsafePointer(data.bytes), data.length, CFStringEncoding(kCFStringEncodingUTF8), baseURL?._cfObject) {
            return
        }
        if _CFURLInitAbsoluteURLWithBytes(_cfObject, UnsafePointer(data.bytes), data.length, CFStringEncoding(kCFStringEncodingISOLatin1), baseURL?._cfObject) {
            return
        }
        fatalError()
    }
    
    /* Returns the data representation of the URL's relativeString. If the URL was initialized with -initWithData:relativeToURL:, the data representation returned are the same bytes as those used at initialization; otherwise, the data representation returned are the bytes of the relativeString encoded with NSUTF8StringEncoding.
    */
    public var dataRepresentation: NSData {
        let bytesNeeded = CFURLGetBytes(_cfObject, nil, 0)
        assert(bytesNeeded > 0)
        
        let buffer = malloc(bytesNeeded)
        let bytesFilled = CFURLGetBytes(_cfObject, UnsafeMutablePointer<UInt8>(buffer), bytesNeeded)
        if bytesFilled == bytesNeeded {
            return NSData(bytesNoCopy: buffer, length: bytesNeeded, freeWhenDone: true)
        } else {
            fatalError()
        }
    }
    
    public var absoluteString: String? {
        if let absURL = CFURLCopyAbsoluteURL(_cfObject) {
            return CFURLGetString(absURL)._swiftObject
        } else {
            return nil
        }
    }
    
    // The relative portion of a URL.  If baseURL is nil, or if the receiver is itself absolute, this is the same as absoluteString
    public var relativeString: String {
        return CFURLGetString(_cfObject)._swiftObject
    }
    
    public var baseURL: NSURL? {
        return CFURLGetBaseURL(_cfObject)?._nsObject
    }
    
    // if the receiver is itself absolute, this will return self.
    public var absoluteURL: NSURL? {
        return CFURLCopyAbsoluteURL(_cfObject)?._nsObject
    }
    
    /* Any URL is composed of these two basic pieces.  The full URL would be the concatenation of [myURL scheme], ':', [myURL resourceSpecifier]
    */
    public var scheme: String? {
        return CFURLCopyScheme(_cfObject)?._swiftObject
    }
    
    internal var _isAbsolute : Bool {
        return self.baseURL == nil && self.scheme != nil
    }
    
    public var resourceSpecifier: String? {
        // Note that this does NOT have the same meaning as CFURL's resource specifier, which, for decomposeable URLs is merely that portion of the URL which comes after the path.  NSURL means everything after the scheme.
        if !_isAbsolute {
            return self.relativeString
        } else {
            let cf = _cfObject
            guard CFURLCanBeDecomposed(cf) else {
                return CFURLCopyResourceSpecifier(cf)?._swiftObject
            }
            guard baseURL == nil else {
                return CFURLGetString(cf)?._swiftObject
            }
            
            let netLoc = CFURLCopyNetLocation(cf)?._swiftObject
            let path = CFURLCopyPath(cf)?._swiftObject
            let theRest = CFURLCopyResourceSpecifier(cf)?._swiftObject
            
            if let netLoc = netLoc {
                let p = path ?? ""
                let rest = theRest ?? ""
                return "//\(netLoc)\(p)\(rest)"
            } else if let path = path {
                let rest = theRest ?? ""
                return "\(path)\(rest)"
            } else {
                return theRest
            }
        }
    }
    
    /* If the URL conforms to rfc 1808 (the most common form of URL), the following accessors will return the various components; otherwise they return nil.  The litmus test for conformance is as recommended in RFC 1808 - whether the first two characters of resourceSpecifier is @"//".  In all cases, they return the component's value after resolving the receiver against its base URL.
    */
    public var host: String? {
        return CFURLCopyHostName(_cfObject)?._swiftObject
    }
    
    public var port: NSNumber? {
        let port = CFURLGetPortNumber(_cfObject)
        if port == -1 {
            return nil
        } else {
            return NSNumber(int: port)
        }
    }
    
    public var user: String? {
        return CFURLCopyUserName(_cfObject)?._swiftObject
    }
    
    public var password: String? {
        let absoluteURL = CFURLCopyAbsoluteURL(_cfObject)
#if os(Linux)
        let passwordRange = CFURLGetByteRangeForComponent(absoluteURL, kCFURLComponentPassword, nil)
#else
        let passwordRange = CFURLGetByteRangeForComponent(absoluteURL, .Password, nil)
#endif
        guard passwordRange.location != kCFNotFound else {
            return nil
        }
        
        // For historical reasons, the password string should _not_ have its percent escapes removed.
        let bufSize = CFURLGetBytes(absoluteURL, nil, 0)
        var buf = [UInt8](count: bufSize, repeatedValue: 0)
        guard CFURLGetBytes(absoluteURL, &buf, bufSize) >= 0 else {
            return nil
        }
        
        let passwordBuf = buf[passwordRange.location ..< passwordRange.location+passwordRange.length]
        return passwordBuf.withUnsafeBufferPointer { ptr in
            NSString(bytes: ptr.baseAddress, length: passwordBuf.count, encoding: NSUTF8StringEncoding)?._swiftObject
        }
    }
    
    public var path: String? {
        let absURL = CFURLCopyAbsoluteURL(_cfObject)
        return CFURLCopyFileSystemPath(absURL, kCFURLPOSIXPathStyle)?._swiftObject
    }
    
    public var fragment: String? {
        return CFURLCopyFragment(_cfObject, nil)?._swiftObject
    }
    
    public var parameterString: String? {
        return CFURLCopyParameterString(_cfObject, nil)?._swiftObject
    }
    
    public var query: String? {
        return CFURLCopyQueryString(_cfObject, nil)?._swiftObject
    }
    
    // The same as path if baseURL is nil
    public var relativePath: String? {
        return CFURLCopyFileSystemPath(_cfObject, kCFURLPOSIXPathStyle)?._swiftObject
    }
    
    /* Determines if a given URL string's path represents a directory (i.e. the path component in the URL string ends with a '/' character). This does not check the resource the URL refers to.
    */
    public var hasDirectoryPath: Bool {
        return CFURLHasDirectoryPath(_cfObject)
    }
    
    /* Returns the URL's path in file system representation. File system representation is a null-terminated C string with canonical UTF-8 encoding.
    */
    public func getFileSystemRepresentation(buffer: UnsafeMutablePointer<Int8>, maxLength maxBufferLength: Int) -> Bool {
        return CFURLGetFileSystemRepresentation(_cfObject, true, UnsafeMutablePointer<UInt8>(buffer), maxBufferLength)
    }
    
    /* Returns the URL's path in file system representation. File system representation is a null-terminated C string with canonical UTF-8 encoding. The returned C string will be automatically freed just as a returned object would be released; your code should copy the representation or use getFileSystemRepresentation:maxLength: if it needs to store the representation outside of the autorelease context in which the representation is created.
    */
    
    // Memory leak. See https://github.com/apple/swift-corelibs-foundation/blob/master/Docs/Issues.md
    public var fileSystemRepresentation: UnsafePointer<Int8> {
        
        let bufSize = Int(PATH_MAX + 1)
        
        let _fsrBuffer = UnsafeMutablePointer<Int8>.alloc(bufSize)
        for i in 0..<bufSize {
            _fsrBuffer.advancedBy(i).initialize(0)
        }
        
        if getFileSystemRepresentation(_fsrBuffer, maxLength: bufSize) {
            return UnsafePointer(_fsrBuffer)
        }

        return nil
    }
    
    // Whether the scheme is file:; if [myURL isFileURL] is YES, then [myURL path] is suitable for input into NSFileManager or NSPathUtilities.
    public var fileURL: Bool {
        return _CFURLIsFileURL(_cfObject)
    }
    
    /* A string constant for the "file" URL scheme. If you are using this to compare to a URL's scheme to see if it is a file URL, you should instead use the NSURL fileURL property -- the fileURL property is much faster. */
    public var standardizedURL: NSURL? {
        NSUnimplemented()
    }
    
    /* Returns whether the URL's resource exists and is reachable. This method synchronously checks if the resource's backing store is reachable. Checking reachability is appropriate when making decisions that do not require other immediate operations on the resource, e.g. periodic maintenance of UI state that depends on the existence of a specific document. When performing operations such as opening a file or copying resource properties, it is more efficient to simply try the operation and handle failures. If this method returns NO, the optional error is populated. This method is currently applicable only to URLs for file system resources. For other URL types, NO is returned. Symbol is present in iOS 4, but performs no operation.
    */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public func resourceIsReachable() throws -> Bool {
        NSUnimplemented()
    }

    /* Returns a file path URL that refers to the same resource as a specified URL. File path URLs use a file system style path. An error will occur if the url parameter is not a file URL. A file reference URL's resource must exist and be reachable to be converted to a file path URL. Symbol is present in iOS 4, but performs no operation.
    */
    public var filePathURL: NSURL? {
        NSUnimplemented()
    }
    
    override public var _cfTypeID: CFTypeID {
        return CFURLGetTypeID()
    }
}

extension NSCharacterSet {
    
    // Predefined character sets for the six URL components and subcomponents which allow percent encoding. These character sets are passed to -stringByAddingPercentEncodingWithAllowedCharacters:.
    
    // Returns a character set containing the characters allowed in an URL's user subcomponent.
    public class func URLUserAllowedCharacterSet() -> NSCharacterSet {
        return _CFURLComponentsGetURLUserAllowedCharacterSet()._nsObject
    }
    
    // Returns a character set containing the characters allowed in an URL's password subcomponent.
    public class func URLPasswordAllowedCharacterSet() -> NSCharacterSet {
        return _CFURLComponentsGetURLPasswordAllowedCharacterSet()._nsObject
    }
    
    // Returns a character set containing the characters allowed in an URL's host subcomponent.
    public class func URLHostAllowedCharacterSet() -> NSCharacterSet {
        return _CFURLComponentsGetURLHostAllowedCharacterSet()._nsObject
    }
    
    // Returns a character set containing the characters allowed in an URL's path component. ';' is a legal path character, but it is recommended that it be percent-encoded for best compatibility with NSURL (-stringByAddingPercentEncodingWithAllowedCharacters: will percent-encode any ';' characters if you pass the URLPathAllowedCharacterSet).
    public class func URLPathAllowedCharacterSet() -> NSCharacterSet {
        return _CFURLComponentsGetURLPathAllowedCharacterSet()._nsObject
    }
    
    // Returns a character set containing the characters allowed in an URL's query component.
    public class func URLQueryAllowedCharacterSet() -> NSCharacterSet {
        return _CFURLComponentsGetURLQueryAllowedCharacterSet()._nsObject
    }
    
    // Returns a character set containing the characters allowed in an URL's fragment component.
    public class func URLFragmentAllowedCharacterSet() -> NSCharacterSet {
        return _CFURLComponentsGetURLFragmentAllowedCharacterSet()._nsObject
    }
}

extension NSString {
    
    // Returns a new string made from the receiver by replacing all characters not in the allowedCharacters set with percent encoded characters. UTF-8 encoding is used to determine the correct percent encoded characters. Entire URL strings cannot be percent-encoded. This method is intended to percent-encode an URL component or subcomponent string, NOT the entire URL string. Any characters in allowedCharacters outside of the 7-bit ASCII range are ignored.
    public func stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters: NSCharacterSet) -> String? {
        return _CFStringCreateByAddingPercentEncodingWithAllowedCharacters(kCFAllocatorSystemDefault, self._cfObject, allowedCharacters._cfObject)._swiftObject
    }
    
    // Returns a new string made from the receiver by replacing all percent encoded sequences with the matching UTF-8 characters.
    public var stringByRemovingPercentEncoding: String? {
        return _CFStringCreateByRemovingPercentEncoding(kCFAllocatorSystemDefault, self._cfObject)._swiftObject
    }
}

extension NSURL {
    
    /* The following methods work on the path portion of a URL in the same manner that the NSPathUtilities methods on NSString do.
    */
    public class func fileURLWithPathComponents(components: [String]) -> NSURL? {
        let path = NSString.pathWithComponents(components)
        if components.last == "/" {
            return NSURL(fileURLWithPath: path, isDirectory: true)
        } else {
            return NSURL(fileURLWithPath: path)
        }
    }

    public var pathComponents: [String]? {
        return self.path?.pathComponents
    }
    
    public var lastPathComponent: String? {
        return self.path?.lastPathComponent
    }
    
    public var pathExtension: String? {
        return self.path?.pathExtension
    }
    
    public func URLByAppendingPathComponent(pathComponent: String) -> NSURL? {
        var result : NSURL? = URLByAppendingPathComponent(pathComponent, isDirectory: false)
        if !pathComponent.hasSuffix("/") && fileURL {
            if let urlWithoutDirectory = result, path = urlWithoutDirectory.path {
                var isDir : Bool = false
                if NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isDir) && isDir {
                    result = self.URLByAppendingPathComponent(pathComponent, isDirectory: true)
                }
            }
    
        }
        return result
    }
    
    public func URLByAppendingPathComponent(pathComponent: String, isDirectory: Bool) -> NSURL? {
        return CFURLCreateCopyAppendingPathComponent(kCFAllocatorSystemDefault, _cfObject, pathComponent._cfObject, isDirectory)?._nsObject
    }
    
    public var URLByDeletingLastPathComponent: NSURL? {
        return CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorSystemDefault, _cfObject)?._nsObject
    }
    
    public func URLByAppendingPathExtension(pathExtension: String) -> NSURL? {
        return CFURLCreateCopyAppendingPathExtension(kCFAllocatorSystemDefault, _cfObject, pathExtension._cfObject)?._nsObject
    }
    
    public var URLByDeletingPathExtension: NSURL? {
        return CFURLCreateCopyDeletingPathExtension(kCFAllocatorSystemDefault, _cfObject)?._nsObject
    }
    
    /* The following methods work only on `file:` scheme URLs; for non-`file:` scheme URLs, these methods return the URL unchanged.
    */
    public var URLByStandardizingPath: NSURL? {
        // Documentation says it should expand initial tilde, but it does't do this on OS X.
        // In remaining cases it works just like URLByResolvingSymlinksInPath.
        return URLByResolvingSymlinksInPath
    }
    
    public var URLByResolvingSymlinksInPath: NSURL? {
        return _resolveSymlinksInPath(excludeSystemDirs: true)
    }
    
    internal func _resolveSymlinksInPath(excludeSystemDirs excludeSystemDirs: Bool) -> NSURL? {
        guard fileURL else {
            return NSURL(string: absoluteString!)
        }
        
        guard let selfPath = path else {
            return NSURL(string: absoluteString!)
        }
        
        let absolutePath: String
        if selfPath.hasPrefix("/") {
            absolutePath = selfPath
        } else {
            let workingDir = NSFileManager.defaultManager().currentDirectoryPath
            absolutePath = workingDir.bridge().stringByAppendingPathComponent(selfPath)
        }
        
        var components = absolutePath.pathComponents
        guard !components.isEmpty else {
            return NSURL(string: absoluteString!)
        }
        
        var resolvedPath = components.removeFirst()
        for component in components {
            switch component {
                
            case "", ".":
                break
                
            case "..":
                resolvedPath = resolvedPath.bridge().stringByDeletingLastPathComponent
                
            default:
                resolvedPath = resolvedPath.bridge().stringByAppendingPathComponent(component)
                if let destination = NSFileManager.defaultManager()._tryToResolveTrailingSymlinkInPath(resolvedPath) {
                    resolvedPath = destination
                }
            }
        }
        
        // It might be a responsibility of NSURL(fileURLWithPath:). Check it.
        var isExistingDirectory = false
        NSFileManager.defaultManager().fileExistsAtPath(resolvedPath, isDirectory: &isExistingDirectory)
        
        if excludeSystemDirs {
            resolvedPath = resolvedPath._tryToRemovePathPrefix("/private") ?? resolvedPath
        }
        
        if isExistingDirectory && !resolvedPath.hasSuffix("/") {
            resolvedPath += "/"
        }
        
        return NSURL(fileURLWithPath: resolvedPath)
    }
}

// NSURLQueryItem encapsulates a single query name-value pair. The name and value strings of a query name-value pair are not percent encoded. For use with the NSURLComponents queryItems property.
public class NSURLQueryItem : NSObject, NSSecureCoding, NSCopying {
    public init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public let name: String
    public let value: String?
}

public class NSURLComponents : NSObject, NSCopying {
    private let _components : CFURLComponentsRef!
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    // Initialize a NSURLComponents with the components of a URL. If resolvingAgainstBaseURL is YES and url is a relative URL, the components of [url absoluteURL] are used. If the url string from the NSURL is malformed, nil is returned.
    public init?(URL url: NSURL, resolvingAgainstBaseURL resolve: Bool) {
        _components = _CFURLComponentsCreateWithURL(kCFAllocatorSystemDefault, url._cfObject, resolve)
        super.init()
        if _components == nil {
            return nil
        }
    }
    
    // Initialize a NSURLComponents with a URL string. If the URLString is malformed, nil is returned.
    public init?(string URLString: String) {
        _components = _CFURLComponentsCreateWithString(kCFAllocatorSystemDefault, URLString._cfObject)
        super.init()
        if _components == nil {
            return nil
        }
    }
    
    public override init() {
        _components = _CFURLComponentsCreate(kCFAllocatorSystemDefault)
    }
    
    // Returns a URL created from the NSURLComponents. If the NSURLComponents has an authority component (user, password, host or port) and a path component, then the path must either begin with "/" or be an empty string. If the NSURLComponents does not have an authority component (user, password, host or port) and has a path component, the path component must not start with "//". If those requirements are not met, nil is returned.
    public var URL: NSURL? {
        guard let result = _CFURLComponentsCopyURL(_components) else { return nil }
        return unsafeBitCast(result, NSURL.self)
    }
    
    // Returns a URL created from the NSURLComponents relative to a base URL. If the NSURLComponents has an authority component (user, password, host or port) and a path component, then the path must either begin with "/" or be an empty string. If the NSURLComponents does not have an authority component (user, password, host or port) and has a path component, the path component must not start with "//". If those requirements are not met, nil is returned.
    public func URLRelativeToURL(baseURL: NSURL?) -> NSURL? {
        NSUnimplemented()
    }
    
    // Returns a URL string created from the NSURLComponents. If the NSURLComponents has an authority component (user, password, host or port) and a path component, then the path must either begin with "/" or be an empty string. If the NSURLComponents does not have an authority component (user, password, host or port) and has a path component, the path component must not start with "//". If those requirements are not met, nil is returned.
    public var string: String?  {
        return _CFURLComponentsCopyString(_components)?._swiftObject
    }
    
    // Warning: IETF STD 66 (rfc3986) says the use of the format "user:password" in the userinfo subcomponent of a URI is deprecated because passing authentication information in clear text has proven to be a security risk. However, there are cases where this practice is still needed, and so the user and password components and methods are provided.
    
    // Getting these properties removes any percent encoding these components may have (if the component allows percent encoding). Setting these properties assumes the subcomponent or component string is not percent encoded and will add percent encoding (if the component allows percent encoding).
    // Attempting to set the scheme with an invalid scheme string will cause an exception.
    public var scheme: String? {
        get {
            return _CFURLComponentsCopyScheme(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetScheme(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var user: String? {
        get {
            return _CFURLComponentsCopyUser(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetUser(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var password: String? {
        get {
            return _CFURLComponentsCopyPassword(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPassword(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var host: String? {
        get {
            return _CFURLComponentsCopyHost(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetHost(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    // Attempting to set a negative port number will cause an exception.
    public var port: NSNumber? {
        get {
            if let result = _CFURLComponentsCopyPort(_components) {
                return unsafeBitCast(result, NSNumber.self)
            } else {
                return nil
            }
        }
        set(new) {
            if !_CFURLComponentsSetPort(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var path: String? {
        get {
            return _CFURLComponentsCopyPath(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPath(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var query: String? {
        get {
            return _CFURLComponentsCopyQuery(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetQuery(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var fragment: String? {
        get {
            return _CFURLComponentsCopyFragment(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetFragment(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    
    // Getting these properties retains any percent encoding these components may have. Setting these properties assumes the component string is already correctly percent encoded. Attempting to set an incorrectly percent encoded string will cause an exception. Although ';' is a legal path character, it is recommended that it be percent-encoded for best compatibility with NSURL (-stringByAddingPercentEncodingWithAllowedCharacters: will percent-encode any ';' characters if you pass the URLPathAllowedCharacterSet).
    public var percentEncodedUser: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedUser(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedUser(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var percentEncodedPassword: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedPassword(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedPassword(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var percentEncodedHost: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedHost(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedHost(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var percentEncodedPath: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedPath(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedPath(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var percentEncodedQuery: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedQuery(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedQuery(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    public var percentEncodedFragment: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedFragment(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedFragment(_components, new?._cfObject) {
                fatalError()
            }
        }
    }
    
    
    /* These properties return the character range of a component in the URL string returned by -[NSURLComponents string]. If the component does not exist in the NSURLComponents object, {NSNotFound, 0} is returned. Note: Zero length components are legal. For example, the URL string "scheme://:@/?#" has a zero length user, password, host, query and fragment; the URL strings "scheme:" and "" both have a zero length path.
    */
    public var rangeOfScheme: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfScheme(_components))
    }
    
    public var rangeOfUser: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfUser(_components))
    }
    
    public var rangeOfPassword: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfPassword(_components))
    }
    
    public var rangeOfHost: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfHost(_components))
    }
    
    public var rangeOfPort: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfPort(_components))
    }
    
    public var rangeOfPath: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfPath(_components))
    }
    
    public var rangeOfQuery: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfQuery(_components))
    }
    
    public var rangeOfFragment: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfFragment(_components))
    }
    
    // The getter method that underlies the queryItems property parses the query string based on these delimiters and returns an NSArray containing any number of NSURLQueryItem objects, each of which represents a single key-value pair, in the order in which they appear in the original query string.  Note that a name may appear more than once in a single query string, so the name values are not guaranteed to be unique. If the NSURLComponents object has an empty query component, queryItems returns an empty NSArray. If the NSURLComponents object has no query component, queryItems returns nil.
    // The setter method that underlies the queryItems property combines an NSArray containing any number of NSURLQueryItem objects, each of which represents a single key-value pair, into a query string and sets the NSURLComponents' query property. Passing an empty NSArray to setQueryItems sets the query component of the NSURLComponents object to an empty string. Passing nil to setQueryItems removes the query component of the NSURLComponents object.
    // Note: If a name-value pair in a query is empty (i.e. the query string starts with '&', ends with '&', or has "&&" within it), you get a NSURLQueryItem with a zero-length name and and a nil value. If a query's name-value pair has nothing before the equals sign, you get a zero-length name. If a query's name-value pair has nothing after the equals sign, you get a zero-length value. If a query's name-value pair has no equals sign, the query name-value pair string is the name and you get a nil value.
    public var queryItems: [NSURLQueryItem]? {
        get {
            // This CFURL implementation returns a CFArray of CFDictionary; each CFDictionary has an entry for name and optionally an entry for value
            if let queryArray = _CFURLComponentsCopyQueryItems(_components) {
                let count = CFArrayGetCount(queryArray)
                
                return (0..<count).map { idx in
                    let oneEntry = unsafeBitCast(CFArrayGetValueAtIndex(queryArray, idx), NSDictionary.self)
                    let entryName = oneEntry.objectForKey("name"._cfObject) as! String
                    let entryValue = oneEntry.objectForKey("value"._cfObject) as? String
                    return NSURLQueryItem(name: entryName, value: entryValue)
                }
            } else {
                return nil
            }
        }
        set(new) {
            if let new = new {
                // The CFURL implementation requires two CFArrays, one for names and one for values
                var names = [CFTypeRef]()
                var values = [CFTypeRef]()
                for entry in new {
                    names.append(entry.name._cfObject)
                    if let v = entry.value {
                        values.append(v._cfObject)
                    } else {
                        values.append(kCFNull)
                    }
                }
                _CFURLComponentsSetQueryItems(_components, names._cfObject, values._cfObject)
            } else {
                self.percentEncodedQuery = nil
            }
        }
    }
}

extension NSURL : _CFBridgable { }

extension CFURLRef : _NSBridgable {
    typealias NSType = NSURL
    internal var _nsObject: NSType { return unsafeBitCast(self, NSType.self) }
}

