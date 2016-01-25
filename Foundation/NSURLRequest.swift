// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/*!
    @header NSURLRequest.h

    This header file describes the constructs used to represent URL
    load requests in a manner independent of protocol and URL scheme.
    Immutable and mutable variants of this URL load request concept
    are described, named NSURLRequest and NSMutableURLRequest,
    respectively. A collection of constants is also declared to
    exercise control over URL content caching policy.

    <p>NSURLRequest and NSMutableURLRequest are designed to be
    customized to support protocol-specific requests. Protocol
    implementors who need to extend the capabilities of NSURLRequest
    and NSMutableURLRequest are encouraged to provide categories on
    these classes as appropriate to support protocol-specific data. To
    store and retrieve data, category methods can use the
    <tt>+propertyForKey:inRequest:</tt> and
    <tt>+setProperty:forKey:inRequest:</tt> class methods on
    NSURLProtocol. See the NSHTTPURLRequest on NSURLRequest and
    NSMutableHTTPURLRequest on NSMutableURLRequest for examples of
    such extensions.

    <p>The main advantage of this design is that a client of the URL
    loading library can implement request policies in a standard way
    without type checking of requests or protocol checks on URLs. Any
    protocol-specific details that have been set on a URL request will
    be used if they apply to the particular URL being loaded, and will
    be ignored if they do not apply.
*/

/*!
    @enum NSURLRequestCachePolicy

    @discussion The NSURLRequestCachePolicy enum defines constants that
    can be used to specify the type of interactions that take place with
    the caching system when the URL loading system processes a request.
    Specifically, these constants cover interactions that have to do
    with whether already-existing cache data is returned to satisfy a
    URL load request.

    @constant NSURLRequestUseProtocolCachePolicy Specifies that the
    caching logic defined in the protocol implementation, if any, is
    used for a particular URL load request. This is the default policy
    for URL load requests.

    @constant NSURLRequestReloadIgnoringLocalCacheData Specifies that the
    data for the URL load should be loaded from the origin source. No
    existing local cache data, regardless of its freshness or validity,
    should be used to satisfy a URL load request.

    @constant NSURLRequestReloadIgnoringLocalAndRemoteCacheData Specifies that
    not only should the local cache data be ignored, but that proxies and
    other intermediates should be instructed to disregard their caches
    so far as the protocol allows.  Unimplemented.

    @constant NSURLRequestReloadIgnoringCacheData Older name for
    NSURLRequestReloadIgnoringLocalCacheData.

    @constant NSURLRequestReturnCacheDataElseLoad Specifies that the
    existing cache data should be used to satisfy a URL load request,
    regardless of its age or expiration date. However, if there is no
    existing data in the cache corresponding to a URL load request,
    the URL is loaded from the origin source.

    @constant NSURLRequestReturnCacheDataDontLoad Specifies that the
    existing cache data should be used to satisfy a URL load request,
    regardless of its age or expiration date. However, if there is no
    existing data in the cache corresponding to a URL load request, no
    attempt is made to load the URL from the origin source, and the
    load is considered to have failed. This constant specifies a
    behavior that is similar to an "offline" mode.

    @constant NSURLRequestReloadRevalidatingCacheData Specifies that
    the existing cache data may be used provided the origin source
    confirms its validity, otherwise the URL is loaded from the
    origin source.  Unimplemented.
*/
public enum NSURLRequestCachePolicy : UInt {
    
    case UseProtocolCachePolicy
    
    case ReloadIgnoringLocalCacheData
    case ReloadIgnoringLocalAndRemoteCacheData // Unimplemented
    public static var ReloadIgnoringCacheData: NSURLRequestCachePolicy { return .ReloadIgnoringLocalCacheData }
    
    case ReturnCacheDataElseLoad
    case ReturnCacheDataDontLoad
    
    case ReloadRevalidatingCacheData // Unimplemented
}

/*!
 @enum NSURLRequestNetworkServiceType
 
 @discussion The NSURLRequestNetworkServiceType enum defines constants that
 can be used to specify the service type to associate with this request.  The
 service type is used to provide the networking layers a hint of the purpose 
 of the request.
 
 @constant NSURLNetworkServiceTypeDefault Is the default value for an NSURLRequest
 when created.  This value should be left unchanged for the vast majority of requests.
 
 @constant NSURLNetworkServiceTypeVoIP Specifies that the request is for voice over IP
 control traffic.
 
 @constant NSURLNetworkServiceTypeVideo Specifies that the request is for video
 traffic.

 @constant NSURLNetworkServiceTypeBackground Specifies that the request is for background
 traffic (such as a file download).

 @constant NSURLNetworkServiceTypeVoice Specifies that the request is for voice data.

*/
public enum NSURLRequestNetworkServiceType : UInt {
    
