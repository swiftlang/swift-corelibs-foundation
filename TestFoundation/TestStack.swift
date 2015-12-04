// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

class TestStack : XCTestCase {
    
    var allTests : [(String, () -> ())] {
        return [
            ("test_isEmpty", test_isEmpty),
            ("test_push", test_push),
            ("test_pop", test_pop),
            ("test_pop_whenEmpty", test_pop_whenEmpty),
            ("test_LIFO", test_LIFO),
            ("test_arrayLiteralConvertible", test_arrayLiteralConvertible)
        ]
    }
    
    func test_isEmpty() {
        let stack = Stack<Int>()
        XCTAssertTrue(stack.isEmpty)
        
        stack.push(1)
        XCTAssertFalse(stack.isEmpty)
    }
    
    func test_push() {
        let stack = Stack<Int>()
        XCTAssertEqual(stack.count, 0, "Stack should be empty")
        
        stack.push(1)
        XCTAssertEqual(stack.count, 1, "Stack should have 1 item")
    }
    
    func test_pop() {
        let stack = Stack<Int>()
        stack.push(2)
        stack.push(1)
        XCTAssertEqual(stack.count, 2, "Stack should have 2 items")
        
        let top = stack.pop()
        XCTAssertEqual(top!, 1, "Wrong value returned")
        XCTAssertEqual(stack.count, 1, "Stack should now have 1 item")
    }
    
    func test_pop_whenEmpty() {
        let stack = Stack<Int>()
        XCTAssertEqual(stack.count, 0, "Stack should be empty")
        XCTAssertNil(stack.pop())
    }
    
    func test_LIFO() {
        let stack = Stack<Int>()
        stack.push(1)
        stack.push(2)
        stack.push(3)
        XCTAssertEqual(stack.count, 3, "Stack should have 3 items")
        
        XCTAssertEqual(stack.pop()!, 3, "Wrong value returned")
        XCTAssertEqual(stack.pop()!, 2, "Wrong value returned")
        XCTAssertEqual(stack.pop()!, 1, "Wrong value returned")
    }
    
    func test_arrayLiteralConvertible() {
        let stack = Stack(arrayLiteral: "Hello", "World")
        XCTAssertEqual(stack.count, 2, "Stack should have 2 items")
        
        XCTAssertEqual(stack.pop()!, "World")
        XCTAssertEqual(stack.pop()!, "Hello")
    }
}
