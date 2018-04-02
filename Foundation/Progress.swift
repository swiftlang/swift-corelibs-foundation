// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if os(macOS) || os(iOS)
import Darwin
#elseif os(Linux)
import Glibc
#endif

import Dispatch

/**
 `Progress` is used to report the amount of work done, and provides a way to allow the user to cancel that work.
 
 Since work is often split up into several parts, progress objects can form a tree where children represent part of the overall total work. Each parent may have as many children as required, but each child only has one parent. The top level progress object in this tree is typically the one that you would display to a user. The leaf objects are updated as work completes, and the updates propagate up the tree.
 
 The work that a `Progress` does is tracked via a "unit count." There are two unit count values: total and completed. In its leaf form, a `Progress` is created with a total unit count and its completed unit count is updated by setting `completedUnitCount` until it matches the `totalUnitCount`. The progress is then considered finished.
 
 When progress objects form nodes in trees, they are still created with a total unit count. Portions of the total are then handed out to children as a "pending unit count." The total amount handed out to children should add up to the parent's `totalUnitCount`. When those children become finished, the pending unit count assigned to that child is added to the parent's `completedUnitCount`. Therefore, when all children are finished, the parent's `completedUnitCount` is equal to its `totalUnitCount` and it becomes finished itself.
 
 Children `Progress` objects can be added implicitly or by calling `addChild(withPendingUnitCount)` on the parent. Implicitly added children are attached to a parent progress between a call to `becomeCurrent(withPendingUnitCount)` and a call to `resignCurrent`. The implicit child is created with the `Progress(totalUnitCount:)` initializer, or by passing the result of `Progress.currentProgress` to the `Progress(parent:userInfo:)` initializer. Both kinds of children can be attached to the same parent progress object. If you have an idea in advance that some portions of the work will take more or less time than the others, you can use different values of pending unit count for each child.
 
 If you are designing an interface of an object that reports progress, then the recommended approach is to vend a `Progress` property and adopt the `ProgressReporting` protocol. The progress should be created with the `Progress.discreteProgress(withTotalUnitCount:)` class function. You can then either update the progress object directly or set it up to have children of its own. Users of your object can compose your progress into their tree by using the `addChild(withPendingUnitCount)` function.
 
 If you want to provide progress reporting for a single method, then the recommended approach is to implicitly attach to a current `Progress` by creating an `Progress` object at the very beginning of your method using `Progress(withTotalUnitCount)`. This progress object will consume the pending unit count, and then you can set up the progress object with children of its own.

 The `localizedDescription` and `localizedAdditionalDescription` properties are meant to be observed as well as set. So are the `cancellable` and `pausable` properties. `totalUnitCount` and `completedUnitCount`, on the other hand, are often not the best properties to observe when presenting progress to the user. You should observe `fractionCompleted` instead of observing `totalUnitCount` and `completedUnitCount` and doing your own calculation. `Progress`' default implementation of `fractionCompleted` does fairly sophisticated things like taking child `Progress` into account.
 
 - note: In swift-corelibs-foundation, Key Value Observing is not yet available.
 */
open class Progress : NSObject {
    
    private weak var _parent : Progress?
    private var _children : Set<Progress>
    private var _selfFraction : _ProgressFraction
    private var _childFraction : _ProgressFraction
    private var _userInfo : [ProgressUserInfoKey : Any]
    
    // This is set once, but after initialization
    private var _portionOfParent : Int64
    
    static private var _tsdKey = "_Foundation_CurrentProgressKey"
    
    /// The instance of `Progress` associated with the current thread by a previous invocation of `becomeCurrent(withPendingUnitCount:)`, if any. 
    ///
    /// The purpose of this per-thread value is to allow code that does work to usefully report progress even when it is widely separated from the code that actually presents progress to the user, without requiring layers of intervening code to pass the instance of `Progress` through. Using the result of invoking this directly will often not be the right thing to do, because the invoking code will often not even know what units of work the current progress object deals in. Using `Progress(withTotalUnitCount:)` to create a child `Progress` object and then using that to report progress makes more sense in that situation.
    open class func current() -> Progress? {
        return (Thread.current.threadDictionary[Progress._tsdKey] as? _ProgressTSD)?.currentProgress
    }
    
