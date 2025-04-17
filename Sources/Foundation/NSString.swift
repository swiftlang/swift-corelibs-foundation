// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@_spi(SwiftCorelibsFoundation) @_exported import FoundationEssentials
@_implementationOnly import CoreFoundation
internal import Synchronization

public typealias unichar = UInt16

extension unichar {
    public init(unicodeScalarLiteral scalar: UnicodeScalar) {
        self.init(scalar.value)
    }
}

/// Returns a localized string, using the main bundle if one is not specified.
public
func NSLocalizedString(_ key: String,
                       tableName: String? = nil,
                       bundle: Bundle = Bundle.main,
                       value: String = "",
                       comment: String) -> String {
    return bundle.localizedString(forKey: key, value: value, table: tableName)
}

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

extension NSString {

    public struct EncodingConversionOptions : OptionSet, Sendable {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let allowLossy = EncodingConversionOptions(rawValue: 1)
        public static let externalRepresentation = EncodingConversionOptions(rawValue: 2)
        internal static let failOnPartialEncodingConversion = EncodingConversionOptions(rawValue: 1 << 20)
    }

    public struct EnumerationOptions : OptionSet, Sendable {
        public let rawValue : UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        
        public static let byLines = EnumerationOptions([])
        public static let byParagraphs = EnumerationOptions(rawValue: 1)
        public static let byComposedCharacterSequences = EnumerationOptions(rawValue: 2)
        
        @available(*, unavailable, message: "Enumeration by words isn't supported in swift-corelibs-foundation")
        public static let byWords = EnumerationOptions(rawValue: 3)
        
        @available(*, unavailable, message: "Enumeration by sentences isn't supported in swift-corelibs-foundation")
        public static let bySentences = EnumerationOptions(rawValue: 4)
        
        public static let reverse = EnumerationOptions(rawValue: 1 << 8)
        public static let substringNotRequired = EnumerationOptions(rawValue: 1 << 9)
        public static let localized = EnumerationOptions(rawValue: 1 << 10)
        
        internal static let forceFullTokens = EnumerationOptions(rawValue: 1 << 20)
    }
}

extension NSString {
    public typealias CompareOptions = String.CompareOptions
}

extension NSString.CompareOptions {
        internal func _cfValue(_ fixLiteral: Bool = false) -> CFStringCompareFlags {
            return contains(.literal) || !fixLiteral ? CFStringCompareFlags(rawValue: rawValue) : CFStringCompareFlags(rawValue: rawValue).union(.compareNonliteral)
        }
}

public struct StringTransform: Equatable, Hashable, RawRepresentable, Sendable {
    typealias RawType = String

    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    // Transliteration
    public static let toLatin = StringTransform(rawValue: kCFStringTransformToLatin!._swiftObject)
    public static let latinToArabic = StringTransform(rawValue: kCFStringTransformLatinArabic!._swiftObject)
    public static let latinToCyrillic = StringTransform(rawValue: kCFStringTransformLatinCyrillic!._swiftObject)
    public static let latinToGreen = StringTransform(rawValue: kCFStringTransformLatinGreek!._swiftObject)
    public static let latinToHangul = StringTransform(rawValue: kCFStringTransformLatinHangul!._swiftObject)
    public static let latinToHebrew = StringTransform(rawValue: kCFStringTransformLatinHebrew!._swiftObject)
    public static let latinToHiragana = StringTransform(rawValue: kCFStringTransformLatinHiragana!._swiftObject)
    public static let latinToKatakana = StringTransform(rawValue: kCFStringTransformLatinKatakana!._swiftObject)
    public static let latinToThai = StringTransform(rawValue: kCFStringTransformLatinThai!._swiftObject)
    public static let hiraganaToKatakana = StringTransform(rawValue: kCFStringTransformHiraganaKatakana!._swiftObject)
    public static let mandarinToLatin = StringTransform(rawValue: kCFStringTransformMandarinLatin!._swiftObject)

    // Diacritic and Combining Mark Removal
    public static let stripDiacritics = StringTransform(rawValue: kCFStringTransformStripDiacritics!._swiftObject)
    public static let stripCombiningMarks = StringTransform(rawValue: kCFStringTransformStripCombiningMarks!._swiftObject)

    // Halfwidth and Fullwidth Form Conversion
    public static let fullwidthToHalfwidth = StringTransform(rawValue: kCFStringTransformFullwidthHalfwidth!._swiftObject)

    // Character Representation
    public static let toUnicodeName = StringTransform(rawValue: kCFStringTransformToUnicodeName!._swiftObject)
    public static let toXMLHex = StringTransform(rawValue: kCFStringTransformToXMLHex!._swiftObject)
}


// NSCache is marked as non-Sendable, but it actually does have locking in our implementation
fileprivate nonisolated(unsafe) let regularExpressionCache: NSCache<NSString, NSRegularExpression> = {
    let cache = NSCache<NSString, NSRegularExpression>()
    cache.name = "NSRegularExpressionCache"
    cache.countLimit = 10
    return cache
}()

internal func _createRegexForPattern(_ pattern: String, _ options: NSRegularExpression.Options) -> NSRegularExpression? {
    
    let key = "\(options):\(pattern)"
    if let regex = regularExpressionCache.object(forKey: key._nsObject) {
        return regex
    }

    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
        return nil
    }

    regularExpressionCache.setObject(regex, forKey: key._nsObject)
    
    return regex
}

