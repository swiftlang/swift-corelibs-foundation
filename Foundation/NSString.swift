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
#endif

public struct NSStringEncodingConversionOptions : OptionSetType {
    public let rawValue : UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let AllowLossy = NSStringEncodingConversionOptions(rawValue: 1)
    public static let ExternalRepresentation = NSStringEncodingConversionOptions(rawValue: 2)
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
}

extension String : _ObjectiveCBridgeable {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    public static func _getObjectiveCType() -> Any.Type {
        return NSString.self
    }
    
    public func _bridgeToObjectiveC() -> NSString {
        return NSString(self)
    }
    
    public static func _forceBridgeFromObjectiveC(x: NSString, inout result: String?) {
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
                
                let str = String._fromWellFormedCodeUnitSequence(UTF16.self, input: UnsafeBufferPointer(start: buffer, count: length))
                buffer.destroy(length)
                buffer.dealloc(length)
                result = str
            }
        } else if x.dynamicType == _NSCFConstantString.self {
            let conststr = unsafeBitCast(x, _NSCFConstantString.self)
            let str = String._fromCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: conststr._ptr, count: Int(conststr._length)))
            result = str
        } else {
            NSUnimplemented() // TODO: subclasses
        }
    }
    
    public static func _conditionallyBridgeFromObjectiveC(x: NSString, inout result: String?) -> Bool {
        self._forceBridgeFromObjectiveC(x, result: &result)
        return true
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
}

public class NSString : NSObject, NSCopying, NSMutableCopying, NSSecureCoding, NSCoding {
    private let _cfinfo = _CFInfo(typeID: CFStringGetTypeID())
    internal var _storage: String
    
    public var length: Int {
        get {
            if self.dynamicType === NSString.self || self.dynamicType === NSMutableString.self {
                return _storage.utf16.count
            } else {
                NSRequiresConcreteImplementation()
            }
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
    
    deinit {
        _CFDeinit(self)
    }
    
    public override convenience init() {
        let characters = Array<unichar>(count: 1, repeatedValue: 0)
        self.init(characters: characters, length: 0)
    }
    
    internal init(_ string: String) {
        _storage = string
    }
    
    public convenience required init?(coder aDecoder: NSCoder) {
        NSUnimplemented()
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return self
    }
    
    public func mutableCopyWithZone(zone: NSZone) -> AnyObject {
        if self.dynamicType === NSString.self || self.dynamicType === NSMutableString.self {
            let contents = _fastContents
            if contents != nil {
                return NSMutableString(characters: contents, length: length)
            }
        }
        let characters = UnsafeMutablePointer<unichar>.alloc(length)
        self.getCharacters(characters, range: NSMakeRange(0, length))
        let result = NSMutableString(characters: characters, length: length)
        characters.destroy()
        characters.dealloc(length)
        return result
    }
    
    public static func supportsSecureCoding() -> Bool {
        return true
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        
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
        if value.hasPointerRepresentation {
            _storage = String._fromWellFormedCodeUnitSequence(UTF8.self, input: UnsafeBufferPointer(start: value.utf8Start, count: Int(value.byteSize)))
        } else {
            var uintValue = value.unicodeScalar.value
            _storage = String._fromWellFormedCodeUnitSequence(UTF32.self, input: UnsafeBufferPointer(start: &uintValue, count: 1))
        }
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
    
    override internal var _cfTypeID: CFTypeID {
        return CFStringGetTypeID()
    }
}

extension NSString {
    public func getCharacters(buffer: UnsafeMutablePointer<unichar>, range: NSRange) {
        for var idx = 0; idx < range.length; idx++ {
            buffer[idx] = characterAtIndex(idx + range.location)
        }
    }
    
    public func substringFromIndex(from: Int) -> String {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return String(_storage.utf16.suffixFrom(_storage.utf16.startIndex.advancedBy(from)))
        } else {
            return self.substringWithRange(NSMakeRange(from, self.length - from))
        }
    }
    
    public func substringToIndex(to: Int) -> String {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return String(_storage.utf16.prefixUpTo(_storage.utf16.startIndex
            .advancedBy(to)))
        } else {
            return self.substringWithRange(NSMakeRange(0, to))
        }
    }
    
    public func substringWithRange(range: NSRange) -> String {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            let start = _storage.utf16.startIndex
            return String(_storage.utf16[Range<String.UTF16View.Index>(start: start.advancedBy(range.location), end: start.advancedBy(range.location + range.length))])
        } else {
            let buff = UnsafeMutablePointer<unichar>.alloc(range.length)
            self.getCharacters(buff, range: range)
            let result = String(buff)
            buff.destroy()
            buff.dealloc(range.length)
            return result
        }
    }
    
