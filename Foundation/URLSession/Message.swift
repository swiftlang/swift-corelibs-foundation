// Foundation/URLSession/Message.swift - URLSession & libcurl
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// Common code for Header parsing 
///
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
