// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public enum NSStreamStatus : UInt {
    
    case NotOpen
    case Opening
    case Open
    case Reading
    case Writing
    case AtEnd
    case Closed
    case Error
}

public struct NSStreamEvent : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let OpenCompleted = NSStreamEvent(rawValue: 1 << 0)
    public static let HasBytesAvailable = NSStreamEvent(rawValue: 1 << 1)
    public static let HasSpaceAvailable = NSStreamEvent(rawValue: 1 << 2)
    public static let ErrorOccurred = NSStreamEvent(rawValue: 1 << 3)
    public static let EndEncountered = NSStreamEvent(rawValue: 1 << 4)
}

// NSStream is an abstract class encapsulating the common API to NSInputStream and NSOutputStream.
// Subclassers of NSInputStream and NSOutputStream must also implement these methods.
public class NSStream : NSObject {
    
    public override init() {
        
    }
    
    public func open() {
        NSUnimplemented()
    }
    
    public func close() {
        NSUnimplemented()
    }
    
    public weak var delegate: NSStreamDelegate?
    // By default, a stream is its own delegate, and subclassers of NSInputStream and NSOutputStream must maintain this contract. [someStream setDelegate:nil] must restore this behavior. As usual, delegates are not retained.
    
    public func propertyForKey(key: String) -> AnyObject? {
        NSUnimplemented()
    }
    
    public func setProperty(property: AnyObject?, forKey key: String) -> Bool {
        NSUnimplemented()
    }

// Re-enable once run loop is compiled on all platforms
#if false
    public func scheduleInRunLoop(aRunLoop: NSRunLoop, forMode mode: String) {
        NSUnimplemented()
    }
    
    public func removeFromRunLoop(aRunLoop: NSRunLoop, forMode mode: String) {
        NSUnimplemented()
    }
#endif
    
    public var streamStatus: NSStreamStatus {
        NSUnimplemented()
    }
    
    /*@NSCopying */public var streamError: NSError? {
        NSUnimplemented()
    }
}

// NSInputStream is an abstract class representing the base functionality of a read stream.
// Subclassers are required to implement these methods.
public class NSInputStream : NSStream {
    // reads up to length bytes into the supplied buffer, which must be at least of size len. Returns the actual number of bytes read.
    public func read(buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        NSUnimplemented()
    }
    
    // returns in O(1) a pointer to the buffer in 'buffer' and by reference in 'len' how many bytes are available. This buffer is only valid until the next stream operation. Subclassers may return NO for this if it is not appropriate for the stream type. This may return NO if the buffer is not available.
    public func getBuffer(buffer: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>>, length len: UnsafeMutablePointer<Int>) -> Bool {
        NSUnimplemented()
    }
    
    // returns YES if the stream has bytes available or if it impossible to tell without actually doing the read.
    public var hasBytesAvailable: Bool {
        NSUnimplemented()
    }
    
    public init(data: NSData) {
        NSUnimplemented()
    }
    
    public init?(URL url: NSURL) {
        NSUnimplemented()
    }

    public convenience init?(fileAtPath path: String) {
        NSUnimplemented()
    }
}

// NSOutputStream is an abstract class representing the base functionality of a write stream.
// Subclassers are required to implement these methods.
public class NSOutputStream : NSStream {
    // writes the bytes from the specified buffer to the stream up to len bytes. Returns the number of bytes actually written.
    public func write(buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        NSUnimplemented()
    }
    
    // returns YES if the stream can be written to or if it is impossible to tell without actually doing the write.
    public var hasSpaceAvailable: Bool {
        NSUnimplemented()
    }
    
    public init(toMemory: ()) {
        NSUnimplemented()
    }

    public init(toBuffer buffer: UnsafeMutablePointer<UInt8>, capacity: Int) {
        NSUnimplemented()
    }

    public init?(URL url: NSURL, append shouldAppend: Bool) {
        NSUnimplemented()
    }
    
    public convenience init?(toFileAtPath path: String, append shouldAppend: Bool) {
        NSUnimplemented()
    }
    
    public class func outputStreamToMemory() -> Self {
        NSUnimplemented()
    }
}

// Discussion of this API is ongoing for its usage of AutoreleasingUnsafeMutablePointer
#if false
extension NSStream {
    public class func getStreamsToHostWithName(hostname: String, port: Int, inputStream: AutoreleasingUnsafeMutablePointer<NSInputStream?>, outputStream: AutoreleasingUnsafeMutablePointer<NSOutputStream?>) {
        NSUnimplemented()
    }
}

extension NSStream {
    public class func getBoundStreamsWithBufferSize(bufferSize: Int, inputStream: AutoreleasingUnsafeMutablePointer<NSInputStream?>, outputStream: AutoreleasingUnsafeMutablePointer<NSOutputStream?>) {
        NSUnimplemented()
    }
}
#endif

extension NSStreamDelegate {
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) { }
}

public protocol NSStreamDelegate : class {
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent)
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

