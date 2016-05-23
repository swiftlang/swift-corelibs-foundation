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

public class NSOperation : NSObject {
    let lock = NSLock()
    internal weak var _queue: NSOperationQueue?
    internal var _cancelled = false
    internal var _executing = false
    internal var _finished = false
    internal var _ready = false
    internal var _dependencies = Set<NSOperation>()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    internal var _group = dispatch_group_create()
    internal var _depGroup = dispatch_group_create()
    internal var _groups = [dispatch_group_t]()
#endif
    
    public override init() {
        super.init()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        dispatch_group_enter(_group)
#endif
    }
    
    internal func _leaveGroups() {
        // assumes lock is taken
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        _groups.forEach() { dispatch_group_leave($0) }
        _groups.removeAll()
        dispatch_group_leave(_group)
#endif
    }
    
    /// - Note: Operations that are asynchronous from the execution of the operation queue itself are not supported since there is no KVO to trigger the finish.
    public func start() {
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
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
                completion()
            }
        }
#endif
    }
    
    public func main() { }
    
    public var cancelled: Bool {
        return _cancelled
    }
    
    public func cancel() {
        lock.lock()
        _cancelled = true
        _leaveGroups()
        lock.unlock()
    }
    
    public var executing: Bool {
        return _executing
    }
    
    public var finished: Bool {
        return _finished
    }
    
    // - Note: This property is NEVER used in the objective-c implementation!
    public var asynchronous: Bool {
        return false
    }
    
    public var ready: Bool {
        return _ready
    }
    
    public func addDependency(_ op: NSOperation) {
        lock.lock()
        _dependencies.insert(op)
        op.lock.lock()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        dispatch_group_enter(_depGroup)
        op._groups.append(_depGroup)
#endif
        op.lock.unlock()
        lock.unlock()
    }
    
    public func removeDependency(_ op: NSOperation) {
        lock.lock()
        _dependencies.remove(op)
        op.lock.lock()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        let groupIndex = op._groups.index(where: { $0 === self._depGroup })
        if let idx = groupIndex {
            let group = op._groups.remove(at: idx)
            dispatch_group_leave(group)
        }
#endif
        op.lock.unlock()
        lock.unlock()
    }
    
    public var dependencies: [NSOperation] {
        lock.lock()
        let ops = _dependencies.map() { $0 }
        lock.unlock()
        return ops
    }
    
    public var queuePriority: OperationQueuePriority = .Normal
    public var completionBlock: (() -> Void)?
    public func waitUntilFinished() {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        dispatch_group_wait(_group, DISPATCH_TIME_FOREVER)
#endif
    }
    
    public var threadPriority: Double = 0.5
    
    /// - Note: Quality of service is not directly supported here since there are not qos class promotions available outside of darwin targets.
    public var qualityOfService: NSQualityOfService = .default
    
    public var name: String?
    
    internal func _waitUntilReady() {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        dispatch_group_wait(_depGroup, DISPATCH_TIME_FOREVER)
#endif
        _ready = true
    }
}

public enum OperationQueuePriority : Int {
    case VeryLow
    case Low
    case Normal
    case High
    case VeryHigh
}

public class NSBlockOperation : NSOperation {
    typealias ExecutionBlock = () -> Void
    internal var _block: () -> Void
    internal var _executionBlocks = [ExecutionBlock]()
    
    public init(block: () -> Void) {
        _block = block
    }
    
    override public func main() {
        lock.lock()
        let block = _block
        let executionBlocks = _executionBlocks
        lock.unlock()
        block()
        executionBlocks.forEach { $0() }
    }
    
    public func addExecutionBlock(_ block: () -> Void) {
        lock.lock()
        _executionBlocks.append(block)
        lock.unlock()
    }
    
    public var executionBlocks: [() -> Void] {
        lock.lock()
        let blocks = _executionBlocks
        lock.unlock()
        return blocks
    }
}

public let NSOperationQueueDefaultMaxConcurrentOperationCount: Int = Int.max

internal struct _OperationList {
    var veryLow = [NSOperation]()
    var low = [NSOperation]()
    var normal = [NSOperation]()
    var high = [NSOperation]()
    var veryHigh = [NSOperation]()
    var all = [NSOperation]()
    
