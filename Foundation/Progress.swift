// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/*
 Progress is used to report the amount of work done, and provides a way to allow the user to cancel that work.
 
 Since work is often split up into several parts, progress objects can form a tree where children represent part of the overall total work. Each parent may have as many children as required, but each child only has one parent. The top level progress object in this tree is typically the one that you would display to a user. The leaf objects are updated as work completes, and the updates propagate up the tree.
 
 The work that an Progress does is tracked via a "unit count." There are two unit count values: total and completed. In its leaf form, an Progress is created with a total unit count and its completed unit count is updated with -setCompletedUnitCount: until it matches the total unit count. The progress is then considered finished.
 
 When progress objects form nodes in trees, they are still created with a total unit count. Portions of the total are then handed out to children as a "pending unit count." The total amount handed out to children should add up to the parent's totalUnitCount. When those children become finished, the pending unit count assigned to that child is added to the parent's completedUnitCount. Therefore, when all children are finished, the parent's completedUnitCount is equal to its totalUnitCount and it becomes finished itself.
 
 Children Progress objects can be added implicitly or by invoking the -addChild:withPendingUnitCount: method on the parent. Implicitly added children are attached to a parent progress between a call to -becomeCurrentWithPendingUnitCount: and a call to -resignCurrent. The implicit child is created with the +progressWithTotalUnitCount: method or by passing the result of +currentProgress to the -initWithParent:userInfo: method. Both kinds of children can be attached to the same parent progress object. If you have an idea in advance that some portions of the work will take more or less time than the others, you can use different values of pending unit count for each child.
 
 If you are designing an interface of an object that reports progress, then the recommended approach is to vend an Progress property and adopt the ProgressReporting protocol. The progress should be created with the -discreteProgressWithTotalUnitCount: method. You can then either update the progress object directly or set it to have children of its own. Users of your object can compose your progress into their tree by using the -addChild:withPendingUnitCount: method.
 
 If you want to provide progress reporting for a single method, then the recommended approach is to implicitly attach to a current Progress by creating an Progress object at the very beginning of your method using +progressWithTotalUnitCount:. This progress object will consume the pending unit count, and then you can set up the progress object with children of its own.

 The localizedDescription and localizedAdditionalDescription properties are meant to be observed as well as set. So are the cancellable and pausable properties. totalUnitCount and completedUnitCount on the other hand are often not the best properties to observe when presenting progress to the user. For example, you should observe fractionCompleted instead of observing totalUnitCount and completedUnitCount and doing your own calculation. Progress' default implementation of fractionCompleted does fairly sophisticated things like taking child Progresses into account.
 */

/// The `Progress` class provides a self-contained mechanism for progress
/// reporting. It makes it easy for code that does work to report the progress
/// of that work, and for user interface code to observe that progress for
/// presentation to the user. Specifically, it can be used to show the user a
/// progress bar and explanatory text, both updated properly as progress is
/// made. It also allows work to be cancelled or paused by the user.
public class Progress : NSObject {
    
    //MARK: Creating Progress Objects

    /// Initializes a newly allocated `Progress` instance.
    ///
    /// This is the designated initializer for the `Progress` class.
    ///
    /// - Parameter parent: The parent `Progress` object, if any, to notify when
    ///   reporting progress or to consult when checking for cancellation.
    ///
    ///   The only valid values are `Progress.currentProgress()` or `nil`.
    /// - Parameter userInfo: The user information dictionary for the progress
    ///   object. May be `nil`.
    public init(parent: Progress?, userInfo: [NSObject : AnyObject]? = [:]) {
        self.userInfo = userInfo ?? [:]
    }
    
    /// Creates and returns a `Progress` instance with the specified
    /// `totalUnitCount` that is not part of any existing progress tree. The
    /// instance is initialized using `init(parent:userInfo:)` with the parent
    /// set to `nil`.
    ///
    /// Use this method to create the top level progress object returned by your
    /// own custom classes. The user of the returned progress object can add it
    /// to a progress tree using `addChild(_:withPendingUnitCount:)`.
    ///
    /// You are responsible for updating the progress count of the created
    /// progress object. You can invoke this method on one thread and then
    /// message the returned NSProgress on another thread. For example, you can
    /// capture the created progress instance in a block that you pass to
    /// `DispatchQueue.async()`. In that block you can invoke methods like
    /// `becomeCurrent(withPendingUnitCount:)` or `resignCurrent()`, and set the
    /// `completedUnitCount` or `isCancelled` properties as work is carried out.
    ///
    /// - Parameter totalUnitCount: The total number of units of work to be
    ///   carried out.
    public class func discreteProgress(totalUnitCount: Int64) -> Progress {
        NSUnimplemented()
    }
    
