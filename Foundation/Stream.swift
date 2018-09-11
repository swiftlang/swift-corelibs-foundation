// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(macOS) || os(iOS)
internal extension UInt {
    init(_ status: CFStreamStatus) {
        self.init(status.rawValue)
    }
    
    init(_ event: CFStreamEventType) {
        self.init(event.rawValue)
    }
}
#endif

extension Stream {
    public struct PropertyKey : RawRepresentable, Equatable, Hashable {
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
    
    open func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        NSRequiresConcreteImplementation()
    }
    
    open func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
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
open class InputStream: Stream, _CFBridgeable {

    typealias CFType = CFReadStream
    internal var _base = _CFInfo(typeID: CFReadStreamGetTypeID())
    internal var _flags : CFOptionFlags = 0
    internal var _error : UnsafeMutablePointer<CFError>? = nil
    internal var _client : UnsafeMutablePointer<_CFStreamClient>? = nil
    internal var _info : UnsafeMutableRawPointer? = nil
    internal var _callBacks : UnsafeMutablePointer<_CFStreamCallBacks>? = nil
    internal var _lock : pthread_mutex_t?
    internal var _previousRunloopsAndModes : UnsafeMutablePointer<CFArray>? = nil
    #if DEPLOYMENT_ENABLE_LIBDISPATCH
    internal var _queue : UnsafeMutableRawPointer?
    #endif
    internal var _pendingEventsToDeliver : _DarwinCompatibleBoolean = false
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    override open var _cfTypeID: CFTypeID {
        return CFReadStreamGetTypeID()
    }
    
    open override var delegate: StreamDelegate? {
        get {
            if let info = _CFReadStreamGetClient(_cfObject) {
                return info.assumingMemoryBound(to: StreamDelegate.self).pointee
            }
            return nil
        }
        set {
            if let newValue = newValue as AnyObject? {
                let info = Unmanaged.passUnretained(newValue).toOpaque()
                var context = CFStreamClientContext(version: 0, info: info, retain: nil, release: nil, copyDescription: nil)
                CFReadStreamSetClient(_cfObject, 0x1f, InputStream.clientCallback, &context)
            } else {
                CFReadStreamSetClient(_cfObject, 0, nil, nil)
            }
        }
    }
    
    // reads up to length bytes into the supplied buffer, which must be at least of size len. Returns the actual number of bytes read.
    open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return CFReadStreamRead(_cfObject, buffer, len)
    }
    
    // returns in O(1) a pointer to the buffer in 'buffer' and by reference in 'len' how many bytes are available. This buffer is only valid until the next stream operation. Subclassers may return NO for this if it is not appropriate for the stream type. This may return NO if the buffer is not available.
    open func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        let maxLen = len.pointee
        buffer.pointee = UnsafeMutablePointer(mutating: CFReadStreamGetBuffer(_cfObject, maxLen, len))
        return buffer.pointee != nil && len.pointee >= 0
    }
    
    // returns YES if the stream has bytes available or if it impossible to tell without actually doing the read.
    open var hasBytesAvailable: Bool {
        return CFReadStreamHasBytesAvailable(_cfObject)
    }
    
    public init(data: Data) {
        super.init()
        _CFReadStreamInitWithData(_cfObject, data._cfObject)
    }
    
    public init?(url: URL) {
        super.init()
        let _pointer = OpaquePointer(Unmanaged.passUnretained(self).toOpaque())
        _CFStreamInitWithFile(_pointer, url._cfObject, true)
    }
    
    deinit {
        _CFDeinit(self)
    }
    
    public convenience init?(fileAtPath path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }
    
    open override func open() {
        CFReadStreamOpen(_cfObject)
    }
    
    open override func close() {
        CFReadStreamClose(_cfObject)
    }
    
    open override func property(forKey key: PropertyKey) -> AnyObject? {
        return CFReadStreamCopyProperty(_cfObject, key.rawValue._cfObject)
    }
    
    open override func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
        return CFReadStreamSetProperty(_cfObject, key.rawValue._cfObject, property)
    }
    
    open override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFReadStreamScheduleWithRunLoop(_cfObject, aRunLoop.getCFRunLoop(), mode.rawValue._cfObject)
    }
    
    open override func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFReadStreamUnscheduleFromRunLoop(_cfObject, aRunLoop.getCFRunLoop(), mode.rawValue._cfObject)
    }
    
    open override var streamStatus: Status {
        return Stream.Status(rawValue: UInt(CFReadStreamGetStatus(_cfObject)))!
    }
    
    open override var streamError: Error? {
        return CFReadStreamCopyError(_cfObject)
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        switch object {
        case let object as InputStream:
            return CFEqual(self._cfObject, object._cfObject)
        case let object as CFReadStream:
            return CFEqual(self._cfObject, object)
        default:
            return false
        }
    }
    
    open override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    fileprivate static let clientCallback: CFReadStreamClientCallBack = { cfstream , event, info in
        guard let cfstream = cfstream, let delegate = info?.assumingMemoryBound(to: StreamDelegate.self).pointee else {
            return
        }
        let handle = Stream.Event(rawValue: UInt(event))
        delegate.stream(unsafeBitCast(cfstream, to: InputStream.self), handle: handle)
    }
}