    mutating func insert(_ operation: NSOperation) {
        all.append(operation)
        switch operation.queuePriority {
        case .VeryLow:
            veryLow.append(operation)
            break
        case .Low:
            low.append(operation)
            break
        case .Normal:
            normal.append(operation)
            break
        case .High:
            high.append(operation)
            break
        case .VeryHigh:
            veryHigh.append(operation)
            break
        }
    }
    
    mutating func remove(_ operation: NSOperation) {
        if let idx = all.index(of: operation) {
            all.remove(at: idx)
        }
        switch operation.queuePriority {
        case .VeryLow:
            if let idx = veryLow.index(of: operation) {
                veryLow.remove(at: idx)
            }
            break
        case .Low:
            if let idx = low.index(of: operation) {
                low.remove(at: idx)
            }
            break
        case .Normal:
            if let idx = normal.index(of: operation) {
                normal.remove(at: idx)
            }
            break
        case .High:
            if let idx = high.index(of: operation) {
                high.remove(at: idx)
            }
            break
        case .VeryHigh:
            if let idx = veryHigh.index(of: operation) {
                veryHigh.remove(at: idx)
            }
            break
        }
    }
    
    mutating func dequeue() -> NSOperation? {
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
    
    func map<T>(_ transform: @noescape (NSOperation) throws -> T) rethrows -> [T] {
        return try all.map(transform)
    }
}

public class NSOperationQueue : NSObject {
    let lock = NSLock()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    var __concurrencyGate: dispatch_semaphore_t?
    var __underlyingQueue: dispatch_queue_t?
    let queueGroup = dispatch_group_create()
#endif
    
    var _operations = _OperationList()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    internal var _concurrencyGate: dispatch_semaphore_t? {
        get {
            lock.lock()
            let val = __concurrencyGate
            lock.unlock()
            return val
        }
    }

    // This is NOT the behavior of the objective-c variant; it will never re-use a queue and instead for every operation it will create a new one.
    // However this is considerably faster and probably more effecient.
    internal var _underlyingQueue: dispatch_queue_t {
        lock.lock()
        if let queue = __underlyingQueue {
            lock.unlock()
            return queue
        } else {
            let effectiveName: String
            if let requestedName = _name {
                effectiveName = requestedName
            } else {
                effectiveName = "NSOperationQueue::\(unsafeAddress(of: self))"
            }
            let attr: dispatch_queue_attr_t?
            if maxConcurrentOperationCount == 1 {
                attr = DISPATCH_QUEUE_SERIAL
            } else {
                attr = DISPATCH_QUEUE_CONCURRENT
                if maxConcurrentOperationCount != NSOperationQueueDefaultMaxConcurrentOperationCount {
                    __concurrencyGate = dispatch_semaphore_create(maxConcurrentOperationCount)
                }
            }
            let queue = dispatch_queue_create(effectiveName, attr)
            if _suspended {
                dispatch_suspend(queue)
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
    internal init(_queue queue: dispatch_queue_t, maxConcurrentOperations: Int = NSOperationQueueDefaultMaxConcurrentOperationCount) {
        __underlyingQueue = queue
        maxConcurrentOperationCount = maxConcurrentOperations
        super.init()
        dispatch_queue_set_specific(queue, NSOperationQueue.OperationQueueKey, unsafeBitCast(Unmanaged.passUnretained(self), to: UnsafeMutablePointer<Void>.self), nil)
        
    }
#endif

    internal func _dequeueOperation() -> NSOperation? {
        lock.lock()
        let op = _operations.dequeue()
        lock.unlock()
        return op
    }
    
    public func addOperation(_ op: NSOperation) {
        addOperations([op], waitUntilFinished: false)
    }
    
    internal func _runOperation() {
        if let op = _dequeueOperation() {
            if !op.cancelled {
                op._waitUntilReady()
                if !op.cancelled {
                    op.start()
                }
            }
        }
    }
    
    public func addOperations(_ ops: [NSOperation], waitUntilFinished wait: Bool) {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        var waitGroup: dispatch_group_t?
        if wait {
            waitGroup = dispatch_group_create()
        }
#endif
        /*
         If OperationQueuePriority was not supported this could be much faster
         since it would not need to have the extra book-keeping for managing a priority
         queue. However this implementation attempts to be similar to the specification.
         As a concequence this means that the dequeue may NOT nessicarly be the same as
         the enqueued operation in this callout. So once the dispatch_block is created
         the operation must NOT be touched; since it has nothing to do with the actual
         execution. The only differential is that the block enqueued to dispatch_async
         is balanced with the number of Operations enqueued to the NSOperationQueue.
         */
        ops.forEach { (operation: NSOperation) -> Void in
            lock.lock()
            operation._queue = self
            _operations.insert(operation)
            lock.unlock()
#if DEPLOYMENT_ENABLE_LIBDISPATCH
            if let group = waitGroup {
                dispatch_group_enter(group)
            }
            
            let block = dispatch_block_create(DISPATCH_BLOCK_ENFORCE_QOS_CLASS) { () -> Void in
                if let sema = self._concurrencyGate {
                    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
                    self._runOperation()
                    dispatch_semaphore_signal(sema)
                } else {
                    self._runOperation()
                }
                if let group = waitGroup {
                    dispatch_group_leave(group)
                }
            }
            dispatch_group_async(queueGroup, _underlyingQueue, block)
#endif
        }
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        if let group = waitGroup {
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        }
#endif
    }
    
    internal func _operationFinished(_ operation: NSOperation) {
        lock.lock()
        _operations.remove(operation)
        operation._queue = nil
        lock.unlock()
    }
    
    public func addOperationWithBlock(_ block: () -> Void) {
        let op = NSBlockOperation(block: block)
        op.qualityOfService = qualityOfService
        addOperation(op)
    }
    
    // WARNING: the return value of this property can never be used to reliably do anything sensible
    public var operations: [NSOperation] {
        lock.lock()
        let ops = _operations.map() { $0 }
        lock.unlock()
        return ops
    }
    
    // WARNING: the return value of this property can never be used to reliably do anything sensible
    public var operationCount: Int {
        lock.lock()
        let count = _operations.count
        lock.unlock()
        return count
    }
    
    public var maxConcurrentOperationCount: Int = NSOperationQueueDefaultMaxConcurrentOperationCount
    
    internal var _suspended = false
    public var suspended: Bool {
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
                        dispatch_suspend(queue)
                    } else {
                        dispatch_resume(queue)
                    }
                }
#endif
            }
            lock.unlock()
        }
    }
    
