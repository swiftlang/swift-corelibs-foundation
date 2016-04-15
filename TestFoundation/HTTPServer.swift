// TestFoundation/Tests/HTTPServer.swift - HTTP server for testing
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// This file implements a simple HTTP server designed specifically to help
/// testing the NSURLSession API. As such it is not a general purpose HTTP
/// server. But it allows inspection of HTTP header fields and body data that
/// arrives at the server. And returning arbitrary (even incorrect) responses.
///
// -----------------------------------------------------------------------------



#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
#else
    import SwiftFoundation
#endif
import Dispatch


//
//MARK: - HTTP Server -

typealias RequestHandler = (request: HTTPRequest) -> (HTTPResponse)
private let OperationCancelledError = ECANCELED



/// This handler can be passed to SocketServer.withAcceptHandler to create an HTTP server.
func httpConnectionHandler(channel: dispatch_io_t, clientAddress: SocketAddress, queue: dispatch_queue_t, handler: RequestHandler) -> () {
    dispatch_io_set_low_water(channel, 1)
    
    var accumulated: dispatch_data_t? = nil
    var request = RequestInProgress.none
    
    read(channel: channel, offset: 0, length: Int.max, queue: queue) { (done, result) in
        switch result {
        case .data(let data):
            // Append the data and update the request:
            accumulated = accumulated.flatMap { $0 + data } ?? data
            if let a = accumulated {
                let r = request.consume(data: a, done: done)
                request = r.request
                accumulated = r.remainder
            }
        case .error(let error) where error != OperationCancelledError:
            print("Error on channel: \(String(validatingUTF8: strerror(error)) ?? "") (\(error))")
            dispatch_io_close(channel, 0)
        case .error:
            dispatch_io_close(channel, 0)
        case .empty:
            break
        }
        switch request {
        case let .complete(message, body: body):
            request = RequestInProgress.none
            guard let r = HTTPRequest(message: message, body: body, clientAddress: clientAddress) else {
                dispatch_io_close(channel, 0)
                return
            }
            let response = handler(request: r)
            let data = response.serializedData
            write(channel: channel, offset: 0, data: data, queue: queue) { (done, result) in
                if case .error(let error) = result where error != OperationCancelledError {
                    print("Error on channel: \(String(validatingUTF8: strerror(error)) ?? "") (\(error))")
                    dispatch_io_close(channel, 0)
                }
            }
            
        case .error:
            dispatch_io_close(channel, DISPATCH_IO_STOP)
        default:
            break
        }
        if (done) {
            dispatch_io_close(channel, 0)
        }
    }
}

private func read(channel: dispatch_io_t, offset: off_t, length: Int, queue: dispatch_queue_t, handler: (done: Bool, result: ReadWriteResult) -> ()) {
    dispatch_io_read(channel, offset, length, queue) { (done, data, error) in
        handler(done: done, result: ReadWriteResult(data: data, error: error))
    }
}
private func write(channel: dispatch_io_t, offset: off_t, data: dispatch_data_t, queue: dispatch_queue_t, handler: (done: Bool, result: ReadWriteResult) -> ()) {
    dispatch_io_write(channel, offset, data, queue) { (done, data, error) in
        handler(done: done, result: ReadWriteResult(data: data, error: error))
    }
}

private enum ReadWriteResult {
    case empty
    case data(dispatch_data_t)
    case error(CInt)
}
extension ReadWriteResult {
    init(data: dispatch_data_t?, error: CInt) {
        if let d = data where error == 0 {
            self = .data(d)
        } else if error != 0 {
            self = .error(error)
        } else {
            self = .empty
        }
    }
}



private func splitData(data: dispatch_data_t, location: Int) -> (dispatch_data_t, dispatch_data_t) {
    let head = dispatch_data_create_subrange(data, 0, location)
    let tail = dispatch_data_create_subrange(data, location, dispatch_data_get_size(data) - location)
    return (head, tail)
}

private struct RequestInProgressAndRemainder {
    let request: RequestInProgress
    let remainder: dispatch_data_t
    init(_ r: RequestInProgress, _ d: dispatch_data_t) {
        request = r
        remainder = d
    }
}

private enum RequestInProgress {
    case none
    case error
    case incompleteHeader
    case incompleteMessage(HTTPMessage)
    case complete(HTTPMessage, body: dispatch_data_t?)
}

extension RequestInProgress {
    func consume(data: dispatch_data_t, done: Bool) -> RequestInProgressAndRemainder {
        switch self {
        case .error:
            return RequestInProgressAndRemainder(.error, data)
        case .none:
            fallthrough
        case .incompleteHeader:
            if let message = HTTPMessage(byteCollection: ByteCollection(data: data)) {
                guard message.isRequest else { return RequestInProgressAndRemainder(.error, data) }
                let remainingData = dataSuffix(data, from: message.byteCountConsumed)
                return RequestInProgressAndRemainder(message: message, data: remainingData, done: done)
            } else {
                return RequestInProgressAndRemainder(.incompleteHeader, data)
            }
        case let .incompleteMessage(message):
            return RequestInProgressAndRemainder(message: message, data: data, done: done)
        case let .complete(message, body: body):
            return RequestInProgressAndRemainder(.complete(message, body: body), data)
        }
    }
}

