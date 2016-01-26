// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
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
internal let kCFStringEncodingMacRoman =  CFStringBuiltInEncodings.MacRoman.rawValue
internal let kCFStringEncodingWindowsLatin1 =  CFStringBuiltInEncodings.WindowsLatin1.rawValue
internal let kCFStringEncodingISOLatin1 =  CFStringBuiltInEncodings.ISOLatin1.rawValue
internal let kCFStringEncodingNextStepLatin =  CFStringBuiltInEncodings.NextStepLatin.rawValue
internal let kCFStringEncodingASCII =  CFStringBuiltInEncodings.ASCII.rawValue
internal let kCFStringEncodingUnicode =  CFStringBuiltInEncodings.Unicode.rawValue
internal let kCFStringEncodingUTF8 =  CFStringBuiltInEncodings.UTF8.rawValue
internal let kCFStringEncodingNonLossyASCII =  CFStringBuiltInEncodings.NonLossyASCII.rawValue
internal let kCFStringEncodingUTF16 = CFStringBuiltInEncodings.UTF16.rawValue
internal let kCFStringEncodingUTF16BE =  CFStringBuiltInEncodings.UTF16BE.rawValue
internal let kCFStringEncodingUTF16LE =  CFStringBuiltInEncodings.UTF16LE.rawValue
internal let kCFStringEncodingUTF32 =  CFStringBuiltInEncodings.UTF32.rawValue
internal let kCFStringEncodingUTF32BE =  CFStringBuiltInEncodings.UTF32BE.rawValue
internal let kCFStringEncodingUTF32LE =  CFStringBuiltInEncodings.UTF32LE.rawValue

internal let kCFStringGraphemeCluster = CFStringCharacterClusterType.GraphemeCluster
internal let kCFStringComposedCharacterCluster = CFStringCharacterClusterType.ComposedCharacterCluster
internal let kCFStringCursorMovementCluster = CFStringCharacterClusterType.CursorMovementCluster
internal let kCFStringBackwardDeletionCluster = CFStringCharacterClusterType.BackwardDeletionCluster

internal let kCFStringNormalizationFormD = CFStringNormalizationForm.D
internal let kCFStringNormalizationFormKD = CFStringNormalizationForm.KD
internal let kCFStringNormalizationFormC = CFStringNormalizationForm.C
internal let kCFStringNormalizationFormKC = CFStringNormalizationForm.KC
    
#endif

public struct NSStringEncodingConversionOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let AllowLossy = NSStringEncodingConversionOptions(rawValue: 1)
    public static let ExternalRepresentation = NSStringEncodingConversionOptions(rawValue: 2)
    internal static let FailOnPartialEncodingConversion = NSStringEncodingConversionOptions(rawValue: 1 << 20)
}

public struct NSStringEnumerationOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let ByLines = NSStringEnumerationOptions(rawValue: 0)
    public static let ByParagraphs = NSStringEnumerationOptions(rawValue: 1)
    public static let ByComposedCharacterSequences = NSStringEnumerationOptions(rawValue: 2)
    public static let ByWords = NSStringEnumerationOptions(rawValue: 3)
    public static let BySentences = NSStringEnumerationOptions(rawValue: 4)
    public static let Reverse = NSStringEnumerationOptions(rawValue: 1 << 8)
    public static let SubstringNotRequired = NSStringEnumerationOptions(rawValue: 1 << 9)
    public static let Localized = NSStringEnumerationOptions(rawValue: 1 << 10)
    
    internal static let ForceFullTokens = NSStringEnumerationOptions(rawValue: 1 << 20)
}

extension String : _ObjectTypeBridgeable {
    public func _bridgeToObject() -> NSString {
        return NSString(self)
    }
    
    public static func _forceBridgeFromObject(x: NSString, inout result: String?) {
        if x.dynamicType == NSString.self || x.dynamicType == NSMutableString.self {
            result = x._storage
        } else if x.dynamicType == _NSCFString.self {
            let cf = unsafeBitCast(x, CFStringRef.self)
            let str = CFStringGetCStringPtr(cf, CFStringEncoding(kCFStringEncodingUTF8))
            if str != nil {
                result = String.fromCString(str)
            } else {
                let length = CFStringGetLength(cf)
                let buffer = UnsafeMutablePointer<UniChar>.alloc(length)
                CFStringGetCharacters(cf, CFRangeMake(0, length), buffer)
                
                let str = String._fromCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: buffer, count: length))
                buffer.destroy(length)
                buffer.dealloc(length)
                result = str
            }
        } else if x.dynamicType == _NSCFConstantString.self {
            let conststr = unsafeBitCast(x, _NSCFConstantString.self)
            let str = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: conststr._ptr, count: Int(conststr._length)))
            result = str
        } else {
            let len = x.length
            var characters = [unichar](count: len, repeatedValue: 0)
            result = characters.withUnsafeMutableBufferPointer() { (inout buffer: UnsafeMutableBufferPointer<unichar>) -> String? in
                x.getCharacters(buffer.baseAddress, range: NSMakeRange(0, len))
                return String._fromCodeUnitSequence(UTF16.self, input: buffer)
            }
        }
    }
    
    public static func _conditionallyBridgeFromObject(x: NSString, inout result: String?) -> Bool {
        self._forceBridgeFromObject(x, result: &result)
        return result != nil
    }
}

