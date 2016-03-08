// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2015 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//



import CoreFoundation

public class NSScanner : NSObject, NSCopying {
    internal var _scanString: String
    internal var _skipSet: NSCharacterSet?
    internal var _invertedSkipSet: NSCharacterSet?
    internal var _scanLocation: Int
    
    public override func copy() -> AnyObject {
        return copyWithZone(nil)
    }
    
    public func copyWithZone(zone: NSZone) -> AnyObject {
        return NSScanner(string: string)
    }
    
    public var string: String {
        return _scanString
    }
    
    public var scanLocation: Int {
        get {
            return _scanLocation
        }
        set {
            if newValue > string.length {
                fatalError("Index \(newValue) beyond bounds; string length \(string.length)")
            }
            _scanLocation = newValue
        }
    }
    /*@NSCopying*/ public var charactersToBeSkipped: NSCharacterSet? {
        get {
            return _skipSet
        }
        set {
            _skipSet = newValue?.copy() as? NSCharacterSet
            _invertedSkipSet = nil
        }
    }
    
    internal var invertedSkipSet: NSCharacterSet? {
        if let inverted = _invertedSkipSet {
            return inverted
        } else {
            if let set = charactersToBeSkipped {
                _invertedSkipSet = set.invertedSet
                return _invertedSkipSet
            }
            return nil
        }
    }
    
    public var caseSensitive: Bool = false
    public var locale: NSLocale?
    
    internal static let defaultSkipSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
    
    public init(string: String) {
        _scanString = string
        _skipSet = NSScanner.defaultSkipSet
        _scanLocation = 0
    }
}

internal struct _NSStringBuffer {
    var bufferLen: Int
    var bufferLoc: Int
    var string: NSString
    var stringLen: Int
    var _stringLoc: Int
    var buffer = Array<unichar>(count: 32, repeatedValue: 0)
    var curChar: unichar?
    
    static let EndCharacter = unichar(0xffff)
    
    init(string: String, start: Int, end: Int) {
        self.string = string._bridgeToObject()
        _stringLoc = start
        stringLen = end
    
        if _stringLoc < stringLen {
            bufferLen = min(32, stringLen - _stringLoc);
            let range = NSMakeRange(_stringLoc, bufferLen)
            bufferLoc = 1
            buffer.withUnsafeMutableBufferPointer({ (inout ptr: UnsafeMutableBufferPointer<unichar>) -> Void in
                self.string.getCharacters(ptr.baseAddress, range: range)
            })
            curChar = buffer[0]
        } else {
            bufferLen = 0
            bufferLoc = 1
            curChar = _NSStringBuffer.EndCharacter
        }
    }
    
    init(string: NSString, start: Int, end: Int) {
        self.string = string
        _stringLoc = start
        stringLen = end
        
        if _stringLoc < stringLen {
            bufferLen = min(32, stringLen - _stringLoc);
            let range = NSMakeRange(_stringLoc, bufferLen)
            bufferLoc = 1
            buffer.withUnsafeMutableBufferPointer({ (inout ptr: UnsafeMutableBufferPointer<unichar>) -> Void in
                self.string.getCharacters(ptr.baseAddress, range: range)
            })
            curChar = buffer[0]
        } else {
            bufferLen = 0
            bufferLoc = 1
            curChar = _NSStringBuffer.EndCharacter
        }
    }
    
    var currentCharacter: unichar {
        return curChar!
    }
    
    var isAtEnd: Bool {
        return curChar == _NSStringBuffer.EndCharacter
    }
    
    mutating func fill() {
        bufferLen = min(32, stringLen - _stringLoc);
        let range = NSMakeRange(_stringLoc, bufferLen)
        buffer.withUnsafeMutableBufferPointer({ (inout ptr: UnsafeMutableBufferPointer<unichar>) -> Void in
            string.getCharacters(ptr.baseAddress, range: range)
        })
        bufferLoc = 1
        curChar = buffer[0]
    }
    
