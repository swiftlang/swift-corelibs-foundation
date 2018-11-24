// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

/* NSRegularExpression is a class used to represent and apply regular expressions.  An instance of this class is an immutable representation of a compiled regular expression pattern and various option flags.
*/

import CoreFoundation

extension NSRegularExpression {
    public struct Options : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let caseInsensitive = Options(rawValue: 1 << 0) /* Match letters in the pattern independent of case. */
        public static let allowCommentsAndWhitespace = Options(rawValue: 1 << 1) /* Ignore whitespace and #-prefixed comments in the pattern. */
        public static let ignoreMetacharacters = Options(rawValue: 1 << 2) /* Treat the entire pattern as a literal string. */
        public static let dotMatchesLineSeparators = Options(rawValue: 1 << 3) /* Allow . to match any character, including line separators. */
        public static let anchorsMatchLines = Options(rawValue: 1 << 4) /* Allow ^ and $ to match the start and end of lines. */
        public static let useUnixLineSeparators = Options(rawValue: 1 << 5) /* Treat only \n as a line separator (otherwise, all standard line separators are used). */
        public static let useUnicodeWordBoundaries = Options(rawValue: 1 << 6) /* Use Unicode TR#29 to specify word boundaries (otherwise, traditional regular expression word boundaries are used). */
    }
}

open class NSRegularExpression: NSObject, NSCopying, NSCoding {
    internal var _internal: _CFRegularExpression
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
    
    open func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        aCoder.encode(self.pattern._nsObject, forKey: "NSPattern")
        aCoder.encode(self.options.rawValue._bridgeToObjectiveC(), forKey: "NSOptions")
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        
        guard let pattern = aDecoder.decodeObject(forKey: "NSPattern") as? NSString,
            let options = aDecoder.decodeObject(forKey: "NSOptions") as? NSNumber else {
                return nil
        }
        
        do {
            try self.init(pattern: pattern._swiftObject, options: Options(rawValue: options.uintValue))
        } catch {
            return nil
        }
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSRegularExpression else { return false }
        
        return self === other
            || (self.pattern == other.pattern
                && self.options == other.options)
    }
    
    /* An instance of NSRegularExpression is created from a regular expression pattern and a set of options.  If the pattern is invalid, nil will be returned and an NSError will be returned by reference.  The pattern syntax currently supported is that specified by ICU.
    */
    
    public init(pattern: String, options: Options = []) throws {
        var error: Unmanaged<CFError>?
#if os(macOS) || os(iOS)
        let opt =  _CFRegularExpressionOptions(rawValue: options.rawValue)
#else
        let opt = _CFRegularExpressionOptions(options.rawValue)
#endif
        if let regex = _CFRegularExpressionCreate(kCFAllocatorSystemDefault, pattern._cfObject, opt, &error) {
            _internal = regex
        } else {
            throw error!.takeRetainedValue()
        }
    }
    
    open var pattern: String {
        return _CFRegularExpressionGetPattern(_internal)._swiftObject
    }
    
    open var options: Options {
#if os(macOS) || os(iOS)
        let opt = _CFRegularExpressionGetOptions(_internal).rawValue
#else
        let opt = _CFRegularExpressionGetOptions(_internal)
#endif
    
        return Options(rawValue: opt)
    }
    
    open var numberOfCaptureGroups: Int {
        return _CFRegularExpressionGetNumberOfCaptureGroups(_internal)
    }
    
    /* This class method will produce a string by adding backslash escapes as necessary to the given string, to escape any characters that would otherwise be treated as pattern metacharacters.
    */
    open class func escapedPattern(for string: String) -> String { 
        return _CFRegularExpressionCreateEscapedPattern(string._cfObject)._swiftObject
    }
}

extension NSRegularExpression {

