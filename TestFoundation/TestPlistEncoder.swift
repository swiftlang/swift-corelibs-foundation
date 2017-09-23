// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
    import Foundation
    import XCTest
#else
    import SwiftFoundation
    import SwiftXCTest
#endif

// MARK: - Test Suite

class TestPropertyListEncoderSuper : XCTestCase { }

class TestPropertyListEncoder : TestPropertyListEncoderSuper {
  // MARK: - Encoding Top-Level Empty Types
  func test_encodingTopLevelEmptyStruct() {
    let empty = EmptyStruct()
    _testRoundTrip(of: empty, in: .binary, expectedPlist: _plistEmptyDictionaryBinary)
    _testRoundTrip(of: empty, in: .xml, expectedPlist: _plistEmptyDictionaryXML)
  }

  func test_encodingTopLevelEmptyClass() {
    let empty = EmptyClass()
    _testRoundTrip(of: empty, in: .binary, expectedPlist: _plistEmptyDictionaryBinary)
    _testRoundTrip(of: empty, in: .xml, expectedPlist: _plistEmptyDictionaryXML)
  }

  // MARK: - Encoding Top-Level Single-Value Types
  func test_encodingTopLevelSingleValueEnum() {
    let s1 = Switch.off
    _testEncodeFailure(of: s1, in: .binary)
    _testEncodeFailure(of: s1, in: .xml)
    _testRoundTrip(of: TopLevelWrapper(s1), in: .binary)
    _testRoundTrip(of: TopLevelWrapper(s1), in: .xml)

    let s2 = Switch.on
    _testEncodeFailure(of: s2, in: .binary)
    _testEncodeFailure(of: s2, in: .xml)
    _testRoundTrip(of: TopLevelWrapper(s2), in: .binary)
    _testRoundTrip(of: TopLevelWrapper(s2), in: .xml)
  }

  func test_encodingTopLevelSingleValueStruct() {
    let t = Timestamp(3141592653)
    _testEncodeFailure(of: t, in: .binary)
    _testEncodeFailure(of: t, in: .xml)
    _testRoundTrip(of: TopLevelWrapper(t), in: .binary)
    _testRoundTrip(of: TopLevelWrapper(t), in: .xml)
  }

  func test_encodingTopLevelSingleValueClass() {
    let c = Counter()
    _testEncodeFailure(of: c, in: .binary)
    _testEncodeFailure(of: c, in: .xml)
    _testRoundTrip(of: TopLevelWrapper(c), in: .binary)
    _testRoundTrip(of: TopLevelWrapper(c), in: .xml)
  }

  // MARK: - Encoding Top-Level Structured Types
  func test_encodingTopLevelStructuredStruct() {
    // Address is a struct type with multiple fields.
    let address = Address.testValue
    _testRoundTrip(of: address, in: .binary)
    _testRoundTrip(of: address, in: .xml)
  }

  func test_encodingTopLevelStructuredClass() {
    // Person is a class with multiple fields.
    let person = Person.testValue
    _testRoundTrip(of: person, in: .binary)
    _testRoundTrip(of: person, in: .xml)
  }

  func test_encodingTopLevelStructuredSingleStruct() {
    // Numbers is a struct which encodes as an array through a single value container.
    let numbers = Numbers.testValue
    _testRoundTrip(of: numbers, in: .binary)
    _testRoundTrip(of: numbers, in: .xml)
  }

  func test_encodingTopLevelStructuredSingleClass() {
    // Mapping is a class which encodes as a dictionary through a single value container.
    let mapping = Mapping.testValue
    _testRoundTrip(of: mapping, in: .binary)
    _testRoundTrip(of: mapping, in: .xml)
  }

  func test_encodingTopLevelDeepStructuredType() {
    // Company is a type with fields which are Codable themselves.
    let company = Company.testValue
    _testRoundTrip(of: company, in: .binary)
    _testRoundTrip(of: company, in: .xml)
  }

  func test_encodingClassWhichSharesEncoderWithSuper() {
    // Employee is a type which shares its encoder & decoder with its superclass, Person.
    let employee = Employee.testValue
    _testRoundTrip(of: employee, in: .binary)
    _testRoundTrip(of: employee, in: .xml)
  }