    mutating func advance() {
        if bufferLoc < bufferLen { /*buffer is OK*/
            curChar = buffer[bufferLoc]
            bufferLoc += 1
        } else if (_stringLoc + bufferLen < stringLen) { /* Buffer is empty but can be filled */
            _stringLoc += bufferLen
            fill()
        } else { /* Buffer is empty and we're at the end */
            bufferLoc = bufferLen + 1
            curChar = _NSStringBuffer.EndCharacter
        }
    }
    
    mutating func rewind() {
        if bufferLoc > 1 { /* Buffer is OK */
            bufferLoc -= 1
            curChar = buffer[bufferLoc - 1]
        } else if _stringLoc > 0 { /* Buffer is empty but can be filled */
            bufferLoc = min(32, _stringLoc)
            bufferLen = bufferLoc
            _stringLoc -= bufferLen
            let range = NSMakeRange(_stringLoc, bufferLen)
            buffer.withUnsafeMutableBufferPointer({ (inout ptr: UnsafeMutableBufferPointer<unichar>) -> Void in
                string.getCharacters(ptr.baseAddress, range: range)
            })
        } else {
            bufferLoc = 0
            curChar = _NSStringBuffer.EndCharacter
        }
    }
    
    mutating func skip(skipSet: NSCharacterSet?) {
        if let set = skipSet {
            while set.characterIsMember(currentCharacter) && !isAtEnd {
                advance()
            }
        }
    }
    
    var location: Int {
        get {
            return _stringLoc + bufferLoc - 1
        }
        mutating set {
            if newValue < _stringLoc || newValue >= _stringLoc + bufferLen {
                if newValue < 16 { /* Get the first NSStringBufferSize chars */
                    _stringLoc = 0
                } else if newValue > stringLen - 16 { /* Get the last NSStringBufferSize chars */
                    _stringLoc = stringLen < 32 ? 0 : stringLen - 32
                } else {
                    _stringLoc = newValue - 16 /* Center around loc */
                }
                fill()
            }
            bufferLoc = newValue - _stringLoc
            curChar = buffer[bufferLoc]
            bufferLoc += 1
        }
    }
}

private func isADigit(ch: unichar) -> Bool {
    struct Local {
        static let set = NSCharacterSet.decimalDigitCharacterSet()
    }
    return Local.set.characterIsMember(ch)
}

// This is just here to allow just enough generic math to handle what is needed for scanning an abstract integer from a string, perhaps these should be on IntegerType?

internal protocol _BitShiftable {
    func >>(lhs: Self, rhs: Self) -> Self
    func <<(lhs: Self, rhs: Self) -> Self
}

internal protocol _IntegerLike : IntegerType, _BitShiftable {
    init(_ value: Int)
    static var max: Self { get }
    static var min: Self { get }
}

internal protocol _FloatArithmeticType {
    func +(lhs: Self, rhs: Self) -> Self
    func -(lhs: Self, rhs: Self) -> Self
    func *(lhs: Self, rhs: Self) -> Self
    func /(lhs: Self, rhs: Self) -> Self
}

internal protocol _FloatLike : FloatingPointType, _FloatArithmeticType {
    init(_ value: Int)
    init(_ value: Double)
    static var max: Self { get }
    static var min: Self { get }
}

extension Int : _IntegerLike { }
extension Int32 : _IntegerLike { }
extension Int64 : _IntegerLike { }
extension UInt32 : _IntegerLike { }
extension UInt64 : _IntegerLike { }

// these might be good to have in the stdlib
extension Float : _FloatLike {
    static var max: Float { return FLT_MAX }
    static var min: Float { return FLT_MIN }
}

extension Double : _FloatLike {
    static var max: Double { return DBL_MAX }
    static var min: Double { return DBL_MIN }
}

private func numericValue(ch: unichar) -> Int {
    if (ch >= unichar(unicodeScalarLiteral: "0") && ch <= unichar(unicodeScalarLiteral: "9")) {
        return Int(ch) - Int(unichar(unicodeScalarLiteral: "0"))
    } else {
        return __CFCharDigitValue(UniChar(ch))
    }
}

