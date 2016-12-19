// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
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



class TestUUID: XCTestCase {

    static var allTests: [(String, (TestUUID) -> () throws -> Void)] {
        return [
            ("test_initUUIDString_ValidString", test_initUUIDString_ValidString),
            ("test_initUUIDString_Invalid_TimeLow", test_initUUIDString_Invalid_TimeLow),
            ("test_initUUIDString_Invalid_TimeMid", test_initUUIDString_Invalid_TimeMid),
            ("test_initUUIDString_Invalid_Version_TimeHigh", test_initUUIDString_Invalid_Version_TimeHigh),
            ("test_initUUIDString_Invalid_ClockSeq", test_initUUIDString_Invalid_ClockSeq),
            ("test_initUUIDString_Invalid_Node", test_initUUIDString_Invalid_Node),
            ("test_initUUID_T", test_initUUID_T),
            ("test_init", test_init),
            ("test_equality", test_equality),
            ("test_description", test_description),
            ("test_debugDescription", test_debugDescription),
            ("test_uuidString", test_uuidString),
            ("test_customReflection", test_customReflection),
            ("test_bridgeToObjectiveC", test_bridgeToObjectiveC),
            ("test_bridgeFromObjectiveC", test_bridgeFromObjectiveC),
        ]
    }
    
    
    let hex:  uuid_t = (0xe6,0x21,0xe1,0xf8,0xc3,0x6c,0x49,0x5a,0x93,0xfc,0x0c,0x24,0x7a,0x3e,0x6e,0x5f)
    let zero: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    let test: uuid_t = (155, 155, 155, 155, 155, 155, 155, 155, 155, 155, 155, 155, 155, 155, 155, 155)
    let testString   = "9b9b9b9b-9b9b-9b9b-9b9b-9b9b9b9b9b9b"
    let zeroString   = "00000000-0000-0000-0000-000000000000"
    let validUUIDStrings = [
        "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
        "e621e1f8-c36c-495a-93fc-0c247a3e6e5f",
        "0dc71623-0aa6-4b6c-aa6e-59a4f8474871",
        "9f9efe4f-d614-435b-bb34-0b1aeb7cc240",
        "db808267-8bba-4856-97ac-efd5f0fed1ad",
        "6ea59215-290c-4a4d-8b54-e0a199f25479",
        "1d1ef4b2-e515-4696-9423-b0a1a70963a7",
        "506717ff-0bcf-4f69-8bb0-f14e1f7428ef",
        "cf52884b-ca1a-414e-9b7e-26107ec3f03f",
        "ccf56bf6-4a5e-4bf1-9710-04d563179873",
        "d0036e91-5627-48ab-8d82-b1a3a220c9e2",
        "ce92e276-56cd-4dda-80b8-f28ba845d02c",
        "452a9b13-ed08-4499-a9a7-7ccaecbca255",
        "c3a2676a-a1ab-48e1-b5df-16b8c2cea38e",
        "211c1fdf-651e-4dc9-9ac4-332d73a2b3c5",
        "c18e874f-572b-4a4c-8f26-dab17c7c25e0",
        "546839d1-f2fd-413e-a58a-a7c66f50f278",
        "15867986-1f73-4deb-9476-9dcb543e4e65",
        "c2fdf4b6-20fa-4dfa-8167-4063ba08ef7e",
        "cfb3a304-0379-424c-8f87-8ecce831b108",
        "ae3fbdd0-dc1c-4375-bbf9-3c0f3d4fc951",
        "3a432dcc-3c64-4aa1-a170-f151219ecaac"
    ]
    
    
    
    func test_initUUIDString_ValidString() {
        for validString in validUUIDStrings {
            XCTAssertNotNil(UUID(uuidString: validString))
        }
        let zeroUUID = UUID(uuidString:zeroString)
        XCTAssertNotNil(zeroUUID)
    }
    
