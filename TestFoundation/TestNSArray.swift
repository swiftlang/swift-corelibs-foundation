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



class TestNSArray : XCTestCase {
    
    static var allTests: [(String, TestNSArray -> () throws -> Void)] {
        return [
            ("test_BasicConstruction", test_BasicConstruction),
            ("test_enumeration", test_enumeration),
            ("test_sequenceType", test_sequenceType),
            ("test_getObjects", test_getObjects),
            ("test_objectAtIndex", test_objectAtIndex),
            ("test_binarySearch", test_binarySearch),
            ("test_binarySearchFringeCases", test_binarySearchFringeCases),
            ("test_replaceObjectsInRange_withObjectsFromArray", test_replaceObjectsInRange_withObjectsFromArray),
            ("test_replaceObjectsInRange_withObjectsFromArray_range", test_replaceObjectsInRange_withObjectsFromArray_range),
            ("test_replaceObjectAtIndex", test_replaceObjectAtIndex),
            ("test_removeObjectsInArray", test_removeObjectsInArray),
            ("test_sortedArrayUsingComparator", test_sortedArrayUsingComparator),
            ("test_sortedArrayWithOptionsUsingComparator", test_sortedArrayWithOptionsUsingComparator),
            ("test_arrayReplacement", test_arrayReplacement),
            ("test_arrayReplaceObjectsInRangeFromRange", test_arrayReplaceObjectsInRangeFromRange),
            ("test_sortUsingFunction", test_sortUsingFunction),
            ("test_sortUsingComparator", test_sortUsingComparator),
            ("test_equality", test_equality),
            ("test_copying", test_copying),
            ("test_mutableCopying", test_mutableCopying),
        ]
    }
    
    func test_BasicConstruction() {
        let array = NSArray()
        let array2 : NSArray = ["foo", "bar"] as NSArray
        XCTAssertEqual(array.count, 0)
        XCTAssertEqual(array2.count, 2)
    }
    
    func test_enumeration() {
        let array : NSArray = ["foo", "bar", "baz"] as NSArray
        let e = array.objectEnumerator()
        XCTAssertEqual((e.nextObject() as! NSString) as String, "foo")
        XCTAssertEqual((e.nextObject() as! NSString) as String, "bar")
        XCTAssertEqual((e.nextObject() as! NSString) as String, "baz")
        XCTAssertNil(e.nextObject())
        XCTAssertNil(e.nextObject())
        
        let r = array.reverseObjectEnumerator()
        XCTAssertEqual((r.nextObject() as! NSString) as String, "baz")
        XCTAssertEqual((r.nextObject() as! NSString) as String, "bar")
        XCTAssertEqual((r.nextObject() as! NSString) as String, "foo")
        XCTAssertNil(r.nextObject())
        XCTAssertNil(r.nextObject())
        
        let empty = NSArray().objectEnumerator()
        XCTAssertNil(empty.nextObject())
        XCTAssertNil(empty.nextObject())
        
        let reverseEmpty = NSArray().reverseObjectEnumerator()
        XCTAssertNil(reverseEmpty.nextObject())
        XCTAssertNil(reverseEmpty.nextObject())
    }
    
    func test_sequenceType() {
        let array : NSArray = ["foo", "bar", "baz"] as NSArray
        var res = [String]()
        for obj in array {
            res.append((obj as! NSString) as String)
        }
        XCTAssertEqual(res, ["foo", "bar", "baz"])
    }

    func test_getObjects() {
        let array : NSArray = ["foo", "bar", "baz", "foo1", "bar2", "baz3",] as NSArray
        var objects = [AnyObject]()
        array.getObjects(&objects, range: NSMakeRange(1, 3))
        XCTAssertEqual(objects.count, 3)
        let fetched = [
            (objects[0] as! NSString) as String,
            (objects[1] as! NSString) as String,
            (objects[2] as! NSString) as String,
        ]
        XCTAssertEqual(fetched, ["bar", "baz", "foo1"])
    }
    
    func test_objectAtIndex() {
        let array : NSArray = ["foo", "bar"] as NSArray
        let foo = array.objectAtIndex(0) as! NSString
        XCTAssertEqual(foo, "foo" as NSString)
        
        let bar = array.objectAtIndex(1) as! NSString
        XCTAssertEqual(bar, "bar" as NSString)
    }

