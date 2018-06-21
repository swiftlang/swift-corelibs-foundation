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

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
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

    private let sendFlags: CInt
    private var listenSocket: Int32!
    private var socketAddress = UnsafeMutablePointer<sockaddr_in>.allocate(capacity: 1) 
    private var connectionSocket: Int32!
    
    private func isNotNegative(r: CInt) -> Bool {
        return r != -1
    }

    private func isZero(r: CInt) -> Bool {
        return r == 0
    }

    private func attempt(_ name: String, file: String = #file, line: UInt = #line, valid: (CInt) -> Bool,  _ b: @autoclosure () -> CInt) throws -> CInt {
        let r = b()
        guard valid(r) else {
            throw ServerError(operation: name, errno: errno, file: file, line: line)
        }
        return r
    }

    public private(set) var port: UInt16

    init(port: UInt16?) throws {
#if canImport(Darwin)
        sendFlags = 0
#else
        sendFlags = CInt(MSG_NOSIGNAL)
#endif

#if os(Linux) && !os(Android)
            let SOCKSTREAM = Int32(SOCK_STREAM.rawValue)
#else
            let SOCKSTREAM = SOCK_STREAM
#endif
        self.port = port ?? 0
        listenSocket = try attempt("socket", valid: isNotNegative, socket(AF_INET, SOCKSTREAM, Int32(IPPROTO_TCP)))
        var on: CInt = 1
        _ = try attempt("setsockopt", valid: isZero, setsockopt(listenSocket, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<CInt>.size)))

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
        #else
            return sockaddr_in(sin_len: 0, sin_family: sa_family_t(AF_INET), sin_port: netPort, sin_addr: in_addr(s_addr: addr), sin_zero: (0,0,0,0,0,0,0,0))
        #endif
    }

    func acceptConnection(notify: ServerSemaphore) throws {
        try socketAddress.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size, {
            let addr = UnsafeMutablePointer<sockaddr>($0)
            var sockLen = socklen_t(MemoryLayout<sockaddr>.size) 
            connectionSocket = try attempt("accept", valid: isNotNegative, accept(listenSocket, addr, &sockLen))
#if canImport(Dawin)
            // Disable SIGPIPEs when writing to closed sockets
            var on: CInt = 1
            _ = try attempt("setsockopt", valid: isZero, setsockopt(connectionSocket, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<CInt>.size)))
#endif
        })
    }
 
    func readData() throws -> String {
        var buffer = [UInt8](repeating: 0, count: 4096)
        _ = try attempt("read", valid: isNotNegative, CInt(read(connectionSocket, &buffer, buffer.count)))
        return String(cString: &buffer)
    }
    
    func split(_ str: String, _ count: Int) -> [String] {
        return stride(from: 0, to: str.count, by: count).map { i -> String in
            let startIndex = str.index(str.startIndex, offsetBy: i)
            let endIndex   = str.index(startIndex, offsetBy: count, limitedBy: str.endIndex) ?? str.endIndex
            return String(str[startIndex..<endIndex])
        }
    }

    func writeRawData(_ data: Data) throws {
        _ = try data.withUnsafeBytes { ptr in
            try attempt("send", valid: isNotNegative, CInt(send(connectionSocket, ptr, data.count, sendFlags)))
        }
    }
   
    func writeData(header: String, body: String, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
        var _header = Array(header.utf8)
        _  = try attempt("send", valid: isNotNegative, CInt(send(connectionSocket, &_header, _header.count, sendFlags)))

        if let sendDelay = sendDelay, let bodyChunks = bodyChunks {
            let count = max(1, Int(Double(body.utf8.count) / Double(bodyChunks)))
            let texts = split(body, count)
            
            for item in texts {
                sleep(UInt32(sendDelay))
                var bytes = Array(item.utf8)
                _  = try attempt("send", valid: isNotNegative, CInt(send(connectionSocket, &bytes, bytes.count, sendFlags)))
            }
        } else {
            var bytes = Array(body.utf8)
            _  = try attempt("send", valid: isNotNegative, CInt(send(connectionSocket, &bytes, bytes.count, sendFlags)))
        }
    }

    func closeClient() {
        if let connectionSocket = self.connectionSocket {
            close(connectionSocket)
            self.connectionSocket = nil
        }
    }

    func shutdownListener() {
        closeClient()
        shutdown(listenSocket, CInt(SHUT_RDWR))
        close(listenSocket)
    }
}

class _HTTPServer {

    let socket: _TCPSocket
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
        socket.closeClient()
        socket.shutdownListener()
    }
   
    public func request() throws -> _HTTPRequest {
       return try _HTTPRequest(request: socket.readData())
    }

    public func respond(with response: _HTTPResponse, startDelay: TimeInterval? = nil, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
        if let delay = startDelay {
            Thread.sleep(forTimeInterval: delay)
        }
        do {
            try self.socket.writeData(header: response.header, body: response.body, sendDelay: sendDelay, bodyChunks: bodyChunks)
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
                responseData = Data(bytes: [
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
    let headers: [String]

    public init(request: String) {
        let headerEnd = (request as NSString).range(of: _HTTPUtils.CRLF2)
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
    public let body: String

    public init(response: Response, headers: String = _HTTPUtils.EMPTY, body: String) {
        self.responseCode = response
        self.headers = headers
        self.body = body
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
        } else {
            try httpServer.respond(with: process(request: req), startDelay: self.startDelay, sendDelay: self.sendDelay, bodyChunks: self.bodyChunks)
        }
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

        if uri == "/requestCookies" {
            let text = request.getCommaSeparatedHeaders()
            return _HTTPResponse(response: .OK, headers: "Content-Length: \(text.data(using: .utf8)!.count)\r\nSet-Cookie: fr=anjd&232; Max-Age=7776000; path=/\r\nSet-Cookie: nm=sddf&232; Max-Age=7776000; path=/; domain=.swift.org; secure; httponly\r\n", body: text)
        }

        if uri == "/setCookies" {
            let text = request.getCommaSeparatedHeaders()
            return _HTTPResponse(response: .OK, headers: "Content-Length: \(text.data(using: .utf8)!.count)", body: text)
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

        while serverPort == -2 {
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