// Caller must free, or leak, the pointer
fileprivate func _allocateBytesInEncoding(_ str: NSString, _ encoding: String.Encoding) -> UnsafeMutableBufferPointer<Int8>? {
    let theRange: NSRange = NSRange(location: 0, length: str.length)
    var cLength = 0
    if !str.getBytes(nil, maxLength: Int.max - 1, usedLength: &cLength, encoding: encoding.rawValue, options: [], range: theRange, remaining: nil) {
        return nil
    }
    
    let buffer = UnsafeMutableBufferPointer<Int8>.allocate(capacity: cLength + 1)
    buffer.initialize(repeating: 0)
    _ = str.getBytes(buffer.baseAddress, maxLength: cLength, usedLength: nil, encoding: encoding.rawValue, options: [], range: theRange, remaining: nil)    
    
    return buffer
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

@available(*, unavailable)
extension NSString : @unchecked Sendable { }

open class NSString : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFStringGetTypeID())
    internal var _storage: String
    
    open var length: Int {
        guard type(of: self) === NSString.self || type(of: self) === NSMutableString.self else {
            NSRequiresConcreteImplementation()
        }
        return _storage.utf16.count
    }
    
    open func character(at index: Int) -> unichar {
        guard type(of: self) === NSString.self || type(of: self) === NSMutableString.self else {
            NSRequiresConcreteImplementation()
        }
        let start = _storage.utf16.startIndex
        return _storage.utf16[_storage.utf16.index(start, offsetBy: index)]
    }
    
    public override convenience init() {
        self.init("")
    }
    
    internal init(_ string: String) {
        _storage = string
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            preconditionFailure("Unkeyed coding is unsupported.")
        }
        if type(of: aDecoder) == NSKeyedUnarchiver.self || aDecoder.containsValue(forKey: "NS.string") {
            let str = aDecoder._decodePropertyListForKey("NS.string") as! String
            self.init(string: str)
        } else {
            let decodedData : Data? = aDecoder.withDecodedUnsafeBufferPointer(forKey: "NS.bytes") {
                guard let buffer = $0 else { return nil }
                return Data(buffer: buffer)
            }
            guard let data = decodedData else { return nil }
            self.init(data: data, encoding: String.Encoding.utf8.rawValue)
        }
    }
    
    public required convenience init(string aString: String) {
        self.init(aString)
    }
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        if type(of: self) === NSString.self {
            return self
        }
        let characters = UnsafeMutablePointer<unichar>.allocate(capacity: length)
        getCharacters(characters, range: NSRange(location: 0, length: length))
        let result = NSString(characters: characters, length: length)
        characters.deinitialize(count: length)
        characters.deallocate()
        return result
    }
    
    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }
    
    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        if type(of: self) === NSString.self || type(of: self) === NSMutableString.self {
            if let contents = _fastContents {
                return NSMutableString(characters: contents, length: length)
            }
        }
        let characters = UnsafeMutablePointer<unichar>.allocate(capacity: length)
        getCharacters(characters, range: NSRange(location: 0, length: length))
        let result = NSMutableString(characters: characters, length: length)
        characters.deinitialize(count: 1)
        characters.deallocate()
        return result
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    open func encode(with aCoder: NSCoder) {
        if let aKeyedCoder = aCoder as? NSKeyedArchiver {
            aKeyedCoder._encodePropertyList(self, forKey: "NS.string")
        } else {
            aCoder.encode(self)
        }
    }
    
    public init(characters: UnsafePointer<unichar>, length: Int) {
        _storage = String(decoding: UnsafeBufferPointer(start: characters, count: length), as: UTF16.self)
    }
    
    public required convenience init(unicodeScalarLiteral value: StaticString) {
        self.init(stringLiteral: value)
    }
    
    public required convenience init(extendedGraphemeClusterLiteral value: StaticString) {
        self.init(stringLiteral: value)
    }
    
    public required init(stringLiteral value: StaticString) {
        _storage = String(describing: value)
    }
    
    public convenience init?(cString nullTerminatedCString: UnsafePointer<Int8>, encoding: UInt) {
        guard let str =
            CFStringCreateWithCString(kCFAllocatorSystemDefault,
                                      nullTerminatedCString,
                                      CFStringConvertNSStringEncodingToEncoding(numericCast(encoding))) else {
            return nil
        }
        self.init(string: str._swiftObject)
    }
    
    internal func _fastCStringContents(_ nullTerminated: Bool) -> UnsafePointer<Int8>? {
        // There is no truly safe way to return an inner pointer for CFString here
        return nil
    }

    internal var _fastContents: UnsafePointer<UniChar>? {
        // The string held in _storage is a Swift string, natively stored as UTF-8. There is no UTF-16 data that can be
        // returned here. If, in the future, CFStrings are lazy-bridged to Swift Strings and the address of the CFString
        // is held as a foreign object in the String then it may be possible to return a pointer here.
        return nil
    }

    internal var _encodingCantBeStoredInEightBitCFString: Bool {
        if type(of: self) == NSString.self || type(of: self) == NSMutableString.self {
            return !_storage._guts._isContiguousASCII
        }
        return false
    }
    
    internal override var _cfTypeID: CFTypeID {
        return CFStringGetTypeID()
    }
  
    open override func isEqual(_ object: Any?) -> Bool {
        guard let string = (object as? NSString)?._swiftObject else { return false }
        return self.isEqual(to: string)
    }
    
    open override var description: String {
        return _swiftObject
    }
    
    open override var hash: Int {
        return Int(bitPattern:CFStringHashNSString(self._cfObject))
    }
}

extension NSString {
    public func getCharacters(_ buffer: UnsafeMutablePointer<unichar>, range: NSRange) {
        if type(of: self) == NSString.self || type(of: self) == NSMutableString.self {
            let utf16 = _storage.utf16
            var idx = utf16.index(utf16.startIndex, offsetBy: range.location)
            for offset in 0..<range.length {
                buffer[offset] = utf16[idx]
                idx = utf16.index(after: idx)
            }
        } else {
            //TODO: fast paths for _fastContents != nil / _fastCString != nil
            for idx in 0..<range.length {
                buffer[idx] = character(at: idx + range.location)
            }
        }
    }
    
    public func substring(from: Int) -> String {
        if type(of: self) == NSString.self || type(of: self) == NSMutableString.self {
            return String(_storage.utf16.suffix(from: _storage.utf16.index(_storage.utf16.startIndex, offsetBy: from)))!
        } else {
            return substring(with: NSRange(location: from, length: length - from))
        }
    }
    
    public func substring(to: Int) -> String {
        if type(of: self) == NSString.self || type(of: self) == NSMutableString.self {
            return String(_storage.utf16.prefix(upTo: _storage.utf16.index(_storage.utf16.startIndex, offsetBy: to)))!
        } else {
            return substring(with: NSRange(location: 0, length: to))
        }
    }
    
    public func substring(with range: NSRange) -> String {
        if type(of: self) == NSString.self || type(of: self) == NSMutableString.self {
            let start = _storage.utf16.startIndex
            let min = _storage.utf16.index(start, offsetBy: range.location)
            let max = _storage.utf16.index(min, offsetBy: range.length)
            return String(decoding: _storage.utf16[min..<max], as: UTF16.self)
        } else {
            let buff = UnsafeMutablePointer<unichar>.allocate(capacity: range.length)
            getCharacters(buff, range: range)
            let result = String(utf16CodeUnits: buff, count: range.length)
            buff.deinitialize(count: 1)
            buff.deallocate()
            return result
        }
    }
    
    public func compare(_ string: String) -> ComparisonResult {
        return compare(string, options: [], range: NSRange(location: 0, length: length))
    }
    
    public func compare(_ string: String, options mask: CompareOptions) -> ComparisonResult {
        return compare(string, options: mask, range: NSRange(location: 0, length: length))
    }
    
    public func compare(_ string: String, options mask: CompareOptions, range compareRange: NSRange) -> ComparisonResult {
        return compare(string, options: mask, range: compareRange, locale: nil)
    }
    
    public func compare(_ string: String, options mask: CompareOptions, range compareRange: NSRange, locale: Any?) -> ComparisonResult {
        var res: CFComparisonResult
        if let loc = locale {
            res = CFStringCompareWithOptionsAndLocale(_cfObject, string._cfObject, CFRange(compareRange), mask._cfValue(true), (loc as! NSLocale)._cfObject)
        } else {
            res = CFStringCompareWithOptionsAndLocale(_cfObject, string._cfObject, CFRange(compareRange), mask._cfValue(true), nil)
        }
        return ComparisonResult._fromCF(res)
    }
    
    public func caseInsensitiveCompare(_ string: String) -> ComparisonResult {
        return compare(string, options: .caseInsensitive, range: NSRange(location: 0, length: length))
    }
    
    public func localizedCompare(_ string: String) -> ComparisonResult {
        return compare(string, options: [], range: NSRange(location: 0, length: length), locale: Locale.current._bridgeToObjectiveC())
    }
    
    public func localizedCaseInsensitiveCompare(_ string: String) -> ComparisonResult {
        return compare(string, options: .caseInsensitive, range: NSRange(location: 0, length: length), locale: Locale.current._bridgeToObjectiveC())
    }
    
