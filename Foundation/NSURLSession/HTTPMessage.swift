// Foundation/NSURLSession/HTTPMessage.swift - HTTP Message parsing
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
/// These are libcurl helpers for the NSURLSession API code.
/// - SeeAlso: https://curl.haxx.se/libcurl/c/
/// - SeeAlso: NSURLSession.swift
///
// -----------------------------------------------------------------------------

import CoreFoundation
import Dispatch



extension NSURLSessionTask {
    /// An HTTP header being parsed.
    ///
    /// It can either be complete (i.e. the final CR LF CR LF has been
    /// received), or partial.
    internal enum ParsedResponseHeader {
        case partial(ResponseHeaderLines)
        case complete(ResponseHeaderLines)
        init() {
            self = .partial(ResponseHeaderLines())
        }
    }
    /// A type safe wrapper around multiple lines of headers.
    ///
    /// This can be converted into an `NSHTTPURLResponse`.
    internal struct ResponseHeaderLines {
        let lines: [String]
        init() {
            self.lines = []
        }
        init(headerLines: [String]) {
            self.lines = headerLines
        }
    }
}

extension NSURLSessionTask.ParsedResponseHeader {
    /// Parse a header line passed by libcurl.
    ///
    /// These contain the <CRLF> ending and the final line contains nothing but
    /// that ending.
    /// - Returns: Returning nil indicates failure. Otherwise returns a new
    ///     `ParsedResponseHeader` with the given line added.
    @warn_unused_result
    func byAppending(headerLine data: UnsafeBufferPointer<Int8>) -> NSURLSessionTask.ParsedResponseHeader? {
        // The buffer must end in CRLF
        guard
            2 <= data.count &&
                data[data.endIndex - 2] == CR &&
                data[data.endIndex - 1] == LF
            else { return nil }
        let lineBuffer = UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.baseAddress), count: data.count - 2)
        guard let line = String(utf8Buffer: lineBuffer) else { return nil }
        return byAppending(headerLine: line)
    }
    /// Append a status line.
    ///
    /// If the line is empty, it marks the end of the header, and the result
    /// is a complete header. Otherwise it's a partial header.
    /// - Note: Appending a line to a complete header results in a partial
    ///     header with just that line.
    @warn_unused_result
    private func byAppending(headerLine line: String) -> NSURLSessionTask.ParsedResponseHeader {
        if line.isEmpty {
            switch self {
            case .partial(let header): return .complete(header)
            case .complete: return .partial(NSURLSessionTask.ResponseHeaderLines())
            }
        } else {
            let header = partialResponseHeader
            return .partial(header.byAppending(headerLine: line))
        }
    }
    private var partialResponseHeader: NSURLSessionTask.ResponseHeaderLines {
        switch self {
        case .partial(let header): return header
        case .complete: return NSURLSessionTask.ResponseHeaderLines()
        }
    }
}
private extension NSURLSessionTask.ResponseHeaderLines {
    /// Returns a copy of the lines with the new line appended to it.
    @warn_unused_result
    func byAppending(headerLine line: String) -> NSURLSessionTask.ResponseHeaderLines {
        var l = self.lines
        l.append(line)
        return NSURLSessionTask.ResponseHeaderLines(headerLines: l)
    }
}
internal extension NSURLSessionTask.ResponseHeaderLines {
    /// Create an `NSHTTPRULResponse` from the lines.
    ///
    /// This will parse the header lines.
    /// - Returns: `nil` if an error occured while parsing the header lines.
    @warn_unused_result
    func createHTTPURLResponse(for URL: NSURL) -> NSHTTPURLResponse? {
        guard let message = createHTTPMessage() else { return nil }
        return NSHTTPURLResponse(message: message, URL: URL)
    }
    /// Parse the lines into a `NSURLSessionTask.HTTPMessage`.
    @warn_unused_result
    func createHTTPMessage() -> NSURLSessionTask.HTTPMessage? {
        guard let (head, tail) = lines.decompose else { return nil }
        guard let startline = NSURLSessionTask.HTTPMessage.StartLine(line: head) else { return nil }
        guard let headers = createHeaders(from: tail) else { return nil }
        return NSURLSessionTask.HTTPMessage(startLine: startline, headers: headers)
    }
}

