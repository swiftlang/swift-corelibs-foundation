//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

private func _utfRangeToNSRange(_ inRange : Range<UnicodeScalar>) -> NSRange {
    return NSRange(location: Int(inRange.lowerBound.value), length: Int(inRange.upperBound.value - inRange.lowerBound.value))
}

private func _utfRangeToNSRange(_ inRange : ClosedRange<UnicodeScalar>) -> NSRange {
    return NSRange(location: Int(inRange.lowerBound.value), length: Int(inRange.upperBound.value - inRange.lowerBound.value + 1))
}

/**
 A `CharacterSet` represents a set of Unicode-compliant characters. Foundation types use `CharacterSet` to group characters together for searching operations, so that they can find any of a particular set of characters during a search.
 
 This type provides "copy-on-write" behavior, and is also bridged to the Objective-C `NSCharacterSet` class.
 */
public struct CharacterSet : ReferenceConvertible, Equatable, Hashable, SetAlgebra, Sendable {
    public typealias ReferenceType = NSCharacterSet
    
    // This may be either an NSCharacterSet or an NSMutableCharacterSet (dynamically)
    internal nonisolated(unsafe) var _wrapped : NSCharacterSet
    
    // MARK: Init methods
    
    internal init(_bridged characterSet: NSCharacterSet) {
        // We must copy the input because it might be mutable; just like storing a value type in ObjC
        _wrapped = characterSet.copy() as! NSCharacterSet
    }
    
    /// Initialize an empty instance.
    public init() {
        _wrapped = NSCharacterSet()
    }
    
    /// Initialize with a range of integers.
    ///
    /// It is the caller's responsibility to ensure that the values represent valid `UnicodeScalar` values, if that is what is desired.
    public init(charactersIn range: Range<UnicodeScalar>) {
        _wrapped = NSCharacterSet(range: _utfRangeToNSRange(range))
    }
    
    /// Initialize with a closed range of integers.
    ///
    /// It is the caller's responsibility to ensure that the values represent valid `UnicodeScalar` values, if that is what is desired.
    public init(charactersIn range: ClosedRange<UnicodeScalar>) {
        _wrapped = NSCharacterSet(range: _utfRangeToNSRange(range))
    }
    
    /// Initialize with the characters in the given string.
    ///
    /// - parameter string: The string content to inspect for characters.
    public init(charactersIn string: String) {
        _wrapped = NSCharacterSet(charactersIn: string)
    }
    
    /// Initialize with a bitmap representation.
    ///
    /// This method is useful for creating a character set object with data from a file or other external data source.
    /// - parameter data: The bitmap representation.
    public init(bitmapRepresentation data: Data) {
        _wrapped = NSCharacterSet(bitmapRepresentation: data)
    }
    
#if !os(WASI)
    /// Initialize with the contents of a file.
    ///
    /// Returns `nil` if there was an error reading the file.
    /// - parameter file: The file to read.
    public init?(contentsOfFile file: String) {
        if let interior = NSCharacterSet(contentsOfFile: file) {
            _wrapped = interior
        } else {
            return nil
        }
    }
#endif
    
    public func hash(into hasher: inout Hasher) {
        _wrapped.hash(into: &hasher)
    }
    
    public var description: String {
        _wrapped.description
    }
    
    public var debugDescription: String {
        _wrapped.debugDescription
    }
    
    // MARK: Static functions
    
    /// Returns a character set containing the characters in Unicode General Category Cc and Cf.
    public static var controlCharacters : CharacterSet {
        return NSCharacterSet.controlCharacters
    }
    
    /// Returns a character set containing the characters in Unicode General Category Zs and `CHARACTER TABULATION (U+0009)`.
    public static var whitespaces : CharacterSet {
        return NSCharacterSet.whitespaces
    }
    
    /// Returns a character set containing characters in Unicode General Category Z*, `U+000A ~ U+000D`, and `U+0085`.
    public static var whitespacesAndNewlines : CharacterSet {
        return NSCharacterSet.whitespacesAndNewlines
    }
    
    /// Returns a character set containing the characters in the category of Decimal Numbers.
    public static var decimalDigits : CharacterSet {
        return NSCharacterSet.decimalDigits
    }
    
    /// Returns a character set containing the characters in Unicode General Category L* & M*.
    public static var letters : CharacterSet {
        return NSCharacterSet.letters
    }
    
