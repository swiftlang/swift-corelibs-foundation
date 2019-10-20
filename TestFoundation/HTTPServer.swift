// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


//This is a very rudimentary HTTP server written plainly for testing URLSession. 
//It is not concurrent. It listens on a port, reads once and writes back only once.
//We can make it better everytime we need more functionality to test different aspects of URLSession.

import Dispatch

#if canImport(MSVCRT)
    import MSVCRT
    import WinSDK
#elseif canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

#if !os(Windows)
typealias SOCKET = Int32
#endif


public let globalDispatchQueue = DispatchQueue.global()
public let dispatchQueueMake: (String) -> DispatchQueue = { DispatchQueue.init(label: $0) }
public let dispatchGroupMake: () -> DispatchGroup = DispatchGroup.init

struct _HTTPUtils {
    static let CRLF = "\r\n"
    static let VERSION = "HTTP/1.1"
    static let SPACE = " "
    static let CRLF2 = CRLF + CRLF
    static let EMPTY = ""
}

extension UInt16 {
    public init(networkByteOrder input: UInt16) {
        self.init(bigEndian: input)
    }
}

class _TCPSocket {
#if !os(Windows)
    private let sendFlags: CInt
#endif
    private var listenSocket: SOCKET!
    private var socketAddress = UnsafeMutablePointer<sockaddr_in>.allocate(capacity: 1)
    private var _connectionSocketLock = NSLock()
    private var _connectionSocket: SOCKET?
    private var connectionSocket: SOCKET? {
        get { _connectionSocketLock.synchronized { _connectionSocket } }
        set { _connectionSocketLock.synchronized { _connectionSocket = newValue } }
    }
    
    private func isNotNegative(r: CInt) -> Bool {
        return r != -1
    }

    private func isZero(r: CInt) -> Bool {
        return r == 0
    }

    private func attempt<T>(_ name: String, file: String = #file, line: UInt = #line, valid: (T) -> Bool,  _ b: @autoclosure () -> T) throws -> T {
        let r = b()
        guard valid(r) else {
            throw ServerError(operation: name, errno: errno, file: file, line: line)
        }
        return r
    }

    public private(set) var port: UInt16

    init(port: UInt16?) throws {
#if !os(Windows)
#if os(Linux) || os(Android) || os(FreeBSD)
        sendFlags = CInt(MSG_NOSIGNAL)
#else
        sendFlags = 0
#endif
#endif

        self.port = port ?? 0

#if os(Windows)
        listenSocket = try attempt("WSASocketW", valid: { $0 != INVALID_SOCKET }, WSASocketW(AF_INET, SOCK_STREAM, IPPROTO_TCP.rawValue, nil, 0, DWORD(WSA_FLAG_OVERLAPPED)))

        var value: Int8 = 1
        _ = try attempt("setsockopt", valid: { $0 == 0 }, setsockopt(listenSocket, SOL_SOCKET, SO_REUSEADDR, &value, Int32(MemoryLayout.size(ofValue: value))))
#else
#if os(Linux) && !os(Android)
        let SOCKSTREAM = Int32(SOCK_STREAM.rawValue)
#else
        let SOCKSTREAM = SOCK_STREAM
#endif
        listenSocket = try attempt("socket", valid: { $0 >= 0 }, socket(AF_INET, SOCKSTREAM, Int32(IPPROTO_TCP)))
        var on: CInt = 1
        _ = try attempt("setsockopt", valid: { $0 == 0 }, setsockopt(listenSocket, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<CInt>.size)))
#endif

