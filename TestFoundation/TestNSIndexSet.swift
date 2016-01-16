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


class TestNSIndexSet : XCTestCase {
    
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_enumeration", test_enumeration),
            ("test_sequenceType", test_sequenceType),
            ("test_removal", test_removal),
            ("test_addition",test_addition),
        ]
    }
    
    func test_BasicConstruction() {
        let set = NSIndexSet()
        let set2 = NSIndexSet(indexesInRange: NSMakeRange(4, 7))
        XCTAssertEqual(set.count, 0)
        XCTAssertEqual(set.firstIndex, NSNotFound)
        XCTAssertEqual(set.lastIndex, NSNotFound)
        XCTAssertEqual(set2.count, 7)
        XCTAssertEqual(set2.firstIndex, 4)
        XCTAssertEqual(set2.lastIndex, 10)
        
        let set3 = NSMutableIndexSet()
        set3.addIndex(2)
        set3.addIndex(5)
        set3.addIndexesInRange(NSMakeRange(4, 7))
        set3.addIndex(8)
        XCTAssertEqual(set3.count, 8)
        XCTAssertEqual(set3.firstIndex, 2)
        XCTAssertEqual(set3.lastIndex, 10)
        
    }
    
    func test_enumeration() {
        let set = NSIndexSet(indexesInRange: NSMakeRange(4, 7))
        var result = Array<Int>()
        set.enumerateIndexesUsingBlock() { (idx, _) in
            result.append(idx)
        }
        XCTAssertEqual(result, [4, 5, 6, 7, 8, 9, 10])
        
        result = Array<Int>()
        NSIndexSet().enumerateIndexesUsingBlock() { (idx, _) in
            result.append(idx)
        }
        XCTAssertEqual(result, [])
        
        let disjointSet = NSMutableIndexSet()
        disjointSet.addIndex(2)
        disjointSet.addIndex(5)
        disjointSet.addIndex(8)
        disjointSet.addIndexesInRange(NSMakeRange(7, 3))
        disjointSet.addIndex(11)
        disjointSet.addIndexesInRange(NSMakeRange(13, 2))
        result = Array<Int>()
        disjointSet.enumerateIndexesUsingBlock() { (idx, _) in
            result.append(idx)
        }
        XCTAssertEqual(result, [2, 5, 7, 8, 9, 11, 13, 14])
    }
    
    func test_sequenceType() {
        let set = NSIndexSet(indexesInRange: NSMakeRange(4, 7))
        var result = Array<Int>()
        for idx in set {
            result.append(idx)
        }
        XCTAssertEqual(result, [4, 5, 6, 7, 8, 9, 10])
    }
    
    func test_removal() {
        let removalSet = NSMutableIndexSet(indexesInRange: NSMakeRange(0, 10))
        removalSet.removeIndex(0)
        removalSet.removeIndexesInRange(NSMakeRange(9, 5))
        removalSet.removeIndexesInRange(NSMakeRange(2, 4))
        XCTAssertEqual(removalSet.count, 4)
        XCTAssertEqual(removalSet.firstIndex, 1)
        XCTAssertEqual(removalSet.lastIndex, 8)
        
        let additionSet = NSMutableIndexSet()
        additionSet.addIndex(1)
        additionSet.addIndexesInRange(NSMakeRange(6, 3))
        
        XCTAssertTrue(removalSet.isEqualToIndexSet(additionSet))
        
    }
    
    func test_addition() {
        
        let testSetA = NSMutableIndexSet(index: 0)
        testSetA.addIndex(5)
        testSetA.addIndex(6)
        testSetA.addIndex(7)
        testSetA.addIndex(8)
        testSetA.addIndex(42)
        
        let testInputA1 = [0,5,6,7,8,42]
        var i = 0
        
        if testInputA1.count == testSetA.count {
            testSetA.enumerateIndexesUsingBlock { (idx, _) in
                XCTAssertEqual(idx, testInputA1[i])
                i += 1
            }
        }
        else {
            XCTFail("IndexSet does not contain correct number of indexes")
        }
        
        
        let testInputA2 = [NSMakeRange(0, 1),NSMakeRange(5, 4),NSMakeRange(42, 1)]
        i = 0
        
        testSetA.enumerateRangesUsingBlock { (range, _) in
            let testRange = testInputA2[i]
            XCTAssertEqual(range.location, testRange.location)
            XCTAssertEqual(range.length, testRange.length)
            i += 1
        }
        
        let testSetB = NSMutableIndexSet(indexesInRange: NSMakeRange(0,5))
        testSetB.addIndexesInRange(NSMakeRange(42, 3))
        testSetB.addIndexesInRange(NSMakeRange(2, 2))
        testSetB.addIndexesInRange(NSMakeRange(18, 1))
        
        let testInputB1 = [0,1,2,3,4,18,42,43,44]
        i = 0
        
        if testInputB1.count == testSetB.count {
            testSetB.enumerateIndexesUsingBlock { (idx, _) in
                XCTAssertEqual(idx, testInputB1[i])
                i += 1
            }
        }
        else {
            XCTFail("IndexSet does not contain correct number of indexes")
        }
        
        
        let testInputB2 = [NSMakeRange(0, 5),NSMakeRange(18, 1),NSMakeRange(42, 3)]
        i = 0
        
        testSetB.enumerateRangesUsingBlock { (range, _) in
            let testRange = testInputB2[i]
            XCTAssertEqual(range.location, testRange.location)
            XCTAssertEqual(range.length, testRange.length)
            i += 1
        }
    
    }
    
}