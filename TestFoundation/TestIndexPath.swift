// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestIndexPath: XCTestCase {
    
    static var allTests: [(String, (TestIndexPath) -> () throws -> Void)] {
        return [
            ("testEmpty", testEmpty),
            ("testSingleIndex", testSingleIndex),
            ("testTwoIndexes", testTwoIndexes),
            ("testManyIndexes", testManyIndexes),
            ("testCreateFromSequence", testCreateFromSequence),
            ("testCreateFromLiteral", testCreateFromLiteral),
            ("testDropLast", testDropLast),
            ("testDropLastFromEmpty", testDropLastFromEmpty),
            ("testDropLastFromSingle", testDropLastFromSingle),
            ("testDropLastFromPair", testDropLastFromPair),
            ("testDropLastFromTriple", testDropLastFromTriple),
            ("testStartEndIndex", testStartEndIndex),
            ("testIterator", testIterator),
            ("testIndexing", testIndexing),
            ("testCompare", testCompare),
            ("testHashing", testHashing),
            ("testEquality", testEquality),
            ("testSubscripting", testSubscripting),
            ("testAppending", testAppending),
            ("testAppendEmpty", testAppendEmpty),
            ("testAppendEmptyIndexPath", testAppendEmptyIndexPath),
            ("testAppendManyIndexPath", testAppendManyIndexPath),
            ("testAppendEmptyIndexPathToSingle", testAppendEmptyIndexPathToSingle),
            ("testAppendSingleIndexPath", testAppendSingleIndexPath),
            ("testAppendSingleIndexPathToSingle", testAppendSingleIndexPathToSingle),
            ("testAppendPairIndexPath", testAppendPairIndexPath),
            ("testAppendManyIndexPathToEmpty", testAppendManyIndexPathToEmpty),
            ("testAppendByOperator", testAppendByOperator),
            ("testAppendArray", testAppendArray),
            ("testRanges", testRanges),
            ("testRangeFromEmpty", testRangeFromEmpty),
            ("testRangeFromSingle", testRangeFromSingle),
            ("testRangeFromPair", testRangeFromPair),
            ("testRangeFromMany", testRangeFromMany),
            ("testRangeReplacementSingle", testRangeReplacementSingle),
            ("testRangeReplacementPair", testRangeReplacementPair),
            ("testMoreRanges", testMoreRanges),
            ("testIteration", testIteration),
            ("testDescription", testDescription),
            ("testBridgeToObjC", testBridgeToObjC),
            ("testForceBridgeFromObjC", testForceBridgeFromObjC),
            ("testConditionalBridgeFromObjC", testConditionalBridgeFromObjC),
            ("testUnconditionalBridgeFromObjC", testUnconditionalBridgeFromObjC),
            ("testObjcBridgeType", testObjcBridgeType),
            ("test_AnyHashableContainingIndexPath", test_AnyHashableContainingIndexPath),
            ("test_AnyHashableCreatedFromNSIndexPath", test_AnyHashableCreatedFromNSIndexPath),
            ("test_unconditionallyBridgeFromObjectiveC", test_unconditionallyBridgeFromObjectiveC),
            ("test_slice_1ary", test_slice_1ary),
        ]
    }

    func testEmpty() {
        let ip = IndexPath()
        XCTAssertEqual(ip.count, 0)
    }
    
    func testSingleIndex() {
        let ip = IndexPath(index: 1)
        XCTAssertEqual(ip.count, 1)
        XCTAssertEqual(ip[0], 1)
        
        let highValueIp = IndexPath(index: .max)
        XCTAssertEqual(highValueIp.count, 1)
        XCTAssertEqual(highValueIp[0], .max)
        
        let lowValueIp = IndexPath(index: .min)
        XCTAssertEqual(lowValueIp.count, 1)
        XCTAssertEqual(lowValueIp[0], .min)
    }
    
    func testTwoIndexes() {
        let ip = IndexPath(indexes: [0, 1])
        XCTAssertEqual(ip.count, 2)
        XCTAssertEqual(ip[0], 0)
        XCTAssertEqual(ip[1], 1)
    }
    
    func testManyIndexes() {
        let ip = IndexPath(indexes: [0, 1, 2, 3, 4])
        XCTAssertEqual(ip.count, 5)
        XCTAssertEqual(ip[0], 0)
        XCTAssertEqual(ip[1], 1)
        XCTAssertEqual(ip[2], 2)
        XCTAssertEqual(ip[3], 3)
        XCTAssertEqual(ip[4], 4)
    }
    
    func testCreateFromSequence() {
        let seq = repeatElement(5, count: 3)
        let ip = IndexPath(indexes: seq)
        XCTAssertEqual(ip.count, 3)
        XCTAssertEqual(ip[0], 5)
        XCTAssertEqual(ip[1], 5)
        XCTAssertEqual(ip[2], 5)
    }
    
    func testCreateFromLiteral() {
        let ip: IndexPath = [1, 2, 3, 4]
        XCTAssertEqual(ip.count, 4)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[1], 2)
        XCTAssertEqual(ip[2], 3)
        XCTAssertEqual(ip[3], 4)
    }
    
    func testDropLast() {
        let ip: IndexPath = [1, 2, 3, 4]
        let ip2 = ip.dropLast()
        XCTAssertEqual(ip2.count, 3)
        XCTAssertEqual(ip2[0], 1)
        XCTAssertEqual(ip2[1], 2)
        XCTAssertEqual(ip2[2], 3)
    }
    
    func testDropLastFromEmpty() {
        let ip: IndexPath = []
        let ip2 = ip.dropLast()
        XCTAssertEqual(ip2.count, 0)
    }
    
    func testDropLastFromSingle() {
        let ip: IndexPath = [1]
        let ip2 = ip.dropLast()
        XCTAssertEqual(ip2.count, 0)
    }
    
    func testDropLastFromPair() {
        let ip: IndexPath = [1, 2]
        let ip2 = ip.dropLast()
        XCTAssertEqual(ip2.count, 1)
        XCTAssertEqual(ip2[0], 1)
    }
    
    func testDropLastFromTriple() {
        let ip: IndexPath = [1, 2, 3]
        let ip2 = ip.dropLast()
        XCTAssertEqual(ip2.count, 2)
        XCTAssertEqual(ip2[0], 1)
        XCTAssertEqual(ip2[1], 2)
    }
    
    func testStartEndIndex() {
        let ip: IndexPath = [1, 2, 3, 4]
        XCTAssertEqual(ip.startIndex, 0)
        XCTAssertEqual(ip.endIndex, ip.count)
    }
    
    func testIterator() {
        let ip: IndexPath = [1, 2, 3, 4]
        var iter = ip.makeIterator()
        var sum = 0
        while let index = iter.next() {
            sum += index
        }
        XCTAssertEqual(sum, 1 + 2 + 3 + 4)
    }
    
    func testIndexing() {
        let ip: IndexPath = [1, 2, 3, 4]
        XCTAssertEqual(ip.index(before: 1), 0)
        XCTAssertEqual(ip.index(before: 0), -1) // beyond range!
        XCTAssertEqual(ip.index(after: 1), 2)
        XCTAssertEqual(ip.index(after: 4), 5) // beyond range!
    }
    
    func testCompare() {
        let ip1: IndexPath = [1, 2]
        let ip2: IndexPath = [3, 4]
        let ip3: IndexPath = [5, 1]
        let ip4: IndexPath = [1, 1, 1]
        let ip5: IndexPath = [1, 1, 9]
        
        XCTAssertEqual(ip1.compare(ip1), .orderedSame)
        XCTAssertEqual(ip1 < ip1, false)
        XCTAssertEqual(ip1 <= ip1, true)
        XCTAssertEqual(ip1 == ip1, true)
        XCTAssertEqual(ip1 >= ip1, true)
        XCTAssertEqual(ip1 > ip1, false)
        
        XCTAssertEqual(ip1.compare(ip2), .orderedAscending)
        XCTAssertEqual(ip1 < ip2, true)
        XCTAssertEqual(ip1 <= ip2, true)
        XCTAssertEqual(ip1 == ip2, false)
        XCTAssertEqual(ip1 >= ip2, false)
        XCTAssertEqual(ip1 > ip2, false)
        
        XCTAssertEqual(ip1.compare(ip3), .orderedAscending)
        XCTAssertEqual(ip1 < ip3, true)
        XCTAssertEqual(ip1 <= ip3, true)
        XCTAssertEqual(ip1 == ip3, false)
        XCTAssertEqual(ip1 >= ip3, false)
        XCTAssertEqual(ip1 > ip3, false)
        
        XCTAssertEqual(ip1.compare(ip4), .orderedDescending)
        XCTAssertEqual(ip1 < ip4, false)
        XCTAssertEqual(ip1 <= ip4, false)
        XCTAssertEqual(ip1 == ip4, false)
        XCTAssertEqual(ip1 >= ip4, true)
        XCTAssertEqual(ip1 > ip4, true)
        
        XCTAssertEqual(ip1.compare(ip5), .orderedDescending)
        XCTAssertEqual(ip1 < ip5, false)
        XCTAssertEqual(ip1 <= ip5, false)
        XCTAssertEqual(ip1 == ip5, false)
        XCTAssertEqual(ip1 >= ip5, true)
        XCTAssertEqual(ip1 > ip5, true)
        
        XCTAssertEqual(ip2.compare(ip1), .orderedDescending)
        XCTAssertEqual(ip2 < ip1, false)
        XCTAssertEqual(ip2 <= ip1, false)
        XCTAssertEqual(ip2 == ip1, false)
        XCTAssertEqual(ip2 >= ip1, true)
        XCTAssertEqual(ip2 > ip1, true)
        
        XCTAssertEqual(ip2.compare(ip2), .orderedSame)
        XCTAssertEqual(ip2 < ip2, false)
        XCTAssertEqual(ip2 <= ip2, true)
        XCTAssertEqual(ip2 == ip2, true)
        XCTAssertEqual(ip2 >= ip2, true)
        XCTAssertEqual(ip2 > ip2, false)
        
        XCTAssertEqual(ip2.compare(ip3), .orderedAscending)
        XCTAssertEqual(ip2 < ip3, true)
        XCTAssertEqual(ip2 <= ip3, true)
        XCTAssertEqual(ip2 == ip3, false)
        XCTAssertEqual(ip2 >= ip3, false)
        XCTAssertEqual(ip2 > ip3, false)
        
        XCTAssertEqual(ip2.compare(ip4), .orderedDescending)
        XCTAssertEqual(ip2.compare(ip5), .orderedDescending)
        XCTAssertEqual(ip3.compare(ip1), .orderedDescending)
        XCTAssertEqual(ip3.compare(ip2), .orderedDescending)
        XCTAssertEqual(ip3.compare(ip3), .orderedSame)
        XCTAssertEqual(ip3.compare(ip4), .orderedDescending)
        XCTAssertEqual(ip3.compare(ip5), .orderedDescending)
        XCTAssertEqual(ip4.compare(ip1), .orderedAscending)
        XCTAssertEqual(ip4.compare(ip2), .orderedAscending)
        XCTAssertEqual(ip4.compare(ip3), .orderedAscending)
        XCTAssertEqual(ip4.compare(ip4), .orderedSame)
        XCTAssertEqual(ip4.compare(ip5), .orderedAscending)
        XCTAssertEqual(ip5.compare(ip1), .orderedAscending)
        XCTAssertEqual(ip5.compare(ip2), .orderedAscending)
        XCTAssertEqual(ip5.compare(ip3), .orderedAscending)
        XCTAssertEqual(ip5.compare(ip4), .orderedDescending)
        XCTAssertEqual(ip5.compare(ip5), .orderedSame)
        
        let ip6: IndexPath = [1, 1]
        XCTAssertEqual(ip6.compare(ip5), .orderedAscending)
        XCTAssertEqual(ip5.compare(ip6), .orderedDescending)
    }
    
    func testHashing() {
        let ip1: IndexPath = [5, 1]
        let ip2: IndexPath = [1, 1, 1]
        
        XCTAssertNotEqual(ip1.hashValue, ip2.hashValue)

        // this should not cause an overflow crash
        let hash: Int? = IndexPath(indexes: [Int.max >> 8, 2, Int.max >> 36]).hashValue
        XCTAssertNotNil(hash)
    }
    
    func testEquality() {
        let ip1: IndexPath = [1, 1]
        let ip2: IndexPath = [1, 1]
        let ip3: IndexPath = [1, 1, 1]
        let ip4: IndexPath = []
        let ip5: IndexPath = [1]
        
        XCTAssertTrue(ip1 == ip2)
        XCTAssertFalse(ip1 == ip3)
        XCTAssertFalse(ip1 == ip4)
        XCTAssertFalse(ip4 == ip1)
        XCTAssertFalse(ip5 == ip1)
        XCTAssertFalse(ip5 == ip4)
        XCTAssertTrue(ip4 == ip4)
        XCTAssertTrue(ip5 == ip5)
    }
    
    func testSubscripting() {
        var ip1: IndexPath = [1]
        var ip2: IndexPath = [1, 2]
        var ip3: IndexPath = [1, 2, 3]
        
        XCTAssertEqual(ip1[0], 1)
        
        XCTAssertEqual(ip2[0], 1)
        XCTAssertEqual(ip2[1], 2)
        
        XCTAssertEqual(ip3[0], 1)
        XCTAssertEqual(ip3[1], 2)
        XCTAssertEqual(ip3[2], 3)
        
        ip1[0] = 2
        XCTAssertEqual(ip1[0], 2)
        
        ip2[0] = 2
        ip2[1] = 3
        XCTAssertEqual(ip2[0], 2)
        XCTAssertEqual(ip2[1], 3)
        
        ip3[0] = 2
        ip3[1] = 3
        ip3[2] = 4
        XCTAssertEqual(ip3[0], 2)
        XCTAssertEqual(ip3[1], 3)
        XCTAssertEqual(ip3[2], 4)
        
        let ip4 = ip3[0..<2]
        XCTAssertEqual(ip4.count, 2)
        XCTAssertEqual(ip4[0], 2)
        XCTAssertEqual(ip4[1], 3)
    }
    
    func testAppending() {
        var ip : IndexPath = [1, 2, 3, 4]
        let ip2 = IndexPath(indexes: [5, 6, 7])
        
        ip.append(ip2)
        
        XCTAssertEqual(ip.count, 7)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[6], 7)
        
        let ip3 = ip.appending(IndexPath(indexes: [8, 9]))
        XCTAssertEqual(ip3.count, 9)
        XCTAssertEqual(ip3[7], 8)
        XCTAssertEqual(ip3[8], 9)
        
        let ip4 = ip3.appending([10, 11])
        XCTAssertEqual(ip4.count, 11)
        XCTAssertEqual(ip4[9], 10)
        XCTAssertEqual(ip4[10], 11)
        
        let ip5 = ip.appending(8)
        XCTAssertEqual(ip5.count, 8)
        XCTAssertEqual(ip5[7], 8)
    }
    
    func testAppendEmpty() {
        var ip: IndexPath = []
        ip.append(1)
        
        XCTAssertEqual(ip.count, 1)
        XCTAssertEqual(ip[0], 1)
        
        ip.append(2)
        XCTAssertEqual(ip.count, 2)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[1], 2)
        
        ip.append(3)
        XCTAssertEqual(ip.count, 3)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[1], 2)
        XCTAssertEqual(ip[2], 3)
        
        ip.append(4)
        XCTAssertEqual(ip.count, 4)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[1], 2)
        XCTAssertEqual(ip[2], 3)
        XCTAssertEqual(ip[3], 4)
    }
    
    func testAppendEmptyIndexPath() {
        var ip: IndexPath = []
        ip.append(IndexPath(indexes: []))
        
        XCTAssertEqual(ip.count, 0)
    }
    
    func testAppendManyIndexPath() {
        var ip: IndexPath = []
        ip.append(IndexPath(indexes: [1, 2, 3]))
        
        XCTAssertEqual(ip.count, 3)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[1], 2)
        XCTAssertEqual(ip[2], 3)
    }
    
    func testAppendEmptyIndexPathToSingle() {
        var ip: IndexPath = [1]
        ip.append(IndexPath(indexes: []))
        
        XCTAssertEqual(ip.count, 1)
        XCTAssertEqual(ip[0], 1)
    }
    
    func testAppendSingleIndexPath() {
        var ip: IndexPath = []
        ip.append(IndexPath(indexes: [1]))
        
        XCTAssertEqual(ip.count, 1)
        XCTAssertEqual(ip[0], 1)
    }
    
    func testAppendSingleIndexPathToSingle() {
        var ip: IndexPath = [1]
        ip.append(IndexPath(indexes: [1]))
        
        XCTAssertEqual(ip.count, 2)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[1], 1)
    }
    
    func testAppendPairIndexPath() {
        var ip: IndexPath = []
        ip.append(IndexPath(indexes: [1, 2]))
        
        XCTAssertEqual(ip.count, 2)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[1], 2)
    }
    
    func testAppendManyIndexPathToEmpty() {
        var ip: IndexPath = []
        ip.append(IndexPath(indexes: [1, 2, 3]))
        
        XCTAssertEqual(ip.count, 3)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[1], 2)
        XCTAssertEqual(ip[2], 3)
    }
    
    func testAppendByOperator() {
        let ip1: IndexPath = []
        let ip2: IndexPath = []
        
        let ip3 = ip1 + ip2
        XCTAssertEqual(ip3.count, 0)
        
        let ip4: IndexPath = [1]
        let ip5: IndexPath = [2]
        
        let ip6 = ip4 + ip5
        XCTAssertEqual(ip6.count, 2)
        XCTAssertEqual(ip6[0], 1)
        XCTAssertEqual(ip6[1], 2)
        
        var ip7: IndexPath = []
        ip7 += ip6
        XCTAssertEqual(ip7.count, 2)
        XCTAssertEqual(ip7[0], 1)
        XCTAssertEqual(ip7[1], 2)
    }
    
    func testAppendArray() {
        var ip: IndexPath = [1, 2, 3, 4]
        let indexes = [5, 6, 7]
        
        ip.append(indexes)
        
        XCTAssertEqual(ip.count, 7)
        XCTAssertEqual(ip[0], 1)
        XCTAssertEqual(ip[6], 7)
    }
    
    func testRanges() {
        let ip1 = IndexPath(indexes: [1, 2, 3])
        let ip2 = IndexPath(indexes: [6, 7, 8])
        
        // Replace the whole range
        var mutateMe = ip1
        mutateMe[0..<3] = ip2
        XCTAssertEqual(mutateMe, ip2)
        
        // Insert at the beginning
        mutateMe = ip1
        mutateMe[0..<0] = ip2
        XCTAssertEqual(mutateMe, IndexPath(indexes: [6, 7, 8, 1, 2, 3]))
        
        // Insert at the end
        mutateMe = ip1
        mutateMe[3..<3] = ip2
        XCTAssertEqual(mutateMe, IndexPath(indexes: [1, 2, 3, 6, 7, 8]))
        
        // Insert in middle
        mutateMe = ip1
        mutateMe[2..<2] = ip2
        XCTAssertEqual(mutateMe, IndexPath(indexes: [1, 2, 6, 7, 8, 3]))
    }
    
    func testRangeFromEmpty() {
        let ip1 = IndexPath()
        let ip2 = ip1[0..<0]
        XCTAssertEqual(ip2.count, 0)
    }
    
    func testRangeFromSingle() {
        let ip1 = IndexPath(indexes: [1])
        let ip2 = ip1[0..<0]
        XCTAssertEqual(ip2.count, 0)
        let ip3 = ip1[0..<1]
        XCTAssertEqual(ip3.count, 1)
        XCTAssertEqual(ip3[0], 1)
    }
    
    func testRangeFromPair() {
        let ip1 = IndexPath(indexes: [1, 2])
        let ip2 = ip1[0..<0]
        XCTAssertEqual(ip2.count, 0)
        let ip3 = ip1[0..<1]
        XCTAssertEqual(ip3.count, 1)
        XCTAssertEqual(ip3[0], 1)
        let ip4 = ip1[1..<1]
        XCTAssertEqual(ip4.count, 0)
        let ip5 = ip1[0..<2]
        XCTAssertEqual(ip5.count, 2)
        XCTAssertEqual(ip5[0], 1)
        XCTAssertEqual(ip5[1], 2)
        let ip6 = ip1[1..<2]
        XCTAssertEqual(ip6.count, 1)
        XCTAssertEqual(ip6[0], 2)
        let ip7 = ip1[2..<2]
        XCTAssertEqual(ip7.count, 0)
    }
    
    func testRangeFromMany() {
        let ip1 = IndexPath(indexes: [1, 2, 3])
        let ip2 = ip1[0..<0]
        XCTAssertEqual(ip2.count, 0)
        let ip3 = ip1[0..<1]
        XCTAssertEqual(ip3.count, 1)
        let ip4 = ip1[0..<2]
        XCTAssertEqual(ip4.count, 2)
        let ip5 = ip1[0..<3]
        XCTAssertEqual(ip5.count, 3)
    }
    
    func testRangeReplacementSingle() {
        var ip1 = IndexPath(indexes: [1])
        ip1[0..<1] = IndexPath(indexes: [2])
        XCTAssertEqual(ip1[0], 2)
        
        ip1[0..<1] = IndexPath(indexes: [])
        XCTAssertEqual(ip1.count, 0)
    }
    
    func testRangeReplacementPair() {
        var ip1 = IndexPath(indexes: [1, 2])
        ip1[0..<1] = IndexPath(indexes: [2, 3])
        XCTAssertEqual(ip1.count, 3)
        XCTAssertEqual(ip1[0], 2)
        XCTAssertEqual(ip1[1], 3)
        XCTAssertEqual(ip1[2], 2)
        
        ip1[0..<1] = IndexPath(indexes: [])
        XCTAssertEqual(ip1.count, 2)
    }
    
    func testMoreRanges() {
        var ip = IndexPath(indexes: [1, 2, 3])
        let ip2 = IndexPath(indexes: [5, 6, 7, 8, 9, 10])
        
        ip[1..<2] = ip2
        XCTAssertEqual(ip, IndexPath(indexes: [1, 5, 6, 7, 8, 9, 10, 3]))
    }
    
    func testIteration() {
        let ip = IndexPath(indexes: [1, 2, 3])
        
        var count = 0
        for _ in ip {
            count += 1
        }
        
        XCTAssertEqual(3, count)
    }
    
    func testDescription() {
        let ip1: IndexPath = []
        let ip2: IndexPath = [1]
        let ip3: IndexPath = [1, 2]
        let ip4: IndexPath = [1, 2, 3]
        
        XCTAssertEqual(ip1.description, "[]")
        XCTAssertEqual(ip2.description, "[1]")
        XCTAssertEqual(ip3.description, "[1, 2]")
        XCTAssertEqual(ip4.description, "[1, 2, 3]")
        
        XCTAssertEqual(ip1.debugDescription, ip1.description)
        XCTAssertEqual(ip2.debugDescription, ip2.description)
        XCTAssertEqual(ip3.debugDescription, ip3.description)
        XCTAssertEqual(ip4.debugDescription, ip4.description)
    }
    
    func testBridgeToObjC() {
        let ip1: IndexPath = []
        let ip2: IndexPath = [1]
        let ip3: IndexPath = [1, 2]
        let ip4: IndexPath = [1, 2, 3]
        
        let nsip1 = ip1._bridgeToObjectiveC()
        let nsip2 = ip2._bridgeToObjectiveC()
        let nsip3 = ip3._bridgeToObjectiveC()
        let nsip4 = ip4._bridgeToObjectiveC()
        
        XCTAssertEqual(nsip1.length, 0)
        XCTAssertEqual(nsip2.length, 1)
        XCTAssertEqual(nsip3.length, 2)
        XCTAssertEqual(nsip4.length, 3)
    }
    
    func testForceBridgeFromObjC() {
        let nsip1 = NSIndexPath()
        let nsip2 = NSIndexPath(index: 1)
        let nsip3 = [1, 2].withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<Int>) -> NSIndexPath in
            return NSIndexPath(indexes: buffer.baseAddress, length: buffer.count)
        }
        let nsip4 = [1, 2, 3].withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<Int>) -> NSIndexPath in
            return NSIndexPath(indexes: buffer.baseAddress, length: buffer.count)
        }
        
        var ip1: IndexPath?
        IndexPath._forceBridgeFromObjectiveC(nsip1, result: &ip1)
        XCTAssertNotNil(ip1)
        XCTAssertEqual(ip1!.count, 0)
        
        var ip2: IndexPath?
        IndexPath._forceBridgeFromObjectiveC(nsip2, result: &ip2)
        XCTAssertNotNil(ip2)
        XCTAssertEqual(ip2!.count, 1)
        XCTAssertEqual(ip2![0], 1)
        
        var ip3: IndexPath?
        IndexPath._forceBridgeFromObjectiveC(nsip3, result: &ip3)
        XCTAssertNotNil(ip3)
        XCTAssertEqual(ip3!.count, 2)
        XCTAssertEqual(ip3![0], 1)
        XCTAssertEqual(ip3![1], 2)
        
        var ip4: IndexPath?
        IndexPath._forceBridgeFromObjectiveC(nsip4, result: &ip4)
        XCTAssertNotNil(ip4)
        XCTAssertEqual(ip4!.count, 3)
        XCTAssertEqual(ip4![0], 1)
        XCTAssertEqual(ip4![1], 2)
        XCTAssertEqual(ip4![2], 3)
    }
    
    func testConditionalBridgeFromObjC() {
        let nsip1 = NSIndexPath()
        let nsip2 = NSIndexPath(index: 1)
        let nsip3 = [1, 2].withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<Int>) -> NSIndexPath in
            return NSIndexPath(indexes: buffer.baseAddress, length: buffer.count)
        }
        let nsip4 = [1, 2, 3].withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<Int>) -> NSIndexPath in
            return NSIndexPath(indexes: buffer.baseAddress, length: buffer.count)
        }
        
        var ip1: IndexPath?
        XCTAssertTrue(IndexPath._conditionallyBridgeFromObjectiveC(nsip1, result: &ip1))
        XCTAssertNotNil(ip1)
        XCTAssertEqual(ip1!.count, 0)
        
        var ip2: IndexPath?
        XCTAssertTrue(IndexPath._conditionallyBridgeFromObjectiveC(nsip2, result: &ip2))
        XCTAssertNotNil(ip2)
        XCTAssertEqual(ip2!.count, 1)
        XCTAssertEqual(ip2![0], 1)
        
        var ip3: IndexPath?
        XCTAssertTrue(IndexPath._conditionallyBridgeFromObjectiveC(nsip3, result: &ip3))
        XCTAssertNotNil(ip3)
        XCTAssertEqual(ip3!.count, 2)
        XCTAssertEqual(ip3![0], 1)
        XCTAssertEqual(ip3![1], 2)
        
        var ip4: IndexPath?
        XCTAssertTrue(IndexPath._conditionallyBridgeFromObjectiveC(nsip4, result: &ip4))
        XCTAssertNotNil(ip4)
        XCTAssertEqual(ip4!.count, 3)
        XCTAssertEqual(ip4![0], 1)
        XCTAssertEqual(ip4![1], 2)
        XCTAssertEqual(ip4![2], 3)
    }
    
    func testUnconditionalBridgeFromObjC() {
        let nsip1 = NSIndexPath()
        let nsip2 = NSIndexPath(index: 1)
        let nsip3 = [1, 2].withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<Int>) -> NSIndexPath in
            return NSIndexPath(indexes: buffer.baseAddress, length: buffer.count)
        }
        let nsip4 = [1, 2, 3].withUnsafeBufferPointer { (buffer: UnsafeBufferPointer<Int>) -> NSIndexPath in
            return NSIndexPath(indexes: buffer.baseAddress, length: buffer.count)
        }
        
        let ip1: IndexPath = IndexPath._unconditionallyBridgeFromObjectiveC(nsip1)
        XCTAssertEqual(ip1.count, 0)
        
        var ip2: IndexPath = IndexPath._unconditionallyBridgeFromObjectiveC(nsip2)
        XCTAssertEqual(ip2.count, 1)
        XCTAssertEqual(ip2[0], 1)
        
        var ip3: IndexPath = IndexPath._unconditionallyBridgeFromObjectiveC(nsip3)
        XCTAssertEqual(ip3.count, 2)
        XCTAssertEqual(ip3[0], 1)
        XCTAssertEqual(ip3[1], 2)
        
        var ip4: IndexPath = IndexPath._unconditionallyBridgeFromObjectiveC(nsip4)
        XCTAssertEqual(ip4.count, 3)
        XCTAssertEqual(ip4[0], 1)
        XCTAssertEqual(ip4[1], 2)
        XCTAssertEqual(ip4[2], 3)
    }
    
    func testObjcBridgeType() {
        XCTAssertTrue(IndexPath._getObjectiveCType() == NSIndexPath.self)
    }
    
    func test_AnyHashableContainingIndexPath() {
        let values: [IndexPath] = [
            IndexPath(indexes: [1, 2]),
            IndexPath(indexes: [1, 2, 3]),
            IndexPath(indexes: [1, 2, 3]),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssert(IndexPath.self == type(of: anyHashables[0].base))
        XCTAssert(IndexPath.self == type(of: anyHashables[1].base))
        XCTAssert(IndexPath.self == type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableCreatedFromNSIndexPath() {
        let values: [NSIndexPath] = [
            NSIndexPath(index: 1),
            NSIndexPath(index: 2),
            NSIndexPath(index: 2),
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssert(IndexPath.self == type(of: anyHashables[0].base))
        XCTAssert(IndexPath.self == type(of: anyHashables[1].base))
        XCTAssert(IndexPath.self == type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_unconditionallyBridgeFromObjectiveC() {
        XCTAssertEqual(IndexPath(), IndexPath._unconditionallyBridgeFromObjectiveC(nil))
    }
    
    func test_slice_1ary() {
        let indexPath: IndexPath = [0]
        let res = indexPath.dropFirst()
        XCTAssertEqual(0, res.count)
        
        let slice = indexPath[1..<1]
        XCTAssertEqual(0, slice.count)
    }

}
