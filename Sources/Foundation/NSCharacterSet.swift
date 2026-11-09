// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

// These values are part of the archive format. They match the CFCharacterSetPredefinedSet constants.
fileprivate enum PredefinedCharacterSetID: Int {
    case control = 1
    case whitespace = 2
    case whitespaceAndNewline = 3
    case decimalDigit = 4
    case letter = 5
    case lowercaseLetter = 6
    case uppercaseLetter = 7
    case nonBase = 8
    case decomposable = 9
    case alphaNumeric = 10
    case punctuation = 11
    case illegal = 12
    case capitalizedLetter = 13
    case symbol = 14
    case newline = 15

    var characterSet: CharacterSet {
        switch self {
        case .control: return .controlCharacters
        case .whitespace: return .whitespaces
        case .whitespaceAndNewline: return .whitespacesAndNewlines
        case .decimalDigit: return .decimalDigits
        case .letter: return .letters
        case .lowercaseLetter: return .lowercaseLetters
        case .uppercaseLetter: return .uppercaseLetters
        case .nonBase: return .nonBaseCharacters
        case .decomposable: return .decomposables
        case .alphaNumeric: return .alphanumerics
        case .punctuation: return .punctuationCharacters
        case .illegal: return .illegalCharacters
        case .capitalizedLetter: return .capitalizedLetters
        case .symbol: return .symbols
        case .newline: return .newlines
        }
    }
}

fileprivate extension String {
    static let characterSetBitmapRepresentationKey = "NSBitmap"
    static let characterSetAltBitmapRepresentationKey = "NSBitmapObject"
    static let characterSetStringKey = "NSString"
    static let characterSetAltStringKey = "NSStringObject"
    static let characterSetRangeKey = "NSRange"
    static let characterSetBuiltinIDKey = "NSBuiltinID"
    static let characterSetNewBuiltinIDKey = "NSBuiltinID2"
    static let characterSetIsInvertedKey = "NSIsInverted"
    static let characterSetNewIsInvertedKey = "NSIsInverted2"
}

/// Converts a range of UTF-32 code points to a range of scalars, clamping around the surrogate range.
fileprivate func closedScalarRange(from range: NSRange) -> ClosedRange<Unicode.Scalar>? {
    guard range.length > 0, range.location >= 0, range.location <= 0x10FFFF else {
        return nil
    }

    var lower = range.location
    var upper = min(range.location + range.length - 1, 0x10FFFF)

    // Surrogate code points are not scalars, so move an end of the range that lands on one.
    if (0xD800...0xDFFF).contains(lower) { lower = 0xE000 }
    if (0xD800...0xDFFF).contains(upper) { upper = 0xD7FF }
    guard lower <= upper,
          let lowerScalar = Unicode.Scalar(UInt32(lower)),
          let upperScalar = Unicode.Scalar(UInt32(upper)) else {
        return nil
    }
    return lowerScalar...upperScalar
}

@available(*, unavailable)
extension NSCharacterSet : @unchecked Sendable { }

open class NSCharacterSet : NSObject, NSCopying, NSMutableCopying, NSSecureCoding {
    internal var _characterSet: CharacterSet

    internal init(_characterSet: CharacterSet) {
        self._characterSet = _characterSet
        super.init()
    }

    open override var hash: Int {
        return _characterSet.hashValue
    }

    open override func isEqual(_ value: Any?) -> Bool {
        switch value {
        case let other as CharacterSet: return _characterSet == other
        case let other as NSCharacterSet: return _characterSet == other._characterSet
        default: return false
        }
    }

    open override var description: String {
        return _characterSet.description
    }

    public override init() {
        _characterSet = CharacterSet()
        super.init()
    }

    open class var controlCharacters: CharacterSet {
        return CharacterSet.controlCharacters
    }

    open class var whitespaces: CharacterSet {
        return CharacterSet.whitespaces
    }

    open class var whitespacesAndNewlines: CharacterSet {
        return CharacterSet.whitespacesAndNewlines
    }

    open class var decimalDigits: CharacterSet {
        return CharacterSet.decimalDigits
    }

    public class var letters: CharacterSet {
        return CharacterSet.letters
    }

    open class var lowercaseLetters: CharacterSet {
        return CharacterSet.lowercaseLetters
    }

    open class var uppercaseLetters: CharacterSet {
        return CharacterSet.uppercaseLetters
    }

    open class var nonBaseCharacters: CharacterSet {
        return CharacterSet.nonBaseCharacters
    }

    open class var alphanumerics: CharacterSet {
        return CharacterSet.alphanumerics
    }

    open class var decomposables: CharacterSet {
        return CharacterSet.decomposables
    }

    open class var illegalCharacters: CharacterSet {
        return CharacterSet.illegalCharacters
    }

