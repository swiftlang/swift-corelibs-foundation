// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  TestListing.swift
//  Implementation of the mode for printing the list of tests.
//

internal struct TestListing {
    private let testSuite: XCTestSuite

    init(testSuite: XCTestSuite) {
        self.testSuite = testSuite
    }

    /// Prints a flat list of the tests in the suite, in the format used to
    /// specify a test by name when running tests.
    func printTestList() {
        let list = testSuite.list()
        let tests = list.count == 1 ? "test" : "tests"
        let bundleName = testSuite.findBundleTestSuite()?.name ?? "<<unknown bundle>>"

        print("Listing \(list.count) \(tests) in \(bundleName):\n")
        for entry in testSuite.list() {
            print(entry)
        }
    }

    /// Prints a JSON representation of the tests in the suite, mirring the internal
    /// tree representation of test suites and test cases. This output is intended
    /// to be consumed by other tools.
    func printTestJSON() {
        let json = try! JSONSerialization.data(withJSONObject: testSuite.dictionaryRepresentation())
        print(String(data: json, encoding: .utf8)!)
    }
}

protocol Listable {
    func list() -> [String]
    func dictionaryRepresentation() -> NSDictionary
}

private func moduleName(value: Any) -> String {
    let moduleAndType = String(reflecting: type(of: value))
    return String(moduleAndType.split(separator: ".").first!)
}

extension XCTestSuite: Listable {
    private var listables: [Listable] {
        return tests
            .compactMap({ ($0 as? Listable) })
    }

    private var listingName: String {
        if let childTestCase = tests.first as? XCTestCase, name == String(describing: type(of: childTestCase)) {
            return "\(moduleName(value: childTestCase)).\(name)"
        } else {
            return name
        }
    }

    func list() -> [String] {
        return listables.flatMap({ $0.list() })
    }

    func dictionaryRepresentation() -> NSDictionary {
        let listedTests = NSArray(array: tests.compactMap({ ($0 as? Listable)?.dictionaryRepresentation() }))
        return NSDictionary(objects: [NSString(string: listingName),
                                      listedTests],
                            forKeys: [NSString(string: "name"),
                                      NSString(string: "tests")])
    }

    func findBundleTestSuite() -> XCTestSuite? {
        if name.hasSuffix(".xctest") {
            return self
        } else {
            return tests.compactMap({ ($0 as? XCTestSuite)?.findBundleTestSuite() }).first
        }
    }
}

extension XCTestCase: Listable {
    func list() -> [String] {
        let adjustedName = name.split(separator: ".")
            .map(String.init)
            .joined(separator: "/")
        return ["\(moduleName(value: self)).\(adjustedName)"]
    }

    func dictionaryRepresentation() -> NSDictionary {
        let methodName = String(name.split(separator: ".").last!)
        return NSDictionary(object: NSString(string: methodName), forKey: NSString(string: "name"))
    }
}