    public func localizedStandardCompare(_ string: String) -> ComparisonResult {
        return compare(string, options: [.caseInsensitive, .numeric, .widthInsensitive, .forcedOrdering], range: NSRange(location: 0, length: length), locale: Locale.current._bridgeToObjectiveC())
    }
    
    public func isEqual(to aString: String) -> Bool {
        if type(of: self) == NSString.self || type(of: self) == NSMutableString.self {
            return _storage == aString
        } else {
            return length == aString.length && compare(aString, options: .literal, range: NSRange(location: 0, length: length)) == .orderedSame
        }
    }
    
    public func hasPrefix(_ str: String) -> Bool {
        return range(of: str, options: .anchored, range: NSRange(location: 0, length: length)).location != NSNotFound
    }
    
    public func hasSuffix(_ str: String) -> Bool {
        return range(of: str, options: [.anchored, .backwards], range: NSRange(location: 0, length: length)).location != NSNotFound
    }
    
    public func commonPrefix(with str: String, options mask: CompareOptions = []) -> String {

        let receiver = self as String
        if receiver.isEmpty || str.isEmpty {
            return ""
        }
        let literal = mask.contains(.literal)
        let caseInsensitive = mask.contains(.caseInsensitive)

        var result = ""
        var otherIterator = str.makeIterator()

        for ch in receiver {
            guard let otherCh = otherIterator.next() else { break }

            if ch != otherCh {
                guard caseInsensitive && String(ch).lowercased() == String(otherCh).lowercased() else { break }
            }

            if literal && otherCh.unicodeScalars.count != ch.unicodeScalars.count { break }
            result.append(ch)
        }

        return result
    }
    
    public func contains(_ str: String) -> Bool {
        return range(of: str, options: [], range: NSRange(location: 0, length: length), locale: nil).location != NSNotFound
    }
    
    public func localizedCaseInsensitiveContains(_ str: String) -> Bool {
        return range(of: str, options: .caseInsensitive, range: NSRange(location: 0, length: length), locale: Locale.current).location != NSNotFound
    }
    
    public func localizedStandardContains(_ str: String) -> Bool {
        return range(of: str, options: [.caseInsensitive, .diacriticInsensitive], range: NSRange(location: 0, length: length), locale: Locale.current).location != NSNotFound
    }
    
    public func localizedStandardRange(of str: String) -> NSRange {
        return range(of: str, options: [.caseInsensitive, .diacriticInsensitive], range: NSRange(location: 0, length: length), locale: Locale.current)
    }
    
    public func range(of searchString: String) -> NSRange {
        return range(of: searchString, options: [], range: NSRange(location: 0, length: length), locale: nil)
    }
    
    public func range(of searchString: String, options mask: CompareOptions = []) -> NSRange {
        return range(of: searchString, options: mask, range: NSRange(location: 0, length: length), locale: nil)
    }
    
    public func range(of searchString: String, options mask: CompareOptions = [], range searchRange: NSRange) -> NSRange {
        return range(of: searchString, options: mask, range: searchRange, locale: nil)
    }
    