    public func compare(string: String) -> NSComparisonResult {
        return compare(string, options: [], range:NSMakeRange(0, self.length), locale: nil)
    }
    
    public func compare(string: String, options mask: NSStringCompareOptions) -> NSComparisonResult {
        return compare(string, options: mask, range:NSMakeRange(0, self.length), locale: nil)
    }
    
    public func compare(string: String, options mask: NSStringCompareOptions, range compareRange: NSRange) -> NSComparisonResult {
        return compare(string, options: [], range:compareRange, locale: nil)
    }
    
    public func compare(string: String, options mask: NSStringCompareOptions, range compareRange: NSRange, locale: AnyObject?) -> NSComparisonResult {
        if let _ = locale {
            NSUnimplemented()
        }
#if os(Linux)
        var cfflags = CFStringCompareFlags(mask.rawValue)
        if mask.contains(.LiteralSearch) {
            cfflags |= UInt(kCFCompareNonliteral)
        }
#else
        var cfflags = CFStringCompareFlags(rawValue: mask.rawValue)
        if mask.contains(.LiteralSearch) {
            cfflags.unionInPlace(.CompareNonliteral)
        }
#endif
        
        let cfresult = CFStringCompareWithOptionsAndLocale(self._cfObject, string._cfObject, CFRangeMake(compareRange.location, compareRange.length), cfflags, nil)
#if os(Linux)
        return NSComparisonResult(rawValue: cfresult)!
#else
        return NSComparisonResult(rawValue: cfresult.rawValue)!
#endif
    }
    
    public func caseInsensitiveCompare(string: String) -> NSComparisonResult {
        return self.compare(string, options: [.CaseInsensitiveSearch], range: NSMakeRange(0, self.length), locale: nil)
    }
    
    public func localizedCompare(string: String) -> NSComparisonResult {
        return self.compare(string, options: [], range: NSMakeRange(0, self.length), locale: NSLocale.currentLocale())
    }
    
    public func localizedCaseInsensitiveCompare(string: String) -> NSComparisonResult {
        return self.compare(string, options: [.CaseInsensitiveSearch], range: NSMakeRange(0, self.length), locale: NSLocale.currentLocale())
    }
    
    public func localizedStandardCompare(string: String) -> NSComparisonResult {
        return self.compare(string, options: [.CaseInsensitiveSearch, .NumericSearch, .WidthInsensitiveSearch, .ForcedOrderingSearch], range: NSMakeRange(0, self.length), locale: NSLocale.currentLocale())
    }
    
