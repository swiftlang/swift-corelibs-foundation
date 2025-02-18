// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

#if canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(Bionic)
@preconcurrency import Bionic
#elseif os(WASI)
import WASILibc
#elseif canImport(CRT)
import CRT
#endif


// This function is used to mimic a bare minimum of the swift-testing library. Since this package has no swift-testing tests, we simply exit.
// The test runner will automatically call this function when running tests, so it must exit gracefully rather than using `fatalError()`.
public func __swiftPMEntryPoint(passing _: (any Sendable)? = nil) async -> Never {
    exit(0)
}
