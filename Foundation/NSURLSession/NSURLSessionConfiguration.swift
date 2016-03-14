// Foundation/NSURLSession/NSURLSessionConfiguration.swift - NSURLSession Configuration
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// NSURLSession API code.
/// - SeeAlso: NSURLSession.swift
///
// -----------------------------------------------------------------------------



/// Configuration options for an NSURLSession.
///
/// When a session is
/// created, a copy of the configuration object is made - you cannot
/// modify the configuration of a session after it has been created.
///
/// The shared session uses the global singleton credential, cache
/// and cookie storage objects.
///
/// An ephemeral session has no persistent disk storage for cookies,
/// cache or credentials.
///
/// A background session can be used to perform networking operations
/// on behalf of a suspended application, within certain constraints.
public class NSURLSessionConfiguration : NSObject, NSCopying {
    public override init() {
        self.requestCachePolicy = NSURLRequestCachePolicy.useProtocolCachePolicy
        self.timeoutIntervalForRequest = 60
        self.timeoutIntervalForResource = 604800
        self.networkServiceType = .networkServiceTypeDefault
        self.allowsCellularAccess = true
        self.discretionary = false
        self.httpShouldUsePipelining = false
        self.httpShouldSetCookies = true
        self.httpCookieAcceptPolicy = .OnlyFromMainDocumentDomain
        self.httpMaximumConnectionsPerHost = 6
        self.httpCookieStorage = nil
        self.urlCredentialStorage = nil
        self.urlCache = nil
        self.shouldUseExtendedBackgroundIdleMode = false
        super.init()
    }
    
    private init(identifier: String?,
                 requestCachePolicy: NSURLRequestCachePolicy,
                 timeoutIntervalForRequest: NSTimeInterval,
                 timeoutIntervalForResource: NSTimeInterval,
                 networkServiceType: NSURLRequestNetworkServiceType,
                 allowsCellularAccess: Bool,
                 discretionary: Bool,
                 connectionProxyDictionary: [NSObject : AnyObject]?,
                 httpShouldUsePipelining: Bool,
                 httpShouldSetCookies: Bool,
                 httpCookieAcceptPolicy: NSHTTPCookieAcceptPolicy,
                 httpAdditionalHeaders: [NSObject : AnyObject]?,
                 httpMaximumConnectionsPerHost: Int,
                 httpCookieStorage: NSHTTPCookieStorage?,
                 urlCredentialStorage: NSURLCredentialStorage?,
                 urlCache: NSURLCache?,
                 shouldUseExtendedBackgroundIdleMode: Bool,
                 protocolClasses: [AnyClass]?)
    {
        self.identifier = identifier
        self.requestCachePolicy = requestCachePolicy
        self.timeoutIntervalForRequest = timeoutIntervalForRequest
        self.timeoutIntervalForResource = timeoutIntervalForResource
        self.networkServiceType = networkServiceType
        self.allowsCellularAccess = allowsCellularAccess
        self.discretionary = discretionary
        self.connectionProxyDictionary = connectionProxyDictionary
        self.httpShouldUsePipelining = httpShouldUsePipelining
        self.httpShouldSetCookies = httpShouldSetCookies
        self.httpCookieAcceptPolicy = httpCookieAcceptPolicy
        self.httpAdditionalHeaders = httpAdditionalHeaders
        self.httpMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
        self.httpCookieStorage = httpCookieStorage
        self.urlCredentialStorage = urlCredentialStorage
        self.urlCache = urlCache
        self.shouldUseExtendedBackgroundIdleMode = shouldUseExtendedBackgroundIdleMode
        self.protocolClasses = protocolClasses
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        return NSURLSessionConfiguration(
            identifier: identifier,
            requestCachePolicy: requestCachePolicy,
            timeoutIntervalForRequest: timeoutIntervalForRequest,
            timeoutIntervalForResource: timeoutIntervalForResource,
            networkServiceType: networkServiceType,
            allowsCellularAccess: allowsCellularAccess,
            discretionary: discretionary,
            connectionProxyDictionary: connectionProxyDictionary,
            httpShouldUsePipelining: httpShouldUsePipelining,
            httpShouldSetCookies: httpShouldSetCookies,
            httpCookieAcceptPolicy: httpCookieAcceptPolicy,
            httpAdditionalHeaders: httpAdditionalHeaders,
            httpMaximumConnectionsPerHost: httpMaximumConnectionsPerHost,
            httpCookieStorage: httpCookieStorage,
            urlCredentialStorage: urlCredentialStorage,
            urlCache: urlCache,
            shouldUseExtendedBackgroundIdleMode: shouldUseExtendedBackgroundIdleMode,
            protocolClasses: protocolClasses)
    }
    
