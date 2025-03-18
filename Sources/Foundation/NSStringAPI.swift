//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// Exposing the API of NSString on Swift's String
//
//===----------------------------------------------------------------------===//

// Open Issues
// ===========
//
// Property Lists need to be properly bridged
//

/// From a non-`nil` `UnsafePointer` to a null-terminated string
/// with possibly-transient lifetime, create a null-terminated array of 'C' char.
/// Returns `nil` if passed a null pointer.
internal func _persistCString(_ p: UnsafePointer<CChar>?) -> [CChar]? {
    guard let cString = p else {
        return nil
    }
    let bytesToCopy = UTF8._nullCodeUnitOffset(in: cString) + 1 // +1 for the terminating NUL
    let result = [CChar](unsafeUninitializedCapacity: bytesToCopy) { buf, initedCount in
        buf.baseAddress!.update(from: cString, count: bytesToCopy)
        initedCount = bytesToCopy
    }
    return result
}

extension String {
    public typealias EncodingConversionOptions = NSString.EncodingConversionOptions
    public typealias EnumerationOptions = NSString.EnumerationOptions
}

extension String {
    //===--- Class Methods --------------------------------------------------===//
    //===--------------------------------------------------------------------===//

    // @property (class) const NSStringEncoding *availableStringEncodings;

    /// An array of the encodings that strings support in the application's
    /// environment.
    public static var availableStringEncodings: [Encoding] {
        var result = [Encoding]()
        var p = NSString.availableStringEncodings
        while p.pointee != 0 {
            result.append(Encoding(rawValue: p.pointee))
            p += 1
        }
        return result
    }

    // @property (class) NSStringEncoding defaultCStringEncoding;

    /// The C-string encoding assumed for any method accepting a C string as an
    /// argument.
    public static var defaultCStringEncoding: Encoding {
        return Encoding(rawValue: NSString.defaultCStringEncoding)
    }

    // + (NSString *)localizedNameOfStringEncoding:(NSStringEncoding)encoding

    /// Returns a human-readable string giving the name of the specified encoding.
    ///
    /// - Parameter encoding: A string encoding. For possible values, see
    ///   `String.Encoding`.
    /// - Returns: A human-readable string giving the name of `encoding` in the
    ///   current locale.
    public static func localizedName(
        of encoding: Encoding
        ) -> String {
        return NSString.localizedName(of: encoding.rawValue)
    }

    // + (instancetype)localizedStringWithFormat:(NSString *)format, ...

    /// Returns a string created by using a given format string as a
    /// template into which the remaining argument values are substituted
    /// according to the user's default locale.
    public static func localizedStringWithFormat(
        _ format: String, _ arguments: CVarArg...
        ) -> String {
        return String(format: format, locale: Locale.current,
                      arguments: arguments)
    }

    //===--------------------------------------------------------------------===//
    // NSString factory functions that have a corresponding constructor
    // are omitted.
    //
    // + (instancetype)string
    //
    // + (instancetype)
    //     stringWithCharacters:(const unichar *)chars length:(NSUInteger)length
    //
    // + (instancetype)stringWithFormat:(NSString *)format, ...
    //
    // + (instancetype)
    //     stringWithContentsOfFile:(NSString *)path
    //     encoding:(NSStringEncoding)enc
    //     error:(NSError **)error
    //
    // + (instancetype)
    //     stringWithContentsOfFile:(NSString *)path
    //     usedEncoding:(NSStringEncoding *)enc
    //     error:(NSError **)error
    //
    // + (instancetype)
    //     stringWithContentsOfURL:(NSURL *)url
    //     encoding:(NSStringEncoding)enc
    //     error:(NSError **)error
    //
    // + (instancetype)
    //     stringWithContentsOfURL:(NSURL *)url
    //     usedEncoding:(NSStringEncoding *)enc
    //     error:(NSError **)error
    //
    // + (instancetype)
    //     stringWithCString:(const char *)cString
    //     encoding:(NSStringEncoding)enc
    //===--------------------------------------------------------------------===//

    //===--- Adds nothing for String beyond what String(s) does -------------===//
    // + (instancetype)stringWithString:(NSString *)aString
    //===--------------------------------------------------------------------===//

    // + (instancetype)stringWithUTF8String:(const char *)bytes

    /// Creates a string by copying the data from a given
    /// null-terminated C array of UTF8-encoded bytes.
    public init?(utf8String bytes: UnsafePointer<CChar>) {
        if let str = String(validatingCString: bytes) {
            self = str
            return
        }
        if let ns = NSString(utf8String: bytes) {
            self = String._unconditionallyBridgeFromObjectiveC(ns)
        } else {
            return nil
        }
    }

    /// Creates a string by copying the data from a given
    /// null-terminated array of UTF8-encoded bytes.
    @_alwaysEmitIntoClient
    public init?(utf8String bytes: [CChar]) {
        guard let nullPosition = bytes.firstIndex(of: 0) else {
            fatalError(
                "input of String.init(utf8String:) must be null-terminated"
            )
        }
        guard nullPosition != bytes.startIndex else {
            self = ""
            return
        }
        let substrBeforeNull = bytes[bytes.startIndex..<nullPosition]
        if let str = String(validating: substrBeforeNull, as: UTF8.self) {
            self = str
            return
        }
        let ns = bytes.withUnsafeBytes {
            NSString(bytes: $0.baseAddress!,
                     length: nullPosition,
                     encoding: Encoding.utf8.rawValue)
        }
        guard let ns = ns else {
            return nil
        }
        self = String._unconditionallyBridgeFromObjectiveC(ns)
    }

    @_alwaysEmitIntoClient
    @available(*, deprecated, message: "Use a copy of the String argument")
    public init?(utf8String bytes: String) {
        var decoded = bytes
        decoded.makeContiguousUTF8()
        if let null = decoded.firstIndex(of: "\0") {
            decoded = String(decoded[..<null])
        }
        self = decoded
    }

    @_alwaysEmitIntoClient
    @available(*, deprecated, message: "Use String(_ scalar: Unicode.Scalar)")
    public init?(utf8String bytes: inout CChar) {
        // a byte interpreted as a buffer is valid only if the value is zero.
        guard bytes == 0 else {
            fatalError(
                "input of String.init(utf8String:) must be null-terminated"
            )
        }
        self = ""
    }
}

extension String {
    //===--- Already provided by String's core ------------------------------===//
    // - (instancetype)init

    // - (instancetype)
    //     initWithBytesNoCopy:(void *)bytes
    //     length:(NSUInteger)length
    //     encoding:(NSStringEncoding)encoding
    //     freeWhenDone:(BOOL)flag

    /// Creates a new string that contains the specified number of bytes from the
    /// given buffer, interpreted in the specified encoding, and optionally
    /// frees the buffer.
    ///
    /// - Warning: This initializer is not memory-safe!
    @available(swift, deprecated: 6.0, message: "String does not support no-copy initialization")
    public init?(
        bytesNoCopy bytes: UnsafeMutableRawPointer, length: Int,
        encoding: Encoding, freeWhenDone flag: Bool
        ) {
        if let ns = NSString(
            bytesNoCopy: bytes, length: length, encoding: encoding.rawValue,
            freeWhenDone: flag) {

            self = String._unconditionallyBridgeFromObjectiveC(ns)
        } else {
            return nil
        }
    }


