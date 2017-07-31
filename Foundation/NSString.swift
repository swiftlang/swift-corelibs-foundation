// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

import CoreFoundation

/*    NSString.h
 Copyright (c) 1994-2017, Apple Inc. All rights reserved.
 */

/*
 An NSString object encodes a Unicode-compliant text string, represented as a sequence of UTF–16 code units. All lengths, character indexes, and ranges are expressed in terms of UTF–16 code units, with index values starting at 0.  The length property of an NSString returns the number of UTF-16 code units in an NSString, and the characterAtIndex: method retrieves a specific UTF-16 code unit. These two "primitive" methods provide basic access to the contents of a string object.
 
 Most use of strings, however, is at a higher level, with the strings being treated as single entities: Using the APIs in NSString, you can compare strings against one another, search them for substrings, combine them into new strings, and so on. In cases where locale settings may make a difference, use the localized... API variants to perform the operations using the current user's locale, or use the locale: variants that take an explicit NSLocale argument.
 
 If you do need to access individual characters in a string, you need to consider whether you want to access the individual UTF-16 code points (referred to as "characters" in APIs, and represented with the "unichar" type), or human-readable characters (referred to as "composed character sequences" or "grapheme clusters").  Composed character sequences can span multiple UTF-16 characters, when representing a base letter plus an accent, for example, or Emoji.
 
 To access composed character sequences, use APIs such as rangeOfComposedCharacterSequenceAtIndex:, or enumerate the whole or part of the string with enumerateSubstringsInRange:options:usingBlock:, supplying NSStringEnumerationByComposedCharacterSequences as the enumeration option.
 
 For instance, to extract the composed character sequence at a given index (where index is a valid location in the string, 0..length-1):
 
 NSString *substr = [string substringWithRange:[string rangeOfComposedCharacterSequenceAtIndex:index]];
 
 And to enumerate composed character sequences in a string:
 
 [string enumerateSubstringsInRange:NSMakeRange(0, string.length)                      // enumerate the whole range of the string
 options:NSStringEnumerationByComposedCharacterSequences    // by composed character sequences
 usingBlock:^(NSString * substr, NSRange substrRange, NSRange enclosingRange, BOOL *stop) {
 ... use substr, whose range in string is substrRange ...
 }];
 
 NSStrings can be immutable or mutable. The contents of an immutable string is defined when it is created and subsequently cannot be changed.  To construct and manage a string that can be changed after it has been created, use NSMutableString, which is a subclass of NSString.
 
 An NSString object can be initialized using a number of ways: From a traditional (char *) C-string, a sequence of bytes, an NSData object, the contents of an NSURL, etc, with the character contents specified in a variety of string encodings, such as ASCII, ISOLatin1, UTF–8, UTF–16, etc.
 */

/* The unichar type represents a single UTF-16 code unit in an NSString. Although many human-readable characters are representable with a single unichar, some  such as Emoji may span multiple unichars. See discussion above.
 */

public typealias unichar = UInt16

extension NSString {
    public struct CompareOptions : OptionSet {
        public private(set) var rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
  
        public static let caseInsensitive = CompareOptions(rawValue: 1)
        public static let literal = CompareOptions(rawValue: 2)
        public static let backwards = CompareOptions(rawValue: 4)
        public static let anchored = CompareOptions(rawValue: 8)
        public static let numeric = CompareOptions(rawValue: 64)
        public static let diacriticInsensitive = CompareOptions(rawValue: 128)
        public static let widthInsensitive = CompareOptions(rawValue: 256)
        public static var forcedOrdering = CompareOptions(rawValue: 512)
        public static let regularExpression = CompareOptions(rawValue: 1024)
    }
    
    
    /* Note that in addition to the values explicitly listed below, NSStringEncoding supports encodings provided by CFString.
     See CFStringEncodingExt.h for a list of these encodings.
     See CFString.h for functions which convert between NSStringEncoding and CFStringEncoding.
     */
    
    /* 0..127 only */
    
    /* kCFStringEncodingDOSJapanese */
    
    /* Cyrillic; same as AdobeStandardCyrillic */
    /* WinLatin1 */
    /* Greek */
    /* Turkish */
    /* WinLatin2 */
    /* ISO 2022 Japanese encoding for e-mail */
    
    /* An alias for NSUnicodeStringEncoding */
    
    /* NSUTF16StringEncoding encoding with explicit endianness specified */
    /* NSUTF16StringEncoding encoding with explicit endianness specified */
    
    /* NSUTF32StringEncoding encoding with explicit endianness specified */
    /* NSUTF32StringEncoding encoding with explicit endianness specified */
    
    public struct EncodingConversionOptions : OptionSet {
        public private(set) var rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let allowLossy = EncodingConversionOptions(rawValue: 1)
        public static let externalRepresentation = EncodingConversionOptions(rawValue: 2)
        
        internal static let failOnPartialEncodingConversion = EncodingConversionOptions(rawValue: 4)
    }
    
    
    /* NSString primitives. A minimal subclass of NSString just needs to implement these two, along with an init method appropriate for that subclass. We also recommend overriding getCharacters:range: for performance.
     */
    
    /* The initializers available to subclasses. See further below for additional init methods.
     */
    
    /* To avoid breaking up character sequences such as Emoji, you can do:
     [str substringFromIndex:[str rangeOfComposedCharacterSequenceAtIndex:index].location]
     [str substringToIndex:NSMaxRange([str rangeOfComposedCharacterSequenceAtIndex:index])]
     [str substringWithRange:[str rangeOfComposedCharacterSequencesForRange:range]
     */
    
    // Use with rangeOfComposedCharacterSequencesForRange: to avoid breaking up character sequences
    
    // Use with rangeOfComposedCharacterSequencesForRange: to avoid breaking up character sequences
    
    /* In the compare: methods, the range argument specifies the subrange, rather than the whole, of the receiver to use in the comparison. The range is not applied to the search string.  For example, [@"AB" compare:@"ABC" options:0 range:NSMakeRange(0,1)] compares "A" to "ABC", not "A" to "A", and will return NSOrderedAscending. It is an error to specify a range that is outside of the receiver's bounds, and an exception may be raised.
     */
    
    // locale arg used to be a dictionary pre-Leopard. We now accept NSLocale. Assumes the current locale if non-nil and non-NSLocale. nil continues to mean canonical compare, which doesn't depend on user's locale choice.
    
    /* localizedStandardCompare:, added in 10.6, should be used whenever file names or other strings are presented in lists and tables where Finder-like sorting is appropriate.  The exact behavior of this method may be tweaked in future releases, and will be different under different localizations, so clients should not depend on the exact sorting order of the strings.
     */
    
    /* These perform locale unaware prefix or suffix match. If you need locale awareness, use rangeOfString:options:range:locale:, passing NSAnchoredSearch (or'ed with NSBackwardsSearch for suffix, and NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch if needed) for options, NSMakeRange(0, [receiver length]) for range, and [NSLocale currentLocale] for locale.
     */
    
    /* Simple convenience methods for string searching. containsString: returns YES if the target string is contained within the receiver. Same as calling rangeOfString:options: with no options, thus doing a case-sensitive, locale-unaware search. localizedCaseInsensitiveContainsString: is the case-insensitive variant which also takes the current locale into effect. Starting in 10.11 and iOS9, the new localizedStandardRangeOfString: or localizedStandardContainsString: APIs are even better convenience methods for user level searching.   More sophisticated needs can be achieved by calling rangeOfString:options:range:locale: directly.
     */
    
    /* The following two are the most appropriate methods for doing user-level string searches, similar to how searches are done generally in the system.  The search is locale-aware, case and diacritic insensitive. As with other APIs, "standard" in the name implies "system default behavior," so the exact list of search options applied may change over time.  If you need more control over the search options, please use the rangeOfString:options:range:locale: method. You can pass [NSLocale currentLocale] for searches in user's locale.
     */
    
    /* These methods perform string search, looking for the searchString within the receiver string.  These return length==0 if the target string is not found. So, to check for containment: ([str rangeOfString:@"target"].length > 0).  Note that the length of the range returned by these methods might be different than the length of the target string, due composed characters and such.
     
     Note that the first three methods do not take locale arguments, and perform the search in a non-locale aware fashion, which is not appropriate for user-level searching. To do user-level string searching, use the last method, specifying locale:[NSLocale currentLocale], or better yet, use localizedStandardRangeOfString: or localizedStandardContainsString:.
     
     The range argument specifies the subrange, rather than the whole, of the receiver to use in the search.  It is an error to specify a range that is outside of the receiver's bounds, and an exception may be raised.
     */
    
    /* These return the range of the first character from the set in the string, not the range of a sequence of characters.
     
     The range argument specifies the subrange, rather than the whole, of the receiver to use in the search.  It is an error to specify a range that is outside of the receiver's bounds, and an exception may be raised.
     */
    
    /* The following convenience methods all skip initial space characters (whitespaceSet) and ignore trailing characters. They are not locale-aware. NSScanner or NSNumberFormatter can be used for more powerful and locale-aware parsing of numbers.
     */
    
    // Skips initial space characters (whitespaceSet), or optional -/+ sign followed by zeroes. Returns YES on encountering one of "Y", "y", "T", "t", or a digit 1-9. It ignores any trailing characters.
    
    /* The following three return the canonical (non-localized) mappings. They are suitable for programming operations that require stable results not depending on the user's locale preference.  For locale-aware case mapping for strings presented to users, use the "localized" methods below.
     */
    
    /* The following three return the locale-aware case mappings. They are suitable for strings presented to the user.
     */
    
    /* The following methods perform localized case mappings based on the locale specified. Passing nil indicates the canonical mapping.  For the user preference locale setting, specify +[NSLocale currentLocale].
     */
    