    func test_binarySearch() {
        let array = NSArray(array: [
            NSNumber(int: 0), NSNumber(int: 1), NSNumber(int: 2), NSNumber(int: 2), NSNumber(int: 3),
            NSNumber(int: 4), NSNumber(int: 4), NSNumber(int: 6), NSNumber(int: 7), NSNumber(int: 7),
            NSNumber(int: 7), NSNumber(int: 8), NSNumber(int: 9), NSNumber(int: 9)])
        
        // Not sure how to test fatal errors.
        
//        NSArray throws NSInvalidArgument if range exceeds bounds of the array.
//        let rangeOutOfArray = NSRange(location: 5, length: 15)
//        let _ = array.indexOfObject(NSNumber(integer: 9), inSortedRange: rangeOutOfArray, options: [.InsertionIndex, .FirstEqual], usingComparator: compareIntNSNumber)
        
//        NSArray throws NSInvalidArgument if both .FirstEqual and .LastEqaul are specified
//        let searchForBoth: NSBinarySearchingOptions = [.FirstEqual, .LastEqual]
//        let _ = objectIndexInArray(array, value: 9, startingFrom: 0, length: 13, options: searchForBoth)

        let notFound = objectIndexInArray(array, value: 11, startingFrom: 0, length: 13)
        XCTAssertEqual(notFound, NSNotFound, "NSArray return NSNotFound if object is not found.")
        
        let notFoundInRange = objectIndexInArray(array, value: 7, startingFrom: 0, length: 5)
        XCTAssertEqual(notFoundInRange, NSNotFound, "NSArray return NSNotFound if object is not found.")
        
        let indexOfAnySeven = objectIndexInArray(array, value: 7, startingFrom: 0, length: 13)
        XCTAssertTrue(Set([8, 9, 10]).contains(indexOfAnySeven), "If no options provided NSArray returns an arbitrary matching object's index.")
        
        let indexOfFirstNine = objectIndexInArray(array, value: 9, startingFrom: 7, length: 6, options: [.FirstEqual])
        XCTAssertTrue(indexOfFirstNine == 12, "If .FirstEqual is set NSArray returns the lowest index of equal objects.")
        
        let indexOfLastTwo = objectIndexInArray(array, value: 2, startingFrom: 1, length: 7, options: [.LastEqual])
        XCTAssertTrue(indexOfLastTwo == 3, "If .LastEqual is set NSArray returns the highest index of equal objects.")
        
        let anyIndexToInsertNine = objectIndexInArray(array, value: 9, startingFrom: 0, length: 13, options: [.InsertionIndex])
        XCTAssertTrue(Set([12, 13, 14]).contains(anyIndexToInsertNine), "If .InsertionIndex is specified and no other options provided NSArray returns any equal or one larger index than any matching object’s index.")
        
        let lowestIndexToInsertTwo = objectIndexInArray(array, value: 2, startingFrom: 0, length: 5, options: [.InsertionIndex, .FirstEqual])
        XCTAssertTrue(lowestIndexToInsertTwo == 2, "If both .InsertionIndex and .FirstEqual are specified NSArray returns the lowest index of equal objects.")
        
        let highestIndexToInsertNine = objectIndexInArray(array, value: 9, startingFrom: 7, length: 6, options: [.InsertionIndex, .LastEqual])
        XCTAssertTrue(highestIndexToInsertNine == 13, "If both .InsertionIndex and .LastEqual are specified NSArray returns the index of the least greater object...")
        
        let indexOfLeastGreaterObjectThanFive = objectIndexInArray(array, value: 5, startingFrom: 0, length: 10, options: [.InsertionIndex, .LastEqual])
        XCTAssertTrue(indexOfLeastGreaterObjectThanFive == 7, "If both .InsertionIndex and .LastEqual are specified NSArray returns the index of the least greater object...")
        
        let rangeStart = 0
        let rangeLength = 13
        let endOfArray = objectIndexInArray(array, value: 10, startingFrom: rangeStart, length: rangeLength, options: [.InsertionIndex, .LastEqual])
        XCTAssertTrue(endOfArray == (rangeStart + rangeLength), "...or the index at the end of the array if the object is larger than all other elements.")
        
        let arrayOfTwo = NSArray(array: [NSNumber(int: 0), NSNumber(int: 2)])
        let indexInMiddle = objectIndexInArray(arrayOfTwo, value: 1, startingFrom: 0, length: 2, options: [.InsertionIndex, .FirstEqual])
        XCTAssertEqual(indexInMiddle, 1, "If no match found item should be inserted before least greater object")
        let indexInMiddle2 = objectIndexInArray(arrayOfTwo, value: 1, startingFrom: 0, length: 2, options: [.InsertionIndex, .LastEqual])
        XCTAssertEqual(indexInMiddle2, 1, "If no match found item should be inserted before least greater object")
        let indexInMiddle3 = objectIndexInArray(arrayOfTwo, value: 1, startingFrom: 0, length: 2, options: [.InsertionIndex])
        XCTAssertEqual(indexInMiddle3, 1, "If no match found item should be inserted before least greater object")
    }