    func test_initUUIDString_Invalid_TimeLow() {
        let invalidTimeLowA = UUID(uuidString:"621e1f8-c36c-495a-93fc-0c247a3e6e5f")
        let invalidTimeLowB = UUID(uuidString:"21e1f8-c36c-495a-93fc-0c247a3e6e5f")
        let invalidTimeLowC = UUID(uuidString:"1e1f8-c36c-495a-93fc-0c247a3e6e5f")
        let invalidTimeLowD = UUID(uuidString:"e1f8-c36c-495a-93fc-0c247a3e6e5f")
        let invalidTimeLowE = UUID(uuidString:"1f8-c36c-495a-93fc-0c247a3e6e5f")
        let invalidTimeLowF = UUID(uuidString:"f8-c36c-495a-93fc-0c247a3e6e5f")
        let invalidTimeLowG = UUID(uuidString:"8-c36c-495a-93fc-0c247a3e6e5f")
        let invalidTimeLowH = UUID(uuidString:"-c36c-495a-93fc-0c247a3e6e5f")
        
        XCTAssertNil(invalidTimeLowA, "Should be nil but is \(String(describing: invalidTimeLowA))")
        XCTAssertNil(invalidTimeLowB, "Should be nil but is \(String(describing: invalidTimeLowB))")
        XCTAssertNil(invalidTimeLowC, "Should be nil but is \(String(describing: invalidTimeLowC))")
        XCTAssertNil(invalidTimeLowD, "Should be nil but is \(String(describing: invalidTimeLowD))")
        XCTAssertNil(invalidTimeLowE, "Should be nil but is \(String(describing: invalidTimeLowE))")
        XCTAssertNil(invalidTimeLowF, "Should be nil but is \(String(describing: invalidTimeLowF))")
        XCTAssertNil(invalidTimeLowG, "Should be nil but is \(String(describing: invalidTimeLowG))")
        XCTAssertNil(invalidTimeLowH, "Should be nil but is \(String(describing: invalidTimeLowH))")
    }
    
    func test_initUUIDString_Invalid_TimeMid() {
        let invalidTimeMidA = UUID(uuidString:"e621e1f8-36c-495a-93fc-0c247a3e6e5f")
        let invalidTimeMidB = UUID(uuidString:"e621e1f8-6c-495a-93fc-0c247a3e6e5f")
        let invalidTimeMidC = UUID(uuidString:"e621e1f8-c-495a-93fc-0c247a3e6e5f")
        let invalidTimeMidD = UUID(uuidString:"e621e1f8--495a-93fc-0c247a3e6e5f")
        
        XCTAssertNil(invalidTimeMidA, "Should be nil but is \(String(describing: invalidTimeMidA))")
        XCTAssertNil(invalidTimeMidB, "Should be nil but is \(String(describing: invalidTimeMidB))")
        XCTAssertNil(invalidTimeMidC, "Should be nil but is \(String(describing: invalidTimeMidC))")
        XCTAssertNil(invalidTimeMidD, "Should be nil but is \(String(describing: invalidTimeMidD))")
    }

    func test_initUUIDString_Invalid_Version_TimeHigh() {
        let invalidVersionA = UUID(uuidString:"e621e1f8-c36c-95a-93fc-0c247a3e6e5f")
        let invalidVersionB = UUID(uuidString:"e621e1f8-c36c-5a-93fc-0c247a3e6e5f")
        let invalidVersionC = UUID(uuidString:"e621e1f8-c36c-a-93fc-0c247a3e6e5f")
        let invalidVersionD = UUID(uuidString:"e621e1f8-c36c--93fc-0c247a3e6e5f")
        
        XCTAssertNil(invalidVersionA, "Should be nil but is \(String(describing: invalidVersionA))")
        XCTAssertNil(invalidVersionB, "Should be nil but is \(String(describing: invalidVersionB))")
        XCTAssertNil(invalidVersionC, "Should be nil but is \(String(describing: invalidVersionC))")
        XCTAssertNil(invalidVersionD, "Should be nil but is \(String(describing: invalidVersionD))")
    }

    func test_initUUIDString_Invalid_ClockSeq() {
        let invalidClockSeqA = UUID(uuidString:"e621e1f8-c36c-495a-3fc-0c247a3e6e5f")
        let invalidClockSeqB = UUID(uuidString:"e621e1f8-c36c-495a-fc-0c247a3e6e5f")
        let invalidClockSeqC = UUID(uuidString:"e621e1f8-c36c-495a-c-0c247a3e6e5f")
        let invalidClockSeqD = UUID(uuidString:"e621e1f8-c36c-495a--0c247a3e6e5f")
        
        XCTAssertNil(invalidClockSeqA, "Should be nil but is \(String(describing: invalidClockSeqA))")
        XCTAssertNil(invalidClockSeqB, "Should be nil but is \(String(describing: invalidClockSeqB))")
        XCTAssertNil(invalidClockSeqC, "Should be nil but is \(String(describing: invalidClockSeqC))")
        XCTAssertNil(invalidClockSeqD, "Should be nil but is \(String(describing: invalidClockSeqD))")
    }
    
