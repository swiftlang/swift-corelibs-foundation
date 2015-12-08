// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/*
 NSProgress is used to report the amount of work done, and provides a way to allow the user to cancel that work.
 
 Since work is often split up into several parts, progress objects can form a tree where children represent part of the overall total work. Each parent may have as many children as required, but each child only has one parent. The top level progress object in this tree is typically the one that you would display to a user. The leaf objects are updated as work completes, and the updates propagate up the tree.
 
 The work that an NSProgress does is tracked via a "unit count." There are two unit count values: total and completed. In its leaf form, an NSProgress is created with a total unit count and its completed unit count is updated with -setCompletedUnitCount: until it matches the total unit count. The progress is then considered finished.
 
 When progress objects form nodes in trees, they are still created with a total unit count. Portions of the total are then handed out to children as a "pending unit count." The total amount handed out to children should add up to the parent's totalUnitCount. When those children become finished, the pending unit count assigned to that child is added to the parent's completedUnitCount. Therefore, when all children are finished, the parent's completedUnitCount is equal to its totalUnitCount and it becomes finished itself.
 
 Children NSProgress objects can be added implicitly or by invoking the -addChild:withPendingUnitCount: method on the parent. Implicitly added children are attached to a parent progress between a call to -becomeCurrentWithPendingUnitCount: and a call to -resignCurrent. The implicit child is created with the +progressWithTotalUnitCount: method or by passing the result of +currentProgress to the -initWithParent:userInfo: method. Both kinds of children can be attached to the same parent progress object. If you have an idea in advance that some portions of the work will take more or less time than the others, you can use different values of pending unit count for each child.
 
 If you are designing an interface of an object that reports progress, then the recommended approach is to vend an NSProgress property and adopt the NSProgressReporting protocol. The progress should be created with the -discreteProgressWithTotalUnitCount: method. You can then either update the progress object directly or set it to have children of its own. Users of your object can compose your progress into their tree by using the -addChild:withPendingUnitCount: method.
 
 If you want to provide progress reporting for a single method, then the recommended approach is to implicitly attach to a current NSProgress by creating an NSProgress object at the very beginning of your method using +progressWithTotalUnitCount:. This progress object will consume the pending unit count, and then you can set up the progress object with children of its own.

 The localizedDescription and localizedAdditionalDescription properties are meant to be observed as well as set. So are the cancellable and pausable properties. totalUnitCount and completedUnitCount on the other hand are often not the best properties to observe when presenting progress to the user. For example, you should observe fractionCompleted instead of observing totalUnitCount and completedUnitCount and doing your own calculation. NSProgress' default implementation of fractionCompleted does fairly sophisticated things like taking child NSProgresses into account.
 */
public class NSProgress : NSObject {
    
    /* The instance of NSProgress associated with the current thread by a previous invocation of -becomeCurrentWithPendingUnitCount:, if any. The purpose of this per-thread value is to allow code that does work to usefully report progress even when it is widely separated from the code that actually presents progress to the user, without requiring layers of intervening code to pass the instance of NSProgress through. Using the result of invoking this directly will often not be the right thing to do, because the invoking code will often not even know what units of work the current progress object deals in. Invoking +progressWithTotalUnitCount: to create a child NSProgress object and then using that to report progress makes more sense in that situation.
    */
    public class func currentProgress() -> NSProgress? { NSUnimplemented() }
    
    /* Return an instance of NSProgress that has been initialized with -initWithParent:userInfo:. The initializer is passed the current progress object, if there is one, and the value of the totalUnitCount property is set. In many cases you can simply precede code that does a substantial amount of work with an invocation of this method, with repeated invocations of -setCompletedUnitCount: and -isCancelled in the loop that does the work.
    
    You can invoke this method on one thread and then message the returned NSProgress on another thread. For example, you can let the result of invoking this method get captured by a block passed to dispatch_async(). In that block you can invoke methods like -becomeCurrentWithPendingUnitCount: and -resignCurrent, or -setCompletedUnitCount: and -isCancelled.
    */
    public init(totalUnitCount unitCount: Int64) { NSUnimplemented() }
    