    public struct MatchingOptions : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let reportProgress = MatchingOptions(rawValue: 1 << 0) /* Call the block periodically during long-running match operations. */
        public static let reportCompletion = MatchingOptions(rawValue: 1 << 1) /* Call the block once after the completion of any matching. */
        public static let anchored = MatchingOptions(rawValue: 1 << 2) /* Limit matches to those at the start of the search range. */
        public static let withTransparentBounds = MatchingOptions(rawValue: 1 << 3) /* Allow matching to look beyond the bounds of the search range. */
        public static let withoutAnchoringBounds = MatchingOptions(rawValue: 1 << 4) /* Prevent ^ and $ from automatically matching the beginning and end of the search range. */
        internal static let OmitResult = MatchingOptions(rawValue: 1 << 13)
    }

    public struct MatchingFlags : OptionSet {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let progress = MatchingFlags(rawValue: 1 << 0) /* Set when the block is called to report progress during a long-running match operation. */
        public static let completed = MatchingFlags(rawValue: 1 << 1) /* Set when the block is called after completion of any matching. */
        public static let hitEnd = MatchingFlags(rawValue: 1 << 2) /* Set when the current match operation reached the end of the search range. */
        public static let requiredEnd = MatchingFlags(rawValue: 1 << 3) /* Set when the current match depended on the location of the end of the search range. */
        public static let internalError = MatchingFlags(rawValue: 1 << 4) /* Set when matching failed due to an internal error. */
    }
}

