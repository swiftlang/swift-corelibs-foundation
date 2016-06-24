// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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

class TestNSProgress: XCTestCase {
    static var allTests: [(String, (TestNSProgress) -> () throws -> Void)] {
        return [
            // Creating Progress Objects
            ("test_init", test_init),
            ("test_initWithUserInfo", test_initWithUserInfo),
            
            // Current Progress Object
            ("test_currentProgress", test_currentProgress),
            
            // Reporting Progress
            ("test_totalUnitCount", test_totalUnitCount),
            ("test_completedUnitCount", test_completedUnitCount),
            
            // Observing Progress
            ("test_fractionCompleted", test_fractionCompleted),
            
            // Progress Information
            ("test_isIndeterminate", test_isIndeterminate),
            ("test_kind", test_kind),
            ("test_setUserInfoObject", test_setUserInfoObject),
        ]
    }
}

//MARK: - Creating Progress Objects

extension TestNSProgress {
    
    func test_init() {
        let progress = NSProgress()
        XCTAssertTrue(progress.userInfo.isEmpty)
        XCTAssertEqual(progress.totalUnitCount, 0)
        XCTAssertEqual(progress.completedUnitCount, 0)
        XCTAssertNil(progress.kind)
        XCTAssertTrue(progress.isCancellable)
        XCTAssertFalse(progress.isPausable)
    }
    
    func test_initWithUserInfo() {
        var progress = NSProgress(parent: nil, userInfo: nil)
        XCTAssertTrue(progress.userInfo.isEmpty)
        XCTAssertEqual(progress.totalUnitCount, 0)
        XCTAssertEqual(progress.completedUnitCount, 0)
        XCTAssertNil(progress.kind)
        XCTAssertTrue(progress.isCancellable)
        XCTAssertFalse(progress.isPausable)
        
        progress = NSProgress(parent: nil, userInfo: ["key".bridge(): "value".bridge()])
        XCTAssertTrue(progress.userInfo == ["key".bridge(): "value".bridge()] as [NSObject:AnyObject])
        XCTAssertEqual(progress.totalUnitCount, 0)
        XCTAssertEqual(progress.completedUnitCount, 0)
        XCTAssertNil(progress.kind)
        XCTAssertTrue(progress.isCancellable)
        XCTAssertFalse(progress.isPausable)
    }
    
}

//MARK: - Current Progress Object

extension TestNSProgress {
    
    func test_currentProgress() {
        XCTAssertNil(NSProgress.current())
        XCTAssertTrue(isTrueInThread { NSProgress.current() == nil })
        
        let progress = NSProgress()
        progress.becomeCurrent(withPendingUnitCount: 0)
        
        XCTAssertEqual(NSProgress.current(), progress)
        XCTAssertTrue(isTrueInThread { NSProgress.current() == nil })
        
        progress.resignCurrent()
        
        XCTAssertNil(NSProgress.current())
        XCTAssertTrue(isTrueInThread { NSProgress.current() == nil })
    }
    
}

//MARK: - Reporting Progress

extension TestNSProgress {
    
    func test_totalUnitCount() {
        let progress = NSProgress(parent: nil, userInfo: nil)
        progress.totalUnitCount = 100
        XCTAssertEqual(progress.totalUnitCount, 100)
    }
    
    func test_completedUnitCount() {
        let progress = NSProgress(parent: nil, userInfo: nil)
        progress.completedUnitCount = 50
        XCTAssertEqual(progress.completedUnitCount, 50)
    }
    
}

//MARK: - Observing Progress

extension TestNSProgress {
    
