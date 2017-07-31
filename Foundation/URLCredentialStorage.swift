// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/*!
    @class URLCredential.Storage
    @discussion URLCredential.Storage implements a singleton object (shared instance) which manages the shared credentials cache. Note: Whereas in Mac OS X any application can access any credential with a persistence of URLCredential.Persistence.permanent provided the user gives permission, in iPhone OS an application can access only its own credentials.
*/
open class URLCredentialStorage: NSObject {
    
    /*!
        @method sharedCredentialStorage
        @abstract Get the shared singleton authentication storage
        @result the shared authentication storage
    */
    open class var shared: URLCredentialStorage { get { NSUnimplemented() } }
    
    /*!
        @method credentialsForProtectionSpace:
        @abstract Get a dictionary mapping usernames to credentials for the specified protection space.
        @param protectionSpace An URLProtectionSpace indicating the protection space for which to get credentials
        @result A dictionary where the keys are usernames and the values are the corresponding URLCredentials.
    */
    open func credentials(for space: URLProtectionSpace) -> [String : URLCredential]? { NSUnimplemented() }
    
    /*!
        @method allCredentials
        @abstract Get a dictionary mapping URLProtectionSpaces to dictionaries which map usernames to URLCredentials
        @result an NSDictionary where the keys are URLProtectionSpaces
        and the values are dictionaries, in which the keys are usernames
        and the values are URLCredentials
    */
    open var allCredentials: [URLProtectionSpace : [String : URLCredential]] { NSUnimplemented() }
    
    /*!
        @method setCredential:forProtectionSpace:
        @abstract Add a new credential to the set for the specified protection space or replace an existing one.
        @param credential The credential to set.
        @param space The protection space for which to add it. 
        @discussion Multiple credentials may be set for a given protection space, but each must have
        a distinct user. If a credential with the same user is already set for the protection space,
        the new one will replace it.
    */
    open func set(_ credential: URLCredential, for space: URLProtectionSpace) { NSUnimplemented() }
    
    /*!
        @method removeCredential:forProtectionSpace:
        @abstract Remove the credential from the set for the specified protection space.
        @param credential The credential to remove.
        @param space The protection space for which a credential should be removed
        @discussion The credential is removed from both persistent and temporary storage. A credential that
        has a persistence policy of URLCredential.Persistence.synchronizable will fail.
        See removeCredential:forProtectionSpace:options.
    */
    open func remove(_ credential: URLCredential, for space: URLProtectionSpace) { NSUnimplemented() }
    
    /*!
     @method removeCredential:forProtectionSpace:options
     @abstract Remove the credential from the set for the specified protection space based on options.
     @param credential The credential to remove.
     @param space The protection space for which a credential should be removed
     @param options A dictionary containing options to consider when removing the credential.  This should
     be used when trying to delete a credential that has the URLCredential.Persistence.synchronizable policy.
     Please note that when URLCredential objects that have a URLCredential.Persistence.synchronizable policy
     are removed, the credential will be removed on all devices that contain this credential.
     @discussion The credential is removed from both persistent and temporary storage.
     */
    open func remove(_ credential: URLCredential, for space: URLProtectionSpace, options: [String : AnyObject]? = [:]) { NSUnimplemented() }
    
    /*!
        @method defaultCredentialForProtectionSpace:
        @abstract Get the default credential for the specified protection space.
        @param space The protection space for which to get the default credential.
    */
    open func defaultCredential(for space: URLProtectionSpace) -> URLCredential? { NSUnimplemented() }
    
    /*!
        @method setDefaultCredential:forProtectionSpace:
        @abstract Set the default credential for the specified protection space.
        @param credential The credential to set as default.
        @param space The protection space for which the credential should be set as default.
        @discussion If the credential is not yet in the set for the protection space, it will be added to it.
    */
    open func setDefaultCredential(_ credential: URLCredential, for space: URLProtectionSpace) { NSUnimplemented() }
}

extension URLCredentialStorage {
    public func getCredentials(for protectionSpace: URLProtectionSpace, task: URLSessionTask, completionHandler: ([String : URLCredential]?) -> Void) { NSUnimplemented() }
    public func set(_ credential: URLCredential, for protectionSpace: URLProtectionSpace, task: URLSessionTask) { NSUnimplemented() }
    public func remove(_ credential: URLCredential, for protectionSpace: URLProtectionSpace, options: [String : AnyObject]? = [:], task: URLSessionTask) { NSUnimplemented() }
    public func getDefaultCredential(for space: URLProtectionSpace, task: URLSessionTask, completionHandler: (URLCredential?) -> Void) { NSUnimplemented() }
    public func setDefaultCredential(_ credential: URLCredential, for protectionSpace: URLProtectionSpace, task: URLSessionTask) { NSUnimplemented() }
}

public extension Notification.Name {
    /*!
        @const NSURLCredentialStorageChangedNotification
        @abstract This notification is sent on the main thread whenever
        the set of stored credentials changes.
    */
    public static let NSURLCredentialStorageChanged = NSNotification.Name(rawValue: "NSURLCredentialStorageChangedNotification")
}

/*
 *  NSURLCredentialStorageRemoveSynchronizableCredentials - (NSNumber value)
 *		A key that indicates either @YES or @NO that credentials which contain the NSURLCredentialPersistenceSynchronizable
 *		attribute should be removed.  If the key is missing or the value is @NO, then no attempt will be made
 *		to remove such a credential.
 */
public let NSURLCredentialStorageRemoveSynchronizableCredentials: String = "NSURLCredentialStorageRemoveSynchronizableCredentials"

