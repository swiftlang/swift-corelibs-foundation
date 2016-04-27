// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/*!
    @class NSURLAuthenticationChallenge
    @discussion This class represents an authentication challenge. It
    provides all the information about the challenge, and has a method
    to indicate when it's done.
*/
public class NSURLAuthenticationChallenge : NSObject, NSSecureCoding {
    
    static public func supportsSecureCoding() -> Bool {
        return true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    /*!
        @method initWithProtectionSpace:proposedCredential:previousFailureCount:failureResponse:error:
        @abstract Initialize an authentication challenge 
        @param space The NSURLProtectionSpace to use
        @param credential The proposed NSURLCredential for this challenge, or nil
        @param previousFailureCount A count of previous failures attempting access.
        @param response The NSURLResponse for the authentication failure, if applicable, else nil
        @param error The NSError for the authentication failure, if applicable, else nil
        @result An authentication challenge initialized with the specified parameters
    */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public init(protectionSpace space: NSURLProtectionSpace, proposedCredential credential: NSURLCredential?, previousFailureCount: Int, failureResponse response: NSURLResponse?, error: NSError?) { NSUnimplemented() }
    
    /*!
        @method initWithAuthenticationChallenge:
        @abstract Initialize an authentication challenge copying all parameters from another one.
        @param challenge
        @result A new challenge initialized with the parameters from the passed in challenge
        @discussion This initializer may be useful to subclassers that want to proxy
        one type of authentication challenge to look like another type.
    */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public init(authenticationChallenge challenge: NSURLAuthenticationChallenge) { NSUnimplemented() }
    
    /*!
        @method protectionSpace
        @abstract Get a description of the protection space that requires authentication
        @result The protection space that needs authentication
    */
    /*@NSCopying*/ public var protectionSpace: NSURLProtectionSpace { NSUnimplemented() }
    
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
    /*@NSCopying*/ public var proposedCredential: NSURLCredential? { NSUnimplemented() }
    
    /*!
        @method previousFailureCount
        @abstract Get count of previous failed authentication attempts
        @result The count of previous failures
    */
    public var previousFailureCount: Int { NSUnimplemented() }
    
    /*!
        @method failureResponse
        @abstract Get the response representing authentication failure.
        @result The failure response or nil
        @discussion If there was a previous authentication failure, and
        this protocol uses responses to indicate authentication failure,
        then this method will return the response. Otherwise it will
        return nil.
    */
    /*@NSCopying*/ public var failureResponse: NSURLResponse? { NSUnimplemented() }
    
    /*!
        @method error
        @abstract Get the error representing authentication failure.
        @discussion If there was a previous authentication failure, and
        this protocol uses errors to indicate authentication failure,
        then this method will return the error. Otherwise it will
        return nil.
    */
    /*@NSCopying*/ public var error: NSError? { NSUnimplemented() }
}

