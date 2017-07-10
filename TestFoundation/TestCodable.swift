// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#else
import SwiftFoundation
import SwiftXCTest
#endif

// MARK: - Helper Functions

private func makePersonNameComponents(namePrefix: String? = nil,
                                      givenName: String? = nil,
                                      middleName: String? = nil,
                                      familyName: String? = nil,
                                      nameSuffix: String? = nil,
                                      nickname: String? = nil) -> PersonNameComponents {
    var result = PersonNameComponents()
    result.namePrefix = namePrefix
    result.givenName = givenName
    result.middleName = middleName
    result.familyName = familyName
    result.nameSuffix = nameSuffix
    result.nickname = nickname
    return result
}

func expectRoundTripEquality<T : Codable>(of value: T, encode: (T) throws -> Data, decode: (Data) throws -> T) where T : Equatable {
    let data: Data
    do {
        data = try encode(value)
    } catch {
        fatalError("Unable to encode \(T.self) <\(value)>: \(error)")
    }

    let decoded: T
    do {
        decoded = try decode(data)
    } catch {
        fatalError("Unable to decode \(T.self) <\(value)>: \(error)")
    }

    XCTAssertEqual(value, decoded, "Decoded \(T.self) <\(decoded)> not equal to original <\(value)>")
}

func expectRoundTripEqualityThroughJSON<T : Codable>(for value: T) where T : Equatable {
    let encode = { (_ value: T) throws -> Data in
        return try JSONEncoder().encode(value)
    }

    let decode = { (_ data: Data) throws -> T in
        return try JSONDecoder().decode(T.self, from: data)
    }

    expectRoundTripEquality(of: value, encode: encode, decode: decode)
}

// MARK: - Helper Types
// A wrapper around a UUID that will allow it to be encoded at the top level of an encoder.
struct UUIDCodingWrapper : Codable, Equatable {
    let value: UUID

    init(_ value: UUID) {
        self.value = value
    }

    static func ==(_ lhs: UUIDCodingWrapper, _ rhs: UUIDCodingWrapper) -> Bool {
        return lhs.value == rhs.value
    }
}

// MARK: - Tests
class TestCodable : XCTestCase {

    // MARK: - PersonNameComponents
    lazy var personNameComponentsValues: [PersonNameComponents] = [
        makePersonNameComponents(givenName: "John", familyName: "Appleseed"),
        makePersonNameComponents(givenName: "John", familyName: "Appleseed", nickname: "Johnny"),
        makePersonNameComponents(namePrefix: "Dr.", givenName: "Jane", middleName: "A.", familyName: "Appleseed", nameSuffix: "Esq.", nickname: "Janie")
    ]

    func test_PersonNameComponents_JSON() {
        for components in personNameComponentsValues {
            expectRoundTripEqualityThroughJSON(for: components)
        }
    }

    // MARK: - UUID
    lazy var uuidValues: [UUID] = [
        UUID(),
        UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!,
        UUID(uuidString: "e621e1f8-c36c-495a-93fc-0c247a3e6e5f")!,
        UUID(uuid: uuid_t(0xe6,0x21,0xe1,0xf8,0xc3,0x6c,0x49,0x5a,0x93,0xfc,0x0c,0x24,0x7a,0x3e,0x6e,0x5f))
    ]

    func test_UUID_JSON() {
        for uuid in uuidValues {
            // We have to wrap the UUID since we cannot have a top-level string.
            expectRoundTripEqualityThroughJSON(for: UUIDCodingWrapper(uuid))
        }
    }

}

extension TestCodable {
    static var allTests: [(String, (TestCodable) -> () throws -> Void)] {
        return [
            ("test_PersonNameComponents_JSON", test_PersonNameComponents_JSON),
            ("test_UUID_JSON", test_UUID_JSON),
        ]
    }
}
