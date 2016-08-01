// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_ENABLE_LIBDISPATCH
import Dispatch
#if os(Linux)
import CoreFoundation
private func pthread_main_np() -> Int32 {
    return _CFIsMainThread() ? 1 : 0
}
#endif
#endif

open class Operation: NSObject {
    let lock = Lock()
    internal weak var _queue: OperationQueue?
    internal var _cancelled = false
    internal var _executing = false
    internal var _finished = false
    internal var _ready = false
    internal var _dependencies = Set<Operation>()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    internal var _group = DispatchGroup()
    internal var _depGroup = DispatchGroup()
    internal var _groups = [DispatchGroup]()
#endif
    
    public override init() {
        super.init()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        _group.enter()
#endif
    }
    
    internal func _leaveGroups() {
        // assumes lock is taken
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        _groups.forEach() { $0.leave() }
        _groups.removeAll()
        _group.leave()
#endif
    }
    
    /// - Note: Operations that are asynchronous from the execution of the operation queue itself are not supported since there is no KVO to trigger the finish.
    open func start() {
        main()
        finish()
    }
    
    internal func finish() {
        lock.lock()
        _finished = true
        _leaveGroups()
        lock.unlock()
        if let queue = _queue {
            queue._operationFinished(self)
        }
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        // The completion block property is a bit cagey and can not be executed locally on the queue due to thread exhaust potentials.
        // This sets up for some strange behavior of finishing operations since the handler will be executed on a different queue
        if let completion = completionBlock {
            DispatchQueue.global(attributes: .qosBackground).async { () -> Void in
                completion()
            }
        }
#endif
    }
    
    open func main() { }
    
    open var isCancelled: Bool {
        return _cancelled
    }
    
    open func cancel() {
        lock.lock()
        _cancelled = true
        _leaveGroups()
        lock.unlock()
    }
    
    open var isExecuting: Bool {
        return _executing
    }
    
    open var isFinished: Bool {
        return _finished
    }
    
    // - Note: This property is NEVER used in the objective-c implementation!
    open var isAsynchronous: Bool {
        return false
    }
    
    open var isReady: Bool {
        return _ready
    }
    
    open func addDependency(_ op: Operation) {
        lock.lock()
        _dependencies.insert(op)
        op.lock.lock()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        _depGroup.enter()
        op._groups.append(_depGroup)
#endif
        op.lock.unlock()
        lock.unlock()
    }
    
    open func removeDependency(_ op: Operation) {
        lock.lock()
        _dependencies.remove(op)
        op.lock.lock()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        let groupIndex = op._groups.index(where: { $0 === self._depGroup })
        if let idx = groupIndex {
            let group = op._groups.remove(at: idx)
            group.leave()
        }
#endif
        op.lock.unlock()
        lock.unlock()
    }
    
    open var dependencies: [Operation] {
        lock.lock()
        let ops = _dependencies.map() { $0 }
        lock.unlock()
        return ops
    }
    
    open var queuePriority: QueuePriority = .normal
    public var completionBlock: (() -> Void)?
    open func waitUntilFinished() {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        _group.wait()
#endif
    }
    
    open var threadPriority: Double = 0.5
    
    /// - Note: Quality of service is not directly supported here since there are not qos class promotions available outside of darwin targets.
    open var qualityOfService: NSQualityOfService = .default
    
    open var name: String?
    
    internal func _waitUntilReady() {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        _depGroup.wait()
#endif
        _ready = true
    }
}

extension Operation {
    public enum QueuePriority : Int {
        case veryLow
        case low
        case normal
        case high
        case veryHigh
    }
}

open class BlockOperation: Operation {
    typealias ExecutionBlock = () -> Void
    internal var _block: () -> Void
    internal var _executionBlocks = [ExecutionBlock]()
    
    public init(block: @escaping () -> Void) {
        _block = block
    }
    
    override open func main() {
        lock.lock()
        let block = _block
        let executionBlocks = _executionBlocks
        lock.unlock()
        block()
        executionBlocks.forEach { $0() }
    }
    
    open func addExecutionBlock(_ block: @escaping () -> Void) {
        lock.lock()
        _executionBlocks.append(block)
        lock.unlock()
    }
    
    open var executionBlocks: [() -> Void] {
        lock.lock()
        let blocks = _executionBlocks
        lock.unlock()
        return blocks
    }
}

public let NSOperationQueueDefaultMaxConcurrentOperationCount: Int = Int.max

