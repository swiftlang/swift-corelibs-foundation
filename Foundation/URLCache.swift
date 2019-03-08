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
import SQLite3

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
    
    private static var sharedCache: URLCache? {
        willSet {
            URLCache.sharedCache?.syncQ.sync {
                URLCache.sharedCache?._databaseClient?.close()
                URLCache.sharedCache?.flushDatabase()
            }
        }
        didSet {
            URLCache.sharedCache?.syncQ.sync {
                URLCache.sharedCache?.setupCacheDatabaseIfNotExist()
            }
        }
    }
    
    private let syncQ = DispatchQueue(label: "org.swift.URLCache.syncQ")
    private let _baseDiskPath: String?
    private var _databaseClient: _CacheSQLiteClient?
    
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
                    let fourMegaByte = 4 * 1024 * 1024
                    let twentyMegaByte = 20 * 1024 * 1024
                    let cacheDirectoryPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.path ?? "\(NSHomeDirectory())/Library/Caches/"
                    let path = "\(cacheDirectoryPath)\(Bundle.main.bundleIdentifier ?? UUID().uuidString)"
                    let cache = URLCache(memoryCapacity: fourMegaByte, diskCapacity: twentyMegaByte, diskPath: path)
                    sharedCache = cache
                    return cache
                }
            }
        }
        set {
            sharedSyncQ.sync { sharedCache = newValue }
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
    public init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) {
        self.memoryCapacity = memoryCapacity
        self.diskCapacity = diskCapacity
        self._baseDiskPath = path
        
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
    
    private func flushDatabase() {
        guard let path = _baseDiskPath else { return }
        
        do {
            let dbPath = path.appending("/Cache.db")
            try FileManager.default.removeItem(atPath: dbPath)
        } catch {
            fatalError("Unable to flush database for URLCache: \(error.localizedDescription)")
        }
    }
    
}

extension URLCache {
    public func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) { NSUnimplemented() }
    public func getCachedResponse(for dataTask: URLSessionDataTask, completionHandler: (CachedURLResponse?) -> Void) { NSUnimplemented() }
    public func removeCachedResponse(for dataTask: URLSessionDataTask) { NSUnimplemented() }
}

extension URLCache {
    
    private func setupCacheDatabaseIfNotExist() {
        guard let path = _baseDiskPath else { return }
        
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            } catch {
                fatalError("Unable to create directories for URLCache: \(error.localizedDescription)")
            }
        }
        
        // Close the currently opened database connection(if any), before creating/replacing the db file
        _databaseClient?.close()
        
        let dbPath = path.appending("/Cache.db")
        if !FileManager.default.createFile(atPath: dbPath, contents: nil, attributes: nil) {
            fatalError("Unable to setup database for URLCache")
        }
        
        _databaseClient = _CacheSQLiteClient(databasePath: dbPath)
        if _databaseClient == nil {
            _databaseClient?.close()
            flushDatabase()
            fatalError("Unable to setup database for URLCache")
        }
        
        if !createTables() {
            _databaseClient?.close()
            flushDatabase()
            fatalError("Unable to setup database for URLCache: Tables not created")
        }
        
        if !createIndicesForTables() {
            _databaseClient?.close()
            flushDatabase()
            fatalError("Unable to setup database for URLCache: Indices not created for tables")
        }
    }
    
    private func createTables() -> Bool {
        guard _databaseClient != nil else {
            fatalError("Cannot create table before database setup")
        }
        
        let tableSQLs = [
            "CREATE TABLE cfurl_cache_response(entry_ID INTEGER PRIMARY KEY, version INTEGER, hash_value VARCHAR, storage_policy INTEGER, request_key VARCHAR, time_stamp DATETIME, partition VARCHAR)",
            "CREATE TABLE cfurl_cache_receiver_data(entry_ID INTEGER PRIMARY KEY, isDataOnFS INTEGER, receiver_data BLOB)",
            "CREATE TABLE cfurl_cache_blob_data(entry_ID INTEGER PRIMARY KEY, response_object BLOB, request_object BLOB, proto_props BLOB, user_info BLOB)",
            "CREATE TABLE cfurl_cache_schema_version(schema_version INTEGER)"
        ]
        
        for sql in tableSQLs {
            if let isSuccess = _databaseClient?.execute(sql: sql), !isSuccess {
                return false
            }
        }
        
        return true
    }
    
    private func createIndicesForTables() -> Bool {
        guard _databaseClient != nil else {
            fatalError("Cannot create table before database setup")
        }
        
        let indicesSQLs = [
            "CREATE INDEX proto_props_index ON cfurl_cache_blob_data(entry_ID)",
            "CREATE INDEX receiver_data_index ON cfurl_cache_receiver_data(entry_ID)",
            "CREATE INDEX request_key_index ON cfurl_cache_response(request_key)",
            "CREATE INDEX time_stamp_index ON cfurl_cache_response(time_stamp)"
        ]
        
        for sql in indicesSQLs {
            if let isSuccess = _databaseClient?.execute(sql: sql), !isSuccess {
                return false
            }
        }
        
        return true
    }
    
}

fileprivate struct _CacheSQLiteClient {
    
    private var database: OpaquePointer?
    
    init?(databasePath: String) {
        if sqlite3_open_v2(databasePath, &database, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) != SQLITE_OK {
            return nil
        }
    }
    
    func execute(sql: String) -> Bool {
        guard let db = database else { return false }
        
        return sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK
    }
    
    mutating func close() {
        guard let db = database else { return }
        
        sqlite3_close_v2(db)
        database = nil
    }
    
}
