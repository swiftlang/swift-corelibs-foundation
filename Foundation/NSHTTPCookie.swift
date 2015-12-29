// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/*!
    @const NSHTTPCookieName
    @discussion Key for cookie name
*/
public let NSHTTPCookieName: String = "Name"

/*!
    @const NSHTTPCookieValue
    @discussion Key for cookie value
*/
public let NSHTTPCookieValue: String = "Value"

/*!
    @const NSHTTPCookieOriginURL
    @discussion Key for cookie origin URL
*/
public let NSHTTPCookieOriginURL: String = "OriginURL"

/*!
    @const NSHTTPCookieVersion
    @discussion Key for cookie version
*/
public let NSHTTPCookieVersion: String = "Version"

/*!
    @const NSHTTPCookieDomain
    @discussion Key for cookie domain
*/
public let NSHTTPCookieDomain: String = "Domain"

/*!
    @const NSHTTPCookiePath
    @discussion Key for cookie path
*/
public let NSHTTPCookiePath: String = "Path"

/*!
    @const NSHTTPCookieSecure
    @discussion Key for cookie secure flag
*/
public let NSHTTPCookieSecure: String = "Secure"

/*!
    @const NSHTTPCookieExpires
    @discussion Key for cookie expiration date
*/
public let NSHTTPCookieExpires: String = "Expires"

/*!
    @const NSHTTPCookieComment
    @discussion Key for cookie comment text
*/
public let NSHTTPCookieComment: String = "Comment"

/*!
    @const NSHTTPCookieCommentURL
    @discussion Key for cookie comment URL
*/
public let NSHTTPCookieCommentURL: String = "CommentURL"

/*!
    @const NSHTTPCookieDiscard
    @discussion Key for cookie discard (session-only) flag
*/
public let NSHTTPCookieDiscard: String = "Discard"

/*!
    @const NSHTTPCookieMaximumAge
    @discussion Key for cookie maximum age (an alternate way of specifying the expiration)
*/
public let NSHTTPCookieMaximumAge: String = "Max-Age"

/*!
    @const NSHTTPCookiePort
    @discussion Key for cookie ports
*/
public let NSHTTPCookiePort: String = "Port"


/*!
    @class NSHTTPCookie
    @abstract NSHTTPCookie represents an http cookie.
    @discussion A NSHTTPCookie instance represents a single http cookie. It is
    an immutable object initialized from a dictionary that contains
    the various cookie attributes. It has accessors to get the various
    attributes of a cookie.
*/
public class NSHTTPCookie : NSObject {
    let _comment: String?
    let _commentURL: NSURL?
    let _domain: String
    let _expiresDate: NSDate?
    let _HTTPOnly: Bool
    let _secure: Bool
    let _sessionOnly: Bool
    let _name: String
    let _path: String
    let _portList: [NSNumber]?
    let _value: String
    let _version: Int
    var _properties: [String : Any]
    
