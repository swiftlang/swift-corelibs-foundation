// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if !DARWIN_COMPATIBILITY_TESTS
struct IntSortable {
    var value: Int
}

struct StringSortable {
    var value: String
}

struct PlayerRecordSortable: Hashable {
    var name: String
    var victories: Int
    var tiebreakerPoints: Int
}

class TestNSSortDescriptor: XCTestCase {
    // Conceptually, requires a < firstCopyOfB, firstCopyOfB == secondCopyOfB, firstCopyOfB !== secondCopyOfB (if reference types)
    private func assertObjectsPass<Root, Value: Comparable>(_ a: Root, _ firstCopyOfB: Root, _ secondCopyOfB: Root, keyPath: KeyPath<Root, Value>) {
        do {
            let sort = NSSortDescriptor(keyPath: keyPath, ascending: true)
            XCTAssertEqual(sort.compare(a, to: firstCopyOfB), .orderedAscending)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: a), .orderedDescending)
            XCTAssertEqual(sort.compare(a, to: secondCopyOfB), .orderedAscending)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: a), .orderedDescending)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: secondCopyOfB), .orderedSame)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: firstCopyOfB), .orderedSame)
        }
        
        do {
            let sort = NSSortDescriptor(keyPath: keyPath, ascending: false)
            XCTAssertEqual(sort.compare(a, to: firstCopyOfB), .orderedDescending)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: a), .orderedAscending)
            XCTAssertEqual(sort.compare(a, to: secondCopyOfB), .orderedDescending)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: a), .orderedAscending)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: secondCopyOfB), .orderedSame)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: firstCopyOfB), .orderedSame)
        }
    }
    
    func assertObjectsPass<Root, BridgedRoot, BaseType, Value: Comparable>(_ a: Root, _ firstCopyOfB: Root, _ secondCopyOfB: Root, _ bridgedA: BridgedRoot, _ firstCopyOfBridgedB: BridgedRoot, _ secondCopyOfBridgedB: BridgedRoot, keyPath: KeyPath<BaseType, Value>) {
        do {
            let sort = NSSortDescriptor(keyPath: keyPath, ascending: true)
            XCTAssertEqual(sort.compare(bridgedA, to: firstCopyOfB), .orderedAscending)
            XCTAssertEqual(sort.compare(a, to: firstCopyOfBridgedB), .orderedAscending)
            XCTAssertEqual(sort.compare(firstCopyOfBridgedB, to: a), .orderedDescending)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: bridgedA), .orderedDescending)
            XCTAssertEqual(sort.compare(bridgedA, to: secondCopyOfB), .orderedAscending)
            XCTAssertEqual(sort.compare(a, to: secondCopyOfBridgedB), .orderedAscending)
            XCTAssertEqual(sort.compare(secondCopyOfBridgedB, to: a), .orderedDescending)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: bridgedA), .orderedDescending)
            XCTAssertEqual(sort.compare(firstCopyOfBridgedB, to: secondCopyOfB), .orderedSame)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: secondCopyOfBridgedB), .orderedSame)
            XCTAssertEqual(sort.compare(secondCopyOfBridgedB, to: firstCopyOfB), .orderedSame)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: firstCopyOfBridgedB), .orderedSame)
        }
        
        do {
            let sort = NSSortDescriptor(keyPath: keyPath, ascending: false)
            XCTAssertEqual(sort.compare(bridgedA, to: firstCopyOfB), .orderedDescending)
            XCTAssertEqual(sort.compare(a, to: firstCopyOfBridgedB), .orderedDescending)
            XCTAssertEqual(sort.compare(firstCopyOfBridgedB, to: a), .orderedAscending)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: bridgedA), .orderedAscending)
            XCTAssertEqual(sort.compare(bridgedA, to: secondCopyOfB), .orderedDescending)
            XCTAssertEqual(sort.compare(a, to: secondCopyOfBridgedB), .orderedDescending)
            XCTAssertEqual(sort.compare(secondCopyOfBridgedB, to: a), .orderedAscending)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: bridgedA), .orderedAscending)
            XCTAssertEqual(sort.compare(firstCopyOfBridgedB, to: secondCopyOfB), .orderedSame)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: secondCopyOfBridgedB), .orderedSame)
            XCTAssertEqual(sort.compare(secondCopyOfBridgedB, to: firstCopyOfB), .orderedSame)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: firstCopyOfBridgedB), .orderedSame)
        }
    }
    
    private func assertObjectsPass<Root, Value>(_ a: Root, _ firstCopyOfB: Root, _ secondCopyOfB: Root, keyPath: KeyPath<Root, Value>, comparator: @escaping Comparator) {
        do {
            let sort = NSSortDescriptor(keyPath: keyPath, ascending: true, comparator: comparator)
            XCTAssertEqual(sort.compare(a, to: firstCopyOfB), .orderedAscending)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: a), .orderedDescending)
            XCTAssertEqual(sort.compare(a, to: secondCopyOfB), .orderedAscending)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: a), .orderedDescending)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: secondCopyOfB), .orderedSame)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: firstCopyOfB), .orderedSame)
        }
        
        do {
            let sort = NSSortDescriptor(keyPath: keyPath, ascending: false, comparator: comparator)
            XCTAssertEqual(sort.compare(a, to: firstCopyOfB), .orderedDescending)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: a), .orderedAscending)
            XCTAssertEqual(sort.compare(a, to: secondCopyOfB), .orderedDescending)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: a), .orderedAscending)
            XCTAssertEqual(sort.compare(firstCopyOfB, to: secondCopyOfB), .orderedSame)
            XCTAssertEqual(sort.compare(secondCopyOfB, to: firstCopyOfB), .orderedSame)
        }
    }
    
    func testComparable() {
        let a = IntSortable(value: 42)
        let b = IntSortable(value: 108)
        let bAgain = IntSortable(value: 108)
        
        assertObjectsPass(a, b, bAgain, keyPath: \IntSortable.value)
    }
    
    func testBuiltinComparableObject() {
        let a = NSString(string: "A")
        let b = NSString(string: "B")
        let bAgain = NSString(string: "B")
        
        assertObjectsPass(a, b, bAgain, keyPath: \NSString.self)
    }
    
    func testBuiltinComparableBridgeable() {
        let a = NSString(string: "A")
        let b = NSString(string: "B")
        let bAgain = NSString(string: "B")
        
        let aString = "A"
        let bString = "B"
        let bStringAgain = "B"
        
        assertObjectsPass(a, b, bAgain, aString, bString, bStringAgain, keyPath: \NSString.self)
        assertObjectsPass(a, b, bAgain, aString, bString, bStringAgain, keyPath: \String.self)
    }
    
    func testComparatorSorting() {
        let canonicalOrder = [ "Velma", "Daphne", "Scooby" ]
        
        let a = StringSortable(value: "Velma")
        let b = StringSortable(value: "Daphne")
        let bAgain = StringSortable(value: "Daphne")
        
        assertObjectsPass(a, b, bAgain, keyPath: \StringSortable.value) { (lhs, rhs) -> ComparisonResult in
            let lhsIndex = canonicalOrder.firstIndex(of: lhs as! String)!
            let rhsIndex = canonicalOrder.firstIndex(of: rhs as! String)!
            
            if lhsIndex < rhsIndex {
                return .orderedAscending
            } else if lhsIndex > rhsIndex {
                return .orderedDescending
            } else {
                return .orderedSame
            }
        }
    }
    
    private let runOnlySinglePermutation = false // Useful for debugging. Always keep set to false when committing.
    
    func permute<T>(_ array: [T]) -> [[T]] {
        guard !runOnlySinglePermutation else {
            return [array]
        }
        
        guard !array.isEmpty else { return [[]] }

        var rest = array
        let head = rest.popLast()!
        let subpermutations = permute(rest)

        var result: [[T]] = []
        for permutation in subpermutations {
            for i in 0 ..< array.count {
                var edited = permutation
                edited.insert(head, at: i)
                result.append(edited)
            }
        }

        return result
    }
    
    func testSortingContainers() {
        let a = PlayerRecordSortable(name: "A", victories: 3, tiebreakerPoints: 0)
        let b = PlayerRecordSortable(name: "B", victories: 1, tiebreakerPoints: 10)
        let c = PlayerRecordSortable(name: "C", victories: 1, tiebreakerPoints: 10)
        let d = PlayerRecordSortable(name: "D", victories: 1, tiebreakerPoints: 15)
        
        func check(_ result: [Any]) {
            let actualResult = result as! [PlayerRecordSortable]
            
            XCTAssertEqual(actualResult[0].name, "A")
            XCTAssertEqual(actualResult[1].name, "D")
            if actualResult[2].name == "B" {
                XCTAssertEqual(actualResult[2].name, "B")
                XCTAssertEqual(actualResult[3].name, "C")
            } else {
                XCTAssertEqual(actualResult[2].name, "C")
                XCTAssertEqual(actualResult[3].name, "B")
            }
        }
        
        let descriptors = [
            NSSortDescriptor(keyPath: \PlayerRecordSortable.victories, ascending: false),
            NSSortDescriptor(keyPath: \PlayerRecordSortable.tiebreakerPoints, ascending: false),
        ]
        
        let permutations = permute([a, b, c, d])
        for permutation in permutations {
            
            check(NSArray(array: permutation).sortedArray(using: descriptors))
            
            let mutable = NSMutableArray(array: permutation)
            mutable.sort(using: descriptors)
            check(mutable as! [PlayerRecordSortable])
            
            let set = NSSet(array: permutation)
            check(set.sortedArray(using: descriptors))
            
            let orderedSet = NSOrderedSet(array: permutation)
            check(orderedSet.sortedArray(using: descriptors))
            
            let mutableOrderedSet = orderedSet.mutableCopy() as! NSMutableOrderedSet
            mutableOrderedSet.sort(using: descriptors)
            check(mutableOrderedSet.array)
            
        }
    }
    
    static var allTests: [(String, (TestNSSortDescriptor) -> () throws -> Void)] {
        return [
            ("testComparable", testComparable),
            ("testBuiltinComparableObject", testBuiltinComparableObject),
            ("testBuiltinComparableBridgeable", testBuiltinComparableBridgeable),
            ("testComparatorSorting", testComparatorSorting),
            ("testSortingContainers", testSortingContainers),
        ]
    }
}
#endif
