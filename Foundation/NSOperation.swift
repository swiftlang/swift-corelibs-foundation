// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import Dispatch

public enum NSOperationQueuePriority : Int {
    case VeryLow
    case Low
    case Normal
    case High
    case VeryHigh
}

internal let NSOperationDefaultThreadPriority: Double                  = 0.5
internal let NSOperationDefaultQueuePriority: NSOperationQueuePriority = .Normal
internal let NSOperationDefaultQualityOfService: NSQualityOfService    = .Background

/* The NSOperation class is an abstract class you use to encapsulate the code and data associated with a single task.
   Because it is abstract, you do not use this class directly but instead subclass or use one of the system-defined subclasses
   (NSInvocationOperation or NSBlockOperation) to perform the actual task. Despite being abstract, the base implementation
   of NSOperation does include significant logic to coordinate the safe execution of your task. The presence of this built-in
   logic allows you to focus on the actual implementation of your task, rather than on the glue code needed to ensure it works
   correctly with other system objects. */
public class NSOperation : NSObject {
    
    public override init() {
        queuePriority    = NSOperationDefaultQueuePriority
        threadPriority   = NSOperationDefaultThreadPriority
        qualityOfService = NSOperationDefaultQualityOfService
    }

    private enum NSOperationState {
        case Inactive
        case Executing
        case Cancelled
        case Finished
    }

    // Internal state of the operation.
    private var _state: NSOperationState = .Inactive
    private let _stateLock = NSLock()

    // Internal list of depedencies.
    private var _depedencies = [NSOperation]()
    private let _depedenciesLock = NSLock()

    public func start() {
        if asynchronous {
            NSRequiresConcreteImplementation()
        }
    }

    public func main() {
        if !asynchronous {
            NSRequiresConcreteImplementation()
        }
    }
    
    public var cancelled: Bool {
        NSRequiresConcreteImplementation()
    }

    public func cancel() {
        NSRequiresConcreteImplementation()
    }
    
    public var executing: Bool {
        if asynchronous {
            NSRequiresConcreteImplementation()
        }

        return false
    }
    
    public var finished: Bool {
        if asynchronous {
            NSRequiresConcreteImplementation()
        }

        return false
    }
    
    public var asynchronous: Bool {
        return false
    }
    
    public var ready: Bool {
        _depedenciesLock.lock()
        defer { _depedenciesLock.unlock() }

        let unfinished = _depedencies.filter({ operation in !operation.finished })

        return unfinished.count == 0
    }

    internal var inactive: Bool {
        _stateLock.lock()
        defer { _stateLock.unlock() }

        return _state == .Inactive
    }
    
    public func addDependency(op: NSOperation) {
        _depedenciesLock.lock()
        defer { _depedenciesLock.unlock() }

        _depedencies.append(op)
    }
 
    public func removeDependency(operationToRemove: NSOperation) {
        _depedenciesLock.lock()
        defer { _depedenciesLock.unlock() }

        _depedencies = _depedencies.filter({ operation in operation !== operationToRemove })
    }
    
    public var dependencies: [NSOperation] {
         _depedenciesLock.lock()
        defer { _depedenciesLock.unlock() }

        return _depedencies
    }
    
    public var queuePriority: NSOperationQueuePriority
    public var completionBlock: (() -> ())?
    public func waitUntilFinished() {
        NSRequiresConcreteImplementation()
    }
    
    public var threadPriority: Double
    
    public var qualityOfService: NSQualityOfService
    
    public var name: String?
}

/*  The NSBlockOperation class is a concrete subclass of NSOperation that manages the concurrent execution
    of one or more blocks. You can use this object to execute several blocks at once without having to 
    create separate operation objects for each. When executing more than one block, the operation itself 
    is considered finished only when all blocks have finished executing. */
public class NSBlockOperation : NSOperation {
    
    private typealias ExecutionBlock = () -> ()
    private var _executionBlocks = [ExecutionBlock]()
    private let _executionBlocksLock = NSLock()

    private let _concurrencyLimitingSemaphore = DispatchSemaphoreBridge(count: NSOperationQueueDefaultMaxConcurrentOperationCount)
    private let _queue = DispatchQueueBridge(name: "com.apple.queue.NSBlockOperation.\(NSUUID().UUIDString)", type: .Concurrent)

    private let _dispatchGroup = DispatchGroupBridge()

    public override init() {
        super.init()
        _dispatchGroup.enter()
    }

