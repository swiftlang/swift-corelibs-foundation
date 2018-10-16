// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

class TestNSRegularExpression : XCTestCase {
    
    static var allTests : [(String, (TestNSRegularExpression) -> () throws -> Void)] {
        return [
            ("test_simpleRegularExpressions", test_simpleRegularExpressions),
            ("test_regularExpressionReplacement", test_regularExpressionReplacement),
            ("test_complexRegularExpressions", test_complexRegularExpressions),
            ("test_Equal", test_Equal),
            ("test_NSCoding", test_NSCoding),
            ("test_defaultOptions", test_defaultOptions),
            ("test_badPattern", test_badPattern),
        ]
    }
    
    func simpleRegularExpressionTestWithPattern(_ patternString: String, target searchString: String, looking: Bool, match: Bool, file: StaticString = #file, line: UInt = #line) {
        do {
            let str = NSString(string: searchString)
            var range = NSRange(location: 0, length: str.length)
            let regex = try NSRegularExpression(pattern: patternString)
            do {
                let lookingRange = regex.rangeOfFirstMatch(in: searchString, options: .anchored, range: range)
                let matchRange = regex.rangeOfFirstMatch(in: searchString, options: [], range: range)
                let lookingResult = lookingRange.location == range.location
                let matchResult = NSEqualRanges(matchRange, range)
                XCTAssertTrue((lookingResult && looking) || (!lookingResult && !looking), "Case 0 simple regex \(patternString) in \(searchString) looking \(lookingResult) should be \(looking)", file: file, line: line)
                XCTAssertTrue((matchResult && match) || (!matchResult && !match), "Case 0 simple regex \(patternString) in \(searchString) match \(matchResult) should be \(match)", file: file, line: line)
            }
            do {
                let lookingRange = str.range(of: patternString, options: [.regularExpression, .anchored], range: range, locale: nil)
                let matchRange = str.range(of: patternString, options: .regularExpression, range: range, locale: nil)
                let lookingResult = lookingRange.location == range.location
                let matchResult = NSEqualRanges(matchRange, range)
                
                XCTAssertTrue((lookingResult && looking) || (!lookingResult && !looking), "Case 1 simple regex \(patternString) in \(searchString) looking \(lookingResult) should be \(looking)", file: file, line: line)
                XCTAssertTrue((matchResult && match) || (!matchResult && !match), "Case 1 simple regex \(patternString) in \(searchString) match \(matchResult) should be \(match)", file: file, line: line)
            }
            do {
                let prefixString = "when in the course of human events "
                let suffixString = " becomes necessary"
                let searchString2 = NSString(string: "\(prefixString)\(searchString)\(suffixString)")
                range.location = prefixString.utf16.count
                let lookingRange = searchString2.range(of: patternString, options: [.regularExpression, .anchored], range: range, locale: nil)
                let matchRange = searchString2.range(of: patternString, options: [.regularExpression], range: range, locale: nil)
                
                let lookingResult = lookingRange.location == range.location
                let matchResult = NSEqualRanges(matchRange, range)
                
                XCTAssertTrue((lookingResult && looking) || (!lookingResult && !looking), "Case 2 simple regex \(patternString) in \(searchString) looking \(lookingResult) should be \(looking)", file: file, line: line)
                XCTAssertTrue((matchResult && match) || (!matchResult && !match), "Case 2 simple regex \(patternString) in \(searchString) match \(matchResult) should be \(match)", file: file, line: line)
            }
            if !patternString.hasPrefix(".") {
                let prefixString = "when in the course of human events "
                let suffixString = " becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary"
                let searchString2 = NSString(string: "\(prefixString)\(searchString)\(suffixString)")
                range.location = prefixString.utf16.count
                let lookingRange = searchString2.range(of: patternString, options:  [.regularExpression, .anchored], range: NSRange(location: range.location, length: range.length + suffixString.utf16.count), locale: nil)
                let matchRange = searchString2.range(of: patternString, options: .regularExpression, range: NSRange(location: range.location, length: range.length + suffixString.utf16.count), locale: nil)
                let lookingResult = lookingRange.location == range.location
                let matchResult = lookingResult && (matchRange.length >= range.length)
                
                XCTAssertTrue((lookingResult && looking) || (!lookingResult && !looking), "Case 3 simple regex \(patternString) in \(searchString) looking \(lookingResult) should be \(looking)", file: file, line: line)
                XCTAssertTrue((matchResult && match) || (!matchResult && !match), "Case 3 simple regex \(patternString) in \(searchString) match \(matchResult) should be \(match)", file: file, line: line)
            }
            
            do {
                let prefixString = "when in the course of human events "
                let suffixString = " becomes necessary’"
                let searchString2 = NSString(string: "\(prefixString)\(searchString)\(suffixString)")
                range.location = prefixString.utf16.count
                let lookingRange = searchString2.range(of: patternString, options: [.regularExpression, .anchored], range: range, locale: nil)
                let matchRange = searchString2.range(of: patternString, options: [.regularExpression], range: range, locale: nil)
                
                let lookingResult = lookingRange.location == range.location
                let matchResult = NSEqualRanges(matchRange, range)
                
                XCTAssertTrue((lookingResult && looking) || (!lookingResult && !looking), "Case 4 simple regex \(patternString) in \(searchString) looking \(lookingResult) should be \(looking)", file: file, line: line)
                XCTAssertTrue((matchResult && match) || (!matchResult && !match), "Case 4 simple regex \(patternString) in \(searchString) match \(matchResult) should be \(match)", file: file, line: line)
            }
        } catch {
            XCTFail("Unable to build regular expression for pattern \(patternString)", file: file, line: line)
        }
    }
    
