// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

#if DEPLOYMENT_ENABLE_LIBDISPATCH
import Dispatch

open class Operation : NSObject {
    
    fileprivate typealias OperationCompletionBlock = ((_:Operation) -> Void)
    
    fileprivate let lock = NSLock()
    fileprivate weak var _queue: OperationQueue? {
        willSet {
            assert(_queue == nil || newValue == nil, "Operation already added to other queue")
        }
    }
    fileprivate var _cancelled = false
    fileprivate var _executing = false
    fileprivate var _finished = false
    fileprivate var _ready = true
    fileprivate var _dependencies = Set<Operation>()
    fileprivate var _waitGroup: DispatchGroup?
    fileprivate var _queueWaitGroup: DispatchGroup?
    fileprivate var _dependencyCompletionBlocks = [OperationCompletionBlock]()
    
    public override init() {
        super.init()
    }
    
    open func start() {
        if !isCancelled {
            lock.synchronized {
                _executing = true
            }
            main()
            lock.synchronized {
                _executing = false
            }
        }
        finish()
    }
    
    internal func finish() {
        lock.synchronized {
            _finished = true
            _waitGroup?.leave()
            _waitGroup = nil
            _queueWaitGroup?.leave()
            _dependencyCompletionBlocks.forEach {
                $0(self)
            }
            _dependencyCompletionBlocks.removeAll()
        }
        if let queue = _queue {
            queue._operationFinished(self)
        }
        // The completion block property is a bit cagey and can not be executed locally on the queue due to thread exhaust potentials.
        // This sets up for some strange behavior of finishing operations since the handler will be executed on a different queue
        if let completion = completionBlock {
            DispatchQueue.global(qos: .background).async { () -> Void in
                completion()
            }
        }
    }
    
    open func main() { }
    
    open var isCancelled: Bool {
        return lock.synchronized { _cancelled }
    }
    
    open func cancel() {
        // Note that calling cancel() is advisory. It is up to the main() function to
        // call isCancelled at appropriate points in its execution flow and to do the
        // actual canceling work. Eventually main() will invoke finish() and this is
        // where we then leave the groups and unblock other operations that might
        // depend on us.
        var isReadyChanged = false
        lock.synchronized {
            _cancelled = true
            // In macOS 10.6 and later, if you cancel an operation while it is waiting on the completion of
            // one or more dependent operations, those dependencies are thereafter ignored and the
            // value of this property is updated to reflect that it is now ready to run. This behavior gives
            // an operation queue the chance to flush cancelled operations out of its queue more quickly.
            if _ready == false {
                _ready = true
                isReadyChanged = true
            }
        }
        if isReadyChanged {
            didChangeValue(forKey: "isReady")
        }
    }
    
    open var isExecuting: Bool {
        return lock.synchronized { _executing }
    }
    
    open var isFinished: Bool {
        return lock.synchronized { _finished }
    }
    
    // - Note: This property is NEVER used in the objective-c implementation!
    open var isAsynchronous: Bool {
        return false
    }
    
    open var isReady: Bool {
        return lock.synchronized { _ready }
    }
    
    open func addDependency(_ op: Operation) {
        assert(!isFinished, "Operarion already finished")
        assert(!isCancelled, "Operarion already canceled")
        assert(!isExecuting, "Operarion already started")
        op.lock.synchronized {
            if op._finished {
                return
            }
            lock.synchronized {
                _ready = false
                _dependencies.insert(op)
            }
            op._dependencyCompletionBlocks.append { [weak self] completedOperation in
                self?.removeDependency(completedOperation)
            }
        }
    }
    
    open func removeDependency(_ op: Operation) {
        var isReadyChanged = false
        lock.synchronized {
            guard _dependencies.remove(op) != nil else {
                return
            }
            if _dependencies.count == 0 {
                if _ready == false {
                    _ready = true
                    isReadyChanged = true
                }
            }
        }
        if isReadyChanged {
            didChangeValue(forKey: "isReady")
        }
    }
    
