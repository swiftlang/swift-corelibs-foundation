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

@dynamicMemberLookup
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public struct AttributeContainer : Equatable, CustomStringConvertible {
    public static func == (lhs: AttributeContainer, rhs: AttributeContainer) -> Bool {
        guard lhs.contents.keys == rhs.contents.keys else { return false }
        for (key, value) in lhs.contents {
            if !__equalAttributes(value, rhs.contents[key]) {
                return false
            }
        }
        return true
    }
    
    public var description : String {
        contents._attrStrDescription
    }
    
    internal var contents : [String : Any]

    public subscript<T: AttributedStringKey>(_: T.Type) -> T.Value? {
        get { contents[T.name] as? T.Value }
        set { contents[T.name] = newValue }
    }

    public subscript<K: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeDynamicLookup, K>) -> K.Value? {
        get { self[K.self] }
        set { self[K.self] = newValue }
    }
    
    public subscript<S: AttributeScope>(dynamicMember keyPath: KeyPath<AttributeScopes, S.Type>) -> ScopedAttributeContainer<S> {
        get {
            return ScopedAttributeContainer(contents)
        }
        _modify {
            var container = ScopedAttributeContainer<S>()
            defer {
                if let removedKey = container.removedKey {
                    contents[removedKey] = nil
                } else {
                    contents.merge(container.contents) { original, new in
                        return new
                    }
                }
            }
            yield &container
        }
    }

    public static subscript<K: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeDynamicLookup, K>) -> Builder<K> {
        return Builder(container: AttributeContainer())
    }

    @_disfavoredOverload
    public subscript<K: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeDynamicLookup, K>) -> Builder<K> {
        return Builder(container: self)
    }

    public struct Builder<T: AttributedStringKey> {
        var container : AttributeContainer

        public func callAsFunction(_ value: T.Value) -> AttributeContainer {
            var new = container
            new[T.self] = value
            return new
        }
    }

    public init() {
        contents = [:]
    }
    
    internal init(_ contents: [String : Any]) {
        self.contents = contents
    }

    public mutating func merge(_ other: AttributeContainer, mergePolicy: AttributedString.AttributeMergePolicy = .keepNew) {
        self.contents.merge(other.contents, uniquingKeysWith: mergePolicy.combinerClosure)
    }
    
    public func merging(_ other: AttributeContainer, mergePolicy:  AttributedString.AttributeMergePolicy = .keepNew) -> AttributeContainer {
        var copy = self
        copy.merge(other, mergePolicy:  mergePolicy)
        return copy
    }
}

