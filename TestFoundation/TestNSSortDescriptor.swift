// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
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

class TestNSSortDescriptor : XCTestCase {
    
    static var allTests: [(String, (TestNSSortDescriptor) -> () throws -> Void)] {
        return [
            ("test_copy", test_copy),
            ("test_reversed", test_reversed),
            ("test_evaluation", test_evaluation),
            ("test_sortedArrayFromNSSet", test_sortedArrayFromNSSet),
            ("test_sortedArrayFromNSArray", test_sortedArrayFromNSArray),
            ("test_sortNSMutableArray", test_sortNSMutableArray),
            
            // FIXME: Activate this test as soon as NSOrderedSet.sortedArray(options:usingComparator:) is implemented
//            ("test_sortedArrayFromNSOrderedSet", test_sortedArrayFromNSOrderedSet),
            ("test_sortNSMutableOrderedSet", test_sortNSMutableOrderedSet),
        ]
    }
    
    private let _nsnumberComparator = { (_ object1: Any, _ object2: Any) -> ComparisonResult in
        guard let value1 = object1 as? NSNumber, let value2 = object2 as? NSNumber else {
            return .orderedSame
        }
        return value1.compare(value2)
    }
    
    private let _nsstringComparator = { (_ object1: Any, _ object2: Any) -> ComparisonResult in
        guard let value1 = object1 as? NSString, let value2 = object2 as? NSString else {
            return .orderedSame
        }
        return value1.compare(String._unconditionallyBridgeFromObjectiveC(value2))
    }
    
    private class _ObjectToCompare : NSObject {
        
        let number: NSNumber
        let string: NSString
        
        init(_ number: Int, _ string: String) {
            self.number = NSNumber(value: number)
            self.string = NSString(string: string)
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? _ObjectToCompare else { return false }
            return number == other.number && string == other.string
        }
        
        static func numberComparator(_ object1: Any, _ object2: Any) -> ComparisonResult {
            guard let value1 = object1 as? _ObjectToCompare, let value2 = object2 as? _ObjectToCompare else {
                return .orderedSame
            }
            
            return value1.number.compare(value2.number)
        }
        
        static func stringComparator(_ object1: Any, _ object2: Any) -> ComparisonResult {
            guard let value1 = object1 as? _ObjectToCompare, let value2 = object2 as? _ObjectToCompare else {
                return .orderedSame
            }
            
            return value1.string.compare(String._unconditionallyBridgeFromObjectiveC(value2.string))
        }
        
        static let initialArrayToSort = [
            _ObjectToCompare(2, "c"),
            _ObjectToCompare(3, "b"),
            _ObjectToCompare(2, "b"),
            _ObjectToCompare(1, "a")
        ]
        
        static let expectedArrayNumbersAscendingThenStringsDescending = [
            _ObjectToCompare(1, "a"),
            _ObjectToCompare(2, "c"),
            _ObjectToCompare(2, "b"),
            _ObjectToCompare(3, "b")
        ]
        
        static let expectedArrayStringsAscendingThenNumbersDescending = [
            _ObjectToCompare(1, "a"),
            _ObjectToCompare(3, "b"),
            _ObjectToCompare(2, "b"),
            _ObjectToCompare(2, "c")
        ]
        
        static let descriptorsNumbersAscendingThenStringsDescending = [
            NSSortDescriptor(key: nil, ascending: true, comparator: numberComparator),
            NSSortDescriptor(key: nil, ascending: false, comparator: stringComparator)
        ]
        
        static let descriptorsStringsAscendingThenNumbersDescending = [
            NSSortDescriptor(key: nil, ascending: true, comparator: stringComparator),
            NSSortDescriptor(key: nil, ascending: false, comparator: numberComparator)
        ]
    }
    
    func test_copy() {
        
        let descriptor = NSSortDescriptor(key: nil, ascending: true, comparator: _nsnumberComparator)
        
        guard let copiedDescriptor = descriptor.copy() as? NSSortDescriptor else {
                XCTFail()
                return
        }
        
        XCTAssertTrue(descriptor === copiedDescriptor)
    }
    
    func test_reversed() {
        
        let descriptor1 = NSSortDescriptor(key: nil, ascending: true, comparator: _nsnumberComparator)
        let descriptor2 = NSSortDescriptor(key: nil, ascending: false, comparator: _nsnumberComparator)
        
        guard let reversedDescriptor1 = descriptor1.reversedSortDescriptor as? NSSortDescriptor,
            let reversedDescriptor2 = descriptor2.reversedSortDescriptor as? NSSortDescriptor else {
                XCTFail()
                return
        }
        
        XCTAssertEqual(descriptor1.ascending, !reversedDescriptor1.ascending)
        XCTAssertEqual(descriptor2.ascending, !reversedDescriptor2.ascending)
        XCTAssertEqual(descriptor1.key, reversedDescriptor1.key)
        XCTAssertEqual(descriptor2.key, reversedDescriptor2.key)
    }
    
