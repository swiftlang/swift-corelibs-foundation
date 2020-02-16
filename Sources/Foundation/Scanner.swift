// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


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
    open var locale: Any?
    
    internal static let defaultSkipSet = CharacterSet.whitespacesAndNewlines
    
    public init(string: String) {
        _scanString = string
        _skipSet = Scanner.defaultSkipSet
        _scanLocation = 0
    }
    
    // On overflow, the below methods will return success and clamp
    @discardableResult
    open func scanInt32(_ result: UnsafeMutablePointer<Int32>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: Int32) -> Void in
            result.pointee = value
        }
    }
    
    @discardableResult
    open func scanInt(_ result: UnsafeMutablePointer<Int>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: Int) -> Void in
            result.pointee = value
        }
    }
    
    @discardableResult
    open func scanInt64(_ result: UnsafeMutablePointer<Int64>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: Int64) -> Void in
            result.pointee = value
        }
    }
    
    @discardableResult
    open func scanUnsignedLongLong(_ result: UnsafeMutablePointer<UInt64>) -> Bool {
        return _scanString.scan(_skipSet, locationToScanFrom: &_scanLocation) { (value: UInt64) -> Void in
            result.pointee = value
        }
    }
    
    @discardableResult
    open func scanFloat(_ result: UnsafeMutablePointer<Float>) -> Bool {
        return _scanString.scan(_skipSet, locale: locale as? Locale, locationToScanFrom: &_scanLocation) { (value: Float) -> Void in
            result.pointee = value
        }
    }
    
    @discardableResult
    open func scanDouble(_ result: UnsafeMutablePointer<Double>) -> Bool {
        return _scanString.scan(_skipSet, locale: locale as? Locale, locationToScanFrom: &_scanLocation) { (value: Double) -> Void in
            result.pointee = value
        }
    }
    
    @discardableResult
    open func scanHexInt32(_ result: UnsafeMutablePointer<UInt32>) -> Bool {
        return _scanString.scanHex(_skipSet, locationToScanFrom: &_scanLocation) { (value: UInt32) -> Void in
            result.pointee = value
        }
    }
    
    @discardableResult
    open func scanHexInt64(_ result: UnsafeMutablePointer<UInt64>) -> Bool {
        return _scanString.scanHex(_skipSet, locationToScanFrom: &_scanLocation) { (value: UInt64) -> Void in
            result.pointee = value
        }
    }
    
    @discardableResult
    open func scanHexFloat(_ result: UnsafeMutablePointer<Float>) -> Bool {
        return _scanString.scanHex(_skipSet, locale: locale as? Locale, locationToScanFrom: &_scanLocation) { (value: Float) -> Void in
            result.pointee = value
        }
    }
    
    @discardableResult
    open func scanHexDouble(_ result: UnsafeMutablePointer<Double>) -> Bool {
        return _scanString.scanHex(_skipSet, locale: locale as? Locale, locationToScanFrom: &_scanLocation) { (value: Double) -> Void in
            result.pointee = value
        }
    }
    
    open var isAtEnd: Bool {
        var stringLoc = scanLocation
        let stringLen = string.length
        if let invSet = invertedSkipSet {
            let range = string._nsObject.rangeOfCharacter(from: invSet, options: [], range: NSRange(location: stringLoc, length: stringLen - stringLoc))
            stringLoc = range.length > 0 ? range.location : stringLen
        }
        return stringLoc == stringLen
    }
    
    open class func localizedScanner(with string: String) -> Any {
        let scanner = Scanner(string: string)
        scanner.locale = Locale.current
        return scanner
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


private func decimalValue(_ ch: unichar) -> Int? {
    guard let s = UnicodeScalar(ch), s.isASCII else { return nil }
    return Character(s).wholeNumberValue
}

private func decimalOrHexValue(_ ch: unichar) -> Int? {
    guard let s = UnicodeScalar(ch), s.isASCII else { return nil }
    return Character(s).hexDigitValue
}


extension String {

    private func checkForNegative(inBuffer buf: inout _NSStringBuffer, skipping skipSet: CharacterSet? = nil) -> Bool {
        buf.skip(skipSet)
        if buf.currentCharacter == unichar(unicodeScalarLiteral: "-") || buf.currentCharacter == unichar(unicodeScalarLiteral: "+") {
            let neg = buf.currentCharacter == unichar(unicodeScalarLiteral: "-")
            buf.advance()
            buf.skip(skipSet)
            return neg
        }
        return false
    }

    // If a string starts: 0[xX]<Valid Hex Digits> return with the buffer pointing to the hex digits otherwise point to the start of buffer.
    private func skipHexStart(inBuffer buf: inout _NSStringBuffer) {
        let locRewindTo = buf.location
        if buf.currentCharacter == unichar(unicodeScalarLiteral: "0") {
            buf.advance()
            if buf.currentCharacter == unichar(unicodeScalarLiteral: "x") || buf.currentCharacter == unichar(unicodeScalarLiteral: "X") {
                buf.advance()
                if decimalOrHexValue(buf.currentCharacter) != nil {
                    return
                }
            }
            buf.location = locRewindTo
        }
    }

    internal func scan<T: FixedWidthInteger>(_ skipSet: CharacterSet?, locationToScanFrom: inout Int, to: (T) -> Void) -> Bool {
        var buf = _NSStringBuffer(string: self, start: locationToScanFrom, end: length)
        var localResult: T = 0
        var retval = false
        var neg = checkForNegative(inBuffer: &buf, skipping: skipSet)

        while let numeral = decimalValue(buf.currentCharacter) {
            retval = true
            if (localResult >= T.max / 10) && ((localResult > T.max / 10) || T(numeral - (neg ? 1 : 0)) >= T.max - localResult * 10) {
                // apply the clamps and advance past the ending of the buffer where there are still digits
                localResult = neg ? T.min : T.max
                neg = false
                repeat {
                    buf.advance()
                } while decimalValue(buf.currentCharacter) != nil
                break
            } else {
                // normal case for scanning
                localResult = localResult * 10 + T(numeral)
            }
            buf.advance()
        }
        to(neg ? -1 * localResult : localResult)
        locationToScanFrom = buf.location
        return retval
    }

    internal func scanHex<T: FixedWidthInteger>(_ skipSet: CharacterSet?, locationToScanFrom: inout Int, to: (T) -> Void) -> Bool {
        var buf = _NSStringBuffer(string: self, start: locationToScanFrom, end: length)
        var localResult: T = 0
        var retval = false
        buf.skip(skipSet)
        skipHexStart(inBuffer: &buf)

        while let numeral = decimalOrHexValue(buf.currentCharacter)  {
            retval = true
            if localResult > T.max >> T(4) {
                localResult = T.max
            } else {
                localResult = (localResult << T(4)) + T(numeral)
            }
            buf.advance()
        }

        to(localResult)
        locationToScanFrom = buf.location
        return retval
    }
    
    private func _scan<T: BinaryFloatingPoint>(buffer buf: inout _NSStringBuffer, locale: Locale?, neg: Bool, to: (T) -> Void, base: UInt,
                                               numericValue: ((_: unichar) -> Int?)) -> Bool {
        let ds = (locale ?? Locale.current).decimalSeparator?.first ?? Character(".")
        var localResult: T! = nil
        var neg = neg

        while let numeral = numericValue(buf.currentCharacter) {
            localResult = localResult ?? T(0)
            // if (localResult >= T.greatestFiniteMagnitude / T(10)) && ((localResult > T.greatestFiniteMagnitude / T(10)) || T(numericValue(buf.currentCharacter) - (neg ? 1 : 0)) >= T.greatestFiniteMagnitude - localResult * T(10))  is evidently too complex; so break it down to more "edible chunks"
            let limit1 = localResult >= T.greatestFiniteMagnitude / T(base)
            let limit2 = localResult > T.greatestFiniteMagnitude / T(base)
            let limit3 = T(numeral - (neg ? 1 : 0)) >= T.greatestFiniteMagnitude - localResult * T(base)
            if (limit1) && (limit2 || limit3) {
                // apply the clamps and advance past the ending of the buffer where there are still digits
                localResult = neg ? -T.infinity : T.infinity
                neg = false
                repeat {
                    buf.advance()
                } while numericValue(buf.currentCharacter) != nil
                break
            } else {
                localResult = localResult * T(base) + T(numeral)
            }
            buf.advance()
        }
        
        if let us = UnicodeScalar(buf.currentCharacter), Character(us) == ds {
            var factor = 1 / T(base)
            buf.advance()
            while let numeral = numericValue(buf.currentCharacter) {
                localResult = localResult ?? T(0)
                localResult = localResult + T(numeral) * factor
                factor = factor / T(base)
                buf.advance()
            }
        }

        guard localResult != nil else {
            return false
        }

        // If this is used to parse a number in Hexadecimal, this will never be true as the 'e' or 'E' will be caught by the previous loop.
        if buf.currentCharacter == unichar(unicodeScalarLiteral: "e") || buf.currentCharacter == unichar(unicodeScalarLiteral: "E") {
            var exponent = Double(0)

            buf.advance()
            let negExponent = checkForNegative(inBuffer: &buf)

            while let numeral = numericValue(buf.currentCharacter) {
                buf.advance()
                exponent *= Double(base)
                exponent += Double(numeral)
            }

            if exponent > 0 {
                let multiplier = pow(Double(base), exponent)
                if negExponent {
                    localResult /= T(multiplier)
                } else {
                    localResult *= T(multiplier)
                }
            }
        }

        to(neg ? T(-1) * localResult : localResult)
        return true
    }

    internal func scan<T: BinaryFloatingPoint>(_ skipSet: CharacterSet?, locale: Locale?, locationToScanFrom: inout Int, to: (T) -> Void) -> Bool {
        var buf = _NSStringBuffer(string: self, start: locationToScanFrom, end: length)
        let neg = checkForNegative(inBuffer: &buf, skipping: skipSet)
        let result = _scan(buffer: &buf, locale: locale, neg: neg, to: to, base: 10, numericValue: decimalValue)
        locationToScanFrom = buf.location
        return result
    }

    internal func scanHex<T: BinaryFloatingPoint>(_ skipSet: CharacterSet?, locale: Locale?, locationToScanFrom: inout Int, to: (T) -> Void) -> Bool {
        var buf = _NSStringBuffer(string: self, start: locationToScanFrom, end: length)
        let neg = checkForNegative(inBuffer: &buf, skipping: skipSet)
        skipHexStart(inBuffer: &buf)
        let result = _scan(buffer: &buf, locale: locale, neg: neg, to: to, base: 16, numericValue: decimalOrHexValue)
        locationToScanFrom = buf.location
        return result
    }
}

// This extension used to house the experimental API for Scanner. This is all deprecated in favor of API with newer semantics. Some of the experimental API have been promoted to full API with slightly different semantics; see ScannerAPI.swift.
extension Scanner {
    // These methods are in a special bit of mess:
    // - They used to exist here; but
    // - They have all been replaced by methods called scan<Type>(representation:); but
    // - The representation parameter has a default value, so scan<Type>() is still valid and has the same semantics as the below.
    // This means that the new methods _aren't_ fully source compatible — most source will correctly pick up the new .scan<Type>(representation:) with the default, but things like let method = scanner.scanInt32 may or may not work any longer.
    // Make sure that the signatures exist here so that in case the compiler would pick them up, we can direct people to the new ones. This should be rare.
    
    // scanDecimal() is not among these methods and has not changed at all, though it has been promoted to non-experimental API.
    
    @available(swift, obsoleted: 5.0, renamed: "scanInt(representation:)")
    public func scanInt() -> Int? { return scanInt(representation: .decimal) }
    
    @available(swift, obsoleted: 5.0, renamed: "scanInt32(representation:)")
    public func scanInt32() -> Int32? { return scanInt32(representation: .decimal) }
    
    @available(swift, obsoleted: 5.0, renamed: "scanInt64(representation:)")
    public func scanInt64() -> Int64? { return scanInt64(representation: .decimal) }
    
    @available(swift, obsoleted: 5.0, renamed: "scanUInt64(representation:)")
    public func scanUInt64() -> UInt64? { return scanUInt64(representation: .decimal) }
    
    @available(swift, obsoleted: 5.0, renamed: "scanFloat(representation:)")
    public func scanFloat() -> Float? { return scanFloat(representation: .decimal) }
    
    @available(swift, obsoleted: 5.0, renamed: "scanDouble(representation:)")
    public func scanDouble() -> Double? { return scanDouble(representation: .decimal) }
    
    // These existed but are now deprecated in favor of the new methods:
    
    @available(swift, deprecated: 5.0, renamed: "scanUInt64(representation:)")
    public func scanHexInt32() -> UInt32? {
        guard let value = scanUInt64(representation: .hexadecimal) else { return nil }
        return UInt32(min(value, UInt64(UInt32.max)))
    }
    
    @available(swift, deprecated: 5.0, renamed: "scanUInt64(representation:)")
    public func scanHexInt64() -> UInt64? { return scanUInt64(representation: .hexadecimal) }
    
    @available(swift, deprecated: 5.0, renamed: "scanFloat(representation:)")
    public func scanHexFloat() -> Float? { return scanFloat(representation: .hexadecimal) }
    
    @available(swift, deprecated: 5.0, renamed: "scanDouble(representation:)")
    public func scanHexDouble() -> Double? { return scanDouble(representation: .hexadecimal) }
    
    @available(swift, deprecated: 5.0, renamed: "scanString(_:)")
    @discardableResult
    public func scanString(_ string:String, into ptr: UnsafeMutablePointer<String?>?) -> Bool {
        if let str = _scanStringSplittingGraphemes(string) {
            ptr?.pointee = str
            return true
        }
        return false
    }
    
    // These methods avoid calling the private API for _invertedSkipSet and manually re-construct them so that it is only usage of public API usage
    // Future implementations on Darwin of these methods will likely be more optimized to take advantage of the cached values.
    private func _scanStringSplittingGraphemes(_ searchString: String) -> String? {
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
    
    @available(swift, deprecated: 5.0, renamed: "scanCharacters(from:)")
    public func scanCharactersFromSet(_ set: CharacterSet) -> String? {
        return _scanCharactersSplittingGraphemes(from: set)
    }
    
    @available(swift, deprecated: 5.0, renamed: "scanCharacters(from:)")
    public func scanCharacters(from set: CharacterSet, into ptr: UnsafeMutablePointer<String?>?) -> Bool {
        if let str = _scanCharactersSplittingGraphemes(from: set) {
            ptr?.pointee = str
            return true
        }
        return false
    }
    
    private func _scanCharactersSplittingGraphemes(from set: CharacterSet) -> String? {
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
    
    @available(swift, deprecated: 5.0, renamed: "scanUpToString(_:)")
    @discardableResult
    public func scanUpTo(_ string:String, into ptr: UnsafeMutablePointer<String?>?) -> Bool {
        if let str = _scanUpToStringSplittingGraphemes(string) {
            ptr?.pointee = str
            return true
        }
        return false
    }
    
    public func _scanUpToStringSplittingGraphemes(_ string: String) -> String? {
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
    
    @available(swift, deprecated: 5.0, renamed: "scanUpToCharacters(from:)")
    @discardableResult
    public func scanUpToCharacters(from set: CharacterSet, into ptr: UnsafeMutablePointer<String?>?) -> Bool {
        if let result = _scanSplittingGraphemesUpToCharacters(from: set) {
            ptr?.pointee = result
            return true
        }
        return false
    }
    
    @available(swift, deprecated: 5.0, renamed: "scanUpToCharacters(from:)")
    public func scanUpToCharactersFromSet(_ set: CharacterSet) -> String? {
        return _scanSplittingGraphemesUpToCharacters(from: set)
    }
    
    private func _scanSplittingGraphemesUpToCharacters(from set: CharacterSet) -> String? {
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

