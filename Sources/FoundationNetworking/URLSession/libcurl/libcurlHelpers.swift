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

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
import SwiftFoundation
#else
import Foundation
#endif

@_implementationOnly import _CFURLSessionInterface

//TODO: Move things in this file?


private let _initializeLibcurl: Void = {
    try! CFURLSessionInit().asError()
}()

/// Initializes libcurl idempontently.
internal func ensureLibcurlIsInitialized() {
    _ = _initializeLibcurl // The lazy global is computed on only first access.
}

/// OpenSSL < 1.1.0 is not thread-safe.
/// https://curl.se/libcurl/c/threadsafe.html
internal let isThreadSafeOpenSSL: Bool = {
    // curl_version_info is not thread-safe until curl_global_init has been called.
    // https://curl.se/libcurl/c/curl_version_info.html
    ensureLibcurlIsInitialized()

    let version = CFURLSessionSSLVersionInfo();
    guard version.isOpenSSL else { return true }

    return (version.major == 1 && version.minor >= 1) || version.major > 1
}()

private let _openSSLOperationLock = NSLock()

/// Executes the given function, locking only if OpenSSL is not thread-safe.
internal func lockingForOpenSSLIfNeeded<T, E: Error>(_ body: () throws(E) -> T) throws(E) -> T {
    if isThreadSafeOpenSSL {
        return try body()
    }

    _openSSLOperationLock.lock()
    defer { _openSSLOperationLock.unlock() }
    return try body()
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
