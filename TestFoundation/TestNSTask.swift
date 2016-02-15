// This source file is part of the Swift.org open source project
//
// Copyright (c) 2015 - 2016 Apple Inc. and the Swift project authors
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
import CoreFoundation

class TestNSTask : XCTestCase {
    static var allTests: [(String, TestNSTask -> () throws -> Void)] {
        return [("test_exit0" , test_exit0),
                ("test_exit1" , test_exit1),
                ("test_exit100" , test_exit100),
                ("test_sleep2", test_sleep2),
                ("test_sleep2_exit1", test_sleep2_exit1)]
    }
    
    func test_exit0() {
        
        let task = NSTask()
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "exit 0"]
        
        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 0)
    }
    
    func test_exit1() {
        
        let task = NSTask()
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "exit 1"]

        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 1)
    }
    
    func test_exit100() {
        
        let task = NSTask()
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "exit 100"]
        
        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 100)
    }
    
    func test_sleep2() {
        
        let task = NSTask()
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "sleep 2"]
        
        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 0)
    }
    
    func test_sleep2_exit1() {
        
        let task = NSTask()
        
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "sleep 2; exit 1"]
        
        task.launch()
        task.waitUntilExit()
        XCTAssertEqual(task.terminationStatus, 1)
    }
}
