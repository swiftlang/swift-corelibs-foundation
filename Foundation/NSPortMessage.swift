// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public class NSPortMessage : NSObject {
    
    public init(sendPort: NSPort?, receivePort replyPort: NSPort?, components: [AnyObject]?) {
        NSUnimplemented()
    }
    
    public var components: [AnyObject]? {
        NSUnimplemented()
    }
    
    public var receivePort: NSPort? {
        NSUnimplemented()
    }
    
    public var sendPort: NSPort? {
        NSUnimplemented()
    }
    
    public func sendBeforeDate(_ date: NSDate) -> Bool {
        NSUnimplemented()
    }
    
    public var msgid: UInt32
}
