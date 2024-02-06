// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//
//  SourceLocation.swift
//

internal struct SourceLocation {

    typealias LineNumber = UInt

    /// Represents an "unknown" source location, with default values, which may be used as a fallback
    /// when a real source location may not be known.
    static var unknown: SourceLocation = {
        return SourceLocation(file: "<unknown>", line: 0)
    }()

    let file: String
    let line: LineNumber

    init(file: String, line: LineNumber) {
        self.file = file
        self.line = line
    }

    init(file: StaticString, line: LineNumber) {
        self.init(file: String(describing: file), line: line)
    }

    init(file: String, line: Int) {
        self.init(file: file, line: LineNumber(line))
    }

    init(file: StaticString, line: Int) {
        self.init(file: String(describing: file), line: LineNumber(line))
    }

}
