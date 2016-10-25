// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(OSX) || os(iOS)
internal extension UInt {
    init(_ status: CFStreamStatus) {
        self.init(status.rawValue)
    }
}
#endif

extension Stream {
    public struct PropertyKey : RawRepresentable, Equatable, Hashable, Comparable {
        public private(set) var rawValue: String
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public var hashValue: Int {
            return rawValue.hashValue
        }
        
        public static func ==(lhs: Stream.PropertyKey, rhs: Stream.PropertyKey) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
        
        public static func <(lhs: Stream.PropertyKey, rhs: Stream.PropertyKey) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    public enum Status : UInt {
        
        case notOpen
        case opening
        case open
        case reading
        case writing
        case atEnd
        case closed
        case error
    }

    public struct Event : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        // NOTE: on darwin these are vars
        public static let openCompleted = Event(rawValue: 1 << 0)
        public static let hasBytesAvailable = Event(rawValue: 1 << 1)
        public static let hasSpaceAvailable = Event(rawValue: 1 << 2)
        public static let errorOccurred = Event(rawValue: 1 << 3)
        public static let endEncountered = Event(rawValue: 1 << 4)
    }
}



// NSStream is an abstract class encapsulating the common API to InputStream and OutputStream.
// Subclassers of InputStream and OutputStream must also implement these methods.
open class Stream: NSObject {

    public override init() {

    }
    
    open func open() {
        NSRequiresConcreteImplementation()
    }
    
    open func close() {
        NSRequiresConcreteImplementation()
    }
    
    open weak var delegate: StreamDelegate?
    // By default, a stream is its own delegate, and subclassers of InputStream and OutputStream must maintain this contract. [someStream setDelegate:nil] must restore this behavior. As usual, delegates are not retained.
    
    open func property(forKey key: PropertyKey) -> AnyObject? {
        NSUnimplemented()
    }
    
    open func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
        NSUnimplemented()
    }

// Re-enable once run loop is compiled on all platforms

    open func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        NSUnimplemented()
    }
    
    open func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        NSUnimplemented()
    }
    
    open var streamStatus: Status {
        NSRequiresConcreteImplementation()
    }
    
    open var streamError: NSError? {
        NSUnimplemented()
    }
}

// InputStream is an abstract class representing the base functionality of a read stream.
// Subclassers are required to implement these methods.
open class InputStream: Stream {

    private var _stream: CFReadStream!

    // reads up to length bytes into the supplied buffer, which must be at least of size len. Returns the actual number of bytes read.
    open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return CFReadStreamRead(_stream, buffer, CFIndex(len._bridgeToObjectiveC()))
    }
    
    // returns in O(1) a pointer to the buffer in 'buffer' and by reference in 'len' how many bytes are available. This buffer is only valid until the next stream operation. Subclassers may return NO for this if it is not appropriate for the stream type. This may return NO if the buffer is not available.
    open func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        NSUnimplemented()
    }
    
    // returns YES if the stream has bytes available or if it impossible to tell without actually doing the read.
    open var hasBytesAvailable: Bool {
        return CFReadStreamHasBytesAvailable(_stream)
    }
    
    public init(data: Data) {
        _stream = CFReadStreamCreateWithData(kCFAllocatorSystemDefault, data._cfObject)
    }
    
    public init?(url: URL) {
        _stream = CFReadStreamCreateWithFile(kCFAllocatorDefault, url._cfObject)
    }

    public convenience init?(fileAtPath path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }

    open override func open() {
        CFReadStreamOpen(_stream)
    }
    
    open override func close() {
        CFReadStreamClose(_stream)
    }
    
    open override var streamStatus: Status {
        return Stream.Status(rawValue: UInt(CFReadStreamGetStatus(_stream)))!
    }
}

// OutputStream is an abstract class representing the base functionality of a write stream.
// Subclassers are required to implement these methods.
// Currently this is left as named OutputStream due to conflicts with the standard library's text streaming target protocol named OutputStream (which ideally should be renamed)
open class OutputStream : Stream {
    
    private  var _stream: CFWriteStream!
    