    func test_initUUIDString_Invalid_Node() {
        let invalidNodeA = UUID(uuidString:"e621e1f8-c36c-495a-93fc-c247a3e6e5f")
        let invalidNodeB = UUID(uuidString:"e621e1f8-c36c-495a-93fc-247a3e6e5f")
        let invalidNodeC = UUID(uuidString:"e621e1f8-c36c-495a-93fc-47a3e6e5f")
        let invalidNodeD = UUID(uuidString:"e621e1f8-c36c-495a-93fc-7a3e6e5f")
        let invalidNodeE = UUID(uuidString:"e621e1f8-c36c-495a-93fc-a3e6e5f")
        let invalidNodeF = UUID(uuidString:"e621e1f8-c36c-495a-93fc-3e6e5f")
        let invalidNodeG = UUID(uuidString:"e621e1f8-c36c-495a-93fc-e6e5f")
        let invalidNodeH = UUID(uuidString:"e621e1f8-c36c-495a-93fc-6e5f")
        let invalidNodeI = UUID(uuidString:"e621e1f8-c36c-495a-93fc-e5f")
        let invalidNodeJ = UUID(uuidString:"e621e1f8-c36c-495a-93fc-5f")
        let invalidNodeK = UUID(uuidString:"e621e1f8-c36c-495a-93fc-f")
        let invalidNodeL = UUID(uuidString:"e621e1f8-c36c-495a-93fc-")
        
        XCTAssertNil(invalidNodeA, "Should be nil but is \(String(describing: invalidNodeA))")
        XCTAssertNil(invalidNodeB, "Should be nil but is \(String(describing: invalidNodeB))")
        XCTAssertNil(invalidNodeC, "Should be nil but is \(String(describing: invalidNodeC))")
        XCTAssertNil(invalidNodeD, "Should be nil but is \(String(describing: invalidNodeD))")
        XCTAssertNil(invalidNodeE, "Should be nil but is \(String(describing: invalidNodeE))")
        XCTAssertNil(invalidNodeF, "Should be nil but is \(String(describing: invalidNodeF))")
        XCTAssertNil(invalidNodeG, "Should be nil but is \(String(describing: invalidNodeG))")
        XCTAssertNil(invalidNodeH, "Should be nil but is \(String(describing: invalidNodeH))")
        XCTAssertNil(invalidNodeI, "Should be nil but is \(String(describing: invalidNodeI))")
        XCTAssertNil(invalidNodeJ, "Should be nil but is \(String(describing: invalidNodeJ))")
        XCTAssertNil(invalidNodeK, "Should be nil but is \(String(describing: invalidNodeK))")
        XCTAssertNil(invalidNodeL, "Should be nil but is \(String(describing: invalidNodeL))")
    }
    
    func test_initUUID_T() {
        let validUUIDA = UUID(uuid: zero)
        let validUUIDB = UUID(uuid: test)
        let validUUIDC = UUID(uuid: hex)
        
        XCTAssertNotNil(validUUIDA, "Schould be \(zeroString) but is nil")
        XCTAssertNotNil(validUUIDB, "Schould be \(testString) but is nil")
        XCTAssertNotNil(validUUIDC, "Schould be \(validUUIDStrings[0]) but is nil")
        XCTAssertEqual(validUUIDA.uuidString, zeroString.uppercased())
        XCTAssertEqual(zeroString.uppercased(), validUUIDA.uuidString)
        XCTAssertEqual(validUUIDB.uuidString, testString.uppercased())
        XCTAssertEqual(testString.uppercased(), validUUIDB.uuidString)
    }
    
    func test_init() {
        for _ in 1...20 {
            let uuid = UUID()
            XCTAssertNotNil(uuid, "Should be RFC 4122 V4 Conform UUID but is nil")
            XCTAssertEqual(versionString(uuid: uuid), "4", "Version should be 4")
        }
    }
    
    func test_equality() {
        let uuidA = UUID(uuidString: validUUIDStrings [0])
        let uuidB = UUID(uuidString: validUUIDStrings [1])
        let uuidC = UUID()
        let uuidD = UUID(uuidString: testString)
        let uuidE = UUID(uuid: test)
        let uuidF = UUID(uuid: hex)
        let uuidG = UUID()
        
        XCTAssertEqual(uuidA, uuidB)
        XCTAssertEqual(uuidB, uuidA)
        XCTAssertEqual(uuidA, uuidF)
        XCTAssertEqual(uuidF, uuidA)
        XCTAssertEqual(uuidD, uuidE)
        XCTAssertEqual(uuidE, uuidD)
        XCTAssertNotEqual(uuidA, uuidC)
        XCTAssertNotEqual(uuidC, uuidA)
        XCTAssertNotEqual(uuidG, uuidC)
        XCTAssertNotEqual(uuidC, uuidG)
    }
    
