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

extension NSStream {
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

        public static let openCompleted = Event(rawValue: 1 << 0)
        public static let hasBytesAvailable = Event(rawValue: 1 << 1)
        public static let hasSpaceAvailable = Event(rawValue: 1 << 2)
        public static let errorOccurred = Event(rawValue: 1 << 3)
        public static let endEncountered = Event(rawValue: 1 << 4)
    }
}

public func ==(lhs: NSStream.PropertyKey, rhs: NSStream.PropertyKey) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public func <(lhs: NSStream.PropertyKey, rhs: NSStream.PropertyKey) -> Bool {
    return lhs.rawValue < rhs.rawValue
}


// NSStream is an abstract class encapsulating the common API to NSInputStream and NSOutputStream.
// Subclassers of NSInputStream and NSOutputStream must also implement these methods.
public class NSStream: NSObject, NSCopying {

    public override init() {

    }
    
    public func open() {
        NSRequiresConcreteImplementation()
    }
    
    public func close() {
        NSRequiresConcreteImplementation()
    }
    
    public weak var delegate: StreamDelegate?
    // By default, a stream is its own delegate, and subclassers of NSInputStream and NSOutputStream must maintain this contract. [someStream setDelegate:nil] must restore this behavior. As usual, delegates are not retained.
    
    public func propertyForKey(_ key: String) -> AnyObject? {
        NSRequiresConcreteImplementation()
    }
    
    public func setProperty(_ property: AnyObject?, forKey key: String) -> Bool {
        NSRequiresConcreteImplementation()
    }

// Re-enable once run loop is compiled on all platforms

    public func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        NSUnimplemented()
    }
    
    public func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        NSUnimplemented()
    }
    
    public var streamStatus: Status {
        NSRequiresConcreteImplementation()
    }
    
    /*@NSCopying */public var streamError: NSError? {
        NSRequiresConcreteImplementation()
    }
    
    public override func copy() -> AnyObject {
        return self
    }
    
    public func copy(with zone: NSZone?) -> AnyObject {
        return self
    }
}

internal final class _SwiftInputStream : NSInputStream, _SwiftNativeFoundationType {
    internal typealias ImmutableType = NSInputStream
    internal typealias MutableType = NSMutableData
    
    var __wrapped : _MutableUnmanagedWrapper<ImmutableType, MutableType>
    
    init(immutableObject: AnyObject) {
        // Take ownership.
        __wrapped = .Immutable(Unmanaged.passRetained(_unsafeReferenceCast(immutableObject, to: ImmutableType.self)))
        super.init(data:Data())
    }
    
    init(mutableObject: AnyObject) {
        // Take ownership.
        __wrapped = .Mutable(Unmanaged.passRetained(_unsafeReferenceCast(mutableObject, to: MutableType.self)))
        super.init(data:Data())
    }
    
    internal required init(unmanagedImmutableObject: Unmanaged<ImmutableType>) {
        // Take ownership.
        __wrapped = .Immutable(unmanagedImmutableObject)
        
        super.init(data:Data())
    }
    
    internal required init(unmanagedMutableObject: Unmanaged<MutableType>) {
        // Take ownership.
        __wrapped = .Mutable(unmanagedMutableObject)
        
        super.init(data:Data())
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required convenience init() {
        self.init(immutableObject: NSInputStream(data:Data()))
    }
    
    deinit {
        releaseWrappedObject()
    }
    
    // Stubs
    // -----
    
    func isEqual(to other: NSInputStream) -> Bool {
        return true
    }
    
}

public struct InputStream: ReferenceConvertible, CustomStringConvertible, Equatable, Hashable,_MutablePairBoxing{
    public typealias ReferenceType = NSInputStream
    internal var _wrapped : _SwiftInputStream =  _SwiftInputStream()

    
    public var streamError:NSError? {
        return _wrapped._mapUnmanaged{ return $0.streamError }
    }
    
    public var hasBytesAvailable:Bool {
        return _wrapped._mapUnmanaged{ return $0.hasBytesAvailable }
    }
    
    public var streamStatus: NSStream.Status {
        return NSStream.Status(rawValue: UInt(CFReadStreamGetStatus(_wrapped._mapUnmanaged{ return $0._stream })))!
    }
    
    public init(data: Data) {
        _wrapped = _SwiftInputStream(immutableObject: NSInputStream(data: data))
    }
    
    public init?(url: URL) {
        guard let nsis = NSInputStream(url:url) else { return nil }
        _wrapped = _SwiftInputStream(immutableObject: nsis)
    }
    
    public init?(fileAtPath path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }
    
    public func open() {
        _wrapped._mapUnmanaged{ $0.open() }
    }
    
