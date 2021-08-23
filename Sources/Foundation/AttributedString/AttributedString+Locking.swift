//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if canImport(Darwin)
import Darwin

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
extension UnsafeMutablePointer where Pointee == os_unfair_lock_s {
    internal init() {
        let l = UnsafeMutablePointer.allocate(capacity: 1)
        l.initialize(to: os_unfair_lock())
        self = l
    }
    
    internal func cleanupLock() {
        deinitialize(count: 1)
        deallocate()
    }
    
    internal func lock() {
        os_unfair_lock_lock(self)
    }
    
    internal func tryLock() -> Bool {
        let result = os_unfair_lock_trylock(self)
        return result
    }
    
    internal func unlock() {
        os_unfair_lock_unlock(self)
    }
}

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
typealias Lock = os_unfair_lock_t

#else
internal typealias Lock = NSLock

extension NSLock {
    // Stub to match the API of os_unfair_lock_t
    func cleanupLock() { /* NOOP */ }
}
#endif