    // writes the bytes from the specified buffer to the stream up to len bytes. Returns the number of bytes actually written.
    open func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        return  CFWriteStreamWrite(_stream, buffer, len)
    }
    
    // returns YES if the stream can be written to or if it is impossible to tell without actually doing the write.
    open var hasSpaceAvailable: Bool {
        return CFWriteStreamCanAcceptBytes(_stream)
    }
    // NOTE: on Darwin this is     'open class func toMemory() -> Self'
    required public init(toMemory: ()) {
        _stream = CFWriteStreamCreateWithAllocatedBuffers(kCFAllocatorDefault, kCFAllocatorDefault)
    }

    // TODO: this should use the real buffer API
    public init(toBuffer buffer: UnsafeMutablePointer<UInt8>, capacity: Int) {
        _stream = CFWriteStreamCreateWithBuffer(kCFAllocatorSystemDefault, buffer, capacity)
    }
    
    public init?(url: URL, append shouldAppend: Bool) {
        _stream = CFWriteStreamCreateWithFile(kCFAllocatorSystemDefault, url._cfObject)
        CFWriteStreamSetProperty(_stream, kCFStreamPropertyAppendToFile, shouldAppend._cfObject)
    }
    
    public convenience init?(toFileAtPath path: String, append shouldAppend: Bool) {
        self.init(url: URL(fileURLWithPath: path), append: shouldAppend)
    }
    
    open override func open() {
        CFWriteStreamOpen(_stream)
    }
    
    open override func close() {
        CFWriteStreamClose(_stream)
    }
    
    open override var streamStatus: Status {
        return Stream.Status(rawValue: UInt(CFWriteStreamGetStatus(_stream)))!
    }
    
    open class func outputStreamToMemory() -> Self {
        return self.init(toMemory: ())
    }
    
    open override func property(forKey key: PropertyKey) -> AnyObject? {
        return CFWriteStreamCopyProperty(_stream, key.rawValue._cfObject)
    }
    
    open  override func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
        return CFWriteStreamSetProperty(_stream, key.rawValue._cfObject, property)
    }
}

// Discussion of this API is ongoing for its usage of AutoreleasingUnsafeMutablePointer
#if false
extension Stream {
    open class func getStreamsToHost(withName hostname: String, port: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<OutputStream?>?) {
        NSUnimplemented()
    }
}

extension Stream {
    open class func getBoundStreams(withBufferSize bufferSize: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<OutputStream?>?) {
        NSUnimplemented()
    }
}
#endif

extension StreamDelegate {
    func stream(_ aStream: Stream, handleEvent eventCode: Stream.Event) { }
}

public protocol StreamDelegate : class {
    func stream(_ aStream: Stream, handleEvent eventCode: Stream.Event)
}

// MARK: -
extension Stream.PropertyKey {
    public static let socketSecurityLevelKey = Stream.PropertyKey(rawValue: "kCFStreamPropertySocketSecurityLevel")
    public static let socksProxyConfigurationKey = Stream.PropertyKey(rawValue: "kCFStreamPropertySOCKSProxy")
    public static let dataWrittenToMemoryStreamKey = Stream.PropertyKey(rawValue: "kCFStreamPropertyDataWritten")
    public static let fileCurrentOffsetKey = Stream.PropertyKey(rawValue: "kCFStreamPropertyFileCurrentOffset")
    public static let networkServiceType = Stream.PropertyKey(rawValue: "kCFStreamNetworkServiceType")
}