    /// Initializes an instance of `Progress` with a parent of `Progress.current()`.
    /// 
    /// The value of the `totalUnitCount` property is also set. In many cases you can simply precede code that does a substantial amount of work with an invocation of this method, with repeated setting of the `completedUnitCount` property and synchronous checking of `isCancelled` in the loop that does the work.
    public convenience init(totalUnitCount unitCount: Int64) {
        self.init(parent: Progress.current())
        totalUnitCount = unitCount
    }
    
    /// Initializes an instance of `Progress` with a `nil` parent.
    ///
    /// The value of the `totalUnitCount` property is also set. The resulting progress object is not part of an existing progress tree.
    open class func discreteProgress(totalUnitCount unitCount: Int64) -> Progress {
        let progress = Progress(parent: nil)
        progress.totalUnitCount = unitCount
        return progress
    }
    
    /// Initializes an instance of `Progress` with the specified total unit count, parent, and pending unit count.
    public convenience init(totalUnitCount unitCount: Int64, parent: Progress, pendingUnitCount portionOfParentTotalUnitCount: Int64) {
        self.init(parent: nil)
        totalUnitCount = unitCount
        parent.addChild(self, withPendingUnitCount: portionOfParentTotalUnitCount)
    }
    
    /// Initializes an instance of `Progress` with the specified parent and user info dictionary.
    public init(parent parentProgress: Progress?, userInfo userInfoOrNil: [ProgressUserInfoKey : Any]? = nil) {
        _children = Set()
        
        isCancellable = false
        isPausable = false
        isCancelled = false
        isPaused = false
        
        _selfFraction = _ProgressFraction()
        _childFraction = _ProgressFraction()
        
        // It doesn't matter what the units are here as long as the total is non-zero
        _childFraction.total = 1
        
        // This is reset later, if this progress becomes a child of some other progress
        _portionOfParent = 0
        
        _userInfo = userInfoOrNil ?? [:]
        
        super.init()
        
        if let p = parentProgress {
            precondition(p === Progress.current(), "The Parent must be the current progress")
            p._addImplicitChild(self)
        }
    }
    
    /// MARK: -
    
    /// This is called when some other progress becomes an implicit child of this progress.
    private func _addImplicitChild(_ child : Progress) {
        guard let tsd = Thread.current.threadDictionary[Progress._tsdKey] as? _ProgressTSD else { preconditionFailure("A child was added without a current progress being set") }
        
        // We only allow one implicit child. More than that and things get confusing (and wrong) real quick.
        if !tsd.childAttached {
            addChild(child, withPendingUnitCount: tsd.pendingUnitCount)
            tsd.childAttached = true
        }
    }
    
    /// Make this `Progress` the current thread's current progress object, returned by `Progress.currentProgress()`. 
    ///
    /// At the same time, record how large a portion of the work represented by the progress will be represented by the next progress object initialized with `Progress(parent:userInfo:)` in the current thread with this `Progress` as the parent. The portion of work will be used when the `completedUnitCount` of the child is set.
    ///
    /// With this mechanism, code that doesn't know anything about its callers can report progress accurately by using `Progress(withTotalUnitCount:)` and `completedUnitCount`. The calling code will account for the fact that the work done is only a portion of the work to be done as part of a larger operation.
    ///
    /// The unit of work in a call to `becomeCurrent(withPendingUnitCount:)` has to be the same unit of work as that used for the value of the `totalUnitCount` property, but the unit of work used by the child can be a completely different one, and often will be. 
    ///
    /// You must always balance invocations of this method with invocations of `resignCurrent`.
    open func becomeCurrent(withPendingUnitCount unitCount: Int64) {
        let oldTSD = Thread.current.threadDictionary[Progress._tsdKey] as? _ProgressTSD
        if let checkedTSD = oldTSD {
            precondition(checkedTSD.currentProgress !== self, "This Progress is already current on this thread.")
        }
        
        let newTSD = _ProgressTSD(currentProgress: self, nextTSD: oldTSD, pendingUnitCount: unitCount)
        Thread.current.threadDictionary[Progress._tsdKey] = newTSD
    }
    
