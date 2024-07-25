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

internal final class _SwiftNSCharacterSet : NSCharacterSet, _SwiftNativeFoundationType {
    internal typealias ImmutableType = NSCharacterSet
    internal typealias MutableType = NSMutableCharacterSet
    
    fileprivate var __wrapped : _MutableUnmanagedWrapper<ImmutableType, MutableType>
    
    init(immutableObject: AnyObject) {
        // Take ownership.
        __wrapped = .Immutable(Unmanaged.passRetained(_unsafeReferenceCast(immutableObject, to: ImmutableType.self)))
        super.init()
    }
    
    init(mutableObject: AnyObject) {
        // Take ownership.
        __wrapped = .Mutable(Unmanaged.passRetained(_unsafeReferenceCast(mutableObject, to: MutableType.self)))
        super.init()
    }
    
    internal required init(unmanagedImmutableObject: Unmanaged<ImmutableType>) {
        // Take ownership.
        __wrapped = .Immutable(unmanagedImmutableObject)
        
        super.init()
    }
    
    internal required init(unmanagedMutableObject: Unmanaged<MutableType>) {
        // Take ownership.
        __wrapped = .Mutable(unmanagedMutableObject)
        
        super.init()
    }
    
    convenience required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        releaseWrappedObject()
    }
    
    
    override func copy(with zone: NSZone? = nil) -> Any {
        return _mapUnmanaged { $0.copy(with: zone) }
    }
    
    override func mutableCopy(with zone: NSZone? = nil) -> Any {
        return _mapUnmanaged { $0.mutableCopy(with: zone) }
    }
    
    public override var classForCoder: AnyClass {
        return NSCharacterSet.self
    }
    
    override var bitmapRepresentation: Data {
        return _mapUnmanaged { $0.bitmapRepresentation }
    }
    
    override var inverted : CharacterSet {
        return _mapUnmanaged { $0.inverted }
    }
    
    override func hasMemberInPlane(_ thePlane: UInt8) -> Bool {
        return _mapUnmanaged {$0.hasMemberInPlane(thePlane) }
    }
    
    override func characterIsMember(_ member: unichar) -> Bool {
        return _mapUnmanaged { $0.characterIsMember(member) }
    }
    
    override func longCharacterIsMember(_ member: UInt32) -> Bool {
        return _mapUnmanaged { $0.longCharacterIsMember(member) }
    }
    
    override func isSuperset(of other: CharacterSet) -> Bool {
        return _mapUnmanaged { $0.isSuperset(of: other) }
    }

    override var _cfObject: CFType {
        // We cannot inherit super's unsafeBitCast(self, to: CFType.self) here, because layout of _SwiftNSCharacterSet
        // is not compatible with CFCharacterSet. We need to bitcast the underlying NSCharacterSet instead.
        return _mapUnmanaged { unsafeBitCast($0, to: CFType.self) }
    }
}

/**
 A `CharacterSet` represents a set of Unicode-compliant characters. Foundation types use `CharacterSet` to group characters together for searching operations, so that they can find any of a particular set of characters during a search.
 
 This type provides "copy-on-write" behavior, and is also bridged to the Objective-C `NSCharacterSet` class.
 */
public struct CharacterSet : ReferenceConvertible, Equatable, Hashable, SetAlgebra, Sendable, _MutablePairBoxing {
    public typealias ReferenceType = NSCharacterSet
    
    internal typealias SwiftNSWrapping = _SwiftNSCharacterSet
    internal typealias ImmutableType = SwiftNSWrapping.ImmutableType
    internal typealias MutableType = SwiftNSWrapping.MutableType
    
    internal nonisolated(unsafe) var _wrapped : _SwiftNSCharacterSet
    
    // MARK: Init methods
    
    internal init(_bridged characterSet: NSCharacterSet) {
        // We must copy the input because it might be mutable; just like storing a value type in ObjC
        _wrapped = _SwiftNSCharacterSet(immutableObject: characterSet.copy() as! NSObject)
    }
    
    /// Initialize an empty instance.
    public init() {
        _wrapped = _SwiftNSCharacterSet(immutableObject: NSCharacterSet())
    }
    