    /// Returns a character set containing the characters in Unicode General Category Ll.
    public static var lowercaseLetters : CharacterSet {
        return NSCharacterSet.lowercaseLetters
    }
    
    /// Returns a character set containing the characters in Unicode General Category Lu and Lt.
    public static var uppercaseLetters : CharacterSet {
        return NSCharacterSet.uppercaseLetters
    }
    
    /// Returns a character set containing the characters in Unicode General Category M*.
    public static var nonBaseCharacters : CharacterSet {
        return NSCharacterSet.nonBaseCharacters
    }
    
    /// Returns a character set containing the characters in Unicode General Categories L*, M*, and N*.
    public static var alphanumerics : CharacterSet {
        return NSCharacterSet.alphanumerics
    }
    
    /// Returns a character set containing individual Unicode characters that can also be represented as composed character sequences (such as for letters with accents), by the definition of "standard decomposition" in version 3.2 of the Unicode character encoding standard.
    public static var decomposables : CharacterSet {
        return NSCharacterSet.decomposables
    }
    
    /// Returns a character set containing values in the category of Non-Characters or that have not yet been defined in version 3.2 of the Unicode standard.
    public static var illegalCharacters : CharacterSet {
        return NSCharacterSet.illegalCharacters
    }
    
    /// Returns a character set containing the characters in Unicode General Category P*.
    public static var punctuationCharacters : CharacterSet {
        return NSCharacterSet.punctuationCharacters
    }
    
    /// Returns a character set containing the characters in Unicode General Category Lt.
    public static var capitalizedLetters : CharacterSet {
        return NSCharacterSet.capitalizedLetters
    }
    
    /// Returns a character set containing the characters in Unicode General Category S*.
    public static var symbols : CharacterSet {
        return NSCharacterSet.symbols
    }
    
    /// Returns a character set containing the newline characters (`U+000A ~ U+000D`, `U+0085`, `U+2028`, and `U+2029`).
    public static var newlines : CharacterSet {
        return NSCharacterSet.newlines
    }
    
    // MARK: Static functions, from NSURL
    
    /// Returns the character set for characters allowed in a user URL subcomponent.
    public static var urlUserAllowed : CharacterSet {
        return NSCharacterSet.urlUserAllowed
    }
    
    /// Returns the character set for characters allowed in a password URL subcomponent.
    public static var urlPasswordAllowed : CharacterSet {
        return NSCharacterSet.urlPasswordAllowed
    }
    
    /// Returns the character set for characters allowed in a host URL subcomponent.
    public static var urlHostAllowed : CharacterSet {
        return NSCharacterSet.urlHostAllowed
    }
    
    /// Returns the character set for characters allowed in a path URL component.
    public static var urlPathAllowed : CharacterSet {
        return NSCharacterSet.urlPathAllowed
    }
    
    /// Returns the character set for characters allowed in a query URL component.
    public static var urlQueryAllowed : CharacterSet {
        return NSCharacterSet.urlQueryAllowed
    }
    
    /// Returns the character set for characters allowed in a fragment URL component.
    public static var urlFragmentAllowed : CharacterSet {
        return NSCharacterSet.urlFragmentAllowed
    }
    
    // MARK: Immutable functions
    
    /// Returns a representation of the `CharacterSet` in binary format.
    public var bitmapRepresentation: Data {
        _wrapped.bitmapRepresentation
    }
    
    /// Returns an inverted copy of the receiver.
    public var inverted : CharacterSet {
        _wrapped.inverted
    }
    
    /// Returns true if the `CharacterSet` has a member in the specified plane.
    ///
    /// This method makes it easier to find the plane containing the members of the current character set. The Basic Multilingual Plane (BMP) is plane 0.
    public func hasMember(inPlane plane: UInt8) -> Bool {
        _wrapped.hasMemberInPlane(plane)
    }
    
    // MARK: Mutable functions
    
    private mutating func _add(charactersIn nsRange: NSRange) {
        if !isKnownUniquelyReferenced(&_wrapped) {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.addCharacters(in: nsRange)
            _wrapped = copy
        } else if let mutable = _wrapped as? NSMutableCharacterSet {
            mutable.addCharacters(in: nsRange)
        } else {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.addCharacters(in: nsRange)
            _wrapped = copy
        }
    }
    