    /// Balance the most recent previous invocation of `becomeCurrent(withPendingUnitCount:)` on the same thread.
    ///
    /// This restores the current progress object to what it was before `becomeCurrent(withPendingUnitCount:)` was invoked.
    open func resignCurrent() {
        guard let oldTSD = Thread.current.threadDictionary[Progress._tsdKey] as? _ProgressTSD else {
            preconditionFailure("This Progress was not the current progress on this thread.")
        }
        
        if !oldTSD.childAttached {
            // No children attached. Account for the completed unit count now.
            _addCompletedUnitCount(oldTSD.pendingUnitCount)
        }
        
        // Ok if the following is nil - then we clear the dictionary entry
        let newTSD = oldTSD.nextTSD
        Thread.current.threadDictionary[Progress._tsdKey] = newTSD
    }
    
    /// Directly add a child progress to the receiver, assigning it a portion of the receiver's total unit count.
    open func addChild(_ child: Progress, withPendingUnitCount inUnitCount: Int64) {
        precondition(child._parent == nil, "The Progress was already the child of another Progress")
        
        _children.insert(child)
        
        child._setParent(self, portion: inUnitCount)
        
        if isCancelled {
            child.cancel()
        }
        
        if isPaused {
            child.pause()
        }
    }
    
    private func _setParent(_ parent: Progress, portion: Int64) {
        _parent = parent
        _portionOfParent = portion
        
        // We need to tell the new parent what our fraction completed is
        // The previous fraction is the same as if it didn't exist (0/0), but the new one represents our current state.
        _parent?._updateChild(self, from: _ProgressFraction(completed: 0, total: 0), to: _overallFraction, portion: portion)
    }
    
    /// How much of the job has been completed so far.
    ///
    /// For a `Progress` with a kind of `.file`, the unit of these properties is bytes while the `fileTotalCountKey` and `fileCompletedCountKey` keys in the `userInfo` dictionary are used for the overall count of files. For any other kind of `Progress`, the unit of measurement you use does not matter as long as you are consistent. The values may be reported to the user in the `localizedDescription` and `localizedAdditionalDescription`.
    ///
    /// If the `Progress` object is a "leaf progress" (no children), then the `fractionCompleted` is generally `completedUnitCount / totalUnitCount`. If the receiver `Progress` has children, the `fractionCompleted` will reflect progress made in child objects in addition to its own `completedUnitCount`. As children finish, the `completedUnitCount` of the parent will be updated.
    open var totalUnitCount: Int64 {
        get {
            return _selfFraction.total
        }
        set {
            let previous = _overallFraction
            if _selfFraction.total != newValue && _selfFraction.total > 0 {
                _childFraction = _childFraction * _ProgressFraction(completed: _selfFraction.total, total: newValue)
            }
            _selfFraction.total = newValue
            _updateFractionCompleted(from: previous, to: _overallFraction)
        }
    }
    
    /// The size of the job whose progress is being reported.
    ///
    /// For a `Progress` with a kind of `.file`, the unit of these properties is bytes while the `fileTotalCountKey` and `fileCompletedCountKey` keys in the `userInfo` dictionary are used for the overall count of files. For any other kind of `Progress`, the unit of measurement you use does not matter as long as you are consistent. The values may be reported to the user in the `localizedDescription` and `localizedAdditionalDescription`.
    ///
    /// If the `Progress` object is a "leaf progress" (no children), then the `fractionCompleted` is generally `completedUnitCount / totalUnitCount`. If the receiver `Progress` has children, the `fractionCompleted` will reflect progress made in child objects in addition to its own `completedUnitCount`. As children finish, the `completedUnitCount` of the parent will be updated.
    open var completedUnitCount: Int64 {
        get {
            return _selfFraction.completed
        }
        set {
            let previous = _overallFraction
            _selfFraction.completed = newValue
            _updateFractionCompleted(from: previous, to: _overallFraction)
        }
    }
    
