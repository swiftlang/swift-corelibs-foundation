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
    import Glibc
#else
    import CoreFoundation
    import SwiftFoundation
    import Darwin
#endif

public let globalDispatchQueue = DispatchQueue.global()

struct _HTTPUtils {
    static let CRLF = "\r\n"
    static let VERSION = "HTTP/1.1"
    static let SPACE = " "
    static let CRLF2 = CRLF + CRLF
    static let EMPTY = ""
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

    init(port: UInt16) throws {
        #if os(Linux)
            let SOCKSTREAM = Int32(SOCK_STREAM.rawValue)
        #else
            let SOCKSTREAM = SOCK_STREAM
        #endif
        listenSocket = try attempt("socket", valid: isNotNegative, socket(AF_INET, SOCKSTREAM, Int32(IPPROTO_TCP)))
        var on: Int = 1
        _ = try attempt("setsockopt", valid: isZero, setsockopt(listenSocket, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int>.size)))
        let sa = createSockaddr(port)
        socketAddress.initialize(to: sa)
        try socketAddress.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size, { 
            let addr = UnsafePointer<sockaddr>($0)
            _ = try attempt("bind", valid: isZero, bind(listenSocket, addr, socklen_t(MemoryLayout<sockaddr>.size)))
        })
    }

    private func createSockaddr(_ port: UInt16) -> sockaddr_in {
        #if os(Linux)
            return sockaddr_in(sin_family: sa_family_t(AF_INET), sin_port: htons(port), sin_addr: in_addr(s_addr: INADDR_ANY), sin_zero: (0,0,0,0,0,0,0,0))
        #else
            return sockaddr_in(sin_len: 0, sin_family: sa_family_t(AF_INET), sin_port: CFSwapInt16HostToBig(port), sin_addr: in_addr(s_addr: INADDR_ANY), sin_zero: (0,0,0,0,0,0,0,0) )
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
        return stride(from: 0, to: str.characters.count, by: count).map { i -> String in
            let startIndex = str.index(str.startIndex, offsetBy: i)
            let endIndex   = str.index(startIndex, offsetBy: count, limitedBy: str.endIndex) ?? str.endIndex
            return str[startIndex..<endIndex]
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
        close(connectionSocket)
        close(listenSocket)
    }
}

class _HTTPServer {

    let socket: _TCPSocket 
    
    init(port: UInt16) throws {
        socket = try _TCPSocket(port: port)
    }

    public class func create(port: UInt16) throws -> _HTTPServer {
        return try _HTTPServer(port: port)
    }

    public func listen(notify: ServerSemaphore) throws {
        try socket.acceptConnection(notify: notify)
    }

    public func stop() {
        socket.shutdown()
    }
   
    public func request() throws -> _HTTPRequest {
       return _HTTPRequest(request: try socket.readData()) 
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
                                     "country.txt": "A country is a region that is identified as a distinct national entity in political geography"]
    let httpServer: _HTTPServer
    let startDelay: TimeInterval?
    let sendDelay: TimeInterval?
    let bodyChunks: Int?
    
    public init (port: UInt16, startDelay: TimeInterval? = nil, sendDelay: TimeInterval? = nil, bodyChunks: Int? = nil) throws {
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
        try httpServer.respond(with: process(request: httpServer.request()), startDelay: self.startDelay, sendDelay: self.sendDelay, bodyChunks: self.bodyChunks)
    }

    func process(request: _HTTPRequest) -> _HTTPResponse {
        if request.method == .GET || request.method == .POST {
            return getResponse(request: request)
        } else {
            fatalError("Unsupported method!")
        }
    }

    func getResponse(request: _HTTPRequest) -> _HTTPResponse {
        let uri = request.uri
        if uri == "/country.txt" {
            let text = capitals[String(uri.characters.dropFirst())]!
            return _HTTPResponse(response: .OK, headers: "Content-Length: \(text.characters.count)", body: text)
        }

        if uri == "/requestHeaders" {
            let text = request.getCommaSeparatedHeaders()
            return _HTTPResponse(response: .OK, headers: "Content-Length: \(text.characters.count)", body: text)
        }
        return _HTTPResponse(response: .OK, body: capitals[String(uri.characters.dropFirst())]!) 
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