    private mutating func _remove(charactersIn nsRange: NSRange) {
        if !isKnownUniquelyReferenced(&_wrapped) {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.removeCharacters(in: nsRange)
            _wrapped = copy
        } else if let mutable = _wrapped as? NSMutableCharacterSet {
            mutable.removeCharacters(in: nsRange)
        } else {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.removeCharacters(in: nsRange)
            _wrapped = copy
        }
    }
    
    /// Insert a range of integer values in the `CharacterSet`.
    ///
    /// It is the caller's responsibility to ensure that the values represent valid `UnicodeScalar` values, if that is what is desired.
    public mutating func insert(charactersIn range: Range<UnicodeScalar>) {
        let nsRange = _utfRangeToNSRange(range)
        _add(charactersIn: nsRange)
    }
    
    /// Insert a closed range of integer values in the `CharacterSet`.
    ///
    /// It is the caller's responsibility to ensure that the values represent valid `UnicodeScalar` values, if that is what is desired.
    public mutating func insert(charactersIn range: ClosedRange<UnicodeScalar>) {
        let nsRange = _utfRangeToNSRange(range)
        _add(charactersIn: nsRange)
    }
    
    /// Remove a range of integer values from the `CharacterSet`.
    public mutating func remove(charactersIn range: Range<UnicodeScalar>) {
        let nsRange = _utfRangeToNSRange(range)
        _remove(charactersIn: nsRange)
    }
    
    /// Remove a closed range of integer values from the `CharacterSet`.
    public mutating func remove(charactersIn range: ClosedRange<UnicodeScalar>) {
        let nsRange = _utfRangeToNSRange(range)
        _remove(charactersIn: nsRange)
    }
    
    /// Insert the values from the specified string into the `CharacterSet`.
    public mutating func insert(charactersIn string: String) {
        if !isKnownUniquelyReferenced(&_wrapped) {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.addCharacters(in: string)
            _wrapped = copy
        } else if let mutable = _wrapped as? NSMutableCharacterSet {
            mutable.addCharacters(in: string)
        } else {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.addCharacters(in: string)
            _wrapped = copy
        }
    }
    
    /// Remove the values from the specified string from the `CharacterSet`.
    public mutating func remove(charactersIn string: String) {
        if !isKnownUniquelyReferenced(&_wrapped) {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.removeCharacters(in: string)
            _wrapped = copy
        } else if let mutable = _wrapped as? NSMutableCharacterSet {
            mutable.removeCharacters(in: string)
        } else {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.removeCharacters(in: string)
            _wrapped = copy
        }
    }
    
    /// Invert the contents of the `CharacterSet`.
    public mutating func invert() {
        if !isKnownUniquelyReferenced(&_wrapped) {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.invert()
            _wrapped = copy
        } else if let mutable = _wrapped as? NSMutableCharacterSet {
            mutable.invert()
        } else {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.invert()
            _wrapped = copy
        }
    }
    
    // -----
    // MARK: -
    // MARK: SetAlgebraType
    
    /// Insert a `UnicodeScalar` representation of a character into the `CharacterSet`.
    ///
    /// `UnicodeScalar` values are available on `Swift.String.UnicodeScalarView`.
    @discardableResult
    public mutating func insert(_ character: UnicodeScalar) -> (inserted: Bool, memberAfterInsert: UnicodeScalar) {
        let nsRange = NSRange(location: Int(character.value), length: 1)
        _add(charactersIn: nsRange)
        // TODO: This should probably return the truth, but figuring it out requires two calls into NSCharacterSet
        return (true, character)
    }
    
    /// Insert a `UnicodeScalar` representation of a character into the `CharacterSet`.
    ///
    /// `UnicodeScalar` values are available on `Swift.String.UnicodeScalarView`.
    @discardableResult
    public mutating func update(with character: UnicodeScalar) -> UnicodeScalar? {
        let nsRange = NSRange(location: Int(character.value), length: 1)
        _add(charactersIn: nsRange)
        // TODO: This should probably return the truth, but figuring it out requires two calls into NSCharacterSet
        return character
    }
    
    
    /// Remove a `UnicodeScalar` representation of a character from the `CharacterSet`.
    ///
    /// `UnicodeScalar` values are available on `Swift.String.UnicodeScalarView`.
    @discardableResult
    public mutating func remove(_ character: UnicodeScalar) -> UnicodeScalar? {
        // TODO: Add method to NSCharacterSet to do this in one call
        let result : UnicodeScalar? = contains(character) ? character : nil
        let r = NSRange(location: Int(character.value), length: 1)
        _remove(charactersIn: r)
        return result
    }
    