private func numericOrHexValue(ch: unichar) -> Int {
    if (ch >= unichar(unicodeScalarLiteral: "0") && ch <= unichar(unicodeScalarLiteral: "9")) {
        return Int(ch) - Int(unichar(unicodeScalarLiteral: "0"))
    } else if (ch >= unichar(unicodeScalarLiteral: "A") && ch <= unichar(unicodeScalarLiteral: "F")) {
        return Int(ch) + 10 - Int(unichar(unicodeScalarLiteral: "A"))
    } else if (ch >= unichar(unicodeScalarLiteral: "a") && ch <= unichar(unicodeScalarLiteral: "f")) {
        return Int(ch) + 10 - Int(unichar(unicodeScalarLiteral: "a"))
    } else {
        return -1;
    }
}

private func decimalSep(locale: NSLocale?) -> String {
    if let loc = locale {
        if let sep = loc.objectForKey(NSLocaleDecimalSeparator) as? NSString {
            return sep._swiftObject
        }
        return "."
    } else {
        return decimalSep(NSLocale.currentLocale())
    }
}

extension String {
    internal func scan<T: _IntegerLike>(skipSet: NSCharacterSet?, inout locationToScanFrom: Int, to: (T) -> Void) -> Bool {
        var buf = _NSStringBuffer(string: self, start: locationToScanFrom, end: length)
        buf.skip(skipSet)
        var neg = false
        var localResult: T = 0
        if buf.currentCharacter == unichar(unicodeScalarLiteral: "-") || buf.currentCharacter == unichar(unicodeScalarLiteral: "+") {
           neg = buf.currentCharacter == unichar(unicodeScalarLiteral: "-")
            buf.advance()
            buf.skip(skipSet)
        }
        if (!isADigit(buf.currentCharacter)) {
            return false
        }
        repeat {
            let numeral = numericValue(buf.currentCharacter)
            if numeral == -1 {
                break
            }
            if (localResult >= T.max / 10) && ((localResult > T.max / 10) || T(numeral - (neg ? 1 : 0)) >= T.max - localResult * 10) {
                // apply the clamps and advance past the ending of the buffer where there are still digits
                localResult = neg ? T.min : T.max
                neg = false
                repeat {
                    buf.advance()
                } while (isADigit(buf.currentCharacter))
                break
            } else {
                // normal case for scanning
                localResult = localResult * 10 + T(numeral)
            }
            buf.advance()
        } while (isADigit(buf.currentCharacter))
        to(neg ? -1 * localResult : localResult)
        locationToScanFrom = buf.location
        return true
    }
    
    internal func scanHex<T: _IntegerLike>(skipSet: NSCharacterSet?, inout locationToScanFrom: Int, to: (T) -> Void) -> Bool {
        var buf = _NSStringBuffer(string: self, start: locationToScanFrom, end: length)
        buf.skip(skipSet)
        var localResult: T = 0
        var curDigit: Int
        if buf.currentCharacter == unichar(unicodeScalarLiteral: "0") {
            buf.advance()
            let locRewindTo = buf.location
            curDigit = numericOrHexValue(buf.currentCharacter)
            if curDigit == -1 {
                if buf.currentCharacter == unichar(unicodeScalarLiteral: "x") || buf.currentCharacter == unichar(unicodeScalarLiteral: "X") {
                    buf.advance()
                    curDigit = numericOrHexValue(buf.currentCharacter)
                }
            }
            if curDigit == -1 {
                locationToScanFrom = locRewindTo
                to(T(0))
                return true
            }
        } else {
            curDigit = numericOrHexValue(buf.currentCharacter)
            if curDigit == -1 {
                return false
            }
        }
        
        repeat {
            if localResult > T.max >> T(4) {
                localResult = T.max
            } else {
                localResult = (localResult << T(4)) + T(curDigit)
            }
            buf.advance()
            curDigit = numericOrHexValue(buf.currentCharacter)
        } while (curDigit != -1)
        
        to(localResult)
        locationToScanFrom = buf.location
        return true
    }
    
