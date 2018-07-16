// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSTextCheckingResult: XCTestCase {
    static var allTests: [(String, (TestNSTextCheckingResult) -> () throws -> Void)] {
        return [
           ("test_textCheckingResult", test_textCheckingResult),
        ]
    }
    
    func test_textCheckingResult() {
       let patternString = "(a|b)x|123|(c|d)y"
       do {
           let patternOptions: NSRegularExpression.Options = []
           let regex = try NSRegularExpression(pattern: patternString, options: patternOptions)
           let searchString = "1x030cy"
           let searchOptions: NSRegularExpression.MatchingOptions = []
           let searchRange = NSRange(location: 0, length: 7)
           let match: NSTextCheckingResult =  regex.firstMatch(in: searchString, options: searchOptions, range: searchRange)!
           //Positive offset
           var result = match.adjustingRanges(offset: 1)
           XCTAssertEqual(result.range(at: 0).location, 6)
           XCTAssertEqual(result.range(at: 1).location, NSNotFound)
           XCTAssertEqual(result.range(at: 2).location, 6)
           //Negative offset
           result = match.adjustingRanges(offset: -2)
           XCTAssertEqual(result.range(at: 0).location, 3)
           XCTAssertEqual(result.range(at: 1).location, NSNotFound)
           XCTAssertEqual(result.range(at: 2).location, 3)
           //ZeroOffset
           result = match.adjustingRanges(offset: 0)
           XCTAssertEqual(result.range(at: 0).location, 5)
           XCTAssertEqual(result.range(at: 1).location, NSNotFound)
           XCTAssertEqual(result.range(at: 2).location, 5)
        } catch {
            XCTFail("Unable to build regular expression for pattern \(patternString)")
        }
    }
}
