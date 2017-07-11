// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

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


extension Stream : _NSFactory { }

// NSStream is an abstract class encapsulating the common API to InputStream and OutputStream.
// Subclassers of InputStream and OutputStream must also implement these methods.
open class Stream: NSObject {
    open func open() {
        NSRequiresConcreteImplementation()
    }
    
    open func close() {
        NSRequiresConcreteImplementation()
    }
    
    weak open var delegate: StreamDelegate? {
        get {
            NSRequiresConcreteImplementation()
        }
        set {
            NSRequiresConcreteImplementation()
        }
    }
    
    open func property(forKey key: Stream.PropertyKey) -> Any? {
        NSRequiresConcreteImplementation()
    }
    
    open func setProperty(_ property: Any?, forKey key: Stream.PropertyKey) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    open func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        NSRequiresConcreteImplementation()
    }
    
    open func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        NSRequiresConcreteImplementation()
    }
    
    open var streamStatus: Stream.Status {
        get {
            NSRequiresConcreteImplementation()
        }
    }
    
    open var streamError: Error? {
        get {
            NSRequiresConcreteImplementation()
        }
    }
}

// InputStream is an abstract class representing the base functionality of a read stream.
// Subclassers are required to implement these methods.
open class InputStream: Stream {
    open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        NSRequiresConcreteImplementation()
    }
    
    // reads up to length bytes into the supplied buffer, which must be at least of size len. Returns the actual number of bytes read.
    
    open func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        NSRequiresConcreteImplementation()
    }
    
    // returns in O(1) a pointer to the buffer in 'buffer' and by reference in 'len' how many bytes are available. This buffer is only valid until the next stream operation. Subclassers may return NO for this if it is not appropriate for the stream type. This may return NO if the buffer is not available.
    
    open var hasBytesAvailable: Bool {
        get {
            NSRequiresConcreteImplementation()
        }
    }
    
    internal override init() {
        
    }
    
    // returns YES if the stream has bytes available or if it impossible to tell without actually doing the read.
    
    public convenience init(data: Data) {
        if type(of: self) == InputStream.self {
            let stream = CFReadStreamCreateWithData(kCFAllocatorSystemDefault, _unsafeReferenceCast(data._bridgeToObjectiveC(), to: CFData.self))
            self.init(factory: _unsafeReferenceCast(stream, to: InputStream.self))
        } else {
            self.init()
        }
    }
    
    public convenience init?(url: URL) {
        if type(of: self) == InputStream.self {
            let stream = CFReadStreamCreateWithFile(kCFAllocatorSystemDefault, _unsafeReferenceCast(url._bridgeToObjectiveC(), to: CFURL.self))
            self.init(factory: _unsafeReferenceCast(stream, to: InputStream.self))
        } else {
            self.init()
        }
    }
    
    public convenience init?(fileAtPath path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }
    
    internal var _cfStreamError: CFStreamError {
        return CFStreamError(domain: kCFStreamErrorDomainCustom, error: -1)
    }
    
    open override var _cfTypeID: CFTypeID {
        return CFReadStreamGetTypeID()
    }
}

// OutputStream is an abstract class representing the base functionality of a write stream.
// Subclassers are required to implement these methods.
open class OutputStream : Stream {
    open func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        NSRequiresConcreteImplementation()
    }
    
    open var hasSpaceAvailable: Bool {
        get {
            NSRequiresConcreteImplementation()
        }
    }
    
    internal override init() {
        
    }
    
    public convenience init(toMemory: ()) {
        if type(of: self) == OutputStream.self {
            let stream = CFWriteStreamCreateWithAllocatedBuffers(kCFAllocatorSystemDefault, kCFAllocatorDefault)
            self.init(factory: _unsafeReferenceCast(stream, to: OutputStream.self))
        } else {
            self.init()
        }
    }
    
    public convenience init(toBuffer buffer: UnsafeMutablePointer<UInt8>, capacity: Int) {
        if type(of: self) == OutputStream.self {
            let stream = CFWriteStreamCreateWithBuffer(kCFAllocatorSystemDefault, buffer, capacity)
            self.init(factory: _unsafeReferenceCast(stream, to: OutputStream.self))
        } else {
            self.init()
        }
    }
    
    public convenience init?(url: URL, append shouldAppend: Bool) {
        if type(of: self) == OutputStream.self {
            let stream = CFWriteStreamCreateWithFile(kCFAllocatorSystemDefault, _unsafeReferenceCast(url._bridgeToObjectiveC(), to: CFURL.self))
            if shouldAppend {
                CFWriteStreamSetProperty(stream, kCFStreamPropertyAppendToFile, kCFBooleanTrue)
            }
            self.init(factory: _unsafeReferenceCast(stream, to: OutputStream.self))
        } else {
            self.init()
        }
    }
    
    public convenience init?(toFileAtPath path: String, append shouldAppend: Bool) {
        self.init(url: URL(fileURLWithPath: path), append: shouldAppend)
    }
    
    internal var _cfStreamError: CFStreamError {
        return CFStreamError(domain: kCFStreamErrorDomainCustom, error: -1)
    }
    
    open override var _cfTypeID: CFTypeID {
        return CFWriteStreamGetTypeID()
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
// NSString constants for error domains.
public let NSStreamSocketSSLErrorDomain: String = "NSStreamSocketSSLErrorDomain"
// SSL errors are to be interpreted via <Security/SecureTransport.h>
public let NSStreamSOCKSErrorDomain: String = "NSStreamSOCKSErrorDomain"