    // - (instancetype)
    //     initWithCharacters:(const unichar *)characters
    //     length:(NSUInteger)length

    /// Creates a new string that contains the specified number of characters
    /// from the given C array of Unicode characters.
    public init(
        utf16CodeUnits: UnsafePointer<unichar>,
        count: Int
        ) {
        self = String(decoding: UnsafeBufferPointer(start: utf16CodeUnits, count: count), as: UTF16.self)
    }

    // - (instancetype)
    //     initWithCharactersNoCopy:(unichar *)characters
    //     length:(NSUInteger)length
    //     freeWhenDone:(BOOL)flag

    /// Creates a new string that contains the specified number of characters
    /// from the given C array of UTF-16 code units.
    @available(swift, deprecated: 6.0, message: "String does not support no-copy initialization")
    public init(
        utf16CodeUnitsNoCopy: UnsafePointer<unichar>,
        count: Int,
        freeWhenDone flag: Bool
        ) {
        self = String._unconditionallyBridgeFromObjectiveC(NSString(
            charactersNoCopy: UnsafeMutablePointer(mutating: utf16CodeUnitsNoCopy),
            length: count,
            freeWhenDone: flag))
    }

    //===--- Initializers that can fail -------------------------------------===//

    @available(swift, deprecated: 6.0, message: "Use `init(contentsOfFile:encoding:)` instead")
    public init(
        contentsOfFile path: __shared String
        ) throws {
        var encoding = Encoding.utf8
        try self.init(contentsOfFile: path, usedEncoding: &encoding)
    }

    @available(swift, deprecated: 6.0, message: "Use `init(contentsOf:encoding:)` instead")
    public init(
        contentsOf url: __shared URL
        ) throws {
        var encoding = Encoding.utf8
        try self.init(contentsOf: url, usedEncoding: &encoding)
    }

    // - (instancetype)
    //     initWithCString:(const char *)nullTerminatedCString
    //     encoding:(NSStringEncoding)encoding

    /// Produces a string by copying the null-terminated bytes
    /// in a given C array, interpreted according to a given encoding.
    public init?(cString: UnsafePointer<CChar>, encoding enc: Encoding) {
        if enc == .utf8 || enc == .ascii {
            if let str = String(validatingCString: cString) {
                if enc == .utf8 || str._guts._isContiguousASCII {
                    self = str
                    return
                }
            }
        }
        if let ns = NSString(cString: cString, encoding: enc.rawValue) {
            self = String._unconditionallyBridgeFromObjectiveC(ns)
        } else {
            return nil
        }
    }

    /// Produces a string by copying the null-terminated bytes
    /// in a given array, interpreted according to a given encoding.
    @_alwaysEmitIntoClient
    public init?(cString: [CChar], encoding enc: Encoding) {
        guard let nullPosition = cString.firstIndex(of: 0) else {
            fatalError(
                "input of String.init(cString:encoding:) must be null-terminated"
            )
        }

        if enc == .utf8 || enc == .ascii {
            guard nullPosition != cString.startIndex else {
                self = ""
                return
            }
            let substrBeforeNull = cString[cString.startIndex..<nullPosition]
            if let str = String(validating: substrBeforeNull, as: UTF8.self) {
                if enc == .utf8 || str._guts._isContiguousASCII {
                    self = str
                    return
                }
            }
        }
        guard let nullPosition = cString.firstIndex(of: 0) else {
            fatalError(
                "input of String.init(cString:encoding:) must be null-terminated"
            )
        }
        let ns = cString.withUnsafeBytes {
            NSString(bytes: $0.baseAddress!,
                     length: nullPosition,
                     encoding: enc.rawValue)
        }
        guard let ns = ns else {
            return nil
        }
        self = String._unconditionallyBridgeFromObjectiveC(ns)
    }

    @_alwaysEmitIntoClient
    @available(*, deprecated, message: "Use a copy of the String argument")
    public init?(cString: String, encoding enc: Encoding) {
        if enc == .utf8 || enc == .ascii {
            var decoded = cString
            decoded.makeContiguousUTF8()
            if let null = decoded.firstIndex(of: "\0") {
                decoded = String(decoded[..<null])
            }
            if enc == .utf8 || decoded.utf8.allSatisfy({ $0 < 128 }) {
                self = decoded
                return
            }
        }
        return nil
    }

    @_alwaysEmitIntoClient
    @available(*, deprecated, message: "Use String(_ scalar: Unicode.Scalar)")
    public init?(cString: inout CChar, encoding enc: Encoding) {
        // a byte interpreted as a buffer is valid only if the value is zero.
        guard cString == 0 else {
            fatalError(
                "input of String.init(cString:encoding:) must be null-terminated"
            )
        }
        self = ""
    }

    // FIXME: handle optional locale with default arguments

    // - (instancetype)initWithFormat:(NSString *)format, ...

    /// Returns a `String` object initialized by using a given
    /// format string as a template into which the remaining argument
    /// values are substituted.
    public init(format: __shared String, _ arguments: CVarArg...) {
        self = String(format: format, arguments: arguments)
    }

    // - (instancetype)
    //     initWithFormat:(NSString *)format
    //     arguments:(va_list)argList

    /// Returns a `String` object initialized by using a given
    /// format string as a template into which the remaining argument
    /// values are substituted according to the user's default locale.
    public init(format: __shared String, arguments: __shared [CVarArg]) {
        self = String(format: format, locale: nil, arguments: arguments)
    }

    // - (instancetype)initWithFormat:(NSString *)format locale:(id)locale, ...

    /// Returns a `String` object initialized by using a given
    /// format string as a template into which the remaining argument
    /// values are substituted according to given locale information.
    public init(format: __shared String, locale: __shared Locale?, _ args: CVarArg...) {
        self = String(format: format, locale: locale, arguments: args)
    }

    // - (instancetype)
    //     initWithFormat:(NSString *)format
    //     locale:(id)locale
    //     arguments:(va_list)argList

    /// Returns a `String` object initialized by using a given
    /// format string as a template into which the remaining argument
    /// values are substituted according to given locale information.
    public init(format: __shared String, locale: __shared Locale?, arguments: __shared [CVarArg]) {
        self = withVaList(arguments) {
            String._unconditionallyBridgeFromObjectiveC(
                NSString(format: format, locale: locale?._bridgeToObjectiveC(), arguments: $0)
            )
        }
    }

    public init(_ cocoaString: NSString) {
        self = cocoaString._storage
    }
}

extension StringProtocol {
    //===--- Bridging Helpers -----------------------------------------------===//
    //===--------------------------------------------------------------------===//

    /// The corresponding `NSString` - a convenience for bridging code.
    // FIXME(strings): There is probably a better way to bridge Self to NSString
    var _ns: NSString {
        return self._ephemeralString._bridgeToObjectiveC()
    }

    /// Return an `Index` corresponding to the given offset in our UTF-16
    /// representation.
    func _toIndex(_ utf16Index: Int) -> Index {
        return self._toUTF16Index(utf16Index)
    }

    /// Return the UTF-16 code unit offset corresponding to an Index
    func _toOffset(_ idx: String.Index) -> Int {
        return self._toUTF16Offset(idx)
    }

    @inlinable
    internal func _toRelativeNSRange(_ r: Range<String.Index>) -> NSRange {
        return NSRange(self._toUTF16Offsets(r))
    }