    open var dependencies: [Operation] {
        return lock.synchronized {
            _dependencies.map() { $0 }
        }
    }
    
    open var queuePriority: QueuePriority = .normal
    public var completionBlock: (() -> Void)?
    open func waitUntilFinished() {
        lock.synchronized {
            if !_finished && _waitGroup == nil {
                _waitGroup = DispatchGroup()
                _waitGroup?.enter()
            }
        }
        // if operation already finished `_waitGroup` should be nil
        _waitGroup?.wait()
    }
    
    open var threadPriority: Double = 0.5
    
    /// - Note: Quality of service is not directly supported here since there are not qos class promotions available outside of darwin targets.
    open var qualityOfService: QualityOfService = .default
    
    open var name: String?
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
        if key == "isReady" && isReady {
            _queue?._drainQueue()
        }
    }
}

open class BlockOperation: Operation {
    typealias ExecutionBlock = () -> Void
    fileprivate var _executionBlocks: [ExecutionBlock]
    
    public init(block: @escaping () -> Void) {
        _executionBlocks = [block]
    }
    
    override open func main() {
        let executionBlocks = lock.synchronized { _executionBlocks }
        executionBlocks.forEach { $0() }
    }
    
    open func addExecutionBlock(_ block: @escaping () -> Void) {
        lock.synchronized {
            _executionBlocks.append(block)
        }
    }
    
    open var executionBlocks: [() -> Void] {
        return lock.synchronized { _executionBlocks }
    }
}

