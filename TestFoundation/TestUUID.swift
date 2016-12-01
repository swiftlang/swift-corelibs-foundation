// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// RUN: %target-run-simple-swift
// REQUIRES: executable_test
// REQUIRES: objc_interop

#if DEPLOYMENT_RUNTIME_OBJC || os(Linux)
import Foundation
import XCTest
#elseif DEPLOYMENT_RUNTIME_SWIFT
import SwiftFoundation
import SwiftXCTest
#endif

class TestUUID : XCTestCase {
    static var allTests: [(String, (TestUUID) -> () throws -> Void)] {
        return [
            ("test_NS_Equality", test_NS_Equality),
            ("test_Equality", test_Equality),
            ("test_NS_InvalidUUID", test_NS_InvalidUUID),
            ("test_InvalidUUID", test_InvalidUUID),
            ("test_NS_uuidString", test_NS_uuidString),
            ("test_uuidString", test_uuidString),
            ("test_description", test_description),
            ("test_roundTrips", test_roundTrips),
            ("test_hash", test_hash),
            ("test_AnyHashableContainingUUID", test_AnyHashableContainingUUID),
            ("test_AnyHashableCreatedFromNSUUID", test_AnyHashableCreatedFromNSUUID),
        ]
    }
    
    func test_NS_Equality() {
        let uuidA = NSUUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        let uuidB = NSUUID(uuidString: "e621e1f8-c36c-495a-93fc-0c247a3e6e5f")
        let uuidC = NSUUID(uuidBytes: [0xe6,0x21,0xe1,0xf8,0xc3,0x6c,0x49,0x5a,0x93,0xfc,0x0c,0x24,0x7a,0x3e,0x6e,0x5f])
        let uuidD = NSUUID()
        
        XCTAssertEqual(uuidA, uuidB, "String case must not matter.")
        XCTAssertEqual(uuidA, uuidC, "A UUID initialized with a string must be equal to the same UUID initialized with its UnsafePointer<UInt8> equivalent representation.")
        XCTAssertNotEqual(uuidC, uuidD, "Two different UUIDs must not be equal.")
    }
    
    func test_Equality() {
        let uuidA = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
        let uuidB = UUID(uuidString: "e621e1f8-c36c-495a-93fc-0c247a3e6e5f")
        let uuidC = UUID(uuid: uuid_t(0xe6,0x21,0xe1,0xf8,0xc3,0x6c,0x49,0x5a,0x93,0xfc,0x0c,0x24,0x7a,0x3e,0x6e,0x5f))
        let uuidD = UUID()
        
        XCTAssertEqual(uuidA, uuidB, "String case must not matter.")
        XCTAssertEqual(uuidA, uuidC, "A UUID initialized with a string must be equal to the same UUID initialized with its UnsafePointer<UInt8> equivalent representation.")
        XCTAssertNotEqual(uuidC, uuidD, "Two different UUIDs must not be equal.")
    }
    
    func test_NS_InvalidUUID() {
        let uuid = NSUUID(uuidString: "Invalid UUID")
        XCTAssertNil(uuid, "The convenience initializer `init?(uuidString string:)` must return nil for an invalid UUID string.")
    }
    
    func test_InvalidUUID() {
        let uuid = UUID(uuidString: "Invalid UUID")
        XCTAssertNil(uuid, "The convenience initializer `init?(uuidString string:)` must return nil for an invalid UUID string.")
    }
    
