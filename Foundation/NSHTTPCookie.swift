// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/// Key for cookie name
public let NSHTTPCookieName: String = "Name"

/// Key for cookie value
public let NSHTTPCookieValue: String = "Value"

/// Key for cookie origin URL
public let NSHTTPCookieOriginURL: String = "OriginURL"

/// Key for cookie version
public let NSHTTPCookieVersion: String = "Version"

/// Key for cookie domain
public let NSHTTPCookieDomain: String = "Domain"

/// Key for cookie path
public let NSHTTPCookiePath: String = "Path"

/// Key for cookie secure flag
public let NSHTTPCookieSecure: String = "Secure"

/// Key for cookie expiration date
public let NSHTTPCookieExpires: String = "Expires"

/// Key for cookie comment text
public let NSHTTPCookieComment: String = "Comment"

/// Key for cookie comment URL
public let NSHTTPCookieCommentURL: String = "CommentURL"

/// Key for cookie discard (session-only) flag
public let NSHTTPCookieDiscard: String = "Discard"

/// Key for cookie maximum age (an alternate way of specifying the expiration)
public let NSHTTPCookieMaximumAge: String = "Max-Age"

/// Key for cookie ports
public let NSHTTPCookiePort: String = "Port"


/// `NSHTTPCookie` represents an http cookie.
///
/// An `NSHTTPCookie` instance represents a single http cookie. It is
/// an immutable object initialized from a dictionary that contains
/// the various cookie attributes. It has accessors to get the various
/// attributes of a cookie.
public class HTTPCookie : NSObject {

    let _comment: String?
    let _commentURL: URL?
    let _domain: String
    let _expiresDate: Date?
    let _HTTPOnly: Bool
    let _secure: Bool
    let _sessionOnly: Bool
    let _name: String
    let _path: String
    let _portList: [NSNumber]?
    let _value: String
    let _version: Int
    var _properties: [String : Any]

    static let _attributes: [String] = [NSHTTPCookieName, NSHTTPCookieValue, NSHTTPCookieOriginURL, NSHTTPCookieVersion,
                                        NSHTTPCookieDomain, NSHTTPCookiePath, NSHTTPCookieSecure, NSHTTPCookieExpires, 
                                        NSHTTPCookieComment, NSHTTPCookieCommentURL, NSHTTPCookieDiscard, NSHTTPCookieMaximumAge,
                                        NSHTTPCookiePort] 

