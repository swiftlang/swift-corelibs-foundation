// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/*!
   @const NSURLProtectionSpaceHTTP
   @abstract The protocol for HTTP
*/
public let NSURLProtectionSpaceHTTP: String = "NSURLProtectionSpaceHTTP"

/*!
   @const NSURLProtectionSpaceHTTPS
   @abstract The protocol for HTTPS
*/
public let NSURLProtectionSpaceHTTPS: String = "NSURLProtectionSpaceHTTPS"

/*!
   @const NSURLProtectionSpaceFTP
   @abstract The protocol for FTP
*/
public let NSURLProtectionSpaceFTP: String = "NSURLProtectionSpaceFTP"

/*!
    @const NSURLProtectionSpaceHTTPProxy
    @abstract The proxy type for http proxies
*/
public let NSURLProtectionSpaceHTTPProxy: String = "NSURLProtectionSpaceHTTPProxy"

/*!
    @const NSURLProtectionSpaceHTTPSProxy
    @abstract The proxy type for https proxies
*/
public let NSURLProtectionSpaceHTTPSProxy: String = "NSURLProtectionSpaceHTTPSProxy"

/*!
    @const NSURLProtectionSpaceFTPProxy
    @abstract The proxy type for ftp proxies
*/
public let NSURLProtectionSpaceFTPProxy: String = "NSURLProtectionSpaceFTPProxy"

/*!
    @const NSURLProtectionSpaceSOCKSProxy
    @abstract The proxy type for SOCKS proxies
*/
public let NSURLProtectionSpaceSOCKSProxy: String = "NSURLProtectionSpaceSOCKSProxy"

/*!
    @const NSURLAuthenticationMethodDefault
    @abstract The default authentication method for a protocol
*/
public let NSURLAuthenticationMethodDefault: String = "NSURLAuthenticationMethodDefault"

/*!
    @const NSURLAuthenticationMethodHTTPBasic
    @abstract HTTP basic authentication. Equivalent to
    NSURLAuthenticationMethodDefault for http.
*/
public let NSURLAuthenticationMethodHTTPBasic: String = "NSURLAuthenticationMethodHTTPBasic"

/*!
    @const NSURLAuthenticationMethodHTTPDigest
    @abstract HTTP digest authentication.
*/
public let NSURLAuthenticationMethodHTTPDigest: String = "NSURLAuthenticationMethodHTTPDigest"

/*!
    @const NSURLAuthenticationMethodHTMLForm
    @abstract HTML form authentication. Applies to any protocol.
*/
public let NSURLAuthenticationMethodHTMLForm: String = "NSURLAuthenticationMethodHTMLForm"

/*!
   @const NSURLAuthenticationMethodNTLM
   @abstract NTLM authentication.
*/
public let NSURLAuthenticationMethodNTLM: String = "NSURLAuthenticationMethodNTLM"

/*!
   @const NSURLAuthenticationMethodNegotiate
   @abstract Negotiate authentication.
*/
public let NSURLAuthenticationMethodNegotiate: String = "NSURLAuthenticationMethodNegotiate"

/*!
    @const NSURLAuthenticationMethodClientCertificate
    @abstract SSL Client certificate.  Applies to any protocol.
 */
public let NSURLAuthenticationMethodClientCertificate: String = "NSURLAuthenticationMethodClientCertificate"

/*!
    @const NSURLAuthenticationMethodServerTrust
    @abstract SecTrustRef validation required.  Applies to any protocol.
 */
public let NSURLAuthenticationMethodServerTrust: String = "NSURLAuthenticationMethodServerTrust"


