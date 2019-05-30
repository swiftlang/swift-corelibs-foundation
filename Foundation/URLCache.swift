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
    
    /*! 
    private static let _sharedCacheLock: NSLock = NSLock()
    private static var _sharedCache: URLCache!

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
            _sharedCacheLock.lock()
            defer { _sharedCacheLock.unlock() }
            if _sharedCache == nil {
                // TODO: diskPath?
                _sharedCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)
            }

            return _sharedCache
        }
        set {
            _sharedCacheLock.lock()
            defer { _sharedCacheLock.unlock() }
            _sharedCache = newValue
        }
    }

    /*! 
    private let _memoryCache: _URLMemoryCache<_URLCacheKey, CachedURLResponse>
    private let _diskPath: String
    private let _diskCache: _URLDiskCache<_URLCacheKey, CachedURLResponse>

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
        self._diskPath = path ?? "/" // TODO?
        self._memoryCache = _URLMemoryCache(capacity: memoryCapacity)
        self._diskCache = _URLDiskCache(capacity: diskCapacity, path: self._diskPath)
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
    open func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        guard let key = _URLCacheKey(request: request) else {
            return nil
        }

        return _memoryCache[key] ?? _diskCache[key]
    }
    
    /*! 
        @method storeCachedResponse:forRequest:
        @abstract Stores the given NSCachedURLResponse in the cache using
        the given request.
        @param cachedResponse The cached response to store.
        @param request the NSURLRequest to use as a key for the storage.
    */
    open func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        guard cachedResponse.storagePolicy != .notAllowed else {
            // Don't store. But don't remove - may be cache reuse case.
            return
        }

        guard let key = _URLCacheKey(request: request) else {
            return
        }

        _memoryCache[key] = cachedResponse
        if cachedResponse.storagePolicy != .allowedInMemoryOnly {
            _diskCache[key] = cachedResponse
        } else {
            // If we are not supposed to write to disk, ensure any existing
            // entry is removed.
            _diskCache[key] = nil
        }
    }
    
    /*! 
        @method removeCachedResponseForRequest:
        @abstract Removes the NSCachedURLResponse from the cache that is
        stored using the given request. 
        @discussion No action is taken if there is no NSCachedURLResponse
        stored with the given request.
        @param request the NSURLRequest to use as a key for the lookup.
    */
    open func removeCachedResponse(for request: URLRequest) {
        guard let key = _URLCacheKey(request: request) else {
            return
        }

        _memoryCache[key] = nil
        _diskCache[key] = nil
    }
    
    /*! 
        @method removeAllCachedResponses
        @abstract Clears the given cache, removing all NSCachedURLResponse
        objects that it stores.
    */
    open func removeAllCachedResponses() {
        _memoryCache.removeAll()
        _diskCache.removeAll()
    }
    
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
    open var memoryCapacity: Int {
        get { return _memoryCache.capacity }
        set { _memoryCache.capacity = newValue }
    }
    
    /*! 
        @method diskCapacity
        @abstract The on-disk capacity of the receiver. 
        @discussion At the time this call is made, the on-disk cache will truncate its contents to the size given, if necessary.
        @param diskCapacity the new on-disk capacity, measured in bytes, for the receiver.
    */
    open var diskCapacity: Int {
        get { return _diskCache.capacity }
        set { _diskCache.capacity = newValue }
    }
    
    /*! 
        @method currentMemoryUsage
        @abstract Returns the current amount of space consumed by the
        in-memory cache of the receiver.
        @discussion This size, measured in bytes, indicates the current
        usage of the in-memory cache. 
        @result the current usage of the in-memory cache of the receiver.
    */
    open var currentMemoryUsage: Int {
        return _memoryCache.currentCost
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
        return _diskCache.currentCost
    }
}

extension URLCache {
    public func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) { NSUnimplemented() }
    public func getCachedResponse(for dataTask: URLSessionDataTask, completionHandler: (CachedURLResponse?) -> Void) { NSUnimplemented() }
    public func removeCachedResponse(for dataTask: URLSessionDataTask) { NSUnimplemented() }
}