fileprivate struct _OperationList {
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
    
    func dequeueIfReady(from operations: inout [Operation]) -> Operation? {
        if operations.isEmpty {
            return nil
        }
        
        for (i, operation) in operations.enumerated() {
            if operation.isReady {
                operations.remove(at: i)
                return operation
            }
        }
        
        return nil
    }
    
    mutating func dequeueIfReady() -> Operation? {
        if let operation = dequeueIfReady(from: &veryHigh) {
            return operation
        }
        if let operation = dequeueIfReady(from: &high) {
            return operation
        }
        if let operation = dequeueIfReady(from: &normal) {
            return operation
        }
        if let operation = dequeueIfReady(from: &low) {
            return operation
        }
        if let operation = dequeueIfReady(from: &veryLow) {
            return operation
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
    fileprivate let lock = NSLock()
    fileprivate var __underlyingQueue: DispatchQueue? {
        didSet {
            let key = OperationQueue.OperationQueueKey
            oldValue?.setSpecific(key: key, value: nil)
            __underlyingQueue?.setSpecific(key: key, value: Unmanaged.passUnretained(self))
        }
    }
    fileprivate let queueGroup = DispatchGroup()
    fileprivate var _operations = _OperationList()
    fileprivate var _runningOperationCount = 0
    fileprivate var _maxConcurrentOperationCount = Int.max
    
    // This is NOT the behavior of the objective-c variant; it will never re-use a queue and instead for every operation it will create a new one.
    // However this is considerably faster and probably more effecient.
    fileprivate var _underlyingQueue: DispatchQueue {
        if let queue = __underlyingQueue {
            return queue
        } else {
            let effectiveName: String
            if let requestedName = _name {
                effectiveName = requestedName
            } else {
                effectiveName = "NSOperationQueue::\(Unmanaged.passUnretained(self).toOpaque())"
            }
            let qos: DispatchQoS
            switch qualityOfService {
            case .background: qos = DispatchQoS(qosClass: .background, relativePriority: 0)
            case .`default`: qos = DispatchQoS(qosClass: .`default`, relativePriority: 0)
            case .userInitiated: qos = DispatchQoS(qosClass: .userInitiated, relativePriority: 0)
            case .userInteractive: qos = DispatchQoS(qosClass: .userInteractive, relativePriority: 0)
            case .utility: qos = DispatchQoS(qosClass: .utility, relativePriority: 0)
            }
            // Always .concurrent because maxConcurrentOperationCount is immutable
            let queue = DispatchQueue(label: effectiveName, qos: qos, attributes: .concurrent)
            if _suspended {
                queue.suspend()
            }
            __underlyingQueue = queue
            return queue
        }
    }
    
    public override init() {
        super.init()
    }
    
    internal init(_queue queue: DispatchQueue, maxConcurrentOperations: Int = OperationQueue.defaultMaxConcurrentOperationCount) {
        __underlyingQueue = queue
        super.init()
        maxConcurrentOperationCount = maxConcurrentOperations
        queue.setSpecific(key: OperationQueue.OperationQueueKey, value: Unmanaged.passUnretained(self))
    }
    
    open func addOperation(_ op: Operation) {
        addOperations([op], waitUntilFinished: false)
    }
    
    fileprivate func _drainQueue() {
        lock.synchronized {
            while !_suspended && _runningOperationCount < _maxConcurrentOperationCount, let op = _operations.dequeueIfReady() {
                let block = DispatchWorkItem(flags: .enforceQoS) {
                    op.start()
                }
                _runningOperationCount += 1
                _underlyingQueue.async(execute: block)
            }
        }
    }
    
    open func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        var waitGroup: DispatchGroup?
        if wait {
            waitGroup = DispatchGroup()
        }
        lock.synchronized {
            ops.forEach { (operation: Operation) -> Void in
                operation.lock.synchronized {
                    assert(operation._finished == false, "Operation already finished")
                    assert(operation._executing == false, "Operation already started")
                    operation._queue = self
                    if let waitGroup = waitGroup {
                        waitGroup.enter()
                        operation._queueWaitGroup = waitGroup
                    }
                }
                queueGroup.enter()
                _operations.insert(operation)
            }
        }
        self._drainQueue()
        if let waitGroup = waitGroup {
            waitGroup.wait()
        }
    }
    
    fileprivate func _operationFinished(_ operation: Operation) {
        lock.synchronized {
            queueGroup.leave()
            _operations.remove(operation)
            _runningOperationCount -= 1
            operation._queue = nil
        }
        _drainQueue()
    }
    
    open func addOperation(_ block: @escaping () -> Swift.Void) {
        let op = BlockOperation(block: block)
        op.qualityOfService = qualityOfService
        addOperation(op)
    }
    
    // WARNING: the return value of this property can never be used to reliably do anything sensible
    open var operations: [Operation] {
        return lock.synchronized {
            _operations.map() { $0 }
        }
    }
    
    // WARNING: the return value of this property can never be used to reliably do anything sensible
    open var operationCount: Int {
        return lock.synchronized { _operations.count }
    }
    
    open var maxConcurrentOperationCount: Int {
        get {
            return lock.synchronized { _maxConcurrentOperationCount }
        }
        set {
            let increasing: Bool = lock.synchronized {
                let increasing = _maxConcurrentOperationCount < newValue
                _maxConcurrentOperationCount = newValue
                return increasing
            }
            
            if increasing {
                _drainQueue()
            }
        }
    }
    
    fileprivate var _suspended = false
    open var isSuspended: Bool {
        get {
            return lock.synchronized { _suspended }
        }
        set {
            lock.synchronized {
                if _suspended != newValue {
                    _suspended = newValue
                }
            }
            if newValue == false {
                _drainQueue()
            }
        }
    }
    
    fileprivate var _name: String?
    open var name: String? {
        get {
            return lock.synchronized { _name }
        }
        set {
            lock.synchronized {
                _name = newValue
                __underlyingQueue = nil
            }
        }
    }
    
    open var qualityOfService: QualityOfService = .default
    
    // Note: this will return non nil whereas the objective-c version will only return non nil when it has been set.
    // it uses a target queue assignment instead of returning the actual underlying queue.
    open var underlyingQueue: DispatchQueue? {
        get {
            return lock.synchronized { __underlyingQueue }
        }
        set {
            lock.synchronized {
                __underlyingQueue = newValue
            }
        }
    }
    
    open func cancelAllOperations() {
        let ops = lock.synchronized {
            _operations.map() { $0 }
        }
        ops.forEach() { $0.cancel() }
    }
    
    open func waitUntilAllOperationsAreFinished() {
        queueGroup.wait()
    }
    
    fileprivate static let OperationQueueKey = DispatchSpecificKey<Unmanaged<OperationQueue>>()
    
    open class var current: OperationQueue? {
        guard let specific = DispatchQueue.getSpecific(key: OperationQueue.OperationQueueKey) else {
            if _CFIsMainThread() {
                return OperationQueue.main
            } else {
                return nil
            }
        }
        
        return specific.takeUnretainedValue()
    }
    
    private static let _main = OperationQueue(_queue: .main, maxConcurrentOperations: 1)
    
    open class var main: OperationQueue {
        return _main
    }
}
#else

open class Operation : NSObject {
    
    public override init() {
        super.init()
    }
    
    open func start() {
        NSUnimplemented()
    }
    
    open func main() {
        NSUnimplemented()
    }
    
    open var isCancelled: Bool {
        NSUnimplemented()
    }
    
    open func cancel() {
        NSUnimplemented()
    }
    
    open var isExecuting: Bool {
        NSUnimplemented()
    }
    
    open var isFinished: Bool {
        NSUnimplemented()
    }
    
    // - Note: This property is NEVER used in the objective-c implementation!
    open var isAsynchronous: Bool {
        NSUnimplemented()
    }
    
    open var isReady: Bool {
        NSUnimplemented()
    }
    
    open func addDependency(_ op: Operation) {
        NSUnimplemented()
    }
    
    open func removeDependency(_ op: Operation) {
        NSUnimplemented()
    }
    
    open var dependencies: [Operation] {
        NSUnimplemented()
    }
    
    open var queuePriority: QueuePriority {
        NSUnimplemented()
    }
    
    public var completionBlock: (() -> Void)?
    
    open func waitUntilFinished() {
        NSUnimplemented()
    }
    
    open var threadPriority: Double = 0.5
    
    open var qualityOfService: QualityOfService = .default
    
    open var name: String?
}

open class BlockOperation: Operation {
    typealias ExecutionBlock = () -> Void
    
    public init(block: @escaping () -> Void) {
        super.init()
    }
    
    override open func main() {
        NSUnimplemented()
    }
    
    open func addExecutionBlock(_ block: @escaping () -> Void) {
        NSUnimplemented()
    }
    
    open var executionBlocks: [() -> Void] {
        NSUnimplemented()
    }
}

open class OperationQueue: NSObject {
    
    public override init() {
        super.init()
    }
    
    internal init(_queue queue: DispatchQueue, maxConcurrentOperations: Int = OperationQueue.defaultMaxConcurrentOperationCount) {
        super.init()
    }
    
    open func addOperation(_ op: Operation) {
        NSUnimplemented()
    }
    
    open func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) {
        NSUnimplemented()
    }
    
    open func addOperation(_ block: @escaping () -> Swift.Void) {
        NSUnimplemented()
    }
    
    open var operations: [Operation] {
        NSUnimplemented()
    }
    
    open var operationCount: Int {
        NSUnimplemented()
    }
    
    open var maxConcurrentOperationCount: Int {
        NSUnimplemented()
    }
    
    open var isSuspended: Bool {
        NSUnimplemented()
    }
    
    open var name: String? {
        NSUnimplemented()
    }
    
    open var qualityOfService: QualityOfService = .default
    
    open var underlyingQueue: DispatchQueue? {
        NSUnimplemented()
    }
    
    open func cancelAllOperations() {
        NSUnimplemented()
    }
    
    open func waitUntilAllOperationsAreFinished() {
        NSUnimplemented()
    }
    
    open class var current: OperationQueue? {
        NSUnimplemented()
    }
    
    open class var main: OperationQueue {
        NSUnimplemented()
    }
}
#endif

extension Operation {
    public enum QueuePriority : Int {
        case veryLow
        case low
        case normal
        case high
        case veryHigh
    }
}

public extension OperationQueue {
    static let defaultMaxConcurrentOperationCount: Int = Int.max
}
