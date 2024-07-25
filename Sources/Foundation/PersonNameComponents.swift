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

public struct PersonNameComponents : ReferenceConvertible, Hashable, Equatable, Sendable {
    public typealias ReferenceType = NSPersonNameComponents
    
    public init() {
        _phoneticRepresentation = .none
    }
    
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public init(
        namePrefix: String? = nil,
        givenName: String? = nil,
        middleName: String? = nil,
        familyName: String? = nil,
        nameSuffix: String? = nil,
        nickname: String? = nil,
        phoneticRepresentation: PersonNameComponents? = nil) {
        self.init()
        self.namePrefix = namePrefix
        self.givenName = givenName
        self.middleName = middleName
        self.familyName = familyName
        self.nameSuffix = nameSuffix
        self.nickname = nickname
        self.phoneticRepresentation = phoneticRepresentation
    }
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny", pre-nominal letters denoting title, salutation, or honorific, e.g. Dr., Mr.
    public var namePrefix: String?
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny",  name bestowed upon an individual by one's parents, e.g. Johnathan
    public var givenName: String?
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny", secondary given name chosen to differentiate those with the same first name, e.g. Maple
    public var middleName: String?
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny", name passed from one generation to another to indicate lineage, e.g. Appleseed
    public var familyName: String?
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny", post-nominal letters denoting degree, accreditation, or other honor, e.g. Esq., Jr., Ph.D.
    public var nameSuffix: String?
    
    /// Assuming the full name is: Dr. Johnathan Maple Appleseed Esq., nickname "Johnny", name substituted for the purposes of familiarity, e.g. "Johnny"
    public var nickname: String?
    
    /// Each element of the phoneticRepresentation should correspond to an element of the original PersonNameComponents instance.
    /// The phoneticRepresentation of the phoneticRepresentation object itself will be ignored. nil by default, must be instantiated.
    public var phoneticRepresentation: PersonNameComponents? {
        get {
            switch _phoneticRepresentation {
            case .wrapped(let personNameComponents):
                personNameComponents
            case .none:
                nil
            }
        }
        set {
            switch newValue {
            case .some(let pnc):
                _phoneticRepresentation = .wrapped(pnc)
            case .none:
                _phoneticRepresentation = .none
            }
        }
    }
    
    private var _phoneticRepresentation: PhoneticRepresentation
}

/// Allows for `PersonNameComponents` to store a `PersonNameComponents` for its phonetic representation.
private enum PhoneticRepresentation : Hashable, Equatable {
    indirect case wrapped(PersonNameComponents)
    case none
    
    func hash(into hasher: inout Hasher) {
        let opt : PersonNameComponents? = switch self {
        case .wrapped(let pnc): pnc
        case .none: nil
        }
        hasher.combine(opt)
    }
}

extension PersonNameComponents : CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        return self.customMirror.children.reduce("") {
            $0.appending("\($1.label ?? ""): \($1.value) ")
        }
    }

    public var debugDescription: String {
        return self.description
    }

    public var customMirror: Mirror {
        var c: [(label: String?, value: Any)] = []
        if let r = namePrefix { c.append((label: "namePrefix", value: r)) }
        if let r = givenName { c.append((label: "givenName", value: r)) }
        if let r = middleName { c.append((label: "middleName", value: r)) }
        if let r = familyName { c.append((label: "familyName", value: r)) }
        if let r = nameSuffix { c.append((label: "nameSuffix", value: r)) }
        if let r = nickname { c.append((label: "nickname", value: r)) }
        if let r = phoneticRepresentation { c.append((label: "phoneticRepresentation", value: r)) }
        return Mirror(self, children: c, displayStyle: .struct)
    }
}

extension PersonNameComponents : _ObjectiveCBridgeable {
    public static func _getObjectiveCType() -> Any.Type {
        return NSPersonNameComponents.self
    }

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSPersonNameComponents {
        return NSPersonNameComponents(pnc: self)
    }

    public static func _forceBridgeFromObjectiveC(_ personNameComponents: NSPersonNameComponents, result: inout PersonNameComponents?) {
        if !_conditionallyBridgeFromObjectiveC(personNameComponents, result: &result) {
            fatalError("Unable to bridge \(NSPersonNameComponents.self) to \(self)")
        }
    }

    public static func _conditionallyBridgeFromObjectiveC(_ personNameComponents: NSPersonNameComponents, result: inout PersonNameComponents?) -> Bool {
        result = personNameComponents._pnc
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSPersonNameComponents?) -> PersonNameComponents {
        var result: PersonNameComponents? = nil
        _forceBridgeFromObjectiveC(source!, result: &result)
        return result!
    }
}

extension NSPersonNameComponents : _HasCustomAnyHashableRepresentation {
    // Must be @nonobjc to avoid infinite recursion during bridging.
    @nonobjc
    public func _toCustomAnyHashable() -> AnyHashable? {
        return AnyHashable(self._bridgeToSwift())
    }
}

extension PersonNameComponents : Codable {
    private enum CodingKeys : Int, CodingKey {
        case namePrefix
        case givenName
        case middleName
        case familyName
        case nameSuffix
        case nickname
    }
    
    public init(from decoder: Decoder) throws {
        self.init()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.namePrefix = try container.decodeIfPresent(String.self, forKey: .namePrefix)
        self.givenName  = try container.decodeIfPresent(String.self, forKey: .givenName)
        self.middleName = try container.decodeIfPresent(String.self, forKey: .middleName)
        self.familyName = try container.decodeIfPresent(String.self, forKey: .familyName)
        self.nameSuffix = try container.decodeIfPresent(String.self, forKey: .nameSuffix)
        self.nickname   = try container.decodeIfPresent(String.self, forKey: .nickname)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let np = self.namePrefix { try container.encode(np, forKey: .namePrefix) }
        if let gn = self.givenName  { try container.encode(gn, forKey: .givenName) }
        if let mn = self.middleName { try container.encode(mn, forKey: .middleName) }
        if let fn = self.familyName { try container.encode(fn, forKey: .familyName) }
        if let ns = self.nameSuffix { try container.encode(ns, forKey: .nameSuffix) }
        if let nn = self.nickname   { try container.encode(nn, forKey: .nickname) }
    }
}
