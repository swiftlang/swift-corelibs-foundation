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


class TestNSIndexSet : XCTestCase {
    
    static var allTests: [(String, (TestNSIndexSet) -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_enumeration", test_enumeration),
            ("test_sequenceType", test_sequenceType),
            ("test_removal", test_removal),
            ("test_addition", test_addition),
            ("test_setAlgebra", test_setAlgebra),
        ]
    }
    
    func test_BasicConstruction() {
        let set = IndexSet()
        let set2 = IndexSet(integersIn: 4..<11)
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set.first, nil)
        XCTAssertEqual(set.last, nil)
        XCTAssertEqual(set2.count, 7)
        XCTAssertEqual(set2.first, 4)
        XCTAssertEqual(set2.last, 10)
        
        let set3 = NSMutableIndexSet()
        set3.add(2)
        set3.add(5)
        set3.add(in: NSMakeRange(4, 7))
        set3.add(8)
        XCTAssertEqual(set3.count, 8)
        XCTAssertEqual(set3.firstIndex, 2)
        XCTAssertEqual(set3.lastIndex, 10)
        
    }
    
    func test_enumeration() {
        let set = IndexSet(integersIn: 4..<11)
        var result = Array<Int>()
        for idx in set {
            result.append(idx)
        }
        XCTAssertEqual(result, [4, 5, 6, 7, 8, 9, 10])
        
        result = Array<Int>()
        for idx in IndexSet() {
            result.append(idx)
        }
        XCTAssertEqual(result, [])
        
        let disjointSet = NSMutableIndexSet()
        disjointSet.add(2)
        disjointSet.add(5)
        disjointSet.add(8)
        disjointSet.add(in: NSMakeRange(7, 3))
        disjointSet.add(11)
        disjointSet.add(in: NSMakeRange(13, 2))
        result = Array<Int>()
        disjointSet.enumerate(options: []) { (idx, _) in
            result.append(idx)
        }
        XCTAssertEqual(result, [2, 5, 7, 8, 9, 11, 13, 14])
    }
    
    func test_sequenceType() {
        let set = IndexSet(integersIn: 4..<11)
        var result = Array<Int>()
        for idx in set {
            result.append(idx)
        }
        XCTAssertEqual(result, [4, 5, 6, 7, 8, 9, 10])
    }
    
    func test_removal() {
        let removalSet = NSMutableIndexSet(indexesIn: NSMakeRange(0, 10))
        removalSet.remove(0)
        removalSet.remove(in: NSMakeRange(9, 5))
        removalSet.remove(in: NSMakeRange(2, 4))
        XCTAssertEqual(removalSet.count, 4)
        XCTAssertEqual(removalSet.firstIndex, 1)
        XCTAssertEqual(removalSet.lastIndex, 8)
        
        var additionSet = IndexSet()
        additionSet.insert(1)
        additionSet.insert(integersIn: 6..<9)
        
        XCTAssertTrue(removalSet.isEqual(to: additionSet))
        
    }
    
    func test_addition() {
        
        let testSetA = NSMutableIndexSet(index: 0)
        testSetA.add(5)
        testSetA.add(6)
        testSetA.add(7)
        testSetA.add(8)
        testSetA.add(42)
        
        let testInputA1 = [0,5,6,7,8,42]
        var i = 0
        
        if testInputA1.count == testSetA.count {
            testSetA.enumerate(options: []) { (idx, _) in
                XCTAssertEqual(idx, testInputA1[i])
                i += 1
            }
        }
        else {
            XCTFail("IndexSet does not contain correct number of indexes")
        }
        
        
        let testInputA2 = [NSMakeRange(0, 1),NSMakeRange(5, 4),NSMakeRange(42, 1)]
        i = 0
        
        testSetA.enumerateRanges(options: []) { (range, _) in
            let testRange = testInputA2[i]
            XCTAssertEqual(range.location, testRange.location)
            XCTAssertEqual(range.length, testRange.length)
            i += 1
        }
        
        let testSetB = NSMutableIndexSet(indexesIn: NSMakeRange(0,5))
        testSetB.add(in: NSMakeRange(42, 3))
        testSetB.add(in: NSMakeRange(2, 2))
        testSetB.add(in: NSMakeRange(18, 1))
        
        let testInputB1 = [0,1,2,3,4,18,42,43,44]
        i = 0
        
        if testInputB1.count == testSetB.count {
            testSetB.enumerate(options: []) { (idx, _) in
                XCTAssertEqual(idx, testInputB1[i])
                i += 1
            }
        }
        else {
            XCTFail("IndexSet does not contain correct number of indexes")
        }
        
        
        let testInputB2 = [NSMakeRange(0, 5),NSMakeRange(18, 1),NSMakeRange(42, 3)]
        i = 0
        
        testSetB.enumerateRanges(options: []) { (range, _) in
            let testRange = testInputB2[i]
            XCTAssertEqual(range.location, testRange.location)
            XCTAssertEqual(range.length, testRange.length)
            i += 1
        }
    
    }
    
    func test_setAlgebra() {
        
        var is1, is2, expected: IndexSet
        
        do {
            is1 = IndexSet(integersIn: 0..<5)
            is2 = IndexSet(integersIn: 3..<10)
            
            expected = IndexSet(integersIn: 0..<3)
            expected.insert(integersIn: 5..<10)
            
            XCTAssertTrue(expected == is1.symmetricDifference(is2))
            XCTAssertTrue(expected == is2.symmetricDifference(is1))
        }
        
        do {
            is1 = IndexSet([0, 2])
            is2 = IndexSet([0, 1, 2])
            XCTAssertTrue(IndexSet(integer: 1) == is1.symmetricDifference(is2))
        }
        
        do {
            is1 = IndexSet(integersIn: 0..<5)
            is2 = IndexSet(integersIn: 4..<10)
            
            expected = IndexSet(integer: 4)
            
            XCTAssertTrue(expected == is1.intersection(is2))
            XCTAssertTrue(expected == is2.intersection(is1))
        }
        
        do {
            is1 = IndexSet([0, 2])
            is2 = IndexSet([0, 1, 2])
            XCTAssertTrue(is1 == is1.intersection(is2))
        }
        
    }
    
}
