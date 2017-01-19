// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/*!
    @header NSURLProtocol.h

    This header file describes the constructs used to represent URL
    protocols, and describes the extensible system by which specific
    classes can be made to handle the loading of particular URL types or
    schemes.
    
    <p>NSURLProtocol is an abstract class which provides the
    basic structure for performing protocol-specific loading of URL
    data.
    
    <p>The NSURLProtocolClient describes the integration points a
    protocol implemention can use to hook into the URL loading system.
    NSURLProtocolClient describes the methods a protocol implementation
    needs to drive the URL loading system from a NSURLProtocol subclass.
    
    <p>To support customization of protocol-specific requests,
    protocol implementors are encouraged to provide categories on
    NSURLRequest and NSMutableURLRequest. Protocol implementors who
    need to extend the capabilities of NSURLRequest and
    NSMutableURLRequest in this way can store and retrieve
    protocol-specific request data by using the
    <tt>+propertyForKey:inRequest:</tt> and
    <tt>+setProperty:forKey:inRequest:</tt> class methods on
    NSURLProtocol. See the NSHTTPURLRequest on NSURLRequest and
    NSMutableHTTPURLRequest on NSMutableURLRequest for examples of
    such extensions.
    
    <p>An essential responsibility for a protocol implementor is
    creating a NSURLResponse for each request it processes successfully.
    A protocol implementor may wish to create a custom, mutable 
    NSURLResponse class to aid in this work.
*/

/*!
@protocol NSURLProtocolClient
@discussion NSURLProtocolClient provides the interface to the URL
loading system that is intended for use by NSURLProtocol
implementors.
*/
public protocol URLProtocolClient : NSObjectProtocol {
    
    
    /*!
     @method URLProtocol:wasRedirectedToRequest:
     @abstract Indicates to an NSURLProtocolClient that a redirect has
     occurred.
     @param URLProtocol the NSURLProtocol object sending the message.
     @param request the NSURLRequest to which the protocol implementation
     has redirected.
     */
    func urlProtocol(_ protocol: URLProtocol, wasRedirectedTo request: URLRequest, redirectResponse: URLResponse)
    
    
    /*!
     @method URLProtocol:cachedResponseIsValid:
     @abstract Indicates to an NSURLProtocolClient that the protocol
     implementation has examined a cached response and has
     determined that it is valid.
     @param URLProtocol the NSURLProtocol object sending the message.
     @param cachedResponse the NSCachedURLResponse object that has
     examined and is valid.
     */
    func urlProtocol(_ protocol: URLProtocol, cachedResponseIsValid cachedResponse: CachedURLResponse)
    
    
    /*!
     @method URLProtocol:didReceiveResponse:
     @abstract Indicates to an NSURLProtocolClient that the protocol
     implementation has created an NSURLResponse for the current load.
     @param URLProtocol the NSURLProtocol object sending the message.
     @param response the NSURLResponse object the protocol implementation
     has created.
     @param cacheStoragePolicy The NSURLCacheStoragePolicy the protocol
     has determined should be used for the given response if the
     response is to be stored in a cache.
     */
    func urlProtocol(_ protocol: URLProtocol, didReceive response: URLResponse, cacheStoragePolicy policy: URLCache.StoragePolicy)
    
    
    /*!
     @method URLProtocol:didLoadData:
     @abstract Indicates to an NSURLProtocolClient that the protocol
     implementation has loaded URL data.
     @discussion The data object must contain only new data loaded since
     the previous call to this method (if any), not cumulative data for
     the entire load.
     @param URLProtocol the NSURLProtocol object sending the message.
     @param data URL load data being made available.
     */
    func urlProtocol(_ protocol: URLProtocol, didLoad data: Data)
    
    
    /*!
     @method URLProtocolDidFinishLoading:
     @abstract Indicates to an NSURLProtocolClient that the protocol
     implementation has finished loading successfully.
     @param URLProtocol the NSURLProtocol object sending the message.
     */
    func urlProtocolDidFinishLoading(_ protocol: URLProtocol)
    
    
    /*!
     @method URLProtocol:didFailWithError:
     @abstract Indicates to an NSURLProtocolClient that the protocol
     implementation has failed to load successfully.
     @param URLProtocol the NSURLProtocol object sending the message.
     @param error The error that caused the load to fail.
     */
    func urlProtocol(_ protocol: URLProtocol, didFailWithError error: Error)
    
    
    /*!
     @method URLProtocol:didReceiveAuthenticationChallenge:
     @abstract Start authentication for the specified request
     @param protocol The protocol object requesting authentication.
     @param challenge The authentication challenge.
     @discussion The protocol client guarantees that it will answer the
     request on the same thread that called this method. It may add a
     default credential to the challenge it issues to the connection delegate,
     if the protocol did not provide one.
     */
    func urlProtocol(_ protocol: URLProtocol, didReceive challenge: URLAuthenticationChallenge)
    
    
    /*!
     @method URLProtocol:didCancelAuthenticationChallenge:
     @abstract Cancel authentication for the specified request
     @param protocol The protocol object cancelling authentication.
     @param challenge The authentication challenge.
     */
    func urlProtocol(_ protocol: URLProtocol, didCancel challenge: URLAuthenticationChallenge)
}

