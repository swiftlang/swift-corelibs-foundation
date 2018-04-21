// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//



import CoreFoundation

open class Scanner: NSObject, NSCopying {
    internal var _scanString: String
    internal var _skipSet: CharacterSet?
    internal var _invertedSkipSet: CharacterSet?
    internal var _scanLocation: Int
    
    open override func copy() -> Any {
        return copy(with: nil)
    }
    
    open func copy(with zone: NSZone? = nil) -> Any {
        return Scanner(string: string)
    }
    
    open var string: String {
        return _scanString
    }
    
    open var scanLocation: Int {
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
    /*@NSCopying*/ open var charactersToBeSkipped: CharacterSet? {
        get {
            return _skipSet
        }
        set {
            _skipSet = newValue
            _invertedSkipSet = nil
        }
    }
    
    internal var invertedSkipSet: CharacterSet? {
        if let inverted = _invertedSkipSet {
            return inverted
        } else {
            if let set = charactersToBeSkipped {
                _invertedSkipSet = set.inverted
                return _invertedSkipSet
            }
            return nil
        }
    }
    
    open var caseSensitive: Bool = false
    open var locale: Locale?
    
    internal static let defaultSkipSet = CharacterSet.whitespacesAndNewlines
    
    public init(string: String) {
        _scanString = string
        _skipSet = Scanner.defaultSkipSet
        _scanLocation = 0
    }
}

internal struct _NSStringBuffer {
    var bufferLen: Int
    var bufferLoc: Int
    var string: NSString
    var stringLen: Int
    var _stringLoc: Int
    var buffer = Array<unichar>(repeating: 0, count: 32)
    var curChar: unichar?
    
    static let EndCharacter = unichar(0xffff)
    
