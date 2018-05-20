// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016, 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if !os(Android) // not available
import CoreFoundation

#if os(macOS) || os(iOS)
    import Darwin
#elseif os(Linux) || CYGWIN
    import Glibc
#endif

extension Process {
    public enum TerminationReason : Int {
        case exit
        case uncaughtSignal
    }
}

private func WIFEXITED(_ status: Int32) -> Bool {
    return _WSTATUS(status) == 0
}

private func _WSTATUS(_ status: Int32) -> Int32 {
    return status & 0x7f
}

private func WIFSIGNALED(_ status: Int32) -> Bool {
    return (_WSTATUS(status) != 0) && (_WSTATUS(status) != 0x7f)
}

private func WEXITSTATUS(_ status: Int32) -> Int32 {
    return (status >> 8) & 0xff
}

private func WTERMSIG(_ status: Int32) -> Int32 {
    return status & 0x7f
}

private var managerThreadRunLoop : RunLoop? = nil
private var managerThreadRunLoopIsRunning = false
private var managerThreadRunLoopIsRunningCondition = NSCondition()

#if os(macOS) || os(iOS)
internal let kCFSocketDataCallBack = CFSocketCallBackType.dataCallBack.rawValue
#endif

private func emptyRunLoopCallback(_ context : UnsafeMutableRawPointer?) -> Void {}


// Retain method for run loop source
private func runLoopSourceRetain(_ pointer : UnsafeRawPointer?) -> UnsafeRawPointer? {
    let ref = Unmanaged<AnyObject>.fromOpaque(pointer!).takeUnretainedValue()
    let retained = Unmanaged<AnyObject>.passRetained(ref)
    return unsafeBitCast(retained, to: UnsafeRawPointer.self)
}

// Release method for run loop source
private func runLoopSourceRelease(_ pointer : UnsafeRawPointer?) -> Void {
    Unmanaged<AnyObject>.fromOpaque(pointer!).release()
}

// Equal method for run loop source