    case NetworkServiceTypeDefault // Standard internet traffic
    case NetworkServiceTypeVoIP // Voice over IP control traffic
    case NetworkServiceTypeVideo // Video traffic
    case NetworkServiceTypeBackground // Background traffic
    case NetworkServiceTypeVoice // Voice data
}

/*!
    @class NSURLRequest
    
    @abstract An NSURLRequest object represents a URL load request in a
    manner independent of protocol and URL scheme.
    
    @discussion NSURLRequest encapsulates two basic data elements about
    a URL load request:
    <ul>
    <li>The URL to load.
    <li>The policy to use when consulting the URL content cache made
    available by the implementation.
    </ul>
    In addition, NSURLRequest is designed to be extended to support
    protocol-specific data by adding categories to access a property
    object provided in an interface targeted at protocol implementors.
    <ul>
    <li>Protocol implementors should direct their attention to the
    NSURLRequestExtensibility category on NSURLRequest for more
    information on how to provide extensions on NSURLRequest to
    support protocol-specific request information.
    <li>Clients of this API who wish to create NSURLRequest objects to
    load URL content should consult the protocol-specific NSURLRequest
    categories that are available. The NSHTTPURLRequest category on
    NSURLRequest is an example.
    </ul>
    <p>
    Objects of this class are used to create NSURLConnection instances,
    which can are used to perform the load of a URL, or as input to the
    NSURLConnection class method which performs synchronous loads.
*/
public class NSURLRequest : NSObject, NSSecureCoding, NSCopying, NSMutableCopying {
    
    private var _URL : NSURL?
    private var _mainDocumentURL: NSURL?
    private var _httpHeaderFields: [String: String]?
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }
    
    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    private override init() {}
    
    /*! 
        @method requestWithURL:
        @abstract Allocates and initializes an NSURLRequest with the given
        URL.
        @discussion Default values are used for cache policy
        (NSURLRequestUseProtocolCachePolicy) and timeout interval (60
        seconds).
        @param URL The URL for the request.
        @result A newly-created and autoreleased NSURLRequest instance.
    */
    
    /*
        @method supportsSecureCoding
        @abstract Indicates that NSURLRequest implements the NSSecureCoding protocol.
        @result A BOOL value set to YES.
    */
    public static func supportsSecureCoding() -> Bool { return true }
    
    /*!
        @method requestWithURL:cachePolicy:timeoutInterval:
        @abstract Allocates and initializes a NSURLRequest with the given
        URL and cache policy.
        @param URL The URL for the request. 
        @param cachePolicy The cache policy for the request. 
        @param timeoutInterval The timeout interval for the request. See the
        commentary for the <tt>timeoutInterval</tt> for more information on
        timeout intervals.
        @result A newly-created and autoreleased NSURLRequest instance. 
    */
    
    /*! 
        @method initWithURL:
        @abstract Initializes an NSURLRequest with the given URL. 
        @discussion Default values are used for cache policy
        (NSURLRequestUseProtocolCachePolicy) and timeout interval (60
        seconds).
        @param URL The URL for the request. 
        @result An initialized NSURLRequest. 
    */
    public convenience init(URL: NSURL) {
        self.init()
        _URL = URL
    }
    
    /*!
        @method URL
        @abstract Returns the URL of the receiver. 
        @result The URL of the receiver. 
    */
    /*@NSCopying */public var URL: NSURL? { return _URL }
    
    /*!
        @method mainDocumentURL
        @abstract The main document URL associated with this load.
        @discussion This URL is used for the cookie "same domain as main
        document" policy. There may also be other future uses.
        See setMainDocumentURL:
        @result The main document URL.
    */
    /*@NSCopying*/ public var mainDocumentURL: NSURL? { return _mainDocumentURL }
    
    /*!
    @method HTTPMethod
    @abstract Returns the HTTP request method of the receiver.
    @result the HTTP request method of the receiver.
    */
    public var HTTPMethod: String? { return "GET" }
    
    /*!
    @method allHTTPHeaderFields
    @abstract Returns a dictionary containing all the HTTP header fields
    of the receiver.
    @result a dictionary containing all the HTTP header fields of the
    receiver.
    */
    public var allHTTPHeaderFields: [String : String]? { return _httpHeaderFields  }
    
    /*!
    @method valueForHTTPHeaderField:
    @abstract Returns the value which corresponds to the given header
    field. Note that, in keeping with the HTTP RFC, HTTP header field
    names are case-insensitive.
    @param field the header field name to use for the lookup
    (case-insensitive).
    @result the value associated with the given header field, or nil if
    there is no value associated with the given header field.
    */
    public func valueForHTTPHeaderField(field: String) -> String? { return _httpHeaderFields?[field.lowercaseString] }
    
}