        let sa = createSockaddr(port)
        socketAddress.initialize(to: sa)
        try socketAddress.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size, { 
            let addr = UnsafePointer<sockaddr>($0)
            _ = try attempt("bind", valid: isZero, bind(listenSocket, addr, socklen_t(MemoryLayout<sockaddr>.size)))
            _ = try attempt("listen", valid: isZero, listen(listenSocket, SOMAXCONN))
        })

        var actualSA = sockaddr_in()
        withUnsafeMutablePointer(to: &actualSA) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { (ptr: UnsafeMutablePointer<sockaddr>) in
                var len = socklen_t(MemoryLayout<sockaddr>.size)
                getsockname(listenSocket, ptr, &len)
            }
        }

        self.port = UInt16(networkByteOrder: actualSA.sin_port)
    }

    private func createSockaddr(_ port: UInt16?) -> sockaddr_in {
        // Listen on the loopback address so that OSX doesnt pop up a dialog
        // asking to accept incoming connections if the firewall is enabled.
        let addr = UInt32(INADDR_LOOPBACK).bigEndian
        let netPort = UInt16(bigEndian: port ?? 0)
        #if os(Android)
            return sockaddr_in(sin_family: sa_family_t(AF_INET), sin_port: netPort, sin_addr: in_addr(s_addr: addr), __pad: (0,0,0,0,0,0,0,0))
        #elseif os(Linux)
            return sockaddr_in(sin_family: sa_family_t(AF_INET), sin_port: netPort, sin_addr: in_addr(s_addr: addr), sin_zero: (0,0,0,0,0,0,0,0))
        #elseif os(Windows)
            return sockaddr_in(sin_family: ADDRESS_FAMILY(AF_INET), sin_port: USHORT(netPort), sin_addr: IN_ADDR(S_un: in_addr.__Unnamed_union_S_un(S_addr: addr)), sin_zero: (CHAR(0), CHAR(0), CHAR(0), CHAR(0), CHAR(0), CHAR(0), CHAR(0), CHAR(0)))
        #else
            return sockaddr_in(sin_len: 0, sin_family: sa_family_t(AF_INET), sin_port: netPort, sin_addr: in_addr(s_addr: addr), sin_zero: (0,0,0,0,0,0,0,0))
        #endif
    }

    func acceptConnection(notify: ServerSemaphore) throws {
        try socketAddress.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size, {
            let addr = UnsafeMutablePointer<sockaddr>($0)
            var sockLen = socklen_t(MemoryLayout<sockaddr>.size) 
#if os(Windows)
            connectionSocket = try attempt("WSAAccept", valid: { $0 != INVALID_SOCKET }, WSAAccept(listenSocket, addr, &sockLen, nil, 0))
#else
            connectionSocket = try attempt("accept", valid: { $0 >= 0 }, accept(listenSocket, addr, &sockLen))
#endif
#if canImport(Darwin)
            // Disable SIGPIPEs when writing to closed sockets
            var on: CInt = 1
            if let connectionSocket = connectionSocket {
                _ = try attempt("setsockopt", valid: isZero, setsockopt(connectionSocket, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<CInt>.size)))
            }
#endif
        })
    }
 
    func readData() throws -> String {
        guard let connectionSocket = connectionSocket else {
            throw InternalServerError.socketAlreadyClosed
        }

        var buffer = [CChar](repeating: 0, count: 4096)
#if os(Windows)
        var dwNumberOfBytesRecieved: DWORD = 0;
        try buffer.withUnsafeMutableBufferPointer {
            var wsaBuffer: WSABUF = WSABUF(len: ULONG($0.count), buf: $0.baseAddress)
            var flags: DWORD = 0
            _ = try attempt("WSARecv", valid: { $0 != SOCKET_ERROR }, WSARecv(connectionSocket, &wsaBuffer, 1, &dwNumberOfBytesRecieved, &flags, nil, nil))
        }
#else
        _ = try attempt("read", valid: { $0 >= 0 }, read(connectionSocket, &buffer, buffer.count))
#endif
        return String(cString: &buffer)
    }

    func writeRawData(_ data: Data) throws {
        guard let connectionSocket = connectionSocket else {
            throw InternalServerError.socketAlreadyClosed
        }

#if os(Windows)
        _ = try data.withUnsafeBytes {
            var dwNumberOfBytesSent: DWORD = 0
            var wsaBuffer: WSABUF = WSABUF(len: ULONG(data.count), buf: UnsafeMutablePointer<CHAR>(mutating: $0.bindMemory(to: CHAR.self).baseAddress))
            _ = try attempt("WSASend", valid: { $0 != SOCKET_ERROR }, WSASend(connectionSocket, &wsaBuffer, 1, &dwNumberOfBytesSent, 0, nil, nil))
        }
#else
        _ = try data.withUnsafeBytes { ptr in
            try attempt("send", valid: isNotNegative, CInt(send(connectionSocket, ptr.baseAddress!, data.count, sendFlags)))
        }
#endif
    }

    private func _send(_ bytes: [UInt8]) throws -> Int {
        guard let connectionSocket = connectionSocket else {
            throw InternalServerError.socketAlreadyClosed
        }

#if os(Windows)
        return try bytes.withUnsafeBytes {
            var dwNumberOfBytesSent: DWORD = 0
            var wsaBuffer: WSABUF = WSABUF(len: ULONG(bytes.count), buf: UnsafeMutablePointer<CHAR>(mutating: $0.bindMemory(to: CHAR.self).baseAddress))
            return try Int(attempt("WSASend", valid: { $0 != SOCKET_ERROR }, WSASend(connectionSocket, &wsaBuffer, 1, &dwNumberOfBytesSent, 0, nil, nil)))
        }
#else
        return try bytes.withUnsafeBufferPointer {
            try attempt("send", valid: { $0 >= 0 }, send(connectionSocket, $0.baseAddress, $0.count, sendFlags))
        }
#endif
    }

    func writeData(header: String, bodyData: Data, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
        _ = try _send(Array(header.utf8))

        if let sendDelay = sendDelay, let bodyChunks = bodyChunks {
            let count = max(1, Int(Double(bodyData.count) / Double(bodyChunks)))
            for startIndex in stride(from: 0, to: bodyData.count, by: count) {
                Thread.sleep(forTimeInterval: sendDelay)
                let endIndex = min(startIndex + count, bodyData.count)
                try bodyData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Void in
                    let chunk = UnsafeRawBufferPointer(rebasing: ptr[startIndex..<endIndex])
                    _ = try _send(Array(chunk.bindMemory(to: UInt8.self)))
                }
            }
        } else {
            try bodyData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> Void in
                _ = try _send(Array(ptr.bindMemory(to: UInt8.self)))
            }
        }
    }

    func closeClient() {
        _connectionSocketLock.synchronized {
            if let connectionSocket = _connectionSocket {
#if os(Windows)
                closesocket(connectionSocket)
#else
                close(connectionSocket)
#endif
                _connectionSocket = nil
            }
        }
    }

    func shutdownListener() {
        closeClient()
#if os(Windows)
        shutdown(listenSocket, SD_BOTH)
        closesocket(listenSocket)
#else
        shutdown(listenSocket, CInt(SHUT_RDWR))
        close(listenSocket)
#endif
    }
}

