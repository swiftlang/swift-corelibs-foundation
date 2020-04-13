// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

private func assertEqual(_ lhs:PersonNameComponents,
                         _ rhs: PersonNameComponents,
                         file: StaticString = #file,
                         line: UInt = #line) {
    assert(equal: true, lhs, rhs, file: file, line: line)
}

private func assertNotEqual(_ lhs:PersonNameComponents,
                            _ rhs: PersonNameComponents,
                            file: StaticString = #file,
                            line: UInt = #line) {
    assert(equal: false, lhs, rhs, file: file, line: line)
}

private func assert(equal: Bool,
                    _ lhs:PersonNameComponents,
                    _ rhs: PersonNameComponents,
                    file: StaticString = #file,
                    line: UInt = #line) {
    if equal {
        XCTAssertEqual(lhs, rhs, file: file, line: line)
        XCTAssertEqual(lhs._bridgeToObjectiveC(), rhs._bridgeToObjectiveC(), file: file, line: line)
        XCTAssertTrue(lhs._bridgeToObjectiveC().isEqual(rhs), file: file, line: line)
    } else {
        XCTAssertNotEqual(lhs, rhs, file: file, line: line)
        XCTAssertNotEqual(lhs._bridgeToObjectiveC(), rhs._bridgeToObjectiveC(), file: file, line: line)
        XCTAssertFalse(lhs._bridgeToObjectiveC().isEqual(rhs), file: file, line: line)
    }
}

class TestPersonNameComponents : XCTestCase {
    
    static var allTests: [(String, (TestPersonNameComponents) -> () throws -> Void)] {
        return [
            ("testCopy", testCopy),
            ("testEquality", testEquality),
        ]
    }
    
    func testCopy() {
        let original = NSPersonNameComponents()
        original.givenName = "Maria"
        original.phoneticRepresentation = PersonNameComponents()
        original.phoneticRepresentation!.givenName = "Jeff"
        let copy = original.copy(with:nil) as! NSPersonNameComponents
        copy.givenName = "Rebecca"
        
        XCTAssertNotEqual(original.givenName, copy.givenName)
        XCTAssertEqual(original.phoneticRepresentation!.givenName,copy.phoneticRepresentation!.givenName)
        XCTAssertNil(copy.phoneticRepresentation!.phoneticRepresentation)
    }

    func testEquality() {
        do {
            let lhs = PersonNameComponents()
            let rhs = PersonNameComponents()
            assertEqual(lhs, rhs)
        }

        let lhs = self.makePersonNameComponentsWithTestValues()
        do {
            let rhs = self.makePersonNameComponentsWithTestValues()
            assertEqual(lhs, rhs)
        }
        do {
            var rhs = self.makePersonNameComponentsWithTestValues()
            rhs.namePrefix = "differentValue"
            assertNotEqual(lhs, rhs)
        }
        do {
            var rhs = self.makePersonNameComponentsWithTestValues()
            rhs.givenName = "differentValue"
            assertNotEqual(lhs, rhs)
        }
        do {
            var rhs = self.makePersonNameComponentsWithTestValues()
            rhs.middleName = "differentValue"
            assertNotEqual(lhs, rhs)
        }
        do {
            var rhs = self.makePersonNameComponentsWithTestValues()
            rhs.familyName = "differentValue"
            assertNotEqual(lhs, rhs)
        }
        do {
            var rhs = self.makePersonNameComponentsWithTestValues()
            rhs.nameSuffix = "differentValue"
            assertNotEqual(lhs, rhs)
        }
        do {
            var rhs = self.makePersonNameComponentsWithTestValues()
            rhs.nickname = "differentValue"
            assertNotEqual(lhs, rhs)
        }
        do {
            var rhs = self.makePersonNameComponentsWithTestValues()
            rhs.phoneticRepresentation?.namePrefix = "differentValue"
            assertNotEqual(lhs, rhs)
        }
    }

    // MARK: - Helpers

    private func makePersonNameComponentsWithTestValues() -> PersonNameComponents {
        var components = PersonNameComponents()
        components.namePrefix = "namePrefix"
        components.givenName = "givenName"
        components.middleName = "middleName"
        components.familyName = "familyName"
        components.nameSuffix = "nameSuffix"
        components.nickname = "nickname"
        components.phoneticRepresentation = {
            var components = PersonNameComponents()
            components.namePrefix = "phonetic_namePrefix"
            components.givenName = "phonetic_givenName"
            components.middleName = "phonetic_middleName"
            components.familyName = "phonetic_familyName"
            components.nameSuffix = "phonetic_nameSuffix"
            components.nickname = "phonetic_nickname"
            return components
        }()
        return components
    }
}

        