private func dataSuffix(_ data: dispatch_data_t, from: Int) -> dispatch_data_t {
    return dispatch_data_create_subrange(data, from, dispatch_data_get_size(data) - from)
}
private func dataSubrange(_ data: dispatch_data_t, range: Range<Int>) -> dispatch_data_t {
    return dispatch_data_create_subrange(data, range.startIndex, range.count)
}

extension RequestInProgressAndRemainder {
    private init(message: HTTPMessage, data: dispatch_data_t, done: Bool) {
        if let bodyLength = message.transferLength where done || bodyLength <= dispatch_data_get_size(data) {
            let body = dataSubrange(data, range: 0..<bodyLength)
            let tail = dataSuffix(data, from: bodyLength)
            self.init(.complete(message, body: body), tail)
        } else {
            self.init(.incompleteMessage(message), data)
        }
    }
}

//
//MARK: - Socket Server -
//


public enum SocketError : ErrorProtocol {
    case NoPortAvailable
}




public final class SocketServer {
    public struct Channel {
        public let channel: dispatch_io_t
        public let address: SocketAddress
    }
    
    public let port: UInt16
    
    /// The accept handler will be called with a suspended dispatch I/O channel and the client's SocketAddress.
    public convenience init(acceptHandler: (Channel) -> ()) throws {
        let serverSocket = try TCPSocket(domain: .Inet)
        let port = try serverSocket.bindToAnyPort()
        try serverSocket.set(statusFlags: .O_NONBLOCK)
        try self.init(serverSocket: serverSocket, port: port, acceptHandler: acceptHandler)
    }
    
    let serverSocket: TCPSocket
    let acceptSource: dispatch_source_t
    
    private init(serverSocket ss: TCPSocket, port p: UInt16, acceptHandler: (Channel) -> ()) throws {
        serverSocket = ss
        port = p
        acceptSource = SocketServer.createSource(with: ss, port: p, acceptHandler: acceptHandler)
        dispatch_resume(acceptSource)
        try serverSocket.listen()
    }
    
    private static func createSource(with socket: TCPSocket, port: UInt16, acceptHandler: (Channel) -> ()) -> dispatch_source_t {
        let queue = dispatch_queue_create("server on port \(port)", DISPATCH_QUEUE_CONCURRENT)
        let source = socket.createDispatchReadSource(with: queue)
        
        dispatch_source_set_event_handler(source) {
            forEachPendingConnection(source) {
                do {
                    let clientSocket = try socket.accept()
                    let io = clientSocket.createIOChannel(with: queue)
                    let channel = Channel(channel: io, address: clientSocket.address)
                    acceptHandler(channel)
                } catch let e {
                    print("Failed to accept incoming connection: \(e)")
                }
            }
        }
        return source
    }
    
    deinit {
        dispatch_source_cancel(acceptSource)
        ignoreAndLogErrors {
            try serverSocket.close()
        }
    }
}


private func forEachPendingConnection(_ source: dispatch_source_t, b: () -> ()) {
    for _ in 0..<dispatch_source_get_data(source) {
        b()
    }
}


private extension TCPSocket {
    func bindToAnyPort() throws -> UInt16 {
        for port in UInt16(8000 + arc4random_uniform(1000))...10000 {
            do {
                try bindToPort(port)
                return port
            } catch let e as ServerError where e.errno == EADDRINUSE {
                continue
            }
        }
        throw SocketError.NoPortAvailable
    }
}




//
//MARK: - HTTP Reuqest and Response -
//

struct HTTPRequest {
    private let message: HTTPMessage
    /// The message body
    ///
    /// This may differ from the entity body if a transfer-coding has been
    /// applied.
    ///
    /// - SeeAlso: RFC 2616 Section 5.1.1
    let body: dispatch_data_t?
    /// The request method
    ///
    /// - SeeAlso: RFC 2616 Section 5.1.1
    var method: String {
        return message.requestMethod ?? ""
    }
    var URI: NSURL {
        return message.requestURI ?? NSURL(string: "")!
    }
    /// The IP address of the client
    let clientAddress: SocketAddress
    /// Returns the field value for the given name.
    ///
    /// Field name matching is case insensitive as per RFC 2616 Section 4.2.
    func headerFieldWithName(fieldName: String) -> String? {
        return message.headerField(withName: fieldName)
    }
    init?(message: HTTPMessage, body: dispatch_data_t?, clientAddress: SocketAddress) {
        guard message.isRequest else { return nil }
        self.message = message
        self.body = body
        self.clientAddress = clientAddress
    }
}

extension HTTPRequest {
    func forEachHeaderField(@noescape handler: (name: String, value: String) -> ()) {
        message.headers.forEach {
            handler(name: $0.name, value: $0.value)
        }
    }
}

