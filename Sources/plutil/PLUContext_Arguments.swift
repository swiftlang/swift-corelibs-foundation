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

/// Common arguments for create, insert, extract, etc.
struct PLUContextArguments {
    var paths: [String]
    var readable: Bool
    var terminatingNewline: Bool
    var outputFileName: String?
    var outputFileExtension: String?
    var silent: Bool?
    
    init(arguments: [String]) throws {
        paths = []
        readable = false
        terminatingNewline = true
            
        var argumentIterator = arguments.makeIterator()
        var readRemainingAsPaths = false
        while let arg = argumentIterator.next() {
            switch arg {
            case "--":
                readRemainingAsPaths = true
                break
            case "-n":
                terminatingNewline = false
            case "-s":
                silent = true
            case "-r":
                readable = true
            case "-o":
                guard let next = argumentIterator.next() else {
                    throw PLUContextError.argument("Missing argument for -o.")
                }
                
                outputFileName = next
            case "-e":
                guard let next = argumentIterator.next() else {
                    throw PLUContextError.argument("Missing argument for -e.")
                }
                
                outputFileExtension = next
            default:
                if arg.hasPrefix("-") && arg.count > 1 {
                    throw PLUContextError.argument("unrecognized option: \(arg)")
                }
                paths.append(arg)
            }
        }

        if readRemainingAsPaths {
            while let arg = argumentIterator.next() {
                paths.append(arg)
            }
        }
        
        // Make sure we have files
        guard !paths.isEmpty else {
            throw PLUContextError.argument("No files specified.")
        }
    }
}