// OutputStream is an abstract class representing the base functionality of a write stream.
// Subclassers are required to implement these methods.
// Currently this is left as named OutputStream due to conflicts with the standard library's text streaming target protocol named OutputStream (which ideally should be renamed)
open class OutputStream : Stream {
    
    typealias CFType = CFWriteStream
    internal var _base = _CFInfo(typeID: CFWriteStreamGetTypeID())
    internal var _flags : CFOptionFlags = 0
    internal var _error : UnsafeMutablePointer<CFError>? = nil
    internal var _client : UnsafeMutablePointer<_CFStreamClient>? = nil
    internal var _info : UnsafeMutableRawPointer? = nil
    internal var _callBacks : UnsafeMutablePointer<_CFStreamCallBacks>? = nil
    internal var _lock : pthread_mutex_t? = nil
    internal var _previousRunloopsAndModes : UnsafeMutablePointer<CFArray>? = nil
    #if DEPLOYMENT_ENABLE_LIBDISPATCH
    internal var _queue : UnsafeMutableRawPointer?
    #endif
    internal var _pendingEventsToDeliver : _DarwinCompatibleBoolean = false
    
    internal var _cfObject: CFType {
        return unsafeBitCast(self, to: CFType.self)
    }
    
    override open var _cfTypeID: CFTypeID {
        return CFWriteStreamGetTypeID()
    }
    
    open override var delegate: StreamDelegate? {
        get {
            if let info = _CFWriteStreamGetClient(_cfObject) {
                return info.assumingMemoryBound(to: StreamDelegate.self).pointee
            }
            return nil
        }
        set {
            if let newValue = newValue as AnyObject? {
                let info = Unmanaged.passUnretained(newValue).toOpaque()
                var context = CFStreamClientContext(version: 0, info: info, retain: nil, release: nil, copyDescription: nil)
                CFWriteStreamSetClient(_cfObject, 0x1f, OutputStream.clientCallback, &context)
            } else {
                CFWriteStreamSetClient(_cfObject, 0, nil, nil)
            }
        }
    }
    