internal class _NSRegularExpressionMatcher {
    var regex: NSRegularExpression
    var block: (NSTextCheckingResult?, NSRegularExpression.MatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Void
    init(regex: NSRegularExpression, block: @escaping (NSTextCheckingResult?, NSRegularExpression.MatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Void) {
        self.regex = regex
        self.block = block
    }
}

internal func _NSRegularExpressionMatch(_ context: UnsafeMutableRawPointer?, ranges: UnsafeMutablePointer<CFRange>?, count: CFIndex, options: _CFRegularExpressionMatchingOptions, stop: UnsafeMutablePointer<_DarwinCompatibleBoolean>) -> Void {
    let matcher = unsafeBitCast(context, to: _NSRegularExpressionMatcher.self)
    if ranges == nil {
#if os(macOS) || os(iOS)
        let opts = options.rawValue
#else
        let opts = options
#endif
        stop.withMemoryRebound(to: ObjCBool.self, capacity: 1, {
            matcher.block(nil, NSRegularExpression.MatchingFlags(rawValue: opts), $0)
        })
    } else {
        let result = ranges!.withMemoryRebound(to: NSRange.self, capacity: count) { rangePtr in
            NSTextCheckingResult.regularExpressionCheckingResultWithRanges(rangePtr, count: count, regularExpression: matcher.regex)
        }
#if os(macOS) || os(iOS)
        let flags = NSRegularExpression.MatchingFlags(rawValue: options.rawValue)
#else
        let flags = NSRegularExpression.MatchingFlags(rawValue: options)
#endif
        stop.withMemoryRebound(to: ObjCBool.self, capacity: 1, {
            matcher.block(result, flags, $0)
        })
    }
}

extension NSRegularExpression {
    
    /* The fundamental matching method on NSRegularExpression is a block iterator.  There are several additional convenience methods, for returning all matches at once, the number of matches, the first match, or the range of the first match.  Each match is specified by an instance of NSTextCheckingResult (of type NSTextCheckingTypeRegularExpression) in which the overall match range is given by the range property (equivalent to range at:0) and any capture group ranges are given by range at: for indexes from 1 to numberOfCaptureGroups.  {NSNotFound, 0} is used if a particular capture group does not participate in the match.
    */
    
    public func enumerateMatches(in string: String, options: NSRegularExpression.MatchingOptions = [], range: NSRange, using block: @escaping (NSTextCheckingResult?, NSRegularExpression.MatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        let matcher = _NSRegularExpressionMatcher(regex: self, block: block)
        withExtendedLifetime(matcher) { (m: _NSRegularExpressionMatcher) -> Void in
#if os(macOS) || os(iOS)
        let opts = _CFRegularExpressionMatchingOptions(rawValue: options.rawValue)
#else
        let opts = _CFRegularExpressionMatchingOptions(options.rawValue)
#endif
            _CFRegularExpressionEnumerateMatchesInString(_internal, string._cfObject, opts, CFRange(range), unsafeBitCast(matcher, to: UnsafeMutableRawPointer.self), _NSRegularExpressionMatch)
        }
    }
    
    public func matches(in string: String, options: NSRegularExpression.MatchingOptions = [], range: NSRange) -> [NSTextCheckingResult] {
        var matches = [NSTextCheckingResult]()
        enumerateMatches(in: string, options: options.subtracting(.reportProgress).subtracting(.reportCompletion), range: range) { (result: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            if let match = result {
                matches.append(match)
            }
        }
        return matches
        
    }
    
    public func numberOfMatches(in string: String, options: NSRegularExpression.MatchingOptions = [], range: NSRange) -> Int {
        var count = 0
        enumerateMatches(in: string, options: options.subtracting(.reportProgress).subtracting(.reportCompletion).union(.OmitResult), range: range) {_,_,_ in 
            count += 1
        }
        return count
    }
    
    public func firstMatch(in string: String, options: NSRegularExpression.MatchingOptions = [], range: NSRange) -> NSTextCheckingResult? {
        var first: NSTextCheckingResult?
        enumerateMatches(in: string, options: options.subtracting(.reportProgress).subtracting(.reportCompletion), range: range) { (result: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            first = result
            stop.pointee = true
        }
        return first
    }
    
    public func rangeOfFirstMatch(in string: String, options: NSRegularExpression.MatchingOptions = [], range: NSRange) -> NSRange {
        var firstRange = NSRange(location: NSNotFound, length: 0)
        enumerateMatches(in: string, options: options.subtracting(.reportProgress).subtracting(.reportCompletion), range: range) { (result: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            if let match = result {
                firstRange = match.range
            } else {
                firstRange = NSRange(location: 0, length: 0)
            }
            stop.pointee = true
        }
        return firstRange
    }
}

/* By default, the block iterator method calls the block precisely once for each match, with a non-nil result and appropriate flags.  The client may then stop the operation by setting the contents of stop to YES.  If the NSMatchingReportProgress option is specified, the block will also be called periodically during long-running match operations, with nil result and NSMatchingProgress set in the flags, at which point the client may again stop the operation by setting the contents of stop to YES.  If the NSMatchingReportCompletion option is specified, the block will be called once after matching is complete, with nil result and NSMatchingCompleted set in the flags, plus any additional relevant flags from among NSMatchingHitEnd, NSMatchingRequiredEnd, or NSMatchingInternalError.  NSMatchingReportProgress and NSMatchingReportCompletion have no effect for methods other than the block iterator.

NSMatchingHitEnd is set in the flags passed to the block if the current match operation reached the end of the search range.  NSMatchingRequiredEnd is set in the flags passed to the block if the current match depended on the location of the end of the search range.  NSMatchingInternalError is set in the flags passed to the block if matching failed due to an internal error (such as an expression requiring exponential memory allocations) without examining the entire search range.

NSMatchingAnchored, NSMatchingWithTransparentBounds, and NSMatchingWithoutAnchoringBounds can apply to any match or replace method.  If NSMatchingAnchored is specified, matches are limited to those at the start of the search range.  If NSMatchingWithTransparentBounds is specified, matching may examine parts of the string beyond the bounds of the search range, for purposes such as word boundary detection, lookahead, etc.  If NSMatchingWithoutAnchoringBounds is specified, ^ and $ will not automatically match the beginning and end of the search range (but will still match the beginning and end of the entire string).  NSMatchingWithTransparentBounds and NSMatchingWithoutAnchoringBounds have no effect if the search range covers the entire string.

NSRegularExpression is designed to be immutable and threadsafe, so that a single instance can be used in matching operations on multiple threads at once.  However, the string on which it is operating should not be mutated during the course of a matching operation (whether from another thread or from within the block used in the iteration).
*/

extension NSRegularExpression {
    
    /* NSRegularExpression also provides find-and-replace methods for both immutable and mutable strings.  The replacement is treated as a template, with $0 being replaced by the contents of the matched range, $1 by the contents of the first capture group, and so on.  Additional digits beyond the maximum required to represent the number of capture groups will be treated as ordinary characters, as will a $ not followed by digits.  Backslash will escape both $ and itself.
    */
    public func stringByReplacingMatches(in string: String, options: NSRegularExpression.MatchingOptions = [], range: NSRange, withTemplate templ: String) -> String {
        var str: String = ""
        let length = string.length
        var previousRange = NSRange(location: 0, length: 0)
        let results = matches(in: string, options: options.subtracting(.reportProgress).subtracting(.reportCompletion), range: range)
        let start = string.utf16.startIndex
        
        for result in results {
            let currentRange = result.range
            let replacement = replacementString(for: result, in: string, offset: 0, template: templ)
            if currentRange.location > NSMaxRange(previousRange) {
                let min = string.utf16.index(start, offsetBy: NSMaxRange(previousRange))
                let max = string.utf16.index(start, offsetBy: currentRange.location)
                str += String(string.utf16[min..<max])!
            }
            str += replacement
            previousRange = currentRange
        }
        
        if length > NSMaxRange(previousRange) {
            let min = string.utf16.index(start, offsetBy: NSMaxRange(previousRange))
            let max = string.utf16.index(start, offsetBy: length)
            str += String(string.utf16[min..<max])!
        }
        
        return str
    }
    
    public func replaceMatches(in string: NSMutableString, options: NSRegularExpression.MatchingOptions = [], range: NSRange, withTemplate templ: String) -> Int {
        let results = matches(in: string._swiftObject, options: options.subtracting(.reportProgress).subtracting(.reportCompletion), range: range)
        var count = 0
        var offset = 0
        for result in results {
            var currentRange = result.range
            let replacement = replacementString(for: result, in: string._swiftObject, offset: offset, template: templ)
            currentRange.location += offset
            
            string.replaceCharacters(in: currentRange, with: replacement)
            offset += replacement.length - currentRange.length
            count += 1
        }
        return count
    }
    
    /* For clients implementing their own replace functionality, this is a method to perform the template substitution for a single result, given the string from which the result was matched, an offset to be added to the location of the result in the string (for example, in case modifications to the string moved the result since it was matched), and a replacement template.
    */
    public func replacementString(for result: NSTextCheckingResult, in string: String, offset: Int, template templ: String) -> String {
        // ??? need to consider what happens if offset takes range out of bounds due to replacement
        struct once {
            static let characterSet = CharacterSet(charactersIn: "\\$")
        }
        let template = templ._nsObject
        var range = template.rangeOfCharacter(from: once.characterSet)
        if range.length > 0 {
            var numberOfDigits = 1
            var orderOfMagnitude = 10
            let numberOfRanges = result.numberOfRanges
            let str = templ._nsObject.mutableCopy(with: nil) as! NSMutableString
            var length = str.length
            while (orderOfMagnitude < numberOfRanges && numberOfDigits < 20) {
                numberOfDigits += 1
                orderOfMagnitude *= 10
            }
            while range.length > 0 {
                var c = str.character(at: range.location)
                if c == unichar(unicodeScalarLiteral: "\\") {
                    str.deleteCharacters(in: range)
                    length -= range.length
                    range.length = 1
                } else if c == unichar(unicodeScalarLiteral: "$") {
                    var groupNumber: Int = NSNotFound
                    var idx = NSMaxRange(range)
                    while idx < length && idx < NSMaxRange(range) + numberOfDigits {
                        c = str.character(at: idx)
                        if c < unichar(unicodeScalarLiteral: "0") || c > unichar(unicodeScalarLiteral: "9") {
                            break
                        }
                        if groupNumber == NSNotFound {
                            groupNumber = 0
                        }
                        
                        groupNumber *= 10
                        groupNumber += Int(c) - Int(unichar(unicodeScalarLiteral: "0"))
                        idx += 1
                    }
                    if groupNumber != NSNotFound {
                        let rangeToReplace = NSRange(location: range.location, length: idx - range.location)
                        var substringRange = NSRange(location: NSNotFound, length: 0)
                        var substring = ""
                        if groupNumber < numberOfRanges {
                            substringRange = result.range(at: groupNumber)
                        }
                        if substringRange.location != NSNotFound {
                            substringRange.location += offset
                        }
                        if substringRange.location != NSNotFound && substringRange.length > 0 {
                            let start = string.utf16.startIndex
                            let min = string.utf16.index(start, offsetBy: substringRange.location)
                            let max = string.utf16.index(start, offsetBy: substringRange.location + substringRange.length)
                            substring = String(string.utf16[min..<max])!
                        }
                        str.replaceCharacters(in: rangeToReplace, with: substring)
                        
                        length += substringRange.length - rangeToReplace.length
                        range.length = substringRange.length
                    }
                }
                if NSMaxRange(range) > length {
                    break
                }
                range = str.rangeOfCharacter(from: once.characterSet, options: [], range: NSRange(location: NSMaxRange(range), length: length - NSMaxRange(range)))
            }
            return str._swiftObject
        }
        return templ
    }
    
    /* This class method will produce a string by adding backslash escapes as necessary to the given string, to escape any characters that would otherwise be treated as template metacharacters. 
    */
    open class func escapedTemplate(for string: String) -> String {
        return _CFRegularExpressionCreateEscapedPattern(string._cfObject)._swiftObject
    }
}