    /* Return an instance of NSProgress that has been initialized with -initWithParent:userInfo:. The initializer is passed nil for the parent, resulting in a progress object that is not part of an existing progress tree. The value of the totalUnitCount property is also set.
     */
    public class func discreteProgressWithTotalUnitCount(unitCount: Int64) -> NSProgress { NSUnimplemented() }
    
    /* Return an instance of NSProgress that has been attached to a parent progress with the given pending unit count.
     */
    public init(totalUnitCount unitCount: Int64, parent: NSProgress, pendingUnitCount portionOfParentTotalUnitCount: Int64) { NSUnimplemented() }
    
    /* The designated initializer. If a parent NSProgress object is passed then progress reporting and cancellation checking done by the receiver will notify or consult the parent. The only valid arguments to the first argument of this method are nil (indicating no parent) or [NSProgress currentProgress]. Any other value will throw an exception.
    */
    public init(parent parentProgressOrNil: NSProgress?, userInfo userInfoOrNil: [NSObject : AnyObject]?) { NSUnimplemented() }
    
    /* Make the receiver the current thread's current progress object, returned by +currentProgress. At the same time, record how large a portion of the work represented by the receiver will be represented by the next progress object initialized by invoking -initWithParent:userInfo: in the current thread with the receiver as the parent. This will be used when that child is sent -setCompletedUnitCount: and the receiver is notified of that.
     
       With this mechanism, code that doesn't know anything about its callers can report progress accurately by using +progressWithTotalUnitCount: and -setCompletedUnitCount:. The calling code will account for the fact that the work done is only a portion of the work to be done as part of a larger operation. The unit of work in a call to -becomeCurrentWithPendingUnitCount: has to be the same unit of work as that used for the value of the totalUnitCount property, but the unit of work used by the child can be a completely different one, and often will be. You must always balance invocations of this method with invocations of -resignCurrent.
    */
    public func becomeCurrentWithPendingUnitCount(unitCount: Int64) { NSUnimplemented() }
    
    /* Balance the most recent previous invocation of -becomeCurrentWithPendingUnitCount: on the same thread by restoring the current progress object to what it was before -becomeCurrentWithPendingUnitCount: was invoked.
    */
    public func resignCurrent() { NSUnimplemented() }
    
    /* Directly add a child progress to the receiver, assigning it a portion of the receiver's total unit count.
     */
    public func addChild(child: NSProgress, withPendingUnitCount inUnitCount: Int64) { NSUnimplemented() }
    
    /* The size of the job whose progress is being reported, and how much of it has been completed so far, respectively. For an NSProgress with a kind of NSProgressKindFile, the unit of these properties is bytes while the NSProgressFileTotalCountKey and NSProgressFileCompletedCountKey keys in the userInfo dictionary are used for the overall count of files. For any other kind of NSProgress, the unit of measurement you use does not matter as long as you are consistent. The values may be reported to the user in the localizedDescription and localizedAdditionalDescription.
     
       If the receiver NSProgress object is a "leaf progress" (no children), then the fractionCompleted is generally completedUnitCount / totalUnitCount. If the receiver NSProgress has children, the fractionCompleted will reflect progress made in child objects in addition to its own completedUnitCount. As children finish, the completedUnitCount of the parent will be updated.
    */
    public var totalUnitCount: Int64
    public var completedUnitCount: Int64
    
    /* A description of what progress is being made, fit to present to the user. NSProgress is by default KVO-compliant for this property, with the notifications always being sent on thread which updates the property. The default implementation of the getter for this property does not always return the most recently set value of the property. If the most recently set value of this property is nil then NSProgress uses the value of the kind property to determine how to use the values of other properties, as well as values in the user info dictionary, to return a computed string. If it fails to do that then it returns an empty string.
      
      For example, depending on the kind of progress, the completed and total unit counts, and other parameters, these kinds of strings may be generated:
        Copying 10 files…
        30% completed
        Copying “TextEdit”…
    */
    public var localizedDescription: String!
    