extension NSHTTPURLResponse {
    private convenience init?(message: NSURLSessionTask.HTTPMessage, URL: NSURL) {
        /// This needs to be a request, i.e. it needs to have a status line.
        guard case .statusLine(let statusLine) = message.startLine else { return nil }
        let fields = message.headersAsDictionary
        self.init(url: URL, statusCode: statusLine.status, httpVersion: statusLine.version.rawValue, headerFields: fields)
    }
}


extension NSURLSessionTask {
    /// HTTP Message
    ///
    /// A message consist of a *start-line* optionally followed by one or multiple
    /// message-header lines, and optionally a message body.
    ///
    /// This represents everything except for the message body.
    ///
    /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-4
    struct HTTPMessage {
        let startLine: NSURLSessionTask.HTTPMessage.StartLine
        let headers: [NSURLSessionTask.HTTPMessage.Header]
    }
}

extension NSURLSessionTask.HTTPMessage {
    var headersAsDictionary: [String: String] {
        var result: [String: String] = [:]
        headers.forEach {
            result[$0.name] = $0.value
        }
        return result
    }
}
extension NSURLSessionTask.HTTPMessage {
    /// A single HTTP message header field
    ///
    /// Most HTTP messages have multiple header fields.
    struct Header {
        let name: String
        let value: String
    }
    /// The first line of a HTTP message
    ///
    /// This can either be the *request line* (RFC 2616 Section 5.1) or the
    /// *status line* (RFC 2616 Section 6.1)
    enum StartLine {
        /// RFC 2616 Section 5.1 *Request Line*
        /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-5.1
        case requestLine(method: String, uri: NSURL, version: NSURLSessionTask.HTTPMessage.Version)
        /// RFC 2616 Section 6.1 *Status Line*
        /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-6.1
        case statusLine(version: NSURLSessionTask.HTTPMessage.Version, status: Int, reason: String)
    }
    /// A HTTP version, e.g. "HTTP/1.1"
    struct Version: RawRepresentable {
        let rawValue: String
    }
}
extension NSURLSessionTask.HTTPMessage.Version {
    init?(versionString: String) {
        rawValue = versionString
    }
}


// Characters that we need for HTTP parsing:

/// *Carriage Return* symbol
private let CR: Int8 = 0x0d
/// *Line Feed* symbol
private let LF: Int8 = 0x0a
/// *Space* symbol
private let Space = UnicodeScalar(0x20)
private let HorizontalTab = UnicodeScalar(0x09)
private let Colon = UnicodeScalar(0x3a)
/// *Separators* according to RFC 2616
private let Separators: [UnicodeScalar] = [
    0x28, 0x29, 0x3c, 0x3e, 0x40, // "("  ")"  "<"  ">"  "@"
    0x2c, 0x3b, 0x3a, 0x5c, 0x22, // ","  ";"  ":"  "\"  <">
    0x2f, 0x5b, 0x5d, 0x3f, 0x3d, // "/"  "["  "]"  "?"  "="
    0x7b, 0x7d, 0x20, 0x09,       // "{"  "}"  SP  HT
].map { UnicodeScalar($0) }