    public struct EnumerationOptions : OptionSet {
        public private(set) var rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        // Pass in one of the "By" options:
        public static let byLines = EnumerationOptions(rawValue: 0) // Equivalent to lineRangeForRange:
        
        public static let byParagraphs = EnumerationOptions(rawValue: 1) // Equivalent to paragraphRangeForRange:
        
        public static let byComposedCharacterSequences = EnumerationOptions(rawValue: 2) // Equivalent to rangeOfComposedCharacterSequencesForRange:
        
        public static let byWords = EnumerationOptions(rawValue: 3)
        
        public static let bySentences = EnumerationOptions(rawValue: 4)
        
        // ...and combine any of the desired additional options:
        public static let reverse = EnumerationOptions(rawValue: 1 << 8)
        
        public static let substringNotRequired = EnumerationOptions(rawValue: 1 << 9)
        
        public static let localized = EnumerationOptions(rawValue: 1 << 10) // User's default locale
    }
}

open class NSString : NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool = true
    
    open var length: Int {
        get {
            guard type(of: self) == NSString.self else {
                NSRequiresConcreteImplementation()
            }
            return 0
        }
    }
    
    open func character(at index: Int) -> unichar {
        guard type(of: self) == NSString.self else {
            NSRequiresConcreteImplementation()
        }
        fatalError("index \(index) beyond length 0")
    }
    
    public override init() {
        super.init()
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            let archiveVersion = aDecoder.version(forClassName: "NSString")
            if archiveVersion == 1 {
                let str = aDecoder._withDecodedBytes { (buffer) -> String? in
                    return String(bytes: buffer, encoding: .utf8)
                }
                guard let s = str else {
                    return nil
                }
                
                self.init(string: s)
                return
            } else {
                fatalError("NSString cannot decode class version \(archiveVersion)")
            }
        }
        if type(of: aDecoder) == NSKeyedUnarchiver.self {
            guard let plistValue = aDecoder._decodePropertyListForKey("NS.string") else {
                return nil
            }
            guard let str = plistValue as? String else {
                return nil
            }
            self.init(string: str)
            return
        } else {
            let data = aDecoder._withDecodedBytes(forKey: "NS.bytes") { (buffer) -> Data in
                return Data(UnsafeBufferPointer<UInt8>.init(start: buffer.baseAddress?.assumingMemoryBound(to: UInt8.self), count: buffer.count))
            }
            self.init(data: data, encoding: String.Encoding.utf8.rawValue)
            return
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        if !aCoder.allowsKeyedCoding {
            let bufferSize = 6 * length
            var buffer = [unichar](repeating: 0, count: bufferSize)
            buffer.withUnsafeMutableBytes { (bufferPtr) -> Void in
                var used = 0
                if !getBytes(bufferPtr.baseAddress, maxLength: bufferSize, usedLength: &used, encoding: String.Encoding.utf8.rawValue, range: NSMakeRange(0, length), remaining: nil) {
                    fatalError("couldnt encode string \(self)")
                }
                aCoder.encodeBytes(bufferPtr.baseAddress, length: used)
            }
            return
        }
        if let aKeyedCoder = aCoder as? NSKeyedArchiver {
            aKeyedCoder._encodePropertyList(self, forKey: "NS.string")
        } else {
            let bufferSize = 6 * length
            var buffer = [unichar](repeating: 0, count: bufferSize)
            buffer.withUnsafeMutableBytes { (bufferPtr) -> Void in
                var used = 0
                if !getBytes(bufferPtr.baseAddress, maxLength: bufferSize, usedLength: &used, encoding: String.Encoding.utf8.rawValue, range: NSMakeRange(0, length), remaining: nil) {
                    fatalError("couldnt encode string \(self)")
                }
                aCoder.encodeBytes(bufferPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), length: used, forKey: "NS.bytes")
            }
        }
    }
    
    public func copy(with zone: NSZone?) -> Any {
        return NSString(string: self)
    }
    
    public func mutableCopy(with zone: NSZone?) -> Any {
        return NSMutableString(string: self)
    }
    
    internal func _fastCStringContents(_ nullTerminationRequired: Bool) -> UnsafePointer<Int8>? {
        return nil
    }
    
    internal func _fastCharacterContents() -> UnsafePointer<unichar>? {
        return nil
    }
    
    internal func _encodingCantBeStoredInEightBitCFString() -> Bool {
        let encoding = fastestEncoding
        return encoding != CFStringConvertEncodingToNSStringEncoding(__CFStringGetEightBitStringEncoding())
    }
    
    /// Create an instance initialized to `value`.
    public required convenience init(stringLiteral value: StaticString) {
        var immutableResult: NSString
        if value.hasPointerRepresentation {
            immutableResult = NSString(bytesNoCopy: UnsafeMutableRawPointer(mutating: value.utf8Start), length: Int(value.utf8CodeUnitCount), encoding: value.isASCII ? String.Encoding.ascii.rawValue : String.Encoding.utf8.rawValue, freeWhenDone: false)!
        } else {
            var uintValue = value.unicodeScalar
            immutableResult = NSString(bytes: &uintValue, length: 4, encoding: String.Encoding.utf32.rawValue)!
        }
        self.init(factory: immutableResult)
    }
    
    internal convenience init(cString: UnsafePointer<Int8>, length: Int) {
        self.init(bytes: cString, length: length, encoding: _NSGetDefaultStringEncoding())!
    }
    
    override open var description: String {
        get {
            return String(self)
        }
    }
    
    
    override open var hash: Int {
        get {
            return Int(bitPattern: CFStringHashNSString(_unsafeReferenceCast(self, to: CFString.self)))
        }
    }
    
    open func getCharacters(_ buffer: UnsafeMutablePointer<unichar>, range: NSRange) {
        for idx in 0..<range.length {
            buffer[idx] = character(at: idx + range.location)
        }
    }
    
    
    /* In general creation methods in NSString do not apply to subclassers, as subclassers are assumed to provide their own init methods which create the string in the way the subclass wishes.  Designated initializers of NSString are thus init and initWithCoder:.
     */
    public convenience init(charactersNoCopy characters: UnsafeMutablePointer<unichar>, length: Int, freeWhenDone freeBuffer: Bool) { /* "NoCopy" is a hint */
        if type(of: self) == NSString.self {
            let cf = CFStringCreateWithCharactersNoCopy(kCFAllocatorDefault, characters, length, freeBuffer ? kCFAllocatorMalloc : kCFAllocatorNull)
            self.init(factory: _unsafeReferenceCast(cf, to: NSString.self))
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience init(characters: UnsafePointer<unichar>, length: Int) {
        if type(of: self) == NSString.self {
            let cf = CFStringCreateWithCharacters(kCFAllocatorDefault, characters, length)
            self.init(factory: _unsafeReferenceCast(cf, to: NSString.self))
        } else {
            let buffer = UnsafeMutablePointer<unichar>.allocate(capacity: length)
            buffer.initialize(from: characters, count: length)
            self.init(charactersNoCopy: buffer, length: length, freeWhenDone: true)
        }
    }
    
    public convenience init?(utf8String nullTerminatedCString: UnsafePointer<Int8>) {
        if type(of: self) == NSString.self {
            let cf = CFStringCreateWithCString(kCFAllocatorDefault, nullTerminatedCString, CFStringEncoding(kCFStringEncodingUTF8))
            self.init(factory: _unsafeReferenceCast(cf, to: NSString.self))
        } else {
            self.init(bytes: nullTerminatedCString, length: Int(strlen(nullTerminatedCString)), encoding: String.Encoding.utf8.rawValue)
        }
    }
    
    public convenience init(string aString: String) {
        if type(of: self) == NSString.self {
            if aString.isEmpty {
                self.init(factory: _NSString0.empty)
            } else {
                self.init(factory: _NSSwiftString(_string: aString))
            }
        } else {
            let len = aString.utf16.count
            var buffer = [unichar](repeating: 0, count: len)
            aString.withCString(encodedAs: Unicode.UTF16.self) { (chars: UnsafePointer<unichar>) in
                buffer.withUnsafeMutableBufferPointer { bufferPtr in
                    bufferPtr.baseAddress?.assign(from: chars, count: len)
                }
            }
            self.init(characters: buffer, length: len)
        }
    }
    
    public convenience init(format: String, arguments argList: CVaListPointer) {
        self.init(format: format, locale: nil, arguments: argList)
    }
    
    public convenience init(format: String, locale: Any?, arguments argList: CVaListPointer) {
        if type(of: self) == NSString.self {
            let loc = _SwiftValue.store(locale)
            let cf = CFStringCreateWithFormatAndArguments(kCFAllocatorDefault, _unsafeReferenceCast(loc, to: Optional<CFDictionary>.self), _unsafeReferenceCast(NSString(string: format), to: CFString.self), argList)
            self.init(factory: _unsafeReferenceCast(cf, to: NSString.self))
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience init?(data: Data, encoding: UInt) {
        if type(of: self) == NSString.self {
            if data.isEmpty {
                self.init(string: "")
            } else {
                guard let cf = data.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) -> CFString? in
                    return CFStringCreateWithBytes(kCFAllocatorDefault, bytes, data.count, CFStringConvertNSStringEncodingToEncoding(encoding), true)
                }) else { return nil }
                self.init(factory: _unsafeReferenceCast(cf, to: NSString.self))
            }
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience init?(bytes: UnsafeRawPointer, length len: Int, encoding: UInt) {
        if type(of: self) == NSString.self {
            let cf = CFStringCreateWithBytes(kCFAllocatorDefault, bytes.assumingMemoryBound(to: UInt8.self), len, CFStringConvertNSStringEncodingToEncoding(encoding), true)
            self.init(factory: _unsafeReferenceCast(cf, to: NSString.self))
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience init?(bytesNoCopy bytes: UnsafeMutableRawPointer, length len: Int, encoding: UInt, freeWhenDone freeBuffer: Bool) { /* "NoCopy" is a hint */
        if type(of: self) == NSString.self {
            let cf = _CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, bytes.assumingMemoryBound(to: UInt8.self), len, CFStringConvertNSStringEncodingToEncoding(encoding), true, freeBuffer ? kCFAllocatorMalloc : kCFAllocatorNull).takeRetainedValue()
            self.init(factory: _unsafeReferenceCast(cf, to: NSString.self))
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    public convenience init?(cString nullTerminatedCString: UnsafePointer<Int8>, encoding: UInt) {
        if type(of: self) == NSString.self {
            let cf = CFStringCreateWithCString(kCFAllocatorDefault, nullTerminatedCString, CFStringConvertNSStringEncodingToEncoding(encoding))
            self.init(factory: _unsafeReferenceCast(cf, to: NSString.self))
        } else {
            NSRequiresConcreteImplementation()
        }
    }
    
    /* These use the specified encoding.  If nil is returned, the optional error return indicates problem that was encountered (for instance, file system or encoding errors).
     */
    public convenience init(contentsOf url: URL, encoding enc: UInt) throws {
        if url.isFileURL {
            let path = url.path
            try self.init(contentsOfFile: path, encoding: enc)
        } else {
            let readResult = try Data(contentsOf: url)
            guard let str = NSString(data: readResult, encoding: enc) else {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileReadInapplicableStringEncoding.rawValue, userInfo: [
                    "NSDebugDescription" : "Unable to create a string using the specified encoding."
                ])
            }
            if type(of: self) == NSString.self {
                self.init(factory: str)
            } else {
                self.init(string: str)
            }
        }
    }
    
    public convenience init(contentsOfFile path: String, encoding enc: UInt) throws {
        let readResult = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let str = NSString(data: readResult, encoding: enc) else {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileReadInapplicableStringEncoding.rawValue, userInfo: [
                "NSDebugDescription" : "Unable to create a string using the specified encoding."
                ])
        }
        if type(of: self) == NSString.self {
            self.init(factory: str)
        } else {
            self.init(string: str)
        }
    }
    
    /* These try to determine the encoding, and return the encoding which was used.  Note that these methods might get "smarter" in subsequent releases of the system, and use additional techniques for recognizing encodings. If nil is returned, the optional error return indicates problem that was encountered (for instance, file system or encoding errors).
     */
    public convenience init(contentsOf url: URL, usedEncoding enc: UnsafeMutablePointer<UInt>?) throws {
        if url.isFileURL {
            let path = url.path
            try self.init(contentsOfFile: path, usedEncoding: enc)
        } else {
            let readResult = try Data(contentsOf: url)
            let len = readResult.count
            var detectedEncoding: UInt = String.Encoding.utf8.rawValue
            var advance = 0

            let cf = readResult.withUnsafeBytes { (bytePtr: UnsafePointer<UInt8>) -> CFString in
                if len >= 4 && bytePtr[0] == 0xFF && bytePtr[1] == 0xFE && bytePtr[2] == 0x00 && bytePtr[3] == 0x00 {
                    detectedEncoding = String.Encoding.utf32LittleEndian.rawValue
                    advance = 4
                } else if len >= 2 && bytePtr[0] == 0xFE && bytePtr[1] == 0xFF {
                    detectedEncoding = String.Encoding.utf16BigEndian.rawValue
                    advance = 2
                } else if len >= 2 && bytePtr[0] == 0xFF && bytePtr[1] == 0xFE {
                    detectedEncoding = String.Encoding.utf16LittleEndian.rawValue
                    advance = 2
                } else if len >= 4 && bytePtr[0] == 0x00 && bytePtr[1] == 0x00 && bytePtr[2] == 0xFE && bytePtr[3] == 0xFF {
                    detectedEncoding = String.Encoding.utf32BigEndian.rawValue
                    advance = 4
                }
                return CFStringCreateWithBytes(kCFAllocatorDefault, bytePtr.advanced(by: advance), len - advance, CFStringConvertNSStringEncodingToEncoding(detectedEncoding), true)
            }
            enc?.pointee = detectedEncoding
            if type(of: self) == NSString.self {
                self.init(factory: _unsafeReferenceCast(cf, to: NSString.self))
            } else {
                self.init(string: _unsafeReferenceCast(cf, to: NSString.self))
            }
        }
    }
    
    public convenience init(contentsOfFile path: String, usedEncoding enc: UnsafeMutablePointer<UInt>?) throws {
        let readResult = try Data(contentsOf: URL(fileURLWithPath: path))
        let len = readResult.count
        var detectedEncoding: UInt = String.Encoding.utf8.rawValue
        var advance = 0
        let cf = readResult.withUnsafeBytes { (bytePtr: UnsafePointer<UInt8>) -> CFString in
            if len >= 2  && bytePtr[0] == 254 && bytePtr[1] == 255 {
                detectedEncoding = String.Encoding.utf16BigEndian.rawValue
                advance = 2
            } else if len >= 2 && bytePtr[0] == 255 && bytePtr[1] == 254 {
                detectedEncoding = String.Encoding.utf16LittleEndian.rawValue
                advance = 2
            }
            return CFStringCreateWithBytes(kCFAllocatorDefault, bytePtr.advanced(by: advance), len - advance, CFStringConvertNSStringEncodingToEncoding(detectedEncoding), true)
        }
        enc?.pointee = detectedEncoding
        if type(of: self) == NSString.self {
            self.init(factory: _unsafeReferenceCast(cf, to: NSString.self))
        } else {
            self.init(string: _unsafeReferenceCast(cf, to: NSString.self))
        }
    }
    
    // Normally these would be in extensions, however we want to allow overriding
    
    internal func _indexError(_ input: Int, _ max: Int, _ fn: String = #function) -> Void {
        fatalError("\(type(of: self)).\(fn): Index \(input) outf bounds; string length \(max)")
    }
    
    internal func _rangeError(_ input: NSRange, _ max: Int, _ fn: String = #function) -> Void {
        fatalError("\(type(of: self)).\(fn): Range \(input) outf bounds; string length \(max)")
    }
    
    open func substring(from: Int) -> String {
        let len = length
        if from > len { _indexError(from, len) }
        return substring(with: NSMakeRange(from, len - from))
    }
    
    open func substring(to: Int) -> String {
        let len = length
        if to > len { _indexError(to, len) }
        return substring(with: NSMakeRange(0, to))
    }
    
    internal func _newSubstring(with range: NSRange) -> String {
        let len = length
        // Simple cases
        if range.length == 0 { return "" }
        if range.location == 0 && range.length == len { return String(self) }
        
        // First check the 8-bit case. Note that this code isn't invoked for NSCFString, since there is an override of this method there
        if let bytes = _fastCStringContents(false) {
            return String(unsafeBitCast(CFStringCreateWithBytes(kCFAllocatorDefault, UnsafeRawPointer(bytes.advanced(by: range.location)).assumingMemoryBound(to: UInt8.self), range.length, __CFStringGetEightBitStringEncoding(), false), to: NSString.self))
        }
        let chars = UnsafeMutablePointer<unichar>.allocate(capacity: range.length)
        defer { chars.deallocate(capacity: range.length) }
        getCharacters(chars, range: range)
        return String(NSString(charactersNoCopy: chars, length: range.length, freeWhenDone: true))
    }
    
    open func substring(with range: NSRange) -> String {
        let len = length
        if (range.length > len) || (range.location > len - range.length) { _rangeError(range, len) }
        return _newSubstring(with: range)
    }
    
    open func compare(_ string: String) -> ComparisonResult {
        return compare(string, options: [], range: NSMakeRange(0, length))
    }
    
    open func compare(_ string: String, options mask: CompareOptions = []) -> ComparisonResult {
        return compare(string, options: mask, range: NSMakeRange(0, length))
    }
    
    open func compare(_ string: String, options mask: CompareOptions = [], range rangeOfReceiverToCompare: NSRange) -> ComparisonResult {
        return compare(string, options: mask, range: rangeOfReceiverToCompare, locale: nil) // Canonical compare
    }
    
    open func compare(_ string: String, options mask: CompareOptions = [], range rangeOfReceiverToCompare: NSRange, locale: Any?) -> ComparisonResult {
        let other = NSString(string: string)
        let localeObj = _SwiftValue.store(locale)
        
        let res = CFStringCompareWithOptionsAndLocale(unsafeBitCast(self, to: CFString.self), unsafeBitCast(other, to: CFString.self), CFRangeMake(rangeOfReceiverToCompare.location, rangeOfReceiverToCompare.length), CFStringCompareFlags(rawValue: mask.rawValue), unsafeBitCast(localeObj, to: CFLocale.self))
        return ComparisonResult._fromCF(res)
    }
    
    open func caseInsensitiveCompare(_ string: String) -> ComparisonResult {
        return compare(string, options: .caseInsensitive, range: NSMakeRange(0, length))
    }
    
    open func localizedCompare(_ string: String) -> ComparisonResult {
        return compare(string, options: [], range: NSMakeRange(0, length), locale: Locale.current)
    }
    
    open func localizedCaseInsensitiveCompare(_ string: String) -> ComparisonResult {
        return compare(string, options: .caseInsensitive, range: NSMakeRange(0, length), locale: Locale.current)
    }
    
    open func localizedStandardCompare(_ string: String) -> ComparisonResult {
        return compare(string, options: [.caseInsensitive, .numeric, .widthInsensitive, .forcedOrdering], range: NSMakeRange(0, length), locale: Locale.current)
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? String {
            return isEqual(to: other)
        } else if let other = object as? NSString {
            if other === self { return true }
            return isEqual(to: String(other))
        }
        return false
    }
    
    open func isEqual(to aString: String) -> Bool {
        return compare(aString, options: .literal, range: NSMakeRange(0, length)) == .orderedSame
    }
    
    open func hasPrefix(_ str: String) -> Bool {
        return range(of: str, options: .anchored, range: NSMakeRange(0, length)).location != NSNotFound
    }
    
    open func hasSuffix(_ str: String) -> Bool {
        return range(of: str, options: [.anchored, .backwards], range: NSMakeRange(0, length)).location != NSNotFound
    }
    
    open func commonPrefix(with str: String, options mask: NSString.CompareOptions = []) -> String {
        let other = NSString(string: str)
        var currentSubstring: CFMutableString?
        let isLiteral = mask.contains(.literal)
        var lastMatch = NSRange(location: 0, length: 0)
        
        // Parameters for character buffer where we gather characters from s1
        var numCharsBuffered = 0
        let selfLen = length
        let otherLen = other.length
        
        let selfChars: UnsafeMutablePointer<unichar>
        var freeBuffer = false
        
        // Parameters for the binary search
        var low = 0
        var high = selfLen
        var probe = 0
        
        if selfLen == 0 || otherLen == 0 { return "" }
        
        // Set up buffer paramaters (use direct contents or stack buffer, or allocate temp if needed)
        if let chars = _fastCharacterContents() {
            numCharsBuffered = selfLen
            selfChars = UnsafeMutablePointer<unichar>(mutating: chars)
        } else {
            selfChars = UnsafeMutablePointer<unichar>.allocate(capacity: selfLen)
            freeBuffer = true
        }
        
        probe = (low + high) / 2
        if (probe > otherLen) { probe = otherLen }    // A little heuristic to avoid some extra work
        
        // Now do the binary search. Note that the probe value determines the length of the substring to check.
        while true {
            let range = NSRange(location: 0, length: isLiteral ? probe + 1 : NSMaxRange(rangeOfComposedCharacterSequence(at: probe))) // Extend the end of the composed char sequence
            if range.length > numCharsBuffered { // Buffer more characters if needed
                getCharacters(selfChars.advanced(by: numCharsBuffered), range: NSMakeRange(numCharsBuffered, range.length - numCharsBuffered))
                numCharsBuffered = range.length
            }
            if currentSubstring == nil { // Create or reset the substring (this way we avoid having to create many substrings)
                currentSubstring = CFStringCreateMutableWithExternalCharactersNoCopy(kCFAllocatorDefault, selfChars, range.length, range.length, kCFAllocatorNull)
            } else {
                CFStringSetExternalCharactersNoCopy(currentSubstring!, selfChars, range.length, range.length)
            }
            
            if other.range(of: String(_unsafeReferenceCast(currentSubstring, to: NSString.self)), options: mask.union(.anchored), range: NSMakeRange(0, otherLen)).length > 0 { // Match
                lastMatch = range
                low = probe + 1
            } else {
                high = probe
            }
            if (low >= high) { break }
            probe = (low + high) / 2
        }
        
        if freeBuffer {
            selfChars.deallocate(capacity: selfLen)
        }
        return lastMatch.length >= 0 ? substring(with: lastMatch) : ""
    }
    
    open func contains(_ str: String) -> Bool {
        return range(of: str, options: [], range: NSMakeRange(0, length), locale: nil).location != NSNotFound
    }
    
    open func localizedCaseInsensitiveContains(_ str: String) -> Bool {
        return range(of: str, options: .caseInsensitive, range: NSMakeRange(0, length), locale: Locale.current).location != NSNotFound
    }
    
    open func localizedStandardContains(_ str: String) -> Bool {
        return range(of: str, options: [.caseInsensitive, .diacriticInsensitive], range: NSMakeRange(0, length), locale: Locale.current).location != NSNotFound
    }
    
    open func localizedStandardRange(of str: String) -> NSRange {
        return range(of: str, options: [.caseInsensitive, .diacriticInsensitive], range: NSMakeRange(0, length), locale: Locale.current)
    }
    
    open func range(of searchString: String) -> NSRange {
        return range(of: searchString, options: [], range: NSMakeRange(0, length), locale: nil)
    }
    
    open func range(of searchString: String, options mask: NSString.CompareOptions = []) -> NSRange {
        return range(of: searchString, options: mask, range: NSMakeRange(0, length), locale: nil)
    }
    
    open func range(of searchString: String, options mask: NSString.CompareOptions = [], range rangeOfReceiverToSearch: NSRange) -> NSRange {
        return range(of: searchString, options: mask, range: rangeOfReceiverToSearch, locale: nil)
    }
    
    internal func _range(ofRegularExpressionPattern pattern: String, options mask: NSString.CompareOptions, range searchRange: NSRange, locale: Locale?) -> NSRange {
        var matchedRange = NSMakeRange(NSNotFound, 0)
        let regexOptions: NSRegularExpression.Options = mask.contains(.caseInsensitive) ? .caseInsensitive : []
        let matchingOptions: NSMatchingOptions = mask.contains(.anchored) ? .anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            matchedRange = regex.rangeOfFirstMatch(in: String(self), options: matchingOptions, range: searchRange)
        }
        return matchedRange
    }
    
    open func range(of searchString: String, options mask: NSString.CompareOptions = [], range fRange: NSRange, locale: Locale?) -> NSRange {
        let findStr = NSString(string: searchString)
        var result = CFRange(location: 0, length: 0)
        let findStrLen = findStr.length
        let len = length
        
        if fRange.length > len || fRange.location > len - fRange.length {
            _rangeError(fRange, len)
        }
        
        if mask.contains(.regularExpression) {
            return _range(ofRegularExpressionPattern: searchString, options: mask, range:fRange, locale: locale)
        }
        
        if fRange.length == 0 || findStrLen == 0 {    // ??? This last item can't be here for correct Unicode compares
            return NSMakeRange(NSNotFound, 0);
        }
        
        var options = CFOptionFlags(mask.rawValue)
        
        if mask.contains(.literal) {
            options |= CFOptionFlags(kCFCompareNonliteral)
        }
        var loc: NSLocale? = nil
        if let l = locale {
            loc = l._bridgeToObjectiveC()
        }
        
        let cf = _unsafeReferenceCast(self, to: CFString.self)
        let cfFindStr = _unsafeReferenceCast(findStr, to: CFString.self)
        let cfLoc = _unsafeReferenceCast(loc, to: Optional<CFLocale>.self)
        if CFStringFindWithOptionsAndLocale(cf, cfFindStr, CFRangeMake(fRange.location, fRange.length), CFStringCompareFlags(rawValue: options), cfLoc, &result) {
            return NSMakeRange(result.location, result.length)
        } else {
            return NSMakeRange(NSNotFound, 0)
        }
    }
    
    open func rangeOfCharacter(from searchSet: CharacterSet) -> NSRange {
        return rangeOfCharacter(from: searchSet, options: [], range: NSMakeRange(0, length))
    }
    
    open func rangeOfCharacter(from searchSet: CharacterSet, options mask: NSString.CompareOptions = []) -> NSRange {
        return rangeOfCharacter(from: searchSet, options: mask, range: NSMakeRange(0, length))
    }
    
    open func rangeOfCharacter(from searchSet: CharacterSet, options mask: NSString.CompareOptions = [], range fRange: NSRange) -> NSRange {
        var range = CFRange(location: 0, length: 0)
        
        let len = length
        
        if fRange.length > len || fRange.location > len - fRange.length {
            _rangeError(fRange, len)
        }
        
        let set = searchSet._bridgeToObjectiveC()
        
        if CFStringFindCharacterFromSet(_unsafeReferenceCast(self, to: CFString.self), _unsafeReferenceCast(set, to: CFCharacterSet.self), CFRangeMake(fRange.location, fRange.length), CFStringCompareFlags(rawValue: mask.rawValue), &range) {
            return NSMakeRange(range.location, range.length)
        } else {
            return NSMakeRange(NSNotFound, 0)
        }
    }
    
    open func rangeOfComposedCharacterSequence(at index: Int) -> NSRange {
        if index >= length {
            fatalError("The index \(index) is invalid)")
        }
        let result = CFStringGetRangeOfCharacterClusterAtIndex(_unsafeReferenceCast(self, to: CFString.self), index, kCFStringComposedCharacterCluster)
        return NSMakeRange(result.location, result.length)
    }
    
    open func rangeOfComposedCharacterSequences(for range: NSRange) -> NSRange {
        let len = length
        let start: Int
        let end: Int
        if range.location == len {
            start = len
        } else {
            start = rangeOfComposedCharacterSequence(at: range.location).location
        }
        var endOfRange = NSMaxRange(range)
        if endOfRange == len {
            end = len
        } else {
            if range.length > 0 { endOfRange -= 1 }
            end = NSMaxRange(rangeOfComposedCharacterSequence(at: endOfRange))
        }
        
        return NSMakeRange(start, end-start)
    }
    
    open func appending(_ aString: String) -> String {
        if length == 0 {
            return aString
        } else if aString.isEmpty {
            return String(self)
        } else {
            return String(self) + aString
        }
    }
    
    open var doubleValue: Double {
        get {
            var start: Int = 0
            var result = 0.0
            let _ = _swiftObject.scan(CharacterSet.whitespaces, locale: nil, locationToScanFrom: &start) { (value: Double) -> Void in
                result = value
            }
            return result
        }
    }
    
    open var floatValue: Float {
        get {
            var start: Int = 0
            var result: Float = 0.0
            let _ = _swiftObject.scan(CharacterSet.whitespaces, locale: nil, locationToScanFrom: &start) { (value: Float) -> Void in
                result = value
            }
            return result
        }
    }
    
    open var intValue: Int32 {
        get {
            return Scanner(string: String(self)).scanInt32() ?? 0
        }
    }
    
    open var integerValue: Int {
        get {
            return Scanner(string: String(self)).scanInt() ?? 0
        }
        
    }
    
    open var longLongValue: Int64 {
        get {
            return Scanner(string: String(self)).scanInt64() ?? 0
        }
        
    }
    
    open var boolValue: Bool {
        get {
            let scanner = Scanner(string: _swiftObject)
            // skip initial whitespace if present
            let _ = scanner.scanCharactersFromSet(.whitespaces)
            // scan a single optional '+' or '-' character, followed by zeroes
            if scanner.scanString("+") == nil {
                let _ = scanner.scanString("-")
            }
            // scan any following zeroes
            let _ = scanner.scanCharactersFromSet(CharacterSet(charactersIn: "0"))
            return scanner.scanCharactersFromSet(CharacterSet(charactersIn: "tTyY123456789")) != nil
        }
    }
    
    open var uppercased: String {
        get {
            return uppercased(with: nil)
        }
    }
    
    open var lowercased: String {
        get {
            return lowercased(with: nil)
        }
    }
    
    open var capitalized: String {
        get {
            return capitalized(with: nil)
        }
    }
    
    open var localizedUppercase: String {
        get {
            return lowercased(with: Locale.current)
        }
    }
    
    open var localizedLowercase: String {
        get {
            return lowercased(with: Locale.current)
        }
    }
    
    open var localizedCapitalized: String {
        get {
            return capitalized(with: Locale.current)
        }
    }
    
    open func uppercased(with locale: Locale?) -> String {
        let string = CFStringCreateMutable(kCFAllocatorDefault, 0)
        CFStringReplaceAll(string, _unsafeReferenceCast(self, to: CFString.self))
        CFStringUppercase(string, _unsafeReferenceCast(locale?._bridgeToObjectiveC(), to: Optional<CFLocale>.self))
        return String(_unsafeReferenceCast(string, to: NSString.self))
    }
    
    open func lowercased(with locale: Locale?) -> String {
        let string = CFStringCreateMutable(kCFAllocatorDefault, 0)
        CFStringReplaceAll(string, _unsafeReferenceCast(self, to: CFString.self))
        CFStringLowercase(string, _unsafeReferenceCast(locale?._bridgeToObjectiveC(), to: Optional<CFLocale>.self))
        return String(_unsafeReferenceCast(string, to: NSString.self))
    }
    
    open func capitalized(with locale: Locale?) -> String {
        let string = CFStringCreateMutable(kCFAllocatorDefault, 0)
        CFStringReplaceAll(string, _unsafeReferenceCast(self, to: CFString.self))
        CFStringCapitalize(string, _unsafeReferenceCast(locale?._bridgeToObjectiveC(), to: Optional<CFLocale>.self))
        return String(_unsafeReferenceCast(string, to: NSString.self))
    }
    
    internal func _getBlockStart(_ startPtr: UnsafeMutablePointer<Int>?, end endPtr: UnsafeMutablePointer<Int>?, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>?, for range: NSRange, stopAtLineSeparators line: Bool) {
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
    
    open func getLineStart(_ startPtr: UnsafeMutablePointer<Int>?, end lineEndPtr: UnsafeMutablePointer<Int>?, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>?, for range: NSRange) {
        _getBlockStart(startPtr, end: lineEndPtr, contentsEnd: contentsEndPtr, for: range, stopAtLineSeparators: true)
    }
    
    open func lineRange(for range: NSRange) -> NSRange {
        var start = 0
        var lineEnd = 0
        getLineStart(&start, end: &lineEnd, contentsEnd: nil, for: range)
        return NSMakeRange(start, lineEnd - start)
    }
    
    open func getParagraphStart(_ startPtr: UnsafeMutablePointer<Int>?, end parEndPtr: UnsafeMutablePointer<Int>?, contentsEnd contentsEndPtr: UnsafeMutablePointer<Int>?, for range: NSRange) {
        _getBlockStart(startPtr, end: parEndPtr, contentsEnd: contentsEndPtr, for: range, stopAtLineSeparators: false)
    }
    
    open func paragraphRange(for range: NSRange) -> NSRange {
        var start = 0
        var parEnd = 0
        getParagraphStart(&start, end: &parEnd, contentsEnd: nil, for: range)
        return NSMakeRange(start, parEnd - start)
    }
    
    
    /* In the enumerate methods, the blocks will be invoked inside an autorelease pool, so any values assigned inside the block should be retained.
     */
    open func enumerateSubstrings(in range: NSRange, options opts: NSString.EnumerationOptions = [], using block: @escaping (String?, NSRange, NSRange, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        NSUnimplemented()
    }
    
    open func enumerateLines(_ block: @escaping (String, UnsafeMutablePointer<ObjCBool>) -> Swift.Void) {
        enumerateSubstrings(in: NSMakeRange(0, length), options: .byLines) { (substring, substringRange, enclosingRange, stop) in
            block(substring!, stop)
        }
    }
    
    // Convenience to return null-terminated UTF8 representation
    open var utf8String: UnsafePointer<Int8>? {
        get {
            return _bytesInEncoding(self, .utf8, false, false, false)
        }
    }
    
    // Result in O(1) time; a rough estimate
    open var fastestEncoding: UInt {
        get {
            return String.Encoding.unicode.rawValue
        }
    }
    
    // Result in O(n) time; the encoding in which the string is most compact
    open var smallestEncoding: UInt {
        get {
            if canBeConverted(to: String.Encoding.ascii.rawValue) { return String.Encoding.ascii.rawValue }
            if canBeConverted(to: _NSGetDefaultStringEncoding()) { return _NSGetDefaultStringEncoding() }
            return String.Encoding.unicode.rawValue
        }
    }
    
    // External representation
    open func data(using encoding: UInt, allowLossyConversion lossy: Bool) -> Data? {
        let len = length
        var reqSize = 0
        
        let cfStringEncoding = CFStringConvertNSStringEncodingToEncoding(encoding)
        if !CFStringIsEncodingAvailable(cfStringEncoding) {
            return nil
        }
        
        let convertedLen = __CFStringEncodeByteStream(_cfObject, 0, len, true, cfStringEncoding, lossy ? (encoding == String.Encoding.ascii.rawValue ? 0xFF : 0x3F) : 0, nil, 0, &reqSize)
        if convertedLen != len {
            return nil     // Not able to do it all...
        }
        
        if 0 < reqSize {
            var data = Data(count: reqSize)
            data.count = data.withUnsafeMutableBytes { (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int in
                if __CFStringEncodeByteStream(_cfObject, 0, len, true, cfStringEncoding, lossy ? (encoding == String.Encoding.ascii.rawValue ? 0xFF : 0x3F) : 0, UnsafeMutablePointer<UInt8>(mutableBytes), reqSize, &reqSize) == convertedLen {
                    return reqSize
                } else {
                    fatalError("didn't convert all characters")
                }
            }
            
            return data
        }
        return Data()
    }
    
    // External representation
    open func data(using encoding: UInt) -> Data? {
        return data(using: encoding, allowLossyConversion: false)
    }
    
    
    open func canBeConverted(to encoding: UInt) -> Bool {
        if encoding == String.Encoding.unicode.rawValue || encoding == String.Encoding.nonLossyASCII.rawValue || encoding == String.Encoding.utf8.rawValue {
            return true
        }
        return __CFStringEncodeByteStream(_cfObject, 0, length, false, CFStringConvertNSStringEncodingToEncoding(encoding), 0, nil, 0, nil) == length
    }
    
    
    /* Methods to convert NSString to a NULL-terminated cString using the specified encoding. Note, these are the "new" cString methods, and are not deprecated like the older cString methods which do not take encoding arguments.
     */
    
    // "Autoreleased"; NULL return if encoding conversion not possible; for performance reasons, lifetime of this should not be considered longer than the lifetime of the receiving string (if the receiver string is freed, this might go invalid then, before the end of the autorelease scope)
    open func cString(using encoding: UInt) -> UnsafePointer<Int8>? {
        return _bytesInEncoding(self, String.Encoding(rawValue: encoding), false, false, false)
    }
    
    // NO return if conversion not possible due to encoding errors or too small of a buffer. The buffer should include room for maxBufferCount bytes; this number should accomodate the expected size of the return value plus the NULL termination character, which this method adds. (So note that the maxLength passed to this method is one more than the one you would have passed to the deprecated getCString:maxLength:.)
    open func getCString(_ buffer: UnsafeMutablePointer<Int8>, maxLength max: Int, encoding: UInt) -> Bool {
        var used = 0
        if max < 2 {
            if max == 0 || length > 0{
                return false
            }
            buffer.pointee = 0
            return true
        } else if getBytes(buffer, maxLength: max - 1, usedLength: &used, encoding: encoding, options: .failOnPartialEncodingConversion, range: NSMakeRange(0, length), remaining: nil) {
            buffer.advanced(by: used).pointee = 0
            return true
        } else {
            return false
        }
    }
    
    
    /* Use this to convert string section at a time into a fixed-size buffer, without any allocations.  Does not NULL-terminate.
     buffer is the buffer to write to; if NULL, this method can be used to computed size of needed buffer.
     maxBufferCount is the length of the buffer in bytes. It's a good idea to make sure this is at least enough to hold one character's worth of conversion.
     usedBufferCount is the length of the buffer used up by the current conversion. Can be NULL.
     encoding is the encoding to convert to.
     options specifies the options to apply.
     range is the range to convert.
     leftOver is the remaining range. Can be NULL.
     YES return indicates some characters were converted. Conversion might usually stop when the buffer fills,
     but it might also stop when the conversion isn't possible due to the chosen encoding.
     */
    open func getBytes(_ buffer: UnsafeMutableRawPointer?, maxLength maxBufferCount: Int, usedLength usedBufferCount: UnsafeMutablePointer<Int>?, encoding: UInt, options: NSString.EncodingConversionOptions = [], range: NSRange, remaining leftover: NSRangePointer?) -> Bool {
        var totalBytesWritten = 0
        var numCharsProcessed = 0
        let cfStringEncoding = CFStringConvertNSStringEncodingToEncoding(encoding)
        var result = true
        if length > 0 {
            if CFStringIsEncodingAvailable(cfStringEncoding) {
                let lossyOk = options.contains(.allowLossy)
                let externalRep = options.contains(.externalRepresentation)
                let failOnPartial = options.contains(.failOnPartialEncodingConversion)
                let bytePtr = buffer?.bindMemory(to: UInt8.self, capacity: maxBufferCount)
                numCharsProcessed = __CFStringEncodeByteStream(_unsafeReferenceCast(self, to: CFString.self), range.location, range.length, externalRep, cfStringEncoding, lossyOk ? (encoding == String.Encoding.ascii.rawValue ? 0xFF : 0x3F) : 0, bytePtr, bytePtr != nil ? maxBufferCount : 0, &totalBytesWritten)
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
    
    
    /* These return the maximum and exact number of bytes needed to store the receiver in the specified encoding in non-external representation. The first one is O(1), while the second one is O(n). These do not include space for a terminating null.
     */
    // Result in O(1) time; the estimate may be way over what's needed. Returns 0 on error (overflow)
    open func maximumLengthOfBytes(using enc: UInt) -> Int {
        let cfEnc = CFStringConvertNSStringEncodingToEncoding(enc)
        let result = CFStringGetMaximumSizeForEncoding(length, cfEnc)
        return result == kCFNotFound ? 0 : result
    }
    
    // Result in O(n) time; the result is exact. Returns 0 on error (cannot convert to specified encoding, or overflow)
    open func lengthOfBytes(using enc: UInt) -> Int {
        let len = length
        var numBytes: CFIndex = 0
        let cfEnc = CFStringConvertNSStringEncodingToEncoding(enc)
        let convertedLen = __CFStringEncodeByteStream(_unsafeReferenceCast(self, to: CFString.self), 0, len, false, cfEnc, 0, nil, 0, &numBytes)
        return convertedLen != len ? 0 : numBytes
    }
    
    open class var availableStringEncodings: UnsafePointer<UInt> {
        get {
            struct once {
                static let encodings: UnsafePointer<UInt> = {
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
                        theEncodingList.advanced(by: numEncodings).pointee = CFStringConvertEncodingToNSStringEncoding(cfEncodings.advanced(by: numEncodings).pointee)
                        numEncodings -= 1
                    }
                    
                    return UnsafePointer<UInt>(theEncodingList)
                }()
            }
            return once.encodings
        }
    }
    
    
    open class func localizedName(of encoding: UInt) -> String {
        guard let name = _unsafeReferenceCast(CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding)), to: Optional<NSString>.self) else {
            return ""
        }
        //        return NSLocalizedStringFromTableInBundle(String(name), "EncodingNames", _NSFoundatioNBundle(), @"Encoding name")
        return String(name)
    }
    
    
    /* User-dependent encoding whose value is derived from user's default language and potentially other factors. The use of this encoding might sometimes be needed when interpreting user documents with unknown encodings, in the absence of other hints.  This encoding should be used rarely, if at all. Note that some potential values here might result in unexpected encoding conversions of even fairly straightforward NSString content --- for instance, punctuation characters with a bidirectional encoding.
     */
    // Should be rarely used
    open class var defaultCStringEncoding: UInt {
        get {
            return _NSGetDefaultStringEncoding()
        }
    }
    
    
    open var decomposedStringWithCanonicalMapping: String {
        get {
            let string = CFStringCreateMutable(kCFAllocatorDefault, 0)
            CFStringReplaceAll(string, _unsafeReferenceCast(self, to: CFString.self))
            CFStringNormalize(string, kCFStringNormalizationFormD)
            return String(_unsafeReferenceCast(string, to: NSString.self))
        }
    }
    
    open var precomposedStringWithCanonicalMapping: String {
        get {
            let string = CFStringCreateMutable(kCFAllocatorDefault, 0)
            CFStringReplaceAll(string, _unsafeReferenceCast(self, to: CFString.self))
            CFStringNormalize(string, kCFStringNormalizationFormC)
            return String(_unsafeReferenceCast(string, to: NSString.self))
        }
    }
    
    open var decomposedStringWithCompatibilityMapping: String {
        get {
            let string = CFStringCreateMutable(kCFAllocatorDefault, 0)
            CFStringReplaceAll(string, _unsafeReferenceCast(self, to: CFString.self))
            CFStringNormalize(string, kCFStringNormalizationFormKD)
            return String(_unsafeReferenceCast(string, to: NSString.self))
        }
    }
    
    open var precomposedStringWithCompatibilityMapping: String {
        get {
            let string = CFStringCreateMutable(kCFAllocatorDefault, 0)
            CFStringReplaceAll(string, _unsafeReferenceCast(self, to: CFString.self))
            CFStringNormalize(string, kCFStringNormalizationFormKC)
            return String(_unsafeReferenceCast(string, to: NSString.self))
        }
    }
    
    
    open func components(separatedBy separator: String) -> [String] {
        var r = range(of: separator, options: [], range: NSMakeRange(0, length))
        if r.length == 0 {
            return [String(self)]
        } else {
            let length = self.length
            var array = [String]()
            var srange = NSRange(location: 0, length: length)
            while true {
                let trange = NSRange(location: srange.location, length: r.location - srange.location)
                let newStr = substring(with: trange)
                array.append(newStr)
                srange.location = r.location + r.length
                srange.length = length - srange.location
                r = range(of: separator, options: [], range: srange)
                if r.length == 0 {
                    break
                }
            }
            let newStr = substring(with: srange)
            array.append(newStr)
            return array
        }
    }
    
    open func components(separatedBy separator: CharacterSet) -> [String] {
        var r = rangeOfCharacter(from: separator, options: [], range: NSMakeRange(0, length))
        if r.length == 0 {
            return [String(self)]
        } else {
            let length = self.length
            var array = [String]()
            var srange = NSRange(location: 0, length: length)
            while true {
                let trange = NSRange(location: srange.location, length: r.location - srange.location)
                let newStr = substring(with: trange)
                array.append(newStr)
                srange.location = r.location + r.length
                srange.length = length - srange.location
                r = rangeOfCharacter(from: separator, options: [], range: srange)
                if r.length == 0 {
                    break
                }
            }
            let newStr = substring(with: srange)
            array.append(newStr)
            return array
        }
    }
    
    
    open func trimmingCharacters(in set: CharacterSet) -> String {
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
            return substring(with: NSMakeRange(startOfNonTrimmedRange, endOfNonTrimmedRange + 1 - startOfNonTrimmedRange))
        } else {
            return substring(with: NSMakeRange(startOfNonTrimmedRange, 1))
        }
    }
    
    open func padding(toLength newLength: Int, withPad padString: String, startingAt padIndex: Int) -> String {
        let len = length
        if newLength <= len { // The simple cases (truncation)
            return newLength == len ? String(self) : substring(with: NSMakeRange(0, newLength))
        }
        
        let padStr = NSString(string: padString)
        let padLen = padStr.length
        
        precondition(padLen > 0, "empty pad string")
        precondition(padLen < padIndex, "out of range of pad index")
        
        let mStr = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, _unsafeReferenceCast(self, to: CFString.self))!
        CFStringPad(mStr, _unsafeReferenceCast(padStr, to: CFString.self), newLength, padIndex)
        return String(_unsafeReferenceCast(mStr, to: NSString.self))
    }
    
    
    /* Returns a string with the character folding options applied. theOptions is a mask of compare flags with *InsensitiveSearch suffix.
     */
    open func folding(options: NSString.CompareOptions = [], locale: Locale?) -> String {
        let string = CFStringCreateMutable(kCFAllocatorDefault, 0)
        CFStringReplaceAll(string, _unsafeReferenceCast(self, to: CFString.self))
        CFStringFold(string, CFStringCompareFlags(rawValue: options.rawValue), _unsafeReferenceCast(locale?._bridgeToObjectiveC(), to: Optional<CFLocale>.self))
        return String(_unsafeReferenceCast(string, to: NSString.self))
    }
    
    internal func _replacingOccurrences(ofRegularExpression pattern: String, withTemplate template: String, options: NSString.CompareOptions, range searchRange: NSRange) -> String {
        let regexOptions: NSRegularExpression.Options = options.contains(.caseInsensitive) ? .caseInsensitive : []
        let matchingOptions: NSMatchingOptions = options.contains(.anchored) ? .anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            return regex.stringByReplacingMatches(in: String(self), options: matchingOptions, range: searchRange, withTemplate: template)
        }
        return ""
    }
    
    /* Replace all occurrences of the target string in the specified range with replacement. Specified compare options are used for matching target. If NSRegularExpressionSearch is specified, the replacement is treated as a template, as in the corresponding NSRegularExpression methods, and no other options can apply except NSCaseInsensitiveSearch and NSAnchoredSearch.
     */
    open func replacingOccurrences(of target: String, with replacement: String, options: NSString.CompareOptions = [], range searchRange: NSRange) -> String {
        if options.contains(.regularExpression) {
            return _replacingOccurrences(ofRegularExpression: target, withTemplate: replacement, options: options, range: searchRange)
        }
        
        let str = mutableCopy() as! NSMutableString
        
        if str.replaceOccurrences(of: target, with: replacement, options: options, range: searchRange) == 0 {
            return String(self)
        } else {
            return String(str)
        }
    }
    
    
    /* Replace all occurrences of the target string with replacement. Invokes the above method with 0 options and range of the whole string.
     */
    open func replacingOccurrences(of target: String, with replacement: String) -> String {
        return replacingOccurrences(of: target, with: replacement, options: [], range: NSMakeRange(0, length))
    }
    
    
    /* Replace characters in range with the specified string, returning new string.
     */
    open func replacingCharacters(in range: NSRange, with replacement: String) -> String {
        let str = mutableCopy() as! NSMutableString
        str.replaceCharacters(in: range, with: replacement)
        return String(str)
    }
    
    
    /* Perform string transliteration.  The transformation represented by transform is applied to the receiver. reverse indicates that the inverse transform should be used instead, if it exists. Attempting to use an invalid transform identifier or reverse an irreversible transform will return nil; otherwise the transformed string value is returned (even if no characters are actually transformed). You can pass one of the predefined transforms below (NSStringTransformLatinToKatakana, etc), or any valid ICU transform ID as defined in the ICU User Guide. Arbitrary ICU transform rules are not supported.
     */
    // Returns nil if reverse not applicable or transform is invalid
    open func applyingTransform(_ transform: StringTransform, reverse: Bool) -> String? {
        let str = CFStringCreateMutable(kCFAllocatorDefault, 0)
        CFStringReplaceAll(str, _unsafeReferenceCast(self, to: CFString.self))
        
        if CFStringTransform(str, nil, _unsafeReferenceCast(NSString(string: transform.rawValue), to: CFString.self), reverse) {
            return String(_unsafeReferenceCast(str, to: NSString.self))
        }
        return nil
    }
    
    internal func _getExternalRepresentation(_ data: inout Data, _ dest: URL, _ enc: UInt) throws {
        let length = self.length
        var numBytes = 0
        let theRange = NSMakeRange(0, length)
        if !getBytes(nil, maxLength: Int.max - 1, usedLength: &numBytes, encoding: enc, options: [], range: theRange, remaining: nil) {
            throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteInapplicableStringEncoding.rawValue, userInfo: [
                NSURLErrorKey: dest,
                ])
        }
        var mData = Data(count: numBytes)
        // The getBytes:... call should hopefully not fail, given it succeeded above, but check anyway (mutable string changing behind our back?)
        var used = 0
        // This binds mData memory to UInt8 because Data.withUnsafeMutableBytes does not handle raw pointers.
        try mData.withUnsafeMutableBytes { (mutableBytes: UnsafeMutablePointer<UInt8>) -> Void in
            if !getBytes(mutableBytes, maxLength: numBytes, usedLength: &used, encoding: enc, options: [], range: theRange, remaining: nil) {
                throw NSError(domain: NSCocoaErrorDomain, code: CocoaError.fileWriteUnknown.rawValue, userInfo: [
                    NSURLErrorKey: dest,
                    ])
            }
        }
        data = mData
    }
    
    internal func _writeTo(_ url: URL, _ useAuxiliaryFile: Bool, _ enc: UInt) throws {
        var data = Data()
        try _getExternalRepresentation(&data, url, enc)
        try data.write(to: url, options: useAuxiliaryFile ? .atomic : [])
    }
    
    /* Write to specified url or path using the specified encoding.  The optional error return is to indicate file system or encoding errors.
     */
    open func write(to url: URL, atomically useAuxiliaryFile: Bool, encoding enc: UInt) throws {
        try _writeTo(url, useAuxiliaryFile, enc)
    }
    
    open func write(toFile path: String, atomically useAuxiliaryFile: Bool, encoding enc: UInt) throws {
        try _writeTo(URL(fileURLWithPath: path), useAuxiliaryFile, enc)
    }
    
    override open var _cfTypeID: CFTypeID {
        return CFStringGetTypeID()
    }
    
    open override var classForCoder: AnyClass { return NSString.self }
}

extension NSString : _NSFactory { }

extension NSString : ExpressibleByStringLiteral {
    
}

extension NSString {
    
    public convenience init(format: NSString, _ args: CVarArg...) {
        let str = withVaList(args) { (va_args) -> NSString in
            return NSString(format: String(format), arguments: va_args)
        }
        
        self.init(factory: str)
    }
    
    public convenience init(format: NSString, locale: Locale?, _ args: CVarArg...) {
        let str = withVaList(args) { (va_args) -> NSString in
            return NSString(format: String(format), locale: locale, arguments: va_args)
        }
        
        self.init(factory: str)
    }
    
    public class func localizedStringWithFormat(_ format: NSString, _ args: CVarArg...) ->NSString {
        return withVaList(args) {
            NSString(format: String(format), locale: Locale.current, arguments: $0)
        }
    }
    
    public func appendingFormat(_ format: NSString, _ args: CVarArg...) -> NSString {
        return withVaList(args) {
            return NSString(string: self.appending(String(NSString(format: String(format), arguments: $0))))
        }
    }
}

extension NSString {
    
    /// Returns an `NSString` object initialized by copying the characters
    /// from another given string.
    ///
    /// - Returns: An `NSString` object initialized by copying the
    ///   characters from `aString`. The returned object may be different
    ///   from the original receiver.
    @nonobjc public convenience init(string aString: NSString) {
        self.init(string: String(aString))
    }
}

extension NSString : CustomPlaygroundQuickLookable {
    
    /// A custom playground Quick Look for this instance.
    ///
    /// If this type has value semantics, the `PlaygroundQuickLook` instance
    /// should be unaffected by subsequent mutations.
    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        return .text(String(self))
    }
}