    public class func defaultSessionConfiguration() -> NSURLSessionConfiguration {
        return NSURLSessionConfiguration()
    }
    public class func ephemeralSessionConfiguration() -> NSURLSessionConfiguration { NSUnimplemented() }
    public class func backgroundSessionConfigurationWithIdentifier(identifier: String) -> NSURLSessionConfiguration { NSUnimplemented() }
    
    /* identifier for the background session configuration */
    public var identifier: String?
    
    /* default cache policy for requests */
    public var requestCachePolicy: NSURLRequestCachePolicy
    
    /* default timeout for requests.  This will cause a timeout if no data is transmitted for the given timeout value, and is reset whenever data is transmitted. */
    public var timeoutIntervalForRequest: NSTimeInterval
    
    /* default timeout for requests.  This will cause a timeout if a resource is not able to be retrieved within a given timeout. */
    public var timeoutIntervalForResource: NSTimeInterval
    
    /* type of service for requests. */
    public var networkServiceType: NSURLRequestNetworkServiceType
    
    /* allow request to route over cellular. */
    public var allowsCellularAccess: Bool
    
    /* allows background tasks to be scheduled at the discretion of the system for optimal performance. */
    public var discretionary: Bool
    
    /* The identifier of the shared data container into which files in background sessions should be downloaded.
     * App extensions wishing to use background sessions *must* set this property to a valid container identifier, or
     * all transfers in that session will fail with NSURLErrorBackgroundSessionRequiresSharedContainer.
     */
    public var sharedContainerIdentifier: String? { return nil }
    
    /*
     * Allows the app to be resumed or launched in the background when tasks in background sessions complete
     * or when auth is required. This only applies to configurations created with +backgroundSessionConfigurationWithIdentifier:
     * and the default value is YES.
     */
    
    /* The proxy dictionary, as described by <CFNetwork/CFHTTPStream.h> */
    public var connectionProxyDictionary: [NSObject : AnyObject]? = nil
    
    // TODO: We don't have the SSLProtocol type from Security
    /*
     /* The minimum allowable versions of the TLS protocol, from <Security/SecureTransport.h> */
     public var TLSMinimumSupportedProtocol: SSLProtocol
     
     /* The maximum allowable versions of the TLS protocol, from <Security/SecureTransport.h> */
     public var TLSMaximumSupportedProtocol: SSLProtocol
     */
    
    /* Allow the use of HTTP pipelining */
    public var httpShouldUsePipelining: Bool
    
    /* Allow the session to set cookies on requests */
    public var httpShouldSetCookies: Bool
    
    /* Policy for accepting cookies.  This overrides the policy otherwise specified by the cookie storage. */
    public var httpCookieAcceptPolicy: NSHTTPCookieAcceptPolicy
    
    /* Specifies additional headers which will be set on outgoing requests.
     Note that these headers are added to the request only if not already present. */
    public var httpAdditionalHeaders: [NSObject : AnyObject]? = nil
    
    /* The maximum number of simultanous persistent connections per host */
    public var httpMaximumConnectionsPerHost: Int
    
    /* The cookie storage object to use, or nil to indicate that no cookies should be handled */
    public var httpCookieStorage: NSHTTPCookieStorage?
    
    /* The credential storage object, or nil to indicate that no credential storage is to be used */
    public var urlCredentialStorage: NSURLCredentialStorage?
    
    /* The URL resource cache, or nil to indicate that no caching is to be performed */
    public var urlCache: NSURLCache?
    
    /* Enable extended background idle mode for any tcp sockets created.    Enabling this mode asks the system to keep the socket open
     *  and delay reclaiming it when the process moves to the background (see https://developer.apple.com/library/ios/technotes/tn2277/_index.html)
     */
    public var shouldUseExtendedBackgroundIdleMode: Bool
    
    /* An optional array of Class objects which subclass NSURLProtocol.
     The Class will be sent +canInitWithRequest: when determining if
     an instance of the class can be used for a given URL scheme.
     You should not use +[NSURLProtocol registerClass:], as that
     method will register your class with the default session rather
     than with an instance of NSURLSession.
     Custom NSURLProtocol subclasses are not available to background
     sessions.
     */
    public var protocolClasses: [AnyClass]?
}