    public convenience init(block: () -> ()) {
        self.init()
        addExecutionBlock(block)
    }

    public override var cancelled: Bool {
        _stateLock.lock()
        defer { _stateLock.unlock() }

        return _state == .Cancelled
    }

    public override func cancel() {
        _stateLock.lock()
        defer { _stateLock.unlock() }

        // TODO: Stop the queue.

        _state = .Cancelled
    }

    public override var executing: Bool {
        _stateLock.lock()
        defer { _stateLock.unlock() }

        return _state == .Executing
    }

    public override var finished: Bool {
        _stateLock.lock()
        defer { _stateLock.unlock() }

        return _state == .Finished || _state == .Cancelled
    }

    public override var asynchronous: Bool {
        return true
    }
    
    public func addExecutionBlock(block: () -> ()) {

        _stateLock.lock()
        defer { _stateLock.unlock() }

        guard _state != .Executing else {
            fatalError("Cannot add a block if the operation is currently executing.")
        }
        
        guard _state != .Finished && _state != .Cancelled else {
            fatalError("Cannot add a block if the operation has already finished.")
        }
        
        _executionBlocksLock.lock()
        defer { _executionBlocksLock.unlock() }
        _executionBlocks.append(block)
    }

    public var executionBlocks: [() -> ()] {
        _executionBlocksLock.lock()
        defer { _executionBlocksLock.unlock() }
        return _executionBlocks
    }

    public override func start() {

        guard ready && inactive else {
            return
        }

        _state = .Executing
        _stateLock.unlock()

        _executionBlocksLock.lock()
        defer { _executionBlocksLock.unlock() }

        for block in _executionBlocks {

            _dispatchGroup.enter()

            _queue.dispatchAsynchronously({

                self._concurrencyLimitingSemaphore.wait(DispatchTimeForever)

                defer { self._dispatchGroup.leave() }
                defer { self._concurrencyLimitingSemaphore.signal() }

                if self._stateLock.synchronized({ self._state == .Cancelled }) {
                    return
                }

                block()
            })
        }

        _dispatchGroup.leave()
        _dispatchGroup.wait(DispatchTimeForever)

        _stateLock.lock()
        _state = .Finished
        _stateLock.unlock()

        if let completionBlock = self.completionBlock {
            completionBlock()
        }
    }

    public override func waitUntilFinished() {
         _dispatchGroup.wait(DispatchTimeForever)
    }
}

public let NSOperationQueueDefaultMaxConcurrentOperationCount: Int = 1 // Unimplemented

public class NSOperationQueue : NSObject {

    private static var _mainQueue = NSOperationQueue(queue: DispatchQueueBridge.mainQueue,
                                                      name: "NSOperationQueue: Main",
                               maxConcurrentOperationCount: 1)

    private var _operations = [NSOperation]()
    private let _operationsLock = NSLock()
    public var maxConcurrentOperationCount: Int = NSOperationQueueDefaultMaxConcurrentOperationCount

    public var suspended: Bool = false {
        didSet {
            _suspendedLock.lock()
            defer {  _suspendedLock.unlock() }

            if !suspended {
                executeOperationsAndWait(false)
            }
        }
    }

    private var _suspendedLock = NSLock()

    public var name: String?

    public var qualityOfService: NSQualityOfService = .Default  // Unimplemented
                                                                // NSThread.currentThread().qualityOfService
                                                                // (suggested by phausler@apple.com)

    unowned(unsafe) public var underlyingQueue: dispatch_queue_t { return _underlyingQueue._queue }

    private let _underlyingQueue: DispatchQueueBridge

    private let _dispatchGroup = DispatchGroupBridge()
    private var _concurrencyLimitingSemaphore: DispatchSemaphoreBridge

    public override init() {
        _underlyingQueue = DispatchQueueBridge(name: name ?? "NSOperationQueue: \(NSUUID().UUIDString)", type: .Concurrent)
        _concurrencyLimitingSemaphore = DispatchSemaphoreBridge(count: maxConcurrentOperationCount)
    }

    private init(queue: DispatchQueueBridge, name aName: String, maxConcurrentOperationCount max: Int = NSOperationQueueDefaultMaxConcurrentOperationCount) {
        self._underlyingQueue = queue
        self.name = aName
        self.maxConcurrentOperationCount = max

        _concurrencyLimitingSemaphore = DispatchSemaphoreBridge(count: maxConcurrentOperationCount)
    }

    public func addOperation(operation: NSOperation) {
        addOperations([operation], waitUntilFinished: false)
    }

