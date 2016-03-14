// Foundation/NSURLSession/TaskRegistry.swift - NSURLSession & libcurl
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// These are libcurl helpers for the NSURLSession API code.
/// - SeeAlso: https://curl.haxx.se/libcurl/c/
/// - SeeAlso: NSURLSession.swift
///
// -----------------------------------------------------------------------------

import CoreFoundation
import Dispatch


extension NSURLSession {
    /// This helper class keeps track of all tasks, and their behaviours.
    ///
    /// Each `NSURLSession` has a `TaskRegistry` for its running tasks. The
    /// *behaviour* defines what action is to be taken e.g. upon completion.
    /// The behaviour stores the completion handler for tasks that are
    /// completion handler based.
    ///
    /// - Note: This must **only** be accessed on the owning session's work queue.
    class TaskRegistry {
        /// Completion handler for `NSURLSessionDataTask`, and `NSURLSessionUploadTask`.
        typealias DataTaskCompletion = (NSData?, NSURLResponse?, NSError?) -> Void
        /// Completion handler for `NSURLSessionDownloadTask`.
        typealias DownloadTaskCompletion = (NSURL?, NSURLResponse?, NSError?) -> Void
        /// What to do upon events (such as completion) of a specific task.
        enum Behaviour {
            /// Call the `NSURLSession`’s delegate
            case callDelegate
            /// Default action for all events, except for completion.
            case dataCompletionHandler(DataTaskCompletion)
            /// Default action for all events, except for completion.
            case downloadCompletionHandler(DownloadTaskCompletion)
        }
        
        private var tasks: [Int: NSURLSessionTask] = [:]
        private var behaviours: [Int: Behaviour] = [:]
    }
}

extension NSURLSession.TaskRegistry {
    /// Add a task
    ///
    /// - Note: This must **only** be accessed on the owning session's work queue.
    func add(_ task: NSURLSessionTask, behaviour: Behaviour) {
        let identifier = task.taskIdentifier
        guard identifier != 0 else { fatalError("Invalid task identifier") }
        guard tasks.index(forKey: identifier) == nil else {
            if tasks[identifier] === task {
                fatalError("Trying to re-insert a task that's already in the registry.")
            } else {
                fatalError("Trying to insert a task, but a different task with the same identifier is already in the registry.")
            }
        }
        tasks[identifier] = task
        behaviours[identifier] = behaviour
    }
    /// Remove a task
    ///
    /// - Note: This must **only** be accessed on the owning session's work queue.
    func remove(_ task: NSURLSessionTask) {
        let identifier = task.taskIdentifier
        guard identifier != 0 else { fatalError("Invalid task identifier") }
        guard let tasksIdx = tasks.index(forKey: identifier) else {
            fatalError("Trying to remove task, but it's not in the registry.")
        }
        tasks.remove(at: tasksIdx)
        guard let behaviourIdx = behaviours.index(forKey: identifier) else {
            fatalError("Trying to remove task's behaviour, but it's not in the registry.")
        }
        behaviours.remove(at: behaviourIdx)
    }
}
extension NSURLSession.TaskRegistry {
    /// The behaviour that's registered for the given task.
    ///
    /// - Note: It is a programming error to pass a task that isn't registered.
    /// - Note: This must **only** be accessed on the owning session's work queue.
    func behaviour(for task: NSURLSessionTask) -> Behaviour {
        guard let b = behaviours[task.taskIdentifier] else {
            fatalError("Trying to access a behaviour for a task that in not in the registry.")
        }
        return b
    }
}
