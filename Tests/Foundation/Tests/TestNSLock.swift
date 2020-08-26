// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSLock: XCTestCase {
    static var allTests: [(String, (TestNSLock) -> () throws -> Void)] {
        return [

            ("test_lockWait", test_lockWait),
            ("test_threadsAndLocks", test_threadsAndLocks),
            ("test_recursiveLock", test_recursiveLock),
            
        ]
    }


    func test_lockWait() {
        let condition = NSCondition()
        let lock = NSLock()

        func test(waitTime: TimeInterval, shouldLock: Bool) -> Bool {
            let locked = lock.lock(before: Date.init(timeIntervalSinceNow: waitTime))
            if locked {
                lock.unlock()
            }
            return locked == shouldLock
        }

        let thread = Thread() {
            lock.lock()

            // Now wake up the main thread so it can try to obtain the lock that
            // this thread just obtained.
            condition.lock()
            condition.signal()
            condition.unlock()

            Thread.sleep(forTimeInterval: 8)
            lock.unlock()
        }
        condition.lock()
        thread.start()
        condition.wait()
        condition.unlock()

        XCTAssertTrue(test(waitTime: 0, shouldLock: false))
        XCTAssertTrue(test(waitTime: -1, shouldLock: false))
        XCTAssertTrue(test(waitTime: 1, shouldLock: false))
        XCTAssertTrue(test(waitTime: 4, shouldLock: false))
        XCTAssertTrue(test(waitTime: 8, shouldLock: true))
        XCTAssertTrue(test(waitTime: -1, shouldLock: true))
    }


    func test_threadsAndLocks() {
        let condition = NSCondition()
        let lock = NSLock()
        let threadCount = 10
        let endSeconds: Double = 2

        let endTime = Date.init(timeIntervalSinceNow: endSeconds)
        var threadsStarted = Array<Bool>(repeating: false, count: threadCount)
        let arrayLock = NSLock()

        for t in 0..<threadCount {
            let thread = Thread() {
                condition.lock()
                arrayLock.lock()
                threadsStarted[t] = true
                arrayLock.unlock()

                condition.wait()
                condition.unlock()
                for _ in 1...50 {
                    let r = Double.random(in: 0...0.02)
                    Thread.sleep(forTimeInterval: r)
                    if lock.lock(before: endTime) {
                        lock.unlock()
                    }
                }
                arrayLock.lock()
                threadsStarted[t] = false
                arrayLock.unlock()
            }
            thread.start()
        }

        var totalThreads = 0
        repeat {
            arrayLock.lock()
            totalThreads = threadsStarted.filter {$0 == true }.count
            arrayLock.unlock()
        } while totalThreads < threadCount
        XCTAssertEqual(totalThreads, threadCount)

        condition.lock()
        condition.broadcast()
        condition.unlock()

        Thread.sleep(until: endTime)
        repeat {
            arrayLock.lock()
            totalThreads = threadsStarted.filter {$0 == false }.count
            arrayLock.unlock()
        } while totalThreads < threadCount
        XCTAssertEqual(totalThreads, threadCount)

        let gotLock = lock.try()
        XCTAssertTrue(gotLock)
        if gotLock {
            lock.unlock()
        }
    }
    
    func test_recursiveLock() {
        // We will start 10 threads, and their collective task will be to reduce
        // the countdown value to zero in less than 30 seconds.
        
        let threadCount = 10
        let countdownPerThread = 1000
        let endTime = Date(timeIntervalSinceNow: 30)
        
        var completedThreadCount = 0
        var countdownValue = threadCount * countdownPerThread
        
        let threadCompletedCondition = NSCondition()
        let countdownValueLock = NSRecursiveLock()
        
        for _ in 0..<threadCount {
            let thread = Thread {
                
                // Some dummy work on countdown.
                // Add/substract operations are balanced to decrease countdown
                // exactly by countdownPerThread
                
                for _ in 0..<countdownPerThread {
                    countdownValueLock.lock()
                    countdownValue -= 3
                    countdownValueLock.lock()
                    countdownValue += 4
                    countdownValueLock.unlock()
                    countdownValueLock.unlock()
                    
                    countdownValueLock.lock()
                    countdownValue += 2
                    countdownValueLock.lock()
                    countdownValue -= 1
                    countdownValueLock.unlock()
                    countdownValue -= 3
                    countdownValueLock.unlock()
                    
                    countdownValueLock.lock()
                    countdownValue += 1
                    countdownValueLock.unlock()
                    
                    countdownValueLock.lock()
                    countdownValue -= 1
                    countdownValueLock.unlock()
                }
                
                threadCompletedCondition.lock()
                completedThreadCount += 1
                threadCompletedCondition.broadcast()
                threadCompletedCondition.unlock()
            }
            thread.start()
        }
        
        threadCompletedCondition.lock()
        
        var isTimedOut = false
        while !isTimedOut && completedThreadCount < threadCount {
            isTimedOut = !threadCompletedCondition.wait(until: endTime)
        }
        
        countdownValueLock.lock()
        let resultCountdownValue = countdownValue
        countdownValueLock.unlock()
        
        XCTAssertEqual(completedThreadCount, threadCount, "Some threads are still not finished, could be hung")
        XCTAssertEqual(resultCountdownValue, 0, "Wrong coundtdown means unresolved race conditions, locks broken")
        
        threadCompletedCondition.unlock()
    }
}
