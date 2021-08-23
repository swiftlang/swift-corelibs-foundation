//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(Reflection) import Swift

// MARK: API

// Developers define new attributes by implementing AttributeKey.
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol AttributedStringKey {
    associatedtype Value : Hashable
    static var name : String { get }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributedStringKey {
    var description: String { Self.name }
}

// Developers can also add the attributes to pre-defined scopes of attributes, which are used to provide type information to the encoding and decoding of AttributedString values, as well as allow for dynamic member lookup in Runss of AttributedStrings.
// Example, where ForegroundColor is an existing AttributedStringKey:
// struct MyAttributes : AttributeScope {
//     var foregroundColor : ForegroundColor
// }
// An AttributeScope can contain other scopes as well.
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol AttributeScope : DecodingConfigurationProviding, EncodingConfigurationProviding {
    static var decodingConfiguration: AttributeScopeCodableConfiguration { get }
    static var encodingConfiguration: AttributeScopeCodableConfiguration { get }
}

@frozen
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public enum AttributeScopes { }

@dynamicMemberLookup @frozen
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public enum AttributeDynamicLookup {
    public subscript<T: AttributedStringKey>(_: T.Type) -> T {
        get { fatalError("Called outside of a dynamicMemberLookup subscript overload") }
    }
}

@dynamicMemberLookup
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public struct ScopedAttributeContainer<S: AttributeScope> {
    internal var contents : [String : Any]
    
    // Record the most recently deleted key for use in AttributedString mutation subscripts that use _modify
    // Note: if ScopedAttributeContainer ever adds a mutating function that can mutate multiple attributes, this will need to record multiple removed keys
    internal var removedKey : String?

    public subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<S, T>) -> T.Value? {
        get { contents[T.name] as? T.Value }
        set {
            contents[T.name] = newValue
            if newValue == nil {
                removedKey = T.name
            }
        }
    }

    internal init(_ contents : [String : Any] = [:]) {
        self.contents = contents
    }

    internal func equals(_ other: Self) -> Bool {
        var equal = true
        _forEachField(of: S.self, options: [.ignoreUnknown]) { name, offset, type, kind -> Bool in
            func project<T>( _: T.Type) -> Bool {
                if let name = GetNameIfAttribute(T.self).attemptAction() {
                    if !__equalAttributes(self.contents[name], other.contents[name]) {
                        equal = false
                        return false
                    }
                }
                // TODO: Nested scopes
                return true
            }
            return _openExistential(type, do: project)
        }
        return equal
    }

    internal var attributes : AttributeContainer {
        var contents = [String : Any]()
        _forEachField(of: S.self, options: [.ignoreUnknown]) { name, offset, type, kind -> Bool in
            func project<T>( _: T.Type) -> Bool {
                if let name = GetNameIfAttribute(T.self).attemptAction() {
                    contents[name] = self.contents[name]
                }
                // TODO: Nested scopes
                return true
            }
            return _openExistential(type, do: project)
        }
        return AttributeContainer(contents)
    }
}


