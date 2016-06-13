// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/*!
    @enum NSHTTPCookieAcceptPolicy
    @abstract Values for the different cookie accept policies
    @constant NSHTTPCookieAcceptPolicyAlways Accept all cookies
    @constant NSHTTPCookieAcceptPolicyNever Reject all cookies
    @constant NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain Accept cookies
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
    @class NSHTTPCookieStorage 
    @discussion NSHTTPCookieStorage implements a singleton object (shared
    instance) which manages the shared cookie store.  It has methods
    to allow clients to set and remove cookies, and get the current
    set of cookies.  It also has convenience methods to parse and
    generate cookie-related HTTP header fields.
*/
public class HTTPCookieStorage: NSObject {
    
    public override init() { NSUnimplemented() }
    
    /*!
        @method sharedHTTPCookieStorage
        @abstract Get the shared cookie storage in the default location.
        @result The shared cookie storage
        @discussion Starting in OS X 10.11, each app has its own sharedHTTPCookieStorage singleton, 
        which will not be shared with other applications.
    */
    class var shared: HTTPCookieStorage { get { NSUnimplemented() } }
    
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
    class func sharedCookieStorage(forGroupContainerIdentifier identifier: String) -> HTTPCookieStorage { NSUnimplemented() }
    
    /*!
        @method setCookie:
        @abstract Set a cookie
        @discussion The cookie will override an existing cookie with the
        same name, domain and path, if any.
    */
    public func setCookie(_ cookie: HTTPCookie) { NSUnimplemented() }
    
    /*!
        @method deleteCookie:
        @abstract Delete the specified cookie
    */
    public func deleteCookie(_ cookie: HTTPCookie) { NSUnimplemented() }
    
    /*!
     @method removeCookiesSince:
     @abstract Delete all cookies from the cookie storage since the provided date.
     */
    public func removeCookiesSinceDate(_ date: Date) { NSUnimplemented() }
    
    /*!
        @method cookiesForURL:
        @abstract Returns an array of cookies to send to the given URL.
        @param URL The URL for which to get cookies.
        @result an NSArray of NSHTTPCookie objects.
        @discussion The cookie manager examines the cookies it stores and
        includes those which should be sent to the given URL. You can use
        <tt>+[NSCookie requestHeaderFieldsWithCookies:]</tt> to turn this array
        into a set of header fields to add to a request.
    */
    public func cookiesForURL(_ url: URL) -> [HTTPCookie]? { NSUnimplemented() }
    
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
    public func setCookies(_ cookies: [HTTPCookie], forURL url: URL?, mainDocumentURL: URL?) { NSUnimplemented() }
    
    /*!
        @method cookieAcceptPolicy
        @abstract The cookie accept policy preference of the
        receiver.
    */
    public var cookieAcceptPolicy: HTTPCookie.AcceptPolicy
    
    /*!
      @method sortedCookiesUsingDescriptors:
      @abstract Returns an array of all cookies in the store, sorted according to the key value and sorting direction of the NSSortDescriptors specified in the parameter.
      @param sortOrder an array of NSSortDescriptors which represent the preferred sort order of the resulting array.
      @discussion proper sorting of cookies may require extensive string conversion, which can be avoided by allowing the system to perform the sorting.  This API is to be preferred over the more generic -[NSHTTPCookieStorage cookies] API, if sorting is going to be performed.
    */
    public func sortedCookiesUsingDescriptors(_ sortOrder: [SortDescriptor]) -> [HTTPCookie] { NSUnimplemented() }
}

/*!
    @const NSHTTPCookieManagerCookiesChangedNotification
    @abstract Notification sent when the set of cookies changes
*/
public let NSHTTPCookieManagerCookiesChangedNotification: String = "" // NSUnimplemented

