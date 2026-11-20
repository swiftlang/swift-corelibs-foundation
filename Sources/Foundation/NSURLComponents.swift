// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@available(*, unavailable)
extension NSURLComponents : @unchecked Sendable { }

open class NSURLComponents: NSObject, NSCopying {
    private let _lock = NSLock()
    private var _storage: URLComponents

    internal var _components: URLComponents {
        get { _lock.synchronized { _storage } }
        set { _lock.synchronized { _storage = newValue } }
    }

    internal init(_components components: URLComponents) {
        _storage = components
        super.init()
    }

    open override func copy() -> Any {
        return copy(with: nil)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSURLComponents else { return false }
        return self === other || _components == other._components
    }

    open override var hash: Int {
        return _components.hashValue
    }

    open override var description: String {
        return _components.description
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        return NSURLComponents(_components: _components)
    }

    // Initialize a NSURLComponents with the components of a URL. If resolvingAgainstBaseURL is YES and url is a relative URL, the components of [url absoluteURL] are used. If the url string from the NSURL is malformed, nil is returned.
    public init?(url: URL, resolvingAgainstBaseURL resolve: Bool) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: resolve) else {
            return nil
        }
        _storage = components
        super.init()
    }

    // Initialize a NSURLComponents with a URL string. If the URLString is malformed, nil is returned.
    public init?(string URLString: String) {
        guard let components = URLComponents(string: URLString) else {
            return nil
        }
        _storage = components
        super.init()
    }

    public override init() {
        _storage = URLComponents()
        super.init()
    }

    // Returns a URL created from the NSURLComponents. If the NSURLComponents has an authority component (user, password, host or port) and a path component, then the path must either begin with "/" or be an empty string. If the NSURLComponents does not have an authority component (user, password, host or port) and has a path component, the path component must not start with "//". If those requirements are not met, nil is returned.
    open var url: URL? {
        return _components.url
    }

    // Returns a URL created from the NSURLComponents relative to a base URL. If the NSURLComponents has an authority component (user, password, host or port) and a path component, then the path must either begin with "/" or be an empty string. If the NSURLComponents does not have an authority component (user, password, host or port) and has a path component, the path component must not start with "//". If those requirements are not met, nil is returned.
    open func url(relativeTo baseURL: URL?) -> URL? {
        return _components.url(relativeTo: baseURL)
    }

    // Returns a URL string created from the NSURLComponents. If the NSURLComponents has an authority component (user, password, host or port) and a path component, then the path must either begin with "/" or be an empty string. If the NSURLComponents does not have an authority component (user, password, host or port) and has a path component, the path component must not start with "//". If those requirements are not met, nil is returned.
    open var string: String?  {
        return _components.string
    }

    // Warning: IETF STD 66 (rfc3986) says the use of the format "user:password" in the userinfo subcomponent of a URI is deprecated because passing authentication information in clear text has proven to be a security risk. However, there are cases where this practice is still needed, and so the user and password components and methods are provided.

    // Getting these properties removes any percent encoding these components may have (if the component allows percent encoding). Setting these properties assumes the subcomponent or component string is not percent encoded and will add percent encoding (if the component allows percent encoding).
    // Attempting to set the scheme with an invalid scheme string will cause an exception.
    open var scheme: String? {
        get { _components.scheme }
        set { _lock.synchronized { _storage.scheme = newValue } }
    }

    open var user: String? {
        get { _components.user }
        set { _lock.synchronized { _storage.user = newValue } }
    }

    open var password: String? {
        get { _components.password }
        set { _lock.synchronized { _storage.password = newValue } }
    }

    open var host: String? {
        get { _components.host }
        set { _lock.synchronized { _storage.host = newValue } }
    }

    // Attempting to set a negative port number will cause an exception.
    open var port: NSNumber? {
        get { _components.port.map { NSNumber(value: $0) } }
        set { _lock.synchronized { _storage.port = newValue?.intValue } }
    }

    open var path: String? {
        get { _components.path }
        set { _lock.synchronized { _storage.path = newValue ?? "" } }
    }

    open var query: String? {
        get { _components.query }
        set { _lock.synchronized { _storage.query = newValue } }
    }

    open var fragment: String? {
        get { _components.fragment }
        set { _lock.synchronized { _storage.fragment = newValue } }
    }


    // Getting these properties retains any percent encoding these components may have. Setting these properties assumes the component string is already correctly percent encoded. Attempting to set an incorrectly percent encoded string will cause an exception. Although ';' is a legal path character, it is recommended that it be percent-encoded for best compatibility with NSURL (-stringByAddingPercentEncodingWithAllowedCharacters: will percent-encode any ';' characters if you pass the urlPathAllowed).
    open var percentEncodedUser: String? {
        get { _components.percentEncodedUser }
        set { _lock.synchronized { _storage.percentEncodedUser = newValue } }
    }

    open var percentEncodedPassword: String? {
        get { _components.percentEncodedPassword }
        set { _lock.synchronized { _storage.percentEncodedPassword = newValue } }
    }

    open var percentEncodedHost: String? {
        get { _components.percentEncodedHost }
        set { _lock.synchronized { _storage.percentEncodedHost = newValue } }
    }

    open var percentEncodedPath: String? {
        get { _components.percentEncodedPath }
        set { _lock.synchronized { _storage.percentEncodedPath = newValue ?? "" } }
    }

    open var percentEncodedQuery: String? {
        get { _components.percentEncodedQuery }
        set { _lock.synchronized { _storage.percentEncodedQuery = newValue } }
    }

    open var percentEncodedFragment: String? {
        get { _components.percentEncodedFragment }
        set { _lock.synchronized { _storage.percentEncodedFragment = newValue } }
    }


    /* These properties return the character range of a component in the URL string returned by -[NSURLComponents string]. If the component does not exist in the NSURLComponents object, {NSNotFound, 0} is returned. Note: Zero length components are legal. For example, the URL string "scheme://:@/?#" has a zero length user, password, host, query and fragment; the URL strings "scheme:" and "" both have a zero length path.
    */
    private func _nsRange(_ keyPath: KeyPath<URLComponents, Range<String.Index>?>) -> NSRange {
        let components = _components
        guard let string = components.string, let range = components[keyPath: keyPath] else {
            return NSRange(location: NSNotFound, length: 0)
        }
        return NSRange(range, in: string)
    }

    open var rangeOfScheme: NSRange {
        return _nsRange(\.rangeOfScheme)
    }

    open var rangeOfUser: NSRange {
        return _nsRange(\.rangeOfUser)
    }

    open var rangeOfPassword: NSRange {
        return _nsRange(\.rangeOfPassword)
    }

    open var rangeOfHost: NSRange {
        return _nsRange(\.rangeOfHost)
    }

    open var rangeOfPort: NSRange {
        return _nsRange(\.rangeOfPort)
    }

    open var rangeOfPath: NSRange {
        return _nsRange(\.rangeOfPath)
    }

    open var rangeOfQuery: NSRange {
        return _nsRange(\.rangeOfQuery)
    }

    open var rangeOfFragment: NSRange {
        return _nsRange(\.rangeOfFragment)
    }

    // The getter method that underlies the queryItems property parses the query string based on these delimiters and returns an NSArray containing any number of NSURLQueryItem objects, each of which represents a single key-value pair, in the order in which they appear in the original query string.  Note that a name may appear more than once in a single query string, so the name values are not guaranteed to be unique. If the NSURLComponents object has an empty query component, queryItems returns an empty NSArray. If the NSURLComponents object has no query component, queryItems returns nil.
    // The setter method that underlies the queryItems property combines an NSArray containing any number of NSURLQueryItem objects, each of which represents a single key-value pair, into a query string and sets the NSURLComponents' query property. Passing an empty NSArray to setQueryItems sets the query component of the NSURLComponents object to an empty string. Passing nil to setQueryItems removes the query component of the NSURLComponents object.
    // Note: If a name-value pair in a query is empty (i.e. the query string starts with '&', ends with '&', or has "&&" within it), you get a NSURLQueryItem with a zero-length name and and a nil value. If a query's name-value pair has nothing before the equals sign, you get a zero-length name. If a query's name-value pair has nothing after the equals sign, you get a zero-length value. If a query's name-value pair has no equals sign, the query name-value pair string is the name and you get a nil value.
    open var queryItems: [URLQueryItem]? {
        get { _components.queryItems }
        set { _lock.synchronized { _storage.queryItems = newValue } }
    }

    open var percentEncodedQueryItems: [URLQueryItem]? {
        get { _components.percentEncodedQueryItems }
        set { _lock.synchronized { _storage.percentEncodedQueryItems = newValue } }
    }

}

extension NSURLComponents: _StructTypeBridgeable {
    public typealias _StructType = URLComponents

    public func _bridgeToSwift() -> _StructType {
        return _StructType._unconditionallyBridgeFromObjectiveC(self)
    }
}
