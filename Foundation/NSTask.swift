// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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

extension Task {
    public enum TerminationReason : Int {
        case exit
        case uncaughtSignal
    }
}

private func WEXITSTATUS(_ status: CInt) -> CInt {
    return (status >> 8) & 0xff
}

private var managerThreadRunLoop : RunLoop? = nil
private var managerThreadRunLoopIsRunning = false
private var managerThreadRunLoopIsRunningCondition = Condition()

#if os(OSX) || os(iOS)
internal let kCFSocketDataCallBack = CFSocketCallBackType.dataCallBack.rawValue
#endif

private func emptyRunLoopCallback(_ context : UnsafeMutablePointer<Void>?) -> Void {}


// Retain method for run loop source
private func runLoopSourceRetain(_ pointer : UnsafePointer<Void>?) -> UnsafePointer<Void>? {
    let ref = Unmanaged<AnyObject>.fromOpaque(pointer!).takeUnretainedValue()
    let retained = Unmanaged<AnyObject>.passRetained(ref)
    return unsafeBitCast(retained, to: UnsafePointer<Void>.self)
}

// Release method for run loop source
private func runLoopSourceRelease(_ pointer : UnsafePointer<Void>?) -> Void {
    Unmanaged<AnyObject>.fromOpaque(pointer!).release()
}

// Equal method for run loop source

private func runloopIsEqual(_ a : UnsafePointer<Void>?, _ b : UnsafePointer<Void>?) -> _DarwinCompatibleBoolean {
    
    let unmanagedrunLoopA = Unmanaged<AnyObject>.fromOpaque(a!)
    guard let runLoopA = unmanagedrunLoopA.takeUnretainedValue() as? RunLoop else {
        return false
    }
    
    let unmanagedRunLoopB = Unmanaged<AnyObject>.fromOpaque(a!)
    guard let runLoopB = unmanagedRunLoopB.takeUnretainedValue() as? RunLoop else {
        return false
    }
    
    guard runLoopA == runLoopB else {
        return false
    }
    
    return true
}


// Equal method for task in run loop source
private func nstaskIsEqual(_ a : UnsafePointer<Void>?, _ b : UnsafePointer<Void>?) -> _DarwinCompatibleBoolean {
    
    let unmanagedTaskA = Unmanaged<AnyObject>.fromOpaque(a!)
    guard let taskA = unmanagedTaskA.takeUnretainedValue() as? Task else {
        return false
    }
    
    let unmanagedTaskB = Unmanaged<AnyObject>.fromOpaque(a!)
    guard let taskB = unmanagedTaskB.takeUnretainedValue() as? Task else {
        return false
    }
    
    guard taskA == taskB else {
        return false
    }
    
    return true
}