    /*!
        @method initWithProperties:
        @abstract Initialize a NSHTTPCookie object with a dictionary of
        parameters
        @param properties The dictionary of properties to be used to
        initialize this cookie.
        @discussion Supported dictionary keys and value types for the
        given dictionary are as follows.
    
        All properties can handle an NSString value, but some can also
        handle other types.
    
        <table border=1 cellspacing=2 cellpadding=4>
        <tr>
            <th>Property key constant</th>
            <th>Type of value</th>
            <th>Required</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>NSHTTPCookieComment</td>
            <td>NSString</td>
            <td>NO</td>
            <td>Comment for the cookie. Only valid for version 1 cookies and
            later. Default is nil.</td>
        </tr>
        <tr>
            <td>NSHTTPCookieCommentURL</td>
            <td>NSURL or NSString</td>
            <td>NO</td>
            <td>Comment URL for the cookie. Only valid for version 1 cookies
            and later. Default is nil.</td>
        </tr>
        <tr>
            <td>NSHTTPCookieDomain</td>
            <td>NSString</td>
            <td>Special, a value for either NSHTTPCookieOriginURL or
            NSHTTPCookieDomain must be specified.</td>
            <td>Domain for the cookie. Inferred from the value for
            NSHTTPCookieOriginURL if not provided.</td>
        </tr>
        <tr>
            <td>NSHTTPCookieDiscard</td>
            <td>NSString</td>
            <td>NO</td>
            <td>A string stating whether the cookie should be discarded at
            the end of the session. String value must be either "TRUE" or
            "FALSE". Default is "FALSE", unless this is cookie is version
            1 or greater and a value for NSHTTPCookieMaximumAge is not
            specified, in which case it is assumed "TRUE".</td>
        </tr>
        <tr>
            <td>NSHTTPCookieExpires</td>
            <td>NSDate or NSString</td>
            <td>NO</td>
            <td>Expiration date for the cookie. Used only for version 0
            cookies. Ignored for version 1 or greater.</td>
        </tr>
        <tr>
            <td>NSHTTPCookieMaximumAge</td>
            <td>NSString</td>
            <td>NO</td>
            <td>A string containing an integer value stating how long in
            seconds the cookie should be kept, at most. Only valid for
            version 1 cookies and later. Default is "0".</td>
        </tr>
        <tr>
            <td>NSHTTPCookieName</td>
            <td>NSString</td>
            <td>YES</td>
            <td>Name of the cookie</td>
        </tr>
        <tr>
            <td>NSHTTPCookieOriginURL</td>
            <td>NSURL or NSString</td>
            <td>Special, a value for either NSHTTPCookieOriginURL or
            NSHTTPCookieDomain must be specified.</td>
            <td>URL that set this cookie. Used as default for other fields
            as noted.</td>
        </tr>
        <tr>
            <td>NSHTTPCookiePath</td>
            <td>NSString</td>
            <td>NO</td>
            <td>Path for the cookie. Inferred from the value for
            NSHTTPCookieOriginURL if not provided. Default is "/".</td>
        </tr>
        <tr>
            <td>NSHTTPCookiePort</td>
            <td>NSString</td>
            <td>NO</td>
            <td>comma-separated integer values specifying the ports for the
            cookie. Only valid for version 1 cookies and later. Default is
            empty string ("").</td>
        </tr>
        <tr>
            <td>NSHTTPCookieSecure</td>
            <td>NSString</td>
            <td>NO</td>
            <td>A string stating whether the cookie should be transmitted
            only over secure channels. String value must be either "TRUE"
            or "FALSE". Default is "FALSE".</td>
        </tr>
        <tr>
            <td>NSHTTPCookieValue</td>
            <td>NSString</td>
            <td>YES</td>
            <td>Value of the cookie</td>
        </tr>
        <tr>
            <td>NSHTTPCookieVersion</td>
            <td>NSString</td>
            <td>NO</td>
            <td>Specifies the version of the cookie. Must be either "0" or
            "1". Default is "0".</td>
        </tr>
        </table>
        <p>
        All other keys are ignored.
        @result An initialized NSHTTPCookie, or nil if the set of
        dictionary keys is invalid, for example because a required key is
        missing, or a recognized key maps to an illegal value.
    */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public init?(properties: [String : Any]) {
        guard let
            path = properties[NSHTTPCookiePath] as? String,
            name = properties[NSHTTPCookieName] as? String,
            value = properties[NSHTTPCookieValue] as? String
        else {
            return nil
        }
        
        let canonicalDomain: String
        if let domain = properties[NSHTTPCookieDomain] as? String {
            canonicalDomain = domain
        } else if let
            originURL = properties[NSHTTPCookieOriginURL] as? NSURL,
            host = originURL.host
        {
            canonicalDomain = host
        } else {
            return nil
        }
        
        _path = path
        _name = name
        _value = value
        _domain = canonicalDomain
        
        if let
            secureString = properties[NSHTTPCookieSecure] as? String
            where secureString.characters.count > 0
        {
            _secure = true
        } else {
            _secure = false
        }

        let version: Int
        if let
            versionString = properties[NSHTTPCookieVersion] as? String
            where versionString == "1"
        {
            version = 1
        } else {
            version = 0
        }
        _version = version
        
        if let portString = properties[NSHTTPCookiePort] as? String
        where _version == 1 {
            _portList = portString.characters
                .split(",")
                .flatMap { Int(String($0)) }
                .map { NSNumber(integer: $0) }
        } else {
            _portList = nil
        }

        // TODO: factor into a utility function
        if version == 0 {
            let expiresProperty = properties[NSHTTPCookieExpires]
            if let date = expiresProperty as? NSDate {
                _expiresDate = date
            } else if let dateString = expiresProperty as? String {
                let formatter = NSDateFormatter()
                formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss O"   // per RFC 6265 '<rfc1123-date, defined in [RFC2616], Section 3.3.1>'
                let timeZone = NSTimeZone(abbreviation: "GMT")
                formatter.timeZone = timeZone
                _expiresDate = formatter.dateFromString(dateString)
            } else {
                _expiresDate = nil
            }
        } else if let
            maximumAge = properties[NSHTTPCookieMaximumAge] as? String,
            secondsFromNow = Int(maximumAge)
            where _version == 1 {
            _expiresDate = NSDate(timeIntervalSinceNow: Double(secondsFromNow))
        } else {
            _expiresDate = nil
        }
        
        
        if let discardString = properties[NSHTTPCookieDiscard] as? String {
            _sessionOnly = discardString == "TRUE"
        } else {
            _sessionOnly = properties[NSHTTPCookieMaximumAge] == nil && version >= 1
        }
        if version == 0 {
            _comment = nil
            _commentURL = nil
        } else {
            _comment = properties[NSHTTPCookieComment] as? String
            if let commentURL = properties[NSHTTPCookieCommentURL] as? NSURL {
                _commentURL = commentURL
            } else if let commentURL = properties[NSHTTPCookieCommentURL] as? String {
                _commentURL = NSURL(string: commentURL)
            } else {
                _commentURL = nil
            }
        }
        _HTTPOnly = false
        _properties = [NSHTTPCookieComment : properties[NSHTTPCookieComment],
                       NSHTTPCookieCommentURL : properties[NSHTTPCookieCommentURL],
                       "Created" : NSDate().timeIntervalSinceReferenceDate,         // Cocoa Compatibility
                       NSHTTPCookieDiscard : _sessionOnly,
                       NSHTTPCookieDomain : _domain,
                       NSHTTPCookieExpires : _expiresDate,
                       NSHTTPCookieMaximumAge : properties[NSHTTPCookieMaximumAge],
                       NSHTTPCookieName : _name,
                       NSHTTPCookieOriginURL : properties[NSHTTPCookieOriginURL],
                       NSHTTPCookiePath : _path,
                       NSHTTPCookiePort : _portList,
                       NSHTTPCookieSecure : _secure,
                       NSHTTPCookieValue : _value,
                       NSHTTPCookieVersion : _version
        ]
    }
    