    /// Initialize a NSHTTPCookie object with a dictionary of parameters
    ///
    /// - Parameter properties: The dictionary of properties to be used to
    /// initialize this cookie.
    ///
    /// Supported dictionary keys and value types for the
    /// given dictionary are as follows.
    ///
    /// All properties can handle an NSString value, but some can also
    /// handle other types.
    ///
    /// <table border=1 cellspacing=2 cellpadding=4>
    /// <tr>
    ///     <th>Property key constant</th>
    ///     <th>Type of value</th>
    ///     <th>Required</th>
    ///     <th>Description</th>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieComment</td>
    ///     <td>NSString</td>
    ///     <td>NO</td>
    ///     <td>Comment for the cookie. Only valid for version 1 cookies and
    ///     later. Default is nil.</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieCommentURL</td>
    ///     <td>NSURL or NSString</td>
    ///     <td>NO</td>
    ///     <td>Comment URL for the cookie. Only valid for version 1 cookies
    ///     and later. Default is nil.</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieDomain</td>
    ///     <td>NSString</td>
    ///     <td>Special, a value for either NSHTTPCookieOriginURL or
    ///     NSHTTPCookieDomain must be specified.</td>
    ///     <td>Domain for the cookie. Inferred from the value for
    ///     NSHTTPCookieOriginURL if not provided.</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieDiscard</td>
    ///     <td>NSString</td>
    ///     <td>NO</td>
    ///     <td>A string stating whether the cookie should be discarded at
    ///     the end of the session. String value must be either "TRUE" or
    ///     "FALSE". Default is "FALSE", unless this is cookie is version
    ///     1 or greater and a value for NSHTTPCookieMaximumAge is not
    ///     specified, in which case it is assumed "TRUE".</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieExpires</td>
    ///     <td>NSDate or NSString</td>
    ///     <td>NO</td>
    ///     <td>Expiration date for the cookie. Used only for version 0
    ///     cookies. Ignored for version 1 or greater.</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieMaximumAge</td>
    ///     <td>NSString</td>
    ///     <td>NO</td>
    ///     <td>A string containing an integer value stating how long in
    ///     seconds the cookie should be kept, at most. Only valid for
    ///     version 1 cookies and later. Default is "0".</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieName</td>
    ///     <td>NSString</td>
    ///     <td>YES</td>
    ///     <td>Name of the cookie</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieOriginURL</td>
    ///     <td>NSURL or NSString</td>
    ///     <td>Special, a value for either NSHTTPCookieOriginURL or
    ///     NSHTTPCookieDomain must be specified.</td>
    ///     <td>URL that set this cookie. Used as default for other fields
    ///     as noted.</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookiePath</td>
    ///     <td>NSString</td>
    ///     <td>NO</td>
    ///     <td>Path for the cookie. Inferred from the value for
    ///     NSHTTPCookieOriginURL if not provided. Default is "/".</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookiePort</td>
    ///     <td>NSString</td>
    ///     <td>NO</td>
    ///     <td>comma-separated integer values specifying the ports for the
    ///     cookie. Only valid for version 1 cookies and later. Default is
    ///     empty string ("").</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieSecure</td>
    ///     <td>NSString</td>
    ///     <td>NO</td>
    ///     <td>A string stating whether the cookie should be transmitted
    ///     only over secure channels. String value must be either "TRUE"
    ///     or "FALSE". Default is "FALSE".</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieValue</td>
    ///     <td>NSString</td>
    ///     <td>YES</td>
    ///     <td>Value of the cookie</td>
    /// </tr>
    /// <tr>
    ///     <td>NSHTTPCookieVersion</td>
    ///     <td>NSString</td>
    ///     <td>NO</td>
    ///     <td>Specifies the version of the cookie. Must be either "0" or
    ///     "1". Default is "0".</td>
    /// </tr>
    /// </table>
    ///
    /// All other keys are ignored.
    ///
    /// - Returns: An initialized `NSHTTPCookie`, or nil if the set of
    /// dictionary keys is invalid, for example because a required key is
    /// missing, or a recognized key maps to an illegal value.
    ///
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public init?(properties: [String : Any]) {
        guard
            let path = properties[NSHTTPCookiePath] as? String,
            let name = properties[NSHTTPCookieName] as? String,
            let value = properties[NSHTTPCookieValue] as? String
        else {
            return nil
        }

        let canonicalDomain: String
        if let domain = properties[NSHTTPCookieDomain] as? String {
            canonicalDomain = domain
        } else if
            let originURL = properties[NSHTTPCookieOriginURL] as? URL,
            let host = originURL.host
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
                .split(separator: ",")
                .flatMap { Int(String($0)) }
                .map { NSNumber(value: $0) }
        } else {
            _portList = nil
        }