public struct StringTransform : RawRepresentable, Equatable, Hashable {
    public private(set) var rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    public static func ==(_ lhs: StringTransform, _ rhs: StringTransform) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension StringTransform {
    public static let latinToKatakana = StringTransform(rawValue: "kCFStringTransformLatinKatakana")
    public static let latinToHiragana = StringTransform(rawValue: "kCFStringTransformLatinHiragana")
    public static let latinToHangul = StringTransform(rawValue: "kCFStringTransformLatinHangul")
    public static let latinToArabic = StringTransform(rawValue: "kCFStringTransformLatinArabic")
    public static let latinToHebrew = StringTransform(rawValue: "kCFStringTransformLatinHebrew")
    public static let latinToThai = StringTransform(rawValue: "kCFStringTransformLatinThai")
    public static let latinToCyrillic = StringTransform(rawValue: "kCFStringTransformLatinCyrillic")
    public static let latinToGreek = StringTransform(rawValue: "kCFStringTransformLatinGreek")
    public static let toLatin = StringTransform(rawValue: "kCFStringTransformToLatin")
    public static let mandarinToLatin = StringTransform(rawValue: "kCFStringTransformMandarinLatin")
    public static let hiraganaToKatakana = StringTransform(rawValue: "kCFStringTransformHiraganaKatakana")
    public static let fullwidthToHalfwidth = StringTransform(rawValue: "kCFStringTransformFullwidthHalfwidth")
    public static let toXMLHex = StringTransform(rawValue: "kCFStringTransformToXMLHex")
    public static let toUnicodeName = StringTransform(rawValue: "kCFStringTransformToUnicodeName")
    public static let stripCombiningMarks = StringTransform(rawValue: "kCFStringTransformStripCombiningMarks")
    public static let stripDiacritics = StringTransform(rawValue: "kCFStringTransformStripDiacritics")
}

public struct StringEncodingDetectionOptionsKey : RawRepresentable, Equatable, Hashable {
    public private(set) var rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    public static func ==(_ lhs: StringEncodingDetectionOptionsKey, _ rhs: StringEncodingDetectionOptionsKey) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension NSString {
    
    
    /* This API is used to detect the string encoding of a given raw data. It can also do lossy string conversion. It converts the data to a string in the detected string encoding. The data object contains the raw bytes, and the option dictionary contains the hints and parameters for the analysis. The opts dictionary can be nil. If the string parameter is not NULL, the string created by the detected string encoding is returned. The lossy substitution string is emitted in the output string for characters that could not be converted when lossy conversion is enabled. The usedLossyConversion indicates if there is any lossy conversion in the resulted string. If no encoding can be detected, 0 is returned.
     
     The possible items for the dictionary are:
     1) an array of suggested string encodings (without specifying the 3rd option in this list, all string encodings are considered but the ones in the array will have a higher preference; moreover, the order of the encodings in the array is important: the first encoding has a higher preference than the second one in the array)
     2) an array of string encodings not to use (the string encodings in this list will not be considered at all)
     3) a boolean option indicating whether only the suggested string encodings are considered
     4) a boolean option indicating whether lossy is allowed
     5) an option that gives a specific string to substitude for mystery bytes
     6) the current user's language
     7) a boolean option indicating whether the data is generated by Windows
     
     If the values in the dictionary have wrong types (for example, the value of NSStringEncodingDetectionSuggestedEncodingsKey is not an array), an exception is thrown.
     If the values in the dictionary are unknown (for example, the value in the array of suggested string encodings is not a valid encoding), the values will be ignored.
     */
    
    // Currently disabled since it uses AutoreleasingUnsafeMutablePointer
#if false
    open class func stringEncoding(for data: Data, encodingOptions opts: [StringEncodingDetectionOptionsKey : Any]? = nil, convertedString string: AutoreleasingUnsafeMutablePointer<NSString?>?, usedLossyConversion: UnsafeMutablePointer<ObjCBool>?) -> UInt {
        NSUnimplemented()
    }
#endif
}
extension StringEncodingDetectionOptionsKey {
    public static let suggestedEncodingsKey = StringEncodingDetectionOptionsKey(rawValue: "NSStringEncodingDetectionSuggestedEncodingsKey")
    public static let disallowedEncodingsKey = StringEncodingDetectionOptionsKey(rawValue: "NSStringEncodingDetectionDisallowedEncodingsKey") // NSArray of NSNumbers which contain NSStringEncoding values; if this key is not present in the dictionary, all encodings are considered
    public static let useOnlySuggestedEncodingsKey = StringEncodingDetectionOptionsKey(rawValue: "NSStringEncodingDetectionUseOnlySuggestedEncodingsKey") // NSNumber boolean value; if this key is not present in the dictionary, the default value is NO
    public static let allowLossyKey = StringEncodingDetectionOptionsKey(rawValue: "NSStringEncodingDetectionAllowLossyKey") // NSNumber boolean value; if this key is not present in the dictionary, the default value is YES
    public static let fromWindowsKey = StringEncodingDetectionOptionsKey(rawValue: "NSStringEncodingDetectionFromWindowsKey") // NSNumber boolean value; if this key is not present in the dictionary, the default value is NO
    public static let lossySubstitutionKey = StringEncodingDetectionOptionsKey(rawValue: "NSStringEncodingDetectionLossySubstitutionKey") // NSString value; if this key is not present in the dictionary, the default value is U+FFFD
    public static let likelyLanguageKey = StringEncodingDetectionOptionsKey(rawValue: "NSStringEncodingDetectionLikelyLanguageKey") // NSString value; ISO language code; if this key is not present in the dictionary, no such information is considered
}

//extension NSString : NSItemProviderReading, NSItemProviderWriting {
//}

open class NSMutableString : NSString {
    public convenience override init() {
        if type(of: self) == NSMutableString.self {
            self.init(factory: _unsafeReferenceCast(CFStringCreateMutable(kCFAllocatorDefault, 0), to: NSMutableString.self))
        } else {
            self.init(capacity: 0)
        }
    }
    