internal extension Dictionary where Key == String, Value == Any {
    var _attrStrDescription : String {
        let keyvals = self.reduce(into: "") { (res, entry) in
            res += "\t\(entry.key) = \(entry.value)" + "\n"
        }
        return "{\n\(keyvals)}"
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol AttributedStringAttributeMutation {
    mutating func setAttributes(_ attributes: AttributeContainer)
    mutating func mergeAttributes(_ attributes: AttributeContainer, mergePolicy:  AttributedString.AttributeMergePolicy)
    mutating func replaceAttributes(_ attributes: AttributeContainer, with others: AttributeContainer)
}

@dynamicMemberLookup
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public protocol AttributedStringProtocol : AttributedStringAttributeMutation, Hashable, CustomStringConvertible {
    var startIndex : AttributedString.Index { get }
    var endIndex : AttributedString.Index { get }
    
    var runs : AttributedString.Runs { get }
    var characters : AttributedString.CharacterView { get }
    var unicodeScalars : AttributedString.UnicodeScalarView { get }
    
    subscript<K: AttributedStringKey>(_: K.Type) -> K.Value? { get set }
    subscript<K: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeDynamicLookup, K>) -> K.Value? { get set }
    subscript<S: AttributeScope>(dynamicMember keyPath: KeyPath<AttributeScopes, S.Type>) -> ScopedAttributeContainer<S> { get set }
    
    subscript<R: RangeExpression>(bounds: R) -> AttributedSubstring where R.Bound == AttributedString.Index { get }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedString {
    internal init<S:AttributedStringProtocol>(_ s: S) {
        if let s = s as? AttributedString {
            self = s
        } else if let s = s as? AttributedSubstring {
            self = AttributedString(s)
        } else {
            // !!!: We don't expect or want this to happen.
            self = AttributedString(s.characters._guts)
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributedStringProtocol {
    func settingAttributes(_ attributes: AttributeContainer) -> AttributedString {
        var new = AttributedString(self)
        new.setAttributes(attributes)
        return new
    }
    
    func mergingAttributes(_ attributes: AttributeContainer, mergePolicy:  AttributedString.AttributeMergePolicy = .keepNew) -> AttributedString {
        var new = AttributedString(self)
        new.mergeAttributes(attributes, mergePolicy:  mergePolicy)
        return new
    }
    
    func replacingAttributes(_ attributes: AttributeContainer, with others: AttributeContainer) -> AttributedString {
        var new = AttributedString(self)
        new.replaceAttributes(attributes, with: others)
        return new
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedStringProtocol {
    internal var __guts : AttributedString.Guts {
        if let s = self as? AttributedString {
            return s._guts
        } else if let s = self as? AttributedSubstring {
            return s._guts
        } else {
            return self.characters._guts
        }
    }
    
    public var description : String {
        var result = ""
        self.__guts.enumerateRuns { run, loc, _, modified in
            let range = self.__guts.index(startIndex, offsetByUTF8: loc) ..< self.__guts.index(startIndex, offsetByUTF8: loc + run.length)
            result += (result.isEmpty ? "" : "\n") + "\(String(self.characters[range])) \(run.attributes)"
            modified = .guaranteedNotModified
        }
        return result
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(__guts)
    }

    @_specialize(where Self == AttributedString, RHS == AttributedString)
    @_specialize(where Self == AttributedString, RHS == AttributedSubstring)
    @_specialize(where Self == AttributedSubstring, RHS == AttributedString)
    @_specialize(where Self == AttributedSubstring, RHS == AttributedSubstring)
    public static func == <RHS: AttributedStringProtocol>(lhs: Self, rhs: RHS) -> Bool {
        // Manually slice the __guts.string (in case its an AttributedSubstring), the Runs type takes the range into account for AttributedSubstrings
        let rangeLHS = Range(uncheckedBounds: (lower: lhs.startIndex, upper: lhs.endIndex))
        let rangeRHS = Range(uncheckedBounds: (lower: rhs.startIndex, upper: rhs.endIndex))
        return lhs.__guts.string[rangeLHS._stringRange] == rhs.__guts.string[rangeRHS._stringRange] && lhs.runs == rhs.runs
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributedStringProtocol {
    func index(afterCharacter i: AttributedString.Index) -> AttributedString.Index {
        self.characters.index(after: i)
    }
    func index(beforeCharacter i: AttributedString.Index) -> AttributedString.Index {
        self.characters.index(before: i)
    }
    func index(_ i: AttributedString.Index, offsetByCharacters distance: Int) -> AttributedString.Index {
        self.characters.index(i, offsetBy: distance)
    }

    func index(afterUnicodeScalar i: AttributedString.Index) -> AttributedString.Index {
        self.unicodeScalars.index(after: i)
    }
    func index(beforeUnicodeScalar i: AttributedString.Index) -> AttributedString.Index {
        self.unicodeScalars.index(before: i)
    }
    func index(_ i: AttributedString.Index, offsetByUnicodeScalars distance: Int) -> AttributedString.Index {
        self.unicodeScalars.index(i, offsetBy: distance)
    }

    func index(afterRun i: AttributedString.Index) -> AttributedString.Index {
        self.runs._runs_index(after: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [])
    }
    func index(beforeRun i: AttributedString.Index) -> AttributedString.Index {
        self.runs._runs_index(before: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [])
    }
    func index(_ i: AttributedString.Index, offsetByRuns distance: Int) -> AttributedString.Index {
        var res = i
        var remainingDistance = distance
        while remainingDistance != 0 {
            if remainingDistance > 0 {
                res = self.runs._runs_index(after: res, startIndex: startIndex, endIndex: endIndex, attributeNames: [])
                remainingDistance -= 1
            } else {
                res = self.runs._runs_index(before: res, startIndex: startIndex, endIndex: endIndex, attributeNames: [])
                remainingDistance += 1
            }
        }
        return res
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedStringProtocol {
    public func range<T: StringProtocol>(of stringToFind: T, options: String.CompareOptions = [], locale: Locale? = nil) -> Range<AttributedString.Index>? {
        // Since we have secret access to the String property, go ahead and use the full implementation given by Foundation rather than the limited reimplementation we needed for CharacterView.
        return self.__guts.string.range(of: stringToFind, options: options, range: (startIndex..<endIndex)._stringRange, locale: locale)?._attributedStringRange
    }
}

@dynamicMemberLookup
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public struct AttributedString : AttributedStringProtocol {
    
    public enum AttributeMergePolicy {
        case keepNew
        case keepCurrent
        
        internal var combinerClosure: (Any, Any) -> Any {
            switch self {
            case .keepNew: return { _, new in new }
            case .keepCurrent: return { current, _ in current }
            }
        }
    }
    
    public subscript<K: AttributedStringKey>(_: K.Type) -> K.Value? {
        get { _guts.getValue(in: startIndex ..< endIndex, key: K.name) as? K.Value }
        set {
            ensureUniqueReference()
            if let v = newValue {
                _guts.add(value: v, in: startIndex ..< endIndex, key: K.name)
            } else {
                _guts.remove(attribute: K.self, in: startIndex ..< endIndex)
            }
        }
    }

    public subscript<K: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeDynamicLookup, K>) -> K.Value? {
        get { self[K.self] }
        set { self[K.self] = newValue }
    }
    
    public subscript<S: AttributeScope>(dynamicMember keyPath: KeyPath<AttributeScopes, S.Type>) -> ScopedAttributeContainer<S> {
        get {
            return ScopedAttributeContainer(_guts.getValues(in: startIndex ..< endIndex))
        }
        _modify {
            ensureUniqueReference()
            var container = ScopedAttributeContainer<S>()
            defer {
                if let removedKey = container.removedKey {
                    _guts.remove(key: removedKey, in: startIndex ..< endIndex)
                } else {
                    _guts.add(attributes: AttributeContainer(container.contents), in: startIndex ..< endIndex)
                }
            }
            yield &container
        }
    }
    
    public mutating func setAttributes(_ attributes: AttributeContainer) {
        ensureUniqueReference()
        _guts.set(attributes: attributes, in: startIndex ..< endIndex)
    }
    
    public mutating func mergeAttributes(_ attributes: AttributeContainer, mergePolicy:  AttributeMergePolicy = .keepNew) {
        ensureUniqueReference()
        _guts.add(attributes: attributes, in: startIndex ..< endIndex, mergePolicy:  mergePolicy)
    }
    
    public mutating func replaceAttributes(_ attributes: AttributeContainer, with others: AttributeContainer) {
        guard attributes != others else {
            return
        }
        ensureUniqueReference()
        _guts.enumerateRuns { run, _, _, modified in
            if _run(run, matches: attributes) {
                for key in attributes.contents.keys {
                    run.attributes.contents.removeValue(forKey: key)
                }
                run.attributes.mergeIn(others)
                modified = .guaranteedModified
            } else {
                modified = .guaranteedNotModified
            }
        }
    }
    
    internal func applyRemovals<K>(withOriginal orig: AttributedString.SingleAttributeTransformer<K>, andChanged changed: AttributedString.SingleAttributeTransformer<K>, to attrStr: inout AttributedString, key: K.Type) {
        if orig.range != changed.range || orig.attrName != changed.attrName {
            attrStr._guts.remove(attribute: K.self, in: orig.range) // If the range changed, we need to remove from the old range first.
        }
    }
    
    internal func applyChanges<K>(withOriginal orig: AttributedString.SingleAttributeTransformer<K>, andChanged changed: AttributedString.SingleAttributeTransformer<K>, to attrStr: inout AttributedString, key: K.Type) {
        if orig.range != changed.range || orig.attrName != changed.attrName || !__equalAttributes(orig.attr, changed.attr) {
            if let newVal = changed.attr { // Then if there's a new value, we add it in.
                // Unfortunately, we can't use the attrStr[range].set() provided by the AttributedStringProtocol, because we *don't know* the new type statically!
                attrStr._guts.add(value: newVal, in: changed.range, key: changed.attrName)
            } else {
                attrStr._guts.remove(attribute: K.self, in: changed.range) // ???: Is this right? Does changing the range of an attribute==nil run remove it from the new range?
            }
        }
    }

    public func transformingAttributes<K>(_ k:  K.Type, _ c: (inout AttributedString.SingleAttributeTransformer<K>) -> Void) -> AttributedString {
        let orig = AttributedString(_guts)
        var copy = orig
        copy.ensureUniqueReference() // ???: Is this best practice? We're going behind the back of the AttributedString mutation API surface, so it doesn't happen anywhere else. It's also aggressively speculative.
        for (attr, range) in orig.runs[k] {
            let origAttr1 = AttributedString.SingleAttributeTransformer<K>(range: range, attr: attr)
            var changedAttr1 = origAttr1
            c(&changedAttr1)
            applyRemovals(withOriginal: origAttr1, andChanged: changedAttr1, to: &copy, key: k)
            applyChanges(withOriginal: origAttr1, andChanged: changedAttr1, to: &copy, key: k)
        }
        return copy
    }

    public func transformingAttributes<K1, K2>(_ k:  K1.Type, _ k2: K2.Type,
                                                   _ c: (inout AttributedString.SingleAttributeTransformer<K1>,
                                                         inout AttributedString.SingleAttributeTransformer<K2>) -> Void) -> AttributedString {
        let orig = AttributedString(_guts)
        var copy = orig
        copy.ensureUniqueReference() // ???: Is this best practice? We're going behind the back of the AttributedString mutation API surface, so it doesn't happen anywhere else. It's also aggressively speculative.
        for (attr, attr2, range) in orig.runs[k, k2] {
            let origAttr1 = AttributedString.SingleAttributeTransformer<K1>(range: range, attr: attr)
            let origAttr2 = AttributedString.SingleAttributeTransformer<K2>(range: range, attr: attr2)
            var changedAttr1 = origAttr1
            var changedAttr2 = origAttr2
            c(&changedAttr1, &changedAttr2)
            applyRemovals(withOriginal: origAttr1, andChanged: changedAttr1, to: &copy, key: k)
            applyRemovals(withOriginal: origAttr2, andChanged: changedAttr2, to: &copy, key: k2)
            applyChanges(withOriginal: origAttr1, andChanged: changedAttr1, to: &copy, key: k)
            applyChanges(withOriginal: origAttr2, andChanged: changedAttr2, to: &copy, key: k2)
        }
        return copy
    }

    public func transformingAttributes<K1, K2, K3>(_ k:  K1.Type, _ k2: K2.Type, _ k3: K3.Type,
                                                   _ c: (inout AttributedString.SingleAttributeTransformer<K1>,
                                                         inout AttributedString.SingleAttributeTransformer<K2>,
                                                         inout AttributedString.SingleAttributeTransformer<K3>) -> Void) -> AttributedString {
        let orig = AttributedString(_guts)
        var copy = orig
        copy.ensureUniqueReference() // ???: Is this best practice? We're going behind the back of the AttributedString mutation API surface, so it doesn't happen anywhere else. It's also aggressively speculative.
        for (attr, attr2, attr3, range) in orig.runs[k, k2, k3] {
            let origAttr1 = AttributedString.SingleAttributeTransformer<K1>(range: range, attr: attr)
            let origAttr2 = AttributedString.SingleAttributeTransformer<K2>(range: range, attr: attr2)
            let origAttr3 = AttributedString.SingleAttributeTransformer<K3>(range: range, attr: attr3)
            var changedAttr1 = origAttr1
            var changedAttr2 = origAttr2
            var changedAttr3 = origAttr3
            c(&changedAttr1, &changedAttr2, &changedAttr3)
            applyRemovals(withOriginal: origAttr1, andChanged: changedAttr1, to: &copy, key: k)
            applyRemovals(withOriginal: origAttr2, andChanged: changedAttr2, to: &copy, key: k2)
            applyRemovals(withOriginal: origAttr3, andChanged: changedAttr3, to: &copy, key: k3)
            applyChanges(withOriginal: origAttr1, andChanged: changedAttr1, to: &copy, key: k)
            applyChanges(withOriginal: origAttr2, andChanged: changedAttr2, to: &copy, key: k2)
            applyChanges(withOriginal: origAttr3, andChanged: changedAttr3, to: &copy, key: k3)
        }
        return copy
    }

    public func transformingAttributes<K1, K2, K3, K4>(_ k:  K1.Type, _ k2: K2.Type, _ k3: K3.Type, _ k4: K4.Type,
                                                       _ c: (inout AttributedString.SingleAttributeTransformer<K1>,
                                                             inout AttributedString.SingleAttributeTransformer<K2>,
                                                             inout AttributedString.SingleAttributeTransformer<K3>,
                                                             inout AttributedString.SingleAttributeTransformer<K4>) -> Void) -> AttributedString {
        let orig = AttributedString(_guts)
        var copy = orig
        copy.ensureUniqueReference() // ???: Is this best practice? We're going behind the back of the AttributedString mutation API surface, so it doesn't happen anywhere else. It's also aggressively speculative.
        for (attr, attr2, attr3, attr4, range) in orig.runs[k, k2, k3, k4] {
            let origAttr1 = AttributedString.SingleAttributeTransformer<K1>(range: range, attr: attr)
            let origAttr2 = AttributedString.SingleAttributeTransformer<K2>(range: range, attr: attr2)
            let origAttr3 = AttributedString.SingleAttributeTransformer<K3>(range: range, attr: attr3)
            let origAttr4 = AttributedString.SingleAttributeTransformer<K4>(range: range, attr: attr4)
            var changedAttr1 = origAttr1
            var changedAttr2 = origAttr2
            var changedAttr3 = origAttr3
            var changedAttr4 = origAttr4
            c(&changedAttr1, &changedAttr2, &changedAttr3, &changedAttr4)
            applyRemovals(withOriginal: origAttr1, andChanged: changedAttr1, to: &copy, key: k)
            applyRemovals(withOriginal: origAttr2, andChanged: changedAttr2, to: &copy, key: k2)
            applyRemovals(withOriginal: origAttr3, andChanged: changedAttr3, to: &copy, key: k3)
            applyRemovals(withOriginal: origAttr4, andChanged: changedAttr4, to: &copy, key: k4)
            applyChanges(withOriginal: origAttr1, andChanged: changedAttr1, to: &copy, key: k)
            applyChanges(withOriginal: origAttr2, andChanged: changedAttr2, to: &copy, key: k2)
            applyChanges(withOriginal: origAttr3, andChanged: changedAttr3, to: &copy, key: k3)
            applyChanges(withOriginal: origAttr4, andChanged: changedAttr4, to: &copy, key: k4)
        }
        return copy
    }

    public func transformingAttributes<K1, K2, K3, K4, K5>(_ k:  K1.Type, _ k2: K2.Type, _ k3: K3.Type, _ k4: K4.Type, _ k5: K5.Type,
                                                           _ c: (inout AttributedString.SingleAttributeTransformer<K1>,
                                                                 inout AttributedString.SingleAttributeTransformer<K2>,
                                                                 inout AttributedString.SingleAttributeTransformer<K3>,
                                                                 inout AttributedString.SingleAttributeTransformer<K4>,
                                                                 inout AttributedString.SingleAttributeTransformer<K5>) -> Void) -> AttributedString {
        let orig = AttributedString(_guts)
        var copy = orig
        copy.ensureUniqueReference() // ???: Is this best practice? We're going behind the back of the AttributedString mutation API surface, so it doesn't happen anywhere else. It's also aggressively speculative.
        for (attr, attr2, attr3, attr4, attr5, range) in orig.runs[k, k2, k3, k4, k5] {
            let origAttr1 = AttributedString.SingleAttributeTransformer<K1>(range: range, attr: attr)
            let origAttr2 = AttributedString.SingleAttributeTransformer<K2>(range: range, attr: attr2)
            let origAttr3 = AttributedString.SingleAttributeTransformer<K3>(range: range, attr: attr3)
            let origAttr4 = AttributedString.SingleAttributeTransformer<K4>(range: range, attr: attr4)
            let origAttr5 = AttributedString.SingleAttributeTransformer<K5>(range: range, attr: attr5)
            var changedAttr1 = origAttr1
            var changedAttr2 = origAttr2
            var changedAttr3 = origAttr3
            var changedAttr4 = origAttr4
            var changedAttr5 = origAttr5
            c(&changedAttr1, &changedAttr2, &changedAttr3, &changedAttr4, &changedAttr5)
            applyRemovals(withOriginal: origAttr1, andChanged: changedAttr1, to: &copy, key: k)
            applyRemovals(withOriginal: origAttr2, andChanged: changedAttr2, to: &copy, key: k2)
            applyRemovals(withOriginal: origAttr3, andChanged: changedAttr3, to: &copy, key: k3)
            applyRemovals(withOriginal: origAttr4, andChanged: changedAttr4, to: &copy, key: k4)
            applyRemovals(withOriginal: origAttr5, andChanged: changedAttr5, to: &copy, key: k5)
            applyChanges(withOriginal: origAttr1, andChanged: changedAttr1, to: &copy, key: k)
            applyChanges(withOriginal: origAttr2, andChanged: changedAttr2, to: &copy, key: k2)
            applyChanges(withOriginal: origAttr3, andChanged: changedAttr3, to: &copy, key: k3)
            applyChanges(withOriginal: origAttr4, andChanged: changedAttr4, to: &copy, key: k4)
            applyChanges(withOriginal: origAttr5, andChanged: changedAttr5, to: &copy, key: k5)
        }
        return copy
    }
    
    public func transformingAttributes<K>(_ k: KeyPath<AttributeDynamicLookup, K>, _ c: (inout AttributedString.SingleAttributeTransformer<K>) -> Void) -> AttributedString {
        self.transformingAttributes(K.self, c)
    }
    
    public func transformingAttributes<K1, K2>(
        _ k:  KeyPath<AttributeDynamicLookup, K1>,
        _ k2: KeyPath<AttributeDynamicLookup, K2>, _ c: (inout AttributedString.SingleAttributeTransformer<K1>,
                                                         inout AttributedString.SingleAttributeTransformer<K2>) -> Void) -> AttributedString {
        self.transformingAttributes(K1.self, K2.self, c)
    }
    
    public func transformingAttributes<K1, K2, K3>(
        _ k:  KeyPath<AttributeDynamicLookup, K1>,
        _ k2: KeyPath<AttributeDynamicLookup, K2>,
        _ k3: KeyPath<AttributeDynamicLookup, K3>, _ c: (inout AttributedString.SingleAttributeTransformer<K1>,
                                                         inout AttributedString.SingleAttributeTransformer<K2>,
                                                         inout AttributedString.SingleAttributeTransformer<K3>) -> Void) -> AttributedString {
        self.transformingAttributes(K1.self, K2.self, K3.self, c)
    }
    
    public func transformingAttributes<K1, K2, K3, K4>(
        _ k:  KeyPath<AttributeDynamicLookup, K1>,
        _ k2: KeyPath<AttributeDynamicLookup, K2>,
        _ k3: KeyPath<AttributeDynamicLookup, K3>,
        _ k4: KeyPath<AttributeDynamicLookup, K4>, _ c: (inout AttributedString.SingleAttributeTransformer<K1>,
                                                         inout AttributedString.SingleAttributeTransformer<K2>,
                                                         inout AttributedString.SingleAttributeTransformer<K3>,
                                                         inout AttributedString.SingleAttributeTransformer<K4>) -> Void) -> AttributedString {
        self.transformingAttributes(K1.self, K2.self, K3.self, K4.self, c)
    }
    
    public func transformingAttributes<K1, K2, K3, K4, K5>(
        _ k:  KeyPath<AttributeDynamicLookup, K1>,
        _ k2: KeyPath<AttributeDynamicLookup, K2>,
        _ k3: KeyPath<AttributeDynamicLookup, K3>,
        _ k4: KeyPath<AttributeDynamicLookup, K4>,
        _ k5: KeyPath<AttributeDynamicLookup, K5>, _ c: (inout AttributedString.SingleAttributeTransformer<K1>,
                                                         inout AttributedString.SingleAttributeTransformer<K2>,
                                                         inout AttributedString.SingleAttributeTransformer<K3>,
                                                         inout AttributedString.SingleAttributeTransformer<K4>,
                                                         inout AttributedString.SingleAttributeTransformer<K5>) -> Void) -> AttributedString {
        self.transformingAttributes(K1.self, K2.self, K3.self, K4.self, K5.self, c)

    }
    
    internal struct _AttributeStorage : Hashable, CustomStringConvertible {
        internal var contents : [String : Any]
        
        subscript <T: AttributedStringKey>(_ attribute: T.Type) -> T.Value? {
            get { self.contents[T.name] as? T.Value }
            set { self.contents[T.name] = newValue }
        }
        
        internal mutating func mergeIn(_ otherContents: [String: Any]) {
            for (key, value) in otherContents {
                contents[key] = value
            }
        }
        
        internal mutating func mergeIn(_ otherContents: [String: Any], uniquingKeysWith: (Any, Any) -> Any) {
            contents.merge(otherContents, uniquingKeysWith: uniquingKeysWith)
        }
        
        internal mutating func mergeIn(_ other: _AttributeStorage) {
            self.mergeIn(other.contents)
        }
        
        internal mutating func mergeIn(_ other: AttributeContainer) {
            self.mergeIn(other.contents)
        }
        
        public init(_ contents: [String : Any] = [:]) {
            self.contents = contents
        }
        
        public static func == (lhs: AttributedString._AttributeStorage, rhs: AttributedString._AttributeStorage) -> Bool {
            guard lhs.contents.keys == rhs.contents.keys else {
                return false
            }
            for (key, value) in lhs.contents {
                if !__equalAttributes(value, rhs.contents[key]) {
                    return false
                }
            }
            return true
        }
        
        public var description : String {
            contents._attrStrDescription
        }
        
        public func hash(into hasher: inout Hasher) {
            let c = contents as! [String : AnyHashable]
            c.hash(into: &hasher)
        }
    }
    
    public struct SingleAttributeTransformer<T: AttributedStringKey> {
        public var range: Range<Index>
        
        internal var attrName = T.name
        internal var attr : Any?
        
        public var value: T.Value? {
            get { attr as? T.Value }
            set { attr = newValue }
        }
        
        public mutating func replace<U: AttributedStringKey>(with key: U.Type, value: U.Value) {
            attrName = key.name
            attr = value
        }

        public mutating func replace<U: AttributedStringKey>(with keyPath: KeyPath<AttributeDynamicLookup, U>, value: U.Value) {
            self.replace(with: U.self, value: value)
        }
    }
        
    public struct Index : Comparable {
        internal let characterIndex: String.Index
        public static func < (lhs: AttributedString.Index, rhs: AttributedString.Index) -> Bool {
            return lhs.characterIndex < rhs.characterIndex
        }
    }

    internal struct _InternalRun : Hashable {
        // UTF-8 Code Unit Length
        internal var length : Int
        internal var attributes : _AttributeStorage
        
        public static func == (lhs: _InternalRun, rhs: _InternalRun) -> Bool {
            if lhs.length != rhs.length {
                return false
            }
            return lhs.attributes == rhs.attributes
        }
        
        public func get<T: AttributedStringKey>(_ k: T.Type) -> T.Value? {
            attributes[k]
        }
    }
    
    internal class Guts : Hashable {
        var string : String
        
        // NOTE: the runs and runOffsetCache should never be modified directly. Instead, use the functions defined in AttributedStringRunCoalescing.swift
        var runs : [_InternalRun]
        var runOffsetCache : RunOffset
        var runOffsetCacheLock : Lock
        
        static func == (lhs: AttributedString.Guts, rhs: AttributedString.Guts) -> Bool {
            return lhs.string == rhs.string && lhs.runs == rhs.runs
        }
        
        init(string: String, runs : [_InternalRun]) {
            precondition(string.isEmpty == runs.isEmpty, "An empty attributed string should not contain any runs")
            self.string = string
            self.runs = runs
            runOffsetCache = RunOffset()
            runOffsetCacheLock = Lock()
            // Ensure the string is a native contiguous string to prevent performance issues when indexing via offsets
            self.string.makeContiguousUTF8()
        }
        
        init(_ guts: Guts, range: Range<Index>) {
            string = String(guts.string[range._stringRange])
            runs = guts.runs(in: range, relativeTo: string)
            runOffsetCache = RunOffset()
            runOffsetCacheLock = Lock()
        }
        
        init(_ guts: Guts) {
            string = guts.string
            runs = guts.runs
            runOffsetCache = RunOffset()
            runOffsetCacheLock = Lock()
        }
        
        deinit {
            runOffsetCacheLock.cleanupLock()
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(string)
            hasher.combine(runs)
        }
        
        var startIndex : Index {
            Index(characterIndex: string.startIndex)
        }
        
        var endIndex : Index {
            Index(characterIndex: string.endIndex)
        }
        
        func index(byCharactersAfter i: Index) -> Index {
            return Index(characterIndex: string.index(after: i.characterIndex))
        }
        
        func index(byCharactersBefore i: Index) -> Index {
            return Index(characterIndex: string.index(before: i.characterIndex))
        }
        
        func index(byUTF8Before i: Index) -> Index {
            return Index(characterIndex: string.utf8.index(before: i.characterIndex))
        }
        
        func index(for utf8Offset: Int) -> Index {
            return index(startIndex, offsetByUTF8: utf8Offset)
        }
        
        func index(_ i: Index, offsetByUTF8 distance: Int) -> Index {
            return Index(characterIndex: string.utf8.index(i.characterIndex, offsetBy: distance))
        }
        
        func utf8OffsetRange(from range: Range<Index>) -> Range<Int> {
            return utf8Distance(from: startIndex, to: range.lowerBound) ..< utf8Distance(from: startIndex, to: range.upperBound)
        }
        
        func utf8Distance(from: Index, to: Index) -> Int {
            return string.utf8.distance(from: from.characterIndex, to: to.characterIndex)
        }
        
        func boundsCheck(_ idx: AttributedString.Index) {
            precondition(idx.characterIndex >= string.startIndex && idx.characterIndex <= string.endIndex, "AttributedString index is out of bounds")
        }
        
        func boundsCheck(_ range: Range<AttributedString.Index>) {
            precondition(range.lowerBound.characterIndex >= string.startIndex && range.upperBound.characterIndex <= string.endIndex, "AttributedString index range is out of bounds")
        }
        
        func boundsCheck(_ idx: Runs.Index) {
            precondition(idx.rangeIndex >= 0 && idx.rangeIndex < runs.count, "AttributedString.Runs index is out of bounds")
        }
        
        func run(at position: Runs.Index, clampedBy range: Range<AttributedString.Index>) -> Runs.Run {
            boundsCheck(position)
            let (internalRun, loc) = runAndLocation(at: position.rangeIndex)
            let result = Runs.Run(_internal: internalRun, _rangeOrStartIndex: .startIndex(index(for: loc)), _guts: self)
            return result.run(clampedTo: range)
            
        }
        
        func run(at position: AttributedString.Index, clampedBy clampRange: Range<AttributedString.Index>) -> (_InternalRun, Range<AttributedString.Index>) {
            boundsCheck(position)
            let location = utf8Distance(from: startIndex, to: position)
            let (run, startIdx) = runAndLocation(containing: location)
            let start = index(for: startIdx)
            let end = index(for: startIdx + run.length)
            return (run, (start ..< end).clamped(to: clampRange))
        }
        
        func indexOfRun(at position: AttributedString.Index) -> Runs.Index {
            boundsCheck(position)
            // !!!: Blech
            if position == self.endIndex {
                return Runs.Index(rangeIndex: runs.endIndex)
            }
            
            return Runs.Index(rangeIndex: indexOfRun(containing: utf8Distance(from: startIndex, to: position)))
        }
        
        // Returns all the runs in the receiver, in the given range.
        func runs(in range: Range<Index>, relativeTo newString: String) -> [_InternalRun] {
            let lowerBound = utf8Distance(from: startIndex, to: range.lowerBound)
            let upperBound = lowerBound + utf8Distance(from: range.lowerBound, to: range.upperBound)
            return runs(containing: lowerBound ..< upperBound)
        }

        func getValue(at index: Index, key: String) -> Any? {
            run(containing: utf8Distance(from: startIndex, to: index)).attributes.contents[key]
        }

        func getValue(in range: Range<Index>, key: String) -> Any? {
            var result : Any? = nil
            let lowerBound = utf8Distance(from: startIndex, to: range.lowerBound)
            let upperBound = lowerBound + utf8Distance(from: range.lowerBound, to: range.upperBound)
            enumerateRuns(containing: lowerBound ..< upperBound) { run, location, stop, modified in
                modified = .guaranteedNotModified
                guard let value = run.attributes.contents[key] else {
                    result = nil
                    stop = true
                    return
                }
                
                if let previous = result, !__equalAttributes(previous, value) {
                    result = nil
                    stop = true
                    return
                }
                result = value
            }
            return result
        }
        
        func getValues(in range: Range<Index>) -> [String : Any] {
            var contents = [String : Any]()
            let lowerBound = utf8Distance(from: startIndex, to: range.lowerBound)
            let upperBound = lowerBound + utf8Distance(from: range.lowerBound, to: range.upperBound)
            enumerateRuns(containing: lowerBound ..< upperBound) { run, _, stop, modification in
                modification = .guaranteedNotModified
                if contents.isEmpty {
                    contents = run.attributes.contents
                } else {
                    contents = contents.filter {
                        run.attributes.contents.keys.contains($0.key) && __equalAttributes($0.value, run.attributes.contents[$0.key])
                    }
                }
                if contents.isEmpty {
                    stop = true
                }
            }
            return contents
        }

        func add(value: Any, in range: Range<Index>, key: String) {
            self.enumerateRuns(containing: utf8OffsetRange(from: range)) { run, _, _, _ in
                run.attributes.contents[key] = value
            }
        }
        
        func add(attributes: AttributeContainer, in range: Range<Index>, mergePolicy:  AttributeMergePolicy = .keepNew) {
            let newAttrDict = attributes.contents
            let closure = mergePolicy.combinerClosure
            self.enumerateRuns(containing: utf8OffsetRange(from: range)) { run, _, _, _ in
                run.attributes.mergeIn(newAttrDict, uniquingKeysWith: closure)
            }
        }
        
        func set(attributes: AttributeContainer, in range: Range<Index>) {
            let newAttrDict = attributes.contents
            let range = utf8OffsetRange(from: range)
            self.replaceRunsSubrange(locations: range, with: [_InternalRun(length: range.endIndex - range.startIndex, attributes: _AttributeStorage(newAttrDict))])
        }
        
        func remove<T : AttributedStringKey>(attribute: T.Type, in range: Range<Index>) {
            self.enumerateRuns(containing: utf8OffsetRange(from: range)) { run, _, _, _ in
                run.attributes.contents[T.name] = nil
            }
        }
        
        func remove(key: String, in range: Range<Index>) {
            self.enumerateRuns(containing: utf8OffsetRange(from: range)) { run, _, _, _ in
                run.attributes.contents[key] = nil
            }
        }
                
        func replaceSubrange<S: AttributedStringProtocol>(_ range: Range<Index>, with s: S) {
            let otherStringRange = s.startIndex.characterIndex ..< s.endIndex.characterIndex
            let thisStringRange = range._stringRange
            let otherString = s.__guts.string[otherStringRange]
            let lowerBound = utf8Distance(from: startIndex, to: range.lowerBound)
            let upperBound = lowerBound + utf8Distance(from: range.lowerBound, to: range.upperBound)
            if string[thisStringRange] != otherString {
                // Faster to allocate and pass String(otherString) than pass otherString because taking
                // replaceSubrange's fast paths for String objects is better than not allocating a String
                string.replaceSubrange(thisStringRange, with: String(otherString))
            }
            let otherLowerBound = utf8Distance(from: s.__guts.startIndex, to: s.startIndex)
            let otherUpperBound = otherLowerBound + utf8Distance(from: s.startIndex, to: s.endIndex)
            self.replaceRunsSubrange(locations: lowerBound ..< upperBound, with: s.__guts.runs(containing: otherLowerBound ..< otherUpperBound))
        }
        
        func attributesToUseForReplacement(in range: Range<Index>) -> _AttributeStorage {
            guard !self.string.isEmpty else {
                return _AttributeStorage()
            }
            if !range.isEmpty {
                return self.run(at: range.lowerBound, clampedBy: self.startIndex ..< self.endIndex).0.attributes
            } else if range.lowerBound > self.startIndex {
                let prevIndex = self.index(byUTF8Before: range.lowerBound)
                return self.run(at: prevIndex, clampedBy: self.startIndex ..< self.endIndex).0.attributes
            } else {
                return self.run(at: self.startIndex, clampedBy: self.startIndex ..< self.endIndex).0.attributes
            }
        }
        
    }
    
    internal var _guts : Guts
    
    internal enum RangeOrStartIndex : Equatable {
        case range(Range<AttributedString.Index>)
        case startIndex(AttributedString.Index)
    }
    public struct Runs : BidirectionalCollection, Equatable, CustomStringConvertible {
        public struct Index : Comparable, Strideable {
            internal let rangeIndex : Int
            
            public static func < (lhs: AttributedString.Runs.Index, rhs: AttributedString.Runs.Index) -> Bool {
                return lhs.rangeIndex < rhs.rangeIndex
            }
            
            public func distance(to other: AttributedString.Runs.Index) -> Int {
                return other.rangeIndex - rangeIndex
            }
            
            public func advanced(by n: Int) -> AttributedString.Runs.Index {
                Index(rangeIndex: rangeIndex + n)
            }
        }
        
        @dynamicMemberLookup
        public struct Run : Equatable, CustomStringConvertible {

            public var range : Range<AttributedString.Index> {
                switch _rangeOrStartIndex {
                case .range(let range):
                    return range
                case .startIndex(let startIndex):
                    return startIndex ..< _guts.index(startIndex, offsetByUTF8: _internal.length)
                }
            }
            internal var startIndex : AttributedString.Index {
                switch _rangeOrStartIndex {
                case .range(let range):
                    return range.lowerBound
                case .startIndex(let startIndex):
                    return startIndex
                }
            }
            internal var _attributes : _AttributeStorage {
                return _internal.attributes
            }

            internal let _internal : _InternalRun
            internal let _rangeOrStartIndex : RangeOrStartIndex
            internal let _guts : AttributedString.Guts
            internal init(_internal: _InternalRun, _rangeOrStartIndex: RangeOrStartIndex, _guts: AttributedString.Guts) {
                self._internal = _internal
                self._rangeOrStartIndex = _rangeOrStartIndex
                self._guts = _guts
            }
            internal init(_ other: Runs.Run) {
                self._internal = other._internal
                self._rangeOrStartIndex = other._rangeOrStartIndex
                self._guts = other._guts
            }
            
            public static func == (lhs: Run, rhs: Run) -> Bool {
                return lhs._internal == rhs._internal
            }
            
            public var description: String {
                AttributedSubstring(_guts, range).description
            }
            
            internal func run(clampedTo range: Range<AttributedString.Index>) -> Run {
                var newInternal = _internal
                let newRange = self.range.clamped(to: range)
                newInternal.length = _guts.utf8Distance(from: newRange.lowerBound, to: newRange.upperBound)
                return Run(_internal: newInternal, _rangeOrStartIndex: .range(newRange), _guts: _guts)
            }
            
            public subscript<K: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeDynamicLookup, K>) -> K.Value? {
                get { self[K.self] }
            }
            
            public subscript<K : AttributedStringKey>(_: K.Type) -> K.Value? {
                get { _internal.attributes.contents[K.name] as? K.Value }
            }
            
            public subscript<S: AttributeScope>(dynamicMember keyPath: KeyPath<AttributeScopes, S.Type>) -> ScopedAttributeContainer<S> {
                get { ScopedAttributeContainer(_internal.attributes.contents) }
            }

            internal subscript<S: AttributeScope>(_ scope: S.Type) -> ScopedAttributeContainer<S> {
                get { ScopedAttributeContainer(_internal.attributes.contents) }
            }

            public var attributes : AttributeContainer {
                AttributeContainer(self._attributes.contents)
            }
        }

        
        public typealias Element = Run
        
        internal var _guts : Guts
        internal var _range : Range<AttributedString.Index>
        internal var _startingRunIndex : Int
        internal var _endingRunIndex : Int
        internal init(_ g: Guts, _ r: Range<AttributedString.Index>) {
            _guts = g
            _range = r
            _startingRunIndex = _guts.indexOfRun(at: _range.lowerBound).rangeIndex
            if _range.upperBound == _guts.endIndex {
                _endingRunIndex = _guts.runs.count
            } else if _range.upperBound == _guts.startIndex {
                _endingRunIndex = 0
            } else {
                _endingRunIndex = _guts.indexOfRun(at: _guts.index(byUTF8Before: _range.upperBound)).rangeIndex + 1
            }
        }
        
        public static func == (lhs: Runs, rhs: Runs) -> Bool {
            let lhsSlice = lhs._guts.runs[lhs._startingRunIndex ..< lhs._endingRunIndex]
            let rhsSlice = rhs._guts.runs[rhs._startingRunIndex ..< rhs._endingRunIndex]
            
            // If there are different numbers of runs, they aren't equal
            guard lhsSlice.count == rhsSlice.count else {
                return false
            }
            
            let runCount = lhsSlice.count
            
            // Empty slices are always equal
            guard runCount > 0 else {
                return true
            }
            
            // Compare the first run (clamping their ranges) since we know each has at least one run
            if lhs._guts.run(at: lhs.startIndex, clampedBy: lhs._range) != rhs._guts.run(at: rhs.startIndex, clampedBy: rhs._range) {
                return false
            }
            
            // Compare all inner runs if they exist without needing to clamp ranges
            if runCount > 2 && !lhsSlice[lhsSlice.startIndex + 1 ..< lhsSlice.endIndex - 1].elementsEqual(rhsSlice[rhsSlice.startIndex + 1 ..< rhsSlice.endIndex - 1]) {
                return false
            }
            
            // If there are more than one run (so we didn't already check this as the first run), check the last run (clamping its range)
            if runCount > 1 && lhs._guts.run(at: Index(rangeIndex: lhs._endingRunIndex - 1), clampedBy: lhs._range) != rhs._guts.run(at: Index(rangeIndex: rhs._endingRunIndex - 1), clampedBy: rhs._range) {
                return false
            }
            
            return true
        }
        
        public var description: String {
            AttributedSubstring(_guts, _range).description
        }
        
        public func index(before i: Index) -> Index {
            return Index(rangeIndex: i.rangeIndex-1)
        }
        
        public func index(after i: Index) -> Index {
            return Index(rangeIndex: i.rangeIndex+1)
        }
        
        public var startIndex: Index {
            return Index(rangeIndex: _startingRunIndex)
        }
        
        public var endIndex: Index {
            return Index(rangeIndex: _endingRunIndex)
        }
        
        public subscript(position: Index) -> Run {
            return _guts.run(at: position, clampedBy: _range)
        }
        
        internal subscript(internal position: Index) -> _InternalRun {
            return _guts.runs[position.rangeIndex]
        }
        
        public subscript(position: AttributedString.Index) -> Run {
            let (internalRun, range) = _guts.run(at: position, clampedBy: _range)
            return Run(_internal: internalRun, _rangeOrStartIndex: .range(range), _guts: _guts)
        }
        
        // ???: public?
        internal func indexOfRun(at position: AttributedString.Index) -> Index {
            return _guts.indexOfRun(at: position)
        }

        internal static func __equalAttributeSlices(lhs: _AttributeStorage, rhs: _AttributeStorage, attributes: [String]) -> Bool {
            for name in attributes {
                if !__equalAttributes(lhs.contents[name], rhs.contents[name]) {
                    return false
                }
            }
            return true
        }
        
        internal func _runs_index(before i: AttributedString.Index, startIndex: AttributedString.Index, endIndex: AttributedString.Index, attributeNames: [String], findingStartOfCurrentSlice: Bool = false) -> AttributedString.Index {
            let beginningOfInitialRun = (i == endIndex) ? endIndex : self[i].startIndex
            var currentIndex = i
            var attributes : _AttributeStorage?
            var result = i
            if findingStartOfCurrentSlice {
                attributes = self[currentIndex]._attributes
            }
            repeat {
                if beginningOfInitialRun < currentIndex {
                    currentIndex = beginningOfInitialRun
                } else {
                    currentIndex = self._guts.index(byCharactersBefore: currentIndex)
                }
                let currentRun = self[currentIndex]
                if let attrs = attributes {
                    if !Self.__equalAttributeSlices(lhs: attrs, rhs: currentRun._attributes, attributes: attributeNames) {
                        break
                    }
                } else {
                    attributes = currentRun._attributes
                }
                
                switch currentRun._rangeOrStartIndex {
                case .range(let r):
                    result = r.clamped(to: startIndex ..< endIndex).lowerBound
                case .startIndex(let si):
                    result = Swift.max(si, startIndex)
                }
            } while result > startIndex
            return result
        }
        
        internal func _runs_index(after i: AttributedString.Index, startIndex: AttributedString.Index, endIndex: AttributedString.Index, attributeNames: [String]) -> AttributedString.Index {
            let thisRunIndex = self.indexOfRun(at: i)
            let thisRun = self[internal: thisRunIndex]
            var nextRunIndex = self.index(after: thisRunIndex)
            while nextRunIndex < self.endIndex {
                let (nextRun, location) = self._guts.runAndLocation(at: nextRunIndex.rangeIndex) // Call to guts directly to avoid unneccesary range clamping
                if !Self.__equalAttributeSlices(lhs: thisRun.attributes, rhs: nextRun.attributes, attributes: attributeNames) {
                    return self._guts.index(_guts.startIndex, offsetByUTF8: location)
                }
                nextRunIndex = self.index(after: nextRunIndex)
            }
            return endIndex
        }
        
        internal func _runs_attributesAndRangeAt(position: AttributedString.Index, from previousRunIndex: AttributedString.Index, through nextRunIndex: AttributedString.Index) -> (_AttributeStorage, Range<AttributedString.Index>) {
            let thisRunIndex = self.indexOfRun(at: position)
            let thisRun = self[thisRunIndex]
            let range = previousRunIndex ..< nextRunIndex
            return (thisRun._attributes, range)
        }
        
        public struct AttributesSlice1<T : AttributedStringKey> : BidirectionalCollection {
            public typealias Index = AttributedString.Index
            public typealias Element = (T.Value?, Range<AttributedString.Index>)
            
            public struct Iterator: IteratorProtocol {
                public typealias Element = AttributesSlice1.Element
                
                let slice: AttributesSlice1
                var currentIndex: AttributedString.Index
                var cachedNextRunIndex: AttributedString.Index?
                
                internal init(_ slice: AttributesSlice1) {
                    self.slice = slice
                    currentIndex = slice.startIndex
                }
                
                public mutating func next() -> Element? {
                    if let cached = cachedNextRunIndex {
                        currentIndex = cached
                    }
                    if currentIndex == slice.endIndex {
                        return nil
                    }
                    cachedNextRunIndex = slice.runs._runs_index(after: currentIndex, startIndex: slice.startIndex, endIndex: slice.endIndex, attributeNames: [T.name])
                    let (attrContents, range) = slice.runs._runs_attributesAndRangeAt(position: currentIndex, from: currentIndex, through: cachedNextRunIndex!)
                    return (attrContents[T.self], range)
                }
            }
            
            public func makeIterator() -> Iterator {
                Iterator(self)
            }
            
            public var startIndex: Index {
                runs._range.lowerBound
            }
            public var endIndex: Index {
                runs._range.upperBound
            }
            
            public func index(before i: Index) -> Index {
                runs._runs_index(before: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name])
            }
            
            public func index(after i: Index) -> Index {
                runs._runs_index(after: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name])
            }
            
            public subscript(position: AttributedString.Index) -> Element {
                let nextRunIndex = self.index(after: position)
                let previousRunIndex : AttributedString.Index
                if position == startIndex {
                    previousRunIndex = position
                } else {
                    previousRunIndex = runs._runs_index(before: position, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name], findingStartOfCurrentSlice: true)
                }
                let (attrContents, range) = runs._runs_attributesAndRangeAt(position: position, from: previousRunIndex, through: nextRunIndex)
                return (attrContents[T.self], range)
            }
            
            let runs : Runs
        }
        
        public struct AttributesSlice2
            <T : AttributedStringKey,
             U : AttributedStringKey> : BidirectionalCollection {
            public typealias Index = AttributedString.Index
            public typealias Element = (T.Value?, U.Value?, Range<AttributedString.Index>)
            
            public struct Iterator: IteratorProtocol {
                public typealias Element = AttributesSlice2.Element
                
                let slice: AttributesSlice2
                var currentIndex: AttributedString.Index
                var cachedNextRunIndex: AttributedString.Index?
                
                internal init(_ slice: AttributesSlice2) {
                    self.slice = slice
                    currentIndex = slice.startIndex
                }
                
                public mutating func next() -> Element? {
                    if let cached = cachedNextRunIndex {
                        currentIndex = cached
                    }
                    if currentIndex == slice.endIndex {
                        return nil
                    }
                    cachedNextRunIndex = slice.runs._runs_index(after: currentIndex, startIndex: slice.startIndex, endIndex: slice.endIndex, attributeNames: [T.name, U.name])
                    let (attrContents, range) = slice.runs._runs_attributesAndRangeAt(position: currentIndex, from: currentIndex, through: cachedNextRunIndex!)
                    return (attrContents[T.self], attrContents[U.self], range)
                }
            }
            
            public func makeIterator() -> Iterator {
                Iterator(self)
            }
            
            public var startIndex: Index {
                runs._range.lowerBound
            }
            public var endIndex: Index {
                runs._range.upperBound
            }
            
            public func index(before i: Index) -> Index {
                runs._runs_index(before: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name])
            }
            
            public func index(after i: Index) -> Index {
                runs._runs_index(after: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name])
            }
            
            public subscript(position: AttributedString.Index) -> Element {
                let nextRunIndex = self.index(after: position)
                let previousRunIndex : AttributedString.Index
                if position == startIndex {
                    previousRunIndex = position
                } else {
                    previousRunIndex = runs._runs_index(before: position, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name], findingStartOfCurrentSlice: true)
                }
                let (attrContents, range) = runs._runs_attributesAndRangeAt(position: position, from: previousRunIndex, through: nextRunIndex)
                return (attrContents[T.self], attrContents[U.self], range)
            }
            
            let runs : Runs
        }
        
        public struct AttributesSlice3
            <T : AttributedStringKey,
             U : AttributedStringKey,
             V : AttributedStringKey> : BidirectionalCollection {
            public typealias Index = AttributedString.Index
            public typealias Element = (T.Value?, U.Value?, V.Value?, Range<AttributedString.Index>)
            
            public struct Iterator: IteratorProtocol {
                public typealias Element = AttributesSlice3.Element
                
                let slice: AttributesSlice3
                var currentIndex: AttributedString.Index
                var cachedNextRunIndex: AttributedString.Index?
                
                internal init(_ slice: AttributesSlice3) {
                    self.slice = slice
                    currentIndex = slice.startIndex
                }
                
                public mutating func next() -> Element? {
                    if let cached = cachedNextRunIndex {
                        currentIndex = cached
                    }
                    if currentIndex == slice.endIndex {
                        return nil
                    }
                    cachedNextRunIndex = slice.runs._runs_index(after: currentIndex, startIndex: slice.startIndex, endIndex: slice.endIndex, attributeNames: [T.name, U.name, V.name])
                    let (attrContents, range) = slice.runs._runs_attributesAndRangeAt(position: currentIndex, from: currentIndex, through: cachedNextRunIndex!)
                    return (attrContents[T.self], attrContents[U.self], attrContents[V.self], range)
                }
            }
            
            public func makeIterator() -> Iterator {
                Iterator(self)
            }
            
            public var startIndex: Index {
                runs._range.lowerBound
            }
            public var endIndex: Index {
                runs._range.upperBound
            }
            
            public func index(before i: Index) -> Index {
                runs._runs_index(before: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name, V.name])
            }
            
            public func index(after i: Index) -> Index {
                runs._runs_index(after: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name, V.name])
            }
            
            public subscript(position: AttributedString.Index) -> Element {
                let nextRunIndex = self.index(after: position)
                let previousRunIndex : AttributedString.Index
                if position == startIndex {
                    previousRunIndex = position
                } else {
                    previousRunIndex = runs._runs_index(before: position, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name, V.name], findingStartOfCurrentSlice: true)
                }
                let (attrContents, range) = runs._runs_attributesAndRangeAt(position: position, from: previousRunIndex, through: nextRunIndex)
                return (attrContents[T.self], attrContents[U.self], attrContents[V.self], range)
            }
            
            let runs : Runs
        }
        
        public struct AttributesSlice4
            <T : AttributedStringKey,
             U : AttributedStringKey,
             V : AttributedStringKey,
             W : AttributedStringKey> : BidirectionalCollection {
            public typealias Index = AttributedString.Index
            public typealias Element = (T.Value?, U.Value?, V.Value?, W.Value?, Range<AttributedString.Index>)
            
            public struct Iterator: IteratorProtocol {
                public typealias Element = AttributesSlice4.Element
                
                let slice: AttributesSlice4
                var currentIndex: AttributedString.Index
                var cachedNextRunIndex: AttributedString.Index?
                
                internal init(_ slice: AttributesSlice4) {
                    self.slice = slice
                    currentIndex = slice.startIndex
                }
                
                public mutating func next() -> Element? {
                    if let cached = cachedNextRunIndex {
                        currentIndex = cached
                    }
                    if currentIndex == slice.endIndex {
                        return nil
                    }
                    cachedNextRunIndex = slice.runs._runs_index(after: currentIndex, startIndex: slice.startIndex, endIndex: slice.endIndex, attributeNames: [T.name, U.name, V.name, W.name])
                    let (attrContents, range) = slice.runs._runs_attributesAndRangeAt(position: currentIndex, from: currentIndex, through: cachedNextRunIndex!)
                    return (attrContents[T.self], attrContents[U.self], attrContents[V.self], attrContents[W.self], range)
                }
            }
            
            public func makeIterator() -> Iterator {
                Iterator(self)
            }
            
            public var startIndex: Index {
                runs._range.lowerBound
            }
            public var endIndex: Index {
                runs._range.upperBound
            }
            
            public func index(before i: Index) -> Index {
                runs._runs_index(before: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name, V.name, W.name])
            }
            
            public func index(after i: Index) -> Index {
                runs._runs_index(after: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name, V.name, W.name])
            }
            