public struct NSStringCompareOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let CaseInsensitiveSearch = NSStringCompareOptions(rawValue: 1)
    public static let LiteralSearch = NSStringCompareOptions(rawValue: 2)
    public static let BackwardsSearch = NSStringCompareOptions(rawValue: 4)
    public static let AnchoredSearch = NSStringCompareOptions(rawValue: 8)
    public static let NumericSearch = NSStringCompareOptions(rawValue: 64)
    public static let DiacriticInsensitiveSearch = NSStringCompareOptions(rawValue: 128)
    public static let WidthInsensitiveSearch = NSStringCompareOptions(rawValue: 256)
    public static let ForcedOrderingSearch = NSStringCompareOptions(rawValue: 512)
    public static let RegularExpressionSearch = NSStringCompareOptions(rawValue: 1024)
    
    internal func _cfValue(fixLiteral: Bool = false) -> CFStringCompareFlags {
#if os(OSX) || os(iOS)
        return contains(.LiteralSearch) || !fixLiteral ? CFStringCompareFlags(rawValue: rawValue) : CFStringCompareFlags(rawValue: rawValue).union(.CompareNonliteral)
#else
        return contains(.LiteralSearch) || !fixLiteral ? CFStringCompareFlags(rawValue) : CFStringCompareFlags(rawValue) | UInt(kCFCompareNonliteral)
#endif
    }
}