  func test_encodingTopLevelNullableType() {
    // EnhancedBool is a type which encodes either as a Bool or as nil.
    _testEncodeFailure(of: EnhancedBool.true, in: .binary)
    _testEncodeFailure(of: EnhancedBool.true, in: .xml)
    _testEncodeFailure(of: EnhancedBool.false, in: .binary)
    _testEncodeFailure(of: EnhancedBool.false, in: .xml)
    _testEncodeFailure(of: EnhancedBool.fileNotFound, in: .binary)
    _testEncodeFailure(of: EnhancedBool.fileNotFound, in: .xml)

    _testRoundTrip(of: TopLevelWrapper(EnhancedBool.true), in: .binary)
    _testRoundTrip(of: TopLevelWrapper(EnhancedBool.true), in: .xml)
    _testRoundTrip(of: TopLevelWrapper(EnhancedBool.false), in: .binary)
    _testRoundTrip(of: TopLevelWrapper(EnhancedBool.false), in: .xml)
    _testRoundTrip(of: TopLevelWrapper(EnhancedBool.fileNotFound), in: .binary)
    _testRoundTrip(of: TopLevelWrapper(EnhancedBool.fileNotFound), in: .xml)
  }

  // MARK: - Encoder Features
  func test_nestedContainerCodingPaths() {
    let encoder = JSONEncoder()
    do {
      let _ = try encoder.encode(NestedContainersTestType())
    } catch let error {
      XCTFail("Caught error during encoding nested container types: \(error)")
    }
  }

  func test_superEncoderCodingPaths() {
    let encoder = JSONEncoder()
    do {
      let _ = try encoder.encode(NestedContainersTestType(testSuperEncoder: true))
    } catch let error {
      XCTFail("Caught error during encoding nested container types: \(error)")
    }
  }

  func test_encodingTopLevelData() {
    let data = try! JSONSerialization.data(withJSONObject: [], options: [])
    _testRoundTrip(of: data, in: .binary, expectedPlist: try! PropertyListSerialization.data(fromPropertyList: data, format: .binary, options: 0))
    _testRoundTrip(of: data, in: .xml, expectedPlist: try! PropertyListSerialization.data(fromPropertyList: data, format: .xml, options: 0))
  }

  func test_interceptData() {
    let data = try! JSONSerialization.data(withJSONObject: [], options: [])
    let topLevel = TopLevelWrapper(data)
    let plist = ["value": data]
    _testRoundTrip(of: topLevel, in: .binary, expectedPlist: try! PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0))
    _testRoundTrip(of: topLevel, in: .xml, expectedPlist: try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0))
  }

  func test_interceptDate() {
    let date = Date(timeIntervalSinceReferenceDate: 0)
    let topLevel = TopLevelWrapper(date)
    let plist = ["value": date]
    _testRoundTrip(of: topLevel, in: .binary, expectedPlist: try! PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0))
    _testRoundTrip(of: topLevel, in: .xml, expectedPlist: try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0))
  }

  // MARK: - Helper Functions
  private var _plistEmptyDictionaryBinary: Data {
    return Data(base64Encoded: "YnBsaXN0MDDQCAAAAAAAAAEBAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAJ")!
  }

  private var _plistEmptyDictionaryXML: Data {
    return "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict/>\n</plist>\n".data(using: .utf8)!
  }

  private func _testEncodeFailure<T : Encodable>(of value: T, in format: PropertyListSerialization.PropertyListFormat) {
    do {
      let encoder = PropertyListEncoder()
      encoder.outputFormat = format
      let _ = try encoder.encode(value)
      XCTFail("Encode of top-level \(T.self) was expected to fail.")
    } catch {}
  }

  private func _testRoundTrip<T>(of value: T, in format: PropertyListSerialization.PropertyListFormat, expectedPlist plist: Data? = nil) where T : Codable, T : Equatable {
    var payload: Data! = nil
    do {
      let encoder = PropertyListEncoder()
      encoder.outputFormat = format
      payload = try encoder.encode(value)
    } catch {
      XCTFail("Failed to encode \(T.self) to plist: \(error)")
    }

    if let expectedPlist = plist {
      XCTAssertEqual(expectedPlist, payload, "Produced plist not identical to expected plist.")
    }

    do {
      var decodedFormat: PropertyListSerialization.PropertyListFormat = .xml
      let decoded = try PropertyListDecoder().decode(T.self, from: payload, format: &decodedFormat)
      XCTAssertEqual(format, decodedFormat, "Encountered plist format differed from requested format.")
      XCTAssertEqual(decoded, value, "\(T.self) did not round-trip to an equal value.")
    } catch {
      XCTFail("Failed to decode \(T.self) from plist: \(error)")
    }
  }
}

