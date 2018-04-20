// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if !DARWIN_COMPATIBILITY_TESTS
class TestProgressFraction : XCTestCase {
    static var allTests: [(String, (TestProgressFraction) -> () throws -> Void)] {
        return [
            ("test_equal", test_equal ),
            ("test_subtract", test_subtract),
            ("test_multiply", test_multiply),
            ("test_simplify", test_simplify),
            ("test_overflow", test_overflow),
            ("test_addOverflow", test_addOverflow),
            ("test_andAndSubtractOverflow", test_andAndSubtractOverflow),
            ("test_fractionFromDouble", test_fractionFromDouble),
            ("test_unnecessaryOverflow", test_unnecessaryOverflow),
        ]
    }

    func test_equal() {
        let f1 = _ProgressFraction(completed: 5, total: 10)
        let f2 = _ProgressFraction(completed: 100, total: 200)
        
        XCTAssertEqual(f1, f2)
        
        let f3 = _ProgressFraction(completed: 3, total: 10)
        XCTAssertNotEqual(f1, f3)
        
        let f4 = _ProgressFraction(completed: 5, total: 10)
        XCTAssertEqual(f1, f4)
    }
    
    func test_addSame() {
        let f1 = _ProgressFraction(completed: 5, total: 10)
        let f2 = _ProgressFraction(completed: 3, total: 10)

        let r = f1 + f2
        XCTAssertEqual(r.completed, 8)
        XCTAssertEqual(r.total, 10)
    }
    
    func test_addDifferent() {
        let f1 = _ProgressFraction(completed: 5, total: 10)
        let f2 = _ProgressFraction(completed: 300, total: 1000)

        let r = f1 + f2
        XCTAssertEqual(r.completed, 800)
        XCTAssertEqual(r.total, 1000)
    }
    
    func test_subtract() {
        let f1 = _ProgressFraction(completed: 5, total: 10)
        let f2 = _ProgressFraction(completed: 3, total: 10)

        let r = f1 - f2
        XCTAssertEqual(r.completed, 2)
        XCTAssertEqual(r.total, 10)
    }
    
    func test_multiply() {
        let f1 = _ProgressFraction(completed: 5, total: 10)
        let f2 = _ProgressFraction(completed: 1, total: 2)

        let r = f1 * f2
        XCTAssertEqual(r.completed, 5)
        XCTAssertEqual(r.total, 20)
    }
    
    func test_simplify() {
        let f1 = _ProgressFraction(completed: 5, total: 10)
        let f2 = _ProgressFraction(completed: 3, total: 10)

        let r = (f1 + f2).simplified()
        
        XCTAssertEqual(r.completed, 4)
        XCTAssertEqual(r.total, 5)
    }
    
    func test_overflow() {
        // These prime numbers are problematic for overflowing
        let denominators : [Int64] = [5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 69]
        
        var f1 = _ProgressFraction(completed: 1, total: 3)
        for d in denominators {
            f1 = f1 + _ProgressFraction(completed: 1, total: d)
        }
        
        let fractionResult = f1.fractionCompleted
        var expectedResult = 1.0 / 3.0
        for d in denominators {
            expectedResult = expectedResult + 1.0 / Double(d)
        }
        
        XCTAssertEqual(fractionResult, expectedResult, accuracy: 0.00001)
    }
    
    func test_addOverflow() {
        // These prime numbers are problematic for overflowing
        let denominators : [Int64] = [5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 69]
        var f1 = _ProgressFraction(completed: 1, total: 3)
        for d in denominators {
            f1 = f1 + _ProgressFraction(completed: 1, total: d)
        }

        // f1 should be in overflow
        XCTAssertTrue(f1.overflowed)
        
        let f2 = _ProgressFraction(completed: 1, total: 4) + f1
        
        // f2 should also be in overflow
        XCTAssertTrue(f2.overflowed)
        
        // And it should have completed value of about 1.0/4.0 + f1.fractionCompleted
        let expected = (1.0 / 4.0) + f1.fractionCompleted
        
        XCTAssertEqual(expected, f2.fractionCompleted, accuracy: 0.00001)
    }
    
    func test_andAndSubtractOverflow() {
        let f1 = _ProgressFraction(completed: 48, total: 60)
        let f2 = _ProgressFraction(completed: 5880, total: 7200)
        let f3 = _ProgressFraction(completed: 7048893638467736640, total: 8811117048084670800)
        
        let result1 = (f3 - f1) + f2
        XCTAssertTrue(result1.completed > 0)
        
        let result2 = (f3 - f2) + f1
        XCTAssertTrue(result2.completed < 60)
    }
    
    func test_fractionFromDouble() {
        let d = 4.25 // exactly representable in binary
        let f1 = _ProgressFraction(double: d)
        
        let simplified = f1.simplified()
        XCTAssertEqual(simplified.completed, 17)
        XCTAssertEqual(simplified.total, 4)
    }
    
    func test_unnecessaryOverflow() {
        // just because a fraction has a large denominator doesn't mean it needs to overflow
        let f1 = _ProgressFraction(completed: (Int64.max - 1) / 2, total: Int64.max - 1)
        let f2 = _ProgressFraction(completed: 1, total: 16)
        
        let r = f1 + f2
        XCTAssertFalse(r.overflowed)
    }
}
#endif