class _HTTPServer {

    let socket: _TCPSocket
    var willReadAgain = false
    var port: UInt16 {
        get {
            return self.socket.port
        }
    }
    
    init(port: UInt16?) throws {
        socket = try _TCPSocket(port: port)
    }

    public class func create(port: UInt16?) throws -> _HTTPServer {
        return try _HTTPServer(port: port)
    }

    public func listen(notify: ServerSemaphore) throws {
        try socket.acceptConnection(notify: notify)
    }

    public func stop() {
        if !willReadAgain {
            socket.closeClient()
            socket.shutdownListener()
	}
    }
   
    public func request() throws -> _HTTPRequest {
        var request = try _HTTPRequest(request: socket.readData())
       
        if Int(request.getHeader(for: "Content-Length") ?? "0") ?? 0 > 0
            || (request.getHeader(for: "Transfer-Encoding") ?? "").lowercased() == "chunked" {
            
            // According to RFC7230 https://tools.ietf.org/html/rfc7230#section-3
            // We receive messageBody after the headers, so we need read from socket minimum 2 times
            //
            // HTTP-message structure
            //
            // start-line
            // *( header-field CRLF )
            // CRLF
            // [ message-body ]
            // We receives '{numofbytes}\r\n{data}\r\n'
            // TODO read data until the end
            
            let substr = try socket.readData().split(separator: "\r\n")
            if substr.count >= 2 {
                request.messageBody = String(substr[1])
            }
        }
        
        return request
    }

