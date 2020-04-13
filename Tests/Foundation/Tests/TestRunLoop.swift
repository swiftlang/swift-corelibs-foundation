// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestRunLoop : XCTestCase {
    func test_constants() {
        XCTAssertEqual(RunLoop.Mode.common.rawValue, "kCFRunLoopCommonModes",
                       "\(RunLoop.Mode.common.rawValue) is not equal to kCFRunLoopCommonModes")
        
        XCTAssertEqual(RunLoop.Mode.default.rawValue, "kCFRunLoopDefaultMode",
                       "\(RunLoop.Mode.default.rawValue) is not equal to kCFRunLoopDefaultMode")
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
            
            XCTAssertEqual(runLoopMode, RunLoop.Mode.default)
        }
        runLoop.add(dummyTimer, forMode: .default)
        let result = runLoop.run(mode: .default, before: endDate)
        
        XCTAssertTrue(result)
        XCTAssertTrue(flag)
    }
    
    func test_runLoopLimitDate() {
        let runLoop = RunLoop.current
        let timeInterval = TimeInterval(1)
        let expectedTimeInterval = Date(timeInterval: timeInterval, since: Date()).timeIntervalSince1970

        let dummyTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in }
        runLoop.add(dummyTimer, forMode: .default)
        
        guard let timerTickInterval = runLoop.limitDate(forMode: .default)?.timeIntervalSince1970 else {
            return
        }
        
        XCTAssertLessThan(abs(timerTickInterval - expectedTimeInterval), 0.01)
    }

    func test_runLoopPoll() {
        let runLoop = RunLoop.current

        let startDate = Date()
        runLoop.run(until: Date())
        let endDate = Date()

        XCTAssertLessThan(endDate.timeIntervalSince(startDate), 0.5)
    }
    
    func test_commonModes() {
        let runLoop = RunLoop.current
        let done = expectation(description: "The timer has fired")
        let timer = Timer(timeInterval: 1, repeats: false) { (_) in
            done.fulfill()
        }
        
        runLoop.add(timer, forMode: .common)
        
        waitForExpectations(timeout: 10)
    }
    
    func test_addingRemovingPorts() {
        let runLoop = RunLoop.current
        var didDeallocate = false
        
        do {
            let port = TestPort {
                didDeallocate = true
            }
            let customMode = RunLoop.Mode(rawValue: "Custom")
            
            XCTAssertEqual(port.scheduledModes, [])
            
            runLoop.add(port, forMode: .default)
            XCTAssertEqual(port.scheduledModes, [.default])
            
            runLoop.add(port, forMode: .default)
            XCTAssertEqual(port.scheduledModes, [.default])
            
            runLoop.add(port, forMode: customMode)
            XCTAssertEqual(port.scheduledModes, [.default, customMode])
            
            runLoop.remove(port, forMode: customMode)
            XCTAssertEqual(port.scheduledModes, [.default])
            
            runLoop.add(port, forMode: customMode)
            XCTAssertEqual(port.scheduledModes, [.default, customMode])
            
            port.invalidate()
        }
        
        XCTAssertTrue(didDeallocate)
    }
    
    static var allTests : [(String, (TestRunLoop) -> () throws -> Void)] {
        return [
            ("test_constants", test_constants),
            ("test_runLoopInit", test_runLoopInit),
            ("test_commonModes", test_commonModes),
            ("test_runLoopRunMode", test_runLoopRunMode),
            ("test_runLoopLimitDate", test_runLoopLimitDate),
            ("test_runLoopPoll", test_runLoopPoll),
            ("test_addingRemovingPorts", test_addingRemovingPorts),
        ]
    }
}

class TestPort: Port {
    let sentinel: () -> Void
    init(sentinel: @escaping () -> Void) {
        self.sentinel = sentinel
        super.init()
    }

    // Required on Darwin
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        invalidate()
        sentinel()
    }
    
    private var _isValid = true
    open override var isValid: Bool { return _isValid }
    
    open override func invalidate() {
        guard isValid else { return }
        
        _isValid = false
        NotificationCenter.default.post(name: Port.didBecomeInvalidNotification, object: self)
    }
    
    var scheduledModes: [RunLoop.Mode] = []
    
    open override func schedule(in runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        scheduledModes.append(mode)
    }
    
    open override func remove(from runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        scheduledModes = scheduledModes.filter { $0 != mode }
    }
}
