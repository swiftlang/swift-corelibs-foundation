//
//  TestNSTask.swift
//  Foundation
//
//  Created by Daniel Stenmark on 12/27/15.
//  Copyright © 2015 Apple. All rights reserved.
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
    var allTests: [(String, () throws -> Void)] {
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