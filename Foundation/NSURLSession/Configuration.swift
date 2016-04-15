// Foundation/NSURLSession/Configuration.swift - NSURLSession & libcurl
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
/// These are libcurl helpers for the NSURLSession API code.
/// - SeeAlso: https://curl.haxx.se/libcurl/c/
/// - SeeAlso: NSURLSession.swift
///
// -----------------------------------------------------------------------------


internal extension NSURLSession {
    /// This is an immutable / `struct` version of `NSURLSessionConfiguration`.
    struct Configuration {
        /// identifier for the background session configuration
        let identifier: String?
        
        /// default cache policy for requests
        let requestCachePolicy: NSURLRequestCachePolicy
        
        /// default timeout for requests.  This will cause a timeout if no data is transmitted for the given timeout value, and is reset whenever data is transmitted.
        let timeoutIntervalForRequest: NSTimeInterval
        
        /// default timeout for requests.  This will cause a timeout if a resource is not able to be retrieved within a given timeout.
        let timeoutIntervalForResource: NSTimeInterval
        
        /// type of service for requests.
        let networkServiceType: NSURLRequestNetworkServiceType
        
        /// allow request to route over cellular.
        let allowsCellularAccess: Bool
        
        /// allows background tasks to be scheduled at the discretion of the system for optimal performance.
        let discretionary: Bool
        
        /// The proxy dictionary, as described by <CFNetwork/CFHTTPStream.h>
        let connectionProxyDictionary: [NSObject : AnyObject]?
        
        /// Allow the use of HTTP pipelining
        let httpShouldUsePipelining: Bool
        
        /// Allow the session to set cookies on requests
        let httpShouldSetCookies: Bool
        
        /// Policy for accepting cookies.  This overrides the policy otherwise specified by the cookie storage.
        let httpCookieAcceptPolicy: NSHTTPCookieAcceptPolicy
        
        /// Specifies additional headers which will be set on outgoing requests.
        /// Note that these headers are added to the request only if not already present.
        
        let httpAdditionalHeaders: [String : String]?
        /// The maximum number of simultanous persistent connections per host
        let httpMaximumConnectionsPerHost: Int
        
        /// The cookie storage object to use, or nil to indicate that no cookies should be handled
        let httpCookieStorage: NSHTTPCookieStorage?
        
        /// The credential storage object, or nil to indicate that no credential storage is to be used
        let urlCredentialStorage: NSURLCredentialStorage?
        
        /// The URL resource cache, or nil to indicate that no caching is to be performed
        let urlCache: NSURLCache?
        
        /// Enable extended background idle mode for any tcp sockets created.
        let shouldUseExtendedBackgroundIdleMode: Bool
        
        let protocolClasses: [AnyClass]?
    }
}
internal extension NSURLSession.Configuration {
    init(URLSessionConfiguration config: NSURLSessionConfiguration) {
        identifier = config.identifier
        requestCachePolicy = config.requestCachePolicy
        timeoutIntervalForRequest = config.timeoutIntervalForRequest
        timeoutIntervalForResource = config.timeoutIntervalForResource
        networkServiceType = config.networkServiceType
        allowsCellularAccess = config.allowsCellularAccess
        discretionary = config.discretionary
        connectionProxyDictionary = config.connectionProxyDictionary
        httpShouldUsePipelining = config.httpShouldUsePipelining
        httpShouldSetCookies = config.httpShouldSetCookies
        httpCookieAcceptPolicy = config.httpCookieAcceptPolicy
        httpAdditionalHeaders = config.httpAdditionalHeaders.map { convertToStringString(dictionary: $0) }
        httpMaximumConnectionsPerHost = config.httpMaximumConnectionsPerHost
        httpCookieStorage = config.httpCookieStorage
        urlCredentialStorage = config.urlCredentialStorage
        urlCache = config.urlCache
        shouldUseExtendedBackgroundIdleMode = config.shouldUseExtendedBackgroundIdleMode
        protocolClasses = config.protocolClasses
    }
}

// Configure NSURLRequests
internal extension NSURLSession.Configuration {
    func configure(request: NSMutableURLRequest) {
        httpAdditionalHeaders?.forEach {
            guard request.value(forHTTPHeaderField: $0.0) == nil else { return }
            request.setValue($0.1, forHTTPHeaderField: $0.0)
        }
    }
    func setCookies(on request: NSMutableURLRequest) {
        if httpShouldSetCookies {
            //TODO: Ask the cookie storage what cookie to set.
        }
    }
}
// Cache Management
private extension NSURLSession.Configuration {
    func cachedResponse(forRequest request: NSURLRequest) -> NSCachedURLResponse? {
        //TODO: Check the policy & consult the cache.
        // There's more detail on how this should work here:
        // <https://developer.apple.com/library/prerelease/ios/documentation/Cocoa/Reference/Foundation/Classes/NSURLRequest_Class/index.html#//apple_ref/swift/enum/c:@E@NSURLRequestCachePolicy>
        switch requestCachePolicy {
        default: return nil
        }
    }
}

private func convertToStringString(dictionary: [NSObject:AnyObject]) -> [String: String] {
    //TODO: There's some confusion about [NSObject:AnyObject] vs. [String:String] for headers.
    // C.f. <https://github.com/apple/swift-corelibs-foundation/pull/287>
    var r: [String: String] = [:]
    dictionary.forEach {
        let k = String($0.key as! NSString)
        let v = String($0.value as! NSString)
        r[k] = v
    }
    return r
}
