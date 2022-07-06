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

#if NS_FOUNDATION_ALLOWS_TESTABLE_IMPORT
    #if canImport(SwiftFoundation) && !DEPLOYMENT_RUNTIME_OBJC
        @testable import SwiftFoundation
    #else
        @testable import Foundation
    #endif
#endif

extension NSAttributedString.Key {
    static let testInt = NSAttributedString.Key("TestInt")
    static let testString = NSAttributedString.Key("TestString")
    static let testDouble = NSAttributedString.Key("TestDouble")
    static let testBool = NSAttributedString.Key("TestBool")
    static let link: NSAttributedString.Key = .init(rawValue: "NSLink")
}

struct Color : Hashable, Codable {
    let name: String
    
    static let black: Color = Color(name: "black")
    static let blue: Color = Color(name: "black")
    static let white: Color = Color(name: "white")
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeScopes.TestAttributes {

    enum TestIntAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        typealias Value = Int
        static let name = "TestInt"
    }

    enum TestStringAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        typealias Value = String
        static let name = "TestString"
    }

    enum TestDoubleAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        typealias Value = Double
        static let name = "TestDouble"
    }

    enum TestBoolAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        typealias Value = Bool
        static let name = "TestBool"
    }
    
    enum TestForegroundColorAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        typealias Value = Color
        static let name = "ForegroundColor"
    }
    
    enum TestBackgroundColorAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
        typealias Value = Color
        static let name = "BackgroundColor"
    }

    #if false
    @frozen enum MisspelledAttribute : CodableAttributedStringKey, FixableAttribute {
        typealias Value = Bool
        static let name = "Misspelled"
        
        public static func fixAttribute(in string: inout AttributedString) {
            let words = string.characters.subranges {
                !$0.isWhitespace && !$0.isPunctuation
            }
            
            // First make sure that no non-words are marked as misspelled
            let nonWords = RangeSet(string.startIndex ..< string.endIndex).subtracting(words)
            string[nonWords].misspelled = nil
            
            // Then make sure that any word ranges containing the attribute span the entire word
            for (misspelled, range) in string.runs[\.misspelledAttribute] {
                if let misspelled = misspelled, misspelled {
                    let fullRange = words.ranges[words.ranges.firstIndex { $0.contains(range.lowerBound) }!]
                    string[fullRange].misspelled = true
                }
            }
        }
    }
    #endif

    enum NonCodableAttribute : AttributedStringKey {
        typealias Value = NonCodableType
        static let name = "NonCodable"
    }

    enum CustomCodableAttribute : CodableAttributedStringKey {
        typealias Value = NonCodableType
        static let name = "NonCodableConvertible"
        
        static func encode(_ value: NonCodableType, to encoder: Encoder) throws {
            var c = encoder.singleValueContainer()
            try c.encode(value.inner)
        }
        
        static func decode(from decoder: Decoder) throws -> NonCodableType {
            let c = try decoder.singleValueContainer()
            let inner = try c.decode(Int.self)
            return NonCodableType(inner: inner)
        }
    }
    
}

struct NonCodableType : Hashable {
    var inner : Int
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeScopes {
    var test: TestAttributes.Type { TestAttributes.self }
    
    struct TestAttributes : AttributeScope {
        var testInt : TestIntAttribute
        var testString : TestStringAttribute
        var testDouble : TestDoubleAttribute
        var testBool : TestBoolAttribute
        var foregroundColor: TestForegroundColorAttribute
        var backgroundColor: TestBackgroundColorAttribute
    #if false
        var misspelled : MisspelledAttribute
    #endif
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.TestAttributes, T>) -> T {
        get { self[T.self] }
    }
}
