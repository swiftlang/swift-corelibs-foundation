// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


import CoreFoundation

public typealias unichar = UInt16

extension unichar : UnicodeScalarLiteralConvertible {
    public typealias UnicodeScalarLiteralType = UnicodeScalar
    
    public init(unicodeScalarLiteral scalar: UnicodeScalar) {
        self.init(scalar.value)
    }
}

#if os(OSX) || os(iOS)
internal let kCFStringEncodingMacRoman =  CFStringBuiltInEncodings.macRoman.rawValue
internal let kCFStringEncodingWindowsLatin1 =  CFStringBuiltInEncodings.windowsLatin1.rawValue
internal let kCFStringEncodingISOLatin1 =  CFStringBuiltInEncodings.isoLatin1.rawValue
internal let kCFStringEncodingNextStepLatin =  CFStringBuiltInEncodings.nextStepLatin.rawValue
internal let kCFStringEncodingASCII =  CFStringBuiltInEncodings.ASCII.rawValue
internal let kCFStringEncodingUnicode =  CFStringBuiltInEncodings.unicode.rawValue
internal let kCFStringEncodingUTF8 =  CFStringBuiltInEncodings.UTF8.rawValue
internal let kCFStringEncodingNonLossyASCII =  CFStringBuiltInEncodings.nonLossyASCII.rawValue
internal let kCFStringEncodingUTF16 = CFStringBuiltInEncodings.UTF16.rawValue
internal let kCFStringEncodingUTF16BE =  CFStringBuiltInEncodings.UTF16BE.rawValue
internal let kCFStringEncodingUTF16LE =  CFStringBuiltInEncodings.UTF16LE.rawValue
internal let kCFStringEncodingUTF32 =  CFStringBuiltInEncodings.UTF32.rawValue
internal let kCFStringEncodingUTF32BE =  CFStringBuiltInEncodings.UTF32BE.rawValue
internal let kCFStringEncodingUTF32LE =  CFStringBuiltInEncodings.UTF32LE.rawValue

internal let kCFStringGraphemeCluster = CFStringCharacterClusterType.graphemeCluster
internal let kCFStringComposedCharacterCluster = CFStringCharacterClusterType.composedCharacterCluster
internal let kCFStringCursorMovementCluster = CFStringCharacterClusterType.cursorMovementCluster
internal let kCFStringBackwardDeletionCluster = CFStringCharacterClusterType.backwardDeletionCluster

internal let kCFStringNormalizationFormD = CFStringNormalizationForm.D
internal let kCFStringNormalizationFormKD = CFStringNormalizationForm.KD
internal let kCFStringNormalizationFormC = CFStringNormalizationForm.C
internal let kCFStringNormalizationFormKC = CFStringNormalizationForm.KC
    
#endif

public struct NSStringEncodingConversionOptions : OptionSet {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let allowLossy = NSStringEncodingConversionOptions(rawValue: 1)
    public static let externalRepresentation = NSStringEncodingConversionOptions(rawValue: 2)
    internal static let FailOnPartialEncodingConversion = NSStringEncodingConversionOptions(rawValue: 1 << 20)
}

public struct NSStringEnumerationOptions : OptionSet {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let byLines = NSStringEnumerationOptions(rawValue: 0)
    public static let byParagraphs = NSStringEnumerationOptions(rawValue: 1)
    public static let byComposedCharacterSequences = NSStringEnumerationOptions(rawValue: 2)
    public static let byWords = NSStringEnumerationOptions(rawValue: 3)
    public static let bySentences = NSStringEnumerationOptions(rawValue: 4)
    public static let reverse = NSStringEnumerationOptions(rawValue: 1 << 8)
    public static let substringNotRequired = NSStringEnumerationOptions(rawValue: 1 << 9)
    public static let localized = NSStringEnumerationOptions(rawValue: 1 << 10)
    
    internal static let ForceFullTokens = NSStringEnumerationOptions(rawValue: 1 << 20)
}

extension String : _ObjectTypeBridgeable {
    public func _bridgeToObject() -> NSString {
        return NSString(self)
    }
    
    public static func _forceBridgeFromObject(_ x: NSString, result: inout String?) {
        if x.dynamicType == NSString.self || x.dynamicType == NSMutableString.self {
            result = x._storage
        } else if x.dynamicType == _NSCFString.self {
            let cf = unsafeBitCast(x, to: CFString.self)
            let str = CFStringGetCStringPtr(cf, CFStringEncoding(kCFStringEncodingUTF8))
            if str != nil {
                result = String(cString: str!)
            } else {
                let length = CFStringGetLength(cf)
                let buffer = UnsafeMutablePointer<UniChar>(allocatingCapacity: length)
                CFStringGetCharacters(cf, CFRangeMake(0, length), buffer)
                
                let str = String._fromCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: buffer, count: length))
                buffer.deinitialize(count: length)
                buffer.deallocateCapacity(length)
                result = str
            }
        } else if x.dynamicType == _NSCFConstantString.self {
            let conststr = unsafeBitCast(x, to: _NSCFConstantString.self)
            let str = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: conststr._ptr, count: Int(conststr._length)))
            result = str
        } else {
            let len = x.length
            var characters = [unichar](repeating: 0, count: len)
            result = characters.withUnsafeMutableBufferPointer() { (buffer: inout UnsafeMutableBufferPointer<unichar>) -> String? in
                x.getCharacters(buffer.baseAddress!, range: NSMakeRange(0, len))
                return String._fromCodeUnitSequence(UTF16.self, input: buffer)
            }
        }
    }
    
    public static func _conditionallyBridgeFromObject(_ x: NSString, result: inout String?) -> Bool {
        self._forceBridgeFromObject(x, result: &result)
        return result != nil
    }
}

public struct NSStringCompareOptions : OptionSet {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let caseInsensitiveSearch = NSStringCompareOptions(rawValue: 1)
    public static let literalSearch = NSStringCompareOptions(rawValue: 2)
    public static let backwardsSearch = NSStringCompareOptions(rawValue: 4)
    public static let anchoredSearch = NSStringCompareOptions(rawValue: 8)
    public static let numericSearch = NSStringCompareOptions(rawValue: 64)
    public static let diacriticInsensitiveSearch = NSStringCompareOptions(rawValue: 128)
    public static let widthInsensitiveSearch = NSStringCompareOptions(rawValue: 256)
    public static let forcedOrderingSearch = NSStringCompareOptions(rawValue: 512)
    public static let regularExpressionSearch = NSStringCompareOptions(rawValue: 1024)
    
    internal func _cfValue(_ fixLiteral: Bool = false) -> CFStringCompareFlags {
#if os(OSX) || os(iOS)
        return contains(.literalSearch) || !fixLiteral ? CFStringCompareFlags(rawValue: rawValue) : CFStringCompareFlags(rawValue: rawValue).union(.compareNonliteral)
#else
        return contains(.literalSearch) || !fixLiteral ? CFStringCompareFlags(rawValue) : CFStringCompareFlags(rawValue) | UInt(kCFCompareNonliteral)
#endif
    }
}