    /* NSMutableString primitive (funnel) method. See below for the other mutation methods.
     */
    open func replaceCharacters(in range: NSRange, with aString: String) {
        NSRequiresConcreteImplementation()
    }
    
    internal func appendCharacters(_ chars: UnsafePointer<unichar>, length: Int) {
        replaceCharacters(in: NSMakeRange(self.length, 0), withCharacters: chars, length: length)
    }
    
    internal func replaceCharacters(in range: NSRange, withCharacters chars: UnsafePointer<unichar>, length: Int) {
        let str = NSString(characters: chars, length: length)
        replaceCharacters(in: range, with: String(str))
    }
    
    internal func _cfAppendCString(_ chars: UnsafePointer<Int8>, length: Int) {
        replaceCharacters(in: NSMakeRange(self.length, 0), withCString: chars, length: length)
    }
    
    internal func replaceCharacters(in range: NSRange, withCString cString: UnsafePointer<Int8>, length: Int) {
        let str = NSString(cString: cString, length: length)
        replaceCharacters(in: range, with: String(str))
    }
    
    open func insert(_ aString: String, at loc: Int) {
        replaceCharacters(in: NSRange(location: loc, length: 0), with: aString)
    }
    
    open func deleteCharacters(in range: NSRange) {
        replaceCharacters(in: range, with: "")
    }
    