    /* A more specific description of what progress is being made, fit to present to the user. NSProgress is by default KVO-compliant for this property, with the notifications always being sent on thread which updates the property. The default implementation of the getter for this property does not always return the most recently set value of the property. If the most recently set value of this property is nil then NSProgress uses the value of the kind property to determine how to use the values of other properties, as well as values in the user info dictionary, to return a computed string. If it fails to do that then it returns an empty string. The difference between this and localizedDescription is that this text is meant to be more specific about what work is being done at any particular moment.
    
       For example, depending on the kind of progress, the completed and total unit counts, and other parameters, these kinds of strings may be generated:
        3 of 10 files
        123 KB of 789.1 MB
        3.3 MB of 103.92 GB — 2 minutes remaining
        1.61 GB of 3.22 GB (2 KB/sec) — 2 minutes remaining
        1 minute remaining (1 KB/sec)
    
    */
    public var localizedAdditionalDescription: String!
    
    /* Whether the work being done can be cancelled or paused, respectively. By default NSProgresses are cancellable but not pausable. NSProgress is by default KVO-compliant for these properties, with the notifications always being sent on the thread which updates the property. These properties are for communicating whether controls for cancelling and pausing should appear in a progress reporting user interface. NSProgress itself does not do anything with these properties other than help pass their values from progress reporters to progress observers. It is valid for the values of these properties to change in virtually any way during the lifetime of an NSProgress. Of course, if an NSProgress is cancellable you should actually implement cancellability by setting a cancellation handler or by making your code poll the result of invoking -isCancelled. Likewise for pausability.
    */
    public var cancellable: Bool
    public var pausable: Bool
    
    /* Whether the work being done has been cancelled or paused, respectively. NSProgress is by default KVO-compliant for these properties, with the notifications always being sent on the thread which updates the property. Instances of NSProgress that have parents are at least as cancelled or paused as their parents.
    */
    public var cancelled: Bool { NSUnimplemented() }
    public var paused: Bool { NSUnimplemented() }
    
    /* A block to be invoked when cancel is invoked. The block will be invoked even when the method is invoked on an ancestor of the receiver, or an instance of NSProgress in another process that resulted from publishing the receiver or an ancestor of the receiver. Your block won't be invoked on any particular queue. If it must do work on a specific queue then it should schedule that work on that queue.
    */
    public var cancellationHandler: (() -> Void)?
    
    /* A block to be invoked when pause is invoked. The block will be invoked even when the method is invoked on an ancestor of the receiver, or an instance of NSProgress in another process that resulted from publishing the receiver or an ancestor of the receiver. Your block won't be invoked on any particular queue. If it must do work on a specific queue then it should schedule that work on that queue.
     */
    public var pausingHandler: (() -> Void)?
    
    /* A block to be invoked when resume is invoked. The block will be invoked even when the method is invoked on an ancestor of the receiver, or an instance of NSProgress in another process that resulted from publishing the receiver or an ancestor of the receiver. Your block won't be invoked on any particular queue. If it must do work on a specific queue then it should schedule that work on that queue.
     */
    public var resumingHandler: (() -> Void)?
    
    /* Set a value in the dictionary returned by invocations of -userInfo, with appropriate KVO notification for properties whose values can depend on values in the user info dictionary, like localizedDescription. If a nil value is passed then the dictionary entry is removed.
    */
    public func setUserInfoObject(objectOrNil: AnyObject?, forKey key: String) { NSUnimplemented() }
    
    /* Whether the progress being made is indeterminate. -isIndeterminate returns YES when the value of the totalUnitCount or completedUnitCount property is less than zero. Zero values for both of those properties indicates that there turned out to not be any work to do after all; -isIndeterminate returns NO and -fractionCompleted returns 1.0 in that case. NSProgress is by default KVO-compliant for these properties, with the notifications always being sent on the thread which updates the property.
    */
    public var indeterminate: Bool { NSUnimplemented() }
    
    /* The fraction of the overall work completed by this progress object, including work done by any children it may have.
    */
    public var fractionCompleted: Double { NSUnimplemented() }
    
    /* Invoke the block registered with the cancellationHandler property, if there is one, and set the cancelled property to YES. Do this for the receiver, any descendants of the receiver, the instance of NSProgress that was published in another process to make the receiver if that's the case, and any descendants of such a published instance of NSProgress.
    */
    public func cancel() { NSUnimplemented() }
    