internal func _createRegexForPattern(_ pattern: String, _ options: NSRegularExpressionOptions) -> NSRegularExpression? {
    struct local {
        static let __NSRegularExpressionCache: NSCache = {
            let cache = NSCache()
            cache.name = "NSRegularExpressionCache"
            cache.countLimit = 10
            return cache
        }()
    }
    let key = "\(options):\(pattern)"
    if let regex = local.__NSRegularExpressionCache.object(forKey: key._nsObject) {
        return (regex as! NSRegularExpression)
    }
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: options)
        local.__NSRegularExpressionCache.setObject(regex, forKey: key._nsObject)
        return regex
    } catch {
        
    }
    
    return nil
}

internal func _bytesInEncoding(_ str: NSString, _ encoding: NSStringEncoding, _ fatalOnError: Bool, _ externalRep: Bool, _ lossy: Bool) -> UnsafePointer<Int8>? {
    let theRange = NSMakeRange(0, str.length)
    var cLength = 0
    var used = 0
    var options: NSStringEncodingConversionOptions = []
    if externalRep {
        options.formUnion(.externalRepresentation)
    }
    if lossy {
        options.formUnion(.allowLossy)
    }
    if !str.getBytes(nil, maxLength: Int.max - 1, usedLength: &cLength, encoding: encoding, options: options, range: theRange, remaining: nil) {
        if fatalOnError {
            fatalError("Conversion on encoding failed")
        }
        return nil
    }
    
    let buffer = malloc(cLength + 1)!
    if !str.getBytes(buffer, maxLength: cLength, usedLength: &used, encoding: encoding, options: options, range: theRange, remaining: nil) {
        fatalError("Internal inconsistency; previously claimed getBytes returned success but failed with similar invocation")
    }
    
    UnsafeMutablePointer<Int8>(buffer).advanced(by: cLength).initialize(with: 0)
    
    return UnsafePointer<Int8>(buffer) // leaked and should be autoreleased via a NSData backing but we cannot here
}

internal func isALineSeparatorTypeCharacter(_ ch: unichar) -> Bool {
    if ch > 0x0d && ch < 0x0085 { /* Quick test to cover most chars */
        return false
    }
    return ch == 0x0a || ch == 0x0d || ch == 0x0085 || ch == 0x2028 || ch == 0x2029
}

internal func isAParagraphSeparatorTypeCharacter(_ ch: unichar) -> Bool {
    if ch > 0x0d && ch < 0x2029 { /* Quick test to cover most chars */
        return false
    }
    return ch == 0x0a || ch == 0x0d || ch == 0x2029
}

public class NSString : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFStringGetTypeID())
    internal var _storage: String
    
    public var length: Int {
        guard self.dynamicType === NSString.self || self.dynamicType === NSMutableString.self else {
            NSRequiresConcreteImplementation()
        }
        return _storage.utf16.count
    }
    
    public func character(at index: Int) -> unichar {
        guard self.dynamicType === NSString.self || self.dynamicType === NSMutableString.self else {
            NSRequiresConcreteImplementation()
        }
        let start = _storage.utf16.startIndex
        return _storage.utf16[start.advanced(by: index)]
    }
    
    public override convenience init() {
        let characters = Array<unichar>(repeating: 0, count: 1)
        self.init(characters: characters, length: 0)
    }
    
    internal init(_ string: String) {
        _storage = string
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            let archiveVersion = aDecoder.versionForClassName("NSString")
            if archiveVersion == 1 {
                var length = 0
                let buffer = aDecoder.decodeBytesWithReturnedLength(&length)
                self.init(bytes: buffer, length: length, encoding: NSUTF8StringEncoding)
            } else {
                aDecoder.failWithError(NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.CoderReadCorruptError.rawValue, userInfo: [
                    "NSDebugDescription": "NSString cannot decode class version \(archiveVersion)"
                    ]))
                return nil
            }
        } else if aDecoder.dynamicType == NSKeyedUnarchiver.self || aDecoder.containsValueForKey("NS.string") {
            let str = aDecoder._decodePropertyListForKey("NS.string") as! String
            self.init(string: str)
        } else {
            var length = 0
            let buffer = UnsafeMutablePointer<Void>(aDecoder.decodeBytesForKey("NS.bytes", returnedLength: &length)!)
            self.init(bytes: buffer, length: length, encoding: NSUTF8StringEncoding)
        }
    }
    
    public required convenience init(string aString: String) {
        self.init(aString)
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(_ zone: NSZone) -> AnyObject {
        return self
    }
    
    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }
    
    public func mutableCopyWithZone(_ zone: NSZone) -> AnyObject {
        if self.dynamicType === NSString.self || self.dynamicType === NSMutableString.self {
            if let contents = _fastContents {
                return NSMutableString(characters: contents, length: length)
            }
        }
        let characters = UnsafeMutablePointer<unichar>(allocatingCapacity: length)
        getCharacters(characters, range: NSMakeRange(0, length))
        let result = NSMutableString(characters: characters, length: length)
        characters.deinitialize()
        characters.deallocateCapacity(length)
        return result
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func encodeWithCoder(_ aCoder: NSCoder) {
        if let aKeyedCoder = aCoder as? NSKeyedArchiver {
            aKeyedCoder._encodePropertyList(self, forKey: "NS.string")
        } else {
            aCoder.encodeObject(self)
        }
    }
    
    public init(characters: UnsafePointer<unichar>, length: Int) {
        _storage = String._fromWellFormedCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: characters, count: length))
    }
    
    public required convenience init(unicodeScalarLiteral value: StaticString) {
        self.init(stringLiteral: value)
    }
    
    public required convenience init(extendedGraphemeClusterLiteral value: StaticString) {
        self.init(stringLiteral: value)
    }
    
    public required init(stringLiteral value: StaticString) {
        _storage = String(value)
    }
    
    internal var _fastCStringContents: UnsafePointer<Int8>? {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            if _storage._core.isASCII {
                return unsafeBitCast(_storage._core.startASCII, to: UnsafePointer<Int8>.self)
            }
        }
        return nil
    }
    
    internal var _fastContents: UnsafePointer<UniChar>? {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            if !_storage._core.isASCII {
                return unsafeBitCast(_storage._core.startUTF16, to: UnsafePointer<UniChar>.self)
            }
        }
        return nil
    }
    
    internal var _encodingCantBeStoredInEightBitCFString: Bool {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return !_storage._core.isASCII
        }
        return false
    }
    
    override public var _cfTypeID: CFTypeID {
        return CFStringGetTypeID()
    }
  
    public override func isEqual(_ object: AnyObject?) -> Bool {
        guard let string = (object as? NSString)?._swiftObject else { return false }
        return self.isEqual(to: string)
    }
    
    public override var description: String {
        return _swiftObject
    }
    
    public override var hash: Int {
        return Int(bitPattern:CFStringHashNSString(self._cfObject))
    }
}

extension NSString {
    public func getCharacters(_ buffer: UnsafeMutablePointer<unichar>, range: NSRange) {
        for idx in 0..<range.length {
            buffer[idx] = character(at: idx + range.location)
        }
    }
    