/*!
    @class NSURLProtectionSpace
    @discussion This class represents a protection space requiring authentication.
*/
public class NSURLProtectionSpace : NSObject, NSSecureCoding, NSCopying {
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject { NSUnimplemented() }
    public static func supportsSecureCoding() -> Bool { return true }
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    
    /*!
        @method initWithHost:port:protocol:realm:authenticationMethod:
        @abstract Initialize a protection space representing an origin server, or a realm on one
        @param host The hostname of the server
        @param port The port for the server
        @param protocol The sprotocol for this server - e.g. "http", "ftp", "https"
        @param realm A string indicating a protocol-specific subdivision
        of a single host. For http and https, this maps to the realm
        string in http authentication challenges. For many other protocols
        it is unused.
        @param authenticationMethod The authentication method to use to access this protection space -
        valid values include nil (default method), @"digest" and @"form".
        @result The initialized object.
    */
    public init(host: String, port: Int, `protocol`: String?, realm: String?, authenticationMethod: String?) { NSUnimplemented() }
    
    /*!
        @method initWithProxyHost:port:type:realm:authenticationMethod:
        @abstract Initialize a protection space representing a proxy server, or a realm on one
        @param host The hostname of the proxy server
        @param port The port for the proxy server
        @param type The type of proxy - e.g. "http", "ftp", "SOCKS"
        @param realm A string indicating a protocol-specific subdivision
        of a single host. For http and https, this maps to the realm
        string in http authentication challenges. For many other protocols
        it is unused.
        @param authenticationMethod The authentication method to use to access this protection space -
        valid values include nil (default method) and @"digest"
        @result The initialized object.
    */
    public init(proxyHost host: String, port: Int, type: String?, realm: String?, authenticationMethod: String?) { NSUnimplemented() }
    
    /*!
        @method realm
        @abstract Get the authentication realm for which the protection space that
        needs authentication
        @discussion This is generally only available for http
        authentication, and may be nil otherwise.
        @result The realm string
    */
    public var realm: String? { NSUnimplemented() }
    
    /*!
        @method receivesCredentialSecurely
        @abstract Determine if the password for this protection space can be sent securely
        @result YES if a secure authentication method or protocol will be used, NO otherwise
    */
    public var receivesCredentialSecurely: Bool { NSUnimplemented() }
    
    /*!
        @method isProxy
        @abstract Determine if this authenticating protection space is a proxy server
        @result YES if a proxy, NO otherwise
    */
    
    /*!
        @method host
        @abstract Get the proxy host if this is a proxy authentication, or the host from the URL.
        @result The host for this protection space.
    */
    public var host: String { NSUnimplemented() }
    
    /*!
        @method port
        @abstract Get the proxy port if this is a proxy authentication, or the port from the URL.
        @result The port for this protection space, or 0 if not set.
    */
    public var port: Int { NSUnimplemented() }
    
    /*!
        @method proxyType
        @abstract Get the type of this protection space, if a proxy
        @result The type string, or nil if not a proxy.
     */
    public var proxyType: String? { NSUnimplemented() }
    
    /*!
        @method protocol
        @abstract Get the protocol of this protection space, if not a proxy
        @result The type string, or nil if a proxy.
    */
    public var `protocol`: String? { NSUnimplemented() }
    
    /*!
        @method authenticationMethod
        @abstract Get the authentication method to be used for this protection space
        @result The authentication method
    */
    public var authenticationMethod: String { NSUnimplemented() }
    public override func isProxy() -> Bool { NSUnimplemented() }
}

extension NSURLProtectionSpace {
    
    /*!
        @method distinguishedNames
        @abstract Returns an array of acceptable certificate issuing authorities for client certification authentication. Issuers are identified by their distinguished name and returned as a DER encoded data.
        @result An array of NSData objects.  (Nil if the authenticationMethod is not NSURLAuthenticationMethodClientCertificate)
     */
    public var distinguishedNames: [NSData]? { NSUnimplemented() }
}

// TODO: Currently no implementation of Security.framework
/*
extension NSURLProtectionSpace {
    
    /*!
        @method serverTrust
        @abstract Returns a SecTrustRef which represents the state of the servers SSL transaction state
        @result A SecTrustRef from Security.framework.  (Nil if the authenticationMethod is not NSURLAuthenticationMethodServerTrust)
     */
    public var serverTrust: SecTrust? { NSUnimplemented() }
}
*/