/*!
    @class NSURLProtocol
 
    @abstract NSURLProtocol is an abstract class which provides the
    basic structure for performing protocol-specific loading of URL
    data. Concrete subclasses handle the specifics associated with one
    or more protocols or URL schemes.
*/
open class URLProtocol : NSObject {
    
    /*! 
        @method initWithRequest:cachedResponse:client:
        @abstract Initializes an NSURLProtocol given request, 
        cached response, and client.
        @param request The request to load.
        @param cachedResponse A response that has been retrieved from the
        cache for the given request. The protocol implementation should
        apply protocol-specific validity checks if such tests are
        necessary.
        @param client The NSURLProtocolClient object that serves as the
        interface the protocol implementation can use to report results back
        to the URL loading system.
    */
    public init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) { NSUnimplemented() }
    
    /*! 
        @method client
        @abstract Returns the NSURLProtocolClient of the receiver. 
        @result The NSURLProtocolClient of the receiver.  
    */
    open var client: URLProtocolClient? { NSUnimplemented() }
    
    /*! 
        @method request
        @abstract Returns the NSURLRequest of the receiver. 
        @result The NSURLRequest of the receiver. 
    */
    /*@NSCopying*/ open var request: URLRequest { NSUnimplemented() }
    
    /*! 
        @method cachedResponse
        @abstract Returns the NSCachedURLResponse of the receiver.  
        @result The NSCachedURLResponse of the receiver. 
    */
    /*@NSCopying*/ open var cachedResponse: CachedURLResponse? { NSUnimplemented() }
    
    /*======================================================================
      Begin responsibilities for protocol implementors
    
      The methods between this set of begin-end markers must be
      implemented in order to create a working protocol.
      ======================================================================*/
    
    /*! 
        @method canInitWithRequest:
        @abstract This method determines whether this protocol can handle
        the given request.
        @discussion A concrete subclass should inspect the given request and
        determine whether or not the implementation can perform a load with
        that request. This is an abstract method. Sublasses must provide an
        implementation. The implementation in this class calls
        NSRequestConcreteImplementation.
        @param request A request to inspect.
        @result YES if the protocol can handle the given request, NO if not.
    */
    open class func canInit(with request: URLRequest) -> Bool { NSUnimplemented() }
    
    /*! 
        @method canonicalRequestForRequest:
        @abstract This method returns a canonical version of the given
        request.
        @discussion It is up to each concrete protocol implementation to
        define what "canonical" means. However, a protocol should
        guarantee that the same input request always yields the same
        canonical form. Special consideration should be given when
        implementing this method since the canonical form of a request is
        used to look up objects in the URL cache, a process which performs
        equality checks between NSURLRequest objects.
        <p>
        This is an abstract method; sublasses must provide an
        implementation. The implementation in this class calls
        NSRequestConcreteImplementation.
        @param request A request to make canonical.
        @result The canonical form of the given request. 
    */
    open class func canonicalRequest(for request: URLRequest) -> URLRequest { NSUnimplemented() }
    
    /*!
        @method requestIsCacheEquivalent:toRequest:
        @abstract Compares two requests for equivalence with regard to caching.
        @discussion Requests are considered euqivalent for cache purposes
        if and only if they would be handled by the same protocol AND that
        protocol declares them equivalent after performing 
        implementation-specific checks.
        @result YES if the two requests are cache-equivalent, NO otherwise.
    */
    open class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool { NSUnimplemented() }
    
    /*! 
        @method startLoading
        @abstract Starts protocol-specific loading of a request. 
        @discussion When this method is called, the protocol implementation
        should start loading a request.
    */
    open func startLoading() { NSUnimplemented() }
    
    /*! 
        @method stopLoading
        @abstract Stops protocol-specific loading of a request. 
        @discussion When this method is called, the protocol implementation
        should end the work of loading a request. This could be in response
        to a cancel operation, so protocol implementations must be able to
        handle this call while a load is in progress.
    */
    open func stopLoading() { NSUnimplemented() }
    
    /*======================================================================
      End responsibilities for protocol implementors
      ======================================================================*/
    
    /*! 
        @method propertyForKey:inRequest:
        @abstract Returns the property in the given request previously
        stored with the given key.
        @discussion The purpose of this method is to provide an interface
        for protocol implementors to access protocol-specific information
        associated with NSURLRequest objects.
        @param key The string to use for the property lookup.
        @param request The request to use for the property lookup.
        @result The property stored with the given key, or nil if no property
        had previously been stored with the given key in the given request.
    */
    open class func property(forKey key: String, in request: URLRequest) -> Any? { NSUnimplemented() }
    
    /*! 
        @method setProperty:forKey:inRequest:
        @abstract Stores the given property in the given request using the
        given key.
        @discussion The purpose of this method is to provide an interface
        for protocol implementors to customize protocol-specific
        information associated with NSMutableURLRequest objects.
        @param value The property to store. 
        @param key The string to use for the property storage. 
        @param request The request in which to store the property. 
    */
    open class func setProperty(_ value: Any, forKey key: String, in request: NSMutableURLRequest) { NSUnimplemented() }
    
    /*!
        @method removePropertyForKey:inRequest:
        @abstract Remove any property stored under the given key
        @discussion Like setProperty:forKey:inRequest: above, the purpose of this
            method is to give protocol implementors the ability to store 
            protocol-specific information in an NSURLRequest
        @param key The key whose value should be removed
        @param request The request to be modified
    */
    open class func removeProperty(forKey key: String, in request: NSMutableURLRequest) { NSUnimplemented() }
    
    /*! 
        @method registerClass:
        @abstract This method registers a protocol class, making it visible
        to several other NSURLProtocol class methods.
        @discussion When the URL loading system begins to load a request,
        each protocol class that has been registered is consulted in turn to
        see if it can be initialized with a given request. The first
        protocol handler class to provide a YES answer to
        <tt>+canInitWithRequest:</tt> "wins" and that protocol
        implementation is used to perform the URL load. There is no
        guarantee that all registered protocol classes will be consulted.
        Hence, it should be noted that registering a class places it first
        on the list of classes that will be consulted in calls to
        <tt>+canInitWithRequest:</tt>, moving it in front of all classes
        that had been registered previously.
        <p>A similar design governs the process to create the canonical form
        of a request with the <tt>+canonicalRequestForRequest:</tt> class
        method.
        @param protocolClass the class to register.
        @result YES if the protocol was registered successfully, NO if not.
        The only way that failure can occur is if the given class is not a
        subclass of NSURLProtocol.
    */
    open class func registerClass(_ protocolClass: AnyClass) -> Bool { NSUnimplemented() }
    
    /*! 
        @method unregisterClass:
        @abstract This method unregisters a protocol. 
        @discussion After unregistration, a protocol class is no longer
        consulted in calls to NSURLProtocol class methods.
        @param protocolClass The class to unregister.
    */
    open class func unregisterClass(_ protocolClass: AnyClass) { NSUnimplemented() }

    open class func canInit(with task: URLSessionTask) -> Bool { NSUnimplemented() }
    public convenience init(task: URLSessionTask, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) { NSUnimplemented() }
    /*@NSCopying*/ open var task: URLSessionTask? { NSUnimplemented() }
}

