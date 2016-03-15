// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/*!
    @class NSURLResponse

    @abstract An NSURLResponse object represents a URL load response in a
    manner independent of protocol and URL scheme.

    @discussion NSURLResponse encapsulates the metadata associated
    with a URL load. Note that NSURLResponse objects do not contain
    the actual bytes representing the content of a URL. See
    NSURLConnection and NSURLConnectionDelegate for more information
    about receiving the content data for a URL load.
*/
public class NSURLResponse : NSObject, NSSecureCoding, NSCopying {

    static public func supportsSecureCoding() -> Bool {
        return true
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    /*!
        @method initWithURL:MIMEType:expectedContentLength:textEncodingName:
        @abstract Initialize an NSURLResponse with the provided values.
        @param URL the URL
        @param MIMETYPE the MIME content type of the response
        @param expectedContentLength the expected content length of the associated data
        @param textEncodingName the name of the text encoding for the associated data, if applicable, else nil
        @result The initialized NSURLResponse.
        @discussion This is the designated initializer for NSURLResponse.
    */
    public init(url: NSURL, mimeType: String?, expectedContentLength length: Int, textEncodingName name: String?) {
        self.url = url
        self.mimeType = mimeType
        self.expectedContentLength = Int64(length)
        self.textEncodingName = name
        let c = url.lastPathComponent
        self.suggestedFilename = (c?.isEmpty ?? true) ? "Unknown" : c
    }
    
    /*! 
        @method URL
        @abstract Returns the URL of the receiver. 
        @result The URL of the receiver. 
    */
    /*@NSCopying*/ public private(set) var url: NSURL?

    
    /*! 
        @method MIMEType
        @abstract Returns the MIME type of the receiver. 
        @discussion The MIME type is based on the information provided
        from an origin source. However, that value may be changed or
        corrected by a protocol implementation if it can be determined
        that the origin server or source reported the information
        incorrectly or imprecisely. An attempt to guess the MIME type may
        be made if the origin source did not report any such information.
        @result The MIME type of the receiver.
    */
    public private(set) var mimeType: String?
    
    /*! 
        @method expectedContentLength
        @abstract Returns the expected content length of the receiver.
        @discussion Some protocol implementations report a content length
        as part of delivering load metadata, but not all protocols
        guarantee the amount of data that will be delivered in actuality.
        Hence, this method returns an expected amount. Clients should use
        this value as an advisory, and should be prepared to deal with
        either more or less data.
        @result The expected content length of the receiver, or -1 if
        there is no expectation that can be arrived at regarding expected
        content length.
    */
    public private(set) var expectedContentLength: Int64
    
    /*! 
        @method textEncodingName
        @abstract Returns the name of the text encoding of the receiver.
        @discussion This name will be the actual string reported by the
        origin source during the course of performing a protocol-specific
        URL load. Clients can inspect this string and convert it to an
        NSStringEncoding or CFStringEncoding using the methods and
        functions made available in the appropriate framework.
        @result The name of the text encoding of the receiver, or nil if no
        text encoding was specified. 
    */
    public private(set) var textEncodingName: String?
    
    /*!
        @method suggestedFilename
        @abstract Returns a suggested filename if the resource were saved to disk.
        @discussion The method first checks if the server has specified a filename using the
        content disposition header. If no valid filename is specified using that mechanism,
        this method checks the last path component of the URL. If no valid filename can be
        obtained using the last path component, this method uses the URL's host as the filename.
        If the URL's host can't be converted to a valid filename, the filename "unknown" is used.
        In mose cases, this method appends the proper file extension based on the MIME type.
        This method always returns a valid filename.
        @result A suggested filename to use if saving the resource to disk.
    */
    public private(set) var suggestedFilename: String?
}

/*!
    @class NSHTTPURLResponse

    @abstract An NSHTTPURLResponse object represents a response to an
    HTTP URL load. It is a specialization of NSURLResponse which
    provides conveniences for accessing information specific to HTTP
    protocol responses.
*/
public class NSHTTPURLResponse : NSURLResponse {
    