/// A HTTP response
///
/// - SeeAlso: RFC 2616 Section 6
struct HTTPResponse {
    /// *Status-Code* of RFC 2616 Section 6.1
    let statusCode: Int
    /// *Reason-Phrase* as per RFC 2616 Section 6.1
    let reasonPhrase: String
    /// *Request header fields* as per RFC 2616 Section 5.3
    let headerFields: [(String, String)]
    /// The message body as per RFC 2616 Section 5.1.1
    ///
    /// This is the message body, i.e. any transfer encoding has been applied to
    /// the entity body.
    let body: dispatch_data_t?
}


extension HTTPResponse {
    init(statusCode: Int, headerFields: [(String, String)], body: dispatch_data_t?) {
        self.init(
            statusCode: statusCode,
            reasonPhrase: statusCode.defaultHTTPStatusDescription ?? "Ok",
            headerFields: headerFields,
            body: body)
    }
}


private extension HTTPResponse {
    var serializedData: dispatch_data_t {
        // Status Line:
        var data = dispatchData("HTTP/1.1 \(statusCode) ")
        data += dispatchData(reasonPhrase)
        data += CRLFData
        // Headers
        if let headerData = encode(headerFields: headerFields) {
            data += headerData
        }
        data += CRLFData
        if let b = body {
            data += b
        }
        return data
    }
}

private func encode(headerFields fields: [(String, String)]) -> dispatch_data_t? {
    return fields.map(encodeHeaderField).reduce(nil) { (combined: dispatch_data_t?, line: dispatch_data_t) -> dispatch_data_t? in
        if let c = combined {
            return c + line
        } else {
            return line
        }
    }
}
private func encodeHeaderField(field: (String, String)) -> dispatch_data_t {
    return dispatchData(field.0) + dispatchData(": ") + dispatchData(field.1) + CRLFData
}




private let CRLFData = dispatchData("\r\n")

/// Encodes the string as UTF-8 into a dispatch_data_t without copying memory.
private func dispatchData(_ string: String) -> dispatch_data_t {
    // Avoid copying buffers. Simply allocate a buffer, fill it with the UTF-8,
    // and wrap the buffer as dispatch_data_t.
    var array = ContiguousArray<UTF8.CodeUnit>()
    for code in string.utf8 {
        array.append(code)
    }
    return array.withUnsafeBufferPointer { buffer in
        return dispatch_data_create(UnsafePointer<Void>(buffer.baseAddress), buffer.count, nil, nil)
    }
}

@warn_unused_result
private func +(lhs: dispatch_data_t, rhs: dispatch_data_t) -> dispatch_data_t {
    return dispatch_data_create_concat(lhs, rhs)
}
private func +=(lhs: inout dispatch_data_t, rhs: dispatch_data_t) {
    lhs = dispatch_data_create_concat(lhs, rhs)
}


private extension Int {
    var defaultHTTPStatusDescription: String? {
        switch self {
        case 100: return "Continue"
        case 101: return "Switching Protocols"
        case 102: return "Processing"
            
        case 200: return "Ok"
        case 201: return "Created"
        case 202: return "Accepted"
        case 203: return "Non-Authoritative Information"
        case 204: return "No Content"
        case 205: return "Reset Content"
        case 206: return "Partial Content"
        case 207: return "Multi-Status"
        case 208: return "Already Reported"
        case 226: return "IM Used"
            
        case 300: return "Multiple Choices"
        case 301: return "Moved Permanently"
        case 302: return "Found"
        case 303: return "See Other"
        case 304: return "Not Modified"
        case 305: return "Use Proxy"
        case 306: return "Switch Proxy"
        case 307: return "Temporary Redirect"
        case 308: return "Permanent Redirect"
            
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 402: return "Payment Required"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 406: return "Not Acceptable"
        case 407: return "Proxy Authentication Required"
        case 408: return "Request Timeout"
        case 409: return "Conflict"
        case 410: return "Gone"
        case 411: return "Length Required"
        case 412: return "Precondition Failed"
        case 413: return "Request Entity Too Large"
        case 414: return "Request-URI Too Long"
        case 415: return "Unsupported Media Type"
        case 416: return "Requested Range Not Satisfiable"
        case 417: return "Expectation Failed"
        case 418: return "I'm a teapot"
        case 419: return "Authentication Timeout"
        case 420: return "Method Failure"
        case 421: return "Misdirected Request"
        case 422: return "Unprocessed Entity"
        case 423: return "Locked"
        case 424: return "Failed Dependency"
        case 426: return "Upgrade Required"
        case 428: return "Precondition Required"
        case 429: return "Too Many Requests"
        case 431: return "Request Header Fields Too Large"
        case 440: return "Login Timeout"
        case 444: return "No Response"
        case 449: return "Retry With"
        case 450: return "Blocked by Windows Parental Controls"
        case 451: return "Unavailable For Legal Reasons"
        case 494: return "Request Header Too Large"
        case 495: return "Cert Error"
        case 496: return "No Cert"
        case 497: return "HTTP to HTTPS"
        case 498: return "Token expired/invalid"
        case 499: return "Client Closed Request"
            
        case 500: return "Internal Server Error"
        case 501: return "Not Implemented"
        case 502: return "Bad Gateway"
        case 503: return "Service Unavailable"
        case 504: return "Gateway Timeout"
        case 505: return "HTTP Version Not Supported"
        case 506: return "Variant Also Negotiates"
        case 507: return "Insufficient Storage"
        case 508: return "Loop Detected"
        case 509: return "Bandwidth Limit Exceeded"
        case 510: return "Not Extended"
        case 511: return "Network Authentication Required"
        case 598: return "Network read timeout error"
        case 599: return "Network connect timeout error"
        default: return nil
        }
    }
}