    /// Return an instance of `Progress` that has been initialized with
    /// `init(parent:userInfo:)`.
    ///
    /// The initializer is passed the current progress object, if there is one,
    /// and the value of the `totalUnitCount` property is set.
    ///
    /// In many cases you can simply precede code that does a substantial amount
    /// of work with an invocation of this method, then repeatedly set the
    /// `completedUnitCount` or `isCancelled` property in the loop that does the
    /// work.
    ///
    /// You can invoke this method on one thread and then message the returned
    /// `Progress` on another thread. For example, you can capture the created
    /// progress instance in a block that you pass to `DispatchQueue.async()`.
    /// In that block you can invoke methods like
    /// `becomeCurrent(withPendingUnitCount:)` or `resignCurrent()`, and set the
    /// `completedUnitCount` or `isCancelled` properties as work is carried out.
    ///
    /// - SeeAlso: `init(totalUnitCount:parent:pendingUnitCount:)`
    override convenience public init() {
        self.init(parent: nil, userInfo: nil)
    }
    
    /// Creates and returns a `Progress` instance, initialized using
    /// `init(parent:userInfo:)`.
    ///
    /// The initializer is passed the current progress object, if there is one,
    /// and the value of the `totalUnitCount` property is set.
    ///
    /// In many cases you can simply precede code that does a substantial amount
    /// of work with an invocation of this method, then repeatedly set the
    /// `completedUnitCount` or `isCancelled` property in the loop that does the
    /// work.
    ///
    /// You can invoke this method on one thread and then message the returned
    /// `Progress` on another thread. For example, you can capture the created
    /// progress instance in a block that you pass to `DispatchQueue.async()`.
    /// In that block you can invoke methods like
    /// `becomeCurrent(withPendingUnitCount:)` or `resignCurrent()`, and set the
    /// `completedUnitCount` or `isCancelled` properties as work is carried out.
    ///
    /// - Parameter totalUnitCount: The total number of units of work to be
    ///   carried out.
    ///
    /// - SeeAlso: `init(totalUnitCount:parent:pendingUnitCount:)`
    convenience public init(totalUnitCount: Int64) {
        self.init(parent: nil, userInfo: nil)
        self.totalUnitCount = totalUnitCount
    }
    
    /// Creates and returns a `Progress` instance attached to the specified
    /// parent with the `totalUnitCount` set to `pendingUnitCount`.
    ///
    /// Use this method to initialize a progress object with a specified parent
    /// and unit count.
    ///
    /// In many cases you can simply precede code that does a substantial amount
    /// of work with an invocation of this method, then repeatedly set the
    /// `completedUnitCount` or `isCancelled` property in the loop that does the
    /// work.
    ///
    /// You can invoke this method on one thread and then message the returned
    /// `Progress` on another thread. For example, you can capture the created
    /// progress instance in a block that you pass to `DispatchQueue.async()`.
    /// In that block you can invoke methods like
    /// `becomeCurrent(withPendingUnitCount:)` or `resignCurrent()`, and set the
    /// `completedUnitCount` or `isCancelled` properties as work is carried out.
    ///
    /// - Parameter totalUnitCount: The total number of units of work to be
    ///   carried out.
    /// - Parameter parent: The parent for the created `Progress` object.
    /// - Parameter pendingUnitCount: The unit count for the progress object.
    ///
    /// - SeeAlso: `init(totalUnitCount:)`
    public init(
        totalUnitCount: Int64, parent: Progress, pendingUnitCount: Int64
    ) {
        NSUnimplemented()
    }

    //MARK: Current Progress Object
    
    /// Returns the `Progress` instance, if any, associated with the current
    /// thread by a previous invocation of
    /// `becomeCurrent(withPendingUnitCount:)`.
    ///
    /// The purpose of this per-thread value is to allow code that does work to
    /// usefully report progress even when it is widely separated from the code
    /// that actually presents progress to the user, without requiring layers of
    /// intervening code to pass the instance of `Progress` through. Using the
    /// result of invoking this directly will often not be the right thing to
    /// do, because the invoking code will often not even know what units of
    /// work the current progress object deals in. Invoking
    /// `discreteProgress(totalUnitCount:)` to create a child `Progress` object
    /// and then using that to report progress makes more sense in that
    /// situation.
    ///
    /// - Returns: The `Progress` instance associated with the current thread,
    ///   if any.
    public class func current() -> Progress? {
        return Progress._currentProgress.get { NullableProgress() }.progress
    }
    