        // TODO: factor into a utility function
        if version == 0 {
            let expiresProperty = properties[NSHTTPCookieExpires]
            if let date = expiresProperty as? Date {
                _expiresDate = date
            } else if let dateString = expiresProperty as? String {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss O"   // per RFC 6265 '<rfc1123-date, defined in [RFC2616], Section 3.3.1>'
                let timeZone = TimeZone(abbreviation: "GMT")
                formatter.timeZone = timeZone
                _expiresDate = formatter.date(from: dateString)
            } else {
                _expiresDate = nil
            }
        } else if
            let maximumAge = properties[NSHTTPCookieMaximumAge] as? String,
            let secondsFromNow = Int(maximumAge)
            where _version == 1 {
            _expiresDate = Date(timeIntervalSinceNow: Double(secondsFromNow))
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
            if let commentURL = properties[NSHTTPCookieCommentURL] as? URL {
                _commentURL = commentURL
            } else if let commentURL = properties[NSHTTPCookieCommentURL] as? String {
                _commentURL = URL(string: commentURL)
            } else {
                _commentURL = nil
            }
        }
        _HTTPOnly = false
        _properties = [NSHTTPCookieComment : properties[NSHTTPCookieComment],
                       NSHTTPCookieCommentURL : properties[NSHTTPCookieCommentURL],
                       "Created" : Date().timeIntervalSinceReferenceDate, // Cocoa Compatibility
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
    
    /// Return a dictionary of header fields that can be used to add the
    /// specified cookies to the request.
    ///
    /// - Parameter cookies: The cookies to turn into request headers.
    /// - Returns: A dictionary where the keys are header field names, and the values
    /// are the corresponding header field values.
    public class func requestHeaderFields(with cookies: [HTTPCookie]) -> [String : String] {
        var cookieString = cookies.reduce("") { (sum, next) -> String in
            return sum + "\(next._name)=\(next._value); "
        }
        //Remove the final trailing semicolon and whitespace
        if ( cookieString.length > 0 ) {
            cookieString.characters.removeLast()
            cookieString.characters.removeLast()
        }
        return ["Cookie": cookieString]
    }
   
    /// Return an array of cookies parsed from the specified response header fields and URL.
    ///
    /// This method will ignore irrelevant header fields so
    /// you can pass a dictionary containing data other than cookie data.
    /// - Parameter headerFields: The response header fields to check for cookies.
    /// - Parameter URL: The URL that the cookies came from - relevant to how the cookies are interpeted.
    /// - Returns: An array of NSHTTPCookie objects
    public class func cookies(withResponseHeaderFields headerFields: [String : String], forURL url: URL) -> [HTTPCookie] {

        //HTTP Cookie parsing based on RFC 6265: https://tools.ietf.org/html/rfc6265
        //Though RFC6265 suggests that multiple cookies cannot be folded into a single Set-Cookie field, this is
        //pretty common. It also suggests that commas and semicolons among other characters, cannot be a part of 
        // names and values. This implementation takes care of multiple cookies in the same field, however it doesn't   
        //support commas and semicolons in names and values(except for dates)

        guard let cookies: String = headerFields["Set-Cookie"]  else { return [] }  

        let nameValuePairs = cookies.components(separatedBy: ";")          //split the name/value and attribute/value pairs
                                .map({$0.trim()})                           //trim whitespaces
                                .map({removeCommaFromDate($0)})     //get rid of commas in dates
                                .flatMap({$0.components(separatedBy: ",")}) //cookie boundaries are marked by commas
                                .map({$0.trim()})                           //trim again
                                .filter({$0.caseInsensitiveCompare("HTTPOnly") != .orderedSame})  //we don't use HTTPOnly, do we?
                                .flatMap({createNameValuePair(pair: $0)})   //create Name and Value properties 

        //mark cookie boundaries in the name-value array
        var cookieIndices = (0..<nameValuePairs.count).filter({nameValuePairs[$0].hasPrefix("Name")})
        cookieIndices.append(nameValuePairs.count)  

        //bake the cookies
        var httpCookies: [HTTPCookie] = []
        for i in 0..<cookieIndices.count-1 {
            if let aCookie = createHttpCookie(url: url, pairs: nameValuePairs, start: cookieIndices[i], end: cookieIndices[i+1]) {
                httpCookies.append(aCookie)
            }
        }
    
        return httpCookies
    } 

    //Bake a cookie
    private class func createHttpCookie(url: URL, pairs: [String], start: Int, end: Int) -> HTTPCookie? {
        var properties: [String:Any] = [:]
        for index in start..<end {
            let name = pairs[index].components(separatedBy: "=")[0]
            var value = pairs[index].components(separatedBy: "\(name)=")[1]  //a value can have an "="
            if canonicalize(name) == "Expires" {
                value = value.insertComma(at: 3)    //re-insert the comma   
            }
            properties[canonicalize(name)] = value
        }
 
        //if domain wasn't provided use the URL
        if properties[NSHTTPCookieDomain] == nil {
            properties[NSHTTPCookieDomain] = url.absoluteString
        }
        
        //the default Path is "/"
        if properties[NSHTTPCookiePath] == nil {
            properties[NSHTTPCookiePath] = "/"
        } 

        return HTTPCookie(properties: properties)
    }

    //we pass this to a map()
    private class func removeCommaFromDate(_ value: String) -> String {
        if value.hasPrefix("Expires") || value.hasPrefix("expires")  {
            return value.removeCommas()
        }
        return value
    }

    //These cookie attributes are defined in RFC 6265 and 2965(which is obsolete)
    //HTTPCookie supports these
    private class func isCookieAttribute(_ string: String) -> Bool {
        return _attributes.first(where: {$0.caseInsensitiveCompare(string) == .orderedSame}) != nil
    }

    //Cookie attribute names are case-insensitive as per RFC6265: https://tools.ietf.org/html/rfc6265
    //but HTTPCookie needs only the first letter of each attribute in uppercase
    private class func canonicalize(_ name: String) -> String {
        let idx = _attributes.index(where: {$0.caseInsensitiveCompare(name) == .orderedSame})!
        return _attributes[idx]
    }

    //A name=value pair should be translated to two properties, Name=name and Value=value
    private class func createNameValuePair(pair: String) -> [String] {
        if pair.caseInsensitiveCompare(NSHTTPCookieSecure) == .orderedSame {
            return ["Secure=TRUE"]
        }
        let name = pair.components(separatedBy: "=")[0]
        let value = pair.components(separatedBy: "\(name)=")[1]
        if !isCookieAttribute(name) {
            return ["Name=\(name)", "Value=\(value)"]
        }
        return [pair]
    }

    /// Returns a dictionary representation of the receiver.
    ///
    /// This method returns a dictionary representation of the
    /// `NSHTTPCookie` which can be saved and passed to
    /// `init(properties:)` later to reconstitute an equivalent cookie.
    ///
    /// See the `NSHTTPCookie` `init(properties:)` method for
    /// more information on the constraints imposed on the dictionary, and
    /// for descriptions of the supported keys and values.
    ///
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
    /// - Note: Since this API is under consideration it may be either removed or revised in the near future
    public var properties: [String : Any]? {
        return _properties
    }
    
    /// The version of the receiver.
    ///
    /// Version 0 maps to "old-style" Netscape cookies.
    /// Version 1 maps to RFC2965 cookies. There may be future versions.
    public var version: Int {
        return _version
    }
    
    /// The name of the receiver.
    public var name: String {
        return _name
    }
    
    /// The value of the receiver.
    public var value: String {
        return _value
    }
    
    /// Returns The expires date of the receiver.
    ///
    /// The expires date is the date when the cookie should be
    /// deleted. The result will be nil if there is no specific expires
    /// date. This will be the case only for *session-only* cookies.
    /*@NSCopying*/ public var expiresDate: Date? {
        return _expiresDate
    }
   
    /// Whether the receiver is session-only.
    ///
    /// `true` if this receiver should be discarded at the end of the
    /// session (regardless of expiration date), `false` if receiver need not
    /// be discarded at the end of the session.
    public var isSessionOnly: Bool {
        return _sessionOnly
    }
    
    /// The domain of the receiver.
    ///
    /// This value specifies URL domain to which the cookie
    /// should be sent. A domain with a leading dot means the cookie
    /// should be sent to subdomains as well, assuming certain other
    /// restrictions are valid. See RFC 2965 for more detail.
    public var domain: String {
        return _domain
    }
    
    /// The path of the receiver.
    ///
    /// This value specifies the URL path under the cookie's
    /// domain for which this cookie should be sent. The cookie will also
    /// be sent for children of that path, so `"/"` is the most general.
    public var path: String {
        return _path
    }
   
    /// Whether the receiver should be sent only over secure channels
    ///
    /// Cookies may be marked secure by a server (or by a javascript).
    /// Cookies marked as such must only be sent via an encrypted connection to
    /// trusted servers (i.e. via SSL or TLS), and should not be delievered to any
    /// javascript applications to prevent cross-site scripting vulnerabilities. 
    public var isSecure: Bool {
        return _secure
    }
    
    /// Whether the receiver should only be sent to HTTP servers per RFC 2965
    ///
    /// Cookies may be marked as HTTPOnly by a server (or by a javascript).
    /// Cookies marked as such must only be sent via HTTP Headers in HTTP Requests
    /// for URL's that match both the path and domain of the respective Cookies.
    /// Specifically these cookies should not be delivered to any javascript
    /// applications to prevent cross-site scripting vulnerabilities.
    public var isHTTPOnly: Bool {
        return _HTTPOnly
    }
    
    /// The comment of the receiver.
    ///
    /// This value specifies a string which is suitable for
    /// presentation to the user explaining the contents and purpose of this
    /// cookie. It may be nil.
    public var comment: String? {
        return _comment
    }
    
    /// The comment URL of the receiver.
    ///
    /// This value specifies a URL which is suitable for
    /// presentation to the user as a link for further information about
    /// this cookie. It may be nil.
    /*@NSCopying*/ public var commentURL: URL? {
        return _commentURL
    }
    
    /// The list ports to which the receiver should be sent.
    ///
    /// This value specifies an NSArray of NSNumbers
    /// (containing integers) which specify the only ports to which this
    /// cookie should be sent.
    ///
    /// The array may be nil, in which case this cookie can be sent to any
    /// port.
    public var portList: [NSNumber]? {
        return _portList
    }
}

//utils for cookie parsing
internal extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines())
    }

    func removeCommas() -> String {
        return self.replacingOccurrences(of: ",", with: "")
    }

    func insertComma(at index:Int) -> String {
        return  String(self.characters.prefix(index)) + ","  + String(self.characters.suffix(self.characters.count-index))
    }
}