private struct _URLCacheKey: Hashable {
    private let value: Int

    init?(request: URLRequest) {
        // TODO: find out the protocol, find out if there's a handler, find out
        // if it is cacheable (data, file, ... are not)


        var hasher = Hasher()
        hasher.combine(request) // TODO: we should not hash everything
        value = hasher.finalize()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}


private protocol _URLCacheEntry {
    var cost: Int { get }
}


extension CachedURLResponse: _URLCacheEntry {
    var cost: Int {
        return data.count
    }
}


private class _URLMemoryCache<Key: Hashable, Value: _URLCacheEntry> {
    private class Entry<Value> {
        let key: Key
        let value: Value
        let cost: Int
        var index: Array<Entry<Value>>.Index!
        // var prev: Entry<Value>? = nil
        // var next: Entry<Value>? = nil

        init(key: Key, value: Value, cost: Int) {
            self.key = key
            self.value = value
            self.cost = cost
        }
    }

    private var _entries: [Key: Entry<Value>]
    private var _lruList: [Entry<Value>]
    private let _lock: NSLock

    init(capacity: Int) {
        self._capacity = capacity
        self._entries = [:]
        self._lruList = []
        self._currentCost = 0
        self._lock = NSLock()
    }

    private var _capacity: Int
    var capacity: Int {
        get {
            _lock.lock()
            defer { _lock.unlock() }

            return _capacity
        }
        set {
            _lock.lock()
            defer { _lock.unlock() }

            _capacity = newValue
            _performGarbageCollectionWhileLocked()
        }
    }

    private var _currentCost: Int
    var currentCost: Int {
        get {
            _lock.lock()
            defer { _lock.unlock() }

            return _currentCost
        }
    }

    subscript(_ key: Key) -> Value? {
        get {
            _lock.lock()
            defer { _lock.unlock() }

            let entry = _findEntryWhileLocked(key)
            return entry?.value;
        }
        set {
            // TODO
            // Check if the size is OK for the memory cache, otherwise remove

            _lock.lock()
            defer { _lock.unlock() }

            if let existing = _findEntryWhileLocked(key) {
                _removeWhileLocked(existing)
            }

            guard let newValue = newValue else {
                return
            }

            let entry = Entry(key: key, value: newValue, cost: 1) // TODO: cost
            _entries[key] = entry
            entry.index = _lruList.endIndex
            _lruList.insert(entry, at: entry.index)
            _currentCost += 1 // TODO: cost
            _performGarbageCollectionWhileLocked()
        }
    }

    func removeAll() {
        _lock.lock()
        defer { _lock.unlock() }

        while let entry = _lruList.first {
            _removeWhileLocked(entry)
        }
    }

    private func _performGarbageCollectionWhileLocked() {
        while _currentCost > _capacity, let entry = _lruList.first {
            _removeWhileLocked(entry)
        }
    }

    private func _removeWhileLocked(_ entry: Entry<Value>) {
        _entries[entry.key] = nil
        _lruList.remove(at: entry.index)
        _currentCost -= entry.cost
    }

    private func _findEntryWhileLocked(_ key: Key) -> Entry<Value>? {
        guard let entry = _entries[key] else {
            return nil
        }

        _lruList.remove(at: entry.index)
        entry.index = _lruList.endIndex
        _lruList.insert(entry, at: entry.index)

        return entry
    }
}


private class _URLDiskCache<Key: Hashable, Value: NSCoding> {
    private let _path: String

    init(capacity: Int, path: String) {
        self._capacity = capacity
        self._path = path
        self._currentCost = 0 // TODO: read from disk

        // TODO: run capacity setter code?
    }

    private var _capacity: Int
    var capacity: Int {
        get {
            // TODO
            return _capacity
        }
        set {
            // TODO
            _capacity = newValue
        }
    }

    private var _currentCost: Int
    var currentCost: Int {
        get {
            // TODO
            return _currentCost
        }
    }

    subscript(_ key: Key) -> Value? {
        get {
            // TODO
            return nil
        }
        set {
            // TODO
        }
    }

    func removeAll() {
        // TODO
    }
}