internal struct _OperationList {
    var veryLow = [Operation]()
    var low = [Operation]()
    var normal = [Operation]()
    var high = [Operation]()
    var veryHigh = [Operation]()
    var all = [Operation]()
    
    mutating func insert(_ operation: Operation) {
        all.append(operation)
        switch operation.queuePriority {
        case .veryLow:
            veryLow.append(operation)
            break
        case .low:
            low.append(operation)
            break
        case .normal:
            normal.append(operation)
            break
        case .high:
            high.append(operation)
            break
        case .veryHigh:
            veryHigh.append(operation)
            break
        }
    }
    
    mutating func remove(_ operation: Operation) {
        if let idx = all.index(of: operation) {
            all.remove(at: idx)
        }
        switch operation.queuePriority {
        case .veryLow:
            if let idx = veryLow.index(of: operation) {
                veryLow.remove(at: idx)
            }
            break
        case .low:
            if let idx = low.index(of: operation) {
                low.remove(at: idx)
            }
            break
        case .normal:
            if let idx = normal.index(of: operation) {
                normal.remove(at: idx)
            }
            break
        case .high:
            if let idx = high.index(of: operation) {
                high.remove(at: idx)
            }
            break
        case .veryHigh:
            if let idx = veryHigh.index(of: operation) {
                veryHigh.remove(at: idx)
            }
            break
        }
    }
    
    mutating func dequeue() -> Operation? {
        if veryHigh.count > 0 {
            return veryHigh.remove(at: 0)
        }
        if high.count > 0 {
            return high.remove(at: 0)
        }
        if normal.count > 0 {
            return normal.remove(at: 0)
        }
        if low.count > 0 {
            return low.remove(at: 0)
        }
        if veryLow.count > 0 {
            return veryLow.remove(at: 0)
        }
        return nil
    }
    
    var count: Int {
        return all.count
    }
    
    func map<T>(_ transform: @noescape (Operation) throws -> T) rethrows -> [T] {
        return try all.map(transform)
    }
}

open class OperationQueue: NSObject {
    let lock = Lock()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    var __concurrencyGate: DispatchSemaphore?
    var __underlyingQueue: DispatchQueue?
    let queueGroup = DispatchGroup()
#endif
    
    var _operations = _OperationList()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    internal var _concurrencyGate: DispatchSemaphore? {
        get {
            lock.lock()
            let val = __concurrencyGate
            lock.unlock()
            return val
        }
    }

    // This is NOT the behavior of the objective-c variant; it will never re-use a queue and instead for every operation it will create a new one.
    // However this is considerably faster and probably more effecient.
    internal var _underlyingQueue: DispatchQueue {
        lock.lock()
        if let queue = __underlyingQueue {
            lock.unlock()
            return queue
        } else {
            let effectiveName: String
            if let requestedName = _name {
                effectiveName = requestedName
            } else {
                effectiveName = "NSOperationQueue::\(Unmanaged.passUnretained(self).toOpaque())"
            }
            let attr: DispatchQueueAttributes
            if maxConcurrentOperationCount == 1 {
                attr = .serial
            } else {
                attr = .concurrent
                if maxConcurrentOperationCount != NSOperationQueueDefaultMaxConcurrentOperationCount {
                    __concurrencyGate = DispatchSemaphore(value:maxConcurrentOperationCount)
                }
            }
            let queue = DispatchQueue(label: effectiveName, attributes: attr)
            if _suspended {
                queue.suspend()
            }
            __underlyingQueue = queue
            lock.unlock()
            return queue
        }
    }
#endif

    public override init() {
        super.init()
    }

#if DEPLOYMENT_ENABLE_LIBDISPATCH
    internal init(_queue queue: DispatchQueue, maxConcurrentOperations: Int = NSOperationQueueDefaultMaxConcurrentOperationCount) {
        __underlyingQueue = queue
        maxConcurrentOperationCount = maxConcurrentOperations
        super.init()
        queue.setSpecific(key: OperationQueue.OperationQueueKey, value: Unmanaged.passUnretained(self))
    }
#endif

    internal func _dequeueOperation() -> Operation? {
        lock.lock()
        let op = _operations.dequeue()
        lock.unlock()
        return op
    }
    
    open func addOperation(_ op: Operation) {
        addOperations([op], waitUntilFinished: false)
    }
    
    internal func _runOperation() {
        if let op = _dequeueOperation() {
            if !op.isCancelled {
                op._waitUntilReady()
                if !op.isCancelled {
                    op.start()
                }
            }
        }
    }
    