    public func respond(with response: _HTTPResponse, startDelay: TimeInterval? = nil, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
        if let delay = startDelay {
            Thread.sleep(forTimeInterval: delay)
        }
        do {
            try self.socket.writeData(header: response.header, bodyData: response.bodyData, sendDelay: sendDelay, bodyChunks: bodyChunks)
        } catch {
        }
    }

    func respondWithBrokenResponses(uri: String) throws {
        let responseData: Data
        switch uri {
            case "/LandOfTheLostCities/Pompeii":
                /* this is an example of what you get if you connect to an HTTP2
                 server using HTTP/1.1. Curl interprets that as a HTTP/0.9
                 simple-response and therefore sends this back as a response
                 body. Go figure! */
                responseData = Data([
                    0x00, 0x00, 0x18, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x01, 0x00, 0x00, 0x10, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00,
                    0x01, 0x00, 0x05, 0x00, 0x00, 0x40, 0x00, 0x00, 0x06, 0x00,
                    0x00, 0x1f, 0x40, 0x00, 0x00, 0x86, 0x07, 0x00, 0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01,
                    0x48, 0x54, 0x54, 0x50, 0x2f, 0x32, 0x20, 0x63, 0x6c, 0x69,
                    0x65, 0x6e, 0x74, 0x20, 0x70, 0x72, 0x65, 0x66, 0x61, 0x63,
                    0x65, 0x20, 0x73, 0x74, 0x72, 0x69, 0x6e, 0x67, 0x20, 0x6d,
                    0x69, 0x73, 0x73, 0x69, 0x6e, 0x67, 0x20, 0x6f, 0x72, 0x20,
                    0x63, 0x6f, 0x72, 0x72, 0x75, 0x70, 0x74, 0x2e, 0x20, 0x48,
                    0x65, 0x78, 0x20, 0x64, 0x75, 0x6d, 0x70, 0x20, 0x66, 0x6f,
                    0x72, 0x20, 0x72, 0x65, 0x63, 0x65, 0x69, 0x76, 0x65, 0x64,
                    0x20, 0x62, 0x79, 0x74, 0x65, 0x73, 0x3a, 0x20, 0x34, 0x37,
                    0x34, 0x35, 0x35, 0x34, 0x32, 0x30, 0x32, 0x66, 0x33, 0x33,
                    0x32, 0x66, 0x36, 0x34, 0x36, 0x35, 0x37, 0x36, 0x36, 0x39,
                    0x36, 0x33, 0x36, 0x35, 0x32, 0x66, 0x33, 0x31, 0x33, 0x32,
                    0x33, 0x33, 0x33, 0x34, 0x33, 0x35, 0x33, 0x36, 0x33, 0x37,
                    0x33, 0x38, 0x33, 0x39, 0x33, 0x30])
            case "/LandOfTheLostCities/Sodom":
                /* a technically valid HTTP/0.9 simple-response */
                responseData = ("technically, this is a valid HTTP/0.9 " +
                    "simple-response. I know it's odd but CURL supports it " +
                    "still...\r\nFind out more in those URLs:\r\n " +
                    " - https://www.w3.org/Protocols/HTTP/1.0/spec.html#Message-Types\r\n" +
                    " - https://github.com/curl/curl/issues/467\r\n").data(using: .utf8)!
            case "/LandOfTheLostCities/Gomorrah":
                /* just broken, hope that's not officially HTTP/0.9 :p */
                responseData = "HTTP/1.1\r\n\r\n\r\n".data(using: .utf8)!
            case "/LandOfTheLostCities/Myndus":
                responseData = ("HTTP/1.1 200 OK\r\n" +
                               "\r\n" +
                               "this is a body that isn't legal as it's " +
                               "neither chunked encoding nor any Content-Length\r\n").data(using: .utf8)!
            case "/LandOfTheLostCities/Kameiros":
                responseData = ("HTTP/1.1 999 Wrong Code\r\n" +
                               "illegal: status code (too large)\r\n" +
                               "\r\n").data(using: .utf8)!
            case "/LandOfTheLostCities/Dinavar":
                responseData = ("HTTP/1.1 20 Too Few Digits\r\n" +
                               "illegal: status code (too few digits)\r\n" +
                               "\r\n").data(using: .utf8)!
            case "/LandOfTheLostCities/Kuhikugu":
                responseData = ("HTTP/1.1 2000 Too Many Digits\r\n" +
                               "illegal: status code (too many digits)\r\n" +
                               "\r\n").data(using: .utf8)!
            default:
                responseData = ("HTTP/1.1 500 Internal Server Error\r\n" +
                               "case-missing-in: TestFoundation/HTTPServer.swift\r\n" +
                               "\r\n").data(using: .utf8)!
        }
        try self.socket.writeRawData(responseData)
    }