    open func append(_ aString: String) {
        replaceCharacters(in: NSRange(location: length, length: 0), with: aString)
    }
    
    
    open func setString(_ aString: String) {
        replaceCharacters(in: NSMakeRange(0, length), with: aString)
    }
    
    internal func _replaceOccurrences(ofRegularExpression pattern: String, withTemplate template: String, options: NSString.CompareOptions, range searchRange: NSRange) -> Int {
        let regexOptions: NSRegularExpression.Options = options.contains(.caseInsensitive) ? .caseInsensitive : []
        let matchingOptions: NSMatchingOptions = options.contains(.anchored) ? .anchored : []
        if let regex = _createRegexForPattern(pattern, regexOptions) {
            return regex.replaceMatches(in: self, options: matchingOptions, range: searchRange, withTemplate: template)
        }
        return 0
    }
    
    open func replaceOccurrences(of target: String, with replacement: String, options: NSString.CompareOptions = [], range searchRange: NSRange) -> Int {
        let len = length
        if (searchRange.length > len) || (searchRange.location > len - searchRange.length) {
            _rangeError(searchRange, len)
        }
        if options.contains(.regularExpression) {
            return _replaceOccurrences(ofRegularExpression: target, withTemplate: replacement, options: options, range: searchRange)
        }
        
        var opts = CFOptionFlags(options.rawValue)
        if options.contains(.literal) {
            opts |= CFOptionFlags(kCFCompareNonliteral)
        }
        
        guard let findResults = CFStringCreateArrayWithFindResults(kCFAllocatorDefault, _unsafeReferenceCast(self, to: CFString.self), _unsafeReferenceCast(NSString(string: target), to: CFString.self), CFRangeMake(searchRange.location, searchRange.length), CFStringCompareFlags(rawValue: opts)) else {
            return 0
        }
        
        let backwards = options.contains(.backwards)
        
        let numOccurrences = CFArrayGetCount(findResults)
        for cnt in 0..<numOccurrences {
            let index = backwards ? cnt : (numOccurrences - cnt - 1)
            let range = CFArrayGetValueAtIndex(findResults, index).assumingMemoryBound(to: CFRange.self).pointee
            replaceCharacters(in: NSMakeRange(range.location, range.length), with: replacement)
        }
        
        return numOccurrences
    }
    
