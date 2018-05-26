// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
import Dispatch
import CoreFoundation

/*!
    @enum HTTPCookie.AcceptPolicy
    @abstract Values for the different cookie accept policies
    @constant HTTPCookie.AcceptPolicy.always Accept all cookies
    @constant HTTPCookie.AcceptPolicy.never Reject all cookies
    @constant HTTPCookie.AcceptPolicy.onlyFromMainDocumentDomain Accept cookies
    only from the main document domain
*/
extension HTTPCookie {
    public enum AcceptPolicy : UInt {
        case always
        case never
        case onlyFromMainDocumentDomain
    }
}


/*!
    @class HTTPCookieStorage 
    @discussion HTTPCookieStorage implements a singleton object (shared
    instance) which manages the shared cookie store.  It has methods
    to allow clients to set and remove cookies, and get the current
    set of cookies.  It also has convenience methods to parse and
    generate cookie-related HTTP header fields.
*/
open class HTTPCookieStorage: NSObject {

    /* both sharedStorage and sharedCookieStorages are synchronized on sharedSyncQ */
    private static var sharedStorage: HTTPCookieStorage?
    private static var sharedCookieStorages: [String: HTTPCookieStorage] = [:] //for group storage containers
    private static let sharedSyncQ = DispatchQueue(label: "org.swift.HTTPCookieStorage.sharedSyncQ")

    /* only modified in init */
    private var cookieFilePath: String!