    open class var punctuationCharacters: CharacterSet {
        return CharacterSet.punctuationCharacters
    }

    open class var capitalizedLetters: CharacterSet {
        return CharacterSet.capitalizedLetters
    }

    open class var symbols: CharacterSet {
        return CharacterSet.symbols
    }

    open class var newlines: CharacterSet {
        return CharacterSet.newlines
    }

    public init(range aRange: NSRange) {
        if let range = closedScalarRange(from: aRange) {
            _characterSet = CharacterSet(charactersIn: range)
        } else {
            _characterSet = CharacterSet()
        }
        super.init()
    }

    public init(charactersIn aString: String) {
        _characterSet = CharacterSet(charactersIn: aString)
        super.init()
    }

    public init(bitmapRepresentation data: Data) {
        _characterSet = CharacterSet(bitmapRepresentation: data)
        super.init()
    }

    public convenience init?(contentsOfFile fName: String) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: fName))
            self.init(bitmapRepresentation: data)
        } catch {
            return nil
        }
    }

    open class var supportsSecureCoding: Bool { return true }

    public required init?(coder aDecoder: NSCoder) {
        guard aDecoder.allowsKeyedCoding else {
            fatalError("Decoding requires a NSCoder that allows keyed coding.")
        }

        func fail(code: CocoaError.Code = .coderReadCorrupt, _ message: String) {
            aDecoder.failWithError(NSError(domain: NSCocoaErrorDomain, code: code.rawValue, userInfo: [ NSLocalizedDescriptionKey: message ]))
        }

        var builtinType = aDecoder.decodeInteger(forKey: .characterSetBuiltinIDKey)
        if builtinType == 0 {
            builtinType = aDecoder.decodeInteger(forKey: .characterSetNewBuiltinIDKey)
        }

        let isInverted = aDecoder.decodeBool(forKey: .characterSetIsInvertedKey) || aDecoder.decodeBool(forKey: .characterSetNewIsInvertedKey)

        let keyedUnarchiver = aDecoder as? NSKeyedUnarchiver
        let containsCharacterSetStringKeyName = aDecoder.containsValue(forKey: .characterSetStringKey)
        let containsCharacterSetStringAltKeyName = aDecoder.containsValue(forKey: .characterSetAltStringKey)

        var finalSet: CharacterSet

        if let predefinedSet = PredefinedCharacterSetID(rawValue: builtinType) {
            finalSet = predefinedSet.characterSet
        } else if aDecoder.containsValue(forKey: .characterSetRangeKey) {
            let range = UInt64(bitPattern: aDecoder.decodeInt64(forKey: .characterSetRangeKey))
            if let scalarRange = closedScalarRange(from: NSRange(location: Int(range >> 32), length: Int(range & 0xFFFFFFFF))) {
                finalSet = CharacterSet(charactersIn: scalarRange)
            } else {
                finalSet = CharacterSet()
            }
        } else if containsCharacterSetStringKeyName || containsCharacterSetStringAltKeyName {
            let maybeResult: NSString?

            if let keyedUnarchiver = keyedUnarchiver, containsCharacterSetStringKeyName {
                maybeResult = keyedUnarchiver._decodePropertyListForKey(.characterSetStringKey) as? NSString
            } else {
                maybeResult = aDecoder.decodeObject(of: NSString.self, forKey: .characterSetAltStringKey)
            }

            guard let result = maybeResult else {
                fail(code: .coderValueNotFound, "Decoder value not found")
                return nil
            }

            finalSet = CharacterSet(charactersIn: result._swiftObject)
        } else {
            let maybeResult: NSData?

            if let keyedUnarchiver = keyedUnarchiver, keyedUnarchiver.containsValue(forKey: .characterSetBitmapRepresentationKey) {
                maybeResult = keyedUnarchiver._decodePropertyListForKey(.characterSetBitmapRepresentationKey) as? NSData
            } else {
                maybeResult = aDecoder.decodeObject(of: NSData.self, forKey: .characterSetAltBitmapRepresentationKey)
            }

            guard let result = maybeResult else {
                fail(code: .coderValueNotFound, "Decoder value not found")
                return nil
            }

            finalSet = CharacterSet(bitmapRepresentation: result._swiftObject)
        }

        if isInverted {
            finalSet.invert()
        }

        _characterSet = finalSet
        super.init()
    }

    public func encode(with aCoder: NSCoder) {
        guard aCoder.allowsKeyedCoding else {
            fatalError("Encoding requires a NSCoder that allows keyed coding.")
        }

        // The public CharacterSet API does not say how a set is stored, so every set is archived as a bitmap.
        // The bitmap already includes any inversion.
        let bitmap = bitmapRepresentation._nsObject
        if let keyedArchiver = aCoder as? NSKeyedArchiver {
            keyedArchiver._encodePropertyList(bitmap, forKey: .characterSetBitmapRepresentationKey)
        } else {
            aCoder.encode(bitmap, forKey: .characterSetAltBitmapRepresentationKey)
        }
    }

    open func characterIsMember(_ aCharacter: unichar) -> Bool {
        return longCharacterIsMember(UInt32(aCharacter))
    }

    open var bitmapRepresentation: Data {
        return _characterSet.bitmapRepresentation
    }

    open var inverted: CharacterSet {
        return _characterSet.inverted
    }

    open func longCharacterIsMember(_ theLongChar: UInt32) -> Bool {
        // Surrogate code points and values past U+10FFFF are not scalars and are never members.
        guard let scalar = Unicode.Scalar(theLongChar) else {
            return false
        }
        return _characterSet.contains(scalar)
    }

    open func isSuperset(of theOtherSet: CharacterSet) -> Bool {
        return _characterSet.isSuperset(of: theOtherSet)
    }

    open func hasMemberInPlane(_ thePlane: UInt8) -> Bool {
        return _characterSet.hasMember(inPlane: thePlane)
    }

    open override func copy() -> Any {
        return copy(with: nil)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        if type(of: self) == NSCharacterSet.self {
            return self
        }
        return NSCharacterSet(_characterSet: _characterSet)
    }

    open override func mutableCopy() -> Any {
        return mutableCopy(with: nil)
    }

    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        return NSMutableCharacterSet(_characterSet: _characterSet)
    }
}

