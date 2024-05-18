// Foundation/URLSession/HTTPMessage.swift - HTTP Message parsing
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// Helpers for parsing HTTP responses.
/// These are libcurl helpers for the URLSession API code.
/// - SeeAlso: https://curl.haxx.se/libcurl/c/
/// - SeeAlso: URLSession.swift
///
// -----------------------------------------------------------------------------

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import SwiftFoundation
#else
import Foundation
#endif
@_implementationOnly import CoreFoundation

internal extension _HTTPURLProtocol._ResponseHeaderLines {
    /// Create an `NSHTTPRULResponse` from the lines.
    ///
    /// This will parse the header lines.
    /// - Returns: `nil` if an error occurred while parsing the header lines.
    func createHTTPURLResponse(for URL: URL) -> HTTPURLResponse? {
        guard let message = createHTTPMessage() else { return nil }
        return HTTPURLResponse(message: message, URL: URL)
    }
    /// Parse the lines into a `_HTTPURLProtocol.HTTPMessage`.
    func createHTTPMessage() -> _HTTPURLProtocol._HTTPMessage? {
        guard let (head, tail) = lines.decompose else { return nil }
        guard let startline = _HTTPURLProtocol._HTTPMessage._StartLine(line: head) else { return nil }
        guard let headers = createHeaders(from: tail) else { return nil }
        return _HTTPURLProtocol._HTTPMessage(startLine: startline, headers: headers)
    }
}

extension HTTPURLResponse {
    fileprivate convenience init?(message: _HTTPURLProtocol._HTTPMessage, URL: URL) {
        /// This needs to be a request, i.e. it needs to have a status line.
        guard case .statusLine(let version, let status, _) = message.startLine else { return nil }
        let fields = message.headersAsDictionary
        self.init(url: URL, statusCode: status, httpVersion: version.rawValue, headerFields: fields)
    }
}


extension _HTTPURLProtocol {
    /// HTTP Message
    ///
    /// A message consist of a *start-line* optionally followed by one or multiple
    /// message-header lines, and optionally a message body.
    ///
    /// This represents everything except for the message body.
    ///
    /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-4
    struct _HTTPMessage {
        let startLine: _HTTPURLProtocol._HTTPMessage._StartLine
        let headers: [_HTTPURLProtocol._HTTPMessage._Header]
    }
}