    /// A description of what progress is being made, fit to present to the user. 
    ///
    /// `Progress` is by default KVO-compliant for this property, with the notifications always being sent on thread which updates the property. The default implementation of the getter for this property does not always return the most recently set value of the property. If the most recently set value of this property is nil then `Progress` uses the value of the `kind` property to determine how to use the values of other properties, as well as values in the user info dictionary, to return a computed string. If it fails to do that then it returns an empty string.
    ///
    ///  For example, depending on the kind of progress, the completed and total unit counts, and other parameters, these kinds of strings may be generated:
    ///    Copying 10 files…
    ///    30% completed
    ///    Copying “TextEdit”…
    ///  - note: In swift-corelibs-foundation, Key Value Observing is not yet available.
    open var localizedDescription: String! {
        // Unimplemented
        return ""
    }
    
    /// A more specific description of what progress is being made, fit to present to the user. 
    ///
    /// `Progress` is by default KVO-compliant for this property, with the notifications always being sent on thread which updates the property. The default implementation of the getter for this property does not always return the most recently set value of the property. If the most recently set value of this property is nil then `Progress` uses the value of the `kind` property to determine how to use the values of other properties, as well as values in the user info dictionary, to return a computed string. If it fails to do that then it returns an empty string. The difference between this and `localizedDescription` is that this text is meant to be more specific about what work is being done at any particular moment.
    ///
    ///   For example, depending on the kind of progress, the completed and total unit counts, and other parameters, these kinds of strings may be generated:
    ///    3 of 10 files
    ///    123 KB of 789.1 MB
    ///    3.3 MB of 103.92 GB — 2 minutes remaining
    ///    1.61 GB of 3.22 GB (2 KB/sec) — 2 minutes remaining
    ///    1 minute remaining (1 KB/sec)
    ///  - note: In swift-corelibs-foundation, Key Value Observing is not yet available.
    open var localizedAdditionalDescription: String! {
        // Unimplemented
        return ""
    }
    
    /// Whether the work being done can be cancelled.
    ///
    /// By default `Progress` is cancellable.
    /// 
    /// This property is for communicating whether controls for cancelling should appear in a progress reporting user interface. `Progress` itself does not do anything with these properties other than help pass their values from progress reporters to progress observers. It is valid for the values of these properties to change in virtually any way during the lifetime of a `Progress`. Of course, if a `Progress` is cancellable you should actually implement cancellability by setting a cancellation handler or by making your code poll the result of invoking `isCancelled`.
    open var isCancellable: Bool

    /// Whether the work being done can be paused.
    ///
    /// By default `Progress` not pausable.
    ///
    /// This property is for communicating whether controls for pausing should appear in a progress reporting user interface. `Progress` itself does not do anything with these properties other than help pass their values from progress reporters to progress observers. It is valid for the values of these properties to change in virtually any way during the lifetime of a `Progress`. Of course, if a `Progress` is pausable you should actually implement pausibility by setting a pausing handler or by making your code poll the result of invoking `isPaused`.
    open var isPausable: Bool
    
    /// Whether the work being done has been cancelled.
    ///
    /// Instances of `Progress` that have parents are at least as cancelled as their parents.
    open var isCancelled: Bool

    /// Whether the work being done has been paused.
    ///
    /// Instances of `Progress` that have parents are at least as paused as their parents.
    open var isPaused: Bool
    
