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



class TestNSPersonNameComponents : XCTestCase {
    
    static var allTests: [(String, (TestNSPersonNameComponents) -> () throws -> Void)] {
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

    func testEquality() {
        do {
            let lhs = PersonNameComponents()
            let rhs = PersonNameComponents()
            XCTAssertEqual(lhs, rhs)
        }
        do {
            let lhs = self.makePersonNameComponentsWithTestValues()
            let rhs = self.makePersonNameComponentsWithTestValues()
            XCTAssertEqual(lhs, rhs)
        }
        do {
            var lhs = self.makePersonNameComponentsWithTestValues()
            lhs.namePrefix = "differentValue"
            let rhs = self.makePersonNameComponentsWithTestValues()
            XCTAssertNotEqual(lhs, rhs)
        }
        do {
            var lhs = self.makePersonNameComponentsWithTestValues()
            lhs.givenName = "differentValue"
            let rhs = self.makePersonNameComponentsWithTestValues()
            XCTAssertNotEqual(lhs, rhs)
        }
        do {
            var lhs = self.makePersonNameComponentsWithTestValues()
            lhs.middleName = "differentValue"
            let rhs = self.makePersonNameComponentsWithTestValues()
            XCTAssertNotEqual(lhs, rhs)
        }
        do {
            var lhs = self.makePersonNameComponentsWithTestValues()
            lhs.familyName = "differentValue"
            let rhs = self.makePersonNameComponentsWithTestValues()
            XCTAssertNotEqual(lhs, rhs)
        }
        do {
            var lhs = self.makePersonNameComponentsWithTestValues()
            lhs.nameSuffix = "differentValue"
            let rhs = self.makePersonNameComponentsWithTestValues()
            XCTAssertNotEqual(lhs, rhs)
        }
        do {
            var lhs = self.makePersonNameComponentsWithTestValues()
            lhs.nickname = "differentValue"
            let rhs = self.makePersonNameComponentsWithTestValues()
            XCTAssertNotEqual(lhs, rhs)
        }
        do {
            var lhs = self.makePersonNameComponentsWithTestValues()
            lhs.phoneticRepresentation?.namePrefix = "differentValue"
            let rhs = self.makePersonNameComponentsWithTestValues()
            XCTAssertNotEqual(lhs, rhs)
        }
    }
}

        