    init(string: String, start: Int, end: Int) {
        self.string = string._bridgeToObjectiveC()
        _stringLoc = start
        stringLen = end
    
        if _stringLoc < stringLen {
            bufferLen = min(32, stringLen - _stringLoc)
            let range = NSRange(location: _stringLoc, length: bufferLen)
            bufferLoc = 1
            buffer.withUnsafeMutableBufferPointer({ (ptr: inout UnsafeMutableBufferPointer<unichar>) -> Void in
                self.string.getCharacters(ptr.baseAddress!, range: range)
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
            bufferLen = min(32, stringLen - _stringLoc)
            let range = NSRange(location: _stringLoc, length: bufferLen)
            bufferLoc = 1
            buffer.withUnsafeMutableBufferPointer({ (ptr: inout UnsafeMutableBufferPointer<unichar>) -> Void in
                self.string.getCharacters(ptr.baseAddress!, range: range)
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
        bufferLen = min(32, stringLen - _stringLoc)
        let range = NSRange(location: _stringLoc, length: bufferLen)
        buffer.withUnsafeMutableBufferPointer({ (ptr: inout UnsafeMutableBufferPointer<unichar>) -> Void in
            string.getCharacters(ptr.baseAddress!, range: range)
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
            let range = NSRange(location: _stringLoc, length: bufferLen)
            buffer.withUnsafeMutableBufferPointer({ (ptr: inout UnsafeMutableBufferPointer<unichar>) -> Void in
                string.getCharacters(ptr.baseAddress!, range: range)
            })
            curChar = buffer[bufferLoc - 1]
        } else {
            bufferLoc = 0
            curChar = _NSStringBuffer.EndCharacter
        }
    }
    
    mutating func skip(_ skipSet: CharacterSet?) {
        if let set = skipSet {
            while set.contains(UnicodeScalar(currentCharacter)!) && !isAtEnd {
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

private func isADigit(_ ch: unichar) -> Bool {
    struct Local {
        static let set = CharacterSet.decimalDigits
    }
    return Local.set.contains(UnicodeScalar(ch)!)
}


private func numericValue(_ ch: unichar) -> Int {
    if (ch >= unichar(unicodeScalarLiteral: "0") && ch <= unichar(unicodeScalarLiteral: "9")) {
        return Int(ch) - Int(unichar(unicodeScalarLiteral: "0"))
    } else {
        return __CFCharDigitValue(UniChar(ch))
    }
}

private func numericOrHexValue(_ ch: unichar) -> Int {
    if (ch >= unichar(unicodeScalarLiteral: "0") && ch <= unichar(unicodeScalarLiteral: "9")) {
        return Int(ch) - Int(unichar(unicodeScalarLiteral: "0"))
    } else if (ch >= unichar(unicodeScalarLiteral: "A") && ch <= unichar(unicodeScalarLiteral: "F")) {
        return Int(ch) + 10 - Int(unichar(unicodeScalarLiteral: "A"))
    } else if (ch >= unichar(unicodeScalarLiteral: "a") && ch <= unichar(unicodeScalarLiteral: "f")) {
        return Int(ch) + 10 - Int(unichar(unicodeScalarLiteral: "a"))
    } else {
        return -1
    }
}

private func decimalSep(_ locale: Locale?) -> String {
    if let loc = locale {
        if let sep = loc._bridgeToObjectiveC().object(forKey: .decimalSeparator) as? NSString {
            return sep._swiftObject
        }
        return "."
    } else {
        return decimalSep(Locale.current)
    }
}

extension String {
    internal func scan<T: FixedWidthInteger>(_ skipSet: CharacterSet?, locationToScanFrom: inout Int, to: (T) -> Void) -> Bool {
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
    
    internal func scanHex<T: FixedWidthInteger>(_ skipSet: CharacterSet?, locationToScanFrom: inout Int, to: (T) -> Void) -> Bool {
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
    
    internal func scan<T: BinaryFloatingPoint>(_ skipSet: CharacterSet?, locale: Locale?, locationToScanFrom: inout Int, to: (T) -> Void) -> Bool {
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
            // if (localResult >= T.greatestFiniteMagnitude / T(10)) && ((localResult > T.greatestFiniteMagnitude / T(10)) || T(numericValue(buf.currentCharacter) - (neg ? 1 : 0)) >= T.greatestFiniteMagnitude - localResult * T(10))  is evidently too complex; so break it down to more "edible chunks"
            let limit1 = localResult >= T.greatestFiniteMagnitude / T(10)
            let limit2 = localResult > T.greatestFiniteMagnitude / T(10)
            let limit3 = T(numeral - (neg ? 1 : 0)) >= T.greatestFiniteMagnitude - localResult * T(10)
            if (limit1) && (limit2 || limit3) {
                // apply the clamps and advance past the ending of the buffer where there are still digits
                localResult = neg ? -T.infinity : T.infinity
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
    
    internal func scanHex<T: BinaryFloatingPoint>(_ skipSet: CharacterSet?, locale: Locale?, locationToScanFrom: inout Int, to: (T) -> Void) -> Bool {
        NSUnimplemented()
    }
}

extension Scanner {
    
    // On overflow, the below methods will return success and clamp
    public func scanInt32(_ result: UnsafeMutablePointer<Int32>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: Int32) -> Void in
            result.pointee = value
        }
    }
    
    public func scanInt(_ result: UnsafeMutablePointer<Int>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: Int) -> Void in
            result.pointee = value
        }
    }
    
    public func scanInt64(_ result: UnsafeMutablePointer<Int64>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: Int64) -> Void in
            result.pointee = value
        }
    }
    
    public func scanUnsignedLongLong(_ result: UnsafeMutablePointer<UInt64>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: UInt64) -> Void in
            result.pointee = value
        }
    }
    
    public func scanFloat(_ result: UnsafeMutablePointer<Float>) -> Bool {
        return _scanString.scan(_skipSet, locale: locale, locationToScanFrom: &_scanLocation) { (value: Float) -> Void in
            result.pointee = value
        }
    }
    
    public func scanDouble(_ result: UnsafeMutablePointer<Double>) -> Bool {
        return _scanString.scan(_skipSet, locale: locale, locationToScanFrom: &_scanLocation) { (value: Double) -> Void in
            result.pointee = value
        }
    }
    
    public func scanHexInt32(_ result: UnsafeMutablePointer<UInt32>) -> Bool {
        return _scanString.scanHex(_skipSet, locationToScanFrom: &_scanLocation) { (value: UInt32) -> Void in
            result.pointee = value
        }
    }
    
    public func scanHexInt64(_ result: UnsafeMutablePointer<UInt64>) -> Bool {
        return _scanString.scanHex(_skipSet, locationToScanFrom: &_scanLocation) { (value: UInt64) -> Void in
            result.pointee = value
        }
    }
    
    public func scanHexFloat(_ result: UnsafeMutablePointer<Float>) -> Bool {
        return _scanString.scanHex(_skipSet, locale: locale, locationToScanFrom: &_scanLocation) { (value: Float) -> Void in
            result.pointee = value
        }
    }
    
    public func scanHexDouble(_ result: UnsafeMutablePointer<Double>) -> Bool {
        return _scanString.scanHex(_skipSet, locale: locale, locationToScanFrom: &_scanLocation) { (value: Double) -> Void in
            result.pointee = value
        }
    }
    
    public var isAtEnd: Bool {
        var stringLoc = scanLocation
        let stringLen = string.length
        if let invSet = invertedSkipSet {
            let range = string._nsObject.rangeOfCharacter(from: invSet, options: [], range: NSRange(location: stringLoc, length: stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        return stringLoc == stringLen
    }
    
    open class func localizedScannerWithString(_ string: String) -> AnyObject { NSUnimplemented() }
}


/// Revised API for avoiding usage of AutoreleasingUnsafeMutablePointer and better Optional usage.
/// - Experiment: This is a draft API currently under consideration for official import into Foundation as a suitable alternative
/// - Note: Since this API is under consideration it may be either removed or revised in the near future
extension Scanner {
    public func scanInt32() -> Int32? {
        var value: Int32 = 0
        return withUnsafeMutablePointer(to: &value) { (ptr: UnsafeMutablePointer<Int32>) -> Int32? in
            if scanInt32(ptr) {
                return ptr.pointee
            } else {
                return nil
            }
        }
    }
    
    public func scanInt() -> Int? {
        var value: Int = 0
        return withUnsafeMutablePointer(to: &value) { (ptr: UnsafeMutablePointer<Int>) -> Int? in
            if scanInt(ptr) {
                return ptr.pointee
            } else {
                return nil
            }
        }
    }
    
    public func scanInt64() -> Int64? {
        var value: Int64 = 0
        return withUnsafeMutablePointer(to: &value) { (ptr: UnsafeMutablePointer<Int64>) -> Int64? in
            if scanInt64(ptr) {
                return ptr.pointee
            } else {
                return nil
            }
        }
    }
    
    public func scanUnsignedLongLong() -> UInt64? {
        var value: UInt64 = 0
        return withUnsafeMutablePointer(to: &value) { (ptr: UnsafeMutablePointer<UInt64>) -> UInt64? in
            if scanUnsignedLongLong(ptr) {
                return ptr.pointee
            } else {
                return nil
            }
        }
    }
    
    public func scanFloat() -> Float? {
        var value: Float = 0.0
        return withUnsafeMutablePointer(to: &value) { (ptr: UnsafeMutablePointer<Float>) -> Float? in
            if scanFloat(ptr) {
                return ptr.pointee
            } else {
                return nil
            }
        }
    }
    
    public func scanDouble() -> Double? {
        var value: Double = 0.0
        return withUnsafeMutablePointer(to: &value) { (ptr: UnsafeMutablePointer<Double>) -> Double? in
            if scanDouble(ptr) {
                return ptr.pointee
            } else {
                return nil
            }
        }
    }
    
    public func scanHexInt32() -> UInt32? {
        var value: UInt32 = 0
        return withUnsafeMutablePointer(to: &value) { (ptr: UnsafeMutablePointer<UInt32>) -> UInt32? in
            if scanHexInt32(ptr) {
                return ptr.pointee
            } else {
                return nil
            }
        }
    }
    
    public func scanHexInt64() -> UInt64? {
        var value: UInt64 = 0
        return withUnsafeMutablePointer(to: &value) { (ptr: UnsafeMutablePointer<UInt64>) -> UInt64? in
            if scanHexInt64(ptr) {
                return ptr.pointee
            } else {
                return nil
            }
        }
    }
    
    public func scanHexFloat() -> Float? {
        var value: Float = 0.0
        return withUnsafeMutablePointer(to: &value) { (ptr: UnsafeMutablePointer<Float>) -> Float? in
            if scanHexFloat(ptr) {
                return ptr.pointee
            } else {
                return nil
            }
        }
    }
    
    public func scanHexDouble() -> Double? {
        var value: Double = 0.0
        return withUnsafeMutablePointer(to: &value) { (ptr: UnsafeMutablePointer<Double>) -> Double? in
            if scanHexDouble(ptr) {
                return ptr.pointee
            } else {
                return nil
            }
        }
    }
    
    public func scanString(_ string:String, into ptr: UnsafeMutablePointer<String?>?) -> Bool {
        if let str = scanString(string) {
            ptr?.pointee = str
            return true
        }
        return false
    }
    
    // These methods avoid calling the private API for _invertedSkipSet and manually re-construct them so that it is only usage of public API usage
    // Future implementations on Darwin of these methods will likely be more optimized to take advantage of the cached values.
    public func scanString(_ searchString: String) -> String? {
        let str = self.string._bridgeToObjectiveC()
        var stringLoc = scanLocation
        let stringLen = str.length
        let options: NSString.CompareOptions = [caseSensitive ? [] : .caseInsensitive, .anchored]
        
        if let invSkipSet = charactersToBeSkipped?.inverted {
            let range = str.rangeOfCharacter(from: invSkipSet, options: [], range: NSRange(location: stringLoc, length: stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        
        let range = str.range(of: searchString, options: options, range: NSRange(location: stringLoc, length: stringLen - stringLoc))
        if range.length > 0 {
            /* ??? Is the range below simply range? 99.9% of the time, and perhaps even 100% of the time... Hmm... */
            let res = str.substring(with: NSRange(location: stringLoc, length: range.location + range.length - stringLoc))
            scanLocation = range.location + range.length
            return res
        }
        return nil
    }
    
    public func scanCharactersFromSet(_ set: CharacterSet) -> String? {
        let str = self.string._bridgeToObjectiveC()
        var stringLoc = scanLocation
        let stringLen = str.length
        let options: NSString.CompareOptions = caseSensitive ? [] : .caseInsensitive
        if let invSkipSet = charactersToBeSkipped?.inverted {
            let range = str.rangeOfCharacter(from: invSkipSet, options: [], range: NSRange(location: stringLoc, length: stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        var range = str.rangeOfCharacter(from: set.inverted, options: options, range: NSRange(location: stringLoc, length: stringLen - stringLoc))
        if range.length == 0 {
            range.location = stringLen
        }
        if stringLoc != range.location {
            let res = str.substring(with: NSRange(location: stringLoc, length: range.location - stringLoc))
            scanLocation = range.location
            return res
        }
        return nil
    }
    
    public func scanUpToString(_ string: String) -> String? {
        let str = self.string._bridgeToObjectiveC()
        var stringLoc = scanLocation
        let stringLen = str.length
        let options: NSString.CompareOptions = caseSensitive ? [] : .caseInsensitive
        if let invSkipSet = charactersToBeSkipped?.inverted {
            let range = str.rangeOfCharacter(from: invSkipSet, options: [], range: NSRange(location: stringLoc, length: stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        var range = str.range(of: string, options: options, range: NSRange(location: stringLoc, length: stringLen - stringLoc))
        if range.length == 0 {
            range.location = stringLen
        }
        if stringLoc != range.location {
            let res = str.substring(with: NSRange(location: stringLoc, length: range.location - stringLoc))
            scanLocation = range.location
            return res
        }
        return nil
    }
    
    public func scanUpToCharacters(from set: CharacterSet, into ptr: UnsafeMutablePointer<String?>?) -> Bool {
        if let result = scanUpToCharactersFromSet(set) {
            ptr?.pointee = result
            return true
        }
        return false
    }
    
    public func scanUpToCharactersFromSet(_ set: CharacterSet) -> String? {
        let str = self.string._bridgeToObjectiveC()
        var stringLoc = scanLocation
        let stringLen = str.length
        let options: NSString.CompareOptions = caseSensitive ? [] : .caseInsensitive
        if let invSkipSet = charactersToBeSkipped?.inverted {
            let range = str.rangeOfCharacter(from: invSkipSet, options: [], range: NSRange(location: stringLoc, length: stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        var range = str.rangeOfCharacter(from: set, options: options, range: NSRange(location: stringLoc, length: stringLen - stringLoc))
        if range.length == 0 {
            range.location = stringLen
        }
        if stringLoc != range.location {
            let res = str.substring(with: NSRange(location: stringLoc, length: range.location - stringLoc))
            scanLocation = range.location
            return res
        }
        return nil
    }
}