    func test_simpleRegularExpressions() {
        simpleRegularExpressionTestWithPattern("st(abc)ring", target:"stabcring thing", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("st(abc)ring", target:"stabcring", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("st(abc)ring", target:"stabcrung", looking:false, match:false)
        simpleRegularExpressionTestWithPattern("st(abc)*ring", target:"string", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("st(abc)*ring", target:"stabcring", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("st(abc)*ring", target:"stabcabcring", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("st(abc)*ring", target:"stabcabcdring", looking:false, match:false)
        simpleRegularExpressionTestWithPattern("st(abc)*ring", target:"stabcabcabcring etc.", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("a*", target:"", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("a*", target:"b", looking:true, match:false)
        simpleRegularExpressionTestWithPattern(".", target:"abc", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("...", target:"abc", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("....", target:"abc", looking:false, match:false)
        simpleRegularExpressionTestWithPattern(".*", target:"abcxyz123", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("ab.*xyz", target:"abcdefghij", looking:false, match:false)
        simpleRegularExpressionTestWithPattern("ab.*xyz", target:"abcdefg...wxyz", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("ab.*xyz", target:"abcde...wxyz...abc..xyz", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("ab.*xyz", target:"abcde...wxyz...abc..xyz...", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("abc*", target:"ab", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("abc*", target:"abccccc", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("[1-6]", target:"1", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("[1-6]", target:"3", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("[1-6]", target:"7", looking:false, match:false)
        simpleRegularExpressionTestWithPattern("a[1-6]", target:"a3", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("a[1-6]", target:"a3", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("a[1-6]b", target:"a3b", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("a[0-9]*b", target:"a123b", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("a[0-9]*b", target:"abc", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("[\\p{Nd}]*", target:"123456", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("[\\p{Nd}]*", target:"a123456", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("[a][b][[:Zs:]]*", target:"ab   ", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("(a|b)", target:"a", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("(a|b)", target:"b", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("(a|b)", target:"c", looking:false, match:false)
        simpleRegularExpressionTestWithPattern("a|b", target:"b", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("(a|b|c)*", target:"aabcaaccbcabc", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("(a|b|c)*", target:"aabcaaccbcabdc", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("(a(b|c|d)(x|y|z)*|123)", target:"ac", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("(a(b|c|d)(x|y|z)*|123)", target:"123", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("(a|(1|2)*)(b|c|d)(x|y|z)*|123", target:"123", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("(a|(1|2)*)(b|c|d)(x|y|z)*|123", target:"222211111czzzzw", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("ab+", target:"abbc", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("ab+c", target:"ac", looking:false, match:false)
        simpleRegularExpressionTestWithPattern("b+", target:"", looking:false, match:false)
        simpleRegularExpressionTestWithPattern("(abc|def)+", target:"defabc", looking:true, match:true)
        simpleRegularExpressionTestWithPattern(".+y", target:"zippity dooy dah ", looking:true, match:false)
        simpleRegularExpressionTestWithPattern(".+y", target:"zippity dooy", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("ab?", target:"ab", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("ab?", target:"a", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("ab?", target:"ac", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("ab?", target:"abb", looking:true, match:false)
        simpleRegularExpressionTestWithPattern("a(b|c)?d", target:"abd", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("a(b|c)?d", target:"acd", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("a(b|c)?d", target:"ad", looking:true, match:true)
        simpleRegularExpressionTestWithPattern("a(b|c)?d", target:"abcd", looking:false, match:false)
        simpleRegularExpressionTestWithPattern("a(b|c)?d", target:"ab", looking:false, match:false)
        simpleRegularExpressionTestWithPattern(".*\\Ax", target:"xyz", looking:true, match:false)
        simpleRegularExpressionTestWithPattern(".*\\Ax", target:" xyz", looking:false, match:false)
        simpleRegularExpressionTestWithPattern("\\\\\\|\\(\\)\\[\\{\\~\\$\\*\\+\\?\\.", target:"\\|()[{~$*+?.", looking:true, match:true)
        simpleRegularExpressionTestWithPattern(NSRegularExpression.escapedPattern(for: "+\\{}[].^$?#<=!&*()"), target:"+\\{}[].^$?#<=!&*()", looking:true, match:true)
        simpleRegularExpressionTestWithPattern(NSRegularExpression.escapedPattern(for: "+\\{}[].^$?#<=!&*()"), target:"+\\{}[].^$?#<=!&*() abc", looking:true, match:false)
    }
    
    func replaceRegularExpressionTest(_ patternString: String, _ patternOptions: NSRegularExpression.Options, _ searchString: String, _ searchOptions: NSRegularExpression.MatchingOptions, _ searchRange: NSRange, _ templ: String, _ numberOfMatches: Int, _ result: String, file: StaticString = #file, line: UInt = #line) {
        do {
            let regex = try NSRegularExpression(pattern: patternString, options: patternOptions)
            let mutableString = NSMutableString(string: searchString)
            let matchCount = regex.replaceMatches(in: mutableString, options: searchOptions, range: searchRange, withTemplate: templ)
            let replacedString = regex.stringByReplacingMatches(in: searchString, options: searchOptions, range: searchRange, withTemplate: templ)
            XCTAssertEqual(numberOfMatches, matchCount, "Regex replace \(patternString) in \(searchString) with \(templ) number \(matchCount) should be \(numberOfMatches)", file: file, line: line)
            XCTAssertEqual(result, replacedString, "Regex replace \(patternString) in \(searchString) with \(templ) replaced \(replacedString) should be \(result)", file: file, line: line)
            XCTAssertEqual(NSString(string: result), mutableString, "Regex replace \(patternString) in \(searchString) with \(templ) mutated \(mutableString) should be \(result)", file: file, line: line)
        } catch {
            XCTFail("Unable to construct regular expression from \(patternString) options \(patternOptions)", file: file, line: line)
        }
    }
    
    func test_regularExpressionReplacement() {
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This is the way.", [], NSRange(location: 0, length: 16), "foo", 0, "This is the way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), "foo", 1, "This this is foo way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), "$0", 1, "This this is the the way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), "*$0*", 1, "This this is *the the* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), "*$1*", 1, "This this is *the* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), "*$2*", 1, "This this is ** way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), "*$10*", 1, "This this is *the0* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), "*$*", 1, "This this is *$* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), NSRegularExpression.escapedTemplate(for: "*$1*"), 1, "This this is *$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), NSRegularExpression.escapedTemplate(for: "*\\$1*"), 1, "This this is *\\$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), "*\\$1*", 1, "This this is *$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), "*\\\\\\$1*", 1, "This this is *\\$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), "$0", 2, "This this is the the way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), "*$0*", 2, "*This this* is *the the* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), "*$1*", 2, "*This* is *the* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), "*$2*", 2, "** is ** way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), "*$10*", 2, "*This0* is *the0* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), "*$*", 2, "*$* is *$* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), NSRegularExpression.escapedTemplate(for: "*$1*"), 2, "*$1* is *$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), NSRegularExpression.escapedTemplate(for: "*\\$1*"), 2, "*\\$1* is *\\$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), "*\\$1*", 2, "*$1* is *$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), "*\\\\\\$1*", 2, "*\\$1* is *\\$1* way.")
        replaceRegularExpressionTest("([1-9]a)([1-9]b)([1-9]c)([1-9]d)([1-9]e)([1-9]f)", [], "9a3b4c8d3e1f,9a3b4c8d3e1f", [], NSRange(location: 0, length: 25), "$2$4 is your key", 2, "3b8d is your key,3b8d is your key")
        replaceRegularExpressionTest("([1-9]a)([1-9]b)([1-9]c)([1-9]d)([1-9]e)([1-9]f)([1-9]z)", [], "9a3b4c8d3e1f2z,9a3b4c8d3e1f2z", [], NSRange(location: 0, length: 29), "$2$4$1 is your key", 2, "3b8d9a is your key,3b8d9a is your key")
    }
    
    func complexRegularExpressionTest(_ patternString: String, _ patternOptions: NSRegularExpression.Options, _ searchString: String, _ searchOptions: NSRegularExpression.MatchingOptions, _ searchRange: NSRange, _ numberOfMatches: Int, _ firstMatchOverallRange: NSRange, _ firstMatchFirstCaptureRange: NSRange, _ firstMatchLastCaptureRange: NSRange, file: StaticString = #file, line: UInt = #line) {
        do {
            let regex = try NSRegularExpression(pattern: patternString, options: patternOptions)
            let matches = regex.matches(in: searchString, options: searchOptions, range: searchRange)
            let matchCount = regex.numberOfMatches(in: searchString, options: searchOptions, range: searchRange)
            let firstResult = regex.firstMatch(in: searchString, options: searchOptions, range: searchRange)
            let firstRange = regex.rangeOfFirstMatch(in: searchString, options: searchOptions, range: searchRange)
            let captureCount = regex.numberOfCaptureGroups
            
            XCTAssertEqual(numberOfMatches, matches.count, "Complex regex \(patternString) in \(searchString) number \(matches.count)/\(matchCount) should be \(numberOfMatches)", file: file, line: line)
            XCTAssertTrue(NSEqualRanges(firstRange, firstMatchOverallRange), "Complex regex \(patternString) in \(searchString) match range \(NSStringFromRange(firstRange)) should be \(NSStringFromRange(firstMatchOverallRange))", file: file, line: line)
            for result in matches {
                let rangeCount = result.numberOfRanges
                XCTAssertEqual(captureCount + 1, rangeCount, "Complex regex \(patternString) in \(searchString) mismatch \(captureCount) groups but \(result) has \(rangeCount) ranges", file: file, line: line)
            }
            if let first = firstResult, matches.count > 0 {
                XCTAssertTrue(NSEqualRanges(first.range, firstMatchOverallRange), "Complex regex \(patternString) in \(searchString) match range \(NSStringFromRange(first.range)) should be \(NSStringFromRange(firstMatchOverallRange))", file: file, line: line)
                if captureCount > 0 {
                    XCTAssertTrue(NSEqualRanges(first.range(at: 1), firstMatchFirstCaptureRange), "Complex regex \(patternString) in \(searchString) match range \(first.range(at: 1)) should be \(NSStringFromRange(firstMatchFirstCaptureRange))", file: file, line: line)
                } else {
                    XCTAssertTrue(NSEqualRanges(firstMatchFirstCaptureRange, NSRange(location: NSNotFound, length: 0)), "Complex regex \(patternString) in \(searchString) no captures should be \(NSStringFromRange(firstMatchFirstCaptureRange))", file: file, line: line)
                }
                if captureCount > 1 {
                    XCTAssertTrue(NSEqualRanges(first.range(at: captureCount), firstMatchLastCaptureRange), "Complex regex \(patternString) in \(searchString)  last capture range \(NSStringFromRange(first.range(at: captureCount))) should be \(NSStringFromRange(firstMatchLastCaptureRange))", file: file, line: line)
                }
            }
        } catch {
            XCTFail("Unable to construct regular expression from \(patternString) options \(patternOptions)", file: file, line: line)
        }
    }
    
    func test_complexRegularExpressions() {
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This is the way.", [], NSRange(location: 0, length: 16), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the theway.", [], NSRange(location: 0, length: 24), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the theway.", [], NSRange(location: 0, length: 20), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the theway.", .withTransparentBounds, NSRange(location: 0, length: 20), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "xThis this is the theway.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "xThis this is the theway.", [], NSRange(location: 1, length: 20), 1, NSRange(location: 14, length: 7), NSRange(location: 14, length: 3), NSRange(location: 14, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "xThis this is the theway.", [], NSRange(location: 1, length: 20), 2, NSRange(location: 1, length: 9), NSRange(location: 1, length: 4), NSRange(location: 1, length: 4))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "xThis this is the theway.", .withTransparentBounds, NSRange(location: 1, length: 20), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        
        complexRegularExpressionTest(NSRegularExpression.escapedPattern(for: "\\b(th[a-z]+) \\1\\b"), [], "This this is the the way.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest(NSRegularExpression.escapedPattern(for: "\\b(th[a-z]+) \\1\\b"), [], "x\\b(th[a-z]+) \\1\\by", [], NSRange(location: 0, length: 19), 1, NSRange(location: 1, length: 17), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .ignoreMetacharacters, "This this is the the way.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .ignoreMetacharacters, "x\\b(th[a-z]+) \\1\\by", [], NSRange(location: 0, length: 19), 1, NSRange(location: 1, length: 17), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "This this is the the way.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "This this is the the way.", [], NSRange(location: 13, length: 7), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "This this is the the way.", .withoutAnchoringBounds, NSRange(location: 13, length: 7), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "this this\nthe the", [], NSRange(location: 0, length: 17), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", .anchorsMatchLines, "this this\nthe the", [], NSRange(location: 0, length: 17), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", .anchorsMatchLines, "this this\rthe the", [], NSRange(location: 0, length: 17), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [.useUnixLineSeparators, .anchorsMatchLines], "this this\nthe the", [], NSRange(location: 0, length: 17), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [.useUnixLineSeparators, .anchorsMatchLines], "this this\rthe the", [], NSRange(location: 0, length: 17), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "This is the way.", [], NSRange(location: 0, length: 16), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "Thisxthis is thexthe way.", [], NSRange(location: 0, length: 25), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", .caseInsensitive, "Thisxthis is thexthe way.", [], NSRange(location: 0, length: 25), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "This\nthis is the\nthe way.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", .dotMatchesLineSeparators, "This\nthis is the\nthe way.", [], NSRange(location: 0, length: 25), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [.dotMatchesLineSeparators, .caseInsensitive], "Thisxthis is thexthe way.", [], NSRange(location: 0, length: 25), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        
        complexRegularExpressionTest("\\b(th[a-z]+).\n#the first expression repeats\n\\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+).\n#the first expression repeats\n\\1\\b", .allowCommentsAndWhitespace, "This this is the the way.", [], NSRange(location: 0, length: 25), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "This this is the the way.", [], NSRange(location: 0, length: 25), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the theway.", [], NSRange(location: 0, length: 24), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the theway.", [], NSRange(location: 0, length: 20), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the theway.", .withTransparentBounds, NSRange(location: 0, length: 20), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "xThis this is the theway.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "xThis this is the theway.", [], NSRange(location: 1, length: 20), 1, NSRange(location: 14, length: 7), NSRange(location: 14, length: 3), NSRange(location: 14, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "xThis this is the theway.", [], NSRange(location: 1, length: 20), 2, NSRange(location: 1, length: 9), NSRange(location: 1, length: 4), NSRange(location: 1, length: 4))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .caseInsensitive, "xThis this is the theway.", .withTransparentBounds, NSRange(location: 1, length: 20), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        
        complexRegularExpressionTest(NSRegularExpression.escapedPattern(for: "\\b(th[a-z]+) \\1\\b"), [], "This this is the the way.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest(NSRegularExpression.escapedPattern(for: "\\b(th[a-z]+) \\1\\b"), [], "x\\b(th[a-z]+) \\1\\by", [], NSRange(location: 0, length: 19), 1, NSRange(location: 1, length: 17), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .ignoreMetacharacters, "This this is the the way.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .ignoreMetacharacters, "x\\b(th[a-z]+) \\1\\by", [], NSRange(location: 0, length: 19), 1, NSRange(location: 1, length: 17), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "This this is the the way.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "This this is the the way.", [], NSRange(location: 13, length: 7), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "This this is the the way.", .withoutAnchoringBounds, NSRange(location: 13, length: 7), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "this this\nthe the", [], NSRange(location: 0, length: 17), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", .anchorsMatchLines, "this this\nthe the", [], NSRange(location: 0, length: 17), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", .anchorsMatchLines, "this this\rthe the", [], NSRange(location: 0, length: 17), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [.useUnixLineSeparators, .anchorsMatchLines], "this this\nthe the", [], NSRange(location: 0, length: 17), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [.useUnixLineSeparators, .anchorsMatchLines], "this this\rthe the", [], NSRange(location: 0, length: 17), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "This is the way.", [], NSRange(location: 0, length: 16), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "Thisxthis is thexthe way.", [], NSRange(location: 0, length: 25), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", .caseInsensitive, "Thisxthis is thexthe way.", [], NSRange(location: 0, length: 25), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "This\nthis is the\nthe way.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", .dotMatchesLineSeparators, "This\nthis is the\nthe way.", [], NSRange(location: 0, length: 25), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [.dotMatchesLineSeparators, .caseInsensitive], "Thisxthis is thexthe way.", [], NSRange(location: 0, length: 25), 2, NSRange(location: 0, length: 9), NSRange(location: 0, length: 4), NSRange(location: 0, length: 4))
        
        complexRegularExpressionTest("\\b(th[a-z]+).\n#the first expression repeats\n\\1\\b", [], "This this is the the way.", [], NSRange(location: 0, length: 25), 0, NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("\\b(th[a-z]+).\n#the first expression repeats\n\\1\\b", .allowCommentsAndWhitespace, "This this is the the way.", [], NSRange(location: 0, length: 25), 1, NSRange(location: 13, length: 7), NSRange(location: 13, length: 3), NSRange(location: 13, length: 3))
        complexRegularExpressionTest("(a(b|c|d)(x|y|z)*|123)", [], "abx", [], NSRange(location: 0, length: 3), 1, NSRange(location: 0, length: 3), NSRange(location: 0, length: 3), NSRange(location: 2, length: 1))
        complexRegularExpressionTest("(a(b|c|d)(x|y|z)*|123)", [], "123", [], NSRange(location: 0, length: 3), 1, NSRange(location: 0, length: 3), NSRange(location: 0, length: 3), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("a(b|c|d)(x|y|z)*|123", [], "123", [], NSRange(location: 0, length: 3), 1, NSRange(location: 0, length: 3), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("a(b|c|d)(x|y|z)*", [], "abx", [], NSRange(location: 0, length: 3), 1, NSRange(location: 0, length: 3), NSRange(location: 1, length: 1), NSRange(location: 2, length: 1))
        complexRegularExpressionTest("(a(b|c|d)(x|y|z)*|123)", [], "abxy", [], NSRange(location: 0, length: 4), 1, NSRange(location: 0, length: 4), NSRange(location: 0, length: 4), NSRange(location: 3, length: 1))
        complexRegularExpressionTest("a(b|c|d)(x|y|z)*", [], "abxy", [], NSRange(location: 0, length: 4), 1, NSRange(location: 0, length: 4), NSRange(location: 1, length: 1), NSRange(location: 3, length: 1))
        complexRegularExpressionTest("(a|b)x|123|(c|d)y", [], "123dy", [], NSRange(location: 0, length: 5), 2, NSRange(location: 0, length: 3), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("(a|b)x|123|(c|d)y", [], "903847123", [], NSRange(location: 0, length: 9), 1, NSRange(location: 6, length: 3), NSRange(location: NSNotFound, length: 0), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("(a|b)x|123|(c|d)y", [], "axcy", [], NSRange(location: 0, length: 4), 2, NSRange(location: 0, length: 2), NSRange(location: 0, length: 1), NSRange(location: NSNotFound, length: 0))
        complexRegularExpressionTest("(a|b)x|123|(c|d)y", [], "cya", [], NSRange(location: 0, length: 3), 1, NSRange(location: 0, length: 2), NSRange(location: NSNotFound, length: 0), NSRange(location: 0, length: 1))
    }
    
    func test_Equal() {
        var regularExpressionA = try! NSRegularExpression(pattern: "[a-z]+", options: [])
        var regularExpressionB = try! NSRegularExpression(pattern: "[a-z]+", options: [])
        XCTAssertTrue(regularExpressionA == regularExpressionB)
        XCTAssertFalse(regularExpressionA === regularExpressionB)
        
        regularExpressionA = try! NSRegularExpression(pattern: "[a-z]+", options: .caseInsensitive)
        regularExpressionB = try! NSRegularExpression(pattern: "[a-z]+", options: .caseInsensitive)
        XCTAssertTrue(regularExpressionA == regularExpressionB)
        XCTAssertFalse(regularExpressionA === regularExpressionB)
        
        regularExpressionA = try! NSRegularExpression(pattern: "[a-z]+", options: [.caseInsensitive, .allowCommentsAndWhitespace])
        regularExpressionB = try! NSRegularExpression(pattern: "[a-z]+", options: [.caseInsensitive, .allowCommentsAndWhitespace])
        XCTAssertTrue(regularExpressionA == regularExpressionB)
        XCTAssertFalse(regularExpressionA === regularExpressionB)
        
        regularExpressionA = try! NSRegularExpression(pattern: "[a-z]+", options: .caseInsensitive)
        regularExpressionB = try! NSRegularExpression(pattern: "[a-z]+", options: [.caseInsensitive, .allowCommentsAndWhitespace])
        XCTAssertFalse(regularExpressionA == regularExpressionB)
        XCTAssertFalse(regularExpressionA === regularExpressionB)
        
        regularExpressionA = try! NSRegularExpression(pattern: "[a-y]+", options: .caseInsensitive)
        regularExpressionB = try! NSRegularExpression(pattern: "[a-z]+", options: .caseInsensitive)
        XCTAssertFalse(regularExpressionA == regularExpressionB)
        XCTAssertFalse(regularExpressionA === regularExpressionB)
    }
    
    func test_NSCoding() {
        let regularExpressionA = try! NSRegularExpression(pattern: "[a-z]+", options: [.caseInsensitive, .allowCommentsAndWhitespace])
        let regularExpressionB = NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: regularExpressionA)) as! NSRegularExpression
        XCTAssertEqual(regularExpressionA, regularExpressionB, "Archived then unarchived `NSRegularExpression` must be equal.")
    }

    // Check all of the following functions do not need to be passed options:
    func test_defaultOptions() {
        let pattern = ".*fatal error: (.*): file (.*), line ([0-9]+)$"
        let text = "fatal error: Some message: file /tmp/foo.swift, line 123"
        let regex = try? NSRegularExpression(pattern: pattern)
        XCTAssertNotNil(regex)
        let range = NSRange(text.startIndex..., in: text)
        regex!.enumerateMatches(in: text, range: range, using: {_,_,_ in })
        XCTAssertEqual(regex!.matches(in: text, range: range).first?.numberOfRanges, 4)
        XCTAssertEqual(regex!.numberOfMatches(in: text, range: range), 1)
        XCTAssertEqual(regex!.firstMatch(in: text, range: range)?.numberOfRanges, 4)
        XCTAssertEqual(regex!.rangeOfFirstMatch(in: text, range: range),
                       NSRange(location: 0, length: 56))
        XCTAssertEqual(regex!.stringByReplacingMatches(in: text, range: range, withTemplate: "$1-$2-$3"),
                      "Some message-/tmp/foo.swift-123")
        let str = NSMutableString(string: text)
        XCTAssertEqual(regex!.replaceMatches(in: str, range: range, withTemplate: "$1-$2-$3"), 1)
    }

    func test_badPattern() {
        do {
            _ = try NSRegularExpression(pattern: "(", options: [])
            XCTFail()
        } catch {
            let err = String(describing: error)
            XCTAssertEqual(err, "Error Domain=NSCocoaErrorDomain Code=2048 \"(null)\" UserInfo={NSInvalidValue=(}")
        }
    }
}
