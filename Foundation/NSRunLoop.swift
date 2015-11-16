// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public let NSDefaultRunLoopMode: String = "" // NSUnimplemented
public let NSRunLoopCommonModes: String = "" // NSUnimplemented

public class NSRunLoop : NSObject {
    
    public class func currentRunLoop() -> NSRunLoop {
        NSUnimplemented()
    }
    
    public class func mainRunLoop() -> NSRunLoop {
        NSUnimplemented()
    }
    
    public var currentMode: String? {
        NSUnimplemented()
    }
    
    public func addTimer(timer: NSTimer, forMode mode: String) {
        NSUnimplemented()
    }
    
    public func addPort(aPort: NSPort, forMode mode: String) {
        NSUnimplemented()
    }

    public func removePort(aPort: NSPort, forMode mode: String) {
        NSUnimplemented()
    }
    
    public func limitDateForMode(mode: String) -> NSDate? {
        NSUnimplemented()
    }

    public func acceptInputForMode(mode: String, beforeDate limitDate: NSDate) {
        NSUnimplemented()
    }

}

extension NSRunLoop {
    
    public func run() {
        NSUnimplemented()
    }

    public func runUntilDate(limitDate: NSDate) {
        NSUnimplemented()
    }

    public func runMode(mode: String, beforeDate limitDate: NSDate) -> Bool {
        NSUnimplemented()
    }

}