    /// Sets the receiver as the current progress object of the current thread
    /// and specifies the portion of work to be performed by the next child
    /// progress object of the receiver.
    ///
    /// Use this method to build a tree of progress objects.
    ///
    /// - Parameter pendingUnitCount: The number of units of work to be carried
    ///   out by the next progress object that is initialized by invoking the
    ///   `init(parent:userInfo:)` method in the current thread with the
    ///   receiver set as the parent. This number represents the portion of work
    ///   to be performed in relation to the total number of units of work to be
    ///   performed by the receiver (represented by the value of the receiver’s
    ///   `totalUnitCount` property). The units of work represented by this
    ///   parameter must be the same units of work that are used in the
    ///   receiver’s `totalUnitCount` property.
    public func becomeCurrent(withPendingUnitCount pendingUnitCount: Int64) {
        Progress.setCurrent(progress: self)
    }
    
    /// Add a process object as a child of a progress tree. The
    /// `pendingUnitCount` indicates the expected work for the progress unit.
    ///
    /// The child will be assigned a portion of the receivers total unit count
    /// based on `pendingUnitCount`.
    ///
    /// - Parameter child: The `Progress` instance to add to the progress tree.
    /// - Parameter pendingUnitCount: The number of units of work to be carried
    ///   out by the new child.
    public func addChild(
        _ child: Progress, withPendingUnitCount pendingUnitCount: Int64
    ) {
        NSUnimplemented()
    }
    
    /// Balance the most recent previous invocation of
    /// `becomeCurrent(withPendingUnitCount:)` on the same thread by restoring
    /// the current progress object to what it was before
    /// `becomeCurrent(withPendingUnitCount:)` was invoked.
    ///
    /// Use this method after building your tree of progress objects.
    public func resignCurrent() {
        Progress.setCurrent(progress: nil)
    }
    
    //MARK: Reporting Progress
    
    /// The total number of units of work tracked for the current progress.
    ///
    /// For an `Progress` with a `kind` of `ProgressKind.file`, the unit of this
    /// property is bytes while the `Progress.Key.fileTotalCountKey` and
    /// `Progress.Key.fileCompletedCountKey` keys in the `userInfo` dictionary
    /// are used for the overall count of files.
    ///
    /// For any other kind of `Progress`, the unit of measurement does not
    /// matter as long as it is consistent. The values may be reported to the
    /// user in the `localizedDescription` and `localizedAdditionalDescription`.
    ///
    /// - SeeAlso: `fractionCompleted`
    public var totalUnitCount: Int64 = 0
    
    /// The number of units of work for the current job that have already been
    /// completed.
    ///
    /// For an `Progress` with a `kind` of `ProgressKind.file`, the unit of this
    /// property is bytes while the `Progress.Key.fileTotalCountKey` and
    /// `Progress.Key.fileCompletedCountKey` keys in the `userInfo` dictionary
    /// are used for the overall count of files.
    ///
    /// For any other kind of `Progress`, the unit of measurement does not
    /// matter as long as it is consistent. The values may be reported to the
    /// user in the `localizedDescription` and `localizedAdditionalDescription`.
    ///
    /// - SeeAlso: `fractionCompleted`
    public var completedUnitCount: Int64 = 0
    
    /// A localized description of progress tracked by the receiver.
    ///
    /// If you don’t specify your own custom value for this property,
    /// `Progress` uses the value of the `kind` property to determine how to use
    /// the values of other properties, as well as values in the `userInfo`
    /// dictionary, to return an automatically-computed string. If it fails to
    /// do that, it returns an empty string.
    ///
    /// The `localizedDescription` represents a general description of the work
    /// tracked by the receiver. Depending on the kind of progress, the
    /// completed and total unit counts, and other parameters, example localized
    /// descriptions include:
    ///
    /// * Copying 10 files...
    /// * 30% completed
    /// * Copying "TextEdit"...
    ///
    /// - SeeAlso: `localizedAdditionalDescription`
    public var localizedDescription: String!
    