    internal func _rangeOfRegularExpressionPattern(regex pattern: String, options mask: CompareOptions, range searchRange: NSRange, locale: Locale?) -> NSRange {
        var matchedRange = NSRange(location: NSNotFound, length: 0)
        let regexOptions: NSRegularExpression.Options = mask.contains(.caseInsensitive) ? .caseInsensitive : []
        let matchingOptions: NSRegularExpression.MatchingOptions = mask.contains(.anchored) ? .anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            matchedRange = regex.rangeOfFirstMatch(in: _swiftObject, options: matchingOptions, range: searchRange)
        }
        return matchedRange
    }
    
    public func range(of searchString: String, options mask: CompareOptions = [], range searchRange: NSRange, locale: Locale?) -> NSRange {
        let findStrLen = searchString.length
        let len = length
        
        precondition(searchRange.length <= len && searchRange.location <= len - searchRange.length, "Bounds Range {\(searchRange.location), \(searchRange.length)} out of bounds; string length \(len)")
        
        if mask.contains(.regularExpression) {
            return _rangeOfRegularExpressionPattern(regex: searchString, options: mask, range:searchRange, locale: locale)
        }
        
        if searchRange.length == 0 || findStrLen == 0 { // ??? This last item can't be here for correct Unicode compares
            return NSRange(location: NSNotFound, length: 0)
        }
        
        var result = CFRange()
        let res = withUnsafeMutablePointer(to: &result) { (rangep: UnsafeMutablePointer<CFRange>) -> Bool in
            if let loc = locale {
                return CFStringFindWithOptionsAndLocale(_cfObject, searchString._cfObject, CFRange(searchRange), mask._cfValue(true), loc._cfObject, rangep)
            } else {
                return CFStringFindWithOptionsAndLocale(_cfObject, searchString._cfObject, CFRange(searchRange), mask._cfValue(true), nil, rangep)
            }
        }
        if res {
            return NSRange(location: result.location, length: result.length)
        } else {
            return NSRange(location: NSNotFound, length: 0)
        }
    }
    
    public func rangeOfCharacter(from searchSet: CharacterSet) -> NSRange {
        return rangeOfCharacter(from: searchSet, options: [], range: NSRange(location: 0, length: length))
    }
    
    public func rangeOfCharacter(from searchSet: CharacterSet, options mask: CompareOptions = []) -> NSRange {
        return rangeOfCharacter(from: searchSet, options: mask, range: NSRange(location: 0, length: length))
    }
    
    public func rangeOfCharacter(from searchSet: CharacterSet, options mask: CompareOptions = [], range searchRange: NSRange) -> NSRange {
        let len = length
        
        precondition(searchRange.length <= len && searchRange.location <= len - searchRange.length, "Bounds Range {\(searchRange.location), \(searchRange.length)} out of bounds; string length \(len)")
        
        var result = CFRange()
        let res = withUnsafeMutablePointer(to: &result) { (rangep: UnsafeMutablePointer<CFRange>) -> Bool in
            return CFStringFindCharacterFromSet(_cfObject, searchSet._cfObject, CFRange(searchRange), mask._cfValue(), rangep)
        }
        if res {
            return NSRange(location: result.location, length: result.length)
        } else {
            return NSRange(location: NSNotFound, length: 0)
        }
    }
    
    public func rangeOfComposedCharacterSequence(at index: Int) -> NSRange {
        let range = CFStringGetRangeOfCharacterClusterAtIndex(_cfObject, index, kCFStringComposedCharacterCluster)
        return NSRange(location: range.location, length: range.length)
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
        return NSRange(location: start, length: end - start)
    }
    
    public func appending(_ aString: String) -> String {
        return _swiftObject + aString
    }

    public var doubleValue: Double {
        var start: Int = 0
        var result = 0.0
        let _ = _swiftObject.scan(CharacterSet.whitespaces, locale: nil, locationToScanFrom: &start) { (value: Double) -> Void in
            result = value
        }
        return result
    }

    public var floatValue: Float {
        var start: Int = 0
        var result: Float = 0.0
        let _ = _swiftObject.scan(CharacterSet.whitespaces, locale: nil, locationToScanFrom: &start) { (value: Float) -> Void in
            result = value
        }
        return result
    }

    public var intValue: Int32 {
        return Scanner(string: _swiftObject).scanInt32() ?? 0
    }

    public var integerValue: Int {
        let scanner = Scanner(string: _swiftObject)
        var value: Int = 0
        let _ = scanner.scanInt(&value)
        return value
    }

    public var longLongValue: Int64 {
        return Scanner(string: _swiftObject).scanInt64() ?? 0
    }

    public var boolValue: Bool {
        let scanner = Scanner(string: _swiftObject)
        // skip initial whitespace if present
        let _ = scanner.scanCharacters(from: .whitespaces)

        if scanner.scanCharacters(from: CharacterSet(charactersIn: "tTyY")) != nil {
            return true
        }

        // scan a single optional '+' or '-' character, followed by zeroes
        if scanner.scanString("+") == nil {
            let _ = scanner.scanString("-")
        }
        
        // scan any following zeroes
        let _ = scanner.scanCharacters(from: CharacterSet(charactersIn: "0"))
        return scanner.scanCharacters(from: CharacterSet(charactersIn: "123456789")) != nil
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
        return uppercased(with: Locale.current)
    }
    
    public var localizedLowercase: String {
        return lowercased(with: Locale.current)
    }
    
    public var localizedCapitalized: String {
        return capitalized(with: Locale.current)
    }
    
    public func uppercased(with locale: Locale?) -> String {
        let mutableCopy = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, self._cfObject)!
        CFStringUppercase(mutableCopy, locale?._cfObject)
        return mutableCopy._swiftObject
    }

    public func lowercased(with locale: Locale?) -> String {
        let mutableCopy = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, self._cfObject)!
        CFStringLowercase(mutableCopy, locale?._cfObject)
        return mutableCopy._swiftObject
    }
    
    public func capitalized(with locale: Locale?) -> String {
        let mutableCopy = CFStringCreateMutableCopy(kCFAllocatorSystemDefault, 0, self._cfObject)!
        CFStringCapitalize(mutableCopy, locale?._cfObject)
        return mutableCopy._swiftObject
    }
    
    internal func _getBlockStart(_ startPtr: UnsafeMutablePointer<Int>?, end endPtr: UnsafeMutablePointer<Int>?, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>?, forRange range: NSRange, stopAtLineSeparators line: Bool) {
        let len = length
        var ch: unichar
        
        precondition(range.length <= len && range.location <= len - range.length, "Range {\(range.location), \(range.length)} is out of bounds of length \(len)")
        
        if range.location == 0 && range.length == len && contentsEndPtr == nil { // This occurs often
            startPtr?.pointee = 0
            endPtr?.pointee = range.length
            return
        }
        /* Find the starting point first */
        if let startPtr = startPtr {
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
                startPtr.pointee = start
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
        return NSRange(location: start, length: lineEnd - start)
    }
    
    public func getParagraphStart(_ startPtr: UnsafeMutablePointer<Int>?, end parEndPtr: UnsafeMutablePointer<Int>?, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>?, for range: NSRange) {
        _getBlockStart(startPtr, end: parEndPtr, contentsEnd: contentsEndPtr, forRange: range, stopAtLineSeparators: false)
    }
    
    public func paragraphRange(for range: NSRange) -> NSRange {
        var start = 0
        var parEnd = 0
        getParagraphStart(&start, end: &parEnd, contentsEnd: nil, for: range)
        return NSRange(location: start, length: parEnd - start)
    }
    
    private enum EnumerateBy : Sendable {
        case lines
        case paragraphs
        case composedCharacterSequences
        
        init?(parsing options: EnumerationOptions) {
            var me: EnumerateBy?
            
            // We don't test for .byLines because .byLines.rawValue == 0, which unfortunately means _every_ NSString.EnumerationOptions contains .byLines.
            // Instead, we just default to .lines below.
            
            if options.contains(.byParagraphs) {
                guard me == nil else { return nil }
                me = .paragraphs
            }
            
            if options.contains(.byComposedCharacterSequences) {
                guard me == nil else { return nil }
                me = .composedCharacterSequences
            }
            
            self = me ?? .lines
        }
    }
    
    public func enumerateSubstrings(in range: NSRange, options opts: EnumerationOptions = [], using block: (String?, NSRange, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        guard let enumerateBy = EnumerateBy(parsing: opts) else {
            fatalError("You must specify only one of the .by… enumeration options.")
        }
        
        // We do not heed the .localized flag because it affects only by-words and by-sentences enumeration, which we do not support in s-c-f.
        
        var currentIndex = opts.contains(.reverse) ? length - 1 : 0
        
        func shouldContinue() -> Bool {
            opts.contains(.reverse) ? currentIndex >= 0 : currentIndex < length
        }
        
        let reverse = opts.contains(.reverse)
        
        func nextIndex(after fullRange: NSRange, compensatingForLengthDifferenceFrom oldLength: Int) -> Int {
            var index = reverse ? fullRange.location - 1 : fullRange.location + fullRange.length
            
            if !reverse {
                index += (oldLength - length)
            }
            
            return index
        }
        
        while shouldContinue() {
            var range = NSRange(location: currentIndex, length: 0)
            var fullRange = range
            
            switch enumerateBy {
            case .lines:
                var start = 0, end = 0, contentsEnd = 0
                getLineStart(&start, end: &end, contentsEnd: &contentsEnd, for: range)
                range.location = start
                range.length = contentsEnd - start
                fullRange.location = start
                fullRange.length = end - start
            case .paragraphs:
                var start = 0, end = 0, contentsEnd = 0
                getParagraphStart(&start, end: &end, contentsEnd: &contentsEnd, for: range)
                range.location = start
                range.length = contentsEnd - start
                fullRange.location = start
                fullRange.length = end - start
            case .composedCharacterSequences:
                range = rangeOfComposedCharacterSequences(for: range)
                fullRange = range
            }
            
            var substring: String?
            if !opts.contains(.substringNotRequired) {
                substring = self.substring(with: range)
            }
            
            let oldLength = length
            
            var stop: ObjCBool = false
            block(substring, range, fullRange, &stop)
            if stop.boolValue {
                return
            }
            
            currentIndex = nextIndex(after: fullRange, compensatingForLengthDifferenceFrom: oldLength)
        }
    }
    
    public func enumerateLines(_ block: (String, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateSubstrings(in: NSRange(location: 0, length: length), options:.byLines) { substr, substrRange, enclosingRange, stop in
            block(substr!, stop)
        }
    }
    
    @available(*, deprecated, message: "On platforms without Objective-C autorelease pools, use withCString instead")
    public var utf8String: UnsafePointer<Int8>? {
        guard let buffer = _allocateBytesInEncoding(self, .utf8) else {
            return nil
        }
        // leaked. On Darwin, freed via an autorelease
        return UnsafePointer<Int8>(buffer.baseAddress)
    }
    
    public var fastestEncoding: UInt {
        return String.Encoding.unicode.rawValue
    }
    
    public var smallestEncoding: UInt {
        if canBeConverted(to: String.Encoding.ascii.rawValue) {
            return String.Encoding.ascii.rawValue
        }
        return String.Encoding.unicode.rawValue
    }
    
    public func data(using encoding: UInt, allowLossyConversion lossy: Bool = false) -> Data? {
        let len = length
        var reqSize = 0
        
        let cfStringEncoding = CFStringConvertNSStringEncodingToEncoding(numericCast(encoding))
        if !CFStringIsEncodingAvailable(cfStringEncoding) {
            return nil
        }
        
        let convertedLen = __CFStringEncodeByteStream(_cfObject, 0, len, true, cfStringEncoding, lossy ? (encoding == String.Encoding.ascii.rawValue ? 0xFF : 0x3F) : 0, nil, 0, &reqSize)
        if convertedLen != len {
            return nil 	// Not able to do it all...
        }
        
        if 0 < reqSize {
            var data = Data(count: reqSize)
            data.count = data.withUnsafeMutableBytes { (mutableRawBuffer: UnsafeMutableRawBufferPointer) -> Int in
                let mutableBytes = mutableRawBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
                if __CFStringEncodeByteStream(_cfObject, 0, len, true, cfStringEncoding, lossy ? (encoding == String.Encoding.ascii.rawValue ? 0xFF : 0x3F) : 0, mutableBytes, reqSize, &reqSize) == convertedLen {
                    return reqSize
                } else {
                    fatalError("didn't convert all characters")
                }
            }

            return data
        }
        return Data()
    }
    
    public func data(using encoding: UInt) -> Data? {
        return data(using: encoding, allowLossyConversion: false)
    }
    
    public func canBeConverted(to encoding: UInt) -> Bool {
        if encoding == String.Encoding.unicode.rawValue || encoding == String.Encoding.nonLossyASCII.rawValue || encoding == String.Encoding.utf8.rawValue {
            return true
        }
        return __CFStringEncodeByteStream(_cfObject, 0, length, false,
                                          CFStringConvertNSStringEncodingToEncoding(numericCast(encoding)),
                                          0, nil, 0, nil) == length
    }
   
    @available(*, deprecated, message: "On platforms without Objective-C autorelease pools, use withCString(encodedAs:_) instead")
    public func cString(using encoding: UInt) -> UnsafePointer<Int8>? {
        // leaked. On Darwin, freed via an autorelease
        guard let buffer = _allocateBytesInEncoding(self,  String.Encoding(rawValue: encoding)) else {
            return nil
        }
        // leaked. On Darwin, freed via an autorelease
        return UnsafePointer<Int8>(buffer.baseAddress)
    }

    internal func _withCString<T>(using encoding: UInt, closure: (UnsafePointer<Int8>?) -> T) -> T {
        let buffer = _allocateBytesInEncoding(self, String.Encoding(rawValue: encoding))
        let result = closure(buffer?.baseAddress)
        if let buffer {
            buffer.deinitialize()
            buffer.deallocate()
        }
        return result
    }
    
    public func getCString(_ buffer: UnsafeMutablePointer<Int8>, maxLength maxBufferCount: Int, encoding: UInt) -> Bool {
        var used = 0
        if type(of: self) == NSString.self || type(of: self) == NSMutableString.self {
            if _storage._guts._isContiguousASCII {
                used = min(self.length, maxBufferCount - 1)
                
                // This is mutable, but since we just checked the contiguous behavior, should not copy
                var copy = _storage
                copy.withUTF8 {
                    $0.withMemoryRebound(to: Int8.self) {
                        buffer.update(from: $0.baseAddress!, count: used)
                    }
                }
                
                buffer.advanced(by: used).initialize(to: 0)
                return true
            }
        }
        if getBytes(UnsafeMutableRawPointer(buffer), maxLength: maxBufferCount, usedLength: &used, encoding: encoding, options: [], range: NSRange(location: 0, length: self.length), remaining: nil) {
            buffer.advanced(by: used).initialize(to: 0)
            return true
        }
        return false
    }
    
    public func getBytes(_ buffer: UnsafeMutableRawPointer?, maxLength maxBufferCount: Int, usedLength usedBufferCount: UnsafeMutablePointer<Int>?, encoding: UInt, options: EncodingConversionOptions = [], range: NSRange, remaining leftover: NSRangePointer?) -> Bool {
        var totalBytesWritten = 0
        var numCharsProcessed = 0
        let cfStringEncoding =
            CFStringConvertNSStringEncodingToEncoding(numericCast(encoding))
        var result = true
        if length > 0 {
            if CFStringIsEncodingAvailable(cfStringEncoding) {
                let lossyOk = options.contains(.allowLossy)
                let externalRep = options.contains(.externalRepresentation)
                let failOnPartial = options.contains(.failOnPartialEncodingConversion)
                let bytePtr = buffer?.bindMemory(to: UInt8.self, capacity: maxBufferCount)
                numCharsProcessed = __CFStringEncodeByteStream(_cfObject, range.location, range.length, externalRep, cfStringEncoding, lossyOk ? (encoding == String.Encoding.ascii.rawValue ? 0xFF : 0x3F) : 0, bytePtr, bytePtr != nil ? maxBufferCount : 0, &totalBytesWritten)
                if (failOnPartial && numCharsProcessed < range.length) || numCharsProcessed == 0 {
                    result = false
                }
            } else {
                result = false /* ??? Need other encodings */
            }
        }
        usedBufferCount?.pointee = totalBytesWritten
        leftover?.pointee = NSRange(location: range.location + numCharsProcessed, length: range.length - numCharsProcessed)
        return result
    }
    
    public func maximumLengthOfBytes(using enc: UInt) -> Int {
        let cfEnc = CFStringConvertNSStringEncodingToEncoding(numericCast(enc))
        let result = CFStringGetMaximumSizeForEncoding(length, cfEnc)
        return result == kCFNotFound ? 0 : result
    }
    
    public func lengthOfBytes(using enc: UInt) -> Int {
        let len = length
        var numBytes: CFIndex = 0
        let cfEnc = CFStringConvertNSStringEncodingToEncoding(numericCast(enc))
        let convertedLen = __CFStringEncodeByteStream(_cfObject, 0, len, false, cfEnc, 0, nil, 0, &numBytes)
        return convertedLen != len ? 0 : numBytes
    }
    
    private static nonisolated(unsafe) let _availableStringEncodings : UnsafePointer<UInt> = {
        let cfEncodings = CFStringGetListOfAvailableEncodings()!
        var idx = 0
        var numEncodings = 0
        
        while cfEncodings.advanced(by: idx).pointee != kCFStringEncodingInvalidId {
            idx += 1
            numEncodings += 1
        }
        
        let theEncodingList = UnsafeMutablePointer<String.Encoding.RawValue>.allocate(capacity: numEncodings + 1)
        theEncodingList.advanced(by: numEncodings).pointee = 0 // Terminator
        
        numEncodings -= 1
        while numEncodings >= 0 {
            theEncodingList.advanced(by: numEncodings).pointee =
                numericCast(CFStringConvertEncodingToNSStringEncoding(cfEncodings.advanced(by: numEncodings).pointee))
            numEncodings -= 1
        }
        
        return UnsafePointer<UInt>(theEncodingList)
    }()
    
    public class var availableStringEncodings: UnsafePointer<UInt> {
        return _availableStringEncodings
    }
    
    public class func localizedName(of encoding: UInt) -> String {
        if let theString = CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(numericCast(encoding))) {
            // TODO: read the localized version from the Foundation "bundle"
            return theString._swiftObject
        }
        
        return ""
    }
    
    public class var defaultCStringEncoding: UInt {
        return numericCast(CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding()))
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
        var lrange = range(of: separator, options: [], range: NSRange(location: 0, length: len))
        if lrange.length == 0 {
            return [_swiftObject]
        } else {
            var array = [String]()
            var srange = NSRange(location: 0, length: len)
            while true {
                let trange = NSRange(location: srange.location, length: lrange.location - srange.location)
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
    
    public func components(separatedBy separator: CharacterSet) -> [String] {
        let len = length
        var range = rangeOfCharacter(from: separator, options: [], range: NSRange(location: 0, length: len))
        if range.length == 0 {
            return [_swiftObject]
        } else {
            var array = [String]()
            var srange = NSRange(location: 0, length: len)
            while true {
                let trange = NSRange(location: srange.location, length: range.location - srange.location)
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
    
    public func trimmingCharacters(in set: CharacterSet) -> String {
        let len = length
        var buf = _NSStringBuffer(string: self, start: 0, end: len)
        while !buf.isAtEnd,
            let character = UnicodeScalar(buf.currentCharacter),
            set.contains(character) {
                buf.advance()
        }
        
        let startOfNonTrimmedRange = buf.location // This points at the first char not in the set
        
        if startOfNonTrimmedRange == len { // Note that this also covers the len == 0 case, which is important to do here before the len-1 in the next line.
            return ""
        } else if startOfNonTrimmedRange < len - 1 {
            buf.location = len - 1
            while let character = UnicodeScalar(buf.currentCharacter),
                set.contains(character),
                buf.location >= startOfNonTrimmedRange {
                    buf.rewind()
            }
            let endOfNonTrimmedRange = buf.location
            return substring(with: NSRange(location: startOfNonTrimmedRange, length: endOfNonTrimmedRange + 1 - startOfNonTrimmedRange))
        } else {
            return substring(with: NSRange(location: startOfNonTrimmedRange, length: 1))
        }
    }
    
    public func padding(toLength newLength: Int, withPad padString: String, startingAt padIndex: Int) -> String {
        let len = length
        if newLength <= len {	// The simple cases (truncation)
            return newLength == len ? _swiftObject : substring(with: NSRange(location: 0, length: newLength))
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
    
    public func folding(options: CompareOptions = [], locale: Locale?) -> String {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)!
        CFStringReplaceAll(string, self._cfObject)
        CFStringFold(string, options._cfValue(), locale?._cfObject)
        return string._swiftObject
    }
    
    internal func _stringByReplacingOccurrencesOfRegularExpressionPattern(_ pattern: String, withTemplate replacement: String, options: CompareOptions, range: NSRange) -> String {
        let regexOptions: NSRegularExpression.Options = options.contains(.caseInsensitive) ? .caseInsensitive : []
        let matchingOptions: NSRegularExpression.MatchingOptions = options.contains(.anchored) ? .anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            return regex.stringByReplacingMatches(in: _swiftObject, options: matchingOptions, range: range, withTemplate: replacement)
        }
        return ""
    }
    
    public func replacingOccurrences(of target: String, with replacement: String, options: CompareOptions = [], range searchRange: NSRange) -> String {
        if options.contains(.regularExpression) {
            return _stringByReplacingOccurrencesOfRegularExpressionPattern(target, withTemplate: replacement, options: options, range: searchRange)
        }
        let str = mutableCopy(with: nil) as! NSMutableString
        if str.replaceOccurrences(of: target, with: replacement, options: options, range: searchRange) == 0 {
            return _swiftObject
        } else {
            return str._swiftObject
        }
    }
    
    public func replacingOccurrences(of target: String, with replacement: String) -> String {
        return replacingOccurrences(of: target, with: replacement, options: [], range: NSRange(location: 0, length: length))
    }
    
    public func replacingCharacters(in range: NSRange, with replacement: String) -> String {
        let str = mutableCopy(with: nil) as! NSMutableString
        str.replaceCharacters(in: range, with: replacement)
        return str._swiftObject
    }
    
    public func applyingTransform(_ transform: StringTransform, reverse: Bool) -> String? {
        let string = CFStringCreateMutable(kCFAllocatorSystemDefault, 0)!
        CFStringReplaceAll(string, _cfObject)
        if (CFStringTransform(string, nil, transform.rawValue._cfObject, reverse)) {
            return string._swiftObject
        } else {
            return nil
        }
    }
    
    internal func _getExternalRepresentation(_ data: inout Data, _ dest: URL, _ enc: UInt) throws {
        let length = self.length
        var numBytes = 0
        let theRange = NSRange(location: 0, length: length)
        if !getBytes(nil, maxLength: Int.max - 1, usedLength: &numBytes, encoding: enc, options: [.externalRepresentation], range: theRange, remaining: nil) {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteInapplicableStringEncoding.rawValue, userInfo: [
                NSURLErrorKey: dest,
            ])
        }
        var mData = Data(count: numBytes)
        // The getBytes:... call should hopefully not fail, given it succeeded above, but check anyway (mutable string changing behind our back?)
        var used = 0
        try mData.withUnsafeMutableBytes { (mutableRawBuffer: UnsafeMutableRawBufferPointer) -> Void in
            if !getBytes(mutableRawBuffer.baseAddress, maxLength: numBytes, usedLength: &used, encoding: enc, options: [.externalRepresentation], range: theRange, remaining: nil) {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnknown.rawValue, userInfo: [
                    NSURLErrorKey: dest,
                ])
            }
        }
        data = mData
    }
    
    #if os(WASI)
    @available(*, unavailable, message: "WASI does not support atomic file-writing as it does not have temporary directories")
    #endif
    internal func _writeTo(_ url: URL, _ useAuxiliaryFile: Bool, _ enc: UInt) throws {
        #if os(WASI)
        throw CocoaError(.featureUnsupported)
        #else
        var data = Data()
        try _getExternalRepresentation(&data, url, enc)
        try data.write(to: url, options: useAuxiliaryFile ? .atomic : [])
        #endif
    }
    
    #if os(WASI)
    @available(*, unavailable, message: "WASI does not support atomic file-writing as it does not have temporary directories")
    #endif
    public func write(to url: URL, atomically useAuxiliaryFile: Bool, encoding enc: UInt) throws {
        try _writeTo(url, useAuxiliaryFile, enc)
    }
    
    #if os(WASI)
    @available(*, unavailable, message: "WASI does not support atomic file-writing as it does not have temporary directories")
    #endif
    public func write(toFile path: String, atomically useAuxiliaryFile: Bool, encoding enc: UInt) throws {
        try _writeTo(URL(fileURLWithPath: path), useAuxiliaryFile, enc)
    }
    
    public convenience init(charactersNoCopy characters: UnsafeMutablePointer<unichar>, length: Int, freeWhenDone freeBuffer: Bool) /* "NoCopy" is a hint */ {
        // ignore the no-copy-ness
        self.init(characters: characters, length: length)
        if freeBuffer { // can't take a hint here...
            free(UnsafeMutableRawPointer(characters))
        }
    }
    
    public convenience init?(utf8String nullTerminatedCString: UnsafePointer<Int8>) {
        guard let str = String(validatingCString: nullTerminatedCString) else { return nil }
        self.init(str)
    }
    
    public convenience init(format: String, arguments argList: CVaListPointer) {
        let str = CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, nil, format._cfObject, argList)!
        self.init(str._swiftObject)
    }
    
    public convenience init(format: String, locale: AnyObject?, arguments argList: CVaListPointer) {
        let str: CFString
        if let loc = locale {
            if type(of: loc) === NSLocale.self {
                // Create a CFLocaleRef
                let cf = (loc as! NSLocale)._cfObject
                str = CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, unsafeBitCast(cf, to: CFDictionary.self), format._cfObject, argList)
            } else if type(of: loc) === NSDictionary.self {
                let dict = (loc as! NSDictionary)._cfObject
                str = CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, dict, format._cfObject, argList)
            } else {
                fatalError("locale parameter must be a NSLocale or a NSDictionary")
            }
        } else {
            str = CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, nil, format._cfObject, argList)
        }
        self.init(str._swiftObject)
    }
    
    public convenience init(format: NSString, _ args: CVarArg...) {
        let str = withVaList(args) { (vaPtr) -> CFString? in
            CFStringCreateWithFormatAndArguments(kCFAllocatorSystemDefault, nil, format._cfObject, vaPtr)
        }!
        self.init(str._swiftObject)
    }
    
    public convenience init?(data: Data, encoding: UInt) {
        if data.isEmpty {
            self.init("")
        } else {
        guard let cf = data.withUnsafeBytes({ (rawBuffer: UnsafeRawBufferPointer) -> CFString? in
            let bytes = rawBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            return CFStringCreateWithBytes(kCFAllocatorDefault, bytes, data.count,
                                           CFStringConvertNSStringEncodingToEncoding(numericCast(encoding)), true)
        }) else { return nil }
        
            var str: String?
            if String._conditionallyBridgeFromObjectiveC(cf._nsObject, result: &str) {
                self.init(str!)
            } else {
                return nil
            }
        }
    }
    
    public convenience init?(bytes: UnsafeRawPointer, length len: Int, encoding: UInt) {
        let bytePtr = bytes.bindMemory(to: UInt8.self, capacity: len)
        guard let cf = CFStringCreateWithBytes(kCFAllocatorDefault, bytePtr, len, CFStringConvertNSStringEncodingToEncoding(numericCast(encoding)), true) else {
            return nil
        }
        var str: String?
        if String._conditionallyBridgeFromObjectiveC(cf._nsObject, result: &str) {
            self.init(str!)
        } else {
            return nil
        }
    }
    
    public convenience init?(bytesNoCopy bytes: UnsafeMutableRawPointer, length len: Int, encoding: UInt, freeWhenDone freeBuffer: Bool) /* "NoCopy" is a hint */ {
        // just copy for now since the internal storage will be a copy anyhow
        self.init(bytes: bytes, length: len, encoding: encoding)
        if freeBuffer { // don't take the hint
#if os(Windows)
          bytes.deallocate()
#else
          free(bytes)
#endif
        }
    }

    public convenience init(contentsOf url: URL, encoding enc: UInt) throws {
        let readResult = try NSData(contentsOf: url, options: [])

        let cf = try withExtendedLifetime(readResult) { _ -> CFString in
            let bytePtr = readResult.bytes.bindMemory(to: UInt8.self, capacity: readResult.length)
            guard let cf = CFStringCreateWithBytes(kCFAllocatorDefault, bytePtr, readResult.length, CFStringConvertNSStringEncodingToEncoding(numericCast(enc)), true) else {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileReadInapplicableStringEncoding.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "Unable to create a string using the specified encoding."
                    ])
            }
            return cf
        }

        var str: String?
        if String._conditionallyBridgeFromObjectiveC(cf._nsObject, result: &str) {
            self.init(str!)
        } else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileReadInapplicableStringEncoding.rawValue, userInfo: [
                NSDebugDescriptionErrorKey : "Unable to bridge CFString to String."
                ])
        }
    }

    public convenience init(contentsOfFile path: String, encoding enc: UInt) throws {
        try self.init(contentsOf: URL(fileURLWithPath: path), encoding: enc)
    }

    public convenience init(contentsOf url: URL, usedEncoding enc: UnsafeMutablePointer<UInt>?) throws {
        let (readResult, textEncodingNameMaybe) = try NSData.contentsOf(url: url)


        let (cf, encoding) = try withExtendedLifetime(readResult) { _ -> (CFString, UInt) in
            let encoding: UInt
            let offset: Int
            // Look for a BOM (Byte Order Marker) to try and determine the text Encoding, this also skips
            // over the bytes. This takes precedence over the textEncoding in the http header
            let bytePtr = readResult.bytes.bindMemory(to: UInt8.self, capacity:readResult.length)
            if readResult.length >= 4 && bytePtr[0] == 0xFF && bytePtr[1] == 0xFE && bytePtr[2] == 0x00 && bytePtr[3] == 0x00 {
                encoding = String.Encoding.utf32LittleEndian.rawValue
                offset = 4
            }
            else if readResult.length >= 2 && bytePtr[0] == 0xFE && bytePtr[1] == 0xFF {
                encoding = String.Encoding.utf16BigEndian.rawValue
                offset = 2
            }
            else if readResult.length >= 2 && bytePtr[0] == 0xFF && bytePtr[1] == 0xFE {
                encoding = String.Encoding.utf16LittleEndian.rawValue
                offset = 2
            }
            else if readResult.length >= 4 && bytePtr[0] == 0x00 && bytePtr[1] == 0x00 && bytePtr[2] == 0xFE && bytePtr[3] == 0xFF {
                encoding = String.Encoding.utf32BigEndian.rawValue
                offset = 4
            }
            else if let charSet = textEncodingNameMaybe, let textEncoding = String.Encoding(charSet: charSet) {
                encoding = textEncoding.rawValue
                offset = 0
            } else {
                //Need to work on more conditions. This should be the default
                encoding = String.Encoding.utf8.rawValue
                offset = 0
            }

            // Since the encoding being passed includes the byte order the BOM wont be checked or skipped, so pass offset to
            // manually skip the BOM header.
            guard let cf = CFStringCreateWithBytes(kCFAllocatorDefault, bytePtr + offset, readResult.length - offset,
                                                   CFStringConvertNSStringEncodingToEncoding(numericCast(encoding)), true) else {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileReadInapplicableStringEncoding.rawValue, userInfo: [
                    NSDebugDescriptionErrorKey : "Unable to create a string using the specified encoding."
                    ])
            }
            return (cf, encoding)
        }

        var str: String?
        if String._conditionallyBridgeFromObjectiveC(cf._nsObject, result: &str) {
            self.init(str!)
        } else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileReadInapplicableStringEncoding.rawValue, userInfo: [
                NSDebugDescriptionErrorKey : "Unable to bridge CFString to String."
                ])
        }
        enc?.pointee = encoding
    }
    
    public convenience init(contentsOfFile path: String, usedEncoding enc: UnsafeMutablePointer<UInt>?) throws {
        try self.init(contentsOf: URL(fileURLWithPath: path), usedEncoding: enc)
    }
}

