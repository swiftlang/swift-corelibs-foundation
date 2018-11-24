// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestIndexSet : XCTestCase {
    
    static var allTests: [(String, (TestIndexSet) -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_enumeration", test_enumeration),
            ("test_sequenceType", test_sequenceType),
            ("test_removal", test_removal),
            ("test_addition", test_addition),
            ("test_setAlgebra", test_setAlgebra),
            ("test_copy", test_copy),
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_copy", test_copy),
            ("test_enumeration", test_enumeration),
            ("test_sequenceType", test_sequenceType),
            ("test_removal", test_removal),
            ("test_addition", test_addition),
            ("test_setAlgebra", test_setAlgebra),
            ("testEnumeration", testEnumeration),
            ("testSubsequence", testSubsequence),
            ("testIndexRange", testIndexRange),
            ("testMutation", testMutation),
            ("testContainsAndIntersects", testContainsAndIntersects),
            ("testContainsIndexSet", testContainsIndexSet),
            ("testIteration", testIteration),
            ("testRangeIteration", testRangeIteration),
            ("testSubrangeIteration", testSubrangeIteration),
            ("testSlicing", testSlicing),
            ("testEmptyIteration", testEmptyIteration),
            ("testSubsequences", testSubsequences),
            ("testFiltering", testFiltering),
            ("testFilteringRanges", testFilteringRanges),
            ("testShift", testShift),
            ("testSymmetricDifference", testSymmetricDifference),
            ("testIntersection", testIntersection),
            ("testUnion", testUnion),
            ("test_findIndex", test_findIndex),
            ("testIndexingPerformance", testIndexingPerformance),
            ("test_AnyHashableContainingIndexSet", test_AnyHashableContainingIndexSet),
            ("test_AnyHashableCreatedFromNSIndexSet", test_AnyHashableCreatedFromNSIndexSet),
            ("test_unconditionallyBridgeFromObjectiveC", test_unconditionallyBridgeFromObjectiveC),
            ("testInsertNonOverlapping", testInsertNonOverlapping),
            ("testInsertOverlapping", testInsertOverlapping),
            ("testInsertOverlappingExtend", testInsertOverlappingExtend),
            ("testInsertOverlappingMultiple", testInsertOverlappingMultiple),
            ("testRemoveNonOverlapping", testRemoveNonOverlapping),
            ("testRemoveOverlapping", testRemoveOverlapping),
            ("testRemoveSplitting", testRemoveSplitting),
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
        set3.add(in: NSRange(location: 4, length: 7))
        set3.add(8)
        XCTAssertEqual(set3.count, 8)
        XCTAssertEqual(set3.firstIndex, 2)
        XCTAssertEqual(set3.lastIndex, 10)
        
    }

    func test_copy() {
        let range: NSRange = NSRange(location: 3, length: 4)
        let array : [Int] = [1,2,3,4,5,6,7,8,9,10]
        let indexSet = NSMutableIndexSet()
        for index in array {
            indexSet.add(index)
        }

        //Test copy operation of NSIndexSet case which is immutable
        let selfIndexSet: NSIndexSet = NSIndexSet(indexesIn: range)
        let selfIndexSetCopy = selfIndexSet.copy() as! NSIndexSet
        XCTAssertTrue(selfIndexSetCopy === selfIndexSet)
        XCTAssertTrue(selfIndexSetCopy.isEqual(to: selfIndexSet._bridgeToSwift()))

        //Test copy operation of NSMutableIndexSet case
        let mutableIndexSet: NSIndexSet = indexSet
        indexSet.add(11)
        let mutableIndexSetCopy = mutableIndexSet.copy() as! NSIndexSet
        XCTAssertFalse(mutableIndexSetCopy === mutableIndexSet)
        XCTAssertTrue(mutableIndexSetCopy.isEqual(to: mutableIndexSet._bridgeToSwift()))
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
        disjointSet.add(in: NSRange(location: 7, length: 3))
        disjointSet.add(11)
        disjointSet.add(in: NSRange(location: 13, length: 2))
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
        var removalSet = NSMutableIndexSet(indexesIn: NSRange(location: 0, length: 10))
        removalSet.remove(0)
        removalSet.remove(in: NSRange(location: 9, length: 5))
        removalSet.remove(in: NSRange(location: 2, length: 4))
        XCTAssertEqual(removalSet.count, 4)
        XCTAssertEqual(removalSet.firstIndex, 1)
        XCTAssertEqual(removalSet.lastIndex, 8)
        
        var expected = IndexSet()
        expected.insert(1)
        expected.insert(integersIn: 6..<9)
        XCTAssertTrue(removalSet.isEqual(to: expected))
        
        // Removing a non-existent element has no effect
        removalSet.remove(9)
        XCTAssertTrue(removalSet.isEqual(to: expected))
        
        removalSet.removeAllIndexes()
        
        expected = IndexSet()
        XCTAssertTrue(removalSet.isEqual(to: expected))
        
        // Set removal
        removalSet = NSMutableIndexSet(indexesIn: NSRange(location: 0, length: 10))
        removalSet.remove(IndexSet(integersIn: 8..<11))
        removalSet.remove(IndexSet(integersIn: 0..<2))
        removalSet.remove(IndexSet(integersIn: 4..<6))
        XCTAssertEqual(removalSet.count, 4)
        XCTAssertEqual(removalSet.firstIndex, 2)
        XCTAssertEqual(removalSet.lastIndex, 7)

        expected = IndexSet()
        expected.insert(integersIn: 2..<4)
        expected.insert(integersIn: 6..<8)
        XCTAssertTrue(removalSet.isEqual(to: expected))
        
        // Removing an empty set has no effect
        removalSet.remove(IndexSet())
        XCTAssertTrue(removalSet.isEqual(to: expected))
        
        // Removing non-existent elements has no effect
        removalSet.remove(IndexSet(integersIn: 0..<2))
        XCTAssertTrue(removalSet.isEqual(to: expected))
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
        
        
        let testInputA2 = [NSRange(location: 0, length: 1),NSRange(location: 5, length: 4),NSRange(location: 42, length: 1)]
        i = 0
        
        testSetA.enumerateRanges(options: []) { (range, _) in
            let testRange = testInputA2[i]
            XCTAssertEqual(range.location, testRange.location)
            XCTAssertEqual(range.length, testRange.length)
            i += 1
        }
        
        let testSetB = NSMutableIndexSet(indexesIn: NSRange(location: 0, length: 5))
        testSetB.add(in: NSRange(location: 42, length: 3))
        testSetB.add(in: NSRange(location: 2, length: 2))
        testSetB.add(in: NSRange(location: 18, length: 1))
        
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
        
        
        let testInputB2 = [NSRange(location: 0, length: 5),NSRange(location: 18, length: 1),NSRange(location: 42, length: 3)]
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
    
    
    
    func testEnumeration() {
        let someIndexes = IndexSet(integersIn: 3...4)
        let first = someIndexes.startIndex
        let last = someIndexes.endIndex
        
        XCTAssertNotEqual(first, last)
        
        var count = 0
        var firstValue = 0
        var secondValue = 0
        for v in someIndexes {
            if count == 0 { firstValue = v }
            if count == 1 { secondValue = v }
            count += 1
        }
        
        XCTAssertEqual(2, count)
        XCTAssertEqual(3, firstValue)
        XCTAssertEqual(4, secondValue)
    }
    
    func testSubsequence() {
        var someIndexes = IndexSet(integersIn: 1..<3)
        someIndexes.insert(integersIn: 10..<20)
        
        let intersectingRange = someIndexes.indexRange(in: 5..<21)
        XCTAssertFalse(intersectingRange.isEmpty)
        
        let sub = someIndexes[intersectingRange]
        var count = 0
        for i in sub {
            if count == 0 {
                XCTAssertEqual(10, i)
            }
            if count == 9 {
                XCTAssertEqual(19, i)
            }
            count += 1
        }
        XCTAssertEqual(count, 10)
    }
    
    func testIndexRange() {
        var someIndexes = IndexSet(integersIn: 1..<3)
        someIndexes.insert(integersIn: 10..<20)
        
        var r : Range<IndexSet.Index>
        
        r = someIndexes.indexRange(in: 1..<3)
        XCTAssertEqual(1, someIndexes[r.lowerBound])
        XCTAssertEqual(10, someIndexes[r.upperBound])
        
        r = someIndexes.indexRange(in: 0..<0)
        XCTAssertEqual(r.lowerBound, r.upperBound)
        
        r = someIndexes.indexRange(in: 100..<201)
        XCTAssertEqual(r.lowerBound, r.upperBound)
        XCTAssertTrue(r.isEmpty)
        
        r = someIndexes.indexRange(in: 0..<100)
        XCTAssertEqual(r.lowerBound, someIndexes.startIndex)
        XCTAssertEqual(r.upperBound, someIndexes.endIndex)
        
        r = someIndexes.indexRange(in: 1..<11)
        XCTAssertEqual(1, someIndexes[r.lowerBound])
        XCTAssertEqual(11, someIndexes[r.upperBound])
        
        let empty = IndexSet()
        XCTAssertTrue(empty.indexRange(in: 1..<3).isEmpty)
    }
    
    func testMutation() {
        var someIndexes = IndexSet(integersIn: 1..<3)
        someIndexes.insert(3)
        someIndexes.insert(4)
        someIndexes.insert(5)
        
        someIndexes.insert(10)
        someIndexes.insert(11)
        
        XCTAssertEqual(someIndexes.count, 7)
        
        someIndexes.remove(11)
        
        XCTAssertEqual(someIndexes.count, 6)
        
        someIndexes.insert(integersIn: 100...101)
        XCTAssertEqual(8, someIndexes.count)
        XCTAssertEqual(2, someIndexes.count(in: 100...101))
        
        someIndexes.remove(integersIn: 100...101)
        XCTAssertEqual(6, someIndexes.count)
        XCTAssertEqual(0, someIndexes.count(in: 100...101))
        
        someIndexes.insert(integersIn: 200..<202)
        XCTAssertEqual(8, someIndexes.count)
        XCTAssertEqual(2, someIndexes.count(in: 200..<202))
        
        someIndexes.remove(integersIn: 200..<202)
        XCTAssertEqual(6, someIndexes.count)
        XCTAssertEqual(0, someIndexes.count(in: 200..<202))
    }
    
    func testContainsAndIntersects() {
        let someIndexes = IndexSet(integersIn: 1..<10)
        
        XCTAssertTrue(someIndexes.contains(integersIn: 1..<10))
        XCTAssertTrue(someIndexes.contains(integersIn: 1...9))
        XCTAssertTrue(someIndexes.contains(integersIn: 2..<10))
        XCTAssertTrue(someIndexes.contains(integersIn: 2...9))
        XCTAssertTrue(someIndexes.contains(integersIn: 1..<9))
        XCTAssertTrue(someIndexes.contains(integersIn: 1...8))
        
        XCTAssertFalse(someIndexes.contains(integersIn: 0..<10))
        XCTAssertFalse(someIndexes.contains(integersIn: 0...9))
        XCTAssertFalse(someIndexes.contains(integersIn: 2..<11))
        XCTAssertFalse(someIndexes.contains(integersIn: 2...10))
        XCTAssertFalse(someIndexes.contains(integersIn: 0..<9))
        XCTAssertFalse(someIndexes.contains(integersIn: 0...8))
        
        XCTAssertTrue(someIndexes.intersects(integersIn: 1..<10))
        XCTAssertTrue(someIndexes.intersects(integersIn: 1...9))
        XCTAssertTrue(someIndexes.intersects(integersIn: 2..<10))
        XCTAssertTrue(someIndexes.intersects(integersIn: 2...9))
        XCTAssertTrue(someIndexes.intersects(integersIn: 1..<9))
        XCTAssertTrue(someIndexes.intersects(integersIn: 1...8))
        
        XCTAssertTrue(someIndexes.intersects(integersIn: 0..<10))
        XCTAssertTrue(someIndexes.intersects(integersIn: 0...9))
        XCTAssertTrue(someIndexes.intersects(integersIn: 2..<11))
        XCTAssertTrue(someIndexes.intersects(integersIn: 2...10))
        XCTAssertTrue(someIndexes.intersects(integersIn: 0..<9))
        XCTAssertTrue(someIndexes.intersects(integersIn: 0...8))
        
        XCTAssertFalse(someIndexes.intersects(integersIn: 0..<0))
        XCTAssertFalse(someIndexes.intersects(integersIn: 10...12))
        XCTAssertFalse(someIndexes.intersects(integersIn: 10..<12))
    }

    func testContainsIndexSet() {
        var someIndexes = IndexSet()
        someIndexes.insert(integersIn: 1..<2)
        someIndexes.insert(integersIn: 100..<200)
        someIndexes.insert(integersIn: 1000..<2000)

        let contained1 = someIndexes
        let contained2 = IndexSet(integersIn: 120..<150)

        var contained3 = IndexSet()
        contained3.insert(integersIn: 100..<200)
        contained3.insert(integersIn: 1500..<1600)

        let notContained1 = IndexSet(integer: 9)
        let notContained2 = IndexSet(integersIn: 150..<300)
        var notContained3 = IndexSet()
        notContained3.insert(integersIn: 1..<2)
        notContained3.insert(integersIn: 100..<200)
        notContained3.insert(integersIn: 1000..<2000)
        notContained3.insert(integersIn: 3000..<5000)

        XCTAssertTrue(someIndexes.contains(integersIn: contained1))
        XCTAssertTrue(someIndexes.contains(integersIn: contained2))
        XCTAssertTrue(someIndexes.contains(integersIn: contained3))

        XCTAssertFalse(someIndexes.contains(integersIn: notContained1))
        XCTAssertFalse(someIndexes.contains(integersIn: notContained2))
        XCTAssertFalse(someIndexes.contains(integersIn: notContained3))

        let emptySet = IndexSet()

        XCTAssertTrue(emptySet.contains(integersIn: emptySet))
        XCTAssertTrue(someIndexes.contains(integersIn: emptySet))
        XCTAssertFalse(emptySet.contains(integersIn: someIndexes))
    }
    
    func testIteration() {
        var someIndexes = IndexSet(integersIn: 1..<5)
        someIndexes.insert(integersIn: 8..<11)
        someIndexes.insert(15)
        
        let start = someIndexes.startIndex
        let end = someIndexes.endIndex
        
        // Count forwards
        var i = start
        var count = 0
        while i != end {
            count += 1
            i = someIndexes.index(after: i)
        }
        XCTAssertEqual(8, count)
        
        // Count backwards
        i = end
        count = 0
        while i != start {
            i = someIndexes.index(before: i)
            count += 1
        }
        XCTAssertEqual(8, count)
        
        // Count using a for loop
        count = 0
        for _ in someIndexes {
            count += 1
        }
        XCTAssertEqual(8, count)
        
        // Go the other way
        count = 0
        for _ in someIndexes.reversed() {
            count += 1
        }
        XCTAssertEqual(8, count)
    }
    
    func testRangeIteration() {
        var someIndexes = IndexSet(integersIn: 1..<5)
        someIndexes.insert(integersIn: 8..<11)
        someIndexes.insert(15)
        
        var count = 0
        for r in someIndexes.rangeView {
            // print("\(r)")
            count += 1
            if count == 3 {
                XCTAssertEqual(r, 15..<16)
            }
        }
        XCTAssertEqual(3, count)
        
        // Backwards
        count = 0
        for r in someIndexes.rangeView.reversed() {
            // print("\(r)")
            count += 1
            if count == 3 {
                XCTAssertEqual(r, 1..<5)
            }
        }
        XCTAssertEqual(3, count)
    }
    
    func testSubrangeIteration() {
        var someIndexes = IndexSet(integersIn: 2..<5)
        someIndexes.insert(integersIn: 8..<11)
        someIndexes.insert(integersIn: 15..<20)
        someIndexes.insert(integersIn: 30..<40)
        someIndexes.insert(integersIn: 60..<80)
        
        var count = 0
        for _ in someIndexes.rangeView {
            count += 1
        }
        XCTAssertEqual(5, count)
        
        
        count = 0
        for r in someIndexes.rangeView(of: 9..<35) {
            if count == 0 {
                XCTAssertEqual(r, 9..<11)
            }
            count += 1
            if count == 3 {
                XCTAssertEqual(r, 30..<35)
            }
        }
        XCTAssertEqual(3, count)
        
        count = 0
        for r in someIndexes.rangeView(of: 0...34) {
            if count == 0 {
                XCTAssertEqual(r, 2..<5)
            }
            count += 1
            if count == 4 {
                XCTAssertEqual(r, 30..<35)
            }
        }
        XCTAssertEqual(4, count)
        
        // Empty intersection, before start
        count = 0
        for _ in someIndexes.rangeView(of: 0..<1) {
            count += 1
        }
        XCTAssertEqual(0, count)
        
        // Empty range
        count = 0
        for _ in someIndexes.rangeView(of: 0..<0) {
            count += 1
        }
        XCTAssertEqual(0, count)
        
        // Empty intersection, after end
        count = 0
        for _ in someIndexes.rangeView(of: 999..<1000) {
            count += 1
        }
        XCTAssertEqual(0, count)
    }
    
    func testSlicing() {
        var someIndexes = IndexSet(integersIn: 2..<5)
        someIndexes.insert(integersIn: 8..<11)
        someIndexes.insert(integersIn: 15..<20)
        someIndexes.insert(integersIn: 30..<40)
        someIndexes.insert(integersIn: 60..<80)
        
        var r : Range<IndexSet.Index>
        
        r = someIndexes.indexRange(in: 5..<25)
        XCTAssertEqual(8, someIndexes[r.lowerBound])
        XCTAssertEqual(19, someIndexes[someIndexes.index(before: r.upperBound)])
        var count = 0
        for _ in someIndexes[r] {
            count += 1
        }
        
        XCTAssertEqual(8, someIndexes.count(in: 5..<25))
        XCTAssertEqual(8, count)
        
        r = someIndexes.indexRange(in: 100...199)
        XCTAssertTrue(r.isEmpty)
        
        let emptySlice = someIndexes[r]
        XCTAssertEqual(0, emptySlice.count)
        
        let boundarySlice = someIndexes[someIndexes.indexRange(in: 2..<3)]
        XCTAssertEqual(1, boundarySlice.count)
        
        let boundarySlice2 = someIndexes[someIndexes.indexRange(in: 79..<80)]
        XCTAssertEqual(1, boundarySlice2.count)
        
        let largeSlice = someIndexes[someIndexes.indexRange(in: 0..<100000)]
        XCTAssertEqual(someIndexes.count, largeSlice.count)
    }
    
    func testEmptyIteration() {
        var empty = IndexSet()
        let start = empty.startIndex
        let end = empty.endIndex
        
        XCTAssertEqual(start, end)
        
        var count = 0
        for _ in empty {
            count += 1
        }
        
        XCTAssertEqual(count, 0)
        
        count = 0
        for _ in empty.rangeView {
            count += 1
        }
        
        XCTAssertEqual(count, 0)
        
        empty.insert(5)
        empty.remove(5)
        
        count = 0
        for _ in empty {
            count += 1
        }
        XCTAssertEqual(count, 0)
        
        count = 0
        for _ in empty.rangeView {
            count += 1
        }
        XCTAssertEqual(count, 0)
    }
    
    func testSubsequences() {
        var someIndexes = IndexSet(integersIn: 1..<5)
        someIndexes.insert(integersIn: 8..<11)
        someIndexes.insert(15)
        
        // Get a subsequence of this IndexSet
        let range = someIndexes.indexRange(in: 4..<15)
        let subSet = someIndexes[range]
        
        XCTAssertEqual(subSet.count, 4)
        
        // Iterate a subset
        var count = 0
        for _ in subSet {
            count += 1
        }
        XCTAssertEqual(count, 4)
        
        // And in reverse
        count = 0
        for _ in subSet.reversed() {
            count += 1
        }
        XCTAssertEqual(count, 4)
    }
    
    func testFiltering() {
        var someIndexes = IndexSet(integersIn: 1..<5)
        someIndexes.insert(integersIn: 8..<11)
        someIndexes.insert(15)
        
        // An array
        let resultArray = someIndexes.filter { $0 % 2 == 0 }
        XCTAssertEqual(resultArray.count, 4)
        
        let resultSet = someIndexes.filteredIndexSet { $0 % 2 == 0 }
        XCTAssertEqual(resultSet.count, 4)
        
        let resultOutsideRange = someIndexes.filteredIndexSet(in: 20..<30, includeInteger: { _ in return true } )
        XCTAssertEqual(resultOutsideRange.count, 0)
        
        let resultInRange = someIndexes.filteredIndexSet(in: 0..<16, includeInteger: { _ in return true } )
        XCTAssertEqual(resultInRange.count, someIndexes.count)
    }
    
    func testFilteringRanges() {
        var someIndexes = IndexSet(integersIn: 1..<5)
        someIndexes.insert(integersIn: 8..<11)
        someIndexes.insert(15)
        
        let resultArray = someIndexes.rangeView.filter { $0.count > 1 }
        XCTAssertEqual(resultArray.count, 2)
    }
    
    func testShift() {
        var someIndexes = IndexSet(integersIn: 1..<5)
        someIndexes.insert(integersIn: 8..<11)
        someIndexes.insert(15)
        
        let lastValue = someIndexes.last!
        
        someIndexes.shift(startingAt: 13, by: 1)
        
        // Count should not have changed
        XCTAssertEqual(someIndexes.count, 8)
        
        // But the last value should have
        XCTAssertEqual(lastValue + 1, someIndexes.last!)
        
        // Shift starting at something not in the set
        someIndexes.shift(startingAt: 0, by: 1)
        
        // Count should not have changed, again
        XCTAssertEqual(someIndexes.count, 8)
        
        // But the last value should have, again
        XCTAssertEqual(lastValue + 2, someIndexes.last!)
    }
    
    func testSymmetricDifference() {
        var is1 : IndexSet
        var is2 : IndexSet
        var expected : IndexSet
        
        do {
            is1 = IndexSet()
            is1.insert(integersIn: 1..<3)
            is1.insert(integersIn: 4..<11)
            is1.insert(integersIn: 15..<21)
            is1.insert(integersIn: 40..<51)
            
            is2 = IndexSet()
            is2.insert(integersIn: 5..<18)
            is2.insert(integersIn: 45..<61)
            
            expected = IndexSet()
            expected.insert(integersIn: 1..<3)
            expected.insert(4)
            expected.insert(integersIn: 11..<15)
            expected.insert(integersIn: 18..<21)
            expected.insert(integersIn: 40..<45)
            expected.insert(integersIn: 51..<61)
            
            XCTAssertEqual(expected, is1.symmetricDifference(is2))
            XCTAssertEqual(expected, is2.symmetricDifference(is1))
        }
        
        do {
            is1 = IndexSet()
            is1.insert(integersIn: 5..<18)
            is1.insert(integersIn: 45..<61)
            
            is2 = IndexSet()
            is2.insert(integersIn: 5..<18)
            is2.insert(integersIn: 45..<61)
            
            expected = IndexSet()
            XCTAssertEqual(expected, is1.symmetricDifference(is2))
            XCTAssertEqual(expected, is2.symmetricDifference(is1))
        }
        
        do {
            is1 = IndexSet(integersIn: 1..<10)
            is2 = IndexSet(integersIn: 20..<30)
            
            expected = IndexSet()
            expected.insert(integersIn: 1..<10)
            expected.insert(integersIn: 20..<30)
            XCTAssertEqual(expected, is1.symmetricDifference(is2))
            XCTAssertEqual(expected, is2.symmetricDifference(is1))
        }
        
        do {
            is1 = IndexSet(integersIn: 1..<10)
            is2 = IndexSet(integersIn: 1..<11)
            expected = IndexSet(integer: 10)
            XCTAssertEqual(expected, is1.symmetricDifference(is2))
            XCTAssertEqual(expected, is2.symmetricDifference(is1))
        }
        
        do {
            is1 = IndexSet(integer: 42)
            is2 = IndexSet(integer: 42)
            XCTAssertEqual(IndexSet(), is1.symmetricDifference(is2))
            XCTAssertEqual(IndexSet(), is2.symmetricDifference(is1))
        }
        
        do {
            is1 = IndexSet(integer: 1)
            is1.insert(3)
            is1.insert(5)
            is1.insert(7)
            
            is2 = IndexSet(integer: 0)
            is2.insert(2)
            is2.insert(4)
            is2.insert(6)
            
            expected = IndexSet(integersIn: 0..<8)
            XCTAssertEqual(expected, is1.symmetricDifference(is2))
            XCTAssertEqual(expected, is2.symmetricDifference(is1))
        }
        
        do {
            is1 = IndexSet(integersIn: 0..<5)
            is2 = IndexSet(integersIn: 3..<10)
            
            expected = IndexSet(integersIn: 0..<3)
            expected.insert(integersIn: 5..<10)
            
            XCTAssertEqual(expected, is1.symmetricDifference(is2))
            XCTAssertEqual(expected, is2.symmetricDifference(is1))
        }
        
        do {
            is1 = IndexSet([0, 2])
            is2 = IndexSet([0, 1, 2])
            XCTAssertEqual(IndexSet(integer: 1), is1.symmetricDifference(is2))
        }
    }
    
    func testIntersection() {
        var is1 : IndexSet
        var is2 : IndexSet
        var expected : IndexSet
        
        do {
            is1 = IndexSet()
            is1.insert(integersIn: 1..<3)
            is1.insert(integersIn: 4..<11)
            is1.insert(integersIn: 15..<21)
            is1.insert(integersIn: 40..<51)
            
            is2 = IndexSet()
            is2.insert(integersIn: 5..<18)
            is2.insert(integersIn: 45..<61)
            
            expected = IndexSet()
            expected.insert(integersIn: 5..<11)
            expected.insert(integersIn: 15..<18)
            expected.insert(integersIn: 45..<51)
            
            XCTAssertEqual(expected, is1.intersection(is2))
            XCTAssertEqual(expected, is2.intersection(is1))
        }
        
        do {
            is1 = IndexSet()
            is1.insert(integersIn: 5..<11)
            is1.insert(integersIn: 20..<31)
            
            is2 = IndexSet()
            is2.insert(integersIn: 11..<20)
            is2.insert(integersIn: 31..<40)
            
            XCTAssertEqual(IndexSet(), is1.intersection(is2))
            XCTAssertEqual(IndexSet(), is2.intersection(is1))
        }
        
        do {
            is1 = IndexSet(integer: 42)
            is2 = IndexSet(integer: 42)
            XCTAssertEqual(IndexSet(integer: 42), is1.intersection(is2))
        }
        
        do {
            is1 = IndexSet(integer: 1)
            is1.insert(3)
            is1.insert(5)
            is1.insert(7)
            
            is2 = IndexSet(integer: 0)
            is2.insert(2)
            is2.insert(4)
            is2.insert(6)
            
            expected = IndexSet()
            XCTAssertEqual(expected, is1.intersection(is2))
            XCTAssertEqual(expected, is2.intersection(is1))
        }
        
        do {
            is1 = IndexSet(integersIn: 0..<5)
            is2 = IndexSet(integersIn: 4..<10)
            
            expected = IndexSet(integer: 4)
            
            XCTAssertEqual(expected, is1.intersection(is2))
            XCTAssertEqual(expected, is2.intersection(is1))
        }
        
        do {
            is1 = IndexSet([0, 2])
            is2 = IndexSet([0, 1, 2])
            XCTAssertEqual(is1, is1.intersection(is2))
        }
    }
    
    func testUnion() {
        var is1 : IndexSet
        var is2 : IndexSet
        var expected : IndexSet
        
        do {
            is1 = IndexSet()
            is1.insert(integersIn: 1..<3)
            is1.insert(integersIn: 4..<11)
            is1.insert(integersIn: 15..<21)
            is1.insert(integersIn: 40..<51)
            
            is2 = IndexSet()
            is2.insert(integersIn: 5..<18)
            is2.insert(integersIn: 45..<61)
            
            expected = IndexSet()
            expected.insert(integersIn: 1..<3)
            expected.insert(integersIn: 4..<21)
            expected.insert(integersIn: 40..<61)
            
            let u1 = is1.union(is2)
            
            XCTAssertEqual(expected, u1)
        }
        
        do {
            is1 = IndexSet()
            is1.insert(integersIn: 5..<11)
            is1.insert(integersIn: 20..<31)
            
            is2 = IndexSet()
            is2.insert(integersIn: 11..<20)
            is2.insert(integersIn: 31..<40)
            
            expected = IndexSet()
            expected.insert(integersIn: 5..<11)
            expected.insert(integersIn: 20..<31)
            expected.insert(integersIn: 11..<20)
            expected.insert(integersIn: 31..<40)
            
            XCTAssertEqual(expected, is1.union(is2))
            XCTAssertEqual(expected, is2.union(is1))
        }
        
        do {
            is1 = IndexSet(integer: 42)
            is2 = IndexSet(integer: 42)
            let u1 = is1.union(is2)
            XCTAssertEqual(IndexSet(integer: 42), u1)
        }
        
        do {
            is1 = IndexSet()
            is1.insert(integersIn: 5..<10)
            is1.insert(integersIn: 15..<20)
            
            is2 = IndexSet()
            is2.insert(integersIn: 1..<4)
            is2.insert(integersIn: 15..<20)
            
            expected = IndexSet()
            expected.insert(integersIn: 1..<4)
            expected.insert(integersIn: 5..<10)
            expected.insert(integersIn: 15..<20)
            
            XCTAssertEqual(expected, is1.union(is2))
            XCTAssertEqual(expected, is2.union(is1))
        }
        
        XCTAssertEqual(IndexSet(), IndexSet().union(IndexSet()))
        
        do {
            is1 = IndexSet(integer: 1)
            is1.insert(3)
            is1.insert(5)
            is1.insert(7)
            
            is2 = IndexSet(integer: 0)
            is2.insert(2)
            is2.insert(4)
            is2.insert(6)
            
            expected = IndexSet()
            XCTAssertEqual(expected, is1.intersection(is2))
            XCTAssertEqual(expected, is2.intersection(is1))
        }
        
        do {
            is1 = IndexSet(integersIn: 0..<5)
            is2 = IndexSet(integersIn: 3..<10)
            
            expected = IndexSet(integersIn: 0..<10)
            
            XCTAssertEqual(expected, is1.union(is2))
            XCTAssertEqual(expected, is2.union(is1))
        }
        
        do {
            is1 = IndexSet()
            is1.insert(2)
            is1.insert(6)
            is1.insert(21)
            is1.insert(22)
            
            is2 = IndexSet()
            is2.insert(8)
            is2.insert(14)
            is2.insert(21)
            is2.insert(22)
            is2.insert(24)
            
            expected = IndexSet()
            expected.insert(2)
            expected.insert(6)
            expected.insert(21)
            expected.insert(22)
            expected.insert(8)
            expected.insert(14)
            expected.insert(21)
            expected.insert(22)
            expected.insert(24)
            
            let u1 = is1.union(is2)
            let u2 = is2.union(is1)
            
            XCTAssertEqual(expected, u1)
            XCTAssertEqual(expected, u2)
        }
    }
    
    func test_findIndex() {
        var i = IndexSet()
        
        // Verify nil result for empty sets
        XCTAssertEqual(nil, i.first)
        XCTAssertEqual(nil, i.last)
        XCTAssertEqual(nil, i.integerGreaterThan(5))
        XCTAssertEqual(nil, i.integerLessThan(5))
        XCTAssertEqual(nil, i.integerGreaterThanOrEqualTo(5))
        XCTAssertEqual(nil, i.integerLessThanOrEqualTo(5))
        
        i.insert(integersIn: 5..<10)
        i.insert(integersIn: 15..<20)
        
        // Verify non-nil result
        XCTAssertEqual(5, i.first)
        XCTAssertEqual(19, i.last)
        
        XCTAssertEqual(nil, i.integerGreaterThan(19))
        XCTAssertEqual(5, i.integerGreaterThan(3))
        
        XCTAssertEqual(nil, i.integerLessThan(5))
        XCTAssertEqual(5, i.integerLessThan(6))
        
        XCTAssertEqual(nil, i.integerGreaterThanOrEqualTo(20))
        XCTAssertEqual(19, i.integerGreaterThanOrEqualTo(19))
        
        XCTAssertEqual(nil, i.integerLessThanOrEqualTo(4))
        XCTAssertEqual(5, i.integerLessThanOrEqualTo(5))
    }
    
    // MARK: -
    // MARK: Performance Testing
    
    func largeIndexSet() -> IndexSet {
        var result = IndexSet()
        
        for i in 1..<10000 {
            let start = i * 10
            let end = start + 9
            result.insert(integersIn: start..<end + 1)
        }
        
        return result
    }
    
    func testIndexingPerformance() {
        /*
        let set = largeIndexSet()
        self.measureBlock {
            var count = 0
            while count < 20 {
                for _ in set {
                }
                count += 1
            }
        }
        */
    }
    
    func test_AnyHashableContainingIndexSet() {
        let values: [IndexSet] = [
            IndexSet([0, 1]),
            IndexSet([0, 1, 2]),
            IndexSet([0, 1, 2]),
        ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssert(IndexSet.self == type(of: anyHashables[0].base))
        XCTAssert(IndexSet.self == type(of: anyHashables[1].base))
        XCTAssert(IndexSet.self == type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableCreatedFromNSIndexSet() {
        let values: [NSIndexSet] = [
            NSIndexSet(index: 0),
            NSIndexSet(index: 1),
            NSIndexSet(index: 1),
        ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssert(IndexSet.self == type(of: anyHashables[0].base))
        XCTAssert(IndexSet.self == type(of: anyHashables[1].base))
        XCTAssert(IndexSet.self == type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_unconditionallyBridgeFromObjectiveC() {
        XCTAssertEqual(IndexSet(), IndexSet._unconditionallyBridgeFromObjectiveC(nil))
    }

    func testInsertNonOverlapping() {
        var tested = IndexSet()
        tested.insert(integersIn: 1..<2)
        tested.insert(integersIn: 100..<200)
        tested.insert(integersIn: 1000..<2000)

        tested.insert(200)

        var expected = IndexSet()
        expected.insert(integersIn: 1..<2)
        expected.insert(integersIn: 100..<201)
        expected.insert(integersIn: 1000..<2000)

        XCTAssertEqual(tested, expected)
    }

    func testInsertOverlapping() {
        var tested = IndexSet()
        tested.insert(integersIn: 1..<2)
        tested.insert(integersIn: 100..<200)
        tested.insert(integersIn: 1000..<2000)
        tested.insert(integersIn: 10000..<20000)

        tested.insert(integersIn: 150..<1500)

        var expected = IndexSet()
        expected.insert(integersIn: 1..<2)
        expected.insert(integersIn: 100..<2000)
        expected.insert(integersIn: 10000..<20000)

        XCTAssertEqual(tested, expected)
    }

    func testInsertOverlappingExtend() {
        var tested = IndexSet()
        tested.insert(integersIn: 1..<2)
        tested.insert(integersIn: 100..<200)
        tested.insert(integersIn: 1000..<2000)

        tested.insert(integersIn: 50..<500)

        var expected = IndexSet()
        expected.insert(integersIn: 1..<2)
        expected.insert(integersIn: 50..<500)
        expected.insert(integersIn: 1000..<2000)

        XCTAssertEqual(tested, expected)
    }

    func testInsertOverlappingMultiple() {
        var tested = IndexSet()
        tested.insert(integersIn: 1..<2)
        tested.insert(integersIn: 100..<200)
        tested.insert(integersIn: 1000..<2000)
        tested.insert(integersIn: 10000..<20000)

        tested.insert(integersIn: 150..<3000)

        var expected = IndexSet()
        expected.insert(integersIn: 1..<2)
        expected.insert(integersIn: 100..<3000)
        expected.insert(integersIn: 10000..<20000)

        XCTAssertEqual(tested, expected)
    }

    func testRemoveNonOverlapping() {
        var tested = IndexSet()
        tested.insert(integersIn: 1..<2)
        tested.insert(integersIn: 100..<200)
        tested.insert(integersIn: 1000..<2000)

        tested.remove(199)

        var expected = IndexSet()
        expected.insert(integersIn: 1..<2)
        expected.insert(integersIn: 100..<199)
        expected.insert(integersIn: 1000..<2000)

        XCTAssertEqual(tested, expected)
    }

    func testRemoveOverlapping() {
        var tested = IndexSet()
        tested.insert(integersIn: 1..<2)
        tested.insert(integersIn: 100..<200)
        tested.insert(integersIn: 1000..<2000)

        tested.remove(integersIn: 150..<1500)

        var expected = IndexSet()
        expected.insert(integersIn: 1..<2)
        expected.insert(integersIn: 100..<150)
        expected.insert(integersIn: 1500..<2000)

        XCTAssertEqual(tested, expected)
    }

    func testRemoveSplitting() {
        var tested = IndexSet()
        tested.insert(integersIn: 1..<2)
        tested.insert(integersIn: 100..<200)
        tested.insert(integersIn: 1000..<2000)

        tested.remove(integersIn: 150..<160)

        var expected = IndexSet()
        expected.insert(integersIn: 1..<2)
        expected.insert(integersIn: 100..<150)
        expected.insert(integersIn: 160..<200)
        expected.insert(integersIn: 1000..<2000)

        XCTAssertEqual(tested, expected)
    }

}
