//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Foundation
@preconcurrency import Glibc
#elseif canImport(Musl)
import Foundation
@preconcurrency import Musl
#elseif canImport(Bionic)
import Foundation
@preconcurrency import Bionic
#elseif canImport(CRT)
import CRT
#endif

do {
    let command = try PLUCommand(
        arguments: ProcessInfo.processInfo.arguments,
        outputFileHandle: FileHandle.standardOutput,
        errorFileHandle: FileHandle.standardError)
    
    let success = try command.execute()
    exit(success ? EXIT_SUCCESS : EXIT_FAILURE)
} catch let error as PLUContextError {
    FileHandle.standardError.write(error.description + "\n")
    exit(EXIT_FAILURE)
} catch {
    // Some other error?
    FileHandle.standardError.write(error.localizedDescription + "\n")
    exit(EXIT_FAILURE)
}