    public func substring(from: Int) -> String {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return String(_storage.utf16.suffix(from: _storage.utf16.startIndex.advanced(by: from)))
        } else {
            return substring(with: NSMakeRange(from, length - from))
        }
    }
    
    public func substring(to: Int) -> String {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return String(_storage.utf16.prefix(upTo: _storage.utf16.startIndex
            .advanced(by: to)))
        } else {
            return substring(with: NSMakeRange(0, to))
        }
    }
    
    public func substring(with range: NSRange) -> String {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            let start = _storage.utf16.startIndex
            let min = start.advanced(by: range.location)
            let max = start.advanced(by: range.location + range.length)
            return String(_storage.utf16[min..<max])
        } else {
            let buff = UnsafeMutablePointer<unichar>(allocatingCapacity: range.length)
            getCharacters(buff, range: range)
            let result = String(buff)
            buff.deinitialize()
            buff.deallocateCapacity(range.length)
            return result
        }
    }
    
    public func compare(_ string: String) -> NSComparisonResult {
        return compare(string, options: [], range: NSMakeRange(0, length))
    }
    
    public func compare(_ string: String, options mask: NSStringCompareOptions) -> NSComparisonResult {
        return compare(string, options: mask, range: NSMakeRange(0, length))
    }
    
    public func compare(_ string: String, options mask: NSStringCompareOptions, range compareRange: NSRange) -> NSComparisonResult {
        return compare(string, options: mask, range: compareRange, locale: nil)
    }
    
    public func compare(_ string: String, options mask: NSStringCompareOptions, range compareRange: NSRange, locale: AnyObject?) -> NSComparisonResult {
        var res: CFComparisonResult
        if let loc = locale {
            res = CFStringCompareWithOptionsAndLocale(_cfObject, string._cfObject, CFRange(compareRange), mask._cfValue(true), (loc as! NSLocale)._cfObject)
        } else {
            res = CFStringCompareWithOptionsAndLocale(_cfObject, string._cfObject, CFRange(compareRange), mask._cfValue(true), nil)
        }
        return NSComparisonResult._fromCF(res)
    }
    
    public func caseInsensitiveCompare(_ string: String) -> NSComparisonResult {
        return compare(string, options: .caseInsensitiveSearch, range: NSMakeRange(0, length))
    }
    
    public func localizedCompare(_ string: String) -> NSComparisonResult {
        return compare(string, options: [], range: NSMakeRange(0, length), locale: NSLocale.currentLocale())
    }
    
    public func localizedCaseInsensitiveCompare(_ string: String) -> NSComparisonResult {
        return compare(string, options: .caseInsensitiveSearch, range: NSMakeRange(0, length), locale: NSLocale.currentLocale())
    }
    
    public func localizedStandardCompare(_ string: String) -> NSComparisonResult {
        return compare(string, options: [.caseInsensitiveSearch, .numericSearch, .widthInsensitiveSearch, .forcedOrderingSearch], range: NSMakeRange(0, length), locale: NSLocale.currentLocale())
    }
    
    public func isEqual(to aString: String) -> Bool {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return _storage == aString
        } else {
            return length == aString.length && compare(aString, options: .literalSearch, range: NSMakeRange(0, length)) == .orderedSame
        }
    }
    
    public func hasPrefix(_ str: String) -> Bool {
        return range(of: str, options: .anchoredSearch, range: NSMakeRange(0, length)).location != NSNotFound
    }
    
    public func hasSuffix(_ str: String) -> Bool {
        return range(of: str, options: [.anchoredSearch, .backwardsSearch], range: NSMakeRange(0, length)).location != NSNotFound
    }
    
    public func commonPrefix(with str: String, options mask: NSStringCompareOptions = []) -> String {
        var currentSubstring: CFMutableString?
        let isLiteral = mask.contains(.literalSearch)
        var lastMatch = NSRange()
        let selfLen = length
        let otherLen = str.length
        var low = 0
        var high = selfLen
        var probe = (low + high) / 2
        if (probe > otherLen) {
            probe = otherLen // A little heuristic to avoid some extra work
        }
        if selfLen == 0 || otherLen == 0 {
            return ""
        }
        var numCharsBuffered = 0
        var arrayBuffer = [unichar](repeating: 0, count: 100)
        let other = str._nsObject
        return arrayBuffer.withUnsafeMutablePointerOrAllocation(selfLen, fastpath: UnsafeMutablePointer<unichar>(_fastContents)) { (selfChars: UnsafeMutablePointer<unichar>) -> String in
            // Now do the binary search. Note that the probe value determines the length of the substring to check.
            while true {
                let range = NSMakeRange(0, isLiteral ? probe + 1 : NSMaxRange(rangeOfComposedCharacterSequence(at: probe))) // Extend the end of the composed char sequence
                if range.length > numCharsBuffered { // Buffer more characters if needed
                    getCharacters(selfChars, range: NSMakeRange(numCharsBuffered, range.length - numCharsBuffered))
                    numCharsBuffered = range.length
                }
                if currentSubstring == nil {
                    currentSubstring = CFStringCreateMutableWithExternalCharactersNoCopy(kCFAllocatorSystemDefault, selfChars, range.length, range.length, kCFAllocatorNull)
                } else {
                    CFStringSetExternalCharactersNoCopy(currentSubstring, selfChars, range.length, range.length)
                }
                if other.range(of: currentSubstring!._swiftObject, options: mask.union(.anchoredSearch), range: NSMakeRange(0, otherLen)).length != 0 { // Match
                    lastMatch = range
                    low = probe + 1
                } else {
                    high = probe
                }
                if low >= high {
                    break
                }
                probe = (low + high) / 2
            }
            return lastMatch.length != 0 ? substring(with: lastMatch) : ""
        }
    }
    
    public func contains(_ str: String) -> Bool {
        return range(of: str, options: [], range: NSMakeRange(0, length), locale: nil).location != NSNotFound
    }
    
    public func localizedCaseInsensitiveContains(_ str: String) -> Bool {
        return range(of: str, options: .caseInsensitiveSearch, range: NSMakeRange(0, length), locale: NSLocale.currentLocale()).location != NSNotFound
    }
    
    public func localizedStandardContains(_ str: String) -> Bool {
        return range(of: str, options: [.caseInsensitiveSearch, .diacriticInsensitiveSearch], range: NSMakeRange(0, length), locale: NSLocale.currentLocale()).location != NSNotFound
    }
    
    public func localizedStandardRange(of str: String) -> NSRange {
        return range(of: str, options: [.caseInsensitiveSearch, .diacriticInsensitiveSearch], range: NSMakeRange(0, length), locale: NSLocale.currentLocale())
    }
    
    public func range(of searchString: String) -> NSRange {
        return range(of: searchString, options: [], range: NSMakeRange(0, length), locale: nil)
    }
    
    public func range(of searchString: String, options mask: NSStringCompareOptions = []) -> NSRange {
        return range(of: searchString, options: mask, range: NSMakeRange(0, length), locale: nil)
    }
    
    public func range(of searchString: String, options mask: NSStringCompareOptions = [], range searchRange: NSRange) -> NSRange {
        return range(of: searchString, options: mask, range: searchRange, locale: nil)
    }
    
    internal func _rangeOfRegularExpressionPattern(regex pattern: String, options mask: NSStringCompareOptions, range searchRange: NSRange, locale: NSLocale?) -> NSRange {
        var matchedRange = NSMakeRange(NSNotFound, 0)
        let regexOptions: NSRegularExpressionOptions = mask.contains(.caseInsensitiveSearch) ? .caseInsensitive : []
        let matchingOptions: NSMatchingOptions = mask.contains(.anchoredSearch) ? .anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            matchedRange = regex.rangeOfFirstMatch(in: _swiftObject, options: matchingOptions, range: searchRange)
        }
        return matchedRange
    }
    
    public func range(of searchString: String, options mask: NSStringCompareOptions = [], range searchRange: NSRange, locale: NSLocale?) -> NSRange {
        let findStrLen = searchString.length
        let len = length
        
        precondition(searchRange.length <= len && searchRange.location <= len - searchRange.length, "Bounds Range {\(searchRange.location), \(searchRange.length)} out of bounds; string length \(len)")
        
        if mask.contains(.regularExpressionSearch) {
            return _rangeOfRegularExpressionPattern(regex: searchString, options: mask, range:searchRange, locale: locale)
        }
        
        if searchRange.length == 0 || findStrLen == 0 { // ??? This last item can't be here for correct Unicode compares
            return NSMakeRange(NSNotFound, 0)
        }
        
        var result = CFRange()
        let res = withUnsafeMutablePointer(&result) { (rangep: UnsafeMutablePointer<CFRange>) -> Bool in
            if let loc = locale {
                return CFStringFindWithOptionsAndLocale(_cfObject, searchString._cfObject, CFRange(searchRange), mask._cfValue(true), loc._cfObject, rangep)
            } else {
                return CFStringFindWithOptionsAndLocale(_cfObject, searchString._cfObject, CFRange(searchRange), mask._cfValue(true), nil, rangep)
            }
        }
        if res {
            return NSMakeRange(result.location, result.length)
        } else {
            return NSMakeRange(NSNotFound, 0)
        }
    }
    
    public func rangeOfCharacter(from searchSet: NSCharacterSet) -> NSRange {
        return rangeOfCharacter(from: searchSet, options: [], range: NSMakeRange(0, length))
    }
    
    public func rangeOfCharacter(from searchSet: NSCharacterSet, options mask: NSStringCompareOptions = []) -> NSRange {
        return rangeOfCharacter(from: searchSet, options: mask, range: NSMakeRange(0, length))
    }
    
    public func rangeOfCharacter(from searchSet: NSCharacterSet, options mask: NSStringCompareOptions = [], range searchRange: NSRange) -> NSRange {
        let len = length
        
        precondition(searchRange.length <= len && searchRange.location <= len - searchRange.length, "Bounds Range {\(searchRange.location), \(searchRange.length)} out of bounds; string length \(len)")
        
        var result = CFRange()
        let res = withUnsafeMutablePointer(&result) { (rangep: UnsafeMutablePointer<CFRange>) -> Bool in
            return CFStringFindCharacterFromSet(_cfObject, searchSet._cfObject, CFRange(searchRange), mask._cfValue(), rangep)
        }
        if res {
            return NSMakeRange(result.location, result.length)
        } else {
            return NSMakeRange(NSNotFound, 0)
        }
    }
    
    public func rangeOfComposedCharacterSequence(at index: Int) -> NSRange {
        let range = CFStringGetRangeOfCharacterClusterAtIndex(_cfObject, index, kCFStringComposedCharacterCluster)
        return NSMakeRange(range.location, range.length)
    }
    
    public func rangeOfComposedCharacterSequences(for range: NSRange) -> NSRange {
        let length = self.length
        var start: Int
        var end: Int
        if range.location == length {
            start = length
        } else {
            start = rangeOfComposedCharacterSequence(at: range.location).location
        }
        var endOfRange = NSMaxRange(range)
        if endOfRange == length {
            end = length
        } else {
            if range.length > 0 {
                endOfRange = endOfRange - 1 // We want 0-length range to be treated same as 1-length range.
            }
            end = NSMaxRange(rangeOfComposedCharacterSequence(at: endOfRange))
        }
        return NSMakeRange(start, end - start)
    }
    
    public func appending(_ aString: String) -> String {
        return _swiftObject + aString
    }

    public var doubleValue: Double {
        var start: Int = 0
        var result = 0.0
        let _ = _swiftObject.scan(NSCharacterSet.whitespaces(), locale: nil, locationToScanFrom: &start) { (value: Double) -> Void in
            result = value
        }
        return result
    }

    public var floatValue: Float {
        var start: Int = 0
        var result: Float = 0.0
        let _ = _swiftObject.scan(NSCharacterSet.whitespaces(), locale: nil, locationToScanFrom: &start) { (value: Float) -> Void in
            result = value
        }
        return result
    }

    public var intValue: Int32 {
        return NSScanner(string: _swiftObject).scanInt() ?? 0
    }

    public var integerValue: Int {
        let scanner = NSScanner(string: _swiftObject)
        var value: Int = 0
        let _ = scanner.scanInteger(&value)
        return value
    }

    public var longLongValue: Int64 {
        return NSScanner(string: _swiftObject).scanLongLong() ?? 0
    }

    public var boolValue: Bool {
        let scanner = NSScanner(string: _swiftObject)
        // skip initial whitespace if present
        let _ = scanner.scanCharactersFromSet(NSCharacterSet.whitespaces())
        // scan a single optional '+' or '-' character, followed by zeroes
        if scanner.scanString(string: "+") == nil {
            let _ = scanner.scanString(string: "-")
        }
        // scan any following zeroes
        let _ = scanner.scanCharactersFromSet(NSCharacterSet(charactersIn: "0"))
        return scanner.scanCharactersFromSet(NSCharacterSet(charactersIn: "tTyY123456789")) != nil
    }

    public var uppercased: String {
        return uppercased(with: nil)
    }

    public var lowercased: String {
        return lowercased(with: nil)
    }
    
    public var capitalized: String {
        return capitalized(with: nil)
    }
    
    public var localizedUppercase: String {
        return uppercased(with: NSLocale.currentLocale())
    }
    
    public var localizedLowercase: String {
        return lowercased(with: NSLocale.currentLocale())
    }
    
    public var localizedCapitalized: String {
        return capitalized(with: NSLocale.currentLocale())
    }
    
    public func uppercased(with locale: NSLocale?) -> String {
        let mutableCopy = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, self._cfObject)!
        CFStringUppercase(mutableCopy, locale?._cfObject ?? nil)
        return mutableCopy._swiftObject
    }

    public func lowercased(with locale: NSLocale?) -> String {
        let mutableCopy = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, self._cfObject)!
        CFStringLowercase(mutableCopy, locale?._cfObject ?? nil)
        return mutableCopy._swiftObject
    }
    
    public func capitalized(with locale: NSLocale?) -> String {
        let mutableCopy = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, self._cfObject)!
        CFStringCapitalize(mutableCopy, locale?._cfObject ?? nil)
        return mutableCopy._swiftObject
    }
    
    internal func _getBlockStart(_ startPtr: UnsafeMutablePointer<Int>?, end endPtr: UnsafeMutablePointer<Int>?, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>?, forRange range: NSRange, stopAtLineSeparators line: Bool) {
        let len = length
        var ch: unichar
        
        precondition(range.length <= len && range.location < len - range.length, "Range {\(range.location), \(range.length)} is out of bounds of length \(len)")
        
        if range.location == 0 && range.length == len && contentsEndPtr == nil { // This occurs often
            startPtr?.pointee = 0
            endPtr?.pointee = range.length
            return
        }
        /* Find the starting point first */
        if startPtr != nil {
            var start: Int = 0
            if range.location == 0 {
                start = 0
            } else {
                var buf = _NSStringBuffer(string: self, start: range.location, end: len)
                /* Take care of the special case where start happens to fall right between \r and \n */
                ch = buf.currentCharacter
                buf.rewind()
                if ch == 0x0a && buf.currentCharacter == 0x0d {
                    buf.rewind()
                }
                
                while true {
                    if line ? isALineSeparatorTypeCharacter(buf.currentCharacter) : isAParagraphSeparatorTypeCharacter(buf.currentCharacter) {
                        start = buf.location + 1
                        break
                    } else if buf.location <= 0 {
                        start = 0
                        break
                    } else {
                        buf.rewind()
                    }
                }
                startPtr!.pointee = start
            }
        }

        if (endPtr != nil || contentsEndPtr != nil) {
            var endOfContents = 1
            var lineSeparatorLength = 1
            var buf = _NSStringBuffer(string: self, start: NSMaxRange(range) - (range.length > 0 ? 1 : 0), end: len)
            /* First look at the last char in the range (if the range is zero length, the char after the range) to see if we're already on or within a end of line sequence... */
            ch = buf.currentCharacter
            if ch == 0x0a {
                endOfContents = buf.location
                buf.rewind()
                if buf.currentCharacter == 0x0d {
                    lineSeparatorLength = 2
                    endOfContents -= 1
                }
            } else {
                while true {
                    if line ? isALineSeparatorTypeCharacter(ch) : isAParagraphSeparatorTypeCharacter(ch) {
                        endOfContents = buf.location /* This is actually end of contentsRange */
                        buf.advance() /* OK for this to go past the end */
                        if ch == 0x0d && buf.currentCharacter == 0x0a {
                            lineSeparatorLength = 2
                        }
                        break
                    } else if buf.location == len {
                        endOfContents = len
                        lineSeparatorLength = 0
                        break
                    } else {
                        buf.advance()
                        ch = buf.currentCharacter
                    }
                }
            }
            
            contentsEndPtr?.pointee = endOfContents
            endPtr?.pointee = endOfContents + lineSeparatorLength
        }
    }
    
    public func getLineStart(_ startPtr: UnsafeMutablePointer<Int>?, end lineEndPtr: UnsafeMutablePointer<Int>?, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>?, for range: NSRange) {
        _getBlockStart(startPtr, end: lineEndPtr, contentsEnd: contentsEndPtr, forRange: range, stopAtLineSeparators: true)
    }
    
    public func lineRange(for range: NSRange) -> NSRange {
        var start = 0
        var lineEnd = 0
        getLineStart(&start, end: &lineEnd, contentsEnd: nil, for: range)
        return NSMakeRange(start, lineEnd - start)
    }
    
    public func getParagraphStart(_ startPtr: UnsafeMutablePointer<Int>?, end parEndPtr: UnsafeMutablePointer<Int>?, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>?, for range: NSRange) {
        _getBlockStart(startPtr, end: parEndPtr, contentsEnd: contentsEndPtr, forRange: range, stopAtLineSeparators: false)
    }
    
    public func paragraphRange(for range: NSRange) -> NSRange {
        var start = 0
        var parEnd = 0
        getParagraphStart(&start, end: &parEnd, contentsEnd: nil, for: range)
        return NSMakeRange(start, parEnd - start)
    }
    
    public func enumerateSubstrings(in range: NSRange, options opts: NSStringEnumerationOptions = [], using block: (String?, NSRange, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        NSUnimplemented()
    }
    
    public func enumerateLines(_ block: (String, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateSubstrings(in: NSMakeRange(0, length), options:.byLines) { substr, substrRange, enclosingRange, stop in
            block(substr!, stop)
        }
    }
    
    public var utf8String: UnsafePointer<Int8>? {
        return _bytesInEncoding(self, NSUTF8StringEncoding, false, false, false)
    }
    
    public var fastestEncoding: UInt {
        return NSUnicodeStringEncoding
    }
    
    public var smallestEncoding: UInt {
        if canBeConverted(to: NSASCIIStringEncoding) {
            return NSASCIIStringEncoding
        }
        return NSUnicodeStringEncoding
    }
    
    public func data(using encoding: UInt, allowLossyConversion lossy: Bool) -> NSData? {
        let len = length
        var reqSize = 0
        
        let cfStringEncoding = CFStringConvertNSStringEncodingToEncoding(encoding)
        if !CFStringIsEncodingAvailable(cfStringEncoding) {
            return nil
        }
        
        let convertedLen = __CFStringEncodeByteStream(_cfObject, 0, len, true, cfStringEncoding, lossy ? (encoding == NSASCIIStringEncoding ? 0xFF : 0x3F) : 0, nil, 0, &reqSize)
        if convertedLen != len {
            return nil 	// Not able to do it all...
        }
        
        if let data = NSMutableData(length: reqSize) {
            if 0 < reqSize {
                if __CFStringEncodeByteStream(_cfObject, 0, len, true, cfStringEncoding, lossy ? (encoding == NSASCIIStringEncoding ? 0xFF : 0x3F) : 0, UnsafeMutablePointer<UInt8>(data.mutableBytes), reqSize, &reqSize) == convertedLen {
                    data.length = reqSize
                } else {
                    fatalError("didn't convert all characters")
                }
                return data
            }
        }
        return nil
    }
    
    public func data(using encoding: UInt) -> NSData? {
        return data(using: encoding, allowLossyConversion: false)
    }
    
    public func canBeConverted(to encoding: UInt) -> Bool {
        if encoding == NSUnicodeStringEncoding || encoding == NSNonLossyASCIIStringEncoding || encoding == NSUTF8StringEncoding {
            return true
        }
        return __CFStringEncodeByteStream(_cfObject, 0, length, false, CFStringConvertNSStringEncodingToEncoding(encoding), 0, nil, 0, nil) == length
    }
   
    public func cString(using encoding: UInt) -> UnsafePointer<Int8>? { 
        return _bytesInEncoding(self, encoding, false, false, false)
    }
    
    public func getCString(_ buffer: UnsafeMutablePointer<Int8>, maxLength maxBufferCount: Int, encoding: UInt) -> Bool {
        var used = 0
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            if _storage._core.isASCII {
                used = min(self.length, maxBufferCount - 1)
                buffer.moveAssignFrom(unsafeBitCast(_storage._core.startASCII, to: UnsafeMutablePointer<Int8>.self)
                    , count: used)
                buffer.advanced(by: used).initialize(with: 0)
                return true
            }
        }
        if getBytes(UnsafeMutablePointer<Void>(buffer), maxLength: maxBufferCount, usedLength: &used, encoding: encoding, options: [], range: NSMakeRange(0, self.length), remaining: nil) {
            buffer.advanced(by: used).initialize(with: 0)
            return true
        }
        return false
    }
    
    public func getBytes(_ buffer: UnsafeMutablePointer<Void>?, maxLength maxBufferCount: Int, usedLength usedBufferCount: UnsafeMutablePointer<Int>?, encoding: UInt, options: NSStringEncodingConversionOptions = [], range: NSRange, remaining leftover: NSRangePointer?) -> Bool {
        var totalBytesWritten = 0
        var numCharsProcessed = 0
        let cfStringEncoding = CFStringConvertNSStringEncodingToEncoding(encoding)
        var result = true
        if length > 0 {
            if CFStringIsEncodingAvailable(cfStringEncoding) {
                let lossyOk = options.contains(.allowLossy)
                let externalRep = options.contains(.externalRepresentation)
                let failOnPartial = options.contains(.FailOnPartialEncodingConversion)
                numCharsProcessed = __CFStringEncodeByteStream(_cfObject, range.location, range.length, externalRep, cfStringEncoding, lossyOk ? (encoding == NSASCIIStringEncoding ? 0xFF : 0x3F) : 0, UnsafeMutablePointer<UInt8>(buffer), buffer != nil ? maxBufferCount : 0, &totalBytesWritten)
                if (failOnPartial && numCharsProcessed < range.length) || numCharsProcessed == 0 {
                    result = false
                }
            } else {
                result = false /* ??? Need other encodings */
            }
        }
        usedBufferCount?.pointee = totalBytesWritten
        leftover?.pointee = NSMakeRange(range.location + numCharsProcessed, range.length - numCharsProcessed)
        return result
    }
    
    public func maximumLengthOfBytes(using enc: UInt) -> Int {
        let cfEnc = CFStringConvertNSStringEncodingToEncoding(enc)
        let result = CFStringGetMaximumSizeForEncoding(length, cfEnc)
        return result == kCFNotFound ? 0 : result
    }
    
    public func lengthOfBytes(using enc: UInt) -> Int {
        let len = length
        var numBytes: CFIndex = 0
        let cfEnc = CFStringConvertNSStringEncodingToEncoding(enc)
        let convertedLen = __CFStringEncodeByteStream(_cfObject, 0, len, false, cfEnc, 0, nil, 0, &numBytes)
        return convertedLen != len ? 0 : numBytes
    }
    
    public class func availableStringEncodings() -> UnsafePointer<UInt> {
        struct once {
            static let encodings: UnsafePointer<UInt> = {
                let cfEncodings = CFStringGetListOfAvailableEncodings()!
                var idx = 0
                var numEncodings = 0
                
                while cfEncodings.advanced(by: idx).pointee != kCFStringEncodingInvalidId {
                    idx += 1
                    numEncodings += 1
                }
                
                let theEncodingList = UnsafeMutablePointer<NSStringEncoding>(allocatingCapacity: numEncodings + 1)
                theEncodingList.advanced(by: numEncodings).pointee = 0 // Terminator
                
                numEncodings -= 1
                while numEncodings >= 0 {
                    theEncodingList.advanced(by: numEncodings).pointee = CFStringConvertEncodingToNSStringEncoding(cfEncodings.advanced(by: numEncodings).pointee)
                    numEncodings -= 1
                }
                
                return UnsafePointer<UInt>(theEncodingList)
            }()
        }
        return once.encodings
    }
    
    public class func localizedName(of encoding: UInt) -> String {
        if let theString = CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding)) {
            // TODO: read the localized version from the Foundation "bundle"
            return theString._swiftObject
        }
        
        return ""
    }
    
    public class func defaultCStringEncoding() -> UInt {
        return CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding())
    }
    
    public var decomposedStringWithCanonicalMapping: String {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)!
        CFStringReplaceAll(string, self._cfObject)
        CFStringNormalize(string, kCFStringNormalizationFormD)
        return string._swiftObject
    }
    
    public var precomposedStringWithCanonicalMapping: String {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)!
        CFStringReplaceAll(string, self._cfObject)
        CFStringNormalize(string, kCFStringNormalizationFormC)
        return string._swiftObject
    }
    
    public var decomposedStringWithCompatibilityMapping: String {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)!
        CFStringReplaceAll(string, self._cfObject)
        CFStringNormalize(string, kCFStringNormalizationFormKD)
        return string._swiftObject
    }
    
    public var precomposedStringWithCompatibilityMapping: String {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)!
        CFStringReplaceAll(string, self._cfObject)
        CFStringNormalize(string, kCFStringNormalizationFormKC)
        return string._swiftObject
    }
    
    public func components(separatedBy separator: String) -> [String] {
        let len = length
        var lrange = range(of: separator, options: [], range: NSMakeRange(0, len))
        if lrange.length == 0 {
            return [_swiftObject]
        } else {
            var array = [String]()
            var srange = NSMakeRange(0, len)
            while true {
                let trange = NSMakeRange(srange.location, lrange.location - srange.location)
                array.append(substring(with: trange))
                srange.location = lrange.location + lrange.length
                srange.length = len - srange.location
                lrange = range(of: separator, options: [], range: srange)
                if lrange.length == 0 {
                    break
                }
            }
            array.append(substring(with: srange))
            return array
        }
    }
    
    public func components(separatedBy separator: NSCharacterSet) -> [String] {
        let len = length
        var range = rangeOfCharacter(from: separator, options: [], range: NSMakeRange(0, len))
        if range.length == 0 {
            return [_swiftObject]
        } else {
            var array = [String]()
            var srange = NSMakeRange(0, len)
            while true {
                let trange = NSMakeRange(srange.location, range.location - srange.location)
                array.append(substring(with: trange))
                srange.location = range.location + range.length
                srange.length = len - srange.location
                range = rangeOfCharacter(from: separator, options: [], range: srange)
                if range.length == 0 {
                    break
                }
            }
            array.append(substring(with: srange))
            return array
        }
    }
    
    public func trimmingCharacters(in set: NSCharacterSet) -> String {
        let len = length
        var buf = _NSStringBuffer(string: self, start: 0, end: len)
        while !buf.isAtEnd && set.characterIsMember(buf.currentCharacter) {
            buf.advance()
        }
        
        let startOfNonTrimmedRange = buf.location // This points at the first char not in the set
        
        if startOfNonTrimmedRange == len { // Note that this also covers the len == 0 case, which is important to do here before the len-1 in the next line.
            return ""
        } else if startOfNonTrimmedRange < len - 1 {
            buf.location = len - 1
            while set.characterIsMember(buf.currentCharacter) && buf.location >= startOfNonTrimmedRange {
                buf.rewind()
            }
            let endOfNonTrimmedRange = buf.location
            return substring(with: NSMakeRange(startOfNonTrimmedRange, endOfNonTrimmedRange + 1 - startOfNonTrimmedRange))
        } else {
            return substring(with: NSMakeRange(startOfNonTrimmedRange, 1))
        }
    }
    
    public func padding(toLength newLength: Int, withPad padString: String, startingAt padIndex: Int) -> String {
        let len = length
        if newLength <= len {	// The simple cases (truncation)
            return newLength == len ? _swiftObject : substring(with: NSMakeRange(0, newLength))
        }
        let padLen = padString.length
        if padLen < 1 {
            fatalError("empty pad string")
        }
        if padIndex >= padLen {
            fatalError("out of range padIndex")
        }
        
        let mStr = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, _cfObject)!
        CFStringPad(mStr, padString._cfObject, newLength, padIndex)
        return mStr._swiftObject
    }
    
    public func folding(_ options: NSStringCompareOptions = [], locale: NSLocale?) -> String {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)!
        CFStringReplaceAll(string, self._cfObject)
        CFStringFold(string, options._cfValue(), locale?._cfObject)
        return string._swiftObject
    }
    
    internal func _stringByReplacingOccurrencesOfRegularExpressionPattern(_ pattern: String, withTemplate replacement: String, options: NSStringCompareOptions, range: NSRange) -> String {
        let regexOptions: NSRegularExpressionOptions = options.contains(.caseInsensitiveSearch) ? .caseInsensitive : []
        let matchingOptions: NSMatchingOptions = options.contains(.anchoredSearch) ? .anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            return regex.stringByReplacingMatches(in: _swiftObject, options: matchingOptions, range: range, withTemplate: replacement)
        }
        return ""
    }
    
    public func replacingOccurrences(of target: String, with replacement: String, options: NSStringCompareOptions = [], range searchRange: NSRange) -> String {
        if options.contains(.regularExpressionSearch) {
            return _stringByReplacingOccurrencesOfRegularExpressionPattern(target, withTemplate: replacement, options: options, range: searchRange)
        }
        let str = mutableCopyWithZone(nil) as! NSMutableString
        if str.replaceOccurrences(of: target, with: replacement, options: options, range: searchRange) == 0 {
            return _swiftObject
        } else {
            return str._swiftObject
        }
    }
    
    public func replacingOccurrences(of target: String, with replacement: String) -> String {
        return replacingOccurrences(of: target, with: replacement, options: [], range: NSMakeRange(0, length))
    }
    
    public func replacingCharacters(in range: NSRange, with replacement: String) -> String {
        let str = mutableCopyWithZone(nil) as! NSMutableString
        str.replaceCharacters(in: range, with: replacement)
        return str._swiftObject
    }
    
    public func applyingTransform(_ transform: String, reverse: Bool) -> String? {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)!
        CFStringReplaceAll(string, _cfObject)
        if (CFStringTransform(string, nil, transform._cfObject, reverse)) {
            return string._swiftObject
        } else {
            return nil
        }
    }
    
    internal func _getExternalRepresentation(_ data: inout NSData, _ dest: NSURL, _ enc: UInt) throws {
        let length = self.length
        var numBytes = 0
        let theRange = NSMakeRange(0, length)
        if !getBytes(nil, maxLength: Int.max - 1, usedLength: &numBytes, encoding: enc, options: [], range: theRange, remaining: nil) {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteInapplicableStringEncodingError.rawValue, userInfo: [
                NSURLErrorKey: dest,
            ])
        }
        let mData = NSMutableData(length: numBytes)!
        // The getBytes:... call should hopefully not fail, given it succeeded above, but check anyway (mutable string changing behind our back?)
        var used = 0
        if !getBytes(mData.mutableBytes, maxLength: numBytes, usedLength: &used, encoding: enc, options: [], range: theRange, remaining: nil) {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnknownError.rawValue, userInfo: [
                NSURLErrorKey: dest,
            ])
        }
        data = mData
    }
    
    internal func _writeTo(_ url: NSURL, _ useAuxiliaryFile: Bool, _ enc: UInt) throws {
        var data = NSData()
        try _getExternalRepresentation(&data, url, enc)
        
        if url.fileURL {
            try data.write(to: url, options: useAuxiliaryFile ? .dataWritingAtomic : [])
        } else {
            if let path = url.path {
                try data.write(toFile: path, options: useAuxiliaryFile ? .dataWritingAtomic : [])
            } else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [
                    NSURLErrorKey: url,
                ])
            }
        }
    }
    
    public func write(to url: NSURL, atomically useAuxiliaryFile: Bool, encoding enc: UInt) throws {
        try _writeTo(url, useAuxiliaryFile, enc)
    }
    
    public func write(toFile path: String, atomically useAuxiliaryFile: Bool, encoding enc: UInt) throws {
        try _writeTo(NSURL(fileURLWithPath: path), useAuxiliaryFile, enc)
    }
    
    public convenience init(charactersNoCopy characters: UnsafeMutablePointer<unichar>, length: Int, freeWhenDone freeBuffer: Bool) /* "NoCopy" is a hint */ {
        // ignore the no-copy-ness
        self.init(characters: characters, length: length)
        if freeBuffer { // cant take a hint here...
            free(UnsafeMutablePointer<Void>(characters))
        }
    }
    
    public convenience init?(UTF8String nullTerminatedCString: UnsafePointer<Int8>) {
        let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(nullTerminatedCString), count: Int(strlen(nullTerminatedCString)))
        if let str = String._fromCodeUnitSequence(UTF8.self, input: buffer) {
            self.init(str)
        } else {
            return nil
        }
    }
    
    public convenience init(format: String, arguments argList: CVaListPointer) {
        let str = CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, nil, format._cfObject, argList)!
        self.init(str._swiftObject)
    }
    
    public convenience init(format: String, locale: AnyObject?, arguments argList: CVaListPointer) {
        let str: CFString
        if let loc = locale {
            if loc.dynamicType === NSLocale.self || loc.dynamicType === NSDictionary.self {
                str = CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, unsafeBitCast(loc, to: CFDictionary.self), format._cfObject, argList)
            } else {
                fatalError("locale parameter must be a NSLocale or a NSDictionary")
            }
        } else {
            str = CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, nil, format._cfObject, argList)
        }
        self.init(str._swiftObject)
    }
    
    public convenience init(format: NSString, _ args: CVarArg...) {
        let str = withVaList(args) { (vaPtr) -> CFString! in
            CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, nil, format._cfObject, vaPtr)
        }!
        self.init(str._swiftObject)
    }
    
    public convenience init?(data: NSData, encoding: UInt) {
        self.init(bytes: data.bytes, length: data.length, encoding: encoding)
    }
    
    public convenience init?(bytes: UnsafePointer<Void>, length len: Int, encoding: UInt) {
        guard let cf = CFStringCreateWithBytes(kCFAllocatorDefault, UnsafePointer<UInt8>(bytes), len, CFStringConvertNSStringEncodingToEncoding(encoding), true) else {
            return nil
        }
        var str: String?
        if String._conditionallyBridgeFromObject(cf._nsObject, result: &str) {
            self.init(str!)
        } else {
            return nil
        }
    }
    
    public convenience init?(bytesNoCopy bytes: UnsafeMutablePointer<Void>, length len: Int, encoding: UInt, freeWhenDone freeBuffer: Bool) /* "NoCopy" is a hint */ {
        // just copy for now since the internal storage will be a copy anyhow
        self.init(bytes: bytes, length: len, encoding: encoding)
        if freeBuffer { // dont take the hint
            free(bytes)
        }
    }
    
    public convenience init?(CString nullTerminatedCString: UnsafePointer<Int8>, encoding: UInt) {
        guard let cf = CFStringCreateWithCString(kCFAllocatorSystemDefault, nullTerminatedCString, CFStringConvertNSStringEncodingToEncoding(encoding)) else {
            return nil
        }
        var str: String?
        if String._conditionallyBridgeFromObject(cf._nsObject, result: &str) {
            self.init(str!)
        } else {
            return nil
        }
    }

    public convenience init(contentsOf url: NSURL, encoding enc: UInt) throws {
        let readResult = try NSData.init(contentsOfURL: url, options: [])
        guard let cf = CFStringCreateWithBytes(kCFAllocatorDefault, UnsafePointer<UInt8>(readResult.bytes), readResult.length, CFStringConvertNSStringEncodingToEncoding(enc), true) else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadInapplicableStringEncodingError.rawValue, userInfo: [
                "NSDebugDescription" : "Unable to create a string using the specified encoding."
                ])
        }
        var str: String?
        if String._conditionallyBridgeFromObject(cf._nsObject, result: &str) {
            self.init(str!)
        } else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileReadInapplicableStringEncodingError.rawValue, userInfo: [
                "NSDebugDescription" : "Unable to bridge CFString to String."
                ])
        }
    }

    public convenience init(contentsOfFile path: String, encoding enc: UInt) throws {
        try self.init(contentsOf: NSURL(fileURLWithPath: path), encoding: enc)
    }
    
    public convenience init(contentsOf url: NSURL, usedEncoding enc: UnsafeMutablePointer<UInt>?) throws {
        NSUnimplemented()    
    }
    
    public convenience init(contentsOfFile path: String, usedEncoding enc: UnsafeMutablePointer<UInt>?) throws {
        NSUnimplemented()    
    }
}