    /* synchronized on syncQ, please don't use _allCookies directly outside of init/deinit */
    private var _allCookies: [String: HTTPCookie]
    private var allCookies: [String: HTTPCookie] {
        get {
            if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
                dispatchPrecondition(condition: DispatchPredicate.onQueue(self.syncQ))
            }
            return self._allCookies
        }
        set {
            if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
                dispatchPrecondition(condition: DispatchPredicate.onQueue(self.syncQ))
            }
            self._allCookies = newValue
        }
    }
    private let syncQ = DispatchQueue(label: "org.swift.HTTPCookieStorage.syncQ")

    private init(cookieStorageName: String) {
        _allCookies = [:]
        cookieAcceptPolicy = .always
        super.init()
        let bundlePath = Bundle.main.bundlePath
        var bundleName = bundlePath.components(separatedBy: "/").last!
        if let range = bundleName.range(of: ".", options: .backwards, range: nil, locale: nil) {
            bundleName = String(bundleName[..<range.lowerBound])
        }
        let cookieFolderPath = _CFXDGCreateDataHomePath()._swiftObject + "/" + bundleName
        cookieFilePath = filePath(path: cookieFolderPath, fileName: "/.cookies." + cookieStorageName, bundleName: bundleName)
        loadPersistedCookies()
    }

    private func loadPersistedCookies() {
        guard let cookiesData = try? Data(contentsOf: URL(fileURLWithPath: cookieFilePath)) else { return }
        guard let cookies = try? PropertyListSerialization.propertyList(from: cookiesData, format: nil) else { return }
        var cookies0 = cookies as? [String: [String: Any]] ?? [:]
        self.syncQ.sync {
            for key in cookies0.keys {
                if let cookie = createCookie(cookies0[key]!) {
                    allCookies[key] = cookie
                }
            }
        }
    }

    private func directory(with path: String) -> Bool {
        guard !FileManager.default.fileExists(atPath: path) else { return true }

        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            return false
        }
    }

    private func filePath(path: String, fileName: String, bundleName: String) -> String {
        if directory(with: path) {
            return path + fileName
        }
        //if we were unable to create the desired directory, create the cookie file
        //in a subFolder (named after the bundle) of the `pwd`
        return FileManager.default.currentDirectoryPath + "/" + bundleName + fileName
    }

    open var cookies: [HTTPCookie]? {
        return Array(self.syncQ.sync { self.allCookies.values })
    }
    
    /*!
        @method sharedHTTPCookieStorage
        @abstract Get the shared cookie storage in the default location.
        @result The shared cookie storage
        @discussion Starting in OS X 10.11, each app has its own sharedHTTPCookieStorage singleton, 
        which will not be shared with other applications.
    */
    open class var shared: HTTPCookieStorage {
        get {
            return sharedSyncQ.sync {
                if sharedStorage == nil {
                    sharedStorage = HTTPCookieStorage(cookieStorageName: "shared")
                }
                return sharedStorage!
            }
        }
    }
    
    /*!
        @method sharedCookieStorageForGroupContainerIdentifier:
        @abstract Get the cookie storage for the container associated with the specified application group identifier
        @param identifier The application group identifier
        @result A cookie storage with a persistent store in the application group container
        @discussion By default, applications and associated app extensions have different data containers, which means
        that the sharedHTTPCookieStorage singleton will refer to different persistent cookie stores in an application and
        any app extensions that it contains. This method allows clients to create a persistent cookie storage that can be
        shared among all applications and extensions with access to the same application group. Subsequent calls to this
        method with the same identifier will return the same cookie storage instance.
     */
    open class func sharedCookieStorage(forGroupContainerIdentifier identifier: String) -> HTTPCookieStorage {
        return sharedSyncQ.sync {
            guard let cookieStorage = sharedCookieStorages[identifier] else {
                let newCookieStorage = HTTPCookieStorage(cookieStorageName: identifier)
                sharedCookieStorages[identifier] = newCookieStorage
                return newCookieStorage
            }
            return cookieStorage
        }
    }

    
    /*!
        @method setCookie:
        @abstract Set a cookie
        @discussion The cookie will override an existing cookie with the
        same name, domain and path, if any.
    */
    open func setCookie(_ cookie: HTTPCookie) {
        self.syncQ.sync {
            guard cookieAcceptPolicy != .never else { return }

            //add or override
            let key = cookie.domain + cookie.path + cookie.name
            if let _ = allCookies.index(forKey: key) {
                allCookies.updateValue(cookie, forKey: key)
            } else {
                allCookies[key] = cookie
            }

            //remove stale cookies, these may include the one we just added
            let expired = allCookies.filter { (_, value) in value.expiresDate != nil && value.expiresDate!.timeIntervalSinceNow < 0 }
            for (key,_) in expired {
                self.allCookies.removeValue(forKey: key)
            }

            updatePersistentStore()
        }
    }
    
    open override var description: String {
        return "<NSHTTPCookieStorage cookies count:\(cookies?.count ?? 0)>"
    }

    private func createCookie(_ properties: [String: Any]) -> HTTPCookie? {
        var cookieProperties: [HTTPCookiePropertyKey: Any] = [:]
        for (key, value) in properties {
            if key == "Expires" {
                guard let timestamp  = value as? NSNumber else { continue }
                cookieProperties[HTTPCookiePropertyKey(rawValue: key)] = Date(timeIntervalSince1970: timestamp.doubleValue)
            } else {
                cookieProperties[HTTPCookiePropertyKey(rawValue: key)] = properties[key]
            }
        }
        return HTTPCookie(properties: cookieProperties)
    }

    private func updatePersistentStore() {
        if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
            dispatchPrecondition(condition: DispatchPredicate.onQueue(self.syncQ))
        }

        //persist cookies
        var persistDictionary: [String : [String : Any]] = [:]
        let persistable = self.allCookies.filter { (_, value) in
            value.expiresDate != nil &&
            value.isSessionOnly == false &&
            value.expiresDate!.timeIntervalSinceNow > 0
        }

        for (key,cookie) in persistable {
            persistDictionary[key] = cookie.persistableDictionary()
        }

        let nsdict = _SwiftValue.store(persistDictionary) as! NSDictionary
        _ = nsdict.write(toFile: cookieFilePath, atomically: true)
    }

    /*!
        @method lockedDeleteCookie:
        @abstract Delete the specified cookie, for internal callers already on syncQ.
    */
    private func lockedDeleteCookie(_ cookie: HTTPCookie) {
        let key = cookie.domain + cookie.path + cookie.name
        self.allCookies.removeValue(forKey: key)
        updatePersistentStore()
    }

    /*!
        @method deleteCookie:
        @abstract Delete the specified cookie
    */
    open func deleteCookie(_ cookie: HTTPCookie) {
        self.syncQ.sync {
            self.lockedDeleteCookie(cookie)
        }
    }
    
    /*!
     @method removeCookiesSince:
     @abstract Delete all cookies from the cookie storage since the provided date.
     */
    open func removeCookies(since date: Date) {
        self.syncQ.sync {
            let cookiesSinceDate = self.allCookies.values.filter {
                $0.properties![.created] as! Double >  date.timeIntervalSinceReferenceDate
            }
            for cookie in cookiesSinceDate {
                lockedDeleteCookie(cookie)
            }
            updatePersistentStore()
        }
    }

    /*!
        @method cookiesForURL:
        @abstract Returns an array of cookies to send to the given URL.
        @param URL The URL for which to get cookies.
        @result an Array of HTTPCookie objects.
        @discussion The cookie manager examines the cookies it stores and
        includes those which should be sent to the given URL. You can use
        <tt>+[NSCookie requestHeaderFieldsWithCookies:]</tt> to turn this array
        into a set of header fields to add to a request.
    */
    open func cookies(for url: URL) -> [HTTPCookie]? {
        guard let host = url.host else { return nil }
        return Array(self.syncQ.sync(execute: {allCookies}).values.filter{ $0.domain == host })
    }
    
    /*!
        @method setCookies:forURL:mainDocumentURL:
        @abstract Adds an array cookies to the cookie store, following the
        cookie accept policy.
        @param cookies The cookies to set.
        @param URL The URL from which the cookies were sent.
        @param mainDocumentURL The main document URL to be used as a base for the "same
        domain as main document" policy.
        @discussion For mainDocumentURL, the caller should pass the URL for
        an appropriate main document, if known. For example, when loading
        a web page, the URL of the main html document for the top-level
        frame should be passed. To save cookies based on a set of response
        headers, you can use <tt>+[NSCookie
        cookiesWithResponseHeaderFields:forURL:]</tt> on a header field
        dictionary and then use this method to store the resulting cookies
        in accordance with policy settings.
    */
    open func setCookies(_ cookies: [HTTPCookie], for url: URL?, mainDocumentURL: URL?) {
        //if the cookieAcceptPolicy is `never` we don't have anything to do
        guard cookieAcceptPolicy != .never else { return }

        //if the urls don't have a host, we cannot do anything
        guard let urlHost = url?.host else { return }

        if mainDocumentURL != nil && cookieAcceptPolicy == .onlyFromMainDocumentDomain {
            guard let mainDocumentHost = mainDocumentURL?.host else { return }

            //the url.host must be a suffix of manDocumentURL.host, this is based on Darwin's behaviour
            guard mainDocumentHost.hasSuffix(urlHost) else { return }
        }

        //save only those cookies whose domain matches with the url.host
        let validCookies = cookies.filter { urlHost == $0.domain }
        for cookie in validCookies {
            setCookie(cookie)
        }
    }
    
    /*!
        @method cookieAcceptPolicy
        @abstract The cookie accept policy preference of the
        receiver.
    */
    open var cookieAcceptPolicy: HTTPCookie.AcceptPolicy
    
    /*!
      @method sortedCookiesUsingDescriptors:
      @abstract Returns an array of all cookies in the store, sorted according to the key value and sorting direction of the NSSortDescriptors specified in the parameter.
      @param sortOrder an array of NSSortDescriptors which represent the preferred sort order of the resulting array.
      @discussion proper sorting of cookies may require extensive string conversion, which can be avoided by allowing the system to perform the sorting.  This API is to be preferred over the more generic -[HTTPCookieStorage cookies] API, if sorting is going to be performed.
    */
    open func sortedCookies(using sortOrder: [NSSortDescriptor]) -> [HTTPCookie] { NSUnimplemented() }
}