    open func applyTransform(_ transform: String, reverse: Bool, range: NSRange, updatedRange resultingRange: NSRangePointer?) -> Bool {
        var cfRange = CFRangeMake(range.location, range.length)
        guard CFStringTransform(_unsafeReferenceCast(self, to: CFMutableString.self), &cfRange, _unsafeReferenceCast(NSString(string: transform), to: CFString.self), reverse) else {
            return false
        }
        resultingRange?.pointee = NSMakeRange(cfRange.location, cfRange.length)
        return true
    }
    
    internal init(_ placeholder: ()) {
        super.init()
    }
    
    public convenience init(capacity: Int) {
        if type(of: self) == NSMutableString.self {
            self.init(factory: _unsafeReferenceCast(CFStringCreateMutable(kCFAllocatorDefault, 0), to: NSMutableString.self))
        } else {
            self.init(())
        }
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if !aDecoder.allowsKeyedCoding {
            let archiveVersion = aDecoder.version(forClassName: "NSString")
            if archiveVersion == 1 {
                let str = aDecoder._withDecodedBytes { (buffer) -> String? in
                    return String(bytes: buffer, encoding: .utf8)
                }
                guard let s = str else {
                    return nil
                }
                
                self.init(string: s)
                return
            } else {
                fatalError("NSString cannot decode class version \(archiveVersion)")
            }
        }
        if type(of: aDecoder) == NSKeyedUnarchiver.self {
            guard let plistValue = aDecoder._decodePropertyListForKey("NS.string") else {
                return nil
            }
            guard let str = plistValue as? String else {
                return nil
            }
            self.init(string: str)
            return
        } else {
            let data = aDecoder._withDecodedBytes(forKey: "NS.bytes") { (buffer) -> Data in
                return Data(UnsafeBufferPointer<UInt8>.init(start: buffer.baseAddress?.assumingMemoryBound(to: UInt8.self), count: buffer.count))
            }
            self.init(data: data, encoding: String.Encoding.utf8.rawValue)
            return
        }
    }
    
