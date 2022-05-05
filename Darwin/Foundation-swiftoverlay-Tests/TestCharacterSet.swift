//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import XCTest

class TestCharacterSet : XCTestCase {
    let capitalA = UnicodeScalar(0x0041)! // LATIN CAPITAL LETTER A
    let capitalB = UnicodeScalar(0x0042)! // LATIN CAPITAL LETTER B
    let capitalC = UnicodeScalar(0x0043)! // LATIN CAPITAL LETTER C
    
    func testBasicConstruction() {
        // Create a character set
        let cs = CharacterSet.letters
        
        // Use some method from it
        let invertedCs = cs.inverted
        XCTAssertTrue(!invertedCs.contains(capitalA), "Character set must not contain our letter")
        
        // Use another method from it
        let originalCs = invertedCs.inverted
        
        XCTAssertTrue(originalCs.contains(capitalA), "Character set must contain our letter")
    }
    
    func testMutability_copyOnWrite() {
        var firstCharacterSet = CharacterSet(charactersIn: "ABC")
        XCTAssertTrue(firstCharacterSet.contains(capitalA), "Character set must contain our letter")
        XCTAssertTrue(firstCharacterSet.contains(capitalB), "Character set must contain our letter")
        XCTAssertTrue(firstCharacterSet.contains(capitalC), "Character set must contain our letter")
        
        // Make a 'copy' (just the struct)
        var secondCharacterSet = firstCharacterSet
        // first: ABC, second: ABC
        
        // Mutate first and verify that it has correct content
        firstCharacterSet.remove(charactersIn: "A")
        // first: BC, second: ABC
        
        XCTAssertTrue(!firstCharacterSet.contains(capitalA), "Character set must not contain our letter")
        XCTAssertTrue(secondCharacterSet.contains(capitalA), "Copy should not have been mutated")
        
        // Make a 'copy' (just the struct) of the second set, mutate it
        let thirdCharacterSet = secondCharacterSet
        // first: BC, second: ABC, third: ABC
        
        secondCharacterSet.remove(charactersIn: "B")
        // first: BC, second: AC, third: ABC
        
        XCTAssertTrue(firstCharacterSet.contains(capitalB), "Character set must contain our letter")
        XCTAssertTrue(!secondCharacterSet.contains(capitalB), "Character set must not contain our letter")
        XCTAssertTrue(thirdCharacterSet.contains(capitalB), "Character set must contain our letter")
        
        firstCharacterSet.remove(charactersIn: "C")
        // first: B, second: AC, third: ABC
        
        XCTAssertTrue(!firstCharacterSet.contains(capitalC), "Character set must not contain our letter")
        XCTAssertTrue(secondCharacterSet.contains(capitalC), "Character set must not contain our letter")
        XCTAssertTrue(thirdCharacterSet.contains(capitalC), "Character set must contain our letter")
    }

    func testMutability_mutableCopyCrash() {
        let cs = CharacterSet(charactersIn: "ABC")
        (cs as NSCharacterSet).mutableCopy() // this should not crash
    }
    
    func testMutability_SR_1782() {
        var nonAlphanumeric = CharacterSet.alphanumerics.inverted
        nonAlphanumeric.remove(charactersIn: " ") // this should not crash
    }

    func testRanges() {
        // Simple range check
        let asciiUppercase = CharacterSet(charactersIn: UnicodeScalar(0x41)!...UnicodeScalar(0x5A)!)
        XCTAssertTrue(asciiUppercase.contains(UnicodeScalar(0x49)!))
        XCTAssertTrue(asciiUppercase.contains(UnicodeScalar(0x5A)!))
        XCTAssertTrue(asciiUppercase.contains(UnicodeScalar(0x41)!))
        XCTAssertTrue(!asciiUppercase.contains(UnicodeScalar(0x5B)!))
        
        // Some string filtering tests
        let asciiLowercase = CharacterSet(charactersIn: UnicodeScalar(0x61)!...UnicodeScalar(0x7B)!)
        let testString = "helloHELLOhello"
        let expected = "HELLO"
        
        let result = testString.trimmingCharacters(in: asciiLowercase)
        XCTAssertEqual(result, expected)
    }

    func testClosedRanges_SR_2988() {
      // "CharacterSet.insert(charactersIn: ClosedRange) crashes on a closed ClosedRange<UnicodeScalar> containing U+D7FF"
      let problematicChar = UnicodeScalar(0xD7FF)!
      let range = capitalA...problematicChar
      var characters = CharacterSet(charactersIn: range) // this should not crash
      XCTAssertTrue(characters.contains(problematicChar))
      characters.remove(charactersIn: range) // this should not crash
      XCTAssertTrue(!characters.contains(problematicChar))
      characters.insert(charactersIn: range) // this should not crash
      XCTAssertTrue(characters.contains(problematicChar))
    }