    /// A closure to be called when `cancel` is called.
    ///
    /// The closure will be called even when the function is called on an ancestor of the receiver. Your closure won't be called on any particular queue. If it must do work on a specific queue then it should schedule that work on that queue.
    open var cancellationHandler: (() -> Void)? {
        didSet {
            guard let handler = cancellationHandler else { return }
            // If we're already cancelled, then invoke it - asynchronously
            if isCancelled {
                DispatchQueue.global().async {
                    handler()
                }
            }
        }
    }
    
    /// A closure to be called when pause is called.
    ///
    /// The closure will be called even when the function is called on an ancestor of the receiver. Your closure won't be called on any particular queue. If it must do work on a specific queue then it should schedule that work on that queue.
    open var pausingHandler: (() -> Void)? {
        didSet {
            guard let handler = pausingHandler else { return }
            // If we're already paused, then invoke it - asynchronously
            if isPaused {
                DispatchQueue.global().async {
                    handler()
                }
            }
        }
    }

    
    /// A closure to be called when resume is called.
    ///
    /// The closure will be called even when the function is called on an ancestor of the receiver. Your closure won't be called on any particular queue. If it must do work on a specific queue then it should schedule that work on that queue.
    open var resumingHandler: (() -> Void)?
    
    /// Returns `true` if the progress is indeterminate.
    ///
    /// This returns `true` when the value of the `totalUnitCount` or `completedUnitCount` property is less than zero. Zero values for both of those properties indicates that there turned out to not be any work to do after all; `isIndeterminate` returns `false` and `fractionCompleted` returns `1.0` in that case.
    open var isIndeterminate: Bool {
        return _selfFraction.isIndeterminate
    }
    
    /// Returns `true` if the progress is finished.
    ///
    /// Checking the result of this function is preferred to comparing `fractionCompleted`, as rounding errors can cause that value to appear less than `1.0` in some circumstances.
    /// - Experiment: This is a draft API currently under consideration for official import into Foundation
    open var isFinished: Bool {
        return _selfFraction.isFinished
    }
    
    /// The fraction of the overall work completed by this progress object, including work done by any children it may have.
    public var fractionCompleted: Double {
        // We have to special case one thing to maintain consistency; if _selfFraction.total == 0 then we do not add any children
        guard _selfFraction.total > 0 else { return _selfFraction.fractionCompleted }
        return (_selfFraction + _childFraction).fractionCompleted
    }
    
    /// Calls the closure registered with the `cancellationHandler` property, if there is one, and set the `isCancelled` property to `true`.
    ///
    /// Do this for this `Progress` and any descendants of this `Progress`.
    open func cancel() {
        isCancelled = true
        
        if let handler = cancellationHandler {
            DispatchQueue.global().async {
                handler()
            }
        }
        
        for child in _children {
            child.cancel()
        }
    }
    
    /// Calls the closure registered with the `pausingHandler` property, if there is one, and set the `isPaused` property to `true`.
    ///
    /// Do this for this `Progress` and any descendants of this `Progress`.
    open func pause() {
        isPaused = true
        
        if let handler = pausingHandler {
            DispatchQueue.global().async {
                handler()
            }
        }
        
        for child in _children {
            child.pause()
        }
    }
    
    /// Calls the closure registered with the `resumingHandler` property, if there is one, and set the `isPaused` property to `false`.
    ///
    /// Do this for this `Progress` and any descendants of this `Progress`.
    open func resume() {
        isPaused = false
        
        if let handler = resumingHandler {
            DispatchQueue.global().async {
                handler()
            }
        }
        
        for child in _children {
            child.resume()
        }
    }
    
    /// Set a value in the dictionary returned by `userInfo`, with appropriate KVO notification for properties whose values can depend on values in the user info dictionary, like `localizedDescription`. If a nil value is passed then the dictionary entry is removed.
    /// - note: In swift-corelibs-foundation, Key Value Observing is not yet available.
    open func setUserInfoObject(_ objectOrNil: Any?, forKey key: ProgressUserInfoKey) {
        _userInfo[key] = objectOrNil
    }
    
