// Foundation/URLSession/Configuration.swift - URLSession & libcurl
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
/// These are libcurl helpers for the URLSession API code.
/// - SeeAlso: https://curl.haxx.se/libcurl/c/
/// - SeeAlso: URLSession.swift
///
// -----------------------------------------------------------------------------


internal extension URLSession {
    /// This is an immutable / `struct` version of `URLSessionConfiguration`.
    struct _Configuration {
        /// identifier for the background session configuration
        let identifier: String?
        
        /// default cache policy for requests
        let requestCachePolicy: URLRequest.CachePolicy
        
        /// default timeout for requests.  This will cause a timeout if no data is transmitted for the given timeout value, and is reset whenever data is transmitted.
        let timeoutIntervalForRequest: TimeInterval
        
        /// default timeout for requests.  This will cause a timeout if a resource is not retrievable within a given timeout.
        let timeoutIntervalForResource: TimeInterval
        
        /// type of service for requests.
        let networkServiceType: URLRequest.NetworkServiceType
        
        /// allow request to route over cellular.
        let allowsCellularAccess: Bool
        
        /// allows background tasks to be scheduled at the discretion of the system for optimal performance.
        let isDiscretionary: Bool
        
        /// The proxy dictionary, as described by <CFNetwork/CFHTTPStream.h>
        let connectionProxyDictionary: [AnyHashable : Any]?
        
        /// Allow the use of HTTP pipelining
        let httpShouldUsePipelining: Bool
        
        /// Allow the session to set cookies on requests
        let httpShouldSetCookies: Bool
        
        /// Policy for accepting cookies.  This overrides the policy otherwise specified by the cookie storage.
        let httpCookieAcceptPolicy: HTTPCookie.AcceptPolicy
        
        /// Specifies additional headers which will be set on outgoing requests.
        /// Note that these headers are added to the request only if not already present.
        
        let httpAdditionalHeaders: [String : String]?
        /// The maximum number of simultaneous persistent connections per host
        let httpMaximumConnectionsPerHost: Int
        
        /// The cookie storage object to use, or nil to indicate that no cookies should be handled
        let httpCookieStorage: HTTPCookieStorage?
        
        /// The credential storage object, or nil to indicate that no credential storage is to be used
        let urlCredentialStorage: URLCredentialStorage?
        
        /// The URL resource cache, or nil to indicate that no caching is to be performed
        let urlCache: URLCache?
        
        /// Enable extended background idle mode for any tcp sockets created.
        let shouldUseExtendedBackgroundIdleMode: Bool
        
        let protocolClasses: [AnyClass]?
    }
}
internal extension URLSession._Configuration {
    init(URLSessionConfiguration config: URLSessionConfiguration) {
        identifier = config.identifier
        requestCachePolicy = config.requestCachePolicy
        timeoutIntervalForRequest = config.timeoutIntervalForRequest
        timeoutIntervalForResource = config.timeoutIntervalForResource
        networkServiceType = config.networkServiceType
        allowsCellularAccess = config.allowsCellularAccess
        isDiscretionary = config.isDiscretionary
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
internal extension URLSession._Configuration {
    func configure(request: URLRequest) -> URLRequest {
        var request = request
        return setCookies(on: request)
    }

     func setCookies(on request: URLRequest) -> URLRequest {
        var request = request
        if httpShouldSetCookies {
            if let cookieStorage = self.httpCookieStorage, let url = request.url, let cookies = cookieStorage.cookies(for: url) {
                let cookiesHeaderFields =  HTTPCookie.requestHeaderFields(with: cookies)
                if let cookieValue = cookiesHeaderFields["Cookie"], cookieValue != "" {
                    request.addValue(cookieValue, forHTTPHeaderField: "Cookie")
                }
            }
        }
        return request
    }
}

// Cache Management
private extension URLSession._Configuration {
    func cachedResponse(forRequest request: URLRequest) -> CachedURLResponse? {
        //TODO: Check the policy & consult the cache.
        // There's more detail on how this should work here:
        // <https://developer.apple.com/library/prerelease/ios/documentation/Cocoa/Reference/Foundation/Classes/NSURLRequest_Class/index.html#//apple_ref/swift/enum/c:@E@URLRequestCachePolicy>
        switch requestCachePolicy {
        default: return nil
        }
    }
}

private func convertToStringString(dictionary: [AnyHashable:Any]) -> [String: String] {
    //TODO: There's some confusion about [NSObject:AnyObject] vs. [String:String] for headers.
    // C.f. <https://github.com/apple/swift-corelibs-foundation/pull/287>
    var r: [String: String] = [:]
    dictionary.forEach {
        let k = getString(from: $0.key)
        let v = getString(from: $0.value)
        r[k] = v
    }
    return r
}

private func getString(from obj: Any) -> String {
    if let string = obj as? String {
        return string
    } else {
        return String(describing: obj as! NSString)
    }
}