    internal func scan<T: _FloatLike>(skipSet: NSCharacterSet?, locale: NSLocale?, inout locationToScanFrom: Int, to: (T) -> Void) -> Bool {
        let ds_chars = decimalSep(locale).utf16
        let ds = ds_chars[ds_chars.startIndex]
        var buf = _NSStringBuffer(string: self, start: locationToScanFrom, end: length)
        buf.skip(skipSet)
        var neg = false
        var localResult: T = T(0)
        
        if buf.currentCharacter == unichar(unicodeScalarLiteral: "-") || buf.currentCharacter == unichar(unicodeScalarLiteral: "+") {
            neg = buf.currentCharacter == unichar(unicodeScalarLiteral: "-")
            buf.advance()
            buf.skip(skipSet)
        }
        if (!isADigit(buf.currentCharacter)) {
            return false
        }
        
        repeat {
            let numeral = numericValue(buf.currentCharacter)
            if numeral == -1 {
                break
            }
            // if (localResult >= T.max / T(10)) && ((localResult > T.max / T(10)) || T(numericValue(buf.currentCharacter) - (neg ? 1 : 0)) >= T.max - localResult * T(10))  is evidently too complex; so break it down to more "edible chunks"
            let limit1 = localResult >= T.max / T(10)
            let limit2 = localResult > T.max / T(10)
            let limit3 = T(numeral - (neg ? 1 : 0)) >= T.max - localResult * T(10)
            if (limit1) && (limit2 || limit3) {
                // apply the clamps and advance past the ending of the buffer where there are still digits
                localResult = neg ? T.min : T.max
                neg = false
                repeat {
                    buf.advance()
                } while (isADigit(buf.currentCharacter))
                break
            } else {
                localResult = localResult * T(10) + T(numeral)
            }
            buf.advance()
        } while (isADigit(buf.currentCharacter))
        
        if buf.currentCharacter == ds {
            var factor = T(0.1)
            buf.advance()
            repeat {
                let numeral = numericValue(buf.currentCharacter)
                if numeral == -1 {
                    break
                }
                localResult = localResult + T(numeral) * factor
                factor = factor * T(0.1)
                buf.advance()
            } while (isADigit(buf.currentCharacter))
        }
        
        to(neg ? T(-1) * localResult : localResult)
        locationToScanFrom = buf.location
        return true
    }
    
    internal func scanHex<T: _FloatLike>(skipSet: NSCharacterSet?, locale: NSLocale?, inout locationToScanFrom: Int, to: (T) -> Void) -> Bool {
        NSUnimplemented()
    }
}

extension NSScanner {
    