    /// Test for membership of a particular `UnicodeScalar` in the `CharacterSet`.
    public func contains(_ member: UnicodeScalar) -> Bool {
        _wrapped.longCharacterIsMember(member.value)
    }
    
    /// Returns a union of the `CharacterSet` with another `CharacterSet`.
    public func union(_ other: CharacterSet) -> CharacterSet {
        // The underlying collection does not have a method to return new CharacterSets with changes applied, so we will copy and apply here
        var result = self
        result.formUnion(other)
        return result
    }
    
    /// Sets the value to a union of the `CharacterSet` with another `CharacterSet`.
    public mutating func formUnion(_ other: CharacterSet) {
        if !isKnownUniquelyReferenced(&_wrapped) {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.formUnion(with: other)
            _wrapped = copy
        } else if let mutable = _wrapped as? NSMutableCharacterSet {
            mutable.formUnion(with: other)
        } else {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.formUnion(with: other)
            _wrapped = copy
        }
    }
    
    /// Returns an intersection of the `CharacterSet` with another `CharacterSet`.
    public func intersection(_ other: CharacterSet) -> CharacterSet {
        // The underlying collection does not have a method to return new CharacterSets with changes applied, so we will copy and apply here
        var result = self
        result.formIntersection(other)
        return result
    }
    
    /// Sets the value to an intersection of the `CharacterSet` with another `CharacterSet`.
    public mutating func formIntersection(_ other: CharacterSet) {
        if !isKnownUniquelyReferenced(&_wrapped) {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.formIntersection(with: other)
            _wrapped = copy
        } else if let mutable = _wrapped as? NSMutableCharacterSet {
            mutable.formIntersection(with: other)
        } else {
            let copy = _wrapped.mutableCopy() as! NSMutableCharacterSet
            copy.formIntersection(with: other)
            _wrapped = copy
        }
    }
    
    /// Returns a `CharacterSet` created by removing elements in `other` from `self`.
    public func subtracting(_ other: CharacterSet) -> CharacterSet {
        return intersection(other.inverted)
    }
    
    /// Sets the value to a `CharacterSet` created by removing elements in `other` from `self`.
    public mutating func subtract(_ other: CharacterSet) {
        self = subtracting(other)
    }
    
    /// Returns an exclusive or of the `CharacterSet` with another `CharacterSet`.
    public func symmetricDifference(_ other: CharacterSet) -> CharacterSet {
        return union(other).subtracting(intersection(other))
    }
    
    /// Sets the value to an exclusive or of the `CharacterSet` with another `CharacterSet`.
    public mutating func formSymmetricDifference(_ other: CharacterSet) {
        self = symmetricDifference(other)
    }
    
    /// Returns true if `self` is a superset of `other`.
    public func isSuperset(of other: CharacterSet) -> Bool {
        _wrapped.isSuperset(of: other)
    }
    
    /// Returns true if the two `CharacterSet`s are equal.
    public static func ==(lhs : CharacterSet, rhs: CharacterSet) -> Bool {
        lhs._wrapped.isEqual(rhs._wrapped)
    }
}


// MARK: Objective-C Bridging
extension CharacterSet : _ObjectiveCBridgeable {
    public static func _isBridgedToObjectiveC() -> Bool {
        return true
    }
    
    public static func _getObjectiveCType() -> Any.Type {
        return NSCharacterSet.self
    }
    
    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSCharacterSet {
        return _wrapped
    }
    
    public static func _forceBridgeFromObjectiveC(_ input: NSCharacterSet, result: inout CharacterSet?) {
        result = CharacterSet(_bridged: input)
    }
    
    public static func _conditionallyBridgeFromObjectiveC(_ input: NSCharacterSet, result: inout CharacterSet?) -> Bool {
        result = CharacterSet(_bridged: input)
        return true
    }
    
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSCharacterSet?) -> CharacterSet {
        return CharacterSet(_bridged: source!)
    }
    
}

extension CharacterSet : Codable {
    private enum CodingKeys : Int, CodingKey {
        case bitmap
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bitmap = try container.decode(Data.self, forKey: .bitmap)
        self.init(bitmapRepresentation: bitmap)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.bitmapRepresentation, forKey: .bitmap)
    }
}