    func test_NS_uuidString() {
        let uuid = NSUUID(uuidBytes: [0xe6,0x21,0xe1,0xf8,0xc3,0x6c,0x49,0x5a,0x93,0xfc,0x0c,0x24,0x7a,0x3e,0x6e,0x5f])
        XCTAssertEqual(uuid.uuidString, "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
    }
    
    func test_uuidString() {
        let uuid = UUID(uuid: uuid_t(0xe6,0x21,0xe1,0xf8,0xc3,0x6c,0x49,0x5a,0x93,0xfc,0x0c,0x24,0x7a,0x3e,0x6e,0x5f))
        XCTAssertEqual(uuid.uuidString, "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")
    }
    
    func test_description() {
        let uuid = UUID()
        XCTAssertEqual(uuid.description, uuid.uuidString, "The description must be the same as the uuidString.")
    }
    
    func test_roundTrips() {
        let ref = NSUUID()
        let valFromRef = UUID._unconditionallyBridgeFromObjectiveC(ref)
        var bytes: [UInt8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        let valFromBytes = bytes.withUnsafeMutableBufferPointer { buffer -> UUID in
            ref.getBytes(buffer.baseAddress)
            return UUID(uuid: UnsafeRawPointer(buffer.baseAddress!).load(as: uuid_t.self))
        }
        let valFromStr = UUID(uuidString: ref.uuidString)
        XCTAssertEqual(ref.uuidString, valFromRef.uuidString)
        XCTAssertEqual(ref.uuidString, valFromBytes.uuidString)
        XCTAssertNotNil(valFromStr)
        XCTAssertEqual(ref.uuidString, valFromStr!.uuidString)
    }
    
    func test_hash() {
        let ref = NSUUID()
        let val = UUID(uuidString: ref.uuidString)!
        XCTAssertEqual(ref.hashValue, val.hashValue, "Hashes of references and values should be identical")
    }
    
    func test_AnyHashableContainingUUID() {
        let values: [UUID] = [
            UUID(uuidString: "e621e1f8-c36c-495a-93fc-0c247a3e6e5f")!,
            UUID(uuidString: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6")!,
            UUID(uuidString: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6")!,
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(UUID.self, type(of: anyHashables[0].base))
        XCTAssertSameType(UUID.self, type(of: anyHashables[1].base))
        XCTAssertSameType(UUID.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
    
    func test_AnyHashableCreatedFromNSUUID() {
        let values: [NSUUID] = [
            NSUUID(uuidString: "e621e1f8-c36c-495a-93fc-0c247a3e6e5f")!,
            NSUUID(uuidString: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6")!,
            NSUUID(uuidString: "f81d4fae-7dec-11d0-a765-00a0c91e6bf6")!,
            ]
        let anyHashables = values.map(AnyHashable.init)
        XCTAssertSameType(UUID.self, type(of: anyHashables[0].base))
        XCTAssertSameType(UUID.self, type(of: anyHashables[1].base))
        XCTAssertSameType(UUID.self, type(of: anyHashables[2].base))
        XCTAssertNotEqual(anyHashables[0], anyHashables[1])
        XCTAssertEqual(anyHashables[1], anyHashables[2])
    }
}

//#if !FOUNDATION_XCTEST
//var UUIDTests = TestSuite("TestUUID")
//UUIDTests.test("test_NS_Equality") { TestUUID().test_NS_Equality() }
//UUIDTests.test("test_Equality") { TestUUID().test_Equality() }
//UUIDTests.test("test_NS_InvalidUUID") { TestUUID().test_NS_InvalidUUID() }
//UUIDTests.test("test_InvalidUUID") { TestUUID().test_InvalidUUID() }
//UUIDTests.test("test_NS_uuidString") { TestUUID().test_NS_uuidString() }
//UUIDTests.test("test_uuidString") { TestUUID().test_uuidString() }
//UUIDTests.test("test_description") { TestUUID().test_description() }
//UUIDTests.test("test_roundTrips") { TestUUID().test_roundTrips() }
//UUIDTests.test("test_hash") { TestUUID().test_hash() }
//UUIDTests.test("test_AnyHashableContainingUUID") { TestUUID().test_AnyHashableContainingUUID() }
//UUIDTests.test("test_AnyHashableCreatedFromNSUUID") { TestUUID().test_AnyHashableCreatedFromNSUUID() }
//runAllTests()
//#endif