    func respondWithAuthResponse(uri: String, firstRead: Bool) throws {
        let responseData: Data
        if firstRead {
            responseData = ("HTTP/1.1 401 UNAUTHORIZED \r\n" +
                        "Content-Length: 0\r\n" +
                        "WWW-Authenticate: Basic realm=\"Fake Relam\"\r\n" +
                        "Access-Control-Allow-Origin: *\r\n" +
                        "Access-Control-Allow-Credentials: true\r\n" +
                        "Via: 1.1 vegur\r\n" +
                        "Cache-Control: proxy-revalidate\r\n" +
                        "Connection: keep-Alive\r\n" +
                        "\r\n").data(using: .utf8)!
        } else {
            responseData = ("HTTP/1.1 200 OK \r\n" +
                "Content-Length: 37\r\n" +
                "Content-Type: application/json\r\n" +
                "Access-Control-Allow-Origin: *\r\n" +
                "Access-Control-Allow-Credentials: true\r\n" +
                "Via: 1.1 vegur\r\n" +
                "Cache-Control: proxy-revalidate\r\n" +
                "Connection: keep-Alive\r\n" +
                "\r\n" +
                "{\"authenticated\":true,\"user\":\"user\"}\n").data(using: .utf8)!
        }
        try self.socket.writeRawData(responseData)
    }

    func respondWithUnauthorizedHeader() throws{
        let responseData = ("HTTP/1.1 401 UNAUTHORIZED \r\n" +
                "Content-Length: 0\r\n" +
                "Connection: keep-Alive\r\n" +
                "\r\n").data(using: .utf8)!
        try self.socket.writeRawData(responseData)
    }
}

struct _HTTPRequest {
    enum Method : String {
        case GET
        case POST
        case PUT
    }
    let method: Method
    let uri: String 
    let body: String
    var messageBody: String?
    let headers: [String]

    enum Error: Swift.Error {
        case headerEndNotFound
    }
    
    public init(request: String) throws {
        let headerEnd = (request as NSString).range(of: _HTTPUtils.CRLF2)
        guard headerEnd.location != NSNotFound else { throw Error.headerEndNotFound }
        let header = (request as NSString).substring(to: headerEnd.location)
        headers = header.components(separatedBy: _HTTPUtils.CRLF)
        let action = headers[0]
        method = Method(rawValue: action.components(separatedBy: " ")[0])!
        uri = action.components(separatedBy: " ")[1]
        body = (request as NSString).substring(from: headerEnd.location + headerEnd.length)
    }

    public func getCommaSeparatedHeaders() -> String {
        var allHeaders = ""
        for header in headers {
            allHeaders += header + ","
        }
        return allHeaders
    }

    public func getHeader(for key: String) -> String? {
        let lookup = key.lowercased()
        for header in headers {
            let parts = header.components(separatedBy: ":")
            if parts[0].lowercased() == lookup {
                return parts[1].trimmingCharacters(in: CharacterSet(charactersIn: " "))
            }
        }
        return nil
    }
}

