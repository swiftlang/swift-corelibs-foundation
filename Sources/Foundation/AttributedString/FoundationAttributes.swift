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

// MARK: Attribute Scope

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeScopes {
    public var foundation: FoundationAttributes.Type { FoundationAttributes.self }
    
    public struct FoundationAttributes : AttributeScope {
        public let link: LinkAttribute
        public let morphology: MorphologyAttribute
        public let inflect: InflectionRuleAttribute
        public let languageIdentifier: LanguageIdentifierAttribute
        public let personNameComponent: PersonNameComponentAttribute
        public let numberFormat: NumberFormatAttributes
        public let dateField: DateFieldAttribute
        public let replacementIndex : ReplacementIndexAttribute
        public let measurement: MeasurementAttribute
        public let inflectionAlternative: InflectionAlternativeAttribute
        public let byteCount: ByteCountAttribute
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
public extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.FoundationAttributes, T>) -> T {
        return self[T.self]
    }

    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.FoundationAttributes.NumberFormatAttributes, T>) -> T { self[T.self] }
}

// MARK: Attribute Definitions

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeScopes.FoundationAttributes {
    @frozen
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public enum LinkAttribute : CodableAttributedStringKey, ObjectiveCConvertibleAttributedStringKey {
        public typealias Value = URL
        public typealias ObjectiveCValue = NSObject // NSURL or NSString
        public static var name = "NSLink"
        
        public static func objectiveCValue(for value: URL) throws -> NSObject {
            value as NSURL
        }
        
        public static func value(for object: NSObject) throws -> URL {
            if let object = object as? NSURL {
                return object as URL
            } else if let object = object as? NSString {
                // TODO: Do we need to call up to [NSTextView _URLForString:] on macOS here?
                if let result = URL(string: object as String) {
                    return result
                }
            }
            throw CocoaError(.coderInvalidValue)
        }
    }
    
    @frozen
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public enum MorphologyAttribute : CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        public typealias Value = Morphology
        public static let name = NSAttributedString.Key.morphology.rawValue
        public static let markdownName = "morphology"
    }

    @frozen
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public enum InflectionRuleAttribute : CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        public typealias Value = InflectionRule
        public static let name = NSAttributedString.Key.inflectionRule.rawValue
        public static let markdownName = "inflect"
    }

    @frozen
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public enum LanguageIdentifierAttribute : CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        public typealias Value = String
        public static let name = NSAttributedString.Key.language.rawValue
        public static let markdownName = "languageIdentifier"
    }
    
    @frozen
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public enum PersonNameComponentAttribute : CodableAttributedStringKey, ObjectiveCConvertibleAttributedStringKey {
        public typealias Value = Component
        public typealias ObjectiveCValue = NSString
        public static let name = "NSPersonNameComponentKey"

        public enum Component: String, Codable {
            case givenName, familyName, middleName, namePrefix, nameSuffix, nickname, delimiter
        }
    }

    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public struct NumberFormatAttributes: AttributeScope {
        public let numberSymbol: SymbolAttribute
        public let numberPart: NumberPartAttribute

        @frozen
        public enum NumberPartAttribute : CodableAttributedStringKey {
            public enum NumberPart : Int, Codable {
                case integer
                case fraction
            }

            public static let name = "Foundation.NumberFormatPart"
            public typealias Value = NumberPart
        }

        @frozen
        public enum SymbolAttribute : CodableAttributedStringKey {
            public enum Symbol : Int, Codable {
                case groupingSeparator
                case sign
                case decimalSeparator
                case currency
                case percent
            }

            public static let name = "Foundation.NumberFormatSymbol"
            public typealias Value = Symbol
        }
    }

    @frozen
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public enum DateFieldAttribute : CodableAttributedStringKey {
        public enum Field : Hashable, Codable {
            case era
            case year
            /// For non-Gregorian calendars, this corresponds to the extended Gregorian year in which the calendar’s year begins.
            case relatedGregorianYear
            case quarter
            case month
            case weekOfYear
            case weekOfMonth
            case weekday
            /// The ordinal position of the weekday unit within the month unit. For example, `2` in "2nd Wednesday in July"
            case weekdayOrdinal
            case day
            case dayOfYear
            case amPM
            case hour
            case minute
            case second
            case secondFraction
            case timeZone

            var rawValue: String {
                switch self {
                case .era:
                    return "G"
                case .year:
                    return "y"
                case .relatedGregorianYear:
                    return "r"
                case .quarter:
                    return "Q"
                case .month:
                    return "M"
                case .weekOfYear:
                    return "w"
                case .weekOfMonth:
                    return "W"
                case .weekday:
                    return "E"
                case .weekdayOrdinal:
                    return "F"
                case .day:
                    return "d"
                case .dayOfYear:
                    return "D"
                case .amPM:
                    return "a"
                case .hour:
                    return "h"
                case .minute:
                    return "m"
                case .second:
                    return "s"
                case .secondFraction:
                    return "S"
                case .timeZone:
                    return "z"
                }
            }

            init?(rawValue: String) {
                let mappings: [String: Self] = [
                    "G": .era,
                    "y": .year,
                    "Y": .year,
                    "u": .year,
                    "U": .year,
                    "r": .relatedGregorianYear,
                    "Q": .quarter,
                    "q": .quarter,
                    "M": .month,
                    "L": .month,
                    "w": .weekOfYear,
                    "W": .weekOfMonth,
                    "e": .weekday,
                    "c": .weekday,
                    "E": .weekday,
                    "F": .weekdayOrdinal,
                    "d": .day,
                    "g": .day,
                    "D": .dayOfYear,
                    "a": .amPM,
                    "b": .amPM,
                    "B": .amPM,
                    "h": .hour,
                    "H": .hour,
                    "k": .hour,
                    "K": .hour,
                    "m": .minute,
                    "s": .second,
                    "A": .second,
                    "S": .secondFraction,
                    "v": .timeZone,
                    "z": .timeZone,
                    "Z": .timeZone,
                    "O": .timeZone,
                    "V": .timeZone,
                    "X": .timeZone,
                    "x": .timeZone,
                ]

                guard let field = mappings[rawValue] else {
                    return nil
                }
                self = field
            }

            // Codable
            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let rawValue = try container.decode(String.self)
                guard let field = Field(rawValue: rawValue) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid Field pattern <\(rawValue)>."))
                }
                self = field
            }

            public func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(rawValue)
            }
        }

        public static let name = "Foundation.DateFormatField"
        public typealias Value = Field
    }

    @frozen
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public enum InflectionAlternativeAttribute : CodableAttributedStringKey, MarkdownDecodableAttributedStringKey, ObjectiveCConvertibleAttributedStringKey {
        public typealias Value = AttributedString
        public typealias ObjectiveCValue = NSObject
        public static let name = NSAttributedString.Key.inflectionAlternative.rawValue
        public static let markdownName = "inflectionAlternative"
        
        public static func objectiveCValue(for value: AttributedString) throws -> NSObject {
            try NSAttributedString(value, including: \.foundation)
        }
        
        public static func value(for object: NSObject) throws -> AttributedString {
            if let attrString = object as? NSAttributedString {
                return try AttributedString(attrString, including: \.foundation)
            } else {
                throw CocoaError(.coderInvalidValue)
            }
        }
    }

    @frozen
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public enum ReplacementIndexAttribute : CodableAttributedStringKey {
        public typealias Value = Int
        public static let name = "NSReplacementIndex"
    }

    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public struct MeasurementAttribute: CodableAttributedStringKey {
        public typealias Value = Component
        public static let name = "Foundation.MeasurementAttribute"
        public enum Component: Int, Codable {
            case value
            case unit
        }
    }
    
    @frozen
    @available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
    public enum ByteCountAttribute: CodableAttributedStringKey {
        public typealias Value = Component
        public static let name = "Foundation.ByteCountAttribute"
        public enum Component: Codable, Hashable {
            case value
            case spelledOutValue
            case unit(Unit)
            case actualByteCount
        }
        
        public enum Unit: Codable {
            case byte
            case kb
            case mb
            case gb
            case tb
            case pb
            case eb
            case zb
            case yb
        }
    }
}
