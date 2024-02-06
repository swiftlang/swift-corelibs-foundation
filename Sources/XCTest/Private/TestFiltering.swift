// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  XCTestFiltering.swift
//  This provides utilities for executing only a subset of the tests provided to `XCTMain`
//

internal typealias TestFilter = (XCTestCase.Type, String) -> Bool

internal struct TestFiltering {
    private let selectedTestNames: [String]?

    init(selectedTestNames: [String]?) {
        self.selectedTestNames = selectedTestNames
    }

    var selectedTestFilter: TestFilter {
        guard let selectedTestNames = selectedTestNames else { return includeAllFilter() }
        let selectedTests = Set(selectedTestNames.compactMap { SelectedTest(selectedTestName: $0) })

        return { testCaseClass, testCaseMethodName in
            return selectedTests.contains(SelectedTest(testCaseClass: testCaseClass, testCaseMethodName: testCaseMethodName)) ||
                   selectedTests.contains(SelectedTest(testCaseClass: testCaseClass, testCaseMethodName: nil))
        }
    }

    private func includeAllFilter() -> TestFilter {
        return { _,_ in true }
    }

    static func filterTests(_ entries: [XCTestCaseEntry], filter: TestFilter) -> [XCTestCaseEntry] {
        return entries
            .map { testCaseClass, testCaseMethods in
                return (testCaseClass, testCaseMethods.filter { filter(testCaseClass, $0.0) } )
            }
            .filter { _, testCaseMethods in
                return !testCaseMethods.isEmpty
            }
    }
}

/// A selected test can be a single test case, or an entire class of test cases
private struct SelectedTest : Hashable {
    let testCaseClassName: String
    let testCaseMethodName: String?
}

private extension SelectedTest {
    init?(selectedTestName: String) {
        let components = selectedTestName.split(separator: "/").map(String.init)
        switch components.count {
        case 1:
            testCaseClassName = components[0]
            testCaseMethodName = nil
        case 2:
            testCaseClassName = components[0]
            testCaseMethodName = components[1]
        default:
            return nil
        }
    }

    init(testCaseClass: XCTestCase.Type, testCaseMethodName: String?) {
        self.init(testCaseClassName: String(reflecting: testCaseClass), testCaseMethodName: testCaseMethodName)
    }
}
