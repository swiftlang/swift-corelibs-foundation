// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  ObjectWrapper.swift
//  Utility type for adapting implementors of a `class` protocol to `Hashable`
//

/// A `Hashable` representation of an object and its `ObjectIdentifier`. This is
/// useful because Swift classes aren't implicitly hashable based on identity.
internal struct ObjectWrapper<T>: Hashable {
    let object: T
    let objectIdentifier: ObjectIdentifier

    func hash(into hasher: inout Hasher) {
        hasher.combine(objectIdentifier)
    }
}

internal func ==<T>(lhs: ObjectWrapper<T>, rhs: ObjectWrapper<T>) -> Bool {
    return lhs.objectIdentifier == rhs.objectIdentifier
}