struct _HTTPResponse {
    enum Response : Int {
        case OK = 200
        case REDIRECT = 302
        case NOTFOUND = 404
    }
    private let responseCode: Response
    private let headers: String
    public let bodyData: Data

    public init(response: Response, headers: String = _HTTPUtils.EMPTY, bodyData: Data) {
        self.responseCode = response
        self.headers = headers
        self.bodyData = bodyData
    }

    public init(response: Response, headers: String = _HTTPUtils.EMPTY, body: String) {
        self.init(response: response, headers: headers, bodyData: body.data(using: .utf8)!)
    }

    public var header: String {
        let statusLine = _HTTPUtils.VERSION + _HTTPUtils.SPACE + "\(responseCode.rawValue)" + _HTTPUtils.SPACE + "\(responseCode)"
        return statusLine + (headers != _HTTPUtils.EMPTY ? _HTTPUtils.CRLF + headers : _HTTPUtils.EMPTY) + _HTTPUtils.CRLF2
    }
}

public class TestURLSessionServer {
    let capitals: [String:String] = ["Nepal": "Kathmandu",
                                     "Peru": "Lima",
                                     "Italy": "Rome",
                                     "USA": "Washington, D.C.",
                                     "UnitedStates": "USA",
                                     "UnitedKingdom": "UK",
                                     "UK": "London",
                                     "country.txt": "A country is a region that is identified as a distinct national entity in political geography"]
    let httpServer: _HTTPServer
    let startDelay: TimeInterval?
    let sendDelay: TimeInterval?
    let bodyChunks: Int?
    var port: UInt16 {
        get {
            return self.httpServer.port
        }
    }
    
    public init (port: UInt16?, startDelay: TimeInterval? = nil, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
        httpServer = try _HTTPServer.create(port: port)
        self.startDelay = startDelay
        self.sendDelay = sendDelay
        self.bodyChunks = bodyChunks
    }

    public func readAndRespond() throws {
        let req = try httpServer.request()

        if let value = req.getHeader(for: "x-pause") {
            if let wait = Double(value), wait > 0 {
                Thread.sleep(forTimeInterval: wait)
            }
        }

        if req.uri.hasPrefix("/LandOfTheLostCities/") {
            /* these are all misbehaving servers */
            try httpServer.respondWithBrokenResponses(uri: req.uri)
        } else if req.uri == "/NSString-ISO-8859-1-data.txt" {
            // Serve this directly as binary data to avoid any String encoding conversions.
            if let url = testBundle().url(forResource: "NSString-ISO-8859-1-data", withExtension: "txt"),
                let content = try? Data(contentsOf: url) {
                var responseData = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=ISO-8859-1\r\nContent-Length: \(content.count)\r\n\r\n".data(using: .ascii)!
                responseData.append(content)
                try httpServer.socket.writeRawData(responseData)
            } else {
                try httpServer.respond(with: _HTTPResponse(response: .NOTFOUND, body: "Not Found"))
            }
        } else if req.uri.hasPrefix("/auth") {
            httpServer.willReadAgain = true
            try httpServer.respondWithAuthResponse(uri: req.uri, firstRead: true)
        } else if req.uri.hasPrefix("/unauthorized") {
            try httpServer.respondWithUnauthorizedHeader()
        } else {
            try httpServer.respond(with: process(request: req), startDelay: self.startDelay, sendDelay: self.sendDelay, bodyChunks: self.bodyChunks)
        }
    }

    public func readAndRespondAgain() throws {
        let req = try httpServer.request()
        if req.uri.hasPrefix("/auth/") {
            try httpServer.respondWithAuthResponse(uri: req.uri, firstRead: false)
        }
        httpServer.willReadAgain = false
    }

    func process(request: _HTTPRequest) -> _HTTPResponse {
        if request.method == .GET || request.method == .POST || request.method == .PUT {
            return getResponse(request: request)
        } else {
            fatalError("Unsupported method!")
        }
    }