    /// A more specific localized description of progress tracked by the
    /// receiver.
    ///
    /// If you don’t specify your own custom value for this property, `Progress`
    /// uses the value of the `kind` property to determine how to use the values
    /// of other properties, as well as values in the `userInfo` dictionary, to
    /// return an automatically-computed string. If it fails to do that, it
    /// returns an empty string.
    ///
    /// The `localizedAdditionalDescription` is more specific than
    /// `localizedDescription` about the work the receiver is tracking at any
    /// particular moment. Depending on the kind of progress, the completed and
    /// total unit counts, and other parameters, example localized additional
    /// descriptions include:
    ///
    /// * 3 of 10 files
    /// * 123 KB of 789.1 MB
    /// * 3.3 MB of 103.92 GB – 2 minutes remaining
    /// * 1.61 GB of 3.22 GB (2 KB/sec) – 2 minutes remaining
    /// * 1 minute remaining (1 KB/sec)
    ///
    /// - SeeAlso: `localizedDescription`
    public var localizedAdditionalDescription: String!
    
    //MARK: Observing Progress
    
    /// The fraction of the overall work completed by this progress object,
    /// including work done by any children it may have.
    /// 
    /// If the receiver object does not have any children, fractionCompleted is
    /// generally the result of dividing `completedUnitCount` by
    /// `totalUnitCount`.
    ///
    /// If the receiver does have children, `fractionCompleted` will reflect
    /// progress made in child objects in addition to its own
    /// `completedUnitCount`. When children finish, the `completedUnitCount` of
    /// the parent is updated.
    public var fractionCompleted: Double {
        if isIndeterminate {
            return 0.0
        } else if totalUnitCount == 0 {
            return 1.0
        } else {
            return Double(completedUnitCount) / Double(totalUnitCount)
        }
    }
    
    //MARK: Controlling Progress
    
    /// Indicates whether the receiver is tracking work that can be cancelled.
    ///
    /// By default, `Progress` objects are cancellable.
    ///
    /// You typically use this property to communicate whether controls for
    /// canceling should appear in a progress reporting user interface.
    /// `Progress` itself does not do anything with this property other than
    /// help pass the value from progress reporters to progress observers.
    ///
    /// If a `Progress` is cancellable, you should implement the ability to
    /// cancel progress either by setting a block for the `cancellationHandler`
    /// property, or by polling the `isCancelled` property periodically while
    /// performing the relevant work.
    ///
    /// It is valid for the value of this property to change during the lifetime
    /// of a `Progress` object.
    ///
    /// - SeeAlso: `isCancelled`, `cancel()`, `cancellationHandler`
    public var isCancellable: Bool = true
    
    /// Indicates whether the receiver is tracking work that has been cancelled.
    ///
    /// If the receiver has a parent that has already been cancelled, the
    /// receiver will also report being cancelled.
    ///
    /// - SeeAlso: `isCancellable`, `cancel()`, `cancellationHandler`
    public var isCancelled: Bool {
        NSUnimplemented()
    }
    
    /// Cancel progress tracking.
    ///
    /// This method invokes the block set for `cancellationHandler`, if there is
    /// one, and ensures that any subsequent reads of the `isCancelled` property
    /// return true.
    ///
    /// If the receiver has any children, those children will also be cancelled.
    ///
    /// - SeeAlso: `isCancellable`, `isCancelled`, `cancellationHandler`
    public func cancel() {
        NSUnimplemented()
    }

    /// The block to invoke when progress is cancelled.
    ///
    /// If the receiver is a child of another progress object, the
    /// `cancellationHandler` block will be invoked when the parent is
    /// cancelled.
    ///
    /// - Important: You are responsible for cancelling any work associated with
    ///   the progress object.
    ///
    ///   The cancellation handler may be invoked on any queue. If you must do
    ///   work on a specific queue, you should dispatch to that queue from
    ///   within the cancellation handler block.
    ///
    /// - SeeAlso: `isCancellable`, `isCancelled`, `cancel()`
    public var cancellationHandler: (() -> Void)?
    
