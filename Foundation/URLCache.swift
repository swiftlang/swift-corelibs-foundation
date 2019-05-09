// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import SwiftFoundation
#else
import Foundation
#endif

/*!
    @enum URLCache.StoragePolicy
    
    @discussion The URLCache.StoragePolicy enum defines constants that
    can be used to specify the type of storage that is allowable for an
    NSCachedURLResponse object that is to be stored in an URLCache.
    
    @constant URLCache.StoragePolicy.allowed Specifies that storage in an
    URLCache is allowed without restriction.

    @constant URLCache.StoragePolicy.allowedInMemoryOnly Specifies that
    storage in an URLCache is allowed; however storage should be
    done in memory only, no disk storage should be done.

    @constant URLCache.StoragePolicy.notAllowed Specifies that storage in an
    URLCache is not allowed in any fashion, either in memory or on
    disk.
*/
extension URLCache {
    public enum StoragePolicy : UInt {
        
        case allowed
        case allowedInMemoryOnly
        case notAllowed
    }
}

/*!
    @class CachedURLResponse
    CachedURLResponse is a class whose objects functions as a wrapper for
    objects that are stored in the framework's caching system. 
    It is used to maintain characteristics and attributes of a cached 
    object. 
*/
open class CachedURLResponse : NSObject, NSSecureCoding, NSCopying {
    
    public required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            /* Unkeyed unarchiving is not supported. */
            return nil
        }

        guard let data = aDecoder.decodeObject(of: NSData.self, forKey: "Data") else {
            return nil
        }
        guard let response = aDecoder.decodeObject(of: URLResponse.self, forKey: "URLResponse") else {
            return nil
        }
        guard let storagePolicyValue = aDecoder.decodeObject(of: NSNumber.self, forKey: "StoragePolicy") else {
            return nil
        }
        guard let storagePolicy = URLCache.StoragePolicy(rawValue: storagePolicyValue.uintValue) else {
            return nil
        }
        let userInfo = aDecoder.decodeObject(of: NSDictionary.self, forKey: "UserInfo")

        self.data = data as Data
        self.response = response
        self.storagePolicy = storagePolicy
        self.userInfo = userInfo?._swiftObject
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            fatalError("We do not support saving to a non-keyed coder.")
        }

        aCoder.encode(data as NSData, forKey: "Data")
        aCoder.encode(response, forKey: "URLResponse")
        aCoder.encode(NSNumber(value: storagePolicy.rawValue), forKey: "StoragePolicy")
        if let userInfo = userInfo {
            aCoder.encode(userInfo._nsObject, forKey: "UserInfo")
        }
    }
    
    static public var supportsSecureCoding: Bool {
        return true
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }

    /*!
        @method initWithResponse:data
        @abstract Initializes an CachedURLResponse with the given
        response and data.
        @discussion A default URLCache.StoragePolicy is used for
        CachedURLResponse objects initialized with this method:
        URLCache.StoragePolicy.allowed.
        @param response a URLResponse object.
        @param data an Data object representing the URL content
        corresponding to the given response.
        @result an initialized CachedURLResponse.
    */
    public init(response: URLResponse, data: Data) {
        self.response = response.copy() as! URLResponse
        self.data = data
        self.userInfo = nil
        self.storagePolicy = .allowed
    }
    
    /*! 
        @method initWithResponse:data:userInfo:storagePolicy:
        @abstract Initializes an NSCachedURLResponse with the given
        response, data, user-info dictionary, and storage policy.
        @param response a URLResponse object.
        @param data an NSData object representing the URL content
        corresponding to the given response.
        @param userInfo a dictionary user-specified information to be
        stored with the NSCachedURLResponse.
        @param storagePolicy an URLCache.StoragePolicy constant.
        @result an initialized CachedURLResponse.
    */
    public init(response: URLResponse, data: Data, userInfo: [AnyHashable : Any]? = nil, storagePolicy: URLCache.StoragePolicy) {
        self.response = response.copy() as! URLResponse
        self.data = data
        self.userInfo = userInfo
        self.storagePolicy = storagePolicy
    }
    
    /*! 
        @method response
        @abstract Returns the response wrapped by this instance. 
        @result The response wrapped by this instance. 
    */
    /*@NSCopying*/ open private(set) var response: URLResponse
    
    /*! 
        @method data
        @abstract Returns the data of the receiver. 
        @result The data of the receiver. 
    */
    /*@NSCopying*/ open private(set) var data: Data
    
    /*! 
        @method userInfo
        @abstract Returns the userInfo dictionary of the receiver. 
        @result The userInfo dictionary of the receiver. 
    */
    open private(set) var userInfo: [AnyHashable : Any]?
    
    /*! 
        @method storagePolicy
        @abstract Returns the URLCache.StoragePolicy constant of the receiver.
        @result The URLCache.StoragePolicy constant of the receiver.
    */
    open private(set) var storagePolicy: URLCache.StoragePolicy

    open override func isEqual(_ value: Any?) -> Bool {
        switch value {
        case let other as CachedURLResponse:
            return self.isEqual(to: other)
        default:
            return false
        }
    }

    private func isEqual(to other: CachedURLResponse) -> Bool {
        if self === other {
            return true
        }

        // We cannot compare userInfo because of the values are Any, which
        // doesn't conform to Equatable.
        return self.response == other.response &&
                self.data == other.data &&
                self.storagePolicy == other.storagePolicy
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(response)
        hasher.combine(data)
        hasher.combine(storagePolicy)
        return hasher.finalize()
    }
}

