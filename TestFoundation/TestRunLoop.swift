// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestRunLoop : XCTestCase {
    static var allTests : [(String, (TestRunLoop) -> () throws -> Void)] {
        return [
            ("test_constants", test_constants),
            ("test_runLoopInit", test_runLoopInit),
            ("test_commonModes", test_commonModes),
            // these tests do not work the same as Darwin https://bugs.swift.org/browse/SR-399
//            ("test_runLoopRunMode", test_runLoopRunMode),
//            ("test_runLoopLimitDate", test_runLoopLimitDate),
        ]
    }
    
    func test_constants() {
        XCTAssertEqual(RunLoopMode.commonModes.rawValue, "kCFRunLoopCommonModes",
                       "\(RunLoopMode.commonModes.rawValue) is not equal to kCFRunLoopCommonModes")
        
        XCTAssertEqual(RunLoopMode.defaultRunLoopMode.rawValue, "kCFRunLoopDefaultMode",
                       "\(RunLoopMode.defaultRunLoopMode.rawValue) is not equal to kCFRunLoopDefaultMode")
    }
    
    func test_runLoopInit() {
        let mainRunLoop = RunLoop.main
        let currentRunLoop = RunLoop.current

        let secondAccessOfMainLoop = RunLoop.main
        XCTAssertEqual(mainRunLoop, secondAccessOfMainLoop, "fetching the main loop a second time should be equal")
        XCTAssertTrue(mainRunLoop === secondAccessOfMainLoop, "fetching the main loop a second time should be identical")
        
        let secondAccessOfCurrentLoop = RunLoop.current
        XCTAssertEqual(currentRunLoop, secondAccessOfCurrentLoop, "fetching the current loop a second time should be equal")
        XCTAssertTrue(currentRunLoop === secondAccessOfCurrentLoop, "fetching the current loop a second time should be identical")
        
        // We can assume that the tests will be run on the main run loop
        // so the current loop should be the main loop
        XCTAssertEqual(mainRunLoop, currentRunLoop, "the current run loop should be the main loop")
    }
    
    func test_runLoopRunMode() {
        let runLoop = RunLoop.current
        let timeInterval = TimeInterval(0.05)
        let endDate = Date(timeInterval: timeInterval, since: Date())
        var flag = false

        let dummyTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { _ in
            flag = true
            guard let runLoopMode = runLoop.currentMode else {
                XCTFail("Run loop mode is not defined")
                return
            }
            
            XCTAssertEqual(runLoopMode, RunLoopMode.defaultRunLoopMode)
        }
        runLoop.add(dummyTimer, forMode: .defaultRunLoopMode)
        let result = runLoop.run(mode: .defaultRunLoopMode, before: endDate)
        
        XCTAssertFalse(result) // should be .Finished
        XCTAssertTrue(flag)
    }
    
    func test_runLoopLimitDate() {
        let runLoop = RunLoop.current
        let timeInterval = TimeInterval(1)
        let expectedTimeInterval = Date(timeInterval: timeInterval, since: Date()).timeIntervalSince1970

        let dummyTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in }
        runLoop.add(dummyTimer, forMode: .defaultRunLoopMode)
        
        guard let timerTickInterval = runLoop.limitDate(forMode: .defaultRunLoopMode)?.timeIntervalSince1970 else {
            return
        }
        
        XCTAssertLessThan(abs(timerTickInterval - expectedTimeInterval), 0.01)
    }
    
    func test_commonModes() {
        let runLoop = RunLoop.current
        let done = expectation(description: "The timer has fired")
        let timer = Timer(timeInterval: 1, repeats: false) { (_) in
            done.fulfill()
        }
        
        runLoop.add(timer, forMode: .commonModes)
        
        waitForExpectations(timeout: 10)
    }
}
