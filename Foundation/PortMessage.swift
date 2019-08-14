// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


open class PortMessage : NSObject, NSCopying {
    public init(sendPort: Port?, receivePort replyPort: Port?, components: [AnyObject]?) {
        self.sendPort = sendPort
        self.receivePort = replyPort
        self.components = components
    }
    
    open var msgid: UInt32 = 0
    
    open private(set) var components: [AnyObject]?
    open private(set) var receivePort: Port?
    open private(set) var sendPort: Port?
    
    open func sendBeforeDate(_ date: Date) -> Bool {
        return sendPort?.sendBeforeDate(date, msgid: Int(msgid), components: NSMutableArray(array: components ?? []), from: receivePort, reserved: 0) ?? false
    }
    
    public func copy(with zone: NSZone?) -> Any {
        return self
    }
}