internal func _createRegexForPattern(pattern: String, _ options: NSRegularExpressionOptions) -> NSRegularExpression? {
    struct local {
        static let __NSRegularExpressionCache: NSCache = {
            let cache = NSCache()
            cache.name = "NSRegularExpressionCache"
            cache.countLimit = 10
            return cache
        }()
    }
    let key = "\(options):\(pattern)"
    if let regex = local.__NSRegularExpressionCache.objectForKey(key._nsObject) {
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

internal func _bytesInEncoding(str: NSString, _ encoding: NSStringEncoding, _ fatalOnError: Bool, _ externalRep: Bool, _ lossy: Bool) -> UnsafePointer<Int8> {
    let theRange = NSMakeRange(0, str.length)
    var cLength = 0
    var used = 0
    var options: NSStringEncodingConversionOptions = []
    if externalRep {
        options.unionInPlace(.ExternalRepresentation)
    }
    if lossy {
        options.unionInPlace(.AllowLossy)
    }
    if !str.getBytes(nil, maxLength: Int.max - 1, usedLength: &cLength, encoding: encoding, options: options, range: theRange, remainingRange: nil) {
        if fatalOnError {
            fatalError("Conversion on encoding failed")
        }
        return nil
    }
    
    let buffer = malloc(cLength + 1)
    if !str.getBytes(buffer, maxLength: cLength, usedLength: &used, encoding: encoding, options: options, range: theRange, remainingRange: nil) {
        fatalError("Internal inconsistency; previously claimed getBytes returned success but failed with similar invocation")
    }
    
    UnsafeMutablePointer<Int8>(buffer).advancedBy(cLength).initialize(0)
    
    return UnsafePointer<Int8>(buffer) // leaked and should be autoreleased via a NSData backing but we cannot here
}

internal func isALineSeparatorTypeCharacter(ch: unichar) -> Bool {
    if ch > 0x0d && ch < 0x0085 { /* Quick test to cover most chars */
        return false
    }
    return ch == 0x0a || ch == 0x0d || ch == 0x0085 || ch == 0x2028 || ch == 0x2029
}

internal func isAParagraphSeparatorTypeCharacter(ch: unichar) -> Bool {
    if ch > 0x0d && ch < 0x2029 { /* Quick test to cover most chars */
        return false
    }
    return ch == 0x0a || ch == 0x0d || ch == 0x2029
}

public class NSString : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFStringGetTypeID())
    internal var _storage: String
    
    public var length: Int {
        if self.dynamicType === NSString.self || self.dynamicType === NSMutableString.self {
            return _storage.utf16.count
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public func characterAtIndex(index: Int) -> unichar {
        if self.dynamicType === NSString.self || self.dynamicType === NSMutableString.self {
            let start = _storage.utf16.startIndex
            return _storage.utf16[start.advancedBy(index)]
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public override convenience init() {
        let characters = Array<unichar>(count: 1, repeatedValue: 0)
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
            let buffer = UnsafeMutablePointer<Void>(aDecoder.decodeBytesForKey("NS.bytes", returnedLength: &length))
            self.init(bytes: buffer, length: length, encoding: NSUTF8StringEncoding)
        }
    }
    
    public required convenience init(string aString: String) {
        self.init(aString)
    }
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public override func mutableCopy() -> AnyObject {
        return mutableCopyWithZone(nil)
    }
    
    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        if self.dynamicType === NSString.self || self.dynamicType === NSMutableString.self {
            let contents = _fastContents
            if contents != nil {
                return NSMutableString(characters: contents, length: length)
            }
        }
        let characters = UnsafeMutablePointer<unichar>.alloc(length)
        getCharacters(characters, range: NSMakeRange(0, length))
        let result = NSMutableString(characters: characters, length: length)
        characters.destroy()
        characters.dealloc(length)
        return result
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
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
        _storage = value.stringValue
    }
    
    internal var _fastCStringContents: UnsafePointer<Int8> {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            if _storage._core.isASCII {
                return unsafeBitCast(_storage._core.startASCII, UnsafePointer<Int8>.self)
            }
        }
        return nil
    }
    
    internal var _fastContents: UnsafePointer<UniChar> {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            if !_storage._core.isASCII {
                return unsafeBitCast(_storage._core.startUTF16, UnsafePointer<UniChar>.self)
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
  
    public override func isEqual(object: AnyObject?) -> Bool {
        guard let string = (object as? NSString)?._swiftObject else { return false }
        return self.isEqualToString(string)
    }
    
    public override var description: String {
        return _swiftObject
    }
    
    public override var hash: Int {
        return Int(bitPattern:CFStringHashNSString(self._cfObject))
    }
}

extension NSString {
    public func getCharacters(buffer: UnsafeMutablePointer<unichar>, range: NSRange) {
        for idx in 0..<range.length {
            buffer[idx] = characterAtIndex(idx + range.location)
        }
    }
    
    public func substringFromIndex(from: Int) -> String {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return String(_storage.utf16.suffixFrom(_storage.utf16.startIndex.advancedBy(from)))
        } else {
            return substringWithRange(NSMakeRange(from, length - from))
        }
    }
    
    public func substringToIndex(to: Int) -> String {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return String(_storage.utf16.prefixUpTo(_storage.utf16.startIndex
            .advancedBy(to)))
        } else {
            return substringWithRange(NSMakeRange(0, to))
        }
    }
    
    public func substringWithRange(range: NSRange) -> String {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            let start = _storage.utf16.startIndex
            return String(_storage.utf16[Range<String.UTF16View.Index>(start: start.advancedBy(range.location), end: start.advancedBy(range.location + range.length))])
        } else {
            let buff = UnsafeMutablePointer<unichar>.alloc(range.length)
            getCharacters(buff, range: range)
            let result = String(buff)
            buff.destroy()
            buff.dealloc(range.length)
            return result
        }
    }
    
    public func compare(string: String) -> NSComparisonResult {
        return compare(string, options: [], range: NSMakeRange(0, length))
    }
    
    public func compare(string: String, options mask: NSStringCompareOptions) -> NSComparisonResult {
        return compare(string, options: mask, range: NSMakeRange(0, length))
    }
    
    public func compare(string: String, options mask: NSStringCompareOptions, range compareRange: NSRange) -> NSComparisonResult {
        return compare(string, options: mask, range: compareRange, locale: nil)
    }
    
    public func compare(string: String, options mask: NSStringCompareOptions, range compareRange: NSRange, locale: AnyObject?) -> NSComparisonResult {
        var res: CFComparisonResult
        if let loc = locale {
            res = CFStringCompareWithOptionsAndLocale(_cfObject, string._cfObject, CFRange(compareRange), mask._cfValue(true), (loc as! NSLocale)._cfObject)
        } else {
            res = CFStringCompareWithOptionsAndLocale(_cfObject, string._cfObject, CFRange(compareRange), mask._cfValue(true), nil)
        }
        return NSComparisonResult._fromCF(res)
    }
    
    public func caseInsensitiveCompare(string: String) -> NSComparisonResult {
        return compare(string, options: .CaseInsensitiveSearch, range: NSMakeRange(0, length))
    }
    
    public func localizedCompare(string: String) -> NSComparisonResult {
        return compare(string, options: [], range: NSMakeRange(0, length), locale: NSLocale.currentLocale())
    }
    
    public func localizedCaseInsensitiveCompare(string: String) -> NSComparisonResult {
        return compare(string, options: .CaseInsensitiveSearch, range: NSMakeRange(0, length), locale: NSLocale.currentLocale())
    }
    
    public func localizedStandardCompare(string: String) -> NSComparisonResult {
        return compare(string, options: [.CaseInsensitiveSearch, .NumericSearch, .WidthInsensitiveSearch, .ForcedOrderingSearch], range: NSMakeRange(0, length), locale: NSLocale.currentLocale())
    }
    
    public func isEqualToString(aString: String) -> Bool {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return _storage == aString
        } else {
            return length == aString.length && compare(aString, options: .LiteralSearch, range: NSMakeRange(0, length)) == .OrderedSame
        }
    }
    
    public func hasPrefix(str: String) -> Bool {
        return rangeOfString(str, options: .AnchoredSearch, range: NSMakeRange(0, length)).location != NSNotFound
    }
    
    public func hasSuffix(str: String) -> Bool {
        return rangeOfString(str, options: [.AnchoredSearch, .BackwardsSearch], range: NSMakeRange(0, length)).location != NSNotFound
    }
    
    public func commonPrefixWithString(str: String, options mask: NSStringCompareOptions) -> String {
        var currentSubstring: CFMutableStringRef?
        let isLiteral = mask.contains(.LiteralSearch)
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
        var arrayBuffer = [unichar](count: 100, repeatedValue: 0)
        let other = str._nsObject
        return arrayBuffer.withUnsafeMutablePointerOrAllocation(selfLen, fastpath: UnsafeMutablePointer<unichar>(_fastContents)) { (selfChars: UnsafeMutablePointer<unichar>) -> String in
            // Now do the binary search. Note that the probe value determines the length of the substring to check.
            while true {
                let range = NSMakeRange(0, isLiteral ? probe + 1 : NSMaxRange(rangeOfComposedCharacterSequenceAtIndex(probe))) // Extend the end of the composed char sequence
                if range.length > numCharsBuffered { // Buffer more characters if needed
                    getCharacters(selfChars, range: NSMakeRange(numCharsBuffered, range.length - numCharsBuffered))
                    numCharsBuffered = range.length
                }
                if currentSubstring == nil {
                    currentSubstring = CFStringCreateMutableWithExternalCharactersNoCopy(kCFAllocatorSystemDefault, selfChars, range.length, range.length, kCFAllocatorNull)
                } else {
                    CFStringSetExternalCharactersNoCopy(currentSubstring, selfChars, range.length, range.length)
                }
                if other.rangeOfString(currentSubstring!._swiftObject, options: mask.union(.AnchoredSearch), range: NSMakeRange(0, otherLen)).length != 0 { // Match
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
            return lastMatch.length != 0 ? substringWithRange(lastMatch) : ""
        }
    }
    
    public func containsString(str: String) -> Bool {
        return rangeOfString(str, options: [], range: NSMakeRange(0, length), locale: nil).location != NSNotFound
    }
    
    public func localizedCaseInsensitiveContainsString(str: String) -> Bool {
        return rangeOfString(str, options: .CaseInsensitiveSearch, range: NSMakeRange(0, length), locale: NSLocale.currentLocale()).location != NSNotFound
    }
    
    public func localizedStandardContainsString(str: String) -> Bool {
        return rangeOfString(str, options: [.CaseInsensitiveSearch, .DiacriticInsensitiveSearch], range: NSMakeRange(0, length), locale: NSLocale.currentLocale()).location != NSNotFound
    }
    
    public func localizedStandardRangeOfString(str: String) -> NSRange {
        return rangeOfString(str, options: [.CaseInsensitiveSearch, .DiacriticInsensitiveSearch], range: NSMakeRange(0, length), locale: NSLocale.currentLocale())
    }
    
    public func rangeOfString(searchString: String) -> NSRange {
        return rangeOfString(searchString, options: [], range: NSMakeRange(0, length), locale: nil)
    }
    
    public func rangeOfString(searchString: String, options mask: NSStringCompareOptions) -> NSRange {
        return rangeOfString(searchString, options: mask, range: NSMakeRange(0, length), locale: nil)
    }
    
    public func rangeOfString(searchString: String, options mask: NSStringCompareOptions, range searchRange: NSRange) -> NSRange {
        return rangeOfString(searchString, options: mask, range: searchRange, locale: nil)
    }
    
    internal func _rangeOfRegularExpressionPattern(regex pattern: String, options mask: NSStringCompareOptions, range searchRange: NSRange, locale: NSLocale?) -> NSRange {
        var matchedRange = NSMakeRange(NSNotFound, 0)
        let regexOptions: NSRegularExpressionOptions = mask.contains(.CaseInsensitiveSearch) ? .CaseInsensitive : []
        let matchingOptions: NSMatchingOptions = mask.contains(.AnchoredSearch) ? .Anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            matchedRange = regex.rangeOfFirstMatchInString(_swiftObject, options: matchingOptions, range: searchRange)
        }
        return matchedRange
    }
    
    public func rangeOfString(searchString: String, options mask: NSStringCompareOptions, range searchRange: NSRange, locale: NSLocale?) -> NSRange {
        let findStrLen = searchString.length
        let len = length
        
        precondition(searchRange.length <= len && searchRange.location <= len - searchRange.length, "Bounds Range {\(searchRange.location), \(searchRange.length)} out of bounds; string length \(len)")
        
        if mask.contains(.RegularExpressionSearch) {
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
    
    public func rangeOfCharacterFromSet(searchSet: NSCharacterSet) -> NSRange {
        return rangeOfCharacterFromSet(searchSet, options: [], range: NSMakeRange(0, length))
    }
    
    public func rangeOfCharacterFromSet(searchSet: NSCharacterSet, options mask: NSStringCompareOptions) -> NSRange {
        return rangeOfCharacterFromSet(searchSet, options: mask, range: NSMakeRange(0, length))
    }
    
    public func rangeOfCharacterFromSet(searchSet: NSCharacterSet, options mask: NSStringCompareOptions, range searchRange: NSRange) -> NSRange {
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
    
    public func rangeOfComposedCharacterSequenceAtIndex(index: Int) -> NSRange {
        let range = CFStringGetRangeOfCharacterClusterAtIndex(_cfObject, index, kCFStringComposedCharacterCluster)
        return NSMakeRange(range.location, range.length)
    }
    
    public func rangeOfComposedCharacterSequencesForRange(range: NSRange) -> NSRange {
        let length = self.length
        var start: Int
        var end: Int
        if range.location == length {
            start = length
        } else {
            start = rangeOfComposedCharacterSequenceAtIndex(range.location).location
        }
        var endOfRange = NSMaxRange(range)
        if endOfRange == length {
            end = length
        } else {
            if range.length > 0 {
                endOfRange = endOfRange - 1 // We want 0-length range to be treated same as 1-length range.
            }
            end = NSMaxRange(rangeOfComposedCharacterSequenceAtIndex(endOfRange))
        }
        return NSMakeRange(start, end - start)
    }
    
    public func stringByAppendingString(aString: String) -> String {
        return _swiftObject + aString
    }
    
    public var doubleValue: Double {
        var start: Int = 0
        var result = 0.0
        _swiftObject.scan(NSCharacterSet.whitespaceCharacterSet(), locale: nil, locationToScanFrom: &start) { (value: Double) -> Void in
            result = value
        }
        return result
    }
    
    public var floatValue: Float {
        var start: Int = 0
        var result: Float = 0.0
        _swiftObject.scan(NSCharacterSet.whitespaceCharacterSet(), locale: nil, locationToScanFrom: &start) { (value: Float) -> Void in
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
        scanner.scanInteger(&value)
        return value
    }
    
    public var longLongValue: Int64 {
        return NSScanner(string: _swiftObject).scanLongLong() ?? 0
    }
    
    public var boolValue: Bool {
        let scanner = NSScanner(string: _swiftObject)
        // skip initial whitespace if present
        scanner.scanCharactersFromSet(NSCharacterSet.whitespaceCharacterSet())
        // scan a single optional '+' or '-' character, followed by zeroes
        if scanner.scanString(string: "+") == nil {
            scanner.scanString(string: "-")
        }
        // scan any following zeroes
        scanner.scanCharactersFromSet(NSCharacterSet(charactersInString: "0"))
        return scanner.scanCharactersFromSet(NSCharacterSet(charactersInString: "tTyY123456789")) != nil
    }
    
    public var uppercaseString: String {
        return uppercaseStringWithLocale(nil)
    }

    public var lowercaseString: String {
        return lowercaseStringWithLocale(nil)
    }
    
    public var capitalizedString: String {
        return capitalizedStringWithLocale(nil)
    }
    
    public var localizedUppercaseString: String {
        return uppercaseStringWithLocale(NSLocale.currentLocale())
    }
    
    public var localizedLowercaseString: String {
        return lowercaseStringWithLocale(NSLocale.currentLocale())
    }
    
    public var localizedCapitalizedString: String {
        return capitalizedStringWithLocale(NSLocale.currentLocale())
    }
    
    public func uppercaseStringWithLocale(locale: NSLocale?) -> String {
        let mutableCopy = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, self._cfObject)
        CFStringUppercase(mutableCopy, locale?._cfObject ?? nil)
        return mutableCopy._swiftObject
    }

    public func lowercaseStringWithLocale(locale: NSLocale?) -> String {
        let mutableCopy = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, self._cfObject)
        CFStringLowercase(mutableCopy, locale?._cfObject ?? nil)
        return mutableCopy._swiftObject
    }
    
    public func capitalizedStringWithLocale(locale: NSLocale?) -> String {
        let mutableCopy = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, self._cfObject)
        CFStringCapitalize(mutableCopy, locale?._cfObject ?? nil)
        return mutableCopy._swiftObject
    }
    
    internal func _getBlockStart(startPtr: UnsafeMutablePointer<Int>, end endPtr: UnsafeMutablePointer<Int>, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>, forRange range: NSRange, stopAtLineSeparators line: Bool) {
        let len = length
        var ch: unichar
        
        precondition(range.length <= len && range.location < len - range.length, "Range {\(range.location), \(range.length)} is out of bounds of length \(len)")
        
        if range.location == 0 && range.length == len && contentsEndPtr == nil { // This occurs often
            if startPtr != nil {
                startPtr.memory = 0
            }
            if endPtr != nil {
                endPtr.memory = range.length
            }
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
                startPtr.memory = start
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
            
            if contentsEndPtr != nil {
                contentsEndPtr.memory = endOfContents
            }
            if endPtr != nil {
                endPtr.memory = endOfContents + lineSeparatorLength
            }
        }
    }
    
    public func getLineStart(startPtr: UnsafeMutablePointer<Int>, end lineEndPtr: UnsafeMutablePointer<Int>, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>, forRange range: NSRange) {
        _getBlockStart(startPtr, end: lineEndPtr, contentsEnd: contentsEndPtr, forRange: range, stopAtLineSeparators: true)
    }
    
    public func lineRangeForRange(range: NSRange) -> NSRange {
        var start = 0
        var lineEnd = 0
        getLineStart(&start, end: &lineEnd, contentsEnd: nil, forRange: range)
        return NSMakeRange(start, lineEnd - start)
    }
    
    public func getParagraphStart(startPtr: UnsafeMutablePointer<Int>, end parEndPtr: UnsafeMutablePointer<Int>, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>, forRange range: NSRange) {
        _getBlockStart(startPtr, end: parEndPtr, contentsEnd: contentsEndPtr, forRange: range, stopAtLineSeparators: false)
    }
    
    public func paragraphRangeForRange(range: NSRange) -> NSRange {
        var start = 0
        var parEnd = 0
        getParagraphStart(&start, end: &parEnd, contentsEnd: nil, forRange: range)
        return NSMakeRange(start, parEnd - start)
    }
    
    public func enumerateSubstringsInRange(range: NSRange, options opts: NSStringEnumerationOptions, usingBlock block: (String?, NSRange, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        NSUnimplemented()
    }
    
    public func enumerateLinesUsingBlock(block: (String, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateSubstringsInRange(NSMakeRange(0, length), options:.ByLines) { substr, substrRange, enclosingRange, stop in
            block(substr!, stop)
        }
    }
    
    public var UTF8String: UnsafePointer<Int8> {
        return _bytesInEncoding(self, NSUTF8StringEncoding, false, false, false)
    }
    
    public var fastestEncoding: UInt {
        return NSUnicodeStringEncoding
    }
    
    public var smallestEncoding: UInt {
        if canBeConvertedToEncoding(NSASCIIStringEncoding) {
            return NSASCIIStringEncoding
        }
        return NSUnicodeStringEncoding
    }
    
    public func dataUsingEncoding(encoding: UInt, allowLossyConversion lossy: Bool) -> NSData? {
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
    
    public func dataUsingEncoding(encoding: UInt) -> NSData? {
        return dataUsingEncoding(encoding, allowLossyConversion: false)
    }
    
    public func canBeConvertedToEncoding(encoding: UInt) -> Bool {
        if encoding == NSUnicodeStringEncoding || encoding == NSNonLossyASCIIStringEncoding || encoding == NSUTF8StringEncoding {
            return true
        }
        return __CFStringEncodeByteStream(_cfObject, 0, length, false, CFStringConvertNSStringEncodingToEncoding(encoding), 0, nil, 0, nil) == length
    }
    
    public func cStringUsingEncoding(encoding: UInt) -> UnsafePointer<Int8> {
        return _bytesInEncoding(self, encoding, false, false, false)
    }
    
    public func getCString(buffer: UnsafeMutablePointer<Int8>, maxLength maxBufferCount: Int, encoding: UInt) -> Bool {
        var used = 0
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            if _storage._core.isASCII {
                used = min(self.length, maxBufferCount - 1)
                buffer.moveAssignFrom(unsafeBitCast(_storage._core.startASCII, UnsafeMutablePointer<Int8>.self)
                    , count: used)
                buffer.advancedBy(used).initialize(0)
                return true
            }
        }
        if getBytes(UnsafeMutablePointer<Void>(buffer), maxLength: maxBufferCount, usedLength: &used, encoding: encoding, options: [], range: NSMakeRange(0, self.length), remainingRange: nil) {
            buffer.advancedBy(used).initialize(0)
            return true
        }
        return false
    }
    
    public func getBytes(buffer: UnsafeMutablePointer<Void>, maxLength maxBufferCount: Int, usedLength usedBufferCount: UnsafeMutablePointer<Int>, encoding: UInt, options: NSStringEncodingConversionOptions, range: NSRange, remainingRange leftover: NSRangePointer) -> Bool {
        var totalBytesWritten = 0
        var numCharsProcessed = 0
        let cfStringEncoding = CFStringConvertNSStringEncodingToEncoding(encoding)
        var result = true
        if length > 0 {
            if CFStringIsEncodingAvailable(cfStringEncoding) {
                let lossyOk = options.contains(.AllowLossy)
                let externalRep = options.contains(.ExternalRepresentation)
                let failOnPartial = options.contains(.FailOnPartialEncodingConversion)
                numCharsProcessed = __CFStringEncodeByteStream(_cfObject, range.location, range.length, externalRep, cfStringEncoding, lossyOk ? (encoding == NSASCIIStringEncoding ? 0xFF : 0x3F) : 0, UnsafeMutablePointer<UInt8>(buffer), buffer != nil ? maxBufferCount : 0, &totalBytesWritten)
                if (failOnPartial && numCharsProcessed < range.length) || numCharsProcessed == 0 {
                    result = false
                }
            } else {
                result = false /* ??? Need other encodings */
            }
        }
        if usedBufferCount != nil {
            usedBufferCount.memory = totalBytesWritten
        }
        if leftover != nil {
            leftover.memory = NSMakeRange(range.location + numCharsProcessed, range.length - numCharsProcessed)
        }
        return result
    }
    
    public func maximumLengthOfBytesUsingEncoding(enc: UInt) -> Int {
        let cfEnc = CFStringConvertNSStringEncodingToEncoding(enc)
        let result = CFStringGetMaximumSizeForEncoding(length, cfEnc)
        return result == kCFNotFound ? 0 : result
    }
    
    public func lengthOfBytesUsingEncoding(enc: UInt) -> Int {
        let len = length
        var numBytes: CFIndex = 0
        let cfEnc = CFStringConvertNSStringEncodingToEncoding(enc)
        let convertedLen = __CFStringEncodeByteStream(_cfObject, 0, len, false, cfEnc, 0, nil, 0, &numBytes)
        return convertedLen != len ? 0 : numBytes
    }
    
    public class func availableStringEncodings() -> UnsafePointer<UInt> {
        struct once {
            static let encodings: UnsafePointer<UInt> = {
                let cfEncodings = CFStringGetListOfAvailableEncodings()
                var idx = 0
                var numEncodings = 0
                
                while cfEncodings.advancedBy(idx).memory != kCFStringEncodingInvalidId {
                    idx += 1
                    numEncodings += 1
                }
                
                let theEncodingList = UnsafeMutablePointer<NSStringEncoding>.alloc(numEncodings + 1)
                theEncodingList.advancedBy(numEncodings).memory = 0 // Terminator
                
                numEncodings -= 1
                while numEncodings >= 0 {
                    theEncodingList.advancedBy(numEncodings).memory = CFStringConvertEncodingToNSStringEncoding(cfEncodings.advancedBy(numEncodings).memory)
                    numEncodings -= 1
                }
                
                return UnsafePointer<UInt>(theEncodingList)
            }()
        }
        return once.encodings
    }
    
    public class func localizedNameOfStringEncoding(encoding: UInt) -> String {
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
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)
        CFStringReplaceAll(string, self._cfObject)
        CFStringNormalize(string, kCFStringNormalizationFormD)
        return string._swiftObject
    }
    
    public var precomposedStringWithCanonicalMapping: String {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)
        CFStringReplaceAll(string, self._cfObject)
        CFStringNormalize(string, kCFStringNormalizationFormC)
        return string._swiftObject
    }
    
    public var decomposedStringWithCompatibilityMapping: String {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)
        CFStringReplaceAll(string, self._cfObject)
        CFStringNormalize(string, kCFStringNormalizationFormKD)
        return string._swiftObject
    }
    
    public var precomposedStringWithCompatibilityMapping: String {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)
        CFStringReplaceAll(string, self._cfObject)
        CFStringNormalize(string, kCFStringNormalizationFormKC)
        return string._swiftObject
    }
    
    public func componentsSeparatedByString(separator: String) -> [String] {
        let len = length
        var range = rangeOfString(separator, options: [], range: NSMakeRange(0, len))
        if range.length == 0 {
            return [_swiftObject]
        } else {
            var array = [String]()
            var srange = NSMakeRange(0, len)
            while true {
                let trange = NSMakeRange(srange.location, range.location - srange.location)
                array.append(substringWithRange(trange))
                srange.location = range.location + range.length
                srange.length = len - srange.location
                range = rangeOfString(separator, options: [], range: srange)
                if range.length == 0 {
                    break
                }
            }
            array.append(substringWithRange(srange))
            return array
        }
    }
    
    public func componentsSeparatedByCharactersInSet(separator: NSCharacterSet) -> [String] {
        let len = length
        var range = rangeOfCharacterFromSet(separator, options: [], range: NSMakeRange(0, len))
        if range.length == 0 {
            return [_swiftObject]
        } else {
            var array = [String]()
            var srange = NSMakeRange(0, len)
            while true {
                let trange = NSMakeRange(srange.location, range.location - srange.location)
                array.append(substringWithRange(trange))
                srange.location = range.location + range.length
                srange.length = len - srange.location
                range = rangeOfCharacterFromSet(separator, options: [], range: srange)
                if range.length == 0 {
                    break
                }
            }
            array.append(substringWithRange(srange))
            return array
        }
    }
    
    public func stringByTrimmingCharactersInSet(set: NSCharacterSet) -> String {
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
            return substringWithRange(NSMakeRange(startOfNonTrimmedRange, endOfNonTrimmedRange + 1 - startOfNonTrimmedRange))
        } else {
            return substringWithRange(NSMakeRange(startOfNonTrimmedRange, 1))
        }
    }
    
    public func stringByPaddingToLength(newLength: Int, withString padString: String, startingAtIndex padIndex: Int) -> String {
        let len = length
        if newLength <= len {	// The simple cases (truncation)
            return newLength == len ? _swiftObject : substringWithRange(NSMakeRange(0, newLength))
        }
        let padLen = padString.length
        if padLen < 1 {
            fatalError("empty pad string")
        }
        if padIndex >= padLen {
            fatalError("out of range padIndex")
        }
        
        let mStr = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, _cfObject)
        CFStringPad(mStr, padString._cfObject, newLength, padIndex)
        return mStr._swiftObject
    }
    
    public func stringByFoldingWithOptions(options: NSStringCompareOptions, locale: NSLocale?) -> String {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)
        CFStringReplaceAll(string, self._cfObject)
        CFStringFold(string, options._cfValue(), locale?._cfObject)
        return string._swiftObject
    }
    
    internal func _stringByReplacingOccurrencesOfRegularExpressionPattern(pattern: String, withTemplate replacement: String, options: NSStringCompareOptions, range: NSRange) -> String {
        let regexOptions: NSRegularExpressionOptions = options.contains(.CaseInsensitiveSearch) ? .CaseInsensitive : []
        let matchingOptions: NSMatchingOptions = options.contains(.AnchoredSearch) ? .Anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            return regex.stringByReplacingMatchesInString(_swiftObject, options: matchingOptions, range: range, withTemplate: replacement)
        }
        return ""
    }
    
    public func stringByReplacingOccurrencesOfString(target: String, withString replacement: String, options: NSStringCompareOptions, range searchRange: NSRange) -> String {
        if options.contains(.RegularExpressionSearch) {
            return _stringByReplacingOccurrencesOfRegularExpressionPattern(target, withTemplate: replacement, options: options, range: searchRange)
        }
        let str = mutableCopyWithZone(nil) as! NSMutableString
        if str.replaceOccurrencesOfString(target, withString: replacement, options: options, range: searchRange) == 0 {
            return _swiftObject
        } else {
            return str._swiftObject
        }
    }
    
    public func stringByReplacingOccurrencesOfString(target: String, withString replacement: String) -> String {
        return stringByReplacingOccurrencesOfString(target, withString: replacement, options: [], range: NSMakeRange(0, length))
    }
    
    public func stringByReplacingCharactersInRange(range: NSRange, withString replacement: String) -> String {
        let str = mutableCopyWithZone(nil) as! NSMutableString
        str.replaceCharactersInRange(range, withString: replacement)
        return str._swiftObject
    }
    
    public func stringByApplyingTransform(transform: String, reverse: Bool) -> String? {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)
        CFStringReplaceAll(string, _cfObject)
        if (CFStringTransform(string, nil, transform._cfObject, reverse)) {
            return string._swiftObject
        } else {
            return nil
        }
    }
    
    internal func _getExternalRepresentation(inout data: NSData, _ dest: NSURL, _ enc: UInt) throws {
        let length = self.length
        var numBytes = 0
        let theRange = NSMakeRange(0, length)
        if !getBytes(nil, maxLength: Int.max - 1, usedLength: &numBytes, encoding: enc, options: [], range: theRange, remainingRange: nil) {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteInapplicableStringEncodingError.rawValue, userInfo: [
                NSURLErrorKey: dest,
            ])
        }
        let mData = NSMutableData(length: numBytes)!
        // The getBytes:... call should hopefully not fail, given it succeeded above, but check anyway (mutable string changing behind our back?)
        var used = 0
        if !getBytes(mData.mutableBytes, maxLength: numBytes, usedLength: &used, encoding: enc, options: [], range: theRange, remainingRange: nil) {
            throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileWriteUnknownError.rawValue, userInfo: [
                NSURLErrorKey: dest,
            ])
        }
        data = mData
    }
    
    internal func _writeTo(url: NSURL, _ useAuxiliaryFile: Bool, _ enc: UInt) throws {
        var data = NSData()
        try _getExternalRepresentation(&data, url, enc)
        
        if url.fileURL {
            try data.writeToURL(url, options: useAuxiliaryFile ? .DataWritingAtomic : [])
        } else {
            if let path = url.path {
                try data.writeToFile(path, options: useAuxiliaryFile ? .DataWritingAtomic : [])
            } else {
                throw NSError(domain: NSCocoaErrorDomain, code: NSCocoaError.FileNoSuchFileError.rawValue, userInfo: [
                    NSURLErrorKey: url,
                ])
            }
        }
    }
    
    public func writeToURL(url: NSURL, atomically useAuxiliaryFile: Bool, encoding enc: UInt) throws {
        try _writeTo(url, useAuxiliaryFile, enc)
    }
    
    public func writeToFile(path: String, atomically useAuxiliaryFile: Bool, encoding enc: UInt) throws {
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
        let str = CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, nil, format._cfObject, argList)
        self.init(str._swiftObject)
    }
    
    public convenience init(format: String, locale: AnyObject?, arguments argList: CVaListPointer) {
        NSUnimplemented()    
    }
    
    public convenience init(format: NSString, _ args: CVarArgType...) {
        let str = withVaList(args) { (vaPtr) -> CFString! in
            CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, nil, format._cfObject, vaPtr)
        }
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

    public convenience init(contentsOfURL url: NSURL, encoding enc: UInt) throws {
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
        try self.init(contentsOfURL: NSURL(fileURLWithPath: path), encoding: enc)
    }
    
    public convenience init(contentsOfURL url: NSURL, usedEncoding enc: UnsafeMutablePointer<UInt>) throws {
        NSUnimplemented()    
    }
    
    public convenience init(contentsOfFile path: String, usedEncoding enc: UnsafeMutablePointer<UInt>) throws {
        NSUnimplemented()    
    }
}