    public func isEqualToString(aString: String) -> Bool {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return _storage == aString
        } else {
            return self.length == aString._nsObject.length && self.compare(aString, options: [.LiteralSearch], range: NSMakeRange(0, self.length)) == .OrderedSame
        }
    }
    
    public func hasPrefix(str: String) -> Bool {
        return _swiftObject.hasPrefix(str)
    }
    
    public func hasSuffix(str: String) -> Bool {
        return _swiftObject.hasSuffix(str)
    }
    
    public func commonPrefixWithString(str: String, options mask: NSStringCompareOptions) -> String {
        NSUnimplemented()
    }
    
    public func containsString(str: String) -> Bool {
        return self.rangeOfString(str).location != NSNotFound
    }
    
    public func localizedCaseInsensitiveContainsString(str: String) -> Bool {
        return self.rangeOfString(str, options: [.CaseInsensitiveSearch], range: NSMakeRange(0, self.length), locale: NSLocale.currentLocale()).location != NSNotFound
    }
    
    public func localizedStandardContainsString(str: String) -> Bool {
        return self.rangeOfString(str, options: [.CaseInsensitiveSearch, .DiacriticInsensitiveSearch], range: NSMakeRange(0, self.length), locale: NSLocale.currentLocale()).location != NSNotFound
    }
    
    public func localizedStandardRangeOfString(str: String) -> NSRange {
        return self.rangeOfString(str, options: [.CaseInsensitiveSearch, .DiacriticInsensitiveSearch], range: NSMakeRange(0, self.length), locale: NSLocale.currentLocale())
    }
    
    public func rangeOfString(searchString: String) -> NSRange {
        return self.rangeOfString(searchString, options: [], range: NSMakeRange(0, self.length), locale: nil)
    }
    
    public func rangeOfString(searchString: String, options mask: NSStringCompareOptions) -> NSRange {
        return self.rangeOfString(searchString, options: mask, range: NSMakeRange(0, self.length), locale: nil)
    }
    
    public func rangeOfString(searchString: String, options mask: NSStringCompareOptions, range searchRange: NSRange) -> NSRange {
        return self.rangeOfString(searchString, options: mask, range: searchRange, locale: nil)
    }
    
    public func rangeOfString(searchString: String, options mask: NSStringCompareOptions, range searchRange: NSRange, locale: NSLocale?) -> NSRange {
        if let _ = locale {
            NSUnimplemented()
        }
        if mask.contains(.RegularExpressionSearch) {
            NSUnimplemented()
        }
        if searchString.length == 0 || searchRange.length == 0 {
            return NSMakeRange(NSNotFound, 0)
        }
        
#if os(Linux)
        var cfflags = CFStringCompareFlags(mask.rawValue)
        if mask.contains(.LiteralSearch) {
            cfflags |= UInt(kCFCompareNonliteral)
        }
#else
        var cfflags = CFStringCompareFlags(rawValue: mask.rawValue)
        if mask.contains(.LiteralSearch) {
            cfflags.unionInPlace(.CompareNonliteral)
        }
#endif
        var result = CFRangeMake(kCFNotFound, 0)
        if CFStringFindWithOptionsAndLocale(_cfObject, searchString._cfObject, CFRangeMake(searchRange.location, searchRange.length), cfflags, nil, &result) {
            return NSMakeRange(result.location, result.length)
        } else {
            return NSMakeRange(NSNotFound, 0)
        }
    }
    
    public func rangeOfCharacterFromSet(searchSet: NSCharacterSet) -> NSRange {
        NSUnimplemented()
    }
    
    public func rangeOfCharacterFromSet(searchSet: NSCharacterSet, options mask: NSStringCompareOptions) -> NSRange {
        NSUnimplemented()
    }
    
    public func rangeOfCharacterFromSet(searchSet: NSCharacterSet, options mask: NSStringCompareOptions, range searchRange: NSRange) -> NSRange {
        NSUnimplemented()
    }
    
    public func rangeOfComposedCharacterSequenceAtIndex(index: Int) -> NSRange {
        NSUnimplemented()
    }
    
    public func rangeOfComposedCharacterSequencesForRange(range: NSRange) -> NSRange {
        NSUnimplemented()
    }
    
    public func stringByAppendingString(aString: String) -> String {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            return _storage + aString
        } else {
            NSUnimplemented()
        }
    }
    
    public var doubleValue: Double {
        get {
            NSUnimplemented()
        }
    }
    
    public var floatValue: Float {
        get {
            NSUnimplemented()
        }
    }
    
    public var intValue: Int32 {
        get {
            NSUnimplemented()
        }
    }
    
    public var integerValue: Int {
        get {
            NSUnimplemented()
        }
    }
    
    public var longLongValue: Int64 {
        get {
            NSUnimplemented()
        }
    }
    
    public var boolValue: Bool {
        get {
            NSUnimplemented()
        }
    }
    
    public var uppercaseString: String {
        get {
            NSUnimplemented()
        }
    }
    
    public var lowercaseString: String {
        get {
            NSUnimplemented()
        }
    }
    
    public var capitalizedString: String {
        get {
            NSUnimplemented()
        }
    }
    
    public var localizedUppercaseString: String {
        get {
            NSUnimplemented()
        }
    }
    
    public var localizedLowercaseString: String {
        get {
            NSUnimplemented()
        }
    }
    
    public var localizedCapitalizedString: String {
        get {
            NSUnimplemented()
        }
    }
    
    public func uppercaseStringWithLocale(locale: NSLocale?) -> String {
        NSUnimplemented()
    }
    
    public func lowercaseStringWithLocale(locale: NSLocale?) -> String {
        NSUnimplemented()
    }
    
    public func capitalizedStringWithLocale(locale: NSLocale?) -> String {
        NSUnimplemented()
    }
    
    public func getLineStart(startPtr: UnsafeMutablePointer<Int>, end lineEndPtr: UnsafeMutablePointer<Int>, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>, forRange range: NSRange) {
        NSUnimplemented()
    }
    
    public func lineRangeForRange(range: NSRange) -> NSRange {
        NSUnimplemented()
    }
    
    public func getParagraphStart(startPtr: UnsafeMutablePointer<Int>, end parEndPtr: UnsafeMutablePointer<Int>, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>, forRange range: NSRange) {
        NSUnimplemented()
    }
    
    public func paragraphRangeForRange(range: NSRange) -> NSRange {
        NSUnimplemented()
    }
    
    public func enumerateSubstringsInRange(range: NSRange, options opts: NSStringEnumerationOptions, usingBlock block: (String?, NSRange, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        NSUnimplemented()
    }
    
    public func enumerateLinesUsingBlock(block: (String, UnsafeMutablePointer<ObjCBool>) -> Void) {
        NSUnimplemented()
    }
    
    public var UTF8String: UnsafePointer<Int8> {
        get {
            NSUnimplemented()
        }
    }
    
    public var fastestEncoding: UInt {
        get {
            NSUnimplemented()
        }
    }
    
    public var smallestEncoding: UInt {
        get {
            NSUnimplemented()
        }
    }
    
    public func dataUsingEncoding(encoding: UInt, allowLossyConversion lossy: Bool) -> NSData? {
        NSUnimplemented()
    }
    
    public func dataUsingEncoding(encoding: UInt) -> NSData? {
        NSUnimplemented()
    }
    
    public func canBeConvertedToEncoding(encoding: UInt) -> Bool {
        NSUnimplemented()
    }
    
    public func cStringUsingEncoding(encoding: UInt) -> UnsafePointer<Int8> {
        NSUnimplemented()
    }
    
    public func getCString(buffer: UnsafeMutablePointer<Int8>, maxLength maxBufferCount: Int, encoding: UInt) -> Bool {
        if self.dynamicType == NSString.self || self.dynamicType == NSMutableString.self {
            if _storage._core.isASCII {
                let len = min(self.length, maxBufferCount)
                buffer.moveAssignFrom(unsafeBitCast(_storage._core.startASCII, UnsafeMutablePointer<Int8>.self)
                    , count: len)
                return true
            }
        }
        return false
    }
    
    public func getBytes(buffer: UnsafeMutablePointer<Void>, maxLength maxBufferCount: Int, usedLength usedBufferCount: UnsafeMutablePointer<Int>, encoding: UInt, options: NSStringEncodingConversionOptions, range: NSRange, remainingRange leftover: NSRangePointer) -> Bool {
        NSUnimplemented()
    }
    
    public func maximumLengthOfBytesUsingEncoding(enc: UInt) -> Int {
        NSUnimplemented()
    }
    
    public func lengthOfBytesUsingEncoding(enc: UInt) -> Int {
        NSUnimplemented()
    }
    
    public class func availableStringEncodings() -> UnsafePointer<UInt> {
        NSUnimplemented()
    }
    
    public class func localizedNameOfStringEncoding(encoding: UInt) -> String {
        NSUnimplemented()
    }
    
    public class func defaultCStringEncoding() -> UInt {
        NSUnimplemented()
    }
    
    public var decomposedStringWithCanonicalMapping: String {
        get {
            NSUnimplemented()
        }
    }
    
    public var precomposedStringWithCanonicalMapping: String {
        get {
            NSUnimplemented()
        }
    }
    
    public var decomposedStringWithCompatibilityMapping: String {
        get {
            NSUnimplemented()
        }
    }
    
    public var precomposedStringWithCompatibilityMapping: String {
        get {
            NSUnimplemented()
        }
    }
    
    public func componentsSeparatedByString(separator: String) -> [String] {
        NSUnimplemented()
    }
    
    public func componentsSeparatedByCharactersInSet(separator: NSCharacterSet) -> [String] {
        NSUnimplemented()
    }
    
    public func stringByTrimmingCharactersInSet(set: NSCharacterSet) -> String {
        NSUnimplemented()
    }
    
    public func stringByPaddingToLength(newLength: Int, withString padString: String, startingAtIndex padIndex: Int) -> String {
        NSUnimplemented()
    }
    
    public func stringByFoldingWithOptions(options: NSStringCompareOptions, locale: NSLocale?) -> String {
        NSUnimplemented()
    }
    
    public func stringByReplacingOccurrencesOfString(target: String, withString replacement: String, options: NSStringCompareOptions, range searchRange: NSRange) -> String {
        NSUnimplemented()
    }
    
    public func stringByReplacingOccurrencesOfString(target: String, withString replacement: String) -> String {
        NSUnimplemented()
    }
    
    public func stringByReplacingCharactersInRange(range: NSRange, withString replacement: String) -> String {
        NSUnimplemented()
    }
    
    public func stringByApplyingTransform(transform: String, reverse: Bool) -> String? {
        NSUnimplemented()
    }
    
    public func writeToURL(url: NSURL, atomically useAuxiliaryFile: Bool, encoding enc: UInt) throws {
        NSUnimplemented()
    }
    
    public func writeToFile(path: String, atomically useAuxiliaryFile: Bool, encoding enc: UInt) throws {
        NSUnimplemented()
    }
    
    public convenience init(charactersNoCopy characters: UnsafeMutablePointer<unichar>, length: Int, freeWhenDone freeBuffer: Bool) /* "NoCopy" is a hint */ {
        NSUnimplemented()
    }
    
    public convenience init?(UTF8String nullTerminatedCString: UnsafePointer<Int8>) {
        NSUnimplemented()    
    }
    
    public convenience init(string aString: String) {
        NSUnimplemented()    
    }
    
    public convenience init(format: String, arguments argList: CVaListPointer) {
        NSUnimplemented()    
    }
    
    public convenience init(format: String, locale: AnyObject?, arguments argList: CVaListPointer) {
        NSUnimplemented()    
    }
    
    public convenience init?(data: NSData, encoding: UInt) {
        self.init(bytes: data.bytes, length: data.length, encoding: encoding)
    }
    
    public convenience init?(bytes: UnsafePointer<Void>, length len: Int, encoding: UInt) {
        guard let cf = CFStringCreateWithBytes(kCFAllocatorDefault, UnsafePointer<UInt8>(bytes), len, CFStringConvertNSStringEncodingToEncoding(encoding), true) else {
            return nil
        }
        self.init(cf._swiftObject)
    }
    
    public convenience init?(bytesNoCopy bytes: UnsafeMutablePointer<Void>, length len: Int, encoding: UInt, freeWhenDone freeBuffer: Bool) /* "NoCopy" is a hint */ {
        NSUnimplemented()    
    }
    
    public convenience init?(CString nullTerminatedCString: UnsafePointer<Int8>, encoding: UInt) {
        guard let cf = CFStringCreateWithCString(kCFAllocatorDefault, nullTerminatedCString, CFStringConvertNSStringEncodingToEncoding(encoding)) else {
            return nil
        }
        self.init(cf._swiftObject)
    }
    
    public convenience init(contentsOfURL url: NSURL, encoding enc: UInt) throws {
        NSUnimplemented()    
    }
    
    public convenience init(contentsOfFile path: String, encoding enc: UInt) throws {
        NSUnimplemented()    
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
        NSUnimplemented()
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
        self.replaceCharactersInRange(NSMakeRange(loc, 0), withString: aString)
    }
    
    public func deleteCharactersInRange(range: NSRange) {
        self.replaceCharactersInRange(range, withString: "")
    }
    
    public func appendString(aString: String) {
        self.replaceCharactersInRange(NSMakeRange(self.length, 0), withString: aString)
    }
    
    public func setString(aString: String) {
        self.replaceCharactersInRange(NSMakeRange(0, self.length), withString: aString)
    }
    
    public func replaceOccurrencesOfString(target: String, withString replacement: String, options: NSStringCompareOptions, range searchRange: NSRange) -> Int {
        NSUnimplemented()
    }
    
    public func applyTransform(transform: String, reverse: Bool, range: NSRange, updatedRange resultingRange: NSRangePointer) -> Bool {
        NSUnimplemented()
    }
}


