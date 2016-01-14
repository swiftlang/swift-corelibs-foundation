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



class TestNSRegularExpression : XCTestCase {
    
    var allTests : [(String, () throws -> ())] {
        return [
            ("test_simpleRegularExpressions", test_simpleRegularExpressions),
            ("test_regularExpressionReplacement", test_regularExpressionReplacement)
        ]
    }
    
    func simpleRegularExpressionTestWithPattern(patternString: String, target searchString: String, looking: Bool, match: Bool, file: StaticString = __FILE__, line: UInt = __LINE__) {
        do {
            let str = searchString.bridge()
            var range = NSMakeRange(0, str.length)
            let regex = try NSRegularExpression(pattern: patternString, options: [])
            do {
                let lookingRange = regex.rangeOfFirstMatchInString(searchString, options: .Anchored, range: range)
                let matchRange = regex.rangeOfFirstMatchInString(searchString, options: [], range: range)
                let lookingResult = lookingRange.location == range.location
                let matchResult = NSEqualRanges(matchRange, range)
                XCTAssertTrue((lookingResult && looking) || (!lookingResult && !looking), "Case 0 simple regex \(patternString) in \(searchString) looking \(lookingResult) should be \(looking)", file: file, line: line)
                XCTAssertTrue((matchResult && match) || (!matchResult && !match), "Case 0 simple regex \(patternString) in \(searchString) match \(matchResult) should be \(match)", file: file, line: line)
            }
            do {
                let lookingRange = str.rangeOfString(patternString, options: [.RegularExpressionSearch, .AnchoredSearch], range: range, locale: nil)
                let matchRange = str.rangeOfString(patternString, options: .RegularExpressionSearch, range: range, locale: nil)
                let lookingResult = lookingRange.location == range.location
                let matchResult = NSEqualRanges(matchRange, range)
                
                XCTAssertTrue((lookingResult && looking) || (!lookingResult && !looking), "Case 1 simple regex \(patternString) in \(searchString) looking \(lookingResult) should be \(looking)", file: file, line: line)
                XCTAssertTrue((matchResult && match) || (!matchResult && !match), "Case 1 simple regex \(patternString) in \(searchString) match \(matchResult) should be \(match)", file: file, line: line)
            }
            do {
                let prefixString = "when in the course of human events "
                let suffixString = " becomes necessary"
                let searchString2 = "\(prefixString)\(searchString)\(suffixString)".bridge()
                range.location = prefixString.utf16.count
                let lookingRange = searchString2.rangeOfString(patternString, options: [.RegularExpressionSearch, .AnchoredSearch], range: range, locale: nil)
                let matchRange = searchString2.rangeOfString(patternString, options: [.RegularExpressionSearch], range: range, locale: nil)
                
                let lookingResult = lookingRange.location == range.location
                let matchResult = NSEqualRanges(matchRange, range)
                
                XCTAssertTrue((lookingResult && looking) || (!lookingResult && !looking), "Case 2 simple regex \(patternString) in \(searchString) looking \(lookingResult) should be \(looking)", file: file, line: line)
                XCTAssertTrue((matchResult && match) || (!matchResult && !match), "Case 2 simple regex \(patternString) in \(searchString) match \(matchResult) should be \(match)", file: file, line: line)
            }
            if !patternString.hasPrefix(".") {
                let prefixString = "when in the course of human events "
                let suffixString = " becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary becomes necessary"
                let searchString2 = "\(prefixString)\(searchString)\(suffixString)".bridge()
                range.location = prefixString.utf16.count
                let lookingRange = searchString2.rangeOfString(patternString, options:  [.RegularExpressionSearch, .AnchoredSearch], range: NSMakeRange(range.location, range.length + suffixString.utf16.count), locale: nil)
                let matchRange = searchString2.rangeOfString(patternString, options: .RegularExpressionSearch, range: NSMakeRange(range.location, range.length + suffixString.utf16.count), locale: nil)
                let lookingResult = lookingRange.location == range.location
                let matchResult = lookingResult && (matchRange.length >= range.length)
                
                XCTAssertTrue((lookingResult && looking) || (!lookingResult && !looking), "Case 3 simple regex \(patternString) in \(searchString) looking \(lookingResult) should be \(looking)", file: file, line: line)
                XCTAssertTrue((matchResult && match) || (!matchResult && !match), "Case 3 simple regex \(patternString) in \(searchString) match \(matchResult) should be \(match)", file: file, line: line)
            }
            
            do {
                let prefixString = "when in the course of human events "
                let suffixString = " becomes necessary’"
                let searchString2 = "\(prefixString)\(searchString)\(suffixString)".bridge()
                range.location = prefixString.utf16.count
                let lookingRange = searchString2.rangeOfString(patternString, options: [.RegularExpressionSearch, .AnchoredSearch], range: range, locale: nil)
                let matchRange = searchString2.rangeOfString(patternString, options: [.RegularExpressionSearch], range: range, locale: nil)
                
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
    }
    
    func replaceRegularExpressionTest(patternString: String, _ patternOptions: NSRegularExpressionOptions, _ searchString: String, _ searchOptions: NSMatchingOptions, _ searchRange: NSRange, _ templ: String, _ numberOfMatches: Int, _ result: String, file: StaticString = __FILE__, line: UInt = __LINE__) {
        do {
            let regex = try NSRegularExpression(pattern: patternString, options: patternOptions)
            let mutableString = searchString.bridge().mutableCopy() as! NSMutableString
            let matchCount = regex.replaceMatchesInString(mutableString, options: searchOptions, range: searchRange, withTemplate: templ)
            let replacedString = regex.stringByReplacingMatchesInString(searchString, options: searchOptions, range: searchRange, withTemplate: templ)
            XCTAssertEqual(numberOfMatches, matchCount, "Regex replace \(patternString) in \(searchString) with \(templ) number \(matchCount) should be \(numberOfMatches)", file: file, line: line)
            XCTAssertEqual(result, replacedString, "Regex replace \(patternString) in \(searchString) with \(templ) replaced \(replacedString) should be \(result)", file: file, line: line)
            XCTAssertEqual(result, mutableString.bridge(), "Regex replace \(patternString) in \(searchString) with \(templ) mutated \(mutableString) should be \(result)", file: file, line: line)
        } catch {
            XCTFail("Unable to construct regular expression from \(patternString) options \(patternOptions)", file: file, line: line)
        }
    }
    
    func test_regularExpressionReplacement() {
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This is the way.", [], NSMakeRange(0, 16), "foo", 0, "This is the way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), "foo", 1, "This this is foo way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), "$0", 1, "This this is the the way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), "*$0*", 1, "This this is *the the* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), "*$1*", 1, "This this is *the* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), "*$2*", 1, "This this is ** way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), "*$10*", 1, "This this is *the0* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), "*$*", 1, "This this is *$* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), NSRegularExpression.escapedTemplateForString("*$1*"), 1, "This this is *$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), NSRegularExpression.escapedTemplateForString("*\\$1*"), 1, "This this is *\\$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), "*\\$1*", 1, "This this is *$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), "*\\\\\\$1*", 1, "This this is *\\$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), "$0", 2, "This this is the the way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), "*$0*", 2, "*This this* is *the the* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), "*$1*", 2, "*This* is *the* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), "*$2*", 2, "** is ** way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), "*$10*", 2, "*This0* is *the0* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), "*$*", 2, "*$* is *$* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), NSRegularExpression.escapedTemplateForString("*$1*"), 2, "*$1* is *$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), NSRegularExpression.escapedTemplateForString("*\\$1*"), 2, "*\\$1* is *\\$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), "*\\$1*", 2, "*$1* is *$1* way.")
        replaceRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), "*\\\\\\$1*", 2, "*\\$1* is *\\$1* way.")
    }
    
    func complexRegularExpressionTest(patternString: String, _ patternOptions: NSRegularExpressionOptions, _ searchString: String, _ searchOptions: NSMatchingOptions, _ searchRange: NSRange, _ numberOfMatches: Int, _ firstMatchOverallRange: NSRange, _ firstMatchFirstCaptureRange: NSRange, _ firstMatchLastCaptureRange: NSRange, file: StaticString = __FILE__, line: UInt = __LINE__) {
        do {
            let regex = try NSRegularExpression(pattern: patternString, options: patternOptions)
            let matches = regex.matchesInString(searchString, options: searchOptions, range: searchRange)
            let matchCount = regex.numberOfMatchesInString(searchString, options: searchOptions, range: searchRange)
            let firstResult = regex.firstMatchInString(searchString, options: searchOptions, range: searchRange)
            let firstRange = regex.rangeOfFirstMatchInString(searchString, options: searchOptions, range: searchRange)
            let captureCount = regex.numberOfCaptureGroups
            
            XCTAssertEqual(numberOfMatches, matches.count, "Complex regex \(patternString) in \(searchString) number \(matches.count)/\(matchCount) should be \(numberOfMatches)", file: file, line: line)
            XCTAssertTrue(NSEqualRanges(firstRange, firstMatchOverallRange), "Complex regex \(patternString) in \(searchString) match range \(NSStringFromRange(firstRange)) should be \(NSStringFromRange(firstMatchOverallRange))", file: file, line: line)
            for result in matches {
                let rangeCount = result.numberOfRanges
                XCTAssertEqual(captureCount + 1, rangeCount, "Complex regex \(patternString) in \(searchString) mismatch \(captureCount) groups but \(result) has \(rangeCount) ranges", file: file, line: line)
            }
            if let first = firstResult where matches.count > 0 {
                XCTAssertTrue(NSEqualRanges(first.range, firstMatchOverallRange), "Complex regex \(patternString) in \(searchString) match range \(NSStringFromRange(first.range)) should be \(NSStringFromRange(firstMatchOverallRange))", file: file, line: line)
                if captureCount > 0 {
                    XCTAssertTrue(NSEqualRanges(first.rangeAtIndex(1), firstMatchFirstCaptureRange), "Complex regex \(patternString) in \(searchString) match range \(first.rangeAtIndex(1)) should be \(NSStringFromRange(firstMatchOverallRange))", file: file, line: line)
                } else {
                    XCTAssertTrue(NSEqualRanges(firstMatchFirstCaptureRange, NSMakeRange(NSNotFound, 0)), "Complex regex \(patternString) in \(searchString) no captures should be \(NSStringFromRange(firstMatchFirstCaptureRange))", file: file, line: line)
                }
                if captureCount > 1 {
                    XCTAssertTrue(NSEqualRanges(first.rangeAtIndex(captureCount), firstMatchLastCaptureRange), "Complex regex \(patternString) in \(searchString)  last capture range \(NSStringFromRange(first.rangeAtIndex(captureCount))) should be \(NSStringFromRange(firstMatchLastCaptureRange))", file: file, line: line)
                }
            }
        } catch {
            XCTFail("Unable to construct regular expression from \(patternString) options \(patternOptions)", file: file, line: line)
        }
    }
    
    func test_complexRegularExpressions() {
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This is the way.", [], NSMakeRange(0, 16), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0))
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), 1, NSMakeRange(13, 7), NSMakeRange(13, 3), NSMakeRange(13, 3));
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "This this is the the way.", [], NSMakeRange(0, 25), 2, NSMakeRange(0, 9), NSMakeRange(0, 4), NSMakeRange(0, 4));
        
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the theway.", [], NSMakeRange(0, 24), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the theway.", [], NSMakeRange(0, 20), 1, NSMakeRange(13, 7), NSMakeRange(13, 3), NSMakeRange(13, 3));
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "This this is the theway.", .WithTransparentBounds, NSMakeRange(0, 20), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "xThis this is the theway.", [], NSMakeRange(0, 25), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", [], "xThis this is the theway.", [], NSMakeRange(1, 20), 1, NSMakeRange(14, 7), NSMakeRange(14, 3), NSMakeRange(14, 3));
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "xThis this is the theway.", [], NSMakeRange(1, 20), 2, NSMakeRange(1, 9), NSMakeRange(1, 4), NSMakeRange(1, 4));
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .CaseInsensitive, "xThis this is the theway.", .WithTransparentBounds, NSMakeRange(1, 20), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        
        complexRegularExpressionTest(NSRegularExpression.escapedPatternForString("\\b(th[a-z]+) \\1\\b"), [], "This this is the the way.", [], NSMakeRange(0, 25), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest(NSRegularExpression.escapedPatternForString("\\b(th[a-z]+) \\1\\b"), [], "x\\b(th[a-z]+) \\1\\by", [], NSMakeRange(0, 19), 1, NSMakeRange(1, 17), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .IgnoreMetacharacters, "This this is the the way.", [], NSMakeRange(0, 25), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("\\b(th[a-z]+) \\1\\b", .IgnoreMetacharacters, "x\\b(th[a-z]+) \\1\\by", [], NSMakeRange(0, 19), 1, NSMakeRange(1, 17), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "This this is the the way.", [], NSMakeRange(0, 25), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "This this is the the way.", [], NSMakeRange(13, 7), 1, NSMakeRange(13, 7), NSMakeRange(13, 3), NSMakeRange(13, 3));
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "This this is the the way.", .WithoutAnchoringBounds, NSMakeRange(13, 7), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [], "this this\nthe the", [], NSMakeRange(0, 17), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("^(th[a-z]+) \\1$", .AnchorsMatchLines, "this this\nthe the", [], NSMakeRange(0, 17), 2, NSMakeRange(0, 9), NSMakeRange(0, 4), NSMakeRange(0, 4));
        complexRegularExpressionTest("^(th[a-z]+) \\1$", .AnchorsMatchLines, "this this\rthe the", [], NSMakeRange(0, 17), 2, NSMakeRange(0, 9), NSMakeRange(0, 4), NSMakeRange(0, 4));
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [.UseUnixLineSeparators, .AnchorsMatchLines], "this this\nthe the", [], NSMakeRange(0, 17), 2, NSMakeRange(0, 9), NSMakeRange(0, 4), NSMakeRange(0, 4));
        complexRegularExpressionTest("^(th[a-z]+) \\1$", [.UseUnixLineSeparators, .AnchorsMatchLines], "this this\rthe the", [], NSMakeRange(0, 17), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "This is the way.", [], NSMakeRange(0, 16), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), 1, NSMakeRange(13, 7), NSMakeRange(13, 3), NSMakeRange(13, 3));
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "Thisxthis is thexthe way.", [], NSMakeRange(0, 25), 1, NSMakeRange(13, 7), NSMakeRange(13, 3), NSMakeRange(13, 3));
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", .CaseInsensitive, "Thisxthis is thexthe way.", [], NSMakeRange(0, 25), 2, NSMakeRange(0, 9), NSMakeRange(0, 4), NSMakeRange(0, 4));
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [], "This\nthis is the\nthe way.", [], NSMakeRange(0, 25), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", .DotMatchesLineSeparators, "This\nthis is the\nthe way.", [], NSMakeRange(0, 25), 1, NSMakeRange(13, 7), NSMakeRange(13, 3), NSMakeRange(13, 3));
        complexRegularExpressionTest("\\b(th[a-z]+).\\1\\b", [.DotMatchesLineSeparators, .CaseInsensitive], "Thisxthis is thexthe way.", [], NSMakeRange(0, 25), 2, NSMakeRange(0, 9), NSMakeRange(0, 4), NSMakeRange(0, 4));
        
        complexRegularExpressionTest("\\b(th[a-z]+).\n#the first expression repeats\n\\1\\b", [], "This this is the the way.", [], NSMakeRange(0, 25), 0, NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("\\b(th[a-z]+).\n#the first expression repeats\n\\1\\b", .AllowCommentsAndWhitespace, "This this is the the way.", [], NSMakeRange(0, 25), 1, NSMakeRange(13, 7), NSMakeRange(13, 3), NSMakeRange(13, 3));
        
        complexRegularExpressionTest("(a(b|c|d)(x|y|z)*|123)", [], "abx", [], NSMakeRange(0, 3), 1, NSMakeRange(0, 3), NSMakeRange(0, 3), NSMakeRange(2, 1));
        complexRegularExpressionTest("(a(b|c|d)(x|y|z)*|123)", [], "123", [], NSMakeRange(0, 3), 1, NSMakeRange(0, 3), NSMakeRange(0, 3), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("a(b|c|d)(x|y|z)*|123", [], "123", [], NSMakeRange(0, 3), 1, NSMakeRange(0, 3), NSMakeRange(NSNotFound, 0), NSMakeRange(NSNotFound, 0));
        complexRegularExpressionTest("a(b|c|d)(x|y|z)*", [], "abx", [], NSMakeRange(0, 3), 1, NSMakeRange(0, 3), NSMakeRange(1, 1), NSMakeRange(2, 1));
        complexRegularExpressionTest("(a(b|c|d)(x|y|z)*|123)", [], "abxy", [], NSMakeRange(0, 4), 1, NSMakeRange(0, 4), NSMakeRange(0, 4), NSMakeRange(3, 1));
        complexRegularExpressionTest("a(b|c|d)(x|y|z)*", [], "abxy", [], NSMakeRange(0, 4), 1, NSMakeRange(0, 4), NSMakeRange(1, 1), NSMakeRange(3, 1));
    }
}