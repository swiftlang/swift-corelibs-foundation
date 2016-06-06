// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public class PortMessage : NSObject {
    
    public init(sendPort: Port?, receivePort replyPort: Port?, components: [AnyObject]?) {
        NSUnimplemented()
    }
    
    public var components: [AnyObject]? {
        NSUnimplemented()
    }
    
    public var receivePort: Port? {
        NSUnimplemented()
    }
    
    public var sendPort: Port? {
        NSUnimplemented()
    }
    
    public func sendBeforeDate(_ date: Date) -> Bool {
        NSUnimplemented()
    }
    
    public var msgid: UInt32
}