    /// Return a `Range<Index>` corresponding to the given `NSRange` of
    /// our UTF-16 representation.
    func _toRange(_ r: NSRange) -> Range<Index> {
        return self._toUTF16Indices(Range(r)!)
    }

    /// Return a `Range<Index>?` corresponding to the given `NSRange` of
    /// our UTF-16 representation.
    func _optionalRange(_ r: NSRange) -> Range<Index>? {
        if r.location == NSNotFound {
            return nil
        }
        return _toRange(r)
    }

    /// Invoke `body` on an `Int` buffer.  If `index` was converted from
    /// non-`nil`, convert the buffer to an `Index` and write it into the
    /// memory referred to by `index`
    func _withOptionalOutParameter<Result>(
        _ index: UnsafeMutablePointer<Index>?,
        _ body: (UnsafeMutablePointer<Int>?) -> Result
        ) -> Result {
        var utf16Index: Int = 0
        let result = (index != nil ? body(&utf16Index) : body(nil))
        index?.pointee = _toIndex(utf16Index)
        return result
    }

    /// Invoke `body` on an `NSRange` buffer.  If `range` was converted
    /// from non-`nil`, convert the buffer to a `Range<Index>` and write
    /// it into the memory referred to by `range`
    func _withOptionalOutParameter<Result>(
        _ range: UnsafeMutablePointer<Range<Index>>?,
        _ body: (UnsafeMutablePointer<NSRange>?) -> Result
        ) -> Result {
        var nsRange = NSRange(location: 0, length: 0)
        let result = (range != nil ? body(&nsRange) : body(nil))
        range?.pointee = self._toRange(nsRange)
        return result
    }

    //===--- Instance Methods/Properties-------------------------------------===//
    //===--------------------------------------------------------------------===//

    //===--- Omitted by agreement during API review 5/20/2014 ---------------===//
    // @property BOOL boolValue;

    // - (BOOL)canBeConvertedToEncoding:(NSStringEncoding)encoding

    /// Returns a Boolean value that indicates whether the string can be
    /// converted to the specified encoding without loss of information.
    ///
    /// - Parameter encoding: A string encoding.
    /// - Returns: `true` if the string can be encoded in `encoding` without loss
    ///   of information; otherwise, `false`.
    public func canBeConverted(to encoding: String.Encoding) -> Bool {
        return _ns.canBeConverted(to: encoding.rawValue)
    }

    // - (NSComparisonResult)caseInsensitiveCompare:(NSString *)aString

    /// Returns the result of invoking `compare:options:` with
    /// `NSCaseInsensitiveSearch` as the only option.
    public func caseInsensitiveCompare<
        T : StringProtocol
        >(_ aString: T) -> ComparisonResult {
        return _ns.caseInsensitiveCompare(aString._ephemeralString)
    }

    //===--- Omitted by agreement during API review 5/20/2014 ---------------===//
    // - (unichar)characterAtIndex:(NSUInteger)index
    //
    // We have a different meaning for "Character" in Swift, and we are
    // trying not to expose error-prone UTF-16 integer indexes

    // - (NSString *)
    //     commonPrefixWithString:(NSString *)aString
    //     options:(StringCompareOptions)mask

    /// Returns a string containing characters this string and the
    /// given string have in common, starting from the beginning of each
    /// up to the first characters that aren't equivalent.
    public func commonPrefix<
        T : StringProtocol
        >(with aString: T, options: String.CompareOptions = []) -> String {
        return _ns.commonPrefix(with: aString._ephemeralString, options: options)
    }

    // - (NSComparisonResult)
    //     compare:(NSString *)aString
    //
    // - (NSComparisonResult)
    //     compare:(NSString *)aString options:(StringCompareOptions)mask
    //
    // - (NSComparisonResult)
    //     compare:(NSString *)aString options:(StringCompareOptions)mask
    //     range:(NSRange)range
    //
    // - (NSComparisonResult)
    //     compare:(NSString *)aString options:(StringCompareOptions)mask
    //     range:(NSRange)range locale:(id)locale

    /// Compares the string using the specified options and
    /// returns the lexical ordering for the range.
    public func compare<T : StringProtocol>(
        _ aString: T,
        options mask: String.CompareOptions = [],
        range: Range<Index>? = nil,
        locale: Locale? = nil
        ) -> ComparisonResult {
        // According to Ali Ozer, there may be some real advantage to
        // dispatching to the minimal selector for the supplied options.
        // So let's do that; the switch should compile away anyhow.
        let aString = aString._ephemeralString
        return locale != nil ? _ns.compare(
            aString,
            options: mask,
            range: _toRelativeNSRange(
                range ?? startIndex..<endIndex
            ),
            locale: locale?._bridgeToObjectiveC()
            )

            : range != nil ? _ns.compare(
                aString,
                options: mask,
                range: _toRelativeNSRange(range!)
                )

            : !mask.isEmpty ? _ns.compare(aString, options: mask)

            : _ns.compare(aString)
    }

    // - (NSUInteger)
    //     completePathIntoString:(NSString **)outputName
    //     caseSensitive:(BOOL)flag
    //     matchesIntoArray:(NSArray **)outputArray
    //     filterTypes:(NSArray *)filterTypes

    /// Interprets the string as a path in the file system and
    /// attempts to perform filename completion, returning a numeric
    /// value that indicates whether a match was possible, and by
    /// reference the longest path that matches the string.
    ///
    /// - Returns: The actual number of matching paths.
    public func completePath(
        into outputName: UnsafeMutablePointer<String>? = nil,
        caseSensitive: Bool,
        matchesInto outputArray: UnsafeMutablePointer<[String]>? = nil,
        filterTypes: [String]? = nil
        ) -> Int {
        var outputNamePlaceholder: String?
        var outputArrayPlaceholder = [String]()
        let res = self._ns.completePath(
            into: &outputNamePlaceholder,
            caseSensitive: caseSensitive,
            matchesInto: &outputArrayPlaceholder,
            filterTypes: filterTypes
        )
        if let n = outputNamePlaceholder {
            outputName?.pointee = n
        } else {
            outputName?.pointee = ""
        }
        outputArray?.pointee = outputArrayPlaceholder
        return res
    }

    // - (NSArray *)
    //     componentsSeparatedByCharactersInSet:(NSCharacterSet *)separator

    /// Returns an array containing substrings from the string
    /// that have been divided by characters in the given set.
    public func components(separatedBy separator: CharacterSet) -> [String] {
        return _ns.components(separatedBy: separator)
    }

    // - (const char *)cStringUsingEncoding:(NSStringEncoding)encoding

    /// Returns a representation of the string as a C string
    /// using a given encoding.
    public func cString(using encoding: String.Encoding) -> [CChar]? {
        return _ns._withCString(using: encoding.rawValue) {
            _persistCString($0)
        }
    }

    // @property NSString* decomposedStringWithCanonicalMapping;

    /// A string created by normalizing the string's contents using Form D.
    public var decomposedStringWithCanonicalMapping: String {
        return _ns.decomposedStringWithCanonicalMapping
    }

    // @property NSString* decomposedStringWithCompatibilityMapping;

    /// A string created by normalizing the string's contents using Form KD.
    public var decomposedStringWithCompatibilityMapping: String {
        return _ns.decomposedStringWithCompatibilityMapping
    }

    //===--- Importing Foundation should not affect String printing ---------===//
    // Therefore, we're not exposing this:
    //
    //   @property NSString* description