    /// Initialize with a range of integers.
    ///
    /// It is the caller's responsibility to ensure that the values represent valid `UnicodeScalar` values, if that is what is desired.
    public init(charactersIn range: Range<UnicodeScalar>) {
        _wrapped = _SwiftNSCharacterSet(immutableObject: NSCharacterSet(range: _utfRangeToNSRange(range)))
    }
    
    /// Initialize with a closed range of integers.
    ///
    /// It is the caller's responsibility to ensure that the values represent valid `UnicodeScalar` values, if that is what is desired.
    public init(charactersIn range: ClosedRange<UnicodeScalar>) {
        _wrapped = _SwiftNSCharacterSet(immutableObject: NSCharacterSet(range: _utfRangeToNSRange(range)))
    }
    
    /// Initialize with the characters in the given string.
    ///
    /// - parameter string: The string content to inspect for characters.
    public init(charactersIn string: String) {
        _wrapped = _SwiftNSCharacterSet(immutableObject: NSCharacterSet(charactersIn: string))
    }
    
    /// Initialize with a bitmap representation.
    ///
    /// This method is useful for creating a character set object with data from a file or other external data source.
    /// - parameter data: The bitmap representation.
    public init(bitmapRepresentation data: Data) {
        _wrapped = _SwiftNSCharacterSet(immutableObject: NSCharacterSet(bitmapRepresentation: data))
    }
    
#if !os(WASI)
    /// Initialize with the contents of a file.
    ///
    /// Returns `nil` if there was an error reading the file.
    /// - parameter file: The file to read.
    public init?(contentsOfFile file: String) {
        if let interior = NSCharacterSet(contentsOfFile: file) {
            _wrapped = _SwiftNSCharacterSet(immutableObject: interior)
        } else {
            return nil
        }
    }
#endif
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_mapUnmanaged { $0 })
    }
    
    public var description: String {
        return _mapUnmanaged { $0.description }
    }
    
    public var debugDescription: String {
        return _mapUnmanaged { $0.debugDescription }
    }
    
    private init(reference: NSCharacterSet) {
        _wrapped = _SwiftNSCharacterSet(immutableObject: reference)
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
        return _mapUnmanaged { $0.bitmapRepresentation }
    }
    
    /// Returns an inverted copy of the receiver.
    public var inverted : CharacterSet {
        return _mapUnmanaged { $0.inverted }
    }
    
    /// Returns true if the `CharacterSet` has a member in the specified plane.
    ///
    /// This method makes it easier to find the plane containing the members of the current character set. The Basic Multilingual Plane (BMP) is plane 0.
    public func hasMember(inPlane plane: UInt8) -> Bool {
        return _mapUnmanaged { $0.hasMemberInPlane(plane) }
    }
    
    // MARK: Mutable functions
    
    /// Insert a range of integer values in the `CharacterSet`.
    ///
    /// It is the caller's responsibility to ensure that the values represent valid `UnicodeScalar` values, if that is what is desired.
    public mutating func insert(charactersIn range: Range<UnicodeScalar>) {
        let nsRange = _utfRangeToNSRange(range)
        _applyUnmanagedMutation {
            $0.addCharacters(in: nsRange)
        }
    }
    
    /// Insert a closed range of integer values in the `CharacterSet`.
    ///
    /// It is the caller's responsibility to ensure that the values represent valid `UnicodeScalar` values, if that is what is desired.
    public mutating func insert(charactersIn range: ClosedRange<UnicodeScalar>) {
        let nsRange = _utfRangeToNSRange(range)
        _applyUnmanagedMutation {
            $0.addCharacters(in: nsRange)
        }
    }
    
    /// Remove a range of integer values from the `CharacterSet`.
    public mutating func remove(charactersIn range: Range<UnicodeScalar>) {
        let nsRange = _utfRangeToNSRange(range)
        _applyUnmanagedMutation {
            $0.removeCharacters(in: nsRange)
        }
    }
    
    /// Remove a closed range of integer values from the `CharacterSet`.
    public mutating func remove(charactersIn range: ClosedRange<UnicodeScalar>) {
        let nsRange = _utfRangeToNSRange(range)
        _applyUnmanagedMutation {
            $0.removeCharacters(in: nsRange)
        }
    }
    
    /// Insert the values from the specified string into the `CharacterSet`.
    public mutating func insert(charactersIn string: String) {
        _applyUnmanagedMutation {
            $0.addCharacters(in: string)
        }
    }
    
    /// Remove the values from the specified string from the `CharacterSet`.
    public mutating func remove(charactersIn string: String) {
        _applyUnmanagedMutation {
            $0.removeCharacters(in: string)
        }
    }
    
    /// Invert the contents of the `CharacterSet`.
    public mutating func invert() {
        _applyUnmanagedMutation { $0.invert() }
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
        _applyUnmanagedMutation {
            $0.addCharacters(in: nsRange)
        }
        // TODO: This should probably return the truth, but figuring it out requires two calls into NSCharacterSet
        return (true, character)
    }
    
    /// Insert a `UnicodeScalar` representation of a character into the `CharacterSet`.
    ///
    /// `UnicodeScalar` values are available on `Swift.String.UnicodeScalarView`.
    @discardableResult
    public mutating func update(with character: UnicodeScalar) -> UnicodeScalar? {
        let nsRange = NSRange(location: Int(character.value), length: 1)
        _applyUnmanagedMutation {
            $0.addCharacters(in: nsRange)
        }
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
        _applyUnmanagedMutation {
            $0.removeCharacters(in: r)
        }
        return result
    }
    
    /// Test for membership of a particular `UnicodeScalar` in the `CharacterSet`.
    public func contains(_ member: UnicodeScalar) -> Bool {
        return _mapUnmanaged { $0.longCharacterIsMember(member.value) }
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
        _applyUnmanagedMutation { $0.formUnion(with: other) }
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
        _applyUnmanagedMutation {
            $0.formIntersection(with: other)
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
        return _mapUnmanaged { $0.isSuperset(of: other) }
    }
    
    /// Returns true if the two `CharacterSet`s are equal.
    public static func ==(lhs : CharacterSet, rhs: CharacterSet) -> Bool {
        return lhs._mapUnmanaged { $0.isEqual(rhs) }
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

// MARK: - Boxing protocols
// Only used by CharacterSet at this time

fileprivate enum _MutableUnmanagedWrapper<ImmutableType : NSObject, MutableType : NSObject> where MutableType : NSMutableCopying {
    case Immutable(Unmanaged<ImmutableType>)
    case Mutable(Unmanaged<MutableType>)
}

fileprivate protocol _SwiftNativeFoundationType: AnyObject {
    associatedtype ImmutableType : NSObject
    associatedtype MutableType : NSObject,  NSMutableCopying
    var __wrapped : _MutableUnmanagedWrapper<ImmutableType, MutableType> { get }
    
    init(unmanagedImmutableObject: Unmanaged<ImmutableType>)
    init(unmanagedMutableObject: Unmanaged<MutableType>)
    
    func mutableCopy(with zone : NSZone) -> Any
    
    func hash(into hasher: inout Hasher)
    var hashValue: Int { get }

    var description: String { get }
    var debugDescription: String { get }
    
    func releaseWrappedObject()
}

extension _SwiftNativeFoundationType {
    
    @inline(__always)
    func _mapUnmanaged<ReturnType>(_ whatToDo : (ImmutableType) throws -> ReturnType) rethrows -> ReturnType {
        defer { _fixLifetime(self) }
        
        switch __wrapped {
        case .Immutable(let i):
            return try i._withUnsafeGuaranteedRef {
                _onFastPath()
                return try whatToDo($0)
            }
        case .Mutable(let m):
            return try m._withUnsafeGuaranteedRef {
                _onFastPath()
                return try whatToDo(_unsafeReferenceCast($0, to: ImmutableType.self))
            }
        }
    }
    
    func releaseWrappedObject() {
        switch __wrapped {
        case .Immutable(let i):
            i.release()
        case .Mutable(let m):
            m.release()
        }
    }
    
    func mutableCopy(with zone : NSZone) -> Any {
        return _mapUnmanaged { ($0 as NSObject).mutableCopy() }
    }
    
    func hash(into hasher: inout Hasher) {
        _mapUnmanaged { hasher.combine($0) }
    }

    var hashValue: Int {
        return _mapUnmanaged { return $0.hashValue }
    }
    
    var description: String {
        return _mapUnmanaged { return $0.description }
    }
    
    var debugDescription: String {
        return _mapUnmanaged { return $0.debugDescription }
    }
    
    func isEqual(_ other: AnyObject) -> Bool {
        return _mapUnmanaged { return $0.isEqual(other) }
    }
}

fileprivate protocol _MutablePairBoxing {
    associatedtype WrappedSwiftNSType : _SwiftNativeFoundationType
    var _wrapped :  WrappedSwiftNSType { get set }
}

extension _MutablePairBoxing {
    @inline(__always)
    func _mapUnmanaged<ReturnType>(_ whatToDo : (WrappedSwiftNSType.ImmutableType) throws -> ReturnType) rethrows -> ReturnType {
        // We are using Unmanaged. Make sure that the owning container class
        // 'self' is guaranteed to be alive by extending the lifetime of 'self'
        // to the end of the scope of this function.
        // Note: At the time of this writing using withExtendedLifetime here
        // instead of _fixLifetime causes different ARC pair matching behavior
        // foiling optimization. This is why we explicitly use _fixLifetime here
        // instead.
        defer { _fixLifetime(self) }
        
        let unmanagedHandle = Unmanaged.passUnretained(_wrapped)
        let wrapper = unmanagedHandle._withUnsafeGuaranteedRef { $0.__wrapped }
        switch (wrapper) {
        case .Immutable(let i):
            return try i._withUnsafeGuaranteedRef {
                return try whatToDo($0)
            }
        case .Mutable(let m):
            return try m._withUnsafeGuaranteedRef {
                return try whatToDo(_unsafeReferenceCast($0, to: WrappedSwiftNSType.ImmutableType.self))
            }
        }
    }
    
    @inline(__always)
    mutating func _applyUnmanagedMutation<ReturnType>(_ whatToDo : (WrappedSwiftNSType.MutableType) throws -> ReturnType) rethrows -> ReturnType {
        // We are using Unmanaged. Make sure that the owning container class
        // 'self' is guaranteed to be alive by extending the lifetime of 'self'
        // to the end of the scope of this function.
        // Note: At the time of this writing using withExtendedLifetime here
        // instead of _fixLifetime causes different ARC pair matching behavior
        // foiling optimization. This is why we explicitly use _fixLifetime here
        // instead.
        defer { _fixLifetime(self) }
        
        var unique = true
        let _unmanagedHandle = Unmanaged.passUnretained(_wrapped)
        let wrapper = _unmanagedHandle._withUnsafeGuaranteedRef { $0.__wrapped }
        
        // This check is done twice because: <rdar://problem/24939065> Value kept live for too long causing uniqueness check to fail
        switch (wrapper) {
        case .Immutable:
            break
        case .Mutable:
            unique = isKnownUniquelyReferenced(&_wrapped)
        }
        
        switch (wrapper) {
        case .Immutable(let i):
            // We need to become mutable; by creating a new instance we also become unique
            let copy = Unmanaged.passRetained(i._withUnsafeGuaranteedRef {
                return _unsafeReferenceCast($0.mutableCopy(), to: WrappedSwiftNSType.MutableType.self) }
            )
            
            // Be sure to set the var before calling out; otherwise references to the struct in the closure may be looking at the old value
            _wrapped = WrappedSwiftNSType(unmanagedMutableObject: copy)
            return try copy._withUnsafeGuaranteedRef {
                _onFastPath()
                return try whatToDo($0)
            }
        case .Mutable(let m):
            // Only create a new box if we are not uniquely referenced
            if !unique {
                let copy = Unmanaged.passRetained(m._withUnsafeGuaranteedRef {
                    return _unsafeReferenceCast($0.mutableCopy(), to: WrappedSwiftNSType.MutableType.self)
                    })
                _wrapped = WrappedSwiftNSType(unmanagedMutableObject: copy)
                return try copy._withUnsafeGuaranteedRef {
                    _onFastPath()
                    return try whatToDo($0)
                }
            } else {
                return try m._withUnsafeGuaranteedRef {
                    _onFastPath()
                    return try whatToDo($0)
                }
            }
        }
    }
}

