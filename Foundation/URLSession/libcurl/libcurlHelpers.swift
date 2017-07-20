// Foundation/URLSession/libcurlHelpers - URLSession & libcurl
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
// -----------------------------------------------------------------------------
///
/// These are libcurl helpers for the URLSession API code.
/// - SeeAlso: https://curl.haxx.se/libcurl/c/
/// - SeeAlso: URLSession.swift
///
// -----------------------------------------------------------------------------


import CoreFoundation


//TODO: Move things in this file?


internal func initializeLibcurl() {
    try! CFURLSessionInit().asError()
}


internal extension String {
    /// Create a string by a buffer of UTF 8 code points that is not zero
    /// terminated.
    init?(utf8Buffer: UnsafeBufferPointer<UInt8>) {
        var bufferIterator = utf8Buffer.makeIterator()
        var codec = UTF8()
        var result: String = ""
        iter: repeat {
            switch codec.decode(&bufferIterator) {
            case .scalarValue(let scalar):
                result.append(String(describing: scalar))
            case .error:
                return nil
            case .emptyInput:
                break iter
            }
        } while true
        self.init(stringLiteral: result)
    }
}