//
//MARK: - HTTP Message -
//


/// HTTP Message
///
/// A message consist of a *start-line* optionally followed by one or multiple
/// message-header lines, and optionally a message body.
///
/// This represents everything except for the message body.
///
/// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-4
struct HTTPMessage {
    let startLine: StartLine
    let headers: [MessageHeader]
    let byteCountConsumed: Int
    enum Version {
        case HTTP1_0
        case HTTP1_1
    }
}

protocol HTTPMessageType {
    var isRequest: Bool { get }
    var version: HTTPMessage.Version { get }
    var requestMethod: String? { get }
    var requestURI: NSURL? { get }
    func headerField(withName fieldName: String) -> String?
}

extension HTTPMessage : HTTPMessageType {
    var isRequest: Bool {
        switch startLine {
        case .RequestLine: return true
        case .StatusLine: return false
        }
    }
    var version: Version {
        switch startLine {
        case .RequestLine(method: _, uri: _, version: let version): return version
        case .StatusLine(version: let version, status: _, reason: _): return version
        }
    }
    /// The HTTP method
    ///
    /// Returns `nil` if and only if this is not a request.
    var requestMethod: String? {
        switch startLine {
        case .RequestLine(method: let method, uri: _, version: _): return method
        case .StatusLine: return nil
        }
    }
    var requestURI: NSURL? {
        switch startLine {
        case .RequestLine(method: _, uri: let uri, version: _): return uri
        case .StatusLine: return nil
        }
    }
    /// Returns the field value for the given name.
    ///
    /// Field name matching is case insensitive.
    func headerField(withName fieldName: String) -> String? {
        let lowercased = fieldName.lowercased()
        for header in headers {
            if header.name.lowercased() == lowercased {
                return header.value
            }
        }
        return nil
    }
}

private extension HTTPMessage {
    /// Parses raw bytes into a message.
    init?(byteCollection: ByteCollection) {
        let lines = byteCollection.generateHTTPLines()
        
        // Since header lines can be folded, we need to make this little dance:
        guard let startline = lines.next().flatMap({ StartLine($0) }) else { return nil }
        guard let (headerLines, endIndex) = filterHeaderLines(lines) else { return nil }
        guard let headers = createHeaders(fromLines: headerLines) else { return nil }
        
        self.startLine = startline
        self.headers = headers
        self.byteCountConsumed = endIndex - byteCollection.startIndex
    }
}

/// Consumes lines from the given generator until it finds an empty one, then returns all found lines.
/// If no empty line is found, returns `nil`.
private func filterHeaderLines(_ lines: AnyIterator<ByteCollection>) -> ([ByteCollection], ByteCollection.Index)? {
    var result: [ByteCollection] = []
    for line in lines {
        if line.isEmpty {
            return (result, line.endIndex + 2) // CRLF is 2 bytes long
        }
        result.append(line)
    }
    return nil
}

/// Parses `MessageHeader` from an array of lines.
private func createHeaders(fromLines lines: [ByteCollection]) -> [MessageHeader]? {
    var headerLines = lines
    var headers: [MessageHeader] = []
    while !headerLines.isEmpty {
        guard let (header, remaining) = MessageHeader.create(fromLines: headerLines) else { return nil }
        headers.append(header)
        headerLines = remaining
    }
    return headers
}

/// The first line of a HTTP message
///
/// This can either be the *request line* (RFC 2616 Section 5.1) or the
/// *status line* (RFC 2616 Section 6.1)
enum StartLine {
    /// RFC 2616 Section 5.1 *Request Line*
    /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-5.1
    case RequestLine(method: String, uri: NSURL, version: HTTPMessage.Version)
    /// RFC 2616 Section 6.1 *Status Line*
    /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-6.1
    case StatusLine(version: HTTPMessage.Version, status: Int, reason: String)
}

extension HTTPMessage.Version {
    init?(versionString: String) {
        switch versionString {
        case "HTTP/1.0": self = .HTTP1_0
        case "HTTP/1.1": self = .HTTP1_1
        default: return nil
        }
    }
}


struct MessageHeader {
    let name: String
    let value: String
}