extension NSString : StringLiteralConvertible { }

public class NSMutableString : NSString {
    public func replaceCharactersInRange(range: NSRange, withString aString: String) {
        if self.dynamicType === NSString.self || self.dynamicType === NSMutableString.self {
            // this is incorrectly calculated for grapheme clusters that have a size greater than a single unichar
            let start = _storage.startIndex
            
            let subrange = Range(start: start.advancedBy(range.location), end: start.advancedBy(range.location + range.length))
            _storage.replaceRange(subrange, with: aString)
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public required override init(characters: UnsafePointer<unichar>, length: Int) {
        super.init(characters: characters, length: length)
    }
    
    public required init(capacity: Int) {
        super.init(characters: nil, length: 0)
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
            super.init(String._fromWellFormedCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: value.utf8Start, count: Int(value.byteSize))))
        } else {
            var uintValue = value.unicodeScalar.value
            super.init(String._fromWellFormedCodeUnitSequence(UTF32.self, input: UnsafeBufferPointer(start: &uintValue, count: 1)))
        }
    }

    public required init(string aString: String) {
        super.init(aString)
    }
    
    internal func appendCharacters(characters: UnsafePointer<unichar>, length: Int) {
        if self.dynamicType == NSMutableString.self {
            _storage.appendContentsOf(String._fromWellFormedCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: characters, count: length)))
        } else {
            replaceCharactersInRange(NSMakeRange(self.length, 0), withString: String._fromWellFormedCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: characters, count: length)))
        }
    }
    
    internal func _cfAppendCString(characters: UnsafePointer<Int8>, length: Int) {
        if self.dynamicType == NSMutableString.self {
            _storage.appendContentsOf(String.fromCString(characters)!)
        }
    }
}