// MARK: - Helper Global Functions
func XCTAssertEqualPaths(_ lhs: [CodingKey], _ rhs: [CodingKey], _ prefix: String) {
  if lhs.count != rhs.count {
    XCTFail("\(prefix) [CodingKey].count mismatch: \(lhs.count) != \(rhs.count)")
    return
  }

  for (key1, key2) in zip(lhs, rhs) {
    switch (key1.intValue, key2.intValue) {
    case (.none, .none): break
    case (.some(let i1), .none):
      XCTFail("\(prefix) CodingKey.intValue mismatch: \(type(of: key1))(\(i1)) != nil")
      return
    case (.none, .some(let i2)):
      XCTFail("\(prefix) CodingKey.intValue mismatch: nil != \(type(of: key2))(\(i2))")
      return
    case (.some(let i1), .some(let i2)):
        guard i1 == i2 else {
            XCTFail("\(prefix) CodingKey.intValue mismatch: \(type(of: key1))(\(i1)) != \(type(of: key2))(\(i2))")
            return
        }

        break
    }

    XCTAssertEqual(key1.stringValue, key2.stringValue, "\(prefix) CodingKey.stringValue mismatch: \(type(of: key1))('\(key1.stringValue)') != \(type(of: key2))('\(key2.stringValue)')")
  }
}

// MARK: - Test Types
/* FIXME: Import from %S/Inputs/Coding/SharedTypes.swift somehow. */

// MARK: - Empty Types
fileprivate struct EmptyStruct : Codable, Equatable {
  static func ==(_ lhs: EmptyStruct, _ rhs: EmptyStruct) -> Bool {
    return true
  }
}

fileprivate class EmptyClass : Codable, Equatable {
  static func ==(_ lhs: EmptyClass, _ rhs: EmptyClass) -> Bool {
    return true
  }
}

// MARK: - Single-Value Types
/// A simple on-off switch type that encodes as a single Bool value.
fileprivate enum Switch : Codable {
  case off
  case on

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    switch try container.decode(Bool.self) {
    case false: self = .off
    case true:  self = .on
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .off: try container.encode(false)
    case .on:  try container.encode(true)
    }
  }
}

/// A simple timestamp type that encodes as a single Double value.
fileprivate struct Timestamp : Codable, Equatable {
  let value: Double

  init(_ value: Double) {
    self.value = value
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    value = try container.decode(Double.self)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.value)
  }

  static func ==(_ lhs: Timestamp, _ rhs: Timestamp) -> Bool {
    return lhs.value == rhs.value
  }
}

/// A simple referential counter type that encodes as a single Int value.
fileprivate final class Counter : Codable, Equatable {
  var count: Int = 0

  init() {}

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    count = try container.decode(Int.self)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.count)
  }

  static func ==(_ lhs: Counter, _ rhs: Counter) -> Bool {
    return lhs === rhs || lhs.count == rhs.count
  }
}

// MARK: - Structured Types
/// A simple address type that encodes as a dictionary of values.
fileprivate struct Address : Codable, Equatable {
  let street: String
  let city: String
  let state: String
  let zipCode: Int
  let country: String

  init(street: String, city: String, state: String, zipCode: Int, country: String) {
    self.street = street
    self.city = city
    self.state = state
    self.zipCode = zipCode
    self.country = country
  }

  static func ==(_ lhs: Address, _ rhs: Address) -> Bool {
    return lhs.street == rhs.street &&
           lhs.city == rhs.city &&
           lhs.state == rhs.state &&
           lhs.zipCode == rhs.zipCode &&
           lhs.country == rhs.country
  }

  static var testValue: Address {
    return Address(street: "1 Infinite Loop",
                   city: "Cupertino",
                   state: "CA",
                   zipCode: 95014,
                   country: "United States")
  }
}

/// A simple person class that encodes as a dictionary of values.
fileprivate class Person : Codable, Equatable {
  let name: String
  let email: String
  let website: URL?

  init(name: String, email: String, website: URL? = nil) {
    self.name = name
    self.email = email
    self.website = website
  }

  private enum CodingKeys : String, CodingKey {
    case name
    case email
    case website
  }

  // FIXME: Remove when subclasses (Employee) are able to override synthesized conformance.
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    email = try container.decode(String.self, forKey: .email)
    website = try container.decodeIfPresent(URL.self, forKey: .website)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(email, forKey: .email)
    try container.encodeIfPresent(website, forKey: .website)
  }

  func isEqual(_ other: Person) -> Bool {
    return self.name == other.name &&
           self.email == other.email &&
           self.website == other.website
  }

  static func ==(_ lhs: Person, _ rhs: Person) -> Bool {
    return lhs.isEqual(rhs)
  }

  class var testValue: Person {
    return Person(name: "Johnny Appleseed", email: "appleseed@apple.com")
  }
}