    /// Indicates whether the receiver is tracking work that can be paused.
    ///
    /// By default, `Progress` objects are not pausable.
    ///
    /// You typically use this property to communicate whether controls for
    /// pausing should appear in a progress reporting user interface. `Progress`
    /// itself does not do anything with this property other than help pass the
    /// value from progress reporters to progress observers.
    ///
    /// If an `Progress` is pausable, you should implement the ability to pause
    /// either by setting a block for the `pausingHandler` property, or by
    /// polling the `isPaused` property periodically while performing the
    /// relevant work.
    ///
    /// It is valid for the value of this property to change during the lifetime
    /// of a `Progress` object.
    ///
    /// - SeeAlso: `isPaused`, `pausingHandler`, `pause()`
    public var isPausable: Bool = false
    
    /// Indicates whether the receiver is tracking work that has been paused.
    ///
    /// If the receiver has a parent that has already been paused, the receiver
    /// will also report being paused.
    ///
    /// - SeeAlso: `isPausable`, `pausingHandler`, `pause()`
    public var isPaused: Bool { NSUnimplemented() }

    /// Pause progress tracking.
    ///
    /// This method invokes the block set for `pausingHandler`, if there is one,
    /// and ensures that any subsequent reads of the `isPaused` property return
    /// true.
    ///
    /// If the receiver has any children, those children will also be paused.
    ///
    /// - SeeAlso: `isPausable`, `isPaused`, `pausingHandler`
    public func pause() {
        NSUnimplemented()
    }
    
    /// The block to invoke when progress is paused.
    ///
    /// If the receiver is a child of another progress object, the
    /// `pausingHandler` block will be invoked when the parent is paused.
    ///
    /// - Important: You are responsible for pausing any work associated with
    ///   the progress object.
    ///
    ///   The pausing handler may be invoked on any queue. If you must do work
    ///   on a specific queue, you should dispatch to that queue from within the
    ///   pausing handler block.
    ///
    /// - SeeAlso: `isPausable`, `isPaused`, `pause()`
    public var pausingHandler: (() -> Void)?
    
    /// Resume progress tracking.
    ///
    /// This method invokes the block set for `resumingHandler`, if there is
    /// one, and ensures that any subsequent reads of the `isPaused` property
    /// return false.
    ///
    /// If the receiver has any children, those children will also be resumed.
    ///
    /// - SeeAlso: `resumeHandler`
    public func resume() {
        NSUnimplemented()
    }
    
    /// The block to invoke when progress is resumed.
    ///
    /// If the receiver is a child of another progress object, the
    /// `resumingHandler` block will be invoked when the parent is paused.
    ///
    /// - Important: You are responsible for resuming any work associated with
    ///   the progress object.
    ///
    ///   The resuming handler may be invoked on any queue. If you must do work
    ///   on a specific queue, you should dispatch to that queue from within the
    ///   resuming handler block.
    ///
    /// - SeeAlso: `resume()`
    public var resumingHandler: (() -> Void)?
    
    //MARK: Progress Information
    
    /// Indicates whether the tracked progress is indeterminate.
    ///
    /// Progress is indeterminate when the value of both `totalUnitCount` and
    /// `completedUnitCount` are zero.
    public var isIndeterminate: Bool {
        return completedUnitCount < 0 || totalUnitCount < 0 ||
            (completedUnitCount == 0 && totalUnitCount == 0)
    }
    
    /// The kind of progress being made.
    ///
    /// This property identifies the kind of progress being made, such as
    /// `file`. It can be `nil`.
    ///
    /// If the value of the `localizedDescription` property has not previously
    /// been set to a non-nil value, the default `localizedDescription` getter
    /// uses the progress kind to determine how to use the values of other
    /// properties, as well as values in the user info dictionary, to create a
    /// string that is presentable to the user.
    ///
    /// - SeeAlso: `localizedDescription`
    public var kind: ProgressKind?
    
    /// Set a value in the `userInfo` dictionary.
    ///
    /// Use this method to set a value in the `userInfo` dictionary, with
    /// appropriate modifications for properties whose values can depend on
    /// values in the user info dictionary, like `localizedDescription`.
    ///
    /// Supply a value of `nil` to remove an existing dictionary entry for a
    /// given key.
    ///
    /// - Parameter object: The object to set for the given key, or `nil` to
    ///   remove an existing entry in the dictionary.
    /// - Parameter key: The key to use to store the given object.
    ///
    /// - SeeAlso: `userInfo`
    public func setUserInfoObject(_ object: AnyObject?, forKey key: String) {
        userInfo[key.bridge()] = object
    }
    