    /*!
        @method cookieWithProperties:
        @abstract Allocates and initializes an NSHTTPCookie with the given
        dictionary.
        @discussion See the NSHTTPCookie <tt>-initWithProperties:</tt>
        method for more information on the constraints imposed on the
        dictionary, and for descriptions of the supported keys and values.
        @param properties The dictionary to use to initialize this cookie.
        @result A newly-created and autoreleased NSHTTPCookie instance, or
        nil if the set of dictionary keys is invalid, for example because
        a required key is missing, or a recognized key maps to an illegal
        value.
    */
    
    /*!
        @method requestHeaderFieldsWithCookies:
        @abstract Return a dictionary of header fields that can be used to add the
        specified cookies to the request.
        @param cookies The cookies to turn into request headers.
        @result An NSDictionary where the keys are header field names, and the values
        are the corresponding header field values.
    */
    public class func requestHeaderFieldsWithCookies(cookies: [NSHTTPCookie]) -> [String : String] {
        var cookieString = cookies.reduce("") { (sum, next) -> String in
            return sum + "\(next._name)=\(next._value); "
        }
        //Remove the final trailing semicolon and whitespace
        if ( cookieString.length > 0 ) {
            cookieString.removeAtIndex(cookieString.endIndex.predecessor())
            cookieString.removeAtIndex(cookieString.endIndex.predecessor())
        }
        return ["Cookie": cookieString]
    }
    
    /*!
        @method cookiesWithResponseHeaderFields:forURL:
        @abstract Return an array of cookies parsed from the specified response header fields and URL.
        @param headerFields The response header fields to check for cookies.
        @param URL The URL that the cookies came from - relevant to how the cookies are interpeted.
        @result An NSArray of NSHTTPCookie objects
        @discussion This method will ignore irrelevant header fields so
        you can pass a dictionary containing data other than cookie data.
    */
    public class func cookiesWithResponseHeaderFields(headerFields: [String : String], forURL URL: NSURL) -> [NSHTTPCookie] { NSUnimplemented() }
    
    /*!
        @method properties
        @abstract Returns a dictionary representation of the receiver.
        @discussion This method returns a dictionary representation of the
        NSHTTPCookie which can be saved and passed to
        <tt>-initWithProperties:</tt> or <tt>+cookieWithProperties:</tt>
        later to reconstitute an equivalent cookie.
        <p>See the NSHTTPCookie <tt>-initWithProperties:</tt> method for
        more information on the constraints imposed on the dictionary, and
        for descriptions of the supported keys and values.
        @result The dictionary representation of the receiver.
    */
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public var properties: [String : Any]? {
        return _properties
    }
    