    // writes the bytes from the specified buffer to the stream up to len bytes. Returns the number of bytes actually written.
    open func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        return CFWriteStreamWrite(_cfObject, buffer, len)
    }
    
    // returns YES if the stream can be written to or if it is impossible to tell without actually doing the write.
    open var hasSpaceAvailable: Bool {
        return CFWriteStreamCanAcceptBytes(_cfObject)
    }
    
    // NOTE: on Darwin this is     'open class func toMemory() -> Self'
    required public init(toMemory: ()) {
        super.init()
        _CFWriteStreamInitWithAllocatedBuffers(_cfObject, kCFAllocatorDefault)
    }
    
    // TODO: this should use the real buffer API
    public init(toBuffer buffer: UnsafeMutablePointer<UInt8>, capacity: Int) {
        super.init()
        _CFWriteStreamInitWithBuffer(_cfObject, buffer, capacity)
    }
    
    public init?(url: URL, append shouldAppend: Bool) {
        super.init()
        let _pointer = OpaquePointer(Unmanaged.passUnretained(self).toOpaque())
        _CFStreamInitWithFile(_pointer, url._cfObject, true)
        CFWriteStreamSetProperty(_cfObject, kCFStreamPropertyAppendToFile, shouldAppend._cfObject)
    }
    
    deinit {
        _CFDeinit(self)
    }
    
    public convenience init?(toFileAtPath path: String, append shouldAppend: Bool) {
        self.init(url: URL(fileURLWithPath: path), append: shouldAppend)
    }
    
    open override func open() {
        CFWriteStreamOpen(_cfObject)
    }
    
    open override func close() {
        CFWriteStreamClose(_cfObject)
    }
    
    open class func toMemory() -> Self {
        return self.init(toMemory: ())
    }
    
    open override func property(forKey key: PropertyKey) -> AnyObject? {
        return CFWriteStreamCopyProperty(_cfObject, key.rawValue._cfObject)
    }
    
    open override func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
        return CFWriteStreamSetProperty(_cfObject, key.rawValue._cfObject, property)
    }
    
    open override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFWriteStreamScheduleWithRunLoop(_cfObject, aRunLoop.getCFRunLoop(), mode.rawValue._cfObject)
    }
    
    open override func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFWriteStreamUnscheduleFromRunLoop(_cfObject, aRunLoop.getCFRunLoop(), mode.rawValue._cfObject)
    }
    
    open override var streamStatus: Status {
        return Stream.Status(rawValue: UInt(CFWriteStreamGetStatus(_cfObject)))!
    }
    
    open override var streamError: Error? {
        return CFWriteStreamCopyError(_cfObject)
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        switch object {
        case let object as OutputStream:
            return self._cfObject == object._cfObject
        case let object as CFWriteStream:
            return self._cfObject == object
        default:
            return false
        }
    }
    
    open override var hash: Int {
        return Int(bitPattern: CFHash(_cfObject))
    }
    
    fileprivate static let clientCallback: CFWriteStreamClientCallBack = { cfstream , event, info in
        guard let cfstream = cfstream, let delegate = info?.assumingMemoryBound(to: StreamDelegate.self).pointee else {
            return
        }
        let handle = Stream.Event(rawValue: UInt(event))
        delegate.stream(unsafeBitCast(cfstream, to: OutputStream.self), handle: handle)
    }
}

// Discussion of this API is ongoing for its usage of AutoreleasingUnsafeMutablePointer
#if false
extension Stream {
    open class func getStreamsToHost(withName hostname: String, port: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<OutputStream?>?) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, hostname._cfObject, UInt32(port), &readStream, &writeStream)
        inputStream?.pointee = readStream.map({ InputStream($0.takeRetainedValue()) })
        outputStream?.pointee = writeStream.map({ OutputStream($0.takeRetainedValue()) })
    }
}

extension Stream {
    open class func getBoundStreams(withBufferSize bufferSize: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<OutputStream?>?) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreateBoundPair(kCFAllocatorDefault, &readStream, &writeStream, bufferSize)
        inputStream?.pointee = readStream.map({ InputStream($0.takeRetainedValue()) })
        outputStream?.pointee = writeStream.map({ OutputStream($0.takeRetainedValue()) })
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
    public var hashValue: Int {
        return rawValue.hashValue
    }
    public static func ==(lhs: StreamSocketSecurityLevel, rhs: StreamSocketSecurityLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
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
    public var hashValue: Int {
        return rawValue.hashValue
    }
    public static func ==(lhs: StreamSOCKSProxyConfiguration, rhs: StreamSOCKSProxyConfiguration) -> Bool {
        return lhs.rawValue == rhs.rawValue
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
    public var hashValue: Int {
        return rawValue.hashValue
    }
    public static func ==(lhs: StreamSOCKSProxyVersion, rhs: StreamSOCKSProxyVersion) -> Bool {
        return lhs.rawValue == rhs.rawValue
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
    public var hashValue: Int {
        return rawValue.hashValue
    }
    public static func ==(lhs: StreamNetworkServiceTypeValue, rhs: StreamNetworkServiceTypeValue) -> Bool {
        return lhs.rawValue == rhs.rawValue
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