extension NSString : ExpressibleByStringLiteral { }

open class NSMutableString : NSString {
    open func replaceCharacters(in range: NSRange, with aString: String) {
        guard type(of: self) === NSString.self || type(of: self) === NSMutableString.self else {
            NSRequiresConcreteImplementation()
        }

        let start = _storage.utf16.startIndex
        let min = _storage.utf16.index(start, offsetBy: range.location).samePosition(in: _storage) ?? {
            let characterRange = _storage.rangeOfComposedCharacterSequence(at: range.location)
            return _storage.utf16.index(start, offsetBy: characterRange.location)
        }()

        let max = _storage.utf16.index(start, offsetBy: range.location + range.length).samePosition(in: _storage) ?? {
            let characterRange = _storage.rangeOfComposedCharacterSequence(at: range.location + range.length)
            return _storage.utf16.index(start, offsetBy: characterRange.location)
        }()
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
        
        self.init(string: String._unconditionallyBridgeFromObjectiveC(str))
    }

    public required convenience init(unicodeScalarLiteral value: StaticString) {
        self.init(stringLiteral: value)
    }
    
    public required convenience init(extendedGraphemeClusterLiteral value: StaticString) {
        self.init(stringLiteral: value)
    }
    
    public required init(stringLiteral value: StaticString) {
        super.init(value.description)
    }