extension NSString : StringLiteralConvertible { }

public class NSMutableString : NSString {
    public func replaceCharacters(in range: NSRange, with aString: String) {
        guard self.dynamicType === NSString.self || self.dynamicType === NSMutableString.self else {
            NSRequiresConcreteImplementation()
        }

        // this is incorrectly calculated for grapheme clusters that have a size greater than a single unichar
        let start = _storage.startIndex
        let min = _storage.index(start, offsetBy: range.location)
        let max = _storage.index(start, offsetBy: range.location + range.length)
        _storage.replaceSubrange(min..<max, with: aString)
    }
    
    public required override init(characters: UnsafePointer<unichar>, length: Int) {
        super.init(characters: characters, length: length)
    }
    
    public required init(capacity: Int) {
        super.init(characters: [], length: 0)
    }

    public convenience required init?(coder aDecoder: NSCoder) {
        guard let str = NSString(coder: aDecoder) else {
            return nil
        }
        
        self.init(string: str.bridge())
    }

    public required convenience init(unicodeScalarLiteral value: StaticString) {
        self.init(stringLiteral: value)
    }
    
    public required convenience init(extendedGraphemeClusterLiteral value: StaticString) {
        self.init(stringLiteral: value)
    }
    
    public required init(stringLiteral value: StaticString) {
        if value.hasPointerRepresentation {
            super.init(String._fromWellFormedCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: value.utf8Start, count: Int(value.utf8CodeUnitCount))))
        } else {
            var uintValue = value.unicodeScalar.value
            super.init(String._fromWellFormedCodeUnitSequence(UTF32.self, input: UnsafeBufferPointer(start: &uintValue, count: 1)))
        }
    }

    public required init(string aString: String) {
        super.init(aString)
    }
    
    internal func appendCharacters(_ characters: UnsafePointer<unichar>, length: Int) {
        if self.dynamicType == NSMutableString.self {
            _storage.append(String._fromWellFormedCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: characters, count: length)))
        } else {
            replaceCharacters(in: NSMakeRange(self.length, 0), with: String._fromWellFormedCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: characters, count: length)))
        }
    }
    
    internal func _cfAppendCString(_ characters: UnsafePointer<Int8>, length: Int) {
        if self.dynamicType == NSMutableString.self {
            _storage.append(String(cString: characters))
        }
    }
}