    /* Invoke the block registered with the pausingHandler property, if there is one, and set the paused property to YES. Do this for the receiver, any descendants of the receiver, the instance of NSProgress that was published in another process to make the receiver if that's the case, and any descendants of such a published instance of NSProgress.
    */
    public func pause() { NSUnimplemented() }
    
    /* Invoke the block registered with the resumingHandler property, if there is one, and set the paused property to NO. Do this for the receiver, any descendants of the receiver, the instance of NSProgress that was published in another process to make the receiver if that's the case, and any descendants of such a published instance of NSProgress.
    */
    public func resume() { NSUnimplemented() }
    
    /* Arbitrary values associated with the receiver. Returns a KVO-compliant dictionary that changes as -setUserInfoObject:forKey: is sent to the receiver. The dictionary will send all of its KVO notifications on the thread which updates the property. The result will never be nil, but may be an empty dictionary. Some entries have meanings that are recognized by the NSProgress class itself. See the NSProgress...Key string constants listed below.
    */
    public var userInfo: [NSObject : AnyObject] { NSUnimplemented() }
    
    /* Either a string identifying what kind of progress is being made, like NSProgressKindFile, or nil. If the value of the localizedDescription property has not been set to a non-nil value then the default implementation of -localizedDescription uses the progress kind to determine how to use the values of other properties, as well as values in the user info dictionary, to create a string that is presentable to the user. This is most useful when -localizedDescription is actually being invoked in another process, whose localization language may be different, as a result of using the publish and subscribe mechanism described here.
    */
    public var kind: String?
    
}

/* If your class supports reporting progress, then you can adopt the NSProgressReporting protocol. Objects that adopt this protocol should typically be "one-shot" -- that is, the progress is setup at initialization of the object and is updated when work is done. The value of the property should not be set to another progress object. Instead, the user of the NSProgressReporting class should create a new instance to represent a new set of work.
 */
public protocol NSProgressReporting : NSObjectProtocol {
    var progress: NSProgress { get }
}

/* How much time is probably left in the operation, as an NSNumber containing a number of seconds.
*/
public let NSProgressEstimatedTimeRemainingKey: String = "NSProgressEstimatedTimeRemainingKey"

/* How fast data is being processed, as an NSNumber containing bytes per second.
*/
public let NSProgressThroughputKey: String = "NSProgressThroughputKey"

/* The value for the kind property that indicates that the work being done is one of the kind of file operations listed below. NSProgress of this kind is assumed to use bytes as the unit of work being done and the default implementation of -localizedDescription takes advantage of that to return more specific text than it could otherwise. The NSProgressFileTotalCountKey and NSProgressFileCompletedCountKey keys in the userInfo dictionary are used for the overall count of files.
*/
public let NSProgressKindFile: String = "NSProgressKindFile"

/* A user info dictionary key, for an entry that is required when the value for the kind property is NSProgressKindFile. The value must be one of the strings listed in the next section. The default implementations of of -localizedDescription and -localizedItemDescription use this value to determine the text that they return.
*/
public let NSProgressFileOperationKindKey: String = "NSProgressKindFile"

/* Possible values for NSProgressFileOperationKindKey entries.
*/
public let NSProgressFileOperationKindDownloading: String = "NSProgressFileOperationKindDownloading"
public let NSProgressFileOperationKindDecompressingAfterDownloading: String = "NSProgressFileOperationKindDecompressingAfterDownloading"
public let NSProgressFileOperationKindReceiving: String = "NSProgressFileOperationKindReceiving"
public let NSProgressFileOperationKindCopying: String = "NSProgressFileOperationKindCopying"

/* A user info dictionary key. The value must be an NSURL identifying the item on which progress is being made. This is required for any NSProgress that is published using -publish to be reported to subscribers registered with +addSubscriberForFileURL:withPublishingHandler:.
*/
public let NSProgressFileURLKey: String = "NSProgressFileURLKey"

/* User info dictionary keys. The values must be NSNumbers containing integers. These entries are optional but if they are both present then the default implementation of -localizedAdditionalDescription uses them to determine the text that it returns.
*/
public let NSProgressFileTotalCountKey: String = "NSProgressFileTotalCountKey"
public let NSProgressFileCompletedCountKey: String = "NSProgressFileCompletedCountKey"