    //===--- Omitted for consistency with API review results 5/20/2014 -----===//
    // @property double doubleValue;

    // - (void)
    //     enumerateLinesUsing:(void (^)(NSString *line, BOOL *stop))block

    /// Enumerates all the lines in a string.
    public func enumerateLines(
        invoking body: @escaping (_ line: String, _ stop: inout Bool) -> Void
        ) {
        _ns.enumerateLines {
            (line: String, stop: UnsafeMutablePointer<ObjCBool>)
            in
            var stop_ = false
            body(line, &stop_)
            if stop_ {
                stop.pointee = true
            }
        }
    }

    // @property NSStringEncoding fastestEncoding;

    /// The fastest encoding to which the string can be converted without loss
    /// of information.
    public var fastestEncoding: String.Encoding {
        return String.Encoding(rawValue: _ns.fastestEncoding)
    }

    // - (BOOL)
    //     getCString:(char *)buffer
    //     maxLength:(NSUInteger)maxBufferCount
    //     encoding:(NSStringEncoding)encoding

    /// Converts the `String`'s content to a given encoding and
    /// stores them in a buffer.
    /// - Note: will store a maximum of `min(buffer.count, maxLength)` bytes.
    public func getCString(
        _ buffer: inout [CChar], maxLength: Int, encoding: String.Encoding
        ) -> Bool {
        return _ns.getCString(&buffer,
                              maxLength: Swift.min(buffer.count, maxLength),
                              encoding: encoding.rawValue)
    }

    // - (NSUInteger)hash

    /// An unsigned integer that can be used as a hash table address.
    public var hash: Int {
        return _ns.hash
    }

    // - (NSUInteger)lengthOfBytesUsingEncoding:(NSStringEncoding)enc

    /// Returns the number of bytes required to store the
    /// `String` in a given encoding.
    public func lengthOfBytes(using encoding: String.Encoding) -> Int {
        return _ns.lengthOfBytes(using: encoding.rawValue)
    }

    // - (NSComparisonResult)localizedCaseInsensitiveCompare:(NSString *)aString

    /// Compares the string and the given string using a case-insensitive,
    /// localized, comparison.
    public
    func localizedCaseInsensitiveCompare<
        T : StringProtocol
        >(_ aString: T) -> ComparisonResult {
        return _ns.localizedCaseInsensitiveCompare(aString._ephemeralString)
    }

    // - (NSComparisonResult)localizedCompare:(NSString *)aString

    /// Compares the string and the given string using a localized comparison.
    public func localizedCompare<
        T : StringProtocol
        >(_ aString: T) -> ComparisonResult {
        return _ns.localizedCompare(aString._ephemeralString)
    }

    /// Compares the string and the given string as sorted by the Finder.
    public func localizedStandardCompare<
        T : StringProtocol
        >(_ string: T) -> ComparisonResult {
        return _ns.localizedStandardCompare(string._ephemeralString)
    }

    //===--- Omitted for consistency with API review results 5/20/2014 ------===//
    // @property long long longLongValue

    // - (NSUInteger)maximumLengthOfBytesUsingEncoding:(NSStringEncoding)enc

    /// Returns the maximum number of bytes needed to store the
    /// `String` in a given encoding.
    public
    func maximumLengthOfBytes(using encoding: String.Encoding) -> Int {
        return _ns.maximumLengthOfBytes(using: encoding.rawValue)
    }

    // @property NSString* precomposedStringWithCanonicalMapping;

    /// A string created by normalizing the string's contents using Form C.
    public var precomposedStringWithCanonicalMapping: String {
        return _ns.precomposedStringWithCanonicalMapping
    }

    // @property NSString * precomposedStringWithCompatibilityMapping;

    /// A string created by normalizing the string's contents using Form KC.
    public var precomposedStringWithCompatibilityMapping: String {
        return _ns.precomposedStringWithCompatibilityMapping
    }

    // - (BOOL)localizedStandardContainsString:(NSString *)str NS_AVAILABLE(10_11, 9_0);

    /// Returns a Boolean value indicating whether the string contains the given
    /// string, taking the current locale into account.
    ///
    /// This is the most appropriate method for doing user-level string searches,
    /// similar to how searches are done generally in the system.  The search is
    /// locale-aware, case and diacritic insensitive.  The exact list of search
    /// options applied may change over time.
    @available(macOS 10.11, iOS 9.0, *)
    public func localizedStandardContains<
        T : StringProtocol
        >(_ string: T) -> Bool {
        return _ns.localizedStandardContains(string._ephemeralString)
    }

    // @property NSStringEncoding smallestEncoding;

    /// The smallest encoding to which the string can be converted without
    /// loss of information.
    public var smallestEncoding: String.Encoding {
        return String.Encoding(rawValue: _ns.smallestEncoding)
    }

    // - (NSString *)
    //     stringByAddingPercentEncodingWithAllowedCharacters:
    //       (NSCharacterSet *)allowedCharacters

    /// Returns a new string created by replacing all characters in the string
    /// not in the specified set with percent encoded characters.
    public func addingPercentEncoding(
        withAllowedCharacters allowedCharacters: CharacterSet
        ) -> String? {
        // FIXME: the documentation states that this method can return nil if the
        // transformation is not possible, without going into further details.  The
        // implementation can only return nil if malloc() returns nil, so in
        // practice this is not possible.  Still, to be consistent with
        // documentation, we declare the method as returning an optional String.
        //
        // <rdar://problem/17901698> Docs for -[NSString
        // stringByAddingPercentEncodingWithAllowedCharacters] don't precisely
        // describe when return value is nil
        return _ns.addingPercentEncoding(withAllowedCharacters:
            allowedCharacters
        )
    }

    // - (NSString *)stringByAppendingFormat:(NSString *)format, ...

    /// Returns a string created by appending a string constructed from a given
    /// format string and the following arguments.
    public func appendingFormat<
        T : StringProtocol
        >(
        _ format: T, _ arguments: CVarArg...
        ) -> String {
        return _ns.appending(
            String(format: format._ephemeralString, arguments: arguments))
    }

    // - (NSString *)stringByAppendingString:(NSString *)aString

    /// Returns a new string created by appending the given string.
    // FIXME(strings): shouldn't it be deprecated in favor of `+`?
    public func appending<
        T : StringProtocol
        >(_ aString: T) -> String {
        return _ns.appending(aString._ephemeralString)
    }

    /// Returns a string with the given character folding options
    /// applied.
    public func folding(
        options: String.CompareOptions = [], locale: Locale?
        ) -> String {
        return _ns.folding(options: options, locale: locale)
    }

    // - (NSString *)stringByPaddingToLength:(NSUInteger)newLength
    //     withString:(NSString *)padString
    //     startingAtIndex:(NSUInteger)padIndex

    /// Returns a new string formed from the `String` by either
    /// removing characters from the end, or by appending as many
    /// occurrences as necessary of a given pad string.
    public func padding<
        T : StringProtocol
        >(
        toLength newLength: Int,
        withPad padString: T,
        startingAt padIndex: Int
        ) -> String {
        return _ns.padding(
            toLength: newLength,
            withPad: padString._ephemeralString,
            startingAt: padIndex)
    }

    // @property NSString* stringByRemovingPercentEncoding;