    func test_evaluation() {
        
        let number1 = NSNumber(value: 1)
        let number2 = NSNumber(value: 2)
        let string1 = NSString(string: "Hello")
        let string2 = NSString(string: "World")
        let numberDescriptor = NSSortDescriptor(key: nil, ascending: true, comparator: _nsnumberComparator)
        let stringDescriptor = NSSortDescriptor(key: nil, ascending: false, comparator: _nsstringComparator)
        
        XCTAssertEqual(numberDescriptor.compare(number1, to: number2), .orderedAscending)
        XCTAssertEqual(numberDescriptor.comparator(number1, number2), .orderedAscending)
        
        XCTAssertEqual(stringDescriptor.compare(string1, to: string2), .orderedDescending)
        XCTAssertEqual(stringDescriptor.comparator(string1, string2), .orderedAscending)
        
        XCTAssertEqual(stringDescriptor.compare(number1, to: string2), .orderedSame)
        XCTAssertEqual( stringDescriptor.comparator(number1, string2), .orderedSame)
    }
    
    func test_sortedArrayFromNSSet() {
        
        let set = NSSet(array: _ObjectToCompare.initialArrayToSort)
        
        guard let returnedArray1 = set.sortedArray(using: _ObjectToCompare.descriptorsNumbersAscendingThenStringsDescending) as? [_ObjectToCompare],
            let returnedArray2 = set.sortedArray(using: _ObjectToCompare.descriptorsStringsAscendingThenNumbersDescending) as? [_ObjectToCompare] else {
                XCTFail()
                return
        }
        
        XCTAssertEqual(returnedArray1, _ObjectToCompare.expectedArrayNumbersAscendingThenStringsDescending)
        XCTAssertEqual(returnedArray2, _ObjectToCompare.expectedArrayStringsAscendingThenNumbersDescending)
    }
    
    func test_sortedArrayFromNSArray() {
        
        let array = NSArray(array: _ObjectToCompare.initialArrayToSort)
        
        guard let returnedArray1 = array.sortedArray(using: _ObjectToCompare.descriptorsNumbersAscendingThenStringsDescending) as? [_ObjectToCompare],
            let returnedArray2 = array.sortedArray(using: _ObjectToCompare.descriptorsStringsAscendingThenNumbersDescending) as? [_ObjectToCompare] else {
                XCTFail()
                return
        }
        
        XCTAssertEqual(returnedArray1, _ObjectToCompare.expectedArrayNumbersAscendingThenStringsDescending)
        XCTAssertEqual(returnedArray2, _ObjectToCompare.expectedArrayStringsAscendingThenNumbersDescending)
    }
    
    func test_sortNSMutableArray() {
        
        let mutableArray = NSMutableArray(array: _ObjectToCompare.initialArrayToSort)
        
        mutableArray.sort(using: _ObjectToCompare.descriptorsNumbersAscendingThenStringsDescending)
        
        guard let returnedArray1 = Array(mutableArray) as? [_ObjectToCompare] else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(returnedArray1, _ObjectToCompare.expectedArrayNumbersAscendingThenStringsDescending)
        
        mutableArray.sort(using: _ObjectToCompare.descriptorsStringsAscendingThenNumbersDescending)
        
        guard let returnedArray2 = Array(mutableArray) as? [_ObjectToCompare] else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(returnedArray2, _ObjectToCompare.expectedArrayStringsAscendingThenNumbersDescending)
    }
    
    func test_sortedArrayFromNSOrderedSet() {
        
        let orderedSet = NSOrderedSet(array: _ObjectToCompare.initialArrayToSort)
        
        guard let returnedArray1 = orderedSet.sortedArray(using: _ObjectToCompare.descriptorsNumbersAscendingThenStringsDescending) as? [_ObjectToCompare],
            let returnedArray2 = orderedSet.sortedArray(using: _ObjectToCompare.descriptorsStringsAscendingThenNumbersDescending) as? [_ObjectToCompare] else {
                XCTFail()
                return
        }
        
        XCTAssertEqual(returnedArray1, _ObjectToCompare.expectedArrayNumbersAscendingThenStringsDescending)
        XCTAssertEqual(returnedArray2, _ObjectToCompare.expectedArrayStringsAscendingThenNumbersDescending)
    }
    
    func test_sortNSMutableOrderedSet() {
        
        let mutableOrderedSet = NSMutableOrderedSet()
        mutableOrderedSet.addObjects(from: _ObjectToCompare.initialArrayToSort)
        
        mutableOrderedSet.sort(using: _ObjectToCompare.descriptorsNumbersAscendingThenStringsDescending)
        
        guard let returnedArray1 = Array(mutableOrderedSet) as? [_ObjectToCompare] else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(returnedArray1, _ObjectToCompare.expectedArrayNumbersAscendingThenStringsDescending)
        
        mutableOrderedSet.sort(using: _ObjectToCompare.descriptorsStringsAscendingThenNumbersDescending)

        guard let returnedArray2 = Array(mutableOrderedSet) as? [_ObjectToCompare] else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(returnedArray2, _ObjectToCompare.expectedArrayStringsAscendingThenNumbersDescending)
    }
}
