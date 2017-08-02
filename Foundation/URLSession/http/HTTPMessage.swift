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

import CoreFoundation


extension _HTTPURLProtocol {
    /// An HTTP header being parsed.
    ///
    /// It can either be complete (i.e. the final CR LF CR LF has been
    /// received), or partial.
    internal enum _ParsedResponseHeader {
        case partial(_ResponseHeaderLines)
        case complete(_ResponseHeaderLines)
        init() {
            self = .partial(_ResponseHeaderLines())
        }
    }
    /// A type safe wrapper around multiple lines of headers.
    ///
    /// This can be converted into an `HTTPURLResponse`.
    internal struct _ResponseHeaderLines {
        let lines: [String]
        init() {
            self.lines = []
        }
        init(headerLines: [String]) {
            self.lines = headerLines
        }
    }
}

extension _HTTPURLProtocol._ParsedResponseHeader {
    /// Parse a header line passed by libcurl.
    ///
    /// These contain the <CRLF> ending and the final line contains nothing but
    /// that ending.
    /// - Returns: Returning nil indicates failure. Otherwise returns a new
    ///     `ParsedResponseHeader` with the given line added.
    func byAppending(headerLine data: Data) -> _HTTPURLProtocol._ParsedResponseHeader? {
        // The buffer must end in CRLF
        guard
            2 <= data.count &&
                data[data.endIndex - 2] == _HTTPCharacters.CR &&
                data[data.endIndex - 1] == _HTTPCharacters.LF
            else { return nil }
        let lineBuffer = data.subdata(in: Range(data.startIndex..<data.endIndex-2))
        guard let line = String(data: lineBuffer, encoding: String.Encoding.utf8) else { return nil}
        return byAppending(headerLine: line)
    }
    /// Append a status line.
    ///
    /// If the line is empty, it marks the end of the header, and the result
    /// is a complete header. Otherwise it's a partial header.
    /// - Note: Appending a line to a complete header results in a partial
    ///     header with just that line.
    private func byAppending(headerLine line: String) -> _HTTPURLProtocol._ParsedResponseHeader {
        if line.isEmpty {
            switch self {
            case .partial(let header): return .complete(header)
            case .complete: return .partial(_HTTPURLProtocol._ResponseHeaderLines())
            }
        } else {
            let header = partialResponseHeader
            return .partial(header.byAppending(headerLine: line))
        }
    }
    private var partialResponseHeader: _HTTPURLProtocol._ResponseHeaderLines {
        switch self {
        case .partial(let header): return header
        case .complete: return _HTTPURLProtocol._ResponseHeaderLines()
        }
    }
}
private extension _HTTPURLProtocol._ResponseHeaderLines {
    /// Returns a copy of the lines with the new line appended to it.
    func byAppending(headerLine line: String) -> _HTTPURLProtocol._ResponseHeaderLines {
        var l = self.lines
        l.append(line)
        return _HTTPURLProtocol._ResponseHeaderLines(headerLines: l)
    }
}
internal extension _HTTPURLProtocol._ResponseHeaderLines {
    /// Create an `NSHTTPRULResponse` from the lines.
    ///
    /// This will parse the header lines.
    /// - Returns: `nil` if an error occured while parsing the header lines.
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
        guard case .statusLine(let statusLine) = message.startLine else { return nil }
        let fields = message.headersAsDictionary
        self.init(url: URL, statusCode: statusLine.status, httpVersion: statusLine.version.rawValue, headerFields: fields)
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
}
extension _HTTPURLProtocol._HTTPMessage._Version {
    init?(versionString: String) {
        rawValue = versionString
    }
}


// Characters that we need for HTTP parsing:

struct _HTTPCharacters {
    /// *Carriage Return* symbol
    static let CR: UInt8 = 0x0d
    /// *Line Feed* symbol
    static let LF: UInt8 = 0x0a
    /// *Space* symbol
    static let Space = UnicodeScalar(0x20)
    static let HorizontalTab = UnicodeScalar(0x09)
    static let Colon = UnicodeScalar(0x3a)
    /// *Separators* according to RFC 2616
    static let Separators = NSCharacterSet(charactersIn: "()<>@,;:\\\"/[]?={} \t")
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
            // The request method must be a token (i.e. without seperators):
            let seperatorIdx = r.0.unicodeScalars.index(where: { !$0.isValidMessageToken } )
            guard seperatorIdx == nil else { return nil }
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
        guard headView.index(after: nameRange.upperBound) <= headView.endIndex && headView[nameRange.upperBound] == _HTTPCharacters.Colon else { return nil }
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
        guard let idx = index(of: _HTTPCharacters.Space!) else { return nil }
        return idx..<self.index(after: idx)
    }
    // Has a space (SP) or horizontal tab (HT) prefix
    var hasSPHTPrefix: Bool {
        guard !isEmpty else { return false }
        return self[startIndex] == _HTTPCharacters.Space || self[startIndex] == _HTTPCharacters.HorizontalTab
    }
    /// Unicode scalars after removing the leading spaces (SP) and horizontal tabs (HT).
    /// Returns `nil` if the unicode scalars do not start with a SP or HT.
    var trimSPHTPrefix: SubSequence? {
        guard !isEmpty else { return nil }
        var idx = startIndex
        while idx < endIndex {
            if self[idx] == _HTTPCharacters.Space || self[idx] == _HTTPCharacters.HorizontalTab {
                idx = self.index(after: idx)
            } else {
                guard startIndex < idx else { return nil }
                return self[idx..<endIndex]
            }
        }
        return nil
    }
}
private extension UnicodeScalar {
    /// Is this a valid **token** as defined by RFC 2616 ?
    ///
    /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-2
    var isValidMessageToken: Bool {
        guard UnicodeScalar(32) <= self && self <= UnicodeScalar(126) else { return false }
        return !_HTTPCharacters.Separators.characterIsMember(UInt16(self.value))
    }
}
