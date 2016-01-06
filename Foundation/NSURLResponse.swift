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
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
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
    public init(URL: NSURL, MIMEType: String?, expectedContentLength length: Int, textEncodingName name: String?) {
        self.URL = URL
        self.MIMEType = MIMEType
        self.expectedContentLength = Int64(length)
        self.textEncodingName = name
    }
    
    /*! 
        @method URL
        @abstract Returns the URL of the receiver. 
        @result The URL of the receiver. 
    */
    /*@NSCopying*/ public private(set) var URL: NSURL?

    
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
    public private(set) var MIMEType: String?
    
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
    public var suggestedFilename: String? { NSUnimplemented() }
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
    public init?(URL url: NSURL, statusCode: Int, HTTPVersion: String?, headerFields: [String : String]?) { NSUnimplemented() }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    /*! 
        @method statusCode
        @abstract Returns the HTTP status code of the receiver. 
        @result The HTTP status code of the receiver. 
    */
    public var statusCode: Int { NSUnimplemented() }
    
    /*! 
        @method allHeaderFields
        @abstract Returns a dictionary containing all the HTTP header fields
        of the receiver.
        @discussion By examining this header dictionary, clients can see
        the "raw" header information which was reported to the protocol
        implementation by the HTTP server. This may be of use to
        sophisticated or special-purpose HTTP clients.
        @result A dictionary containing all the HTTP header fields of the
        receiver.
    */
    public var allHeaderFields: [NSObject : AnyObject] { NSUnimplemented() }
    
    /*! 
        @method localizedStringForStatusCode:
        @abstract Convenience method which returns a localized string
        corresponding to the status code for this response.
        @param the status code to use to produce a localized string.
        @result A localized string corresponding to the given status code.
    */
    public class func localizedStringForStatusCode(statusCode: Int) -> String { NSUnimplemented() }
}

