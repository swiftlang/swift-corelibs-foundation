// Collections/Stack.swift - Implementation of stack data structure
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// This is a simple implementation of the stack data structure.
///
// -----------------------------------------------------------------------------

public class Stack<T>: ArrayLiteralConvertible {
    public typealias Element = T
    
    private var storage = [Element]()
    
    public init() {
    }
    
    /// Create an instance initialized with `elements`.
    public required init(arrayLiteral elements: Element...) {
        storage.appendContentsOf(elements)
    }
    
    /// Pushes a new element onto the stack.
    public func push(element: Element) {
        storage.append(element)
    }
    
    /// Removes and returns the value at the top of the stack,
    /// or `nil` if the stack is empty.
    ///
    /// Complexity: O(1)
    public func pop() -> Element? {
        if !self.isEmpty {
            return storage.removeLast()
        } else {
            return nil
        }
    }
    
    /// Returns `true` if the stack is empty.
    public var isEmpty: Bool {
        return storage.isEmpty
    }
    
    /// The number of elements in the stack.
    public var count: Int {
        return storage.count
    }
    
    /// Returns the value at the top of the stack without removing it,
    /// or `nil` if the stack is empty.
    ///
    /// Complexity: O(1)
    public func peek() -> Element? {
        return storage.last
    }
}