    func getResponse(request: _HTTPRequest) -> _HTTPResponse {
        let uri = request.uri

        if uri == "/upload" {
            let text = "Upload completed!"
            return _HTTPResponse(response: .OK, headers: "Content-Length: \(text.data(using: .utf8)!.count)", body: text)
        }

        if uri == "/country.txt" {
            let text = capitals[String(uri.dropFirst())]!
            return _HTTPResponse(response: .OK, headers: "Content-Length: \(text.data(using: .utf8)!.count)", body: text)
        }

        if uri == "/requestHeaders" {
            let text = request.getCommaSeparatedHeaders()
            return _HTTPResponse(response: .OK, headers: "Content-Length: \(text.data(using: .utf8)!.count)", body: text)
        }

        if uri == "/emptyPost" {
            if request.body.count == 0 && request.getHeader(for: "Content-Type") == nil {
                return _HTTPResponse(response: .OK, body: "")
            }
            return _HTTPResponse(response: .NOTFOUND, body: "")
        }

        if uri == "/requestCookies" {
            return _HTTPResponse(response: .OK, headers: "Set-Cookie: fr=anjd&232; Max-Age=7776000; path=/\r\nSet-Cookie: nm=sddf&232; Max-Age=7776000; path=/; domain=.swift.org; secure; httponly\r\n", body: "")
        }

        if uri == "/echoHeaders" {
            let text = request.getCommaSeparatedHeaders()
            return _HTTPResponse(response: .OK, headers: "Content-Length: \(text.data(using: .utf8)!.count)", body: text)
        }
        
        if uri == "/redirectToEchoHeaders" {
            return _HTTPResponse(response: .REDIRECT, headers: "Location: /echoHeaders\r\nSet-Cookie: redirect=true; Max-Age=7776000; path=/", body: "")
        }

        if uri == "/UnitedStates" {
            let value = capitals[String(uri.dropFirst())]!
            let text = request.getCommaSeparatedHeaders()
            let host = request.headers[1].components(separatedBy: " ")[1]
            let ip = host.components(separatedBy: ":")[0]
            let port = host.components(separatedBy: ":")[1]
            let newPort = Int(port)! + 1
            let newHost = ip + ":" + String(newPort)
            let httpResponse = _HTTPResponse(response: .REDIRECT, headers: "Location: http://\(newHost + "/" + value)", body: text)
            return httpResponse 
        }

        if uri == "/DTDs/PropertyList-1.0.dtd" {
            let dtd = """
    <!ENTITY % plistObject "(array | data | date | dict | real | integer | string | true | false )" >
    <!ELEMENT plist %plistObject;>
    <!ATTLIST plist version CDATA "1.0" >

    <!-- Collections -->
    <!ELEMENT array (%plistObject;)*>
    <!ELEMENT dict (key, %plistObject;)*>
    <!ELEMENT key (#PCDATA)>

    <!--- Primitive types -->
    <!ELEMENT string (#PCDATA)>
    <!ELEMENT data (#PCDATA)> <!-- Contents interpreted as Base-64 encoded -->
    <!ELEMENT date (#PCDATA)> <!-- Contents should conform to a subset of ISO 8601 (in particular, YYYY '-' MM '-' DD 'T' HH ':' MM ':' SS 'Z'.  Smaller units may be omitted with a loss of precision) -->

    <!-- Numerical primitives -->
    <!ELEMENT true EMPTY>  <!-- Boolean constant true -->
    <!ELEMENT false EMPTY> <!-- Boolean constant false -->
    <!ELEMENT real (#PCDATA)> <!-- Contents should represent a floating point number matching ("+" | "-")? d+ ("."d*)? ("E" ("+" | "-") d+)? where d is a digit 0-9.  -->
    <!ELEMENT integer (#PCDATA)> <!-- Contents should represent a (possibly signed) integer number in base 10 -->
"""
            return _HTTPResponse(response: .OK, body: dtd)
        }

        if uri == "/UnitedKingdom" {
            let value = capitals[String(uri.dropFirst())]!
            let text = request.getCommaSeparatedHeaders()
            //Response header with only path to the location to redirect.
            let httpResponse = _HTTPResponse(response: .REDIRECT, headers: "Location: \(value)", body: text)
            return httpResponse
        }
        
        if uri == "/echo" {
            return _HTTPResponse(response: .OK, body: request.messageBody ?? request.body)
        }
        
        if uri == "/redirect-with-default-port" {
            let text = request.getCommaSeparatedHeaders()
            let host = request.headers[1].components(separatedBy: " ")[1]
            let ip = host.components(separatedBy: ":")[0]
            let httpResponse = _HTTPResponse(response: .REDIRECT, headers: "Location: http://\(ip)/redirected-with-default-port", body: text)
            return httpResponse

        }

        if uri == "/gzipped-response" {
            // This is "Hello World!" gzipped.
            let helloWorld = Data([0x1f, 0x8b, 0x08, 0x00, 0x6d, 0xca, 0xb2, 0x5c,
                                   0x00, 0x03, 0xf3, 0x48, 0xcd, 0xc9, 0xc9, 0x57,
                                   0x08, 0xcf, 0x2f, 0xca, 0x49, 0x51, 0x04, 0x00,
                                   0xa3, 0x1c, 0x29, 0x1c, 0x0c, 0x00, 0x00, 0x00])
            return _HTTPResponse(response: .OK,
                                 headers: ["Content-Length: \(helloWorld.count)",
                                           "Content-Encoding: gzip"].joined(separator: _HTTPUtils.CRLF),
                                 bodyData: helloWorld)
        }

        return _HTTPResponse(response: .OK, body: capitals[String(uri.dropFirst())]!)
    }