extension NSMutableString {
    public func insert(_ aString: String, at loc: Int) {
        replaceCharacters(in: NSMakeRange(loc, 0), with: aString)
    }
    
    public func deleteCharacters(in range: NSRange) {
        replaceCharacters(in: range, with: "")
    }
    
    public func append(_ aString: String) {
        replaceCharacters(in: NSMakeRange(length, 0), with: aString)
    }
    
    public func setString(_ aString: String) {
        replaceCharacters(in: NSMakeRange(0, length), with: aString)
    }
    
    internal func _replaceOccurrencesOfRegularExpressionPattern(_ pattern: String, withTemplate replacement: String, options: NSStringCompareOptions, range searchRange: NSRange) -> Int {
        let regexOptions: NSRegularExpressionOptions = options.contains(.caseInsensitiveSearch) ? .caseInsensitive : []
        let matchingOptions: NSMatchingOptions = options.contains(.anchoredSearch) ? .anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            return regex.replaceMatches(in: self, options: matchingOptions, range: searchRange, withTemplate: replacement)
        }
        return 0
    }
    
    public func replaceOccurrences(of target: String, with replacement: String, options: NSStringCompareOptions = [], range searchRange: NSRange) -> Int {
        let backwards = options.contains(.backwardsSearch)
        let len = length
        
        precondition(searchRange.length <= len && searchRange.location <= len - searchRange.length, "Search range is out of bounds")
        
        if options.contains(.regularExpressionSearch) {
            return _replaceOccurrencesOfRegularExpressionPattern(target, withTemplate:replacement, options:options, range: searchRange)
        }
        

        if let findResults = CFStringCreateArrayWithFindResults(kCFAllocatorSystemDefault, _cfObject, target._cfObject, CFRange(searchRange), options._cfValue(true)) {
            let numOccurrences = CFArrayGetCount(findResults)
            for cnt in 0..<numOccurrences {
                let range = UnsafePointer<CFRange>(CFArrayGetValueAtIndex(findResults, backwards ? cnt : numOccurrences - cnt - 1)!)
                replaceCharacters(in: NSRange(range.pointee), with: replacement)
            }
            return numOccurrences
        } else {
            return 0
        }

    }
    
    public func applyTransform(_ transform: String, reverse: Bool, range: NSRange, updatedRange resultingRange: NSRangePointer?) -> Bool {
        var cfRange = CFRangeMake(range.location, range.length)
        return withUnsafeMutablePointer(&cfRange) { (rangep: UnsafeMutablePointer<CFRange>) -> Bool in
            if CFStringTransform(_cfMutableObject, rangep, transform._cfObject, reverse) {
                resultingRange?.pointee.location = rangep.pointee.location
                resultingRange?.pointee.length = rangep.pointee.length
                return true
            }
            return false
        }
    }
}


