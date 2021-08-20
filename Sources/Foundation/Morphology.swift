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

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public struct Morphology {
    public init() {}
    
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public enum GrammaticalGender: Int, Hashable {
        case feminine  = 1
        case masculine
        case neuter
    }
    public var grammaticalGender: GrammaticalGender?

    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public enum PartOfSpeech: Int, Hashable {
        case determiner = 1
        case pronoun
        case letter
        case adverb
        case particle
        case adjective
        case adposition
        case verb
        case noun
        case conjunction
        case numeral
        case interjection
        case preposition
        case abbreviation
    }
    public var partOfSpeech: PartOfSpeech?

    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public enum GrammaticalNumber: Int, Hashable {
        case singular = 1
        case zero
        case plural
        case pluralTwo
        case pluralFew
        case pluralMany
    }
    public var number: GrammaticalNumber?
    
    fileprivate var customPronouns: [String: CustomPronoun] = [:]
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public enum InflectionRule {
    case automatic
    case explicit(Morphology)

    public init(morphology: Morphology) {
        self = .explicit(morphology)
    }
}

// MARK: -
// MARK: Equatable & Hashable Support

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Morphology: Hashable {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Morphology.CustomPronoun: Hashable {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension InflectionRule: Hashable {}

// MARK: -
// MARK: Codable Support

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Morphology: Codable {
    enum CodingKeys: String, CodingKey {
        case grammaticalGender
        case partOfSpeech
        case number
        case customPronouns
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.grammaticalGender = try container.decodeIfPresent(GrammaticalGender.self, forKey: .grammaticalGender)
        self.partOfSpeech = try container.decodeIfPresent(PartOfSpeech.self, forKey: .partOfSpeech)
        self.number = try container.decodeIfPresent(GrammaticalNumber.self, forKey: .number)
        self.customPronouns = try container.decodeIfPresent([String: CustomPronoun].self, forKey: .customPronouns) ?? [:]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let grammaticalGender = grammaticalGender {
            try container.encode(grammaticalGender, forKey: .grammaticalGender)
        }
        if let partOfSpeech = partOfSpeech {
            try container.encode(partOfSpeech, forKey: .partOfSpeech)
        }
        if let number = number {
            try container.encode(number, forKey: .number)
        }
        if !customPronouns.isEmpty {
            try container.encode(customPronouns, forKey: .customPronouns)
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Morphology.CustomPronoun: Codable {}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Morphology.GrammaticalGender: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch try container.decode(String.self) {
        case "feminine":  self = .feminine
        case "masculine": self = .masculine
        case "neuter":    self = .neuter
        default: throw CocoaError(.coderInvalidValue)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .feminine:  try container.encode("feminine")
        case .masculine: try container.encode("masculine")
        case .neuter:    try container.encode("neuter")
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Morphology.GrammaticalNumber: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch try container.decode(String.self) {
        case "one":   self = .singular
        case "zero":  self = .zero
        case "other": self = .plural
        case "two":   self = .pluralTwo
        case "few":   self = .pluralFew
        case "many":  self = .pluralMany
        default: throw CocoaError(.coderInvalidValue)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .singular:   try container.encode("one")
        case .zero:       try container.encode("zero")
        case .plural:     try container.encode("other")
        case .pluralTwo:  try container.encode("two")
        case .pluralFew:  try container.encode("few")
        case .pluralMany: try container.encode("many")
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Morphology.PartOfSpeech: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch try container.decode(String.self) {
        case "determiner":   self = .determiner
        case "pronoun":      self = .pronoun
        case "letter":       self = .letter
        case "adverb":       self = .adverb
        case "particle":     self = .particle
        case "adjective":    self = .adjective
        case "adposition":   self = .adposition
        case "verb":         self = .verb
        case "noun":         self = .noun
        case "conjunction":  self = .conjunction
        case "numeral":      self = .numeral
        case "interjection": self = .interjection
        case "preposition":  self = .preposition
        case "abbreviation": self = .abbreviation
        default: throw CocoaError(.coderInvalidValue)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .determiner:   try container.encode("determiner")
        case .pronoun:      try container.encode("pronoun")
        case .letter:       try container.encode("letter")
        case .adverb:       try container.encode("adverb")
        case .particle:     try container.encode("particle")
        case .adjective:    try container.encode("adjective")
        case .adposition:   try container.encode("adposition")
        case .verb:         try container.encode("verb")
        case .noun:         try container.encode("noun")
        case .conjunction:  try container.encode("conjunction")
        case .numeral:      try container.encode("numeral")
        case .interjection: try container.encode("interjection")
        case .preposition:  try container.encode("preposition")
        case .abbreviation: try container.encode("abbreviation")
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension InflectionRule: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let it = try? container.decode(Bool.self), it == true {
            self = .automatic
        } else {
            let it = try container.decode(Morphology.self)
            self = .explicit(it)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .automatic:                try container.encode(true)
        case .explicit(let morphology): try container.encode(morphology)
        }
    }
}

// MARK: -
// MARK: Inflection Availability

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension InflectionRule {
    // Whether inflection will edit strings for the specified language, specified as a BCP 47 language identifier.
    public static func canInflect(language: String) -> Bool {
        return false
    }
    
    // Whether inflection will edit strings for the language of the user's
    // current preferred localization. Does not change throughout the lifetime
    // of a process.
    public static var canInflectPreferredLocalization: Bool {
        return false
    }
}

// MARK: -
// MARK: Per-Language Features

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Morphology.CustomPronoun {
    static func keyPath(forObjectiveCKey stringKey: String) -> KeyPath<Self, String?>? {
        switch stringKey {
        case "subjectForm": return \Self.subjectForm
        case "objectForm": return \Self.objectForm
        case "possessiveForm": return \Self.possessiveForm
        case "possessiveAdjectiveForm": return \Self.possessiveAdjectiveForm
        case "reflexiveForm": return \Self.reflexiveForm
        default: return nil
        }
    }
    
    func value(forObjectiveCKey stringKey: String) -> Any? {
        if let path = Self.keyPath(forObjectiveCKey: stringKey) {
            return self[keyPath: path]
        } else {
            return nil
        }
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension Morphology {
    public func customPronoun(forLanguage language: String) -> CustomPronoun? {
        return customPronouns[language.lowercased()]
    }
    
    mutating public func setCustomPronoun(_ pronoun: CustomPronoun?, forLanguage language: String) throws {
        if let pronoun = pronoun {
            let result = pronoun.validate(forLanguage: language)
            if !result {
                throw CocoaError(.keyValueValidation)
            }
        }
        
        customPronouns[language.lowercased()] = pronoun
    }

    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    public struct CustomPronoun {
        public init() {}

        public static func isSupported(forLanguage language: String) -> Bool {
            let indexAtTwo = language.index(language.startIndex, offsetBy: 2)
            // For now we only support English custom pronoun
            return language.count >= 2 &&
                language.lowercased().starts(with: "en") &&
                (language.count == 2 ||
                 language[indexAtTwo ..< language.index(after: indexAtTwo)] == "-" ||
                 language[indexAtTwo ..< language.index(after: indexAtTwo)] == "_")
        }

        public static func requiredKeys(forLanguage language: String) -> [PartialKeyPath<Self>] {
            guard self.isSupported(forLanguage: language) else {
                return []
            }
            return [\.subjectForm, \.objectForm, \.possessiveForm, \.possessiveAdjectiveForm, \.reflexiveForm]
        }
        
        fileprivate func validate(forLanguage language: String) -> Bool {
            guard Self.isSupported(forLanguage: language) else {
                return false
            }
            
            for keyPath in Self.requiredKeys(forLanguage: language) {
                let value: Any? = self[keyPath: keyPath]
                if value == nil {
                    return false
                }
            }
            
            return true
        }

        public var subjectForm: String?
        public var objectForm: String?
        public var possessiveForm: String?
        public var possessiveAdjectiveForm: String?
        public var reflexiveForm: String?
    }
}

// MARK: -
// MARK: NSAttributedString Keys

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension NSAttributedString.Key {
    public static let morphology = NSAttributedString.Key(rawValue: "NSMorphology")
    public static let inflectionRule = NSAttributedString.Key(rawValue: "NSInflect")
    public static let inflectionAlternative = NSAttributedString.Key(rawValue: "NSInflectionAlternative")
    public static let language = NSAttributedString.Key(rawValue: "NSLanguage")
}
