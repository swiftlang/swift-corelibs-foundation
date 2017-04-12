// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


/// Decorates types which are backed by a Foundation reference type.
///
/// All `ReferenceConvertible` types are hashable, equatable, and provide description functions.
public protocol ReferenceConvertible : CustomStringConvertible, CustomDebugStringConvertible, Hashable {
    associatedtype ReferenceType : NSObject, NSCopying
}