    /// A new string made from the string by replacing all percent encoded
    /// sequences with the matching UTF-8 characters.
    public var removingPercentEncoding: String? {
        return _ns.removingPercentEncoding
    }

    // - (NSString *)
    //     stringByReplacingCharactersInRange:(NSRange)range
    //     withString:(NSString *)replacement

    /// Returns a new string in which the characters in a
    /// specified range of the `String` are replaced by a given string.
    public func replacingCharacters<
        T : StringProtocol, R : RangeExpression
        >(in range: R, with replacement: T) -> String where R.Bound == Index {
        return _ns.replacingCharacters(
            in: _toRelativeNSRange(range.relative(to: self)),
            with: replacement._ephemeralString)
    }

    // - (NSString *)
    //     stringByReplacingOccurrencesOfString:(NSString *)target
    //     withString:(NSString *)replacement
    //
    // - (NSString *)
    //     stringByReplacingOccurrencesOfString:(NSString *)target
    //     withString:(NSString *)replacement
    //     options:(StringCompareOptions)options
    //     range:(NSRange)searchRange

    /// Returns a new string in which all occurrences of a target
    /// string in a specified range of the string are replaced by
    /// another given string.
    public func replacingOccurrences<
        Target : StringProtocol,
        Replacement : StringProtocol
        >(
        of target: Target,
        with replacement: Replacement,
        options: String.CompareOptions = [],
        range searchRange: Range<Index>? = nil
        ) -> String {
        let target = target._ephemeralString
        let replacement = replacement._ephemeralString
        return (searchRange != nil) || (!options.isEmpty)
            ? _ns.replacingOccurrences(
                of: target,
                with: replacement,
                options: options,
                range: _toRelativeNSRange(
                    searchRange ?? startIndex..<endIndex
                )
                )
            : _ns.replacingOccurrences(of: target, with: replacement)
    }

    // - (NSString *)stringByTrimmingCharactersInSet:(NSCharacterSet *)set

    /// Returns a new string made by removing from both ends of
    /// the `String` characters contained in a given character set.
    public func trimmingCharacters(in set: CharacterSet) -> String {
        return _ns.trimmingCharacters(in: set)
    }

    //===--- Omitted due to redundancy with "utf8" property -----------------===//
    // - (const char *)UTF8String

    // - (void)
    //     enumerateSubstringsInRange:(NSRange)range
    //     options:(NSStringEnumerationOptions)opts
    //     usingBlock:(
    //       void (^)(
    //         NSString *substring,
    //         NSRange substringRange,
    //         NSRange enclosingRange,
    //         BOOL *stop)
    //       )block

    /// Enumerates the substrings of the specified type in the specified range of
    /// the string.
    ///
    /// Mutation of a string value while enumerating its substrings is not
    /// supported. If you need to mutate a string from within `body`, convert
    /// your string to an `NSMutableString` instance and then call the
    /// `enumerateSubstrings(in:options:using:)` method.
    ///
    /// - Parameters:
    ///   - range: The range within the string to enumerate substrings.
    ///   - opts: Options specifying types of substrings and enumeration styles.
    ///     If `opts` is omitted or empty, `body` is called a single time with
    ///     the range of the string specified by `range`.
    ///   - body: The closure executed for each substring in the enumeration. The
    ///     closure takes four arguments:
    ///     - The enumerated substring. If `substringNotRequired` is included in
    ///       `opts`, this parameter is `nil` for every execution of the
    ///       closure.
    ///     - The range of the enumerated substring in the string that
    ///       `enumerate(in:options:_:)` was called on.
    ///     - The range that includes the substring as well as any separator or
    ///       filler characters that follow. For instance, for lines,
    ///       `enclosingRange` contains the line terminators. The enclosing
    ///       range for the first string enumerated also contains any characters
    ///       that occur before the string. Consecutive enclosing ranges are
    ///       guaranteed not to overlap, and every single character in the
    ///       enumerated range is included in one and only one enclosing range.
    ///     - An `inout` Boolean value that the closure can use to stop the
    ///       enumeration by setting `stop = true`.
    public func enumerateSubstrings<
        R : RangeExpression
        >(
        in range: R,
        options opts: String.EnumerationOptions = [],
        _ body: @escaping (
        _ substring: String?, _ substringRange: Range<Index>,
        _ enclosingRange: Range<Index>, inout Bool
        ) -> Void
        ) where R.Bound == Index {
        _ns.enumerateSubstrings(
        in: _toRelativeNSRange(range.relative(to: self)), options: opts) {
            var stop_ = false

            body($0,
                 self._toRange($1),
                 self._toRange($2),
                 &stop_)

            if stop_ {
                UnsafeMutablePointer($3).pointee = true
            }
        }
    }

    //===--- Omitted for consistency with API review results 5/20/2014 ------===//
    // @property float floatValue;

    // - (BOOL)
    //     getBytes:(void *)buffer
    //     maxLength:(NSUInteger)maxBufferCount
    //     usedLength:(NSUInteger*)usedBufferCount
    //     encoding:(NSStringEncoding)encoding
    //     options:(StringEncodingConversionOptions)options
    //     range:(NSRange)range
    //     remainingRange:(NSRangePointer)leftover

    /// Writes the given `range` of characters into `buffer` in a given
    /// `encoding`, without any allocations.  Does not NULL-terminate.
    ///
    /// - Parameter buffer: A buffer into which to store the bytes from
    ///   the receiver. The returned bytes are not NUL-terminated.
    ///
    /// - Parameter maxBufferCount: The maximum number of bytes to write
    ///   to buffer.
    ///
    /// - Parameter usedBufferCount: The number of bytes used from
    ///   buffer. Pass `nil` if you do not need this value.
    ///
    /// - Parameter encoding: The encoding to use for the returned bytes.
    ///
    /// - Parameter options: A mask to specify options to use for
    ///   converting the receiver's contents to `encoding` (if conversion
    ///   is necessary).
    ///
    /// - Parameter range: The range of characters in the receiver to get.
    ///
    /// - Parameter leftover: The remaining range. Pass `nil` If you do
    ///   not need this value.
    ///
    /// - Returns: `true` iff some characters were converted.
    ///
    /// - Note: Conversion stops when the buffer fills or when the
    ///   conversion isn't possible due to the chosen encoding.
    ///
    /// - Note: will get a maximum of `min(buffer.count, maxLength)` bytes.
    public func getBytes<
        R : RangeExpression
        >(
        _ buffer: inout [UInt8],
        maxLength maxBufferCount: Int,
        usedLength usedBufferCount: UnsafeMutablePointer<Int>,
        encoding: String.Encoding,
        options: String.EncodingConversionOptions = [],
        range: R,
        remaining leftover: UnsafeMutablePointer<Range<Index>>
        ) -> Bool where R.Bound == Index {
        return _withOptionalOutParameter(leftover) {
            self._ns.getBytes(
                &buffer,
                maxLength: Swift.min(buffer.count, maxBufferCount),
                usedLength: usedBufferCount,
                encoding: encoding.rawValue,
                options: options,
                range: _toRelativeNSRange(range.relative(to: self)),
                remaining: $0)
        }
    }

    // - (void)
    //     getLineStart:(NSUInteger *)startIndex
    //     end:(NSUInteger *)lineEndIndex
    //     contentsEnd:(NSUInteger *)contentsEndIndex
    //     forRange:(NSRange)aRange