    /// A collection of arbitrary values associated with this `Progress`. 
    ///
    /// Returns a KVO-compliant dictionary that changes as `setUserInfoObject(forKey:)` is sent to this `Progress`. The dictionary will send all of its KVO notifications on the thread which updates the property. The result will never be nil, but may be an empty dictionary.
    ///
    /// Some entries have meanings that are recognized by the `Progress` class itself. See also `ProgressUserInfoKey`.
    /// - note: In swift-corelibs-foundation, Key Value Observing is not yet available.
    open var userInfo: [ProgressUserInfoKey : Any] {
        return _userInfo
    }

    /// Optionally specifies more information about what kind of progress is being reported.
    ///
    /// If the value of the `localizedDescription` property has not been set, then the default implementation of `localizedDescription` uses the progress kind to determine how to use the values of other properties, as well as values in the user info dictionary, to create a string that is presentable to the user.
    open var kind: ProgressKind?
    
    public struct FileOperationKind : RawRepresentable, Equatable, Hashable {
        public let rawValue: String
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public init(rawValue: String) { self.rawValue = rawValue }
        public var hashValue: Int { return self.rawValue.hashValue }
        public static func ==(_ lhs: FileOperationKind, _ rhs: FileOperationKind) -> Bool { return lhs.rawValue == rhs.rawValue }
        
        /// Use for indicating the progress represents a download.
        public static let downloading = FileOperationKind(rawValue: "NSProgressFileOperationKindDownloading")

        /// Use for indicating the progress represents decompressing after downloading.
        public static let decompressingAfterDownloading = FileOperationKind(rawValue: "NSProgressFileOperationKindDecompressingAfterDownloading")
        
        /// Use for indicating the progress represents receiving a file in some way.
        public static let receiving = FileOperationKind(rawValue: "NSProgressFileOperationKindReceiving")
        
        /// Use for indicating the progress represents copying a file.
        public static let copying = FileOperationKind(rawValue: "NSProgressFileOperationKindCopying")
    }
    
    // MARK: -
    // MARK: Implementation of unit counts
    
    private var _overallFraction : _ProgressFraction {
        return _selfFraction + _childFraction
    }
    
    private func _addCompletedUnitCount(_ unitCount : Int64) {
        let old = _overallFraction
        _selfFraction.completed += unitCount
        let new = _overallFraction
        _updateFractionCompleted(from: old, to: new)
    }

    private func _updateFractionCompleted(from: _ProgressFraction, to: _ProgressFraction) {
        if from != to {
            _parent?._updateChild(self, from: from, to: to, portion: _portionOfParent)
        }
    }
    
    /// A child progress has been updated, which changes our own fraction completed.
    private func _updateChild(_ child: Progress, from previous: _ProgressFraction, to next: _ProgressFraction, portion: Int64) {
        let previousOverallFraction = _overallFraction
        
        let multiple = _ProgressFraction(completed: portion, total: _selfFraction.total)
        let oldFractionOfParent = previous * multiple
        
        // Subtract the previous fraction (multiplied by portion), add new fraction (multiplied by portion). If either is indeterminate, treat as zero.
        if !previous.isIndeterminate {
            _childFraction = _childFraction - oldFractionOfParent
        }
        
        if !next.isIndeterminate {
            _childFraction = _childFraction + (next * multiple)
        }
        
        if next.isFinished {
            _children.remove(child)
            
            if portion != 0 {
                // Update our self completed units
                _selfFraction.completed += portion
                
                // Subtract the (child's fraction completed * multiple) from our child fraction
                _childFraction = _childFraction - (multiple * next)
            }
        }
        
        _updateFractionCompleted(from: previousOverallFraction, to: _overallFraction)
    }
}

