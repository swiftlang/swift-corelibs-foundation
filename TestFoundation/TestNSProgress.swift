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
            ("test_initWithTotalUnitCount", test_init),
            ("test_initWithUserInfo", test_initWithUserInfo),
            ("test_totalUnitCount", test_totalUnitCount),
            ("test_completedUnitCount", test_completedUnitCount),
            ("test_fractionCompleted", test_fractionCompleted),
            ("test_isIndeterminate", test_isIndeterminate),
            ("test_kind", test_kind),
            ("test_currentProgress", test_currentProgress)
        ]
    }
    
    func test_init() {
        let progress = NSProgress()
        XCTAssertTrue(progress.userInfo.isEmpty)
        XCTAssertEqual(progress.totalUnitCount, 0)
        XCTAssertEqual(progress.completedUnitCount, 0)
        XCTAssertTrue(progress.isCancellable)
        XCTAssertFalse(progress.isPausable)
    }
    
    func test_initWithUserInfo() {
        var progress = NSProgress(parent: nil, userInfo: nil)
        XCTAssertTrue(progress.userInfo.isEmpty)
        XCTAssertEqual(progress.totalUnitCount, 0)
        XCTAssertEqual(progress.completedUnitCount, 0)
        XCTAssertTrue(progress.isCancellable)
        XCTAssertFalse(progress.isPausable)
        
        progress = NSProgress(parent: nil, userInfo: ["key".bridge(): "value".bridge()])
        XCTAssertTrue(progress.userInfo.count == 1)
        XCTAssertEqual(progress.userInfo["key".bridge()] as? NSString, "value".bridge())
        XCTAssertEqual(progress.totalUnitCount, 0)
        XCTAssertEqual(progress.completedUnitCount, 0)
        XCTAssertTrue(progress.isCancellable)
        XCTAssertFalse(progress.isPausable)
    }
    
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
    
    func test_currentProgress() {
        let progress = NSProgress()
        
        XCTAssertNil(NSProgress.current())
        XCTAssertTrue(isTrueInThread { NSProgress.current() == nil })
        
        progress.becomeCurrent(withPendingUnitCount: 0)
        
        XCTAssertEqual(NSProgress.current(), progress)
        XCTAssertTrue(isTrueInThread { NSProgress.current() == nil })
        
        progress.resignCurrent()
        
        XCTAssertNil(NSProgress.current())
        XCTAssertTrue(isTrueInThread { NSProgress.current() == nil })
    }

}

func isTrueInThread(predicate: () -> Bool) -> Bool {
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