    /// Returns by reference the beginning of the first line and
    /// the end of the last line touched by the given range.
    public func getLineStart<
        R : RangeExpression
        >(
        _ start: UnsafeMutablePointer<Index>,
        end: UnsafeMutablePointer<Index>,
        contentsEnd: UnsafeMutablePointer<Index>,
        for range: R
        ) where R.Bound == Index {
        _withOptionalOutParameter(start) {
            start in self._withOptionalOutParameter(end) {
                end in self._withOptionalOutParameter(contentsEnd) {
                    contentsEnd in self._ns.getLineStart(
                        start, end: end,
                        contentsEnd: contentsEnd,
                        for: _toRelativeNSRange(range.relative(to: self)))
                }
            }
        }
    }

    // - (void)
    //     getParagraphStart:(NSUInteger *)startIndex
    //     end:(NSUInteger *)endIndex
    //     contentsEnd:(NSUInteger *)contentsEndIndex
    //     forRange:(NSRange)aRange

    /// Returns by reference the beginning of the first paragraph
    /// and the end of the last paragraph touched by the given range.
    public func getParagraphStart<
        R : RangeExpression
        >(
        _ start: UnsafeMutablePointer<Index>,
        end: UnsafeMutablePointer<Index>,
        contentsEnd: UnsafeMutablePointer<Index>,
        for range: R
        ) where R.Bound == Index {
        _withOptionalOutParameter(start) {
            start in self._withOptionalOutParameter(end) {
                end in self._withOptionalOutParameter(contentsEnd) {
                    contentsEnd in self._ns.getParagraphStart(
                        start, end: end,
                        contentsEnd: contentsEnd,
                        for: _toRelativeNSRange(range.relative(to: self)))
                }
            }
        }
    }

    //===--- Already provided by core Swift ---------------------------------===//
    // - (instancetype)initWithString:(NSString *)aString

    //===--- Initializers that can fail dropped for factory functions -------===//
    // - (instancetype)initWithUTF8String:(const char *)bytes

    //===--- Omitted for consistency with API review results 5/20/2014 ------===//
    // @property NSInteger integerValue;
    // @property Int intValue;

    //===--- Omitted by apparent agreement during API review 5/20/2014 ------===//
    // @property BOOL absolutePath;
    // - (BOOL)isEqualToString:(NSString *)aString

    // - (NSRange)rangeOfCharacterFromSet:(NSCharacterSet *)aSet
    //
    // - (NSRange)
    //     rangeOfCharacterFromSet:(NSCharacterSet *)aSet
    //     options:(StringCompareOptions)mask
    //
    // - (NSRange)
    //     rangeOfCharacterFromSet:(NSCharacterSet *)aSet
    //     options:(StringCompareOptions)mask
    //     range:(NSRange)aRange

    /// Finds and returns the range in the `String` of the first
    /// character from a given character set found in a given range with
    /// given options.
    public func rangeOfCharacter(
        from aSet: CharacterSet,
        options mask: String.CompareOptions = [],
        range aRange: Range<Index>? = nil
        ) -> Range<Index>? {
        return _optionalRange(
            _ns.rangeOfCharacter(
                from: aSet,
                options: mask,
                range: _toRelativeNSRange(
                    aRange ?? startIndex..<endIndex
                )
            )
        )
    }

    // - (NSRange)rangeOfComposedCharacterSequenceAtIndex:(NSUInteger)anIndex

    /// Returns the range in the `String` of the composed
    /// character sequence located at a given index.
    public
    func rangeOfComposedCharacterSequence(at anIndex: Index) -> Range<Index> {
        return _toRange(
            _ns.rangeOfComposedCharacterSequence(at: _toOffset(anIndex)))
    }

    // - (NSRange)rangeOfComposedCharacterSequencesForRange:(NSRange)range

    /// Returns the range in the string of the composed character
    /// sequences for a given range.
    public func rangeOfComposedCharacterSequences<
        R : RangeExpression
        >(
        for range: R
        ) -> Range<Index> where R.Bound == Index {
        // Theoretically, this will be the identity function.  In practice
        // I think users will be able to observe differences in the input
        // and output ranges due (if nothing else) to locale changes
        return _toRange(
            _ns.rangeOfComposedCharacterSequences(
                for: _toRelativeNSRange(range.relative(to: self))))
    }

    // - (NSRange)rangeOfString:(NSString *)aString
    //
    // - (NSRange)
    //     rangeOfString:(NSString *)aString options:(StringCompareOptions)mask
    //
    // - (NSRange)
    //     rangeOfString:(NSString *)aString
    //     options:(StringCompareOptions)mask
    //     range:(NSRange)aRange
    //
    // - (NSRange)
    //     rangeOfString:(NSString *)aString
    //     options:(StringCompareOptions)mask
    //     range:(NSRange)searchRange
    //     locale:(Locale *)locale

    /// Finds and returns the range of the first occurrence of a
    /// given string within a given range of the `String`, subject to
    /// given options, using the specified locale, if any.
    public func range<
        T : StringProtocol
        >(
        of aString: T,
        options mask: String.CompareOptions = [],
        range searchRange: Range<Index>? = nil,
        locale: Locale? = nil
        ) -> Range<Index>? {
        let aString = aString._ephemeralString
        return _optionalRange(
            locale != nil ? _ns.range(
                of: aString,
                options: mask,
                range: _toRelativeNSRange(
                    searchRange ?? startIndex..<endIndex
                ),
                locale: locale
                )
                : searchRange != nil ? _ns.range(
                    of: aString, options: mask, range: _toRelativeNSRange(searchRange!)
                    )
                : !mask.isEmpty ? _ns.range(of: aString, options: mask)
                : _ns.range(of: aString)
        )
    }

    // - (NSRange)localizedStandardRangeOfString:(NSString *)str NS_AVAILABLE(10_11, 9_0);

    /// Finds and returns the range of the first occurrence of a given string,
    /// taking the current locale into account.  Returns `nil` if the string was
    /// not found.
    ///
    /// This is the most appropriate method for doing user-level string searches,
    /// similar to how searches are done generally in the system.  The search is
    /// locale-aware, case and diacritic insensitive.  The exact list of search
    /// options applied may change over time.
    @available(macOS 10.11, iOS 9.0, *)
    public func localizedStandardRange<
        T : StringProtocol
        >(of string: T) -> Range<Index>? {
        return _optionalRange(
            _ns.localizedStandardRange(of: string._ephemeralString))
    }

    //===--- From the 10.10 release notes; not in public documentation ------===//
    // No need to make these unavailable on earlier OSes, since they can
    // forward trivially to rangeOfString.

    /// Returns `true` iff `other` is non-empty and contained within
    /// `self` by case-sensitive, non-literal search.
    ///
    /// Equivalent to `self.rangeOfString(other) != nil`
    public func contains<T : StringProtocol>(_ other: T) -> Bool {
        let r = self.range(of: other) != nil
        if #available(macOS 10.10, iOS 8.0, *) {
            assert(r == _ns.contains(other._ephemeralString))
        }
        return r
    }

    /// Returns a Boolean value indicating whether the given string is non-empty
    /// and contained within this string by case-insensitive, non-literal
    /// search, taking into account the current locale.
    ///
    /// Locale-independent case-insensitive operation, and other needs, can be
    /// achieved by calling `range(of:options:range:locale:)`.
    ///
    /// Equivalent to:
    ///
    ///     range(of: other, options: .caseInsensitiveSearch,
    ///           locale: Locale.current) != nil
    public func localizedCaseInsensitiveContains<
        T : StringProtocol
        >(_ other: T) -> Bool {
        let r = self.range(
            of: other, options: .caseInsensitive, locale: Locale.current
            ) != nil
        if #available(macOS 10.10, iOS 8.0, *) {
            assert(r ==
                _ns.localizedCaseInsensitiveContains(other._ephemeralString))
        }
        return r
    }
}