public class Task: NSObject {
    private static func setup() {
        struct Once {
            static var done = false
            static let lock = Lock()
        }
        Once.lock.synchronized {
            if !Once.done {
                let thread = Thread {
                    managerThreadRunLoop = RunLoop.current()
                    var emptySourceContext = CFRunLoopSourceContext()
                    emptySourceContext.version = 0
                    emptySourceContext.retain = runLoopSourceRetain
                    emptySourceContext.release = runLoopSourceRelease
                    emptySourceContext.equal = runloopIsEqual
                    emptySourceContext.perform = emptyRunLoopCallback
                    managerThreadRunLoop!.withUnretainedReference {
                        emptySourceContext.info = $0
                    }
                    
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
                thread.start()
                managerThreadRunLoopIsRunningCondition.lock()
                while managerThreadRunLoopIsRunning == false {
                    managerThreadRunLoopIsRunningCondition.wait()
                }
                managerThreadRunLoopIsRunningCondition.unlock()
                Once.done = true
            }
        }
    }
    
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
    
    public var currentDirectoryPath: String = FileManager.defaultInstance.currentDirectoryPath
    
    // standard I/O channels; could be either an NSFileHandle or an NSPipe
    public var standardInput: AnyObject? {
        willSet {
            precondition(newValue is Pipe || newValue is FileHandle,
                         "standardInput must be either NSPipe or NSFileHandle")
        }
    }
    public var standardOutput: AnyObject? {
        willSet {
            precondition(newValue is Pipe || newValue is FileHandle,
                         "standardOutput must be either NSPipe or NSFileHandle")
        }
    }
    public var standardError: AnyObject? {
        willSet {
            precondition(newValue is Pipe || newValue is FileHandle,
                         "standardError must be either NSPipe or NSFileHandle")
        }
    }
    
    private var runLoopSourceContext : CFRunLoopSourceContext?
    private var runLoopSource : CFRunLoopSource?
    
    private weak var runLoop : RunLoop? = nil
    
    private var processLaunchedCondition = Condition()
    
    // actions
    public func launch() {
        
        self.processLaunchedCondition.lock()
    
        // Dispatch the manager thread if it isn't already running
        
        Task.setup()
        
        // Ensure that the launch path is set
        
        guard let launchPath = self.launchPath else {
            fatalError()
        }
        
        // Convert the arguments array into a posix_spawn-friendly format
        
        var args = [launchPath]
        if let arguments = self.arguments {
            args.append(contentsOf: arguments)
        }
        
        let argv : UnsafeMutablePointer<UnsafeMutablePointer<Int8>?> = args.withUnsafeBufferPointer {
            let array : UnsafeBufferPointer<String> = $0
            let buffer = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>(allocatingCapacity: array.count + 1)
            buffer.initializeFrom(array.map { $0.withCString(strdup) })
            buffer[array.count] = nil
            return buffer
        }
        
        defer {
            for arg in argv ..< argv + args.count {
                free(UnsafeMutablePointer<Void>(arg.pointee))
            }
            
            argv.deallocateCapacity(args.count + 1)
        }
        
        let envp: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>
        
        if let env = environment {
            let nenv = env.count
            envp = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>(allocatingCapacity: 1 + nenv)
            envp.initializeFrom(env.map { strdup("\($0)=\($1)") })
            envp[env.count] = nil
        } else {
            envp = _CFEnviron()
        }

        defer {
            if let env = environment {
                for pair in envp ..< envp + env.count {
                    free(UnsafeMutablePointer<Void>(pair.pointee))
                }
                envp.deallocateCapacity(env.count + 1)
            }
        }

        var taskSocketPair : [Int32] = [0, 0]
        socketpair(AF_UNIX, _CF_SOCK_STREAM(), 0, &taskSocketPair)
        var context = CFSocketContext()
        context.version = 0
        context.retain = runLoopSourceRetain
        context.release = runLoopSourceRelease
		context.info = UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque())
        
        let socket = CFSocketCreateWithNative( nil, taskSocketPair[0], CFOptionFlags(kCFSocketDataCallBack), {
            (socket, type, address, data, info )  in
            
            let task: Task = NSObject.unretainedReference(info!)
            
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
                let thread = Thread {
                    task.terminationHandler!(task)
                }
                thread.start()
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

        // file_actions
        #if os(OSX) || os(iOS)
            var fileActions: posix_spawn_file_actions_t? = nil
        #else
            var fileActions: posix_spawn_file_actions_t = posix_spawn_file_actions_t()
        #endif
        posix(posix_spawn_file_actions_init(&fileActions))
        defer { posix_spawn_file_actions_destroy(&fileActions) }

        switch standardInput {
        case let pipe as Pipe:
            posix(posix_spawn_file_actions_adddup2(&fileActions, pipe.fileHandleForReading.fileDescriptor, STDIN_FILENO))
            posix(posix_spawn_file_actions_addclose(&fileActions, pipe.fileHandleForWriting.fileDescriptor))
        case let handle as FileHandle:
            posix(posix_spawn_file_actions_adddup2(&fileActions, handle.fileDescriptor, STDIN_FILENO))
        default: break
        }

        switch standardOutput {
        case let pipe as Pipe:
            posix(posix_spawn_file_actions_adddup2(&fileActions, pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO))
            posix(posix_spawn_file_actions_addclose(&fileActions, pipe.fileHandleForReading.fileDescriptor))
        case let handle as FileHandle:
            posix(posix_spawn_file_actions_adddup2(&fileActions, handle.fileDescriptor, STDOUT_FILENO))
        default: break
        }

        switch standardError {
        case let pipe as Pipe:
            posix(posix_spawn_file_actions_adddup2(&fileActions, pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO))
            posix(posix_spawn_file_actions_addclose(&fileActions, pipe.fileHandleForReading.fileDescriptor))
        case let handle as FileHandle:
            posix(posix_spawn_file_actions_adddup2(&fileActions, handle.fileDescriptor, STDERR_FILENO))
        default: break
        }

        // Launch

        var pid = pid_t()
        posix(posix_spawn(&pid, launchPath, &fileActions, nil, argv, envp))

        // Close the write end of the input and output pipes.
        if let pipe = standardInput as? Pipe {
            pipe.fileHandleForReading.closeFile()
        }
        if let pipe = standardOutput as? Pipe {
            pipe.fileHandleForWriting.closeFile()
        }
        if let pipe = standardError as? Pipe {
            pipe.fileHandleForWriting.closeFile()
        }

        close(taskSocketPair[1])
        
        self.runLoop = RunLoop.current()
        self.runLoopSourceContext = CFRunLoopSourceContext(version: 0,
                                                           info: UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque()),
                                                           retain: { return runLoopSourceRetain($0) },
                                                           release: { runLoopSourceRelease($0) },
                                                           copyDescription: nil,
                                                           equal: { return nstaskIsEqual($0, $1) },
                                                           hash: nil,
                                                           schedule: nil,
                                                           cancel: nil,
                                                           perform: { emptyRunLoopCallback($0) }
        )
        
        var runLoopContext = CFRunLoopSourceContext()
        runLoopContext.version = 0
        runLoopContext.retain = runLoopSourceRetain
        runLoopContext.release = runLoopSourceRelease
        runLoopContext.equal = nstaskIsEqual
        runLoopContext.perform = emptyRunLoopCallback
        self.withUnretainedReference {
            runLoopContext.info = $0
        }
        self.runLoopSourceContext = runLoopContext
        
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
    public var terminationReason: TerminationReason { NSUnimplemented() }
    
    /*
    A block to be invoked when the process underlying the NSTask terminates.  Setting the block to nil is valid, and stops the previous block from being invoked, as long as it hasn't started in any way.  The NSTask is passed as the argument to the block so the block does not have to capture, and thus retain, it.  The block is copied when set.  Only one termination handler block can be set at any time.  The execution context in which the block is invoked is undefined.  If the NSTask has already finished, the block is executed immediately/soon (not necessarily on the current thread).  If a terminationHandler is set on an NSTask, the NSTaskDidTerminateNotification notification is not posted for that task.  Also note that -waitUntilExit won't wait until the terminationHandler has been fully executed.  You cannot use this property in a concrete subclass of NSTask which hasn't been updated to include an implementation of the storage and use of it.  
    */
    public var terminationHandler: ((Task) -> Void)?
    public var qualityOfService: NSQualityOfService = .default  // read-only after the task is launched
}

extension Task {
    
    // convenience; create and launch
    public class func launchedTaskWithLaunchPath(_ path: String, arguments: [String]) -> Task {
        let task = Task()
        task.launchPath = path
        task.arguments = arguments
        task.launch()
    
        return task
    }
    
    // poll the runLoop in defaultMode until task completes
    public func waitUntilExit() {
        
        repeat {
            
        } while( self.running == true && RunLoop.current().run(mode: .defaultRunLoopMode, before: Date(timeIntervalSinceNow: 0.05)) )
        
        self.runLoop = nil
    }
}

public let NSTaskDidTerminateNotification: String = "NSTaskDidTerminateNotification"

private func posix(_ code: Int32) {
    switch code {
    case 0: return
    case EBADF: fatalError("POSIX command failed with error: \(code) -- EBADF")
    default: fatalError("POSIX command failed with error: \(code)")
    }
}