    func test_fractionCompleted() {
        let progress = NSProgress(parent: nil, userInfo: nil)
        
        progress.completedUnitCount = -4
        progress.totalUnitCount = -10
        XCTAssertEqual(progress.fractionCompleted, 0)
        
        progress.completedUnitCount = -20
        progress.totalUnitCount = -10
        XCTAssertEqual(progress.fractionCompleted, 0)
        
        progress.completedUnitCount = -10
        progress.totalUnitCount = 0
        XCTAssertEqual(progress.fractionCompleted, 0)
        
        progress.completedUnitCount = 0
        progress.totalUnitCount = -20
        XCTAssertEqual(progress.fractionCompleted, 0)
        
        progress.completedUnitCount = 5
        progress.totalUnitCount = -10
        XCTAssertEqual(progress.fractionCompleted, 0)
        
        progress.completedUnitCount = -5
        progress.totalUnitCount = 10
        XCTAssertEqual(progress.fractionCompleted, 0)
        
        progress.completedUnitCount = 0
        progress.totalUnitCount = 0
        XCTAssertEqual(progress.fractionCompleted, 0)
        
        progress.completedUnitCount = 20
        progress.totalUnitCount = 0
        XCTAssertEqual(progress.fractionCompleted, 1.0)
        
        progress.completedUnitCount = 0
        progress.totalUnitCount = 100
        XCTAssertEqual(progress.fractionCompleted, 0)
        
        progress.completedUnitCount = 20
        progress.totalUnitCount = 100
        XCTAssertEqual(progress.fractionCompleted, 0.2)
        
        progress.completedUnitCount = 150
        progress.totalUnitCount = 100
        XCTAssertEqual(progress.fractionCompleted, 1.5)
    }
    
}

//MARK: - Progress Information

extension TestNSProgress {
    
    func test_isIndeterminate() {
        let progress = NSProgress(parent: nil, userInfo: nil)
        
        progress.completedUnitCount = -4
        progress.totalUnitCount = -10
        XCTAssertTrue(progress.isIndeterminate)
        
        progress.completedUnitCount = -10
        progress.totalUnitCount = 0
        XCTAssertTrue(progress.isIndeterminate)
        
        progress.completedUnitCount = 0
        progress.totalUnitCount = -20
        XCTAssertTrue(progress.isIndeterminate)
        
        progress.completedUnitCount = 0
        progress.totalUnitCount = 0
        XCTAssertTrue(progress.isIndeterminate)
        
        progress.completedUnitCount = 20
        progress.totalUnitCount = 0
        XCTAssertFalse(progress.isIndeterminate)
        
        progress.completedUnitCount = 0
        progress.totalUnitCount = 100
        XCTAssertFalse(progress.isIndeterminate)
        
        progress.completedUnitCount = 20
        progress.totalUnitCount = 100
        XCTAssertFalse(progress.isIndeterminate)
    }
    
    func test_kind() {
        let progress = NSProgress(parent: nil, userInfo: nil)
        
        progress.kind = "custom"
        XCTAssertEqual(progress.kind, "custom")
        progress.kind = NSProgressKindFile
        XCTAssertEqual(progress.kind, NSProgressKindFile)
    }
    
    func test_setUserInfoObject() {
        let progress = NSProgress(parent: nil, userInfo: nil)
        
        progress.setUserInfoObject(NSNumber(value: 5), forKey: "number")
        XCTAssertTrue(progress.userInfo == ["number".bridge(): NSNumber(value: 5)] as [NSObject:AnyObject])
        
        progress.setUserInfoObject("hello".bridge(), forKey: "string")
        XCTAssertTrue(progress.userInfo == ["number".bridge(): NSNumber(value: 5), "string".bridge(): "hello".bridge()] as [NSObject:AnyObject])
        
        progress.setUserInfoObject(nil, forKey: "number")
        XCTAssertTrue(progress.userInfo == ["string".bridge(): "hello".bridge()] as [NSObject:AnyObject])
    }

}

private func isTrueInThread(predicate: () -> Bool) -> Bool {
    var result: Bool = false
    let thread = NSThread {
        result = predicate()
    }
    
    thread.start()
    
    while !thread.finished {
        NSThread.sleepForTimeInterval(0.01)
    }
    
    return result
}

private func ==(lhs: [NSObject: AnyObject], rhs: [NSObject: AnyObject] ) -> Bool {
    return lhs.bridge() == rhs.bridge()
}
