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

// This file is for internal use of FoundationNetworking

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import SwiftFoundation
#else
import Foundation
#endif

/// A class type which acts as a handle (pointer-to-pointer) to a Foundation reference type which has only a mutable class (e.g., NSURLComponents).
///
/// Note: This assumes that the result of calling copy() is mutable. The documentation says that classes which do not have a mutable/immutable distinction should just adopt NSCopying instead of NSMutableCopying.
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