    func test_arrayReplacement() {
        let array = NSMutableArray(array: [
                               NSNumber(int: 0), NSNumber(int: 1), NSNumber(int: 2), NSNumber(int: 3),
                               NSNumber(int: 4), NSNumber(int: 5), NSNumber(int: 7)])
        array.replaceObjectsInRange(NSRange(location: 0, length: 2), withObjectsFromArray: [NSNumber(int: 8), NSNumber(int: 9)])
        XCTAssertTrue((array[0] as! NSNumber).integerValue == 8)
        XCTAssertTrue((array[1] as! NSNumber).integerValue == 9)
        XCTAssertTrue((array[2] as! NSNumber).integerValue == 2)
    }

    func test_arrayReplaceObjectsInRangeFromRange() {
        let array = NSMutableArray(array: [
                                      NSNumber(int: 0), NSNumber(int: 1), NSNumber(int: 2), NSNumber(int: 3),
                                      NSNumber(int: 4), NSNumber(int: 5), NSNumber(int: 7)])
        array.replaceObjectsInRange(NSRange(location: 0, length: 2), withObjectsFromArray: [NSNumber(int: 8), NSNumber(int: 9), NSNumber(int: 10)], range: NSRange(location: 1, length: 2))
        XCTAssertTrue((array[0] as! NSNumber).integerValue == 9)
        XCTAssertTrue((array[1] as! NSNumber).integerValue == 10)
        XCTAssertTrue((array[2] as! NSNumber).integerValue == 2)
    }

    func test_replaceObjectAtIndex() {
        let array = NSMutableArray(array: [
            NSNumber(int: 0), NSNumber(int: 1), NSNumber(int: 2), NSNumber(int: 3),
            NSNumber(int: 4), NSNumber(int: 5), NSNumber(int: 7)])

        // 1. Check replacement in the middle of the array
        array.replaceObjectAtIndex(3, withObject: NSNumber(int: 8))
        XCTAssertEqual(array.count, 7)
        XCTAssertEqual((array[3] as! NSNumber).integerValue, 8)

        // 2. Check replacement of the first element
        array.replaceObjectAtIndex(0, withObject: NSNumber(int: 7))
        XCTAssertEqual(array.count, 7)
        XCTAssertEqual((array[0] as! NSNumber).integerValue, 7)

        // 3. Check replacement of the last element
        array.replaceObjectAtIndex(6, withObject: NSNumber(int: 6))
        XCTAssertEqual(array.count, 7)
        XCTAssertEqual((array[6] as! NSNumber).integerValue, 6)
    }

    func test_removeObjectsInArray() {
        let array = NSMutableArray(array: [
            NSNumber(int: 0), NSNumber(int: 1), NSNumber(int: 2), NSNumber(int: 3),
            NSNumber(int: 4), NSNumber(int: 5), NSNumber(int: 7)])
        let objectsToRemove: Array<AnyObject> = [
            NSNumber(int: 1), NSNumber(int: 22), NSNumber(int: 7), NSNumber(int: 5)]
        array.removeObjectsInArray(objectsToRemove)
        XCTAssertEqual(array.count, 4)
        XCTAssertEqual((array[0] as! NSNumber).integerValue, 0)
        XCTAssertEqual((array[1] as! NSNumber).integerValue, 2)
        XCTAssertEqual((array[2] as! NSNumber).integerValue, 3)
        XCTAssertEqual((array[3] as! NSNumber).integerValue, 4)
    }