    public func close() {
        _wrapped._mapUnmanaged{ $0.close() }
    }
    
    public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return _wrapped._mapUnmanaged{ return $0.read(buffer, maxLength: len) }
    }
    
    public func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        return _wrapped._mapUnmanaged{ return $0.getBuffer(buffer, length: len) }
    }
    
    public func setProperty(_ property: AnyObject?, forKey key: String) -> Bool {
        return _wrapped._mapUnmanaged{ return $0.setProperty(property, forKey: key) }
    }
    
    public  func propertyForKey(_ key: String) -> AnyObject? {
        return _wrapped._mapUnmanaged{ return $0.propertyForKey(key) }
    }
    public var description: String { return "" }

    public var debugDescription: String { return "" }
    
    public var hashValue: Int { return 1 }


}

public func ==(d1 : InputStream, d2 : InputStream) -> Bool {
    return d1._wrapped.isEqual(to: d2._wrapped._mapUnmanaged{return $0})
}


// NSInputStream is an abstract class representing the base functionality of a read stream.
// Subclassers are required to implement these methods.
public class NSInputStream: NSStream {

    private var _stream: CFReadStream!
    
    // reads up to length bytes into the supplied buffer, which must be at least of size len. Returns the actual number of bytes read.
    public func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return CFReadStreamRead(_stream, buffer, CFIndex(len._bridgeToObject()))
    }
    
    // returns in O(1) a pointer to the buffer in 'buffer' and by reference in 'len' how many bytes are available. This buffer is only valid until the next stream operation. Subclassers may return NO for this if it is not appropriate for the stream type. This may return NO if the buffer is not available.
    public func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        guard let bufPtr = CFReadStreamGetBuffer(_stream, 0, len) else { return false }
        buffer.pointee = UnsafeMutablePointer<UInt8>(bufPtr)
        return true
    }
    
    // returns YES if the stream has bytes available or if it impossible to tell without actually doing the read.
    public var hasBytesAvailable: Bool {
        return CFReadStreamHasBytesAvailable(_stream)
    }
    
    public init(data: Data) {
        _stream = CFReadStreamCreateWithData(kCFAllocatorSystemDefault, data._cfObject)
    }
    
    public init?(url: URL) {
        _stream = CFReadStreamCreateWithFile(kCFAllocatorDefault, url._cfObject)
    }

    public static func initialize(url:URL) -> CFReadStream{
        return CFReadStreamCreateWithFile(kCFAllocatorDefault, url._cfObject)
    }
    
    public convenience init?(fileAtPath path: String) {
        self.init(url: URL(fileURLWithPath: path))
    }

    public override func open() {
        CFReadStreamOpen(_stream)
    }
    
    public override func close() {
        CFReadStreamClose(_stream)
    }
    
    override public var streamError: NSError?{
        let error = CFReadStreamCopyError(_stream)
        return error?._nsObject
    }
    
    public override var streamStatus: Status {
        return NSStream.Status(rawValue: UInt(CFReadStreamGetStatus(_stream)))!
    }
    
    public override func setProperty(_ property: AnyObject?, forKey key: String) -> Bool {
        return CFReadStreamSetProperty(_stream, key._cfObject, property)
    }
    
    public override func propertyForKey(_ key: String) -> AnyObject? {
        return CFReadStreamCopyProperty(_stream, key._cfObject)
    }

}

// NSOutputStream is an abstract class representing the base functionality of a write stream.
// Subclassers are required to implement these methods.
// Currently this is left as named NSOutputStream due to conflicts with the standard library's text streaming target protocol named OutputStream (which ideally should be renamed)
public class NSOutputStream : NSStream {
    
    private  var _stream: CFWriteStream!
    
    // writes the bytes from the specified buffer to the stream up to len bytes. Returns the number of bytes actually written.
    public func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        return  CFWriteStreamWrite(_stream, buffer, len)
    }
    
    // returns YES if the stream can be written to or if it is impossible to tell without actually doing the write.
    public var hasSpaceAvailable: Bool {
        return CFWriteStreamCanAcceptBytes(_stream)
    }
    
    required public init(toMemory: ()) {
        _stream = CFWriteStreamCreateWithAllocatedBuffers(kCFAllocatorDefault, kCFAllocatorDefault)
    }

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
    
    public override func open() {
        CFWriteStreamOpen(_stream)
    }
    
    public override func close() {
        CFWriteStreamClose(_stream)
    }
    
    public override var streamStatus: Status {
        return NSStream.Status(rawValue: UInt(CFWriteStreamGetStatus(_stream)))!
    }
    
    public class func outputStreamToMemory() -> Self {
        return self.init(toMemory: ())
    }
    
    override public var streamError: NSError?{
        let error = CFWriteStreamCopyError(_stream)
        return error?._nsObject
    }
    
    public  override func setProperty(_ property: AnyObject?, forKey key: String) -> Bool {
        return CFWriteStreamSetProperty(_stream, key._cfObject, property)
    }
    
    public override func propertyForKey(_ key: String) -> AnyObject? {
        return CFWriteStreamCopyProperty(_stream, key._cfObject)
    }
}

