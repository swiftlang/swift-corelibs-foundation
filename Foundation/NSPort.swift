// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public typealias NSSocketNativeHandle = Int32

public let NSPortDidBecomeInvalidNotification: String = "NSPortDidBecomeInvalidNotification"

public class NSPort : NSObject, NSCopying, NSCoding {
    
    public override init() {
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        NSUnimplemented()
    }
    
    public func invalidate() {
        NSUnimplemented()
    }

    public var valid: Bool {
        NSUnimplemented()
    }
    
    // TODO: this delegate situation is confusing on all platforms
    /*
    public func setDelegate(anObject: NSPortDelegate?)
    public func delegate() -> NSPortDelegate?
    */
    
    // These two methods should be implemented by subclasses
    // to setup monitoring of the port when added to a run loop,
    // and stop monitoring if needed when removed;
    // These methods should not be called directly!
//    public func scheduleInRunLoop(runLoop: NSRunLoop, forMode mode: String) {
//        NSUnimplemented()
//    }
//
//    public func removeFromRunLoop(runLoop: NSRunLoop, forMode mode: String) {
//        NSUnimplemented()
//    }
    
    public var reservedSpaceLength: Int {
        return 0
    }
    
    public func sendBeforeDate(limitDate: NSDate, components: NSMutableArray?, from receivePort: NSPort?, reserved headerSpaceReserved: Int) -> Bool {
        NSUnimplemented()
    }

    public func sendBeforeDate(limitDate: NSDate, msgid msgID: Int, components: NSMutableArray?, from receivePort: NSPort?, reserved headerSpaceReserved: Int) -> Bool {
        NSUnimplemented()
    }
}

extension NSPortDelegate {
    func handlePortMessage(message: NSPortMessage) { }
}

public protocol NSPortDelegate : class {
    func handlePortMessage(message: NSPortMessage)
}

// A subclass of NSPort which can be used for local
// message sending on all platforms.

public class NSMessagePort : NSPort {
}

// A subclass of NSPort which can be used for remote
// message sending on all platforms.

public class NSSocketPort : NSPort {
    
    public convenience override init() {
        NSUnimplemented()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public convenience init?(TCPPort port: UInt16) {
        NSUnimplemented()
    }
    
    public init?(protocolFamily family: Int32, socketType type: Int32, `protocol`: Int32, address: NSData) {
        NSUnimplemented()
    }
    
    public init?(protocolFamily family: Int32, socketType type: Int32, `protocol`: Int32, socket sock: NSSocketNativeHandle) {
        NSUnimplemented()
    }
    
    public convenience init?(remoteWithTCPPort port: UInt16, host hostName: String?) {
        NSUnimplemented()
    }
    
    public init(remoteWithProtocolFamily family: Int32, socketType type: Int32, `protocol`: Int32, address: NSData) {
        NSUnimplemented()
    }

    public var protocolFamily: Int32 {
        NSUnimplemented()
    }
    
    public var socketType: Int32 {
        NSUnimplemented()
    }
    
    public var `protocol`: Int32 {
        NSUnimplemented()
    }
    
    /*@NSCopying*/ public var address: NSData {
        NSUnimplemented()
    }
    
    public var socket: NSSocketNativeHandle {
        NSUnimplemented()
    }
}