    /*!
        @method version
        @abstract Returns the version of the receiver.
        @discussion Version 0 maps to "old-style" Netscape cookies.
        Version 1 maps to RFC2965 cookies. There may be future versions.
        @result the version of the receiver.
    */
    public var version: Int {
        return _version
    }
    
    /*!
        @method name
        @abstract Returns the name of the receiver.
        @result the name of the receiver.
    */
    public var name: String {
        return _name
    }
    
    /*!
        @method value
        @abstract Returns the value of the receiver.
        @result the value of the receiver.
    */
    public var value: String {
        return _value
    }
    
    /*!
        @method expiresDate
        @abstract Returns the expires date of the receiver.
        @result the expires date of the receiver.
        @discussion The expires date is the date when the cookie should be
        deleted. The result will be nil if there is no specific expires
        date. This will be the case only for "session-only" cookies.
        @result The expires date of the receiver.
    */
    /*@NSCopying*/ public var expiresDate: NSDate? {
        return _expiresDate
    }
    
    /*!
        @method isSessionOnly
        @abstract Returns whether the receiver is session-only.
        @result YES if this receiver should be discarded at the end of the
        session (regardless of expiration date), NO if receiver need not
        be discarded at the end of the session.
    */
    public var sessionOnly: Bool {
        return _sessionOnly
    }
    
    /*!
        @method domain
        @abstract Returns the domain of the receiver.
        @discussion This value specifies URL domain to which the cookie
        should be sent. A domain with a leading dot means the cookie
        should be sent to subdomains as well, assuming certain other
        restrictions are valid. See RFC 2965 for more detail.
        @result The domain of the receiver.
    */
    public var domain: String {
        return _domain
    }
    
    /*!
        @method path
        @abstract Returns the path of the receiver.
        @discussion This value specifies the URL path under the cookie's
        domain for which this cookie should be sent. The cookie will also
        be sent for children of that path, so "/" is the most general.
        @result The path of the receiver.
    */
    public var path: String {
        return _path
    }
    
    /*!
        @method isSecure
        @abstract Returns whether the receiver should be sent only over
        secure channels
        @discussion Cookies may be marked secure by a server (or by a javascript).
        Cookies marked as such must only be sent via an encrypted connection to 
        trusted servers (i.e. via SSL or TLS), and should not be delievered to any
        javascript applications to prevent cross-site scripting vulnerabilities.
        @result YES if this cookie should be sent only over secure channels,
        NO otherwise.
    */
    public var secure: Bool {
        return _secure
    }
    
    /*!
        @method isHTTPOnly
        @abstract Returns whether the receiver should only be sent to HTTP servers
        per RFC 2965
        @discussion Cookies may be marked as HTTPOnly by a server (or by a javascript).
        Cookies marked as such must only be sent via HTTP Headers in HTTP Requests
        for URL's that match both the path and domain of the respective Cookies.
        Specifically these cookies should not be delivered to any javascript 
        applications to prevent cross-site scripting vulnerabilities.
        @result YES if this cookie should only be sent via HTTP headers,
        NO otherwise.
    */
    public var HTTPOnly: Bool {
        return _HTTPOnly
    }
    
    /*!
        @method comment
        @abstract Returns the comment of the receiver.
        @discussion This value specifies a string which is suitable for
        presentation to the user explaining the contents and purpose of this
        cookie. It may be nil.
        @result The comment of the receiver, or nil if the receiver has no
        comment.
    */
    public var comment: String? {
        return _comment
    }
    
    /*!
        @method commentURL
        @abstract Returns the comment URL of the receiver.
        @discussion This value specifies a URL which is suitable for
        presentation to the user as a link for further information about
        this cookie. It may be nil.
        @result The comment URL of the receiver, or nil if the receiver
        has no comment URL.
    */
    /*@NSCopying*/ public var commentURL: NSURL? {
        return _commentURL
    }
    
    /*!
        @method portList
        @abstract Returns the list ports to which the receiver should be
        sent.
        @discussion This value specifies an NSArray of NSNumbers
        (containing integers) which specify the only ports to which this
        cookie should be sent.
        @result The list ports to which the receiver should be sent. The
        array may be nil, in which case this cookie can be sent to any
        port.
    */
    public var portList: [NSNumber]? {
        return _portList
    }
}