    public required init(string aString: String) {
        super.init(aString)
    }
    
    internal func appendCharacters(_ characters: UnsafePointer<unichar>, length: Int) {
        let str = String(decoding: UnsafeBufferPointer(start: characters, count: length), as: UTF16.self)
        if type(of: self) == NSMutableString.self {
            _storage.append(str)
        } else {
            replaceCharacters(in: NSRange(location: self.length, length: 0), with: str)
        }
    }
    
    internal func _cfAppendCString(_ characters: UnsafePointer<Int8>, length: Int) {
        if type(of: self) == NSMutableString.self {
            _storage.append(String(cString: characters))
        }
    }
}

extension NSMutableString {
    public func insert(_ aString: String, at loc: Int) {
        replaceCharacters(in: NSRange(location: loc, length: 0), with: aString)
    }
    
    public func deleteCharacters(in range: NSRange) {
        replaceCharacters(in: range, with: "")
    }
    
    public func append(_ aString: String) {
        replaceCharacters(in: NSRange(location: length, length: 0), with: aString)
    }
    
    public func setString(_ aString: String) {
        replaceCharacters(in: NSRange(location: 0, length: length), with: aString)
    }
    
    internal func _replaceOccurrencesOfRegularExpressionPattern(_ pattern: String, withTemplate replacement: String, options: CompareOptions, range searchRange: NSRange) -> Int {
        let regexOptions: NSRegularExpression.Options = options.contains(.caseInsensitive) ? .caseInsensitive : []
        let matchingOptions: NSRegularExpression.MatchingOptions = options.contains(.anchored) ? .anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            return regex.replaceMatches(in: self, options: matchingOptions, range: searchRange, withTemplate: replacement)
        }
        return 0
    }

    private static func makeFindResultsRangeIterator(findResults: CFArray, count: Int, backwards: Bool) -> AnyIterator<NSRange> {
        var index = 0
        return AnyIterator<NSRange>() { () -> NSRange? in
            defer { index += 1 }
            if index < count {
                let rangePtr = CFArrayGetValueAtIndex(findResults, backwards ? count - index - 1 : index)
                return NSRange(rangePtr!.load(as: CFRange.self))
            }
            return nil
        }
    }
    
    public func replaceOccurrences(of target: String, with replacement: String, options: CompareOptions = [], range searchRange: NSRange) -> Int {
        let backwards = options.contains(.backwards)
        let len = length
        
        precondition(searchRange.length <= len && searchRange.location <= len - searchRange.length, "Search range is out of bounds")
        
        if options.contains(.regularExpression) {
            return _replaceOccurrencesOfRegularExpressionPattern(target, withTemplate:replacement, options:options, range: searchRange)
        }

        guard let findResults = CFStringCreateArrayWithFindResults(kCFAllocatorSystemDefault, _cfObject, target._cfObject, CFRange(searchRange), options._cfValue(true)) else {
             return 0
        }
        let numOccurrences = CFArrayGetCount(findResults)

        let rangeIterator = NSMutableString.makeFindResultsRangeIterator(findResults: findResults, count: numOccurrences, backwards: backwards)

        guard type(of: self) == NSMutableString.self else {
            // If we're dealing with non NSMutableString, mutations must go through `replaceCharacters` (documented behavior)
            for range in rangeIterator {
                replaceCharacters(in: range, with: replacement)
            }

            return numOccurrences
        }

        var newStorage = Substring()
        var sourceStringCurrentIndex = _storage.startIndex
        for range in rangeIterator {
            let matchStartIndex = String.Index(utf16Offset: range.location, in: _storage)
            let matchEndIndex = String.Index(utf16Offset: range.location + range.length, in: _storage)
            newStorage += _storage[sourceStringCurrentIndex ..< matchStartIndex]
            newStorage += replacement
            sourceStringCurrentIndex = matchEndIndex
        }
        newStorage += _storage[sourceStringCurrentIndex ..< _storage.endIndex]
        _storage = String(newStorage)
        return numOccurrences
    }
    
    public func applyTransform(_ transform: String, reverse: Bool, range: NSRange, updatedRange resultingRange: NSRangePointer?) -> Bool {
        var cfRange = CFRangeMake(range.location, range.length)
        return withUnsafeMutablePointer(to: &cfRange) { (rangep: UnsafeMutablePointer<CFRange>) -> Bool in
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

extension NSString : _SwiftBridgeable {
    typealias SwiftType = String
    internal var _cfObject: CFString { return unsafeBitCast(self, to: CFString.self) }
    internal var _swiftObject: String { return String._unconditionallyBridgeFromObjectiveC(self) }
}

extension NSMutableString {
    internal var _cfMutableObject: CFMutableString { return unsafeBitCast(self, to: CFMutableString.self) }
}

extension CFString : _NSBridgeable, _SwiftBridgeable {
    typealias NSType = NSString
    typealias SwiftType = String
    internal var _nsObject: NSType { return unsafeBitCast(self, to: NSString.self) }
    internal var _swiftObject: String { return _nsObject._swiftObject }
}

extension String : _NSBridgeable {
    typealias NSType = NSString
    typealias CFType = CFString
    internal var _nsObject: NSType { return _bridgeToObjectiveC() }
    internal var _cfObject: CFType { return _nsObject._cfObject }
}

extension NSString : _StructTypeBridgeable {
    public typealias _StructType = String
    
    public func _bridgeToSwift() -> _StructType {
        return _StructType._unconditionallyBridgeFromObjectiveC(self)
    }
}

extension NSString : CVarArg {
    @inlinable // c-abi
    public var _cVarArgEncoding: [Int] {
        return _encodeBitsAsWords(unsafeBitCast(self, to: AnyObject.self))
    }
}

#if !_runtime(_ObjC)
extension String : CVarArg, _CVarArgObject {
    @inlinable // c-abi
    public var _cVarArgObject: CVarArg {
        return NSString(string: self)
    }

    @inlinable // c-abi
    public var _cVarArgEncoding: [Int] {
        fatalError("_cVarArgEncoding must be called on NSString instead")
    }
}
#endif

// Upcall from swift-foundation for conversion of less frequently-used encodings
@_dynamicReplacement(for: _cfStringEncodingConvert(string:using:allowLossyConversion:))
private func _cfStringEncodingConvert_corelibs_foundation(string: String, using encoding: UInt, allowLossyConversion: Bool) -> Data? {
    return (string as NSString).data(using: encoding, allowLossyConversion: allowLossyConversion)
}

@_dynamicReplacement(for: _cfMakeStringFromBytes(_:encoding:))
private func _cfMakeStringFromBytes_corelibs_foundation(_ bytes: UnsafeBufferPointer<UInt8>, encoding: UInt) -> String? {
    return NSString(bytes: bytes.baseAddress!, length: bytes.count, encoding: encoding) as? String
}
