// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

internal extension UInt {
    init(_ status: CFStreamStatus) {
        self.init(status.rawValue)
    }
}

extension Stream {
    public struct PropertyKey : RawRepresentable, Equatable, Hashable {
        public private(set) var rawValue: String
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
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



// Stream is an abstract class encapsulating the common API to InputStream and OutputStream.
// Subclassers of InputStream and OutputStream must also implement these methods.
open class Stream: NSObject {

    public override init() {
        if type(of: self) == Stream.self {
            NSRequiresConcreteImplementation()
        }
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
        NSRequiresConcreteImplementation()
    }
    
    open func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
        NSRequiresConcreteImplementation()
    }

    open func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        NSRequiresConcreteImplementation()
    }
    
    open func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        NSRequiresConcreteImplementation()
    }
    
    open var streamStatus: Status {
        NSRequiresConcreteImplementation()
    }
    
    open var streamError: Error? {
        NSRequiresConcreteImplementation()
    }
}

// InputStream is an abstract class representing the base functionality of a read stream.
// Subclassers are required to implement these methods.
open class InputStream: Stream {
    enum _Error: Error {
        case cantSeekInputStream
    }
    
    internal let _stream: CFReadStream!

    // reads up to length bytes into the supplied buffer, which must be at least of size len. Returns the actual number of bytes read.
    open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return CFReadStreamRead(_stream, buffer, len)
    }
    
    // returns in O(1) a pointer to the buffer in 'buffer' and by reference in 'len' how many bytes are available. This buffer is only valid until the next stream operation. Subclassers may return NO for this if it is not appropriate for the stream type. This may return NO if the buffer is not available.
    open func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        if let result = UnsafeMutablePointer(mutating: CFReadStreamGetBuffer(_stream, 0, len)) {
            buffer.pointee = result
            return true
        } else {
            return false
        }
    }
    
    // returns YES if the stream has bytes available or if it impossible to tell without actually doing the read.
    open var hasBytesAvailable: Bool {
        return CFReadStreamHasBytesAvailable(_stream)
    }
    
    fileprivate init(readStream: CFReadStream) {
        _stream = readStream
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
    
    open override var streamError: Error? {
        return CFReadStreamCopyError(_stream)
    }
    
    open override func property(forKey key: PropertyKey) -> AnyObject? {
        return CFReadStreamCopyProperty(_stream, key.rawValue._cfObject)
    }
    
    open override func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
        return CFReadStreamSetProperty(_stream, key.rawValue._cfObject, property)
    }
    
    open override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        CFReadStreamScheduleWithRunLoop(_stream, aRunLoop.getCFRunLoop(), mode.rawValue._cfObject)
    }
    
    open override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        CFReadStreamUnscheduleFromRunLoop(_stream, aRunLoop.getCFRunLoop(), mode.rawValue._cfObject)
    }
}

// OutputStream is an abstract class representing the base functionality of a write stream.
// Subclassers are required to implement these methods.
// Currently this is left as named OutputStream due to conflicts with the standard library's text streaming target protocol named OutputStream (which ideally should be renamed)
open class OutputStream : Stream {
    
    private var _stream: CFWriteStream!
    
    // writes the bytes from the specified buffer to the stream up to len bytes. Returns the number of bytes actually written.
    open func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        return  CFWriteStreamWrite(_stream, buffer, len)
    }
    
    // returns YES if the stream can be written to or if it is impossible to tell without actually doing the write.
    open var hasSpaceAvailable: Bool {
        return CFWriteStreamCanAcceptBytes(_stream)
    }
    
    fileprivate init(writeStream: CFWriteStream) {
        _stream = writeStream
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
    
    open class func toMemory() -> Self {
        return self.init(toMemory: ())
    }
    
    open override func property(forKey key: PropertyKey) -> AnyObject? {
        return CFWriteStreamCopyProperty(_stream, key.rawValue._cfObject)
    }
    
    open override func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
        return CFWriteStreamSetProperty(_stream, key.rawValue._cfObject, property)
    }
    
    open override var streamError: Error? {
        return CFWriteStreamCopyError(_stream)
    }
    
    open override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        CFWriteStreamScheduleWithRunLoop(_stream, aRunLoop.getCFRunLoop(), mode.rawValue._cfObject)
    }
    
    open override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        CFWriteStreamUnscheduleFromRunLoop(_stream, aRunLoop.getCFRunLoop(), mode.rawValue._cfObject)
    }
}

public struct _InputStreamSPIForFoundationNetworkingUseOnly {
    var inputStream: InputStream
    
    public init(_ inputStream: InputStream) {
        self.inputStream = inputStream
    }
    
    public func seek(to position: UInt64) throws {
        try inputStream.seek(to: position)
    }
}

extension InputStream {
    func seek(to position: UInt64) throws {
        guard position > 0 else {
            return
        }
        
        guard position < Int.max else { throw _Error.cantSeekInputStream }
        
        let bufferSize = 1024
        var remainingBytes = Int(position)
        
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: bufferSize, alignment: MemoryLayout<UInt8>.alignment)
        
        guard let pointer = buffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
            buffer.deallocate()
            throw _Error.cantSeekInputStream
        }
        
        if self.streamStatus == .notOpen {
            self.open()
        }
        
        while remainingBytes > 0 && self.hasBytesAvailable {
            let read = self.read(pointer, maxLength: min(bufferSize, remainingBytes))
            if read == -1 {
                throw _Error.cantSeekInputStream
            }
            remainingBytes -= read
        }
        
        buffer.deallocate()
        if remainingBytes != 0 {
            throw _Error.cantSeekInputStream
        }
    }
}

// Discussion of this API is ongoing for its usage of AutoreleasingUnsafeMutablePointer
#if false
extension Stream {
    open class func getStreamsToHost(withName hostname: String, port: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<OutputStream?>?) {
        NSUnsupported()
    }
}

extension Stream {
    open class func getBoundStreams(withBufferSize bufferSize: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<OutputStream?>?) {
        NSUnsupported()
    }
}
#endif

extension StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) { }
}

public protocol StreamDelegate : class {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event)
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
public struct StreamSocketSecurityLevel : RawRepresentable, Equatable, Hashable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
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
public struct StreamSOCKSProxyConfiguration : RawRepresentable, Equatable, Hashable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
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
public struct StreamSOCKSProxyVersion : RawRepresentable, Equatable, Hashable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
extension StreamSOCKSProxyVersion {
    public static let version4 = StreamSOCKSProxyVersion(rawValue: "kCFStreamSocketSOCKSVersion4")
    public static let version5 = StreamSOCKSProxyVersion(rawValue: "kCFStreamSocketSOCKSVersion5")
}


// MARK: - Supported network service types
public struct StreamNetworkServiceTypeValue : RawRepresentable, Equatable, Hashable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
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
// String constants for error domains.
public let NSStreamSocketSSLErrorDomain: String = "NSStreamSocketSSLErrorDomain"
// SSL errors are to be interpreted via <Security/SecureTransport.h>
public let NSStreamSOCKSErrorDomain: String = "NSStreamSOCKSErrorDomain"