    func testUpperBoundaryInsert_SR_2988() {
      // "CharacterSet.insert(_: Unicode.Scalar) crashes on U+D7FF"
      let problematicChar = UnicodeScalar(0xD7FF)!
      var characters = CharacterSet()
      characters.insert(problematicChar) // this should not crash
      XCTAssertTrue(characters.contains(problematicChar))
      characters.remove(problematicChar) // this should not crash
      XCTAssertTrue(!characters.contains(problematicChar))
    }

    func testInsertAndRemove() {
        var asciiUppercase = CharacterSet(charactersIn: UnicodeScalar(0x41)!...UnicodeScalar(0x5A)!)
        XCTAssertTrue(asciiUppercase.contains(UnicodeScalar(0x49)!))
        XCTAssertTrue(asciiUppercase.contains(UnicodeScalar(0x5A)!))
        XCTAssertTrue(asciiUppercase.contains(UnicodeScalar(0x41)!))
        
        asciiUppercase.remove(UnicodeScalar(0x49)!)
        XCTAssertTrue(!asciiUppercase.contains(UnicodeScalar(0x49)!))
        XCTAssertTrue(asciiUppercase.contains(UnicodeScalar(0x5A)!))
        XCTAssertTrue(asciiUppercase.contains(UnicodeScalar(0x41)!))
       

        // Zero-length range
        asciiUppercase.remove(charactersIn: UnicodeScalar(0x41)!..<UnicodeScalar(0x41)!)
        XCTAssertTrue(asciiUppercase.contains(UnicodeScalar(0x41)!))

        asciiUppercase.remove(charactersIn: UnicodeScalar(0x41)!..<UnicodeScalar(0x42)!)
        XCTAssertTrue(!asciiUppercase.contains(UnicodeScalar(0x41)!))
        
        asciiUppercase.remove(charactersIn: "Z")
        XCTAssertTrue(!asciiUppercase.contains(UnicodeScalar(0x5A)))
    }
    
    func testBasics() {
        
        var result : [String] = []
        
        let string = "The quick, brown, fox jumps over the lazy dog - because, why not?"
        var set = CharacterSet(charactersIn: ",-")
        result = string.components(separatedBy: set)
        XCTAssertEqual(5, result.count)
        
        set.remove(charactersIn: ",")
        set.insert(charactersIn: " ")
        result = string.components(separatedBy: set)
        XCTAssertEqual(14, result.count)
        
        set.remove(" ".unicodeScalars.first!)
        result = string.components(separatedBy: set)
        XCTAssertEqual(2, result.count)
    }

    // MARK: -
    func test_classForCoder() {
        // confirm internal bridged impl types are not exposed to archival machinery
        let cs = CharacterSet() as NSCharacterSet
        
        // Either of the following two are OK
        let expectedImmutable: AnyClass = NSCharacterSet.self as AnyClass
        let expectedMutable: AnyClass = NSMutableCharacterSet.self as AnyClass
        
        let actualClass: AnyClass = cs.classForCoder
        let actualClassForCoder: AnyClass = cs.classForKeyedArchiver!
        
        XCTAssertTrue(actualClass == expectedImmutable || actualClass == expectedMutable)
        XCTAssertTrue(actualClassForCoder == expectedImmutable || actualClassForCoder == expectedMutable)
    }

    func test_hashing() {
        let a = CharacterSet(charactersIn: "ABC")
        let b = CharacterSet(charactersIn: "CBA")
        let c = CharacterSet(charactersIn: "bad")
        let d = CharacterSet(charactersIn: "abd")
        let e = CharacterSet.capitalizedLetters
        let f = CharacterSet.lowercaseLetters
        checkHashableGroups(
            [[a, b], [c, d], [e], [f]],
            // FIXME: CharacterSet delegates equality and hashing to
            // CFCharacterSet, which uses unseeded hashing, so it's not
            // complete.
            allowIncompleteHashing: true)
    }

