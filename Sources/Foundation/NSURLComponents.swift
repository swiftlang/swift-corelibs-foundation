// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_implementationOnly import CoreFoundation


open class NSURLComponents: NSObject, NSCopying {
    private let _componentsStorage: AnyObject!
    private var _components: CFURLComponents! { unsafeBitCast(_componentsStorage, to: CFURLComponents?.self) }

    open override func copy() -> Any {
        return copy(with: nil)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSURLComponents else { return false }
        return self === other
            || (scheme == other.scheme
                && user == other.user
                && password == other.password
                && host == other.host
                && port == other.port
                && path == other.path
                && query == other.query
                && fragment == other.fragment)
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(scheme)
        hasher.combine(user)
        hasher.combine(password)
        hasher.combine(host)
        hasher.combine(port)
        hasher.combine(path)
        hasher.combine(query)
        hasher.combine(fragment)
        return hasher.finalize()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = NSURLComponents()
        copy.scheme = self.scheme
        copy.user = self.user
        copy.password = self.password
        copy.host = self.host
        copy.port = self.port
        copy.path = self.path
        copy.query = self.query
        copy.fragment = self.fragment
        return copy
    }

    // Initialize a NSURLComponents with the components of a URL. If resolvingAgainstBaseURL is YES and url is a relative URL, the components of [url absoluteURL] are used. If the url string from the NSURL is malformed, nil is returned.
    public init?(url: URL, resolvingAgainstBaseURL resolve: Bool) {
        _componentsStorage = _CFURLComponentsCreateWithURL(kCFAllocatorSystemDefault, url._cfObject, resolve)
        super.init()
        if _componentsStorage == nil {
            return nil
        }
    }

    // Initialize a NSURLComponents with a URL string. If the URLString is malformed, nil is returned.
    public init?(string URLString: String) {
        _componentsStorage = _CFURLComponentsCreateWithString(kCFAllocatorSystemDefault, URLString._cfObject)
        super.init()
        if _componentsStorage == nil {
            return nil
        }
    }

    public override init() {
        _componentsStorage = _CFURLComponentsCreate(kCFAllocatorSystemDefault)
    }

    // Returns a URL created from the NSURLComponents. If the NSURLComponents has an authority component (user, password, host or port) and a path component, then the path must either begin with "/" or be an empty string. If the NSURLComponents does not have an authority component (user, password, host or port) and has a path component, the path component must not start with "//". If those requirements are not met, nil is returned.
    open var url: URL? {
        guard let result = _CFURLComponentsCopyURL(_components) else { return nil }
        return unsafeBitCast(result, to: URL.self)
    }

    // Returns a URL created from the NSURLComponents relative to a base URL. If the NSURLComponents has an authority component (user, password, host or port) and a path component, then the path must either begin with "/" or be an empty string. If the NSURLComponents does not have an authority component (user, password, host or port) and has a path component, the path component must not start with "//". If those requirements are not met, nil is returned.
    open func url(relativeTo baseURL: URL?) -> URL? {
        if let componentString = string {
            return URL(string: componentString, relativeTo: baseURL)
        }
        return nil
    }

    // Returns a URL string created from the NSURLComponents. If the NSURLComponents has an authority component (user, password, host or port) and a path component, then the path must either begin with "/" or be an empty string. If the NSURLComponents does not have an authority component (user, password, host or port) and has a path component, the path component must not start with "//". If those requirements are not met, nil is returned.
    open var string: String?  {
        return _CFURLComponentsCopyString(_components)?._swiftObject
    }

    // Warning: IETF STD 66 (rfc3986) says the use of the format "user:password" in the userinfo subcomponent of a URI is deprecated because passing authentication information in clear text has proven to be a security risk. However, there are cases where this practice is still needed, and so the user and password components and methods are provided.