extension _HTTPURLProtocol._HTTPMessage {
    var headersAsDictionary: [String: String] {
        var result: [String: String] = [:]
        headers.forEach {
            if result[$0.name] == nil {
                result[$0.name] = $0.value
            }
            else {
                result[$0.name]! += (", " + $0.value)
            }
        }
        return result
    }
}
extension _HTTPURLProtocol._HTTPMessage {
    /// A single HTTP message header field
    ///
    /// Most HTTP messages have multiple header fields.
    struct _Header {
        let name: String
        let value: String
    }
    /// The first line of a HTTP message
    ///
    /// This can either be the *request line* (RFC 2616 Section 5.1) or the
    /// *status line* (RFC 2616 Section 6.1)
    enum _StartLine {
        /// RFC 2616 Section 5.1 *Request Line*
        /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-5.1
        case requestLine(method: String, uri: URL, version: _HTTPURLProtocol._HTTPMessage._Version)
        /// RFC 2616 Section 6.1 *Status Line*
        /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-6.1
        case statusLine(version: _HTTPURLProtocol._HTTPMessage._Version, status: Int, reason: String)
    }
    /// A HTTP version, e.g. "HTTP/1.1"
    struct _Version: RawRepresentable {
        let rawValue: String
    }
    /// An authentication challenge parsed from `WWW-Authenticate` header field.
    ///
    /// Only parts necessary for Basic auth scheme are implemented at the moment.
    /// - SeeAlso: https://tools.ietf.org/html/rfc7235#section-4.1
    struct _Challenge {
        static let AuthSchemeBasic = "basic"
        static let AuthSchemeDigest = "digest"
        /// A single auth challenge parameter
        struct _AuthParameter {
            let name: String
            let value: String
        }
        let authScheme: String
        let authParameters: [_AuthParameter]
    }
}
extension _HTTPURLProtocol._HTTPMessage._Version {
    init?(versionString: String) {
        rawValue = versionString
    }
}
extension _HTTPURLProtocol._HTTPMessage._Challenge {
    /// Case-insensitively searches for auth parameter with specified name
    func parameter(withName name: String) -> _AuthParameter? {
        return authParameters.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}
extension _HTTPURLProtocol._HTTPMessage._Challenge {
    /// Creates authentication challenges from provided `HTTPURLResponse`.
    ///
    /// The value of `WWW-Authenticate` field is used for parsing authentication challenges
    /// of supported type.
    ///
    /// - note: `Basic` is the only supported scheme at the moment.
    /// - parameter response: A response to get header value from.
    /// - returns: An array of supported challenges found in response.
    /// # Reference
    /// - [RFC 7235 - Hypertext Transfer Protocol (HTTP/1.1): Authentication](https://tools.ietf.org/html/rfc7235)
    /// - [RFC 7617 - The 'Basic' HTTP Authentication Scheme](https://tools.ietf.org/html/rfc7617)
    static func challenges(from response: HTTPURLResponse) -> [_HTTPURLProtocol._HTTPMessage._Challenge] {
        guard let authenticateValue = response.value(forHTTPHeaderField: "WWW-Authenticate") else {
            return []
        }
        return challenges(from: authenticateValue)
    }
    /// Creates authentication challenges from provided field value.
    ///
    /// Field value is expected to conform [RFC 7235 Section 4.1](https://tools.ietf.org/html/rfc7235#section-4.1)
    /// as much as needed to define supported authorization schemes.
    ///
    /// - note: `Basic` is the only supported scheme at the moment.
    /// - parameter authenticateFieldValue: A value of `WWW-Authenticate` field
    /// - returns: array of supported challenges found.
    /// # Reference
    /// - [RFC 7235 - Hypertext Transfer Protocol (HTTP/1.1): Authentication](https://tools.ietf.org/html/rfc7235)
    /// - [RFC 7617 - The 'Basic' HTTP Authentication Scheme](https://tools.ietf.org/html/rfc7617)
    static func challenges(from authenticateFieldValue: String) -> [_HTTPURLProtocol._HTTPMessage._Challenge] {
        var challenges = [_HTTPURLProtocol._HTTPMessage._Challenge]()
        
        // Typical WWW-Authenticate header is something like
        //   WWWW-Authenticate: Digest realm="test", domain="/HTTP/Digest", nonce="e3d002b9b2080453fdacea2d89f2d102"
        //
        // https://tools.ietf.org/html/rfc7235#section-4.1
        //   WWW-Authenticate = 1#challenge
        //
        // https://tools.ietf.org/html/rfc7235#section-2.1
        //   challenge      = auth-scheme [ 1*SP ( token68 / #auth-param ) ]
        //   auth-scheme    = token
        //   auth-param     = token BWS "=" BWS ( token / quoted-string )
        //   token68        = 1*( ALPHA / DIGIT /
        //                        "-" / "." / "_" / "~" / "+" / "/" ) *"="
        //
        // https://tools.ietf.org/html/rfc7230#section-3.2.3
        //   OWS            = *( SP / HTAB ) ; optional whitespace
        //   BWS            = OWS            ; "bad" whitespace
        //
        // https://tools.ietf.org/html/rfc7230#section-3.2.6
        //   token          = 1*tchar
        //   tchar          = "!" / "#" / "$" / "%" / "&" / "'" / "*"
        //                    / "+" / "-" / "." / "^" / "_" / "`" / "|" / "~"
        //                    / DIGIT / ALPHA
        //                   ; any VCHAR, except delimiters
        //   quoted-string  = DQUOTE *( qdtext / quoted-pair ) DQUOTE
        //   qdtext         = HTAB / SP /%x21 / %x23-5B / %x5D-7E / obs-text
        //   obs-text       = %x80-FF
        //   quoted-pair    = "\" ( HTAB / SP / VCHAR / obs-text )
        //
        // https://tools.ietf.org/html/rfc5234#appendix-B.1
        //   ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z
        //   SP             =  %x20
        //   HTAB           =  %x09                ; horizontal tab
        //   VCHAR          =  %x21-7E             ; visible (printing) characters
        //   DQUOTE         =  %x22
        //   DIGIT          =  %x30-39             ; 0-9
        
        var authenticateView = authenticateFieldValue.unicodeScalars[...]
        // Do an "eager" search of supported auth schemes. Same as it implemented in CURL.
        // This means we will look after every comma on every step, no matter what was
        // (or wasn't) parsed on previous step.
        //
        // WWW-Authenticate field could contain some sort of ambiguity, because, in general,
        // it is a comma-separated list of comma-separated lists. As mentioned
        // in https://tools.ietf.org/html/rfc7235#section-4.1, user agents are advised to
        // take special care of parsing all challenges completely.
        while !authenticateView.isEmpty {
            guard let authSchemeRange = authenticateView.rangeOfTokenPrefix else {
                break
            }
            let authScheme = String(authenticateView[authSchemeRange])
            if authScheme.caseInsensitiveCompare(AuthSchemeBasic) == .orderedSame {
                let authDataView = authenticateView[authSchemeRange.upperBound...]
                let authParameters = _HTTPURLProtocol._HTTPMessage._Challenge._AuthParameter.parameters(from: authDataView)
                let challenge = _HTTPURLProtocol._HTTPMessage._Challenge(authScheme: authScheme, authParameters: authParameters)
                // "realm" is the only mandatory parameter for Basic auth scheme. Otherwise consider parsed data invalid.
                if challenge.parameter(withName: "realm") != nil {
                    challenges.append(challenge)
                }
            }
            // read up to the next comma
            guard let commaIndex = authenticateView.firstIndex(of: _Delimiters.Comma) else {
                break
            }
            // skip comma
            authenticateView = authenticateView[authenticateView.index(after: commaIndex)...]
            // consume spaces
            authenticateView = authenticateView.trimSPPrefix
        }
        return challenges
    }
}
private extension _HTTPURLProtocol._HTTPMessage._Challenge._AuthParameter {
    /// Reads authorization challenge parameters from provided Unicode Scalar view
    static func parameters(from parametersView: String.UnicodeScalarView.SubSequence) -> [_HTTPURLProtocol._HTTPMessage._Challenge._AuthParameter] {
        var parametersView = parametersView
        var parameters = [_HTTPURLProtocol._HTTPMessage._Challenge._AuthParameter]()
        while true {
            parametersView = parametersView.trimSPPrefix
            guard let parameter = parameter(from: &parametersView) else {
                break
            }
            parameters.append(parameter)
            // trim spaces and expect comma
            parametersView = parametersView.trimSPPrefix
            guard parametersView.first == _Delimiters.Comma else {
                break
            }
            // drop comma
            parametersView = parametersView.dropFirst()
        }
        return parameters
    }
    /// Reads a single challenge parameter from provided Unicode Scalar view
    private static func parameter(from parametersView: inout String.UnicodeScalarView.SubSequence) -> _HTTPURLProtocol._HTTPMessage._Challenge._AuthParameter? {
        // Read parameter name. Return nil if name is not readable.
        guard let parameterName = parameterName(from: &parametersView) else {
            return nil
        }
        // Trim BWS, expect '='
        parametersView = parametersView.trimSPHTPrefix ?? parametersView
        guard parametersView.first == _Delimiters.Equals else {
            return nil
        }
        // Drop '='
        parametersView = parametersView.dropFirst()
        // Read parameter value. Return nil if parameter is not readable.
        guard let parameterValue = parameterValue(from: &parametersView) else {
            return nil
        }
        return _HTTPURLProtocol._HTTPMessage._Challenge._AuthParameter(name: parameterName, value: parameterValue)
    }
    /// Reads a challenge parameter name from provided Unicode Scalar view
    private static func parameterName(from nameView: inout String.UnicodeScalarView.SubSequence) -> String? {
        guard let nameRange = nameView.rangeOfTokenPrefix else {
            return nil
        }
        
        let name = String(nameView[nameRange])
        nameView = nameView[nameRange.upperBound...]
        return name
    }
    /// Reads a challenge parameter value from provided Unicode Scalar view
    private static func parameterValue(from valueView: inout String.UnicodeScalarView.SubSequence) -> String? {
        // Trim BWS
        valueView = valueView.trimSPHTPrefix ?? valueView
        if valueView.first == _Delimiters.DoubleQuote {
            // quoted-string
            if let valueRange = valueView.rangeOfQuotedStringPrefix {
                let value = valueView[valueRange].dequotedString()
                valueView = valueView[valueRange.upperBound...]
                return value
            }
        }
        else {
            // token
            if let valueRange = valueView.rangeOfTokenPrefix {
                let value = String(valueView[valueRange])
                valueView = valueView[valueRange.upperBound...]
                return value
            }
        }
        return nil
    }
}
private extension _HTTPURLProtocol._HTTPMessage._StartLine {
    init?(line: String) {
        guard let r = line.splitRequestLine() else { return nil }
        if let version = _HTTPURLProtocol._HTTPMessage._Version(versionString: r.0) {
            // Status line:
            guard let status = Int(r.1), 100 <= status && status <= 999 else { return nil }
            self = .statusLine(version: version, status: status, reason: r.2)
        } else if let version = _HTTPURLProtocol._HTTPMessage._Version(versionString: r.2),
            let URI = URL(string: r.1) {
            // The request method must be a token (i.e. without separators):
            let separatorIdx = r.0.unicodeScalars.firstIndex(where: { !$0.isValidMessageToken } )
            guard separatorIdx == nil else { return nil }
            self = .requestLine(method: r.0, uri: URI, version: version)
        } else {
            return nil
        }
    }
}
private extension String {
    /// Split a request line into its 3 parts: *Method*, *Request-URI*, and *HTTP-Version*.
    /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-5.1
    func splitRequestLine() -> (String, String, String)? {
        let scalars = self.unicodeScalars[...]
        guard let firstSpace = scalars.rangeOfSpace else { return nil }
        let remainingRange = firstSpace.upperBound..<scalars.endIndex
        let remainder = scalars[remainingRange]
        guard let secondSpace = remainder.rangeOfSpace else { return nil }
        let methodRange = scalars.startIndex..<firstSpace.lowerBound
        let uriRange = remainder.startIndex..<secondSpace.lowerBound
        let versionRange = secondSpace.upperBound..<remainder.endIndex
      
        //TODO: is this necessary? If yes, this guard needs an alternate implementation 
        //guard 0 < methodRange.count && 0 < uriRange.count && 0 < versionRange.count else { return nil } 

        let m = String(scalars[methodRange])
        let u = String(remainder[uriRange])
        let v = String(remainder[versionRange])
        return (m, u, v)
    }
}

/// Parses an array of lines into an array of
/// `URLSessionTask.HTTPMessage.Header`.
///
/// This respects the header folding as described by
/// https://tools.ietf.org/html/rfc2616#section-2.2 :
///
/// - SeeAlso: `_HTTPURLProtocol.HTTPMessage.Header.createOne(from:)`
private func createHeaders(from lines: ArraySlice<String>) -> [_HTTPURLProtocol._HTTPMessage._Header]? {

    var headerLines = Array(lines)
    var headers: [_HTTPURLProtocol._HTTPMessage._Header] = []
    while !headerLines.isEmpty {
        guard let (header, remaining) = _HTTPURLProtocol._HTTPMessage._Header.createOne(from: headerLines) else { return nil }
        headers.append(header)
        headerLines = remaining
    }
    return headers
}
private extension _HTTPURLProtocol._HTTPMessage._Header {
    /// Parse a single HTTP message header field
    ///
    /// Each header field consists
    /// of a name followed by a colon (":") and the field value. Field names
    /// are case-insensitive. The field value MAY be preceded by any amount
    /// of LWS, though a single SP is preferred. Header fields can be
    /// extended over multiple lines by preceding each extra line with at
    /// least one SP or HT. Applications ought to follow "common form", where
    /// one is known or indicated, when generating HTTP constructs, since
    /// there might exist some implementations that fail to accept anything
    /// beyond the common forms.
    ///
    /// Consumes lines from the given array of lines to produce a single HTTP
    /// message header and returns the resulting header plus the remainder.
    ///
    /// If an error occurs, it returns `nil`.
    ///
    /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-4.2
    static func createOne(from lines: [String]) -> (_HTTPURLProtocol._HTTPMessage._Header, [String])? {
        // HTTP/1.1 header field values can be folded onto multiple lines if the
        // continuation line begins with a space or horizontal tab. All linear
        // white space, including folding, has the same semantics as SP. A
        // recipient MAY replace any linear white space with a single SP before
        // interpreting the field value or forwarding the message downstream.
        guard let (head, tail) = lines.decompose else { return nil }
        let headView = head.unicodeScalars[...]
        guard let nameRange = headView.rangeOfTokenPrefix else { return nil }
        guard headView.index(after: nameRange.upperBound) <= headView.endIndex && headView[nameRange.upperBound] == _Delimiters.Colon else { return nil }
        let name = String(headView[nameRange])
        var value: String?
        let line = headView[headView.index(after: nameRange.upperBound)..<headView.endIndex]
        if !line.isEmpty {
            if line.hasSPHTPrefix && line.count == 1 {
                // to handle empty headers i.e header without value
                value = ""
            } else {
                guard let v = line.trimSPHTPrefix else { return nil }
                value = String(v)
            }
        }
        do {
            var t = tail
            while t.first?.unicodeScalars[...].hasSPHTPrefix ?? false {
                guard let (h2, t2) = t.decompose else { return nil }
                t = t2
                guard let v = h2.unicodeScalars[...].trimSPHTPrefix else { return nil }
                let valuePart = String(v)
                value = value.map { $0 + " " + valuePart } ?? valuePart
            }
            return (_HTTPURLProtocol._HTTPMessage._Header(name: name, value: value ?? ""), Array(t))
        }
    }
}
private extension Collection {
    /// Splits the collection into its first element and the remainder.
    var decompose: (Iterator.Element, Self.SubSequence)? {
        guard let head = self.first else { return nil }
        let tail = self[self.index(after: startIndex)..<endIndex]
        return (head, tail)
    }
}
private extension String.UnicodeScalarView.SubSequence {
    /// The range of *Token* characters as specified by RFC 2616.
    var rangeOfTokenPrefix: Range<Index>? {
        guard !isEmpty else { return nil }
        var end = startIndex
        while self[end].isValidMessageToken {
            end = self.index(after: end)
        }
        guard end != startIndex else { return nil }
        return startIndex..<end
    }
    /// The range of space (U+0020) characters.
    var rangeOfSpace: Range<Index>? {
        guard !isEmpty else { return startIndex..<startIndex }
        guard let idx = firstIndex(of: _Delimiters.Space!) else { return nil }
        return idx..<self.index(after: idx)
    }
    // Has a space (SP) or horizontal tab (HT) prefix
    var hasSPHTPrefix: Bool {
        guard !isEmpty else { return false }
        return self[startIndex] == _Delimiters.Space || self[startIndex] == _Delimiters.HorizontalTab
    }
    /// Unicode scalars after removing the leading spaces (SP) and horizontal tabs (HT).
    /// Returns `nil` if the unicode scalars do not start with a SP or HT.
    var trimSPHTPrefix: SubSequence? {
        guard !isEmpty else { return nil }
        var idx = startIndex
        while idx < endIndex {
            if self[idx] == _Delimiters.Space || self[idx] == _Delimiters.HorizontalTab {
                idx = self.index(after: idx)
            } else {
                guard startIndex < idx else { return nil }
                return self[idx..<endIndex]
            }
        }
        return nil
    }
    var trimSPPrefix: SubSequence {
        var idx = startIndex
        while idx < endIndex {
            if self[idx] == _Delimiters.Space {
                idx = self.index(after: idx)
            } else {
                return self[idx..<endIndex]
            }
        }
        return self
    }
    /// Returns range of **quoted-string** starting from first index of sequence.
    ///
    /// - returns: range of **quoted-string** or `nil` if value can not be parsed.
    var rangeOfQuotedStringPrefix: Range<Index>? {
        //   quoted-string  = DQUOTE *( qdtext / quoted-pair ) DQUOTE
        //   qdtext         = HTAB / SP /%x21 / %x23-5B / %x5D-7E / obs-text
        //   obs-text       = %x80-FF
        //   quoted-pair    = "\" ( HTAB / SP / VCHAR / obs-text )
        guard !isEmpty else {
            return nil
        }
        var idx = startIndex
        // Expect and consume dquote
        guard self[idx] == _Delimiters.DoubleQuote else {
            return nil
        }
        idx = self.index(after: idx)
        var isQuotedPair = false
        while idx < endIndex {
            let currentScalar = self[idx]
            if currentScalar == _Delimiters.Backslash && !isQuotedPair {
                isQuotedPair = true
            } else if isQuotedPair {
                guard currentScalar.isQuotedPairEscapee else {
                    return nil
                }
                isQuotedPair = false
            } else if currentScalar == _Delimiters.DoubleQuote {
                break
            } else {
                guard currentScalar.isQdtext else {
                    return nil
                }
            }
            idx = self.index(after: idx)
        }
        // Expect stop on dquote
        guard idx < endIndex, self[idx] == _Delimiters.DoubleQuote else {
            return nil
        }
        return startIndex..<self.index(after: idx)
    }
    /// Returns dequoted string if receiver contains **quoted-string**
    ///
    /// - returns: dequoted string or `nil` if receiver does not contain valid quoted string
    func dequotedString() -> String? {
        guard !isEmpty else {
            return nil
        }
        var resultView = String.UnicodeScalarView()
        resultView.reserveCapacity(self.count)
        var idx = startIndex
        // Expect and consume dquote
        guard self[idx] == _Delimiters.DoubleQuote else {
            return nil
        }
        idx = self.index(after: idx)
        var isQuotedPair = false
        while idx < endIndex {
            let currentScalar = self[idx]
            if currentScalar == _Delimiters.Backslash && !isQuotedPair {
                isQuotedPair = true
            } else if isQuotedPair {
                guard currentScalar.isQuotedPairEscapee else {
                    return nil
                }
                isQuotedPair = false
                resultView.append(currentScalar)
            } else if currentScalar == _Delimiters.DoubleQuote {
                break
            } else {
                guard currentScalar.isQdtext else {
                    return nil
                }
                resultView.append(currentScalar)
            }
            idx = self.index(after: idx)
        }
        // Expect stop on dquote
        guard idx < endIndex, self[idx] == _Delimiters.DoubleQuote else {
            return nil
        }
        return String(resultView)
    }
}
private extension UnicodeScalar {
    /// Is this a valid **token** as defined by RFC 2616 ?
    ///
    /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-2
    var isValidMessageToken: Bool {
        guard UnicodeScalar(32) <= self && self <= UnicodeScalar(126) else { return false }
        return !_Delimiters.Separators.characterIsMember(UInt16(self.value))
    }
    /// Is this a valid **qdtext** character
    ///
    /// - SeeAlso: https://tools.ietf.org/html/rfc7230#section-3.2.6
    var isQdtext: Bool {
        //   qdtext         = HTAB / SP /%x21 / %x23-5B / %x5D-7E / obs-text
        //   obs-text       = %x80-FF
        let value = self.value
        return self == _Delimiters.HorizontalTab
            || self == _Delimiters.Space
            || value == 0x21
            || 0x23 <= value && value <= 0x5B
            || 0x5D <= value && value <= 0x7E
            || 0x80 <= value && value <= 0xFF
            
    }
    /// Is this a valid second octet of **quoted-pair**
    ///
    /// - SeeAlso: https://tools.ietf.org/html/rfc7230#section-3.2.6
    /// - SeeAlso: https://tools.ietf.org/html/rfc5234#appendix-B.1
    var isQuotedPairEscapee: Bool {
        // quoted-pair    = "\" ( HTAB / SP / VCHAR / obs-text )
        // obs-text       = %x80-FF
        let value = self.value
        return self == _Delimiters.HorizontalTab
            || self == _Delimiters.Space
            || 0x21 <= value && value <= 0x7E
            || 0x80 <= value && value <= 0xFF
    }
}