    func stop() {
        httpServer.stop()
    }
}

struct ServerError : Error {
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

enum InternalServerError : Error {
    case socketAlreadyClosed
}

public class ServerSemaphore {
    let dispatchSemaphore = DispatchSemaphore(value: 0)

    public func wait(timeout: DispatchTime) -> DispatchTimeoutResult {
        return dispatchSemaphore.wait(timeout: timeout)
    }

    public func signal() {
        dispatchSemaphore.signal()
    }
}

class LoopbackServerTest : XCTestCase {
    private static let staticSyncQ = DispatchQueue(label: "org.swift.TestFoundation.HTTPServer.StaticSyncQ")

    private static var _serverPort: Int = -1
    private static let serverReady = ServerSemaphore()
    private static var _serverActive = false
    private static var testServer: TestURLSessionServer? = nil


    static var serverPort: Int {
        get {
            return staticSyncQ.sync { _serverPort }
        }
        set {
            staticSyncQ.sync { _serverPort = newValue }
        }
    }

    static var serverActive: Bool {
        get { return staticSyncQ.sync { _serverActive } }
        set { staticSyncQ.sync { _serverActive = newValue }}
    }

    static func terminateServer() {
        serverActive = false
        testServer?.stop()
        testServer = nil
    }

    override class func setUp() {
        super.setUp()
        func runServer(with condition: ServerSemaphore, startDelay: TimeInterval? = nil, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
            let server = try TestURLSessionServer(port: nil, startDelay: startDelay, sendDelay: sendDelay, bodyChunks: bodyChunks)
            testServer = server
            serverPort = Int(server.port)
            serverReady.signal()
            serverActive = true

            while serverActive {
                do {
                    try server.httpServer.listen(notify: condition)
                    try server.readAndRespond()
                    if server.httpServer.willReadAgain {
                        try server.httpServer.listen(notify: condition)
                        try server.readAndRespondAgain()
                    }
                    server.httpServer.socket.closeClient()
                } catch {
                }
            }
            serverPort = -2
        }

        globalDispatchQueue.async {
            do {
                try runServer(with: serverReady)
            } catch {
            }
        }

        let timeout = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 2_000_000_000)

        while serverPort == -1 {
            guard serverReady.wait(timeout: timeout) == .success else {
                fatalError("Timedout waiting for server to be ready")
            }
        }
    }

    override class func tearDown() {
        super.tearDown()
        terminateServer()
    }
}