extension String {
    /// Returns an Array of the encodings string objects support
    /// in the application’s environment.
    private static func _getAvailableStringEncodings() -> [NSStringEncoding] {
        let encodings = CFStringGetListOfAvailableEncodings()
        var numEncodings = 0
        var encodingArray = Array<NSStringEncoding>()
        while encodings.advancedBy(numEncodings).memory != CoreFoundation.kCFStringEncodingInvalidId {
            encodingArray.append(CFStringConvertEncodingToNSStringEncoding(encodings.advancedBy(numEncodings).memory))
            numEncodings++
        }
        return encodingArray
    }
    
    
    private static var _availableStringEncodings = String._getAvailableStringEncodings()
    @warn_unused_result
    public static func availableStringEncodings() -> [NSStringEncoding] {
        return _availableStringEncodings
    }
    
    @warn_unused_result
    public static func defaultCStringEncoding() -> NSStringEncoding {
        return NSUTF8StringEncoding
    }
    
    @warn_unused_result
    public static func localizedNameOfStringEncoding(encoding: NSStringEncoding) -> String {
        return CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding))._swiftObject
    }
    
    // this is only valid for the usage for CF since it expects the length to be in unicode characters instead of grapheme clusters "✌🏾".utf16.count = 3 and CFStringGetLength(CFSTR("✌🏾")) = 3 not 1 as it would be represented with grapheme clusters
    internal var length: Int {
        return utf16.count
    }
    
    public func canBeConvertedToEncoding(encoding: NSStringEncoding) -> Bool {
        if encoding == NSUnicodeStringEncoding || encoding == NSNonLossyASCIIStringEncoding || encoding == NSUTF8StringEncoding {
            return true
        }
        
        return false
    }
    
    public var capitalizedString: String {
        get {
            return capitalizedStringWithLocale(nil)
        }
    }
    
    public var localizedCapitalizedString: String {
        get {
            return capitalizedStringWithLocale(NSLocale.currentLocale())
        }
    }
    
    @warn_unused_result
    public func capitalizedStringWithLocale(locale: NSLocale?) -> String {
        NSUnimplemented()
    }
    
    public func caseInsensitiveCompare(aString: String) -> NSComparisonResult {
        return compare(aString, options: .CaseInsensitiveSearch, range: NSMakeRange(0, self.length), locale: NSLocale.currentLocale())
    }
    
    public func compare(aString: String, options mask: NSStringCompareOptions = [], range: NSRange? = nil, locale: NSLocale? = nil) -> NSComparisonResult {
        NSUnimplemented()
    }
    
