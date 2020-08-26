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
    @class URLCredential.Storage
    @discussion URLCredential.Storage implements a singleton object (shared instance) which manages the shared credentials cache. Note: Whereas in Mac OS X any application can access any credential with a persistence of URLCredential.Persistence.permanent provided the user gives permission, in iPhone OS an application can access only its own credentials.
*/
open class URLCredentialStorage: NSObject {

    private static var _shared = URLCredentialStorage()

    /*!
        @method sharedCredentialStorage
        @abstract Get the shared singleton authentication storage
        @result the shared authentication storage
    */
    open class var shared: URLCredentialStorage { return _shared }

    private let _lock: NSLock
    private var _credentials: [URLProtectionSpace: [String: URLCredential]]
    private var _defaultCredentials: [URLProtectionSpace: URLCredential]

    public override init() {
        _lock = NSLock()
        _credentials = [:]
        _defaultCredentials = [:]
    }

    convenience init(ephemeral: Bool) {
        // Some URLCredentialStorages must be ephemeral, to support ephemeral URLSessions. They should not write anything to persistent storage.
        // All URLCredentialStorage instances are _currently_ ephemeral, so there's no need to record the value of 'ephemeral' here, but if we implement persistent storage in the future using platform secure storage, implementers of that functionality will have to heed this flag here.
        self.init()
    }
    
    /*!
        @method credentialsForProtectionSpace:
        @abstract Get a dictionary mapping usernames to credentials for the specified protection space.
        @param protectionSpace An URLProtectionSpace indicating the protection space for which to get credentials
        @result A dictionary where the keys are usernames and the values are the corresponding URLCredentials.
    */
    open func credentials(for space: URLProtectionSpace) -> [String : URLCredential]? {
        _lock.lock()
        defer { _lock.unlock() }
        return _credentials[space]
    }

    /*!
        @method allCredentials
        @abstract Get a dictionary mapping URLProtectionSpaces to dictionaries which map usernames to URLCredentials
        @result an NSDictionary where the keys are URLProtectionSpaces
        and the values are dictionaries, in which the keys are usernames
        and the values are URLCredentials
    */
    open var allCredentials: [URLProtectionSpace : [String : URLCredential]] {
        _lock.lock()
        defer { _lock.unlock() }
        return _credentials
    }

    /*!
        @method setCredential:forProtectionSpace:
        @abstract Add a new credential to the set for the specified protection space or replace an existing one.
        @param credential The credential to set.
        @param space The protection space for which to add it.
        @discussion Multiple credentials may be set for a given protection space, but each must have
        a distinct user. If a credential with the same user is already set for the protection space,
        the new one will replace it.
    */
    open func set(_ credential: URLCredential, for space: URLProtectionSpace) {
        guard credential.persistence != .synchronizable else {
            // Do what logged-out-from-iCloud Darwin does, and refuse to save synchronizable credentials when a sync service is not available (which, in s-c-f, is always)
            return
        }

        guard credential.persistence != .none else {
            return
        }

        _lock.lock()
        let needsNotification = _setWhileLocked(credential, for: space)
        _lock.unlock()

        if needsNotification {
            _sendNotificationWhileUnlocked()
        }
    }

    /*!
        @method removeCredential:forProtectionSpace:
        @abstract Remove the credential from the set for the specified protection space.
        @param credential The credential to remove.
        @param space The protection space for which a credential should be removed
        @discussion The credential is removed from both persistent and temporary storage. A credential that
        has a persistence policy of URLCredential.Persistence.synchronizable will fail.
        See removeCredential:forProtectionSpace:options.
    */
    open func remove(_ credential: URLCredential, for space: URLProtectionSpace) {
        remove(credential, for: space, options: nil)
    }

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
    open func remove(_ credential: URLCredential, for space: URLProtectionSpace, options: [String : AnyObject]? = [:]) {
        if credential.persistence == .synchronizable {
            guard let options = options,
                  let removeSynchronizable = options[NSURLCredentialStorageRemoveSynchronizableCredentials] as? NSNumber,
                  removeSynchronizable.boolValue == true else {
                return
            }
        }

        var needsNotification = false

        _lock.lock()

        if let user = credential.user {
            if _credentials[space]?[user] == credential {
                _credentials[space]?[user] = nil
                needsNotification = true
                // If we remove the last entry, remove the protection space.
                if _credentials[space]?.count == 0 {
                    _credentials[space] = nil
                }
            }
        }
        // Also, look for a default object, if it exists, but check equality.
        if let defaultCredential = _defaultCredentials[space],
           defaultCredential == credential {
            _defaultCredentials[space] = nil
            needsNotification = true
        }

        _lock.unlock()

        if needsNotification {
            _sendNotificationWhileUnlocked()
        }
    }

    /*!
        @method defaultCredentialForProtectionSpace:
        @abstract Get the default credential for the specified protection space.
        @param space The protection space for which to get the default credential.
    */
    open func defaultCredential(for space: URLProtectionSpace) -> URLCredential? {
        _lock.lock()
        defer { _lock.unlock() }

        return _defaultCredentials[space]
    }

    /*!
        @method setDefaultCredential:forProtectionSpace:
        @abstract Set the default credential for the specified protection space.
        @param credential The credential to set as default.
        @param space The protection space for which the credential should be set as default.
        @discussion If the credential is not yet in the set for the protection space, it will be added to it.
    */
    open func setDefaultCredential(_ credential: URLCredential, for space: URLProtectionSpace) {
        guard credential.persistence != .synchronizable else {
            return
        }

        guard credential.persistence != .none else {
            return
        }

        _lock.lock()
        let needsNotification = _setWhileLocked(credential, for: space, isDefault: true)
        _lock.unlock()

        if needsNotification {
            _sendNotificationWhileUnlocked()
        }
    }

    private func _setWhileLocked(_ credential: URLCredential, for space: URLProtectionSpace, isDefault: Bool = false) -> Bool {
        var modified = false

        if let user = credential.user {
            if _credentials[space] == nil {
                _credentials[space] = [:]
            }

            modified = _credentials[space]![user] != credential
            _credentials[space]![user] = credential
        }

        if isDefault || _defaultCredentials[space] == nil {
            modified = modified || _defaultCredentials[space] != credential
            _defaultCredentials[space] = credential
        }

        return modified
    }

    private func _sendNotificationWhileUnlocked() {
        let notification = Notification(name: .NSURLCredentialStorageChanged, object: self, userInfo: nil)
        NotificationCenter.default.post(notification)
    }
}

extension URLCredentialStorage {
    public func getCredentials(for protectionSpace: URLProtectionSpace, task: URLSessionTask, completionHandler: ([String : URLCredential]?) -> Void) {
        completionHandler(credentials(for: protectionSpace))
    }

    public func set(_ credential: URLCredential, for protectionSpace: URLProtectionSpace, task: URLSessionTask) {
        set(credential, for: protectionSpace)
    }

    public func remove(_ credential: URLCredential, for protectionSpace: URLProtectionSpace, options: [String : AnyObject]? = [:], task: URLSessionTask) {
        remove(credential, for: protectionSpace, options: options)
    }

    public func getDefaultCredential(for space: URLProtectionSpace, task: URLSessionTask, completionHandler: (URLCredential?) -> Void) {
        completionHandler(defaultCredential(for: space))
    }

    public func setDefaultCredential(_ credential: URLCredential, for protectionSpace: URLProtectionSpace, task: URLSessionTask) {
        setDefaultCredential(credential, for: protectionSpace)
    }
}

extension Notification.Name {
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