// MARK: -
public struct StreamSocketSecurityLevel : RawRepresentable, Equatable, Hashable, Comparable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    public var hashValue: Int {
        return rawValue.hashValue
    }
    public static func ==(lhs: StreamSocketSecurityLevel, rhs: StreamSocketSecurityLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func <(lhs: StreamSocketSecurityLevel, rhs: StreamSocketSecurityLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
extension StreamSocketSecurityLevel {
    public static let none = StreamSocketSecurityLevel(rawValue: "kCFStreamSocketSecurityLevelNone")
    public static let ssLv2 = StreamSocketSecurityLevel(rawValue: "NSStreamSocketSecurityLevelSSLv2")
    public static let ssLv3 = StreamSocketSecurityLevel(rawValue: "NSStreamSocketSecurityLevelSSLv3")
    public static let tlSv1 = StreamSocketSecurityLevel(rawValue: "kCFStreamSocketSecurityLevelTLSv1")
    public static let negotiatedSSL = StreamSocketSecurityLevel(rawValue: "kCFStreamSocketSecurityLevelNegotiatedSSL")
}


// MARK: -
public struct StreamSOCKSProxyConfiguration : RawRepresentable, Equatable, Hashable, Comparable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    public var hashValue: Int {
        return rawValue.hashValue
    }
    public static func ==(lhs: StreamSOCKSProxyConfiguration, rhs: StreamSOCKSProxyConfiguration) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func <(lhs: StreamSOCKSProxyConfiguration, rhs: StreamSOCKSProxyConfiguration) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
extension StreamSOCKSProxyConfiguration {
    public static let hostKey = StreamSOCKSProxyConfiguration(rawValue: "NSStreamSOCKSProxyKey")
    public static let portKey = StreamSOCKSProxyConfiguration(rawValue: "NSStreamSOCKSPortKey")
    public static let versionKey = StreamSOCKSProxyConfiguration(rawValue: "kCFStreamPropertySOCKSVersion")
    public static let userKey = StreamSOCKSProxyConfiguration(rawValue: "kCFStreamPropertySOCKSUser")
    public static let passwordKey = StreamSOCKSProxyConfiguration(rawValue: "kCFStreamPropertySOCKSPassword")
}


// MARK: -
public struct StreamSOCKSProxyVersion : RawRepresentable, Equatable, Hashable, Comparable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    public var hashValue: Int {
        return rawValue.hashValue
    }
    public static func ==(lhs: StreamSOCKSProxyVersion, rhs: StreamSOCKSProxyVersion) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func <(lhs: StreamSOCKSProxyVersion, rhs: StreamSOCKSProxyVersion) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
extension StreamSOCKSProxyVersion {
    public static let version4 = StreamSOCKSProxyVersion(rawValue: "kCFStreamSocketSOCKSVersion4")
    public static let version5 = StreamSOCKSProxyVersion(rawValue: "kCFStreamSocketSOCKSVersion5")
}


// MARK: - Supported network service types
public struct StreamNetworkServiceTypeValue : RawRepresentable, Equatable, Hashable, Comparable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    public var hashValue: Int {
        return rawValue.hashValue
    }
    public static func ==(lhs: StreamNetworkServiceTypeValue, rhs: StreamNetworkServiceTypeValue) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func <(lhs: StreamNetworkServiceTypeValue, rhs: StreamNetworkServiceTypeValue) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
extension StreamNetworkServiceTypeValue {
    public static let voIP = StreamNetworkServiceTypeValue(rawValue: "kCFStreamNetworkServiceTypeVoIP")
    public static let video = StreamNetworkServiceTypeValue(rawValue: "kCFStreamNetworkServiceTypeVideo")
    public static let background = StreamNetworkServiceTypeValue(rawValue: "kCFStreamNetworkServiceTypeBackground")
    public static let voice = StreamNetworkServiceTypeValue(rawValue: "kCFStreamNetworkServiceTypeVoice")
    public static let callSignaling = StreamNetworkServiceTypeValue(rawValue: "kCFStreamNetworkServiceTypeVoice")
}

// MARK: - Error Domains
// NSString constants for error domains.
public let NSStreamSocketSSLErrorDomain: String = "NSStreamSocketSSLErrorDomain"
// SSL errors are to be interpreted via <Security/SecureTransport.h>
public let NSStreamSOCKSErrorDomain: String = "NSStreamSOCKSErrorDomain"

func socketRead(from s: CFSocketNativeHandle, buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
    return read(s, buffer, len)
}

func socketWrite(from s: CFSocketNativeHandle, buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
    return write(s, buffer, len)
}

func closeSocket(_ socket: CFSocketNativeHandle) {
    close(socket)
}

extension Stream {
    open class func getStreamsToHost(withName hostname: String, port: Int, inputStream: UnsafeMutablePointer<InputStream?>?, outputStream: UnsafeMutablePointer<OutputStream?>?) {
        
        let myipv4cfsock = CFSocketCreate(kCFAllocatorDefault, PF_INET, Int32(SOCK_STREAM.rawValue), Int32(IPPROTO_TCP), CFOptionFlags(kCFSocketNoCallBack), nil, nil)
        
        
        let sinSize = MemoryLayout<sockaddr_in>.size
        let sin = UnsafeMutablePointer<sockaddr_in>.allocate(capacity: sinSize)
        defer {
            sin.deinitialize()
            sin.deallocate(capacity: sinSize)
        }
        memset(sin, 0, sinSize)
        sin.pointee.sin_family = sa_family_t(UInt16(AF_INET))
        sin.pointee.sin_port = htons(UInt16(port))
        sin.pointee.sin_addr.s_addr = inet_addr(hostname)
        
        sin.withMemoryRebound(to: UInt8.self, capacity: sinSize, {
            let sincfd = CFDataCreate(kCFAllocatorDefault, $0, sinSize)
            let socketError = CFSocketConnectToAddress(myipv4cfsock, sincfd, 0.0)
            if socketError != 0 {
                print("socketError: \(socketError)")
                return
            }
        })
        let sock = CFSocketGetNative(myipv4cfsock)
        getStreamsTo(socket: sock, inputStream: inputStream, outputStream: outputStream)
    }
    
    open class func getStreamsTo(socket: CFSocketNativeHandle, inputStream: UnsafeMutablePointer<InputStream?>?, outputStream: UnsafeMutablePointer<OutputStream?>?) {
        inputStream?.pointee = SocketInputStream(withSocket: socket)
        outputStream?.pointee = SocketOutputStream(withSocket: socket)
    }
}

open class SocketInputStream: InputStream {
    var nativeSocket: CFSocketNativeHandle!
    var socket: CFSocket?
    var status: Status?
    
    public init(withSocket s: CFSocketNativeHandle) {
        super.init(data: Data(count: 0))
        nativeSocket = s
        status = .opening
        
        let handleRead : CFSocketCallBack = {s, type, address, data, info in
            print("handleRead")
            let inputStream = unsafeBitCast(info, to: SocketInputStream.self)
            if let delegate = inputStream.delegate {
                delegate.stream(inputStream, handleEvent: Stream.Event.hasBytesAvailable)
            }
        }
        
        var context = CFSocketContext(version: CFIndex(0), info: unsafeBitCast(self, to: UnsafeMutableRawPointer.self), retain: nil, release: nil, copyDescription: nil)
        socket = CFSocketCreateWithNative(kCFAllocatorDefault, nativeSocket, CFOptionFlags(kCFSocketReadCallBack), handleRead, &context)
    }
    
    open override func schedule(in runLoop: RunLoop, forMode mode: RunLoopMode) {
        //print("SocketInputStream schedule")
        let socketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), socketSource, kCFRunLoopDefaultMode)
    }
    
    open override func open() {
        
        self.status = .open
        if let delegate = self.delegate {
            delegate.stream(self, handleEvent: Stream.Event.openCompleted)
        }
    }
    
    // reads up to length bytes into the supplied buffer, which must be at least of size len. Returns the actual number of bytes read.
    open override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return socketRead(from: nativeSocket, buffer: buffer, maxLength: len)
    }
    
    open override func close() {
        closeSocket(nativeSocket)
    }
}

