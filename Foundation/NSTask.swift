// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public enum NSTaskTerminationReason : Int {
    
    case Exit
    case UncaughtSignal
}

public class NSTask : NSObject {
    
    // Create an NSTask which can be run at a later time
    // An NSTask can only be run once. Subsequent attempts to
    // run an NSTask will raise.
    // Upon task death a notification will be sent
    //   { Name = NSTaskDidTerminateNotification; object = task; }
    //
    
    public override init() { NSUnimplemented() }
    
    // these methods can only be set before a launch
    public var launchPath: String?
    public var arguments: [String]?
    public var environment: [String : String]? // if not set, use current
    public var currentDirectoryPath: String // if not set, use current
    
    // standard I/O channels; could be either an NSFileHandle or an NSPipe
    public var standardInput: AnyObject?
    public var standardOutput: AnyObject?
    public var standardError: AnyObject?
    
    // actions
    public func launch() { NSUnimplemented() }
    
    public func interrupt() { NSUnimplemented() } // Not always possible. Sends SIGINT.
    public func terminate()  { NSUnimplemented() }// Not always possible. Sends SIGTERM.
    
    public func suspend() -> Bool { NSUnimplemented() }
    public func resume() -> Bool { NSUnimplemented() }
    
    // status
    public var processIdentifier: Int32  { NSUnimplemented() }
    public var running: Bool  { NSUnimplemented() }
    
    public var terminationStatus: Int32  { NSUnimplemented() }
    public var terminationReason: NSTaskTerminationReason { NSUnimplemented() }
    
    /*
    A block to be invoked when the process underlying the NSTask terminates.  Setting the block to nil is valid, and stops the previous block from being invoked, as long as it hasn't started in any way.  The NSTask is passed as the argument to the block so the block does not have to capture, and thus retain, it.  The block is copied when set.  Only one termination handler block can be set at any time.  The execution context in which the block is invoked is undefined.  If the NSTask has already finished, the block is executed immediately/soon (not necessarily on the current thread).  If a terminationHandler is set on an NSTask, the NSTaskDidTerminateNotification notification is not posted for that task.  Also note that -waitUntilExit won't wait until the terminationHandler has been fully executed.  You cannot use this property in a concrete subclass of NSTask which hasn't been updated to include an implementation of the storage and use of it.  
    */
    public var terminationHandler: ((NSTask) -> Void)?
    public var qualityOfService: NSQualityOfService // read-only after the task is launched
}

extension NSTask {
    
    public class func launchedTaskWithLaunchPath(path: String, arguments: [String]) -> NSTask { NSUnimplemented() }
    // convenience; create and launch
    
    public func waitUntilExit() { NSUnimplemented() }
}

// poll the runLoop in defaultMode until task completes

public let NSTaskDidTerminateNotification: String = "NSTaskDidTerminateNotification"


