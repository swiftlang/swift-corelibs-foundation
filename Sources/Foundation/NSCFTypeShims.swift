//
//  NSCFTypeShims.swift
//  SwiftFoundation
//
//  Created by Aura Lily Vulcano on 8/27/20.
//  Copyright © 2020 Swift. All rights reserved.
//

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

import Darwin
typealias _NSCFLock = pthread_mutex_t
func _NSCFLockInit() -> _NSCFLock {
    pthread_mutex_t(__sig: Int(_PTHREAD_ERRORCHECK_MUTEX_SIG_init), __opaque: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
}

#elseif os(Windows)

typealias _NSCFLock = Int32
func _NSCFLockInit() -> _NSCFLock { 0 }

#elseif os(Linux) || os(FreeBSD)

typealias _NSCFLock = Int32
func _NSCFLockInit() -> _NSCFLock { 0 }

#else

typealias _NSCFLock = Int
func _NSCFLockInit() -> _NSCFLock { 0 }

#endif