            public subscript(position: AttributedString.Index) -> Element {
                let nextRunIndex = self.index(after: position)
                let previousRunIndex : AttributedString.Index
                if position == startIndex {
                    previousRunIndex = position
                } else {
                    previousRunIndex = runs._runs_index(before: position, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name, V.name, W.name], findingStartOfCurrentSlice: true)
                }
                let (attrContents, range) = runs._runs_attributesAndRangeAt(position: position, from: previousRunIndex, through: nextRunIndex)
                return (attrContents[T.self], attrContents[U.self], attrContents[V.self], attrContents[W.self], range)
            }
            
            let runs : Runs
        }
        
        public struct AttributesSlice5
            <T : AttributedStringKey,
             U : AttributedStringKey,
             V : AttributedStringKey,
             W : AttributedStringKey,
             X : AttributedStringKey> : BidirectionalCollection {
            public typealias Index = AttributedString.Index
            public typealias Element = (T.Value?, U.Value?, V.Value?, W.Value?, X.Value?, Range<AttributedString.Index>)
            
            public struct Iterator: IteratorProtocol {
                public typealias Element = AttributesSlice5.Element
                
                let slice: AttributesSlice5
                var currentIndex: AttributedString.Index
                var cachedNextRunIndex: AttributedString.Index?
                
                internal init(_ slice: AttributesSlice5) {
                    self.slice = slice
                    currentIndex = slice.startIndex
                }
                
                public mutating func next() -> Element? {
                    if let cached = cachedNextRunIndex {
                        currentIndex = cached
                    }
                    if currentIndex == slice.endIndex {
                        return nil
                    }
                    cachedNextRunIndex = slice.runs._runs_index(after: currentIndex, startIndex: slice.startIndex, endIndex: slice.endIndex, attributeNames: [T.name, U.name, V.name, W.name, X.name])
                    let (attrContents, range) = slice.runs._runs_attributesAndRangeAt(position: currentIndex, from: currentIndex, through: cachedNextRunIndex!)
                    return (attrContents[T.self], attrContents[U.self], attrContents[V.self], attrContents[W.self], attrContents[X.self], range)
                }
            }
            
            public func makeIterator() -> Iterator {
                Iterator(self)
            }
            
            public var startIndex: Index {
                runs._range.lowerBound
            }
            public var endIndex: Index {
                runs._range.upperBound
            }
            
            public func index(before i: Index) -> Index {
                runs._runs_index(before: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name, V.name, W.name, X.name])
            }
            
            public func index(after i: Index) -> Index {
                runs._runs_index(after: i, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name, V.name, W.name, X.name])
            }
            
            public subscript(position: AttributedString.Index) -> Element {
                let nextRunIndex = self.index(after: position)
                let previousRunIndex : AttributedString.Index
                if position == startIndex {
                    previousRunIndex = position
                } else {
                    previousRunIndex = runs._runs_index(before: position, startIndex: startIndex, endIndex: endIndex, attributeNames: [T.name, U.name, V.name, W.name, X.name], findingStartOfCurrentSlice: true)
                }
                let (attrContents, range) = runs._runs_attributesAndRangeAt(position: position, from: previousRunIndex, through: nextRunIndex)
                return (attrContents[T.self], attrContents[U.self], attrContents[V.self], attrContents[W.self], attrContents[X.self], range)
            }
            
            let runs : Runs
        }
        
        public subscript <
            T : AttributedStringKey,
            U : AttributedStringKey,
            V : AttributedStringKey,
            W : AttributedStringKey,
            X : AttributedStringKey> (_ t: KeyPath<AttributeDynamicLookup, T>,
                                      _ u: KeyPath<AttributeDynamicLookup, U>,
                                      _ v: KeyPath<AttributeDynamicLookup, V>,
                                      _ w: KeyPath<AttributeDynamicLookup, W>,
                                      _ x: KeyPath<AttributeDynamicLookup, X>) -> AttributesSlice5<T, U, V, W, X>
        {
            return AttributesSlice5<T, U, V, W, X>(runs: self)
        }
        
        public subscript <
            T : AttributedStringKey,
            U : AttributedStringKey,
            V : AttributedStringKey,
            W : AttributedStringKey> (_ t: KeyPath<AttributeDynamicLookup, T>,
                                      _ u: KeyPath<AttributeDynamicLookup, U>,
                                      _ v: KeyPath<AttributeDynamicLookup, V>,
                                      _ w: KeyPath<AttributeDynamicLookup, W>) -> AttributesSlice4<T, U, V, W>
        {
            return AttributesSlice4<T, U, V, W>(runs: self)
        }
        
        public subscript <
            T : AttributedStringKey,
            U : AttributedStringKey,
            V : AttributedStringKey> (_ t: KeyPath<AttributeDynamicLookup, T>,
                                      _ u: KeyPath<AttributeDynamicLookup, U>,
                                      _ v: KeyPath<AttributeDynamicLookup, V>) -> AttributesSlice3<T, U, V>
        {
            return AttributesSlice3<T, U, V>(runs: self)
        }

        public subscript <
            T : AttributedStringKey,
            U : AttributedStringKey> (_ t: KeyPath<AttributeDynamicLookup, T>,
                                      _ u: KeyPath<AttributeDynamicLookup, U>) -> AttributesSlice2<T, U>
        {
            return AttributesSlice2<T, U>(runs: self)
        }

        public subscript<T : AttributedStringKey>(_ keyPath: KeyPath<AttributeDynamicLookup, T>) -> AttributesSlice1<T> {
            return AttributesSlice1<T>(runs: self)
        }

        public subscript <
            T : AttributedStringKey,
            U : AttributedStringKey,
            V : AttributedStringKey,
            W : AttributedStringKey,
            X : AttributedStringKey> (_ t: T.Type,
                                      _ u: U.Type,
                                      _ v: V.Type,
                                      _ w: W.Type,
                                      _ x: X.Type) -> AttributesSlice5<T, U, V, W, X>
        {
            return AttributesSlice5<T, U, V, W, X>(runs: self)
        }

        public subscript <
            T : AttributedStringKey,
            U : AttributedStringKey,
            V : AttributedStringKey,
            W : AttributedStringKey> (_ t: T.Type,
                                      _ u: U.Type,
                                      _ v: V.Type,
                                      _ w: W.Type) -> AttributesSlice4<T, U, V, W>
        {
            return AttributesSlice4<T, U, V, W>(runs: self)
        }

        public subscript <
            T : AttributedStringKey,
            U : AttributedStringKey,
            V : AttributedStringKey> (_ t: T.Type,
                                      _ u: U.Type,
                                      _ v: V.Type) -> AttributesSlice3<T, U, V>
        {
            return AttributesSlice3<T, U, V>(runs: self)
        }

        public subscript <
            T : AttributedStringKey,
            U : AttributedStringKey> (_ t: T.Type,
                                      _ u: U.Type) -> AttributesSlice2<T, U>
        {
            return AttributesSlice2<T, U>(runs: self)
        }

        public subscript<T : AttributedStringKey>(_ t: T.Type) -> AttributesSlice1<T> {
            return AttributesSlice1<T>(runs: self)
        }
 
    }
    
    public var runs : Runs {
        get { .init(_guts, _guts.startIndex ..< _guts.endIndex) }
    }
    
    public struct CharacterView : BidirectionalCollection, RangeReplaceableCollection {
        public typealias Element = Character
        public typealias Index = AttributedString.Index

        internal var _guts : Guts
        internal var _range : Range<Index>
        internal var _identity : Int = 0
        internal init(_ g: Guts, _ r: Range<Index>) {
            _guts = g
            _range = r
        }
        
        public init() {
            _guts = Guts(string: "", runs: [])
            _range = _guts.startIndex ..< _guts.endIndex
        }
        
        public var startIndex: AttributedString.Index {
            return _range.lowerBound
        }
        
        public var endIndex: AttributedString.Index {
            return _range.upperBound
        }
    
        public func index(before i: AttributedString.Index) -> AttributedString.Index {
            return _guts.index(byCharactersBefore: i)
        }
        
        public func index(after i: AttributedString.Index) -> AttributedString.Index {
            return _guts.index(byCharactersAfter: i)
        }
        
        internal mutating func ensureUniqueReference() {
            if !isKnownUniquelyReferenced(&_guts) {
                _guts = Guts(_guts)
            }
        }
        
        public subscript(index: AttributedString.Index) -> Character {
            get {
                _guts.string[index.characterIndex]
            }
            set {
                self.replaceSubrange(index ..< _guts.index(byCharactersAfter: index), with: [newValue])
            }
        }
        
        public subscript(bounds: Range<AttributedString.Index>) -> Slice<AttributedString.CharacterView> {
            get {
                Slice(base: self, bounds: bounds)
            }
            set {
                ensureUniqueReference()
                let newAttributedString = AttributedString(String(newValue))
                if newAttributedString._guts.runs.count > 0 {
                    var run = newAttributedString._guts.runs[0]
                    run.attributes = _guts.run(at: bounds.lowerBound, clampedBy: _range).0.attributes // ???: Is this right?
                    newAttributedString._guts.updateAndCoalesce(run: run, at: 0)
                }
                _guts.replaceSubrange(bounds, with: newAttributedString)
            }
        }
        
        public mutating func replaceSubrange<C : Collection>(_ subrange: Range<Index>, with newElements: C) where C.Element == Character {
            ensureUniqueReference()
            let newAttributedString = AttributedString(String(newElements))
            if newAttributedString._guts.runs.count > 0 {
                var run = newAttributedString._guts.runs[0]
                run.attributes = _guts.attributesToUseForReplacement(in: subrange)
                newAttributedString._guts.updateAndCoalesce(run: run, at: 0)
            }
            
            // !!!: We're dealing with Characters in this view, but the subrange could sub-Character indexes. I'm pretty sure this will FATALERROR if they do if we try to compute character distance. This needs serious vetting & testing.
            let sliceOffset = _guts.utf8Distance(from: _guts.startIndex, to: self.startIndex)
            let newSliceCount = _guts.utf8Distance(from: self.startIndex, to: subrange.lowerBound) + _guts.utf8Distance(from: subrange.upperBound, to: self.endIndex) + String(newElements).utf8.count
            _guts.replaceSubrange(subrange, with: newAttributedString)
            _range = _guts.index(_guts.startIndex, offsetByUTF8: sliceOffset) ..< _guts.index(self.startIndex, offsetByUTF8: newSliceCount)
        }
    }
    
    public struct UnicodeScalarView : RangeReplaceableCollection, BidirectionalCollection {
        public typealias Element = UnicodeScalar
        public typealias Index = AttributedString.Index
        
        internal var _guts : Guts
        internal var _range : Range<Index>
        internal var _identity : Int = 0
        internal init(_ g: Guts, _ r: Range<Index>) {
            _guts = g
            _range = r
        }
        
        public init() {
            _guts = Guts(string: "", runs: [])
            _range = _guts.startIndex ..< _guts.endIndex
        }
        
        public var startIndex: AttributedString.Index {
            return _range.lowerBound
        }
        
        public var endIndex: AttributedString.Index {
            return _range.upperBound
        }
    
        public func index(before i: AttributedString.Index) -> AttributedString.Index {
            let index = _guts.string.unicodeScalars.index(before: i.characterIndex)
            return Index(characterIndex: index)
        }
        
        public func index(after i: AttributedString.Index) -> AttributedString.Index {
            let index = _guts.string.unicodeScalars.index(after: i.characterIndex)
            return Index(characterIndex: index)
        }
        
        public func index(_ i: AttributedString.Index, offsetBy distance: Int) -> AttributedString.Index {
            let index = _guts.string.unicodeScalars.index(i.characterIndex, offsetBy: distance)
            return Index(characterIndex: index)
        }
        
        public subscript(index: AttributedString.Index) -> UnicodeScalar {
            _guts.string.unicodeScalars[index.characterIndex]
        }
        
        public subscript(bounds: Range<AttributedString.Index>) -> Slice<AttributedString.UnicodeScalarView> {
            Slice(base: self, bounds: bounds)
        }
        
        internal mutating func ensureUniqueReference() {
            if !isKnownUniquelyReferenced(&_guts) {
                _guts = Guts(_guts)
            }
        }
        
        public mutating func replaceSubrange<C : Collection>(_ subrange: Range<Index>, with newElements: C) where C.Element == UnicodeScalar {
            ensureUniqueReference()
            let unicodeScalarView = String.UnicodeScalarView(newElements)
            let newAttributedString = AttributedString(String(unicodeScalarView))
            if newAttributedString._guts.runs.count > 0 {
                var run = newAttributedString._guts.runs[0]
                run.attributes = _guts.attributesToUseForReplacement(in: subrange)
                newAttributedString._guts.updateAndCoalesce(run: run, at: 0)
            }
            
            // !!!: We're dealing with Characters in this view, but the subrange could sub-Character indexes. I'm pretty sure this will FATALERROR if they do if we try to compute character distance. This needs serious vetting & testing.
            let sliceOffset = _guts.utf8Distance(from: _guts.startIndex, to: self.startIndex)
            let newSliceCount = _guts.utf8Distance(from: self.startIndex, to: subrange.lowerBound) + _guts.utf8Distance(from: subrange.upperBound, to: self.endIndex) + newElements.count
            _guts.replaceSubrange(subrange, with: newAttributedString)
            _range = _guts.index(_guts.startIndex, offsetByUTF8: sliceOffset) ..< _guts.index(self.startIndex, offsetByUTF8: newSliceCount)
        }
    }
    
    public var characters : CharacterView {
        get {
            return CharacterView(_guts, startIndex ..< endIndex)
        }
        _modify {
            ensureUniqueReference()
            var cv = CharacterView(_guts, startIndex ..< endIndex)
            let ident = Self._nextModifyIdentity
            cv._identity = ident
            _guts = Guts(string: "", runs: []) // Dummy guts so the CharacterView has (hopefully) the sole reference
            defer {
                if cv._identity != ident {
                    fatalError("Mutating a CharacterView by replacing it with another from a different source is unsupported")
                }
                _guts = cv._guts
            }
            yield &cv
        } set {
            self.characters.replaceSubrange(startIndex ..< endIndex, with: newValue)
        }
    }
    
    public var unicodeScalars : UnicodeScalarView {
        get {
            UnicodeScalarView(_guts, startIndex ..< endIndex)
        }
        _modify {
            ensureUniqueReference()
            var usv = UnicodeScalarView(_guts, startIndex ..< endIndex)
            let ident = Self._nextModifyIdentity
            usv._identity = ident
            _guts = Guts(string: "", runs: []) // Dummy guts so the UnicodeScalarView has (hopefully) the sole reference
            defer {
                if usv._identity != ident {
                    fatalError("Mutating a UnicodeScalarView by replacing it with another from a different source is unsupported")
                }
                _guts = usv._guts
            }
            yield &usv
        } set {
            self.unicodeScalars.replaceSubrange(startIndex ..< endIndex, with: newValue)
        }
    }
        
    // MARK: Protocol conformance
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs._guts == rhs._guts
    }

    // MARK: Initialization
    
    public init() {
        self.init("")
    }
    
    fileprivate init(_ string: String, attributes: _AttributeStorage) {
        if string.isEmpty {
            _guts = Guts(string: string, runs: [])
        } else {
            let run = _InternalRun(length: string.utf8.count, attributes: attributes)
            _guts = Guts(string: string, runs: [run])
        }
    }
    
    /// Creates a new attributed string with the given `String` value associated with the given
    /// attributes.
    public init(_ string: String, attributes: AttributeContainer = .init()) {
        var storage = _AttributeStorage()
        storage.contents = attributes.contents
        self.init(string, attributes: storage)
    }

    /// Creates a new attributed string with the given `Substring` value associated with the given
    /// attributes.
    public init(_ substring: Substring, attributes: AttributeContainer = .init()) {
        self.init(String(substring), attributes: attributes)
    }
    
    public init<S : Sequence>(_ elements: S, attributes: AttributeContainer = .init()) where S.Element == Character {
        if let string = elements as? String {
            self.init(string, attributes: attributes)
            return
        }
        if let substring = elements as? Substring {
            self.init(substring, attributes: attributes)
            return
        }
        self.init(String(elements), attributes: attributes)
    }
        
    public init(_ substring: AttributedSubstring) {
        let newString = String(substring._guts.string[substring._range._stringRange])
        let newRuns = substring._guts.runs(in: substring._range, relativeTo: newString)
        _guts = Guts(string: newString, runs: newRuns)
    }
    
    internal init(_ guts: Guts) {
        _guts = guts
    }
    
    public init<S : AttributeScope, T : AttributedStringProtocol>(_ other: T, including scope: KeyPath<AttributeScopes, S.Type>) {
        self.init(other, including: S.self)
    }
    
    public init<S : AttributeScope, T : AttributedStringProtocol>(_ other: T, including scope: S.Type) {
        self.init(Guts(other.__guts, range: other.startIndex ..< other.endIndex))
        var attributeCache = [String : Bool]()
        _guts.enumerateRuns { run, _, _, modification in
            modification = .guaranteedNotModified
            for key in run.attributes.contents.keys {
                var inScope: Bool
                if let cachedInScope = attributeCache[key] {
                    inScope = cachedInScope
                } else {
                    inScope = scope.attributeKeyType(matching: key) != nil
                    attributeCache[key] = inScope
                }
                
                if !inScope {
                    run.attributes.contents.removeValue(forKey: key)
                    modification = .guaranteedModified
                }
            }
        }
    }

    // MARK: Appending
    
    internal mutating func ensureUniqueReference() {
        if !isKnownUniquelyReferenced(&_guts) {
            _guts = Guts(_guts)
        }
    }

    public static func + <T: AttributedStringProtocol> (lhs: AttributedString, rhs: T) -> AttributedString {
        var result = lhs
        result.append(rhs)
        return result
    }

    public static func += <T: AttributedStringProtocol> (lhs: inout AttributedString, rhs: T) {
        lhs.append(rhs)
    }

    public static func + (lhs: AttributedString, rhs: AttributedString) -> AttributedString {
        var result = lhs
        result.append(rhs)
        return result
    }

    public static func += (lhs: inout Self, rhs: AttributedString) {
        lhs.append(rhs)
    }

    // MARK: Attribute Access

    internal static var currentIdentity = 0
    internal static var currentIdentityLock = Lock()
    internal static var _nextModifyIdentity : Int {
        currentIdentityLock.lock()
        currentIdentity += 1
        let result = currentIdentity
        currentIdentityLock.unlock()
        return result
    }

    public subscript<R: RangeExpression>(bounds: R) -> AttributedSubstring where R.Bound == Index {
        get {
            return AttributedSubstring(_guts, bounds.relative(to: characters))
        }
        _modify {
            ensureUniqueReference()
            var substr = AttributedSubstring(_guts, bounds.relative(to: characters))
            let ident = Self._nextModifyIdentity
            substr._identity = ident
            _guts = Guts(string: "", runs: []) // Dummy guts so the substr has (hopefully) the sole reference
            defer {
                if substr._identity != ident {
                    fatalError("Mutating an AttributedSubstring by replacing it with another from a different source is unsupported")
                }
                _guts = substr._guts
            }
            yield &substr
        }
        set {
            self.replaceSubrange(bounds, with: newValue)
        }
    }
    
    public mutating func append<S: AttributedStringProtocol>(_ s: S) {
        replaceSubrange(endIndex ..< endIndex, with: s)
    }
    
    public mutating func insert<S: AttributedStringProtocol>(_ s: S, at index: AttributedString.Index) {
        replaceSubrange(index ..< index, with: s)
    }
    
    public mutating func removeSubrange<R: RangeExpression>(_ range: R) where R.Bound == Index {
        replaceSubrange(range, with: AttributedString())
    }
    
    public mutating func replaceSubrange<R: RangeExpression, S: AttributedStringProtocol>(_ range: R, with s: S) where R.Bound == Index {
        ensureUniqueReference()
        _guts.replaceSubrange(range.relative(to: characters), with: s)
    }
    
    public var startIndex : Index {
        return _guts.startIndex
    }
    
    public var endIndex : Index {
        return _guts.endIndex
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedString : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

@dynamicMemberLookup
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public struct AttributedSubstring {
    internal var _guts: AttributedString.Guts
    internal var _range: Range<AttributedString.Index>
    internal var _identity: Int = 0
    
    internal init(_ guts: AttributedString.Guts, _ range: Range<AttributedString.Index>) {
        self._guts = guts
        self._range = range
    }
    
    public init() {
        let str = AttributedString()
        self.init(str._guts, str.startIndex ..< str.endIndex)
    }
    
    public var base : AttributedString {
        return AttributedString(_guts)
    }
    
    public var description: String {
        var result = ""
        self._guts.enumerateRuns(containing: self._guts.utf8OffsetRange(from: _range)) { run, loc, _, modified in
            let range = self._guts.index(_guts.startIndex, offsetByUTF8: loc) ..< self._guts.index(_guts.startIndex, offsetByUTF8: loc + run.length)
            result += (result.isEmpty ? "" : "\n") + "\(String(self.characters[range])) \(run.attributes)"
            modified = .guaranteedNotModified
        }
        return result
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedSubstring : AttributedStringProtocol {
    public var startIndex: AttributedString.Index {
        get {
            return _range.lowerBound
        }
    }
    
    public var endIndex: AttributedString.Index {
        get {
            return _range.upperBound
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs._guts.string[lhs._range._stringRange] == rhs._guts.string[rhs._range._stringRange] else {
            return false
        }
        return lhs.runs == rhs.runs
    }
    
    internal mutating func ensureUniqueReference() {
        // Ideally we'd only copy the portions that this range covers. However, we need to be able to vend the .base AttributedString, so we copy the entire Guts.
        if !isKnownUniquelyReferenced(&_guts) {
            _guts = AttributedString.Guts(_guts, range: _guts.startIndex ..< _guts.endIndex)
        }
    }
    
    public mutating func setAttributes(_ attributes: AttributeContainer) {
        ensureUniqueReference()
        _guts.set(attributes: attributes, in: _range)
    }
    
    public mutating func mergeAttributes(_ attributes: AttributeContainer, mergePolicy:  AttributedString.AttributeMergePolicy = .keepNew) {
        ensureUniqueReference()
        _guts.add(attributes: attributes, in: _range, mergePolicy:  mergePolicy)
    }
    
    public mutating func replaceAttributes(_ attributes: AttributeContainer, with others: AttributeContainer) {
        guard attributes != others else {
            return
        }
        ensureUniqueReference()
        _guts.enumerateRuns { run, _, _, modified in
            if _run(run, matches: attributes) {
                for key in attributes.contents.keys {
                    run.attributes.contents.removeValue(forKey: key)
                }
                run.attributes.mergeIn(others)
                modified = .guaranteedModified
            } else {
                modified = .guaranteedNotModified
            }
        }
    }
    
    public var runs : AttributedString.Runs {
        get { .init(_guts, _range) }
    }
    
    public var characters : AttributedString.CharacterView {
        return AttributedString.CharacterView(_guts, startIndex ..< endIndex)
    }
    
    public var unicodeScalars : AttributedString.UnicodeScalarView {
        return AttributedString.UnicodeScalarView(_guts, startIndex ..< endIndex)
    }

    public subscript<R: RangeExpression>(bounds: R) -> AttributedSubstring where R.Bound == AttributedString.Index {
        return AttributedSubstring(_guts, bounds.relative(to: characters))
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributedSubstring {
    public subscript<K: AttributedStringKey>(_: K.Type) -> K.Value? {
        get { _guts.getValue(in: _range, key: K.name) as? K.Value }
        set {
            ensureUniqueReference()
            if let v = newValue {
                _guts.add(value: v, in: _range, key: K.name)
            } else {
                _guts.remove(attribute: K.self, in: _range)
            }
        }
    }

    public subscript<K: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeDynamicLookup, K>) -> K.Value? {
        get { self[K.self] }
        set { self[K.self] = newValue }
    }
    
    public subscript<S: AttributeScope>(dynamicMember keyPath: KeyPath<AttributeScopes, S.Type>) -> ScopedAttributeContainer<S> {
        get {
            return ScopedAttributeContainer(_guts.getValues(in: _range))
        }
        _modify {
            ensureUniqueReference()
            var container = ScopedAttributeContainer<S>()
            defer {
                if let removedKey = container.removedKey {
                    _guts.remove(key: removedKey, in: _range)
                } else {
                    _guts.add(attributes: AttributeContainer(container.contents), in: _range)
                }
            }
            yield &container
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension String {
    init(_ attrStrSlice: Slice<AttributedString.CharacterView>) {
        self = String(attrStrSlice.base._guts.string[attrStrSlice.startIndex.characterIndex ..< attrStrSlice.endIndex.characterIndex])
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
internal func _run(_ run : AttributedString._InternalRun, matches container: AttributeContainer) -> Bool {
    let attrs = run.attributes.contents
    for (key, value) in container.contents {
        if !__equalAttributes(attrs[key], value) {
            return false
        }
    }
    return true
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Range where Bound == AttributedString.Index {
    internal var _stringRange : Range<String.Index> {
        lowerBound.characterIndex ..< upperBound.characterIndex
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Range where Bound == String.Index {
    internal var _attributedStringRange : Range<AttributedString.Index> {
        AttributedString.Index(characterIndex: lowerBound) ..< AttributedString.Index(characterIndex: upperBound)
    }
}

internal func __equalAttributes(_ lhs: Any?, _ rhs: Any?) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
        return true
    case (.none, .some(_)):
        return false
    case (.some(_), .none):
        return false
    case (.some(let lhs), .some(let rhs)):
        func openLHS<LHS>(_ lhs: LHS) -> Bool {
            if let rhs = rhs as? LHS {
                return CheckEqualityIfEquatable(lhs, rhs).attemptAction() ?? false
            } else {
                return false
            }
        }
        return _openExistential(lhs, do: openLHS)
    }
}