/// A single HTTP message header field
///
/// Most HTTP messages have multiple header fields.
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
/// https://tools.ietf.org/html/rfc2616#section-4.2
private extension MessageHeader {
    static func create(fromLines lines: [ByteCollection]) -> (MessageHeader, [ByteCollection])? {
        // HTTP/1.1 header field values can be folded onto multiple lines if the
        // continuation line begins with a space or horizontal tab. All linear
        // white space, including folding, has the same semantics as SP. A
        // recipient MAY replace any linear white space with a single SP before
        // interpreting the field value or forwarding the message downstream.
        
        guard let (head, tail) = lines.decompose else { return nil }
        guard let nameRange = head.rangeOfTokenPrefix else { return nil }
        guard nameRange.endIndex.successor() <= head.endIndex && head[nameRange.endIndex] == Colon else { return nil }
        guard let name = head[nameRange].string else { return nil }
        var value: String?
        let line = head[nameRange.endIndex.successor()..<head.endIndex]
        if !line.isEmpty {
            guard line.hasSPHTPrefix else { return nil }
            guard let valuePart = line.suffix(from: line.startIndex.successor()).string else { return nil }
            value = valuePart
        }
        do {
            var t = tail
            while t.first?.hasSPHTPrefix ?? false {
                guard let (h2, t2) = t.decompose else { return nil }
                t = t2
                guard let valuePart = h2.suffix(from: h2.startIndex.successor()).string else { return nil }
                value = value.map { $0 + " " + valuePart } ?? valuePart
            }
            return (MessageHeader(name: name, value: value ?? ""), Array(t))
        }
    }
}

private extension Collection {
    var decompose: (Generator.Element, Self.SubSequence)? {
        guard let head = self.first else { return nil }
        let tail = self[startIndex.successor()..<endIndex]
        return (head, tail)
    }
}


private let MaximumLineLength = 16384
//private let r = 0..<4
private let CRLF: [UInt8] = [13, 10]
private let Space = UInt8(32)
private let HorizontalTab = UInt8(0x09)
private let Colon = UInt8(0x3a)
private let Seperators: [UInt8] = [
                                      0x28, 0x29, 0x3c, 0x3e, 0x40, // "("  ")"  "<"  ">"  "@"
    0x2c, 0x3b, 0x3a, 0x5c, 0x22, // ","  ";"  ":"  "\"  <">
    0x2f, 0x5b, 0x5d, 0x3f, 0x3d, // "/"  "["  "]"  "?"  "="
    0x7b, 0x7d, 0x20, 0x09, // "{"  "}"  SP  HT
]

private extension UInt8 {
    private var isValidToken: Bool {
        guard 32 <= self && self <= 126 else { return false }
        return !Seperators.contains(self)
    }
}


private extension StartLine {
    init?(_ byteCollection: ByteCollection) {
        guard let r = byteCollection.splitRequestLine() else { return nil }
        if let version = HTTPMessage.Version(versionString: r.0) {
            // Status line:
            guard let status = Int(r.1) where 100 <= status && status <= 999 else { return nil }
            self = .StatusLine(version: version, status: status, reason: r.2)
        } else if let version = HTTPMessage.Version(versionString: r.2),
            let URI = NSURL(string: r.1) {
            // The request method must be a token (i.e. without seperators):
            let seperatorIdx = r.0.utf8.index { !UInt8($0).isValidToken }
            guard seperatorIdx == nil else { return nil }
            self = .RequestLine(method: r.0, uri: URI, version: version)
        } else {
            return nil
        }
    }
}

private extension String {
    var isHTTPVersion: Bool {
        return self == "HTTP/1.0" || self == "HTTP/1.1"
    }
}

private extension ByteCollection {
    func splitRequestLine() -> (String, String, String)? {
        guard let firstSpace = range(of: [Space]) else { return nil }
        let remainingRange = firstSpace.endIndex..<self.endIndex
        let remainder = self[remainingRange]
        guard let secondSpace = remainder.range(of: [Space]) else { return nil }
        let methodRange = self.startIndex..<firstSpace.startIndex
        let uriRange = firstSpace.endIndex..<secondSpace.startIndex
        let versionRange = secondSpace.endIndex..<self.endIndex
        guard 0 < methodRange.count && 0 < uriRange.count && 0 < versionRange.count else { return nil }
        guard
            let m = self[methodRange].string,
            let u = self[uriRange].string,
            let v = self[versionRange].string
            else { return nil }
        return (m, u, v)
    }
}

extension ByteCollection {
    /// String representation.
    ///
    /// Returns `nil` if the byte sequence can not be interpreted as valid UTF-8.
    var string: String? {
        var result = String()
        var codec = UTF8()
        var g = makeIterator()
        repeat {
            switch codec.decode(&g) {
            case .scalarValue(let scalar):
                result.append(scalar)
            case .emptyInput:
                return result
            case .error:
                return nil
            }
        } while true
    }
}

extension ByteCollection {
    var rangeOfTokenPrefix: Range<Index>? {
        var end = startIndex
        while self[end].isValidToken {
            end = end.successor()
        }
        guard end != startIndex else { return nil }
        return startIndex..<end
    }
    var hasSPHTPrefix: Bool {
        guard !isEmpty else { return false }
        return self[startIndex] == Space || self[startIndex] == HorizontalTab
    }
}

