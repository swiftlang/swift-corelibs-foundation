// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

public enum NSTaskTerminationReason : Int {
    case Exit
    case UncaughtSignal
}

private func WEXITSTATUS(status: CInt) -> CInt {
    return (status >> 8) & 0xff
}


private var processMap : [pid_t : NSTask] = [:]
private var processLaunchLock = NSLock()

private var managerThreadSetupOnceToken = pthread_once_t()
private var threadID = pthread_t()

private let semaphore = sem_open("_NSTaskRunLoopSemaphore", O_CREAT, 0o777, 0)

@noreturn private func managerThread(x: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> {
    
    while true {
        sem_wait( semaphore )
        
        // Block for any child process to finish
        
        var status = Int32()
        let pid = waitpid( 0, &status, 0 )
        
        // Lock
        
        processLaunchLock.lock()
        
        // Get the associated NSTask object
        
        if let task = processMap[pid] {
            
            // Get the exit status (TODO: handle the different kinds of exits)
            
            task.terminationStatus = WEXITSTATUS( status )
            
            // If a termination handler has been set, invoke it on a background thread
            
            if task.terminationHandler != nil {
                var threadID = pthread_t()
                pthread_create(&threadID, nil, { (context) -> UnsafeMutablePointer<Void> in
                    
                    let unmanagedTask : Unmanaged<NSTask> = Unmanaged.fromOpaque(context)
                    let task = unmanagedTask.takeRetainedValue()
                    
                    task.terminationHandler!( task )
                    return context
                    
                    }, UnsafeMutablePointer<Void>(Unmanaged.passRetained(task).toOpaque()))
            }
            
            // Set the running flag to false
            
            task.running = false
            
            // Invalidate the source and wake up the run loop, if it's available
            
            CFRunLoopSourceInvalidate(task.runLoopSource)
            if let runLoop = task.runLoop {
                CFRunLoopWakeUp(runLoop._cfRunLoop)
            }
        }
        
        // Clear out the NSTask from the process table
        
        processMap[pid] = nil
        
        processLaunchLock.unlock()
    }
}

private func runLoopCallback(context : UnsafeMutablePointer<Void>) -> Void {}

private func managerThreadSetup() -> Void {
    pthread_create(&threadID, nil, managerThread, nil)
}


// Equal method for run loop source
private func nstaskIsEqual(a : UnsafePointer<Void>, b : UnsafePointer<Void>) -> Bool {
    
    let unmanagedTaskA = Unmanaged<AnyObject>.fromOpaque(COpaquePointer(a))
    guard let taskA = unmanagedTaskA.takeUnretainedValue() as? NSTask else {
        return false
    }
    
    let unmanagedTaskB = Unmanaged<AnyObject>.fromOpaque(COpaquePointer(a))
    guard let taskB = unmanagedTaskB.takeUnretainedValue() as? NSTask else {
        return false
    }
    
    guard taskA == taskB else {
        return false
    }
    
    return true
}

// Retain method for run loop source
private func nstaskRetain(pointer : UnsafePointer<Void>) -> UnsafePointer<Void> {
    let _ = Unmanaged<AnyObject>.fromOpaque(COpaquePointer(pointer)).retain()
    return pointer
}

// Release method for run loop source
private func nstaskRelease(pointer : UnsafePointer<Void>) -> Void {
    let _ = Unmanaged<AnyObject>.fromOpaque(COpaquePointer(pointer)).release()
}

public class NSTask : NSObject {
    
    // Create an NSTask which can be run at a later time
    // An NSTask can only be run once. Subsequent attempts to
    // run an NSTask will raise.
    // Upon task death a notification will be sent
    //   { Name = NSTaskDidTerminateNotification; object = task; }
    //
    
    public override init() {
    
    }
    
    // these methods can only be set before a launch
    public var launchPath: String?
    public var arguments: [String]?
    public var environment: [String : String]? // if not set, use current
    
    public var currentDirectoryPath: String = NSFileManager.defaultInstance.currentDirectoryPath
    
    // standard I/O channels; could be either an NSFileHandle or an NSPipe
    public var standardInput: AnyObject?
    public var standardOutput: AnyObject?
    public var standardError: AnyObject?
    
    private var runLoopSourceContext : CFRunLoopSourceContext?
    private var runLoopSource : CFRunLoopSource?
    
    private weak var runLoop : NSRunLoop? = nil
    
    // actions
    public func launch() {
    
        // Dispatch the manager thread if it isn't already running
        
        pthread_once(&managerThreadSetupOnceToken, managerThreadSetup)
        
        // Ensure that the launch path is set
        
        guard let launchPath = self.launchPath else {
            fatalError()
        }
        
        // Convert the arguments array into a posix_spawn-friendly format
        
        var args = [launchPath.lastPathComponent]
        if let arguments = self.arguments {
            args.appendContentsOf(arguments)
        }
        
        let argv : UnsafeMutablePointer<UnsafeMutablePointer<Int8>> = args.withUnsafeBufferPointer {
            let array : UnsafeBufferPointer<String> = $0
            let buffer = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(array.count + 1)
            buffer.initializeFrom(array.map { $0.withCString(strdup) })
            buffer[array.count] = nil
            return buffer
        }
        
        defer {
            for arg in argv ..< argv + args.count {
                free(UnsafeMutablePointer<Void>(arg.memory))
            }
            
            argv.dealloc(args.count + 1)
        }
        
        // Lock...
        
        processLaunchLock.lock()
        
        // ...and load
        
        var pid = pid_t()
        let status = posix_spawn(&pid, launchPath, nil, nil, argv, nil)
        
        guard status == 0 else {
            fatalError()
        }
        
        self.runLoop = NSRunLoop.currentRunLoop()
        
        self.runLoopSourceContext = CFRunLoopSourceContext (version: 0, info: UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque()),
                                                                     retain: nstaskRetain, release: nstaskRelease, copyDescription: nil,
                                                                             equal: nstaskIsEqual, hash: nil, schedule: nil, cancel: nil,
                                                                                    perform: runLoopCallback)
        
        self.runLoopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &runLoopSourceContext!)
        CFRunLoopAddSource(NSRunLoop.currentRunLoop()._cfRunLoop, runLoopSource, kCFRunLoopDefaultMode)
        
        running = true
        
        self.processIdentifier = pid
        processMap[pid] = self
        
        processLaunchLock.unlock()
        
        // Signal the run loop
        sem_post(semaphore)
    }
    
    public func interrupt() { NSUnimplemented() } // Not always possible. Sends SIGINT.
    public func terminate()  { NSUnimplemented() }// Not always possible. Sends SIGTERM.
    
    public func suspend() -> Bool { NSUnimplemented() }
    public func resume() -> Bool { NSUnimplemented() }
    
    // status
    public private(set) var processIdentifier: Int32 = -1
    public private(set) var running: Bool = false
    
    public private(set) var terminationStatus: Int32 = 0
    public var terminationReason: NSTaskTerminationReason { NSUnimplemented() }
    
    /*
    A block to be invoked when the process underlying the NSTask terminates.  Setting the block to nil is valid, and stops the previous block from being invoked, as long as it hasn't started in any way.  The NSTask is passed as the argument to the block so the block does not have to capture, and thus retain, it.  The block is copied when set.  Only one termination handler block can be set at any time.  The execution context in which the block is invoked is undefined.  If the NSTask has already finished, the block is executed immediately/soon (not necessarily on the current thread).  If a terminationHandler is set on an NSTask, the NSTaskDidTerminateNotification notification is not posted for that task.  Also note that -waitUntilExit won't wait until the terminationHandler has been fully executed.  You cannot use this property in a concrete subclass of NSTask which hasn't been updated to include an implementation of the storage and use of it.  
    */
    public var terminationHandler: ((NSTask) -> Void)?
    public var qualityOfService: NSQualityOfService = .Default  // read-only after the task is launched
}

extension NSTask {
    
    // convenience; create and launch
    public class func launchedTaskWithLaunchPath(path: String, arguments: [String]) -> NSTask {
        let task = NSTask()
        task.launchPath = path
        task.arguments = arguments
        task.launch()
    
        return task
    }
    
    // poll the runLoop in defaultMode until task completes
    public func waitUntilExit() {
        
        repeat {
            
        } while( self.running == true && NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.05)) )
        
        self.runLoop = nil
    }
}

public let NSTaskDidTerminateNotification: String = "NSTaskDidTerminateNotification"