    func test_binarySearchFringeCases() {
        let array = NSArray(array: [
            NSNumber(int: 0), NSNumber(int: 1), NSNumber(int: 2), NSNumber(int: 2), NSNumber(int: 3),
            NSNumber(int: 4), NSNumber(int: 4), NSNumber(int: 6), NSNumber(int: 7), NSNumber(int: 7),
            NSNumber(int: 7), NSNumber(int: 8), NSNumber(int: 9), NSNumber(int: 9)])
        
        let emptyArray = NSArray()
//        Same as for non empty NSArray but error message ends with 'bounds for empty array'.
//        let _ = objectIndexInArray(emptyArray, value: 0, startingFrom: 0, length: 1)
        
        let notFoundInEmptyArray = objectIndexInArray(emptyArray, value: 9, startingFrom: 0, length: 0)
        XCTAssertEqual(notFoundInEmptyArray, NSNotFound, "Empty NSArray return NSNotFound for any valid arguments.")
        
        let startIndex = objectIndexInArray(emptyArray, value: 7, startingFrom: 0, length: 0, options: [.InsertionIndex])
        XCTAssertTrue(startIndex == 0, "For Empty NSArray any objects should be inserted at start.")
        
        let rangeStart = 0
        let rangeLength = 13
        
        let leastSearch = objectIndexInArray(array, value: -1, startingFrom: rangeStart, length: rangeLength)
        XCTAssertTrue(leastSearch == NSNotFound, "If object is less than least object in the range then there is no change it could be found.")
        
        let greatestSearch = objectIndexInArray(array, value: 15, startingFrom: rangeStart, length: rangeLength)
        XCTAssertTrue(greatestSearch == NSNotFound, "If object is greater than greatest object in the range then there is no change it could be found.")
        
        let leastInsert = objectIndexInArray(array, value: -1, startingFrom: rangeStart, length: rangeLength, options: .InsertionIndex)
        XCTAssertTrue(leastInsert == rangeStart, "If object is less than least object in the range it should be inserted at range' location.")
        
        let greatestInsert = objectIndexInArray(array, value: 15, startingFrom: rangeStart, length: rangeLength, options: .InsertionIndex)
        XCTAssertTrue(greatestInsert == (rangeStart + rangeLength), "If object is greater than greatest object in the range it should be inserted at range' end.")
    }
    
    func objectIndexInArray(_ array: NSArray, value: Int, startingFrom: Int, length: Int, options: NSBinarySearchingOptions = []) -> Int {
        return array.indexOfObject(NSNumber(integer: value), inSortedRange: NSRange(location: startingFrom, length: length), options: options, usingComparator: compareIntNSNumber)
    }
    
    func compareIntNSNumber(_ lhs: AnyObject, rhs: AnyObject) -> NSComparisonResult {
        let lhsInt = (lhs as! NSNumber).integerValue
        let rhsInt = (rhs as! NSNumber).integerValue
        if lhsInt == rhsInt {
            return .OrderedSame
        }
        if lhsInt < rhsInt {
            return .OrderedAscending
        }
        
        return .OrderedDescending
    }
    
    func test_replaceObjectsInRange_withObjectsFromArray() {
        let array1 = NSMutableArray(array:[
            "foo1" as NSString,
            "bar1" as NSString,
            "baz1" as NSString])
        
        let array2: [AnyObject] = [
            "foo2" as NSString,
            "bar2" as NSString,
            "baz2" as NSString]
        
        array1.replaceObjectsInRange(NSMakeRange(0, 2), withObjectsFromArray: array2)
        
        XCTAssertEqual(array1[0] as? NSString, "foo2" as NSString, "Expected foo2 but was \(array1[0])")
        XCTAssertEqual(array1[1] as? NSString, "bar2" as NSString, "Expected bar2 but was \(array1[1])")
        XCTAssertEqual(array1[2] as? NSString, "baz2" as NSString, "Expected baz2 but was \(array1[2])")
        XCTAssertEqual(array1[3] as? NSString, "baz1" as NSString, "Expected baz1 but was \(array1[3])")
    }
    
