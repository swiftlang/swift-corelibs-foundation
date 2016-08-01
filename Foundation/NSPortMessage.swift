// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


open class PortMessage : NSObject {
    
    public init(sendPort: Port?, receivePort replyPort: Port?, components: [AnyObject]?) {
        NSUnimplemented()
    }
    
    open var components: [AnyObject]? {
        NSUnimplemented()
    }
    
    open var receivePort: Port? {
        NSUnimplemented()
    }
    
    open var sendPort: Port? {
        NSUnimplemented()
    }
    
    open func sendBeforeDate(_ date: Date) -> Bool {
        NSUnimplemented()
    }
    
    open var msgid: UInt32
}
