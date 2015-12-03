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
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
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
    public convenience init(URL: NSURL) { NSUnimplemented() }
    
    /*!
        @method URL
        @abstract Returns the URL of the receiver. 
        @result The URL of the receiver. 
    */
    /*@NSCopying */public var URL: NSURL? { NSUnimplemented() }
    
    /*! 
        @method cachePolicy
        @abstract Returns the cache policy of the receiver. 
        @result The cache policy of the receiver. 
    */
    public var cachePolicy: NSURLRequestCachePolicy { get { NSUnimplemented() } }
    
    /*! 
        @method timeoutInterval
        @abstract Returns the timeout interval of the receiver.
        @discussion The timeout interval specifies the limit on the idle
        interval alloted to a request in the process of loading. The "idle
        interval" is defined as the period of time that has passed since the
        last instance of load activity occurred for a request that is in the
        process of loading. Hence, when an instance of load activity occurs
        (e.g. bytes are received from the network for a request), the idle
        interval for a request is reset to 0. If the idle interval ever
        becomes greater than or equal to the timeout interval, the request
        is considered to have timed out. This timeout interval is measured
        in seconds.
        @result The timeout interval of the receiver. 
    */
    public var timeoutInterval: NSTimeInterval { get { NSUnimplemented() } }
    
    /*!
        @method mainDocumentURL
        @abstract The main document URL associated with this load.
        @discussion This URL is used for the cookie "same domain as main
        document" policy. There may also be other future uses.
        See setMainDocumentURL:
        @result The main document URL.
    */
    /*@NSCopying*/ public var mainDocumentURL: NSURL? { NSUnimplemented() }
    
    /*!
        @method HTTPMethod
        @abstract Returns the HTTP request method of the receiver.
        @result the HTTP request method of the receiver.
    */
    public var HTTPMethod: String? { get { NSUnimplemented() } set { NSUnimplemented() } }
    
    /*!
        @method allHTTPHeaderFields
        @abstract Returns a dictionary containing all the HTTP header fields
        of the receiver.
        @result a dictionary containing all the HTTP header fields of the
        receiver.
    */
    public var allHTTPHeaderFields: [String : String]? { NSUnimplemented() }
    
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
    public func valueForHTTPHeaderField(field: String) -> String? { NSUnimplemented() }
    
    /*! 
        @method HTTPBody
        @abstract Returns the request body data of the receiver. 
        @discussion This data is sent as the message body of the request, as
        in done in an HTTP POST request.
        @result The request body data of the receiver. 
    */
    /*@NSCopying*/ public var HTTPBody: NSData? { get { NSUnimplemented() } }

    /*!
        @method HTTPBodyStream
        @abstract Returns the request body stream of the receiver
        if any has been set
        @discussion The stream is returned for examination only; it is
        not safe for the caller to manipulate the stream in any way.  Also
        note that the HTTPBodyStream and HTTPBody are mutually exclusive - only
        one can be set on a given request.  Also note that the body stream is
        preserved across copies, but is LOST when the request is coded via the 
        NSCoding protocol
        @result The request body stream of the receiver.
    */
    public var HTTPBodyStream: NSInputStream? { get { NSUnimplemented() } }
    
    /*! 
        @method HTTPShouldHandleCookies
        @abstract Determine whether default cookie handling will happen for 
        this request.
        @discussion NOTE: This value is not used prior to 10.3
        @result YES if cookies will be sent with and set for this request; 
        otherwise NO.
    */
    public var HTTPShouldHandleCookies: Bool { get { NSUnimplemented() } }
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
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    /*! 
        @method URL
        @abstract Sets the URL of the receiver. 
        @param URL The new URL for the receiver. 
    */
    /*@NSCopying */ public override var URL: NSURL? { get { NSUnimplemented() } set { NSUnimplemented() } }

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
    /*@NSCopying*/ public override var mainDocumentURL: NSURL? { get { NSUnimplemented() } set { NSUnimplemented() } }
    
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
    public func setValue(value: String?, forHTTPHeaderField field: String) { NSUnimplemented() }
    
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
    public func addValue(value: String, forHTTPHeaderField field: String) { NSUnimplemented() }
}


