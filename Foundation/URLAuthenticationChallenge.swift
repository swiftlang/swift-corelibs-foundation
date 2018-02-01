// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

public protocol URLAuthenticationChallengeSender : NSObjectProtocol {
    
    
    /*!
     @method useCredential:forAuthenticationChallenge:
     */
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge)
    
    
    /*!
     @method continueWithoutCredentialForAuthenticationChallenge:
     */
    func continueWithoutCredential(for challenge: URLAuthenticationChallenge)
    
    
    /*!
     @method cancelAuthenticationChallenge:
     */
    func cancel(_ challenge: URLAuthenticationChallenge)
    
    
    /*!
     @method performDefaultHandlingForAuthenticationChallenge:
     */
    func performDefaultHandling(for challenge: URLAuthenticationChallenge)
    
    
    /*!
     @method rejectProtectionSpaceAndContinueWithChallenge:
     */
    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge)
}

/*!
    @class URLAuthenticationChallenge
    @discussion This class represents an authentication challenge. It
    provides all the information about the challenge, and has a method
    to indicate when it's done.
*/
open class URLAuthenticationChallenge : NSObject, NSSecureCoding {

    private let _protectionSpace: URLProtectionSpace
    private let _proposedCredential: URLCredential?
    private let _previousFailureCount: Int
    private let _failureResponse: URLResponse?
    private let _error: Error?
    private let _sender: URLAuthenticationChallengeSender
    
    static public var supportsSecureCoding: Bool {
        return true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    
    /*!
     @method initWithProtectionSpace:proposedCredential:previousFailureCount:failureResponse:error:
     @abstract Initialize an authentication challenge
     @param space The URLProtectionSpace to use
     @param credential The proposed URLCredential for this challenge, or nil
     @param previousFailureCount A count of previous failures attempting access.
     @param response The URLResponse for the authentication failure, if applicable, else nil
     @param error The NSError for the authentication failure, if applicable, else nil
     @result An authentication challenge initialized with the specified parameters
     */
    public init(protectionSpace space: URLProtectionSpace, proposedCredential credential: URLCredential?, previousFailureCount: Int, failureResponse response: URLResponse?, error: Error?, sender: URLAuthenticationChallengeSender) {
        self._protectionSpace = space
        self._proposedCredential = credential
        self._previousFailureCount = previousFailureCount
        self._failureResponse = response
        self._error = error
        self._sender = sender
    }
    
    
    /*!
     @method initWithAuthenticationChallenge:
     @abstract Initialize an authentication challenge copying all parameters from another one.
     @param challenge
     @result A new challenge initialized with the parameters from the passed in challenge
     @discussion This initializer may be useful to subclassers that want to proxy
     one type of authentication challenge to look like another type.
     */
    public init(authenticationChallenge challenge: URLAuthenticationChallenge, sender: URLAuthenticationChallengeSender) {
        self._protectionSpace = challenge.protectionSpace
        self._proposedCredential = challenge.proposedCredential
        self._previousFailureCount = challenge.previousFailureCount
        self._failureResponse = challenge.failureResponse
        self._error = challenge.error
        self._sender = sender
    }
    
    
    /*!
     @method protectionSpace
     @abstract Get a description of the protection space that requires authentication
     @result The protection space that needs authentication
     */
    /*@NSCopying*/ open var protectionSpace: URLProtectionSpace {
        get {
            return _protectionSpace
        }
    }
    
    
    /*!
     @method proposedCredential
     @abstract Get the proposed credential for this challenge
     @result The proposed credential
     @discussion proposedCredential may be nil, if there is no default
     credential to use for this challenge (either stored or in the
     URL). If the credential is not nil and returns YES for
     hasPassword, this means the NSURLConnection thinks the credential
     is ready to use as-is. If it returns NO for hasPassword, then the
     credential is not ready to use as-is, but provides a default
     username the client could use when prompting.
     */
    /*@NSCopying*/ open var proposedCredential: URLCredential? {
        get {
            return _proposedCredential
        }
    }
    
    
    /*!
     @method previousFailureCount
     @abstract Get count of previous failed authentication attempts
     @result The count of previous failures
     */
    open var previousFailureCount: Int {
        get {
            return _previousFailureCount
        }
    }
    
    
    /*!
     @method failureResponse
     @abstract Get the response representing authentication failure.
     @result The failure response or nil
     @discussion If there was a previous authentication failure, and
     this protocol uses responses to indicate authentication failure,
     then this method will return the response. Otherwise it will
     return nil.
     */
    /*@NSCopying*/ open var failureResponse: URLResponse? {
        get {
            return _failureResponse
        }
    }
    
    
    /*!
     @method error
     @abstract Get the error representing authentication failure.
     @discussion If there was a previous authentication failure, and
     this protocol uses errors to indicate authentication failure,
     then this method will return the error. Otherwise it will
     return nil.
     */
    /*@NSCopying*/ open var error: Error? {
        get {
            return _error
        }
    }
    
    
    /*!
     @method sender
     @abstract Get the sender of this challenge
     @result The sender of the challenge
     @discussion The sender is the object you should reply to when done processing the challenge.
     */
    open var sender: URLAuthenticationChallengeSender? {
        get {
            return _sender
        }
    }
}