    public convenience init(string aString: String) {
        self.init(capacity: 0)
        self.append(aString)
    }
    
    open override var classForCoder: AnyClass { return NSMutableString.self }
}

extension NSMutableString {
    
    public func appendFormat(_ format: NSString, _ args: CVarArg...) {
        withVaList(args) {
            let temp = NSString(format: String(format), arguments: $0)
            replaceCharacters(in: NSMakeRange(length, 0), with: String(temp))
        }
    }
}

extension NSString {
    
    
    open func propertyList() -> Any {
        var errorStr: Unmanaged<CFString>? = nil
        
        let result = _CFPropertyListCreateFromXMLString(kCFAllocatorDefault, _unsafeReferenceCast(self, to: CFString.self), 0, &errorStr, true, nil)
        if let err = errorStr {
            let errorString = err.takeRetainedValue()
            if let d = data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                do {
                    let res = try PropertyListSerialization.propertyList(from: d, format: nil)
                    return res
                } catch {
                    fatalError("\(error)")
                }
            } else {
                fatalError(String(_unsafeReferenceCast(errorString, to: NSString.self)))
            }
        }
        return _SwiftValue.fetch(result)!
    }
    
    open func propertyListFromStringsFileFormat() -> [AnyHashable : Any]? {
        return propertyList() as? [AnyHashable : Any]
    }
}

extension NSString {
    
    
    /* This method is unsafe because it could potentially cause buffer overruns. You should use -getCharacters:range: instead.
     */
    open func getCharacters(_ buffer: UnsafeMutablePointer<unichar>) {
        getCharacters(buffer, range: NSMakeRange(0, length))
    }
}

public let NSProprietaryStringEncoding: UInt = 65536 /* Installation-specific encoding */

/* The rest of this file is bookkeeping stuff that has to be here. Don't use this stuff, don't refer to it.
 */

open class NSSimpleCString : NSString {
    var bytes: UnsafePointer<Int8>? = nil
    var numBytes: Int32 = 0
#if arch(x86_64) || arch(arm64)
    var _unused: Int32 = 0
#endif
    
    open override func character(at index: Int) -> unichar {
        if index >= numBytes {
            _indexError(index, Int(numBytes))
        }
        let ch = bytes!.advanced(by: index).pointee
        return _NSCStringCharToUnicharTable!.advanced(by: Int(ch)).pointee
    }
    
    open override var length: Int {
        return Int(numBytes)
    }
    
    open override var fastestEncoding: UInt {
        return String.Encoding.ascii.rawValue
    }
}

open class NSConstantString : NSSimpleCString {
}