extension ByteCollection {
    func range(of bytes: [UInt8]) -> Range<Index>? {
        guard !bytes.isEmpty else { return startIndex..<startIndex }
        var remaining = startIndex..<endIndex
        repeat {
            let remainder = self[remaining]
            guard let idx = remainder.index(of: bytes[0]) else { return nil }
            if idx + bytes.count - 1 < remainder.endIndex {
                if (1..<bytes.count).reduce(true, combine: { (t, jj) -> Bool in
                    return t && (bytes[jj] == remainder[idx + jj])
                }) {
                    let start = idx
                    let end = idx + bytes.count
                    return start..<end
                }
            }
            let offset = idx.successor()
            remaining = offset..<endIndex
        } while remaining.startIndex < remaining.endIndex
        return nil
    }
    /// Generator of lines in to the given function.
    ///
    /// The trailing CRLF is stripped from these already.
    func generateHTTPLines() -> AnyIterator<ByteCollection> {
        var remainder = self
        return AnyIterator() {
            guard !remainder.isEmpty else { return nil }
            guard let range = remainder.range(of: CRLF) else { return nil }
            let line = remainder[remainder.startIndex..<range.startIndex]
            remainder = remainder[range.endIndex..<remainder.endIndex]
            return line
        }
    }
}

extension HTTPMessageType {
    /// Expected length of the message-body as it appears in the message.
    ///
    /// This returns the length that the message body should have according
    /// to the message type and the headers available in the message.
    ///
    /// - SeeAlso: https://tools.ietf.org/html/rfc2616#section-4.4
    var transferLength: Int? {
        if let transferEncoding = headerField(withName: "Transfer-Encoding") where transferEncoding != "identity" {
            //   2.If a Transfer-Encoding header field (section 14.41) is present and
            //     has any value other than "identity", then the transfer-length is
            //     defined by use of the "chunked" transfer-coding (section 3.6),
            //     unless the message is terminated by closing the connection.
            
            // TODO
            return nil
        } else if let contentLength = headerField(withName: "Content-Length").flatMap({Int($0)}) {
            //   3.If a Content-Length header field (section 14.13) is present, its
            //     decimal value in OCTETs represents both the entity-length and the
            //     transfer-length. The Content-Length header field MUST NOT be sent
            //     if these two lengths are different (i.e., if a Transfer-Encoding
            //     header field is present). If a message is received with both a
            //     Transfer-Encoding header field and a Content-Length header field,
            //     the latter MUST be ignored.
            return contentLength
        }
        return 0
    }
}


//
//MARK: - Errors -
//



private struct ServerError : ErrorProtocol {
    let operation: String
    let errno: CInt
    let file: String
    let line: UInt
    var _code: Int { return Int(errno) }
    var _domain: String { return NSPOSIXErrorDomain }
}


extension ServerError : CustomStringConvertible {
    var description: String {
        let s = String(validatingUTF8: strerror(errno)) ?? ""
        return "\(operation) failed: \(s) (\(_code))"
    }
}

/// Turn a C library function into something that throws on error.
///
/// The 1st closure must return `true` if the result is an error.
/// The 2nd closure is the operation to be performed.
private func attempt(_ name: String, file: String = #file, line: UInt = #line, @noescape valid: (CInt) -> Bool, @autoclosure _ b: () -> CInt) throws -> CInt {
    let r = b()
    guard valid(r) else {
        throw ServerError(operation: name, errno: r, file: file, line: line)
    }
    return r
}

private func isNotNegative1(r: CInt) -> Bool {
    return r != -1
}
private func is0(r: CInt) -> Bool {
    return r != -1
}

private func ignoreAndLogErrors(@noescape b: () throws -> ()) {
    do {
        try b()
    } catch let e {
        print("error: \(e)")
    }
}



//
//MARK: - Socket -
//


struct TCPSocket {
    enum Domain {
        case Inet
        case Inet6
    }
    private let domain: Domain
    private let backingSocket: CInt
    init(domain d: Domain) throws {
        domain = d
        backingSocket = try attempt("socket(2)",  valid: isNotNegative1, socket(d.rawValue, SOCK_STREAM, IPPROTO_TCP))
    }
}

extension TCPSocket {
    /// Close the socket.
    func close() throws {
        try attempt("close(2)", valid: is0, Darwin.close(backingSocket))
    }
    /// Listen for connections.
    /// Start accepting incoming connections and set the queue limit for incoming connections.
    func listen(backlog: CInt = SOMAXCONN) throws {
        try attempt("listen(2)", valid: is0, Darwin.listen(backingSocket, backlog))
    }
}

extension TCPSocket {
    /// Accept a connection.
    /// Retruns the resulting client socket.
    func accept() throws -> ClientSocket {
        // The address has the type `sockaddr`, but could have more data than `sizeof(sockaddr)`. Hence we put it inside an NSData instance.
        let addressData = NSMutableData(length: Int(SOCK_MAXADDRLEN))!
        let p = UnsafeMutablePointer<sockaddr>(addressData.bytes)
        var length = socklen_t(sizeof(sockaddr_in))
        let socket = try attempt("accept(2)", valid: isNotNegative1, Darwin.accept(backingSocket, p, &length))
        addressData.length = Int(length)
        let address = SocketAddress(addressData: addressData)
        return ClientSocket(address: address, backingSocket: socket)
    }
}