extension NSMutableString {
    public func insertString(aString: String, atIndex loc: Int) {
        replaceCharactersInRange(NSMakeRange(loc, 0), withString: aString)
    }
    
    public func deleteCharactersInRange(range: NSRange) {
        replaceCharactersInRange(range, withString: "")
    }
    
    public func appendString(aString: String) {
        replaceCharactersInRange(NSMakeRange(length, 0), withString: aString)
    }
    
    public func setString(aString: String) {
        replaceCharactersInRange(NSMakeRange(0, length), withString: aString)
    }
    
    internal func _replaceOccurrencesOfRegularExpressionPattern(pattern: String, withTemplate replacement: String, options: NSStringCompareOptions, range searchRange: NSRange) -> Int {
        let regexOptions: NSRegularExpressionOptions = options.contains(.CaseInsensitiveSearch) ? .CaseInsensitive : []
        let matchingOptions: NSMatchingOptions = options.contains(.AnchoredSearch) ? .Anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            return regex.replaceMatchesInString(self, options: matchingOptions, range: searchRange, withTemplate: replacement)
        }
        return 0
    }
    
    public func replaceOccurrencesOfString(target: String, withString replacement: String, options: NSStringCompareOptions, range searchRange: NSRange) -> Int {
        let backwards = options.contains(.BackwardsSearch)
        let len = length
        
        precondition(searchRange.length <= len && searchRange.location <= len - searchRange.length, "Search range is out of bounds")
        
        if options.contains(.RegularExpressionSearch) {
            return _replaceOccurrencesOfRegularExpressionPattern(target, withTemplate:replacement, options:options, range: searchRange)
        }
        

        if let findResults = CFStringCreateArrayWithFindResults(kCFAllocatorSystemDefault, _cfObject, target._cfObject, CFRange(searchRange), options._cfValue(true)) {
            let numOccurrences = CFArrayGetCount(findResults)
            for cnt in 0..<numOccurrences {
                let range = UnsafePointer<CFRange>(CFArrayGetValueAtIndex(findResults, backwards ? cnt : numOccurrences - cnt - 1))
                replaceCharactersInRange(NSRange(range.memory), withString: replacement)
            }
            return numOccurrences
        } else {
            return 0
        }

    }
    
    public func applyTransform(transform: String, reverse: Bool, range: NSRange, updatedRange resultingRange: NSRangePointer) -> Bool {
        var cfRange = CFRangeMake(range.location, range.length)
        return withUnsafeMutablePointer(&cfRange) { (rangep: UnsafeMutablePointer<CFRange>) -> Bool in
            if CFStringTransform(_cfMutableObject, rangep, transform._cfObject, reverse) {
                if resultingRange != nil {
                    resultingRange.memory.location = rangep.memory.location
                    resultingRange.memory.length = rangep.memory.length
                }
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
    internal var _cfObject: CFStringRef { return unsafeBitCast(self, CFStringRef.self) }
    internal var _swiftObject: String {
        var str: String?
        String._forceBridgeFromObject(self, result: &str)
        return str!
    }
}

extension NSMutableString {
    internal var _cfMutableObject: CFMutableStringRef { return unsafeBitCast(self, CFMutableStringRef.self) }
}

extension CFStringRef : _NSBridgable, _SwiftBridgable {
    typealias NSType = NSString
    typealias SwiftType = String
    internal var _nsObject: NSType { return unsafeBitCast(self, NSString.self) }
    internal var _swiftObject: String { return _nsObject._swiftObject }
}

extension String : _NSBridgable, _CFBridgable {
    typealias NSType = NSString
    typealias CFType = CFStringRef
    internal var _nsObject: NSType { return _bridgeToObject() }
    internal var _cfObject: CFType { return _nsObject._cfObject }
}

extension String : Bridgeable {
    public func bridge() -> NSString { return _nsObject }
}

extension NSString : Bridgeable {
    public func bridge() -> String { return _swiftObject }
}
