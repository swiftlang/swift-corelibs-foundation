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

extension Stream {
    internal func _handleStreamEvent(_ event:CFStreamEventType){
        switch event {
        case CFStreamEventType.errorOccurred:
            delegate?.stream(self, handleEvent: Stream.Event.errorOccurred)
        case CFStreamEventType.endEncountered:
            delegate?.stream(self, handleEvent: Stream.Event.endEncountered)
        case CFStreamEventType.hasBytesAvailable:
            delegate?.stream(self, handleEvent: Stream.Event.hasBytesAvailable)
        case CFStreamEventType.openCompleted:
            delegate?.stream(self, handleEvent: Stream.Event.openCompleted)
        case CFStreamEventType.canAcceptBytes:
            delegate?.stream(self, handleEvent: Stream.Event.hasSpaceAvailable)
        default: break
        }
    }
}

// Stream is an abstract class encapsulating the common API to NSInputStream and NSOutputStream.
// Subclassers of NSInputStream and NSOutputStream must also implement these methods.
open class Stream: NSObject {

    internal override init() {}
    
    internal lazy var _defaultEventOptions = CFStreamEventType.canAcceptBytes.rawValue    |
                                             CFStreamEventType.hasBytesAvailable.rawValue |
                                             CFStreamEventType.errorOccurred.rawValue     |
                                             CFStreamEventType.endEncountered.rawValue    |
                                             CFStreamEventType.openCompleted.rawValue
    
    open func open() {
        NSRequiresConcreteImplementation()
    }
    
    open func close() {
        NSRequiresConcreteImplementation()
    }
    
    open weak var delegate: StreamDelegate?
    // By default, a stream is its own delegate, and subclassers of NSInputStream and NSOutputStream must maintain this contract. [someStream setDelegate:nil] must restore this behavior. As usual, delegates are not retained.
    
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
    
    open var streamError: NSError? {
        NSRequiresConcreteImplementation()
    }
}

// NSInputStream is an abstract class representing the base functionality of a read stream.
// Subclassers are required to implement these methods.
open class InputStream: Stream {

    private var _stream: CFReadStream!
    
    private lazy var _cb : CFReadStreamClientCallBack =  { (stream, event, data) in
        let inStream = unsafeBitCast(data, to: InputStream.self)
        inStream._handleStreamEvent(event)
    }
   
    open override var delegate: StreamDelegate?{
        didSet{
            switch  (delegate, oldValue) {
                case (.none , .some): _removeReadStreamClient()
                case (.some , .none): _setReadStreamClient()
                default: break 
            }
        }
    }
    
    private func _setReadStreamClient(){
        
        var ctx = CFStreamClientContext(version: CFIndex(0),
                                           info: Unmanaged.passUnretained(self).toOpaque(),
                                         retain: nil,
                                        release: nil,
                                copyDescription: nil)
        
        CFReadStreamSetClient(_stream, _defaultEventOptions, _cb, &ctx)
    }
    
    private func _removeReadStreamClient(){
                                      //should be .none per docs but cant find it on CFStreamEventType
        CFReadStreamSetClient(_stream, 0, nil, nil)
    }
    
    // reads up to length bytes into the supplied buffer, which must be at least of size len. Returns the actual number of bytes read.
    open func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        return CFReadStreamRead(_stream, buffer, CFIndex(len._bridgeToObjectiveC()))
    }
    
    // returns in O(1) a pointer to the buffer in 'buffer' and by reference in 'len' how many bytes are available. This buffer is only valid until the next stream operation. Subclassers may return NO for this if it is not appropriate for the stream type. This may return NO if the buffer is not available.
    open func getBuffer(_ buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>, length len: UnsafeMutablePointer<Int>) -> Bool {
        guard let bufPtr = CFReadStreamGetBuffer(_stream, 0, len) else { return false }
        buffer.pointee = UnsafeMutablePointer<UInt8>(mutating: bufPtr)
        return true
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

    open override var streamError: NSError?{
        let error = CFReadStreamCopyError(_stream)
        return error?._nsObject
    }
    
    open override var streamStatus: Status {
        return Stream.Status(rawValue: UInt(CFReadStreamGetStatus(_stream)))!
    }

    open override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFReadStreamScheduleWithRunLoop(_stream, aRunLoop._cfRunLoop, mode.rawValue._cfObject)
    }
    
    open override func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFReadStreamUnscheduleFromRunLoop(_stream, aRunLoop._cfRunLoop, mode.rawValue._cfObject)
    }
    
    open override func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
        guard let property = property else { return false }
        return CFReadStreamSetProperty(_stream, key.rawValue._cfObject, property)
    }
    
    open override func property(forKey key: PropertyKey) -> AnyObject? {
        return CFReadStreamCopyProperty(_stream, key.rawValue._cfObject)
    }
    
    deinit {
        _removeReadStreamClient()
    }
}