public extension Notification.Name {
    /*!
     @const NSHTTPCookieManagerCookiesChangedNotification
     @abstract Notification sent when the set of cookies changes
     */
    public static let NSHTTPCookieManagerCookiesChanged = Notification.Name(rawValue: "NSHTTPCookieManagerCookiesChangedNotification")
}

extension HTTPCookie {
    internal func persistableDictionary() -> [String: Any] {
        var properties: [String: Any] = [:]
        properties[HTTPCookiePropertyKey.name.rawValue] = name
        properties[HTTPCookiePropertyKey.path.rawValue] = path
        properties[HTTPCookiePropertyKey.value.rawValue] = _value
        properties[HTTPCookiePropertyKey.secure.rawValue] = _secure
        properties[HTTPCookiePropertyKey.version.rawValue] = _version
        properties[HTTPCookiePropertyKey.expires.rawValue] = _expiresDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970 //OK?
        properties[HTTPCookiePropertyKey.domain.rawValue] = _domain
        if let commentURL = _commentURL {
            properties[HTTPCookiePropertyKey.commentURL.rawValue] = commentURL.absoluteString
        }
        if let comment = _comment {
            properties[HTTPCookiePropertyKey.comment.rawValue] = comment
        }
        properties[HTTPCookiePropertyKey.port.rawValue] = portList
        return properties
    }
}