#if os(Linux)
    public func hasPrefix(prefix: String) -> Bool {
        let characters = utf16
        let prefixCharacters = prefix.utf16
        let start = characters.startIndex
        let prefixStart = prefixCharacters.startIndex
        if characters.count < prefixCharacters.count {
            return false
        }
        for var idx = 0; idx < prefixCharacters.count; idx++ {
            if characters[start.advancedBy(idx)] != prefixCharacters[prefixStart.advancedBy(idx)] {
                return false
            }
        }
        return true
    }

    public func hasSuffix(suffix: String) -> Bool {
        let characters = utf16
        let suffixCharacters = suffix.utf16
        let start = characters.startIndex
        let suffixStart = suffixCharacters.startIndex
        
        if characters.count < suffixCharacters.count {
            return false
        }
        for var idx = 0; idx < suffixCharacters.count; idx++ {
            let charactersIdx = start.advancedBy(characters.count - idx - 1)
            let suffixIdx = suffixStart.advancedBy(suffixCharacters.count - idx - 1)
            if characters[charactersIdx] != suffixCharacters[suffixIdx] {
                return false
            }
        }
        return true
    }
#endif
    
}

extension NSString : _CFBridgable, _SwiftBridgable {
    typealias SwiftType = String
    internal var _cfObject: CFStringRef { return unsafeBitCast(self, CFStringRef.self) }
    internal var _swiftObject: String {
        var str: String?
        String._forceBridgeFromObjectiveC(self, result: &str)
        return str!
    }
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
    internal var _nsObject: NSType { return _bridgeToObjectiveC() }
    internal var _cfObject: CFType { return _nsObject._cfObject }
}

extension String : Bridgeable {
    public func bridge() -> NSString { return _nsObject }
}

extension NSString : Bridgeable {
    public func bridge() -> String { return _swiftObject }
}