    func test_description() {
        let uuidA = UUID(uuid: zero)
        let uuidB = UUID(uuidString: zeroString)
        let uuidC = UUID(uuid: test)
        let uuidD = UUID(uuidString: testString)
        let uuidE = UUID(uuid: hex)
        
        XCTAssertEqual(uuidA.description, zeroString)
        XCTAssertEqual(uuidB?.description, zeroString)
        XCTAssertEqual(uuidC.description, testString.uppercased())
        XCTAssertEqual(uuidD?.description, testString.uppercased())
        XCTAssertEqual(uuidA.description, uuidB?.description)
        XCTAssertEqual(uuidC.description, uuidD?.description)
        XCTAssertEqual(uuidE.description, validUUIDStrings[0])
    }
    
    func test_debugDescription() {
        let uuidA = UUID(uuid: zero)
        let uuidB = UUID(uuidString: zeroString)
        let uuidC = UUID(uuid: test)
        let uuidD = UUID(uuidString: testString)
        let uuidE = UUID(uuid: hex)
        
        XCTAssertEqual(uuidA.debugDescription, zeroString)
        XCTAssertEqual(uuidB?.debugDescription, zeroString)
        XCTAssertEqual(uuidC.debugDescription, testString.uppercased())
        XCTAssertEqual(uuidD?.debugDescription, testString.uppercased())
        XCTAssertEqual(uuidA.debugDescription, uuidB?.description)
        XCTAssertEqual(uuidC.debugDescription, uuidD?.description)
        XCTAssertEqual(uuidE.debugDescription, uuidE.description)
    }
    
    func test_uuidString() {
        let uuidA = UUID(uuid: zero)
        let uuidB = UUID(uuidString: zeroString)
        let uuidC = UUID(uuid: test)
        let uuidD = UUID(uuidString: testString)
        let uuidE = UUID(uuid: hex)
        
        XCTAssertEqual(uuidA.uuidString, zeroString)
        XCTAssertEqual(uuidB?.uuidString, zeroString)
        XCTAssertEqual(uuidC.uuidString, testString.uppercased())
        XCTAssertEqual(uuidD?.uuidString, testString.uppercased())
        XCTAssertEqual(uuidA.uuidString, uuidB?.description)
        XCTAssertEqual(uuidC.uuidString, uuidD?.description)
        XCTAssertEqual(uuidE.uuidString, validUUIDStrings[0])
        XCTAssertEqual(uuidE.uuidString, uuidE.description)
    }
    
    func test_customReflection() {
        let uuid   = UUID()
        let mirror = uuid.customMirror
        let children = Array(mirror.children)
        
        XCTAssertNotNil(mirror)
        XCTAssertEqual(mirror.displayStyle, .struct)
        XCTAssertNil(mirror.superclassMirror)
        XCTAssertEqual(children.count, 0)
    }
    
    func test_bridgeToObjectiveC() {
        let uuid    = UUID(uuid: test)
        let bridged = uuid._bridgeToObjectiveC()
        
        XCTAssertNotNil(bridged)
        XCTAssertTrue((bridged as Any) is NSUUID)
        XCTAssertFalse((bridged as Any) is UUID)
        XCTAssertEqual(uuid.uuidString, bridged.uuidString)
    }
    
    func test_bridgeFromObjectiveC() {
        let uuid    = NSUUID(uuidString: testString)
        let bridged = UUID._unconditionallyBridgeFromObjectiveC(uuid)
        var bridgedConditional : UUID? = nil
        let _ = UUID._conditionallyBridgeFromObjectiveC(uuid!, result: &bridgedConditional)
        
        XCTAssertNotNil(bridged)
        XCTAssertNotNil(bridgedConditional)
        XCTAssertTrue((bridged as Any) is UUID)
        XCTAssertTrue((bridgedConditional as Any) is UUID)
        XCTAssertFalse((bridged as Any) is NSUUID)
        XCTAssertFalse((bridgedConditional as Any) is NSUUID)
        XCTAssertEqual(uuid?.uuidString, bridged.uuidString)
        XCTAssertEqual(uuid?.uuidString, bridgedConditional?.uuidString)
    }
    
    func versionString(uuid: UUID) -> String {
        let versionIndex = uuid.uuidString.index(uuid.uuidString.startIndex, offsetBy: 14)
        return String(uuid.uuidString[versionIndex])
    }

}