// Deprecated slicing
extension StringProtocol where Index == String.Index {
    // - (NSString *)substringFromIndex:(NSUInteger)anIndex

    /// Returns a new string containing the characters of the
    /// `String` from the one at a given index to the end.
    @available(swift, deprecated: 4.0,
    message: "Please use String slicing subscript with a 'partial range from' operator.")
    public func substring(from index: Index) -> String {
        return _ns.substring(from: _toOffset(index))
    }

    // - (NSString *)substringToIndex:(NSUInteger)anIndex

    /// Returns a new string containing the characters of the
    /// `String` up to, but not including, the one at a given index.
    @available(swift, deprecated: 4.0,
    message: "Please use String slicing subscript with a 'partial range upto' operator.")
    public func substring(to index: Index) -> String {
        return _ns.substring(to: _toOffset(index))
    }

    // - (NSString *)substringWithRange:(NSRange)aRange

    /// Returns a string object containing the characters of the
    /// `String` that lie within a given range.
    @available(swift, deprecated: 4.0,
    message: "Please use String slicing subscript.")
    public func substring(with aRange: Range<Index>) -> String {
        return _ns.substring(with: _toRelativeNSRange(aRange))
    }
}

extension StringProtocol {
    // - (const char *)fileSystemRepresentation

    /// Returns a file system-specific representation of the `String`.
    @available(*, unavailable, message: "Use getFileSystemRepresentation on URL instead.")
    public var fileSystemRepresentation: [CChar] {
        fatalError("unavailable function can't be called")
    }

    // - (BOOL)
    //     getFileSystemRepresentation:(char *)buffer
    //     maxLength:(NSUInteger)maxLength

    /// Interprets the `String` as a system-independent path and
    /// fills a buffer with a C-string in a format and encoding suitable
    /// for use with file-system calls.
    /// - Note: will store a maximum of `min(buffer.count, maxLength)` bytes.
    @available(*, unavailable, message: "Use getFileSystemRepresentation on URL instead.")
    public func getFileSystemRepresentation(
        _ buffer: inout [CChar], maxLength: Int) -> Bool {
        fatalError("unavailable function can't be called")
    }

    //===--- Kept for consistency with API review results 5/20/2014 ---------===//
    // We decided to keep pathWithComponents, so keeping this too
    // @property NSString lastPathComponent;

    /// Returns the last path component of the `String`.
    @available(*, unavailable, message: "Use lastPathComponent on URL instead.")
    public var lastPathComponent: String {
        fatalError("unavailable function can't be called")
    }

    //===--- Renamed by agreement during API review 5/20/2014 ---------------===//
    // @property NSUInteger length;

    /// Returns the number of Unicode characters in the `String`.
    @available(*, unavailable,
    message: "Take the count of a UTF-16 view instead, i.e. str.utf16.count")
    public var utf16Count: Int {
        fatalError("unavailable function can't be called")
    }

    // @property NSArray* pathComponents

    /// Returns an array of NSString objects containing, in
    /// order, each path component of the `String`.
    @available(*, unavailable, message: "Use pathComponents on URL instead.")
    public var pathComponents: [String] {
        fatalError("unavailable function can't be called")
    }

    // @property NSString* pathExtension;

    /// Interprets the `String` as a path and returns the
    /// `String`'s extension, if any.
    @available(*, unavailable, message: "Use pathExtension on URL instead.")
    public var pathExtension: String {
        fatalError("unavailable function can't be called")
    }

    // @property NSString *stringByAbbreviatingWithTildeInPath;

    /// Returns a new string that replaces the current home
    /// directory portion of the current path with a tilde (`~`)
    /// character.
    @available(*, unavailable, message: "Use abbreviatingWithTildeInPath on NSString instead.")
    public var abbreviatingWithTildeInPath: String {
        fatalError("unavailable function can't be called")
    }

    // - (NSString *)stringByAppendingPathComponent:(NSString *)aString

    /// Returns a new string made by appending to the `String` a given string.
    @available(*, unavailable, message: "Use appendingPathComponent on URL instead.")
    public func appendingPathComponent(_ aString: String) -> String {
        fatalError("unavailable function can't be called")
    }

    // - (NSString *)stringByAppendingPathExtension:(NSString *)ext

    /// Returns a new string made by appending to the `String` an
    /// extension separator followed by a given extension.
    @available(*, unavailable, message: "Use appendingPathExtension on URL instead.")
    public func appendingPathExtension(_ ext: String) -> String? {
        fatalError("unavailable function can't be called")
    }

    // @property NSString* stringByDeletingLastPathComponent;

    /// Returns a new string made by deleting the last path
    /// component from the `String`, along with any final path
    /// separator.
    @available(*, unavailable, message: "Use deletingLastPathComponent on URL instead.")
    public var deletingLastPathComponent: String {
        fatalError("unavailable function can't be called")
    }

    // @property NSString* stringByDeletingPathExtension;

    /// Returns a new string made by deleting the extension (if
    /// any, and only the last) from the `String`.
    @available(*, unavailable, message: "Use deletingPathExtension on URL instead.")
    public var deletingPathExtension: String {
        fatalError("unavailable function can't be called")
    }

    // @property NSString* stringByExpandingTildeInPath;

    /// Returns a new string made by expanding the initial
    /// component of the `String` to its full path value.
    @available(*, unavailable, message: "Use expandingTildeInPath on NSString instead.")
    public var expandingTildeInPath: String {
        fatalError("unavailable function can't be called")
    }

    // - (NSString *)
    //     stringByFoldingWithOptions:(StringCompareOptions)options
    //     locale:(Locale *)locale

    @available(*, unavailable, renamed: "folding(options:locale:)")
    public func folding(
        _ options: String.CompareOptions = [], locale: Locale?
        ) -> String {
        fatalError("unavailable function can't be called")
    }

    // @property NSString* stringByResolvingSymlinksInPath;

    /// Returns a new string made from the `String` by resolving
    /// all symbolic links and standardizing path.
    @available(*, unavailable, message: "Use resolvingSymlinksInPath on URL instead.")
    public var resolvingSymlinksInPath: String {
        fatalError("unavailable property")
    }

    // @property NSString* stringByStandardizingPath;

    /// Returns a new string made by removing extraneous path
    /// components from the `String`.
    @available(*, unavailable, message: "Use standardizingPath on URL instead.")
    public var standardizingPath: String {
        fatalError("unavailable function can't be called")
    }

    // - (NSArray *)stringsByAppendingPaths:(NSArray *)paths

    /// Returns an array of strings made by separately appending
    /// to the `String` each string in a given array.
    @available(*, unavailable, message: "Map over paths with appendingPathComponent instead.")
    public func strings(byAppendingPaths paths: [String]) -> [String] {
        fatalError("unavailable function can't be called")
    }

}