// Discussion of this API is ongoing for its usage of AutoreleasingUnsafeMutablePointer
#if false
extension Stream {
    public class func getStreamsToHost(withName hostname: String, port: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<NSOutputStream?>?) {
        NSUnimplemented()
    }
}

extension Stream {
    public class func getBoundStreams(withBufferSize bufferSize: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<NSOutputStream?>?) {
        NSUnimplemented()
    }
}
#endif

extension StreamDelegate {
    func stream(_ aStream: NSStream, handleEvent eventCode: NSStream.Event) { }
}

public protocol StreamDelegate : class {
    func stream(_ aStream: NSStream, handleEvent eventCode: NSStream.Event)
}

// NSString constants for the propertyForKey/setProperty:forKey: API
// String constants for the setting of the socket security level.
// use this as the key for setting one of the following values for the security level of the target stream.
public let NSStreamSocketSecurityLevelKey: String = "kCFStreamPropertySocketSecurityLevel"

public let NSStreamSocketSecurityLevelNone: String = "kCFStreamSocketSecurityLevelNone"
public let NSStreamSocketSecurityLevelSSLv2: String = "NSStreamSocketSecurityLevelSSLv2"
public let NSStreamSocketSecurityLevelSSLv3: String = "NSStreamSocketSecurityLevelSSLv3"
public let NSStreamSocketSecurityLevelTLSv1: String = "kCFStreamSocketSecurityLevelTLSv1"
public let NSStreamSocketSecurityLevelNegotiatedSSL: String = "kCFStreamSocketSecurityLevelNegotiatedSSL"

public let NSStreamSOCKSProxyConfigurationKey: String  = "kCFStreamPropertySOCKSProxy"
// Value is an NSDictionary containing the key/value pairs below. The dictionary returned from SystemConfiguration for SOCKS proxies will work without alteration.

public let NSStreamSOCKSProxyHostKey: String = "NSStreamSOCKSProxyKey"
// Value is an NSString
public let NSStreamSOCKSProxyPortKey: String = "NSStreamSOCKSPortKey"
// Value is an NSNumber
public let NSStreamSOCKSProxyVersionKey: String = "kCFStreamPropertySOCKSVersion"
// Value is one of NSStreamSOCKSProxyVersion4 or NSStreamSOCKSProxyVersion5
public let NSStreamSOCKSProxyUserKey: String = "kCFStreamPropertySOCKSUser"
// Value is an NSString
public let NSStreamSOCKSProxyPasswordKey: String = "kCFStreamPropertySOCKSPassword"
// Value is an NSString

public let NSStreamSOCKSProxyVersion4: String = "kCFStreamSocketSOCKSVersion4"
// Value for NSStreamSOCKProxyVersionKey
public let NSStreamSOCKSProxyVersion5: String = "kCFStreamSocketSOCKSVersion5"
// Value for NSStreamSOCKProxyVersionKey

public let NSStreamDataWrittenToMemoryStreamKey: String = "kCFStreamPropertyDataWritten"
// Key for obtaining the data written to a memory stream.

public let NSStreamFileCurrentOffsetKey: String = "kCFStreamPropertyFileCurrentOffset"
// Value is an NSNumber representing the current absolute offset of the stream.

// NSString constants for error domains.
public let NSStreamSocketSSLErrorDomain: String = "NSStreamSocketSSLErrorDomain"
// SSL errors are to be interpreted via <Security/SecureTransport.h>
public let NSStreamSOCKSErrorDomain: String = "NSStreamSOCKSErrorDomain"

// Property key to specify the type of service for the stream.  This
// allows the system to properly handle the request with respect to
// routing, suspension behavior and other networking related attributes
// appropriate for the given service type.  The service types supported
// are documented below.
public let NSStreamNetworkServiceType: String = "kCFStreamNetworkServiceType"
// Supported network service types:
public let NSStreamNetworkServiceTypeVoIP: String = "kCFStreamNetworkServiceTypeVoIP"
public let NSStreamNetworkServiceTypeVideo: String = "kCFStreamNetworkServiceTypeVideo"
public let NSStreamNetworkServiceTypeBackground: String = "kCFStreamNetworkServiceTypeBackground"
public let NSStreamNetworkServiceTypeVoice: String = "kCFStreamNetworkServiceTypeVoice"