open class URLCache : NSObject {
    
    /*! 
        @method sharedURLCache
        @abstract Returns the shared URLCache instance.
        @discussion Unless set explicitly, this method returns an URLCache
        instance created with the following default values:
        <ul>
        <li>Memory capacity: 4 megabytes (4 * 1024 * 1024 bytes)
        <li>Disk capacity: 20 megabytes (20 * 1024 * 1024 bytes)
        <li>Disk path: <nobr>(user home directory)/Library/Caches/(application bundle id)</nobr> 
        </ul>
        <p>Users who do not have special caching requirements or
        constraints should find the default shared cache instance
        acceptable. If this default shared cache instance is not
        acceptable, the property can be set with a different URLCache
        instance to be returned from this method.
        @result the shared URLCache instance.
    */
    open class var shared: URLCache {
        get {
            NSUnimplemented()
        }
        set {
            NSUnimplemented()
        }
    }

    /*! 
        @method initWithMemoryCapacity:diskCapacity:diskPath:
        @abstract Initializes an URLCache with the given capacity and
        path.
        @discussion The returned URLCache is backed by disk, so
        developers can be more liberal with space when choosing the
        capacity for this kind of cache. A disk cache measured in the tens
        of megabytes should be acceptable in most cases.
        @param capacity the capacity, measured in bytes, for the cache.
        @param path the path on disk where the cache data is stored.
        @result an initialized URLCache, with the given capacity, backed
        by disk.
    */
    public init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) { NSUnimplemented() }
    
    /*! 
        @method cachedResponseForRequest:
        @abstract Returns the NSCachedURLResponse stored in the cache with
        the given request.
        @discussion The method returns nil if there is no
        NSCachedURLResponse stored using the given request.
        @param request the NSURLRequest to use as a key for the lookup.
        @result The NSCachedURLResponse stored in the cache with the given
        request, or nil if there is no NSCachedURLResponse stored with the
        given request.
    */
    open func cachedResponse(for request: URLRequest) -> CachedURLResponse? { NSUnimplemented() }
    
    /*! 
        @method storeCachedResponse:forRequest:
        @abstract Stores the given NSCachedURLResponse in the cache using
        the given request.
        @param cachedResponse The cached response to store.
        @param request the NSURLRequest to use as a key for the storage.
    */
    open func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) { NSUnimplemented() }
    
    /*! 
        @method removeCachedResponseForRequest:
        @abstract Removes the NSCachedURLResponse from the cache that is
        stored using the given request. 
        @discussion No action is taken if there is no NSCachedURLResponse
        stored with the given request.
        @param request the NSURLRequest to use as a key for the lookup.
    */
    open func removeCachedResponse(for request: URLRequest) { NSUnimplemented() }
    
    /*! 
        @method removeAllCachedResponses
        @abstract Clears the given cache, removing all NSCachedURLResponse
        objects that it stores.
    */
    open func removeAllCachedResponses() { NSUnimplemented() }
    
    /*!
     @method removeCachedResponsesSince:
     @abstract Clears the given cache of any cached responses since the provided date.
     */
    open func removeCachedResponses(since date: Date) { NSUnimplemented() }
    
    /*! 
        @method memoryCapacity
        @abstract In-memory capacity of the receiver. 
        @discussion At the time this call is made, the in-memory cache will truncate its contents to the size given, if necessary.
        @result The in-memory capacity, measured in bytes, for the receiver. 
    */
    open var memoryCapacity: Int
    
    /*! 
        @method diskCapacity
        @abstract The on-disk capacity of the receiver. 
        @discussion At the time this call is made, the on-disk cache will truncate its contents to the size given, if necessary.
        @param diskCapacity the new on-disk capacity, measured in bytes, for the receiver.
    */
    open var diskCapacity: Int
    
    /*! 
        @method currentMemoryUsage
        @abstract Returns the current amount of space consumed by the
        in-memory cache of the receiver.
        @discussion This size, measured in bytes, indicates the current
        usage of the in-memory cache. 
        @result the current usage of the in-memory cache of the receiver.
    */
    open var currentMemoryUsage: Int { NSUnimplemented() }
    
    /*! 
        @method currentDiskUsage
        @abstract Returns the current amount of space consumed by the
        on-disk cache of the receiver.
        @discussion This size, measured in bytes, indicates the current
        usage of the on-disk cache. 
        @result the current usage of the on-disk cache of the receiver.
    */
    open var currentDiskUsage: Int { NSUnimplemented() }
}

extension URLCache {
    public func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) { NSUnimplemented() }
    public func getCachedResponse(for dataTask: URLSessionDataTask, completionHandler: (CachedURLResponse?) -> Void) { NSUnimplemented() }
    public func removeCachedResponse(for dataTask: URLSessionDataTask) { NSUnimplemented() }
}