    open func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        var waitGroup: DispatchGroup?
        if wait {
            waitGroup = DispatchGroup()
        }
#endif
        /*
         If QueuePriority was not supported this could be much faster
         since it would not need to have the extra book-keeping for managing a priority
         queue. However this implementation attempts to be similar to the specification.
         As a concequence this means that the dequeue may NOT nessicarly be the same as
         the enqueued operation in this callout. So once the dispatch_block is created
         the operation must NOT be touched; since it has nothing to do with the actual
         execution. The only differential is that the block enqueued to dispatch_async
         is balanced with the number of Operations enqueued to the NSOperationQueue.
         */
        ops.forEach { (operation: Operation) -> Void in
            lock.lock()
            operation._queue = self
            _operations.insert(operation)
            lock.unlock()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
            if let group = waitGroup {
                group.enter()
            }

            let block = DispatchWorkItem(group: queueGroup, flags: .enforceQoS) { () -> Void in
                if let sema = self._concurrencyGate {
                    sema.wait()
                    self._runOperation()
                    sema.signal()
                } else {
                    self._runOperation()
                }
                if let group = waitGroup {
                    group.leave()
                }
            }
            _underlyingQueue.async(execute: block)
#endif
        }
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        if let group = waitGroup {
            group.wait()
        }
#endif
    }
    
    internal func _operationFinished(_ operation: Operation) {
        lock.lock()
        _operations.remove(operation)
        operation._queue = nil
        lock.unlock()
    }
    
    open func addOperationWithBlock(_ block: @escaping () -> Void) {
        let op = BlockOperation(block: block)
        op.qualityOfService = qualityOfService
        addOperation(op)
    }
    
    // WARNING: the return value of this property can never be used to reliably do anything sensible
    open var operations: [Operation] {
        lock.lock()
        let ops = _operations.map() { $0 }
        lock.unlock()
        return ops
    }
    
    // WARNING: the return value of this property can never be used to reliably do anything sensible
    open var operationCount: Int {
        lock.lock()
        let count = _operations.count
        lock.unlock()
        return count
    }
    
    open var maxConcurrentOperationCount: Int = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    internal var _suspended = false
    open var suspended: Bool {
        get {
            return _suspended
        }
        set {
            lock.lock()
            if _suspended != newValue {
                _suspended = newValue
#if DEPLOYMENT_ENABLE_LIBDISPATCH
                if let queue = __underlyingQueue {
                    if newValue {
                        queue.suspend()
                    } else {
                        queue.resume()
                    }
                }
#endif
            }
            lock.unlock()
        }
    }
    
    internal var _name: String?
    open var name: String? {
        get {
            lock.lock()
            let val = _name
            lock.unlock()
            return val
        }
        set {
            lock.lock()
            _name = newValue
#if DEPLOYMENT_ENABLE_LIBDISPATCH
            __underlyingQueue = nil
#endif
            lock.unlock()
        }
    }
    
    open var qualityOfService: NSQualityOfService = .default
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    // Note: this will return non nil whereas the objective-c version will only return non nil when it has been set.
    // it uses a target queue assignment instead of returning the actual underlying queue.
    open var underlyingQueue: DispatchQueue? {
        get {
            lock.lock()
            let queue = __underlyingQueue
            lock.unlock()
            return queue
        }
        set {
            lock.lock()
            __underlyingQueue = newValue
            lock.unlock()
        }
    }
#endif
    
    open func cancelAllOperations() {
        lock.lock()
        let ops = _operations.map() { $0 }
        lock.unlock()
        ops.forEach() { $0.cancel() }
    }
    
    open func waitUntilAllOperationsAreFinished() {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        queueGroup.wait()
#endif
    }
    
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    static let OperationQueueKey = DispatchSpecificKey<Unmanaged<OperationQueue>>()
#endif

    open class func currentQueue() -> OperationQueue? {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        let specific = DispatchQueue.getSpecific(key: OperationQueue.OperationQueueKey)
        if specific == nil {
            if pthread_main_np() == 1 {
                return OperationQueue.mainQueue()
            } else {
                return nil
            }
        } else {
            return specific!.takeUnretainedValue()
        }
#else
        return nil
#endif
    }
    
    open class func mainQueue() -> OperationQueue {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        let specific = DispatchQueue.main.getSpecific(key: OperationQueue.OperationQueueKey)
        if specific == nil {
            return OperationQueue(_queue: DispatchQueue.main, maxConcurrentOperations: 1)
        } else {
            return specific!.takeUnretainedValue()
        }
#else
        fatalError("NSOperationQueue requires libdispatch")
#endif
    }
}