    // Getting these properties removes any percent encoding these components may have (if the component allows percent encoding). Setting these properties assumes the subcomponent or component string is not percent encoded and will add percent encoding (if the component allows percent encoding).
    // Attempting to set the scheme with an invalid scheme string will cause an exception.
    open var scheme: String? {
        get {
            return _CFURLComponentsCopyScheme(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetScheme(_components, new?._cfObject) {
                fatalError()
            }
        }
    }

    open var user: String? {
        get {
            return _CFURLComponentsCopyUser(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetUser(_components, new?._cfObject) {
                fatalError()
            }
        }
    }

    open var password: String? {
        get {
            return _CFURLComponentsCopyPassword(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPassword(_components, new?._cfObject) {
                fatalError()
            }
        }
    }

    open var host: String? {
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
    open var port: NSNumber? {
        get {
            if let result = _CFURLComponentsCopyPort(_components) {
                return unsafeBitCast(result, to: NSNumber.self)
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

    open var path: String? {
        get {
            return _CFURLComponentsCopyPath(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPath(_components, new?._cfObject) {
                fatalError()
            }
        }
    }

    open var query: String? {
        get {
            return _CFURLComponentsCopyQuery(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetQuery(_components, new?._cfObject) {
                fatalError()
            }
        }
    }

    open var fragment: String? {
        get {
            return _CFURLComponentsCopyFragment(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetFragment(_components, new?._cfObject) {
                fatalError()
            }
        }
    }


    // Getting these properties retains any percent encoding these components may have. Setting these properties assumes the component string is already correctly percent encoded. Attempting to set an incorrectly percent encoded string will cause an exception. Although ';' is a legal path character, it is recommended that it be percent-encoded for best compatibility with NSURL (-stringByAddingPercentEncodingWithAllowedCharacters: will percent-encode any ';' characters if you pass the urlPathAllowed).
    open var percentEncodedUser: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedUser(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedUser(_components, new?._cfObject) {
                fatalError()
            }
        }
    }

    open var percentEncodedPassword: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedPassword(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedPassword(_components, new?._cfObject) {
                fatalError()
            }
        }
    }

    open var percentEncodedHost: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedHost(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedHost(_components, new?._cfObject) {
                fatalError()
            }
        }
    }

    open var percentEncodedPath: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedPath(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedPath(_components, new?._cfObject) {
                fatalError()
            }
        }
    }

    open var percentEncodedQuery: String? {
        get {
            return _CFURLComponentsCopyPercentEncodedQuery(_components)?._swiftObject
        }
        set(new) {
            if !_CFURLComponentsSetPercentEncodedQuery(_components, new?._cfObject) {
                fatalError()
            }
        }
    }

    open var percentEncodedFragment: String? {
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
    open var rangeOfScheme: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfScheme(_components))
    }

    open var rangeOfUser: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfUser(_components))
    }

    open var rangeOfPassword: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfPassword(_components))
    }

    open var rangeOfHost: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfHost(_components))
    }

    open var rangeOfPort: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfPort(_components))
    }

    open var rangeOfPath: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfPath(_components))
    }

    open var rangeOfQuery: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfQuery(_components))
    }

    open var rangeOfFragment: NSRange {
        return NSRange(_CFURLComponentsGetRangeOfFragment(_components))
    }

    // The getter method that underlies the queryItems property parses the query string based on these delimiters and returns an NSArray containing any number of NSURLQueryItem objects, each of which represents a single key-value pair, in the order in which they appear in the original query string.  Note that a name may appear more than once in a single query string, so the name values are not guaranteed to be unique. If the NSURLComponents object has an empty query component, queryItems returns an empty NSArray. If the NSURLComponents object has no query component, queryItems returns nil.
    // The setter method that underlies the queryItems property combines an NSArray containing any number of NSURLQueryItem objects, each of which represents a single key-value pair, into a query string and sets the NSURLComponents' query property. Passing an empty NSArray to setQueryItems sets the query component of the NSURLComponents object to an empty string. Passing nil to setQueryItems removes the query component of the NSURLComponents object.
    // Note: If a name-value pair in a query is empty (i.e. the query string starts with '&', ends with '&', or has "&&" within it), you get a NSURLQueryItem with a zero-length name and and a nil value. If a query's name-value pair has nothing before the equals sign, you get a zero-length name. If a query's name-value pair has nothing after the equals sign, you get a zero-length value. If a query's name-value pair has no equals sign, the query name-value pair string is the name and you get a nil value.
    open var queryItems: [URLQueryItem]? {
        get {
            // This CFURL implementation returns a CFArray of CFDictionary; each CFDictionary has an entry for name and optionally an entry for value
            guard let queryArray = _CFURLComponentsCopyQueryItems(_components) else {
                return nil
            }

            let count = CFArrayGetCount(queryArray)
            return (0..<count).map { idx in
                let oneEntry = unsafeBitCast(CFArrayGetValueAtIndex(queryArray, idx), to: NSDictionary.self)
                let swiftEntry = oneEntry._swiftObject
                let entryName = swiftEntry["name"] as! String
                let entryValue = swiftEntry["value"] as? String
                return URLQueryItem(name: entryName, value: entryValue)
            }
        }
        set(new) {
            guard let new = new else {
                self.percentEncodedQuery = nil
                return
            }

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
        }
    }
}

extension NSURLComponents: _StructTypeBridgeable {
    public typealias _StructType = URLComponents

    public func _bridgeToSwift() -> _StructType {
        return _StructType._unconditionallyBridgeFromObjectiveC(self)
    }
}