extension TCPSocket {
    struct StatusFlag : OptionSet {
        let rawValue: CInt
        static let O_NONBLOCK = StatusFlag(rawValue: 0x0004)
        static let O_APPEND = StatusFlag(rawValue: 0x0008)
        static let O_ASYNC = StatusFlag(rawValue: 0x0040)
    }
    /// Set the socket status flags.
    /// Uses `fnctl(2)` with `F_SETFL`.
    func set(statusFlags flag: StatusFlag) throws {
        try attempt("fcntl(2)", valid: isNotNegative1, fcntl(backingSocket, F_SETFL, flag.rawValue))
    }
    /// Get the socket status flags.
    /// Uses `fnctl(2)` with `F_GETFL`.
    func get(statusFlags flag: StatusFlag) -> StatusFlag {
        return StatusFlag(rawValue: fcntl(backingSocket, F_GETFL)) ?? StatusFlag()
    }
}

extension TCPSocket {
    func createDispatchReadSource(with queue: dispatch_queue_t) -> dispatch_source_t {
        return dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, UInt(backingSocket), 0, queue)
    }
}

//extension TCPSocket.StatusFlag {
//    init?(rawValue: Self.RawValue) {
//        switch
//    }
//}


extension TCPSocket.Domain {
    private var rawValue: CInt {
        switch self {
        case .Inet: return PF_INET
        case .Inet6: return PF_INET6
        }
    }
    private var addressFamily: sa_family_t {
        switch self {
        case .Inet: return sa_family_t(AF_INET)
        case .Inet6: return sa_family_t(AF_INET6)
        }
    }
}


private let INADDR_ANY = in_addr(s_addr: in_addr_t(0))

extension TCPSocket {
    private func withUnsafeAnySockAddr(port: UInt16, @noescape block: (UnsafePointer<sockaddr>) throws -> ()) rethrows {
        let portN = in_port_t(port.bigEndian)
        let addr = UnsafeMutablePointer<sockaddr_in>(allocatingCapacity: 1)
        addr.initialize(with: sockaddr_in(sin_len: 0, sin_family: domain.addressFamily, sin_port: portN, sin_addr: INADDR_ANY, sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)))
        defer { addr.deinitialize(count: 1) }
        try block(UnsafePointer<sockaddr>(addr))
    }
    func bindToPort(_ port: UInt16) throws {
        try withUnsafeAnySockAddr(port: port) { addr in
            try attempt("bind(2)", valid: is0, bind(backingSocket, addr, socklen_t(sizeof(sockaddr))))
        }
    }
}

public struct SocketAddress {
    /// Wraps a `sockaddr`, but could have more data than `sizeof(sockaddr)`
    let addressData: NSData
}

/// A socket that connects to a client, i.e. a program that connected to us.
struct ClientSocket {
    let address: SocketAddress
    private let backingSocket: CInt
    init(address: SocketAddress, backingSocket: CInt) {
        self.address = address
        self.backingSocket = backingSocket
    }
}

extension ClientSocket {
    /// Creates a dispatch I/O channel associated with the socket.
    func createIOChannel(with queue: dispatch_queue_t) -> dispatch_io_t {
        let fd = backingSocket
        return dispatch_io_create(DISPATCH_IO_STREAM, fd, queue) {
            error in
            if let e = POSIXError(rawValue: error) {
                print("Error on socket: \(e)")
            }
            let closeError = close(fd)
            if closeError != 0 {
                print("Error closing socket (\(closeError)).")
            }
        }
    }
}

extension SocketAddress : CustomStringConvertible {
    public var description: String {
        if let addr = inAddrDescription, let port = inPortDescription {
            switch inFamily {
            case sa_family_t(AF_INET6):
                return "[" + addr + "]:" + port
            case sa_family_t(AF_INET):
                return addr + ":" + port
            default:
                break
            }
        }
        return "<unknown>"
    }
}

extension SocketAddress {
    static let offsetOf__sin_addr__in__sockaddr_in = 4
    