    func test_AnyHashableContainingCharacterSet() {
        let values: [CharacterSet] = [
            CharacterSet(charactersIn: "ABC"),
            CharacterSet(charactersIn: "XYZ"),
            CharacterSet(charactersIn: "XYZ")
        ]
        let anyHashables = values.map(AnyHashable.init)
        expectEqual(CharacterSet.self, type(of: anyHashables[0].base))
        expectEqual(CharacterSet.self, type(of: anyHashables[1].base))
        expectEqual(CharacterSet.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }

    func test_AnyHashableCreatedFromNSCharacterSet() {
        let values: [NSCharacterSet] = [
            NSCharacterSet(charactersIn: "ABC"),
            NSCharacterSet(charactersIn: "XYZ"),
            NSCharacterSet(charactersIn: "XYZ"),
        ]
        let anyHashables = values.map(AnyHashable.init)
        expectEqual(CharacterSet.self, type(of: anyHashables[0].base))
        expectEqual(CharacterSet.self, type(of: anyHashables[1].base))
        expectEqual(CharacterSet.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }

    func test_superSet() {
        let a = CharacterSet.letters.isSuperset(of: CharacterSet(charactersIn: "ab"))
        XCTAssertTrue(a)
    }

    func test_union() {
        let union = CharacterSet(charactersIn: "ab").union(CharacterSet(charactersIn: "cd"))
        let expected = CharacterSet(charactersIn: "abcd")
        XCTAssertEqual(expected, union)
    }

    func test_subtracting() {
        let difference = CharacterSet(charactersIn: "abc").subtracting(CharacterSet(charactersIn: "b"))
        let expected = CharacterSet(charactersIn: "ac")
        XCTAssertEqual(expected, difference)
    }

    func test_subtractEmptySet() {
        var mutableSet = CharacterSet(charactersIn: "abc")
        let emptySet = CharacterSet()
        mutableSet.subtract(emptySet)
        let expected = CharacterSet(charactersIn: "abc")
        XCTAssertEqual(expected, mutableSet)
    }

    func test_subtractNonEmptySet() {
        var mutableSet = CharacterSet()
        let nonEmptySet = CharacterSet(charactersIn: "abc")
        mutableSet.subtract(nonEmptySet)
        XCTAssertTrue(mutableSet.isEmpty)
    }

    func test_symmetricDifference() {
        let symmetricDifference = CharacterSet(charactersIn: "ac").symmetricDifference(CharacterSet(charactersIn: "b"))
        let expected = CharacterSet(charactersIn: "abc")
        XCTAssertEqual(expected, symmetricDifference)
    }

    func test_hasMember() {
        let contains = CharacterSet.letters.hasMember(inPlane: 1)
        XCTAssertTrue(contains)
    }

    func test_bitmap() {
        let bitmap = CharacterSet(charactersIn: "ab").bitmapRepresentation
        XCTAssertEqual(0x6, bitmap[12])
        XCTAssertEqual(8192, bitmap.count)
    }
    
    func test_setOperationsOfEmptySet() {
        // The following tests pass on these versions of the OS
        if #available(OSX 10.12.3, iOS 10.3, watchOS 3.2, tvOS 10.2, *) {
            let emptySet = CharacterSet()
            let abcSet = CharacterSet(charactersIn: "abc")
            
            XCTAssertTrue(abcSet.isSuperset(of: emptySet))
            XCTAssertTrue(emptySet.isSuperset(of: emptySet))
            XCTAssertFalse(emptySet.isSuperset(of: abcSet))
            
            XCTAssertTrue(abcSet.isStrictSuperset(of: emptySet))
            XCTAssertFalse(emptySet.isStrictSuperset(of: emptySet))
            XCTAssertFalse(emptySet.isStrictSuperset(of: abcSet))
            
            XCTAssertTrue(emptySet.isSubset(of: abcSet))
            XCTAssertTrue(emptySet.isSubset(of: emptySet))
            XCTAssertFalse(abcSet.isSubset(of: emptySet))
            
            XCTAssertTrue(emptySet.isStrictSubset(of: abcSet))
            XCTAssertFalse(emptySet.isStrictSubset(of: emptySet))
            XCTAssertFalse(abcSet.isStrictSubset(of: emptySet))
            XCTAssertFalse(abcSet.isStrictSubset(of: abcSet))
            
            XCTAssertEqual(emptySet, emptySet)
            XCTAssertNotEqual(abcSet, emptySet)
        }
    }
    
    func test_moreSetOperations() {
        // previous to these releases the subset methods improperly calculated strict subsets
        // as of macOS 10.12.4, iOS 10.3, watchOS 3.2 and tvOS 10.2 CoreFoundation had a bug
        // fix that corrected this behavior.
        // TODO: figure out why the simulator is claiming this as a failure.
        // https://bugs.swift.org/browse/SR-4457

        /*  Disabled now: rdar://problem/31746923
        #if os(macOS)
            if #available(OSX 10.12.4, iOS 10.3, watchOS 3.2, tvOS 10.2, *) {
                let abcSet = CharacterSet(charactersIn: "abc")
                let abcdSet = CharacterSet(charactersIn: "abcd")
                
                XCTAssertEqual(abcSet, abcSet)
                XCTAssertNotEqual(abcSet, abcdSet)
                
                XCTAssertTrue(abcSet.isStrictSubset(of:abcdSet))
                XCTAssertFalse(abcdSet.isStrictSubset(of:abcSet))
                XCTAssertTrue(abcdSet.isStrictSuperset(of:abcSet))
                XCTAssertFalse(abcSet.isStrictSuperset(of:abcdSet))
            }
        #endif
        */
    }

    func test_unconditionallyBridgeFromObjectiveC() {
        XCTAssertEqual(CharacterSet(), CharacterSet._unconditionallyBridgeFromObjectiveC(nil))
    }
}

