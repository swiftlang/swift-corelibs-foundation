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

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol ObjectiveCConvertibleAttributedStringKey : AttributedStringKey {
    associatedtype ObjectiveCValue : NSObject

    static func objectiveCValue(for value: Value) throws -> ObjectiveCValue
    static func value(for object: ObjectiveCValue) throws -> Value
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension ObjectiveCConvertibleAttributedStringKey where Value : RawRepresentable, Value.RawValue == Int, ObjectiveCValue == NSNumber {
    static func objectiveCValue(for value: Value) throws -> ObjectiveCValue {
        return NSNumber(value: value.rawValue)
    }
    static func value(for object: ObjectiveCValue) throws -> Value {
        if let val = Value(rawValue: object.intValue) {
            return val
        }
        throw CocoaError(.coderInvalidValue)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension ObjectiveCConvertibleAttributedStringKey where Value : RawRepresentable, Value.RawValue == String, ObjectiveCValue == NSString {
    static func objectiveCValue(for value: Value) throws -> ObjectiveCValue {
        return value.rawValue as NSString
    }
    static func value(for object: ObjectiveCValue) throws -> Value {
        if let val = Value(rawValue: object as String) {
            return val
        }
        throw CocoaError(.coderInvalidValue)
    }
}

internal struct _AttributeConversionOptions : OptionSet {
    let rawValue: Int
    
    // If an attribute's value(for: ObjectieCValue) or objectiveCValue(for: Value) function throws, ignore the error and drop the attribute
    static let dropThrowingAttributes = Self(rawValue: 1 << 0)
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributeContainer {
    init(_ dictionary: [NSAttributedString.Key : Any]) {
        var attributeKeyTypes = _loadDefaultAttributes()
        // Passing .dropThrowingAttributes causes attributes that throw during conversion to be dropped, so it is safe to do try! here
        try! self.init(dictionary, including: AttributeScopes.FoundationAttributes.self, attributeKeyTypes: &attributeKeyTypes, options: .dropThrowingAttributes)
    }
    
    
    init<S: AttributeScope>(_ dictionary: [NSAttributedString.Key : Any], including scope: KeyPath<AttributeScopes, S.Type>) throws {
        try self.init(dictionary, including: S.self)
    }
    
    init<S: AttributeScope>(_ dictionary: [NSAttributedString.Key : Any], including scope: S.Type) throws {
        var attributeKeyTypes = [String : Any.Type]()
        try self.init(dictionary, including: scope, attributeKeyTypes: &attributeKeyTypes)
    }
    
    fileprivate init<S: AttributeScope>(_ dictionary: [NSAttributedString.Key : Any], including scope: S.Type, attributeKeyTypes: inout [String : Any.Type], options: _AttributeConversionOptions = []) throws {
        contents = [:]
        for (key, value) in dictionary {
            if let type = attributeKeyTypes[key.rawValue] ?? S.attributeKeyType(matching: key.rawValue) {
                attributeKeyTypes[key.rawValue] = type
                var swiftVal: AnyHashable?
                func project<T>(_: T.Type) throws {
                    if let val = try ConvertFromObjCIfObjCAttribute(T.self, value: value as AnyObject).attemptAction() {
                        // Value is converted via the function defined by `ObjectiveCConvertibleAttributedStringKey`
                        swiftVal = val
                    } else if let val = try ConvertFromObjCIfAttribute(T.self, value: value as AnyObject).attemptAction() {
                        // Attribute is only `AttributedStringKey`, so converted by casting to Value type
                        // This implicitly bridges or unboxes the value
                        swiftVal = val
                    } // else: the type was not an attribute (should never happen)
                }
                do {
                    try _openExistential(type, do: project)
                } catch let conversionError {
                    if !options.contains(.dropThrowingAttributes) {
                        throw conversionError
                    }
                }
                if let swiftVal = swiftVal {
                    contents[key.rawValue] = swiftVal
                }
            } // else, attribute is not in provided scope, so drop it
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension Dictionary where Key == NSAttributedString.Key, Value == Any {
    init(_ container: AttributeContainer) {
        var attributeKeyTypes = _loadDefaultAttributes()
        // Passing .dropThrowingAttributes causes attributes that throw during conversion to be dropped, so it is safe to do try! here
        try! self.init(container, including: AttributeScopes.FoundationAttributes.self, attributeKeyTypes: &attributeKeyTypes, options: .dropThrowingAttributes)
    }
    
    init<S: AttributeScope>(_ container: AttributeContainer, including scope: KeyPath<AttributeScopes, S.Type>) throws {
        try self.init(container, including: S.self)
    }
    
    init<S: AttributeScope>(_ container: AttributeContainer, including scope: S.Type) throws {
        var attributeKeyTypes = [String : Any.Type]()
        try self.init(container, including: scope, attributeKeyTypes: &attributeKeyTypes)
    }
    
    // These includingOnly SPI initializers were provided originally when conversion boxed attributes outside of the given scope as an AnyObject
    // After rdar://80201634, these SPI initializers have the same behavior as the API initializers
    @_spi(AttributedString)
    init<S: AttributeScope>(_ container: AttributeContainer, includingOnly scope: KeyPath<AttributeScopes, S.Type>) throws {
        try self.init(container, including: S.self)
    }
    
    @_spi(AttributedString)
    init<S: AttributeScope>(_ container: AttributeContainer, includingOnly scope: S.Type) throws {
        try self.init(container, including: S.self)
    }
    
    fileprivate init<S: AttributeScope>(_ container: AttributeContainer, including scope: S.Type, attributeKeyTypes: inout [String : Any.Type], options: _AttributeConversionOptions = []) throws {
        self.init()
        for (key, value) in container.contents {
            if let type = attributeKeyTypes[key] ?? S.attributeKeyType(matching: key) {
                attributeKeyTypes[key] = type
                var objcVal: AnyObject?
                func project<T>(_: T.Type) throws {
                    if let val = try ConvertToObjCIfObjCAttribute(T.self, value: value).attemptAction() {
                        objcVal = val
                    } else {
                        // Attribute is not `ObjectiveCConvertibleAttributedStringKey`, so cast it to AnyObject to implicitly bridge it or box it
                        objcVal = value as AnyObject
                    }
                }
                do {
                    try _openExistential(type, do: project)
                } catch let conversionError {
                    if !options.contains(.dropThrowingAttributes) {
                        throw conversionError
                    }
                }
                if let val = objcVal {
                    self[NSAttributedString.Key(rawValue: key)] = val
                }
            }
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension NSAttributedString {
    convenience init(_ attrStr: AttributedString) {
        // Passing .dropThrowingAttributes causes attributes that throw during conversion to be dropped, so it is safe to do try! here
        try! self.init(attrStr, scope: AttributeScopes.FoundationAttributes.self, otherAttributeTypes: _loadDefaultAttributes(), options: .dropThrowingAttributes)
    }
    
    convenience init<S: AttributeScope>(_ attrStr: AttributedString, including scope: KeyPath<AttributeScopes, S.Type>) throws {
        try self.init(attrStr, scope: S.self)
    }
    
    convenience init<S: AttributeScope>(_ attrStr: AttributedString, including scope: S.Type) throws {
        try self.init(attrStr, scope: scope)
    }
    
    @_spi(AttributedString)
    convenience init<S: AttributeScope>(_ attrStr: AttributedString, includingOnly scope: KeyPath<AttributeScopes, S.Type>) throws {
        try self.init(attrStr, scope: S.self)
    }
    
    @_spi(AttributedString)
    convenience init<S: AttributeScope>(_ attrStr: AttributedString, includingOnly scope: S.Type) throws {
        try self.init(attrStr, scope: scope)
    }
    
    internal convenience init<S: AttributeScope>(_ attrStr: AttributedString, scope: S.Type, otherAttributeTypes: [String : Any.Type] = [:], options: _AttributeConversionOptions = []) throws {
        let result = NSMutableAttributedString(string: attrStr._guts.string)
        var attributeKeyTypes: [String : Any.Type] = otherAttributeTypes
        // Iterate through each run of the source
        var nsStartIndex = 0
        var stringStart = attrStr._guts.string.startIndex
        for run in attrStr._guts.runs {
            let stringEnd = attrStr._guts.string.utf8.index(stringStart, offsetBy: run.length)
            let utf16Length = attrStr._guts.string.utf16.distance(from: stringStart, to: stringEnd)
            let range = NSRange(location: nsStartIndex, length: utf16Length)
            let attributes = try Dictionary(AttributeContainer(run.attributes.contents), including: scope, attributeKeyTypes: &attributeKeyTypes, options: options)
            result.setAttributes(attributes, range: range)
            nsStartIndex += utf16Length
            stringStart = stringEnd
        }
        self.init(attributedString: result)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributedString {
    init(_ nsStr: NSAttributedString) {
        // Passing .dropThrowingAttributes causes attributes that throw during conversion to be dropped, so it is safe to do try! here
        try! self.init(nsStr, scope: AttributeScopes.FoundationAttributes.self, otherAttributeTypes: _loadDefaultAttributes(), options: .dropThrowingAttributes)
    }
    
    init<S: AttributeScope>(_ nsStr: NSAttributedString, including scope: KeyPath<AttributeScopes, S.Type>) throws {
        try self.init(nsStr, scope: S.self)
    }
    
    init<S: AttributeScope>(_ nsStr: NSAttributedString, including scope: S.Type) throws {
        try self.init(nsStr, scope: S.self)
    }
    
    private init<S: AttributeScope>(_ nsStr: NSAttributedString, scope: S.Type, otherAttributeTypes: [String : Any.Type] = [:], options: _AttributeConversionOptions = []) throws {
        let string = nsStr.string
        var runs: [_InternalRun] = []
        var attributeKeyTypes: [String : Any.Type] = otherAttributeTypes
        var conversionError: Error?
        var stringStart = string.startIndex
        nsStr.enumerateAttributes(in: NSMakeRange(0, nsStr.length), options: []) { (nsAttrs, range, stop) in
            let container: AttributeContainer
            do {
                container = try AttributeContainer(nsAttrs, including: scope, attributeKeyTypes: &attributeKeyTypes, options: options)
            } catch {
                conversionError = error
                stop.pointee = true
                return
            }
            let stringEnd = string.utf16.index(stringStart, offsetBy: range.length)
            let runLength = string.utf8.distance(from: stringStart, to: stringEnd)
            let attrStorage = _AttributeStorage(container.contents)
            if let previous = runs.last, previous.attributes == attrStorage {
                runs[runs.endIndex - 1].length += runLength
            } else {
                runs.append(_InternalRun(length: runLength, attributes: attrStorage))
            }
            stringStart = stringEnd
        }
        if let error = conversionError {
            throw error
        }
        self = AttributedString(Guts(string: string, runs: runs))
    }
}

fileprivate var _loadedScopeCache = [String : [String : Any.Type]]()
fileprivate var _loadedScopeCacheLock = Lock()

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal func _loadDefaultAttributes() -> [String : Any.Type] {
    #if os(macOS)
    #if !targetEnvironment(macCatalyst)
        // AppKit scope on macOS
        let macOSSymbol = ("$s10Foundation15AttributeScopesO6AppKitE0dE10AttributesVN", "/usr/lib/swift/libswiftAppKit.dylib")
    #else
        // UIKit scope on macOS
        let macOSSymbol = ("$s10Foundation15AttributeScopesO5UIKitE0D10AttributesVN", "/System/iOSSupport/usr/lib/swift/libswiftUIKit.dylib")
    #endif

    let loadedScopes = [
        macOSSymbol,
        // UIKit scope on non-macOS
        ("$s10Foundation15AttributeScopesO5UIKitE0D10AttributesVN", "/usr/lib/swift/libswiftUIKit.dylib"),
        // SwiftUI scope
        ("$s10Foundation15AttributeScopesO7SwiftUIE0D12UIAttributesVN", "/System/Library/Frameworks/SwiftUI.framework/SwiftUI"),
        // Accessibility scope
        ("$s10Foundation15AttributeScopesO13AccessibilityE0D10AttributesVN", "/System/Library/Frameworks/Accessibility.framework/Accessibility")
    ].compactMap {
        _loadScopeAttributes(forSymbol: $0.0, from: $0.1)
    }

    return loadedScopes.reduce([:]) { result, item in
        result.merging(item) { current, new in new }
    }
    #else
    return [:]
    #endif // os(macOS)
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
fileprivate func _loadScopeAttributes(forSymbol symbol: String, from path: String) -> [String : Any.Type]? {
#if os(macOS)
    _loadedScopeCacheLock.lock()
    defer { _loadedScopeCacheLock.unlock() }
    if let cachedResult = _loadedScopeCache[symbol] {
        return cachedResult
    }
    guard let handle = dlopen(path, RTLD_NOLOAD) else {
        return nil
    }
    guard let symbolPointer = dlsym(handle, symbol) else {
        return nil
    }
    let scopeType = unsafeBitCast(symbolPointer, to: Any.Type.self)
    let attributeTypes =  _loadAttributeTypes(from: scopeType)
    _loadedScopeCache[symbol] = attributeTypes
    return attributeTypes
#else
    return nil
#endif // os(macOS)
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
fileprivate func _loadAttributeTypes(from scope: Any.Type) -> [String : Any.Type] {
    var result = [String : Any.Type]()
    _forEachField(of: scope, options: [.ignoreUnknown]) { pointer, offset, type, kind -> Bool in
        func project<K>(_: K.Type) {
            if let key = GetNameIfAttribute(K.self).attemptAction() {
                result[key] = type
            } else if let subResults = GetAllAttributeTypesIfAttributeScope(K.self).attemptAction() {
                result.merge(subResults, uniquingKeysWith: { current, new in new })
            }
        }
        _openExistential(type, do: project)
        return true
    }
    return result
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension String.Index {
    public init?<S: StringProtocol>(_ sourcePosition: AttributedString.Index, within target: S) {
        self.init(sourcePosition.characterIndex, within: target)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedString.Index {
    public init?<S: AttributedStringProtocol>(_ sourcePosition: String.Index, within target: S) {
        guard let strIndex = String.Index(sourcePosition, within: target.__guts.string) else {
            return nil
        }
        self.init(characterIndex: strIndex)
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension NSRange {
    public init<R: RangeExpression, S: AttributedStringProtocol>(_ region: R, in target: S) where R.Bound == AttributedString.Index {
        let str = target.__guts.string
        let r = region.relative(to: target.characters)._stringRange.relative(to: str)
        self.init(str._toUTF16Offsets(r))
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Range where Bound == AttributedString.Index {
    public init?<S: AttributedStringProtocol>(_ range: NSRange, in attrStr: S) {
        if let r = Range<String.Index>(range, in: attrStr.__guts.string) {
            self = r._attributedStringRange
        } else {
            return nil
        }
    }
    public init?<R: RangeExpression, S: AttributedStringProtocol>(_ region: R, in attrStr: S) where R.Bound == String.Index {
        let range = region.relative(to: attrStr.__guts.string)
        if let lwr = Bound(range.lowerBound, within: attrStr), let upr = Bound(range.upperBound, within: attrStr) {
            self = lwr ..< upr
        } else {
            return nil
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Range where Bound == String.Index {
    public init?<R: RangeExpression, S: StringProtocol>(_ region: R, in string: S) where R.Bound == AttributedString.Index {
        let range = region.relative(to: AttributedString(string).characters)
        if let lwr = Bound(range.lowerBound, within: string), let upr = Bound(range.upperBound, within: string) {
            self = lwr ..< upr
        } else {
            return nil
        }
    }
}