    /*!
      @method	initWithURL:statusCode:HTTPVersion:headerFields:
      @abstract initializer for NSHTTPURLResponse objects.
      @param 	url the URL from which the response was generated.
      @param	statusCode an HTTP status code.
      @param	HTTPVersion The version of the HTTP response as represented by the server.  This is typically represented as "HTTP/1.1".
      @param 	headerFields A dictionary representing the header keys and values of the server response.
      @result 	the instance of the object, or NULL if an error occurred during initialization.
      @discussion This API was introduced in Mac OS X 10.7.2 and iOS 5.0 and is not available prior to those releases.
    */
    public init?(url: NSURL, statusCode: Int, httpVersion: String?, headerFields: [String : String]?) {
        self.statusCode = statusCode
        self.allHeaderFields = headerFields ?? [:]
        super.init(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        expectedContentLength = getExpectedContentLength(fromHeaderFields: headerFields) ?? -1
        suggestedFilename = getSuggestedFilename(fromHeaderFields: headerFields) ?? "Unknown"
        if let type = ContentTypeComponents(headerFields: headerFields) {
            mimeType = type.mimeType.lowercased()
            textEncodingName = type.textEncoding?.lowercased()
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    /*! 
        @method statusCode
        @abstract Returns the HTTP status code of the receiver. 
        @result The HTTP status code of the receiver. 
    */
    public let statusCode: Int
    
    /// Returns a dictionary containing all the HTTP header fields
    /// of the receiver.
    ///
    /// By examining this header dictionary, clients can see
    /// the "raw" header information which was reported to the protocol
    /// implementation by the HTTP server. This may be of use to
    /// sophisticated or special-purpose HTTP clients.
    ///
    /// - Returns: A dictionary containing all the HTTP header fields of the
    /// receiver.
    ///
    /// - Important: This is an *experimental* change from the
    /// `[NSObject: AnyObject]` type that Darwin Foundation uses.
    public let allHeaderFields: [String: String]
    
    /*!
        @method localizedStringForStatusCode:
        @abstract Convenience method which returns a localized string
        corresponding to the status code for this response.
        @param the status code to use to produce a localized string.
        @result A localized string corresponding to the given status code.
    */
    public class func localizedString(forStatusCode statusCode: Int) -> String { NSUnimplemented() }
}
/// Parses the expected content length from the headers.
///
/// Note that the message content length is different from the message
/// transfer length.
/// The transfer length can only be derived when the Transfer-Encoding is identity (default).
/// For compressed content (Content-Encoding other than identity), there is not way to derive the
/// content length from the transfer length.
private func getExpectedContentLength(fromHeaderFields headerFields: [String : String]?) -> Int64? {
    guard
        let f = headerFields,
        let contentLengthS = valueForCaseInsensitiveKey("content-length", fields: f),
        let contentLength = Int64(contentLengthS)
        else { return nil }
    return contentLength
}
/// Parses the suggested filename from the `Content-Disposition` header.
///
/// - SeeAlso: [RFC 2183](https://tools.ietf.org/html/rfc2183)
private func getSuggestedFilename(fromHeaderFields headerFields: [String : String]?) -> String? {
    // Typical use looks like this:
    //     Content-Disposition: attachment; filename="fname.ext"
    guard
        let f = headerFields,
        let contentDisposition = valueForCaseInsensitiveKey("content-disposition", fields: f),
        let field = contentDisposition.httpHeaderParts
        else { return nil }
    for part in field.parameters where part.attribute == "filename" {
        return part.value?.pathComponents.map{ $0 == "/" ? "" : $0}.joined(separator: "_")
    }
    return nil
}
/// Parts corresponding to the `Content-Type` header field in a HTTP message.
private struct ContentTypeComponents {
    /// For `text/html; charset=ISO-8859-4` this would be `text/html`
    let mimeType: String
    /// For `text/html; charset=ISO-8859-4` this would be `ISO-8859-4`. Will be
    /// `nil` when no `charset` is specified.
    let textEncoding: String?
}
extension ContentTypeComponents {
    /// Parses the `Content-Type` header field
    ///
    /// `Content-Type: text/html; charset=ISO-8859-4` would result in `("text/html", "ISO-8859-4")`, while
    /// `Content-Type: text/html` would result in `("text/html", nil)`.
    init?(headerFields: [String : String]?) {
        guard
            let f = headerFields,
            let contentType = valueForCaseInsensitiveKey("content-type", fields: f),
            let field = contentType.httpHeaderParts
            else { return nil }
        for parameter in field.parameters where parameter.attribute == "charset" {
            self.mimeType = field.value
            self.textEncoding = parameter.value
            return
        }
        self.mimeType = field.value
        self.textEncoding = nil
    }
}

/// A type with paramteres
///
/// RFC 2616 specifies a few types that can have parameters, e.g. `Content-Type`.
/// These are specified like so
/// ```
/// field          = value *( ";" parameter )
/// value          = token
/// ```
/// where parameters are attribute/value as specified by
/// ```
/// parameter               = attribute "=" value
/// attribute               = token
/// value                   = token | quoted-string
/// ```
private struct ValueWithParameters {
    let value: String
    let parameters: [Parameter]
    struct Parameter {
        let attribute: String
        let value: String?
    }
}

private extension String {
    /// Split the string at each ";", remove any quoting.
    /// 
    /// The trouble is if there's a
    /// ";" inside something that's quoted. And we can escape the separator and
    /// the quotes with a "\".
    var httpHeaderParts: ValueWithParameters? {
        var type: String?
        var parameters: [ValueWithParameters.Parameter] = []
        let ws = NSCharacterSet.whitespaceCharacterSet()
        func append(_ string: String) {
            if type == nil {
                type = string
            } else {
                if let r = string.rangeOfString("=") {
                    let name = string[string.startIndex..<r.startIndex].stringByTrimmingCharactersInSet(ws)
                    let value = string[r.endIndex..<string.endIndex].stringByTrimmingCharactersInSet(ws)
                    parameters.append(ValueWithParameters.Parameter(attribute: name, value: value))
                } else {
                    let name = string.stringByTrimmingCharactersInSet(ws)
                    parameters.append(ValueWithParameters.Parameter(attribute: name, value: nil))
                }
            }
        }
        
        let escape = UnicodeScalar(0x5c)    //  \
        let quote = UnicodeScalar(0x22)     //  "
        let separator = UnicodeScalar(0x3b) //  ;
        enum State {
            case nonQuoted(String)
            case nonQuotedEscaped(String)
            case quoted(String)
            case quotedEscaped(String)
        }
        var state = State.nonQuoted("")
        for next in unicodeScalars {
            switch (state, next) {
            case (.nonQuoted(let s), separator):
                append(s)
                state = .nonQuoted("")
            case (.nonQuoted(let s), escape):
                state = .nonQuotedEscaped(s + String(next))
            case (.nonQuoted(let s), quote):
                state = .quoted(s)
            case (.nonQuoted(let s), _):
                state = .nonQuoted(s + String(next))
                
            case (.nonQuotedEscaped(let s), _):
                state = .nonQuoted(s + String(next))
                
            case (.quoted(let s), quote):
                state = .nonQuoted(s)
            case (.quoted(let s), escape):
                state = .quotedEscaped(s + String(next))
            case (.quoted(let s), _):
                state = .quoted(s + String(next))
            
            case (.quotedEscaped(let s), _):
                state = .quoted(s + String(next))
            }
        }
        switch state {
            case .nonQuoted(let s): append(s)
            case .nonQuotedEscaped(let s): append(s)
            case .quoted(let s): append(s)
            case .quotedEscaped(let s): append(s)
        }
        guard let t = type else { return nil }
        return ValueWithParameters(value: t, parameters: parameters)
    }
}
private func valueForCaseInsensitiveKey(_ key: String, fields: [String: String]) -> String? {
    let kk = key.lowercased()
    for (k, v) in fields {
        if k.lowercased() == kk {
            return v
        }
    }
    return nil
}