extension String {  
    // this is only valid for the usage for CF since it expects the length to be in unicode characters instead of grapheme clusters "✌🏾".utf16.count = 3 and CFStringGetLength(CFSTR("✌🏾")) = 3 not 1 as it would be represented with grapheme clusters
    internal var length: Int {
        return utf16.count
    }
}

extension NSString : _CFBridgable, _SwiftBridgable {
    typealias SwiftType = String
    internal var _cfObject: CFString { return unsafeBitCast(self, to: CFString.self) }
    internal var _swiftObject: String {
        var str: String?
        String._forceBridgeFromObject(self, result: &str)
        return str!
    }
}

extension NSMutableString {
    internal var _cfMutableObject: CFMutableString { return unsafeBitCast(self, to: CFMutableString.self) }
}

extension CFString : _NSBridgable, _SwiftBridgable {
    typealias NSType = NSString
    typealias SwiftType = String
    internal var _nsObject: NSType { return unsafeBitCast(self, to: NSString.self) }
    internal var _swiftObject: String { return _nsObject._swiftObject }
}

extension String : _NSBridgable, _CFBridgable {
    typealias NSType = NSString
    typealias CFType = CFString
    internal var _nsObject: NSType { return _bridgeToObject() }
    internal var _cfObject: CFType { return _nsObject._cfObject }
}

extension String : Bridgeable {
    public func bridge() -> NSString { return _nsObject }
}

extension NSString : Bridgeable {
    public func bridge() -> String { return _swiftObject }
}

extension NSString : CustomPlaygroundQuickLookable {
    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        return .text(self.bridge())
    }
}