open class NSMutableCharacterSet : NSCharacterSet {

    open func addCharacters(in aRange: NSRange) {
        if let range = closedScalarRange(from: aRange) {
            _characterSet.insert(charactersIn: range)
        }
    }

    open func removeCharacters(in aRange: NSRange) {
        if let range = closedScalarRange(from: aRange) {
            _characterSet.remove(charactersIn: range)
        }
    }

    open func addCharacters(in aString: String) {
        _characterSet.insert(charactersIn: aString)
    }

    open func removeCharacters(in aString: String) {
        _characterSet.remove(charactersIn: aString)
    }

    open func formUnion(with otherSet: CharacterSet) {
        _characterSet.formUnion(otherSet)
    }

    open func formIntersection(with otherSet: CharacterSet) {
        _characterSet.formIntersection(otherSet)
    }

    open func invert() {
        _characterSet.invert()
    }

    open class func control() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .controlCharacters)
    }

    open class func whitespace() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .whitespaces)
    }

    open class func whitespaceAndNewline() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .whitespacesAndNewlines)
    }

    open class func decimalDigit() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .decimalDigits)
    }

    public class func letter() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .letters)
    }

    open class func lowercaseLetter() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .lowercaseLetters)
    }

    open class func uppercaseLetter() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .uppercaseLetters)
    }

    open class func nonBase() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .nonBaseCharacters)
    }

    open class func alphanumeric() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .alphanumerics)
    }

    open class func decomposable() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .decomposables)
    }

    open class func illegal() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .illegalCharacters)
    }

    open class func punctuation() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .punctuationCharacters)
    }

    open class func capitalizedLetter() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .capitalizedLetters)
    }

    open class func symbol() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .symbols)
    }

    open class func newline() -> NSMutableCharacterSet {
        return NSMutableCharacterSet(_characterSet: .newlines)
    }
}

extension CharacterSet : _NSBridgeable {
    typealias NSType = NSCharacterSet
    internal var _nsObject: NSType {
        return _bridgeToObjectiveC()
    }
}

extension CharacterSet : ReferenceConvertible {
    public typealias ReferenceType = NSCharacterSet
}

extension CharacterSet : _ObjectiveCBridgeable {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSCharacterSet {
        return NSCharacterSet(_characterSet: self)
    }

    public static func _forceBridgeFromObjectiveC(_ input: NSCharacterSet, result: inout CharacterSet?) {
        result = input._characterSet
    }

    public static func _conditionallyBridgeFromObjectiveC(_ input: NSCharacterSet, result: inout CharacterSet?) -> Bool {
        result = input._characterSet
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSCharacterSet?) -> CharacterSet {
        guard let source else { return CharacterSet() }
        return source._characterSet
    }
}

extension NSCharacterSet : _SwiftBridgeable {
    typealias SwiftType = CharacterSet
    internal var _swiftObject: SwiftType {
        return _characterSet
    }
}

extension NSCharacterSet : _StructTypeBridgeable {
    public typealias _StructType = CharacterSet
    public func _bridgeToSwift() -> CharacterSet {
        return _characterSet
    }
}
