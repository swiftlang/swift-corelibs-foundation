// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/*!
    @enum NSURLCredentialPersistence
    @abstract Constants defining how long a credential will be kept around
    @constant NSURLCredentialPersistenceNone This credential won't be saved.
    @constant NSURLCredentialPersistenceForSession This credential will only be stored for this session.
    @constant NSURLCredentialPersistencePermanent This credential will be stored permanently. Note: Whereas in Mac OS X any application can access any credential provided the user gives permission, in iPhone OS an application can access only its own credentials.
    @constant NSURLCredentialPersistenceSynchronizable This credential will be stored permanently. Additionally, this credential will be distributed to other devices based on the owning AppleID.
        Note: Whereas in Mac OS X any application can access any credential provided the user gives permission, on iOS an application can 
        access only its own credentials.
*/
extension URLCredential {
    public enum Persistence : UInt {
        case none
        case forSession
        case permanent
        case synchronizable
    }
}


/*!
    @class NSURLCredential
    @discussion This class is an immutable object representing an authentication credential.  The actual type of the credential is determined by the constructor called in the categories declared below.
*/
open class URLCredential : NSObject, NSSecureCoding, NSCopying {
    private var _user : String
    private var _password : String
    private var _persistence : Persistence
    
    /*!
        @method initWithUser:password:persistence:
        @abstract Initialize a NSURLCredential with a user and password
        @param user the username
        @param password the password
        @param persistence enum that says to store per session, permanently or not at all
        @result The initialized NSURLCredential
     */
    public init(user: String, password: String, persistence: Persistence) {
        guard persistence != .permanent && persistence != .synchronizable else {
            NSUnimplemented()
        }
        _user = user
        _password = password
        _persistence = persistence
        super.init()
    }
    
    /*!
        @method credentialWithUser:password:persistence:
        @abstract Create a new NSURLCredential with a user and password
        @param user the username
        @param password the password
        @param persistence enum that says to store per session, permanently or not at all
        @result The new autoreleased NSURLCredential
     */
    
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
        @method persistence
        @abstract Determine whether this credential is or should be stored persistently
        @result A value indicating whether this credential is stored permanently, per session or not at all.
     */
    open var persistence: Persistence { return _persistence }
    
    /*!
        @method user
        @abstract Get the username
        @result The user string
     */
    open var user: String? { return _user }
    
    /*!
        @method password
        @abstract Get the password
        @result The password string
        @discussion This method might actually attempt to retrieve the
        password from an external store, possible resulting in prompting,
        so do not call it unless needed.
     */
    open var password: String? { return _password }

    /*!
        @method hasPassword
        @abstract Find out if this credential has a password, without trying to get it
        @result YES if this credential has a password, otherwise NO
        @discussion If this credential's password is actually kept in an
        external store, the password method may return nil even if this
        method returns YES, since getting the password may fail, or the
        user may refuse access.
     */
    open var hasPassword: Bool {
        // Currently no support for SecTrust/SecIdentity, always return true
        return true
    }
}

// TODO: We have no implementation for Security.framework primitive types SecIdentity and SecTrust yet
/*
extension NSURLCredential {
    
    /*!
        @method initWithIdentity:certificates:persistence:
        @abstract Initialize an NSURLCredential with an identity and array of at least 1 client certificates (SecCertificateRef)
        @param identity a SecIdentityRef object
        @param certArray an array containing at least one SecCertificateRef objects
        @param persistence enum that says to store per session, permanently or not at all
        @result the Initialized NSURLCredential
     */
    public convenience init(identity: SecIdentity, certificates certArray: [AnyObject]?, persistence: NSURLCredentialPersistence)
    
    /*!
        @method credentialWithIdentity:certificates:persistence:
        @abstract Create a new NSURLCredential with an identity and certificate array
        @param identity a SecIdentityRef object
        @param certArray an array containing at least one SecCertificateRef objects
        @param persistence enum that says to store per session, permanently or not at all
        @result The new autoreleased NSURLCredential
     */
    
    /*!
        @method identity
        @abstract Returns the SecIdentityRef of this credential, if it was created with a certificate and identity
        @result A SecIdentityRef or NULL if this is a username/password credential
     */
    public var identity: SecIdentity? { NSUnimplemented() }
    
    /*!
        @method certificates
        @abstract Returns an NSArray of SecCertificateRef objects representing the client certificate for this credential, if this credential was created with an identity and certificate.
        @result an NSArray of SecCertificateRef or NULL if this is a username/password credential
     */
    public var certificates: [AnyObject] { NSUnimplemented() }
}

extension NSURLCredential {
    
    /*!
        @method initWithTrust:
        @abstract Initialize a new NSURLCredential which specifies that the specified trust has been accepted.
        @result the Initialized NSURLCredential
     */
    public convenience init(trust: SecTrust) { NSUnimplemented() }
    
    /*!
        @method credentialForTrust:
        @abstract Create a new NSURLCredential which specifies that a handshake has been trusted.
        @result The new autoreleased NSURLCredential
     */
    public convenience init(forTrust trust: SecTrust) { NSUnimplemented() }
}
*/
