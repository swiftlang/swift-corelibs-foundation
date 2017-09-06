// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@available(*,deprecated,message:"Not available on non-Darwin platforms")
open class PortMessage : NSObject {
    
    public init(sendPort: Port?, receivePort replyPort: Port?, components: [AnyObject]?) {
        NSUnsupported()
    }
    
    open var components: [AnyObject]? {
        NSUnsupported()
    }
    
    open var receivePort: Port? {
        NSUnsupported()
    }
    
    open var sendPort: Port? {
        NSUnsupported()
    }
    
    open func sendBeforeDate(_ date: Date) -> Bool {
        NSUnsupported()
    }
    
    open var msgid: UInt32
}