/// If your class supports reporting progress, then you can adopt the ProgressReporting protocol. 
///
/// Objects that adopt this protocol should typically be "one-shot" -- that is, the progress is setup at initialization of the object and is updated when work is done. The value of the property should not be set to another progress object. Instead, the user of the `ProgressReporting` class should create a new instance to represent a new set of work.
public protocol ProgressReporting : NSObjectProtocol {
    var progress: Progress { get }
}

public struct ProgressKind : RawRepresentable, Equatable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(rawValue: String) { self.rawValue = rawValue }
    public var hashValue: Int { return self.rawValue.hashValue }
    public static func ==(_ lhs: ProgressKind, _ rhs: ProgressKind) -> Bool { return lhs.rawValue == rhs.rawValue }
    
    /// Indicates that the progress being performed is related to files.
    ///
    /// Progress of this kind is assumed to use bytes as the unit of work being done and the default implementation of `localizedDescription` takes advantage of that to return more specific text than it could otherwise.
    public static let file = ProgressKind(rawValue: "NSProgressKindFile")
}

public struct ProgressUserInfoKey : RawRepresentable, Equatable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(rawValue: String) { self.rawValue = rawValue }
    public var hashValue: Int { return self.rawValue.hashValue }
    public static func ==(_ lhs: ProgressUserInfoKey, _ rhs: ProgressUserInfoKey) -> Bool { return lhs.rawValue == rhs.rawValue }
    
    /// How much time is probably left in the operation, as an NSNumber containing a number of seconds.
    ///
    /// If this value is present, then `Progress` can present a more detailed `localizedAdditionalDescription`.
    /// Value is an `NSNumber`.
    public static let estimatedTimeRemainingKey = ProgressUserInfoKey(rawValue: "NSProgressEstimatedTimeRemainingKey")
    
    /// How fast data is being processed, as an NSNumber containing bytes per second.
    ///
    /// If this value is present, then `Progress` can present a more detailed `localizedAdditionalDescription`.
    /// Value is an `NSNumber`.
    public static let throughputKey = ProgressUserInfoKey(rawValue: "NSProgressThroughputKey")
    
    /// A description of what "kind" of progress is being made on a file.
    ///
    /// If this value is present, then `Progress` can present a more detailed `localizedAdditionalDescription`.
    /// Value is a `Progress.FileOperationKind`.
    public static let fileOperationKindKey = ProgressUserInfoKey(rawValue: "NSProgressFileOperationKindKey")
    
    /// A URL for the item on which progress is being made.
    ///
    /// If this value is present, then `Progress` can present a more detailed `localizedAdditionalDescription`.
    /// Value is a `URL`.
    public static let fileURLKey = ProgressUserInfoKey(rawValue: "NSProgressFileURLKey")
    
    /// The total number of files.
    ///
    /// If this value is present, then `Progress` can present a more detailed `localizedAdditionalDescription`.
    /// Value is an `NSNumber`.
    public static let fileTotalCountKey = ProgressUserInfoKey(rawValue: "NSProgressFileTotalCountKey")

    /// The completed number of files.
    ///
    /// If this value is present, then `Progress` can present a more detailed `localizedAdditionalDescription`.
    /// Value is an `NSNumber`.
    public static let fileCompletedCountKey = ProgressUserInfoKey(rawValue: "NSProgressFileCompletedCountKey")
}

fileprivate class _ProgressTSD {
    /// The thread's default progress.
    fileprivate var currentProgress : Progress
    
    /// The instances of this thing that will become current the next time resignCurrent is called
    fileprivate var nextTSD : _ProgressTSD?
    
    /// Pending unit count
    var pendingUnitCount : Int64
    
    /// True if any children are implicitly attached
    var childAttached : Bool
    
    init(currentProgress: Progress, nextTSD: _ProgressTSD?, pendingUnitCount: Int64) {
        self.currentProgress = currentProgress
        self.pendingUnitCount = pendingUnitCount
        self.nextTSD = nextTSD
        childAttached = false
    }
}