open class SocketOutputStream: OutputStream {
    var nativeSocket: CFSocketNativeHandle!
    var socket: CFSocket?
    var status: Status?
    
    required public init(toMemory: ()) {
        super.init(toMemory: ())
    }
    
    public init(withSocket s: CFSocketNativeHandle) {
        super.init(toMemory: ())
        nativeSocket = s
        status = .opening
        
        let handleWrite : CFSocketCallBack = {s, type, address, data, info in
            print("handleWrite")
            let outputStream = unsafeBitCast(info, to: SocketOutputStream.self)
            if let delegate = outputStream.delegate {
                delegate.stream(outputStream, handleEvent: Stream.Event.hasSpaceAvailable)
            }
        }
        var context = CFSocketContext(version: CFIndex(0), info: unsafeBitCast(self, to: UnsafeMutableRawPointer.self), retain: nil, release: nil, copyDescription: nil)
        socket = CFSocketCreateWithNative(kCFAllocatorDefault, nativeSocket, CFOptionFlags(kCFSocketWriteCallBack), handleWrite, &context)
        //print("SocketOutputStream socket: \(socket)")
    }
    
    open override func schedule(in runLoop: RunLoop, forMode mode: RunLoopMode) {
        //print("SocketOutputStream schedule")
        let socketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), socketSource, kCFRunLoopDefaultMode)
    }
    
    open override func open() {
        //print("SocketOutputStream open")
        
        self.status = .open
        if let delegate = self.delegate {
            delegate.stream(self, handleEvent: Stream.Event.openCompleted)
            delegate.stream(self, handleEvent: Stream.Event.hasSpaceAvailable)
        }
    }
    
    open override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        //return write(nativeSocket, buffer, len)
        return socketWrite(from: nativeSocket, buffer: buffer, maxLength: len)
    }
    
    open override func close() {
        closeSocket(nativeSocket)
    }
}