    func test_replaceObjectsInRange_withObjectsFromArray_range() {
        let array1 = NSMutableArray(array:[
            "foo1" as NSString,
            "bar1" as NSString,
            "baz1" as NSString])
        
        let array2: [AnyObject] = [
            "foo2" as NSString,
            "bar2" as NSString,
            "baz2" as NSString]
        
        array1.replaceObjectsInRange(NSMakeRange(1, 1), withObjectsFromArray: array2, range: NSMakeRange(1, 2))
        
        XCTAssertEqual(array1[0] as? NSString, "foo1" as NSString, "Expected foo1 but was \(array1[0])")
        XCTAssertEqual(array1[1] as? NSString, "bar2" as NSString, "Expected bar2 but was \(array1[1])")
        XCTAssertEqual(array1[2] as? NSString, "baz2" as NSString, "Expected baz2 but was \(array1[2])")
        XCTAssertEqual(array1[3] as? NSString, "baz1" as NSString, "Expected baz1 but was \(array1[3])")
    }

    func test_sortedArrayUsingComparator() {
        // sort with localized caseInsensitive compare
        let input = ["this", "is", "a", "test", "of", "sort", "with", "strings"]
        let expectedResult: Array<String> = input.sorted()
        let result = (input as NSArray).sortedArrayUsingComparator { left, right -> NSComparisonResult in
            let l = left as! NSString
            let r = right as! NSString
            return l.localizedCaseInsensitiveCompare(r as String)
        }
        XCTAssertEqual(result.map { ($0 as! NSString) as String} , expectedResult)

        // sort empty array
        let emptyArray = NSArray().sortedArrayUsingComparator { _,_ in .OrderedSame }
        XCTAssertTrue(emptyArray.isEmpty)

        // sort numbers
        let inputNumbers = [0, 10, 25, 100, 21, 22]
        let expectedNumbers = inputNumbers.sorted()
        let resultNumbers = (inputNumbers as NSArray).sortedArrayUsingComparator { left, right -> NSComparisonResult in
            let l = (left as! NSNumber).integerValue
            let r = (right as! NSNumber).integerValue
            return l < r ? .OrderedAscending : (l > r ? .OrderedSame : .OrderedDescending)
        }
        XCTAssertEqual(resultNumbers.map { ($0 as! NSNumber).integerValue}, expectedNumbers)
    }

    func test_sortedArrayWithOptionsUsingComparator() {
        // check that sortedArrayWithOptions:comparator: works in the way sortedArrayUsingComparator does
        let input = ["this", "is", "a", "test", "of", "sort", "with", "strings"] as NSArray
        let comparator: (AnyObject, AnyObject) -> NSComparisonResult = { left, right -> NSComparisonResult in
            let l = left as! NSString
            let r = right as! NSString
            return l.localizedCaseInsensitiveCompare(r as String)
        }
        let result1 = input.sortedArrayUsingComparator(comparator)
        let result2 = input.sortedArrayWithOptions([], usingComparator: comparator)

        XCTAssertTrue((result1 as NSArray).isEqualToArray(result2))

        // sort empty array
        let emptyArray = NSArray().sortedArrayWithOptions([]) { _,_ in .OrderedSame }
        XCTAssertTrue(emptyArray.isEmpty)
    }

    func test_sortUsingFunction() {
        let inputNumbers = [11, 120, 215, 11, 1, -22, 35, -89, 65]
        let mutableInput = (inputNumbers as NSArray).mutableCopy() as! NSMutableArray
        let expectedNumbers = inputNumbers.sorted()

        func compare(_ left: AnyObject, right:AnyObject,  context: UnsafeMutablePointer<Void>?) -> Int {
            let l = (left as! NSNumber).integerValue
            let r = (right as! NSNumber).integerValue
            return l < r ? -1 : (l > r ? 0 : 1)
        }
        mutableInput.sortUsingFunction(compare, context: UnsafeMutablePointer<Void>(bitPattern: 0))

        XCTAssertEqual(mutableInput.map { ($0 as! NSNumber).integerValue}, expectedNumbers)
    }