    private var inFamily: sa_family_t {
        let pointer = UnsafePointer<sockaddr_in>(addressData.bytes)
        return pointer.pointee.sin_family
    }
    private var inAddrDescription: String? {
        let pointer = UnsafePointer<sockaddr_in>(addressData.bytes)
        switch inFamily {
        case sa_family_t(AF_INET6):
            fallthrough
        case sa_family_t(AF_INET):
            let data = NSMutableData(length: Int(INET6_ADDRSTRLEN))!
            let inAddr = (UnsafePointer<UInt8>(pointer) + SocketAddress.offsetOf__sin_addr__in__sockaddr_in)
            if inet_ntop(AF_INET, inAddr, UnsafeMutablePointer<Int8>(data.mutableBytes), socklen_t(data.length)) != nil {
                return String(data: data, encoding: NSUTF8StringEncoding)!
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    private var inPortDescription: String? {
        let pointer = UnsafePointer<sockaddr_in>(addressData.bytes)
        switch inFamily {
        case sa_family_t(AF_INET6):
            fallthrough
        case sa_family_t(AF_INET):
            let p = UInt16(bigEndian: UInt16(pointer.pointee.sin_port))
            return "\(p)"
        default:
            return nil
        }
    }
}



//
//MARK: - Byte Collection -
//

/// Array like access to bytes inside `dispatch_data_t`.
///
/// Note that indexes are opaque. An index into a slice and the collection it
/// has been created from will be equal. Same goes for range. As a result it
/// is valid to index into a slice given an index found on the original
/// collection and vice-versa.
///
/// Creating slices (i.e. subscript with a range) is performant and O(1) since
/// it simply references the same the unlerlying `dispatch_data_t` with adjusted
/// `startIndex` and `endIndex` values.
///
/// Dispatch data is not necessarily backed by a single contiguous memory
/// region. Hence this wrapper.
private struct ByteCollection : Collection {
    private let data: dispatch_data_t
    let startIndex: Index
    let endIndex: Index
    init(data: dispatch_data_t) {
        self.data = data
        self.startIndex = Index(rawValue: 0)
        self.endIndex = Index(rawValue: dispatch_data_get_size(data))
    }
    /// This is not particularly efficient when the data consists of multiple
    /// regions, but probably still better than lots of memory copies.
    /// As long as the numbmer of regions is small, performance is reasonable.
    subscript (position: Index) -> UInt8 {
        let p = position
        guard 0 <= p.rawValue && p.rawValue < dispatch_data_get_size(data) else { fatalError() }
        var result = UInt8()
        dispatch_data_apply(data) { (_, offset, buffer, bufferLength) -> Bool in
            if p.rawValue < offset + bufferLength {
                let typedBuffer = UnsafePointer<UInt8>(buffer)!
                result = typedBuffer[p.rawValue - offset]
                return false
            }
            return true
        }
        return result
    }
    subscript (bounds: Range<Index>) -> ByteCollection {
        return ByteCollection(byteCollection: self, startIndex: bounds.startIndex, endIndex: bounds.endIndex)
    }
    var isEmpty: Bool { return count == 0 }
    var count: Int { return startIndex.distance(to: endIndex) }
    var first: UInt8? { return (count == 0) ? nil : self[startIndex] }
    func underestimateCount() -> Int { return count }
    /// Opaque index into a `ByteCollection`.
    struct Index {
        private let rawValue: Int
    }
}

extension ByteCollection : CustomDebugStringConvertible {
    var debugDescription: String {
        return "ByteCollection { data = \(data), start = \(startIndex.rawValue), end = \(startIndex.rawValue), count = \(count)}"
    }
    var description: String {
        return "ByteCollection { data = \(data), start = \(startIndex.rawValue), end = \(startIndex.rawValue), count = \(count)}"
    }
}

extension ByteCollection {
    private init(byteCollection: ByteCollection, startIndex: Index, endIndex: Index) {
        self.data = byteCollection.data
        self.startIndex = startIndex
        self.endIndex = endIndex
        guard 0 <= self.startIndex.rawValue && self.startIndex.rawValue <= dispatch_data_get_size(data) else { fatalError() }
        guard 0 <= self.endIndex.rawValue && self.endIndex.rawValue <= dispatch_data_get_size(data) else { fatalError() }
        guard self.startIndex <= self.endIndex else { fatalError() }
    }
}

extension ByteCollection.Index : Comparable {}
@warn_unused_result
private func ==(lhs: ByteCollection.Index, rhs: ByteCollection.Index) -> Bool {
    return lhs.rawValue == rhs.rawValue
}
@warn_unused_result
private func <(lhs: ByteCollection.Index, rhs: ByteCollection.Index) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
@warn_unused_result
private func <=(lhs: ByteCollection.Index, rhs: ByteCollection.Index) -> Bool {
    return lhs.rawValue <= rhs.rawValue
}
@warn_unused_result
private func >=(lhs: ByteCollection.Index, rhs: ByteCollection.Index) -> Bool {
    return lhs.rawValue >= rhs.rawValue
}
@warn_unused_result
private func >(lhs: ByteCollection.Index, rhs: ByteCollection.Index) -> Bool {
    return lhs.rawValue > rhs.rawValue
}

extension ByteCollection.Index : RandomAccessIndex {
    @warn_unused_result
    func successor() -> ByteCollection.Index {
        return advanced(by: 1)
    }
    @warn_unused_result
    func predecessor() -> ByteCollection.Index {
        return ByteCollection.Index(rawValue: rawValue - 1)
    }
    @warn_unused_result
    func advanced(by n: Int) -> ByteCollection.Index {
        return ByteCollection.Index(rawValue: rawValue + n)
    }
    @warn_unused_result
    func advanced(by n: Int, limit: ByteCollection.Index) -> ByteCollection.Index {
        //TODO: The documentation is a bit vague on how this is to be implemented
        // when self is already past the limit.
        if 0 < n && self.rawValue <= limit.rawValue  {
            return ByteCollection.Index(rawValue: min(self.rawValue + n, limit.rawValue))
        } else if n < 0 && limit.rawValue <= self.rawValue  {
            return ByteCollection.Index(rawValue: max(self.rawValue + n, limit.rawValue))
        }
        return ByteCollection.Index(rawValue: self.rawValue + n)
    }
    @warn_unused_result
    func distance(to other: ByteCollection.Index) -> Int {
        return other.rawValue - self.rawValue
    }
}