    /// A dictionary of arbitrary values associated with the receiver.
    ///
    /// It changes in response to `setUserInfoObject(_:forKey:)`.
    ///
    /// Some entries have meanings that are recognized by the `Progress` class
    /// itself.
    ///
    /// - SeeAlso: `setUserInfoObject(_:forKey:)`
    public private(set) var userInfo: [NSObject : AnyObject]
    
    //MARK: General progress user info dictionary keys
    
    ///
    public struct Key : RawRepresentable, Comparable, Equatable, Hashable {
        public let rawValue: String
        
        public var hashValue: Int {
            return rawValue.hashValue
        }
        
        //MARK: Initializers
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        //MARK: Type Properties
        
        /// The corresponding value is a `Number` instance representing the time
        /// remaining, in seconds.
        public static let estimatedTimeRemainingKey = Key(rawValue:
            "NSProgressEstimatedTimeRemainingKey")
        
        /// The corresponding value must be a `Number` containing an integer to
        /// represent the number of completed files. This entry is optional; if
        /// you set a value for this key, the auto-generated
        ///`localizedAdditionalDescription` string will make use of it.
        public static let fileCompletedCountKey = Key(rawValue:
            "NSProgressFileCompletedCountKey")
        
        /// A value is required for this key in the user info dictionary when
        /// the progress kind is set to file. The corresponding value must be
        /// one of the entries of `FileOperationKind`.
        public static let fileOperationKindKey = Key(rawValue:
            "NSProgressFileOperationKindKey")
        
        /// The corresponding value must be a `Number` containing an integer to
        /// represent the total number of files affected. This entry is
        /// optional; if you set a value for this key, the auto-generated
        /// `localizedAdditionalDescription` string will make use of it.
        public static let fileTotalCountKey = Key(rawValue:
            "NSProgressFileTotalCountKey")
        
        public static let fileURLKey = Key(rawValue: "NSProgressFileURLKey")
        
        /// The corresponding value is an `Number` instance indicating the speed
        /// of data processing, in bytes per second.
        public static let throughputKey = Key(rawValue:
            "NSProgressThroughputKey")
    }
}

//MARK: Constants

public struct ProgressKind : RawRepresentable, Comparable, Equatable, Hashable {
    public let rawValue: String

    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    //MARK: Initializers
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    //MARK: Type Properties

    /// The value for the `kind` property that indicates that the progress is
    /// tracking a file operation. If you set this value for the progress
    /// `kind`, you must set a value in the user info dictionary for the
    /// `fileOperationKindKey`.
    ///
    /// `Progress` of this kind is assumed to use bytes as the unit of work
    /// being done, and the default implementation of `localizedDescription`
    /// takes advantage of that to return more specific text than it could
    /// otherwise. The `fileTotalCountKey` and `fileCompletedCountKey` keys in
    /// the `userInfo` dictionary are used for the overall count of files.
    public static let file = ProgressKind(rawValue: "ProgressKindFile")
}

/// Implement the `ProgressReporting` protocol to report progress for classes
/// that return only one progress object.
///
/// # Creating the Progress Object
///
/// Create the returned progress object using `ProgressReporting`. The resulting
/// object has no parent allowing the caller to add it to a progress tree using
/// `ProgressReporting`.
///
/// You can return a single progress object or a progress tree. If you are
/// creating a progress tree, add the children to the returned progress object.
///
/// # Updating the Progress Object
///
/// You are responsible for setting and updating the `ProgressReporting` and
/// `ProgressReporting` of any `Progress` object you create.
public protocol ProgressReporting : NSObjectProtocol {
    /// The progress object returned by the class.
    ///
    /// The progress object is usually setup at class initialization time and
    /// updated as work is completed. The progress property is set only once. If
    /// another progress object is needed the caller should create a new
    /// instance of the custom class to represent the work.
    ///
    /// - Important: The `progress` property is only set once.
    var progress: Progress { get }
}

public func == (lhs: ProgressKind, rhs: ProgressKind) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public func < (lhs: ProgressKind, rhs: ProgressKind) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

public func == (lhs: Progress.Key, rhs: Progress.Key) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public func < (lhs: Progress.Key, rhs: Progress.Key) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

internal extension Progress {
    static var _currentProgress = NSThreadSpecific<NullableProgress>()
    class func setCurrent(progress: Progress?) {
        Progress._currentProgress.get { NullableProgress() }.progress = progress
    }
}

internal class NullableProgress: NSObject {
    var progress: Progress?
}
