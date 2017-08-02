// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public typealias SocketNativeHandle = Int32

extension Port {
    public static let didBecomeInvalidNotification  = NSNotification.Name(rawValue:  "NSPortDidBecomeInvalidNotification")
}

open class Port : NSObject, NSCopying, NSCoding {
    
    
    public override init() {
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func encode(with aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        NSUnimplemented()
    }
    
    open func invalidate() {
        NSUnimplemented()
    }

    open var isValid: Bool {
        NSUnimplemented()
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
        NSUnimplemented()
    }

    open func remove(from runLoop: RunLoop, forMode mode: RunLoopMode) {
        NSUnimplemented()
    }
    
    open var reservedSpaceLength: Int {
        return 0
    }
    
    open func sendBeforeDate(_ limitDate: Date, components: NSMutableArray?, from receivePort: Port?, reserved headerSpaceReserved: Int) -> Bool {
        NSUnimplemented()
    }

    open func sendBeforeDate(_ limitDate: Date, msgid msgID: Int, components: NSMutableArray?, from receivePort: Port?, reserved headerSpaceReserved: Int) -> Bool {
        NSUnimplemented()
    }
}

extension PortDelegate {
    func handle(_ message: PortMessage) { }
}

public protocol PortDelegate : class {
    func handlePortMessage(_ message: PortMessage)
}

// A subclass of Port which can be used for local
// message sending on all platforms.

open class MessagePort : Port {
}

// A subclass of Port which can be used for remote
// message sending on all platforms.

open class SocketPort : Port {
    
    public convenience override init() {
        NSUnimplemented()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public convenience init?(tcpPort port: UInt16) {
        NSUnimplemented()
    }
    
    public init?(protocolFamily family: Int32, socketType type: Int32, protocol: Int32, address: Data) {
        NSUnimplemented()
    }
    
    public init?(protocolFamily family: Int32, socketType type: Int32, protocol: Int32, socket sock: SocketNativeHandle) {
        NSUnimplemented()
    }
    
    public convenience init?(remoteWithTCPPort port: UInt16, host hostName: String?) {
        NSUnimplemented()
    }
    
    public init(remoteWithProtocolFamily family: Int32, socketType type: Int32, protocol: Int32, address: Data) {
        NSUnimplemented()
    }

    open var protocolFamily: Int32 {
        NSUnimplemented()
    }
    
    open var socketType: Int32 {
        NSUnimplemented()
    }
    
    open var `protocol`: Int32 {
        NSUnimplemented()
    }
    
    open var address: Data {
        NSUnimplemented()
    }
    
    open var socket: SocketNativeHandle {
        NSUnimplemented()
    }
}