/// A class which shares its encoder and decoder with its superclass.
fileprivate class Employee : Person {
  let id: Int

  init(name: String, email: String, website: URL? = nil, id: Int) {
    self.id = id
    super.init(name: name, email: email, website: website)
  }

  enum CodingKeys : String, CodingKey {
    case id
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int.self, forKey: .id)
    try super.init(from: decoder)
  }

  override func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try super.encode(to: encoder)
  }

  override func isEqual(_ other: Person) -> Bool {
    if let employee = other as? Employee {
      guard self.id == employee.id else { return false }
    }

    return super.isEqual(other)
  }

  override class var testValue: Employee {
    return Employee(name: "Johnny Appleseed", email: "appleseed@apple.com", id: 42)
  }
}

/// A simple company struct which encodes as a dictionary of nested values.
fileprivate struct Company : Codable, Equatable {
  let address: Address
  var employees: [Employee]

  init(address: Address, employees: [Employee]) {
    self.address = address
    self.employees = employees
  }

  static func ==(_ lhs: Company, _ rhs: Company) -> Bool {
    return lhs.address == rhs.address && lhs.employees == rhs.employees
  }

  static var testValue: Company {
    return Company(address: Address.testValue, employees: [Employee.testValue])
  }
}

/// An enum type which decodes from Bool?.
fileprivate enum EnhancedBool : Codable {
  case `true`
  case `false`
  case fileNotFound

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .fileNotFound
    } else {
      let value = try container.decode(Bool.self)
      self = value ? .true : .false
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .true: try container.encode(true)
    case .false: try container.encode(false)
    case .fileNotFound: try container.encodeNil()
    }
  }
}

/// A type which encodes as a dictionary directly through a single value container.
fileprivate final class Mapping : Codable, Equatable {
  let values: [String : URL]

  init(values: [String : URL]) {
    self.values = values
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    values = try container.decode([String : URL].self)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(values)
  }

  static func ==(_ lhs: Mapping, _ rhs: Mapping) -> Bool {
    return lhs === rhs || lhs.values == rhs.values
  }

  static var testValue: Mapping {
    return Mapping(values: ["Apple": URL(string: "http://apple.com")!,
                            "localhost": URL(string: "http://127.0.0.1")!])
  }
}

// MARK: - Helper Types

/// A key type which can take on any string or integer value.
/// This needs to mirror _PlistKey.
fileprivate struct _TestKey : CodingKey {
  var stringValue: String
  var intValue: Int?

  init?(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }

  init?(intValue: Int) {
    self.stringValue = "\(intValue)"
    self.intValue = intValue
  }

  init(index: Int) {
    self.stringValue = "Index \(index)"
    self.intValue = index
  }
}

/// Wraps a type T so that it can be encoded at the top level of a payload.
fileprivate struct TopLevelWrapper<T> : Codable, Equatable where T : Codable, T : Equatable {
  let value: T

  init(_ value: T) {
    self.value = value
  }

  static func ==(_ lhs: TopLevelWrapper<T>, _ rhs: TopLevelWrapper<T>) -> Bool {
    return lhs.value == rhs.value
  }
}

// MARK: - Run Tests

extension TestPropertyListEncoder {
    static var allTests: [(String, (TestPropertyListEncoder) -> () throws -> Void)] {
        return [
            ("test_encodingTopLevelEmptyStruct", test_encodingTopLevelEmptyStruct),
            ("test_encodingTopLevelEmptyClass", test_encodingTopLevelEmptyClass),
            ("test_encodingTopLevelSingleValueEnum", test_encodingTopLevelSingleValueEnum),
            ("test_encodingTopLevelSingleValueStruct", test_encodingTopLevelSingleValueStruct),
            ("test_encodingTopLevelSingleValueClass", test_encodingTopLevelSingleValueClass),
            ("test_encodingTopLevelStructuredStruct", test_encodingTopLevelStructuredStruct),
            ("test_encodingTopLevelStructuredClass", test_encodingTopLevelStructuredClass),
            ("test_encodingTopLevelStructuredSingleStruct", test_encodingTopLevelStructuredSingleStruct),
            ("test_encodingTopLevelStructuredSingleClass", test_encodingTopLevelStructuredSingleClass),
            ("test_encodingTopLevelDeepStructuredType", test_encodingTopLevelDeepStructuredType),
            ("test_encodingClassWhichSharesEncoderWithSuper", test_encodingClassWhichSharesEncoderWithSuper),
            ("test_encodingTopLevelNullableType", test_encodingTopLevelNullableType),
            ("test_nestedContainerCodingPaths", test_nestedContainerCodingPaths),
            ("test_superEncoderCodingPaths", test_superEncoderCodingPaths),
            ("test_encodingTopLevelData", test_encodingTopLevelData),
            ("test_interceptData", test_interceptData),
            ("test_interceptDate", test_interceptDate),
        ]
    }
}