/*!
    @class NSMutableURLRequest

    @abstract An NSMutableURLRequest object represents a mutable URL load
    request in a manner independent of protocol and URL scheme.
    
    @discussion This specialization of NSURLRequest is provided to aid
    developers who may find it more convenient to mutate a single request
    object for a series of URL loads instead of creating an immutable
    NSURLRequest for each load. This programming model is supported by
    the following contract stipulation between NSMutableURLRequest and 
    NSURLConnection: NSURLConnection makes a deep copy of each 
    NSMutableURLRequest object passed to one of its initializers.    
    <p>NSMutableURLRequest is designed to be extended to support
    protocol-specific data by adding categories to access a property
    object provided in an interface targeted at protocol implementors.
    <ul>
    <li>Protocol implementors should direct their attention to the
    NSMutableURLRequestExtensibility category on
    NSMutableURLRequest for more information on how to provide
    extensions on NSMutableURLRequest to support protocol-specific
    request information.
    <li>Clients of this API who wish to create NSMutableURLRequest
    objects to load URL content should consult the protocol-specific
    NSMutableURLRequest categories that are available. The
    NSMutableHTTPURLRequest category on NSMutableURLRequest is an
    example.
    </ul>
*/
public class NSMutableURLRequest : NSURLRequest {
    
    private var _HTTPMethod: String? = "GET"
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
    }
    
    private override init() { super.init() }
    
    /*!
        @method URL
        @abstract Sets the URL of the receiver. 
        @param URL The new URL for the receiver. 
    */
    /*@NSCopying */ public override var URL: NSURL? {
        get {
            return _URL
        }
        set(newURL) {
            _URL = newURL
        }
    }

    /*!
        @method setMainDocumentURL:
        @abstract Sets the main document URL
        @param URL The main document URL.
        @discussion The caller should pass the URL for an appropriate main
        document, if known. For example, when loading a web page, the URL
        of the main html document for the top-level frame should be
        passed.  This main document will be used to implement the cookie
        "only from same domain as main document" policy, and possibly
        other things in the future.
    */
    /*@NSCopying*/ public override var mainDocumentURL: NSURL? {
        get {
            return _mainDocumentURL
        } set(newMainDocumentURL) {
            _mainDocumentURL = newMainDocumentURL
        }
    }
    
    
    /*!
        @method HTTPMethod
        @abstract Sets the HTTP request method of the receiver.
        @result the HTTP request method of the receiver.
    */
    public override var HTTPMethod: String? {
        get {
            return _HTTPMethod
        } set(newHTTPMethod) {
            _HTTPMethod = newHTTPMethod
        }
    }
    
    /*!
        @method setValue:forHTTPHeaderField:
        @abstract Sets the value of the given HTTP header field.
        @discussion If a value was previously set for the given header
        field, that value is replaced with the given value. Note that, in
        keeping with the HTTP RFC, HTTP header field names are
        case-insensitive.
        @param value the header field value. 
        @param field the header field name (case-insensitive). 
    */
    public func setValue(value: String?, forHTTPHeaderField field: String) {
        if _httpHeaderFields == nil {
            _httpHeaderFields = [:]
        }
        if let existingHeader = _httpHeaderFields?.filter({ (existingField, _) -> Bool in
            return existingField.lowercaseString == field.lowercaseString
        }).first {
            let (existingField, _) = existingHeader
            _httpHeaderFields?.removeValueForKey(existingField)
        }
        _httpHeaderFields?[field] = value
    }
    
    /*! 
        @method addValue:forHTTPHeaderField:
        @abstract Adds an HTTP header field in the current header
        dictionary.
        @discussion This method provides a way to add values to header
        fields incrementally. If a value was previously set for the given
        header field, the given value is appended to the previously-existing
        value. The appropriate field delimiter, a comma in the case of HTTP,
        is added by the implementation, and should not be added to the given
        value by the caller. Note that, in keeping with the HTTP RFC, HTTP
        header field names are case-insensitive.
        @param value the header field value. 
        @param field the header field name (case-insensitive). 
    */
    public func addValue(value: String, forHTTPHeaderField field: String) {
        if _httpHeaderFields == nil {
            _httpHeaderFields = [:]
        }
        if let existingHeader = _httpHeaderFields?.filter({ (existingField, _) -> Bool in
            return existingField.lowercaseString == field.lowercaseString
        }).first {
            let (existingField, existingValue) = existingHeader
            _httpHeaderFields?[existingField] = "\(existingValue),\(value)"
        } else {
            _httpHeaderFields?[field] = value
        }
    }
}


