// This source file is part of the Swift.org open source project
//
// Copyright (c) 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  ArgumentParser.swift
//  Tools for parsing test execution configuration from command line arguments.
//

/// Utility for converting command line arguments into a strongly-typed
/// representation of the passed-in options
internal struct ArgumentParser {

    /// The basic operations that can be performed by an XCTest runner executable
    enum ExecutionMode {
        /// Run tests or test cases, printing results to stdout and exiting with
        /// a non-0 return code if any tests failed. The names of tests or test cases
        /// may be provided to only run a subset of them.
        case run(selectedTestNames: [String]?)

        /// The different ways that the tests can be represented when they are listed
        enum ListType {
            /// A flat list of the tests that can be run. The lines in this
            /// output are valid test names for the `run` mode.
            case humanReadable

            /// A JSON representation of the test suite, intended for consumption
            /// by other tools
            case json
        }

        /// Print a list of all the tests in the suite.
        case list(type: ListType)

        /// Print Help
        case help(invalidOption: String?)

        var selectedTestNames: [String]? {
            if case .run(let names) = self {
                return names
            } else {
                return nil
            }
        }
    }

    private let arguments: [String]

    init(arguments: [String]) {
        self.arguments = arguments
    }

    var executionMode: ExecutionMode {
        if arguments.count <= 1 {
            return .run(selectedTestNames: nil)
        } else if arguments[1] == "--list-tests" || arguments[1] == "-l" {
            return .list(type: .humanReadable)
        } else if arguments[1] == "--dump-tests-json" {
            return .list(type: .json)
        } else if arguments[1] == "--help" || arguments[1] == "-h" {
            return .help(invalidOption: nil)
        } else if let fst = arguments[1].first, fst == "-" {
            return .help(invalidOption: arguments[1])
        } else {
            return .run(selectedTestNames: arguments[1].split(separator: ",").map(String.init))
        }
    }
}
