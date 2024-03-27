// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSRange : XCTestCase {
    
    static var allTests: [(String, (TestNSRange) -> () throws -> Void)] {
        return [
            ("test_NSRangeFromString", test_NSRangeFromString ),
            ("test_NSRangeBridging", test_NSRangeBridging),
            ("test_NSMaxRange", test_NSMaxRange),
            ("test_NSLocationInRange", test_NSLocationInRange),
            ("test_NSEqualRanges", test_NSEqualRanges),
            ("test_NSUnionRange", test_NSUnionRange),
            ("test_NSIntersectionRange", test_NSIntersectionRange),
            ("test_NSStringFromRange", test_NSStringFromRange),
            ("test_init_region_in_ascii_string", test_init_region_in_ascii_string),
            ("test_init_region_in_unicode_string", test_init_region_in_unicode_string),
            ("test_hashing", test_hashing),
        ]
    }

    func test_NSRangeFromString() {
        let emptyRangeStrings = [
            "",
            "{}",
            "{a, b}",
        ]
        let emptyRange = NSRange(location: 0, length: 0)
        for string in emptyRangeStrings {
            XCTAssert(NSEqualRanges(NSRangeFromString(string), emptyRange))
        }

        let partialRangeStrings = [
            "12",
            "[12]",
            "{12",
            "{12,",
        ]
        let partialRange = NSRange(location: 12, length: 0)
        for string in partialRangeStrings {
            XCTAssert(NSEqualRanges(NSRangeFromString(string), partialRange))
        }

        let fullRangeStrings = [
            "{12, 34}",
            "[12, 34]",
            "12.34",
        ]
        let fullRange = NSRange(location: 12, length: 34)
        for string in fullRangeStrings {
            XCTAssert(NSEqualRanges(NSRangeFromString(string), fullRange))
        }
    }
    
    func test_NSRangeBridging() {
        let swiftRange: Range<Int> = 1..<7
        let range = NSRange(swiftRange)
        let swiftRange2 = Range(range)
        XCTAssertEqual(swiftRange, swiftRange2)
    }

    func test_NSMaxRange() {
        let ranges = [(NSRange(location: 0, length: 3), 3),
                      (NSRange(location: 7, length: 8), 15),
                      (NSRange(location: 56, length: 1), 57)]
        for (range, result) in ranges {
            XCTAssertEqual(NSMaxRange(range), result)
        }
    }

    func test_NSLocationInRange() {
        let ranges = [(3, NSRange(location: 0, length: 5), true),
                      (10, NSRange(location: 2, length: 9), true),
                      (7, NSRange(location: 2, length: 5), false),
                      (5, NSRange(location: 5, length: 1), true)];
        for (location, range, result) in ranges {
            XCTAssertEqual(NSLocationInRange(location, range), result);
        }
    }

    func test_NSEqualRanges() {
        let ranges = [(NSRange(location: 0, length: 3), NSRange(location: 0, length: 3), true),
                      (NSRange(location: 0, length: 4), NSRange(location: 0, length: 8), false),
                      (NSRange(location: 3, length: 6), NSRange(location: 3, length: 10), false),
                      (NSRange(location: 0, length: 5), NSRange(location: 7, length: 8), false)]
        for (first, second, result) in ranges {
            XCTAssertEqual(NSEqualRanges(first, second), result)
        }
    }

    
    func test_NSUnionRange() {
        let ranges = [(NSRange(location: 0, length: 5), NSRange(location: 3, length: 8), NSRange(location: 0, length: 11)),
                      (NSRange(location: 6, length: 10), NSRange(location: 3, length: 8), NSRange(location: 3, length: 13)),
                      (NSRange(location: 3, length: 8), NSRange(location: 6, length: 10), NSRange(location: 3, length: 13)),
                      (NSRange(location: 0, length: 5), NSRange(location: 7, length: 8), NSRange(location: 0, length: 15)),
                      (NSRange(location: 0, length: 3), NSRange(location: 1, length: 2), NSRange(location: 0, length: 3))]
        for (first, second, result) in ranges {
            XCTAssert(NSEqualRanges(NSUnionRange(first, second), result))
        }
    }

    func test_NSIntersectionRange() {
        let ranges = [(NSRange(location: 0, length: 5), NSRange(location: 3, length: 8), NSRange(location: 3, length: 2)),
                      (NSRange(location: 6, length: 10), NSRange(location: 3, length: 8), NSRange(location: 6, length: 5)),
                      (NSRange(location: 3, length: 8), NSRange(location: 6, length: 10), NSRange(location: 6, length: 5)),
                      (NSRange(location: 0, length: 5), NSRange(location: 7, length: 8), NSRange(location: 0, length: 0)),
                      (NSRange(location: 0, length: 3), NSRange(location: 1, length: 2), NSRange(location: 1, length: 2))]
        for (first, second, result) in ranges {
            XCTAssert(NSEqualRanges(NSIntersectionRange(first, second), result))
        }
    }

    func test_NSStringFromRange() {
        let ranges = ["{0, 0}": NSRange(location: 0, length: 0),
                      "{6, 4}": NSRange(location: 6, length: 4),
                      "{0, 10}": NSRange(location: 0, length: 10),
                      "{10, 200}": NSRange(location: 10, length: 200),
                      "{100, 10}": NSRange(location: 100, length: 10),
                      "{1000, 100000}": NSRange(location: 1000, length: 100_000)];

        for (string, range) in ranges {
            XCTAssertEqual(NSStringFromRange(range), string)
        }
    }
    
    /// Specialized for the below tests.
    private func _assertNSRangeInit<S: StringProtocol, R: RangeExpression>(
        _ region: R, in target: S, is rangeString: String
    ) where R.Bound == S.Index {
        XCTAssert(NSEqualRanges(NSRangeFromString(rangeString), NSRange(region, in: target)))
    }
    
    func test_init_region_in_ascii_string() {
        // all count = 18
        let normalString = "1;DROP TABLE users"
        
        _assertNSRangeInit(normalString.index(normalString.startIndex, offsetBy: 2)..<normalString.index(normalString.endIndex, offsetBy: -6), in: normalString, is: "{2, 10}")
        _assertNSRangeInit(normalString.index(after: normalString.startIndex)...normalString.index(before: normalString.endIndex), in: normalString, is: "{1, 17}")
        _assertNSRangeInit(normalString.startIndex..., in: normalString, is: "{0, 18}")
        _assertNSRangeInit(...normalString.firstIndex(of: " ")!, in: normalString, is: "{0, 7}")
        _assertNSRangeInit(..<normalString.lastIndex(of: " ")!, in: normalString, is: "{0, 12}")
        
        let normalSubstring: Substring = normalString.split(separator: ";")[1]
        
        _assertNSRangeInit(normalSubstring.range(of: "TABLE")!, in: normalSubstring, is: "{5, 5}")
        _assertNSRangeInit(normalSubstring.index(after: normalSubstring.firstIndex(of: " ")!)..<normalSubstring.lastIndex(of: " ")!, in: normalString, is: "{7, 5}")
        _assertNSRangeInit(normalSubstring.firstIndex(of: "u")!...normalSubstring.lastIndex(of: "u")!, in: normalSubstring, is: "{11, 1}")
        _assertNSRangeInit(normalSubstring.startIndex..., in: normalSubstring, is: "{0, 16}")
        _assertNSRangeInit(normalSubstring.startIndex..., in: normalString, is: "{2, 16}")
        _assertNSRangeInit(...normalSubstring.lastIndex(of: " ")!, in: normalSubstring, is: "{0, 11}")
        _assertNSRangeInit(..<normalSubstring.lastIndex(of: " ")!, in: normalString, is: "{0, 12}")
    }
    
    func test_init_region_in_unicode_string() {
        // count: 46, utf8: 90, utf16: 54
        let unicodeString = "This  is a #naughty👻 string (╯°□°）╯︵ ┻━┻👨‍👩‍👧‍👦)"
        
        _assertNSRangeInit(unicodeString.index(unicodeString.startIndex, offsetBy: 10)..<unicodeString.index(unicodeString.startIndex, offsetBy: 28), in: unicodeString, is: "{10, 19}")
        _assertNSRangeInit(unicodeString.index(after: unicodeString.startIndex)...unicodeString.index(before: unicodeString.endIndex), in: unicodeString, is: "{1, 53}")
        _assertNSRangeInit(unicodeString.startIndex..., in: unicodeString, is: "{0, 54}")
        _assertNSRangeInit(...unicodeString.firstIndex(of: "👻")!, in: unicodeString, is: "{0, 22}")
        _assertNSRangeInit(..<unicodeString.range(of: "👨‍👩‍👧‍👦")!.lowerBound, in: unicodeString, is: "{0, 42}")
        
        let unicodeSubstring: Substring = unicodeString[unicodeString.firstIndex(of: "👻")!...]
        
        _assertNSRangeInit(unicodeSubstring.range(of: "👨‍👩‍👧‍👦")!, in: unicodeSubstring, is: "{22, 11}")
        _assertNSRangeInit(unicodeSubstring.range(of: "👨")!.lowerBound..<unicodeSubstring.range(of: "👦")!.upperBound, in: unicodeString, is: "{42, 11}")
        _assertNSRangeInit(unicodeSubstring.index(after: unicodeSubstring.startIndex)...unicodeSubstring.index(before: unicodeSubstring.endIndex), in: unicodeSubstring, is: "{2, 32}")
        _assertNSRangeInit(unicodeSubstring.startIndex..., in: unicodeSubstring, is: "{0, 34}")
        _assertNSRangeInit(unicodeSubstring.startIndex..., in: unicodeString, is: "{20, 34}")
        _assertNSRangeInit(...unicodeSubstring.firstIndex(of: "╯")!, in: unicodeSubstring, is: "{0, 12}")
        _assertNSRangeInit(..<unicodeSubstring.firstIndex(of: "╯")!, in: unicodeString, is: "{0, 31}")
    }

    func test_hashing() {
        let large = Int.max >> 2
        let samples: [NSRange] = [
            NSRange(location: 1, length: 1),
            NSRange(location: 1, length: 2),
            NSRange(location: 2, length: 1),
            NSRange(location: 2, length: 2),
            NSRange(location: large, length: large),
            NSRange(location: 0, length: large),
            NSRange(location: large, length: 0),
        ]
        checkHashable(samples, equalityOracle: { $0 == $1 })
    }
}