// MARK: Internals

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal extension AttributeScope {
    static func attributeKeyType(matching key: String) -> Any.Type? {
        var result : Any.Type?
        _forEachField(of: Self.self, options: [.ignoreUnknown]) { name, offset, type, kind -> Bool in
            func project<T>( _: T.Type) -> Bool {
                if GetNameIfAttribute(T.self).attemptAction() == key {
                    result = type
                    return false
                } else if let t = GetAttributeTypeIfAttributeScope(T.self, key: key).attemptAction() ?? nil {
                    result = t
                    return false
                }
                return true
            }
            return _openExistential(type, do: project)
        }
        return result
    }
    
    static func markdownAttributeKeyType(matching key: String) -> Any.Type? {
        var result : Any.Type?
        _forEachField(of: Self.self, options: [.ignoreUnknown]) { name, offset, type, kind -> Bool in
            func project<T>( _: T.Type) -> Bool {
                if GetMarkdownNameIfMarkdownDecodableAttribute(T.self).attemptAction() == key {
                    result = type
                    return false
                } else if let t = GetMarkdownAttributeTypeIfAttributeScope(T.self, key: key).attemptAction() ?? nil {
                    result = t
                    return false
                }
                return true
            }
            return _openExistential(type, do: project)
        }
        return result
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributeDynamicLookup {
}

// MARK: Attribute Protocol Unwrappers

internal protocol ProxyProtocol {
    associatedtype Wrapped
}

internal enum Proxy<Wrapped>: ProxyProtocol {}

internal protocol DynamicallyDispatched {
    associatedtype Input
    associatedtype Result
    func attemptAction() -> Result?
}

internal protocol ThrowingDynamicallyDispatched {
    associatedtype Input
    associatedtype Result
    func attemptAction() throws -> Result?
}

private protocol KnownConformance {
    static func performAction<T: DynamicallyDispatched>(_ t: T) -> T.Result
}

private protocol KnownThrowingConformance {
    static func performAction<T: ThrowingDynamicallyDispatched>(_ t: T) throws -> T.Result
}

private protocol ConformanceMarker {
    associatedtype A: DynamicallyDispatched
}

private protocol ThrowingConformanceMarker {
    associatedtype A: ThrowingDynamicallyDispatched
}

extension ConformanceMarker {
    fileprivate static func attempt(_ a: A) -> A.Result? {
        (self as? KnownConformance.Type)?.performAction(a)
    }
}

extension ThrowingConformanceMarker {
    fileprivate static func attempt(_ a: A) throws -> A.Result? {
        try (self as? KnownThrowingConformance.Type)?.performAction(a)
    }
}

// Specific to CodableAttributedStringKey

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal protocol AttemptIfCodable : ThrowingDynamicallyDispatched {
    override associatedtype Result

    func action<T: CodableAttributedStringKey>(_ t: T.Type) throws -> Result where T == Input
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttemptIfCodable {
    func attemptAction() throws -> Result? {
        try CodableAttributeMarker.attempt(self)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
private enum CodableAttributeMarker<A: AttemptIfCodable>: ThrowingConformanceMarker {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension CodableAttributeMarker: KnownThrowingConformance where A.Input: CodableAttributedStringKey {
    static func performAction<T: ThrowingDynamicallyDispatched>(_ t: T) throws -> T.Result {
        try (t as! A).action(A.Input.self) as! T.Result
    }
}

// Specific to Encoding and Decoding

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct EncodeIfCodable<P: ProxyProtocol> : AttemptIfCodable where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = Void

    private var x : Input.Type
    private var v : Any
    private var e : Encoder

    init<T>(_ x: T.Type, value : Any, encoder: Encoder) where P == Proxy<T> {
        self.x = x
        self.v = value
        self.e = encoder
    }

    func action<T : CodableAttributedStringKey>(_ t: T.Type) throws -> Result where T == Input {
        try x.encode(v as! T.Value, to: e)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct DecodeIfCodable<P: ProxyProtocol> : AttemptIfCodable where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = AnyHashable

    private var x : Input.Type
    private var d : Decoder

    init<T>(_ x: T.Type, decoder: Decoder) where P == Proxy<T> {
        self.x = x
        self.d = decoder
    }

    func action<T>(_ t: T.Type) throws -> AnyHashable where T : CodableAttributedStringKey, T == P.Wrapped {
        try x.decode(from: d)
    }
}

// Specific to MarkdownDecodableAttributedStringKey

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal protocol AttemptIfMarkdownDecodable : DynamicallyDispatched {
    override associatedtype Result

    func action<T: MarkdownDecodableAttributedStringKey>(_ t: T.Type) -> Result where T == Input
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttemptIfMarkdownDecodable {
    func attemptAction() -> Result? {
        MarkdownDecodableAttributeMarker.attempt(self)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
private enum MarkdownDecodableAttributeMarker<A: AttemptIfMarkdownDecodable>: ConformanceMarker {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension MarkdownDecodableAttributeMarker: KnownConformance where A.Input: MarkdownDecodableAttributedStringKey {
    static func performAction<T: DynamicallyDispatched>(_ t: T) -> T.Result {
        (t as! A).action(A.Input.self) as! T.Result
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal protocol ThrowingAttemptIfMarkdownDecodable : ThrowingDynamicallyDispatched {
    override associatedtype Result

    func action<T: MarkdownDecodableAttributedStringKey>(_ t: T.Type) throws -> Result where T == Input
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension ThrowingAttemptIfMarkdownDecodable {
    func attemptAction() throws -> Result? {
        try ThrowingMarkdownDecodableAttributeMarker.attempt(self)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
private enum ThrowingMarkdownDecodableAttributeMarker<A: ThrowingAttemptIfMarkdownDecodable>: ThrowingConformanceMarker {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension ThrowingMarkdownDecodableAttributeMarker: KnownThrowingConformance where A.Input: MarkdownDecodableAttributedStringKey {
    static func performAction<T: ThrowingDynamicallyDispatched>(_ t: T) throws -> T.Result {
        try (t as! A).action(A.Input.self) as! T.Result
    }
}

// Specific to Markdown decoding

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct DecodeIfMarkdownDecodable<P: ProxyProtocol> : ThrowingAttemptIfMarkdownDecodable where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = AnyHashable

    private var x : Input.Type
    private var d : Decoder

    init<T>(_ x: T.Type, decoder: Decoder) where P == Proxy<T> {
        self.x = x
        self.d = decoder
    }

    func action<T>(_ t: T.Type) throws -> AnyHashable where T : MarkdownDecodableAttributedStringKey, T == P.Wrapped {
        try x.decodeMarkdown(from: d)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct GetMarkdownNameIfMarkdownDecodableAttribute<P: ProxyProtocol> : AttemptIfMarkdownDecodable where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = String

    private var x : Input.Type

    init<T>(_ x: T.Type) where P == Proxy<T> {
        self.x = x
    }

    func action<T>(_ t: T.Type) -> String where T : MarkdownDecodableAttributedStringKey, T == P.Wrapped {
        x.markdownName
    }
}

// Specific to AttributedStringKey

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal protocol AttemptIfAttribute : DynamicallyDispatched {
    override associatedtype Result

    func action<T: AttributedStringKey>(_ t: T.Type) -> Result where T == Input
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttemptIfAttribute {
    func attemptAction() -> Result? {
        AttributeMarker.attempt(self)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
private enum AttributeMarker<A: AttemptIfAttribute>: ConformanceMarker {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeMarker: KnownConformance where A.Input: AttributedStringKey {
    static func performAction<T: DynamicallyDispatched>(_ t: T) -> T.Result {
        (t as! A).action(A.Input.self) as! T.Result
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal protocol ThrowingAttemptIfAttribute : ThrowingDynamicallyDispatched {
    override associatedtype Result

    func action<T: AttributedStringKey>(_ t: T.Type) throws -> Result where T == Input
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension ThrowingAttemptIfAttribute {
    func attemptAction() throws -> Result? {
        try ThrowingAttributeMarker.attempt(self)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
private enum ThrowingAttributeMarker<A: ThrowingAttemptIfAttribute>: ThrowingConformanceMarker {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension ThrowingAttributeMarker: KnownThrowingConformance where A.Input: AttributedStringKey {
    static func performAction<T: ThrowingDynamicallyDispatched>(_ t: T) throws -> T.Result {
        try (t as! A).action(A.Input.self) as! T.Result
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct GetNameIfAttribute<P: ProxyProtocol> : AttemptIfAttribute where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = String

    private var x : Input.Type

    init<T>(_ x: T.Type) where P == Proxy<T> {
        self.x = x
    }

    func action<T : AttributedStringKey>(_ t: T.Type) -> Result where T == Input {
        return t.name
    }
}

// Specific to NSAS Conversion

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal protocol AttemptIfObjCAttribute : ThrowingDynamicallyDispatched {
    override associatedtype Result

    func action<T: ObjectiveCConvertibleAttributedStringKey>(_ t: T.Type) throws -> Result where T == Input
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttemptIfObjCAttribute {
    func attemptAction() throws -> Result? {
        try ObjCAttributeMarker.attempt(self)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
private enum ObjCAttributeMarker<A: AttemptIfObjCAttribute>: ThrowingConformanceMarker {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension ObjCAttributeMarker: KnownThrowingConformance where A.Input: ObjectiveCConvertibleAttributedStringKey {
    static func performAction<T: ThrowingDynamicallyDispatched>(_ t: T) throws -> T.Result {
        try (t as! A).action(A.Input.self) as! T.Result
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct ConvertToObjCIfObjCAttribute<P: ProxyProtocol> : AttemptIfObjCAttribute where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = AnyObject

    private var x : Input.Type
    private var v : Any

    init<T>(_ x: T.Type, value : Any) where P == Proxy<T> {
        self.x = x
        self.v = value
    }

    func action<T : ObjectiveCConvertibleAttributedStringKey>(_ t: T.Type) throws -> Result where T == Input {
        return try t.objectiveCValue(for: v as! T.Value)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct ConvertFromObjCIfObjCAttribute<P: ProxyProtocol> : AttemptIfObjCAttribute where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = AnyHashable

    private var x : Input.Type
    private var v : AnyObject

    init<T>(_ x: T.Type, value : AnyObject) where P == Proxy<T> {
        self.x = x
        self.v = value
    }

    func action<T : ObjectiveCConvertibleAttributedStringKey>(_ t: T.Type) throws -> Result where T == Input {
        guard let objCValue = v as? T.ObjectiveCValue else {
            throw CocoaError(.coderInvalidValue)
        }
        return try t.value(for: objCValue)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct ConvertFromObjCIfAttribute<P: ProxyProtocol> : ThrowingAttemptIfAttribute where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = AnyHashable?

    private var x : Input.Type
    private var v : AnyObject

    init<T>(_ x: T.Type, value : AnyObject) where P == Proxy<T> {
        self.x = x
        self.v = value
    }

    func action<T : AttributedStringKey>(_ t: T.Type) throws -> Result where T == Input {
        guard let value = v as? T.Value else {
            throw CocoaError(.coderInvalidValue)
        }
        return value
    }
}

// For implementing generic Equatable without Hashable conformance

internal protocol AttemptIfEquatable : DynamicallyDispatched {
    override associatedtype Result

    func action<T: Equatable>(_ t: T.Type) -> Result where T == Input
}

extension AttemptIfEquatable {
    public func attemptAction() -> Result? {
        EquatableMarker.attempt(self)
    }
}

private enum EquatableMarker<A: AttemptIfEquatable>: ConformanceMarker {}

extension EquatableMarker: KnownConformance where A.Input: Equatable {
  static func performAction<T: DynamicallyDispatched>(_ t: T) -> T.Result {
    (t as! A).action(A.Input.self) as! T.Result
  }
}

internal struct CheckEqualityIfEquatable<P: ProxyProtocol> : AttemptIfEquatable where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = Bool

    private var lhs : Input
    private var rhs : Input

    init<T>(_ lhs: T, _ rhs: T) where P == Proxy<T> {
        self.lhs = lhs
        self.rhs = rhs
    }

    func action<T: Equatable>(_ t: T.Type) -> Result where T == Input {
        return lhs == rhs
    }
}

// Specific to AttributeScope.

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal protocol AttemptIfAttributeScope : DynamicallyDispatched {
    override associatedtype Result

    func action<T: AttributeScope>(_ t: T.Type) -> Result where T == Input
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttemptIfAttributeScope {
    func attemptAction() -> Result? {
        AttributeScopeMarker.attempt(self)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
private enum AttributeScopeMarker<A: AttemptIfAttributeScope>: ConformanceMarker {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeScopeMarker: KnownConformance where A.Input: AttributeScope {
    static func performAction<T: DynamicallyDispatched>(_ t: T) -> T.Result {
        (t as! A).action(A.Input.self) as! T.Result
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct GetAttributeTypeIfAttributeScope<P: ProxyProtocol> : AttemptIfAttributeScope where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = Any.Type?
    private var x : Input.Type
    private var key: String
    init<T>(_ x: T.Type, key: String) where P == Proxy<T> {
        self.x = x
        self.key = key
    }
    func action<T : AttributeScope>(_ t: T.Type) -> Result where T == Input {
        return t.attributeKeyType(matching: key)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct GetAllAttributeTypesIfAttributeScope<P: ProxyProtocol> : AttemptIfAttributeScope where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = [String : Any.Type]
    private var x : Input.Type
    init<T>(_ x: T.Type) where P == Proxy<T> {
        self.x = x
    }
    func action<T : AttributeScope>(_ t: T.Type) -> Result where T == Input {
        var result = [String : Any.Type]()
        _forEachField(of: t, options: [.ignoreUnknown]) { pointer, offset, type, kind -> Bool in
            func project<K>(_: K.Type) {
                if let key = GetNameIfAttribute(K.self).attemptAction() {
                    result[key] = type
                } else if let subResults = GetAllAttributeTypesIfAttributeScope<Proxy<K>>(K.self).attemptAction() {
                    result.merge(subResults, uniquingKeysWith: { current, new in new })
                }
            }
            _openExistential(type, do: project)
            return true
        }
        return result
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal struct GetMarkdownAttributeTypeIfAttributeScope<P: ProxyProtocol> : AttemptIfAttributeScope where P.Wrapped : Any {
    typealias Input = P.Wrapped
    typealias Result = Any.Type?
    private var x : Input.Type
    private var key: String
    init<T>(_ x: T.Type, key: String) where P == Proxy<T> {
        self.x = x
        self.key = key
    }
    func action<T : AttributeScope>(_ t: T.Type) -> Result where T == Input {
        return t.markdownAttributeKeyType(matching: key)
    }
}
