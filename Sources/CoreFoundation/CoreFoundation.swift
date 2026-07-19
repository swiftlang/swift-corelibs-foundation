// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

@_exported import CoreFoundation

// The Clang importer synthesizes conformance to the compiler-known
// CoreFoundation._CFObject protocol for declarations it recognizes as Core
// Foundation reference types. Both the module and protocol names are required;
// the default witnesses below then satisfy Hashable for those imported types.
public protocol _CFObject: AnyObject, Hashable {}

extension _CFObject {
    public var hashValue: Int {
        Int(bitPattern: CFHash(self))
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        CFEqual(lhs, rhs)
    }
}
