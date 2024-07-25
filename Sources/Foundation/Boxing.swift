//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// This file is for internal use of Foundation

/// A class type which acts as a handle (pointer-to-pointer) to a Foundation reference type which has only a mutable class (e.g., NSURLComponents).
///
/// Note: This assumes that the result of calling copy() is mutable. The documentation says that classes which do not have a mutable/immutable distinction should just adopt NSCopying instead of NSMutableCopying.
///
/// `Sendable` Note: A `_MutableHandle` can be considered safely `Sendable` if and only if the following conditions of the `_MutableBoxing`-conforming type are met:
///         - All calls within `mapWithoutMutation` calls are read-only, and are safe to execute concurrently across multiple actors
///         - The passed pointer to the `MutableType` does not escape any `mapWithoutMutation`/`_applyMutation` blocks
///         - Any and all mutations of the held mutable type are only performed in an `_applyMutation` block
///    If both of those conditions are met and verified, the Copy on Write protections will make the `_MutableHandle` safely `Sendable` (the `_MutableBoxing`-conforming type can be marked `Sendable` if these
///    conditions are met and the type is otherwise `Sendable`)
internal final class _MutableHandle<MutableType : NSObject> : @unchecked Sendable where MutableType : NSCopying {
    @usableFromInline internal var _pointer : MutableType
    
    init(reference : MutableType) {
        _pointer = reference.copy() as! MutableType
    }
    
    init(adoptingReference reference: MutableType) {
        _pointer = reference
    }
    
    /// Apply a closure to the reference type.
    func map<ReturnType>(_ whatToDo : (MutableType) throws -> ReturnType) rethrows -> ReturnType {
        return try whatToDo(_pointer)
    }
    
    func _copiedReference() -> MutableType {
        return _pointer.copy() as! MutableType
    }
    
    func _uncopiedReference() -> MutableType {
        return _pointer
    }
}