    func test_sortUsingComparator() {
        // check behaviour with Array's sort method
        let inputNumbers = [11, 120, 215, 11, 1, -22, 35, -89, 65]
        let mutableInput = (inputNumbers as NSArray).mutableCopy() as! NSMutableArray
        let expectedNumbers = inputNumbers.sorted()

        mutableInput.sortUsingComparator { left, right -> NSComparisonResult in
            let l = (left as! NSNumber).integerValue
            let r = (right as! NSNumber).integerValue
            return l < r ? .OrderedAscending : (l > r ? .OrderedSame : .OrderedDescending)
        }

        XCTAssertEqual(mutableInput.map { ($0 as! NSNumber).integerValue}, expectedNumbers)

        // check that it works in the way self.sortWithOptions([], usingComparator: cmptr) does
        let inputStrings = ["this", "is", "a", "test", "of", "sort", "with", "strings"]
        let mutableStringsInput1 = (inputStrings as NSArray).mutableCopy() as! NSMutableArray
        let mutableStringsInput2 = (inputStrings as NSArray).mutableCopy() as! NSMutableArray
        let comparator: (AnyObject, AnyObject) -> NSComparisonResult = { left, right -> NSComparisonResult in
            let l = left as! NSString
            let r = right as! NSString
            return l.localizedCaseInsensitiveCompare(r as String)
        }
        mutableStringsInput1.sortUsingComparator(comparator)
        mutableStringsInput2.sortWithOptions([], usingComparator: comparator)
        XCTAssertTrue(mutableStringsInput1.isEqualToArray(mutableStringsInput2 as Array))
    }

    func test_equality() {
        let array1 = ["this", "is", "a", "test", "of", "equal", "with", "strings"] as NSArray
        let array2 = ["this", "is", "a", "test", "of", "equal", "with", "strings"] as NSArray
        let array3 = ["this", "is", "a", "test", "of", "equal", "with", "objects"] as NSArray

        XCTAssertTrue(array1 == array2)
        XCTAssertTrue(array1.isEqual(array2))
        XCTAssertTrue(array1.isEqualToArray(array2 as Array))
        // if 2 arrays are equal, hashes should be equal as well. But not vise versa
        XCTAssertEqual(array1.hash, array2.hash)
        XCTAssertEqual(array1.hashValue, array2.hashValue)

        XCTAssertFalse(array1 == array3)
        XCTAssertFalse(array1.isEqual(array3))
        XCTAssertFalse(array1.isEqualToArray(array3 as Array))

        XCTAssertFalse(array1.isEqual(nil))
        XCTAssertFalse(array1.isEqual(NSObject()))
    }

    func test_copying() {
        let array = ["this", "is", "a", "test", "of", "copy", "with", "strings"] as NSArray

        let arrayCopy1 = array.copy() as! NSArray
        XCTAssertTrue(array === arrayCopy1)

        let arrayMutableCopy = array.mutableCopy() as! NSMutableArray
        let arrayCopy2 = arrayMutableCopy.copy() as! NSArray
        XCTAssertTrue(arrayCopy2.dynamicType === NSArray.self)
        XCTAssertFalse(arrayMutableCopy === arrayCopy2)
        for entry in arrayCopy2 {
            XCTAssertTrue(array.indexOfObjectIdenticalTo(entry) != NSNotFound)
        }

    }

    func test_mutableCopying() {
        let array = ["this", "is", "a", "test", "of", "mutableCopy", "with", "strings"] as NSArray

        let arrayMutableCopy1 = array.mutableCopy() as! NSMutableArray
        XCTAssertTrue(arrayMutableCopy1.dynamicType === NSMutableArray.self)
        XCTAssertFalse(array === arrayMutableCopy1)
        for entry in arrayMutableCopy1 {
            XCTAssertTrue(array.indexOfObjectIdenticalTo(entry) != NSNotFound)
        }

        let arrayMutableCopy2 = arrayMutableCopy1.mutableCopy() as! NSMutableArray
        XCTAssertTrue(arrayMutableCopy2.dynamicType === NSMutableArray.self)
        XCTAssertFalse(arrayMutableCopy2 === arrayMutableCopy1)
        for entry in arrayMutableCopy2 {
            XCTAssertTrue(arrayMutableCopy1.indexOfObjectIdenticalTo(entry) != NSNotFound)
        }
    }

}
