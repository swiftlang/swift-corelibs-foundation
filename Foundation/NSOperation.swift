// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

internal let NSOperationDefaultThreadPriority: Double                  = 0.5
internal let NSOperationDefaultQueuePriority: NSOperationQueuePriority = .Normal
internal let NSOperationDefaultQualityOfService: NSQualityOfService    = .Background

public class NSOperation : NSObject {
    
    public override init() {
        queuePriority    = NSOperationDefaultQueuePriority
        threadPriority   = NSOperationDefaultThreadPriority
        qualityOfService = NSOperationDefaultQualityOfService
    }
    
    public func start() {
        NSUnimplemented()
    }

    public func main() {
        NSUnimplemented()
    }
    
    public var cancelled: Bool {
        NSUnimplemented()
    }

    public func cancel() {
        NSUnimplemented()
    }
    
    public var executing: Bool {
        NSUnimplemented()
    }
    
    public var finished: Bool {
        NSUnimplemented()
    }
    
    public var asynchronous: Bool {
        NSUnimplemented()
    }
    
    public var ready: Bool {
        NSUnimplemented()
    }
    
    public func addDependency(op: NSOperation) {
        NSUnimplemented()
    }
 
    public func removeDependency(op: NSOperation) {
        NSUnimplemented()
    }
    
    public var dependencies: [NSOperation] {
        NSUnimplemented()
    }
    
    public var queuePriority: NSOperationQueuePriority
    public var completionBlock: (() -> Void)?
    public func waitUntilFinished() {
        NSUnimplemented()
    }
    
    public var threadPriority: Double
    
    public var qualityOfService: NSQualityOfService
    
    public var name: String?
}

public enum NSOperationQueuePriority : Int {
    case VeryLow
    case Low
    case Normal
    case High
    case VeryHigh
}

public class NSBlockOperation : NSOperation {
    
    private typealias ExecutionBlock = () -> ()
    private var _executionBlocks = [ExecutionBlock]()
    private let _executionBlocksLock = NSLock()
    
    public convenience init(block: () -> ()) {
        self.init()
        addExecutionBlock(block)
    }
    
    public func addExecutionBlock(block: () -> ()) {
        guard !executing else {
            fatalError("Cannot add a block if the operation is currently executing.")
        }
        
        guard !finished else {
            fatalError("Cannot add a block if the operation has already finished.")
        }
        
        _executionBlocksLock.lock()
        _executionBlocks.append(block)
        _executionBlocksLock.unlock()
    }

    public var executionBlocks: [() -> ()] {
        _executionBlocksLock.lock()
        defer { _executionBlocksLock.unlock() }
        return _executionBlocks
    }
}

public let NSOperationQueueDefaultMaxConcurrentOperationCount: Int = 0 // Unimplemented

public class NSOperationQueue : NSObject {
    
    public func addOperation(op: NSOperation) {
        NSUnimplemented()
    }

    public func addOperations(ops: [NSOperation], waitUntilFinished wait: Bool) {
        NSUnimplemented()
    }
    
    public func addOperationWithBlock(block: () -> Void) {
        NSUnimplemented()
    }
    
    public var operations: [NSOperation] {
        NSUnimplemented()
    }

    public var operationCount: Int {
        NSUnimplemented()
    }
    
    public var maxConcurrentOperationCount: Int = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    public var suspended: Bool = false
    
    public var name: String?
    
    public var qualityOfService: NSQualityOfService = .Default // Unimplemented
                                                               // NSThread.currentThread().qualityOfService
                                                               // (suggested by phausler@apple.com)
    
    /* This method remains commented out until we have an implementation of libdispatch. */
    // unowned(unsafe) public var underlyingQueue: dispatch_queue_t? /* actually retain */
    
    public func cancelAllOperations() {
        NSUnimplemented()
    }
    
    public func waitUntilAllOperationsAreFinished() {
        NSUnimplemented()
    }
    
    public class func currentQueue() -> NSOperationQueue? {
        NSUnimplemented()
    }
    
    public class func mainQueue() -> NSOperationQueue {
        NSUnimplemented()
    }
}