    public func addOperations(operations: [NSOperation], waitUntilFinished wait: Bool) {
        _operationsLock.lock()
        _operations += operations
        _operationsLock.unlock()

        _suspendedLock.lock()
        defer {  _suspendedLock.unlock() }
        if !suspended {
            executeOperationsAndWait(wait)
        }
    }

    private func executeOperations(operations: [NSOperation]) {
        for operation in operations {
            _dispatchGroup.enter()

            _underlyingQueue.dispatchAsynchronously({
                self._concurrencyLimitingSemaphore.wait(DispatchTimeForever)

                self.executeOperation(operation)

                self._concurrencyLimitingSemaphore.signal()
                self._dispatchGroup.leave()
            })
        }
    }

    private func executeOperation(operation: NSOperation) {
        if operation.asynchronous {
            operation.start()
            operation.waitUntilFinished()
        } else {
            operation.main()
        }
    }

    private func operationsReadyToExecute(ops: [NSOperation]) -> [NSOperation] {
        let readyOperations = ops.filter({ operation in operation.ready })
        let readyAndSortedOperations = readyOperations.sort({ operation1, operation2 in
            operation1.qualityOfService.rawValue > operation2.qualityOfService.rawValue
        })

        return readyAndSortedOperations
    }

    private func executeOperationsAndWait(wait: Bool) {

        _operationsLock.lock()
        let availableOperations = _operations
        let operationsToExecute = operationsReadyToExecute(availableOperations)
        executeOperations(operationsToExecute)
        _operationsLock.unlock()

        if wait {
            _dispatchGroup.wait(DispatchTimeForever)
        }
    }

    public func addOperationWithBlock(block: () -> ()) {
        addOperation(NSBlockOperation(block: block))

        if !suspended {
            executeOperationsAndWait(false)
        }
    }

    public var operations: [NSOperation] {
        _operationsLock.lock()
        defer { _operationsLock.unlock() }
        return _operations
    }

    public var operationCount: Int {
        _operationsLock.lock()
        defer { _operationsLock.unlock() }
        return _operations.count
    }

    public func cancelAllOperations() {
        _operationsLock.lock()
        for operation in _operations.filter({ !$0.cancelled && !$0.finished }) {
            operation.cancel()
        }
        _operationsLock.unlock()
    }

    public func waitUntilAllOperationsAreFinished() {
        _dispatchGroup.wait(DispatchTimeForever)
    }

    public class func currentQueue() -> NSOperationQueue? {
        NSUnimplemented()
    }

    public class func mainQueue() -> NSOperationQueue {
        return _mainQueue
    }
}

// MARK: - DispatchBridges -

internal typealias DispatchTime = UInt64

let DispatchTimeForever: DispatchTime = DISPATCH_TIME_FOREVER

internal struct DispatchGroupBridge {

    private let _dispatchGroup = dispatch_group_create()

    func enter() {
        dispatch_group_enter(_dispatchGroup)
    }

    func leave() {
        dispatch_group_leave(_dispatchGroup)
    }

    func wait(timeout: DispatchTime) {
        dispatch_group_wait(_dispatchGroup, timeout)
    }
}

internal struct DispatchSemaphoreBridge {

    private let _semaphore: dispatch_semaphore_t

    init(count: Int) {
        _semaphore = dispatch_semaphore_create(count)
    }

    func wait(timeout: DispatchTime) {
        dispatch_semaphore_wait(_semaphore, timeout)
    }

    func signal() {
        dispatch_semaphore_signal(_semaphore)
    }
}

internal enum DispatchQueueType {
    case Serial
    case Concurrent
}

internal struct DispatchQueueBridge {

    private let _queue: dispatch_queue_t
    static let mainQueue = DispatchQueueBridge(queue: dispatch_get_main_queue())

    init(name: String, type: DispatchQueueType = .Serial) {

        let isSerial = type == .Serial
        let actualType = isSerial ? DISPATCH_QUEUE_SERIAL : DISPATCH_QUEUE_CONCURRENT

        _queue = dispatch_queue_create(name, actualType)
    }

    init(queue: dispatch_queue_t) {
        _queue = queue
    }

    func dispatchSynchronously(block: () -> ()) {
        dispatch_sync(_queue, block)
    }

    func dispatchAsynchronously(block: () -> ()) {
        dispatch_async(_queue, block)
    }
}

extension DispatchQueueBridge {
    var dispatchQueue: dispatch_queue_t {
        return _queue
    }
}

