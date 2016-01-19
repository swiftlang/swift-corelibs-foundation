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

private var managerThreadSetupOnceToken = pthread_once_t()
private var threadID = pthread_t()

private var managerThreadRunLoop : NSRunLoop? = nil
private var managerThreadRunLoopIsRunning = false
private var managerThreadRunLoopIsRunningCondition = NSCondition()

#if os(OSX) || os(iOS)
internal let kCFSocketDataCallBack = CFSocketCallBackType.DataCallBack.rawValue
#endif

private func emptyRunLoopCallback(context : UnsafeMutablePointer<Void>) -> Void {}


// Retain method for run loop source
private func runLoopSourceRetain(pointer : UnsafePointer<Void>) -> UnsafePointer<Void> {
    let _ = Unmanaged<AnyObject>.fromOpaque(COpaquePointer(pointer)).retain()
    return pointer
}

// Release method for run loop source
private func runLoopSourceRelease(pointer : UnsafePointer<Void>) -> Void {
    Unmanaged<AnyObject>.fromOpaque(COpaquePointer(pointer)).release()
}

// Equal method for run loop source

private func runloopIsEqual(a : UnsafePointer<Void>, b : UnsafePointer<Void>) -> _DarwinCompatibleBoolean {
    
    let unmanagedrunLoopA = Unmanaged<AnyObject>.fromOpaque(COpaquePointer(a))
    guard let runLoopA = unmanagedrunLoopA.takeUnretainedValue() as? NSRunLoop else {
        return false
    }
    
    let unmanagedRunLoopB = Unmanaged<AnyObject>.fromOpaque(COpaquePointer(a))
    guard let runLoopB = unmanagedRunLoopB.takeUnretainedValue() as? NSRunLoop else {
        return false
    }
    
    guard runLoopA == runLoopB else {
        return false
    }
    
    return true
}

@noreturn private func managerThread(x: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> {
    
    managerThreadRunLoop = NSRunLoop.currentRunLoop()
    var emptySourceContext = CFRunLoopSourceContext (version: 0, info: UnsafeMutablePointer<Void>(Unmanaged.passUnretained(managerThreadRunLoop!).toOpaque()),
                                                              retain: runLoopSourceRetain, release: runLoopSourceRelease, copyDescription: nil,
                                                                      equal: runloopIsEqual, hash: nil, schedule: nil, cancel: nil,
                                                                             perform: emptyRunLoopCallback)
    
    CFRunLoopAddSource(managerThreadRunLoop?._cfRunLoop, CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &emptySourceContext), kCFRunLoopDefaultMode)
    
    managerThreadRunLoopIsRunningCondition.lock()
    
    CFRunLoopPerformBlock(managerThreadRunLoop?._cfRunLoop, kCFRunLoopDefaultMode) { 
        managerThreadRunLoopIsRunning = true
        managerThreadRunLoopIsRunningCondition.broadcast()
        managerThreadRunLoopIsRunningCondition.unlock()
    }
    
    managerThreadRunLoop?.run()
    fatalError("NSTask manager run loop exited unexpectedly; it should run forever once initialized")
}

private func managerThreadSetup() -> Void {
    pthread_create(&threadID, nil, managerThread, nil)
    
    managerThreadRunLoopIsRunningCondition.lock()
    while managerThreadRunLoopIsRunning == false {
        managerThreadRunLoopIsRunningCondition.wait()
    }
    
    managerThreadRunLoopIsRunningCondition.unlock()
}


// Equal method for task in run loop source
private func nstaskIsEqual(a : UnsafePointer<Void>, b : UnsafePointer<Void>) -> _DarwinCompatibleBoolean {
    
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
    
    private var processLaunchedCondition = NSCondition()
    
    // actions
    public func launch() {
        
        self.processLaunchedCondition.lock()
    
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
        
        let envp: UnsafeMutablePointer<UnsafeMutablePointer<Int8>>
        
        if let env = environment {
            let nenv = env.count
            envp = UnsafeMutablePointer<UnsafeMutablePointer<Int8>>.alloc(1 + nenv)
            envp.initializeFrom(env.map { strdup("\($0)=\($1)") })
            envp[env.count] = nil
            
            defer {
                for pair in envp ..< envp + env.count {
                    free(UnsafeMutablePointer<Void>(pair.memory))
                }
                envp.dealloc(env.count + 1)
            }
        } else {
            envp = _CFEnviron()
        }
        
        
        var taskSocketPair : [Int32] = [0, 0]
        socketpair(AF_UNIX, _CF_SOCK_STREAM(), 0, &taskSocketPair)
        
        var context = CFSocketContext(version: 0, info: UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque()),
                                               retain: runLoopSourceRetain, release: runLoopSourceRelease, copyDescription: nil)
        
        let socket = CFSocketCreateWithNative( nil, taskSocketPair[0], CFOptionFlags(kCFSocketDataCallBack), {
            (socket, type, address, data, info )  in
            
            let task = Unmanaged<NSTask>.fromOpaque(COpaquePointer(info)).takeUnretainedValue()
            
            task.processLaunchedCondition.lock()
            while task.running == false {
                task.processLaunchedCondition.wait()
            }
            
            task.processLaunchedCondition.unlock()
            
            var exitCode : Int32 = 0
            var waitResult : Int32 = 0
            
            repeat {
                waitResult = waitpid( task.processIdentifier, &exitCode, 0)
            } while ( (waitResult == -1) && (errno == EINTR) )
            
            task.terminationStatus = WEXITSTATUS( exitCode )
            
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
            
            CFSocketInvalidate( socket )
            
            }, &context )
        
        CFSocketSetSocketFlags( socket, CFOptionFlags(kCFSocketCloseOnInvalidate))
        
        let source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        CFRunLoopAddSource(managerThreadRunLoop?._cfRunLoop, source, kCFRunLoopDefaultMode)
        
        // Launch
        
        var pid = pid_t()
        let status = posix_spawn(&pid, launchPath, nil, nil, argv, envp)
        
        guard status == 0 else {
            fatalError()
        }
        
        close(taskSocketPair[1])
        
        self.runLoop = NSRunLoop.currentRunLoop()
        
        self.runLoopSourceContext = CFRunLoopSourceContext (version: 0, info: UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque()),
                                                                     retain: runLoopSourceRetain, release: runLoopSourceRelease, copyDescription: nil,
                                                                             equal: nstaskIsEqual, hash: nil, schedule: nil, cancel: nil,
                                                                                    perform: emptyRunLoopCallback)
        
        self.runLoopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &runLoopSourceContext!)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode)
        
        running = true
        
        self.processIdentifier = pid
        
        self.processLaunchedCondition.unlock()
        self.processLaunchedCondition.broadcast()
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


