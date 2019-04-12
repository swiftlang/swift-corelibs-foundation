// This source file is part of the Swift.org open source project
//
// Copyright (c) 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

// Please keep this import statement as-is; this file is also used by the GenerateTestFixtures project, which doesn't have TestImports.swift.

#if DEPLOYMENT_RUNTIME_SWIFT && (os(macOS) || os(iOS) || os(watchOS) || os(tvOS))
    import SwiftFoundation
#else
    import Foundation
#endif

// -----

enum Fixtures {
    static let mutableAttributedString = TypedFixture<NSMutableAttributedString>("NSMutableAttributedString") {
        let string = NSMutableAttributedString(string: "0123456789")
        // Should have:                                 .xyyzzxyx.
        
        let attrs1: [NSAttributedString.Key: Any] = [.init("Font"): "Helvetica", .init("Size"): 123]
        let attrs2: [NSAttributedString.Key: Any] = [.init("Font"): "Times", .init("Size"): 456]
        
        let attrs3NS = attrs2 as NSDictionary
        let attrs3Maybe: [NSAttributedString.Key: Any]?
        if let attrs3Swift = attrs3NS as? [String: Any] {
            attrs3Maybe = Dictionary(attrs3Swift.map { (NSAttributedString.Key($0.key), $0.value) }, uniquingKeysWith: { $1 })
        } else {
            attrs3Maybe = nil
        }
        
        let attrs3 = try attrs3Maybe.unwrapped()
        
        string.setAttributes(attrs1, range: NSMakeRange(1, string.length - 2))
        string.setAttributes(attrs2, range: NSMakeRange(2, 2))
        string.setAttributes(attrs3, range: NSMakeRange(4, 2))
        string.setAttributes(attrs2, range: NSMakeRange(8, 1))
        
        return string
    }
    
    static let attributedString = TypedFixture<NSAttributedString>("NSAttributedString") {
        return NSAttributedString(attributedString: try Fixtures.mutableAttributedString.make())
    }
    
    // ===== ByteCountFormatter =====
    
    static let byteCountFormatterDefault = TypedFixture<ByteCountFormatter>("ByteCountFormatter-Default") {
        return ByteCountFormatter()
    }
    
    static let byteCountFormatterAllFieldsSet = TypedFixture<ByteCountFormatter>("ByteCountFormatter-AllFieldsSet") {
        let f = ByteCountFormatter()
        
        f.allowedUnits = [.useBytes, .useKB]
        f.countStyle = .decimal
        f.formattingContext = .beginningOfSentence
        
        f.zeroPadsFractionDigits = true
        f.includesCount = true
        
        f.allowsNonnumericFormatting = false
        f.includesUnit = false
        f.includesCount = false
        f.isAdaptive = false
        
        return f
    }
    
    // ===== Fixture list =====
    
    static let all: [AnyFixture] = [
        AnyFixture(Fixtures.mutableAttributedString),
        AnyFixture(Fixtures.attributedString),
        AnyFixture(Fixtures.byteCountFormatterDefault),
        AnyFixture(Fixtures.byteCountFormatterAllFieldsSet),
    ]
}

// -----

// Support for the above:

enum FixtureVariant: String, CaseIterable {
    case macOS10_14 = "macOS-10.14"
    
    func url(fixtureRepository: URL) -> URL {
        return URL(fileURLWithPath: self.rawValue, relativeTo: fixtureRepository)
    }
}

protocol Fixture {
    associatedtype ValueType
    var identifier: String { get }
    func make() throws -> ValueType
    var supportsSecureCoding: Bool { get }
}

struct TypedFixture<ValueType: NSObject & NSCoding>: Fixture {
    var identifier: String
    private var creationHandler: () throws -> ValueType
    
    init(_ identifier: String, creationHandler: @escaping () throws -> ValueType) {
        self.identifier = identifier
        self.creationHandler = creationHandler
    }
    
    func make() throws -> ValueType {
        return try creationHandler()
    }
    
    var supportsSecureCoding: Bool {
        return (ValueType.self as? NSSecureCoding.Type)?.supportsSecureCoding == true
    }
}

struct AnyFixture: Fixture {
    var identifier: String
    private var creationHandler: () throws -> NSObject & NSCoding
    let supportsSecureCoding: Bool
    
    init<T: Fixture>(_ fixture: T) {
        self.identifier = fixture.identifier
        self.creationHandler = { return try fixture.make() as! (NSObject & NSCoding) }
        self.supportsSecureCoding = fixture.supportsSecureCoding
    }
    
    func make() throws -> NSObject & NSCoding {
        return try creationHandler()
    }
}

enum FixtureError: Error {
    case noneFound
}

extension Fixture where ValueType: NSObject & NSCoding {
    func load(fixtureRepository: URL, variant: FixtureVariant) throws -> ValueType? {
        let data = try Data(contentsOf: url(inFixtureRepository: fixtureRepository, variant: variant))
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)
        unarchiver.requiresSecureCoding = self.supportsSecureCoding
        
        let value = unarchiver.decodeObject(of: ValueType.self, forKey: NSKeyedArchiveRootObjectKey)
        if let error = unarchiver.error {
            throw error
        }
        return value
    }
    
    func url(inFixtureRepository fixtureRepository: URL, variant: FixtureVariant) -> URL {
        return variant.url(fixtureRepository: fixtureRepository)
            .appendingPathComponent(identifier)
            .appendingPathExtension("archive")
    }
    
    func loadEach(fixtureRepository: URL, handler: (ValueType, FixtureVariant) throws -> Void) throws {
        var foundAny = false
        
        for variant in FixtureVariant.allCases {
            let fileURL = url(inFixtureRepository: fixtureRepository, variant: variant)
            guard (try? fileURL.checkResourceIsReachable()) == true else { continue }
            
            foundAny = true
            
            if let value = try load(fixtureRepository: fixtureRepository, variant: variant) {
                try handler(value, variant)
            }
        }
        
        guard foundAny else { throw FixtureError.noneFound }
    }
}
