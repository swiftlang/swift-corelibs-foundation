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
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    static public var supportsSecureCoding: Bool {
        return true
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        NSUnimplemented()
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
    public init(response: URLResponse, data: Data) { NSUnimplemented() }
    
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
    public init(response: URLResponse, data: Data, userInfo: [AnyHashable : Any]? = [:], storagePolicy: URLCache.StoragePolicy) { NSUnimplemented() }
    
    /*! 
        @method response
        @abstract Returns the response wrapped by this instance. 
        @result The response wrapped by this instance. 
    */
    /*@NSCopying*/ open var response: URLResponse { NSUnimplemented() }
    
    /*! 
        @method data
        @abstract Returns the data of the receiver. 
        @result The data of the receiver. 
    */
    /*@NSCopying*/ open var data: Data { NSUnimplemented() }
    
    /*! 
        @method userInfo
        @abstract Returns the userInfo dictionary of the receiver. 
        @result The userInfo dictionary of the receiver. 
    */
    open var userInfo: [AnyHashable : Any]? { NSUnimplemented() }
    
    /*! 
        @method storagePolicy
        @abstract Returns the URLCache.StoragePolicy constant of the receiver.
        @result The URLCache.StoragePolicy constant of the receiver.
    */
    open var storagePolicy: URLCache.StoragePolicy { NSUnimplemented() }
}

open class URLCache : NSObject {
    
    private static let sharedSyncQ = DispatchQueue(label: "org.swift.URLCache.sharedSyncQ")
    private static var sharedCache: URLCache?
    
    private let syncQ = DispatchQueue(label: "org.swift.URLCache.syncQ")
    private var persistence: _CachePersistence?
    
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
            return sharedSyncQ.sync {
                if let cache = sharedCache {
                    return cache
                } else {
                    guard var cacheDirectoryUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                        fatalError("Unable to find cache directory")
                    }

                    let fourMegaByte = 4 * 1024 * 1024
                    let twentyMegaByte = 20 * 1024 * 1024
                    cacheDirectoryUrl.appendPathComponent(ProcessInfo.processInfo.processName)
                    let cache = URLCache(memoryCapacity: fourMegaByte, diskCapacity: twentyMegaByte, diskPath: cacheDirectoryUrl.path)
                    sharedCache = cache
                    cache.persistence?.setupCacheDirectory()
                    return cache
                }
            }
        }
        set {
            guard newValue !== sharedCache else { return }
            
            sharedSyncQ.sync {
                sharedCache = newValue
                newValue.persistence?.setupCacheDirectory()
            }
        }
    }

    private var allCaches: [String: CachedURLResponse] = [:]
    private var cacheSizeInMemory: Int = 0

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
    public init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) {
        self.memoryCapacity = memoryCapacity
        self.diskCapacity = diskCapacity

        // As per the function of URLCache, `diskCapacity` of `0` is assumed as no-persistence.
        if diskCapacity > 0, let _path = path {
            self.persistence = _CachePersistence(path: _path)
        }

        super.init()
    }
    
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
    open var currentMemoryUsage: Int {
        return self.syncQ.sync { self.cacheSizeInMemory }
    }
    
    /*! 
        @method currentDiskUsage
        @abstract Returns the current amount of space consumed by the
        on-disk cache of the receiver.
        @discussion This size, measured in bytes, indicates the current
        usage of the on-disk cache. 
        @result the current usage of the on-disk cache of the receiver.
    */
    open var currentDiskUsage: Int {
        return self.syncQ.sync { self.persistence?.cacheSizeInDisk ?? 0 }
    }

}

extension URLCache {
    public func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) { NSUnimplemented() }
    public func getCachedResponse(for dataTask: URLSessionDataTask, completionHandler: (CachedURLResponse?) -> Void) { NSUnimplemented() }
    public func removeCachedResponse(for dataTask: URLSessionDataTask) { NSUnimplemented() }
}

fileprivate struct _CachePersistence {

    let path: String

    // FIXME: Create a stored property
    // Update this value as the cache added and evicted
    var cacheSizeInDisk: Int {
        do {
            let subFiles = try FileManager.default.subpathsOfDirectory(atPath: path)
            var total: Int = 0
            for fileName in subFiles {
                let attributes = try FileManager.default.attributesOfItem(atPath: path.appending(fileName))
                total += (attributes[.size] as? Int) ?? 0
            }
            return total
        } catch {
            return 0
        }
    }

    func setupCacheDirectory() {
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }

    func saveCachedResponse(_ response: CachedURLResponse, for request: URLRequest) {
        do {
            if let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: response, requiringSecureCoding: true),
                let fileIdentifier = request.cacheFileIdentifier {
                let cacheFileURL = urlForFileIdentifier(fileIdentifier)
                try archivedData.write(to: cacheFileURL)
            }
        } catch {
            fatalError("Unable to save cache data: \(error.localizedDescription)")
        }
    }

    func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        guard let fileIdentifier = request.cacheFileIdentifier else {
            return nil
        }

        let url = urlForFileIdentifier(fileIdentifier)
        guard let data = try? Data(contentsOf: url),
            let response = try? NSKeyedUnarchiver.unarchivedObject(ofClasses:[CachedURLResponse.self], from: data) as? CachedURLResponse else {
            return nil
        }

        return response
    }

    private func urlForFileIdentifier(_ identifier: String) -> URL {
        return URL(fileURLWithPath: path).appendingPathComponent(identifier)
    }

}

extension URLRequest {

    fileprivate var cacheFileIdentifier: String? {
        guard let scheme = self.url?.scheme, scheme == "http" || scheme == "https",
            let method = httpMethod, !method.isEmpty,
            let urlString = url?.absoluteString else {
                return nil
        }

        var hashString = "\(abs(method.hashValue))-\(abs(urlString.hashValue))"

        if let userAgent = self.allHTTPHeaderFields?["User-Agent"], !userAgent.isEmpty {
            hashString.append("\(abs(userAgent.hashValue))")
        }

        if let acceptLanguage = self.allHTTPHeaderFields?["Accept-Language"], !acceptLanguage.isEmpty {
            hashString.append("-\(abs(acceptLanguage.hashValue))")
        }

        if let range = self.allHTTPHeaderFields?["Range"], !range.isEmpty {
            hashString.append("-\(abs(range.hashValue))")
        }

        if let data = self.httpBody, !data.isEmpty {
            hashString.append("-\(abs(data.hashValue))")
        }

        return hashString
    }

}