    internal var _name: String?
    public var name: String? {
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
    
    public var qualityOfService: NSQualityOfService = .default
#if DEPLOYMENT_ENABLE_LIBDISPATCH
    // Note: this will return non nil whereas the objective-c version will only return non nil when it has been set.
    // it uses a target queue assignment instead of returning the actual underlying queue.
    public var underlyingQueue: dispatch_queue_t? {
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
    
    public func cancelAllOperations() {
        lock.lock()
        let ops = _operations.map() { $0 }
        lock.unlock()
        ops.forEach() { $0.cancel() }
    }
    
    public func waitUntilAllOperationsAreFinished() {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        dispatch_group_wait(queueGroup, DISPATCH_TIME_FOREVER)
#endif
    }
    
    static let OperationQueueKey = UnsafePointer<Void>(UnsafeMutablePointer<Void>(allocatingCapacity: 1))
    
    public class func currentQueue() -> NSOperationQueue? {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        let specific = dispatch_get_specific(NSOperationQueue.OperationQueueKey)
        if specific == nil {
            if pthread_main_np() == 1 {
                return NSOperationQueue.mainQueue()
            } else {
                return nil
            }
        } else {
            return Unmanaged<NSOperationQueue>.fromOpaque(unsafeBitCast(specific, to: UnsafePointer<Void>.self)).takeUnretainedValue()
        }
#else
        return nil
#endif
    }
    
    public class func mainQueue() -> NSOperationQueue {
#if DEPLOYMENT_ENABLE_LIBDISPATCH
        let specific = dispatch_queue_get_specific(dispatch_get_main_queue(), NSOperationQueue.OperationQueueKey)
        if specific == nil {
            return NSOperationQueue(_queue: dispatch_get_main_queue(), maxConcurrentOperations: 1)
        } else {
            return Unmanaged<NSOperationQueue>.fromOpaque(unsafeBitCast(specific, to: UnsafePointer<Void>.self)).takeUnretainedValue()
        }
#else
        fatalError("NSOperationQueue requires libdispatch")
#endif
    }
}
