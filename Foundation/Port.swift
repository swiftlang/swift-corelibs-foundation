// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@available(*,deprecated,message:"Not available on non-Darwin platforms")
public typealias SocketNativeHandle = Int32

@available(*,deprecated,message:"Not available on non-Darwin platforms")
extension Port {
    public static let didBecomeInvalidNotification  = NSNotification.Name(rawValue:  "NSPortDidBecomeInvalidNotification")
}

@available(*,deprecated,message:"Not available on non-Darwin platforms")
open class Port : NSObject, NSCopying, NSCoding {
    
    
    public override init() {
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnsupported()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnsupported()
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        NSUnsupported()
    }
    
    open func invalidate() {
        NSUnsupported()
    }

    open var isValid: Bool {
        NSUnsupported()
    }
    
    // TODO: this delegate situation is confusing on all platforms
    /*
    open func setDelegate(_ anObject: PortDelegate?)
    open func delegate() -> PortDelegate?
    */
    
    // These two methods should be implemented by subclasses
    // to setup monitoring of the port when added to a run loop,
    // and stop monitoring if needed when removed;
    // These methods should not be called directly!
    open func schedule(in runLoop: RunLoop, forMode mode: RunLoopMode) {
        NSUnsupported()
    }

    open func remove(from runLoop: RunLoop, forMode mode: RunLoopMode) {
        NSUnsupported()
    }
    
    open var reservedSpaceLength: Int {
        return 0
    }
    
    open func sendBeforeDate(_ limitDate: Date, components: NSMutableArray?, from receivePort: Port?, reserved headerSpaceReserved: Int) -> Bool {
        NSUnsupported()
    }

    open func sendBeforeDate(_ limitDate: Date, msgid msgID: Int, components: NSMutableArray?, from receivePort: Port?, reserved headerSpaceReserved: Int) -> Bool {
        NSUnsupported()
    }
}

@available(*,deprecated,message:"Not available on non-Darwin platforms")
extension PortDelegate {
    func handle(_ message: PortMessage) { }
}

@available(*,deprecated,message:"Not available on non-Darwin platforms")
public protocol PortDelegate : class {
    func handlePortMessage(_ message: PortMessage)
}

// A subclass of Port which can be used for local
// message sending on all platforms.

@available(*,deprecated,message:"Not available on non-Darwin platforms")
open class MessagePort : Port {
}

// A subclass of Port which can be used for remote
// message sending on all platforms.

@available(*,deprecated,message:"Not available on non-Darwin platforms")
open class SocketPort : Port {
    
    public convenience override init() {
        NSUnsupported()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnsupported()
    }
    
    public convenience init?(tcpPort port: UInt16) {
        NSUnsupported()
    }
    
    public init?(protocolFamily family: Int32, socketType type: Int32, protocol: Int32, address: Data) {
        NSUnsupported()
    }
    
    public init?(protocolFamily family: Int32, socketType type: Int32, protocol: Int32, socket sock: SocketNativeHandle) {
        NSUnsupported()
    }
    
    public convenience init?(remoteWithTCPPort port: UInt16, host hostName: String?) {
        NSUnsupported()
    }
    
    public init(remoteWithProtocolFamily family: Int32, socketType type: Int32, protocol: Int32, address: Data) {
        NSUnsupported()
    }

    open var protocolFamily: Int32 {
        NSUnsupported()
    }
    
    open var socketType: Int32 {
        NSUnsupported()
    }
    
    open var `protocol`: Int32 {
        NSUnsupported()
    }
    
    open var address: Data {
        NSUnsupported()
    }
    
    open var socket: SocketNativeHandle {
        NSUnsupported()
    }
}