// Old method names
extension NSString {
    @available(*, unavailable, renamed: "path(withComponents:)")
    public static func pathWithComponents(_ components: [String]) -> String {
        fatalError("unavailable function can't be called")
    }
}

// Pre-Swift-3 method names
extension String {
    @available(*, unavailable, renamed: "localizedName(of:)")
    public static func localizedNameOfStringEncoding(
        _ encoding: String.Encoding
        ) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, message: "Use fileURL(withPathComponents:) on URL instead.")
    public static func pathWithComponents(_ components: [String]) -> String {
        fatalError("unavailable function can't be called")
    }

    // + (NSString *)pathWithComponents:(NSArray *)components

    /// Returns a string built from the strings in a given array
    /// by concatenating them with a path separator between each pair.
    @available(*, unavailable, message: "Use fileURL(withPathComponents:) on URL instead.")
    public static func path(withComponents components: [String]) -> String {
        fatalError("unavailable function can't be called")
    }
}

extension StringProtocol {

    @available(*, unavailable, renamed: "canBeConverted(to:)")
    public func canBeConvertedToEncoding(_ encoding: String.Encoding) -> Bool {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "capitalizedString(with:)")
    public func capitalizedStringWith(_ locale: Locale?) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "commonPrefix(with:options:)")
    public func commonPrefixWith(
        _ aString: String, options: String.CompareOptions) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "completePath(into:outputName:caseSensitive:matchesInto:filterTypes:)")
    public func completePathInto(
        _ outputName: UnsafeMutablePointer<String>? = nil,
        caseSensitive: Bool,
        matchesInto matchesIntoArray: UnsafeMutablePointer<[String]>? = nil,
        filterTypes: [String]? = nil
        ) -> Int {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "components(separatedBy:)")
    public func componentsSeparatedByCharactersIn(
        _ separator: CharacterSet
        ) -> [String] {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "components(separatedBy:)")
    public func componentsSeparatedBy(_ separator: String) -> [String] {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "cString(usingEncoding:)")
    public func cStringUsingEncoding(_ encoding: String.Encoding) -> [CChar]? {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "data(usingEncoding:allowLossyConversion:)")
    public func dataUsingEncoding(
        _ encoding: String.Encoding,
        allowLossyConversion: Bool = false
        ) -> Data? {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "enumerateSubstrings(in:options:_:)")
    public func enumerateSubstringsIn(
        _ range: Range<Index>,
        options opts: String.EnumerationOptions = [],
        _ body: (
        _ substring: String?, _ substringRange: Range<Index>,
        _ enclosingRange: Range<Index>, inout Bool
        ) -> Void
        ) {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "getBytes(_:maxLength:usedLength:encoding:options:range:remaining:)")
    public func getBytes(
        _ buffer: inout [UInt8],
        maxLength maxBufferCount: Int,
        usedLength usedBufferCount: UnsafeMutablePointer<Int>,
        encoding: String.Encoding,
        options: String.EncodingConversionOptions = [],
        range: Range<Index>,
        remainingRange leftover: UnsafeMutablePointer<Range<Index>>
        ) -> Bool {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "getLineStart(_:end:contentsEnd:for:)")
    public func getLineStart(
        _ start: UnsafeMutablePointer<Index>,
        end: UnsafeMutablePointer<Index>,
        contentsEnd: UnsafeMutablePointer<Index>,
        forRange: Range<Index>
        ) {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "getParagraphStart(_:end:contentsEnd:for:)")
    public func getParagraphStart(
        _ start: UnsafeMutablePointer<Index>,
        end: UnsafeMutablePointer<Index>,
        contentsEnd: UnsafeMutablePointer<Index>,
        forRange: Range<Index>
        ) {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "lengthOfBytes(using:)")
    public func lengthOfBytesUsingEncoding(_ encoding: String.Encoding) -> Int {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "lineRange(for:)")
    public func lineRangeFor(_ aRange: Range<Index>) -> Range<Index> {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "lowercased(with:)")
    public func lowercaseStringWith(_ locale: Locale?) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "maximumLengthOfBytes(using:)")
    public
    func maximumLengthOfBytesUsingEncoding(_ encoding: String.Encoding) -> Int {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "paragraphRange(for:)")
    public func paragraphRangeFor(_ aRange: Range<Index>) -> Range<Index> {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "rangeOfCharacter(from:options:range:)")
    public func rangeOfCharacterFrom(
        _ aSet: CharacterSet,
        options mask: String.CompareOptions = [],
        range aRange: Range<Index>? = nil
        ) -> Range<Index>? {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "rangeOfComposedCharacterSequence(at:)")
    public
    func rangeOfComposedCharacterSequenceAt(_ anIndex: Index) -> Range<Index> {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "rangeOfComposedCharacterSequences(for:)")
    public func rangeOfComposedCharacterSequencesFor(
        _ range: Range<Index>
        ) -> Range<Index> {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "range(of:options:range:locale:)")
    public func rangeOf(
        _ aString: String,
        options mask: String.CompareOptions = [],
        range searchRange: Range<Index>? = nil,
        locale: Locale? = nil
        ) -> Range<Index>? {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "localizedStandardRange(of:)")
    public func localizedStandardRangeOf(_ string: String) -> Range<Index>? {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "addingPercentEncoding(withAllowedCharacters:)")
    public func addingPercentEncodingWithAllowedCharacters(
        _ allowedCharacters: CharacterSet
        ) -> String? {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "addingPercentEscapes(using:)")
    public func addingPercentEscapesUsingEncoding(
        _ encoding: String.Encoding
        ) -> String? {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "appendingFormat")
    public func stringByAppendingFormat(
        _ format: String, _ arguments: CVarArg...
        ) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "padding(toLength:with:startingAt:)")
    public func byPaddingToLength(
        _ newLength: Int, withString padString: String, startingAt padIndex: Int
        ) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "replacingCharacters(in:with:)")
    public func replacingCharactersIn(
        _ range: Range<Index>, withString replacement: String
        ) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "replacingOccurrences(of:with:options:range:)")
    public func replacingOccurrencesOf(
        _ target: String,
        withString replacement: String,
        options: String.CompareOptions = [],
        range searchRange: Range<Index>? = nil
        ) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "replacingPercentEscapes(usingEncoding:)")
    public func replacingPercentEscapesUsingEncoding(
        _ encoding: String.Encoding
        ) -> String? {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "trimmingCharacters(in:)")
    public func byTrimmingCharactersIn(_ set: CharacterSet) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "strings(byAppendingPaths:)")
    public func stringsByAppendingPaths(_ paths: [String]) -> [String] {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "substring(from:)")
    public func substringFrom(_ index: Index) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "substring(to:)")
    public func substringTo(_ index: Index) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "substring(with:)")
    public func substringWith(_ aRange: Range<Index>) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "uppercased(with:)")
    public func uppercaseStringWith(_ locale: Locale?) -> String {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "write(toFile:atomically:encoding:)")
    public func writeToFile(
        _ path: String, atomically useAuxiliaryFile:Bool,
        encoding enc: String.Encoding
        ) throws {
        fatalError("unavailable function can't be called")
    }

    @available(*, unavailable, renamed: "write(to:atomically:encoding:)")
    public func writeToURL(
        _ url: URL, atomically useAuxiliaryFile: Bool,
        encoding enc: String.Encoding
        ) throws {
        fatalError("unavailable function can't be called")
    }
}
