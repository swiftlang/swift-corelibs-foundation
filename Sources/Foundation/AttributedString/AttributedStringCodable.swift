//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(Reflection) import Swift

// MARK: AttributedStringKey

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol EncodableAttributedStringKey : AttributedStringKey {
    static func encode(_ value: Value, to encoder: Encoder) throws
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol DecodableAttributedStringKey : AttributedStringKey {
    static func decode(from decoder: Decoder) throws -> Value
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public typealias CodableAttributedStringKey = EncodableAttributedStringKey & DecodableAttributedStringKey

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension EncodableAttributedStringKey where Value : Encodable {
    static func encode(_ value: Value, to encoder: Encoder) throws { try value.encode(to: encoder) }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension DecodableAttributedStringKey where Value : Decodable {
    static func decode(from decoder: Decoder) throws -> Value { return try Value.init(from: decoder) }
}


@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol MarkdownDecodableAttributedStringKey : AttributedStringKey {
    static func decodeMarkdown(from decoder: Decoder) throws -> Value
    static var markdownName: String { get }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension MarkdownDecodableAttributedStringKey {
    static var markdownName: String { name }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension MarkdownDecodableAttributedStringKey where Self : DecodableAttributedStringKey {
    static func decodeMarkdown(from decoder: Decoder) throws -> Value { try Self.decode(from: decoder) }
}


@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension EncodableAttributedStringKey where Value : NSSecureCoding & NSObject {
    static func encode(_ value: Value, to encoder: Encoder) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true)
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension DecodableAttributedStringKey where Value : NSSecureCoding & NSObject {
    static func decode(from decoder: Decoder) throws -> Value {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        if let result = try NSKeyedUnarchiver.unarchivedObject(ofClass: Value.self, from: data) {
            return result
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                    debugDescription: "Unable to unarchive object, result was nil"))
        }
    }
}

// MARK: Codable With Configuration

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol EncodingConfigurationProviding {
    associatedtype EncodingConfiguration
    static var encodingConfiguration: EncodingConfiguration { get }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol EncodableWithConfiguration {
    associatedtype EncodingConfiguration
    func encode(to encoder: Encoder, configuration: EncodingConfiguration) throws
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol DecodingConfigurationProviding {
    associatedtype DecodingConfiguration
    static var decodingConfiguration: DecodingConfiguration { get }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol DecodableWithConfiguration {
    associatedtype DecodingConfiguration
    init(from decoder: Decoder, configuration: DecodingConfiguration) throws
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public typealias CodableWithConfiguration = EncodableWithConfiguration & DecodableWithConfiguration


@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension KeyedEncodingContainer {
    mutating func encode<T, C>(_ wrapper: CodableConfiguration<T?, C>, forKey key: Self.Key) throws {
        switch wrapper.wrappedValue {
        case .some(let val):
            try val.encode(to: self.superEncoder(forKey: key), configuration: C.encodingConfiguration)
            break
        default: break
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension KeyedDecodingContainer {
    func decode<T, C>(_: CodableConfiguration<T?, C>.Type, forKey key: Self.Key) throws -> CodableConfiguration<T?, C> {
        if self.contains(key) {
            let wrapper = try self.decode(CodableConfiguration<T, C>.self, forKey: key)
            return CodableConfiguration<T?, C>(wrappedValue: wrapper.wrappedValue)
        } else {
            return CodableConfiguration<T?, C>(wrappedValue: nil)
        }
    }

}


@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension KeyedEncodingContainer {

    mutating func encode<T: EncodableWithConfiguration, C: EncodingConfigurationProviding>(_ t: T, forKey key: Self.Key, configuration: C.Type) throws where T.EncodingConfiguration == C.EncodingConfiguration {
        try t.encode(to: self.superEncoder(forKey: key), configuration: C.encodingConfiguration)
    }
    mutating func encodeIfPresent<T: EncodableWithConfiguration, C: EncodingConfigurationProviding>(_ t: T?, forKey key: Self.Key, configuration: C.Type) throws where T.EncodingConfiguration == C.EncodingConfiguration {
        guard let value = t else { return }
        try self.encode(value, forKey: key, configuration: configuration)
    }

    mutating func encode<T: EncodableWithConfiguration>(_ t: T, forKey key: Self.Key, configuration: T.EncodingConfiguration) throws {
        try t.encode(to: self.superEncoder(forKey: key), configuration: configuration)
    }
    mutating func encodeIfPresent<T: EncodableWithConfiguration>(_ t: T?, forKey key: Self.Key, configuration: T.EncodingConfiguration) throws {
        guard let value = t else { return }
        try self.encode(value, forKey: key, configuration: configuration)
    }

}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension KeyedDecodingContainer {

    func decode<T: DecodableWithConfiguration, C: DecodingConfigurationProviding>(_ : T.Type, forKey key: Self.Key, configuration: C.Type) throws -> T where T.DecodingConfiguration == C.DecodingConfiguration {
        return try T(from: self.superDecoder(forKey: key), configuration: C.decodingConfiguration)
    }
    func decodeIfPresent<T: DecodableWithConfiguration, C: DecodingConfigurationProviding>(_ : T.Type, forKey key: Self.Key, configuration: C.Type) throws -> T? where T.DecodingConfiguration == C.DecodingConfiguration {
        if contains(key) {
            return try self.decode(T.self, forKey: key, configuration: configuration)
        } else {
            return nil
        }
    }

    func decode<T: DecodableWithConfiguration>(_ : T.Type, forKey key: Self.Key, configuration: T.DecodingConfiguration) throws -> T {
        return try T(from: self.superDecoder(forKey: key), configuration: configuration)
    }
    func decodeIfPresent<T: DecodableWithConfiguration>(_ : T.Type, forKey key: Self.Key, configuration: T.DecodingConfiguration) throws -> T? {
        if contains(key) {
            return try self.decode(T.self, forKey: key, configuration: configuration)
        } else {
            return nil
        }
    }

}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension UnkeyedEncodingContainer {

    mutating func encode<T: EncodableWithConfiguration, C: EncodingConfigurationProviding>(_ t: T, configuration: C.Type) throws where T.EncodingConfiguration == C.EncodingConfiguration {
        try t.encode(to: self.superEncoder(), configuration: C.encodingConfiguration)
    }

    mutating func encode<T: EncodableWithConfiguration>(_ t: T, configuration: T.EncodingConfiguration) throws {
        try t.encode(to: self.superEncoder(), configuration: configuration)
    }

}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension UnkeyedDecodingContainer {

    mutating func decode<T: DecodableWithConfiguration, C: DecodingConfigurationProviding>(_ : T.Type, configuration: C.Type) throws -> T where T.DecodingConfiguration == C.DecodingConfiguration {
        return try T(from: try self.superDecoder(), configuration: C.decodingConfiguration)
    }
    mutating func decodeIfPresent<T: DecodableWithConfiguration, C: DecodingConfigurationProviding>(_ : T.Type, configuration: C.Type) throws -> T? where T.DecodingConfiguration == C.DecodingConfiguration {
        if try self.decodeNil() {
            return nil
        } else {
            return try self.decode(T.self, configuration: configuration)
        }
    }

    mutating func decode<T: DecodableWithConfiguration>(_ : T.Type, configuration: T.DecodingConfiguration) throws -> T {
        return try T(from: try self.superDecoder(), configuration: configuration)
    }
    mutating func decodeIfPresent<T: DecodableWithConfiguration>(_ : T.Type, configuration: T.DecodingConfiguration) throws -> T? {
        if try self.decodeNil() {
            return nil
        } else {
            return try self.decode(T.self, configuration: configuration)
        }
    }

}

@propertyWrapper
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public struct CodableConfiguration<T, ConfigurationProvider> : Codable where T : CodableWithConfiguration, ConfigurationProvider : EncodingConfigurationProviding & DecodingConfigurationProviding, ConfigurationProvider.EncodingConfiguration == T.EncodingConfiguration, ConfigurationProvider.DecodingConfiguration == T.DecodingConfiguration {
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public init(wrappedValue: T, from configurationProvider: ConfigurationProvider.Type) {
        self.wrappedValue = wrappedValue
    }

    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder, configuration: ConfigurationProvider.encodingConfiguration)
    }

    public init(from decoder: Decoder) throws {
        wrappedValue = try T(from: decoder, configuration: ConfigurationProvider.decodingConfiguration)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension CodableConfiguration : Equatable where T : Equatable { }

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension CodableConfiguration : Hashable where T : Hashable { }

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Optional : EncodableWithConfiguration where Wrapped : EncodableWithConfiguration {
    public func encode(to encoder: Encoder, configuration: Wrapped.EncodingConfiguration) throws {
        if let wrapped = self {
            try wrapped.encode(to: encoder, configuration: configuration)
        } else {
            var c = encoder.singleValueContainer()
            try c.encodeNil()
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Optional : DecodableWithConfiguration where Wrapped : DecodableWithConfiguration {
    public init(from decoder: Decoder, configuration: Wrapped.DecodingConfiguration) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            self = nil
        } else {
            self = try Wrapped.init(from: decoder, configuration: configuration)
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Array : EncodableWithConfiguration where Element : EncodableWithConfiguration {
    public func encode(to encoder: Encoder, configuration: Element.EncodingConfiguration) throws {
        var c = encoder.unkeyedContainer()
        for e in self {
            try c.encode(e, configuration: configuration)
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Array : DecodableWithConfiguration where Element : DecodableWithConfiguration {
    public init(from decoder: Decoder, configuration: Element.DecodingConfiguration) throws {
        var result = [Element]()
        var c = try decoder.unkeyedContainer()
        while !c.isAtEnd {
            try result.append(c.decode(Element.self, configuration: configuration))
        }
        self = result
    }
}

// MARK: AttributedString CodableWithConfiguration Conformance

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public struct AttributeScopeCodableConfiguration {
    internal let scopeType : Any.Type
    internal let extraAttributesTable : [String : Any.Type]
    
    internal init(scopeType: Any.Type, extraAttributesTable: [String : Any.Type] = [:]) {
        self.scopeType = scopeType
        self.extraAttributesTable = extraAttributesTable
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributeScope {
    static var encodingConfiguration: AttributeScopeCodableConfiguration { AttributeScopeCodableConfiguration(scopeType: self) }
    static var decodingConfiguration: AttributeScopeCodableConfiguration { AttributeScopeCodableConfiguration(scopeType: self) }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedString : Codable {
    public func encode(to encoder: Encoder) throws {
        try encode(to: encoder, configuration: AttributeScopeCodableConfiguration(scopeType: AttributeScopes.FoundationAttributes.self, extraAttributesTable: _loadDefaultAttributes()))
    }
    
    public init(from decoder: Decoder) throws {
        try self.init(from: decoder, configuration: AttributeScopeCodableConfiguration(scopeType: AttributeScopes.FoundationAttributes.self, extraAttributesTable: _loadDefaultAttributes()))
    }
}


@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedString : CodableWithConfiguration {

    private enum CodingKeys : String, CodingKey {
        case runs
        case attributeTable
    }

    private struct AttributeKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }

    public func encode(to encoder: Encoder, configuration: AttributeScopeCodableConfiguration) throws {
        if self._guts.runs.count == 0 || (self._guts.runs.count == 1 && self._guts.runs[0].attributes.contents.isEmpty) {
            var container = encoder.singleValueContainer()
            try container.encode(self._guts.string)
            return
        }

        var runsContainer: UnkeyedEncodingContainer
        var attributeTable = [_AttributeStorage : Int]()
        var attributeTableNextIndex = 0
        var attributeTableContainer: UnkeyedEncodingContainer?
        if self._guts.runs.count <= 10 {
            runsContainer = encoder.unkeyedContainer()
        } else {
            var topLevelContainer = encoder.container(keyedBy: CodingKeys.self)
            runsContainer = topLevelContainer.nestedUnkeyedContainer(forKey: .runs)
            attributeTableContainer = topLevelContainer.nestedUnkeyedContainer(forKey: .attributeTable)
        }

        var currentIndex = self.startIndex
        var attributeKeyTypes = configuration.extraAttributesTable
        for run in self._guts.runs {
            let currentEndIndex = self._guts.index(currentIndex, offsetByUTF8: run.length)
            let substring = self._guts.string[(currentIndex ..< currentEndIndex)._stringRange]
            try runsContainer.encode(String(substring))

            if !run.attributes.contents.isEmpty, var attributeTableContainer = attributeTableContainer {
                let index = attributeTable[run.attributes, default: attributeTableNextIndex]
                if index == attributeTableNextIndex {
                    try Self.encodeAttributeContainer(run.attributes, to: attributeTableContainer.superEncoder(), configuration: configuration, using: &attributeKeyTypes)
                    attributeTable[run.attributes] = index
                    attributeTableNextIndex += 1
                }
                try runsContainer.encode(index)
            } else {
                try Self.encodeAttributeContainer(run.attributes, to: runsContainer.superEncoder(), configuration: configuration, using: &attributeKeyTypes)
            }

            currentIndex = currentEndIndex
        }
    }

    fileprivate static func encodeAttributeContainer(_ attributes: _AttributeStorage, to encoder: Encoder, configuration: AttributeScopeCodableConfiguration, using attributeKeyTypeTable: inout [String : Any.Type]) throws {
        func projectScopeType<S>(_: S.Type) throws {
            var attributesContainer = encoder.container(keyedBy: AttributeKey.self)
            for (name, value) in attributes.contents {
                if let attributeKeyType = attributeKeyTypeTable[name] ?? GetAttributeTypeIfAttributeScope(S.self, key: name).attemptAction() ?? nil {
                    attributeKeyTypeTable[name] = attributeKeyType
                    func project<T>( _: T.Type) throws {
                        let attributeEncoder = attributesContainer.superEncoder(forKey: AttributeKey(stringValue: name)!)
                        let encodeIfCodable = EncodeIfCodable(T.self, value: value, encoder: attributeEncoder)
                        let _ = try encodeIfCodable.attemptAction() // Ignores result to drop attributes that are not codable
                    }
                    try _openExistential(attributeKeyType, do: project)
                } // else: the attribute was not in the provided scope, so drop it
            }
        }
        try _openExistential(configuration.scopeType, do: projectScopeType)
    }

    public init(from decoder: Decoder, configuration: AttributeScopeCodableConfiguration) throws {
        if let svc = try? decoder.singleValueContainer(), let str = try? svc.decode(String.self) {
            self.init(str)
            return
        }

        var runsContainer: UnkeyedDecodingContainer
        var attributeTable: [_AttributeStorage]?
        var attributeKeyTypeTable = configuration.extraAttributesTable

        if let runs = try? decoder.unkeyedContainer() {
            runsContainer = runs
            attributeTable = nil
        } else {
            let topLevelContainer = try decoder.container(keyedBy: CodingKeys.self)
            runsContainer = try topLevelContainer.nestedUnkeyedContainer(forKey: .runs)
            attributeTable = try Self.decodeAttributeTable(from: topLevelContainer.superDecoder(forKey: .attributeTable), configuration: configuration, using: &attributeKeyTypeTable)
        }

        var string = ""
        var runs = [_InternalRun]()
        if let containerCount = runsContainer.count {
            runs.reserveCapacity(containerCount / 2)
        }
        while !runsContainer.isAtEnd {
            let substring = try runsContainer.decode(String.self)
            var attributes: _AttributeStorage

            if let tableIndex = try? runsContainer.decode(Int.self) {
                guard let attributeTable = attributeTable else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                            debugDescription: "Attribute table index present with no reference attribute table"))
                }
                guard tableIndex >= 0 && tableIndex < attributeTable.count else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                            debugDescription: "Attribute table index \(tableIndex) is not within the bounds of the attribute table [0...\(attributeTable.count - 1)]"))
                }
                attributes = attributeTable[tableIndex]
            } else {
                attributes = try Self.decodeAttributeContainer(from: try runsContainer.superDecoder(), configuration: configuration, using: &attributeKeyTypeTable)
            }

            if substring.isEmpty && (runs.count > 0 || !runsContainer.isAtEnd) {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                        debugDescription: "When multiple runs are present, runs with empty substrings are not allowed"))
            }
            if substring.isEmpty && !attributes.contents.isEmpty {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                        debugDescription: "Runs of empty substrings cannot contain attributes"))
            }

            string += substring
            if let previous = runs.last, previous.attributes == attributes {
                runs[runs.count - 1].length += substring.count
            } else {
                runs.append(_InternalRun(length: substring.count, attributes: attributes))
            }
        }
        if runs.isEmpty {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                    debugDescription: "Runs container must not be empty"))
        }
        self.init(Guts(string: string, runs: runs))
    }

    private static func decodeAttributeTable(from decoder: Decoder, configuration: AttributeScopeCodableConfiguration, using attributeKeyTypeTable: inout [String : Any.Type]) throws -> [_AttributeStorage] {
        var container = try decoder.unkeyedContainer()
        var table = [_AttributeStorage]()
        if let size = container.count {
            table.reserveCapacity(size)
        }
        while !container.isAtEnd {
            table.append(try decodeAttributeContainer(from: try container.superDecoder(), configuration: configuration, using: &attributeKeyTypeTable))
        }
        return table
    }

    fileprivate static func decodeAttributeContainer(from decoder: Decoder, configuration: AttributeScopeCodableConfiguration, using attributeKeyTypeTable: inout [String : Any.Type]) throws -> _AttributeStorage {
        let attributesContainer = try decoder.container(keyedBy: AttributeKey.self)
        var attributes = _AttributeStorage()
        func projectScopeType<S>(_: S.Type) throws {
            for key in attributesContainer.allKeys {
                let name = key.stringValue
                if let attributeKeyType = attributeKeyTypeTable[name] ?? GetAttributeTypeIfAttributeScope(S.self, key: name).attemptAction() ?? nil {
                    attributeKeyTypeTable[name] = attributeKeyType
                    func project<T>( _: T.Type) throws {
                        let decodeIfCodable = DecodeIfCodable(T.self, decoder: try attributesContainer.superDecoder(forKey: key))
                        if let decoded = try decodeIfCodable.attemptAction() {
                            attributes.contents[name] = decoded
                        } // else: attribute was not codable, so drop it
                    }
                    try _openExistential(attributeKeyType, do: project)
                }
                // else: the attribute was not in the provided scope, so drop it
            }
        }
        try _openExistential(configuration.scopeType, do: projectScopeType)
        return attributes
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeContainer : CodableWithConfiguration {
    public func encode(to encoder: Encoder, configuration: AttributeScopeCodableConfiguration) throws {
        var attributeKeyTypeTable = configuration.extraAttributesTable
        var storage = AttributedString._AttributeStorage()
        storage.contents = self.contents
        try AttributedString.encodeAttributeContainer(storage, to: encoder, configuration: configuration, using: &attributeKeyTypeTable)
    }

    public init(from decoder: Decoder, configuration: AttributeScopeCodableConfiguration) throws {
        var attributeKeyTypeTable = configuration.extraAttributesTable
        let storage = try AttributedString.decodeAttributeContainer(from: decoder, configuration: configuration, using: &attributeKeyTypeTable)
        self.contents = storage.contents
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension CodableConfiguration where ConfigurationProvider : AttributeScope {
    init(wrappedValue: T, from keyPath: KeyPath<AttributeScopes, ConfigurationProvider.Type>) {
        self.wrappedValue = wrappedValue
    }
}
