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

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
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
        guard valid(r) else { throw ServerError(operation: name, errno: r, file: file, line: line) }
        return r
    }

    public private(set) var port: UInt16

    init(port: UInt16?) throws {
        #if os(Linux) && !os(Android)
            let SOCKSTREAM = Int32(SOCK_STREAM.rawValue)
        #else
            let SOCKSTREAM = SOCK_STREAM
        #endif
        self.port = port ?? 0
        listenSocket = try attempt("socket", valid: isNotNegative, socket(AF_INET, SOCKSTREAM, Int32(IPPROTO_TCP)))
        var on: Int = 1
        _ = try attempt("setsockopt", valid: isZero, setsockopt(listenSocket, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int>.size)))
        let sa = createSockaddr(port)
        socketAddress.initialize(to: sa)
        try socketAddress.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size, { 
            let addr = UnsafePointer<sockaddr>($0)
            _ = try attempt("bind", valid: isZero, bind(listenSocket, addr, socklen_t(MemoryLayout<sockaddr>.size)))
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
        _ = try attempt("listen", valid: isZero, listen(listenSocket, SOMAXCONN))
        try socketAddress.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size, {
            let addr = UnsafeMutablePointer<sockaddr>($0)
            var sockLen = socklen_t(MemoryLayout<sockaddr>.size) 
            notify.signal()
            connectionSocket = try attempt("accept", valid: isNotNegative, accept(listenSocket, addr, &sockLen))
        })
    }
 
    func readData() throws -> String {
        var buffer = [UInt8](repeating: 0, count: 4096)
        _ = try attempt("read", valid: isNotNegative, CInt(read(connectionSocket, &buffer, 4096)))
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
            try attempt("write", valid: isNotNegative, CInt(write(connectionSocket, ptr, data.count)))
        }
    }
   
    func writeData(header: String, body: String, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
        var header = Array(header.utf8)
        _  = try attempt("write", valid: isNotNegative, CInt(write(connectionSocket, &header, header.count)))
        
        if let sendDelay = sendDelay, let bodyChunks = bodyChunks {
            let count = max(1, Int(Double(body.utf8.count) / Double(bodyChunks)))
            let texts = split(body, count)
            
            for item in texts {
                sleep(UInt32(sendDelay))
                var bytes = Array(item.utf8)
                _  = try attempt("write", valid: isNotNegative, CInt(write(connectionSocket, &bytes, bytes.count)))
            }
        } else {
            var bytes = Array(body.utf8)
            _  = try attempt("write", valid: isNotNegative, CInt(write(connectionSocket, &bytes, bytes.count)))
        }
    }

    func shutdown() {
        if let connectionSocket = self.connectionSocket {
            close(connectionSocket)
        }
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
        socket.shutdown()
    }
   
    public func request() throws -> _HTTPRequest {
       return try _HTTPRequest(request: socket.readData())
    }

    public func respond(with response: _HTTPResponse, startDelay: TimeInterval? = nil, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
        let semaphore = DispatchSemaphore(value: 0)
        let deadlineTime: DispatchTime
            
        if let startDelay = startDelay {
           deadlineTime = .now() + .seconds(Int(startDelay))
        } else {
            deadlineTime = .now()
        }

        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            do {
                try self.socket.writeData(header: response.header, body: response.body, sendDelay: sendDelay, bodyChunks: bodyChunks)
                semaphore.signal()
            } catch { }
        }
        semaphore.wait()
        
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
        let lines = request.components(separatedBy: _HTTPUtils.CRLF2)[0].components(separatedBy: _HTTPUtils.CRLF)
        headers = Array(lines[0...lines.count-2])
        method = Method(rawValue: headers[0].components(separatedBy: " ")[0])!
        uri = headers[0].components(separatedBy: " ")[1]
        body = lines.last!
    }

    public func getCommaSeparatedHeaders() -> String {
        var allHeaders = ""
        for header in headers {
            allHeaders += header + ","
        }
        return allHeaders
    }

}

struct _HTTPResponse {
    enum Response : Int {
        case OK = 200
        case REDIRECT = 302
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
    let capitals: [String:String] = ["Nepal":"Kathmandu",
                                     "Peru":"Lima",
                                     "Italy":"Rome",
                                     "USA":"Washington, D.C.",
				     "UnitedStates": "USA",
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
    public func start(started: ServerSemaphore) throws {
        started.signal()
        try httpServer.listen(notify: started)
    }
   
    public func readAndRespond() throws {
        let req = try httpServer.request()
        if req.uri.hasPrefix("/LandOfTheLostCities/") {
            /* these are all misbehaving servers */
            try httpServer.respondWithBrokenResponses(uri: req.uri)
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

    public func wait() {
        dispatchSemaphore.wait()
    }

    public func signal() {
        dispatchSemaphore.signal()
    }
}

class LoopbackServerTest : XCTestCase {
    private static let staticSyncQ = DispatchQueue(label: "org.swift.TestFoundation.HTTPServer.StaticSyncQ")

    private static var _serverPort: Int = -1
    static var serverPort: Int {
        get {
            return staticSyncQ.sync { _serverPort }
        }
        set {
            staticSyncQ.sync { _serverPort = newValue }
        }
    }

    override class func setUp() {
        super.setUp()
        func runServer(with condition: ServerSemaphore, startDelay: TimeInterval? = nil, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
            while true {
                let test = try TestURLSessionServer(port: nil, startDelay: startDelay, sendDelay: sendDelay, bodyChunks: bodyChunks)
                serverPort = Int(test.port)
                try test.start(started: condition)
                try test.readAndRespond()
                serverPort = -2
                test.stop()
            }
        }

        let serverReady = ServerSemaphore()
        globalDispatchQueue.async {
            do {
                try runServer(with: serverReady)

            } catch {
                XCTAssertTrue(true)
                return
            }
        }

        serverReady.wait()
    }
}