private func runloopIsEqual(_ a : UnsafeRawPointer?, _ b : UnsafeRawPointer?) -> _DarwinCompatibleBoolean {
    
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


// Equal method for process in run loop source
private func processIsEqual(_ a : UnsafeRawPointer?, _ b : UnsafeRawPointer?) -> _DarwinCompatibleBoolean {
    
    let unmanagedProcessA = Unmanaged<AnyObject>.fromOpaque(a!)
    guard let processA = unmanagedProcessA.takeUnretainedValue() as? Process else {
        return false
    }
    
    let unmanagedProcessB = Unmanaged<AnyObject>.fromOpaque(a!)
    guard let processB = unmanagedProcessB.takeUnretainedValue() as? Process else {
        return false
    }
    
    guard processA == processB else {
        return false
    }
    
    return true
}

open class Process: NSObject {
    private static func setup() {
        struct Once {
            static var done = false
            static let lock = NSLock()
        }
        
        Once.lock.synchronized {
            if !Once.done {
                let thread = Thread {
                    managerThreadRunLoop = RunLoop.current
                    var emptySourceContext = CFRunLoopSourceContext()
                    emptySourceContext.version = 0
                    emptySourceContext.retain = runLoopSourceRetain
                    emptySourceContext.release = runLoopSourceRelease
                    emptySourceContext.equal = runloopIsEqual
                    emptySourceContext.perform = emptyRunLoopCallback
                    managerThreadRunLoop!.withUnretainedReference {
                        (refPtr: UnsafeMutablePointer<UInt8>) in
                        emptySourceContext.info = UnsafeMutableRawPointer(refPtr)
                    }
                    
                    CFRunLoopAddSource(managerThreadRunLoop?._cfRunLoop, CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &emptySourceContext), kCFRunLoopDefaultMode)
                    
                    managerThreadRunLoopIsRunningCondition.lock()
                    
                    CFRunLoopPerformBlock(managerThreadRunLoop?._cfRunLoop, kCFRunLoopDefaultMode) {
                        managerThreadRunLoopIsRunning = true
                        managerThreadRunLoopIsRunningCondition.broadcast()
                        managerThreadRunLoopIsRunningCondition.unlock()
                    }
                    
                    managerThreadRunLoop?.run()
                    fatalError("Process manager run loop exited unexpectedly; it should run forever once initialized")
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

    // Create an Process which can be run at a later time
    // An Process can only be run once. Subsequent attempts to
    // run an Process will raise.
    // Upon process death a notification will be sent
    //   { Name = ProcessDidTerminateNotification; object = process; }
    //
    
    public override init() {

    }

    // These properties can only be set before a launch.
    open var executableURL: URL?
    open var currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    open var arguments: [String]?
    open var environment: [String : String]? // if not set, use current

    @available(*, deprecated: 4, renamed: "executableURL")
    open var launchPath: String? {
        get { return executableURL?.path }
        set { executableURL = (newValue != nil) ? URL(fileURLWithPath: newValue!) : nil }
    }

    @available(*, deprecated: 4, renamed: "currentDirectoryURL")
    open var currentDirectoryPath: String {
        get { return currentDirectoryURL.path }
        set { currentDirectoryURL = URL(fileURLWithPath: newValue) }
    }

    // Standard I/O channels; could be either a FileHandle or a Pipe

    open var standardInput: Any? {
        willSet {
            precondition(newValue is Pipe || newValue is FileHandle,
                         "standardInput must be either Pipe or FileHandle")
        }
    }

    open var standardOutput: Any? {
        willSet {
            precondition(newValue is Pipe || newValue is FileHandle,
                         "standardOutput must be either Pipe or FileHandle")
        }
    }
    
    open var standardError: Any? {
        willSet {
            precondition(newValue is Pipe || newValue is FileHandle,
                         "standardError must be either Pipe or FileHandle")
        }
    }
    
    private var runLoopSourceContext : CFRunLoopSourceContext?
    private var runLoopSource : CFRunLoopSource?
    
    fileprivate weak var runLoop : RunLoop? = nil
    
    private var processLaunchedCondition = NSCondition()
    
    // Actions
    
    @available(*, deprecated: 4, renamed: "run")
    open func launch() {
        do {
            try run()
        } catch let nserror as NSError {
            if let path = nserror.userInfo[NSFilePathErrorKey] as? String, path == currentDirectoryPath {
                // Foundation throws an NSException when changing the working directory fails,
                // and unfortunately launch() is not marked `throws`, so we get away with a
                // fatalError.
                switch CocoaError.Code(rawValue: nserror.code) {
                case .fileReadNoSuchFile:
                    fatalError("Process: The specified working directory does not exist.")
                case .fileReadNoPermission:
                    fatalError("Process: The specified working directory cannot be accessed.")
                default:
                    fatalError("Process: The specified working directory cannot be set.")
                }
            }
        } catch {
            fatalError(String(describing: error))
        }
    }

    open func run() throws {
        
        self.processLaunchedCondition.lock()
    
        // Dispatch the manager thread if it isn't already running
        
        Process.setup()
        
        // Ensure that the launch path is set
        guard let launchPath = self.executableURL?.path else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError)
        }
        
        // Convert the arguments array into a posix_spawn-friendly format
        
        var args = [launchPath]
        if let arguments = self.arguments {
            args.append(contentsOf: arguments)
        }
        
        let argv : UnsafeMutablePointer<UnsafeMutablePointer<Int8>?> = args.withUnsafeBufferPointer {
            let array : UnsafeBufferPointer<String> = $0
            let buffer = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: array.count + 1)
            buffer.initialize(from: array.map { $0.withCString(strdup) }, count: array.count)
            buffer[array.count] = nil
            return buffer
        }
        
        defer {
            for arg in argv ..< argv + args.count {
                free(UnsafeMutableRawPointer(arg.pointee))
            }
            argv.deallocate()
        }
        
        let envp: UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>
        
        if let env = environment {
            let nenv = env.count
            envp = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: 1 + nenv)
            envp.initialize(from: env.map { strdup("\($0)=\($1)") }, count: nenv)
            envp[env.count] = nil
        } else {
            envp = _CFEnviron()
        }

        defer {
            if let env = environment {
                for pair in envp ..< envp + env.count {
                    free(UnsafeMutableRawPointer(pair.pointee))
                }
                envp.deallocate()
            }
        }

        var taskSocketPair : [Int32] = [0, 0]
#if os(macOS) || os(iOS)
        socketpair(AF_UNIX, SOCK_STREAM, 0, &taskSocketPair)
#else
        socketpair(AF_UNIX, Int32(SOCK_STREAM.rawValue), 0, &taskSocketPair)
#endif
        var context = CFSocketContext()
        context.version = 0
        context.retain = runLoopSourceRetain
        context.release = runLoopSourceRelease
        context.info = Unmanaged.passUnretained(self).toOpaque()
        
        let socket = CFSocketCreateWithNative( nil, taskSocketPair[0], CFOptionFlags(kCFSocketDataCallBack), {
            (socket, type, address, data, info )  in
            
            let process: Process = NSObject.unretainedReference(info!)
            
            process.processLaunchedCondition.lock()
            while process.isRunning == false {
                process.processLaunchedCondition.wait()
            }
            
            process.processLaunchedCondition.unlock()
            
            var exitCode : Int32 = 0
#if CYGWIN
            let exitCodePtrWrapper = withUnsafeMutablePointer(to: &exitCode) {
                exitCodePtr in
                __wait_status_ptr_t(__int_ptr: exitCodePtr)
            }
#endif
            var waitResult : Int32 = 0

            repeat {
#if CYGWIN
                waitResult = waitpid( process.processIdentifier, exitCodePtrWrapper, 0)
#else
                waitResult = waitpid( process.processIdentifier, &exitCode, 0)
#endif
            } while ( (waitResult == -1) && (errno == EINTR) )

            if WIFSIGNALED(exitCode) {
                process.terminationStatus = WTERMSIG(exitCode)
                process.terminationReason = .uncaughtSignal
            } else {
                assert(WIFEXITED(exitCode))
                process.terminationStatus = WEXITSTATUS(exitCode)
                process.terminationReason = .exit
            }
            
            // If a termination handler has been set, invoke it on a background thread
            
            if let terminationHandler = process.terminationHandler {
                let thread = Thread {
                    terminationHandler(process)
                }
                thread.start()
            }
            
            // Set the running flag to false
            process.isRunning = false
            process.processIdentifier = -1

            // Invalidate the source and wake up the run loop, if it's available
            
            CFRunLoopSourceInvalidate(process.runLoopSource)
            if let runLoop = process.runLoop {
                CFRunLoopWakeUp(runLoop._cfRunLoop)
            }
            
            CFSocketInvalidate( socket )
            
            }, &context )
        
        CFSocketSetSocketFlags( socket, CFOptionFlags(kCFSocketCloseOnInvalidate))
        
        let source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        CFRunLoopAddSource(managerThreadRunLoop?._cfRunLoop, source, kCFRunLoopDefaultMode)

        // file_actions
        #if os(macOS) || os(iOS) || CYGWIN
            var fileActions: posix_spawn_file_actions_t? = nil
        #else
            var fileActions: posix_spawn_file_actions_t = posix_spawn_file_actions_t()
        #endif
        posix(posix_spawn_file_actions_init(&fileActions))
        defer { posix_spawn_file_actions_destroy(&fileActions) }

        // File descriptors to duplicate in the child process. This allows
        // output redirection to NSPipe or NSFileHandle.
        var adddup2 = [Int32: Int32]()

        // File descriptors to close in the child process. A set so that
        // shared pipes only get closed once. Would result in EBADF on OSX
        // otherwise.
        var addclose = Set<Int32>()

        switch standardInput {
        case let pipe as Pipe:
            adddup2[STDIN_FILENO] = pipe.fileHandleForReading.fileDescriptor
            addclose.insert(pipe.fileHandleForWriting.fileDescriptor)
        case let handle as FileHandle:
            adddup2[STDIN_FILENO] = handle.fileDescriptor
        default: break
        }

        switch standardOutput {
        case let pipe as Pipe:
            adddup2[STDOUT_FILENO] = pipe.fileHandleForWriting.fileDescriptor
            addclose.insert(pipe.fileHandleForReading.fileDescriptor)
        case let handle as FileHandle:
            adddup2[STDOUT_FILENO] = handle.fileDescriptor
        default: break
        }

        switch standardError {
        case let pipe as Pipe:
            adddup2[STDERR_FILENO] = pipe.fileHandleForWriting.fileDescriptor
            addclose.insert(pipe.fileHandleForReading.fileDescriptor)
        case let handle as FileHandle:
            adddup2[STDERR_FILENO] = handle.fileDescriptor
        default: break
        }

        for (new, old) in adddup2 {
            posix(posix_spawn_file_actions_adddup2(&fileActions, old, new))
        }
        for fd in addclose {
            posix(posix_spawn_file_actions_addclose(&fileActions, fd))
        }

        let fileManager = FileManager()
        let previousDirectoryPath = fileManager.currentDirectoryPath
        if !fileManager.changeCurrentDirectoryPath(currentDirectoryURL.path) {
            throw _NSErrorWithErrno(errno, reading: true, url: currentDirectoryURL)
        }

        // Launch

        var pid = pid_t()
        guard posix_spawn(&pid, launchPath, &fileActions, nil, argv, envp) == 0 else {
            throw _NSErrorWithErrno(errno, reading: true, path: launchPath)
        }

        // Reset the previous working directory path.
        fileManager.changeCurrentDirectoryPath(previousDirectoryPath)

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
        
        self.runLoop = RunLoop.current
        self.runLoopSourceContext = CFRunLoopSourceContext(version: 0,
                                                           info: Unmanaged.passUnretained(self).toOpaque(),
                                                           retain: { return runLoopSourceRetain($0) },
                                                           release: { runLoopSourceRelease($0) },
                                                           copyDescription: nil,
                                                           equal: { return processIsEqual($0, $1) },
                                                           hash: nil,
                                                           schedule: nil,
                                                           cancel: nil,
                                                           perform: { emptyRunLoopCallback($0) }
        )
        
        var runLoopContext = CFRunLoopSourceContext()
        runLoopContext.version = 0
        runLoopContext.retain = runLoopSourceRetain
        runLoopContext.release = runLoopSourceRelease
        runLoopContext.equal = processIsEqual
        runLoopContext.perform = emptyRunLoopCallback
        self.withUnretainedReference {
            (refPtr: UnsafeMutablePointer<UInt8>) in
            runLoopContext.info = UnsafeMutableRawPointer(refPtr)
        }
        self.runLoopSourceContext = runLoopContext
        
        self.runLoopSource = CFRunLoopSourceCreate(kCFAllocatorDefault, 0, &runLoopSourceContext!)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode)
        
        isRunning = true
        
        self.processIdentifier = pid
        
        self.processLaunchedCondition.unlock()
        self.processLaunchedCondition.broadcast()
    }
    
    open func interrupt() { NSUnimplemented() } // Not always possible. Sends SIGINT.
    open func terminate()  { NSUnimplemented() }// Not always possible. Sends SIGTERM.
    
    open func suspend() -> Bool { NSUnimplemented() }
    open func resume() -> Bool { NSUnimplemented() }
    
    // status
    open private(set) var processIdentifier: Int32 = -1
    open private(set) var isRunning: Bool = false
    
    open private(set) var terminationStatus: Int32 = 0
    open private(set) var terminationReason: TerminationReason = .exit
    
    /*
    A block to be invoked when the process underlying the Process terminates.  Setting the block to nil is valid, and stops the previous block from being invoked, as long as it hasn't started in any way.  The Process is passed as the argument to the block so the block does not have to capture, and thus retain, it.  The block is copied when set.  Only one termination handler block can be set at any time.  The execution context in which the block is invoked is undefined.  If the Process has already finished, the block is executed immediately/soon (not necessarily on the current thread).  If a terminationHandler is set on an Process, the ProcessDidTerminateNotification notification is not posted for that process.  Also note that -waitUntilExit won't wait until the terminationHandler has been fully executed.  You cannot use this property in a concrete subclass of Process which hasn't been updated to include an implementation of the storage and use of it.  
    */
    open var terminationHandler: ((Process) -> Void)?
    open var qualityOfService: QualityOfService = .default  // read-only after the process is launched


    open class func run(_ url: URL, arguments: [String], terminationHandler: ((Process) -> Void)? = nil) throws -> Process {
        let process = Process()
        process.executableURL = url
        process.arguments = arguments
        process.terminationHandler = terminationHandler
        try process.run()
        return process
    }

    @available(*, deprecated: 4, renamed: "run(_:arguments:terminationHandler:)")
    // convenience; create and launch
    open class func launchedProcess(launchPath path: String, arguments: [String]) -> Process {
        let process = Process()
        process.launchPath = path
        process.arguments = arguments
        process.launch()
    
        return process
    }

    // poll the runLoop in defaultMode until process completes
    open func waitUntilExit() {
        
        repeat {
            
        } while( self.isRunning == true && RunLoop.current.run(mode: .defaultRunLoopMode, before: Date(timeIntervalSinceNow: 0.05)) )
        
        self.runLoop = nil
    }
}

extension Process {
    
    public static let didTerminateNotification = NSNotification.Name(rawValue: "NSTaskDidTerminateNotification")
}
    
private func posix(_ code: Int32) {
    switch code {
    case 0: return
    case EBADF: fatalError("POSIX command failed with error: \(code) -- EBADF")
    default: fatalError("POSIX command failed with error: \(code)")
    }
}
#endif
