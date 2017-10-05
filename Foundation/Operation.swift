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
#endif
import CoreFoundation

open class Operation : NSObject {
    let lock = NSLock()
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
    
    open func start() {
        if !isCancelled {
            lock.lock()
            _executing = true
            lock.unlock()
            main()
            lock.lock()
            _executing = false
            lock.unlock()
        }
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
            DispatchQueue.global(qos: .background).async { () -> Void in
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
        // Note that calling cancel() is advisory. It is up to the main() function to
        // call isCancelled at appropriate points in its execution flow and to do the
        // actual canceling work. Eventually main() will invoke finish() and this is
        // where we then leave the groups and unblock other operations that might
        // depend on us.
        lock.lock()
        _cancelled = true
        lock.unlock()
    }
    
    open var isExecuting: Bool {
        let wasExecuting: Bool
        lock.lock()
        wasExecuting = _executing
        lock.unlock()

        return wasExecuting
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
    open var qualityOfService: QualityOfService = .default
    
    open var name: String?
    
    internal func _waitUntilReady() {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        _depGroup.wait()
#endif
        _ready = true
    }
}

/// The following two methods are added to provide support for Operations which
/// are asynchronous from the execution of the operation queue itself.  On Darwin,
/// this is supported via KVO notifications.  In the absence of KVO on non-Darwin
/// platforms, these two methods (which are defined in NSObject on Darwin) are
/// temporarily added here.  They should be removed once a permanent solution is
/// found.
extension Operation {
    public func willChangeValue(forKey key: String) {
        // do nothing
    }

    public func didChangeValue(forKey key: String) {
        if key == "isFinished" && isFinished {
            finish()
        }
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

public extension OperationQueue {
    public static let defaultMaxConcurrentOperationCount: Int = Int.max
}

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
        case .low:
            low.append(operation)
        case .normal:
            normal.append(operation)
        case .high:
            high.append(operation)
        case .veryHigh:
            veryHigh.append(operation)
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
        case .low:
            if let idx = low.index(of: operation) {
                low.remove(at: idx)
            }
        case .normal:
            if let idx = normal.index(of: operation) {
                normal.remove(at: idx)
            }
        case .high:
            if let idx = high.index(of: operation) {
                high.remove(at: idx)
            }
        case .veryHigh:
            if let idx = veryHigh.index(of: operation) {
                veryHigh.remove(at: idx)
            }
        }
    }
    
    mutating func dequeue() -> Operation? {
        if !veryHigh.isEmpty {
            return veryHigh.remove(at: 0)
        }
        if !high.isEmpty {
            return high.remove(at: 0)
        }
        if !normal.isEmpty {
            return normal.remove(at: 0)
        }
        if !low.isEmpty {
            return low.remove(at: 0)
        }
        if !veryLow.isEmpty {
            return veryLow.remove(at: 0)
        }
        return nil
    }
    
    var count: Int {
        return all.count
    }
    
    func map<T>(_ transform: (Operation) throws -> T) rethrows -> [T] {
        return try all.map(transform)
    }
}

open class OperationQueue: NSObject {
    let lock = NSLock()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    var __concurrencyGate: DispatchSemaphore?
    var __underlyingQueue: DispatchQueue? {
        didSet {
            let key = OperationQueue.OperationQueueKey
            oldValue?.setSpecific(key: key, value: nil)
            __underlyingQueue?.setSpecific(key: key, value: Unmanaged.passUnretained(self))
        }
    }
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
            let attr: DispatchQueue.Attributes
            if maxConcurrentOperationCount == 1 {
                attr = []
                __concurrencyGate = DispatchSemaphore(value: 1)
            } else {
                attr = .concurrent
                if maxConcurrentOperationCount != OperationQueue.defaultMaxConcurrentOperationCount {
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
    internal init(_queue queue: DispatchQueue, maxConcurrentOperations: Int = OperationQueue.defaultMaxConcurrentOperationCount) {
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
         is balanced with the number of Operations enqueued to the OperationQueue.
         */
        lock.lock()
        ops.forEach { (operation: Operation) -> Void in
            operation._queue = self
            _operations.insert(operation)
        }
        lock.unlock()
        ops.forEach { (operation: Operation) -> Void in
#if DEPLOYMENT_ENABLE_LIBDISPATCH
            if let group = waitGroup {
                group.enter()
            }

            let block = DispatchWorkItem(flags: .enforceQoS) { () -> Void in
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
            _underlyingQueue.async(group: queueGroup, execute: block)
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
    
    open func addOperation(_ block: @escaping () -> Swift.Void) {
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
    
    open var maxConcurrentOperationCount: Int = OperationQueue.defaultMaxConcurrentOperationCount
    
    internal var _suspended = false
    open var isSuspended: Bool {
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
    
    open var qualityOfService: QualityOfService = .default
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

    open class var current: OperationQueue? {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        guard let specific = DispatchQueue.getSpecific(key: OperationQueue.OperationQueueKey) else {
            if _CFIsMainThread() {
                return OperationQueue.main
            } else {
                return nil
            }
        }
        
        return specific.takeUnretainedValue()
#else
        return nil
#endif
    }
    
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    private static let _main = OperationQueue(_queue: .main, maxConcurrentOperations: 1)
#endif
    
    open class var main: OperationQueue {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        return _main
#else
        fatalError("OperationQueue requires libdispatch")
#endif
    }
}