private extension NSURLSessionTask.HTTPMessage.StartLine {
    init?(line: String) {
        guard let r = line.splitRequestLine() else { return nil }
        if let version = NSURLSessionTask.HTTPMessage.Version(versionString: r.0) {
            // Status line:
            guard let status = Int(r.1) where 100 <= status && status <= 999 else { return nil }
            self = .statusLine(version: version, status: status, reason: r.2)
        } else if let version = NSURLSessionTask.HTTPMessage.Version(versionString: r.2),
            let URI = NSURL(string: r.1) {
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
        let scalars = self.unicodeScalars
        guard let firstSpace = scalars.rangeOfSpace else { return nil }
        let remainingRange = firstSpace.endIndex..<scalars.endIndex
        let remainder = scalars[remainingRange]
        guard let secondSpace = remainder.rangeOfSpace else { return nil }
        let methodRange = scalars.startIndex..<firstSpace.startIndex
        let uriRange = remainder.startIndex..<secondSpace.startIndex
        let versionRange = secondSpace.endIndex..<remainder.endIndex
        guard 0 < methodRange.count && 0 < uriRange.count && 0 < versionRange.count else { return nil }
        
        let m = String(scalars[methodRange])
        let u = String(remainder[uriRange])
        let v = String(remainder[versionRange])
        return (m, u, v)
    }
}
/// Parses an array of lines into an array of
/// `NSURLSessionTask.HTTPMessage.Header`.
///
/// This respects the header folding as described by
/// https://tools.ietf.org/html/rfc2616#section-2.2 :
///
/// - SeeAlso: `NSURLSessionTask.HTTPMessage.Header.createOne(from:)`
private func createHeaders(from lines: ArraySlice<String>) -> [NSURLSessionTask.HTTPMessage.Header]? {
    var headerLines = Array(lines)
    var headers: [NSURLSessionTask.HTTPMessage.Header] = []
    while !headerLines.isEmpty {
        guard let (header, remaining) = NSURLSessionTask.HTTPMessage.Header.createOne(from: headerLines) else { return nil }
        headers.append(header)
        headerLines = remaining
    }
    return headers
}
private extension NSURLSessionTask.HTTPMessage.Header {
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
    static func createOne(from lines: [String]) -> (NSURLSessionTask.HTTPMessage.Header, [String])? {
        // HTTP/1.1 header field values can be folded onto multiple lines if the
        // continuation line begins with a space or horizontal tab. All linear
        // white space, including folding, has the same semantics as SP. A
        // recipient MAY replace any linear white space with a single SP before
        // interpreting the field value or forwarding the message downstream.
        guard let (head, tail) = lines.decompose else { return nil }
        let headView = head.unicodeScalars
        guard let nameRange = headView.rangeOfTokenPrefix else { return nil }
        guard nameRange.endIndex.successor() <= headView.endIndex && headView[nameRange.endIndex] == Colon else { return nil }
        let name = String(headView[nameRange])
        var value: String?
        let line = headView[nameRange.endIndex.successor()..<headView.endIndex]
        if !line.isEmpty {
            guard let v = line.trimSPHTPrefix else { return nil }
            value = String(v)
        }
        do {
            var t = tail
            while t.first?.unicodeScalars.hasSPHTPrefix ?? false {
                guard let (h2, t2) = t.decompose else { return nil }
                t = t2
                guard let v = h2.unicodeScalars.trimSPHTPrefix else { return nil }
                let valuePart = String(v)
                value = value.map { $0 + " " + valuePart } ?? valuePart
            }
            return (NSURLSessionTask.HTTPMessage.Header(name: name, value: value ?? ""), Array(t))
        }
    }
}
private extension Collection {
    /// Splits the collection into its first element and the remainder.
    var decompose: (Iterator.Element, Self.SubSequence)? {
        guard let head = self.first else { return nil }
        let tail = self[startIndex.successor()..<endIndex]
        return (head, tail)
    }
}
private extension String.UnicodeScalarView {
    /// The range of *Token* characters as specified by RFC 2616.
    var rangeOfTokenPrefix: Range<Index>? {
        var end = startIndex
        while self[end].isValidMessageToken {
            end = end.successor()
        }
        guard end != startIndex else { return nil }
        return startIndex..<end
    }
    /// The range of space (U+0020) characters.
    var rangeOfSpace: Range<Index>? {
        guard !isEmpty else { return startIndex..<startIndex }
        guard let idx = index(of: Space) else { return nil }
        return idx..<idx.successor()
    }
    // Has a space (SP) or horizontal tab (HT) prefix
    var hasSPHTPrefix: Bool {
        guard !isEmpty else { return false }
        return self[startIndex] == Space || self[startIndex] == HorizontalTab
    }
    /// Unicode scalars after removing the leading spaces (SP) and horizontal tabs (HT).
    /// Returns `nil` if the unicode scalars do not start with a SP or HT.
    var trimSPHTPrefix: String.UnicodeScalarView? {
        guard !isEmpty else { return nil }
        var idx = startIndex
        while idx < endIndex {
            if self[idx] == Space || self[idx] == HorizontalTab {
                idx = idx.successor()
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
        return !Separators.contains(self)
    }
}