    // On overflow, the below methods will return success and clamp
    public func scanInt(result: UnsafeMutablePointer<Int32>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: Int32) -> Void in
            result.memory = value
        }
    }
    
    public func scanInteger(result: UnsafeMutablePointer<Int>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: Int) -> Void in
            result.memory = value
        }
    }
    
    public func scanLongLong(result: UnsafeMutablePointer<Int64>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: Int64) -> Void in
            result.memory = value
        }
    }
    
    public func scanUnsignedLongLong(result: UnsafeMutablePointer<UInt64>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: UInt64) -> Void in
            result.memory = value
        }
    }
    
    public func scanFloat(result: UnsafeMutablePointer<Float>) -> Bool {
        return _scanString.scan(_skipSet, locale: locale, locationToScanFrom: &_scanLocation) { (value: Float) -> Void in
            result.memory = value
        }
    }
    
    public func scanDouble(result: UnsafeMutablePointer<Double>) -> Bool {
        return _scanString.scan(_skipSet, locale: locale, locationToScanFrom: &_scanLocation) { (value: Double) -> Void in
            result.memory = value
        }
    }
    
    public func scanHexInt(result: UnsafeMutablePointer<UInt32>) -> Bool {
        return _scanString.scanHex(_skipSet, locationToScanFrom: &_scanLocation) { (value: UInt32) -> Void in
            result.memory = value
        }
    }
    
    public func scanHexLongLong(result: UnsafeMutablePointer<UInt64>) -> Bool {
        return _scanString.scanHex(_skipSet, locationToScanFrom: &_scanLocation) { (value: UInt64) -> Void in
            result.memory = value
        }
    }
    
    public func scanHexFloat(result: UnsafeMutablePointer<Float>) -> Bool {
        return _scanString.scanHex(_skipSet, locale: locale, locationToScanFrom: &_scanLocation) { (value: Float) -> Void in
            result.memory = value
        }
    }
    
    public func scanHexDouble(result: UnsafeMutablePointer<Double>) -> Bool {
        return _scanString.scanHex(_skipSet, locale: locale, locationToScanFrom: &_scanLocation) { (value: Double) -> Void in
            result.memory = value
        }
    }
    
    public var atEnd: Bool {
        var stringLoc = scanLocation
        let stringLen = string.length
        if let invSet = invertedSkipSet {
            let range = string._nsObject.rangeOfCharacterFromSet(invSet, options: [], range: NSMakeRange(stringLoc, stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        return stringLoc == stringLen
    }
    
    public class func localizedScannerWithString(string: String) -> AnyObject { NSUnimplemented() }
}


/// Revised API for avoiding usage of AutoreleasingUnsafeMutablePointer and better Optional usage.
/// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
/// - Note: Since this API is under consideration it may be either removed or revised in the near future
extension NSScanner {
    public func scanInt() -> Int32? {
        var value: Int32 = 0
        return withUnsafeMutablePointer(&value) { (ptr: UnsafeMutablePointer<Int32>) -> Int32? in
            if scanInt(ptr) {
                return ptr.memory
            } else {
                return nil
            }
        }
    }
    
    public func scanInteger() -> Int? {
        var value: Int = 0
        return withUnsafeMutablePointer(&value) { (ptr: UnsafeMutablePointer<Int>) -> Int? in
            if scanInteger(ptr) {
                return ptr.memory
            } else {
                return nil
            }
        }
    }
    
    public func scanLongLong() -> Int64? {
        var value: Int64 = 0
        return withUnsafeMutablePointer(&value) { (ptr: UnsafeMutablePointer<Int64>) -> Int64? in
            if scanLongLong(ptr) {
                return ptr.memory
            } else {
                return nil
            }
        }
    }
    
    public func scanUnsignedLongLong() -> UInt64? {
        var value: UInt64 = 0
        return withUnsafeMutablePointer(&value) { (ptr: UnsafeMutablePointer<UInt64>) -> UInt64? in
            if scanUnsignedLongLong(ptr) {
                return ptr.memory
            } else {
                return nil
            }
        }
    }
    
    public func scanFloat() -> Float? {
        var value: Float = 0.0
        return withUnsafeMutablePointer(&value) { (ptr: UnsafeMutablePointer<Float>) -> Float? in
            if scanFloat(ptr) {
                return ptr.memory
            } else {
                return nil
            }
        }
    }
    
    public func scanDouble() -> Double? {
        var value: Double = 0.0
        return withUnsafeMutablePointer(&value) { (ptr: UnsafeMutablePointer<Double>) -> Double? in
            if scanDouble(ptr) {
                return ptr.memory
            } else {
                return nil
            }
        }
    }
    
    public func scanHexInt() -> UInt32? {
        var value: UInt32 = 0
        return withUnsafeMutablePointer(&value) { (ptr: UnsafeMutablePointer<UInt32>) -> UInt32? in
            if scanHexInt(ptr) {
                return ptr.memory
            } else {
                return nil
            }
        }
    }
    
    public func scanHexLongLong() -> UInt64? {
        var value: UInt64 = 0
        return withUnsafeMutablePointer(&value) { (ptr: UnsafeMutablePointer<UInt64>) -> UInt64? in
            if scanHexLongLong(ptr) {
                return ptr.memory
            } else {
                return nil
            }
        }
    }
    
    public func scanHexFloat() -> Float? {
        var value: Float = 0.0
        return withUnsafeMutablePointer(&value) { (ptr: UnsafeMutablePointer<Float>) -> Float? in
            if scanHexFloat(ptr) {
                return ptr.memory
            } else {
                return nil
            }
        }
    }
    
    public func scanHexDouble() -> Double? {
        var value: Double = 0.0
        return withUnsafeMutablePointer(&value) { (ptr: UnsafeMutablePointer<Double>) -> Double? in
            if scanHexDouble(ptr) {
                return ptr.memory
            } else {
                return nil
            }
        }
    }
    
    // These methods avoid calling the private API for _invertedSkipSet and manually re-construct them so that it is only usage of public API usage
    // Future implementations on Darwin of these methods will likely be more optimized to take advantage of the cached values.
    public func scanString(string searchString: String) -> String? {
        let str = self.string._bridgeToObject()
        var stringLoc = scanLocation
        let stringLen = str.length
        let options: NSStringCompareOptions = [caseSensitive ? [] : NSStringCompareOptions.CaseInsensitiveSearch, NSStringCompareOptions.AnchoredSearch]
        
        if let invSkipSet = charactersToBeSkipped?.invertedSet {
            let range = str.rangeOfCharacterFromSet(invSkipSet, options: [], range: NSMakeRange(stringLoc, stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        
        let range = str.rangeOfString(searchString, options: options, range: NSMakeRange(stringLoc, stringLen - stringLoc))
        if range.length > 0 {
            /* ??? Is the range below simply range? 99.9% of the time, and perhaps even 100% of the time... Hmm... */
            let res = str.substringWithRange(NSMakeRange(stringLoc, range.location + range.length - stringLoc))
            scanLocation = range.location + range.length
            return res
        }
        return nil
    }
    
    public func scanCharactersFromSet(set: NSCharacterSet) -> String? {
        let str = self.string._bridgeToObject()
        var stringLoc = scanLocation
        let stringLen = str.length
        let options: NSStringCompareOptions = caseSensitive ? [] : NSStringCompareOptions.CaseInsensitiveSearch
        if let invSkipSet = charactersToBeSkipped?.invertedSet {
            let range = str.rangeOfCharacterFromSet(invSkipSet, options: [], range: NSMakeRange(stringLoc, stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        var range = str.rangeOfCharacterFromSet(set.invertedSet, options: options, range: NSMakeRange(stringLoc, stringLen - stringLoc))
        if range.length == 0 {
            range.location = stringLen
        }
        if stringLoc != range.location {
            let res = str.substringWithRange(NSMakeRange(stringLoc, range.location - stringLoc))
            scanLocation = range.location
            return res
        }
        return nil
    }
    
    public func scanUpToString(string: String) -> String? {
        let str = self.string._bridgeToObject()
        var stringLoc = scanLocation
        let stringLen = str.length
        let options: NSStringCompareOptions = caseSensitive ? [] : NSStringCompareOptions.CaseInsensitiveSearch
        if let invSkipSet = charactersToBeSkipped?.invertedSet {
            let range = str.rangeOfCharacterFromSet(invSkipSet, options: [], range: NSMakeRange(stringLoc, stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        var range = str.rangeOfString(string, options: options, range: NSMakeRange(stringLoc, stringLen - stringLoc))
        if range.length == 0 {
            range.location = stringLen
        }
        if stringLoc != range.location {
            let res = str.substringWithRange(NSMakeRange(stringLoc, range.location - stringLoc))
            scanLocation = range.location
            return res
        }
        return nil
    }
    
    public func scanUpToCharactersFromSet(set: NSCharacterSet) -> String? {
        let str = self.string._bridgeToObject()
        var stringLoc = scanLocation
        let stringLen = str.length
        let options: NSStringCompareOptions = caseSensitive ? [] : NSStringCompareOptions.CaseInsensitiveSearch
        if let invSkipSet = charactersToBeSkipped?.invertedSet {
            let range = str.rangeOfCharacterFromSet(invSkipSet, options: [], range: NSMakeRange(stringLoc, stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        var range = str.rangeOfCharacterFromSet(set, options: options, range: NSMakeRange(stringLoc, stringLen - stringLoc))
        if range.length == 0 {
            range.location = stringLen
        }
        if stringLoc != range.location {
            let res = str.substringWithRange(NSMakeRange(stringLoc, range.location - stringLoc))
            scanLocation = range.location
            return res
        }
        return nil
    }
}

