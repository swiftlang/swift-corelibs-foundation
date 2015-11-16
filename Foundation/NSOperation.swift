// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


public class NSOperation : NSObject {
    
    public override init() {
        NSUnimplemented()
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
    
    public convenience init(block: () -> Void) {
        NSUnimplemented()
    }
    
    public func addExecutionBlock(block: () -> Void) {
        NSUnimplemented()
    }

    public var executionBlocks: [() -> Void] {
        NSUnimplemented()
    }
}

public let NSOperationQueueDefaultMaxConcurrentOperationCount: Int = 0 // Unimplemented

public class NSOperationQueue : NSObject {
    
    public override init() {
        NSUnimplemented()
    }
    
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
    
    public var maxConcurrentOperationCount: Int
    
    public var suspended: Bool
    
    public var name: String?
    
    public var qualityOfService: NSQualityOfService
    
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