// NSOutputStream is an abstract class representing the base functionality of a write stream.
// Subclassers are required to implement these methods.
// Currently this is left as named NSOutputStream due to conflicts with the standard library's text streaming target protocol named OutputStream (which ideally should be renamed)
open class NSOutputStream : Stream {
    
    private var _stream: CFWriteStream!
    
    open override var delegate: StreamDelegate?{
        didSet{
            switch (delegate, oldValue) {
            case (.none , .some): _removeWriteStreamClient()
            case (.some , .none): _setWriteStreamClient()
            default: break
            }
        }
    }
    
    private lazy var _cb : CFWriteStreamClientCallBack =  { (stream, event, data) in
        let outStream = unsafeBitCast(data, to: NSOutputStream.self)
        outStream._handleStreamEvent(event)
    }

    private func _setWriteStreamClient(){
        var ctx = CFStreamClientContext(version: CFIndex(0),
                                           info: Unmanaged.passUnretained(self).toOpaque(),
                                         retain: nil,
                                        release: nil,
                                copyDescription: nil)

        CFWriteStreamSetClient(_stream, _defaultEventOptions, _cb, &ctx)
    }
    
    
    private func _removeWriteStreamClient(){
                                       //should be .none per docs but cant find it on CFStreamEventType
        CFWriteStreamSetClient(_stream, 0, nil, nil)
    }

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

    open override var streamError: NSError?{
        let error = CFWriteStreamCopyError(_stream)
        return error?._nsObject
    }
    
    open override func setProperty(_ property: AnyObject?, forKey key: PropertyKey) -> Bool {
        guard let property = property else { return false }
        return CFWriteStreamSetProperty(_stream, key.rawValue._cfObject, property)
    }
    
    open override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFWriteStreamScheduleWithRunLoop(_stream, aRunLoop._cfRunLoop, mode.rawValue._cfObject)
    }
    
    open override func remove(from aRunLoop: RunLoop, forMode mode: RunLoopMode) {
        CFWriteStreamUnscheduleFromRunLoop(_stream, aRunLoop._cfRunLoop, mode.rawValue._cfObject)
    }
    
    deinit {
        _removeWriteStreamClient()
    }

}

#if false
// Discussion of this API is ongoing for its usage of AutoreleasingUnsafeMutablePointer
extension Stream {
    open class func getStreamsToHost(withName hostname: String, port: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<NSOutputStream?>?) {
        NSUnimplemented()
    }
}

extension Stream {
    open class func getBoundStreams(withBufferSize bufferSize: Int, inputStream: AutoreleasingUnsafeMutablePointer<InputStream?>?, outputStream: AutoreleasingUnsafeMutablePointer<NSOutputStream?>?) {
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
    public static let ssLv2 = StreamSocketSecurityLevel(rawValue: "kCFStreamSocketSecurityLevelSSLv2")
    public static let ssLv3 = StreamSocketSecurityLevel(rawValue: "kCFStreamSocketSecurityLevelSSLv3")
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
    public static let hostKey = StreamSOCKSProxyConfiguration(rawValue: "kCFStreamPropertySOCKSProxyHost")
    public static let portKey = StreamSOCKSProxyConfiguration(rawValue: "kCFStreamPropertySOCKSProxyPort")
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
public let NSStreamSocketSSLErrorDomain: String = "kCFStreamErrorDomainSSL"
// SSL errors are to be interpreted via <Security/SecureTransport.h>
public let NSStreamSOCKSErrorDomain: String = "kCFStreamErrorDomainSOCKS"

